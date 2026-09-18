# Exceptions: what a person has excepted, for a while, from blocking a task.
#
# Amendments §3, first increment (docs/2026-09-17-exception-channel-design.md).
# A row in projects/<name>/exceptions.tsv clears ONE admitted obligation of
# class TASK_BLOCKING at the task moment and nothing else. It is keyed to the
# obligation's row by content hash, carries an absolute expiry, and reads as
# no clearance when missing, malformed, expired or moved.
#
# THE ONE THING THIS FILE IS FOR IS WHERE IT READS FROM. A session can write
# any file in the tree, so a grant read from the working tree is a grant the
# session can give itself, and the amendment says the grant must not be a
# command the model can invoke. So this reads the table from the REMOTE-
# TRACKING MAIN, refs/remotes/origin/main and nothing else, of the repository that
# holds projects/<name>/: the checkout itself when Felix governs itself, the
# Felix home for a governed product — and only its REMOTE-TRACKING main,
# refs/remotes/origin/main, never a local branch, because a local branch is
# the session's to move. A row in the working tree, on a branch, on a local
# main, or in a repository with no remote clears nothing. Merging the row
# is what makes it a grant, and merging it is an escape (`exception`, in
# escape.sh) that felix merge hands to a person. The session can write the
# grant, cannot make it effective, and the act that does is one the boundary
# takes from it.
#
# DIRECTION OF FAILURE. A clearance widens: every reader here has one success
# path — a well-formed row naming this obligation, a hash that prefixes this
# row's hash by twelve or more characters, an expiry of the right shape that
# has not passed, an obligation whose class is TASK_BLOCKING — and every other
# path prints nothing. A git that cannot show the file, a repository with no
# toplevel, a file with no rows: nothing, identically. Nothing here is a
# verdict about the obligation; it is a person's dated acceptance that the
# obligation does not stop this task.
#
# THE HASH covers the exact ledger line, tabs and reason included, with its
# newline: `printf '%s\n' "$line" | git hash-object --stdin`, which is also
# what `git hash-object --stdin <<< "$line"` computes. `felix obligations`
# prints it beside each row so nobody computes it by hand. A reason edit
# therefore voids the grant, and that is the clause: an obligation cannot be
# rewritten under a live grant.
#
# THE EXPIRY is compared as text. YYYY-MM-DDTHH:MM:SSZ is fixed-width and
# UTC, so two stamps of that shape order as strings order, and no date is
# parsed — GNU and BSD date parse differently and the engine is bash and git
# on both. A stamp of any other shape is malformed and clears nothing. `now`
# is the same shape from `date -u`; a wrong clock can only make a grant read
# expired early or late by that clock's error, and the receipt the gate
# writes carries its own stamp beside the verdict.

if ! command -v felix_base_ref >/dev/null 2>&1; then
  . "$(dirname "${BASH_SOURCE[0]:-$0}")/resolve.sh"
fi

FELIX_EXCEPTION_STAMP='^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]T[0-9][0-9]:[0-9][0-9]:[0-9][0-9]Z$'
FELIX_EXCEPTION_HASH_MIN=12
# How far out a grant may expire: the year after the current one, at most. A
# person who wants longer merges the row again next year, which is the point.
FELIX_EXCEPTION_HORIZON_YEARS=1

# `now` is the LATER of the machine clock and the base commit's own date, both
# in the stamp's shape. The clock is a binary on PATH, which a session
# controls; a shim that answered March would revive every grant that expired
# since. The base commit's date is monotone, lives in the object store, and
# moves only when the ref moves, so a grant that had expired by the time the
# ref was last fetched can never read as live, whatever the clock says.
_felix_exceptions_now() {   # [proj] -> stamp
  local clock ref
  clock="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  # format-local, not format: TZ applies only to the former, and the latter
  # renders the commit's own zone with a Z glued on — three reviewers, one bug.
  ref="$([ -n "${1:-}" ] && TZ=UTC git -C "$(felix_exceptions_repo "$1" 2>/dev/null || printf .)" log -1 --date=format-local:%Y-%m-%dT%H:%M:%SZ --format=%cd refs/remotes/origin/main 2>/dev/null)"
  if [ -n "$ref" ] && [[ "$ref" > "$clock" ]]; then printf '%s\n' "$ref"; else printf '%s\n' "$clock"; fi
}

# The repository that holds the project directory, and the table's path in
# it. Physical paths on both sides, so a symlinked home and a worktree agree
# with what `git show` will be asked for.
felix_exceptions_repo() { git -C "$1" rev-parse --show-toplevel 2>/dev/null; }
felix_exceptions_rel()  {   # proj -> path of exceptions.tsv relative to the repo toplevel
  local proj repo
  proj="$(cd "$1" 2>/dev/null && pwd -P)" || return 1
  repo="$(felix_exceptions_repo "$proj")" || return 1
  [ -n "$repo" ] && [ "$proj" != "$repo" ] || return 1
  case "$proj" in "$repo"/*) printf '%s/exceptions.tsv\n' "${proj#"$repo"/}" ;; *) return 1 ;; esac
}

# The ref the grants are read from: the REMOTE-TRACKING main, verified by its
# full name, or nothing. Not felix_base_ref's fallback to a local `main`: a
# local branch is the session's to move — `git update-ref`, a commit on the
# home checkout, which sits on main — and a grant read from it would be a
# grant the session gave itself. refs/remotes/origin/main moves only when
# something is fetched from the remote, which is where the person is. A
# repository with no remote therefore has no grants, which is the honest
# reading: it has no person-side of a merge either.
felix_exceptions_ref() {   # proj -> ref
  local repo; repo="$(felix_exceptions_repo "$1")" || return 1
  git -C "$repo" rev-parse --verify --quiet refs/remotes/origin/main >/dev/null 2>&1 || return 1
  printf 'origin/main\n'
}
# When that ref was last moved, for the person reading the listing: a grant
# revoked on the remote is honoured here until somebody fetches, and nothing
# on the enforcing path fetches.
felix_exceptions_ref_date() {   # proj -> ISO date of the ref's commit, or nothing
  local repo; repo="$(felix_exceptions_repo "$1")" || return 1
  TZ=UTC git -C "$repo" log -1 --date=format-local:%Y-%m-%dT%H:%M:%SZ --format=%cd refs/remotes/origin/main 2>/dev/null
}

# The table as the base ref holds it. Nothing when there is no repository, no
# base ref, or no file at that commit — and nothing, deliberately, when git
# fails for any other reason: a reader that cannot see the grant has no grant.
felix_exceptions_at_base() {   # proj -> file text
  local proj="$1" repo ref rel
  repo="$(felix_exceptions_repo "$proj")" || return 1
  ref="$(felix_exceptions_ref "$proj")" || return 1
  rel="$(felix_exceptions_rel "$proj")" || return 1
  git -C "$repo" show "refs/remotes/$ref:$rel" 2>/dev/null
}

# Rows and refusals, from text on stdin. One scan decides both, the way the
# obligation ledger's does, so the two cannot disagree about what a row is.
# A row is five or more tab-separated fields with the first four non-empty;
# comments and blank lines are skipped; nothing else is a row.
_felix_exceptions_scan() {   # mode (rows|bad) <- text
  local mode="$1"
  awk -F'\t' -v mode="$mode" -v stamp="$FELIX_EXCEPTION_STAMP" -v hmin="$FELIX_EXCEPTION_HASH_MIN" '
    /^[[:space:]]*(#|$)/ { next }
    {
      sub(/\r$/, "")
      why = ""
      if ($1 == "")                         why = "a row with no obligation name"
      else if (NF < 5)                      why = $1 ": " NF " field(s), and a grant has five"
      else if ($2 !~ /^[0-9a-f]+$/ || length($2) < hmin)
                                            why = $1 ": row_hash is not " hmin "+ hex characters"
      else if ($3 !~ stamp || substr($3, 6, 2) < "01" || substr($3, 6, 2) > "12" \
               || substr($3, 9, 2) < "01" || substr($3, 9, 2) > "31" || substr($3, 12, 2) > "23" \
               || substr($3, 15, 2) > "59" || substr($3, 18, 2) > "60")
                                            why = $1 ": expires is not YYYY-MM-DDTHH:MM:SSZ"
      else if ($4 == "")                    why = $1 ": nobody is named as granting it"
      if (mode == "rows" && why == "") print
      if (mode == "bad"  && why != "") print why
    }'
  return 0
}
felix_exceptions_rows()      { _felix_exceptions_scan rows; }
felix_exceptions_malformed() { _felix_exceptions_scan bad; }

# The hash a grant is keyed to: the ledger line, verbatim, with its newline.
felix_obligation_row_hash() {   # proj obligation -> hash, or nothing
  local proj="$1" name="$2" line
  line="$(felix_obligation_rows "$proj" | awk -F'\t' -v n="$name" '$1 == n { print; exit }')"
  [ -n "$line" ] || return 1
  printf '%s\n' "$line" | git hash-object --stdin 2>/dev/null
}

# Does a valid grant clear this obligation, now? Prints
#   excepted|<expires>|<granted_by>
# — a bar, because the stamp carries colons — for the well-formed rows at the
# base ref that name the obligation, prefix its current row hash, have not
# expired, lie within the horizon, and name a TASK_BLOCKING row; among
# several LIVE rows the earliest expiry wins, so at any instant adding a row
# can only narrow the grant. Across time a later row takes over once the
# earlier has expired, which is a person extending a grant by merging again;
# the horizon bounds every row. Otherwise nothing, exit 1. The class and the ledger line come from the
# caller, which is the run that already has both in hand, so this never
# re-reads the ledger and cannot key the grant to a different line than the
# one being judged.
felix_exception_for() {   # proj obligation class ledger-line [now] -> excepted:... | nothing
  local proj="$1" name="$2" cls="$3" line="$4" now="${5:-}" text hash row h exp who
  [ "$cls" = "TASK_BLOCKING" ] || return 1
  [ -n "$line" ] || return 1
  # An authority hold — pathway `unknown` — blocks whatever its discharge says
  # and no grant may clear it (amendments §1.3).
  [ "$(printf '%s\n' "$line" | cut -f3)" != "unknown" ] || return 1
  text="$(felix_exceptions_at_base "$proj")" || return 1
  [ -n "$text" ] || return 1
  hash="$(printf '%s\n' "$line" | git hash-object --stdin 2>/dev/null)"
  [ -n "$hash" ] || return 1
  [ -n "$now" ] || now="$(_felix_exceptions_now "$proj")"
  printf '%s\n' "$now" | grep -qE "$FELIX_EXCEPTION_STAMP" || return 1
  local best="" bestwho="" maxyear=$(( ${now%%-*} + FELIX_EXCEPTION_HORIZON_YEARS ))
  while IFS= read -r row; do
    [ -n "$row" ] || continue
    [ "$(printf '%s\n' "$row" | cut -f1)" = "$name" ] || continue
    h="$(printf '%s\n' "$row" | cut -f2)"
    exp="$(printf '%s\n' "$row" | cut -f3)"
    who="$(printf '%s\n' "$row" | cut -f4)"
    case "$hash" in "$h"*) ;; *) continue ;; esac
    [[ "$exp" > "$now" ]] || continue
    [ "${exp%%-*}" -le "$maxyear" ] 2>/dev/null || continue
    if [ -z "$best" ] || [[ "$exp" < "$best" ]]; then best="$exp"; bestwho="$who"; fi
  done <<EOF
$(printf '%s\n' "$text" | felix_exceptions_rows)
EOF
  [ -n "$best" ] || return 1
  printf 'excepted|%s|%s\n' "$best" "$bestwho"
  return 0
}

# Every grant at the base ref, judged against the ledger as it stands, for the
# person reading `felix obligations`. One line per row:
#   live|armed|refused <TAB> obligation <TAB> expires <TAB> granted_by <TAB> why
# `armed` is a valid grant on a row that is DORMANT now: it clears nothing
# today and will the day the grounded state makes the row apply, which the
# person merging it should see as what it is.
felix_exceptions_judge() {   # proj [now] [run-output] -> lines
  local proj="$1" now="${2:-}" runout="${3:-}" text row name h exp who cls line hash why appl maxyear
  text="$(felix_exceptions_at_base "$proj")" || return 0
  [ -n "$now" ] || now="$(_felix_exceptions_now "$proj")"
  maxyear=$(( ${now%%-*} + FELIX_EXCEPTION_HORIZON_YEARS ))
  printf '%s\n' "$text" | felix_exceptions_malformed | while IFS= read -r why; do
    [ -n "$why" ] && printf 'refused\t%s\t-\t-\t%s\n' "${why%%:*}" "$why"
  done
  printf '%s\n' "$text" | felix_exceptions_rows | while IFS= read -r row; do
    [ -n "$row" ] || continue
    name="$(printf '%s\n' "$row" | cut -f1)"; h="$(printf '%s\n' "$row" | cut -f2)"
    exp="$(printf '%s\n' "$row" | cut -f3)";  who="$(printf '%s\n' "$row" | cut -f4)"
    line="$(felix_obligation_rows "$proj" | awk -F'\t' -v n="$name" '$1 == n { print; exit }')"
    why=""
    if [ -z "$line" ]; then why="names an obligation the ledger does not admit"
    else
      cls="$(printf '%s\n' "$line" | cut -f2)"
      hash="$(printf '%s\n' "$line" | git hash-object --stdin 2>/dev/null)"
      if [ "$cls" != "TASK_BLOCKING" ]; then why="names a $cls obligation, which no exception may clear"
      elif [ "$(printf '%s\n' "$line" | cut -f3)" = "unknown" ]; then why="names an authority hold, which no exception may clear"
      else case "$hash" in "$h"*) ;; *) why="keyed to a row that has since changed" ;; esac
      fi
      [ -z "$why" ] && ! [[ "$exp" > "$now" ]] && why="expired"
      [ -z "$why" ] && ! [ "${exp%%-*}" -le "$maxyear" ] 2>/dev/null && why="expires past the horizon, which is the end of next year"
    fi
    appl="$(printf '%s\n' "$runout" | awk -F'\t' -v n="$name" '$1 == n { print $4; exit }')"
    if [ -n "$why" ]; then printf 'refused\t%s\t%s\t%s\t%s\n' "$name" "$exp" "$who" "$why"
    elif [ "$appl" = "DORMANT" ]; then printf 'armed\t%s\t%s\t%s\tclears %s if it becomes applicable, until %s\n' "$name" "$exp" "$who" "$name" "$exp"
    else printf 'live\t%s\t%s\t%s\tclears %s until %s\n' "$name" "$exp" "$who" "$name" "$exp"; fi
  done
  return 0
}

# Rows the working tree holds that the base ref does not: written, not yet a
# grant. Shown so a person can see what they wrote before it is merged.
# Read from the governed ROOT's working tree when it and the project share a
# repository: in a worktree session $proj is the home checkout's copy of the
# tables, and the rows a person wrote in this tree live under $root.
felix_exceptions_unmerged() {   # proj [root] -> rows
  local proj="$1" root="${2:-}" f="$1/exceptions.tsv" base rel
  if [ -n "$root" ] && command -v felix_same_repo >/dev/null 2>&1 && felix_same_repo "$proj" "$root" 2>/dev/null \
     && rel="$(felix_exceptions_rel "$proj")"; then f="$root/$rel"; fi
  [ -f "$f" ] || return 0
  base="$(felix_exceptions_at_base "$proj" 2>/dev/null)" || base=""
  felix_exceptions_rows < "$f" | while IFS= read -r row; do
    [ -n "$row" ] || continue
    printf '%s\n' "$base" | felix_exceptions_rows | grep -qxF -- "$row" || printf '%s\n' "$row"
  done
  return 0
}

# The third number: grants at the base ref, well-formed, whatever their state.
felix_exceptions_count() {   # proj -> N
  local text; text="$(felix_exceptions_at_base "$1")" || { printf '0\n'; return 0; }
  printf '%s\n' "$text" | felix_exceptions_rows | grep -c .
  return 0
}
