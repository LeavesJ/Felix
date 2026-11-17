printf '\nfelix audit: a read-only report over Claude Code transcripts\n'
_au_build

case "$("$FELIX" 2>&1)" in
  *"felix audit"*) ok  "felix with no arguments lists felix audit in the grouped help" ;;
  *)               bad "felix with no arguments lists felix audit in the grouped help" "no felix audit line in the help" ;;
esac

_au_resume
_audiag="rc=$_aurc; stdout: $(printf '%s' "$_auo" | head -c 600); stderr: $(tail -c 400 "$AU_ERR")"
is  "felix audit --dir exits 0 over a directory of transcripts" "$_aurc" "0"
[ "$_au_report" -eq 1 ] && ok  "its first line says it is read-only" \
                        || bad "its first line says it is read-only" "$_audiag"
case "$_auo" in
  *"$AUD"*) ok  "it names the directory it read" ;;
  *)        bad "it names the directory it read" "$_audiag" ;;
esac
_au_nums "$_auo" 'session|transcript' 7 \
  && ok  "it counts the seven top-level sessions it read, not the subagent files or the stray one beside them" \
  || bad "it counts the seven top-level sessions it read, not the subagent files or the stray one beside them" "$_audiag"
case "$(_au_strip "$_auo")" in
  *2026-02-11*) bad "it gives the date range from record timestamps, 2026-03-02 to 2026-03-09, not a date quoted in a message" "$_audiag" ;;
  *2026-03-02*2026-03-09*|*2026-03-09*2026-03-02*)
                ok  "it gives the date range from record timestamps, 2026-03-02 to 2026-03-09, not a date quoted in a message" ;;
  *)            bad "it gives the date range from record timestamps, 2026-03-02 to 2026-03-09, not a date quoted in a message" "$_audiag" ;;
esac
_au_nums "$_auo" 'stop' 10 6 \
  && ok  "it counts 10 stops after edits, in 6 sessions" \
  || bad "it counts 10 stops after edits, in 6 sessions" "$_audiag"
_auc="$(_au_counts "$_auo")"
is  "passed is exactly 4: the last check after the last edit did not fail"      "$(printf '%s' "$_auc" | cut -d' ' -f1)" "4"
is  "failed is exactly 1: the last check after the last edit failed"            "$(printf '%s' "$_auc" | cut -d' ' -f2)" "1"
is  "stale is exactly 2: no check after the last edit, one earlier in the session" "$(printf '%s' "$_auc" | cut -d' ' -f3)" "2"
is  "never is exactly 3: no check at any point in the session before the stop"  "$(printf '%s' "$_auc" | cut -d' ' -f4)" "3"
is  "the shares are whole percentages of the stops after edits"                 "$(_au_pcts "$_auo")" "40 10 20 30"
_au_nums "$_auo" 'hold|held' 4 3 \
  && ok  "it counts 4 Felix holds in 3 sessions, not a quoted, sidechain, subagent or foreign stop hook" \
  || bad "it counts 4 Felix holds in 3 sessions, not a quoted, sidechain, subagent or foreign stop hook" "$_audiag"
case "$_auo" in
  *--verify*) ok  "it names what counts as a check and that --verify changes it" ;;
  *)          bad "it names what counts as a check and that --verify changes it" "$_audiag" ;;
esac
grep -qiE 'sub-?agent' <<<"$_auo" \
  && ok  "it says edits and checks inside subagents are not seen" \
  || bad "it says edits and checks inside subagents are not seen" "$_audiag"
case "$(_au_last "$_auo")" in
  *"felix new"*"--no-commission"*) ok  "its last line points at felix new <name> --no-commission" ;;
  *) bad "its last line points at felix new <name> --no-commission" "last line: $(_au_last "$_auo")" ;;
esac

# The awkward cases one session at a time, so a failure names its cause.
is  "a sidechain edit does not turn a pass stale, and a failure reported before its tool_use_id, behind an escaped quote, still fails" \
    "$(_au_counts "$(_au --dir "$AU/solo/a")")" "1 1 1 0"
is  "a check is read from the command, not the description, and a parallel call's error does not fail the check beside it" \
    "$(_au_counts "$(_au --dir "$AU/solo/b")")" "1 0 0 1"
is  "a stop is a distinct message id: a stop logged again is not a second one, and a failing non-check fails nothing" \
    "$(_au_counts "$(_au --dir "$AU/solo/c")")" "2 0 0 0"
is  "a session is read without its subagent files, which would add a check, a stop and a hold" \
    "$(_au_counts "$(_au --dir "$AU/solo/d")")" "0 0 0 1"

is  "--since keeps the cut day, drops what came before it, and splits a session across it" \
    "$(_au_counts "$(_au --since 2026-03-05 --dir "$AUD")")" "2 0 1 2"
# --verify was specified to replace the default runners; the repair after the
# third review made it add to them, so a project's own runner can be named
# without every other project's checks going unseen. F passes under it, and
# every other stop keeps the class the roster gave it.
is  "--verify adds to what counts as a check" \
    "$(_au_counts "$(_au --verify 'prove\.sh' --dir "$AUD")")" "5 1 2 2"
is  "with no --dir it reads CLAUDE_CONFIG_DIR/projects" \
    "$(_au_counts "$(_au)")" "4 1 2 3"
is  "and with CLAUDE_CONFIG_DIR unset, HOME/.claude/projects" \
    "$(_au_counts "$(_au --home "$AU/home2" --cfg -)")" "4 1 2 3"

_auo2="$(_au --dir "$AU/empty")"; _aurc2=$?
[ "$_aurc2" -eq 0 ] && _au_none "$_auo2" \
  && ok  "an empty directory is reported as no transcripts, exit 0" \
  || bad "an empty directory is reported as no transcripts, exit 0" "rc=$_aurc2; $_auo2"
_auo2="$(_au --home "$AU/home" --cfg -)"; _aurc2=$?
[ "$_aurc2" -eq 0 ] && _au_none "$_auo2" \
  && ok  "so is a machine where Claude Code never ran, exit 0" \
  || bad "so is a machine where Claude Code never ran, exit 0" "rc=$_aurc2; $_auo2"

# Bad arguments, each beside the run that differs only by them.
_au --dir "$AUD" --bogus >/dev/null; _aurc2=$?
[ "$_aurc" -eq 0 ] && [ "$_aurc2" -ne 0 ] \
  && ok  "an unknown flag exits non-zero where the same run without it exits 0" \
  || bad "an unknown flag exits non-zero where the same run without it exits 0" "without: $_aurc, with: $_aurc2"
_au --dir "$AUD" --since notadate >/dev/null; _aurc2=$?
[ "$_aurc" -eq 0 ] && [ "$_aurc2" -ne 0 ] \
  && ok  "a --since that is not YYYY-MM-DD exits non-zero" \
  || bad "a --since that is not YYYY-MM-DD exits non-zero" "without: $_aurc, with: $_aurc2"
_au --dir >/dev/null; _aurc2=$?
[ "$_aurc" -eq 0 ] && [ "$_aurc2" -ne 0 ] \
  && ok  "--dir with no value exits non-zero" \
  || bad "--dir with no value exits non-zero" "without: $_aurc, with: $_aurc2"

# Timed as CPU, not wall clock, and written outside the scratch root, which is
# checked below for anything a run left there. It measured 1 s at a load
# average near 340. With each tool_use id looked for among the session's
# earlier ones, one at a time, rather than by key, it took 10 s and still
# counted them (2026-09-23), so 5 s stays far from both.
_auo2="$(_au --dir "$AU/big"; times > "$TMP/audit-big.cpu")"; _au_ms2="$(_au_ms "$TMP/audit-big.cpu")"
is  "it counts every stop in 41,400 lines: 450 passed and 450 failed" "$(_au_counts "$_auo2")" "450 450 0 0"
if [ "$(_au_counts "$_auo2")" = "450 450 0 0" ]; then
  [ "$_au_ms2" -le 5000 ] && ok  "and reads them in under 5 seconds of CPU" \
                          || bad "and reads them in under 5 seconds of CPU" "took ${_au_ms2} ms of CPU"
else
  bad "and reads them in under 5 seconds of CPU" "it did not count them, so its speed says nothing"
fi

# Read-only, measured after every run above. Unconditional silence would pass
# against an engine with no audit at all, so each of these needs a report.
_au_after="$(_au_snap "$AU")"; _au_home_after="$(_au_snap "$AU/home")"
if [ "$_au_report" -eq 1 ]; then
  [ "$_au_before" = "$_au_after" ] \
    && ok  "across every run, no file appeared, vanished or changed under the scratch root" \
    || bad "across every run, no file appeared, vanished or changed under the scratch root" \
           "$(diff <(printf '%s\n' "$_au_before") <(printf '%s\n' "$_au_after") | head -20)"
  [ "$_au_home_before" = "$_au_home_after" ] && [ ! -e "$AU/home/.felix-home" ] && [ ! -e "$AU/home/.felix" ] && [ ! -e "$AU/home/.claude" ] \
    && ok  "and nothing in the scratch HOME changed: no .felix-home, no .felix, no .claude" \
    || bad "and nothing in the scratch HOME changed: no .felix-home, no .felix, no .claude" "$(ls -A "$AU/home")"
  [ ! -s "$AUSTUB_LOG" ] \
    && ok  "and no claude, gh, curl or wget was called" \
    || bad "and no claude, gh, curl or wget was called" "$(head -5 "$AUSTUB_LOG")"
else
  for _n in "across every run, no file appeared, vanished or changed under the scratch root" \
            "and nothing in the scratch HOME changed: no .felix-home, no .felix, no .claude" \
            "and no claude, gh, curl or wget was called"; do
    bad "$_n" "no report was produced, so an untouched tree proves nothing"
  done
fi

