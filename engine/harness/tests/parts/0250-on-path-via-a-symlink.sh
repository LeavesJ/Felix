_plain_build; _hook_payload_vars; _user_prompt_hook_vars
_widget_repo_build
_router_build routed
_says_mandates_build
out="$(cd "$PLAIN" && "$FELIX" route --for "build the results page" 2>&1)"; rc=$?
[ "$rc" -ne 0 ] && ok "route refuses outside a governed repo" \
                || bad "route refuses outside a governed repo" "$out"

# `felix install` tells you to put the CLI on PATH with a symlink. Following
# that instruction resolved SCRIPT_DIR to the directory the link sits in, so
# every library source missed and the command died on its first line. The
# documented way to make Felix convenient was the one way to break it.
printf '\non PATH via a symlink\n'
mkdir -p "$TMP/bin"
ln -sf "$FELIX" "$TMP/bin/felix"
out="$(cd "$REPO" && "$TMP/bin/felix" which 2>&1)"
has "resolves its libraries through a symlink" "$out" "project:      widget"
out="$(cd "$REPO" && "$TMP/bin/felix" gate 2>&1)"; rc=$?
is "and the gate still runs through it" "$rc" "0"

printf '\njust in time, not all at once\n'
# Naming a whole play at the first prompt tells an agent to critique and
# browser-test something that does not exist yet, and spends context saying so.
# A play is a sequence: only the step that is actually due gets named.
TR="$TMP/transcript.jsonl"
: > "$TR"
J1="{\"session_id\":\"jit-1\",\"transcript_path\":\"$TR\",\"prompt\":\"the results page layout needs work\"}"
rm -rf "$FROOT/state/route"
out="$(cd "$REPO" && printf '%s' "$J1" | "$RHK" 2>&1)"; ctx="$(_ctx "$out")"
has "names the first step"        "$ctx" "frontend-design"
case "$ctx" in
  *"Use this now: impeccable"*) bad "does not demand the later steps yet" "$ctx" ;;
  *) ok "does not demand the later steps yet" ;;
esac
has "but says what may come later" "$ctx" "Later, only if"

# The mandate speaks with the channel's measured accuracy, not past it. The
# old paragraph opened "This is a requirement, not a suggestion" — language
# for a channel that is nearly always right, on one measured at 2 of 11
# mandates followed and five recorded failure causes (#29). A maximal claim
# from a low-precision source teaches sessions to skim the channel.
case "$ctx" in
  *"requirement, not a suggestion"*) bad "the mandate does not claim more precision than measured" "$ctx" ;;
  *) ok "the mandate does not claim more precision than measured" ;;
esac
# And it carries its own answer channel, so a wrong route becomes a labeled
# example instead of a silent skip.
has "and names the decline channel" "$ctx" "felix route --ack"

# Once the transcript shows step one was used, step two becomes the due one.
printf '{"type":"assistant","attributionSkill":"frontend-design:frontend-design"}\n' >> "$TR"
J2="{\"session_id\":\"jit-1\",\"transcript_path\":\"$TR\",\"prompt\":\"the results page layout still needs work\"}"
out="$(cd "$REPO" && printf '%s' "$J2" | "$RHK" 2>&1)"; ctx="$(_ctx "$out")"
has "advances to the next step once the first is used" "$ctx" "Use this now: impeccable"

# A plugin that ships an MCP server is used by calling its tools, not a skill.
printf '{"type":"assistant","attributionSkill":"impeccable"}\n' >> "$TR"
printf '{"name":"mcp__plugin_playwright_playwright__browser_navigate"}\n' >> "$TR"
out="$(cd "$REPO" && printf '%s' "$J2" | "$RHK" 2>&1)"; ctx="$(_ctx "$out")"
case "$ctx" in
  *"Use this now:"*) bad "stops naming tools once the play is done" "$ctx" ;;
  *) ok "stops naming tools once the play is done" ;;
esac

# And at the finish line, a step the session never used is worth one sentence.
: > "$TR"
printf 'edit\n' >> "$REPO/WIDGET.txt"
( cd "$REPO" && "$FELIX" gate >/dev/null 2>&1 )
mkdir -p "$FROOT/state/route"; printf 'frontend:frontend-design' > "$FROOT/state/route/jit-2"
SJ="{\"hook_event_name\":\"Stop\",\"stop_hook_active\":false,\"session_id\":\"jit-2\",\"transcript_path\":\"$TR\"}"
out="$(cd "$REPO" && printf '%s' "$SJ" | "$STOP" 2>&1)"
has "says what was skipped at the finish"  "$out" "never used"
case "$out" in
  *'"decision"'*'"block"'*) bad "but does not hold the session for it" "$out" ;;
  *) ok "but does not hold the session for it" ;;
esac

printf '\nthe finish-line message, and its answer channel\n'
# #98. Both interpolations in the old sentence were ${skipped}, so a
# three-step play with two steps followed was reported as though the route had
# asked only for the one that was missed — a partly-followed play rendered
# indistinguishable from a one-step play ignored outright, in the message that
# asks the reader to judge whether the skip was right. And nothing could
# answer it, so it fired identically at every close and got read as furniture.
#
# A play two-thirds followed, so the two facts come apart: the play is three
# names, the skip is one.
TR3="$TMP/transcript3.jsonl"; : > "$TR3"
printf '{"type":"assistant","attributionSkill":"frontend-design:frontend-design"}\n' >> "$TR3"
printf '{"type":"assistant","attributionSkill":"impeccable"}\n' >> "$TR3"
mkdir -p "$FROOT/state/route"; printf 'frontend:playwright' > "$FROOT/state/route/jit-3"
SJ3="{\"hook_event_name\":\"Stop\",\"stop_hook_active\":false,\"session_id\":\"jit-3\",\"transcript_path\":\"$TR3\"}"
out="$(cd "$REPO" && printf '%s' "$SJ3" | "$STOP" 2>&1)"
# The first slot names the PLAY — including a step that was followed — so the
# reader judges the skip against the sequence it came from. Reverse-locked:
# the old sentence put the skipped step in both slots, and `impeccable` was
# followed, so it could not appear.
has "the message names the play, not only the miss" "$out" "impeccable"
has "and still says which step went unused"         "$out" "never used"
has "and carries the decline channel"               "$out" "felix route --ack"

# Once per session. The second telling of an unanswered question is pressure.
out="$(cd "$REPO" && printf '%s' "$SJ3" | "$STOP" 2>&1)"
case "$out" in
  *"never used"*) bad "and it does not repeat within a session" "$out" ;;
  *) ok "and it does not repeat within a session" ;;
esac

# The answer channel, end to end: a recorded decline quiets the complaint and
# lands the reason where the table's next revision can read it. Recording
# only — the deliberation layer's gate in HANDOFF 0z stays closed; this is the
# instrumentation floor it names.
printf 'frontend:playwright' > "$FROOT/state/route/jit-4"
SJ4="{\"hook_event_name\":\"Stop\",\"stop_hook_active\":false,\"session_id\":\"jit-4\",\"transcript_path\":\"$TR3\"}"
out="$(cd "$REPO" && "$FELIX" route --ack "no browser surface in this change" 2>&1)"; rc=$?
is  "felix route --ack records without error" "$rc" "0"
has "and says it did"                         "$out" "on the record"
has "the reason is durable in decisions.log" \
    "$(tail -1 "$MEM/widget/decisions.log" 2>/dev/null)" "no browser surface in this change"
has "as a declined verdict"                   "$(tail -1 "$MEM/widget/decisions.log" 2>/dev/null)" "declined"
out="$(cd "$REPO" && printf '%s' "$SJ4" | "$STOP" 2>&1)"
case "$out" in
  *"never used"*) bad "a declined play is not raised at the finish" "$out" ;;
  *) ok "a declined play is not raised at the finish" ;;
esac
# Consumed, not standing: one decline answers one complaint. A permanent ack
# would be a mute button on the only compliance signal there is.
[ -f "$FROOT/state/route/ack-$(printf '%s' "$(_fx_cd "$REPO" && pwd -P)" | git hash-object --stdin)" ] \
  && bad "and the ack is consumed by the answer" "ack file still present" \
  || ok  "and the ack is consumed by the answer"

# The tracker Decision B is judged from. Recording that cannot be read is
# recording that gets lost in a build week, and the 20-session review needs
# these numbers legible on demand, not reconstructed.
out="$(cd "$REPO" && "$FELIX" decisions 2>&1)"; rc=$?
is  "felix decisions reads the record"        "$rc" "0"
has "and counts the recorded decline"         "$out" "declined, on the record    1"
has "and shows the decline itself"            "$out" "no browser surface in this change"
has "and says it is recording only"           "$out" "Recording only"
# The answer-rate window opens when the channel shipped. Mandates rendered
# before felix route --ack existed could not have been answered, and a rate
# computed over them reports a failure nobody could avoid — the same shape as
# follow-through computed against suggestions nobody was shown.
out="$(cd "$REPO" && FELIX_DECISIONS_SINCE=9999-01-01 "$FELIX" decisions 2>&1)"
has "mandates are counted only inside the answerable window" \
    "$out" "mandates rendered          0"
# And the numerator is inside the same window as the denominator. It was not:
# felix_count read the whole of decisions.log while mandates were counted from
# FELIX_DECISIONS_SINCE, so a decline predating the channel counted against
# mandates that excluded the period it came from.
has "and so are the declines, from the same date" \
    "$out" "declined, on the record    0"

# What the command may not claim.
#
# decisions.log has one appender and one verdict, the literal `declined`.
# Nothing writes a row when a mandate is FOLLOWED — the Stop hook offers both
# responses, "Decline it on the record ... or use it", and only the first
# leaves a trace. So declines over mandates is not an answer rate: the gap
# collapses compliance and disregard into one number. The word is gone, and
# the disregard half is recovered from the `skipped` row the Stop hook has
# been writing all along and this command ignored.
# Counted as a delta, because earlier sections of this file drive the Stop hook
# and leave skipped rows of their own in this project's says.log. An absolute
# number here would be an assertion about how many tests ran above it.
_dskip() { ( cd "$REPO" && "$FELIX" decisions 2>&1 ) \
             | awk '/rendered and not used/ { print $NF }'; }
_sk0="$(_dskip)"
printf '2026-09-01T00:00:00Z\tskipped\tsess-dec\t\tshown and never reached for\n' \
  >> "$MEM/widget/says.log"
is "the skipped row the Stop hook writes is counted" "$(_dskip)" "$(( _sk0 + 1 ))"
out="$(cd "$REPO" && "$FELIX" decisions 2>&1)"
case "$out" in
  *"answered "*) bad "and no rate is claimed over a numerator that cannot hold compliance" "$out" ;;
  *)             ok  "and no rate is claimed over a numerator that cannot hold compliance" ;;
esac
has "and the unwritten remainder is named as unwritten" \
    "$out" "nothing was written either way"
# The two counts come from different populations, so their sum can exceed the
# mandates rendered. Subtracting then would print a negative count of things
# nobody wrote about, which is not a number anyone can act on.
# Enough rows to exceed the mandates rendered whatever the sections above left
# behind, so the branch is reached rather than reached on this machine.
for _i in 1 2 3 4 5 6 7 8 9 10 11 12; do
  printf '2026-09-01T00:00:00Z\tskipped\tsess-dec%s\t\tshown and never reached for\n' "$_i" \
    >> "$MEM/widget/says.log"
done
out="$(cd "$REPO" && "$FELIX" decisions 2>&1)"
has "an overlap is said as an overlap, not as a negative remainder" \
    "$out" "counted in both"
case "$out" in
  *-[0-9]*"about which nothing"*) bad "and never renders a negative count" "$out" ;;
  *)                              ok  "and never renders a negative count" ;;
esac

( _fx_cd "$REPO" && git checkout -q -- WIDGET.txt 2>/dev/null || printf 'contents\n' > "$REPO/WIDGET.txt" )

printf '\nvisible at all\n'
# Felix ships no skills and no commands and costs a session nothing, which is
# the point and also why somebody looked for it, found nothing anywhere, and
# reasonably concluded it was not installed. additionalContext reaches the
# model; systemMessage reaches the person.
out="$(cd "$REPO" && CLAUDE_PLUGIN_ROOT="$FROOT" "$FROOT/harness/hooks/session-start" 2>&1)"
case "$out" in
  *'"systemMessage"'*) ok "says something to the founder, not only the model" ;;
  *) bad "says something to the founder, not only the model" "$out" ;;
esac
line="$(printf '%s' "$out" | python3 -c 'import json,sys
try: print(json.load(sys.stdin).get("systemMessage",""))
except Exception: print("")' 2>/dev/null)"
has "and names the project"  "$line" "widget"
# One line. A briefing repeated every session is one people stop reading.
n="$(printf '%s' "$line" | wc -l | tr -d ' ')"
[ "${n:-0}" -le 1 ] && ok "and stays to one line" || bad "and stays to one line" "$line"
# The model still gets the full briefing.
case "$out" in *'"additionalContext"'*) ok "the model still gets the whole thing" ;;
  *) bad "the model still gets the whole thing" "$out" ;; esac

# The one entry point, for somebody who has never seen Felix.
[ -f "$FROOT/../engine/commands/felix.md" ] || [ -f "$REAL_HARNESS/../commands/felix.md" ] \
  && ok "ships a slash command to be found by" \
  || bad "ships a slash command to be found by" "no commands/felix.md"

