# The incident loop.
#
# Production should generate structured work, not detective work. Felix turns an
# error into a brief: which files it names, which commits last touched them, how
# severe that makes it, and what a fix will have to prove.
#
# It supplies scaffolding and refuses to supply judgment, the same division the
# repair loop takes. Reading a stack trace is mechanical. Deciding what actually
# broke is not, and a script that guessed would be believed.
#
# Severity is not a new opinion. It falls out of the risk rules already declared:
# a trace naming a red path is severe because that project already said those
# paths are severe. One place to change, one meaning.
#
# Input is error text on stdin or from a file, so the source can be Sentry, a log,
# a CI failure, or something a customer pasted into an email. No integration is
# required for the loop to work, which matters because the alternative is a loop
# that only exists once someone finishes wiring an observability vendor.

# Pull repo-relative paths out of arbitrary error text.
#
# Deliberately conservative: a token is a path only if the file actually exists in
# the checkout. Traces carry library paths, temp directories and line numbers, and
# a brief blaming vendor code is worse than one that says it found nothing.
felix_incident_paths() {
  local root="$1" text="$2"
  # Backtick and asterisk join the split set. Issues are markdown, and a path in
  # markdown is written `like this` — the one convention this repo uses in every
  # file it holds. The candidate carried a backtick at each end, no stripping of
  # leading components could ever find a file by that name, and the path was
  # dropped in silence. Found by filing the first issues this repository has ever
  # had: `felix brief` read one that named two files, reported one, and called
  # the tier yellow when the file it dropped is red.
  #
  # Both are delimiters nobody puts in a repo path, which is the same argument
  # the quotes, parens and angle brackets already here rest on.
  printf '%s' "$text" \
    | tr ' \t"'"'"'(),[]<>`*' '\n\n\n\n\n\n\n\n\n\n\n\n\n' \
    | sed -E 's/:[0-9]+(:[0-9]+)?$//; s/,$//; s/^\.\///; s/^[+-]+//' \
    | grep -E '[/.][A-Za-z0-9_]' \
    | sort -u \
    | while IFS= read -r cand; do
        [ -n "$cand" ] || continue
        # A trace almost never carries repo-relative paths. It carries wherever
        # the process was running: /app/src/... in a container, /home/runner/...
        # in CI, /Users/... on a laptop. Strip leading components until the
        # remainder names a file that exists here.
        #
        # Longest match wins, so src/web/app.py is preferred over a bare app.py
        # that happens to exist somewhere unrelated.
        local probe="${cand#/}"
        while [ -n "$probe" ]; do
          if [ -f "$root/$probe" ]; then printf '%s\n' "$probe"; break; fi
          # A path at the end of a clause carries the punctuation with it, and
          # that is how most people write one in an issue. Tried only after the
          # literal form fails, so this can resolve more and never fewer: a file
          # genuinely ending in a dot still wins on the line above.
          #
          # A full stop was the only mark handled, because it was the only one
          # anybody had hit. A colon introducing the offending file — "the
          # failing file is src/thing.py:" — reads the same way to a person and
          # resolved to nothing, and sed only removes a colon with a line number
          # after it.
          local trimmed="$probe"
          while [ "${trimmed%[.,;:]}" != "$trimmed" ]; do trimmed="${trimmed%[.,;:]}"; done
          if [ "$trimmed" != "$probe" ] && [ -f "$root/$trimmed" ]; then
            printf '%s\n' "$trimmed"; break
          fi
          case "$probe" in
            */*) probe="${probe#*/}" ;;
            *)   break ;;
          esac
        done
      done | sort -u
}

# Commits that last touched the implicated files, newest first.
felix_incident_suspects() {
  local root="$1" paths="$2" p
  while IFS= read -r p; do
    [ -n "$p" ] || continue
    git -C "$root" log -1 --format='%h %ad %an %s' --date=short -- "$p" 2>/dev/null \
      | sed "s|^|$p	|"
  done <<EOF
$paths
EOF
}

# Highest declared tier across the implicated files. Severity is derived from the
# project's own risk rules rather than invented here.
# The tier for a set of paths.
#
# Starts at green and escalates, with one rule that is easy to leave out and was:
# a path no row matches contributes FELIX_RISK_DEFAULT, not nothing. risk.tsv's
# own header states it — "Anything matching no rule is yellow. Green must be
# earned by an explicit pattern, so an unfamiliar file can never auto-merge by
# being unrecognised" — and felix_classify_diff obeyed it while this function
# did not. Two readers of one table, disagreeing, and the permissive one was
# what `felix brief` reported to a founder as confidence.
felix_incident_severity() {
  local proj="$1" paths="$2" best="green" tier kind pattern reason p hit
  local rows; rows="$(_felix_risk_rows "$proj")"
  while IFS= read -r p; do
    [ -n "$p" ] || continue
    hit=0
    while IFS=$'\t' read -r tier kind pattern reason; do
      [ "${kind:-}" = "path" ] || continue
      printf '%s' "$p" | grep -qE "$pattern" || continue
      hit=1
      case "$tier:$best" in
        red:*)        best="red" ;;
        yellow:green) best="yellow" ;;
      esac
    done <<EOF2
$rows
EOF2
    if [ "$hit" -eq 0 ]; then
      case "${FELIX_RISK_DEFAULT:-yellow}:$best" in
        red:*)        best="red" ;;
        yellow:green) best="yellow" ;;
      esac
    fi
  done <<EOF
$paths
EOF
  printf '%s' "$best"
}
