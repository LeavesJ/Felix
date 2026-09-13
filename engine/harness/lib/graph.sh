# The knowledge graph, as a fact the session is told rather than a tool it
# might think to reach for.
#
# Measured 2026-09-10: the graph under graphify-out/ had been built three times
# and queried once across 72 recorded sessions, and the once was the session in
# which the founder asked why it was never used. The first fix was a route —
# `orient`, keyed on the words a structure question is asked with. That was
# right and insufficient: a route fires when the prompt matches it, and most
# sessions do not open by saying "trace" or "architecture". A tool that is only
# named when you already knew to ask for it is a tool for people who did not
# need it.
#
# So the graph stops being a suggestion and becomes a line in the one place a
# session always reads: the start. Three facts, no advice — that it exists,
# whether it still describes this tree, and the command that asks it.
#
# What this file may not do, and the boundary is the second invariant rather
# than taste: no model, no network, no cost in front of a person. Reading the
# stamp is a tail of the last four kilobytes, measured at 8ms on a 1.9MB graph;
# reading the whole file to count nodes was 83ms and bought a number nobody
# acts on.

FELIX_GRAPH_TAIL="${FELIX_GRAPH_TAIL:-4096}"

# The graph belongs to the checkout that holds it, not to the tree you are
# standing in. A worktree has no graphify-out/ of its own and never will: the
# graph is built from the holding checkout, so that is the tree it describes
# and the tree its staleness is measured against. This is the same correction
# the graphify maintenance row needed.
felix_graph_home() {
  local root="${1:-$PWD}" common
  common="$(git -C "$root" rev-parse --git-common-dir 2>/dev/null)" || return 1
  case "$common" in
    /*) ;;
    *)  common="$root/$common" ;;
  esac
  (cd "$(dirname "$common")" 2>/dev/null && pwd -P) || return 1
}

felix_graph_file() {
  local home; home="$(felix_graph_home "${1:-$PWD}")" || return 1
  [ -f "$home/graphify-out/graph.json" ] || return 1
  printf '%s/graphify-out/graph.json\n' "$home"
}

# The commit the graph says it was built from, or nothing.
#
# From the tail rather than the whole document. `built_at_commit` is the last
# key graphify writes, and a hook that runs in every session of every governed
# project does not get to read two megabytes to learn forty characters. If the
# key ever moves to the front this returns nothing, which reads as "no stamp"
# — the honest answer, and the one that does not claim currency it cannot
# establish.
felix_graph_stamp() {
  local f="${1:-}" s
  [ -f "$f" ] || return 1
  s="$(tail -c "$FELIX_GRAPH_TAIL" "$f" 2>/dev/null \
       | sed -n 's/.*"built_at_commit"[[:space:]]*:[[:space:]]*"\([0-9a-f]\{7,40\}\)".*/\1/p' | head -1)"
  [ -n "$s" ] || return 1
  printf '%s\n' "$s"
}

# How many commits the holding checkout has taken since the graph was built.
# Nothing and non-zero when the stamp names a commit this repository does not
# have — a graph built elsewhere describes something, but not this.
felix_graph_behind() {
  local root="${1:-$PWD}" stamp="${2:-}" home n
  [ -n "$stamp" ] || return 1
  home="$(felix_graph_home "$root")" || return 1
  git -C "$home" cat-file -e "${stamp}^{commit}" 2>/dev/null || return 1
  n="$(git -C "$home" rev-list --count "${stamp}..HEAD" 2>/dev/null)" || return 1
  case "$n" in ''|*[!0-9]*) return 1 ;; esac
  printf '%s\n' "$n"
}

# The line a session is told at its start, or nothing at all.
#
# Nothing is the important half. A project with no graph hears no line, and a
# line that cannot say whether the graph is current does not pretend: an
# unreadable stamp says so rather than implying freshness. The rule this file
# exists to serve is that a session should know the graph is there; it is not
# served by a sentence that is wrong.
felix_graph_line() {
  local root="${1:-$PWD}" f stamp behind
  f="$(felix_graph_file "$root")" || return 1
  stamp="$(felix_graph_stamp "$f")" || {
    printf 'Knowledge graph: present, and carrying no build stamp, so whether it\n'
    printf 'still describes this tree is unknown. Ask it with: graphify query "..."\n'
    return 0
  }
  if ! behind="$(felix_graph_behind "$root" "$stamp")"; then
    printf 'Knowledge graph: built at %s, which is not a commit this repository\n' "${stamp%"${stamp#???????}"}"
    printf 'holds. Ask it with: graphify query "..." and treat it as describing another tree.\n'
    return 0
  fi
  if [ "$behind" -eq 0 ]; then
    printf 'Knowledge graph: current with this checkout. Ask it before reading files:\n'
    printf '  graphify query "how does X work"   graphify explain "X"   graphify affected "X"\n'
  else
    printf 'Knowledge graph: %s commit(s) behind this checkout, built at %s.\n' \
      "$behind" "${stamp%"${stamp#???????}"}"
    printf 'Still worth asking — it is stale, not wrong — with: graphify query "..."\n'
  fi
  return 0
}

# Code-only refresh, in the background, at most one at a time.
#
# `graphify update` re-extracts code files and says so itself: no LLM needed.
# That is what makes this legal here. The semantic half — documents, papers,
# images — needs a model, a hook may never call one, and so the documents in
# this repository stay the job of the maintenance routine a session runs. This
# closes the common case, which is code moving, and says nothing about the
# other.
#
# The shrink guard is left on deliberately. `graphify update` refuses to write
# a graph with fewer nodes than the one it replaces unless forced, and a
# background job that quietly shrank the graph would be worse than one that did
# nothing. A refusal leaves the previous graph in place and the staleness line
# keeps saying so.
#
# The lock is a directory because mkdir is atomic everywhere and a stale lock
# file is not. Same shape as the discovery refresh, for the same reason.
felix_graph_refresh_bg() {
  local root="${1:-$PWD}" home lock
  command -v graphify >/dev/null 2>&1 || return 0
  home="$(felix_graph_home "$root")" || return 0
  [ -d "$home/graphify-out" ] || return 0
  lock="$home/graphify-out/.felix-refresh.lock"
  mkdir "$lock" 2>/dev/null || return 0   # already running; leave it alone
  (
    trap 'rmdir "$lock" 2>/dev/null' EXIT
    felix_close_inherited_fds
    cd "$home" 2>/dev/null || exit 0
    graphify update "$home" >/dev/null 2>&1
  ) </dev/null >/dev/null 2>&1 &
  return 0
}
