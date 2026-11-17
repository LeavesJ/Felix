printf '\nonly the gate workflow is evidence\n'
# The streak above and the repair ceiling both read `gh run list --branch <b>`,
# and with nothing else on that line it lists every workflow's runs on the
# branch. That was harmless while a governed repository ran one workflow.
# another governed project runs three: the gate, the unattended repair that follows it, and
# GitHub's Dependency Graph. Measured on 2026-09-22 over its last 82 runs, all
# 39 that were not the gate's sat on main, 37 of them the repair's, because a
# workflow_run event records the run on the default branch. So on main the
# newest run was usually the repair's own: skipped, which stops the count of
# the gate's failures at zero, or, while it runs, in progress, which would tell
# the repair asking that the gate is still running. On a pull request's branch
# it is latent: a second workflow run there would dirty a green pull request.
# Recorded as item 2 of "before any scheduler" in the direction decisions of
# 2026-09-19.
#
# gh is stubbed, and the stub does what the server does with what it is given:
# it filters by --workflow and --branch, honours --limit, answers a workflow the
# repository does not have with gh's own 404, and lists every workflow when
# --workflow is empty, because gh does. Its output goes through jq for the -q
# expression, since the expressions are the other half of the contract and a
# stub that pattern-matched them would be testing itself.
if ! command -v jq >/dev/null 2>&1; then
  for a in "a failure in another workflow on the branch does not dirty a green pull request" \
           "another workflow's failures on the branch are not repair attempts" \
           "and the run repair is handed is the gate's, not the newest of any workflow" \
           "every run list those three make names the gate workflow" \
           "a count or a latest run asked for no workflow is refused, not every workflow's" \
           "and a history read for no workflow is unknown" \
           "and none of them asks gh for every workflow's runs" \
           "a repository without the gate workflow makes no pull request clean" \
           "and its repair ceiling does not read as unspent" \
           "and repair hears the gate's runs could not be read, not that there are none" \
           "a branch the gate has not run on has no latest run" \
           "a cancelled gate run between failures neither spends the repair ceiling nor resets it" \
           "and of the conclusions a completed gate run can have, only success resets it" \
           "a gate run that failed to start counts against the ceiling, as do a timed-out one and a conclusion this code does not know" \
           "a window of gate runs that ends before a success or the ceiling is not read as the attempts it saw" \
           "and a gate history exactly as long as the window is counted to its first run" \
           "and a window that reaches the ceiling before it ends reads as reached" \
           "felix repair reads the gate's run on the branch" \
           "and counts only the gate's failures against the ceiling" \
           "and every run list felix repair makes names the gate workflow" \
           "felix repair stops three failed gate runs that a cancelled one sits between" \
           "and says the ceiling is reached, not unknown" \
           "felix repair stops at the ceiling when its attempts cannot be counted" \
           "and hands on no failing output as if attempts remained" \
           "felix repair exits 5, nothing to repair, on a green gate run" \
           "and on a gate run still in progress" \
           "and on a branch the gate has never run on" \
           "felix repair refuses a detached checkout rather than finding nothing to repair on HEAD" \
           "a gate run that completed without failing is nothing to repair, and one that failed without a log is refused" \
           "and none of them is handed on as a brief" \
           "a timed-out gate run is repaired, as the ceiling counts it" \
           "and its brief carries the failing output" \
           "and the ceiling counts it with the failure behind it" \
           "a failed run whose log cannot be read is refused, not briefed" \
           "and says the log could not be read" \
           "felix repair writes the files the failing log names where --implicated says" \
           "and lists them in the brief it hands a model" \
           "and a brief whose log names no file leaves the set empty" \
           "and a run that is no brief empties it, rather than leave the last run's set" \
           "and an --implicated file that cannot be written stops repair before any brief" \
           "felix automerge judges a green pull request by the gate's runs alone" \
           "and every run list felix automerge makes names the gate workflow" \
           "and felix unattended's streak row counts the gate's runs alone" \
           "bootstrap looks for gate.yml when the project names no gate workflow" \
           "a project that names its gate workflow is repaired from that workflow's run" \
           "and every run list names that workflow" \
           "and bootstrap looks for the workflow the project names" \
           "a gate_workflow that is not a file name is refused, and named" \
           "and nothing is asked of gh"; do
    skip "$a" "no jq here to evaluate gh's -q expressions"
  done
else
_gate_workflow_stub_build
export WFSTUB_LOG="$TMP/wf.log" WFSTUB_RUNS="$TMP/wf.runs" \
       WFSTUB_WORKFLOWS="gate.yml unattended.yml dynamic/dependabot/update-graph ci.yml" \
       WFSTUB_PRS='[{"number":7,"headRefName":"feat/x","title":"a green change"}]'
# Newest first, as gh lists them. On each branch the gate's own record is clean
# or holds one failure, and everything that would change the answer belongs to
# another workflow.
{ printf 'dynamic/dependabot/update-graph\tDependency Graph\tfeat/x\t901\tcompleted\tfailure\n'
  printf 'gate.yml\tgate\tfeat/x\t101\tcompleted\tsuccess\n'
  printf 'unattended.yml\tunattended repair\tfeat/x\t902\tcompleted\tfailure\n'
  printf 'gate.yml\tgate\tfeat/x\t102\tcompleted\tsuccess\n'
  printf 'unattended.yml\tunattended repair\tfix/y\t903\tcompleted\tfailure\n'
  printf 'gate.yml\tgate\tfix/y\t201\tcompleted\tfailure\n'
  printf 'dynamic/dependabot/update-graph\tDependency Graph\tfix/y\t904\tcompleted\tfailure\n'
  printf 'ci.yml\tCI\tfix/y\t301\tcompleted\tfailure\n'
  printf 'unattended.yml\tunattended repair\tfix/y\t905\tcompleted\tfailure\n'
  printf 'gate.yml\tgate\tfix/y\t202\tcompleted\tsuccess\n'
} > "$WFSTUB_RUNS"
# The `run list` calls in the log: all of them, those not naming workflow $1,
# and those naming no workflow at all.
_wfruns()  { grep -c '^run list' "$WFSTUB_LOG"; }
_wfbare()  { grep '^run list' "$WFSTUB_LOG" | grep -vcF -- "--workflow $1"; }
_wfunfiltered() { grep '^run list' "$WFSTUB_LOG" | grep -vcE -- '--workflow [^ ]'; }

: > "$WFSTUB_LOG"
is "a failure in another workflow on the branch does not dirty a green pull request" \
   "$(_wfhist gate.yml | cut -f2)" "clean"
is "another workflow's failures on the branch are not repair attempts" \
   "$(_wfatt fix/y gate.yml)" "1"
is "and the run repair is handed is the gate's, not the newest of any workflow" \
   "$(_wflatest fix/y gate.yml | cut -f1)" "201"
[ "$(_wfruns)" -gt 0 ] && [ "$(_wfbare gate.yml)" -eq 0 ] \
  && ok  "every run list those three make names the gate workflow" \
  || bad "every run list those three make names the gate workflow" "$(grep '^run list' "$WFSTUB_LOG" | head -3)"

# A caller that names no workflow. gh reads an empty --workflow as no filter,
# so passing one through would be the same defect one call away; the libraries
# refuse to ask instead, and a refusal is not a number.
: > "$WFSTUB_LOG"
_wa="$(_wfatt fix/y "")"; _war=$?
_wl="$(_wflatest fix/y "")"; _wlr=$?
[ -z "$_wa$_wl" ] && [ "$_war" -ne 0 ] && [ "$_wlr" -ne 0 ] \
  && ok  "a count or a latest run asked for no workflow is refused, not every workflow's" \
  || bad "a count or a latest run asked for no workflow is refused, not every workflow's" \
         "attempts rc $_war [$_wa], latest rc $_wlr [$_wl]"
is "and a history read for no workflow is unknown" "$(_wfhist "" | cut -f2)" "unknown"
is "and none of them asks gh for every workflow's runs" "$(_wfunfiltered)" "0"

# A repository the gate workflow is not on. gh answers 404 and prints nothing,
# and both readings have to land on the side that holds: no pull request made
# clean by it, and no ceiling read as unspent because nothing could be counted.
WFSTUB_WORKFLOWS="ci.yml"
cp "$WFSTUB_RUNS" "$TMP/wf.runs.keep"
{ printf 'ci.yml\tCI\tfeat/x\t302\tcompleted\tsuccess\n'
  printf 'ci.yml\tCI\tfix/y\t303\tcompleted\tsuccess\n'
  printf 'ci.yml\tCI\tfix/y\t304\tcompleted\tfailure\n'
} > "$WFSTUB_RUNS"
is "a repository without the gate workflow makes no pull request clean" \
   "$(_wfhist gate.yml | cut -f2)" "unknown"
_wa="$(_wfatt fix/y gate.yml)"; _war=$?
[ -z "$_wa" ] && [ "$_war" -ne 0 ] \
  && ok  "and its repair ceiling does not read as unspent" \
  || bad "and its repair ceiling does not read as unspent" "rc $_war, printed [$_wa]"
( _wflatest fix/y gate.yml >/dev/null ); _wlr=$?
[ "$_wlr" -ne 0 ] \
  && ok  "and repair hears the gate's runs could not be read, not that there are none" \
  || bad "and repair hears the gate's runs could not be read, not that there are none" "rc 0"

# The gate on the repository and no run of it on this branch yet. `.[0]` of an
# empty list is null, and interpolating null printed `null<TAB>null<TAB>-`,
# which felix repair read as a run still in progress.
WFSTUB_WORKFLOWS="gate.yml ci.yml"
is "a branch the gate has not run on has no latest run" "$(_wflatest fix/y gate.yml)" ""
WFSTUB_WORKFLOWS="gate.yml unattended.yml dynamic/dependabot/update-graph ci.yml"

# Only a success resets the ceiling. A run that ended without a verdict ended
# the count, so failure, cancelled, failure, failure read as one attempt, and a
# gate that cancels in progress, or anyone cancelling a run, could keep an
# unattended loop from ever reaching its ceiling. Such a run is passed over now,
# like one still going; a run that failed to start counts; and so does a
# conclusion this code has not met, because the count errs toward stopping.
_wfseq() { local c; for c in "$@"; do
             printf 'gate.yml\tgate\tfix/y\t501\tcompleted\t%s\n' "$c"; done > "$WFSTUB_RUNS"; }
_wfseq failure cancelled failure failure
is "a cancelled gate run between failures neither spends the repair ceiling nor resets it" \
   "$(_wfatt fix/y gate.yml)" "3"
_wfres=""
for _c in in_progress cancelled skipped neutral stale action_required success; do
  _wfseq failure "${_c#in_progress}" failure; _wfres="$_wfres $_c:$(_wfatt fix/y gate.yml)"
done
is "and of the conclusions a completed gate run can have, only success resets it" \
   "$_wfres" " in_progress:2 cancelled:2 skipped:2 neutral:2 stale:2 action_required:2 success:1"
_wfres=""
for _c in timed_out startup_failure some_later_state; do
  _wfseq failure "$_c" failure; _wfres="$_wfres $_c:$(_wfatt fix/y gate.yml)"
done
is "a gate run that failed to start counts against the ceiling, as do a timed-out one and a conclusion this code does not know" \
   "$_wfres" " timed_out:3 startup_failure:3 some_later_state:3"
# Passing a run over spends the window and not the count. The window is the
# newest hundred runs, so without a rule for its end ninety-nine cancelled runs
# would push the failures behind them out of sight, and the count would read as
# the one it saw. Twice: the second window ends in runs still going, whose empty
# lines a count of lines would lose, making a full window look like a whole
# history.
_wfseq failure $(yes cancelled | head -99) failure failure
_wa="$(_wfatt fix/y gate.yml)"; _war=$?
_wfseq failure $(yes cancelled | head -94) "" "" "" "" "" ""
_wb="$(_wfatt fix/y gate.yml)"; _wbr=$?
[ -z "$_wa$_wb" ] && [ "$_war" -ne 0 ] && [ "$_wbr" -ne 0 ] \
  && ok  "a window of gate runs that ends before a success or the ceiling is not read as the attempts it saw" \
  || bad "a window of gate runs that ends before a success or the ceiling is not read as the attempts it saw" \
         "rc $_war printed [$_wa]; ending in runs still going, rc $_wbr printed [$_wb]"
_wfseq failure failure $(yes cancelled | head -98)
is "and a gate history exactly as long as the window is counted to its first run" \
   "$(_wfatt fix/y gate.yml)" "2"
_wfseq failure failure failure $(yes cancelled | head -98)
is "and a window that reaches the ceiling before it ends reads as reached" "$(_wfatt fix/y gate.yml)" "3"
cp "$TMP/wf.runs.keep" "$WFSTUB_RUNS"

# Through the CLI, where the workflow comes from the project rather than from
# the test. Its own checkout, on a branch, with a GitHub remote: the main
# fixture is remote-less, and felix repair dies without one before any gh.
_gate_workflow_repo_build
cp "$FROOT/projects/widget/project.json" "$TMP/project.wf.keep"

: > "$WFSTUB_LOG"
out="$(_wfcli repair)"
has "felix repair reads the gate's run on the branch" "$out" "run:      201"
has "and counts only the gate's failures against the ceiling" "$out" "attempts: 1 of"
[ "$(_wfruns)" -gt 0 ] && [ "$(_wfbare gate.yml)" -eq 0 ] \
  && ok  "and every run list felix repair makes names the gate workflow" \
  || bad "and every run list felix repair makes names the gate workflow" "$(grep '^run list' "$WFSTUB_LOG" | head -3)"

# The same history through the command the unattended template runs, where one
# attempt of three left read as a brief to act on.
_wfseq failure cancelled failure failure
out="$(_wfcli repair)"; rc=$?
is  "felix repair stops three failed gate runs that a cancelled one sits between" "$rc" "2"
has "and says the ceiling is reached, not unknown" "$out" "CEILING REACHED"
cp "$TMP/wf.runs.keep" "$WFSTUB_RUNS"

# The newest gate run read and the count behind it not. The count is the bound,
# and it used to read as zero whenever gh did not answer, which printed the
# failing output with every attempt still left.
out="$( export WFSTUB_UNANSWERED='.[].conclusion'; _wfcli repair )"; rc=$?
is "felix repair stops at the ceiling when its attempts cannot be counted" "$rc" "2"
case "$out" in
  *"attempt(s) left"*) bad "and hands on no failing output as if attempts remained" "$out" ;;
  *)                   ok  "and hands on no failing output as if attempts remained" ;;
esac

# Nothing failing is not a brief. All three of these printed their sentence
# and exited 0, the status of a brief to act on, and the unattended template
# reads the status and nothing else.
printf 'gate.yml\tgate\tfix/y\t211\tcompleted\tsuccess\n' > "$WFSTUB_RUNS"
out="$(_wfcli repair)"; rc=$?
is "felix repair exits 5, nothing to repair, on a green gate run" "$rc" "5"
printf 'gate.yml\tgate\tfix/y\t212\tin_progress\t\n' > "$WFSTUB_RUNS"
out="$(_wfcli repair)"; rc=$?
is "and on a gate run still in progress" "$rc" "5"
printf 'gate.yml\tgate\tfeat/x\t213\tcompleted\tfailure\n' > "$WFSTUB_RUNS"
out="$(_wfcli repair)"; rc=$?
is "and on a branch the gate has never run on" "$rc" "5"
# A detached checkout's branch reads as HEAD, which no run is on, so it would
# be the third case above for a branch nobody named.
( _fx_cd "$WFR" && git checkout -q --detach )
out="$(_wfcli repair)"; rc=$?
is "felix repair refuses a detached checkout rather than finding nothing to repair on HEAD" "$rc" "1"
( _fx_cd "$WFR" && git checkout -q fix/y )
cp "$TMP/wf.runs.keep" "$WFSTUB_RUNS"

# The newest gate run completed and was neither green nor a failure. Only
# success was caught, so every other conclusion GitHub gives fell through to a
# brief, exit 0, which the unattended template acts on. It was also a run the
# ceiling did not count then: felix_repair_attempts stopped at it, so the
# ceiling read as unspent however many failures sat behind it. Here one does.
# Repair acts on failure and timed_out; a run that completed without failing
# is nothing to repair; and a run that failed without starting, or whose
# conclusion is new to this code, has no log to read and is refused.
_wfnewest() { printf 'gate.yml\tgate\tfix/y\t211\tcompleted\t%s\n' "$1"
              printf 'gate.yml\tgate\tfix/y\t201\tcompleted\tfailure\n'; }
_wfres=""; _wfbriefed=""
for _c in cancelled skipped neutral stale action_required startup_failure some_later_state; do
  _wfnewest "$_c" > "$TMP/wf.runs.$_c"
  out="$( export WFSTUB_RUNS="$TMP/wf.runs.$_c"; _wfcli repair )"; rc=$?
  _wfres="$_wfres $_c:$rc"
  case "$out" in *"failing output"*|*"attempt(s) left"*) _wfbriefed="$_wfbriefed $_c" ;; esac
done
is "a gate run that completed without failing is nothing to repair, and one that failed without a log is refused" \
   "$_wfres" " cancelled:5 skipped:5 neutral:5 stale:5 action_required:5 startup_failure:1 some_later_state:1"
is "and none of them is handed on as a brief" "$_wfbriefed" ""
_wfnewest timed_out > "$TMP/wf.runs.timed_out"
out="$( export WFSTUB_RUNS="$TMP/wf.runs.timed_out"; _wfcli repair )"; rc=$?
is  "a timed-out gate run is repaired, as the ceiling counts it" "$rc" "0"
has "and its brief carries the failing output" "$out" "the widget test failed"
has "and the ceiling counts it with the failure behind it" "$out" "attempts: 2 of"

# A failed run whose log could not be read. The excerpt came back empty, so no
# path was implicated, the red-path check never ran, and repair exited 0 with a
# brief naming no path and carrying no failing output. Both ways it happens:
# gh does not answer, and gh answers with nothing, as for a log GitHub has
# expired.
_wfnolog=""
out="$( export WFSTUB_UNANSWERED='--log-failed'; _wfcli repair )"; rc=$?
_wfnolog="$_wfnolog unanswered:$rc"
case "$out" in *"attempt(s) left"*) _wfnolog="$_wfnolog(briefed)" ;; esac
out="$( export WFSTUB_NOLOG=1; _wfcli repair )"; rc=$?
_wfnolog="$_wfnolog empty:$rc"
case "$out" in *"attempt(s) left"*) _wfnolog="$_wfnolog(briefed)" ;; esac
is  "a failed run whose log cannot be read is refused, not briefed" "$_wfnolog" " unanswered:1 empty:1"
has "and says the log could not be read" "$out" "log of run 201"

# The brief's second half for the unattended template: the files the failing
# log names, written where --implicated says, and listed in the brief a model
# reads, so the set a repair is held to is the set it was shown. Emptied on
# every run, so a run that is no brief cannot leave the last one's set behind
# to stand for it.
_wfimp="$TMP/wf.implicated"
out="$( export WFSTUB_LOGTEXT='WIDGET.txt:3 does not say widget, nor does /tmp/elsewhere.py'
        _wfcli repair --implicated "$_wfimp" )"; rc=$?
is  "felix repair writes the files the failing log names where --implicated says" \
    "exit $rc: $(tr '\n' ' ' < "$_wfimp" 2>/dev/null)" "exit 0: WIDGET.txt "
has "and lists them in the brief it hands a model" "$out" "$(printf 'implicated files:\n\n  WIDGET.txt')"
out="$(_wfcli repair --implicated "$_wfimp")"; rc=$?
is  "and a brief whose log names no file leaves the set empty" \
    "exit $rc, $(wc -c < "$_wfimp" 2>/dev/null | tr -d ' ') bytes" "exit 0, 0 bytes"
printf 'WIDGET.txt\n' > "$_wfimp"
printf 'gate.yml\tgate\tfix/y\t211\tcompleted\tsuccess\n' > "$TMP/wf.runs.green"
out="$( export WFSTUB_RUNS="$TMP/wf.runs.green"; _wfcli repair --implicated "$_wfimp" )"; rc=$?
is  "and a run that is no brief empties it, rather than leave the last run's set" \
    "exit $rc, $(wc -c < "$_wfimp" 2>/dev/null | tr -d ' ') bytes" "exit 5, 0 bytes"
out="$(_wfcli repair --implicated "$TMP/no/such/dir/implicated")"; rc=$?
if [ "$rc" = "1" ] && ! grep -qE 'failing output|attempt\(s\) left' <<<"$out"; then
  ok  "and an --implicated file that cannot be written stops repair before any brief"
else
  bad "and an --implicated file that cannot be written stops repair before any brief" "exit $rc: $out"
fi

: > "$WFSTUB_LOG"
out="$(_wfcli automerge)"
has "felix automerge judges a green pull request by the gate's runs alone" "$out" "clean  #7"
[ "$(_wfruns)" -gt 0 ] && [ "$(_wfbare gate.yml)" -eq 0 ] \
  && ok  "and every run list felix automerge makes names the gate workflow" \
  || bad "and every run list felix automerge makes names the gate workflow" "$(grep '^run list' "$WFSTUB_LOG" | head -3)"
# The readiness report reads the same streak, and is what somebody reads while
# deciding whether to switch on a loop that runs unattended.
has "and felix unattended's streak row counts the gate's runs alone" \
    "$(_wfcli unattended | grep -F 'green merges judged well')" " 1 of "
has "bootstrap looks for gate.yml when the project names no gate workflow" \
    "$(_wfcli bootstrap)" ".github/workflows/gate.yml"

# A project whose gate already runs in a workflow of its own says so, and is
# read through that workflow and no other.
python3 - "$FROOT/projects/widget/project.json" <<'PYJ'
import json,sys,pathlib
p=pathlib.Path(sys.argv[1]); d=json.loads(p.read_text())
d["gate_workflow"]="ci.yml"; p.write_text(json.dumps(d,indent=2))
PYJ
: > "$WFSTUB_LOG"
out="$(_wfcli repair)"
has "a project that names its gate workflow is repaired from that workflow's run" "$out" "run:      301"
[ "$(_wfruns)" -gt 0 ] && [ "$(_wfbare ci.yml)" -eq 0 ] \
  && ok  "and every run list names that workflow" \
  || bad "and every run list names that workflow" "$(grep '^run list' "$WFSTUB_LOG" | head -3)"
has "and bootstrap looks for the workflow the project names" \
    "$(_wfcli bootstrap)" ".github/workflows/ci.yml"

# Refused, not replaced by the default. A declared fact silently overridden
# reads a workflow the project said it does not use, and a path would reach gh
# as a display name that matches nothing.
python3 - "$FROOT/projects/widget/project.json" <<'PYJ'
import json,sys,pathlib
p=pathlib.Path(sys.argv[1]); d=json.loads(p.read_text())
d["gate_workflow"]=".github/workflows/ci.yml"; p.write_text(json.dumps(d,indent=2))
PYJ
: > "$WFSTUB_LOG"
out="$(_wfcli repair)"
has "a gate_workflow that is not a file name is refused, and named" "$out" "gate_workflow"
is  "and nothing is asked of gh" "$(wc -l < "$WFSTUB_LOG" | tr -d ' ')" "0"

cp "$TMP/project.wf.keep" "$FROOT/projects/widget/project.json"
unset WFSTUB_LOG WFSTUB_RUNS WFSTUB_WORKFLOWS WFSTUB_PRS
fi

