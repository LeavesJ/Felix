_locale_bytes_vars
printf "\nbash's own collation and the BSD text tools decide nothing by locale\n"
# The neighbour of the block above, for the two classes it leaves out. Measured
# 2026-10-08 on macOS 26, bash 3.2.57, at b434425f (and main 6fe5f986), with a
# Latin-1 e-acute (\351), which is not UTF-8:
#
#   - bash collates its own globs and bracket ranges in the locale, so the first
#     project.json whose remote_match fits, and the first marketplace holding a
#     plugin, were chosen by who ran felix; and `case B in [a-z])` matched.
#   - BSD sed, tr and cut stop at such a byte; grep misses a match after it on
#     its line; awk aborts the whole program on a regex over it; and a pattern
#     holding it compiles to nothing, in grep and in [[ =~ ]]. Through those,
#     one byte hid a credential from secret-scan and from classify, turned the
#     Stop hook's gate off through project.json, killed a whole deny row, and
#     let a row be removed from a verifier table with no escape.
#
# The rules they hold the engine to are stated once, above felix_json_str in
# lib/resolve.sh: (1) a function whose answer can depend on bash's own
# collation, or that uses [[ =~ ]], declares LC_ALL=C in a local line, and a
# bracket over digits alone in bash's own pattern is spelled out,
# [0123456789]; (2) a text tool reading bytes the engine did not write, where
# its result decides something, is written LC_ALL=C <tool>, and inside the
# verdict functions listed below every one is. The contract and the sweep that
# found each site are in the memory root,
# audits/2026-10-08-locale-glob-bsd-tools/contract.md.
#
# Each locale-dependent assertion sets LCB_U8 (picked by the block above) in a
# subshell around the call under test, and skips by name where it is empty.
# glibc's sed, tr and cut read bytes, so on Linux several of these cannot fail
# and pass on the engine as it was; the comments at each say which.

# fragment a: escape.sh, secret-scan, classify's content rule and felix_added_lines (E1-E9)
#
# BSD grep, sed and cut in a UTF-8 locale on a byte that is not UTF-8 (\351, a
# Latin-1 e-acute): grep misses a match that lies after the byte on its line or
# ends right at it, and fails with rc 2 on a pattern holding it; sed stops with
# "illegal byte sequence" as soon as its regex must scan the byte. Every case
# below puts the byte where that turns a stop into silence, runs the one call
# under test in a subshell set to the UTF-8 locale, and reads the answer back
# outside it with LC_ALL=C tools. Each has a C control on the same fixture, so
# a fixture that cannot reach the escape cannot pass as fixed. glibc's sed does
# not fail this way. GNU grep fails another way: in a UTF-8 locale it takes a
# line holding a byte that is not UTF-8 as binary and prints no line from there
# on. E6 and E7 first failed so on the ubuntu runner, through a bare grep -v in
# felix_changed_paths and in secret-scan, which macOS had passed. Without the
# locale these skip.
_lgb_a_in() {  # C|lang|all <command...>: one call in that locale, in a subshell
  local how="$1"; shift
  case "$how" in
    C)    ( export LC_ALL=C; "$@" ) ;;
    lang) ( unset LC_ALL LC_COLLATE LC_CTYPE; export LANG="$LCB_U8"; "$@" ) ;;
    all)  ( export LC_ALL="$LCB_U8"; "$@" ) ;;
  esac
}
_lgb_a_git() { git -c user.email=t@t -c user.name=t -c core.quotepath=false "$@"; }
# An AWS key id's shape, built here from pieces so no literal sits in this file.
LGB_A_KID="AK""IA$(printf '%s%s%s%s' Q7RJ 4KLM 2NPW 8TXZ)"

# One repository, a base and a branch per case. At base: a deny table whose
# middle row holds the byte, a manifest, a verifier script whose second counted
# line holds the byte before what is counted, a source file and a docs file.
LGB_A_E="$TMP/lgb-a-escape"; mkdir -p "$LGB_A_E"
( _fx_cd "$LGB_A_E" && git init -q -b main && mkdir t tests src docs \
  && printf 'alpha\tstop\ncaf\351\tstop\nzeta\tstop\n' > t/deny.tsv \
  && printf 'requests>=2.0\n' > requirements.txt \
  && printf 'assert one\nx = caf\351; assert two\nassert three\n' > tests/check.sh \
  && printf 'base\n' > src/a.txt && printf '# notes\n' > docs/notes.md \
  && git add -A && _lgb_a_git commit -qm base \
  && git checkout -q -b e1z main && printf 'alpha\tstop\ncaf\351\tstop\n' > t/deny.tsv && _lgb_a_git commit -qam e1z \
  && git checkout -q -b e1a main && printf 'caf\351\tstop\nzeta\tstop\n' > t/deny.tsv && _lgb_a_git commit -qam e1a \
  && git checkout -q -b e2 main && printf 'evil>=1.0  # d\351pendance\n' >> requirements.txt && _lgb_a_git commit -qam e2 \
  && git checkout -q -b e3 main && printf 'assert one\nassert three\n' > tests/check.sh && _lgb_a_git commit -qam e3 \
  && git checkout -q -b e4 main && mkdir db && printf '/* donn\351es */ DROP TABLE t;\n' > db/x.sql \
     && git add db && _lgb_a_git commit -qm e4 \
  && git checkout -q -b e5 main && printf 'changed\n' > src/a.txt && _lgb_a_git commit -qam e5 \
  && git checkout -q -b e7 main && printf '# cl\351: aws = "%s"\n' "$LGB_A_KID" >> docs/notes.md && _lgb_a_git commit -qam e7 \
  && git checkout -q -b e9 main && printf '\351t\351: DROP TABLE t;\n' > docs/e9.txt && git add docs && _lgb_a_git commit -qm e9 \
  && git checkout -q main ) >/dev/null 2>&1
LGB_A_E="$(cd "$LGB_A_E" 2>/dev/null && pwd -P)" || LGB_A_E="$TMP/lgb-a-escape"

# A second repository for the workflow path, whose name holds the byte. APFS
# refuses that name on disk, so the file exists only in the index and the
# commit; the working tree's copy reads as deleted, which still lists the path.
LGB_A_W="$TMP/lgb-a-workflow"; mkdir -p "$LGB_A_W"
LGB_A_WF="$(printf '.github/workflows/\351t\351.yml')"
( _fx_cd "$LGB_A_W" && git init -q -b main && printf 'x\n' > README && git add README && _lgb_a_git commit -qm base \
  && git checkout -q -b e6 && LGB_A_b="$(printf 'on: push\n' | git hash-object -w --stdin)" \
  && git update-index --add --cacheinfo "100644,$LGB_A_b,$LGB_A_WF" && _lgb_a_git commit -qm e6 ) >/dev/null 2>&1
LGB_A_W="$(cd "$LGB_A_W" 2>/dev/null && pwd -P)" || LGB_A_W="$TMP/lgb-a-workflow"

# Projects: one with no risk table (only the engine's channels speak), and one
# per declared row under test.
LGB_A_P0="$TMP/lgb-a-p0"; LGB_A_P2="$TMP/lgb-a-p2"; LGB_A_P3="$TMP/lgb-a-p3"
LGB_A_P5="$TMP/lgb-a-p5"; LGB_A_P8="$TMP/lgb-a-p8"
mkdir -p "$LGB_A_P0" "$LGB_A_P2" "$LGB_A_P3" "$LGB_A_P5" "$LGB_A_P8"
# A confined manifest row: it stays quiet only while every changed line is a
# constraint and the package names on both sides agree.
printf 'yellow\tpath\t(^|/)requirements\\.txt$\ta dependency change\tdependency\t^[-+][A-Za-z0-9._-]+[<>=~!]=\n' \
  > "$LGB_A_P2/risk.tsv"
# A count: verifier row over the script's asserts.
printf 'red\tpath\t(^|/)tests/check\\.sh$\tthe checks the suite runs\tverifier\tcount:assert\n' > "$LGB_A_P3/risk.tsv"
# A path row whose pattern's second alternative holds the byte.
printf 'yellow\tpath\t^(src/|donn\351es/)\tsource changes go past a person\tdeploy\t-\n' > "$LGB_A_P5/risk.tsv"
# A red content rule for a key id, and a green rule for docs.
printf 'red\tcontent\t(AKIA|ASIA)[0-9A-Z]{16}\ta credential\ngreen\tpath\t^docs/\tdocumentation\n' > "$LGB_A_P8/risk.tsv"

# Never a git command with an empty or missing -C.
_lgb_a_esc() {  # <repo> <branch> <project>: felix_escapes for that branch against main, raw lines
  [ -n "$1" ] && [ -d "$1/.git" ] || { printf 'no fixture'; return 0; }
  _fx_git "$1" checkout -q "$2" >/dev/null 2>&1 || { printf 'no branch %s' "$2"; return 0; }
  ( cd "$1" && export GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=core.quotepath GIT_CONFIG_VALUE_0=false
    . "$FROOT/harness/lib/escape.sh"; felix_escapes "$3" main "$1" ) </dev/null 2>/dev/null
}
_lgb_a_ch() {  # <path>: stdin escape lines -> the channels named for that path, space-separated
  LC_ALL=C awk -F'\t' -v p="$1" '$2 == p { printf "%s%s", s, $1; s = " " }'
}
_lgb_a_scan() {  # <branch>: secret-scan's exit status for that branch against main
  [ -n "$LGB_A_E" ] && [ -d "$LGB_A_E/.git" ] || { printf 'no fixture'; return 0; }
  _fx_git "$LGB_A_E" checkout -q "$1" >/dev/null 2>&1 || { printf 'no branch %s' "$1"; return 0; }
  ( cd "$LGB_A_E" && "$FROOT/harness/bin/secret-scan" main ) </dev/null >/dev/null 2>&1
  printf 'rc=%s' "$?"
}
_lgb_a_tier() {  # <branch> <project>: classify's tier for that branch against main
  [ -n "$LGB_A_E" ] && [ -d "$LGB_A_E/.git" ] || { printf 'no fixture'; return 0; }
  _fx_git "$LGB_A_E" checkout -q "$1" >/dev/null 2>&1 || { printf 'no branch %s' "$1"; return 0; }
  ( cd "$LGB_A_E" && . "$FROOT/harness/lib/classify.sh"
    felix_classify_tier "$(felix_classify_diff "$2" main "$LGB_A_E")" ) </dev/null 2>/dev/null
}
_lgb_a_added() {  # <branch>: felix_added_lines for that branch against main, raw
  [ -n "$LGB_A_E" ] && [ -d "$LGB_A_E/.git" ] || { printf 'no fixture'; return 0; }
  _fx_git "$LGB_A_E" checkout -q "$1" >/dev/null 2>&1 || { printf 'no branch %s' "$1"; return 0; }
  ( cd "$LGB_A_E" && . "$FROOT/harness/lib/resolve.sh"; felix_added_lines "$LGB_A_E" main ) </dev/null 2>/dev/null
}

# C controls: each fixture reaches its escape at all.
is  "in C, the foreign-byte escape fixture's deny table removal of the row after the byte row is a verifier escape" \
    "$(_lgb_a_in C _lgb_a_esc "$LGB_A_E" e1z "$LGB_A_P0" | _lgb_a_ch t/deny.tsv)" "verifier"
is  "in C, a new dependency on a manifest line ending in a Latin-1 comment fires the confined row" \
    "$(_lgb_a_in C _lgb_a_esc "$LGB_A_E" e2 "$LGB_A_P2" | _lgb_a_ch requirements.txt)" "dependency"
is  "in C, removing the counted line that holds the byte fires the count: row" \
    "$(_lgb_a_in C _lgb_a_esc "$LGB_A_E" e3 "$LGB_A_P3" | _lgb_a_ch tests/check.sh)" "verifier"
is  "in C, destructive SQL after a Latin-1 comment in the added lines is a durable escape" \
    "$(_lgb_a_in C _lgb_a_esc "$LGB_A_E" e4 "$LGB_A_P0" | _lgb_a_ch ADDED-LINES)" "durable"
is  "in C, a risk row whose pattern holds the byte in another alternative fires on src/" \
    "$(_lgb_a_in C _lgb_a_esc "$LGB_A_E" e5 "$LGB_A_P5" | _lgb_a_ch src/a.txt)" "deploy"
is  "in C, a committed workflow whose name holds the byte is an execute escape" \
    "$(_lgb_a_in C _lgb_a_esc "$LGB_A_W" e6 "$LGB_A_P0" | _lgb_a_ch "$LGB_A_WF")" "execute"
is  "in C, secret-scan refuses a key id that follows a Latin-1 byte on its added line" \
    "$(_lgb_a_in C _lgb_a_scan e7)" "rc=1"
is  "in C, classify rates red an added key id after a Latin-1 byte in a docs file" \
    "$(_lgb_a_in C _lgb_a_tier e7 "$LGB_A_P8")" "red"
is  "in C, felix_added_lines keeps an added line whose first byte after the plus is not UTF-8" \
    "$(_lgb_a_in C _lgb_a_added e9 | LC_ALL=C grep -c 'DROP TABLE t;')" "1"

LGB_A_1L="in a UTF-8 locale with LANG set and LC_ALL unset, removing a deny row after a row holding a byte that is not UTF-8 is still a verifier escape"
LGB_A_1A="in a UTF-8 locale with LC_ALL set, removing a deny row after a row holding a byte that is not UTF-8 is still a verifier escape"
LGB_A_1P="in a UTF-8 locale, removing the deny row before the byte row is still a verifier escape"
LGB_A_2="in a UTF-8 locale, a new dependency on a manifest line ending in a Latin-1 comment still fires the confined row"
LGB_A_3="in a UTF-8 locale, removing a counted line that holds a byte that is not UTF-8 still fires the count: row"
LGB_A_4="in a UTF-8 locale, an added line DROP TABLE after a Latin-1 comment is still a durable ADDED-LINES escape"
LGB_A_5="in a UTF-8 locale, a project risk row whose pattern holds a byte that is not UTF-8 still fires on a change to src/"
LGB_A_6="in a UTF-8 locale, a committed workflow path holding a byte that is not UTF-8, read with core.quotepath=false, is still an execute escape"
LGB_A_7="in a UTF-8 locale, secret-scan still exits non-zero on a key id that follows a Latin-1 byte on its added line"
LGB_A_8="in a UTF-8 locale, classify still rates red an added key id after a Latin-1 byte, over a green docs path rule"
LGB_A_9="in a UTF-8 locale, felix_added_lines still keeps an added line whose first byte after the plus is not UTF-8"
if [ -n "$LCB_U8" ]; then
  is  "$LGB_A_1L" "$(_lgb_a_in lang _lgb_a_esc "$LGB_A_E" e1z "$LGB_A_P0" | _lgb_a_ch t/deny.tsv)" "verifier"
  is  "$LGB_A_1A" "$(_lgb_a_in all  _lgb_a_esc "$LGB_A_E" e1z "$LGB_A_P0" | _lgb_a_ch t/deny.tsv)" "verifier"
  # Holds on the engine as it was (the row before the byte survives the
  # truncation); pins that the fix does not lose it.
  is  "$LGB_A_1P" "$(_lgb_a_in all  _lgb_a_esc "$LGB_A_E" e1a "$LGB_A_P0" | _lgb_a_ch t/deny.tsv)" "verifier"
  is  "$LGB_A_2"  "$(_lgb_a_in all  _lgb_a_esc "$LGB_A_E" e2  "$LGB_A_P2" | _lgb_a_ch requirements.txt)" "dependency"
  is  "$LGB_A_3"  "$(_lgb_a_in all  _lgb_a_esc "$LGB_A_E" e3  "$LGB_A_P3" | _lgb_a_ch tests/check.sh)" "verifier"
  is  "$LGB_A_4"  "$(_lgb_a_in all  _lgb_a_esc "$LGB_A_E" e4  "$LGB_A_P0" | _lgb_a_ch ADDED-LINES)" "durable"
  is  "$LGB_A_5"  "$(_lgb_a_in all  _lgb_a_esc "$LGB_A_E" e5  "$LGB_A_P5" | _lgb_a_ch src/a.txt)" "deploy"
  is  "$LGB_A_6"  "$(_lgb_a_in all  _lgb_a_esc "$LGB_A_W" e6  "$LGB_A_P0" | _lgb_a_ch "$LGB_A_WF")" "execute"
  is  "$LGB_A_7"  "$(_lgb_a_in all  _lgb_a_scan e7)" "rc=1"
  is  "$LGB_A_8"  "$(_lgb_a_in all  _lgb_a_tier e7 "$LGB_A_P8")" "red"
  is  "$LGB_A_9"  "$(_lgb_a_in all  _lgb_a_added e9 | LC_ALL=C grep -c 'DROP TABLE t;')" "1"
else
  for a in "$LGB_A_1L" "$LGB_A_1A" "$LGB_A_1P" "$LGB_A_2" "$LGB_A_3" "$LGB_A_4" "$LGB_A_5" \
           "$LGB_A_6" "$LGB_A_7" "$LGB_A_8" "$LGB_A_9"; do skip "$a" "$LCB_NONE"; done
fi
[ -n "$LGB_A_E" ] && [ -d "$LGB_A_E/.git" ] && _fx_git "$LGB_A_E" checkout -q main >/dev/null 2>&1

# fragment b: E10 E11 E12 E13 E14 F1 (project.json, deny.tsv, risk.tsv, evidence.tsv, the release target, the receipt)
#
# Each fixture puts one Latin-1 e-acute (\351, not UTF-8) where the contract
# says it bites, and each locale-dependent assertion has a C control on the
# same fixture beside it, so a fixture that cannot reach the code path cannot
# read as fixed. BSD sed, cut and grep stop or miss on that byte under a UTF-8
# locale, and bash's [[ =~ ]] compiles a pattern holding it to nothing; glibc
# sed, cut and grep do not stop on it, so on Linux the sed, cut and grep cases
# here cannot fail and pass on the engine as it was.
#
# One call in a chosen locale: C, `lang` (LANG set and every LC_ unset, as a
# Terminal has it) or `all` (LC_ALL set). Only the call is in the subshell.
_lgb_b_in() {  # C|lang|all <command...>
  local how="$1"; shift
  case "$how" in
    C)    ( export LC_ALL=C; "$@" ) ;;
    lang) ( unset LC_ALL LC_COLLATE LC_CTYPE; export LANG="$LCB_U8"; "$@" ) ;;
    all)  ( export LC_ALL="$LCB_U8"; "$@" ) ;;
  esac
}
# Each name below, asserted in a UTF-8 locale, or skipped by the same name.
_lgb_b_u8() {  # <name> <how> <expected> <command...>
  local name="$1" how="$2" want="$3"; shift 3
  if [ -n "$LCB_U8" ]; then is "$name" "$(_lgb_b_in "$how" "$@")" "$want"; else skip "$name" "$LCB_NONE"; fi
}

# ---- E10: project.json read by felix_json_str (O8) ----
# A project whose description line, above remote_match and gate, holds the
# byte. sed -n 's/.../p' stops at that line in a UTF-8 locale, so every key on
# or below it reads empty: no gate, and the Stop hook exits 0 without judging
# completion; no remote_match, and the checkout is ungoverned.
LGB_B_P="$FROOT/projects/lgbb"
mkdir -p "$LGB_B_P"
{ printf '{\n'
  printf '  "name": "lgbb",\n'
  printf '  "description": "caf\351 au lait, a project whose description is Latin-1",\n'
  printf '  "remote_match": "example.com/lgbb-caf",\n'
  printf '  "gate": "sh -c '"'"'test -f LGBB.txt && echo lgbb-gate-ran'"'"'"\n'
  printf '}\n'; } > "$LGB_B_P/project.json"
printf '# lgbb\n' > "$LGB_B_P/CLAUDE.md"
_lgb_b_json() {  # remote_match|gate, as felix_json_str reads them
  ( . "$FROOT/harness/lib/resolve.sh"
    printf '%s|%s' "$(felix_json_str "$LGB_B_P/project.json" remote_match)" \
                   "$(felix_json_str "$LGB_B_P/project.json" gate)" ) </dev/null 2>/dev/null
}
LGB_B_JW="example.com/lgbb-caf|sh -c 'test -f LGBB.txt && echo lgbb-gate-ran'"
is  "in C, felix_json_str reads remote_match and gate from a project.json whose description line above them holds a byte that is not UTF-8" \
    "$(_lgb_b_in C _lgb_b_json)" "$LGB_B_JW"
_lgb_b_u8 "in a UTF-8 locale with LC_ALL set, felix_json_str still reads remote_match and gate below a description line holding a byte that is not UTF-8" \
    all "$LGB_B_JW" _lgb_b_json
_lgb_b_u8 "and with LANG set and LC_ALL unset, felix_json_str reads them too" \
    lang "$LGB_B_JW" _lgb_b_json

# End to end, two ways. A checkout whose origin names the project's
# remote_match and that holds no marker: felix_resolve_project binds it
# through that project.json. And a checkout bound to it by marker, dirty,
# with no receipt: the Stop hook holds it.
LGB_B_RR="$TMP/lgb-b-remote"; mkdir -p "$LGB_B_RR"
( _fx_cd "$LGB_B_RR" && git init -q -b main ) >/dev/null 2>&1
LGB_B_RR="$(cd "$LGB_B_RR" && pwd -P)" || LGB_B_RR=""
[ -n "$LGB_B_RR" ] && [ -d "$LGB_B_RR/.git" ] \
  && _fx_git "$LGB_B_RR" config remote.origin.url "git@example.com:acme/example.com/lgbb-caf.git"
_lgb_b_resolve() {
  [ -n "$LGB_B_RR" ] && [ -d "$LGB_B_RR/.git" ] || { printf 'no fixture'; return 0; }
  ( . "$FROOT/harness/lib/resolve.sh"; cd "$LGB_B_RR" || exit 1
    p="$(felix_resolve_project "$LGB_B_RR" "$FROOT")" && printf '%s' "${p##*/}" || printf 'unresolved' ) </dev/null 2>/dev/null
}
is  "in C, a checkout whose origin names that project's remote_match resolves to it" "$(_lgb_b_in C _lgb_b_resolve)" "lgbb"
_lgb_b_u8 "in a UTF-8 locale, felix_resolve_project still binds that checkout through the project.json whose description holds the byte" \
    all "lgbb" _lgb_b_resolve

LGB_B_SR="$TMP/lgb-b-stop"; mkdir -p "$LGB_B_SR"
( _fx_cd "$LGB_B_SR" && git init -q -b main && printf 'contents\n' > LGBB.txt && printf 'lgbb\n' > .felix \
  && git add -A && git -c user.name=t -c user.email=t@t commit -qm init ) >/dev/null 2>&1
LGB_B_SR="$(cd "$LGB_B_SR" && pwd -P)" || LGB_B_SR=""
[ -n "$LGB_B_SR" ] && [ -f "$LGB_B_SR/LGBB.txt" ] && printf 'unverified\n' >> "$LGB_B_SR/LGBB.txt"
_lgb_b_stop() {  # block | silent | other:<output>
  [ -n "$LGB_B_SR" ] && [ -d "$LGB_B_SR/.git" ] || { printf 'no fixture'; return 0; }
  local o
  o="$(cd "$LGB_B_SR" && printf '%s' '{"hook_event_name":"Stop","stop_hook_active":false}' \
        | "$FROOT/harness/hooks/stop" 2>&1)"
  case "$o" in
    *'"decision"'*'"block"'*) printf 'block' ;;
    '') printf 'silent' ;;
    *) printf 'other:%s' "$o" ;;
  esac
}
is  "in C, the Stop hook holds a dirty checkout bound to that project with no receipt" "$(_lgb_b_in C _lgb_b_stop)" "block"
_lgb_b_u8 "in a UTF-8 locale, the Stop hook still holds that dirty checkout, the byte above gate notwithstanding" \
    all "block" _lgb_b_stop

# ---- E11: a deny row whose pattern holds the byte (O11) ----
# bash compiles a [[ =~ ]] pattern holding a byte that is not UTF-8 to nothing
# in a UTF-8 locale, so every ASCII alternative in that row dies with it. The
# control row is the same pattern with the byte spelled `e`.
LGB_B_D="$TMP/lgb-b-deny"; LGB_B_DA="$TMP/lgb-b-deny-ascii"; mkdir -p "$LGB_B_D" "$LGB_B_DA"
printf 'Bash\tgit push (-f|--force)|rm -rf /caf\351\tno force push here\n' > "$LGB_B_D/deny.tsv"
printf 'Bash\tgit push (-f|--force)|rm -rf /cafe\tno force push here\n'    > "$LGB_B_DA/deny.tsv"
_lgb_b_deny() {  # <proj>: refused | allowed
  ( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/deny.sh"
    felix_deny_match "$1" Bash "git push --force origin main" "$TMP" >/dev/null && printf 'refused' || printf 'allowed' ) </dev/null 2>/dev/null
}
is  "in C, a deny row whose pattern holds a byte that is not UTF-8 refuses git push --force origin main" "$(_lgb_b_in C _lgb_b_deny "$LGB_B_D")" "refused"
_lgb_b_u8 "in a UTF-8 locale, the same row spelled in ASCII refuses git push --force origin main through felix_deny_match" \
    all "refused" _lgb_b_deny "$LGB_B_DA"
_lgb_b_u8 "in a UTF-8 locale with LC_ALL set, a deny row whose pattern holds a byte that is not UTF-8 still refuses git push --force origin main" \
    all "refused" _lgb_b_deny "$LGB_B_D"
_lgb_b_u8 "and with LANG set and LC_ALL unset, that row still refuses it" \
    lang "refused" _lgb_b_deny "$LGB_B_D"

# ---- E12 and E13: risk.tsv path row and evidence.tsv when cell holding the byte (O13, O14) ----
# A repository whose branch adds secrets/prod.env and src/api/x.py and no
# test; a project outside it whose red path row and whose evidence when cell
# each end in an alternative holding the byte. grep -qE with that pattern
# fails rc 2 in a UTF-8 locale, so the red rule never fires (the path falls to
# yellow) and the evidence row reads n/a instead of gap.
LGB_B_C="$TMP/lgb-b-classify"; LGB_B_CP="$TMP/lgb-b-classify-proj"; mkdir -p "$LGB_B_C" "$LGB_B_CP"
( _fx_cd "$LGB_B_C" && git init -q -b main && printf 'readme\n' > README \
  && git add -A && git -c user.name=t -c user.email=t@t commit -qm base \
  && git checkout -q -b work && mkdir -p secrets src/api && printf 'K=v\n' > secrets/prod.env \
  && printf 'x = 1\n' > src/api/x.py && git add -A && git -c user.name=t -c user.email=t@t commit -qm work ) >/dev/null 2>&1
LGB_B_C="$(cd "$LGB_B_C" && pwd -P)" || LGB_B_C=""
printf 'red\tpath\t(^|/)secrets/|^caf\351/\tsecrets are red\n' > "$LGB_B_CP/risk.tsv"
printf 'api-tests\t^src/api/|^caf\351/\t^tests/\tan api change ships a test\n' > "$LGB_B_CP/evidence.tsv"
_lgb_b_tier() {
  [ -n "$LGB_B_C" ] && [ -d "$LGB_B_C/.git" ] || { printf 'no fixture'; return 0; }
  ( cd "$LGB_B_C" && . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/classify.sh"
    felix_classify_tier "$(felix_classify_diff "$LGB_B_CP" main "$LGB_B_C")" ) </dev/null 2>/dev/null
}
_lgb_b_sev() {
  ( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/classify.sh"; . "$FROOT/harness/lib/incident.sh"
    felix_incident_severity "$LGB_B_CP" "secrets/prod.env" ) </dev/null 2>/dev/null
}
_lgb_b_evid() {  # the api-tests row's status, captured inside and read outside
  [ -n "$LGB_B_C" ] && [ -d "$LGB_B_C/.git" ] || { printf 'no fixture'; return 0; }
  ( cd "$LGB_B_C" && . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/evidence.sh"
    felix_evidence_check "$LGB_B_CP" main "$LGB_B_C" ) </dev/null 2>/dev/null
}
_lgb_b_evid_status() {  # <locale shape>
  _lgb_b_in "$1" _lgb_b_evid | LC_ALL=C awk -F'\t' '$2 == "api-tests" { printf "%s", $1 }'
}
is  "in C, a red path row whose pattern ends in an alternative holding a byte that is not UTF-8 makes a diff adding secrets/prod.env red" \
    "$(_lgb_b_in C _lgb_b_tier)" "red"
_lgb_b_u8 "in a UTF-8 locale, that red path row still makes the diff adding secrets/prod.env red" all "red" _lgb_b_tier
is  "in C, felix_incident_severity rates secrets/prod.env red by that row" "$(_lgb_b_in C _lgb_b_sev)" "red"
_lgb_b_u8 "in a UTF-8 locale, felix_incident_severity still rates secrets/prod.env red by the row holding the byte" all "red" _lgb_b_sev
is  "in C, an evidence row whose when cell holds a byte that is not UTF-8 reports a gap for a change to src/api with no test" \
    "$(_lgb_b_evid_status C)" "gap"
if [ -n "$LCB_U8" ]; then
  is  "in a UTF-8 locale, that evidence row still reports the gap rather than n/a" "$(_lgb_b_evid_status all)" "gap"
else
  skip "in a UTF-8 locale, that evidence row still reports the gap rather than n/a" "$LCB_NONE"
fi

# ---- E14: a release target holding the byte, no probes (O15) ----
# The project declares no probes, so the topology is unknown and felix_epoch
# must refuse. The release target is the last component, and cut -f2 stops on
# it in a UTF-8 locale; under pipefail its status hides the `-` awk saw, and
# an epoch is hashed over the unknown. The ASCII target is the control.
LGB_B_E="$TMP/lgb-b-epoch-proj"; mkdir -p "$LGB_B_E"
printf '{\n  "name": "lgbe",\n  "remote_match": "example.com/lgbe"\n}\n' > "$LGB_B_E/project.json"
_lgb_b_epoch() {  # <release target>: rc=N
  [ -n "$LGB_B_C" ] && [ -d "$LGB_B_C/.git" ] || { printf 'no fixture'; return 0; }
  ( cd "$LGB_B_C" && . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/epoch.sh"
    FELIX_RELEASE_TARGET="$1" felix_epoch "$LGB_B_E" "$LGB_B_C" >/dev/null; printf 'rc=%s' "$?" ) </dev/null 2>/dev/null
}
LGB_B_RT="$(printf 'r\351lease')"
is  "in C, felix_epoch refuses (rc 1) for a project with no probes whose release target holds a byte that is not UTF-8" \
    "$(_lgb_b_in C _lgb_b_epoch "$LGB_B_RT")" "rc=1"
_lgb_b_u8 "in a UTF-8 locale, felix_epoch refuses (rc 1) for that project with an ASCII release target" all "rc=1" _lgb_b_epoch "release"
_lgb_b_u8 "in a UTF-8 locale, felix_epoch still refuses (rc 1) when the release target holds the byte, rather than hashing over the unknown topology" \
    all "rc=1" _lgb_b_epoch "$LGB_B_RT"

# ---- F1: a green receipt whose skipped field holds the byte (C1) ----
# A project with ASCII tables and one probe, a clean committed checkout bound
# to it, and a green receipt for that tree written in C whose fifth field (the
# checks the gate reported skipped) holds the byte, as a gate printing a
# Latin-1 check name would leave it. cut -f2 on the receipt stops in a UTF-8
# locale and the receipt reads red.
LGB_B_FP="$FROOT/projects/lgbbr"; LGB_B_FR="$TMP/lgb-b-receipt"
mkdir -p "$LGB_B_FP" "$LGB_B_FR"
printf '{\n  "name": "lgbbr",\n  "remote_match": "example.com/lgbbr",\n  "gate": "true"\n}\n' > "$LGB_B_FP/project.json"
printf '# lgbbr\n' > "$LGB_B_FP/CLAUDE.md"
printf 'marker\t-\t-\tls -1 .felix\ttest -f .felix\n' > "$LGB_B_FP/probes.tsv"
( _fx_cd "$LGB_B_FR" && git init -q -b main && printf 'lgbbr\n' > .felix && printf 'x\n' > X.txt \
  && git add -A && git -c user.name=t -c user.email=t@t commit -qm init ) >/dev/null 2>&1
LGB_B_FR="$(cd "$LGB_B_FR" && pwd -P)" || LGB_B_FR=""
LGB_B_SKIP="$(printf 'caf\351-check')"
if [ -n "$LGB_B_FR" ] && [ -d "$LGB_B_FR/.git" ]; then
  ( export LC_ALL=C; cd "$LGB_B_FR" && . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/verify.sh"
    felix_verify_record "$LGB_B_FR" "$FROOT" 0 "gate" "$(felix_tree_id "$LGB_B_FR" "$FROOT")" "$LGB_B_SKIP" "" ) </dev/null >/dev/null 2>&1
fi
_lgb_b_current() {  # the first field of felix_verify_current's answer, captured inside, cut outside
  [ -n "$LGB_B_FR" ] && [ -d "$LGB_B_FR/.git" ] || { printf 'no fixture'; return 0; }
  ( cd "$LGB_B_FR" && . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/verify.sh"
    felix_verify_current "$LGB_B_FR" "$FROOT" "$LGB_B_FP" ) </dev/null 2>/dev/null
}
_lgb_b_current_word() { _lgb_b_in "$1" _lgb_b_current | LC_ALL=C awk -F'\t' 'NR == 1 { printf "%s", $1 }'; }
is  "the receipt fixture's fifth field holds the byte that is not UTF-8, and in C felix_verify_current reads it current" \
    "$( [ -n "$LGB_B_FR" ] && LC_ALL=C awk -F'\t' -v s="$LGB_B_SKIP" '{ printf "%s|%s", $2, ($5 == s) }' \
          "$FROOT/state/gate/$(printf '%s' "$LGB_B_FR" | git hash-object --stdin)" 2>/dev/null)|$(_lgb_b_current_word C)" \
    "green|1|current"
if [ -n "$LCB_U8" ]; then
  is  "in a UTF-8 locale, felix_verify_current reads that green receipt for this tree as current, the byte in its skipped field notwithstanding" \
      "$(_lgb_b_current_word all)" "current"
else
  skip "in a UTF-8 locale, felix_verify_current reads that green receipt for this tree as current, the byte in its skipped field notwithstanding" "$LCB_NONE"
fi

# The two projects this fragment added to the fixture home leave with it, so
# no later block lists them.
rm -rf "$LGB_B_P" "$LGB_B_FP"

# fragment c: maintenance, incident paths, commissioning counts, discover's
# stack.tsv and .mcp.json reads, the handoff check, felix scope, felix route,
# the obligations scan, felix_probes_run and the ledger summary (E15-E21,
# F2-F6). Written blind from the contract, before any fix.
#
# Every fixture puts one byte that is not UTF-8 (\351 or \374, Latin-1) where
# the contract says BSD text tools stop on it in a UTF-8 locale. Each case has
# a control in C on the same fixture, so a fixture that cannot reach the
# verdict fails the control instead of passing as fixed. The engine call runs
# in a subshell in the chosen locale; everything that reads its output here is
# pinned to LC_ALL=C, because the suite itself may run in a UTF-8 Terminal.
# glibc's tools do not stop on such a byte the way BSD's do, so on a Linux
# runner with en_US.UTF-8 these pass on the engine as it was and cannot fail
# there; without the locale they skip by name.
_lgb_c_in() {  # C|lang|all <command...>: one call in that locale, in a subshell
  local how="$1"; shift
  case "$how" in
    C)    ( export LC_ALL=C; "$@" ) ;;
    lang) ( unset LC_ALL LC_COLLATE LC_CTYPE; export LANG="$LCB_U8"; "$@" ) ;;
    all)  ( export LC_ALL="$LCB_U8"; "$@" ) ;;
  esac
}
# One assertion under UTF-8, or its skip by the same name.
_lgb_c_u8() {  # name how fn expected
  if [ -n "$LCB_U8" ]; then is "$1" "$(_lgb_c_in "$2" "$3")" "$4"; else skip "$1" "$LCB_NONE"; fi
}

# A home, a project bound by marker and a checkout of this fragment's own, so
# no table the rest of the suite reads gains a row.
LGB_C_HOME="$TMP/lgb_c_home"; LGB_C_MEM="$TMP/lgb_c_mem"; LGB_C_KC="$TMP/lgb_c_kc"
LGB_C_PROJ="$LGB_C_HOME/projects/lgbc"
mkdir -p "$LGB_C_PROJ" "$LGB_C_MEM"
printf '{"name":"lgbc","gate":"true"}\n' > "$LGB_C_PROJ/project.json"
printf '# lgbc\n' > "$LGB_C_PROJ/CLAUDE.md"
LGB_C_REPO="$TMP/lgb_c_repo"; mkdir -p "$LGB_C_REPO"
( _fx_cd "$LGB_C_REPO" && git init -q -b main && printf 'lgbc\n' > .felix && printf 'x\n' > a.txt \
  && git add -A >/dev/null && git -c user.name=t -c user.email=t@t commit -qm base >/dev/null ) >/dev/null 2>&1
LGB_C_REPO="$(cd "$LGB_C_REPO" && pwd -P)" || LGB_C_REPO="$TMP/lgb_c_repo"
_lgb_c_felix() {  # <felix args...>: the real CLI, in the fragment's checkout, home and memory
  ( cd "$LGB_C_REPO" || exit 99
    [ -f .felix ] || exit 99
    FELIX_KERNEL='' FELIX_KERNEL_CACHE="$LGB_C_KC" FELIX_HOME="$LGB_C_HOME" FELIX_MEMORY="$LGB_C_MEM" \
      "$FELIX" "$@" ) </dev/null
}

# E15 (O16). felix_maint_status cuts each row's fields with cut, which in a
# UTF-8 locale prints nothing of a line holding the byte, so the second
# routine has no name and is skipped: a routine never run is due nowhere.
LGB_C_MT="$TMP/lgb_c_maint"; mkdir -p "$LGB_C_MT"
{ printf 'lgbc-first\t7\talways\tplain upkeep\n'
  printf 'lgbc-second\t7\talways\trefresh the caf\351 map\n'; } > "$LGB_C_MT/maintenance.tsv"
_lgb_c_maint() {  # the routine names felix_maint_status reports due, raw
  ( . "$FROOT/harness/lib/maintenance.sh"; felix_maint_status "$LGB_C_MT" "" ) 2>/dev/null
}
# Post-processing outside the locale subshell: capture there, read here.
_lgb_c_maint_C()  { _lgb_c_in C _lgb_c_maint | LC_ALL=C awk -F'\t' '$1 == "due" { printf "%s%s", s, $2; s = " " }'; }
_lgb_c_maint_U8() { _lgb_c_in all _lgb_c_maint | LC_ALL=C awk -F'\t' '$1 == "due" { printf "%s%s", s, $2; s = " " }'; }
is "in C, two never-run routines, the second's description holding a Latin-1 byte, are both due" \
   "$(_lgb_c_maint_C)" "lgbc-first lgbc-second"
LGB_C_E15="in a UTF-8 locale, a never-run routine whose description holds a byte that is not UTF-8 is still due, beside the plain one"
if [ -n "$LCB_U8" ]; then is "$LGB_C_E15" "$(_lgb_c_maint_U8)" "lgbc-first lgbc-second"; else skip "$LGB_C_E15" "$LCB_NONE"; fi

# F3 (C3). felix maintenance --ran checks the name against
# `_felix_maint_rows | cut -f1`; cut stops on the other row's byte and exits
# 1, the check reads a routine the table declares as missing, and no run of
# any routine can be recorded while one row holds the byte.
{ printf 'lgbc-weekly\t7\talways\tplain upkeep\n'
  printf 'lgbc-latin\t7\talways\tthe caf\351 menu\n'; } > "$LGB_C_PROJ/maintenance.tsv"
_lgb_c_ran() {  # rc, whether the log gained exactly one row for lgbc-weekly, and what was said
  local out rc n
  rm -f "$LGB_C_PROJ/maintenance.log"
  out="$(_lgb_c_in "$1" _lgb_c_felix maintenance --ran lgbc-weekly 2>&1)"; rc=$?
  n="$(LC_ALL=C grep -c '^lgbc-weekly	' "$LGB_C_PROJ/maintenance.log" 2>/dev/null)"
  printf 'rc=%s logged=%s %s' "$rc" "${n:-0}" "$(printf '%s\n' "$out" | LC_ALL=C sed -n 1p)"
}
is "in C, felix maintenance --ran records a run when another row of the table holds a Latin-1 byte" \
   "$(_lgb_c_ran C)" "rc=0 logged=1 recorded a run of lgbc-weekly"
LGB_C_F3="in a UTF-8 locale, felix maintenance --ran still records a run when another row holds a byte that is not UTF-8"
if [ -n "$LCB_U8" ]; then is "$LGB_C_F3" "$(_lgb_c_ran all)" "rc=0 logged=1 recorded a run of lgbc-weekly"; else skip "$LGB_C_F3" "$LCB_NONE"; fi

# E16 (O17). felix_incident_paths splits the error text with tr, which in a
# UTF-8 locale stops at the byte, so every path named after a Latin-1 line is
# never implicated and a red path reads as nothing.
LGB_C_IR="$TMP/lgb_c_incident"; mkdir -p "$LGB_C_IR/src/auth" "$LGB_C_IR/docs"
printf 'x\n' > "$LGB_C_IR/src/auth/login.py"; printf 'x\n' > "$LGB_C_IR/docs/readme.md"
LGB_C_IT="$(printf 'FAIL  File "/home/runner/work/x/docs/readme.md", line 3\nfixture said: caf\351\n  File "/home/runner/work/x/src/auth/login.py", line 12, in check\nAssertionError\n')"
_lgb_c_inc() { ( . "$FROOT/harness/lib/incident.sh"; felix_incident_paths "$LGB_C_IR" "$LGB_C_IT" ) 2>/dev/null; }
_lgb_c_inc_in() { _lgb_c_in "$1" _lgb_c_inc | LC_ALL=C tr '\n' ' '; }
is "in C, incident paths over error text with a Latin-1 line implicate the file named after it" \
   "$(_lgb_c_inc_in C)" "docs/readme.md src/auth/login.py "
LGB_C_E16="in a UTF-8 locale, a path named after a line holding a byte that is not UTF-8 is still implicated"
if [ -n "$LCB_U8" ]; then is "$LGB_C_E16" "$(_lgb_c_inc_in all)" "docs/readme.md src/auth/login.py "; else skip "$LGB_C_E16" "$LCB_NONE"; fi

# E17 (O19). The counts, not the receipt: felix_commission_counts counts each
# state's rows with `grep -c .`, and BSD grep in a UTF-8 locale misses a line
# whose first byte is not UTF-8, so a row whose need starts with the byte and
# whose instrument is unknown counts 0 unknown and the receipt would read
# commissioned. The receipt's own run-completeness check reads the table
# through awk, which was not shown to disagree here, so the counts are what
# is asserted.
LGB_C_CR="$(printf 'lgbc_d\tdone\tOBSERVED\t-\t9\t\t-\n\351tre\tunknown\tUNKNOWN\t-\t9\tlgbc\t-')"
_lgb_c_counts() { ( . "$FROOT/harness/lib/commission.sh"; felix_commission_counts "$LGB_C_CR" ""; printf '|%s' "$?" ) 2>/dev/null; }
is "in C, a commissioning row whose need starts with a Latin-1 byte and whose instrument is unknown is counted unknown" \
   "$(_lgb_c_in C _lgb_c_counts)" "1 0 1 0 0 0|0"
_lgb_c_u8 "in a UTF-8 locale, a row whose need starts with a byte that is not UTF-8 still counts as unknown, so the receipt cannot read commissioned" \
   all _lgb_c_counts "1 0 1 0 0 0|0"

# E18 (O22). felix_discover_adopt reads stack.tsv's names with cut -f2, which
# stops at a row holding the byte, so a person's DECLARED high-risk row after
# it is not seen, and a low cache verdict for the same name reads `declare`:
# appended as OBSERVED low and installed over the person's judgement.
LGB_C_AH="$TMP/lgb_c_adopt"; LGB_C_AP="$LGB_C_AH/projects/lgbcad"
mkdir -p "$LGB_C_AH/state/discover" "$LGB_C_AP"
{ printf 'plugin\tnotion@mkt\thttps://example.com/notion (f\374r die Doku)\tlow\tdocs\tDECLARED\n'
  printf 'plugin\tshellx\t-\thigh\tsecurity\tDECLARED\n'; } > "$LGB_C_AP/stack.tsv"
{ ( . "$FROOT/harness/lib/discover.sh"; _felix_discover_stamp_line ) 2>/dev/null
  printf 'shellx\tsecurity\tlow\t-\n'; } > "$LGB_C_AH/state/discover/lgbcad.tsv"
_lgb_c_adopt() { ( . "$FROOT/harness/lib/discover.sh"; felix_discover_adopt "$LGB_C_AP" "$LGB_C_AH" ) 2>/dev/null; }
_lgb_c_adopt_in() { _lgb_c_in "$1" _lgb_c_adopt | LC_ALL=C cut -f1,2 | LC_ALL=C tr '\t\n' ': '; }
is "in C, discover reads a person's shellx row after a row holding a Latin-1 byte as already declared" \
   "$(_lgb_c_adopt_in C)" "already:shellx "
LGB_C_E18="in a UTF-8 locale, discover still reads that shellx row as already declared and declares nothing to append"
if [ -n "$LCB_U8" ]; then is "$LGB_C_E18" "$(_lgb_c_adopt_in all)" "already:shellx "; else skip "$LGB_C_E18" "$LCB_NONE"; fi

# E19 (O23). _felix_discover_mcp_facts greps a server file for `${VAR}` and
# for `@latest`; BSD grep in a UTF-8 locale misses a match after the byte on
# the same line, and a .mcp.json is often one line. Losing both facts turns a
# high plugin medium: held becomes a person's decision, and toolbox wires it.
LGB_C_PD="$TMP/lgb_c_plugin"; mkdir -p "$LGB_C_PD/.claude-plugin"
printf '{"name":"lgbcmcp","version":"1.0.0"}\n' > "$LGB_C_PD/.claude-plugin/plugin.json"
printf '{"mcpServers":{"lgbc":{"description":"le caf\351 du coin","command":"npx","args":["lgbc-server@latest"],"env":{"TOKEN":"${TOKEN}"}}}}\n' \
  > "$LGB_C_PD/.mcp.json"
_lgb_c_mcp() {  # interpolates-or-dash floating-or-dash tier, from bash alone inside the locale
  ( . "$FROOT/harness/lib/discover.sh"
    f="$(felix_discover_inspect "$LGB_C_PD")"; r="$(felix_discover_risk "$f")"
    case "$f" in *"interpolates	TOKEN"*) i=interpolates ;; *) i=- ;; esac
    case "$f" in *"floating	"*) l=floating ;; *) l=- ;; esac
    printf '%s %s %s' "$i" "$l" "$r" ) 2>/dev/null
}
is "in C, a one-line .mcp.json with a Latin-1 description before an @latest command and a \${TOKEN} env names both facts and tiers high" \
   "$(_lgb_c_in C _lgb_c_mcp)" "interpolates floating high"
_lgb_c_u8 "in a UTF-8 locale, that .mcp.json still names interpolates and floating, and its tier is high" \
   all _lgb_c_mcp "interpolates floating high"

# E20 (O26). felix_handoff_check reads the index rows' ids with cut -f1, which
# stops at a row whose title holds the byte, so a duplicate row after it is
# never named and the check exits 0 over a broken index.
LGB_C_HO="$TMP/lgb_c_handoff"; mkdir -p "$LGB_C_HO/docs/handoff"
{ printf '# Handoff\n\nThe current section is named here (after 0c comes 0d).\n\n'
  printf '### 0c. Current work\n\nbody\n\n---\n\n'
  printf '| id | title |\n|---|---|\n'
  printf '| [0b](docs/handoff/0b.md) | caf\351 notes |\n'
  printf '| [0a](docs/handoff/0a.md) | first |\n'
  printf '| [0a](docs/handoff/0a.md) | first |\n'; } > "$LGB_C_HO/HANDOFF.md"
printf '### 0a. first\n\nx\n' > "$LGB_C_HO/docs/handoff/0a.md"
printf '### 0b. caf\351 notes\n\nx\n' > "$LGB_C_HO/docs/handoff/0b.md"
_lgb_c_ho() { ( export TMPDIR="$TMP"; . "$FROOT/harness/lib/handoff.sh"; felix_handoff_check "$LGB_C_HO" ""; printf '\nrc=%s\n' "$?" ) 2>/dev/null; }
_lgb_c_ho_in() {  # the index findings and the status
  _lgb_c_in "$1" _lgb_c_ho | LC_ALL=C awk -F'\t' '$1 == "index" { printf "%s; ", $2 } /^rc=/ { printf "%s", $0 }'
}
is "in C, the handoff check names a duplicate index row that follows a row whose title holds a Latin-1 byte" \
   "$(_lgb_c_ho_in C)" "0a has more than one row; rc=1"
LGB_C_E20="in a UTF-8 locale, felix_handoff_check still names the duplicate row after a title holding a byte that is not UTF-8, and exits 1"
if [ -n "$LCB_U8" ]; then is "$LGB_C_E20" "$(_lgb_c_ho_in all)" "0a has more than one row; rc=1"; else skip "$LGB_C_E20" "$LCB_NONE"; fi

# E21 (O27/O28's scope half). felix scope decides "were any paths given" with
# `tr -d '[:space:]'`, which stops at the byte; given a first path starting
# with it, the paths read as none, the empty diff is scoped instead, and a red
# workflow path given beside it says "Nothing to scope" and exits 0.
printf 'red\tpath\t^\\.github/workflows/\tworkflows run code on the runner\n' > "$LGB_C_PROJ/risk.tsv"
_lgb_c_scope() {
  local out rc
  out="$(_lgb_c_in "$1" _lgb_c_felix scope "$(printf '\351t\351.txt')" .github/workflows/ci.yml 2>&1)"; rc=$?
  case "$out" in *'Nothing to scope'*) printf 'nothing-to-scope ' ;; esac
  printf 'rc=%s' "$rc"
}
is "in C, felix scope given a first path starting with a Latin-1 byte and a workflow path is out of scope, exit 3" \
   "$(_lgb_c_scope C)" "rc=3"
LGB_C_E21="in a UTF-8 locale, felix scope given a first path starting with a byte that is not UTF-8 and a workflow path does not say Nothing to scope, and exits 3"
if [ -n "$LCB_U8" ]; then is "$LGB_C_E21" "$(_lgb_c_scope all)" "rc=3"; else skip "$LGB_C_E21" "$LCB_NONE"; fi

# F2 (C2). felix route reads the best route's score, name and play with cut;
# with the byte in that route's play, cut prints nothing in a UTF-8 locale and
# the route is rendered with no name. The name alone is not the whole of it:
# felix_route_render cut the play's first step from the same line, and under
# UTF-8 said "wants , which this project has not declared" (the review of
# 15e707de, contract Amendment 2, R-M4). So the whole output is compared with
# C's, and C's is shown to name the step.
{ printf 'backend\tmigration schema endpoint\tcore\tsuperpowers:brainstorming read-the-caf\351-schema\n'
  printf 'notes\tmenu\tcore\twrite it down\n'; } > "$LGB_C_PROJ/routes.tsv"
_lgb_c_route_all() { _lgb_c_in "$1" _lgb_c_felix route --for 'add a migration for the endpoint schema' 2>/dev/null; }
_lgb_c_route() { _lgb_c_route_all "$1" | LC_ALL=C sed -n 1p; }
is "in C, felix route for a prompt whose best route's play holds a Latin-1 byte prints that route" \
   "$(_lgb_c_route C)" "Felix routed this to: backend"
is "in C, felix route says that route wants superpowers:brainstorming, the first step of its play" \
   "$(_lgb_c_route_all C | LC_ALL=C grep -c '^This kind of work wants superpowers:brainstorming, ')" "1"
LGB_C_F2="in a UTF-8 locale, felix route prints the best route whose play holds a byte that is not UTF-8 exactly as in C, the wants superpowers:brainstorming line included"
if [ -n "$LCB_U8" ]; then is "$LGB_C_F2" "$(_lgb_c_route_all all)" "$(_lgb_c_route_all C)"; else skip "$LGB_C_F2" "$LCB_NONE"; fi

# F4 (C4). _felix_obligation_scan runs one awk over the table with a regex on
# every record, and macOS awk aborts the whole program on a record holding
# the byte: every row is lost and the scan says it could not be read.
LGB_C_OB="$TMP/lgb_c_oblig"; mkdir -p "$LGB_C_OB"
{ printf 'lgbc_one\tRELEASE_BLOCKING\tdeterministic\t-\ttrue\t-\tplain reason\n'
  printf 'lgbc_two\tRELEASE_BLOCKING\tdeterministic\t-\ttrue\t-\tthe caf\351 owes this\n'
  printf 'lgbc_three\tRELEASE_BLOCKING\tdeterministic\t-\ttrue\t-\tanother plain reason\n'; } > "$LGB_C_OB/obligations.tsv"
_lgb_c_ob() {  # names admitted | what the malformed scan said
  ( . "$FROOT/harness/lib/obligations.sh"
    felix_obligation_rows "$LGB_C_OB"; printf '|\n'; felix_obligation_malformed "$LGB_C_OB" ) 2>/dev/null
}
_lgb_c_ob_in() {
  _lgb_c_in "$1" _lgb_c_ob | LC_ALL=C awk -F'\t' '/^\|$/ { m = 1; printf "|"; next }
      !m && $1 != "" { printf "%s ", $1 }  m && /could not be read/ { printf "could not be read" }'
}
is "in C, an obligations table with a Latin-1 byte in one row's reason admits every row and says nothing could not be read" \
   "$(_lgb_c_ob_in C)" "lgbc_one lgbc_two lgbc_three |"
LGB_C_F4="in a UTF-8 locale, an obligations row whose reason holds a byte that is not UTF-8 leaves the scan admitting every row, with no could not be read"
if [ -n "$LCB_U8" ]; then is "$LGB_C_F4" "$(_lgb_c_ob_in all)" "lgbc_one lgbc_two lgbc_three |"; else skip "$LGB_C_F4" "$LCB_NONE"; fi

# F5 (C5). felix_probes_run cuts each row's fields with cut, which prints
# nothing of a row holding the byte in a UTF-8 locale, so a probe whose
# command prints a Latin-1 word is never run and reads unknown.
LGB_C_PR="$TMP/lgb_c_probes"; LGB_C_PRR="$TMP/lgb_c_probes_root"; mkdir -p "$LGB_C_PR" "$LGB_C_PRR"
printf 'lgbclatin\t-\t-\techo caf\351\t-\n' > "$LGB_C_PR/probes.tsv"
_lgb_c_probe() { ( . "$FROOT/harness/lib/probes.sh"; felix_probes_run "$LGB_C_PR" "$LGB_C_PRR" ) 2>/dev/null; }
_lgb_c_probe_in() { _lgb_c_in "$1" _lgb_c_probe | LC_ALL=C awk -F'\t' '{ printf "%s %s %s", $1, $3, $4 }'; }
is "in C, a probe whose command prints a Latin-1 word is run and found" \
   "$(_lgb_c_probe_in C)" "lgbclatin found 1"
LGB_C_F5="in a UTF-8 locale, felix_probes_run still runs a probe whose command prints a byte that is not UTF-8, and finds it"
if [ -n "$LCB_U8" ]; then is "$LGB_C_F5" "$(_lgb_c_probe_in all)" "lgbclatin found 1"; else skip "$LGB_C_F5" "$LCB_NONE"; fi

# F6 (C22). felix_ledger_summary reduces each name with awk's sub(), and
# macOS awk aborts the whole program on a name holding the byte, so the
# summary is empty: no retire list, no unrouted list, no unmount proposal.
LGB_C_LP="$TMP/lgb_c_ledger/projects/lgbcled"; LGB_C_LM="$TMP/lgb_c_ledger_mem"
mkdir -p "$LGB_C_LP" "$LGB_C_LM/lgbcled/ledger.d"
{ printf 's1\t2026-10-01\tplugin\tcaf\351@mkt\t0\t1\n'
  printf 's1\t2026-10-01\tplugin\tfoo@mkt\t2\t1\n'
  printf 's1\t2026-10-01\tplugin\tzed@mkt\t0\t1\n'; } > "$LGB_C_LM/lgbcled/ledger.d/s1.tsv"
_lgb_c_ledger() { ( export FELIX_MEMORY="$LGB_C_LM"; . "$FROOT/harness/lib/ledger.sh"; felix_ledger_summary "$LGB_C_LP" ) 2>/dev/null; }
_lgb_c_ledger_in() { _lgb_c_in "$1" _lgb_c_ledger | LC_ALL=C awk -F'\t' '$1 == "foo" || $1 == "zed" { printf "%s:%s:%s ", $1, $2, $3 }'; }
is "in C, the ledger summary over rows naming a plugin with a Latin-1 byte still summarises the other names" \
   "$(_lgb_c_ledger_in C)" "foo:1:2 zed:1:0 "
LGB_C_F6="in a UTF-8 locale, felix_ledger_summary over rows naming a plugin whose name holds a byte that is not UTF-8 still summarises the other names"
if [ -n "$LCB_U8" ]; then is "$LGB_C_F6" "$(_lgb_c_ledger_in all)" "foo:1:2 zed:1:0 "; else skip "$LGB_C_F6" "$LCB_NONE"; fi

# fragment d: Rule 1 (bash's own collation) at G1-G5, and the three lints L1-L3
#
# bash 3.2 collates with strcoll in the locale for what it does itself: the
# order a glob expands in, and a bracket range in its own patterns (case,
# [[ == ]], ${x#pat}). Measured 2026-10-08 on macOS 26, bash 3.2.57: under
# en_US.UTF-8 a glob puts punctuation first and folds case, and [a-z] or
# [A-Za-z] admits an uppercase or accented letter. So a first-match glob loop
# and a range check over a person's or a third party's input answer by who
# started the process. Each case below runs the real library function in C and
# in the UTF-8 locale, in a subshell around the one call, and asks for the same
# answer. These are bash's own, not BSD's: glibc bash collates the same way,
# so they can fail on Linux too wherever en_US.UTF-8 is installed.
