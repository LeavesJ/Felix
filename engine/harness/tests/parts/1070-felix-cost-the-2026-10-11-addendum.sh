_fc_init
_fc_fixture r1 r6 r11 rE rN
# ======================================================================
# Addendum 2026-10-11, written blind: the ten items the contract gained after
# the adversarial review, and the amended "every *.jsonl under subagents/".
# Written from the contract's addendum alone, with the command unread, by an
# author who had not written the first blind round. Where the addendum leaves
# a thing open nothing here asserts on it: how many files a directory loop
# makes unread, what a reason says inside its parentheses, which record
# directory a repeated id is attributed to, a link's own modification time
# against its target's, a response with no timestamp key at all, and whether a
# floor of zero responses reads unknown. Every fixture is a records root
# $FC/fa..., the numbers are exact, and the arithmetic sits beside each.
# ======================================================================
printf '\nfelix cost: the 2026-10-11 addendum\n'

FCAROOT=0; [ "$(id -u)" = 0 ] && FCAROOT=1
# is / has, skipped when this user is root or the machine ignores the mode bits.
_fcad()  { if [ "$FCAROOT" = 0 ] && [ "$FCCANDENY" = 1 ]; then is  "$1" "$2" "$3"; else skip "$1" "a missing read permission does not stop this user"; fi; }
_fcadh() { if [ "$FCAROOT" = 0 ] && [ "$FCCANDENY" = 1 ]; then has "$1" "$2" "$3"; else skip "$1" "a missing read permission does not stop this user"; fi; }

# A response line as Claude Code writes it: the message, then any
# wireToolInputs, then requestId, and last the line's own type, uuid and
# timestamp. _fca_resp ID TS MODEL USAGE-JSON [CONTENT-JSON [WIRE-JSON]]
_fca_resp() {
  local c="${5:-$FC_CONTENT}" w=""
  if [ -n "${6:-}" ]; then w="\"wireToolInputs\":$6,"; fi
  FCSEQ=$((FCSEQ+1))
  printf '{"parentUuid":null,"isSidechain":false,"message":{"model":"%s","id":"%s","type":"message","role":"assistant","content":%s,"stop_reason":null,"usage":%s},%s"requestId":"req_%s","type":"assistant","uuid":"u-%s","timestamp":"%s","sessionId":"s1"}\n' \
    "$3" "$1" "$c" "$4" "$w" "$FCSEQ" "$FCSEQ" "$2"
}
# The cover keys of the last --tsv run, in the order they were printed.
_fca_cover_keys() { awk -F'\t' '$1 == "cover" { printf "%s%s", s, $2; s = " " }' "$FCOUTF"; }
# The first text-view line that begins with responses (the contract says "beginning", so a prefix), blanks collapsed.
_fca_resp_line() {
  awk '$0 ~ /^[ \t]*responses/ { s = $0; gsub(/[ \t]+/, " ", s); sub(/^ /, "", s); print s; exit }' "$FCOUTF"
}
# A total row's tokens, its percent, and its calls, apart.
_fca_tot() { _fc_row total all | awk -F'\t' -v c="$1" '{ print $c }'; }

# ----------------------------------------------------------------------
# Item 1. Links are followed: the root, a record directory, a transcript. A
# dangling link named *.jsonl, and a link loop, are unread.
# ----------------------------------------------------------------------
# The records root is a symbolic link (a relative one): fa1r/projects -> ../fa1rreal.
rm -rf "$FC/fa1r" "$FC/fa1rreal"; mkdir -p "$FC/fa1r"
_fc_in "$FC/fa1rreal/-Users-dev-rl/s1.jsonl"             msg_LK1 "$FCT0" m-lkroot  1000
_fc_in "$FC/fa1rreal/-Users-dev-rl/s1/subagents/a.jsonl" msg_LK2 "$FCT0" m-lkroot2 2000
ln -s ../fa1rreal "$FC/fa1r/projects"
FCCFG="$FC/fa1r" _fc --tsv
# 1000 + 2000 = 3000 over two calls, 0.0 percent of the 905M cap.
is  "felix cost follows a records root that is a symbolic link: its transcript and its helper agent's are read, 3000 over two calls" \
    "$(_fc_row total all)" "$(_fc_exps total all 3000.00 0.0 2)"
is  "felix cost follows a records root that is a symbolic link: both files read, none unread, coverage measured" \
    "$(_fc_cover files_read) $(_fc_cover files_unread) $(_fc_cover coverage)" "2 0 measured"
is  "felix cost follows a records root that is a symbolic link: the worktree row is the record directory under the link" \
    "$(_fc_row worktree -Users-dev-rl)" "$(_fc_exps worktree -Users-dev-rl 3000.00 0.0 2)"

# A record directory that is a link to a directory elsewhere, beside a real one.
_fc_mk fa1d; rm -rf "$FC/fa1dext"
_fc_in "$FC/fa1dext/real-target/s1.jsonl"                msg_LK3 "$FCT0" m-lkdir  4000
_fc_in "$FC/fa1dext/real-target/s1/subagents/h.jsonl"    msg_LK4 "$FCT0" m-lkdir2 8000
_fc_in "$FC/fa1d/projects/-Users-dev-real/s1.jsonl"      msg_LK5 "$FCT0" m-lkreal 16000
ln -s "$FC/fa1dext/real-target" "$FC/fa1d/projects/-Users-dev-linked"
FCCFG="$FC/fa1d" _fc --tsv
# linked: 4000 + 8000 = 12000 over two calls (its helper agent's file is read through the link too); real: 16000.
is  "felix cost follows a record directory that is a link: its session file and its helper agent's file count, 28000 over three calls" \
    "$(_fc_row total all)" "$(_fc_exps total all 28000.00 0.0 3)"
is  "felix cost follows a record directory that is a link: the worktree rows are the link's name and the real directory's, largest first" \
    "$(_fc_rows worktree)" "$(_fc_exps worktree -Users-dev-real 16000.00 0.0 1 -Users-dev-linked 12000.00 0.0 2)"
is  "felix cost follows a record directory that is a link: three files read, none unread" \
    "$(_fc_cover files_read) $(_fc_cover files_unread) $(_fc_cover coverage)" "3 0 measured"

# A transcript that is a link to a file outside the root, in a record directory and in subagents/.
_fc_mk fa1t; rm -rf "$FC/fa1text"; mkdir -p "$FC/fa1text" "$FC/fa1t/projects/-Users-dev-tl/s1/subagents"
_fc_in "$FC/fa1text/outside.jsonl" msg_LK6 "$FCT0" m-lkfile 32000
_fc_in "$FC/fa1text/helper.jsonl"  msg_LK8 "$FCT0" m-lkhelp 128000
_fc_in "$FC/fa1t/projects/-Users-dev-tl/real.jsonl" msg_LK7 "$FCT0" m-lkreal2 64000
ln -s "$FC/fa1text/outside.jsonl" "$FC/fa1t/projects/-Users-dev-tl/linked.jsonl"
ln -s "$FC/fa1text/helper.jsonl"  "$FC/fa1t/projects/-Users-dev-tl/s1/subagents/h.jsonl"
FCCFG="$FC/fa1t" _fc --tsv
# 32000 + 64000 + 128000 = 224000 over three calls.
is  "felix cost reads a transcript that is a link, in the record directory and in subagents/: 224000 over three calls" \
    "$(_fc_row total all)" "$(_fc_exps total all 224000.00 0.0 3)"
is  "felix cost reads a transcript that is a link as a file read, none unread" \
    "$(_fc_cover files_read) $(_fc_cover files_unread) $(_fc_cover coverage)" "3 0 measured"

# A dangling link named *.jsonl where a transcript is read: unread, so a floor.
_fc_mk fa1x
_fc_in "$FC/fa1x/projects/-Users-dev-dg/ok.jsonl" msg_LK9 "$FCT0" m-dgok 1000
ln -s "$FC/fa1x/no-such-file.jsonl" "$FC/fa1x/projects/-Users-dev-dg/dangling.jsonl"
FCCFG="$FC/fa1x" _fc --tsv
is  "felix cost counts a dangling link named *.jsonl in a record directory as one unread file, and the total is a floor of the readable 1000" \
    "$(_fc_row total all)|$(_fc_cover files_read) $(_fc_cover files_unread) $(_fc_cover coverage)" \
    "$(_fc_exps total all 1000.00 0.0 1)|1 1 floor"
FCCFG="$FC/fa1x" _fc
FCA_TL="$(_fc_line total)"; FCA_FL="$(_fc_line files)"
has "felix cost (text): a dangling link makes the total line read at least" "$FCA_TL" "at least"
has "felix cost (text): a dangling link makes the files line say 1 could not be read" "$FCA_FL" "1 could not be read"
has "felix cost (text): a dangling link makes the files line say floor" "$FCA_FL" "floor"

_fc_mk fa1y
_fc_in "$FC/fa1y/projects/-Users-dev-dg/ok.jsonl" msg_LK11 "$FCT0" m-dgok2 2000
mkdir -p "$FC/fa1y/projects/-Users-dev-dg/s1/subagents"
ln -s "$FC/fa1y/no-such-helper.jsonl" "$FC/fa1y/projects/-Users-dev-dg/s1/subagents/dangling.jsonl"
FCCFG="$FC/fa1y" _fc --tsv
is  "felix cost counts a dangling link named *.jsonl under subagents/ as one unread file, and the total is a floor of the readable 2000" \
    "$(_fc_row total all)|$(_fc_cover files_read) $(_fc_cover files_unread) $(_fc_cover coverage)" \
    "$(_fc_exps total all 2000.00 0.0 1)|1 1 floor"

# Nothing readable but a dangling link: the floor is 0, so the total reads unknown, never 0.
_fc_mk fa1z
mkdir -p "$FC/fa1z/projects/-Users-dev-dg"
ln -s "$FC/fa1z/gone.jsonl" "$FC/fa1z/projects/-Users-dev-dg/dangling.jsonl"
FCCFG="$FC/fa1z" _fc --tsv
is  "felix cost: a root whose only transcript is a dangling link is one unread file, a floor of 0, so the total reads unknown" \
    "$(_fc_row total all)|$(_fc_cover coverage) $(_fc_cover files_unread)|$(_fc_kinds)" \
    "$(printf 'total\tall\tunknown\tunknown\tunknown')|unknown 1|cover total"

# A link loop: a transcript name that is a link to itself.
_fc_mk fa1l
_fc_in "$FC/fa1l/projects/-Users-dev-lp/ok.jsonl" msg_LK10 "$FCT0" m-lpok 4000
ln -s loop.jsonl "$FC/fa1l/projects/-Users-dev-lp/loop.jsonl"
FCCFG="$FC/fa1l" _fc --tsv
is  "felix cost counts a transcript name that is a link loop as one unread file, and the total is a floor of the readable 4000" \
    "$(_fc_row total all)|$(_fc_cover files_read) $(_fc_cover files_unread) $(_fc_cover coverage)" \
    "$(_fc_exps total all 4000.00 0.0 1)|1 1 floor"
# A directory link under subagents/ that points back at its own parent. Whether the addendum makes that
# loop unread is not said, so only this is asserted: the run ends, with a report, the one response once.
_fc_mk fa1p
_fc_in "$FC/fa1p/projects/-Users-dev-dl/s1/subagents/ok.jsonl" msg_LK12 "$FCT0" m-dlok 8000
ln -s .. "$FC/fa1p/projects/-Users-dev-dl/s1/subagents/up"
FCARC="$( ( ulimit -t 60; FCCFG="$FC/fa1p" _fc --tsv; printf '%s' "$FCRC" ) )"
FCRC="$FCARC"; FCOUT="$(cat "$FCOUTF")"
is  "felix cost ends with a report when a directory link under subagents/ loops back to its parent, and counts the response in it once: 8000" \
    "$FCRC $(_fca_tot 3) $(_fca_tot 5)" "0 8000.00 1"

# ----------------------------------------------------------------------
# Item 2. A response's own type and time are the LAST type/uuid/timestamp
# triple in its line, so a triple quoted in the content or in
# wireToolInputs changes nothing, and a record whose own triple is not
# an assistant's is not counted however it nests one.
# ----------------------------------------------------------------------
_fc_mk fa2a
FCA_F="$FC/fa2a/projects/-Users-dev-last/s1.jsonl"; mkdir -p "$(dirname "$FCA_F")"
# 700: a tool_use input quotes a triple of type user dated 2020; the line's own, last, triple is assistant at FCT0: it counts, on 2026-10-09.
_fca_resp msg_TR1 "$FCT0" m-ct1 "$(_fc_use 700 0 0 0 0)" \
  '[{"type":"tool_use","id":"toolu_1","name":"Write","input":{"type":"user","uuid":"fake-1","timestamp":"2020-01-01T00:00:00.000Z"}}]' > "$FCA_F"
# 900: its own last triple is dated before the window; the content quotes an assistant triple dated inside it: it does not count.
_fca_resp msg_TR2 2026-10-01T00:00:00.000Z m-ct2 "$(_fc_use 900 0 0 0 0)" \
  '[{"type":"tool_use","id":"toolu_2","name":"Write","input":{"type":"assistant","uuid":"fake-2","timestamp":"2026-10-09T10:00:00.000Z"}}]' >> "$FCA_F"
# 1100: the content quotes a progress triple dated 2020 and an attachment one; own is assistant at FCT0: counts.
_fca_resp msg_TR5 "$FCT0" m-ct3 "$(_fc_use 1100 0 0 0 0)" \
  '[{"type":"text","text":"x"},{"type":"tool_use","id":"toolu_5","name":"Edit","input":{"type":"progress","uuid":"a","timestamp":"2020-01-01T00:00:00.000Z","old":{"type":"attachment","uuid":"b","timestamp":"2020-01-02T00:00:00.000Z"}}}]' >> "$FCA_F"
FCCFG="$FC/fa2a" _fc --tsv
is  "felix cost: a triple of type user quoted in a tool_use input does not change the response's own type or time: it counts" \
    "$(_fc_row model m-ct1)" "$(_fc_exps model m-ct1 700.00 0.0 1)"
is  "felix cost: a quoted triple dated 2020 does not move the response off its own day, 2026-10-09" \
    "$(_fc_rows day | awk -F'\t' '{ printf "%s%s=%s", s, $2, $3; s = " " }')" "2026-10-09=1800.00"
is  "felix cost: a quoted assistant triple dated inside the window does not bring in a response whose own last triple is dated before it" \
    "$(_fc_absent model m-ct2)" "absent"
is  "felix cost: two quoted triples, a progress and an attachment, leave a response of its own type assistant counted: 1100" \
    "$(_fc_row model m-ct3)" "$(_fc_exps model m-ct3 1100.00 0.0 1)"
is  "felix cost: quoted triples in the content leave the total at the two responses that count, 1800 over two calls" \
    "$(_fc_row total all)" "$(_fc_exps total all 1800.00 0.0 2)"
is  "felix cost: quoted triples in the content leave the report measured, with no response unread" \
    "$(_fc_cover coverage) $(_fc_cover responses_unread)" "measured 0"

_fc_mk fa2b
FCA_F="$FC/fa2b/projects/-Users-dev-wire/s1.jsonl"; mkdir -p "$(dirname "$FCA_F")"
# 800: wireToolInputs sits between the message and the real triple and quotes a user triple dated 2020: it counts, at FCT0.
_fca_resp msg_TR3 "$FCT0" m-wr1 "$(_fc_use 800 0 0 0 0)" \
  '[{"type":"tool_use","id":"toolu_1","name":"Write","input":{"file_path":"/tmp/x.json"}}]' \
  '{"toolu_1":{"file_path":"/tmp/x.json","content":{"type":"user","uuid":"fake-3","timestamp":"2020-01-01T00:00:00.000Z"}}}' > "$FCA_F"
# 1600: the real triple is dated before the window; wireToolInputs quotes an assistant one dated inside it: it does not count.
_fca_resp msg_TR4 2026-10-01T00:00:00.000Z m-wr2 "$(_fc_use 1600 0 0 0 0)" \
  '[{"type":"tool_use","id":"toolu_2","name":"Write","input":{"file_path":"/tmp/y.json"}}]' \
  '{"toolu_2":{"file_path":"/tmp/y.json","content":{"type":"assistant","uuid":"fake-4","timestamp":"2026-10-09T10:00:00.000Z"}}}' >> "$FCA_F"
# 3200: a plain wireToolInputs with no triple in it, one more kind of line that must still count.
_fca_resp msg_TR6 "$FCT0" m-wr3 "$(_fc_use 3200 0 0 0 0)" \
  '[{"type":"tool_use","id":"toolu_6","name":"Bash","input":{"command":"ls"}}]' '{"toolu_6":{"command":"ls"}}' >> "$FCA_F"
FCCFG="$FC/fa2b" _fc --tsv
is  "felix cost: a user triple quoted in wireToolInputs, between the message and the real triple, does not change a response's type or time" \
    "$(_fc_row model m-wr1)" "$(_fc_exps model m-wr1 800.00 0.0 1)"
is  "felix cost: an assistant triple dated inside the window quoted in wireToolInputs does not bring in a response dated before it" \
    "$(_fc_absent model m-wr2)" "absent"
is  "felix cost: a response with a wireToolInputs that quotes nothing counts: 3200" \
    "$(_fc_row model m-wr3)" "$(_fc_exps model m-wr3 3200.00 0.0 1)"
is  "felix cost: the wireToolInputs lines total 4000 over two calls" \
    "$(_fc_row total all)" "$(_fc_exps total all 4000.00 0.0 2)"
is  "felix cost: quoted triples in wireToolInputs leave the report measured, with no response unread" \
    "$(_fc_cover coverage) $(_fc_cover responses_unread)" "measured 0"

# A record that nests a whole assistant record, with its own type, uuid and timestamp AFTER it. Each nested
# message carries 1000000 input tokens, so a count would show; each is dated inside the window.
_fc_mk fa2c
FCA_F="$FC/fa2c/projects/-Users-dev-nest/s1.jsonl"; mkdir -p "$(dirname "$FCA_F")"
FCAU='{"input_tokens":1000000,"output_tokens":0}'
_fca_resp msg_NS0 "$FCT0" m-nctl "$(_fc_use 500 0 0 0 0)" > "$FCA_F"
printf '{"parentUuid":"u-0","isSidechain":false,"data":{"message":%s,"type":"agent_progress"},"toolUseID":"toolu_p1","parentToolUseID":"toolu_p0","type":"progress","uuid":"u-p1","timestamp":"%s","sessionId":"s1"}\n' \
  "$(_fc_rec msg_NS1 "$FCT0" m-nprog "$FCAU")" "$FCT0" >> "$FCA_F"
printf '{"parentUuid":"u-0","isSidechain":false,"message":{"role":"user","content":[{"tool_use_id":"toolu_u1","type":"tool_result","content":"done"}]},"toolUseResult":{"agentId":"a1","message":%s},"type":"user","uuid":"u-q1","timestamp":"%s","sessionId":"s1"}\n' \
  "$(_fc_rec msg_NS2 "$FCT0" m-nuser "$FCAU")" "$FCT0" >> "$FCA_F"
printf '{"parentUuid":"u-0","isSidechain":false,"attachment":{"type":"hook_success","message":%s},"type":"attachment","uuid":"u-a1","timestamp":"%s","sessionId":"s1"}\n' \
  "$(_fc_rec msg_NS3 "$FCT0" m-nattach "$FCAU")" "$FCT0" >> "$FCA_F"
printf '{"parentUuid":"u-0","isSidechain":false,"subtype":"stop_hook_summary","data":{"message":%s},"type":"system","uuid":"u-s1","timestamp":"%s","sessionId":"s1"}\n' \
  "$(_fc_rec msg_NS4 "$FCT0" m-nsystem "$FCAU")" "$FCT0" >> "$FCA_F"
FCCFG="$FC/fa2c" _fc --tsv
is  "felix cost does not count a progress record that nests an assistant record, even when its own type comes after the nested message" \
    "$(_fc_absent model m-nprog)" "absent"
is  "felix cost does not count a user record that nests an assistant record in a toolUseResult, its own type coming after it" \
    "$(_fc_absent model m-nuser)" "absent"
is  "felix cost does not count an attachment record that nests an assistant record, its own type coming after it" \
    "$(_fc_absent model m-nattach)" "absent"
is  "felix cost does not count a system record that nests an assistant record, its own type coming after it" \
    "$(_fc_absent model m-nsystem)" "absent"
is  "felix cost: of the five lines only the plain response counts, 500 over one call" \
    "$(_fc_row total all)" "$(_fc_exps total all 500.00 0.0 1)"
is  "felix cost: records that nest an assistant record are not counted and not read as unreadable responses: measured, responses_unread 0" \
    "$(_fc_cover coverage) $(_fc_cover responses_unread)" "measured 0"

# ----------------------------------------------------------------------
# Item 3. A usage it cannot place is not weighed: it counts in
# responses_unread and the total is a floor. A response whose time cannot be
# read counts there too.
# ----------------------------------------------------------------------
# One readable response (1000) and the response it cannot place, per root.
_fca_floor3() {   # STEM BAD-MODEL: the rows after the run that was just made
  is  "$1: the response is counted in responses_unread" "$(_fc_cover responses_unread)" "1"
  is  "$1: the total is a floor" "$(_fc_cover coverage)" "floor"
  is  "$1: nothing of it is weighed: the total is the readable 1000 and 0.0 percent" \
      "$(_fca_tot 3) $(_fca_tot 4)" "1000.00 0.0"
  is  "$1: it is not a call: the total counts 1 call" "$(_fca_tot 5)" "1"
  is  "$1: it has no model row" "$(_fc_absent model "$2")" "absent"
  is  "$1: the report is still made, exit 0, with every other file read and none unread" \
      "$FCRC $(_fc_cover files_read) $(_fc_cover files_unread)" "0 1 0"
}
# (a) a tool_use input in the content with an object-valued usage key: a second "usage":{ after the message.
_fc_mk fa3a
FCA_F="$FC/fa3a/projects/-Users-dev-three/s1.jsonl"; mkdir -p "$(dirname "$FCA_F")"
_fca_resp msg_UR1 "$FCT0" m-good3 "$(_fc_use 1000 0 0 0 0)" > "$FCA_F"
_fca_resp msg_UR2 "$FCT0" m-two "$(_fc_use 7000 0 0 0 0)" \
  '[{"type":"tool_use","id":"toolu_3","name":"Run","input":{"usage":{"input_tokens":5000000,"output_tokens":5000000}}}]' >> "$FCA_F"
FCCFG="$FC/fa3a" _fc --tsv
_fca_floor3 "felix cost: a response whose content holds an object-valued usage key, a second usage" m-two

# (b) a response whose only "usage":{ comes after a wireToolInputs key.
_fc_mk fa3b
FCA_F="$FC/fa3b/projects/-Users-dev-three/s1.jsonl"; mkdir -p "$(dirname "$FCA_F")"
_fca_resp msg_UR1 "$FCT0" m-good3 "$(_fc_use 1000 0 0 0 0)" > "$FCA_F"
printf '{"parentUuid":null,"isSidechain":false,"message":{"model":"m-wire","id":"msg_UR3","type":"message","role":"assistant","content":[{"type":"tool_use","id":"toolu_4","name":"Run","input":{}}],"stop_reason":null},"wireToolInputs":{"toolu_4":{"usage":{"input_tokens":5000000}}},"requestId":"req_3","type":"assistant","uuid":"u-ur3","timestamp":"%s","sessionId":"s1"}\n' \
  "$FCT0" >> "$FCA_F"
FCCFG="$FC/fa3b" _fc --tsv
_fca_floor3 "felix cost: a response whose only usage comes after a wireToolInputs key" m-wire

# (c) a response whose time cannot be read.
_fc_mk fa3c
FCA_F="$FC/fa3c/projects/-Users-dev-three/s1.jsonl"; mkdir -p "$(dirname "$FCA_F")"
_fca_resp msg_UR1 "$FCT0" m-good3 "$(_fc_use 1000 0 0 0 0)" > "$FCA_F"
_fca_resp msg_UR4 tomorrow m-notime "$(_fc_use 8000 0 0 0 0)" >> "$FCA_F"
FCCFG="$FC/fa3c" _fc --tsv
_fca_floor3 "felix cost: a response whose timestamp is not a time" m-notime

# (d) a message usage first and a second usage in wireToolInputs after it: two "usage":{ after the message.
_fc_mk fa3d
FCA_F="$FC/fa3d/projects/-Users-dev-three/s1.jsonl"; mkdir -p "$(dirname "$FCA_F")"
_fca_resp msg_UR1 "$FCT0" m-good3 "$(_fc_use 1000 0 0 0 0)" > "$FCA_F"
_fca_resp msg_UR5 "$FCT0" m-wire2 "$(_fc_use 9000 0 0 0 0)" \
  '[{"type":"tool_use","id":"toolu_5","name":"Run","input":{}}]' '{"toolu_5":{"usage":{"input_tokens":1}}}' >> "$FCA_F"
FCCFG="$FC/fa3d" _fc --tsv
_fca_floor3 "felix cost: a response whose message usage is followed by a second usage in wireToolInputs" m-wire2

# (e) two of them among readable ones, in the text view: the responses line says how many, and floor.
_fc_mk fa3e
FCA_F="$FC/fa3e/projects/-Users-dev-three/s1.jsonl"; mkdir -p "$(dirname "$FCA_F")"
_fca_resp msg_UR1 "$FCT0" m-good3 "$(_fc_use 1000 0 0 0 0)" > "$FCA_F"
_fca_resp msg_UR6 "$FCT0" m-two2 "$(_fc_use 7000 0 0 0 0)" \
  '[{"type":"tool_use","id":"toolu_3","name":"Run","input":{"usage":{"input_tokens":5000000}}}]' >> "$FCA_F"
_fca_resp msg_UR7 tomorrow m-notime2 "$(_fc_use 8000 0 0 0 0)" >> "$FCA_F"
FCCFG="$FC/fa3e" _fc --tsv
is  "felix cost --tsv: two responses it cannot place are responses_unread 2" "$(_fc_cover responses_unread)" "2"
FCCFG="$FC/fa3e" _fc
FCA_RL="$(_fca_resp_line)"
is  "felix cost (text): a line beginning responses says how many responses could not be read: the number 2 is one of its words" \
    "$(printf '%s\n' "$FCA_RL" | awk '{ for (i = 2; i <= NF; i++) if ($i == "2") f = 1; print (f ? "has 2" : "no 2: " $0) }')" "has 2"
has "felix cost (text): the responses line contains the word floor" "$FCA_RL" "floor"
has "felix cost (text): the total line of a floor from unread responses reads at least" "$(_fc_line total)" "at least"
is  "felix cost (text): the calls line counts only the one readable response" "$(_fc_line calls)" "calls 1"

# ----------------------------------------------------------------------
# Item 4. Across files the largest usage of an id wins; within one file the
# last line of an id still wins. A response with output 200 and input 100
# weighs 100 + 200 x 5 = 1100; its early partial line, output 10, weighs 150.
# ----------------------------------------------------------------------
_fca_i4() {   # STEM DIR SHALLOW-NAME DEEP-NAME SHALLOW-OUT DEEP-OUT: one id in subagents/ and in subagents/workflows/wf_1/
  _fc_mk "$2"
  local d="$FC/$2/projects/-Users-dev-xf/s1/subagents"
  _fc_put "$d/$3"                  msg_XF1 "$FCT0" m-xf 100 0 0 0 "$5"
  _fc_put "$d/workflows/wf_1/$4"   msg_XF1 "$FCT0" m-xf 100 0 0 0 "$6"
  FCCFG="$FC/$2" _fc --tsv
  is  "$1: the id counts once, at the full usage: 1100 over one call" "$(_fc_row total all)" "$(_fc_exps total all 1100.00 0.0 1)"
  is  "$1: the model row holds the full usage once" "$(_fc_row model m-xf)" "$(_fc_exps model m-xf 1100.00 0.0 1)"
  is  "$1: both files were read" "$(_fc_cover files_read) $(_fc_cover files_unread) $(_fc_cover coverage)" "2 0 measured"
}
# subagents/agent-a.jsonl sorts before subagents/workflows/wf_1/agent-a.jsonl; subagents/z-agent.jsonl sorts after it.
_fca_i4 "felix cost: the full usage in subagents/agent-a.jsonl, a partial copy in a workflow's agent-a.jsonl (full path sorts first)"  fa4a agent-a.jsonl agent-a.jsonl 200 10
_fca_i4 "felix cost: the full usage in subagents/z-agent.jsonl, a partial copy in a workflow's agent-a.jsonl (full path sorts last)"    fa4b z-agent.jsonl agent-a.jsonl 200 10
_fca_i4 "felix cost: a partial copy in subagents/agent-a.jsonl, the full usage in a workflow's agent-a.jsonl (partial path sorts first)" fa4c agent-a.jsonl agent-a.jsonl 10 200
_fca_i4 "felix cost: a partial copy in subagents/z-agent.jsonl, the full usage in a workflow's agent-a.jsonl (partial path sorts last)"   fa4d z-agent.jsonl agent-a.jsonl 10 200

# Within a file the last line of an id decides what that file holds; across files the largest of those wins.
# File A holds output 500 and then output 100 for the id (its last line, 100 x 5 = 500); file B holds output 300 (1500).
# The answer is B's 1500: not A's earlier 500-output line (2500), not A's last (500).
_fca_i4b() {   # STEM DIR A-NAME B-NAME
  _fc_mk "$2"
  local d="$FC/$2/projects/-Users-dev-xg"
  _fc_put "$d/$3" msg_XG1 "$FCT0" m-xg 0 0 0 0 500
  _fc_put "$d/$3" msg_XG1 "$FCT0" m-xg 0 0 0 0 100
  _fc_put "$d/$4" msg_XG1 "$FCT0" m-xg 0 0 0 0 300
  FCCFG="$FC/$2" _fc --tsv
  is  "$1: A's last line is A's usage, then the larger of the files' usages counts: 1500, once" \
      "$(_fc_row total all)" "$(_fc_exps total all 1500.00 0.0 1)"
}
_fca_i4b "felix cost: across two files the largest per-file last line wins, not the largest line anywhere (file A sorts first)" fa4e a.jsonl b.jsonl
_fca_i4b "felix cost: across two files the largest per-file last line wins, not the largest line anywhere (file A sorts last)"  fa4f b.jsonl a.jsonl

# The same id under two record directories, the partial copy in one and the full usage in the other. Which
# directory it is attributed to is not said; the total and the sum of the worktree rows are.
_fc_mk fa4g
_fc_put "$FC/fa4g/projects/-Users-dev-xh1/s1.jsonl" msg_XH1 "$FCT0" m-xh 100 0 0 0 10
_fc_put "$FC/fa4g/projects/-Users-dev-xh2/s2.jsonl" msg_XH1 "$FCT0" m-xh 100 0 0 0 200
FCCFG="$FC/fa4g" _fc --tsv
is  "felix cost: an id in two record directories, partial in one and full in the other, counts once at the full usage: 1100" \
    "$(_fc_row total all)" "$(_fc_exps total all 1100.00 0.0 1)"
is  "felix cost: an id in two record directories: the worktree rows add up to the total, 1100 over one call" \
    "$(_fc_rows worktree | awk -F'\t' '{ s += $3; n += $5 } END { printf "%.2f %d", s, n }')" "1100.00 1"

# The amended line: every *.jsonl at any depth under <E>/<sid>/subagents/ is read, and only there.
_fc_mk fa4h
FCA_S="$FC/fa4h/projects/-Users-dev-deep/s1"
_fc_in "$FCA_S/subagents/a.jsonl"                                  msg_DP1 "$FCT0" m-dp1 1000
_fc_in "$FCA_S/subagents/workflows/wf_1/b.jsonl"                   msg_DP2 "$FCT0" m-dp2 2000
_fc_in "$FCA_S/subagents/workflows/wf_1/nested/deep/c.jsonl"       msg_DP3 "$FCT0" m-dp3 4000
_fc_in "$FCA_S/subagents/direct/d.jsonl"                           msg_DP4 "$FCT0" m-dp4 8000
# Never read: subagents/ below another directory of the session, a file without the suffix, a file older than the window.
_fc_in "$FCA_S/other/subagents/e.jsonl"                            msg_DP5 "$FCT0" m-dp5 100001
_fc_in "$FCA_S/subagents/workflows/wf_1/meta.json"                 msg_DP6 "$FCT0" m-dp6 100002
_fc_in "$FCA_S/subagents/workflows/wf_1/old.jsonl"                 msg_DP7 "$FCT0" m-dp7 100003
touch -t 202609010000 "$FCA_S/subagents/workflows/wf_1/old.jsonl"
FCCFG="$FC/fa4h" _fc --tsv
is  "felix cost reads every *.jsonl at any depth under <E>/<sid>/subagents/: direct, in a workflow run, and deeper still: 15000 over four calls" \
    "$(_fc_row total all)" "$(_fc_exps total all 15000.00 0.0 4)"
is  "felix cost reads exactly four files there" "$(_fc_cover files_read) $(_fc_cover files_unread)" "4 0"
is  "felix cost does not read subagents/ when it sits below another directory of the session (<E>/<sid>/other/subagents/)" \
    "$(_fc_absent model m-dp5)" "absent"
is  "felix cost does not read a file under subagents/ without the .jsonl suffix" "$(_fc_absent model m-dp6)" "absent"
is  "felix cost does not read a file under subagents/workflows/ modified before the window start" "$(_fc_absent model m-dp7)" "absent"

# ----------------------------------------------------------------------
# Item 5. A line ending in \r\n is read as if it ended in \n.
# ----------------------------------------------------------------------
_fc_mk fa5
FCA_C="$FC/fa5/projects/-Users-dev-crlf"; mkdir -p "$FCA_C"
printf '%s\r\n' "$(_fc_rec msg_CR1 "$FCT0" m-cr1 "$(_fc_use 1000 0 0 0 0)")" > "$FCA_C/crlf.jsonl"
printf '%s\r\n' "$(_fc_rec msg_CR2 "$FCT0" m-cr2 "$(_fc_use 2000 0 0 0 0)")" >> "$FCA_C/crlf.jsonl"
# The id msg_CR1 again, later, with more: the last CRLF line of an id wins, 3000.
printf '%s\r\n' "$(_fc_rec msg_CR1 "$FCT0" m-cr1 "$(_fc_use 3000 0 0 0 0)")" >> "$FCA_C/crlf.jsonl"
# A CRLF line cut off before its last brace is not whole, whatever follows it.
FCA_L="$(_fc_rec msg_CR9 "$FCT0" m-crcut "$(_fc_use 5000000 0 0 0 0)")"
printf '%s\r\n' "${FCA_L%\}}" >> "$FCA_C/crlf.jsonl"
# A file mixing LF and CRLF lines: 4000 (LF), 8000 (CRLF), 16000 (LF).
_fc_put "$FCA_C/mixed.jsonl" msg_CR3 "$FCT0" m-cr3 4000 0 0 0 0
printf '%s\r\n' "$(_fc_rec msg_CR4 "$FCT0" m-cr4 "$(_fc_use 8000 0 0 0 0)")" >> "$FCA_C/mixed.jsonl"
_fc_put "$FCA_C/mixed.jsonl" msg_CR5 "$FCT0" m-cr5 16000 0 0 0 0
FCCFG="$FC/fa5" _fc --tsv
# CR1 3000 + CR2 2000 + CR3 4000 + CR4 8000 + CR5 16000 = 33000 over five calls.
is  "felix cost reads lines ending \\r\\n as whole records: 33000 over five calls from a CRLF file and a mixed file" \
    "$(_fc_row total all)" "$(_fc_exps total all 33000.00 0.0 5)"
is  "felix cost: of an id repeated on CRLF lines the last line's usage counts: 3000" \
    "$(_fc_row model m-cr1)" "$(_fc_exps model m-cr1 3000.00 0.0 1)"
is  "felix cost reads a CRLF line in the middle of a mixed file: 8000" "$(_fc_row model m-cr4)" "$(_fc_exps model m-cr4 8000.00 0.0 1)"
is  "felix cost skips a CRLF line that lost its last brace" "$(_fc_absent model m-crcut)" "absent"
is  "felix cost: a CRLF file is read without any unread file, coverage measured" \
    "$(_fc_cover files_read) $(_fc_cover files_unread) $(_fc_cover coverage)" "2 0 measured"
is  "felix cost: a CRLF file leaves no response unread: a line ending \\r\\n is a whole line, not a response it cannot place" \
    "$(_fc_cover responses_unread)" "0"
is  "felix cost leaves no carriage return in its TSV report of a CRLF file" "$(tr -cd '\r' < "$FCOUTF" | wc -c | tr -d ' ')" "0"
FCCFG="$FC/fa5" _fc
is  "felix cost (text) reads a CRLF file the same: the calls line counts five" "$(_fc_line calls)" "calls 5"
is  "felix cost leaves no carriage return in its text report of a CRLF file" "$(tr -cd '\r' < "$FCOUTF" | wc -c | tr -d ' ')" "0"

# ----------------------------------------------------------------------
# Item 6. The cover rows, in order: window_start, window_end, source,
# cap_tokens, files_read, files_unread, responses_unread, coverage, as_of.
# ----------------------------------------------------------------------
FCA_ORDER="window_start window_end source cap_tokens files_read files_unread responses_unread coverage as_of"
FCCFG="$FC/fa4a" _fc --tsv
is  "felix cost --tsv: the cover rows are, in order, window_start window_end source cap_tokens files_read files_unread responses_unread coverage as_of" \
    "$(_fca_cover_keys)" "$FCA_ORDER"
is  "felix cost --tsv: the nine cover rows are the first nine lines, and the total row is the tenth" \
    "$(awk -F'\t' 'NR <= 9 && $1 == "cover" { n++ } NR == 10 { t = $1 } END { print n + 0, t }' "$FCOUTF")" "9 total"
is  "felix cost --tsv: responses_unread is 0 when every response could be placed" "$(_fc_cover responses_unread)" "0"
FCCFG="$FC/fa3e" _fc --tsv
is  "felix cost --tsv: the cover rows keep their order when responses are unread, responses_unread being 2" \
    "$(_fca_cover_keys) / $(_fc_cover responses_unread)" "$FCA_ORDER / 2"
FCCFG="$FC/nope" _fc --tsv
is  "felix cost --tsv: the cover rows keep their order when the total is unknown" "$(_fca_cover_keys)" "$FCA_ORDER"
FCCFG="$FC/fa4a" _fc --tsv --since 2026-10-09
is  "felix cost --tsv --since: the cover rows keep their order, window_end reading now" \
    "$(_fca_cover_keys) / $(_fc_cover window_end)" "$FCA_ORDER / now"
FCCFG="$FC/fa4a" _fc --tsv --by model
is  "felix cost --tsv --by model: the cover rows keep their order" "$(_fca_cover_keys)" "$FCA_ORDER"

# ----------------------------------------------------------------------
# Item 7. Unknown reads total unknown (<reason>) in the text view. A records
# root that exists but cannot be read or entered is unknown, and the text says
# could not be read.
# ----------------------------------------------------------------------
_fca_unk() {   # STEM: the text report just run reads total unknown (<a reason>), and no breakdown follows
  is  "$1: the total line reads total unknown, then a reason in parentheses" \
      "$(_fc_line total | awk '{ print ($0 ~ /^total unknown \(.+\)$/) ? "yes" : "no: " $0 }')" "yes"
  is  "$1: exit 0 and no heading" "$FCRC [$(_fc_heads)]" "0 []"
}
FCCFG="$FC/nope" _fc
_fca_unk "felix cost (text): with no records root"
FCCFG="$FC/rE" _fc
_fca_unk "felix cost (text): with a records root that holds no transcript"
FCCFG="$FC/rN" _fc
_fca_unk "felix cost (text): with a records root whose files are read at neither depth"

# The records root exists but has no permission: it cannot be read or entered.
_fc_mk fa7
_fc_in "$FC/fa7/projects/-Users-dev-ur/s1.jsonl" msg_UR9 "$FCT0" m-ur 1000
chmod 000 "$FC/fa7/projects"
FCCFG="$FC/fa7" _fc --tsv
FCA_ROWS="$FCRC|$(_fc_cover coverage)|$(_fc_row total all)|$(_fc_kinds)"
FCCFG="$FC/fa7" _fc
FCA_TL="$(_fc_line total)"; FCA_ALL="$FCOUT"; FCA_RC="$FCRC"
FCA_UNK="$(_fc_line total | awk '{ print ($0 ~ /^total unknown \(.+\)$/) ? "yes" : "no: " $0 }')"
chmod 755 "$FC/fa7/projects"
_fcad  "felix cost --tsv: a records root that cannot be read or entered is exit 0, coverage unknown, a total of unknown in all three columns, no breakdown row" \
       "$FCA_ROWS" "0|unknown|$(printf 'total\tall\tunknown\tunknown\tunknown')|cover total"
_fcad  "felix cost (text): a records root that cannot be read or entered reads total unknown (<reason>), exit 0" \
       "$FCA_RC $FCA_UNK" "0 yes"
_fcadh "felix cost (text): a records root that cannot be read or entered says could not be read" "$FCA_ALL" "could not be read"

# Every file that should be read is unreadable: the floor is 0, unknown, in the text form too.
_fc_mk fa7b
_fc_in "$FC/fa7b/projects/-Users-dev-ul/locked.jsonl" msg_UR10 "$FCT0" m-ul 4000
chmod 000 "$FC/fa7b/projects/-Users-dev-ul/locked.jsonl"
FCCFG="$FC/fa7b" _fc
FCA_UNK="$(_fc_line total | awk '{ print ($0 ~ /^total unknown \(.+\)$/) ? "yes" : "no: " $0 }')"; FCA_RC="$FCRC"
chmod 644 "$FC/fa7b/projects/-Users-dev-ul/locked.jsonl"
_fcad  "felix cost (text): when every file that should be read is unreadable the total reads unknown (<reason>), exit 0" "$FCA_RC $FCA_UNK" "0 yes"

# ----------------------------------------------------------------------
# Item 8. POSIXLY_CORRECT=1 in the environment changes nothing.
# ----------------------------------------------------------------------
_fca_posix() {   # STEM CONFIG-DIR ARGS...: byte-identical output with POSIXLY_CORRECT=1, and a report that was made
  local stem="$1" cfg="$2" prc; shift 2
  FCCFG="$cfg" _fc "$@"
  cp "$FCOUTF" "$FC/fa8.plain"; local plain_rc="$FCRC" plain_total; plain_total="$(awk -F'\t' '$1 == "total" || $1 ~ /^total/ { n++ } END { print n + 0 }' "$FCOUTF")"
  prc="$( ( export POSIXLY_CORRECT=1; FCCFG="$cfg" _fc "$@"; printf '%s' "$FCRC" ) )"
  local same=differ; cmp -s "$FC/fa8.plain" "$FCOUTF" && same=same
  is  "$stem: exit status 0, as without it" "$plain_rc $prc" "0 0"
  is  "$stem: the output is byte-identical to the output without it" "$same" "same"
  is  "$stem: it is a report, with a total line" "$([ "$plain_total" -ge 1 ] && echo yes || echo no)" "yes"
}
FCNOW=2026-10-14T20:00:00Z FCCAP=100 _fca_posix "felix cost --tsv with POSIXLY_CORRECT=1, twelve worktrees and three models" "$FC/r11" --tsv
FCNOW=2026-10-14T20:00:00Z FCCAP=100 _fca_posix "felix cost (text) with POSIXLY_CORRECT=1" "$FC/r11"
_fca_posix "felix cost --tsv with POSIXLY_CORRECT=1, helper agents and a workflow's agents" "$FC/r6" --tsv
_fca_posix "felix cost --tsv with POSIXLY_CORRECT=1, an id in two files with different usage" "$FC/fa4a" --tsv --by model
_fca_posix "felix cost --tsv with POSIXLY_CORRECT=1, CRLF lines" "$FC/fa5" --tsv
_fca_posix "felix cost --tsv with POSIXLY_CORRECT=1, responses it cannot place" "$FC/fa3e" --tsv
_fca_posix "felix cost --tsv with POSIXLY_CORRECT=1, no records root" "$FC/nope" --tsv

# ----------------------------------------------------------------------
# Item 9. Usage errors also: --since '', a --top of more than 9 digits, and a
# FELIX_COST_NOW before 1970-01-01T13:00Z.
# ----------------------------------------------------------------------
FCCFG="$FC/r1" _fc --tsv --since ''
is  "felix cost --since with an empty value, in the TSV view, is a usage error: exit 2, nothing on stdout, a felix cost: line and the usage line on stderr" \
    "$(_fc_usage_verdict)" "$FCUSAGE_OK"
FCCFG="$FC/r1" _fc --since ''
is  "felix cost --since with an empty value, in the text view, is a usage error" "$(_fc_usage_verdict)" "$FCUSAGE_OK"
for FCA_V in 1234567890 99999999999999999999 12345678901234567890123; do
  FCCFG="$FC/r1" _fc --tsv --top "$FCA_V"
  is  "felix cost --top $FCA_V, more than 9 digits, is a usage error: exit 2, nothing on stdout, a felix cost: line and the usage line on stderr" \
      "$(_fc_usage_verdict)" "$FCUSAGE_OK"
done
FCCFG="$FC/r1" _fc --top 1234567890
is  "felix cost --top of ten digits is a usage error in the text view too" "$(_fc_usage_verdict)" "$FCUSAGE_OK"
_fc_run11 --tsv --by worktree --top 999999999
is  "felix cost --top 999999999, nine digits, is accepted: exit 0 and all twelve worktrees" "$FCRC $(_fc_count worktree)" "0 12"
for FCA_V in 1970-01-01T12:59:00Z 1970-01-01T12:59:59Z 1970-01-01T12:59Z 1969-12-31T23:59:00Z 1900-01-01T00:00:00Z; do
  FCCFG="$FC/r1" FCNOW="$FCA_V" _fc --tsv
  is  "felix cost with FELIX_COST_NOW=$FCA_V, before 1970-01-01T13:00Z, is a usage error: exit 2, nothing on stdout, a felix cost: line and the usage line on stderr" \
      "$(_fc_usage_verdict)" "$FCUSAGE_OK"
done
FCCFG="$FC/r1" FCNOW=1970-01-01T12:59:00Z _fc
is  "felix cost (text) with a FELIX_COST_NOW before 1970-01-01T13:00Z is a usage error too" "$(_fc_usage_verdict)" "$FCUSAGE_OK"
# 1970-01-01 was a Thursday: at 13:00:00Z the plan week opens, so that instant is accepted and is in the first week.
FCCFG="$FC/r1" FCNOW=1970-01-01T13:00:00Z _fc --tsv
is  "felix cost with FELIX_COST_NOW=1970-01-01T13:00:00Z, not before the limit, is accepted: exit 0 and the week that opened at that instant" \
    "$FCRC $(_fc_cover window_start) $(_fc_cover window_end) $(_fc_cover as_of)" "0 1970-01-01T13:00Z 1970-01-08T13:00Z 1970-01-01T13:00Z"

# ----------------------------------------------------------------------
# Item 10. The window prune is exact to the second: a file modified at the
# window start is read, one modified a second before it is not. Times are set
# with touch -t and seconds, under TZ=UTC0.
# ----------------------------------------------------------------------
_fc_mk fa10
FCA_P="$FC/fa10/projects"
_fc_in "$FCA_P/-Users-dev-t0/at.jsonl"    msg_SC1 "$FCT0" m-sc-at    1000
_fc_in "$FCA_P/-Users-dev-tm/minus.jsonl" msg_SC2 "$FCT0" m-sc-minus 2000
_fc_in "$FCA_P/-Users-dev-tp/plus.jsonl"  msg_SC3 "$FCT0" m-sc-plus  4000
TZ=UTC0 touch -t 202610081300.00 "$FCA_P/-Users-dev-t0/at.jsonl"       # the week's start, to the second
TZ=UTC0 touch -t 202610081259.59 "$FCA_P/-Users-dev-tm/minus.jsonl"    # one second before it
TZ=UTC0 touch -t 202610081300.01 "$FCA_P/-Users-dev-tp/plus.jsonl"     # one second after it
FCCFG="$FC/fa10" _fc --tsv
is  "felix cost reads a file modified at the second the window opens, 2026-10-08 13:00:00" \
    "$(_fc_row model m-sc-at)" "$(_fc_exps model m-sc-at 1000.00 0.0 1)"
is  "felix cost does not read a file modified one second before the window opens, 12:59:59, though it holds an in-window record" \
    "$(_fc_absent model m-sc-minus)" "absent"
is  "felix cost reads a file modified one second after the window opens" \
    "$(_fc_row model m-sc-plus)" "$(_fc_exps model m-sc-plus 4000.00 0.0 1)"
is  "felix cost: the second-exact prune reads two files, 5000 over two calls" \
    "$(_fc_cover files_read) $(_fc_cover files_unread) $(_fc_row total all)" "2 0 $(_fc_exps total all 5000.00 0.0 2)"
FCCFG="$FC/fa10" FCTZ=Pacific/Auckland _fc --tsv
is  "felix cost prunes to the second in UTC under another zone: the file at the start is read, the one a second before is not" \
    "$(_fc_cover files_read)|$(_fc_absent model m-sc-minus)|$(_fc_row model m-sc-at)" "2|absent|$(_fc_exps model m-sc-at 1000.00 0.0 1)"
FCCFG="$FC/fa10" FCTZ=America/Los_Angeles _fc --tsv
is  "felix cost prunes to the second in UTC under America/Los_Angeles: the file at the start is read, the one a second before is not" \
    "$(_fc_cover files_read)|$(_fc_absent model m-sc-minus)|$(_fc_row model m-sc-at)" "2|absent|$(_fc_exps model m-sc-at 1000.00 0.0 1)"

# The same under --since, whose start is not a Thursday: 2026-10-09T10:30. Every record is dated 11:00 that day.
_fc_mk fa10b
FCA_P="$FC/fa10b/projects"
_fc_in "$FCA_P/-Users-dev-s0/at.jsonl"    msg_SC4 2026-10-09T11:00:00.000Z m-ss-at    1000
_fc_in "$FCA_P/-Users-dev-sm/minus.jsonl" msg_SC5 2026-10-09T11:00:00.000Z m-ss-minus 2000
_fc_in "$FCA_P/-Users-dev-sp/plus.jsonl"  msg_SC6 2026-10-09T11:00:00.000Z m-ss-plus  4000
TZ=UTC0 touch -t 202610091030.00 "$FCA_P/-Users-dev-s0/at.jsonl"
TZ=UTC0 touch -t 202610091029.59 "$FCA_P/-Users-dev-sm/minus.jsonl"
TZ=UTC0 touch -t 202610091030.01 "$FCA_P/-Users-dev-sp/plus.jsonl"
FCCFG="$FC/fa10b" _fc --tsv --since 2026-10-09T10:30
is  "felix cost --since 2026-10-09T10:30 reads the file modified at 10:30:00 and the one at 10:30:01, and not the one at 10:29:59" \
    "$(_fc_cover files_read)|$(_fc_row model m-ss-at)|$(_fc_absent model m-ss-minus)|$(_fc_row model m-ss-plus)" \
    "2|$(_fc_exps model m-ss-at 1000.00 0.0 1)|absent|$(_fc_exps model m-ss-plus 4000.00 0.0 1)"

# A midnight start: --since 2026-10-09 is 00:00:00, and a file at 23:59:59 the day before is a second short of it.
_fc_mk fa10c
FCA_P="$FC/fa10c/projects"
_fc_in "$FCA_P/-Users-dev-m0/at.jsonl"    msg_SC7 2026-10-09T11:00:00.000Z m-sm-at    1000
_fc_in "$FCA_P/-Users-dev-mm/minus.jsonl" msg_SC8 2026-10-09T11:00:00.000Z m-sm-minus 2000
TZ=UTC0 touch -t 202610090000.00 "$FCA_P/-Users-dev-m0/at.jsonl"
TZ=UTC0 touch -t 202610082359.59 "$FCA_P/-Users-dev-mm/minus.jsonl"
FCCFG="$FC/fa10c" _fc --tsv --since 2026-10-09
is  "felix cost --since 2026-10-09 reads the file modified at 00:00:00 and not the one modified at 23:59:59 the day before" \
    "$(_fc_cover files_read)|$(_fc_row model m-sm-at)|$(_fc_absent model m-sm-minus)" "1|$(_fc_exps model m-sm-at 1000.00 0.0 1)|absent"

chmod -R u+rwX "$FC" 2>/dev/null

