# Earned auto-merge.
#
# The guidebook's last principle is that autonomy is earned by proving
# reliability, and the ladder it draws ends at acting autonomously within policy
# rather than starting there. The machinery for auto-merge exists: a green tier
# means no risky path was touched, and no evidence gap means the change proved
# itself. What does not exist is evidence that the rules draw the line where
# anyone would draw it, because the rules were written in one sitting and no
# change has gone through them yet.
#
# So the criterion is a mechanism, not a note. "Turn it on in five PRs" is a
# promise that gets forgotten or, worse, remembered early. This counts.
#
# A green pull request is clean when its own CI never failed. A green
# classification says the local judgement was that nothing risky was touched; CI
# failing afterwards means that judgement was wrong, which is the thing being
# tested. Nothing here counts test flakes as evidence of good rules, because a
# red run is a red run and the whole point is to be strict about what earns trust.

FELIX_AUTOMERGE_REQUIRED="${FELIX_AUTOMERGE_REQUIRED:-5}"

# Emits: pr <TAB> clean|dirty|unknown <TAB> title, newest first.
#
# `unknown` exists because the count that decides this comes off the network.
# An errored or rate-limited `gh run list` prints nothing, and an empty answer
# defaulted to zero — so "we could not find out" read as "nothing failed", and
# the one state that must never be guessed was guessed in the direction that
# advances the streak. Only a number that arrived is evidence.
# Which of three states a pair of run counts describes.
#
# Split out to be testable, and because the case that matters is not one the
# three names make obvious. `gh run list --branch <b>` on a branch that no
# longer exists — which is every merged pull request the moment its branch is
# deleted — returns `[]`, and the length of `[]` is zero. So "no runs found" and
# "no failures" arrive as the same number, and the first was being read as the
# second: a streak that claims CI agreed, advanced by a branch CI may never have
# run on at all. A total of zero is the absence of evidence, not evidence.
felix_automerge_state() {
  local total="$1" failures="$2"
  case "${total:-x}"    in *[!0-9]*) printf 'unknown'; return 0 ;; esac
  case "${failures:-x}" in *[!0-9]*) printf 'unknown'; return 0 ;; esac
  if [ "$total" -eq 0 ] 2>/dev/null; then printf 'unknown'; return 0; fi
  if [ "$failures" -eq 0 ] 2>/dev/null; then printf 'clean'; else printf 'dirty'; fi
}

felix_automerge_history() {
  local repo="$1" limit="${2:-20}"
  gh pr list --repo "$repo" --state merged --label risk-green \
     --limit "$limit" --json number,title,headRefName \
     -q '.[] | "\(.number)\t\(.headRefName)\t\(.title)"' 2>/dev/null \
  | while IFS=$'\t' read -r num branch title; do
      [ -n "${num:-}" ] || continue
      local counts total failures
      counts="$(gh run list --repo "$repo" --branch "$branch" --limit 20 \
                  --json conclusion \
                  -q '[length, ([.[] | select(.conclusion=="failure")] | length)] | @tsv' 2>/dev/null)"
      total="${counts%%	*}"; failures="${counts##*	}"
      printf '%s\t%s\t%s\n' "$num" "$(felix_automerge_state "$total" "$failures")" "$title"
    done
}

# Consecutive clean greens at the head of the history.
felix_automerge_streak() {
  local history="$1" n=0 num state title
  while IFS=$'\t' read -r num state title; do
    [ -n "${num:-}" ] || continue
    [ "$state" = "clean" ] || break
    n=$((n+1))
  done <<EOF
$history
EOF
  printf '%s' "$n"
}
