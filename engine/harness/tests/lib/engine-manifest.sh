# tests/lib/engine-manifest.sh: what 0720 and 0730 read from the rest of the suite.
# Used by 0720 (TBROOT, and the two widget logs its schema checks read) and 0730
# (TBROOT). Moved from parts/0720-the-engine-manifest.sh line 209: the TBROOT
# assignment, verbatim.
# Definitions only. _engine_manifest_build sets TBROOT first. The widget's
# lifecycle.log and decisions.log are written in the serial run by the sessions
# and the decline that earlier parts run; where one is there already (not empty)
# it is left as it stands, and where it is absent the builder writes it by the
# commands that write it: the recorder's four moments for the lifecycle log, and
# `felix route --ack`'s own writer for a decline. It runs no felix command and
# no assertion.

_engine_manifest_build() {
  TBROOT="$(git -C "$REAL_HARNESS" rev-parse --show-toplevel 2>/dev/null)"
  [ -s "$MEM/widget/lifecycle.log" ] || ( . "$REAL_HARNESS/lib/resolve.sh"; . "$REAL_HARNESS/lib/lifecycle.sh"
    felix_lifecycle_session widget "$REPO" startup lib-em-a "$TMP/lib-em-a.jsonl"
    felix_lifecycle_session widget "$REPO" resume lib-em-b "$TMP/lib-em-b.jsonl"
    felix_lifecycle_summary widget "$REPO" lib-em-c "$TMP/lib-em-c.jsonl"
    felix_lifecycle_handoff widget "$REPO" written ) >/dev/null 2>&1
  [ -s "$MEM/widget/decisions.log" ] || ( . "$REAL_HARNESS/lib/resolve.sh"; . "$REAL_HARNESS/lib/route.sh"
    felix_route_ack widget "$REPO" "$TMP/lib-em-home" "the play does not fit this change" ) >/dev/null 2>&1
  return 0
}
