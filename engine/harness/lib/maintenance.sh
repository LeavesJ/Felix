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
#   The third column is `always`, a capability, or `founder`: a row that comes
#   due exactly as an `always` row does, and that a session cannot clear alone,
#   because it ends in something only the founder decides (the public snapshot
#   needs his yes). Everything that names what is due also names whose it is
#   (audit C038): felix_maint_founder lists those rows.

# felix_end_line lives in resolve.sh, which the CLI and the hooks source first.
# Sourced here too rather than assumed: missing, the record below would fail
# every time and say only that the log was not written.
if ! command -v felix_end_line >/dev/null 2>&1; then
  . "$(dirname "${BASH_SOURCE[0]:-$0}")/resolve.sh"
fi

_felix_maint_rows() {
  local proj="$1"
  [ -f "$proj/maintenance.tsv" ] || return 0
  LC_ALL=C grep -vE '^\s*(#|$)' "$proj/maintenance.tsv"
}

_felix_maint_last() {   # epoch of the most recent run, or empty
  local proj="$1" name="$2" line last=""
  [ -f "$proj/maintenance.log" ] || return 0
  # A last line with no newline is a run too, and the loop dropped it, so the
  # routine it recorded read as due again (2026-10-01).
  while IFS=$'\t' read -r n epoch _ || [ -n "${n:-}" ]; do
    [ "${n:-}" = "$name" ] && last="$epoch"
  done < "$proj/maintenance.log"
  printf '%s' "$last"
}

# The names of the rows whose third column is `founder`, one a line.
felix_maint_founder() {
  local proj="$1"
  [ -f "$proj/maintenance.tsv" ] || return 0
  LC_ALL=C awk -F'\t' '/^[ \t]*(#|$)/ { next } $3 == "founder" { print $1 }' "$proj/maintenance.tsv"
}

felix_maint_record() {
  local proj="$1" name="$2" now
  now="$(date +%s)"
  # The log is committed, and a hand-merge can drop its final newline. This run
  # then fused onto that last line, and the reader took the line's first name
  # and epoch, so the run just recorded was never read (2026-10-01). Not
  # ended, no row is written and the caller says so.
  felix_end_line "$proj/maintenance.log" || return 1
  printf '%s\t%s\t%s\n' "$name" "$now" "$(date -r "$now" +%Y-%m-%d 2>/dev/null || date +%Y-%m-%d)" \
    >> "$proj/maintenance.log"
}

# Emits: status <TAB> name <TAB> days-since <TAB> cadence <TAB> description
# status is due | ok | inflight | event | unchecked | dormant | unknown
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
# Emits: name <TAB> capability, one line per unreachable row, and
# name <TAB> capability <TAB> unknown when the declared list could not be read
# at all.
#
# Until 2026-10-01 the list was read here with felix_has_line over
# $(felix_declared), so a list that could not be read said "nothing declares
# it", the same claim as a list that was read and does not. The row is now
# asked of _felix_cap_active, whose status 2 is the third column.
FELIX_MAINT_CAPABILITIES='ci deploy iac observability billing e2e database api frontend llm rust tests secrets'

felix_maint_unreachable() {
  local proj="$1" name cadence cap desc rc
  [ -f "$proj/maintenance.tsv" ] || return 0
  # The last routine is kept when it has no newline, as _felix_maint_last keeps
  # the log's last run: dropped, an unreachable routine written last by hand
  # was never reported (2026-10-01).
  while IFS=$'\t' read -r name cadence cap desc || [ -n "${name:-}" ]; do
    case "$name" in ''|'#'*) continue ;; esac
    [ -n "${cap:-}" ] || continue
    [ "$cap" = "always" ] && continue
    [ "$cap" = "founder" ] && continue
    case " $FELIX_MAINT_CAPABILITIES " in *" $cap "*) continue ;; esac
    _felix_cap_active "$cap" "$proj" 2>/dev/null; rc=$?
    case "$rc" in
      0) continue ;;
      1) printf '%s\t%s\n' "$name" "$cap" ;;
      *) printf '%s\t%s\tunknown\n' "$name" "$cap" ;;
    esac
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
command -v felix_final_filter_lead >/dev/null 2>&1 \
  || . "$(dirname "${BASH_SOURCE[0]:-$0}")/final-filter.sh"

# Each row as five cells, and a sixth: `-`, or why its check is refused. A
# check only runs on an event row, so only there is it judged (final-filter.sh
# reads the cadence as the runner below does).
_felix_maint_judged() {
  _felix_maint_rows "$1" | felix_final_filter_lead maintenance.tsv \
    | awk -F'\t' '{ printf "%s\t%s\t%s\t%s\t%s\t%s\n", $2, $3, $4, $5, (NF >= 6 ? $6 : "-"), $1 }'
}

# name <TAB> why, for every row whose check is refused.
felix_maint_malformed() {
  _felix_maint_judged "$1" | awk -F'\t' '$6 != "-" && $1 != "" { print $1 "\t" $6 }'
  return 0
}

# The engine a check runs beside, so a row can call one of its scripts as
# "$FELIX_HARNESS_DIR/bin/...". Taken when this file is sourced, from where it
# was sourced: the deployed engine in a session, the copy under test in the
# suite, and never the checkout the session stands in, whose engine may be
# older or absent.
FELIX_MAINT_HARNESS="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")/.." 2>/dev/null && pwd)"

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
#
# A check that passes may also say why the work is not due although it is not
# done: a pushed branch already does it. Folding handoff sections is upkeep, so
# the row asking for it was read by every session at once, and on 2026-09-24/25
# three sessions folded overlapping sections where one could land.
# Its check now passes when a fold is in flight and prints the branch, and the
# row reads `inflight`, holding what it printed, so the session start names
# that branch instead of asking a second session to start the same fold.
#
# Only a passing check is read that way. A failing one is due whatever it
# printed: output may explain a row that is not due, and nothing a check
# prints can take a row off the due list, because a check that fails while
# saying something (an error, a line from grep) must stay loud. Dueness is the
# exit status alone, exactly as before. stderr is still thrown away.
#
# Emits, for that row: inflight <TAB> name <TAB> holders <TAB> 0 <TAB> description,
# the holders being its non-empty lines joined by "; ", a tab read as a space
# and every other control byte dropped. A holder goes into the session start's
# JSON, whose escaping knows only \\, ", \n, \r and \t, and one escape byte
# from a check made the whole hook output unreadable.
#
# A check a final filter makes unable to fail (final-filter.sh) is the same
# lesson again: the `bash -c` runs it without pipefail, so it reads `ok`
# whatever it asked and the row is never due. It is not run. The row reads
# `due` with `refused` where the reason goes, because `due` is the one word the
# hooks and pulse surface, and felix_maint_malformed says why.
felix_maint_status() {
  local proj="$1" root="${2:-}" now; now="$(date +%s)"
  # awk rather than `IFS=$'\t' read`, for the reason procedures.sh records: tab
  # is an IFS whitespace character and an empty cell shifts every later column
  # left. Rows written before this column existed have four fields and must
  # keep working, so the fifth is filled with `-` when absent. The sixth is `-`
  # or why the check is refused.
  _felix_maint_judged "$proj" | while IFS= read -r line; do
    local name cadence cap desc check ff rc
    name="$(printf '%s\n' "$line" | LC_ALL=C cut -f1)"
    cadence="$(printf '%s\n' "$line" | LC_ALL=C cut -f2)"
    cap="$(printf '%s\n' "$line" | LC_ALL=C cut -f3)"
    desc="$(printf '%s\n' "$line" | LC_ALL=C cut -f4)"
    check="$(printf '%s\n' "$line" | LC_ALL=C cut -f5)"
    ff="$(printf '%s\n' "$line" | LC_ALL=C cut -f6)"
    [ -n "${name:-}" ] || continue
    # Until 2026-10-01 this was `! _felix_cap_active`, so a declared list that
    # could not be read (status 2) printed `dormant`, a routine that may be due
    # said to be not yet. It is `unknown` now, never due: `due` is what session
    # start's "Maintenance due" line, the stop hook's overnight list, next.sh
    # rank 4 and pulse act on, and a false due sends someone to work that may
    # not apply. The `unchecked` precedent, a row that could not be asked being
    # its own word. Its check is not run and its last run is not read.
    if [ "${cap:-always}" = founder ]; then rc=0; else _felix_cap_active "${cap:-always}" "$proj"; rc=$?; fi
    case "$rc" in
      0) ;;
      1) printf 'dormant\t%s\t-\t%s\t%s\n' "$name" "${cadence:-0}" "$desc"; continue ;;
      *) printf 'unknown\t%s\t-\t%s\t%s\n' "$name" "${cadence:-0}" "$desc"; continue ;;
    esac
    if [ "${cadence:-0}" -eq 0 ] 2>/dev/null; then
      if [ -n "$check" ] && [ "$check" != "-" ] && [ "$ff" != "-" ]; then
        printf 'due\t%s\trefused\t0\t%s\n' "$name" "$desc"; continue
      fi
      if [ -n "$check" ] && [ "$check" != "-" ]; then
        if [ -n "$root" ] && [ -d "$root" ]; then
          local said held
          if said="$(cd "$root" && FELIX_HARNESS_DIR="$FELIX_MAINT_HARNESS" bash -c "$check" felix-maint </dev/null 2>/dev/null)"; then
            held="$(printf '%s\n' "$said" | LC_ALL=C tr '\t' ' ' | LC_ALL=C tr -d '\000-\010\013-\037\177' \
                      | LC_ALL=C awk 'NF { printf "%s%s", s, $0; s = "; " }')"
            if [ -n "$held" ]; then
              printf 'inflight\t%s\t%s\t0\t%s\n' "$name" "$held" "$desc"
            else
              printf 'ok\t%s\t-\t0\t%s\n' "$name" "$desc"
            fi
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
