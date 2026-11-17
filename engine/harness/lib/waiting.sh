# Session start names what waits (audit b03: C002, C029, C038, C069).
#
# Four things used to wait with nobody told, and each had a reason it was not
# said: a pull request the lander cannot land wrote one ledger row and was
# never read back; decisions deferred overnight were shown only to the session
# whose night was live; a PreToolUse hook that could not judge a call allowed
# it and recorded nothing; and a maintenance row only the founder can clear was
# counted as a session's upkeep. This file reads those four back, at the one
# moment that is early enough to matter, and says each in the words of the
# contract (docs/2026-10-24-audit-fixes/b03-session-start-names-what-waits.md).
#
# It is sourced by hooks/session-start, which has no room to grow, and it only
# defines functions. Each sets globals the hook reads: maint_line, _due_n and
# _yours (felix_start_maint); waits_line and _felix_wait_toks (felix_start_waits).
#
# UNREAD IS UNKNOWN, NEVER ZERO. A file that is there and cannot be read says
# so, in the paragraph and in the screen line as `unknown`; only a file that is
# not there, or that holds nothing to name, is silent. Nothing here changes a
# file, and nothing here is allowed to make the hook's JSON unreadable: every
# string from a file written by something else has its control bytes replaced.
#
# Bash 3.2. LC_ALL=C on every text tool; digit brackets spelled out.

# What counts as a wait row is defined beside the tick that ages it. If that file
# does not load, the awk below fails and the paragraph says the list could not be
# read; it is never left out without a word.
if [ -z "${_GT_WAIT_FN-}" ]; then
  _fw_dir="${BASH_SOURCE[0]}"; case "$_fw_dir" in */*) _fw_dir="${_fw_dir%/*}" ;; *) _fw_dir=. ;; esac
  . "$_fw_dir/green-wait.sh" 2>/dev/null || true
fi

_fw_clean() { LC_ALL=C tr '\000-\010\013-\037\177' '?'; }

# An epoch as a UTC ISO time, the one format that sorts as text, so that a time
# window is a string comparison and no awk has to turn a date back into seconds.
_fw_iso() { date -u -r "$1" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -d "@$1" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null; }
_fw_ago() { _fw_iso "$(( $(date +%s) - $1 ))"; }   # SECONDS -> the time that long ago
_fw_mtime() {   # FILE -> its modification time as an epoch, or nothing
  local m; m="$(stat -c %Y "$1" 2>/dev/null || stat -f %m "$1" 2>/dev/null)"
  case "$m" in ''|*[!0123456789]*) ;; *) printf '%s' "$m" ;; esac
}

# Upkeep, and whose it is (C038). Sets maint_line, _due_n and _yours.
#
# Until this existed the line said `Maintenance due: snapshot` and `Do them on
# one branch`, and a row the founder alone can clear (the public snapshot needs
# his yes) read as routine upkeep a session could finish. A row whose third
# column is `founder` (lib/maintenance.sh) comes due as any other does, is
# counted as due, and is named on a line of its own as waiting on him.
#
# Counted before the newlines are flattened. The badge wants HOW MANY are due,
# and by the time this is one space-separated line `grep -c .` can only ever
# answer 1 (#57 item 4). Read once: a checked row runs its check, and a check
# may read every remote branch to say whether its work is already in flight.
felix_start_maint() {   # PROJ ROOT
  local proj="$1" root="$2" st list fnames mine name wh how
  maint_line=""; _due_n=0; _yours=""
  [ -f "$proj/maintenance.tsv" ] || return 0
  st="$(felix_maint_status "$proj" "$root" 2>/dev/null)"
  list="$(printf '%s\n' "$st" | LC_ALL=C awk -F'\t' '$1 == "due" { print $2 }')"
  _due_n="$(printf '%s' "$list" | grep -c . 2>/dev/null)"
  case "$_due_n" in ''|*[!0123456789]*) _due_n=0 ;; esac
  fnames=""; command -v felix_maint_founder >/dev/null 2>&1 && fnames="$(felix_maint_founder "$proj" 2>/dev/null)"
  # The founder's due rows, each as name<TAB>how; the rest, a session's. The
  # names are newline-separated and reach awk through its environment: macOS awk
  # stops with "newline in string" on a newline inside a -v value, which with two
  # founder rows dropped every name from the line and left only the count (review
  # round, B36).
  mine="$(printf '%s\n' "$st" | FW_FOUNDERS="$fnames" LC_ALL=C awk -F'\t' 'BEGIN { n = split(ENVIRON["FW_FOUNDERS"], F, "\n"); for (i = 1; i <= n; i++) if (F[i] != "") fo[F[i]] = 1 }
    $1 == "due" && ($2 in fo) {
      if ($3 == "never") w = "never run, every " $4
      else if ($3 == "check") w = "its check says it is due"
      else if ($3 == "refused") w = "its check is refused"
      else w = $3 " days since it last ran, every " $4
      printf "%s\t%s\n", $2, w }')"
  list="$(printf '%s\n' "$st" | FW_FOUNDERS="$fnames" LC_ALL=C awk -F'\t' 'BEGIN { n = split(ENVIRON["FW_FOUNDERS"], F, "\n"); for (i = 1; i <= n; i++) if (F[i] != "") fo[F[i]] = 1 }
    $1 == "due" && !($2 in fo) { print $2 }')"
  list="$(printf '%s' "$list" | tr '\n' ' ')"; list="${list% }"
  [ -z "$list" ] || maint_line="
Maintenance due: ${list}
Do them on one branch. See 'felix maintenance'."
  if [ -n "$mine" ]; then
    how=""
    while IFS=$'\t' read -r name wh; do
      [ -n "${name:-}" ] || continue
      how="${how:+$how, }${name} (${wh})"; _yours="${_yours:+$_yours, }${name}"
    done <<FWMINE
$mine
FWMINE
    maint_line="${maint_line}
Due, and waiting on the founder's yes rather than a session: ${how}"
  fi
  # A routine a pushed branch is already doing is not due, and saying whose it
  # is keeps a second session from starting it: three sessions folded
  # overlapping handoff sections on 2026-09-24/25 when the row said only
  # "due". Not "elsewhere": the session that pushed the fold reads it too.
  maint_line="${maint_line}$(printf '%s\n' "$st" | LC_ALL=C awk -F'\t' '$1 == "inflight" {
      printf "\nAlready in flight, so not due: %s on %s", $2, $3 }')"
  return 0
}

# The pull requests the lander has aged and that still wait: the count, then
# number<TAB>detail for each, ascending. A pull request is listed when its last
# `waiting` row is less than 26 hours old and every row of its own after that row
# is a wait row (iswait, from lib/green-wait.sh) at that row's head. A hold, a
# landing or a row at another head ends the listing; a row that only changes
# which wait it is (#425 went from `session` to `conflicting with main` and back
# about every five hours for five days) does not. Listing only while the
# `waiting` row was the newest row of any kind dropped such a pull request at its
# first change of wait, and named it again only at the next `waiting` row. The
# tick writes one again 24 hours after the last while the wait lasts, so the
# 26-hour window overlaps its successor.
_FW_PRS_AWK="$_GT_WAIT_FN"'
NF >= 7 && $3 ~ /^[0123456789]+$/ {
  p = $3
  if (!(p in seen)) { seen[p] = 1; order[++n] = p }
  if ($2 == "waiting") { wt[p] = $1; wh[p] = $4; de[p] = $7; ok[p] = 1; next }
  if ((p in wt) && !($4 == wh[p] && iswait($2, $7))) ok[p] = 0 }
END {
  for (i = 1; i <= n; i++) { p = order[i]
    if ((p in wt) && ok[p] && length(wt[p]) == 20 && (wt[p] "") > (cut "")) w[++m] = p }
  for (i = 2; i <= m; i++) { v = w[i]; j = i - 1
    while (j >= 1 && (w[j] + 0) > (v + 0)) { w[j + 1] = w[j]; j-- }
    w[j + 1] = v }
  print m + 0
  for (i = 1; i <= m; i++) print w[i] "\t" de[w[i]] }'

# The deferred queue: the count of rows that are not blank or comments, then the
# oldest all-digit first column when there is one.
_FW_DEFER_AWK='
/^[ \t]*(#|$)/ { next }
{ n++ }
$1 ~ /^[0123456789]+$/ && (!h || ($1 + 0) < lo) { lo = $1 + 0; h = 1 }
END { print n + 0; if (h) printf "%.0f\n", lo }'

# Faults: the count and the newest counted row, the project's own and the ones that
# could name none (`-`), within the window. A row whose time was not recorded takes
# the time of the next row below it that has one, or the log's own modification time
# (a row is written the moment it happens, so the file's time is when the last of
# them did).
_FW_FAULT_AWK='
function iso(t) { return length(t) == 20 && t ~ /^[0123456789][0123456789][0123456789][0123456789]-[0123456789][0123456789]-[0123456789][0123456789]T[0123456789][0123456789]:[0123456789][0123456789]:[0123456789][0123456789]Z$/ }
NF >= 5 { t[++n] = $1; pj[n] = $3; rs[n] = $5 }
END {
  nx = mt
  for (i = n; i >= 1; i--) { if (iso(t[i])) { eff[i] = t[i]; nx = t[i] } else eff[i] = nx }
  for (i = 1; i <= n; i++) if ((pj[i] == proj || pj[i] == "-") && length(eff[i]) == 20 && (eff[i] "") > (cut "")) { c++; last = i }
  print c + 0
  if (c > 0) { print (iso(t[last]) ? t[last] : "-"); print rs[last] } }'

# The paragraphs and the screen tokens (C002, C029, C069). Sets waits_line, each
# paragraph starting on a line of its own, and _felix_wait_toks, the tokens for
# the screen line in the order the contract gives them.
felix_start_waits() {   # PROJ NAME [LAND [HOME]]: LAND is the land row's value as session start read it, HOME its Felix home
  local proj="$1" name="$2" mem land f p why out m body k oldest d n when mt hp=""
  waits_line=""; _felix_wait_toks=""
  mem="$(felix_mem_dir "$proj")"; land="$mem/land"

  # The lander, paused: it merges nothing while it is. When the land row reads paused
  # (lib/status-land.sh: the job is loaded and ticking), session start's landing badge
  # names the pause with its reason, so it is not said here as well. wave-1-combine C7:
  # nor where HOME resolves a project other than this one, which has no lander, and
  # where felix land --resume is refused (audit b05, C013).
  [ -z "${4:-}" ] || hp="$(felix_resolve_project "$4" "$4" 2>/dev/null)" || hp=""
  hp="${hp%/}"; p="${proj%/}"
  [ "${hp##*/}" != "${p##*/}" ] || hp=""
  p="$land/paused"
  if [ "${3:-}" != paused ] && [ -z "$hp" ] && { [ -e "$p" ] || [ -L "$p" ]; }; then
    why=""
    if [ -f "$p" ] && [ -r "$p" ]; then
      IFS= read -r why < "$p" 2>/dev/null || true
      why="${why%$'\r'}"; why="$(printf '%s' "$why" | _fw_clean)"
      [ -n "${why//[[:space:]]/}" ] || why="no reason given"
    else why="the reason could not be read"; fi
    waits_line="${waits_line}
The lander is paused, so nothing merges with nobody present: ${why}
felix land --resume ends the pause."
    _felix_wait_toks="${_felix_wait_toks} · lander paused"
  fi

  # Pull requests the lander has aged (lib/green-wait.sh wrote the rows).
  f="$land/ledger.tsv"
  if [ -e "$f" ] || [ -L "$f" ]; then
    m=""
    if [ -f "$f" ] && [ -r "$f" ] && out="$(LC_ALL=C awk -F'\t' -v cut="$(_fw_ago 93600)" "$_FW_PRS_AWK" "$f" 2>/dev/null)"; then
      m="${out%%$'\n'*}"
      case "$m" in ''|*[!0123456789]*) m="" ;; esac
    fi
    if [ -z "$m" ]; then
      waits_line="${waits_line}
Which pull requests wait could not be read: ${f} is not a readable file."
      _felix_wait_toks="${_felix_wait_toks} · PRs waiting: unknown"
    elif [ "$m" -gt 0 ]; then
      body="$(printf '%s\n' "$out" | sed 1d | head -5 | LC_ALL=C awk -F'\t' '{ printf "  #%s %s\n", $1, $2 }' | _fw_clean)"
      waits_line="${waits_line}
Pull requests waiting longer than four hours, as the lander last saw them (felix land --prs says more):
${body}"
      [ "$m" -le 5 ] || waits_line="${waits_line}
  and $(( m - 5 )) more: felix land --prs"
      _felix_wait_toks="${_felix_wait_toks} · PRs waiting: ${m}"
    fi
  fi

  # Decisions deferred overnight wait on the founder whether or not a night runs.
  f=""; command -v felix_overnight_dir >/dev/null 2>&1 && f="$(felix_overnight_dir "$proj")/deferred.tsv"
  if [ -n "$f" ] && { [ -e "$f" ] || [ -L "$f" ]; }; then
    out=""
    if [ -f "$f" ] && [ -r "$f" ]; then out="$(LC_ALL=C awk -F'\t' "$_FW_DEFER_AWK" "$f" 2>/dev/null)" || out=""; fi
    d="${out%%$'\n'*}"
    case "$d" in
      ''|*[!0123456789]*)
        waits_line="${waits_line}
Decisions deferred overnight could not be read: ${f} is not a readable file."
        _felix_wait_toks="${_felix_wait_toks} · deferred for you: unknown" ;;
      *)
        if [ "$d" -gt 0 ]; then
          oldest="an unknown date"
          case "$out" in *$'\n'*) k="$(_fw_iso "${out#*$'\n'}")"; [ -z "$k" ] || oldest="${k%%T*} (UTC)" ;; esac
          waits_line="${waits_line}
${d} decision(s) deferred overnight wait on the founder, the oldest from ${oldest}.
felix overnight --report reads them back, and felix overnight --clear clears them once read."
          _felix_wait_toks="${_felix_wait_toks} · deferred for you: ${d}"
        fi ;;
    esac
  fi

  # Calls PreToolUse could not judge (C029), counted over the last seven days.
  f="$(felix_mem_root)/hook-faults.log"
  if [ -e "$f" ] || [ -L "$f" ]; then
    out=""
    if [ -f "$f" ] && [ -r "$f" ]; then
      mt="$(_fw_mtime "$f")"; [ -n "$mt" ] || mt="$(date +%s)"
      out="$(LC_ALL=C awk -F'\t' -v proj="$name" -v cut="$(_fw_ago 604800)" -v mt="$(_fw_iso "$mt")" "$_FW_FAULT_AWK" "$f" 2>/dev/null)" || out=""
    fi
    n="${out%%$'\n'*}"
    case "$n" in
      ''|*[!0123456789]*)
        waits_line="${waits_line}
Whether PreToolUse judged every call could not be read: ${f} is not a readable file."
        _felix_wait_toks="${_felix_wait_toks} · calls not judged: unknown" ;;
      *)
        if [ "$n" -gt 0 ]; then
          when="$(printf '%s\n' "$out" | sed -n 2p)"; why="$(printf '%s\n' "$out" | sed -n 3p | _fw_clean)"
          [ "$when" != "-" ] || when="at a time not recorded"
          waits_line="${waits_line}
PreToolUse could not judge ${n} tool call(s) in the last 7 days, so the deny rows were not applied to them and each was allowed. The newest, ${when}: ${why}. Each is a row of ${f}."
          _felix_wait_toks="${_felix_wait_toks} · calls not judged: ${n}"
        fi ;;
    esac
  fi
  return 0
}
