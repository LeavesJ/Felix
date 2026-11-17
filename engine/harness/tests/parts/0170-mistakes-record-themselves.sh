printf '\nmistakes record themselves\n'
# Judgement at write time is the wrong shape: it asks for a decision at the exact
# moment someone is trying to finish something else. Write cheaply, curate later.
_mislog_vars
rm -f "$MISLOG"
# A script rather than an inline command: project.json holds no escaped quotes,
# which its reader documents that it cannot parse, and a gate script is the more
# common shape anyway.
cat > "$FROOT/projects/widget/failing-gate.sh" <<'GS'
#!/usr/bin/env bash
echo "  lint               FAIL"
exit 1
GS
chmod +x "$FROOT/projects/widget/failing-gate.sh"
python3 - "$FROOT/projects/widget/project.json" <<'PYJ'
import json,sys,pathlib
p=pathlib.Path(sys.argv[1]); d=json.loads(p.read_text())
d["gate"]="failing-gate.sh"
p.write_text(json.dumps(d,indent=2))
PYJ
( cd "$REPO" && "$FELIX" gate >/dev/null 2>&1 ); rc=$?
is "a failing gate still exits non-zero" "$rc" "1"
[ -f "$MISLOG" ] && ok "and records the failure without being asked" \
                 || bad "and records the failure without being asked"
grep -q 'lint' "$MISLOG" 2>/dev/null \
  && ok "naming which check failed" || bad "naming which check failed"
# And when, to the second. The file is shared by every session on the project,
# so its own time is whoever wrote last; felix_guard_unrecorded reads this
# column to tell this checkout's catch from a peer's appended after it.
_mst="$(tail -1 "$MISLOG" 2>/dev/null | cut -f5)"
case "$_mst" in
  ''|*[!0-9]*) bad "and the second it was caught, since the file's own time is whoever wrote last" "fifth column [$_mst]" ;;
  *) [ $(( $(date +%s) - _mst )) -lt 600 ] \
       && ok  "and the second it was caught, since the file's own time is whoever wrote last" \
       || bad "and the second it was caught, since the file's own time is whoever wrote last" "fifth column [$_mst]" ;;
esac

# The same tree gated again is the same occasion. It cost a second run, and a
# run is not a recurrence: this rank's advice is to write a lesson, and there
# is nothing to generalise from one incident. Felix's own log had `ecosystem`
# five times, every one of them the same branch at the same sha, ranked beside
# `installed` at twenty-two separate commits.
( cd "$REPO" && "$FELIX" gate >/dev/null 2>&1 )
out="$(cd "$REPO" && "$FELIX" promote 2>&1)"
case "$out" in
  *lint*) bad "one tree gated twice is one occasion, not a habit" "$out" ;;
  *)      ok  "one tree gated twice is one occasion, not a habit" ;;
esac
# A second tree is. Same failure, different commit — which is what "again"
# means and what a lesson would be generalising over.
( _fx_cd "$REPO" && printf 'again\n' >> README.md && git add -A \
  && git -c user.name=t -c user.email=t@t commit -qm second ) >/dev/null 2>&1
( cd "$REPO" && "$FELIX" gate >/dev/null 2>&1 )
out="$(cd "$REPO" && "$FELIX" promote 2>&1)"
has "a second tree makes it a promotion candidate" "$out" "the gate keeps catching"
has "and names the habit"                          "$out" "lint"
# Both numbers, because they are not the same fact: two trees, three runs.
has "counted in occasions"           "$out" "2    lint"
has "with the runs it cost beside it" "$out" "(3 run(s))"

# A check that could not have passed did not catch anything.
#
# Felix's `installed` check compares the tree against the deployed plugin cache.
# In a worktree that can never match — the marketplace is pinned to one path, so
# a worktree's engine is not the one being served — and every gate run there
# recorded `installed` as a mistake. The count went 9 to 11 during the session
# that fixed the recurrence report, and it sat at the top of `felix next` rank 5
# under "already cost time more than once", where the advice is to go and build
# a mechanism. The check manufactured the evidence that ranked it.
#
# The verdict is deliberately NOT changed: the gate still fails, because the
# tree genuinely does not match, and loosening a gate to quiet a report is the
# move this project warns about in the definition of its own objective. Only the
# RECORD changes. A gate may mark a failure as a property of where it ran rather
# than of the work, and the engine subtracts those from what it writes down
# without learning any check's name — the project's own gate declares it.
cat > "$FROOT/projects/widget/structural-gate.sh" <<'GS'
#!/usr/bin/env bash
echo "  lint               FAIL"
echo "  deployed           FAIL (structural: this tree is not the one that deploys)"
exit 1
GS
chmod +x "$FROOT/projects/widget/structural-gate.sh"
python3 - "$FROOT/projects/widget/project.json" <<'PYJ'
import json,sys,pathlib
p=pathlib.Path(sys.argv[1]); d=json.loads(p.read_text())
d["gate"]="structural-gate.sh"; p.write_text(json.dumps(d,indent=2))
PYJ
: > "$MISLOG"
( cd "$REPO" && "$FELIX" gate >/dev/null 2>&1 ); rc=$?
is "a structural failure still fails the gate" "$rc" "1"
grep -q 'lint' "$MISLOG" 2>/dev/null \
  && ok "an ordinary failure is still written down" \
  || bad "an ordinary failure is still written down" "$(cat "$MISLOG")"
grep -q 'deployed' "$MISLOG" 2>/dev/null \
  && bad "but one that could not have passed is not" "$(cat "$MISLOG")" \
  || ok  "but one that could not have passed is not"

# And when EVERY failure was structural, nothing is written — not even the
# exit-status fallback. The first version of this fixed the named check and then
# recorded `exit-1` instead, which is the same permanent row wearing a less
# informative name. Caught by running the real gate in a real worktree, which is
# where the case lives; the suite had passed.
cat > "$FROOT/projects/widget/structural-gate.sh" <<'GS'
#!/usr/bin/env bash
echo "  deployed           FAIL (structural: this tree is not the one that deploys)"
exit 1
GS
: > "$MISLOG"
( cd "$REPO" && "$FELIX" gate >/dev/null 2>&1 ); rc=$?
is "an all-structural gate still fails"           "$rc" "1"
is "and writes no row at all, not even exit-1"    "$(wc -l < "$MISLOG" | tr -d ' ')" "0"

# The contract, against the line the SHIPPED gate actually prints.
#
# Everything above proves the mechanism with a line the fixture writes itself,
# so it stayed green while the real marker was renamed out from under it: #115
# rewrote `FAIL (structural: ...)` into `FAIL (drift, in a tree that cannot
# deploy: ...)` to stop the message misdiagnosing a stray, and the engine
# greps for `structural`. Every worktree gate failure went back to recording a
# mistake — the manufactured evidence issue #3 was filed for — and it put
# `installed` at the top of `felix next` on a count that was 16 of 20
# work-in-progress branches. Two files, one string between them, and nothing
# joined them up. This renders the gate's own format and drives it through the
# real recording path.
_REALG3="$(cd "$REAL_HARNESS/../.." && pwd)/projects/felix/gate.sh"
if [ -f "$_REALG3" ]; then
  _sfmt="$(grep -F 'FAIL (' "$_REALG3" | grep -F 'marketplace serves' | head -1 \
           | sed "s/^[[:space:]]*printf '//; s/'[[:space:]]*installed.*$//")"
  if [ -n "$_sfmt" ]; then
    _sline="$(printf "$_sfmt" installed /some/marketplace 2>/dev/null)"
    has "the shipped gate marks its undeployable failure" "$_sline" "installed"
    printf '#!/usr/bin/env bash\nprintf "%%s\\n" %s\nexit 1\n' "$(printf '%q' "$_sline")" \
      > "$FROOT/projects/widget/structural-gate.sh"
    : > "$MISLOG"
    ( cd "$REPO" && "$FELIX" gate >/dev/null 2>&1 ); rc=$?
    is "and it still fails the gate"             "$rc" "1"
    is "and the engine writes no mistake for it" "$(wc -l < "$MISLOG" | tr -d ' ')" "0"
  else
    skip "the shipped gate marks its undeployable failure" "no such line in the gate"
    skip "and it still fails the gate"                     "no such line in the gate"
    skip "and the engine writes no mistake for it"         "no such line in the gate"
  fi
else
  skip "the shipped gate marks its undeployable failure" "no shipped gate"
  skip "and it still fails the gate"                     "no shipped gate"
  skip "and the engine writes no mistake for it"         "no shipped gate"
fi

# A gate that names nothing still falls back, because then the status is all
# anybody knows.
cat > "$FROOT/projects/widget/structural-gate.sh" <<'GS'
#!/usr/bin/env bash
echo "something went wrong but no check is named"
exit 3
GS
: > "$MISLOG"
( cd "$REPO" && "$FELIX" gate >/dev/null 2>&1 )
grep -q 'exit-3' "$MISLOG" 2>/dev/null \
  && ok "a gate naming no check still records its status" \
  || bad "a gate naming no check still records its status" "$(cat "$MISLOG")"

# A passing gate must not record anything, or the signal is just a run counter.
python3 - "$FROOT/projects/widget/project.json" <<'PYJ'
import json,sys,pathlib
p=pathlib.Path(sys.argv[1]); d=json.loads(p.read_text())
d["gate"]="true"; p.write_text(json.dumps(d,indent=2))
PYJ
before="$(wc -l < "$MISLOG")"
( cd "$REPO" && "$FELIX" gate >/dev/null 2>&1 )
is "a passing gate records nothing" "$(wc -l < "$MISLOG")" "$before"
# Caught a moment ago, and the lessons written below land within the same
# second on a fast runner, which the Stop hook's guard does not count as after
# the catch; the green stops further down would then hear about this catch
# instead of what they assert. Aged an hour here, stated like every other
# ordering this suite depends on.
_mag="$(( $(date +%s) - 3600 ))"
awk -F'\t' -v OFS='\t' -v T="$_mag" 'NF >= 5 { $5 = T } { print }' "$MISLOG" > "$TMP/mislog.aged"
cat "$TMP/mislog.aged" > "$MISLOG"

# An unborn HEAD is still one row.
#
# A repository that has been `git init`ed and not yet committed to is exactly
# where a project gets commissioned, and commissioning is where the gate has to
# be watched failing. There `git rev-parse --abbrev-ref HEAD` prints `HEAD` AND
# exits 128, so a `|| echo '?'` fallback does not replace the answer, it appends
# to it: the branch field became "HEAD\n?" and the record two lines, neither of
# them with a fourth column. Every reader of this log is `cut -f4` or awk's $4,
# so the failure was written down and could not be read. Found 2026-09-18 on a
# real commissioning, where `gate_shown_failing` stayed held on a gate that had
# genuinely been seen red.
#
# Driven through the real gate in a real unborn repository rather than by
# calling the writer, because the defect was in what git says there and a
# fixture that invents git's answer would have inherited the same assumption.
_unborn_repo_build
( cd "$NOHEAD" && "$FELIX" gate >/dev/null 2>&1 ); rc=$?
is "a failing gate on an unborn HEAD still exits non-zero" "$rc" "1"
is "and records exactly one line for it"  "$(grep -c '' "$NOHEADLOG" 2>/dev/null)" "1"
# Six since rows carry the second they were caught and the session that
# caught them, appended after the four every reader takes.
is "of six tab-separated fields"          "$(awk -F'\t' '{ print NF }' "$NOHEADLOG" 2>/dev/null | sort -u | tr '\n' ' ')" "6 "
is "with the failed check in column four" "$(cut -f4 "$NOHEADLOG" 2>/dev/null | tr -d ' ')" "lint"
is "and says the commit is unborn rather than guessing one" "$(cut -f3 "$NOHEADLOG" 2>/dev/null)" "unborn"
# The reader the row was lost on, verbatim from templates/commissioning.tsv.
( FELIX_MEMORY_DIR="$MEM/unbornproj"
  cut -f4 "$FELIX_MEMORY_DIR/mistakes.log" 2>/dev/null | tr ' ' '\n' | grep -vxE 'commission|probes' | grep -q . ) \
  && ok  "so the commissioning check that reads column four sees the failure" \
  || bad "so the commissioning check that reads column four sees the failure" "$(od -c "$NOHEADLOG" 2>/dev/null | head -4)"
# The fallback status is a fourth field too, not only a named check.
cat > "$NOHEADP/gate.sh" <<'GS'
#!/usr/bin/env bash
echo "no check is named"
exit 2
GS
: > "$NOHEADLOG"
( cd "$NOHEAD" && "$FELIX" gate >/dev/null 2>&1 )
is "a gate naming nothing on an unborn HEAD records its status in column four" \
   "$(cut -f4 "$NOHEADLOG" 2>/dev/null)" "exit-2"
# The handoff names the same branch, from the same reader. Its line had no
# fallback, so it was never malformed: it printed `HEAD`, git's word for having
# no commit to abbreviate, to the next session as the branch of a repository
# that is on main. A project being commissioned is where a handoff gets written
# with no commit under it.
( cd "$NOHEAD" && "$FELIX" handoff "being commissioned" >/dev/null 2>&1 )
has "a handoff written on an unborn HEAD names the branch it is on" \
    "$(cat "$MEM/unbornproj/SESSION_HANDOFF.md" 2>/dev/null)" '- branch: `main`'

