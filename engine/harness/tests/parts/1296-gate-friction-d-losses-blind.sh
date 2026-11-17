# >>> gate-friction-d-losses-blind
printf '\ngate friction D: the ending under a short read, a lost holder, a parent and a holder killed (blind, author 2; revision 12)\n'
# Blind, written on 2026-10-19 from contract D, revision 9 (D1 to D8, "Amended after review 1", "Amended after review 2" and "Amended after review 3"), by an author who read no implementation. tests/run, tests/red and tests/receipt.sh are run, never read, in copies of this suite that _suite_copy_tree (part 0003) makes under $TMP with planted parts of this block's own. Part 1292 holds the signals, dispositions and holders, part 1294 the slots, the gate and the log; this part holds
# what the revisions added about losing something: R13 (the parent never waits in an alarm-timed read, so an ending is not cut, and its @@gone read-back), R2 (a second TERM while it stops), R4 (the parent's own ending of a lost unit's holder), R14 and R21 (a stopper signals a member only while a listing shows its start time, and what it has stopped by its pid), R15 and R20 (a parent killed with -9, also while a holder waits for a slot; a holder killed with -9) and R22 (no unit runs before unit.I is written). Names say the clause.
# Revision 17 (R55, R56, R57), by blind author B from the contract alone: (1) R55: every run bound is _db6_lim = 600 s (was 100, and 120 to 150 per case), run.pl's literal ones too
# (gctl, R37's), and the holds and waits tied to it follow (units' release waits, P's and the slot holder's lives, the block shim's GO wait, the waits for a unit or the prelude, now _db6_runw:
# until the run's bound, or the run gone). (2) R56: R15's three margins (pk, hh, pw) are 60 s (were 3 s; a build without the clause waits out the units' 600 s release, L; a stopper's pass
# forks, floor 20 s); so that a holder with R20's 10 s ppid check but no kill 0 is still told apart, a ps (mode pphide) answers a holder's ps -o ppid= -p WRAPPER with the -j parent's
# pid in pk and pw. The djk control's 3 s is 20 s (the floor); the drains of 5 and 8 s are 30 s (R12); lh's look 0.6 s after the stop is a poll, bounded by the run's bound. (3) Review of revision 17: pphide answers only a call whose chain reaches a holder, a perl with " --part " and the key whose parent is WRAPPER, and logs each answer; a control (pc) stops the -j parent, sets the gate once its unit is up, and shows an answer within 60 s and the unit running on.
# Revision 18 (R58, R61, R62), by blind author B from the contract alone: (1) R58, the watches (a pause, then a look for what only a build without the clause makes): u22's block mode looked 4 s after
# its go file, and after the run's end, for started.*, which a holder that runs its unit before unit.I is written (revision 6's) makes through a unit left below pid 1 that the run does not wait for; the look now
# comes once nothing of the run is left by group, directory or id (_db6_clear, R12's 30 s, a bound), so such a unit has written started.* or is named, and the 4 s pause is gone. pw's two looks (1.5 s after
# the holder's slot line, 3 s after the slot is let go) stay short: djk's 60 s check in the same name names every holder or unit that could start a unit after them. Reading: lh's 4 s before release2 places
# an event inside the parent's ending and is followed by no look of its own, so it is no watch (open: under load it can fall before that ending, and the case then tells nothing apart). R59: no record run
# here. (2) R61: every process a case plants that may outlive R12's drain ends within 5 s of its case directory going, looking at least once a second: P and R (p.pl), the units' release waits, the units
# that ignore TERM and their gc sleepers, P's unit's wait for P, the block shim's wait for go, the djk and gctl sleepers, and djk.pl (DJK_DIR, _db6_djk). (3) R62: run.pl writes PIDFILE.ms, so DJX_MLOG gets
# "1296 run CASE/LABEL bound B ms START-TO-EXIT" for every inner run (_db6_fin, _db7_run, gctl) and "1296 margin CASE T MS ms MEASURED" (none when its event never came) for djk/kill and djk/both (20 s), pc,
# pk, hh and pw (60 s), and the watches pw/held-look (1.5 s), pw/released-look (3 s) and u22-block/unit-look (30 s), each with none.
# Revision 18's review, by blind author B (R58): pw's look for a unit while the slot is held is a 20 s watch from the holder's slot line (uw.pl), for started.* or a unit process (a child of a holder that is no ps nor sleep, seen 2 s apart), ending
# at the first it finds, since a holder that runs its unit then and ends it when its parent dies leaves nothing for djk's check; pw/held-look is logged with T 20000 and its ms, or none. The look after the release stays 3 s (djk's check, as before).
# Every case follows R12, as in 1292: TMPDIR is a fixture directory under $TMP, the copy runs under a bounded runner (run.pl) that leads its own process group and starts it with INT and QUIT as the case asks and HUP and TERM at their defaults, every wait is bounded (loops too), and when the run has ended the case waits up to 30 s for that group to hold no live process (stopped or running, zombies aside), fails with what it names, and then sends CONT and KILL to those pids. A process outside the group is ended by the pid recorded. No signal goes to a pid found by a pattern.
# Readings taken where the contract leaves room, for the reviewers to confirm:
# - R13 makes the ending outlast a 2 s read with units that ignore TERM (the ending waits 10 s for its roots before STOP and KILL), and FELIX_TEST_SLOT_NOTE=2 (W = 2); the INT case uses units that end at once when signalled;
# - a run ended by USR1 (which the parent does not trap, so the EXIT trap runs the ending) exits with a status that is neither 0 nor the runner's 124: the contract fixes no number for it, and it differs between systems;
# - "no stderr line printed twice" is: no non-empty line of the parent's stderr occurs twice after a second TERM. That case pins only that a second TERM during the ending changes nothing (R27): the parent's own ignore of TERM rests on review, because on bash 3.2 the second TERM is held back until the first trap's exit, and a parent without the ignore then finds every unit ended and exits 143 again;
# - a run's own slot file is found from the run (R28): a planted member writes ${FELIX_TEST_RAN%/*}, the parent's $TMP/pj, to a file of the case's directory, and the case reads slot.* there and nowhere else. It does not guess where mktemp -d put a run's $TMP (GNU mktemp honours TMPDIR, macOS's ignores it), and FELIX_TEST_PART_LOG is empty in a member (part mode has unset it). "The holder's slot line" is line 2 of a slot.I whose first field is the holder's pid;
# - R4's lost-holder case reads: with W = 2 a STOPped holder (a stopped process cannot check its parent) whose wrapper is then killed is ended by the parent alone, and once the parent has exited neither holder nor unit runs. Its second unit ends while the parent is inside that ending (R13's read-back, R28): its line waits in the FIFO behind a @@tick;
# - R15's "within 3 s", 60 s after R56 (a margin: L is the units' 600 s release, the floor 20 s), is timed inside the perl (djk.pl) that takes the ps listing, from the kill to the start of the
#   first listing that shows what was asked for (the listing's own cost is not charged to the run). In pk and pw the holder's R20 ppid check is answered with the -j parent's pid
#   (pphide), so a 60 s window cannot pass a holder that finds the parent gone only by that 10 s check: the kill 0 is what those two names judge. The pc control shows the ps reached and its answer taken: with the -j parent stopped (kill 0 still finds it) a holder's check is answered within 60 s of the gate (pk's and pw's window: 20 s, R20's two periods, would leave D's own 10 s period above a fifth of T, R56);
# - R14 and R21 are told apart from a pid-only stopper by a ps first on PATH (ps/ in this block's directory): it runs the
#   real ps and passes its output on, and once a gate file exists it counts the listings that hold -A, ppid= and lstart=
#   and whose caller is the -j parent's ending (R47: the shim walks its ancestors with the real ps up to the pid in the run's pid file, the -j parent, and counts the call only when the walk reaches it, no process on the walk is a holder (its command line holds
#   " --part " and the case's key), and either nothing, one process (a $( ) or a perl of the -j parent) or an sh behind a perl is between; a call from below a holder or a wrapper, as the listing at 0007:55 made in a holder's ending is, goes to the real ps
#   and is not counted). Each counted call is logged (pscalls: its number, the -j parent's pid and the chain of pid:command from the caller up to the -j parent); the case reads the -j parent's own command line with ps once the run is up and checks, from the log,
#   that every process between each counted call and the -j parent has exactly that command line or is a perl or an sh with no " --part " (a got that names the pid, the command and the chain otherwise: whose call it was); the check does not use the shim's own
#   decision. With DJX_MLOG naming a file the log is appended to it, with the case's name, before the case's directory goes (evidence only).
#   The date is shifted by perl (Time::Local); where its shape is not the one ps prints here, a suffix makes it differ;
# - R22: the holder's ps -o lstart= -p for the unit it forked is the first such call after the gate file (the holder's
#   own was made before it took its first try, while the case held the slot). R47: the block mode holds only a call whose parent, or parent's parent, is the holder (the first word of the skip file); it logs that call's
#   caller (pid, parent pid, command line) to a file of the case, and the case adds a got clause when the caller is not the holder. One case makes every such call print
#   nothing, one holds the first and kills the holder with kill -9 in that window; the unit must not run in either.
# R37 (revision 11, D8 gains a and b) is the block at the end, between "R37 begin" and "R37 end", with R42 (a) and (b) of revision 12 (a skipped name, and the lint over every text file
# under engine/harness but the three tables, with groups and backslash continuations read).
# R41 (revision 12): every nested run has a stand-in mktemp first on PATH (mk/mktemp): given no template argument it passes the same options and the template "$TMPDIR/tmp.XXXXXXXXXX"
# to the host's mktemp, so a nested run's $TMP is made below the case's fixture directory even on macOS, whose mktemp -d ignores TMPDIR, and it logs each path it made to mktemp.log.
# The closing assertion says that the log is not empty (the stand-in was reached) and that every path in it is under this part's own case directories. A case that puts its own PATH
# in _db6_E (the ps shims) has the stand-in directory put in front of that PATH by _db6_run.
# An assertion whose name ends in (control) passes before D is built on purpose.
DB6="$TMP/db6"; mkdir -p "$DB6/n" "$DB6/pp" "$DB6/psshim" "$DB6/mk"
_db6_mkreal="$(command -v mktemp)"
cat > "$DB6/mk/mktemp" <<'DB6MK'
#!/bin/sh
# mktemp for R41: the host's ($DB6_MKREAL), logging each path it made to $DB6_MKLOG. With no template argument (only options) it passes the same options and the template "$TMPDIR/tmp.XXXXXXXXXX".
t=0
for a in "$@"; do case "$a" in -*) ;; *) t=1 ;; esac; done
if [ "$t" = 0 ] && [ -n "${TMPDIR:-}" ]; then   # R41-RULE
  set -- "$@" "${TMPDIR%/}/tmp.XXXXXXXXXX"
fi
out="$("$DB6_MKREAL" "$@")" || exit $?
printf '%s\n' "$out" >> "$DB6_MKLOG"
printf '%s\n' "$out"
DB6MK
chmod +x "$DB6/mk/mktemp"; : > "$DB6/mktemp.log"
_db6_E=(); _db6_I=DEFAULT; _db6_Q=DEFAULT; _db6_lim=600; _db6_S=8; _db6_td=""; _db6_hp=0; _db6_ctl=0; _db6_bg=0; _db6_rc=0; _db6_lab=""
_db6_leak=""; _db6_ino0=""; _db6_late=""; _db6_x=""; _db6_gn=150; _db6_W=""; _db6_twice=""; _db6_ol=""
: > "$DB6/g-empty.tsv"
cat > "$DB6/run.pl" <<'DB6PL'
# run.pl LIMIT INT QUIT PIDFILE CMD...: CMD leads a process group of its own, started with INT and QUIT as given, HUP and TERM at their
# defaults and no descriptor above 2; at LIMIT seconds the group is killed (exit 124). Exits as bash reports CMD's status. R62: PIDFILE.ms gets the run's start-to-exit, in ms.
use POSIX (); use Time::HiRes ();
my ($t, $i, $q, $f) = splice(@ARGV, 0, 4); my $t0 = Time::HiRes::time(); sub ms { if (open(my $h, ">", "$f.ms")) { printf $h "%d\n", (Time::HiRes::time() - $t0) * 1000; close $h } }
my $p = fork;
defined $p or exit 125;
if (!$p) { setpgrp(0, 0); $SIG{INT} = $i; $SIG{QUIT} = $q; $SIG{HUP} = "DEFAULT"; $SIG{TERM} = "DEFAULT"; POSIX::close($_) for 3 .. 255; exec @ARGV; exit 127 }
if (open(my $h, ">", "$f.t")) { print $h "$p\n"; close $h; rename "$f.t", $f }
$SIG{ALRM} = sub { kill "KILL", -$p; ms(); exit 124 };
alarm $t; waitpid $p, 0; ms();
exit(($? & 127) ? 128 + ($? & 127) : $? >> 8);
DB6PL
cat > "$DB6/djk.pl" <<'DB6DJK'
# djk.pl SIG KILLPID WAITFILE MAXMS MODE ARG...: sends SIG to KILLPID (0: none), waits for the file WAITFILE (- : none; at most 600 s, B), takes the time T0, then
# takes ps listings until what MODE asks about has gone or MAXMS ms have passed. MODE pids PID...: those pids; MODE group PGID KEY ID: every live process
# (zombies aside, not this perl) in group PGID or with KEY or ID in its command line. Prints "gone MS" (MS: from T0 to the start of the first listing that
# showed none of them) or "left MS PID,PID...". R61: with DJK_DIR naming a directory (the case's: _db6_djk), each wait also ends once it is gone.
use Time::HiRes qw(time sleep);
my ($sig, $kp, $wf, $max, $mode, @a) = @ARGV; my $dir = $ENV{DJK_DIR} || ""; sub here { $dir eq "" || -d $dir }
kill $sig, $kp if $kp;
if ($wf ne "-") { my $e = time + 600; while (!-e $wf && time < $e && here()) { sleep 0.02 } }
my $t0 = time; my $t; my @left;
while (1) {
  $t = time; @left = ();
  for my $l (split /\n/, `ps -A -ww -o pid= -o pgid= -o stat= -o command= 2>/dev/null`) {
    next unless $l =~ /^\s*(\d+)\s+(\d+)\s+(\S+)\s+(.*)$/;
    my ($p, $g, $s, $c) = ($1, $2, $3, $4);
    next if $s =~ /^Z/ || $p == $$;
    if ($mode eq "pids") { push @left, $p if grep { $_ == $p } @a }
    else { push @left, $p if ($a[0] && $g == $a[0]) || index($c, $a[1]) >= 0 || index($c, $a[2]) >= 0 }
  }
  last if !@left || ($t - $t0) * 1000 > $max || !here();
  sleep 0.05;
}
if (@left) { printf "left %d %s\n", (time - $t0) * 1000, join(",", @left) } else { printf "gone %d\n", ($t - $t0) * 1000 }
DB6DJK
cat > "$DB6/p.pl" <<'DB6P'
# p.pl PIDFILE TERMFILE RFILE ID: writes its pid to PIDFILE, appends a line to TERMFILE for each TERM it gets and goes on running. When RFILE is not -, it first forks a child R that writes
# its pid to RFILE and sleeps (its command line carries ID). R61: P runs, and R sleeps (900 s at most), only while PIDFILE's directory (the case's) exists, each looking for it every 0.1 s or 1 s. It leads a process group of its own: when the run's driver exits, the kernel sends SIGHUP and SIGCONT to a group that has just become orphaned
# and holds a stopped process, so a process stopped in the run's group would be ended by the kernel and a stopper that leaves it stopped could not be seen. P's group is orphaned when the unit dies, before any STOP.
use POSIX ();
POSIX::setpgid(0, 0);
my ($pf, $tf, $rf, $id) = @ARGV; (my $d = $pf) =~ s{/[^/]*$}{};
$SIG{TERM} = sub { if (open(my $h, ">>", $tf)) { print $h "term\n"; close $h } };
if ($rf ne "-") { my $k = fork; defined $k or exit 3; if (!$k) { if (open(my $h, ">", $rf)) { print $h "$$\n"; close $h } exec "perl", "-e", 'sleep 1 while $n++ < 900 && -d $ARGV[0]', $d, $id, "R"; exit 1 } }
if (open(my $h, ">", "$pf.t")) { print $h "$$\n"; close $h; rename "$pf.t", $pf }
select(undef, undef, undef, 0.1) while -d $d;
DB6P
cat > "$DB6/uw.pl" <<'DB6UW'
# uw.pl DIR MS (R58, pw): until MS ms have passed, every 0.2 s while DIR exists (R61), looks for DIR/started.* and for a unit: a live child of a holder (the first field of line 2 of a slot.* in PTMP/pj, PTMP the path in DIR/ptmp, R28) whose command
# line is not a ps's (ps, the shim, an sh that runs ps) nor a sleep's, seen with the same pid and parent at two listings 2 s or more apart (a ps a holder forks has its command line until it execs; one first seen before MS is confirmed after it). Prints none, or what it found "at MS".
use strict; use Time::HiRes qw(time sleep); my ($d, $max) = @ARGV; my $t0 = time; my (%s, $f); sub ls { my ($x, $p) = @_; opendir(my $h, $x) or return (); map { "$x/$_" } grep { index($_, $p) == 0 } readdir $h }
sub hs { open(my $h, "<", "$d/ptmp") or return (); my $t = <$h>; close $h; defined $t or return (); chomp $t; map { my @l; if (open(my $g, "<", $_)) { @l = <$g>; close $g } defined $l[1] && $l[1] =~ /^(\d+)(?:\s|$)/ ? ($1) : () } ls("$t/pj", "slot.") }
while (-d $d) { my $now = time; my $ms = int(($now - $t0) * 1000); my @st = map { m{([^/]*)$} } ls($d, "started."); if (@st) { $f = "started " . join(",", @st) . " at $ms"; last }
  my %h = map { $_ => 1 } hs(); my %k; for (split /\n/, %h ? `ps -A -ww -o pid= -o ppid= -o stat= -o command= 2>/dev/null` : "") { $k{$1} = [$2, $4] if /^\s*(\d+)\s+(\d+)\s+(\S+)\s+(.*?)\s*$/ && $h{$2} && $3 !~ /^Z/ && $4 !~ m{(?:^|[\s/(`;|&])ps(?:[\s);|&`]|$)} && $4 !~ m{^(?:\S*/)?sleep(?: |$)} }
  for (sort keys %k) { if ($s{$_} && $s{$_}[1] == $k{$_}[0] && $now - $s{$_}[0] >= 2) { $f = "unit $_ ($k{$_}[1]) of holder $k{$_}[0] at $ms"; last } } last if defined $f;
  %s = map { $_ => ($s{$_} && $s{$_}[1] == $k{$_}[0] ? $s{$_} : [$now, $k{$_}[0]]) } grep { $ms < $max || $s{$_} } keys %k; last if $ms >= $max && !%s; sleep 0.2 } print defined $f ? $f : "none";
DB6UW
cat > "$DB6/psshim/ps" <<'DB6SH'
#!/usr/bin/env perl
# ps for R14, R21 and R22: the real ps ($DJ6_PSREAL), except by $DJ6_MODE once the file $DJ6_GATE exists.
#   skew:  a listing that holds -A, ppid= and lstart= and whose caller is the -j parent's ending (R47: the pid in the file $DJ6_JP; see the walk below) is counted in $DJ6_CNT and logged in $DJ6_CLOG (the number, the -j parent's pid and the whole chain of
#          pid:command from the caller up to the -j parent, tab-separated). From the second on, the row of the pid in the file $DJ6_P shows a start time one second later (R14). A listing from anywhere else (a holder's, a wrapper's) goes to the real ps, uncounted.
#   twin:  the same count. The first listing leaves out the row of the pid in the file $DJ6_R, the second is as it is, and from the third on the row of $DJ6_P is shifted (R21).
#   blank: a call that holds lstart= and -p, for a pid that is not in the file $DJ6_SKIPF (the holder's own and the parent's), prints nothing and fails: the start time of the unit a holder forked (R22).
#   block: the first such call whose parent, or its parent's parent, is the holder (the first word of $DJ6_SKIPF; R47) (once: mkdir $DJ6_ONCE) writes its pid to $DJ6_BLK, its caller's pid, its caller's parent's pid and its caller's command line to $DJ6_BWHO,
#          waits for the file $DJ6_GO (at most 600 s, B, or until the case directory, $DJ6_GO's, is gone: R61), and then runs the real ps (R22). A call from anywhere else (the -j parent's _par_endp, for one) goes to the real ps.
#   pphide: a call that holds ppid= and -p WRAPPER and no -A, whose chain (its caller, or its caller's parent) reaches a holder, a perl whose command line holds " --part " and $DJ6_KEY, whose own parent is WRAPPER,
#          prints the pid in the file $DJ6_JP, the -j parent's (R15 (a), R20 after R56), and logs the answer to $DJ6_PLOG (the ms, WRAPPER, the pid answered, the chain from the caller up to the holder, each pid:program and its --part argument, not the whole command line, tab-separated). A holder that lacks the kill 0 then never finds the parent gone, as R20's ppid check would within 10 s, inside a 60 s window. Any other call, the first " --part " process on the chain not a perl or not WRAPPER's child, goes to the real ps.
use strict; use Time::Local; use Time::HiRes ();
my @a = @ARGV; my $args = " @a "; my $real = $ENV{DJ6_PSREAL}; my $mode = $ENV{DJ6_MODE} || ""; my $gate = $ENV{DJ6_GATE} || "";
sub real { exec { $real } $real, @a; exit 127 }
sub rd { my ($f) = @_; open(my $h, "<", $f) or return ""; my $l = <$h>; close $h; defined $l or return ""; $l =~ s/\s+$//; $l }
sub pinfo { my ($q) = @_; open(my $u, "-|", $real, "-ww", "-o", "ppid=", "-o", "command=", "-p", $q) or return (0, ""); my $l = <$u>; close $u; defined $l && $l =~ /^\s*(\d+)\s+(.*?)\s*$/ ? ($1, $2) : (0, "") }   # PID: its parent's pid and its command line
real() unless $gate ne "" && -e $gate;
if ($mode eq "pphide") {   # R15 (a) after R56: a holder's ps -o ppid= -p WRAPPER (R20) is answered with the -j parent's pid, so only its kill 0 can find the parent gone
  real() unless $args =~ /ppid=/ && $args !~ / -A / && $args =~ / -p (\d+)/;
  my $w = $1; my $jp = rd($ENV{DJ6_JP} || ""); my $key = $ENV{DJ6_KEY} || ""; my $q = getppid(); my @ch = (); real() unless $jp =~ /^\d+$/ && $key ne "" && $w != $jp;
  for (1 .. 2) { last if $q <= 1 || $q == $jp; my ($pq, $cmd) = pinfo($q); $pq or last; my ($p0) = $cmd =~ /^(\S+)/; my ($pa) = $cmd =~ / --part (\S+)/; push @ch, "$q:" . ($p0 // "") . (defined $pa ? " --part $pa" : ""); if ($cmd =~ / --part / && index($cmd, $key) >= 0) { last unless $cmd =~ /^(?:\S*\/)?perl[0-9.]*(?:\s|$)/ && $pq == $w;
      if (open(my $lg, ">>", $ENV{DJ6_PLOG} || "/dev/null")) { print $lg join("\t", int(Time::HiRes::time() * 1000), $w, $jp, @ch), "\n"; close $lg } print "$jp\n"; exit 0 } $q = $pq }   # the first " --part " process on the chain: a holder (a perl) whose parent is WRAPPER, or no answer
  real();
}
if ($mode eq "blank" || $mode eq "block") {
  real() unless $args =~ /lstart=/ && $args =~ / -p (\d+)/;
  my $t = $1;
  real() if grep { $_ eq $t } split(" ", rd($ENV{DJ6_SKIPF} || ""));
  exit 1 if $mode eq "blank";
  my $hp = (split(" ", rd($ENV{DJ6_SKIPF} || "")))[0]; my $pp = getppid(); my ($ppp, $pcmd) = pinfo($pp);
  real() unless defined $hp && $hp =~ /^\d+$/ && ($pp == $hp || $ppp == $hp);   # R47: only the holder's own call (its parent, or its parent's parent, is the holder) is held; the -j parent's own lstart= calls are not
  real() unless mkdir $ENV{DJ6_ONCE};
  if (open(my $w, ">", "$ENV{DJ6_BWHO}.t")) { print $w "$pp $ppp $pcmd\n"; close $w; rename "$ENV{DJ6_BWHO}.t", $ENV{DJ6_BWHO} }
  if (open(my $h, ">", "$ENV{DJ6_BLK}.t")) { print $h "$$\n"; close $h; rename "$ENV{DJ6_BLK}.t", $ENV{DJ6_BLK} }
  (my $gd = $ENV{DJ6_GO}) =~ s{/[^/]*$}{}; my $n = 0; while (!-e $ENV{DJ6_GO} && -d $gd && $n++ < 6000) { select(undef, undef, undef, 0.1) }   # R61: and ends once the case directory is gone
  real();
}
real() unless $args =~ / -A / && $args =~ /ppid=/ && $args =~ /lstart=/;
# R47: whose call is this? Walk the ancestors with the real ps up to the -j parent (the pid in $DJ6_JP): @ch holds them, nearest first, as pid:command. The call is the -j parent's own ending when the walk reaches the -j parent,
# no process on it is a holder (a command line that holds " --part " and the case's key $DJ6_KEY: a ps below a holder is passed to the real ps, whatever its depth), and either nothing or one process is between (a $( ) subshell, or a perl, of the -j parent)
# or two are and the outer one is a perl (perl's backticks run an sh: a ps of a perl of the -j parent is ps, sh, perl). Anything else is a wrapper's or a holder's call, and goes to the real ps, uncounted.
my $jp = rd($ENV{DJ6_JP} || ""); my $key = $ENV{DJ6_KEY} || ""; my @ch = (); my $found = 0; my $holder = 0;
if ($jp =~ /^\d+$/) {
  my $q = getppid();
  for (1 .. 12) {
    last if $q <= 1;
    if ($q == $jp) { $found = 1; last }
    my ($pq, $cmd) = pinfo($q); $pq or last;
    push @ch, "$q:$cmd"; $holder = 1 if $cmd =~ / --part / && ($key eq "" || index($cmd, $key) >= 0); $q = $pq;
  }
}
my $mine = $found && !$holder && (@ch <= 1 || (@ch == 2 && $ch[1] =~ /^\d+:(?:\S*\/)?perl(?:\s|$)/));
real() unless $mine;
open(my $c, ">>", $ENV{DJ6_CNT}) or real(); print $c "x\n"; close $c;
my $n = 0; if (open(my $c2, "<", $ENV{DJ6_CNT})) { $n++ while <$c2>; close $c2 }
{ if (open(my $lg, ">>", $ENV{DJ6_CLOG} || "/dev/null")) { print $lg join("\t", $n, $jp, @ch), "\n"; close $lg } }   # logged: the number, the -j parent's pid and the chain (pid:command) from the caller up to the -j parent, tab-separated; none when the caller is the -j parent
my $p = rd($ENV{DJ6_P} || ""); my $r = rd($ENV{DJ6_R} || "");
my ($hide, $shift) = ("", "");
if ($mode eq "skew") { $shift = $p if $n >= 2 } elsif ($mode eq "twin") { $hide = $r if $n == 1; $shift = $p if $n >= 3 }
open(my $ps, "-|", $real, @a) or exit 127;
my %m = (Jan => 0, Feb => 1, Mar => 2, Apr => 3, May => 4, Jun => 5, Jul => 6, Aug => 7, Sep => 8, Oct => 9, Nov => 10, Dec => 11);
while (my $l = <$ps>) {
  if ($l =~ /^(\s*(\d+)\s+\d+\s+)(.*?)\s*$/) {
    my ($pre, $pid, $d) = ($1, $2, $3);
    next if $hide ne "" && $pid eq $hide;
    if ($shift ne "" && $pid eq $shift) {
      my $t;
      if ($d =~ /^\w+\s+(\w+)\s+(\d+)\s+(\d+):(\d+):(\d+)\s+(\d+)$/ && exists $m{$1}) { $t = eval { timelocal($5, $4, $3, $2, $m{$1}, $6) } }
      $d = defined $t ? scalar(localtime($t + 1)) : "$d +1s";
      $l = "$pre$d\n";
    }
  }
  print $l;
}
exit 0;
DB6SH
chmod +x "$DB6/psshim/ps"
_db6_until() { local n="$1" i=0; shift; while [ "$i" -lt "$n" ]; do "$@" && return 0; sleep 0.2; i=$((i + 1)); done; "$@"; }
# TEST...: R56, a bound: a wait for what the run makes lasts until the run's bound (_db6_lim s) has passed, and ends with the run (its job _db6_bg gone); then TEST's status
_db6_runw() { local i=0; while [ "$i" -lt $((_db6_lim * 5)) ]; do "$@" && return 0; kill -0 "$_db6_bg" 2>/dev/null || break; sleep 0.2; i=$((i + 1)); done; "$@"; }
# R61: _db6_djk ARG... is djk.pl with the case directory (DJK_DIR). R62, evidence only (nothing without DJX_MLOG, and never a verdict): _db6_ml WORD... appends "1296 WORD..."; _db6_mg CASE T OUT the margin line "1296 margin CASE T T ms MS" from djk.pl's "gone MS" (else none); _db6_mr CASE MSFILE B the run line "1296 run CASE bound B ms MS" from run.pl's PIDFILE.ms
_db6_djk() { DJK_DIR="$_db6_c" perl "$DB6/djk.pl" "$@"; }; _db6_ml() { [ -z "${DJX_MLOG:-}" ] || printf '1296 %s\n' "$*" >> "$DJX_MLOG"; }; _db6_mg() { case "$3" in "gone "*) _db6_ml margin "$1" T "$2" ms "${3#gone }" ;; *) _db6_ml margin "$1" T "$2" ms none ;; esac; }; _db6_mr() { _db6_ml run "$1" bound "$3" ms "$(cat "$2" 2>/dev/null || echo none)"; }
_db6_cnt() { LC_ALL=C awk -v l="$2" '$0 == l { n++ } END { print n + 0 }' "$1" 2>/dev/null || echo 0; }   # FILE LINE: lines that are exactly LINE
_db6_pfx() { LC_ALL=C awk -v p="$2" 'index($0, p) == 1 { n++ } END { print n + 0 }' "$1" 2>/dev/null || echo 0; }   # FILE PREFIX: lines that start with it
_db6_sel() { _db6_c="$DB6/n/$1"; _db6_F="$_db6_c/f"; _db6_T="$_db6_F/engine/harness/tests"; _db6_tmp="${_db6_td:-$_db6_c/tmp}"; }
# CASE GROUPS MANIFEST STUB...: the copy at $DB6/n/CASE and its fixture TMPDIR; 1 when it could not be made. A MANIFEST of + is a manifest of one row for
# each STUB that says ok "djy $DJ6N", so that a run that passes has compared one and leaves a receipt
_db6_new() {
  local n="$1" s m; shift
  _db6_sel "$n"
  rm -rf "$_db6_c"; mkdir -p "$_db6_c" "$_db6_tmp" || return 1
  if [ "${2:-}" = + ]; then
    m="$_db6_c/manifest.gen"; : > "$m"
    for s in "${@:3}"; do ! grep -qF 'ok "djy $DJ6N"' "$s" || printf '1\tdjy %s\n' "${s##*/}" >> "$m"; done
    set -- "$1" "$m" "${@:3}"
  fi
  _suite_copy_tree "$_db6_F" "$@"
}
# ARG...: the copy's driver under run.pl, TMPDIR $_db6_tmp, INT and QUIT as _db6_I and _db6_Q, FELIX_TEST_SLOTS=$_db6_S (none when empty), _db6_E added
_db6_run() {
  local e p=0
  _db6_ea=(); for e in ${_db6_E[@]+"${_db6_E[@]}"}; do case "$e" in PATH=*) e="PATH=$DB6/mk:${e#PATH=}"; p=1 ;; esac; _db6_ea[${#_db6_ea[@]}]="$e"; done
  [ "$p" = 1 ] || _db6_ea[${#_db6_ea[@]}]="PATH=$DB6/mk:$PATH"
  ( cd "$_db6_F" && exec env -u FELIX_TEST_NO_MANIFEST -u FELIX_TEST_JOBS -u FELIX_TEST_SLOTS -u FELIX_TEST_SLOT_NOTE -u FELIX_TEST_PART_LOG \
      -u FELIX_TEST_PART_RAN -u FELIX_TEST_PART_END -u FELIX_TEST_PART_RECORD -u FELIX_TEST_RED_JOBS -u PERL5OPT TMPDIR="$_db6_tmp" \
      DB6_MKREAL="$_db6_mkreal" DB6_MKLOG="$DB6/mktemp.log" ${_db6_S:+FELIX_TEST_SLOTS=$_db6_S} ${_db6_ea[@]+"${_db6_ea[@]}"} perl "$DB6/run.pl" "$_db6_lim" "$_db6_I" "$_db6_Q" "$_db6_c/$_db6_lab.pid" \
      "$BASH" "$_db6_T/run" "$@" )
}
# LABEL ARG...: the run in the background; its pid file is $_db6_c/LABEL.pid (the run's group), its output LABEL.out and LABEL.err
_db6_go() { _db6_lab="$1"; shift; _db6_run "$@" > "$_db6_c/$_db6_lab.out" 2> "$_db6_c/$_db6_lab.err" & _db6_bg=$!; }
_db6_pid() { cat "$_db6_c/$1.pid" 2>/dev/null; }
_db6_gl()  { ps -A -ww -o pid= -o pgid= -o stat= -o command= 2>/dev/null | G="$1" LC_ALL=C awk '$2 == ENVIRON["G"] && $3 !~ /^Z/ { c = $0; sub(/^ *[0-9]+ +[0-9]+ +[^ ]+ +/, "", c); printf "%s:%s:%s\n", $1, $3, substr(c, 1, 50) }'; }
# GROUP: waits up to 30 s for the run's group to hold no live process; what is left goes into _db6_leak, and is continued and killed
_db6_grp() {
  local g="$1" i=0 l p
  [ -n "$g" ] || return 0
  while [ "$i" -lt "$_db6_gn" ]; do [ -z "$(_db6_gl "$g")" ] && break; sleep 0.2; i=$((i + 1)); done
  l="$(_db6_gl "$g")"
  [ -z "$l" ] || _db6_leak="$_db6_leak left in the run's group: $(printf '%s' "$l" | tr '\n' ' ')"
  for p in $(printf '%s\n' "$l" | sed 's/:.*//'); do kill -CONT "$p" 2>/dev/null; kill -KILL "$p" 2>/dev/null; done
}
_db6_wait0() { { wait "$_db6_bg"; } 2>/dev/null; _db6_rc=$?; }
_db6_fin() { _db6_grp "$(_db6_pid "$_db6_lab")"; _db6_mr "${_db6_c##*/}/$_db6_lab" "$_db6_c/$_db6_lab.pid.ms" "$_db6_lim"; _db6_E=(); _db6_I=DEFAULT; _db6_Q=DEFAULT; _db6_lim=600; _db6_S=8; _db6_W=""; _db6_twice=""; }
_db6_wait() { _db6_wait0; _db6_fin; }
# LABEL SIGNAL: SIGNAL to the driver (twice, 0.5 s apart, when _db6_twice is set), then at most the run's bound (R56: a bound, 600 s, was 45 s) for it to end (a run still there is killed by group, and _db6_late says so).
# _db6_stop0 does that and collects the status only; _db6_stop also checks and ends the run's group
_db6_stop0() {
  local p i=0; p="$(_db6_pid "$1")"; _db6_late=""
  [ -z "$p" ] || kill -"$2" "$p" 2>/dev/null
  [ -z "$_db6_twice" ] || { sleep 0.5; [ -z "$p" ] || kill -"$_db6_twice" "$p" 2>/dev/null; }
  while [ "$i" -lt $((_db6_lim * 5)) ]; do kill -0 "$p" 2>/dev/null || break; sleep 0.2; i=$((i + 1)); done
  if kill -0 "$p" 2>/dev/null; then _db6_late=" the parent was still running $_db6_lim s after the signal;"; kill -KILL -- "-$p" 2>/dev/null; fi
}
_db6_stop() { _db6_stop0 "$@"; _db6_wait; }
_db6_rcpt() { if [ -f "$_db6_F/.git/felix-suite-receipt" ]; then echo present; else echo absent; fi; }
_db6_id()   { printf '%s' "${TMP##*/}-${_db6_c##*/}"; }
_db6_key()  { printf '%s' "${DB6#/private}/n/${_db6_c##*/}/"; }
# GROUP: the live pids of the current case's run, for the check: in its group, or with its directory or its id in the command line (not mine at _db6_hp)
_db6_ps() {
  ps -A -ww -o pid= -o pgid= -o stat= -o command= 2>/dev/null | G="${1:-}" K="$(_db6_key)" I="$(_db6_id)" H="$_db6_hp" LC_ALL=C awk \
    '$3 !~ /^Z/ && $1 != ENVIRON["H"] && (($2 == ENVIRON["G"] && ENVIRON["G"] != "") || index($0, ENVIRON["K"]) || index($0, ENVIRON["I"])) { printf "%s ", $1 }'
}
_db6_clear() { [ -z "$(_db6_ps "$1")" ]; }
_db6_alive() { local s; s="$(ps -o stat= -p "$1" 2>/dev/null | tr -d ' ')"; [ -n "$s" ] && [ "${s#Z}" = "$s" ]; }   # PID: there, and not a zombie
_db6_dead()  { ! _db6_alive "$1"; }
_db6_kf() {   # FILE...: ends the pids those files record, each only while its command line still carries the case's id
  local f p
  for f in "$@"; do [ -f "$f" ] || continue
    for p in $(cat "$f" 2>/dev/null); do case "$(ps -o command= -p "$p" 2>/dev/null)" in *"$(_db6_id)"*) kill -CONT "$p" 2>/dev/null; kill -KILL "$p" 2>/dev/null ;; esac; done
  done
}
_db6_inos() {   # TMPDIR: name:kind:inode of each entry of felix-suite-slots, in name order
  perl -e 'for my $f (sort glob("$ARGV[0]/felix-suite-slots/*")) { my @s = lstat($f); (my $n = $f) =~ s{.*/}{}; print "$n:", (-f _ ? "f" : "x"), ":$s[1] " }' "$1"
}
_db6_held() {   # TMPDIR: the slot files under it that some process holds
  perl -e 'use Fcntl ":flock"; for my $f (sort glob("$ARGV[0]/felix-suite-slots/*")) { next unless -f $f; open(my $h, "<", $f) or next; flock($h, LOCK_EX | LOCK_NB) or print "$f "; close $h }' "$1"
}
_db6_up() { test -e "$_db6_c/up.$1"; }
_db6_slotline() {   # PID PART: line 2 of a slot file in the run's own pj directory, which the planted part PART wrote to pj.PART (${FELIX_TEST_RAN%/*}, R28), whose first field is PID, or nothing
  local d f l
  d="$(cat "$_db6_c/pj.$2" 2>/dev/null)"; [ -n "$d" ] || return 1
  for f in "$d"/slot.*; do [ -f "$f" ] || continue; l="$(sed -n 2p "$f" 2>/dev/null)"; case "$l" in "$1 "*) printf '%s' "$l"; return 0 ;; esac; done
  return 1
}
_db6_nslots() { ls "$(cat "$_db6_c/pj.$1" 2>/dev/null)"/slot.* 2>/dev/null | wc -l | tr -d ' '; }   # PART: how many slot files that pj directory holds
_db6_hold() {   # SLOTFILE: a perl of mine holds its lock until _db6_unhold; _db6_hp is its pid
  [ -d "${1%/*}" ] || mkdir -m 0700 "${1%/*}"
  perl -e 'use Fcntl ":flock"; open(my $h, ">>", $ARGV[0]) or exit 4; flock($h, LOCK_EX | LOCK_NB) or exit 3; $| = 1; print "held\n"; my $e = time + 900; sleep 1 while time < $e && -d $ARGV[1]' "$1" "$_db6_c" > "$_db6_c/hold.out" 2>&1 &
  _db6_hp=$!   # R56: it holds 900 s (was 300), past every wait of the case before _db6_unhold, or until the case's directory is gone
  _db6_until 3000 eval '[ -s "$_db6_c/hold.out" ] || ! kill -0 "$_db6_hp" 2>/dev/null'   # a bound, B (was 20 s): until it holds, or has died
}
_db6_unhold() { [ "$_db6_hp" = 0 ] || { kill -KILL "$_db6_hp" 2>/dev/null; { wait "$_db6_hp"; } 2>/dev/null; }; _db6_hp=0; return 0; }
_db6_started() { local f r=""; for f in "$_db6_c"/started.*; do [ -e "$f" ] && r="$r${f##*/} "; done; printf '%s' "$r"; }
# the parent's prelude is done (a mark at the end of the copy's 0006), and the parent's $TMP is recorded in ptmp (the first prelude to run is the parent's)
_db6_pre() { local f; for f in "$_db6_T"/parts/0006-*.sh; do printf '\n[ -e %q ] || printf "%%s\\n" "$TMP" > %q\n: > "%s/pre.done.$$"\n' "$_db6_c/ptmp" "$_db6_c/ptmp" "$_db6_c" >> "$f"; done; }
_db6_pre_up() { ls "$_db6_c"/pre.done.* >/dev/null 2>&1; }
_db6_hpid() {   # the pid on line 2 of the first slot.* of the parent's pj directory that has one (the holder's, R4), or nothing
  local t f l; t="$(cat "$_db6_c/ptmp" 2>/dev/null)"; [ -n "$t" ] || return 1
  for f in "$t"/pj/slot.*; do [ -f "$f" ] || continue; l="$(sed -n 2p "$f" 2>/dev/null)"; [ -n "$l" ] || continue; printf '%s' "${l%% *}"; return 0; done
  return 1
}
_db6_hpid_up() { [ -n "$(_db6_hpid)" ]; }
_db6_only() {   # GROUP PID: waits up to 30 s (R12's drain, was 8 s) for the run to hold no live process but PID (0: none), by its group, its directory or its id (_db6_ps); _db6_ol is what else was there, named
  local g="$1" k="$2" i=0 l="" p
  while [ "$i" -lt 150 ]; do l=""; for p in $(_db6_ps "$g"); do [ "$p" = "$k" ] || l="$l $p:$(ps -o stat= -p "$p" 2>/dev/null | tr -d ' ')"; done; [ -z "$l" ] && break; sleep 0.2; i=$((i + 1)); done
  _db6_ol="${l# }"
}
_db6_pst() {   # PID: runs, stopped or gone
  local s; s="$(ps -o stat= -p "${1:-0}" 2>/dev/null | tr -d ' ')"
  case "$s" in ''|Z*) echo gone ;; *T*) echo stopped ;; *) echo runs ;; esac
}
# "ok", or what an interrupted run left behind: LABEL STATUS (a STATUS of non0 is any but 0 and the runner's 124)
_db6_gone() {
  local l="$1" r="" g; g="$(_db6_pid "$l")"
  case "$2" in
    non0) { [ "$_db6_rc" != 0 ] && [ "$_db6_rc" != 124 ]; } || r="$r exit $_db6_rc, which is 0 or the runner's 124;" ;;
    *) [ "$_db6_rc" = "$2" ] || r="$r exit $_db6_rc, not $2;" ;;
  esac
  [ "$(_db6_cnt "$_db6_c/$l.out" reached)" = 0 ] || r="$r reached was printed;"
  _db6_until 150 _db6_clear "$g" || r="$r still running: $(_db6_ps "$g");"
  [ -z "$(_db6_held "$_db6_tmp")" ] || r="$r a slot is still held;"
  [ -z "$_db6_ino0" ] || [ "$(_db6_inos "$_db6_tmp")" = "$_db6_ino0" ] || r="$r the slot files changed: [$_db6_ino0] became [$(_db6_inos "$_db6_tmp")];"
  [ "$(_db6_rcpt)" = absent ] || r="$r a receipt was left;"
  [ "$_db6_ctl" = 1 ] || r="$r no positive control, so these absences say nothing;"
  printf '%s' "${r:-ok}"
}
# NAME ACTUAL EXPECTED: is, with what the run's group had left added to the actual
_db6_is() { local a="$2"; [ -z "$_db6_leak" ] || a="$a [$_db6_leak ]"; _db6_leak=""; is "$1" "$a" "$3"; }
# CASE FILE: pp/CASE/FILE is stdin behind a header that names the case's directory, id, the part and this block's directory
_db6_w() {
  mkdir -p "$DB6/pp/$1" || return 1
  { printf 'DJ6D=%q; DJ6I=%q; DJ6N=%q; DJ6L=%q\n' "$DB6/n/$1" "${TMP##*/}-$1" "$2" "$DB6"
    printf '%s\n' "printf '\\ndjy-sec %s\\n' \"\$DJ6N\""; cat; } > "$DB6/pp/$1/$2"
}
_db6_long() {   # CASE FILE...: parts that write the pids of the unit and of its parent and the run's own pj directory (R28), note they are up, and wait for a release file (at most B, 600 s, or until the case directory is gone: R61) before they pass
  local c="$1" f; shift
  for f in "$@"; do _db6_w "$c" "$f" <<'X'
printf '%s %s\n' "$$" "$(ps -o ppid= -p $$ 2>/dev/null | tr -d ' ')" > "$DJ6D/pids.$DJ6N"
printf '%s\n' "${FELIX_TEST_RAN%/*}" > "$DJ6D/pj.$DJ6N"
: > "$DJ6D/up.$DJ6N"
_i=0; until [ -e "$DJ6D/release" ] || [ ! -d "$DJ6D" ] || [ "$_i" -ge 3000 ]; do sleep 0.2; _i=$((_i + 1)); done
ok "djy $DJ6N"
X
  done
}
_db6_quick() { _db6_w "$1" "$2" <<'X'
: > "$DJ6D/started.$DJ6N"
ok "djy $DJ6N"
X
}
# CASE FILE: a part that notes it started, waits for the file $DJ6D/release2 (at most B, 600 s, or until the case directory is gone: R61) and passes
_db6_lateq() { _db6_w "$1" "$2" <<'X'
: > "$DJ6D/started.$DJ6N"
_i=0; until [ -e "$DJ6D/release2" ] || [ ! -d "$DJ6D" ] || [ "$_i" -ge 3000 ]; do sleep 0.2; _i=$((_i + 1)); done
ok "djy $DJ6N"
X
}
# ---- end of the helpers
# ---- the control: two quick parts pass under -j 2 and leave a receipt
_db6_quick ctl 0010-qa.sh; _db6_quick ctl 0020-qb.sh; _db6_new ctl "$DB6/g-empty.tsv" + "$DB6/pp/ctl"/*.sh
_db6_go c -j 2; _db6_wait
[ "$_db6_rc" = 0 ] && [ "$(_db6_rcpt)" = present ] && _db6_ctl=1
_db6_is "D6: two quick parts pass under -j 2: exit 0 and a receipt (positive control)" "$_db6_rc $_db6_ctl" "0 1"
rm -rf "$DB6/n/ctl"
# the timing perl: it reports a killed process gone and a living one left, and finds a member of a group by the group and by the id in its command line
_db6_sel djk; mkdir -p "$_db6_c"
perl -e 'sleep 1 while $n++ < 600 && -d $ARGV[0]' "$_db6_c" "$(_db6_id)" djk & _db6_p1=$!   # R61: 600 s at most, and only while the case directory exists
perl -e 'sleep 1 while $n++ < 600 && -d $ARGV[0]' "$_db6_c" "$(_db6_id)" djk & _db6_p2=$!
_db6_y="$(_db6_djk KILL "$_db6_p1" - 20000 pids "$_db6_p1")"; _db6_mg djk/kill 20000 "$_db6_y"; _db6_x="${_db6_y%% *} $(_db6_djk 0 0 - 300 pids "$_db6_p2" | sed 's/ .*//') $(_db6_djk 0 0 - 300 group 0 "$(_db6_id)" "$(_db6_id)" | sed 's/ .*//')"
kill -KILL "$_db6_p1" "$_db6_p2" 2>/dev/null; for _db6_p in "$_db6_p1" "$_db6_p2"; do { wait "$_db6_p"; } 2>/dev/null; done; _db6_y="$(_db6_djk 0 0 - 20000 group 0 "$(_db6_id)" "$(_db6_id)")"; _db6_mg djk/both 20000 "$_db6_y"; _db6_x="$_db6_x ${_db6_y%% *}"
_db6_is "R12: the timing perl reports a killed process gone, a living one left, a process with the case's id in its command line left, and none once both are killed (control)" "$_db6_x" "gone left left gone"
rm -rf "$DB6/n/djk"
# the group check finds a process left in a run's group after its leader has gone, names it, and ends it
_db6_sel gctl; mkdir -p "$_db6_c"; _db6_lab=g
perl "$DB6/run.pl" 600 DEFAULT DEFAULT "$_db6_c/g.pid" bash -c 'perl -e "sleep 1 while \$n++ < 600 && -d \$ARGV[1]" "$0" "$1" gc & exit 0' "$(_db6_id)" "$_db6_c" & _db6_p1=$!   # R61: the sleeper ends with the case directory
{ wait "$_db6_p1"; } 2>/dev/null; _db6_mr gctl/g "$_db6_c/g.pid.ms" 600
_db6_gn=5; _db6_grp "$(_db6_pid g)"; _db6_gn=150
case "$_db6_leak" in *"perl -e sleep 1 while"*) _db6_x=named ;; *) _db6_x="not named [$_db6_leak]" ;; esac   # not inside $( ): bash 3.2 ends the substitution at the pattern's )
_db6_x="$_db6_x $(_db6_until 150 _db6_clear '' && echo gone || echo still)"; _db6_leak=""
is "R12: the group check names a process left in the run's group after the leader exited, and ends it (control)" "$_db6_x" "named gone"
rm -rf "$DB6/n/gctl"

# ---- R13: the parent never waits in an alarm-timed read, so no ending is cut. W is FELIX_TEST_SLOT_NOTE (2 here), so a 2 s read would be cut by an ending of 10 s or more
# CASE SIGNAL STATUS KIND NUNITS: NUNITS parts (KIND ign: they trap TERM, fork a sleeper on it and go on, so the ending waits 10 s for them before STOP and KILL; KIND quick: they end at
# once when signalled), a -j 2 run with W = $_db6_W (the default when empty), SIGNAL to the parent once they are up; _db6_x is "ok", or what was wrong
_db6_sig() {
  local c="$1" sg="$2" st="$3" kind="$4" nu="${5:-1}" tw="$_db6_twice" r="" g f d=""
  for f in 0010-ka.sh 0020-kb.sh; do
    [ "$f" = 0010-ka.sh ] || [ "$nu" = 2 ] || continue
    if [ "$kind" = ign ]; then _db6_w "$c" "$f" <<'X'
trap 'perl -e "sleep 1 while \$n++ < 900 && -d \$ARGV[0]" "$DJ6D" "$DJ6I" gc & echo $! >> "$DJ6D/gc.pids"' TERM
: > "$DJ6D/up.$DJ6N"
while [ -d "$DJ6D" ]; do sleep 0.1; done
X
    else _db6_w "$c" "$f" <<'X'
: > "$DJ6D/up.$DJ6N"
_i=0; until [ -e "$DJ6D/release" ] || [ ! -d "$DJ6D" ] || [ "$_i" -ge 3000 ]; do sleep 0.2; _i=$((_i + 1)); done
X
    fi
  done
  _db6_new "$c" "$DB6/g-empty.tsv" + "$DB6/pp/$c"/*.sh || { _db6_x="the copy could not be made"; return 0; }
  [ -z "$_db6_W" ] || _db6_E=(FELIX_TEST_SLOT_NOTE="$_db6_W")
  _db6_go i -j 2
  _db6_runw _db6_up 0010-ka.sh || r=" no unit came up;"
  [ "$nu" != 2 ] || _db6_runw _db6_up 0020-kb.sh || r="$r the second unit did not come up;"
  _db6_ino0="$(_db6_inos "$_db6_tmp")"; [ -n "$_db6_ino0" ] || r="$r no slot file before the signal;"
  sleep 0.5
  _db6_stop i "$sg"; r="$r$_db6_late"
  g="$(_db6_gone i "$st")"; _db6_ino0=""; [ "$g" = ok ] || r="$r$g"
  [ "$kind" != ign ] || [ -s "$_db6_c/gc.pids" ] || r="$r the TERM never reached a unit;"
  d="$(LC_ALL=C grep -v '^$' "$_db6_c/i.err" 2>/dev/null | LC_ALL=C sort | uniq -d | head -n 2 | tr '\n' '|')"
  [ -z "$tw" ] || [ -z "$d" ] || r="$r a stderr line was printed twice: $d"
  _db6_kf "$_db6_c/gc.pids"
  _db6_x="${r:-ok}"; rm -rf "$_db6_c"
}
_db6_W=2; _db6_sig r13-term TERM 143 ign 1
_db6_is "R13: with FELIX_TEST_SLOT_NOTE=2 (W is 2, so the ending outlasts what a 2 s read -t left it) and a unit that ignores TERM, TERM to the parent once the unit is up: exit 143, no reached, nothing of the run left, stopped or running, no slot held, the slot files kept, no receipt" "$_db6_x" ok
_db6_W=2; _db6_sig r13-int INT 130 quick 2
_db6_is "R13: the same with INT, sent to a parent started with INT at its default, and two units that end at once when signalled (W is 2): exit 130, with the same afterwards" "$_db6_x" ok
_db6_W=2; _db6_sig r13-usr1 USR1 non0 ign 2
_db6_is "R13: USR1, which the parent does not trap, sent while two units that ignore TERM run (W is 2): the EXIT trap's ending completes: a status that is not 0, no reached, nothing of the run left, stopped or running, no slot held, the slot files kept, no receipt" "$_db6_x" ok
_db6_W=""; _db6_twice=TERM; _db6_sig d6-twice TERM 143 ign 1
_db6_is "D6: a second TERM sent to the parent during its ending changes nothing: exit 143, nothing of the run left, stopped or running, no slot held, no receipt, and no line of its stderr printed twice" "$_db6_x" ok

# ---- R4: the parent's own ending of a lost unit's holder. A stopped holder cannot check its parent, so with its wrapper killed (W = 2: the parent finds the wrapper gone within a few seconds) only the parent can end it.
# R13/R28: the second unit ends while the parent is inside that ending (about 10 s: a stopped holder answers kill -0), so its line waits in the FIFO behind at least one @@tick, and the first look at the
# wrappers after the ending finds its wrapper gone. The unit still reads as ok: a build that marks a wrapper found gone lost at once, or waits only for the next @@tick, fails it.
_db6_long lh 0010-lh.sh; _db6_lateq lh 0020-lr.sh
_db6_new lh "$DB6/g-empty.tsv" + "$DB6/pp/lh"/*.sh
_db6_E=(FELIX_TEST_SLOT_NOTE=2); _db6_go l -j 2
_db6_r=""
_db6_runw _db6_up 0010-lh.sh || _db6_r=" the unit did not come up;"
read -r _db6_u _db6_h < "$_db6_c/pids.0010-lh.sh" 2>/dev/null
_db6_wr="$(ps -o ppid= -p "${_db6_h:-0}" 2>/dev/null | tr -d ' ')"
_db6_sl="$(_db6_slotline "${_db6_h:-0}" 0010-lh.sh >/dev/null && echo slot-line || echo "no-slot-line[holder ${_db6_h:-none}: pj [$(cat "$_db6_c/pj.0010-lh.sh" 2>/dev/null)], $(_db6_nslots 0010-lh.sh) slot files in it]")"
if [ -n "${_db6_u:-}" ] && [ -n "${_db6_h:-}" ] && [ -n "$_db6_wr" ] && [ "$_db6_wr" -gt 1 ]; then
  _db6_runw test -e "$_db6_c/started.0020-lr.sh" || _db6_r="$_db6_r the second unit never started;"
  kill -STOP "$_db6_h" 2>/dev/null; kill -KILL "$_db6_wr" 2>/dev/null
  sleep 0.6; _db6_runw eval '_db6_st="$(ps -o stat= -p "$_db6_h" 2>/dev/null | tr -d " ")"; case "$_db6_st" in *T*|""|Z*) true ;; *) false ;; esac'   # R56: a bound (was a look 0.6 s after the stop): until it reads stopped, or gone
  case "$_db6_st" in *T*) ;; *) _db6_r="$_db6_r the holder was not seen stopped after the stop (stat [$_db6_st]);" ;; esac
  sleep 4; : > "$_db6_c/release2"   # about 5 s after the kill (R28): inside the parent's ending of the stopped holder, which lasts its 10 s wait; a pause, which no load can fail on D's build
  _db6_wait0
  _db6_alive "$_db6_h" && _db6_r="$_db6_r the stopped holder $_db6_h still ran after the parent had exited;"
  _db6_alive "$_db6_u" && _db6_r="$_db6_r its unit $_db6_u still ran after the parent had exited;"
else _db6_r="$_db6_r no unit, holder and wrapper pids were found [$_db6_u $_db6_h $_db6_wr];"; _db6_wait0
fi
_db6_x="$_db6_rc $(_db6_cnt "$_db6_c/l.out" '  FAIL  part ended without its mark: 0010-lh.sh') $(_db6_pfx "$_db6_c/l.out" '  FAIL  part ended without its mark: 0020-lr.sh') $(_db6_cnt "$_db6_c/l.out" '  ok    djy 0020-lr.sh') $(_db6_rcpt) $_db6_sl${_db6_r}"
_db6_kf "$_db6_c/pids.0010-lh.sh"; _db6_fin
_db6_is "R4: a holder STOPped and its wrapper then killed with kill -9, W = 2: the parent ends the lost unit's holder (its pid and start time are line 2 of the slot file, found in the run's own pj directory): once the parent has exited the holder and its unit are gone, the unit failed without its mark, exit 1, no receipt" "$_db6_x" "1 1 0 1 absent slot-line"
rm -rf "$DB6/n/lh"

# ---- the control of pk's and pw's ps (mode pphide): the -j parent STOPped, not killed, so a holder's kill 0 still finds it, and the gate set once the unit is up. The holder's ps -o ppid= -p WRAPPER (R20: every 10 s) is answered with the
# -j parent's pid, the ps's log naming that holder as the caller, within 60 s of the gate (R56, a margin, pk's and pw's own: floor 20 s, a ps forks; L: a holder with no such check while its unit runs, or a ps never reached, never answers), and the unit runs on: the holder's next check is answered too (a bound, B), and the unit then runs. Then the parent is continued and the unit released.
_db6_long pc 0010-pc.sh; _db6_new pc "$DB6/g-empty.tsv" + "$DB6/pp/pc"/*.sh
_db6_E=(PATH="$DB6/psshim:$PATH" DJ6_PSREAL="$(command -v ps)" DJ6_MODE=pphide DJ6_GATE="$_db6_c/gate" DJ6_JP="$_db6_c/q.pid" DJ6_KEY="$(_db6_key)" DJ6_PLOG="$_db6_c/pplog")
_db6_go q -j 2; _db6_r=""; _db6_runw _db6_up 0010-pc.sh || _db6_r=" the unit did not come up;"
read -r _db6_u _db6_h < "$_db6_c/pids.0010-pc.sh" 2>/dev/null; _db6_g="$(_db6_pid q)"; _db6_wr="$(ps -o ppid= -p "${_db6_h:-0}" 2>/dev/null | tr -d ' ')"
[ -z "$_db6_g" ] || kill -STOP "$_db6_g" 2>/dev/null; _db6_t0="$(perl -MTime::HiRes=time -e 'open(my $h, ">", $ARGV[0]) && close $h; printf "%d", time * 1000' "$_db6_c/gate")"
_db6_runw eval '[ "$(cat "$_db6_c/pplog" 2>/dev/null | LC_ALL=C awk "END { print NR }")" -ge 2 ]'; _db6_st="$(_db6_pst "${_db6_u:-0}")"
_db6_x="$(LC_ALL=C awk -F'\t' -v w="${_db6_wr:-x}" -v j="${_db6_g:-x}" -v h="${_db6_h:-x}" -v t="${_db6_t0:-0}" '$2 == w && $3 == j && index($NF, h ":") == 1 { n++; if (n == 1) d = $1 - t } END { if (n && d <= 60000) print "answered"; else printf "not-answered-within-60-s[%d answers, the first %d ms after the gate]", n, d }' "$_db6_c/pplog" 2>/dev/null)"
_db6_x="${_db6_x:-not-answered[no log]} $_db6_st$([ "$(cat "$_db6_c/pplog" 2>/dev/null | LC_ALL=C awk 'END { print NR }')" -ge 2 ] || echo " the holder's next check was not answered;")$_db6_r"
[ -z "$_db6_g" ] || kill -CONT "$_db6_g" 2>/dev/null; : > "$_db6_c/release"; _db6_wait0; _db6_kf "$_db6_c/pids.0010-pc.sh"; _db6_fin; [ -z "${DJX_MLOG:-}" ] || sed "s/^/pc pplog gate=${_db6_t0:-none} /" "$_db6_c/pplog" >> "$DJX_MLOG" 2>/dev/null   # evidence only
_db6_ml margin pc T 60000 ms "$(LC_ALL=C awk -F'\t' -v w="${_db6_wr:-x}" -v j="${_db6_g:-x}" -v h="${_db6_h:-x}" -v t="${_db6_t0:-0}" '$2 == w && $3 == j && index($NF, h ":") == 1 { print $1 - t; f = 1; exit } END { if (!f) print "none" }' "$_db6_c/pplog" 2>/dev/null || echo none)"   # R62: the first answer, ms after the gate
_db6_is "R20: with the -j parent stopped, not killed, so a holder's kill 0 still finds it, pk's and pw's ps answers the holder's ps -o ppid= -p WRAPPER with the -j parent's pid within 60 s of its gate, its log naming the holder as the caller, and the unit runs on: the holder's next check is answered too and the unit is then running (the control of pk's and pw's ps)" "$_db6_x" "answered runs"
rm -rf "$DB6/n/pc"

# ---- R15 (a): the parent killed with kill -9 runs no trap, so each holder finds its parent gone by its kill 0 (R56: a ps answers R20's ppid check with the -j parent's pid, which alone would find it within 10 s): within 60 s no holder or unit of the run is left, stopped or running, and every slot's file grants a lock
_db6_long pk 0010-pa.sh 0020-pb.sh; _db6_new pk "$DB6/g-empty.tsv" + "$DB6/pp/pk"/*.sh
_db6_E=(PATH="$DB6/psshim:$PATH" DJ6_PSREAL="$(command -v ps)" DJ6_MODE=pphide DJ6_GATE="$_db6_c/gate" DJ6_JP="$_db6_c/p.pid" DJ6_KEY="$(_db6_key)" DJ6_PLOG="$_db6_c/pplog")
_db6_go p -j 2
_db6_r=""; _db6_runw _db6_up 0010-pa.sh || _db6_r=" no unit came up;"; _db6_runw _db6_up 0020-pb.sh || _db6_r="$_db6_r the second unit did not come up;"
: > "$_db6_c/gate"   # once both units are up (each has read its own parent with ps): from now on a holder's ps -o ppid= -p WRAPPER is answered with the -j parent's pid
_db6_ino0="$(_db6_inos "$_db6_tmp")"; _db6_g="$(_db6_pid p)"; sleep 0.5
_db6_y="$(_db6_djk KILL "$_db6_g" - 60000 group "$_db6_g" "$(_db6_key)" "$(_db6_id)")"; _db6_mg pk 60000 "$_db6_y"
case "$_db6_y" in gone*) ;; *) _db6_r="$_db6_r the run was not gone within 60 s of its parent's kill -9 ($_db6_y);" ;; esac
_db6_hl="$(_db6_held "$_db6_tmp")"; [ -z "$_db6_hl" ] || _db6_r="$_db6_r a slot was still held: $_db6_hl;"
[ "$_db6_ino0" = "$(_db6_inos "$_db6_tmp")" ] || _db6_r="$_db6_r the slot files changed;"
_db6_wait0; _db6_x="$_db6_rc $(_db6_rcpt) $(_db6_cnt "$_db6_c/p.out" reached)${_db6_r}"
_db6_kf "$_db6_c/pids.0010-pa.sh" "$_db6_c/pids.0020-pb.sh"; _db6_fin; _db6_ino0=""; [ -z "${DJX_MLOG:-}" ] || { printf 'pk pphide-answers %s\n' "$(cat "$_db6_c/pplog" 2>/dev/null | LC_ALL=C awk 'END { print NR }')"; sed 's/^/pk pplog /' "$_db6_c/pplog" 2>/dev/null; } >> "$DJX_MLOG" 2>/dev/null   # evidence only
_db6_is "R15: the parent killed with kill -9 while two units run a long member, a holder's ps -o ppid= -p WRAPPER answered with the -j parent's pid: within 60 s nothing of the run runs, stopped or not, and every slot file grants its lock (the parent's status is 137, no receipt, no reached)" "$_db6_x" "137 absent 0"
rm -rf "$DB6/n/pk"

# ---- R15 (b): a holder killed with kill -9 frees its slot at once while its unit runs on below pid 1: within 60 s the unit is gone, and the run fails naming it
_db6_long hh 0010-hh.sh; _db6_quick hh 0020-hq.sh; _db6_new hh "$DB6/g-empty.tsv" + "$DB6/pp/hh"/*.sh
_db6_go h -j 2
_db6_r=""; _db6_runw _db6_up 0010-hh.sh || _db6_r=" the unit did not come up;"
read -r _db6_u _db6_h < "$_db6_c/pids.0010-hh.sh" 2>/dev/null
_db6_sl="$(_db6_slotline "${_db6_h:-0}" 0010-hh.sh >/dev/null && echo slot-line || echo "no-slot-line[holder ${_db6_h:-none}: pj [$(cat "$_db6_c/pj.0010-hh.sh" 2>/dev/null)], $(_db6_nslots 0010-hh.sh) slot files in it]")"; _db6_y=""
if [ -n "${_db6_u:-}" ] && [ -n "${_db6_h:-}" ] && [ "$_db6_h" -gt 1 ]; then
  _db6_y="$(_db6_djk KILL "$_db6_h" - 60000 pids "$_db6_u")"
  case "$_db6_y" in gone*) ;; *) _db6_r="$_db6_r the unit was not gone within 60 s of its holder's kill -9 ($_db6_y);" ;; esac
else _db6_r="$_db6_r no unit and holder pids were found [$_db6_u $_db6_h];"
fi
_db6_mg hh 60000 "$_db6_y"; _db6_wait0
_db6_until 150 _db6_clear "$(_db6_pid h)" || _db6_r="$_db6_r still running after the parent had exited: $(_db6_ps "$(_db6_pid h)");"
_db6_x="$_db6_rc $(_db6_cnt "$_db6_c/h.out" '  FAIL  part ended without its mark: 0010-hh.sh') $(_db6_pfx "$_db6_c/h.out" '  FAIL  part ended without its mark: 0020-hq.sh') $(_db6_rcpt) $_db6_sl [$(_db6_held "$_db6_tmp")]${_db6_r}"
_db6_kf "$_db6_c/pids.0010-hh.sh"; _db6_fin
_db6_is "R15: a holder killed with kill -9 while its unit runs a member (its pid is line 2 of the slot file): within 60 s the unit is gone, the run fails naming it (part ended without its mark), the other unit passes, exit 1, no receipt, no slot held, and nothing of the run is left" "$_db6_x" "1 1 0 absent slot-line []"
rm -rf "$DB6/n/hh"

# ---- R14: a stopper signals a member only while a listing shows its pid with its start time (R28). A unit starts P with &, which writes its pid, logs each TERM it gets and goes on running. A ps first on
# PATH shows P's start one second later from the ending's second listing on. The unit dies on the ending's TERM before that listing, so P (under pid 1 by then) is a member held with its first
# listing's start time, and is not present in the second: a stopper that signals by pid alone STOPs and KILLs it. R21's twin (mode twin): R, a child P starts, is left out of the first listing and shown
# from the second, so the second listing adds a member and step 4 makes a second round with the third listing, where P's start is shifted after P was sent STOP; P ignores TERM. What a stopper has
# stopped it signals by its pid from then on, so P and R are gone; a build without that leaves P stopped.
# JPFILE LOG N JCMD: R47. Nothing when the log holds N or more lines and every call in it came from the -j parent's ending, else what was wrong, saying whose call it was. The shim logs, for each call it counted, the chain of pid:command from the
# caller up to the -j parent (tab-separated, after the call's number and the -j parent's pid). JCMD is the -j parent's own command line, read by the case with ps after the run was up (the shim never sees it): a process between the call and the -j
# parent is its ending's only when its command line is exactly JCMD (a $( ) of the -j parent) or it is a perl or an sh whose command line holds no " --part " (a probe, or the sh of a perl's backticks); anything else, a holder's perl (it holds
# " --part "), a unit, a wrapper of another command line, fails with "listing K was called by PID (COMMAND, chain ...), not by the -j parent's ending (pid J)". The check does not use the shim's own decision (its holder test and its depth)
_db6_who() {
  LC_ALL=C awk -F'\t' -v j="$(cat "$1" 2>/dev/null)" -v jc="$4" -v want="$3" '
    BEGIN { if (j == "") printf " the -j parent'"'"'s pid is not known, so whose calls were counted cannot be told;"
            if (jc == "") printf " the -j parent'"'"'s command line was not read, so whose calls were counted cannot be told;" }
    { k++; bad = ""; ch = ""
      if (j != "" && $2 != j) printf " listing %s was counted against pid %s, not the -j parent (pid %s);", $1, $2, j
      for (i = 3; i <= NF; i++) {
        x = $i; q = index(x, ":"); pid = substr(x, 1, q - 1); cmd = substr(x, q + 1); ch = ch (i > 3 ? ", " : "") pid ":" substr(cmd, 1, 40)
        if (cmd == jc) continue
        if (cmd ~ /^([^ ]*\/)?(perl|sh)( |$)/ && index(cmd, " --part ") == 0) continue
        if (bad == "") bad = pid " (" substr(cmd, 1, 60) ", chain " }
      if (bad != "" && jc != "") printf " listing %s was called by %s%s), not by the -j parent'"'"'s ending (pid %s);", $1, bad, ch, j }
    END { if (k + 0 < want + 0) printf " the log of counted calls holds %d lines, not the %d listings counted;", k, want }' "$2" 2>/dev/null
}
# CASE MODE: _db6_x is "ok", or what was wrong
_db6_pr() {
  local c="$1" m="$2" r="" g p q lc w jc
  _db6_w "$c" 0010-pa.sh <<'X'
_ra="$(cat "$DJ6D/rarg")"
perl "$DJ6L/p.pl" "$DJ6D/p.pid" "$DJ6D/p.terms" "$_ra" "$DJ6I" &
_i=0
until [ -s "$DJ6D/p.pid" ] && { [ "$_ra" = - ] || [ -s "$_ra" ]; }; do [ "$_i" -lt 6000 ] && [ -d "$DJ6D" ] || break; sleep 0.1; _i=$((_i + 1)); done
: > "$DJ6D/up.$DJ6N"
wait
X
  _db6_new "$c" "$DB6/g-empty.tsv" + "$DB6/pp/$c"/0010-pa.sh || { _db6_x="the copy could not be made"; return 0; }
  if [ "$m" = twin ]; then printf '%s' "$_db6_c/r.pid" > "$_db6_c/rarg"; else printf '%s' - > "$_db6_c/rarg"; fi
  _db6_E=(PATH="$DB6/psshim:$PATH" DJ6_PSREAL="$(command -v ps)" DJ6_MODE="$m" DJ6_GATE="$_db6_c/gate" DJ6_CNT="$_db6_c/pscnt" DJ6_P="$_db6_c/p.pid" DJ6_R="$_db6_c/r.pid" DJ6_JP="$_db6_c/i.pid" DJ6_CLOG="$_db6_c/pscalls" DJ6_KEY="$(_db6_key)")
  _db6_go i -j 2
  _db6_runw _db6_up 0010-pa.sh || r=" no unit came up;"
  jc="$(ps -ww -o command= -p "$(cat "$_db6_c/i.pid" 2>/dev/null)" 2>/dev/null | sed 's/^ *//; s/ *$//')"   # R47: the -j parent's command line, read once now that it is up (the shim does not see it)
  sleep 0.5; : > "$_db6_c/gate"
  _db6_stop0 i TERM; r="$r$_db6_late"; _db6_wait0
  g="$(_db6_pid i)"; p="$(cat "$_db6_c/p.pid" 2>/dev/null)"; q="$(cat "$_db6_c/r.pid" 2>/dev/null)"
  [ -n "$p" ] || r="$r P never wrote its pid;"
  if [ "$m" = twin ]; then _db6_only "$g" 0; w=3; else _db6_only "$g" "${p:-0}"; w=2; fi
  lc="$(wc -l < "$_db6_c/pscnt" 2>/dev/null | tr -d ' ')"; [ "${lc:-0}" -ge "$w" ] 2>/dev/null || r="$r the ending asked for ${lc:-0} listings, so listing $w never came;"
  r="$r$(_db6_who "$_db6_c/i.pid" "$_db6_c/pscalls" "${lc:-0}" "$jc")"   # R47: every listing it counted, so every one it failed or shifted, was the -j parent's
  if [ "$m" = twin ]; then _db6_x="$_db6_rc P-$(_db6_pst "${p:-0}") R-$(_db6_pst "${q:-0}") ${_db6_ol:-none-else} [$(_db6_held "$_db6_tmp")] $(_db6_cnt "$_db6_c/i.out" reached) $(_db6_rcpt)${r}"
  else _db6_x="$_db6_rc P-$(_db6_pst "${p:-0}") terms-$(wc -l < "$_db6_c/p.terms" 2>/dev/null | tr -d ' ') ${_db6_ol:-none-else} [$(_db6_held "$_db6_tmp")] $(_db6_cnt "$_db6_c/i.out" reached) $(_db6_rcpt)${r}"
  fi
  [ -z "${DJX_MLOG:-}" ] || sed "s/^/${c} pscalls /" "$_db6_c/pscalls" >> "$DJX_MLOG" 2>/dev/null   # evidence only: the counted calls and their callers
  _db6_kf "$_db6_c/p.pid" "$_db6_c/r.pid"; _db6_fin; rm -rf "$_db6_c"
}
_db6_pr r14 skew
_db6_is "R14: a ps that shows planted process P's start one second later from the ending's second listing on: once the parent has exited with 143, P still runs, is not stopped, got exactly one TERM, and nothing else of the run is left, stopped or running (a stopper that signals by pid alone STOPs and KILLs it)" "$_db6_x" "143 P-runs terms-1 none-else [] 0 absent"
_db6_pr r21 twin
_db6_is "R21: with R, P's child, left out of the ending's first listing and shown from the second, so that step 4 makes a second round, and P's start shifted from the third listing on, after P was sent STOP, P that ignores TERM and R are both gone once the parent has exited with 143, nothing of the run left stopped or running (what a stopper has stopped it signals by its pid)" "$_db6_x" "143 P-gone R-gone none-else [] 0 absent"

# ---- R15 (a), R20: the parent killed with kill -9 while a holder WAITS for a slot (R28, R36). One slot, its lock held by a perl of mine, two parts: once the parent's prelude has ended, a holder has written its slot line
# (_db6_hpid_up) and the watch below has ended (the holder tries each slot, then waits 1 s and tries again, so polls have run) the parent is killed with kill -9. After the prelude's mark the parent still sources 0007 and
# the lib files before it forks a wrapper, so a kill 2 s after the mark could land before any holder existed and pass for every build. Within 60 s nothing of the run is left, stopped or running; and once I let the slot go no unit
# starts. A holder that checks the parent only while its unit runs outlives the run, waiting. R58 after review: the look for a unit run while the slot is held elsewhere is a watch of 20 s from the holder's slot line (uw.pl: started.*, or a
# unit process, a holder's child that is no ps nor sleep, seen 2 s apart), ending at the first it finds, so a holder that runs its unit then and ends it when its parent dies is seen before the kill. The look 3 s after the slot is let go
# stays short: the holder it watches for (one that outlives the parent, then starts a unit) is still there at djk's end, so djk's 60 s check in the same name (by group, directory or id) names it
_db6_quick pw 0010-wa.sh; _db6_quick pw 0020-wb.sh; _db6_td="$DB6/td-pw"; rm -rf "$_db6_td"; mkdir -p "$_db6_td"; _db6_new pw "$DB6/g-empty.tsv" + "$DB6/pp/pw"/*.sh
_db6_pre; _db6_hold "$_db6_tmp/felix-suite-slots/0"; _db6_ino0="$(_db6_inos "$_db6_tmp")"
_db6_E=(PATH="$DB6/psshim:$PATH" DJ6_PSREAL="$(command -v ps)" DJ6_MODE=pphide DJ6_GATE="$_db6_c/gate" DJ6_JP="$_db6_c/w.pid" DJ6_KEY="$(_db6_key)" DJ6_PLOG="$_db6_c/pplog")
_db6_S=1; : > "$_db6_c/gate"; _db6_go w -j 2   # no unit runs here, so the ps answers a holder's ps -o ppid= -p WRAPPER with the -j parent's pid from the start
_db6_r=""; _db6_runw _db6_pre_up || _db6_r=" the parent's prelude never ended;"
_db6_runw _db6_hpid_up || _db6_r="$_db6_r no holder wrote its slot line before the kill;"
_db6_y="$(perl "$DB6/uw.pl" "$_db6_c" 20000)"   # R58 after review: the watch for a unit while the slot is held, 20 s from the holder's slot line, ending at the first it finds; R62: logged with its ms, or none
case "$_db6_y" in none) _db6_ml margin pw/held-look T 20000 ms none; [ -z "$(_db6_started)" ] || _db6_r="$_db6_r a unit ran while the slot was held elsewhere ($(_db6_started));" ;; "") _db6_r="$_db6_r the watch for a unit while the slot was held gave nothing;" ;; *) _db6_r="$_db6_r a unit ran while the slot was held elsewhere ($_db6_y);"; _db6_ml margin pw/held-look T 20000 ms "${_db6_y##* at }" ;; esac
_db6_g="$(_db6_pid w)"
_db6_y="$(_db6_djk KILL "$_db6_g" - 60000 group "$_db6_g" "$(_db6_key)" "$(_db6_id)")"; _db6_mg pw 60000 "$_db6_y"; _db6_ml margin pw/released-look T 3000 ms none   # R62: the watch after the release (R58), with none
case "$_db6_y" in gone*) ;; *) _db6_r="$_db6_r the run was not gone within 60 s of its parent's kill -9 ($_db6_y);" ;; esac
_db6_unhold; sleep 3
[ -z "$(_db6_started)" ] || _db6_r="$_db6_r a unit started once the slot was let go ($(_db6_started));"
[ -z "$(_db6_held "$_db6_tmp")" ] || _db6_r="$_db6_r a slot is held;"
[ "$_db6_ino0" = "$(_db6_inos "$_db6_tmp")" ] || _db6_r="$_db6_r the slot files changed;"
_db6_wait0; _db6_x="$_db6_rc $(_db6_rcpt) $(_db6_cnt "$_db6_c/w.out" reached)${_db6_r}"
[ -z "${DJX_MLOG:-}" ] || { printf 'pw pphide-answers %s\n' "$(cat "$_db6_c/pplog" 2>/dev/null | LC_ALL=C awk 'END { print NR }')"; sed 's/^/pw pplog /' "$_db6_c/pplog" 2>/dev/null; } >> "$DJX_MLOG" 2>/dev/null   # evidence only
_db6_fin; _db6_ino0=""; _db6_td=""
_db6_is "R20: the parent killed with kill -9 while its holders wait for the only slot, held by another process, a holder's ps -o ppid= -p WRAPPER answered with the -j parent's pid: within 60 s nothing of the run is left, stopped or running; once the slot is let go no unit starts, and every slot file grants its lock (the parent's status is 137, no receipt, no reached)" "$_db6_x" "137 absent 0"
rm -rf "$DB6/n/pw" "$DB6/td-pw"

# ---- R22: no unit runs before unit.I is written. With the only slot held by a perl of mine, the holder has made its own ps call (its slot line is there); then a gate file starts a ps first on PATH that treats
# the next ps -o lstart= -p for any pid but the holder's and the parent's, which is the unit the holder forked, as the case asks, and I let the slot go.
# blank: every such call prints nothing (the holder takes it five times, 0.2 s apart, and gives up): the unit never runs, has no mark and the run fails. block: the first is held while the holder is killed with
# kill -9, and then let through: the forked unit, held back until unit.I is written, must find its holder gone and exit without running the member. R58: in block mode the look for started.*
# is a watch for a unit a holder ran before unit.I (revision 6's holder), left below pid 1 when the holder is killed, which the run does not wait for: it was 4 s after go and the run's end, which load
# could outrun. It now comes once nothing of the run is left by group, directory or id (_db6_clear; 30 s at most, R12's drain), so that unit has written started.* before it ended, or is still there and
# named (the name's "nothing of the run is left"); on D's build nothing is left and it costs nothing. The 4 s pause is gone
# CASE MODE: _db6_x is "ok" or what was wrong
_db6_u22() {
  local c="$1" m="$2" r="" h par
  _db6_quick "$c" 0010-ua.sh
  _db6_td="$DB6/td-$c"; rm -rf "$_db6_td"; mkdir -p "$_db6_td"
  _db6_new "$c" "$DB6/g-empty.tsv" + "$DB6/pp/$c"/0010-ua.sh || { _db6_x="the copy could not be made"; _db6_td=""; return 0; }
  _db6_pre; _db6_hold "$_db6_tmp/felix-suite-slots/0"
  _db6_E=(PATH="$DB6/psshim:$PATH" DJ6_PSREAL="$(command -v ps)" DJ6_MODE="$m" DJ6_GATE="$_db6_c/gate" DJ6_ONCE="$_db6_c/once" DJ6_BLK="$_db6_c/blk" DJ6_GO="$_db6_c/go" DJ6_SKIPF="$_db6_c/skip" DJ6_BWHO="$_db6_c/bwho")
  _db6_S=1; _db6_go u -j 2
  _db6_runw _db6_pre_up || r=" the parent's prelude never ended;"
  _db6_runw _db6_hpid_up || r="$r the holder never wrote its slot line;"
  h="$(_db6_hpid)"; par="$(_db6_pid u)"
  printf '%s %s' "$h" "$par" > "$_db6_c/skip"
  : > "$_db6_c/gate"; _db6_unhold
  if [ "$m" = block ]; then
    _db6_runw test -s "$_db6_c/blk" || r="$r no ps -o lstart= call was held;"
    [ -z "$h" ] || kill -KILL "$h" 2>/dev/null
    sleep 0.3; : > "$_db6_c/go"; _db6_ml margin "$c/unit-look" T 30000 ms none   # R62: the watch below (R58), with none
  fi
  _db6_wait0; _db6_until 150 _db6_clear "$(_db6_pid u)" || r="$r still running after the parent had exited: $(_db6_ps "$(_db6_pid u)");"   # R58: the look for started.* waits until nothing of the run is left (R12's 30 s, a bound)
  if [ "$m" = block ] && [ -s "$_db6_c/bwho" ]; then   # R47: the call that was held must be the holder's own (its parent, or its parent's parent, is the holder)
    read -r _db6_bw1 _db6_bw2 _db6_bw3 < "$_db6_c/bwho"
    [ -z "$h" ] || [ "$_db6_bw1" = "$h" ] || [ "$_db6_bw2" = "$h" ] || r="$r the held ps -o lstart= was called by ${_db6_bw1:-none} (${_db6_bw3:0:60}; its parent ${_db6_bw2:-none}), not the holder ($h);"
    [ -z "${DJX_MLOG:-}" ] || printf '%s held-lstart-caller %s parent %s command %s holder %s\n' "$c" "${_db6_bw1:-none}" "${_db6_bw2:-none}" "${_db6_bw3:0:60}" "${h:-none}" >> "$DJX_MLOG" 2>/dev/null   # evidence only
  fi
  _db6_x="$_db6_rc $(_db6_cnt "$_db6_c/u.out" '  FAIL  part ended without its mark: 0010-ua.sh') [$(_db6_started)] $(_db6_rcpt)${r}"
  _db6_fin; _db6_td=""; rm -rf "$_db6_c" "$DB6/td-$c"
}
_db6_u22 u22-blank blank
_db6_is "R22: where every ps -o lstart= for the forked unit prints nothing (five tries), the holder gives up before the unit runs: the member never ran, the unit has no mark (part ended without its mark, once), exit 1, no receipt, and nothing of the run is left" "$_db6_x" "1 1 [] absent"
_db6_u22 u22-block block
_db6_is "R22: with the holder's ps -o lstart= for the forked unit held and the holder then killed with kill -9, the unit, held back until unit.I is written, finds its holder gone and exits without running the member: it never ran, has no mark (once), exit 1, no receipt, and nothing of the run is left" "$_db6_x" "1 1 [] absent"

# ---- R37 begin
printf '\nR37: no pipe into a tar that extracts (D8 gains a and b, blind, author 2; revision 11)\n'
# Written on 2026-10-20 from contract D, revision 11 (R37), by an author who read no implementation of _copy_content's fix.
# (a) A tar first on PATH, written here, stands in for bsdtar's two habits (1286's stand-in git has the first): after the host's tar has written
# an archive, and a pause of 0.5 s, it writes 1 MiB of zero bytes more where the archive went (stdout for -f - or no -f, else appended to the file),
# and its extractor reads 512-byte records up to and including the end-of-archive marker (two zero records) and no further, then closes its input
# and extracts what it read with the host's tar. So a pipe from a writer into it fails the writer's next write; an archive written whole to a file does not.
# It calls the host's tar through the path `command -v tar` gave before it was put on PATH, held in DB7_TAR, and logs each call's mode in DB7_LOG.
# The control's pipe is written with a variable that holds the bare word, so the lint of (b) does not name it (it is the one pipe the lint leaves).
# Readings taken where the contract leaves room, for the reviewers to confirm:
# - the case is run by bash -c under run.pl (a bounded runner with its own process group, as the other cases), with _copy_content's text from declare -f,
#   the suite's pipefail set, TMPDIR a directory of the case's under $TMP, and R12's group check after it;
# - the source is a git checkout with tracked.txt and sub/deep.txt committed and untracked.txt not ignored; "nothing else" is find's whole listing of the destination;
# - (b) is one awk matcher over the five places the contract names (tests/parts, tests/lib, lib, bin, felix), 1286 allowed by its exact file name; its samples
#   are the contract's, and the rest of what the contract says of the reading (quoted strings and trailing comments read as code, a pipe that ends a line
#   carrying onto the next line of code, comment and blank lines in between, an || that carries nothing, what it does not see) is pinned beside them;
# - this part's own lines are built so that the lint names none: the samples carry the word through a variable, and the awk is not a pipe into the word.
# An assertion whose name ends in (control) passes before D is built on purpose.
DB7="$TMP/db7"; mkdir -p "$DB7/bin" "$DB7/tmp" "$DB7/s" "$DB7/plain"
_db7_host="$(command -v tar)"; case "$_db7_host" in /*) ;; *) _db7_host=/usr/bin/tar ;; esac
_db7_rc=0; _db7_x=""; _db7_k=0; _db7_T=ta; _db7_T=${_db7_T}r
cat > "$DB7/bin/tar" <<'DB7TAR'
#!/usr/bin/env perl
# tar for R37: the host's tar ($DB7_TAR), with bsdtar's two habits. -c: the host's tar, then after 0.5 s 1 MiB of zero bytes more where the archive went.
# -x: reads its archive in records of 512 bytes up to the end-of-archive marker (two zero records) and no further, closes its input, extracts what it read.
use strict; use warnings;
my $real = $ENV{DB7_TAR}; my $log = $ENV{DB7_LOG}; my $tmpd = $ENV{DB7_TMPD};
my @a = @ARGV;
$a[0] = "-$a[0]" if @a && $a[0] =~ /^[A-Za-z]+$/;
my ($mode, $fi, $fv, $eq) = ("", -1, undef, 0);
for (my $i = 0; $i < @a; $i++) {
  my $w = $a[$i];
  last if $w eq "--";
  if ($w eq "--create") { $mode = "c"; next }
  if ($w eq "--extract" || $w eq "--get") { $mode = "x"; next }
  if ($w eq "--list") { $mode = "t"; next }
  if ($w eq "--file") { $fi = $i + 1; $fv = $a[$fi]; $i++; next }
  if ($w =~ /^--file=(.*)$/) { $fi = $i; $eq = 1; $fv = $1; next }
  next if $w =~ /^--/;
  if ($w =~ /^-(.+)$/) {
    my $c = $1;
    for (my $k = 0; $k < length($c); $k++) {
      my $l = substr($c, $k, 1);
      if ($l eq "c" || $l eq "x" || $l eq "t") { $mode = $l }
      if (index("fCTXIb", $l) >= 0) {
        exit 99 if $k < length($c) - 1;
        if ($l eq "f") { $fi = $i + 1; $fv = $a[$fi] }
        $i++; last;
      }
    }
  }
}
if (open(my $lg, ">>", $log)) { print $lg ($mode || "?"), "\n"; close $lg }
sub status { my ($s) = @_; return ($s & 127) ? 128 + ($s & 127) : $s >> 8 }
if ($mode eq "c") {
  my $s = system { $real } $real, @a;
  exit status($s) if $s != 0;
  select(undef, undef, undef, 0.5);
  my $z = "\0" x 1048576;
  if (!defined $fv || $fv eq "-") {
    my $o = 0;
    while ($o < length($z)) { my $n = syswrite(STDOUT, $z, length($z) - $o, $o); defined $n or exit 141; $o += $n }
  } else {
    open(my $h, ">>", $fv) or exit 1;
    binmode $h; print $h $z; close $h or exit 1;
  }
  exit 0;
}
if ($mode eq "x") {
  my $in;
  my $fromstdin = (!defined $fv || $fv eq "-");
  if ($fromstdin) { $in = \*STDIN } else { open($in, "<", $fv) or exit 2 }
  binmode $in;
  my $tmp = "$tmpd/x.$$";
  open(my $o, ">", $tmp) or exit 2;
  binmode $o;
  my $zero = "\0" x 512; my $zc = 0;
  while ($zc < 2) {
    my $rec = "";
    while (length($rec) < 512) { my $n = sysread($in, $rec, 512 - length($rec), length($rec)); last unless $n }
    last if $rec eq "";
    print $o $rec;
    if ($rec eq $zero) { $zc++ } else { $zc = 0 }
    last if length($rec) < 512;
  }
  close $o;
  close $in unless $fromstdin;
  if ($fi >= 0) { $a[$fi] = $eq ? "--file=-" : "-" } else { push @a, "-f", "-" }
  open(STDIN, "<", $tmp) or exit 2;
  my $s = system { $real } $real, @a;
  unlink $tmp;
  exit status($s);
}
my $s = system { $real } $real, @a;
exit status($s);
DB7TAR
chmod +x "$DB7/bin/tar"
# LABEL SCRIPT ARG...: bash -c SCRIPT with the stand-in first on PATH, TMPDIR a directory of the case's, under run.pl (a bounded runner that leads a process group of its
# own, INT and QUIT at their defaults), then R12's group check; _db7_rc is the status
_db7_run() {
  local l="$1" sc="$2"; shift 2
  perl "$DB6/run.pl" 600 DEFAULT DEFAULT "$DB7/$l.pid" env PATH="$DB7/bin:$DB6/mk:$PATH" TMPDIR="$DB7/tmp" DB6_MKREAL="$_db6_mkreal" DB6_MKLOG="$DB6/mktemp.log" DB7_TAR="$_db7_host" DB7_LOG="$DB7/tar.log" DB7_TMPD="$DB7/tmp" \
    "$BASH" -c "$sc" _ "$@" > "$DB7/$l.out" 2> "$DB7/$l.err"
  _db7_rc=$?
  _db6_grp "$(cat "$DB7/$l.pid" 2>/dev/null)"; _db6_mr "r37/$l" "$DB7/$l.pid.ms" 600   # R62, evidence only
}
_db7_pay() { printf 'R37 payload of %s\n' "$1"; seq 1 300; }
_db7_pay plain > "$DB7/plain/f.txt"
mkdir -p "$DB7/src/sub"
_db7_pay tracked > "$DB7/src/tracked.txt"; _db7_pay deep > "$DB7/src/sub/deep.txt"
( _fx_cd "$DB7/src" && git init -q -b main && git add tracked.txt sub/deep.txt \
    && git -c user.name=t -c user.email=t@t commit -qm base ) >/dev/null 2>&1
_db7_pay untracked > "$DB7/src/untracked.txt"
_db7_cnt() { LC_ALL=C awk -v m="$1" '$0 == m { n++ } END { print n + 0 }' "$DB7/tar.log" 2>/dev/null || echo 0; }   # MODE: how many calls the log holds of it

# the stand-in, checked: an archive written whole to a file gets the padding and extracts, exit 0, the bytes the same
: > "$DB7/tar.log"; rm -rf "$DB7/o1"; mkdir -p "$DB7/o1/x"
_db7_run k1 'set -o pipefail; t=tar; "$t" -c -f "$1/a.tar" -C "$2" . && "$t" -x -f "$1/a.tar" -C "$1/x"' "$DB7/o1" "$DB7/plain"
_db7_x="$_db7_rc $([ "$(wc -c < "$DB7/o1/a.tar" 2>/dev/null | tr -d ' ')" -gt 1048576 ] 2>/dev/null && echo padded || echo short) $(cmp -s "$DB7/plain/f.txt" "$DB7/o1/x/f.txt" && echo same || echo differs) c$(_db7_cnt c) x$(_db7_cnt x)"
_db6_is "R37: the stand-in tar writes an archive to a file with 1 MiB of padding after it, and extracts it whole: exit 0, the same bytes, one call of each mode (fixture control)" "$_db7_x" "0 padded same c1 x1"
# its pipe: a writer into the extractor fails on each of three runs, and the log shows both modes called
: > "$DB7/tar.log"; _db7_x=""
for _db7_k in 1 2 3; do
  rm -rf "$DB7/o2"; mkdir -p "$DB7/o2/d"
  _db7_run k2 'set -o pipefail; t=tar; "$t" -c -f - -C "$1" . | "$t" -x -f - -C "$2"' "$DB7/plain" "$DB7/o2/d"
  if [ "$_db7_rc" = 0 ]; then _db7_x="$_db7_x pass"; else _db7_x="$_db7_x fail"; fi
done
if [ "$(_db7_cnt c)" -ge 1 ] && [ "$(_db7_cnt x)" -ge 1 ]; then _db7_x="$_db7_x both"; else _db7_x="$_db7_x modes(c$(_db7_cnt c) x$(_db7_cnt x))"; fi
_db6_is "R37: with the stand-in tar first on PATH, one tar writing an archive to a pipe that a second tar extracts from fails under pipefail on each of three runs, and the log shows both modes called (fixture control)" "$_db7_x" " fail fail fail both"
# the case: _copy_content under the stand-in
rm -rf "$DB7/dest"
_db7_run k3 "$(declare -f _copy_content); set -o pipefail; _copy_content \"\$1\" \"\$2\"" "$DB7/src" "$DB7/dest"
_db7_x="$_db7_rc"
for _db7_f in tracked.txt untracked.txt sub/deep.txt; do
  if cmp -s "$DB7/src/$_db7_f" "$DB7/dest/$_db7_f" 2>/dev/null; then _db7_x="$_db7_x same"; else _db7_x="$_db7_x differs($_db7_f)"; fi
done
_db7_x="$_db7_x [$(cd "$DB7/dest" 2>/dev/null && find . | LC_ALL=C sort | tr '\n' ' ')]"
_db6_is "R37: _copy_content, with a tar first on PATH that writes past the end-of-archive marker and an extractor that stops there, and pipefail set, copies a checkout's tracked file, untracked file and file in a subdirectory: it returns 0, each has the same bytes, and nothing else is in the destination" \
  "$_db7_x" "0 same same same [. ./sub ./sub/deep.txt ./tracked.txt ./untracked.txt ]"

# R42 (a): a tracked file deleted from the working tree is skipped (git lists it, the disk has not), and the skip is no failure even when it is the last path git lists. The source has a.txt and
# sub/b.txt tracked, zz-gone.txt tracked and then removed, and c-untracked.txt not ignored (git lists the untracked first, so the deleted file is the last); the case measures which path is last.
mkdir -p "$DB7/src2/sub"
_db7_pay a > "$DB7/src2/a.txt"; _db7_pay b > "$DB7/src2/sub/b.txt"; _db7_pay z > "$DB7/src2/zz-gone.txt"
( _fx_cd "$DB7/src2" && git init -q -b main && git add a.txt sub/b.txt zz-gone.txt \
    && git -c user.name=t -c user.email=t@t -c commit.gpgsign=false commit -qm base ) >/dev/null 2>&1
rm -f "$DB7/src2/zz-gone.txt"; _db7_pay c > "$DB7/src2/c-untracked.txt"
_db7_last="$(cd "$DB7/src2" && git ls-files -co --exclude-standard -z . | tr '\0' '\n' | tail -n 1)"
rm -rf "$DB7/dest2"
_db7_run k4 "$(declare -f _copy_content); set -o pipefail; _copy_content \"\$1\" \"\$2\"" "$DB7/src2" "$DB7/dest2"
_db7_x="$_db7_rc $_db7_last"
for _db7_f in a.txt sub/b.txt c-untracked.txt; do
  if cmp -s "$DB7/src2/$_db7_f" "$DB7/dest2/$_db7_f" 2>/dev/null; then _db7_x="$_db7_x same"; else _db7_x="$_db7_x differs($_db7_f)"; fi
done
_db7_x="$_db7_x [$(cd "$DB7/dest2" 2>/dev/null && find . | LC_ALL=C sort | tr '\n' ' ')]"
_db6_is "R42: _copy_content, with the last path git lists a tracked file deleted from the working tree and pipefail set, returns 0 and copies every other file with the same bytes, and nothing else is in the destination" \
  "$_db7_x" "0 zz-gone.txt same same same [. ./a.txt ./c-untracked.txt ./sub ./sub/b.txt ]"

# (b) the lint: one matcher (perl, in scan.pl), the samples as the contract lists them, then every text file under engine/harness but the three tables
# scan.pl FILE...: FILE:LINE of the line of each extracting tar that a pipe feeds. A file is read as a stream of its code lines: comment and blank lines are left out, a line that ends in a backslash
# runs on into the next, and the text of a trailing comment stays (it is read as code). After a pipe (a | that is not half of ||), blanks, newlines and a comment that follows the pipe on its
# line are passed over, then the words command, env, nice and time; what stands there is an extracting tar, or a ( group, or a { group, any of whose simple commands (its text split at &&, ||, |,
# ; and line ends, up to the group's own close) is one. An extracting tar is the word tar given an option word that holds x (-x, -xO, -xzf, --extract, --get), or xf and the like as its first word.
cat > "$DB7/scan.pl" <<'DB7SCAN'
use strict; use warnings;
sub xtar {
  my ($s, $i) = @_;
  pos($s) = $i;
  while ($s =~ /\G(?:command|env|nice|time)[ \t]+/gc) { $i = pos($s) }
  pos($s) = $i;
  return -1 unless $s =~ /\Gtar(?=[ \t])/gc;
  my $rest = substr($s, $i + 3, 4000);
  $rest =~ s/(?:\||;|&&|\n|[ \t]#).*//s;
  my @w = grep { $_ ne "" } split /[ \t]+/, $rest;
  for my $k (0 .. $#w) {
    my $c = $w[$k];
    last if $c eq ")" || $c eq "}" || $c eq "&";
    if ($c =~ /\A--/) { return $i if $c =~ /\A--(?:extract|get)(?:=|\z)/; next }
    if ($c =~ /\A-./) { return $i if $c =~ /x/; next }
    return $i if $k == 0 && $c =~ /\A[A-Za-z]+\z/ && $c =~ /x/;
  }
  return -1;
}
my %hit;
for my $f (@ARGV) {
  open(my $h, "<", $f) or next;
  my ($s, @st, @no) = ("");
  my ($n, $cont) = (0, 0);
  while (my $l = <$h>) {
    $n++; chomp $l;
    next if !$cont && $l =~ /\A[ \t]*(?:#|\z)/;
    push @st, length($s); push @no, $n;
    if ($l =~ /\\[ \t]*\z/) { $l =~ s/\\[ \t]*\z/ /; $s .= $l; $cont = 1 }
    else { $s .= $l . "\n"; $cont = 0 }
  }
  close $h;
  my $line = sub { my ($o) = @_; my ($lo, $hi) = (0, $#st); while ($lo < $hi) { my $m = int(($lo + $hi + 1) / 2); if ($st[$m] <= $o) { $lo = $m } else { $hi = $m - 1 } } $no[$lo] };
  my $len = length($s); my $p = 0;
  while (($p = index($s, "|", $p)) >= 0) {
    if (substr($s, $p + 1, 1) eq "|") { $p += 2; next }
    my $q = $p + 1;
    for (;;) {
      $q++ while $q < $len && substr($s, $q, 1) =~ /[ \t\n]/;
      if (substr($s, $q, 1) eq "#") { $q++ while $q < $len && substr($s, $q, 1) ne "\n"; next }
      last;
    }
    my $t = $q;
    pos($s) = $t;
    while ($s =~ /\G(?:command|env|nice|time)[ \t]+/gc) { $t = pos($s) }
    my $o = substr($s, $t, 1);
    if ($o eq "(" || ($o eq "{" && substr($s, $t + 1, 1) =~ /[ \t\n]/)) {
      my $d = 0; my $e;
      for ($e = $t; $e < $len; $e++) {
        my $x = substr($s, $e, 1);
        if ($o eq "(") { $d++ if $x eq "("; if ($x eq ")") { $d--; last if $d == 0 } }
        else {
          my $pv = $e > 0 ? substr($s, $e - 1, 1) : " "; my $nx = substr($s, $e + 1, 1);
          $d++ if $x eq "{" && $pv =~ /[ \t\n;&|(]/ && $nx =~ /[ \t\n]/;
          if ($x eq "}" && $pv =~ /[ \t\n;&]/ && ($nx eq "" || $nx =~ /[ \t\n;&|)<>]/)) { $d--; last if $d == 0 }
        }
      }
      my $b0 = $t + 1; my $body = substr($s, $b0, $e - $t - 1);
      pos($body) = 0;
      while (pos($body) < length($body)) {
        $body =~ /\G(.*?)(?:&&|\|\||\||;|\n|\z)/gcs or last;
        my ($ss, $mend) = ($-[1], $+[0]);
        my $seg = $1; my $lead = $seg =~ /\A[ \t({!]*/ ? length($&) : 0;
        my $r = xtar($body, $ss + $lead);
        $hit{"$f:" . $line->($b0 + $r)} = 1 if $r >= 0;
        last if $mend >= length($body);
      }
    } else {
      my $r = xtar($s, $t);
      $hit{"$f:" . $line->($r)} = 1 if $r >= 0;
    }
    $p = $q > $p ? $q : $p + 1;
  }
}
print "$_\n" for sort { my ($fa, $la) = $a =~ /\A(.*):(\d+)\z/; my ($fb, $lb) = $b =~ /\A(.*):(\d+)\z/; $fa cmp $fb || $la <=> $lb } keys %hit;
DB7SCAN
_db7_scan() { perl "$DB7/scan.pl" "$@"; }
_db7_f() {   # SAMPLE: the line numbers the matcher names in it
  printf '%s\n' "$1" > "$DB7/s/sample"
  ( cd "$DB7/s" && _db7_scan sample ) | awk -F: '{ printf "%s%s", s, $NF; s = " " }'
}
_db6_is "R37: the lint flags a pipe into tar with x among its options: -x, none after the pipe, the old style xf, -x after another option, -xO, --extract and --get" \
  "$(_db7_f "x | $_db7_T -x -C d
x |$_db7_T -xf -
x | $_db7_T xf -
x | $_db7_T -C d -x
x | $_db7_T -xO | sed -n 1p
x | $_db7_T --extract -f -
x | $_db7_T --get")" "1 2 3 4 5 6 7"
_db6_is "R37: the lint flags it behind command, env, nice and time" \
  "$(_db7_f "x | command $_db7_T -x
x | env $_db7_T -x
x | nice $_db7_T -x
x | time $_db7_T -x")" "1 2 3 4"
_db6_is "R37: the lint flags it inside a subshell and a brace group" \
  "$(_db7_f "x | ( $_db7_T -x -C d )
x | { $_db7_T -x; }")" "1 2"
_db6_is "R37: the lint flags a tar -x on the line after a pipe that ends a line, and a line that starts with the pipe" \
  "$(_db7_f "x |
  $_db7_T -x
y
| $_db7_T -x")" "2 4"
_db6_is "R37: the lint flags it on the line after a pipe that a comment follows, and across comment and blank lines" \
  "$(_db7_f "x |   # why it is piped
  $_db7_T -x
y |
# a note

  $_db7_T -x")" "2 6"
_db6_is "R37: the lint leaves an ||, a tar -x with no pipe before it, a pipe into tar that writes or lists, a long option holding x, a pipe after tar -x, and a comment line" \
  "$(_db7_f "x || $_db7_T -x -f a.tar
$_db7_T -x -f a.tar
x | $_db7_T -c -f -
x | $_db7_T -t
x | $_db7_T -c --exclude=y -f -
$_db7_T -xO -f a.tar | sed -n 1p
$_db7_T -c -f - . | cat > a.tar
# x | $_db7_T -x")" ""
_db6_is "R37: the lint carries no || that ends a line onto the next line" \
  "$(_db7_f "a ||
  $_db7_T -x -f a.tar")" ""
_db6_is "R37: the lint reads a quoted string and a code line's trailing comment as code" \
  "$(_db7_f "printf 'use: x | $_db7_T -x\\n'
foo  # see x | $_db7_T -x")" "1 2"
_db6_is "R37: the lint does not see a tar named through a variable (the control's own pipe), by its path, behind a VAR= prefix, or behind a wrapper's options" \
  "$(_db7_f '"$t" -c -f - DIR | "$t" -x -f - -C DEST'"
x | \"\$t\" -x -f -
x | /usr/bin/$_db7_T -x
x | LC_ALL=C $_db7_T -x
x | nice -n 15 $_db7_T -x")" ""
# R42 (b): groups whose later commands extract, and options on past a trailing backslash. The line named is the line of the tar word.
_db6_is "R42: the lint flags a pipe into a group when a later command of the group extracts: after && in a ( group, after || and ; in a ( group, and after ; in a { group" \
  "$(_db7_f "x | (cd \"\$d\" && $_db7_T -xf -)
x | ( cd \"\$d\" || exit 1; $_db7_T -x -f - )
x | { cd \"\$d\"; $_db7_T -x; }")" "1 2 3"
_db6_is "R42: the lint flags a ( group that opens on the pipe's line and holds the cd and the extracting tar on lines of their own, and a { group the same" \
  "$(_db7_f "x | (
  cd \"\$d\"
  $_db7_T -x -f -
)
y | {
  cd \"\$d\"
  $_db7_T -x
}")" "3 7"
_db6_is "R42: the lint flags tar's option x on the line after a trailing backslash, and on a line two on after another option line" \
  "$(_db7_f "x | $_db7_T -C \"\$d\" \\
    -x -f -
y | $_db7_T -C \"\$d\" \\
    -f - \\
    -x")" "1 3"
_db6_is "R42: the lint leaves a group that only writes or lists, an extracting tar after the group's own close, and a backslash continuation with no x" \
  "$(_db7_f "x | ( cd \"\$d\" && $_db7_T -c -f - . )
x | { cd \"\$d\"; $_db7_T -t; }
x | ( cd \"\$d\" && cat ); $_db7_T -x -f a.tar
x | $_db7_T -C \"\$d\" \\
    -c -f -")" ""

# the scope: every text file under a root but tests/assertions.tsv, tests/red.tsv and tests/groups.tsv, and no binary file
_db7_files() {   # ROOT: the paths, one a line
  find "$1" -type f 2>/dev/null | LC_ALL=C sort | while IFS= read -r f; do
    case "$f" in "$1/tests/assertions.tsv"|"$1/tests/red.tsv"|"$1/tests/groups.tsv") ;; *) printf '%s\n' "$f" ;; esac
  done | perl -ne 'chomp; print "$_\n" unless -B $_ && -s $_'
}
_db7_tree() {   # ROOT: the lint over every file of _db7_files, as ROOT-relative FILE:LINE
  local r="$1" f; set --
  while IFS= read -r f; do set -- "$@" "$f"; done < <(_db7_files "$r")
  [ "$#" -gt 0 ] || return 1
  _db7_scan "$@" | LC_ALL=C awk -v r="$r/" 'index($0, r) == 1 { $0 = substr($0, length(r) + 1) } { print }'
}
_db7_scope() {   # a planted root, the shape in each file of it: the ones named, sorted
  local r="$DB7/scope" f
  rm -rf "$r"; mkdir -p "$r/tests/parts" "$r/tests/lib" "$r/hooks" "$r/lib" "$r/bin" "$r/templates/setup"
  for f in tests/run tests/red tests/receipt.sh tests/parts/p.sh tests/lib/l.sh hooks/h.sh lib/l.sh bin/b templates/t.yml templates/setup/s.sh felix tests/assertions.tsv tests/red.tsv tests/groups.tsv; do
    printf 'x | %s -x -f -\n' "$_db7_T" > "$r/$f"
  done
  printf 'x | %s -x -f -\n\0\0\0\0\0\0\0\0' "$_db7_T" > "$r/bin/blob"
  _db7_tree "$r" | LC_ALL=C sort | tr '\n' ' '
}
_db6_is "R42: the lint reads every text file under the root but the three tables (tests/assertions.tsv, tests/red.tsv, tests/groups.tsv): tests/run, tests/red, tests/receipt.sh, hooks, templates, lib, bin, felix, tests/lib and tests/parts are named, a binary file is not" \
  "$(_db7_scope)" "bin/b:1 felix:1 hooks/h.sh:1 lib/l.sh:1 templates/setup/s.sh:1 templates/t.yml:1 tests/lib/l.sh:1 tests/parts/p.sh:1 tests/receipt.sh:1 tests/red:1 tests/run:1 "

# the tree
_db7_raw="$(_db7_tree "$REAL_HARNESS")"
_db7_n="$(printf '%s\n' "$_db7_raw" | LC_ALL=C awk -F: '$1 ~ /(^|\/)1286-land-on-green-round-6-blind[.]sh$/ { printf "%s ", $2 }')"
_db7_x="$(LC_ALL=C awk -v h=" $_db7_n" 'index(h, " " FNR " ") && index($0, "archive") { n++ } END { print n + 0 }' "$HERE"/parts/1286-land-on-green-round-6-blind.sh 2>/dev/null)"
is "R37: the lint names 1286's own pipe of git archive into tar -x, so it reads the parts directory (control)" "$([ "$_db7_x" -ge 1 ] 2>/dev/null && echo named || echo "not named (hits in 1286: [$_db7_n])")" "named"
_db7_sites="$(printf '%s\n' "$_db7_raw" | LC_ALL=C awk -F: '$1 !~ /(^|\/)1286-land-on-green-round-6-blind[.]sh$/ && NF > 1 { printf "%s ", $0 }')"
if [ -z "$_db7_sites" ]; then
  ok "R42: no text file under engine/harness other than 1286 (the three tables aside: tests/lib, tests/run, tests/red, tests/receipt.sh, hooks, lib, bin, templates, felix and the parts) pipes into a tar that extracts"
else
  bad "R42: no text file under engine/harness other than 1286 (the three tables aside: tests/lib, tests/run, tests/red, tests/receipt.sh, hooks, lib, bin, templates, felix and the parts) pipes into a tar that extracts" "named at: $_db7_sites"
fi
is "R37: this part holds no line the lint names, the stand-in case's and the samples' lines included" "$(_db7_scan "$HERE/parts/1296-gate-friction-d-losses-blind.sh" | tr '\n' ' ')" ""
unset _db7_raw _db7_n _db7_x _db7_sites
# ---- R37 end

# R41: the stand-in mktemp was reached by the nested runs, and every path it logged is under this part's own case directories
_db6_x="$(LC_ALL=C awk -v p="$DB6/n/" -v q="$DB6/td-" -v r="$DB7/" '{ t++; if (index($0, p) != 1 && index($0, q) != 1 && index($0, r) != 1) { o++; if (o <= 3) b = b " [" $0 "]" } } END { if (t == 0) print "no path logged"; else if (o) print o " of " t " outside:" b; else print "ok" }' "$DB6/mktemp.log" 2>/dev/null)"
is "R41: every path the mktemp stand-in logged for this part's nested runs (a run's \$TMP among them) is under this part's own case directories, and it logged some" "${_db6_x:-no log}" ok

# ---- the part leaves the shell as it found it
rm -rf "${DB6:?}" "${DB7:?}"
unset -f $(compgen -A function _db6_) $(compgen -A function _db7_) 2>/dev/null
unset $(compgen -A variable _db6_) $(compgen -A variable _db7_) DB6 DB7 2>/dev/null
# <<< gate-friction-d-losses-blind
