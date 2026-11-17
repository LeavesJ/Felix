# ---------------------------------------------------------- felix cost ----
# A read-only report of the tokens Claude Code spent, read from the transcripts
# it already keeps, in input-equivalent tokens: a proxy for plan usage, not the
# plan's own number. Written blind, from the contract alone (Synopsis to TSV
# view), while the command was being written by someone else, so each
# assertion names a rule of that contract and none reads a wording the contract
# does not give. Where the contract leaves a thing open (which record directory
# a forked id is attributed to, what a usage error says after its first words)
# nothing here asserts on it.
#
# Every fixture is a records root, $TMP/cost/<name>/projects/<E>/..., holding
# transcripts in the contract's compact record shape, and every run is a child
# of its own: a plain directory outside any repository for its cwd, a HOME of
# its own, no FELIX_HOME, a TMPDIR of its own (so a scratch file left behind is
# seen), and FELIX_COST_NOW fixed unless a case says otherwise. The numbers
# are chosen so each weight is exact, and the arithmetic sits beside each
# fixture. Rows are read from --tsv; the text view is read by the first word
# of a line, and its numbers with the % and M marks cut off.

printf '\nfelix cost: tokens spent, read from the transcripts\n'

_fc_init

FC_WHERE=outside
git -C "$FCCWD" rev-parse >/dev/null 2>&1 && FC_WHERE=inside

# ======================================================================
# One response: the exact tokens, the percent, the calls, and both views.
# ======================================================================
_fc_fixture r1
# input 10500000 x 1 = 10500000; 5m writes 8000000 x 1.25 = 10000000; 1h writes
# 5000000 x 2 = 10000000; cache reads 100000000 x 0.1 = 10000000; output
# 10000000 x 5 = 50000000. Total 90500000, which is 10.0% of a 905M week.
FCCFG="$FC/r1" _fc --tsv
is  "felix cost --tsv, run from a directory outside every git repository with no FELIX_HOME, exits 0" "$FCRC $FC_WHERE" "0 outside"
is  "felix cost --tsv: the total row is the response's exact input-equivalent tokens, 10.0 percent, one call" \
    "$(_fc_row total all)" "$(_fc_exps total all 90500000.00 10.0 1)"
is  "felix cost --tsv: the worktree row is the record directory, with the same tokens" \
    "$(_fc_row worktree -Users-dev-alpha)" "$(_fc_exps worktree -Users-dev-alpha 90500000.00 10.0 1)"
is  "felix cost --tsv: the day row is the UTC date of the record's time" \
    "$(_fc_row day 2026-10-09)" "$(_fc_exps day 2026-10-09 90500000.00 10.0 1)"
is  "felix cost --tsv: the model row is message.model" \
    "$(_fc_row model claude-opus-5-5)" "$(_fc_exps model claude-opus-5-5 90500000.00 10.0 1)"
is  "felix cost --tsv: cover window_start is the Thursday 13:00Z the plan week opened on" \
    "$(_fc_cover window_start)" "2026-10-08T13:00Z"
is  "felix cost --tsv: cover window_end is the next Thursday 13:00Z" \
    "$(_fc_cover window_end)" "2026-10-15T13:00Z"
is  "felix cost --tsv: cover source with CLAUDE_CONFIG_DIR set is the literal text \$CLAUDE_CONFIG_DIR/projects" \
    "$(_fc_cover source)" '$CLAUDE_CONFIG_DIR/projects'
is  "felix cost --tsv: cover cap_tokens is 905000000 by default" \
    "$(_fc_cover cap_tokens)" "905000000"
is  "felix cost --tsv: cover files_read counts the one transcript read" \
    "$(_fc_cover files_read)" "1"
is  "felix cost --tsv: cover files_unread is 0 when every file could be read" \
    "$(_fc_cover files_unread)" "0"
is  "felix cost --tsv: cover coverage is measured when everything was read" \
    "$(_fc_cover coverage)" "measured"
is  "felix cost --tsv: cover as_of is the instant FELIX_COST_NOW named, to the minute" \
    "$(_fc_cover as_of)" "2026-10-11T05:00Z"
FC_BAD="$(awk -F'\t' '$1 == "cover" { if (NF != 3) n++ ; next }
                      $1 == "total" || $1 == "worktree" || $1 == "day" || $1 == "model" { if (NF != 5) n++ ; next }
                      { n++ } END { if (NR == 0) print "no rows"; else print n + 0 }' "$FCOUTF")"
is  "felix cost --tsv: cover rows have three columns, every other row five, and no row is of another kind (no header line)" "$FC_BAD" "0"
FC_DUP="$(awk -F'\t' '$1 == "cover" { c[$2]++ } $1 == "total" { t++ }
                      END { for (k in c) if (c[k] != 1) d = d " " k; if (t != 1) d = d " total"; if (d == "") print "once each"; else print d }' "$FCOUTF")"
is  "felix cost --tsv: every cover key and the total row appear exactly once" "$FC_DUP" "once each"

FCCFG="$FC/r1" _fc
is  "felix cost (text) over one response exits 0" "$FCRC" "0"
is  "felix cost (text): the first line says it is read-only and a proxy, not the plan's own number" \
    "$(awk 'NR == 1' "$FCOUTF")" "felix cost: read-only. A proxy for plan usage in input-equivalent tokens, not the plan's own number."
is  "felix cost (text): the window line gives the plan week's start and end" \
    "$(_fc_line window)" "window 2026-10-08T13:00Z to 2026-10-15T13:00Z"
FC_TL="$(_fc_line total)"
has "felix cost (text): the total line gives the tokens in millions with one decimal and an M" "$FC_TL" "90.5M"
has "felix cost (text): the total line gives the percent of the cap with one decimal" "$FC_TL" "10.0%"
has "felix cost (text): the total line names the cap, 905M" "$FC_TL" "905M"
is  "felix cost (text): the calls line gives the number of distinct responses" "$(_fc_line calls)" "calls 1"
FC_FL="$(_fc_line files)"
is  "felix cost (text): the files line leads with how many files were read" "$(printf '%s' "$FC_FL" | awk '{ print $1, $2 }')" "files 1"
has "felix cost (text): the files line names the root as the literal \$CLAUDE_CONFIG_DIR/projects" "$FC_FL" 'under $CLAUDE_CONFIG_DIR/projects'
case "$FC_FL" in
  files*"$FC/r1"*) bad "felix cost (text): the files line names the variable, not its value" "[$FC_FL] holds the path" ;;
  files*under*)    ok  "felix cost (text): the files line names the variable, not its value" ;;
  *)               bad "felix cost (text): the files line names the variable, not its value" "no files line under: [$FC_FL]" ;;
esac
is  "felix cost (text): the headings are worktrees and then days, and no models" "$(_fc_heads)" "worktrees days"
is  "felix cost (text): a worktree line is percent, millions, then the record directory" \
    "$(_fc_sec worktrees)" "10.0 90.5 -Users-dev-alpha"
is  "felix cost (text): a day line is the date, millions, then percent" \
    "$(_fc_sec days)" "2026-10-09 90.5 10.0"

# ======================================================================
# The weight of each field, one at a time.
# ======================================================================
_fc_mk r2
FC_W="$FC/r2/projects/-Users-dev-weights/s1.jsonl"
_fc_put "$FC_W" msg_B1 "$FCT0" m-in   1000 0 0 0 0         # 1000 x 1                    = 1000
_fc_put "$FC_W" msg_B2 "$FCT0" m-c5      0 1000 0 0 0      # 1000 x 1.25                = 1250
_fc_put "$FC_W" msg_B3 "$FCT0" m-c1h     0 0 1000 0 0      # 1000 x 2                   = 2000
_fc_put "$FC_W" msg_B4 "$FCT0" m-cr      0 0 0 1000 0      # 1000 x 0.1                 = 100
_fc_put "$FC_W" msg_B5 "$FCT0" m-out     0 0 0 0 1000      # 1000 x 5                   = 5000
# No cache_creation object: cache_creation_input_tokens 2000 is all 5-minute writes,
# 2000 x 1.25 = 2500.
_fc_rec msg_B6 "$FCT0" m-nocc '{"input_tokens":0,"cache_creation_input_tokens":2000,"cache_read_input_tokens":0,"output_tokens":0}' >> "$FC_W"
# cache_creation present: its fields are used and the top-level 999999 is ignored,
# 400 x 1.25 = 500.
_fc_rec msg_B7 "$FCT0" m-ccp '{"input_tokens":0,"cache_creation_input_tokens":999999,"cache_read_input_tokens":0,"output_tokens":0,"cache_creation":{"ephemeral_5m_input_tokens":400,"ephemeral_1h_input_tokens":0}}' >> "$FC_W"
# null counts are 0 and a missing one is 0: only output 100 x 5 = 500.
_fc_rec msg_B8 "$FCT0" m-null '{"input_tokens":null,"cache_creation_input_tokens":null,"cache_read_input_tokens":null,"output_tokens":100}' >> "$FC_W"
# cache_creation holding only a 1h field: 5m reads 0, 1h 100 x 2 = 200, the 777 is ignored.
_fc_rec msg_B9 "$FCT0" m-ccmiss '{"input_tokens":0,"cache_creation_input_tokens":777,"cache_read_input_tokens":0,"output_tokens":0,"cache_creation":{"ephemeral_1h_input_tokens":100}}' >> "$FC_W"
# cache_creation holding only a 5m field, and a different key order: 80 x 1.25 = 100.
_fc_rec msg_B10 "$FCT0" m-cc5only '{"input_tokens":0,"cache_creation_input_tokens":555,"cache_creation":{"ephemeral_5m_input_tokens":80},"output_tokens":0,"cache_read_input_tokens":0}' >> "$FC_W"
# Every field at once, to see two decimals: 1 x 1 (1) + 3 x 1.25 (3.75) + 1 x 2 (2)
# + 7 x 0.1 (0.70) + 1 x 5 (5) = 12.45.
_fc_put "$FC_W" msg_B11 "$FCT0" m-dec 1 3 1 7 1
# Total 1000+1250+2000+100+5000+2500+500+500+200+100+12.45 = 13162.45 over eleven responses.
# Against a cap of 0.01M (10000 tokens) each percent is tokens / 100.
FCCFG="$FC/r2" FCCAP=0.01 _fc --tsv --by model
is  "felix cost weighs an input token at 1" \
    "$(_fc_row model m-in)" "$(_fc_exps model m-in 1000.00 10.0 1)"
is  "felix cost weighs a 5-minute cache write at 1.25" \
    "$(_fc_row model m-c5)" "$(_fc_exps model m-c5 1250.00 12.5 1)"
is  "felix cost weighs a 1-hour cache write at 2" \
    "$(_fc_row model m-c1h)" "$(_fc_exps model m-c1h 2000.00 20.0 1)"
is  "felix cost weighs a cache read at 0.1" \
    "$(_fc_row model m-cr)" "$(_fc_exps model m-cr 100.00 1.0 1)"
is  "felix cost weighs an output token at 5" \
    "$(_fc_row model m-out)" "$(_fc_exps model m-out 5000.00 50.0 1)"
is  "felix cost counts cache_creation_input_tokens as 5-minute writes when cache_creation is absent" \
    "$(_fc_row model m-nocc)" "$(_fc_exps model m-nocc 2500.00 25.0 1)"
is  "felix cost ignores cache_creation_input_tokens when cache_creation is present" \
    "$(_fc_row model m-ccp)" "$(_fc_exps model m-ccp 500.00 5.0 1)"
is  "felix cost reads a null count, and a count that is missing, as 0" \
    "$(_fc_row model m-null)" "$(_fc_exps model m-null 500.00 5.0 1)"
is  "felix cost reads a 5-minute write missing from cache_creation as 0 and uses its 1-hour field" \
    "$(_fc_row model m-ccmiss)" "$(_fc_exps model m-ccmiss 200.00 2.0 1)"
is  "felix cost reads a 1-hour write missing from cache_creation as 0 and uses its 5-minute field" \
    "$(_fc_row model m-cc5only)" "$(_fc_exps model m-cc5only 100.00 1.0 1)"
is  "felix cost prints a weight that has two decimals exactly: tokens are printed to the hundredth" \
    "$(_fc_row model m-dec)" "$(_fc_exps model m-dec 12.45 0.1 1)"
is  "felix cost --by model: the model rows are ordered by tokens, largest first, ties by key" \
    "$(_fc_rows model | awk -F'\t' '{ printf "%s%s", s, $2; s = " " }')" \
    "m-out m-nocc m-c1h m-c5 m-in m-ccp m-null m-ccmiss m-cc5only m-cr m-dec"
is  "felix cost: the total of eleven weighed responses is their sum, as a percent of a 0.01M cap" \
    "$(_fc_row total all)" "$(_fc_exps total all 13162.45 131.6 11)"

# ======================================================================
# iterations is never read; the key order inside usage does not matter.
# ======================================================================
_fc_mk r3
FC_IT='{"input_tokens":9999999,"output_tokens":9999999,"cache_read_input_tokens":9999999,"cache_creation_input_tokens":9999999,"cache_creation":{"ephemeral_5m_input_tokens":9999999,"ephemeral_1h_input_tokens":9999999},"type":"message"}'
FC_I="$FC/r3/projects/-Users-dev-iter/s1.jsonl"; mkdir -p "$(dirname "$FC_I")"
# Top level: input 100, output 10 -> 100 + 50 = 150; iterations hold 9999999 of everything, twice.
_fc_rec msg_C1 "$FCT0" m-it1 '{"input_tokens":100,"cache_creation_input_tokens":0,"cache_read_input_tokens":0,"output_tokens":10,"cache_creation":{"ephemeral_5m_input_tokens":0,"ephemeral_1h_input_tokens":0},"iterations":['"$FC_IT,$FC_IT"']}' >> "$FC_I"
# output_tokens_details first: 200 + 80 x 1.25 (100) + 500 x 0.1 (50) + 20 x 5 (100) = 450.
_fc_rec msg_C2 "$FCT0" m-ko1 '{"output_tokens_details":null,"input_tokens":200,"cache_creation_input_tokens":80,"cache_read_input_tokens":500,"output_tokens":20,"cache_creation":{"ephemeral_5m_input_tokens":80,"ephemeral_1h_input_tokens":0},"iterations":['"$FC_IT"']}' >> "$FC_I"
# The same counts in the reverse order, cache_creation's own fields reversed too, 450.
_fc_rec msg_C3 "$FCT0" m-ko2 '{"output_tokens":20,"cache_read_input_tokens":500,"iterations":['"$FC_IT"'],"cache_creation":{"ephemeral_1h_input_tokens":0,"ephemeral_5m_input_tokens":80},"cache_creation_input_tokens":80,"input_tokens":200}' >> "$FC_I"
# iterations written BEFORE the top-level counts: input 1000 and nothing else = 1000.
_fc_rec msg_C4 "$FCT0" m-it2 '{"iterations":['"$FC_IT"'],"input_tokens":1000,"output_tokens":0,"cache_read_input_tokens":0,"cache_creation_input_tokens":0,"cache_creation":{"ephemeral_5m_input_tokens":0,"ephemeral_1h_input_tokens":0}}' >> "$FC_I"
FCCFG="$FC/r3" _fc --tsv --by model
is  "felix cost never counts usage.iterations: the top level alone is weighed (iterations after the counts)" \
    "$(_fc_row model m-it1)" "$(_fc_exps model m-it1 150.00 0.0 1)"
is  "felix cost never counts usage.iterations: nor when iterations is written before the top-level counts" \
    "$(_fc_row model m-it2)" "$(_fc_exps model m-it2 1000.00 0.0 1)"
is  "felix cost weighs a usage with output_tokens_details first the same as any other order" \
    "$(_fc_row model m-ko1)" "$(_fc_exps model m-ko1 450.00 0.0 1)"
is  "felix cost weighs a usage with its keys, and cache_creation's keys, in reverse order the same" \
    "$(_fc_row model m-ko2)" "$(_fc_exps model m-ko2 450.00 0.0 1)"
is  "felix cost: four responses with iterations and shuffled keys total 2050 over 4 calls" \
    "$(_fc_row total all)" "$(_fc_exps total all 2050.00 0.0 4)"

# ======================================================================
# The record's time is its own top-level timestamp, the one after its uuid, not
# a timestamp sitting in its content.
# ======================================================================
_fc_mk r3b
FC_TS="$FC/r3b/projects/-Users-dev-ts/s1.jsonl"; mkdir -p "$(dirname "$FC_TS")"
# A tool call whose input holds a uuid and a timestamp of its own, dated long before the window.
_fc_rec msg_Y1 "$FCT0" m-tsnest "$(_fc_use 700 0 0 0 0)" \
  '[{"type":"tool_use","id":"toolu_1","name":"Run","input":{"uuid":"nested","timestamp":"2020-01-01T00:00:00.000Z"}}]' > "$FC_TS"
# The reverse: the record is dated before the window and its content holds an in-window time.
_fc_rec msg_Y2 2026-10-01T00:00:00.000Z m-tsout "$(_fc_use 900 0 0 0 0)" \
  '[{"type":"tool_use","id":"toolu_2","name":"Run","input":{"uuid":"nested","timestamp":"2026-10-09T10:00:00.000Z"}}]' >> "$FC_TS"
FCCFG="$FC/r3b" _fc --tsv
is  "felix cost dates a record by its top-level timestamp: one whose content holds an earlier uuid and timestamp still counts" \
    "$(_fc_row model m-tsnest)" "$(_fc_exps model m-tsnest 700.00 0.0 1)"
is  "felix cost dates a record by its top-level timestamp: one dated before the window does not count for a time in its content" \
    "$(_fc_absent model m-tsout)" "absent"
is  "felix cost: the one counted record is dated 2026-10-09" \
    "$(_fc_rows day | awk -F'\t' '{ printf "%s%s=%s", s, $2, $3; s = " " }')" "2026-10-09=700.00"

# ======================================================================
# Once per response: the last line of an id wins within a file, and an id
# counts once across files.
# ======================================================================
_fc_mk r4
FC_G="$FC/r4/projects/-Users-dev-grow/s1.jsonl"
_fc_put "$FC_G" msg_G1 "$FCT0" m-g1  100 0 0 0 10      # one line per content block, usage so far
_fc_put "$FC_G" msg_G2 "$FCT0" m-g2 4000 0 0 0 0
_fc_put "$FC_G" msg_G1 "$FCT0" m-g1  100 0 0 0 50
_fc_put "$FC_G" msg_G3 "$FCT0" m-g3    0 0 0 0 300     # a last line with less than an earlier one
_fc_put "$FC_G" msg_G1 "$FCT0" m-g1  100 0 0 0 200     # last for G1: 100 + 200 x 5 = 1100
_fc_put "$FC_G" msg_G3 "$FCT0" m-g3    0 0 0 0 20      # last for G3: 20 x 5 = 100
FCCFG="$FC/r4" _fc --tsv
is  "felix cost: of an id repeated in one file with growing usage, the last line's usage counts, once" \
    "$(_fc_row model m-g1)" "$(_fc_exps model m-g1 1100.00 0.0 1)"
is  "felix cost: an id written once among the repeats of another is counted as it is" \
    "$(_fc_row model m-g2)" "$(_fc_exps model m-g2 4000.00 0.0 1)"
is  "felix cost: the last line of an id wins even when an earlier line of it carried more" \
    "$(_fc_row model m-g3)" "$(_fc_exps model m-g3 100.00 0.0 1)"
is  "felix cost: six lines of three ids are three calls and the sum of the last lines" \
    "$(_fc_row total all)" "$(_fc_exps total all 5200.00 0.0 3)"

_fc_mk r5
FC_PR="$FC/r5/projects"
_fc_in "$FC_PR/-Users-dev-e1/s1.jsonl" msg_F1 "$FCT0" m-f 1000
_fc_in "$FC_PR/-Users-dev-e1/s1.jsonl" msg_F2 "$FCT0" m-f 2000
# A fork copies those two lines into a new file and adds one of its own.
_fc_in "$FC_PR/-Users-dev-e2/s2.jsonl" msg_F1 "$FCT0" m-f 1000
_fc_in "$FC_PR/-Users-dev-e2/s2.jsonl" msg_F2 "$FCT0" m-f 2000
_fc_in "$FC_PR/-Users-dev-e2/s2.jsonl" msg_F3 "$FCT0" m-f 4000
# Two files of one record directory holding the same response.
_fc_in "$FC_PR/-Users-dev-e3/a.jsonl" msg_H1 "$FCT0" m-f 3000
_fc_in "$FC_PR/-Users-dev-e3/b.jsonl" msg_H1 "$FCT0" m-f 3000
# A response in a session file and again in its helper agent's file.
_fc_in "$FC_PR/-Users-dev-e4/s1.jsonl" msg_J1 "$FCT0" m-f 500
_fc_in "$FC_PR/-Users-dev-e4/s1/subagents/a.jsonl" msg_J1 "$FCT0" m-f 500
# Distinct responses: F1 1000 + F2 2000 + F3 4000 + H1 3000 + J1 500 = 10500, five calls, six files.
FCCFG="$FC/r5" _fc --tsv
is  "felix cost: an id found in two files, a fork's copy, is counted once: five distinct ids, 10500 tokens" \
    "$(_fc_row total all)" "$(_fc_exps total all 10500.00 0.0 5)"
is  "felix cost: every file is still read, though its repeated ids are not counted twice" \
    "$(_fc_cover files_read)" "6"
is  "felix cost: an id in two files of one record directory is that directory's, once" \
    "$(_fc_row worktree -Users-dev-e3)" "$(_fc_exps worktree -Users-dev-e3 3000.00 0.0 1)"
is  "felix cost: an id in a session file and in its helper agent's file is the directory's, once" \
    "$(_fc_row worktree -Users-dev-e4)" "$(_fc_exps worktree -Users-dev-e4 500.00 0.0 1)"
is  "felix cost: the worktree rows add up to the total, so a forked id sits under one directory" \
    "$(_fc_rows worktree | awk -F'\t' '{ s += $3; n += $5 } END { printf "%.2f %d", s, n }')" "10500.00 5"
is  "felix cost: the model row counts each of the five ids once" \
    "$(_fc_row model m-f)" "$(_fc_exps model m-f 10500.00 0.0 5)"

# ======================================================================
# Where it reads: exactly <E>/*.jsonl and every *.jsonl under
# <E>/<sid>/subagents/. Restated after the blind round, not blind: the contract
# was amended on 2026-10-11 to read a workflow's agents in
# subagents/workflows/<run>/ (222 of the week's 626 real transcripts), so the
# deeper file below moved from "never read" to read, and a deeper file outside
# subagents/ took its place as the case that is never read.
# ======================================================================
_fc_fixture r6
FCCFG="$FC/r6" _fc --tsv
is  "felix cost reads <E>/*.jsonl, a session transcript, and every *.jsonl under <E>/<sid>/subagents/, a helper agent's" \
    "$(_fc_rows model | awk -F'\t' '{ printf "%s%s=%s", s, $2, $3; s = " " }')" "m-ses=5000.00 m-sub=2000.00 m-wf=500.00"
is  "felix cost counts a helper agent's file under <E>/<sid>/subagents/, and a workflow agent's under subagents/workflows/<run>/, to <E>" \
    "$(_fc_row worktree -Users-dev-l1)" "$(_fc_exps worktree -Users-dev-l1 3500.00 0.0 3)"
is  "felix cost: the files it read are the four it should: files_read 4" "$(_fc_cover files_read)" "4"
is  "felix cost does not read a .jsonl directly under the records root" "$(_fc_absent model m-root)" "absent"
is  "felix cost does not read <E>/<sid>/x.jsonl" "$(_fc_absent model m-sid)" "absent"
is  "felix cost does not read <E>/<sid>/other/x.jsonl" "$(_fc_absent model m-other)" "absent"
is  "felix cost does not read a file nested deeper under <E>/<sid>/ outside subagents/" "$(_fc_absent model m-deeper)" "absent"
is  "felix cost does not read a file without the .jsonl suffix" "$(_fc_absent model m-txt)" "absent"
is  "felix cost does not read a file whose name only contains .jsonl" "$(_fc_absent model m-bak)" "absent"
is  "felix cost: a directory named *.jsonl is no regular file, so it is neither read nor counted unread" \
    "$(_fc_cover files_unread) $(_fc_cover coverage)" "0 measured"
is  "felix cost: only what it read is in the total, 7500 over four calls" \
    "$(_fc_row total all)" "$(_fc_exps total all 7500.00 0.0 4)"
is  "felix cost: worktree rows are the record directories, largest first" \
    "$(_fc_rows worktree | awk -F'\t' '{ printf "%s%s", s, $2; s = " " }')" "-Users-dev-l2 -Users-dev-l1"

# ======================================================================
# A file modified before the window start is not read.
# ======================================================================
_fc_mk r7
FC_P="$FC/r7/projects"
_fc_in "$FC_P/-Users-dev-old/old.jsonl" msg_P1 "$FCT0" m-old 8000
touch -t 202609010000 "$FC_P/-Users-dev-old/old.jsonl"
_fc_in "$FC_P/-Users-dev-edge/edge.jsonl" msg_P2 "$FCT0" m-edge 1000
TZ=UTC touch -t 202610081300.00 "$FC_P/-Users-dev-edge/edge.jsonl"      # modified at the very second the week opens
_fc_in "$FC_P/-Users-dev-before/before.jsonl" msg_P3 "$FCT0" m-before 2000
TZ=UTC touch -t 202610081259.00 "$FC_P/-Users-dev-before/before.jsonl"  # a minute before it
_fc_in "$FC_P/-Users-dev-new/new.jsonl" msg_P4 "$FCT0" m-new 4000
_fc_in "$FC_P/-Users-dev-new/s/subagents/oldsub.jsonl" msg_P5 "$FCT0" m-oldsub 16000
touch -t 202609010000 "$FC_P/-Users-dev-new/s/subagents/oldsub.jsonl"
# Each old file holds a response dated inside the week, so reading it would show.
FCCFG="$FC/r7" _fc --tsv
is  "felix cost does not read a transcript last modified long before the window start, though it holds an in-window record" \
    "$(_fc_absent model m-old)" "absent"
is  "felix cost does not read a helper agent's file last modified before the window start" \
    "$(_fc_absent model m-oldsub)" "absent"
is  "felix cost does not read a file modified one minute before the window start" \
    "$(_fc_absent model m-before)" "absent"
is  "felix cost reads a file modified at exactly the window start" \
    "$(_fc_row model m-edge)" "$(_fc_exps model m-edge 1000.00 0.0 1)"
is  "felix cost reads a file modified after the window start" \
    "$(_fc_row model m-new)" "$(_fc_exps model m-new 4000.00 0.0 1)"
is  "felix cost: files_read counts only the files it read, 2 of the 5" "$(_fc_cover files_read)" "2"
is  "felix cost: the total of the files it read is 5000 over two calls" \
    "$(_fc_row total all)" "$(_fc_exps total all 5000.00 0.0 2)"
FCCFG="$FC/r7" FCTZ=Pacific/Auckland _fc --tsv
is  "felix cost prunes by the window start in UTC under another zone: the file modified at the start is read, the one a minute before is not" \
    "$(_fc_cover files_read)|$(_fc_absent model m-before)|$(_fc_row model m-edge)" "2|absent|$(_fc_exps model m-edge 1000.00 0.0 1)"
FCCFG="$FC/r7" _fc --tsv --since 2026-08-01
is  "felix cost --since an earlier day reads the older files too, so the prune follows the window start: 5 files, 31000" \
    "$(_fc_cover files_read) $(_fc_row total all)" "5 $(_fc_exps total all 31000.00 0.0 5)"

# ======================================================================
# What does not count.
# ======================================================================
_fc_mk r8
FC_N="$FC/r8/projects/-Users-dev-n/s1.jsonl"; mkdir -p "$(dirname "$FC_N")"
FCU='{"input_tokens":1000000,"output_tokens":0}'
_fc_put "$FC_N" msg_V1 "$FCT0" m-ok 1000 0 0 0 0
# A user record with a usage object in its toolUseResult.
printf '%s\n' '{"parentUuid":"u-0","isSidechain":false,"type":"user","message":{"role":"user","content":[{"tool_use_id":"t1","type":"tool_result","content":"ok"}]},"uuid":"u-n1","timestamp":"2026-10-11T10:00:01.000Z","toolUseResult":{"usage":{"input_tokens":1000000,"output_tokens":1000000}},"sessionId":"s1"}' >> "$FC_N"
# A user record carrying the whole of an assistant record's message, id, model and usage.
_fc_rec msg_U1 "$FCTB" m-user "$FCU" | sed 's/"type":"assistant","uuid"/"type":"user","uuid"/; s/"role":"assistant"/"role":"user"/' >> "$FC_N"
# An attachment and a progress record, each nesting a whole assistant record.
printf '{"type":"attachment","attachment":{"type":"hook_success","message":%s},"uuid":"u-n3","timestamp":"%s","sessionId":"s1"}\n' \
  "$(_fc_rec msg_N1 "$FCTB" m-attach "$FCU")" "$FCTB" >> "$FC_N"
printf '{"type":"progress","data":{"message":%s,"type":"agent_progress"},"uuid":"u-n5","timestamp":"%s","sessionId":"s1"}\n' \
  "$(_fc_rec msg_N2 "$FCTB" m-progress "$FCU")" "$FCTB" >> "$FC_N"
# A system record in the assistant record's own shape.
_fc_rec msg_N3 "$FCTB" m-system "$FCU" | sed 's/"type":"assistant","uuid"/"type":"system","uuid"/' >> "$FC_N"
# The synthetic model.
_fc_rec msg_N4 "$FCTB" '<synthetic>' "$FCU" >> "$FC_N"
# A line cut off mid-write: one that lost its last brace, and one cut part-way through.
FC_LINE="$(_fc_rec msg_N5 "$FCTB" m-cut1 "$FCU")"
printf '%s\n' "${FC_LINE%\}}" >> "$FC_N"
FC_LINE="$(_fc_rec msg_N6 "$FCTB" m-cut2 "$FCU")"
printf '%s\n' "${FC_LINE:0:100}" >> "$FC_N"
# An assistant-typed record whose message.role is user.
_fc_rec msg_N12 "$FCTB" m-badrole "$FCU" | sed 's/"role":"assistant"/"role":"user"/' >> "$FC_N"
# A response with no message.id, with an empty one, and with a usage that is not an object.
_fc_rec msg_N7 "$FCTB" m-noid "$FCU" | sed 's/"id":"msg_N7",//' >> "$FC_N"
_fc_rec msg_N8 "$FCTB" m-emptyid "$FCU" | sed 's/"id":"msg_N8"/"id":""/' >> "$FC_N"
_fc_rec msg_N9 "$FCTB" m-nousage null >> "$FC_N"
# Lines that are no record at all: blank, prose, an array, an object of another kind.
printf '\nnot json at all\n[1,2,3]\n{"a":1}\n' >> "$FC_N"
# The last line whole but with no newline after it: counted.
printf '%s' "$(_fc_rec msg_V2 "$FCT0" m-nonl "$(_fc_use 2000 0 0 0 0)")" >> "$FC_N"
# A second file ends in a record cut off with no newline.
_fc_put "$FC/r8/projects/-Users-dev-n/s2.jsonl" msg_V3 "$FCT0" m-ok2 4000 0 0 0 0
FC_LINE="$(_fc_rec msg_N10 "$FCTB" m-cutend "$FCU")"
printf '%s' "${FC_LINE:0:$(( ${#FC_LINE} - 20 ))}" >> "$FC/r8/projects/-Users-dev-n/s2.jsonl"
# A record directory holding nothing that counts.
mkdir -p "$FC/r8/projects/-Users-dev-onlybad"
printf '%s\n''{"type":"user","message":{"role":"user","content":"x"},"uuid":"u-x","timestamp":"2026-10-10T10:00:01.000Z","toolUseResult":{"usage":{"input_tokens":5,"output_tokens":5}}}' \
  > "$FC/r8/projects/-Users-dev-onlybad/s1.jsonl"
_fc_rec msg_N11 "$FCTB" '<synthetic>' "$FCU" >> "$FC/r8/projects/-Users-dev-onlybad/s1.jsonl"
FCCFG="$FC/r8" _fc --tsv
is  "felix cost: skipping the lines it does not count is silent, exit 0 with nothing on stderr" "$FCRC:$FCERR" "0:"
is  "felix cost counts only the three whole assistant responses among the rest: 1000 + 2000 + 4000" \
    "$(_fc_row total all)" "$(_fc_exps total all 7000.00 0.0 3)"
is  "felix cost counts a whole last line that has no newline after it" \
    "$(_fc_row model m-nonl)" "$(_fc_exps model m-nonl 2000.00 0.0 1)"
is  "felix cost does not count a user record carrying a usage object in a toolUseResult" \
    "$(_fc_absent day 2026-10-11)" "absent"
is  "felix cost does not count a user record, even one in an assistant record's shape" "$(_fc_absent model m-user)" "absent"
is  "felix cost does not count an attachment record that nests an assistant message" "$(_fc_absent model m-attach)" "absent"
is  "felix cost does not count a progress record that nests an assistant message" "$(_fc_absent model m-progress)" "absent"
is  "felix cost does not count a system record, though its message is an assistant's" "$(_fc_absent model m-system)" "absent"
is  "felix cost does not count the <synthetic> model" "$(_fc_absent model '<synthetic>')" "absent"
is  "felix cost skips a line that lost its last brace" "$(_fc_absent model m-cut1)" "absent"
is  "felix cost skips a line cut off part-way through" "$(_fc_absent model m-cut2)" "absent"
is  "felix cost skips a cut-off last line with no newline" "$(_fc_absent model m-cutend)" "absent"
is  "felix cost does not count a record whose message.role is not assistant" "$(_fc_absent model m-badrole)" "absent"
is  "felix cost does not count a record with no message.id" "$(_fc_absent model m-noid)" "absent"
is  "felix cost does not count a record whose message.id is empty" "$(_fc_absent model m-emptyid)" "absent"
is  "felix cost does not count a record whose usage is not an object" "$(_fc_absent model m-nousage)" "absent"
is  "felix cost: a record directory holding nothing that counts has no worktree row" \
    "$(_fc_absent worktree -Users-dev-onlybad)" "absent"
is  "felix cost: a day with nothing counted has no day row; the one day that has is 2026-10-09" \
    "$(_fc_rows day | awk -F'\t' '{ printf "%s%s", s, $2; s = " " }')" "2026-10-09"

