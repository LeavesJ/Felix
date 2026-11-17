# >>> gate-friction-d-blind
printf '\ngate friction D: the parallel runner, part mode, groups and slots (blind, revision 18)\n'
# Blind, written from contract D (docs/2026-10-18-gate-friction-contract-d.md, revision 8) alone. Nothing here was read off an implementation;
# tests/run, tests/red and tests/receipt.sh are run, never read, in copies of this suite that _suite_copy_tree (part 0003) makes under $TMP, each
# with planted parts of this block's own. Every case points TMPDIR at a fixture directory, so none touches the machine's slots; every inner run is
# under a bounded runner that makes its own process group and resets INT, QUIT, HUP and TERM as the case asks; every case ends by asking that group
# to hold no live process, stopped or running, for 30 s, and what is left is named and then sent CONT and KILL by pid. Nothing is killed by pattern.
# Names say the clause: D1 the interface, D2 a unit and part mode, D3 the log and the verdict, D4 the record, red and the durations, D5 groups, D6
# the runner (signals, slots, holders), D8 the fixtures, R9, R10 and R17 the amendments. The runner's own failures are part 1293's.
# Readings taken where the contract leaves room: a refusal is told by its exit status (2), one stderr line and no $TMP made (a mktemp on PATH that
# writes down its calls); a FELIX_TEST_JOBS that is set and empty is not a valid N; a member the driver does not source, in groups.tsv, is not asked.
# Revision 17 (R55 to R57), from the contract alone: every run bound is 600 s (_db1_lim, 150 s before); a wait for an event of a run lasts until the run's bound
# has passed (_db1_evt); the slot holds, the sleeping children and the grandchildren live B + 30 s (630 s; were 60 s and 30 s, which a leftover check could outlast);
# the watches for a unit while a slot is held start once a holder waits, not 2 s after the prelude's mark; the kill -9 slot window is 20 s (was 2 s, below R56's floor);
# the cap control's units hold their spans until four have begun, so its overlap no longer rests on 3 s spans meeting under load; the ordering case's sleeper holds
# its slot until the run's bound (was 60 s). Each window, its kind and its L are in a comment beside it. Review fix: the kill -9 slot window is shown red against
# a slot a dead holder's mark keeps 30 s only; a holder that retries every 30 s is no longer claimed to fail it.
# Readings (revision 17): a holder is a live perl whose command line holds " --part " and this case's copy (R45); a watch, a sleep and then a look for what only a
# build without the clause makes, cannot fail D's build and is read as R56's floor, so it stands, counted from the event after which that build could first show itself.
# Revision 18 (R58, R61, R62), from the contract alone. R58: the two watches for a unit while a slot is held (hw, hk) last 20 s from the first listing that shows a
# waiting holder (were 2 s): a holder that starts its unit without the slot's lock forks it inside them. Each is a poll that ends once it finds a unit, which fails
# the name, or once the run has ended. hw's 3 s watch after the slot is let go stays: R12's drain and the look for any process of the copy, in the same name, catch
# the build it watches for. R61: every sleeper, child, grandchild, unit wait and span.pl's wait this part plants looks for its case directory every second at most and
# ends once it is gone (sl.pl, gc.pl, the units' loops); the kill -9 window and the watches end once the run has exited, after one more look. R62: with DJX_MLOG
# naming a file, "1291 run CASE/LABEL bound B ms MS" for every run and "1291 margin CASE/LABEL T T-MS ms MS|none" for the kill -9 window and the three watches.
# R59 and R60 change nothing here: no case ends a record run with a signal, and none takes R1's at-exit listings.
# Readings (revision 18): a run's start-to-exit is the ms run.pl, its bounded runner, writes at its own exit, from just before its fork to its waitpid's return
# (or to its KILL at B, which its alarm counts from the same fork), so it is read against B as run.pl counts B; review fix: it was the case's reaping, which put
# cap's first run at the second's end. A watch's ms is none on D's build and, where it found what it watches for, the ms from its start to the find. No name changes.
# An assertion whose name ends in (control) passes before D is built on purpose: it pins what makes the others mean something.
DB1="$TMP/db1"
mkdir -p "$DB1/pp/std" "$DB1/pp/ref" "$DB1/n" "$DB1/shim"
_db1_E=(); _db1_INT=DEFAULT; _db1_QUIT=DEFAULT; _db1_td=""; _db1_ctl=0; _db1_pf=(); _db1_cl=ok; _db1_leak=""; _db1_prog=run; _db1_lim=600; _db1_dl=0
# _db1_lim is every run's bound B (R55: 600 s, a run bound is not a margin); _db1_clean's 150 polls of 0.2 s are R12's 30 s drain, which R56 keeps
cat > "$DB1/run.pl" <<'DB1PL'
my ($t, $i, $q, $f, $m) = splice(@ARGV, 0, 5);
my $s = 0; if ($m ne "") { require Time::HiRes; $s = Time::HiRes::time() }
sub ms { if ($m ne "" && open(my $h, ">", $m)) { printf $h "%d\n", (Time::HiRes::time() - $s) * 1000; close $h } }
my $p = fork; defined $p or exit 125;
if (!$p) { setpgrp(0, 0); $SIG{INT} = $i; $SIG{QUIT} = $q; $SIG{HUP} = 'DEFAULT'; $SIG{TERM} = 'DEFAULT'; if (open(my $h, ">", $f)) { print $h "$$\n"; close $h } exec @ARGV; exit 127 }
$SIG{ALRM} = sub { kill "KILL", -$p; ms(); exit 124 };
alarm $t; waitpid $p, 0; my $w = $?; ms();
exit(($w & 127) ? 128 + ($w & 127) : $w >> 8);
DB1PL
printf '#!/bin/sh\nprintf "x\\n" >> "$DJX_DIR/mktemp.log"\nexec "%s" "$@"\n' "$(command -v mktemp)" > "$DB1/shim/mktemp"; chmod +x "$DB1/shim/mktemp"
: > "$DB1/g-empty.tsv"; printf '1\tdjx a1\n' > "$DB1/man.tsv"
_db1_until() { local n="$1" i=0; shift; while [ "$i" -lt "$n" ]; do "$@" && return 0; sleep 0.2; i=$((i + 1)); done; "$@"; }
_db1_cnt()  { LC_ALL=C awk -v p="$2" 'index($0, p) == 1 { n++ } END { print n + 0 }' "$1" 2>/dev/null; }   # FILE PREFIX: lines starting with it
_db1_line() { grep -cxF -e "$2" "$1" 2>/dev/null; }   # FILE LINE: lines that are exactly it
_db1_ps()  { ps -A -o pid= -o command= 2>/dev/null | K="$1" LC_ALL=C awk 'index($0, ENVIRON["K"]) { printf "%s ", $1 }'; }   # pids whose command line holds K
_db1_ms()  { perl -MTime::HiRes=time -e 'printf "%d", time * 1000'; }
# R62: with DJX_MLOG naming a file, a line of evidence (never a verdict); _db1_now is the ms only when there is a log to write
_db1_ml()  { [ -z "${DJX_MLOG:-}" ] || printf '1291 %s\n' "$*" >> "$DJX_MLOG"; }
_db1_now() { [ -z "${DJX_MLOG:-}" ] || _db1_ms; }
# sl.pl DIR SECONDS TAG...: R61's sleeper: it sleeps SECONDS, or until DIR, its case's directory, is gone, looked for once a second
printf '%s\n' 'my ($d, $s) = @ARGV; my $e = time + $s; sleep 1 while time < $e && -d $d;' > "$DB1/sl.pl"
_db1_gm() { ps -A -o pid= -o pgid= -o stat= -o command= 2>/dev/null | G=" $* " LC_ALL=C awk 'index(ENVIRON["G"], " " $2 " ") && $3 !~ /^Z/ { c = $0; sub(/^ *[0123456789]+ +[0123456789]+ +[^ ]+ +/, "", c); print $1 " " $3 " " substr(c, 1, 70) }'; }
# R12: "ok" once the process groups of this case's runs hold no live process (30 s), else what was left, sent CONT and then KILL by pid.
_db1_clean() {
  local g="" f l="" i=0 p
  for f in ${_db1_pf[@]+"${_db1_pf[@]}"}; do g="$g $(cat "$f" 2>/dev/null)"; done
  [ -n "${g// /}" ] || { printf ok; return 0; }
  while [ "$i" -lt 150 ]; do l="$(_db1_gm $g)"; [ -n "$l" ] || { printf ok; return 0; }; sleep 0.2; i=$((i + 1)); done
  for p in $(printf '%s\n' "$l" | awk '{ print $1 }'); do kill -CONT "$p" 2>/dev/null; done
  for p in $(printf '%s\n' "$l" | awk '{ print $1 }'); do kill -KILL "$p" 2>/dev/null; done
  printf 'left behind: %s' "$(printf '%s' "$l" | tr '\n' ';')"
}
_db1_slots() { perl -e 'use Fcntl ":flock"; for my $f (glob "$ARGV[0]/felix-suite-slots/*") { open(my $h, "<", $f) or next; print "$f " unless flock($h, LOCK_EX | LOCK_NB); close $h }' "$1"; }
_db1_si() { ls -i "${_db1_td:-$_db1_tmp}/felix-suite-slots" 2>/dev/null | LC_ALL=C sort | tr '\n' ' '; }   # the slot files' inode numbers and names
# SLOTFILE SECONDS: this process holds the lock on the file for that long, or until the slot's directory is gone; _db1_hp is its pid. R56: its life is a bound,
# B + 30 s from the callers (R44's H; was 60 s, which a loaded run could outlast and then start a unit "while held"); the wait for its "held" lasts until the
# run bound, ended early if the perl has gone (was 20 s)
_db1_hok() { [ -s "$_db1_c/hold.out" ] || ! kill -0 "$_db1_hp" 2>/dev/null; }
_db1_hold() {
  mkdir -p "${1%/*}"
  perl -e 'use Fcntl ":flock"; open(my $h, ">>", $ARGV[0]) or exit 4; flock($h, LOCK_EX | LOCK_NB) or exit 3; $| = 1; print "held\n"; my $e = time + $ARGV[1]; sleep 1 while time < $e && -d $ARGV[2]' \
    "$1" "$2" "${1%/*}" > "$_db1_c/hold.out" 2>&1 &
  _db1_hp=$!; _db1_until $((_db1_lim * 5)) _db1_hok
}
_db1_unhold() { kill -KILL "$_db1_hp" 2>/dev/null; { wait "$_db1_hp"; } 2>/dev/null; return 0; }
# CASE [--red] GROUPS MANIFEST STUB...: the copy at $DB1/n/CASE (_db1_F, _db1_T, _db1_c, _db1_tmp); 1 when it could not be made
_db1_new() {
  local n="$1" r=""; shift
  [ "${1:-}" != --red ] || { r=--red; shift; }
  _db1_c="$DB1/n/$n"; _db1_F="$_db1_c/f"; _db1_T="$_db1_F/engine/harness/tests"; _db1_tmp="$_db1_c/tmp"; _db1_pf=()
  rm -rf "$_db1_c"; mkdir -p "$_db1_tmp" || return 1
  _suite_copy_tree ${r:+"$r"} "$_db1_F" "$@"
}
# LABEL ARG...: the copy's driver (or red, with _db1_prog=red) in the background under a bounded runner (INT and QUIT as _db1_INT and _db1_QUIT);
# stdout $_db1_c/LABEL.out, stderr LABEL.err, the process group's id LABEL.pid; _db1_bg is the runner's pid
_db1_start() {
  local l="$1" t; shift
  t="$(_db1_now)"; [ -z "$t" ] || rm -f "$_db1_c/$l.ms"
  ( cd "$_db1_F" && exec env -u FELIX_TEST_NO_MANIFEST -u FELIX_TEST_JOBS -u FELIX_TEST_SLOTS -u FELIX_TEST_RED_JOBS -u FELIX_TEST_SLOT_NOTE -u FELIX_TEST_PART_LOG \
      -u FELIX_TEST_PART_RAN -u FELIX_TEST_PART_END -u FELIX_TEST_PART_RECORD -u PERL5OPT \
      TMPDIR="${_db1_td:-$_db1_tmp}" FELIX_TEST_SLOTS=8 DJX_LIFE=$((_db1_lim + 30)) DJX_DIR="$_db1_c" DJX_PL="$DB1" DJX_ID="${TMP##*/}-${_db1_c##*/}" ${_db1_E[@]+"${_db1_E[@]}"} \
      perl "$DB1/run.pl" "$_db1_lim" "$_db1_INT" "$_db1_QUIT" "$_db1_c/$l.pid" "${t:+$_db1_c/$l.ms}" "$BASH" "$_db1_T/$_db1_prog" "$@" \
  ) > "$_db1_c/$l.out" 2> "$_db1_c/$l.err" &
  _db1_bg=$!; _db1_pf[${#_db1_pf[@]}]="$_db1_c/$l.pid"
  _db1_dl=$((SECONDS + _db1_lim + 5))   # R44: the run's own bound (run.pl's KILL at _db1_lim) and 5 s more; a wait for an event of the run lasts until then
  [ -z "$t" ] || printf '%s %s %s %s\n' "${_db1_c##*/}/$l" "$_db1_lim" "$t" "$_db1_c/$l.ms" > "$DB1/t0.$_db1_bg"   # R62: CASE/LABEL, B, the start and run.pl's ms file
}
# R44, R56: PRED ARG...: waits until PRED ARG... holds, the run has ended, or the run's own bound has passed; 0 when it held
_db1_evt() { while ! "$@"; do kill -0 "$_db1_bg" 2>/dev/null || break; [ "$SECONDS" -lt "$_db1_dl" ] || break; sleep 0.2; done; "$@"; }
_db1_wait() { { wait "$_db1_bg"; } 2>/dev/null; _db1_rc=$?; _db1_mr "$_db1_bg"; _db1_E=(); _db1_INT=DEFAULT; _db1_QUIT=DEFAULT; }
# BGPID: R62's line for the run that job was, "1291 run CASE/LABEL bound B ms START-TO-EXIT": the ms run.pl, its bounded runner, wrote at its own exit, from
# just before its fork to its waitpid's return (or to its KILL at B), not to the case's reaping; were run.pl ever killed before it wrote, the ms to the reaping
_db1_mr() {
  local f="$DB1/t0.$1" c b t m x
  [ -n "${DJX_MLOG:-}" ] && [ -f "$f" ] || return 0
  read -r c b t m < "$f"; rm -f "$f"; x="$(cat "$m" 2>/dev/null)"; case "$x" in ''|*[!0123456789]*) x=$(( $(_db1_ms) - t )) ;; esac
  _db1_ml run "$c" bound "$b" ms "$x"
}
# R58, a watch: SECS LABEL PRED...: looks every 0.2 s, for SECS s at least (by $SECONDS), for what PRED finds (only a build without the clause makes it), and ends
# early once PRED holds, which fails the name, or once the run has ended (R61), after one more look. 1 when PRED held; logs "margin CASE/LABEL T SECS ms none" (R62),
# or the ms from the watch's start to the find
_db1_watch() {
  local n="$1" l="$2" s="$SECONDS" t r=0; shift 2; t="$(_db1_now)"
  while [ $((SECONDS - s)) -le "$n" ]; do "$@" && { r=1; break; }; kill -0 "$_db1_bg" 2>/dev/null || break; sleep 0.2; done
  [ "$r" = 1 ] || ! "$@" || r=1
  _db1_ml margin "${_db1_c##*/}/$l" T "${n}000" ms "$([ "$r" = 1 ] && [ -n "$t" ] && echo $(( $(_db1_ms) - t )) || echo none)"
  [ "$r" = 0 ]
}
_db1_sweep() { _db1_cl="$(_db1_clean)"; [ "$_db1_cl" = ok ] || _db1_leak="$_db1_leak [$_db1_c: $_db1_cl]"; }   # R12: ends what this case's runs left; _db1_leak keeps the names
_db1_run()  { _db1_start "$@"; _db1_wait; _db1_sweep; }   # _db1_cl: R12's verdict on this run
_db1_rcpt() { if [ -f "$_db1_F/.git/felix-suite-receipt" ]; then echo present; else echo absent; fi; }
_db1_last() { tail -n 1 "$_db1_c/$1.out" 2>/dev/null; }
_db1_vl() { grep -E '^  (ok    |FAIL  |skip  )' "$1" 2>/dev/null | LC_ALL=C sort; }
_db1_same() { local d; d="$(LC_ALL=C diff <(_db1_vl "$1") <(_db1_vl "$2") | head -4 | tr '\n' '|')"; printf '%s' "${d:-same}"; }
_db1_sum() { local s="$1"; s="${s% (counted from lines)}"; s="${s% (reused)}"; printf '%s' "$s"; }
_db1_redrows() { if [ -f "$_db1_T/red.tsv" ]; then grep -v '^#' "$_db1_T/red.tsv" | tr '\n' '|'; else printf '(no red.tsv)'; fi; }
_db1_cnts() { case "$(_db1_redrows)" in base$'\t'origin/main$'\t'*$'\t'0.0.1\|run$'\t'0$'\t'[0123456789]*$'\t'[0123456789]*\|) echo counts ;; *) _db1_redrows ;; esac; }
# The standard planted parts: three that pass, 0010-pa.sh, 0020-pb.sh and 0030-pc.sh, in pp/std. Each prints the FELIX_TEST_RECORD and FELIX_TEST_RED_JOBS it sees,
# and in red's suite (FELIX_TEST_NO_MANIFEST=1) writes down its process id.
_db1_snip='printf "djx-rec:%s\n" "${FELIX_TEST_RECORD-unset}"
printf "djx-redjobs:%s\n" "${FELIX_TEST_RED_JOBS-unset}"
[ "${FELIX_TEST_NO_MANIFEST:-0}" != 1 ] || printf "%s\n" "$$" >> "$DJX_DIR/redpids"'
_db1_std() { local f="$1" s="$2" a; shift 2; { printf 'printf "\\ndjx-sec %s\\n"\n%s\n' "$s" "$_db1_snip"; for a in "$@"; do printf '%s\n' "$a"; done; } > "$f"; }
_db1_std "$DB1/pp/std/0010-pa.sh" 0010-pa.sh 'ok "djx a1"' 'ok "djx a2"'
_db1_std "$DB1/pp/std/0020-pb.sh" 0020-pb.sh 'ok "djx b1"' 'ok "djx b2"'
_db1_std "$DB1/pp/std/0030-pc.sh" 0030-pc.sh 'ok "djx c1"' 'skip "djx c skip" "a reason"'
_db1_mk() {   # CASE [FILE]: pp/CASE holds 0010-pa.sh, 0030-pc.sh and the part read from stdin (default 0020-pb.sh)
  local d="$DB1/pp/$1"; mkdir -p "$d" && cp "$DB1/pp/std/0010-pa.sh" "$DB1/pp/std/0030-pc.sh" "$d/" && cat > "$d/${2:-0020-pb.sh}"
}
# A reached summary: "ok" when run $1 reused a receipt and ran no part.
_db1_reuse() { local f="$_db1_c/$1.out" r=""
  [ "$_db1_rc" = 0 ] || r="$r exit $_db1_rc;"; [ "$(_db1_cnt "$f" 'reused the suite run that ended ')" = 1 ] || r="$r no reuse line;"
  [ "$(_db1_cnt "$f" '  ok    ')" = 0 ] || r="$r a part ran;"; case "$(_db1_last "$1")" in *" (reused)") ;; *) r="$r summary [$(_db1_last "$1")];" ;; esac
  printf '%s' "${r:-ok}"; }

# ---- the helper (D8)
_db1_new h "$DB1/g-empty.tsv" "$DB1/man.tsv" "$DB1/pp/std"/*.sh
_db1_g="$(git -C "$_db1_F" rev-parse --abbrev-ref HEAD 2>/dev/null) $(git -C "$_db1_F" rev-list --count HEAD 2>/dev/null) $([ "$(git -C "$_db1_F" rev-parse HEAD 2>/dev/null)" = "$(git -C "$_db1_F" rev-parse refs/remotes/origin/main 2>/dev/null)" ] && echo origin-at-head)"
is "D8: _suite_copy_tree makes a checkout on main with one commit and refs/remotes/origin/main at it (control)" "$_db1_g" "main 1 origin-at-head"
is "D8: and its driver sources every part it holds once, in name order: 0001 to 0007, the stubs, then 9990 (control)" \
   "$(sed -n 's|^\. "\$HERE/parts/\(.*\)"$|\1|p' "$_db1_T/run" | tr '\n' ' ')" "$(cd "$_db1_T/parts" && LC_ALL=C ls | LC_ALL=C sort | tr '\n' ' ')"
_db1_x=""; _suite_copy_tree "$DB1/n/hx" "$DB1/g-empty.tsv" "$DB1/man.tsv" "$DB1/pp/std/0010-pa.sh" "$DB1/nosuch/0020-pb.sh" 2>/dev/null; _db1_x="$?"
for _db1_p in 0005-x.sh 9990-x.sh x.sh; do mkdir -p "$DB1/pp/bad"; : > "$DB1/pp/bad/$_db1_p"; _suite_copy_tree "$DB1/n/hy" "$DB1/g-empty.tsv" "$DB1/man.tsv" "$DB1/pp/bad/$_db1_p" 2>/dev/null; _db1_x="$_db1_x $?"; done
_suite_copy_tree "$DB1/n/hz" "$DB1/g-empty.tsv" "$DB1/man.tsv" "$DB1/pp/std/0010-pa.sh" "$DB1/pp/std/0010-pa.sh" 2>/dev/null; _db1_x="$_db1_x $?"
is "D8: _suite_copy_tree returns 1 for a missing stub, a stub numbered 0005 or 9990, one not named NNNN-name.sh, and a repeated stub" "$_db1_x" "1 1 1 1 1"
is "D8: and leaves no run in the copy when it fails" "$(ls "$DB1/n/hx/engine/harness/tests/run" "$DB1/n/hy/engine/harness/tests/run" "$DB1/n/hz/engine/harness/tests/run" 2>/dev/null | wc -l | tr -d ' ')" "0"

# ---- the positive control: planted passing parts under -j 3 (D8), and -j 1 beside them
# A receipt is left by a passing run only where a manifest was compared, so a copy whose "no receipt" means something has one: it lists the first
# assertion of the prelude, which every run reaches once, and which a serial run names here.
_db1_run h1 -j 1
printf '1\t%s\n' "$(sed -n 's/^  ok    //p' "$_db1_c/h1.out" | sed -n 1p)" > "$DB1/pman.tsv"; rm -rf "$DB1/n/h"
_db1_new ctl "$DB1/g-empty.tsv" "$DB1/pman.tsv" "$DB1/pp/std"/*.sh
_db1_run c3 -j 3
_db1_r3="$(cat "$_db1_F/.git/felix-suite-receipt" 2>/dev/null)"; _db1_d3="$(cat "$_db1_F/.git/felix-suite-durations" 2>/dev/null)"
[ "$_db1_rc" = 0 ] && [ -n "$_db1_r3" ] && _db1_ctl=1
is "D8: a -j 3 run of planted passing parts exits 0, leaves a receipt and no process in its group, stopped or running (positive control)" "$_db1_rc $_db1_ctl $_db1_cl" "0 1 ok"
_db1_run ru1 --reuse;        is "D4: --reuse accepts the receipt a -j 3 run left, and runs no part" "$(_db1_reuse ru1)" ok
_db1_run ru2 -j 2 --reuse;   is "D1: -j 2 --reuse accepts it as well" "$(_db1_reuse ru2)" ok
_db1_run ru3 --reuse -j 2;   is "D1: and --reuse -j 2, in the other order" "$(_db1_reuse ru3)" ok
_db1_run c1 -j 1
_db1_r1="$(cat "$_db1_F/.git/felix-suite-receipt" 2>/dev/null)"
_db1_run ru4 -j 3 --reuse;   is "D4: and -j 3 --reuse accepts the receipt a -j 1 run left" "$(_db1_reuse ru4)" ok
_db1_s1="$(_db1_last c1)"; _db1_s3="$(_db1_last c3)"
is "D3: the summary of a -j 3 run is the -j 1 summary and ends (counted from lines), which -j 1's does not" \
   "$(_db1_sum "$_db1_s3") | $_db1_s3 | $_db1_s1" "$_db1_s1 | $_db1_s1 (counted from lines) | $_db1_s1"
is "D3: a -j 3 run gives the (verdict, name) lines a -j 1 run gives" "$(_db1_same "$_db1_c/c3.out" "$_db1_c/c1.out")" "same"
is "D3: and prints the part sections in the same order" \
   "$(grep '^djx-sec ' "$_db1_c/c3.out" | tr '\n' ' ')" "$(grep '^djx-sec ' "$_db1_c/c1.out" | tr '\n' ' ')"
_db1_k="$(printf '%s' "$_db1_s1" | awk '{ print $1, $3 + 0, ($6 == "skipped" ? $5 : 0) }')"
is "D4: the receipt a -j 3 run leaves is one v1 line of nine fields, mode normal, with the summary's counts" \
   "$(printf '%s\n' "$_db1_r3" | awk -F'\t' 'END { print NR, NF, $1, $3, $4, $5, $6 }') | $(printf '%s\n' "$_db1_r1" | awk -F'\t' '{ print $3, $4, $5, $6 }')" \
   "1 9 v1 normal $_db1_k | normal $_db1_k"
is "D4: a -j 3 run writes durations, one line a unit: whole seconds, a tab, the unit's name" \
   "$(printf '%s\n' "$_db1_d3" | awk -F'\t' '$1 ~ /^(0|[123456789][0123456789]*)$/ { print $2 }' | LC_ALL=C sort | tr '\n' ' ')" "0010-pa.sh 0020-pb.sh 0030-pc.sh "
is "D2: every unit of a plain -j 3 run sees FELIX_TEST_RECORD as 0, as a part of a plain -j 1 run does" "$(_db1_line "$_db1_c/c3.out" djx-rec:0) $(_db1_line "$_db1_c/c1.out" djx-rec:0)" "3 3"

# ---- the record control (D4): a --red copy writes the manifest and red.tsv, serially and under -j 3, and the manifest is the same
_db1_new rc --red "$DB1/g-empty.tsv" "$DB1/man.tsv" "$DB1/pp/std"/*.sh
_db1_run r1 --record-assertions
_db1_m1="$(cat "$_db1_T/assertions.tsv")"; _db1_x=0
case "$_db1_rc|$(_db1_redrows)" in 0\|base$'\t'origin/main$'\t'*$'\t'0.0.1\|run$'\t'0$'\t'[0123456789]*$'\t'[0123456789]*\|) cmp -s "$DB1/man.tsv" "$_db1_T/assertions.tsv" || _db1_x=1 ;; esac
is "D8: a record run in a --red copy of planted passing parts exits 0, rewrites the manifest, leaves red.tsv with counts and no process (positive control)" "$_db1_x $_db1_cl" "1 ok"
cp "$DB1/man.tsv" "$_db1_T/assertions.tsv"; rm -f "$_db1_c/redpids"; _db1_run r3 -j 3 --record-assertions
_db1_m3="$(cat "$_db1_T/assertions.tsv")"
is "D4: a -j 3 record run exits 0, writes the manifest a serial one writes on the same tree, byte for byte, and leaves red.tsv with counts and no process" \
   "$_db1_rc $([ "$_db1_m3" = "$_db1_m1" ] && echo same || echo differ) $(_db1_cnts) $_db1_cl" "0 same counts ok"
is "D4: red's suite ran its three units as three separate processes, which a serial suite does not (FELIX_TEST_RED_JOBS)" "$(LC_ALL=C sort -u "$_db1_c/redpids" 2>/dev/null | wc -l | tr -d ' ')" 3
is "D4: and no FELIX_TEST_RED_JOBS reaches a part (control)" "$(grep '^djx-redjobs:' "$_db1_c/r3.out" | LC_ALL=C sort -u | tr '\n' ' ')" "djx-redjobs:unset "
is "D2: every unit of a -j 3 record run sees FELIX_TEST_RECORD as 1, as the parts of a serial record run do" "$(_db1_line "$_db1_c/r3.out" djx-rec:1) $(_db1_line "$_db1_c/r1.out" djx-rec:1)" "3 3"
cp "$DB1/man.tsv" "$_db1_T/assertions.tsv"; _db1_run r3b --record-assertions -j 3
is "D1: --record-assertions -j 3, in the other order, exits 0 and records the same manifest" "$_db1_rc $([ "$(cat "$_db1_T/assertions.tsv")" = "$_db1_m1" ] && echo same || echo differ)" "0 same"
_db1_s3="$(_db1_last r3)"
is "D4: a -j 3 record run prints no record judge in this suite, as it did, and its summary ends (counted from lines)" \
   "$(_db1_line "$_db1_c/r3.out" '  no record judge in this suite: the record is not re-judged') ${_db1_s3##* (}" "1 counted from lines)"
rm -rf "$DB1/n/rc"

# ---- refusals (D1, D5): exit 2 with one stderr line, before $TMP is made
for _db1_i in 1 2 3 4 5 6 7; do printf 'ok "djx r%s"\n' "$_db1_i" > "$DB1/pp/ref/00${_db1_i}0-r$_db1_i.sh"; done
_db1_new ref "$DB1/g-empty.tsv" - "$DB1/pp/ref"/*.sh
_db1_gp="$_db1_T/groups.tsv"; _db1_X=(); _db1_w=""; _db1_els=""
_db1_ref() {   # ARG...: run the copy's driver with them under a mktemp that writes down its calls; _db1_v is ok when it refused as D1 says
  local r="" n
  rm -f "$_db1_c/mktemp.log"; _db1_E=(PATH="$DB1/shim:$PATH" ${_db1_X[@]+"${_db1_X[@]}"}); _db1_X=()
  _db1_run ref "$@"
  n="$(awk 'END { print NR }' "$_db1_c/ref.err")"
  [ "$_db1_rc" = 2 ] || r="$r exit $_db1_rc, not 2;"
  [ "$n" = 1 ] || r="$r $n stderr lines, not 1;"
  [ ! -s "$_db1_c/mktemp.log" ] || r="$r a temporary directory was made;"
  _db1_v="${r:-ok}"; _db1_el="$(sed -n 1p "$_db1_c/ref.err")"
}
_db1_acc() {   # ARG...: the run is accepted (exit 0) and made its temporary directory, so the shim saw it
  local r=""
  rm -f "$_db1_c/mktemp.log"; _db1_E=(PATH="$DB1/shim:$PATH"); _db1_run ref "$@"
  [ "$_db1_rc" = 0 ] || r="$r exit $_db1_rc, not 0;"; [ -s "$_db1_c/mktemp.log" ] || r="$r no temporary directory was made;"
  _db1_v="${r:-ok}"
}
_db1_refs() {   # LABEL ARGS-LIST...: each list, split on blanks, is refused; _db1_w names the ones that were not
  local l="$1" a; shift
  _db1_w=""; for a in "$@"; do _db1_ref $a; [ "$_db1_v" = ok ] || _db1_w="$_db1_w [$a]$_db1_v"; done
}
_db1_refs j '-j' '-j3' '-j 2 -j 3'
is "D1: -j with no N, -jN as one word and a second -j are each refused: exit 2, one stderr line, no \$TMP made" "${_db1_w:-ok}" ok
_db1_w=""; for _db1_a in 0 65 007 +2 -2 x 2x ''; do _db1_ref -j "$_db1_a"; [ "$_db1_v" = ok ] || _db1_w="$_db1_w [-j $_db1_a]$_db1_v"; done
is "D1: an N that is not 1 to 64 in plain decimal (0 65 007 +2 -2 x 2x and empty) is refused the same way" "${_db1_w:-ok}" ok
_db1_w=""; for _db1_a in 0 65 abc 03 -1 ''; do _db1_X=(FELIX_TEST_JOBS="$_db1_a"); _db1_ref; [ "$_db1_v" = ok ] || _db1_w="$_db1_w [$_db1_a]$_db1_v"; done
is "D1: a FELIX_TEST_JOBS that is not a valid N (0 65 abc 03 -1 and empty) is refused the same way" "${_db1_w:-ok}" ok
_db1_p1="$(cd "$_db1_T/parts" && ls 0001-*.sh)"; _db1_p6="$(cd "$_db1_T/parts" && ls 0006-*.sh)"; _db1_p7="$(cd "$_db1_T/parts" && ls 0007-*.sh)"; _db1_p9="$(cd "$_db1_T/parts" && ls 9990-*.sh)"
_db1_refs p "--part 0010-nosuch.sh" "--part $_db1_p1" "--part $_db1_p6" "--part $_db1_p7" "--part $_db1_p9" "--part 0020-r2.sh 0010-r1.sh" "--part 0010-r1.sh 0030-r3.sh" \
   "--part 0010-r1.sh 0020-r2.sh 0030-r3.sh 0040-r4.sh 0050-r5.sh 0060-r6.sh 0070-r7.sh" "--part"
is "D1: --part refuses a name the driver does not source, a prelude part (0001, 0006 and 0007), 9990, names out of order or not contiguous, seven names and none" "${_db1_w:-ok}" ok
_db1_refs q "--part 0010-r1.sh -j 2" "-j 2 --part 0010-r1.sh" "--part 0010-r1.sh --record-assertions" "--part 0010-r1.sh --reuse"
is "D1: --part with -j, --record-assertions or --reuse is refused" "${_db1_w:-ok}" ok
_db1_run ref -j 3 --reuse --record-assertions
is "D1: --reuse with --record-assertions is refused with -j given, with the text it had" "$_db1_rc|$(sed -n 1p "$_db1_c/ref.err")" "2|tests/run: --reuse and --record-assertions do not go together"
# groups.tsv (D5): each rule refuses with its own line
_db1_gcase() {   # LABEL FORMAT ARG...: groups.tsv is the printf of the format; -j 2 must be refused
  local l="$1" f="$2"; shift 2
  printf "$f" "$@" > "$_db1_gp"; _db1_ref -j 2
  [ "$_db1_v" = ok ] || _db1_w="$_db1_w $l:$_db1_v"
  _db1_els="$_db1_els$_db1_el"$'\n'
}
_db1_p2="$(cd "$_db1_T/parts" && ls 0002-*.sh)"; _db1_w=""; _db1_els=""
_db1_gcase adjacent 'ga\t0010-r1.sh\ngb\t0030-r3.sh\ngb\t0040-r4.sh\nga\t0020-r2.sh\n'
_db1_gcase contiguous 'ga\t0010-r1.sh\nga\t0030-r3.sh\n'
_db1_gcase one-member 'ga\t0010-r1.sh\n'
_db1_gcase two-groups 'ga\t0010-r1.sh\nga\t0020-r2.sh\ngb\t0020-r2.sh\ngb\t0030-r3.sh\n'
_db1_gcase prelude 'ga\t%s\nga\t%s\n' "$_db1_p1" "$_db1_p2"
_db1_five="$_db1_els"; _db1_els=""
_db1_gcase seven 'ga\t0010-r1.sh\nga\t0020-r2.sh\nga\t0030-r3.sh\nga\t0040-r4.sh\nga\t0050-r5.sh\nga\t0060-r6.sh\nga\t0070-r7.sh\n'
_db1_gcase last 'ga\t0070-r7.sh\nga\t%s\n' "$_db1_p9"
_db1_gcase no-tab 'ga 0010-r1.sh\nga 0020-r2.sh\n'
is "D5: a groups.tsv whose lines for a group are not adjacent, whose members are not contiguous or number one or seven, that puts a part in two groups, or that names 0001, 0002 or 9990, is refused as D1 says, and so is a line with no tab" "${_db1_w:-ok}" ok
is "D5: the refusals name the rule: five different rules give five different lines" "$(printf '%s' "$_db1_five" | LC_ALL=C sort -u | wc -l | tr -d ' ')" 5
rm -f "$_db1_gp"; _db1_ref -j 2; _db1_w="$_db1_v"
printf 'ga\t0010-r1.sh\nga\t0020-r2.sh\n' > "$_db1_gp"; chmod 000 "$_db1_gp"
if [ -r "$_db1_gp" ]; then _db1_w2=skip; else _db1_ref -j 2; _db1_w2="$_db1_v"; fi
chmod 644 "$_db1_gp"; rm -f "$_db1_gp"; mkdir "$_db1_gp"; _db1_ref -j 2; _db1_w3="$_db1_v"; rmdir "$_db1_gp"
is "D1: with N above 1 a groups.tsv that is missing, or a directory, is refused as D1 says" "$_db1_w $_db1_w3" "ok ok"
if [ "$_db1_w2" = skip ]; then skip "D1: with N above 1 an unreadable groups.tsv is refused as D1 says" "a mode 000 file is still readable by this user"
else is "D1: with N above 1 an unreadable groups.tsv is refused as D1 says" "$_db1_w2" ok; fi
printf '# a comment\nga\t0010-r1.sh\nga\t0020-r2.sh\n# another\n' > "$_db1_gp"; _db1_acc -j 2
is "D5: a groups.tsv with comment lines and one valid group is accepted" "$_db1_v" ok
printf 'ga\t0010-r1.sh\n' > "$_db1_gp"; _db1_acc -j 1; _db1_w="$_db1_v"; rm -f "$_db1_gp"; _db1_acc -j 1
is "D1: -j 1 does not read groups.tsv: a broken one and a missing one change nothing" "$_db1_w $_db1_v" "ok ok"
rm -rf "$DB1/n/ref"

# ---- what the suite's own text says (D1, D3, D5, R9)
_db1_n=_suite_; _db1_n="${_db1_n}jobs"
_db1_jobs() {   # the places outside 0001 that name the jobs variable other than in an expansion, file:line
  local f
  while IFS= read -r f; do
    case "${f##*/}" in 0001-*) continue ;; esac
    LC_ALL=C awk -v n="$_db1_n" -v f="${f##*/}" '{ l = $0; gsub("[$][{]?" n, "", l); if (index(l, n)) printf "%s:%s ", f, FNR }' "$f"
  done < <(_suite_files)
}
_db1_x="$(_db1_jobs)"
is "D1: no file of the suite other than 0001 names the jobs variable except in a \$ or \${ expansion" "$_db1_x" ""
# the first line of code (a comment, whole or trailing, is none) that assigns the variable, and the first that makes the temporary directory
_db1_jc() { LC_ALL=C awk -v n="$_db1_n" '{ l = $0; sub(/^[ \t]*#.*/, "", l); sub(/[ \t]#.*/, "", l); gsub("[$][{]?" n, "", l) }
  !a && index(l, n "=") { a = FNR } !t && index(l, "mktemp -d") { t = FNR } END { print (a && t && a < t) ? "before" : "assigned at " a + 0 ", mktemp at " t + 0 }'; }
is "D1: and 0001 assigns it, at its head and in code and not in a comment, before it makes \$TMP" "$(_db1_jc < "$HERE"/parts/0001-*.sh)" "before"
printf '# %s=1 in a comment\nmktemp -d\n%s=1 # and here\n' "$_db1_n" "$_db1_n" > "$DB1/jc.sh"
is "D1: that check reads an assignment after the temporary directory as after, whatever the comments say (control)" "$(_db1_jc < "$DB1/jc.sh")" "assigned at 3, mktemp at 2"
_db1_pre=("part's prelude failed: " "part did not finish: " "part ended without its mark: " "part process ended with status " "part failed more than it printed: " "part printed a line the runner owns: " "part left the shell changed for the parts after it: ")
_db1_pfx() {   # MANIFEST: the runner-failure prefixes some name in it starts with, one a line
  local p; for p in "${_db1_pre[@]}"; do LC_ALL=C awk -v p="$p" '{ i = index($0, "\t"); if (i && index(substr($0, i + 1), p) == 1) { print p; exit } }' "$1"; done
}
for _db1_p in "${_db1_pre[@]}"; do printf '1\t%sX\n' "$_db1_p"; done > "$DB1/planted.tsv"
is "D3: the check for runner-failure prefixes in a manifest reads seven planted names as seven hits (control)" "$(_db1_pfx "$DB1/planted.tsv" | wc -l | tr -d ' ')" 7
is "D3: no name in the manifest starts with one of the runner's seven failure prefixes" "$(_db1_pfx "$HERE/assertions.tsv" | wc -l | tr -d ' ')" 0
_db1_rg="$HERE/groups.tsv"; _db1_ib=""
for _db1_a in 0900 0910 0920 0930 0940; do
  _db1_f="$(cd "$HERE/parts" && ls "$_db1_a"-*.sh 2>/dev/null | sed -n 1p)"
  _db1_ib="$_db1_ib$(awk -F'\t' -v p="$_db1_f" '/^#/ { next } $2 == p { print $1; exit }' "$_db1_rg" 2>/dev/null) "
done
is "D5: the tree's own groups.tsv puts 0900, 0910, 0920, 0930 and 0940 in one group" \
   "$(set -- $_db1_ib; a="${1:-}"; n=$#; for x in "$@"; do [ "$x" = "$a" ] || n=0; done; echo "$n parts in one group")" "5 parts in one group"
is "D5: and that group is ib" "${_db1_ib%% *}" ib
# R17: 1100, 1110 and 1120 hand the reach fixture on from one to the next, so they are a second group, rx
_db1_rx=""
for _db1_a in 1100 1110 1120; do
  _db1_f="$(cd "$HERE/parts" && ls "$_db1_a"-*.sh 2>/dev/null | sed -n 1p)"
  _db1_rx="$_db1_rx$(awk -F'\t' -v p="$_db1_f" '/^#/ { next } $2 == p { print $1; exit }' "$_db1_rg" 2>/dev/null) "
done
is "R17: the tree's own groups.tsv puts 1100, 1110 and 1120 in one group, and that group is rx, a second one beside ib" \
   "$(set -- $_db1_rx; a="${1:-}"; n=$#; for x in "$@"; do [ "$x" = "$a" ] || n=0; done; echo "$n parts in group ${a:-none}")" "3 parts in group rx"
# R40: 0200 and 0201 share _gp_rec0 (the suite's refusal record's length), so they are a group, gp; 0810 to 0850 share the audit fixture's stub
# log and snapshots, so they are a group, au. Both are found in the tree's groups.tsv in the shape of ib's and rx's checks above.
_db1_gpr=""
for _db1_a in 0200 0201; do
  _db1_f="$(cd "$HERE/parts" && ls "$_db1_a"-*.sh 2>/dev/null | sed -n 1p)"
  _db1_gpr="$_db1_gpr$(awk -F'\t' -v p="$_db1_f" '/^#/ { next } $2 == p { print $1; exit }' "$_db1_rg" 2>/dev/null) "
done
is "R40: the tree's own groups.tsv puts 0200 and 0201 in one group, and that group is gp" \
   "$(set -- $_db1_gpr; a="${1:-}"; n=$#; for x in "$@"; do [ "$x" = "$a" ] || n=0; done; echo "$n parts in group ${a:-none}")" "2 parts in group gp"
_db1_aur=""
for _db1_a in 0810 0820 0830 0840 0850; do
  _db1_f="$(cd "$HERE/parts" && ls "$_db1_a"-*.sh 2>/dev/null | sed -n 1p)"
  _db1_aur="$_db1_aur$(awk -F'\t' -v p="$_db1_f" '/^#/ { next } $2 == p { print $1; exit }' "$_db1_rg" 2>/dev/null) "
done
is "R40: and it puts 0810, 0820, 0830, 0840 and 0850 in one group, and that group is au, a third one beside ib and rx" \
   "$(set -- $_db1_aur; a="${1:-}"; n=$#; for x in "$@"; do [ "$x" = "$a" ] || n=0; done; echo "$n parts in group ${a:-none}")" "5 parts in group au"
mkdir -p "$DB1/pp/real"
while IFS= read -r _db1_f; do [ -f "$HERE/parts/$_db1_f" ] && printf 'ok "djx stand-in %s"\n' "$_db1_f" > "$DB1/pp/real/$_db1_f"
done < <(awk -F'\t' '!/^#/ && NF >= 2 { print $2 }' "$_db1_rg" 2>/dev/null | LC_ALL=C sort -u)
if _db1_new real "$_db1_rg" - "$DB1/pp/real"/*.sh; then
  _db1_run real -j 2; is "D5: the tree's own groups.tsv is accepted by the driver, with stand-ins for the parts it names" "$_db1_rc $(awk 'END { print NR }' "$_db1_c/real.err")" "0 0"
else bad "D5: the tree's own groups.tsv is accepted by the driver, with stand-ins for the parts it names" "no copy: is there an engine/harness/tests/groups.tsv naming parts of this suite?"; fi
rm -rf "$DB1/n/real"
# R9: the three yellow rows with no confine, read from the tree's risk.tsv (static: the verifier stops at these files whatever their change)
_db1_rk="$REAL_HARNESS/../../projects/felix/risk.tsv"
for _db1_a in '^engine/harness/tests/groups\.tsv$' '^engine/harness/tests/parts/0007-the-parallel-runner\.sh$' '^engine/harness/tests/(red|receipt\.sh)$'; do
  is "R9: projects/felix/risk.tsv holds one yellow verifier row, with no confine, for $_db1_a" \
     "$(P="$_db1_a" LC_ALL=C awk -F'\t' '$1 == "yellow" && $2 == "path" && $3 == ENVIRON["P"] && $5 == "verifier" && NF == 5 { n++ } END { print n + 0 }' "$_db1_rk" 2>/dev/null)" 1
done

# ---- a group runs as one process (D2, D5): A and B each write a file below $TMP, C counts them
mkdir -p "$DB1/pp/grp"
printf '%s\n' 'printf "\ndjx-sec 0010-ga.sh\n"' 'printf "djx-jobs:%s\n" "${FELIX_TEST_JOBS-unset}"' \
  'mkdir -p "$TMP/djx-g"; : > "$TMP/djx-g/a"; printf "%s\n" "$$" > "$DJX_DIR/pid.a"' > "$DB1/pp/grp/0010-ga.sh"
printf '%s\n' 'printf "\ndjx-sec 0020-gb.sh\n"' 'mkdir -p "$TMP/djx-g"; : > "$TMP/djx-g/b"; printf "%s\n" "$$" > "$DJX_DIR/pid.b"' > "$DB1/pp/grp/0020-gb.sh"
printf '%s\n' 'printf "\ndjx-sec 0030-gc.sh\n"' 'printf "%s\n" "$$" > "$DJX_DIR/pid.c"' 'djx_n="$(ls "$TMP/djx-g" 2>/dev/null | wc -l | tr -d " ")"' \
  '[ "$djx_n" = 2 ] && ok "djx group C sees the files of A and B" || bad "djx group C sees the files of A and B" "the directory holds $djx_n files"; unset djx_n' > "$DB1/pp/grp/0030-gc.sh"
printf 'grp\t0010-ga.sh\ngrp\t0020-gb.sh\ngrp\t0030-gc.sh\n' > "$DB1/g-grp.tsv"
printf '\n# a comment\n\ngrp\t0010-ga.sh\n\ngrp\t0020-gb.sh\n\n\ngrp\t0030-gc.sh\n\n' > "$DB1/g-grpb.tsv"
_db1_pids() { cat "$_db1_c"/pid.? 2>/dev/null | LC_ALL=C sort -u | wc -l | tr -d ' '; }
_db1_gc="  ok    djx group C sees the files of A and B"; _db1_gf="  FAIL  djx group C sees the files of A and B"
_db1_new grp "$DB1/g-grp.tsv" - "$DB1/pp/grp"/*.sh
rm -f "$_db1_c"/pid.?; _db1_E=(FELIX_TEST_JOBS=2); _db1_run g1 -j 3
is "D2: a group runs as one process: with A, B and C in a group, -j 3 passes C, and the three parts had one process id; the FELIX_TEST_JOBS beside -j reaches no part" \
   "$_db1_rc $(_db1_line "$_db1_c/g1.out" "$_db1_gc") $(_db1_pids) $(_db1_last g1 | grep -c ' (counted from lines)$') $(_db1_line "$_db1_c/g1.out" djx-jobs:unset)" "0 1 1 1 1"
is "D4: and the durations name the group once, and not its members" "$(awk -F'\t' '{ print $2 }' "$_db1_F/.git/felix-suite-durations" 2>/dev/null | tr '\n' ' ')" "grp "
cp "$DB1/g-grpb.tsv" "$_db1_T/groups.tsv"; rm -f "$_db1_c"/pid.?; _db1_run g5 -j 3
is "R9: a groups.tsv with empty lines among its members gives the same group: C passes, the three parts had one process id, the durations name the group once" \
   "$_db1_rc $(_db1_line "$_db1_c/g5.out" "$_db1_gc") $(_db1_pids) $(awk -F'\t' '{ print $2 }' "$_db1_F/.git/felix-suite-durations" 2>/dev/null | tr '\n' ' ')" "0 1 1 grp "
cp "$DB1/g-empty.tsv" "$_db1_T/groups.tsv"; rm -f "$_db1_c"/pid.?; _db1_run g2 -j 3
is "D2: with no groups line the same three parts are three units: -j 3 fails C, in three processes" \
   "$_db1_rc $(_db1_line "$_db1_c/g2.out" "$_db1_gf") $(_db1_pids)" "1 1 3"
rm -f "$_db1_c"/pid.?; _db1_E=(FELIX_TEST_JOBS=3); _db1_run g3
is "D1: FELIX_TEST_JOBS=3 with no -j makes a -j 3 run (C fails), and no part sees the variable" \
   "$_db1_rc $(_db1_line "$_db1_c/g3.out" "$_db1_gf") $(_db1_line "$_db1_c/g3.out" djx-jobs:unset)" "1 1 1"
cp "$DB1/g-grp.tsv" "$_db1_T/groups.tsv"; _db1_E=(FELIX_TEST_JOBS=3); _db1_run g4 -j 1
is "D1: and -j 1 beats it: C passes, and no part sees the variable here either" "$_db1_rc $(_db1_line "$_db1_c/g4.out" "$_db1_gc") $(_db1_line "$_db1_c/g4.out" djx-jobs:unset)" "0 1 1"
rm -rf "$DB1/n/grp"
_db1_new grr --red "$DB1/g-empty.tsv" - "$DB1/pp/grp"/*.sh; cp "$DB1/g-grp.tsv" "$_db1_T/groups.tsv"; _db1_run gr -j 3 --record-assertions
case "$_db1_rc|$(_db1_redrows)" in 0\|*'run'$'\t'0$'\t'*) _db1_x=ok ;; *) _db1_x="exit $_db1_rc, red.tsv $(_db1_redrows)" ;; esac
is "D4: red's suite takes this tree's groups.tsv, not the base's: with the group only in the working tree red.tsv counts no failure, and no process is left" "$_db1_x $_db1_cl" "ok ok"
rm -rf "$DB1/n/grr"

# ---- red by hand (R10, D4): it takes FELIX_TEST_JOBS and FELIX_TEST_RED_JOBS out of its environment, and runs its suite -j N only for a valid FELIX_TEST_RED_JOBS
_db1_rbh() {   # CASE LABEL ENV...: red with ENV in the copy CASE (made by the caller); _db1_x is how many processes ran its three parts, and what red.tsv holds
  local l="$1"; shift
  rm -f "$_db1_c/redpids"; _db1_prog=red; _db1_E=("$@"); _db1_run "$l"; _db1_prog=run
  _db1_x="$(LC_ALL=C sort -u "$_db1_c/redpids" 2>/dev/null | wc -l | tr -d ' ') $(_db1_cnts) $_db1_cl"
}
_db1_new rh --red "$DB1/g-empty.tsv" "$DB1/man.tsv" "$DB1/pp/std"/*.sh
_db1_rbh rh1 FELIX_TEST_JOBS=3;  is "R10: red by hand with FELIX_TEST_JOBS=3 runs its suite serially: one process ran the three parts, and red.tsv counts" "$_db1_x" "1 counts ok"
_db1_rbh rh2 FELIX_TEST_JOBS=abc FELIX_TEST_RED_JOBS=abc
is "R10: with FELIX_TEST_JOBS=abc and an invalid FELIX_TEST_RED_JOBS red's suite does not refuse and runs serially" "$_db1_x" "1 counts ok"
_db1_rbh rh3 FELIX_TEST_JOBS=abc FELIX_TEST_RED_JOBS=2
is "R10: and with a valid FELIX_TEST_RED_JOBS=2 its suite runs -j 2: the three parts ran in three processes, whatever FELIX_TEST_JOBS says" "$_db1_x" "3 counts ok"
rm -rf "$DB1/n/rh"
printf '1\tdjx group C sees the files of A and B\n' > "$DB1/man-grp.tsv"
_db1_new rg --red "$DB1/g-grp.tsv" "$DB1/man-grp.tsv" "$DB1/pp/grp"/*.sh; _db1_rbh rg1 FELIX_TEST_RED_JOBS=3
is "D4: red by hand over a base that has a groups.tsv and a tree that has too runs its suite -j 3 with the group, so C passes and red.tsv counts no failure (control)" "$_db1_x" "0 counts ok"
rm -f "$_db1_T/groups.tsv"; _db1_rbh rg2 FELIX_TEST_RED_JOBS=3
is "D4: and over a base that has one and a tree that has none, red removes the base's: its -j suite refuses, and red.tsv holds the rows base - - - and run - - -" \
   "$(_db1_redrows) $_db1_cl" "$(printf 'base\t-\t-\t-|run\t-\t-\t-|') ok"
rm -rf "$DB1/n/rg"

# ---- signals (D6): what a unit starts with, and how a run ends
cat > "$DB1/sig.pl" <<'DB1SIG'
print "djx-sig:", join(",", map { $_ . "=" . ((defined $SIG{$_} && length $SIG{$_}) ? $SIG{$_} : "DEFAULT") } qw(INT QUIT TERM HUP)), "\n";
DB1SIG
cat > "$DB1/gc.pl" <<'DB1GC'
# gc.pl PIDFILE GCFILE ID MODE: ignores TERM; with MODE 1, forks a sleeping grandchild every 50 ms once its parent is gone. A grandchild sleeps
# $DJX_LIFE (B + 30 s; R56: a leftover must outlive every look for it, and 30 s did not outlive R12's 30 s look after a loaded run's exit). R61: it and its
# grandchildren (sl.pl) end once the case's directory, PIDFILE's, is gone
my ($pf, $gf, $id, $mode) = @ARGV;
my $life = $ENV{DJX_LIFE} || 630;
(my $dir = $pf) =~ s{/[^/]*$}{};
$SIG{TERM} = 'IGNORE';
open(my $h, ">", $pf) or exit 3; print $h "$$\n"; close $h;
my $pp = getppid; my $n = 0;
while (-d $dir) {
  select(undef, undef, undef, 0.05);
  next unless $mode && getppid != $pp && $n < 60;
  $n++; my $k = fork;
  if (defined $k && !$k) { open(my $g, ">>", $gf); print $g "$$\n"; close $g; exec "perl", "$ENV{DJX_PL}/sl.pl", $dir, $life, $id, "gc"; exit 1 }
}
DB1GC
_db1_mk sig <<'X'
printf '\ndjx-sec 0020-pb.sh\n'
perl "$DJX_PL/sig.pl"
ok "djx sig"
X
_db1_new sig "$DB1/g-empty.tsv" - "$DB1/pp/sig"/*.sh
for _db1_m in "DEFAULT DEFAULT" "IGNORE IGNORE" "IGNORE DEFAULT" "DEFAULT IGNORE"; do
  _db1_i="${_db1_m% *}"; _db1_q="${_db1_m#* }"
  _db1_INT="$_db1_i"; _db1_QUIT="$_db1_q"; _db1_run s3 -j 3
  _db1_x="$(grep '^djx-sig:' "$_db1_c/s3.out" | tr '\n' ' ')"; _db1_y="$(_db1_last s3 | grep -c ' (counted from lines)$')"
  _db1_INT="$_db1_i"; _db1_QUIT="$_db1_q"; _db1_run s1 -j 1
  _db1_z="$(grep '^djx-sig:' "$_db1_c/s1.out" | tr '\n' ' ')"
  is "D6: a -j 1 run's part sees INT $_db1_i and QUIT $_db1_q as its parent had them (control)" "$([ "${_db1_z#djx-sig:INT=$_db1_i,QUIT=$_db1_q,}" != "$_db1_z" ] && echo yes || echo "no [$_db1_z]")" yes
  is "D6: a -j 3 run's unit reports the same four dispositions as a -j 1 run's part, from a parent with INT $_db1_i and QUIT $_db1_q" \
     "$_db1_y $([ "$_db1_x" = "$_db1_z" ] && echo same || echo "differ [$_db1_x] [$_db1_z]")" "1 same"
done
rm -rf "$DB1/n/sig"
_db1_key()    { printf '%s' "${_db1_c#/private}/f/engine/harness/tests/run"; }
_db1_up()     { ls "$_db1_c"/up.* >/dev/null 2>&1; }
_db1_pe()     { ls "$_db1_c"/prelude-end.* >/dev/null 2>&1; }
# R45: a holder of the current case is up: a live perl whose command line holds " --part " and this case's copy
_db1_hup()    { [ -n "$(ps -A -ww -o stat= -o command= 2>/dev/null | K="${_db1_c#/private}/f/" LC_ALL=C awk '$1 !~ /^Z/ && $2 ~ /perl/ && index($0, ENVIRON["K"]) && index($0, " --part ") { print "up"; exit }')" ]; }
_db1_plantpe() { local f; for f in "$_db1_T"/parts/0006-*.sh; do printf '\n: > "%s/prelude-end.$$"\n' "$_db1_c" >> "$f"; done; }
_db1_noproc() { [ -z "$(_db1_ps "$(_db1_key)")" ]; }
_db1_unitps() { ps -A -o pid= -o command= 2>/dev/null | K="$(_db1_key)" LC_ALL=C awk 'index($0, ENVIRON["K"]) && index($0, " --part ") && $2 !~ /perl/ { printf "%s ", $1 }'; }
_db1_gone() {   # LABEL STATUS: "ok", or what a run that was interrupted left behind (R12 sends what it finds CONT and KILL)
  local l="$1" r=""
  [ "$_db1_rc" = "$2" ] || r="$r exit $_db1_rc, not $2;"
  [ "$(_db1_line "$_db1_c/$l.out" reached)" = 0 ] || r="$r reached was printed;"
  _db1_cl="$(_db1_clean)"; [ "$_db1_cl" = ok ] || r="$r $_db1_cl;"
  [ -z "$(_db1_slots "${_db1_td:-$_db1_tmp}")" ] || r="$r a slot was still held;"
  [ "$(_db1_rcpt)" = absent ] || r="$r a receipt was left;"
  [ "$_db1_ctl" = 1 ] || r="$r no positive control, so these absences say nothing;"
  printf '%s' "${r:-ok}"
}
_db1_intr() {   # CASE SIGNAL STATUS: a -j 3 run of pp/CASE, SIGNAL to the driver once a unit is up; the slot files must be the same ones afterwards
  local c="$1" s="$2" w="$3" r="" p g si
  _db1_new "$c-$s" "$DB1/g-empty.tsv" "$DB1/pman.tsv" "$DB1/pp/$c"/*.sh || { printf 'the copy could not be made'; return 0; }
  _db1_start i -j 3
  _db1_evt _db1_up || r=" no unit came up;"   # R56: a bound that lasts until the run's bound (was 30 s)
  sleep 0.5; si="$(_db1_si)"
  p="$(cat "$_db1_c/i.pid" 2>/dev/null)"; [ -z "$p" ] || kill -"$s" "$p" 2>/dev/null
  _db1_wait
  g="$(_db1_gone i "$w")"; [ "$g" != ok ] || g=""
  { [ -n "$si" ] && [ "$(_db1_si)" = "$si" ]; } || r="$r the slot files were [$si] and are [$(_db1_si)];"
  r="$r$g"; printf '%s' "${r:-ok}"
}
_db1_mk slp <<'X'
printf '\ndjx-sec 0020-pb.sh\n'
perl -e 'open(my $h, ">", $ARGV[0]); print $h "$$\n"; close $h; my $e = time + $ARGV[2]; sleep 1 while time < $e && -d $ARGV[3]' "$DJX_DIR/sl.pid" "$DJX_ID" "${DJX_LIFE:-630}" "$DJX_DIR" &
while [ ! -s "$DJX_DIR/sl.pid" ] && [ -d "$DJX_DIR" ]; do sleep 0.1; done
: > "$DJX_DIR/up.$$"
wait
X
_db1_mk ign <<'X'
printf '\ndjx-sec 0020-pb.sh\n'
perl "$DJX_PL/gc.pl" "$DJX_DIR/ign.pid" "$DJX_DIR/gc.pids" "$DJX_ID" 0 &
while [ ! -s "$DJX_DIR/ign.pid" ] && [ -d "$DJX_DIR" ]; do sleep 0.1; done
: > "$DJX_DIR/up.$$"
wait
X
_db1_mk gcx <<'X'
printf '\ndjx-sec 0020-pb.sh\n'
perl "$DJX_PL/gc.pl" "$DJX_DIR/ign.pid" "$DJX_DIR/gc.pids" "$DJX_ID" 1 &
while [ ! -s "$DJX_DIR/ign.pid" ] && [ -d "$DJX_DIR" ]; do sleep 0.1; done
: > "$DJX_DIR/up.$$"
wait
X
is "D6: TERM sent to the parent while units run: exit 143, no reached, no unit, holder, wrapper or child left running, no slot held, the slot files kept, no receipt" "$(_db1_intr slp TERM 143)" ok
is "D6: INT sent to a parent started with INT at its default: exit 130, with the same afterwards" "$(_db1_intr slp INT 130)" ok
is "D6: HUP sent to the parent, which the bounded runner starts with HUP at its default whatever its caller ignores: exit 129, with the same afterwards" "$(_db1_intr slp HUP 129)" ok
is "D6: a child a unit started with & that ignores TERM, and is moved to pid 1 when the unit dies, is gone once the parent has ended" "$(_db1_intr ign TERM 143)" ok
_db1_x="$(_db1_intr gcx TERM 143)"
if [ "$_db1_x" = ok ] && [ ! -s "$DB1/n/gcx-TERM/gc.pids" ]; then
  skip "D6: and a grandchild that child forks after the parent's TERM is gone once the parent has ended" "the child was stopped before it forked one, so there was none to find"
else is "D6: and a grandchild that child forks after the parent's TERM is gone once the parent has ended" "$_db1_x" ok; fi
rm -rf "$DB1/n/slp-TERM" "$DB1/n/slp-INT" "$DB1/n/slp-HUP" "$DB1/n/ign-TERM" "$DB1/n/gcx-TERM"

# ---- an interrupt while a holder waits, and the slots (D6): an outside process holds the lock of slot 0
rm -rf "$DB1/td-w"; mkdir -p "$DB1/td-w"; _db1_td="$DB1/td-w"
_db1_new hw "$DB1/g-empty.tsv" "$DB1/pman.tsv" "$DB1/pp/slp"/*.sh; _db1_plantpe
_db1_hold "$_db1_td/felix-suite-slots/0" "$((_db1_lim + 30))"; _db1_si0="$(_db1_si)"
_db1_E=(FELIX_TEST_SLOTS=1); _db1_start hw -j 2
# R58, a watch: 20 s (was 2 s) from the first listing that shows a waiting holder, the event after which a holder that starts its unit without the slot's lock
# (D6's flock) would act. That build forks and execs the unit inside it, so its floor is 20 s. It looks every 0.2 s for a unit process or the unit's marker and ends
# at the first, which fails the name; on D's build it waits its whole 20 s. No other check of this name catches that build: a unit it started may be ended by the
# TERM before it writes its marker. The waits before it are bounds that last until the run's bound (was 30 s)
_db1_held() { _db1_wf="$(_db1_unitps)"; _db1_up && _db1_wf="$_db1_wf marker"; [ -n "$_db1_wf" ]; }
_db1_heldu() { _db1_wf="$(_db1_unitps)"; [ -n "$_db1_wf" ]; }
_db1_evt _db1_pe; _db1_nh=""; _db1_evt _db1_hup || _db1_nh=" no holder waited for the slot"; _db1_wf=""; _db1_watch 20 held _db1_held
_db1_x="$_db1_wf$_db1_nh"
# 3 s: a watch for a holder left behind that takes the freed slot. R58 lets it stay short: the same name's R12 drain ($_db1_cl, 30 s for the run's group to empty)
# and its look for any process of the copy (_db1_noproc) catch that build, whose holder stays in the group and carries the copy's path, slot or no slot
kill -TERM "$(cat "$_db1_c/hw.pid" 2>/dev/null)" 2>/dev/null; _db1_wait; _db1_unhold; sleep 3; _db1_ml margin hw/freed T 3000 ms none; _db1_sweep
is "D6: with FELIX_TEST_SLOTS=1 and the slot's lock held elsewhere, TERM to the parent starts no unit, neither before it nor after the parent has exited, which is 143, and the slot file is the one that was locked" \
   "$_db1_rc|${_db1_x}|$(_db1_up && echo started)|$(_db1_unitps)|$(_db1_noproc && echo none || echo left)|$([ -n "$_db1_si0" ] && [ "$(_db1_si)" = "$_db1_si0" ] && echo same-inode || echo "[$_db1_si0] now [$(_db1_si)]") $_db1_cl" "143||||none|same-inode ok"
rm -rf "$DB1/n/hw" "$DB1/td-w"
rm -rf "$DB1/td-k"; mkdir -p "$DB1/td-k"; _db1_td="$DB1/td-k"
_db1_new hk "$DB1/g-empty.tsv" "$DB1/pman.tsv" "$DB1/pp/slp"/*.sh; _db1_plantpe
_db1_hold "$_db1_td/felix-suite-slots/0" "$((_db1_lim + 30))"; _db1_si0="$(_db1_si)"
_db1_E=(FELIX_TEST_SLOTS=1); _db1_start hk -j 2
_db1_evt _db1_pe; _db1_nh=""; _db1_evt _db1_hup || _db1_nh=" no holder waited for the slot"   # as in hw: bounds, then R58's 20 s watch from the holder (was 2 s)
_db1_wf=""; _db1_watch 20 held _db1_heldu; _db1_x="$_db1_wf$_db1_nh"
# R56, a margin: T = 20 s from the kill -9 to the start of the first listing that shows a unit. Inside it D's holder takes the slot at its next try (each second)
# and forks the unit, and the case takes ps listings, so the floor is 20 s. L: a build whose slot stays taken for 30 s after its holder dies (a mark the dead
# holder left, kept 30 s, where D6 has a lock the kernel frees at the death), whose unit comes 30 s or more after the kill: T = L - 10 s. The name is shown red
# against that build alone. A holder that retries only every 30 s is not claimed to fail it: its next try comes 30 s after its last, and load sets how far into
# that wait the kill comes, so the try can fall inside T. The poll ends at the unit, so T costs nothing on D's build. Was 2 s, below the floor. R61: it also ends
# once the run has exited, after one more look
_db1_unhold; _db1_t0="$(_db1_ms)"; _db1_y=""
while :; do _db1_t1="$(_db1_ms)"; _db1_y="$(_db1_unitps)"; [ -z "$_db1_y" ] || break; [ $((_db1_t1 - _db1_t0)) -lt 20000 ] || break
  kill -0 "$_db1_bg" 2>/dev/null || { _db1_t1="$(_db1_ms)"; _db1_y="$(_db1_unitps)"; break; }; sleep 0.05; done
_db1_ml margin hk/kill9 T 20000 ms "$([ -n "$_db1_y" ] && echo $((_db1_t1 - _db1_t0)) || echo none)"
kill -TERM "$(cat "$_db1_c/hk.pid" 2>/dev/null)" 2>/dev/null; _db1_wait; _db1_g="$(_db1_gone hk 143)"
is "D6: a slot whose holder was killed with kill -9 is free at once: no run --part process while it was held, one within 20 s of the kill, timed in milliseconds, on the same slot file, and nothing left behind" \
   "${_db1_x:+running while held [$_db1_x]}|$([ -n "$_db1_y" ] && [ $((_db1_t1 - _db1_t0)) -lt 20000 ] && echo within-20s || echo "after $((_db1_t1 - _db1_t0)) ms") $([ -n "$_db1_si0" ] && [ "$(_db1_si)" = "$_db1_si0" ] && echo same-inode || echo "[$_db1_si0] now [$(_db1_si)]") $_db1_g" "|within-20s same-inode ok"
rm -rf "$DB1/n/hk" "$DB1/td-k"
mkdir -p "$DB1/pp/note"
for _db1_a in a:0010 b:0020; do _db1_n="${_db1_a#*:}-n${_db1_a%:*}.sh"
  printf 'printf "\\ndjx-sec %s\\n"\nok "djx note %s"\nsleep 2\n' "$_db1_n" "$_db1_n" > "$DB1/pp/note/$_db1_n"; done
printf '1\tdjx note 0010-na.sh\n1\tdjx note 0020-nb.sh\n' > "$DB1/man-note.tsv"
rm -rf "$DB1/td-n"; mkdir -p "$DB1/td-n"; _db1_td="$DB1/td-n"
_db1_new nt "$DB1/g-empty.tsv" "$DB1/man-note.tsv" "$DB1/pp/note"/*.sh; _db1_E=(FELIX_TEST_SLOTS=1); _db1_run nt -j 2
_db1_x="$(LC_ALL=C awk '/^  note  [^ ]+ waited [0123456789]+ s for a slot$/ { n++; ln = NR; u = $2 } /^  note  / { all++ }
  index($0, "djx-sec ") == 1 { sec[substr($0, 9)] = NR }
  END { print n + 0, all + 0, (u in sec && sec[u] > ln && sec[u] - ln <= 2) ? "head" : "elsewhere" }' "$_db1_c/nt.out")"
is "R7: with one slot and two units and a manifest that lists only the stubs, so that the tail prints its own note too, the unit that waited gets exactly one line of the wait note's shape, at the head of its section" "$_db1_rc $_db1_x" "0 1 2 head"
is "R7: and the tail's note, UNIT-less, is told from it by that shape: it says how many assertions ran that the manifest does not list" "$(_db1_cnt "$_db1_c/nt.out" '  note  ') $(grep -cE '^  note  [0123456789]+ assertion\(s\) ran that the manifest does not list\.$' "$_db1_c/nt.out")" "2 1"
_db1_x="$(grep '^  ok    ' "$_db1_c/nt.out" | grep -vcF 'every assertion in the manifest was reached')"; _db1_y="$(_db1_last nt | awk '{ print $1 }')"
is "D3: and a note is not an assertion: the summary counts as many passes as the log has ok lines, the tail's own line about the manifest apart" "$([ "$_db1_x" = "$_db1_y" ] && echo same || echo "$_db1_x lines, summary $_db1_y")" same
rm -rf "$DB1/n/nt" "$DB1/td-n"; _db1_td=""

# ---- the slots cap the machine (D6): two -j 4 runs at once, units of 3 s each write their start and end
# span.pl SPANFILE: a unit's span, 3 s. With DJX_SPANW=W (the control) it writes a line to SPANFILE.begun first and holds its span until four lines are
# there, or W s, and 1 s more. R56: the control asked 3 s spans of two loaded runs to meet four at a time, which the preludes' spread under load can
# deny on D's build; its spans now meet by construction wherever four units run at once, and the wait is a bound, the run's bound. R61: the wait also ends once
# the unit's case directory (DJX_DIR) is gone
cat > "$DB1/span.pl" <<'DB1SP'
use Time::HiRes qw(time sleep);
my $s = time; my $w = $ENV{DJX_SPANW} || 0; my $d = $ENV{DJX_DIR} || "/";
if ($w) {
  if (open(my $b, ">>", "$ARGV[0].begun")) { print $b "$$\n"; close $b }
  while (time < $s + $w && -d $d) { my $n = 0; if (open(my $b, "<", "$ARGV[0].begun")) { $n++ while <$b>; close $b } last if $n >= 4; sleep 0.1 }
  sleep 1;
} else { sleep 3 }
my $e = time;
open(my $h, ">>", $ARGV[0]) or exit 1; printf $h "%.3f %.3f\n", $s, $e; close $h;
DB1SP
mkdir -p "$DB1/pp/span"
for _db1_a in a:0010 b:0020 c:0030 d:0040; do _db1_n="${_db1_a#*:}-s${_db1_a%:*}.sh"
  printf 'printf "\\ndjx-sec %s\\n"\nperl "$DJX_PL/span.pl" "$DJX_SPAN"\nok "djx span %s"\n' "$_db1_n" "$_db1_n" > "$DB1/pp/span/$_db1_n"; done
_db1_sel() { _db1_c="$DB1/n/$1"; _db1_F="$_db1_c/f"; _db1_T="$_db1_F/engine/harness/tests"; _db1_tmp="$_db1_c/tmp"; }
_db1_ov() { LC_ALL=C awk '{ s[NR] = $1; e[NR] = $2 } END { m = 0; for (i = 1; i <= NR; i++) { c = 0; for (j = 1; j <= NR; j++) if (s[j] <= s[i] && s[i] < e[j]) c++; if (c > m) m = c } print m, NR }' "$1" 2>/dev/null; }
_db1_uc() {   # how many units (bash run --part, not the subshells a unit forks, which carry the same command line) the two copies have now
  ps -A -o pid= -o ppid= -o command= 2>/dev/null | A="${DB1#/private}/n/capA/f/" B="${DB1#/private}/n/capB/f/" LC_ALL=C awk '
    (index($0, ENVIRON["A"]) || index($0, ENVIRON["B"])) && index($0, " --part ") && $3 !~ /perl/ { u[$1] = 1; pp[$1] = $2 }
    END { for (p in u) if (!(pp[p] in u)) n++; print n + 0 }'
}
_db1_cap() {   # TMPDIR SLOTS SPANFILE [W]: both runs share TMPDIR; _db1_ovr is "most units at once by their spans, units, most unit processes seen at once"; W is DJX_SPANW
  local td="$1" k="$2" f="$3" w="${4:-}" ba bb pk=0 n
  rm -rf "$td"; rm -f "$f" "$f.begun"; mkdir -p "$td"; _db1_td="$td"
  _db1_new capA "$DB1/g-empty.tsv" - "$DB1/pp/span"/*.sh; _db1_new capB "$DB1/g-empty.tsv" - "$DB1/pp/span"/*.sh
  _db1_sel capA; _db1_pf=(); _db1_E=(FELIX_TEST_SLOTS="$k" DJX_SPAN="$f" ${w:+DJX_SPANW=$w}); _db1_start a -j 4; ba="$_db1_bg"
  _db1_sel capB; _db1_E=(FELIX_TEST_SLOTS="$k" DJX_SPAN="$f" ${w:+DJX_SPANW=$w}); _db1_start b -j 4; bb="$_db1_bg"
  while kill -0 "$ba" 2>/dev/null || kill -0 "$bb" 2>/dev/null; do n="$(_db1_uc)"; [ "$n" -le "$pk" ] || pk="$n"; sleep 0.2; done
  _db1_bg="$ba"; _db1_wait; _db1_bg="$bb"; _db1_wait; _db1_sweep
  _db1_ovr="$(_db1_ov "$f") $pk"; _db1_td=""; rm -rf "$DB1/n/capA" "$DB1/n/capB" "$td"
}
_db1_cap "$DB1/td-c3" 3 "$DB1/span3"
is "D6: with FELIX_TEST_SLOTS=3, two -j 4 runs of eight 3 s units never have more than three at once by their spans, and reach three at once by their processes" \
   "$([ "${_db1_ovr%% *}" -le 3 ] 2>/dev/null && echo le3 || echo "$_db1_ovr") ${_db1_ovr#* } $_db1_cl" "le3 8 3 ok"
_db1_cap "$DB1/td-c8" 8 "$DB1/span8" "$_db1_lim"
is "D6: and with FELIX_TEST_SLOTS=8 two runs of the same eight units, each holding its span until four have begun, do overlap more than three units by their spans (control for the count above)" \
   "$([ "${_db1_ovr%% *}" -gt 3 ] 2>/dev/null && echo more || echo "$_db1_ovr")" more

# ---- slots that cannot be taken (D6): the parent refuses with exit 2 and one line, and starts no unit
_db1_srv() {   # sets _db1_v: ok when the -j 2 run in the current copy was refused, exit 2, one stderr line, and no unit came up
  local r="" n
  _db1_run sr -j 2
  n="$(awk 'END { print NR }' "$_db1_c/sr.err")"
  [ "$_db1_rc" = 2 ] || r="$r exit $_db1_rc, not 2;"; [ "$n" = 1 ] || r="$r $n stderr lines, not 1;"
  ! _db1_up || r="$r a unit started;"
  _db1_v="${r:-ok}"
}
printf 'package Djflock;\nuse Errno qw(ENOLCK);\nBEGIN { *CORE::GLOBAL::flock = sub { $! = ENOLCK; return 0 } }\n1;\n' > "$DB1/Djflock.pm"
rm -rf "$DB1/td-f"; mkdir -p "$DB1/td-f"; _db1_td="$DB1/td-f"
_db1_new fl "$DB1/g-empty.tsv" - "$DB1/pp/slp"/*.sh; _db1_E=(PERL5OPT="-I$DB1 -MDjflock" FELIX_TEST_SLOTS=2); _db1_srv
is "D6: where flock fails with ENOLCK, and not with EWOULDBLOCK, the parent's one lock fails and the run is refused: exit 2, one stderr line, no unit" "$_db1_v" ok
rm -rf "$DB1/n/fl" "$DB1/td-f"
rm -rf "$DB1/td-d"; mkdir -p "$DB1/td-d/felix-suite-slots/0"; _db1_td="$DB1/td-d"
_db1_new nd "$DB1/g-empty.tsv" - "$DB1/pp/slp"/*.sh; _db1_E=(FELIX_TEST_SLOTS=2); _db1_srv
is "D6: a name under the slots directory that is not a regular file (a directory) makes a -j run refuse: exit 2, one stderr line, no unit" "$_db1_v" ok
rm -rf "$DB1/n/nd" "$DB1/td-d"
rm -rf "$DB1/td-m"; mkdir -p "$DB1/td-m/felix-suite-slots"; : > "$DB1/td-m/felix-suite-slots/0"; chmod 000 "$DB1/td-m/felix-suite-slots/0"; _db1_td="$DB1/td-m"
if [ -r "$DB1/td-m/felix-suite-slots/0" ]; then skip "D6: a slot file the parent cannot open makes a -j run refuse: exit 2, one stderr line, no unit" "a mode 000 file is still readable by this user"
else _db1_new nm "$DB1/g-empty.tsv" - "$DB1/pp/slp"/*.sh; _db1_E=(FELIX_TEST_SLOTS=2); _db1_srv
  is "D6: a slot file the parent cannot open makes a -j run refuse: exit 2, one stderr line, no unit" "$_db1_v" ok; fi
chmod 644 "$DB1/td-m/felix-suite-slots/0"; rm -rf "$DB1/n/nm" "$DB1/td-m"; _db1_td=""

# ---- the order units start in, and the durations file (D4, D6): seven units, -j 2; the unit named in DJX_SLEEPER holds its slot until all seven have started
mkdir -p "$DB1/pp/ord"
for _db1_a in 0010-oa.sh 0020-ob.sh 0030-oc.sh 0040-od.sh 0050-oe.sh 0060-of.sh 0070-og.sh; do
  printf 'printf "\\ndjx-sec %s\\n"\nprintf "%%s\\n" %s >> "$DJX_DIR/starts"\n' "$_db1_a" "$_db1_a" > "$DB1/pp/ord/$_db1_a"
  # R56: the sleeper's hold is a bound, the run's bound (3000 polls of 0.2 s; was 300, 60 s): six units one after another can take longer than 60 s on a loaded
  # machine, and once the sleeper let its slot go two units could start at once, in either order. R61: the hold also ends once the case's directory is gone
  printf '%s\n' 'if [ "${DJX_SLEEPER:-}" = '"$_db1_a"' ]; then _djx_i=0; while [ "$(wc -l < "$DJX_DIR/starts")" -lt 7 ] && [ "$_djx_i" -lt 3000 ] && [ -d "$DJX_DIR" ]; do sleep 0.2; _djx_i=$((_djx_i + 1)); done; unset _djx_i; fi' \
    "ok \"djx ord $_db1_a\"" >> "$DB1/pp/ord/$_db1_a"; done
_db1_new ord "$DB1/g-empty.tsv" - "$DB1/pp/ord"/*.sh
_db1_w="$DB1/hostile.witness"; rm -f "$_db1_w"
{ printf '2\t0010-oa.sh\n9\t0020-ob.sh\n9\t0060-of.sh\n99\t0070-og.sh\n'
  printf '7 0030-oc.sh\n08\t0040-od.sh\n'
  printf 'a[$(touch %s)]\t0050-oe.sh\n' "$_db1_w"
  printf '08\t0099-zz.sh\n-3\t0098-zz.sh\n\njunk\n1e3\t0096-zz.sh\n'; } > "$_db1_F/.git/felix-suite-durations"
rm -f "$_db1_c/starts"; _db1_E=(DJX_SLEEPER=0030-oc.sh); _db1_run o2 -j 2
_db1_x="$(sed -n '1,2p' "$_db1_c/starts" | LC_ALL=C sort | tr '\n' ' ')|$(sed -n '3,$p' "$_db1_c/starts" | tr '\n' ' ')"
is "D6: units start longest first by the durations file: those with no usable row first in driver order (the first two a pair started at once), then 99, then 9 and 9 in driver order, then 2" \
   "$_db1_rc $_db1_x $_db1_cl" "0 0030-oc.sh 0040-od.sh |0050-oe.sh 0070-og.sh 0020-ob.sh 0060-of.sh 0010-oa.sh  ok"
is "D4: rows with a bad seconds field (a leading zero), a space for the tab, a subscript, a non-unit name or no name are ignored: those units had no row, nothing in the file ran, and no arithmetic error was printed" \
   "$([ -e "$_db1_w" ] && echo ran || echo not-run) $(grep -c -E 'syntax error|arithmetic|invalid|bad substitution|unbound|value too great' "$_db1_c/o2.err" 2>/dev/null)" "not-run 0"
_db1_x="$(awk -F'\t' '$1 ~ /^(0|[123456789][0123456789]*)$/ { print $2 }' "$_db1_F/.git/felix-suite-durations" | LC_ALL=C sort | tr '\n' ' ')"
is "D4: the run writes the file whole at its end: one valid row for each of its seven units, and the old rows gone" "$_db1_x $(awk 'END { print NR }' "$_db1_F/.git/felix-suite-durations")" "0010-oa.sh 0020-ob.sh 0030-oc.sh 0040-od.sh 0050-oe.sh 0060-of.sh 0070-og.sh  7"
rm -f "$_db1_F/.git/felix-suite-durations" "$_db1_c/starts"; _db1_E=(DJX_SLEEPER=0010-oa.sh); _db1_run o3 -j 2
_db1_x="$(sed -n '1,2p' "$_db1_c/starts" | LC_ALL=C sort | tr '\n' ' ')|$(sed -n '3,$p' "$_db1_c/starts" | tr '\n' ' ')"
is "D6: with no durations file the order is the driver's: the first two at once, then the rest one after another" "$_db1_rc $_db1_x $_db1_cl" \
   "0 0010-oa.sh 0020-ob.sh |0030-oc.sh 0040-od.sh 0050-oe.sh 0060-of.sh 0070-og.sh  ok"
rm -rf "$DB1/n/ord"

# ---- part mode (D1, D2): by hand, and as the runner uses it
_db1_mk pm <<'X'
printf '\ndjx-sec 0020-pb.sh\n'
printf 'djx-rec:%s\n' "${FELIX_TEST_RECORD-unset}"
printf 'djx-pv:%s\n' "$(env | grep -c '^FELIX_TEST_PART_')"
ok "djx pm one"
bad "djx pm fails"
printf 'djx-no-newline'
X
_db1_new pm --red "$DB1/g-empty.tsv" "$DB1/man.tsv" "$DB1/pp/pm"/*.sh
_db1_run pm1 --part 0020-pb.sh 0030-pc.sh
_db1_x="$(grep '^@@' "$_db1_c/pm1.out" | tr '\n' '|')"
is "D2: --part by hand prints @@prelude-done, a @@member-done line for each member in order, and the mark naming the members, each on a line of its own" \
   "$_db1_x" "@@prelude-done|@@member-done 0020-pb.sh|@@member-done 0030-pc.sh|@@part-done 0020-pb.sh 0030-pc.sh|"
is "D2: it exits 0 whatever it counts as failed, and the mark is the last line" "$_db1_rc $(_db1_last pm1)" "0 @@part-done 0020-pb.sh 0030-pc.sh"
is "D2: a partial last line of a member is ended before the runner line, the part's own lines are printed, and both members see FELIX_TEST_RECORD as 0, the driver's own" \
   "$(_db1_line "$_db1_c/pm1.out" djx-no-newline) $(_db1_line "$_db1_c/pm1.out" '  FAIL  djx pm fails') $(_db1_line "$_db1_c/pm1.out" djx-rec:0) $(_db1_line "$_db1_c/pm1.out" djx-pv:0)" "1 1 2 1"
is "D2: the prelude's lines come before @@prelude-done and the first member's after it" \
   "$(LC_ALL=C awk '/^@@prelude-done$/ { pd = NR } /^  ok    / && !pd { pre++ } index($0, "djx-sec 0020-pb.sh") == 1 { s = NR } END { print (pre > 0 && pd && s > pd) ? "ordered" : "pre=" pre + 0 " pd=" pd + 0 " sec=" s + 0 }' "$_db1_c/pm1.out")" ordered
is "D2: it prints no reached and no summary, takes no receipt, starts no red run, leaves the manifest and writes no red.tsv, and leaves no process" \
   "$(_db1_line "$_db1_c/pm1.out" reached) $(grep -c -E '^[0123456789]+ passed, [0123456789]+ failed' "$_db1_c/pm1.out") $(_db1_rcpt) $(cmp -s "$DB1/man.tsv" "$_db1_T/assertions.tsv" && echo same || echo changed) $([ -e "$_db1_T/red.tsv" ] && echo red.tsv || echo no-red.tsv) $_db1_cl" \
   "0 0 absent same no-red.tsv ok"
_db1_E=(FELIX_TEST_PART_LOG="$_db1_c/pl.log" FELIX_TEST_PART_RAN="$_db1_c/pl.ran" FELIX_TEST_PART_END="$_db1_c/pl.end" FELIX_TEST_PART_RECORD=1)
_db1_run pm2 --part 0020-pb.sh 0030-pc.sh
is "D2: with the FELIX_TEST_PART_ files it writes the log, in order, with the runner lines in it and none on stdout, and exits 0" \
   "$_db1_rc $(grep '^@@' "$_db1_c/pl.log" 2>/dev/null | tr '\n' '|') $(grep -c '^@@' "$_db1_c/pm2.out")" \
   "0 @@prelude-done|@@member-done 0020-pb.sh|@@member-done 0030-pc.sh|@@part-done 0020-pb.sh 0030-pc.sh| 0"
is "D2: the ran file holds the names reached after @@prelude-done, and only those" "$(LC_ALL=C sort "$_db1_c/pl.ran" 2>/dev/null | tr '\n' '|')" "djx c skip|djx c1|djx pm fails|djx pm one|"
is "D2: it writes an end file, and with FELIX_TEST_PART_RECORD=1 it sets FELIX_TEST_RECORD=1 first (both members see it), and unsets the FELIX_TEST_PART_ variables once read" \
   "$([ -s "$_db1_c/pl.end" ] && echo end-file || echo none) $(_db1_line "$_db1_c/pl.log" djx-rec:1) $(_db1_line "$_db1_c/pl.log" djx-pv:0)" "end-file 2 1"
rm -rf "$DB1/n/pm"

# ---- every case ended every process it started (R12), and the part leaves the shell as it found it
is "R12: no run of this part left a process in its process group, stopped or running, after the 30 s it was given (the interrupt cases judge theirs in their own assertions)" "${_db1_leak:-none}" none
unset -f $(compgen -A function _db1_) 2>/dev/null
unset $(compgen -A variable _db1_) DB1 2>/dev/null
# <<< gate-friction-d-blind
