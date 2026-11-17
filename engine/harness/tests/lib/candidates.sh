# tests/lib/candidates.sh: the topology and the epoch an answer file is keyed to.
# Used by parts 0400 (candidates: what a model proposed) and 0780 (exceptions),
# which keys a surveyed answer to the tree as it stands. Moved from
# parts/0400-candidates-what-a-model-proposed-and-nothing.sh, lines 178-188:
# _cdlib, _cdtopo and _cdepoch, verbatim.
# Definitions only. Each function runs in the subshell its caller opens or in the
# one it opens itself, and takes the project and the repository as arguments;
# with none it reads CDP and CDR, which 0400 sets and 0780, passing its own,
# never needs. _cdlib puts CMSTUB (cm-stub.sh, _cmstub_build) first on PATH, so
# a caller builds the stub before it asks.

# The topology an answer is keyed to, asked the way the provider assertions
# ask it, and the epoch, asked the way the epoch assertions ask it. Neither is
# the code under test, and both are checked non-empty before anything leans on
# them: `Epoch ` with nothing after it is a needle every haystack contains.
_cdlib() { FELIX_HOME_DIR="$FROOT"; PATH="$CMSTUB:$PATH"
           . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/detect.sh"; . "$FROOT/harness/lib/stack.sh"
           . "$FROOT/harness/lib/probes.sh"; . "$FROOT/harness/lib/verify.sh"; . "$FROOT/harness/lib/toolbox.sh"
           . "$FROOT/harness/lib/discover.sh"; . "$FROOT/harness/lib/ready.sh"; . "$FROOT/harness/lib/commission.sh"
           . "$FROOT/harness/lib/commission-provider.sh"; . "$FROOT/harness/lib/epoch.sh"; }
_cdtopo()  { ( _cdlib; felix_commission_topology "${1:-$CDP}" "${2:-$CDR}" ) 2>/dev/null; }
_cdepoch() { ( _cdlib; felix_epoch "${1:-$CDP}" "${2:-$CDR}" ) 2>/dev/null; }
