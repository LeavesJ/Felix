# Discovery's background refresh, and what it says about itself (audit b06).
#
# The refresh runs after a session start has gone, so nobody watches it, and it
# used to leave no trace of how it ended: with TMPDIR unset or under /tmp (a
# Linux default) it ran nothing at all, nothing recorded that, and the pulse
# said the next session would refresh it. A promise the engine cannot keep is
# the thing this file stops making. Every attempt that takes the lock replaces
# state/discover/<project>.refresh with one line,
#
#   <epoch> TAB <outcome> TAB <detail>
#
# where the outcome is `ran` (the cache was written and a reader takes it),
# `failed` (felix discover started and did not finish, or wrote a cache no reader
# takes) or `not-run` (felix discover never started, and the detail says why),
# and the pulse and the session start read it back in their own words.
#
# Sourced by lib/discover.sh and lib/pulse.sh, each with the house guard. What
# needs discover.sh (the cache path, the stamp) is called, never sourced, and is
# only called where discover.sh is loaded.

if ! command -v felix_close_inherited_fds >/dev/null 2>&1; then
  . "$(dirname "${BASH_SOURCE[0]:-$0}")/resolve.sh"
fi

# The record, beside the cache it speaks for.
_felix_discover_rec() { local p="${1%/}"; printf '%s/state/discover/%s.refresh' "$2" "${p##*/}"; }

_felix_discover_utc() {
  date -u -r "$1" +%Y-%m-%dT%H:%MZ 2>/dev/null || date -u -d "@$1" +%Y-%m-%dT%H:%MZ 2>/dev/null \
    || printf 'epoch %s' "$1"
}

# The record, replaced whole and at once, so a reader never sees half of it.
_felix_discover_refresh_note() {   # REC OUTCOME DETAIL
  local tmp="$1.new.$$"
  { printf '%s\t%s\t%s\n' "$(date +%s)" "$2" "$3" > "$tmp"; } 2>/dev/null \
    && mv -f "$tmp" "$1" 2>/dev/null || rm -f "$tmp" 2>/dev/null
  return 0
}

# Why felix discover was not started, from _FELIX_NEUTRAL_NOTRUN (lib/reach-read.sh).
_felix_discover_notrun_why() {
  case "$1" in
    1) printf 'TMPDIR is not an absolute path, so there is no private directory to run discovery in' ;;
    2) printf 'TMPDIR is not a private directory, so discovery was not run: it must be owned by you and writable by no one else, under parents only you or root can write' ;;
    4) printf 'a .mcp.json sits above the scratch directory, so discovery was not run there' ;;
    *) printf 'could not make an empty directory to run discovery in' ;;
  esac
}

# One refresh, in the background subshell that holds the lock. A read that fails
# writes no cache and the previous answer stands: an unreadable catalogue is not
# an empty one, and must not become one for a week. Never the checkout, which
# may be a stranger's: felix discover runs in an empty directory holding a
# .felix naming the project (lib/reach-read.sh), or it does not run.
_felix_discover_refresh_run() {   # PROJ HOME FELIX
  local proj="$1" home="$2" felix_bin="$3" cache new rec rc nr
  cache="$(_felix_discover_cache "$proj" "$home").tsv"; new="$cache.new.$$"; rec="${cache%.tsv}.refresh"
  felix_neutral_run "$proj" felix-discover "$felix_bin" discover --inspect --quiet > "$new" 2>/dev/null; rc=$?
  nr="${_FELIX_NEUTRAL_NOTRUN:-5}"
  if [ "$nr" != 0 ]; then
    rm -f "$new" 2>/dev/null
    _felix_discover_refresh_note "$rec" not-run "$(_felix_discover_notrun_why "$nr")"; return 0
  fi
  if [ "$rc" -ne 0 ]; then
    rm -f "$new" 2>/dev/null
    _felix_discover_refresh_note "$rec" failed "felix discover exited $rc; the previous cache was left as it was"; return 0
  fi
  if ! mv -f "$new" "$cache" 2>/dev/null; then
    rm -f "$new" 2>/dev/null
    _felix_discover_refresh_note "$rec" failed "the new cache could not be moved into place; the previous cache was left as it was"; return 0
  fi
  # Ran is a claim a reader has to agree with: the cache is written either way,
  # and one whose first line is not the current stamp is read as absent.
  if felix_discover_cache_current "$proj" "$home"; then
    _felix_discover_refresh_note "$rec" ran "the cache was rewritten"
  else
    _felix_discover_refresh_note "$rec" failed "felix discover printed a cache whose first line is not the current stamp, so no reader takes it; felix discover --adopt writes one that is"
  fi
  return 0
}

# Refresh in the background, at most one at a time. The lock is a directory
# because mkdir is atomic everywhere and a stale lock file is not. A lock older
# than 30 minutes is broken, because a refresh killed by SIGKILL or a power loss
# never runs its trap (TERM and HUP do) and the lock would otherwise hold every
# project in the home out for good. Accepted, as for reach: a refresh still
# running after 30 minutes can be overlapped, and its trap may remove the newer
# run's lock.
felix_discover_refresh_bg() {
  local proj="$1" home="$2" felix_bin="$3" dir lock
  command -v felix_neutral_run >/dev/null 2>&1 || . "$(dirname "${BASH_SOURCE[0]:-$0}")/reach-read.sh"
  dir="$home/state/discover"
  lock="$dir/.lock"
  mkdir -p "$dir" 2>/dev/null || return 0
  if [ -d "$lock" ] && [ -n "$(find "$lock" -maxdepth 0 -mmin +30 2>/dev/null)" ]; then
    rmdir "$lock" 2>/dev/null
  fi
  mkdir "$lock" 2>/dev/null || return 0   # already running; leave it alone
  (
    trap 'rmdir "$lock" 2>/dev/null' EXIT
    felix_close_inherited_fds
    _felix_discover_refresh_run "$proj" "$home" "$felix_bin"
  ) </dev/null >/dev/null 2>&1 &
  return 0
}

# The record as `epoch TAB outcome TAB detail` on stdout and 0; 1 when there is
# none; 2 when there is a record this cannot read: not one line, not three
# non-empty fields, an epoch that is not digits, or an outcome it does not know.
# A record that is not a regular file is not opened (a pipe would block).
felix_discover_refresh_read() {   # PROJ HOME
  local rec out; rec="$(_felix_discover_rec "$1" "$2")"
  [ -e "$rec" ] || return 1
  [ -f "$rec" ] && [ -r "$rec" ] || return 2
  out="$(LC_ALL=C awk -F'\t' '
    { n++; l = $0; f = NF; e = $1; o = $2; d = $3 }
    END { if (n == 1 && f == 3 && e ~ /^[0123456789]+$/ && length(e) <= 12 && d != "" && (o == "ran" || o == "failed" || o == "not-run")) print l }
  ' "$rec" 2>/dev/null)"
  [ -n "$out" ] || return 2
  printf '%s\n' "$out"
}

# The pulse's one line for a project whose discovery cache is stale: what the
# last background refresh did, and what happens next, in words that are true.
felix_discover_report_line() {   # PROJ HOME
  local p="${1%/}" name rec rc ep rest oc dt utc tab=$'\t'
  name="${p##*/}"
  rec="$(felix_discover_refresh_read "$1" "$2")"; rc=$?
  case "$rc" in
    1) printf 'stale\t%s\tdiscovery cache; no background refresh is recorded here, and the next session in its checkout starts one\n' "$name"; return 0 ;;
    0) ;;
    *) printf 'discover-unread\t%s\tthe record of the last background refresh could not be read, so whether one can run here is not known; felix discover --adopt in its checkout fills the cache in the foreground\n' "$name"; return 0 ;;
  esac
  ep="${rec%%$tab*}"; rest="${rec#*$tab}"; oc="${rest%%$tab*}"; dt="${rest#*$tab}"; utc="$(_felix_discover_utc "$ep")"
  case "$oc" in
    ran) printf 'stale\t%s\tdiscovery cache; the last background refresh ran at %s, and the next session in its checkout starts another\n' "$name" "$utc" ;;
    failed) printf 'discover-unread\t%s\tthe last background refresh, at %s, failed: %s; felix discover --adopt in its checkout fills the cache in the foreground\n' "$name" "$utc" "$dt" ;;
    *) printf 'discover-unread\t%s\tthe last background refresh, at %s, ran nothing: %s; felix discover --adopt in its checkout fills the cache in the foreground\n' "$name" "$utc" "$dt" ;;
  esac
}

# The paragraph a session start owes when the cache is stale and the last
# background refresh ran nothing or failed, said once for each outcome and detail:
# the epoch differs every attempt and a refresh that fails the same way every
# session would otherwise be said every session. $3 is stale or fresh, which the
# caller already knows. Nothing is owed over a ran record, no record, or a record
# that cannot be read (the pulse says that); a cache that reads fresh, or a
# refresh that ran, forgets what was said, so a recurrence is said again.
felix_discover_notice() {   # PROJ HOME stale|fresh
  local p="${1%/}" name rec rc ep rest oc dt said tab=$'\t' base
  name="${p##*/}"; base="$2/state/discover/$name.said"
  rec="$(felix_discover_refresh_read "$1" "$2")"; rc=$?
  if [ "$3" != stale ]; then rm -f "$base" 2>/dev/null; return 0; fi
  [ "$rc" = 0 ] || return 0
  ep="${rec%%$tab*}"; rest="${rec#*$tab}"; oc="${rest%%$tab*}"; dt="${rest#*$tab}"
  if [ "$oc" = ran ]; then rm -f "$base" 2>/dev/null; return 0; fi
  said=""; { IFS= read -r said || :; } 2>/dev/null < "$base"
  [ "$said" != "$oc$tab$dt" ] || return 0
  printf '%s\n' "$oc$tab$dt" > "$base" 2>/dev/null
  printf 'Discovery has not refreshed for %s: the last background refresh, at %s, %s: %s. felix discover --adopt fills the cache in the foreground.' \
    "$name" "$(_felix_discover_utc "$ep")" "$([ "$oc" = failed ] && printf failed || printf 'ran nothing')" "$dt"
}
