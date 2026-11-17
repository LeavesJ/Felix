# >>> gate-friction-a-driver
printf '\ngate friction A: the record run, its receipt and --reuse, in a copy of the driver\n'
# Blind, written from contract A alone (docs/2026-10-12-gate-friction-contract-a.md,
# C2, C3, C4 and C6) on 2026-10-12, before the code it describes existed. The
# driver under test is this tree's tests/run, copied into a fixture checkout
# with every part line replaced by two tiny parts of this block's own, beside
# this tree's lib and every other file in tests/ but red, which is a stub that
# writes down what it was handed and waits for the mark. The fixture's judge,
# _rt_judge, is a stub too: it skips its four names in record mode, reports
# them otherwise, and fails one of them while a flag file exists. Six runs of
# that driver, in this order, each killed if it has not ended in 60 s:
#   R1  --record-assertions, red there, the judge passing
#   R2  --reuse, on a receipt this block writes, counting no skip
#   R3  --reuse --record-assertions
#   R4  --record-assertions, red not executable, the judge failing
#   R5  --reuse, with no receipt left
#   R6  a red run (FELIX_TEST_NO_MANIFEST=1), the judge failing
# What six runs cannot reach is not asserted here: a failed manifest write
# marked failed, a normal run with no manifest, a tree or an environment that
# moves during a run, a suite with no _rt_judge, and a receipt path that is a
# link when a run ends. An assertion whose name ends in (control) passes on the
# code before the change on purpose: it pins something the contract keeps.
GFC="$TMP/gfa-drive"; mkdir -p "$GFC/logs"
GFC_R="$REAL_HARNESS/tests/receipt.sh"
_gfc_git() { git -c user.name=gfa -c user.email=gfa@example.invalid -c commit.gpgsign=false -c core.hooksPath=/dev/null "$@"; }
_gfc_tree_of() {   # pid -> it and every process below it
  ps -A -o pid= -o ppid= 2>/dev/null | awk -v root="$1" '
    { kids[$2] = kids[$2] " " $1 }
    END { q = root; out = ""
          while (q != "") { n = split(q, a, " "); q = ""
                            for (i = 1; i <= n; i++) if (a[i] != "") { out = out " " a[i]; q = q kids[a[i]] } }
          print out }'
}
_gfc_sr() { bash -c '. "$1" >/dev/null 2>&1 || exit 97; shift; "$@"' _ "$GFC_R" "$@" 2>/dev/null; }
_gfc_want() { printf '%s' "${1:-<nothing was computed to compare with>}"; }
_gfc_hm() { date -r "$1" +%H:%M 2>/dev/null || date -d "@$1" +%H:%M; }
# Lines of output compared whole are shown with a bar before each, so that a
# failure's detail never holds a line a reader of this log takes for an
# assertion line of its own.
_gfc_q() { sed 's/^/| /'; }

# ---- the fixture checkout
GFC_F="$GFC/f"; GFC_T="$GFC_F/engine/harness/tests"
mkdir -p "$GFC_T/parts" "$GFC_F/engine/.claude-plugin"
_copy_content "$REAL_HARNESS/lib" "$GFC_F/engine/harness/lib"
for _gfc_x in "$REAL_HARNESS"/tests/*; do
  [ -f "$_gfc_x" ] || continue
  case "${_gfc_x##*/}" in run|red|assertions.tsv|red.tsv) ;; *) cp "$_gfc_x" "$GFC_T/" ;; esac
done
printf '{\n  "name": "felix",\n  "version": "0.0.1"\n}\n' > "$GFC_F/engine/.claude-plugin/plugin.json"
# The suite's preamble parts stay in the copy (part 0003's _suite_copy_driver): since 3+3b they hold $TMP and the EXIT trap.
_suite_copy_driver "$REAL_HARNESS/tests/run" "$GFC_T" 0001-gfc-parts.sh 0002-gfc-judge.sh
chmod +x "$GFC_T/run"
cat > "$GFC_T/parts/0001-gfc-parts.sh" <<'EOF'
printf 'gfc fixture parts\n'
printf 'ran\n' >> "${GFC_PARTLOG:?}"
printf '%s\n%s\n' "$TMP" "$(cd "$TMP" && pwd -P)" > "${GFC_TMPLOG:?}"
if [ "${GFC_WANTRED:-}" = 1 ]; then
  _gfcn=0
  while [ ! -e "$GFC_REDSTART" ] && [ "$_gfcn" -lt 50 ]; do sleep 0.1; _gfcn=$((_gfcn + 1)); done
  if [ -e "$GFC_REDSTART" ]; then echo started > "$GFC_PARTSAW"; else echo 'not started' > "$GFC_PARTSAW"; fi
fi
ok "gfc fixture part passes"
ok "gfc fixture part passes again"
skip "gfc fixture part skips" "a fixture reason"
EOF
cat > "$GFC_T/parts/0002-gfc-judge.sh" <<'EOF'
_rtn1="gfc record check one"; _rtn2="gfc record check two"
_rtn3="gfc record check three"; _rtn4="gfc record check four"
_rt_judge() {
  printf '%s|%s\n' "$1" "${FELIX_TEST_RECORD-unset}" >> "${GFC_JUDGELOG:?}"
  if [ "${FELIX_TEST_RECORD:-}" = 1 ]; then
    for _gfcj in "$_rtn1" "$_rtn2" "$_rtn3" "$_rtn4"; do skip "$_gfcj" "the record is being rewritten"; done
    return 0
  fi
  ok "$_rtn1"
  if [ -e "${GFC_JUDGEFAIL:?}" ]; then bad "$_rtn2" "the fixture's record fails its judge"; else ok "$_rtn2"; fi
  ok "$_rtn3"; ok "$_rtn4"
}
_rt_judge "${REAL_HARNESS}/../.."
EOF
cat > "$GFC_T/red" <<'EOF'
#!/usr/bin/env bash
: > "${GFC_REDSTART:?}"
L="${GFC_REDLOG:?}"
{ printf 'argc=%s\n' "$#"; printf 'arg1=%s\n' "${1-}"; printf 'mark=%s\n' "${2-}"; printf 'pid=%s\n' "${3-}"; } > "$L"
[ "$#" = 3 ] && [ "$1" = --after ] || { echo 'not --after' >> "$L"; exit 0; }
m="$2"; p="$3"
[ -e "$m" ] && echo 'mark present at start' >> "$L"
[ -f /dev/fd/1 ] && echo 'stdout is a file' >> "$L"
[ /dev/fd/1 -ef /dev/fd/2 ] && echo 'stderr is stdout' >> "$L"
o="$(readlink "/proc/$$/fd/1" 2>/dev/null)"
[ -n "$o" ] || o="$(lsof -a -p "$$" -d 1 -Fn 2>/dev/null | sed -n 's/^n//p' | sed -n 1p)"
echo "outpath=$o" >> "$L"
n=0
while [ ! -e "$m" ] && kill -0 "$p" 2>/dev/null && [ "$n" -lt 300 ]; do sleep 0.1; n=$((n + 1)); done
if [ -e "$m" ]; then
  printf 'mark says=%s\n' "$(sed -n 1p "$m")" >> "$L"
  cp "$GFC_MANF" "$GFC_MANSNAP" 2>/dev/null
else
  echo 'no mark' >> "$L"
fi
sleep 1
printf 'gfc red says one\ngfc red says two\n'
printf 'gfc red says on stderr\n' >&2
echo 'red done' >> "$L"
exit 0
EOF
chmod +x "$GFC_T/red"
GFC_NAMES="$(printf '%s\n' "gfc fixture part passes" "gfc fixture part passes again" "gfc fixture part skips" \
  "gfc record check one" "gfc record check two" "gfc record check three" "gfc record check four")"
GFC_ROWS="$(printf '%s\n' "$GFC_NAMES" | _ran_rows)"
{ printf '%s\n' "$GFC_NAMES"; printf 'gfc a name only the committed manifest lists\n'; } | _ran_rows > "$GFC_T/assertions.tsv"
( cd "${GFC_F:?}" && _gfc_git init -q -b main && _gfc_git add -A && _gfc_git commit -qm fixture ) >/dev/null 2>&1
GFC_F="$(cd "${GFC_F:?}" && pwd)"; GFC_T="$GFC_F/engine/harness/tests"
GFC_RP="$(cd "${GFC_F:?}" && pwd -P)/.git/felix-suite-receipt"
GFC_JUDGEFAIL="$GFC/judge.fail"
GFC_E=()
# <name> [driver args...]: one run of the fixture's driver, from its root. Its
# stdout is $GFC/<name>.out and stderr $GFC/<name>.err; GFC_RC its status (124
# when killed at 60 s), GFC_PID its process id, GFC_T0 and GFC_T1 the seconds
# around it, GFC_RAN how many times a part of it ran.
_gfc_drive() {
  local n="$1" pid k c=0 b
  shift
  rm -f "$GFC/redstart" "$GFC/redlog" "$GFC/partsaw" "$GFC/mansnap"
  b="$(awk 'END { print NR }' "$GFC/partlog" 2>/dev/null)"; b="${b:-0}"
  GFC_T0="$(date +%s)"
  ( cd "${GFC_F:?}" && exec env -u FELIX_TEST_NO_MANIFEST GFC_PARTLOG="$GFC/partlog" GFC_TMPLOG="$GFC/tmplog" \
      GFC_REDSTART="$GFC/redstart" GFC_REDLOG="$GFC/redlog" GFC_PARTSAW="$GFC/partsaw" GFC_JUDGELOG="$GFC/$n.judge" \
      GFC_JUDGEFAIL="$GFC_JUDGEFAIL" GFC_MANF="$GFC_T/assertions.tsv" GFC_MANSNAP="$GFC/mansnap" \
      "${GFC_E[@]+"${GFC_E[@]}"}" bash "$GFC_T/run" "$@" ) > "$GFC/$n.out" 2> "$GFC/$n.err" &
  pid=$!
  while kill -0 "$pid" 2>/dev/null && [ "$c" -lt 600 ]; do sleep 0.1; c=$((c + 1)); done
  if kill -0 "$pid" 2>/dev/null; then
    for k in $(_gfc_tree_of "$pid"); do kill -9 "$k" 2>/dev/null; done
    wait "$pid" 2>/dev/null; GFC_RC=124
  else
    wait "$pid"; GFC_RC=$?
  fi
  GFC_T1="$(date +%s)"; GFC_PID="$pid"; GFC_E=()
  GFC_RAN=$(( $(awk 'END { print NR }' "$GFC/partlog" 2>/dev/null) - b ))
}
_gfc_has() { grep -cxF -e "$2" "$GFC/$1.out" 2>/dev/null; }   # <run> <line>: how many lines are exactly it
_gfc_log() { grep -cxF -e "$1" "$GFC/redlog" 2>/dev/null; }
_gfc_field() { awk -F'\t' -v f="$1" '{ print $f }' "$GFC_RP" 2>/dev/null; }

# ---- R1: a record run, red there, the judge passing
rm -f "$GFC_JUDGEFAIL" "$GFC_RP"
_gfc_full0="$(_gfc_sr _sr_tree "$GFC_F")"
GFC_E=(GFC_WANTRED=1)
_gfc_drive r1 --record-assertions
_gfc_tmp="$(sed -n 1p "$GFC/tmplog" 2>/dev/null)"; _gfc_tmpp="$(sed -n 2p "$GFC/tmplog" 2>/dev/null)"
_gfc_mark="$(sed -n 's/^mark=//p' "$GFC/redlog" 2>/dev/null)"
is  "a record run starts tests/red before its first part runs" "$(cat "$GFC/partsaw" 2>/dev/null)" "started"
is  "and hands red three arguments, --after first" \
    "$(sed -n 's/^argc=//p' "$GFC/redlog")|$(sed -n 's/^arg1=//p' "$GFC/redlog")" "3|--after"
is  "and the process id it hands red is the record run's own" "$(sed -n 's/^pid=//p' "$GFC/redlog")" "$GFC_PID"
is  "and the mark it hands red does not exist yet when red starts" \
    "$(sed -n 's/^argc=//p' "$GFC/redlog") $(_gfc_log 'mark present at start')" "3 0"
case "$_gfc_mark" in
  "$_gfc_tmp"/*|"$_gfc_tmpp"/*) ok  "and the mark is a path under the record run's temporary directory" ;;
  *) bad "and the mark is a path under the record run's temporary directory" "mark [$_gfc_mark], temporary directory [$_gfc_tmp]" ;;
esac
is  "red's stdout is a file and its stderr the same file" "$(_gfc_log 'stdout is a file') $(_gfc_log 'stderr is stdout')" "1 1"
_gfc_out="$(sed -n 's/^outpath=//p' "$GFC/redlog")"
if [ -z "$_gfc_out" ] && [ "$(_gfc_log 'stdout is a file')" = 1 ]; then
  skip "and that file lies under the record run's temporary directory" "neither /proc nor lsof named it here"
else
  case "$_gfc_out" in
    "$_gfc_tmp"/*|"$_gfc_tmpp"/*) ok  "and that file lies under the record run's temporary directory" ;;
    *) bad "and that file lies under the record run's temporary directory" "red's stdout [$_gfc_out], temporary directory [$_gfc_tmpp]" ;;
  esac
fi
is  "the mark reads written once the manifest is written" "$(sed -n 's/^mark says=//p' "$GFC/redlog")" "written"
[ -s "$GFC/mansnap" ] && cmp -s "$GFC/mansnap" "$GFC_T/assertions.tsv" \
  && ok  "and the manifest is whole by the time the mark appears" \
  || bad "and the manifest is whole by the time the mark appears" "what red read at the mark differs from what the run left"
is  "the record run still says how many assertions it recorded and where (control)" \
    "$(_gfc_has r1 "  recorded 7 assertions to $GFC_T/assertions.tsv")" "1"
is  "and the manifest it wrote lists each name reached before it, once (control)" "$(cat "$GFC_T/assertions.tsv")" "$GFC_ROWS"
is  "red's output follows the recorded line, every line of it, stderr too, indented by two spaces" \
    "$(grep -xF -e "  recorded 7 assertions to $GFC_T/assertions.tsv" -e '  gfc red says one' -e '  gfc red says two' \
        -e '  gfc red says on stderr' "$GFC/r1.out" | _gfc_q)" \
    "$(printf '  recorded 7 assertions to %s\n  gfc red says one\n  gfc red says two\n  gfc red says on stderr\n' "$GFC_T/assertions.tsv" | _gfc_q)"
is  "the record run does not end before red has" "$(_gfc_log 'red done')" "1"
is  "after red, a record run prints an empty line and then the record this run wrote" \
    "$(awk '$0 == "the record this run wrote" { print (p == "" && NR > 1) ? "after an empty line" : "after [" p "]"; n++ } { p = $0 } END { if (!n) print "never" }' "$GFC/r1.out")" \
    "after an empty line"
is  "and judges its own checkout a second time, with the parts' argument and FELIX_TEST_RECORD not 1" \
    "$(awk -F'|' 'NR == 1 { a = $1; r = $2 } NR == 2 { s = ($1 == a && r == "1" && $2 != "1") ? "so" : "not so: " $0 } END { print NR " " s }' "$GFC/r1.judge" 2>/dev/null)" \
    "2 so"
is  "and the four record names are reported after that line as a normal run reports them" \
    "$(grep -A4 -xF 'the record this run wrote' "$GFC/r1.out" | sed -n '2,5p' | _gfc_q)" \
    "$(printf '  ok    gfc record check one\n  ok    gfc record check two\n  ok    gfc record check three\n  ok    gfc record check four\n' | _gfc_q)"
is  "so a record run reaches each record name twice, once skipped and once judged" \
    "$(grep -c '^  [a-zA-Z]*  *gfc record check one' "$GFC/r1.out")" "2"
is  "the manifest comparison runs in a record run, against the manifest just written, and finds every name reached" \
    "$(_gfc_has r1 '  ok    every assertion in the manifest was reached')" "1"
is  "the summary counts the re-judged names: six passed, none failed, five skipped" \
    "$(sed -n '$p' "$GFC/r1.out")" "6 passed, 0 failed, 5 skipped"
is  "and red's output, the record header, the comparison and the summary come in that order" \
    "$(grep -xF -e '  gfc red says two' -e 'the record this run wrote' -e '  ok    every assertion in the manifest was reached' \
        -e '6 passed, 0 failed, 5 skipped' "$GFC/r1.out" | _gfc_q)" \
    "$(printf '  gfc red says two\nthe record this run wrote\n  ok    every assertion in the manifest was reached\n6 passed, 0 failed, 5 skipped\n' | _gfc_q)"
is  "a record run whose own record passes its judge exits 0 (control)" "$GFC_RC" "0"
is  "a passing record run leaves one receipt line of nine tab-separated fields, v1 first" \
    "$(awk -F'\t' 'END { print NR, NF, $1 }' "$GFC_RP" 2>/dev/null)" "1 9 v1"
is  "and the receipt ends in a newline" "$(tail -c 1 "$GFC_RP" 2>/dev/null | od -An -c | tr -d ' ')" '\n'
is  "the receipt names mode record and the run's counts, six passed, none failed, five skipped" \
    "$(_gfc_field 3) $(_gfc_field 4) $(_gfc_field 5) $(_gfc_field 6)" "record 6 0 5"
is  "and the tree id it records is the full id at the run's end, the rewritten manifest in it" \
    "$(_gfc_field 2)" "$(_gfc_want "$(_gfc_sr _sr_tree "$GFC_F")")"
[ -n "$(_gfc_field 2)" ] && [ "$(_gfc_field 2)" != "$_gfc_full0" ] \
  && ok  "which is not the full id the run started from" \
  || bad "which is not the full id the run started from" "start [$_gfc_full0], receipt [$(_gfc_field 2)]"
is  "and its environment is _sr_env as the run saw it" "$(_gfc_field 7)" "$(_gfc_want "$(_gfc_sr _sr_env)")"
_gfc_s="$(_gfc_field 8)"; _gfc_e="$(_gfc_field 9)"
case "$_gfc_s$_gfc_e" in
  ''|*[!0-9]*) bad "and its start and end are Unix seconds within the run, the start not after the end" "start [$_gfc_s] end [$_gfc_e]" ;;
  *) [ "$GFC_T0" -le "$_gfc_s" ] && [ "$_gfc_s" -le "$_gfc_e" ] && [ "$_gfc_e" -le "$GFC_T1" ] \
       && ok  "and its start and end are Unix seconds within the run, the start not after the end" \
       || bad "and its start and end are Unix seconds within the run, the start not after the end" \
              "run $GFC_T0 to $GFC_T1, receipt $_gfc_s to $_gfc_e" ;;
esac
is  "_sr_check would reuse what the record run left" "$(_gfc_sr _sr_check "$GFC_F")" "reuse 6 0 5 $_gfc_e record"

# ---- R2: --reuse on a reusable receipt that counts no skip
_gfc_n="$(date +%s)"; _gfc_end=$((_gfc_n - 60))
printf 'v1\t%s\tnormal\t9\t0\t0\t%s\t%s\t%s\n' "$(_gfc_sr _sr_tree "$GFC_F")" "$(_gfc_sr _sr_env)" $((_gfc_n - 100)) "$_gfc_end" > "$GFC_RP"
cp "$GFC_RP" "$GFC/r2.receipt"
_gfc_drive r2 --reuse
is  "tests/run --reuse on a reusable receipt prints the reuse line, an empty line and the counts, the skipped clause left out at zero" \
    "$(_gfc_q < "$GFC/r2.out")" \
    "$(printf 'reused the suite run that ended %s on this tree (normal), not run again\n\n9 passed, 0 failed (reused)\n' "$(_gfc_hm "$_gfc_end")" | _gfc_q)"
is  "and exits 0 without running a part" "$GFC_RC $GFC_RAN" "0 0"

# ---- R3: --reuse and --record-assertions together
cp "$GFC_T/assertions.tsv" "$GFC/r3.manifest"
_gfc_drive r3 --reuse --record-assertions
is  "--reuse with --record-assertions is refused on stderr: they do not go together" \
    "$(_gfc_q < "$GFC/r3.err")" "| tests/run: --reuse and --record-assertions do not go together"
is  "and exits 2, running no part and rewriting no manifest" \
    "$GFC_RC $GFC_RAN $(cmp -s "$GFC/r3.manifest" "$GFC_T/assertions.tsv" && echo same || echo rewritten)" "2 0 same"

# ---- R4: a record run with red not executable and a record that fails its judge
: > "$GFC_JUDGEFAIL"; chmod -x "$GFC_T/red"
_gfc_had="$([ -f "$GFC_RP" ] && echo yes || echo no)"
_gfc_drive r4 --record-assertions
chmod +x "$GFC_T/red"; rm -f "$GFC_JUDGEFAIL"
is  "with tests/red not executable a record run says so and starts nothing (control)" \
    "$(_gfc_has r4 '  no tests/red beside this suite: red.tsv not written') $([ -e "$GFC/redstart" ] && echo started || echo none)" "1 none"
is  "a record run whose own record fails its judge exits 1" "$GFC_RC" "1"
is  "and the judge's failure is a FAIL line among the names after the record header" \
    "$(grep -A4 -xF 'the record this run wrote' "$GFC/r4.out" | grep -c '^  FAIL  gfc record check two$')" "1"
is  "and the summary counts it: five passed, one failed, five skipped" "$(sed -n '$p' "$GFC/r4.out")" "5 passed, 1 failed, 5 skipped"
is  "a run that reaches its end with a failure removes the receipt an earlier run left" \
    "$_gfc_had $([ -e "$GFC_RP" ] || [ -L "$GFC_RP" ] && echo yes || echo no)" "yes no"

# ---- R5: --reuse with no receipt, then a normal run
_gfc_drive r5 --reuse
is  "--reuse with no receipt says not reused: no receipt as its first line" "$(sed -n 1p "$GFC/r5.out" | _gfc_q)" "| not reused: no receipt"
is  "and then runs as a normal run, every part and the manifest comparison included (control)" \
    "$GFC_RAN $(_gfc_has r5 '  ok    every assertion in the manifest was reached')" "1 1"
is  "a normal run that passes leaves a receipt naming mode normal and its counts, six passed and one skipped" \
    "$(_gfc_field 1) $(_gfc_field 3) $(_gfc_field 4) $(_gfc_field 5) $(_gfc_field 6)" "v1 normal 6 0 1"
is  "and the tree id it records is the checkout's full id" "$(_gfc_field 2)" "$(_gfc_want "$(_gfc_sr _sr_tree "$GFC_F")")"
is  "_sr_check would reuse what the normal run left" "$(_gfc_sr _sr_check "$GFC_F")" "reuse 6 0 1 $(_gfc_field 9) normal"

# ---- R6: a red run, failing
cp "$GFC_RP" "$GFC/r6.receipt" 2>/dev/null || rm -f "$GFC/r6.receipt"
: > "$GFC_JUDGEFAIL"
GFC_E=(FELIX_TEST_NO_MANIFEST=1)
_gfc_drive r6
rm -f "$GFC_JUDGEFAIL"
# Asked only of the receipt the passing normal run just left: a receipt from
# any earlier run would make keeping it say nothing about this one.
if [ "$(awk -F'\t' '{ print $3, $4, $5, $6 }' "$GFC/r6.receipt" 2>/dev/null)" != "normal 6 0 1" ]; then
  bad "a red run, failing, leaves the receipt it found byte for byte" "the normal run before it left no receipt of its own to keep"
else
  is  "a red run, failing, leaves the receipt it found byte for byte" \
      "$(cmp -s "$GFC/r6.receipt" "$GFC_RP" && echo kept || echo 'not kept')" "kept"
fi
is  "and a plain run with a reusable receipt beside it still runs every part (control)" "$GFC_RC $GFC_RAN" "1 1"
