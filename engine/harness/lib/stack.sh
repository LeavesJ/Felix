# Desired-state provisioning for a project's Claude environment.
#
# A project declares the marketplaces, plugins, and MCP servers it needs. Felix
# reads what is actually installed, diffs, and either prints the plan or applies
# it. Same shape as the guidebook's infrastructure rule (p32): propose, plan,
# check the diff against policy, get approval if required, apply, verify.
#
# Two things keep this from being a footgun.
#
# Capability gating: an entry is only in scope when the capability that justifies
# it is active. A project with no payments never gets billing tooling proposed,
# and the day it does, detection surfaces it first.
#
# Risk tiers: the decision is not made here. admit.sh holds the one install
# policy for every caller, and the row says who grounded it in its sixth
# column — DECLARED for a person's judgment, OBSERVED for what the engine read
# off a plugin, and DECLARED again when the column is absent, which is what
# every manifest written before it relies on. High never installs, at any flag,
# from any caller. High means the tool can move money, reach production, or hold a
# credential, and no automation flag should be able to mount one of those
# without a person present.

# Sourced by path because the suite sources this library alone, in a subshell,
# and a policy call that resolved to nothing would refuse in silence — which
# reads exactly like a correct refusal.
if ! command -v felix_admit >/dev/null 2>&1; then
  . "$(dirname "${BASH_SOURCE[0]:-$0}")/admit.sh"
fi

# Manifest rows: kind <TAB> name <TAB> source <TAB> risk <TAB> capability
#                [<TAB> grounding], absent meaning DECLARED
_felix_stack_rows() {
  local proj="$1"
  [ -f "$proj/stack.tsv" ] || return 0
  grep -vE '^\s*(#|$)' "$proj/stack.tsv"
}

# Actual state, read once because `claude mcp list` runs health checks and is slow.
_felix_load_state() {
  _FELIX_PLUGINS="$(claude plugin list 2>/dev/null || true)"
  _FELIX_MCPS="$(claude mcp list 2>/dev/null || true)"
  _FELIX_MKTS="$(claude plugin marketplace list 2>/dev/null || true)"
  # Bundled plugins are `<name>@inline` keys in ~/.claude.json and appear in
  # no `claude plugin list`. Without this a declared bundled row read as
  # absent, `install` was attempted on every run, the cli said "not found in
  # any configured marketplace", and the first live commissioning run held
  # two projects on a plugin that was live in every session. ready.sh already
  # read the same keys; the stack inventory now reads them too.
  _FELIX_INLINE="$(sed -n 's/.*"\([A-Za-z0-9._-]*\)@inline".*/\1/p' "$HOME/.claude.json" 2>/dev/null | LC_ALL=C sort -u)"
}

# A server is mounted only when its line says connected. Configured-but-failing
# is the state the GitHub server sits in until someone exports a token, and
# calling that mounted hides the only fact that matters.
_felix_mcp_connected() {
  local line
  while IFS= read -r line; do
    case "$line" in
      "$1:"*|*":$1:"*)
        felix_contains "$line" "Failed to connect" && return 1
        felix_contains "$line" "Needs authentication" && return 1
        return 0 ;;
    esac
  done <<EOF
$_FELIX_MCPS
EOF
  return 1
}

_felix_have() {
  case "$1" in
    plugin)      felix_contains "$_FELIX_PLUGINS" "$2" || felix_has_line "${_FELIX_INLINE:-}" "${2%%@*}" ;;
    # A connected MCP and a merely-configured one are different states. The
    # GitHub server sits in the list reporting "Failed to connect" until someone
    # completes OAuth, and calling that mounted would hide the one fact that
    # matters.
    mcp)         _felix_mcp_connected "$2" ;;
    marketplace) felix_contains "$_FELIX_MKTS" "$2" ;;
    skill)       [ -d "$HOME/.claude/skills/$2" ] ;;
    *) return 1 ;;
  esac
}

_felix_cap_active() {
  local cap="$1" proj="$2"
  [ "$cap" = "always" ] && return 0
  felix_has_line "$(felix_declared "$proj")" "$cap"
}


# Classify every manifest row. Emits: action <TAB> kind <TAB> name <TAB> detail
felix_stack_plan() {
  local proj="$1"
  _felix_load_state
  # The sixth column is who grounded the row. Absent, it is a person's —
  # DECLARED — which is what every row was before the column existed. A row
  # the engine wrote after reading a plugin says OBSERVED, and the policy
  # holds an OBSERVED medium for a person where it installs a DECLARED one:
  # that difference is the reason the column exists.
  _felix_stack_rows "$proj" | while IFS=$'\t' read -r kind name source risk cap ground; do
    [ -n "${kind:-}" ] || continue
    ground="${ground:-DECLARED}"
    if _felix_have "$kind" "$name"; then
      printf 'present\t%s\t%s\t-\n' "$kind" "$name"
    elif ! _felix_cap_active "${cap:-always}" "$proj"; then
      printf 'dormant\t%s\t%s\tneeds capability: %s\n' "$kind" "$name" "$cap"
    elif [ "$(felix_admit "${risk:-}" "$ground")" != "install" ]; then
      printf 'blocked\t%s\t%s\t%s\n' "$kind" "$name" "$(felix_admit_why "${risk:-}" "$ground")"
    elif [ "$kind" = "skill" ]; then
      # Standalone skills are files, not packages. There is no install command
      # to run, so they route to a setup runbook instead of pretending.
      printf 'manual\t%s\t%s\tsee: felix setup\n' "$kind" "$name"
    else
      printf 'install\t%s\t%s\t%s\n' "$kind" "$name" "$(felix_admit_why "$risk" "$ground")"
    fi
  done
}

# resolve.sh holds felix_has_line and felix_registry_field, both used below.
# Sourced by path with the house guard because the suite sources this library
# alone, in a subshell. Without it felix_registry_field would be missing rather
# than wrong, its substitution would be empty, and every plugin-provided server
# would fall through to the mount branch — the fix degrading silently into the
# defect it replaces.
if ! command -v felix_registry_field >/dev/null 2>&1; then
  . "$(dirname "${BASH_SOURCE[0]:-$0}")/resolve.sh"
fi

# What the record proposes changing about what is mounted (Decision C step 3,
# 2026-08-30). The ledger records which MCP servers were reached; stack.tsv
# records which are declared. This reads both and proposes — it installs
# nothing, removes nothing, and edits nothing, because mounting binds at
# session start and a person decides what stays mounted.
#
# The asymmetry is the ledger's own. A mount is proposed only on a reach: the
# server answered, so it exists and it earned its row. An unmount mirrors
# felix_ledger_retire — declared, pointed at, and never reached across enough
# sessions. Declared-and-never-named proposes nothing: that zero measures
# routing, not the server, and unmounting on it would conclude Felix was right
# to ignore something because Felix ignored it.
#
# The memo asked for "reached beside needed", and the two halves come from
# different sources because the ledger does not know what is an MCP server.
# A reach signal carries the kind (`mcp__server__tool`); a play name carries
# none, and the rollup records a named-never-reached entry with the literal
# kind `named`. So the unmount side reads the kind-agnostic summary and lets
# stack.tsv supply the kind — a kind-filtered read would miss exactly the
# rows the rule is about — while the mount side reads the mcp record alone,
# because a reach is the one signal that both proves the server exists and
# says what it is. There is deliberately no mount-on-play-named: for an
# undeclared server the play cannot know it names a server at all, and
# historical named rows outliving a deleted declaration would have proposed
# re-mounting forever on the strength of Felix's own routing priors, which
# is the confounded direction the ledger header forbids. Both decided on
# construction, not argument.
#
# Needs ledger.sh sourced beside this file, as the CLI and both session hooks
# already do. Emits: action <TAB> name <TAB> evidence
felix_stack_reconcile() {
  local proj="$1" name sessions calls named declared plugins
  declared="$(_felix_stack_rows "$proj" \
    | awk -F'\t' '$1 == "mcp" { n = $2; sub(/@.*/, "", n); print n }')"

  # The plugin declarations, for the mount side alone.
  #
  # A plugin can ship an MCP server, and the ledger records that server's
  # reaches under the plugin's own name — felix_ledger_mcp folds
  # `plugin_<plugin>_<server>` down to `<plugin>`. So a project that declares
  # a plugin row and reaches for the server that plugin provides was being told
  # "no row declares it", because `declared` above reads kind `mcp` and nothing
  # else. One governed project carried exactly that: the same capability on the
  # mount list for hundreds of reaches and on the retire list for zero
  # invocations, at the same time.
  #
  # Not shared with the unmount loop. That loop proposes only for declared
  # rows, and widening its set to plugins would have it propose unmounting
  # every plugin felix_ledger_retire already proposes retiring — the same
  # finding twice, in two vocabularies, from one table.
  plugins="$(_felix_stack_rows "$proj" \
    | awk -F'\t' '$1 == "plugin" { n = $2; sub(/@.*/, "", n); print n }')"
  felix_ledger_summary "$proj" | while IFS=$'\t' read -r name sessions calls named; do
    [ -n "${name:-}" ] || continue
    felix_has_line "$declared" "$name" || continue
    [ "${calls:-0}" -eq 0 ] 2>/dev/null || continue
    [ "${named:-0}" -gt 0 ] 2>/dev/null || continue
    [ "${sessions:-0}" -ge "${FELIX_LEDGER_MIN:-5}" ] 2>/dev/null || continue
    printf 'unmount\t%s\tnamed %s time(s) across %s session(s), never reached\n' \
      "$name" "$named" "$sessions"
  done
  felix_ledger_mcp "$proj" | while IFS=$'\t' read -r name sessions calls named; do
    [ -n "${name:-}" ] || continue
    felix_has_line "$declared" "$name" && continue
    [ "${calls:-0}" -gt 0 ] 2>/dev/null || continue

    # A name the registry knows is a plugin, not a server anyone adds with
    # `claude mcp add`. Declared as a plugin, there is nothing to propose;
    # undeclared, the row to add is a plugin row, and saying `mcp` would send
    # a person to write a declaration that cannot match what is recorded.
    if [ -n "$(felix_registry_field "$name" installPath 2>/dev/null)" ]; then
      felix_has_line "$plugins" "$name" && continue
      printf 'declare\t%s\treached %s time(s) across %s session(s); a plugin provides it and no row declares that plugin\n' \
        "$name" "$calls" "$sessions"
      continue
    fi

    printf 'mount\t%s\treached %s time(s) across %s session(s), and no row declares it\n' \
      "$name" "$calls" "$sessions"
  done
}

_felix_reconcile_state() { printf '%s/state/reconcile/%s' "$2" "$(basename "$1")"; }

# Proposals not yet shown at a session boundary. The same shape as
# felix_discover_unseen, for the same reason: a proposal a person has already
# seen and left unacted is an answer, and re-rendering it every session is how
# a signal becomes wallpaper — a host-provided server that should never be a
# row would otherwise nag forever. `felix stack reconcile` stays ungated; this
# gates only what session-start volunteers.
felix_stack_reconcile_unseen() {
  local proj="$1" home="$2" seen act name ev
  seen="$(_felix_reconcile_state "$proj" "$home").seen"
  felix_stack_reconcile "$proj" | while IFS=$'\t' read -r act name ev; do
    [ -n "${act:-}" ] || continue
    [ -f "$seen" ] && grep -qxF "$act:$name" "$seen" 2>/dev/null && continue
    printf '%s\t%s\t%s\n' "$act" "$name" "$ev"
  done
}

# Mark proposals as shown. With no third argument, all of them; with one, only
# the actions whose kind matches that regex.
#
# The filter exists because "shown once and never again" is only safe for a
# proposal a later fold cannot overturn. A mount and a declare are proposed
# from a reach — calls above zero, which no amount of further folding takes
# away. An unmount is proposed from calls at zero, and that is exactly what an
# unfolded session's reaches would falsify. Marking one of those seen over a
# partial ledger suppresses it permanently, and the thing suppressed is a
# proposal that may have been wrong when it was made.
felix_stack_reconcile_mark_seen() {
  local proj="$1" home="$2" only="${3:-}" base
  base="$(_felix_reconcile_state "$proj" "$home")"
  mkdir -p "$(dirname "$base")" 2>/dev/null || return 0
  felix_stack_reconcile "$proj" \
    | { if [ -n "$only" ]; then LC_ALL=C awk -F'\t' -v a="$only" '$1 ~ a'; else cat; fi; } \
    | cut -f1-2 | tr '\t' ':' >> "$base.seen" 2>/dev/null
  LC_ALL=C sort -u -o "$base.seen" "$base.seen" 2>/dev/null
  return 0
}

# Install one row. Returns non-zero on failure so the caller can report honestly.
felix_stack_install() {
  local kind="$1" name="$2" source="$3"
  case "$kind" in
    marketplace)
      claude plugin marketplace add "$source" >/dev/null 2>&1 ;;
    plugin)
      claude plugin install "$name" --scope user >/dev/null 2>&1 ;;
    mcp)
      case "$source" in
        http*) claude mcp add --transport http "$name" "$source" >/dev/null 2>&1 ;;
        *)     # shellcheck disable=SC2086
               claude mcp add "$name" -- $source >/dev/null 2>&1 ;;
      esac ;;
    *) return 1 ;;
  esac
}
