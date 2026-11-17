# An owed engine deploy gets its window (docs/2026-11-06-deploy-window-contract.md, DW1 to DW7).
#
# The lander deploys the engine main declares only when no gate or suite runs, and replaces
# nothing beneath a run that has started. On 2026-11-06 sessions kept records and gates going
# back to back, so a deploy owed from 11:29Z found no such moment by 14:40Z, every gate ended
# red on `installed`, and the tick merged nothing. The only way to a window that signals no one
# is that nothing new starts while a deploy is owed: what runs drains, and the next tick deploys.
#
# Three parts, one file, because they share one format:
#   the hold      <memory root>/<project>/land/deploy-hold, one line: LEASE SINCE VERSION (tabs).
#                 The tick writes it (_dh_assert, _dh_clear); a reader looks at */land/deploy-hold.
#   the doors     tests/run and `felix gate` call _dh_wait first: they wait while the machine
#                 is held, say why on stderr, and go ahead at a bound.
#   the filter    the tick does not count a waiter, or a shell around one, as running (_dh_unwaiting).
#
# A waiter must not look like work. The tick finds work by `pgrep -f` on a command line that holds
# engine/harness/tests/run or gate.sh, and a bash waiting in tests/run has exactly that, as has an agent's
# `bash -c '...tests/run...'` around it. So each door starts one small marker process for the length of its wait,
# whose command line holds the token and the memory root it waits on, and the tick drops every pid that is
# such a marker or stands above one (_dh_unwaiting). The root is in the line so that a fixture's waiter, inside
# a real suite's test, does not make the real suite look idle. The marker ends by itself if its door dies.
#
# Every failure here reads as "nothing is held" (DW7): a command is never refused, and never waits
# past its bound, because of a damaged file, a clock or a table that would not read.
#
# Sourced by felix and by tests/run, which is `set -u` and runs under bash 3.2, so: no [[ =~ ]],
# no ${a[@]} of an empty array, no arithmetic on a number with a leading zero.

_DH_WAITTAG="felix-deploy-hold-wait"   # in the command line of whatever sleeps at the hold (DW3, DW6)
_DH_LEASE_TTL=1200                   # a lease older than this is not in force (DW1.3); a tick runs every 300 s

_dh_dec() { case "${1:-}" in ""|*[!0123456789]*) return 1 ;; esac; [ "${#1}" -le 12 ]; }   # plain decimal, no overflow

_dh_now() {   # prints the epoch second; fails when the clock will not say
  local n; n="$(date +%s 2>/dev/null)" || return 1
  _dh_dec "$n" || return 1
  printf '%s' "$((10#$n))"
}

_dh_limit() {   # DW1.4, DW5: FELIX_DEPLOY_HOLD_LIMIT when a plain decimal of at least 1, else 3600
  local v="${FELIX_DEPLOY_HOLD_LIMIT:-}"
  if _dh_dec "$v" && [ "$((10#$v))" -ge 1 ]; then printf '%s' "$((10#$v))"; else printf '3600'; fi
}
_dh_say_every() {   # DW5: FELIX_DEPLOY_HOLD_SAY, default 300
  local v="${FELIX_DEPLOY_HOLD_SAY:-}"
  if _dh_dec "$v" && [ "$((10#$v))" -ge 1 ]; then printf '%s' "$((10#$v))"; else printf '300'; fi
}
_dh_poll() {   # DW5: a positive number, fractions allowed, default 5
  local v="${FELIX_DEPLOY_HOLD_POLL:-}"
  case "$v" in ""|*[!0123456789.]*|*.*.*|.) printf '5'; return 0 ;; esac
  case "$v" in *[123456789]*) printf '%s' "$v" ;; *) printf '5' ;; esac
}

# DW1. Reads one hold file into _DH_LEASE, _DH_SINCE and _DH_VER; fails when it is not a regular
# file holding exactly three tab-separated fields, the first two plain decimals. Not yet "in force".
_dh_read() {   # FILE
  local f="$1" line="" rest rest2 a b c
  _DH_LEASE=""; _DH_SINCE=""; _DH_VER=""
  [ -f "$f" ] && [ ! -L "$f" ] || return 1
  { IFS= read -r line || [ -n "$line" ]; } 2>/dev/null < "$f" || return 1
  a="${line%%$'\t'*}"; rest="${line#*$'\t'}"; [ "$rest" != "$line" ] || return 1
  b="${rest%%$'\t'*}"; rest2="${rest#*$'\t'}"; [ "$rest2" != "$rest" ] || return 1
  c="$rest2"
  case "$c" in ""|*$'\t'*) return 1 ;; esac
  _dh_dec "$a" && _dh_dec "$b" || return 1
  _DH_LEASE="$((10#$a))"; _DH_SINCE="$((10#$b))"; _DH_VER="$c"
}

# DW1. Whether a file is in force at NOW, for LIMIT.
_dh_inforce() {   # FILE NOW LIMIT
  _dh_read "$1" || return 1
  [ "$_DH_LEASE" -le "$(( $2 + 60 ))" ] || return 1
  [ "$(( $2 - _DH_LEASE ))" -lt "$_DH_LEASE_TTL" ] || return 1
  [ "$(( $2 - _DH_SINCE ))" -lt "$3" ]
}

# DW1. Is the machine held? Looks at every <memory root>/*/land/deploy-hold and names no project.
# Sets _DH_STATE to held, lapsed (a file is there and not in force) or gone (none is there), and,
# when held, _DH_HVER and _DH_HSINCE from the hold that began first. Returns 0 when held.
_dh_scan() {
  local root="${FELIX_MEMORY:-${HOME:-}/.felix/memory}" now lim f nf=0 nglob=0 hs="" hv=""
  _DH_STATE=gone; _DH_HVER=""; _DH_HSINCE=""
  case "$-" in *f*) nglob=1; set +f ;; esac
  now="$(_dh_now)" || { [ "$nglob" -eq 0 ] || set -f; return 1; }
  lim="$(_dh_limit)"
  for f in "$root"/*/land/deploy-hold; do
    [ -e "$f" ] || [ -L "$f" ] || continue
    nf=1
    if _dh_inforce "$f" "$now" "$lim" && { [ -z "$hs" ] || [ "$_DH_SINCE" -lt "$hs" ]; }; then hs="$_DH_SINCE"; hv="$_DH_VER"; fi
  done
  [ "$nglob" -eq 0 ] || set -f
  if [ -n "$hs" ]; then _DH_STATE=held; _DH_HSINCE="$hs"; _DH_HVER="$hv"; return 0; fi
  [ "$nf" -eq 0 ] || _DH_STATE=lapsed
  return 1
}

_dh_say() { printf '%s: %s\n' "$1" "$2" >&2; }   # WHO MESSAGE

_dh_since_iso() {   # EPOCH -> the UTC time, or the epoch when date cannot say
  local t; t="$(date -u -r "$1" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -d "@$1" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null)" || t=""
  printf '%s' "${t:-epoch $1}"
}

_dh_first_line() {   # WHO -> the line a waiter says first (DW5)
  local v=""
  [ -z "$_DH_HVER" ] || [ "$_DH_HVER" = - ] || v="$_DH_HVER, "
  printf '%s: waiting for the engine deploy (%sheld since %s): a gate or suite was running when it became owed, and nothing new starts until the lander has deployed it; at most %s s. FELIX_DEPLOY_HOLD=off goes ahead now\n' \
    "$1" "$v" "$(_dh_since_iso "$_DH_HSINCE")" "$(_dh_limit)" >&2
}

_dh_admit() { FELIX_HOLD_PASSED=1; export FELIX_HOLD_PASSED; }   # DW4

# tests/run's door (DW4.1): part mode goes on at once and passes the door on, every other mode waits while the machine is held.
_dh_door() {   # WHO, then tests/run's own arguments
  local who="$1" a part=0; shift
  for a in "$@"; do [ "$a" != --part ] || part=1; done
  if [ "$part" = 1 ]; then _dh_admit; else _dh_wait "$who"; fi
}

_dh_off() { [ -n "${FELIX_HOLD_PASSED:-}" ] || [ "${FELIX_DEPLOY_HOLD:-}" = off ]; }

_dh_root() { printf '%s' "${FELIX_MEMORY:-${HOME:-}/.felix/memory}"; }   # the memory root, as _dh_scan reads it

# DW6. The marker: one perl for the length of a wait. Its command line holds the token, the memory root and
# the poll, so the tick can tell this wait from running work; it ends when its door does, or dies. Sets _DH_MARK.
_dh_mark() {   # POLL
  _DH_MARK=""
  command -v perl >/dev/null 2>&1 || return 1
  perl -e 'my $p = getppid(); while (getppid() == $p) { select(undef, undef, undef, 1) }' "$_DH_WAITTAG" "$(_dh_root)" "$1" \
    </dev/null >/dev/null 2>&1 &
  _DH_MARK="$!"
}
_dh_unmark() { [ -z "${_DH_MARK:-}" ] || { kill "$_DH_MARK"; wait "$_DH_MARK"; } 2>/dev/null; _DH_MARK=""; return 0; }

# The door, for tests/run and `felix gate`: waits in place while the machine is held. Returns once it is not,
# or the bound is reached, with FELIX_HOLD_PASSED exported (DW4, DW5). Nothing is created before it returns
# and nothing goes to stdout.
_dh_wait() {   # WHO
  local who="$1" t0 now last lim say poll why
  if _dh_off; then _dh_admit; return 0; fi
  _dh_scan || { _dh_admit; return 0; }
  t0="$(_dh_now)" || { _dh_admit; return 0; }
  poll="$(_dh_poll)"
  _dh_mark "$poll" || { _dh_say "$who" "not waiting for the engine deploy: there is no perl to mark the wait with"; _dh_admit; return 0; }
  _dh_first_line "$who"
  last="$t0"; lim="$(_dh_limit)"; say="$(_dh_say_every)"
  while :; do
    sleep "$poll" 2>/dev/null || sleep 1
    now="$(_dh_now)" || { _dh_unmark; _dh_admit; return 0; }
    if ! _dh_scan; then
      case "$_DH_STATE" in lapsed) why="the hold lapsed" ;; *) why="the hold ended" ;; esac
      _dh_unmark; _dh_say "$who" "went ahead after $((now - t0)) s: $why"; _dh_admit; return 0
    fi
    if [ "$((now - t0))" -ge "$lim" ]; then
      _dh_unmark; _dh_say "$who" "went ahead after $((now - t0)) s: the limit was reached"; _dh_admit; return 0
    fi
    if [ "$((now - last))" -ge "$say" ]; then
      _dh_say "$who" "still waiting for the engine deploy ($((now - t0)) s of at most $lim s)"; last="$now"
    fi
  done
}

# DW2. The tick writes the hold whole (a temporary file beside it, then a rename). SINCE is kept from
# the file already there when its lease is fresh and it is for the same VERSION; else it is now.
# Returns 1, having written nothing, when it cannot: that costs the machine its window and never a run.
_dh_assert() {   # LANDDIR VERSION
  local land="$1" ver="${2:-}" f now since tmp
  [ -n "$ver" ] || ver="-"
  case "$ver" in *$'\t'*|*$'\n'*) ver="-" ;; esac
  f="$land/deploy-hold"; tmp="$land/deploy-hold.$$"
  now="$(_dh_now)" || return 1
  since="$now"
  if _dh_read "$f" && [ "$_DH_VER" = "$ver" ] && [ "$_DH_LEASE" -le "$((now + 60))" ] \
     && [ "$((now - _DH_LEASE))" -lt "$_DH_LEASE_TTL" ] && [ "$_DH_SINCE" -le "$now" ]; then since="$_DH_SINCE"; fi
  mkdir -p "$land" 2>/dev/null || return 1
  [ ! -d "$f" ] || rmdir "$f" 2>/dev/null || return 1
  printf '%s\t%s\t%s\n' "$now" "$since" "$ver" > "$tmp" 2>/dev/null && mv -f "$tmp" "$f" 2>/dev/null || { rm -f "$tmp" 2>/dev/null; return 1; }
}

_dh_clear() { rm -f "$1/deploy-hold" "$1/deploy-hold.$$" 2>/dev/null; return 0; }   # LANDDIR

# DW3. PIDS, one per line, as pgrep printed them -> those that are not waiting. A pid is dropped when
# the process table shows it holding "TOKEN ROOT " (ROOT being this tick's memory root), or above a
# process that holds it. Anything the table does not show, or will not give, stays: it counts as running.
_dh_unwaiting() {   # PIDS
  local tbl out
  tbl="$(ps -axo pid=,ppid=,command= 2>/dev/null)" || { printf '%s\n' "$1"; return 0; }
  [ -n "$tbl" ] || { printf '%s\n' "$1"; return 0; }
  out="$(printf '%s\n' "$tbl" | LC_ALL=C PIDS="$1" NEEDLE="$_DH_WAITTAG $(_dh_root) " awk '
    BEGIN { n = split(ENVIRON["PIDS"], P, "\n"); tok = ENVIRON["NEEDLE"] }
    $1 ~ /^[0-9]+$/ && $2 ~ /^[0-9]+$/ {
      c = $0; sub(/^[ \t]*[0-9]+[ \t]+[0-9]+[ \t]*/, "", c)
      seen[$1] = 1; par[$1] = $2
      if (index(c, tok) > 0) w[++nw] = $1
    }
    END {
      for (i = 1; i <= nw; i++) {
        p = w[i]; drop[p] = 1
        for (k = 0; k < 256 && (p in par) && par[p] > 1; k++) { p = par[p]; drop[p] = 1 }
      }
      for (i = 1; i <= n; i++) if (P[i] ~ /^[0-9]+$/ && !((P[i] in seen) && (P[i] in drop))) print P[i]
    }')" || { printf '%s\n' "$1"; return 0; }
  printf '%s' "$out"
}
