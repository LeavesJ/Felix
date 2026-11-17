printf '\nfound after the blind part: felix status and the index, and a long list\n'
# Written by the implementer after the blind part (1100), not blind, for two
# things the blind part did not reach.
#
# The first is felix status and the index. The blind part's S4 assertion runs
# with no receipt, where felix_verify_current answers `none` before it touches
# git. With a green receipt it computes the tree id, which runs `git diff HEAD`,
# and that command rewrites .git/index when a tracked file is only stat-dirty,
# GIT_OPTIONAL_LOCKS=0 or not (measured on git 2.54: the variable stops git
# status and not git diff). The gate row must still answer, and the checkout
# must be exactly as it was.
#
# Uses the fixtures part 1100 leaves behind: RXC is a governed checkout, a green
# receipt for its present tree sits in RXH (it reads current), and RXLOG is the
# claude stub's log. The control comes first: the row reads current, so the
# fixture reaches the branch that computes the tree id.
_rx_build gate-green 1110
_rx_gr2() { _rx_field "$(_rx_st "$RXC" --tsv)" gate | cut -f2-; }
is "the control: with a green receipt for the tree the gate row reads current" "$(_rx_gr2)" "$(printf 'value\tcurrent\t-')"
mkdir -p "$RX/tmpd"
# A second between the last git run and the touch: a touch in the same second as
# the index's own write is racily clean, and git then leaves the index alone.
sleep 1; ( cd "$RXC" && touch f.txt ); sleep 1; touch "$RX/marker2"; : > "$RXLOG"
_rxg="$(TMPDIR="$RX/tmpd" _rx_st "$RXC" --tsv | awk -F'\t' '$1 == "gate"' | cut -f2-)"
is "touching a tracked file without editing it still reads current" "$_rxg" "$(printf 'value\tcurrent\t-')"
is "and git's index, the checkout, the home's state and the memory root are as they were" \
   "$(find "$RXC" "$RXH/state" "$RXMEM" -newer "$RX/marker2" 2>/dev/null)" ""
is "and no scratch index is left in TMPDIR" "$(find "$RX/tmpd" -mindepth 1 2>/dev/null)" ""
is "and status ran no claude command" "$(cat "$RXLOG")" ""
printf 'edited\n' > "$RXC/f.txt"; sleep 1; touch "$RX/marker3"
_rxg="$(TMPDIR="$RX/tmpd" _rx_st "$RXC" --tsv | awk -F'\t' '$1 == "gate"' | cut -f2-)"
is "an edit after the receipt reads stale" "$_rxg" "$(printf 'value\tstale\tthe tree changed since the receipt')"
is "and leaves the checkout and the home's state as they were" \
   "$(find "$RXC" "$RXH/state" "$RXMEM" -newer "$RX/marker3" 2>/dev/null)" ""
( _fx_cd "$RXC" && git checkout -q -- f.txt )

# The second: reach reading a long list. The blind part's lists have six lines.
# The first draft of felix_reach_read took the whitespace out of the list with
# ${body//[ws]/} to see whether anything was left, and on bash 3.2 a global
# substitution over a list this size is quadratic: 100 server lines took 3 s,
# 200 took 17 s and 400 took 100 s, at an ordinary load. This machine's own list
# has about a hundred lines. The bound is generous and still separates the two
# by a factor of ten.
RXBIG="$RX/list-big"
{ printf 'Checking MCP server health\342\200\246\n\n'
  _rxi=0; while [ "$_rxi" -lt 300 ]; do
    printf 'plugin:bulk%d:srv: https://b.example/%d?x=1 (HTTP) - \342\234\224 Connected\n' "$_rxi" "$_rxi"; _rxi=$((_rxi+1)); done
  printf 'plugin:ctx:ctx: https://mcp.example/mcp (HTTP) - \342\234\224 Connected\n'
} > "$RXBIG"
_rxt0="$(_rx_ms)"; _rxbig="$(RX_LIST="$RXBIG" _rx_rows reachy)"; _rxt1="$(_rx_ms)"
[ $(( _rxt1 - _rxt0 )) -lt 8000 ] && ok "a list of 300 servers is read and classified in under 8 s" \
  || bad "a list of 300 servers is read and classified in under 8 s" "$(( _rxt1 - _rxt0 )) ms"
is "and the declared plugin among them still reads connected" "$(_rx_pick "$_rxbig" ctx@m | cut -f1)" "connected"
is "and the rows are still one for each plugin row, none of the others owning a server" "$(printf '%s\n' "$_rxbig" | grep -c .)" "7"
_rx_cleanup 1110
