# Readiness for unattended work.
#
# Reports, and deliberately does not decide. Auto-merge can unlock itself
# because what it unlocks is bounded: a change that already passed the gate, the
# classifier and the evidence policy, and whose worst case is a revert. This is
# not that.
#
# The evidence that would justify flipping this switch cannot be gathered without
# flipping it. Every dry run stops before the model is invoked, so dry runs prove
# the guards run; they prove nothing about whether the guards hold, because
# nothing has yet tried to get past them. Counting them and calling it a track
# record would be measuring the wrong thing carefully.
#
# So this prints what is true and leaves the decision where it belongs.

# The dry runs are the unattended repair workflow's, named by its display name
# where the gate is named by its file (felix_gate_workflow). Each is named by
# whatever is fixed about it: bootstrap writes the gate's file, while a person
# copies templates/unattended.yml to a file of their choosing and the template
# fixes only its `name:`.
#
# Two rows read the workflows themselves, on the default branch, where GitHub
# takes a workflow_run trigger and a dispatch from. Both are about drift that
# nothing else reports: a person copies the template once, and the engine moves
# on without the copy. One governed repository's copy kept proceeding on every
# exit of felix repair but 3 for a day after the template stopped doing so.
#   dispatch  yes|no|unread   whether the gate workflow takes workflow_dispatch.
#             The repair pushes with the workflow token, and GitHub creates no
#             run from an event that token causes except a dispatch.
#   template  <verdict> <line> <path>   the deployed copy against this engine's
#             template: match, differ at a line of the copy (or `end` when it
#             stops short), absent, or unread. `-` fills a column with nothing
#             to say, since a tab-separated read collapses an empty field.
felix_unattended_state() {
  local repo="$1" gwf="${2:-gate.yml}" tpl="${3:-}" wf='unattended repair' body path
  printf 'switch\t%s\n' \
    "$(gh variable list --repo "$repo" 2>/dev/null | felix_count FELIX_UNATTENDED)"
  printf 'key\t%s\n' \
    "$(gh secret list --repo "$repo" 2>/dev/null | felix_count ANTHROPIC_API_KEY)"
  printf 'dryruns\t%s\n' \
    "$(gh run list --repo "$repo" --workflow "$wf" --limit 50 \
        --json conclusion -q 'length' 2>/dev/null || printf 0)"
  printf 'dryfails\t%s\n' \
    "$(gh run list --repo "$repo" --workflow "$wf" --limit 50 \
        --json conclusion -q '[.[] | select(.conclusion=="failure")] | length' 2>/dev/null || printf 0)"

  # A read that fails is unread, never no: gh's 404 for a missing file and a
  # network that did not answer both land here, and neither is a fact about
  # the workflow.
  if body="$(gh api -H 'Accept: application/vnd.github.raw' \
               "repos/$repo/contents/.github/workflows/$gwf" 2>/dev/null)"; then
    if felix_workflow_dispatchable <<<"$body"; then printf 'dispatch\tyes\n'
    else printf 'dispatch\tno\n'; fi
  else
    printf 'dispatch\tunread\n'
  fi

  if ! path="$(gh api "repos/$repo/actions/workflows" --paginate \
                 -q ".workflows[] | select(.name == \"$wf\" and .state != \"deleted\") | .path" \
                 2>/dev/null)"; then
    printf 'template\tunread\t-\t-\n'; return 0
  fi
  path="${path%%$'\n'*}"
  [ -n "$path" ] || { printf 'template\tabsent\t-\t-\n'; return 0; }
  if [ ! -s "$tpl" ] || ! body="$(gh api -H 'Accept: application/vnd.github.raw' \
                                    "repos/$repo/contents/$path" 2>/dev/null)"; then
    printf 'template\tunread\t-\t%s\n' "$path"; return 0
  fi
  printf 'template\t%s\t%s\n' "$(felix_unattended_template_diff "$tpl" <<<"$body")" "$path"
}

# Whether a workflow file, on stdin, takes workflow_dispatch: as a key under
# `on:`, as an item of its list, or named on the `on:` line itself. A mention
# anywhere else, such as `github.event_name == 'workflow_dispatch'` in an if:,
# is not a trigger and does not count.
felix_workflow_dispatchable() {
  grep -Eq -e '^[[:space:]]+workflow_dispatch[[:space:]]*:' \
           -e '^[[:space:]]+-[[:space:]]+workflow_dispatch[[:space:]]*$' \
           -e "^[\"']?on[\"']?[[:space:]]*:.*(^|[^A-Za-z_])workflow_dispatch([^A-Za-z_]|\$)"
}

# A deployed copy, on stdin, against the template at $1. Prints `match -`, or
# `differ <line>` naming the copy's first line that does not match, `end` when
# the copy stops short.
#
# Comment and blank lines are set aside on both sides, so a copy that keeps a
# note of its own, or lost one of the template's, still matches: a comment
# changes nothing the workflow does. Every other line must be the template's.
# A {{NAME}} placeholder there stands for any non-empty value, so long as the
# value is not itself a placeholder left unfilled.
felix_unattended_template_diff() {
  awk '
    function skip(s) { return s ~ /^[ \t]*(#|$)/ }
    function norm(s) { sub(/[ \t\r]+$/, "", s); return s }
    function unfilled(v) { return v == "" || v ~ /[{][{]/ }
    function fits(t, d,    n, seg, i, rest, p) {
      n = split(t, seg, /[{][{][A-Z_]+[}][}]/)
      if (n == 1) return t == d
      if (substr(d, 1, length(seg[1])) != seg[1]) return 0
      rest = substr(d, length(seg[1]) + 1)
      for (i = 2; i < n; i++) {
        # Two placeholders with nothing between them cannot be told apart.
        if (seg[i] == "") return 0
        p = index(substr(rest, 2), seg[i])
        if (!p || unfilled(substr(rest, 1, p))) return 0
        rest = substr(rest, p + 1 + length(seg[i]))
      }
      if (length(rest) <= length(seg[n])) return 0
      if (substr(rest, length(rest) - length(seg[n]) + 1) != seg[n]) return 0
      return !unfilled(substr(rest, 1, length(rest) - length(seg[n])))
    }
    FNR == NR { if (!skip($0)) T[++nt] = norm($0); next }
    !skip($0) { D[++nd] = norm($0); L[nd] = FNR }
    END {
      for (i = 1; i <= nt; i++) {
        if (i > nd)            { print "differ\tend"; exit }
        if (!fits(T[i], D[i])) { print "differ\t" L[i]; exit }
      }
      if (nd > nt) { print "differ\t" L[nt + 1]; exit }
      print "match\t-"
    }' "$1" -
}
