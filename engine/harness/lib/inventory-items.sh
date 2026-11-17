# felix inventory's items: what is read of one worktree (its changed paths,
# whether its index holds the undoing of a merge), the pending handoff
# sections, and the chips, for lib/inventory.sh, which sources nothing else
# about a directory. Read-only as the rest is: every git call is _fi_git.

# How a worktree's changed paths stand, as _FI_DD: "differ changed innoobject
# filtered", or unknown. Each changed path's working blob, "path blob", goes
# to $T/dsig. A path under a filter driver, switched off here, is compared
# raw against a cleaned blob, so it is counted apart, as not known. In the
# main worktree, what lies inside a linked worktree or an orphan ($T/nest) is
# theirs, not its.
_fi_dirty() {
  local wt="$1" p k d; local -a nf=()
  : > "$T/dsig"; : > "$T/dfl"; : > "$T/fp"; _FI_DD=unknown
  _fi_git -C "$wt" config --name-only --get-regexp '^filter\.' > "$T/fk" 2>/dev/null
  while IFS= read -r k <&3; do d="${k#filter.}"; d="${d%.*}"
    grep -qxF -- "$d" "$T/dfl" || { printf '%s\n' "$d" >> "$T/dfl"; nf=(${nf[@]+"${nf[@]}"} -c "filter.$d.clean=" -c "filter.$d.process=" -c "filter.$d.required=false"); }
  done 3< "$T/fk"
  _fi_git -C "$wt" ${nf[@]+"${nf[@]}"} status --porcelain=v1 -z --no-renames --untracked-files=all --ignore-submodules=dirty > "$T/stz" 2>/dev/null || return 0
  tr '\000' '\n' < "$T/stz" | if [ "$wt" = "$_FI_MAIN" ] && [ -s "$T/nest" ]; then
    awk 'NR == FNR { N[++n] = $0; next } { p = substr($0, 4); sub(/\/$/, "", p); for (i = 1; i <= n; i++) if (p == N[i] || index(p, N[i] "/") == 1) next; print }' "$T/nest" -
  else cat; fi > "$T/st"
  [ -n "$_FI_DEFSHA" ] || return 0   # clean or not, what it differs from is unknown (spec 4.4)
  [ -s "$T/st" ] || { _FI_DD="0 0 0 0"; return 0; }
  : > "$T/hp"; : > "$T/dx"
  while IFS= read -r p <&3; do
    p="${p:3}"
    if [ -L "$wt/$p" ]; then printf '%s\t%s\n' "$p" "$(printf '%s' "$(readlink "$wt/$p")" | _fi_git hash-object --stdin)" >> "$T/dx"
    elif [ -f "$wt/$p" ]; then printf '%s\n' "$p" >> "$T/hp"
    elif [ -e "$wt/$p" ]; then printf '%s\t(a repository)\n' "${p%/}" >> "$T/dx"
    else printf '%s\t0\n' "$p" >> "$T/dx"; fi
  done 3< "$T/st"
  _fi_git -C "$wt" hash-object --no-filters --stdin-paths < "$T/hp" > "$T/hh" 2>/dev/null || : > "$T/hh"
  { paste "$T/hp" "$T/hh"; cat "$T/dx"; } | LC_ALL=C sort > "$T/dsig"
  [ -s "$T/dfl" ] && cut -f1 "$T/dsig" | tr '\n' '\000' | _fi_git -C "$wt" check-attr -z --stdin filter 2>/dev/null | tr '\000' '\n' \
    | awk -v fl="$T/dfl" 'BEGIN { while ((getline l < fl) > 0) F[l] = 1 } NR % 3 == 1 { p = $0 } NR % 3 == 0 && ($0 in F) { print p }' > "$T/fp"
  _FI_DD="$(awk -F'\t' -v df="$T/deftree" -v fp="$T/fp" -v db="$T/db" 'BEGIN { printf "" > db
      while ((getline l < df) > 0) { i = index(l, "\t"); B[substr(l, 1, i - 1)] = substr(l, i + 1) }; while ((getline l < fp) > 0) F[l] = 1 }
    { n++; if ($2 == "0" ? !($1 in B) : B[$1] == $2) next
      if ($2 != "0" && ($1 in F)) { f++; next }
      d++; if ($2 ~ /^[0-9a-f]+$/) print $2 > db }
    END { printf "%d %d %d", d, n, f }' "$T/dsig")"
  k="$(_fi_git -C "$wt" cat-file --batch-check < "$T/db" 2>/dev/null | grep -c ' missing$')"
  set -- $_FI_DD; _FI_DD="$1 $2 ${k:-0} $3"
}

# Whether ref (a directory) is the top of a working tree of this repository:
# 0 it is, 1 it holds none of its own (git would read an enclosing one), 2 it
# is now another repository's.
_fi_own() {
  local x
  x="$(_fi_git -C "$1" rev-parse --show-toplevel --git-common-dir 2>/dev/null)" || return 1
  [ "${x%%"$_FI_NL"*}" = "$(cd "$1" 2>/dev/null && pwd -P)" ] || return 1
  [ "$(cd "$1" && cd "${x#*"$_FI_NL"}" 2>/dev/null && pwd -P)" = "$_FI_COMMON" ] || return 2
}
_fi_worktree() {
  local shd=no rev=no unc=no orph=no x when="$dt" ucv=landed content
  if [ "$br" != - ]; then _fi_add "branch $br @ ${sha:0:8}"; else _fi_add "detached @ ${sha:0:8}"; fi
  x="${fl//detached,/}"; x="${x//linebreak,/}"; x="${x%,}"; [ "$x" = - ] || [ -z "$x" ] || _fi_add "git marks it ${x//,/ and }"
  [ "$sh" = - ] || { shd=yes; _fi_add "$br is also checked out in $sh"; }
  _FI_H=(unknown - unknown unknown unknown -)
  case "$fl" in
    *linebreak*) unc=unknown; ucv=unknown; _fi_add "its path holds a line break or a tab, so it is not read"
                 _fi_helper "$ref" ;;   # a path never read is no search: a helper's name stays unknown
    *) if [ ! -d "$ref" ]; then _fi_add "the directory is gone"
       else _fi_own "$ref"; x=$?
         if [ "$x" = 2 ]; then unc=unknown; ucv=unknown; _fi_add "it is now a checkout of another repository, so it is not read"
         elif [ "$x" = 1 ]; then orph=yes; _fi_uniq "$ref"; _fi_add "git lists it, but it holds no working tree of this repository: $_FI_UQ"
         else _fi_revert; _fi_dirty "$ref"; _fi_dd; fi
       fi
       _fi_host "$ref" ;;
  esac
  _fi_branch "$sha" "$br" "$rr" "$cl" "$op" "$num" "$st" "$gn"
  _fi_sig; ! _fi_temp "$ref" || _fi_add temp
  case "$when" in *[!0123456789]*|'') when=0 ;; esac
  case "${_FI_H[1]}" in *[!0123456789]*|'') ;; *) [ "${_FI_H[1]}" -gt "$when" ] && when="${_FI_H[1]}" ;; esac
  # A directory that holds no working tree of this repository is read as an orphan is.
  if [ "$orph" = yes ]; then content="$_FI_OC"; else _fi_worse "$_FI_LV" "$ucv"; content="$_FI_W"; fi
  _fi_states "$content" hazard:shared-branch=$shd hazard:staged-revert=$rev live="${_FI_H[2]}" question="${_FI_H[3]}" blocked="${_FI_H[4]}" \
    uncommitted=$unc unpushed=$_FI_UNP unproposed=$_FI_UNPROP pr-open=$_FI_PRO pr-closed-unlanded=$_FI_PRC carried=$_FI_CAR orphan=$orph helper=$_FI_HLP
  _fi_age "$when"; _fi_row worktree "$ref" "$_FI_S" "${_FI_H[0]}" "$_FI_A" "$content" "$_FI_DET" "$_FI_SIG" "$br"
}
# _FI_DD as the worktree's uncommitted state (unc), its content (ucv: none of
# the paths differ landed, all of those compared differ not, else partly; a path
# under a filter driver is not compared, so nothing else differing is unknown)
# and detail.
_fi_dd() {
  [ "$_FI_DD" != unknown ] || { unc=unknown; ucv=unknown; return 0; }
  set -- $_FI_DD
  if [ "$1" -gt 0 ]; then unc=yes; if [ $(($2 - $1 - $4)) -gt 0 ]; then ucv=partly; else ucv=not; fi
    _fi_add "uncommitted: $1 of $2 changed paths differ from $_FI_DEF, $3 of them holding content in no object$([ "$_FI_PARTIAL" = 0 ] || echo ' this clone holds')"
  elif [ "$4" -gt 0 ]; then unc=unknown; ucv=unknown
  elif [ "$2" -gt 0 ]; then _fi_add "$2 changed paths, all as $_FI_DEF has them"; fi
  [ "$4" = 0 ] || _fi_add "$4 changed-looking paths under a filter driver not compared, since the filter would have to run"
}
# The index differs from HEAD (status 1; 128 is an unborn HEAD): does it hold
# the tree of an earlier tip of the branch, or, detached, of an earlier HEAD?
# A read that fails otherwise (the index, the reflog, a tree or a tip the clone
# lacks) leaves the answer unknown, not no.
_fi_revert() {
  local lr=HEAD w="HEAD here" c t rc unk=0 f
  [ "$br" = - ] || { lr="refs/heads/$br"; w="$br"; }
  _fi_git -C "$ref" diff-index --cached --quiet HEAD -- 2>/dev/null; rc=$?
  [ "$rc" != 0 ] || return 0
  [ "$rc" = 1 ] || { _fi_git -C "$ref" rev-parse -q --verify 'HEAD^{commit}' >/dev/null 2>&1 && rev=unknown; return 0; }
  _fi_git -C "$ref" reflog exists "$lr" 2>/dev/null || { rev=unknown; return 0; }
  _fi_git -C "$ref" log -g --format='%H %T' "$lr" -- > "$T/rlg" 2>/dev/null || { rev=unknown; return 0; }
  # log -g skips an entry whose commit the clone lacks, with status 0: fewer printed than the reflog holds is a tip not read.
  f="$(_fi_git -C "$ref" rev-parse --git-path "logs/$lr" 2>/dev/null)"; case "$f" in /*) ;; *) f="$ref/$f" ;; esac
  [ ! -f "$f" ] || [ "$(wc -l < "$f" | tr -d ' ')" -le "$(wc -l < "$T/rlg" | tr -d ' ')" ] || unk=1
  awk -v t="$(_fi_git -C "$ref" rev-parse -q --verify 'HEAD^{tree}' 2>/dev/null)" '$2 != t && !s[$2]++' "$T/rlg" | head -100 > "$T/rl"
  while read -r c t <&3; do
    _fi_git -C "$ref" diff-index --cached --quiet "$t" -- 2>/dev/null; rc=$?
    [ "$rc" = 0 ] || { [ "$rc" = 1 ] || unk=1; continue; }
    _fi_git -C "$ref" merge-base --is-ancestor HEAD "$c" 2>/dev/null; rc=$?
    [ "$rc" != 0 ] || continue
    [ "$rc" = 1 ] || { unk=1; continue; }
    rev=yes; _fi_add "the index is the tree of ${c:0:8}, an earlier tip of $w: a commit here undoes what came after it"; break
  done 3< "$T/rl"
  [ "$rev" = yes ] || [ "$unk" = 0 ] || rev=unknown
}

# Whether another pushed branch already holds a tip (A1, "carried"), after
# _fi_branch0 has read the tip's own states: _FI_CAR is yes or no, and when yes
# the row holds neither unproposed nor pr-closed-unlanded, nor their unknown
# entries, and its detail is what it was before the pull request reading, plus
# "carried by ...". The carriers are the refs/remotes/origin refs but origin/HEAD
# and the default branch. A local branch or worktree is carried by one whose tip
# equals or descends from its own and that is not its own name on origin nor its
# upstream; but when either of those two stands at its tip, the work is already
# on origin under its own name, and only a strict descendant carries it, as for a
# remote row (a remote row only by a strict descendant that is not itself): two
# names pushed at one commit then carry neither the other, and some row always
# remains to say the work needs a PR. Arguments: the tip, its remote-tracking ref
# or -, and its branch or -.
_fi_carry() {
  local self="" n cn cs h rem=0
  local -a pats=(refs/remotes/origin)
  _FI_CAR=no
  [ "$_FI_LV" != landed ] && [ "$_FI_PRO" != yes ] || return 0
  [ "$2" = - ] || self="refs/remotes/$2"
  # The local branch itself rides along (it holds its own tip) to say its upstream.
  if [ "$k" = remote ]; then rem=1; elif [ "${3:--}" != - ]; then pats[1]="refs/heads/$3"; fi
  _fi_git -C "$_FI_D" for-each-ref --contains="$1" --format='%(refname) %(objectname) %(upstream)' "${pats[@]}" 2>/dev/null \
    | awk -v self="$self" -v def="refs/remotes/$_FI_DEF" -v tip="$1" -v remote="$rem" -v hb="refs/heads/${3:--}" '
        $1 == hb { up = $3; next }
        { L[++n] = $1; S[n] = $2 }
        END { strict = remote
          for (i = 1; i <= n; i++) if ((L[i] == self || (up != "" && L[i] == up)) && S[i] == tip) strict = 1
          for (i = 1; i <= n; i++) {
            if (L[i] == "refs/remotes/origin/HEAD" || L[i] == def || L[i] == self || (up != "" && L[i] == up)) continue
            if (strict && S[i] == tip) continue
            print substr(L[i], 21) "\t" S[i] } }' > "$T/car"
  [ -s "$T/car" ] || return 0
  n="$(awk 'END { print NR }' "$T/car")"
  if [ "$n" -gt 1 ]; then   # only the outermost: one that another carrier's tip strictly descends from is left out
    : > "$T/car.d"; mkdir -p "$T/cc"
    while IFS="$_FI_TAB" read -r cn cs <&3; do
      [ -s "$T/cc/$cs" ] || _fi_git -C "$_FI_D" for-each-ref --contains="$cs" --format='%(objectname)' refs/remotes/origin 2>/dev/null > "$T/cc/$cs"
      awk -v cs="$cs" -v cf="$T/cc/$cs" 'FILENAME == cf { if ($1 != cs) D[$1] = 1; next } { if ($2 in D) f = 1 } END { exit f }' "$T/cc/$cs" "$T/car" || continue
      printf '%s\t%s\n' "$cn" "$cs" >> "$T/car.d"
    done 3< "$T/car"
    cp "$T/car.d" "$T/car"
  fi
  [ -f "$T/prnum" ] || awk -F'\t' '$2 == "OPEN" && $10 != 1 && $1 + 0 > N[$3] + 0 { N[$3] = $1 } END { for (h in N) printf "%s\t%s\n", h, N[h] }' "$T/prs" > "$T/prnum"
  # #n carriers by ascending number, then origin/<name> by name, three named, the rest counted.
  h="$(awk -F'\t' -v pf="$T/prnum" '
    FILENAME == pf { PN[$1] = $2; next }
    { if ($1 in PN) P[++np] = PN[$1] + 0; else O[++no] = "origin/" $1 }
    END { for (i = 2; i <= np; i++) for (j = i; j > 1 && P[j] < P[j - 1]; j--) { x = P[j]; P[j] = P[j - 1]; P[j - 1] = x }
      for (i = 2; i <= no; i++) for (j = i; j > 1 && O[j] < O[j - 1]; j--) { x = O[j]; O[j] = O[j - 1]; O[j - 1] = x }
      for (i = 1; i <= np; i++) L[++t] = "#" P[i]; for (i = 1; i <= no; i++) L[++t] = O[i]
      for (i = 1; i <= t && i <= 3; i++) printf "%s%s", (i > 1 ? ", " : ""), L[i]
      if (t > 3) printf ", and %d more", t - 3 }' "$T/prnum" "$T/car")"
  [ -n "$h" ] || return 0
  _FI_CAR=yes; _FI_UNPROP=no; _FI_PRC=no; _FI_DET="$_FI_DETP"; _fi_add "carried by $h"
}

# The pending directory's section files in the default branch's tree (else
# HEAD's) into $T/pend. A listing that fails is no list of none: _FI_PENDFAIL,
# which the default cover row says. An unborn HEAD holds nothing to list.
_fi_pending() {
  local tree="${_FI_DEFSHA:-HEAD}"
  : > "$T/pend"; _FI_PENDFAIL=0
  _fi_git -C "$_FI_D" rev-parse -q --verify "$tree^{commit}" >/dev/null 2>&1 || return 0
  _fi_git -C "$_FI_D" ls-tree --name-only "$tree" -- "$_FI_PENDING/" > "$T/pend0" 2>/dev/null || { _FI_PENDFAIL=1; return 0; }
  grep '\.md$' "$T/pend0" > "$T/pend"
  return 0
}
# Each section waiting there with its "Next" items; a section this clone
# cannot read says so.
_fi_handoff() {
  local tree="${_FI_DEFSHA:-HEAD}" f next when
  while IFS= read -r f <&3; do
    if _fi_git -C "$_FI_D" cat-file -p "$tree:$f" > "$T/hsec" 2>/dev/null; then next="$(awk '
      function add(x) { I[++n] = x; st = 1 }
      { t = $0; sub(/^[#*_ ]+/, "", t) }
      t ~ /^Next([^A-Za-z]|$)/ { on = 1; st = 0; if (sub(/^[^:]*:[*_ ]*/, "", t) && t != "") add(t); next }
      on && /^[ \t]*$/ { if (st) on = 0; next }
      on && /^ ? ? ?([-*+]|[0-9]+[.)]) / { l = $0; sub(/^ *([-*+]|[0-9]+[.)]) +/, "", l); add(l); next }
      on && st && /^  / { l = $0; sub(/^ +/, "", l); I[n] = I[n] " " l; next }
      { on = 0 }
      END { if (n) printf "%d Next item(s): ", n; for (i = 1; i <= n; i++) printf "%s%s", (i > 1 ? " | " : ""), I[i] }' "$T/hsec")"
      next="${next:-no Next lines}"
    else next="its Next lines are unknown: this clone cannot read the section"; fi
    when="$(_fi_git -C "$_FI_D" log -1 --format=%ct "$tree" -- "$f" 2>/dev/null)"; _fi_age "$when"
    _fi_row handoff "$f" handoff-pending - "$_FI_A" - "$next" - -
  done 3< "$T/pend"
}

# Chips from sessions in every worktree, every orphan, and every directory
# under a directory inside the main worktree that holds worktrees, into $T/chips,
# read before the cover rows are written: _FI_CHU is how many session files the
# run could not read left a chip unknown, which the chips cover row says.
_fi_chipsread() {
  _FI_CHU=0; : > "$T/chips"
  [ "$_FI_HOSTOK" = 1 ] || return 0
  mkdir -p "$T/hc"; felix_inv_host_chips "$_FI_NOW" "$_FI_DAYS" "$T/hscope" "$T/chipu" "$T/hc" > "$T/chips" || : > "$T/chips"
  awk -F'\t' '$4 == "unknown" { f = 1 } END { exit !f }' "$T/chips" && _FI_CHU="$(cat "$T/chipu" 2>/dev/null)"
  case "$_FI_CHU" in ''|*[!0123456789]*) _FI_CHU=0 ;; esac
  return 0
}
_fi_chips() {
  local id s e u title
  # u is "unknown" for a chip that a session file the run could not read may have started.
  while IFS="$_FI_TAB" read -r id s e u title <&3; do
    _fi_age "$e"; _fi_row chip "$id" "$([ "$u" != unknown ] || printf 'unknown:')chip-unstarted" "$s" "$_FI_A" - "$title" - -
  done 3< "$T/chips"
}
# The host's record directories for this repository's worktrees, orphans and
# removed worktrees, into $T/hscope, and whether there are any records to read
# (_FI_HOSTOK; _FI_HD says why not).
_fi_hscope() {
  local -a a=("$_FI_REPO"); local d
  _FI_HOSTOK=0; _FI_HD="--no-host"; _FI_HUNREAD=0
  [ "$_FI_HOST" = 1 ] || return 0
  _FI_HD="$(felix_inv_host_where)" || { _FI_HD="no session records"; return 0; }
  # A root that is there but cannot be listed and entered is not an empty one: nothing is read (audit b09, C047).
  felix_inv_host_open || { _FI_HD="$_FI_HD could not be read"; return 0; }
  _FI_HOSTOK=1
  while IFS= read -r d <&3; do a[${#a[@]}]="$d"; done 3< <(awk -F'\t' '$4 !~ /bare|linebreak/ { print $1 }' "$T/wt"; cut -f1 "$T/orph"; cat "$T/scope")
  felix_inv_host_scope "$T/hscope" "${a[@]}"
  # Session files the run cannot read are said, and what they could have decided is unknown.
  _FI_HUNREAD="$(felix_inv_host_unread "$_FI_DAYS" "$T/hscope")"
  [ "${_FI_HUNREAD:-0}" = 0 ] || _FI_HD="$_FI_HD; $_FI_HUNREAD session files could not be read"
}
# The session behind each open PR that is a row of its own (one from a fork has
# none), into $T/owners: head, session, live.
_fi_owners() {
  : > "$T/owners"; [ "$_FI_HOSTOK" = 1 ] || return 0
  awk -F'\t' '$1 == "pr" && $11 != "cross" { print $4 }' "$T/items" | LC_ALL=C sort -u > "$T/prheads"
  [ -s "$T/prheads" ] || return 0
  felix_inv_host_owners "$_FI_NOW" "$_FI_DAYS" "$_FI_LIVE" "$T/hscope" "$T/prheads" > "$T/owners" 2>/dev/null
  return 0
}
# File times, for the host adapter (lib/inventory-host.sh) and whatever replaces it.
# A file's mtime as an epoch, or nothing.
_fi_mtime() { local e; e="$(date -r "$1" +%s 2>/dev/null)"; case "$e" in ''|*[!0123456789]*) ;; *) printf '%s' "$e" ;; esac; }
# _fi_newest MINDEPTH MIN DIR...: the newest file at depth MINDEPTH or more
# under the directories modified within MIN minutes, or nothing: found by -mmin,
# sorted by ls -t, and asked again until none is newer (ls takes long lists in batches).
_fi_newest() {
  local md="$1" min="$2" x y i=0; shift 2
  x="$(find "$@" -mindepth "$md" -type f -mmin -"$min" -exec ls -dt {} + 2>/dev/null | head -n 1)"
  [ -n "$x" ] || return 0
  while [ "$i" -lt 8 ]; do
    y="$(find "$@" -mindepth "$md" -type f -newer "$x" -exec ls -dt {} + 2>/dev/null | head -n 1)"
    [ -n "$y" ] || break; x="$y"; i=$((i + 1))
  done
  printf '%s' "$x"
}
