# Overnight, at a stop: what the Stop hook asks of a session's night.
#
# Kept apart from lib/overnight.sh, which holds the night itself (its state,
# whose it is, the queue and the morning page) and is sourced by the CLI and
# both hooks. Only the Stop hook decides a stop, so only it sources this, after
# overnight.sh. The rule that makes a night end when a session idles lives
# here, in felix_overnight_quiet, and the bounds it feeds are overnight.sh's.

# Did the session do anything since the night last held it?
#
# This was read off the maintenance table: a continuation counted as quiet when
# no maintenance row was due, whatever the session had just done. So a night
# that shipped a pull request on every continuation ended after two of them if
# the graph happened to be fresh, and one that did nothing ran its whole budget
# if the graph was stale. Quiet is a fact about the session, and its transcript
# records it: a continuation that called no tool did nothing. Only the bytes
# appended since the last hold are read, so each stop costs what was added,
# not the length of the session.
#
# Matched on the record's own key, `"type":"tool_use"`. The same words quoted
# inside a message are escaped there (`\"type\":\"tool_use\"`), so prose about
# tools cannot pass for a tool call.
#
# Unknown counts as quiet. A hold nobody can show bought any work is the one
# that should not repeat, and a transcript that cannot be read would otherwise
# hold a session for its whole budget on no evidence at all.
#
# Two limits, both bounded by the budget rather than fixed. The first hold of a
# night has no mark yet and reads from the start of the transcript, so it
# counts the calls made before the night and is never quiet. And a tool call
# something refused is still a call on the record: a session whose every call
# a broken plugin refuses never idles, and spends its budget instead of ending
# after two.
felix_overnight_quiet() {   # proj, sid, transcript -> 1 when quiet, 0 when the session worked
  local proj="$1" sid="${2:-}" tp="${3:-}" mark size from n
  mark="$(_felix_overnight_mark "$proj" "$sid")" || { printf '1'; return 0; }
  { [ -n "$tp" ] && [ -f "$tp" ] && [ -r "$tp" ]; } || { printf '1'; return 0; }
  size="$(wc -c < "$tp" 2>/dev/null | tr -d ' ')"
  case "$size" in ''|*[!0-9]*) printf '1'; return 0 ;; esac
  from="$(cat "$mark" 2>/dev/null)"
  case "$from" in ''|*[!0-9]*) from=0 ;; esac
  # Shorter than the mark is a transcript that was replaced, not one that
  # shrank, so it is read from its start.
  [ "$from" -le "$size" ] || from=0
  n="$(tail -c +"$(( from + 1 ))" "$tp" 2>/dev/null \
       | grep -cE '"type"[[:space:]]*:[[:space:]]*"tool_use"' 2>/dev/null)"
  mkdir -p "$(dirname "$mark")" 2>/dev/null && printf '%s\n' "$size" > "$mark" 2>/dev/null
  case "${n:-0}" in ''|*[!0-9]*|0) printf '1' ;; *) printf '0' ;; esac
  return 0
}

# One stop inside this session's night, decided. The hook owns the JSON and
# the messages that are not the night's; this owns the night.
#
#   0  hold the session; the reason is on stdout
#   2  the night ended at this stop; the morning page is on stdout, and the
#      session may close
#   1  this session holds no night; nothing was printed or spent
#
# `due` is what the maintenance table says is due, passed in rather than read
# here, so this file needs nothing sourced beside it.
felix_overnight_continue() {   # proj, sid, transcript, due -> see above
  local proj="$1" sid="${2:-}" tp="${3:-}" due="${4:-}" why waiting quiet left worked
  felix_overnight_owns "$proj" "$sid" || return 1
  if why="$(felix_overnight_expired "$proj" "$sid")"; then
    felix_overnight_end "$proj" "$why" "$sid"
    printf 'Overnight is over: %s.\n\n' "$why"; felix_overnight_report "$proj" "$sid"
    return 2
  fi

  waiting="$(felix_overnight_deferred_count "$proj")"
  quiet="$(felix_overnight_quiet "$proj" "$sid" "$tp")"
  # A spend that was not written is not a spend, and a hold that costs nothing
  # is bounded by nothing but the clock. So the night ends here and the session
  # may close, which is what everything unexpected in the Stop hook does.
  if ! left="$(felix_overnight_spend "$proj" "$quiet" "$sid")"; then
    why="the night's state could not be written, so no continuation could be spent"
    felix_overnight_end "$proj" "$why" "$sid"
    printf 'Overnight is over: %s.\n\n' "$why"; felix_overnight_report "$proj" "$sid"
    return 2
  fi
  worked="yes"; [ "$quiet" = "1" ] && worked="no"
  # One line per continuation, so the morning report can show the shape of
  # the night rather than only its ending.
  felix_overnight_log_event "$proj" continue \
    "left ${left}; worked ${worked}; due ${due:-none}; deferred ${waiting}; $(_felix_overnight_whose "$sid")"

  # Spending can be what exhausts the grant, so the same question is asked
  # again on the way out.
  if why="$(felix_overnight_expired "$proj" "$sid")"; then
    felix_overnight_end "$proj" "$why" "$sid"
    printf 'Overnight is over: %s.\n\n' "$why"; felix_overnight_report "$proj" "$sid"
    return 2
  fi

  printf 'Overnight is on, and %s continuation(s) remain.\n' "$left"
  printf 'Do not stop to report — take the next piece of work.\n\n'
  printf 'What this hook can see from here:\n'
  [ -n "$due" ] && printf '  * maintenance due: %s\n' "$due"
  [ "${waiting:-0}" -gt 0 ] && \
    printf '  * %s decision(s) already deferred, which stay deferred until morning\n' "$waiting"
  [ "$worked" = "no" ] && \
    printf '  * the last continuation called no tool. One more like it ends the night.\n'
  # Pointed at rather than run. felix next ranks the backlog by reading gate
  # history, the ledger and the tables, which is a second or two of work —
  # affordable when a person asks for it and not in a hook that fires at
  # every stop of every session.
  printf '  * felix next ranks what is left, and HANDOFF'"'"'s own Next list is the queue\n'
  printf '    this hook cannot see.\n\n'
  printf 'Anything that needs the founder gets written down rather than waited on:\n\n'
  printf '  felix overnight --defer approval --what "..." --unblock "the command"\n\n'
  printf 'felix overnight --end stops the night now.'
  return 0
}

# A stop inside a night's chain that the gate is about to refuse. Out of a
# chain a refusal costs the night nothing, because the platform bounds a chain
# of refusals by itself. Inside one, the night carried the session past that
# bound, so the refusal has to be counted against the night or a gate that
# cannot go green would hold the session for as long as the platform lets it.
#
#   0  a continuation was spent; the hook refuses as it always has
#   2  the night ended; the morning page is on stdout and the session may close
#   1  this session holds no night
felix_overnight_charge() {   # proj, sid, transcript, what-the-gate-said -> see above
  local proj="$1" sid="${2:-}" tp="${3:-}" what="${4:-}" why quiet left
  felix_overnight_owns "$proj" "$sid" || return 1
  if ! why="$(felix_overnight_expired "$proj" "$sid")"; then
    quiet="$(felix_overnight_quiet "$proj" "$sid" "$tp")"
    if left="$(felix_overnight_spend "$proj" "$quiet" "$sid")"; then
      felix_overnight_log_event "$proj" refused \
        "left ${left}; gate ${what:-refused}; $(_felix_overnight_whose "$sid")"
      why="$(felix_overnight_expired "$proj" "$sid")" || return 0
    else
      why="the night's state could not be written, so no continuation could be spent"
    fi
  fi
  felix_overnight_end "$proj" "$why" "$sid"
  printf 'Overnight is over: %s. The gate is still not green on this tree.\n\n' "$why"
  felix_overnight_report "$proj" "$sid"
  return 2
}
