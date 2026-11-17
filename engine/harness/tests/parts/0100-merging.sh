# 2026-10-18 (judge refs): felix merge takes a full ref name as its base and
# refuses an expression such as HEAD~1, which git reads in its short-name order.
# The commit before the tip is therefore named by a branch made at it.
_mbase() { _fx_git "$1" update-ref refs/heads/jr-mbase HEAD~1 >/dev/null 2>&1; printf 'refs/heads/jr-mbase'; }
printf '\nmerging\n'
_widget_repo_build
# The escape set decides nothing until something consults it. Felix had no way
# to merge at all — the only merge-adjacent code in the engine turned on
# GitHub's auto-merge and then waited for a person — so a rule saying "Felix
# merges what a revert undoes" would have recoloured a label and saved nobody
# anything.
#
# Every blocker is computed before gh is reached. A merge command that discovers
# its own preconditions from the network cannot be tested and cannot refuse
# offline, and refusing offline is the case that matters.
_blk() { ( cd "$REPO" && . "$FROOT/harness/lib/escape.sh"; . "$FROOT/harness/lib/obligations.sh"
           . "$FROOT/harness/lib/evidence.sh"
           . "$FROOT/harness/lib/verify.sh"
           felix_merge_blockers "$FROOT/projects/widget" HEAD~1 "$REPO" "$FROOT" ); }

printf 'plain notes\n' > "$REPO/README.md"; _stage
has "a not-green tree blocks the merge" "$(_blk)" "not-green"

# A malformed probe row reaches the merge boundary as a blocker. cmd_probes
# --gate already refuses one; a boundary that let the same row through would
# be the weaker of two checks on one table, which is the order they must
# never be in.
printf 'halfrow\t-\n' >> "$FROOT/projects/widget/probes.tsv"
has "a probe row naming a predicate and no command blocks the merge" "$(_blk)" "halfrow"
cp "$TMP/probes.keep" "$FROOT/projects/widget/probes.tsv"
is "the widget's probe table is exactly as this section found it" \
   "$(diff -q "$TMP/probes.keep" "$FROOT/projects/widget/probes.tsv" >/dev/null && echo same)" "same"

# A receipt for a different tree is not a green gate, which is the trap cmd_pr
# already learned. Stamp one for the wrong tree and it must still block.
( cd "$REPO" && . "$FROOT/harness/lib/verify.sh"
  felix_verify_record "$REPO" "$FROOT" 0 "gate.sh" "not-this-tree" >/dev/null 2>&1 )
has "a receipt for another tree still blocks" "$(_blk)" "not-green"

( cd "$REPO" && . "$FROOT/harness/lib/verify.sh"
  felix_verify_record "$REPO" "$FROOT" 0 "gate.sh" "$(felix_tree_id "$REPO" "$FROOT")" >/dev/null 2>&1 )
_cm_stamp
is "a green receipt for this exact tree clears every blocker" "$(_blk)" ""

# And a red receipt for the right tree is not a pass either.
( cd "$REPO" && . "$FROOT/harness/lib/verify.sh"
  felix_verify_record "$REPO" "$FROOT" 1 "gate.sh" "$(felix_tree_id "$REPO" "$FROOT")" >/dev/null 2>&1 )
has "a red receipt for this tree blocks" "$(_blk)" "not-green"
( cd "$REPO" && . "$FROOT/harness/lib/verify.sh"
  felix_verify_record "$REPO" "$FROOT" 0 "gate.sh" "$(felix_tree_id "$REPO" "$FROOT")" >/dev/null 2>&1 )
_cm_stamp

# A green receipt says what was checked, and a skipped check is not a check.
#
# `felix gate --quick` skips the test suite and still exits 0, so the receipt
# it stamps was byte-identical to a full run's: one bit, green. Everything
# downstream then spoke as if the suite had passed — the Stop hook said so in
# those words. The gate already prints which checks it skipped; the receipt now
# carries them, so a reader can tell a full verification from a partial one.
#
# What this cannot say: a gate that skips something silently is still invisible.
# The receipt records what the gate REPORTED as skipped, and no absence of skip
# lines proves nothing was skipped. That limit is stated where it is claimed.
( cd "$REPO" && . "$FROOT/harness/lib/verify.sh"
  felix_verify_record "$REPO" "$FROOT" 0 "gate.sh" "$(felix_tree_id "$REPO" "$FROOT")" "tests,installed" >/dev/null 2>&1 )
_rcpt="$( . "$FROOT/harness/lib/verify.sh"; felix_verify_receipt "$REPO" "$FROOT" )"
is "the receipt records which checks the gate skipped" "$(printf '%s' "$_rcpt" | cut -f5)" "tests,installed"
is "and a run that skipped nothing says so, rather than leaving it blank" \
   "$( ( cd "$REPO" && . "$FROOT/harness/lib/verify.sh"
         felix_verify_record "$REPO" "$FROOT" 0 "gate.sh" "$(felix_tree_id "$REPO" "$FROOT")" "" >/dev/null 2>&1 )
       . "$FROOT/harness/lib/verify.sh"; felix_verify_receipt "$REPO" "$FROOT" | cut -f5 )" "-"
# A sixth field: every check the gate reported, with the verdict it printed.
# The gate's output was a temporary file the command threw away, so the only
# roster of what the gate checks was one typed into a handoff by hand — and a
# typed roster is wrong the day a checker is added. felix qualify reads this
# to say which reported checks no row qualifies.
( cd "$REPO" && . "$FROOT/harness/lib/verify.sh"
  felix_verify_record "$REPO" "$FROOT" 0 "gate.sh" "$(felix_tree_id "$REPO" "$FROOT")" "tests" "syntax:ok,tests:skipped,secret:ok" >/dev/null 2>&1 )
_rcpt="$( . "$FROOT/harness/lib/verify.sh"; felix_verify_receipt "$REPO" "$FROOT" )"
is "the receipt records every check the gate reported, with its verdict" \
   "$(printf '%s' "$_rcpt" | cut -f6)" "syntax:ok,tests:skipped,secret:ok"
is "and the skip list is still where it was" "$(printf '%s' "$_rcpt" | cut -f5)" "tests"
is "and a receipt written without a roster says so rather than leaving it blank" \
   "$( ( cd "$REPO" && . "$FROOT/harness/lib/verify.sh"
         felix_verify_record "$REPO" "$FROOT" 0 "gate.sh" "$(felix_tree_id "$REPO" "$FROOT")" "" "" >/dev/null 2>&1 )
       . "$FROOT/harness/lib/verify.sh"; felix_verify_receipt "$REPO" "$FROOT" | cut -f6 )" "-"
# The four readers all take fields 1-3 positionally, so a fifth field must not
# disturb any of them. Asserted rather than assumed: a `read -r a b c d` would
# have absorbed it, and that is the shape that broke felix profile.
( cd "$REPO" && . "$FROOT/harness/lib/verify.sh"
  felix_verify_record "$REPO" "$FROOT" 0 "gate.sh" "$(felix_tree_id "$REPO" "$FROOT")" "tests" >/dev/null 2>&1 )
_cm_stamp
is "a receipt carrying a skip list still clears every blocker" "$(_blk)" ""

# And cmd_gate reads the skips off the gate's own report rather than off its
# own flags: a project gate that skips for its own reasons is recorded too.
_skipfx="$(printf '  syntax             ok\n  tests              skipped (--quick)\n  installed          skipped (no plugin installed here)\n  secret             ok\n')"
is "the extractor names every skipped check and nothing else" \
   "$(printf '%s\n' "$_skipfx" | awk '$2 == "skipped" { printf "%s%s", sep, $1; sep = "," }')" "tests,installed"
# And the roster the same way: names the gate printed, with what it printed
# beside them, never names anybody listed. Four verdict words: the gate's own
# first real run printed `commission stale`, which a three-word extractor
# dropped — a checker that ran and reported, absent from the roster.
_rosterfx="$(printf 'gate: /tmp/x\n      main @ abc1234\n%s\n    Files a and b differ\n                     1817 passed, 0 failed\n  commission         stale (table set moved; run felix commission)\n  probes             FAIL\n' "$_skipfx")"
is "the roster extractor names every reported check with its verdict, in order" \
   "$(printf '%s\n' "$_rosterfx" | awk '$0 ~ /^  [a-z][a-z-]* +[A-Za-z]/ { printf "%s%s:%s", sep, $1, $2; sep = "," }')" \
   "syntax:ok,tests:skipped,installed:skipped,secret:ok,commission:stale,probes:FAIL"
# And the lib reads the same shape back, so a checker the gate reported under
# any verdict word is a gap when no row qualifies it.
is "felix_qualify_ungoverned keeps every reported checker and drops every sub-line" \
   "$( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/qualify.sh"
       felix_qualify_ungoverned "$TMP/no-such-proj" "$_rosterfx" | tr '\n' ' ')" \
   "commission installed probes secret syntax tests "

( cd "$REPO" && . "$FROOT/harness/lib/verify.sh"
  felix_verify_record "$REPO" "$FROOT" 0 "gate.sh" "$(felix_tree_id "$REPO" "$FROOT")" >/dev/null 2>&1 )
_cm_stamp

# An escape outranks a green gate. This is the whole point: the gate says the
# code works, and says nothing about whether merging writes outside the tree.
mkdir -p "$REPO/.github/workflows"; printf 'on: push\n' > "$REPO/.github/workflows/x.yml"; _stage
( cd "$REPO" && . "$FROOT/harness/lib/verify.sh"
  felix_verify_record "$REPO" "$FROOT" 0 "gate.sh" "$(felix_tree_id "$REPO" "$FROOT")" >/dev/null 2>&1 )
_cm_stamp
has "a green gate does not clear an escape" "$(_blk)" "execute"

# #56, at the level that acts. The same branch, the same workflow, the same
# green receipt — merged against a base git cannot name. This is the shown-
# failing case the issue requires: today it prints "nothing in it escaped the
# tree" and merges.
_blk_at() { ( cd "$REPO" && . "$FROOT/harness/lib/escape.sh"; . "$FROOT/harness/lib/obligations.sh"
              . "$FROOT/harness/lib/evidence.sh"
              . "$FROOT/harness/lib/verify.sh"
              felix_merge_blockers "$FROOT/projects/widget" "$1" "$REPO" "$FROOT" ); }
has "an execute path against an unresolvable base blocks the merge" \
    "$(_blk_at no-such-ref)" "unknown"
# And it blocks as `unknown`, not as `escape`. The distinction is not cosmetic:
# cmd_merge counts escapes as founder escalations — the declared objective is
# interruptions per session — and tells the reader that merging writes outside
# the tree and only they can decide. A base nobody can resolve is neither. It is
# a typo, or a default branch that is not `main`, and correcting it is Felix's
# own work.
case "$(_blk_at no-such-ref)" in
  escape*) bad "and not as an escape, which would escalate a typo to the founder" \
               "$(_blk_at no-such-ref)" ;;
  *)       ok  "and not as an escape, which would escalate a typo to the founder" ;;
esac
_reset

# An evidence gap is not a stop. It is work Felix owes, and handing it back as
# a decision is the defect the charter names.
cp "$FROOT/projects/widget/evidence.tsv" "$TMP/ev.keep" 2>/dev/null || : > "$TMP/ev.keep"
printf 'unit\t^src/\t^tests?/\tcode changes need a test\n' > "$FROOT/projects/widget/evidence.tsv"
mkdir -p "$REPO/src"; printf 'x = 1\n' > "$REPO/src/thing.py"; _stage
( cd "$REPO" && . "$FROOT/harness/lib/verify.sh"
  felix_verify_record "$REPO" "$FROOT" 0 "gate.sh" "$(felix_tree_id "$REPO" "$FROOT")" >/dev/null 2>&1 )
_cm_stamp
has "an untested change blocks, naming the evidence owed" "$(_blk)" "evidence"
has "and says which rule"                                 "$(_blk)" "unit"
_reset
cp "$TMP/ev.keep" "$FROOT/projects/widget/evidence.tsv"

# The command itself must refuse without reaching the network. gh is not called,
# so this assertion holds on a runner with no credentials and no remote.
mkdir -p "$REPO/migrations"; printf 'x\n' > "$REPO/migrations/900.sql"; _stage
out="$( cd "$REPO" && "$FELIX" merge --base "$(_mbase "$REPO")" 2>&1 )"; rc=$?
is  "felix merge refuses on an escape"  "$rc" "3"
has "and names the channel"             "$out" "durable"
has "and says what would have to change" "$out" "founder"
_reset

printf 'ordinary\n' > "$REPO/README.md"; _stage
( cd "$REPO" && . "$FROOT/harness/lib/verify.sh"
  felix_verify_record "$REPO" "$FROOT" 0 "gate.sh" "$(felix_tree_id "$REPO" "$FROOT")" >/dev/null 2>&1 )
_cm_stamp
out="$( cd "$REPO" && "$FELIX" merge --base "$(_mbase "$REPO")" --dry-run 2>&1 )"; rc=$?
is  "and reports a clear merge without performing one" "$rc" "0"
has "saying so plainly"                                "$out" "nothing escapes"
_reset

# A stale commission receipt is not work Felix owes. Observed 2026-09-23 in
# the worktree for #306, gate and CI green: #298 had added rows to risk.tsv, a
# commissioning table, so the receipt was stale, and `felix merge --dry-run`
# closed with "none of it is a founder decision. It is work Felix owes: run
# the gate". A session told the work was its own re-ran a gate that had
# passed, or read it as licence to commission. What clears the receipt is a
# commission run, which is the founder's (§0aq, §0bl), and who makes it turns
# on the commission grant, which the receipt never reads: a grant stamped over
# tables that have since moved runs nothing until the founder re-arms it, a
# current one runs at the next session start, and with none the run is
# simply theirs. Felix never writes a project's autonomy file.
#
# The real case first, through the real libraries: a grant and a receipt
# stamped over the same tables, then a commissioning table moves under both,
# the gate is recorded over the moved tables, and the receipt is not
# re-stamped, so it is the one blocker left.
_mlacks() { case "$2" in *"$3"*) bad "$1" "$2" ;; *) ok "$1" ;; esac; }
_mgrant() { ( . "$FROOT/harness/lib/commission.sh"; . "$FROOT/harness/lib/autonomy.sh"
              felix_autonomy_commission_current "$FROOT/projects/widget" && echo current || echo stale ); }
printf 'ordinary\n' > "$REPO/README.md"; _stage
cp "$FROOT/projects/widget/risk.tsv" "$TMP/risk.cm.keep"
_cm_stamp
( cd "$REPO" && "$FELIX" autonomy --allow commission >/dev/null 2>&1 )
is  "the widget's commission grant covers the tables before one moves" "$(_mgrant)" "current"
printf '# a row added under the commission receipt\n' >> "$FROOT/projects/widget/risk.tsv"
( cd "$REPO" && . "$FROOT/harness/lib/verify.sh"
  felix_verify_record "$REPO" "$FROOT" 0 "gate.sh" "$(felix_tree_id "$REPO" "$FROOT")" >/dev/null 2>&1 )
is  "and once it has, the grant no longer covers them"                 "$(_mgrant)" "stale"
is  "a table moved under the commission receipt is the branch's only blocker" \
    "$(_blk | cut -f1,2)" "commission	receipt"
out="$( cd "$REPO" && "$FELIX" merge --base "$(_mbase "$REPO")" --dry-run 2>&1 )"; rc=$?
is  "felix merge refuses on a stale commission receipt alone" "$rc" "3"
has "and says the merge waits for the founder"                "$out" "waits for the founder"
is  "naming the grant they re-arm, on a line of its own" \
    "$(printf '%s\n' "$out" | grep -cx '  felix autonomy --allow commission')" "1"
is  "and the commission run after it" \
    "$(printf '%s\n' "$out" | grep -A1 -x '  felix autonomy --allow commission' | tail -1)" "  felix commission"
_mlacks "and does not call it work Felix owes"                "$out" "work Felix owes"
_mlacks "nor say that none of it is a founder decision"       "$out" "none of it is a founder decision"

# Beside a blocker that is Felix's, each is said about its own: the commission
# is still the founder's, and the red gate is still Felix's to run again.
( cd "$REPO" && . "$FROOT/harness/lib/verify.sh"
  felix_verify_record "$REPO" "$FROOT" 1 "gate.sh" "$(felix_tree_id "$REPO" "$FROOT")" >/dev/null 2>&1 )
out="$( cd "$REPO" && "$FELIX" merge --base "$(_mbase "$REPO")" --dry-run 2>&1 )"
has "a red gate beside the stale receipt is listed too"             "$out" "not-green"
has "and the commission is still named as the founder's"            "$out" "waits for the founder"
has "while the red gate is handed back as work Felix owes"          "$out" "work Felix owes"
_mlacks "without claiming that none of it is a founder decision"    "$out" "none of it is a founder decision"

# Re-armed over the moved tables, the grant is current and the receipt still
# is not: the next session start re-commissions, so re-arming is not asked for
# again, and it is still not a session's to do by hand.
( cd "$REPO" && "$FELIX" autonomy --allow commission >/dev/null 2>&1 )
( cd "$REPO" && . "$FROOT/harness/lib/verify.sh"
  felix_verify_record "$REPO" "$FROOT" 0 "gate.sh" "$(felix_tree_id "$REPO" "$FROOT")" >/dev/null 2>&1 )
is  "a grant re-armed over the moved tables is current, and the receipt still the one blocker" \
    "$(_mgrant) $(_blk | cut -f1,2)" "current commission	receipt"
out="$( cd "$REPO" && "$FELIX" merge --base "$(_mbase "$REPO")" --dry-run 2>&1 )"
has "under a current grant it says the next session start re-commissions" \
    "$out" "next session started in this"
_mlacks "and asks for no re-arm the grant does not need"            "$out" "felix autonomy --allow commission"
_mlacks "and is still not work Felix owes"                          "$out" "work Felix owes"

# With no grant the run is the founder's alone, and naming the grant would be
# asking for a standing consent to unattended runs that this merge does not
# need: felix commission by hand clears the receipt without one.
( cd "$REPO" && "$FELIX" autonomy --revoke commission >/dev/null 2>&1 )
out="$( cd "$REPO" && "$FELIX" merge --base "$(_mbase "$REPO")" --dry-run 2>&1 )"
has "with no grant the merge still waits for the founder"           "$out" "waits for the founder"
is  "naming the commission run on a line of its own" \
    "$(printf '%s\n' "$out" | grep -cx '  felix commission')" "1"
_mlacks "and asks for no grant the merge does not need"             "$out" "felix autonomy --allow commission"
_mlacks "and is not work Felix owes either"                         "$out" "work Felix owes"
rm -f "$FROOT/projects/widget/autonomy" "$FROOT/projects/widget/autonomy.commission"
cp "$TMP/risk.cm.keep" "$FROOT/projects/widget/risk.tsv"
_reset
is "the widget's risk table is exactly as this section found it, and it has no grant" \
   "$(diff -q "$TMP/risk.cm.keep" "$FROOT/projects/widget/risk.tsv" >/dev/null && echo same) $(ls "$FROOT/projects/widget" | grep -c '^autonomy')" \
   "same 0"

# Then every kind, one at a time, through the CLI with the library's blockers
# replaced by exactly that line, so the assertion is on what cmd_merge says
# for the kind and not on whether this fixture can be made to raise it. The
# kinds are read out of escape.sh first: cmd_merge files anything it does not
# name under work Felix owes, so a kind or a commission subject added there
# without a place here would land in that paragraph unannounced. The boundary is
# felix_merge_blockers, the body it calls once P is read, and the policy blockers
# lib/policy.sh prints for it (trust-plane step 3).
_mbody() { sed -n '/^felix_merge_blockers()/,/^}/p; /^_felix_merge_blockers_at()/,/^}/p' "$FROOT/harness/lib/escape.sh"
           grep "printf 'policy" "$FROOT/harness/lib/policy.sh"; }
_mkinds="$(_mbody \
             | grep -o "printf '[a-z-]*\\\\t" | sed "s/printf '//; s/\\\\t\$//" | LC_ALL=C sort -u | tr '\n' ' ')"
is "felix_merge_blockers emits exactly the kinds cmd_merge places" \
   "$_mkinds" "commission escape evidence not-green obligations policy probes unknown "
_mcsubj="$(_mbody \
             | grep -o "printf 'commission\\\\t[a-z]*" | sed "s/.*\\\\t//" | LC_ALL=C sort -u | tr '\n' ' ')"
is "and commission blockers carry exactly the subjects cmd_merge places" "$_mcsubj" "engine receipt table "

cp "$FROOT/harness/lib/escape.sh" "$TMP/esc.keep"
printf 'felix_merge_blockers() { cat "%s"; }\n' "$TMP/mblk.tsv" >> "$FROOT/harness/lib/escape.sh"
_mclose() { printf "$1" > "$TMP/mblk.tsv"; ( cd "$REPO" && "$FELIX" merge --base "$(_mbase "$REPO")" --dry-run 2>&1 ); }
printf 'ordinary\n' > "$REPO/README.md"; _stage

for _mk in 'not-green\ttree\tno green receipt for this exact tree; run felix gate' \
           'evidence\tunit\tcode changes need a test' \
           'probes\tmarker\tempty: nothing read' \
           'obligations\tfixture\tRELEASE_BLOCKING deterministic: not discharged' \
           'commission\tengine\tthe commissioning library is not loaded, so nothing was asked of this project'; do
  _mn="$(printf "$_mk" | cut -f1-2 | tr '\t' ' ')"
  out="$(_mclose "$_mk\n")"
  has "the $_mn blocker is work Felix owes"                    "$out" "work Felix owes"
  _mlacks "and the $_mn blocker names no commission run"       "$out" "The commission is not"
done

out="$(_mclose 'commission\treceipt\tnever commissioned on this machine\n')"
has "a missing commission receipt waits for the founder"          "$out" "waits for the founder"
_mlacks "and is not work Felix owes"                               "$out" "work Felix owes"
out="$(_mclose 'commission\ttable\tthis project was never commissioned; write projects/widget/commissioning.tsv (felix commission says how)\n')"
has "a commission table blocker waits for the founder too"        "$out" "waits for the founder"
has "and says the table is put right before the commission runs" "$out" "table named above right first"
_mlacks "and is not called work Felix owes"                        "$out" "work Felix owes"
out="$(_mclose 'unknown\tno-such-ref\tthe base names nothing this repository holds\n')"
has "an unknown base still says nothing was compared"             "$out" "Nothing was compared"
_mlacks "and names no commission run"                              "$out" "The commission is not"
out="$(_mclose 'policy\ttable\tprojects/widget is not at refs/remotes/origin/main, so no authorized policy judges this\n')"
has "a policy blocker says no authorized policy judged the branch" "$out" "No authorized version of this project"
_mlacks "and the policy blocker is not called work Felix owes"     "$out" "work Felix owes"
_mlacks "and the policy blocker names no commission run"            "$out" "The commission is not"
out="$(_mclose 'escape\texecute\t.github/workflows/x.yml: runs on push\ncommission\treceipt\tstale (table set moved; run felix commission)\n')"
has "an escape beside a stale receipt is still the founder's decision" "$out" "it is the founder who decides"
is  "and the commission run is named with it, so one visit clears both" \
    "$(printf '%s\n' "$out" | grep -cx '  felix commission')" "1"
_mlacks "and neither is work Felix owes"                                "$out" "work Felix owes"

cp "$TMP/esc.keep" "$FROOT/harness/lib/escape.sh"
_reset
is "the fixture's escape.sh is exactly the engine's again" \
   "$(diff -q "$REAL_HARNESS/lib/escape.sh" "$FROOT/harness/lib/escape.sh" >/dev/null && echo same)" "same"

printf '\na surface no test can judge\n'
# Some changes are revert-complete, touch no store and reach no stranger, and
# still must not merge unread: a rubric that teaches the wrong thing breaks
# nothing a gate can see. another governed project's constitution already answers this — T2
# wants "an independent reviewer running in an isolated worktree at the reviewed
# commit" — and nothing implemented it, so the row sat red and stopped nothing.
#
# The verdict is a receipt keyed on the tree, exactly like the gate's, because
# the trap is the same one: a verdict for a different tree is not a verdict.
RVH="$TMP/reviewhome"; RVP="$RVH/projects/widget"; mkdir -p "$RVP" "$MEM/widget"
cp "$TMP/risk.keep" "$RVP/risk.tsv" 2>/dev/null || : > "$RVP/risk.tsv"
printf 'red\tpath\t^content/\ta doctrine surface; no test can judge it\treviewed\t-\n' >> "$RVP/risk.tsv"
_resc() { ( cd "$REPO" && . "$FROOT/harness/lib/verify.sh"; . "$FROOT/harness/lib/review.sh"
            . "$FROOT/harness/lib/escape.sh"; . "$FROOT/harness/lib/obligations.sh"
            felix_escapes "$RVP" HEAD~1 "$REPO" "$RVH" ); }

mkdir -p "$REPO/content"; printf 'teach this\n' > "$REPO/content/rubric.md"; _stage
has "a doctrine surface with no verdict escapes" "$(_resc)" "reviewed"

# A verdict for some other tree must not clear it.
( . "$FROOT/harness/lib/verify.sh"; . "$FROOT/harness/lib/review.sh"
  felix_review_record "$RVH" "$RVP" "some-other-tree" pass reviewer-1 "looked fine" )
has "a verdict for another tree does not clear it" "$(_resc)" "reviewed"

TID="$( . "$FROOT/harness/lib/verify.sh"; felix_tree_id "$REPO" "$RVH" )"
( . "$FROOT/harness/lib/verify.sh"; . "$FROOT/harness/lib/review.sh"
  felix_review_record "$RVH" "$RVP" "$TID" block reviewer-1 "the rubric contradicts the map" )
has "a blocking verdict does not clear it either" "$(_resc)" "reviewed"

# The control for #57 item 2, and the reason it is placed HERE rather than after
# the fix: a verdict exists for this exact tree and it granted nothing, because
# it blocks. `granted_by` must still be "none". Without this, replacing one
# constant with a different constant would pass the assertion below it.
_rgrant() { ( cd "$REPO" && . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/detect.sh"
              . "$FROOT/harness/lib/verify.sh"; . "$FROOT/harness/lib/review.sh"
              . "$FROOT/harness/lib/escape.sh"; . "$FROOT/harness/lib/obligations.sh"; . "$FROOT/harness/lib/classify.sh"
              . "$FROOT/harness/lib/evidence.sh"; . "$FROOT/harness/lib/receipt.sh"
              felix_receipt "$RVP" HEAD~1 "$REPO" "$RVH" ) \
            | sed -n 's/.*"granted_by": "\([^"]*\)".*/\1/p'; }
is "a verdict that granted nothing names nothing" "$(_rgrant)" "none"

( . "$FROOT/harness/lib/verify.sh"; . "$FROOT/harness/lib/review.sh"
  felix_review_record "$RVH" "$RVP" "$TID" pass reviewer-1 "ran it against real content" )
is "a passing verdict for this exact tree clears it" "$(_resc)" ""

# #57, confirmed item 2. The receipt's `granted_by` was the string literal
# "none", printed unconditionally at lib/receipt.sh:192, and the only assertion
# on it compared that literal to "none" — a constant checked against itself.
#
# Meanwhile the `reviewed` channel genuinely grants authority, and it is the one
# place in Felix where a model's output widens permission rather than narrowing
# it (constitution invariant 2, the exception added 2026-08-12). A receipt that
# reached `autonomous: true` because a verdict cleared a red doctrine surface was
# byte-identical to one where nothing was granted. The only field in the wire
# contract that exists to name the provenance of authority could never name any.
is "the receipt names what granted the authority" "$(_rgrant)" "reviewed"

# Independence cannot be checked. Isolation half can, and it is the half that
# has actually gone wrong: a reviewer running pytest against the live tree while
# somebody keeps editing reports false failures, which the governed project's
# own lessons record as a real incident. So a pass claiming it ran in the tree
# under review is refused as a recording, not merely doubted.
( . "$FROOT/harness/lib/verify.sh"; . "$FROOT/harness/lib/review.sh"
  felix_review_record "$RVH" "$RVP" "$TID" pass reviewer-1 "ran here" "$REPO" "$REPO" ) 2>/dev/null
rc=$?
is "a pass claiming it ran in the reviewed tree is refused" "$rc" "1"
has "and the earlier verdict is not replaced by it" \
    "$( . "$FROOT/harness/lib/review.sh"; felix_review_verdict "$RVH" "$RVP" "$TID" )" "ran it against real content"

( . "$FROOT/harness/lib/verify.sh"; . "$FROOT/harness/lib/review.sh"
  felix_review_record "$RVH" "$RVP" "$TID" pass reviewer-2 "ran elsewhere" "$TMP/some-other-worktree" "$REPO" )
has "a pass from a separate worktree records the place it ran" \
    "$( . "$FROOT/harness/lib/review.sh"; felix_review_verdict "$RVH" "$RVP" "$TID" )" "some-other-worktree"

# A block is never refused for where it ran. A reviewer reporting a problem from
# the wrong place is still reporting a problem, and discarding it would make the
# isolation check a way to lose bad news.
( . "$FROOT/harness/lib/verify.sh"; . "$FROOT/harness/lib/review.sh"
  felix_review_record "$RVH" "$RVP" "$TID" block reviewer-3 "found a contradiction" "$REPO" "$REPO" )
rc=$?
is "a block from the live tree is still recorded" "$rc" "0"
( . "$FROOT/harness/lib/verify.sh"; . "$FROOT/harness/lib/review.sh"
  felix_review_record "$RVH" "$RVP" "$TID" pass reviewer-2 "ran elsewhere" "$TMP/some-other-worktree" "$REPO" )

# The boundary that makes this safe to have at all. A reviewer verdict clears
# the one channel with no mechanical test behind it and nothing else, so no
# review can release a secret, run CI, or move a store.
mkdir -p "$REPO/migrations"; printf 'x\n' > "$REPO/migrations/970.sql"; _stage
( . "$FROOT/harness/lib/verify.sh"; . "$FROOT/harness/lib/review.sh"
  felix_review_record "$RVH" "$RVP" \
    "$( . "$FROOT/harness/lib/verify.sh"; felix_tree_id "$REPO" "$RVH" )" pass reviewer-1 "fine" )
out="$(_resc)"
has "a verdict never clears a durable escape" "$out" "durable"
case "$out" in
  *reviewed*) bad "and the reviewed one is cleared by it" "$out" ;;
  *)          ok  "and the reviewed one is cleared by it" ;;
esac
_reset; _reset

printf '\nthe one number Felix is trying to move\n'
# Declared 2026-08-12: founder interruptions per session. You cannot optimise an
# unnamed objective, and Felix had none — so every improvement was argued rather
# than measured. Gate pass rate was rejected as the target because a gate you
# keep loosening passes more, which makes the metric move the wrong way for the
# worst possible reason.
#
# An interruption is a moment Felix needed a decision it could not make. It has
# to be recorded where it happens; counting it later from a transcript is the
# parsing approach this project already rejected twice.
mkdir -p "$REPO/migrations"; printf 'x\n' > "$REPO/migrations/950.sql"; _stage
before="$(grep -c '	escalated	' "$MEM/widget/says.log" 2>/dev/null || echo 0)"
( cd "$REPO" && "$FELIX" merge --base "$(_mbase "$REPO")" >/dev/null 2>&1 )
after="$(grep -c '	escalated	' "$MEM/widget/says.log" 2>/dev/null || echo 0)"
[ "$after" -gt "$before" ] \
  && ok "a merge stopped for the founder is recorded as one" \
  || bad "a merge stopped for the founder is recorded as one" "says.log did not grow"
has "and the record names the channel" \
    "$(grep '	escalated	' "$MEM/widget/says.log" | tail -1)" "durable"
_reset

# A blocker Felix can clear itself is not an interruption. Counting an unrun
# gate as founder time would make the number improve by running the gate less.
printf 'notes\n' > "$REPO/README.md"; _stage
before="$(grep -c '	escalated	' "$MEM/widget/says.log" 2>/dev/null || echo 0)"
( cd "$REPO" && "$FELIX" merge --base "$(_mbase "$REPO")" >/dev/null 2>&1 )
after="$(grep -c '	escalated	' "$MEM/widget/says.log" 2>/dev/null || echo 0)"
is "a not-green tree is Felix's work, not an interruption" "$after" "$before"
_reset


# The instrument scan (lib/policy.sh, spec S2.1, trust-plane step 3) over a table of commands: what
# it lists (a ?word is one the rewrite could not place, and refuses when P holds it) and the command
# it rewrites. Not blind: the blind cases are parts 2176-2177. It is here so CI's awk runs it too.
_sw=$'tools/check-fx\ntools/run.sh\ntools/marker.txt\nengine/harness/bin/x'
_sc=( 'engine/harness/bin/x engine/harness/templates engine/hooks/hooks.json' 'bash tools/run.sh' '. tools/run.sh; f'
      'if tools/check-fx; then tools/run.sh; fi' 'X="a b" tools/check-fx' '( cd sub && tools/check-fx )'
      'tools/check-fx && case "$f" in a|tools/run.sh) exit 0;; esac' $'tools/check-fx <<E\ntools/run.sh\nE'
      'bash -n tools/run.sh' 'bash -e run.sh' '"tools/check-fx"' 'tools/check\-fx' '{ tools/check-fx; }'
      'diff <(tools/check-fx) x' 'x=$(tools/check-fx); [ -n "$x" ]' 'tools/check-fx; v=$(tools/check-fx)'
      'x=`tools/check-fx`' 'nice tools/check-fx' "sh -c 'tools/check-fx'" 'case x in a) tools/check-fx;; esac'
      'f() { "$@"; }; f bash tools/check-fx' 'cat tools/check-fx | bash' 'x=$(cat tools/run.sh | sh)'
      "printf '%s\\n' p | xargs -I{} grep -qxF {} tools/marker.txt"
      'n="$(git ls-files tools | grep -cE "^(tools/run.sh|tools/check-fx)$")"; [ "$n" = 2 ]'
      'a=(tools/run.sh tools/check-fx); [ ${#a[@]} = 2 ]' '[[ -e tools/run.sh && tools/check-fx -nt x ]]'
      'v="$(git show "HEAD:tools/check-fx" | head -1)"; [ -n "$v" ]' $'true # tools/check-fx\n:'
      "sh -c 'ls Dockerfile* */Dockerfile* 2>/dev/null | grep -q .'" 'grep -q x tools/marker.txt'
      '/bin/bash tools/run.sh' 'nice bash run.sh' 'cat run.sh | bash -e' '"bash" tools/run.sh' './run.sh x' 'bash "tools/check-fx"' 'python3.12 tools/run.sh' )
_sl=( 'engine/harness/bin/x' 'tools/run.sh' 'tools/run.sh' 'tools/check-fx tools/run.sh' 'tools/check-fx' 'tools/check-fx'
      'tools/check-fx' 'tools/check-fx ?tools/run.sh' '?tools/run.sh ?bash ?n' '?run.sh ?bash ?e' '?tools/check-fx' '?tools/check-fx'
      '?tools/check-fx' '?tools/check-fx' '?tools/check-fx' 'tools/check-fx ?tools/check-fx' '?tools/check-fx'
      '?tools/check-fx' '?tools/check-fx' '?tools/check-fx' '?tools/check-fx' '?cat ?tools/check-fx ?bash'
      '?x ?cat ?tools/run.sh ?sh'
      '?tools/marker.txt' '' '' '' '' '' '' '' 'tools/run.sh' '?run.sh' '?cat ?run.sh ?bash ?e' '?tools/run.sh' 'run.sh' '?tools/check-fx' 'tools/run.sh' )
_sbad="$( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/policy.sh"; _k=0
  while [ "$_k" -lt "${#_sc[@]}" ]; do
    _c="${_sc[$_k]}"; _l="$(_felix_p_scan list "$_c" | paste -sd' ' -)"
    [ "$_l" = "${_sl[$_k]}" ] || printf '%s: lists [%s], not [%s]; ' "$_c" "$_l" "${_sl[$_k]}"
    _k=$((_k+1))
  done )"
is "the instrument scan lists, for each of ${#_sc[@]} commands, the words the rewrite takes from P and each it cannot place" "$_sbad" ""
_srw="$( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/policy.sh"
  _felix_p_scan rewrite 'X="a b" tools/check-fx && bash tools/run.sh; { tools/check-fx; }' "$_sw" /P )"
is "and rewrites a placed word to P's copy, leaving everything from a stop on as the table holds it" \
   "$_srw" "X=\"a b\" '/P/tools/check-fx' && bash '/P/tools/run.sh'; { tools/check-fx; }"
