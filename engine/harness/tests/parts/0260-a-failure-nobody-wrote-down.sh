printf '\na failure nobody wrote down\n'
# Felix has had `felix lesson` from the beginning, and a mechanism nobody uses
# is half a mechanism. This fires only when the gate actually caught something
# and nothing was written since — most sessions teach nothing, and a prompt
# that fires every time is one people learn to dismiss.
_memory_guarded_build
: > "$MEM/guarded/lessons.md"; : > "$MEM/guarded/DEVLOG.md"
out="$( . "$FROOT/harness/lib/guard.sh"; felix_guard_unrecorded "$GP" )"
is "silent when the gate has caught nothing" "${#out}" "0"

# `felix_guard_unrecorded` asks whether the catch is newer than the lesson, so
# these two files must have an order and not merely a sequence of writes. They
# were written milliseconds apart and the assertion relied on the filesystem
# resolving that — true on a laptop, and on the CI runner a coin toss that both
# assertions lost the moment anything upstream shifted the timing. Adding tests
# elsewhere in this file turned it red. The `sleep 1` below was the same problem
# noticed once and paid for in wall-clock rather than fixed.
#
# So the order is stated. Every case sets the mtimes it depends on, which also
# means the run is a second faster and neither case can be won by luck.
GYDAY="$(date -v-1d +%Y%m%d%H%M 2>/dev/null || date -d '1 day ago' +%Y%m%d%H%M)"
# Dated today, as the gate dates a row. An untimed row is aged by the day it
# names since rows began carrying their own time, and a row dated January
# in a file written today would be history rather than the catch this asks
# about.
printf '%s\tmain\tabc123\tlint\n' "$(date +%Y-%m-%d)" > "$MEM/guarded/mistakes.log"
touch -t "$GYDAY" "$MEM/guarded/lessons.md" "$MEM/guarded/DEVLOG.md" 2>/dev/null
# Asserted here, where the state is load-bearing. This was the case that went
# red on CI when the guard compared the catch with the lessons file's time; it
# now reads only the entries written.log records, so what the prompt below
# rests on is that none has been written yet, whatever the files' times say.
[ ! -s "$MEM/guarded/written.log" ] \
  && ok  "the fixture has no entry written for the catch yet" \
  || bad "the fixture has no entry written for the catch yet" "$(cat "$MEM/guarded/written.log")"
# Asked from a checkout on the branch the catch names, because an entry settles
# only the catches of whoever wrote it, and a guard told no checkout cannot
# know whose a catch is.
GRP="$TMP/guarded-main"; mkdir -p "$GRP" && ( _fx_cd "$GRP" && git init -q -b main \
  && git -c user.name=t -c user.email=t@t commit -q --allow-empty -m init ) >/dev/null 2>&1
out="$( . "$FROOT/harness/lib/guard.sh"; felix_guard_unrecorded "$GP" "$GRP" )"
has "speaks when a catch went unexplained" "$out" "nothing has been written down"
has "and names what was caught"            "$out" "lint"

# Writing a lesson settles the debt; it must then go quiet. The catch is aged a
# day rather than the lesson being written a second later: still well inside the
# seven days that keep it from being ancient history, and no longer a race.
# Written through felix lesson, which records whose it is beside the prose.
( . "$FROOT/harness/lib/memory.sh"; felix_mem_lesson "$GP" "$GRP" "something learned" ) >/dev/null 2>&1
touch -t "$GYDAY" "$MEM/guarded/mistakes.log" 2>/dev/null
out="$( . "$FROOT/harness/lib/guard.sh"; felix_guard_unrecorded "$GP" "$GRP" )"
is "and stops once something is written" "${#out}" "0"

# A devlog entry settles the debt too, and that half had no coverage at all
# once: a fixture that never wrote one let the whole clause be deleted with the
# suite still green. Both directions asserted, or the quiet one proves nothing.
rm -f "$MEM/guarded/written.log"
printf '%s\tmain\tabc123\tlint\n' "$(date +%Y-%m-%d)" > "$MEM/guarded/mistakes.log"
touch -t "$GYDAY" "$MEM/guarded/mistakes.log" 2>/dev/null
( . "$FROOT/harness/lib/memory.sh"; felix_mem_log "$GP" "$GRP" "what happened and why" ) >/dev/null 2>&1
out="$( . "$FROOT/harness/lib/guard.sh"; felix_guard_unrecorded "$GP" "$GRP" )"
is "a devlog entry newer than the catch settles it too" "${#out}" "0"
printf '%s\tmain\tabc123\tlog\t%s\t-\n' "$(date -v-2d +%Y-%m-%d 2>/dev/null || date -d '2 days ago' +%Y-%m-%d)" \
  "$(( $(date +%s) - 172800 ))" > "$MEM/guarded/written.log"
out="$( . "$FROOT/harness/lib/guard.sh"; felix_guard_unrecorded "$GP" "$GRP" )"
has "and an older one does not" "$out" "nothing has been written down"
rm -f "$MEM/guarded/written.log"

# An old debt is history, not something this session can explain.
printf '2020-01-01\tmain\tabc\told\n' > "$MEM/guarded/mistakes.log"
touch -t 202001010000 "$MEM/guarded/mistakes.log" 2>/dev/null
out="$( . "$FROOT/harness/lib/guard.sh"; felix_guard_unrecorded "$GP" )"
is "and does not nag about ancient history" "${#out}" "0"

# Whose catch it is. Every session's gate appends to the one mistakes.log a
# project has, so with many sessions open the newest row is usually somebody
# else's, and the guard compared the whole file's time with the lessons. On
# 2026-09-25 a session that had merged #339 and written its lesson at 08:19 was
# asked three times about a `tests` catch another branch logged at 08:27. The
# gate now files each row with the second it was caught and the session that
# ran it, and the guard weighs only this session's rows, or, for a row that
# names no session, the rows of the branch this checkout has checked out.
#
# The times are minutes apart and stated, never left to the order of writes:
# the section above is the account of what that cost.
UNOW="$(date +%s)"
_ur_ago() { date -v-"$1"M +%Y%m%d%H%M 2>/dev/null || date -d "$1 minutes ago" +%Y%m%d%H%M; }
_ur_day() { date -v-"$1"d +%Y-%m-%d 2>/dev/null || date -d "$1 days ago" +%Y-%m-%d; }
_ur_at()  { date -d "@$1" +%Y%m%d%H%M.%S 2>/dev/null || date -r "$1" +%Y%m%d%H%M.%S; }
_ur_row() {   # branch, check, minutes ago, [session]: the shape felix_mem_mistake writes
  printf '%s\t%s\t%s\t%s \t%s\t%s\n' "$(date +%Y-%m-%d)" "$1" 0123abcd "$2" "$((UNOW - $3 * 60))" "${4:--}"
}
_ur_repo() {  # dir, branch
  mkdir -p "$1" && ( _fx_cd "$1" && git init -q -b "$2" \
    && git -c user.name=t -c user.email=t@t commit -q --allow-empty -m init ) >/dev/null 2>&1
}
_ur() { ( . "$FROOT/harness/lib/guard.sh"; felix_guard_unrecorded "$GP" "$1" "${2:-}" ); }
# An entry settles only its writer's catches, so a lesson here is the prose
# and the row felix lesson files beside it, naming its owner: this checkout's
# branch and no session unless one is given. The prose is also given a time,
# the entry's own, so no case is settled by a file's time rather than its row.
_ur_eday() { date -d "@$1" +%Y-%m-%d 2>/dev/null || date -r "$1" +%Y-%m-%d; }
_ur_w() {     # epoch, kind, [branch], [session]: the shape felix_mem_lesson writes
  printf '%s\t%s\t0123abcd\t%s\t%s\t%s\n' "$(_ur_eday "$1")" "${3:-claude/this-checkout}" "$2" "$1" "${4:--}"
}
_ur_lesson() {   # minutes ago, [branch], [session]
  printf -- '- **a lesson**\n' > "$MEM/guarded/lessons.md"; touch -t "$(_ur_ago "$1")" "$MEM/guarded/lessons.md"
  _ur_w "$((UNOW - $1 * 60))" lesson "${2:-}" "${3:-}" > "$MEM/guarded/written.log"
}
UCK="$TMP/unrec-checkout"; _ur_repo "$UCK" claude/this-checkout
: > "$MEM/guarded/DEVLOG.md"; _ur_lesson 60

_ur_row claude/peer tests 30 > "$MEM/guarded/mistakes.log"
is "a peer branch's newer catch does not prompt" "$(_ur "$UCK")" ""

{ _ur_row claude/this-checkout lint 30; _ur_row claude/peer tests 10; } > "$MEM/guarded/mistakes.log"
has "this branch's own newer catch still prompts, and names it rather than a peer's logged after it" \
    "$(_ur "$UCK")" "last caught   lint"

{ _ur_row claude/this-checkout lint 120; _ur_row claude/peer tests 30; } > "$MEM/guarded/mistakes.log"
is  "a lesson written after this branch's catch clears it, whatever a peer logged since" "$(_ur "$UCK")" ""
# The same rows with the lesson moved before the catch, or the silence above
# could be a guard that says nothing at all.
_ur_lesson 180
has "and a lesson written before it does not" "$(_ur "$UCK")" "last caught   lint"
printf '## an entry\n' > "$MEM/guarded/DEVLOG.md"; touch -t "$(_ur_ago 60)" "$MEM/guarded/DEVLOG.md"
_ur_w "$((UNOW - 3600))" log >> "$MEM/guarded/written.log"
is  "a devlog entry after this branch's catch clears it too" "$(_ur "$UCK")" ""
: > "$MEM/guarded/DEVLOG.md"; _ur_lesson 180
# To the second, not the minute: every case above is minutes apart, which a
# guard comparing minutes would pass as well.
printf '%s\tclaude/this-checkout\t0123abcd\tlint \t%s\t-\n' "$(date +%Y-%m-%d)" "$((UNOW - 600))" > "$MEM/guarded/mistakes.log"
touch -t "$(_ur_at $((UNOW - 570)))" "$MEM/guarded/lessons.md"; _ur_w "$((UNOW - 570))" lesson > "$MEM/guarded/written.log"
is  "a lesson thirty seconds after the catch clears it" "$(_ur "$UCK")" ""
touch -t "$(_ur_at $((UNOW - 630)))" "$MEM/guarded/lessons.md"; _ur_w "$((UNOW - 630))" lesson > "$MEM/guarded/written.log"
has "and one thirty seconds before it does not" "$(_ur "$UCK")" "last caught   lint"

# The week is this catch's week. A peer appending keeps the file's time fresh
# forever, and a debt that was history must not come back because of it. A row
# from before rows carried a time is aged by the day it names.
_ur_lesson 12960
{ _ur_row claude/this-checkout lint 11520; _ur_row claude/peer tests 10; } > "$MEM/guarded/mistakes.log"
is "this branch's week-old catch stays history while a peer's rows keep the file fresh" "$(_ur "$UCK")" ""
# The only entry a fortnight old, so nothing but the day's own age can make
# this history: a later-day entry would settle it and hide a missing cutoff.
_ur_lesson 20160
{ printf '%s\tclaude/this-checkout\t0123abcd\tlint \n' "$(_ur_day 10)"; _ur_row claude/peer tests 10; } \
  > "$MEM/guarded/mistakes.log"
is "and so does an untimed row dated ten days back" "$(_ur "$UCK")" ""
# A date column that is not a date names no day: it neither makes the row
# history nor keeps the file's own week from aging it.
_ur_lesson 60
{ printf '\tclaude/this-checkout\t0123abcd\tlint \n'; _ur_row claude/peer tests 10; } > "$MEM/guarded/mistakes.log"
has "an untimed row with an empty date is not taken for history" "$(_ur "$UCK")" "last caught   lint"
{ printf -- '-\tclaude/this-checkout\t0123abcd\tlint \n'; _ur_row claude/peer tests 10; } > "$MEM/guarded/mistakes.log"
has "nor one whose date is a dash, which sorts before every day" "$(_ur "$UCK")" "last caught   lint"
# And a fortnight-old entry again, or one after the file's time would settle
# the row and hide a file that never aged.
_ur_lesson 20160
printf 'garbage\tclaude/this-checkout\t0123abcd\tlint \n' > "$MEM/guarded/mistakes.log"
touch -t "$(_ur_ago 11520)" "$MEM/guarded/mistakes.log"
is "and one whose date is unreadable still ages out with the file" "$(_ur "$UCK")" ""
# An untimed row was caught by the end of the day it names, so a lesson from
# a later day settles it, however fresh a peer keeps the file. Without this,
# every checkout on a branch with a row from before this change was asked at
# each peer's append until the row's week ran out. Two days back, so a lesson
# half an hour old is on a later day even just after midnight.
{ printf '%s\tclaude/this-checkout\t0123abcd\tlint \n' "$(_ur_day 2)"; _ur_row claude/peer tests 1; } \
  > "$MEM/guarded/mistakes.log"
_ur_lesson 30
is "an untimed row is settled by a lesson written on a later day than it names" "$(_ur "$UCK")" ""
{ printf '%s\tclaude/this-checkout\t0123abcd\tlint \n' "$(_ur_day 2)"; _ur_row claude/peer tests 1; } \
  > "$MEM/guarded/mistakes.log"
_ur_lesson 4320
has "and not by one from an earlier day" "$(_ur "$UCK")" "last caught   lint"
_ur_lesson 60

# The session that ran the gate owns the row, wherever the gate stood. The
# branch was a stand-in for it, and the review of this change found where the
# stand-in fails open: a session that gated on the branch it was handed and
# then made its own, one that gated another checkout, one that ran checkout -B.
# A row naming another session is that session's, on this very branch too.
UCK2="$TMP/unrec-renamed"; _ur_repo "$UCK2" auto/handed
( _fx_cd "$UCK2" && git checkout -q -b claude/made && git branch -m claude/renamed ) >/dev/null 2>&1
{ _ur_row auto/handed lint 30 ur-this; _ur_row claude/peer tests 10 ur-peer; } > "$MEM/guarded/mistakes.log"
has "this session's catch prompts after its checkout moves to another branch" \
    "$(_ur "$UCK2" ur-this)" "last caught   lint"
{ _ur_row claude/renamed lint 30 ur-earlier; _ur_row claude/peer tests 10 ur-peer; } > "$MEM/guarded/mistakes.log"
is  "and another session's catch on this very branch does not" "$(_ur "$UCK2" ur-this)" ""
has "a conversation holding more than one session owns the rows of each" \
    "$(_ur "$UCK2" "ur-restored ur-earlier")" "last caught   lint"
{ _ur_row claude/renamed lint 30; _ur_row claude/peer tests 10 ur-peer; } > "$MEM/guarded/mistakes.log"
has "a row that names no session is this checkout's when its branch is the one checked out" \
    "$(_ur "$UCK2" ur-this)" "last caught   lint"
UCK3="$TMP/unrec-reused"; _ur_repo "$UCK3" claude/earlier-session
( _fx_cd "$UCK3" && git checkout -q --detach && git checkout -q -b claude/this-session ) >/dev/null 2>&1
_ur_row claude/earlier-session lint 30 > "$MEM/guarded/mistakes.log"
is  "and an earlier session's catch in a reused checkout does not" "$(_ur "$UCK3" ur-this)" ""
( _fx_cd "$UCK3" && git checkout -q --detach ) >/dev/null 2>&1
{ _ur_row HEAD lint 30; _ur_row claude/peer tests 10; } > "$MEM/guarded/mistakes.log"
has "a detached checkout's own catch, filed as HEAD, prompts" "$(_ur "$UCK3")" "last caught   lint"
# A checkout git cannot name, and a row from before rows carried a time, are
# both weighed the way the whole file used to be: toward asking.
mkdir -p "$TMP/unrec-plain"
_ur_row claude/peer tests 30 > "$MEM/guarded/mistakes.log"
has "a checkout git cannot name weighs every catch, as before" "$(_ur "$TMP/unrec-plain")" "last caught   tests"
{ printf '%s\tclaude/this-checkout\t0123abcd\tlint \n' "$(date +%Y-%m-%d)"; _ur_row claude/peer tests 90; } \
  > "$MEM/guarded/mistakes.log"
has "an untimed row of this branch's is taken at the file's time" "$(_ur "$UCK")" "last caught   lint"
# A time column that is not a time is read as none, toward asking, and quietly:
# the arithmetic it would otherwise reach aborts on a leading zero.
printf '%s\tclaude/this-checkout\t0123abcd\tlint \t0189\t-\n' "$(date +%Y-%m-%d)" > "$MEM/guarded/mistakes.log"
out="$( ( . "$FROOT/harness/lib/guard.sh"; felix_guard_unrecorded "$GP" "$UCK" ) 2>&1 )"
case "$out" in
  *"last caught   lint"*) case "$out" in *"base"*|*"expression"*|*"guard.sh"*) bad "a time column that is not a time is read as none" "$out" ;;
                            *) ok "a time column that is not a time is read as none" ;; esac ;;
  *) bad "a time column that is not a time is read as none" "$out" ;;
esac

# Whose entry it is. A lesson or a devlog entry settles only the catches of
# whoever wrote it: the session, for a catch that names one, and the branch,
# for one that names none. The project's lessons.md is written all day by
# every session on it, and review measured a peer's lesson landing within
# hours of nearly every catch, which the file's time took as this session's
# explanation. The catch is this session's in each case below, and in each the
# entry is written well after it; only whose entry it is changes.
{ _ur_row claude/this-checkout lint 120 ur-this; _ur_row claude/peer tests 30 ur-peer; } > "$MEM/guarded/mistakes.log"
_ur_lesson 60 claude/this-checkout ur-this
is  "this session's own lesson after its catch settles it" "$(_ur "$UCK" ur-this)" ""
_ur_lesson 60 claude/this-checkout ur-peer
has "a peer session's lesson after this session's catch does not, on this very branch" \
    "$(_ur "$UCK" ur-this)" "last caught   lint"
_ur_lesson 60 claude/this-checkout
has "nor does one that names no session, as from a terminal outside every session" \
    "$(_ur "$UCK" ur-this)" "last caught   lint"
_ur_lesson 60 claude/elsewhere ur-this
is  "while this session's lesson settles its catch from any branch it stood on" "$(_ur "$UCK" ur-this)" ""
_ur_lesson 60 claude/this-checkout "ur-restored ur-this"
has "and an entry whose session column is not one id is nobody's" \
    "$(_ur "$UCK" "ur-restored ur-this")" "last caught   lint"
_ur_lesson 60 claude/this-checkout ur-restored
is  "an entry under any of the conversation's sessions settles its catch" "$(_ur "$UCK" "ur-restored ur-this")" ""
# The prose settles nothing. A lesson typed into lessons.md by hand, or a
# consolidation that rewrites the file, names no owner.
: > "$MEM/guarded/written.log"; touch -t "$(_ur_ago 60)" "$MEM/guarded/lessons.md"
has "a lesson written into the file by hand after the catch settles nothing" \
    "$(_ur "$UCK" ur-this)" "last caught   lint"
printf '## an entry\n' > "$MEM/guarded/DEVLOG.md"; touch -t "$(_ur_ago 60)" "$MEM/guarded/DEVLOG.md"
has "nor does a devlog entry written by hand" "$(_ur "$UCK" ur-this)" "last caught   lint"
: > "$MEM/guarded/DEVLOG.md"
# A catch naming no session is its branch's, and so is its settling.
{ _ur_row claude/this-checkout lint 120; _ur_row claude/peer tests 30; } > "$MEM/guarded/mistakes.log"
_ur_lesson 60 claude/peer ur-peer
has "a catch naming no session is not settled by another branch's lesson" "$(_ur "$UCK" ur-this)" "last caught   lint"
_ur_lesson 60 claude/this-checkout ur-peer
is  "but is by one written on its own branch, whoever wrote it" "$(_ur "$UCK" ur-this)" ""
# Where the guard cannot tell whose a catch is, it cannot tell whose an entry
# is either, and it goes on asking.
_ur_row claude/this-checkout lint 120 > "$MEM/guarded/mistakes.log"
_ur_lesson 60 claude/this-checkout
has "a checkout git cannot name has no entry settle a catch naming no session" \
    "$(_ur "$TMP/unrec-plain")" "last caught   lint"
# An entry's time is read as a time only when it is one, as a catch's is.
{ _ur_row claude/this-checkout lint 120 ur-this; } > "$MEM/guarded/mistakes.log"
printf '%s\tclaude/elsewhere\t0123abcd\tlesson\t0%s\tur-this\n' "$(date +%Y-%m-%d)" "$((UNOW - 3600))" > "$MEM/guarded/written.log"
has "an entry whose time is not a time settles nothing" "$(_ur "$UCK" ur-this)" "last caught   lint"
_ur_lesson 60

# Each kind of owner is weighed on its own. A catch naming no session is
# settled by anyone's entry on its branch, and review showed one landing after
# this session's own letting a peer's lesson on the branch silence both: the
# guard weighed only the newest row it owned, which was the other one.
{ _ur_row claude/this-checkout lint 120 ur-this; _ur_row claude/this-checkout tests 90; } > "$MEM/guarded/mistakes.log"
_ur_lesson 60 claude/this-checkout ur-peer
has "a catch naming no session after this session's own does not let a peer's lesson settle this session's" \
    "$(_ur "$UCK" ur-this)" "last caught   lint"
_ur_lesson 60 claude/elsewhere ur-this
has "and with this session's own settled, the one naming no session is still asked about" \
    "$(_ur "$UCK" ur-this)" "last caught   tests"
_ur_lesson 60 claude/this-checkout ur-this
is  "while this session's lesson on the branch settles both" "$(_ur "$UCK" ur-this)" ""
# An entry dated after now is after nothing: a clock set back, or a row
# written ahead, must not settle catches that have not happened yet.
_ur_row claude/this-checkout lint 120 ur-this > "$MEM/guarded/mistakes.log"
_ur_w "$((UNOW + 86400))" lesson claude/this-checkout ur-this > "$MEM/guarded/written.log"
has "an entry of this session's dated tomorrow does not settle its catch" "$(_ur "$UCK" ur-this)" "last caught   lint"
{ printf '%s\tclaude/this-checkout\t0123abcd\tlint \n' "$(_ur_day 2)"; } > "$MEM/guarded/mistakes.log"
printf '%s\tclaude/this-checkout\t0123abcd\tlesson\t%s\t-\n' "$(date -v+1d +%Y-%m-%d 2>/dev/null || date -d tomorrow +%Y-%m-%d)" \
  "$((UNOW - 3600 * 48))" > "$MEM/guarded/written.log"
has "nor does one whose day is after today settle an untimed catch" "$(_ur "$UCK")" "last caught   lint"
_ur_lesson 60

# The writer. The session is the one the platform exports to the gate's shell,
# the same id the Stop hook is handed, and a subagent's shell carries its
# parent's, so a catch made on a session's behalf is that session's to explain.
: > "$MEM/guarded/mistakes.log"
( . "$FROOT/harness/lib/memory.sh"; CLAUDE_CODE_SESSION_ID=ur-writer felix_mem_mistake "$GP" "$UCK" lint ) >/dev/null 2>&1
is "the gate's row names the session that ran it" "$(tail -1 "$MEM/guarded/mistakes.log" | cut -f2,6)" "claude/this-checkout	ur-writer"
( . "$FROOT/harness/lib/memory.sh"; unset CLAUDE_CODE_SESSION_ID; felix_mem_mistake "$GP" "$UCK" lint ) >/dev/null 2>&1
is "and a dash when no session ran it" "$(tail -1 "$MEM/guarded/mistakes.log" | cut -f6)" "-"
( . "$FROOT/harness/lib/memory.sh"; CLAUDE_CODE_SESSION_ID="$(printf 'a\tb')" felix_mem_mistake "$GP" "$UCK" lint ) >/dev/null 2>&1
is "and a dash for an id that would break the row" "$(tail -1 "$MEM/guarded/mistakes.log" | awk -F'\t' '{print NF "|" $6}')" "6|-"
# A checkout with no commit yet. `rev-parse --abbrev-ref` prints HEAD and fails
# there, so its fallback wrote a second line into the row, and the fifth
# column landed in the fourth, where every reader of checks would take a
# timestamp for one.
UUB="$TMP/unrec-unborn"; mkdir -p "$UUB" && ( _fx_cd "$UUB" && git init -q -b claude/unborn ) >/dev/null 2>&1
: > "$MEM/guarded/mistakes.log"
( . "$FROOT/harness/lib/memory.sh"; felix_mem_mistake "$GP" "$UUB" lint ) >/dev/null 2>&1
is "a checkout with no commit yet writes one row, under its branch" \
   "$(wc -l < "$MEM/guarded/mistakes.log" | tr -d ' ')|$(cut -f2,4 "$MEM/guarded/mistakes.log" | head -1)" "1|claude/unborn	lint"
( _fx_cd "$UCK3" && git checkout -q --detach ) >/dev/null 2>&1
( . "$FROOT/harness/lib/memory.sh"; felix_mem_mistake "$GP" "$UCK3" lint ) >/dev/null 2>&1
is "and a detached one files under HEAD, as the guard reads it" "$(tail -1 "$MEM/guarded/mistakes.log" | cut -f2)" "HEAD"

# And the entries that settle a catch name their writer the same way: the
# session exported to the shell that ran felix lesson or felix log, the branch
# that checkout had, as one field, and the second. The prose is what it was.
rm -f "$MEM/guarded/written.log"; : > "$MEM/guarded/lessons.md"; : > "$MEM/guarded/DEVLOG.md"
_uwb="$(date +%s)"; _uwd0="$(date +%Y-%m-%d)"
( . "$FROOT/harness/lib/memory.sh"; CLAUDE_CODE_SESSION_ID=ur-writer felix_mem_lesson "$GP" "$UCK" "a durable thing" ) >/dev/null 2>&1
( . "$FROOT/harness/lib/memory.sh"; unset CLAUDE_CODE_SESSION_ID; felix_mem_log "$GP" "$UUB" "a one-off" ) >/dev/null 2>&1
_uwa="$(date +%s)"; _uwd1="$(date +%Y-%m-%d)"
is "felix lesson files its writer beside the lesson: branch, kind and session" \
   "$(head -1 "$MEM/guarded/written.log" | cut -f2,4,6)" "claude/this-checkout	lesson	ur-writer"
# Its commit is `unborn`, the word felix_head_commit (lib/resolve.sh) has for
# a checkout with no commit yet, which every row and devlog header is spelled
# by; `?` is a directory that is no repository.
is "and felix log does too, a dash for no session and the branch of a checkout with no commit" \
   "$(sed -n 2p "$MEM/guarded/written.log" | cut -f2,3,4,6)" "claude/unborn	unborn	log	-"
_uwn=0
for _uwe in $(cut -f5 "$MEM/guarded/written.log"); do
  case "$_uwe" in ''|*[!0-9]*) continue ;; esac
  [ "$_uwe" -ge "$_uwb" ] && [ "$_uwe" -le "$_uwa" ] && _uwn=$((_uwn + 1))
done
is "each at the second it was written" "$_uwn" "2"
is "one row per entry, six columns each" "$(awk -F'\t' '{ print NF }' "$MEM/guarded/written.log" | tr '\n' ' ')" "6 6 "
# Dated by the day the writes began, which is the day they wrote unless the
# run crossed midnight between them, when neither day can be expected.
if [ "$_uwd0" = "$_uwd1" ]; then
  is "and the lesson itself is the prose it always was" "$(cat "$MEM/guarded/lessons.md")" "
- **$_uwd0** a durable thing"
  is "as is the devlog entry, its header one line on a checkout with no commit" \
     "$(cat "$MEM/guarded/DEVLOG.md")" "
## $_uwd0 claude/unborn unborn

a one-off"
else
  skip "and the lesson itself is the prose it always was" "the writes crossed midnight"
  skip "as is the devlog entry, its header one line on a checkout with no commit" "the writes crossed midnight"
fi
rm -f "$MEM/guarded/written.log"; : > "$MEM/guarded/lessons.md"

# Through the Stop hook, where it is read. Called without a checkout or a
# session the guard weighs every row, so a hook that never passed them would
# leave every assertion above green and the founder still asked about a peer's
# catch.
UHP="$FROOT/projects/unrechook"; mkdir -p "$UHP" "$MEM/unrechook"
printf '{\n  "name": "unrechook",\n  "remote_match": "example.com/unrechook",\n  "gate": "true"\n}\n' > "$UHP/project.json"
cp "$TMP/probes.keep" "$UHP/probes.tsv"
UHR="$TMP/unrechook-repo"; _ur_repo "$UHR" claude/this-checkout
UHR="$(cd "$UHR" && pwd -P)"
printf 'unrechook\n' > "$UHR/.felix"; printf 'uncommitted\n' > "$UHR/work.txt"
( cd "$UHR" && . "$FROOT/harness/lib/verify.sh"
  felix_verify_record "$UHR" "$FROOT" 0 "gate.sh" "$(felix_tree_id "$UHR" "$FROOT")" "" >/dev/null 2>&1 )
printf -- '- **a lesson**\n' > "$MEM/unrechook/lessons.md"; touch -t "$(_ur_ago 60)" "$MEM/unrechook/lessons.md"
_ur_stop() { ( cd "$UHR" && printf '{"hook_event_name":"Stop","stop_hook_active":false,"session_id":"%s"}' "$1" \
               | "$FROOT/harness/hooks/stop" 2>&1 ); }
_ur_row claude/this-checkout lint 30 ur-own > "$MEM/unrechook/mistakes.log"
has "through the Stop hook, this session's own catch prompts" "$(_ur_stop ur-own)" "nothing has been written down"
_ur_row claude/this-checkout lint 30 ur-own > "$MEM/unrechook/mistakes.log"
is  "and another session's on this same branch does not" "$(_ur_stop ur-peer)" ""
_ur_row claude/peer tests 30 > "$MEM/unrechook/mistakes.log"
is  "and a peer branch's does not, nor anything else on this green stop" "$(_ur_stop ur-peer2)" ""
# A conversation the desktop app carried on under a new id: its transcript
# opens under the old one, and the catch made then is still this one's. A
# transcript that never held that id does not claim it.
_ur_stop_tp() { ( cd "$UHR" && printf '{"hook_event_name":"Stop","stop_hook_active":false,"session_id":"%s","transcript_path":"%s"}' "$1" "$2" \
                  | "$FROOT/harness/hooks/stop" 2>&1 ); }
printf '%s\n' '{"type":"user","sessionId":"ur-before","message":{"content":"a \"sessionId\":\"ur-quoted\" in the text"},"toolUseResult":{"sessionId":"ur-nested"}}' \
               '{"type":"user","sessionId":"ur-after","message":{"content":"on"}}' > "$TMP/ur-restored.jsonl"
printf '%s\n' '{"type":"user","sessionId":"ur-other","message":{"content":"x"}}' > "$TMP/ur-other.jsonl"
_ur_row claude/peer lint 30 ur-before > "$MEM/unrechook/mistakes.log"
has "through the Stop hook, a catch under the id the transcript opens with is this conversation's" \
    "$(_ur_stop_tp ur-after "$TMP/ur-restored.jsonl")" "nothing has been written down"
is  "and a transcript that never held that id does not claim it" "$(_ur_stop_tp ur-after2 "$TMP/ur-other.jsonl")" ""
_ur_row claude/peer lint 30 ur-nested > "$MEM/unrechook/mistakes.log"
is  "nor does an id nested later in a record than the record's own" "$(_ur_stop_tp ur-after3 "$TMP/ur-restored.jsonl")" ""
# End to end: the lesson written through the CLI, from the checkout, under a
# session, and the Stop hook asked by the session whose catch it is. A
# peer's lesson is the case this exists for, so it goes first.
_ur_row claude/this-checkout lint 30 ur-own > "$MEM/unrechook/mistakes.log"
( cd "$UHR" && CLAUDE_CODE_SESSION_ID=ur-peer "$FROOT/harness/felix" lesson "a peer learned something" ) >/dev/null 2>&1
out="$(_ur_stop ur-own)"
has "through the Stop hook, a peer session's felix lesson does not settle this session's catch" "$out" "nothing has been written down"
has "and the prompt names felix log for a one-off" "$out" 'felix log \"...\"'
( cd "$UHR" && CLAUDE_CODE_SESSION_ID=ur-own "$FROOT/harness/felix" lesson "this session learned something" ) >/dev/null 2>&1
is  "while this session's own felix lesson does" "$(_ur_stop ur-own)" ""
rm -f "$MEM/unrechook/written.log"
( cd "$UHR" && CLAUDE_CODE_SESSION_ID=ur-own "$FROOT/harness/felix" log "a one-off, said so" ) >/dev/null 2>&1
is  "and so does its felix log" "$(_ur_stop ur-own)" ""
# A lesson whose writer cannot be recorded is still in lessons.md, and the
# Stop hook will still ask. The command says both, rather than printing success
# and inviting the same lesson a second time into a file every prompt reads.
_ur_row claude/this-checkout lint 30 ur-own > "$MEM/unrechook/mistakes.log"
rm -f "$MEM/unrechook/written.log"; mkdir -p "$MEM/unrechook/written.log"
_ulb="$(grep -c 'written once' "$MEM/unrechook/lessons.md" 2>/dev/null)"
out="$(cd "$UHR" && CLAUDE_CODE_SESSION_ID=ur-own "$FROOT/harness/felix" lesson "written once" 2>&1)"; _ulrc=$?
is  "a lesson whose writer cannot be recorded exits non-zero" "$_ulrc" "1"
has "and says the lesson is there and must not be written again" "$out" "Do not write it again"
is  "and the lesson is in the file once" "$(( $(grep -c 'written once' "$MEM/unrechook/lessons.md") - ${_ulb:-0} ))" "1"
rmdir "$MEM/unrechook/written.log"
# Both stops that ask go through one helper, so the arguments cannot drift
# apart at a call site no fixture reaches: the night's.
is "the Stop hook calls the guard in one place" "$(grep -c 'felix_guard_unrecorded' "$FROOT/harness/hooks/stop")" "1"
rm -rf "$UHP"

