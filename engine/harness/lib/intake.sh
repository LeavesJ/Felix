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

# The judge that reads evidence.tsv lives in evidence.sh, and a caller that
# sources this file alone (the suite's brief, a script) must still have it.
if ! command -v _felix_evidence_judge >/dev/null 2>&1; then
  . "$(dirname "${BASH_SOURCE[0]:-$0}")/evidence.sh"
fi

# Which evidence rows a fix touching these paths will have to satisfy:
# `name<TAB>reason` for each row whose `when` reaches PATHS, once. A row the
# table cannot be read for is `name<TAB>why it was not judged`, whatever PATHS
# holds, since a rule nobody can read is a rule nobody can say a fix escapes.
#
# Deliberately not felix_evidence_check: that compares a diff against the policy
# and there is no diff yet, because the work has not happened. This answers the
# forward question instead — what will this have to prove — which is the one
# worth asking before starting rather than after. It shares that check's reader
# (_felix_evidence_judge), so the two never disagree on what a row says.
felix_brief_evidence() {
  _felix_evidence_judge "$1" "$2" brief
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

# The title of a pull request when --title gives none, and the squash subject
# felix merge falls back to when gh cannot give the pull request's own: the
# subject of the newest commit this branch made itself.
#
# It was HEAD's subject, and a branch landed by merging main in, taking the
# record and then opening the request ends on none of its own work. #395 reached
# main titled "Merge remote-tracking branch 'origin/main' into
# claude/red-counts-unreached". Replayed over the sixty pull requests merged
# before this, HEAD's subject was a merge for 31 of them and a version slot or a
# suite record for 16 more. Under this rule none is a merge. Two are a record,
# each a commit that also changed tests/run, and six are a handoff section, each
# on a pull request that was itself a handoff.
#
# Three kinds of commit are passed over:
# - Merges, by --no-merges.
# - What a merge brought in, by --first-parent. A branch that merges another
#   branch's head before that one lands holds its commits, and after a squash
#   merge main never does. #404 merged carrier/unattended-pin, which carried
#   other pull requests' heads, and newest first its title would have been one
#   of their commits.
# - A commit whose every path is one the landing writes: the engine's version
#   slot, the suite's manifest and red record, and a handoff section under
#   $FELIX_HANDOFF_PENDING. They are named by path because their subjects
#   follow no one convention: test(record), test(red), chore(tests),
#   chore(version) and chore(engine) are all in the history. The first three
#   are paths in the engine's own tree, which a repository holds only if it
#   carries that tree. The last is where felix handoff --section writes, in any
#   project.
#
# A commit that touches no path is not passed over, since the landing wrote
# nothing in it. When every commit of the branch's own is the landing's, the
# newest of them is the title. When the branch made none, or the base cannot
# be read, it is HEAD's subject, as it always was.
#
# --no-show-signature on both reads, because log.showSignature prints a
# verification line that was read as a sha and left the title empty. The --
# after the title's revision, because a tracked file named HEAD makes it
# ambiguous. A range is never read as a path, so the branch's read needs none.
felix_pr_title() {
  local root="$1" base="$2" own c p paths first="" mine=""
  local pending="${FELIX_HANDOFF_PENDING:-docs/handoff/pending}"
  own="$(git -C "$root" log --no-show-signature --first-parent --no-merges --format=%H "$base..HEAD" 2>/dev/null)"
  while IFS= read -r c; do
    [ -n "$c" ] || continue
    [ -n "$first" ] || first="$c"
    paths="$(git -C "$root" diff-tree --root --no-commit-id --name-only -r "$c" 2>/dev/null)"
    while IFS= read -r p; do
      case "$p" in
        engine/.claude-plugin/plugin.json|engine/harness/tests/assertions.tsv|engine/harness/tests/red.tsv) ;;
        "$pending"/*) ;;
        *) mine="$c"; break ;;
      esac
    done <<EOF
$paths
EOF
    [ -n "$mine" ] && break
  done <<EOF
$own
EOF
  git -C "$root" log --no-show-signature -1 --format=%s "${mine:-${first:-HEAD}}" -- 2>/dev/null
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
    # rc 3 is kept: an unattended start refuses red work, because running with
    # nobody present is consent the founder grants. The sentence is not a merge
    # rule, and used to read as one.
    printf '\nOUT OF SCOPE for an unattended start: this implicates a red path. In a\n'
    printf 'session, read it adversarially and do the work. The tier is advice; felix\n'
    printf 'merge stops only on an escape channel, which is where a person decides.\n'
    return 3
  fi
  return 0
}
