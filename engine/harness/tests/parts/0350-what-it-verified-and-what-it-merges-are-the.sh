printf '\nwhat it verified and what it merges are the same branch\n'
# 2026-10-18 (judge refs): felix merge takes a full ref name as its base and
# refuses an expression such as HEAD~1, which git reads in its short-name order.
# The commit before the tip is therefore named by a branch made at it.
_mbase() { _fx_git "$1" update-ref refs/heads/jr-mbase HEAD~1 >/dev/null 2>&1; printf 'refs/heads/jr-mbase'; }
# Issue #33, from the same concurrency audit. felix merge computed the tree
# identity, checked the receipt against it, ran the evidence check — and only
# then read the branch name. A peer's `git checkout` in the same working copy
# inside that gap made it squash-merge a branch nothing had verified, and print
# that nothing in it escaped the tree. Measured at ~35% of the command's
# runtime, and the harm is the worst category the audit found: an ungated
# escape merged into main, reported as verified, recorded nowhere.
#
# Injected at `git remote get-url`, which is the one landmark that sits inside
# exactly that window: felix_repo_slug is its only caller on this path, and it
# runs after the receipt is checked and before the branch is read. Verified by
# probe rather than assumed — a counted trigger would rot silently the first
# time the call sequence changed.
_merge_repo_build
GB="$TMP/gitstub"; mkdir -p "$GB"
GITREAL="$(command -v git)"
# Parameterised on both halves, because one hard-coded scenario tested one third
# of the guard. RACE_ON picks where in the command the peer lands, RACE_CMD picks
# what the peer does. Between them they reach all three fields of the tuple and
# both sides of felix_merge_blockers.
cat > "$GB/git" <<STUB
#!/usr/bin/env bash
case "\$*" in
  *"\${RACE_ON:-remote get-url}"*)
    if [ -n "\${RACE_CMD:-}" ] && [ ! -f "\${RACE_FIRED:-/nonexistent}" ]; then
      printf 'fired\n' > "\$RACE_FIRED"
      eval "\$RACE_CMD" >/dev/null 2>&1
    fi ;;
esac
exec "$GITREAL" "\$@"
STUB
chmod +x "$GB/git"

( _fx_cd "$MR" && git checkout -q -b feature && git branch other )

# Re-records the receipt, runs felix merge with one peer action injected, and
# reports the exit code and whether gh was asked to merge anything.
_race() {
  local on="$1" cmd="$2"
  ( cd "$MR" && . "$FROOT/harness/lib/verify.sh"
    felix_verify_record "$MR" "$FROOT" 0 "true" "$(felix_tree_id "$MR" "$FROOT")" )
  _cm_stamp "$MR"
_cm_stamp "$MR"
  : > "$TMP/gh.race.log"; rm -f "$TMP/race.fired"
  ( cd "$MR" && PATH="$GB:$GHB:$PATH" GHSTUB_LOG="$TMP/gh.race.log" \
      RACE_ON="$on" RACE_CMD="$cmd" RACE_FIRED="$TMP/race.fired" \
      "$FELIX" merge --base "$(_mbase "$MR")" >/dev/null 2>&1 )
  RACE_RC=$?
  RACE_MERGES="$(grep -c '^pr merge' "$TMP/gh.race.log" | tr -d ' ')"
}

# 1. A peer checkout landing where the audit found it: after the receipt is
#    accepted, before the branch is read.
_race "remote get-url" "$GITREAL -C $MR checkout -q other"
[ -f "$TMP/race.fired" ] && ok "the injected checkout actually moved the branch" \
                         || bad "the injected checkout actually moved the branch" "it never fired"
is "a checkout that moves after verification merges nothing" "$RACE_MERGES" "0"
[ "$RACE_RC" -ne 0 ] && ok "and says so rather than reporting a merge" \
                     || bad "and says so rather than reporting a merge" "exit $RACE_RC"
( _fx_cd "$MR" && git checkout -q feature )

# 2. Inside felix_merge_blockers, which is the assertion that pins the fix. The
#    first version of this test injected only at `remote get-url` — the tail of
#    the command — so it passed just as well against a version that reads the
#    branch after the blockers and re-reads it at the end, which is the whole
#    of the bug the issue is about. A test that cannot tell the fix from the
#    defect is the failure this repository keeps paying for, and it was found
#    by review rather than by the suite.
_race "diff --name-only" "$GITREAL -C $MR checkout -q other"
[ -f "$TMP/race.fired" ] && ok "a checkout inside the verification is caught too" \
                         || bad "a checkout inside the verification is caught too" "it never fired"
is "and nothing is merged when it lands there" "$RACE_MERGES" "0"
( _fx_cd "$MR" && git checkout -q feature )

# 3. The other two fields. A peer commit moves the sha with the branch name
#    unchanged; a peer edit moves neither and changes only the tree the receipt
#    was accepted for. Both were dead weight until something asserted them.
_race "remote get-url" "$GITREAL -C $MR -c user.name=p -c user.email=p@p commit -q --allow-empty -m peer"
is "a peer commit on the same branch merges nothing" "$RACE_MERGES" "0"
_race "remote get-url" "printf 'peer\n' >> $MR/README.md"
is "a peer edit to the working tree merges nothing" "$RACE_MERGES" "0"
# And it must say which of the three moved. Printing a fixed prefix of the
# record rendered this case as two identical lines under "the checkout moved".
( cd "$MR" && . "$FROOT/harness/lib/verify.sh"
  felix_verify_record "$MR" "$FROOT" 0 "true" "$(felix_tree_id "$MR" "$FROOT")" )
_cm_stamp "$MR"
rm -f "$TMP/race.fired"
race_out="$( cd "$MR" && PATH="$GB:$GHB:$PATH" GHSTUB_LOG=/dev/null \
    RACE_ON="remote get-url" RACE_CMD="printf 'peer2\n' >> $MR/README.md" \
    RACE_FIRED="$TMP/race.fired" "$FELIX" merge --base "$(_mbase "$MR")" 2>&1 )"
has "and names the working tree rather than the checkout" "$race_out" "tree       edited under it"
case "$race_out" in
  *"The checkout moved"*) bad "and does not blame a checkout that did not move" "$race_out" ;;
  *)                      ok  "and does not blame a checkout that did not move" ;;
esac
( _fx_cd "$MR" && git checkout -q -- README.md 2>/dev/null; git checkout -q feature )
unset GHSTUB_LOG

# The same defect with no concurrency in it at all. `felix merge 35` shifted the
# 35 away unread and merged whatever HEAD happened to be on, so a command told
# to merge one thing merged another and reported success. An argument it cannot
# honour must stop it, not be discarded — the rest of this command is
# fail-closed everywhere.
export GHSTUB_LOG="$TMP/gh.arg.log"; : > "$GHSTUB_LOG"
( cd "$MR" && PATH="$GHB:$PATH" "$FELIX" merge 35 >/dev/null 2>&1 )
rc=$?
# A flag whose value is missing, which is the same defect one step along and
# needs no concurrency either. `--base) base="${2:-main}"; shift 2` reads as if
# the missing value were handled — the default is right there — but `shift 2`
# fails when $# is 1 and, having failed, shifts nothing, so the loop never
# advances and the command spins with no output until it is killed. Confirmed
# present on main before this branch, so it is not a regression from the
# argument handling added beside it.
#
# A test for a hang has to bound itself or it becomes the hang.
( cd "$MR" && PATH="$GHB:$PATH" "$FELIX" merge --base >/dev/null 2>&1 ) &
_bp=$!
# Kills the children too. `kill $_bp` reaps the subshell and leaves the felix
# it launched spinning — found the hard way: the first red run of this test left
# a `felix merge --base` burning a core for twenty-four minutes, and it was
# still there when the next gate ran slowly enough to notice. A test for a hang
# that leaks the hang is worse than no test, because it only leaks when it fails.
( sleep 5; pkill -9 -P $_bp 2>/dev/null; kill -9 $_bp 2>/dev/null ) >/dev/null 2>&1 &
_bw=$!
wait $_bp 2>/dev/null; _brc=$?
kill $_bw >/dev/null 2>&1
case "$_brc" in
  137|9) bad "a flag with no value refuses instead of spinning" "still running after 5s" ;;
  0)     bad "a flag with no value refuses instead of spinning" "exit 0, it merged something" ;;
  *)     ok  "a flag with no value refuses instead of spinning" ;;
esac

is "an argument it cannot honour merges nothing" \
   "$(grep -c '^pr merge' "$GHSTUB_LOG" | tr -d ' ')" "0"
[ "$rc" -ne 0 ] && ok "and refuses instead of ignoring it" \
                || bad "and refuses instead of ignoring it" "exit $rc"
unset GHSTUB_LOG

