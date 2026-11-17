# >>> deploy-window
printf '\ndeploy window: an owed engine deploy gets its window (contract DW1 to DW7, blind)\n'
# Blind, written from docs/2026-11-06-deploy-window-contract.md alone (rev 1, then rev 2: part mode does not wait; rev 3: a
# waiting door keeps its command line and has one marker child naming its memory root, the default limit is 3600 s, and
# nothing is asserted about instants inside a tick); nothing was read off an implementation.
# The tick is the land fixture's (tests/lib/land-on-green.sh): felix land --tick from the home, with a bin of this part's
# first on PATH. Its pgrep prints ctl-dw/pgrep.out, or, while ctl-dw/pgrep.real names a key, the real pids whose command
# line holds the key and the pattern; its ps prints ctl-dw/ps.out as `PID PPID COMMAND` (and one pid's command for -p),
# exits with ctl-dw/ps.rc, or is the real ps while ctl-dw/ps.real exists. The home's felix stub gets one line more, committed
# to main: it writes what it was asked, its FELIX_HOLD_PASSED and how many hold files exist, to log/dw.log.
# The doors are run for real: felix gate (this tree's harness copy) in a fixture project whose gate.sh writes down its
# FELIX_HOLD_PASSED, and tests/run in a copy of this suite (_suite_copy_tree) with one planted part. Every door run is under
# a bounded runner in a process group of its own, with FELIX_HOLD_PASSED and FELIX_DEPLOY_HOLD out of its environment
# (this suite was admitted, so it has FELIX_HOLD_PASSED itself, DW4). What is left at the end is named and killed by pid.
# Readings where the contract leaves room: a SINCE in the future is in force (DW1 bounds only LEASE), which is how the
# waiter's own bound is shown apart from DW1.4; "going on" includes a door that found no hold, so it exports then too.
# Names say the clause. A name ending (control) passes without the feature on purpose: it pins the fixture.
_lg_build after-1280
DW="$TMP/dw"; mkdir -p "$DW/bin" "$DW/ctl" "$DW/r" "$DW/m" "$DW/rt" "$DW/u" "$DW/live/h/engine/harness/tests" "$DW/pp"
DW="$(cd "$DW" && pwd -P)"; DWB="$DW/bin"; DWK="$DW/ctl"; DWPS="$(command -v ps)"; DWE=()
_dw_put() { sed -e "s#@K@#$DWK#g" -e "s#@PS@#$DWPS#g" > "$1" && chmod +x "$1"; }
_dw_put "$DWB/pgrep" <<'DWSTUB'
#!/bin/bash
K='@K@'
printf '%s\n' "$*" >> "$K/pgrep.log"
pat=""; for a in "$@"; do case "$a" in -*) ;; *) pat="$a" ;; esac; done
if [ -f "$K/pgrep.real" ]; then
  out="$('@PS@' -A -ww -o pid= -o command= 2>/dev/null | P="$pat" KEY="$(cat "$K/pgrep.real")" ME="$$" LC_ALL=C awk '
    { c = $0; sub(/^ *[0-9]+ /, "", c) } $1 != ENVIRON["ME"] && index(c, ENVIRON["KEY"]) && c ~ ENVIRON["P"] { print $1 }')"
else out="$(cat "$K/pgrep.out" 2>/dev/null)"; fi
[ -n "$out" ] || exit 1
printf '%s\n' "$out"
DWSTUB
_dw_put "$DWB/ps" <<'DWSTUB'
#!/bin/bash
K='@K@'
printf '%s\n' "$*" >> "$K/ps.log"
[ ! -f "$K/ps.real" ] || exec '@PS@' "$@"
case " $* " in *" -p "*)
  p=""; prev=""; for a in "$@"; do [ "$prev" != -p ] || p="$a"; prev="$a"; done
  LC_ALL=C awk -v p="$p" '$1 == p { sub(/^ *[0-9]+ +[0-9]+ +/, ""); print }' "$K/ps.out" 2>/dev/null; exit 0 ;;
esac
[ ! -f "$K/ps.out" ] || cat "$K/ps.out"
rc=0; [ ! -f "$K/ps.rc" ] || rc="$(cat "$K/ps.rc")"; exit "$rc"
DWSTUB
# run.pl BOUND PIDFILE CMD...: CMD in a process group of its own, its pid written down, killed with its group at BOUND s
cat > "$DW/run.pl" <<'DWPL'
my ($t, $f) = splice(@ARGV, 0, 2);
my $p = fork; defined $p or exit 125;
if (!$p) { setpgrp(0, 0); if (open(my $h, ">", $f)) { print $h "$$\n"; close $h } exec @ARGV; exit 127 }
$SIG{ALRM} = sub { kill "KILL", -$p; exit 124 };
alarm $t; waitpid $p, 0; my $w = $?; exit(($w & 127) ? 128 + ($w & 127) : $w >> 8);
DWPL
_dw_now() { date +%s; }
_dw_in() { if [ "$1" -ge "$2" ] 2>/dev/null && [ "$1" -le "$3" ] 2>/dev/null; then echo yes; else echo "no ($1 not in $2..$3)"; fi; }
_dw_hf() { mkdir -p "${1%/*}" && printf '%s\t%s\t%s\n' "$2" "$3" "$4" > "$1"; }   # FILE LEASE SINCE VERSION
_dw_fields() {   # FILE -> "LEASE SINCE VERSION" when it is one line of three tab-separated fields, else what it is
  [ -f "$1" ] || { printf 'no file'; return 0; }
  LC_ALL=C awk -F'\t' 'NR == 1 { n = NF; a = $1; b = $2; c = $3 } END { if (NR != 1) printf "lines %d", NR; else if (n != 3) printf "fields %d", n; else printf "%s %s %s", a, b, c }' "$1"
}
_dw_ex() { if [ -e "$1" ]; then echo present; else echo absent; fi; }
_dw_until() { local n=$(( $1 * 10 )) i=0; shift; while [ "$i" -lt "$n" ]; do "$@" && return 0; sleep 0.1; i=$((i + 1)); done; "$@"; }
_dw_said() { [ -f "$DW/r/$1.err" ] && grep -qF -e "$2" "$DW/r/$1.err"; }
_dw_gone() { ! kill -0 "$1" 2>/dev/null; }
_dw_saidorgone() { _dw_said "$1" "$2" || _dw_gone "$3"; }
_dw_saidorgone_f() { [ -s "$1" ] || _dw_gone "$2"; }
_dw_lines() { grep -cE -e "$2" "$DW/r/$1.err" 2>/dev/null | tr -d ' '; }   # LABEL ERE -> how many stderr lines match
_dw_size() { if [ -s "$1" ]; then echo "not empty: $(head -c 120 "$1" | tr '\n' '|')"; else echo empty; fi; }
_dw_nent() { ls -A "$1" 2>/dev/null | wc -l | tr -d ' '; }
# LABEL BOUND CMD...: CMD in the background from DWCD under run.pl, the hold's variables out of its environment and DWE in;
# stdout r/LABEL.out, stderr r/LABEL.err; the runner's pid in DWBG, the group's in r/LABEL.pid
_dw_start() {
  local l="$1" b="$2"; shift 2
  rm -f "$DW/r/$l.out" "$DW/r/$l.err" "$DW/r/$l.pid"
  ( cd "${DWCD:-$DW}" && exec env -u FELIX_HOLD_PASSED -u FELIX_DEPLOY_HOLD -u FELIX_DEPLOY_HOLD_LIMIT -u FELIX_DEPLOY_HOLD_POLL \
      -u FELIX_DEPLOY_HOLD_SAY -u FELIX_TEST_NO_MANIFEST -u FELIX_TEST_JOBS -u FELIX_TEST_SLOTS -u FELIX_TEST_RED_JOBS -u FELIX_TEST_SLOT_NOTE \
      -u FELIX_TEST_PART_LOG -u FELIX_TEST_PART_RAN -u FELIX_TEST_PART_END -u FELIX_TEST_PART_RECORD -u PERL5OPT \
      HOME="$DW/u" FELIX_DEPLOY_HOLD_POLL=0.2 ${DWE[@]+"${DWE[@]}"} perl "$DW/run.pl" "$b" "$DW/r/$l.pid" "$@" ) > "$DW/r/$l.out" 2> "$DW/r/$l.err" &
  DWBG=$!
  _dw_until 5 test -s "$DW/r/$l.pid"
}
_dw_wait() { { wait "$1"; } 2>/dev/null; DWRC=$?; }
_dw_kill() { local g; g="$(cat "$DW/r/$1.pid" 2>/dev/null)"; [ -z "$g" ] || kill -KILL -"$g" 2>/dev/null; _dw_wait "$2"; }
# LABEL ROOT POLL -> N|P|Q (DW6): N, the processes of that run's group whose command line holds felix-deploy-hold-wait ROOT
# and a blank; P, yes when each one's parent still matches the tick's pattern (the door keeps its command line); Q, yes
# when each one's command line holds "felix-deploy-hold-wait ROOT POLL"
_dw_dw6() {
  local g; g="$(cat "$DW/r/$1.pid" 2>/dev/null)"
  "$DWPS" -A -ww -o pid= -o ppid= -o pgid= -o command= 2>/dev/null | G="$g" R="felix-deploy-hold-wait $2 " Q="felix-deploy-hold-wait $2 $3" LC_ALL=C awk '
    { c = $0; sub(/^ *[0-9]+ +[0-9]+ +[0-9]+ +/, "", c); cmd[$1] = c }
    $3 == ENVIRON["G"] && index(c, ENVIRON["R"]) { n++; par[n] = $2; if (!index(c, ENVIRON["Q"])) q = "no" }
    END { p = "yes"; for (i = 1; i <= n; i++) if (cmd[par[i]] !~ /engine\/harness\/tests\/run|gate\.sh/) p = "no"
          printf "%d|%s|%s", n, (n ? p : "-"), (n ? (q ? q : "yes") : "-") }'
}
_dw_markers() { "$DWPS" -A -ww -o command= 2>/dev/null | R="felix-deploy-hold-wait $1 " LC_ALL=C awk 'index($0, ENVIRON["R"]) { n++ } END { print n + 0 }'; }   # ROOT -> how many markers anywhere
_dw_nomark() { [ "$(_dw_markers "$1")" = 0 ]; }

# ---- the felix gate door's fixture: a home with one project whose gate.sh writes down FELIX_HOLD_PASSED
DWH="$DW/home"; DWR="$DW/repo"; mkdir -p "$DWH/projects/dwp" "$DWR"
printf '{\n  "name": "dwp",\n  "remote_match": "example.invalid/dwp",\n  "gate": "gate.sh"\n}\n' > "$DWH/projects/dwp/project.json"
printf '# dwp\n' > "$DWH/projects/dwp/CLAUDE.md"
printf '#!/bin/sh\nprintf "%%s\\n" "${FELIX_HOLD_PASSED-unset}" >> "%s/gate.env"\necho dw-gate-ran\n' "$DW" > "$DWH/projects/dwp/gate.sh"
chmod +x "$DWH/projects/dwp/gate.sh"; printf 'dwp\n' > "$DWR/.felix"
_fx_git "$DWR" init -q -b main >/dev/null 2>&1; _fx_git "$DWR" add -A >/dev/null 2>&1
_fx_git "$DWR" -c user.name=t -c user.email=t@t commit -qm init >/dev/null 2>&1
# LABEL MEMROOT [ARG...]: felix gate in the repository, its memory root MEMROOT, under a 60 s bound; then waits up to 8 s
# for its waiting line or its end. DWW: waited or went. A run that waits is let go by removing MEMROOT, then reaped.
_dw_g() {
  local l="$1" m="$2"; shift 2; rm -f "$DW/gate.env"
  DWE=(FELIX_HOME="$DWH" FELIX_MEMORY="$m" TMPDIR="$DW/rt" ${DWE[@]+"${DWE[@]}"}); DWCD="$DWR" _dw_start "$l" 60 "$FELIX" gate "$@"; DWE=()
  _dw_until 8 _dw_saidorgone "$l" 'felix gate: waiting for the engine deploy' "$DWBG"
  if _dw_said "$l" 'felix gate: waiting for the engine deploy'; then DWW=waited; else DWW=went; fi
  [ "${DWHOLD:-}" = 1 ] || { [ "$DWW" = went ] || rm -rf "$m"; _dw_wait "$DWBG"; }
}
_dw_ran() { if [ -f "$DW/gate.env" ]; then echo "gate ran"; else echo "gate did not run"; fi; }
_dw_m() { M="$DW/m/$1"; rm -rf "$M"; mkdir -p "$M/p1/land"; H1="$M/p1/land/deploy-hold"; }
N="$(_dw_now)"
_dw_m none; _dw_g g0 "$M"
is "DW4: felix gate with no hold goes on at once: no wait, its gate runs (control)" "$DWW|$(_dw_ran)" "went|gate ran"
is "DW4: and says nothing of a deploy on stderr (control)" "$(_dw_lines g0 'engine deploy')" "0"
is "DW4: a door that goes on exports FELIX_HOLD_PASSED=1 to the project's gate" "$(cat "$DW/gate.env" 2>/dev/null)" "1"
# DW1, in force: each must wait
_dw_dw1w() { _dw_g "$1" "$M"; is "DW1: in force, felix gate waits: $2" "$DWW" "waited"; }
_dw_m w1; _dw_hf "$H1" "$N" "$N" 9.9.9; DWE=(FELIX_DEPLOY_HOLD_SAY=1); DWHOLD=1 _dw_g w1 "$M"
is "DW1: a fresh hold (LEASE and SINCE now) is in force: felix gate waits" "$DWW" "waited"
is "DW1 (control): the hold felix gate meets is in force by DW1: one line, three fields, LEASE now, a version" "$(_dw_fields "$H1")" "$N $N 9.9.9"
sleep 1.6
is "DW4: while it waits, felix gate's stdout is empty" "$(_dw_size "$DW/r/w1.out")" "empty"
is "DW4: while it waits, the project's gate has not run" "$(_dw_ran)" "gate did not run"
DWL1="$(sed -n 1p "$DW/r/w1.err")"
case "$DWL1" in "felix gate: waiting for the engine deploy"*) ok "DW5: the first stderr line begins felix gate: waiting for the engine deploy" ;;
  *) bad "DW5: the first stderr line begins felix gate: waiting for the engine deploy" "[$DWL1]" ;; esac
has "DW5: the waiting line holds the hold's VERSION" "$DWL1" "9.9.9"
has "DW5: the waiting line holds at most <LIMIT> s, 3600 by default" "$DWL1" "at most 3600 s"
has "DW5: the waiting line names FELIX_DEPLOY_HOLD=off as the way past" "$DWL1" "FELIX_DEPLOY_HOLD=off"
is "DW5: with FELIX_DEPLOY_HOLD_SAY=1 it says a still-waiting line holding the seconds waited" \
   "$(_dw_lines w1 '^felix gate: still waiting for the engine deploy.*[0-9]' | awk '{ print ($1 > 0) ? "said" : "not said" }')" "said"
is "DW6: a waiting felix gate has exactly one marker child, felix-deploy-hold-wait <its memory root> <its poll>" "$(_dw_dw6 w1 "$M" 0.2 | cut -d'|' -f1,3)" "1|yes"
rm -f "$H1"; _dw_until 3 _dw_said w1 'went ahead after'
is "DW5: once the file is gone it goes ahead within a few polls, saying went ahead after N s: the hold ended" \
   "$(_dw_lines w1 '^felix gate: went ahead after [0-9]+ s: the hold ended$')" "1"
_dw_wait "$DWBG"
is "DW6: a door that went ahead leaves no marker for its root" "$(_dw_markers "$M")" "0"
is "DW4: then its gate runs, with FELIX_HOLD_PASSED=1 exported" "$(_dw_ran)|$(cat "$DW/gate.env" 2>/dev/null)" "gate ran|1"
is "DW5: nothing it said went to stdout" "$(grep -c 'engine deploy' "$DW/r/w1.out" | tr -d ' ')" "0"
_dw_m w2; _dw_hf "$H1" "$N" "$N" -; DWHOLD=1 _dw_g w2 "$M"; _dw_hf "$H1" "$((N - 1300))" "$N" -
_dw_until 3 _dw_said w2 'went ahead after'
is "DW5: a file still there but no longer in force (a stale lease) ends the wait as the hold lapsed" \
   "$(_dw_lines w2 '^felix gate: went ahead after [0-9]+ s: the hold lapsed$')" "1"
_dw_wait "$DWBG"
_dw_m w3; _dw_hf "$H1" "$N" "$((N + 1000))" -; DWE=(FELIX_DEPLOY_HOLD_LIMIT=2); DWHOLD=1 _dw_g w3 "$M"
_dw_until 6 _dw_saidorgone w3 'went ahead after' "$DWBG"
is "DW5: bounded: with FELIX_DEPLOY_HOLD_LIMIT=2 and the hold still in force, it goes ahead saying the limit was reached" \
   "$DWW|$(_dw_lines w3 '^felix gate: went ahead after [0-9]+ s: the limit was reached$')" "waited|1"
_dw_wait "$DWBG"
is "DW5: and then its gate runs" "$(_dw_ran)" "gate ran"
has "DW5: and the waiting line says at most 2 s" "$(sed -n 1p "$DW/r/w3.err")" "at most 2 s"
_dw_m w4; mkdir -p "$M/p2/land"; printf 'garbled\n' > "$H1"; _dw_hf "$M/p2/land/deploy-hold" "$((N - 1100))" "$N" -; _dw_dw1w w4 \
  "one project's file garbled and another's in force (lease 1100 s old): any one in force holds the machine"
_dw_m w5; _dw_hf "$H1" "$((N + 30))" "$N" -; _dw_dw1w w5 "a LEASE 30 s in the future (within now + 60)"
_dw_m w6; _dw_hf "$H1" "$N" "$((N - 150))" -; DWE=(FELIX_DEPLOY_HOLD_LIMIT=200); _dw_dw1w w6 "SINCE 150 s ago under FELIX_DEPLOY_HOLD_LIMIT=200"
_dw_m w7; _dw_hf "$H1" "$N" "$((N - 150))" -; DWE=(FELIX_DEPLOY_HOLD_LIMIT=0); _dw_dw1w w7 "a FELIX_DEPLOY_HOLD_LIMIT of 0 is read as 3600"
_dw_m w8; _dw_hf "$H1" "$N" "$N" -; DWE=(FELIX_HOLD_PASSED=); _dw_dw1w w8 "FELIX_HOLD_PASSED set but empty does not skip it"
_dw_m w9; _dw_hf "$H1" "$N" "$N" -; _dw_g w9 "$M" --quick
is "DW4: felix gate with arguments (--quick) waits too" "$DWW" "waited"
# DW1, not in force, and DW4's bypasses: each goes on with no wait
_dw_dw1n() { _dw_g "$1" "$M"; is "DW1, DW7: not in force, felix gate goes on at once and its gate runs: $2" "$DWW|$(_dw_ran)|$(_dw_lines "$1" 'engine deploy')" "went|gate ran|0"; }
_dw_m n1; mkdir -p "$H1"; _dw_dw1n n1 "the path is a directory"
_dw_m n2; : > "$H1"; _dw_dw1n n2 "an empty file"
_dw_m n3; printf '%s\t%s\n' "$N" "$N" > "$H1"; _dw_dw1n n3 "two fields"
_dw_m n4; printf '%s\t%s\t-\textra\n' "$N" "$N" > "$H1"; _dw_dw1n n4 "four fields"
_dw_m n5; _dw_hf "$H1" "${N}x" "$N" -; _dw_dw1n n5 "a LEASE that is not a plain decimal integer"
_dw_m n6; _dw_hf "$H1" "$((N - 1300))" "$N" -; _dw_dw1n n6 "a stale lease, 1300 s old"
_dw_m n7; _dw_hf "$H1" "$((N + 120))" "$N" -; _dw_dw1n n7 "a LEASE 120 s in the future"
_dw_m n8; _dw_hf "$H1" "$N" "$((N - 3700))" -; _dw_dw1n n8 "SINCE 3700 s ago, past the default limit of 3600"
_dw_m n9; _dw_hf "$H1" "$N" "$((N - 150))" -; DWE=(FELIX_DEPLOY_HOLD_LIMIT=100); _dw_dw1n n9 "SINCE 150 s ago under FELIX_DEPLOY_HOLD_LIMIT=100"
_dw_m n10; _dw_hf "$M/p1/deploy-hold" "$N" "$N" -; _dw_dw1n n10 "a file beside land/, not in it"
_dw_m n11; _dw_hf "$H1" "$N" "$N" -; chmod 000 "$H1"; _dw_dw1n n11 "an unreadable file (fail open)"; chmod 600 "$H1"
_dw_m n12; _dw_hf "$H1" "$N" "$N" -; DWE=(FELIX_HOLD_PASSED=1); _dw_dw1n n12 "FELIX_HOLD_PASSED=1 skips the wait, saying nothing"
_dw_m n13; _dw_hf "$H1" "$N" "$N" -; DWE=(FELIX_DEPLOY_HOLD=off); _dw_dw1n n13 "FELIX_DEPLOY_HOLD=off skips the wait, saying nothing"

# ---- the tests/run door: a copy of this suite with one planted part, which writes down its FELIX_HOLD_PASSED
printf '%s\n' 'printf "%s\n" "${FELIX_HOLD_PASSED-unset}" >> "${DW_PENV:-/dev/null}"' 'ok "dw planted part ran"' > "$DW/pp/0010-dw.sh"
DWC="$DW/live/c"; _suite_copy_tree "$DWC" - - "$DW/pp/0010-dw.sh"; DWX=$?
is "the tests/run door's fixture: _suite_copy_tree made a copy of this suite with the planted part (control)" "$DWX|$(_dw_ex "$DWC/engine/harness/tests/run")" "0|present"
_dw_m run; _dw_hf "$H1" "$N" "$((N + 1000))" -; DWRM="$M"
# macOS mktemp -d ignores TMPDIR, so a shim first on PATH writes down every mktemp the copy's run makes (as part 1291 does)
mkdir -p "$DW/shim"; printf '#!/bin/sh\nprintf "x\\n" >> "${DW_MK:-/dev/null}"\nexec "%s" "$@"\n' "$(command -v mktemp)" > "$DW/shim/mktemp"; chmod +x "$DW/shim/mktemp"
_dw_mk() { if [ -f "$DW/r/$1.mk" ]; then awk 'END { print NR }' "$DW/r/$1.mk"; else echo 0; fi; }
# LABEL ARG...: the copy's tests/run with the hold at DWRM; waits up to 6 s for the waiting line, its first mktemp or its
# end, then: DWW waited or went, DWT how many mktemps it made, DWO its stdout; the run is then killed with its group
_dw_r() {
  local l="$1"; shift; mkdir -p "$DW/rt/$l"; rm -f "$DW/r/$l.mk"
  DWE=(FELIX_MEMORY="$DWRM" TMPDIR="$DW/rt/$l" DW_MK="$DW/r/$l.mk" PATH="$DW/shim:$PATH" ${DWE[@]+"${DWE[@]}"})
  DWCD="$DWC" _dw_start "$l" 120 "$BASH" "$DWC/engine/harness/tests/run" "$@"; DWE=()
  _dw_until 6 _dw_r_seen "$l"; sleep 0.5
  if _dw_said "$l" 'tests/run: waiting for the engine deploy'; then DWW=waited; else DWW=went; fi
  DWT="$(_dw_mk "$l")"; DW6="$(_dw_dw6 "$l" "$DWRM" 0.2)"; DWO="$(_dw_size "$DW/r/$l.out")"
  # DW6: the door (the group's leader) is killed alone, with KILL; its marker must end by itself within a few seconds
  DWG="$(cat "$DW/r/$l.pid" 2>/dev/null)"; [ -z "$DWG" ] || kill -KILL "$DWG" 2>/dev/null
  _dw_until 6 _dw_nomark "$DWRM"; DWMK="$(_dw_markers "$DWRM")"
  _dw_kill "$l" "$DWBG"
}
_dw_r_seen() { _dw_said "$1" 'tests/run: waiting for the engine deploy' || [ "$(_dw_mk "$1")" != 0 ] || _dw_gone "$DWBG"; }
_dw_r r1
is "DW4: a full tests/run under a hold waits: its waiting line, no mktemp made, nothing on stdout" "$DWW|$DWT|$DWO" "waited|0|empty"
is "DW6: a waiting tests/run keeps its command line (it matches the tick's pattern) and has one marker child for its root and poll" "$DW6" "1|yes|yes"
is "DW6: when the waiting door is killed with KILL, its marker ends by itself within a few seconds" "$DWMK" "0"
_dw_r r2 -j 2;                is "DW4: tests/run -j 2 waits, before it makes anything" "$DWW|$DWT" "waited|0"
_dw_r r3 --reuse;             is "DW4: tests/run --reuse waits, before it makes anything" "$DWW|$DWT" "waited|0"
_dw_r r4 --record-assertions; is "DW4: tests/run --record-assertions waits, before it makes anything" "$DWW|$DWT" "waited|0"
DWE=(FELIX_HOLD_PASSED=1); _dw_r r5
is "DW4: a full tests/run with FELIX_HOLD_PASSED=1 skips the wait and starts, saying nothing" "$DWW|$([ "$DWT" != 0 ] && echo made)|$(_dw_lines r5 'engine deploy')" "went|made|0"
DWE=(FELIX_DEPLOY_HOLD=off); _dw_r r6
is "DW4: a full tests/run with FELIX_DEPLOY_HOLD=off skips the wait and starts, saying nothing" "$DWW|$([ "$DWT" != 0 ] && echo made)|$(_dw_lines r6 'engine deploy')" "went|made|0"
# rev 2, DW4.1: part mode does not wait and says nothing, under a hold in force, and still exports FELIX_HOLD_PASSED=1
rm -f "$DW/r8.penv"; mkdir -p "$DW/rt/r8"
DWE=(FELIX_MEMORY="$DWRM" TMPDIR="$DW/rt/r8" DW_PENV="$DW/r8.penv"); DWCD="$DWC" _dw_start r8 120 "$BASH" "$DWC/engine/harness/tests/run" --part 0010-dw.sh; DWE=()
is "DW4 (control): the hold the part run meets is still in force by DW1 (SINCE in the future, LEASE now)" "$(_dw_fields "$H1")" "$N $((N + 1000)) -"
_dw_until 90 _dw_saidorgone_f "$DW/r8.penv" "$DWBG"; _dw_kill r8 "$DWBG"
is "DW4 rev 2: tests/run --part under a hold goes straight on: no waiting line, nothing about a deploy on stderr" "$(_dw_lines r8 'engine deploy')" "0"
is "DW4 rev 2: and its part runs, with FELIX_HOLD_PASSED=1 in its environment" "$(cat "$DW/r8.penv" 2>/dev/null)|$(grep -c 'ok    dw planted part ran' "$DW/r/r8.out" | tr -d ' ')" "1|1"
DWRM="$DW/m/none-run"; mkdir -p "$DWRM"; _dw_r r7
is "DW4: a full tests/run with no hold starts at once, saying nothing (control)" "$DWW|$([ "$DWT" != 0 ] && echo made)|$(_dw_lines r7 'engine deploy')" "went|made|0"

# ---- the tick (DW2, DW3): the home on main, its felix stub writing down what it was asked, a deploy owed
_fx_git "$LGH" fetch -q origin >/dev/null 2>&1; _fx_git "$LGH" checkout -q main >/dev/null 2>&1
_fx_git "$LGH" reset -q --hard refs/remotes/origin/main >/dev/null 2>&1; _fx_git "$LGH" clean -fdq >/dev/null 2>&1
cat > "$DW/stubline" <<'DWSL'
printf '%s\t%s\t%s\n' "$*" "${FELIX_HOLD_PASSED-unset}" "$(ls "$LG"/mem/*/land/deploy-hold 2>/dev/null | wc -l | tr -d ' ')" >> "$LG/log/dw.log"
DWSL
if ! grep -q 'log/dw.log' "$LGH/engine/harness/felix"; then
  LC_ALL=C awk 'NR == FNR { l = $0; next } { print } index($0, "log/felix.log") && !d { print l; d = 1 }' "$DW/stubline" "$LGH/engine/harness/felix" > "$DW/felix.stub" \
    && cat "$DW/felix.stub" > "$LGH/engine/harness/felix"
  _fx_git "$LGH" add -A >/dev/null 2>&1; _fx_git "$LGH" -c user.name=t -c user.email=t@t commit -qm dw-stub >/dev/null 2>&1
  _fx_git "$LGH" push -q origin main >/dev/null 2>&1
fi
DWV="$(_lg_mainv)"; HF="$LAND/deploy-hold"
_dw_owe() { rm -rf "$LGV/$DWV"; }
_dw_land() {   # ARGS -> felix land ARGS from the home under a 90 s bound, this part's bin first; LGRC
  ( cd "$LGH" || exit 97
    exec perl -e 'alarm shift; exec @ARGV or exit 127' 90 env -u FELIX_ALLOW_RED -u FELIX_KERNEL -u FELIX_KERNEL_CACHE -u FELIX_HOLD_PASSED \
      -u FELIX_DEPLOY_HOLD -u FELIX_DEPLOY_HOLD_LIMIT HOME="$LGU" FELIX_HOME="$LGH" FELIX_HOME_DIR="$LGH" FELIX_MEMORY="$LGM" \
      FELIX_PLUGIN_CACHE="$LGC" PATH="$DWB:$LGB:$PATH" "$FELIX" land "$@" ) > "$LG/out" 2>&1
  LGRC=$?
}
_dw_tick() { rm -f "$LAND/ledger.tsv" "$DWK/ps.log"; T0="$(_dw_now)"; _dw_land --tick; T1="$(_dw_now)"; }
_dw_k() { rm -f "$DWK"/*; cp "$DW/ps.table" "$DWK/ps.out"; [ "$#" -eq 0 ] || printf '%s\n' "$@" > "$DWK/pgrep.out"; }   # PID...: what pgrep lists
_dw_row() { _lg_f deploy-owed "" 7; }
_dw_named() {   # PID [ROW] -> the row (default the last deploy-owed row's detail) names pid PID, followed by a non-digit or its end
  local r; if [ "$#" -ge 2 ]; then r="$2"; else r="$(_dw_row)"; fi
  case "$r" in *"pid $1"[!0123456789]*|*"pid $1") echo named ;; *) echo "not named" ;; esac
}
is "the tick fixture: _dw_named reads pid 40010 before a semicolon or at the end as named, and pid 4001 or 400100 as not (control)" \
   "$(_dw_named 40010 'matched pid 40010; new suites and gates wait')|$(_dw_named 40010 'matched pid 40010')|$(_dw_named 4001 'matched pid 40010')|$(_dw_named 400100 'matched pid 40010')" \
   "named|named|not named|not named"
_dw_dwlog() { LC_ALL=C awk -F'\t' -v c="$1" '$1 == c { print $2 "|" $3; exit }' "$LGL/dw.log" 2>/dev/null; }   # CMD -> FELIX_HOLD_PASSED|hold files
_dw_lacks() { case "$2" in *"$3"*) bad "$1" "[$2] holds [$3]" ;; *) ok "$1" ;; esac; }
_dw_ino() { ls -i "$1" 2>/dev/null | awk '{ print $1 }'; }
_dw_ntab() { awk '$0 == "-axo pid=,ppid=,command=" { n++ } END { print n + 0 }' "$DWK/ps.log" 2>/dev/null; }
# waiters' markers name the tick's memory root (@R@, its FELIX_MEMORY as the tick is given it); 40071's names another root
sed "s#@R@#$LGM#g" > "$DW/ps.table" <<'DWT'
    1     0 /sbin/launchd
40020     1 /bin/bash /x/engine/harness/tests/run
 40009     1 /bin/zsh -c cd /y && engine/harness/tests/run
 40010 40009 /bin/bash /y/engine/harness/tests/run
 40011 40010 perl -e 1 felix-deploy-hold-wait @R@ 5
 40012 40011 sleep 1
 40040 40011 /bin/bash /z/gate.sh
 40060 40061 perl -e 1 felix-deploy-hold-wait @R@ 5
 40061 40060 /bin/bash /v/engine/harness/tests/run
 40070     1 /bin/bash /u/engine/harness/tests/run
 40071 40070 perl -e 1 felix-deploy-hold-wait /elsewhere/memory 5
DWT
_lg_reset; _dw_owe; _dw_k; _dw_tick
is "the tick fixture: a deploy owed and nothing running, the tick deploys: one deployed row, one install (control)" "$LGRC|$(_lg_n deployed)|$(_lg_ninst)" "0|1|1"
is "DW4: the tick's own felix gate --quick runs with FELIX_HOLD_PASSED=1" "$(_dw_dwlog 'gate --quick' | cut -d'|' -f1)" "1"
is "DW2.3: and the deployed row clears it" "$(_dw_ex "$HF")" "absent"
_lg_reset; _dw_hf "$HF" "$(_dw_now)" "$(_dw_now)" "$DWV"; _dw_k 40020; _dw_tick
is "the tick fixture: just deployed, a suite running: no deploy is owed, no deploy-owed row, no install (control)" "$(_lg_n deploy-owed)|$(_lg_ninst)" "0|0"
is "DW2.3: with no deploy owed the tick clears a hold in force" "$(_dw_ex "$HF")" "absent"
_dw_owe; _lg_reset; _dw_k 40020; _dw_tick; DWD="$(_dw_row)"
is "the tick fixture: a deploy owed and a suite running: one deploy-owed row, nothing installed (control)" "$(_lg_n deploy-owed)|$(_lg_ninst)" "1|0"
case "$DWD" in "a gate or suite is running"*) ok "DW2.4: the row's first words are still a gate or suite is running" ;; *) bad "DW2.4: the row's first words are still a gate or suite is running" "[$DWD]" ;; esac
has "DW2.4: its detail holds new suites and gates wait" "$DWD" "new suites and gates wait"
read -r DL DS DV <<EOF
$(_dw_fields "$HF")
EOF
is "DW2.1: the tick asserts the hold: one line of three fields, LEASE now, SINCE = LEASE, VERSION main's" \
   "$(_dw_in "$DL" "$T0" "$T1")|$([ "$DS" = "$DL" ] && echo same)|$DV" "yes|same|$DWV"
_dw_ss() {   # NAME LEASE SINCE VERSION: a hold file there before the tick -> DL DS DV after it
  _lg_reset; _dw_hf "$HF" "$2" "$3" "$4"; DWI="$(_dw_ino "$HF")"; _dw_k 40020; _dw_tick
  read -r DL DS DV <<EOF
$(_dw_fields "$HF")
EOF
}
N="$(_dw_now)"; _dw_ss keep "$((N - 30))" "$((N - 100))" "$DWV"
is "DW2.1: a fresh lease of main's version keeps SINCE and moves LEASE to now" "$DS|$(_dw_in "$DL" "$T0" "$T1")" "$((N - 100))|yes"
is "DW2: the file is written whole, a new file renamed over the old (its inode changes)" "$([ -n "$DWI" ] && [ "$(_dw_ino "$HF")" != "$DWI" ] && echo renamed)" "renamed"
_dw_ss stale "$((N - 1300))" "$((N - 2000))" "$DWV"
is "DW2.1: a stale lease (1300 s) does not keep SINCE: SINCE is now" "$(_dw_in "$DS" "$T0" "$T1")" "yes"
_dw_ss other "$((N - 30))" "$((N - 100))" 0.0.0-other
is "DW2.1: a hold for another version does not keep SINCE: SINCE now, VERSION main's" "$(_dw_in "$DS" "$T0" "$T1")|$DV" "yes|$DWV"
_dw_ss lapsed "$((N - 30))" "$((N - 8000))" "$DWV"
is "DW2.1: past the limit the tick keeps refreshing LEASE with SINCE unchanged" "$DS|$(_dw_in "$DL" "$T0" "$T1")" "$((N - 8000))|yes"
has "DW2.4: and the row says the hold has lapsed" "$(_dw_row)" "the hold has lapsed"
_lg_reset; _dw_k 40009 40010 40011 40020 40040 40030; _dw_tick; DWD="$(_dw_row)"
is "DW3: waiters, their ancestors and a real suite listed: still one deploy-owed row (control)" "$(_lg_n deploy-owed)|$(_lg_ninst)" "1|0"
is "DW3: the tick reads the table once with ps -axo pid=,ppid=,command=" "$(_dw_ntab)" "1"
for DWP in 40020 40040 40030; do has "DW3: matched names a pid that is no waiter nor ancestor of one (a suite, a waiter's child, one ps does not show)" "$DWD" "pid $DWP"; done
for DWP in 40009 40010 40011; do _dw_lacks "DW3: matched does not name a waiter or an ancestor of one" "$DWD" "pid $DWP"; done
_lg_reset; _dw_k 40009 40010 40011; _dw_tick
is "DW3: when every pid pgrep lists is a waiter or an ancestor of one, nothing runs and the tick deploys" "$(_lg_n deploy-owed)|$(_lg_n deployed)" "0|1"
_dw_owe
_lg_reset; _dw_k 40070 40071; _dw_tick
is "DW3: a marker for another memory root drops nothing: its suite is named and nothing is installed" "$(_lg_n deploy-owed)|$(_dw_named 40070)|$(_lg_ninst)" "1|named|0"
_dw_trust() {   # WHAT: ps as set up in ctl-dw, pgrep listing 40010 alone -> it counts as running
  _lg_reset; cp "$DWK/ps.out" "$DW/ps.keep" 2>/dev/null; DWR1="$(cat "$DWK/ps.rc" 2>/dev/null)"
  _dw_k 40010; cp "$DW/ps.keep" "$DWK/ps.out" 2>/dev/null || rm -f "$DWK/ps.out"; [ -z "$DWR1" ] || printf '%s\n' "$DWR1" > "$DWK/ps.rc"
  _dw_tick; is "DW3: $1, the ancestor counts as running: deploy-owed names it, nothing installed" \
    "$(_lg_n deploy-owed)|$(_dw_named 40010)|$(_lg_ninst)" "1|named|0"
}
_dw_k; printf '1\n' > "$DWK/ps.rc"; _dw_trust "a ps that exits 1 (its table printed all the same)"
_dw_k; : > "$DWK/ps.out"; _dw_trust "a ps that prints nothing"
_dw_k; printf 'not a table\nat all\n' > "$DWK/ps.out"; _dw_trust "a ps whose lines do not parse"
_lg_reset; _dw_k 40061 40020; _dw_tick
is "DW3: a cycle in the table's parents does not hang the tick: it ends with its deploy-owed row naming the suite" \
   "$(_lg_n deploy-owed)|$(_dw_named 40020)" "1|named"
_lg_reset; _dw_hf "$HF" "$(_dw_now)" "$(_dw_now)" "$DWV"; _dw_k; _dw_tick
is "DW2.3: a hold in force is cleared by the deployed row" "$(_lg_n deployed)|$(_dw_ex "$HF")" "1|absent"
_dw_owe; _lg_reset; _dw_hf "$HF" "$(_dw_now)" "$(_dw_now)" "$DWV"; _dw_k; _fx_git "$LGH" checkout -q -b dwside >/dev/null 2>&1; _dw_tick
is "DW2.3: the tick pausing (the home off main) clears the hold" "$(_dw_ex "$LAND/paused")|$(_dw_ex "$HF")" "present|absent"
_fx_git "$LGH" checkout -q main >/dev/null 2>&1; _fx_git "$LGH" branch -q -D dwside >/dev/null 2>&1
_lg_reset; _dw_hf "$HF" "$(_dw_now)" "$(_dw_now)" "$DWV"; _dw_k; _dw_land --pause "dw hand pause"; _dw_tick
is "DW2.3: after felix land --pause, the tick clears the hold" "$(_dw_ex "$LAND/paused")|$(_dw_ex "$HF")" "present|absent"
_lg_reset; printf '1\n' > "$LGK/gate.rc"; _dw_hf "$HF" "$(_dw_now)" "$(_dw_now)" "$DWV"; _dw_k; _dw_tick
is "DW2.3: a deploy that ends deploy-failed clears the hold" "$(_lg_n deploy-failed)|$(_dw_ex "$HF")" "1|absent"

# ---- end to end: a suite runs, a deploy is owed; a new full suite waits; the running one ends, the tick deploys, the waiter goes on
_dw_owe; _lg_reset; _dw_k; printf '%s\n' "$DW/live/" > "$DWK/pgrep.real"; : > "$DWK/ps.real"; mkdir -p "$DW/live/go"; rm -f "$DW/live/sig" "$DW/e2e.penv"
printf '%s\n' 'trap '"'"'printf "sig\n" >> "$2"'"'"' TERM INT HUP USR1 USR2 QUIT' 'i=0; while [ -d "$1" ] && [ "$i" -lt 900 ]; do sleep 0.1; i=$((i + 1)); done' > "$DW/live/holder.sh"
bash "$DW/live/holder.sh" "$DW/live/go" "$DW/live/sig" "$DW/live/h/engine/harness/tests/run" > /dev/null 2>&1 & DWHP=$!
_dw_tick
is "end to end: with a deploy owed, the running suite (a real process) is matched: one deploy-owed row naming its pid (control)" \
   "$(_lg_n deploy-owed)|$(_dw_named "$DWHP")" "1|named"
read -r DL DS DV <<EOF
$(_dw_fields "$HF")
EOF
is "end to end: and the hold is asserted, in force by DW1 (LEASE now, VERSION main's)" "$(_dw_in "$DL" "$T0" "$T1")|$DV" "yes|$DWV"
DWE=(FELIX_MEMORY="$LGM" TMPDIR="$DW/rt" DW_MK="$DW/r/e2e.mk" PATH="$DW/shim:$PATH" DW_PENV="$DW/e2e.penv" FELIX_DEPLOY_HOLD_SAY=1); rm -f "$DW/r/e2e.mk"
printf '%s\n' '"$@"' 'rc=$?' 'exit "$rc"' > "$DW/live/wrap.sh"   # a caller's wrapper (DW6): a shell that stays the door's parent
mkdir -p "$DW/live/go2"; bash "$DW/live/wrap.sh" bash "$DW/live/holder.sh" "$DW/live/go2" "$DW/live/sig2" "$DWC/engine/harness/tests/run" > /dev/null 2>&1 & DWDP=$!
sleep 0.5; DWPG=" $("$DWB/pgrep" -f 'engine/harness/tests/run|gate\.sh' 2>/dev/null | tr '\n' ' ')"; rmdir "$DW/live/go2"; _dw_wait "$DWDP"
case "$DWPG" in *" $DWDP "*) ok "end to end: a wrapper of that shape around the copy's tests/run is a process the tick's pgrep lists (control)" ;;
  *) bad "end to end: a wrapper of that shape around the copy's tests/run is a process the tick's pgrep lists (control)" "wrapper $DWDP, listed [$DWPG]" ;; esac
DWCD="$DWC" _dw_start e2e 150 "$BASH" "$DW/live/wrap.sh" "$BASH" "$DWC/engine/harness/tests/run"; DWE=(); DWEB="$DWBG"; DWEW="$(cat "$DW/r/e2e.pid" 2>/dev/null)"
_dw_until 6 _dw_saidorgone e2e 'tests/run: waiting for the engine deploy' "$DWEB"
is "end to end: a new full suite does not run: its waiting line on stderr, no mktemp, nothing on stdout" \
   "$(_dw_lines e2e '^tests/run: waiting for the engine deploy')|$(_dw_mk e2e)|$(_dw_size "$DW/r/e2e.out")" "1|0|empty"
is "end to end: the waiting door keeps its command line and has one marker child for the tick's root" "$(_dw_dw6 e2e "$LGM" 0.2 | cut -d'|' -f1,2)" "1|yes"
sleep 1.2; _dw_tick
is "end to end: a tick while both are there still names the running suite" "$(_dw_named "$DWHP")" "named"
is "end to end: and drops the waiter's wrapper, still there and an ancestor of a waiter" "$(kill -0 "$DWEW" 2>/dev/null && echo there)|$(_dw_named "$DWEW")" "there|not named"
read -r DL DS DV <<EOF
$(_dw_fields "$HF")
EOF
is "end to end: it refreshes LEASE and keeps SINCE" "$(_dw_in "$DL" "$T0" "$T1")|$([ -n "$DS" ] && [ "$DS" -le "$T0" ] 2>/dev/null && echo kept)" "yes|kept"
is "end to end: the waiter says it is still waiting" "$(_dw_lines e2e '^tests/run: still waiting for the engine deploy.*[0-9]' | awk '{ print ($1 > 0) ? "said" : "not said" }')" "said"
is "DW2: nothing is signalled: the running suite is alive and caught no signal" "$(kill -0 "$DWHP" 2>/dev/null && echo alive)|$(_dw_ex "$DW/live/sig")" "alive|absent"
rmdir "$DW/live/go"; _dw_wait "$DWHP"; _dw_tick
is "end to end: once the running suite has ended, the tick deploys and clears the hold" "$(_lg_n deployed)|$(_dw_ex "$HF")" "1|absent"
_dw_until 5 _dw_saidorgone e2e 'went ahead after' "$DWEB"
is "end to end: the waiter goes ahead, saying went ahead after N s: the hold ended" "$(_dw_lines e2e '^tests/run: went ahead after [0-9]+ s: the hold ended$')" "1"
_dw_until 3 _dw_nomark "$LGM"; is "end to end: and once it has gone ahead no marker for the tick's root is left" "$(_dw_markers "$LGM")" "0"
_dw_until 90 _dw_saidorgone_f "$DW/e2e.penv" "$DWEB"; _dw_kill e2e "$DWEB"
is "end to end: and its suite runs, FELIX_HOLD_PASSED=1 inherited by its part" "$(cat "$DW/e2e.penv" 2>/dev/null)" "1"
rm -f "$DWK/pgrep.real" "$DWK/ps.real"
kill -KILL "$DWHP" 2>/dev/null; _dw_wait "$DWHP"
DWLEFT="$("$DWPS" -A -ww -o pid= -o command= 2>/dev/null | K="$DW/" LC_ALL=C awk 'index($0, ENVIRON["K"]) { printf "%s ", $1 }')"
for DWP in $DWLEFT; do kill -KILL "$DWP" 2>/dev/null; done
is "this part leaves no process of its own running (control)" "${DWLEFT:-none}" "none"
