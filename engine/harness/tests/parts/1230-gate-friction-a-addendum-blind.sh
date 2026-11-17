# >>> gate-friction-a-addendum
printf '\ngate friction A, round 2: the addendum, written blind\n'
# Written blind from docs/2026-10-12-gate-friction-contract-a.md and the ten
# items its second review added (A1 to A10), before any implementation of them
# and without reading one. What each block asks:
#
#   A1  the receipt names origin/main as the run began, is written only when
#       origin/main is the same at the end, and _sr_check refuses a receipt
#       whose origin/main moved, before its 12-hour check
#   A2  a run that may leave a receipt removes the old one before its first part
#   A3  a log that holds the reuse line, pushed off its first line by stderr,
#       is never the tests check's ok
#   A4  a root that is not its own top level is no checkout
#   A5  red, started by the record run, is not a job a part's bare wait waits for
#   A6  a mark that cannot be written ends red and red's suite at once
#   A7  red notices, while its suite runs, that its record run is gone
#   A8  a process that is not red's parent never extends red's wait
#   A9  a mark that is not a regular file is refused without being opened
#   A10 the summary line is the last line, whatever the receipt does
#
# Three runs of a copy of this driver (its prelude, one stub part, its end) in
# a fixture checkout under $TMP: a normal run that should leave a receipt, a
# record run during which origin/main appears, and a record run whose mark
# cannot be written. Red is asked directly, beside a stub suite, for A7 to A9,
# and the gate beside a stub suite for A3.
#
# Readings chosen where the text leaves room. The receipt's field for
# origin/main has no stated position, so it is looked for as a whole field and
# the receipt is aged by moving every field that is one of the run's times.
# A7's half about a signal to the record run is asked of red alone: a fourth
# driver run is over this block's budget, and red seeing its record run gone
# is what ends red's suite within seconds either way. A8's "no longer the
# process that started red" is read to cover a pid that never was red's
# parent. A3 asks only that such a log is not ok, since what the gate says
# instead (fail, or reused when its own signal says so) is not fixed. A4's
# "no run writes or removes a receipt for such a root" is asked of the
# helpers the driver goes through, not of a run.
_gfb="$TMP/gfb"
_gfb_o="$_gfb/out"
mkdir -p "$_gfb_o" "$_gfb/tmpdir"
_gfb_bounded() {   # <seconds> <cmd>...: cmd in a process group of its own, the group killed at the limit (status 124)
  perl -e '$t = shift; $p = fork; defined $p or exit 125;
    if (!$p) { setpgrp(0, 0); exec @ARGV; exit 127 }
    $SIG{ALRM} = sub { kill "KILL", -$p; exit 124 }; alarm $t; waitpid $p, 0;
    exit(($? & 127) ? 128 + ($? & 127) : $? >> 8)' "$@"
}
_gfb_until() {   # <tries, 0.2 s apart> <cmd>...: true as soon as cmd is
  local n="$1" i=0; shift
  while [ "$i" -lt "$n" ]; do "$@" && return 0; sleep 0.2; i=$((i + 1)); done
  "$@"
}
_gfb_alive() { case "${1:-}" in ''|*[!0-9]*) return 1 ;; esac; kill -0 "$1" 2>/dev/null; }
_gfb_dead()  { ! _gfb_alive "${1:-}"; }
_gfb_pidof() { head -1 "$1" 2>/dev/null; }
_gfb_git()   { git -c user.name=gfb -c user.email=gfb@example.invalid -c commit.gpgsign=false -c core.hooksPath=/dev/null "$@"; }
# file: "the summary" when its last line is the suite's summary line, else that line.
_gfb_last() {
  LC_ALL=C awk '{ l = $0 } END { print (l ~ /^[0-9]+ passed, [0-9]+ failed(, [0-9]+ skipped)?$/) ? "the summary" : "[" l "]" }' "$1" 2>/dev/null
}
# file line: the line, when the file holds it whole; else the file's first line, bracketed.
_gfb_said() {
  GFB_W="$2" LC_ALL=C awk 'NR == 1 { f1 = $0 } $0 == ENVIRON["GFB_W"] { hit = 1 }
    END { print hit ? ENVIRON["GFB_W"] : "[" f1 "]" }' "$1" 2>/dev/null
}
# file prefix: "said" when a line of the file begins with prefix.
_gfb_begins() {
  GFB_W="$2" LC_ALL=C awk 'index($0, ENVIRON["GFB_W"]) == 1 { hit = 1 } END { print hit ? "said" : "not said" }' "$1" 2>/dev/null
}
_gfb_retr="$(printf 'base\t-\t-\t-\nrun\t-\t-\t-')"
_gfb_rows() { grep -v '^#' "$1" 2>/dev/null; }

# ---- the fixture checkout: this driver with one stub part, red, receipt.sh, lib
_gfb_F="$_gfb/f"
mkdir -p "$_gfb_F/engine/harness/tests/parts" "$_gfb_F/engine/.claude-plugin"
_copy_content "$REAL_HARNESS/lib" "$_gfb_F/engine/harness/lib"
cp "$HERE/red" "$_gfb_F/engine/harness/tests/red"
[ -f "$HERE/receipt.sh" ] && cp "$HERE/receipt.sh" "$_gfb_F/engine/harness/tests/receipt.sh"
# The suite's preamble parts stay in the copy (part 0003's _suite_copy_driver): since 3+3b they hold $TMP and the EXIT trap.
_suite_copy_driver "$HERE/run" "$_gfb_F/engine/harness/tests" 0001-gfb-stub.sh
chmod +x "$_gfb_F/engine/harness/tests/run" "$_gfb_F/engine/harness/tests/red"
printf '{\n  "name": "felix",\n  "version": "0.0.1"\n}\n' > "$_gfb_F/engine/.claude-plugin/plugin.json"
printf '1\tgfb: the stub part ran\n' > "$_gfb_F/engine/harness/tests/assertions.tsv"
# The stub part. In red's suite (FELIX_TEST_NO_MANIFEST=1) it records its
# shell's pid, and in d3 it is slow. In the record or normal run it records
# whether a receipt is there as it begins, and then: d2 asks whether red is
# running, times a bare wait on a job of its own and makes origin/main appear;
# d3 waits for red's suite to start and then makes the run's temporary
# directory read-only, so no mark can be put in it.
cat > "$_gfb_F/engine/harness/tests/parts/0001-gfb-stub.sh" <<'GFBSTUB'
_rt_judge() { ok "gfb: the stub judge ran"; }
if [ "${FELIX_TEST_NO_MANIFEST:-0}" = "1" ]; then
  printf '%s\n' "$$" > "${GFB_OUT:?}/suite.${GFB_MODE:-x}.pid"
  if [ "${GFB_MODE:-}" = "d3" ]; then
    _gfbs_i=0; while [ "$_gfbs_i" -lt 30 ]; do sleep 1; _gfbs_i=$((_gfbs_i + 1)); done
  fi
else
  if [ -e "${GFB_RCPT:?}" ] || [ -L "$GFB_RCPT" ]; then _gfbs_r=present; else _gfbs_r=absent; fi
  printf '%s\n' "$_gfbs_r" > "${GFB_OUT:?}/rcpt-at-part.${GFB_MODE:?}"
  case "$GFB_MODE" in
    d2)
      ps axww -o command= 2>/dev/null | LC_ALL=C awk -v pid="$$" 'index($0, "tests/red --after ") && $NF == pid { n++ } END { print n + 0 }' \
        > "$GFB_OUT/d2.red"
      _gfbs_t0="$(date +%s)"; sleep 1 & wait; _gfbs_ws=$?; _gfbs_t1="$(date +%s)"
      printf '%s %s\n' "$((_gfbs_t1 - _gfbs_t0))" "$_gfbs_ws" > "$GFB_OUT/d2.wait"
      git -C "${GFB_F:?}" update-ref refs/remotes/origin/main "${GFB_O:?}"
      ;;
    d3)
      printf '%s\n' "$TMP" > "$GFB_OUT/d3.tmp"
      _gfbs_i=0; while [ "$_gfbs_i" -lt 50 ] && [ ! -s "$GFB_OUT/suite.d3.pid" ]; do sleep 0.2; _gfbs_i=$((_gfbs_i + 1)); done
      ;;
  esac
fi
ok "gfb: the stub part ran"
if [ "${GFB_MODE:-}" = "d3" ] && [ "${FELIX_TEST_NO_MANIFEST:-0}" != "1" ]; then chmod -R a-w "${TMP:?}"; fi
GFBSTUB
( _fx_cd "${_gfb_F:?}" && git init -q -b main && git add -A && _gfb_git commit -qm seed ) >/dev/null 2>&1
_gfb_F="$(cd "${_gfb_F:?}" && pwd -P)"
_gfb_c1="$(_gfb_git -C "${_gfb_F:?}" commit-tree -p HEAD -m 'origin one' 'HEAD^{tree}' 2>/dev/null)"
_gfb_c2="$(_gfb_git -C "${_gfb_F:?}" commit-tree -p HEAD -m 'origin two' 'HEAD^{tree}' 2>/dev/null)"
_gfb_rp="$(git -C "${_gfb_F:?}" rev-parse --git-path felix-suite-receipt 2>/dev/null)"
case "$_gfb_rp" in /*) ;; *) _gfb_rp="$_gfb_F/$_gfb_rp" ;; esac
_gfb_origin() {   # <commit, or - for none>
  if [ "$1" = "-" ]; then _fx_git "${_gfb_F:?}" update-ref -d refs/remotes/origin/main >/dev/null 2>&1
  else _fx_git "${_gfb_F:?}" update-ref refs/remotes/origin/main "$1" >/dev/null 2>&1; fi
}
# <limit> <mode> <stdout> <stderr, or = for the same file> [--record-assertions]
_gfb_drive() {
  local lim="$1" mode="$2" out="$3" err="$4"; shift 4
  if [ "$err" = "=" ]; then
    ( cd "${_gfb_F:?}" && _gfb_bounded "$lim" env -u FELIX_TEST_NO_MANIFEST GFB_MODE="$mode" GFB_OUT="$_gfb_o" \
        GFB_RCPT="$_gfb_rp" GFB_F="$_gfb_F" GFB_O="$_gfb_c2" TMPDIR="$_gfb/tmpdir" \
        "$BASH" "$_gfb_F/engine/harness/tests/run" ${1+"$@"} ) > "$out" 2>&1
  else
    ( cd "${_gfb_F:?}" && _gfb_bounded "$lim" env -u FELIX_TEST_NO_MANIFEST GFB_MODE="$mode" GFB_OUT="$_gfb_o" \
        GFB_RCPT="$_gfb_rp" GFB_F="$_gfb_F" GFB_O="$_gfb_c2" TMPDIR="$_gfb/tmpdir" \
        "$BASH" "$_gfb_F/engine/harness/tests/run" ${1+"$@"} ) > "$out" 2> "$err"
  fi
}
# receipt.sh's helpers, asked in a shell of their own: "status|output".
_gfb_hcall() {
  local o r
  o="$( ( . "${_gfb_F:?}/engine/harness/tests/receipt.sh" >/dev/null 2>&1; "$@" ) 2>/dev/null )"; r=$?
  printf '%s|%s' "$r" "$o"
}
_gfb_chk() { ( . "${_gfb_F:?}/engine/harness/tests/receipt.sh" >/dev/null 2>&1; _sr_check "$_gfb_F" ) 2>/dev/null; }

# ---- A4: a root that is not its own top level is no checkout
is  "(A4) _sr_path, handed a directory inside a checkout that is not its top level, answers no checkout: status 1, nothing printed" \
    "$(_gfb_hcall _sr_path "$_gfb_F/engine")" "1|"
is  "(A4) and so does _sr_tree for that directory" "$(_gfb_hcall _sr_tree "$_gfb_F/engine")" "1|"
is  "(A4) and _sr_check answers run no checkout for it" "$(_gfb_hcall _sr_check "$_gfb_F/engine")" "0|run no checkout"
_v="$(_gfb_hcall _sr_path "$_gfb_F/engine/harness/../..")"
case "$_v" in
  0\|/*) _p="${_v#0|}"
         if [ "$(basename "$_p")" = felix-suite-receipt ] && [ "$(cd "$(dirname "${_p:?}")" 2>/dev/null && pwd -P)" = "$_gfb_F/.git" ]; then
           _v="the checkout's receipt"
         fi ;;
esac
is  "(A4) a root written as the driver writes it, with .. in it, that is the top level, is still the checkout and names its receipt" \
    "$_v" "the checkout's receipt"

# ---- A1: the contract names the inputs from outside the tree
_gfb_doc="$REAL_HARNESS/../../docs/2026-10-12-gate-friction-contract-a.md"
_gfb_docsays() { if [ -f "$_gfb_doc" ] && LC_ALL=C grep -qiF -- "$1" "$_gfb_doc"; then echo names; else echo "does not name"; fi; }
_gfb_n1="(A1) the contract lists the memory lessons.md that part 0590 reads among the inputs from outside the tree"
_gfb_n2="(A1) and the deployed plugin cache that part 0440 reads"
# Not blind: the public snapshot withholds docs/, so where the contract is not
# beside this harness both are skipped saying so, as part 1850 does for its
# document. Where it is, they are asked as they were written.
if [ -f "$_gfb_doc" ]; then
  is  "$_gfb_n1" "$(_gfb_docsays lessons.md)" "names"
  is  "$_gfb_n2" "$(_gfb_docsays 'plugin cache')" "names"
else
  for _gfb_i in "$_gfb_n1" "$_gfb_n2"; do skip "$_gfb_i" "no docs/2026-10-12-gate-friction-contract-a.md beside this harness"; done
fi

# ---- run 1: a normal run, origin/main at a commit of its own, over a planted receipt
printf 'gfb planted\n' > "$_gfb_rp"
_gfb_origin "$_gfb_c1"
_gfb_t0="$(date +%s)"
_gfb_drive 45 d1 "$_gfb_o/d1.out" "="
_gfb_t1="$(date +%s)"
is  "(A2) a normal run removes the checkout's earlier receipt before its first part" \
    "$(cat "$_gfb_o/rcpt-at-part.d1" 2>/dev/null)" "absent"
is  "(A10) a normal run that leaves a receipt prints its summary as the last line of its stdout and stderr together" \
    "$(_gfb_last "$_gfb_o/d1.out")" "the summary"
# restated, not blind: C4/C5 addendum. The block above asked for the commit "as a
# field of its own", a position the addendum does not give ("records the commit
# ... or `-` when there was none") and the contract's nine fields, which parts
# 1100 and 1120 pin ("a receipt of ten fields is malformed", "one receipt line of
# nine tab-separated fields") do not leave room for. The commit rides at the end
# of the env field, `;origin=<commit>`, so the receipt is read for the commit as
# a whole field or as the tail of one, and for no other place it could hide in:
# the tree id, the mode, a count or a time cannot hold it, being fields whose
# values the other assertions pin.
if [ -f "$_gfb_rp" ] && LC_ALL=C awk -F'\t' -v s="$_gfb_c1" 'BEGIN { t = ";origin=" s }
  { for (i = 1; i <= NF; i++) if ($i == s || (length($i) > length(t) && substr($i, length($i) - length(t) + 1) == t)) f = 1 }
  END { exit !f }' "$_gfb_rp"; then _v=yes; else _v=no; fi
is  "(A1) the receipt a passing run leaves names, as a field of its own or as the tail of its env field, the commit origin/main named when the run began" "$_v" "yes"
_v="$(_gfb_chk)"; case "$_v" in "reuse "*) _v=reuse ;; esac
is  "(A1) that receipt is reused while origin/main still names that commit" "$_v" "reuse"
_gfb_origin "$_gfb_c2"
is  "(A1) a receipt whose origin/main now names another commit is refused: run origin/main moved" "$(_gfb_chk)" "run origin/main moved"
_gfb_origin -
is  "(A1) and so is one whose origin/main cannot be read now, when the receipt recorded one" "$(_gfb_chk)" "run origin/main moved"
_gfb_origin "$_gfb_c1"
# Aged: every field that is one of the run's times moves back 50,000 seconds.
if [ -f "$_gfb_rp" ]; then
  cp -p "$_gfb_rp" "$_gfb_o/d1.receipt"
  LC_ALL=C awk -F'\t' -v OFS='\t' -v a="$_gfb_t0" -v b="$_gfb_t1" \
    '{ for (i = 1; i <= NF; i++) if ($i ~ /^[0-9]+$/ && $i + 0 >= a - 2 && $i + 0 <= b + 2) $i = $i - 50000; print }' \
    "$_gfb_o/d1.receipt" > "$_gfb_rp.gfb" && mv -f "$_gfb_rp.gfb" "$_gfb_rp"
fi
is  "(A1) the same receipt aged past 12 hours, origin/main unmoved, is older than 12 hours" "$(_gfb_chk)" "run older than 12 hours"
_gfb_origin "$_gfb_c2"
is  "(A1) aged past 12 hours with origin/main moved, the origin/main check answers first" "$(_gfb_chk)" "run origin/main moved"

# ---- run 2: a record run with no origin/main at its start, during which origin/main appears
rm -rf "${_gfb_rp:?}"; printf 'gfb planted\n' > "$_gfb_rp"
_gfb_origin -
_gfb_drive 45 d2 "$_gfb_o/d2.out" "=" --record-assertions; _gfb_d2rc=$?
is  "(A2) a record run removes the checkout's earlier receipt before its first part" \
    "$(cat "$_gfb_o/rcpt-at-part.d2" 2>/dev/null)" "absent"
_v="$(cat "$_gfb_o/d2.red" 2>/dev/null)"; [ "${_v:-0}" -ge 1 ] 2>/dev/null && _v=running || _v="not running ($_v)"
is  "(A5) the record run's red, given the record run's pid, is already running while the part runs" "$_v" "running"
_v="$(LC_ALL=C awk '{ print ($1 + 0 < 8 && $2 == "0") ? "returned" : "took " $1 " s, status " $2 }' "$_gfb_o/d2.wait" 2>/dev/null)"
is  "(A5) a part's bare wait for a job of its own returns, status 0, within seconds, red running or not" "${_v:-never returned}" "returned"
is  "(A5) and the record run ends on its own rather than at the 45-second bound" "$([ "$_gfb_d2rc" -ne 124 ] && echo ended || echo "stopped at the bound")" "ended"
_v=absent; { [ -e "$_gfb_rp" ] || [ -L "$_gfb_rp" ]; } && _v=present
is  "(A1) a run with no origin/main at its start, during which origin/main appears, leaves no receipt" "$_v" "absent"
is  "(A10) a record run whose receipt is not written prints its summary as the last line of its stdout and stderr together" \
    "$(_gfb_last "$_gfb_o/d2.out")" "the summary"

# ---- run 3: a record run whose mark cannot be written, over a receipt that is a directory
rm -rf "${_gfb_rp:?}"; mkdir -p "$_gfb_rp"; printf 'keep\n' > "$_gfb_rp/keep"
_gfb_origin "$_gfb_c1"
_gfb_t0="$(date +%s)"
_gfb_drive 70 d3 "$_gfb_o/d3.out" "$_gfb_o/d3.err" --record-assertions; _gfb_d3rc=$?
_gfb_t1="$(date +%s)"
_gfb_d3tmp="$(_gfb_pidof "$_gfb_o/d3.tmp")"
case "$_gfb_d3tmp" in /*/*) [ -f "$_gfb_d3tmp/ran" ] && { chmod -R u+w "$_gfb_d3tmp"; rm -rf "${_gfb_d3tmp:?}"; } ;; esac
is  "(A6) a record run that can put neither written nor failed in place as its mark says red was not run, naming the mark" \
    "$(_gfb_begins "$_gfb_o/d3.out" '  red not run: the record run could not write its mark (')" "said"
_v="$(( _gfb_t1 - _gfb_t0 ))"
[ "$_gfb_d3rc" -ne 124 ] && [ "$_v" -le 20 ] && _v=ended || _v="took $_v s, exit $_gfb_d3rc"
is  "(A6) and ends without waiting for red, whose suite alone would take 30 seconds" "$_v" "ended"
_gfb_sp="$(_gfb_pidof "$_gfb_o/suite.d3.pid")"
if [ -z "$_gfb_sp" ]; then _v="red's suite never started"
elif _gfb_until 25 _gfb_dead "$_gfb_sp"; then _v=stopped
else _v="still running"; kill -9 "$_gfb_sp" 2>/dev/null; fi
is  "(A6) and red's suite is not left running after it" "$_v" "stopped"
is  "(A6) and red.tsv keeps the retraction" "$(_gfb_rows "$_gfb_F/engine/harness/tests/red.tsv")" "$_gfb_retr"
_v=gone; [ -d "$_gfb_rp" ] && [ -f "$_gfb_rp/keep" ] && _v=kept
is  "(A2) a receipt path that is a directory is neither removed nor written through by a run" "$_v" "kept"
is  "(A10) and the summary is still the last line on the run's stdout" "$(_gfb_last "$_gfb_o/d3.out")" "the summary"
rm -rf "${_gfb_rp:?}"

# ---- red, asked directly, beside a stub suite in a checkout of its own
_gfb_R="$_gfb/r"
mkdir -p "$_gfb_R/engine/harness/tests"
cp "$HERE/red" "$_gfb_R/engine/harness/tests/red"
cat > "$_gfb_R/engine/harness/tests/run" <<'GFBREDRUN'
#!/usr/bin/env bash
[ -n "${GFB_SUITE_PID:-}" ] && printf '%s\n' "$$" > "$GFB_SUITE_PID"
if [ -n "${GFB_SLOW:-}" ]; then i=0; while [ "$i" -lt 30 ]; do sleep 1; i=$((i + 1)); done; fi
printf '  ok    gfb red stub\n'
printf '\nreached\n'
printf '\n1 passed, 0 failed\n'
GFBREDRUN
chmod +x "$_gfb_R/engine/harness/tests/run" "$_gfb_R/engine/harness/tests/red"
printf '1\tgfb red stub\n' > "$_gfb_R/engine/harness/tests/assertions.tsv"
( _fx_cd "${_gfb_R:?}" && git init -q -b main && git add -A && _gfb_git commit -qm seed ) >/dev/null 2>&1
_gfb_R="$(cd "${_gfb_R:?}" && pwd -P)"
_gfb_redt="$_gfb_R/engine/harness/tests/red.tsv"
# <case> <mark> [<pid>]: red --after <mark> <pid> from a shell of its own that
# is red's parent and, with no pid given, the pid. Out and status beside $_gfb_o/red.<case>.
_gfb_redc() {
  mkdir -p "$_gfb/rt.$1"
  _gfb_bounded 20 env -u FELIX_TEST_NO_MANIFEST TMPDIR="$_gfb/rt.$1" bash -c \
    'p="$3"; [ -n "$p" ] || p=$$; "$1" --after "$2" "$p" > "$4.out" 2>&1; printf "%s\n" "$?" > "$4.rc"' \
    _ "$_gfb_R/engine/harness/tests/red" "$2" "${3:-}" "$_gfb_o/red.$1"
}

# A9: a mark that is not a regular file
mkfifo "$_gfb/mk.fifo"; mkdir -p "$_gfb/mk.dir"; ln -s "$_gfb/mk.fifo" "$_gfb/mk.link"
_gfb_nrf() { printf 'red: not run: the record run did not write a manifest (%s is not a regular file)' "$1"; }
_gfb_redc fifo "$_gfb/mk.fifo"
is  "(A9) red refuses a mark that is a FIFO at once, without opening it, as not a regular file" \
    "$(_gfb_said "$_gfb_o/red.fifo.out" "$(_gfb_nrf "$_gfb/mk.fifo")")" "$(_gfb_nrf "$_gfb/mk.fifo")"
is  "(A9) and exits 2" "$(cat "$_gfb_o/red.fifo.rc" 2>/dev/null)" "2"
is  "(A9) and leaves the retraction in red.tsv" "$(_gfb_rows "$_gfb_redt")" "$_gfb_retr"
_gfb_redc dir "$_gfb/mk.dir"
is  "(A9) a mark that is a directory is refused the same way" \
    "$(_gfb_said "$_gfb_o/red.dir.out" "$(_gfb_nrf "$_gfb/mk.dir")")" "$(_gfb_nrf "$_gfb/mk.dir")"
_gfb_redc link "$_gfb/mk.link"
is  "(A9) and so is a symbolic link to a FIFO" \
    "$(_gfb_said "$_gfb_o/red.link.out" "$(_gfb_nrf "$_gfb/mk.link")")" "$(_gfb_nrf "$_gfb/mk.link")"

# A8: a pid that is alive and is not red's parent
_gfb_gone="red: not run: the record run ended before it wrote the manifest"
sleep 60 & _gfb_P=$!
_gfb_redc a8 "$_gfb/mk.none" "$_gfb_P"
kill "$_gfb_P" 2>/dev/null; wait "$_gfb_P" 2>/dev/null
is  "(A8) a live process that is not the one that started red never extends red's wait: red refuses as the record run gone" \
    "$(_gfb_said "$_gfb_o/red.a8.out" "$_gfb_gone")" "$_gfb_gone"

# A7: the record run, red's parent, is killed while red's suite runs
mkdir -p "$_gfb/rt.a7"
env -u FELIX_TEST_NO_MANIFEST GFB_SLOW=1 GFB_SUITE_PID="$_gfb_o/a7.suite" TMPDIR="$_gfb/rt.a7" \
  bash -c '"$1" --after "$2" "$$" > "$3" 2>&1 & printf "%s\n" "$!" > "$4"; wait' \
  _ "$_gfb_R/engine/harness/tests/red" "$_gfb/mk.a7" "$_gfb_o/red.a7.out" "$_gfb_o/a7.red" &
_gfb_W=$!
_gfb_a7up() { [ -s "$_gfb_o/a7.red" ] && { [ -s "$_gfb_o/a7.suite" ] || _gfb_dead "$(_gfb_pidof "$_gfb_o/a7.red")"; }; }
_gfb_until 75 _gfb_a7up
kill -9 "$_gfb_W" 2>/dev/null; wait "$_gfb_W" 2>/dev/null
_gfb_rp7="$(_gfb_pidof "$_gfb_o/a7.red")"
if _gfb_until 50 _gfb_dead "$_gfb_rp7"; then _v="$(_gfb_said "$_gfb_o/red.a7.out" "$_gfb_gone")"
else _v="red still running 10 s after its record run was killed"; fi
is  "(A7) red, its record run killed while red's suite runs, refuses within seconds as the record run gone" "$_v" "$_gfb_gone"
_gfb_sp7="$(_gfb_pidof "$_gfb_o/a7.suite")"
if [ -z "$_gfb_sp7" ]; then _v="red's suite never started"
elif _gfb_until 15 _gfb_dead "$_gfb_sp7"; then _v=stopped
else _v="still running"; fi
is  "(A7) and stops its suite, which would have run 30 seconds more" "$_v" "stopped"
is  "(A7) and removes its base checkout" "$(ls -A "$_gfb/rt.a7" 2>/dev/null)" ""
is  "(A7) and leaves the retraction in red.tsv" "$(_gfb_rows "$_gfb_redt")" "$_gfb_retr"
_gfb_alive "$_gfb_rp7" && kill -9 "$_gfb_rp7" 2>/dev/null
_gfb_alive "$_gfb_sp7" && kill -9 "$_gfb_sp7" 2>/dev/null

# ---- A3: the gate's tests check, beside a suite whose reuse line stderr pushed off the first line
_gfb_G="$_gfb/g"
mkdir -p "$_gfb_G/engine/harness/tests" "$_gfb_G/projects/felix"
cp "$REAL_HARNESS/../../projects/felix/gate.sh" "$_gfb_G/projects/felix/gate.sh"
cat > "$_gfb_G/engine/harness/tests/run" <<'GFBGATERUN'
#!/usr/bin/env bash
printf 'gfb: a line on stderr before the suite says anything\n' >&2
printf 'reused the suite run that ended 09:00 on this tree (normal), not run again\n'
printf '\n7 passed, 0 failed (reused)\n'
exit 0
GFBGATERUN
chmod +x "$_gfb_G/engine/harness/tests/run"
( _fx_cd "${_gfb_G:?}" && git init -q -b main && git add -A && _gfb_git commit -qm seed ) >/dev/null 2>&1
( cd "${_gfb_G:?}" && _gfb_bounded 60 env -u FELIX_TEST_NO_MANIFEST FELIX_KERNEL_CACHE="$_gfb_G/no-cache" \
    TMPDIR="$_gfb/tmpdir" bash projects/felix/gate.sh ) > "$_gfb_o/gate.out" 2>&1
_v="$(LC_ALL=C awk '/^  tests / && t == "" { t = $0 }
  END { if (t == "") print "no tests line"; else if (t ~ / ok$/) print "reported ok"; else if (t ~ /skipped/) print "skipped"; else print "not reported ok" }' \
  "$_gfb_o/gate.out" 2>/dev/null)"
is  "(A3) a suite log holding the reuse line below a line stderr printed first is never the tests check's ok" "$_v" "not reported ok"
# <<< gate-friction-a-addendum
