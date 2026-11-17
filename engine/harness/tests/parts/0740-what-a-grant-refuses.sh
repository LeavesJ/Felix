printf '\nwhat a grant refuses\n'
# A night is the one thing here nobody is awake to correct, so the refusals are
# the feature. `felix overnight --start 0.5` that rounds, or `--start 100` that
# is accepted, is a session running unattended for as long as it feels like.
_overnight_build
_ovreset "$NP"
_ov felix_overnight_start "$NP" 8.5 5 "$NS" "half" >/dev/null 2>&1 \
  && bad "half an hour is not a whole number of hours" "accepted" \
  || ok  "half an hour is not a whole number of hours"
_zero="$(_ov felix_overnight_start "$NP" 0 5 "$NS" "none")"; _zerorc=$?
[ "$_zerorc" -ne 0 ] && ok "a night of zero hours is not a night" \
                     || bad "a night of zero hours is not a night" "accepted"
# Refusing without saying why leaves a founder retyping the same command.
is "and a refused grant says why" "$([ -n "$_zero" ] && echo said || echo silent)" "said"
_ov felix_overnight_start "$NP" 17 5 "$NS" "too long" >/dev/null 2>&1 \
  && bad "seventeen hours is past the ceiling" "accepted" \
  || ok  "seventeen hours is past the ceiling"
_ov felix_overnight_start "$NP" 8 0 "$NS" "no turns" >/dev/null 2>&1 \
  && bad "a night with no continuations in it is refused" "accepted" \
  || ok  "a night with no continuations in it is refused"
# Continuations have had teeth since a night carries through the platform's
# chain, so their count has a ceiling as the hours do.
_ov felix_overnight_start "$NP" 8 201 "$NS" "too many" >/dev/null 2>&1 \
  && bad "two hundred and one continuations is past the ceiling" "accepted" \
  || ok  "two hundred and one continuations is past the ceiling"
# Nobody to hold is nobody to grant a night to.
_ov felix_overnight_start "$NP" 8 5 "" "whose?" >/dev/null 2>&1 \
  && bad "a night granted to no session is refused" "accepted" \
  || ok  "a night granted to no session is refused"
_ov felix_overnight_start "$NP" 8 5 "../../elsewhere" "a path" >/dev/null 2>&1; _rc=$?
is "and so is one whose session id would name a path, which is not written" \
   "$([ "$_rc" -ne 0 ] && echo refused || echo accepted):$([ -e "$(_ovdir "$NP")/elsewhere" ] && echo written || echo absent)" \
   "refused:absent"
# The control. Without it every assertion above is satisfied by a start that
# refuses everything, which is the shape a blanket guard clause takes.
is "and nothing was granted by any of them" \
   "$([ -f "$(_ovfile "$NP" "$NS")" ] && echo granted || echo none)" "none"
_ov felix_overnight_start "$NP" 16 5 "$NS" "the ceiling itself" >/dev/null 2>&1 \
  && ok  "the ceiling itself is still a night somebody can be granted" \
  || bad "the ceiling itself is still a night somebody can be granted" "16 refused"
_ovreset "$NP"
_ov felix_overnight_start "$NP" 8 200 "$NS" "the turn ceiling itself" >/dev/null 2>&1 \
  && ok  "and so is the continuation ceiling itself" \
  || bad "and so is the continuation ceiling itself" "200 refused"
# The ceilings bound a session, not a grant. A session can run the command from
# its own shell, and a night carries it through the platform's chain, so a
# second grant from inside the chain that reset the budget would be a loop with
# nothing to end it.
_ovreset "$NP"
_ov felix_overnight_start "$NP" 4 150 "$NS" "most of a day's budget" >/dev/null 2>&1
_ov felix_overnight_start "$NP" 4 60 "$NS" "and then some" >/dev/null 2>&1 \
  && bad "a second grant cannot take a session past the day's continuations" "accepted: $(_ovfield "$NP" 3 "$NS") left" \
  || ok  "a second grant cannot take a session past the day's continuations"
_ov felix_overnight_start "$NP" 4 50 "$NS" "exactly the rest" >/dev/null 2>&1 \
  && ok  "and a second grant inside what is left of the day is still a grant" \
  || bad "and a second grant inside what is left of the day is still a grant" "refused at 200"
_ovreset "$NP"
_ov felix_overnight_start "$NP" 10 5 "$NS" "ten hours" >/dev/null 2>&1
_ov felix_overnight_start "$NP" 7 5 "$NS" "seven more" >/dev/null 2>&1 \
  && bad "nor past the day's hours" "seventeen hours granted in a day" \
  || ok  "nor past the day's hours"

# The state is one line, and the note is the only field a person types. A tab
# in it silently adds a column; a newline adds a whole second night. Either way
# the next read gets a deadline that is not a deadline.
_ovreset "$NP"
_ov felix_overnight_start "$NP" 2 3 "$NS" "$(printf 'ship it\tthen\nsleep')" >/dev/null 2>&1
is "a note carrying a tab and a newline still leaves one line of six fields" \
   "$(awk 'END {print NR}' "$(_ovfile "$NP" "$NS")" 2>/dev/null):$(awk -F'\t' 'NR==1 {print NF}' "$(_ovfile "$NP" "$NS")" 2>/dev/null)" \
   "1:6"

printf '\nspending the night down\n'
_ovreset "$NP"
_ov felix_overnight_start "$NP" 8 5 "$NS" "five turns" >/dev/null
_said="$(_ov felix_overnight_spend "$NP" 0 "$NS")"
is "one continuation is spent per turn, not two" "$(_ovfield "$NP" 3 "$NS")" "4"
# The budget lesson, in a second place: a count worked out in advance and
# printed is not the count that was written down.
has "and the number it reports is the number it stored" "$_said" "4"
_ov felix_overnight_spend "$NP" 1 "$NS" >/dev/null; _ov felix_overnight_spend "$NP" 1 "$NS" >/dev/null
is "runs with nothing to show accumulate" "$(_ov felix_overnight_quiets "$NP" "$NS")" "2"
_ov felix_overnight_spend "$NP" 0 "$NS" >/dev/null
is "and a turn that did something clears the count" "$(_ov felix_overnight_quiets "$NP" "$NS")" "0"
# A negative continuation count reads as "below the limit" to any comparison
# written the obvious way, which turns an exhausted night into an endless one.
_ovreset "$NP"
_ov felix_overnight_start "$NP" 8 1 "$NS" "last turn" >/dev/null
_ov felix_overnight_spend "$NP" 0 "$NS" >/dev/null; _ov felix_overnight_spend "$NP" 0 "$NS" >/dev/null
is "spending past the last continuation stops at zero" "$(_ovfield "$NP" 3 "$NS")" "0"

printf '\nwhat is waiting for a person in the morning\n'
# The queue is the whole reason a night is allowed at all: the session does not
# stop to ask, so every question it did not ask has to be written down.
_ovreset "$NP"; rm -f "$(_ovdir "$NP")/deferred.tsv"
_ov felix_overnight_start "$NP" 8 5 "$NS" "queue" >/dev/null
_ov felix_overnight_defer "$NP" question "which name to publish under" "felix overnight --report" >/dev/null
_ov felix_overnight_defer "$NP" blocked "the staging token expired" "op signin staging" >/dev/null
is "two deferrals are two things waiting" "$(_ov felix_overnight_deferred_count "$NP")" "2"
# A row that says something is blocked and not how to unblock it hands the
# morning the search, which is the part the night was supposed to have done.
has "and a row carries the command that unblocks it" \
    "$(cat "$(_ovdir "$NP")/deferred.tsv" 2>/dev/null)" "op signin staging"
_ov felix_overnight_defer "$NP" "" "no kind at all" "true" >/dev/null 2>&1
_ov felix_overnight_defer "$NP" question "" "true" >/dev/null 2>&1
is "a deferral with no kind or no subject writes no row" \
   "$(_ov felix_overnight_deferred_count "$NP")" "2"
_ov felix_overnight_clear "$NP" >/dev/null 2>&1
is "clearing the queue empties it" "$(_ov felix_overnight_deferred_count "$NP")" "0"

printf '\nthe Stop hook through a granted night\n'
# The completion gate is what overnight mode changes, so this drives the real
# hook with real JSON against a real repository, the way the gate section does.
# The gate is re-declared rather than inherited: earlier sections rewrite it to
# prove other things, and a green receipt from a gate of `true` would make every
# assertion below pass without measuring anything.
OVSTOP="$FROOT/harness/hooks/stop"
WP="$FROOT/projects/widget"
cat > "$WP/project.json" <<'EOF2'
{
  "name": "widget",
  "remote_match": "example.com/widget",
  "gate": "sh -c 'test -f WIDGET.txt && echo widget-gate-ran'"
}
EOF2
NREPO="$TMP/nightrepo"
mkdir -p "$NREPO"
( _fx_cd "$NREPO" && git init -q -b main
  printf 'contents\n' > WIDGET.txt
  printf 'widget\n'   > .felix
  git add -A >/dev/null 2>&1
  git -c user.name=t -c user.email=t@t commit -qm init >/dev/null 2>&1 )
# mktemp hands back /var on macOS and the engine resolves it to /private/var, so
# a fixture that skips this stamps a receipt against a path the hook will not
# recognise and every green case below reads as a block.
NREPO="$(cd "$NREPO" && pwd -P)"
# An edit the session made, then a gate run over exactly that tree: this is the
# state the hook is designed for. A clean tree reaches the night too, and is
# measured on its own repository further down.
printf 'night work\n' >> "$NREPO/WIDGET.txt"
_ovgate="$(cd "$NREPO" && "$FELIX" gate 2>&1)"; _ovgaterc=$?
is "the fixture tree is green before any night is granted" "$_ovgaterc" "0"

# The payload names the session, says whether the platform is already
# continuing from a block, and points at the transcript the night reads to
# tell work from idling. A tool call is a record whose key is the type; a
# message that only talks about one carries the same words escaped.
OVTX="$TMP/night-transcript.jsonl"; : > "$OVTX"
_ovtool() { printf '{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Bash"}]}}\n' >> "$OVTX"; }
_ovtalk() { printf '{"type":"assistant","message":{"content":[{"type":"text","text":"no call here, only the words \\"type\\":\\"tool_use\\""}]}}\n' >> "$OVTX"; }
_ovstopin() {   # dir, sid [, stop_hook_active [, transcript]]
  ( cd "$1" && printf '{"hook_event_name":"Stop","stop_hook_active":%s,"session_id":"%s","transcript_path":"%s"}' \
      "${3:-false}" "$2" "${4:-}" | "$OVSTOP" 2>&1 )
}
_ovstop() { _ovstopin "$NREPO" "$@"; }
_ovblocks() { case "$2" in *'"decision"'*'"block"'*) ok "$1" ;; *) bad "$1" "expected a block, got [$2]" ;; esac; }
_ovholds_open() { case "$2" in *'"decision"'*'"block"'*) bad "$1" "expected no block, got [$2]" ;; *) ok "$1" ;; esac; }
_ovsays_night() { grep -qi 'overnight' <<<"$2"; }
_ovgone() { [ -f "$(_ovfile "$1" "${2:-}")" ] && echo present || echo gone; }

_ovreset "$WP"
_out="$(_ovstop night-none)"
_ovholds_open "a green tree with no night granted still ends the session" "$_out"
_ovsays_night x "$_out" && bad "and says nothing about a night nobody granted" "$_out" \
                        || ok  "and says nothing about a night nobody granted"

# The grant, and the behaviour it buys: the session is handed back its own turn
# instead of being allowed to stop and wait for somebody who is asleep.
_ov felix_overnight_start "$WP" 8 12 night-live "a granted night" >/dev/null
_ovtool
_out="$(_ovstop night-live false "$OVTX")"
_ovblocks "a granted night hands the session its turn back instead" "$_out"
is  "and exactly one continuation is spent for it" "$(_ovfield "$WP" 3 night-live)" "11"
has "and the session is told how many are left"    "$_out" "11"

# A night is the session's it was granted to. The project held every session
# in it at every stop until this was keyed, and they all spent one budget.
_out="$(_ovstop night-bystander)"
_ovholds_open "another session in the same project is not held by that night" "$_out"
is "and its stop costs that night nothing" "$(_ovfield "$WP" 3 night-live)" "11"

# The platform marks every stop after a block. Leaving at that mark held a
# night's session once per prompt, so a session nobody typed into got one
# continuation for the whole night.
_ovtool
_out="$(_ovstop night-live true "$OVTX")"
_ovblocks "the night's own session is held again inside the platform's chain" "$_out"
is "and that continuation is spent like any other" "$(_ovfield "$WP" 3 night-live)" "10"

# Quiet is read off the transcript: a continuation that called no tool. Prose
# that quotes a tool call is not one, or a session describing its work would
# stay awake forever.
_ovtalk
_out="$(_ovstop night-live true "$OVTX")"
_ovblocks "one continuation that called no tool is not yet the end of the night" "$_out"
is "and it is counted as quiet, prose about a tool call included" "$(_ovfield "$WP" 4 night-live)" "1"
_ovtool
_ovstop night-live true "$OVTX" >/dev/null
is "a tool call after it clears the count" "$(_ovfield "$WP" 4 night-live)" "0"
_ovtalk; _ovstop night-live true "$OVTX" >/dev/null
_ovtalk; _out="$(_ovstop night-live true "$OVTX")"
_ovholds_open "two continuations in a row that call no tool end the night" "$_out"
is "and the night is closed, not left for the next stop" "$(_ovgone "$WP" night-live)" "gone"
has "and the hand-back says it was the idling that ended it" "$_out" "called no tool"
# Unknown is quiet: a hold nobody can show bought any work must not repeat.
_ov felix_overnight_start "$WP" 8 12 night-blind "no transcript" >/dev/null
_ovstop night-blind false "$TMP/no-such-transcript.jsonl" >/dev/null
is "a transcript that cannot be read counts as a quiet continuation" "$(_ovfield "$WP" 4 night-blind)" "1"
_ov felix_overnight_end "$WP" "done" night-blind

# Morning. The deadline is the bound that ends most nights, and the session that
# meets it must be allowed to stop — with the page, not with a block.
_ov felix_overnight_start "$WP" 8 12 night-live "a granted night" >/dev/null
_ovexpire "$WP" night-live
_whystop="$(_ov felix_overnight_expired "$WP" night-live)"
_out="$(_ovstop night-live)"
_ovholds_open "a night that ran out of time lets the session stop" "$_out"
is "and the grant is not left lying around for the next session" "$(_ovgone "$WP" night-live)" "gone"
# The whole reason, not its longest word: "granted" is in two of the three.
if [ "${#_whystop}" -lt 10 ]; then
  bad "and the hand-back names the bound that ended the night" "nothing to look for in [$_whystop]"
else
  has "and the hand-back names the bound that ended the night" "$_out" "$_whystop"
fi

# The grant is permission to keep working, never permission to be wrong. A red
# gate is the one thing a night cannot buy past, and it must not quietly cost a
# continuation on the way to refusing.
rm -f "$NREPO/WIDGET.txt"
( cd "$NREPO" && "$FELIX" gate ) >/dev/null 2>&1
_ovreset "$WP"
_ov felix_overnight_start "$WP" 8 12 night-red "a granted night" >/dev/null
_out="$(_ovstop night-red)"
_ovblocks "a red gate outranks the grant"   "$_out"
has "and the refusal is the gate's own"     "$_out" "gate"
is  "and refusing costs no continuation"    "$(_ovfield "$WP" 3 night-red)" "12"
# Asked on a red tree, where the gate would refuse anybody who got that far.
# On a green one nothing blocks a bystander, so the exit could not be seen.
# The chain is one Felix started, by holding the bystander's own stop first:
# a flagged stop with no hold of Felix's before it belongs to another hook's
# chain and is judged (felix_hold_take, asserted in the completion gate's
# section), which is the case this used to be asked without.
_out="$(_ovstop night-bystander false "$OVTX")"
_ovblocks "a session with no night is held on a red tree like any other" "$_out"
_out="$(_ovstop night-bystander true "$OVTX")"
_ovholds_open "and a chain in a session with no night still ends as the platform asks" "$_out"
# Inside the chain the night carried the session past the platform's bound, so
# a refusal there is the night's to pay for, or a gate that cannot go green
# holds the session for as long as the platform allows.
_ovtool
_out="$(_ovstop night-red true "$OVTX")"
_ovblocks "inside the night's chain a red gate still refuses" "$_out"
is  "and there the refusal is charged to the night" "$(_ovfield "$WP" 3 night-red)" "11"
_ov felix_overnight_start "$WP" 8 1 night-redlast "one continuation" >/dev/null
_ovtool
_out="$(_ovstop night-redlast true "$OVTX")"
_ovholds_open "a night spent down on refusals lets the session close" "$_out"
is "and the night is closed as it goes" "$(_ovgone "$WP" night-redlast)" "gone"
has "and hands over the page as it goes" "$_out" "overnight report for"
# A spend that could not be written held the session and spent nothing, which
# left only the clock as a bound. Now the night ends there and the session may
# close. Root writes through any mode, so there the case cannot be built.
if [ "$(id -u)" = "0" ]; then
  skip "a night whose state cannot be written lets the session close" "running as root"
else
  _ovreset "$WP"
  _ov felix_overnight_start "$WP" 8 12 night-ro "an unwritable night" >/dev/null
  chmod 555 "$(_ovdir "$WP")" "$(_ovdir "$WP")/nights"
  _ovtool
  _out="$(_ovstop night-ro true "$OVTX")"
  chmod 755 "$(_ovdir "$WP")" "$(_ovdir "$WP")/nights"
  _ovholds_open "a night whose state cannot be written lets the session close" "$_out"
fi
printf 'contents\nnight work\n' > "$NREPO/WIDGET.txt"
# Green again, so a stop below that is not held is not held for the night's
# reasons rather than because the gate refused.
( cd "$NREPO" && "$FELIX" gate ) >/dev/null 2>&1

# A tree with nothing to verify let the session close before this, night or
# no night, so a session that had not committed yet was let go for the night.
CREPO="$TMP/nightclean"
mkdir -p "$CREPO"
( _fx_cd "$CREPO" && git init -q -b main
  printf 'contents\n' > WIDGET.txt
  printf 'widget\n'   > .felix
  git add -A >/dev/null 2>&1
  git -c user.name=t -c user.email=t@t commit -qm init >/dev/null 2>&1 )
CREPO="$(cd "$CREPO" && pwd -P)"
_ovreset "$WP"
_out="$(_ovstopin "$CREPO" night-clean)"
_ovholds_open "a clean tree with no night still closes in silence" "$_out"
_ov felix_overnight_start "$WP" 8 12 night-clean "a granted night" >/dev/null
_ovtool
_out="$(_ovstopin "$CREPO" night-clean false "$OVTX")"
_ovblocks "a clean tree does not end the night of the session standing in it" "$_out"
_ovreset "$WP"

printf '\nwhat the next session is told\n'
# The direction has to reach the session that will act on it, and the only
# channel for that is the start of the session. Said when no night is running it
# is an instruction to work unattended that nobody granted, and said to a
# session the night is not for, it is the same instruction.
_ovnstart() { ( cd "$NREPO" && printf '{"hook_event_name":"SessionStart","source":"startup","session_id":"%s"}' "$1" \
                  | CLAUDE_PLUGIN_ROOT="$FROOT" "$FROOT/harness/hooks/session-start" 2>&1 ); }
_ovreset "$WP"
_ov felix_overnight_start "$WP" 8 12 night-start "a granted night" >/dev/null
_out="$(_ovnstart night-start)"
# Asked against the direction the library hands out, not against the word
# "overnight" appearing somewhere in the context. A hook that says a night is on
# and mounts none of the standing direction is the failure this exists to catch,
# and the word alone cannot tell the two apart — measured, with the mount
# removed and the assertion still passing.
_ovline="$(_ov felix_overnight_direction | awk '{ if (length($0) > length(m)) m = $0 } END { print m }')"
if [ "${#_ovline}" -lt 20 ]; then
  bad "a live night is mounted into the next session's context" "no direction to look for"
  bad "and not into a session the night does not belong to" "no direction to look for"
else
  has "a live night is mounted into the next session's context" "$_out" "$_ovline"
  _out="$(_ovnstart night-bystander)"
  case "$_out" in *"$_ovline"*) bad "and not into a session the night does not belong to" "$_out" ;;
                  *) ok "and not into a session the night does not belong to" ;; esac
fi
# The one file per project an older engine wrote is read and ended, and holds
# nobody: a night granted before nights were a session's is not announced to
# whichever session happens to start, which is the defect itself.
_ovreset "$WP"
mkdir -p "$(_ovdir "$WP")"
printf '%s\t%s\t12\t0\t-\tgranted under an older engine\n' "$(date +%s)" "$(( $(date +%s) + 3600 ))" > "$(_ovfile "$WP")"
_out="$(_ovnstart night-upgraded)"
case "$_out" in *"${_ovline:-no direction}"*) bad "a night an older engine granted to the project is announced to no session" "$_out" ;;
                *) ok "a night an older engine granted to the project is announced to no session" ;; esac
_out="$(_ovstop night-upgraded)"
_ovholds_open "and holds no session at its stop" "$_out"
# A session that closed before its night ran out leaves the night behind, and
# with a night per session nothing else would ever read it again. The session
# that starts next ends the ones whose deadline passed, and leaves the rest.
_ovreset "$WP"
_ov felix_overnight_start "$WP" 8 12 night-gone "its session closed early" >/dev/null
_ov felix_overnight_start "$WP" 8 12 night-running "still inside its deadline" >/dev/null
_ovexpire "$WP" night-gone
_ovnstart night-sweeper >/dev/null
is "a later session ends a night whose deadline passed, and only that one" \
   "$(_ovgone "$WP" night-gone):$(_ovgone "$WP" night-running)" "gone:present"
_ovreset "$WP"
_out="$(_ovnstart night-none)"
_ovsays_night x "$_out" && bad "and no night is announced when none was granted" "$_out" \
                        || ok  "and no night is announced when none was granted"

printf '\nthe command a founder types\n'
# The surface itself. Everything above is reachable only through this, and a
# flag that silently does nothing is indistinguishable from a night that went
# well. The session is set by hand, because the suite runs both inside a
# session that exports one and on a runner that exports none.
_ovcli()   { ( cd "$NREPO" && CLAUDE_CODE_SESSION_ID=night-cli "$FELIX" overnight "$@" 2>&1 ); }
_ovcli2()  { ( cd "$NREPO" && CLAUDE_CODE_SESSION_ID=night-cli2 "$FELIX" overnight "$@" 2>&1 ); }
_ovcliterm() { ( cd "$NREPO" && env -u CLAUDE_CODE_SESSION_ID "$FELIX" overnight "$@" 2>&1 ); }
_ovnights() { _ov felix_overnight_nights "$WP" | grep -c .; }
_ovreset "$WP"; rm -f "$(_ovdir "$WP")/deferred.tsv"
_out="$(_ovcli)"; _rc=$?
is "felix overnight with no arguments says where the night stands" \
   "$_rc:$([ -n "$_out" ] && echo said || echo silent)" "0:said"
_ovcli --start --hours 2 --turns 6 --note "granted from the command line" >/dev/null 2>&1
_ov felix_overnight_active "$WP" night-cli && ok "--start grants the night" \
                                           || bad "--start grants the night" "no state at $(_ovfile "$WP" night-cli)"
is "and grants it to the session it was typed in, and no other" "$(_ovnights)" "1"
_ovcli2 --start --hours 3 >/dev/null 2>&1
is "a second session's grant is a second night, not a replacement" \
   "$(_ovnights):$(_ovfield "$WP" 3 night-cli)" "2:6"
_ovcli --defer question --what "which name to publish under" --unblock "felix overnight --report" >/dev/null 2>&1
is "--defer writes the decision down for the morning" "$(_ov felix_overnight_deferred_count "$WP")" "1"
# A kind nobody defined means a queue nobody can sort in the morning, and the
# row is written by a session with no one watching it type.
_out="$(_ovcli --defer florbnax --what "something" --unblock "true")"; _rc=$?
is "a kind nobody defined is refused, with a reason" \
   "$([ "$_rc" -ne 0 ] && [ -n "$_out" ] && echo refused || echo "accepted ($_rc)")" "refused"
_out="$(_ovcli --report)"; _rc=$?
is "--report prints the morning page" "$_rc:$([ -n "$_out" ] && echo said || echo silent)" "0:said"
is  "and the page shows every session's night, not only the reader's" \
    "$(printf '%s\n' "$_out" | grep -c '^  session night-cl')" "2"
_ovcli --clear >/dev/null 2>&1
is "--clear empties the queue" "$(_ov felix_overnight_deferred_count "$WP")" "0"
_ovcli --end >/dev/null 2>&1
_ov felix_overnight_active "$WP" night-cli && bad "--end ends the night" "still live" \
                                           || ok  "--end ends the night"
_ov felix_overnight_active "$WP" night-cli2 && ok "and ends that session's night and no other" \
                                            || bad "and ends that session's night and no other" "night-cli2 ended too"
# From inside a session, a night is that session's to take and nobody else's
# to give: the one it names would be held at every stop.
_out="$(_ovcli --start --session night-victim)"; _rc=$?
is "a session cannot grant a night to another session" \
   "$([ "$_rc" -ne 0 ] && echo refused || echo accepted):$([ -f "$(_ovfile "$WP" night-victim)" ] && echo granted || echo none)" \
   "refused:none"
# --end ends the caller's night only, so the way out of all of them from
# inside any session is named.
_ovcli --start --hours 1 >/dev/null 2>&1
_ovcli --end --all >/dev/null 2>&1
is "--end --all from inside a session ends every night" "$(_ovnights)" "0"
_ovcli2 --start --hours 1 >/dev/null 2>&1
# A terminal is inside no session, so there is nobody for a night typed there
# to hold. It is refused with the way to type it inside one, and --end typed
# there is a person's way out of every night at once.
_out="$(_ovcliterm --start)"; _rc=$?
is "a night typed outside every session is refused, and nothing is granted" \
   "$([ "$_rc" -ne 0 ] && echo refused || echo accepted):$(_ovnights)" "refused:1"
has "and the refusal says how to type it inside the session" "$_out" "! felix overnight --start"
printf '%s\t%s\t12\t0\t-\tan older engine\n' "$(date +%s)" "$(( $(date +%s) + 3600 ))" > "$(_ovfile "$WP")"
_ovcliterm --end >/dev/null 2>&1
is "and --end typed there ends every night, an older engine's included" "$(_ovnights)" "0"
# The id becomes a file name, and it arrives from the environment.
_out="$( ( cd "$NREPO" && CLAUDE_CODE_SESSION_ID='../../escaped' "$FELIX" overnight --start 2>&1 ) )"; _rc=$?
is "a session id that cannot name a file is refused, and nothing is written where it points" \
   "$([ "$_rc" -ne 0 ] && echo refused || echo "accepted"):$([ -e "$(_ovdir "$WP")/escaped" ] && echo written || echo absent):$(_ovnights)" \
   "refused:absent:0"
_ovreset "$WP"

# A night's hold goes on record like any other, and the record is taken at
# every flagged stop, a night's included (lib/verify.sh, felix_hold_take). Each
# half has its own way to fail. Unrecorded, a night a person ends mid-chain
# leaves the flagged stop after its hold looking like another hook's chain, and
# it is held a second time in a row. Untaken, the record outlives the night and
# waves the next rewake turn through unchecked.
#
# Both need the night's own hold, which only a green tree reaches, so the tree
# is made green here rather than inherited from whatever ran last, and each
# hold is asked for by what it says: a block alone is also what the gate's hold
# looks like, and a fixture with no probes reached that one instead and passed.
_ovrows() { awk 'END { print NR }' "$MEM/widget/verification.log" 2>/dev/null || echo 0; }
( _fx_cd "$NREPO" && git checkout -q -- . ); printf 'night work\n' >> "$NREPO/WIDGET.txt"
_ovgate="$(cd "$NREPO" && "$FELIX" gate 2>&1)"; _ovgaterc=$?
is "the tree is green before the hold record meets a night" "$_ovgaterc" "0"
rm -rf "$FROOT/state/held"
_ov felix_overnight_start "$WP" 8 5 night-held "a granted night" >/dev/null
_ovtool; _out="$(_ovstop night-held false "$OVTX")"
has "a night holds its session on a green tree with a hold of its own" "$_out" "Overnight is on"
_ov felix_overnight_end "$WP" "ended by hand" night-held >/dev/null
_ovn="$(_ovrows)"
_ovtool; _out="$(_ovstop night-held true "$OVTX")"
is "a night ended mid-chain leaves the stop after its hold to the night's own chain" \
   "$(( $(_ovrows) - _ovn )):[$_out]" "0:[]"
_ovreset "$WP"; rm -rf "$FROOT/state/held"
_ov felix_overnight_start "$WP" 8 2 night-spent "two turns" >/dev/null
_ovtool; _out="$(_ovstop night-spent false "$OVTX")"
has "a two-turn night holds at its first stop" "$_out" "Overnight is on"
_ovtool; _out="$(_ovstop night-spent true "$OVTX")"
has "and ends at the flagged stop after it" "$_out" "Overnight is over"
_ovn="$(_ovrows)"
_ovtool; _ovstop night-spent true "$OVTX" >/dev/null
is "and the hold a night made does not outlive it: the rewake turn after is judged" \
   "$(( $(_ovrows) - _ovn ))" "1"
_ovreset "$WP"; rm -rf "$FROOT/state/held"

