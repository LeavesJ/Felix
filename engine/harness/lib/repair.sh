# The bounded repair loop.
#
# Felix does not fix anything here. It supplies the deterministic scaffolding a
# repair loop needs and refuses to be the part that requires judgment: fetch the
# failure, extract what actually broke, count how many attempts have already been
# spent, and enforce the ceiling. Diagnosis and the patch are the agent's job.
#
# The ceiling is the point. The guidebook (p8) asks for a bounded loop, because
# an agent that retries indefinitely burns money converging on nothing and looks
# busy the entire time. After FELIX_REPAIR_MAX failures of the gate with no
# success between them, the answer stops being "try again" and becomes "a human
# needs to look at this." A run cancelled or skipped between them does not
# start the count again; felix_repair_attempts says which conclusions count.
#
# Attempts are counted from CI history rather than a local counter, so the count
# survives a new session, a different machine, and a cleared scratch directory.
# A counter that resets when the agent restarts cannot bound anything.
#
# GitHub Actions only for now, via gh. Stated plainly rather than hidden behind a
# provider abstraction with one implementation.
#
# felix repair's exit status is its contract with templates/unattended.yml,
# which branches on it and on nothing else, so each status means one thing:
#
#   0  a brief for the newest gate run, which failed or timed out; the only
#      status a repair acts on
#   1  the gate's runs could not be read: no gh, no GitHub remote, no gate
#      workflow, no branch checked out, or gh did not answer. Also the failing
#      run's own log, when gh does not answer, GitHub no longer holds it, or
#      it is empty. And a run that failed to start, which left no log, or one
#      whose conclusion this code does not know
#   2  the repair ceiling is reached, or could not be counted: gh did not
#      answer, or the newest 100 gate runs held no success and fewer failures
#      than the ceiling
#   3  the failure implicates a red path, which unattended repair leaves alone
#   4  no project governs the checkout, or the binding naming one is broken
#   5  nothing to repair: the gate has not run on the branch, is still running,
#      is green, or ended without failing (cancelled, skipped, neutral, stale,
#      action_required)
#
# 4 was 2 until 2026-09-23, the status every other command still exits on a
# failed resolve, and the template's case read it as a spent ceiling.
# A failed resolve says the workflow is wired to a Felix that does not govern
# this repository, which is true of every branch at once and says nothing about
# the failing change, so the template fails the job on it rather than labelling
# a pull request.
#
# 5 was 0 until the same day, the status of a brief, so the template would
# have spent the budget and run a model on a brief saying nothing was wrong.
# Nothing failed, so it stops the job without failing it or asking anyone.
#
# Repair acts only on what its ceiling counts. Until the same day only success
# was caught, so every other conclusion a completed run can have fell through
# to a brief: a cancelled or skipped run, which felix_repair_attempts then
# stopped at, so its ceiling read as unspent however many failures sat behind
# it. A failed run whose excerpt came back empty was a brief too, and
# implicated no path, so the red-path check never ran and the model was handed
# no failing output.
# startup_failure is left alone too, whether or not the ceiling counts it: the
# gate never ran, so no step left a log to read.
#
# felix brief keeps this shape and uses 0, 1, 2 and 3 of it: its 2 is a failed
# resolve, and it has no 5, because an issue is always something to act on.

FELIX_REPAIR_MAX="${FELIX_REPAIR_MAX:-3}"

_felix_repair_require_gh() {
  command -v gh >/dev/null 2>&1 || {
    printf 'felix repair needs the gh CLI, which is not on PATH.\n' >&2
    return 1
  }
}

felix_repair_branch() {
  git rev-parse --abbrev-ref HEAD 2>/dev/null
}

# Both reads below are of the gate workflow's runs, named by the caller from
# felix_gate_workflow, and of no other workflow's. `gh run list --branch` alone
# is every workflow on the branch. The unattended repair's own runs are
# recorded on the default branch, which is where a workflow_run event puts
# them, and on any branch it is dispatched on; GitHub's Dependency Graph runs
# on the default branch as well. There the newest run was usually the repair's:
# skipped, which then ended the count of the gate's failures at zero, or, while
# it runs, in progress, which would tell the very repair asking that the gate is
# still running. Any other workflow's failures there spend the ceiling.
#
# Where the runs cannot be read, the direction is fixed. No workflow named, or
# one the repository does not have (gh answers 404 and prints nothing), or any
# other gh failure, returns non-zero with nothing printed. An empty --workflow
# is no filter to gh, so it is never passed through. And an unreadable count is
# never zero: a ceiling that reads as unspent whenever the network does not
# answer bounds nothing.

# The gate's failures on this branch since its last success: the attempts the
# ceiling has already spent.
#
# Only a success resets the count. failure and timed_out count, and so do
# startup_failure and any conclusion this code has not met. A run that ended
# without a verdict (cancelled, skipped, neutral, stale, action_required) is
# passed over like one still going, and neither spends the ceiling nor resets
# it. Until 2026-09-23 each of those ended the count, so failure, cancelled,
# failure, failure read as one attempt and not three, and a gate that cancels
# in progress, or anyone cancelling a run, could keep an unattended loop from
# ever reaching its ceiling.
#
# startup_failure counts because the gate did not pass. A workflow file the
# change carries can cause one as surely as a test can fail, and passing it
# over would bound the loop only while something else refuses to repair from
# such a run. A run that failed to start for a reason no change caused spends
# the ceiling too, and what that costs is stopping early, which is the
# direction the ceiling errs in.
#
# The window is the newest 100 runs, one page of GitHub's API; one more is
# asked for to tell a full window from a history that ends there. Passing a
# run over spends the window and not the count, so a window that ends before
# a success and before the ceiling is a count nobody finished. It is refused,
# not read as the attempts it happened to see. A branch whose whole gate
# history fits in the window is counted to its first run. gh prints the length
# first, because a run still going prints an empty line, and trailing ones do
# not survive the substitution to be counted.
felix_repair_attempts() {
  local branch="$1" repo="$2" workflow="${3:-}" window=100 n=0 total c runs
  [ -n "$workflow" ] || return 1
  runs="$(gh run list --repo "$repo" --branch "$branch" --workflow "$workflow" --limit "$((window + 1))" \
            --json conclusion -q 'length, .[].conclusion' 2>/dev/null)" || return 1
  {
    read -r total
    case "$total" in ''|*[!0-9]*) return 1 ;; esac
    while read -r c; do
      case "$c" in
        success) printf '%s' "$n"; return 0 ;;
        ""|cancelled|skipped|neutral|stale|action_required) continue ;;
        *) n=$((n+1)) ;;
      esac
    done
  } <<EOF
$runs
EOF
  [ "$total" -le "$window" ] || [ "$n" -ge "$FELIX_REPAIR_MAX" ] || return 1
  printf '%s' "$n"
}

# The newest gate run on the branch, or nothing when the gate has not run
# there. `.[0]` of an empty list is null, and interpolating null printed
# `null<TAB>null<TAB>-`, which the caller read as a run still in progress.
felix_repair_latest() {
  local branch="$1" repo="$2" workflow="${3:-}"
  [ -n "$workflow" ] || return 1
  gh run list --repo "$repo" --branch "$branch" --workflow "$workflow" --limit 1 \
    --json databaseId,conclusion,status \
    -q '.[0] // empty | "\(.databaseId)\t\(.status)\t\(.conclusion // "-")"' 2>/dev/null
}

# The failing lines, not the whole log. A repair agent handed 4000 lines of
# ANSI-coded setup output spends its context on apt-get.
#
# Non-zero with nothing printed when there is nothing to show: gh failed, or
# answered with a log that is empty once blank lines go. The pipeline's status
# was tail's, 0 either way, and an empty excerpt read as a failure with no
# output and no path in it.
felix_repair_excerpt() {
  local run_id="$1" repo="$2" log out
  log="$(gh run view "$run_id" --repo "$repo" --log-failed 2>/dev/null)" || return 1
  out="$(printf '%s\n' "$log" \
    | sed 's/^[^\t]*\t[^\t]*\t//' \
    | sed 's/^[0-9TZ:.-]*Z //' \
    | grep -vE '^\s*$' \
    | tail -40)"
  [ -n "$out" ] || return 1
  printf '%s\n' "$out"
}
