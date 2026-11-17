# 2026-10-18 (judge refs): felix merge takes a full ref name as its base and
# refuses an expression such as HEAD~1, which git reads in its short-name order.
# The commit before the tip is therefore named by a branch made at it.
_mbase() { _fx_git "$1" update-ref refs/heads/jr-mbase HEAD~1 >/dev/null 2>&1; printf 'refs/heads/jr-mbase'; }
printf '\nthe line that does the work\n'
# `felix merge` was shipped, deployed, written into the handoff as "Felix can
# merge", and could never merge anything. `gh pr merge --repo <slug> --squash`
# carries no PR selector, and gh rejects it client-side with "argument required
# when using the --repo flag" before any network call.
#
# Every existing merge test asserted a refusal or a dry run, so the single line
# that reaches gh was never executed by anything. Green suite, deployed engine,
# dead command. Fourth time this project has paid for "a test can be green
# because it cannot reach the branch it names".
#
# gh is stubbed here rather than called. The point is not that gh works; it is
# that Felix hands it something it will accept, which is exactly the half no
# test covered.
_merge_repo_build

export GHSTUB_LOG="$TMP/gh.log"; : > "$GHSTUB_LOG"
( cd "$MR" && . "$FROOT/harness/lib/verify.sh"
  felix_verify_record "$MR" "$FROOT" 0 "true" "$(felix_tree_id "$MR" "$FROOT")" )
_cm_stamp "$MR"
( cd "$MR" && PATH="$GHB:$PATH" "$FELIX" merge --base "$(_mbase "$MR")" >/dev/null 2>&1 )
mg="$(grep '^pr merge' "$GHSTUB_LOG" | head -1)"
[ -n "$mg" ] && ok "felix merge reaches gh at all" \
             || bad "felix merge reaches gh at all" "gh was never invoked"
# The assertion that would have caught it: a bare argument after `merge` that is
# not the value of a flag. The naive version counted the value of --repo and
# passed against the broken command, which is the same defect one level up.
sel=0; skip=0
for a in $mg; do
  [ "$skip" -eq 1 ] && { skip=0; continue; }
  case "$a" in
    pr|merge) ;;
    --repo|--body|--subject) skip=1 ;;
    --*) ;;
    *) sel=1 ;;
  esac
done
[ "$sel" -eq 1 ] && ok "and hands it a pull request to merge" \
                 || bad "and hands it a pull request to merge" "no selector in [$mg]"
# And the stub reproduces gh's own refusal, so a regression fails loudly here
# rather than only in somebody's terminal.
printf 'pr merge --repo x/y --squash\n' > "$TMP/shape.probe"
( PATH="$GHB:$PATH" GHSTUB_LOG=/dev/null gh pr merge --repo x/y --squash ) 2>/dev/null \
  && bad "the stub refuses a selectorless merge the way gh does" "stub accepted it" \
  || ok "the stub refuses a selectorless merge the way gh does"
unset GHSTUB_LOG

printf '\nthe version that judges is the one main declares\n'
# Issue #28, the engine half, second attempt. The first resolved the judge as
# "the newest thing in the plugin cache" and was vacuous: the gate's `installed`
# check demands the cache match the tree byte for byte before it will go green,
# and merge demands a green receipt, so by merge time the newest cache entry IS
# the candidate. docs/2026-08-14-earned-autonomy-decision.md said so at §4a
# before any of it was written — "one problem seen from two sides".
#
# The judge is instead the version `main` declares. The cache keeps every
# version ever installed, and a branch must bump its own version to deploy at
# all, so main's entry is present and is not the candidate's. The deadlock is
# side-stepped rather than fought: `installed` compares the tree to the newest
# entry while the kernel is an older one, and both hold at once.
KR="$TMP/kres"; mkdir -p "$KR/engine/.claude-plugin"
# -b main explicitly: without it the branch name comes from init.defaultBranch,
# which is the machine and not the fixture. This passed on a laptop that says
# main and failed on a runner that says master.
( _fx_cd "$KR" && git init -q -b main && git config user.email t@t && git config user.name t )
printf '{ "name": "felix", "version": "1.0.0" }\n' > "$KR/engine/.claude-plugin/plugin.json"
mkdir -p "$KR/engine/harness/lib"; printf 'x\n' > "$KR/engine/harness/lib/escape.sh"
( _fx_cd "$KR" && git add -A >/dev/null && git commit -qm base >/dev/null )
KC="$TMP/kcache"; mkdir -p "$KC/1.0.0/harness/lib" "$KC/2.0.0/harness/lib" "$KC/10.0.0/harness/lib"

_kd() { ( . "$FROOT/harness/lib/resolve.sh"
          FELIX_KERNEL_CACHE="$KC" felix_kernel_dir "$KR" ); }
is "the judge is the version main declares" "$(_kd)" "$KC/1.0.0/harness"

# The bump the deploy loop forces is what makes the two differ. After it, the
# tree is 2.0.0 and the judge is still main's 1.0.0 — which is the whole point,
# and is what the first attempt got wrong by taking the newest.
printf '{ "name": "felix", "version": "2.0.0" }\n' > "$KR/engine/.claude-plugin/plugin.json"
is "a bumped tree does not become its own judge" "$(_kd)" "$KC/1.0.0/harness"
case "$(_kd)" in
  *10.0.0*|*2.0.0*) bad "and never the newest thing in the cache" "$(_kd)" ;;
  *)                ok  "and never the newest thing in the cache" ;;
esac

# Absent rather than guessed. Answering with some other version would be the
# first attempt's defect with a different arithmetic.
rm -rf "$KC/1.0.0"
is "a version main declares but nobody installed resolves to nothing" "$(_kd)" ""
mkdir -p "$KC/1.0.0/harness/lib"
KR2="$TMP/kres2"; mkdir -p "$KR2"; ( _fx_cd "$KR2" && git init -q -b main )
is "and a repository with no main resolves to nothing" \
   "$( . "$FROOT/harness/lib/resolve.sh"; FELIX_KERNEL_CACHE="$KC" felix_kernel_dir "$KR2" )" ""

# Only the repository that ships the engine has this problem at all. A governed
# product's rules live in the Felix home and are not in its diff, so there is no
# circularity to break and nothing to demand of it — which is what keeps this
# from becoming a fix for Felix and a regression for everything Felix governs.
_sg() { ( . "$FROOT/harness/lib/resolve.sh"; felix_self_governed "$1" && echo yes || echo no ); }
# The branch name is an argument, not a constant. A project whose trunk is
# called something else must still find its judge.
( _fx_cd "$KR" && git branch -m main trunk )
is "the judge is found on whatever branch is being merged into" \
   "$( . "$FROOT/harness/lib/resolve.sh"; FELIX_KERNEL_CACHE="$KC" felix_kernel_dir "$KR" trunk )" \
   "$KC/1.0.0/harness"
is "and not found by assuming the branch is called main" \
   "$( . "$FROOT/harness/lib/resolve.sh"; FELIX_KERNEL_CACHE="$KC" felix_kernel_dir "$KR" main )" ""
( _fx_cd "$KR" && git branch -m trunk main )

# The collision that shipped. toolbox.sh sets FELIX_PLUGIN_CACHE to the plugins
# cache root and the CLI sources it, so a resolver reading that name looked one
# level too high and found nothing — while every test here passed, because they
# all set the variable themselves. This one deliberately does not set ours.
mkdir -p "$TMP/plugroot/felix/felix/1.0.0/harness/lib"
is "the plugins cache root is composed with, not read as ours" \
   "$( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/toolbox.sh"
       FELIX_PLUGIN_CACHE="$TMP/plugroot" felix_kernel_dir "$KR" main )" \
   "$TMP/plugroot/felix/felix/1.0.0/harness"

is "the repository that ships the engine is self-governed" "$(_sg "$KR")" "yes"
is "and an ordinary product repository is not"             "$(_sg "$MR")" "no"

printf '\nand it is that version that forms the verdict\n'
# A self-governing fixture: a repository that ships an engine, with main
# declaring one version and the branch declaring another, which is the shape the
# deploy loop forces on every engine change.
SG="$TMP/selfgov"; mkdir -p "$SG/engine/.claude-plugin" "$SG/engine/harness/lib"
( _fx_cd "$SG" && git init -q -b main && git config user.email t@t && git config user.name t \
  && git remote add origin https://github.com/example/widget.git )
# Physical path, as $MR already does a few hundred lines up and for the same
# reason. felix_repo_root resolves symlinks, so on macOS a fixture under /tmp
# becomes /private/tmp — and the gate receipt is keyed on a hash of the root, so
# recording under one spelling and reading under the other never matches. That
# is why no assertion here could show a self-governed merge SUCCEEDING: every
# one was refused for a stale receipt, and a refusal looks exactly like the
# feature working.
SG="$( cd "$SG" && pwd -P )"
printf 'widget\n' > "$SG/.felix"
# Main's engine is the real harness, committed as the base, and the cache entry
# for main's version below is a copy of the same: since #260 the boundary
# refuses a judge that is not byte-identical to main's engine at the base ref,
# so a fixture whose main was a one-line stub while its cache held a real
# engine was modelling exactly the doctored cache the boundary now refuses.
cp -R "$FROOT/harness/." "$SG/engine/harness/"
# And it ignores what the real repository ignores, so a log the suite leaves in
# its harness copy is residue to the byte comparison here as it is there (#86).
printf '*.log\n.DS_Store\n' > "$SG/.gitignore"
printf '{ "version": "1.0.0" }\n' > "$SG/engine/.claude-plugin/plugin.json"
( _fx_cd "$SG" && git add -A >/dev/null && git commit -qm base >/dev/null && git checkout -q -b feature )
printf '{ "version": "2.0.0" }\n' > "$SG/engine/.claude-plugin/plugin.json"
printf 'runs something\n' > "$SG/KERNEL2.txt"
# The candidate edits the judge's own source. Without this the diff touches only
# engine/.claude-plugin, which is not self-judgement and no longer trips the
# guard — the correction this fixture exists to exercise.
printf 'candidate edit\n' >> "$SG/engine/harness/lib/escape.sh"
( _fx_cd "$SG" && git add -A >/dev/null && git commit -qm candidate >/dev/null )
printf 'red\tpath\t^KERNEL2\\.txt$\ta channel for the kernel test\texecute\n' \
  >> "$FROOT/projects/widget/risk.tsv"

KC2="$TMP/kcache2"; mkdir -p "$KC2/1.0.0" "$KC2/2.0.0"
cp -R "$FROOT/harness" "$KC2/1.0.0/harness"          # main's version: honest
cp -R "$FROOT/harness" "$KC2/2.0.0/harness"          # the candidate's own
# 2026-10-18 (judge refs, Part C): the entry is compared whole, so it holds main's manifest too.
_kcplug() { mkdir -p "$1/.claude-plugin"; printf '{ "version": "1.0.0" }\n' > "$1/.claude-plugin/plugin.json"; }
_kcplug "$KC2/1.0.0"

_sgmerge() {
  : > "$TMP/gh.sg.log"
  ( cd "$SG" && PATH="$GHB:$PATH" GHSTUB_LOG="$TMP/gh.sg.log" \
      FELIX_KERNEL_CACHE="$KC2" "$FELIX" merge --base "$(_mbase "$SG")" >"$TMP/sg.out" 2>&1 )
  SGRC=$?
  SGMERGES="$(grep -c '^pr merge' "$TMP/gh.sg.log" | tr -d ' ')"
}
_sgrecord() { ( cd "$SG" && . "$FROOT/harness/lib/verify.sh"
                felix_verify_record "$SG" "$FROOT" 0 "true" "$(felix_tree_id "$SG" "$FROOT")" 
                _cm_stamp "$SG" ); }

# The escape is real, so nothing below can pass by finding nothing.
# Asserted on WHICH blocker fired, never on "nothing merged". A merge can fail
# for a stale receipt, and an assertion that only counts merges passes just as
# well when the thing under test did nothing at all — which is how the first
# attempt at this looked green.
_sgrecord; _sgmerge
has "the execute channel stops this merge" "$(cat "$TMP/sg.out")" "execute"
is  "and nothing is merged"                "$SGMERGES" "0"

# The attack: the running engine's escape.sh is taught to find nothing. The
# verdict comes from main's version, which was never taught anything.
cp "$FROOT/harness/lib/escape.sh" "$TMP/esc.orig"
cat > "$FROOT/harness/lib/escape.sh" <<'WEAK'
felix_escapes() { return 0; }
felix_merge_blockers() { return 0; }
felix_merge_checkout() {
  printf '%s\t%s\t%s\n' "$(git -C "$1" rev-parse --abbrev-ref HEAD 2>/dev/null)" \
    "$(git -C "$1" rev-parse HEAD 2>/dev/null)" ""
}
WEAK
_sgrecord; _sgmerge
# The channel must appear in the refusal. The tree's felix_escapes returns
# nothing, so this line can only come from main's copy — a count alone would
# have been satisfied by any unrelated blocker.
has "a disarmed engine is still judged by main's version" "$(cat "$TMP/sg.out")" "execute"
is  "and it merges nothing"                               "$SGMERGES" "0"
cp "$TMP/esc.orig" "$FROOT/harness/lib/escape.sh"

# The vacuous case the first attempt shipped: a judge byte-identical to the tree
# it judges. It must be loud, not silent.
rm -rf "$KC2/1.0.0/harness"; cp -R "$SG/engine/harness" "$KC2/1.0.0/harness"
_sgrecord; _sgmerge
is "a judge identical to the candidate merges nothing" "$SGMERGES" "0"
has "and says why it refused" "$(cat "$TMP/sg.out")" "identical"
rm -rf "$KC2/1.0.0/harness"; cp -R "$FROOT/harness" "$KC2/1.0.0/harness"

# A change that does not touch the engine has no circularity to break, and the
# judge being identical to the tree is not self-judgement — it IS the base
# version, unchanged. The first version of this guard fired on every
# documentation branch and made them unmergeable, which the first real use
# found within a minute of the feature landing.
# main carries a real engine here, not the stub the other scenarios use: the
# judge has to be identical to the tree AND loadable, and a stub that cannot be
# sourced would refuse for the wrong reason and the assertion would pass
# without testing anything.
( _fx_cd "$SG" && git checkout -q main \
  && rm -rf engine/harness && cp -R "$FROOT/harness" engine/harness \
  && git add -A >/dev/null \
  && { git diff --cached --quiet || git -c user.name=t -c user.email=t@t commit -qm engine >/dev/null; } \
  && git checkout -q -b prose \
  && printf 'notes\n' > NOTES.md && git add -A >/dev/null \
  && git -c user.name=t -c user.email=t@t commit -qm prose >/dev/null )
rm -rf "$KC2/1.0.0/harness"; cp -R "$FROOT/harness" "$KC2/1.0.0/harness"
_sgrecord; _sgmerge
# Asserted on the refusal, not on a merge. What changed is whether the
# identical-judge guard fires, and a merge additionally needs a valid receipt —
# which this fixture does not reliably produce, so asserting on it would test
# the fixture rather than the fix.
case "$(cat "$TMP/sg.out")" in
  *"judging itself"*) bad "a change that does not touch the engine is not called self-judgement" "$(cat "$TMP/sg.out")" ;;
  *)           ok  "a change that does not touch the engine is not called self-judgement" ;;
esac
# And it actually merges. Every other assertion in this section is a refusal,
# and a guard that refused everything would satisfy all of them — this is the
# one that fails if the kernel path stops permitting anything at all.
# With the reason, not the count alone: a merge refused for any cause reads
# as zero, and the block's own comment above says why that is vacuous.
if [ "$SGMERGES" = "1" ]; then ok "and a self-governed branch does merge under the kernel"
else bad "and a self-governed branch does merge under the kernel" "merges=$SGMERGES rc=$SGRC: $(cat "$TMP/sg.out")"; fi
( _fx_cd "$SG" && git checkout -q feature && git branch -qD prose )
rm -rf "$KC2/1.0.0/harness"; cp -R "$FROOT/harness" "$KC2/1.0.0/harness"

# And the other half: the same identical judge, with the engine in the diff,
# must still refuse. Without this the pair proves nothing — a guard that never
# fires would satisfy the assertion above.
rm -rf "$KC2/1.0.0/harness"; cp -R "$SG/engine/harness" "$KC2/1.0.0/harness"
_sgrecord; _sgmerge
has "but a change that does touch it still is" "$(cat "$TMP/sg.out")" "identical"
rm -rf "$KC2/1.0.0/harness"; cp -R "$FROOT/harness" "$KC2/1.0.0/harness"

# The kernel is built from engine/harness, but the guard tested `^engine/`. So a
# branch whose only engine change is the version bump — which every deploy
# forces, and which cannot touch engine/harness — was told to bump the version
# and install main's. Advice that had already been followed and could not have
# helped. Found by review the day the guard shipped.
# The kernel is copied AFTER the checkout, or it is not identical to the tree
# and the guard never gets the chance to fire — the assertion below is a
# negative, so it would pass because nothing happened.
( _fx_cd "$SG" && git checkout -q main && git checkout -q -b bumponly \
  && printf '{ "version": "3.0.0" }\n' > engine/.claude-plugin/plugin.json \
  && git add -A >/dev/null && git -c user.name=t -c user.email=t@t commit -qm bump >/dev/null )
rm -rf "$KC2/1.0.0/harness"; cp -R "$SG/engine/harness" "$KC2/1.0.0/harness"
# Proof the fixture is armed: the judge really is byte-identical to the tree, so
# the guard's own precondition holds and only the path predicate decides.
diff -rq "$SG/engine/harness" "$KC2/1.0.0/harness" >/dev/null 2>&1 \
  && ok "the bump fixture has an identical judge, so the guard can fire" \
  || bad "the bump fixture has an identical judge, so the guard can fire" "they differ"
_sgrecord; _sgmerge
case "$(cat "$TMP/sg.out")" in
  *"judging itself"*) bad "a version bump alone is not self-judgement" "$(cat "$TMP/sg.out")" ;;
  *)           ok  "a version bump alone is not self-judgement" ;;
esac
( _fx_cd "$SG" && git checkout -q feature && git branch -qD bumponly )
rm -rf "$KC2/1.0.0/harness"; cp -R "$FROOT/harness" "$KC2/1.0.0/harness"

# review.sh must be in the kernel's source list. escape.sh guards the reviewed
# channel with `command -v felix_review_passed`, so leaving review.sh out does
# not error — it silently stops a reviewer's pass from ever clearing, which is
# the one exception invariant 2 grants. The verdict is RECORDED, through the
# real review.sh, for this tree: since #260 the boundary refuses a judge whose
# review.sh was rewritten, so a stubbed pass would be refused as a doctored
# judge before it could clear anything.
_sgreview() {   # verdict -> a record for the SG tree, as a reviewer would leave it
  ( cd "$SG" && . "$FROOT/harness/lib/resolve.sh" && . "$FROOT/harness/lib/verify.sh" && . "$FROOT/harness/lib/review.sh"
    felix_review_record "$FROOT" "$FROOT/projects/widget" "$(felix_tree_id "$SG" "$FROOT")" "$1" reviewer-1 "through the kernel" ) >/dev/null 2>&1
}
_sgreview pass
# The row is rewritten rather than sed'd onto. BSD sed does not interpret \t, so
# substituting on a tab silently changes nothing, and this assertion would have
# gone on testing the execute channel while claiming to test reviewed.
sed '/KERNEL2/d' "$FROOT/projects/widget/risk.tsv" > "$TMP/rv" \
  && mv "$TMP/rv" "$FROOT/projects/widget/risk.tsv"
printf 'red\tpath\t^KERNEL2\\.txt$\ta channel a verdict may clear\treviewed\n' \
  >> "$FROOT/projects/widget/risk.tsv"
_sgrecord; _sgmerge
case "$(cat "$TMP/sg.out")" in
  *reviewed*) bad "a passing verdict clears a reviewed escape through the kernel" "$(cat "$TMP/sg.out")" ;;
  *)          ok  "a passing verdict clears a reviewed escape through the kernel" ;;
esac
# The other half of the pair: the same tree with a verdict that is not a pass.
# Only `pass` clears, so a reviewer who blocked reads the same as one who
# never ran, and the escape stands.
_sgreview block
_sgrecord; _sgmerge
has "and without it the same escape stands" "$(cat "$TMP/sg.out")" "reviewed"

sed '/KERNEL2/d' "$FROOT/projects/widget/risk.tsv" > "$TMP/rv2" \
  && mv "$TMP/rv2" "$FROOT/projects/widget/risk.tsv"

# And the repository that does not ship an engine is left exactly alone: no
# kernel demanded, no cache consulted, merge as before. This is the assertion
# that keeps a fix for Felix from becoming a regression for every product.
: > "$TMP/gh.prod.log"
( cd "$MR" && . "$FROOT/harness/lib/verify.sh"
  felix_verify_record "$MR" "$FROOT" 0 "true" "$(felix_tree_id "$MR" "$FROOT")" )
_cm_stamp "$MR"
( cd "$MR" && PATH="$GHB:$PATH" GHSTUB_LOG="$TMP/gh.prod.log" \
    FELIX_KERNEL_CACHE="$TMP/no-cache-at-all" "$FELIX" merge --base "$(_mbase "$MR")" >/dev/null 2>&1 )
is "a governed product merges with no installed engine at all" \
   "$(grep -c '^pr merge' "$TMP/gh.prod.log" | tr -d ' ')" "1"


# The judge is pinned outside the tree it judges (#260, amendments §2.3). Three
# ways the pin can fail to hold, each refused on a branch that merges when it
# does hold — so every refusal below is attributable to the one thing changed,
# never to an escape or a stale receipt. FELIX_KERNEL no longer names a judge
# anywhere: a set variable is refused before anything is judged, whatever it
# points at, and it points here at the faithful judge itself. The judge that
# is resolved is then compared byte for byte with the engine main accepted at
# the base, and an entry that differs by so much as a comment is not that
# engine.
#
# The branch is the prose shape from above: off main, one file, no engine in
# the diff, so the identical-judge guard stays out of the picture and the
# merge that closes this section is the same merge the section opened with.
( _fx_cd "$SG" && git checkout -q main && git checkout -q -b pinned \
  && printf 'pinned notes\n' > NOTES.md && git add -A >/dev/null \
  && git -c user.name=t -c user.email=t@t commit -qm pinned >/dev/null )
# review.sh was rewritten above, so the entry is restored before anything
# reads it: a faithful entry is byte-identical to main's engine, and that is
# the precondition every assertion here either relies on or breaks on purpose.
rm -rf "$KC2/1.0.0/harness"; cp -R "$FROOT/harness" "$KC2/1.0.0/harness"

# _sgmerge with the CLI's environment varied: every argument is a VAR=value
# handed to env, so the one difference from _sgmerge is the variable under
# test. A FELIX_KERNEL_CACHE given here overrides the fixture's own.
_sgmerge_under() {
  : > "$TMP/gh.sg.log"
  ( cd "$SG" && PATH="$GHB:$PATH" GHSTUB_LOG="$TMP/gh.sg.log" \
      FELIX_KERNEL_CACHE="$KC2" env "$@" "$FELIX" merge --base "$(_mbase "$SG")" >"$TMP/sg.out" 2>&1 )
  SGRC=$?
  SGMERGES="$(grep -c '^pr merge' "$TMP/gh.sg.log" | tr -d ' ')"
}
# A refusal is an exit AND a reason. Asserted together because either alone
# passes for the wrong thing: a warning that merges anyway carries the text,
# and a merge refused for a stale receipt carries the exit.
_sgrefused() {
  if [ "$SGRC" -ne 0 ]; then has "$1" "$(cat "$TMP/sg.out")" "$2"
  else bad "$1" "exit 0: $(cat "$TMP/sg.out")"; fi
}
# The first line of sg.out holding the text, by number, for the assertions
# about order; empty when the text is absent.
_sgline() { grep -n -F -- "$1" "$TMP/sg.out" | head -1 | cut -d: -f1; }

# (a) A set FELIX_KERNEL is refused whatever it names — here the faithful
# judge itself, so nothing about the value can be what was refused.
_sgrecord; _sgmerge_under FELIX_KERNEL="$KC2/1.0.0/harness"
_sgrefused "felix merge refuses a self-governed repository when FELIX_KERNEL is set" "FELIX_KERNEL is set"
is "and merges nothing under it" "$SGMERGES" "0"

# (b) One comment appended to one file, which no judge would execute any
# differently. Byte for byte means byte for byte.
printf '# one more line than main accepted\n' >> "$KC2/1.0.0/harness/lib/say.sh"
_sgrecord; _sgmerge_under
_sgrefused "a judge that differs from main's engine by one comment is not the engine main accepted" \
           "the judge is not the engine main accepted"
is "and a doctored judge merges nothing" "$SGMERGES" "0"
cp "$FROOT/harness/lib/say.sh" "$KC2/1.0.0/harness/lib/say.sh"

# (c) A cache with nothing in it. Whether the CLI says it cannot tell or that
# nothing is installed at main's version, it must not merge, and it must say
# what it looked for or where it looked.
SGEMPTY="$TMP/kcache-empty"; mkdir -p "$SGEMPTY"
_sgrecord; _sgmerge_under FELIX_KERNEL_CACHE="$SGEMPTY"
[ "$SGRC" -ne 0 ] \
  && ok  "an empty kernel cache leaves the judge unverifiable and the merge refused" \
  || bad "an empty kernel cache leaves the judge unverifiable and the merge refused" "exit 0: $(cat "$TMP/sg.out")"
case "$(cat "$TMP/sg.out")" in
  *1.0.0*|*"$SGEMPTY"*) ok  "and the refusal names the version main declares or the cache it searched" ;;
  *)                    bad "and the refusal names the version main declares or the cache it searched" "$(cat "$TMP/sg.out")" ;;
esac
is "and an empty cache merges nothing" "$SGMERGES" "0"
# "Before judging anything" has one observable: with no judge to be found at
# all, the refusal is still the variable's and not the cache's.
_sgrecord; _sgmerge_under FELIX_KERNEL="$KC2/1.0.0/harness" FELIX_KERNEL_CACHE="$SGEMPTY"
_sgrefused "and FELIX_KERNEL is refused before the cache is even consulted" "FELIX_KERNEL is set"

# (e) The dry run, before the real merge, so that whatever a merge leaves
# behind is not what the dry run is reading.
_sgrecord
: > "$TMP/gh.sg.log"
( cd "$SG" && PATH="$GHB:$PATH" GHSTUB_LOG="$TMP/gh.sg.log" \
    FELIX_KERNEL_CACHE="$KC2" "$FELIX" merge --base "$(_mbase "$SG")" --dry-run >"$TMP/sg.out" 2>&1 )
_sgj="$(_sgline 'judged by ')"; _sgw="$(_sgline 'would squash')"
if [ -n "$_sgj" ] && [ -n "$_sgw" ] && [ "$_sgj" -lt "$_sgw" ]; then
  ok  "a dry run names the judge before saying what it would squash"
else
  bad "a dry run names the judge before saying what it would squash" \
      "judged-by at line [$_sgj], would-squash at line [$_sgw]: $(cat "$TMP/sg.out")"
fi
has "and the dry run says the judge is byte-identical to main" "$(cat "$TMP/sg.out")" "byte-identical to main"

# (f) The incident of 2026-09-19, kept as a fixture, because it cannot be
# staged where it happened: the stray sat in the REAL harness, and a suite
# that writes into the tree it is testing is a worse defect than the one this
# pins. So a checkout is built here that holds what that one held — a
# committed engine, and beside it a directory its .gitignore names, dropped
# after the commit the way the hook dropped it — and two cache entries are
# cut from it: one through _copy_content, one with the `cp -R` every fixture
# used until that day. The second is the control. It must be refused, and
# refused naming the stray, or the first being accepted shows nothing: this
# pair is red on every machine without the copy rule, where the incident
# itself needed one developer's global excludes file to show at all.
INC="$TMP/incident"; mkdir -p "$INC/engine"
cp -R "$FROOT/harness" "$INC/engine/harness"
printf '*.log\n.DS_Store\n.claude-flow/\n' > "$INC/.gitignore"
( _fx_cd "$INC" && git init -q -b main && git add -A >/dev/null \
  && git -c user.name=t -c user.email=t@t commit -qm checkout >/dev/null )
mkdir -p "$INC/engine/harness/.claude-flow/data"
printf '{}\n' > "$INC/engine/harness/.claude-flow/data/pending-insights.jsonl"
is "a stray directory the repository ignores leaves git status clean, so nothing points at it" \
   "$(git -C "$INC" status --porcelain 2>/dev/null | grep -c .)" "0"
KC3="$TMP/kcache3"; KC4="$TMP/kcache4"; mkdir -p "$KC3/1.0.0" "$KC4/1.0.0"
_copy_content "$INC/engine/harness" "$KC3/1.0.0/harness"
cp -R "$INC/engine/harness" "$KC4/1.0.0/harness"
_kcplug "$KC3/1.0.0"; _kcplug "$KC4/1.0.0"
is "the suite's copy of a harness holding one leaves it behind" \
   "$(find "$KC3/1.0.0/harness" -name .claude-flow 2>/dev/null | grep -c .)" "0"
_sgdry() {   # <kernel cache> -> a dry run of the pinned merge, judged from that cache
  : > "$TMP/gh.sg.log"
  ( cd "$SG" && PATH="$GHB:$PATH" GHSTUB_LOG="$TMP/gh.sg.log" \
      FELIX_KERNEL_CACHE="$1" "$FELIX" merge --base "$(_mbase "$SG")" --dry-run >"$TMP/sg.out" 2>&1 )
  SGRC=$?
}
_sgrecord; _sgdry "$KC3"
has "and a cache entry cut from that copy is still the engine main accepted" \
    "$(cat "$TMP/sg.out")" "byte-identical to main"
_sgrecord; _sgdry "$KC4"
_sgrefused "while the raw copy the suite used to take is refused as a judge" \
           "the judge is not the engine main accepted"
has "and the refusal names the stray, which is all the incident ever printed" \
    "$(cat "$TMP/sg.out")" ".claude-flow"

# The rest of the copy's contract, each line of it a way the rule above could
# be kept and the suite still be wrong. Work not yet added to git is under
# test, so untracked-and-not-ignored is carried; the CLI is run from the copy,
# so its bit survives; a tracked file deleted from disk is in git's listing
# and nowhere else, and the copy must still finish and say it succeeded. And
# where git tracks nothing under the source there is no rule to apply and the
# directory is copied whole — asked as "does git track anything here" and
# never as "is this inside a repository", because the plugin cache, where a
# copy of this suite also sits, was inside one, a home directory under version
# control, and an ignore rule there lists an empty harness. The fixture is
# that layout.
printf 'not added yet\n' > "$INC/engine/harness/lib/unadded.sh"
_copy_content "$INC/engine/harness" "$TMP/incident-copy"
[ -f "$TMP/incident-copy/lib/unadded.sh" ] \
  && ok  "work not yet added to git is still carried into the copy" \
  || bad "work not yet added to git is still carried into the copy" "lib/unadded.sh was left behind"
[ -x "$TMP/incident-copy/felix" ] \
  && ok  "and the CLI keeps its executable bit through it" \
  || bad "and the CLI keeps its executable bit through it" "felix is not executable in the copy"
mv "$INC/engine/harness/lib/say.sh" "$TMP/incident-say.aside"
_copy_content "$INC/engine/harness" "$TMP/incident-copy2"; _incrc=$?
if [ "$_incrc" -eq 0 ] && [ -f "$TMP/incident-copy2/felix" ] && [ ! -e "$TMP/incident-copy2/lib/say.sh" ]; then
  ok  "a tracked file missing from disk does not stop the copy"
else
  bad "a tracked file missing from disk does not stop the copy" "rc=$_incrc, felix copied: $([ -f "$TMP/incident-copy2/felix" ] && echo yes || echo no)"
fi
mv "$TMP/incident-say.aside" "$INC/engine/harness/lib/say.sh"
INCH="$TMP/incident-home"; mkdir -p "$INCH/cache/harness/.claude-flow/data"
printf 'a home directory under version control\n' > "$INCH/README"
printf 'cache/\n' > "$INCH/.gitignore"
printf '#!/bin/sh\n' > "$INCH/cache/harness/felix"
printf '{}\n' > "$INCH/cache/harness/.claude-flow/data/pending-insights.jsonl"
( _fx_cd "$INCH" && git init -q -b main && git add -A >/dev/null \
  && git -c user.name=t -c user.email=t@t commit -qm home >/dev/null )
_copy_content "$INCH/cache/harness" "$TMP/incident-cache-copy"
is "a directory git tracks nothing under is copied whole, even inside a repository that ignores it" \
   "$(find "$TMP/incident-cache-copy" -type f 2>/dev/null | grep -c .)" "2"

# (d) The same fixture, untouched, merges — the assertion every refusal above
# borrows its meaning from. The entry named is the version directory main
# declares, the parent of the harness that judged and not the harness itself;
# the pattern admits any spelling of the cache path and no other suffix.
_sgrecord; _sgmerge
is "a faithful cache entry still merges a self-governed branch" "$SGMERGES" "1"
grep -Eq 'judged by [^ ]*/1\.0\.0, the engine main declares, byte-identical to main\.' "$TMP/sg.out" \
  && ok  "and the merge names the entry main declares, not the harness inside it" \
  || bad "and the merge names the entry main declares, not the harness inside it" "$(cat "$TMP/sg.out")"
_sgm="$(_sgline 'merged. nothing in it escaped the tree')"; _sgj="$(_sgline 'judged by ')"
if [ -n "$_sgm" ] && [ -n "$_sgj" ] && [ "$_sgj" -gt "$_sgm" ]; then
  ok  "and names the judge only after the merge is reported"
else
  bad "and names the judge only after the merge is reported" \
      "merged at line [$_sgm], judged-by at line [$_sgj]: $(cat "$TMP/sg.out")"
fi
( _fx_cd "$SG" && git checkout -q feature && git branch -qD pinned )
rm -rf "$KC2/1.0.0/harness"; cp -R "$FROOT/harness" "$KC2/1.0.0/harness"

# And the product that ships no engine is still left alone — now with the one
# variable that refuses a self-governed repository outright set in its
# environment, and no cache to find a judge in.
: > "$TMP/gh.prod.log"
( cd "$MR" && . "$FROOT/harness/lib/verify.sh"
  felix_verify_record "$MR" "$FROOT" 0 "true" "$(felix_tree_id "$MR" "$FROOT")" )
_cm_stamp "$MR"
( cd "$MR" && PATH="$GHB:$PATH" GHSTUB_LOG="$TMP/gh.prod.log" \
    FELIX_KERNEL_CACHE="$TMP/no-cache-at-all" FELIX_KERNEL="$KC2/1.0.0/harness" \
    "$FELIX" merge --base "$(_mbase "$MR")" >/dev/null 2>&1 )
is "a governed product merges with FELIX_KERNEL set and no engine installed" \
   "$(grep -c '^pr merge' "$TMP/gh.prod.log" | tr -d ' ')" "1"
