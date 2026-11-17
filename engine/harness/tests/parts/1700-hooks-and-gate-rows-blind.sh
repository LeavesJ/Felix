# >>> hooks-and-gate-rows
printf '\nfelix status, doctor and session start show hooks switched off and a project with no gate (audit b04, A38-A69, blind)\n'
# Blind, written on 2026-10-24 from the b04 contract alone (docs/2026-10-24-audit-fixes/, "status shows a
# stopped lander, hooks off and ungoverned projects": B14 to B20, fixture S of section 4 and part 1700's
# table), before the fix, without reading lib/status.sh, lib/pulse.sh, hooks/session-start, hooks/stop or
# felix. Felix is run as a black box. The defects: settings that switch Felix's hooks off went undetected
# (C014), and a project that declares no gate looked governed on the surfaces read every day (C115).
#
# Fixture S, under $TMP/hks, physical paths throughout: H a Felix home holding lp (gate "true"), ng (no gate
# key), ne ("gate": ""), nj (no project.json) and dj (project.json a directory), each with a checkout bound
# by .felix under co/; CL is lp's. U a HOME whose settings enable felix@felix; U2 a second HOME whose
# settings file each case of A38-A43 writes; M a memory root; P a repository with no marker; and B the
# stubs, as part 1690 has them: uname ($S_UNAME or Darwin), launchctl (print exits with ctl/print.rc, 113
# by default; list prints its header alone), osascript (exit 0), gh and claude (exit 1), each logging.
# CL's .claude/settings*.json are set from nothing for each case by _hks_cl.
#
# Readings, where the contract leaves room. A42's file enables felix@felix beside "yes", so the unknown is
# disableAllHooks's alone. A52 is three runs and one assertion, each file alone in CL's .claude. A55's
# "no .claude files" is an empty .claude directory (A45 is the one with none). A57's marker is touched
# before each of A45-A56's runs, after CL's .claude is set, and what each run leaves newer is gathered. A58
# finds the project line as the line that is project:, padded to 14 columns, then lp. A69's "prints
# nothing" is both streams, as part 0210's Stop helper reads it. Session start runs as parts 0120, 0220 and
# 0250 run it, CLAUDE_PLUGIN_ROOT naming the suite's copy, and a discovery it may leave running is waited
# for by its lock, as part 1690 does. A check that needs a real JSON parser is skipped, saying so, when
# command -v jq finds none, as part 1100 does.
HKS="$(mkdir -p "$TMP/hks" && cd "$TMP/hks" && pwd -P)"; [ -n "$HKS" ] && [ -d "$HKS" ] || HKS="$TMP/hks"
HKSH="$HKS/home"; HKSU="$HKS/user"; HKSU2="$HKS/user2"; HKSM="$HKS/memory"; HKSP="$HKS/plain"
HKSB="$HKS/bin"; HKSK="$HKS/ctl"; HKSO="$HKS/out"; HKSCO="$HKS/co"; HKSC="$HKS/co/lp"
HKSTAB="$(printf '\t')"; HKSNL='
'
HKSJQ="$(command -v jq 2>/dev/null)"
mkdir -p "$HKSU/.claude" "$HKSU/Library/LaunchAgents" "$HKSU2/.claude" "$HKSM" "$HKSP" "$HKSB" "$HKSK" "$HKSO"
for _hksw in lp ng ne nj dj; do mkdir -p "$HKSH/projects/$_hksw" "$HKSCO/$_hksw"; printf '# %s\n' "$_hksw" > "$HKSH/projects/$_hksw/CLAUDE.md"; done
printf '{"name":"lp","remote_match":"example.invalid/lp","gate":"true"}\n' > "$HKSH/projects/lp/project.json"
printf '{"name":"ng","remote_match":"example.invalid/ng"}\n' > "$HKSH/projects/ng/project.json"
printf '{"name":"ne","remote_match":"example.invalid/ne","gate":""}\n' > "$HKSH/projects/ne/project.json"
mkdir -p "$HKSH/projects/dj/project.json"
printf '{"enabledPlugins":{"felix@felix":true}}\n' > "$HKSU/.claude/settings.json"
for _hksw in lp ng ne nj dj; do
  ( _fx_cd "$HKSCO/$_hksw" && git init -q -b main && printf '%s\n' "$_hksw" > .felix && printf '%s notes\n' "$_hksw" > notes.txt \
    && git add -A && git -c user.name=t -c user.email=t@t commit -qm base ) >/dev/null 2>&1
done
( _fx_cd "$HKSP" && git init -q -b main && printf 'plain notes\n' > notes.txt \
  && git add -A && git -c user.name=t -c user.email=t@t commit -qm base ) >/dev/null 2>&1
_hks_put() { sed "s#@K@#$HKSK#g" > "$1" && chmod +x "$1"; }
_hks_put "$HKSB/uname" <<'HKSSTUB'
#!/bin/bash
printf '%s\n' "${S_UNAME:-Darwin}"
HKSSTUB
_hks_put "$HKSB/launchctl" <<'HKSSTUB'
#!/bin/bash
printf '%s\n' "$*" >> '@K@/launchctl.log'
case "${1:-}" in
  print) rc=113; [ -f '@K@/print.rc' ] && rc="$(cat '@K@/print.rc')"; exit "$rc" ;;
  list) printf 'PID\tStatus\tLabel\n'; exit 0 ;;
esac
exit 0
HKSSTUB
for _hksw in osascript:0 gh:1 claude:1; do
  printf '#!/bin/bash\nprintf '"'"'%%s\\n'"'"' "$*" >> '"'"'@K@/%s.log'"'"'\nexit %s\n' "${_hksw%%:*}" "${_hksw#*:}" > "$HKSK/stub"
  _hks_put "$HKSB/${_hksw%%:*}" < "$HKSK/stub"
done
: > "$HKSO/newer"
printf '{"hook_event_name":"Stop","stop_hook_active":false}' > "$HKSO/stop.json"
sleep 1   # the checkouts' indexes are older than any second a run below starts in

# CMD...: fixture S's environment. HKSHOME, when set, is the HOME; HKSX holds more NAME=value words.
HKSX=(); HKSHOME=""; HKSMARK=0; _hks_n=0
_hks_env() {
  env -u COPILOT_CLI -u CURSOR_PLUGIN_ROOT -u CLAUDE_CONFIG_DIR -u FELIX_JQ \
    HOME="${HKSHOME:-$HKSU}" FELIX_HOME="$HKSH" FELIX_HOME_DIR="$HKSH" FELIX_MEMORY="$HKSM" \
    PATH="$HKSB:$PATH" ${HKSX[@]+"${HKSX[@]}"} "$@"
}
# DIR -> felix status --tsv from DIR: output in HKSF, status in HKSRC; under HKSMARK=1 what the run left
# newer than a marker touched just before it, under CL, H or M, is gathered in out/newer.
_hks_st() {
  local nw
  _hks_n=$((_hks_n + 1)); HKSF="$HKSO/st.$_hks_n"
  [ "$HKSMARK" = 0 ] || touch "$HKSO/marker"
  ( cd "$1" && _hks_env "$FELIX" status --tsv ) > "$HKSF" 2> "$HKSO/status.err"; HKSRC=$?
  if [ "$HKSMARK" = 1 ]; then
    nw="$(find "$HKSC" "$HKSH" "$HKSM" -newer "$HKSO/marker" 2>&1)"
    [ -z "$nw" ] || printf 'after status run %s: %s\n' "$_hks_n" "$nw" >> "$HKSO/newer"
  fi
}
_hks_row() { LC_ALL=C awk -F'\t' -v r="$2" '$1 == r' "$1" 2>/dev/null; }   # FILE ROW -> that row's lines
_hks_want() { printf '%s\t%s\t%s\t%s' "$1" "$2" "$3" "$4"; }   # ROW STATE VALUE DETAIL -> the whole row
# NAME FILE ROW STATE VALUE [is|starts|holds TEXT]...: FILE holds one ROW row with that state and value, and
# a detail that passes each test.
_hks_like() {
  local n="$1" r="$3" row h d="" why="" op t
  row="$(_hks_row "$2" "$3")"; h="$3$HKSTAB$4$HKSTAB$5$HKSTAB"
  shift 5
  case "$row" in
    *"$HKSNL"*) why="more than one $r row" ;;
    "$h"*) d="${row#"$h"}"; case "$d" in *"$HKSTAB"*) why="the detail holds a tab" ;; "") why="the detail is empty" ;; esac ;;
    *) why="not the row [$h...]" ;;
  esac
  while [ -z "$why" ] && [ "$#" -ge 2 ]; do
    op="$1"; t="$2"; shift 2
    case "$op" in
      is)     [ "$d" = "$t" ] || why="the detail is not [$t]" ;;
      starts) case "$d" in "$t"*) ;; *) why="the detail does not start [$t]" ;; esac ;;
      holds)  case "$d" in *"$t"*) ;; *) why="the detail does not hold [$t]" ;; esac ;;
    esac
  done
  if [ -z "$why" ]; then ok "$n"; else bad "$n" "$why; the $r row is [$row]"; fi
}
# CL's .claude, set from nothing: project=JSON, local=JSON, projectempty, projectdir, emptydir.
_hks_cl() {
  local w
  rm -rf "$HKSC/.claude"
  for w in "$@"; do
    mkdir -p "$HKSC/.claude"
    case "$w" in
      project=*)    printf '%s\n' "${w#project=}" > "$HKSC/.claude/settings.json" ;;
      local=*)      printf '%s\n' "${w#local=}" > "$HKSC/.claude/settings.local.json" ;;
      projectempty) : > "$HKSC/.claude/settings.json" ;;
      projectdir)   mkdir -p "$HKSC/.claude/settings.json" ;;
    esac
  done
}
_hks_u2() { printf '%s\n' "$1" > "$HKSU2/.claude/settings.json"; }   # JSON -> U2's settings file
# NAME -> 0 when jq is on PATH; a skip naming why, and 1, when it is not.
_hks_jq() { [ -n "$HKSJQ" ] && return 0; skip "$1" "no jq on PATH: this check needs a real JSON parser"; return 1; }
_hks_calm() { local i=0; while [ "$i" -lt 100 ] && [ -d "$HKSH/state/discover/.lock" ]; do sleep 0.2; i=$((i+1)); done; }
# DIR -> session start there, a startup payload naming DIR: output in HKSF, status in HKSRC.
_hks_ss() {
  _hks_n=$((_hks_n + 1)); HKSF="$HKSO/ss.$_hks_n"
  printf '{"session_id":"b04","source":"startup","cwd":"%s"}' "$1" > "$HKSO/startup.json"
  ( cd "$1" && _hks_env CLAUDE_PLUGIN_ROOT="$FROOT" "$FROOT/harness/hooks/session-start" < "$HKSO/startup.json" ) \
    > "$HKSF" 2> "$HKSO/ss.err"; HKSRC=$?
  sleep 0.5; _hks_calm
}
_hks_js() {   # FILE KEY -> systemMessage, or hookSpecificOutput's additionalContext, as UTF-8; <absent> or <not JSON>
  python3 -c 'import json, sys
try:
    d = json.loads(open(sys.argv[1], "rb").read())
    assert isinstance(d, dict)
except Exception:
    sys.stdout.write("<not JSON>"); sys.exit(0)
k = sys.argv[2]
h = d.get("hookSpecificOutput")
v = d.get(k) if k == "systemMessage" else (h.get(k) if isinstance(h, dict) else None)
if not isinstance(v, str):
    sys.stdout.write("<absent>"); sys.exit(0)
sys.stdout.buffer.write(v.encode("utf-8"))' "$1" "$2" 2>/dev/null
}
_hks_line() {   # FILE LINE -> yes when FILE holds that exact line
  local l
  while IFS= read -r l || [ -n "$l" ]; do [ "$l" != "$2" ] || { printf 'yes'; return 0; }; done < "$1"
  printf 'no'
}
HKSF2="$HKSU2/.claude/settings.json"

# ---- B16: the user file ----------------------------------------------------------------------------------
_hksn="A38: a user settings file that enables felix@felix and sets disableAllHooks to true reads settings value hooks-off, naming it and that no hook runs"
if _hks_jq "$_hksn"; then
  _hks_u2 '{"enabledPlugins":{"felix@felix":true},"disableAllHooks":true}'; HKSHOME="$HKSU2"; _hks_st "$HKSP"; HKSHOME=""
  is "$_hksn" "$(_hks_row "$HKSF" settings)" \
     "$(_hks_want settings value hooks-off "$HKSF2 sets disableAllHooks to true: Claude Code runs no hook, Felix's included, unless a project's own settings set it back to false")"
fi
_hksn="A39: felix pulse prints the same answer on its settings line: settings, hooks-off and that detail"
if _hks_jq "$_hksn"; then
  ( cd "$HKSP" && HKSHOME="$HKSU2" _hks_env "$FELIX" pulse ) > "$HKSO/pulse.out" 2>&1
  has "$_hksn" "$(cat "$HKSO/pulse.out")" \
      "$(printf 'settings\thooks-off\t%s sets disableAllHooks to true: Claude Code runs no hook, Felix'"'"'s included, unless a project'"'"'s own settings set it back to false' "$HKSF2")"
fi
_hksn="A40: disableAllHooks true reads hooks-off even beside felix@felix false"
if _hks_jq "$_hksn"; then
  _hks_u2 '{"enabledPlugins":{"felix@felix":false},"disableAllHooks":true}'; HKSHOME="$HKSU2"; _hks_st "$HKSP"; HKSHOME=""
  _hks_like "$_hksn" "$HKSF" settings value hooks-off
fi
_hksn="A41 (control): disableAllHooks false beside felix@felix true still reads settings value ok"
if _hks_jq "$_hksn"; then
  _hks_u2 '{"enabledPlugins":{"felix@felix":true},"disableAllHooks":false}'; HKSHOME="$HKSU2"; _hks_st "$HKSP"; HKSHOME=""
  is "$_hksn" "$(_hks_row "$HKSF" settings)" "$(_hks_want settings value ok "$HKSF2 enables felix@felix")"
fi
_hksn="A42: disableAllHooks set to the string yes leaves the settings row unknown, quoting its JSON"
if _hks_jq "$_hksn"; then
  _hks_u2 '{"enabledPlugins":{"felix@felix":true},"disableAllHooks":"yes"}'; HKSHOME="$HKSU2"; _hks_st "$HKSP"; HKSHOME=""
  is "$_hksn" "$(_hks_row "$HKSF" settings)" "$(_hks_want settings unknown - "$HKSF2 sets disableAllHooks to \"yes\", which this check does not read")"
fi
_hks_u2 '{"enabledPlugins":{"felix@felix":true},"disableAllHooks":true}'
HKSHOME="$HKSU2"; HKSX=(FELIX_JQ=/nonexistent); _hks_st "$HKSP"; HKSX=(); HKSHOME=""
is "A43 (control): with no parser the settings row is still unknown, and the file is not read" \
   "$(_hks_row "$HKSF" settings)" "$(_hks_want settings unknown - "no JSON parser on this machine (jq); $HKSF2 was not read")"

# ---- B17: the hooks row --------------------------------------------------------------------------------------
_hks_st "$HKSP"
is "A44: outside a governed checkout the hooks row is none" \
   "$(_hks_row "$HKSF" hooks)" "$(_hks_want hooks none - 'this directory is not a governed checkout')"
HKSMARK=1
_hks_cl; _hks_st "$HKSC"
_hks_like "A45: a checkout with no .claude reads hooks clear, saying no settings file turns hooks off and what is not read" \
  "$HKSF" hooks value clear holds 'no project or local settings file' \
  holds 'managed settings, a --settings file, --bare and an untrusted workspace are not read here'
_hksn="A46: a local settings file setting disableAllHooks to true reads hooks off, naming that file"
if _hks_jq "$_hksn"; then
  _hks_cl 'local={"disableAllHooks":true}'; _hks_st "$HKSC"
  is "$_hksn" "$(_hks_row "$HKSF" hooks)" \
     "$(_hks_want hooks value off "$HKSC/.claude/settings.local.json sets disableAllHooks to true: Claude Code runs no hook in a session here, Felix's included")"
fi
_hksn="A47: a project settings file setting disableAllHooks to true reads off too, naming the project file"
if _hks_jq "$_hksn"; then
  _hks_cl 'project={"disableAllHooks":true}'; _hks_st "$HKSC"
  _hks_like "$_hksn" "$HKSF" hooks value off starts "$HKSC/.claude/settings.json sets disableAllHooks"
fi
_hksn="A48: a local disableAllHooks false wins over a project true: clear"
if _hks_jq "$_hksn"; then
  _hks_cl 'project={"disableAllHooks":true}' 'local={"disableAllHooks":false}'; _hks_st "$HKSC"
  _hks_like "$_hksn" "$HKSF" hooks value clear
fi
_hksn="A49: a project settings file setting felix@felix to false reads hooks felix-off: Felix's hooks do not load"
if _hks_jq "$_hksn"; then
  _hks_cl 'project={"enabledPlugins":{"felix@felix":false}}'; _hks_st "$HKSC"
  is "$_hksn" "$(_hks_row "$HKSF" hooks)" \
     "$(_hks_want hooks value felix-off "$HKSC/.claude/settings.json sets enabledPlugins[\"felix@felix\"] to false: Felix's hooks do not load in a session here")"
fi
_hksn="A50: a local felix@felix true wins over the project's false: clear"
if _hks_jq "$_hksn"; then
  _hks_cl 'project={"enabledPlugins":{"felix@felix":false}}' 'local={"enabledPlugins":{"felix@felix":true}}'; _hks_st "$HKSC"
  _hks_like "$_hksn" "$HKSF" hooks value clear
fi
_hksn="A51: a local disableAllHooks true beside the project's felix@felix false reads off"
if _hks_jq "$_hksn"; then
  _hks_cl 'project={"enabledPlugins":{"felix@felix":false}}' 'local={"disableAllHooks":true}'; _hks_st "$HKSC"
  _hks_like "$_hksn" "$HKSF" hooks value off
fi
_hksn="A52: a local file that does not parse, a project file holding [] and an empty project file each leave the hooks row unknown"
if _hks_jq "$_hksn"; then
  _hkso=""; _hksw=""
  for _hksi in 'local={not json:settings.local.json' 'project=[]:settings.json' 'projectempty:settings.json'; do
    _hks_cl "${_hksi%:*}"; _hks_st "$HKSC"
    _hkso="$_hkso[$(_hks_row "$HKSF" hooks)]"
    _hksw="$_hksw[$(_hks_want hooks unknown - "$HKSC/.claude/${_hksi##*:} does not parse as a JSON object, so whether it turns hooks off is not known")]"
  done
  is "$_hksn" "$_hkso" "$_hksw"
fi
_hksn="A53: disableAllHooks set to the string true leaves the hooks row unknown, quoting its JSON"
if _hks_jq "$_hksn"; then
  _hks_cl 'project={"disableAllHooks":"true"}'; _hks_st "$HKSC"
  is "$_hksn" "$(_hks_row "$HKSF" hooks)" \
     "$(_hks_want hooks unknown - "$HKSC/.claude/settings.json sets disableAllHooks to \"true\", which this check does not read")"
fi
_hks_cl 'local={"disableAllHooks":true}'; HKSX=(FELIX_JQ=/nonexistent); _hks_st "$HKSC"; HKSX=()
_hks_like "A54: with no parser a present settings file leaves the hooks row unknown: no JSON parser on this machine" \
  "$HKSF" hooks unknown - starts 'no JSON parser on this machine (jq)'
_hks_cl; mkdir -p "$HKSC/.claude"; HKSX=(FELIX_JQ=/nonexistent); _hks_st "$HKSC"; HKSX=()
_hks_like "A55: with no parser and no settings file in .claude the hooks row is still clear" "$HKSF" hooks value clear
_hks_cl projectdir; _hks_st "$HKSC"
is "A56: a settings.json that is a directory leaves the hooks row unknown: it cannot be read" \
   "$(_hks_row "$HKSF" hooks)" \
   "$(_hks_want hooks unknown - "$HKSC/.claude/settings.json cannot be read, so whether it turns hooks off is not known")"
HKSMARK=0
is "A57 (control): felix status changed nothing under the checkout, the home or the memory root in A45-A56's runs" \
   "$(cat "$HKSO/newer")" ""

# ---- B18: felix doctor ------------------------------------------------------------------------------------
_hksn="A58: felix doctor prints gate, settings and hooks lines straight after its project line, each label padded to 14 columns"
if _hks_jq "$_hksn"; then
  _hks_cl 'local={"disableAllHooks":true}'
  ( cd "$HKSC" && _hks_env "$FELIX" doctor ) > "$HKSO/doctor.lp" 2>&1; HKSRC=$?
  _hkso="$(LC_ALL=C awk -v p="$(printf '%-14s%s' 'project:' lp)" 'f && n < 3 { n++; print; next } $0 == p || index($0, p " ") == 1 { f = 1 }' "$HKSO/doctor.lp")"
  _hksw="$(printf '%-14s%s' 'hooks:' "off: $HKSC/.claude/settings.local.json sets disableAllHooks to true")"
  case "$_hkso" in *"$HKSNL$_hksw"*) _hkso="${_hkso%%"$HKSNL$_hksw"*}$HKSNL$_hksw" ;; esac
  is "$_hksn" "exit $HKSRC$HKSNL$_hkso" \
     "exit 0$HKSNL$(printf '%-14s%s' 'gate:' true)$HKSNL$(printf '%-14s%s' 'settings:' "ok: $HKSU/.claude/settings.json enables felix@felix")$HKSNL$_hksw"
  _hks_cl
fi
( cd "$HKSCO/ng" && _hks_env "$FELIX" doctor ) > "$HKSO/doctor.ng" 2>&1
is "A59: felix doctor in a project that declares no gate says none declared: no stop is checked, and where to set one" \
   "$(_hks_line "$HKSO/doctor.ng" "$(printf '%-14s%s' 'gate:' "none declared: no stop is checked; set \"gate\" in $HKSH/projects/ng/project.json")")" "yes"

# ---- B19: the gate row --------------------------------------------------------------------------------------
_hks_st "$HKSCO/ng"
is "A60: a project.json with no gate key reads gate value no-gate: the Stop hook checks no stop here" \
   "$(_hks_row "$HKSF" gate)" \
   "$(_hks_want gate value no-gate "ng declares no gate in $HKSH/projects/ng/project.json: the Stop hook checks no stop here; set \"gate\" there")"
_hks_st "$HKSCO/ne"
_hks_like "A61: an empty gate reads no-gate too" "$HKSF" gate value no-gate
_hks_st "$HKSCO/nj"
is "A62: a project with no project.json reads no-gate, saying the file does not exist" \
   "$(_hks_row "$HKSF" gate)" \
   "$(_hks_want gate value no-gate "$HKSH/projects/nj/project.json does not exist, so no gate is declared: the Stop hook checks no stop here")"
_hks_st "$HKSCO/dj"
is "A63: a project.json that is a directory leaves the gate row unknown: whether a gate is declared is not known" \
   "$(_hks_row "$HKSF" gate)" \
   "$(_hks_want gate unknown - "$HKSH/projects/dj/project.json cannot be read, so whether a gate is declared is not known; the Stop hook reads no gate from it and checks no stop here")"
_hks_st "$HKSC"
is "A64 (control): a gated project with no receipt still reads gate value none-run" \
   "$(_hks_row "$HKSF" gate)" "$(_hks_want gate value none-run 'no gate has run in this checkout')"

# ---- B14, B15 and B20: the no-gate badge, its order, and the Stop hook --------------------------------------
HKSNG="Felix: ng · no gate, stops unchecked"
if command -v python3 >/dev/null 2>&1; then
  _hks_ss "$HKSCO/ng"; _hkso="$(_hks_js "$HKSF" systemMessage)"
  case "$_hkso" in "$HKSNG"*) _hkso="starts with it" ;; esac
  is "A65: session start in a project with no gate says no gate, stops unchecked on its one line, after Felix: ng" "$_hkso" "starts with it"
  _hkso="$(_hks_js "$HKSF" additionalContext)"
  case "$_hkso" in *"Gate: none declared (set \"gate\" in $HKSH/projects/ng/project.json)"*) _hkso="holds it" ;; esac
  is "A66 (control): and its context keeps Gate: none declared, naming where to set one" "$_hkso" "holds it"
  _hks_ss "$HKSC"; _hkso="$(_hks_js "$HKSF" systemMessage)"
  case "$_hkso" in *"no gate"*) ;; *) _hkso="no such words" ;; esac
  is "A67 (control): session start in a gated project says nothing of no gate on its line" "$_hkso" "no such words"
  printf '<plist/>\n' > "$HKSU/Library/LaunchAgents/felix.land.ng.plist"; printf '0\n' > "$HKSK/print.rc"
  mkdir -p "$HKSM/ng/land"; printf '%s\n' "$(( $(date +%s) - 60 ))" > "$HKSM/ng/land/heartbeat"
  printf 'held for the test\n' > "$HKSM/ng/land/paused"
  _hks_ss "$HKSCO/ng"; _hkso="$(_hks_js "$HKSF" systemMessage)"
  case "$_hkso" in "$HKSNG"*" · landing paused"*) _hkso="no gate first, then landing paused" ;; esac
  is "A68: with no gate and the lander paused the line says no gate, stops unchecked first and landing paused after it" \
     "$_hkso" "no gate first, then landing paused"
  rm -f "$HKSU/Library/LaunchAgents/felix.land.ng.plist" "$HKSK/print.rc"; rm -rf "$HKSM/ng/land"
else
  for _hksw in "A65: session start in a project with no gate says no gate, stops unchecked on its one line, after Felix: ng" \
               "A66 (control): and its context keeps Gate: none declared, naming where to set one" \
               "A67 (control): session start in a gated project says nothing of no gate on its line" \
               "A68: with no gate and the lander paused the line says no gate, stops unchecked first and landing paused after it"; do
    skip "$_hksw" "no python3 on PATH to read the hook's JSON"
  done
fi
printf 'edited\n' >> "$HKSCO/ng/notes.txt"
_hkso="$( cd "$HKSCO/ng" && _hks_env "$FROOT/harness/hooks/stop" < "$HKSO/stop.json" 2>&1 )"; HKSRC=$?
is "A69 (control): the Stop hook in a project with no gate, over an edited tracked file, still prints nothing and exits 0" \
   "$HKSRC [$_hkso]" "0 []"
( _fx_cd "$HKSCO/ng" && git checkout -q -- notes.txt ) >/dev/null 2>&1
_hks_calm
# <<< hooks-and-gate-rows
