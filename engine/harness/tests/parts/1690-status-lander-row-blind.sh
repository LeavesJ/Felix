# >>> status-lander-row
printf '\nfelix status shows the lander: the land row, the heartbeat and the landing badge (audit b04, A1-A37, blind)\n'
# Blind, written on 2026-10-24 from the b04 contract alone (docs/2026-10-24-audit-fixes/, "status shows a
# stopped lander, hooks off and ungoverned projects": B1-B15, fixture S of section 4 and part 1690's table),
# before the fix, without reading lib/status.sh, lib/green-tick.sh, hooks/session-start or felix. Felix is
# run as a black box. The defect (C005): a paused, unloaded, uninstalled or hung land-on-green job showed on
# no surface a person reads at the start of a session.
#
# Fixture S, under $TMP/lnd, with physical paths throughout, since every Ld/... and <Pl> in a detail is the
# full path: H a Felix home holding project lp (gate "true"), U a HOME whose settings enable felix@felix, M
# a memory root, C a checkout bound to lp by .felix (one commit), P a repository with no marker, and B the
# stubs, first on PATH: uname prints $S_UNAME or Darwin; launchctl logs its argv, and answers print with
# nothing and the exit in ctl/print.rc (113 when there is none) and list with its header alone; osascript
# logs and exits 0; gh and claude log and exit 1. Ld is M/lp/land; Pl is U/Library/LaunchAgents/
# felix.land.lp.plist, any file. Every state is set from nothing by _lnd_set. "hb K" is a heartbeat of
# now - K; "row1" is the ledger line of 2026-10-23T06:16:28Z, a pause for a tracked change in the home.
#
# Readings, where the contract leaves room. A2 holds every status run to the nine rows in order as well as
# to D16's shape, since B1 asks both on every path and the shape alone holds of five rows too. A22's marker
# is touched before each of A4-A21's runs, after its state is set, and what each run leaves newer is
# gathered: the states themselves are written under M and U/Library, and are not the status's writes.
# Session start is run as parts 0120, 0220 and 0250 run it, with CLAUDE_PLUGIN_ROOT naming the suite's
# copy, its payload from a file; A32 reads felix status in the same state. A35's "A30's line" is Felix: lp,
# as A30 states it. A discovery a session start may leave running is waited for, up to 20 s, by the lock
# part 1130 waits on, so no process of this part outlives it; A25's sleep is ended by its pid.
LND="$(mkdir -p "$TMP/lnd" && cd "$TMP/lnd" && pwd -P)"; [ -n "$LND" ] && [ -d "$LND" ] || LND="$TMP/lnd"
LNDH="$LND/home"; LNDU="$LND/user"; LNDM="$LND/memory"; LNDC="$LND/checkout"; LNDP="$LND/plain"
LNDB="$LND/bin"; LNDB2="$LND/bin-no-launchctl"; LNDK="$LND/ctl"; LNDO="$LND/out"
LNDLD="$LNDM/lp/land"; LNDPL="$LNDU/Library/LaunchAgents/felix.land.lp.plist"
LNDTAB="$(printf '\t')"; LNDNL='
'
mkdir -p "$LNDH/projects/lp" "$LNDU/.claude" "$LNDU/Library/LaunchAgents" "$LNDM" "$LNDC" "$LNDP" \
         "$LNDB" "$LNDB2" "$LNDK" "$LNDO/st"
printf '{"name":"lp","remote_match":"example.invalid/lp","gate":"true"}\n' > "$LNDH/projects/lp/project.json"
printf '# lp\n' > "$LNDH/projects/lp/CLAUDE.md"
# Combined with b05 (docs/2026-10-24-audit-fixes/wave-1-combine.md, S4): felix land runs only where the home resolves the
# checkout's own project (C013, B14), so the home is a checkout whose .felix names lp, as LNDC's does.
( _fx_cd "$LNDH" && git init -q -b main && printf 'lp\n' > .felix \
  && git add -A && git -c user.name=t -c user.email=t@t commit -qm base ) >/dev/null 2>&1
printf '{"enabledPlugins":{"felix@felix":true}}\n' > "$LNDU/.claude/settings.json"
( _fx_cd "$LNDC" && git init -q -b main && printf 'lp\n' > .felix && printf 'lp notes\n' > notes.txt \
  && git add -A && git -c user.name=t -c user.email=t@t commit -qm base ) >/dev/null 2>&1
( _fx_cd "$LNDP" && git init -q -b main && printf 'plain notes\n' > notes.txt \
  && git add -A && git -c user.name=t -c user.email=t@t commit -qm base ) >/dev/null 2>&1
_lnd_put() { sed "s#@K@#$LNDK#g" > "$1" && chmod +x "$1"; }
_lnd_put "$LNDB/uname" <<'LNDSTUB'
#!/bin/bash
printf '%s\n' "${S_UNAME:-Darwin}"
LNDSTUB
_lnd_put "$LNDB/launchctl" <<'LNDSTUB'
#!/bin/bash
printf '%s\n' "$*" >> '@K@/launchctl.log'
case "${1:-}" in
  print) rc=113; [ -f '@K@/print.rc' ] && rc="$(cat '@K@/print.rc')"; exit "$rc" ;;
  list) printf 'PID\tStatus\tLabel\n'; exit 0 ;;
esac
exit 0
LNDSTUB
for _lndw in osascript:0 gh:1 claude:1; do
  printf '#!/bin/bash\nprintf '"'"'%%s\\n'"'"' "$*" >> '"'"'@K@/%s.log'"'"'\nexit %s\n' "${_lndw%%:*}" "${_lndw#*:}" > "$LNDK/stub"
  _lnd_put "$LNDB/${_lndw%%:*}" < "$LNDK/stub"
  cp "$LNDB/${_lndw%%:*}" "$LNDB2/${_lndw%%:*}"
done
cp "$LNDB/uname" "$LNDB2/uname"
for _lndw in launchctl osascript gh claude; do : > "$LNDK/$_lndw.log"; done
: > "$LNDK/launchctl.all"; : > "$LNDO/newer"
LNDROW1="2026-10-23T06:16:28Z${LNDTAB}paused${LNDTAB}-${LNDTAB}-${LNDTAB}-${LNDTAB}0${LNDTAB}the home checkout holds a tracked change"
LNDN1="the ledger's newest row is 2026-10-23T06:16:28Z paused: the home checkout holds a tracked change"
LNDWHY="the home checkout holds a tracked change"
printf '{"session_id":"b04","source":"startup","cwd":"%s"}' "$LNDC" > "$LNDO/startup.json"
printf '{"session_id":"b04","source":"resume","cwd":"%s"}' "$LNDC" > "$LNDO/resume.json"
sleep 1   # the checkout's index is older than any second a run below starts in

# CMD...: fixture S's environment. LNDX holds more NAME=value words; LNDPATH, when set, is the whole PATH.
LNDX=(); LNDPATH=""; LNDMARK=0; _lnd_n=0
_lnd_env() {
  env -u COPILOT_CLI -u CURSOR_PLUGIN_ROOT -u CLAUDE_CONFIG_DIR -u FELIX_JQ \
    HOME="$LNDU" FELIX_HOME="$LNDH" FELIX_HOME_DIR="$LNDH" FELIX_MEMORY="$LNDM" \
    PATH="${LNDPATH:-$LNDB:$PATH}" ${LNDX[@]+"${LNDX[@]}"} "$@"
}
# Ld, Pl and launchctl print's exit, set from nothing: pl, print=N, hb=K, hbtext=TEXT, row1, paused=R, pausedempty.
_lnd_set() {
  local w
  rm -rf "$LNDLD"; rm -f "$LNDPL" "$LNDK/print.rc"
  for w in "$@"; do
    case "$w" in
      pl)          printf '<plist/>\n' > "$LNDPL" ;;
      print=*)     printf '%s\n' "${w#print=}" > "$LNDK/print.rc" ;;
      hb=*)        mkdir -p "$LNDLD"; printf '%s\n' "$(( $(date +%s) - ${w#hb=} ))" > "$LNDLD/heartbeat" ;;
      hbtext=*)    mkdir -p "$LNDLD"; printf '%s\n' "${w#hbtext=}" > "$LNDLD/heartbeat" ;;
      row1)        mkdir -p "$LNDLD"; printf '%s\n' "$LNDROW1" > "$LNDLD/ledger.tsv" ;;
      paused=*)    mkdir -p "$LNDLD"; printf '%s\n' "${w#paused=}" > "$LNDLD/paused" ;;
      pausedempty) mkdir -p "$LNDLD"; : > "$LNDLD/paused" ;;
    esac
  done
}
# DIR -> felix status --tsv from DIR: output in LNDF (kept for A2), status in LNDRC. Its launchctl calls are
# in ctl/launchctl.log and gathered in ctl/launchctl.all; under LNDMARK=1 what the run left newer than a
# marker touched just before it is gathered in out/newer.
_lnd_st() {
  local nw
  _lnd_n=$((_lnd_n + 1)); LNDF="$LNDO/st/$_lnd_n"
  : > "$LNDK/launchctl.log"
  [ "$LNDMARK" = 0 ] || touch "$LNDO/marker"
  ( cd "$1" && _lnd_env "$FELIX" status --tsv ) > "$LNDF" 2> "$LNDO/status.err"; LNDRC=$?
  if [ "$LNDMARK" = 1 ]; then
    nw="$(find "$LNDH" "$LNDM" "$LNDC" "$LNDU/Library" -newer "$LNDO/marker" 2>&1)"
    [ -z "$nw" ] || printf 'after status run %s: %s\n' "$_lnd_n" "$nw" >> "$LNDO/newer"
  fi
  cat "$LNDK/launchctl.log" >> "$LNDK/launchctl.all"
}
_lnd_row() { LC_ALL=C awk -F'\t' -v r="$2" '$1 == r' "$1" 2>/dev/null; }   # FILE ROW -> that row's lines
_lnd_prints() { LC_ALL=C awk '$1 == "print" { n++ } END { print n + 0 }' "$LNDK/launchctl.log"; }
# NAME FILE ROW STATE VALUE [is|starts|ends|holds|matches TEXT]...: FILE holds one ROW row with that state and
# value, and a detail that passes each test (matches is an ERE).
_lnd_like() {
  local n="$1" r="$3" row h d="" why="" op t
  row="$(_lnd_row "$2" "$3")"; h="$3$LNDTAB$4$LNDTAB$5$LNDTAB"
  shift 5
  case "$row" in
    *"$LNDNL"*) why="more than one $r row" ;;
    "$h"*) d="${row#"$h"}"; case "$d" in *"$LNDTAB"*) why="the detail holds a tab" ;; "") why="the detail is empty" ;; esac ;;
    *) why="not the row [$h...]" ;;
  esac
  while [ -z "$why" ] && [ "$#" -ge 2 ]; do
    op="$1"; t="$2"; shift 2
    case "$op" in
      is)      [ "$d" = "$t" ] || why="the detail is not [$t]" ;;
      starts)  case "$d" in "$t"*) ;; *) why="the detail does not start [$t]" ;; esac ;;
      ends)    case "$d" in *"$t") ;; *) why="the detail does not end [$t]" ;; esac ;;
      holds)   case "$d" in *"$t"*) ;; *) why="the detail does not hold [$t]" ;; esac ;;
      matches) ( [[ $d =~ $t ]] ) || why="the detail does not match [$t]" ;;   # a subshell: bash 3.2 leaves BASH_REMATCH readonly, and the runner refuses a part that changes the shell (R8)
    esac
  done
  if [ -z "$why" ]; then ok "$n"; else bad "$n" "$why; the $r row is [$row]"; fi
}
_lnd_want() { printf 'land\t%s\t%s\t%s' "$1" "$2" "$3"; }   # STATE VALUE DETAIL -> the whole land row
# A discovery a session start may have left running, waited for while it holds its lock (part 1130's).
_lnd_calm() { local i=0; while [ "$i" -lt 100 ] && [ -d "$LNDH/state/discover/.lock" ]; do sleep 0.2; i=$((i+1)); done; }
# PAYLOAD -> session start from C with that payload: output in LNDF, status in LNDRC.
_lnd_ss() {
  _lnd_n=$((_lnd_n + 1)); LNDF="$LNDO/ss.$_lnd_n"
  ( cd "$LNDC" && _lnd_env CLAUDE_PLUGIN_ROOT="$FROOT" "$FROOT/harness/hooks/session-start" < "$LNDO/$1.json" ) \
    > "$LNDF" 2> "$LNDO/ss.err"; LNDRC=$?
  sleep 0.5; _lnd_calm
}
# FILE KEY -> systemMessage, or hookSpecificOutput's additionalContext, as UTF-8; json for KEY json when the
# file is an object; <absent> or <not JSON> otherwise.
_lnd_js() {
  python3 -c 'import json, sys
try:
    d = json.loads(open(sys.argv[1], "rb").read())
    assert isinstance(d, dict)
except Exception:
    sys.stdout.write("<not JSON>"); sys.exit(0)
k = sys.argv[2]
if k == "json":
    sys.stdout.write("json"); sys.exit(0)
h = d.get("hookSpecificOutput")
v = d.get(k) if k == "systemMessage" else (h.get(k) if isinstance(h, dict) else None)
if not isinstance(v, str):
    sys.stdout.write("<absent>"); sys.exit(0)
sys.stdout.buffer.write(v.encode("utf-8"))' "$1" "$2" 2>/dev/null
}
_lnd_landing() { case "$(_lnd_js "$1" additionalContext)" in *"Landing on green is"*) printf 'a landing line' ;; *) printf 'no landing line' ;; esac; }
# ARGS -> felix land ARGS from C: output in LNDF, status in LNDRC.
_lnd_land() {
  _lnd_n=$((_lnd_n + 1)); LNDF="$LNDO/land.$_lnd_n"
  ( cd "$LNDC" && _lnd_env "$FELIX" land "$@" ) > "$LNDF" 2>&1; LNDRC=$?
}
# T0 T1 -> fresh when Ld/heartbeat is one line of 1 to 12 digits, a newline after them, between T0 and T1.
_lnd_hb() {
  local f="$LNDLD/heartbeat" v n
  [ -f "$f" ] || { printf 'no heartbeat file'; return 0; }
  n="$(wc -l < "$f" | tr -d ' ')"; v="$(cat "$f")"
  case "$v" in ""|*[!0123456789]*) printf 'not digits: [%s]' "$v"; return 0 ;; esac
  [ "$n" = 1 ] || { printf '%s newlines in [%s]' "$n" "$v"; return 0; }
  [ "${#v}" -le 12 ] || { printf '%s digits' "${#v}"; return 0; }
  if [ "$v" -ge "$1" ] && [ "$v" -le "$2" ]; then printf 'fresh'; else printf '%s, not between %s and %s' "$v" "$1" "$2"; fi
}
_lnd_rows() { if [ -f "$LNDLD/ledger.tsv" ]; then LC_ALL=C awk -F'\t' -v e="${1:-}" 'e == "" || $2 == e { n++ } END { print n + 0 }' "$LNDLD/ledger.tsv"; else echo 0; fi; }
_lnd_calls() { LC_ALL=C awk 'END { print NR }' "$LNDK/$1.log" 2>/dev/null || echo 0; }

# ---- B1: nine rows -------------------------------------------------------------------------------------
# Combined with b05 (docs/2026-10-24-audit-fixes/wave-1-combine.md, S1) and b18: b05's alerts row follows hooks
# and b18's icloud row follows alerts, so B1's rows are nine.
# Changed by the lane counter contract (docs/2026-10-29-lane-slice-0-plan.md, C6): the lane row was added at the end, as the status header allows.
_lnd_set
_lnd_st "$LNDC"
is "A1: felix status --tsv exits 0 and prints ten rows, in order: settings, schedule, pulse, reach, gate, land, hooks, alerts, icloud, lane" \
   "$LNDRC $(LC_ALL=C awk -F'\t' '{ printf "%s ", $1 }' "$LNDF")" "0 settings schedule pulse reach gate land hooks alerts icloud lane "

# ---- B2 to B5: governed, a job, launchd's answer -------------------------------------------------------------
_lnd_st "$LNDP"
is "A3: outside a governed checkout the land row is none: this directory is not a governed checkout" \
   "$(_lnd_row "$LNDF" land)" "$(_lnd_want none - 'this directory is not a governed checkout')"
LNDMARK=1
_lnd_set; _lnd_st "$LNDC"
is "A4: with no plist and no ledger the land row is none, says felix land --install schedules one, and asks launchctl print nothing" \
   "$(_lnd_row "$LNDF" land) | prints $(_lnd_prints)" \
   "$(_lnd_want none - 'no land-on-green job for lp; felix land --install schedules one') | prints 0"
_lnd_set pl; LNDX=(S_UNAME=Linux); _lnd_st "$LNDC"; LNDX=()
is "A5: with a plist on a machine whose uname says Linux the land row is unknown, no launchd on Linux, and asks launchctl print nothing" \
   "$(_lnd_row "$LNDF" land) | prints $(_lnd_prints)" "$(_lnd_want unknown - 'no launchd on Linux') | prints 0"
_lnd_set pl print=113; _lnd_st "$LNDC"
is "A6: a plist launchctl print answers 113 for reads not-loaded: the plist exists, launchd has not loaded felix.land.lp, nothing lands, the ledger has no row" \
   "$(_lnd_row "$LNDF" land)" \
   "$(_lnd_want value not-loaded "$LNDPL exists and launchd has not loaded felix.land.lp: nothing lands; the ledger has no row")"
is "A7: the land row asks launchctl print gui/<uid>/felix.land.lp" \
   "$(LC_ALL=C grep -cE '^print gui/[0123456789]+/felix\.land\.lp$' "$LNDK/launchctl.log")" "1"
_lnd_set print=113 row1; _lnd_st "$LNDC"
is "A8: no plist, print 113 and a ledger whose newest row is a pause read not-installed, quoting that row: nothing lands here until felix land --install" \
   "$(_lnd_row "$LNDF" land)" \
   "$(_lnd_want value not-installed "no felix.land.lp job is installed and launchd has none loaded, and $LNDN1: nothing lands here until felix land --install")"
_lnd_set pl print=5; _lnd_st "$LNDC"
is "A9: a launchctl print that exits 5 leaves the land row unknown, naming the exit" \
   "$(_lnd_row "$LNDF" land)" \
   "$(_lnd_want unknown - 'launchctl print exited 5, so whether felix.land.lp is loaded is not known')"
_lndn="A10: with no launchctl on PATH the land row is unknown: launchctl could not answer"
if [ -e /usr/bin/launchctl ] || [ -e /bin/launchctl ]; then
  skip "$_lndn" "a launchctl sits in /usr/bin or /bin here, so no PATH of B, /usr/bin and /bin goes without one"
else
  _lnd_set pl; LNDPATH="$LNDB2:/usr/bin:/bin"; _lnd_st "$LNDC"; LNDPATH=""
  is "$_lndn" "$(_lnd_row "$LNDF" land)" "$(_lnd_want unknown - 'launchctl could not answer')"
fi

# ---- B6 to B10: ticking, paused, liveness, running, and the newest row ------------------------------------
_lnd_set pl print=0 hb=3600 row1; _lnd_st "$LNDC"
_lnd_like "A11: a loaded job whose heartbeat is an hour old reads not-ticking, for 60 minutes, ending with the ledger's newest row" \
  "$LNDF" land value not-ticking matches 'no tick has started for 6[01] minutes, since ' ends "; $LNDN1"
_lnd_set pl print=0 hb=3600 row1 "paused=$LNDWHY"; _lnd_st "$LNDC"
_lnd_like "A12: a job both paused and not ticking reads not-ticking" "$LNDF" land value not-ticking
_lnd_set pl print=0 hb=600 "paused=$LNDWHY"; _lnd_st "$LNDC"
is "A13: a loaded job with a fresh heartbeat and a paused file reads paused, quoting its reason: nothing lands while it is paused" \
   "$(_lnd_row "$LNDF" land)" "$(_lnd_want value paused "$LNDWHY: nothing lands while it is paused")"
_lnd_set pl print=0 "paused=$LNDWHY"; _lnd_st "$LNDC"
is "A14: and with no heartbeat at all it reads the same paused row" \
   "$(_lnd_row "$LNDF" land)" "$(_lnd_want value paused "$LNDWHY: nothing lands while it is paused")"
_lnd_set pl print=0 hb=600 pausedempty; _lnd_st "$LNDC"
_lnd_like "A15: an empty paused file reads paused: no reason could be read" \
  "$LNDF" land value paused is 'no reason could be read: nothing lands while it is paused'
_lnd_set pl print=0; _lnd_st "$LNDC"
_lnd_like "A16: a loaded job, not paused, with no heartbeat is unknown, naming the Ld/heartbeat no tick has recorded" \
  "$LNDF" land unknown - holds "no tick has recorded a heartbeat in $LNDLD/heartbeat"
_lnd_set pl print=0 hbtext=soon; _lnd_st "$LNDC"
_lnd_like "A17: a heartbeat that reads soon is unknown: it holds no time this check can read" \
  "$LNDF" land unknown - holds 'holds no time this check can read'
_lnd_set pl print=0 hb=-3600; _lnd_st "$LNDC"
_lnd_like "A18: a heartbeat an hour ahead of the clock is unknown: it is dated seconds after this clock" \
  "$LNDF" land unknown - holds 'seconds after this clock'
_lnd_set pl print=0 hb=120 row1; _lnd_st "$LNDC"
_lnd_like "A19: a loaded job, not paused, whose heartbeat is two minutes old reads running, ending with the ledger's newest row" \
  "$LNDF" land value running starts 'launchd has felix.land.lp loaded, it is not paused, and its last tick started ' ends "; $LNDN1"
_lnd_set pl print=0 hb=120; _lnd_st "$LNDC"
_lnd_like "A20: and with no ledger its detail ends: the ledger has no row" "$LNDF" land value running ends '; the ledger has no row'
_lnd_set pl print=0 hb=2000; _lnd_st "$LNDC"
_lnd_like "A21: a heartbeat 2000 seconds old, inside the 2700-second bound, still reads running, not not-ticking" "$LNDF" land value running
LNDMARK=0

# ---- B11: read-only --------------------------------------------------------------------------------------
is "A22 (control): felix status changed nothing under the home, the memory root, the checkout or U/Library in A4-A21's runs, and asked launchctl only list and print" \
   "$(cat "$LNDO/newer")$(LC_ALL=C awk '$1 != "list" && $1 != "print" { print "launchctl " $0 }' "$LNDK/launchctl.all")" ""

# ---- B12: the heartbeat ------------------------------------------------------------------------------------
_lnd_set "paused=$LNDWHY"; : > "$LNDK/osascript.log"
_lndt0="$(date +%s)"; _lnd_land --tick; _lndt1="$(date +%s)"
is "A23: a paused felix land --tick exits 0 and writes Ld/heartbeat, one line of digits, its start between the times read around it" \
   "$LNDRC $(_lnd_hb "$_lndt0" "$_lndt1")" "0 fresh"
is "A24 (control): and that tick still writes one paused row and sends one notification" \
   "$(_lnd_rows paused) paused row(s), $(_lnd_calls osascript) osascript call(s)" "1 paused row(s), 1 osascript call(s)"
_lnd_set; mkdir -p "$LNDLD/lock"; sleep 120 & LNDSLP=$!
printf '%s\n' "$LNDSLP" > "$LNDLD/lock/pid"; : > "$LNDK/gh.log"
_lndt0="$(date +%s)"; _lnd_land --tick; _lndt1="$(date +%s)"
is "A25: a tick that finds the lock held by a live process still writes the heartbeat first" \
   "$(_lnd_hb "$_lndt0" "$_lndt1")" "fresh"
is "A26 (control): and that tick still writes no ledger row and asks gh nothing" \
   "$(_lnd_rows) ledger row(s), $(_lnd_calls gh) gh call(s)" "0 ledger row(s), 0 gh call(s)"
kill "$LNDSLP" 2>/dev/null; wait "$LNDSLP" 2>/dev/null
_lnd_set "paused=$LNDWHY"; mkdir -p "$LNDLD/heartbeat"; _lnd_land --tick
is "A27 (control): a paused tick whose heartbeat cannot be written, a directory standing there, still exits 0 and writes its paused row" \
   "$LNDRC, $(_lnd_rows paused) paused row(s)" "0, 1 paused row(s)"
_lnd_set; _lndo=""
for _lndw in "--status --tsv" "--pause x" "--resume"; do
  # shellcheck disable=SC2086
  _lnd_land $_lndw
  if [ -e "$LNDLD/heartbeat" ]; then _lndo="$_lndo [$_lndw: a heartbeat]"; else _lndo="$_lndo [$_lndw: none]"; fi
done
is "A28 (control): felix land --status --tsv, --pause x and --resume, in turn, write no heartbeat" \
   "$_lndo" " [--status --tsv: none] [--pause x: none] [--resume: none]"
_lnd_set pl print=0 "paused=$LNDWHY"; _lnd_land --tick; rm -f "$LNDLD/paused"; _lnd_st "$LNDC"
_lnd_like "A29: after a paused tick, with the pause then removed, the land row reads running" "$LNDF" land value running

# ---- B13 and B15: the landing badge ----------------------------------------------------------------------------
if command -v python3 >/dev/null 2>&1; then
  _lnd_set; _lnd_ss startup
  is "A30 (control): session start with no job and no ledger exits 0, its line is Felix: lp, and its context says nothing of landing" \
     "$LNDRC | $(_lnd_js "$LNDF" systemMessage) | $(_lnd_landing "$LNDF")" "0 | Felix: lp | no landing line"
  _lnd_set pl print=0 hb=600 "paused=$LNDWHY"; _lnd_st "$LNDC"
  _lndd="$(_lnd_row "$LNDF" land)"; _lndd="${_lndd#land"$LNDTAB"*"$LNDTAB"*"$LNDTAB"}"
  _lnd_ss startup
  is "A31: session start while the lander is paused adds the landing paused badge to that one line" \
     "$(_lnd_js "$LNDF" systemMessage)" "Felix: lp · landing paused"
  _lndw="Landing on green is paused: $_lndd"; _lndo="no such line"
  _lnd_js "$LNDF" additionalContext > "$LNDO/context.txt"
  while IFS= read -r _lndl || [ -n "$_lndl" ]; do [ "$_lndl" != "$_lndw" ] || _lndo="the line"; done < "$LNDO/context.txt"
  is "A32: and its context holds the line Landing on green is paused: followed by the land detail felix status --tsv prints in that state" \
     "$_lndo [$_lndw]" "the line [$_lndw]"
  # Combined with b03 (docs/2026-10-24-audit-fixes/wave-1-combine.md, S3): b03's waits also name a paused lander. Said once.
  _lndl="$(_lnd_js "$LNDF" systemMessage)"; case "$_lndl" in *"lander paused"*) _lndl=twice ;; *) _lndl=once ;; esac
  is "A32b: and the pause is said once, with how to end it: no lander paused token, no The lander is paused paragraph, and the line felix land --resume ends the pause." \
     "$_lndl $(LC_ALL=C grep -c 'The lander is paused' "$LNDO/context.txt") $(LC_ALL=C grep -cx 'felix land --resume ends the pause.' "$LNDO/context.txt")" "once 0 1"
  _lnd_set pl print=113; _lnd_ss startup
  _lndo="$(_lnd_js "$LNDF" systemMessage)"
  case "$_lndo" in *" · landing not-loaded") _lndo="ends with it" ;; esac
  is "A33: session start with the job not loaded ends its line with the landing not-loaded badge" "$_lndo" "ends with it"
  _lnd_set pl print=0 hb=3600 row1; _lnd_ss startup
  _lndo="$(_lnd_js "$LNDF" systemMessage)"
  case "$_lndo" in *" · landing not-ticking") _lndo="ends with it" ;; esac
  is "A34: session start with the job not ticking ends its line with the landing not-ticking badge" "$_lndo" "ends with it"
  _lndo=""
  for _lndw in "running:pl print=0 hb=120 row1" "not-installed:print=113 row1" "unknown liveness:pl print=0" "no launchd:pl"; do
    # shellcheck disable=SC2086
    _lnd_set ${_lndw#*:}
    case "$_lndw" in "no launchd:"*) LNDX=(S_UNAME=Linux) ;; esac
    _lnd_ss startup; LNDX=()
    _lndo="$_lndo [${_lndw%%:*}: $(_lnd_js "$LNDF" systemMessage), $(_lnd_landing "$LNDF")]"
  done
  is "A35 (control): running, not-installed, a liveness not known and no launchd add no badge to Felix: lp and no landing line to the context" \
     "$_lndo" " [running: Felix: lp, no landing line] [not-installed: Felix: lp, no landing line] [unknown liveness: Felix: lp, no landing line] [no launchd: Felix: lp, no landing line]"
  _lnd_set pl print=5; _lnd_ss startup
  is "A36 (control): session start with launchctl print exiting 5 still exits 0 and prints JSON" "$LNDRC $(_lnd_js "$LNDF" json)" "0 json"
  _lnd_set pl print=0 hb=600 "paused=$LNDWHY"; _lnd_ss resume
  is "A37 (control): a resume payload still prints nothing, exit 0, while the lander is paused" "$LNDRC [$(cat "$LNDF")]" "0 []"
else
  for _lndw in "A30 (control): session start with no job and no ledger exits 0, its line is Felix: lp, and its context says nothing of landing" \
               "A31: session start while the lander is paused adds the landing paused badge to that one line" \
               "A32: and its context holds the line Landing on green is paused: followed by the land detail felix status --tsv prints in that state" \
               "A32b: and the pause is said once, with how to end it: no lander paused token, no The lander is paused paragraph, and the line felix land --resume ends the pause." \
               "A33: session start with the job not loaded ends its line with the landing not-loaded badge" \
               "A34: session start with the job not ticking ends its line with the landing not-ticking badge" \
               "A35 (control): running, not-installed, a liveness not known and no launchd add no badge to Felix: lp and no landing line to the context" \
               "A36 (control): session start with launchctl print exiting 5 still exits 0 and prints JSON" \
               "A37 (control): a resume payload still prints nothing, exit 0, while the lander is paused"; do
    skip "$_lndw" "no python3 on PATH to read the hook's JSON"
  done
fi

# ---- B1 again, over every status run above -----------------------------------------------------------------
# Changed by the lane counter contract (docs/2026-10-29-lane-slice-0-plan.md, C6): the lane row was added at the end, as the status header allows.
_lndo=""
for _lndw in "$LNDO"/st/*; do
  [ -f "$_lndw" ] || continue
  _lndl="$(LC_ALL=C awk -F'\t' '{ printf "%s ", $1 }' "$_lndw")"
  [ "$_lndl" = "settings schedule pulse reach gate land hooks alerts icloud lane " ] || _lndo="$_lndo [run ${_lndw##*/}: rows $_lndl]"
  _lndl="$(LC_ALL=C awk -F'\t' 'NF != 4 || $2 !~ /^(value|none|unknown)$/ || ($2 != "value" && $3 != "-") || $4 == "" || $3 ~ / / { print NR ": " $0 }' "$_lndw")"
  [ -z "$_lndl" ] || _lndo="$_lndo [run ${_lndw##*/}: line $_lndl]"
done
is "A2: every felix status this part ran prints the ten rows in order, and no row breaks D16's shape (1100's awk)" "$_lndo" ""
_lnd_calm
# <<< status-lander-row
