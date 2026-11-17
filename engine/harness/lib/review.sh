# The verdict on a surface no test can judge.
#
# Most escapes name something mechanical: a credential in the added lines, a job
# that will run holding secrets, a store that moves. One class has no mechanical
# test at all. A rubric that teaches the wrong thing is revert-complete, touches
# no store, reaches no stranger, and passes every check there is — and it is
# still the change you least want merged unread.
#
# A governed project had already written the answer into its own constitution
# before Felix could enforce any of it: an independent reviewer running in an
# isolated worktree at the reviewed commit, with the part that matters attached
# — a reviewer that executes the claim, because one that only reads the diff is
# a weaker tier wearing the name. So a verdict attests to something run.
#
# ---------------------------------------------------------------------------
# THE ONE PLACE A MODEL'S OUTPUT PERMITS RATHER THAN RESTRICTS.
#
# Invariant 2 says a model "may only ever narrow what the mechanical path
# already allowed", and a `reviewed` verdict widens: it clears an escape. That
# is a real exception and it is written here rather than smuggled past, because
# the invariant exists to stop a model overriding a mechanical verdict — and
# there is no mechanical verdict here to override. The alternative is not a
# stricter check; it is nobody reading it.
#
# Three things bound it, and they are the reason it is safe to have:
#
#   - A verdict clears `reviewed` and nothing else. `disclose`, `execute`,
#     `durable` and `verifier` are untouched by any review, so no reviewer can
#     release a secret, run CI, or move a store. Tested in that direction.
#   - It is keyed to the exact tree, the same way the gate receipt is, because
#     the trap is the same: a verdict for a different tree is not a verdict.
#   - Only `pass` clears. A missing verdict and a blocking verdict behave
#     identically, so a reviewer that never ran cannot read as approval.
#
# Independence cannot be checked, and Felix must not imply it does: whether a
# reviewer was genuinely at arm's length is a property of how it was dispatched,
# and no receipt establishes it. Nor can Felix know that anything was executed.
#
# Isolation is different, and it is the half that has actually gone wrong. A
# reviewer running the suite against the live tree while somebody keeps editing
# reports false failures — recorded as a real incident in a governed project's
# own lessons. So `where` is checked rather than merely stored: a **pass** that
# claims it ran in the tree under review is refused as a recording, because a
# clean result from the tree being edited is the one result that means nothing.
#
# A **block** is never refused for where it ran. A reviewer reporting a problem
# from the wrong place is still reporting a problem, and discarding it would
# turn the isolation check into a way of losing bad news.

_felix_review_path() {
  # Keyed on project and tree so two projects, or two trees, never share one.
  printf '%s/state/review/%s-%s' "$1" "$(basename "$2")" "$3"
}

# Write a verdict. Overwrites: the latest word on a tree is the one that counts,
# and keeping a history here would invite reading the wrong row.
felix_review_record() {
  local home="$1" proj="$2" tid="$3" verdict="$4" by="${5:-unknown}" note="${6:-}"
  local where="${7:-}" root="${8:-}" path here there
  [ -n "$tid" ] || return 1
  case "$verdict" in pass|block) ;; *) return 1 ;; esac

  # The reviewed root is passed in rather than taken from PWD. A verdict can be
  # recorded from anywhere — a wrapper, another worktree, a script — and reading
  # the caller's cwd as "the tree under review" would make the check depend on
  # where somebody happened to be standing.
  #
  # Both sides resolved before comparing, because two paths to one directory are
  # one directory and a string compare passes a symlink straight through.
  if [ "$verdict" = "pass" ] && [ -n "$where" ] && [ -n "$root" ]; then
    here="$(cd "$where" 2>/dev/null && pwd -P)" || here="$where"
    there="$(cd "$root" 2>/dev/null && pwd -P)" || there="$root"
    [ "$here" = "$there" ] && return 1
  fi

  path="$(_felix_review_path "$home" "$proj" "$tid")"
  mkdir -p "$(dirname "$path")" 2>/dev/null || return 1
  printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$tid" "$verdict" \
    "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$by" \
    "$(printf '%s' "$note" | tr '\t\n' '  ' | cut -c1-300)" \
    "${where:-unstated}" \
    > "$path" 2>/dev/null || return 1
}

# Where a passing review ran, judged by the command before it records one.
#
# felix_review_record refuses a pass whose `where` is the reviewed root, and
# that is all it can refuse: a record is a file any session can write, and 0100
# and 0340 record passes with no `where` to exercise the channel. The command is
# the reviewer's path, and through it a pass with no --in, an --in that does not
# exist, a directory inside the live tree or a work tree at another commit was
# recorded as a pass (audit b11, C078). So the isolation check fired only for a
# reviewer who volunteered the exact path of the live checkout, and the one who
# said where the review ran was the one refused. A pass now has to say it ran in
# a work tree of its own at the reviewed commit. That is the isolation the
# header asks for, and it is no claim of independence: a session can name any
# separate work tree.
#
# ROOT is the repository root the verdict is keyed to. Prints why and returns 1
# when a pass may not be recorded, and prints nothing when it may. Work trees are
# told apart by the top level git names, not by the path: a worktree made inside
# the checkout's own directory is a separate work tree, and a directory inside
# the checkout is not. A block never comes here.
felix_review_where() {   # ROOT WHERE
  local root="$1" where="${2:-}" top here rhead whead
  if [ -z "$where" ]; then
    printf 'a pass needs --in <the separate worktree the reviewer ran in, at this commit>: without it nothing says where the review ran, and a result from the tree being edited means nothing'
    return 1
  fi
  if [ ! -d "$where" ]; then
    printf -- '--in %s is not a directory that exists, so there is nowhere a review could have run' "$where"
    return 1
  fi
  top="$(git -C "$where" rev-parse --show-toplevel 2>/dev/null)" && [ -n "$top" ] \
    && top="$(cd "$top" 2>/dev/null && pwd -P)" && [ -n "$top" ] || {
    printf -- '--in %s is in no git work tree, so it names no commit the review ran at' "$where"
    return 1
  }
  here="$(git -C "$root" rev-parse --show-toplevel 2>/dev/null)" && here="$(cd "$here" 2>/dev/null && pwd -P)" || here="$root"
  if [ "$top" = "$here" ]; then
    printf -- '--in %s is the tree under review, or a directory inside it. A reviewer running against the live tree while it is being edited reports results about neither, so this is refused rather than recorded. Run it in a separate worktree at this commit.' "$where"
    return 1
  fi
  rhead="$(git -C "$root" rev-parse --verify -q 'HEAD^{commit}' 2>/dev/null)" || {
    printf 'the tree under review has no commit to compare the review against, so a pass cannot be tied to one'
    return 1
  }
  whead="$(git -C "$where" rev-parse --verify -q 'HEAD^{commit}' 2>/dev/null)" || {
    printf -- '--in %s has no commit (its HEAD names none), so the review ran at no commit' "$where"
    return 1
  }
  if [ "$whead" != "$rhead" ]; then
    printf -- '--in %s is at commit %s, and the tree under review is at %s. A pass for another commit says nothing about this one: run the review in a worktree at this commit.' \
      "$where" "$(printf '%s' "$whead" | LC_ALL=C cut -c1-8)" "$(printf '%s' "$rhead" | LC_ALL=C cut -c1-8)"
    return 1
  fi
}

felix_review_verdict() {
  cat "$(_felix_review_path "$1" "$2" "$3")" 2>/dev/null
}

# Has this exact tree been reviewed and passed?
felix_review_passed() {
  local home="$1" proj="$2" tid="$3" rec
  [ -n "$tid" ] || return 1
  rec="$(felix_review_verdict "$home" "$proj" "$tid")"
  [ -n "$rec" ] || return 1
  [ "$(printf '%s' "$rec" | LC_ALL=C cut -f1)" = "$tid" ] || return 1
  [ "$(printf '%s' "$rec" | LC_ALL=C cut -f2)" = "pass" ]
}
