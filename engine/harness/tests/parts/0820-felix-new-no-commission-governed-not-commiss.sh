printf '\nfelix new --no-commission: governed, not commissioned\n'
_au_build
_nc_build
for _r in r-trail r-lead r-mid r-full r-bogus; do _nc_repo "$_r"; done

out="$(cd "$NC" && "$FELIX" new 2>&1)"
has "felix new's usage line names --no-commission" "$out" "--no-commission"
case "$("$FELIX" 2>&1)" in
  *"--no-commission"*) ok  "the grouped help names --no-commission" ;;
  *)                   bad "the grouped help names --no-commission" "no --no-commission in the help" ;;
esac

_nct="$(_nc "$NC/r-trail" nctrail --no-commission)"; _nctrc=$?; _nctcalls="$(_nc_calls)"
_ncf="$(_nc "$NC/r-full" ncfull)"; _ncfrc=$?; _ncfcalls="$(_nc_calls)"
_nctb=0; [ "$_nctrc" -eq 0 ] && _nc_bound r-trail nctrail && _nctb=1
if [ "$_nctb" -eq 1 ] && [ -n "$(_nc_ls nctrail)" ] && [ "$(_nc_ls nctrail)" = "$(_nc_ls ncfull)" ] \
   && [ -f "$NC/mem/nctrail/DEVLOG.md" ] && [ -f "$NC/mem/nctrail/lessons.md" ] && [ -f "$NC/mem/nctrail/SESSION_HANDOFF.md" ]; then
  ok  "felix new <name> --no-commission creates the project, binds the checkout, and seeds what a commissioned one gets"
else
  bad "felix new <name> --no-commission creates the project, binds the checkout, and seeds what a commissioned one gets" \
      "rc=$_nctrc marker=[$(cat "$NC/r-trail/.felix" 2>/dev/null)] seeded=[$(_nc_ls nctrail)] commissioned=[$(_nc_ls ncfull)]"
fi
if [ "$_nctb" -eq 1 ]; then
  is  "and calls no claude" "$_nctcalls" "0"
  case "$_nct" in
    *"commissioning for nctrail"*) bad "and runs none of commissioning: no run, no receipt, no discovery cache, no commissioning log" "$_nct" ;;
    *) [ ! -e "$NC/home/state/commission/nctrail" ] && [ ! -e "$NC/home/state/discover/nctrail.tsv" ] \
         && [ ! -e "$NC/mem/nctrail/commissioning.log" ] && [ ! -e "$NC/mem/nctrail/commission" ] \
         && ok  "and runs none of commissioning: no run, no receipt, no discovery cache, no commissioning log" \
         || bad "and runs none of commissioning: no run, no receipt, no discovery cache, no commissioning log" \
                "$(find "$NC/home/state" "$NC/mem/nctrail" -print 2>/dev/null | grep -i -e commission -e discover)" ;;
  esac
else
  bad "and calls no claude" "the project was not created and bound, so a silent stub proves nothing"
  bad "and runs none of commissioning: no run, no receipt, no discovery cache, no commissioning log" \
      "the project was not created and bound, so an absent receipt proves nothing"
fi
grep -i 'skip' <<<"$_nct" | grep -q 'felix commission' \
  && ok  "and prints one line saying commissioning was skipped and felix commission runs it later" \
  || bad "and prints one line saying commissioning was skipped and felix commission runs it later" "$_nct"

# Without the flag the same checkout shape commissions, through the same stub:
# so the flag, and nothing else about these runs, is what made the difference.
if [ "$_ncfrc" -eq 0 ] && [ "${_ncfcalls:-0}" -gt 0 ] && [ -f "$NC/home/state/commission/ncfull" ] \
   && [ "$_nctb" -eq 1 ] && [ "$_nctcalls" = "0" ] && [ ! -e "$NC/home/state/commission/nctrail" ]; then
  ok  "the flag is what made the difference: the same felix new without it calls claude and writes a receipt"
else
  bad "the flag is what made the difference: the same felix new without it calls claude and writes a receipt" \
      "without: rc=$_ncfrc calls=$_ncfcalls receipt=$([ -f "$NC/home/state/commission/ncfull" ] && echo yes || echo no); with: bound=$_nctb calls=$_nctcalls"
fi

_ncl="$(_nc "$NC/r-lead" --no-commission nclead)"; _nclrc=$?; _nclcalls="$(_nc_calls)"
_ncg="$(_nc "$NC/r-bogus" --bogus ncbogus)"; _ncgrc=$?
if [ "$_nclrc" -eq 0 ] && _nc_bound r-lead nclead && [ "$_nclcalls" = "0" ] \
   && [ "$_ncgrc" -ne 0 ] && [ ! -e "$NC/home/projects/ncbogus" ] && [ ! -e "$NC/home/projects/--bogus" ]; then
  case "$_ncg" in
    *"got a flag"*) ok  "a leading --no-commission is the flag, while any other leading flag is still refused as a name" ;;
    *)              bad "a leading --no-commission is the flag, while any other leading flag is still refused as a name" "$_ncg" ;;
  esac
else
  bad "a leading --no-commission is the flag, while any other leading flag is still refused as a name" \
      "leading: rc=$_nclrc calls=$_nclcalls marker=[$(cat "$NC/r-lead/.felix" 2>/dev/null)]; --bogus: rc=$_ncgrc $_ncg"
fi

_ncm="$(_nc "$NC" ncmid --no-commission "$NC/r-mid")"; _ncmrc=$?; _ncmcalls="$(_nc_calls)"
[ "$_ncmrc" -eq 0 ] && _nc_bound r-mid ncmid && [ "$_ncmcalls" = "0" ] && [ ! -e "$NC/.felix" ] \
  && ok  "the flag between the name and the path binds the path given" \
  || bad "the flag between the name and the path binds the path given" "rc=$_ncmrc calls=$_ncmcalls marker=[$(cat "$NC/r-mid/.felix" 2>/dev/null)] $_ncm"

if [ "$_nctb" -eq 1 ]; then
  : > "$CMSTUB_LOG"
  ( cd "$NC/r-trail" && HOME="$NC/userhome" FELIX_HOME="$NC/home" FELIX_MEMORY="$NC/mem" PATH="$CMSTUB:$PATH" "$FELIX" commission ) >/dev/null 2>&1
  [ "$(_nc_calls)" -gt 0 ] && [ -f "$NC/home/state/commission/nctrail" ] \
    && ok  "felix commission, run later, commissions what felix new --no-commission created" \
    || bad "felix commission, run later, commissions what felix new --no-commission created" "calls=$(_nc_calls)"
else
  bad "felix commission, run later, commissions what felix new --no-commission created" \
      "felix new --no-commission created nothing to commission"
fi

# Not blind: written by the implementer, after the blind section above went
# green, for the two paths of lib/audit.sh no line of that fixture reaches.
# Claude Code writes one content block per line, so the block cutting in uses()
# and results() only ever sees one block there. These lines hold two: a
# non-check before the check, and results whose first block carries a content
# array, whose "},{" is not the boundary between the blocks. Read as one block,
# the first session's check is missed or charged with the other call's error,
# and the second session's failure lands on nothing.
printf '\nfelix audit: two blocks on one line\n'
AUM="$TMP/audit-multi/-Users-dev-multi"; mkdir -p "$AUM"
_au_open "$AUM/m1.jsonl" m1
_au_edit 2026-03-10T10:00:01.000Z msg_M1 toolu_M1
_au_res  2026-03-10T10:00:02.000Z toolu_M1 ok
_au_tool toolu_M2b Bash '{"command":"ls /nope"}'; _aum_b1="$_AU_B"
_au_tool toolu_M2a Bash '{"command":"npm test"}'
_au_a    2026-03-10T10:00:03.000Z msg_M2 '"tool_use"' "$_aum_b1,$_AU_B"
_au_u    2026-03-10T10:00:04.000Z '[{"tool_use_id":"toolu_M2a","type":"tool_result","content":[{"type":"text","text":"ok"},{"type":"text","text":"12 passed"}]},{"tool_use_id":"toolu_M2b","type":"tool_result","content":"No such file","is_error":true}]'
_au_stop 2026-03-10T10:00:05.000Z msg_M3 'Done.'
_au_open "$AUM/m2.jsonl" m2
_au_edit 2026-03-10T11:00:01.000Z msg_N1 toolu_N1
_au_res  2026-03-10T11:00:02.000Z toolu_N1 ok
_au_tool toolu_N2b Bash '{"command":"git status"}'; _aum_b1="$_AU_B"
_au_tool toolu_N2a Bash '{"command":"npm test"}'
_au_a    2026-03-10T11:00:03.000Z msg_N2 '"tool_use"' "$_aum_b1,$_AU_B"
_au_u    2026-03-10T11:00:04.000Z '[{"tool_use_id":"toolu_N2a","type":"tool_result","content":[{"type":"text","text":"1 failed"},{"type":"text","text":"x"}],"is_error":true},{"tool_use_id":"toolu_N2b","type":"tool_result","content":"clean"}]'
_au_stop 2026-03-10T11:00:05.000Z msg_N3 'Done.'
# Every audit run here goes through _au, with the scratch HOME and the stubs
# first on PATH: run with the suite's own HOME, an audit that regressed to
# writing ~/.felix-home would truncate the developer's before anything failed.
is  "a line of two tool_use blocks is read block by block, and an error is charged only to the result block that reported it" \
    "$(_au_counts "$(_au --dir "$TMP/audit-multi")")" "1 1 0 0"
out="$(_au --help)"; rc=$?
[ "$rc" -eq 0 ] && case "$out" in *"usage: felix audit"*) true ;; *) false ;; esac \
  && ok  "felix audit --help answers its usage and reads nothing" \
  || bad "felix audit --help answers its usage and reads nothing" "rc=$rc $out"
# Beside the same run on a directory, so an engine with no audit, which exits
# non-zero on both, cannot pass it.
_au --dir "$TMP/audit-multi" >/dev/null; _aumrc=$?
_au --dir "$TMP/audit-nope" >/dev/null; rc=$?
[ "$_aumrc" -eq 0 ] && [ "$rc" -ne 0 ] \
  && ok  "an explicit --dir that is not a directory is refused, where the same run on a directory exits 0" \
  || bad "an explicit --dir that is not a directory is refused, where the same run on a directory exits 0" "directory: $_aumrc, not one: $rc"

# Not blind either: written by the fixer, from two reviews of the code above,
# one assertion per defect they found, each shown failing against the engine
# before the fix. Fixtures sit under $AU so the report's paths strip to AUROOT
# and no digit in a temporary path can pass a count; the read-only snapshot
# above was taken before any of them existed.
printf '\nfelix audit: what the reviews found\n'
_rv_build

# A pipe, a later command or the background takes a check's exit status, so
# "no error reported" is all such a check can say. pipefail, && and 2>&1 do not.
_rv_hid_build
_rvo="$(_au --dir "$RV/hid")"
if [ "$(_au_counts "$_rvo")" = "5 0 0 0" ] && _au_nums "$_rvo" 'pipe|background' 3; then
  ok  "a passing check whose exit status a pipe, a later command or the background took is counted as one that could not fail: 3 of 5"
else
  bad "a passing check whose exit status a pipe, a later command or the background took is counted as one that could not fail: 3 of 5" "$_rvo"
fi
case "$(printf '%s\n' "$_rvo" | grep -E '^ *passed ')" in
  *"reported no error"*) ok  "and the passed class claims only that no error was reported" ;;
  *)                     bad "and the passed class claims only that no error was reported" "$_rvo" ;;
esac

# The same session under two project directories, and its history copied into
# a resumed session that then stops again with no new edit: one stop, one hold.
_rv_new dup s-dup
_au_edit "$_rv_ts:01.000Z" msg_D1 toolu_D1; _au_bash "$_rv_ts:02.000Z" msg_D2 toolu_D2 'npm test'
_au_res "$_rv_ts:03.000Z" toolu_D2 ok; _au_stop "$_rv_ts:04.000Z" msg_D3
_au_hold "$_rv_ts:05.000Z" 'Stop hook feedback:\nThe gate last ran at 2026-04-01T00:00:00Z, on a different tree.'
mkdir -p "$RV/dup/-Users-dev-rv2"; cp "$RV/dup/-Users-dev-rv/s-dup.jsonl" "$RV/dup/-Users-dev-rv2/"
cp "$RV/dup/-Users-dev-rv/s-dup.jsonl" "$RV/dup/-Users-dev-rv/s-resumed.jsonl"
_AU_F="$RV/dup/-Users-dev-rv/s-resumed.jsonl"; _AU_SID=s-resumed
_au_say "$_rv_ts:09.000Z" 'what did you change?'; _au_stop "$_rv_ts:10.000Z" msg_D4 'Only the parser.'
_rvo="$(_au --dir "$RV/dup")"
if _au_nums "$_rvo" '^ *sessions' 2 && _au_nums "$_rvo" 'came after' 1 1 && _au_nums "$_rvo" 'held' 1 1 \
   && [ "$(_au_counts "$_rvo")" = "1 0 0 0" ]; then
  ok  "a session filed under two projects, and history copied into a resumed one, count once: 2 sessions, 1 stop, 1 hold"
else
  bad "a session filed under two projects, and history copied into a resumed one, count once: 2 sessions, 1 stop, 1 hold" "$_rvo"
fi

# Runner names that are text: a here-document commit message (backticks and
# all), a grep alternation, a commit message over several lines. A runner
# after a quoted path holding an apostrophe still counts.
_rv_new quoted q1; _au_edit "$_rv_ts:01.000Z" msg_Q1a toolu_Q1a
_au_bash "$_rv_ts:02.000Z" msg_Q1b toolu_Q1b 'git commit -m \"$(cat <<'"'"'EOF'"'"'\nfix: x\n\n`felix gate` passes; tests/run reports 12\nEOF\n)\"'
_au_res "$_rv_ts:03.000Z" toolu_Q1b ok; _au_stop "$_rv_ts:04.000Z" msg_Q1c
_rv_new quoted q2; _au_edit "$_rv_ts:01.000Z" msg_Q2a toolu_Q2a
_au_bash "$_rv_ts:02.000Z" msg_Q2b toolu_Q2b "grep -nE 'foo|pytest' README.md"; _au_res "$_rv_ts:03.000Z" toolu_Q2b ok
_au_stop "$_rv_ts:04.000Z" msg_Q2c
_rv_new quoted q3; _au_edit "$_rv_ts:01.000Z" msg_Q3a toolu_Q3a
_au_bash "$_rv_ts:02.000Z" msg_Q3b toolu_Q3b 'git commit -m \"fix the parser\n\npytest passes now\"'; _au_res "$_rv_ts:03.000Z" toolu_Q3b ok
_au_stop "$_rv_ts:04.000Z" msg_Q3c
_rv_new quoted q4; _au_edit "$_rv_ts:01.000Z" msg_Q4a toolu_Q4a
_au_bash "$_rv_ts:02.000Z" msg_Q4b toolu_Q4b 'cd \"/w/it'"'"'s here\" && npm test'; _au_res "$_rv_ts:03.000Z" toolu_Q4b ok
_au_stop "$_rv_ts:04.000Z" msg_Q4c
is  "a runner named in a here-document, a single-quoted pattern or a multi-line message is text, not a check; one after a quoted path is" \
    "$(_au_counts "$(_au --dir "$RV/quoted")")" "1 0 0 3"

# Edits no gate covers: a scratch file and a memory note under the config
# directory. Their stops are said, and left out of the four.
_rv_new aside a1
_au_tool toolu_A1a Write '{"file_path":"/tmp/scratch.py","content":"x"}'; _au_a "$_rv_ts:01.000Z" msg_A1a '"tool_use"' "$_AU_B"
_au_stop "$_rv_ts:02.000Z" msg_A1b
_au_tool toolu_A1c Edit "{\"file_path\":\"$AU/cfg/projects/-Users-dev-rv/memory/note.md\",\"old_string\":\"a\",\"new_string\":\"b\"}"
_au_a "$_rv_ts:03.000Z" msg_A1c '"tool_use"' "$_AU_B"; _au_stop "$_rv_ts:04.000Z" msg_A1d
_au_edit "$_rv_ts:05.000Z" msg_A1e toolu_A1e; _au_stop "$_rv_ts:06.000Z" msg_A1f
_rvo="$(_au --dir "$RV/aside")"
if [ "$(_au_counts "$_rvo")" = "0 0 0 1" ] && _au_nums "$_rvo" 'came after' 1 && _au_nums "$_rvo" 'scratch' 2; then
  ok  "an edit to a scratch file or to Claude's own config directory is left out of the four, and the report says how many stops that was"
else
  bad "an edit to a scratch file or to Claude's own config directory is left out of the four, and the report says how many stops that was" "$_rvo"
fi

# Record-level keys only: an isSidechain and a timestamp nested in a tool's
# result, a subagent message nested in a progress record, and a tool_use whose
# type key comes last, with id and name keys nested in its input before its own.
_rv_new nested n1; _au_edit 2026-09-02T00:00:00.000Z msg_N1a toolu_N1a
_au_bash 2026-09-02T00:00:01.000Z msg_N1b toolu_N1b 'npm test'
_au_raw "{\"parentUuid\":\"p\",\"isSidechain\":false,\"type\":\"user\",\"message\":{\"role\":\"user\",\"content\":[{\"tool_use_id\":\"toolu_N1b\",\"type\":\"tool_result\",\"content\":\"1 failed\",\"is_error\":true}]},\"uuid\":\"u-n1\",\"timestamp\":\"2026-09-02T00:00:02.000Z\",\"toolUseResult\":{\"stdout\":\"\",\"meta\":{\"timestamp\":\"2026-08-01T00:00:00Z\"},\"agent\":{\"isSidechain\":true}}}"
_au_stop 2026-09-02T00:00:03.000Z msg_N1c
_rv_new nested n2; _au_bash 2026-09-02T00:00:00.000Z msg_N2a toolu_N2a 'npm test'; _au_res 2026-09-02T00:00:01.000Z toolu_N2a ok
_au_raw '{"parentUuid":"p","isSidechain":false,"type":"progress","data":{"type":"agent_progress","message":{"type":"assistant","message":{"id":"msg_sub1","type":"message","role":"assistant","content":[{"type":"tool_use","id":"toolu_sub1","name":"Edit","input":{"file_path":"/w/a"}}],"stop_reason":"tool_use"}}},"uuid":"u-p1","timestamp":"2026-09-02T00:00:02.000Z"}'
_au_raw '{"parentUuid":"p","isSidechain":false,"type":"progress","data":{"type":"agent_progress","message":{"type":"assistant","message":{"id":"msg_sub2","type":"message","role":"assistant","content":[{"type":"text","text":"done"}],"stop_reason":"end_turn"}}},"uuid":"u-p2","timestamp":"2026-09-02T00:00:03.000Z"}'
_au_stop 2026-09-02T00:00:04.000Z msg_N2b
_rv_new nested n3
_au_a 2026-09-02T00:00:00.000Z msg_N3a '"tool_use"' '{"id":"toolu_N3a","name":"Edit","input":{"file_path":"/w/a.js"},"type":"tool_use"}'
_au_a 2026-09-02T00:00:01.000Z msg_N3b '"tool_use"' '{"input":{"command":"npm test","name":"x","id":"y"},"name":"Bash","id":"toolu_N3b","type":"tool_use"}'
_au_res 2026-09-02T00:00:02.000Z toolu_N3b true; _au_stop 2026-09-02T00:00:03.000Z msg_N3c
is  "whose record, when and whether a sidechain are read from the record's own keys, and a tool_use with its type key last is read" \
    "$(_au_counts "$(_au --since 2026-09-01 --dir "$RV/nested")")" "0 2 0 0"

# The shape of the directory: one project's directory given whole, and a last
# glob entry that is a directory or a dangling link, not a transcript.
mkdir -p "$RV/glob/-a" "$RV/glob/-zz/dir.jsonl" "$RV/glob2/-a" "$RV/glob2/-zz"
cp "$RV/hid/-Users-dev-rv/h1.jsonl" "$RV/glob/-a/"; cp "$RV/hid/-Users-dev-rv/h1.jsonl" "$RV/glob2/-a/"
ln -s "$RV/nowhere.jsonl" "$RV/glob2/-zz/x.jsonl"
_au --dir "$RV/glob" >/dev/null; _rvrc=$?; _au --dir "$RV/glob2" >/dev/null; _rvrc2=$?
_rvo="$(_au --dir "$RV/glob2")"
[ "$_rvrc" -eq 0 ] && [ "$_rvrc2" -eq 0 ] && [ "$(_au_counts "$_rvo")" = "1 0 0 0" ] \
  && ok  "a directory or a dangling link named like a transcript, sorting last, is skipped and the run exits 0" \
  || bad "a directory or a dangling link named like a transcript, sorting last, is skipped and the run exits 0" "rc=$_rvrc,$_rvrc2 $_rvo"
is  "--dir pointed at one project's directory reads the transcripts in it" \
    "$(_au_counts "$(_au --dir "$RV/hid/-Users-dev-rv")")" "5 0 0 0"

# The time a line of megabytes costs: a command of 262,144 backslashes before
# its runner, a result line whose first block holds 131,072 content blocks,
# and a result record holding 131,072 timestamps of its own. Each was a loop
# that re-copied the rest of the line per step: 63 seconds on BWK awk, where
# half these sizes took 17.
mkdir -p "$RV/perf/-Users-dev-perf"
awk -v d="$RV/perf/-Users-dev-perf" '
  function A(id, content, sr) {
    return "{\"parentUuid\":\"p\",\"isSidechain\":false,\"message\":{\"model\":\"m\",\"id\":\"" id "\",\"type\":\"message\",\"role\":\"assistant\",\"content\":[" content "],\"stop_reason\":\"" sr "\"},\"type\":\"assistant\",\"uuid\":\"u-" id "\",\"timestamp\":\"2026-04-03T10:00:00.000Z\"}" }
  function U(id, content, extra) {
    return "{\"parentUuid\":\"p\",\"isSidechain\":false,\"type\":\"user\",\"message\":{\"role\":\"user\",\"content\":[" content "]},\"uuid\":\"u-" id "\",\"timestamp\":\"2026-04-03T10:00:01.000Z\"" extra "}" }
  function T(id, name, input) { return "{\"type\":\"tool_use\",\"id\":\"toolu_" id "\",\"name\":\"" name "\",\"input\":" input "}" }
  function R(id, rest) { return "{\"tool_use_id\":\"toolu_" id "\",\"type\":\"tool_result\"," rest "}" }
  BEGIN {
    ed = "{\"file_path\":\"/w/a.js\"}"; done = "{\"type\":\"text\",\"text\":\"Done.\"}"
    bs = "\\\\"; for (i = 0; i < 18; i++) bs = bs bs
    tx = "{\"type\":\"text\",\"text\":\"x\"}"; for (i = 0; i < 17; i++) tx = tx "," tx
    ts = "{\"timestamp\":\"2026-03-01T00:00:00Z\"}"; for (i = 0; i < 17; i++) ts = ts "," ts
    f = d "/p1.jsonl"
    print A("msg_p1a", T("p1a", "Edit", ed), "tool_use") > f
    print A("msg_p1b", T("p1b", "Bash", "{\"command\":\"printf %s \047" bs "\047 && npm test\"}"), "tool_use") > f
    print U("p1c", R("p1b", "\"content\":\"ok\""), "") > f
    print A("msg_p1d", done, "end_turn") > f
    f = d "/p2.jsonl"
    print A("msg_p2a", T("p2a", "Edit", ed), "tool_use") > f
    print A("msg_p2b", T("p2x", "Read", ed) "," T("p2b", "Bash", "{\"command\":\"npm test\"}"), "tool_use") > f
    print U("p2c", R("p2x", "\"content\":[" tx "]") "," R("p2b", "\"content\":\"Exit code 1\",\"is_error\":true"), "") > f
    print A("msg_p2d", done, "end_turn") > f
    f = d "/p3.jsonl"
    print A("msg_p3a", T("p3a", "Edit", ed), "tool_use") > f
    print A("msg_p3b", T("p3b", "Bash", "{\"command\":\"npm test\"}"), "tool_use") > f
    print U("p3c", R("p3b", "\"content\":\"ok\""), ",\"toolUseResult\":{\"history\":[" ts "]}") > f
    print A("msg_p3d", done, "end_turn") > f
  }'
# Timed as CPU: 0.5 s at a load average near 340. Each session reaches its
# own reader, and each reader, made to copy the rest of its line at every
# step, still counted all three and took far longer (2026-09-23): rawcmd()
# finding the command's end one escape at a time 15 s, results() finding the
# last block boundary walking forward 37 s, stamp() walking every timestamp
# 50 s. So 5 s stays far from all of them.
_rvo="$(_au --dir "$RV/perf"; times > "$RV/perf.cpu")"; _rv_ms="$(_au_ms "$RV/perf.cpu")"
_rvn="a megabyte line of backslashes, content blocks or timestamps is read in one pass: three sessions in under 5 seconds of CPU"
if [ "$(_au_counts "$_rvo")" = "2 1 0 0" ]; then
  [ "$_rv_ms" -le 5000 ] && ok "$_rvn" || bad "$_rvn" "took ${_rv_ms} ms of CPU"
else
  bad "$_rvn" "it did not count them, so its speed says nothing: $(_au_counts "$_rvo")"
fi

# Arguments that used to pass and answer something nobody meant, each beside
# the run that differs only by them.
_au --dir "$RV/hid" --verify 'npm[[:space:]]+test' >/dev/null; _rvrc=$?
_au --dir "$RV/hid" --verify 'npm\s+test' >/dev/null; _rvrc2=$?
[ "$_rvrc" -eq 0 ] && [ "$_rvrc2" -ne 0 ] \
  && ok  "--verify refuses a backslash class, which is a class on one awk and a letter on another, where [[:space:]] runs" \
  || bad "--verify refuses a backslash class, which is a class on one awk and a letter on another, where [[:space:]] runs" "posix: $_rvrc, \\s: $_rvrc2"
_au --dir "$RV/hid" --since 2026-03-31 >/dev/null; _rvrc=$?
_au --dir "$RV/hid" --since 2026-19-39 >/dev/null; _rvrc2=$?
[ "$_rvrc" -eq 0 ] && [ "$_rvrc2" -ne 0 ] \
  && ok  "--since refuses a month of 19 and a day of 39, where a real date runs" \
  || bad "--since refuses a month of 19 and a day of 39, where a real date runs" "real: $_rvrc, 2026-19-39: $_rvrc2"

# No HOME and no CLAUDE_CONFIG_DIR is a machine with nowhere to look, not an
# error; and a transcript that cannot be opened is named, not dropped.
_rvo="$(cd "$AU/cwd" && env -i PATH="$AUSTUB:$PATH" "$AUF" audit 2>&1)"; _rvrc=$?
[ "$_rvrc" -eq 0 ] && _au_none "$_rvo" \
  && ok  "with neither HOME nor CLAUDE_CONFIG_DIR set it reports no transcripts and exits 0" \
  || bad "with neither HOME nor CLAUDE_CONFIG_DIR set it reports no transcripts and exits 0" "rc=$_rvrc $_rvo"
mkdir -p "$RV/unread/-a"; cp "$RV/hid/-Users-dev-rv/h1.jsonl" "$RV/hid/-Users-dev-rv/h2.jsonl" "$RV/unread/-a/"
chmod 000 "$RV/unread/-a/h2.jsonl"
if [ -r "$RV/unread/-a/h2.jsonl" ]; then
  skip "a transcript that cannot be opened is named in the report, not silently left out" "running as a user who reads a mode-000 file"
else
  _rvo="$(_au --dir "$RV/unread")"
  case "$(_au_strip "$_rvo")" in
    *"AUROOT/rv/unread/-a/h2.jsonl"*) ok  "a transcript that cannot be opened is named in the report, not silently left out" ;;
    *) bad "a transcript that cannot be opened is named in the report, not silently left out" "$_rvo" ;;
  esac
fi
chmod 644 "$RV/unread/-a/h2.jsonl"

# What the words claim. A hold means no passing gate result was current for
# the tree (it may have passed on it, before something moved), and a held stop
# is still one of the stops above. felix new --no-commission installs no
# plugin, but a session is only held once felix install has run.
_rvo="$(_au --dir "$AUD")"
case "$_rvo" in
  *"had not passed"*) bad "the hold line claims no more than the hold does, and says a held stop is counted" "$(printf '%s\n' "$_rvo" | grep -i held)" ;;
  *held*"still counted"*) ok "the hold line claims no more than the hold does, and says a held stop is counted" ;;
  *) bad "the hold line claims no more than the hold does, and says a held stop is counted" "$(printf '%s\n' "$_rvo" | grep -i held)" ;;
esac
_rvh="$("$FELIX" 2>&1 | grep -A3 -e '--no-commission$')"; _rvl="$(_au_last "$_rvo")"
case "$_rvh|$_rvl" in
  *"nothing installed"*|*"without installing anything"*) _rvw=0 ;;
  *"felix install"*"|"*"felix install"*) _rvw=1 ;;
  *) _rvw=0 ;;
esac
[ "$_rvw" -eq 1 ] \
  && ok  "neither the help nor the audit says --no-commission governs with nothing installed; both name felix install" \
  || bad "neither the help nor the audit says --no-commission governs with nothing installed; both name felix install" "help: $_rvh | last: $_rvl"

# felix new: a flag, or a path that is not a directory, where the path goes.
# Both used to create projects/<name>, write no marker, say "bound via" and
# exit 0, leaving a project the corrected command refused as already there.
_nc_repo r-typo
_ncy="$(_nc "$NC/r-typo" nctypo --no-comission)"; _ncyrc=$?
_ncz="$(_nc "$NC" ncnodir "$NC/does-not-exist")"; _nczrc=$?
if [ "$_ncyrc" -ne 0 ] && [ ! -e "$NC/home/projects/nctypo" ] && [ "$_nczrc" -ne 0 ] && [ ! -e "$NC/home/projects/ncnodir" ]; then
  ok  "felix new with a flag or a missing directory where the path goes is refused before anything is made"
else
  bad "felix new with a flag or a missing directory where the path goes is refused before anything is made" \
      "typo: rc=$_ncyrc made=$([ -e "$NC/home/projects/nctypo" ] && echo yes || echo no); missing: rc=$_nczrc made=$([ -e "$NC/home/projects/ncnodir" ] && echo yes || echo no)"
fi
_ncy2="$(_nc "$NC/r-typo" nctypo --no-commission)"; _ncy2rc=$?
[ "$_ncy2rc" -eq 0 ] && _nc_bound r-typo nctypo \
  && ok  "so the same command with the flag spelled right then binds it" \
  || bad "so the same command with the flag spelled right then binds it" "rc=$_ncy2rc $_ncy2"

