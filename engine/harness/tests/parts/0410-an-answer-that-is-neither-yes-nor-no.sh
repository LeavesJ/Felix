printf '\nan answer that is neither yes nor no\n'
_oblig_build
# Three columns ask a command a yes/no question from the repo root: an
# obligation's `applies`, a probe row's `when`, and its `witness`. Each read
# every non-zero exit but 126/127 as "no" — so an ask that CRASHED (grep on a
# bad regex exits 2, git in a directory that is not there exits 128) retired a
# blocking obligation to DORMANT, switched a probe row off as not-applicable,
# or let "nothing found" render as a clean `empty`. #236 closed the same hole
# for qualification premises. The contract now, for all three: 0 is yes, 1 is
# the ONLY no, and anything else is neither, says so with the code, and blocks.
# Fresh fixture dirs: the obligation fixture above hardwires OBP/OBR and the
# blocks after it depend on their state.
ASKP="$TMP/askproj"; ASKQ="$TMP/askprobes"; ASKC="$TMP/askcheck"; ASKN="$TMP/askcheck-none"
ASKR="$TMP/askrepo"
mkdir -p "$ASKP" "$ASKQ" "$ASKC" "$ASKN" "$ASKR" "$MEM/askproj" "$MEM/askprobes" "$MEM/askcheck"
( _fx_cd "$ASKR" && git init -q -b main && printf 'x\n' > x && git add -A \
  && git -c user.name=t -c user.email=t@t commit -qm x ) >/dev/null 2>&1
ASKR="$(cd "$ASKR" && pwd -P)"
printf 'thing\t-\t-\tls -1 x\ttest -f x\n' > "$ASKP/probes.tsv"
_ask()    { ( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/probes.sh"
              . "$FROOT/harness/lib/obligations.sh"; "$@" ) 2>/dev/null; }
_askrun() { _ask felix_obligations_run "$ASKP" "$ASKR"; }
_askblk() { ( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/detect.sh"
              . "$FROOT/harness/lib/verify.sh"; . "$FROOT/harness/lib/evidence.sh"
              . "$FROOT/harness/lib/escape.sh"; . "$FROOT/harness/lib/probes.sh"
              . "$FROOT/harness/lib/facts.sh"; . "$FROOT/harness/lib/obligations.sh"
              felix_merge_blockers "$ASKP" "" "$ASKR" "$FROOT" ) 2>/dev/null | grep '^obligations'; }
# The detail must carry the phrase and the code it saw, in either order.
_asksays() { case "$2" in *"neither yes nor no"*) case "$2" in *"exited $3"*) ok "$1"; return ;; esac ;; esac
             bad "$1" "[$2] lacks [neither yes nor no] with [exited $3]"; }

# The obligation. `applies` crashes with 2; the evidence would leave a mark.
printf 'a\tRELEASE_BLOCKING\tdeterministic\tsh -c "exit 2"\ttouch ran2\tthing\t?\n' > "$ASKP/obligations.tsv"
is  "an applies command that exits 2 is UNKNOWN on both axes, not DORMANT" \
    "$(_askrun | cut -f4,5)" "UNKNOWN	UNKNOWN"
_asksays "and says the answer was neither yes nor no, naming the code" "$(_askrun)" 2
[ ! -f "$ASKR/ran2" ] && ok  "and its evidence is never run behind an applicability nobody established" \
                      || bad "and its evidence is never run behind an applicability nobody established" \
                             "the evidence ran on a row whose applies exited 2"
has "and the row blocks a release rather than vanishing" "$(_askblk)" "obligations	a	UNKNOWN UNKNOWN"
# 128 is git's own crash code and the one seen in the wild. It is not a second
# kind of no, and the code reported is the one that happened, not 2 by habit.
printf 'a\tRELEASE_BLOCKING\tdeterministic\tgit -C /nonexistent rev-parse --git-dir\ttouch ran128\tthing\t?\n' > "$ASKP/obligations.tsv"
is  "an applies command that exits 128 is UNKNOWN too, not a second kind of no" \
    "$(_askrun | cut -f4,5)" "UNKNOWN	UNKNOWN"
_asksays "carrying the code that happened" "$(_askrun)" 128
# And 1 is still the one honest no.
printf 'a\tRELEASE_BLOCKING\tdeterministic\tsh -c "exit 1"\ttouch ran1\tthing\t?\n' > "$ASKP/obligations.tsv"
is  "an applies command that exits 1 is the one honest no: DORMANT" "$(_askrun | cut -f4)" "DORMANT"

# The probe row. Its `when` and its `witness` are asks of the same shape.
{ printf '# predicate\tgrounds\twhen\tprobe\twitness\n'
  # when crashes: the row is neither on nor off, and the probe must not run.
  printf 'whencrash\t-\tsh -c "exit 2"\ttouch probed-whencrash; ls -1 x\ttest -f x\n'
  # when says no: off, silently, as before.
  printf 'whenno\t-\tsh -c "exit 1"\tls -1 x\ttest -f x\n'
  # nothing came back and the witness crashed: nobody said the surface is absent.
  printf 'witcrash\t-\t-\tgit ls-files "*.rs"\tsh -c "exit 2"\n'
  # nothing came back and the witness said no: empty, as before.
  printf 'witno\t-\t-\tgit ls-files "*.rs"\tsh -c "exit 1"\n'
  # the probe itself failed AND the witness crashed: still nobody knows.
  printf 'witcrashfail\t-\t-\tsh -c "exit 3"\tsh -c "exit 2"\n'
} > "$ASKQ/probes.tsv"
_askq()      { ( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/detect.sh"
                 . "$FROOT/harness/lib/probes.sh"; . "$FROOT/harness/lib/facts.sh"; . "$FROOT/harness/lib/obligations.sh"
                 felix_probes_run "$ASKQ" "$ASKR" ); }
_askqstate() { _askq | awk -F'\t' -v p="$1" '$1 == p { print $3 }'; }
_askqrow()   { _askq | awk -F'\t' -v p="$1" '$1 == p'; }
_askqblk()   { ( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/detect.sh"
                 . "$FROOT/harness/lib/probes.sh"; . "$FROOT/harness/lib/facts.sh"; . "$FROOT/harness/lib/obligations.sh"
                 felix_probes_run "$ASKQ" "$ASKR" | felix_probes_blocking | cut -f1 | LC_ALL=C sort | tr '\n' ' ' ); }

is  "a when test that exits 2 makes the row unknown, not not-applicable" "$(_askqstate whencrash)" "unknown"
_asksays "and the row says the when test was neither yes nor no, with its code" "$(_askqrow whencrash)" 2
[ ! -f "$ASKR/probed-whencrash" ] && ok  "and the probe is never run behind a when test nobody could answer" \
                                  || bad "and the probe is never run behind a when test nobody could answer" \
                                         "the probe ran on a row whose when test exited 2"
is  "a when test that exits 1 still switches the row off as not-applicable" "$(_askqstate whenno)" "not-applicable"
is  "a witness that exits 2 after a silent probe makes the row unknown, never empty" \
    "$(_askqstate witcrash)" "unknown"
_asksays "and the row says the witness was neither yes nor no, with its code" "$(_askqrow witcrash)" 2
is  "a witness that exits 1 after a silent probe is still empty" "$(_askqstate witno)" "empty"
is  "a witness that exits 2 after a probe that failed is unknown, not blind" \
    "$(_askqstate witcrashfail)" "unknown"
# Blocking follows the state, so the crashed asks block and the honest noes do not.
is  "exactly the rows whose ask crashed block" "$(_askqblk)" "whencrash witcrash witcrashfail "
# Stated, not fixed: `false | grep -q x` reports grep's 1, so a crash before
# the last stage of a pipeline is invisible here. Nothing above expects the
# engine to see one.

# The command. A table of the three clean states passes; one row nobody could
# establish fails and is named; no table at all fails and says so.
_askctable() {
  { printf '# predicate\tgrounds\twhen\tprobe\twitness\n'
    printf 'tracked\t-\t-\tgit ls-files\tgit ls-tree -r HEAD --name-only 2>/dev/null | grep -q .\n'
    printf 'rustcrate\t-\t-\tls -1 Cargo.toml 2>/dev/null\ttest -f Cargo.toml\n'
    printf 'na\t-\ttest -f Cargo.toml\tls -1 x\ttest -f x\n'
    [ -n "${1:-}" ] && printf '%s\n' "$1"
    :
  } > "$ASKC/probes.tsv"
}
_askchk() { ( cd "$ASKR" && "$FROOT/harness/bin/probes-check" "$1" 2>&1 ); }
if [ -x "$FROOT/harness/bin/probes-check" ]; then
  _askctable
  out="$(_askchk "$ASKC")"; rc=$?
  is  "probes-check passes a table of found, empty and not-applicable rows" "$rc" "0"
  case "$out" in
    *"probes for askcheck"*"3 probe(s):"*) ok  "and heads the report with the project and counts every row" ;;
    *) bad "and heads the report with the project and counts every row" "$out" ;;
  esac
  _askctable 'blindrow	-	-	git ls-files "*.rs"	test -f x'
  out="$(_askchk "$ASKC")"; rc=$?
  is  "probes-check fails on a blind row" "$rc" "1"
  has "naming the predicate that blocks" "$out" "blindrow"
  _askctable 'nowit	-	-	git ls-files "*.rs"	-'
  out="$(_askchk "$ASKC")"; rc=$?
  is  "probes-check fails on an unknown row" "$rc" "1"
  out="$(_askchk "$ASKN")"; rc=$?
  is  "probes-check fails on a project with no probes.tsv" "$rc" "1"
  has "and says the table is absent" "$out" "no probes.tsv"
  _askctable
else
  for a in "probes-check passes a table of found, empty and not-applicable rows" \
           "and heads the report with the project and counts every row" \
           "probes-check fails on a blind row" "naming the predicate that blocks" \
           "probes-check fails on an unknown row" \
           "probes-check fails on a project with no probes.tsv" "and says the table is absent"; do
    skip "$a" "no bin/probes-check beside this harness"; done
fi

# Refused rows, and the classes that do not block.
printf 'a\tRELEASE_BLOCKING\tprobabilistic\t-\ttrue\tthing\tguess\n' > "$OBP/obligations.tsv"
has "a probabilistic row with a blocking class is refused" \
    "$(_ob felix_obligation_malformed "$OBP")" "advisory only"
is  "and never evaluated" "$(_obrun)" ""
has "and refused at the boundary" "$(_obblk)" "advisory only"
printf 'a\tSHOUTY\tdeterministic\t-\ttrue\tthing\t?\n' > "$OBP/obligations.tsv"
has "a class outside the set is refused" "$(_ob felix_obligation_malformed "$OBP")" "not one of"
printf 'a\tRELEASE_BLOCKING\tdeterministic\t-\t-\tthing\t?\n' > "$OBP/obligations.tsv"
has "a row with no evidence contract is refused" \
    "$(_ob felix_obligation_malformed "$OBP")" "no evidence contract"
printf 'a\tADVISORY\tprobabilistic\t-\tfalse\tthing\tguess\n' > "$OBP/obligations.tsv"
is  "an advisory probabilistic row that fails blocks nothing" "$(_obblk)" ""
is  "but is still evaluated and reported" "$(_obrun | cut -f5)" "UNSATISFIED"
printf 'a\tTASK_BLOCKING\tdeterministic\t-\tfalse\tthing\ttask\n' > "$OBP/obligations.tsv"
is  "a task-blocking row does not block a release" "$(_obblk)" ""
is  "and does block a task" "$(_obrun | _ob felix_obligations_blocking | cut -f1)" "a"

# Grounds.
printf 'a\tRELEASE_BLOCKING\tdeterministic\t-\ttrue\tnothing\t?\n' > "$OBP/obligations.tsv"
is  "a row grounded on a probe the project does not declare is an orphan" \
    "$(_ob felix_obligations_orphans "$OBP")" "nothing"
has "and refused at the boundary" "$(_obblk)" "does not declare"
printf 'a\tRELEASE_BLOCKING\tdeterministic\t-\ttrue\t-\t?\n' > "$OBP/obligations.tsv"
is  "an ungrounded row is counted" "$(_ob felix_obligations_ungrounded "$OBP")" "a"
is  "not refused" "$(_ob felix_obligations_orphans "$OBP")" ""

# The empty case, at the boundary.
printf '# nothing\n' > "$OBP/obligations.tsv"
has "an obligations.tsv admitting nothing blocks a merge" "$(_obblk)" "admits no obligation"
OBN="$TMP/oblig-none"; mkdir -p "$OBN"; cp "$OBP/probes.tsv" "$OBN/"
has "and a project with no obligations.tsv blocks a merge" "$(_obblk "$OBN")" "admits no obligation; write"

# The CLI, on the bound fixture.
out="$(cd "$REPO" && "$FELIX" obligations --gate 2>&1)"; rc=$?
is  "felix obligations --gate passes on the fixture's one holding obligation" "$rc" "0"
has "and reports it on its axes" "$out" "ACTIVE    SATISFIED"
has "and counts it" "$out" "1 obligation(s): 1 active, 0 dormant, 0 unknown; 0 blocking"

# The first obligation's evidence contract, on the real tree and on a copy.
if [ -x "$REAL_HARNESS/bin/lifecycle-check" ]; then
  out="$(cd "$REAL_HARNESS/../.." && "$REAL_HARNESS/bin/lifecycle-check" engine/harness/templates engine/hooks/hooks.json 2>&1)"; rc=$?
  is  "the shipped hooks bind every moment the stance table says is wired" "$rc" "0"
  has "and the contract names each moment it examined" "$out" "SubagentStop"
  # Its arguments are read from the top of the checkout, and its library from
  # where it was called: dirname "$0" is relative to the caller's directory.
  _lcsub="$(cd "$REAL_HARNESS/templates" && ../bin/lifecycle-check engine/harness/templates engine/hooks/hooks.json 2>&1)"
  is  "and says the same called by a relative path from a subdirectory, finding its library from where it was called" \
      "$?:$_lcsub" "$rc:$out"
  LC="$TMP/lc"; mkdir -p "$LC/tpl"; cp "$REAL_HARNESS/templates/lifecycle.tsv" "$LC/tpl/"
  python3 -c 'import json,sys; d=json.load(open(sys.argv[1])); h=d["hooks"] if "hooks" in d else d; h.pop("SubagentStop", None); json.dump(d, open(sys.argv[2], "w"))' \
    "$REAL_HARNESS/../hooks/hooks.json" "$LC/hooks.json"
  out="$(cd "$LC" && "$REAL_HARNESS/bin/lifecycle-check" tpl hooks.json 2>&1)"; rc=$?
  is  "and fails when a wired moment is unbound" "$rc" "1"
  has "naming it" "$out" "missing       SubagentStop"
  is  "and cannot examine without a stance table" \
      "$(cd "$LC" && "$REAL_HARNESS/bin/lifecycle-check" nowhere hooks.json >/dev/null 2>&1; echo $?)" "2"
  is  "or without hooks" \
      "$(cd "$LC" && "$REAL_HARNESS/bin/lifecycle-check" tpl nohooks.json >/dev/null 2>&1; echo $?)" "2"
else
  for a in "the shipped hooks bind every moment the stance table says is wired" \
           "and the contract names each moment it examined" \
           "and says the same called by a relative path from a subdirectory, finding its library from where it was called" \
           "and fails when a wired moment is unbound" \
           "naming it" "and cannot examine without a stance table" "or without hooks"; do
    skip "$a" "no bin/lifecycle-check beside this harness"; done
fi

# The real ledger on the real tree.
_REALP="$(cd "$REAL_HARNESS/../.." && pwd)/projects/felix"
if [ -f "$_REALP/obligations.tsv" ] && [ -x "$REAL_HARNESS/bin/obligations-check" ]; then
  out="$(cd "$REAL_HARNESS/../.." && "$REAL_HARNESS/bin/obligations-check" projects/felix release 2>&1)"; rc=$?
  is  "felix's own first obligation is discharged on this tree" "$rc" "0"
  has "and it is the lifecycle one" "$out" "lifecycle_wired"
  _obsub="$(cd "$REAL_HARNESS/templates" && ../bin/obligations-check projects/felix release 2>&1)"
  is  "and says the same called by a relative path from a subdirectory, finding its libraries from where it was called" \
      "$?:$_obsub" "$rc:$out"
  is  "grounded on a probe felix declares" "$(_ob felix_obligations_orphans "$_REALP")" ""
else
  for a in "felix's own first obligation is discharged on this tree" "and it is the lifecycle one" \
           "and says the same called by a relative path from a subdirectory, finding its libraries from where it was called" \
           "grounded on a probe felix declares"; do skip "$a" "no projects/felix/obligations.tsv beside this harness"; done
fi

