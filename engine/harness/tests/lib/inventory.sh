# tests/lib/inventory.sh: the felix inventory fixture, its runner and the readers of its rows.
# Used by parts 0860 (builds the fixture) 0870 (the live session, the runs) 0880 0890. Moved from
# parts/0860-felix-inventory-where-unlanded-work-is-deriv.sh: the fixture's git and clock helpers from lines 24-66, _ivpr from
# 182-195, _ivchip from 330-336, the fixture itself from lines 3-324 and 337-424 (into
# _iv_fixture; the variables it only names into _iv_build, which sets them first);
# from parts/0870-continued.sh: _ivrun (2-25), the row readers (56-121), _ivln _ivlnw _ivmin
# _ivcnt (260-263), _ivrows (286-288), _ivcode and _ivwhere (454-459), the live session
# (34-44, into _iv_live), the gh-less PATH (316-327, into _iv_nogh), _iv_sum (45) and the
# library paths (446-453, into _iv_build). _iv_runs repeats the commands of the runs 0870 makes
# that 0890 reads (T0 T0W T1 T3 T4 T5 T6 T7 T8 and the human report), so 0890 can stand alone.
# Definitions only. A builder sets its variables first and does nothing more when its fixture
# is already there, so in the serial run only 0860's call builds.

# The fixture's own git: a scratch HOME, no system config, a fixed author. Its
# reads take no optional lock, so checking the fixture cannot refresh an index
# the read-only assertion watches. Commits no worktree holds are built in a
# temporary index outside every repository.
_ivg() { HOME="$IVH" XDG_CONFIG_HOME="$IVH/.config" GIT_CONFIG_NOSYSTEM=1 \
         GIT_AUTHOR_NAME=Fixture GIT_AUTHOR_EMAIL=fixture@example.invalid \
         GIT_COMMITTER_NAME=Fixture GIT_COMMITTER_EMAIL=fixture@example.invalid git "$@"; }
_ivq() { _ivg --no-optional-locks "$@"; }
_ivi() { GIT_INDEX_FILE="$IV/idx" HOME="$IVH" XDG_CONFIG_HOME="$IVH/.config" GIT_CONFIG_NOSYSTEM=1 git "$@"; }
# _inventory_vars: the variables this file's functions read, set when the prelude calls it
# (contract C2: a lib file defines functions and nothing else).
_inventory_vars() {
IVC=""
}
_ivc() {  # repo parent message path content [path content]... -> IVC
  local r="$1" par="$2" msg="$3" blob tree; shift 3
  _ivi -C "$r" read-tree "$par"
  while [ $# -ge 2 ]; do
    blob="$(printf '%s\n' "$2" | _ivg -C "$r" hash-object -w --stdin)"
    _ivi -C "$r" update-index --add --cacheinfo "100644,$blob,$1"
    shift 2
  done
  tree="$(_ivi -C "$r" write-tree)"
  IVC="$(_ivg -C "$r" commit-tree "$tree" -p "$par" -m "$msg")"
}
_ivwc() { _ivg -C "$1" add -A && _ivg -C "$1" commit -q -m "$2"; }
_ivwt() { _ivg -C "$IVM" worktree add -q "$@"; }
_ivrepo() {  # bare clone owner/name
  _ivg -c init.defaultBranch=main init -q --bare "$1"
  _ivg -C "$1" symbolic-ref HEAD refs/heads/main
  _ivg -c init.defaultBranch=main -c "url.$1.insteadOf=https://github.com/$3.git" \
       clone -q "https://github.com/$3.git" "$2" 2>/dev/null
  _ivg -C "$2" symbolic-ref HEAD refs/heads/main
  _ivg -C "$2" config "url.$1.pushInsteadOf" "https://github.com/$3.git"
}
# A time N minutes ago, as a transcript timestamp or as touch -t wants it.
_ivago() {
  local t f u=-u
  t=$(( $(date +%s) - $1 * 60 ))
  if [ "$2" = touch ]; then f='+%Y%m%d%H%M.%S'; u=""; else f='+%Y-%m-%dT%H:%M:%S.000Z'; fi
  date $u -r "$t" "$f" 2>/dev/null || date $u -d "@$t" "$f"
}
_ivtouch() { touch -t "$(_ivago "$2" touch)" "$1"; }
# The host's directory for a working directory: every character outside
# [A-Za-z0-9-] becomes -, as the spec's adapter section says.
_ive() { printf '%s/' "$IVP"; printf '%s' "$1" | sed 's/[^A-Za-z0-9-]/-/g'; }
_ivopen() { _au_open "$(_ive "$1")/$2.jsonl" "$2"; }
_ivpr() {  # number branch state head updated-min labels mergeable rollup merged-min closed-min
  local lab="" l one up cr me=null cl=null ms=CLEAN
  for l in $6; do
    printf -v one '{"id":"LA_%s","name":"%s","description":"","color":"ededed"}' "$l" "$l"
    lab="$lab${lab:+,}$one"
  done
  up="$(_ivago "$5" iso)"; cr="$(_ivago 6000 iso)"
  [ "$9" = - ] || me="\"$(_ivago "$9" iso)\""
  [ "${10}" = - ] || cl="\"$(_ivago "${10}" iso)\""
  [ "$7" = CONFLICTING ] && ms=DIRTY
  printf -v one '{"number":%s,"title":"Change %s","state":"%s","isDraft":false,"headRefName":"%s","headRefOid":"%s","baseRefName":"main","createdAt":"%s","updatedAt":"%s","mergedAt":%s,"closedAt":%s,"labels":[%s],"mergeable":"%s","mergeStateStatus":"%s","statusCheckRollup":[%s],"url":"https://github.com/acme/widget/pull/%s","author":{"login":"fixture"},"headRepositoryOwner":{"login":"acme"},"reviewDecision":""}' \
    "$1" "$1" "$3" "$2" "$4" "$cr" "$up" "$me" "$cl" "$lab" "$7" "$ms" "$8" "$1"
  printf '%s\n' "$one" >> "$IVGH/prs.lines"
}
_ivchip() {  # ts tool-id task-id title prompt
  local inp res
  printf -v inp '{"title":"%s","tldr":"%s","prompt":"%s"}' "$4" 'Noticed in passing.' "$5"
  _au_tool "$2" mcp__ccd_session__spawn_task "$inp"; _au_a "$1" "msg_$2" '"tool_use"' "$_AU_B"
  printf -v res '[{"tool_use_id":"%s","type":"tool_result","content":[{"type":"text","text":"Noted (position 1, task_id: %s). A chip is showing for the user."}]}]' "$2" "$3"
  _au_u "$1" "$res"
}
# felix from the main clone, with the stand-ins first on PATH, the scratch
# HOME and TMPDIR, nothing of Felix's in the environment, no system git config,
# only the file transport, and discovery stopped at the scratch root.
_ivrun() {  # [--path P] [--cwd D] [--bash B] [--home H] [--troots R] felix-args...
  local p="$IVSTUB:$PATH" d="$IVM" b="" h="$IVH" tr="" trs=0
  while :; do
    case "${1:-}" in
      --path) p="$2"; shift 2 ;;
      --cwd)  d="$2"; shift 2 ;;
      --bash) b="$2"; shift 2 ;;
      --home) h="$2"; shift 2 ;;
      --troots) tr="$2"; trs=1; shift 2 ;;
      *) break ;;
    esac
  done
  ( cd "$d" || exit 97
    unset FELIX_HOME FELIX_MEMORY FELIX_KERNEL FELIX_KERNEL_CACHE FELIX_PLUGIN_CACHE CLAUDE_PLUGIN_ROOT \
          CLAUDE_CONFIG_DIR GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OPTIONAL_LOCKS GIT_CEILING_DIRECTORIES \
          FELIX_INVENTORY_TEMP_ROOTS
    export HOME="$h" TMPDIR="$IVT" PATH="$p" XDG_CONFIG_HOME="$IVH/.config" GIT_CONFIG_NOSYSTEM=1 \
           GIT_ALLOW_PROTOCOL=file GIT_TERMINAL_PROMPT=0 GIT_CEILING_DIRECTORIES="$IV"
    [ "$trs" = 0 ] || export FELIX_INVENTORY_TEMP_ROOTS="$tr"
    if [ -n "$b" ]; then "$b" "$IVF" "$@"; else "$IVF" "$@"; fi ) 2>>"$IV_ERR"
}
# ---- reading the rows ----------------------------------------------------
# _iv_sel FILE TOKEN puts the rows naming TOKEN in $IV/sel; _iv_q asks a
# question of them and needs at least one row. A chip's or a handoff's row
# may name the worktree it came from, and is never that worktree's row.
_iv_sel() { LC_ALL=C awk -F'\t' -v t="$2" '
    $1 == "kind" && $4 == "states" { next }
    { x = " " $4 " "; gsub(/[^a-z:-]+/, " ", x) }
    index(x, " chip-unstarted ") || index(x, " handoff-pending ") { next }
    index($3, t) { r[++n] = $0; next }
    index($0, t) { o[++m] = $0 }
    END { if (n) { for (i = 1; i <= n; i++) print r[i] } else { for (i = 1; i <= m; i++) print o[i] } }' "$1" > "$IV/sel"; }
_iv_selstate() { LC_ALL=C awk -F'\t' -v s="$2" '
    $1 == "kind" && $4 == "states" { next }
    { x = $4; gsub(/[^a-z:-]+/, " ", x); k = split(x, t, " "); for (i = 1; i <= k; i++) if (t[i] == s) { print; break } }' "$1" > "$IV/sel"; }
#   lead S     every row's first state is S      hold S    some row holds S
#   lack S     no row holds S                    word C:W  some row has word W in column C (0: the line)
#   noword C:W no row has it                     num L:H   some row's age_h or detail holds a number in L..H
#   dnum L:H   some row's detail holds one
_iv_q() { LC_ALL=C awk -F'\t' -v m="$1" -v a="$2" '
  function has(s,   x, k, i, t) { x = $4; gsub(/[^a-z:-]+/, " ", x); k = split(x, t, " "); for (i = 1; i <= k; i++) if (t[i] == s) return 1; return 0 }
  function lead(   x, t) { x = $4; gsub(/[^a-z:-]+/, " ", x); split(x, t, " "); return t[1] }
  function word(c, w,   x) { x = tolower(c == 0 ? $0 : $c); return x ~ ("(^|[^a-z])" w "([^a-z]|$)") }
  function num(s, lo, hi,   v) { while (match(s, /[0-9]+(\.[0-9]+)?/)) { v = substr(s, RSTART, RLENGTH) + 0; if (v >= lo && v <= hi) return 1; s = substr(s, RSTART + RLENGTH) } return 0 }
  { n++; split(a, p, ":")
    if (m == "lead") { if (lead() != a) b = 1 }
    else if (m == "hold") { if (has(a)) g = 1 }
    else if (m == "lack") { if (has(a)) b = 1 }
    else if (m == "word") { if (word(p[1] + 0, p[2])) g = 1 }
    else if (m == "noword") { if (word(p[1] + 0, p[2])) b = 1 }
    else if (m == "num") { if (num($6 " " $8, p[1] + 0, p[2] + 0)) g = 1 }
    else if (m == "dnum") { if (num($8, p[1] + 0, p[2] + 0)) g = 1 } }
  END { if (!n || b) exit 1; if (m == "hold" || m == "word" || m == "num" || m == "dnum") exit g ? 0 : 1; exit 0 }' "$IV/sel"; }
# The table's states on each selected row, rows joined by " | ".
_iv_states() { LC_ALL=C awk -F'\t' -v o="$IV_ORDER" '
  BEGIN { n = split(o, a, " "); for (i = 1; i <= n; i++) known[a[i]] = 1 }
  { x = $4; gsub(/[^a-z:-]+/, " ", x); k = split(x, s, " "); r = ""
    for (i = 1; i <= k; i++) if (s[i] in known) r = r (r == "" ? "" : " ") s[i]
    out = out (NR > 1 ? " | " : "") r }
  END { print out }' "$IV/sel"; }
_iv_diag() { if [ -s "$IV/sel" ]; then tr '\t\n' '|;' < "$IV/sel" | head -c 700; else printf 'no row names it; stderr: '; tail -c 300 "$IV_ERR" | tr '\n' ' '; fi; }
_iv_chk() {  # name file token mode arg
  _iv_sel "$2" "$3"
  if _iv_q "$4" "$5"; then ok "$1"; else bad "$1" "$(_iv_diag)"; fi; }
_ivgh() { if [ "$IV_JQ" = 1 ]; then "$@"; else skip "$2" "no jq for the gh stand-in"; fi; }
_iv_count() { LC_ALL=C awk -F'\t' -v s="$2" '
  $1 == "kind" && $4 == "states" { next }
  { x = $4; gsub(/[^a-z:-]+/, " ", x); k = split(x, t, " "); for (i = 1; i <= k; i++) if (t[i] == s) { c++; break } }
  END { print c + 0 }' "$1"; }
_iv_fields() { LC_ALL=C awk -F'\t' 'NF && NF != 8 { printf "line %d has %d fields; ", NR, NF }' "$1"; }
_iv_blank()  { LC_ALL=C awk -F'\t' 'NF == 8 && ($1 == "" || $2 == "" || $3 == "" || $4 == "") { printf "line %d; ", NR }' "$1"; }
_iv_repos()  { LC_ALL=C awk -F'\t' '$1 == "kind" && $4 == "states" { next } NF { r[$2] = 1 } END { for (k in r) print k }' "$1"; }
_iv_order()  { LC_ALL=C awk -F'\t' -v o="$IV_ORDER" '
  BEGIN { n = split(o, a, " "); for (i = 1; i <= n; i++) r[a[i]] = i }
  $1 == "kind" && $4 == "states" { next }
  { x = $4; gsub(/[^a-z:-]+/, " ", x); k = split(x, s, " "); l = 0
    for (i = 1; i <= k; i++) if (s[i] in r) { if (r[s[i]] < l) { printf "%s [%s]; ", $3, $4; break } l = r[s[i]] } }' "$1"; }
_iv_landx()  { LC_ALL=C awk -F'\t' -v o="$IV_ORDER" '
  BEGIN { n = split(o, a, " "); for (i = 1; i <= n; i++) r[a[i]] = 1 }
  $1 == "kind" && $4 == "states" { next }
  { x = $4; gsub(/[^a-z:-]+/, " ", x); k = split(x, s, " "); L = 0; X = 0
    for (i = 1; i <= k; i++) { if (s[i] == "landed") L = 1; else if (s[i] != "live" && (s[i] in r)) X = 1 }
    if (L && X) printf "%s [%s]; ", $3, $4 }' "$1"; }
_iv_kinds()  { LC_ALL=C awk -F'\t' -v g="${2:-}" '$1 == "kind" && $4 == "states" { next } NF && $2 != g { print $1 "\t" $4 }' "$1" | LC_ALL=C sort; }
_iv_named()  { local f="$1" n m=""; shift; for n in "$@"; do grep -qF -- "$n" "$f" || m="$m $n"; done; printf '%s' "$m"; }
_iv_col2()   { LC_ALL=C awk -F'\t' 'NR == 1 { print $2 }' "$IV/sel"; }
_ivnr()      { LC_ALL=C awk 'END { print NR }' "$1"; }
_ivln()  { LC_ALL=C awk -v a="$2" -v b="$3" 'index($0, a) || index($0, b) { print NR; exit }' "$1"; }
_ivlnw() { LC_ALL=C awk -v w="$2" 'tolower($0) ~ ("(^|[^a-z])" w) { print NR; exit }' "$1"; }
_ivmin() { local m="" v; for v in "$@"; do [ -n "$v" ] || continue; if [ -z "$m" ] || [ "$v" -lt "$m" ]; then m="$v"; fi; done; printf '%s' "$m"; }
_ivcnt() { LC_ALL=C awk -v w="$2" 'tolower($0) ~ ("(^|[^a-z])" w "([^a-z]|$)") && /[0-9]/ { f = 1 } END { exit f ? 0 : 1 }' "$1"; }
# A run that printed nothing asked nothing and reported nothing, so each
# absence below counts only over a run that gave rows.
_ivrows() { [ -s "$1" ] && printf '%s' "$2" || printf 'no rows'; }
# Lines that are not comments, each prefixed with its file and line number.
_ivcode() { LC_ALL=C awk '!/^[[:space:]]*#/ { f = FILENAME; sub(/.*\//, "", f); print f ":" FNR ":" $0 }' "$@" 2>/dev/null; }
# Each pattern sits in a function of its own, never inside "$(...)", where
# bash 3.2 can brace-expand a quoted literal. A finding names the file, the
# line and the rule, and quotes no code.
_ivwhere() { LC_ALL=C awk -F: -v w="$1" '{ printf "%s:%s %s; ", $1, $2, w }' | head -c 300; }

# _iv_nogh: IV/nogh, a directory of links to everything on PATH but gh (the run with no gh at all).
_iv_nogh() {
# A directory of links to everything on PATH but gh, first found first.
mkdir -p "$IV/nogh"
_ivifs="$IFS"; IFS=:
for _ivd in $PATH; do
  IFS="$_ivifs"
  [ -d "$_ivd" ] || continue
  for _ivf in "$_ivd"/*; do
    _ivn="${_ivf##*/}"
    [ "$_ivn" = gh ] && continue
    [ -e "$IV/nogh/$_ivn" ] || [ -L "$IV/nogh/$_ivn" ] || { [ -x "$_ivf" ] && [ ! -d "$_ivf" ] && ln -s "$_ivf" "$IV/nogh/$_ivn"; }
  done
done
IFS="$_ivifs"
}

# _iv_build [live|runs]: IV and the variables of the fixture, then the fixture (the widget,
# gadget and their worktrees, the gh and git stand-ins, the host's session records). "live"
# adds the live session and the fresh subagent transcript 0870 writes just before its runs;
# "runs" adds those and the runs 0870 makes that 0890 reads. Each step does nothing when done.
_iv_build() {
IV="$TMP/inventory"; mkdir -p "$IV"; IV="$(cd "$IV" && pwd -P)"
IVW="$IV/work"; IVM="$IVW/widget"; IVO="$IV/origin.git"
IVW2="$IV/work2"; IVG="$IVW2/gadget"; IVO2="$IV/origin2.git"
IVH="$IV/home"; IVP="$IVH/.claude/projects"; IVT="$IV/tmp"
IVGH="$IV/gh"; IVSTUB="$IV/stub"; IVGH_LOG="$IV/gh.log"; IVGIT_LOG="$IV/git.log"; IV_ERR="$IV/stderr"
IVF="$IV/clone/felix/engine/harness/felix"
IV_REALGIT="$(command -v git)"
IV_JQ=0; command -v jq >/dev/null 2>&1 && IV_JQ=1
IV_ORDER='hazard:shared-branch hazard:staged-revert live question blocked uncommitted unpushed unproposed pr-open pr-closed-unlanded orphan chip-unstarted handoff-pending landed'
IV_WTS='wt-squash wt-same wt-dirty wt-unpushed wt-unproposed wt-closed wt-sharea wt-shareb wt-revert wt-live wt-query wt-bold wt-answered wt-blocked wt-unread'
_iv_sum=cksum; command -v shasum >/dev/null 2>&1 && _iv_sum=shasum
IV_PA_PROMPT='Alpha task: make the parser treat a blank line as the end of a record, then add a test that feeds it two records split by one blank line and checks both.'
IV_PC_PROMPT='Gamma task: rename the config loader so it says what it loads, update every caller in the tree, and keep the old name as a thin alias for one release.'
IV_PD_PROMPT='Delta task: give the scheduler a dry-run mode that prints the jobs it would start and starts none, with a test that counts zero starts made by it.'
IV_PE_PROMPT='Epsilon task: move the retry budget into the settings file so it can change without a release, and assert the default stays at three attempts.'
IV_PF_PROMPT='Zeta task: make the export write its rows in a stable order so two runs over one input produce the same file, and test that twice in a row.'
IV_NID=c3c3c3c3-0000-4000-8000-000000000002
# The spec puts git and GitHub in lib/inventory.sh and what only Claude Code's
# transcripts say in lib/inventory-host.sh, one adapter, so a second host is a
# second adapter. Comments are left out: they may name what the other holds.
IVLIB="$REAL_HARNESS/lib/inventory.sh"; IVLIBH="$REAL_HARNESS/lib/inventory-host.sh"
# The core may be split into parts beside it (lib/inventory-*.sh other than
# the adapter); each part is held to what the core is held to.
# The adapter is two files, lib/inventory-host.sh and lib/inventory-chips.sh,
# which reads the proposals; the chips file is held to the adapter's rules and
# to the shared ones, and is no part of the core.
IVLIBC="$REAL_HARNESS/lib/inventory-chips.sh"
IVPARTS=()
for _ivf in "$REAL_HARNESS"/lib/inventory-*.sh; do [ -f "$_ivf" ] && [ "$_ivf" != "$IVLIBH" ] && [ "$_ivf" != "$IVLIBC" ] && IVPARTS[${#IVPARTS[@]}]="$_ivf"; done
_iv_fixture
case "${1:-}" in live|runs) _iv_live ;; esac
case "${1:-}" in runs) _iv_runs ;; esac
}

# _iv_fixture: the 0860 fixture. The guard is the last session file written.
_iv_fixture() {
  [ -e "$IVP/-elsewhere-other/a9a9a9a9-0000-4000-8000-000000000001.jsonl" ] && return 0
# One scratch root holds everything the command may read: a bare origin, a
# main clone whose origin names GitHub (pushes are rewritten to the bare one
# and fetches are not, so a fetch fails rather than reaching anything),
# worktrees and orphans beside the clone, a second small repository for
# --repo, gh and git behind stand-ins that log every call, and a scratch HOME
# with Claude Code transcripts. The engine is a plain copy laid out the way a
# clone lays it out, with no install, as the audit section's is.
mkdir -p "$IVW" "$IVW2" "$IVH/.config" "$IVP" "$IVT" "$IVGH" "$IVSTUB" "$IV/cwd" "$IV/clone/felix/engine"
: > "$IVGH_LOG"; : > "$IVGIT_LOG"; : > "$IV_ERR"
_copy_content "$REAL_HARNESS" "$IV/clone/felix/engine/harness"
# ---- widget: main, and the branches cut from it --------------------------
_ivrepo "$IVO" "$IVM" acme/widget
mkdir -p "$IVM/src"
printf 'widget\n' > "$IVM/README.md"; printf 'core line\n' > "$IVM/src/core.txt"
printf 'old\n' > "$IVM/src/old.txt"; printf 'base\n' > "$IVM/src/conflict.txt"
printf '*.log\n' > "$IVM/.gitignore"
_ivwc "$IVM" 'the first widget'; IV_C0="$(_ivg -C "$IVM" rev-parse HEAD)"
_ivc "$IVM" "$IV_C0" 'the squash feature' src/squash.txt 'squash feature'; IV_S1="$IVC"
_ivc "$IVM" "$IV_C0" 'the superseded file' src/superseded.txt 'superseded'; IV_X1="$IVC"
_ivc "$IVM" "$IV_C0" 'two files, one of them main'"'"'s' src/partly-a.txt 'A' src/partly-b.txt 'B'; IV_PA="$IVC"
_ivc "$IVM" "$IV_C0" 'the branch side' src/conflict.txt 'branch side' src/plain.txt 'plain'; IV_PL="$IVC"
_ivc "$IVM" "$IV_C0" 'precedes, first' src/precedes.txt 'one'; IV_P1="$IVC"
_ivc "$IVM" "$IV_P1" 'precedes, second' src/precedes.txt "$(printf 'one\ntwo')"; IV_P2="$IVC"
# Main takes #4101 by squash (same content, no ancestry), a second edition
# that deletes old.txt, holds superseded.txt and partly-a.txt as the branches
# have them and changes conflict.txt, then #4102 squashed with an edit made
# in review, and one handoff section waiting in pending/.
printf 'squash feature\n' > "$IVM/src/squash.txt"
_ivwc "$IVM" 'the squash feature (#4101)'
rm -f "$IVM/src/old.txt"
printf 'widget, second edition\n' > "$IVM/README.md"; printf 'superseded\n' > "$IVM/src/superseded.txt"
printf 'A\n' > "$IVM/src/partly-a.txt"; printf 'main side\n' > "$IVM/src/conflict.txt"
_ivwc "$IVM" 'the second edition'
printf 'one\ntwo, as edited in review\n' > "$IVM/src/precedes.txt"
mkdir -p "$IVM/docs/handoff/pending"
cat > "$IVM/docs/handoff/pending/20260920T101010Z-frobnicator.md" <<'IVEOF'
### 2026-09-20 - the frobnicator waits

The frobnicator was designed here and not built.

**Next:**
- Build the frobnicator.
- Measure the frobnicator.

**Traps paid:**
- Ignore this trap line.
IVEOF
_ivwc "$IVM" 'precedes, squashed with an edit (#4102), and a pending handoff'
IV_C3="$(_ivg -C "$IVM" rev-parse HEAD)"
_ivg -C "$IVM" push -q origin main
_ivg -C "$IVM" remote set-head origin main

# ---- worktrees beside the clone, and two orphans -------------------------
_ivg -C "$IVM" branch topic/squash "$IV_S1"
_ivwt "$IVW/wt-squash" topic/squash
_ivwt -b topic/same "$IVW/wt-same" "$IV_C0"
for _ivn in dirty unpushed unproposed closed revert live query bold answered blocked unread; do
  _ivwt -b "topic/$_ivn" "$IVW/wt-$_ivn" "$IV_C3"
done
_ivg -C "$IVM" branch topic/shared "$IV_C3"
_ivwt "$IVW/wt-sharea" topic/shared
_ivwt -f "$IVW/wt-shareb" topic/shared
_ivwt --detach "$IVW/orphan-edit" "$IV_C3"
_ivwt --detach "$IVW/orphan-clean" "$IV_C3"
printf 'unpushed\n' > "$IVW/wt-unpushed/src/unpushed.txt"; _ivwc "$IVW/wt-unpushed" 'work nobody pushed'
printf 'unproposed\n' > "$IVW/wt-unproposed/src/unproposed.txt"; _ivwc "$IVW/wt-unproposed" 'work pushed with no pull request'
printf 'closed\n' > "$IVW/wt-closed/src/closed.txt"; _ivwc "$IVW/wt-closed" 'work whose pull request was closed'
IV_CL="$(_ivg -C "$IVW/wt-closed" rev-parse HEAD)"
# The staged revert, as the sweep found it: wt-revert commits its tip, then
# another checkout moves the branch on. wt-revert's HEAD follows the branch,
# and its index still holds the first tip.
printf 'revert one\n' > "$IVW/wt-revert/src/revert-one.txt"; _ivwc "$IVW/wt-revert" 'the first tip'
IV_R1="$(_ivg -C "$IVW/wt-revert" rev-parse HEAD)"
_ivc "$IVM" "$IV_R1" 'adopted by another checkout' src/revert-two.txt 'revert two'; IV_R2="$IVC"
_ivg -C "$IVM" update-ref -m 'adopted by another checkout' refs/heads/topic/revert "$IV_R2" "$IV_R1"
# Branches with no worktree: pull request heads (hold's felix/ready status
# sits on its parent, not its head), one pushed with no pull request, and
# local ones never pushed, two of them making the same change.
_ivc "$IVM" "$IV_C3" 'hold, first' src/hold.txt 'hold one'; IV_H0="$IVC"
_ivc "$IVM" "$IV_H0" 'hold, second' src/hold.txt 'hold two'; IV_H1="$IVC"
_ivc "$IVM" "$IV_C3" 'ready' src/ready.txt 'ready'; IV_Y1="$IVC"
_ivc "$IVM" "$IV_C3" 'needs the founder' src/needs.txt 'needs'; IV_N1="$IVC"
_ivc "$IVM" "$IV_C3" 'remote only' src/remote-only.txt 'remote only'; IV_RO="$IVC"
_ivc "$IVM" "$IV_C3" 'the duplicate, once' src/dup.txt 'duplicate'; IV_D1="$IVC"
_ivc "$IVM" "$IV_C3" 'the duplicate, twice' src/dup.txt 'duplicate'; IV_D2="$IVC"
_ivg -C "$IVM" branch topic/superseded "$IV_X1"
_ivg -C "$IVM" branch topic/partly "$IV_PA"
_ivg -C "$IVM" branch topic/precedes "$IV_P1"
_ivg -C "$IVM" branch topic/dup-one "$IV_D1"
_ivg -C "$IVM" branch topic/dup-two "$IV_D2"
_ivg -C "$IVM" push -q origin topic/squash topic/superseded topic/unproposed topic/closed topic/revert \
  "$IV_P2:refs/heads/topic/precedes" "$IV_PL:refs/heads/topic/pr-plain" "$IV_H1:refs/heads/topic/pr-hold" \
  "$IV_Y1:refs/heads/topic/pr-ready" "$IV_N1:refs/heads/topic/pr-needs" "$IV_RO:refs/heads/topic/remote-only"
# Uncommitted: a staged edit, an untracked file and an ignored one. Landed
# though dirty: an untracked file and an edit that both hold main's content,
# a deletion main made too, and an ignored file.
printf 'dirty edit\n' >> "$IVW/wt-dirty/src/core.txt"; _ivg -C "$IVW/wt-dirty" add src/core.txt
printf 'fresh\n' > "$IVW/wt-dirty/src/untracked-new.txt"; printf 'noise\n' > "$IVW/wt-dirty/build.log"
printf 'squash feature\n' > "$IVW/wt-same/src/squash.txt"; rm -f "$IVW/wt-same/src/old.txt"
printf 'widget, second edition\n' > "$IVW/wt-same/README.md"; printf 'noise\n' > "$IVW/wt-same/debug.log"
# The orphans: git's record of them goes and the files stay, .git link too.
# One holds two files whose content is in no object; the other holds none.
printf 'orphan-only line\n' >> "$IVW/orphan-edit/src/core.txt"
mkdir -p "$IVW/orphan-edit/notes"; printf 'only here\n' > "$IVW/orphan-edit/notes/orphan-new.txt"
rm -rf "$IVM/.git/worktrees/orphan-edit" "$IVM/.git/worktrees/orphan-clean"

# ---- gadget: a second repository, for --repo ----------------------------
_ivrepo "$IVO2" "$IVG" acme/gadget
printf 'gadget\n' > "$IVG/README.md"; _ivwc "$IVG" 'the first gadget'
_ivg -C "$IVG" push -q origin main
_ivg -C "$IVG" remote set-head origin main
_ivc "$IVG" "$(_ivg -C "$IVG" rev-parse HEAD)" 'gadget work nobody pushed' src/gadget.txt 'gadget'
_ivg -C "$IVG" branch topic/gadget-only "$IVC"

# Every index goes stale: a file's mtime moves and its content does not, so a
# git status that refreshes the index would rewrite it, and the read-only
# assertion sees any git read taken without --no-optional-locks.
for _ivn in widget $IV_WTS; do _ivtouch "$IVW/$_ivn/README.md" 1440; done
_ivtouch "$IVG/README.md" 1440

# ---- GitHub, as the stand-in answers it ----------------------------------
# One JSON object per pull request, in gh's field names. #4101 and #4102
# merged, #4107 and #4108 closed unmerged, five open.
: > "$IVGH/prs.lines"
printf -v IV_ROLL '{"__typename":"StatusContext","context":"felix/ready","state":"SUCCESS","targetUrl":"","description":"ready","startedAt":"%s"}' "$(_ivago 100 iso)"
_ivpr 4101 topic/squash     MERGED "$IV_S1" 2880 ''              UNKNOWN     ''         2880 2880
_ivpr 4102 topic/precedes   MERGED "$IV_P2" 2400 ''              UNKNOWN     ''         2400 2400
_ivpr 4103 topic/pr-hold    OPEN   "$IV_H1" 1800 'felix:hold'    MERGEABLE   ''         -    -
_ivpr 4104 topic/pr-ready   OPEN   "$IV_Y1" 120  'felix:founder' MERGEABLE   "$IV_ROLL" -    -
_ivpr 4105 topic/pr-plain   OPEN   "$IV_PL" 300  ''              CONFLICTING ''         -    -
_ivpr 4106 topic/pr-needs   OPEN   "$IV_N1" 480  'needs-founder' MERGEABLE   ''         -    -
_ivpr 4107 topic/closed     CLOSED "$IV_CL" 1200 ''              UNKNOWN     ''         -    1200
_ivpr 4108 topic/superseded CLOSED "$IV_X1" 1500 ''              UNKNOWN     ''         -    1500
_ivpr 4109 topic/revert     OPEN   "$IV_R2" 60   ''              MERGEABLE   ''         -    -
LC_ALL=C awk 'BEGIN { printf "[" } NR > 1 { printf "," } { printf "%s", $0 } END { print "]" }' "$IVGH/prs.lines" > "$IVGH/prs.json"
printf -v _ivst '{"context":"felix/ready","state":"success","description":"ready","target_url":"","created_at":"%s","updated_at":"%s","creator":{"login":"felix"}}' "$(_ivago 100 iso)" "$(_ivago 100 iso)"
printf '{"%s":[%s],"%s":[%s]}\n' "$IV_H0" "$_ivst" "$IV_Y1" "$_ivst" > "$IVGH/statuses.json"

# The gh stand-in: pr list/view/checks, repo view, auth status and api GETs
# for commit statuses and pulls, from the files above, in gh's shapes, with
# --json fields, --jq, --state, --head and --search head: honoured. Every call
# is logged first. It serves no graphql and no write.
printf '#!/bin/bash\nD=%s\nL=%s\n' "'$IVGH'" "'$IVGH_LOG'" > "$IVSTUB/gh"
cat >> "$IVSTUB/gh" <<'IVGHEOF'
set -f
printf '%s\n' "$*" >> "$L"
KEEP='def pr_keep($f): if $f == "" then . else ($f | split(",")) as $k | with_entries(select(.key as $x | any($k[]; . == $x))) end;'
SEL='def pr_sel($st; $hd): select(($st == "all") or ($st == "open" and .state == "OPEN") or ($st == "closed" and (.state == "CLOSED" or .state == "MERGED")) or ($st == "merged" and .state == "MERGED")) | select($hd == "" or .headRefName == $hd);'
REST='def pr_rest: {number, title, state: (if .state == "OPEN" then "open" else "closed" end), draft: .isDraft, merged_at: .mergedAt, closed_at: .closedAt, created_at: .createdAt, updated_at: .updatedAt, head: {ref: .headRefName, sha: .headRefOid, label: ("acme:" + .headRefName)}, base: {ref: .baseRefName}, labels: [.labels[] | {name}], user: {login: .author.login}, html_url: .url, mergeable: (if .mergeable == "CONFLICTING" then false elif .mergeable == "MERGEABLE" then true else null end), mergeable_state: (if .mergeable == "CONFLICTING" then "dirty" elif .mergeable == "MERGEABLE" then "clean" else "unknown" end)};'
FIND='def pr_find($p): [.[] | select((.number | tostring) == $p or .headRefName == $p)] | sort_by([(if .state == "OPEN" then 1 else 0 end), .updatedAt]) | last;'
CHECKS='def pr_checks($l): [$l[] | {name: .context, state: (.state | ascii_upcase), bucket: (if .state == "success" then "pass" elif .state == "pending" then "pending" else "fail" end), link: .target_url, description, workflow: ""}];'
COMB='(.[$s] // []) as $l | {sha: $s, total_count: ($l | length), statuses: $l, state: (if ($l | length) == 0 then "pending" elif all($l[]; .state == "success") then "success" elif any($l[]; .state == "failure" or .state == "error") then "failure" else "pending" end)}'
PLIST=' [.[] | pr_sel($st; $hd) | pr_keep($f)]'
PTSV=' .[] | pr_sel($st; $hd) | [(.number | tostring), .title, .headRefName, .state, .createdAt] | @tsv'
PVIEW=' pr_find($p) | if . == null then empty else pr_keep($f) end'
PSHA=' pr_find($p) | if . == null then empty else .headRefOid end'
PCHK=' pr_checks(.[$s] // [])'
PBYSHA=' [.[] | select(.headRefOid == $s) | pr_rest]'
PBYNUM=' [.[] | select((.number | tostring) == $n) | pr_rest] | .[0] // empty'
PREST=' [.[] | pr_sel($st; $hd) | pr_rest]'
KEEPALL=' [.[] | pr_keep($f)]'
KEEPONE=' pr_keep($f)'
REPO='{"nameWithOwner":"acme/widget","name":"widget","owner":{"login":"acme"},"defaultBranchRef":{"name":"main"},"url":"https://github.com/acme/widget","isPrivate":false}'
RREPO='{"full_name":"acme/widget","name":"widget","owner":{"login":"acme"},"default_branch":"main","private":false,"html_url":"https://github.com/acme/widget"}'
NF='{"message":"Not Found","status":"404"}'
out() { if [ -n "$q" ]; then jq -r "$q"; else jq -cS .; fi; }
nf()  { printf '%s\n' "$NF"; echo 'gh: Not Found (HTTP 404)' >&2; exit 1; }
no()  { echo 'gh: the stand-in serves reads only' >&2; exit 1; }
qv()  { printf '%s' "&$qs&" | tr '&' '\n' | sed -n "s/^$1=//p" | head -n 1; }
cmd="${1:-}"; [ $# -gt 0 ] && shift
sub=""
case "$cmd" in pr|repo|auth) sub="${1:-}"; [ $# -gt 0 ] && shift ;; esac
j=""; q=""; st=open; hd=""; se=""; me=""; fq=""; pos=""
while [ $# -gt 0 ]; do
  a="$1"; v="${2:-}"; n=2
  case "$a" in --*=*) v="${a#*=}"; a="${a%%=*}"; n=1 ;; esac
  case "$a" in
    --json) j="$v" ;;
    -q|--jq) q="$v" ;;
    -s|--state) st="$v" ;;
    --head) hd="$v" ;;
    -H) [ "$cmd" = api ] || hd="$v" ;;
    -S|--search) se="$v" ;;
    -X|--method) me="$v" ;;
    -f|-F|--field|--raw-field) fq="$fq&$v" ;;
    --input) fq="$fq&input" ;;
    --header|-R|--repo|-L|--limit|-t|--template|-B|--base|-A|--author|-l|--label|-a|--assignee|--hostname|--cache|-p|--preview) : ;;
    -*) n=1 ;;
    *) n=1; [ -n "$pos" ] || pos="$a" ;;
  esac
  if [ "$n" -eq 2 ] && [ $# -ge 2 ]; then shift 2; else shift; fi
done
for w in $se; do
  case "$w" in
    head:*) hd="${w#head:}" ;;
    is:open|state:open) st=open ;;
    is:closed|state:closed) st=closed ;;
    is:merged) st=merged ;;
  esac
done
case "$cmd:$sub" in
  --version:*|version:*) echo 'gh version 2.99.0 (stand-in)' ;;
  auth:status) echo 'github.com: logged in as fixture (stand-in)' >&2 ;;
  pr:list)
    if [ -z "$j" ]; then jq -r --arg st "$st" --arg hd "$hd" "$SEL$PTSV" "$D/prs.json"
    else jq -c --arg st "$st" --arg hd "$hd" --arg f "$j" "$KEEP$SEL$PLIST" "$D/prs.json" | out; fi ;;
  pr:view)
    r=$(jq -c --arg p "$pos" --arg f "$j" "$KEEP$FIND$PVIEW" "$D/prs.json")
    [ -n "$r" ] || { echo "no pull requests found for branch \"$pos\"" >&2; exit 1; }
    printf '%s\n' "$r" | out ;;
  pr:checks)
    s=$(jq -r --arg p "$pos" "$FIND$PSHA" "$D/prs.json")
    [ -n "$s" ] || { echo "no pull requests found for branch \"$pos\"" >&2; exit 1; }
    c=$(jq -c --arg s "$s" "$CHECKS$PCHK" "$D/statuses.json")
    [ "$c" != "[]" ] || { echo "no checks reported on the '$pos' branch" >&2; exit 1; }
    if [ -n "$j" ]; then printf '%s\n' "$c" | jq -c --arg f "$j" "$KEEP$KEEPALL" | out
    else printf '%s\n' "$c" | jq -r '.[] | [.name, .bucket, "0", .link, .description] | @tsv'; fi ;;
  repo:view) printf '%s\n' "$REPO" | jq -c --arg f "$j" "$KEEP$KEEPONE" | out ;;
  api:*)
    case "$me" in ""|GET|get) ;; *) no ;; esac
    [ -z "$fq" ] || [ -n "$me" ] || no
    p="${pos#/}"; qs=""
    case "$p" in *\?*) qs="${p#*\?}"; p="${p%%\?*}" ;; esac
    qs="$qs$fq"
    case "$p" in
      graphql) echo 'gh: the stand-in serves no graphql' >&2; exit 1 ;;
      */commits/*/status) s="${p%/status}"; s="${s##*/}"; jq -c --arg s "$s" "$COMB" "$D/statuses.json" | out ;;
      */commits/*/statuses) s="${p%/statuses}"; s="${s##*/}"; jq -c --arg s "$s" '.[$s] // []' "$D/statuses.json" | out ;;
      */statuses/*) s="${p##*/}"; jq -c --arg s "$s" '.[$s] // []' "$D/statuses.json" | out ;;
      */commits/*/check-runs) printf '%s\n' '{"total_count":0,"check_runs":[]}' | out ;;
      */commits/*/pulls) s="${p%/pulls}"; s="${s##*/}"; jq -c --arg s "$s" "$REST$PBYSHA" "$D/prs.json" | out ;;
      */pulls/*) n="${p##*/}"; case "$n" in ''|*[!0-9]*) nf ;; esac
                 r=$(jq -c --arg n "$n" "$REST$PBYNUM" "$D/prs.json"); [ -n "$r" ] || nf
                 printf '%s\n' "$r" | out ;;
      */pulls) s2=$(qv state); h2=$(qv head); h2="${h2#*:}"
               jq -c --arg st "${s2:-open}" --arg hd "$h2" "$REST$SEL$PREST" "$D/prs.json" | out ;;
      repos/*/*/*) nf ;;
      repos/*/*) printf '%s\n' "$RREPO" | out ;;
      *) nf ;;
    esac ;;
  *) echo "gh: the stand-in does not answer $cmd $sub" >&2; exit 1 ;;
esac
IVGHEOF
# The git stand-in logs each call, with GIT_OPTIONAL_LOCKS as git itself sets
# it for its children, and runs the real git.
cat > "$IVSTUB/git" <<IVGITEOF
#!/bin/sh
printf '%s\t%s\n' "\${GIT_OPTIONAL_LOCKS:-}" "\$*" >> "$IVGIT_LOG"
exec "$IV_REALGIT" "\$@"
IVGITEOF
chmod +x "$IVSTUB/gh" "$IVSTUB/git"

# ---- the host's session records ------------------------------------------
# wt-query: an older session ended on a statement, the newest on a question.
_ivopen "$IVW/wt-query" a1a1a1a1-0000-4000-8000-000000000001
_au_say  "$(_ivago 302 iso)" 'tidy the notes'
_au_stop "$(_ivago 300 iso)" msg_q0 'Tidied the notes.'
_ivtouch "$_AU_F" 300
_ivopen "$IVW/wt-query" a1a1a1a1-0000-4000-8000-000000000002
_au_say  "$(_ivago 182 iso)" 'prepare the push'
_au_stop "$(_ivago 180 iso)" msg_q1 'The branch is ready. Shall I push it?'
_ivtouch "$_AU_F" 180
# wt-bold: a question in bold, then only a system envelope.
_ivopen "$IVW/wt-bold" b2b2b2b2-0000-4000-8000-000000000001
_au_say  "$(_ivago 184 iso)" 'compare the two layouts'
_au_tool toolu_bold1 Bash '{"command":"ls","description":"List them"}'
_au_a    "$(_ivago 183 iso)" msg_b1 '"tool_use"' "$_AU_B"
_au_res  "$(_ivago 182 iso)" toolu_bold1 ok
_au_stop "$(_ivago 181 iso)" msg_b2 'Two layouts remain. **Which one do you want?**'
_au_say  "$(_ivago 180 iso)" '<system-reminder>A background task finished.</system-reminder>'
_ivtouch "$_AU_F" 180
# wt-answered: an older session ended on a question; the newest asked one and
# was answered. A fresh subagent transcript ending on a question is added
# just before the runs, under the newest session's subagents/ directory.
_ivopen "$IVW/wt-answered" c3c3c3c3-0000-4000-8000-000000000001
_au_say  "$(_ivago 302 iso)" 'clean up'
_au_stop "$(_ivago 300 iso)" msg_n0 'Shall I delete the scratch branch?'
_ivtouch "$_AU_F" 300
_ivopen "$IVW/wt-answered" "$IV_NID"
_au_say  "$(_ivago 183 iso)" 'get it ready'
_au_stop "$(_ivago 182 iso)" msg_n1 'It is ready. Should I push?'
_au_say  "$(_ivago 180 iso)" 'yes, push it'
_ivtouch "$_AU_F" 180
# wt-blocked: the last record is a tool call with no result, two hours old.
_ivopen "$IVW/wt-blocked" d4d4d4d4-0000-4000-8000-000000000001
_au_say  "$(_ivago 125 iso)" 'run the daily watch'
_au_tool toolu_k1 Bash '{"command":"date","description":"Read the clock"}'
_au_a    "$(_ivago 124 iso)" msg_k1 '"tool_use"' "$_AU_B"
_au_res  "$(_ivago 123 iso)" toolu_k1 ok
_au_tool toolu_k2 Bash '{"command":"watch-the-ledger","description":"Watch the ledger"}'
_au_a    "$(_ivago 120 iso)" msg_k2 '"tool_use"' "$_AU_B"
_ivtouch "$_AU_F" 120
# wt-unread: the newest session cannot be read at all. Spec §5.2 and §6.6
# (R4, ruled 2026-10-02): an unreadable session file anywhere under the records
# root leaves every chip proposed before its mtime unknown:chip-unstarted. Its
# mtime, 14500 minutes ago, is older than every proposal read inside the
# 14-day window (wt-squash's at 2882-2884 minutes, Zeta's, Theta's, and
# doohickey's Kappa at 14401), so the chips below stay decided, and the file,
# inside that window, is still compared.
_ivopen "$IVW/wt-unread" e5e5e5e5-0000-4000-8000-000000000001
_au_say  "$(_ivago 14502 iso)" 'look around'
_au_stop "$(_ivago 14500 iso)" msg_u1 'Shall I go on?'
_ivtouch "$_AU_F" 14500
IV_UNREAD="$_AU_F"; chmod 000 "$IV_UNREAD"
# wt-squash: five chips. Epsilon's session is twenty days old, past the
# default window of 14 (decision D4 of 2026-09-24; it was ten days old
# against the old default of 7). Alpha, Gamma and
# Delta come two days ago; Gamma is dismissed there; Alpha is started a day
# later by a session whose first human message repeats its prompt's first 120
# characters; Delta's prompt opens a session from before it was suggested,
# which starts nothing. Zeta is suggested in a directory of no worktree here.
_ivopen "$IVW/wt-squash" f6f6f6f6-0000-4000-8000-000000000001
_au_say  "$(_ivago 28802 iso)" 'note what is left'
_ivchip  "$(_ivago 28801 iso)" toolu_ce task_e5e5e5e5 'Epsilon chip too old' "$IV_PE_PROMPT"
_au_stop "$(_ivago 28800 iso)" msg_e9 'Noted.'
_ivtouch "$_AU_F" 28800
_ivopen "$IVW/wt-squash" f6f6f6f6-0000-4000-8000-000000000002
_au_say  "$(_ivago 2885 iso)" 'file the follow-ups'
_ivchip  "$(_ivago 2884 iso)" toolu_ca task_a1a1a1a1 'Alpha chip started later' "$IV_PA_PROMPT"
_ivchip  "$(_ivago 2883 iso)" toolu_cc task_c3c3c3c3 'Gamma chip dismissed' "$IV_PC_PROMPT"
_ivchip  "$(_ivago 2882 iso)" toolu_cd task_d4d4d4d4 'Delta chip never started' "$IV_PD_PROMPT"
_au_tool toolu_cx mcp__ccd_session__dismiss_task '{"task_id":"task_c3c3c3c3","reason":"fixed in this session"}'
_au_a    "$(_ivago 2881 iso)" msg_cx '"tool_use"' "$_AU_B"
_au_res  "$(_ivago 2881 iso)" toolu_cx ok
_au_stop "$(_ivago 2880 iso)" msg_cz 'Filed the follow-ups.'
_ivtouch "$_AU_F" 2880
_au_open "$IVP/-elsewhere-started/a7a7a7a7-0000-4000-8000-000000000001.jsonl" a7a7a7a7-0000-4000-8000-000000000001
_au_raw  '{"type":"queue-operation","operation":"enqueue","sessionId":"a7a7a7a7-0000-4000-8000-000000000001"}'
_au_say  "$(_ivago 1442 iso)" "${IV_PA_PROMPT:0:120} - and say so in the changelog."
_au_stop "$(_ivago 1440 iso)" msg_sa 'Done, and noted.'
_ivtouch "$_AU_F" 1440
_au_open "$IVP/-elsewhere-early/a8a8a8a8-0000-4000-8000-000000000001.jsonl" a8a8a8a8-0000-4000-8000-000000000001
_au_say  "$(_ivago 4322 iso)" "$IV_PD_PROMPT"
_au_stop "$(_ivago 4320 iso)" msg_se 'Done.'
_ivtouch "$_AU_F" 4320
_au_open "$IVP/-elsewhere-other/a9a9a9a9-0000-4000-8000-000000000001.jsonl" a9a9a9a9-0000-4000-8000-000000000001
_au_say  "$(_ivago 2885 iso)" 'look around'
_ivchip  "$(_ivago 2884 iso)" toolu_cf task_f6f6f6f6 'Zeta chip elsewhere' "$IV_PF_PROMPT"
_au_stop "$(_ivago 2880 iso)" msg_so 'Noted.'
_ivtouch "$_AU_F" 2880
}

# _iv_live: the live session and a fresh subagent transcript, written last so their ages at the
# runs are minutes. Needs _iv_build; the guard is the subagent transcript.
_iv_live() {
  [ -e "$(_ive "$IVW/wt-answered")/$IV_NID/subagents/agent-a1.jsonl" ] && return 0
# The live session and a fresh subagent transcript are written last, so their
# ages at the runs are minutes, then everything is listed and checksummed.
_ivopen "$IVW/wt-live" 99999999-0000-4000-8000-000000000001
_au_say  "$(_ivago 4 iso)" 'watch the build'
_au_tool toolu_l1 Bash '{"command":"make watch","description":"Watch the build"}'
_au_a    "$(_ivago 3 iso)" msg_l1 '"tool_use"' "$_AU_B"
_ivtouch "$_AU_F" 3
_au_open "$(_ive "$IVW/wt-answered")/$IV_NID/subagents/agent-a1.jsonl" agent-a1
_au_say  "$(_ivago 2 iso)" 'look into it'
_au_stop "$(_ivago 1 iso)" msg_sub 'Found it. Anything else?'
_ivtouch "$_AU_F" 1
}

# _iv_runs: the runs 0870 makes whose files 0890 reads, in 0870's order and with its commands.
# Needs _iv_build live. In the serial run they are made already and this does nothing.
_iv_runs() {
  IV_T1="$IV/t1.tsv"; IV_T0="$IV/t0.tsv"; IV_T0W="$IV/t0w.tsv"; IV_HU="$IV/human.txt"
  IV_T3="$IV/t3.tsv"; IV_T4="$IV/t4.tsv"; IV_T5="$IV/t5.tsv"; IV_T6="$IV/t6.tsv"
  IV_T7="$IV/t7.tsv"; IV_T8="$IV/t8.tsv"
  [ -e "$IV_T8" ] && return 0
  _ivrun inventory --tsv --repo "$IVM" > "$IV_T1"
  _ivrun inventory --tsv > "$IV_T0"
  _ivrun --cwd "$IVW/wt-squash" inventory --tsv > "$IV_T0W"
  _ivrun inventory --repo "$IVM" > "$IV_HU"
  _ivrun inventory --tsv --no-gh --repo "$IVM" > "$IV_T3"
  _ivrun inventory --tsv --no-host --repo "$IVM" > "$IV_T4"
  _iv_nogh
  _ivrun --path "$IV/nogh" inventory --tsv --repo "$IVM" > "$IV_T5"
  _ivrun --cwd "$IV/cwd" inventory --tsv --repo "$IVM" --repo "$IVG" > "$IV_T6"
  if /bin/bash -c 'case "$BASH_VERSION" in 3.*) exit 0 ;; esac; exit 1' 2>/dev/null; then
    mkdir -p "$IV/b32"; ln -sf /bin/bash "$IV/b32/bash"
    _ivrun --path "$IV/b32:$IVSTUB:$PATH" --bash /bin/bash inventory --tsv --repo "$IVM" > "$IV_T7"
  fi
  _ivrun inventory --tsv --repo "$IVM" --live 1 --blocked 1 --days 1 > "$IV_T8"
}
