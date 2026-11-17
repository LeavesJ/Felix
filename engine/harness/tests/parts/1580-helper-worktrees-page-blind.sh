# >>> helper-worktrees-page
printf '\nhelper worktrees placed apart: the lost-work page (contract Part C, C5.14-18, blind)\n'
# Blind, written on 2026-10-23 from docs/2026-10-18-lost-work-page-contract.md (C4, C5 and the marks
# "(Part C)" in B3-B6) alone; felix was run as a black box. The stubs, runner and readers are
# tests/lib/lost-work.sh's. The fixtures are this part's own (C5.14: B9.26's shared page fixture pins
# counts), so it runs alone and in the serial order.
# hp6: two helper worktrees, one with an unpushed commit and one whose last call is unanswered past
# --blocked; a plain worktree of each kind; and a helper sharing its branch with another worktree (a
# hazard). hn6: one helper-form worktree, read under --no-host. Helpers are named by meta files under
# the main worktree's session, as section 6.4 of the inventory spec reads them. No project governs
# either repository, so land's own rows are unread and its gh row is read (B9.38).
_lw_build
_hw6_meta() {  # RECORD-ROOT DIR-OF-SPAWNER SID NAME WORKTREE-PATH DESCRIPTION: a meta file and its sibling .jsonl, both 300 minutes old
  local f="$1/$(_lw_enc "$2")/$3/subagents/$4"
  mkdir -p "${f%/*}"
  printf '{"agentType":"general-purpose","description":"%s","worktreePath":"%s"}\n' "$6" "$5" > "$f.meta.json"
  printf '{}\n' > "$f.jsonl"; _lw_age "$f.meta.json" 300; _lw_age "$f.jsonl" 300
}
_hw6_wt() {  # REPO PATH BRANCH [FILE CONTENT]
  _lwg "$1" worktree add -q -b "$3" "$2" main >/dev/null 2>&1
  [ -n "${4:-}" ] || return 0
  printf '%s\n' "$5" > "$2/$4"; _lwg "$2" add -A >/dev/null 2>&1; _lwg "$2" commit -qm "$4" >/dev/null 2>&1
}
_hw6_blk() {  # DIR SID: a session in DIR's own record directory whose last record is a Bash call 290 minutes old, unanswered
  _lw_sess "$1" "$2"; _lw_h 292 'run the checks'
  _lw_tu 290 "toolu_$2" Bash '{"command":"run-the-checks","description":"Run the checks"}'; _lw_age "$LW_F" 290
}
_lw_repo hp6; HP6="$LW/hp6"; HP6W="$LW/hp6-wt"; mkdir -p "$HP6W"
_lw_prs fixture_hp6
_hw6_wt "$HP6" "$HP6W/agent-6a6a6a6a" hp6-p1 p1.txt 'helper work never pushed'
_hw6_wt "$HP6" "$HP6W/agent-6b6b6b6b" hp6-p2
_hw6_wt "$HP6" "$HP6W/plain-unp6" hp6-u u6.txt 'plain work never pushed'
_hw6_wt "$HP6" "$HP6W/plain-blk6" hp6-b
_lwg "$HP6" branch -q hp6-shared main >/dev/null 2>&1
_lwg "$HP6" worktree add -q "$HP6W/agent-6c6c6c6c" hp6-shared >/dev/null 2>&1
_lwg "$HP6" worktree add -q -f "$HP6W/share6" hp6-shared >/dev/null 2>&1
HP6A="$LW/hp6a"; LW_RR="$HP6A/.claude/projects"; mkdir -p "$LW_RR"
_lw_sess "$HP6" s6-boss; _lw_h 302 'spawn the helpers'; _lw_a 300 'Spawned them.'; _lw_age "$LW_F" 300
_hw6_meta "$LW_RR" "$HP6" s6-boss agent-p1 "$HP6W/agent-6a6a6a6a" 'write the page'
_hw6_meta "$LW_RR" "$HP6" s6-boss agent-p2 "$HP6W/agent-6b6b6b6b" 'return the result'
_hw6_meta "$LW_RR" "$HP6" s6-boss agent-p3 "$HP6W/agent-6c6c6c6c" 'share a branch'
_hw6_blk "$HP6W/agent-6b6b6b6b" s6-dead
_hw6_blk "$HP6W/plain-blk6" s6-wait
_lw_run C6PT "$HP6A" "$LW/cwd" monitor --tsv --repo "$HP6"
_lw_run C6PX "$HP6A" "$LW/cwd" monitor --repo "$HP6"
_lw_run C6IV "$HP6A" "$LW/cwd" inventory --tsv --repo "$HP6"
_lw_run C6LD "$HP6A" "$LW/cwd" land --prs --tsv --repo "$HP6"
_lw_run C6HELP "$HP6A" "$LW/cwd" monitor --help
_lw_repo hn6; HN6="$LW/hn6"; HN6W="$LW/hn6-wt"; mkdir -p "$HN6W"
_lw_prs fixture_hn6
_hw6_wt "$HN6" "$HN6W/agent-7d7d7d7d" hn6-p7 p7.txt 'helper work never pushed'
HN6A="$LW/hn6a"; LW_RR="$HN6A/.claude/projects"; mkdir -p "$LW_RR"
_lw_sess "$HN6" s6-nboss; _lw_h 302 'spawn the helper'; _lw_a 300 'Spawned it.'; _lw_age "$LW_F" 300
_hw6_meta "$LW_RR" "$HN6" s6-nboss agent-p7 "$HN6W/agent-7d7d7d7d" 'write the notes'
_lw_run C6NT "$HN6A" "$LW/cwd" monitor --tsv --no-host --repo "$HN6"
_lw_run C6NX "$HN6A" "$LW/cwd" monitor --no-host --repo "$HN6"
_lw_run C6NI "$HN6A" "$LW/cwd" monitor --tsv --repo "$HN6"

# ---- readers ------------------------------------------------------------------------------
_hw6_in() { case "$1" in *"$2"*) printf '%s' "$3" ;; *) printf '%s' "$4" ;; esac; }   # STRING PART YES NO
_hw6_g() { _lw_col "$1" "$2" "$3" 0 1; }   # the group cell of the page row KIND REF in FILE
_hw6_tn() {  # FILE REF -> the number of lines on which REF stands, followed by nothing, a blank, a colon or a comma
  LC_ALL=C awk -v r="$2" '{ s = $0; while ((i = index(s, r)) > 0) { z = substr(s, i + length(r), 1); if (z == "" || z == " " || z == ":" || z == ",") { n++; break } s = substr(s, i + length(r)) } } END { print n + 0 }' "$1" 2>/dev/null; }
_hw6_tl() { LC_ALL=C awk -v r="$2 " '{ s = $0; sub(/^ +/, "", s); if (index(s, r) == 1) n++ } END { print n + 0 }' "$1" 2>/dev/null; }   # rows listed: lines that start with REF
_hw6_coll() {  # FILE -> the collapsed line's elements, one a line
  LC_ALL=C awk 'index($0, "  collapsed: ") == 1 { s = substr($0, 14); n = split(s, e, ", "); for (i = 1; i <= n; i++) print e[i]; exit }' "$1" 2>/dev/null; }
P1="$HP6W/agent-6a6a6a6a"; P2="$HP6W/agent-6b6b6b6b"; P3="$HP6W/agent-6c6c6c6c"; PU="$HP6W/plain-unp6"; PB="$HP6W/plain-blk6"; P7="$HN6W/agent-7d7d7d7d"
PT="$(_lw_o C6PT)"; PX="$(_lw_o C6PX)"; IV="$(_lw_o C6IV)"; NT="$(_lw_o C6NT)"; NX="$(_lw_o C6NX)"; NI="$(_lw_o C6NI)"
_hw6o=""; for _hw6i in C6PT C6PX C6IV C6LD C6NT C6NX C6NI; do _hw6o="$_hw6o$(_lw_rc $_hw6i)$([ -s "$(_lw_o $_hw6i)" ] && echo + || echo -)"; done
is "C5.14 fixture: the pages over hp6 and hn6 and hp6's two sources exit 0 and print something (control)" "$_hw6o" "0+0+0+0+0+0+0+"

# ---- C5.14 and C5.15: groups and summaries --------------------------------------------------
is "C5.14 control: the helper rows name their spawning session and the plain rows name none, so the meta files are found" \
   "$(_lw_elem "$IV" worktree "$P1" 'spawned by session s6-boss: write the page') $(_lw_elem "$IV" worktree "$P2" 'spawned by session s6-boss: return the result') $(_hw6_in "$(_lw_col "$IV" worktree "$PU" 8)$(_lw_col "$IV" worktree "$PB" 8)" 'spawned by session' named none)" \
   "yes yes none"
is "C5.14 control: the plain unpushed worktree is in never-proposed and the plain blocked worktree in blocked" \
   "$(_hw6_g "$PT" worktree "$PU") $(_hw6_g "$PT" worktree "$PB")" "never-proposed blocked"
is "C5.14: the helper with an unpushed commit and the helper whose last call is unanswered are both in group helper in --tsv" \
   "$(_hw6_g "$PT" worktree "$P1") $(_hw6_g "$PT" worktree "$P2")" "helper helper"
is "C5.14: the never-proposed and blocked summaries do not count them: each is complete, content 1" \
   "$(_lw_st "$PT" summary never-proposed 1) $(_lw_col "$PT" summary never-proposed 7 1) $(_lw_st "$PT" summary blocked 1) $(_lw_col "$PT" summary blocked 7 1)" \
   "complete 1 complete 1"
is "C5.14: the helper summary is complete, content 2" "$(_lw_st "$PT" summary helper 1) $(_lw_col "$PT" summary helper 7 1)" "complete 2"
is "C5.15: a helper worktree that also holds hazard:shared-branch holds both, and is in group hazard" \
   "$(_lw_many "$PT" worktree "$P3" 1 hazard:shared-branch helper) $(_hw6_g "$PT" worktree "$P3")" "hazard:shared-branch=yes helper=yes hazard"

# ---- C5.16: the text page ------------------------------------------------------------------------
is "C5.16 control: the plain unpushed and the plain blocked worktrees are each listed once on the text page" \
   "$(_hw6_tl "$PX" "$PU") $(_hw6_tl "$PX" "$PB")" "1 1"
is "C5.16: neither helper's ref appears on any line of the text page" "$(_hw6_tn "$PX" "$P1") $(_hw6_tn "$PX" "$P2")" "0 0"
is "C5.16: the collapsed line says helper worktrees 2, right after running <count>" \
   "$(_hw6_coll "$PX" | LC_ALL=C sed -n '1,2p' | LC_ALL=C tr '\n' '|')" "running $(_lw_col "$PT" summary running 7 1)|helper worktrees 2|"

# ---- C5.17: --no-host ----------------------------------------------------------------------------
is "C5.17 control: under --no-host hn6's sessions cover row is unknown, --no-host; read with the host, its helper-form worktree names its spawning session" \
   "$(_lw_st "$NT" cover sessions 1 | LC_ALL=C cut -d, -f1) $(_lw_col "$NT" cover sessions 8 1) $(_lw_elem "$NI" worktree "$P7" 'spawned by session s6-nboss: write the notes' 1)" \
   "unknown --no-host yes"
is "C5.17: under --no-host the helper summary is incomplete and, with no row in it, its content is unknown" \
   "$(_lw_st "$NT" summary helper 1) $(_lw_col "$NT" summary helper 7 1)" "incomplete unknown"
is "C5.17: its reason names sessions unknown: --no-host and, for the one helper-form worktree, 1 rows not decided" \
   "$(_lw_elem "$NT" summary helper 'sessions unknown: --no-host' 1) $(_lw_elem "$NT" summary helper '1 rows not decided' 1)" "yes yes"
is "C5.17: the text page says helper worktrees unknown on its collapsed line" \
   "$(_hw6_coll "$NX" | LC_ALL=C grep -c '^helper worktrees unknown$')" 1
is "C5.17: the helper-form worktree carries unknown:helper and is in never-proposed, the group B3 gives it without helper" \
   "$(_lw_holds "$NT" worktree "$P7" unknown:helper 1) $(_hw6_g "$NT" worktree "$P7")" "yes never-proposed"

# ---- C5.18: seventeen summaries, nothing dropped or added ------------------------------------------
HW6_GROUPS='hazard blocked question never-proposed pr-founder pr-session pr-lander pr-unknown undecided running helper pr-nobody proposed carried handoff landed quiet'
_hw6r="$(_lw_mainwt "$HP6")"
is "C5.18: the page opens with 17 summary rows in B5's order, helper right after running, each with ref the group" \
   "$(LC_ALL=C awk -F'\t' 'NR <= 17 { printf "%s%s", s, ($2 == "summary" && $4 == $1 && $3 == r) ? $1 : "[" $1 " " $2 "]"; s = " " }' r="$_hw6r" "$PT")" "$HW6_GROUPS"
is "C5.18: and holds no other summary row" "$(_lw_n16 "$PT")" 17
_hw6a="$(LC_ALL=C awk -F'\t' '$2 != "summary"' "$PT" | LC_ALL=C cut -f2- | _lw_norm)"
_hw6b="$(cat "$IV" "$(_lw_o C6LD)" | _lw_norm)"
is "C5.18: B9.27 holds with helpers present: the page's non-summary rows, first column cut, equal its two sources' rows as a multiset" \
   "$([ -n "$_hw6b" ] && echo sources)|$_hw6a" "sources|$_hw6b"
is "C5.18 (C4): felix monitor's usage says 17 summary rows per repository on its --tsv line" \
   "$(LC_ALL=C awk 'index($0, "  --tsv") == 1 && index($0, "17 summary rows per repository") { n++ } END { print n + 0 }' "$(_lw_o C6HELP)")" 1
# <<< helper-worktrees-page
