# Every value a verdict is computed from takes its status from its own
# assignment. One read is not enough if the held count, the total, the rows
# run, the checkers, a checker's controls or the checkers never shown failing
# come out of a pipeline whose status nobody reads. So awk, tr, cut and sort
# are each wrapped to fail their Nth call with exit 2 without running, for
# every N a clean run makes, over three tables.
#
# One has a met violation and a held restoration and nothing else wrong, so
# every right answer refuses. The held control expects pass: a command field
# that came back empty, as a field cut by a fork that failed once did, ran
# `eval ""`, passed, and met it.
#
# One has a met restoration and demo's only fail control, whose premise is
# absent here, so demo is never shown failing and every right answer refuses.
# The list of checkers never shown failing, failing, came back empty, and read
# as every checker shown.
#
# One has a single met control. It may exit 0 only with the output a clean run
# gives, word for word, and that output shows the control met and demo's
# shortfall naming the five controls it lacks: a list of its controls that
# failed to empty named all six missing, violation too, and a list of the
# checkers, or of what one lacks, that failed to empty said no shortfall at
# all, and each passed. Exiting non-zero once its report has begun, it says
# what could not be read or worked out; a fault before that, in finding which
# project governs the checkout, stops felix with a refusal of its own.
#
# Two checks no fault here can reach are kept as defence in depth, not pinned
# by a test invented for them. The split of felix qualify's one read into rows
# and malformed rows refuses a line tagged neither way, but that read is one awk
# that tags every line it prints or fails whole. And --gate wanting at least
# one verdict repeats what the refusals of no selected row and of fewer
# verdicts than rows already make true.
_widget_repo_build
_QFSHIM="$TMP/fault-shim"; _QFC="$TMP/fault-shim.count"
for _qfc in awk tr cut sort; do
  mkdir -p "$_QFSHIM/$_qfc"
  cat > "$_QFSHIM/$_qfc/$_qfc" <<EOF
#!/bin/sh
printf x >> "\$QFAULT_COUNT"
[ "\$((\$(wc -c < "\$QFAULT_COUNT")))" -eq "\${QFAULT_AT:-0}" ] && exit 2
exec "$(command -v "$_qfc")" "\$@"
EOF
  chmod +x "$_QFSHIM/$_qfc/$_qfc"
done
# _qfsweep PRED COMMAND...: for each COMMAND, felix qualify --gate with its
# Nth call failing, for N from 1 to the calls a clean run makes. Prints
# "COMMAND N: what PRED said" for each wrong result, and a line for a command
# a clean run never called, since then nothing was faulted.
_qfsweep() {
  local pred="$1" c n k said; shift
  for c in "$@"; do
    : > "$_QFC"
    ( cd "$REPO" && PATH="$_QFSHIM/$c:$PATH" QFAULT_COUNT="$_QFC" QFAULT_AT=0 "$FELIX" qualify --gate ) >/dev/null 2>&1
    n=$(( $(wc -c < "$_QFC") ))
    [ "$n" -ge 1 ] || { printf 'a clean run called %s no times, so nothing was faulted\n' "$c"; continue; }
    k=1
    while [ "$k" -le "$n" ]; do
      : > "$_QFC"
      _qsout="$(cd "$REPO" && PATH="$_QFSHIM/$c:$PATH" QFAULT_COUNT="$_QFC" QFAULT_AT="$k" "$FELIX" qualify --gate 2>&1)"; _qsrc=$?
      said="$("$pred")"; [ -z "$said" ] || printf '%s %s of %s: %s\n' "$c" "$k" "$n" "$said"
      k=$((k + 1))
    done
  done
}
_qfheld() { [ "$_qsrc" != 0 ] || printf 'exit 0'; }
_qfshort='  demo declares no control for: restoration irrelevant alternate decoupled_violation decoupled_satisfaction'
_qfclean() {
  if [ "$_qsrc" = 0 ]; then
    [ "$_qsout" = "$_qfok" ] || printf 'exit 0 with output a clean run does not give; '
    [ "$(printf '%s\n' "$_qsout" | grep -cE '^  demo +violation +fail +fail +ok$')" = 1 ] \
      || printf 'exit 0 without showing the one control met; '
    [ "$(printf '%s\n' "$_qsout" | grep -cxF "$_qfshort")" = 1 ] \
      || printf "exit 0 without demo's shortfall of the five controls it lacks; "
  else
    case "$_qsout" in
      "qualification for "*)
        [ "$(printf '%s\n' "$_qsout" | grep -cE 'could not be (read|worked out)')" -ge 1 ] \
          || printf 'exit %s saying nothing of what could not be read or worked out; ' "$_qsrc" ;;
    esac
  fi
}
{ printf 'demo\t%s\tviolation\tfail\tprintf FORBIDDEN > bad.txt\n' "$_qcheck"
  printf 'demo\tfalse\trestoration\tpass\ttrue\n'; } > "$_qlw"
is  "whichever awk, tr, cut or sort call felix qualify --gate makes fails, a run over a held control never exits 0" \
    "$(_qfsweep _qfheld awk tr cut sort)" ""
{ printf 'demo\t%s\tviolation\tfail\tprintf FORBIDDEN > bad.txt\tfalse\n' "$_qcheck"
  printf 'demo\t%s\trestoration\tpass\ttrue\n' "$_qcheck"; } > "$_qlw"
is  "and a run whose one checker is never shown failing here never exits 0 either" \
    "$(_qfsweep _qfheld awk tr cut sort)" ""
printf 'demo\t%s\tviolation\tfail\tprintf FORBIDDEN > bad.txt\n' "$_qcheck" > "$_qlw"
_qfok="$(cd "$REPO" && "$FELIX" qualify --gate 2>&1)"
is  "and a run over a met control exits 0 only with a clean run's output, its shortfall included, and otherwise says what could not be read or worked out" \
    "$(_qfsweep _qfclean awk tr cut sort)" ""
rm -f "$FROOT/projects/widget/qualification.tsv"
[ -f "$TMP/qual.keep" ] && mv "$TMP/qual.keep" "$FROOT/projects/widget/qualification.tsv"
is "and the widget project is as this block found it" \
   "$([ -f "$FROOT/projects/widget/qualification.tsv" ] && echo present || echo absent)" "absent"

printf '\nthe receipt carries the epoch, and a fact that moved outside the tree stales it\n'
# A gate receipt was keyed on the tree id alone, and the tree id covers every
# byte git can see and nothing else. A probe that counts an ignored file, a
# probe that reads $HOME, a table in the Felix home for a governed product:
# each can move without the tree id moving, and every reader took the old
# green as current. The receipt now records the decision epoch it was stamped
# under (fields 7 and 8), and one reader — felix_verify_current — says whether
# that epoch still holds, with the reason when it does not.
#
# Authored blind to the implementation, from the behaviour in prose. Two
# fixture choices carry the whole block. The project directory sits in the
# Felix home, outside the repository, so a table can move where the tree id
# cannot see it. And the one probe counts a file the repository IGNORES, so the
# grounded facts can move where the tree id cannot see them either. Beside
# every such movement the tree id is asserted unchanged, so no stale verdict
# here can be the old tree check firing under a new name.
ERP="$FROOT/projects/epochrcpt"; mkdir -p "$ERP" "$MEM/epochrcpt"
cat > "$ERP/project.json" <<'EOF'
{
  "name": "epochrcpt",
  "remote_match": "example.com/epochrcpt",
  "gate": "true"
}
EOF
# The probe exits 0 with nothing found, so the row reads `empty` with the
# witness agreeing and `found` once a member exists — two known states, never
# blind, so the topology hashes a fact either way and moves between them.
_er_probes() {
  { printf '# predicate\tgrounds\twhen\tprobe\twitness\n'
    printf 'tmpfiles\t-\t-\tfind . -maxdepth 1 -name "*.tmp"\ttest -e .git\n'
  } > "$ERP/probes.tsv"
}
# A second table in the policy set that is neither the subject nor the probes,
# so the table set can move with nothing else moving. $1 is an extra row.
_er_evidence() {
  { printf 'unit\t^src/\t^tests?/\tcode changes need a test\n'
    [ -n "${1:-}" ] && printf '%s\n' "$1"
  } > "$ERP/evidence.tsv"
}
# And the admitted obligation every merge fixture carries, so the merge
# boundary below is measuring the receipt and not the empty ledger.
printf 'fixture\tRELEASE_BLOCKING\tdeterministic\t-\ttrue\t-\ta fixture owes one thing, and it holds\n' \
  > "$ERP/obligations.tsv"
_er_probes; _er_evidence

# Two commits, so the merge boundary has a base to diff against; `*.tmp`
# ignored and committed, so the file the probe counts is invisible to git.
ERR="$TMP/epochrcpt-repo"; mkdir -p "$ERR"
( _fx_cd "$ERR" && git init -q -b main
  printf 'epochrcpt\n' > .felix
  printf '*.tmp\n'     > .gitignore
  printf 'code\n'      > code.txt
  git add -A >/dev/null 2>&1
  git -c user.name=t -c user.email=t@t commit -qm base >/dev/null 2>&1
  printf 'notes\n'     > README.md
  git add -A >/dev/null 2>&1
  git -c user.name=t -c user.email=t@t commit -qm notes >/dev/null 2>&1 ) >/dev/null 2>&1
ERR="$(cd "$ERR" && pwd -P)"

# The sourcing shape the reader is specified under: resolve, verify, probes,
# epoch; epoch.sh brings commission.sh and everything that carries.
_er_lib()   { . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/verify.sh"
              . "$FROOT/harness/lib/probes.sh";  . "$FROOT/harness/lib/epoch.sh"; }
_er_tid()   { ( cd "$ERR" && _er_lib; felix_tree_id "$ERR" "$FROOT" ); }
_er_epoch() { ( cd "$ERR" && _er_lib; felix_epoch "${1:-$ERP}" "$ERR" ); }
_er_comps() { ( cd "$ERR" && _er_lib
                felix_epoch_components "${1:-$ERP}" "$ERR" | cut -f2 | paste -sd, - ); }
# $1 the gate's exit status; $2 and $3 the epoch and the comma-joined
# components, computed now unless given (`-` is given verbatim). Nine
# positional arguments: the seven the writer already took, then these two.
_er_rec() { ( cd "$ERR" && _er_lib
              felix_verify_record "$ERR" "$FROOT" "$1" "gate.sh" "$(felix_tree_id "$ERR" "$FROOT")" "" "" \
                "${2:-$(felix_epoch "$ERP" "$ERR")}" \
                "${3:-$(felix_epoch_components "$ERP" "$ERR" | cut -f2 | paste -sd, -)}" \
                >/dev/null 2>&1 ); }
# The writer called the way every caller before this section called it: seven
# arguments, no epoch. This is the receipt an older engine leaves behind.
_er_rec_old() { ( cd "$ERR" && _er_lib
                  felix_verify_record "$ERR" "$FROOT" 0 "gate.sh" "$(felix_tree_id "$ERR" "$FROOT")" "" "" \
                    >/dev/null 2>&1 ); }
_er_rcpt() { ( _er_lib; felix_verify_receipt "$ERR" "$FROOT" ); }
_er_cur()  { ( cd "$ERR" && _er_lib; felix_verify_current "$ERR" "$FROOT" "${1:-$ERP}" ) 2>/dev/null; }

# ------------------------------------------------------------ the writer ------
out="$(_er_cur)"; rc=$?
is "a root nothing has stamped reads as none" "$out" "none"
[ "$rc" -ne 0 ] && ok  "and none is not a passing answer" \
                || bad "and none is not a passing answer" "exited 0 on a root with no receipt"

er_tid0="$(_er_tid)"; er_epoch0="$(_er_epoch)"; er_comps0="$(_er_comps)"
is "the fixture has an epoch before anything is stamped" "$(printf '%s' "$er_epoch0" | grep -c .)" "1"
_er_rec 0
er_line="$(_er_rcpt)"
is "a receipt written with an epoch reads back with eight fields" \
   "$(printf '%s\n' "$er_line" | awk -F'\t' '{ print NF }')" "8"
is "and field 1 is still the tree id"   "$(printf '%s' "$er_line" | cut -f1)" "$er_tid0"
is "and field 2 is still the verdict"   "$(printf '%s' "$er_line" | cut -f2)" "green"
is "and field 4 is still the gate"      "$(printf '%s' "$er_line" | cut -f4)" "gate.sh"
is "and fields 5 and 6 still say nothing skipped and no roster, as dashes" \
   "$(printf '%s' "$er_line" | cut -f5,6 | tr '\t' ' ')" "- -"
is "field 7 is the epoch the receipt was stamped under" "$(printf '%s' "$er_line" | cut -f7)" "$er_epoch0"
is "field 8 is the four components, comma-joined in the order the spec lists them" \
   "$(printf '%s' "$er_line" | cut -f8)" "$er_comps0"
is "and that field holds four members" \
   "$(printf '%s' "$er_line" | cut -f8 | tr ',' '\n' | grep -c .)" "4"

# ------------------------------------------------------------ the reader ------
out="$(_er_cur)"; rc=$?
is "a green receipt for this tree under this epoch is current" "$out" "current"
is "and current returns 0"                                      "$rc"  "0"
is "and the reader prints exactly one line"                     "$(_er_cur | grep -c .)" "1"

# The fact that moves is a file the repository ignores. Both halves are
# asserted: the tree id did not move, and the epoch did. Without the first,
# the stale verdict could be the tree check firing; without the second, the
# verdict could be right for a reason the fixture never produced.
: > "$ERR/a.tmp"
is "an ignored file the probe counts leaves the tree id where it was" "$(_er_tid)" "$er_tid0"
[ "$(_er_epoch)" != "$er_epoch0" ] \
  && ok  "and moves the epoch, because the probe counts it" \
  || bad "and moves the epoch, because the probe counts it" "the epoch is still $er_epoch0"
out="$(_er_cur)"; rc=$?
is  "so the receipt is stale with the tree unchanged"          "$(printf '%s' "$out" | cut -f1)" "stale"
has "and the reason is that the grounded facts moved"           "$(printf '%s' "$out" | cut -f2)" "the grounded facts moved"
[ "$rc" -ne 0 ] && ok  "and stale returns non-zero" \
                || bad "and stale returns non-zero" "exited 0 while stale"
is  "and stale is one line as well"                             "$(_er_cur | grep -c .)" "1"

# A tree that changed is the first thing said, whatever else moved: the
# receipt is about a tree that no longer exists, and a moved fact beside it
# is a detail about a verdict that already does not apply.
printf 'edited\n' >> "$ERR/code.txt"
out="$(_er_cur)"
has "a tree that changed is named before a fact that moved" "$out" "the tree changed"
case "$out" in
  *"the grounded facts moved"*) bad "and the moved fact is not what it blames" "$out" ;;
  *)                            ok  "and the moved fact is not what it blames" ;;
esac
( _fx_cd "$ERR" && git checkout -q -- code.txt )
is "and with the edit undone the tree id is back" "$(_er_tid)" "$er_tid0"

# Topology before policy, when both moved.
_er_evidence 'docs	^docs/	^docs/	a second rule'
has "with a fact and a table both moved, the fact is named first" "$(_er_cur)" "the grounded facts moved"
rm -f "$ERR/a.tmp"
# The topology component alone is back — the table is still edited, so the
# epoch as a whole is not, and that is the point of the next assertion.
is  "the topology is back once the ignored file is gone" \
    "$(_er_comps | cut -d, -f2)" "$(printf '%s' "$er_comps0" | cut -d, -f2)"
out="$(_er_cur)"
has "a table edited in the project directory stales the receipt because the table set moved" \
    "$out" "the table set moved"
is  "and that is stale, reason in the second field"   "$(printf '%s' "$out" | cut -f1)" "stale"
is  "while the tree id never saw the table"           "$(_er_tid)" "$er_tid0"
_er_evidence
is  "and putting the table back makes the same receipt current again" "$(_er_cur)" "current"

# The subject is the project's name and remote, and project.json is a member
# of the table set too — so the one way to move the subject alone is to move
# the directory. The receipt is keyed on the root, so it is still the receipt
# under the new name; what changed is who the root is said to belong to.
mv "$ERP" "$ERP.moved"
has "the same receipt read for a renamed project is stale because the subject moved" \
    "$(_er_cur "$ERP.moved")" "the subject moved"
mv "$ERP.moved" "$ERP"
is  "and under its own name it is current" "$(_er_cur)" "current"

# The release target, moved by the environment the reader runs under.
has "a receipt read under a different release target is stale for that reason" \
    "$( ( export FELIX_RELEASE_TARGET=release-9; _er_cur ) )" "the release target moved"
is  "and with the target back the receipt is current" "$(_er_cur)" "current"

# A receipt that carries no epoch cannot be compared with anything, and is
# never current: the old engine's receipts, and a gate that could not read
# the facts when it stamped, both land here.
_er_rec 0 - -
is  "a dash in the seventh field is written as a dash" "$(_er_rcpt | cut -f7)" "-"
out="$(_er_cur)"; rc=$?
is  "and a receipt with a dash for an epoch is stale"  "$(printf '%s' "$out" | cut -f1)" "stale"
has "because it carries no epoch"                       "$out" "carries no epoch"
[ "$rc" -ne 0 ] && ok  "and a receipt with no epoch never returns 0" \
                || bad "and a receipt with no epoch never returns 0" "exited 0"
# No epoch outranks a fact that moved: there is nothing to compare the moved
# fact against, so the moved fact is not what is wrong.
: > "$ERR/a.tmp"
has "and with a fact moved as well, no epoch is still the reason given" "$(_er_cur)" "carries no epoch"
rm -f "$ERR/a.tmp"
# The tree changing outranks even that.
printf 'edited\n' >> "$ERR/code.txt"
has "a tree that changed is named before a receipt with no epoch" "$(_er_cur)" "the tree changed"
( _fx_cd "$ERR" && git checkout -q -- code.txt )
# The receipt the writer leaves when called the way every earlier caller
# calls it, with no eighth and ninth argument at all. The blind author of
# this block expected it to carry no epoch and read stale; the writer went
# the stricter way instead — it computes the epoch from the checkout's own
# binding, so a caller that forgot the arguments cannot leave a receipt that
# rests on nothing. Only a checkout with no binding gets `-`, and that one
# reads stale.
_er_rec_old
is  "a receipt written without the two epoch arguments still has eight fields" \
    "$(_er_rcpt | awk -F'\t' '{ print NF }')" "8"
case "$(_er_rcpt | cut -f7)" in
  -|"") bad "and carries the epoch of the checkout's binding, not a dash" "$(_er_rcpt | cut -f7)" ;;
  *)    ok  "and carries the epoch of the checkout's binding, not a dash" ;;
esac
is  "and reads current, because it rests on the same facts a gate would have recorded" "$(_er_cur | cut -f1)" "current"
ERN="$TMP/epochrcpt-nomark"; mkdir -p "$ERN"
( _fx_cd "$ERN" && git init -q -b main && printf 'x\n' > x && git add -A \
  && git -c user.name=t -c user.email=t@t commit -qm x ) >/dev/null 2>&1
ERN="$(cd "$ERN" && pwd -P)"
( cd "$ERN" && _er_lib; felix_verify_record "$ERN" "$FROOT" 0 "gate.sh" "$(felix_tree_id "$ERN" "$FROOT")" "" "" >/dev/null 2>&1 )
is  "a checkout with no binding gets a dash for its epoch" \
    "$( _er_lib; felix_verify_receipt "$ERN" "$FROOT" | cut -f7 )" "-"
has "and that receipt reads stale, never current" \
    "$( cd "$ERN" && _er_lib; felix_verify_current "$ERN" "$FROOT" "$ERP" 2>/dev/null )" "carries no epoch"

# A receipt that has an epoch, read at a moment the epoch cannot be
# recomputed: the probe table has gone since. Not `the grounded facts moved`,
# because nothing can say whether they did; the honest answer is that the
# receipt cannot be read now.
_er_rec 0
is "the control: with the probe table in place the receipt is current" "$(_er_cur)" "current"
rm -f "$ERP/probes.tsv"
out="$(_er_epoch)"; rc=$?
is "with the probe table gone the epoch cannot be computed" "${#out}" "0"
out="$(_er_cur)"; rc=$?
has "so the receipt cannot be read now"                "$out" "cannot be read now"
is  "and cannot-be-read-now is stale, not current"     "$(printf '%s' "$out" | cut -f1)" "stale"
[ "$rc" -ne 0 ] && ok  "and an epoch that cannot be read returns non-zero" \
                || bad "and an epoch that cannot be read returns non-zero" "exited 0 with the facts unreadable"
case "$out" in
  *"the grounded facts moved"*|*"the table set moved"*)
    bad "and does not claim to know which way the facts went" "$out" ;;
  *) ok  "and does not claim to know which way the facts went" ;;
esac
# A dash on the receipt is named before facts that cannot be read now.
_er_rec 0 - -
has "a receipt with no epoch is said to have none before the facts are said to be unreadable" \
    "$(_er_cur)" "carries no epoch"
_er_probes
_er_rec 0
is "and with the table back a fresh receipt is current" "$(_er_cur)" "current"

# A red receipt is red, whatever the epoch did.
_er_rec 1
out="$(_er_cur)"; rc=$?
is "a red receipt reads as red" "$out" "red"
[ "$rc" -ne 0 ] && ok  "and red returns non-zero" \
                || bad "and red returns non-zero" "exited 0 on a red receipt"
: > "$ERR/a.tmp"
is "and red is named before any fact that moved" "$(_er_cur)" "red"
rm -f "$ERR/a.tmp"
_er_rec 0

# ---------------------------------------------------------- the Stop hook ------
# Driven the way the completion-gate section drives it: real JSON on stdin, a
# real repository, FELIX_HOME pinned to the fixture. The dirt is an untracked
# file, which the tree id covers, so it is made BEFORE the receipt is stamped;
# the ignored file, which the tree id does not cover, after.
_er_stop()    { ( cd "$ERR" && printf '%s' '{"hook_event_name":"Stop","stop_hook_active":false}' \
                  | "$FROOT/harness/hooks/stop" 2>&1 ); }
_er_blocked() { case "$1" in *'"decision"'*'"block"'*) return 0 ;; *) return 1 ;; esac; }
printf 'session work\n' > "$ERR/dirt.txt"
[ "$(_er_tid)" != "$er_tid0" ] \
  && ok  "an untracked file is in the tree id, so the session's dirt is seen" \
  || bad "an untracked file is in the tree id, so the session's dirt is seen" "the tree id did not move"
_er_rec 0
out="$(_er_stop)"
_er_blocked "$out" \
  && bad "a dirty tree with a green receipt under the current epoch may stop" "$out" \
  || ok  "a dirty tree with a green receipt under the current epoch may stop"
er_tid1="$(_er_tid)"
: > "$ERR/a.tmp"
is "the ignored file leaves the tree id the receipt was stamped for" "$(_er_tid)" "$er_tid1"
out="$(_er_stop)"
_er_blocked "$out" \
  && ok  "but once the grounded facts move under that receipt, the hook blocks" \
  || bad "but once the grounded facts move under that receipt, the hook blocks" "expected a block, got [$out]"
has "and tells the session which fact moved" "$out" "the grounded facts moved"
rm -f "$ERR/a.tmp"
out="$(_er_stop)"
_er_blocked "$out" \
  && bad "and with the fact back where it was, the same receipt allows again" "$out" \
  || ok  "and with the fact back where it was, the same receipt allows again"
rm -f "$ERR/dirt.txt"

# ------------------------------------------------------ the merge boundary ------
# felix_merge_blockers sourced the way the obligation and probe sections
# source it, plus the epoch library the reader is specified beside. Only the
# `not-green` line is read: the fixture project has commissioned nothing, and
# whatever else the boundary says about that is not what this measures.
_er_blk() { ( cd "$ERR" && . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/detect.sh"
              . "$FROOT/harness/lib/verify.sh";  . "$FROOT/harness/lib/evidence.sh"
              . "$FROOT/harness/lib/escape.sh";  . "$FROOT/harness/lib/obligations.sh"
              . "$FROOT/harness/lib/probes.sh";  . "$FROOT/harness/lib/facts.sh"
              . "$FROOT/harness/lib/epoch.sh"
              felix_merge_blockers "$ERP" HEAD~1 "$ERR" "$FROOT" ) 2>/dev/null \
            | awk -F'\t' '$1 == "not-green"'; }
_er_rec 0
is "a current receipt raises no not-green line at the merge boundary" "$(_er_blk)" ""
: > "$ERR/a.tmp"
is  "the tree id is still the one the receipt names" "$(_er_tid)" "$er_tid0"
out="$(_er_blk)"
is  "a fact that moved under the receipt raises exactly one" "$(printf '%s\n' "$out" | grep -c .)" "1"
has "with the reason in its third field" "$(printf '%s\n' "$out" | cut -f3)" "the grounded facts moved"
rm -f "$ERR/a.tmp"
is  "and it is gone again once the fact is back" "$(_er_blk)" ""

rm -rf "$ERP" "$ERP.moved"

