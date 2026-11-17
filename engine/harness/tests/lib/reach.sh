# tests/lib/reach.sh: the reach fixture, its helpers, and the builder that gives parts 1100-1120 the same state.
# Used by 1100 (builds it), 1110 and 1120; 1130 finds _rx_base_ok here (it asks command -v first).
# Moved from parts/1100-declared-tools-reach-the-pulse-and-felix-status.sh: lines 13-28 (_rx_chain_private,
# _rx_base_ok), 87-132 (_rx_env to _rx_field), 248 (_rx_rows), 251-252 (_rx_pick), 606-611 (_rx_st) and
# 723-724 (_rx_rec), verbatim; and the fixture code, now in _rx_build: lines 29-86 and 134-208 (step base),
# 603-605 (step status), 730-731 (step gate-green).
# Definitions only. _rx_build <base|status|gate-green> [<part tag>] is guarded step by step: the base step
# runs only when there is no fixture directory, the status step only when the launch table is not there,
# the gate-green step only when reachy has no probes.tsv. In the serial run 1100 makes each of them and
# 1110 and 1120 find all of them, so the state those two see is the one 1100 left. A part that makes the
# base itself is its owner (RX_OWNER is its tag), and _rx_cleanup <tag> removes it, and a base made outside
# $TMP, only for the owner. 1100 gives no tag: 1110 and 1120 need what it makes.

# Changed in review (part 1120): the reach read refuses a TMPDIR that others could write into or sit above (R13), and a .mcp.json above it. So the fixtures need a base whose every ancestor is root's or the user's and writable by neither group nor others, and which has no .mcp.json from there up to / (this machine's HOME has one). $TMP is such a base on macOS (/var/folders/.../T). A Linux runner's is under /tmp, which is world-writable; there the fixtures live under the first of XDG_RUNTIME_DIR, RUNNER_TEMP and HOME that qualifies, for the length of parts 1100 to 1120, and part 1120 removes them. The chain is checked with perl, not with the engine's own test.
_rx_chain_private() {   # <dir>: 0 when it and every ancestor is owned by root or this user with no group or other write bit
  perl -e 'use Cwd qw(abs_path); my $d = abs_path($ARGV[0]); exit 1 unless defined $d && -d $d;
           while (1) { my @s = stat($d) or exit 1; exit 1 unless $s[4] == 0 || $s[4] == $<; exit 1 if $s[2] & 022;
                       last if $d eq "/"; $d =~ s{/[^/]*$}{}; $d = "/" if $d eq ""; } exit 0' "$1" 2>/dev/null
}
_rx_base_ok() {   # <dir>: a private chain and no .mcp.json from it up to /
  local d
  [ -d "$1" ] && _rx_chain_private "$1" || return 1
  d="$(cd "$1" && pwd -P)"
  while :; do
    [ -e "$d/.mcp.json" ] && return 1
    [ -n "$d" ] || return 0
    d="${d%/*}"
  done
}

# Every command runs through this: the fixture's HOME and home, the stubs first
# on PATH, CLAUDE_CONFIG_DIR and FELIX_JQ unset unless a test sets them.
_rx_env() {
  env -u CLAUDE_CONFIG_DIR -u FELIX_JQ HOME="${RX_HOMEOVR:-$RXHOME}" FELIX_HOME="${RX_FH:-$RXH}" \
      FELIX_HOME_DIR="${RX_FH:-$RXH}" FELIX_MEMORY="$RXMEM" FELIX_PLUGIN_CACHE="$RXPC" TMPDIR="$RXT" \
      PATH="${RX_PATH:-$RXB:$PATH}" RX_LOG="$RXLOG" RX_LIST="${RX_LIST-$RXLA}" RX_RC="${RX_RC:-0}" \
      RX_SLEEP="${RX_SLEEP:-}" RX_PLUGINS="${RX_PLUGINS:-}" "$@"
}
# One lib under /bin/bash, sourced alone after resolve.sh (the house pattern
# says each new lib sources what it needs), then the code given.
_rxl() {
  _rx_env /bin/bash -c '. "$1/lib/resolve.sh" && . "$1/lib/$2.sh" || exit 97; eval "$3"' \
    rxl "$FROOT/harness" "$1" "$2" 2>/dev/null
}
_rx_now() { date +%s; }
_rx_ms() { perl -MTime::HiRes=time -e 'printf "%d\n", time * 1000'; }
_rx_ago() { local e=$(( $(date +%s) - $1 )); date -r "$e" +%Y%m%d%H%M.%S 2>/dev/null || date -d "@$e" +%Y%m%d%H%M.%S; }
_rx_utc() { date -u -r "$1" +%Y-%m-%dT%H:%MZ 2>/dev/null || date -u -d "@$1" +%Y-%m-%dT%H:%MZ; }
_rx_wait() {   # <seconds> <test>: poll five times a second until the test holds
  local i=0 n=$(( $1 * 5 ))
  while [ "$i" -lt "$n" ]; do eval "$2" && return 0; sleep 0.2; i=$((i+1)); done
  eval "$2"
}
_rx_mcpn() { grep -c '^mcp list$' "$RXLOG"; }
_rx_cache() { printf '%s' "$RXH/state/reach/$1.tsv"; }
_rx_put() {   # <project> <epoch> <cwd> <rows file>: a cache written by hand
  mkdir -p "$RXH/state/reach"
  { printf '# read %s %s\n' "$2" "$3"; cat "$4"; } > "$(_rx_cache "$1")"
}
_rx_age() {   # <project> <epoch>: the header's epoch set, the rest kept
  local c; c="$(_rx_cache "$1")"
  sed "1s/^# read [0-9][0-9]* /# read $2 /" "$c" > "$c.rxtmp" && mv -f "$c.rxtmp" "$c"
}
_rx_proj() {
  mkdir -p "$RXH/projects/$1"
  printf '{"name": "%s", "remote_match": "example.com/%s", "gate": "true"}\n' "$1" "$1" > "$RXH/projects/$1/project.json"
  printf '# %s\n' "$1" > "$RXH/projects/$1/CLAUDE.md"
}
_rx_checkout() {   # <dir> <project>
  mkdir -p "$1"
  ( _fx_cd "$1" && git init -q -b main && printf '%s\n' "$2" > .felix && printf 'x\n' > f.txt \
    && git add -A && git -c user.name=t -c user.email=t@t commit -qm base ) >/dev/null 2>&1
}
# has(), without printing a haystack that may be a whole file.
_rx_has() { case "$2" in *"$3"*) ok "$1" ;; *) bad "$1" "lacks [$3]" ;; esac; }
_rx_field() { printf '%s\n' "$1" | awk -F'\t' -v r="$2" '$1 == r'; }

_rx_rows() { _rxl reach "felix_reach_read >/dev/null; felix_reach_rows '$RXH/projects/$1'"; }

# Harness mistake in the blind part: "$3" is unbound under set -u when this is called with two arguments, which killed every substitution that used it; defaulted to empty.
_rx_pick() { printf '%s\n' "$1" | awk -F'\t' -v n="$2" -v s="${3:-}" '$3 == n && (s == "" || $4 == s)'; }

_rx_st() {   # <dir> [args]: felix status from there, launchctl and uname stubbed
  local d="$1"; shift
  ( cd "$d" && RX_PATH="$RXU:$RXB:$PATH" _rx_env UNAME_STUB="${UNAME_STUB_RX:-Darwin}" \
      RX_LAUNCH="${RX_LAUNCH:-$RXLT}" RX_LAUNCH_RC="${RX_LAUNCH_RC:-0}" FELIX_JQ="${RX_JQ:-}" \
      "$FELIX" status "$@" 2>"$RX/err" )
}

_rx_rec() { ( cd "$RXC" && . "$FROOT/harness/lib/verify.sh"
              felix_verify_record "$RXC" "$RXH" "$1" "gate.sh" "$(felix_tree_id "$RXC" "$RXH")" ) >/dev/null 2>&1; }

_rx_build() {   # base|status|gate-green [<part tag>]: the fixture, up to that state; steps done are skipped
  local want="${1:-base}"
  if [ -z "${RX:-}" ] || [ ! -x "${RX:-/nonexistent}/bin/claude" ]; then
    RX_OWNER="${2:-}"
    RXBASE=""
    for _rxc in "$TMP" "${XDG_RUNTIME_DIR:-}" "${RUNNER_TEMP:-}" "${HOME:-}"; do
      [ -n "$_rxc" ] && _rx_base_ok "$_rxc" || continue
      if [ "$_rxc" = "$TMP" ]; then RXBASE="$TMP"; else RXBASE="$(mktemp -d "$_rxc/.felix-suite-rx.XXXXXX" 2>/dev/null)" || RXBASE=""; fi
      [ -n "$RXBASE" ] && break
    done
    [ -n "$RXBASE" ] || RXBASE="$TMP"
    # A base outside $TMP is a root of the fixture guard (part 0002), or its git lines are refused. RX_ROOTS0 is what the roots were before it: the part that removes the base puts them back (contract D, R17).
    RX_ROOTS0="$_fx_roots"; _fx_root_add "$RXBASE"
    RX="$(mktemp -d "$RXBASE/rx.XXXXXX")"; RX="$(cd "$RX" && pwd -P)"
    RXH="$RX/home"; RXHOME="$RX/user"; RXB="$RX/bin"; RXU="$RX/ubin"; RXPC="$RX/cache"
    RXMEM="$RX/memory"; RXLOG="$RX/claude.log"; RXLA="$RX/list-a"; RXPLAIN="$RX/plain"
    RXT="$RX/tmp"
    mkdir -p "$RXH/projects" "$RXH/state" "$RXHOME/.claude" "$RXB" "$RXU" "$RXPC" "$RXMEM" "$RXPLAIN" "$RX/jq" "$RXT"
    chmod 700 "$RXT"
    : > "$RXLOG"
    printf '{"enabledPlugins":{"felix@felix":true}}\n' > "$RXHOME/.claude/settings.json"

    # A claude that logs every argument line, answers `mcp list` from a file with
    # an exit status the test chooses (after a sleep, if asked), says something on
    # stderr that must never surface, and refuses every shape it was not taught.
    cat > "$RXB/claude" <<'RXCLAUDESTUB'
#!/bin/bash
printf '%s\n' "$*" >> "${RX_LOG:-/dev/null}"
case "$*" in
  "mcp list")
    printf 'RX-STDERR-NOISE\n' >&2
    if [ -n "${RX_SLEEP:-}" ]; then sleep "$RX_SLEEP"; fi
    if [ -n "${RX_LIST:-}" ]; then cat "$RX_LIST"; fi
    exit "${RX_RC:-0}" ;;
  "plugin list") if [ -n "${RX_PLUGINS:-}" ]; then printf '  > %s\n    Status: enabled\n' "$RX_PLUGINS"; fi; exit 0 ;;
  "plugin marketplace list") exit 0 ;;
  *) printf 'stub: untaught shape: %s\n' "$*" >&2; exit 2 ;;
esac
RXCLAUDESTUB
    cat > "$RXU/launchctl" <<'RXLAUNCHSTUB'
#!/bin/bash
case "${1:-}" in list) if [ -n "${RX_LAUNCH:-}" ]; then cat "$RX_LAUNCH"; fi; exit "${RX_LAUNCH_RC:-0}" ;; esac
exit 0
RXLAUNCHSTUB
    printf '#!/bin/bash\nprintf "%%s\\n" "${UNAME_STUB:-Darwin}"\n' > "$RXU/uname"
    printf '#!/bin/bash\nexit 0\n' > "$RX/jq/jq-empty"
    printf '#!/bin/bash\nprintf "banana\\n"\n' > "$RX/jq/jq-banana"
    printf '#!/bin/bash\nprintf "ok\\n"\nexit 1\n' > "$RX/jq/jq-okfail"
    chmod +x "$RXB/claude" "$RXU/launchctl" "$RXU/uname" "$RX/jq/"*

    # LIST-A, verbatim from the spec.
    cat > "$RXLA" <<'RXLISTA'
Checking MCP server health…

plugin:ctx:ctx: https://mcp.example/mcp?client=claude&key=SECRET (HTTP) - ✔ Connected
plugin:gh:gh: https://api.example/mcp/ (HTTP) - ✘ Failed to connect — HTTP 400: bad request
plugin:cf:cf-api: https://cf.example/mcp (HTTP) - ! Needs authentication
plugin:cf:cf-docs: https://docs.cf.example/mcp (HTTP) - ✔ Connected
plugin:dd:mcp: https://not-setup/v1/mcp?referrer=x (HTTP) - ✘ Failed to connect — ENOTFOUND: TypeError dialing https://not-setup[redacted]?k=REDACTED (ENOTFOUND)
sentry: https://mcp.sentry.example/mcp (HTTP) - ✔ Connected
RXLISTA

    # reachy: the spec's R4 project. A marketplace row and a skill row emit
    # nothing; gone@m names a capability nobody declared, so it is dormant (D7).
    _rx_proj reachy
    { printf 'marketplace\tm\thttps://example.invalid/m\tlow\talways\n'
      for _p in ctx gh cf dd quiet; do printf 'plugin\t%s@m\t-\tlow\talways\n' "$_p"; done
      printf 'plugin\tgone@m\t-\tlow\tnot-a-declared-capability\n'
      printf 'plugin\tlost@m\t-\tlow\talways\n'
      printf 'skill\tsome-skill\t-\tlow\talways\n'
    } > "$RXH/projects/reachy/stack.tsv"
    mkdir -p "$RXPC/m/quiet/1.0.0" "$RXPC/m/lost/1.0.0"
    printf '{"lost": {"command": "npx", "args": ["lost"]}}\n' > "$RXPC/m/lost/1.0.0/.mcp.json"
    RXC="$RX/reachy-checkout"; _rx_checkout "$RXC" reachy; RXC="$(cd "$RXC" && pwd -P)"
    RXR4="$RX/rows-r4"
    printf '%s\t%s\t%s\t%s\t%s\n' \
      connected plugin ctx@m plugin:ctx:ctx 'Connected' \
      failed plugin gh@m plugin:gh:gh 'Failed to connect — HTTP 400: bad request' \
      needs-auth plugin cf@m plugin:cf:cf-api 'Needs authentication' \
      connected plugin cf@m plugin:cf:cf-docs 'Connected' \
      failed plugin dd@m plugin:dd:mcp 'Failed to connect — ENOTFOUND: TypeError dialing https://not-setup[redacted]' \
      no-server plugin quiet@m - 'the plugin declares no MCP server; its reach is its install, which felix stack plan reports' \
      unknown plugin gone@m - 'no installed directory for gone, so whether it ships an MCP server is not known' \
      not-listed plugin lost@m - 'the plugin declares an MCP server and no line of claude mcp list names one' \
      > "$RXR4"
    RXR4U="$RX/rows-r4-unread"
    for _p in ctx gh cf dd quiet gone lost; do
      printf 'unknown\tplugin\t%s@m\t-\tclaude mcp list exited 1\n' "$_p"
    done > "$RXR4U"

    # mcpy: mcp rows beside one plugin row.
    _rx_proj mcpy
    { printf 'plugin\tcf@m\t-\tlow\talways\n'
      printf 'mcp\tsentry\thttps://mcp.sentry.example/mcp\tlow\talways\n'
      printf 'mcp\tcf-api\thttps://cf.example/mcp\tlow\talways\n'
      printf 'mcp\tnothere\thttps://nothere.example/mcp\tlow\talways\n'
    } > "$RXH/projects/mcpy/stack.tsv"
    RXM="$RX/mcpy-checkout"; _rx_checkout "$RXM" mcpy; RXM="$(cd "$RXM" && pwd -P)"
    # Changed in review (part 1120): the list is read from an empty directory, where a project-scoped server is not listed, so an mcp row it does not name is unknown and not not-listed (R6, D19).
    RXR6="$RX/rows-r6"
    printf '%s\t%s\t%s\t%s\t%s\n' \
      needs-auth plugin cf@m plugin:cf:cf-api 'Needs authentication' \
      connected plugin cf@m plugin:cf:cf-docs 'Connected' \
      connected mcp sentry sentry 'Connected' \
      needs-auth mcp cf-api plugin:cf:cf-api 'Needs authentication' \
      unknown mcp nothere - 'no line of claude mcp list names this server; a project-scoped server is not started by Felix, so whether it connects is not known' \
      > "$RXR6"

    # bare: rows the stack does not hold only. nostack: no stack.tsv at all.
    _rx_proj bare
    printf 'marketplace\tm\thttps://example.invalid/m\tlow\talways\nskill\tsome-skill\t-\tlow\talways\n' \
      > "$RXH/projects/bare/stack.tsv"
    RXN="$RX/bare-checkout"; _rx_checkout "$RXN" bare; RXN="$(cd "$RXN" && pwd -P)"
    _rx_proj nostack

    # shapes: the three manifest shapes of section 0, and two that declare nothing.
    _rx_proj shapes
    for _p in wrapped top pj emptyj authorurl; do
      printf 'plugin\t%s@m\t-\tlow\talways\n' "$_p"; mkdir -p "$RXPC/m/$_p/2.0.0/.claude-plugin"
    done > "$RXH/projects/shapes/stack.tsv"
    printf '{"mcpServers": {"w": {"command": "node", "args": ["s.js"]}}}\n' > "$RXPC/m/wrapped/2.0.0/.mcp.json"
    printf '{"t": {"type": "http", "url": "https://t.example/mcp"}}\n'      > "$RXPC/m/top/2.0.0/.mcp.json"
    printf '{"name": "pj", "mcpServers": "./.dd_claude-code_mcp.json"}\n'  > "$RXPC/m/pj/2.0.0/.claude-plugin/plugin.json"
    printf '{}\n'                                                          > "$RXPC/m/emptyj/2.0.0/.mcp.json"
    printf '{"name": "authorurl", "author": {"url": "https://a.example"}}\n' > "$RXPC/m/authorurl/2.0.0/.claude-plugin/plugin.json"

    # oddy: a prose line, a status phrase nobody knows, a tab and a CR in an error.
    _rx_proj oddy
    printf 'plugin\tctx@m\t-\tlow\talways\nplugin\tod@m\t-\tlow\talways\nplugin\ttb@m\t-\tlow\talways\n' \
      > "$RXH/projects/oddy/stack.tsv"
    RXLO="$RX/list-odd"
    { printf 'Checking MCP server health\342\200\246\n\n'
      printf 'Note on plugin:ctx:ctx: https://evil.example - \342\234\230 Failed to connect\n'
      printf 'plugin:ctx:ctx: https://mcp.example/mcp (HTTP) - \342\234\224 Connected\n'
      printf 'plugin:od:od: https://o.example/x?tok=SECRET (HTTP) - ~ Starting?tok=SECRET\n'
      printf 'plugin:tb:tb: https://t.example/mcp (HTTP) - \342\234\230 Failed to connect \342\200\224 a\tb\rc\n'
    } > "$RXLO"
  fi
  case "$want" in status|gate-green)
    if [ ! -f "${RXLT:-/nonexistent}" ]; then
      RXLT="$RX/launch-table"
      printf 'PID\tStatus\tLabel\n-\t0\tcom.example.other\n-\t0\tfelix.pulse\n' > "$RXLT"
      mkdir -p "$RXHOME/Library/LaunchAgents"; printf '<plist/>\n' > "$RXHOME/Library/LaunchAgents/felix.pulse.plist"
    fi ;;
  esac
  case "$want" in gate-green)
    if [ ! -f "$RXH/projects/reachy/probes.tsv" ]; then
      printf 'marker\t-\t-\tls -1 .felix\ttest -f .felix\n' > "$RXH/projects/reachy/probes.tsv"
      _rx_rec 0
    fi ;;
  esac
  return 0
}

_rx_cleanup() {   # <part tag>: take away what this part's _rx_build made, and nothing a later part needs
  [ -n "${1:-}" ] && [ "${RX_OWNER:-}" = "$1" ] || return 0
  [ -n "${RXBASE:-}" ] && [ "$RXBASE" != "$TMP" ] && { _fx_root_del "$RXBASE"; rm -rf "$RXBASE"; }
  [ -n "${RX:-}" ] && rm -rf "${RX:?}"
  RX_OWNER=""
  return 0
}
