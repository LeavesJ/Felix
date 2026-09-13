# Decision epochs, as hashes.
#
# v3.2 §3 states one:
#
#   decision_epoch = hash(subject_identity, topology_version, policy_version,
#                         release_target)
#
# and the rule it exists for: within one epoch, admitted blocking obligations
# may stay constant or increase, and discovery may not remove or relax them. A
# new grounded topology or a new policy state creates a new epoch, and that is
# when applicability is recomputed. It is what stops an obligation ledger from
# ratcheting permanently, and equally what stops a model from arguing one
# away — the difference between the two is whether the grounded world moved,
# and the epoch is how that question gets a mechanical answer.
#
# This file computes and reports the epoch. It changes no verdict, and the
# omission is deliberate. Felix's existing rule is STRICTER than the spec's:
# shrinking the obligations ledger escapes to a person unconditionally,
# whatever the epoch says. Wiring the epoch into that stop so a shrink became
# permissible when the epoch had moved would widen a mechanical refusal on the
# strength of a hash computed in the same process — the second invariant's
# whole subject. Narrowing may be automated; widening asks.
#
# The four components, and why each is what it is here:
#
#   subject_identity  the project and the repository it governs. Not the tree:
#                     a tree id changes with every commit, and an epoch that
#                     changes with every commit is an epoch that never holds
#                     two decisions, which empties the rule it exists for.
#
#   topology_version  the grounded probe facts. The spec is explicit that
#                     relations ground topology, and probes are where Felix
#                     asks the thing that knows rather than reading a table
#                     that claims. A probe count moving IS the topology moving.
#
#   policy_version    felix_commission_policy_version, which already hashes the
#                     project's table set with a header per file. Amendment 1.1
#                     replaced "signed policy" with exactly this, so there is
#                     nothing to invent.
#
#   release_target    what the decision releases to. For a repository that is
#                     the branch being merged into.
#
# Two properties worth knowing before reading an epoch as a stable window.
#
# It is only as stable as the probes it is grounded in. Felix's own probes
# count tracked files and recorded assertions, so on the project that governs
# itself nearly every commit is a new grounded topology and therefore a new
# epoch. That is the rule answering honestly — the topology did move — but it
# means the "may only add" window is short here and long on a project whose
# probes ask about deployed routes and schema instead. A probe table that
# grounds topology rather than counts files is what lengthens it.
#
# And the components are not independent. `project.json` is both the subject's
# identity and a member of the table set, so editing it moves two of the four.
# For the epoch that is nothing — one hash over four inputs — but the
# components report is read by people, and two lines moving at once is one
# change and not two.
#
# An unknown component is not hashed over. If the probes cannot run, the
# topology is unknown, and a hash taken over the absence would be a different
# epoch every time the probes broke — silently claiming the world had moved.
# felix_epoch prints nothing and fails in that case, and the components report
# says which one is missing.

# Sourced by name when a caller has not already brought them, which is the
# pattern discover.sh uses and for the same reason: the suite sources one
# library at a time in a subshell, and a helper from a sibling that is simply
# assumed turns that into a runtime error rather than a failing assertion.
# commission.sh carries resolve, detect, stack, probes and verify with it, so
# one guard covers every borrowed function here.
if ! command -v felix_commission_policy_version >/dev/null 2>&1; then
  . "$(dirname "${BASH_SOURCE[0]:-$0}")/commission.sh"
fi

_felix_epoch_hash() { git hash-object --stdin 2>/dev/null; }

# The project and the repository it governs, as one line.
felix_epoch_subject() {
  local proj="$1" name remote
  [ -d "$proj" ] || return 1
  name="$(basename "$proj")"
  remote="$(felix_json_str "$proj/project.json" remote_match 2>/dev/null)"
  [ -n "$name" ] || return 1
  printf 'project=%s\nremote=%s\n' "$name" "${remote:--}" | _felix_epoch_hash
}

# The grounded facts, hashed. Sorted, because the epoch is a fact about what
# was found and not about the order a table happened to list it in.
felix_epoch_topology() {
  local proj="$1" root="$2" rows
  rows="$(felix_probes_run "$proj" "$root" 2>/dev/null | LC_ALL=C sort)"
  [ -n "$rows" ] || return 1
  printf '%s\n' "$rows" | _felix_epoch_hash
}

# The project's table set, hashed. The guard in front of it is the same
# argument the digest of a plugin copy makes, and the blind author of these
# assertions made it here before anyone had written it down:
# felix_commission_policy_version emits a header per file whether or not the
# file is there, so a project directory that does not exist hashes to a
# perfectly good sha — and to the SAME sha as every other project with no
# tables. Two absences that compare equal are worse than an absence that
# refuses to answer, so a project with no directory and a project with not one
# table of the set report no policy version at all.
felix_epoch_policy() {
  local proj="$1" v f found=0
  command -v felix_commission_policy_version >/dev/null 2>&1 || return 1
  [ -d "$proj" ] || return 1
  for f in $FELIX_COMMISSION_TABLES; do
    [ -e "$proj/$f" ] && { found=1; break; }
  done
  [ "$found" -eq 1 ] || return 1
  v="$(felix_commission_policy_version "$proj" 2>/dev/null)"
  [ -n "$v" ] || return 1
  printf '%s\n' "$v"
}

# What this decision releases to.
#
# Read from the project first, because a project that deploys somewhere other
# than a branch should say so rather than have this file guess; then from the
# repository's own idea of its default branch; and `main` last, named rather
# than inferred so that a repository with no origin still produces an epoch
# instead of failing over a word.
felix_epoch_target() {
  local proj="$1" root="$2" t
  # Each of these terminates its line. A hash printed without a newline is a
  # prefix of whatever prints next, and two of them appended to one file read
  # back as one value — the other three functions here end in a newline
  # because git hash-object does, and an output contract that holds for three
  # of five is not one.
  if [ -n "${FELIX_RELEASE_TARGET:-}" ]; then printf '%s\n' "$FELIX_RELEASE_TARGET"; return 0; fi
  t="$(felix_json_str "$proj/project.json" release_target 2>/dev/null)"
  if [ -n "$t" ]; then printf '%s\n' "$t"; return 0; fi
  t="$(git -C "$root" symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null)"
  t="${t#origin/}"
  if [ -n "$t" ]; then printf '%s\n' "$t"; return 0; fi
  printf 'main\n'
}

# component <TAB> value, one per line, in the order the spec lists them.
# `-` is an unknown component, and it is the report's whole point: an epoch
# that changed is only useful beside the thing that changed it.
felix_epoch_components() {
  local proj="$1" root="$2" s t p r
  s="$(felix_epoch_subject  "$proj"         )" || s=""
  t="$(felix_epoch_topology "$proj" "$root" )" || t=""
  p="$(felix_epoch_policy   "$proj"         )" || p=""
  r="$(felix_epoch_target   "$proj" "$root" )" || r=""
  printf 'subject_identity\t%s\n'  "${s:--}"
  printf 'topology_version\t%s\n'  "${t:--}"
  printf 'policy_version\t%s\n'    "${p:--}"
  printf 'release_target\t%s\n'    "${r:--}"
  return 0
}

# The epoch itself, or nothing and a non-zero status when a component is
# unknown.
felix_epoch() {
  local proj="$1" root="$2" comps
  comps="$(felix_epoch_components "$proj" "$root")"
  printf '%s\n' "$comps" | cut -f2 | grep -qx -- '-' && return 1
  printf '%s\n' "$comps" | _felix_epoch_hash
}
