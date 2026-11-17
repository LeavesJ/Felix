# >>> helper-worktrees-review-fixes
printf '\nhelper worktrees placed apart: the review round (contract C8, items 1 and 2, blind)\n'
# Blind, written on 2026-10-23 from docs/2026-10-18-lost-work-page-contract.md (C8, with Part C and
# B9 around it) alone; felix was run as a black box. The stubs, the runner and the TSV readers are
# tests/lib/lost-work.sh's (_lw_build); every fixture here is this part's own, under $LW, so it runs
# alone and in the serial order.
#
# hw8: one repository, worktrees in $LW/hw8-wt and one temporary root under $LW/temproot.
#   dot-j8  its record directory's only session file is named .jsonl (an empty id), last record a
#           Bash call 300 minutes old, unanswered (C8.1)
#   ctl-j8  the same, but the file is s-ctl.jsonl (C8.1's control)
#   $LW/temproot/hw8/agent-8e8e8e01  temp and helper, one unpushed commit (C8.2, C5.12's case)
#   $LW/temproot/hw8/plain-t8        temp only, one unpushed commit (C8.2's control)
# Home A holds the records; home B the same with dot-j8's .jsonl removed, so that the fixture check
# can show the run reads that file.
_lw_build
_hw8_wt() {  # REPO PATH BRANCH [FILE CONTENT]: a worktree on a new branch from main, with one commit of FILE when given
  _lwg "$1" worktree add -q -b "$3" "$2" main >/dev/null 2>&1
  [ -n "${4:-}" ] || return 0
  printf '%s\n' "$5" > "$2/$4"; _lwg "$2" add -A >/dev/null 2>&1; _lwg "$2" commit -qm "$4" >/dev/null 2>&1
}
_hw8_blk() {  # FILE SID: a session file whose last record is a Bash call 300 minutes old, unanswered
  _lw_open "$1" "$2"; _lw_h 302 'watch the ledger'
  _lw_tu 300 "toolu_hw8$RANDOM" Bash '{"command":"watch-the-ledger","description":"Watch the ledger"}'; _lw_age "$LW_F" 300
}
_hw8_meta() {  # RECORD-ROOT DIR-OF-SPAWNER SID NAME WORKTREE-PATH DESCRIPTION: a meta file and its sibling .jsonl, both 300 minutes old
  local f="$1/$(_lw_enc "$2")/$3/subagents/$4"
  mkdir -p "${f%/*}"
  printf '{"agentType":"general-purpose","description":"%s","worktreePath":"%s"}\n' "$6" "$5" > "$f.meta.json"
  printf '{}\n' > "$f.jsonl"; _lw_age "$f.meta.json" 300; _lw_age "$f.jsonl" 300
}
_hw8_bad() {  # DETAIL -> the elements ("; "-joined) equal to yes, no or unknown, space-separated, or "none"
  printf '%s\n' "$1" | LC_ALL=C awk '{ n = split($0, e, "; "); for (i = 1; i <= n; i++) if (e[i] == "yes" || e[i] == "no" || e[i] == "unknown") o = o (o == "" ? "" : " ") "[" e[i] "]" }
    END { print (o == "" ? "none" : o) }'; }
_hw8_files() {  # DIR -> the names of the files in DIR, dotfiles too, space-separated
  ( cd "$1" 2>/dev/null && LC_ALL=C ls -A | LC_ALL=C tr '\n' ' ' ); }
# The human view: a heading is two spaces, a label, two spaces and a count; a row line is four spaces,
# a kind and a path. _hw8_vrow prints the row line naming NAME (its path's last component) and the
# heading it is under, as "HEADING|LINE".
_hw8_vrow() {  # FILE NAME
  LC_ALL=C awk -v n="$2" '
    /^  [^ ].*  [0123456789]+$/ { g = $0; sub(/^  /, "", g); sub(/  [0123456789]+$/, "", g); next }
    /^    [abcdefghijklmnopqrstuvwxyz]+ +[^ ]/ { k = split($2, s, "/"); if (s[k] == n) { print g "|" $0; exit } }' "$1" 2>/dev/null; }
_hw8_word() {  # LINE WORD -> yes when WORD is a whole word of LINE after its path (split on spaces, commas and brackets)
  printf '%s\n' "$1" | LC_ALL=C awk -v w="$2" '{ $1 = ""; $2 = ""; n = split($0, t, /[ ,()\[\]]+/); for (i = 1; i <= n; i++) if (t[i] == w) f = 1 } END { print (f ? "yes" : "no") }'; }

_lw_repo hw8; HW8="$LW/hw8"; HW8W="$LW/hw8-wt"; HW8T="$LW/temproot/hw8"; mkdir -p "$HW8W" "$HW8T"
_lw_prs fixture_hw8
HW8D="$HW8W/dot-j8"; HW8C="$HW8W/ctl-j8"; HW8H="$HW8T/agent-8e8e8e01"; HW8P="$HW8T/plain-t8"
_hw8_wt "$HW8" "$HW8D" hw8-dot
_hw8_wt "$HW8" "$HW8C" hw8-ctl
_hw8_wt "$HW8" "$HW8H" hw8-th th.txt 'temporary helper work'
_hw8_wt "$HW8" "$HW8P" hw8-tp tp.txt 'temporary plain work'
HW8A="$LW/hh8a"; LW_RR="$HW8A/.claude/projects"; mkdir -p "$LW_RR"
HW8DR="$LW_RR/$(_lw_enc "$HW8D")"
_hw8_blk "$HW8DR/.jsonl" ""
_hw8_blk "$LW_RR/$(_lw_enc "$HW8C")/s-ctl.jsonl" s-ctl
_lw_sess "$HW8" s8-boss; _lw_h 302 'spawn the helper'; _lw_a 300 'Spawned it.'; _lw_age "$LW_F" 300
_hw8_meta "$LW_RR" "$HW8" s8-boss agent-t8 "$HW8H" 'work in a temporary place'
HW8B="$LW/hh8b"; mkdir -p "$HW8B/.claude"; cp -Rp "$LW_RR" "$HW8B/.claude/projects"
rm -f "$HW8B/.claude/projects/$(_lw_enc "$HW8D")/.jsonl"

_lw_run C8A "$HW8A" "$LW/cwd" inventory --tsv --repo "$HW8"
_lw_run C8B "$HW8B" "$LW/cwd" inventory --tsv --repo "$HW8"
_lw_run C8V "$HW8A" "$LW/cwd" inventory --repo "$HW8"
C8A="$(_lw_o C8A)"; C8B="$(_lw_o C8B)"; C8V="$(_lw_o C8V)"
_hw8o=""; for _hw8i in C8A C8B C8V; do _hw8o="$_hw8o$(_lw_rc $_hw8i)$([ -s "$(_lw_o $_hw8i)" ] && echo + || echo -)"; done
is "C8.1 fixture: the three inventory runs over hw8 exit 0 and print something (control)" "$_hw8o" "0+0+0+"

# ---- item 1: the adapter's line is read by position ----------------------------------------------
is "C8.1 fixture: dot-j8's record directory holds one session file, named .jsonl (control)" "$(_hw8_files "$HW8DR")" ".jsonl "
is "C8.1 fixture: the run reads dot-j8's .jsonl: with it the row holds blocked or question, without it neither (control)" \
   "$(_lw_many "$C8A" worktree "$HW8D" 0 blocked question | LC_ALL=C sed 's/blocked=yes question=yes/either/; s/blocked=yes question=no/either/; s/blocked=no question=yes/either/') $(_lw_many "$C8B" worktree "$HW8D" 0 blocked question)" \
   "either blocked=no question=no"
is "C8.1 control: ctl-j8, its only session file s-ctl.jsonl, holds blocked and not question" \
   "$(_lw_many "$C8A" worktree "$HW8C" 0 blocked question)" "blocked=yes question=no"
is "C8.1 control: ctl-j8's owner is s-ctl" "$(_lw_col "$C8A" worktree "$HW8C" 5)" s-ctl
is "C8.1 control: no element of ctl-j8's detail is a bare yes, no or unknown" "$(_hw8_bad "$(_lw_col "$C8A" worktree "$HW8C" 8)")" none
is "C8.1: dot-j8, whose call has waited past --blocked, holds blocked" "$(_lw_holds "$C8A" worktree "$HW8D" blocked)" yes
is "C8.1: dot-j8 does not hold question" "$(_lw_holds "$C8A" worktree "$HW8D" question)" no
is "C8.1: dot-j8's owner is unknown, never empty and never another field's value" "$(_lw_col "$C8A" worktree "$HW8D" 5)" unknown
is "C8.1: no element of dot-j8's detail is a bare yes, no or unknown" "$(_hw8_bad "$(_lw_col "$C8A" worktree "$HW8D" 8)")" none

# ---- item 2: the temporary section shows helper ----------------------------------------------------
is "C8.2 fixture: agent-8e8e8e01 reads unpushed,helper and names its spawning session; plain-t8 reads unpushed (control)" \
   "$(_lw_st "$C8A" worktree "$HW8H") $(_lw_elem "$C8A" worktree "$HW8H" 'spawned by session s8-boss: work in a temporary place') $(_lw_st "$C8A" worktree "$HW8P")" \
   "unpushed,helper yes unpushed"
_hw8h="$(_hw8_vrow "$C8V" agent-8e8e8e01)"; _hw8p="$(_hw8_vrow "$C8V" plain-t8)"
is "C8.2 control: both temporary worktrees are listed under in temporary directories" "${_hw8h%%|*} ${_hw8p%%|*}" \
   "in temporary directories in temporary directories"
is "C8.2 control: in the temporary section each row shows its headline unpushed, and plain-t8's shows no helper" \
   "$(_hw8_word "${_hw8h#*|}" unpushed) $(_hw8_word "${_hw8p#*|}" unpushed) $(_hw8_word "${_hw8p#*|}" helper)" "yes yes no"
is "C8.2: in the temporary section the temp and helper row shows helper among its states" "$(_hw8_word "${_hw8h#*|}" helper)" yes
# <<< helper-worktrees-review-fixes
