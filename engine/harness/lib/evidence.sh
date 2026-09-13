# Evidence policy.
#
# The guidebook's table on p7 says what a change must prove before it counts as
# done: code needs tests, a schema change needs database tests, user-facing
# behaviour needs browser coverage, a bug fix needs a regression test that failed
# before the fix. None of it was enforced, so a comment edit and a schema
# migration were gated identically.
#
# What is checkable here is narrow and deliberately so: this diff touched X and
# did not touch Y. That is a heuristic about coverage, not proof of it. A test
# file being edited says nothing about whether the test is any good. What it does
# catch is the common and consequential case, changing behaviour and shipping no
# test at all, which is the failure the table exists to prevent.
#
# Reports by default and exits 0. `--strict` exits non-zero so CI can gate on it.
# Defaulting to hard failure would have blocked legitimate work on day one, and
# a gate that has to be routinely bypassed teaches people to bypass gates.
#
# evidence.tsv rows: name <TAB> when-regex <TAB> requires-regex <TAB> reason

# felix_changed_paths lives in resolve.sh, which every hook and the CLI source
# first. Sourced here too rather than assumed: a lib whose helper is missing
# returns an empty path list, which reads as "nothing changed" and silently
# stops enforcing. That is the same shape as a test that is green because it
# cannot reach the branch it names, and it cost 15 assertions to notice.
if ! command -v felix_changed_paths >/dev/null 2>&1; then
  . "$(dirname "${BASH_SOURCE[0]:-$0}")/resolve.sh"
fi

_felix_evidence_rows() {
  local proj="$1"
  [ -f "$proj/evidence.tsv" ] || return 0
  grep -vE '^\s*(#|$)' "$proj/evidence.tsv"
}

_felix_any_match() {
  local paths="$1" pattern="$2" f
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    printf '%s' "$f" | grep -qE "$pattern" && return 0
  done <<EOF
$paths
EOF
  return 1
}

# Emits: status <TAB> name <TAB> reason.  status is met | gap | n/a | unknown
felix_evidence_check() {
  local proj="$1" base="$2" root="$3"
  local paths

  # Before any row, because `n/a` is a claim about the diff — "this change does
  # not touch that surface" — and a base git cannot name produces no diff to
  # make it about. felix_changed_paths sends git's exit-128 to /dev/null, so
  # every row fell to n/a and the command signed off with "No evidence gaps."
  # #56 closed this on the merge path; this is the same emptiness read one
  # layer up, where a person reads it.
  #
  # One row, not one per rule. The rules were never consulted, so reporting
  # each of them as unknown would imply they were each considered and found
  # unanswerable. Nothing was considered.
  if [ -n "$base" ] && ! felix_base_resolves "$root" "$base"; then
    printf 'unknown\t%s\tthis base names nothing here, so no rule was consulted\n' "$base"
    return 0
  fi

  paths="$(felix_changed_paths "$root" "$base")"

  while IFS=$'\t' read -r name when requires reason; do
    [ -n "${name:-}" ] || continue
    if ! _felix_any_match "$paths" "$when"; then
      printf 'n/a\t%s\t%s\n' "$name" "this change does not touch that surface"
    elif _felix_any_match "$paths" "$requires"; then
      printf 'met\t%s\t%s\n' "$name" "$reason"
    else
      printf 'gap\t%s\t%s\n' "$name" "$reason"
    fi
  done <<EOF
$(_felix_evidence_rows "$proj")
EOF
}
