# >>> lost-work-inventory-chips
printf '\nthe lost-work page, step 6: felix inventory chips from start_session, and what started means (contract A2, A3, B9.13-25, blind)\n'
# Blind, from docs/2026-10-18-lost-work-page-contract.md alone, on the stubs,
# builders and readers of tests/lib/lost-work.sh (part 1450's when written).
# Repository ch; every proposal is made from sessions filed under its main
# worktree. Two records roots: hc0 holds the proposing sessions only, so every
# chip they propose is shown to exist (the control run CH0); hc1 is a copy of
# hc0, mtimes kept, plus the
# sessions that start some of them (CH1). Proposals are 600 minutes old, the
# starting sessions 300, so each starter is modified after the proposal; the
# two expiry chips are 170 hours old, inside the default 14-day window.
_lw_build
_lw_repo ch; CH="$LW/ch"; CHR="$(_lw_mainwt "$CH")"
_lwg "$CH" worktree add -q -b q25 "$LW/ch-q25" main >/dev/null 2>&1
_lwg "$CH" worktree add -q -b q25c "$LW/ch-q25c" main >/dev/null 2>&1
LW_RR="$LW/hc0/.claude/projects"; mkdir -p "$LW_RR"
LWS_A=c0c0c0c0-0000-4000-8000-00000000000a; LWS_B=c0c0c0c0-0000-4000-8000-00000000000b
LWS_C=c0c0c0c0-0000-4000-8000-00000000000c; LWS_D=c0c0c0c0-0000-4000-8000-00000000000d
LWS_E=c0c0c0c0-0000-4000-8000-00000000000e
LWP13="$(_lw_p 'Thirteen: make the loader name the file it read, and test that two files give two names.' 130)"
LWP14="$(_lw_p 'Fourteen: make the writer sort its keys, and test two runs over one input give one file.' 130)"
LWP15="$(_lw_p 'Fifteen: make the cache expire its entries by age, and test one entry past its age.' 130)"
LWP16="$(_lw_p 'Sixteen: make the parser accept a trailing comma in lists, and add one test for it.' 130)"
LWP17="$(_lw_p 'Seventeen: rename the config loader so it says what it loads, and keep an alias.' 130)"
LWP18="$(_lw_p 'Eighteen: give the scheduler a dry run that prints the jobs and starts none of them.' 130)"
LWP18B="$(_lw_p 'Eighteen b: make the export write rows in a stable order, and test it twice in a row.' 130)"
LWP19="$(_lw_p 'Nineteen: make the retry budget a setting, and assert the default stays at three.' 130)"
LWP20="$(_lw_p 'Twenty: teach the report to name the file each total came from, with a two-file test.' 130)"
LWP20C="$(_lw_p 'Twenty control: make the sorter stable, and test equal keys over two inputs.' 130)"
LWP21="$(_lw_p 'Twenty-one: log each retry once, and test the count the log reports at the end.' 130)"
LWP22='Twenty-two: drop the unused flag from the CLI.'
LWP23="$(_lw_p 'Twenty-three: split the long module in two along the reader and writer seam.' 130)"
LWP23B="$(_lw_p 'Twenty-three b: make the help text list the commands in the order they run.' 130)"
LWP23C="$(_lw_p 'Twenty-three c: make the watcher stop on a second interrupt, with a test.' 130)"
LWP24="$(_lw_p 'Twenty-four: make the lock name the process that holds it, with a test.' 130)"
LWP24B="$(_lw_p 'Twenty-four b: make the gate print its slowest part, with a test of the line.' 130)"
# A start_session proposal: MIN TOOL-ID INPUT-JSON RESULT-TEXT
_lw_start() { _lw_tu "$1" "$2" mcp__ccd_session__start_session "$3"; _lw_tr "$1" "$2" "$4"; }
LWOK='The user sees a card and nothing runs until they start it.'
# s-a: start_session proposals in every input form, a dismissal, a denied
# spawn_task and one with no result recorded.
_lw_sess "$CHR" "$LWS_A"; _lw_h 612 'file the follow-ups'
printf -v _lwi '{"initiation":"own_initiative","title":"Chip thirteen","prompt":"%s"}' "$LWP13"
_lw_start 610 toolu_13 "$_lwi" "Proposed (task_id: task_13131313). $LWOK"
printf -v _lwi '{"title":"Chip fourteen","prompt":"%s","initiation":"own_initiative"}' "$LWP14"
_lw_start 609 toolu_14 "$_lwi" "Proposed (task_id: task_14141414). $LWOK"
printf -v _lwi '{"initiation":"user_asked","title":"Chip fourteen asked","prompt":"%s"}' "$LWP14"
_lw_start 609 toolu_14b "$_lwi" "Started (task_id: task_14b14b14)."
printf -v _lwi '{"initiation":"offer","title":"Chip fourteen offered"}'
_lw_start 609 toolu_14c "$_lwi" "Offered (task_id: task_14c14c14)."
printf -v _lwi '{"initiation":"own_initiative","proposal_id":"task_99999999","title":"Chip fourteen started","prompt":"%s"}' "$LWP14"
_lw_start 609 toolu_14d "$_lwi" "Started (task_id: task_14d14d14)."
printf -v _lwi '{"initiation":"own_initiative","title":"Chip fifteen","prompt":"%s"}' "$LWP15"
_lw_start 608 toolu_15 "$_lwi" "Proposed (task_id: task_15151515). Also still waiting: task_7d7cee05 \\\"Another card\\\""
printf -v _lwi '{"initiation":"own_initiative","title":"Chip seventeen","prompt":"%s"}' "$LWP17"
_lw_start 607 toolu_17 "$_lwi" "Proposed (task_id: task_17171717). $LWOK"
_lw_tu 606 toolu_17d mcp__ccd_session__dismiss_task '{"task_id":"task_17171717","reason":"fixed in this session"}'
_lw_tr 606 toolu_17d 'Dismissed.'
printf -v _lwi '{"title":"Chip nineteen denied","prompt":"%s","tldr":"x"}' "$LWP19"
_lw_tu 605 toolu_19den mcp__ccd_session__spawn_task "$_lwi"
_lw_tr 605 toolu_19den 'Permission to use mcp__ccd_session__spawn_task has been denied.'
printf -v _lwi '{"title":"Chip nineteen unanswered","prompt":"%s","tldr":"x"}' "$LWP19"
_lw_tu 604 toolu_19none mcp__ccd_session__spawn_task "$_lwi"
_lw_a 600 'Filed.'; _lw_age "$LW_F" 600
# s-b: one start_session proposal in a file that names spawn_task nowhere,
# whose records hold "task" only in the result.
_lw_sess "$CHR" "$LWS_B"; _lw_h 612 'note it'
printf -v _lwi '{"initiation":"own_initiative","title":"Free of the word","prompt":"%s"}' "$LWP16"
_lw_start 610 toolu_16free "$_lwi" "Proposed (task_id: task_16161616). $LWOK"
_lw_a 600 'Noted.'; _lw_age "$LW_F" 600
# s-c: a start_session and a spawn_task proposal, both 170 hours old.
_lw_sess "$CHR" "$LWS_C"; _lw_h 10212 'file the old ones'
printf -v _lwi '{"initiation":"own_initiative","title":"Chip eighteen card","prompt":"%s"}' "$LWP18"
_lw_start 10210 toolu_18 "$_lwi" "Proposed (task_id: task_18181818). $LWOK"
_lw_spawn 10210 toolu_18b task_18b18b18 'Chip eighteen spawn' "$LWP18B"
_lw_a 10200 'Filed.'; _lw_age "$LW_F" 10200
# s-d: spawn_task proposals the starters below start, or do not. Its own
# custom-title names chip 23b.
_lw_sess "$CHR" "$LWS_D"; _lw_h 612 'file the rest'
_lw_spawn 610 toolu_20 task_20202020 'Chip twenty' "$LWP20"
_lw_spawn 610 toolu_20c task_20c20c20 'Chip twenty control' "$LWP20C"
_lw_spawn 610 toolu_22 task_22222222 'Chip twenty-two' "$LWP22"
_lw_spawn 610 toolu_23 task_23232323 'Chip twenty-three by title' "$LWP23"
_lw_spawn 610 toolu_23b task_23b23b23 'Chip twenty-three own title' "$LWP23B"
_lw_spawn 610 toolu_23c task_23c23c23 'Chip twenty-three near title' "$LWP23C"
_lw_spawn 610 toolu_24 task_24242424 'Chip twenty-four' "$LWP24"
_lw_spawn 610 toolu_24b task_24b24b24 'Chip twenty-four unanswered' "$LWP24B"
_lw_title 'Chip twenty-three own title'
_lw_a 600 'Filed.'; _lw_age "$LW_F" 600
# s-e: a start_session proposal the framed starter starts.
_lw_sess "$CHR" "$LWS_E"; _lw_h 612 'one more'
printf -v _lwi '{"initiation":"own_initiative","title":"Chip twenty-one","prompt":"%s"}' "$LWP21"
_lw_start 610 toolu_21 "$_lwi" "Proposed (task_id: task_21212121). $LWOK"
_lw_a 600 'Filed.'; _lw_age "$LW_F" 600
# B9.25's worktrees: each session's last assistant text asks; q25's is
# answered in the two-item reminder form, q25c's is not answered.
_lw_sess "$LW/ch-q25" c0c0c0c0-0000-4000-8000-000000000025; _lw_h 402 'get it ready'
_lw_a 400 'It is ready. Should I push?'; _lw_h2 398 'yes, push it'; _lw_age "$LW_F" 398
_lw_sess "$LW/ch-q25c" c0c0c0c0-0000-4000-8000-0000000025cc; _lw_h 402 'get it ready'
_lw_a 400 'It is ready. Should I push?'; _lw_age "$LW_F" 400

# hc1: hc0, plus the starters.
mkdir -p "$LW/hc1"; cp -Rp "$LW/hc0/." "$LW/hc1/"
LW_RR="$LW/hc1/.claude/projects"
_lw_open "$LW_RR/-elsewhere-s20/s20.jsonl" c0c0c0c0-0000-4000-8000-000000000s20
_lw_h2 302 "$LWP20"; _lw_a 301 'On it.'
_lw_h 300 'This session is being continued from a previous conversation that ran out of context.'; _lw_age "$LW_F" 300
_lw_open "$LW_RR/-elsewhere-s20c/s20c.jsonl" c0c0c0c0-0000-4000-8000-00000000s20c
printf -v _lwi '[{"type":"text","text":"<system-reminder>r</system-reminder>"},{"type":"text","text":"%s"}]' "$LWP20C"
_lw_u 302 "$_lwi"; _lw_a 300 'On it.'; _lw_age "$LW_F" 300
_lw_open "$LW_RR/-elsewhere-s21/s21.jsonl" c0c0c0c0-0000-4000-8000-000000000s21
_lw_h 302 "Background (from the session that started this one):\\nThe loader work is done; the retry log is next.\\n\\nTask:\\n$LWP21\\n\\nShared notes folder for this group of sessions is the notes directory."
_lw_a 300 'On it.'; _lw_age "$LW_F" 300
_lw_open "$LW_RR/-elsewhere-s22/s22.jsonl" c0c0c0c0-0000-4000-8000-000000000s22
_lw_h 302 "$LWP22 And then say so in the changelog."; _lw_a 300 'On it.'; _lw_age "$LW_F" 300
_lw_open "$LW_RR/-elsewhere-s23/s23.jsonl" c0c0c0c0-0000-4000-8000-000000000s23
_lw_title 'Chip twenty-three by title'; _lw_h 302 'look at something unrelated'; _lw_a 300 'Done.'; _lw_age "$LW_F" 300
_lw_open "$LW_RR/-elsewhere-s23c/s23c.jsonl" c0c0c0c0-0000-4000-8000-00000000s23c
_lw_title 'Chip twenty-three near titlE'; _lw_h 302 'look at another unrelated thing'; _lw_a 300 'Done.'; _lw_age "$LW_F" 300
_lw_open "$LW_RR/-elsewhere-s24/s24.jsonl" c0c0c0c0-0000-4000-8000-000000000s24
_lw_h 303 'start the card'; _lw_tu 302 toolu_24go mcp__ccd_session__start_session '{"proposal_id":"task_24242424"}'
_lw_tr 301 toolu_24go 'Started.'; _lw_a 300 'Started it.'; _lw_age "$LW_F" 300
_lw_open "$LW_RR/-elsewhere-s24b/s24b.jsonl" c0c0c0c0-0000-4000-8000-00000000s24b
_lw_h 303 'start the other card'; _lw_tu 302 toolu_24no mcp__ccd_session__start_session '{"proposal_id":"task_24b24b24"}'
_lw_a 300 'Asked.'; _lw_age "$LW_F" 300

is "A2 fixture: s-b names spawn_task nowhere, and its proposal record holds task nowhere (fixture control)" \
   "$(LC_ALL=C grep -c 'spawn_task' "$LW/hc0/.claude/projects/$(_lw_enc "$CHR")/$LWS_B.jsonl") $(LC_ALL=C grep 'toolu_16free' "$LW/hc0/.claude/projects/$(_lw_enc "$CHR")/$LWS_B.jsonl" | LC_ALL=C grep -v tool_result | LC_ALL=C grep -c task)" "0 0"
is "A3 fixture: the s20 starter's first user record is two text items, the first ending in a reminder and a blank line (fixture control)" \
   "$(LC_ALL=C awk 'index($0, "\"type\":\"user\"") { print (index($0, "</system-reminder>\\n\\n\"},{\"type\":\"text\",\"text\":\"Twenty: ") ? "two-item" : "other"); exit }' "$LW/hc1/.claude/projects/-elsewhere-s20/s20.jsonl")" "two-item"

_lw_run CH0 "$LW/hc0" "$LW/cwd" inventory --repo "$CH" --tsv --no-gh
_lw_run CH1 "$LW/hc1" "$LW/cwd" inventory --repo "$CH" --tsv --no-gh
C0="$(_lw_o CH0)"; C1="$(_lw_o CH1)"
is "A2: both inventory runs over ch exit 0, and each lists a chip (control)" \
   "$(_lw_rc CH0)$(_lw_rc CH1) $(_lw_kind "$C0" task_20202020) $(_lw_kind "$C1" task_23b23b23)" "00 chip chip"
# B9.13
is "B9.13: a start_session with initiation own_initiative and a task id in its result is a chip: its states, title as detail, proposing session as owner" \
   "$(_lw_st "$C1" chip task_13131313) | $(_lw_col "$C1" chip task_13131313 8) | $(_lw_col "$C1" chip task_13131313 5)" \
   "chip-unstarted | Chip thirteen | $LWS_A"
# B9.14
is "B9.14: initiation after title and prompt is still a chip; user_asked, offer and proposal_id make none" \
   "$(_lw_kind "$C1" task_14141414) $(_lw_kind "$C1" task_14b14b14) $(_lw_kind "$C1" task_14c14c14) $(_lw_kind "$C1" task_14d14d14)" "chip none none none"
# B9.15
is "B9.15: the result's task id is a chip, and a card the result says is still waiting makes no row" \
   "$(_lw_kind "$C1" task_15151515) $(_lw_kind "$C1" task_7d7cee05)" "chip none"
# B9.16
is "B9.16: a proposal whose record holds task nowhere outside its result, in a file naming spawn_task nowhere, is a chip" \
   "$(_lw_st "$C1" chip task_16161616)" "chip-unstarted"
# B9.17
is "B9.17: dismiss_task naming a start_session chip's id removes it, while an undismissed one stays" \
   "$(_lw_kind "$C1" task_17171717) $(_lw_kind "$C1" task_13131313)" "none chip"
# B9.18
is "B9.18: a start_session chip 168 hours old or more has the detail element card expired, and a spawn_task chip of the same age none" \
   "$(_lw_elem "$C1" chip task_18181818 'card expired') $(_lw_elem "$C1" chip task_18b18b18 'card expired')" "yes no"
# B9.19
is "B9.19: a spawn_task with no tool_result in its file is a row whose ref is the tool_use id, states unknown:chip-unstarted" \
   "$(_lw_kind "$C1" toolu_19none) | $(_lw_st "$C1" chip toolu_19none)" "chip | unknown:chip-unstarted"
_lwo="$(_lw_col "$C1" chip toolu_19none 8)"
case "$_lwo" in
  'Chip nineteen unanswered'*'no result recorded for the proposal') ok "B9.19: its detail is the title, ending no result recorded for the proposal" ;;
  *) bad "B9.19: its detail is the title, ending no result recorded for the proposal" "detail [$_lwo]" ;;
esac
is "B9.19: a spawn_task whose result says the permission was denied makes no row" "$(_lw_kind "$C1" toolu_19den) $(_lw_kind "$C1" toolu_19none)" "none chip"
# B9.20
is "B9.20: a chip whose starter's first user record is the two-item reminder form is started: a row before, none after" \
   "$(_lw_st "$C0" chip task_20202020) | $(_lw_kind "$C1" task_20202020)" "chip-unstarted | none"
is "B9.20: the same with the reminder not ending in a blank line (control)" \
   "$(_lw_st "$C0" chip task_20c20c20) | $(_lw_kind "$C1" task_20c20c20)" "chip-unstarted | none"
# B9.21
is "B9.21: a start_session chip whose starter's first text is framed by Background and Task is started" \
   "$(_lw_st "$C0" chip task_21212121) | $(_lw_kind "$C1" task_21212121)" "chip-unstarted | none"
# B9.22
is "B9.22: a prompt shorter than 120 characters, started by a text that goes on after it, is started" \
   "$(_lw_st "$C0" chip task_22222222) | $(_lw_kind "$C1" task_22222222)" "chip-unstarted | none"
# B9.23
is "B9.23: a custom-title equal to the chip's title, in another file modified after, starts it; the first text is unrelated" \
   "$(_lw_st "$C0" chip task_23232323) | $(_lw_kind "$C1" task_23232323)" "chip-unstarted | none"
is "B9.23: the same title only in the proposer's own file starts nothing, nor a title one character off, while the exact title does" \
   "$(_lw_kind "$C1" task_23232323) $(_lw_st "$C1" chip task_23b23b23) $(_lw_st "$C1" chip task_23c23c23)" "none chip-unstarted chip-unstarted"
# B9.24
is "B9.24: a start_session carrying the chip's id as proposal_id, with a result, starts it" \
   "$(_lw_st "$C0" chip task_24242424) | $(_lw_kind "$C1" task_24242424)" "chip-unstarted | none"
is "B9.24: the same call with no result in its file does not, while the one with a result does" "$(_lw_kind "$C1" task_24242424) $(_lw_st "$C1" chip task_24b24b24)" "none chip-unstarted"
# B9.25
is "B9.25: a session whose last assistant text asks, answered in the two-item reminder form, is not question" \
   "$(_lw_many "$C1" worktree "$LW/ch-q25" 0 question unknown:question)" "question=no unknown:question=no"
is "B9.25: the same session left unanswered is question (control)" "$(_lw_holds "$C1" worktree "$LW/ch-q25c" question)" yes
# <<< lost-work-inventory-chips
