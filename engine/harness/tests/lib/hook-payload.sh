# tests/lib/hook-payload.sh: the Stop hook's payload helpers.
# Used by 0210 (builds them), 0220 and 0250 (STOP), plus 0220's EMPTY_JSON, _stop,
# _blocks, _allows, _hj and _hv. Moved from parts/0210-the-completion-gate.sh:
# STOP (line 301), EMPTY_JSON (322), _stop (324), _blocks (325-327), _allows (328),
# _hj (464), _hv (465), _hn (466). Part 0120 defined a different _hn, a reader of
# the handoff note; it is _hnote there now, so this _hn reaches every later part.
# Definitions only. _hook_payload_vars assigns the three variables (the same
# strings every time, so a second call changes nothing).

_hook_payload_vars() {
  STOP="$FROOT/harness/hooks/stop"
  EMPTY_JSON='{"hook_event_name":"Stop","stop_hook_active":false}'
  _hv="$MEM/widget/verification.log"
}
_stop() { ( cd "$1" && printf '%s' "${2:-$EMPTY_JSON}" | "$STOP" 2>&1 ); }
_blocks() {
  case "$2" in *'"decision"'*'"block"'*) ok "$1" ;; *) bad "$1" "expected a block, got [$2]" ;; esac
}
_allows() { [ -z "$2" ] && ok "$1" || bad "$1" "expected silence, got [$2]"; }
_hj() { printf '{"hook_event_name":"Stop","stop_hook_active":%s,"session_id":"%s"}' "$1" "$2"; }
_hn() { awk 'END { print NR }' "$_hv" 2>/dev/null || echo 0; }
