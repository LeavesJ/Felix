# Issue intake.
#
# The guidebook's first exit criterion (p41) is "take an issue", and nothing
# read one. Felix turns an issue into the same shape felix repair produces for a
# CI failure: which files it names, what tier that makes it, what a fix will
# have to prove, and which tool this project already decided to reach for.
# Brief on stdout, scope verdict in the exit code.
#
# It supplies scaffolding and refuses to supply judgment, the same division the
# repair and incident loops take. Reading an issue is mechanical. Deciding what
# to build is not, and a script that guessed would be believed.
#
# Rendering is separated from fetching so a brief can be produced from text that
# came from anywhere: gh, a paste, a file. No integration is required for the
# loop to work, which matters because the alternative is a loop that exists only
# once somebody finishes wiring an issue tracker. It is also the only way the
# half worth testing is testable: the suite stubs no `gh` and never has.

# Which evidence rows a fix touching these paths will have to satisfy.
#
# Deliberately not felix_evidence_check: that compares a diff against the policy
# and there is no diff yet, because the work has not happened. This answers the
# forward question instead — what will this have to prove — which is the one
# worth asking before starting rather than after.
felix_brief_evidence() {
  local proj="$1" paths="$2" name when requires reason p
  [ -f "$proj/evidence.tsv" ] || return 0
  grep -vE '^[[:space:]]*(#|$)' "$proj/evidence.tsv" | while IFS=$'\t' read -r name when requires reason; do
    [ -n "${when:-}" ] || continue
    while IFS= read -r p; do
      [ -n "$p" ] || continue
      if printf '%s' "$p" | grep -qE "$when"; then
        printf '%s\t%s\n' "$name" "${reason:-$requires}"
        break
      fi
    done <<EOF
$paths
EOF
  done
}

# The play this project already decided this kind of work goes through.
#
# Scored against the issue text alone, with no working-tree context: the tree
# says what you are standing in, which has nothing to do with an issue you have
# not started. Letting it contribute would route every brief to whatever the
# current branch happens to be about.
felix_brief_play() {
  local proj="$1" text="$2" best
  [ -f "$proj/routes.tsv" ] || return 0
  best="$(felix_route_best "$proj" "$text" "" 2>/dev/null)" || return 0
  printf '%s' "$best" | cut -f7
}

# The body of a pull request, from the commits actually on the branch.
#
# Written from git rather than from anybody's memory of what they did. The
# branch is the record; the memory is not, and the two diverge exactly when it
# matters most.
felix_pr_body() {
  local root="$1" base="$2"
  printf 'what this carries\n\n'
  git -C "$root" log --format='- %s' "$base..HEAD" 2>/dev/null
}

# Prints the brief. Returns 3 when a red path is implicated, matching
# felix repair's contract so the same callers branch on it unchanged.
felix_brief_render() {
  local proj="$1" root="$2" title="$3" body="$4"
  local implicated sev ev play

  printf 'title:    %s\n' "$title"

  implicated="$(felix_incident_paths "$root" "$title
$body")"

  if [ -z "$implicated" ]; then
    printf 'files:    no file it names exists in this checkout\n'
    printf 'tier:     unknown\n\n'
    printf 'Nothing can be scoped from this mechanically. Read it and say which\n'
    printf 'paths it means before starting, because a brief that guessed would\n'
    printf 'be believed.\n'
    return 0
  fi

  printf 'files:\n'
  printf '%s\n' "$implicated" | sed 's|^|  |'

  # No table means no rule matched anything, which is the unrecognised case and
  # therefore the default tier — not green. Green is earned by an explicit
  # pattern, and a project with no risk.tsv has written none.
  sev="${FELIX_RISK_DEFAULT:-yellow}"
  [ -f "$proj/risk.tsv" ] && sev="$(felix_incident_severity "$proj" "$implicated")"
  printf 'tier:     %s\n' "$sev"

  ev="$(felix_brief_evidence "$proj" "$implicated")"
  if [ -n "$ev" ]; then
    printf '\nwhat a fix must prove\n'
    printf '%s\n' "$ev" | while IFS=$'\t' read -r name reason; do
      [ -n "${name:-}" ] || continue
      printf '  %-12s %s\n' "$name" "$reason"
    done
  fi

  play="$(felix_brief_play "$proj" "$title
$body")"
  [ -n "$play" ] && printf '\nplay:     %s\n' "$play"

  if [ "$sev" = "red" ]; then
    printf '\nOUT OF SCOPE. This implicates a red path. Escalate rather than\n'
    printf 'starting: approval comes before the work, not after it.\n'
    return 3
  fi
  return 0
}
