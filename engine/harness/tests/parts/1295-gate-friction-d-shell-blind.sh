# >>> gate-friction-d-shell-blind
printf '\ngate friction D: the shell a unit leaves for the parts after it (blind, revision 12)\n'
# Blind, written from contract D revision 9 alone (docs/2026-10-18-gate-friction-contract-d.md: D3, D8, R8, R12, R16, R24, R28), with R31 of revision 10, R38 of revision 11 and R41 and R42 (e) of revision 12 added. Nothing here was read off an
# implementation; tests/run is run, never read, in copies of this suite that _suite_copy_tree (part 0003) makes under $TMP, each with planted parts of
# this block's own. Every case points TMPDIR at a fixture directory, runs every inner run under a bounded runner that makes its own process group and
# resets HUP and TERM, and ends by asking that group to hold no live process, stopped or running (zombies aside), for 30 s; what is left is named,
# then sent CONT and KILL by pid. Nothing is killed by pattern: a sleeper a planted part leaves is ended by the pid it wrote down.
# The planted parts are one set, each doing one thing to the shell and then printing its own ok line. They are numbered so that the ones that spoil
# the shell for what follows (a closed descriptor, a disabled printf or enable, a removed EXIT trap) come last, so a -j 1 run reaches every one.
# Four kinds: x leaves the shell changed (the seventh failure under -j 3, none under -j 1); p passes; s is skipped; j is a part that is only judged
# under -j 3 and left out of the -j 1 run, since a function that forwards nothing (perl() { :; }) would break the parts after it there (R28); c is a
# part that only the -j 1 run holds, a control (a function that forwards, which R28 no longer counts as a case of the seventh failure).
# Names say the clause: R8 the first comparison, R16 what it was widened to, R24 every builtin's status, aliases and readonly functions, R28 the
# shadows that forward nothing, the watched variables, a trap removed and a group. Each change line is the one the contract gives, as written.
# R41: every nested run has a stand-in mktemp first on PATH (mk/mktemp): given no template argument it passes the same options and the template "$TMPDIR/tmp.XXXXXXXXXX" to the
# host's mktemp, so a nested run's $TMP is made below the case's fixture directory even on macOS, whose mktemp -d ignores TMPDIR, and it logs each path it made to mktemp.log.
# The closing assertions say that the log is not empty (the stand-in was reached) and that every path in it is under this part's own case directories.
# Revision 17 (R53, R55, R56, R57), by blind author B from the contract alone: (1) R53: hold.pl (the same text as part 1293's) waits, once hold.go exists, for the record run's
# failed mark (a regular file manifest.mark one directory below DIR/tmp, the TMPDIR the case gives its runs, whose first line is failed, polled every 0.1 s, B at most), writes hold.mark
# (the ms it first saw it) and only then waits C = 40 s; DJX_MLOG gains go-to-mark and mark-to-step-end (none when a file is missing); R46's verdict is unchanged. (2) R55: every run
# bound is _db5_lim = 600 s, the -j 3 runs (g3: the run of every part reached its old 150 s), the -j 1 run (was 100 s) and the record run, B (was 240 s), alike. (3) R56: the
# job part's sleeper, a hold whose life the unit's comparison must fall inside, lives B, 600 s (was 30 s), so its name says sleep 600; every other window stands (the report's table).
# Revision 18 (R58 to R62), by blind author B from the contract alone: (1) R60: _db5_atexit (atexit.pl, the same text as part 1293's) takes its two listings as before, 0.1 s apart, the first at
# once, but a process whose command line is the record run's own (_db5_cmd: its watcher, or a subshell of it) and its descendants are not judged by them: they are waited for, a bound of 20 s polled
# every 0.1 s (the floor: the watcher forks once on its way out), each listing's descendants noted, and once none with that command line is left two listings 0.1 s apart, the first at once, judge
# what was a descendant as any other process; one still there at 20 s is left. A plain run has no _db5_cmd and is judged as before. (2) R61: the job part's sleeper, which a sleep 600 could not make
# look for its directory, is a perl started with & (command perl, so no part's perl function stands in) that sleeps 1 s at a time for 600 s at most while the case directory exists; its name says so,
# and _db5_reap knows it by its tag djx-job and the case directory in its command line. (3) R62: DJX_MLOG gets "1295 run CASE/LABEL bound B ms START-TO-EXIT" for every inner run, and
# "1295 margin sr/r/watcher T 20000 ms MS" (none when the watcher was still there at 20 s), R60's wait, each after its case's checks. (4) R58: no watch here. R59: no record run here is ended by a signal.
# Revision 18's review, by blind author B from the contract alone: (1) R60: once a process with the record run's command line was seen and none is left (or 20 s have passed), the two listings
# 0.1 s apart judge every live process of the run's groups that the first two did not already name, not only what a poll saw below the watcher, so a child the watcher left between two polls,
# or a process that came into the groups after the first listing, is judged like any other (atexit.pl, the same text as 1293's). (2) R62: the run that holds (DJX_HOLD) also logs C as a margin,
# "1295 margin sr/r/C T 40000 ms MS", MS its mark-to-step-end (hold.ended - hold.mark; none when either file is missing).
# R42 (e), after R38, with R44: red's suite runs this part on the base's tests/red and tests/receipt.sh, which lack R1's stopper, so the record run's exit with a runner failure is, there, only
# after red's suite has ended by itself, and what is left of red's tree then is a matter of timing. The record run therefore gives red's suite (DJX_HOLD names hold.pl, for that run
# alone, and DJX_LIM the case's run bound B, 600 s, _db5_lim) a red-only holder H, planted in the last part that fails (the line sits before its change): where FELIX_TEST_NO_MANIFEST=1 the part makes the case's hold.dir (only the first
# to do so goes on), starts H (a process that ends within 0.2 s of hold.release appearing, and on its own only once B + 30 s have passed since it started),
# writes hold.pid and hold.start and waits until hold.go exists, for B at most (without it, it goes on all the same, R46), then for the record run's failed mark (R53, B at most since the step started), and C = 40 s more after the mark;
# in the record run the same part waits for hold.start (B at most; if it never came it writes no hold.go, R46) and writes hold.go. The record run's failure, and its mark, come after hold.go
# (DJX_MLOG, when it names a file, logs go-to-mark and mark-to-step-end): against D's build red's monitor ends red's suite on the failed mark while the step holds (C is counted from the mark, R53),
# H with it, and nothing of red's tree is left when the record run exits; against a build without R1 red's suite goes on 40 s after the mark and ends by itself, leaving H running, and the
# name fails on every run; so it does against a build whose red leaves its suite running and whose record run ends red's tree at its own 60 s bound, 59 s or more after the mark, once the
# step has ended at 40 s and H has left red's tree (R53). _db5_run writes hold.release as soon as _db5_atexit has listed, before _db5_clean. The step is one perl process (no short-lived child to be left behind).
# R44: no bound of a hold is shorter than the case's own run bound, and a hold that did not happen fails R1's name on either build: R46: _db5_hv gives R1's verdict on a record half that holds, ok only when hold.start exists (else "red's suite never reached its hold"), hold.go exists (else "the record run never reached its hold"), the run did not end at its bound (exit 124: "the run reached its bound") and the listings at the exit find nothing, the first that fails giving the got. hold.miss and hold.nogo are not written: run.pl's KILL at B comes before either could be. DJX_MLOG's line for a case that held also gives, in ms from the run's start (_db5_start writes it to run.start), the times to hold.start, to hold.go and to the exit.
# An assertion whose name ends in (control) passes before D is built on purpose.
DB5="$TMP/db5"
mkdir -p "$DB5/pp/std" "$DB5/pp/sh" "$DB5/exp" "$DB5/n" "$DB5/mk"
_db5_mkreal="$(command -v mktemp)"
cat > "$DB5/mk/mktemp" <<'DB5MK'
#!/bin/sh
# mktemp for R41: the host's ($DB5_MKREAL), logging each path it made to $DB5_MKLOG. With no template argument (only options) it passes the same options and the template "$TMPDIR/tmp.XXXXXXXXXX".
t=0
for a in "$@"; do case "$a" in -*) ;; *) t=1 ;; esac; done
if [ "$t" = 0 ] && [ -n "${TMPDIR:-}" ]; then   # R41-RULE
  set -- "$@" "${TMPDIR%/}/tmp.XXXXXXXXXX"
fi
out="$("$DB5_MKREAL" "$@")" || exit $?
printf '%s\n' "$out" >> "$DB5_MKLOG"
printf '%s\n' "$out"
DB5MK
chmod +x "$DB5/mk/mktemp"; : > "$DB5/mktemp.log"
cat > "$DB5/hold.pl" <<'DB5HOLD'
# hold.pl SIDE DIR (R38, R44, R53; the same text in parts 1293 and 1295): SIDE 1 is red's suite (FELIX_TEST_NO_MANIFEST=1), anything else the record run. DIR is the case's directory,
# and DIR/tmp the TMPDIR the case gives its runs. B, the case's run bound, is $ENV{DJX_LIM}. C, the step's hold after the record run's failed mark, is 40 s (R53).
use strict; use Time::HiRes qw(time sleep);
my ($side, $d) = @ARGV; my $B = $ENV{DJX_LIM} || 600;
sub ms { sprintf "%d\n", time * 1000 }
sub put { my ($f, $t) = @_; open(my $h, ">", "$f.t") or return; print $h $t; close $h; rename "$f.t", $f }
# R53: the record run's failed mark: a regular file manifest.mark one directory below DIR/tmp (R41's stand-in mktemp puts the record run's $TMP there) whose first line is failed
sub failed { opendir(my $D, "$d/tmp") or return 0; for my $n (readdir $D) { next if $n eq "." || $n eq ".."; my $m = "$d/tmp/$n/manifest.mark"; next unless -f $m && open(my $h, "<", $m);
  my $l = <$h>; close $h; next unless defined $l; chomp $l; return 1 if $l eq "failed" } return 0 }
if ($side eq "1") {
  mkdir "$d/hold.dir" or exit 0;
  $SIG{TERM} = sub { put("$d/hold.ended", ms()); exit 143 };
  my $t0 = time; my $h = fork; defined $h or exit 0;
  if (!$h) {
    open(STDIN, "<", "/dev/null"); open(STDOUT, ">", "/dev/null"); open(STDERR, ">", "/dev/null");
    $SIG{TERM} = "DEFAULT";
    sleep 0.1 until -e "$d/hold.release" || ! -d $d || time > $t0 + $B + 30;
    exit 0;
  }
  put("$d/hold.pid", "$h\n"); put("$d/hold.start", ms());
  my $e = $t0 + $B; sleep 0.1 until -e "$d/hold.go" || ! -d $d || time > $e;
  if (-e "$d/hold.go") {
    my $f = 0; until (($f = failed()) || ! -d $d || time > $e) { sleep 0.1 }   # R53: once hold.go exists, the mark, every 0.1 s, until B has passed since the step started
    if ($f) { put("$d/hold.mark", ms()); my $c = time + 40; sleep 0.1 while time < $c && -d $d }   # then C = 40 s more, and only then on, without waiting for H
  }
} else {
  my $e = time + $B; sleep 0.1 until -e "$d/hold.start" || ! -d $d || time > $e;
  if (-e "$d/hold.start") { put("$d/hold.go", ms()) }
}
DB5HOLD
cat > "$DB5/atexit.pl" <<'DB5AX'
# atexit.pl WFILE CMD GROUP... (R1, R60; the same text in parts 1293 and 1295): "ok", or "left at its exit: PID STAT COMMAND;..." for what the process groups GROUP... (zombies aside) hold
# at a run's exit. Two listings 0.1 s apart, the first at once: a process in both is left. Not judged by them: a process whose command line is CMD (the record run's own: its watcher, or a subshell
# of it; CMD empty, none) and what either listing shows below one. When either shows one with CMD, it is waited for, a bound of 20 s from the first listing polled every 0.1 s; then (once none with
# CMD is left, or at 20 s) two listings 0.1 s apart, the first at once, judge every process of the groups that the first two did not already name, whether or not a listing saw it below one with
# CMD (a child the watcher left between two polls is judged like any other), and one with CMD still there at 20 s is left. WFILE gets the ms from the first listing to the first with none with CMD, or none.
use strict; use Time::HiRes qw(time sleep);
open(STDERR, ">", "/dev/null"); my ($wf, $cmd, @g) = @ARGV; my %g = map { $_ => 1 } grep { /^\d+$/ } @g;
sub ls { my %p; open(my $h, "-|", "ps", "-A", "-ww", "-o", "pid=", "-o", "ppid=", "-o", "pgid=", "-o", "stat=", "-o", "command=") or return \%p;
  while (my $l = <$h>) { next unless $l =~ /^\s*(\d+)\s+(\d+)\s+(\d+)\s+(\S+)\s*(.*?)\s*$/; $p{$1} = [$2, $4, $5] if $g{$3} && $4 !~ /^Z/ } close $h; \%p }
sub wt { my ($p) = @_; $cmd eq "" ? () : grep { $p->{$_}[2] eq $cmd } keys %$p }   # the processes with CMD
sub dn { my ($p, @w) = @_; my %d = map { $_ => 1 } @w; my $n = 1; while ($n) { $n = 0; for (keys %$p) { next if $d{$_} || !$d{$p->{$_}[0]}; $d{$_} = 1; $n = 1 } } delete @d{@w}; keys %d }   # their descendants
sub row { my ($p, $k) = @_; "$k $p->{$k}[1] " . substr($p->{$k}[2], 0, 70) }
sub both { my ($x, $y, @k) = @_; join "", map { row($y, $_) . ";" } sort { $a <=> $b } grep { exists $y->{$_} } @k }
my $t0 = time; my $l1 = ls(); my @w1 = wt($l1); my %out = map { $_ => 1 } (@w1, dn($l1, @w1));
sleep 0.1; my $t2 = time; my $l2 = ls(); my @w2 = wt($l2); $out{$_} = 1 for (@w2, dn($l2, @w2));
my %nm = map { $_ => 1 } grep { !$out{$_} && exists $l2->{$_} } keys %$l1; my $left = both($l1, $l2, keys %nm);   # what the first two listings named
my $wms; my %wl = map { $_ => row($l2, $_) } @w2;
if (!@w1 && !@w2) { $wms = 0 } elsif (!@w2) { $wms = int(($t2 - $t0) * 1000) }
else { while (time < $t0 + 20) { sleep 0.1; my $tl = time; my $p = ls(); my @x = wt($p); if (!@x) { $wms = int(($tl - $t0) * 1000); last } %wl = map { $_ => row($p, $_) } @x } }
unless (defined $wms) { $left .= join "", map { "$wl{$_} (the record run's own command line, still there 20 s after its exit);" } sort { $a <=> $b } keys %wl; $nm{$_} = 1 for keys %wl }
if (@w1 || @w2) { my $a1 = ls(); sleep 0.1; my $a2 = ls(); $left .= both($a1, $a2, grep { !$nm{$_} } keys %$a1) }   # R60 after review: every process of the groups not named yet
if ($wf ne "-" && open(my $h, ">", $wf)) { print $h (defined $wms ? $wms : "none"), "\n"; close $h }
print $left eq "" ? "ok" : "left at its exit: $left";
DB5AX
_db5_HL='[ -z "${DJX_HOLD:-}" ] || command perl "$DJX_HOLD" "${FELIX_TEST_NO_MANIFEST:-0}" "$DJX_DIR"'   # command: a serial red suite runs the earlier parts first, one of which defines a perl that does nothing
_db5_lab=""; _db5_cmd=""; _db5_t1=""; _db5_E=(); _db5_pf=(); _db5_cl=ok; _db5_ex=ok; _db5_leak=""; _db5_ctl=0; _db5_lim=600   # R55: B, every run bound of this part (the record run's too)
cat > "$DB5/run.pl" <<'DB5PL'
my ($t, $f) = splice(@ARGV, 0, 2);
my $p = fork; defined $p or exit 125;
if (!$p) { setpgrp(0, 0); $SIG{INT} = 'DEFAULT'; $SIG{QUIT} = 'DEFAULT'; $SIG{HUP} = 'DEFAULT'; $SIG{TERM} = 'DEFAULT'; if (open(my $h, ">", $f)) { print $h "$$\n"; close $h } exec @ARGV; exit 127 }
$SIG{ALRM} = sub { kill "KILL", -$p; exit 124 };
alarm $t; waitpid $p, 0;
exit(($? & 127) ? 128 + ($? & 127) : $? >> 8);
DB5PL
# FIRST SECOND LABEL: LABEL: FIRST-line is now SECOND-line, for the first line of two listings that differs
cat > "$DB5/ld.pl" <<'DB5LD'
my @a = split /\n/, $ARGV[0]; my @b = split /\n/, $ARGV[1];
for my $i (0 .. $#a) { next if $a[$i] eq ($b[$i] // ""); print "$ARGV[2]: $a[$i] is now ", ($b[$i] // ""), "\n"; last }
DB5LD
: > "$DB5/g-empty.tsv"; printf '1\tdjx a1\n' > "$DB5/man.tsv"
printf 'printf "\\ndjx-sec 0010-pa.sh\\n"\nok "djx a1"\n' > "$DB5/pp/std/0010-pa.sh"
_db5_cnt()  { LC_ALL=C awk -v p="$2" 'index($0, p) == 1 { n++ } END { print n + 0 }' "$1" 2>/dev/null; }   # FILE PREFIX: lines starting with it
_db5_line() { grep -cxF -e "$2" "$1" 2>/dev/null; }   # FILE LINE: lines that are exactly it
# The members of the process groups $* that are not zombies, one a line: PID STAT COMMAND.
_db5_gm() { ps -A -o pid= -o pgid= -o stat= -o command= 2>/dev/null | G=" $* " LC_ALL=C awk 'index(ENVIRON["G"], " " $2 " ") && $3 !~ /^Z/ { c = $0; sub(/^ *[0123456789]+ +[0123456789]+ +[^ ]+ +/, "", c); print $1 " " $3 " " substr(c, 1, 70) }'; }
_db5_gs() { local f; for f in ${_db5_pf[@]+"${_db5_pf[@]}"}; do printf ' %s' "$(cat "$f" 2>/dev/null)"; done; }   # the ids of the process groups of this case's runs
# R1: "ok" when no process of those groups is alive at two listings 0.1 s apart, the first taken at once after a run has exited, else the ones in both. R60: for a record run (_db5_cmd, its own
# command line) its watcher, a subshell of it and their descendants are waited for, 20 s at most, and once they are gone two listings judge every process of the groups not named yet (atexit.pl); the wait's ms go to CASE/LABEL.axw (R62)
_db5_atexit() { local g; g="$(_db5_gs)"; [ -n "${g// /}" ] || { printf ok; return 0; }; perl "$DB5/atexit.pl" "$_db5_c/$_db5_lab.axw" "$_db5_cmd" $g; }
# R12: "ok" once the groups of this case's runs hold no live process (30 s), else what was left, sent CONT and then KILL by pid.
_db5_clean() {
  local g l="" i=0 p; g="$(_db5_gs)"
  [ -n "${g// /}" ] || { printf ok; return 0; }
  while [ "$i" -lt 150 ]; do l="$(_db5_gm $g)"; [ -n "$l" ] || { printf ok; return 0; }; sleep 0.2; i=$((i + 1)); done
  for p in $(printf '%s\n' "$l" | awk '{ print $1 }'); do kill -CONT "$p" 2>/dev/null; done
  for p in $(printf '%s\n' "$l" | awk '{ print $1 }'); do kill -KILL "$p" 2>/dev/null; done
  printf 'left behind: %s' "$(printf '%s' "$l" | tr '\n' ';')"
}
# The sleepers a planted part left running (job.pids): each is ended by the pid it wrote down, after a look that the pid still is that sleep.
_db5_reap() {
  local p c
  for p in $(cat "$_db5_c/job.pids" 2>/dev/null); do
    c="$(ps -ww -o command= -p "$p" 2>/dev/null)"; case "$c" in *perl*" djx-job $_db5_c"*) kill -KILL "$p" 2>/dev/null ;; esac   # R61: the job part's sleeper, by its tag and its case directory
  done
  return 0
}
# CASE [--red] GROUPS MANIFEST STUB...: the copy at $DB5/n/CASE (_db5_F, _db5_T, _db5_c, _db5_tmp); 1 when it could not be made
_db5_new() {
  local n="$1" r=""; shift
  [ "${1:-}" != --red ] || { r=--red; shift; }
  _db5_c="$DB5/n/$n"; _db5_F="$_db5_c/f"; _db5_T="$_db5_F/engine/harness/tests"; _db5_tmp="$_db5_c/tmp"; _db5_pf=()
  rm -rf "$_db5_c"; mkdir -p "$_db5_tmp" || return 1
  _suite_copy_tree ${r:+"$r"} "$_db5_F" "$@"
}
# LABEL ARG...: the copy's driver in the background under a bounded runner (stdin /dev/null, stdout LABEL.out, stderr LABEL.err, the group's id
# LABEL.pid). LC_ALL, LC_COLLATE, CLAUDE_CONFIG_DIR and EXECIGNORE are taken out of its environment, so that a part that exports them adds them.
_db5_start() {
  local l="$1" e; shift
  _db5_lab="$l"; _db5_cmd=""   # R62: the run's label; R60: a record run's own command line, as ps prints it (run.pl execs it from this argv)
  case " $* " in *" --record-assertions "*) _db5_cmd="$BASH $_db5_T/run"; for e in "$@"; do _db5_cmd="$_db5_cmd $e"; done ;; esac
  _db5_ms > "$_db5_c/run.start"   # R46: the run's start, ms (evidence fields of DJX_MLOG)
  ( cd "$_db5_F" && exec env -u FELIX_TEST_NO_MANIFEST -u FELIX_TEST_JOBS -u FELIX_TEST_SLOTS -u FELIX_TEST_RED_JOBS -u FELIX_TEST_SLOT_NOTE -u FELIX_TEST_PART_LOG \
      -u FELIX_TEST_PART_RAN -u FELIX_TEST_PART_END -u FELIX_TEST_PART_RECORD -u PERL5OPT -u LC_ALL -u LC_COLLATE -u CLAUDE_CONFIG_DIR -u EXECIGNORE \
      TMPDIR="$_db5_tmp" PATH="$DB5/mk:$PATH" DB5_MKREAL="$_db5_mkreal" DB5_MKLOG="$DB5/mktemp.log" FELIX_TEST_SLOTS=8 DJX_DIR="$_db5_c" DJX_PL="$DB5" DJX_KEEP=1 ${_db5_E[@]+"${_db5_E[@]}"} \
      perl "$DB5/run.pl" "$_db5_lim" "$_db5_c/$l.pid" "$BASH" "$_db5_T/run" "$@" \
  ) < /dev/null > "$_db5_c/$l.out" 2> "$_db5_c/$l.err" &
  _db5_bg=$!; _db5_pf[${#_db5_pf[@]}]="$_db5_c/$l.pid"
}
_db5_wait() { { wait "$_db5_bg"; } 2>/dev/null; _db5_rc=$?; _db5_E=(); }
_db5_ms() { perl -MTime::HiRes=time -e 'printf "%d", time * 1000'; }
# R46: R1's verdict on a record run that held ($1: what the listings at its exit found): the first of these that fails gives the got. hold.start missing: red's suite never reached its step; hold.go missing: the record run never reached its wait;
# the run ended at its bound (exit 124); else what the listings found.
_db5_hv() {
  if [ ! -e "$_db5_c/hold.start" ]; then printf "red's suite never reached its hold"
  elif [ ! -e "$_db5_c/hold.go" ]; then printf 'the record run never reached its hold'
  elif [ "$_db5_rc" = 124 ]; then printf 'the run reached its bound'
  else printf '%s' "$1"; fi
}
_db5_df() { local a="${1:-}" b="${2:-}"; case "$a" in ""|*[!0123456789]*) printf none; return 0 ;; esac; case "$b" in ""|*[!0123456789]*) printf none; return 0 ;; esac; printf '%s' "$((10#$a - 10#$b))"; }   # A B: A - B in ms, or none when either is not a number (a missing or empty file must not end the part: R46 evidence fields)
_db5_rel() { _db5_df "$(cat "$_db5_c/$1" 2>/dev/null)" "$(cat "$_db5_c/run.start" 2>/dev/null)"; }   # FILE: its ms, from the run's start (none when either is missing)
_db5_run()  {   # _db5_ex: R1's verdict on this run, _db5_cl: R12's, whose findings _db5_leak keeps
  local e h=0; for e in ${_db5_E[@]+"${_db5_E[@]}"}; do case "$e" in DJX_HOLD=*) h=1 ;; esac; done   # a run that holds is given DJX_HOLD
  _db5_start "$@"; _db5_wait; _db5_reap; _db5_t1="$(_db5_ms)"; _db5_ex="$(_db5_atexit)"; [ "$h" = 0 ] || _db5_ex="$(_db5_hv "$_db5_ex")"
  : > "$_db5_c/hold.release"   # R42 (e): the red-only holder ends (within 0.2 s) as soon as the listings are taken, so _db5_clean has about a second to wait for
  _db5_cl="$(_db5_clean)"
  [ "$_db5_cl" = ok ] || _db5_leak="$_db5_leak [$_db5_c: $_db5_cl]"
  # evidence only: with DJX_MLOG naming a file, a run that had a holding step logs the case, hold.go to the end of the step (hold.ended) and to the record run's exit, (R46) the times to hold.start, hold.go and the exit from the run's start,
  # and (R53) go-to-mark (hold.mark - hold.go) and mark-to-step-end (hold.ended - hold.mark), none when a file is missing; in ms; ex last, since it may hold blanks
  [ -z "${DJX_MLOG:-}" ] || [ ! -e "$_db5_c/hold.go" ] || printf '%s go-to-step-end %s go-to-exit %s start-to-hold.start %s start-to-hold.go %s start-to-exit %s go-to-mark %s mark-to-step-end %s ex %s\n' "${_db5_c##*/}" \
    "$([ -e "$_db5_c/hold.ended" ] && _db5_df "$(cat "$_db5_c/hold.ended" 2>/dev/null)" "$(cat "$_db5_c/hold.go" 2>/dev/null)" || echo natural)" "$(_db5_df "$_db5_t1" "$(cat "$_db5_c/hold.go" 2>/dev/null)")" \
    "$(_db5_rel hold.start)" "$(_db5_rel hold.go)" "$(_db5_df "$_db5_t1" "$(cat "$_db5_c/run.start" 2>/dev/null)")" \
    "$(_db5_df "$(cat "$_db5_c/hold.mark" 2>/dev/null)" "$(cat "$_db5_c/hold.go" 2>/dev/null)")" "$(_db5_df "$(cat "$_db5_c/hold.ended" 2>/dev/null)" "$(cat "$_db5_c/hold.mark" 2>/dev/null)")" "$_db5_ex" >> "$DJX_MLOG"
  [ "$h" = 0 ] || _db5_ml margin "${_db5_c##*/}/$_db5_lab/C" T 40000 ms "$(_db5_df "$(cat "$_db5_c/hold.ended" 2>/dev/null)" "$(cat "$_db5_c/hold.mark" 2>/dev/null)")"   # R62 after review: every run that holds, C (40 s) as a margin, mark-to-step-end (none when either file is missing)
  _db5_mr
}
# R62, evidence only (a line never decides a verdict, and none is written without DJX_MLOG): _db5_ml WORD...: the line "1295 WORD..."; _db5_mr, once a run's checks are done: its run line,
# "1295 run CASE/LABEL bound B ms START-TO-EXIT", and for a record run R60's wait as a margin, "1295 margin CASE/LABEL/watcher T 20000 ms MS-OR-none"
_db5_ml() { [ -z "${DJX_MLOG:-}" ] || printf '1295 %s\n' "$*" >> "$DJX_MLOG"; }
_db5_mr() {
  _db5_ml run "${_db5_c##*/}/$_db5_lab" bound "$_db5_lim" ms "$(_db5_df "$_db5_t1" "$(cat "$_db5_c/run.start" 2>/dev/null)")"
  [ -z "$_db5_cmd" ] || [ ! -s "$_db5_c/$_db5_lab.axw" ] || _db5_ml margin "${_db5_c##*/}/$_db5_lab/watcher" T 20000 ms "$(sed -n 1p "$_db5_c/$_db5_lab.axw")"
}
_db5_rcpt() { if [ -f "$_db5_F/.git/felix-suite-receipt" ]; then echo present; else echo absent; fi; }
_db5_last() { tail -n 1 "$_db5_c/$1.out" 2>/dev/null; }
_db5_redrows() { if [ -f "$_db5_T/red.tsv" ]; then grep -v '^#' "$_db5_T/red.tsv" | tr '\n' '|'; else printf '(no red.tsv)'; fi; }
_db5_w="part left the shell changed for the parts after it"
# LABEL EXPECT...: "ok", or what differed, for the run LABEL just made: exit 1; each EXPECT a FAIL line printed once ("!X": never starting so); the summary
# counts as many failures as the log has FAIL lines; no receipt, and a control showing a passing run leaves one
_db5_chk() {
  local l="$1" e c r="" s wf; shift
  [ "$_db5_rc" = 1 ] || r="$r exit $_db5_rc, not 1;"
  for e in "$@"; do
    case "$e" in
      !*) c="$(_db5_cnt "$_db5_c/$l.out" "  FAIL  ${e#!}")"; [ "$c" = 0 ] || r="$r [${e#!}] printed $c times;" ;;
      *) c="$(_db5_cnt "$_db5_c/$l.out" "  FAIL  $e")"; [ "$c" = 1 ] || r="$r [$e] printed $c times;" ;;
    esac
  done
  s="$(_db5_last "$l")"; wf="$(_db5_cnt "$_db5_c/$l.out" '  FAIL  ')"
  case "$s" in *" passed, "*" failed"*) s="${s#* passed, }"; s="${s%% failed*}"; [ "$s" = "$wf" ] || r="$r summary counts $s failed, not $wf;" ;; esac
  [ "$_db5_ctl" = 1 ] || r="$r the control left no receipt, so a missing one says nothing;"
  [ "$(_db5_rcpt)" = absent ] || r="$r a receipt was left;"
  printf '%s' "${r:-ok}"
}
# LABEL EXPECT...: _db5_chk for a record run, the manifest as it was, and red.tsv the two retraction rows (red has gone: _db5_run waited for the group)
_db5_chkr() {
  local r; r="$(_db5_chk "$@")"; [ "$r" != ok ] || r=""
  cmp -s "$DB5/man.tsv" "$_db5_T/assertions.tsv" || r="$r the manifest was rewritten;"
  [ "$(_db5_redrows)" = "$(printf 'base\t-\t-\t-|run\t-\t-\t-|')" ] || r="$r red.tsv holds [$(_db5_redrows)];"
  printf '%s' "${r:-ok}"
}
# OUT UNIT: the "  | " lines directly after UNIT's seventh failure, sorted, one a line; when the failure is not printed exactly once, say so
_db5_bars() {
  LC_ALL=C awk -v u="  FAIL  $_db5_w: $2" '
    $0 == u { n++; on = 1; next }
    on && index($0, "  | ") == 1 { b[++k] = substr($0, 5); next }
    { on = 0 }
    END { if (n != 1) { print "[the failure was printed " n + 0 " times]"; exit } for (i = 1; i <= k; i++) print b[i] }' "$_db5_c/$1" | LC_ALL=C sort
}
# The planted parts. _db5_sp NAME DESC KIND CODE [EXPECTED-LINE...]: part NNN0-NAME.sh does CODE and then its own ok line. KIND x: it leaves the shell
# changed, and the seventh failure's bar lines are exactly the EXPECTED-LINEs (none given: the part writes them to $DJX_DIR/exp.NAME); j: as x, but
# only the -j 3 run holds it; c: as p, but only the -j 1 run holds it; p: it passes; s: skipped, the part does nothing, and _db5_skr says why.
_db5_i=0; _db5_sn=(); _db5_sd=(); _db5_sk=(); _db5_sc=(); _db5_sr=(); _db5_skr=
_db5_sp() {
  local f
  _db5_i=$((_db5_i + 1)); f="$(printf '%04d-%s.sh' $((_db5_i * 10)) "$2")"
  printf 'printf "\\ndjx-sec %s\\n"\n%s\nok "djx shell %s"\n' "$f" "$5" "$2" > "$DB5/pp/sh/$f"
  _db5_sc[$_db5_i]="$1"; _db5_sn[$_db5_i]="$2"; _db5_sd[$_db5_i]="$3"; _db5_sk[$_db5_i]="$4"; _db5_sr[$_db5_i]="$_db5_skr"; _db5_skr=""
  [ "$#" -le 5 ] || { shift 5; printf '%s\n' "$@" > "$DB5/exp/${_db5_sn[$_db5_i]}"; }
}
_db5_unit() { printf '%04d-%s.sh' $(($1 * 10)) "${_db5_sn[$1]}"; }
_db5_ul="$(ulimit -S -n 2>/dev/null)"; case "$_db5_ul" in ''|*[!0123456789]*) _db5_ul=0 ;; esac
# the first two functions tests/lib defines, other than its _vars functions: a part redefines the first and unsets the second
_db5_fn=($(LC_ALL=C awk '/^_[a-z0-9_]+\(\) *[{]/ { s = $1; sub(/\(\).*/, "", s); if (s !~ /_vars$/ && !(s in seen) && ++k <= 2) { seen[s] = 1; print s } }' "$HERE"/lib/*.sh))
# R16: a resource whose hard limit is above its soft one and can be lowered to it, measured in a child of this bash (flag and soft value), or nothing
_db5_uh="$("$BASH" -c 'for f in c s n d f l m t v u; do
    s="$(ulimit -S -$f 2>/dev/null)" || continue; h="$(ulimit -H -$f 2>/dev/null)" || continue
    case "$s" in ""|*[!0123456789]*) continue ;; esac
    [ "$s" != "$h" ] || continue
    ( ulimit -H -$f "$s" ) 2>/dev/null || continue
    echo "$f $s"; exit 0
  done' 2>/dev/null)"
_db5_ulf="${_db5_uh% *}"; _db5_uls="${_db5_uh#* }"
_db5_umk='djx_w="$(umask)"; case "$djx_w" in 0077|077) umask 027 ;; *) umask 077 ;; esac; printf "umask %s is now %s\n" "$djx_w" "$(umask)"'

_db5_sp R8 umask "umask 077 left set" x "$_db5_umk"' > "$DJX_DIR/exp.umask"; unset djx_w'
_db5_sp R8 shopt "shopt -s nullglob left set" x 'shopt -s nullglob' 'shopt -u nullglob is now shopt -s nullglob'
_db5_sp R8 trap "a trap on USR1 left set" x 'trap : USR1' 'trap on SIGUSR1 added'
_db5_sp R8 unexp "an exported variable the case set, unset" x 'unset DJX_KEEP' 'export DJX_KEEP removed'
_db5_sp R8 fnre "a function of tests/lib redefined" x "${_db5_fn[0]:-NONE}() { :; }" "function ${_db5_fn[0]:-NONE} changed"
_db5_sp R8 fnun "a function of tests/lib unset, as part 0290 did" x "unset -f ${_db5_fn[1]:-NONE}" "function ${_db5_fn[1]:-NONE} removed"
_db5_sp R8 felix "FELIX given another value" x 'FELIX=/djx/other' 'variable FELIX changed'
_db5_sp R8 fd7 "descriptor 7 left open" x 'exec 7>/dev/null' 'descriptor 7 opened'
if [ "$_db5_ul" -ge 8 ]; then
  _db5_sp R8 ulimit "a soft limit lowered with ulimit -S" x 'djx_w="$(ulimit -Sa)"; ulimit -S -n "$((DJX_ULIM - 1))"; djx_n="$(ulimit -Sa)"
perl "$DJX_PL/ld.pl" "$djx_w" "$djx_n" "ulimit -a" > "$DJX_DIR/exp.ulimit"; unset djx_w djx_n'
else _db5_skr="the soft limit on open files is [$(ulimit -S -n 2>/dev/null)], not a number to lower"; _db5_sp R8 ulimit "a soft limit lowered with ulimit -S" s ':'; fi
_db5_sp R8 newvar "a part that sets a new variable" p 'djx_new_variable=1'
_db5_sp R8 newfn "a part that defines a new function that hides no builtin, keyword or command" p 'djx_new_function() { :; }'
_db5_sp R8 libvar "a part that changes a variable of tests/lib" p 'IB_BR=x; _AU_F=/djx/changed'
_db5_sp R16 newexp "a part that exports a new name outside the old steering list, which R8 passed" x 'export DJX_NEW_EXPORT=1' 'export DJX_NEW_EXPORT added'
_db5_sp R16 repo "unset REPO, a plain variable the prelude sets" x 'unset REPO' 'variable REPO removed'
_db5_sp R16 roots "a change to _fx_roots, an underscore-prefixed prelude variable" x '_fx_roots="$_fx_roots"$'"'"'\n'"'"'"$TMP/djx-root"' 'variable _fx_roots changed'
_db5_sp R16 keep "a new value for an export the case made before the run" x 'DJX_KEEP=2' 'export DJX_KEEP changed'
_db5_sp R16 lcall "export LC_ALL=C, with LC_ALL absent from the run's environment" x 'export LC_ALL=C' 'export LC_ALL added'
_db5_sp R16 cfgdir "export CLAUDE_CONFIG_DIR=/x, with it absent from the run's environment" x 'export CLAUDE_CONFIG_DIR=/x' 'export CLAUDE_CONFIG_DIR added'
_db5_sp R28 cdpath "CDPATH=/djx, a plain variable the main shell itself reads" x 'CDPATH=/djx' 'variable CDPATH added'
_db5_sp R28 lccoll "LC_COLLATE=C plain, with LC_COLLATE absent from the run's environment" x 'LC_COLLATE=C' 'variable LC_COLLATE added'
_db5_sp R28 optind "OPTIND=5" x 'OPTIND=5' 'variable OPTIND changed'
_db5_sp R16 posn "set -- a b c" x 'set -- a b c' 'positional parameters changed'
_db5_sp R16 pushd "pushd of the working directory, which leaves the stack changed and the directory as found" x 'pushd "$PWD" >/dev/null' 'directory stack changed'
_db5_sp R16 ro "readonly djx_ro=1" x 'readonly djx_ro=1' 'readonly djx_ro added'
_db5_sp R16 job "a 600 s sleeper started with & and left running (it ends once its case directory is gone)" x 'command perl -e '"'"'sleep 1 while $n++ < 600 && -d $ARGV[1]'"'"' djx-job "$DJX_DIR" &
printf "%s\n" "$!" >> "$DJX_DIR/job.pids"; printf "job %s left running\n" "$!" > "$DJX_DIR/exp.job"'
if [ -n "$_db5_ulf" ] && [ "$_db5_ulf" != "$_db5_uh" ]; then
  _db5_sp R16 ulh "a hard limit lowered with ulimit -H to its soft value" x 'djx_w="$(ulimit -Ha)"; ulimit -H -'"$_db5_ulf $_db5_uls"'; djx_n="$(ulimit -Ha)"
perl "$DJX_PL/ld.pl" "$djx_w" "$djx_n" "ulimit -Ha" > "$DJX_DIR/exp.ulh"; unset djx_w djx_n'
else _db5_skr="no resource has a hard limit above its soft one that this bash can lower"; _db5_sp R16 ulh "a hard limit lowered with ulimit -H to its soft value" s ':'; fi
_db5_sp R8 path "PATH changed" x 'PATH="$PATH:/djx/none"' 'export PATH changed'
_db5_sp R8 git "git() { :; } left defined" x 'git() { :; }' 'function git added over a command'
_db5_sp R8 gitdir "GIT_DIR exported" x 'export GIT_DIR=/djx/x' 'export GIT_DIR added'
# functions that forward to the real tool pin nothing of the guard (a comparator that calls perl or export by name reads the same through them), so under -j 3 they
# are no case of the seventh failure (R28): they stay as -j 1 controls. The ones that forward nothing are the cases, each in a unit of its own, beside umask 077.
_db5_sp R16 expfn "export() { builtin export \"\$@\"; } left defined, a -j 1 control" c 'export() { builtin export "$@"; }'
_db5_sp R16 perlum "perl() { command perl \"\$@\"; } beside umask 077, a -j 1 control" c "$_db5_umk"' > "$DJX_DIR/exp.perlum"; unset djx_w; perl() { command perl "$@"; }'
_db5_sp R28 shperl "perl() { :; } beside umask 077" j "$_db5_umk"' > "$DJX_DIR/exp.shperl"; unset djx_w
printf "function perl added over a command\n" >> "$DJX_DIR/exp.shperl"; perl() { :; }'
_db5_sp R28 shcomp "compgen() { :; } beside umask 077" j "$_db5_umk"' > "$DJX_DIR/exp.shcomp"; unset djx_w
printf "function compgen added over a builtin\n" >> "$DJX_DIR/exp.shcomp"; compgen() { :; }'
_db5_sp R28 shdecl "declare() { :; } beside umask 077" j "$_db5_umk"' > "$DJX_DIR/exp.shdecl"; unset djx_w
printf "function declare added over a builtin\n" >> "$DJX_DIR/exp.shdecl"; declare() { :; }'
# the driver runs under set -uo pipefail (tests/run:17), so a bare set -o pipefail would change nothing: the part measures the option in its own shell and flips it
_db5_sp R16 pipefail "the set -o pipefail option flipped from what the unit's shell has" x 'djx_w="$(set +o | grep " pipefail$")"
case "$djx_w" in "set -o pipefail") set +o pipefail ;; *) set -o pipefail ;; esac
printf "%s is now %s\n" "$djx_w" "$(set +o | grep " pipefail$")" > "$DJX_DIR/exp.pipefail"; unset djx_w'
_db5_sp R16 fd0 "exec 0<&-" x 'exec 0<&-' 'descriptor 0 closed'
_db5_sp R16 enable "enable -n printf" x 'enable -n printf' 'builtin printf disabled'
_db5_sp R24 enabl2 "enable -n enable, which hides the list of disabled builtins from the comparison" x 'enable -n enable' 'the shell state could not be compared'
_db5_sp R24 alias "alias djx_al=true" x 'alias djx_al=true' 'alias djx_al added'
_db5_sp R24 rofn "a readonly function" x 'djx_rf() { :; }; readonly -f djx_rf' 'readonly function djx_rf added'
_db5_sp R31 rxfn "a readonly function that is also exported, which a readonly function with only the r flag does not cover" x 'djx_rx() { :; }; readonly -f djx_rx; export -f djx_rx' 'readonly function djx_rx added'
_db5_sp R31 execign "EXECIGNORE='*/djx' plain, with EXECIGNORE absent from the run's environment" x "EXECIGNORE='*/djx'" 'variable EXECIGNORE added'
_db5_sp R16 fd2 "exec 2>&-" x 'exec 2>&-' 'descriptor 2 closed'
_db5_sp R16 trapexit "trap 'printf \"djx-exit\\n\"' EXIT" x 'trap '"'"'printf "djx-exit\n"'"'"' EXIT' 'trap on EXIT changed'
_db5_sp R28 trapnone "trap - EXIT, the prelude's EXIT trap removed, numbered last so that the -j 1 run reaches every part" x 'trap - EXIT' 'trap on EXIT removed'
_db5_n=$_db5_i
_db5_a1=(); _db5_a3=(); _db5_px=(); _db5_pp=(); _db5_xx=(); _db5_k=1   # the -j 1 set, the -j 3 set, the parts that fail, the ones that pass, their failures
while [ "$_db5_k" -le "$_db5_n" ]; do
  _db5_f="$DB5/pp/sh/$(_db5_unit "$_db5_k")"
  case "${_db5_sk[$_db5_k]}" in
    x|j) _db5_px[${#_db5_px[@]}]="$_db5_f"; _db5_xx[${#_db5_xx[@]}]="$_db5_w: $(_db5_unit "$_db5_k")" ;;
    p) _db5_pp[${#_db5_pp[@]}]="$_db5_f" ;;
  esac
  case "${_db5_sk[$_db5_k]}" in j) ;; *) _db5_a1[${#_db5_a1[@]}]="$_db5_f" ;; esac
  case "${_db5_sk[$_db5_k]}" in c) ;; *) _db5_a3[${#_db5_a3[@]}]="$_db5_f" ;; esac
  _db5_k=$((_db5_k + 1))
done
# R42 (e): the last part that fails gets the hold line, before its change (its second line); every other run has no DJX_HOLD, and the line then does nothing
_db5_hf="${_db5_px[${#_db5_px[@]} - 1]}"
{ sed -n 1p "$_db5_hf"; printf '%s\n' "$_db5_HL"; sed -n '2,$p' "$_db5_hf"; } > "$_db5_hf.t" && mv "$_db5_hf.t" "$_db5_hf"
_db5_oks() {   # OUT KINDS: the ok line of every planted part of those kinds is in OUT exactly once: "ok", or the names of those that are not
  local k=1 r="" c
  while [ "$k" -le "$_db5_n" ]; do
    case "$2" in *"${_db5_sk[$k]}"*) c="$(_db5_line "$_db5_c/$1" "  ok    djx shell ${_db5_sn[$k]}")"; [ "$c" = 1 ] || r="$r ${_db5_sn[$k]}:$c" ;; esac
    k=$((k + 1))
  done
  printf '%s' "${r:-ok}"
}

# ---- the controls: planted parts that pass, under -j 3 (D8), and a copy with a manifest, so that a missing receipt says something
_db5_new pn "$DB5/g-empty.tsv" - "$DB5/pp/std/0010-pa.sh"; _db5_run n1 -j 1
printf '1\t%s\n' "$(sed -n 's/^  ok    //p' "$_db5_c/n1.out" | sed -n 1p)" > "$DB5/pman.tsv"
rm -rf "$DB5/n/pn"
_db5_new sp "$DB5/g-empty.tsv" "$DB5/pman.tsv" ${_db5_pp[@]+"${_db5_pp[@]}"}; _db5_E=(DJX_ULIM="$_db5_ul"); _db5_run sp -j 3
_db5_x="$(_db5_oks sp.out p)"
[ "$_db5_rc" = 0 ] && [ "$(_db5_rcpt)" = present ] && _db5_ctl=1
is "R8: a new plain variable, a new function that hides nothing and a change to a variable of tests/lib each pass under -j 3: the run exits 0, leaves a receipt and no process, every part printed its ok line once, and none gave the seventh failure" \
   "$_db5_rc $(_db5_rcpt) $_db5_cl $_db5_x $(_db5_cnt "$_db5_c/sp.out" "  FAIL  $_db5_w")" "0 present ok ok 0"
rm -rf "$DB5/n/sp"

# ---- every part together under -j 3: the seventh failure of each, once, with exactly its change lines
_db5_new sh "$DB5/g-empty.tsv" "$DB5/pman.tsv" "${_db5_a3[@]}"; _db5_E=(DJX_ULIM="$_db5_ul"); _db5_run s3 -j 3
_db5_ny=(); _db5_k=1; while [ "$_db5_k" -le "$_db5_n" ]; do
  case "${_db5_sk[$_db5_k]}" in p) _db5_ny[${#_db5_ny[@]}]="!$_db5_w: $(_db5_unit "$_db5_k")" ;; esac; _db5_k=$((_db5_k + 1)); done
is "R8: every part that leaves the shell changed gives the seventh failure, once, and the ones that do not give none: the run exits 1, counts them in its summary, leaves no receipt and no process, and every part printed its ok line once" \
   "$(_db5_chk s3 "${_db5_xx[@]}" ${_db5_ny[@]+"${_db5_ny[@]}"}) $_db5_cl $(_db5_oks s3.out xpsj)" "ok ok ok"
_db5_k=1; while [ "$_db5_k" -le "$_db5_n" ]; do
  _db5_nm="${_db5_sn[$_db5_k]}"; _db5_t="${_db5_sc[$_db5_k]}: ${_db5_sd[$_db5_k]} gives the seventh failure with exactly its change line"
  case "${_db5_sk[$_db5_k]}" in
    s) skip "$_db5_t" "${_db5_sr[$_db5_k]}" ;;
    p) ;;
    x|j)
      _db5_e="$(if [ -f "$DB5/exp/$_db5_nm" ]; then cat "$DB5/exp/$_db5_nm"; else cat "$_db5_c/exp.$_db5_nm" 2>/dev/null; fi | LC_ALL=C sort)"
      _db5_g="$(_db5_bars s3.out "$(_db5_unit "$_db5_k")")"
      is "$_db5_t" "$([ -n "$_db5_e" ] && [ "$_db5_g" = "$_db5_e" ] && echo ok || echo "got [$(printf '%s' "$_db5_g" | tr '\n' '|')], wanted [$(printf '%s' "$_db5_e" | tr '\n' '|')]")" ok ;;
  esac
  _db5_k=$((_db5_k + 1))
done

# ---- R28: a group's unit is compared over its members: the first of two members leaves nullglob set, and the unit gives one seventh failure, named for the group
mkdir -p "$DB5/pp/grp"; printf 'djg\t0010-ga.sh\ndjg\t0020-gb.sh\n' > "$DB5/g-grp.tsv"
printf '%s\n' 'printf "\ndjx-sec 0010-ga.sh\n"' 'shopt -s nullglob' 'ok "djx grp a"' > "$DB5/pp/grp/0010-ga.sh"
printf '%s\n' 'printf "\ndjx-sec 0020-gb.sh\n"' 'ok "djx grp b"' > "$DB5/pp/grp/0020-gb.sh"
_db5_new sg "$DB5/g-grp.tsv" "$DB5/pman.tsv" "$DB5/pp/grp/0010-ga.sh" "$DB5/pp/grp/0020-gb.sh"; _db5_run g3 -j 3
is "R28: a two-member group whose first member leaves nullglob set gives one seventh failure naming the group's unit, exit 1, no receipt, no process, and both members printed their ok line once" \
   "$(_db5_chk g3 "$_db5_w: djg" "!$_db5_w: 0010-ga.sh" "!$_db5_w: 0020-gb.sh") $_db5_cl $(_db5_line "$_db5_c/g3.out" '  ok    djx grp a') $(_db5_line "$_db5_c/g3.out" '  ok    djx grp b')" "ok ok 1 1"
is "R28: and its one bar line is shopt -u nullglob is now shopt -s nullglob" "$(_db5_bars g3.out djg)" "shopt -u nullglob is now shopt -s nullglob"
rm -rf "$DB5/n/sg"

# ---- under -j 1 nothing is compared: none of them gives the seventh failure, and the run is known to have reached every part
_db5_new sj "$DB5/g-empty.tsv" "$DB5/pman.tsv" "${_db5_a1[@]}"; _db5_E=(DJX_ULIM="$_db5_ul"); _db5_run s1 -j 1
is "R8: under -j 1 none of them gives the seventh failure (R24, R28 included), a change carrying to the parts after it as it always did, and every part of the -j 1 set printed its ok line once, so the run reached them all" \
   "$(_db5_cnt "$_db5_c/s1.out" "  FAIL  $_db5_w") $(_db5_oks s1.out xpsc) $_db5_cl" "0 ok ok"

# ---- a record run: the seventh failure writes no manifest, and red.tsv holds the two retraction rows
_db5_new sr --red "$DB5/g-empty.tsv" "$DB5/man.tsv" "${_db5_px[@]}"; _db5_E=(DJX_ULIM="$_db5_ul" DJX_HOLD="$DB5/hold.pl" DJX_LIM="$_db5_lim")   # R42 (e), R44, R55: the red-only holder, for this run alone, given the run bound B
_db5_run r -j 3 --record-assertions
is "R8: in a record run the seventh failure writes no manifest, and red.tsv holds the rows base - - - and run - - -, with no process left" "$(_db5_chkr r "${_db5_xx[@]}") $_db5_cl" "ok ok"
is "R1: and once that record run has exited no process of red's tree is left, stopped or running" "$_db5_ex" ok
rm -rf "$DB5/n/sh" "$DB5/n/sj" "$DB5/n/sr"


# ---- R31: descriptors 10 and above are not compared (bash can name them only by globbing /dev/fd), so a lint holds the line: no line of a part or of tests/lib opens
# one at the top level, outside every function body and subshell, where it would reach every later part of a -j 1 run. The lint is a scan of the files' text, made here
# and not in the build: tl.awk follows function bodies, brace groups, subshells, substitutions, arithmetic, case arms, quotes, comments and here-documents from the start
# of a file, and names each exec there that opens a descriptor of 10 or above (a number from 10 up, or a {NAME}) with FILE:LINE:TEXT; closing one (>&-) is no opening.
# It reads only the files where a line could match, and reports a file whose nesting it loses (FILE:0:). A pipeline or a background group counts as top level, so
# the lint errs toward a finding. This block writes the word and the number together only inside the here-documents below, which the lint skips.
cat > "$DB5/tl.awk" <<'DB5TL'
function tl(   i) { for (i = 1; i <= sp; i++) if (stk[i] == "F" || stk[i] == "S" || stk[i] == "B" || stk[i] == "A") return 0; return 1 }
function add(s,   j) { for (j = 1; j <= length(s); j++) { sx = sx substr(s, j, 1); ctx[length(sx)] = tl() } }
function cmdpos(t) { sub(/[ \t]+$/, "", t); return (t == "" || t ~ /[;&|(){`!]$/ || t ~ /(^|[^A-Za-z0-9_])(then|do|else|elif|if|while|until)$/) }
function push(k) { sp++; stk[sp] = k; ad[sp] = 0; sv[sp] = svq; svq = "" }
function pop() { if (sv[sp] != "") q = sv[sp]; sp-- }
function fin() { if (sp != 0 || q != "" || nh != 0) print pf ":0:lost the nesting (open " sp ", quote [" q "], heredocs " nh ")" }
FNR == 1 { if (NR > 1) fin(); pf = FILENAME; sp = 0; q = ""; nh = 0; pd = 0; pend = ""; pk = 0; evalq = 0 }
END { if (NR > 0) fin() }
{
  if (nh > 0) {
    t = $0; if (hdash[1]) sub(/^\t+/, "", t)
    if (t == hd[1]) { for (j = 1; j < nh; j++) { hd[j] = hd[j + 1]; hdash[j] = hdash[j + 1] }; nh-- }
    next
  }
  line = $0; n = length(line); sx = ""; split("", ctx)
  for (i = 1; i <= n; i++) {
    c = substr(line, i, 1); p = (i > 1) ? substr(line, i - 1, 1) : " "; nx = (i < n) ? substr(line, i + 1, 1) : " "
    if (q == "'") { if (c == "'") q = ""; add(evalq ? c : " "); continue }
    if (q == "$") { if (c == "\\") { add(" "); i++; add(" ") } else { if (c == "'") q = ""; add(" ") }; continue }
    if (q == "\"") {
      if (c == "$" && nx == "(") { svq = "\""; q = ""; if (substr(line, i + 2, 1) == "(") { push("A"); add(evalq ? "$((" : "   "); i += 2 } else { push("S"); add(evalq ? "$(" : "  "); i++ }; continue }
      if (c == "\\") { add(evalq ? c : " "); i++; if (i <= n) add(evalq ? substr(line, i, 1) : " ") }
      else { if (c == "\"") q = ""; add(evalq ? c : " ") }
      continue
    }
    if (c == "\\") { add(" "); i++; if (i <= n) add(" "); continue }
    if (c == "'" || c == "\"") { evalq = (sx ~ /(^|[^A-Za-z0-9_])eval[ \t]+$/); q = c; add(evalq ? c : " "); continue }
    if (c == "$" && nx == "'") { q = "$"; add("  "); i++; continue }
    if (c == "#" && (i == 1 || p ~ /[ \t;&|()]/)) break
    if (pd > 0) { if (c == "{") pd++; else if (c == "}") pd--; add(c); continue }
    if (c == "$" && nx == "{") { pd = 1; add("${"); i++; continue }
    if (pend == "F" && !pk && c !~ /[ \t{(]/) pend = ""
    if (c == "<" && nx == "<" && substr(line, i, 3) != "<<<" && p != "<" && !(sp > 0 && stk[sp] == "A")) {
      r = substr(line, i + 2); d = 0
      if (substr(r, 1, 1) == "-") { d = 1; r = substr(r, 2) }
      sub(/^[ \t]+/, "", r)
      if (r ~ /^['"\\A-Za-z_]/) {
        if (match(r, /^'[^']*'/) || match(r, /^"[^"]*"/)) w = substr(r, 2, RLENGTH - 2)
        else { match(r, /^[\\A-Za-z_][A-Za-z0-9_]*/); w = substr(r, 1, RLENGTH); sub(/^\\/, "", w) }
        nh++; hd[nh] = w; hdash[nh] = d
      }
      add("<<"); i++; continue
    }
    if (c == "(" && nx == "(") { push("A"); add("  "); i++; continue }
    if (c == "(") {
      if (sp > 0 && stk[sp] == "A") { ad[sp]++; add(c); continue }
      rest = substr(line, i + 1)
      if (rest ~ /^[ \t]*\)/) {
        tt = sx; sub(/[ \t]+$/, "", tt)
        if (!pk && match(tt, /[A-Za-z_][A-Za-z0-9_.:@-]*$/) && cmdpos(substr(tt, 1, RSTART - 1))) pend = "F"
        match(rest, /\)/); add("(" substr(rest, 1, RSTART)); i += RSTART; continue
      }
      pend = ""; push("S"); add(c); continue
    }
    if (c == ")") {
      if (sp > 0 && stk[sp] == "A") { if (ad[sp] > 0) ad[sp]--; else { pop(); if (nx == ")") { add(c); i++ } } }
      else if (sp > 0 && stk[sp] == "S") pop()
      add(c); continue
    }
    if (c == "`") { if (sp > 0 && stk[sp] == "B") pop(); else push("B"); add(c); continue }
    if (c == "{" && (i == 1 || p ~ /[ \t;&|(]/) && (i == n || nx ~ /[ \t]/)) { push(pend == "F" ? "F" : "G"); pend = ""; pk = 0; add(c); continue }
    if (c == "}" && (i == 1 || p ~ /[ \t;&]/) && (i == n || nx ~ /[ \t;&|)<>]/)) { if (sp > 0 && (stk[sp] == "F" || stk[sp] == "G")) sp--; add(c); continue }
    if (c ~ /[A-Za-z_]/ && p !~ /[A-Za-z0-9_]/) {
      match(substr(line, i), /^[A-Za-z_][A-Za-z0-9_]*/); w = substr(line, i, RLENGTH)
      after = (i + RLENGTH <= n) ? substr(line, i + RLENGTH, 1) : " "
      if (after ~ /[ \t;)&|]/) {
        if (w == "case" && cmdpos(sx)) push("C")
        else if (w == "function" && cmdpos(sx)) { pend = "F"; pk = 1 }
        else if (w == "esac" && sp > 0 && stk[sp] == "C") sp--
      }
      add(w); i += RLENGTH - 1; continue
    }
    add(c)
  }
  L = length(sx)
  for (k = 1; k + 4 <= L; k++) {
    if (substr(sx, k, 4) != "exec" || !(k == 1 || substr(sx, k - 1, 1) !~ /[A-Za-z0-9_]/) || substr(sx, k + 4, 1) !~ /[ \t]/ || !ctx[k]) continue
    tail = substr(sx, k + 4); gsub(/&&/, ";", tail); gsub(/\|\|/, ";", tail); sub(/[;|)].*/, "", tail)
    gsub(/([{][A-Za-z_][A-Za-z0-9_]*[}]|[0-9]+)[<>]&-/, " ", tail)
    if (tail ~ /(^|[ \t])([{][A-Za-z_][A-Za-z0-9_]*[}]|[1-9][0-9]+)[<>]/) { print FILENAME ":" FNR ":" line; break }
  }
}
DB5TL
cat > "$DB5/shapes.txt" <<'DB5SH'
== a1
exec 11>/dev/null
== a2
exec {djx_fd}>/dev/null
== a3
exec 12<f
== a4
exec 10<>f
== a5
exec {fd}<f
== a6
exec 3>&1 11>x
== a7
eval "exec 11>x"
== a8
if true; then exec 11>x; fi
== a9
for i in 1 2; do
  exec 11>x
done
== a10
{ exec 11>x; }
== a11
f() { :; }
f
exec 11>/dev/null
== a12
case $x in
  a) exec 11>x ;;
esac
== a13
f() {
  :
}
g() { :; }
exec 100>x
== a14
f() { echo hi; }; exec 11>/dev/null
== a15
exec 11>&2
== a16
[ -n "$x" ] && exec 11>x
== a17
while read -r l; do exec 11>x; done < f
== a18
f() { echo "$(date)"; }
exec 11>x
== a19
cat <<EOF
text
EOF
exec 11>x
== a20
x=$(printf '%s' "$(echo ")")")
exec 11>x
== n1
f() { exec 11>/dev/null; }
== n2
f() {
  exec 11>x
}
g() {
  if x; then
    exec {fd}>y
  fi
}
== n3
( exec 11>x )
== n4
x=$(exec 11>x)
== n5
exec 63>&-
== n6
exec 9>x
== n7
# exec 11>x
== n8
cat <<EOF
exec 11>x
EOF
:
== n9
printf '%s\n' 'exec 11>x'
== n10
echo "exec 11>x"
== n11
function f {
  exec 11>x
}
== n12
f()
{
  exec 11>x
}
== n13
f() ( exec 11>x )
== n14
exec {fd}>&-
== n15
f() { eval "exec 11>&2"; }
== n16
cat <<-'EOF'
	exec 11>x
	EOF
:
== n17
case $x in
  a) f() { exec 11>x; } ;;
esac
== n18
exec 3>&1
== n19
x="$(exec 11>x)"
== n20
f() {
  case $x in a) exec 11>x ;; esac
}
== n21
x=$(case $y in a) exec 11>x ;; esac)
== n22
f() { echo "$(date)"; exec 11>x; }
DB5SH
_db5_x=ex; _db5_x="${_db5_x}ec"
_db5_tlint() {   # FILE...: FILE:LINE:TEXT of every top-level exec that opens a descriptor of 10 or above, nothing when there is none
  local c
  c="$(LC_ALL=C grep -lE 'exec[[:space:]]([^#]*[[:space:]])?([{][A-Za-z_][A-Za-z0-9_]*[}]|[1-9][0-9]+)[<>]' "$@" 2>/dev/null)"
  [ -n "$c" ] || return 0
  LC_ALL=C awk -f "$DB5/tl.awk" $c
}
# NAME PLANT FILE: a copy of the tree's parts and lib in $DB5/lint/NAME with the line PLANT added at the end of FILE: "ok" when the lint names that line and no other
_db5_tlc() {
  local d="$DB5/lint/$1" n
  rm -rf "$d"; mkdir -p "$d" && cp -R "$HERE/parts" "$HERE/lib" "$d/" || { printf 'the copy could not be made'; return 0; }
  printf '\n%s\n' "$2" >> "$d/$3"; n="$(awk 'END { print NR }' "$d/$3")"
  printf '%s\n' "$d/$3:$n:$2" > "$d/want"
  _db5_tlint "$d"/parts/*.sh "$d"/lib/*.sh > "$d/got"
  cmp -s "$d/got" "$d/want" && printf ok || printf 'got [%s], wanted [%s]' "$(cat "$d/got")" "$(cat "$d/want")"
}
is "R31: no line at the top level of a part or of tests/lib opens a descriptor of 10 or above (exec {NAME}> or <, or exec N> or < with N from 10 up): today's lines are inside functions" \
   "$(_db5_tlint "$HERE"/parts/*.sh "$HERE"/lib/*.sh)" ""
is "R31: the lint fails on a copy of the tree with exec 11>/dev/null planted at the top level of a part, naming that line and no other" \
   "$(_db5_tlc p11 "$_db5_x 11>/dev/null" parts/0007-the-parallel-runner.sh)" ok
is "R31: and on a copy with exec {djx_fd}>/dev/null planted at the top level of a lib file, naming that line and no other" \
   "$(_db5_tlc pnm "$_db5_x {djx_fd}>/dev/null" lib/gitproof.sh)" ok
mkdir -p "$DB5/shapes"; awk -v d="$DB5/shapes" '/^== / { if (f != "") close(f); f = d "/" $2 ".sh"; next } { print > f }' "$DB5/shapes.txt"
is "R31: the lint names the tops of files, of loops, of brace groups and of case arms, and not what is in a function (one line or many), a subshell, a substitution, a comment, a here-document, a string, a close or a descriptor below 10" \
   "$(_db5_tlint "$DB5"/shapes/*.sh | sed 's|.*/\([an][0-9]*\)[.]sh:.*|\1|' | LC_ALL=C sort -u | tr '\n' ' ')" \
   "$(sed -n 's/^== \(a[0-9]*\)$/\1/p' "$DB5/shapes.txt" | LC_ALL=C sort -u | tr '\n' ' ')"
rm -rf "$DB5/lint" "$DB5/shapes"

is "R12: no run of this part left a process in its process group, stopped or running, after the 30 s it was given" "${_db5_leak:-none}" none
# R41: the stand-in mktemp was reached by the nested runs, and every path it logged is under this part's own case directories
_db5_x="$(LC_ALL=C awk -v p="$DB5/n/" '{ t++; if (index($0, p) != 1) { o++; if (o <= 3) b = b " [" $0 "]" } } END { if (t == 0) print "no path logged"; else if (o) print o " of " t " outside:" b; else print "ok" }' "$DB5/mktemp.log" 2>/dev/null)"
is "R41: every path the mktemp stand-in logged for this part's nested runs (a run's \$TMP among them) is under this part's own case directories, and it logged some" "${_db5_x:-no log}" ok
unset -f $(compgen -A function _db5_) 2>/dev/null
unset $(compgen -A variable _db5_) DB5 2>/dev/null
# <<< gate-friction-d-shell-blind
