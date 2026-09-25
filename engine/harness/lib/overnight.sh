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
# remain. The Stop hook blocks by returning a decision, and the platform marks
# every stop after a block with stop_hook_active. The hook used to leave at
# that flag before reading anything, so a night held a session once per prompt
# and the budget below could not be spent by a session nobody was typing into:
# the one kind of session a night is for. A session that holds a live night now
# carries on through the flag, bounded by the three bounds below and by
# nothing else of Felix's. The platform keeps a cap of its own on consecutive
# blocks, which its hooks guide mentions without a number, so a night may end
# sooner than its bounds say. The bounds hold per session per day, not per
# grant: a session's own shell can run `felix overnight --start`, and a night
# it could re-grant from inside the chain would be a loop with nothing to end
# it but the model's restraint (see felix_overnight_granted).
#
# THE BOUNDS, BECAUSE AN UNBOUNDED LOOP IS A DEFECT AND NOT A FEATURE.
#
# Three, and whichever arrives first ends the mode:
#   * a deadline in wall-clock time, because "overnight" is a duration;
#   * a count of continuations, because a session looping on nothing should
#     stop looping;
#   * two consecutive continuations that called no tool, because there is
#     no virtue in staying awake over an empty queue.
# `felix overnight --end` is a person's way out, and closing the session is
# always available — nothing here survives a closed terminal, and nothing here
# runs while no session is open.
#
# WHOSE NIGHT IT IS.
#
# A night belongs to the session it was granted to, not to the project. It was
# one file per project at first, with the session id written into it and never
# read. That was harmless while one session ran at a time and wrong once ten
# did: every session in the project was held at every stop, all of them spent
# one shared budget, a second grant overwrote the first, and every session that
# started was told the founder was asleep. A night is keyed now by the session
# id the platform hands every hook, which the session's own shell also sees as
# CLAUDE_CODE_SESSION_ID, and that is where `felix overnight --start` reads it.
#
# So a night needs a session, and one typed in a terminal outside every
# session is refused with the way to type it inside one. Letting the next
# session to start claim it was considered and dropped: the platform starts
# sessions nobody types into (#264), a session is only known to be a person's
# at its first prompt, and a night claimed by one of those is a night nobody
# gets. The one file per project that came before, `active`, is still read,
# swept and ended, so a night granted under an older engine is closed rather
# than stranded, and it holds nobody.
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
# And on its continuations, which have had teeth since a night carries through
# the platform's chain: before, a night could spend one per prompt, and a
# ceiling on a budget nobody could reach bounded nothing.
FELIX_OVERNIGHT_MAX_TURNS="${FELIX_OVERNIGHT_MAX_TURNS:-200}"
# Both ceilings bound what one session is granted in this many seconds, summed
# over every grant, so a second grant is not a way past the first one's.
FELIX_OVERNIGHT_WINDOW="${FELIX_OVERNIGHT_WINDOW:-86400}"
# Consecutive continuations that called no tool before the night ends.
FELIX_OVERNIGHT_QUIET_LIMIT="${FELIX_OVERNIGHT_QUIET_LIMIT:-2}"

felix_overnight_dir() {   # proj -> the directory holding this project's night
  printf '%s/overnight' "$(felix_mem_dir "$1")"
}

_felix_overnight_deferred() { printf '%s/deferred.tsv' "$(felix_overnight_dir "$1")"; }
_felix_overnight_log()      { printf '%s/log.tsv'      "$(felix_overnight_dir "$1")"; }

# Can this id name a file? It arrives in a hook payload, so a path built from it
# unchecked is a write anywhere. A leading dash is refused as well, because a
# dash is what an older engine's state line holds where a session would be.
_felix_overnight_sid_ok() {   # sid -> 0 when it is a usable session id
  case "${1:-}" in ''|.|..|-*|*[!A-Za-z0-9._-]*) return 1 ;; esac
  [ "${#1}" -le 128 ]
}

# The state file of one night: the session's own, or, given no session, the
# project-wide file an older engine wrote. It prints nothing and returns 1 for an id that cannot name a
# file, so `[ -f "$(...)" ]` over a bad id is false rather than a path outside
# the directory.
_felix_overnight_state() {   # proj [, sid] -> path
  local d; d="$(felix_overnight_dir "$1")"
  if [ -z "${2:-}" ]; then printf '%s/active' "$d"; return 0; fi
  _felix_overnight_sid_ok "$2" || return 1
  printf '%s/nights/%s' "$d" "$2"
}

# Where a night's last hold stopped reading the transcript. Kept outside
# nights/ so that directory holds nights and nothing else.
_felix_overnight_mark() {   # proj, sid -> path
  _felix_overnight_sid_ok "${2:-}" || return 1
  printf '%s/marks/%s' "$(felix_overnight_dir "$1")" "$2"
}

# How a log row and a report name a night.
_felix_overnight_whose() {   # sid -> words
  if [ -n "${1:-}" ] && [ "$1" != "-" ]; then
    printf 'session %s' "$(printf '%s' "$1" | cut -c1-8)"
  else
    printf 'project-wide, from an older engine'
  fi
}

# Does this session hold a night, live or ended? Nothing without an id: an
# empty id would otherwise read an older engine's night as this session's own.
felix_overnight_owns() {   # proj, sid -> 0 when it does
  [ -n "${2:-}" ] || return 1
  local f; f="$(_felix_overnight_state "$1" "$2")" || return 1
  [ -f "$f" ]
}

# Every night on record, one id per line: `-` for an older engine's
# project-wide night, then each session's.
felix_overnight_nights() {   # proj -> ids
  local d f; d="$(felix_overnight_dir "$1")"
  [ -f "$d/active" ] && printf -- '-\n'
  for f in "$d"/nights/*; do
    [ -f "$f" ] || continue
    printf '%s\n' "${f##*/}"
  done
  return 0
}

# The state file is one line, and it is deliberately not JSON: every reader
# here is bash, and a hand-rolled JSON reader in a hook is how this project has
# broken things before.
#
#   started <TAB> deadline <TAB> turns-left <TAB> quiet-runs <TAB> session <TAB> note
#
# `quiet-runs` counts consecutive continuations that called no tool. It is
# stored rather than derived because the hook that increments it cannot see the
# one before it.
#
# Every reader takes the session last and optionally. Given one, it reads that
# session's night; given none, an older engine's project-wide night. No reader
# ever falls back from the one to the other, because that fallback is the
# defect this file was rewritten to remove.
felix_overnight_field() {   # proj, field-number [, sid] -> value
  local f; f="$(_felix_overnight_state "$1" "${3:-}")" || return 1
  [ -f "$f" ] || return 1
  cut -f"$2" < "$f" 2>/dev/null | head -1
}

felix_overnight_now() { date +%s; }

# Active means granted AND still inside every bound. A caller that only wants
# to know whether a grant exists asks felix_overnight_owns; everything else
# asks this, because a grant whose deadline has passed is not a licence.
felix_overnight_active() {   # proj [, sid] -> 0 when the night is live
  local proj="$1" sid="${2:-}" f deadline turns quiets now
  f="$(_felix_overnight_state "$proj" "$sid")" || return 1
  [ -f "$f" ] || return 1
  deadline="$(felix_overnight_field "$proj" 2 "$sid")" || return 1
  turns="$(felix_overnight_field "$proj" 3 "$sid")" || return 1
  quiets="$(felix_overnight_quiets "$proj" "$sid")"
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
felix_overnight_expired() {   # proj [, sid] -> reason, or nothing
  local proj="$1" sid="${2:-}" f deadline turns quiets now
  f="$(_felix_overnight_state "$proj" "$sid")" || return 1
  [ -f "$f" ] || return 1
  deadline="$(felix_overnight_field "$proj" 2 "$sid")"; turns="$(felix_overnight_field "$proj" 3 "$sid")"
  quiets="$(felix_overnight_quiets "$proj" "$sid")"
  now="$(felix_overnight_now)"
  case "$deadline$turns" in *[!0-9]*|'') printf 'the state file is unreadable'; return 0 ;; esac
  [ "$now" -ge "$deadline" ] && { printf 'the granted time ran out'; return 0; }
  [ "$turns" -le 0 ] && { printf 'the granted continuations ran out'; return 0; }
  [ "$quiets" -ge "$FELIX_OVERNIGHT_QUIET_LIMIT" ] && { printf 'two continuations in a row called no tool'; return 0; }
  return 1
}

felix_overnight_log_event() {   # proj, event, detail
  local f; f="$(_felix_overnight_log "$1")"
  mkdir -p "$(dirname "$f")" 2>/dev/null || return 0
  printf '%s\t%s\t%s\n' "$(felix_overnight_now)" "$2" "${3:-}" >> "$f" 2>/dev/null || true
}

# A night is granted to a session. A second grant to the same session
# replaces its night, and a grant to another session is another night: neither
# can touch a night that is not its own.
# What a session has been granted in the last window, as "turns hours". Every
# grant is appended to the session's ledger, and the ledger is only read here.
# A session can run `felix overnight --start` from its own shell, and a night
# carries it through the platform's chain, so a grant made from inside the
# chain would reset the budget the chain is bounded by. Summing grants over a
# day is what makes the ceilings a bound on the session and not on one
# command: a person who wants more starts another session.
_felix_overnight_grants() {   # proj, sid -> path
  _felix_overnight_sid_ok "${2:-}" || return 1
  printf '%s/grants/%s' "$(felix_overnight_dir "$1")" "$2"
}

felix_overnight_granted() {   # proj, sid -> "turns hours" granted inside the window
  local f since
  f="$(_felix_overnight_grants "$1" "${2:-}")" || { printf '0 0'; return 0; }
  since=$(( $(felix_overnight_now) - FELIX_OVERNIGHT_WINDOW ))
  [ -f "$f" ] || { printf '0 0'; return 0; }
  awk -F'\t' -v since="$since" '$1 ~ /^[0-9]+$/ && $1 >= since { t += $2; h += $3 }
    END { printf "%d %d", t, h }' "$f" 2>/dev/null || printf '0 0'
}

felix_overnight_start() {   # proj, hours, turns, session, note -> 0, or 1 with a reason on stdout
  local proj="$1" hours="${2:-$FELIX_OVERNIGHT_DEFAULT_HOURS}" turns="${3:-$FELIX_OVERNIGHT_DEFAULT_TURNS}"
  local sid="${4:-}" note="${5:-}" now deadline f mark
  case "$hours" in ''|*[!0-9]*) printf 'hours must be a whole number of hours'; return 1 ;; esac
  case "$turns" in ''|*[!0-9]*) printf 'turns must be a whole number'; return 1 ;; esac
  [ "$hours" -ge 1 ] || { printf 'a night shorter than an hour is a normal session'; return 1; }
  [ "$hours" -le "$FELIX_OVERNIGHT_MAX_HOURS" ] || {
    printf 'the ceiling is %s hours; start another night rather than one long one' "$FELIX_OVERNIGHT_MAX_HOURS"; return 1; }
  [ "$turns" -ge 1 ] || { printf 'a night with no continuations cannot continue anything'; return 1; }
  [ "$turns" -le "$FELIX_OVERNIGHT_MAX_TURNS" ] || {
    printf 'the ceiling is %s continuations; start another night rather than one long one' "$FELIX_OVERNIGHT_MAX_TURNS"; return 1; }
  [ -n "$sid" ] || { printf 'a night is granted to a session, and none was named'; return 1; }
  _felix_overnight_sid_ok "$sid" || {
    printf 'the session id cannot name a night: letters, digits, dot, dash and underscore only'; return 1; }
  local had had_t had_h
  had="$(felix_overnight_granted "$proj" "$sid")"; had_t="${had% *}"; had_h="${had#* }"
  [ $(( had_t + turns )) -le "$FELIX_OVERNIGHT_MAX_TURNS" ] || {
    printf 'this session was granted %s continuation(s) in the last day, and the ceiling is %s a day; a new session is a new day' \
      "$had_t" "$FELIX_OVERNIGHT_MAX_TURNS"; return 1; }
  [ $(( had_h + hours )) -le "$FELIX_OVERNIGHT_MAX_HOURS" ] || {
    printf 'this session was granted %s hour(s) of night in the last day, and the ceiling is %s a day; a new session is a new day' \
      "$had_h" "$FELIX_OVERNIGHT_MAX_HOURS"; return 1; }

  now="$(felix_overnight_now)"; deadline=$(( now + hours * 3600 ))
  f="$(_felix_overnight_state "$proj" "$sid")"
  mkdir -p "$(dirname "$f")" 2>/dev/null || { printf 'cannot write %s' "$(dirname "$f")"; return 1; }
  # Tabs and newlines out of the note, because the state is one TSV line and a
  # note that breaks it would make the night unreadable rather than invalid.
  note="$(printf '%s' "$note" | tr '\t\n' '  ')"
  printf '%s\t%s\t%s\t0\t%s\t%s\n' "$now" "$deadline" "$turns" "${sid:--}" "$note" \
    > "$f" 2>/dev/null || { printf 'cannot write the state file'; return 1; }
  # A new night reads the transcript from its own first hold, not from where
  # an old one stopped.
  mark="$(_felix_overnight_mark "$proj" "$sid" 2>/dev/null)" && rm -f "$mark" 2>/dev/null
  mark="$(_felix_overnight_grants "$proj" "$sid")"
  mkdir -p "$(dirname "$mark")" 2>/dev/null
  printf '%s\t%s\t%s\n' "$now" "$turns" "$hours" >> "$mark" 2>/dev/null || {
    rm -f "$f" 2>/dev/null
    printf 'cannot write the grant ledger, so the grant could not be bounded'; return 1; }
  felix_overnight_log_event "$proj" start "${hours}h ${turns} continuations; $(_felix_overnight_whose "$sid")"
  return 0
}

felix_overnight_end() {   # proj, reason [, sid] -> 0 whether or not one was running
  local proj="$1" reason="${2:-ended}" sid="${3:-}" f mark
  f="$(_felix_overnight_state "$proj" "$sid")" || return 0
  [ -f "$f" ] || return 0
  felix_overnight_log_event "$proj" end "$reason; $(_felix_overnight_whose "$sid")"
  rm -f "$f" 2>/dev/null || true
  mark="$(_felix_overnight_mark "$proj" "$sid" 2>/dev/null)" && rm -f "$mark" 2>/dev/null
  return 0
}

# Spend one continuation. Prints what is left, and the caller decides what to
# do with zero; ending the night here would hide the last continuation from the
# reader that asked for it.
felix_overnight_spend() {   # proj, quiet(0|1) [, sid] -> remaining
  local proj="$1" quiet="${2:-0}" sid="${3:-}" started deadline turns quiets owner note f
  f="$(_felix_overnight_state "$proj" "$sid")" || { printf '0'; return 1; }
  [ -f "$f" ] || { printf '0'; return 1; }
  IFS=$'\t' read -r started deadline turns quiets owner note < "$f" 2>/dev/null || true
  case "$turns" in ''|*[!0-9]*) turns=0 ;; esac
  case "$quiets" in ''|*[!0-9]*) quiets=0 ;; esac
  [ "$turns" -gt 0 ] && turns=$(( turns - 1 ))
  if [ "$quiet" = "1" ]; then quiets=$(( quiets + 1 )); else quiets=0; fi
  # Written beside and renamed over, and only while the night is still there.
  # A spend that could not be written must not be a spend that happened: a
  # hold that costs nothing is a hold with no bound but the clock. The caller
  # hears the failure and ends the night. A rename over a file an --end or a
  # sweep removed a moment ago would bring the night back, which the check
  # before it narrows to the width of one rename.
  # Outside nights/, so the listing can never read the half-written copy as a night.
  local tmp; tmp="$(felix_overnight_dir "$proj")/.spend.$$"
  if printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$started" "$deadline" "$turns" "$quiets" "$owner" "$note" \
       > "$tmp" 2>/dev/null && [ -f "$f" ] && mv -f "$tmp" "$f" 2>/dev/null; then
    printf '%s' "$turns"
    return 0
  fi
  rm -f "$tmp" 2>/dev/null
  printf '%s' "$turns"
  return 1
}

felix_overnight_quiets() {   # proj [, sid] -> consecutive continuations that called no tool
  local q; q="$(felix_overnight_field "$1" 4 "${2:-}" 2>/dev/null)"
  case "$q" in ''|*[!0-9]*) printf '0' ;; *) printf '%s' "$q" ;; esac
}

# Nights whose deadline passed while nobody was there to end them. With a
# night per session, a session that closes before its night runs out leaves
# its file behind, and nothing else ever reads it again. A night past its
# deadline holds nobody, so ending it loses only the state line, and the end
# is written to the log the morning page reads. The caller's own night is
# left alone: its own session says it is over, and that message is better
# from there. Only the deadline is swept, never the other two bounds, because
# only the deadline can pass while no session is running.
felix_overnight_sweep() {   # proj [, the caller's sid] -> how many were ended
  local proj="$1" mine="${2:-}" id key deadline now n=0
  now="$(felix_overnight_now)"
  while IFS= read -r id; do
    [ -n "$id" ] || continue
    [ -n "$mine" ] && [ "$id" = "$mine" ] && continue
    key="$id"; [ "$id" = "-" ] && key=""
    deadline="$(felix_overnight_field "$proj" 2 "$key")" || continue
    case "$deadline" in ''|*[!0-9]*) continue ;; esac
    [ "$now" -ge "$deadline" ] || continue
    felix_overnight_end "$proj" "the granted time ran out; closed by a later session" "$key"
    n=$(( n + 1 ))
  done <<EOT
$(felix_overnight_nights "$proj")
EOT
  printf '%s' "$n"
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
felix_overnight_report() {   # proj [, sid] -> prose on stdout
  local proj="$1" mine="${2:-}" f key id label started deadline turns quiets owner note now n any=0 why
  printf 'overnight report for %s\n\n' "$(basename "$proj")"

  # Every night, not one: with a night per session, a page that showed only
  # the reader's own would hide the others from the person reading it.
  now="$(felix_overnight_now)"
  while IFS= read -r id; do
    [ -n "$id" ] || continue
    key="$id"; [ "$id" = "-" ] && key=""
    f="$(_felix_overnight_state "$proj" "$key")" || continue
    [ -f "$f" ] || continue
    any=1
    IFS=$'\t' read -r started deadline turns quiets owner note < "$f" 2>/dev/null || true
    label="$(_felix_overnight_whose "$key")"
    [ -n "$mine" ] && [ "$id" = "$mine" ] && label="${label}, this session"
    printf '  %s\n' "$label"
    printf '    started    %s\n' "$(date -r "$started" '+%Y-%m-%d %H:%M' 2>/dev/null || printf '%s' "$started")"
    printf '    deadline   %s\n' "$(date -r "$deadline" '+%Y-%m-%d %H:%M' 2>/dev/null || printf '%s' "$deadline")"
    case "$deadline" in ''|*[!0-9]*) ;; *)
      printf '    left       %s continuation(s), %s hour(s)\n' "$turns" "$(( (deadline - now) / 3600 ))" ;;
    esac
    [ -n "${note:-}" ] && printf '    note       %s\n' "$note"
    why="$(felix_overnight_expired "$proj" "$key")" && printf '    over       %s\n' "$why"
    printf '\n'
  done <<EOT
$(felix_overnight_nights "$proj")
EOT
  [ "$any" -eq 1 ] || \
    printf '  No night is running. The log below, if there is one, is the last.\n\n'

  n="$(felix_overnight_deferred_count "$proj")"
  printf 'waiting on you (%s)\n\n' "$n"
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
