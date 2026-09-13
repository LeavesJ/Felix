# The bounded repair loop.
#
# Felix does not fix anything here. It supplies the deterministic scaffolding a
# repair loop needs and refuses to be the part that requires judgment: fetch the
# failure, extract what actually broke, count how many attempts have already been
# spent, and enforce the ceiling. Diagnosis and the patch are the agent's job.
#
# The ceiling is the point. The guidebook (p8) asks for a bounded loop, because
# an agent that retries indefinitely burns money converging on nothing and looks
# busy the entire time. After FELIX_REPAIR_MAX consecutive failures the answer
# stops being "try again" and becomes "a human needs to look at this."
#
# Attempts are counted from CI history rather than a local counter, so the count
# survives a new session, a different machine, and a cleared scratch directory.
# A counter that resets when the agent restarts cannot bound anything.
#
# GitHub Actions only for now, via gh. Stated plainly rather than hidden behind a
# provider abstraction with one implementation.

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

# Consecutive failures at the head of this branch's run history.
felix_repair_attempts() {
  local branch="$1" repo="$2" n=0 c
  while read -r c; do
    case "$c" in
      failure|timed_out) n=$((n+1)) ;;
      "") continue ;;
      *) break ;;
    esac
  done <<EOF
$(gh run list --repo "$repo" --branch "$branch" --limit 10 \
    --json conclusion -q '.[].conclusion' 2>/dev/null)
EOF
  printf '%s' "$n"
}

felix_repair_latest() {
  local branch="$1" repo="$2"
  gh run list --repo "$repo" --branch "$branch" --limit 1 \
    --json databaseId,conclusion,status -q '.[0] | "\(.databaseId)\t\(.status)\t\(.conclusion // "-")"' 2>/dev/null
}

# The failing lines, not the whole log. A repair agent handed 4000 lines of
# ANSI-coded setup output spends its context on apt-get.
felix_repair_excerpt() {
  local run_id="$1" repo="$2"
  gh run view "$run_id" --repo "$repo" --log-failed 2>/dev/null \
    | sed 's/^[^\t]*\t[^\t]*\t//' \
    | sed 's/^[0-9TZ:.-]*Z //' \
    | grep -vE '^\s*$' \
    | tail -40
}
