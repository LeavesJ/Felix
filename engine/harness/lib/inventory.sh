# felix inventory: where unlanded work is, derived from disk, git and gh, and
# from the host's session records through one adapter.
#
# Work is lost before it reaches a pull request, and a landing actor sees only
# open ones. The sweep of 2026-09-24 found every stage, from edits left in
# stopped worktrees to a branch checked out twice whose idle index held a
# staged revert of the other's merge. A session that dies registers nothing,
# and SessionEnd fired for 13 of 60, so this is derived, every time.
#
# Read-only by construction. Every git call (_fi_git) takes no optional lock,
# runs no fsmonitor, shows no signature (a user's log.showSignature would run
# gpg), reads pathspecs literally (a directory named k* is not a
# glob) and fetches nothing a partial clone lacks (GIT_NO_LAZY_FETCH, git
# 2.44; on an older git a partial clone is refused, not read). git is never
# asked to write: no merge-tree --write-tree, stash create, write-tree,
# update-index or fetch, and hash-object without -w or filters. git status
# runs with every configured filter driver switched off, since a clean filter
# runs on each stat-dirty file and may store what it is handed (git-lfs
# does), and with submodules compared by commit only, so no git runs inside
# one. Remote-tracking refs are taken as they stand; gh is asked `pr list`
# and nothing else, with its own state pointed into the scratch. Scratch is
# one mktemp -d outside every repository (inside a worktree it would read as
# that worktree's changes), removed on exit and on HUP, INT, QUIT and TERM;
# no here-document, which bash 3.2 backs with a file outside it. Advisory:
# nothing on the enforcing path reads it (invariant 2), and it exits 0
# unless a repository cannot be read at all, 2 on a bad argument.
#
# Everything here is git and GitHub, with lib/inventory-gh.sh (what gh says),
# lib/inventory-orphans.sh (what sits beside the worktrees) and
# lib/inventory-items.sh (one worktree, handoff sections, chips); what only a
# host's records say (live, question, blocked, chips, the session behind a pull
# request) is asked of lib/inventory-host.sh, and lib/inventory-view.sh draws
# the human view. What cannot be read prints unknown, never absent.
#
# One row per item: a worktree, an orphan, a local branch checked out
# nowhere, a remote branch no local branch covers (one at its tip or ahead of
# it) or open PR does, an open PR whose head no local branch proposes (always
# one from a fork), a chip, a pending handoff section; a branch's PR states ride
# on its own row, looked up by the name it has on origin. Whether a branch is
# the default one is told by its name, never by its upstream: a feature branch
# made with --track origin/main tracks the default branch and is not it. What
# was read of the repository is five rows of kind cover first: default, prs,
# sessions, chips, objects. States print in _FI_ORDER, the first the headline;
# landed means none holds but live and the content column says landed. A
# worktree or orphan that is a helper's (a subagent's or a workflow's, which the
# host adapter says) also holds helper, after landed and before any unknown
# entry, and unknown:helper, last, when the host's records were not searched for
# it: a placement mark, never a headline, and no bar to landed. A
# worktree or orphan in a temporary directory ($TMPDIR, /tmp, /private/tmp,
# /private/var/folders, or instead the colon-separated FELIX_INVENTORY_TEMP_ROOTS
# when set, which tests use) says temp in its detail and is read as any other.
# Content is on the default branch (origin/HEAD's target, else origin/main,
# else origin/master) when the branch reaches the tip, or a merged PR's head
# is the tip or descends from it, since squash merges defeat ancestry;
# otherwise each path the tip changed since its merge-base is compared with
# the default branch's blob: all equal landed, none not, some partly. That
# compares with main's current blobs, so a pushed tip read that way, when no PR
# list could settle it, is unknown, not unlanded. A dirty path compares its
# working file; a worktree's content is the worse of the two. Three gaps in the
# spec are filled: a pushed branch whose PRs all merged before its newest
# commits is unproposed, not landed; a staged revert's earlier tip must not
# descend from HEAD, or a reset --soft reads as one, and a detached worktree
# reads its HEAD's reflog; and a branch never pushed heads no PR, so under
# --no-gh its PR states are no.
#
# Carried (step 6): a worktree, branch or remote row whose tip's content is not
# landed, that holds no open PR, and whose tip another pushed branch (a
# refs/remotes/origin ref but origin/HEAD, the default branch and its own name
# on origin) already holds, is carried, not unproposed or pr-closed-unlanded;
# git alone decides it, so --no-gh keeps it. lib/inventory-items.sh (_fi_carry)
# reads the carriers with one for-each-ref --contains and names the outermost.
#
# A worktree git lists is read only when git, asked there, names that
# directory as the top of a working tree of this repository: a directory
# whose .git file is gone would otherwise be read as the checkout enclosing
# it, and a path holding a line break is not read at all.
#
# Every fact per item is joined once, by awk, into one line of $T/items, and
# the loop only reads fields: a lookup in a bash string of a few thousand
# refs costs seconds a time on bash 3.2, and a fork per helper, minutes.

_FI_ORDER='hazard:shared-branch hazard:staged-revert live question blocked uncommitted unpushed unproposed pr-open pr-closed-unlanded carried orphan chip-unstarted handoff-pending'
_FI_TAB=$'\t'
_FI_NL=$'\n'
_FI_PENDING="docs/handoff/pending"   # the layout lib/handoff.sh writes

felix_inventory_usage() {
  printf 'usage: felix inventory [--repo DIR]... [--tsv] [--live MIN] [--blocked MIN] [--days N] [--no-gh] [--no-host]\n'
  printf '  read-only: where unlanded work is, derived from git, gh and the host'"'"'s session records\n'
  printf '  --repo DIR     a repository to read, repeatable (default: the one holding this directory)\n'
  printf '  --tsv          one row per item: kind repo ref states owner age_h content detail\n'
  printf '  --live MIN, --blocked MIN, --days N   live: a session active within MIN (60); blocked: a tool call\n'
  printf '                 unanswered for MIN (20); chips: from sessions active within N days (14)\n'
  printf '  --no-gh        do not ask gh: PR states become unknown\n'
  printf '  --no-host      do not read session records: live, question, blocked and chips become unknown\n'
}
_fi_refuse() { printf 'felix inventory: %s\n' "$1" >&2; felix_inventory_usage >&2; return 2; }
_fi_git() { GIT_NO_LAZY_FETCH=1 git --no-optional-locks --literal-pathspecs -c core.fsmonitor=false -c log.showSignature=false "$@"; }
_fi_git_244() { _fi_git --version 2>/dev/null | awk '{ split($3, v, "."); exit !(v[1] > 2 || (v[1] == 2 && v[2] >= 44)) }'; }
# A row: kind ref states owner age content detail sig branch, the repository second; no tab or line break in a field, - for empty.
_fi_row() {
  local a line=""
  for a in "$1" "$_FI_REPO" "${@:2}"; do a="${a//$_FI_TAB/ }"; a="${a//$_FI_NL/ }"; a="${a//$'\001'/ }"; a="${a//$'\002'/ }"; line="$line${a:--}$_FI_TAB"; done
  printf '%s\n' "${line%"$_FI_TAB"}" >> "$_FI_T/rows"
}
_fi_age() { case "${1:-}" in ''|0|-|*[!0123456789]*) _FI_A=- ;; *) _FI_A=$(( (_FI_NOW - $1) / 3600 )) ;; esac; }
_fi_add() { _FI_DET="${_FI_DET:+$_FI_DET; }$1"; }
# The content (landed, partly, not, unknown or -), then name=yes|no|unknown
# pairs in _FI_ORDER, as the states field: the held ones, landed when none but
# live is held, nothing is unknown but live and the content is landed or -,
# helper (the last pair, when given: a placement mark, not a held state, so it
# never keeps a row from landed), then each unknown, unknown:helper last. No
# state at all prints -.
_fi_states() {
  local c="$1" a held="" unk="" hp="" open=0
  shift
  for a in "$@"; do
    case "${a#*=}" in
      yes) if [ "${a%%=*}" = helper ]; then hp=",helper"; continue; fi; held="$held,${a%%=*}" ;;
      unknown) unk="$unk,unknown:${a%%=*}" ;;
      *) continue ;;
    esac
    [ "${a%%=*}" = live ] || open=1
  done
  case "$c" in landed|-) [ "$open" = 1 ] || held="$held,landed" ;; esac
  held="$held$hp$unk"; _FI_S="${held#,}"
}
# The worse of two content values, as _FI_W: not, then partly, unknown, landed.
_fi_worse() {
  case "$1,$2" in not,*|*,not) _FI_W=not ;; partly,*|*,partly) _FI_W=partly ;; unknown,*|*,unknown) _FI_W=unknown ;; *) _FI_W=landed ;; esac
}
# What an item changed, as one checksum, for possible-duplicate.
_fi_sig() { _FI_SIG=-; if [ -s "$T/sig" ] || [ -s "$T/dsig" ]; then _FI_SIG="$(cat "$T/sig" "$T/dsig" | cksum | tr ' ' :)"; fi; }
# Scratch outside every repository, else under /tmp, else none.
_fi_scratch() {
  local b
  for b in "${TMPDIR:-/tmp}" /tmp; do
    _FI_T="$(mktemp -d "${b%/}/felix-inventory.XXXXXX" 2>/dev/null)" || { _FI_T=""; continue; }
    _fi_git -C "$_FI_T" rev-parse --git-dir >/dev/null 2>&1 || return 0
    rmdir "$_FI_T"; _FI_T=""
  done
  return 1
}

felix_inventory() {
  local tsv=0 repos="" d rc=0
  _FI_LIVE=60; _FI_BLOCKED=20; _FI_DAYS=14; _FI_GH=1; _FI_HOST=1
  while [ $# -gt 0 ]; do
    case "$1" in
      --repo) [ $# -ge 2 ] && [ -n "$2" ] || { _fi_refuse "--repo needs a directory"; return; }; repos="$repos$2$_FI_NL"; shift 2 ;;
      --live|--blocked|--days)
              case "${2:-}" in ''|*[!0123456789]*|???????*) _fi_refuse "$1 needs a whole number of at most six digits"; return ;; esac
              case "$1" in --live) _FI_LIVE=$((10#$2)) ;; --blocked) _FI_BLOCKED=$((10#$2)) ;; *) _FI_DAYS=$((10#$2)) ;; esac; shift 2 ;;
      --tsv) tsv=1; shift ;;  --no-gh) _FI_GH=0; shift ;;  --no-host) _FI_HOST=0; shift ;;
      -h|--help) felix_inventory_usage; return 0 ;;  *) _fi_refuse "unknown argument: $1"; return ;;
    esac
  done
  # The repositories read are the ones named, never one an inherited GIT_DIR names.
  unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_COMMON_DIR GIT_OBJECT_DIRECTORY CDPATH   # CDPATH would send a cd to a relative common dir elsewhere
  export LC_ALL=C; [ -n "$repos" ] || repos="$PWD$_FI_NL"; _fi_tmps
  _FI_T=""; trap '[ -z "$_FI_T" ] || rm -rf "$_FI_T"' EXIT
  trap 'exit 129' HUP; trap 'exit 130' INT; trap 'exit 131' QUIT; trap 'exit 143' TERM
  _fi_scratch || { printf 'felix inventory: no scratch directory outside every repository\n' >&2; return 1; }
  _FI_NOW="$(date +%s)"; T="$_FI_T/r"; : > "$_FI_T/rows"; printf '%s' "$repos" > "$_FI_T/repos"
  while IFS= read -r d <&3; do [ -n "$d" ] && { _fi_repo "$d" || rc=1; }; done 3< "$_FI_T/repos"
  _fi_out "$tsv"; return "$rc"
}

# ---------------------------------------------------------------- facts ----
# Scratch for one repository is $T; every loop reads its file on fd 3, since
# git and awk inside a loop would otherwise read what the loop is reading.
_fi_repo() {
  local d="$1" c f w k ref sha br dt cl rr op num st fl sh gn
  [ -d "$T" ] && rm -rf "$T"; mkdir "$T" || return 1
  # -z, since a path may hold a line break (git 2.36; before it, plain).
  c="$(_fi_git -C "$d" rev-parse --git-common-dir 2>/dev/null)" && c="$(cd "$d" && cd "$c" && pwd -P)" \
    && { { _fi_git -C "$d" worktree list --porcelain -z > "$T/wtz" 2>/dev/null && tr '\n\000' '\001\n' < "$T/wtz" > "$T/wtp"; } \
         || _fi_git -C "$d" worktree list --porcelain > "$T/wtp" 2>/dev/null; } \
    || { printf 'felix inventory: %s is not a git repository it can read\n' "$d" >&2; return 1; }
  _FI_D="$d"; _FI_COMMON="$c"; _FI_PARTIAL=0; _FI_SHALLOW=0
  [ "$(_fi_git -C "$d" rev-parse --is-shallow-repository 2>/dev/null)" != true ] || _FI_SHALLOW=1
  if _fi_git -C "$d" config --get extensions.partialClone >/dev/null 2>&1 \
     || _fi_git -C "$d" config --bool --get-regexp '^remote\..*\.promisor$' 2>/dev/null | awk '/ true$/ { f = 1 } END { exit !f }'; then
    _fi_git_244 || { printf 'felix inventory: %s is a partial clone, and a git before 2.44 would fetch what it lacks\n' "$d" >&2; return 1; }
    _FI_PARTIAL=1
  fi
  # path head branch flags, one line per worktree, the main one first; a path
  # holding a line break (\001 here) or a tab (\002) is flagged linebreak and
  # never read, and prints with a space in their place.
  awk 'function out() { if (p != "") print p "\t" h "\t" b "\t" (s == "" ? "-" : s) }
       /^worktree / { out(); p = substr($0, 10); h = "-"; b = "-"; s = ""
         if (index(p, "\001") || index(p, "\t")) { gsub(/\t/, "\002", p); s = "linebreak," } next }
       /^HEAD / { h = $2 } /^branch / { b = substr($0, 8); sub(/^refs\/heads\//, "", b) }
       /^(bare|detached|locked|prunable)/ { s = s $1 "," }
       END { out() }' "$T/wtp" > "$T/wt"
  _FI_REPO="$(head -1 "$T/wt" | cut -f1)"; _FI_MAIN="$_FI_REPO"
  case "$(head -1 "$T/wt" | cut -f4)" in *bare*|*linebreak*) _FI_MAIN="" ;; esac
  _FI_DEF="$(_fi_git -C "$d" rev-parse --abbrev-ref origin/HEAD 2>/dev/null)" || _FI_DEF=""
  case "$_FI_DEF" in origin/HEAD|origin/) _FI_DEF="" ;; origin/*) ;; *) _FI_DEF="" ;; esac
  for f in origin/main origin/master; do
    [ -z "$_FI_DEF" ] && _fi_git -C "$d" rev-parse -q --verify "refs/remotes/$f^{commit}" >/dev/null 2>&1 && _FI_DEF="$f"
  done
  _FI_DEFSHA=""; : > "$T/deftree"
  if [ -n "$_FI_DEF" ]; then
    _FI_DEFSHA="$(_fi_git -C "$d" rev-parse -q --verify "refs/remotes/$_FI_DEF^{commit}")" || _FI_DEFSHA=""
    # A tree the clone lacks leaves the default branch unknown, not empty.
    if [ -n "$_FI_DEFSHA" ] && _fi_git -C "$d" ls-tree -r -z --full-tree "$_FI_DEFSHA" > "$T/deftz" 2>/dev/null; then
      tr '\000' '\n' < "$T/deftz" | awk '{ i = index($0, "\t"); split(substr($0, 1, i - 1), m, " "); print substr($0, i + 1) "\t" m[3] }' > "$T/deftree"
    else _FI_DEF=""; _FI_DEFSHA=""; fi
  fi
  _fi_git -C "$d" for-each-ref --format='%(refname)%09%(objectname)%09%(committerdate:unix)%09%(upstream)%09%(symref)' \
    refs/heads refs/remotes | awk -F'\t' -v OFS='\t' '{ for (i = 1; i <= 5; i++) if ($i == "") $i = "-"; print }' > "$T/refs"
  if _fi_gh "$d"; then _FI_GHOK=1; else _FI_GHOK=0; fi
  _fi_sets; _fi_orphan_find; _fi_hscope; _fi_pending; _fi_chipsread; _fi_cover; _fi_owners
  while IFS="$_FI_TAB" read -r k ref sha br dt cl rr op num st fl sh gn <&3; do _fi_item; done 3< "$T/items"
  _fi_orphan_rows; _fi_handoff; _fi_chips
  return 0
}

# The whole hours since the later of FETCH_HEAD's mtime and the newest reflog
# entry of the default branch's remote-tracking ref, as the detail of the cover
# row: remote facts are as old as that.
_fi_fetched() {
  local a b
  a="$(date -r "$_FI_COMMON/FETCH_HEAD" +%s 2>/dev/null)"
  b="$(_fi_git -C "$_FI_D" log -g -1 --format=%gd --date=unix "refs/remotes/$_FI_DEF" -- 2>/dev/null)"; b="${b#*@\{}"; b="${b%\}*}"
  case "$a" in ''|*[!0123456789]*) a=0 ;; esac; case "$b" in ''|*[!0123456789]*) b=0 ;; esac
  [ "$b" -le "$a" ] || a="$b"
  if [ "$a" -gt 0 ]; then printf 'fetched %dh ago' $(( (_FI_NOW - a) / 3600 )); else printf 'fetch time unknown'; fi
}
# The five cover rows of a repository: what was read of it, and for each facet
# not read the unknown states it leaves the items. Read, partial or unknown.
_fi_cover() {
  local s d
  if [ -n "$_FI_DEF" ]; then s=read; d="$_FI_DEF @ ${_FI_DEFSHA:0:8}; $(_fi_fetched)"
  else s="unknown,unknown:uncommitted,unknown:unpushed,unknown:unproposed,unknown:pr-closed-unlanded"
       d="no origin/HEAD, origin/main or origin/master whose tree this clone holds"; fi
  [ "$_FI_PENDFAIL" = 0 ] || { d="$d; handoff sections not read"; s="$s,unknown:handoff-pending"; }
  _fi_row cover default "$s" - - - "$d" - -
  if [ "$_FI_GHOK" = 0 ]; then s="unknown,unknown:pr-open,unknown:unproposed,unknown:pr-closed-unlanded"; d="$_FI_GHSTATE"
  elif [ "$_FI_GHTRUNC" = 1 ]; then s="partial,unknown:unproposed"; d="$_FI_GHCMD: $_FI_GHN PRs, gh's limit: older PRs are not seen"
  else s=read; d="$_FI_GHCMD: $_FI_GHN PRs"; fi
  _fi_row cover prs "$s" - - - "$d" - -
  if [ "$_FI_HOSTOK" = 1 ]; then s=read; d="$_FI_HD"; else s="unknown,unknown:live,unknown:question,unknown:blocked"; d="$_FI_HD"; fi
  _fi_row cover sessions "$s" - - - "$d" - -
  if [ "$_FI_HOSTOK" = 1 ]; then s=read; d="proposed in sessions active in the last $_FI_DAYS days"; [ "$_FI_CHU" = 0 ] || d="$d; $_FI_CHU session files could not be read"
  else s="unknown,unknown:chip-unstarted"; d="$_FI_HD"; fi
  _fi_row cover chips "$s" - - - "$d" - -
  s=read; d="a full clone"
  if [ "$_FI_PARTIAL" = 1 ]; then s=partial; d="a partial clone: nothing was fetched, so content in no object here may be the remote's"; fi
  if [ "$_FI_SHALLOW" = 1 ]; then s=partial; d="${d#a full clone}"; d="${d:+$d; }a shallow clone: history past the graft is absent, so a merge-base may be missing or wrong"; fi
  _fi_row cover objects "$s" - - - "$d" - -
}

# The commits of the tips in file $3 that the ^lines of file $4 do not reach, into
# $1, by one shared rev-list. A shared walk dies when one tip's history lacks an
# object, and would then read every tip as reached: so it is redone one tip at a
# time (-n 1 prints the tip itself when it is not reached), and a tip whose own
# walk dies is listed in $T/bad as "$2<TAB>tip", for its reading to be unknown.
_fi_walk() {
  local tip
  { cat "$3" "$4"; } | _fi_git -C "$_FI_D" rev-list --stdin > "$1" 2>/dev/null && return 0
  : > "$1"
  while IFS= read -r tip <&3; do
    { printf '%s\n' "$tip"; cat "$4"; } | _fi_git -C "$_FI_D" rev-list -n 1 --stdin >> "$1" 2>/dev/null || printf '%s\t%s\n' "$2" "$tip" >> "$T/bad"
  done 3< "$3"
  return 0
}

# The items: kind ref sha branch date class rr open num state flags shared gone.
# Class RXM: R the default branch reaches the tip, X it holds a commit on no
# remote-tracking ref, M a merged PR's head is it or descends from it; --- it
# is not here, and is kept out of every rev-list, which one would fail. A
# letter u says its walk could not be made, since a commit the clone lacks lies
# in the tip's own history (M: in a merged head's): what that decides is unknown.
_fi_sets() {
  local t="$T/tips" have='%(objectname) %(objecttype)' r rs ls h
  { cut -f2 "$T/wt"; awk -F'\t' '$1 ~ /^refs\/heads\// { print $2 }' "$T/refs"; } | awk '$1 != "-"' | LC_ALL=C sort -u > "$t.l"
  awk -F'\t' -v dn="${_FI_DEF#origin/}" '$2 == "MERGED" && dn != "" && $12 == dn { print $4 }' "$T/prs" > "$T/mh"   # only a PR merged into the default branch
  { cat "$t.l"; awk -F'\t' '$1 ~ /^refs\/remotes\// && $5 == "-" { print $2 }' "$T/refs"; awk -F'\t' '$2 == "OPEN" { print $4 }' "$T/prs"; } \
    | LC_ALL=C sort -u | _fi_git -C "$_FI_D" cat-file --batch-check="$have" 2>/dev/null | awk '$2 == "commit" { print $1 }' > "$t"
  : > "$T/ahead"; : > "$T/merged"; : > "$T/bad"; : > "$T/unpushed"
  if [ -n "$_FI_DEFSHA" ]; then printf '^%s\n' "$_FI_DEFSHA" > "$T/neg"; _fi_walk "$T/ahead" a "$t" "$T/neg"; fi
  grep -xF -f "$t" "$t.l" > "$T/lt"
  awk -F'\t' '$1 ~ /^refs\/remotes\// && $5 == "-" { print "^" $2 }' "$T/refs" > "$T/negx"; _fi_walk "$T/unpushed" x "$T/lt" "$T/negx"
  _fi_git -C "$_FI_D" cat-file --batch-check="$have" < "$T/mh" 2>/dev/null | awk '$2 == "commit" { print $1 }' > "$T/mheads"
  if [ -s "$T/mheads" ] && [ -n "$_FI_DEFSHA" ]; then
    { cat "$T/mheads"; cat "$T/neg"; } | _fi_git -C "$_FI_D" rev-list --stdin > "$T/merged" 2>/dev/null || {
      : > "$T/merged"   # one head's history lacks an object: head by head, and any tip that is not found is then unknown
      while IFS= read -r h <&3; do { printf '%s\n' "$h"; cat "$T/neg"; } | _fi_git -C "$_FI_D" rev-list --stdin >> "$T/merged" 2>/dev/null || printf 'm\t-\n' >> "$T/bad"; done 3< "$T/mheads"; }
  fi
  cut -f2 "$T/wt" | grep -xF -f "$t" | _fi_git -C "$_FI_D" log --no-walk=unsorted --stdin --format='%H %ct' > "$T/dates" 2>/dev/null
  # The remote branch each local branch covers: origin/<its name>, else its
  # upstream unless that is the default branch. Covered means its tip is the
  # local tip or behind it; one ahead or apart gets a row of its own.
  awk -F'\t' -v def="$_FI_DEF" '$1 ~ /^refs\/heads\// { L[substr($1, 12)] = $2; U[substr($1, 12)] = $4; next }
    $1 ~ /^refs\/remotes\// && $5 == "-" { R[substr($1, 14)] = $2 }
    END { for (n in L) { r = "origin/" n; u = substr(U[n], 14)
            if (!(r in R)) { if (U[n] ~ /^refs\/remotes\// && u != def && (u in R)) r = u; else continue }
            print r "\t" R[r] "\t" L[n] } }' "$T/refs" > "$T/covp"
  : > "$T/cov"
  while IFS="$_FI_TAB" read -r r rs ls <&3; do
    { [ "$rs" = "$ls" ] || _fi_git -C "$_FI_D" merge-base --is-ancestor "$rs" "$ls" 2>/dev/null; } && printf '%s\n' "$r" >> "$T/cov"
  done 3< "$T/covp"
  awk -F'\t' -v OFS='\t' -v r="$_FI_DEFSHA" -v def="$_FI_DEF" -v dn="${_FI_DEF#origin/}" '
    FILENAME ~ /bad$/ { BD[$1, $2] = 1; next }
    FILENAME ~ /ahead$/ { A[$1] = 1; next } FILENAME ~ /unpushed$/ { X[$1] = 1; next }
    FILENAME ~ /(merged|mheads)$/ { M[$1] = 1; next }
    FILENAME ~ /tips$/ { C[$1] = (r == "" ? 0 : (("a", $1) in BD) ? "u" : !($1 in A)) ((("x", $1) in BD) ? "u" : ($1 in X) + 0) (($1 in M) ? 1 : (("m", "-") in BD) ? "u" : 0); next }
    FILENAME ~ /dates$/ { split($0, x, " "); D[x[1]] = x[2]; next }
    FILENAME ~ /prh$/ { O[$1] = $2; NUM[$1] = $3; ST[$1] = $4; next }
    FILENAME ~ /prs$/ { if ($2 == "OPEN") P[++np] = $0; next }
    FILENAME ~ /cov$/ { CV[$1] = 1; next }
    FILENAME ~ /refs$/ { if ($1 ~ /^refs\/heads\//) { n = substr($1, 12); LB[n] = $2; LD[n] = $3; UP[n] = $4; LO[++nl] = n }
      else if ($1 ~ /^refs\/remotes\// && $5 == "-") { n = substr($1, 14); RB[n] = $2; RD[n] = $3; RO[++nr] = n }; next }
    { W[++nw] = $0; if ($3 != "-") CO[$3] = CO[$3] "\n" $1 }
    function rr(n,    u) { if (("origin/" n) in RB) return "origin/" n
      u = substr(UP[n], 14); return (UP[n] ~ /^refs\/remotes\// && (u in RB) && u != def) ? u : "-" }
    function pk(b, rrr) { return rrr ~ /^origin\// ? substr(rrr, 8) : b }
    function gn(n,    u) { u = substr(UP[n], 14)   # the upstream, when its remote-tracking ref is gone
      return (UP[n] ~ /^refs\/remotes\// && !(u in RB) && !(("origin/" n) in RB)) ? u : "-" }
    function out(k, ref, sha, b, d, rrr, fl, sh, ptx, pn, ps,    p) { p = pk(b, rrr)
      print k, ref, sha, b, (d == "" ? "-" : d), ((sha in C) ? C[sha] : "---"), rrr, \
        (k == "pr" ? ptx "\t" pn "\t" ps : (b == "-" || b == dn || !(p in NUM) ? "-\t-\t-" : O[p] "\t" NUM[p] "\t" ST[p])), fl, (sh == "" ? "-" : sh), \
        ((k == "worktree" || k == "branch") && b != "-" ? gn(b) : "-") }
    END {
      for (i = 1; i <= nw; i++) { split(W[i], w, "\t"); if (w[4] ~ /bare/) continue
        m = split(CO[w[3]], S, "\n"); o = ""; for (j = 2; j <= m; j++) if (S[j] != w[1]) o = o " " S[j]
        out("worktree", w[1], w[2], w[3], D[w[2]], (w[3] == "-" ? "-" : rr(w[3])), w[4], (w[3] == "-" ? "" : substr(o, 2))) }
      for (i = 1; i <= nl; i++) { n = LO[i]; if (!(n in CO)) out("branch", n, LB[n], n, LD[n], rr(n), "-", ""); if (pk(n, rr(n)) != dn) PB[pk(n, rr(n))] = 1 }
      for (i = 1; i <= nr; i++) { n = RO[i]; b = substr(n, 8)
        if (n !~ /^origin\// || n == def || (n in CV) || (O[b] != "" && O[b] != "-")) continue
        out("remote", n, RB[n], b, RD[n], n, "-", "") }
      for (i = 1; i <= np; i++) { split(P[i], p, "\t"); if (p[10] == 1 || !(p[3] in PB)) out("pr", "#" p[1], p[4], p[3], p[5], "-", (p[10] == 1 ? "cross" : "-"), "", p[11], p[1], p[2]) } }' \
    "$T/bad" "$T/ahead" "$T/unpushed" "$T/merged" "$T/mheads" "$t" "$T/dates" "$T/prh" "$T/prs" "$T/cov" "$T/refs" "$T/wt" > "$T/items"
}

# Whether a tip's content is on the default branch: _FI_LV is landed, partly,
# not or unknown, and _FI_L the same with what it says for a detail. What it
# changed since its merge-base, "path blob", goes to $T/sig. Arguments: the
# tip, its class and whether a PR with its head was listed. Rule 3 compares
# with the default branch's current blobs, so a squash-merged branch whose
# paths main edited since reads not or partly: on a tip some remote-tracking
# ref holds (class ?0?), when the PR lists could not settle it, that is unknown.
_fi_land() {
  local mb
  : > "$T/sig"; _FI_L=unknown; _FI_LV=unknown
  [ -n "$_FI_DEFSHA" ] || return 0
  case "$2" in 1??|??1) _FI_L=landed; _FI_LV=landed; return 0 ;; u??) return 0 ;; esac
  mb="$(_fi_git -C "$_FI_D" merge-base "$_FI_DEFSHA" "$1" 2>/dev/null)" || return 0
  _fi_git -C "$_FI_D" diff-tree -r --no-renames -z "$mb" "$1" > "$T/dtz" 2>/dev/null || return 0
  _FI_L="$(tr '\000' '\n' < "$T/dtz" | awk -v df="$T/deftree" -v sig="$T/sig" -v def="$_FI_DEF" '
    BEGIN { while ((getline l < df) > 0) { i = index(l, "\t"); B[substr(l, 1, i - 1)] = substr(l, i + 1) } }
    /^:/ { split($0, m, " "); dst = m[4]; next }
    { n++; print $0 "\t" dst > sig; if (dst ~ /^0+$/ ? !($0 in B) : B[$0] == dst) eq++ }
    END { if (!n || eq == n) printf "landed"; else printf "%s on %s (%s%d changed path%s)", (eq ? "partly" : "not"), def, (eq ? eq " of " : ""), n, (n > 1 ? "s" : "") }')"
  _FI_LV="${_FI_L%% *}"
  case "$_FI_LV:$2" in
    not:?0?|partly:?0?) if [ "$_FI_GHOK" = 0 ] || { [ "$_FI_GHTRUNC" = 1 ] && [ "${3:-0}" != 1 ]; }; then _FI_L=unknown; _FI_LV=unknown; fi ;;
  esac
  # A merged head whose history could not be walked might have landed it.
  case "$_FI_LV:$2" in not:??u|partly:??u) _FI_L=unknown; _FI_LV=unknown ;; esac
}

# The host's answer for a directory, as _FI_H: owner mtime live question
# blocked note helper; the note, if any, joins the detail. The line is read by
# position, an empty field kept in its place: a tab is IFS whitespace, so a
# tab-IFS split drops one and moves every later field left (contract C8.1).
_fi_host() {
  local x="unknown${_FI_TAB}-${_FI_TAB}unknown${_FI_TAB}unknown${_FI_TAB}unknown${_FI_TAB}-" i=0
  [ "$_FI_HOSTOK" = 1 ] && x="$(felix_inv_host_dir "$1" "$_FI_NOW" "$_FI_LIVE" "$_FI_BLOCKED" "$T/hscope")"
  _FI_H=()
  while :; do
    _FI_H[i]="${x%%"$_FI_TAB"*}"
    case "$x" in *"$_FI_TAB"*) x="${x#*"$_FI_TAB"}"; i=$((i + 1)) ;; *) break ;; esac
  done
  [ "${#_FI_H[@]}" -ge 6 ] || _FI_H=(unknown - unknown unknown unknown "the host adapter answered nothing")
  [ -n "${_FI_H[0]}" ] || _FI_H[0]=unknown   # an empty owner is not "no session ran here"
  [ "${_FI_H[5]}" = - ] || _fi_add "${_FI_H[5]}"
  _fi_helper "$1"
}
# Whether a directory is a helper's, as _FI_HLP (yes, no or unknown): the
# adapter's seventh field in _FI_H. With none (--no-host, no records, a short
# line) or a word that is not one of the three, the adapter's name test decides:
# a helper's name is unknown, any other no. The rule for the name stays there.
_fi_helper() {
  case "${_FI_H[6]:-}" in
    yes|no|unknown) _FI_HLP="${_FI_H[6]}" ;;
    *) if felix_inv_host_helper_form "$1"; then _FI_HLP=unknown; else _FI_HLP=no; fi ;;
  esac
}

# The branch-borne states of a tip, into _FI_UNP _FI_UNPROP _FI_PRO _FI_PRC, and
# its content into _FI_L and _FI_LV. Arguments: tip, branch or -, its
# remote-tracking ref or -, class, open PRs or -, newest PR number and state or -,
# and the upstream whose remote-tracking ref is gone, or -.
_fi_branch() {
  _fi_branch0 "$@"
  _fi_carry "$1" "$3" "$2"
}
_fi_branch0() {
  local tip="$1" br="$2" rr="$3" cl="$4" op="$5" num="$6" st="$7" gn="${8:--}" n hp=0
  _FI_UNP=no; _FI_UNPROP=no; _FI_PRO=no; _FI_PRC=no
  [ "$br" = - ] || [ "$br" = "${_FI_DEF#origin/}" ] || [ "$num" = - ] || hp=1
  _fi_land "$tip" "$cl" "$hp"
  case "$cl" in ?1?)
    case "$_FI_LV" in landed) ;; unknown) _FI_UNP=unknown ;;
      # 0 means it was pushed after the classes were read: the newer fact wins.
      *) n="$(_fi_git -C "$_FI_D" rev-list --count "$tip" --not --remotes 2>/dev/null)"
         [ "${n:-1}" = 0 ] || { _FI_UNP=yes; _fi_add "${n:-some} commit(s) on no remote; content $_FI_L"; } ;; esac ;;
    ?u?) [ "$_FI_LV" = landed ] || _FI_UNP=unknown ;;
  esac
  # A pruned upstream leaves no remote copy of the branch: it counts as not pushed.
  [ "$gn" = - ] || [ "$_FI_LV" = landed ] || _fi_add "upstream $gn is gone"
  _FI_DETP="$_FI_DET"   # what _fi_carry keeps when another pushed branch holds the tip
  [ "$br" != - ] && [ "$br" != "${_FI_DEF#origin/}" ] || return 0   # the default branch heads no PR
  if [ "$_FI_GHOK" = 0 ]; then
    [ "$rr" != - ] || return 0
    _FI_PRO=unknown
    [ "$_FI_LV" = landed ] && return 0
    _FI_UNPROP=unknown; _FI_PRC=unknown
    [ "$_FI_LV" = unknown ] || [ "$_FI_UNP" = yes ] || _fi_add "on $rr; content $_FI_L"
    return 0
  fi
  [ "$num" != - ] || [ "$rr" != - ] || return 0
  [ "$op" = - ] || { _FI_PRO=yes; _fi_add "$op"; return 0; }
  [ "$_FI_LV" != landed ] || return 0
  if [ "$st" = CLOSED ]; then
    if [ "$_FI_LV" = unknown ]; then _FI_PRC=unknown; else _FI_PRC=yes; _fi_add "#$num closed without merge; content $_FI_L"; fi
  elif [ "$num" != - ]; then   # the newest PR merged: no remote-tracking ref is needed for what came after
    if [ "$_FI_LV" = unknown ]; then _FI_UNPROP=unknown
    else n="no PR since #$num merged; content $_FI_L"; [ "$rr" = - ] || n="on $rr, $n"; _FI_UNPROP=yes; _fi_add "$n"; fi
  elif [ "$rr" != - ]; then
    if [ "$_FI_LV" = unknown ]; then _FI_UNPROP=unknown
    elif [ "$_FI_GHTRUNC" = 1 ]; then _FI_UNPROP=unknown; _fi_add "on $rr, no PR among the $_FI_GHN gh listed, which may not be all; content $_FI_L"
    else _FI_UNPROP=yes; _fi_add "on $rr with no PR; content $_FI_L"; fi
  fi
}

# ---------------------------------------------------------------- items ----
# One line of $T/items, its fields read by _fi_repo's loop.
_fi_item() {
  local own=- lv=no x
  _FI_DET=""; : > "$T/dsig"
  case "$k" in
    worktree) _fi_worktree; return 0 ;;
    pr) _FI_DET="head $br @ ${sha:0:8}"; _fi_add "$op"; [ "$fl" != cross ] || _fi_add "from a fork"
        _FI_LV=unknown; : > "$T/sig"; [ "$cl" = --- ] || _fi_land "$sha" "$cl" 1
        if [ "$_FI_HOSTOK" != 1 ]; then own=unknown; lv=unknown
        elif [ "$fl" != cross ]; then
          x="$(awk -F'\t' -v h="$br" '$1 == h { print $2 "\t" $3; exit }' "$T/owners")"
          # No line for the head, though a session file in the window could not be read: unknown, not none.
          # A line with owner - was settled by the adapter: only a plugin's session names the head, and every file was read (audit b09, C028, M1).
          if [ -n "$x" ]; then own="${x%%"$_FI_TAB"*}"; lv="${x#*"$_FI_TAB"}"
          elif [ "${_FI_HUNREAD:-0}" != 0 ]; then own=unknown; lv=unknown; fi
        fi
        _fi_states "$_FI_LV" live=$lv pr-open=yes ;;
    *) _FI_DET="@ ${sha:0:8}"; _fi_branch "$sha" "$br" "$rr" "$cl" "$op" "$num" "$st" "$gn"
       [ "$k" != remote ] || _FI_PRO=no
       _fi_states "$_FI_LV" unpushed=$_FI_UNP unproposed=$_FI_UNPROP pr-open=$_FI_PRO pr-closed-unlanded=$_FI_PRC carried=$_FI_CAR ;;
  esac
  _fi_sig; _fi_age "$dt"; _fi_row "$k" "$ref" "$_FI_S" "$own" "$_FI_A" "$_FI_LV" "$_FI_DET" "$_FI_SIG" "$br"
}

# ---------------------------------------------------------------- output ----
# Two rows of one repository holding unlanded content whose changed paths and
# blobs are the same, on different branches, are each a possible-duplicate, and
# the --tsv detail says of which, naming only rows on other branches than its
# own (origin/X beside X is one branch); the human view's copy of the rows ($_FI_T/outv)
# leaves that tail out, since its states say possible-duplicate and it would
# name another row's path. Then the rows: as TSV, or as lib/inventory-view.sh
# groups them for a person.
_fi_out() {
  awk -F'\t' -v OFS='\t' -v vf="$_FI_T/outv" '{ R[NR] = $0 }
    $9 != "-" && $4 ~ /(^|,)(uncommitted|unpushed|unproposed|pr-open|pr-closed-unlanded)(,|$)/ {
      k = $2 SUBSEP $9; D[NR] = k; if (!((k, $10) in B)) { B[k, $10] = 1; NB[k]++ }; W[k] = W[k] "\n" $3; WB[k] = WB[k] "\n" $10 }
    END { for (i = 1; i <= NR; i++) { split(R[i], f, "\t")
        if ((i in D) && NB[D[i]] > 1) { m = split(W[D[i]], L, "\n"); split(WB[D[i]], LB, "\n"); o = ""; for (j = 2; j <= m; j++) if (LB[j] != f[10]) o = o " " L[j]
          p = index(f[4], "unknown:"); f[4] = p ? substr(f[4], 1, p - 1) "possible-duplicate," substr(f[4], p) : f[4] ",possible-duplicate"
          print f[1], f[2], f[3], f[4], f[5], f[6], f[7], f[8] > vf; f[8] = f[8] "; possible duplicate of" o }
        else print f[1], f[2], f[3], f[4], f[5], f[6], f[7], f[8] > vf
        print f[1], f[2], f[3], f[4], f[5], f[6], f[7], f[8] } }' "$_FI_T/rows" > "$_FI_T/out"
  if [ "$1" = 1 ]; then cat "$_FI_T/out"; else _fi_view; fi
}
