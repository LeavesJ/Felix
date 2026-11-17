# >>> gate-friction-a-survivors
printf '\ngate friction A, round 3: eleven rules no assertion held, written blind\n'
# Written blind from docs/2026-10-12-gate-friction-contract-a.md and its
# addendum, for eleven of its rules that a mutant could break without any
# earlier block noticing. tests/run, tests/red and tests/receipt.sh are run,
# never read. Each assertion names the rule it holds:
#
#   (1)  C2.2   a manifest write that fails puts failed in the mark, and red says so
#   (2)  C4.2   a record run whose tree moved, outside the two record files, leaves no receipt
#   (3)  C4.2   a run whose environment changed (a claude command appeared on PATH) leaves none
#   (4)  C4.2   a normal run whose tree moved (red.tsv, which only the stable id leaves out) leaves none
#   (5)  C4.2   a normal run that compared no manifest leaves none
#   (6)  C3.2   a record run with no _rt_judge says so and leaves none
#   (7)  C4.3   a receipt path that is a directory holds nothing new, and the run says why
#   (8)  C4.3   a failing run removes a receipt that appeared while it ran
#   (9)  A8     a record run that has ended, whose id is still held, does not extend red's wait
#   (10) A8     red's parent having changed ends red's wait
#   (11) C2.6   a record run ended by SIGTERM, or by SIGINT, ends red within seconds, the retraction kept
#
# Twelve runs of a copy of this driver (its prelude, one stub part, its end) in
# a fixture checkout under $TMP, two of them controls that show a passing run
# there leaves a receipt, so that every "leaves none" below says something.
# Red is asked directly, beside a stub suite, for (9) and (10).
#
# Readings chosen where the text leaves room. (3) changes the environment by
# putting a claude command into a directory already on PATH, so the PATH itself
# is unchanged and only whether claude is there moves. (9): a later process
# taking the same id cannot be made here at a bearable cost (ids are handed out
# in order and wrap at 99,999), so the id is held instead by the record run's
# own unreaped entry, which kill -0 still finds; the record run is red's
# grandparent, so red's parent never changes and (10) is not what ends the
# wait. That asks A8's ancestor half; its start-time half only a true reuse
# reaches, and it is not asked. (10) holds the parent's id the same way, so
# kill -0 alone still finds it and the changed parent (or the unreaped entry)
# is what says it is gone. (11) signals the record run's process alone, never its group,
# while red's suite is running and would run 40 seconds more, and starts the
# record run with SIGINT at its default so that a SIGINT can end it.
_gfd="$TMP/gfd"
_gfd_o="$_gfd/out"
mkdir -p "$_gfd_o" "$_gfd/tmpdir" "$_gfd/cbin" "$_gfd/gbin"
# <seconds> <cmd>...: cmd in a process group of its own with SIGINT at its
# default, the group killed at the limit (status 124).
_gfd_bounded() {
  perl -e '$t = shift; $p = fork; defined $p or exit 125;
    if (!$p) { setpgrp(0, 0); $SIG{INT} = "DEFAULT"; exec @ARGV; exit 127 }
    $SIG{ALRM} = sub { kill "KILL", -$p; exit 124 }; alarm $t; waitpid $p, 0;
    exit(($? & 127) ? 128 + ($? & 127) : $? >> 8)' "$@"
}
_gfd_until() {   # <tries, 0.2 s apart> <cmd>...: true as soon as cmd is
  local n="$1" i=0; shift
  while [ "$i" -lt "$n" ]; do "$@" && return 0; sleep 0.2; i=$((i + 1)); done
  "$@"
}
_gfd_num()   { case "${1:-}" in ''|*[!0-9]*) return 1 ;; esac; return 0; }
_gfd_alive() { _gfd_num "${1:-}" || return 1; kill -0 "$1" 2>/dev/null || return 1
               case "$(ps -o stat= -p "$1" 2>/dev/null)" in Z*) return 1 ;; esac; return 0; }
_gfd_dead()  { ! _gfd_alive "${1:-}"; }
_gfd_kill()  { local p; for p in "$@"; do _gfd_alive "$p" && kill -9 "$p" 2>/dev/null; done; return 0; }
_gfd_pidof() { head -1 "$1" 2>/dev/null; }
_gfd_git()   { git -c user.name=gfd -c user.email=gfd@example.invalid -c commit.gpgsign=false -c core.hooksPath=/dev/null "$@"; }
# <file> <text>: "said" when a line of the file is the text, leading blanks aside.
_gfd_said() {
  GFD_W="$2" LC_ALL=C awk '{ sub(/^[ \t]+/, "") } $0 == ENVIRON["GFD_W"] { h = 1 } END { print h ? "said" : "not said" }' "$1" 2>/dev/null
}
_gfd_retr="$(printf 'base\t-\t-\t-\nrun\t-\t-\t-')"
_gfd_rows() { grep -v '^#' "$1" 2>/dev/null; }
_gfd_redtsv0="$(printf 'base\t1\t1\t1\nrun\t1\t1\t1')"

# The fixtures' PATH: no directory that holds a claude command, then this
# block's empty cbin (where (3) puts one) and a directory holding the git this
# suite uses, so the fixtures keep it.
ln -s "$(command -v git)" "$_gfd/gbin/git" 2>/dev/null
_gfd_path="$_gfd/cbin:$_gfd/gbin"
_gfd_ifs="$IFS"; IFS=:
for _gfd_d in $PATH; do
  [ -n "$_gfd_d" ] && [ ! -x "$_gfd_d/claude" ] && _gfd_path="$_gfd_path:$_gfd_d"
done
IFS="$_gfd_ifs"

# ---- the fixture checkout: this driver with one stub part, beside every other file in tests/
_gfd_F="$_gfd/f"; _gfd_T="$_gfd_F/engine/harness/tests"
mkdir -p "$_gfd_T/parts" "$_gfd_F/engine/.claude-plugin"
_copy_content "$REAL_HARNESS/lib" "$_gfd_F/engine/harness/lib"
for _gfd_x in "$HERE"/*; do
  [ -f "$_gfd_x" ] || continue
  case "${_gfd_x##*/}" in run|assertions.tsv|red.tsv) ;; *) cp "$_gfd_x" "$_gfd_T/" ;; esac
done
# The suite's preamble parts stay in the copy (part 0003's _suite_copy_driver): since 3+3b they hold $TMP and the EXIT trap.
_suite_copy_driver "$HERE/run" "$_gfd_T" 0001-gfd-stub.sh
chmod +x "$_gfd_T/run" "$_gfd_T/red"
printf '{\n  "name": "felix",\n  "version": "0.0.1"\n}\n' > "$_gfd_F/engine/.claude-plugin/plugin.json"
printf '1\tgfd: the stub part ran\n' > "$_gfd_T/assertions.tsv"
printf '%s\n' "$_gfd_redtsv0" > "$_gfd_T/red.tsv"
printf 'tracked\n' > "$_gfd_F/gfd-tracked.txt"
# The stub part. In red's suite (FELIX_TEST_NO_MANIFEST=1) it writes its
# shell's pid and, for (11), runs 40 seconds. In the record or normal run it
# does what its mode asks, mid-run, then passes, and judges the record unless
# the mode is r6. Its judge call spells the checkout with braces, as part 1120's
# does: part 1010 counts the lines of the parts that name the suite's own call,
# and this text is a stub's, not a call this suite makes.
cat > "$_gfd_T/parts/0001-gfd-stub.sh" <<'GFDSTUBPART'
_rtn1="gfd record check one"; _rtn2="gfd record check two"
_rtn3="gfd record check three"; _rtn4="gfd record check four"
_gfds_m="${GFD_MODE:-}"
if [ "${FELIX_TEST_NO_MANIFEST:-0}" = "1" ]; then
  printf '%s\n' "$$" > "${GFD_OUT:?}/rsuite.$_gfds_m"
  case "$_gfds_m" in
    r11*) _gfds_i=0; while [ "$_gfds_i" -lt 40 ]; do sleep 1; _gfds_i=$((_gfds_i + 1)); done ;;
  esac
else
  case "$_gfds_m" in
    r2) printf 'gfd moved\n' >> "${GFD_F:?}/gfd-tracked.txt" ;;
    n4) printf 'gfd moved\n' >> "${GFD_F:?}/engine/harness/tests/red.tsv" ;;
    n3) printf '#!/bin/sh\nexit 0\n' > "${GFD_CBIN:?}/claude"; chmod +x "$GFD_CBIN/claude" ;;
    n8) cp "${GFD_PLANT:?}" "${GFD_RCPT:?}" && [ -f "$GFD_RCPT" ] && printf 'planted\n' > "$GFD_OUT/n8.planted" ;;
    r1) _gfds_mf="${GFD_F:?}/engine/harness/tests/assertions.tsv"
        rm -f "$_gfds_mf"; mkdir "$_gfds_mf" && chmod a-w "$_gfds_mf" && printf 'blocked\n' > "$GFD_OUT/r1.blocked" ;;
    r11*)
      printf '%s\n' "$$" > "${GFD_OUT:?}/drv.$_gfds_m"
      _gfds_i=0; _gfds_rp=""
      while [ "$_gfds_i" -lt 25 ] && [ -z "$_gfds_rp" ]; do
        _gfds_rp="$(ps axww -o pid= -o command= 2>/dev/null \
          | LC_ALL=C awk -v me="$$" 'index($0, "tests/red --after ") && $NF == me { print $1; exit }')"
        [ -n "$_gfds_rp" ] || sleep 0.2; _gfds_i=$((_gfds_i + 1))
      done
      printf '%s\n' "$_gfds_rp" > "$GFD_OUT/red.$_gfds_m"
      _gfds_i=0; while [ "$_gfds_i" -lt 125 ] && [ ! -s "$GFD_OUT/rsuite.$_gfds_m" ]; do sleep 0.2; _gfds_i=$((_gfds_i + 1)); done
      sleep 60 & printf '%s\n' "$!" > "$GFD_OUT/sleep.$_gfds_m"
      : > "$GFD_OUT/ready.$_gfds_m"
      wait "$!"
      ;;
  esac
fi
ok "gfd: the stub part ran"
if [ "$_gfds_m" = n8 ] && [ "${FELIX_TEST_NO_MANIFEST:-0}" != "1" ]; then bad "gfd: the stub part fails on purpose" "a failing run"; fi
if [ "$_gfds_m" != r6 ]; then
  _rt_judge() {
    if [ "${FELIX_TEST_RECORD:-}" = 1 ]; then
      skip "$_rtn1" "the record is being rewritten"; skip "$_rtn2" "the record is being rewritten"
      skip "$_rtn3" "the record is being rewritten"; skip "$_rtn4" "the record is being rewritten"
      return 0
    fi
    ok "$_rtn1"; ok "$_rtn2"; ok "$_rtn3"; ok "$_rtn4"
  }
  _rt_judge "${REAL_HARNESS}/../.."
fi
GFDSTUBPART
( _fx_cd "${_gfd_F:?}" && git init -q -b main && git add -A && _gfd_git commit -qm seed ) >/dev/null 2>&1
_gfd_F="$(cd "${_gfd_F:?}" && pwd -P)"; _gfd_T="$_gfd_F/engine/harness/tests"
_gfd_c1="$(_gfd_git -C "${_gfd_F:?}" commit-tree -p HEAD -m 'origin' 'HEAD^{tree}' 2>/dev/null)"
[ -n "$_gfd_c1" ] && _fx_git "${_gfd_F:?}" update-ref refs/remotes/origin/main "$_gfd_c1" >/dev/null 2>&1
_gfd_rp="$(git -C "${_gfd_F:?}" rev-parse --git-path felix-suite-receipt 2>/dev/null)"
case "$_gfd_rp" in /*) ;; *) _gfd_rp="$_gfd_F/$_gfd_rp" ;; esac
_gfd_mf="$_gfd_T/assertions.tsv"
_gfd_rcpt() { if [ -e "$_gfd_rp" ] || [ -L "$_gfd_rp" ]; then echo present; else echo absent; fi; }
_gfd_rmode() {   # "a receipt, mode <its third field>" or "no receipt"
  if [ -f "$_gfd_rp" ] && [ ! -L "$_gfd_rp" ]; then
    printf 'a receipt, mode %s' "$(LC_ALL=C awk -F'\t' 'NR == 1 { print $3 }' "$_gfd_rp")"
  else printf 'no receipt'; fi
}
# <mode> <limit> [driver args...]: one run, stdout and stderr in $_gfd_o/<mode>.out, status in _gfd_rc.
_gfd_run() {
  local m="$1" lim="$2"; shift 2
  ( cd "${_gfd_F:?}" && _gfd_bounded "$lim" env -u FELIX_TEST_NO_MANIFEST GFD_MODE="$m" GFD_OUT="$_gfd_o" \
      GFD_F="$_gfd_F" GFD_RCPT="$_gfd_rp" GFD_PLANT="$_gfd/plant" GFD_CBIN="$_gfd/cbin" \
      TMPDIR="$_gfd/tmpdir" PATH="$_gfd_path" "$BASH" "$_gfd_T/run" ${1+"$@"} ) > "$_gfd_o/$m.out" 2>&1
  _gfd_rc=$?
}

# ---- controls: a passing record run and a passing normal run each leave a receipt here
chmod -x "$_gfd_T/red"
rm -rf "${_gfd_rp:?}"
_gfd_run r0 60 --record-assertions
is  "(2)(6) a passing record run in this fixture leaves a receipt, mode record, so a missing one below says something (control)" \
    "$(_gfd_rmode)" "a receipt, mode record"
cp "$_gfd_mf" "$_gfd/manifest.r0" 2>/dev/null
_gfd_run n0 60
is  "(3)(4)(5)(7)(8) a passing normal run in this fixture leaves a receipt, mode normal (control)" \
    "$(_gfd_rmode)" "a receipt, mode normal"
if [ -f "$_gfd_rp" ]; then cp "$_gfd_rp" "$_gfd/plant"; else printf 'gfd planted\n' > "$_gfd/plant"; fi
_gfd_env0="$(LC_ALL=C awk -F'\t' 'NR == 1 { print $7 }' "$_gfd/plant" 2>/dev/null)"

# ---- (2) a record run during which a tracked file other than the record files changes
_gfd_run r2 60 --record-assertions
is  "(2) a record run during which a tracked file other than assertions.tsv and red.tsv changed leaves no receipt" \
    "$(_gfd_rcpt)" "absent"
printf 'tracked\n' > "$_gfd_F/gfd-tracked.txt"

# ---- (6) a record run in a suite with no _rt_judge
_gfd_run r6 60 --record-assertions
is  "(6) a record run in a suite with no _rt_judge says the record is not re-judged" \
    "$(grep -cxF -e '  no record judge in this suite: the record is not re-judged' "$_gfd_o/r6.out" 2>/dev/null)" "1"
is  "(6) and leaves no receipt" "$(_gfd_rcpt)" "absent"
cp "$_gfd/manifest.r0" "$_gfd_mf" 2>/dev/null

# ---- (4) a normal run during which red.tsv changes
_gfd_run n4 60
is  "(4) a normal run during which red.tsv changed (the full tree id moved, the stable one did not) leaves no receipt" \
    "$(_gfd_rcpt)" "absent"
printf '%s\n' "$_gfd_redtsv0" > "$_gfd_T/red.tsv"

# ---- (3) a normal run during which a claude command appears on PATH
rm -f "$_gfd/cbin/claude"
_gfd_run n3 60
case "$_gfd_env0" in
  *claude=no*) _v="$(_gfd_rcpt)" ;;
  *) _v="the control's environment did not say claude=no, so nothing could appear: [$_gfd_env0]" ;;
esac
is  "(3) a normal run during which a claude command appeared on PATH (the PATH itself unchanged) leaves no receipt" "$_v" "absent"
rm -f "$_gfd/cbin/claude"

# ---- (5) a normal run with no manifest to compare
rm -f "$_gfd_mf"
_gfd_run n5 60
if LC_ALL=C grep -q 'no manifest yet' "$_gfd_o/n5.out" 2>/dev/null; then _v="$(_gfd_rcpt)"; else _v="the run never said no manifest yet"; fi
is  "(5) a normal run that compared no manifest (it said no manifest yet) leaves no receipt" "$_v" "absent"
cp "$_gfd/manifest.r0" "$_gfd_mf" 2>/dev/null

# ---- (7) a passing normal run whose receipt path is a directory
rm -rf "${_gfd_rp:?}"; mkdir -p "$_gfd_rp"; printf 'keep\n' > "$_gfd_rp/keep"
_gfd_run n7 60
_v="$( (cd "${_gfd_rp:?}" 2>/dev/null && find . | LC_ALL=C sort | tr '\n' ' '; printf '| %s' "$(cat keep 2>/dev/null)") )"
is  "(7) a receipt path that is a directory holds nothing new after a passing run: nothing written into it or through it" \
    "$_v" ". ./keep | keep"
_v="$(LC_ALL=C awk -v rp="$_gfd_rp" '
  index($0, "  receipt not written: ") == 1 && substr($0, length($0) - 21) == " is not a regular file" {
    print substr($0, 24, length($0) - 23 - 22); exit }' "$_gfd_o/n7.out" 2>/dev/null)"
if [ -z "$_v" ]; then _v="not said"
elif [ "$(basename "$_v")" = felix-suite-receipt ] && [ "$(cd "$(dirname "$_v")" 2>/dev/null && pwd -P)" = "$_gfd_F/.git" ]; then
  _v="said, naming the receipt path"
else _v="said, naming [$_v]"; fi
is  "(7) and the run says receipt not written: <the receipt path> is not a regular file" "$_v" "said, naming the receipt path"
rm -rf "${_gfd_rp:?}"

# ---- (8) a failing normal run during which a receipt appears
_gfd_run n8 60
if [ ! -f "$_gfd_o/n8.planted" ]; then _v="the stub never put a receipt in place"
elif [ "$_gfd_rc" -ne 1 ]; then _v="the run did not fail as a failing run does (exit $_gfd_rc)"
else _v="$(_gfd_rcpt)"; fi
is  "(8) a failing run removes a receipt that appeared while it ran" "$_v" "absent"
rm -rf "${_gfd_rp:?}"

# ---- (1) a record run, red there, whose manifest write fails
chmod +x "$_gfd_T/red"
_gfd_run r1 90 --record-assertions
chmod -R u+w "$_gfd_mf" 2>/dev/null; rm -rf "${_gfd_mf:?}"; cp "$_gfd/manifest.r0" "$_gfd_mf" 2>/dev/null
if [ -f "$_gfd_o/r1.blocked" ]; then
  _v="$(_gfd_said "$_gfd_o/r1.out" 'red: not run: the record run did not write a manifest (failed)')"
else _v="the stub could not make the manifest unwritable"; fi
is  "(1) a record run whose manifest write fails marks it failed: red says the record run did not write a manifest (failed)" "$_v" "said"
_gfd_kill "$(_gfd_pidof "$_gfd_o/rsuite.r1")"
rm -rf "${_gfd_rp:?}"

# ---- (11) a record run ended by a signal while red's suite runs
# <mode> <signal>: the record run in the background, signalled once red's
# suite has started; _gfd_v1 is what became of red, _gfd_v2 what red.tsv holds.
_gfd_sig() {
  local m="$1" s="$2" lp d r t0 t1
  printf '%s\n' "$_gfd_redtsv0" > "$_gfd_T/red.tsv"
  ( cd "${_gfd_F:?}" && exec perl -e '$t = shift; $p = fork; defined $p or exit 125;
      if (!$p) { setpgrp(0, 0); $SIG{INT} = "DEFAULT"; exec @ARGV; exit 127 }
      $SIG{ALRM} = sub { kill "KILL", -$p; exit 124 }; alarm $t; waitpid $p, 0; exit 0' 90 \
      env -u FELIX_TEST_NO_MANIFEST GFD_MODE="$m" GFD_OUT="$_gfd_o" GFD_F="$_gfd_F" GFD_RCPT="$_gfd_rp" \
      GFD_PLANT="$_gfd/plant" GFD_CBIN="$_gfd/cbin" TMPDIR="$_gfd/tmpdir" PATH="$_gfd_path" \
      "$BASH" "$_gfd_T/run" --record-assertions ) > "$_gfd_o/$m.out" 2>&1 &
  lp=$!
  _gfd_v1="the record run never came to red's suite running"
  if _gfd_until 225 test -e "$_gfd_o/ready.$m"; then
    d="$(_gfd_pidof "$_gfd_o/drv.$m")"; r="$(_gfd_pidof "$_gfd_o/red.$m")"
    if ! _gfd_alive "$r"; then _gfd_v1="red was not running when the record run was signalled [$r]"
    elif ! _gfd_num "$d"; then _gfd_v1="no record run id to signal"
    else
      t0="$(date +%s)"; kill -s "$s" "$d" 2>/dev/null
      if _gfd_until 75 _gfd_dead "$r"; then
        t1="$(date +%s)"
        if [ $((t1 - t0)) -le 10 ]; then _gfd_v1=ended; else _gfd_v1="red ended $((t1 - t0)) s after the signal"; fi
      else
        _gfd_v1="red still running 15 s after the signal"
        _gfd_alive "$d" && _gfd_v1="$_gfd_v1, and so is the record run"
      fi
    fi
  fi
  _gfd_v2="$(_gfd_rows "$_gfd_T/red.tsv")"
  _gfd_kill "$(_gfd_pidof "$_gfd_o/sleep.$m")" "$(_gfd_pidof "$_gfd_o/red.$m")" "$(_gfd_pidof "$_gfd_o/rsuite.$m")"
  d="$(_gfd_pidof "$_gfd_o/drv.$m")"; _gfd_num "$d" && kill -9 -- "-$d" 2>/dev/null
  wait "$lp" 2>/dev/null
  return 0
}
_gfd_sig r11t TERM
is  "(11) a record run ended by SIGTERM while red's suite runs ends red within ten seconds" "$_gfd_v1" "ended"
is  "(11) and red.tsv then holds the two retraction rows" "$_gfd_v2" "$_gfd_retr"
_gfd_sig r11i INT
is  "(11) a record run ended by SIGINT while red's suite runs ends red within ten seconds" "$_gfd_v1" "ended"
is  "(11) and red.tsv then holds the two retraction rows, after SIGINT too" "$_gfd_v2" "$_gfd_retr"
rm -rf "${_gfd_rp:?}"

# ---- red, asked directly, beside a stub suite in a checkout of its own: (9) and (10)
_gfd_R="$_gfd/r"
mkdir -p "$_gfd_R/engine/harness/tests"
cp "$HERE/red" "$_gfd_R/engine/harness/tests/red"
cat > "$_gfd_R/engine/harness/tests/run" <<'GFDREDSTUBRUN'
#!/usr/bin/env bash
[ -n "${GFD_SUITE_RAN:-}" ] && printf '%s\n' "$$" > "$GFD_SUITE_RAN"
printf '  ok    gfd red stub\n'
printf '\nreached\n'
printf '\n1 passed, 0 failed\n'
GFDREDSTUBRUN
chmod +x "$_gfd_R/engine/harness/tests/run" "$_gfd_R/engine/harness/tests/red"
printf '1\tgfd red stub\n' > "$_gfd_R/engine/harness/tests/assertions.tsv"
( _fx_cd "${_gfd_R:?}" && git init -q -b main && git add -A && _gfd_git commit -qm seed ) >/dev/null 2>&1
_gfd_R="$(cd "${_gfd_R:?}" && pwd -P)"
# p.sh <red> <mark> <pid, or self> <out> <red pid file> <own pid file>: starts
# red in the background, as the record run does, and waits for it.
cat > "$_gfd/p.sh" <<'GFDPSCRIPT'
p="$3"; [ "$p" = self ] && p=$$
printf '%s\n' "$$" > "$6"
"$1" --after "$2" "$p" > "$4" 2>&1 &
printf '%s\n' "$!" > "$5"
wait
GFDPSCRIPT
# g.sh <red> <mark> <out> <red pid file> <p pid file>: runs p.sh in the
# foreground, handing it this shell's own id, so it is red's grandparent.
cat > "$_gfd/g.sh" <<'GFDGSCRIPT'
"$BASH" "$GFD_PSH" "$1" "$2" "$$" "$3" "$4" "$5"
:
GFDGSCRIPT
_gfd_gone="red: not run: the record run ended before it wrote the manifest"
# <case> <script> <args>...: the script under a holder, red's suite awaited,
# then the holder's child killed and left unreaped. _gfd_h, _gfd_k are the
# holder's pid and its child's; the caller checks and cleans up.
_gfd_held() {
  local c="$1"; shift
  mkdir -p "$_gfd/rt.$c"
  env -u FELIX_TEST_NO_MANIFEST GFD_SUITE_RAN="$_gfd_o/$c.ran" GFD_PSH="$_gfd/p.sh" TMPDIR="$_gfd/rt.$c" \
    perl -e '$f = shift; $t = shift; $p = fork; defined $p or exit 125;
      if (!$p) { exec @ARGV; exit 127 }
      open(my $h, ">", $f) or exit 126; print $h "$p\n"; close $h;
      sleep $t; kill "KILL", $p; exit 0' "$_gfd_o/$c.held" 45 "$BASH" "$@" &
  _gfd_h=$!
  _gfd_until 150 test -s "$_gfd_o/$c.ran"
  sleep 1
  _gfd_k="$(_gfd_pidof "$_gfd_o/$c.held")"
  _gfd_rb="$(ps -o ppid= -p "$(_gfd_pidof "$_gfd_o/$c.red.pid")" 2>/dev/null | tr -d ' ')"
  _gfd_num "$_gfd_k" && kill -9 "$_gfd_k" 2>/dev/null
  sleep 0.3
}
_gfd_redwait() {   # <case> <red pid>: what red did after the record run went
  if ! _gfd_num "$2"; then echo "red was never started"
  elif _gfd_until 60 _gfd_dead "$2"; then
    if [ "$(_gfd_said "$_gfd_o/$1.red.out" "$_gfd_gone")" = said ]; then echo "$_gfd_gone"
    else printf 'red ended saying [%s]' "$(grep -v '^$' "$_gfd_o/$1.red.out" 2>/dev/null | tail -1)"; fi
  else echo "red still waiting 12 s after the record run went"; fi
}

# (10): red's parent, the record run, killed; its id stays held, so only the changed parent says it is gone
_gfd_held a10 "$_gfd/p.sh" "$_gfd_R/engine/harness/tests/red" "$_gfd/mk.a10" self \
  "$_gfd_o/a10.red.out" "$_gfd_o/a10.red.pid" "$_gfd_o/a10.p.pid"
_gfd_r10="$(_gfd_pidof "$_gfd_o/a10.red.pid")"
if [ -z "$_gfd_rb" ]; then _v="red had ended before its record run did"
elif [ "$_gfd_rb" != "$_gfd_k" ]; then _v="red's parent was not the record run [$_gfd_rb]"
elif ! kill -0 "$_gfd_k" 2>/dev/null; then _v="the record run's id was not held after it ended"
else _v="$(_gfd_redwait a10 "$_gfd_r10")"; fi
is  "(10) red, its parent the record run ended (id still held) and red re-parented, refuses: the record run ended before it wrote the manifest" \
    "$_v" "$_gfd_gone"
_gfd_kill "$_gfd_r10"; kill "$_gfd_h" 2>/dev/null; wait "$_gfd_h" 2>/dev/null

# (9): the record run is red's grandparent; it ends, its id stays held, red's parent stays
_gfd_held a9 "$_gfd/g.sh" "$_gfd_R/engine/harness/tests/red" "$_gfd/mk.a9" \
  "$_gfd_o/a9.red.out" "$_gfd_o/a9.red.pid" "$_gfd_o/a9.p.pid"
_gfd_r9="$(_gfd_pidof "$_gfd_o/a9.red.pid")"; _gfd_p9="$(_gfd_pidof "$_gfd_o/a9.p.pid")"
_gfd_a9="(9) an ended record run whose id is still held, no longer red's ancestor, never extends red's wait: red refuses as the record run gone"
if [ -z "$_gfd_rb" ]; then
  # Red took a living grandparent for gone at once, which "the process that
  # started red" allows: then nothing here asks about a held id.
  skip "$_gfd_a9" "red ended before its grandparent did, so no held id was ever put to it"
else
  if [ "$_gfd_rb" != "$_gfd_p9" ]; then _v="red's parent was not p.sh [$_gfd_rb]"
  elif ! kill -0 "$_gfd_k" 2>/dev/null; then _v="the record run's id was not held after it ended"
  elif _gfd_alive "$_gfd_r9" && [ "$(ps -o ppid= -p "$_gfd_r9" 2>/dev/null | tr -d ' ')" != "$_gfd_p9" ]; then
    _v="red's parent changed, which is (10), not this"
  else _v="$(_gfd_redwait a9 "$_gfd_r9")"; fi
  is  "$_gfd_a9" "$_v" "$_gfd_gone"
fi
_gfd_kill "$_gfd_r9" "$_gfd_p9"; kill "$_gfd_h" 2>/dev/null; wait "$_gfd_h" 2>/dev/null
# <<< gate-friction-a-survivors
