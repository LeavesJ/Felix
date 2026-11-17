# A ceiling on unattended work.
#
# The reason a spend cap matters is not the money, it is that a loop nobody is
# watching can repeat a mistake all night. A dollar limit is a poor shape for
# that: it fails mid-task at an arbitrary boundary, and on some plans it is not
# available at all.
#
# A count of invocations per day fails closed on the behaviour actually worth
# fearing, which is repetition, and it fails between runs rather than during one.
# Ten deliberate attempts in a day is a working system. Two hundred is a loop,
# whatever each one cost.
#
# The log is durable state in the project directory. A ceiling tracked in a
# runner's ephemeral filesystem resets every job, which is the same as no
# ceiling, and it resets invisibly.

# felix_end_line lives in resolve.sh, which the CLI and the hooks source first.
# Sourced here too rather than assumed: missing, the record below would fail
# every time and say only that the log was not written.
if ! command -v felix_end_line >/dev/null 2>&1; then
  . "$(dirname "${BASH_SOURCE[0]:-$0}")/resolve.sh"
fi

FELIX_BUDGET_DEFAULT="${FELIX_BUDGET_DEFAULT:-10}"

felix_budget_limit() {
  local proj="$1" v
  v="$(felix_json_str "$proj/project.json" unattended_daily_limit 2>/dev/null)"
  case "$v" in
    ''|*[!0123456789]*) printf '%s' "$FELIX_BUDGET_DEFAULT" ;;
    *) printf '%s' "$v" ;;
  esac
}

# Invocations recorded in the last 24 hours.
felix_budget_used() {
  local proj="$1" now cutoff n=0 epoch _
  [ -f "$proj/budget.log" ] || { printf '0'; return; }
  now="$(date +%s)"; cutoff=$((now - 86400))
  # A last line with no newline is a run too. `read` returns 1 on it with the
  # fields filled, and the loop dropped it, so a hand-merged log counted one
  # run short and the ceiling bound one run late (2026-10-01).
  while IFS=$'\t' read -r epoch _ || [ -n "${epoch:-}" ]; do
    case "$epoch" in ''|*[!0123456789]*) continue ;; esac
    [ "$epoch" -ge "$cutoff" ] && n=$((n+1))
  done < "$proj/budget.log"
  printf '%s' "$n"
}

# The status of this function is load-bearing and must stay that way.
#
# A failed redirection already makes the command non-zero, in a function as much
# as at top level, so this reports a failed write correctly and always has. The
# defect #84 names was never here: cmd_budget DISCARDED the status and then
# printed a count it had worked out in advance. Worth being exact about, because
# "the append is unchecked" was the diagnosis and it was wrong about which line.
#
# What that means for anyone editing this: the status is carried by the last
# command, so appending anything after the redirection - a log line, a chmod, a
# `true` - silently makes this function always succeed, and the ceiling goes
# back to not binding. There is no assertion that can see such an edit coming;
# the one in the suite pins the behaviour, not the shape.
felix_budget_record() {
  local proj="$1" why="${2:-unattended run}" now
  now="$(date +%s)"
  # Before the append, never after it, for the reason above. A budget.log whose
  # last line has no newline took this run onto that line, so two runs read as
  # one and the ceiling undercounted (2026-10-01). Not ended, this is a failed
  # write like any other, and cmd_budget refuses the run.
  felix_end_line "$proj/budget.log" || return 1
  printf '%s\t%s\t%s\n' "$now" "$(date -r "$now" +%Y-%m-%dT%H:%M 2>/dev/null || date +%Y-%m-%dT%H:%M)" "$why" \
    >> "$proj/budget.log"
}
