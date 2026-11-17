# >>> inventory-true-owners
printf '\naudit b09: true owners past SDK sessions, and a records root the run cannot read is unknown (C028, C047: A1-A26, A42-A49, blind)\n'
# Blind, written on 2026-10-24 from docs/2026-10-24-audit-fixes/b09-inventory-speed-and-true-owners.md
# alone (sections 2 and 4); felix was run as a black box and no engine code was read. The stubs, the
# runner and the TSV readers are tests/lib/lost-work.sh's (_lw_build); every fixture here is this
# part's own, under $LW, so it runs alone and in the serial order.
#
# tw9 (C028): worktrees whose record directories hold a person's session and a plugin's SDK session
# (a security reviewer, "entrypoint":"sdk-py"), filed after it; a desktop session that only quotes an
# SDK entrypoint; sessions with no entrypoint at all; an unreadable newer session file; and pull
# requests whose heads are named by person and SDK records. uw9 (C047): one repository read under
# records roots at modes 000, 100 and 400, a missing one, CLAUDE_CONFIG_DIR's at 000, and a readable
# root with one record directory at 000. Every mode set here is set back before the assertions.
_lw_build
T9Q='Review this change for security vulnerabilities.'
T9ASK='Fixed and committed. Should I merge #12?'
T9_CWD=""
# _t9_as EP BR WRITER ARGS...: WRITER's records (_lw_h, _lw_a, _lw_tu or _lw_tr), each with
# ,"gitBranch":"BR" after its version unless BR is -, and ,"entrypoint":"EP","cwd":"$T9_CWD" before
# its final } unless EP is - (sdk-py makes an SDK record, claude-desktop a desktop one).
_t9_as() {
  local ep="$1" br="$2" f="$LW_F"; shift 2
  LW_F="$LW/t9.rec"; : > "$LW_F"; "$@"; LW_F="$f"
  LC_ALL=C awk -v ep="$ep" -v br="$br" -v cwd="$T9_CWD" '
    br != "-" { i = index($0, "\"version\":\"2.1.286\""); if (i) $0 = substr($0, 1, i + 18) ",\"gitBranch\":\"" br "\"" substr($0, i + 19) }
    ep != "-" { $0 = substr($0, 1, length($0) - 1) ",\"entrypoint\":\"" ep "\",\"cwd\":\"" cwd "\"}" }
    { print }' "$LW/t9.rec" >> "$f"
}
_t9_P() {  # DIR SID MIN TEXT EP: P(MIN, TEXT), person records when EP is -, desktop records when it is claude-desktop
  _lw_sess "$1" "$2"; T9_CWD="$1"
  _t9_as "$5" - _lw_h "$(( $3 + 2 ))" 'fix it'; _t9_as "$5" - _lw_a "$3" "$4"; _lw_age "$LW_F" "$3"
}
_t9_R() {  # DIR SID MIN pending|answered: the reviewer session R(MIN, ...)
  local l; _lw_sess "$1" "$2"; T9_CWD="$1"
  printf -v l '{"type":"queue-operation","operation":"enqueue","timestamp":"%s","sessionId":"%s","content":"%s"}' "$(_lw_ts "$(( $3 + 1 ))")" "$2" "$T9Q"
  _lw_raw "$l"
  _t9_as sdk-py - _lw_h "$(( $3 + 1 ))" "$T9Q"
  _t9_as sdk-py - _lw_tu "$3" "toolu_$2" StructuredOutput '{"findings":[]}'
  if [ "$4" = answered ]; then
    _t9_as sdk-py - _lw_tr "$3" "toolu_$2" 'Structured output provided successfully.'
    _t9_as sdk-py - _lw_a "$3" 'No findings.'
  fi
  _lw_age "$LW_F" "$3"
}
# _t9_pfx FILE KIND REF PREFIX [OFF] -> how many elements of the row's detail begin PREFIX, or "no row"
_t9_pfx() { local d; d="$(_lw_col "$1" "$2" "$3" 8 "${5:-0}")"
  [ "$d" != "no row" ] || { printf 'no row'; return; }
  printf '%s\n' "$d" | LC_ALL=C awk -v w="$4" '{ n = split($0, e, "; "); for (i = 1; i <= n; i++) if (index(e[i], w) == 1) c++ } END { printf "%d", c + 0 }'; }
_t9_open() { if [ -r "$1" ] && [ -x "$1" ]; then printf open; else printf shut; fi; }   # DIR -> open when the run could list and enter it
# _t9_runc NAME HOME CWD CONFIG-DIR ARGS...: _lw_run's body, with CLAUDE_CONFIG_DIR set to CONFIG-DIR where _lw_run unsets it
_t9_runc() {
  local n="$1" h="$2" d="$3" c="$4"; shift 4
  ( cd "$d" || exit 97
    exec env -u FELIX_ALLOW_RED -u FELIX_KERNEL -u FELIX_KERNEL_CACHE -u CLAUDE_CODE_SESSION_ID \
      -u CLAUDE_PLUGIN_ROOT -u GIT_DIR -u GIT_WORK_TREE -u GIT_INDEX_FILE -u GIT_COMMON_DIR -u GIT_OBJECT_DIRECTORY -u GIT_OPTIONAL_LOCKS \
      CLAUDE_CONFIG_DIR="$c" HOME="$h" FELIX_HOME="$LW_FH" FELIX_HOME_DIR="$LW_FH" FELIX_MEMORY="$LWM" FELIX_PLUGIN_CACHE="$LW/cache" \
      FELIX_INVENTORY_TEMP_ROOTS="$LW/temproot" XDG_CONFIG_HOME="$h/.config" XDG_STATE_HOME="$h/.state" XDG_CACHE_HOME="$h/.cache" \
      GH_CONFIG_DIR="$h/.config/gh" GIT_CONFIG_NOSYSTEM=1 GIT_TERMINAL_PROMPT=0 GIT_CEILING_DIRECTORIES="$LW" \
      TMPDIR="$LWT" PATH="$LWB:$PATH" "$FELIX" "$@" ) > "$LWX/$n.out" 2> "$LWX/$n.err"
  printf '%s\n' "$?" > "$LWX/$n.rc"
}

# ---- tw9 ------------------------------------------------------------------------------------
_lw_repo tw9; TW9="$LW/tw9"; T9W="$LW/tw9-wt"; mkdir -p "$T9W"
for _t9i in ask9 asr9 ctl9 sdk9 nest9 old9 blk9 unr9 prw9; do _lwg "$TW9" worktree add -q -b "t9-$_t9i" "$T9W/$_t9i" main >/dev/null 2>&1; done
T9M0="$(_lwq "$TW9" refs/heads/main)"
_lw_mk "$TW9" "$T9M0" 'pull request nine' pr9.txt 'nine'; T9X="$LWC"
_lw_mk "$TW9" "$T9M0" 'pull request nine b' pr9b.txt 'nine b'; T9Y="$LWC"
_lwg "$TW9" push -q origin "$T9X:refs/heads/pr9" "$T9Y:refs/heads/pr9b" >/dev/null 2>&1
_lwg "$TW9" fetch -q origin >/dev/null 2>&1
_lw_prs fixture_tw9 "$(_lw_pr 91 pr9 "$T9X" green pr9.txt repo=fixture/tw9)" "$(_lw_pr 92 pr9b "$T9Y" green pr9b.txt repo=fixture/tw9)"
T9H="$LW/htw9"; LW_RR="$T9H/.claude/projects"; mkdir -p "$LW_RR"
_t9_P "$T9W/ask9" t9-ask-p 120 "$T9ASK" claude-desktop; _t9_R "$T9W/ask9" t9-ask-r 118 pending
_t9_P "$T9W/asr9" t9-asr-p 120 "$T9ASK" claude-desktop; _t9_R "$T9W/asr9" t9-asr-r 118 answered
_t9_P "$T9W/ctl9" t9-ctl-p 120 "$T9ASK" claude-desktop
_t9_R "$T9W/sdk9" t9-sdk-r 5 pending
T9TR="$LW_RR/$(_lw_enc "$T9W/sdk9")/t9-sdk-r/tool-results"; mkdir -p "$T9TR"; printf 'a tool result\n' > "$T9TR/t.txt"; _lw_age "$T9TR/t.txt" 2
# nest9: desktop records only, quoting an SDK entrypoint in a human text and in a tool input.
_lw_sess "$T9W/nest9" t9-nest; T9_CWD="$T9W/nest9"
_t9_as claude-desktop - _lw_h 124 'please check \"entrypoint\":\"sdk-py\" handling'
_t9_as claude-desktop - _lw_tu 123 toolu_t9nest mcp__fx__probe '{"entrypoint":"sdk-py"}'
_t9_as claude-desktop - _lw_tr 122 toolu_t9nest 'Probed.'
_t9_as claude-desktop - _lw_a 120 "$T9ASK"; _lw_age "$LW_F" 120
# old9 and blk9: no entrypoint anywhere; blk9's StructuredOutput call is unanswered past --blocked.
_t9_P "$T9W/old9" t9-old 120 "$T9ASK" -
_lw_sess "$T9W/blk9" t9-blk; _lw_h 292 'run the checks'
_lw_tu 290 toolu_t9blk StructuredOutput '{"findings":[]}'; _lw_age "$LW_F" 290
# unr9: a person's question, and a newer person-shaped file the run T cannot read.
_t9_P "$T9W/unr9" t9-unr-a 120 "$T9ASK" -; _t9_P "$T9W/unr9" t9-unr-b 60 'Done.' -; T9UF="$LW_F"
# prw9: the records that name the pull requests' heads.
_lw_sess "$T9W/prw9" t9-prp; T9_CWD="$T9W/prw9"
_t9_as - pr9 _lw_h 31 'carry the pull request'; _t9_as - pr9 _lw_a 30 'Pushed it.'; _lw_age "$LW_F" 30
_lw_sess "$T9W/prw9" t9-prs; _t9_as sdk-py pr9 _lw_h 6 "$T9Q"; _t9_as sdk-py pr9 _lw_a 5 'No findings.'; _lw_age "$LW_F" 5
_lw_sess "$T9W/prw9" t9-prs2; _t9_as sdk-py pr9b _lw_h 11 "$T9Q"; _t9_as sdk-py pr9b _lw_a 10 'No findings.'; _lw_age "$LW_F" 10
chmod 000 "$T9UF"; T9UR=shut; [ -r "$T9UF" ] && T9UR=open
_lw_run T9T "$T9H" "$LW/cwd" inventory --tsv --repo "$TW9"
chmod 600 "$T9UF"
_lw_run T9R "$T9H" "$LW/cwd" inventory --tsv --repo "$TW9"
_lw_run T9M "$T9H" "$LW/cwd" monitor --tsv --repo "$TW9"

# ---- uw9 ------------------------------------------------------------------------------------
_lw_repo uw9; UW9="$LW/uw9"; UW9R="$(_lw_mainwt "$UW9")"; UW9H="$UW9/.claude/worktrees/agent-9f9f9f01"; mkdir -p "$UW9/.claude/worktrees"
_lwg "$UW9" worktree add -q -b uw9-h "$UW9H" main >/dev/null 2>&1
_lw_mk "$UW9" "$(_lwq "$UW9" refs/heads/main)" 'pull request uw nine' uw9.txt 'uw nine'; UW9Z="$LWC"
_lwg "$UW9" push -q origin "$UW9Z:refs/heads/uw9pr" >/dev/null 2>&1; _lwg "$UW9" fetch -q origin >/dev/null 2>&1
_lw_prs fixture_uw9 "$(_lw_pr 95 uw9pr "$UW9Z" green uw9.txt repo=fixture/uw9)"
U9A="$LW/huw9a"; LW_RR="$U9A/.claude/projects"; mkdir -p "$LW_RR"
_lw_sess "$UW9R" s9-main; _lw_h 202 'get the branch ready'
_lw_spawn 201 toolu_9u task_9c9c9c01 'Chip uw nine' 'Prompt uw nine: do it once.'
_lw_a 200 'The branch is ready. Shall I push it?'; _lw_age "$LW_F" 200
_lw_sess "$UW9H" s9-uwh; T9_CWD="$UW9H"
_t9_as - uw9pr _lw_h 31 'carry the pull request'; _t9_as - uw9pr _lw_a 30 'Pushed it.'; _lw_age "$LW_F" 30
for _t9i in huw9z huw9x huw9r huw9d; do mkdir -p "$LW/$_t9i"; cp -Rp "$U9A/.claude" "$LW/$_t9i/.claude"; done
mkdir -p "$LW/huw9n/.claude" "$LW/cuw9"; cp -Rp "$U9A/.claude/projects" "$LW/cuw9/projects"
U9DD="$LW/huw9d/.claude/projects/$(_lw_enc "$UW9R")"
chmod 000 "$LW/huw9z/.claude/projects"; chmod 100 "$LW/huw9x/.claude/projects"; chmod 400 "$LW/huw9r/.claude/projects"
chmod 000 "$U9DD" "$LW/cuw9/projects"
U9OZ="$(_t9_open "$LW/huw9z/.claude/projects")"; U9OX="$(_t9_open "$LW/huw9x/.claude/projects")"; U9OR="$(_t9_open "$LW/huw9r/.claude/projects")"
U9OD="$(_t9_open "$U9DD")"; U9OC="$(_t9_open "$LW/cuw9/projects")"
_lw_run U9UA "$U9A" "$LW/cwd" inventory --tsv --repo "$UW9"
_lw_run U9UZ "$LW/huw9z" "$LW/cwd" inventory --tsv --repo "$UW9"
_lw_run U9UX "$LW/huw9x" "$LW/cwd" inventory --tsv --repo "$UW9"
_lw_run U9UR "$LW/huw9r" "$LW/cwd" inventory --tsv --repo "$UW9"
_lw_run U9UN "$LW/huw9n" "$LW/cwd" inventory --tsv --repo "$UW9"
_lw_run U9UD "$LW/huw9d" "$LW/cwd" inventory --tsv --repo "$UW9"
_t9_runc U9UC "$U9A" "$LW/cwd" "$LW/cuw9" inventory --tsv --repo "$UW9"
_lw_run U9UM "$LW/huw9z" "$LW/cwd" monitor --tsv --repo "$UW9"
chmod 755 "$LW/huw9z/.claude/projects" "$LW/huw9x/.claude/projects" "$LW/huw9r/.claude/projects" "$U9DD" "$LW/cuw9/projects"

# ---- C028: A1 to A12 ----------------------------------------------------------------------------
T9O="$(_lw_o T9T)"; T9P="$(_lw_o T9M)"
is "A1 (B1): a reviewer's SDK session filed after the person's question leaves ask9 its person's session as owner, question, not blocked, and the question it ended on" \
   "$(_lw_col "$T9O" worktree "$T9W/ask9" 5) $(_lw_holds "$T9O" worktree "$T9W/ask9" question) $(_lw_holds "$T9O" worktree "$T9W/ask9" blocked) $(_lw_elem "$T9O" worktree "$T9W/ask9" "ended on: $T9ASK")" \
   "t9-ask-p yes no yes"
is "A2 (B1): a reviewer whose result was written, filed after the person's question, leaves asr9 its person's session as owner and question" \
   "$(_lw_col "$T9O" worktree "$T9W/asr9" 5) $(_lw_holds "$T9O" worktree "$T9W/asr9" question)" "t9-asr-p yes"
is "A3 (B1, control): ctl9, the person's desktop session alone, has that session as owner and holds question" \
   "$(_lw_col "$T9O" worktree "$T9W/ctl9" 5) $(_lw_holds "$T9O" worktree "$T9W/ctl9" question)" "t9-ctl-p yes"
is "A4 (B1): a record directory holding only an SDK session gives owner -, neither question nor blocked, and the element passed over 1 SDK session(s)" \
   "$(_lw_col "$T9O" worktree "$T9W/sdk9" 5) $(_lw_holds "$T9O" worktree "$T9W/sdk9" question) $(_lw_holds "$T9O" worktree "$T9W/sdk9" blocked) $(_lw_elem "$T9O" worktree "$T9W/sdk9" 'passed over 1 SDK session(s)')" \
   "- no no yes"
is "A5 (B1, control): where a person's session remains beside the SDK one, no element of the detail begins passed over" \
   "$(_t9_pfx "$T9O" worktree "$T9W/ask9" 'passed over') $(_t9_pfx "$T9O" worktree "$T9W/asr9" 'passed over')" "0 0"
is "A6 (B2): an SDK session's records and its <sid>/ files, minutes old, do not make the worktree live" \
   "$(_lw_holds "$T9O" worktree "$T9W/sdk9" live)" no
is "A7 (B3, control): a desktop session quoting an SDK entrypoint in its text and in a tool input is a person's: owner and question" \
   "$(_lw_col "$T9O" worktree "$T9W/nest9" 5) $(_lw_holds "$T9O" worktree "$T9W/nest9" question)" "t9-nest yes"
is "A8 (B4, control): sessions with no entrypoint are a person's: old9's owner and question, and blk9's unanswered StructuredOutput call is a wait" \
   "$(_lw_col "$T9O" worktree "$T9W/old9" 5) $(_lw_holds "$T9O" worktree "$T9W/old9" question) $(_lw_holds "$T9O" worktree "$T9W/blk9" blocked) $(_t9_pfx "$T9O" worktree "$T9W/blk9" 'waiting on StructuredOutput for ')" \
   "t9-old yes yes 1"
is "A9 (B5): a pull request whose head SDK records name more recently is owned by the person's session that named it, and is live" \
   "$(_lw_col "$T9O" pr '#91' 5) $(_lw_holds "$T9O" pr '#91' live)" "t9-prp yes"
is "A10 (B5, R1): with every session file read (run T2), a pull request whose head only SDK records name has owner - and is not live" \
   "$(_lw_col "$(_lw_o T9R)" pr '#92' 5) $(_lw_holds "$(_lw_o T9R)" pr '#92' live)" "- no"
if [ "$T9UR" = open ]; then skip "A11 (B6, control): a newest session file the run cannot read gives owner unknown and unknown:question" "a mode-000 file is readable here"
else is "A11 (B6, control): a newest session file the run cannot read gives owner unknown and unknown:question" \
   "$(_lw_col "$T9O" worktree "$T9W/unr9" 5) $(_lw_holds "$T9O" worktree "$T9W/unr9" unknown:question)" "unknown yes"; fi
is "A12 (B7): on the page ask9 and asr9 are in group question, blk9 in blocked, and the blocked summary counts 1" \
   "$(_lw_col "$T9P" worktree "$T9W/ask9" 0 1) $(_lw_col "$T9P" worktree "$T9W/asr9" 0 1) $(_lw_col "$T9P" worktree "$T9W/blk9" 0 1) $(_lw_col "$T9P" summary blocked 7 1)" \
   "question question blocked 1"

# ---- C047: A13 to A26 ---------------------------------------------------------------------------
U9D='Claude Code session records under $HOME/.claude/projects could not be read'
U9S='unknown,unknown:live,unknown:question,unknown:blocked'
UAO="$(_lw_o U9UA)"; UZO="$(_lw_o U9UZ)"; UXO="$(_lw_o U9UX)"; URO="$(_lw_o U9UR)"; UNO="$(_lw_o U9UN)"; UDO="$(_lw_o U9UD)"; UCO="$(_lw_o U9UC)"; UMO="$(_lw_o U9UM)"
_t9_sk() { [ "$1" = shut ] || { skip "$2" "the directory is still readable and searchable after its chmod"; return 1; }; }   # STATE NAME
_t9n="A13 (B8): a records root at mode 000 makes the sessions cover row unknown in all four, saying the records could not be read"
_t9_sk "$U9OZ" "$_t9n" && is "$_t9n" "$(_lw_st "$UZO" cover sessions)|$(_lw_col "$UZO" cover sessions 8)" "$U9S|$U9D"
_t9n="A14 (B8): and the chips cover row unknown,unknown:chip-unstarted with the same detail"
_t9_sk "$U9OZ" "$_t9n" && is "$_t9n" "$(_lw_st "$UZO" cover chips)|$(_lw_col "$UZO" cover chips 8)" "unknown,unknown:chip-unstarted|$U9D"
_t9n="A15 (B8): and the main worktree's owner unknown, holding unknown:live, unknown:question and unknown:blocked and none of live, question or blocked"
_t9_sk "$U9OZ" "$_t9n" && is "$_t9n" \
   "$(_lw_col "$UZO" worktree "$UW9" 5) $(_lw_many "$UZO" worktree "$UW9" 0 unknown:live unknown:question unknown:blocked live question blocked)" \
   "unknown unknown:live=yes unknown:question=yes unknown:blocked=yes live=no question=no blocked=no"
_t9n="A16 (B8, control): and the helper-form agent-9f9f9f01 carries unknown:helper and no helper"
_t9_sk "$U9OZ" "$_t9n" && is "$_t9n" "$(_lw_many "$UZO" worktree "$UW9H" 0 unknown:helper helper)" "unknown:helper=yes helper=no"
_t9n="A17 (B8): and the pull request #95 has owner unknown and holds unknown:live"
_t9_sk "$U9OZ" "$_t9n" && is "$_t9n" "$(_lw_col "$UZO" pr '#95' 5) $(_lw_holds "$UZO" pr '#95' unknown:live)" "unknown yes"
_t9n="A18 (B8, control): the readable root lists the chip task_9c9c9c01, and the root at mode 000 lists no chip row (its run exiting 0)"
_t9_sk "$U9OZ" "$_t9n" && is "$_t9n" \
   "$(_lw_kind "$UAO" task_9c9c9c01) $(LC_ALL=C awk -F'\t' '$1 == "chip" { n++ } END { print n + 0 }' "$UZO" 2>/dev/null) $(_lw_rc U9UZ)" "chip 0 0"
_t9n="A19 (B8): a records root at mode 100 reads as A13 says"
_t9_sk "$U9OX" "$_t9n" && is "$_t9n" "$(_lw_st "$UXO" cover sessions)|$(_lw_col "$UXO" cover sessions 8)" "$U9S|$U9D"
_t9n="A20 (B8): a records root at mode 400 reads as A13 says"
_t9_sk "$U9OR" "$_t9n" && is "$_t9n" "$(_lw_st "$URO" cover sessions)|$(_lw_col "$URO" cover sessions 8)" "$U9S|$U9D"
_t9n="A21 (B9): CLAUDE_CONFIG_DIR's projects at mode 000 reads as A13 says, the detail naming \$CLAUDE_CONFIG_DIR/projects literally"
_t9_sk "$U9OC" "$_t9n" && is "$_t9n" "$(_lw_st "$UCO" cover sessions)|$(_lw_col "$UCO" cover sessions 8)" \
   "$U9S|Claude Code session records under \$CLAUDE_CONFIG_DIR/projects could not be read"
_t9n="A22 (B10): on the page the blocked, question, running and helper summaries are incomplete, content unknown, each reason saying sessions unknown and why"
_t9o=""; for _t9i in blocked question running helper; do
  _t9o="$_t9o $_t9i:$(_lw_st "$UMO" summary "$_t9i" 1),$(_lw_col "$UMO" summary "$_t9i" 7 1),$(_lw_elem "$UMO" summary "$_t9i" "sessions unknown: $U9D" 1)"; done
_t9_sk "$U9OZ" "$_t9n" && is "$_t9n" "$_t9o" \
   " blocked:incomplete,unknown,yes question:incomplete,unknown,yes running:incomplete,unknown,yes helper:incomplete,unknown,yes"
_t9n="A23 (B10): and the never-proposed summary is incomplete, its reason saying chips unknown and why"
_t9_sk "$U9OZ" "$_t9n" && is "$_t9n" \
   "$(_lw_st "$UMO" summary never-proposed 1) $(_lw_elem "$UMO" summary never-proposed "chips unknown: $U9D" 1)" "incomplete yes"
is "A24 (B11, control): a readable records root reads read under the literal \$HOME/.claude/projects, and the main worktree's owner is s9-main with question" \
   "$(_lw_st "$UAO" cover sessions)|$(_lw_col "$UAO" cover sessions 8)|$(_lw_col "$UAO" worktree "$UW9" 5) $(_lw_holds "$UAO" worktree "$UW9" question)" \
   "read|Claude Code session records under \$HOME/.claude/projects|s9-main yes"
is "A25 (B11, control): a missing records root reads unknown in all four with the detail no session records" \
   "$(_lw_st "$UNO" cover sessions)|$(_lw_col "$UNO" cover sessions 8)" "$U9S|no session records"
_t9n="A26 (B11, control): one record directory at mode 000 under a readable root leaves the cover row read, and that worktree owner unknown, saying which directory"
_t9_sk "$U9OD" "$_t9n" && is "$_t9n" \
   "$(_lw_st "$UDO" cover sessions | LC_ALL=C cut -d, -f1) $(_lw_col "$UDO" worktree "$UW9" 5) $(_lw_elem "$UDO" worktree "$UW9" "could not read the record directory $U9DD")" \
   "read unknown yes"

# ---- review round, M1: an SDK record never stands in for an owner the run could not read (A42 to A49) ----
# Written 2026-10-26 from the contract's section 9 alone. mw9: sole9's record directory holds a person
# session naming mw9a (made unreadable for run MU) and an SDK reviewer naming it later; pers9's holds a
# person session naming mw9c 90 minutes ago, an SDK one naming it 5 minutes ago, and a person session
# naming mw9d 20 minutes ago. MR reads every file; MU reads all but m9-pa, which is set back after it.
_t9_su() { [ "$1" = shut ] || { skip "$2" "a mode-000 file is readable here"; return 1; }; }   # STATE NAME
_lw_repo mw9; MW9="$LW/mw9"; M9W="$LW/mw9-wt"; mkdir -p "$M9W"
for _t9i in sole9 pers9; do _lwg "$MW9" worktree add -q -b "m9-$_t9i" "$M9W/$_t9i" main >/dev/null 2>&1; done
M9M0="$(_lwq "$MW9" refs/heads/main)"
_lw_mk "$MW9" "$M9M0" 'pull request m nine a' m9a.txt 'm nine a'; M9A="$LWC"
_lw_mk "$MW9" "$M9M0" 'pull request m nine c' m9c.txt 'm nine c'; M9C="$LWC"
_lw_mk "$MW9" "$M9M0" 'pull request m nine d' m9d.txt 'm nine d'; M9D="$LWC"
_lwg "$MW9" push -q origin "$M9A:refs/heads/mw9a" "$M9C:refs/heads/mw9c" "$M9D:refs/heads/mw9d" >/dev/null 2>&1
_lwg "$MW9" fetch -q origin >/dev/null 2>&1
_lw_prs fixture_mw9 "$(_lw_pr 96 mw9a "$M9A" green m9a.txt repo=fixture/mw9)" "$(_lw_pr 98 mw9c "$M9C" green m9c.txt repo=fixture/mw9)" \
  "$(_lw_pr 99 mw9d "$M9D" green m9d.txt repo=fixture/mw9)"
M9H="$LW/hmw9"; LW_RR="$M9H/.claude/projects"; mkdir -p "$LW_RR"
_lw_sess "$M9W/sole9" m9-pa; T9_CWD="$M9W/sole9"
_t9_as claude-desktop mw9a _lw_h 41 'carry the pull request'; _t9_as claude-desktop mw9a _lw_a 40 'Pushed it.'; _lw_age "$LW_F" 40; M9PF="$LW_F"
_lw_sess "$M9W/sole9" m9-sa
_t9_as sdk-py mw9a _lw_h 31 "$T9Q"; _t9_as sdk-py mw9a _lw_tu 30 toolu_m9sa StructuredOutput '{"findings":[]}'; _lw_age "$LW_F" 30
_lw_sess "$M9W/pers9" m9-pc; T9_CWD="$M9W/pers9"
_t9_as claude-desktop mw9c _lw_h 91 'carry the pull request'; _t9_as claude-desktop mw9c _lw_a 90 'Pushed it.'; _lw_age "$LW_F" 90
_lw_sess "$M9W/pers9" m9-sc; _t9_as sdk-py mw9c _lw_h 6 "$T9Q"; _t9_as sdk-py mw9c _lw_a 5 'No findings.'; _lw_age "$LW_F" 5
_lw_sess "$M9W/pers9" m9-pd
_t9_as claude-desktop mw9d _lw_h 21 'carry the pull request'; _t9_as claude-desktop mw9d _lw_a 20 'Pushed it.'; _lw_age "$LW_F" 20
_lw_run M9MR "$M9H" "$LW/cwd" inventory --tsv --repo "$MW9"
chmod 000 "$M9PF"; M9UR=shut; [ -r "$M9PF" ] && M9UR=open
_lw_run M9MU "$M9H" "$LW/cwd" inventory --tsv --repo "$MW9"
chmod 600 "$M9PF"
M9RO="$(_lw_o M9MR)"; M9UO="$(_lw_o M9MU)"
_t9n="A42 (R1): in run T, unr9's unread file older than the SDK records naming pr9b, #92's owner is unknown, not -, and it is not live"
_t9_su "$T9UR" "$_t9n" && is "$_t9n" "$(_lw_col "$T9O" pr '#92' 5) $(_lw_holds "$T9O" pr '#92' live)" "unknown no"
is "A43 (R1, control): read, the person session that named mw9a owns #96 past the newer SDK records naming it, and #96 is live" \
   "$(_lw_col "$M9RO" pr '#96' 5) $(_lw_holds "$M9RO" pr '#96' live)" "m9-pa yes"
_t9n="A44 (R1): with that person's file unread and only SDK records left naming mw9a, newer than the file, #96's owner is unknown, not -, and live is unknown"
_t9_su "$M9UR" "$_t9n" && is "$_t9n" "$(_lw_col "$M9UO" pr '#96' 5) $(_lw_many "$M9UO" pr '#96' 0 live unknown:live)" "unknown live=no unknown:live=yes"
is "A45 (R2, B5): read, #98's owner is the person session that named mw9c 90 minutes ago, and an SDK record naming it 5 minutes ago makes it neither live nor unknown" \
   "$(_lw_col "$M9RO" pr '#98' 5) $(_lw_many "$M9RO" pr '#98' 0 live unknown:live)" "m9-pc live=no unknown:live=no"
_t9n="A46 (R2): a file unread, modified after the owner's record naming mw9c but before the SDK record naming it, makes #98's owner and live unknown"
_t9_su "$M9UR" "$_t9n" && is "$_t9n" "$(_lw_col "$M9UO" pr '#98' 5) $(_lw_many "$M9UO" pr '#98' 0 live unknown:live)" "unknown live=no unknown:live=yes"
_t9n="A47 (R2, control): a file unread, modified before the owner's record naming mw9d, leaves #99 its owner m9-pd, live"
_t9_su "$M9UR" "$_t9n" && is "$_t9n" "$(_lw_col "$M9UO" pr '#99' 5) $(_lw_holds "$M9UO" pr '#99' live)" "m9-pd yes"
is "A48 (R3, control): read, sole9's owner is its person session past the newer SDK one, live, and the SDK session's pending call is no wait" \
   "$(_lw_col "$M9RO" worktree "$M9W/sole9" 5) $(_lw_many "$M9RO" worktree "$M9W/sole9" 0 live question blocked)" "m9-pa live=yes question=no blocked=no"
_t9n="A49 (R3): with only that SDK session readable beside an older unread file, sole9's owner is unknown, not -, and live, question and blocked are unknown"
_t9_su "$M9UR" "$_t9n" && is "$_t9n" \
   "$(_lw_col "$M9UO" worktree "$M9W/sole9" 5) $(_lw_many "$M9UO" worktree "$M9W/sole9" 0 live question blocked unknown:live unknown:question unknown:blocked)" \
   "unknown live=no question=no blocked=no unknown:live=yes unknown:question=yes unknown:blocked=yes"
# <<< inventory-true-owners
