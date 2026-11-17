# Settled by the writer, asserted blind. Written from a statement of what
# felix_guard_unrecorded, felix_mem_lesson and felix_mem_log must do once an
# entry settles only its writer's catches, by an author who never saw the
# implementation or the assertions above. Run against the engine before it
# existed, 60 of these 110 failed, each for a reason the statement names; 50
# held already, as positive controls and silences must. Mutating the new
# engine (any owner settles, the same second settles, a sessionless entry
# settles a session's catch, an unknown owner is settled, no later-day rule,
# a loose epoch, no settling at all, the file's time read as zero, no log row,
# the old devlog stamp, an unsanitised session id) failed both blocks on
# every mutation but the last, which only this one caught.
#
# Two rules came after it, from the adversarial review, and the statement
# these were written from never had them: each kind of owner is weighed on its
# own, so a catch naming no session cannot let a peer's lesson silence this
# session's, and an entry dated after now settles nothing. The author's cases
# above assert both; nothing here does.
printf '\nunrecorded catches, settled by their writer (blind)\n'
# Written from the contract alone: a lesson or devlog entry settles only its
# writer's catches, and only through the row it leaves in written.log. Every
# time relation below is built from explicit epochs minutes apart, never from
# the order of writes, and every silent case sits beside a case that differs in
# the one property under test and still prompts.

_memory_guarded_build
_bw_build
_BWFIRST='The gate caught something here and nothing has been written down since.'

_BWTODAY="$(_bwday "$_BWN")"
_BWDAY2="$(_bwday "$(( _BWN - 2 * 86400 ))")"

# a timed catch row, as the gate files it: branch checks epoch session
_bwcatch() {
  printf '%s\t%s\t0123abc\t%s\t%s\t%s\n' "$(_bwday "$3")" "$1" "$2" "$3" "$4" >> "$_BWK"
  _bwmt "$3" "$_BWK"
}
# a written.log row: branch kind epoch session [day]
_bwwrote() {
  printf '%s\t%s\t0123abc\t%s\t%s\t%s\n' "${5:-$(_bwday "$3")}" "$1" "$2" "$3" "$4" >> "$_BWW"
}
# lessons.md and DEVLOG.md written by hand at an epoch second
_bwprose() {
  printf '\n- **%s** a lesson written by hand\n' "$_BWTODAY" >> "$_BWL"
  printf '\n## %s hand entry\n\nwritten by hand\n' "$_BWTODAY" >> "$_BWV"
  _bwmt "$1" "$_BWL"; _bwmt "$1" "$_BWV"
}
# the guard's verdict: silent, or prompts:<what the last-caught line names>
_bwverdict() {
  if [ -z "$1" ]; then printf 'silent'
  else printf 'prompts:%s' "$(printf '%s\n' "$1" | sed -n 's/^  last caught   //p' | head -1 | sed 's/[[:space:]]*$//')"; fi
}
_bwsays()  { _bwverdict "$( ( . "$FROOT/harness/lib/guard.sh"; felix_guard_unrecorded "$GP" "$1" "${2:-}" ) 2>/dev/null )"; }
_bwsays0() { _bwverdict "$( ( . "$FROOT/harness/lib/guard.sh"; felix_guard_unrecorded "$GP" ) 2>/dev/null )"; }

# throwaway checkouts
_bwhead() { git -C "$1" symbolic-ref --short -q HEAD 2>/dev/null \
              || { git -C "$1" rev-parse --git-dir >/dev/null 2>&1 && echo HEAD || echo '?'; }; }
_BWR_THIS="$TMP/bw-this";   _bwrepo "$_BWR_THIS" bw/this
_BWR_V="$TMP/bw-v";         _bwrepo "$_BWR_V" bw/v1.2
_BWR_W="$TMP/bw-writer";    _bwrepo "$_BWR_W" bw/writer
_BWR_DET="$TMP/bw-det";     _bwrepo "$_BWR_DET" bw/det
_bwg -C "$_BWR_DET" checkout -q --detach >/dev/null 2>&1
_BWR_UB="$TMP/bw-unborn";   mkdir -p "$_BWR_UB" && ( _fx_cd "$_BWR_UB" && git init -q -b bw/unborn ) >/dev/null 2>&1
_BWR_NG="$TMP/bw-nongit";   mkdir -p "$_BWR_NG"

is "fixture: every throwaway checkout stands where its case assumes" \
   "$(_bwhead "$_BWR_THIS") $(_bwhead "$_BWR_V") $(_bwhead "$_BWR_W") $(_bwhead "$_BWR_DET") $(_bwhead "$_BWR_UB") $(_bwhead "$_BWR_NG")" \
   "bw/this bw/v1.2 bw/writer HEAD bw/unborn ?"
git -C "$_BWR_UB" rev-parse -q --verify HEAD >/dev/null 2>&1 \
  && bad "fixture: the unborn checkout has no commit yet" "HEAD resolves" \
  || ok  "fixture: the unborn checkout has no commit yet"

# ================================================================ (a) writer
# row helpers: rows in written.log; a row's day and epoch against the window
_bwrows() { if [ -f "$_BWW" ]; then wc -l < "$_BWW" | tr -d ' '; else printf 0; fi; }
_bwlast() { tail -1 "$_BWW" 2>/dev/null | cut -f"$1" | tr '\t' '|'; }
_bwnf()   { tail -1 "$1" 2>/dev/null | awk -F'\t' '{print NF}'; }
_bwwhen() {  # row t0 t1 d0 d1 -> "day ok|bad, epoch ok|bad"
  local d e dv=bad ev=bad
  d="$(printf '%s' "$1" | cut -f1)"; e="$(printf '%s' "$1" | cut -f5)"
  { [ "$d" = "$4" ] || [ "$d" = "$5" ]; } && dv=ok
  case "$e" in [1-9]*) case "$e" in *[!0-9]*) ;; *)
    [ "${#e}" -le 12 ] && [ "$e" -ge "$2" ] && [ "$e" -le "$3" ] && ev=ok ;; esac ;; esac
  printf 'day %s, epoch %s' "$dv" "$ev"
}
# a file's exact bytes, trailing newlines kept
_bwbytes() { cat "$1" 2>/dev/null; printf '|'; }
# midnight: the expectation built from the later day when that is what was written
_bwpick() { if [ "$1" = "$3" ]; then printf '%s' "$3"; else printf '%s' "$2"; fi; }
_bwlesson() { ( . "$FROOT/harness/lib/memory.sh"; felix_mem_lesson "$GP" "$1" "$2" ) >/dev/null 2>&1; }
_bwlog()    { ( . "$FROOT/harness/lib/memory.sh"; felix_mem_log "$GP" "$1" "$2" ) >/dev/null 2>&1; }

_bwreset
_BWSHA="$(git -C "$_BWR_W" rev-parse --short HEAD)"
_bwt0="$(date +%s)"; _bwd0="$(date +%Y-%m-%d)"
CLAUDE_CODE_SESSION_ID=bw-w1 _bwlesson "$_BWR_W" "bw lesson one"
_bwt1="$(date +%s)"; _bwd1="$(date +%Y-%m-%d)"
is "felix_mem_lesson appends exactly one row to written.log, with six columns" \
   "$(_bwrows)|$(_bwnf "$_BWW")" "1|6"
is "that row reads lesson, on the checkout's branch, at its short HEAD, under the session" \
   "$(_bwlast 2,3,4,6)" "bw/writer|$_BWSHA|lesson|bw-w1"
is "that row carries today's date and the epoch second of the call" \
   "$(_bwwhen "$(tail -1 "$_BWW" 2>/dev/null)" "$_bwt0" "$_bwt1" "$_bwd0" "$_bwd1")" "day ok, epoch ok"
_bwgot="$(_bwbytes "$_BWL")"
is "lessons.md gets exactly the old entry and nothing else: blank line, dated bullet, text" "$_bwgot" \
   "$(_bwpick "$_bwgot" "$(printf '\n- **%s** bw lesson one\n|' "$_bwd0")" "$(printf '\n- **%s** bw lesson one\n|' "$_bwd1")")"

_bwt0="$(date +%s)"; _bwd0="$(date +%Y-%m-%d)"
CLAUDE_CODE_SESSION_ID=bw-w1 _bwlog "$_BWR_W" "bw log one"
_bwt1="$(date +%s)"; _bwd1="$(date +%Y-%m-%d)"
is "felix_mem_log appends a second six-column row and keeps the lesson row ahead of it" \
   "$(_bwrows)|$(_bwnf "$_BWW")|$(head -1 "$_BWW" 2>/dev/null | cut -f4)" "2|6|lesson"
is "the devlog row reads log, on the checkout's branch, at its short HEAD, under the session" \
   "$(_bwlast 2,3,4,6)" "bw/writer|$_BWSHA|log|bw-w1"
is "the devlog row carries today's date and the epoch second of the call" \
   "$(_bwwhen "$(tail -1 "$_BWW" 2>/dev/null)" "$_bwt0" "$_bwt1" "$_bwd0" "$_bwd1")" "day ok, epoch ok"
_bwgot="$(_bwbytes "$_BWV")"
is "DEVLOG.md gets exactly the old entry: blank line, header with day branch sha, blank line, text" "$_bwgot" \
   "$(_bwpick "$_bwgot" "$(printf '\n## %s bw/writer %s\n\nbw log one\n|' "$_bwd0" "$_BWSHA")" \
                        "$(printf '\n## %s bw/writer %s\n\nbw log one\n|' "$_bwd1" "$_BWSHA")")"
_bwgot="$(_bwbytes "$_BWL")"
is "and felix_mem_log adds nothing to lessons.md" "$_bwgot" \
   "$(_bwpick "$_bwgot" "$(printf '\n- **%s** bw lesson one\n|' "$_bwd0")" "$(printf '\n- **%s** bw lesson one\n|' "$_bwd1")")"

# appended, never rewritten
_bwreset
printf '2020-01-01\tbw/old\t0000000\tlesson\t1577880000\tbw-old\n' > "$_BWW"
CLAUDE_CODE_SESSION_ID=bw-w2 _bwlesson "$_BWR_W" "bw lesson two"
CLAUDE_CODE_SESSION_ID=bw-w2 _bwlog "$_BWR_W" "bw log two"
is "rows already in written.log are kept unchanged ahead of the new ones" \
   "$(_bwrows)|$(head -1 "$_BWW" | tr '\t' '|')|$(sed -n 2p "$_BWW" | cut -f4)|$(sed -n 3p "$_BWW" | cut -f4)" \
   "3|2020-01-01|bw/old|0000000|lesson|1577880000|bw-old|lesson|log"

# the session column, sanitised as the gate's is
_bwsess() {  # how -> NF|session of the one row a lesson writes
  _bwreset
  case "$1" in
    unset) ( unset CLAUDE_CODE_SESSION_ID; _bwlesson "$_BWR_W" "bw s" ) ;;
    log)   CLAUDE_CODE_SESSION_ID="$2" _bwlog "$_BWR_W" "bw s" ;;
    *)     CLAUDE_CODE_SESSION_ID="$2" _bwlesson "$_BWR_W" "bw s" ;;
  esac
  printf '%s|%s' "$(_bwnf "$_BWW")" "$(_bwlast 6)"
}
is "a lesson written with no session id set is filed under a dash"          "$(_bwsess unset)" "6|-"
is "a lesson written with an empty session id is filed under a dash"        "$(_bwsess set '')" "6|-"
is "a session id holding a tab is filed as a dash, and the row stays six columns"   "$(_bwsess set "$(printf 'bw\tx')")" "6|-"
is "a session id holding a space is filed as a dash, and the row stays six columns" "$(_bwsess set 'bw x')" "6|-"
is "a session id holding a slash is filed as a dash"                        "$(_bwsess set 'bw/x')" "6|-"
is "a session id of letters, digits, dot, underscore and dash is kept as it is" "$(_bwsess set 'Bw.9_z-1')" "6|Bw.9_z-1"
is "felix_mem_log files a session id holding a tab as a dash too"           "$(_bwsess log "$(printf 'bw\tx')")" "6|-"

# the branch column where git has less to say
_bwreset
_bwd0="$(date +%Y-%m-%d)"
_bwlog "$_BWR_DET" "bw detached entry"
_bwd1="$(date +%Y-%m-%d)"
_BWDSHA="$(git -C "$_BWR_DET" rev-parse --short HEAD)"
is "felix_mem_log in a detached checkout files its row under HEAD at the short sha" \
   "$(_bwlast 2,3)" "HEAD|$_BWDSHA"
_bwgot="$(sed -n 2p "$_BWV" 2>/dev/null)"
is "and the devlog header there names HEAD the same way" "$_bwgot" \
   "$(_bwpick "$_bwgot" "## $_bwd0 HEAD $_BWDSHA" "## $_bwd1 HEAD $_BWDSHA")"

_bwreset
_bwlesson "$_BWR_NG" "bw outside git"
( . "$FROOT/harness/lib/memory.sh"; felix_mem_mistake "$GP" "$_BWR_NG" lint ) >/dev/null 2>&1
is "felix_mem_lesson outside git files its row under a question mark" "$(_bwlast 2)" "?"
is "outside git the written row spells branch and sha exactly as the gate's own row does" \
   "$(_bwlast 2,3)" "$(tail -1 "$_BWK" 2>/dev/null | cut -f2,3 | tr '\t' '|')"

_bwreset
_bwlesson "$_BWR_UB" "bw unborn lesson"
( . "$FROOT/harness/lib/memory.sh"; felix_mem_mistake "$GP" "$_BWR_UB" lint ) >/dev/null 2>&1
is "in a checkout with no commit felix_mem_lesson writes one six-column row under the branch name" \
   "$(_bwrows)|$(_bwnf "$_BWW")|$(_bwlast 2)" "1|6|bw/unborn"
is "with no commit yet the written row spells branch and sha exactly as the gate's own row does" \
   "$(_bwlast 2,3)" "$(tail -1 "$_BWK" 2>/dev/null | cut -f2,3 | tr '\t' '|')"
_bwreset
_bwd0="$(date +%Y-%m-%d)"
_bwlog "$_BWR_UB" "bw unborn entry"
_bwd1="$(date +%Y-%m-%d)"
_bwhdr="$(sed -n 2p "$_BWV" 2>/dev/null)"
case "$_bwhdr" in "## $_bwd0 bw/unborn "*|"## $_bwd1 bw/unborn "*) _bwhv=begins ;; *) _bwhv="[$_bwhdr]" ;; esac
is "a devlog entry in a checkout with no commit has a one-line header beginning with day and branch" \
   "$(awk 'END{print NR}' "$_BWV" 2>/dev/null)|$_bwhv|$(sed -n 3p "$_BWV" 2>/dev/null)|$(sed -n 4p "$_BWV" 2>/dev/null)" \
   "4|begins||bw unborn entry"
is "and felix_mem_log there writes one six-column row under the branch name" \
   "$(_bwrows)|$(_bwnf "$_BWW")|$(_bwlast 2,4)" "1|6|bw/unborn|log"

# the row the writer leaves is the one the guard reads
_bwreset
_bwcatch bw/writer lint "$(_bwago 30)" bw-lib
CLAUDE_CODE_SESSION_ID=bw-lib _bwlesson "$_BWR_W" "bw lib lesson"
is "the row felix_mem_lesson writes settles the catch of the session that wrote it" \
   "$(_bwsays "$_BWR_W" bw-lib)" "silent"
_bwreset
_bwcatch bw/writer lint "$(_bwago 30)" bw-lib
CLAUDE_CODE_SESSION_ID=bw-lib-peer _bwlesson "$_BWR_W" "bw lib lesson"
is "and the row a peer session's felix_mem_lesson writes on the same branch does not" \
   "$(_bwsays "$_BWR_W" bw-lib)" "prompts:lint"

# ========================================================= (b) session-owned
_BWT="$(_bwago 30)"   # the catch
_bwreset
_bwcatch bw/this lint "$_BWT" bw-s1
_bwout="$( ( . "$FROOT/harness/lib/guard.sh"; felix_guard_unrecorded "$GP" "$_BWR_THIS" bw-s1 ) 2>/dev/null )"
is "with no written.log this session's catch prompts, first line exact" \
   "$(printf '%s\n' "$_bwout" | head -1)" "$_BWFIRST"
is "and its last-caught line names the catch" "$(_bwverdict "$_bwout")" "prompts:lint"
has "the prompt names felix lesson as a way to settle it" "$_bwout" "felix lesson"
has "the prompt names felix log as a way to settle it too" "$_bwout" "felix log"

_bwreset; _bwcatch bw/this lint "$_BWT" bw-s1
_bwwrote bw/this lesson "$(( _BWT + 600 ))" bw-s1
is "this session's written row ten minutes after its catch settles it" "$(_bwsays "$_BWR_THIS" bw-s1)" "silent"
_bwreset; _bwcatch bw/this lint "$_BWT" bw-s1
_bwwrote bw/this lesson "$(( _BWT - 600 ))" bw-s1
is "this session's written row ten minutes before its catch does not" "$(_bwsays "$_BWR_THIS" bw-s1)" "prompts:lint"
_bwreset; _bwcatch bw/this lint "$_BWT" bw-s1
_bwwrote bw/this lesson "$(( _BWT + 600 ))" bw-peer
is "a peer session's row on the same branch after the catch does not settle it" "$(_bwsays "$_BWR_THIS" bw-s1)" "prompts:lint"
_bwreset; _bwcatch bw/this lint "$_BWT" bw-s1
_bwwrote bw/this lesson "$(( _BWT + 600 ))" bw-peer; _bwprose "$(( _BWT + 600 ))"
is "nor does it with the lessons.md and DEVLOG.md a peer's writing leaves newer than the catch" \
   "$(_bwsays "$_BWR_THIS" bw-s1)" "prompts:lint"
_bwreset; _bwcatch bw/this lint "$_BWT" bw-s1
_bwwrote bw/this lesson "$(( _BWT - 600 ))" bw-s1
_bwwrote bw/this lesson "$(( _BWT + 1200 ))" bw-peer
is "this session's row from before the catch and a newer peer row after it still prompt" \
   "$(_bwsays "$_BWR_THIS" bw-s1)" "prompts:lint"
_bwreset; _bwcatch bw/this lint "$_BWT" bw-s1
_bwwrote bw/this lesson "$(( _BWT + 600 ))" -
is "a row naming no session does not settle a session-owned catch, even on its branch" \
   "$(_bwsays "$_BWR_THIS" bw-s1)" "prompts:lint"

# several ids in one conversation
_bwreset; _bwcatch bw/this lint "$_BWT" bw-s1
_bwwrote bw/this lesson "$(( _BWT + 600 ))" bw-s0
is "a row under the first of several ids in SIDS settles a catch filed under another of them" \
   "$(_bwsays "$_BWR_THIS" "bw-s0 bw-s1 bw-s2")" "silent"
_bwreset; _bwcatch bw/this lint "$_BWT" bw-s1
_bwwrote bw/this lesson "$(( _BWT + 600 ))" bw-s2
is "and so does a row under the last of them" "$(_bwsays "$_BWR_THIS" "bw-s0 bw-s1 bw-s2")" "silent"
_bwreset; _bwcatch bw/this lint "$_BWT" bw-s1
_bwwrote bw/this lesson "$(( _BWT + 600 ))" bw-s9
is "a row under an id missing from a multi-id SIDS does not" "$(_bwsays "$_BWR_THIS" "bw-s0 bw-s1 bw-s2")" "prompts:lint"
_bwreset; _bwcatch bw/this lint "$_BWT" bw-s1
_bwwrote bw/this lesson "$(( _BWT + 600 ))" bw-s
is "a row under an id that is only part of an id in SIDS does not" "$(_bwsays "$_BWR_THIS" "bw-s0 bw-s1 bw-s2")" "prompts:lint"

# to the second
_bwreset; _bwcatch bw/this lint "$_BWT" bw-s1
_bwwrote bw/this lesson "$_BWT" bw-s1
is "a row stamped the very second of the catch does not settle it" "$(_bwsays "$_BWR_THIS" bw-s1)" "prompts:lint"
_bwreset; _bwcatch bw/this lint "$_BWT" bw-s1
_bwwrote bw/this lesson "$(( _BWT + 1 ))" bw-s1
is "a row one second after the catch does" "$(_bwsays "$_BWR_THIS" bw-s1)" "silent"

# wherever this session wrote it
_bwreset; _bwcatch bw/handed lint "$_BWT" bw-s1
_bwwrote bw/this lesson "$(( _BWT + 600 ))" bw-s1
is "this session's row on another branch settles its catch" "$(_bwsays "$_BWR_THIS" bw-s1)" "silent"
_bwreset; _bwcatch bw/handed lint "$_BWT" bw-s1
_bwwrote bw/this lesson "$(( _BWT + 600 ))" bw-peer
is "and a peer's row on that same other branch does not" "$(_bwsays "$_BWR_THIS" bw-s1)" "prompts:lint"
_bwreset; _bwcatch bw/this lint "$_BWT" bw-s1
_bwwrote '?' lesson "$(( _BWT + 600 ))" bw-s1
is "this session's catch seen from outside git is settled by its own row" "$(_bwsays "$_BWR_NG" bw-s1)" "silent"
_bwreset; _bwcatch bw/this lint "$_BWT" bw-s1
_bwwrote '?' lesson "$(( _BWT + 600 ))" bw-peer
is "and not by a peer's row there" "$(_bwsays "$_BWR_NG" bw-s1)" "prompts:lint"
_bwreset; _bwcatch bw/this lint "$_BWT" bw-s1
_bwwrote bw/this lesson "$(( _BWT + 600 ))" bw-s1
is "this session's catch with no checkout given is settled by its own row" "$(_bwsays '' bw-s1)" "silent"
_bwreset; _bwcatch bw/this lint "$_BWT" bw-s1
_bwwrote bw/this lesson "$(( _BWT + 600 ))" bw-peer
is "and not by a peer's row with no checkout given" "$(_bwsays '' bw-s1)" "prompts:lint"

# which catch: the last owned row in the file, against its own time
_bwreset
_bwcatch bw/this first "$(( _BWT - 3600 ))" bw-s1
_bwcatch bw/this second "$_BWT" bw-s1
_bwwrote bw/this lesson "$(( _BWT - 1800 ))" bw-s1
is "a row between two of this session's catches leaves the later one owed" "$(_bwsays "$_BWR_THIS" bw-s1)" "prompts:second"
_bwwrote bw/this lesson "$(( _BWT + 600 ))" bw-s1
is "and a row after both settles it" "$(_bwsays "$_BWR_THIS" bw-s1)" "silent"
_bwreset
_bwcatch bw/this newer "$_BWT" bw-s1
_bwcatch bw/this older "$(( _BWT - 3600 ))" bw-s1
_bwwrote bw/this lesson "$(( _BWT - 1800 ))" bw-s1
is "a row after the file's last owned catch settles it though an earlier line holds a newer time" \
   "$(_bwsays "$_BWR_THIS" bw-s1)" "silent"
_bwreset
_bwcatch bw/this newer "$_BWT" bw-s1
_bwcatch bw/this older "$(( _BWT - 3600 ))" bw-s1
_bwwrote bw/this lesson "$(( _BWT - 5400 ))" bw-s1
is "and a row before that last owned catch does not" "$(_bwsays "$_BWR_THIS" bw-s1)" "prompts:older"
_bwreset
_bwcatch bw/this lint "$_BWT" bw-s1
_bwcatch bw/this tests "$(( _BWT + 900 ))" bw-peer
_bwwrote bw/this lesson "$(( _BWT + 600 ))" bw-s1
is "this session's row settles its catch whatever a peer caught later on the same branch" \
   "$(_bwsays "$_BWR_THIS" bw-s1)" "silent"
_bwreset
_bwcatch bw/this lint "$_BWT" bw-s1
_bwcatch bw/this tests "$(( _BWT + 900 ))" bw-peer
_bwwrote bw/this lesson "$(( _BWT + 1200 ))" bw-peer
is "and the peer who caught later writing its own row settles only its own" \
   "$(_bwsays "$_BWR_THIS" bw-s1)" "prompts:lint"

# ========================================================== (c) branch-owned
_bwreset; _bwcatch bw/this lint "$_BWT" -
_bwwrote bw/this lesson "$(( _BWT + 600 ))" -
is "a catch naming no session is settled by a sessionless row on its branch" "$(_bwsays "$_BWR_THIS" bw-s1)" "silent"
_bwreset; _bwcatch bw/this lint "$_BWT" -
_bwwrote bw/other lesson "$(( _BWT + 600 ))" -
is "and not by a sessionless row on another branch" "$(_bwsays "$_BWR_THIS" bw-s1)" "prompts:lint"
_bwreset; _bwcatch bw/this lint "$_BWT" -
_bwwrote bw/this lesson "$(( _BWT + 600 ))" bw-peer
is "a catch naming no session is settled by a peer's row on its branch" "$(_bwsays "$_BWR_THIS" bw-s1)" "silent"
_bwreset; _bwcatch bw/this lint "$_BWT" -
_bwwrote bw/other lesson "$(( _BWT + 600 ))" bw-peer
is "and not by a peer's row on another branch" "$(_bwsays "$_BWR_THIS" bw-s1)" "prompts:lint"
_bwreset; _bwcatch bw/this lint "$_BWT" -
_bwwrote bw/this lesson "$(( _BWT + 600 ))" bw-s1
is "a catch naming no session is settled by this session's row on its branch" "$(_bwsays "$_BWR_THIS" bw-s1)" "silent"
_bwreset; _bwcatch bw/this lint "$_BWT" -
_bwwrote bw/other lesson "$(( _BWT + 600 ))" bw-s1
is "and not by this session's row on another branch" "$(_bwsays "$_BWR_THIS" bw-s1)" "prompts:lint"
_bwreset; _bwcatch bw/this lint "$_BWT" -
_bwwrote bw/this lesson "$(( _BWT - 600 ))" -
is "a branch-owned catch is not settled by a row on its branch from before it" "$(_bwsays "$_BWR_THIS" bw-s1)" "prompts:lint"
_bwreset; _bwcatch bw/this lint "$_BWT" -
_bwwrote bw/other lesson "$(( _BWT + 600 ))" -; _bwprose "$(( _BWT + 600 ))"
is "nor by another branch's row with lessons.md and DEVLOG.md newer than the catch" \
   "$(_bwsays "$_BWR_THIS" bw-s1)" "prompts:lint"

# with SIDS empty, a catch that names a session is weighed by branch
_bwreset; _bwcatch bw/this lint "$_BWT" bw-s1
_bwwrote bw/this lesson "$(( _BWT + 600 ))" bw-peer
is "with no session asking, a named catch is settled by any row on its branch" "$(_bwsays "$_BWR_THIS" '')" "silent"
_bwreset; _bwcatch bw/this lint "$_BWT" bw-s1
_bwwrote bw/other lesson "$(( _BWT + 600 ))" bw-peer
is "and not by that row on another branch" "$(_bwsays "$_BWR_THIS" '')" "prompts:lint"
_bwreset; _bwcatch bw/this lint "$_BWT" bw-s1
_bwwrote bw/other lesson "$(( _BWT + 600 ))" bw-s1
is "nor by its own session's row on another branch" "$(_bwsays "$_BWR_THIS" '')" "prompts:lint"

# look-alike branch names
_bwreset; _bwcatch bw/v1.2 lint "$_BWT" -
for _bwb in bw/v1x2 bw/v1.2-rc xbw/v1.2 bw/v1 bw/V1.2; do _bwwrote "$_bwb" lesson "$(( _BWT + 600 ))" -; done
is "rows on look-alike branches do not settle a branch-owned catch" "$(_bwsays "$_BWR_V" bw-s1)" "prompts:lint"
_bwwrote bw/v1.2 lesson "$(( _BWT + 600 ))" -
is "while the same rows plus one on the exact branch do" "$(_bwsays "$_BWR_V" bw-s1)" "silent"

# detached
_bwreset; _bwcatch HEAD lint "$_BWT" -
_bwwrote HEAD lesson "$(( _BWT + 600 ))" -
is "a detached checkout's catch is settled by a row filed under HEAD" "$(_bwsays "$_BWR_DET" bw-s1)" "silent"
_bwreset; _bwcatch HEAD lint "$_BWT" -
_bwwrote bw/det lesson "$(( _BWT + 600 ))" -
is "and not by a row on the branch it was detached from" "$(_bwsays "$_BWR_DET" bw-s1)" "prompts:lint"

# ========================================================= (d) unknown owner
# every case here would settle a catch whose owner is known, and each also
# leaves lessons.md and DEVLOG.md newer than the catch, as a writer does
_bwreset; _bwcatch '?' lint "$_BWT" -
_bwwrote '?' lesson "$(( _BWT + 600 ))" -; _bwprose "$(( _BWT + 600 ))"
is "from a root outside git with no session, no row settles a catch" "$(_bwsays "$_BWR_NG" '')" "prompts:lint"
_bwreset; _bwcatch bw/this lint "$_BWT" -
_bwwrote bw/this lesson "$(( _BWT + 600 ))" -; _bwprose "$(( _BWT + 600 ))"
is "with no root and no session, not even a row on the catch's own branch settles it" "$(_bwsays0)" "prompts:lint"
_bwreset; _bwcatch '?' lint "$_BWT" -
_bwwrote '?' lesson "$(( _BWT + 600 ))" bw-s1; _bwprose "$(( _BWT + 600 ))"
is "from outside git, a catch naming no session is not settled even by the asking session's row" \
   "$(_bwsays "$_BWR_NG" bw-s1)" "prompts:lint"
_bwreset; _bwcatch '?' lint "$_BWT" bw-s1
_bwwrote '?' lesson "$(( _BWT + 600 ))" bw-s1; _bwprose "$(( _BWT + 600 ))"
is "from outside git with SIDS empty, a named catch is not settled by its session's row" \
   "$(_bwsays "$_BWR_NG" '')" "prompts:lint"

# =========================================================== (e) untimed rows
# Four columns, no epoch. Taken at mistakes.log's time, or by the day it names.
_BWM="$(_bwago 30)"   # mistakes.log's mtime
_bwuntimed() { printf '%s\tbw/this\t0123abc\tlint\n' "$1" > "$_BWK"; _bwmt "$_BWM" "$_BWK"; }
_bwreset; _bwuntimed "$_BWTODAY"
_bwwrote bw/this lesson "$(( _BWM + 600 ))" - "$_BWTODAY"
is "an untimed catch is settled by a same-branch row whose epoch is after mistakes.log's time" \
   "$(_bwsays "$_BWR_THIS" bw-s1)" "silent"
_bwreset; _bwuntimed "$_BWTODAY"
_bwwrote bw/this lesson "$(( _BWM - 600 ))" - "$_BWTODAY"
is "and not by one before that time on the same day" "$(_bwsays "$_BWR_THIS" bw-s1)" "prompts:lint"
_bwreset; _bwuntimed "$_BWDAY2"
_bwwrote bw/this lesson "$(( _BWM - 600 ))" - "$_BWTODAY"
is "an untimed catch is settled by a same-branch row dated a later day, though its epoch is earlier" \
   "$(_bwsays "$_BWR_THIS" bw-s1)" "silent"
_bwreset; _bwuntimed "$_BWDAY2"
_bwwrote bw/this lesson "$(( _BWM - 600 ))" - "$_BWDAY2"
is "and not by that row dated the catch's own day" "$(_bwsays "$_BWR_THIS" bw-s1)" "prompts:lint"
_bwreset; _bwuntimed "$_BWDAY2"
_bwwrote bw/other lesson "$(( _BWM + 600 ))" - "$_BWTODAY"
is "an untimed catch is not settled by another branch's later row" "$(_bwsays "$_BWR_THIS" bw-s1)" "prompts:lint"

# ============================================ (f) prose mtimes settle nothing
_bwreset; _bwcatch bw/this lint "$_BWT" bw-s1
printf -- '- **%s** consolidated by hand\n' "$_BWTODAY" > "$_BWL"; _bwmt "$(( _BWT + 600 ))" "$_BWL"
is "a lessons.md written by hand after the catch, with no written row, does not settle it" \
   "$(_bwsays "$_BWR_THIS" bw-s1)" "prompts:lint"
_bwreset; _bwcatch bw/this lint "$_BWT" bw-s1
printf '\n## %s by hand\n\nan entry\n' "$_BWTODAY" > "$_BWV"; _bwmt "$(( _BWT + 600 ))" "$_BWV"
is "a DEVLOG.md entry written by hand after the catch does not settle it" "$(_bwsays "$_BWR_THIS" bw-s1)" "prompts:lint"
_bwreset; _bwcatch bw/this lint "$_BWT" -
_bwprose "$(( _BWT + 600 ))"
is "nor do hand-written lessons and devlog settle a branch-owned catch" "$(_bwsays "$_BWR_THIS" bw-s1)" "prompts:lint"
_bwreset; _bwuntimed "$_BWDAY2"
_bwprose "$(( _BWM + 600 ))"
is "nor an untimed catch, though both are newer than mistakes.log and a later day" \
   "$(_bwsays "$_BWR_THIS" bw-s1)" "prompts:lint"
_bwreset; _bwcatch bw/this lint "$_BWT" bw-s1
_bwprose "$(( _BWT + 600 ))"
is "both hand-written files newer than this session's catch, with no written row, do not settle it" \
   "$(_bwsays "$_BWR_THIS" bw-s1)" "prompts:lint"
_bwwrote bw/this lesson "$(( _BWT + 600 ))" bw-s1
is "the same hand-written files beside this session's written row are silent" "$(_bwsays "$_BWR_THIS" bw-s1)" "silent"

# =============================================================== (g) malformed
_bwbadrow() {  # epoch column as given, otherwise this session's row after the catch
  _bwreset; _bwcatch bw/this lint "$_BWT" bw-s1
  printf '%s\tbw/this\t0123abc\tlesson\t%s\tbw-s1\n' "$_BWTODAY" "$1" > "$_BWW"
  _bwsays "$_BWR_THIS" bw-s1
}
is "a written row whose epoch has a leading zero settles nothing" "$(_bwbadrow "0$(( _BWT + 600 ))")" "prompts:lint"
is "a written row whose epoch has thirteen digits settles nothing" "$(_bwbadrow 9999999999999)" "prompts:lint"
is "a written row whose epoch is not a number settles nothing" "$(_bwbadrow later)" "prompts:lint"
is "a written row whose epoch is empty settles nothing" "$(_bwbadrow '')" "prompts:lint"
is "a written row whose epoch is negative settles nothing" "$(_bwbadrow "-$(( _BWT + 600 ))")" "prompts:lint"
_bwreset; _bwcatch bw/this lint "$_BWT" -
printf '%s\tbw/this\t0123abc\tlesson\n' "$_BWTODAY" > "$_BWW"
is "a four-column written row on the catch's branch settles nothing" "$(_bwsays "$_BWR_THIS" bw-s1)" "prompts:lint"
_bwreset; _bwcatch bw/this lint "$_BWT" bw-s1
printf '%s\tbw/this\t0123abc\tlesson\t%s\n' "$_BWTODAY" "$(( _BWT + 600 ))" > "$_BWW"
is "a five-column written row, naming no session, does not settle a session-owned catch" \
   "$(_bwsays "$_BWR_THIS" bw-s1)" "prompts:lint"
_bwreset; _bwcatch bw/this lint "$_BWT" bw-s1
: > "$_BWW"
is "an empty written.log settles nothing" "$(_bwsays "$_BWR_THIS" bw-s1)" "prompts:lint"
_bwreset; _bwcatch bw/this lint "$_BWT" bw-s1
is "a missing written.log settles nothing" "$(_bwsays "$_BWR_THIS" bw-s1)" "prompts:lint"
_bwreset; _bwcatch bw/this lint "$_BWT" bw-s1
{ printf '%s\tbw/this\t0123abc\tlesson\t0%s\tbw-s1\n' "$_BWTODAY" "$(( _BWT + 600 ))"
  printf '%s\tbw/this\t0123abc\tlesson\n' "$_BWTODAY"
  printf 'garbage\n'; } > "$_BWW"
is "a written.log of malformed rows only settles nothing" "$(_bwsays "$_BWR_THIS" bw-s1)" "prompts:lint"
_bwwrote bw/this lesson "$(( _BWT + 600 ))" bw-s1
is "and one well-formed row of this session's after them does" "$(_bwsays "$_BWR_THIS" bw-s1)" "silent"

# ============================================================ (h) kind log
_bwreset; _bwcatch bw/this lint "$_BWT" bw-s1
_bwwrote bw/this log "$(( _BWT + 600 ))" bw-s1
is "this session's log row settles its catch as a lesson row does" "$(_bwsays "$_BWR_THIS" bw-s1)" "silent"
_bwreset; _bwcatch bw/this lint "$_BWT" bw-s1
_bwwrote bw/this log "$(( _BWT + 600 ))" bw-peer
is "a peer's log row does not" "$(_bwsays "$_BWR_THIS" bw-s1)" "prompts:lint"
_bwreset; _bwcatch bw/this lint "$_BWT" -
_bwwrote bw/this log "$(( _BWT + 600 ))" -
is "a log row on the branch settles a branch-owned catch" "$(_bwsays "$_BWR_THIS" bw-s1)" "silent"
_bwreset; _bwcatch bw/this lint "$_BWT" -
_bwwrote bw/other log "$(( _BWT + 600 ))" -
is "a log row on another branch does not" "$(_bwsays "$_BWR_THIS" bw-s1)" "prompts:lint"
_bwreset

