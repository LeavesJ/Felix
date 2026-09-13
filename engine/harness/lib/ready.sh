# Is every tool this project names actually usable in a session?
#
# The router can point at a skill mid-turn and the agent will invoke it, which
# is the whole reason routing works at all. What cannot happen mid-turn is
# enabling a plugin that is switched off, or connecting an MCP server: Claude
# Code says "Restart to apply changes" and means it.
#
# So availability is decided before the session starts, and a project's needs
# are not the same as the next project's. One project routes to a browser
# tester and a design critic; another routes to a database plugin it alone
# declares. A tool that is installed but disabled looks identical to a tool that
# is present, right up until the turn where it is needed and silently is not.
#
# This is the pre-flight. It reads every play in routes.tsv and every row in
# stack.tsv, and reports each named tool as usable, disabled, or absent.

# Everything usable on this machine, from every source, because no single source
# knows them all.
#
# `claude plugin list` reports 15 here and misses 14 more. Plugins bundled into
# the Claude Code binary — legal, data, design, marketing, operations and the
# rest — appear in no plugin list, in no marketplace directory, and in
# installed_plugins.json not at all. Their skills are nonetheless live in every
# session. A capability router that cannot see half the toolbox is not routing.
#
# So this unions four sources and deduplicates, and each is optional. On a
# machine with no claude CLI, the on-disk registry still answers. On a machine
# where the config has moved, the CLI still answers. This has to work on
# somebody else's laptop, laid out however they left it, not only on the one it
# was written on.
#
# MCP servers are deliberately absent. They are fixed at session start and
# cannot be reached for on demand, so listing them would invite routes to name
# something the router can never make happen.
felix_ready_inventory() {
  local d cfg="$HOME/.claude.json"
  {
    # 1. the CLI, which alone knows what is switched on
    if command -v claude >/dev/null 2>&1; then
      claude plugin list --json 2>/dev/null \
        | sed -n -e 's/.*"id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/ID \1/p' \
                 -e 's/.*"enabled"[[:space:]]*:[[:space:]]*\([a-z]*\).*/EN \1/p' \
        | awk '/^ID /{id=$2} /^EN /{ if ($2=="true") { sub(/@.*/,"",id); print "plugin\t" id } }'
    fi

    # 2. the on-disk registry, for when the CLI is absent
    sed -n 's/.*"\([A-Za-z0-9._-]*\)@[A-Za-z0-9._-]*"[[:space:]]*:[[:space:]]*\[.*/plugin\t\1/p' \
      "$HOME/.claude/plugins/installed_plugins.json" 2>/dev/null

    # 3. plugins bundled into the binary, recorded nowhere else. Read with a
    #    record separator rather than a line pattern so it survives the config
    #    being pretty-printed, minified, or reordered.
    if [ -f "$cfg" ]; then
      awk 'BEGIN{RS="[,{}]"}
           {gsub(/^[[:space:]]+|[[:space:]]+$/,"")}
           /^"[A-Za-z0-9._-]+@inline":?$/{gsub(/[":]/,""); sub(/@inline/,""); print "plugin\t" $0}' \
        "$cfg" 2>/dev/null
    fi

    # 4. standalone skills, which are directories and belong to no package
    for d in "$HOME"/.claude/skills/*/; do
      [ -d "$d" ] || continue
      d="${d%/}"
      printf 'skill\t%s\n' "${d##*/}"
    done
  } | grep -vE '	[0-9.]+$' | LC_ALL=C sort -u
  # An empty toolbox is a fact, not a failure. `grep -v` returns 1 when it is
  # handed nothing, and under `set -o pipefail` that becomes the function's
  # status — so on a machine with no plugins at all, asking what exists would
  # have looked like the asking itself had broken.
  return 0
}

# What exists here that no route in this project ever reaches for.
#
# The point is not tidiness. A router is only ever as good as the tools its
# table knows about, and a table that names one plugin five times while thirty
# others sit unused is not routing, it is a habit. This is the list that makes
# the habit visible.
felix_ready_unused() {
  local proj="$1" wanted kind name owner
  # sed rather than a case statement, and not for style. bash 3.2 parses the
  # closing paren of a `case` pattern written inside $( ) as the end of the
  # substitution, so `case "$w" in *:*)` fails at runtime with a syntax error
  # about an unexpected newline. It parses cleanly under zsh, which is how it
  # survived a hand-check and died the moment the real CLI ran it.
  wanted="$(
    felix_ready_wanted "$proj" | sed 's/:.*//'
    grep -vE '^[[:space:]]*(#|$)' "$proj/stack.tsv" 2>/dev/null | cut -f2 | sed 's/@.*//'
  )"
  felix_ready_inventory | while IFS=$'\t' read -r kind name; do
    [ -n "$name" ] || continue
    felix_has_line "$wanted" "$name" && continue
    printf '%s\t%s\n' "$kind" "$name"
  done
}

# Every distinct tool this project could reach for, from any route.
felix_ready_wanted() {
  local proj="$1" n k pr pl p
  [ -f "$proj/routes.tsv" ] || return 0
  while IFS=$'\t' read -r n k pr pl; do
    case "$n" in ''|'#'*) continue ;; esac
    [ -n "${pl:-}" ] && [ "$pl" != "-" ] || continue
    for p in $pl; do printf '%s\n' "$p"; done
  done < "$proj/routes.tsv" | LC_ALL=C sort -u
}

# A play entry names a skill; the manifest declares the plugin that owns it.
_felix_ready_owner() {
  case "$1" in *:*) printf '%s' "${1%%:*}" ;; *) printf '%s' "$1" ;; esac
}

# state <TAB> name <TAB> detail
#
# `usable` means installed and switched on. `disabled` is the dangerous one: it
# is installed, so every eyeball check passes, and it contributes nothing.
felix_ready_report() {
  local proj="$1" want owner line id enabled found
  # id and enabled are not adjacent in the object — version and scope sit
  # between them — so a naive "pull both values and pair them" produces nothing
  # at all. Tag each line with which field it is, then pair in awk, which holds
  # the last id it saw. Line-oriented because the CLI pretty-prints, and no jq
  # because the engine may not require a runtime.
  local plugins=""
  if command -v claude >/dev/null 2>&1; then
    plugins="$(claude plugin list --json 2>/dev/null \
      | sed -n -e 's/.*"id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/ID \1/p' \
               -e 's/.*"enabled"[[:space:]]*:[[:space:]]*\([a-z]*\).*/EN \1/p' \
      | awk '/^ID /{id=$2} /^EN /{print id "\t" $2}')"
  fi

  while IFS= read -r want; do
    [ -n "$want" ] || continue
    owner="$(_felix_ready_owner "$want")"

    # Declared in the project's own manifest? A tool nobody declared is a tool
    # nobody agreed to, whatever happens to be installed on this laptop.
    local row kind
    row="$(grep -E "	($want|$owner)(@[^	]*)?	" "$proj/stack.tsv" 2>/dev/null | head -1)"
    if [ -z "$row" ]; then
      printf 'undeclared\t%s\t%s\n' "$want" "named by a route, absent from stack.tsv"
      continue
    fi
    kind="$(printf '%s' "$row" | cut -f1)"

    # A standalone skill is a directory, not a package: there is no plugin to
    # enable and nothing in the plugin list to find. Looking for one there
    # reported a perfectly working skill as missing, which is exactly the kind
    # of false alarm that gets a pre-flight check ignored.
    if [ "$kind" = "skill" ] && [ "$want" = "$owner" ]; then
      if [ -d "$HOME/.claude/skills/$want" ]; then
        printf 'usable\t%s\t%s\n' "$want" "skill, always available"
      else
        printf 'absent\t%s\t%s\n' "$want" "skill directory not present"
      fi
      continue
    fi

    found=""; enabled=""
    while IFS=$'\t' read -r id enabled; do
      case "$id" in "$owner@"*|"$owner") found="$id"; break ;; esac
    done <<EOF
$plugins
EOF

    # Bundled plugins are the reason this second look exists. `claude plugin
    # list` reports what was installed from a marketplace and nothing else, so a
    # plugin compiled into the binary is absent from it while being present, and
    # enabled, and live in every session. felix_ready_inventory already reads
    # the four places a plugin can hide; consulting only the narrow one reported
    # three real tools as missing on every single session, which is exactly the
    # kind of false alarm that teaches somebody to skim a pre-flight check.
    #
    # This sits above the no-CLI row on purpose, and used to sit below it. A
    # bundled plugin needs no CLI to be found — the inventory reads it off disk
    # — so short-circuiting to `unknown` first threw away an answer Felix
    # already had. It only ever showed up where no CLI answers, which is every
    # CI runner and no laptop, so the suite went green on the machine that
    # could not reach the branch.
    if [ -z "$found" ] && felix_ready_inventory 2>/dev/null \
         | grep -qxF "plugin	$owner"; then
      printf 'usable\t%s\t%s\n' "$want" "bundled, live in every session"
      continue
    fi

    # Nothing bundled and no list to consult. `absent` here would be a guess:
    # Felix cannot tell "not installed" from "installed where I cannot look",
    # and a pre-flight check that cries absent is one people learn to skim.
    if [ -z "$plugins" ]; then
      printf 'unknown\t%s\t%s\n' "$want" "no claude CLI here, cannot check"
      continue
    fi

    if [ -z "$found" ]; then
      printf 'absent\t%s\t%s\n' "$want" "not installed"
    elif [ "$enabled" = "true" ]; then
      printf 'usable\t%s\t%s\n' "$want" "$found"
    else
      printf 'disabled\t%s\t%s\n' "$want" "installed but switched off"
    fi
  done <<EOF
$(felix_ready_wanted "$proj")
EOF
}
