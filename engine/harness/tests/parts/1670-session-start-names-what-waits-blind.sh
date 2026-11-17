# >>> session-start-names-what-waits
printf '\nsession start names what waits: PreToolUse faults, waiting PRs, a paused lander, deferred decisions, founder upkeep (audit b03, A29-A63, blind)\n'
# Blind, written on 2026-10-24 from the audit b03 contract alone ("session start
# names what waits", sections 2.2-2.4 and 2.6, assertions A29-A63), before the fix
# and without reading hooks/*, lib/*.sh or the felix CLI. Parts 0120, 0460, 0600,
# 0740, 1130 and 1600 and the fixture libs were read only for how their fixtures
# are built and their hooks driven. Part 1680 carries A1-A28.
#
# PreToolUse (FX-D): a home holding projects/demo with one deny row against a
# forced push, a repository whose .felix names demo, a memory root that exists and
# is empty, and per case a copy of the engine's harness to break, the hook run
# under env -i from the repository. Session start (FX-S): a home of its own
# holding project p, a repository bound to it by .felix, a memory root of its own,
# HOME a fixture directory, and claude, gh and graphify stubs first on PATH; the
# screen line and the context are read from the hook's JSON with python3.

# ---- helpers -----------------------------------------------------------------------
_nw_t() {   # SECONDS-AGO -> that moment as UTC ISO
  local t; t="$(( $(date +%s) - $1 ))"
  date -u -r "$t" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -d "@$t" +%Y-%m-%dT%H:%M:%SZ
}
_nw_d='[0123456789]'
_nw_when() {   # TIME -> "time" for an ISO time or -, else what it was
  case "$1" in
    -) printf 'time' ;;
    $_nw_d$_nw_d$_nw_d$_nw_d-$_nw_d$_nw_d-$_nw_d$_nw_d"T"$_nw_d$_nw_d:$_nw_d$_nw_d:$_nw_d$_nw_d"Z") printf 'time' ;;
    *) printf 'other[%s]' "$1" ;;
  esac
}
_nw_has() { case "$1" in *"$2"*) printf 'yes' ;; *) printf 'no[%s]' "$1" ;; esac; }
_nw_starts() { case "$1" in "$2"*) printf 'yes' ;; *) printf 'no[%s]' "$1" ;; esac; }
_nw_not2() { if [ "$1" = 2 ]; then printf '2'; else printf 'not 2'; fi; }

# ---- PreToolUse (FX-D) -------------------------------------------------------------
NWD="$TMP/b03-deny"; rm -rf "$NWD"; mkdir -p "$NWD"; NWD="$(cd "$NWD" && pwd -P)"
NWH="$NWD/home"; NWR="$NWD/repo"; NWPL="$NWD/plain"; NWU="$NWD/user"; NWM="$NWD/mem"; NWF="$NWM/hook-faults.log"
mkdir -p "$NWH/projects/demo" "$NWR" "$NWPL" "$NWU" "$NWM"
printf '{"name": "demo", "gate": "true"}\n' > "$NWH/projects/demo/project.json"
printf '# demo\n' > "$NWH/projects/demo/CLAUDE.md"
printf 'Bash\tgit push .*--force\tno forced pushes\n' > "$NWD/deny.keep"; cp "$NWD/deny.keep" "$NWH/projects/demo/deny.tsv"
( _fx_cd "$NWR" && git init -q -b main && printf 'demo\n' > .felix && printf 'a\n' > a.txt && git add -A \
  && git -c user.name=t -c user.email=t@t commit -qm one ) >/dev/null 2>&1
( _fx_cd "$NWPL" && git init -q -b main ) >/dev/null 2>&1
NWP="{\"session_id\":\"b03\",\"cwd\":\"$NWR\",\"hook_event_name\":\"PreToolUse\",\"tool_name\":\"Bash\",\"tool_input\":{\"command\":\"git push --force origin main\"}}"
NWPS="{\"session_id\":\"b03\",\"cwd\":\"$NWR\",\"hook_event_name\":\"PreToolUse\",\"tool_name\":\"Bash\",\"tool_input\":{\"command\":\"git status\"}}"
NWPT="{\"session_id\":\"b03\",\"cwd\":\"$NWR\",\"hook_event_name\":\"PreToolUse\",\"tool_input\":{\"command\":\"git push --force origin main\"}}"
NWPP="{\"session_id\":\"b03\",\"cwd\":\"$NWPL\",\"hook_event_name\":\"PreToolUse\",\"tool_name\":\"Bash\",\"tool_input\":{\"command\":\"git push --force origin main\"}}"
_nw_copy() {   # NAME -> a copy of the engine's harness, less its tests, at $NWD/NAME
  local e; rm -rf "$NWD/$1"; mkdir -p "$NWD/$1"
  for e in bin ecosystem.tsv felix hooks lib templates; do [ -e "$FROOT/harness/$e" ] && cp -R "$FROOT/harness/$e" "$NWD/$1/$e"; done
}
_nw_fresh() { rm -rf "$NWM"; mkdir -p "$NWM"; }
_nw_pre() {   # COPY [PAYLOAD [DIR [MEMR [WRAP]]]] -> the hook's status in NWRC
  local c="$1" p="${2:-$NWP}" d="${3:-$NWR}" m="${4:-$NWM}"
  if [ "${5:-}" = ulimit ]; then
    ( cd "$d" && printf '%s' "$p" | env -i PATH=/usr/bin:/bin:/usr/sbin:/sbin HOME="$NWU" FELIX_HOME="$NWH" FELIX_MEMORY="$m" \
        /bin/bash -c 'ulimit -u 1; exec /bin/bash "$0"' "$c/hooks/pre-tool" ) > "$NWD/pre.out" 2> "$NWD/pre.err"
  else
    ( cd "$d" && printf '%s' "$p" | env -i PATH=/usr/bin:/bin:/usr/sbin:/sbin HOME="$NWU" FELIX_HOME="$NWH" FELIX_MEMORY="$m" \
        /bin/bash "$c/hooks/pre-tool" ) > "$NWD/pre.out" 2> "$NWD/pre.err"
  fi
  NWRC=$?
}
_nw_rows() { if [ -f "$NWF" ]; then LC_ALL=C awk 'END { print NR }' "$NWF"; elif [ -e "$NWF" ]; then echo 'not a file'; else echo none; fi; }
_nw_fld() { LC_ALL=C awk -F'\t' -v k="$1" 'NR == 1 { printf "%s", (k == "NF" ? NF : $k) }' "$NWF" 2>/dev/null; }
_nw_one() { printf '%s|%s' "$NWRC" "$(_nw_rows)"; }   # status|rows

_nw_copy intact
_nw_fresh; _nw_pre "$NWD/intact"; NWa="$NWRC|$(LC_ALL=C awk 'END { print NR }' "$NWM/demo/says.log" 2>/dev/null)"
_nw_pre "$NWD/intact" "$NWPS"
is "b03 A29: with the harness intact a forced push is refused with a says.log row, git status is allowed, and neither leaves hook-faults.log (control)" \
   "$NWa|$NWRC|$(_nw_rows)" "2|1|0|none"

_nw_copy c30; mv "$NWD/c30/lib/deny-read.sh" "$NWD/c30/lib/deny-read 2.sh"
_nw_fresh; _nw_pre "$NWD/c30"; cp -R "$NWM" "$NWD/mem-a30"
is "b03 A30: with lib/deny-read.sh renamed the hook allows and writes one fault row of five fields: a time, pre-tool, demo, Bash, a reason naming deny-read.sh" \
   "$(_nw_one)|$(_nw_fld NF)|$(_nw_when "$(_nw_fld 1)")|$(_nw_fld 2)|$(_nw_fld 3)|$(_nw_fld 4)|$(_nw_has "$(_nw_fld 5)" deny-read.sh)" \
   "0|1|5|time|pre-tool|demo|Bash|yes"

_nw_copy c31; mv "$NWD/c31/lib/deny.sh" "$NWD/c31/lib/deny 2.sh"
_nw_fresh; _nw_pre "$NWD/c31"
is "b03 A31: with lib/deny.sh renamed the hook allows and writes one row, project -, reason lib/deny.sh did not load" \
   "$(_nw_one)|$(_nw_fld 3)|$(_nw_starts "$(_nw_fld 5)" "lib/deny.sh did not load")" "0|1|-|yes"

_nw_copy c32; mv "$NWD/c32/lib/resolve.sh" "$NWD/c32/lib/resolve 2.sh"
_nw_fresh; _nw_pre "$NWD/c32"
is "b03 A32: with lib/resolve.sh renamed the hook allows and writes one row, reason lib/resolve.sh did not load" \
   "$(_nw_one)|$(_nw_starts "$(_nw_fld 5)" "lib/resolve.sh did not load")" "0|1|yes"

_nw_copy c33; printf '%s\n' "_FELIX_DENY_READ='BEGIN { exit 3 }'" > "$NWD/c33/lib/deny-read.sh"
_nw_fresh; _nw_pre "$NWD/c33"
is "b03 A33: with the deny reader's awk exiting 3 the hook allows and writes one row whose reason says awk exited 3" \
   "$(_nw_one)|$(_nw_has "$(_nw_fld 5)" "awk exited 3")" "0|1|yes"

_nw_copy c34; printf '%s\n' '_felix_deny_first() { : "$_felix_b03_unbound"; }' >> "$NWD/c34/lib/deny.sh"
_nw_fresh; _nw_pre "$NWD/c34"
is "b03 A34: an unbound variable in the matcher ends the hook with a status that is not 2 and one row saying the hook ended with a status before a verdict" \
   "$(_nw_not2 "$NWRC")|$(_nw_rows)|$(_nw_starts "$(_nw_fld 5)" "the hook ended with status ")" "not 2|1|yes"

_nw_copy c35; printf '%s\n' ': "$_felix_b03_unbound_load"' >> "$NWD/c35/lib/deny.sh"
_nw_fresh; _nw_pre "$NWD/c35"
is "b03 A35: an unbound variable while lib/deny.sh loads ends the hook with a status that is not 2 and one row" \
   "$(_nw_not2 "$NWRC")|$(_nw_rows)" "not 2|1"

if [ "$(id -u)" = 0 ]; then
  skip "b03 A36: with no process to spare (ulimit -u 1) the hook ends with a status that is not 2 and one row saying it ended before a verdict" "the suite runs as root, whom ulimit -u does not bind"
else
  _nw_fresh; _nw_pre "$NWD/intact" "$NWP" "$NWR" "$NWM" ulimit
  is "b03 A36: with no process to spare (ulimit -u 1) the hook ends with a status that is not 2 and one row saying it ended before a verdict" \
     "$(_nw_not2 "$NWRC")|$(_nw_rows)|$(_nw_when "$(_nw_fld 1)")|$(_nw_starts "$(_nw_fld 5)" "the hook ended with status ")" "not 2|1|time|yes"
fi

rm -f "$NWH/projects/demo/deny.tsv"; mkdir -p "$NWH/projects/demo/deny.tsv"
_nw_fresh; _nw_pre "$NWD/intact"
is "b03 A37: deny.tsv a directory: the hook allows and writes one row, reason deny.tsv is not a readable file" \
   "$(_nw_one)|$(_nw_starts "$(_nw_fld 5)" "deny.tsv is not a readable file")" "0|1|yes"
rm -rf "$NWH/projects/demo/deny.tsv"; cp "$NWD/deny.keep" "$NWH/projects/demo/deny.tsv"

_nw_fresh; _nw_pre "$NWD/intact" "$NWPT"
is "b03 A38: a payload with no tool_name is allowed with one row, reason the payload names no tool" \
   "$(_nw_one)|$(_nw_starts "$(_nw_fld 5)" "the payload names no tool")" "0|1|yes"

_nw_fresh; _nw_pre "$NWD/c30" "$NWPP" "$NWPL"
is "b03 A39: a directory no project governs writes no fault row, even with deny-read.sh renamed (control)" "$(_nw_one)" "0|none"

rm -f "$NWH/projects/demo/deny.tsv"; _nw_fresh; _nw_pre "$NWD/intact"
is "b03 A40: a project with no deny.tsv writes no fault row (control)" "$(_nw_one)" "0|none"
cp "$NWD/deny.keep" "$NWH/projects/demo/deny.tsv"

rm -rf "$NWD/nomem"; _nw_pre "$NWD/c30" "$NWP" "$NWR" "$NWD/nomem"
is "b03 A41: with FELIX_MEMORY naming a directory that is not there, a fault writes nothing and creates nothing, and the hook exits 0" \
   "$NWRC|$([ -e "$NWD/nomem" ] && echo created || echo absent)" "0|absent"

_nw_match() {   # COPY CMD -> stdout|status of felix_deny_match, sourced from COPY's lib/deny.sh
  ( cd "$NWR" || exit 97; FELIX_MEMORY="$NWD/mem42"; . "$1/lib/deny.sh" >/dev/null 2>&1
    o="$(felix_deny_match "$NWH/projects/demo" Bash "$2" 2>/dev/null)"; r=$?; printf '%s|%s' "$r" "$o" )
}
NWa="$(_nw_match "$NWD/c30" 'git push --force origin main')"
is "b03 A42: sourced with no deny-read.sh beside it, felix_deny_match exits 2 naming deny-read.sh; intact, it exits 0 with the reason for a forced push and 1 for git status" \
   "${NWa%%|*}|$(_nw_has "${NWa#*|}" deny-read.sh)|$(_nw_match "$NWD/intact" 'git push --force origin main')|$(_nw_match "$NWD/intact" 'git status')" \
   "2|yes|0|no forced pushes|1|"

# ---- session start (FX-S) -----------------------------------------------------------
NWS="$TMP/b03-start"; rm -rf "$NWS"; mkdir -p "$NWS"; NWS="$(cd "$NWS" && pwd -P)"
NWSH="$NWS/home"; NWSP="$NWS/home/projects/p"; NWSR="$NWS/repo"; NWSU="$NWS/user"; NWSM="$NWS/mem"; NWSB="$NWS/bin"
NWSL="$NWSM/p/land"; NWSQ="$NWSM/p/overnight"; NWSF="$NWSM/hook-faults.log"
mkdir -p "$NWSP" "$NWSR" "$NWSU" "$NWSM/p" "$NWSB"
printf '{"name": "p", "gate": "true"}\n' > "$NWSP/project.json"; printf '# p\n' > "$NWSP/CLAUDE.md"
( _fx_cd "$NWSR" && git init -q -b main && printf 'p\n' > .felix && printf 'a\n' > a.txt && git add -A \
  && git -c user.name=t -c user.email=t@t commit -qm one && printf 'b\n' > a.txt \
  && git -c user.name=t -c user.email=t@t commit -qam two ) >/dev/null 2>&1
printf '#!/bin/sh\ncase "$*" in "plugin list --json --available") printf "[]\\n"; exit 0 ;; "mcp list"|"plugin list"|"plugin marketplace list") exit 0 ;; esac\nexit 2\n' > "$NWSB/claude"
printf '#!/bin/sh\nexit 0\n' > "$NWSB/gh"; printf '#!/bin/sh\nexit 0\n' > "$NWSB/graphify"; chmod +x "$NWSB/claude" "$NWSB/gh" "$NWSB/graphify"
_nw_start() {   # [SESSION [HOME [REPO [MEMR]]]] -> NWSRC, NWJ (the JSON parsed: ok or bad), NWC (context), NWSS (screen line)
  local id="${1:-b03-start}" h="${2:-$NWSH}" r="${3:-$NWSR}" m="${4:-$NWSM}" o
  o="$( cd "$r" && printf '{"hook_event_name":"SessionStart","source":"startup","session_id":"%s"}' "$id" \
        | env -u CLAUDE_CODE_SESSION_ID -u FELIX_HOME_DIR HOME="$NWSU" FELIX_HOME="$h" FELIX_MEMORY="$m" \
            PATH="$NWSB:$PATH" CLAUDE_PLUGIN_ROOT="$FROOT" "$FROOT/harness/hooks/session-start" 2>"$NWS/start.err" )"; NWSRC=$?
  printf '%s' "$o" > "$NWS/start.json"
  NWJ="$(python3 -c 'import json, sys
try: d = json.load(open(sys.argv[1]))
except Exception: print("bad"); sys.exit(0)
print("ok" if isinstance(d, dict) else "bad")' "$NWS/start.json" 2>/dev/null)"
  NWC="$(_nw_json additionalContext)"; NWSS="$(_nw_json systemMessage)"
}
_nw_json() { python3 -c 'import json, sys
try: d = json.load(open(sys.argv[2]))
except Exception: sys.exit(3)
sys.stdout.write(d.get(sys.argv[1]) or (d.get("hookSpecificOutput") or {}).get(sys.argv[1]) or "")' "$1" "$NWS/start.json" 2>/dev/null; }
_nw_in() { case "$NWC" in *"$1"*) printf 'yes' ;; *) printf 'no' ;; esac; }
_nw_c() { printf '%s\n' "$NWC" | LC_ALL=C awk -v p="$1" 'index($0, p) == 1 { n++ } END { print n + 0 }'; }
_nw_tok() { case "$NWSS" in *"$1"|*"$1 · "*|*"$1 ("*) printf 'yes' ;; *) printf 'no[%s]' "$NWSS" ;; esac; }
_nw_lacks() { case "$NWSS" in *"$1"*) printf 'has[%s]' "$NWSS" ;; *) printf 'none' ;; esac; }
_nw_clear() { rm -rf "$NWSL" "$NWSQ" "$NWSF"; }
_nw_sha() { printf '%04d%s' "$1" c0ffeec0ffeec0ffeec0ffeec0ffeec0ffee; }
_nw_lrow() { mkdir -p "$NWSL"; printf '%s\t%s\t%s\t%s\t-\t0\t%s\n' "$1" "$2" "$3" "$(_nw_sha "$3")" "$4" >> "$NWSL/ledger.tsv"; }   # TIME EVENT PR DETAIL
NWHDR="Pull requests waiting longer than four hours, as the lander last saw them (felix land --prs says more):"
NWNC="no checkout holds the gated head"

# A43: the PRs whose newest row is a waiting row less than 26 hours old.
_nw_a43() {
  NWT30="$(_nw_t 108000)"
  _nw_lrow "$NWT30" session 425 "$NWNC"
  _nw_lrow "$(_nw_t 7200)" waiting 425 "waits on a session since $NWT30: session: $NWNC"
  _nw_lrow "$NWT30" waiting 7 "waits on a session since $NWT30: session: $NWNC"
  _nw_lrow "$(_nw_t 3600)" waiting 9 "waits on a session since $NWT30: session: $NWNC"
  _nw_lrow "$(_nw_t 1800)" landed 9 "merged"
}
_nw_clear; _nw_a43; _nw_start
NWa="$(printf '%s\n' "$NWC" | LC_ALL=C awk 'index($0, "  #") == 1 { print substr($0, 1, 32); exit }')"
is "b03 A43: session start lists only the PR whose newest row is a waiting row under 26 hours old, under its header, and the screen says PRs waiting: 1" \
   "$(_nw_c "$NWHDR")|$(_nw_c '  #')|$NWa|$(_nw_tok ' · PRs waiting: 1')" "1|1|  #425 waits on a session since |yes"

_nw_clear; for NWk in 7 6 5 4 3 2 1; do _nw_lrow "$(_nw_t 3600)" waiting "$NWk" "waits on a session since $(_nw_t 18000): session: $NWNC"; done
_nw_start
NWa="$(printf '%s\n' "$NWC" | LC_ALL=C awk 'index($0, "  #") == 1 { s = substr($0, 4); sub(/ .*/, "", s); printf "%s%s", c, s; c = " " }')"
NWb="$(printf '%s\n' "$NWC" | LC_ALL=C awk 'index($0, "  #") == 1 { l = NR } $0 == "  and 2 more: felix land --prs" { a = NR } END { print (a && a == l + 1) ? "after" : "not after" }')"
is "b03 A44: seven waiting PRs show the first five in ascending order, then and 2 more: felix land --prs, and the screen counts seven" \
   "$NWa|$NWb|$(_nw_tok ' · PRs waiting: 7')" "1 2 3 4 5|after|yes"

_nw_clear; _nw_start
is "b03 A45: with no land directory there is no waiting-PR header and no PRs waiting token (control)" \
   "$(_nw_c "$NWHDR")|$(_nw_lacks 'PRs waiting')" "0|none"

_nw_clear; mkdir -p "$NWSL/ledger.tsv"; _nw_start
is "b03 A46: a ledger that is a directory is said to be unreadable, naming its path, the screen says PRs waiting: unknown, and the hook exits 0 with one JSON object" \
   "$(_nw_in 'Which pull requests wait could not be read:')|$(_nw_in "$NWSL/ledger.tsv")|$(_nw_tok ' · PRs waiting: unknown')|$NWSRC|$NWJ" "yes|yes|yes|0|ok"

# A47: a paused lander.
_nw_clear; mkdir -p "$NWSL"; printf 'held for the test\nsecond line\n' > "$NWSL/paused"; _nw_start
NWa="$(_nw_in "$(printf 'The lander is paused, so nothing merges with nobody present: held for the test\nfelix land --resume ends the pause.')")"
NWb="$(_nw_in 'second line')|$(_nw_tok ' · lander paused')"
: > "$NWSL/paused"; _nw_start
is "b03 A47: a paused lander is named with the first line of its reason and how to resume, not its second line, the screen says lander paused, and an empty reason reads no reason given" \
   "$NWa|$NWb|$(_nw_in 'The lander is paused, so nothing merges with nobody present: no reason given')" "yes|no|yes|yes"

# A48-A50: decisions deferred overnight.
NWQ1="$(printf '1790169800\tquestion\tb\t-\n1790169788\tapproval\ta\t-')"
NWDEF="$(printf '2 decision(s) deferred overnight wait on the founder, the oldest from 2026-09-23 (UTC).\nfelix overnight --report reads them back, and felix overnight --clear clears them once read.')"
_nw_clear; mkdir -p "$NWSQ"; printf '%s\n' "$NWQ1" > "$NWSQ/deferred.tsv"; _nw_start bystander
is "b03 A48: with no night, a session start names the two deferred decisions, the oldest date, how to read and clear them, and the screen says deferred for you: 2" \
   "$(_nw_in "$NWDEF")|$(_nw_tok ' · deferred for you: 2')" "yes|yes"

_nw_ov() { ( export FELIX_MEMORY="$NWSM"; . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/overnight.sh"; "$@" ) 2>/dev/null; }
NWDIR="$(_nw_ov felix_overnight_direction | LC_ALL=C awk '{ if (length($0) > length(m)) m = $0 } END { print m }')"
_nw_ov felix_overnight_start "$NWSP" 8 12 s1 "a night for b03" >/dev/null
_nw_start s1; NWa="$(_nw_in "$NWDIR")|$(_nw_in 'Granted to this session:')|$(_nw_in "$NWDEF")"
_nw_start bystander
is "b03 A49: with a night granted to s1, s1 gets the direction, its grant and the deferred paragraph, and a bystander the deferred paragraph and no line of the direction" \
   "$([ "${#NWDIR}" -ge 20 ] && echo direction)|$NWa|$(_nw_in "$NWDEF")|$(_nw_in "$NWDIR")" "direction|yes|yes|yes|yes|no"
NWOD="$(_nw_ov felix_overnight_dir "$NWSP")"; [ -z "$NWOD" ] || rm -rf "$NWOD/active" "$NWOD/nights" "$NWOD/marks" "$NWOD/grants"

_nw_clear; mkdir -p "$NWSQ/deferred.tsv"; _nw_start
NWa="$(_nw_in 'Decisions deferred overnight could not be read:')|$(_nw_tok ' · deferred for you: unknown')"
rm -rf "$NWSQ/deferred.tsv"; printf 'x\tquestion\tb\t-\n' > "$NWSQ/deferred.tsv"; _nw_start
is "b03 A50: a deferred queue that is a directory is said to be unreadable and counted unknown; a row with no all-digit time reads the oldest from an unknown date" \
   "$NWa|$(_nw_in 'the oldest from an unknown date.')" "yes|yes|yes"

# A51-A54: PreToolUse faults, read from MEMR/hook-faults.log.
_nw_faults() {   # [EXTRA-ROW] -> A51's four rows, and EXTRA after them
  NWT1="$(_nw_t 3600)"
  { printf '%s\tpre-tool\tp\tBash\tlib/deny.sh did not load\n' "$NWT1"
    printf '%s\tpre-tool\tp\tBash\told\n' "$(_nw_t 691200)"
    printf '%s\tpre-tool\tother\tBash\ttheirs\n' "$(_nw_t 7200)"
    printf -- '-\tpre-tool\t-\t-\tthe hook ended with status 128 before a verdict\n'
    [ -z "${1:-}" ] || printf '%s\n' "$1"; } > "$NWSF"
}
_nw_clear; _nw_faults; _nw_start
is "b03 A51: two faults count, this project's in 7 days and a - row timed by the file: the newest at a time not recorded, the log named, the screen says calls not judged: 2" \
   "$(_nw_in 'PreToolUse could not judge 2 tool call(s) in the last 7 days')|$(_nw_in 'The newest, at a time not recorded: the hook ended with status 128 before a verdict.')|$(_nw_in "$NWSF")|$(_nw_tok ' · calls not judged: 2')" \
   "yes|yes|yes|yes"

_nw_clear; _nw_faults "$(printf '%s\tpre-tool\tp\tBash\tolder\n' "$(_nw_t 777600)")"; _nw_start
is "b03 A52: a - row takes the time of the row below it, nine days old, so one fault counts and the newest is the one-hour row" \
   "$(_nw_in 'could not judge 1 tool call(s)')|$(_nw_in "The newest, $NWT1: lib/deny.sh did not load.")" "yes|yes"

_nw_clear; printf -- '-\tpre-tool\t-\t-\tthe hook ended with status 128 before a verdict\n' > "$NWSF"
NWa="$(( $(date +%s) - 691200 ))"
touch -t "$(date -r "$NWa" +%Y%m%d%H%M.%S 2>/dev/null || date -d "@$NWa" +%Y%m%d%H%M.%S)" "$NWSF"; _nw_start
is "b03 A53: a lone - row in a log last written eight days ago counts nothing: no paragraph, no token" \
   "$(_nw_in 'PreToolUse could not judge')|$(_nw_lacks 'calls not judged')" "no|none"

_nw_clear; mkdir -p "$NWSF"; _nw_start
is "b03 A54: a fault log that is a directory is said to be unreadable, and the screen says calls not judged: unknown" \
   "$(_nw_in 'Whether PreToolUse judged every call could not be read:')|$(_nw_tok ' · calls not judged: unknown')" "yes|yes"
rm -rf "$NWSF"

_nw_start b03-a55 "$NWH" "$NWR" "$NWD/mem-a30"
is "b03 A55: the fault A30's broken reader wrote is counted by the next session start of demo: calls not judged: 1" \
   "$(_nw_tok ' · calls not judged: 1')" "yes"

# A56-A58: maintenance the founder owns.
NWFL="Due, and waiting on the founder's yes rather than a session: "
_nw_mt() {   # [log] -> the founder row and the weekly row; with log, snapshot ran 28 days ago
  printf 'snapshot\t14\tfounder\tbring the snapshot up\nweekly\t7\talways\ta cleanup\n' > "$NWSP/maintenance.tsv"; rm -f "$NWSP/maintenance.log"
  local t; t="$(( $(date +%s) - 2419260 ))"
  [ -z "${1:-}" ] || printf 'snapshot\t%s\t%s\n' "$t" "$(date -u -r "$t" +%Y-%m-%d 2>/dev/null || date -u -d "@$t" +%Y-%m-%d)" > "$NWSP/maintenance.log"
}
_nw_maint() { ( cd "$NWSR" && env -u FELIX_HOME_DIR HOME="$NWSU" FELIX_HOME="$NWSH" FELIX_MEMORY="$NWSM" PATH="$NWSB:$PATH" "$FELIX" maintenance 2>&1 ); }
_nw_clear; _nw_mt log; _nw_start
NWa="$(printf '%s\n' "$NWC" | LC_ALL=C awk 'index($0, "Maintenance due:") == 1 { print; exit }')"
NWb="$(printf '%s' "$NWSS" | sed -n 's/.*· \([0-9][0-9]*\) due.*/\1/p')"
is "b03 A56: the founder's due row leaves the Maintenance due line, is named as waiting on his yes with its age and cadence, and the screen counts both as due, yours: snapshot" \
   "$NWa|$(_nw_in "${NWFL}snapshot (28 days since it last ran, every 14)")|$(_nw_tok ' · 2 due (yours: snapshot)')|$NWb|$(_nw_maint | grep -c '^  DUE ')" \
   "Maintenance due: weekly|yes|yes|2|2"

printf 'snapshot\t14\tfounder\tbring the snapshot up\n' > "$NWSP/maintenance.tsv"; _nw_start
NWa="$(_nw_c 'Maintenance due:')|$(_nw_in 'Do them on one branch')|$(_nw_in "${NWFL}snapshot (28 days since it last ran, every 14)")|$(_nw_tok ' · 1 due (yours: snapshot)')"
rm -f "$NWSP/maintenance.log"; _nw_start
is "b03 A57: with only the founder's row due there is no Maintenance due or one-branch line, the founder line and 1 due (yours: snapshot); never run, it reads never run, every 14" \
   "$NWa|$(_nw_in "${NWFL}snapshot (never run, every 14)")" "0|no|yes|yes|yes"

printf 'weekly\t7\talways\ta cleanup\n' > "$NWSP/maintenance.tsv"; _nw_clear; _nw_start
is "b03 A58: with none of this batch's state, no founder line and the screen line is Felix: p, at most N due and new tooling found (control)" \
   "$(_nw_c "Due, and waiting on the founder's yes")|$(printf '%s\n' "$NWSS" | LC_ALL=C grep -Ec '^Felix: p( · [0123456789]+ due)?( · new tooling found)?$')|$(printf '%s\n' "$NWSS" | LC_ALL=C awk 'END { print NR }')" \
   "0|1|1"

# A59: everything at once.
_nw_clear; _nw_a43; printf 'held for the test\nsecond line\n' > "$NWSL/paused"
mkdir -p "$NWSQ"; printf '%s\n' "$NWQ1" > "$NWSQ/deferred.tsv"; _nw_faults; _nw_start
_nw_at() { local p; case "$NWSS" in *"$1"*) p="${NWSS%%"$1"*}"; printf '%s' "$(( ${#p} + 1 ))" ;; *) printf '0' ;; esac; }
NWa="$(_nw_at ' · lander paused') $(_nw_at ' · PRs waiting: 1') $(_nw_at ' · deferred for you: 2') $(_nw_at ' · calls not judged: 2')"
NWa="$(printf '%s' "$NWa" | LC_ALL=C awk '{ print ($1 > 0 && $1 < $2 && $2 < $3 && $3 < $4) ? "in order" : "out of order: " $0 }')"
NWb="$(printf '%s\n' "$NWC" | LC_ALL=C awk -v a="Pull requests waiting longer than four hours" -v b="The lander is paused, so nothing merges" \
        -v c="2 decision(s) deferred overnight" -v d="PreToolUse could not judge" '
  index($0, "Memory: ") == 1 && !m { m = NR } index($0, "Read before planning:") == 1 && !r { r = NR }
  index($0, a) == 1 && !x1 { x1 = NR } index($0, b) == 1 && !x2 { x2 = NR }
  index($0, c) == 1 && !x3 { x3 = NR } index($0, d) == 1 && !x4 { x4 = NR }
  function at(x) { return (m && r && x > m && x < r) ? "between" : "out(" m "," x "," r ")" }
  END { print at(x1) " " at(x2) " " at(x3) " " at(x4) }')"
is "b03 A59: with all four at once the screen tokens come in the contract's order, on one line, and each paragraph sits after Memory: and before Read before planning:" \
   "$NWa|$(printf '%s\n' "$NWSS" | LC_ALL=C awk 'END { print NR }')|$NWb" "in order|1|between between between between"
_nw_clear

# A60, A61: the libraries on A56's table.
_nw_mt log; : > "$NWSP/routes.tsv"; : > "$NWSP/stack.tsv"
_nw_lib() { ( cd "$NWSR" && export FELIX_HOME="$NWSH" FELIX_MEMORY="$NWSM" HOME="$NWSU"
              . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/detect.sh"; . "$FROOT/harness/lib/stack.sh"
              . "$FROOT/harness/lib/maintenance.sh"; "$@" ) 2>/dev/null; }
NWa="$(_nw_lib felix_maint_status "$NWSP" "$NWSR" | LC_ALL=C awk -F'\t' '$2 == "snapshot"')"
is "b03 A60: felix_maint_status reads the founder row as due like an always row, felix_maint_unreachable lists nothing, felix maintenance prints it DUE" \
   "$NWa|$(_nw_lib felix_maint_unreachable "$NWSP")|$(_nw_maint | grep -c '^  DUE     snapshot')" \
   "$(printf 'due\tsnapshot\t28\t14\tbring the snapshot up')||1"
NWa="$( cd "$NWSR" && export FELIX_HOME="$NWSH" FELIX_MEMORY="$NWSM" HOME="$NWSU"
        . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/detect.sh"
        . "$FROOT/harness/lib/verify.sh"; . "$FROOT/harness/lib/review.sh"
        . "$FROOT/harness/lib/escape.sh"; . "$FROOT/harness/lib/obligations.sh"; . "$FROOT/harness/lib/evidence.sh"
        . "$FROOT/harness/lib/maintenance.sh"; . "$FROOT/harness/lib/stack.sh"
        . "$FROOT/harness/lib/ready.sh"; . "$FROOT/harness/lib/ledger.sh"
        . "$FROOT/harness/lib/coverage.sh"; . "$FROOT/harness/lib/deny.sh"
        . "$FROOT/harness/lib/route.sh"; . "$FROOT/harness/lib/next.sh"
        felix_next "$NWSP" "$NWSH" "$NWSR" HEAD~1 2>/dev/null )"
is "b03 A61: felix next gives the founder row's upkeep its owner founder, and the weekly row's felix" \
   "$(printf '%s\n' "$NWa" | LC_ALL=C awk -F'\t' '$1 == 4 && index($3, "upkeep due: snapshot") == 1 { o = o $2 } $1 == 4 && index($3, "upkeep due: weekly") == 1 { w = w $2 } END { print o "|" w }')" \
   "founder|felix"

# A62, A63: this tree.
NWa="$(cd "$REAL_HARNESS/../.." && pwd)/projects/felix/maintenance.tsv"
is "b03 A62: this tree's felix maintenance table gives snapshot the trigger founder and keeps always on deployed, discover, promote, lessons, graphify and handoff" \
   "$(LC_ALL=C awk -F'\t' '/^#/ { next } $1 == "snapshot" { s = $3 } $1 ~ /^(deployed|discover|promote|lessons|graphify|handoff)$/ { a = a " " $1 ":" $3 } END { print s "|" a }' "$NWa" 2>/dev/null)" \
   "founder| deployed:always discover:always promote:always lessons:always graphify:always handoff:always"
NWa="$(LC_ALL=C awk 'END { print NR }' "$REAL_HARNESS/hooks/session-start" 2>/dev/null)"; NWb="$(LC_ALL=C awk 'END { print NR }' "$REAL_HARNESS/lib/green-tick.sh" 2>/dev/null)"
is "b03 A63: hooks/session-start is at most 780 lines and lib/green-tick.sh at most 500 (control)" \
   "$([ "${NWa:-9999}" -le 780 ] && echo ok || echo "$NWa")|$([ "${NWb:-9999}" -le 500 ] && echo ok || echo "$NWb")" "ok|ok"

# ---- review round (A64-A70) ---------------------------------------------------------
# Written on 2026-10-26 from the contract's section 9 alone (B36-B38), without
# reading the code under test. A64, A65: two and three founder rows, under
# whichever awk is first on PATH (BWK refuses a newline inside a -v value). A66,
# A67: the time of a fault row the hook really writes under this machine's
# /bin/bash (3.2 on macOS, which has no EPOCHSECONDS; on a bash that has it, as
# CI's does, both are controls). A68-A70: a wait whose rows change after its
# waiting row.
_nw_err() { case "$(cat "$NWS/start.err" 2>/dev/null)" in *"$1"*) printf 'has' ;; *) printf 'none' ;; esac; }
_nw_iso() {   # TIME -> iso for a UTC ISO time, else what it was
  case "$1" in
    $_nw_d$_nw_d$_nw_d$_nw_d-$_nw_d$_nw_d-$_nw_d$_nw_d"T"$_nw_d$_nw_d:$_nw_d$_nw_d:$_nw_d$_nw_d"Z") printf 'iso' ;;
    *) printf 'other[%s]' "$1" ;;
  esac
}
_nw_near() {   # ISO -> now when it lies within 300 s of now (ISO UTC times order as strings)
  LC_ALL=C awk -v lo="$(_nw_t 300)" -v t="$1" -v hi="$(_nw_t -300)" 'BEGIN { print (t "" >= lo "" && t "" <= hi "") ? "now" : "not now[" t "]" }'
}
rm -f "$NWSP/routes.tsv" "$NWSP/stack.tsv" "$NWSP/maintenance.log"; _nw_clear
printf 'snapshot\t14\tfounder\tbring the snapshot up\nrelease\t14\tfounder\tcut a release\nweekly\t7\talways\ta cleanup\n' > "$NWSP/maintenance.tsv"
_nw_start
NWa="$(printf '%s\n' "$NWC" | LC_ALL=C awk 'index($0, "Maintenance due:") == 1 { print; exit }')"
NWb="$(printf '%s' "$NWSS" | LC_ALL=C sed -n 's/.*· \([0123456789][0123456789]*\) due.*/\1/p')"
is "b03 A64: two founder rows and one always row due: Maintenance due names weekly, the founder line names both in table order, the screen says 3 due (yours: snapshot, release), and no awk newline error is printed" \
   "$NWa|$(_nw_in "${NWFL}snapshot (never run, every 14), release (never run, every 14)")|$(_nw_tok ' · 3 due (yours: snapshot, release)')|$NWb|$(_nw_maint | grep -c '^  DUE ')|$(_nw_err 'newline in string')" \
   "Maintenance due: weekly|yes|yes|3|3|none"

printf 'snapshot\t14\tfounder\tbring the snapshot up\nrelease\t14\tfounder\tcut a release\naudit\t30\tfounder\tread the audit\n' > "$NWSP/maintenance.tsv"
NWa="$(( $(date +%s) - 2419260 ))"
printf 'snapshot\t%s\t%s\n' "$NWa" "$(date -u -r "$NWa" +%Y-%m-%d 2>/dev/null || date -u -d "@$NWa" +%Y-%m-%d)" > "$NWSP/maintenance.log"
_nw_start
is "b03 A65: three founder rows due and no other: no Maintenance due line, the founder line names all three in table order with their ages, and the screen says 3 due (yours: snapshot, release, audit)" \
   "$(_nw_c 'Maintenance due:')|$(_nw_in "${NWFL}snapshot (28 days since it last ran, every 14), release (never run, every 14), audit (never run, every 30)")|$(_nw_tok ' · 3 due (yours: snapshot, release, audit)')|$(_nw_err 'newline in string')" \
   "0|yes|yes|none"
rm -f "$NWSP/maintenance.tsv" "$NWSP/maintenance.log"

_nw_fresh; _nw_pre "$NWD/c30"; NWa="$(_nw_fld 1)"
is "b03 A66: a fault the hook meets under this machine's /bin/bash is written with its UTC ISO time, within five minutes of now, never -" \
   "$(_nw_one)|$(_nw_iso "$NWa")|$(_nw_near "$NWa")" "0|1|iso|now"

_nw_fresh; _nw_pre "$NWD/c30"; _nw_pre "$NWD/c30"; _nw_pre "$NWD/c30"
LC_ALL=C awk -F'\t' -v OFS='\t' -v t="$(_nw_t 1728000)" '$1 != "-" { $1 = t } { print }' "$NWF" > "$NWD/faults.old" 2>/dev/null \
  && cat "$NWD/faults.old" > "$NWF"
NWa="$(( $(date +%s) - 1728000 ))"
touch -t "$(date -r "$NWa" +%Y%m%d%H%M.%S 2>/dev/null || date -d "@$NWa" +%Y%m%d%H%M.%S)" "$NWF"
_nw_pre "$NWD/c30"; NWb="$(LC_ALL=C awk -F'\t' 'NR == 4 { printf "%s", $1 }' "$NWF" 2>/dev/null)"
_nw_start b03-a67 "$NWH" "$NWR" "$NWM"
is "b03 A67: three faults the hook wrote twenty days ago and one written now: session start counts one in the last 7 days, gives the newest its recorded time, and the screen says calls not judged: 1" \
   "$(_nw_rows)|$(_nw_in 'PreToolUse could not judge 1 tool call(s) in the last 7 days')|$(_nw_in "The newest, $NWb: ")|$(_nw_in 'at a time not recorded')|$(_nw_tok ' · calls not judged: 1')" \
   "4|yes|yes|no|yes"

_nw_clear; NWT30="$(_nw_t 108000)"
_nw_lrow "$NWT30" session 425 "$NWNC"
_nw_lrow "$(_nw_t 72000)" waiting 425 "waits on a session since $NWT30: session: $NWNC"
_nw_lrow "$(_nw_t 68400)" skip 425 "conflicting with main"
_nw_lrow "$(_nw_t 3600)" session 425 "$NWNC"
_nw_start
is "b03 A68: #425, waiting 30 hours, its waiting row 20 hours old and followed at the same head by a conflicting skip and a session row, is listed under the header and the screen says PRs waiting: 1" \
   "$(_nw_c "$NWHDR")|$(_nw_c '  #')|$(_nw_c "  #425 waits on a session since $NWT30")|$(_nw_tok ' · PRs waiting: 1')" "1|1|1|yes"

_nw_clear; NWa="waits on a session since $NWT30: session: $NWNC"
_nw_lrow "$(_nw_t 7200)" waiting 31 "$NWa"; _nw_lrow "$(_nw_t 3600)" skip 31 "a draft"
_nw_lrow "$(_nw_t 7200)" waiting 32 "$NWa"
printf '%s\tsession\t32\t%s\t-\t1\t%s\n' "$(_nw_t 3600)" "$(_nw_sha 9932)" "$NWNC" >> "$NWSL/ledger.tsv"
_nw_lrow "$(_nw_t 7200)" waiting 33 "$NWa"; _nw_lrow "$(_nw_t 3600)" skip 33 "labelled felix:hold"
_nw_lrow "$(_nw_t 97200)" waiting 34 "$NWa"; _nw_lrow "$(_nw_t 3600)" session 34 "$NWNC"
_nw_start
is "b03 A69: a waiting row followed by a draft skip, by a row at another head or by a felix:hold skip, and a waiting row 27 hours old followed by a session row, list nothing (control)" \
   "$(_nw_c "$NWHDR")|$(_nw_c '  #')|$(_nw_lacks 'PRs waiting')" "0|0|none"

_nw_clear; NWT10="$(_nw_t 36000)"
_nw_lrow "$NWT10" session 41 "$NWNC"
_nw_lrow "$(_nw_t 18000)" waiting 41 "waits on a session since $NWT10: session: $NWNC"
_nw_lrow "$(_nw_t 7200)" refused 41 "blocker: the receipt is stale [main 0123abcd]"
_nw_lrow "$NWT10" skip 42 "labelled needs-founder"
_nw_lrow "$(_nw_t 18000)" waiting 42 "waits on the founder since $NWT10: skip: labelled needs-founder"
_nw_lrow "$(_nw_t 3600)" founder 42 "changes projects/felix/risk.tsv"
_nw_start
NWa="$(printf '%s\n' "$NWC" | LC_ALL=C awk 'index($0, "  #") == 1 { s = substr($0, 4); sub(/ .*/, "", s); printf "%s%s", c, s; c = " " }')"
is "b03 A70: a waiting row followed at its head by a refusal (#41) or by a founder row (#42) is still listed, in PR order, and the screen says PRs waiting: 2" \
   "$NWa|$(_nw_tok ' · PRs waiting: 2')" "41 42|yes"
_nw_clear

# Discovery that a session start launched is left to finish before the part ends.
NWk=0; while [ "$NWk" -lt 100 ] && { [ -d "$NWSH/state/discover/.lock" ] || [ -d "$NWH/state/discover/.lock" ]; }; do sleep 0.2; NWk=$((NWk+1)); done
