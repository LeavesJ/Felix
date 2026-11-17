# Land on green: the tick's lock and its watchdog (lib/green-tick.sh).
#
# Moved out of lib/green-tick.sh unchanged when the audit's batches together took
# that file past 500 lines. Sourced by it at load, from beside it, so _GT_WDSECS
# has its default before the line after felix's source of green-tick.sh (part
# 1285's fixture, as A28 allows). Every function here is _gt_, like the tick's.

# --- the lock and the clock --------------------------------------------------
# A lock is held by a live tick when its pid is alive and its started line is
# that process's start time. A pid that is alive under another start time was
# reused, so the lock is dead. A started line that is absent or empty cannot be
# compared, so a live pid holds it: no tick reads a half-written lock as dead (A5).
_gt_started() { LC_ALL=C ps -o lstart= -p "$1" 2>/dev/null | LC_ALL=C sed 's/^ *//; s/ *$//'; }

_gt_unlock() {
  [ -z "${_GT_WD:-}" ] || { kill "$_GT_WD" 2>/dev/null; wait "$_GT_WD" 2>/dev/null; _GT_WD=""; }
  [ "${_GT_LOCKED:-0}" = 1 ] || return 0
  rm -rf "$_GT_LAND/lock" 2>/dev/null; _GT_LOCKED=0
}

# Seconds the process has run, from ps's [[dd-]hh:]mm:ss; empty when unreadable.
_gt_age() {
  LC_ALL=C ps -o etime= -p "$1" 2>/dev/null | LC_ALL=C awk 'NF { n = split($1, a, /[-:]/); s = 0
    if (n == 2) s = a[1] * 60 + a[2]; else if (n == 3) s = a[1] * 3600 + a[2] * 60 + a[3]
    else if (n == 4) s = a[1] * 86400 + a[2] * 3600 + a[3] * 60 + a[4]; else exit; print s }'
}

# 0 when the lock directory names a live tick; sets _GT_HPID to its pid.
_gt_holder_live() {
  local pid="" st=""
  [ -f "$1/pid" ] && pid="$(LC_ALL=C sed -n 1p "$1/pid" 2>/dev/null)"
  [ -f "$1/started" ] && st="$(LC_ALL=C sed -n 1p "$1/started" 2>/dev/null)"; _GT_HPID=""
  case "$pid" in ""|*[!0123456789]*) return 1 ;; esac
  kill -0 "$pid" 2>/dev/null || return 1
  _GT_HPID="$pid"
  [ -z "$st" ] || [ "$(_gt_started "$pid")" = "$st" ]
}

# A5. The pid and started line are written into a fresh directory, which is
# renamed to lock/. A dead lock is first renamed aside to a unique name, and
# only the tick whose rename succeeds goes on to take it. mv onto an existing
# directory would move into it, so a rename that did not win is told by lock/pid.
_gt_take() {   # 0 when this tick's directory is now lock/
  local l="$_GT_LAND/lock" t="$_GT_LAND/lock.new.$$"
  rm -rf "$t"; mkdir "$t" 2>/dev/null || return 1
  printf '%s\n' "$$" > "$t/pid"; _gt_started "$$" > "$t/started"
  [ ! -e "$l" ] && mv "$t" "$l" 2>/dev/null
  if [ "$(LC_ALL=C sed -n 1p "$l/pid" 2>/dev/null)" = "$$" ] && [ ! -e "$t" ]; then return 0; fi
  rm -rf "$t" "$l/lock.new.$$" 2>/dev/null; return 1
}

_gt_lock() {   # 0 when taken; 1 when a live tick holds it or another tick won it
  local l="$_GT_LAND/lock" dead age old
  mkdir -p "$_GT_LAND" 2>/dev/null
  if [ -e "$l" ]; then
    if _gt_holder_live "$l"; then
      age="$(_gt_age "$_GT_HPID")"
      # A live lock older than 45 minutes is said once, and neither taken nor signalled.
      if [ -n "$age" ] && [ "$age" -gt 2700 ]; then
        _gt_row_once stuck - - - 0 "tick $_GT_HPID has held the lock for over 45 minutes: it is neither taken nor signalled"
      fi
      return 1
    fi
    old="$(LC_ALL=C sed -n 1p "$l/pid" 2>/dev/null)"
    dead="$_GT_LAND/lock.dead.$$.$RANDOM"
    mv "$l" "$dead" 2>/dev/null || return 1
    # Another tick may have replaced the dead lock between the look and the
    # rename; what was moved aside is dead only if it still names the same pid.
    if [ "$(LC_ALL=C sed -n 1p "$dead/pid" 2>/dev/null)" != "$old" ]; then
      [ -e "$l" ] || mv "$dead" "$l" 2>/dev/null; return 1
    fi
    rm -rf "$dead" 2>/dev/null
  fi
  _gt_take || return 1
  _GT_LOCKED=1; _GT_T00=$SECONDS
  # Released on every way out. bash runs a trap once the foreground command
  # returns, and the exit a trap names runs the EXIT one.
  trap '_gt_unlock' EXIT
  trap '_gt_timeout' TERM; trap 'exit 130' INT; trap 'exit 129' HUP
  return 0
}

_gt_timeout() {
  trap '' TERM
  _gt_row timeout - - - "$((SECONDS - ${_GT_T00:-0}))" "the tick was stopped by TERM, as the 30 minute watchdog sends it: its lock is released"
  exit 143
}

# A4, A25. After 30 minutes the watchdog sends TERM to the tick's pid first, and
# only then to the tick's descendants, listed before the tick can end and orphan
# them. It never signals its own pid or its own process group: the group is the
# shell's when the tick is run by hand, and holds the watchdog itself.
_gt_descendants() {   # PID [SKIP] -> PID's descendants' pids, one per line, minus SKIP and its own
  LC_ALL=C ps -axo pid=,ppid= 2>/dev/null | LC_ALL=C awk -v root="$1" -v skip="${2:-x}" '{ k[NR] = $1; par[$1] = $2 }
    END { want[root] = 1; sk[skip] = 1
          do { c = 0; for (i = 1; i <= NR; i++) {
                 if (!(k[i] in want) && (par[k[i]] in want)) { want[k[i]] = 1; c = 1 }
                 if (!(k[i] in sk) && (par[k[i]] in sk)) { sk[k[i]] = 1; c = 1 } } } while (c)
          for (i = 1; i <= NR; i++) if (k[i] != root && (k[i] in want) && !(k[i] in sk)) print k[i] }'
}

_GT_WDSECS=1800
_gt_watchdog() {
  local tick=$$ st; st="$(_gt_started "$tick")"
  (
    trap - EXIT; exec >/dev/null 2>&1 </dev/null
    me="$(sh -c 'echo $PPID')"
    sleep "$_GT_WDSECS" & sp=$!
    trap 'kill "$sp" 2>/dev/null; exit 0' TERM
    wait "$sp" 2>/dev/null
    # A15: the pid may name another process by now; only the tick it was set on is signalled.
    [ -n "$st" ] && [ "$(_gt_started "$tick")" = "$st" ] || exit 0
    kids="$(_gt_descendants "$tick" "$me")"
    kill -TERM "$tick" 2>/dev/null
    [ -z "$kids" ] || kill -TERM $kids 2>/dev/null
  ) &
  _GT_WD=$!
}
