# Risk classification for a diff.
#
# The guidebook's merge policy (p8) sorts changes into green, yellow, and red.
# The labels existed already; nothing decided which one applied, so they sat
# unused and every change was treated identically.
#
# Three properties this has to have, or it is worse than nothing.
#
# Deterministic. A classifier a model can talk itself past is not a gate. These
# are declared patterns matched against a diff, and the same diff always
# produces the same tier.
#
# Conservative by default. A file matching no rule is yellow, never green. Green
# has to be earned by matching a pattern someone deliberately declared safe, so
# an unfamiliar file cannot get itself auto-merged by being unrecognised.
#
# Escalate-only. The highest tier any file reaches wins for the whole diff. One
# red file makes the change red no matter how much green sits beside it, because
# risk does not average.
#
# risk.tsv rows: tier <TAB> kind <TAB> pattern <TAB> reason
#   kind=path     extended regex matched against each changed path
#   kind=content  extended regex matched against added lines only

# felix_changed_paths lives in resolve.sh, which every hook and the CLI source
# first. Sourced here too rather than assumed: a lib whose helper is missing
# returns an empty path list, which reads as "nothing changed" and silently
# stops enforcing. That is the same shape as a test that is green because it
# cannot reach the branch it names, and it cost 15 assertions to notice.
if ! command -v felix_changed_paths >/dev/null 2>&1; then
  . "$(dirname "${BASH_SOURCE[0]:-$0}")/resolve.sh"
fi

# A rule change may only ever tighten the diff that carries it.
#
# When Felix governs itself the risk table is a tracked file in the repository
# being classified, so a commit could add a green row and then be judged by the
# row it had just added. That is the candidate writing its own judge, and it is
# the circularity the earned-autonomy decision names in §4a: the evaluator must
# be the base version, `V_n` judging `V_n+1`.
#
# Achieved here for the tables, which is the half of the authority kernel that
# is data rather than code. Both versions are evaluated and the stricter wins:
# a widening takes effect from the next diff on, a tightening takes effect at
# once. The asymmetry is escape.sh's, for the same reason — failing to demote
# costs a founder one look, failing to stop costs whatever the rule guarded.
#
# The engine half is not fixed by this and cannot be from inside the tree: the
# CLI sources lib/*.sh from the branch under judgement, so a branch's escape.sh
# evaluates that branch. Closing that needs a pinned base engine or an
# enforcement point off the tree, which is issue #2. Said plainly here because
# a partial kernel that reads as a whole one is worse than none.

FELIX_RISK_DEFAULT="yellow"

# The repo-relative path of an enforcing table, when the repository being
# classified is the one that holds it. Fails otherwise.
#
# This is exactly the condition under which a branch can rewrite the rules it
# is about to be judged by, and it is also the guard against a fix for Felix
# becoming a regression for every project Felix governs: a governed product's
# tables live in the Felix home and are not in its diff at all. Reading a base
# version that was never there would yield no rows and floor every product diff
# at the yellow default.
felix_table_rel() {
  local root="$1" abs="$2" dir base rel
  [ -f "$abs" ] || return 1
  dir="$(dirname "$abs")"; base="$(basename "$abs")"
  # Same repository, asked of git — not the same string prefix. The prefix test
  # got two ordinary cases wrong and got them wrong by switching the guard off:
  # a worktree, whose root is a different directory in the same repository, and
  # a macOS /var versus /private/var pair, which is one directory spelled twice.
  # felix_same_repo exists because two earlier path-prefix guards lapsed exactly
  # this way, one of them the last defence on the only path in Felix that
  # deletes. A guard that fails open is worth less than no guard, because it
  # also reports that something checked.
  felix_same_repo "$root" "$dir" || return 1
  rel="$(git -C "$dir" ls-files --full-name --error-unmatch -- "$base" 2>/dev/null)" || return 1
  [ -n "$rel" ] || return 1
  printf '%s' "$rel"
}

_felix_risk_rows() {
  local proj="$1"
  [ -f "$proj/risk.tsv" ] || return 0
  grep -vE '^\s*(#|$)' "$proj/risk.tsv"
}

# The rows the tree under judgement inherited. Empty when this branch added the
# table, which floors its own diff at the default — conservative, and a branch
# introducing a whole table has not yet earned the right to be judged by it.
_felix_risk_rows_at() {
  local root="$1" ref="$2" rel="$3"
  git -C "$root" show "$ref:$rel" 2>/dev/null | grep -vE '^\s*(#|$)'
}

_felix_tier_rank() {
  case "$1" in green) echo 0 ;; yellow) echo 1 ;; red) echo 2 ;; *) echo 1 ;; esac
}

# One table's verdict on one diff.
#
# Split out so the same rules can be applied to two versions of the table
# without the second pass being a copy of the first that drifts from it.
_felix_classify_pass() {
  local rows="$1" paths="$2" added="$3"
  local tier kind pattern reason f
  local matched_paths=""
  while IFS=$'\t' read -r tier kind pattern reason; do
    [ -n "${tier:-}" ] || continue
    case "$kind" in
      path)
        while IFS= read -r f; do
          [ -n "$f" ] || continue
          if printf '%s' "$f" | grep -qE "$pattern"; then
            printf '%s\t%s\t%s\n' "$tier" "$f" "$reason"
            matched_paths="$matched_paths
$f"
          fi
        done <<EOF
$paths
EOF
        ;;
      content)
        if [ -n "$added" ] && printf '%s' "$added" | grep -qE "$pattern"; then
          printf '%s\tADDED-LINES\t%s\n' "$tier" "$reason"
        fi
        ;;
    esac
  done <<EOF
$rows
EOF

  # Anything no rule recognised. Reported so the default is visible rather than
  # silently deciding the outcome. Applied per pass, because a path a green row
  # was just written for is precisely a path the inherited table did not know,
  # and its default is the verdict that has to survive.
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    felix_has_line "$matched_paths" "$f" || \
      printf '%s\t%s\tno rule matched\n' "$FELIX_RISK_DEFAULT" "$f"
  done <<EOF
$paths
EOF
}

# Emits: tier <TAB> path-or-ADDED <TAB> reason, one line per rule that fired.
#
# Findings from both versions of the table, deduplicated. When the table is not
# in the diff — every governed product, and most of Felix's own changes — the
# two passes are identical and the output is what it always was. When it is, a
# path whose tier moved appears twice, which is the truth about a diff that
# changed the rules, and felix_classify_tier already takes the highest.
felix_classify_diff() {
  local proj="$1" base="$2" root="$3"
  local paths added rel out

  # An unresolvable base yields no findings, and no findings reduces to green —
  # the tier that can auto-merge. That is not a cosmetic misreport: cmd_pr takes
  # this same reduction and LABELS the pull request with it. So the emptiness
  # has to be distinguishable from a clean diff before anything consumes it.
  #
  # Emitted as a finding rather than returned as a status, because every caller
  # reads stdout and drops the exit code. felix_classify_tier promotes this to
  # `unknown`, which outranks every tier — receipt.sh's stated precedence, since
  # a verdict computed from inputs nobody read is the confident wrong answer.
  if [ -n "$base" ] && ! felix_base_resolves "$root" "$base"; then
    printf 'unknown\t%s\tthis base names nothing here, so nothing was compared\n' "$base"
    return 0
  fi

  paths="$(felix_changed_paths "$root" "$base")"
  # Added lines only. A removed secret is not a new exposure, and counting it as
  # one trains people to ignore the finding.
  added="$(git -C "$root" diff "$base...HEAD" 2>/dev/null | grep '^+' | grep -v '^+++' || true)"

  out="$(_felix_classify_pass "$(_felix_risk_rows "$proj")" "$paths" "$added")"

  if rel="$(felix_table_rel "$root" "$proj/risk.tsv")"; then
    out="$out
$(_felix_classify_pass "$(_felix_risk_rows_at "$root" "$base" "$rel")" "$paths" "$added")"
  fi

  printf '%s\n' "$out" | grep -v '^[[:space:]]*$' | LC_ALL=C sort -u
}

felix_classify_tier() {
  local findings="$1" best=0 rank line tier
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    tier="${line%%	*}"
    # Not knowing outranks every tier, and returns immediately rather than
    # ranking. _felix_tier_rank maps anything it does not recognise to 1, so
    # without this an unknown finding reduced to `yellow` — a computed-looking
    # answer to a question nobody asked, which is worse than the green it
    # replaced because it looks deliberate.
    [ "$tier" = "unknown" ] && { echo unknown; return 0; }
    rank="$(_felix_tier_rank "$tier")"
    [ "$rank" -gt "$best" ] && best="$rank"
  done <<EOF
$findings
EOF
  case "$best" in 0) echo green ;; 2) echo red ;; *) echo yellow ;; esac
}
