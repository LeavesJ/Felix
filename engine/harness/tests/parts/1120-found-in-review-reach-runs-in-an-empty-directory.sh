printf '\nfound in review: reach reads the list from an empty directory, and the CLI has one home\n'
# Written by the implementer after the adversarial review of this branch, not
# blind. Two blockers, and the first was shown failing before it was fixed.
#
# The first. `claude mcp list` ran in the checkout: the session's own for the
# SessionStart refresh, the person's cwd for felix stack --reach. Claude Code
# starts a project-scoped server of the directory it is run in once that server
# is approved, or auto-enabled (enableAllProjectMcpServers), so in a checkout
# whose .mcp.json declares a stdio server the refresh could start the
# repository's own command at session start, before the person had looked at
# it; and the founder opens hostile repositories for bounty work. Measured
# 2026-10-12 with the real claude: in a checkout with a project .mcp.json the
# server is listed as "Pending approval" and not started; from an empty
# directory it is not listed at all, whatever CLAUDE_PROJECT_DIR says. So the
# list is read from a fresh empty directory under TMPDIR, removed after, and an
# mcp row that list does not name is unknown (a project-scoped server is not
# started by Felix), never not-listed. The stub below models the case after
# approval: it starts the .mcp.json command of the directory it is run in, and
# its control comes first, so "no marker" cannot pass on a stub that never
# starts anything.
#
# The second. The reviewer ran felix stack --reach with FELIX_HOME_DIR set to a
# scratch directory and the real home's cache was written. FELIX_HOME_DIR is
# not the CLI's override: felix and the hooks assign it from felix_home, which
# reads FELIX_HOME and then the ~/.felix-home pointer. Part 1100's _rx_env sets
# both to one value, so nothing here could have told them apart; these do.
#
# Uses the fixtures part 1100 leaves behind: RXH (the project reachy and its
# stack), RXPC, RXMEM, RXLA (LIST-A), RXR4 (its rows) and the helpers.
_rx_build base 1120
RZ="$(mktemp -d "$RXBASE/rz.XXXXXX")"; RZ="$(cd "$RZ" && pwd -P)"
RZB="$RZ/bin"; RZT="$RZ/tmp"; RZU="$RZ/user"; RZC="$RZ/hostile-checkout"
mkdir -p "$RZB" "$RZT" "$RZU"
RZT="$(cd "$RZT" && pwd -P)"; chmod 700 "$RZT"
cat > "$RZB/claude" <<'RZCLAUDESTUB'
#!/bin/bash
printf '%s\n' "$*" >> "${RZ_ARGLOG:-/dev/null}"
case "$*" in
  "mcp list")
    pwd -P >> "${RZ_PWDLOG:-/dev/null}"
    # Like the real CLI (measured 2026-10-12), it walks up: the nearest .mcp.json from the working directory to / is the one whose server it starts.
    _d="$PWD"
    while :; do
      if [ -f "$_d/.mcp.json" ]; then
        c="$(sed -n 's/.*"command": *"\([^"]*\)".*/\1/p' "$_d/.mcp.json" | head -1)"
        if [ -n "$c" ]; then "$c" >/dev/null 2>&1; fi
        break
      fi
      [ -n "$_d" ] && [ "$_d" != / ] || break
      _d="${_d%/*}"
    done
    if [ -n "${RZ_DROP:-}" ]; then printf 'x\n' > ./dropped-by-claude; pwd -P >> "${RZ_DROPLOG:-/dev/null}"; fi
    if [ -n "${RX_LIST:-}" ]; then cat "$RX_LIST"; fi
    exit "${RX_RC:-0}" ;;
  *) printf 'stub: untaught shape: %s\n' "$*" >&2; exit 2 ;;
esac
RZCLAUDESTUB
chmod +x "$RZB/claude"
for _w in co home; do
  printf '#!/bin/bash\nprintf started > "%s/marker-%s"\n' "$RZ" "$_w" > "$RZ/writer-$_w.sh"
  chmod +x "$RZ/writer-$_w.sh"
done
# A project-scoped server in the checkout, and another in HOME, which is itself a
# repository on the machine this was found on.
_rx_checkout "$RZC" reachy; RZC="$(cd "$RZC" && pwd -P)"
printf '{"mcpServers": {"evil": {"command": "%s/writer-co.sh", "args": []}}}\n' "$RZ" > "$RZC/.mcp.json"
printf '{"mcpServers": {"evil": {"command": "%s/writer-home.sh", "args": []}}}\n' "$RZ" > "$RZU/.mcp.json"

_rz_env() {   # the stub first on PATH, a TMPDIR of its own, the pwd of every list read logged
  RX_PATH="$RZB:$PATH" RX_HOMEOVR="$RZU" _rx_env TMPDIR="${RZ_TMPDIR:-$RZT}" \
    RZ_PWDLOG="$RZ/pwd.log" RZ_ARGLOG="$RZ/args.log" RZ_DROPLOG="$RZ/drop.log" RZ_DROP="${RZ_DROP:-}" "$@"
}
_rz_stk() { ( cd "$1" && shift && _rz_env "$FELIX" stack "$@" 2>"$RZ/err" ); }
_rz_lib() {   # <lib> <code>: one lib under /bin/bash, the stub and the fixture TMPDIR in place
  _rz_env /bin/bash -c '. "$1/lib/resolve.sh" && . "$1/lib/$2.sh" || exit 97; eval "$3"' rzl "$FROOT/harness" "$1" "$2" 2>/dev/null
}
_rz_reset() { : > "$RZ/pwd.log"; : > "$RZ/args.log"; : > "$RZ/drop.log"; rm -f "$RZ/marker-co" "$RZ/marker-home"; }
_rz_n() { wc -l < "$1" 2>/dev/null | tr -d ' '; }
_rz_left() { ls -A "$RZT" 2>/dev/null | wc -l | tr -d ' '; }
_rz_marks() { local m=""; [ -e "$RZ/marker-co" ] && m="$m checkout"; [ -e "$RZ/marker-home" ] && m="$m home"; printf '%s' "$m"; }
_rz_where() {   # <test name> <logged pwd>: under TMPDIR, fresh, and neither the checkout nor HOME
  case "$2" in
    "$RZT"/felix-reach.??????) ok "$1: a fresh felix-reach directory under TMPDIR" ;;
    *) bad "$1: a fresh felix-reach directory under TMPDIR" "ran in [$2]" ;;
  esac
  case "$2" in
    "$RZC"|"$RZC"/*|"$RZU"|"$RZU"/*|"") bad "$1: not the checkout and not HOME" "ran in [$2]" ;;
    *) ok "$1: not the checkout and not HOME" ;;
  esac
}

printf '\nthe control: the stub starts what a project-scoped .mcp.json declares\n'
_rz_reset
( cd "$RZC" && _rz_env "$RZB/claude" mcp list ) >/dev/null 2>&1
is "run in the checkout, the stub starts the checkout's project server" "$(_rz_marks)" " checkout"
_rz_reset
( cd "$RZU" && _rz_env "$RZB/claude" mcp list ) >/dev/null 2>&1
is "run in HOME, it starts HOME's" "$(_rz_marks)" " home"
_rz_reset

printf '\nreach: felix stack --reach reads from an empty directory\n'
_rzo="$(_rz_stk "$RZC" --reach --tsv)"; _rzrc=$?
is  "felix stack --reach --tsv from the hostile checkout still answers R4's rows" "$_rzo" "$(cat "$RXR4")"
is  "and exits 0" "$_rzrc" "0"
is  "and runs claude mcp list once" "$(_rz_n "$RZ/pwd.log")" "1"
_rzp="$(head -1 "$RZ/pwd.log" 2>/dev/null)"
_rz_where "felix stack --reach" "$_rzp"
is  "and it started no project-scoped server, in the checkout or in HOME" "$(_rz_marks)" ""
is  "and the directory it ran in is gone afterwards, so nothing is left in TMPDIR" "$(_rz_left)" "0"
case "$(head -1 "$(_rx_cache reachy)" 2>/dev/null)" in
  "# read "[0-9]*" $_rzp") ok "and the cache header names the directory the read ran in, not the checkout" ;;
  *) bad "and the cache header names the directory the read ran in, not the checkout" "$(head -1 "$(_rx_cache reachy)" 2>/dev/null) against [$_rzp]" ;;
esac

_rz_reset
_rzo="$(RZ_DROP=1 _rz_stk "$RZC" --reach --tsv)"
is  "a list read that leaves a file behind: the stub did drop one, in the directory it ran in" \
    "$(head -1 "$RZ/drop.log" 2>/dev/null)" "$(head -1 "$RZ/pwd.log" 2>/dev/null)"
_rz_where "a list read that leaves a file behind" "$(head -1 "$RZ/drop.log" 2>/dev/null)"
is  "and the directory, file and all, is removed afterwards" "$(_rz_left)" "0"
is  "and the rows are the same" "$_rzo" "$(cat "$RXR4")"
_rz_reset
_rzo="$(RX_RC=1 _rz_stk "$RZC" --reach --tsv)"
is  "a list that fails (exit 1) ran claude once" "$(_rz_n "$RZ/pwd.log")" "1"
_rz_where "a list that fails" "$(head -1 "$RZ/pwd.log" 2>/dev/null)"
is  "and its directory is removed all the same" "$(_rz_left)" "0"

printf '\nreach: felix_reach_read called from anywhere\n'
_rz_reset
is  "called with HOME as the cwd it reads the list" \
    "$(_rz_lib reach "cd '$RZU'; felix_reach_read >/dev/null; printf '%s' \"\$?\"")" "0"
_rz_where "called from HOME" "$(head -1 "$RZ/pwd.log" 2>/dev/null)"
is  "and started no server when called from HOME" "$(_rz_marks)" ""
_rz_reset
_rz_lib reach "cd '$RZC'; felix_reach_read" >/dev/null
_rz_where "called from the checkout" "$(head -1 "$RZ/pwd.log" 2>/dev/null)"
is  "and started no server when called from the checkout" "$(_rz_marks)" ""
_rz_reset
is  "a TMPDIR that cannot make a directory leaves the list unread, and says so" \
    "$(RZ_TMPDIR="$RZ/no-such-tmp" _rz_lib reach 'felix_reach_read >/dev/null; printf "%s|%s" "$?" "$_FELIX_REACH_WHY"')" \
    "1|could not make an empty directory to run claude mcp list in"
is  "and claude was not run, in the checkout or anywhere" "$(_rz_n "$RZ/args.log")" "0"
cp "$(_rx_cache reachy)" "$RZ/cache.keep" 2>/dev/null
_rzo="$(RZ_TMPDIR="$RZ/no-such-tmp" _rz_stk "$RZC" --reach --tsv)"; _rzrc=$?
is  "felix stack --reach with no directory to read from gives one unknown row per plugin row" "$_rzo" \
    "$(for _p in ctx gh cf dd quiet gone lost; do printf 'unknown\tplugin\t%s@m\t-\tcould not make an empty directory to run claude mcp list in\n' "$_p"; done)"
is  "and exits 0" "$_rzrc" "0"
is  "and ran no claude command" "$(_rz_n "$RZ/args.log")" "0"
cmp -s "$RZ/cache.keep" "$(_rx_cache reachy)" && ok "and left the cache as it was" || bad "and left the cache as it was"
# Measured 2026-10-12 with the real claude: run in a subdirectory of a checkout it lists the server of the parent's .mcp.json, so an empty directory under a project is not neutral. A TMPDIR below a .mcp.json (a repository's own tmp, or a planted /tmp/.mcp.json) must leave the list unread.
RZUP="$RZ/under-mcp"; mkdir -p "$RZUP"; chmod 755 "$RZUP"; printf '{"mcpServers": {}}\n' > "$RZUP/.mcp.json"
_rz_reset
is  "a .mcp.json above the scratch directory leaves the list unread, and says why" \
    "$(RZ_TMPDIR="$RZUP" _rz_lib reach 'felix_reach_read >/dev/null; printf "%s|%s" "$?" "$_FELIX_REACH_WHY"')" \
    "1|a .mcp.json sits above the scratch directory, so claude mcp list could start a project-scoped server there"
is  "and claude was not run" "$(_rz_n "$RZ/args.log")" "0"
is  "and the scratch directory it made is gone, the .mcp.json left alone" "$(ls -A "$RZUP" | tr '\n' ' ')" ".mcp.json "
_rzo="$(RZ_TMPDIR="$RZUP" _rz_stk "$RZC" --reach --tsv)"
is  "felix stack --reach under such a TMPDIR gives unknown rows that carry the reason" \
    "$(printf '%s\n' "$_rzo" | awk -F'\t' '{ print $1 "|" $5 }' | sort -u)" \
    "unknown|a .mcp.json sits above the scratch directory, so claude mcp list could start a project-scoped server there"
is  "and ran no claude command" "$(_rz_n "$RZ/args.log")" "0"
rm -f "$RZUP/.mcp.json"
is  "the same TMPDIR without the .mcp.json reads the list (the control)" \
    "$(RZ_TMPDIR="$RZUP" _rz_lib reach 'felix_reach_read >/dev/null; printf "%s" "$?"')" "0"
_rz_reset
_rz_src="$(awk '/^[[:space:]]*#/ { next } /claude mcp list 2>/ { print }' "$FROOT/harness/lib/reach.sh" "$FROOT/harness/lib/reach-read.sh" 2>/dev/null)"
is  "reach.sh and reach-read.sh run claude mcp list in exactly one place" "$(printf '%s\n' "$_rz_src" | grep -c 'claude mcp list 2>')" "1"
_rx_has "and that place changes into the scratch directory first" "$_rz_src" 'cd "'

printf '\nreach: the SessionStart refresh reads from an empty directory\n'
_rz_hook() { ( cd "$RZC" && _rz_env CLAUDE_PLUGIN_ROOT="$FROOT" "$FROOT/harness/hooks/session-start" ) >/dev/null 2>&1; }
_rz_lock="$RXH/state/reach/reachy.lock"
_rx_wait 10 '[ ! -d "$_rz_lock" ]'
rm -f "$(_rx_cache reachy)"; _rz_reset
_rz_hook
_rx_wait 10 '[ -s "$(_rx_cache reachy)" ] && [ ! -d "$_rz_lock" ]' && _rzk=1 || _rzk=0
[ "$_rzk" = 1 ] && ok "with the cache absent a session start in the hostile checkout writes one" \
                || bad "with the cache absent a session start in the hostile checkout writes one" "no cache, or the lock is still held"
_rzp="$(head -1 "$RZ/pwd.log" 2>/dev/null)"
_rz_where "the refresh" "$_rzp"
is  "and it started no project-scoped server, in the checkout or in HOME" "$(_rz_marks)" ""
is  "and nothing is left in TMPDIR" "$(_rz_left)" "0"
case "$(head -1 "$(_rx_cache reachy)" 2>/dev/null)" in
  "# read "[0-9]*" $_rzp") ok "and the cache header names that directory" ;;
  *) bad "and the cache header names that directory" "$(head -1 "$(_rx_cache reachy)" 2>/dev/null)" ;;
esac
rm -f "$(_rx_cache reachy)"; _rz_reset
RZ_TMPDIR="$RZ/no-such-tmp" _rz_hook
_rx_wait 10 '[ ! -d "$_rz_lock" ]'
is  "a refresh that cannot make its directory runs no claude command" "$(_rz_n "$RZ/args.log")" "0"
if [ -e "$(_rx_cache reachy)" ]; then bad "and writes no cache"; else ok "and writes no cache"; fi
is  "and the lock is not left behind" "$([ -d "$_rz_lock" ] && echo held || echo free)" "free"

printf '\nreach: an mcp row the neutral list does not name is unknown\n'
_rzr="$(_rx_rows mcpy)"
_rz_nh() { printf '%s\n' "$_rzr" | awk -F'\t' '$2 == "mcp" && $3 == "nothere"' | cut -f"$1"; }
is  "an mcp row no line of the list names reads unknown" "$(_rz_nh 1)" "unknown"
is  "with no server" "$(_rz_nh 4)" "-"
is  "and a detail that says a project-scoped server is not started by Felix" \
    "$(_rz_nh 5)" "no line of claude mcp list names this server; a project-scoped server is not started by Felix, so whether it connects is not known"
is  "no mcp row ever reads not-listed" "$(printf '%s\n' "$_rzr" | awk -F'\t' '$2 == "mcp" && $1 == "not-listed"' | wc -l | tr -d ' ')" "0"
is  "and none reads failed unless a line says Failed to connect" "$(printf '%s\n' "$_rzr" | awk -F'\t' '$2 == "mcp" && $1 == "failed"' | wc -l | tr -d ' ')" "0"
is  "an mcp row the list does name still reads by its line (sentry connected)" \
    "$(printf '%s\n' "$_rzr" | awk -F'\t' '$2 == "mcp" && $3 == "sentry" { print $1 }')" "connected"
is  "and one a plugin's server answers to still reads by its line (cf-api needs-auth)" \
    "$(printf '%s\n' "$_rzr" | awk -F'\t' '$2 == "mcp" && $3 == "cf-api" { print $1 }')" "needs-auth"
case "$_rzr" in *"?"*) bad "and no row carries a query string" "$_rzr" ;; *) ok "and no row carries a query string" ;; esac
printf '%s\n' "$_rzr" > "$RZ/rows-mcpy"
_rx_put mcpy "$(_rx_now)" "$RZ/x" "$RZ/rows-mcpy"
_rzpl="$(_rxl reach "felix_reach_report '$RXH/projects/mcpy' '$RXH'")"
is  "the pulse names it in a reach-unknown line" \
    "$(printf '%s\n' "$_rzpl" | awk -F'\t' '$1 == "reach-unknown"')" \
    "$(printf 'reach-unknown\tmcpy\t1 declared row(s) whose reach is not known: nothere')"
is  "and not in an unreachable line" "$(printf '%s\n' "$_rzpl" | awk -F'\t' '$1 == "unreachable" && index($3, "nothere")' | wc -l | tr -d ' ')" "0"
rm -f "$(_rx_cache mcpy)"

printf '\nthe CLI has one home: FELIX_HOME, then the pointer, and FELIX_HOME_DIR is assigned from them\n'
RZREAL="$RZ/realhome"; RZSCR="$RZ/scratchhome"; RZP="$RZ/pointer-user"
for _h in "$RZREAL" "$RZSCR"; do
  mkdir -p "$_h/projects/reachy" "$_h/state"
  for _f in project.json CLAUDE.md stack.tsv; do cp "$RXH/projects/reachy/$_f" "$_h/projects/reachy/$_f"; done
done
mkdir -p "$RZP"; printf '%s\n' "$RZREAL" > "$RZP/.felix-home"
_rz_h() {   # no FELIX_HOME and no FELIX_HOME_DIR but what the test passes; the pointer names the real home
  env -u CLAUDE_CONFIG_DIR -u FELIX_JQ -u FELIX_HOME -u FELIX_HOME_DIR HOME="$RZP" FELIX_MEMORY="$RXMEM" \
      FELIX_PLUGIN_CACHE="$RXPC" PATH="$RZB:$PATH" TMPDIR="$RZT" RZ_PWDLOG="$RZ/pwd.log" RZ_ARGLOG="$RZ/args.log" \
      RX_LIST="$RXLA" RX_RC=0 "$@"
}
_rz_has_state() { local h="$1" r="" f; for f in reach/reachy.tsv pulse.status.tsv pulse.log; do [ -e "$h/state/$f" ] && r="$r ${f##*/}"; done; printf '%s' "$r"; }
_rz_clear() { rm -rf "$RZREAL/state" "$RZSCR/state"; mkdir -p "$RZREAL/state" "$RZSCR/state"; }
_rz_hset() { ( cd "$RZC" && _rz_h "$@" 2>/dev/null ); }

_rz_clear; _rz_reset
_rz_hset "$FELIX" stack --reach --tsv >/dev/null
is  "with no override the pointer's home receives the reach cache (the control)" "$(_rz_has_state "$RZREAL")" " reachy.tsv"
is  "and the scratch home receives nothing" "$(_rz_has_state "$RZSCR")" ""
_rz_clear
_rz_hset FELIX_HOME="$RZSCR" "$FELIX" stack --reach --tsv >/dev/null
is  "FELIX_HOME names the home: the scratch home receives the reach cache" "$(_rz_has_state "$RZSCR")" " reachy.tsv"
is  "and the home the pointer names receives nothing" "$(_rz_has_state "$RZREAL")" ""
case "$(head -1 "$RZSCR/state/reach/reachy.tsv" 2>/dev/null)" in "# read "[0-9]*) ok "and the scratch cache has a valid header" ;; *) bad "and the scratch cache has a valid header" ;; esac
_rz_hset FELIX_HOME="$RZSCR" "$FELIX" pulse >/dev/null
is  "the pulse's record and log land beside it, in the scratch home" "$(_rz_has_state "$RZSCR")" " reachy.tsv pulse.status.tsv pulse.log"
is  "and the home the pointer names still has none of them" "$(_rz_has_state "$RZREAL")" ""
_rz_clear; _rz_reset
( cd "$RZC" && _rz_h FELIX_HOME="$RZSCR" CLAUDE_PLUGIN_ROOT="$FROOT" "$FROOT/harness/hooks/session-start" ) >/dev/null 2>&1
_rz_slock="$RZSCR/state/reach/reachy.lock"
_rx_wait 10 '[ -s "$RZSCR/state/reach/reachy.tsv" ] && [ ! -d "$_rz_slock" ]'
is  "the SessionStart refresh writes the scratch home's cache" "$(_rz_has_state "$RZSCR")" " reachy.tsv"
is  "and the home the pointer names receives nothing" "$(_rz_has_state "$RZREAL")" ""
_rz_clear
_rz_hset FELIX_HOME_DIR="$RZSCR" "$FELIX" stack --reach --tsv >/dev/null
is  "FELIX_HOME_DIR alone is not an override: the pointer's home is written (what the review saw)" "$(_rz_has_state "$RZREAL")" " reachy.tsv"
is  "and the directory it named is not" "$(_rz_has_state "$RZSCR")" ""
_rz_clear; _rz_reset

printf '\nreach: the scratch directory is made only under a TMPDIR nobody else can write\n'
# The third blocker, from the security review of the empty-directory fix (MEDIUM,
# toctou). The fix fell back to /tmp when TMPDIR was unset or relative. /tmp is
# shared and world-writable (sticky stops a delete, not a create), so between
# "no .mcp.json in any parent" and `claude mcp list` another local user could
# plant /tmp/.mcp.json, which the CLI reads from a parent, and the refresh would
# start whatever it names. The ancestor check cannot close that: it is a check,
# and the file arrives after it. What closes it is a directory nobody else can
# write into, under parents nobody else can write into: TMPDIR must be absolute,
# owned by the user with no group or other write bit, and every ancestor up to /
# owned by root or the user with neither. Otherwise claude is not run.
# Shown failing first: against the /tmp fallback the unset, empty and relative
# cases READ the list, and the 0777, group-writable, world-writable-parent and
# foreign-owner cases read it too.
RZSB="$RZ/sbin"; mkdir -p "$RZSB"
cat > "$RZSB/stat" <<'RZSTATSTUB'
#!/bin/bash
# stat for the ownership tests. RZ_STATFAIL=1: no form of it works. RZ_FOREIGN=<path>:
# that path belongs to uid 4242, in whichever form was asked. Anything else is the real one.
if [ -n "${RZ_STATFAIL:-}" ]; then exit 1; fi
for _a in "$@"; do _p="$_a"; done
if [ -n "${RZ_FOREIGN:-}" ] && [ "${_p:-}" = "$RZ_FOREIGN" ]; then printf '4242 755\n'; exit 0; fi
for _s in /usr/bin/stat /bin/stat; do [ -x "$_s" ] && exec "$_s" "$@"; done
exit 1
RZSTATSTUB
cat > "$RZSB/ls" <<'RZLSSTUB'
#!/bin/bash
# ls for the fallback tests. RZ_LSJUNK=1: prints something that is no listing.
# RZ_FOREIGN=<path>: that path is listed as belonging to uid 4242. Otherwise the real one.
if [ -n "${RZ_LSJUNK:-}" ]; then printf 'not a listing\n'; exit 0; fi
for _a in "$@"; do _p="$_a"; done
if [ -n "${RZ_FOREIGN:-}" ] && [ "${_p:-}" = "$RZ_FOREIGN" ]; then printf 'drwxr-xr-x  2 4242  20  64 Oct 12 12:00 %s\n' "$_p"; exit 0; fi
for _s in /bin/ls /usr/bin/ls; do [ -x "$_s" ] && exec "$_s" "$@"; done
exit 1
RZLSSTUB
chmod +x "$RZSB/stat" "$RZSB/ls"

# One lib under /bin/bash like _rz_lib, with extra env(1) arguments (-u TMPDIR, TMPDIR=x, PATH=...) and a working directory.
_rz_libenv() {   # <lib> <code> [env arg]...
  local lib="$1" code="$2"; shift 2
  [ -z "${RZ_CWD:-}" ] || cd "$RZ_CWD" || return 1
  _rz_env env "$@" /bin/bash -c '. "$1/lib/resolve.sh" && . "$1/lib/$2.sh" || exit 97; eval "$3"' rzl "$FROOT/harness" "$lib" "$code" 2>/dev/null
}
RZWHY_ABS="TMPDIR is not an absolute path, so there is no private directory to run claude mcp list in"
RZWHY_PRIV="TMPDIR is not a private directory, so claude mcp list was not run: it must be owned by you and writable by no one else, under parents only you or root can write"
_rz_refuses() {   # <name> <why> <env arg>... : the read says no, with that sentence, and claude was never started
  local n="$1" why="$2" got; shift 2
  _rz_reset
  got="$(_rz_libenv reach 'felix_reach_read >/dev/null; printf "%s|%s" "$?" "$_FELIX_REACH_WHY"' "$@")"
  is  "$n: the list is unread, with the sentence that says why" "$got" "1|$why"
  is  "$n: claude was not run" "$(_rz_n "$RZ/args.log")" "0"
}
_rz_reads() {   # <name> <env arg>... : the read is made, and where it ran is a fresh felix-reach directory
  local n="$1" got; shift
  _rz_reset
  got="$(_rz_libenv reach 'felix_reach_read >/dev/null; printf "%s" "$?"' "$@")"
  is  "$n: the list is read" "$got" "0"
  is  "$n: claude ran once" "$(_rz_n "$RZ/args.log")" "1"
}
_rz_mk() {   # <dir> <mode>: a directory, with that mode
  mkdir -p "$1" && chmod "$2" "$1"
}
_rz_mk "$RZ/priv" 700; _rz_mk "$RZ/pub" 755
_rz_mk "$RZ/d777" 777; _rz_mk "$RZ/d770" 770; _rz_mk "$RZ/d707" 707
_rz_mk "$RZ/world" 700; _rz_mk "$RZ/world/priv" 700; chmod 777 "$RZ/world"
_rz_mk "$RZ/grp" 700; _rz_mk "$RZ/grp/priv" 700; chmod 775 "$RZ/grp"
_rz_mk "$RZ/world2" 700; _rz_mk "$RZ/world2/mid" 755; _rz_mk "$RZ/world2/mid/priv" 700; chmod 777 "$RZ/world2"
_rz_mk "$RZ/fgn" 755; _rz_mk "$RZ/fgn/priv" 700

printf '\nthe controls: a private TMPDIR reads\n'
_rz_reads "a 0700 TMPDIR owned by the user" TMPDIR="$RZ/priv"
case "$(head -1 "$RZ/pwd.log" 2>/dev/null)" in "$RZ/priv"/felix-reach.??????) ok "a 0700 TMPDIR: it ran in a fresh felix-reach directory under that TMPDIR" ;; *) bad "a 0700 TMPDIR: it ran in a fresh felix-reach directory under that TMPDIR" "$(head -1 "$RZ/pwd.log" 2>/dev/null)" ;; esac
is  "and its directory is gone afterwards" "$(ls -A "$RZ/priv" | wc -l | tr -d ' ')" "0"
_rz_reads "a 0755 TMPDIR (no group or other write bit)" TMPDIR="$RZ/pub"
ln -s "$RZ/priv" "$RZ/link-priv"
_rz_reads "a symlink to a private directory" TMPDIR="$RZ/link-priv"
case "$(head -1 "$RZ/pwd.log" 2>/dev/null)" in "$RZ/priv"/felix-reach.??????) ok "and it ran in the physical directory, not under the link" ;; *) bad "and it ran in the physical directory, not under the link" "$(head -1 "$RZ/pwd.log" 2>/dev/null)" ;; esac

printf '\nTMPDIR unset, empty or relative: no fallback to /tmp\n'
_rz_refuses "TMPDIR unset" "$RZWHY_ABS" -u TMPDIR
_rz_refuses "TMPDIR empty" "$RZWHY_ABS" TMPDIR=
RZ_CWD="$RZ" _rz_refuses "a relative TMPDIR naming a private directory that exists under the working directory" "$RZWHY_ABS" TMPDIR=priv
RZ_CWD="$RZ" _rz_refuses "a TMPDIR of ." "$RZWHY_ABS" TMPDIR=.
is  "and with the same directory given absolutely the control reads" \
    "$(RZ_CWD="$RZ" _rz_libenv reach 'felix_reach_read >/dev/null; printf "%s" "$?"' TMPDIR="$RZ/priv")" "0"

printf '\na TMPDIR that others can write\n'
_rz_refuses "a 0777 TMPDIR" "$RZWHY_PRIV" TMPDIR="$RZ/d777"
is  "and nothing was made in it" "$(ls -A "$RZ/d777" | wc -l | tr -d ' ')" "0"
_rz_refuses "a 0770 TMPDIR (group write)" "$RZWHY_PRIV" TMPDIR="$RZ/d770"
_rz_refuses "a 0707 TMPDIR (other write)" "$RZWHY_PRIV" TMPDIR="$RZ/d707"
ln -s "$RZ/d777" "$RZ/link-777"
_rz_refuses "a symlink to a 0777 directory" "$RZWHY_PRIV" TMPDIR="$RZ/link-777"
if [ "$(id -u)" != 0 ]; then
  _rz_refuses "a directory the user does not own (/usr)" "$RZWHY_PRIV" TMPDIR=/usr
else
  skip "a directory the user does not own (/usr)" "running as root, which owns it"
fi
_rz_refuses "/ itself" "could not make an empty directory to run claude mcp list in" TMPDIR=/
is  "and nothing named felix-reach was made in /" "$(ls -d /felix-reach.* 2>/dev/null | wc -l | tr -d ' ')" "0"

printf '\na private TMPDIR under a parent that others can write (the planted /tmp/.mcp.json)\n'
_rz_refuses "a 0700 TMPDIR under a world-writable parent" "$RZWHY_PRIV" TMPDIR="$RZ/world/priv"
is  "and nothing was made in it" "$(ls -A "$RZ/world/priv" | wc -l | tr -d ' ')" "0"
printf '{"mcpServers": {"evil": {"command": "%s/writer-home.sh", "args": []}}}\n' "$RZ" > "$RZ/world/.mcp.json"
_rz_refuses "the same with a .mcp.json planted in the parent" "$RZWHY_PRIV" TMPDIR="$RZ/world/priv"
is  "and the planted server was not started" "$(_rz_marks)" ""
rm -f "$RZ/world/.mcp.json"
_rz_refuses "a 0700 TMPDIR under a group-writable parent" "$RZWHY_PRIV" TMPDIR="$RZ/grp/priv"
_rz_refuses "a 0700 TMPDIR under a world-writable grandparent" "$RZWHY_PRIV" TMPDIR="$RZ/world2/mid/priv"
chmod 755 "$RZ/world"
_rz_reads "the control: the same TMPDIR once the parent is 0755" TMPDIR="$RZ/world/priv"
chmod 777 "$RZ/world"
_rz_refuses "and 0777 again" "$RZWHY_PRIV" TMPDIR="$RZ/world/priv"

printf '\nan ancestor owned by someone else\n'
_rz_refuses "a parent owned by another user, by stat" "$RZWHY_PRIV" TMPDIR="$RZ/fgn/priv" PATH="$RZSB:$RZB:$PATH" RZ_FOREIGN="$RZ/fgn"
_rz_reads "the control: the same stub with no foreign path" TMPDIR="$RZ/fgn/priv" PATH="$RZSB:$RZB:$PATH"
_rz_refuses "a parent owned by another user, by ls when stat says nothing" "$RZWHY_PRIV" TMPDIR="$RZ/fgn/priv" PATH="$RZSB:$RZB:$PATH" RZ_STATFAIL=1 RZ_FOREIGN="$RZ/fgn"
_rz_reads "a private TMPDIR still reads by ls when stat says nothing" TMPDIR="$RZ/priv" PATH="$RZSB:$RZB:$PATH" RZ_STATFAIL=1
_rz_refuses "a 0777 TMPDIR is still refused by ls when stat says nothing" "$RZWHY_PRIV" TMPDIR="$RZ/d777" PATH="$RZSB:$RZB:$PATH" RZ_STATFAIL=1
_rz_refuses "a 0770 TMPDIR is still refused by ls when stat says nothing (group write)" "$RZWHY_PRIV" TMPDIR="$RZ/d770" PATH="$RZSB:$RZB:$PATH" RZ_STATFAIL=1
_rz_refuses "a 0707 TMPDIR is still refused by ls when stat says nothing (other write)" "$RZWHY_PRIV" TMPDIR="$RZ/d707" PATH="$RZSB:$RZB:$PATH" RZ_STATFAIL=1
_rz_refuses "a world-writable parent is still refused by ls" "$RZWHY_PRIV" TMPDIR="$RZ/world/priv" PATH="$RZSB:$RZB:$PATH" RZ_STATFAIL=1
_rz_refuses "when neither stat nor ls can say, it is refused and not assumed fine" "$RZWHY_PRIV" TMPDIR="$RZ/priv" PATH="$RZSB:$RZB:$PATH" RZ_STATFAIL=1 RZ_LSJUNK=1

printf '\nthe default TMPDIR of this platform is private\n'
if [ "$(uname)" = Darwin ] && _rzdef="$(getconf DARWIN_USER_TEMP_DIR 2>/dev/null)" && [ -d "$_rzdef" ]; then
  is  "macOS's per-user temporary directory passes the rule" \
      "$(_rz_lib reach "d=\"\$(cd '$_rzdef' && pwd -P)\"; _felix_reach_private \"\$d\"; printf '%s' \"\$?\"")" "0"
else
  skip "macOS's per-user temporary directory passes the rule" "not macOS"
fi

printf '\nfelix stack --reach and the SessionStart refresh with a TMPDIR nobody can trust\n'
_rx_put reachy "$(_rx_now)" "$RZ/x" "$RXR4"
cp "$(_rx_cache reachy)" "$RZ/cache.keep"
_rz_reset
_rzo="$(RZ_TMPDIR="$RZ/world/priv" _rz_stk "$RZC" --reach --tsv)"; _rzrc=$?
is  "felix stack --reach --tsv under a world-writable parent gives one unknown row per plugin row, with the reason" "$_rzo" \
    "$(for _p in ctx gh cf dd quiet gone lost; do printf 'unknown\tplugin\t%s@m\t-\t%s\n' "$_p" "$RZWHY_PRIV"; done)"
is  "and exits 0" "$_rzrc" "0"
is  "and ran no claude command" "$(_rz_n "$RZ/args.log")" "0"
cmp -s "$RZ/cache.keep" "$(_rx_cache reachy)" && ok "and left the cache as it was" || bad "and left the cache as it was"
_rz_reset
rm -f "$(_rx_cache reachy)"; _rz_reset
_rx_wait 10 '[ ! -d "$_rz_lock" ]'
RZ_TMPDIR="$RZ/d777" _rz_hook
_rx_wait 10 '[ ! -d "$_rz_lock" ]'
is  "a SessionStart refresh under a 0777 TMPDIR runs no claude command" "$(_rz_n "$RZ/args.log")" "0"
if [ -e "$(_rx_cache reachy)" ]; then bad "and writes no cache"; else ok "and writes no cache"; fi
is  "and the lock is not left behind" "$([ -d "$_rz_lock" ] && echo held || echo free)" "free"
is  "and started no project-scoped server" "$(_rz_marks)" ""

printf '\nreach.sh has no /tmp\n'
_rz_src="$(awk '/^[[:space:]]*#/ { next } { print }' "$FROOT/harness/lib/reach.sh" "$FROOT/harness/lib/reach-read.sh" 2>/dev/null)"
is  "no line of code in reach.sh or reach-read.sh names /tmp" "$(printf '%s\n' "$_rz_src" | grep -c '/tmp')" "0"
is  "and none gives TMPDIR a default" "$(printf '%s\n' "$_rz_src" | grep -c 'TMPDIR:-[^}]')" "0"
for _rzl in reach reach-read; do
  _rzlc="$(awk 'END { print NR }' "$FROOT/harness/lib/$_rzl.sh" 2>/dev/null)"
  [ -n "$_rzlc" ] && [ "$_rzlc" -gt 0 ] && [ "$_rzlc" -lt 500 ] && ok "lib/$_rzl.sh is under 500 lines" || bad "lib/$_rzl.sh is under 500 lines" "${_rzlc:-absent}"
done
is  "reach-read.sh pipes nothing into grep -q" "$(awk '/\|[[:space:]]*grep -q/ { print FILENAME ":" FNR }' "$FROOT/harness/lib/reach-read.sh" 2>/dev/null)" ""
is  "reach.sh sources reach-read.sh, so every caller of the read has it" \
    "$(awk '/reach-read\.sh/ && !/^[[:space:]]*#/ { n++ } END { print n + 0 }' "$FROOT/harness/lib/reach.sh")" "1"
_rz_reset
# The fixtures of parts 1100 to 1120 lived under HOME on a runner whose temporary directory is under a world-writable /tmp (see part 1100); they go with the part.
# and the fixture guard's roots go back to what they were before the base was added, byte for byte, so the group of 1100 to 1120 leaves them as its prelude made them.
[ "$RXBASE" = "$TMP" ] || { _fx_root_del "$RXBASE"; rm -rf "$RXBASE"; _fx_roots="$RX_ROOTS0"; }
