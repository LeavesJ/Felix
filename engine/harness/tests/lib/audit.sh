# tests/lib/audit.sh: the felix audit fixture, its transcript writers and its readers.
# Used by parts 0810 (builds the fixture), 0820 0830 0840 0850 (the fixture and the
# readers), and 0860 0870 0880 0890 (the transcript writers _au_open _au_a _au_u _au_say
# _au_stop _au_tool _au_res and the rest, for their own sessions). Moved from
# parts/0810-felix-audit-a-read-only-report-over-claude-c.sh: the writers and readers from lines 20-57, 226-247
# and 252-330 (_AU_B, _AU_F, _AU_SID and the _au_* functions, unchanged), the
# fixture from lines 2-19, 58-225 and 248-256 into _au_build, and lines 337-341 into
# _au_resume. Definitions only. A builder sets its variables first and does nothing more
# when its fixture is already there, so in the serial run only 0810's call builds.


# Transcripts in the shape Claude Code writes them: one compact JSON object per
# line, the assistant's own "type":"message" nested before the record's
# "type":"assistant", one line per content block, stop_reason repeated on each.
# _audit_vars: the variables this file's functions read, set when the prelude calls it
# (contract C2: a lib file defines functions and nothing else).
_audit_vars() {
_AU_F=""; _AU_SID=""
_AU_B=""
}
_au_open() { _AU_F="$1"; _AU_SID="$2"; mkdir -p "${1%/*}"; : > "$1"; }
_au_raw()  { printf '%s\n' "$1" >> "$_AU_F"; }
_au_a() {    # ts msgid stop_reason block [isSidechain]
  printf '{"parentUuid":"p","isSidechain":%s,"message":{"model":"claude-test","id":"%s","type":"message","role":"assistant","content":[%s],"stop_reason":%s,"stop_sequence":null,"usage":{"input_tokens":1,"output_tokens":1}},"requestId":"req_%s","type":"assistant","uuid":"u-%s","timestamp":"%s","sessionId":"%s"}\n' \
    "${5:-false}" "$2" "$4" "$3" "$2" "$2" "$1" "$_AU_SID" >> "$_AU_F"; }
_au_u() {    # ts content-json [isSidechain]
  printf '{"parentUuid":"p","isSidechain":%s,"type":"user","message":{"role":"user","content":%s},"uuid":"u","timestamp":"%s","sessionId":"%s"}\n' \
    "${3:-false}" "$2" "$1" "$_AU_SID" >> "$_AU_F"; }
_au_say()  { _au_u "$1" "\"$2\"" "${3:-false}"; }
# A stop hook's feedback, as Claude Code records it: a meta user record whose
# content is the string the hook returned.
_au_hold() {  # ts text [isSidechain]
  printf '{"parentUuid":"p","isSidechain":%s,"promptId":"pr","type":"user","message":{"role":"user","content":"%s"},"isMeta":true,"uuid":"u","timestamp":"%s","sessionId":"%s"}\n' \
    "${3:-false}" "$2" "$1" "$_AU_SID" >> "$_AU_F"; }
# Blocks are built with printf -v, never "$(...)": bash 3.2 brace-expands a
# quoted {"a":1,"b":2} inside a double-quoted command substitution, which cut
# every Bash call in the first version of this fixture in two.
_au_tool() { printf -v _AU_B '{"type":"tool_use","id":"%s","name":"%s","input":%s}' "$1" "$2" "$3"; }
_au_text() { printf -v _AU_B '{"type":"text","text":"%s"}' "$1"; }
_au_edit() { _au_tool "$3" "${4:-Edit}" '{"file_path":"/w/src/app.js","old_string":"a","new_string":"b"}'
             _au_a "$1" "$2" '"tool_use"' "$_AU_B" "${5:-false}"; }
_au_bash() { local inp; printf -v inp '{"command":"%s","description":"%s"}' "$4" "${5:-Run it}"
             _au_tool "$3" Bash "$inp"; _au_a "$1" "$2" '"tool_use"' "$_AU_B" "${6:-false}"; }
_au_stop() { _au_text "${3:-Done.}"; _au_a "$1" "$2" '"end_turn"' "$_AU_B" "${4:-false}"; }
_au_res() {  # ts tool_use_id ok|false|true|true-first [isSidechain]
  case "$3" in
    ok)         _au_u "$1" "[{\"tool_use_id\":\"$2\",\"type\":\"tool_result\",\"content\":\"ok\"}]" "${4:-false}" ;;
    false)      _au_u "$1" "[{\"tool_use_id\":\"$2\",\"type\":\"tool_result\",\"content\":\"ok\",\"is_error\":false}]" "${4:-false}" ;;
    true)       _au_u "$1" "[{\"tool_use_id\":\"$2\",\"type\":\"tool_result\",\"content\":\"Exit code 1\",\"is_error\":true}]" "${4:-false}" ;;
    true-first) _au_u "$1" "[{\"type\":\"tool_result\",\"content\":\"Exit code 1\",\"is_error\":true,\"tool_use_id\":\"$2\"}]" "${4:-false}" ;;
  esac; }

# And a larger set, for speed: two sessions of 450 turns, each turn twenty
# reads, an edit, a check and a stop — 41,400 lines, 450 passed and 450 failed.
_au_big() {  # file session-id turns
  awk -v sid="$2" -v n="$3" 'BEGIN {
    a = "{\"parentUuid\":\"p\",\"isSidechain\":false,\"message\":{\"model\":\"claude-test\",\"id\":\"%s\",\"type\":\"message\",\"role\":\"assistant\",\"content\":[%s],\"stop_reason\":\"%s\",\"stop_sequence\":null},\"type\":\"assistant\",\"uuid\":\"u\",\"timestamp\":\"2026-04-01T10:00:00.000Z\",\"sessionId\":\"" sid "\"}\n"
    u = "{\"parentUuid\":\"p\",\"isSidechain\":false,\"type\":\"user\",\"message\":{\"role\":\"user\",\"content\":%s},\"uuid\":\"u\",\"timestamp\":\"2026-04-01T10:00:00.000Z\",\"sessionId\":\"" sid "\"}\n"
    for (i = 1; i <= n; i++) {
      printf u, "\"step " i "\""
      for (j = 1; j <= 20; j++) {
        id = "toolu_" sid "_" i "_" j
        printf a, "msg_" sid "_" i "_" j, "{\"type\":\"tool_use\",\"id\":\"" id "\",\"name\":\"Read\",\"input\":{\"file_path\":\"/w/src/f" j ".js\"}}", "tool_use"
        printf u, "[{\"tool_use_id\":\"" id "\",\"type\":\"tool_result\",\"content\":\"line one of the file\"}]"
      }
      id = "toolu_" sid "_" i "_e"
      printf a, "msg_" sid "_" i "_e", "{\"type\":\"tool_use\",\"id\":\"" id "\",\"name\":\"Edit\",\"input\":{\"file_path\":\"/w/src/f1.js\",\"old_string\":\"a\",\"new_string\":\"b\"}}", "tool_use"
      printf u, "[{\"tool_use_id\":\"" id "\",\"type\":\"tool_result\",\"content\":\"ok\"}]"
      id = "toolu_" sid "_" i "_t"
      printf a, "msg_" sid "_" i "_t", "{\"type\":\"tool_use\",\"id\":\"" id "\",\"name\":\"Bash\",\"input\":{\"command\":\"npm test\"}}", "tool_use"
      printf u, "[{\"tool_use_id\":\"" id "\",\"type\":\"tool_result\",\"content\":\"done\",\"is_error\":" (i % 2 ? "false" : "true") "}]"
      printf a, "msg_" sid "_" i "_s", "{\"type\":\"text\",\"text\":\"Done.\"}", "end_turn"
    } }' > "$1"
}
# felix audit from the plain directory, with the stubs first on PATH, the
# scratch HOME, TMPDIR inside the scratch root, and nothing of Felix's in the
# environment. --home and --cfg choose HOME and CLAUDE_CONFIG_DIR (- unsets
# it). Stdout only; stderr is kept for the failure messages.
# --engine runs another felix the same way; only the wiring canary uses it.
_au() {
  local h="$AU/home" c="$AU/cfg" e="$AUF"
  while :; do
    case "${1:-}" in
      --home)   h="$2"; shift 2 ;;
      --cfg)    c="$2"; shift 2 ;;
      --engine) e="$2"; shift 2 ;;
      *) break ;;
    esac
  done
  ( cd "$AU/cwd" || exit 97
    unset FELIX_HOME FELIX_MEMORY FELIX_KERNEL FELIX_KERNEL_CACHE FELIX_PLUGIN_CACHE CLAUDE_PLUGIN_ROOT CLAUDE_CONFIG_DIR
    [ "$c" = "-" ] || export CLAUDE_CONFIG_DIR="$c"
    HOME="$h" TMPDIR="$AU/tmp" PATH="$AUSTUB:$PATH" "$e" audit "$@" ) 2>>"$AU_ERR"
}
# The CPU an audit cost, in ms, from a file `times` wrote inside the command
# substitution that ran it: that subshell's user time, then its children's,
# the audit among them, as 0m1.234s. It counts nothing else the suite has
# running, so load stretches the wall clock and leaves this alone.
#
# User time only, the first column of each line. The system time beside it is
# the kernel's, and on a Linux VM it was most of the total and no measure of
# the reader: over the 6 MB command, the one mawk reading it made 136,471
# mremap calls, and three runs on an idle machine took 0.8, 2.4 and 9.9 s of
# system time around 0.4 s of user time each. The copying these bounds exist
# to catch, a line copied once per escape, is user time.
_au_ms() {
  awk '{ split($1, t, "m"); sub(/s$/, "", t[2]); ms += (t[1] * 60 + t[2]) * 1000 }
       END { printf "%d", ms }' "$1"
}
# The report is plain text in a wording nobody fixed, so it is read loosely: a
# class is the line that names it and carries a percentage, its count the
# first bare number there, its share the first number with a % after it.
_au_strip() { printf '%s\n' "$1" | awk -v a="$AU" '{ while ((i = index($0, a)) > 0) $0 = substr($0, 1, i - 1) "AUROOT" substr($0, i + length(a)); print }'; }
# No reader here leaves before its input ends. Under pipefail an awk that
# exits on its first match can close the pipe while printf is still writing,
# and the SIGPIPE status, 141, then reads as "no match". Seen through
# _au_nums: correct reports failed that way in parallel runs, and a replica
# of it returned 141 in 34 of 3,200. _au_first had the same shape.
_au_first() { printf '%s\n' "$1" | awk 'NF && !d { print; d = 1 }'; }
_au_last()  { printf '%s\n' "$1" | awk 'NF { l = $0 } END { print l }'; }
_au_class() {  # text class -> "count pct", "-" where absent
  printf '%s\n' "$1" | awk -v w="$2" '
    { l = tolower($0) }
    l !~ /[0-9]+%/ { next }
    lead == "" && l ~ ("^[^a-z]*" w "([^a-z]|$)")  { lead = $0 }
    any  == "" && l ~ ("(^|[^a-z])" w "([^a-z]|$)") { any = $0 }
    END { s = (lead != "") ? lead : any; c = "-"; p = "-"
          while (s != "" && match(s, /[0-9]+%?/)) {
            t = substr(s, RSTART, RLENGTH); s = substr(s, RSTART + RLENGTH)
            if (t ~ /%$/) { if (p == "-") p = substr(t, 1, length(t) - 1) } else if (c == "-") c = t
          }
          print c, p }'
}
_au_counts() { local w r=""; for w in passed failed stale never; do r="$r $(_au_class "$(_au_strip "$1")" "$w" | cut -d' ' -f1)"; done; printf '%s' "${r# }"; }
_au_pcts()   { local w r=""; for w in passed failed stale never; do r="$r $(_au_class "$(_au_strip "$1")" "$w" | cut -d' ' -f2)"; done; printf '%s' "${r# }"; }
# True when one line without a % matches the pattern and holds these numbers,
# in this order, each as a whole run of digits.
_au_nums() {  # text ERE number...
  local t; t="$(_au_strip "$1")"; local re="$2"; shift 2
  printf '%s\n' "$t" | awk -v re="$re" -v want="$*" '
    f { next }
    { l = tolower($0) }
    index(l, "%") || l !~ re { next }
    { n = split(want, w, " "); k = 1; s = $0
      while (k <= n && match(s, /[0-9]+/)) { if (substr(s, RSTART, RLENGTH) == w[k]) k++; s = substr(s, RSTART + RLENGTH) }
      if (k > n) f = 1 }
    END { exit f ? 0 : 1 }'
}
_au_none() { printf '%s\n' "$1" | awk '{ l = tolower($0) }
  l ~ /(^|[^a-z])no([^a-z]|$).*transcript/ || l ~ /transcript.*(none|not found)/ || l ~ /(^|[^0-9])0 (transcripts|sessions)/ { f = 1 }
  END { exit f ? 0 : 1 }'; }
_au_snap() { ( cd "$1" && find . -print | LC_ALL=C sort && find . -type f -exec cksum {} + | LC_ALL=C sort ) 2>&1; }

# _au_build: the scratch root AU with the engine copy, the stubs, the main fixture of
# seven sessions, its copies under home2 and solo, and the two big sessions. Sets AU
# AUD AUF AUSTUB AUSTUB_LOG AU_ERR and AU_SA to AU_SG; the guard is the last file made.
_au_build() {
AU="$TMP/audit"; mkdir -p "$AU"; AU="$(cd "$AU" && pwd -P)"
AUD="$AU/cfg/projects"
AUF="$AU/clone/felix/engine/harness/felix"
AUSTUB="$TMP/audit-stub"; AUSTUB_LOG="$TMP/audit-stub.log"
AU_ERR="$TMP/audit.err"
AU_SA=aaaa1111-0000-4000-8000-00000000000a; AU_SB=bbbb2222-0000-4000-8000-00000000000b
AU_SC=cccc3333-0000-4000-8000-00000000000c; AU_SD=dddd4444-0000-4000-8000-00000000000d
AU_SE=eeee5555-0000-4000-8000-00000000000e; AU_SF=ffff6666-0000-4000-8000-00000000000f
AU_SG=abcd7777-0000-4000-8000-000000000007
[ -s "$AU/big/-Users-dev-big/big-two.jsonl" ] && return 0

# Everything the audit may see or touch lives under one scratch root, which is
# listed and checksummed before the first run and after the last. The engine it
# runs is a plain copy of this one, laid out the way a clone lays it out, with
# no install, no ~/.felix-home, no FELIX_HOME and no memory root.
mkdir -p "$AU/home" "$AU/cwd" "$AU/tmp" "$AU/empty" "$AU/clone/felix/engine" "$AUD"
printf 'export PS1=x\n' > "$AU/home/.profile"
_copy_content "$REAL_HARNESS" "$AU/clone/felix/engine/harness"

# Everything that could reach the network or the claude CLI, recording any call.
mkdir -p "$AUSTUB"; : > "$AUSTUB_LOG"
for _c in claude gh curl wget; do
  printf '#!/bin/sh\nprintf "%%s %%s\\n" "%s" "$*" >> "%s"\nexit 0\n' "$_c" "$AUSTUB_LOG" > "$AUSTUB/$_c"
  chmod +x "$AUSTUB/$_c"
done
# The main fixture: seven sessions in two project directories, holding ten
# stops after edits — 4 passed, 1 failed, 2 stale, 3 never — in six of them,
# and four Felix holds in three. Every awkward case below would change one of
# those numbers if it were read the wrong way.

# A: passed, failed, stale; two holds. A thinking block and an edit share one
# message id; a sidechain edit after the passing check would make the first
# stop stale if it were read; the first stop is logged on two lines; the check
# before the second stop has an escaped quote ahead of the command that makes
# it a check, and its failure arrives with is_error before tool_use_id.
_au_open "$AUD/-Users-dev-alpha/$AU_SA.jsonl" "$AU_SA"
_au_raw '{"type":"summary","summary":"Fixing the parser","leafUuid":"u-last"}'
T=2026-03-02T10:00
_au_say  "$T:00.000Z" 'fix the parser'
_au_a    "$T:01.000Z" msg_A1 '"tool_use"' '{"type":"thinking","thinking":"Look first.","signature":"sig"}'
_au_edit "$T:01.500Z" msg_A1 toolu_A1
_au_res  "$T:02.000Z" toolu_A1 ok
_au_bash "$T:03.000Z" msg_A2 toolu_A2 'npm test' 'Run the tests'
_au_res  "$T:04.000Z" toolu_A2 false
_au_edit "$T:05.000Z" msg_SC1 toolu_SC1 Edit true
_au_res  "$T:05.500Z" toolu_SC1 ok true
_au_stop "$T:05.800Z" msg_SC2 'Subtask done.' true
_au_stop "$T:06.000Z" msg_A3 'Fixed.'
_au_stop "$T:06.000Z" msg_A3 'The tests pass.'
T=2026-03-02T10:10
_au_say  "$T:00.000Z" 'also handle unicode'
_au_edit "$T:01.000Z" msg_A4 toolu_A4 Write
_au_res  "$T:02.000Z" toolu_A4 ok
_au_bash "$T:03.000Z" msg_A5 toolu_A5 'cd \"/w/my dir\" && npx vitest run' 'Run vitest where the path has a space'
_au_res  "$T:04.000Z" toolu_A5 true-first
_au_stop "$T:05.000Z" msg_A6 'One test still fails.'
_au_hold "$T:06.000Z" 'Stop hook feedback:\nThe gate failed on this exact tree. It has not passed since the last edit.\n\n  felix gate'
T=2026-03-02T10:20
_au_edit "$T:01.000Z" msg_A7 toolu_A7
_au_res  "$T:02.000Z" toolu_A7 ok
_au_stop "$T:03.000Z" msg_A8 'Adjusted the test.'
_au_hold "$T:04.000Z" 'Stop hook feedback:\nThe gate last ran at 2026-03-02T10:00:00Z, on a different tree. It has not seen this work.'
_au_bash "$T:05.000Z" msg_A9 toolu_A9 'felix gate' 'Run the gate'
_au_res  "$T:06.000Z" toolu_A9 ok
_au_stop "$T:07.000Z" msg_A10 'The gate is green.'

# B: never, then passed; one hold. The first Bash call names npm test in its
# description and not its command. The last check runs beside a parallel call
# in the same message whose error arrives first.
_au_open "$AUD/-Users-dev-alpha/$AU_SB.jsonl" "$AU_SB"
T=2026-03-03T09:00
_au_say  "$T:00.000Z" 'tidy the notebook'
_au_bash "$T:01.000Z" msg_B1 toolu_B1 'git status' 'Check the tree before npm test'
_au_res  "$T:02.000Z" toolu_B1 ok
_au_edit "$T:03.000Z" msg_B2 toolu_B2 MultiEdit
_au_res  "$T:04.000Z" toolu_B2 ok
_au_stop "$T:05.000Z" msg_B3 'Tidied.'
_au_hold "$T:06.000Z" 'Stop hook feedback:\nThe gate has never run on this checkout.\n\n  felix gate'
_au_hold "$T:06.500Z" 'Stop hook feedback:\nRemember to update the changelog.'
_au_edit "$T:07.000Z" msg_B4 toolu_B4 NotebookEdit
_au_res  "$T:08.000Z" toolu_B4 ok
_au_bash "$T:09.000Z" msg_B5 toolu_B5 'python -m pytest tests/ -q' 'Run the tests'
_au_bash "$T:09.100Z" msg_B5 toolu_B5b 'ls /nonexistent' 'Look for the fixture'
_au_res  "$T:10.000Z" toolu_B5b true
_au_res  "$T:10.500Z" toolu_B5 ok
_au_stop "$T:11.000Z" msg_B6 'Done.'

# C: passed, passed; one hold. A failing command that is not a check follows
# the passing one, and the first stop is logged again, whole, after the next
# edit: a replayed message is not a second stop.
_au_open "$AUD/-Users-dev-beta/$AU_SC.jsonl" "$AU_SC"
T=2026-03-05T12:00
_au_say  "$T:00.000Z" 'port the build to cargo'
_au_edit "$T:01.000Z" msg_C1 toolu_C1
_au_res  "$T:02.000Z" toolu_C1 ok
_au_bash "$T:03.000Z" msg_C2 toolu_C2 'cargo test' 'Run the tests'
_au_res  "$T:04.000Z" toolu_C2 true
_au_edit "$T:05.000Z" msg_C3 toolu_C3
_au_res  "$T:06.000Z" toolu_C3 ok
_au_bash "$T:07.000Z" msg_C4 toolu_C4 'make check' 'Run the checks'
_au_res  "$T:08.000Z" toolu_C4 false
_au_bash "$T:09.000Z" msg_C4b toolu_C4b 'git diff --stat' 'See what changed'
_au_res  "$T:10.000Z" toolu_C4b true
_au_stop "$T:11.000Z" msg_C5 'Ported.'
_au_hold "$T:12.000Z" 'Stop hook feedback:\nThe gate passed on this exact tree at 2026-03-05T12:00:08Z, and the tree has changed since.'
_au_edit "$T:13.000Z" msg_C6 toolu_C6
_au_res  "$T:14.000Z" toolu_C6 ok
_au_stop "$T:11.000Z" msg_C5 'Ported.'
_au_bash "$T:15.000Z" msg_C7 toolu_C7 'go test ./...' 'Run the Go tests'
_au_res  "$T:16.000Z" toolu_C7 ok
_au_stop "$T:17.000Z" msg_C8 'Done.'

# D: never; no hold. A session-start attachment quotes a hold, a person quotes
# one mid-sentence, and a sidechain carries a real one. Its subagent files,
# marked NOT sidechain so only the path can exclude them, hold a failing check,
# a stop and a hold that would all change the answer if they were read.
_au_open "$AUD/-Users-dev-beta/$AU_SD.jsonl" "$AU_SD"
T=2026-03-06T09:00
_au_raw  "{\"parentUuid\":null,\"isSidechain\":false,\"attachment\":{\"type\":\"hook_success\",\"hookName\":\"SessionStart:startup\",\"content\":\"\",\"stdout\":\"- Stop hook feedback: The gate last ran at 2026-02-11T00:00:00Z, on a different tree.\"},\"type\":\"attachment\",\"uuid\":\"u-d0\",\"timestamp\":\"$T:00.000Z\",\"sessionId\":\"$AU_SD\"}"
_au_say  "$T:01.000Z" 'I saw Stop hook feedback: The gate last ran at 2026-02-11T00:00:00Z. Why?'
_au_hold "$T:02.000Z" 'Stop hook feedback:\nThe gate last ran at 2026-03-06T08:00:00Z, on a different tree.' true
_au_edit "$T:03.000Z" msg_D1 toolu_D1
_au_res  "$T:04.000Z" toolu_D1 ok
_au_stop "$T:05.000Z" msg_D2 'Answered, and fixed a typo.'
_au_open "$AUD/-Users-dev-beta/$AU_SD/subagents/agent-a1b2c3.jsonl" "$AU_SD"
T=2026-03-06T09:10
_au_edit "$T:01.000Z" msg_S1 toolu_S1
_au_res  "$T:02.000Z" toolu_S1 ok
_au_bash "$T:03.000Z" msg_S2 toolu_S2 'npm test' 'Run the tests'
_au_res  "$T:04.000Z" toolu_S2 true
_au_stop "$T:05.000Z" msg_S3 'Subtask done.'
_au_hold "$T:06.000Z" 'Stop hook feedback:\nThe gate failed on this exact tree.'
_au_open "$AUD/-Users-dev-beta/$AU_SD/subagents/workflows/wf_1/agent-d4e5f6.jsonl" "$AU_SD"
_au_edit "$T:07.000Z" msg_S4 toolu_S4
_au_res  "$T:08.000Z" toolu_S4 ok
_au_stop "$T:09.000Z" msg_S5 'Workflow step done.'

# E: edits, a check, more edits, and no stop: interrupted, stop_reason null.
_au_open "$AUD/-Users-dev-beta/$AU_SE.jsonl" "$AU_SE"
T=2026-03-07T15:00
_au_say  "$T:00.000Z" 'start the migration'
_au_edit "$T:01.000Z" msg_E1 toolu_E1
_au_res  "$T:02.000Z" toolu_E1 ok
_au_bash "$T:03.000Z" msg_E2 toolu_E2 'npm run verify' 'Verify'
_au_res  "$T:04.000Z" toolu_E2 ok
_au_edit "$T:05.000Z" msg_E3 toolu_E3
_au_res  "$T:06.000Z" toolu_E3 ok
_au_text 'Still going...'; _au_a "$T:07.000Z" msg_E4 null "$_AU_B"

# F: never by default, passed under --verify 'prove\.sh'.
_au_open "$AUD/-Users-dev-alpha/$AU_SF.jsonl" "$AU_SF"
T=2026-03-09T18:00
_au_say  "$T:00.000Z" 'make the proof script pass'
_au_bash "$T:01.000Z" msg_F1 toolu_F1 './scripts/prove.sh --quick' 'Run the proof'
_au_res  "$T:02.000Z" toolu_F1 ok
_au_edit "$T:03.000Z" msg_F2 toolu_F2
_au_res  "$T:04.000Z" toolu_F2 ok
_au_bash "$T:05.000Z" msg_F3 toolu_F3 './scripts/prove.sh' 'Run the proof'
_au_res  "$T:06.000Z" toolu_F3 ok
_au_stop "$T:07.000Z" msg_F4 'Proved.'

# G: stale — its only check is four days before its only edit. A --since
# between them counts the stop after the edit, and it is still stale: the
# check before the cutoff still ran in the session.
_au_open "$AUD/-Users-dev-beta/$AU_SG.jsonl" "$AU_SG"
_au_say  2026-03-04T12:00:00.000Z 'run the suite'
_au_bash 2026-03-04T12:00:01.000Z msg_G1 toolu_G1 'pnpm test' 'Run the tests'
_au_res  2026-03-04T12:00:02.000Z toolu_G1 ok
_au_stop 2026-03-04T12:00:03.000Z msg_G2 'All green.'
_au_say  2026-03-08T12:00:00.000Z 'now rename the helper'
_au_edit 2026-03-08T12:00:01.000Z msg_G3 toolu_G3
_au_res  2026-03-08T12:00:02.000Z toolu_G3 ok
_au_stop 2026-03-08T12:00:03.000Z msg_G4 'Renamed.'

# And one transcript beside the project directories rather than in one: not
# DIR/*/*.jsonl, so not read. Read, it would add a never and move the range.
_au_open "$AUD/stray.jsonl" stray-0000
_au_edit 2026-03-12T08:00:01.000Z msg_X1 toolu_X1
_au_stop 2026-03-12T08:00:02.000Z msg_X2 'Stray.'

# The same fixture where the defaults look for it, and single sessions alone.
mkdir -p "$AU/home2/.claude"; cp -R "$AUD" "$AU/home2/.claude/projects"
for _s in a b c d; do mkdir -p "$AU/solo/$_s/-Users-dev-solo"; done
cp "$AUD/-Users-dev-alpha/$AU_SA.jsonl" "$AU/solo/a/-Users-dev-solo/"
cp "$AUD/-Users-dev-alpha/$AU_SB.jsonl" "$AU/solo/b/-Users-dev-solo/"
cp "$AUD/-Users-dev-beta/$AU_SC.jsonl"  "$AU/solo/c/-Users-dev-solo/"
cp "$AUD/-Users-dev-beta/$AU_SD.jsonl"  "$AU/solo/d/-Users-dev-solo/"
cp -R "$AUD/-Users-dev-beta/$AU_SD"     "$AU/solo/d/-Users-dev-solo/"

mkdir -p "$AU/big/-Users-dev-big"
_au_big "$AU/big/-Users-dev-big/big-one.jsonl" bigone 450
_au_big "$AU/big/-Users-dev-big/big-two.jsonl" bigtwo 450
: > "$AU_ERR"
}

# _au_resume: the state 0810 leaves for 0850: the snapshots of AU and its HOME taken
# before the first run, and the first run's read-only verdict. In the serial run the
# first call, 0810's, makes them and any later call finds them made.
_au_resume() {
  [ -n "${_au_report:-}" ] && return 0
_au_before="$(_au_snap "$AU")"; _au_home_before="$(_au_snap "$AU/home")"
_auo="$(_au --dir "$AUD")"; _aurc=$?
_au_report=0
[ "$_aurc" -eq 0 ] && _au_first "$_auo" | grep -qiE 'read[- ]only' && _au_report=1
}
