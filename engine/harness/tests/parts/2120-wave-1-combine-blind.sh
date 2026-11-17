# >>> wave-1-combine
printf '\nwave 1 combined: a hand pause is said once, the brakes never alert, what waits reaches the phone, and a checkout outside the home is told the truth (wave-1-combine.md C1-C7, blind)\n'
# Blind, written on 2026-10-28 from docs/2026-10-24-audit-fixes/wave-1-combine.md alone (section 3, C1-C7, and
# the cases of its section 5), reading the batch contracts it cites (b02 B22-B25, b03 B1-B9, b04 B1-B15, b05
# B1-B13 and R1-R9) for the words it uses. lib/, the felix CLI, hooks/ and bin/ were not read: felix land,
# felix status and hooks/session-start are run as black boxes. Parts 1690, 1710 and 1720 and tests/lib were
# read for how their fixtures are built. Fixture controls are their own assertions, named so.
#
# Fixture G is the shared land fixture (_lg_build amend), its home on main at origin's main with main's entry
# cached, in 1720's GitHub state: the home's origin reads https://github.com/fixture/lgh.git and insteadOf
# sends fetch to the local origin. A gh wrapper of this part's own takes the fixture's gh's place: it logs every
# call (its kind, then its argv) to $W1/s/calls.log, answers api user (fixture-bot), api repos/fixture/lgh
# (owner fixture, a User, push true), issue list (from its issues file), issue create (adding the issue) and
# workflow run (keeping each body= value as $W1/s/body.K, printing a run URL), and hands every other call to the
# fixture's gh. Each run carries CLAUDE_CODE_SESSION_ID=s-w1c, so a brake's row ends ; by session s-w1c. The
# part puts the origin and the gh back at its end, and moves the suite's lib/green-wait.sh aside only for C4's
# two ticks.
#
# Fixture W (C6, C7) is a home of its own under $TMP/w1cfx, as 1690's S: H a checkout whose .felix names
# homeproj (hp) and which holds projects homeproj and sideproj; C a checkout whose .felix names sideproj (p);
# C0 a checkout whose .felix names homeproj; H2 the same projects in a directory that resolves no project; stubs
# first on PATH: uname prints Darwin, launchctl answers print with the exit in ctl/print.rc (113 when none), and
# osascript, gh and claude log and exit (0, 1, 1).
_lg_build amend
W1="$LG/w1c"; rm -rf "$W1"; mkdir -p "$W1/s"
W1T="$(printf '\t')"; W1CWD="$(pwd -P)"
W1DL='details: felix land --status on the machine that runs the lander'
W1NC='no checkout holds the gated head'
_fx_git "$LGH" fetch -q origin >/dev/null 2>&1; _fx_git "$LGH" checkout -q main >/dev/null 2>&1
_fx_git "$LGH" reset -q --hard refs/remotes/origin/main >/dev/null 2>&1
W1V="$(_l3_mainv)"; [ -n "$W1V" ] && _lg_cache "$W1V"
_lg_reset; _lg_land --uninstall; _lg_reset
is "W1C fixture G: the land fixture's home is on main at origin's main, clean, and main's check accepts its cached entry (fixture control)" \
   "$(git -C "$LGH" rev-parse HEAD 2>&1)|$(git -C "$LGH" status --porcelain 2>&1)|$(_l4_acc refs/remotes/origin/main)" "$(git -C "$LGO" rev-parse main 2>&1)||0"

/bin/mv "$LGB/gh" "$W1/gh.prev"
sed "s#@W1@#$W1#g" > "$LGB/gh" <<'W1CGH'
#!/bin/bash
L='@W1@'; S="$L/s"; mkdir -p "$S"
kind="${1:-} ${2:-}"
if [ "${1:-}" = api ]; then kind="api ?"; for a in "$@"; do case "$a" in user) kind="api user" ;; repos/fixture/lgh) kind="api repos/fixture/lgh" ;; esac; done; fi
line="$kind"; for a in "$@"; do a="${a//$'\n'/ }"; line="$line	${a//	/ }"; done
printf '%s\n' "$line" >> "$S/calls.log"
step=""
case "$kind" in "api user") step=user ;; "api repos/fixture/lgh") step=repos ;; "issue list") step=list ;;
  "issue create") step=create ;; "workflow run") step=dispatch ;; esac
[ -n "$step" ] || exec "$L/gh.prev" "$@"
jqx=""; bf=""; t=""; prev=""
for a in "$@"; do
  case "$prev" in -q|--jq) jqx="$a" ;; -F|--body-file) bf="$a" ;; -t|--title) t="$a" ;; esac
  case "$a" in --jq=*) jqx="${a#--jq=}" ;; --body-file=*) bf="${a#--body-file=}" ;; --title=*) t="${a#--title=}" ;; esac
  prev="$a"
done
out() { if [ -n "$jqx" ] && command -v jq >/dev/null 2>&1; then jq -r "$jqx"; else cat; fi; }
case "$step" in
  user) printf '{"login":"fixture-bot"}\n' | out ;;
  repos) printf '{"full_name":"fixture/lgh","owner":{"login":"fixture","type":"User"},"permissions":{"admin":false,"maintain":false,"push":true}}\n' | out ;;
  list) { printf '['; s=""
      if [ -f "$L/issues.tsv" ]; then while IFS='	' read -r n ti au; do
        printf '%s{"number":%s,"title":"%s","author":{"login":"%s"},"state":"OPEN"}' "$s" "$n" "$ti" "$au"; s=","; done < "$L/issues.tsv"; fi
      printf ']\n'; } | out ;;
  create) [ "$bf" = - ] && cat > /dev/null
    n=1; [ -f "$L/issues.tsv" ] && n=$(( $(awk 'END { print NR }' "$L/issues.tsv") + 1 ))
    printf '%s\t%s\t%s\n' "$n" "$t" fixture-bot >> "$L/issues.tsv"
    printf 'https://github.com/fixture/lgh/issues/%s\n' "$n" ;;
  dispatch) k=0; [ -f "$S/k" ] && k="$(cat "$S/k")"; k=$((k+1)); printf '%s\n' "$k" > "$S/k"
    pv=""; for a in "$@"; do case "$pv" in -f|-F|--field|--raw-field) case "$a" in body=*) printf '%s' "${a#body=}" > "$S/body.$k" ;; esac ;; esac; pv="$a"; done
    printf 'Created workflow_dispatch event for felix-alert.yml at main\n' >&2
    printf 'https://github.com/fixture/lgh/actions/runs/%s\n' "$((k + 900))" ;;
esac
exit 0
W1CGH
chmod +x "$LGB/gh"

# ---------------------------------------------------------------- helpers ---
_w1c_on() { _fx_git "$LGH" config remote.origin.url https://github.com/fixture/lgh.git >/dev/null 2>&1
            _fx_git "$LGH" config "url.$LGO.insteadOf" https://github.com/fixture/lgh.git >/dev/null 2>&1; }
_w1c_off() { _fx_git "$LGH" config remote.origin.url "$LGO" >/dev/null 2>&1; _fx_git "$LGH" config --unset-all "url.$LGO.insteadOf" >/dev/null 2>&1; }
_w1c_clear() { rm -rf "$W1/s"; mkdir -p "$W1/s"; }   # this step's calls and bodies emptied
_w1c_keep() { [ -f "$LAND/alerts.tsv" ] && cat "$LAND/alerts.tsv" >> "$W1/all.alerts"; return 0; }   # the records so far, kept for C5
_w1c_reset() {   # land state, issues and calls emptied, in the GitHub state
  _lg_reset; rm -f "$W1/issues.tsv"; _w1c_clear; _w1c_on
  LGX=(GIT_ALLOW_PROTOCOL=file CLAUDE_CODE_SESSION_ID=s-w1c)
}
_w1c_nk() { if [ -f "$W1/s/calls.log" ]; then LC_ALL=C awk -F'\t' -v r="$1" '$1 ~ r { n++ } END { print n + 0 }' "$W1/s/calls.log"; else echo 0; fi; }   # KIND-REGEX -> calls this step
_w1c_n() { if [ -f "$LAND/alerts.tsv" ]; then LC_ALL=C awk 'END { print NR }' "$LAND/alerts.tsv"; else echo 0; fi; }   # -> records
_w1c_f() { [ -f "$LAND/alerts.tsv" ] && LC_ALL=C awk -F'\t' -v r="$1" -v k="$2" 'NR == r + 0 { v = $k } END { printf "%s", v }' "$LAND/alerts.tsv"; }   # ROW FIELD
_w1c_lines() { [ -f "${1:-/nonexistent}" ] && LC_ALL=C awk '{ printf "%s%s", s, $0; s = "|" }' "$1"; }   # FILE -> its lines joined by |
_w1c_osa() { _lg_logs osa | LC_ALL=C grep -c "with title \"Felix: $1" ; }   # TITLE -> banners sent with it
_w1c_has() { case "$1" in *"$2"*) printf '%s' "$3" ;; *) printf 'no-%s' "$3" ;; esac; }   # TEXT NEEDLE TAG -> TAG, or no-TAG
_w1c_t() { local t; t="$(( $(date +%s) - $1 ))"; date -u -r "$t" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -d "@$t" +%Y-%m-%dT%H:%M:%SZ; }   # SECONDS-AGO -> UTC ISO
_w1c_row() { printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$@" >> "$LAND/ledger.tsv"; }   # TIME EVENT PR HEAD WORKTREE WALL DETAIL
_w1c_age() {   # the ledger's rows a year older, so the newest paused row is past its hour (1280's G2 reading, as 1720 ages it)
  [ -f "$LAND/ledger.tsv" ] || return 0
  LC_ALL=C awk -F'\t' -v OFS='\t' -v y="$(date -u +%Y)" '{ if (index($1, y)) sub(y, y - 1, $1); print }' "$LAND/ledger.tsv" > "$LAND/ledger.aged" \
    && /bin/mv "$LAND/ledger.aged" "$LAND/ledger.tsv"
}
_w1c_wait31() {   # -> a fresh ledger whose PR 31 has waited on a session for five hours; gh lists 31, green
  mkdir -p "$LAND"; : > "$LAND/ledger.tsv"
  W1T0="$(_w1c_t 18000)"; _w1c_row "$W1T0" session 31 "$(_lg_sha 31)" - 1 "$W1NC"
  _lg_prs "$(_lg_pr 31)"; _lg_green 31
}
: > "$W1/all.alerts"

# ---------------------------------------------------------------- C1 ---
_w1c_reset; _lg_land --pause "W1C first reason"; W1RC="$LGRC"
is "W1C C1a: in the GitHub state felix land --pause R makes one dispatch, recorded dispatched for paused, whose field 8 is R without the ; by session suffix the ledger row keeps" \
   "$W1RC|$(_w1c_nk '^workflow run')|$(_w1c_n)|$(_w1c_f 1 2) $(_w1c_f 1 3) $(_w1c_f 1 4)|$(_w1c_f 1 8)|$(_lg_f paused - 7)" \
   "0|1|1|dispatched paused -|W1C first reason|W1C first reason; by session s-w1c"
_w1c_age; _w1c_clear; _lg_land --tick
is "W1C C1b: the tick's hourly paused row for the same reason, the ledger aged past the hour, is the same event: one more paused row (detail R) and banner, but no gh call and still one record" \
   "$(_lg_n paused)|$(_lg_f paused - 7)|$(_w1c_osa paused)|$(_w1c_nk .)|$(_w1c_n)" "2|W1C first reason|2|0|1"
_w1c_clear; _lg_land --pause "W1C second reason"
is "W1C C1c: --pause with another reason after that is a new event: one more dispatch on the standing issue, no issue create, and a second dispatched record whose field 8 is that reason" \
   "$(_w1c_nk '^workflow run')|$(_w1c_nk '^issue create')|$(_w1c_n)|$(_w1c_f 2 2) $(_w1c_f 2 3)|$(_w1c_f 2 8)" "1|0|2|dispatched paused|W1C second reason"

# ---------------------------------------------------------------- C2 ---
_w1c_clear; W1C2=""
for _w1cw in --resume --install --uninstall; do
  _lg_land "$_w1cw"; W1C2="$W1C2${_w1cw#--}:rc=$LGRC,calls=$(_w1c_nk .),records=$(_w1c_n);"
done
is "W1C C2a: --resume, --install and --uninstall, in turn, each exit 0, make no gh call and append nothing to alerts.tsv" \
   "$W1C2" "resume:rc=0,calls=0,records=2;install:rc=0,calls=0,records=2;uninstall:rc=0,calls=0,records=2;"
is "W1C C2b (control): and each keeps its ledger row and its banner, Felix: resumed, Felix: installed and Felix: uninstalled" \
   "$(_lg_n resumed)$(_w1c_osa resumed) $(_lg_n installed)$(_w1c_osa installed) $(_lg_n uninstalled)$(_w1c_osa uninstalled)" "11 11 11"
_w1c_keep

# ---------------------------------------------------------------- C3 ---
_w1c_reset; _w1c_wait31; _lg_land --tick
W1WD="waits on a session since $W1T0: session: $W1NC"
is "W1C C3 (fixture control): a tick over green PR 31, whose session wait is five hours old, writes one waiting row as b03 B1 says" \
   "$(_lg_n waiting 31)|$(_lg_f waiting 31 7)" "1|$W1WD"
is "W1C C3a: in the GitHub state that waiting row is dispatched: @fixture Felix land: waiting #31, an empty line, A green pull request has waited more than four hours to land., the details line; one record, dispatched, waiting, #31" \
   "$(_w1c_nk '^workflow run')|$(_w1c_lines "$W1/s/body.1")|$(_w1c_n)|$(_w1c_f 1 2) $(_w1c_f 1 3) $(_w1c_f 1 4)" \
   "1|@fixture Felix land: waiting #31||A green pull request has waited more than four hours to land.|$W1DL|1|dispatched waiting 31"
_w1c_clear; _lg_land --tick
is "W1C C3b: a second tick with nothing changed writes no second waiting row and makes no second dispatch; the one record stays dispatched" \
   "$(_lg_n waiting 31)|$(_w1c_nk '^workflow run')|$(_w1c_n) $(_w1c_f 1 2)" "1|0|1 dispatched"
LC_ALL=C awk -F'\t' -v OFS='\t' -v t="$(_w1c_t 90000)" '$2 == "waiting" { $1 = t } { print }' "$LAND/ledger.tsv" > "$LAND/ledger.w1c" \
  && /bin/mv "$LAND/ledger.w1c" "$LAND/ledger.tsv"
_w1c_clear; _lg_land --tick
is "W1C C3c: with that waiting row moved 25 hours back, the tick writes a second one with the same detail, the same event under B8: no dispatch and no new record" \
   "$(_lg_n waiting 31)|$(_lg_f waiting 31 7)|$(_w1c_nk '^workflow run')|$(_w1c_n) $(_w1c_f 1 2)" "2|$W1WD|0|1 dispatched"
_w1c_keep

# ---------------------------------------------------------------- C4 ---
W1GW="$FROOT/harness/lib/green-wait.sh"; W1GWK="$(cksum < "$W1GW" 2>&1)"
_w1c_reset; _w1c_wait31
/bin/mv "$W1GW" "$W1/green-wait.sh.aside"
_lg_land --tick
W1C4A="$(_lg_n unaged)|$(_w1c_has "$(_lg_f unaged "" 7)" 'lib/green-wait.sh did not load' did-not-load)|stuck=$(_lg_n stuck)|waiting=$(_lg_n waiting)"
W1C4B="$(_w1c_nk '^workflow run')|$(_w1c_lines "$W1/s/body.1")|lock=$(cat "$W1/s"/body.* 2>/dev/null | LC_ALL=C grep -c 'held the lock for more than 45 minutes')|$(_w1c_n)|$(_w1c_f 1 2) $(_w1c_f 1 3)"
_w1c_clear; _lg_land --tick
W1C4C="$(_lg_n unaged)|$(_w1c_nk '^workflow run')|$(_w1c_n)"
/bin/mv "$W1/green-wait.sh.aside" "$W1GW"
is "W1C C4 (fixture control): the suite's lib/green-wait.sh was moved aside for two ticks and is back as it was" \
   "$(cksum < "$W1GW" 2>&1)|$([ -e "$W1/green-wait.sh.aside" ] && echo left || echo moved-back)" "$W1GWK|moved-back"
is "W1C C4a: a tick whose lib/green-wait.sh is missing writes one row of kind unaged, saying green-wait.sh did not load, and none of kind stuck (or waiting)" \
   "$W1C4A" "1|did-not-load|stuck=0|waiting=0"
is "W1C C4b: and dispatches @fixture Felix land: unaged with A tick could not age what waits, so no waiting pull request is named., never the lock sentence; one record, dispatched, unaged" \
   "$W1C4B" "1|@fixture Felix land: unaged||A tick could not age what waits, so no waiting pull request is named.|$W1DL|lock=0|1|dispatched unaged"
is "W1C C4c: a second tick with the file still missing writes no second unaged row and makes no second dispatch (once per kind and detail)" \
   "$W1C4C" "1|0|1"
_w1c_keep

# ---------------------------------------------------------------- C5 ---
W1K15=' landed paused refused gh founder deployed stuck deploy-failed timeout unresolved fetch deploy-owed unreadable waiting unaged '
is "W1C C5: across C1-C4 some records were written, no record's note starts kind:, and every record's kind is one of the fifteen that have an R2 sentence" \
   "$(LC_ALL=C awk -F'\t' -v ks="$W1K15" '{ n++ } index($7, "kind:") == 1 { k++ } index(ks, " " $3 " ") == 0 { o = o " " $3 } END { printf "records=%s|kind-notes=%d|other-kinds=%s", (n > 0 ? "some" : "none"), k, o }' "$W1/all.alerts" 2>&1)" \
   "records=some|kind-notes=0|other-kinds="

# --------------------------------------------------------- G undone ---
_w1c_off; /bin/mv "$W1/gh.prev" "$LGB/gh"; _lg_reset; _lg_land --uninstall; _lg_reset; rm -rf "$W1"
is "W1C fixture G: the part put the land fixture back: origin the local path, no insteadOf, the home clean, the fixture's gh in place, and the working directory where it was (fixture control)" \
   "$(git -C "$LGH" config --get remote.origin.url 2>&1)|$(git -C "$LGH" config --get-regexp '^url\.' 2>&1)|$(git -C "$LGH" status --porcelain 2>&1)|$(LC_ALL=C grep -c 'amend/gh.1280' "$LGB/gh" 2>&1)|$(pwd -P)" \
   "$LGO|||1|$W1CWD"

# ------------------------------------------------------------ fixture W ---
WF="$(mkdir -p "$TMP/w1cfx" && cd "$TMP/w1cfx" && pwd -P)"; [ -n "$WF" ] && [ -d "$WF" ] || WF="$TMP/w1cfx"
WFH="$WF/home"; WFH2="$WF/home2"; WFU="$WF/user"; WFM="$WF/mem"; WFC="$WF/side"; WFC0="$WF/own"; WFB="$WF/bin"; WFK="$WF/ctl"; WFO="$WF/out"
WFP=sideproj; WFHP=homeproj; WFLD="$WFM/$WFP/land"; WFPL="$WFU/Library/LaunchAgents/felix.land.$WFP.plist"
mkdir -p "$WFH/projects/$WFHP" "$WFH/projects/$WFP" "$WFH2" "$WFU/.claude" "$WFU/Library/LaunchAgents" "$WFM" "$WFC" "$WFC0" "$WFB" "$WFK" "$WFO"
for _w1cw in "$WFHP" "$WFP"; do
  printf '{"name":"%s","remote_match":"example.invalid/%s","gate":"true"}\n' "$_w1cw" "$_w1cw" > "$WFH/projects/$_w1cw/project.json"
  printf '# %s\n' "$_w1cw" > "$WFH/projects/$_w1cw/CLAUDE.md"
done
cp -R "$WFH/projects" "$WFH2/projects"
( _fx_cd "$WFH" && git init -q -b main && printf '%s\n' "$WFHP" > .felix \
  && git add -A && git -c user.name=t -c user.email=t@t commit -qm base ) >/dev/null 2>&1
( _fx_cd "$WFC" && git init -q -b main && printf '%s\n' "$WFP" > .felix && printf 'side notes\n' > notes.txt \
  && git add -A && git -c user.name=t -c user.email=t@t commit -qm base ) >/dev/null 2>&1
( _fx_cd "$WFC0" && git init -q -b main && printf '%s\n' "$WFHP" > .felix && printf 'own notes\n' > notes.txt \
  && git add -A && git -c user.name=t -c user.email=t@t commit -qm base ) >/dev/null 2>&1
printf '{"enabledPlugins":{"felix@felix":true}}\n' > "$WFU/.claude/settings.json"
_wf_put() { sed "s#@K@#$WFK#g" > "$1" && chmod +x "$1"; }
printf '#!/bin/bash\necho Darwin\n' | _wf_put "$WFB/uname"
_wf_put "$WFB/launchctl" <<'W1CSTUB'
#!/bin/bash
printf '%s\n' "$*" >> '@K@/launchctl.log'
case "${1:-}" in
  print) rc=113; [ -f '@K@/print.rc' ] && rc="$(cat '@K@/print.rc')"; exit "$rc" ;;
  list) printf 'PID\tStatus\tLabel\n'; exit 0 ;;
esac
exit 0
W1CSTUB
for _w1cw in osascript:0 gh:1 claude:1; do
  printf '#!/bin/bash\nprintf "%%s\\n" "$*" >> "@K@/%s.log"\nexit %s\n' "${_w1cw%%:*}" "${_w1cw#*:}" | _wf_put "$WFB/${_w1cw%%:*}"
done
sleep 1   # the checkouts' indexes are older than any second a run below starts in
is "W1C fixture W: H resolves homeproj by its .felix, C names sideproj, C0 names homeproj, and the stubs answer (fixture control)" \
   "$(cat "$WFH/.felix" "$WFC/.felix" "$WFC0/.felix" 2>&1 | tr '\n' ' ')|$(git -C "$WFH" rev-list --count HEAD 2>&1)|$("$WFB/uname")|$("$WFB/launchctl" print x >/dev/null 2>&1; echo $?)" \
   "homeproj sideproj homeproj |1|Darwin|113"
: > "$WFK/launchctl.log"

WFHOME="$WFH"
_wf_env() {   # CMD... -> fixture W's environment, its home WFHOME
  env -u COPILOT_CLI -u CURSOR_PLUGIN_ROOT -u CLAUDE_CONFIG_DIR -u FELIX_JQ HOME="$WFU" FELIX_HOME="$WFHOME" FELIX_HOME_DIR="$WFHOME" \
    FELIX_MEMORY="$WFM" PATH="$WFB:$PATH" "$@"
}
_wf_set() {   # pl, print=N, hb=K (a heartbeat K seconds old), paused=R (sideproj's), hpaused=R (homeproj's), each set from nothing
  local w
  rm -rf "$WFM/$WFP" "$WFM/$WFHP"; rm -f "$WFPL" "$WFK/print.rc"
  for w in "$@"; do
    case "$w" in
      pl)        printf '<plist/>\n' > "$WFPL" ;;
      print=*)   printf '%s\n' "${w#print=}" > "$WFK/print.rc" ;;
      hb=*)      mkdir -p "$WFLD"; printf '%s\n' "$(( $(date +%s) - ${w#hb=} ))" > "$WFLD/heartbeat" ;;
      paused=*)  mkdir -p "$WFLD"; printf '%s\n' "${w#paused=}" > "$WFLD/paused" ;;
      hpaused=*) mkdir -p "$WFM/$WFHP/land"; printf '%s\n' "${w#hpaused=}" > "$WFM/$WFHP/land/paused" ;;
    esac
  done
}
_wf_st() { ( cd "$1" && _wf_env "$FELIX" status --tsv ) > "$WFO/st" 2> "$WFO/st.err"; WFRC=$?; WFROW="$(LC_ALL=C awk -F'\t' '$1 == "land"' "$WFO/st")"; }   # DIR
_wf_f() { printf '%s' "$WFROW" | LC_ALL=C cut -f"$1"; }   # FIELD -> that field of the land row
_wf_calm() { local i=0; while [ "$i" -lt 100 ] && [ -d "$WFH/state/discover/.lock" ]; do sleep 0.2; i=$((i+1)); done; }
_wf_ss() {   # DIR -> session start there, a startup payload: stdout WFO/ss and WFSS, status WFRC
  printf '{"session_id":"w1c","source":"startup","cwd":"%s"}' "$1" > "$WFO/ss.json"
  ( cd "$1" && _wf_env CLAUDE_PLUGIN_ROOT="$FROOT" "$FROOT/harness/hooks/session-start" < "$WFO/ss.json" ) > "$WFO/ss" 2> "$WFO/ss.err"; WFRC=$?
  sleep 0.5; _wf_calm; WFSS="$(cat "$WFO/ss" 2>/dev/null)"
}
_wf_ctx() {   # -> the context (hookSpecificOutput.additionalContext) of WFO/ss, as UTF-8
  python3 -c 'import json, sys
try:
    d = json.loads(open(sys.argv[1], "rb").read()); v = d["hookSpecificOutput"]["additionalContext"]
except Exception:
    v = "<no context>"
sys.stdout.buffer.write(str(v).encode("utf-8"))' "$WFO/ss" 2>/dev/null
}

# ---------------------------------------------------------------- C6 ---
_wf_set; _wf_st "$WFC"
is "W1C C6a: felix status --tsv in a governed checkout of sideproj under a home whose project is homeproj, with no plist for sideproj: the land row is none, names sideproj and homeproj, and holds no felix land --install" \
   "$WFRC|$(_wf_f 2) $(_wf_f 3)|$(_w1c_has "$(_wf_f 4)" "$WFP" names-p)|$(_w1c_has "$(_wf_f 4)" "$WFHP" names-hp)|$(_w1c_has "$(_wf_f 4)" 'felix land --install' install)" \
   "0|none -|names-p|names-hp|no-install"
_wf_set pl print=113; _wf_st "$WFC"; WFD="$(_wf_f 4)"
is "W1C C6b: with sideproj's plist present and launchd answering 113, the land row is value not-home, naming the plist, homeproj and felix land --uninstall" \
   "$(_wf_f 2) $(_wf_f 3)|$(_w1c_has "$(_wf_f 4)" "$WFPL" names-plist)|$(_w1c_has "$(_wf_f 4)" "$WFHP" names-hp)|$(_w1c_has "$(_wf_f 4)" 'felix land --uninstall' uninstall)" \
   "value not-home|names-plist|names-hp|uninstall"
_wf_set pl print=0 hb=3600; _wf_st "$WFC"
is "W1C C6c: and with that job loaded and no tick for an hour (a job installed for sideproj before b05) it is still value not-home, not not-ticking" \
   "$(_wf_f 2) $(_wf_f 3)|$(_w1c_has "$(_wf_f 4)" "$WFPL" names-plist)|$(_w1c_has "$(_wf_f 4)" 'felix land --uninstall' uninstall)" \
   "value not-home|names-plist|uninstall"
_wf_set; _wf_st "$WFC0"; W1X1="$WFROW"
WFHOME="$WFH2"; _wf_set; _wf_st "$WFC"; W1X2="$WFROW"; _wf_set pl print=113; _wf_st "$WFC"; W1X3="$WFROW"; WFHOME="$WFH"
is "W1C C6d (control): where p is hp, or hp does not resolve, the land row is b04's: none with felix land --install in C0, none for sideproj and not-loaded with its plist under a home that resolves no project" \
   "$W1X1 // $W1X2 // $W1X3" \
   "land${W1T}none${W1T}-${W1T}no land-on-green job for $WFHP; felix land --install schedules one // land${W1T}none${W1T}-${W1T}no land-on-green job for $WFP; felix land --install schedules one // land${W1T}value${W1T}not-loaded${W1T}$WFPL exists and launchd has not loaded felix.land.$WFP: nothing lands; the ledger has no row"
_wf_set pl print=113; _wf_ss "$WFC"
is "W1C C6e: session start in that checkout, with sideproj's plist present, exits 0 and shows landing not-home" \
   "$WFRC|$(_w1c_has "$WFSS" 'landing not-home' badge)" "0|badge"
if command -v python3 >/dev/null 2>&1; then
  _wf_ctx > "$WFO/ctx"; W1L="no such line"
  while IFS= read -r _w1cw || [ -n "$_w1cw" ]; do [ "$_w1cw" != "Landing on green is not-home: $WFD" ] || W1L="the line"; done < "$WFO/ctx"
  is "W1C C6f: and its context holds Landing on green is not-home: and the land detail felix status prints in that state, as b04 B13 says for paused, not-loaded and not-ticking" \
     "$W1L" "the line"
else
  skip "W1C C6f: and its context holds Landing on green is not-home: and the land detail felix status prints in that state, as b04 B13 says for paused, not-loaded and not-ticking" "no python3 on PATH to read the hook's JSON"
fi

# ---------------------------------------------------------------- C7 ---
_wf_set "paused=held by W1C"; _wf_ss "$WFC"
is "W1C C7a: with sideproj's land/paused present, session start in its checkout (p not hp) exits 0, says Felix: sideproj, and names no paused lander: no lander paused token and no The lander is paused paragraph" \
   "$WFRC|$(_w1c_has "$WFSS" "Felix: $WFP" line)|$(_w1c_has "$WFSS" 'lander paused' token)|$(_w1c_has "$WFSS" 'The lander is paused' paragraph)" \
   "0|line|no-token|no-paragraph"
_wf_set "hpaused=held by W1C"; _wf_ss "$WFC0"
is "W1C C7b (control): in a checkout of the home's own project, homeproj's land/paused with no job installed is still named, as S3 leaves it: the lander paused token and The lander is paused" \
   "$WFRC|$(_w1c_has "$WFSS" "Felix: $WFHP" line)|$(_w1c_has "$WFSS" 'lander paused' token)|$(_w1c_has "$WFSS" 'The lander is paused' paragraph)" \
   "0|line|token|paragraph"
_wf_calm; rm -rf "$WF"
# <<< wave-1-combine
