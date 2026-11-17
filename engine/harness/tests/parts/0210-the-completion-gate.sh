printf '\nthe completion gate\n'
_plain_build
# The principle under test: an agent must not be able to say it is finished
# while the tree it changed has never been verified. Everything here drives the
# real Stop hook with real JSON on stdin, against a real git repository.
_hook_payload_vars
# Earlier sections rewrite the widget gate to prove other things, so this one
# declares the gate it depends on instead of inheriting whatever ran last.
# Without this the red-gate case silently tests a gate of `true`, which cannot
# fail, and the failure reads like a product bug rather than a suite bug.
_gate_repo_build

ACTIVE_JSON='{"hook_event_name":"Stop","stop_hook_active":true}'

out="$(_stop "$GREPO")"; rc=$?
_allows "a session that changed nothing stops silently" "$out"
is      "and exits 0"                                   "$rc" "0"

# The guidebook states DEFINITION OF DONE absolutely: never declare a task
# complete while a required deterministic verification step is failing. The hook
# opened with a bare `felix_tree_dirty || exit 0`, so committing your work
# skipped the check entirely — and committing is what you do at the end. Every
# session that finished properly was the one never asked.
#
# "Dirty" was standing in for "this session changed something", and those come
# apart the moment anybody commits. SessionStart now records the HEAD it saw, so
# the two can be told apart.
SESS='{"hook_event_name":"Stop","stop_hook_active":false,"session_id":"dod-sess"}'
# Laid by the real hook rather than hand-written, so the test exercises the
# path that actually runs. UserPromptSubmit carries the session id;
# SessionStart never reads its payload at all.
_start_at() {
  rm -f "$FROOT/state/session/dod-sess"
  ( cd "$1" && printf '{"session_id":"dod-sess","prompt":"begin"}' \
      | "$FROOT/harness/hooks/user-prompt" >/dev/null 2>&1 )
}

_start_at "$GREPO"
out="$(_stop "$GREPO" "$SESS")"
_allows "a recorded session that committed nothing is still silent" "$out"

printf 'committed work\n' >> "$GREPO/WIDGET.txt"
( _fx_cd "$GREPO" && git add -A >/dev/null 2>&1 \
  && git -c user.name=t -c user.email=t@t commit -qm work >/dev/null 2>&1 )
out="$(_stop "$GREPO" "$SESS")"
_blocks "committing unverified work no longer skips the check" "$out"
has     "and says the gate has not seen it"                    "$out" "gate"

# Fail open when there is no record: a session that began before this shipped,
# or one whose id could not be read, must not start blocking on a clean tree.
out="$(_stop "$GREPO" "$EMPTY_JSON")"
_allows "with no session record it behaves as before" "$out"
rm -f "$FROOT/state/session/dod-sess"

# Restore the fixture for the assertions below, which expect an unverified edit.
( _fx_cd "$GREPO" && git reset -q --hard HEAD~1 )

printf 'edited\n' >> "$GREPO/WIDGET.txt"
out="$(_stop "$GREPO")"
_blocks "an unverified change blocks completion" "$out"
has     "and says the gate never ran"            "$out" "never"

# The table is written BEFORE the gate runs. stack.tsv is in the epoch's
# policy set, and a receipt is bound to the epoch its gate ran under (v3.2
# §5), so a table edited after the gate stales the receipt and the stop below
# would block on "the table set moved" — correctly — instead of reaching the
# nudge this is about.
printf 'plugin\tsuperpowers@x\t-\tlow\talways\n' > "$FROOT/projects/widget/stack.tsv"
out="$(cd "$GREPO" && "$FELIX" gate 2>&1)"
out="$(_stop "$GREPO")"
_allows "a green gate on this exact tree allows it" "$out"

# A green gate proves the suite passed and nothing about the claims made on the
# way there. Those are what go wrong: work reported as fixed that reached no
# session, a tool reported as removed that was still installed, a document
# describing a capability the thing had outgrown. All three passed a gate.
rm -rf "$FROOT/state/verified"
out="$(cd "$GREPO" && printf '{"hook_event_name":"Stop","stop_hook_active":false,"session_id":"vsess"}' \
       | "$STOP" 2>&1)"
has "a green gate still asks for verification" "$out" "verification-before-completion"
has "and says why the gate is not enough"      "$out" "does not mean"
has "and says the suite passed when nothing was skipped" "$out" "which means the suite passed"
# Once per session. Said at every stop it becomes noise, and noise is skimmed.
out="$(cd "$GREPO" && printf '{"hook_event_name":"Stop","stop_hook_active":false,"session_id":"vsess"}' \
       | "$STOP" 2>&1)"
case "$out" in
  *verification-before-completion*) bad "and only once per session" "$out" ;;
  *)                                ok  "and only once per session" ;;
esac

# And the sentence does NOT claim a passing suite when the gate skipped it.
# `felix gate --quick` skips the tests and still exits 0, so its receipt was
# byte-identical to a full run's — one bit — and this said "the suite passed"
# over it. The receipt's fifth field names what the gate reported skipping.
# Placed after the once-per-session assertion above, not before it: clearing
# the marker is what that assertion measures, so a block that clears it in the
# middle makes the sentence fire twice and reads as a defect in the hook rather
# than in the fixture.
rm -rf "$FROOT/state/verified"
( cd "$GREPO" && . "$FROOT/harness/lib/verify.sh"
  felix_verify_record "$GREPO" "$FROOT" 0 "gate.sh" "$(felix_tree_id "$GREPO" "$FROOT")" "tests" >/dev/null 2>&1 )
out="$(cd "$GREPO" && printf '{"hook_event_name":"Stop","stop_hook_active":false,"session_id":"vsess-skip"}' \
       | "$STOP" 2>&1)"
has "a gate that skipped the suite is not called a passing suite" "$out" "it skipped: tests"
case "$out" in
  *"which means the suite passed"*) bad "and the claim it could not support is gone" "$out" ;;
  *)                                ok  "and the claim it could not support is gone" ;;
esac
( cd "$GREPO" && . "$FROOT/harness/lib/verify.sh"
  felix_verify_record "$GREPO" "$FROOT" 0 "gate.sh" "$(felix_tree_id "$GREPO" "$FROOT")" "" >/dev/null 2>&1 )
# A project that does not use superpowers is not told to reach for it.
printf 'plugin\tsomething-else@x\t-\tlow\talways\n' > "$FROOT/projects/widget/stack.tsv"
rm -rf "$FROOT/state/verified"
out="$(cd "$GREPO" && printf '{"hook_event_name":"Stop","stop_hook_active":false,"session_id":"vsess2"}' \
       | "$STOP" 2>&1)"
case "$out" in
  *verification-before-completion*) bad "and never where it is not declared" "$out" ;;
  *)                                ok  "and never where it is not declared" ;;
esac
rm -rf "$FROOT/state/verified"

# The git-status trap. Two different edits to the same file produce identical
# porcelain output, so a receipt keyed on status alone stays valid across a
# change it never saw. The hash has to include diff content.
printf 'different\n' >> "$GREPO/WIDGET.txt"
out="$(_stop "$GREPO")"
_blocks "editing the same file again invalidates the receipt" "$out"

( _fx_cd "$GREPO" && git checkout -q -- WIDGET.txt )
out="$(cd "$GREPO" && "$FELIX" gate 2>&1)"
printf 'new\n' > "$GREPO/untracked.txt"
out="$(_stop "$GREPO")"
_blocks "a new untracked file invalidates the receipt" "$out"
rm -f "$GREPO/untracked.txt"

# The platform caps consecutive blocks and documents the contract: return
# success while stop_hook_active is set. Ignoring it is how a hook loops.
printf 'unverified\n' >> "$GREPO/WIDGET.txt"
out="$(_stop "$GREPO" "$ACTIVE_JSON")"
_allows "stop_hook_active is honoured, so it never loops" "$out"

# That rule is about a chain Felix started, and the flag does not say who did.
# An asyncRewake hook that exits 2 wakes the model into a turn of its own with
# the flag already set (measured on Claude Code 2.1.260 and 2.1.280, a Stop
# and a PostToolUse hook alike), and security-guidance, which commissioning
# installs for every project, is one. Leaving at the flag let the turn that
# answered a background review end unchecked and unrecorded. Driven through
# the real hook, in the order the platform sends these stops.
rm -rf "$FROOT/state/held"
_n0="$(_hn)"
out="$(_stop "$GREPO" "$(_hj true rw-foreign)")"
_blocks "a flagged stop in a chain Felix did not start is judged, not waved through" "$out"
is "and that hold is on the record" "$(( $(_hn) - _n0 )):$(tail -1 "$_hv" | cut -f2)" "1:blocked"
# Silence alone cannot tell Felix's own chain from a hold that went unrecorded
# and was then refused inside a chain it took for another's. Only the first
# writes no row.
_n0="$(_hn)"
out="$(_stop "$GREPO" "$(_hj true rw-foreign)")"
is "the flagged stop after that hold is Felix's own chain, and ends there" \
   "$(( $(_hn) - _n0 )):[$out]" "0:[]"

# The record is taken by the stop it was for, so a rewake turn right after
# Felix's own chain is not mistaken for part of it.
out="$(_stop "$GREPO" "$(_hj false rw-own)")"
_n0="$(_hn)"
out="$(_stop "$GREPO" "$(_hj true rw-own)")"
is "a hold lets the one flagged stop it started end" "$(( $(_hn) - _n0 )):[$out]" "0:[]"
# Restated for the hold once per tree (slot 2a, part B): judged, the rewake
# turn finds the tree the session was held on, so it is debt, a row of its own,
# where a turn taken for part of Felix's chain would have written none.
_n0="$(_hn)"
out="$(_stop "$GREPO" "$(_hj true rw-own)")"
is "and only that one: the rewake turn after it is judged, as debt on the tree it was held on" \
   "$(( $(_hn) - _n0 )):$(tail -1 "$_hv" | cut -f2):[$out]" "1:debt:[]"

# A chain can end without reaching its flagged stop (an interrupted turn), and
# the next prompt's stop is unflagged. That stop starts afresh and clears what
# was left, or the leftover waves the next rewake turn through.
out="$(_stop "$GREPO" "$(_hj false rw-stale)")"
out="$(cd "$GREPO" && _hj false rw-stale | FELIX_ALLOW_RED=1 "$STOP" 2>&1)"
# Restated for the hold once per tree: the flagged stop is judged, and on the
# tree the session was held on that is a debt row. A hold left behind would have
# ended it at the flag with no row.
_n0="$(_hn)"
out="$(_stop "$GREPO" "$(_hj true rw-stale)")"
is "an unflagged stop clears a hold left behind, so the flagged stop after it is judged" \
   "$(( $(_hn) - _n0 )):$(tail -1 "$_hv" | cut -f2)" "1:debt"

# The id comes from the payload, so it is checked before it names a file. One
# that cannot name a file ends a flagged stop, as the flag always did, and a
# hold made under it writes nothing outside state/held.
out="$(_stop "$GREPO" "$(_hj false ../held-escape)")"
_blocks "an id that cannot name a file still holds an unflagged stop" "$out"
[ -e "$FROOT/state/held-escape" ] && bad "and records nothing outside state/held" "$FROOT/state/held-escape" \
                                  || ok  "and records nothing outside state/held"
out="$(_stop "$GREPO" "$(_hj true ../held-escape)")"
_allows "and a flagged stop under it ends, as before" "$out"

# A hold that cannot be recorded. Starting a chain, Felix holds anyway: the
# flagged stop after it is judged once more and let through, two holds at
# most. Inside another hook's chain it does not hold, since that would be the
# second in a row, and it says so on the record instead.
# The record of the tree held on cannot be written either, or the flagged stop
# would be debt on that tree before it came to this rule.
rm -rf "$FROOT/state/held" "$FROOT/state/held-tree"; : > "$FROOT/state/held"; : > "$FROOT/state/held-tree"
out="$(_stop "$GREPO" "$(_hj false rw-ro)")"
_blocks "an unflagged stop holds even when the hold cannot be recorded" "$out"
out="$(_stop "$GREPO" "$(_hj true rw-ro)")"
_allows "but a flagged one does not hold again unrecorded" "$out"
has "and the record says why" "$(tail -1 "$_hv")" "could not be recorded"
rm -f "$FROOT/state/held" "$FROOT/state/held-tree"

# The flag is a FIELD. The payload also carries the model's last message, and
# a glob for the key followed by `true` anywhere after it was satisfied by a
# message that used the word — an unverified tree whose session ended with
# "that is true" was exempt from its own gate. Found by the review, not by
# the suite, which had only ever sent the flag alone.
out="$(_stop "$GREPO" '{"hook_event_name":"Stop","stop_hook_active":false,"last_assistant_message":"and that is true"}')"
_blocks "the word true in the last message does not read as the flag" "$out"
out="$(_stop "$GREPO" '{"hook_event_name":"Stop","last_assistant_message":"\"stop_hook_active\": true","stop_hook_active":false}')"
_blocks "nor does the key spelt inside a string, which a quote cannot open" "$out"

# The override is the founder's, not the model's: it is read from the
# environment the session was launched with.
out="$(cd "$GREPO" && FELIX_ALLOW_RED=1 printf '%s' "$EMPTY_JSON" | FELIX_ALLOW_RED=1 "$STOP" 2>&1)"
_allows "FELIX_ALLOW_RED lets a founder stop anyway" "$out"

# A failing gate must leave a red receipt, not no receipt. No receipt and a red
# one both block, but only one of them tells the truth about what happened.
rm -f "$GREPO/WIDGET.txt"
out="$(cd "$GREPO" && "$FELIX" gate 2>&1)"
out="$(_stop "$GREPO")"
_blocks "a failing gate still blocks"  "$out"
has     "and says the gate failed"     "$out" "failed"
printf 'contents\n' > "$GREPO/WIDGET.txt"

VLOG="$MEM/widget/verification.log"
[ -s "$VLOG" ] && ok "every decision is recorded" \
               || bad "every decision is recorded" "no verification.log at $VLOG"
if [ -s "$VLOG" ]; then
  grep -q 'blocked'  "$VLOG" && ok "blocks are recorded"    || bad "blocks are recorded"
  grep -q 'override' "$VLOG" && ok "overrides are recorded" || bad "overrides are recorded"
fi

out="$(_stop "$PLAIN")"; rc=$?
_allows "silent in an ungoverned repo" "$out"
is      "and exits 0 there"            "$rc" "0"

NOGIT="$TMP/notgit"; mkdir -p "$NOGIT"; printf 'widget\n' > "$NOGIT/.felix"
out="$(_stop "$NOGIT")"; rc=$?
_allows "silent outside a git repository" "$out"
is      "and exits 0 there too"           "$rc" "0"

