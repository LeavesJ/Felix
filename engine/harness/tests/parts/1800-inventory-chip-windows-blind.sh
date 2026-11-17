# >>> inventory-chip-windows
printf '\naudit b09: the chip reader reads windows, not whole files, and the page counts helper work that never reached a PR (C050, C025: A27-A41, blind)\n'
# Blind, written on 2026-10-24 from docs/2026-10-24-audit-fixes/b09-inventory-speed-and-true-owners.md
# alone (sections 2 and 4); felix was run as a black box and no engine code was read. The stubs, the
# runner and the TSV readers are tests/lib/lost-work.sh's (_lw_build); every fixture here is this
# part's own, under $LW, so it runs alone and in the serial order.
#
# cw9: chips whose starts (a custom-title, a start_session call and its result, a first human text)
# lie in a session file's head, its tail, or only between them, the file padded with filler lines a
# reader passes over. cb9: one chip, and eight 16 MiB session files outside the repository's scope
# moved into the records root and out again, to read what they add to the CPU of a run; the 128 MiB
# is removed before the part ends. hq9 and hr9: helper worktrees holding work that never reached a
# pull request, or holding none, on the text page.
_lw_build
# A filler line: {"type":"progress","data":"<4,000 x>"}, 4,030 bytes with its newline.
_c9x=x; while [ "${#_c9x}" -lt 4000 ]; do _c9x="$_c9x$_c9x"; done
C9FL="{\"type\":\"progress\",\"data\":\"${_c9x:0:4000}\"}"
printf '%s\n' "$C9FL" > "$LW/c9.f1"; : > "$LW/c9.f10"; : > "$LW/c9.f100"
for _c9i in 1 2 3 4 5 6 7 8 9 10; do cat "$LW/c9.f1" >> "$LW/c9.f10"; done
for _c9i in 1 2 3 4 5 6 7 8 9 10; do cat "$LW/c9.f10" >> "$LW/c9.f100"; done
_c9_fill() {  # N: N filler lines onto LW_F
  local n="$1"
  while [ "$n" -ge 100 ]; do cat "$LW/c9.f100" >> "$LW_F"; n="$(( n - 100 ))"; done
  while [ "$n" -ge 10 ]; do cat "$LW/c9.f10" >> "$LW_F"; n="$(( n - 10 ))"; done
  while [ "$n" -gt 0 ]; do cat "$LW/c9.f1" >> "$LW_F"; n="$(( n - 1 ))"; done
}
_c9_start() { _lw_open "$LW_RR/-elsewhere-$1/s9-$1.jsonl" "s9-$1"; _lw_h 302 "unrelated $1"; }   # NAME: a starter's file, opening with its first human text
_c9_end() { _lw_a 300 'Done.'; _lw_age "$LW_F" 300; }
_c9_go() {  # TASK TOOL-ID: a start_session call naming TASK as proposal_id, and its result, at 302
  _lw_tu 302 "$2" mcp__ccd_session__start_session "{\"proposal_id\":\"$1\"}"; _lw_tr 302 "$2" 'Started.'; }
# _c9_at FILE PATTERN -> "START END SIZE": where the first line holding PATTERN begins and where it
# ends (past its newline), by grep -b on a match that begins the line, and the file's size; or none
_c9_at() { local l s o; l="$(LC_ALL=C grep -b -m 1 -e "^.*$2" "$1" 2>/dev/null)"; s="$(wc -c < "$1" 2>/dev/null | tr -d ' ')"
  [ -n "$l" ] || { printf none; return; }
  o="${l%%:*}"; printf '%s %s %s' "$o" "$(( o + ${#l} - ${#o} ))" "$s"; }
_c9_mid() { set -- $(_c9_at "$1" "$2"); if [ "$#" -eq 3 ] && [ "$1" -ge 1572864 ] && [ "$(( $3 - $2 ))" -ge 1048576 ]; then printf in; else printf '[%s]' "$*"; fi; }
_c9_head() { set -- $(_c9_at "$1" "$2"); if [ "$#" -eq 3 ] && [ "$2" -le 65536 ]; then printf in; else printf '[%s]' "$*"; fi; }
_c9_tail() { set -- $(_c9_at "$1" "$2"); if [ "$#" -eq 3 ] && [ "$1" -ge "$(( $3 - 65536 ))" ]; then printf in; else printf '[%s]' "$*"; fi; }

# ---- cw9 ------------------------------------------------------------------------------------
_lw_repo cw9; CW9="$LW/cw9"; CW9R="$(_lw_mainwt "$CW9")"; C9OWN="$LW/cw9-wt/own9"; mkdir -p "$LW/cw9-wt"
_lwg "$CW9" worktree add -q -b cw9-own "$C9OWN" main >/dev/null 2>&1
LW_RR="$LW/hcw9/.claude/projects"; mkdir -p "$LW_RR"
_lw_sess "$CW9R" s9-prop; _lw_h 612 'file the chips'; _c9n=0
for _c9t in 'Chip head nine' 'Chip tail nine' 'Chip mid nine' 'Chip s3 head nine' 'Chip s3 tail nine' 'Chip s3 mid nine' 'Chip s3 own nine' 'Chip prompt nine'; do
  _c9n="$(( _c9n + 1 ))"
  _lw_spawn 610 "toolu_9p$_c9n" "task_9e00000$_c9n" "$_c9t" "Prompt nine $_c9n: do the named thing and test it once."
done
_lw_a 600 'Filed.'; _lw_age "$LW_F" 600
_c9_start hd9; _lw_title 'Chip head nine'; _c9_fill 600; _c9_end
_c9_start tl9; _c9_fill 600; _lw_title 'Chip tail nine'; _c9_end
_c9_start md9; _c9_fill 400; _lw_title 'Chip mid nine'; _c9_fill 300; _c9_end
_c9_start s3hd9; _c9_go task_9e000004 toolu_9go4; _c9_fill 600; _c9_end
_c9_start s3tl9; _c9_fill 600; _c9_go task_9e000005 toolu_9go5; _c9_end
_c9_start s3md9; _c9_fill 400; _c9_go task_9e000006 toolu_9go6; _c9_fill 300; _c9_end
_lw_open "$LW_RR/-elsewhere-pr9/s9-pr9.jsonl" s9-pr9; _lw_h 302 'Prompt nine 8: do the named thing and test it once.'; _c9_fill 600; _c9_end
# own9, in scope: a proposal of its own, then chip 7's call and result between its windows.
_lw_sess "$C9OWN" s9-own; _lw_h 402 'do the other thing'
_lw_spawn 401 toolu_9o task_9e000009 'Chip other nine' 'Prompt nine 9: do the other thing once.'
_c9_fill 400; _c9_go task_9e000007 toolu_9go7; _c9_fill 300; _c9_end
_lw_run C9CW "$LW/hcw9" "$LW/cwd" inventory --tsv --no-gh --repo "$CW9"
C9F="$LW_RR/-elsewhere"

# ---- cb9 ------------------------------------------------------------------------------------
_lw_repo cb9; CB9="$LW/cb9"; CB9R="$(_lw_mainwt "$CB9")"; C9BH="$LW/hcb9"; C9BR="$C9BH/.claude/projects"; LW_RR="$C9BR"; mkdir -p "$LW_RR"
_lw_sess "$CB9R" s9-bprop; _lw_spawn 610 toolu_9b task_9e00000b 'Chip bulk nine' 'Prompt nine b: carry the bulk once.'
_lw_a 600 'Filed.'; _lw_age "$LW_F" 600
# 16,777,216 bytes of filler lines: 4,163 whole ones, then one cut to 325 bytes, then a newline.
: > "$LW/c9.bulk"; LW_F="$LW/c9.bulk"; _c9_fill 4163; printf '%s\n' "${C9FL:0:325}" >> "$LW/c9.bulk"
mkdir -p "$LW/bulk9"
for _c9i in 1 2 3 4 5 6 7 8; do
  _lw_open "$LW/bulk9/-elsewhere-bulk9-$_c9i/s9-bulk$_c9i.jsonl" "s9-bulk$_c9i"; _lw_h 302 "bulk $_c9i"
  [ "$_c9i" -gt 4 ] || _lw_title "Bulk title $_c9i"
  cat "$LW/c9.bulk" >> "$LW_F"; _lw_a 300 'Done.'; _lw_age "$LW_F" 300
done
_c9_in() { local i; for i in 1 2 3 4 5 6 7 8; do mv "$LW/bulk9/-elsewhere-bulk9-$i" "$C9BR/" 2>/dev/null; done; }
_c9_out() { local i; for i in 1 2 3 4 5 6 7 8; do mv "$C9BR/-elsewhere-bulk9-$i" "$LW/bulk9/" 2>/dev/null; done; }
_c9_cpu() {  # NAME: the run NAME over cb9; prints its CPU (times' second line, user plus system) in seconds, or unread
  ( _lw_run "$1" "$C9BH" "$LW/cwd" inventory --tsv --no-gh --repo "$CB9"; times ) > "$LW/c9.$1.times" 2>/dev/null
  LC_ALL=C awk 'function s(v,  m) { gsub(/,/, ".", v); m = v; sub(/m.*$/, "", m); sub(/^[0123456789]+m/, "", v); sub(/s$/, "", v); return m * 60 + v }
    NR == 2 && $1 ~ /^[0123456789]+m[0123456789.,]+s$/ && $2 ~ /^[0123456789]+m[0123456789.,]+s$/ { printf "%.3f", s($1) + s($2); f = 1 }
    END { if (!f) printf "unread" }' "$LW/c9.$1.times" 2>/dev/null; }
C9A1="$(_c9_cpu C9A1)"; _c9_in; C9B1="$(_c9_cpu C9B1)"; _c9_out
C9A2="$(_c9_cpu C9A2)"; _c9_in; C9B2="$(_c9_cpu C9B2)"; _c9_out
rm -rf "$LW/bulk9" "$LW/c9.bulk" "$C9BR"/-elsewhere-bulk9-*

# ---- hq9 and hr9 ----------------------------------------------------------------------------
_c9_wt() {  # REPO PATH BRANCH [FILE CONTENT]: a worktree on a new branch from main, with one commit of FILE when given
  _lwg "$1" worktree add -q -b "$3" "$2" main >/dev/null 2>&1
  [ -n "${4:-}" ] || return 0
  printf '%s\n' "$5" > "$2/$4"; _lwg "$2" add -A >/dev/null 2>&1; _lwg "$2" commit -qm "$4" >/dev/null 2>&1
}
_c9_meta() {  # RECORD-ROOT DIR-OF-SPAWNER SID NAME WORKTREE-PATH DESCRIPTION: a meta file and its sibling .jsonl, both 300 minutes old
  local f="$1/$(_lw_enc "$2")/$3/subagents/$4"
  mkdir -p "${f%/*}"
  printf '{"agentType":"general-purpose","description":"%s","worktreePath":"%s"}\n' "$6" "$5" > "$f.meta.json"
  printf '{}\n' > "$f.jsonl"; _lw_age "$f.meta.json" 300; _lw_age "$f.jsonl" 300
}
_c9_blk() {  # DIR SID: a person session in DIR's own record directory whose last record is a Bash call 290 minutes old, unanswered
  _lw_sess "$1" "$2"; _lw_h 292 'run the checks'
  _lw_tu 290 "toolu_$2" Bash '{"command":"run-the-checks","description":"Run the checks"}'; _lw_age "$LW_F" 290
}
_lw_repo hq9; HQ9="$LW/hq9"; HQ9W="$HQ9/.claude/worktrees"; C9PU="$LW/hq9-wt/plain-9u"; mkdir -p "$HQ9W" "$LW/hq9-wt"
_lw_prs fixture_hq9
_c9_wt "$HQ9" "$HQ9W/agent-9a0a0a01" hq9-h1 h1.txt 'helper work never pushed'
_c9_wt "$HQ9" "$HQ9W/agent-9a0a0a02" hq9-h2; printf 'never committed\n' > "$HQ9W/agent-9a0a0a02/new.txt"
_c9_wt "$HQ9" "$HQ9W/agent-9a0a0a03" hq9-h3
_c9_wt "$HQ9" "$HQ9W/agent-9a0a0a04" hq9-h4
mkdir -p "$HQ9W/agent-9a0a0a05"; printf 'an orphan of its own words\n' > "$HQ9W/agent-9a0a0a05/o.txt"
_c9_wt "$HQ9" "$C9PU" hq9-u u.txt 'plain work never pushed'
LW_RR="$LW/hhq9/.claude/projects"; mkdir -p "$LW_RR"
_lw_sess "$HQ9" s9-qboss; _lw_h 302 'spawn the helpers'; _lw_a 300 'Spawned them.'; _lw_age "$LW_F" 300
for _c9i in 1 2 3 4 5; do _c9_meta "$LW_RR" "$HQ9" s9-qboss "agent-q$_c9i" "$HQ9W/agent-9a0a0a0$_c9i" "helper $_c9i"; done
_c9_blk "$HQ9W/agent-9a0a0a04" s9-qdead
_lw_repo hr9; HR9="$LW/hr9"; HR9W="$HR9/.claude/worktrees"; mkdir -p "$HR9W"
_lw_prs fixture_hr9
_c9_wt "$HR9" "$HR9W/agent-9b0b0b01" hr9-h1
_c9_wt "$HR9" "$HR9W/agent-9b0b0b02" hr9-h2
LW_RR="$LW/hhr9/.claude/projects"; mkdir -p "$LW_RR"
_lw_sess "$HR9" s9-rboss; _lw_h 302 'spawn the helpers'; _lw_a 300 'Spawned them.'; _lw_age "$LW_F" 300
for _c9i in 1 2; do _c9_meta "$LW_RR" "$HR9" s9-rboss "agent-r$_c9i" "$HR9W/agent-9b0b0b0$_c9i" "helper $_c9i"; done
_c9_blk "$HR9W/agent-9b0b0b02" s9-rdead
_lw_run C9QX "$LW/hhq9" "$LW/cwd" monitor --repo "$HQ9"
_lw_run C9QT "$LW/hhq9" "$LW/cwd" monitor --tsv --repo "$HQ9"
_lw_run C9RX "$LW/hhr9" "$LW/cwd" monitor --repo "$HR9"

# ---- readers ----------------------------------------------------------------------------------
_c9_coll() {  # TEXT-PAGE -> the collapsed line's elements, one a line
  LC_ALL=C awk 'index($0, "  collapsed: ") == 1 { s = substr($0, 14); n = split(s, e, ", "); for (i = 1; i <= n; i++) print e[i]; exit }' "$1" 2>/dev/null; }
_c9_next() {  # TEXT-PAGE -> the line right after the collapsed line
  LC_ALL=C awk 'f { print; g = 1; exit } index($0, "  collapsed: ") == 1 { f = 1 } END { if (!f) print "no collapsed line"; else if (!g) print "no line after it" }' "$1" 2>/dev/null; }
_c9_tn() {  # TEXT-PAGE REF -> the number of lines on which REF stands, followed by nothing, a blank, a colon or a comma (1580's C5.16 reading)
  LC_ALL=C awk -v r="$2" '{ s = $0; while ((i = index(s, r)) > 0) { z = substr(s, i + length(r), 1); if (z == "" || z == " " || z == ":" || z == ",") { n++; break } s = substr(s, i + length(r)) } } END { print n + 0 }' "$1" 2>/dev/null; }
_c9_tl() { LC_ALL=C awk -v r="$2 " '{ s = $0; sub(/^ +/, "", s); if (index(s, r) == 1) n++ } END { print n + 0 }' "$1" 2>/dev/null; }   # rows listed: lines that start with REF
_c9_chips() { LC_ALL=C awk -F'\t' '$1 == "chip" { printf "%s%s %s", s, $3, $4; s = "; " } END { if (!NR) printf "no rows" }' "$1" 2>/dev/null; }

# ---- C050, the windows: A27 to A35 -----------------------------------------------------------
CWO="$(_lw_o C9CW)"; C9RC="$(_lw_rc C9CW)"
is "A27 (B12, control): a custom-title equal to the chip's title in a file's head starts it: no row, the run exiting 0" "$(_lw_kind "$CWO" task_9e000001) $C9RC" "none 0"
is "A28 (B12, control): the same title in a file's tail starts it: no row" "$(_lw_kind "$CWO" task_9e000002) $C9RC" "none 0"
is "A29 (B12): the same title only between a file's head and tail starts nothing: the chip stays chip-unstarted" \
   "$(_lw_kind "$CWO" task_9e000003) $(_lw_st "$CWO" chip task_9e000003)" "chip chip-unstarted"
is "A30 (B13, control): a start_session call naming the chip as proposal_id, with its result, in a file's head starts it: no row" "$(_lw_kind "$CWO" task_9e000004) $C9RC" "none 0"
is "A31 (B13, control): the same call and result in a file's tail start it: no row" "$(_lw_kind "$CWO" task_9e000005) $C9RC" "none 0"
is "A32 (B13): the same call and result only between a file's head and tail start nothing: the chip stays chip-unstarted" \
   "$(_lw_kind "$CWO" task_9e000006) $(_lw_st "$CWO" chip task_9e000006)" "chip chip-unstarted"
is "A33 (B13, control): in an in-scope file read whole for its own proposal, a call and result between the windows still start the chip, and that file's own chip stays" \
   "$(_lw_kind "$CWO" task_9e000007) $(_lw_st "$CWO" chip task_9e000009) $C9RC" "none chip-unstarted 0"
is "A34 (B14, control): a starter whose first human text is the chip's prompt starts it however long the file is: no row" "$(_lw_kind "$CWO" task_9e000008) $C9RC" "none 0"
is "A35 (fixture control): by grep -b, md9's title and s3md9's call lie past 1.5 MiB and over 1 MiB before the end; hd9's and s3hd9's in the first 64 KiB; tl9's and s3tl9's in the last 64 KiB" \
   "md9 $(_c9_mid "$C9F-md9/s9-md9.jsonl" '"customTitle":"Chip mid nine"'), s3md9 $(_c9_mid "$C9F-s3md9/s9-s3md9.jsonl" '"id":"toolu_9go6"'), hd9 $(_c9_head "$C9F-hd9/s9-hd9.jsonl" '"customTitle":"Chip head nine"'), s3hd9 $(_c9_head "$C9F-s3hd9/s9-s3hd9.jsonl" '"id":"toolu_9go4"'), tl9 $(_c9_tail "$C9F-tl9/s9-tl9.jsonl" '"customTitle":"Chip tail nine"'), s3tl9 $(_c9_tail "$C9F-s3tl9/s9-s3tl9.jsonl" '"id":"toolu_9go5"')" \
   "md9 in, s3md9 in, hd9 in, s3hd9 in, tl9 in, s3tl9 in"

# ---- C050, the cost: A36 and A37 -------------------------------------------------------------
_c9n="A36 (B15): eight 16 MiB session files outside every window add at most 0.75 s to the CPU of the run (lower of two with them, less lower of two without)"
_c9rc="$(_lw_rc C9A1)$(_lw_rc C9B1)$(_lw_rc C9A2)$(_lw_rc C9B2)"
_c9d="$(LC_ALL=C awk -v a1="$C9A1" -v a2="$C9A2" -v b1="$C9B1" -v b2="$C9B2" 'BEGIN {
  if (a1 !~ /^[0123456789.]+$/ || a2 !~ /^[0123456789.]+$/ || b1 !~ /^[0123456789.]+$/ || b2 !~ /^[0123456789.]+$/) { print "not measured"; exit }
  a = (a1 + 0 < a2 + 0) ? a1 + 0 : a2 + 0; b = (b1 + 0 < b2 + 0) ? b1 + 0 : b2 + 0
  if (b - a <= 0.75) print "within"; else printf "%.3f s more\n", b - a }')"
if [ "$_c9rc" = 0000 ] && [ "$_c9d" = within ]; then ok "$_c9n"
else bad "$_c9n" "A1 $C9A1 s, A2 $C9A2 s, B1 $C9B1 s, B2 $C9B2 s (exits $_c9rc): $_c9d"; fi
is "A37 (B15, control): with the eight files the chip rows, ref and states, are those without them: one row, task_9e00000b chip-unstarted" \
   "$(_c9_chips "$(_lw_o C9B1)")|$(_c9_chips "$(_lw_o C9A1)")" "task_9e00000b chip-unstarted|task_9e00000b chip-unstarted"

# ---- C025, the page: A38 to A41 --------------------------------------------------------------
QXO="$(_lw_o C9QX)"; QTO="$(_lw_o C9QT)"; RXO="$(_lw_o C9RX)"
is "A38 (B16): the collapsed line says helper worktrees 5, and the line after it counts the 3 helper rows holding work that never reached a PR" \
   "$(_c9_coll "$QXO" | LC_ALL=C awk '$0 == "helper worktrees 5" { n++ } END { print n + 0 }')|$(_c9_next "$QXO")" \
   "1|  helper worktrees holding work that never reached a PR: 3"
_c9o=""; for _c9i in 1 2 3 4 5; do _c9o="$_c9o $(_c9_tn "$QXO" "$HQ9W/agent-9a0a0a0$_c9i")"; done
is "A39 (B16, control): no line of the text page names any of the five helpers' paths, and the plain unpushed worktree is listed once" \
   "$_c9o|$(_c9_tl "$QXO" "$C9PU")" " 0 0 0 0 0|1"
is "A40 (B17, control): --tsv keeps 17 summary rows, helper complete with 5, and the plain unpushed worktree alone in never-proposed, complete with 1" \
   "$(_lw_n16 "$QTO") $(_lw_st "$QTO" summary helper 1) $(_lw_col "$QTO" summary helper 7 1) $(_lw_col "$QTO" worktree "$C9PU" 0 1) $(_lw_st "$QTO" summary never-proposed 1) $(_lw_col "$QTO" summary never-proposed 7 1)" \
   "17 complete 5 never-proposed complete 1"
is "A41 (B16, control): with no helper row holding such work no count line is printed, and the collapsed line, saying helper worktrees 2, stays last" \
   "$(LC_ALL=C awk 'index($0, "  helper worktrees holding") == 1 { n++ } END { print n + 0 }' "$RXO" 2>/dev/null)|$(LC_ALL=C awk 'END { print (index($0, "  collapsed: ") == 1) ? "collapsed last" : "last: " $0 }' "$RXO" 2>/dev/null)|$(_c9_coll "$RXO" | LC_ALL=C awk '$0 == "helper worktrees 2" { n++ } END { print n + 0 }')" \
   "0|collapsed last|1"
# <<< inventory-chip-windows
