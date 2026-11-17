_fc_init
# ======================================================================
# felix cost serves one reading at a time: slice 0 of the load governor,
# written blind from its contract (docs/2026-11-06-load-governor-design.md,
# section 5, C1-C13) with the new code unwritten and unread. Every records
# root is $FC/c75..., every home (so every cache directory and every lock) is
# one of its own under $FC/c75, and a grep placed first on PATH counts the
# scans (C13): one line a grep, one grep a scan for a root under 256 files.
# Left open by the contract, so asserted nowhere here:
# - a reading's file name and its format past "the first line names the key",
#   and a temporary file's name, so temporary-file pruning (C11) is not tried;
# - whether the usage line names --max-age; whether an empty
#   FELIX_COST_DEADLINE, or a value with leading zeros, is refused;
# - whether --max-age reads a reading's age from its mtime or its header;
# - the exit status of a caller ended by TERM or INT;
# - whether the text view of "served none" prints a files line or a served line;
# - the age C6's served line prints, past its being a whole number;
# - whether a call served from a kept reading prunes (C11 says "when written");
# - what TERM to the supervisor leaves in the cache directory, and what its
#   caller prints then;
# - which of C4's simultaneous callers scans, and so the order of their outputs;
# - the boundary of C11's 14 days (15 days is pruned, 13 days kept).
# Where the contract names no process, the supervisor is taken to be the
# parent of the scan's process-group leader ("forks, puts the child in its own
# group"), or that leader itself when its parent is the caller.
# ======================================================================
printf '\nfelix cost: one reading at a time (slice 0 of the load governor, blind)\n'

FCOROOTU=0; [ "$(id -u)" = 0 ] && FCOROOTU=1
FCOPERL=0; [ -n "$(type -P perl 2>/dev/null)" ] && FCOPERL=1
FCOGREAL="$(type -P grep)"
FCO="$FC/c75"; rm -rf "$FCO"; mkdir -p "$FCO/shim"; FCOSHIM="$FCO/shim"
FCOGLOG="$FCO/g.log"; : > "$FCOGLOG"
FCOW=2026-10-11T05:00:00Z;  FCOAS=2026-10-11T05:00Z      # inside the week of 2026-10-08T13:00Z
FCOW2=2026-10-14T20:00:00Z; FCOAS2=2026-10-14T20:00Z     # the same week, three days on
FCOSEQ=0; FCOLPID=""
FCOMYPG="$(perl -e 'print getpgrp(0)' 2>/dev/null)"

# The grep of this part: it writes its pid to FCO_GLOG and then runs the real
# grep. On request it records its process group (FCO_GPG), leaves a sleep
# behind in its group (FCO_GBG), ignores TERM (FCO_GTRAP), marks its start
# (FCO_GSTART) and sleeps first (FCO_GSLEEP), the sleep's pid in FCO_GLOG.sl.
cat > "$FCOSHIM/grep" <<'FCOSHIMEOF'
#!/bin/sh
printf '%s\n' "$$" >> "${FCO_GLOG:-/dev/null}"
if [ -n "${FCO_GPG:-}" ]; then perl -e 'print getpgrp(0), "\n"' >> "$FCO_GPG"; fi
if [ -n "${FCO_GBG:-}" ]; then sleep 300 </dev/null >/dev/null 2>&1 & printf '%s\n' "$!" >> "$FCO_GBG"; fi
if [ -n "${FCO_GTRAP:-}" ]; then trap '' TERM; fi
if [ -n "${FCO_GSTART:-}" ]; then : > "$FCO_GSTART"; fi
if [ -n "${FCO_GSLEEP:-}" ]; then
  sleep "$FCO_GSLEEP" </dev/null >/dev/null 2>&1 &
  printf '%s\n' "$!" >> "${FCO_GLOG:-/dev/null}.sl"
  wait "$!"
fi
exec "$FCO_GREAL" "$@"
FCOSHIMEOF
chmod 755 "$FCOSHIM/grep"

# is / has, skipped where perl is not on PATH: the lock and the supervisor need it (C10).
_fcoi() { if [ "$FCOPERL" = 1 ]; then is  "$1" "$2" "$3"; else skip "$1" "perl is not on PATH"; fi; }
_fcoh() { if [ "$FCOPERL" = 1 ]; then has "$1" "$2" "$3"; else skip "$1" "perl is not on PATH"; fi; }

# Inside a subshell: the directory and environment of one run. The knobs, set
# on the call: FCOH the HOME ("-" unsets it), FCCFG, FCNOW ("clock" leaves it
# unset), FCCAP as _fc's; FCODL is FELIX_COST_DEADLINE; FCOP replaces PATH;
# FCOGS, FCOGT, FCOGB, FCOGST and FCOGP are the grep's knobs above.
_fco_env() {
  cd "${FCCWD:?}" || exit 97
  unset FELIX_HOME FELIX_MEMORY CLAUDE_PLUGIN_ROOT CLAUDE_CONFIG_DIR FELIX_COST_CAP_M FELIX_COST_NOW FELIX_COST_DEADLINE \
        FCO_GSLEEP FCO_GTRAP FCO_GBG FCO_GSTART FCO_GPG
  if [ "${FCOH-}" = - ]; then unset HOME; else export HOME="${FCOH-$FCO/h0}"; fi
  export TMPDIR="$FCTMPD" FCO_GLOG="$FCOGLOG" FCO_GREAL="$FCOGREAL"
  case "${FCNOW-$FCOW}" in clock) ;; *) export FELIX_COST_NOW="${FCNOW-$FCOW}" ;; esac
  if [ -n "${FCCFG+x}" ]; then export CLAUDE_CONFIG_DIR="$FCCFG"; fi
  if [ -n "${FCCAP+x}" ]; then export FELIX_COST_CAP_M="$FCCAP"; fi
  if [ -n "${FCODL+x}" ]; then export FELIX_COST_DEADLINE="$FCODL"; fi
  if [ -n "${FCOGS:-}" ]; then export FCO_GSLEEP="$FCOGS"; fi
  if [ -n "${FCOGT:-}" ]; then export FCO_GTRAP=1; fi
  if [ -n "${FCOGB:-}" ]; then export FCO_GBG="$FCOGB"; fi
  if [ -n "${FCOGST:-}" ]; then export FCO_GSTART="$FCOGST"; fi
  if [ -n "${FCOGP:-}" ]; then export FCO_GPG="$FCOGP"; fi
  export PATH="${FCOP:-$FCOSHIM:$PATH}"
}
# A run in the background: _fco_start TAG ARGS... Its files are $FCO/run.TAG.*: out, err,
# pid (felix's own pid), rc (once it ended), sub (the subshell that waits for it) and t0.
# FCOSO sends its stdout elsewhere; FCOPG=1 starts it as a group leader with INT and QUIT
# at their defaults, as a terminal's foreground job would be.
_fco_start() {
  local o="$FCO/run.$1"; shift
  rm -f "$o.out" "$o.err" "$o.pid" "$o.rc" "$o.sub"
  printf '%s\n' "$SECONDS" > "$o.t0"
  ( _fco_env
    if [ "${FCOPG:-}" = 1 ]; then
      perl -e 'setpgrp(0, 0) or exit 126; $SIG{INT} = "DEFAULT"; $SIG{QUIT} = "DEFAULT"; exec { $ARGV[0] } @ARGV; exit 127' \
        "${FCOENG:-$REAL_HARNESS}/felix" cost "$@" >"${FCOSO:-$o.out}" 2>"$o.err" &
    else
      "${FCOENG:-$REAL_HARNESS}/felix" cost "$@" >"${FCOSO:-$o.out}" 2>"$o.err" &
    fi
    printf '%s\n' "$!" > "$o.pid"
    wait "$!"; printf '%s\n' "$?" > "$o.rc.tmp"; mv -f "$o.rc.tmp" "$o.rc"
  ) </dev/null >/dev/null 2>&1 &
  printf '%s\n' "$!" > "$o.sub"
}
# _fco_wait TAG BOUND: wait for the run until BOUND s after it started; past that, TERM it and then KILL it.
# FCORC is its status or "timeout", FCOEL the seconds since it started, and its output
# is read back as _fc's is (FCOUTF, FCERRF, FCOUT, FCERR, FCRC), so _fc_row and the rest read it.
_fco_wait() {
  local o="$FCO/run.$1" n=0 t0 p
  t0="$(cat "$o.t0")"
  while [ ! -f "$o.rc" ] && [ "$((SECONDS - t0))" -lt "$2" ]; do sleep 0.2; done
  FCOEL=$(( SECONDS - t0 ))
  if [ -f "$o.rc" ]; then FCORC="$(cat "$o.rc")"
  else
    FCORC=timeout; p="$(cat "$o.pid" 2>/dev/null)"
    [ -z "$p" ] || kill -TERM "$p" 2>/dev/null
    n=0; while [ ! -f "$o.rc" ] && [ "$n" -lt 25 ]; do sleep 0.2; n=$((n + 1)); done
    [ -f "$o.rc" ] || [ -z "$p" ] || kill -KILL "$p" 2>/dev/null
  fi
  wait "$(cat "$o.sub")" 2>/dev/null
  if [ -f "$o.out" ]; then cp "$o.out" "$FCOUTF"; else : > "$FCOUTF"; fi
  if [ -f "$o.err" ]; then cp "$o.err" "$FCERRF"; else : > "$FCERRF"; fi
  FCOUT="$(cat "$FCOUTF")"; FCERR="$(cat "$FCERRF")"; FCRC="$FCORC"
}
_fco() { _fco_start f "$@"; _fco_wait f 120; }
# What a fresh scan prints now, in a home of its own and with a grep log of its own: FCOREF.
_fco_ref() {
  FCOSEQ=$((FCOSEQ + 1)); mkdir -p "$FCO/ref$FCOSEQ"
  FCOH="$FCO/ref$FCOSEQ" FCOGLOG="$FCO/ref.glog" _fco "$@"
  FCOREF="$FCOUT"
}
# The number of greps the current log holds.
_fco_g() { awk 'END { print NR }' "$FCOGLOG"; }
# Until FILE exists, up to BOUND s: yes or no.
_fco_until() {
  local n=0 lim=$(( $2 * 5 ))
  while [ ! -e "$1" ] && [ "$n" -lt "$lim" ]; do sleep 0.2; n=$((n + 1)); done
  if [ -e "$1" ]; then printf yes; else printf no; fi
}
# A pid that runs (a zombie does not).
_fco_alive() {
  kill -0 "$1" 2>/dev/null || return 1
  case "$(ps -o stat= -p "$1" 2>/dev/null)" in *Z*) return 1 ;; esac
  return 0
}
# _fco_left BOUND FILE...: waits up to BOUND s for every pid the files list to end; prints those still running.
_fco_left() {
  local lim=$(( $1 * 5 )) n=0 p f left; shift
  while :; do
    left=""
    for f in "$@"; do [ -f "$f" ] || continue; while IFS= read -r p; do
      case "$p" in ''|*[!0-9]*) continue ;; esac; _fco_alive "$p" && left="$left $p"; done < "$f"; done
    if [ -z "$left" ] || [ "$n" -ge "$lim" ]; then break; fi
    sleep 0.2; n=$((n + 1))
  done
  printf '%s' "${left# }"
}
# KILL each pid the files list that still runs as this part's grep, or as one of its sleeps.
_fco_reap() {
  local f p c
  for f in "$@"; do [ -f "$f" ] || continue; while IFS= read -r p; do
    case "$p" in ''|*[!0-9]*) continue ;; esac
    _fco_alive "$p" || continue
    c="$(ps -o command= -p "$p" 2>/dev/null)"
    case "$c" in *"$FCOSHIM/grep"*|"$FCOGREAL "*"$FC/"*|"sleep "[0-9]*) kill -KILL "$p" 2>/dev/null ;; esac
  done < "$f"; done
}
# The cache directory of a home, its names sorted, and its shape: lock+N (N names besides lock).
_fco_d()  { printf '%s' "$1/.cache/felix/cost"; }
_fco_ls() {
  [ -d "$(_fco_d "$1")" ] || { printf '(no directory)'; return 0; }
  ls -A "$(_fco_d "$1")" | LC_ALL=C sort | awk '{ printf "%s%s", s, $0; s = " " }'
}
_fco_shape() {
  [ -d "$(_fco_d "$1")" ] || { printf '(no directory)'; return 0; }
  ls -A "$(_fco_d "$1")" | awk '$0 == "lock" { l = 1; next } { n++ } END { printf "%s+%d", l ? "lock" : "nolock", n }'
}
# The names besides lock, sorted, one a line.
_fco_rdgs() { [ -d "$(_fco_d "$1")" ] || return 0; ls -A "$(_fco_d "$1")" | LC_ALL=C sort | awk '$0 != "lock"'; }
# Names joined, sorted: _fco_join NAME...
_fco_join() { printf '%s\n' "$@" | LC_ALL=C sort | awk '{ printf "%s%s", s, $0; s = " " }'; }
# Hold a home's lock from a process of this part's (FCOLPID); FCOHELD is yes once it holds it.
_fco_lock() {
  local d; d="$(_fco_d "$1")"; mkdir -p "$d"; rm -f "$FCO/held"
  perl -MFcntl=:flock -e 'open(my $f, ">>", $ARGV[0]) or exit 3; flock($f, LOCK_EX) or exit 4; open(my $m, ">", $ARGV[1]); close $m; sleep 120' \
    "$d/lock" "$FCO/held" </dev/null >/dev/null 2>&1 &
  FCOLPID=$!
  FCOHELD="$(_fco_until "$FCO/held" 30)"
}
_fco_unlock() {
  [ -n "$FCOLPID" ] || return 0
  kill -TERM "$FCOLPID" 2>/dev/null; kill -KILL "$FCOLPID" 2>/dev/null; wait "$FCOLPID" 2>/dev/null; FCOLPID=""
}
# Whether anyone holds a home's lock: free, held, or "no lock file".
_fco_free() {
  perl -MFcntl=:flock -e 'open(my $f, "<", $ARGV[0]) or exit 3; exit(flock($f, LOCK_EX | LOCK_NB) ? 0 : 1)' "$(_fco_d "$1")/lock" 2>/dev/null
  case $? in 0) printf free ;; 1) printf held ;; *) printf 'no lock file' ;; esac
}
# Until a home holds a reading, up to BOUND s, or 5 s after every grep and sleep FILE lists has ended.
_fco_until_rdg() {
  local h="$1" lim=$(( $2 * 5 )) n=0 g=0; shift 2
  while [ "$n" -lt "$lim" ] && [ -z "$(_fco_rdgs "$h")" ] && [ "$g" -lt 25 ]; do
    [ -n "$(_fco_left 0 "$@")" ] || g=$((g + 1))
    sleep 0.2; n=$((n + 1))
  done
  if [ -n "$(_fco_rdgs "$h")" ]; then printf yes; else printf no; fi
}
# The line after the first whose first word is W, and the output without it.
_fco_after() { W="$1" awk 'p && !d { print; d = 1 } { p = ($1 == ENVIRON["W"]) }' "$FCOUTF"; }
_fco_sans()  { W="$1" awk 'p && !d { d = 1; p = 0; next } { print; p = ($1 == ENVIRON["W"]) }' "$FCOUTF"; }
# A local time DAYS ago, as touch -t reads it.
_fco_ago() { date -v-"$1"d +%Y%m%d%H%M.%S 2>/dev/null || date -d "-$1 days" +%Y%m%d%H%M.%S; }

# ---- the records ----------------------------------------------------------
# A root $FC/NAME: 10M and 20M in a session's transcript, 40M in its helper agent's.
_fco_root() {
  _fc_mk "$1"
  _fc_in "$FC/$1/projects/-Users-dev-c75/s1.jsonl" msg_C1 "$FCT0" m-c75a 10000000
  _fc_in "$FC/$1/projects/-Users-dev-c75/s1.jsonl" msg_C2 "$FCTB" m-c75b 20000000
  _fc_in "$FC/$1/projects/-Users-dev-c75/s1/subagents/a1.jsonl" msg_C3 "$FCT0" m-c75a 40000000
}
# One response more, 80M on 2026-10-09: the reading of the root before it is no longer current.
_fco_grow() { _fc_in "$FC/$1/projects/-Users-dev-c75/s1.jsonl" msg_C4 "$FCT0" m-c75b 80000000; }
# What --tsv prints: _fco_out a|b|none ASOF [SERVED [START END]]. a is the root, b the root
# grown; none is C5's rows when no reading is kept. SERVED, when given, is the served row's value.
_fco_out() {
  local k="$1" as="$2" sv="${3:-}" ws="${4:-2026-10-08T13:00Z}" we="${5:-2026-10-15T13:00Z}"
  printf 'cover\twindow_start\t%s\ncover\twindow_end\t%s\ncover\tsource\t$CLAUDE_CONFIG_DIR/projects\ncover\tcap_tokens\t905000000\n' "$ws" "$we"
  case "$k" in
    none) printf 'cover\tfiles_read\t0\ncover\tfiles_unread\t0\ncover\tresponses_unread\t0\ncover\tcoverage\tunknown\n' ;;
    *)    printf 'cover\tfiles_read\t2\ncover\tfiles_unread\t0\ncover\tresponses_unread\t0\ncover\tcoverage\tmeasured\n' ;;
  esac
  printf 'cover\tas_of\t%s\n' "$as"
  [ -z "$sv" ] || printf 'cover\tserved\t%s\n' "$sv"
  case "$k" in
    none) printf 'total\tall\tunknown\tunknown\tunknown\n' ;;
    a) printf 'total\tall\t70000000.00\t7.7\t3\nworktree\t-Users-dev-c75\t70000000.00\t7.7\t3\n'
       printf 'day\t2026-10-09\t50000000.00\t5.5\t2\nday\t2026-10-10\t20000000.00\t2.2\t1\n'
       printf 'model\tm-c75a\t50000000.00\t5.5\t2\nmodel\tm-c75b\t20000000.00\t2.2\t1\n' ;;
    b) printf 'total\tall\t150000000.00\t16.6\t4\nworktree\t-Users-dev-c75\t150000000.00\t16.6\t4\n'
       printf 'day\t2026-10-09\t130000000.00\t14.4\t3\nday\t2026-10-10\t20000000.00\t2.2\t1\n'
       printf 'model\tm-c75b\t100000000.00\t11.0\t2\nmodel\tm-c75a\t50000000.00\t5.5\t2\n' ;;
  esac
}
FCONONE_RUN='total    unknown (another felix cost run is reading now, and no earlier reading of this window is kept)'
FCOLAST_RUN="served   the reading made at $FCOAS; another felix cost run is reading now"

# ----------------------------------------------------------------------
# C1. Two things are new, --max-age and FELIX_COST_DEADLINE; an invalid value of either is refused as today's are.
# ----------------------------------------------------------------------
_fco_root c75z; mkdir -p "$FCO/h0"
FCOH="$FCO/h0" FCCFG="$FC/c75z" _fco --week --tsv --max-age 0
is  "felix cost one reading (C1): --max-age 0 is taken: status 0 and the week's total" \
    "$FCRC|$(_fc_row total all)" "0|$(printf 'total\tall\t70000000.00\t7.7\t3')"
FCOH="$FCO/h0" FCCFG="$FC/c75z" _fco --week --tsv --max-age 604800
is  "felix cost one reading (C1): --max-age 604800 is taken: status 0 and the week's total" \
    "$FCRC|$(_fc_row total all)" "0|$(printf 'total\tall\t70000000.00\t7.7\t3')"
for FCOV in 604801 -1 abc 1.5 ' 5' 1e3; do
  FCOH="$FCO/h0" FCCFG="$FC/c75z" _fco --week --tsv --max-age "$FCOV"
  is  "felix cost one reading (C1): --max-age [$FCOV] is refused: status 2, nothing on stdout, a message and the usage" \
      "$(_fc_usage_verdict)" "$FCUSAGE_OK"
done
FCOH="$FCO/h0" FCCFG="$FC/c75z" _fco --week --tsv --max-age
is  "felix cost one reading (C1): --max-age with no value is refused: status 2, nothing on stdout, a message and the usage" \
    "$(_fc_usage_verdict)" "$FCUSAGE_OK"
for FCOV in 0 86401 abc -1 2.5 '1 0'; do
  FCOH="$FCO/h0" FCCFG="$FC/c75z" FCODL="$FCOV" _fco --week --tsv
  is  "felix cost one reading (C1): FELIX_COST_DEADLINE [$FCOV] is refused: status 2, nothing on stdout, a message and the usage" \
      "$(_fc_usage_verdict)" "$FCUSAGE_OK"
done
for FCOV in 1800 86400; do
  FCOH="$FCO/h0" FCCFG="$FC/c75z" FCODL="$FCOV" _fco --week --tsv
  is  "felix cost one reading (C1): FELIX_COST_DEADLINE=$FCOV is taken: status 0 and the week's total" \
      "$FCRC|$(_fc_row total all)" "0|$(printf 'total\tall\t70000000.00\t7.7\t3')"
done

# ----------------------------------------------------------------------
# C2, C3, C12, C13: one scan makes a reading; every shape of report is served from it while nothing changes.
# ----------------------------------------------------------------------
_fco_root c75a; FCOH1="$FCO/h1"; mkdir -p "$FCOH1"; FCOGLOG="$FCO/g.a"; : > "$FCOGLOG"
FCOH="$FCOH1" FCCFG="$FC/c75a" _fco --week --tsv
is  "felix cost one reading (C12): a first scan prints the week as before, byte for byte, status 0" \
    "$FCRC|$FCOUT" "0|$(_fco_out a "$FCOAS")"
is  "felix cost one reading (C13): a scan of a root of two transcripts runs grep once" "$(_fco_g)" 1
_fcoi "felix cost one reading (C2): after one scan of one window the cache directory holds the lock and one reading" \
    "$(_fco_shape "$FCOH1")" "lock+1"
is  "felix cost one reading (C2): the readings are not kept under ~/.felix" "$([ -e "$FCOH1/.felix" ] && echo there || echo absent)" absent
FCOA1="$(_fco_rdgs "$FCOH1")"
FCOH="$FCOH1" FCCFG="$FC/c75a" _fco --week --tsv
_fcoi "felix cost one reading (C3): the same call again prints the same bytes and runs no grep" \
    "$FCRC|$FCOUT|greps=$(_fco_g)" "0|$(_fco_out a "$FCOAS")|greps=1"
FCOH="$FCOH1" FCCFG="$FC/c75a" FCNOW="$FCOW2" _fco --week --tsv
_fcoi "felix cost one reading (C3): a current reading is served with as_of now (FELIX_COST_NOW three days on) and no grep" \
    "$FCOUT|greps=$(_fco_g)" "$(_fco_out a "$FCOAS2")|greps=1"
FCCFG="$FC/c75a" _fco_ref --week
FCOH="$FCOH1" FCCFG="$FC/c75a" _fco --week
_fcoi "felix cost one reading (C3): the text view served from the reading is what a fresh scan prints, with no grep" \
    "$FCOUT|greps=$(_fco_g)" "$FCOREF|greps=1"
FCCFG="$FC/c75a" _fco_ref --week --by model --top 1 --tsv
FCOH="$FCOH1" FCCFG="$FC/c75a" _fco --week --by model --top 1 --tsv
_fcoi "felix cost one reading (C3): --by model --top 1 served from the reading is what a fresh scan prints, with no grep" \
    "$FCOUT|greps=$(_fco_g)" "$FCOREF|greps=1"
FCCFG="$FC/c75a" FCCAP=100 _fco_ref --week --by day
FCOH="$FCOH1" FCCFG="$FC/c75a" FCCAP=100 _fco --week --by day
_fcoi "felix cost one reading (C3): a cap of 100M and --by day, served from the reading, is what a fresh scan prints, with no grep" \
    "$FCOUT|greps=$(_fco_g)" "$FCOREF|greps=1"
_fcoi "felix cost one reading (C2): --by, --top, --tsv, the cap and as_of are not in the key: still the lock and the one reading" \
    "$(_fco_ls "$FCOH1")" "$(_fco_join lock "$FCOA1")"
# The root through a link: the key holds the root resolved to a physical path.
ln -s "$FC/c75a" "$FC/c75alink"
FCOH="$FCOH1" FCCFG="$FC/c75alink" _fco --week --tsv
_fcoi "felix cost one reading (C2): the root named through a link is the same key: served with no grep, no reading added" \
    "$FCOUT|greps=$(_fco_g)|$(_fco_ls "$FCOH1")" "$(_fco_out a "$FCOAS")|greps=1|$(_fco_join lock "$FCOA1")"
# Served while another holds the lock: a current reading takes no lock (C3).
_fco_lock "$FCOH1"
FCOH="$FCOH1" FCCFG="$FC/c75a" _fco --week --tsv
_fcoi "felix cost one reading (C3): while another holds the lock a current reading is served as if just read, at once, no grep" \
    "held=$FCOHELD|$FCOUT|greps=$(_fco_g)|quick=$([ "$FCOEL" -le 20 ] && echo yes || echo no)" \
    "held=yes|$(_fco_out a "$FCOAS")|greps=1|quick=yes"
_fco_unlock
# A second window is a second key.
FCOH="$FCOH1" FCCFG="$FC/c75a" _fco --since 2026-10-01 --tsv
is  "felix cost one reading (C12): a --since window prints as before" \
    "$FCRC|$FCOUT" "0|$(_fco_out a "$FCOAS" "" 2026-10-01T00:00Z now)"
_fcoi "felix cost one reading (C2): a second window adds one reading: the lock and two" \
    "$(_fco_shape "$FCOH1")|greps=$(_fco_g)" "lock+2|greps=2"
FCOH="$FCOH1" FCCFG="$FC/c75a" _fco --since 2026-10-01 --tsv
_fcoi "felix cost one reading (C3): the second window is served from its own reading, no grep" \
    "$FCOUT|greps=$(_fco_g)" "$(_fco_out a "$FCOAS" "" 2026-10-01T00:00Z now)|greps=2"
# A change under the root: an appended response, a new directory, a mode change.
sleep 1; _fco_grow c75a
FCOH="$FCOH1" FCCFG="$FC/c75a" _fco --week --tsv
_fcoi "felix cost one reading (C3): a response appended to a transcript makes the reading not current: one more grep, the new total" \
    "$FCOUT|greps=$(_fco_g)" "$(_fco_out b "$FCOAS")|greps=3"
_fcoi "felix cost one reading (C2): the rescan rewrites its key's reading and adds none" \
    "$(_fco_shape "$FCOH1")" "lock+2"
sleep 1; mkdir "$FC/c75a/projects/-Users-dev-empty"
FCOH="$FCOH1" FCCFG="$FC/c75a" _fco --week --tsv
_fcoi "felix cost one reading (C3): a new directory under the root makes the reading not current: one more grep, same numbers" \
    "$FCOUT|greps=$(_fco_g)" "$(_fco_out b "$FCOAS")|greps=4"
sleep 1; chmod 600 "$FC/c75a/projects/-Users-dev-c75/s1/subagents/a1.jsonl"
FCOH="$FCOH1" FCCFG="$FC/c75a" _fco --week --tsv
_fcoi "felix cost one reading (C3): a transcript's mode changed (its ctime) makes the reading not current: one more grep" \
    "$FCOUT|greps=$(_fco_g)" "$(_fco_out b "$FCOAS")|greps=5"
FCOH="$FCOH1" FCCFG="$FC/c75a" _fco --week --tsv
_fcoi "felix cost one reading (C3): with nothing changed since, the rescan's reading is served, no grep" \
    "$FCOUT|greps=$(_fco_g)" "$(_fco_out b "$FCOAS")|greps=5"

# A root whose find reports an error (a dangling link) is never current.
_fco_root c75e; FCOH2="$FCO/h2"; mkdir -p "$FCOH2"; FCOGLOG="$FCO/g.e"; : > "$FCOGLOG"
ln -s "$FC/c75e/gone.jsonl" "$FC/c75e/projects/-Users-dev-c75/gone.jsonl"
FCOH="$FCOH2" FCCFG="$FC/c75e" _fco --week --tsv; FCOE1="$FCOUT"
FCOH="$FCOH2" FCCFG="$FC/c75e" _fco --week --tsv
is  "felix cost one reading (C3): a root holding a dangling link is scanned on every call: two calls, two greps, the same report" \
    "$FCOUT|greps=$(_fco_g)" "$FCOE1|greps=2"
_fco_lock "$FCOH2"
FCOH="$FCOH2" FCCFG="$FC/c75e" _fco --week --tsv
_fcoi "felix cost one reading (C3): a root holding a dangling link is not current, so under another's lock its reading is served last" \
    "held=$FCOHELD|$(_fc_cover served)|greps=$(_fco_g)" "held=yes|last|greps=2"
_fco_unlock

# The key holds the checksum of lib/cost.sh: an engine whose cost.sh differs by one comment scans again.
_fco_root c75b; FCOH3="$FCO/h3"; mkdir -p "$FCOH3" "$FCO/eng/harness"; FCOGLOG="$FCO/g.b"; : > "$FCOGLOG"
cp "$REAL_HARNESS/felix" "$FCO/eng/harness/felix"; cp -R "$REAL_HARNESS/lib" "$FCO/eng/harness/lib"
printf '# part 1075: one line more, so its checksum differs\n' >> "$FCO/eng/harness/lib/cost.sh"
FCOH="$FCOH3" FCCFG="$FC/c75b" _fco --week --tsv
FCOH="$FCOH3" FCCFG="$FC/c75b" FCOENG="$FCO/eng/harness" _fco --week --tsv
_fcoi "felix cost one reading (C2): an engine whose lib/cost.sh has another checksum is another key: one more grep, one more reading" \
    "$FCOUT|greps=$(_fco_g)|$(_fco_shape "$FCOH3")" "$(_fco_out a "$FCOAS")|greps=2|lock+2"
FCOH="$FCOH3" FCCFG="$FC/c75b" _fco --week --tsv
_fcoi "felix cost one reading (C3): the first engine's reading is still served to it, no grep" "greps=$(_fco_g)" "greps=2"

# ----------------------------------------------------------------------
# C4. One run at a time: three callers in the same second make one scan between them.
# ----------------------------------------------------------------------
_fco_root c75c; FCOH4="$FCO/h4"; mkdir -p "$FCOH4"; FCOGLOG="$FCO/g.c"; : > "$FCOGLOG"
for FCOV in 1 2 3; do FCOH="$FCOH4" FCCFG="$FC/c75c" FCOGS=10 _fco_start "c$FCOV" --week --tsv; done
FCOC=""; FCOCF=0
for FCOV in 1 2 3; do
  _fco_wait "c$FCOV" 90; FCOC="$FCOC $FCRC"
  if [ "$FCOUT" = "$(_fco_out a "$FCOAS")" ]; then FCOCF=$((FCOCF + 1))
  elif [ "$FCOUT" != "$(_fco_out none "$FCOAS" none)" ]; then FCOCF=$((FCOCF + 100)); fi
done
_fcoi "felix cost one reading (C4): three callers at once make one scan between them: one grep, one reading" \
    "greps=$(_fco_g)|$(_fco_shape "$FCOH4")" "greps=1|lock+1"
_fcoi "felix cost one reading (C4): each of the three ends with status 0" "${FCOC# }" "0 0 0"
_fcoi "felix cost one reading (C4): each prints the reading or C5's served none, and at least one the reading" \
    "$([ "$FCOCF" -ge 1 ] && [ "$FCOCF" -le 3 ] && echo yes || echo "no ($FCOCF)")" yes
_fcoi "felix cost one reading (C4): once they ended, the lock is free" "$(_fco_free "$FCOH4")" free
_fco_reap "$FCOGLOG" "$FCOGLOG.sl"

# ----------------------------------------------------------------------
# C5. Another run holds the lock: the caller returns at once, status 0, with what is kept.
# ----------------------------------------------------------------------
_fco_root c75d; FCOH5="$FCO/h5"; mkdir -p "$FCOH5"; FCOGLOG="$FCO/g.d"; : > "$FCOGLOG"
_fco_lock "$FCOH5"
FCOH="$FCOH5" FCCFG="$FC/c75d" _fco --week --tsv
_fcoi "felix cost one reading (C5): under another's lock with no reading kept: status 0 at once, the rows of served none, no grep" \
    "held=$FCOHELD|$FCRC|quick=$([ "$FCOEL" -le 20 ] && echo yes || echo no)|$FCOUT|greps=$(_fco_g)" \
    "held=yes|0|quick=yes|$(_fco_out none "$FCOAS" none)|greps=0"
FCOH="$FCOH5" FCCFG="$FC/c75d" _fco --week
_fcoi "felix cost one reading (C5, text): with none kept the total line says another run is reading now and none is kept" \
    "$FCRC|$(awk '$1 == "total" { print; exit }' "$FCOUTF")" "0|$FCONONE_RUN"
_fcoi "felix cost one reading (C5, text): with none kept, calls unknown follows the total line" "$(_fco_after total)" "calls    unknown"
_fcoi "felix cost one reading (C5, text): with none kept, the window line is today's" \
    "$(awk '$1 == "window" { print; exit }' "$FCOUTF")" "window   2026-10-08T13:00Z to 2026-10-15T13:00Z"
_fco_unlock

# C5 with a reading kept, and C6 --max-age, on one root: scan, then change it.
_fco_root c75f; FCOH6="$FCO/h6"; mkdir -p "$FCOH6"; FCOGLOG="$FCO/g.f"; : > "$FCOGLOG"
FCCFG="$FC/c75f" _fco_ref --week; FCOATXT="$FCOREF"
FCOH="$FCOH6" FCCFG="$FC/c75f" _fco --week --tsv
FCOF1="$(_fco_rdgs "$FCOH6")"; [ -z "$FCOF1" ] || cp -p "$(_fco_d "$FCOH6")/$FCOF1" "$FCO/f1.save"
sleep 1; _fco_grow c75f
FCOH="$FCOH6" FCCFG="$FC/c75f" FCNOW="$FCOW2" _fco --week --tsv --max-age 3600
_fcoi "felix cost one reading (C6): --max-age 3600 serves the kept reading unchecked: its numbers, its as_of, served aged, no grep" \
    "$FCRC|$FCOUT|greps=$(_fco_g)" "0|$(_fco_out a "$FCOAS" aged)|greps=1"
FCOH="$FCOH6" FCCFG="$FC/c75f" FCNOW="$FCOW2" _fco --week --max-age 3600
FCOV="$(_fco_after window)"; FCORE='^served   the reading made at 2026-10-11T05:00Z, [0-9]+ s ago \(--max-age 3600\)$'
_fcoi "felix cost one reading (C6, text): the line after window says the reading made at its as_of, its age in seconds, and --max-age 3600" \
    "$([[ $FCOV =~ $FCORE ]] && echo yes || echo "no [$FCOV]")" yes
_fcoi "felix cost one reading (C6, text): past the served line, the text is the reading's" "$(_fco_sans window)" "$FCOATXT"
_fco_lock "$FCOH6"
FCOH="$FCOH6" FCCFG="$FC/c75f" FCNOW="$FCOW2" _fco --week --tsv --max-age 3600
_fcoi "felix cost one reading (C6): under another's lock --max-age still serves the reading aged, at once" \
    "held=$FCOHELD|$FCOUT|quick=$([ "$FCOEL" -le 20 ] && echo yes || echo no)" "held=yes|$(_fco_out a "$FCOAS" aged)|quick=yes"
FCOH="$FCOH6" FCCFG="$FC/c75f" FCNOW="$FCOW2" _fco --week --tsv
_fcoi "felix cost one reading (C5): under another's lock a kept reading not current is printed at once: its as_of, served last, no grep" \
    "$FCRC|quick=$([ "$FCOEL" -le 20 ] && echo yes || echo no)|$FCOUT|greps=$(_fco_g)" \
    "0|quick=yes|$(_fco_out a "$FCOAS" last)|greps=1"
FCOH="$FCOH6" FCCFG="$FC/c75f" FCNOW="$FCOW2" _fco --week
_fcoi "felix cost one reading (C5, text): the line after window says the reading made at its as_of, and another run is reading now" \
    "$(_fco_after window)" "$FCOLAST_RUN"
_fcoi "felix cost one reading (C5, text): past the served line, the text is the reading's" "$(_fco_sans window)" "$FCOATXT"
_fcoi "felix cost one reading (C5): serving it left the reading as it was" \
    "$(_fco_ls "$FCOH6")|$(cmp -s "$FCO/f1.save" "$(_fco_d "$FCOH6")/$FCOF1" && echo same || echo changed)" "$(_fco_join lock "$FCOF1")|same"
_fco_unlock
sleep 2
FCOH="$FCOH6" FCCFG="$FC/c75f" _fco --week --tsv --max-age 1
_fcoi "felix cost one reading (C6): a reading older than --max-age goes on to C3: a rescan, the new numbers, no served row" \
    "$FCRC|$FCOUT|greps=$(_fco_g)" "0|$(_fco_out b "$FCOAS")|greps=2"
sleep 1
FCOH="$FCOH6" FCCFG="$FC/c75f" FCNOW="$FCOW2" _fco --week --tsv --max-age 0
_fcoi "felix cost one reading (C6): --max-age 0 with a current reading goes on to C3: served as just read, as_of now, no grep" \
    "$FCOUT|greps=$(_fco_g)" "$(_fco_out b "$FCOAS2")|greps=2"
mkdir -p "$FCO/h6b"
FCOH="$FCO/h6b" FCCFG="$FC/c75f" _fco --week --tsv --max-age 3600
_fcoi "felix cost one reading (C6): --max-age with no reading kept scans: the numbers, no served row, one grep" \
    "$FCRC|$FCOUT|greps=$(_fco_g)" "0|$(_fco_out b "$FCOAS")|greps=3"

# ----------------------------------------------------------------------
# C7. The deadline, five runs at once, each in a home of its own: no reading kept (--tsv and text),
# a reading kept (--tsv and text), and a scan that ignores TERM.
# ----------------------------------------------------------------------
_fco_root c75g; _fco_root c75i
mkdir -p "$FCO/h7t" "$FCO/h7x" "$FCO/h8t" "$FCO/h8x" "$FCO/h9"
FCCFG="$FC/c75i" _fco_ref --week; FCOITXT="$FCOREF"
for FCOV in h8t h8x; do FCOH="$FCO/$FCOV" FCCFG="$FC/c75i" FCOGLOG="$FCO/g.i0" _fco --week --tsv; done
FCOI8T="$(_fco_rdgs "$FCO/h8t")"; [ -z "$FCOI8T" ] || cp -p "$(_fco_d "$FCO/h8t")/$FCOI8T" "$FCO/i8t.save"
sleep 1; _fco_grow c75i
for FCOV in g.7t g.7x g.8t g.8x g.9; do : > "$FCO/$FCOV"; done
FCOH="$FCO/h7t" FCCFG="$FC/c75g" FCODL=2 FCOGS=120 FCOGLOG="$FCO/g.7t" _fco_start 7t --week --tsv
FCOH="$FCO/h7x" FCCFG="$FC/c75g" FCODL=2 FCOGS=120 FCOGLOG="$FCO/g.7x" _fco_start 7x --week
FCOH="$FCO/h8t" FCCFG="$FC/c75i" FCODL=2 FCOGS=120 FCOGLOG="$FCO/g.8t" FCNOW="$FCOW2" _fco_start 8t --week --tsv
FCOH="$FCO/h8x" FCCFG="$FC/c75i" FCODL=2 FCOGS=120 FCOGLOG="$FCO/g.8x" FCNOW="$FCOW2" _fco_start 8x --week
FCOH="$FCO/h9"  FCCFG="$FC/c75g" FCODL=2 FCOGS=120 FCOGT=1 FCOGLOG="$FCO/g.9" _fco_start 9 --week --tsv
_fco_wait 7t 35
_fcoi "felix cost one reading (C7): a scan past FELIX_COST_DEADLINE=2 with no reading kept: status 0 within 30 s, the rows of served none" \
    "$FCRC|quick=$([ "$FCOEL" -le 30 ] && echo yes || echo "no ($FCOEL s)")|$FCOUT" "0|quick=yes|$(_fco_out none "$FCOAS" none)"
_fco_wait 7x 35
_fcoi "felix cost one reading (C7, text): with none kept the total line says the reading did not finish within 2 s" \
    "$FCRC|$(awk '$1 == "total" { print; exit }' "$FCOUTF")" \
    "0|total    unknown (the reading did not finish within 2 s, and no earlier reading of this window is kept)"
_fco_wait 8t 35
_fcoi "felix cost one reading (C7): a scan past its deadline with a reading kept: status 0 within 30 s, the reading's rows, served last" \
    "$FCRC|quick=$([ "$FCOEL" -le 30 ] && echo yes || echo "no ($FCOEL s)")|$FCOUT" "0|quick=yes|$(_fco_out a "$FCOAS" last)"
_fco_wait 8x 35
_fcoi "felix cost one reading (C7, text): the line after window says the reading made at its as_of, and the new one did not finish within 2 s" \
    "$(_fco_after window)" "served   the reading made at $FCOAS; the new reading did not finish within 2 s"
_fcoi "felix cost one reading (C7, text): past the served line, the text is the kept reading's" "$(_fco_sans window)" "$FCOITXT"
_fco_wait 9 45
_fcoi "felix cost one reading (C7): a scan that ignores TERM is killed 5 s after its deadline: status 0 within 40 s, served none" \
    "$FCRC|quick=$([ "$FCOEL" -le 40 ] && echo yes || echo "no ($FCOEL s)")|$FCOUT" "0|quick=yes|$(_fco_out none "$FCOAS" none)"
_fcoi "felix cost one reading (C7): a scan cut at its deadline writes no reading and leaves no temporary file: only the lock" \
    "$(_fco_ls "$FCO/h7t")|$(_fco_ls "$FCO/h7x")|$(_fco_ls "$FCO/h9")" "lock|lock|lock"
_fcoi "felix cost one reading (C7): with a reading kept, a scan cut at its deadline leaves the lock and that reading, unchanged" \
    "$(_fco_ls "$FCO/h8t")|$(cmp -s "$FCO/i8t.save" "$(_fco_d "$FCO/h8t")/$FCOI8T" && echo same || echo changed)" \
    "$(_fco_join lock "$FCOI8T")|same"
_fcoi "felix cost one reading (C7): every grep of a scan cut at its deadline, and its sleep, is gone within 10 s" \
    "started=$([ -s "$FCO/g.7t" ] && [ -s "$FCO/g.8t" ] && echo yes || echo no)|left=$(_fco_left 10 "$FCO"/g.7t* "$FCO"/g.7x* "$FCO"/g.8t* "$FCO"/g.8x*)" \
    "started=yes|left="
_fcoi "felix cost one reading (C7): a grep that ignores TERM is gone within 10 s, killed" \
    "started=$([ -s "$FCO/g.9" ] && echo yes || echo no)|left=$(_fco_left 10 "$FCO"/g.9*)" "started=yes|left="
_fcoi "felix cost one reading (C7): after a deadline the lock is free" \
    "$(_fco_free "$FCO/h7t") $(_fco_free "$FCO/h8t") $(_fco_free "$FCO/h9")" "free free free"
_fco_reap "$FCO"/g.7t* "$FCO"/g.7x* "$FCO"/g.8t* "$FCO"/g.8x* "$FCO"/g.9*

# The caller waits for its own run; the scan runs in a group of its own; what is left in that group is killed.
_fco_root c75h; FCOH10="$FCO/h10"; mkdir -p "$FCOH10"; FCOGLOG="$FCO/g.h"; : > "$FCOGLOG"; : > "$FCO/h.bg"; : > "$FCO/h.pg"
FCOH="$FCOH10" FCCFG="$FC/c75h" FCOGS=4 FCOGB="$FCO/h.bg" FCOGP="$FCO/h.pg" _fco --week --tsv
is  "felix cost one reading (C7): a caller waits for its own scan of 4 s, within the deadline, and prints its numbers" \
    "$FCRC|waited=$([ "$FCOEL" -ge 4 ] && echo yes || echo "no ($FCOEL s)")|$FCOUT" "0|waited=yes|$(_fco_out a "$FCOAS")"
FCOPG1="$(head -n 1 "$FCO/h.pg")"
_fcoi "felix cost one reading (C7): the scan's grep runs in a process group other than its caller's" \
    "$([ -n "$FCOPG1" ] && [ -n "$FCOMYPG" ] && [ "$FCOPG1" != "$FCOMYPG" ] && echo own || echo "the caller's [$FCOPG1]")" own
_fcoi "felix cost one reading (C7): when the scan ends, what it left in its group (a sleep) is killed within 10 s" \
    "started=$([ -s "$FCO/h.bg" ] && echo yes || echo no)|left=$(_fco_left 10 "$FCO/h.bg")" "started=yes|left="
_fco_reap "$FCO/h.bg" "$FCOGLOG" "$FCOGLOG.sl"

# ----------------------------------------------------------------------
# C8. The caller can die, and the work is not lost.
# ----------------------------------------------------------------------
# TERM to felix alone, its stdout a pipe: the pipe closes at once, and the scan goes on to a reading.
_fco_root c75k; FCOH11="$FCO/h11"; mkdir -p "$FCOH11"; FCOGLOG="$FCO/g.k"; : > "$FCOGLOG"
rm -f "$FCO/k.fifo" "$FCO/k.eof" "$FCO/k.start"; mkfifo "$FCO/k.fifo"
( cat "$FCO/k.fifo" > "$FCO/k.read"; : > "$FCO/k.eof" ) </dev/null >/dev/null 2>&1 &
FCORD=$!
FCOH="$FCOH11" FCCFG="$FC/c75k" FCOGS=15 FCOGST="$FCO/k.start" FCOSO="$FCO/k.fifo" _fco_start k --week --tsv
FCOV="$(_fco_until "$FCO/k.start" 60)"
FCOKP="$(cat "$FCO/run.k.pid" 2>/dev/null)"
[ "$FCOV" != yes ] || [ -z "$FCOKP" ] || kill -TERM "$FCOKP" 2>/dev/null
FCOEOF="$(_fco_until "$FCO/k.eof" 8)"
_fco_wait k 30
_fcoi "felix cost one reading (C8): TERM to felix alone mid-scan closes its stdout pipe within 8 s: nothing else holds it" \
    "started=$FCOV|eof=$FCOEOF" "started=yes|eof=yes"
_fcoi "felix cost one reading (C8): after TERM to its caller the scan goes on and writes the reading" \
    "$(_fco_until_rdg "$FCOH11" 90 "$FCOGLOG" "$FCOGLOG.sl")" yes
FCOH="$FCOH11" FCCFG="$FC/c75k" _fco --week --tsv
_fcoi "felix cost one reading (C8): the reading the orphaned scan wrote is served: its numbers, no further grep" \
    "$FCOUT|greps=$(_fco_g)" "$(_fco_out a "$FCOAS")|greps=1"
_fcoi "felix cost one reading (C8): after the orphaned scan the lock is free and its greps are gone" \
    "$(_fco_free "$FCOH11")|left=$(_fco_left 10 "$FCOGLOG" "$FCOGLOG.sl")" "free|left="
# The reader ends once every writer has closed the pipe; one that never saw a writer is let go by an open that cannot block.
[ "$(_fco_until "$FCO/k.eof" 30)" = yes ] \
  || perl -MFcntl -e 'sysopen(my $f, $ARGV[0], O_WRONLY | O_NONBLOCK)' "$FCO/k.fifo" 2>/dev/null
[ "$(_fco_until "$FCO/k.eof" 5)" = yes ] || kill -KILL "$FCORD" 2>/dev/null
wait "$FCORD" 2>/dev/null
_fco_reap "$FCOGLOG" "$FCOGLOG.sl"

# A Ctrl-C: INT to felix's whole group ends felix at once; the scan, not in that group, goes on, and QUIT and HUP change nothing.
_fco_root c75l; FCOH12="$FCO/h12"; mkdir -p "$FCOH12"; FCOGLOG="$FCO/g.l"; : > "$FCOGLOG"; rm -f "$FCO/l.start"
FCOH="$FCOH12" FCCFG="$FC/c75l" FCOGS=20 FCOGST="$FCO/l.start" FCOPG=1 _fco_start l --week --tsv
FCOV="$(_fco_until "$FCO/l.start" 60)"
FCOLP="$(cat "$FCO/run.l.pid" 2>/dev/null)"
FCOLG="$(perl -e 'print getpgrp($ARGV[0])' "${FCOLP:-0}" 2>/dev/null)"
FCOSENT=no
if [ "$FCOV" = yes ] && [ -n "$FCOLP" ] && [ "$FCOLG" = "$FCOLP" ] && [ "$FCOLG" != "$FCOMYPG" ]; then
  kill -INT -- "-$FCOLP" 2>/dev/null; FCOSENT=yes
fi
_fco_wait l 10
_fcoi "felix cost one reading (C8): INT to felix's process group, as a Ctrl-C sends it, ends felix within 10 s" \
    "sent=$FCOSENT|ended=$([ "$FCRC" != timeout ] && echo yes || echo no)" "sent=yes|ended=yes"
[ "$FCOSENT" != yes ] || { kill -QUIT -- "-$FCOLP" 2>/dev/null; kill -HUP -- "-$FCOLP" 2>/dev/null; }
_fcoi "felix cost one reading (C8): after INT, QUIT and HUP to felix's group the scan goes on and writes the reading" \
    "$(_fco_until_rdg "$FCOH12" 90 "$FCOGLOG" "$FCOGLOG.sl")" yes
FCOH="$FCOH12" FCCFG="$FC/c75l" _fco --week --tsv
_fcoi "felix cost one reading (C8): the reading written after the Ctrl-C is served: its numbers, no further grep" \
    "$FCOUT|greps=$(_fco_g)" "$(_fco_out a "$FCOAS")|greps=1"
_fco_reap "$FCOGLOG" "$FCOGLOG.sl"

# TERM to the supervisor itself: it kills the scan's group and ends, and the lock goes with it.
_fco_root c75m; FCOH13="$FCO/h13"; mkdir -p "$FCOH13"; FCOGLOG="$FCO/g.m"; : > "$FCOGLOG"; : > "$FCO/m.pg"; rm -f "$FCO/m.start"
FCOH="$FCOH13" FCCFG="$FC/c75m" FCOGS=40 FCOGST="$FCO/m.start" FCOGP="$FCO/m.pg" _fco_start m --week --tsv
FCOV="$(_fco_until "$FCO/m.start" 60)"
FCOMP="$(cat "$FCO/run.m.pid" 2>/dev/null)"; FCOMG="$(head -n 1 "$FCO/m.pg")"; FCOSUP=""
if [ "$FCOV" = yes ] && [ -n "$FCOMG" ] && [ -n "$FCOMYPG" ] && [ "$FCOMG" != "$FCOMYPG" ] && [ "$FCOMG" != 1 ]; then
  FCOSUP="$(ps -o ppid= -p "$FCOMG" 2>/dev/null | awk '{ print $1 }')"
  [ "$FCOSUP" != "$FCOMP" ] || FCOSUP="$FCOMG"
  case "$FCOSUP" in ''|1|"$$"|"$FCOMYPG") FCOSUP="" ;; esac
fi
[ -z "$FCOSUP" ] || kill -TERM "$FCOSUP" 2>/dev/null
_fcoi "felix cost one reading (C8): TERM to the supervisor kills the scan's group: its grep and sleep are gone within 15 s" \
    "supervisor=$([ -n "$FCOSUP" ] && echo found || echo none)|left=$(_fco_left 15 "$FCOGLOG" "$FCOGLOG.sl")" "supervisor=found|left="
_fcoi "felix cost one reading (C8): TERM to the supervisor releases the lock" \
    "$(FCOV=0; while [ "$(_fco_free "$FCOH13")" != free ] && [ "$FCOV" -lt 50 ]; do sleep 0.2; FCOV=$((FCOV + 1)); done; _fco_free "$FCOH13")" free
_fco_wait m 50
_fcoi "felix cost one reading (C8): TERM to the supervisor lets its caller end within 20 s, its scan of 40 s cut" \
    "$([ "$FCRC" != timeout ] && [ "$FCOEL" -le 20 ] && echo yes || echo "no ($FCRC, $FCOEL s)")" yes
_fco_reap "$FCOGLOG" "$FCOGLOG.sl"

# ----------------------------------------------------------------------
# C9. A reading that does not parse, or whose first line names another key, is absent.
# ----------------------------------------------------------------------
_fco_root c75n; FCOH14="$FCO/h14"; mkdir -p "$FCOH14"; FCOGLOG="$FCO/g.n"; : > "$FCOGLOG"
FCOH="$FCOH14" FCCFG="$FC/c75n" _fco --week --tsv; FCONW="$(_fco_rdgs "$FCOH14")"
FCOH="$FCOH14" FCCFG="$FC/c75n" _fco --since 2026-10-01 --tsv
FCONS="$(_fco_rdgs "$FCOH14" | awk -v w="$FCONW" '$0 != w')"
FCOND="$(_fco_d "$FCOH14")"
if [ -n "$FCONW" ] && [ -f "$FCOND/$FCONW" ]; then
  cp -p "$FCOND/$FCONW" "$FCO/nw.save"; printf 'not a reading\n' > "$FCOND/$FCONW"; touch -r "$FCO/nw.save" "$FCOND/$FCONW"
fi
_fco_lock "$FCOH14"
FCOH="$FCOH14" FCCFG="$FC/c75n" _fco --week --tsv
_fcoi "felix cost one reading (C9): a reading that does not parse is absent: under another's lock the rows of served none" \
    "held=$FCOHELD|$FCOUT" "held=yes|$(_fco_out none "$FCOAS" none)"
_fco_unlock
FCOH="$FCOH14" FCCFG="$FC/c75n" _fco --week --tsv
_fcoi "felix cost one reading (C9): a reading that does not parse is absent: a rescan prints the numbers" \
    "$FCOUT|greps=$(_fco_g)" "$(_fco_out a "$FCOAS")|greps=3"
if [ -n "$FCONW" ] && [ -n "$FCONS" ] && [ -f "$FCOND/$FCONS" ]; then
  cp -p "$FCOND/$FCONS" "$FCO/ns.save"; cat "$FCOND/$FCONW" > "$FCOND/$FCONS"; touch -r "$FCO/ns.save" "$FCOND/$FCONS"
fi
_fco_lock "$FCOH14"
FCOH="$FCOH14" FCCFG="$FC/c75n" _fco --since 2026-10-01 --tsv
_fcoi "felix cost one reading (C9): a reading whose first line names another key is absent: under another's lock served none" \
    "held=$FCOHELD|$FCOUT" "held=yes|$(_fco_out none "$FCOAS" none 2026-10-01T00:00Z now)"
_fco_unlock
FCOH="$FCOH14" FCCFG="$FC/c75n" _fco --since 2026-10-01 --tsv
_fcoi "felix cost one reading (C9): a reading whose first line names another key is absent: a rescan prints its window's numbers" \
    "$FCOUT|greps=$(_fco_g)" "$(_fco_out a "$FCOAS" "" 2026-10-01T00:00Z now)|greps=4"

# ----------------------------------------------------------------------
# C10. Without the means, felix cost scans inline as before and writes nothing.
# ----------------------------------------------------------------------
_fco_root c75o; FCOGLOG="$FCO/g.o"; : > "$FCOGLOG"
FCOH="" FCCFG="$FC/c75o" _fco --week --tsv; FCOV="$FCRC|$FCOUT"
FCOH="" FCCFG="$FC/c75o" _fco --week --tsv
is  "felix cost one reading (C10): HOME empty: each call scans inline, status 0, the report as before" \
    "$FCOV|$FCRC|$FCOUT|greps=$(_fco_g)" "0|$(_fco_out a "$FCOAS")|0|$(_fco_out a "$FCOAS")|greps=2"
: > "$FCOGLOG"
FCOH=- FCCFG="$FC/c75o" _fco --week --tsv; FCOV="$FCRC|$FCOUT"
FCOH=- FCCFG="$FC/c75o" _fco --week --tsv
is  "felix cost one reading (C10): HOME unset: each call scans inline, status 0, the report as before" \
    "$FCOV|$FCRC|$FCOUT|greps=$(_fco_g)" "0|$(_fco_out a "$FCOAS")|0|$(_fco_out a "$FCOAS")|greps=2"
# No perl on PATH: every command of PATH but those named perl*, the first of a name winning, this part's grep first.
mkdir -p "$FCO/noperl" "$FCO/h15c"
if [ "$FCOPERL" = 1 ]; then
  perl -e 'my $d = shift; my %seen; for my $p (@ARGV, split(/:/, $ENV{PATH})) { opendir(my $h, $p) or next;
    for my $n (sort readdir $h) { next if $n =~ /^\./ || $n =~ /^perl/ || $seen{$n}; my $f = "$p/$n";
      next unless -f $f && -x _; $seen{$n} = 1; symlink($f, "$d/$n") } closedir $h }' "$FCO/noperl" "$FCOSHIM"
  FCONOP="$FCO/noperl"
  FCONOPOK="$( [ -x "$FCO/noperl/bash" ] && [ -x "$FCO/noperl/grep" ] && [ -z "$(ls "$FCO/noperl" | awk '/^perl/')" ] && echo yes || echo no)"
else FCONOP="$FCOSHIM:$PATH"; FCONOPOK=yes; fi
: > "$FCOGLOG"
FCOH="$FCO/h15c" FCCFG="$FC/c75o" FCOP="$FCONOP" _fco --week --tsv; FCOV="$FCRC|$FCOUT"
FCOH="$FCO/h15c" FCCFG="$FC/c75o" FCOP="$FCONOP" _fco --week --tsv
is  "felix cost one reading (C10): no perl on PATH: each call scans inline, status 0, the report as before" \
    "noperl=$FCONOPOK|$FCOV|$FCRC|$FCOUT|greps=$(_fco_g)" \
    "noperl=yes|0|$(_fco_out a "$FCOAS")|0|$(_fco_out a "$FCOAS")|greps=2"
is  "felix cost one reading (C10): no perl on PATH: nothing is made under HOME/.cache" \
    "$([ -e "$FCO/h15c/.cache" ] && echo made || echo nothing)" nothing
# A cache directory that cannot be made: HOME/.cache is a regular file.
mkdir -p "$FCO/h15d"; printf 'a file\n' > "$FCO/h15d/.cache"; : > "$FCOGLOG"
FCOH="$FCO/h15d" FCCFG="$FC/c75o" _fco --week --tsv; FCOV="$FCRC|$FCOUT"
FCOH="$FCO/h15d" FCCFG="$FC/c75o" _fco --week --tsv
is  "felix cost one reading (C10): HOME/.cache a regular file: each call scans inline, status 0, the report as before" \
    "$FCOV|$FCRC|$FCOUT|greps=$(_fco_g)|$([ -f "$FCO/h15d/.cache" ] && echo file || echo changed)" \
    "0|$(_fco_out a "$FCOAS")|0|$(_fco_out a "$FCOAS")|greps=2|file"
# A cache directory that cannot be written: mode 555.
mkdir -p "$FCO/h15e/.cache/felix/cost"; chmod 555 "$FCO/h15e/.cache/felix/cost"; : > "$FCOGLOG"
FCOH="$FCO/h15e" FCCFG="$FC/c75o" _fco --week --tsv; FCOV="$FCRC|$FCOUT"
FCOH="$FCO/h15e" FCCFG="$FC/c75o" _fco --week --tsv
chmod 755 "$FCO/h15e/.cache/felix/cost"
if [ "$FCOROOTU" = 0 ]; then
  is  "felix cost one reading (C10): a cache directory that cannot be written: each call scans inline, the report as before, nothing written" \
      "$FCOV|$FCRC|$FCOUT|greps=$(_fco_g)|[$(_fco_ls "$FCO/h15e")]" "0|$(_fco_out a "$FCOAS")|0|$(_fco_out a "$FCOAS")|greps=2|[]"
else
  skip "felix cost one reading (C10): a cache directory that cannot be written: each call scans inline, the report as before, nothing written" \
       "root writes through mode 555"
fi

# ----------------------------------------------------------------------
# C11. Writing a reading removes the readings not rewritten for 14 days.
# ----------------------------------------------------------------------
_fco_root c75p; FCOH16="$FCO/h16"; mkdir -p "$FCOH16"; FCOGLOG="$FCO/g.p"; : > "$FCOGLOG"; FCOPD="$(_fco_d "$FCOH16")"
FCOH="$FCOH16" FCCFG="$FC/c75p" _fco --since 2026-10-01 --tsv; FCOP1="$(_fco_rdgs "$FCOH16")"
FCOH="$FCOH16" FCCFG="$FC/c75p" _fco --since 2026-10-05 --tsv
FCOP3="$(_fco_rdgs "$FCOH16" | awk -v a="$FCOP1" '$0 != a')"
FCOH="$FCOH16" FCCFG="$FC/c75p" _fco --week --tsv
FCOP2="$(_fco_rdgs "$FCOH16" | awk -v a="$FCOP1" -v b="$FCOP3" '$0 != a && $0 != b')"
[ -z "$FCOP1" ] || touch -t "$(_fco_ago 15)" "$FCOPD/$FCOP1"
[ -z "$FCOP3" ] || touch -t "$(_fco_ago 13)" "$FCOPD/$FCOP3"
sleep 1; _fco_grow c75p
FCOH="$FCOH16" FCCFG="$FC/c75p" _fco --week --tsv
_fcoi "felix cost one reading (C11): writing a reading removes one not rewritten for 15 days and keeps one of 13 days" \
    "three=$([ -n "$FCOP1" ] && [ -n "$FCOP2" ] && [ -n "$FCOP3" ] && echo yes || echo no)|$FCOUT|$(_fco_ls "$FCOH16")" \
    "three=yes|$(_fco_out b "$FCOAS")|$(_fco_join lock "$FCOP2" "$FCOP3")"

# ----------------------------------------------------------------------
# C13. One grep per up to 256 files: 300 transcripts are two greps, and a served call none.
# ----------------------------------------------------------------------
_fc_mk c75q; mkdir -p "$FC/c75q/projects/-Users-dev-many" "$FCO/h17"; FCOGLOG="$FCO/g.q"; : > "$FCOGLOG"
FCOV=0
while [ "$FCOV" -lt 300 ]; do
  FCOV=$((FCOV + 1))
  _fc_rec "msg_M$FCOV" "$FCT0" m-many '{"input_tokens":1000,"output_tokens":0}' > "$FC/c75q/projects/-Users-dev-many/s$FCOV.jsonl"
done
FCOH="$FCO/h17" FCCFG="$FC/c75q" _fco --week --tsv
is  "felix cost one reading (C13): a scan of 300 transcripts runs grep twice and counts every one: 300000 over 300 calls" \
    "greps=$(_fco_g)|$(_fc_row total all)|$(_fc_cover files_read)" "greps=2|$(printf 'total\tall\t300000.00\t0.0\t300')|300"
FCOH="$FCO/h17" FCCFG="$FC/c75q" _fco --week --tsv
_fcoi "felix cost one reading (C13): the freshness check of 300 transcripts runs no grep" \
    "greps=$(_fco_g)|$(_fc_row total all)" "greps=2|$(printf 'total\tall\t300000.00\t0.0\t300')"

_fco_unlock
