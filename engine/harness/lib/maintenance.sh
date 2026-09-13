# Scheduled maintenance.
#
# Maintenance is the work that never has a deadline, so it never happens, and
# then happens all at once as a crisis. Putting it on a clock is the whole point
# of the guidebook's table on p10.
#
# Felix tracks what is due and refuses to lose track. It does not perform the
# routines: cleaning dead code and grouping dependency updates are judgment, and
# a script that did them unattended would produce exactly the flood of
# unreviewable pull requests the guidebook warns against.
#
# The last-run log is durable state in the project directory, committed like
# everything else, because a cadence tracked in a scratch file resets the first
# time someone works from a different machine and quietly reports everything as
# never-run.
#
# Times are stored as epoch seconds. Parsing a date back is where portability
# goes to die: BSD date wants -j -f, GNU date wants -d, and a maintenance tracker
# that only works on the author's laptop is not a tracker.
#
# maintenance.tsv rows: name <TAB> cadence-days <TAB> capability <TAB> description
#   cadence 0 means event-driven, never on a clock.

_felix_maint_rows() {
  local proj="$1"
  [ -f "$proj/maintenance.tsv" ] || return 0
  grep -vE '^\s*(#|$)' "$proj/maintenance.tsv"
}

_felix_maint_last() {   # epoch of the most recent run, or empty
  local proj="$1" name="$2" line last=""
  [ -f "$proj/maintenance.log" ] || return 0
  while IFS=$'\t' read -r n epoch _; do
    [ "${n:-}" = "$name" ] && last="$epoch"
  done < "$proj/maintenance.log"
  printf '%s' "$last"
}

felix_maint_record() {
  local proj="$1" name="$2" now
  now="$(date +%s)"
  printf '%s\t%s\t%s\n' "$name" "$now" "$(date -r "$now" +%Y-%m-%d 2>/dev/null || date +%Y-%m-%d)" \
    >> "$proj/maintenance.log"
}

# Emits: status <TAB> name <TAB> days-since <TAB> cadence <TAB> description
# status is due | ok | event | dormant
# Upkeep rows that can never come due.
#
# The capability column takes `always` or a capability name. Anything else
# resolves to dormant, and dormant renders as a dash next to "Nothing due" —
# which is indistinguishable from a well-kept repository. Felix's own table used
# `-` in that column for four routines that had therefore never run and never
# could, and the report said nothing was outstanding every single time.
#
# A row naming a REAL capability the project has not declared is not an error:
# that is a dormant row working as designed, and flagging it would turn this
# into noise. Only a name that is not a capability at all is caught, because
# that is a typo wearing a dash.
#
# Emits: name <TAB> capability, one line per unreachable row.
FELIX_MAINT_CAPABILITIES='ci deploy iac observability billing e2e database api frontend llm rust tests secrets'

felix_maint_unreachable() {
  local proj="$1" name cadence cap desc
  [ -f "$proj/maintenance.tsv" ] || return 0
  while IFS=$'\t' read -r name cadence cap desc; do
    case "$name" in ''|'#'*) continue ;; esac
    [ -n "${cap:-}" ] || continue
    [ "$cap" = "always" ] && continue
    case " $FELIX_MAINT_CAPABILITIES " in *" $cap "*) continue ;; esac
    felix_has_line "$(felix_declared "$proj")" "$cap" 2>/dev/null && continue
    printf '%s\t%s\n' "$name" "$cap"
  done < "$proj/maintenance.tsv"
}

# Sourced rather than assumed, the way escape.sh, probes.sh and facts.sh do it.
# _felix_cap_active lives in stack.sh and is shared with setup.sh; sourced from
# a caller that did not load stack.sh, this file did not error — it printed
# "command not found" to a redirected stderr and then read every row as
# `dormant`, which renders as a dash beside "Nothing due". A missing helper
# that reads as a well-kept repository is the direction every verifier here
# must not fail in, and it was found by the first test that loaded this lib on
# its own. stack.sh's one top-level statement is a constant.
if ! command -v _felix_cap_active >/dev/null 2>&1; then
  . "$(dirname "${BASH_SOURCE[0]:-$0}")/stack.sh"
fi

# The fifth column, and why it exists.
#
# A cadence of 0 means event-driven, and the format's own words are that such
# a row "is never reported as overdue". One governed project has carried
# `graphify  0  always  refresh the relationship map after a major merge` since
# 2026-08-19. Its graph was built that day and never again; fifteen days and
# two merges later the row still read `event`, and the founder found out by
# asking why the map was never updated. A row that can never come due is the
# lesson this project already holds — "nothing due" and "nothing is being
# checked" rendering identically — one table over.
#
# So an event row may carry a CHECK: a command run in the checkout, exit 0
# meaning "not due" and anything else meaning "due". Reality decides, not a
# clock. A check that cannot run is non-zero, so a broken check is loud rather
# than a quiet `ok`, which is the direction every verifier here fails in.
#
# Evaluated only where a checkout is known, and said so when it is not. An
# earlier draft let a checked row fall through to `event` when no root was
# given, reasoning that this "says nothing false, because it is not claiming
# the check passed, only that it was not asked". True of this function and
# false of its readers: `event` is also what an unchecked row emits, so at the
# rendering layer "nobody asked" and "there is nothing to ask" became the same
# line — and `felix pulse`, which keeps only `due`, dropped both. That is the
# graphify lesson a second time, one layer down. So the two are now different
# words, and a reader that cannot use `unchecked` at least cannot mistake it
# for a row that answered.
felix_maint_status() {
  local proj="$1" root="${2:-}" now; now="$(date +%s)"
  # awk rather than `IFS=$'\t' read`, for the reason procedures.sh records: tab
  # is an IFS whitespace character and an empty cell shifts every later column
  # left. Rows written before this column existed have four fields and must
  # keep working, so the fifth is filled with `-` when absent.
  _felix_maint_rows "$proj" \
    | awk -F'\t' '{ printf "%s\t%s\t%s\t%s\t%s\n", $1, $2, $3, $4, (NF >= 5 ? $5 : "-") }' \
    | while IFS= read -r line; do
    local name cadence cap desc check
    name="$(printf '%s\n' "$line" | cut -f1)"
    cadence="$(printf '%s\n' "$line" | cut -f2)"
    cap="$(printf '%s\n' "$line" | cut -f3)"
    desc="$(printf '%s\n' "$line" | cut -f4)"
    check="$(printf '%s\n' "$line" | cut -f5)"
    [ -n "${name:-}" ] || continue
    if ! _felix_cap_active "${cap:-always}" "$proj"; then
      printf 'dormant\t%s\t-\t%s\t%s\n' "$name" "${cadence:-0}" "$desc"; continue
    fi
    if [ "${cadence:-0}" -eq 0 ] 2>/dev/null; then
      if [ -n "$check" ] && [ "$check" != "-" ]; then
        if [ -n "$root" ] && [ -d "$root" ]; then
          if ( cd "$root" && bash -c "$check" felix-maint </dev/null >/dev/null 2>&1 ); then
            printf 'ok\t%s\t-\t0\t%s\n' "$name" "$desc"
          else
            printf 'due\t%s\tcheck\t0\t%s\n' "$name" "$desc"
          fi
        else
          printf 'unchecked\t%s\t-\t0\t%s\n' "$name" "$desc"
        fi
        continue
      fi
      printf 'event\t%s\t-\t0\t%s\n' "$name" "$desc"; continue
    fi
    local last age days
    last="$(_felix_maint_last "$proj" "$name")"
    if [ -z "$last" ]; then
      printf 'due\t%s\tnever\t%s\t%s\n' "$name" "$cadence" "$desc"; continue
    fi
    age=$(( (now - last) / 86400 ))
    if [ "$age" -ge "$cadence" ]; then days="due"; else days="ok"; fi
    printf '%s\t%s\t%s\t%s\t%s\n' "$days" "$name" "$age" "$cadence" "$desc"
  done
}
