# tests/lib/lost-work.sh: the lost-work page's shared fixture, its stubs and helpers, and the builders
# parts 1450-1490 share. Moved for gate friction C from parts/1450-lost-work-inventory-carried-blind.sh:
# lines 23-27, 29-77 and 101, 118, 171, 197, 221, 239 (the base directories, the stubs, and the variables the helpers read),
# now the body of _lw_build, and lines 28 and 78-247 less those variables (_lw_put to _lw_order),
# verbatim; from parts/1470-lost-work-page-groups-blind.sh: lines 13-57 (the page fixture pg) and 202
# (LW_HEAD), now the body of _lw_pg_build, and _lw_n16 (72-73) and _lw_norm (110), which 1480 also
# calls, verbatim. Definitions only. Each of 1450-1490 calls _lw_build, which sets the variables of
# $TMP/lost-work and makes its directories and stubs when they are not there, so each part runs
# alone. 1470 and 1480 then call _lw_pg_build: in the serial run 1470 builds pg and 1480 finds
# it as 1470 left it, which 1470's runs do not change (its B9.34 checks that); alone, 1480 builds it.

_lw_put() { mkdir -p "${1%/*}" && LC_ALL=C sed "s#@LW@#$LW#g" > "$1" && chmod +x "$1"; }

# ---- the fixture's git ------------------------------------------------------
# Every git command goes through _fx_git, with a fixture HOME and author.
_lwg() { local d="$1"; shift
         HOME="$LW/fxhome" XDG_CONFIG_HOME="$LW/fxhome/.config" GIT_CONFIG_NOSYSTEM=1 \
         GIT_AUTHOR_NAME=Fixture GIT_AUTHOR_EMAIL=fixture@example.invalid \
         GIT_COMMITTER_NAME=Fixture GIT_COMMITTER_EMAIL=fixture@example.invalid \
         _fx_git "$d" -c init.defaultBranch=main -c advice.detachedHead=false "$@"; }
_lwq() { _lwg "$1" rev-parse -q --verify "$2" 2>/dev/null; }
_lw_repo() {  # NAME: $LW/github.com/fixture/NAME.git and $LW/NAME cloned from it, main pushed with one commit
  local n="$1" o="$LW/github.com/fixture/$1.git"
  mkdir -p "$o"
  _lwg "$o" init -q --bare >/dev/null 2>&1; _lwg "$o" symbolic-ref HEAD refs/heads/main >/dev/null 2>&1
  _lwg "$LW" clone -q "$o" "$n" >/dev/null 2>&1
  _lwg "$LW/$n" symbolic-ref HEAD refs/heads/main >/dev/null 2>&1
  printf '%s\n' "$n" > "$LW/$n/README.md"
  _lwg "$LW/$n" add -A >/dev/null 2>&1; _lwg "$LW/$n" commit -qm "the first $n" >/dev/null 2>&1
  _lwg "$LW/$n" push -q -u origin main >/dev/null 2>&1
  _lwg "$LW/$n" remote set-head origin main >/dev/null 2>&1
}
_lw_mainwt() { _lwg "$1" worktree list --porcelain 2>/dev/null | LC_ALL=C awk 'NR == 1 { sub(/^worktree /, ""); print }'; }
# A commit no checkout holds: the parent's top-level tree with NAME set to
# CONTENT for each pair, made with mktree and commit-tree. -> LWC
_lw_mk() {  # REPO PARENT MESSAGE NAME CONTENT [NAME CONTENT]...
  local r="$1" p="$2" m="$3" b t; shift 3
  _lwg "$r" ls-tree "$p" > "$LW/mk.tree" 2>/dev/null
  while [ $# -ge 2 ]; do
    b="$(printf '%s\n' "$2" | _lwg "$r" hash-object -w --stdin)"
    LC_ALL=C awk -F'\t' -v n="$1" '$2 != n' "$LW/mk.tree" > "$LW/mk.tmp"; mv "$LW/mk.tmp" "$LW/mk.tree"
    printf '100644 blob %s\t%s\n' "$b" "$1" >> "$LW/mk.tree"
    shift 2
  done
  t="$(_lwg "$r" mktree < "$LW/mk.tree")"
  LWC="$(_lwg "$r" commit-tree "$t" -p "$p" -m "$m")"
}
_lw_anc() { if _lwg "$1" merge-base --is-ancestor "$2" "$3" >/dev/null 2>&1; then printf y; else printf n; fi; }

# ---- pull requests as gh lists them -------------------------------------------
_lw_ago() { local t; t=$(( $(date +%s) - $1 )); date -u -r "$t" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -d "@$t" +%Y-%m-%dT%H:%M:%SZ; }
_lw_cr() { printf '{"__typename":"CheckRun","name":"%s","workflowName":"%s","status":"%s","conclusion":"%s","startedAt":"%s","completedAt":"%s","detailsUrl":"https://example.invalid/%s"}' \
             "$1" "$1" "$2" "$3" "$LW_UPD" "$LW_UPD" "$1"; }
_lw_roll() {
  case "$1" in
    green)   printf '[%s]' "$(_lw_cr gate COMPLETED SUCCESS)" ;;
    red)     printf '[%s,%s]' "$(_lw_cr gate COMPLETED SUCCESS)" "$(_lw_cr lint COMPLETED FAILURE)" ;;
    running) printf '[%s,%s]' "$(_lw_cr gate COMPLETED SUCCESS)" "$(_lw_cr lint IN_PROGRESS '')" ;;
    *)       printf '[]' ;;
  esac
}
_lw_files() {  # "path ..." or @100 for exactly one hundred files
  local s="" f i=1
  if [ "$1" = @100 ]; then
    while [ "$i" -le 100 ]; do printf '%s{"path":"notes/many/f%03d.md","additions":1,"deletions":0}' "$s" "$i"; s=","; i=$((i+1)); done
    return 0
  fi
  for f in $1; do printf '%s{"path":"%s","additions":1,"deletions":0}' "$s" "$f"; s=","; done
}
_lw_labels() { ( IFS=,; s=""; for l in $1; do printf '%s{"id":"LA_%s","name":"%s","description":"","color":"ededed"}' "$s" "$l" "$l"; s=","; done ); }
_lw_pr() {  # N HEAD-BRANCH HEAD-OID ROLL FILES [state=OPEN|CLOSED|MERGED] [labels=a,b] [repo=fixture/x]
  local n="$1" br="$2" oid="$3" ro="$4" fs="$5" kv st=OPEN lb="" rp=fixture/x me=null cl=null; shift 5
  for kv in "$@"; do case "$kv" in state=*) st="${kv#state=}" ;; labels=*) lb="${kv#labels=}" ;; repo=*) rp="${kv#repo=}" ;; esac; done
  [ "$st" = OPEN ] || cl="\"$LW_UPD\""
  [ "$st" = MERGED ] && me="\"$LW_UPD\""
  printf '{"number":%s,"title":"Change %s","state":"%s","isDraft":false,"isCrossRepository":false,"headRefName":"%s","headRefOid":"%s","baseRefName":"main",' "$n" "$n" "$st" "$br" "$oid"
  printf '"headRepositoryOwner":{"login":"fixture"},"headRepository":{"name":"%s"},"author":{"id":"U_fixture","is_bot":false,"login":"fixture","name":""},"labels":[%s],' "${rp#*/}" "$(_lw_labels "$lb")"
  printf '"mergeable":"MERGEABLE","mergeStateStatus":"CLEAN","statusCheckRollup":%s,"files":[%s],"createdAt":"%s","updatedAt":"%s","mergedAt":%s,"closedAt":%s,"reviewDecision":"","url":"https://github.com/%s/pull/%s"}' \
    "$(_lw_roll "$ro")" "$(_lw_files "$fs")" "$LW_CRE" "$LW_UPD" "$me" "$cl" "$rp" "$n"
}
_lw_prs() {  # KEY OBJECT...: ctl/prs.KEY.{all,open,closed,merged}.json
  local k="$1" o a="" op="" cl="" mg="" s1="" s2="" s3="" s4=""; shift
  for o in "$@"; do
    a="$a$s1$o"; s1=","
    case "$o" in
      *'"state":"OPEN"'*) op="$op$s2$o"; s2="," ;;
      *'"state":"MERGED"'*) cl="$cl$s3$o"; s3=","; mg="$mg$s4$o"; s4="," ;;
      *) cl="$cl$s3$o"; s3="," ;;
    esac
  done
  printf '[%s]\n' "$a" > "$LWK/prs.$k.all.json"; printf '[%s]\n' "$op" > "$LWK/prs.$k.open.json"
  printf '[%s]\n' "$cl" > "$LWK/prs.$k.closed.json"; printf '[%s]\n' "$mg" > "$LWK/prs.$k.merged.json"
  rm -f "$LWK/prs.$k.rc" "$LWK/prs.$k.err"
}
_lw_ghfail() { printf '1\n' > "$LWK/prs.$1.rc"; printf '%s\n' "$2" > "$LWK/prs.$1.err"; }

# ---- host records -------------------------------------------------------------
# Session files where Claude Code files them: LW_RR is the records root (a
# fixture HOME's .claude/projects), and a working directory's sessions sit in
# a directory named by it with every character outside [A-Za-z0-9-] made -.
# Every user and assistant record carries a timestamp MIN minutes ago; _lw_age
# sets the file's mtime to its last record's age. A user record puts
# "type":"user" before its message, an assistant record its message first.
_lw_enc() { printf '%s' "$1" | LC_ALL=C sed 's/[^A-Za-z0-9-]/-/g'; }
_lw_open() { LW_F="$1"; LW_SID="$2"; mkdir -p "${1%/*}"; : > "$1"; }
_lw_sess() { _lw_open "$LW_RR/$(_lw_enc "$1")/$2.jsonl" "$2"; }
_lw_ts() { local e; e=$(( $(date +%s) - $1 * 60 )); date -u -r "$e" '+%Y-%m-%dT%H:%M:%S.000Z' 2>/dev/null || date -u -d "@$e" '+%Y-%m-%dT%H:%M:%S.000Z'; }
_lw_age() { local e; e=$(( $(date +%s) - $2 * 60 )); touch -t "$(date -r "$e" '+%Y%m%d%H%M.%S' 2>/dev/null || date -d "@$e" '+%Y%m%d%H%M.%S')" "$1"; }
_lw_raw() { printf '%s\n' "$1" >> "$LW_F"; }
_lw_u() {  # MIN CONTENT-JSON
  local l; printf -v l '{"parentUuid":"p","isSidechain":false,"userType":"external","sessionId":"%s","version":"2.1.286","type":"user","message":{"role":"user","content":%s},"uuid":"u-%s","timestamp":"%s"}' \
    "$LW_SID" "$2" "$RANDOM" "$(_lw_ts "$1")"
  printf '%s\n' "$l" >> "$LW_F"; }
_lw_ax() {  # MIN ITEMS-JSON STOP-REASON
  local l; printf -v l '{"parentUuid":"p","isSidechain":false,"userType":"external","sessionId":"%s","version":"2.1.286","message":{"model":"claude-test","id":"msg_%s","type":"message","role":"assistant","content":[%s],"stop_reason":"%s","stop_sequence":null,"usage":{"input_tokens":1,"output_tokens":1}},"requestId":"req_%s","type":"assistant","uuid":"a-%s","timestamp":"%s"}' \
    "$LW_SID" "$RANDOM" "$2" "$3" "$RANDOM" "$RANDOM" "$(_lw_ts "$1")"
  printf '%s\n' "$l" >> "$LW_F"; }
_lw_h()  { _lw_u "$1" "\"$2\""; }
_lw_a()  { local b; printf -v b '{"type":"text","text":"%s"}' "$2"; _lw_ax "$1" "$b" end_turn; }
_lw_tu() { local b; printf -v b '{"type":"tool_use","id":"%s","name":"%s","input":%s}' "$2" "$3" "$4"; _lw_ax "$1" "$b" tool_use; }
_lw_tr() { local b; printf -v b '[{"tool_use_id":"%s","type":"tool_result","content":[{"type":"text","text":"%s"}]}]' "$2" "$3"; _lw_u "$1" "$b"; }
_lw_spawn() {  # MIN TOOL-ID TASK-ID TITLE PROMPT: a spawn_task proposal and the result naming its task
  local i; printf -v i '{"title":"%s","prompt":"%s","tldr":"Noticed in passing."}' "$4" "$5"
  _lw_tu "$1" "$2" mcp__ccd_session__spawn_task "$i"
  _lw_tr "$1" "$2" "Noted (position 1, task_id: $3). A chip is showing for the user."; }
_lw_title() { local l; printf -v l '{"type":"custom-title","customTitle":"%s","sessionId":"%s"}' "$1" "$LW_SID"; _lw_raw "$l"; }
# A3 cause 1: a first user record of two text items, the worktree reminder
# ending in a blank line, then the human text. The \n are JSON escapes.
_lw_h2() { local c; printf -v c '[{"type":"text","text":"%s"},{"type":"text","text":"%s"}]' "$LW_REM" "$2"; _lw_u "$1" "$c"; }
# A prompt of N characters cut from a repeated seed.
_lw_p() { local s="$1 $1 $1 $1 $1"; printf '%s' "${s:0:$2}"; }

# ---- running felix, and reading its rows -----------------------------------------
# _lw_run NAME HOME CWD ARGS...: $FELIX ARGS in CWD, stdout and stderr in
# $LWX/NAME.out and .err, the status in .rc.
_lw_run() {
  local n="$1" h="$2" d="$3"; shift 3
  ( cd "$d" || exit 97
    exec env -u FELIX_ALLOW_RED -u FELIX_KERNEL -u FELIX_KERNEL_CACHE -u CLAUDE_CODE_SESSION_ID -u CLAUDE_CONFIG_DIR \
      -u CLAUDE_PLUGIN_ROOT -u GIT_DIR -u GIT_WORK_TREE -u GIT_INDEX_FILE -u GIT_COMMON_DIR -u GIT_OBJECT_DIRECTORY -u GIT_OPTIONAL_LOCKS \
      HOME="$h" FELIX_HOME="$LW_FH" FELIX_HOME_DIR="$LW_FH" FELIX_MEMORY="$LWM" FELIX_PLUGIN_CACHE="$LW/cache" \
      FELIX_INVENTORY_TEMP_ROOTS="$LW/temproot" XDG_CONFIG_HOME="$h/.config" XDG_STATE_HOME="$h/.state" XDG_CACHE_HOME="$h/.cache" \
      GH_CONFIG_DIR="$h/.config/gh" GIT_CONFIG_NOSYSTEM=1 GIT_TERMINAL_PROMPT=0 GIT_CEILING_DIRECTORIES="$LW" \
      TMPDIR="$LWT" PATH="$LWB:$PATH" "$FELIX" "$@" ) > "$LWX/$n.out" 2> "$LWX/$n.err"
  printf '%s\n' "$?" > "$LWX/$n.rc"
}
_lw_o()  { printf '%s' "$LWX/$1.out"; }
_lw_rc() { cat "$LWX/$1.rc" 2>/dev/null; }
# OFF is 0 for a source's own --tsv (kind in column 1) and 1 for the page's
# (its group first); a column N is numbered as the source numbers it. LW_REPO,
# when set, keeps only rows whose repo cell is it.
_lw_row() { LC_ALL=C awk -F'\t' -v k="$2" -v r="$3" -v o="${4:-0}" -v p="$LW_REPO" \
              '$(1+o) == k && $(3+o) == r && (p == "" || $(2+o) == p) { print; exit }' "$1" 2>/dev/null; }
_lw_col() {  # FILE KIND REF N [OFF] -> that cell, or "no row"
  local l; l="$(_lw_row "$1" "$2" "$3" "${5:-0}")"
  if [ -z "$l" ]; then printf 'no row'; else printf '%s\n' "$l" | LC_ALL=C awk -F'\t' -v n="$4" -v o="${5:-0}" '{ printf "%s", $(n+o) }'; fi; }
_lw_st() { _lw_col "$1" "$2" "$3" 4 "${4:-0}"; }
_lw_holds() {  # FILE KIND REF STATE [OFF] -> yes, no or "no row"
  local s; s="$(_lw_st "$1" "$2" "$3" "${5:-0}")"
  if [ "$s" = "no row" ]; then printf 'no row'; else case ",$s," in *",$4,"*) printf yes ;; *) printf no ;; esac; fi; }
_lw_many() {  # FILE KIND REF OFF STATE... -> "S1=yes S2=no ..."
  local f="$1" k="$2" r="$3" o="$4" s out=""; shift 4
  for s in "$@"; do out="$out${out:+ }$s=$(_lw_holds "$f" "$k" "$r" "$s" "$o")"; done; printf '%s' "$out"; }
_lw_elem() {  # FILE KIND REF ELEMENT [OFF] -> yes, no or "no row": the detail holds ELEMENT whole (elements joined by "; ")
  local d; d="$(_lw_col "$1" "$2" "$3" 8 "${5:-0}")"
  [ "$d" != "no row" ] || { printf 'no row'; return; }
  printf '%s\n' "$d" | LC_ALL=C awk -v w="$4" '{ n = split($0, e, "; "); for (i = 1; i <= n; i++) if (e[i] == w) f = 1 } END { printf "%s", (f ? "yes" : "no") }'; }
_lw_kind() { local k; k="$(LC_ALL=C awk -F'\t' -v r="$2" -v o="${3:-0}" '$(3+o) == r { print $(1+o); exit }' "$1" 2>/dev/null)"; printf '%s' "${k:-none}"; }
# FILE [OFF] -> "B|C": B rows whose states break the order above, C rows holding carried.
_lw_order() { LC_ALL=C awk -F'\t' -v o="${2:-0}" -v ord="$LW_ORDER" '
    BEGIN { n = split(ord, t, " "); for (i = 1; i <= n; i++) r[t[i]] = i }
    { k = split($(4+o), s, ","); last = 0; bad = 0
      for (i = 1; i <= k; i++) if (s[i] in r) { if (r[s[i]] < last) bad = 1; last = r[s[i]] }
      b += bad; if (index("," $(4+o) ",", ",carried,")) c++ }
    END { printf "%d|%d", b + 0, c + 0 }' "$1" 2>/dev/null; }

# _lw_norm: rows through B7's filter (bytes below 0x20 but tab and line feed, and
# 0x7f, as ?), the age_h cell and the digits of the detail read as N, then sorted.
_lw_norm() { LC_ALL=C tr '\001-\010\013-\037\177' '?' | LC_ALL=C awk -F'\t' 'BEGIN { OFS = "\t" } { $6 = "N"; gsub(/[0123456789]+/, "N", $8); print }' | LC_ALL=C sort; }

# The number of summary rows in a page TSV.
_lw_n16() { LC_ALL=C awk -F'\t' '$2 == "summary" { n++ } END { print n + 0 }' "$1" 2>/dev/null; }

# The shared fixture. Every repository is a clone of a bare origin at
# $LW/github.com/fixture/NAME.git, so its slug is fixture/NAME. gh, launchctl,
# open and xdg-open are stubs first on PATH, each logging its argv under
# $LW/log. gh answers pr list from ctl/prs.<owner>_<name>.<state>.json (the
# repository from -R, else from the origin of the directory it runs in; state
# open unless --state says all, closed or merged), fails as ctl/prs.<key>.rc
# says, and answers the api GETs step 5 makes (the Actions billing, a user, a
# repository's default branch) from fixed bodies. launchctl print fails (the
# lander job is not loaded). open is stubbed so that no run of the page before
# it exists, where `monitor --open` still opens, can open a window. Every felix
# run has a fixture HOME (its .claude/projects is the records root), TMPDIR
# $LW/tmp, an empty FELIX_INVENTORY_TEMP_ROOTS (the suite's $TMP is under the
# real temporary roots), FELIX_MEMORY $LW/mem and FELIX_HOME $LW_FH.
# _lw_build: the variables above and the helpers read, then the directories and
# stubs, when the last stub written is not there yet.
_lw_build() {
LW="$TMP/lost-work"; mkdir -p "$LW"; LW="$(cd "$LW" && pwd -P)"
LWB="$LW/bin"; LWK="$LW/ctl"; LWL="$LW/log"; LWX="$LW/out"; LWT="$LW/tmp"; LWM="$LW/mem"
mkdir -p "$LWB" "$LWK" "$LWL" "$LWX" "$LWT" "$LWM" "$LW/fxhome/.config" "$LW/cache" "$LW/temproot" \
         "$LW/norepo" "$LW/cwd" "$LW/nohome/projects" "$LW/hA/.claude/projects"
LW_FH="$LW/nohome"
LWC=""
LW_UPD="$(_lw_ago 181800)"; LW_CRE="$(_lw_ago 216000)"   # 50.5 and 60 hours ago
LW_F=""; LW_SID=""; LW_RR=""
LW_REM='<system-reminder>\nYou are operating in a git worktree.\nEdit files only under it.\n</system-reminder>\n\n'
LW_REPO=""
LW_ORDER='hazard:shared-branch hazard:staged-revert live question blocked uncommitted unpushed unproposed pr-open pr-closed-unlanded carried orphan chip-unstarted handoff-pending'
[ -x "$LWB/xdg-open" ] && return 0
_lw_put "$LWB/gh" <<'LWSTUB'
#!/bin/bash
LW='@LW@'; K="$LW/ctl"
printf '%s\n' "$*" >> "$LW/log/gh.log"
jqx=""; repo=""; prev=""; st=open; bill=0; user=0; dflt=""; deep=0
for a in "$@"; do
  case "$prev" in -q|--jq) jqx="$a" ;; -R|--repo) repo="$a" ;; -s|--state) st="$a" ;; esac
  case "$a" in --jq=*) jqx="${a#--jq=}" ;; --repo=*) repo="${a#--repo=}" ;; --state=*) st="${a#--state=}" ;; esac
  case "$a" in *settings/billing/usage*) bill=1; bq="$a" ;; users/*|/users/*) user=1 ;; esac
  case "${a#/}" in repos/fixture/*/*) deep=1 ;; repos/fixture/*) dflt="${a#/}" ;; esac
  prev="$a"
done
if [ -z "$repo" ]; then
  u="$(git config --get remote.origin.url 2>/dev/null)"; u="${u%/}"; u="${u%.git}"
  n="${u##*/}"; o="${u%/*}"; o="${o##*/}"; [ -n "$n" ] && [ -n "$o" ] && repo="$o/$n"
fi
repo="${repo#https://}"; repo="${repo#github.com/}"; repo="${repo%.git}"
key="$(printf '%s' "$repo" | LC_ALL=C tr '/' '_')"
out() { if [ -n "$jqx" ] && command -v jq >/dev/null 2>&1; then jq -r "$jqx"; else cat; fi; }
case "${1:-} ${2:-}" in
  "pr list")
    if [ -f "$K/prs.$key.rc" ]; then cat "$K/prs.$key.err" >&2; exit "$(cat "$K/prs.$key.rc")"; fi
    case "$st" in open|all|closed|merged) ;; *) st=all ;; esac
    [ -f "$K/prs.$key.$st.json" ] || { printf 'stub: no answer for repository [%s]\n' "$repo" >&2; exit 4; }
    out < "$K/prs.$key.$st.json"; exit 0 ;;
  "auth status") exit 0 ;;
esac
case "${1:-}" in --version|version) echo 'gh version 2.99.0 (stub)'; exit 0 ;; esac
if [ "${1:-}" = api ]; then
  if [ "$bill" = 1 ]; then by="${bq##*year=}"; by="${by%%&*}"; bm="${bq##*month=}"; bm="${bm%%&*}"; [ "${#bm}" -eq 1 ] && bm="0$bm"; printf '{"usageItems":[{"date":"%s-%s-01T00:00:00Z","product":"actions","sku":"Actions Linux","quantity":123.0,"unitType":"Minutes","pricePerUnit":0.006,"grossAmount":0.0,"discountAmount":0.0,"netAmount":0.0,"repositoryName":"home"}]}\n' "$by" "$bm" | out; exit 0; fi
  if [ "$user" = 1 ]; then printf '{"login":"fixture","id":1,"type":"User"}\n' | out; exit 0; fi
  if [ -n "$dflt" ] && [ "$deep" = 0 ]; then printf '{"full_name":"%s","default_branch":"main"}\n' "${dflt#repos/}" | out; exit 0; fi
  printf 'gh: Not Found (HTTP 404)\n' >&2; exit 1
fi
printf 'stub: gh %s is not served\n' "$*" >&2
exit 1
LWSTUB
_lw_put "$LWB/launchctl" <<'LWSTUB'
#!/bin/bash
printf '%s\n' "$*" >> '@LW@/log/launchctl.log'
case "${1:-}" in print) exit 113 ;; esac
exit 0
LWSTUB
_lw_put "$LWB/open" <<'LWSTUB'
#!/bin/bash
printf '%s\n' "$*" >> '@LW@/log/open.log'
exit 0
LWSTUB
cp "$LWB/open" "$LWB/xdg-open"
}

# _lw_pg_build: the page fixture pg, after _lw_build. When pg is already built
# (the live session, written last, is there) it sets pg's paths, names and
# commits from what is on disk and builds nothing.
_lw_pg_build() {
LW_HEAD='felix monitor: read-only. It wrote nothing, fetched nothing and acted on nothing; it read felix inventory and felix land --prs.'
if [ -f "$LW/hp/.claude/projects/$(_lw_enc "$LW/pg-wt/live-q4")/d0d0d0d0-0000-4000-8000-0000000000a4.jsonl" ]; then
  PG="$LW/pg"; PGR="$(_lw_mainwt "$PG")"; LW_FH="$PG"; LWW="$LW/pg-wt"
  LW_HP="$LW/hp"; LW_RR="$LW_HP/.claude/projects"
  LWESC="$(printf '\033')"; LWBEL="$(printf '\007')"
  LW_CHIPT="Page chip ${LWESC}[31m red ${LWBEL} bell"
  LWS_PG=d0d0d0d0-0000-4000-8000-0000000000aa; LWS_BLK=d0d0d0d0-0000-4000-8000-0000000000b2; LWS_ASK=d0d0d0d0-0000-4000-8000-0000000000a3
  LWPG0="$(_lwq "$PG" refs/heads/lw-landed-q8)"; LWPGM="$(_lwq "$PG" refs/heads/main)"
  LWQ7X="$(_lwq "$PG" refs/heads/lw-carried-q7)"; LWQ5="$(_lwq "$PG" refs/heads/lw-unprop-q5)"
  for _lwi in 301 302 303 304 305; do eval "LWH$_lwi=\$(_lwq \"\$PG\" refs/remotes/origin/b$_lwi)"; done
  return 0
fi
_lw_repo pg; PG="$LW/pg"; LWPG0="$(_lwq "$PG" refs/heads/main)"
mkdir -p "$PG/projects/pg" "$PG/docs/handoff/pending"
printf '{\n  "name": "pg",\n  "remote_match": "github.com/fixture/pg",\n  "gate": "true"\n}\n' > "$PG/projects/pg/project.json"
printf '# pg\n' > "$PG/projects/pg/CLAUDE.md"
printf 'landdir/.*\tfounder\t-\t-\n' > "$PG/projects/pg/land.tsv"
printf 'red\tpath\t^riskdir/plain/\ta person reads these\treviewed\t-\n' > "$PG/projects/pg/risk.tsv"
printf '### 2026-10-16 - the page waits\n\nThe page was designed here and not built.\n\n**Next:**\n- Build the page.\n' \
  > "$PG/docs/handoff/pending/20261016T101010Z-lw-handoff-q6.md"
_lwg "$PG" add -A >/dev/null 2>&1; _lwg "$PG" commit -qm 'the project and a pending handoff section' >/dev/null 2>&1
_lwg "$PG" push -q origin main >/dev/null 2>&1
PGR="$(_lw_mainwt "$PG")"; LWPGM="$(_lwq "$PG" refs/heads/main)"
LW_FH="$PG"
for _lwi in 301 302 304 305; do _lw_mk "$PG" "$LWPGM" "head $_lwi" "n$_lwi.txt" "$_lwi"; eval "LWH$_lwi=\$LWC"; done
_lw_mk "$PG" "$LWPGM" 'carried work' q7.txt q7; LWQ7X="$LWC"; _lw_mk "$PG" "$LWQ7X" 'head 303' n303.txt 303; LWH303="$LWC"
_lw_mk "$PG" "$LWPGM" 'unproposed work' q5.txt q5; LWQ5="$LWC"
_lwg "$PG" push -q origin "$LWH301:refs/heads/b301" "$LWH302:refs/heads/b302" "$LWH303:refs/heads/b303" "$LWH304:refs/heads/b304" \
  "$LWH305:refs/heads/b305" "$LWQ5:refs/heads/lw-unprop-q5" >/dev/null 2>&1
_lwg "$PG" fetch -q origin >/dev/null 2>&1
_lwg "$PG" branch -q lw-unprop-q5 "$LWQ5" >/dev/null 2>&1; _lwg "$PG" branch -q --set-upstream-to=origin/lw-unprop-q5 lw-unprop-q5 >/dev/null 2>&1
_lwg "$PG" branch -q lw-carried-q7 "$LWQ7X" >/dev/null 2>&1
_lwg "$PG" branch -q lw-landed-q8 "$LWPG0" >/dev/null 2>&1
_lwg "$PG" branch -q lw-shared-q1 "$LWPGM" >/dev/null 2>&1
LWW="$LW/pg-wt"; mkdir -p "$LWW"
_lwg "$PG" worktree add -q "$LWW/share-a-q1" lw-shared-q1 >/dev/null 2>&1
_lwg "$PG" worktree add -q -f "$LWW/share-b-q1" lw-shared-q1 >/dev/null 2>&1
for _lwi in blocked-q2 ask-q3 live-q4 dirty-q9; do _lwg "$PG" worktree add -q -b "lw-$_lwi" "$LWW/$_lwi" "$LWPGM" >/dev/null 2>&1; done
printf 'work in progress\n' > "$LWW/live-q4/wip.txt"; printf 'never committed\n' > "$LWW/dirty-q9/new.txt"
_lw_prs fixture_pg "$(_lw_pr 301 b301 "$LWH301" green notes/301.md labels=needs-founder repo=fixture/pg)" \
  "$(_lw_pr 302 b302 "$LWH302" red notes/302.md repo=fixture/pg)" "$(_lw_pr 303 b303 "$LWH303" green notes/303.md repo=fixture/pg)" \
  "$(_lw_pr 304 b304 "$LWH304" running notes/304.md repo=fixture/pg)" "$(_lw_pr 305 b305 "$LWH305" green @100 repo=fixture/pg)"
# The page's records: the chip (its title holding ESC and BEL as raw bytes),
# the blocked call, the question, and the live session written last.
LW_HP="$LW/hp"; LW_RR="$LW_HP/.claude/projects"; mkdir -p "$LW_RR"
LWESC="$(printf '\033')"; LWBEL="$(printf '\007')"
LW_CHIPT="Page chip ${LWESC}[31m red ${LWBEL} bell"
LWS_PG=d0d0d0d0-0000-4000-8000-0000000000aa; LWS_BLK=d0d0d0d0-0000-4000-8000-0000000000b2; LWS_ASK=d0d0d0d0-0000-4000-8000-0000000000a3
_lw_sess "$PGR" "$LWS_PG"; _lw_h 652 'file the follow-ups'
_lw_spawn 651 toolu_pg task_c0ffee01 "$LW_CHIPT" "$(_lw_p 'Page task: make the page print its groups in the order the contract gives them.' 130)"
_lw_a 650 'Filed.'; _lw_age "$LW_F" 650
_lw_sess "$LWW/blocked-q2" "$LWS_BLK"; _lw_h 292 'run the daily watch'
_lw_tu 290 toolu_blk Bash '{"command":"watch-the-ledger","description":"Watch the ledger"}'; _lw_age "$LW_F" 290
_lw_sess "$LWW/ask-q3" "$LWS_ASK"; _lw_h 202 'prepare the push'
_lw_a 200 'The branch is ready. Shall I push it?'; _lw_age "$LW_F" 200
_lw_sess "$LWW/live-q4" d0d0d0d0-0000-4000-8000-0000000000a4; _lw_h 2 'watch the build'
_lw_tu 1 toolu_live Bash '{"command":"make watch","description":"Watch the build"}'; _lw_age "$LW_F" 1
}
