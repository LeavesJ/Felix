# felix status's land row: is the land-on-green job installed, loaded, paused and
# still ticking (audit b04, C005; docs/2026-10-24-audit-fixes/b04-*.md B2-B10).
#
# Until this row a paused, unloaded, uninstalled or hung job showed on no surface
# a person reads at the start of a session. The tick's own rows cannot say: they
# are deduplicated, a pause writes one an hour, and launchd never starts a second
# copy of a running job, so a hung tick writes nothing at all. What can say is the
# tick's heartbeat (lib/green-tick.sh writes $land/heartbeat first of all, every
# tick) read against the clock, beside launchd's own answer and the paused file.
#
# Read-only: it creates, changes and removes nothing, runs no claude, and asks
# launchctl one thing, `print gui/<uid>/felix.land.<project>`. Every outside
# command is called by name through PATH. Sourced by lib/status.sh when a row or
# the session-start badge needs it, never at load.
#
# The row is `<state> TAB <value> TAB <detail>`, as felix_schedule_state's is.
# Unknown is its own answer: a launchctl that cannot answer, a heartbeat nobody
# wrote or one that cannot be read is `unknown`, never `running`.

# The newest-row clause of every detail: the ledger's last non-empty line, fields
# 1, 2 and 7 (when, what, and why), tabs and CRs made spaces.
_felix_lander_newest() {   # LEDGER -> the clause
  local led="$1" r
  if [ ! -e "$led" ] && [ ! -L "$led" ]; then printf 'the ledger has no row'; return 0; fi
  if [ ! -f "$led" ] || [ ! -r "$led" ]; then printf 'the ledger could not be read'; return 0; fi
  r="$(LC_ALL=C awk -F'\t' 'length($0) > 0 { a = $1; b = $2; c = $7; n++ }
        END { if (n) { gsub(/\r/, " ", a); gsub(/\r/, " ", b); gsub(/\r/, " ", c); print a " " b ": " c } }' "$led" 2>/dev/null)" \
    || { printf 'the ledger could not be read'; return 0; }
  if [ -z "$r" ]; then printf 'the ledger has no row'; else printf "the ledger's newest row is %s" "$r"; fi
}

# The first line of a regular, readable file; empty when it is neither or is empty.
_felix_lander_first() {   # FILE -> its first line
  local l=""
  if [ -f "$1" ] && [ -r "$1" ]; then { IFS= read -r l || [ -n "$l" ]; } 2>/dev/null < "$1"; fi
  printf '%s' "$l"
}

# wave-1-combine C6, C7. The name of the project the Felix home H resolves, when it resolves one and
# it is not P: land on green lands that project's pull requests only, and felix land refuses to
# install, pause, resume, tick or report a lander for any other (audit b05, C013). Nothing otherwise.
_felix_lander_home() {   # P H -> the home's project's name
  local hp
  [ -n "${2:-}" ] || return 0
  hp="$(felix_resolve_project "$2" "$2" 2>/dev/null)" || return 0
  hp="${hp%/}"; hp="${hp##*/}"
  [ -z "$hp" ] || [ "$hp" = "$1" ] || printf '%s' "$hp"
}

# Prints `<state><TAB><value><TAB><detail>` for the project at $1, whose land
# directory is its memory root's land/, under the Felix home $2 (felix status's
# and session start's own). Returns 0, always.
felix_lander_state() {   # PROJ [HOME]
  local proj="${1%/}" p ld pl led n un uid rc hbf hb="" hbst=absent first now age=0 t r hp tab=$'\t' cr=$'\r'
  _felix_status_need felix_mem_dir resolve
  p="${proj##*/}"; ld="$(felix_mem_dir "$proj")/land"; led="$ld/ledger.tsv"; hbf="$ld/heartbeat"
  if [ -z "${HOME:-}" ]; then printf 'unknown\t-\tno home directory to look for the job in\n'; return 0; fi
  pl="$HOME/Library/LaunchAgents/felix.land.$p.plist"
  # wave-1-combine C6. Outside the home this project has no lander, and a job installed for it before
  # b05 serves nothing: said before launchd is asked, so such a job never reads as a hung tick.
  hp="$(_felix_lander_home "$p" "${2:-}")"
  if [ -n "$hp" ]; then
    if [ -e "$pl" ]; then
      printf 'value\tnot-home\t%s is installed, but land on green lands the pull requests of the home'\''s project %s only, so the job serves nothing for %s: felix land --uninstall from this checkout removes it\n' "$pl" "$hp" "$p"
    else
      printf 'none\t-\tland on green lands the pull requests of the home'\''s project %s only, so %s has no lander\n' "$hp" "$p"
    fi
    return 0
  fi
  n="$(_felix_lander_newest "$led")"
  if [ ! -e "$pl" ] && [ "$n" = "the ledger has no row" ]; then
    printf 'none\t-\tno land-on-green job for %s; felix land --install schedules one\n' "$p"; return 0
  fi
  un="$(uname 2>/dev/null)"
  if [ "$un" != "Darwin" ]; then printf 'unknown\t-\tno launchd on %s\n' "${un:-this machine}"; return 0; fi
  if ! command -v launchctl >/dev/null 2>&1; then printf 'unknown\t-\tlaunchctl could not answer\n'; return 0; fi
  uid="$(id -u 2>/dev/null)"
  case "$uid" in ''|*[!0123456789]*)
    printf 'unknown\t-\tid -u gave no user id, so whether felix.land.%s is loaded is not known\n' "$p"; return 0 ;; esac
  launchctl print "gui/$uid/felix.land.$p" >/dev/null 2>&1; rc=$?
  if [ "$rc" -eq 113 ]; then
    if [ -e "$pl" ]; then
      printf 'value\tnot-loaded\t%s exists and launchd has not loaded felix.land.%s: nothing lands; %s\n' "$pl" "$p" "$n"
    else
      printf 'value\tnot-installed\tno felix.land.%s job is installed and launchd has none loaded, and %s: nothing lands here until felix land --install\n' "$p" "$n"
    fi
    return 0
  fi
  if [ "$rc" -ne 0 ]; then
    printf 'unknown\t-\tlaunchctl print exited %s, so whether felix.land.%s is loaded is not known\n' "$rc" "$p"; return 0
  fi
  # Loaded. The heartbeat is a first line of 1 to 12 digits and nothing else.
  now="$(date +%s)"
  if [ -e "$hbf" ] || [ -L "$hbf" ]; then
    hbst=unreadable; first="$(_felix_lander_first "$hbf")"
    case "$first" in ''|*[!0123456789]*) ;; *) if [ "${#first}" -le 12 ]; then hb=$((10#$first)); hbst=time; fi ;; esac
  fi
  if [ "$hbst" = time ]; then
    age=$((now - hb))
    if [ "$age" -gt 2700 ]; then
      t="$(_felix_status_utc "$hb")"; [ -n "$t" ] || t="epoch second $hb"
      printf 'value\tnot-ticking\tlaunchd has felix.land.%s loaded and no tick has started for %s minutes, since %s: a tick may be hung, or the job cannot start one; %s\n' \
        "$p" "$((age / 60))" "$t" "$n"
      return 0
    fi
  fi
  if [ -e "$ld/paused" ]; then
    r="$(_felix_lander_first "$ld/paused")"; r="${r//$tab/ }"; r="${r//$cr/ }"
    [ -n "$r" ] || r="no reason could be read"
    printf 'value\tpaused\t%s: nothing lands while it is paused\n' "$r"; return 0
  fi
  case "$hbst" in
    absent)
      printf 'unknown\t-\tlaunchd has felix.land.%s loaded and it is not paused; no tick has recorded a heartbeat in %s, so whether it still ticks is not known; %s\n' "$p" "$hbf" "$n"; return 0 ;;
    unreadable)
      printf 'unknown\t-\t%s holds no time this check can read, so whether felix.land.%s still ticks is not known; %s\n' "$hbf" "$p" "$n"; return 0 ;;
  esac
  if [ "$age" -lt -300 ]; then
    printf 'unknown\t-\t%s is dated %s seconds after this clock, so whether felix.land.%s still ticks is not known; %s\n' "$hbf" "$((0 - age))" "$p" "$n"; return 0
  fi
  [ "$age" -ge 0 ] || age=0
  printf 'value\trunning\tlaunchd has felix.land.%s loaded, it is not paused, and its last tick started %s min ago; %s\n' "$p" "$((age / 60))" "$n"
  return 0
}

# The session-start badge (B13): `<value><TAB><detail>` when the land row, as
# felix status prints it in this directory, reads paused, not-loaded,
# not-ticking or not-home (wave-1-combine C6); nothing for every other answer.
# It goes through the row's own normalising, so the detail is the one felix
# status shows.
felix_lander_notice() {   # PROJ [HOME]
  local row state value detail tab=$'\t'
  row="$(_felix_status_from3 land "$(felix_lander_state "$1" "${2:-}")" 2>/dev/null)" || return 0
  row="${row#*$tab}"; state="${row%%$tab*}"; row="${row#*$tab}"; value="${row%%$tab*}"; detail="${row#*$tab}"
  [ "$state" = value ] || return 0
  case "$value" in paused|not-loaded|not-ticking|not-home) printf '%s\t%s\n' "$value" "$detail" ;; esac
  return 0
}
