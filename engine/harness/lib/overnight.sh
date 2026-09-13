# Overnight: the standing direction a founder should never have to type twice.
#
# The founder has now given the same four instructions at the start of every
# long unattended session: keep going rather than stopping to report, skip what
# needs my permission and collect it for the morning, verify with the gate, and
# keep building. Repeating a standing direction is precisely the thing this
# project's charter calls a Felix failure — if the founder is thinking about
# tooling, Felix has not done its job — so it belongs in a mechanism.
#
# WHAT THIS CHANGES, AND WHAT IT DELIBERATELY DOES NOT.
#
# It changes the response to a boundary, never the boundary. Nothing here
# widens what a session may do: deny.tsv still refuses, the gate still gates,
# risk.tsv's channels still stop a merge, and anything irreversible still waits
# for a person. What changes is what happens WHEN one of those stops the work.
# Attended, the session stops and asks. Overnight, it defers — writes down what
# was blocked, which boundary blocked it, and the exact command that would
# unblock it — and then goes to the next thing. The queue is the deliverable,
# and the morning report is how a person spends five minutes instead of
# reconstructing a night.
#
# It also refuses to let a session close while granted time and work both
# remain. That lever already exists and is already honest about its reach: the
# Stop hook blocks by returning a decision, the platform sets stop_hook_active
# and caps consecutive blocks, so this interrupts once per chain. It is a
# nudge with a record, not a treadmill, and it cannot become an infinite loop
# because the platform will not let it.
#
# THE BOUNDS, BECAUSE AN UNBOUNDED LOOP IS A DEFECT AND NOT A FEATURE.
#
# Three, and whichever arrives first ends the mode:
#   * a deadline in wall-clock time, because "overnight" is a duration;
#   * a count of continuations, because a session looping on nothing should
#     stop looping;
#   * two consecutive continuations that found nothing to do, because there is
#     no virtue in staying awake over an empty queue.
# `felix overnight --end` is a person's way out, and closing the session is
# always available — nothing here survives a closed terminal, and nothing here
# runs while no session is open.
#
# WHAT IT CANNOT DO, STATED SO NOBODY BUILDS ON A WISH.
#
# Felix cannot make a model take a turn. Invariant 2 keeps every hook to bash
# and git, so this file can prepare context, refuse a quiet close, and write a
# record; the turns themselves come from a session somebody started. Overnight
# mode lays the rails. It does not drive the train, and a night with nobody's
# session open is a night where nothing happens.

FELIX_OVERNIGHT_DEFAULT_HOURS="${FELIX_OVERNIGHT_DEFAULT_HOURS:-8}"
FELIX_OVERNIGHT_DEFAULT_TURNS="${FELIX_OVERNIGHT_DEFAULT_TURNS:-40}"
# A ceiling on the grant itself. A typo of --hours 800 should not hand a
# session a month of licence, and the founder can always start another night.
FELIX_OVERNIGHT_MAX_HOURS="${FELIX_OVERNIGHT_MAX_HOURS:-16}"
# Consecutive continuations that found nothing to do before the night ends.
FELIX_OVERNIGHT_QUIET_LIMIT="${FELIX_OVERNIGHT_QUIET_LIMIT:-2}"

felix_overnight_dir() {   # proj -> the directory holding this project's night
  printf '%s/overnight' "$(felix_mem_dir "$1")"
}

_felix_overnight_state()    { printf '%s/active'       "$(felix_overnight_dir "$1")"; }
_felix_overnight_deferred() { printf '%s/deferred.tsv' "$(felix_overnight_dir "$1")"; }
_felix_overnight_log()      { printf '%s/log.tsv'      "$(felix_overnight_dir "$1")"; }

# The state file is one line, and it is deliberately not JSON: every reader
# here is bash, and a hand-rolled JSON reader in a hook is how this project has
# broken things before.
#
#   started <TAB> deadline <TAB> turns-left <TAB> quiet-runs <TAB> session <TAB> note
#
# `quiet-runs` counts consecutive continuations that found nothing to do. It is
# stored rather than derived because the hook that increments it cannot see the
# one before it.
felix_overnight_field() {   # proj, field-number -> value
  local f; f="$(_felix_overnight_state "$1")"
  [ -f "$f" ] || return 1
  cut -f"$2" < "$f" 2>/dev/null | head -1
}

felix_overnight_now() { date +%s; }

# Active means granted AND still inside every bound. A caller that only wants
# to know whether a grant exists asks for the file; everything else asks this,
# because a grant whose deadline has passed is not a licence.
felix_overnight_active() {   # proj -> 0 when the night is live
  local proj="$1" deadline turns quiets now
  [ -f "$(_felix_overnight_state "$proj")" ] || return 1
  deadline="$(felix_overnight_field "$proj" 2)" || return 1
  turns="$(felix_overnight_field "$proj" 3)" || return 1
  quiets="$(felix_overnight_quiets "$proj")"
  now="$(felix_overnight_now)"
  case "$deadline$turns" in *[!0-9]*|'') return 1 ;; esac
  [ "$now" -lt "$deadline" ] || return 1
  [ "$turns" -gt 0 ] || return 1
  [ "$quiets" -lt "$FELIX_OVERNIGHT_QUIET_LIMIT" ] || return 1
  return 0
}

# Why the night is over, in the words a report should use. Nothing when it is
# not over, and nothing when there is no night at all — those are different
# facts and a reader that cannot tell them apart is the defect this project
# keeps finding.
felix_overnight_expired() {   # proj -> reason, or nothing
  local proj="$1" deadline turns quiets now
  [ -f "$(_felix_overnight_state "$proj")" ] || return 1
  deadline="$(felix_overnight_field "$proj" 2)"; turns="$(felix_overnight_field "$proj" 3)"
  quiets="$(felix_overnight_quiets "$proj")"
  now="$(felix_overnight_now)"
  case "$deadline$turns" in *[!0-9]*|'') printf 'the state file is unreadable'; return 0 ;; esac
  [ "$now" -ge "$deadline" ] && { printf 'the granted time ran out'; return 0; }
  [ "$turns" -le 0 ] && { printf 'the granted continuations ran out'; return 0; }
  [ "$quiets" -ge "$FELIX_OVERNIGHT_QUIET_LIMIT" ] && { printf 'two continuations in a row found nothing to do'; return 0; }
  return 1
}

felix_overnight_log_event() {   # proj, event, detail
  local f; f="$(_felix_overnight_log "$1")"
  mkdir -p "$(dirname "$f")" 2>/dev/null || return 0
  printf '%s\t%s\t%s\n' "$(felix_overnight_now)" "$2" "${3:-}" >> "$f" 2>/dev/null || true
}

felix_overnight_start() {   # proj, hours, turns, session, note -> 0, or 1 with a reason on stdout
  local proj="$1" hours="${2:-$FELIX_OVERNIGHT_DEFAULT_HOURS}" turns="${3:-$FELIX_OVERNIGHT_DEFAULT_TURNS}"
  local sid="${4:-}" note="${5:-}" now deadline dir
  case "$hours" in ''|*[!0-9]*) printf 'hours must be a whole number of hours'; return 1 ;; esac
  case "$turns" in ''|*[!0-9]*) printf 'turns must be a whole number'; return 1 ;; esac
  [ "$hours" -ge 1 ] || { printf 'a night shorter than an hour is a normal session'; return 1; }
  [ "$hours" -le "$FELIX_OVERNIGHT_MAX_HOURS" ] || {
    printf 'the ceiling is %s hours; start another night rather than one long one' "$FELIX_OVERNIGHT_MAX_HOURS"; return 1; }
  [ "$turns" -ge 1 ] || { printf 'a night with no continuations cannot continue anything'; return 1; }

  now="$(felix_overnight_now)"; deadline=$(( now + hours * 3600 ))
  dir="$(felix_overnight_dir "$proj")"
  mkdir -p "$dir" 2>/dev/null || { printf 'cannot write %s' "$dir"; return 1; }
  # Tabs and newlines out of the note, because the state is one TSV line and a
  # note that breaks it would make the night unreadable rather than invalid.
  note="$(printf '%s' "$note" | tr '\t\n' '  ')"
  printf '%s\t%s\t%s\t0\t%s\t%s\n' "$now" "$deadline" "$turns" "${sid:--}" "$note" \
    > "$(_felix_overnight_state "$proj")" 2>/dev/null || { printf 'cannot write the state file'; return 1; }
  felix_overnight_log_event "$proj" start "${hours}h ${turns} continuations"
  return 0
}

felix_overnight_end() {   # proj, reason -> 0 whether or not one was running
  local proj="$1" reason="${2:-ended}" f
  f="$(_felix_overnight_state "$proj")"
  [ -f "$f" ] || return 0
  felix_overnight_log_event "$proj" end "$reason"
  rm -f "$f" 2>/dev/null || true
  return 0
}

# Spend one continuation. Prints what is left, and the caller decides what to
# do with zero; ending the night here would hide the last continuation from the
# reader that asked for it.
felix_overnight_spend() {   # proj, quiet(0|1) -> remaining
  local proj="$1" quiet="${2:-0}" started deadline turns quiets sid note
  local f; f="$(_felix_overnight_state "$proj")"
  [ -f "$f" ] || { printf '0'; return 1; }
  IFS=$'\t' read -r started deadline turns quiets sid note < "$f" 2>/dev/null || true
  case "$turns" in ''|*[!0-9]*) turns=0 ;; esac
  case "$quiets" in ''|*[!0-9]*) quiets=0 ;; esac
  [ "$turns" -gt 0 ] && turns=$(( turns - 1 ))
  if [ "$quiet" = "1" ]; then quiets=$(( quiets + 1 )); else quiets=0; fi
  printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$started" "$deadline" "$turns" "$quiets" "$sid" "$note" \
    > "$f" 2>/dev/null || true
  printf '%s' "$turns"
  return 0
}

felix_overnight_quiets() {   # proj -> consecutive continuations that found nothing
  local q; q="$(felix_overnight_field "$1" 4 2>/dev/null)"
  case "$q" in ''|*[!0-9]*) printf '0' ;; *) printf '%s' "$q" ;; esac
}

# A boundary a person owns, written down instead of waited on.
#
# kind says which boundary: approval (a risk channel), irreversible, blocked
# (outside this session's reach), or question. `unblock` is the command or the
# decision that clears it, and it is the field that makes the morning short —
# a queue of problems is work, a queue of commands is a checklist.
felix_overnight_defer() {   # proj, kind, what, unblock -> 0
  local proj="$1" kind="$2" what="$3" unblock="${4:-}" f
  [ -n "$kind" ] && [ -n "$what" ] || return 1
  f="$(_felix_overnight_deferred "$proj")"
  mkdir -p "$(dirname "$f")" 2>/dev/null || return 1
  what="$(printf '%s' "$what" | tr '\t\n' '  ')"
  unblock="$(printf '%s' "$unblock" | tr '\t\n' '  ')"
  printf '%s\t%s\t%s\t%s\n' "$(felix_overnight_now)" "$kind" "$what" "$unblock" >> "$f" 2>/dev/null || return 1
  felix_overnight_log_event "$proj" defer "$kind: $what"
  return 0
}

felix_overnight_deferred_rows() {   # proj -> the queue, oldest first
  local f; f="$(_felix_overnight_deferred "$1")"
  [ -f "$f" ] || return 0
  grep -vE '^[[:space:]]*(#|$)' "$f" 2>/dev/null
  return 0
}

felix_overnight_deferred_count() {   # proj -> how many decisions are waiting
  local n; n="$(felix_overnight_deferred_rows "$1" | grep -c . 2>/dev/null)"
  case "${n:-}" in ''|*[!0-9]*) printf '0' ;; *) printf '%s' "$n" ;; esac
}

# The queue is cleared by a person, not by a session, and clearing is its own
# act so that "I read these" is recorded rather than assumed.
felix_overnight_clear() {   # proj -> 0
  local f; f="$(_felix_overnight_deferred "$1")"
  [ -f "$f" ] || return 0
  felix_overnight_log_event "$1" cleared "$(felix_overnight_deferred_count "$1") row(s)"
  rm -f "$f" 2>/dev/null || true
  return 0
}

# The standing direction, in one place, so the hook that mounts it and the
# command that prints it cannot drift apart.
felix_overnight_direction() {
  cat <<'EOF'
Overnight is on. The founder is asleep; these are standing and do not need
asking again:

  * Keep going. Finish a piece, verify it, ship it, take the next one. Do not
    stop to report progress — the morning report is the report.
  * Defer, do not wait. When something needs the founder — an approval channel,
    anything irreversible, a question only they can answer — write it down with
    felix overnight --defer and move to the next piece of work.
  * Verify everything. The gate before anything is called done, and the
    verification skill before believing what you wrote about it.
  * Every boundary still stands. Overnight changes what you do when you are
    stopped, never what may stop you.
EOF
}

# The morning page. Short by construction: what is waiting on a person, how
# much of the night is left, and what the night did, counted from its own log
# rather than from a summary somebody wrote.
felix_overnight_report() {   # proj -> prose on stdout
  local proj="$1" f started deadline turns quiets sid note now n
  f="$(_felix_overnight_state "$proj")"
  printf 'overnight report for %s\n\n' "$(basename "$proj")"

  if [ -f "$f" ]; then
    IFS=$'\t' read -r started deadline turns quiets sid note < "$f" 2>/dev/null || true
    now="$(felix_overnight_now)"
    printf '  started    %s\n' "$(date -r "$started" '+%Y-%m-%d %H:%M' 2>/dev/null || printf '%s' "$started")"
    printf '  deadline   %s\n' "$(date -r "$deadline" '+%Y-%m-%d %H:%M' 2>/dev/null || printf '%s' "$deadline")"
    printf '  left       %s continuation(s), %s hour(s)\n' "$turns" "$(( (deadline - now) / 3600 ))"
    [ -n "${note:-}" ] && printf '  note       %s\n' "$note"
    local why; why="$(felix_overnight_expired "$proj")" && printf '  over       %s\n' "$why"
  else
    printf '  No night is running. The log below, if there is one, is the last.\n'
  fi

  n="$(felix_overnight_deferred_count "$proj")"
  printf '\nwaiting on you (%s)\n\n' "$n"
  if [ "${n:-0}" -eq 0 ]; then
    printf '  Nothing. Either the night hit no boundary, or it has not started.\n'
  else
    felix_overnight_deferred_rows "$proj" | while IFS=$'\t' read -r when kind what unblock; do
      printf '  [%s] %s\n' "$kind" "$what"
      [ -n "${unblock:-}" ] && printf '        %s\n' "$unblock"
    done
    printf '\n  Clear them once read:  felix overnight --clear\n'
  fi

  local log; log="$(_felix_overnight_log "$proj")"
  if [ -f "$log" ]; then
    printf '\nthe night, by event\n\n'
    awk -F'\t' '{ c[$2]++ } END { for (e in c) printf "  %-10s %s\n", e, c[e] }' "$log" 2>/dev/null
    # The last few continuations in full. A count says how many there were; a
    # reader wants to know whether the night moved or sat on one thing, and
    # that is only visible in what each continuation found.
    if grep -q '	continue	' "$log" 2>/dev/null; then
      printf '\nthe last continuations\n\n'
      grep '	continue	' "$log" 2>/dev/null | tail -5 | while IFS=$'\t' read -r when _ detail; do
        printf '  %s  %s\n' "$(date -r "$when" '+%H:%M' 2>/dev/null || printf '%s' "$when")" "$detail"
      done
    fi
  fi
  return 0
}
