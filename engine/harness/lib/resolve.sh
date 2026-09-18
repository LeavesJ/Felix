# Project resolution for Felix. Sourced by the CLI and the session hook, which
# are the two real callers; it is not a layer waiting for a third.
#
# Dependencies are bash and git only. Deliberately no jq and no python: Felix
# governs projects in languages it must not require, so it cannot drag a runtime
# along. The JSON reader below is the price of that, and its limits are stated.

# Substring test that never builds a pipeline.
#
# `producer | grep -q x` is a trap under `set -o pipefail`: grep exits the moment
# it matches, the producer takes SIGPIPE, and the pipeline reports 141. The check
# then says "absent" about something that is present. It is worse than a plain
# bug because it is timing-dependent for small producers, so it passes in testing
# and fails against a real repository.
# Close every descriptor this shell inherited above the standard three.
#
# Called as the first thing inside a background subshell. Measured on the
# shipped session-start hook, with a commission grant live so the background
# resume actually ran:
#
#   hook process exits           1.9s
#   its stderr pipe reaches EOF  12.2s
#
# Ten of those seconds are not work. Something in the background tree was
# holding the stderr pipe the platform reads to know the hook is done, so the
# session waited for a refresh it was never supposed to wait for. Redirecting
# 0, 1 and 2 inside the subshell does not fix it — every background job here
# already did that. Closing descriptors 10 through 13 in the subshell did:
# 12.2s became 1.9s, repeatably.
#
# What is measured and what is inferred, kept apart on purpose. The
# measurement is the A/B above. The inference is WHY a descriptor in that range
# holds the pipe: bash saves a redirected descriptor on a high number to
# restore it afterwards, and a subshell forked while one is live inherits the
# copy. A minimal reproduction of that shape did NOT reproduce the hang, so
# treat the explanation as unconfirmed and the fix as empirical. If you are
# here because something regressed, re-run the A/B rather than reasoning from
# this paragraph.
#
# Bounded rather than enumerated: bash allocates saved descriptors from 10
# upward, and /dev/fd enumeration needs a descriptor of its own to read.
felix_close_inherited_fds() {
  local _fd=3
  while [ "$_fd" -le 30 ]; do
    [ -e "/dev/fd/$_fd" ] && eval "exec ${_fd}>&-"
    _fd=$((_fd + 1))
  done
  return 0
}

felix_contains() {
  case "$1" in *"$2"*) return 0 ;; *) return 1 ;; esac
}

# Whole-line variant, for lists where a substring match would be too loose.
felix_has_line() {
  local line
  while IFS= read -r line; do [ "$line" = "$2" ] && return 0; done <<EOF
$1
EOF
  return 1
}

# Where Felix keeps writable state: projects and their doctrine. Not their
# memory, which since 2026-08-14 lives outside any repository — see
# felix_mem_root below for why that had to stop being the same directory.
#
# Separate from the engine because an installed plugin lives in a versioned cache
# that is replaced wholesale on update. Writing project doctrine in there would
# lose it on the next `claude plugin update`, silently, which is the worst way to
# lose a lesson someone paid for.
#
# Order: an explicit environment variable, then the pointer file `felix install`
# writes, then a repo checkout that already carries projects/ beside the engine,
# then the default.
# Is this engine path a deployed copy of Felix rather than a checkout of it?
#
# Two callers need this and they must agree. felix_home must never adopt such a
# copy as a home — a constitution frozen at install time, and memory written
# into a directory the next plugin update deletes. And cmd_install must never
# treat one as the tree being deployed FROM: run the deployed CLI and its own
# FELIX_ROOT *is* the cache, so `diff -rq "$FELIX_ROOT/harness" "$live/harness"`
# compared the deployed engine with itself, could not fail, and certified a
# repository whose engine had never been deployed at all. That is #55, and it
# was the fifth defect in this project whose cause was "correct code, installed
# nowhere" — sitting inside the guard written to stop the other four.
#
# One definition, because the alternative is two and the two would drift. This
# is the same correction #56 made to the base-resolution check an hour earlier,
# for the same reason.
#
# Matched on the path, not on anything inside the directory. A frozen copy is
# byte-identical to the checkout it came from and carries no marker that would
# tell them apart; where it sits is the only evidence there is.
felix_plugin_copy() {
  case "${1:-}" in
    */.claude/plugins/cache/*|*/.claude/plugins/marketplaces/*) return 0 ;;
    *) return 1 ;;
  esac
}

# The Felix engine tree being operated ON, which is not the tree the running
# script lives IN whenever somebody uses the deployed CLI — which is what every
# session-start message tells them to do.
#
# Prints the engine directory and returns 0, or prints nothing and returns 1
# when no checkout can be found. Callers decide what an absence means: felix
# install refuses, because a deploy it cannot verify is the defect; felix
# bootstrap reports "none", because a machine with no Felix checkout genuinely
# has no repository for CI to fetch the harness from.
#
# Two commands needed this and each grew its own answer. cmd_install's was
# written for #55; cmd_bootstrap resolved the same question with
# `felix_repo_slug "$FELIX_ROOT"` and got it wrong the same way, one function
# along (#65) — from the cache it returned empty and printed "Felix has no
# remote for CI to fetch" about an engine whose remote exists, and on a machine
# whose home is itself a git repository with an origin it would have returned
# THAT slug, straight into a generated workflow's `repository:` beside a deploy
# key. So the resolution lives here once.
#
# Order: what the marketplace actually serves, then where you are standing, then
# the home. The first is the real answer — Claude Code deploys from the
# registered marketplace root and nowhere else — and the other two are what to
# try before a first install has registered one.
#
# A candidate qualifies only by carrying engine/harness/felix, never by being a
# git repository with a remote. That is what keeps an unrelated home checkout
# from being mistaken for the engine.
felix_engine_source() {
  local engine="${1:-}" home="${2:-}" cand
  [ -n "$engine" ] || return 1
  felix_plugin_copy "$engine" || { printf '%s' "$engine"; return 0; }
  for cand in "$(felix_marketplace_root)" "$(felix_repo_root "$PWD")" "$home"; do
    [ -n "$cand" ] || continue
    [ -x "$cand/engine/harness/felix" ] || continue
    printf '%s' "$cand/engine"; return 0
  done
  return 1
}

# Where the felix plugin is actually deployed, or nothing.
#
# Asked of the CLI rather than read off the cache directory, because the cache
# keeps every version it has ever installed and the newest on disk is not
# necessarily the one that loads.
#
# One reader because it had been written out three times and the copies had
# already diverged: both of cmd_install's asked the CLI and nothing else, while
# the project gate falls back to the highest cached version when the CLI is
# absent. That gate keeps its own copy on purpose — a project's gate must run
# without the engine's libraries, which is the property the independence check
# exists to protect — so this replaces the engine's two, not all three.
#
# Fails quiet. No CLI, or a CLI that answers nothing, is "no deployment I can
# see", and every caller here treats that as "say nothing" rather than as a
# finding.
felix_deployed_engine() {
  command -v claude >/dev/null 2>&1 || return 1
  local p
  p="$(claude plugin list --json 2>/dev/null \
       | sed -n '/"felix@felix"/,/}/p' \
       | sed -n 's/.*"installPath"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)"
  [ -n "$p" ] || return 1
  printf '%s' "$p"
}

felix_home() {
  local engine="$1"
  if [ -n "${FELIX_HOME:-}" ]; then printf '%s' "$FELIX_HOME"; return; fi
  if [ -f "$HOME/.felix-home" ]; then
    local p; p="$(tr -d '[:space:]' < "$HOME/.felix-home")"
    [ -n "$p" ] && [ -d "$p" ] && { printf '%s' "$p"; return; }
  fi
  # A plugin install is a frozen copy of the whole repository, projects/
  # included. Trusting that copy would govern from a constitution frozen at
  # install time and write memory into a directory the next plugin update
  # deletes, both silently. The copy is never a home.
  if ! felix_plugin_copy "$engine"; then
    # The engine may sit at the repo root, or one level down so that a plugin
    # install carries the engine alone and leaves projects/ behind. Check both
    # before falling through, or a fresh clone silently starts a new home and
    # reports the project it is standing in as unknown.
    [ -d "$engine/projects" ] && { printf '%s' "$engine"; return; }
    [ -d "$engine/../projects" ] && { (cd "$engine/.." && pwd); return; }
  fi
  printf '%s' "$HOME/.felix"
}

# Where project memory lives — and deliberately not under felix_home.
#
# Doctrine and memory were one directory tree until 2026-08-14, and that is what
# made this repository unpublishable. Doctrine is the part worth showing and the
# part the founder owns outright. Memory is not: it holds verbatim founder
# prompts, and whatever a governed project's work happens to be about, which
# includes material belonging to somebody who never agreed to be published. A
# repository that stores every governed project's memory can never be public,
# and left alone that cost is paid again by every project Felix adopts rather
# than once.
#
# The root is computed from $HOME and never from felix_home, even though every
# other writable thing Felix owns hangs off home. Derived from home it would sit
# inside the repository in the one case that actually went wrong — Felix
# governing itself, where home *is* the checkout. The invariant is worth more
# than the symmetry: memory is outside a repository by construction, not by
# whichever directory home resolved to today.
#
# A gitignore rule was the cheaper option and is not enough. It is one `git add
# -f` from failing, it does nothing about a tree somebody clones or cleans, and
# it leaves the material on disk inside the repository either way. Ignoring a
# file is a statement about git. Moving it is a statement about the disk.
felix_mem_root() {
  printf '%s' "${FELIX_MEMORY:-$HOME/.felix/memory}"
}
# One field of one plugin's entry in the installed-plugin registry.
#
# Bounded to the entry: opened by the plugin's own key, closed by the next key
# or the end of the file, on a pretty-printed registry and a minified one
# alike. The shape this replaces set a flag on the key line and printed the
# next matching field it met, which on an entry lacking that field returned the
# NEXT plugin's value, and on a single-line registry returned the last one in
# the file for every name. Two callers carried that shape independently — the
# ledger's hook classifier and the commissioning provenance — so it lives here,
# in the library both already depend on, rather than being fixed twice.
#
# Prints nothing when the registry, the entry or the field is absent. Nothing
# is the honest answer: a guess here is a wrong provenance or a wrong tier.
felix_registry_field() {   # bare plugin name, field name -> value, or nothing
  local name="$1" field="$2" reg="${3:-$HOME/.claude/plugins/installed_plugins.json}"
  [ -n "$name" ] && [ -n "$field" ] && [ -f "$reg" ] || return 0
  awk -v p="\"$name@" -v k="$field" '
    {
      line = $0
      if (!f) { i = index(line, p); if (!i) next; f = 1; line = substr(line, i + length(p)) }
      else if (line ~ /^[[:space:]]*"[^"]+@[^"]+"[[:space:]]*:/) exit
      if (match(line, /"[^"]+@[^"]+"[[:space:]]*:/)) line = substr(line, 1, RSTART - 1)
      if (match(line, "\"" k "\"[[:space:]]*:[[:space:]]*\"[^\"]*\"")) {
        s = substr(line, RSTART, RLENGTH)
        sub("^\"" k "\"[[:space:]]*:[[:space:]]*\"", "", s); sub(/"$/, "", s)
        print s; exit
      }
    }' "$reg" 2>/dev/null
}


# The memory directory for one project, named by its doctrine directory.
#
# Keyed on the project's name rather than its path, so a worktree and the tree it
# came from share one memory. That is the behaviour every caller already assumed
# when memory sat beside doctrine under a single home, and the alternative — one
# memory per checkout — would silently split a project's lessons the first time
# somebody opened a worktree.
felix_mem_dir() {
  local p="${1%/}"
  printf '%s/%s' "${FELIX_MEMORY:-$HOME/.felix/memory}" "${p##*/}"
}

# Read one top-level string field out of a flat JSON file.
# Handles exactly what project.json needs: one nesting level, no escaped quotes.
# Anything richer belongs in a real parser, and would mean project.json has
# outgrown its job.
felix_json_str() {
  sed -n "s/.*\"$2\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p" "$1" | head -1
}

# Print the repo root for a directory, or the directory itself when not in git.
# Felix must work in a checkout that is not a git repo at all.
felix_repo_root() {
  local start="${1:-$PWD}" root d
  # Walk up for .git before asking git. `git rev-parse --show-toplevel` costs
  # about 12ms, and this is called from PreToolUse, which is synchronous on
  # every tool call — so it was roughly a third of that hook's whole budget for
  # an answer the filesystem already has. `.git` is a directory in a normal
  # clone and a file in a worktree or submodule, so -e covers both.
  d="$(cd "$start" 2>/dev/null && pwd -P)" || d=""
  while [ -n "$d" ] && [ "$d" != "/" ]; do
    [ -e "$d/.git" ] && { printf '%s' "$d"; return; }
    d="${d%/*}"
  done
  # Nothing found by walking. Ask git anyway rather than give up: GIT_DIR set in
  # the environment, or any layout where the marker is not on the path above,
  # is exactly the case the walk cannot see and git can.
  root="$(cd "$start" 2>/dev/null && git rev-parse --show-toplevel 2>/dev/null)"
  [ -n "$root" ] && printf '%s' "$root" || printf '%s' "$start"
}

# Resolve which project governs a working directory.
# Prints the project directory on success, prints nothing and returns 1 on miss.
#
# Order matters. The .felix marker wins because it is the only mechanism that
# works for a repo with no remote, a fork, a rename, or a checkout of somebody
# else's code. Remote matching is the convenience path, not the contract.
felix_resolve_project() {
  local start="${1:-$PWD}" felix_root="$2"
  local root name remote meta match
  root="$(felix_repo_root "$start")"

  # 1. explicit marker file naming the project
  if [ -f "$root/.felix" ]; then
    name="$(tr -d '[:space:]' < "$root/.felix")"
    if _felix_name_ok "$name" && [ -d "$felix_root/projects/$name" ]; then
      printf '%s' "$felix_root/projects/$name"
      return 0
    fi
    return 1
  fi

  # 2. git remote substring match declared by each project
  remote="$(cd "$root" 2>/dev/null && git remote get-url origin 2>/dev/null)" || remote=""
  [ -n "$remote" ] || return 1
  for meta in "$felix_root"/projects/*/project.json; do
    [ -e "$meta" ] || continue
    match="$(felix_json_str "$meta" remote_match)"
    [ -n "$match" ] || continue
    case "$remote" in
      *"$match"*) printf '%s' "$(dirname "$meta")"; return 0 ;;
    esac
  done
  return 1
}

# Marker and pointer contents are written by whoever edited the file, and both
# end up inside a JSON string a hook emits. Printable characters only, and
# short, so a broken binding cannot be used to say something else.
_felix_binding_sane() {
  printf '%s' "$1" | LC_ALL=C tr -cd '[:print:]' | cut -c1-80
}

# What a project name may be: one directory name under projects/, made of
# letters, digits, dot, underscore and dash, not starting with a dot or a
# dash. `.` and `..` are directories and `-d` says so, which is how a marker
# reading `.` resolved to a healthy binding at `projects/.` — a project with
# no tables, no deny rows and no gate, and every hook reading it as governed.
# A name holding a slash is a path, and a path is not a name either.
_felix_name_ok() {
  case "${1:-}" in
    ''|.*|-*|*/*|*[!A-Za-z0-9._-]*) return 1 ;;
  esac
  return 0
}

# A binding that is PRESENT and does not resolve.
#
# felix_resolve_project answers one question — which project governs here — and
# returns non-zero for two states that are not the same fact. Nothing named
# this checkout, which is the ordinary case and means ungoverned. Or something
# named it and the name went nowhere, which means somebody broke the binding
# and nothing is being checked. Every caller reads a non-zero resolve as the
# first, so `echo nonexistent > .felix` switched the whole floor off in one
# line: no gate, no hold, no record, exit 0.
#
# Absent is not broken, and that half must keep working. A directory with no
# marker and no matching remote is a repository Felix does not govern, and it
# has to stay silent there or Felix is unusable anywhere it has not been
# adopted. This function is the other half, and it is this project's own rule
# that "nothing due" and "nothing is being checked" must not render
# identically.
#
# Two surfaces, because there are two ways to say where the binding points.
# `$HOME/.felix-home` is checked first and matters more: it decides which home
# the marker below is resolved against, it is read on every invocation, and it
# sits outside every repository — so changing it produces no diff, no
# classification, and nothing for a reviewer to see. A pointer that exists and
# names a directory that is not a Felix home is a broken pointer, not an
# absence.
#
# An explicit $FELIX_HOME wins over the pointer in felix_home, so when it is
# set the pointer is never consulted and cannot bypass anything. Unread is not
# broken either.
#
# Prints a sentence when the binding is broken and nothing when it is not, the
# same shape as the other reporters a hook interpolates. It never repairs: the
# correct binding is not knowable from here, since only a person can say
# whether this tree is a project that was renamed or a tree Felix should leave
# alone.
felix_binding_broken() {
  local start="${1:-$PWD}" home="${2:-}" root name p known why=""

  # Three ways to be wrong, one place that decides and one place that prints.
  # Printing from inside each branch and deciding afterwards whether to finish
  # the sentence is how a partial refusal escapes — and a partial refusal is
  # worse than none, because the caller tests emptiness and would block on half
  # an explanation.
  if [ -z "${FELIX_HOME:-}" ] && [ -f "$HOME/.felix-home" ]; then
    p="$(tr -d '[:space:]' < "$HOME/.felix-home" 2>/dev/null)"
    if   [ -z "$p" ]; then
      why="is empty, so it names no home"
    elif [ ! -d "$p" ]; then
      why="names $(_felix_binding_sane "$p"), which is not a Felix home: no such directory"
    elif [ ! -d "$p/projects" ]; then
      why="names $(_felix_binding_sane "$p"), which is not a Felix home: it holds no projects/ directory"
    fi
    if [ -n "$why" ]; then
      printf 'The Felix home pointer at %s %s.\n\n' "$HOME/.felix-home" "$why"
      printf 'Every hook in every session resolves through that pointer, and it lives outside every repository, so breaking it leaves no diff to review.\n\n'
      printf 'Point it at a real home, or delete it to fall back to the default:\n\n  felix install --home <path>\n'
      return 0
    fi
  fi

  root="$(felix_repo_root "$start")"
  [ -f "$root/.felix" ] || return 0
  name="$(tr -d '[:space:]' < "$root/.felix" 2>/dev/null)"
  _felix_name_ok "$name" && [ -d "$home/projects/$name" ] && return 0

  known="$(ls "$home/projects" 2>/dev/null | tr '\n' ' ')"
  if [ -z "$name" ]; then
    printf 'The .felix marker in %s is empty, so it does not resolve to a project. ' "$root"
  elif ! _felix_name_ok "$name"; then
    printf 'The .felix marker in %s names "%s", which is not a project name: a name is one directory name under %s, and this is a path or a dot. ' \
      "$root" "$(_felix_binding_sane "$name")" "$home/projects"
  else
    printf 'The .felix marker in %s names "%s", and that does not resolve to a project under %s. ' \
      "$root" "$(_felix_binding_sane "$name")" "$home/projects"
  fi
  printf 'A marker is present, so this tree was meant to be governed, and right now nothing is checking it.\n\n'
  printf 'Name a project that exists, or remove the marker if this tree really is ungoverned:\n\n'
  printf '  known projects: %s\n' "${known:-none}"
}

# A refusal that belongs to no project, because the thing that broke is what
# decides which project this is.
#
# felix_say and felix_verify_log both key on a resolved project and cannot be
# used here. The memory root can: it is outside any repository by construction,
# it is the one writable place that does not need the binding to work, and a
# line here is the difference between a hook that refused and a hook that never
# ran.
felix_unresolved_log() {
  local reason="$1" where="${2:-}" mem
  mem="$(felix_mem_root)"
  [ -d "$mem" ] || mkdir -p "$mem" 2>/dev/null || return 0
  printf '%s\t%s\t%s\n' \
    "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "${where:-unknown}" \
    "$(printf '%s' "$reason" | tr '\t\n' '  ')" \
    >> "$mem/unresolved.log" 2>/dev/null || true
}

# Does this base name something that exists here?
#
# The question felix_changed_paths cannot answer, because it sends every git
# error to /dev/null and so reports a base nobody can resolve as a branch that
# changed nothing. An empty answer and an unanswerable question are different
# facts, and every caller that conflates them reads the second as the first —
# which is always the permissive direction.
#
# `^{commit}` is load-bearing, and receipt.sh learned it first. `git rev-parse
# --verify <40-hex>` exits 0 for a sha this repository has never held, because a
# full-length hex string is a syntactically valid object name and --verify alone
# checks the syntax. Only a name it cannot parse exits non-zero. Peeling to a
# commit is what turns a syntax check into an existence test.
#
# An empty base is not a failure to resolve one. felix_changed_paths has always
# taken it to mean "no branch comparison, working tree only", and callers rely
# on that; deciding it is unknown would break every one of them.
felix_base_resolves() {
  local root="${1:-}" base="${2:-}"
  [ -n "$root" ] && [ -n "$base" ] || return 1
  git -C "$root" rev-parse --verify "$base^{commit}" >/dev/null 2>&1
}

# The ref a base NAME should actually be compared against.
#
# Every command defaults to `main`, and `main` is a local ref. In a worktree it
# is a SHARED local ref naming whatever the primary checkout last pulled — and a
# worktree cannot check `main` out, so nothing in that workflow ever advances
# it. Observed on this repository: local main three merges behind origin/main
# while the work continued in a worktree (#74).
#
# It is also the ref that matters least. `felix merge` merges through
# `gh pr merge`, so what a branch actually lands on is the REMOTE branch. The
# local one is a cache of it that this workflow never refreshes.
#
# The same correction felix_kernel_dir already makes, in the same shape and for
# the same reason — its comment records that hard-coding a branch name was
# "green on a laptop that says main and red on a runner that says master".
#
# Only a name whose remote-tracking ref exists is redirected. A sha, a `HEAD~1`,
# a tag, or a branch that lives only here is taken exactly as given: rewriting
# those would invent a base nobody named. `origin/HEAD~1` does not resolve, so
# the loop falls through on its own rather than needing a rule about syntax.
#
# No fetch, ever. The enforcing path has to work with no network, so this is as
# current as the last fetch and never more. That is a real limit and it is still
# strictly better than a ref the worktree workflow cannot advance at all.
felix_base_ref() {
  local root="${1:-}" base="${2:-}" ref
  [ -n "$root" ] && [ -n "$base" ] || return 1
  for ref in "origin/$base" "$base"; do
    if git -C "$root" rev-parse --verify "$ref^{commit}" >/dev/null 2>&1; then
      printf '%s' "$ref"; return 0
    fi
  done
  return 1
}

# The two refs to diff to see what MERGING this branch would change, or nothing
# when that cannot be computed.
#
# `felix merge` squashes. A squash commit is not a descendant of the branch it
# came from, so merging a branch's base does not advance
# merge-base(base, branch) — it stays frozen at the commit before the base
# merged, for the life of the branch. Three-dot is anchored to that merge-base,
# so a stacked branch keeps being blamed for every path its base touched, even
# though the base now holds those exact bytes. #51, observed on #50 stacked on
# #49: a documentation change classified red by inheriting plugin.json, and a
# docs-only branch escalated to the founder because the branch below it had
# added a workflow.
#
# Neither two-dot nor three-dot is the answer, which is why this computes a
# third thing. Three-dot blames the branch for what is already in the base.
# Two-dot blames it for the base's INDEPENDENT progress — a file main gained
# and the branch never had reads as a deletion, which fails open. The object
# actually being judged is the tree a merge would produce, and `merge-tree`
# computes exactly that without touching the working tree.
#
# Silent about failure on purpose, and every failure falls back to three-dot:
#   - git older than 2.38 has no `--write-tree`
#   - a conflicting merge exits non-zero, and its tree is not what would land
#   - anything that does not look like an object id
# Three-dot over-reports, so falling back is the safe direction — it can only
# make the verdict stricter, never weaker. A narrower answer computed from a
# failed merge would be the opposite.
_felix_merge_refs() {
  local root="$1" base="$2" mb tip tree
  [ -n "$base" ] || return 1
  mb="$(git -C "$root" merge-base "$base" HEAD 2>/dev/null)" || return 1
  tip="$(git -C "$root" rev-parse "$base^{commit}" 2>/dev/null)" || return 1
  [ -n "$mb" ] && [ -n "$tip" ] || return 1
  # The base has not moved since this branch was cut, so three-dot already asks
  # exactly the right question. Left alone rather than rerouted, because this is
  # every ordinary branch and the fix is only for the case that differs.
  [ "$mb" = "$tip" ] && return 1
  tree="$(git -C "$root" merge-tree --write-tree "$base" HEAD 2>/dev/null)" || return 1
  tree="$(printf '%s\n' "$tree" | head -1)"
  case "$tree" in
    ""|*[!0-9a-f]*) return 1 ;;
  esac
  printf '%s^{tree} %s' "$base" "$tree"
}

# Every path this branch touches, including what is staged but not committed.
#
# One function because there were four, and they drifted in the same direction.
# Each tried `git diff --name-only base...HEAD` and fell back to `git diff base`
# only when that came back EMPTY — so on a branch with commits, which is every
# pull request, the fallback never ran and everything staged or unstaged was
# dropped. `felix evidence` told a session it owed a test the session had just
# staged, and felix_escapes could not see a staged workflow change or a staged
# credential at all.
#
# It hid because the shape that masks it is the shape a fixture reaches for: on
# a branch with no commits yet, `base...HEAD` is empty and the fallback covers
# everything. lessons.sh had this right and nothing required the others to agree.
#
# Three sources, unioned rather than fallen back through:
#   base...HEAD   committed on this branch
#   --cached      staged, about to be committed
#   (bare)        edited, not yet staged
felix_changed_paths() {
  local root="$1" base="${2:-}" refs
  {
    if [ -n "$base" ]; then
      # What merging would change, when that is computable and differs from what
      # was typed. See _felix_merge_refs. Unquoted on purpose: it prints two refs.
      if refs="$(_felix_merge_refs "$root" "$base")"; then
        # shellcheck disable=SC2086
        git -C "$root" diff --name-only $refs 2>/dev/null
      else
        git -C "$root" diff --name-only "$base...HEAD" 2>/dev/null
      fi
    fi
    git -C "$root" diff --name-only --cached 2>/dev/null
    git -C "$root" diff --name-only 2>/dev/null
  } | grep -v '^$' | LC_ALL=C sort -u
}

# Every line this branch ADDS, including staged and unstaged ones.
#
# The companion to felix_changed_paths, and the half that was missed when that
# landed: knowing a path changed is not knowing what the change says. A content
# rule reading only `base...HEAD` names a staged file and then inspects the
# version without the staged content in it.
felix_added_lines() {
  local root="$1" base="${2:-}" refs
  {
    if [ -n "$base" ]; then
      # The same correction as felix_changed_paths, and for the same reason: a
      # content rule reading three-dot on a stacked branch scans lines the base
      # already merged, so a credential the branch below it added is reported
      # against this one.
      if refs="$(_felix_merge_refs "$root" "$base")"; then
        # shellcheck disable=SC2086
        git -C "$root" diff $refs 2>/dev/null
      else
        git -C "$root" diff "$base...HEAD" 2>/dev/null
      fi
    fi
    git -C "$root" diff --cached 2>/dev/null
    git -C "$root" diff 2>/dev/null
  } | grep '^+' | grep -v '^+++'
}

# A file as it will be committed, not as it was last committed.
#
# The worktree copy when there is one, because that is what `git add -A` is
# about to record; `git show <ref>:` only afterwards. Erring toward the worktree
# errs toward seeing more, which is the safe direction for a check that decides
# whether something stops.
felix_file_at() {
  local root="$1" ref="$2" path="$3"
  if [ "$ref" = "HEAD" ] && [ -f "$root/$path" ]; then
    cat "$root/$path" 2>/dev/null
  else
    git -C "$root" show "$ref:$path" 2>/dev/null
  fi
}

# Whether two paths are checkouts of one repository, worktrees included.
#
# A worktree and its main checkout share one `--git-common-dir`, which is what
# makes this survive being somewhere else. Resolved to an absolute path first,
# because git answers `.git` from inside the main checkout and a full path from
# inside a worktree — comparing those two strings says "different" about the
# same repository, which is the bug this exists to stop rather than cause.
#
# Written because two guards asked "is this Felix's own storage" with a path
# prefix — `case "$root/$f" in "$FELIX_HOME_DIR"/projects/*)` — which is true
# only when you are standing in the home itself. From a worktree the root is
# elsewhere, the prefix never matches, and the guard silently does nothing. One
# of the two guards only reports; the other deletes.
# How many lines match, as one number.
#
# `grep -c` prints the count and *also* exits 1 when that count is zero, so the
# obvious `$(grep -c … || echo 0)` appends a fallback zero to the zero grep has
# already printed and yields "0\n0". Every arithmetic test on that errors into
# the wrong branch, and written to a file it becomes a stray line that later
# readers count as data: this project's own ledger held 215 of them in 280
# lines, and `felix ledger` reported seven sessions where there were three.
#
# Exit 2 — no such file — is the only case that prints nothing, and so it is the
# only case that needs a fallback. Recorded in lessons.md before this existed,
# which is why the fix is one function rather than eight repaired call sites.
felix_count() {
  local n
  n="$(grep -c "$@" 2>/dev/null)" || true
  case "$n" in ''|*[!0-9]*) printf '0' ;; *) printf '%s' "$n" ;; esac
}

felix_same_repo() {
  local a="$1" b="$2" ga gb
  [ -n "$a" ] && [ -n "$b" ] || return 1
  ga="$(git -C "$a" rev-parse --path-format=absolute --git-common-dir 2>/dev/null)" || return 1
  gb="$(git -C "$b" rev-parse --path-format=absolute --git-common-dir 2>/dev/null)" || return 1
  [ -n "$ga" ] && [ "$ga" = "$gb" ]
}

# Whether the repository under judgement is the one that ships this engine.
#
# Only that repository has the circularity worth breaking. A governed product's
# rules live in the Felix home and are not in its diff at all — #42 established
# that — so its branch cannot rewrite what judges it, and demanding a pinned
# engine there would be a fix for Felix and a regression for everything Felix
# governs: no plugin on a CI runner, none on a fresh clone, and merge refusing
# in both.
felix_self_governed() {
  local root="${1:-}"
  [ -n "$root" ] && [ -f "$root/engine/.claude-plugin/plugin.json" ] || return 1
  git -C "$root" ls-files --error-unmatch engine/.claude-plugin/plugin.json >/dev/null 2>&1
}

# The version a manifest declares, at a ref or in the working tree.
_felix_plugin_version() {
  local root="$1" ref="${2:-}"
  { if [ -n "$ref" ]; then git -C "$root" show "$ref:engine/.claude-plugin/plugin.json" 2>/dev/null
    else cat "$root/engine/.claude-plugin/plugin.json" 2>/dev/null; fi
  } | sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1
}

# The engine that judges, which must not be the engine being judged.
#
# The first version of this took the newest entry in the plugin cache and was
# vacuous, because the gate's `installed` check will not go green until that
# entry matches the tree byte for byte, and merge will not run without a green
# receipt. So the newest entry is always the candidate by the time it matters.
# docs/2026-08-14-earned-autonomy-decision.md §4a had already said base-version
# evaluation could not be reached without settling the install-before-green
# cycle — "one problem seen from two sides".
#
# The judge is the version `main` declares instead. The cache keeps every
# version ever installed, and `felix install` refuses a changed engine at an
# unchanged version, so a branch that touches the engine has bumped past main
# and main's entry is both present and not the candidate's. The deadlock is
# side-stepped rather than fought: `installed` compares the tree against the
# newest entry while this reads an older one, and both hold at once.
#
# One limit, stated because a root of trust that overclaims is worse than none:
# this is not a signature. The trust is that the cache entry for main's version
# is what main contained when somebody installed it, and felix merge no longer
# takes that on trust — it asks felix_accepted_deploy_diff whether the entry is
# byte-identical to main's engine at the base ref before letting it judge.
#
# FELIX_KERNEL, which once named a judge outright, is gone (#260). It existed
# so the suite could point at a constructed kernel and the suite never used
# it; what it did do was let anything that can set the environment choose its
# own judge, which is every escape channel evadable in one variable. The cache
# location is still composable (FELIX_KERNEL_CACHE, FELIX_PLUGIN_CACHE), and
# the byte comparison at the boundary is what makes that safe: a cache the
# session doctored does not match main's engine and is refused as the judge.
felix_kernel_dir() {
  local root="${1:-}" base="${2:-main}" ver p ref
  [ -n "$root" ] || return 1
  # The branch being merged into, not the literal word "main". Hard-coding it
  # made this depend on `init.defaultBranch`, which is a property of whoever ran
  # it — green on a laptop that says main and red on a runner that says master.
  for ref in "origin/$base" "$base"; do
    git -C "$root" rev-parse --verify "$ref" >/dev/null 2>&1 && break
    ref=""
  done
  [ -n "$ref" ] || return 1
  ver="$(_felix_plugin_version "$root" "$ref")"
  [ -n "$ver" ] || return 1
  # FELIX_KERNEL_CACHE, not FELIX_PLUGIN_CACHE. toolbox.sh already owns that
  # name and means something else by it — the plugins cache ROOT, one level up
  # from felix's own versions — and the CLI sources toolbox.sh, so reading it
  # here resolved .../plugins/cache/<version>/harness and found nothing. The
  # suite never saw it because every test set the variable explicitly, which
  # masks a collision instead of exposing one. Composed with it rather than
  # around it, so a machine that moves the plugins cache moves this too.
  p="${FELIX_KERNEL_CACHE:-${FELIX_PLUGIN_CACHE:-$HOME/.claude/plugins/cache}/felix/felix}/$ver/harness"
  [ -d "$p" ] || return 1
  printf '%s' "$p"
}

# Where the felix marketplace serves its engine from, or empty when it is not
# registered. Reads the registry rather than assuming, because the answer is the
# difference between a deploy and a no-op that reports success.
felix_marketplace_root() {
  local reg="${1:-$HOME/.claude/plugins/known_marketplaces.json}"
  [ -f "$reg" ] || return 0
  sed -n '/"felix"[[:space:]]*:[[:space:]]*{/,/^  }/p' "$reg" 2>/dev/null \
    | sed -n 's/.*"installLocation"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1
}

# Whether this engine is one Claude Code could ever install from.
#
# `felix install` in a worktree bumps the manifest, runs the three plugin
# commands, finds the cache unchanged and reports "this is no longer the version
# cache; something else is wrong" — which sends you looking for corruption. The
# registry is a directory marketplace pinned to one path, so a worktree's engine
# is not the engine being served and never was. Nothing is broken; the deploy
# went to the tree the marketplace names, which is main.
#
# It is not a refusal. The bump still belongs on the branch, because merging is
# what makes it deployable, and a branch that never bumped deploys nothing when
# it lands. Only the diagnosis changes.
# Tested on the engine's own parent, not on a path prefix. A worktree lives
# under `.claude/worktrees/` *inside* the main checkout, so "starts with the
# marketplace root" is true of every worktree there is and the check would have
# passed exactly where it needed to fail.
#
# The comparison is between two DIRECTORIES and not between two strings. The
# registry holds whatever path was typed at registration and this side derives
# one from `pwd`, so a symlinked home, or /var against /private/var on macOS,
# made the served checkout read as one the marketplace does not serve — and on
# the obligation that rests on this, "not served" is DORMANT, which is the
# permissive direction. `-ef` asks the filesystem the question the string was
# standing in for; the string compare stays as the answer for a path that no
# longer exists, where `-ef` cannot answer at all.
felix_deployable_from() {
  local engine_root="$1" mroot parent
  mroot="$(felix_marketplace_root "${2:-}")"
  [ -n "$mroot" ] || return 0
  parent="${engine_root%/*}"
  [ "$parent" = "$mroot" ] && return 0
  if [ -d "$parent" ] && [ -d "$mroot" ] && [ "$parent" -ef "$mroot" ]; then
    return 0
  fi
  printf '%s' "$mroot"
  return 1
}

# Raise the patch digit in a plugin manifest, and print the new version.
#
# Claude Code caches a plugin by version, so a changed engine at an unchanged
# version never deploys and still reports success. `felix install` detected that
# exact condition and printed "bump the version, then re-run this" — a command
# suggesting something it could safely have done, which the charter names as a
# defect. The gate caught `installed` nine times before anybody counted, every
# one of them a person typing the digit the command was withholding.
#
# Bumping is not the risky half. install is already the thing that replaces the
# deployed engine; refusing to change a number while doing that is caution in
# the wrong place.
#
# Refuses rather than guesses when the version is not three numbers. A manifest
# it cannot parse is one it must not rewrite.
felix_version_bump() {
  local manifest="$1" cur major minor patch next tmp
  [ -f "$manifest" ] || return 1
  cur="$(sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$manifest" | head -1)"
  case "$cur" in
    [0-9]*.[0-9]*.[0-9]*) ;;
    *) return 1 ;;
  esac
  major="${cur%%.*}"; minor="${cur#*.}"; minor="${minor%%.*}"; patch="${cur##*.}"
  case "$major$minor$patch" in *[!0-9]*) return 1 ;; esac
  next="${major}.${minor}.$((patch + 1))"
  # Through a temp file, so a failed write cannot leave empty the one manifest
  # whose corruption stops everything deploying.
  tmp="$(mktemp)" || return 1
  sed 's/\("version"[[:space:]]*:[[:space:]]*"\)[^"]*\("\)/\1'"${next}"'\2/' \
      "$manifest" > "$tmp" 2>/dev/null || { rm -f "$tmp"; return 1; }
  [ -s "$tmp" ] || { rm -f "$tmp"; return 1; }
  mv -f "$tmp" "$manifest" 2>/dev/null || { rm -f "$tmp"; return 1; }
  printf '%s' "$next"
}

# The deployed surface is three directories, and comparing one of them
# certified deployments that never happened (#82). The cache serves harness/,
# hooks/ and commands/; hooks.json is the file that decides which hooks BIND,
# so a deploy that copied harness/ and dropped hooks/ reads as `installed ok`
# while every session runs yesterday's bindings — a hook binary deployed
# perfectly and running nowhere. engine/.claude-plugin is deliberately not
# compared: plugin.json differs whenever a bump is pending, which is this
# tree's normal state, and the cache does not carry that directory anyway.
#
# A directory absent from BOTH sides is skipped — nothing was deployed and
# nothing was expected, which is a fixture, not a drift. Absent from one side
# is a drift: diff itself fails on the missing operand, which is the honest
# verdict rather than a special case.
#
# The merge-time self-judgement guard is deliberately NOT this function. It
# compares harness/ alone, on purpose — it asks whether the judging LIBRARIES
# are the accepted ones, not whether the deployment is complete — and widening
# it would let a hooks-only difference block a merge that hooks cannot affect.
# A path the repository itself declares non-content is residue, not drift
# (#86). A claude-flow hook dropped 4KB of state under tests/ while the suite
# ran there, and this comparison called a byte-identical deploy a drift — in a
# worktree the gate then misdiagnosed that as "structural: cannot deploy".
# The rule is the repository's own .gitignore, asked per surviving line via
# git check-ignore, on both sides: a stray in the cache is a deployed stray,
# same non-content. Untracked-but-not-ignored still counts — that is
# undeployed work, and quieting it would be loosening the check. Lines diff
# emits about a missing operand match no path shape and always survive, which
# keeps "absent from one side is the verdict".
#
# A third argument names the repository the ignore rule is read from, for a
# caller whose source side is an archive extracted to a temporary directory
# and so is not a repository at all; it defaults to the source side.
felix_deploy_diff() {
  local src="$1" live="$2" igroot="${3:-$1}" d rc=0 line rest dir name p only
  for d in harness hooks commands; do
    [ -e "$src/$d" ] || [ -e "$live/$d" ] || continue
    # A directory on one side only is reported file by file, in the shape
    # diff itself uses for a lone entry, so the report names what was missed
    # rather than the operand diff could not open — and so each file passes
    # the residue rule on its own.
    only=""
    if [ -e "$src/$d" ] && [ ! -e "$live/$d" ]; then
      only="$(cd "$src" && find "$d" -type f 2>/dev/null | LC_ALL=C sort | sed "s|^|Only in $src: |")"
    elif [ ! -e "$src/$d" ] && [ -e "$live/$d" ]; then
      only="$(cd "$live" && find "$d" -type f 2>/dev/null | LC_ALL=C sort | sed "s|^|Only in $live: |")"
    fi
    while IFS= read -r line; do
      [ -n "$line" ] || continue
      p=""
      case "$line" in
        "Files $src/"*)
          # The filename itself may contain " and ", so the separator matched
          # is the whole " and $live/…" tail, never the first " and ". A
          # truncated path handed to check-ignore is answered about a
          # DIFFERENT file, and an ignore rule matching the fragment
          # certified a real content drift as clean — found in review, by
          # construction, before it shipped.
          p="${line#Files "$src/"}"; p="${p% differ}"; p="${p% and "$live"/*}" ;;
        "Only in $src: "*|"Only in $src/"*)
          # The slash and colon are the path boundary: without them, a live
          # directory whose absolute path merely begins with the src string
          # was parsed as src-relative, against the wrong root.
          rest="${line#Only in }"; dir="${rest%%: *}"; name="${rest#*: }"
          if [ "$dir" = "$src" ]; then p="$name"; else p="${dir#"$src/"}/$name"; fi ;;
        "Only in $live: "*|"Only in $live/"*)
          rest="${line#Only in }"; dir="${rest%%: *}"; name="${rest#*: }"
          if [ "$dir" = "$live" ]; then p="$name"; else p="${dir#"$live/"}/$name"; fi ;;
      esac
      # Asked twice because a directory-only pattern — `.claude-flow/`, the
      # incident's own rule — matches only what git can see is a directory,
      # and a cache-side stray does not exist in the tree at all; the
      # trailing slash supplies what the filesystem cannot. The global
      # excludes file is shut off: a verifier whose verdict varies with one
      # machine's personal ignore rules is not a verifier. What cannot be
      # shut off is .git/info/exclude — inside the repository's own .git, a
      # rule there is this machine's deliberate act, and it is named here so
      # nobody discovers it as a surprise.
      if [ -n "$p" ] && { git -C "$igroot" -c core.excludesFile=/dev/null check-ignore -q "$p" \
             || git -C "$igroot" -c core.excludesFile=/dev/null check-ignore -q "$p/"; } 2>/dev/null; then
        continue
      fi
      printf '%s\n' "$line"
      rc=1
    done <<EOF
$(if [ -n "$only" ]; then printf '%s\n' "$only"; else diff -rq "$src/$d" "$live/$d" 2>&1; fi)
EOF
  done
  return "$rc"
}

# The branch being merged into, as a ref this repository can read: the
# remote's copy first, so a local main that lags the remote is not what gets
# certified, then the local one. Prints nothing and fails when neither
# resolves, which is a repository that cannot say what was accepted.
felix_base_ref() {
  local root="$1" base="${2:-main}" ref
  for ref in "origin/$base" "$base"; do
    if git -C "$root" rev-parse --verify --quiet "$ref" >/dev/null 2>&1; then
      printf '%s' "$ref"; return 0
    fi
  done
  return 1
}

# Is the engine main accepted the one deployed? Both sides from the base
# (docs/2026-08-18-promotion-spec.md §4): the version main declares names the
# cache entry, and main's own engine/{harness,hooks,commands} — read from the
# commit, never from any working tree — is what that entry must hold. Every
# checkout can answer this, which is what lets `felix merge` run from a
# worktree (#2); the tree standing here does not enter into it.
#
#   exit 0  identical; prints the entry
#   exit 1  differs; every differing path on stdout, or one line naming the
#           version main declares and that nothing is installed at it
#   exit 2  cannot examine: no cache on this machine, no base ref, or a
#           version that cannot be read from the base
#
# Both readers of the question share this. deploy-check, the obligation
# ledger's evidence for the same fact, sources it from the tree beside it. The
# gate's `installed` check kept an inline copy until 2026-09-17, on the
# argument that a verifier which sources the code it judges can be switched
# off by editing that code; it now reads THIS FILE from the base ref with
# `git show` — never the working tree, never the cache entry — and calls this
# function in a subshell, so the code that judges is the code main accepted
# and the argument holds without the copy. The gate and the ledger cannot
# disagree by construction. FELIX_KERNEL, the suite's override of the judge,
# is not read: this asks about the real cache.
felix_accepted_deploy_diff() {
  local root="$1" base="${2:-main}" cache ref ver entry tmp d rc
  cache="${FELIX_KERNEL_CACHE:-${FELIX_PLUGIN_CACHE:-$HOME/.claude/plugins/cache}/felix/felix}"
  [ -d "$cache" ] || { printf 'cannot examine: no felix cache at %s\n' "$cache"; return 2; }
  ref="$(felix_base_ref "$root" "$base")" || { printf 'cannot examine: no %s or origin/%s in this repository\n' "$base" "$base"; return 2; }
  ver="$(_felix_plugin_version "$root" "$ref")"
  [ -n "$ver" ] || { printf 'cannot examine: %s declares no engine version\n' "$ref"; return 2; }
  entry="$cache/$ver"
  if [ ! -d "$entry/harness" ]; then
    printf '%s declares %s and nothing is installed at that version\n' "$ref" "$ver"
    return 1
  fi
  tmp="$(mktemp -d 2>/dev/null)" || { printf 'cannot examine: no temporary directory\n'; return 2; }
  for d in harness hooks commands; do
    git -C "$root" cat-file -e "$ref:engine/$d" 2>/dev/null || continue
    git -C "$root" archive "$ref" "engine/$d" 2>/dev/null | tar -x -C "$tmp" 2>/dev/null \
      || { rm -rf "$tmp"; printf 'cannot examine: could not read engine/%s at %s\n' "$d" "$ref"; return 2; }
  done
  felix_deploy_diff "$tmp/engine" "$entry" "$root/engine"; rc=$?
  rm -rf "$tmp"
  [ "$rc" -eq 0 ] && printf '%s\n' "$entry"
  return "$rc"
}
