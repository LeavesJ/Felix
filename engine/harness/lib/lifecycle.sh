# The session lifecycle, one row per moment.
#
# A session starts, resumes, is cleared or is compacted, and between sessions
# a handoff is written or refused. The only record of those moments was kept
# by two of ECC's hooks, session:start's resume markers and
# stop:cost-tracker's costs.jsonl, and the founder's settings edit (queue item
# 1) switches both off. Every direct-strength failure in the usage analysis
# was a handoff failure, and none of the per-session questions — resume after
# idle, an engine promoted mid-session, restart against continue — can be
# asked of a record that does not say when a session began, on which engine,
# at which HEAD, having been handed which handoff. So Felix keeps it. Nothing
# here reads it: the evaluations are derived later, from this file and the
# transcripts.
#
# A dated exception to rows-first, taken 2026-09-21 and closed 2026-09-22.
# This was a new store landing ahead of the table validator, queue item 2,
# because it had to exist before queue item 1 took effect. Its schema row is
# now in templates/schemas.tsv, and the suite checks the rows this file writes
# against that row with lib/table.sh. The columns below and that row must say
# the same nine names in the same order; the suite holds them to it.
#
# Append-only TSV at $(felix_mem_dir <project>)/lifecycle.log: the memory
# root, never the tree, and apart from the ledger. Nine columns on every row,
# `-` wherever a field does not apply or cannot be read, and no tab or line
# break inside a field, since either would move every column after it:
#
#   1 time        UTC, 2026-09-21T12:00:00Z, the stamp the other memory logs use
#   2 kind        startup | resume | clear | compact, the SessionStart source;
#                 or handoff; or summary, written by the prompt hook when the
#                 session is the platform's summary request (#264). SessionStart
#                 cannot tell one apart, so that session's startup row is
#                 already here, and a reader drops every row of a session that
#                 has a summary row. A source the platform has not named is
#                 `-`, so the column holds what a schema row can enumerate.
#   3 session     the payload's session_id
#   4 bound       the engine executing this code, read from its own plugin.json
#   5 installed   what the Claude Code registry has installed for felix: the
#                 promoted engine, which a long session may be behind
#   6 head        the full sha of the governed checkout's HEAD; `unborn` in a
#                 repository with no commit yet, `-` where git has no repository
#   7 handoff     git hash-object of the project's SESSION_HANDOFF.md as it
#                 stands at that moment, the join between a handoff row and the
#                 session start that was handed it
#   8 transcript  the payload's transcript_path
#   9 note        on a handoff row, written | replaced | refused; `-` otherwise
#
# It never blocks and never fails its caller. It runs at every session start
# of every governed project, so it asks git two things at most, rev-parse and
# hash-object, reads plugin.json and cleans every field by parameter
# expansion, and sends every error nowhere: a row that cannot be written is a
# lost row, not a broken session. The callers wrap it the same way.

# The engine's own plugin.json, found from this file rather than from
# CLAUDE_PLUGIN_ROOT. That variable is set only when Felix runs as a plugin,
# and a plain settings.json hook is the same engine running the same code. A
# copy with no plugin.json beside it gets `-`, never the registry's version:
# the point of two columns is a session running something other than what is
# promoted, and filling one from the other would hide exactly that.
case "${BASH_SOURCE[0]:-}" in
  */*) _FELIX_LC_PLUGIN="${BASH_SOURCE[0]%/*}/../../.claude-plugin/plugin.json" ;;
  *)   _FELIX_LC_PLUGIN="./../../.claude-plugin/plugin.json" ;;
esac
_felix_lc_out=""

# A SessionStart moment. proj, the directory it started in, then the payload's
# source, session_id and transcript_path, each empty when it carried none.
felix_lifecycle_session() {
  local kind
  case "${3:-}" in
    startup|resume|clear|compact) kind="$3" ;;
    *)                            kind="" ;;
  esac
  _felix_lifecycle_row "$1" "$2" "$kind" "${4:-}" "${5:-}" ""
}

# A felix handoff. proj, the checkout's root, and why: written, replaced or
# refused. Called after the write or the refusal, so the hash is of the file as
# it now stands — the one the next session start will read.
felix_lifecycle_handoff() {
  _felix_lifecycle_row "$1" "$2" handoff "" "" "${3:-}"
}

# The platform's summary request, recognised by the prompt hook (#264). proj,
# the directory, the payload's session_id and transcript_path. The one row a
# summary session adds, so the startup row it already has can be told apart.
felix_lifecycle_summary() {
  _felix_lifecycle_row "$1" "$2" summary "${3:-}" "${4:-}" ""
}

# proj, dir, kind, session, transcript, note
_felix_lifecycle_row() {
  local proj="$1" dir="$2" kind="$3" sess="$4" trans="$5" note="$6"
  local mem stamp bound installed sha rc hash="" row="" v tab
  tab=$'\t'
  [ -n "$proj" ] || return 0
  mem="$(felix_mem_dir "$proj")"
  [ -n "$mem" ] || return 0
  stamp="$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null)"
  _felix_lc_bound; bound="$_felix_lc_out"
  installed="$(felix_registry_field felix version 2>/dev/null)"
  # Three answers that mean three things. rev-parse --verify -q exits 1, and
  # says nothing, where HEAD names no commit yet; outside any repository it
  # exits 128.
  sha="$(git -C "$dir" rev-parse -q --verify HEAD 2>/dev/null)"; rc=$?
  case "$rc" in 0) ;; 1) sha=unborn ;; *) sha="" ;; esac
  # --no-filters: the bytes on disk, whichever checkout's attributes the
  # caller happens to be standing in.
  [ -f "$mem/SESSION_HANDOFF.md" ] \
    && hash="$(git hash-object --no-filters -- "$mem/SESSION_HANDOFF.md" 2>/dev/null)"
  for v in "$stamp" "${kind:-}" "$sess" "$bound" "$installed" "$sha" "$hash" "$trans" "${note:-}"; do
    _felix_lc_field "$v"
    row="$row${row:+$tab}$_felix_lc_out"
  done
  [ -d "$mem" ] || mkdir -p "$mem" 2>/dev/null || return 0
  # Braced so the redirection's own complaint goes nowhere too. Written as
  # `printf ... >> log 2>/dev/null`, bash opens the log first and reports the
  # failure before stderr is redirected.
  { printf '%s\n' "$row" >> "$mem/lifecycle.log"; } 2>/dev/null || return 0
}

# One field, cleaned into _felix_lc_out: tabs and line breaks become spaces,
# and nothing becomes `-`. A variable rather than a printf, so the row costs
# no subshell per column.
_felix_lc_field() {
  _felix_lc_out="${1//$'\t'/ }"
  _felix_lc_out="${_felix_lc_out//$'\n'/ }"
  _felix_lc_out="${_felix_lc_out//$'\r'/ }"
  [ -n "$_felix_lc_out" ] || _felix_lc_out="-"
}

# The first "version" in this engine's plugin.json, into _felix_lc_out, or
# nothing. The same field discover's stamp reads with sed, read here with
# `read` and parameter expansion because this runs at every session start.
_felix_lc_bound() {
  local l v
  _felix_lc_out=""
  [ -f "$_FELIX_LC_PLUGIN" ] || return 0
  while IFS= read -r l || [ -n "$l" ]; do
    case "$l" in *'"version"'*) ;; *) continue ;; esac
    v="${l#*\"version\"}"
    v="${v#"${v%%[![:space:]]*}"}"
    case "$v" in :*) v="${v#:}" ;; *) continue ;; esac
    v="${v#"${v%%[![:space:]]*}"}"
    case "$v" in \"*) v="${v#\"}"; _felix_lc_out="${v%%\"*}"; return 0 ;; esac
  done 2>/dev/null < "$_FELIX_LC_PLUGIN"
  return 0
}
