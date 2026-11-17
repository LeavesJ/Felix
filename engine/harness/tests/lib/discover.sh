# tests/lib/discover.sh: reading a plugin before recommending it.
# Used by 0290 (builds the fixtures), 0310 (_tier), 0320 (_tier and DF, which it
# adds more plugins under) and 0380 (_dstamp). Moved from
# parts/0290-noticing-when-another-plugin-breaks-the-sess.sh: _dstamp from line
# 110 and _tier from lines 254-255 (both verbatim), and the fixtures from lines
# 247-252 (verbatim, in the function body below).
# Definitions only. _discover_fixtures_build sets DF first and does nothing more
# once the last plugin it makes is there, so in the serial run only 0290's call
# builds. It makes only the five plugins 0290 reads; 0320 makes its own beside them.
# _discover_quiesce, added 2026-10-28, is used by 0290.

# Every fixture cache carries the stamp a real one does, or the readers treat
# it as absent.
_dstamp() { ( . "$FROOT/harness/lib/discover.sh"; _felix_discover_stamp_line "$FROOT/harness/templates" ); }

_tier() { ( . "$FROOT/harness/lib/discover.sh"
            felix_discover_risk "$(felix_discover_inspect "$1")" ); }

# _discover_fixtures_build: five plugins, one for each tier a reading can give.
_discover_fixtures_build() {
  DF="$TMP/discover-fixtures"
  [ -f "$DF/creds/.mcp.json" ] && return 0
  mkdir -p "$DF/skillsonly/skills/a" "$DF/hooky/hooks" "$DF/mcplocal" "$DF/floaty" "$DF/creds"
  printf '{"mcpServers":{"x":{"command":"/usr/local/bin/x","args":["run"]}}}\n' > "$DF/mcplocal/.mcp.json"
  printf '{"hooks":{"PreToolUse":[{"hooks":[{"command":"bash s.sh"}]}]}}\n'     > "$DF/hooky/hooks/hooks.json"
  printf '{"mcpServers":{"x":{"command":"npx","args":["pkg@latest"]}}}\n'       > "$DF/floaty/.mcp.json"
  printf '{"mcpServers":{"x":{"type":"http","url":"https://e.example","headers":{"Authorization":"${SECRET_TOKEN}"}}}}\n' > "$DF/creds/.mcp.json"
}

# _discover_quiesce [home [seconds]]: 0 once no discovery refresh is running under <home> (the
# fixture home by default), 1 if one still is after <seconds> (300). A refresh a hook forked holds
# <home>/state/discover/.lock from before the fork until after it has written the cache
# (felix_discover_refresh_bg), so with the lock gone every refresh an earlier block started has
# finished, and none can write again until a hook starts another. Nothing waits for a hook's child,
# so nothing else says it is done: a block that forks one on purpose calls this to wait for it, and
# the lock and not a sleep because a refresh takes as long as the machine does.
_discover_quiesce() {
  local lock="${1:-$FROOT}/state/discover/.lock" i=0 n=$(( ${2:-300} * 10 ))
  while [ -d "$lock" ] && [ "$i" -lt "$n" ]; do sleep 0.1; i=$((i+1)); done
  [ ! -d "$lock" ]
}
