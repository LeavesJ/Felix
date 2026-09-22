# The toolbox: everything installed, what it actually is, and whether anything
# can reach it.
#
# Felix could already see the whole toolbox and could already read a candidate
# it had fetched from a marketplace. It could not read a plugin already sitting
# on this machine, which is the one it will actually be asked about. The reading
# machinery needed no change at all — an installed plugin is a directory of the
# same shape a fetched one is — so this is a path resolver and a report, not a
# second analyser.
#
# The point is the last column. `felix ready` has always been able to say that
# forty-six installed plugins are named by no route, and saying it is where it
# stopped. A tool no route names is never reached for and costs context in every
# session anyway, which is exactly the condition the ledger design calls the
# reason to retire something. Naming the gap per plugin, with the capability it
# looks like, is what makes it fixable.

# Where the plugin cache lives. Overridable so the suite can point at a fixture
# rather than at whatever this machine happens to have installed.
FELIX_PLUGIN_CACHE="${FELIX_PLUGIN_CACHE:-$HOME/.claude/plugins/cache}"

# Newest installed directory for a plugin name, empty when it has none.
#
# Plugins bundled into the Claude Code binary are real and reachable and have no
# directory anywhere, so "no path" is a normal answer and never an error.
# Version directories sort with -V so 0.10.0 beats 0.9.0, which plain sort does
# not: the gate's own installed check was once wrong for exactly this reason.
felix_toolbox_path() {
  local name="$1" d
  for d in "$FELIX_PLUGIN_CACHE"/*/"$name"; do
    [ -d "$d" ] || continue
    local newest
    newest="$(ls -d "$d"/*/ 2>/dev/null | sort -V | tail -1)"
    [ -n "$newest" ] && { printf '%s' "${newest%/}"; return 0; }
    printf '%s' "$d"; return 0
  done
  return 1
}

# The tier of an installed copy, read with its marketplace entry. The cache is
# laid out <cache>/<marketplace>/<plugin>/<version>, which is how
# felix_toolbox_path found the copy, so the marketplace is the first name under
# the cache root. An LSP plugin from the official catalogue ships a README and
# nothing else; its server is declared in the entry, and read without it the
# copy tiers `low` on no evidence at all.
felix_toolbox_marketplace() {
  local rel="${1#"$FELIX_PLUGIN_CACHE"/}"
  [ "$rel" != "$1" ] || return 1
  printf '%s' "${rel%%/*}"
}

felix_toolbox_risk() {
  local name="$1" dir="$2" mkt mf=""
  mkt="$(felix_toolbox_marketplace "$dir")" && mf="$(felix_discover_marketplace_file "$mkt")"
  felix_discover_risk "$(felix_discover_inspect "$dir" "" "$mf" "$name")"
}

# Skills a plugin ships, one per line. These are what a route can actually name:
# a play entry is `plugin` or `plugin:skill`, and without the list the second
# form has to be guessed.
felix_toolbox_skills() {
  local dir="$1" d
  [ -d "$dir/skills" ] || return 0
  for d in "$dir"/skills/*/; do
    [ -d "$d" ] || continue
    d="${d%/}"
    printf '%s\n' "${d##*/}"
  done
}

# Which declared capability this plugin looks like.
#
# Delegates to felix_capability_match so an installed plugin and a candidate are
# scored by one rule. They were not, and the comment here used to claim they
# were: this file scored the name alone while discovery scored a marketplace
# blurb, and that disagreement is how two plugins were installed under a
# capability neither has.
#
# The description comes from the plugin's own manifest rather than a listing,
# the skills come from the directory it actually ships — what a thing ships is
# a manifest fact, and the strongest one there is (Decision C, 2026-08-30) —
# and the threshold is discovery's, so "worth reporting" and "worth installing"
# stay the same bar until somebody deliberately makes them different.
felix_toolbox_capability() {
  local name="$1" rules="$2" dir="${3:-}" desc="" skills="" hit
  if [ -n "$dir" ]; then
    desc="$(felix_plugin_description "$dir")"
    skills="$(felix_toolbox_skills "$dir")"
  fi
  hit="$(felix_capability_match "$name" "$desc" "$rules" "$skills")"
  [ "$(printf '%s' "$hit" | cut -f1)" -ge "${FELIX_DISCOVER_MIN:-3}" ] 2>/dev/null || return 0
  printf '%s' "$(printf '%s' "$hit" | cut -f2)"
}

# Does any route already name this plugin, under either play form?
felix_toolbox_routed() {
  local proj="$1" name="$2" plays
  [ -f "$proj/routes.tsv" ] || return 1
  plays="$(grep -vE '^[[:space:]]*(#|$)' "$proj/routes.tsv" | cut -f4 | tr ' ' '\n')"
  printf '%s\n' "$plays" | sed 's/:.*//' | grep -xF "$name" >/dev/null 2>&1
}

# The route a capability belongs to: profiles.tsv maps a profile to capabilities,
# routes.tsv gives each route a profile. Emits route names, one per line.
#
# Empty is a real answer and the useful one. A project can declare a capability
# that no profile covers, and then every tool adopted for that capability is
# unreachable no matter how good it is: the gap is in the tables, not in the
# plugin. Saying which table is missing the row is the whole point.
felix_toolbox_route_for() {
  local proj="$1" want="$2" prof caps name kw pr play
  [ -n "$want" ] || return 0
  [ -f "$proj/profiles.tsv" ] && [ -f "$proj/routes.tsv" ] || return 0
  while IFS=$'\t' read -r prof caps; do
    case "$prof" in ''|'#'*) continue ;; esac
    # Exact capability only. Matching `always` here as a wildcard would send
    # every capability to the core profile and make the report useless by
    # making it always succeed.
    case ",${caps}," in
      *",${want},"*) ;;
      *) continue ;;
    esac
    while IFS=$'\t' read -r name kw pr play; do
      case "$name" in ''|'#'*) continue ;; esac
      [ "${pr:-}" = "$prof" ] && printf '%s\n' "$name"
    done < "$proj/routes.tsv"
  done < "$proj/profiles.tsv"
}

# The reachable-but-unrouted set: installed here, matched to a capability this
# project declares, that capability in a profile a route carries, not high
# risk, and no route naming it yet. This is what `felix toolbox --route`
# wires, extracted so a commissioning check can ask whether anything is left
# without re-deriving the loop. Needs no `claude`: the inventory reads the
# registry files when the cli is absent.
felix_toolbox_unwired() {
  local proj="$1" tpl="${2:-$(dirname "${BASH_SOURCE[0]:-$0}")/../templates}" rules kind name dir risk cap
  rules="$(_felix_discover_rules "$tpl" "$proj")"
  felix_ready_inventory | LC_ALL=C sort -u | while IFS=$'\t' read -r kind name; do
    [ "${kind:-}" = "plugin" ] && [ -n "${name:-}" ] || continue
    felix_toolbox_routed "$proj" "$name" && continue
    dir="$(felix_toolbox_path "$name")" || dir=""
    cap="$(felix_toolbox_capability "$name" "$rules" "$dir")"
    [ -n "$cap" ] || continue
    [ -n "$(felix_toolbox_route_for "$proj" "$cap")" ] || continue
    risk="-"; [ -n "$dir" ] && risk="$(felix_toolbox_risk "$name" "$dir")"
    [ "$risk" = "high" ] && continue
    printf '%s\t%s\n' "$name" "$cap"
  done
  return 0
}
