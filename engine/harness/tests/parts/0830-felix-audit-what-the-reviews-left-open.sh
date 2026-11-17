# Written blind, from what the verifiers of the fixes above left open and what
# they noticed besides, before any change for it: each says what the audit,
# felix new or this suite should do. The ones still open were shown failing
# against the engine as it stands; the rest pin a fix no assertion bound.
# Fixtures sit under $RV like the reviews', so their paths strip to AUROOT.
printf '\nfelix audit: what the reviews left open\n'
_au_build
_rv_build

# Runner names that are text, a shape at a time so a failure names it: a
# here-document body outside any double quotes, whose lines start with a
# runner; markdown backticks in a one-line commit message; runner names in
# one-line double-quoted text, beside a runner whose own argument is quoted.
_rv_one open/hdoc o-hd1 'git commit -F - <<'"'"'EOF'"'"'\nfix: the parser\n\nnpm test passes now\nEOF'
_rv_one open/hdoc o-hd2 'cat > notes.md <<EOF\npytest -q\nEOF'
is  "a runner at the start of a here-document line is text handed to a command, not a check" \
    "$(_au_counts "$(_au --dir "$RV/open/hdoc")")" "0 0 0 2"
_rv_one open/btick o-bt1 'git commit -m \"fix: `felix gate` passes on the parser\"'
is  "a runner in markdown backticks inside a one-line commit message is not counted as a check" \
    "$(_au_counts "$(_au --dir "$RV/open/btick")")" "0 0 0 1"
_rv_one open/dq o-dq1 'grep -nE \"foo|pytest\" README.md'
_rv_one open/dq o-dq2 'pgrep -fl \"tests/run|felix gate\"'
_rv_one open/dq o-dq3 'echo \"step 2; npm test next\"'
_rv_one open/dq o-dq4 'pytest -k \"parse or lex\" tests/'
is  "a runner inside one-line double-quoted text, a grep or pgrep pattern or an echo, is not a check; a runner whose own argument is quoted still is" \
    "$(_au_counts "$(_au --dir "$RV/open/dq")")" "1 0 0 3"

# A runner handed to a shell as its script is a run, not text: counted, or
# the report says plainly that such runs are not seen.
_rv_one open/shc o-sc1 'bash -c '"'"'cd /w && npm test'"'"''
_rv_one open/shc o-sc2 'timeout 600 bash -c '"'"'pytest -q'"'"''
_rv_one open/shc o-sc3 'bash <<'"'"'EOF'"'"'\nnpm test\nEOF'
_rvo="$(_au --dir "$RV/open/shc")"
if [ "$(_au_counts "$_rvo")" = "3 0 0 0" ] || { [ -n "$_rvo" ] && _rv_says "$_rvo" '(ba)?sh -c'; }; then
  ok  "a runner in bash -c '...' or in a here-document fed to bash is counted as a check, or the report says such runs are not seen"
else
  bad "a runner in bash -c '...' or in a here-document fed to bash is counted as a check, or the report says such runs are not seen" "$_rvo"
fi

# The word pipefail in an echo turns nothing on: the check piped into tail
# still hands its status away. Beside a plain check, so 1 of 2 could not fail.
_rv_one open/pfw o-pw1 'echo \"pipefail is off here\"; npm test | tail -3'
_rv_one open/pfw o-pw2 'npm test'
_rvo="$(_au --dir "$RV/open/pfw")"
[ "$(_au_counts "$_rvo")" = "2 0 0 0" ] && _au_nums "$_rvo" 'pipe|background' 1 \
  && ok  "the word pipefail in an echo does not make a piped check able to fail: 1 of 2 passing checks could not have" \
  || bad "the word pipefail in an echo does not make a piped check able to fail: 1 of 2 passing checks could not have" "$_rvo"

# Holds are counted from every stop hook feedback, the four classes only from
# stops after an edit. One hold here follows a stop after an edit and two
# follow turns with no new edit, in two sessions. Each clause of the hold
# paragraph saying held stops are counted, included or among the stops above
# must carry the number 1 just before that word: not none, which claims all 3.
_rv_new open/stops o-k1
_au_edit "$_rv_ts:01.000Z" msg_ok1a toolu_ok1a; _au_bash "$_rv_ts:02.000Z" msg_ok1b toolu_ok1b 'npm test'
_au_res  "$_rv_ts:03.000Z" toolu_ok1b ok; _au_stop "$_rv_ts:04.000Z" msg_ok1c
_au_hold "$_rv_ts:05.000Z" 'Stop hook feedback:\nThe gate last ran at 2026-04-01T00:00:00Z, on a different tree.'
_au_say  "$_rv_ts:06.000Z" 'why?'; _au_stop "$_rv_ts:07.000Z" msg_ok1d 'The gate ran on another tree.'
_au_hold "$_rv_ts:08.000Z" 'Stop hook feedback:\nThe gate last ran at 2026-04-01T00:00:00Z, on a different tree.'
_rv_new open/stops o-k2
_au_say  "$_rv_ts:01.000Z" 'what is this repo?'; _au_stop "$_rv_ts:02.000Z" msg_ok2a 'A parser.'
_au_hold "$_rv_ts:03.000Z" 'Stop hook feedback:\nThe gate has never run on this checkout.'
_rvho="$(_au --dir "$RV/open/stops")"
_rvc="$(printf '%s\n' "$_rvho" | awk '
  { l = tolower($0) }
  !p && l ~ /(^|[^a-z])(held|holds?)([^a-z]|$)/ && l ~ /[0-9]/ { p = 1 }
  p == 1 && !NF { p = 2 }
  p == 1 { s = s " " tolower($0) }
  END { n = split(s, S, /[.;:]/)
        for (i = 1; i <= n; i++) {
          if (S[i] !~ /counted|included|among/ || S[i] !~ /above/) continue
          match(S[i], /counted|included|among/); pre = substr(S[i], 1, RSTART - 1); num = "none"
          while (match(pre, /[0-9]+/)) { num = substr(pre, RSTART, RLENGTH); pre = substr(pre, RSTART + RLENGTH) }
          printf "%s ", num } }')"
_rvn="of 3 held stops, the hold line counts among the stops above only the 1 that followed an edit, not the 2 after turns with no new edit"
if _au_nums "$_rvho" 'came after' 1 && _au_nums "$_rvho" 'held' 3 2; then
  _rvx=0; for _c in $_rvc; do [ "$_c" = 1 ] || _rvx=1; done
  [ "$_rvx" -eq 0 ] && ok "$_rvn" || bad "$_rvn" "claims [$_rvc]: $(printf '%s\n' "$_rvho" | grep -i 'held [0-9]')"
else
  bad "$_rvn" "not read as 1 stop after an edit and 3 holds in 2 sessions: $_rvho"
fi
# A held stop did not end, so no wording anywhere says a turn ended.
_rvh="$(printf '%s\n' "$_rvho"; _au --help; "$FELIX" 2>&1 | grep -i -A3 'felix audit')"
[ "$(_au_counts "$_rvho")" = "1 0 0 0" ] && ! _rv_says "$_rvh" 'turns? ended|ended anyway|ended on' \
  && ok  "no line of the report, of felix audit --help or of felix's help says a turn ended, since a held stop did not" \
  || bad "no line of the report, of felix audit --help or of felix's help says a turn ended, since a held stop did not" "$_rvh"

# A tool_use with its type key first, whose input holds an id and a name of
# its own ahead of the block's: an Edit whose input names Bash, and a Bash
# whose input names Read and fails.
_rv_new open/tfirst o-tf1
_au_a "$_rv_ts:01.000Z" msg_otf1a '"tool_use"' '{"type":"tool_use","input":{"file_path":"/w/a.js","name":"Bash","id":"toolu_decoy1"},"name":"Edit","id":"toolu_otf1a"}'
_au_stop "$_rv_ts:02.000Z" msg_otf1b
_rv_new open/tfirst o-tf2
_au_edit "$_rv_ts:01.000Z" msg_otf2a toolu_otf2a
_au_a "$_rv_ts:02.000Z" msg_otf2b '"tool_use"' '{"type":"tool_use","input":{"command":"npm test","name":"Read","id":"toolu_decoy2"},"name":"Bash","id":"toolu_otf2b"}'
_au_res "$_rv_ts:03.000Z" toolu_otf2b true; _au_stop "$_rv_ts:04.000Z" msg_otf2c
is  "a tool_use with its type key first is read by its own id and name, not by an id or a name nested in its input ahead of them" \
    "$(_au_counts "$(_au --dir "$RV/open/tfirst")")" "0 1 0 1"

# A check piped into another command hides its own status, but the command
# that took it can fail, and then the stop is counted failed. So no sentence
# may say a piped check's result is never marked an error: not the report's,
# and not the README's, which says what the report does.
_rv_one open/pipe o-pp1 'pytest | grep -q passed' true
_rvo="$(_au --dir "$RV/open/pipe")"
[ "$(_au_counts "$_rvo")" = "0 1 0 0" ] && ! _rv_says "$_rvo" 'never[^.]*marked[^.]*error' \
  && ok  "a failing piped check is counted failed, and the report does not say a piped check's result is never marked an error" \
  || bad "a failing piped check is counted failed, and the report does not say a piped check's result is never marked an error" "$_rvo"
_rvr="$(awk '/^## / { p = ($0 ~ /^## Try it/); next } p' "$REAL_HARNESS/../../README.md" 2>/dev/null)"
if [ -n "$_rvr" ]; then
  ! _rv_says "$_rvr" 'never[^.]*marked[^.]*error' \
    && ok  "nor does the README's Try it section" \
    || bad "nor does the README's Try it section" "$(printf '%s\n' "$_rvr" | grep -i -B1 -A1 'marked')"
  _rv_says "$_rvr" 'git clone' && _rv_says "$_rvr" 'felix audit' && _rv_says "$_rvr" 'felix new [^ ]+ --no-commission' \
    && _rv_says "$_rvr" 'felix install' && ! _rv_says "$_rvr" 'no-commission[^.]*(nothing installed|without installing)' \
    && ok  "the README's Try it section shows felix audit from a clone and felix new <name> --no-commission, and names felix install as what holds sessions" \
    || bad "the README's Try it section shows felix audit from a clone and felix new <name> --no-commission, and names felix install as what holds sessions" "$_rvr"
  # With no gate guessed, felix gate after --no-commission exits 1 naming the
  # missing gate, so a sentence promising it at once has to carry a condition.
  printf '%s\n' "$_rvr" | awk '{ s = s " " tolower($0) } END { n = split(s, S, /\. /)
      for (i = 1; i <= n; i++)
        if (S[i] ~ /felix gate/ && S[i] ~ /(straight|right) away|immediately|at once/ \
            && S[i] !~ /(^|[^a-z])(if|when|once|where|unless|provided)([^a-z]|$)/) f = 1
      exit f ? 1 : 0 }' \
    && ok  "the README promises felix gate after --no-commission only where a gate was guessed or set" \
    || bad "the README promises felix gate after --no-commission only where a gate was guessed or set" "$(printf '%s\n' "$_rvr" | grep -i -B1 -A1 'away')"
else
  for _n in "nor does the README's Try it section" \
            "the README's Try it section shows felix audit from a clone and felix new <name> --no-commission, and names felix install as what holds sessions" \
            "the README promises felix gate after --no-commission only where a gate was guessed or set"; do
    bad "$_n" "no Try it section in $REAL_HARNESS/../../README.md"
  done
fi

# The time a command of megabytes costs, at the size the review measured: 6 MB
# holding 300,000 backslashes in one single-quoted argument after the runner,
# read with the default checks and with a --verify holding a backslash, the
# one path that rejoins what decoding split. And a command of 10,000 << that
# are shifts, not here-documents, each of which starts a look for a body.
# Some version of this engine spent minutes on each; seconds separate them.
# The first command ends by writing big.txt after its runner, a > to a named
# path, which is an edit after the check: its stop is stale, which also shows
# both ends of it were read.
mkdir -p "$RV/open/huge/-Users-dev-huge" "$RV/open/shifts/-Users-dev-shifts"
awk -v f="$RV/open/huge/-Users-dev-huge/h1.jsonl" -v g="$RV/open/shifts/-Users-dev-shifts/s1.jsonl" '
  function A(id, content, sr, ts) {
    return "{\"parentUuid\":\"p\",\"isSidechain\":false,\"message\":{\"model\":\"m\",\"id\":\"" id "\",\"type\":\"message\",\"role\":\"assistant\",\"content\":[" content "],\"stop_reason\":\"" sr "\"},\"type\":\"assistant\",\"uuid\":\"u-" id "\",\"timestamp\":\"2026-04-03T10:00:0" ts ".000Z\"}" }
  function B(o, id) {
    printf "%s", "{\"parentUuid\":\"p\",\"isSidechain\":false,\"message\":{\"model\":\"m\",\"id\":\"msg_" id "\",\"type\":\"message\",\"role\":\"assistant\",\"content\":[{\"type\":\"tool_use\",\"id\":\"toolu_" id "\",\"name\":\"Bash\",\"input\":{\"command\":\"" > o }
  function E(o, id, tail) {
    printf "%s\n", tail "\"}}],\"stop_reason\":\"tool_use\"},\"type\":\"assistant\",\"uuid\":\"u-" id "\",\"timestamp\":\"2026-04-03T10:00:02.000Z\"}" > o
    print "{\"parentUuid\":\"p\",\"isSidechain\":false,\"type\":\"user\",\"message\":{\"role\":\"user\",\"content\":[{\"tool_use_id\":\"toolu_" id "\",\"type\":\"tool_result\",\"content\":\"ok\"}]},\"uuid\":\"u-r" id "\",\"timestamp\":\"2026-04-03T10:00:03.000Z\"}" > o
    print A("msg_d" id, "{\"type\":\"text\",\"text\":\"Done.\"}", "end_turn", 4) > o }
  BEGIN {
    ed = "{\"type\":\"tool_use\",\"id\":\"toolu_e1\",\"name\":\"Edit\",\"input\":{\"file_path\":\"/w/a.js\"}}"
    print A("msg_e1", ed, "tool_use", 1) > f
    B(f, "h1"); printf "%s", "npm test && printf %s \047" > f
    for (i = 0; i < 300000; i++) printf "%s", "abcdefghijklmnopqrs\\\\" > f
    E(f, "h1", "\047 > big.txt")
    print A("msg_e1", ed, "tool_use", 1) > g
    B(g, "s1"); for (i = 0; i < 10000; i++) printf "%s", "echo $((1<<2)); " > g
    E(g, "s1", "npm test")
  }'
# Timed as CPU: 0.4 s each at a load average near 340. The 6 MB reaches one
# reader whole, rawcmd(), which finds where the command ends; decoding, and
# the rejoin a backslash in --verify asks for, read only the 64K at its ends,
# where putting the backslashes back one piece at a time added under 0.1 s.
# With rawcmd() finding the end one escape at a time, the rest of the line
# copied at each, both runs still counted it and took 186 s (2026-09-23), so
# 5 s each stays far from both.
_rvo="$(_au --dir "$RV/open/huge"; times > "$RV/open/huge.cpu")"; _rv_ms="$(_au_ms "$RV/open/huge.cpu")"
_rvo2="$(_au --dir "$RV/open/huge" --verify 'npm test|x\\z'; times > "$RV/open/huge2.cpu")"; _rv_ms2="$(_au_ms "$RV/open/huge2.cpu")"
_rvn="a 6 MB command holding 300,000 backslashes is read in seconds, with the default checks and with a --verify that holds a backslash: under 5 seconds of CPU each"
if [ "$(_au_counts "$_rvo")" = "0 0 1 0" ] && [ "$(_au_counts "$_rvo2")" = "0 0 1 0" ]; then
  [ "$_rv_ms" -le 5000 ] && [ "$_rv_ms2" -le 5000 ] && ok "$_rvn" \
    || bad "$_rvn" "took ${_rv_ms} and ${_rv_ms2} ms of CPU"
else
  bad "$_rvn" "it did not count them, so its speed says nothing: $(_au_counts "$_rvo") / $(_au_counts "$_rvo2")"
fi
# The shifts are timed as CPU, not wall clock. At a load average near 300 the
# wall clock read 9 s, and an hour later it passed on the same tree; the read
# measured 0.4 s of CPU at a load near 200. times inside the substitution
# counts that subshell and the audit under it, and nothing else the suite has
# running. With each << found again from the start of the command, or the
# rest of the command searched at each, the read took 18 s and 11 s of CPU
# and still counted it (2026-09-23), so 5 s stays far from all three.
_rvo="$(_au --dir "$RV/open/shifts"; times > "$RV/open/shifts.cpu")"; _rv_ms="$(_au_ms "$RV/open/shifts.cpu")"
_rvn="a command of 10,000 << shifts, none of them a here-document, is read in one pass: under 5 seconds of CPU"
if [ "$(_au_counts "$_rvo")" = "1 0 0 0" ]; then
  [ "$_rv_ms" -le 5000 ] && ok "$_rvn" || bad "$_rvn" "took ${_rv_ms} ms of CPU"
else
  bad "$_rvn" "it did not count it, so its speed says nothing: $(_au_counts "$_rvo")"
fi

