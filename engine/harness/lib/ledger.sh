# The capability ledger.
#
# Which capabilities earn their place. Specced 2026-08-09 and unbuilt until
# 2026-08-11, because the spec contradicted itself: its body argued that parsing
# a session transcript breaks the bash-and-git invariant and that the pipeline
# must invert to recording as it happens, and its Records section then described
# a hook that parses a transcript. Recording needs no parser, so the invariant
# wins and this file has no JSON reader in it beyond pulling two known fields
# out of a hook payload.
#
# The asymmetry the design rests on: "loaded and used" is confounded, because
# loading a capability is what causes it to be used. So mounting is driven by
# declared need and only retiring is driven by evidence.
#
# That is why the zero rows matter more than the counts. A capability never
# reached for leaves no trace of its own; if nothing writes the zero down, the
# only thing the ledger can say is that whatever got used got used.
#
# **The correction, 2026-08-12.** This file used to claim a zero "is not
# confounded — it was mounted, it was in scope, and it was ignored every time."
# That is false, and the false half is the half Felix controls. Felix decides
# what the routes name, so a capability no route ever named was never in scope
# in any sense a session could act on. Its zero measures Felix's own priors, and
# retiring on it is a loop closing on itself: logged data confounded by the
# logging policy, which reads as evidence and is not. A year of it would be
# unusable, and the fix is only cheap before the year exists.
#
# So the policy's decision is recorded beside the outcome. `named` counts the
# times a route pointed at a capability; `calls` counts the times it was reached
# for. That splits one zero into two that mean opposite things:
#
#   named>0, calls=0   pointed at and ignored. Evidence about the capability.
#   named=0, calls=0   never pointed at. Evidence about ROUTING, and none at all
#                      about the capability. Reported by felix_ledger_unrouted.
#
# Two things this still does not fix, and they should not be written as if it
# did. Utilisation is not utility: a capability whose whole value is keeping the
# session off a wrong path is never invoked when it works, so counting calls
# punishes prevention and no column here observes the counterfactual. And a gate
# verdict is one bit for a session holding dozens of decisions, so nothing here
# can say which mounted capability earned it.

# Every row of the ledger, from the per-session files and from the single file
# that predates them.
#
# There are two locations because there used to be one, and one was the defect.
# `felix_ledger_rollup` was an unlocked read-modify-write of a shared file: it
# read what every other session had committed, spent wall time on per-row work,
# then renamed its own snapshot over the top. A session that committed inside
# that window was not merely missed, it was deleted, and the file could shrink.
# Reproduced at 1 of 12 with the real SessionEnd hook, against 12 of 12 run one
# at a time. Its input was already per-session, so the fix is to stop sharing
# the output rather than to make sharing safe.
#
# `ledger.tsv` is whatever was written before that and is read as data, not
# migrated: rewriting a record to change its shape is the one operation with
# nothing to gain and a whole history to lose. A session that has since been
# re-rolled wins over its own old rows, because those are the same rows written
# again and counting both would double it.
_felix_ledger_rows() {
  local mem="$1" f own=""
  for f in "$mem"/ledger.d/*.tsv; do
    [ -f "$f" ] || continue
    cat "$f"
    f="${f##*/}"
    own="$own${f%.tsv}
"
  done
  [ -f "$mem/ledger.tsv" ] || return 0
  # Through the environment rather than -v: a session id per line is the one
  # shape that cannot collide with a session id, and awk rejects a newline
  # inside a -v assignment — on the platform this runs on it says so on stderr
  # and drops the file, which reads downstream as a project with no history.
  FELIX_LEDGER_OWN="$own" LC_ALL=C awk -F'\t' '
    BEGIN {
      n = split(ENVIRON["FELIX_LEDGER_OWN"], a, "\n")
      for (i = 1; i <= n; i++) if (a[i] != "") have[a[i]] = 1
    }
    !($1 in have)
  ' "$mem/ledger.tsv"
}

# How many sessions each capability was present for, and how often it was
# actually reached for.
#
# Reduced to the owner on both sides. A package is declared as
# `superpowers@marketplace` and invoked as `superpowers:brainstorming`, and an
# MCP server is declared under its own name and invoked as `mcp__server__tool`.
# Counting those as three different things would report every capability as
# unused and every use as belonging to nothing.
#
# Emits: name <TAB> sessions <TAB> invocations <TAB> named
#
# `named` is -1 when no row for this capability carried the column, which is how
# data written before 2026-08-12 says "unknown" rather than "zero".
felix_ledger_summary() {
  local proj="$1"
  _felix_ledger_rows "$(felix_mem_dir "$proj")" | awk -F'\t' '
    $4 != "" {
      # A built-in skill is not the plugin that shares its name.
      #
      # The identity space here is one string, and the host provides skills
      # into it unqualified. Every plugin-provided item is recorded with its
      # provider prefix — including where plugin and item share a name — so a
      # `skill` row with no colon came from the host, not from a plugin. Left
      # unseparated it lands on the declared plugin, because the declaration
      # `<name>@<marketplace>` reduces to the same bare string one line below.
      #
      # On this machine that donated reaches and namings to a plugin that
      # ships no skill at all, and the donation is what kept it off every
      # list: retire needs calls at zero and the borrowed reaches disqualified
      # it, unrouted needs named at zero and the borrowed namings disqualified
      # it. The one capability with no evidence of its own was the only one the
      # report never mentioned. Same class as the plugin_<plugin>_<server>
      # misjoin below and running the other way: that one loses reaches and
      # manufactures a retire row, this one donates them and suppresses one.
      #
      # Only `skill` rows. A `named` row carrying a bare name is genuinely
      # ambiguous — a play naming <name> in a project that declares the plugin
      # of that name may mean either — and it stays with the plugin, which is
      # both the declared thing and the reading that makes the retire rule
      # true: pointed at, and whatever answered, the plugin did not.
      builtin = ($3 == "skill" && $4 !~ /:/)
      owner = $4
      sub(/@.*/, "", owner)
      sub(/:.*/, "", owner)
      # An MCP server a plugin ships is reached as plugin_<plugin>_<server>,
      # and the plugin is the unit that is declared, routed and retired. Left
      # unjoined, a route naming the plugin and reaches recorded under the
      # prefix of its server were two capabilities that never met, and one
      # browser-automation plugin sat on the retire list with 773 reaches
      # across three projects. Split on the underscore because marketplace
      # names use hyphens. A plugin name with an underscore of its own would
      # join to its first segment, and two such names sharing that segment
      # would be summed into one row; no installed plugin has one today, and
      # the day one does this is the line to revisit.
      if ($3 == "mcp" && owner ~ /^plugin_/) {
        n = split(owner, seg, "_")
        if (n >= 3) owner = seg[2]
      }
      # Appended after the reductions, never before: a marker containing a
      # colon or an @ would itself be reduced away, and one containing neither
      # cannot collide with a provider-prefixed name.
      if (builtin) owner = owner " (built-in)"
      key = owner SUBSEP $1
      if (!(key in seen)) { seen[key] = 1; sessions[owner]++ }
      calls[owner] += $5
      if (NF >= 6 && $6 != "") { named[owner] += $6; known[owner] = 1 }
    }
    END { for (o in sessions)
            printf "%s\t%s\t%s\t%s\n", o, sessions[o], calls[o],
                   (o in known ? named[o] : -1) }
  ' | LC_ALL=C sort
}

# How many distinct sessions the ledger holds. Field 1 is the session id.
#
# This is the denominator for every count rendered beside it, and it exists as
# a function because it had been written out twice: `felix ledger` computed it
# inline for its header, while the session-start banner did not compute it at
# all and asserted "every session" in its place. A row admitted on five
# sessions was being reported as a row seen in all of them.
felix_ledger_sessions() {
  _felix_ledger_rows "$(felix_mem_dir "$1")" \
    | cut -f1 | LC_ALL=C sort -u | LC_ALL=C awk 'NF { n++ } END { print n + 0 }'
}

# What Felix pointed at and nobody reached for.
#
# The only direction this may ever run. "Loaded and used" is confounded, because
# loading is what causes use, so no amount of counting can turn a high number
# into a reason to mount something.
#
# `named` is required, and a missing one never counts. Rows written before that
# column existed say nothing either way, and reading a blank as "named" would
# put the overclaim back in the one place nobody would look for it: the data
# already on disk.
#
# The window is sessions, not days. A capability unused across two sessions may
# simply not have come up; the threshold is what separates that from evidence.
# resolve.sh holds felix_mem_dir and felix_registry_field, both used below.
# Sourced by path with the house guard because the suite sources this library
# alone, in a subshell.
if ! command -v felix_mem_dir >/dev/null 2>&1; then
  . "$(dirname "${BASH_SOURCE[0]:-$0}")/resolve.sh"
fi

FELIX_LEDGER_MIN="${FELIX_LEDGER_MIN:-5}"
# What an installed copy ships, as far as the ledger can see it.
#
# A hook fires inside Claude Code and leaves no tool call. PostToolUse sees
# tool calls and nothing else, so another plugin's hook firing is invisible to
# the ledger by construction, and a plugin whose contribution is a hook reads
# zero forever however much it does. That zero is not disuse and must never be
# reported as it — the recorded lesson that utilisation is not utility, and the
# ledger was punishing prevention, made mechanical.
#
# But "ships a hook" is not one thing. The first draft made it one bit and
# filed every hooked plugin as unmeasurable; on this machine that reclassified
# exactly one row, and it was a plugin that ships a hook AND an MCP server AND
# a skill — two countable surfaces, pointed at by a route, never reached. So:
#
#   none    no hooks. Everything it does leaves a tool call; its zero is disuse.
#   only    hooks and nothing countable. Its zero is unmeasurable.
#   mixed   hooks and something countable. The countable part's zero is real
#           and the hook's is not, and the two are said apart — and the
#           proposal for it is scoped to the route that points at it, never
#           to the stack.tsv row, because removing the row removes the hook.
#
# "Ships" is a file test, not a firing test: a hooks.json that declares no
# events, or one a plugin option has switched off, still reads as shipped.
# Countable is any of .mcp.json, skills/, agents/, commands/ being present.
# Absent from the registry reads as none, because nothing says otherwise and a
# guess in the lenient direction would hide a real zero.
felix_ledger_hook_shape() {   # bare name -> none | only | mixed
  # Not `path`: under zsh that name is the array bound to PATH, and a person
  # sourcing this library from a zsh prompt would watch awk vanish and every
  # plugin read as none. The enforcing path is bash, but the diagnosis is not.
  local copy; copy="$(felix_registry_field "$1" installPath)"
  [ -n "$copy" ] && [ -f "$copy/hooks/hooks.json" ] || { printf 'none'; return 0; }
  if [ -f "$copy/.mcp.json" ] || [ -d "$copy/skills" ] || [ -d "$copy/agents" ] || [ -d "$copy/commands" ]; then
    printf 'mixed'
  else
    printf 'only'
  fi
}

# Hook-only: nothing here can be counted.
felix_ledger_unobservable() { [ "$(felix_ledger_hook_shape "$1")" = "only" ]; }

# The rows that are zero for enough sessions to mean something: named by a
# route, never reached, across FELIX_LEDGER_MIN sessions or more. Split below
# into the two things a zero can be.
_felix_ledger_zero_rows() {
  local proj="$1" name sessions calls named
  felix_ledger_summary "$proj" | while IFS=$'\t' read -r name sessions calls named; do
    [ -n "${name:-}" ] || continue
    [ "${calls:-0}" -eq 0 ] 2>/dev/null || continue
    [ "${named:--1}" -gt 0 ] 2>/dev/null || continue
    [ "${sessions:-0}" -ge "$FELIX_LEDGER_MIN" ] 2>/dev/null || continue
    printf '%s\t%s\t%s\n' "$name" "$sessions" "$named"
  done
}

# The zero rows, filtered to one hook shape.
_felix_ledger_zero_shaped() {   # proj, shape
  local name sessions named
  _felix_ledger_zero_rows "$1" | while IFS=$'\t' read -r name sessions named; do
    [ "$(felix_ledger_hook_shape "$name")" = "$2" ] || continue
    printf '%s\t%s\t%s\n' "$name" "$sessions" "$named"
  done
}

# The zero that is disuse. Proposed for retirement: the row and the play.
felix_ledger_retire()     { _felix_ledger_zero_shaped "$1" none; }

# The zero that is a hook nobody can count. Said as unmeasurable, proposed
# for nothing.
felix_ledger_unobserved() { _felix_ledger_zero_shaped "$1" only; }

# The zero on a plugin that ships a hook AND countable surfaces. The countable
# surfaces were pointed at and never reached — that part is disuse — while the
# hook cannot be counted. Proposed: drop it from the play that names it; keep
# the row, because the row is what mounts the hook.
felix_ledger_partly()     { _felix_ledger_zero_shaped "$1" mixed; }

# Mounted, and no route pointed at it in any recorded session.
#
# Precisely that, and not "no route names it" — `felix toolbox` reads the table
# and will happily say a route names the same capability. The two are different
# claims: the table can name a capability whose keywords never match the work
# anybody actually does, and that row is the one this finds.
#
# So it is a finding about routes.tsv, never about the capability. Retiring on
# it would be concluding Felix was right to ignore something because Felix
# ignored it. It is also weak while few sessions are recorded, since a route
# that has not fired yet looks identical to one that never will.
felix_ledger_unrouted() {
  local proj="$1" name sessions calls named uninvokable=""
  # A kind with no invocation form has no zero to measure.
  #
  # The rollup writes a zero row for every stack.tsv line whatever its kind,
  # and everything downstream is kind-agnostic, so a `marketplace` entered the
  # capability namespace as an equal. A marketplace is where plugins come
  # from: it has no play form and no legal route entry, so its named=0 and
  # calls=0 are a fact about the kind and not evidence about routing. The
  # report classified it as the one thing routes.tsv can fix, and `felix next`
  # handed out an action nobody can perform — wire a thing that cannot be
  # named. Read from stack.tsv rather than filtered at the source, so the
  # rows already on disk are covered too.
  if [ -f "$proj/stack.tsv" ]; then
    uninvokable="$(LC_ALL=C awk -F'\t' '$1 == "marketplace" && $2 != "" {
                     n = $2; sub(/@.*/, "", n); print n }' "$proj/stack.tsv")"
  fi
  felix_ledger_summary "$proj" | while IFS=$'\t' read -r name sessions calls named; do
    [ -n "${name:-}" ] || continue
    [ "${named:--1}" -eq 0 ] 2>/dev/null || continue
    [ "${calls:-0}" -eq 0 ] 2>/dev/null || continue
    felix_has_line "$uninvokable" "$name" && continue
    printf '%s\t%s\n' "$name" "$sessions"
  done
}

# The MCP record alone, per server: how many sessions it appears in, how often
# it was reached, how often a play named it (Decision C, 2026-08-30).
#
# A server is the unit that gets mounted, so it is the unit the reconciler
# reasons about — the summary above folds everything to one owner column and
# loses the kind, which is right for retirement and useless for mount state.
# Reduced to the owner the same way, because a declared row may carry a
# marketplace suffix while the recorded signal never does.
#
# Emits: name <TAB> sessions <TAB> calls <TAB> named
felix_ledger_mcp() {
  local proj="$1"
  _felix_ledger_rows "$(felix_mem_dir "$proj")" | LC_ALL=C awk -F'\t' '
    $3 == "mcp" && $4 != "" {
      owner = $4; sub(/@.*/, "", owner)
      # The same plugin_<plugin>_<server> fold the summary applies, or the
      # reconciler proposes mounting a server the plugin already provides
      # while the summary credits the plugin for the same reaches.
      if (owner ~ /^plugin_/) { n = split(owner, seg, "_"); if (n >= 3) owner = seg[2] }
      key = owner SUBSEP $1
      if (!(key in seen)) { seen[key] = 1; sessions[owner]++ }
      calls[owner] += $5
      if (NF >= 6 && $6 != "") named[owner] += $6
    }
    END { for (o in sessions)
            printf "%s\t%s\t%s\t%s\n", o, sessions[o], calls[o], named[o] + 0 }
  ' | LC_ALL=C sort
}

# One line per tool call, appended. This runs after every tool call in every
# governed session, so its cost is the design constraint: no subshells, no git,
# no reading anything back.
#
# Emits: kind <TAB> name. Empty when the payload carries no tool name, which is
# a normal answer and never an error.
felix_ledger_signal() {
  local raw="$1" tool skill
  tool="$(printf '%s' "$raw" \
    | sed -n 's/.*"tool_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)"
  [ -n "$tool" ] || return 0

  case "$tool" in
    # mcp__<server>__<tool>. The server is the unit that gets mounted, so it is
    # the unit worth counting: the design notes that MCP contribution is
    # invisible to the attribution fields and only tool names reveal it.
    mcp__*)
      tool="${tool#mcp__}"
      printf 'mcp\t%s' "${tool%%__*}"
      return 0 ;;
    Skill|skill)
      skill="$(printf '%s' "$raw" \
        | sed -n 's/.*"skill"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)"
      [ -n "$skill" ] && { printf 'skill\t%s' "$skill"; return 0; }
      ;;
    # Which agent, the way Skill records which skill. Recorded as a bare
    # `tool Agent`, a plugin whose whole contribution is a subagent type could
    # not be reached for at all. `Task` is what earlier Claude Code releases
    # called the same tool. Both extractions here take the LAST unescaped
    # `"key": "value"` on the line, so they depend on the payload carrying the
    # key once, in tool_input, which PostToolUse does today; a response that
    # echoed the same key later on the line would win.
    Agent|agent|Task|task)
      skill="$(printf '%s' "$raw" \
        | sed -n 's/.*"subagent_type"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)"
      [ -n "$skill" ] && { printf 'agent\t%s' "$skill"; return 0; }
      ;;
  esac
  printf 'tool\t%s' "$tool"
}

_felix_ledger_state() { printf '%s/state/ledger/%s.tsv' "$1" "$2"; }

# What a route named, recorded at the moment it was named.
#
# This is the policy's decision, and without it the ledger only ever holds the
# outcome. Same append-only, never-fatal shape as felix_ledger_record: it runs
# on every prompt, so a failure here loses a measurement and must never cost the
# session. Takes the play verbatim — a space-separated list of tools — because
# that is exactly what the route table holds and what got rendered.
felix_ledger_note_named() {
  local home="$1" session="$2" play="$3" f one
  [ -n "$session" ] && [ -n "$play" ] || return 0
  f="$(_felix_ledger_state "$home" "$session")"
  mkdir -p "$(dirname "$f")" 2>/dev/null || return 0
  for one in $play; do
    [ -n "$one" ] || continue
    printf 'named\t%s\n' "$one" >> "$f" 2>/dev/null || true
  done
}

# Append. Failure is never fatal and never blocks a tool call: a ledger that
# cannot write is a lost measurement, and a hook that fails loudly over one is a
# hook somebody removes.
felix_ledger_record() {
  local home="$1" session="$2" signal="$3" f
  [ -n "$session" ] && [ -n "$signal" ] || return 0
  f="$(_felix_ledger_state "$home" "$session")"
  mkdir -p "$(dirname "$f")" 2>/dev/null || return 0
  printf '%s\n' "$signal" >> "$f" 2>/dev/null || true
}

# Fold one session's appends into the committed ledger, once.
#
# Rewritten rather than appended to, so rolling the same session twice cannot
# double it: a SessionEnd hook can fire more than once, and a ledger that grows
# on every clear would report a capability as used far more than it was.
#
# The file it rewrites is its own, and that is the whole of the fix for #32.
# This used to rewrite one file shared by every session, which made "rewritten
# rather than appended to" — correct, and the reason this function exists —
# into a delete of everything another session had committed since the read.
# Nothing here now reads a row it did not write, so there is no window to lose
# and no lock to take.
felix_ledger_rollup() {
  local proj="$1" home="$2" session="$3" date="$4" state out seen kind name mem dir
  local seen_owner="" _o=""
  state="$(_felix_ledger_state "$home" "$session")"
  [ -f "$state" ] || return 0
  mem="$(felix_mem_dir "$proj")"
  dir="$mem/ledger.d"
  [ -d "$dir" ] || mkdir -p "$dir" 2>/dev/null || return 0
  out="$dir/$session.tsv"

  # Staged beside its destination so the rename below is a rename. mktemp
  # defaults to $TMPDIR, which is routinely a different filesystem, and mv
  # across one is a copy a reader can catch half written. The name is dotted
  # and unsuffixed so the reader's *.tsv glob cannot see it in flight.
  local tmp; tmp="$(mktemp "$dir/.${session}.XXXXXX")" || return 0

  # `named` rows are the policy's decision, not a call. They are folded into the
  # sixth column of whatever they name rather than being rows of their own.
  seen=""
  while IFS=$'\t' read -r kind name; do
    [ -n "${name:-}" ] || continue
    [ "$kind" = "named" ] && continue
    printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$session" "$date" "$kind" "$name" \
      "$(felix_count -xF "$kind	$name" "$state")" \
      "$(felix_count -xF "named	$name" "$state")" >> "$tmp"
    seen="$seen
$name"
    # The owner this signal can stand for, which is not always its own name.
    #
    # The zero-row loop below asks "did anything this session stand for the
    # declared capability", and a signal stands for a plugin when it carries
    # that plugin's prefix. A bare `skill` name carries none: the host provides
    # skills unqualified, so it stands for nothing declared and must not
    # suppress the declared row of the same name — which is what it did, and
    # the plugin then had no row at all in exactly the sessions where the
    # built-in ran.
    _o="${name%%:*}"; _o="${_o%%@*}"
    case "$kind" in skill) case "$name" in *:*) ;; *) _o="" ;; esac ;; esac
    [ -n "$_o" ] && seen_owner="$seen_owner
$_o"
  done <<EOF
$(sort -u "$state" 2>/dev/null)
EOF

  # Anything a route named that was never reached for. It has no call row to
  # hang a count on, and it is the most important cell in the table: Felix
  # pointed at it and the session went elsewhere.
  while IFS=$'\t' read -r kind name; do
    [ "${kind:-}" = "named" ] || continue
    [ -n "${name:-}" ] || continue
    printf '%s\n' "$seen" | grep -xF "$name" >/dev/null 2>&1 && continue
    printf '%s\t%s\tnamed\t%s\t0\t%s\n' "$session" "$date" "$name" \
      "$(felix_count -xF "named	$name" "$state")" >> "$tmp"
    seen="$seen
$name"
    # A play naming is not a provider signal, so there is no built-in case
    # here: whatever it names, it names by the owner it wrote.
    _o="${name%%:*}"; _o="${_o%%@*}"
    seen_owner="$seen_owner
$_o"
  done <<EOF
$(sort -u "$state" 2>/dev/null)
EOF

  # The zero rows. Every declared capability that this session never reached
  # for, written down because absence of use given presence is the only
  # unconfounded evidence in the design and it leaves no trace of its own.
  if [ -f "$proj/stack.tsv" ]; then
    while IFS=$'\t' read -r kind name _src _risk _cap; do
      case "${kind:-}" in ''|'#'*) continue ;; esac
      [ -n "${name:-}" ] || continue
      # stack.tsv names a package (`superpowers@marketplace`); a signal names
      # what was actually invoked (`superpowers:brainstorming`). Compared with
      # both sides reduced to the owner, or a plugin whose skill was used all
      # session gets recorded as never reached for — which would put the one
      # unconfounded signal in the design permanently in the wrong column.
      local bare="${name%%@*}"
      printf '%s\n' "$seen_owner" | grep -xF "$bare" >/dev/null 2>&1 && continue
      # Owner-equality, not substring. This used to be `felix_count -F`, and a
      # bare -F match let a declared server accrue `named` it never earned from
      # any play entry it merely prefixes — `context7` counted every naming of
      # `context7-docs`, and five such sessions read as "pointed at and ignored
      # five times", the exact evidence retire and the reconciler act on. The
      # reduction is the summary's own: strip a marketplace suffix and a skill
      # suffix, then compare whole owners.
      printf '%s\t%s\t%s\t%s\t0\t%s\n' "$session" "$date" "$kind" "$name" \
        "$(LC_ALL=C awk -F'\t' -v b="$bare" \
             '$1 == "named" { o = $2; sub(/@.*/, "", o); sub(/:.*/, "", o)
                              if (o == b) n++ }
              END { print n + 0 }' "$state")" >> "$tmp"
    done < "$proj/stack.tsv"
  fi

  mv -f "$tmp" "$out" 2>/dev/null || rm -f "$tmp"
}

# Fold every session nothing folded.
#
# The rollup runs from one place: the SessionEnd hook. So a session that is
# killed, put to sleep, or torn down with its process never folds, and its
# appends sit in state/ledger/ uncounted forever. Measured on this machine the
# night it was found: 31 stranded sessions from 2026-08-11 onward, several
# carrying thousands of reaches, against 12 that had folded. The ledger was
# therefore reporting the sessions that happened to exit cleanly and calling
# that "the only unconfounded signal here" — while recommending capabilities be
# retired for a zero that was an artefact of how their sessions ended.
#
# Safe by construction, and for the reason the rollup already gives above: it
# rewrites its own file rather than appending, so folding a session twice — or
# folding a live one that folds again at its own end — cannot double anything.
#
# The date is the state file's own mtime, never today's. A session from three
# weeks ago folded under today's date would report old work as recent, which is
# the same defect one level down from the one this fixes.
#
# Not called from any hook. It walks every unfolded session and the rollup is
# several greps per distinct signal, so its cost belongs to a person running
# `felix ledger` and not to every session start. Prints how many it folded.
# Does this repository's history contain the session's first HEAD?
#
# state/ledger/ carries no project namespace, and that is deliberate: the
# PostToolUse hook refuses to resolve the project because resolution touches
# git, and that would put a git invocation behind every Read, Edit and Bash in
# every session on this machine. SessionEnd resolves PWD and folds to the right
# project. Anything that folds LATER has nothing to resolve with, and the first
# version of the catch-up therefore folded every unfolded session into whichever
# project happened to ask — importing one project's routing into another's
# ledger, and putting a capability on a retire list whose name the project's
# tables have never contained.
#
# No new record is needed to answer it. The user-prompt hook already writes the
# governed repository's HEAD to state/session/<id> (felix_session_mark, first
# mark wins), and governed repositories have disjoint histories, so `git
# cat-file -e` decides it with bash and git and nothing else.
#
# A session with no mark, or a mark this repository does not contain, is not
# ours. Both return 1: unknown holds rather than guessing, which is the same
# reading of unknown the probes runner and the commissioning table already use.
_felix_ledger_owns() {   # home, root, session -> 0 when this repository owns it
  local home="$1" root="$2" session="$3" sha
  [ -n "$root" ] || return 1
  sha="$(head -1 "$home/state/session/$session" 2>/dev/null)"
  [ -n "$sha" ] || return 1
  git -C "$root" cat-file -e "${sha}^{commit}" 2>/dev/null
}

# Is this session's fold current — does it account for everything on disk?
#
# The guard here used to be `[ -f "$dir/$session.tsv" ]`, which tests whether a
# fold exists and not whether it is finished. Both ways a fold goes stale are
# ordinary. The catch-up folds sessions that are still alive, because it cannot
# tell which are; and a resumed session (`--continue`, same id) appends to a
# state file that a previous SessionEnd already folded. Either way the state
# file keeps growing, the fold does not, and because a fold now EXISTS neither
# loop ever looks at it again.
#
# The header above this pair used to argue the catch-up is safe by
# construction. That argument is about double-counting and it is correct — the
# rollup is a whole-file rewrite, staged and renamed, so folding twice cannot
# add anything. It says nothing about under-counting, which is what the
# existence test actually caused: an audit found four signals on disk since
# 2026-09-01 — one reach and three route namings — that the summary could
# never see, because a SessionEnd fold at 15:14 was followed by appends until
# 17:35 and the catch-up skipped it three days running.
#
# `-nt` rather than stat: it is a bash builtin, it needs no date parsing, and
# equal mtimes read as not-newer, which is the right answer for a fold that
# already accounts for the file.
_felix_ledger_fold_current() {   # state file, fold file -> 0 when nothing new
  [ -f "$2" ] || return 1
  [ "$1" -nt "$2" ] && return 1
  return 0
}

# The sessions nobody typed into, from the one record that says which they were.
#
# Until #264 the platform's summary request came through the prompt hook as a
# session of its own, and each one left what a session leaves: a mark, a named
# play in state/ledger, a fold in ledger.d. A one-off pass takes the folds away.
# The rest stays on disk, so the two loops below met a session whose record was
# behind what is on disk, and the catch-up folded it straight back: the pass
# undone by the next `felix ledger`, and session-start holding every unmount
# proposal on account of sessions that never were.
#
# says.log is where the old prompt hook wrote what it was asked, beside the
# session id and when, cut to its first 200 characters by felix_say. That is
# all of the request the record keeps, and 200 characters of its opening are
# words a person can paste as well: the prompt hook reads a person who stops
# short of the whole opening and closing as a person, and still writes their
# brief with the same 200 characters in it. Matched on those alone, that
# person's session was passed over here, never folded and never counted as
# stranded, with whatever it reached for. So a session is taken for one of
# these only when its brief rows can have come from nothing else:
#
#   every brief row of the session asked the first 200 characters of an
#   opening route.sh lists, since the request was its only prompt; and
#   every one was written before the day route.sh gives for that wording,
#   when no engine that matched it was running yet and a request of the
#   platform's was still briefed like a prompt.
#
# What this still takes for one: a person's session from before that day whose
# only briefs asked those 200 characters. In the logs on 2026-09-22 there is
# none; each of the 78 sessions with such a row has that one brief and no other.
#
# Read at most once per walk, and only when the walk meets a session it would
# otherwise count, so a home with nothing stranded pays nothing for it. route.sh
# holds the wordings, and session-start does not source it, hence the load here.
_felix_ledger_machine_sessions() {   # proj -> one session id per line
  local says forms="" i
  says="$(felix_mem_dir "$1")/says.log"
  [ -f "$says" ] || return 0
  [ -n "${_FELIX_ROUTE_SESSION_REQUESTS+x}" ] \
    || . "$(dirname "${BASH_SOURCE[0]:-$0}")/route.sh" 2>/dev/null || return 0
  # day <TAB> the opening's first 200 characters, one wording per line.
  for ((i = 0; i + 2 < ${#_FELIX_ROUTE_SESSION_REQUESTS[@]}; i += 3)); do
    forms="${forms}${_FELIX_ROUTE_SESSION_REQUESTS[i + 2]}	${_FELIX_ROUTE_SESSION_REQUESTS[i]:0:200}
"
  done
  # Through the environment, because awk -v would read each `\n` in the
  # wording as a newline and the row holds it as two characters. The stamps
  # are ISO 8601 in UTC, so a string comparison against the day is a
  # comparison of times: a row from that day or later is not before it.
  _FELIX_LEDGER_FORMS="$forms" LC_ALL=C awk -F'\t' '
    BEGIN { n = split(ENVIRON["_FELIX_LEDGER_FORMS"], f, "\n")
            for (i = 1; i <= n; i++) {
              j = index(f[i], "\t")
              if (j > 1) day[substr(f[i], j + 1)] = substr(f[i], 1, j - 1)
            } }
    $2 != "brief" { next }
    ($4 in day) && ($1 "") < day[$4] { old[$3] = 1; next }
    { other[$3] = 1 }
    END { for (s in old) if (!(s in other)) print s }' "$says" 2>/dev/null
}

# How many sessions have appends that nothing folded.
#
# The companion to the catch-up, and the reason it exists separately: the
# catch-up costs several greps per distinct signal per stranded session and
# belongs to a person running `felix ledger`, while this is one stat per state
# file and no reads at all, which is cheap enough for a hook.
#
# It exists because the catch-up does not run in a hook. The moment a session
# ends uncleanly the fold is incomplete again, and the session-start banner
# goes on naming what was pointed at and never reached while calling it the
# only unconfounded signal here. That is this repository's own recorded lesson
# one level down: "Nothing due" and "nothing is being checked" render
# identically.
#
# It counts a stale fold as well as a missing one, and that is not a detail:
# the qualifier this number gates is the sentence that tells a reader the list
# above it may not be clearing. When both loops tested existence alone, a fold
# that had stopped keeping up made this zero, so the banner printed the retire
# list with no caveat at all while uncounted reaches sat on disk.
felix_ledger_stranded() {
  local proj="$1" home="$2" root="${3:-}" mem dir f session n=0 machine="" looked=0
  mem="$(felix_mem_dir "$proj")"
  dir="$mem/ledger.d"
  for f in "$home"/state/ledger/*.tsv; do
    [ -f "$f" ] || continue
    session="$(basename "$f" .tsv)"
    _felix_ledger_fold_current "$f" "$dir/$session.tsv" && continue
    _felix_ledger_owns "$home" "$root" "$session" || continue
    [ "$looked" = 1 ] || { machine="$(_felix_ledger_machine_sessions "$proj")"; looked=1; }
    printf '%s\n' "$machine" | grep -qxF -- "$session" && continue
    n=$((n + 1))
  done
  printf '%s' "$n"
}

felix_ledger_catchup() {
  local proj="$1" home="$2" root="${3:-}" mem dir f session n=0 machine="" looked=0
  mem="$(felix_mem_dir "$proj")"
  dir="$mem/ledger.d"
  for f in "$home"/state/ledger/*.tsv; do
    [ -f "$f" ] || continue
    session="$(basename "$f" .tsv)"
    _felix_ledger_fold_current "$f" "$dir/$session.tsv" && continue
    _felix_ledger_owns "$home" "$root" "$session" || continue
    [ "$looked" = 1 ] || { machine="$(_felix_ledger_machine_sessions "$proj")"; looked=1; }
    printf '%s\n' "$machine" | grep -qxF -- "$session" && continue
    felix_ledger_rollup "$proj" "$home" "$session" \
      "$(date -r "$f" -u +%Y-%m-%d 2>/dev/null || date -u +%Y-%m-%d)" || continue
    n=$((n + 1))
  done
  printf '%s' "$n"
}
