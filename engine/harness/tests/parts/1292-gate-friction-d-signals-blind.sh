# >>> gate-friction-d-signals-blind
printf '\ngate friction D: signals, endings and holders (blind, author 2; revision 18)\n'
# Blind, written on 2026-10-18 from contract D, then rewritten on 2026-10-19 against revision 7 (D1 to D8 and
# "Amended after review 1"), by an author who read no implementation. tests/run, tests/red and tests/receipt.sh
# are run, never read, in copies of this suite that _suite_copy_tree (part 0003) makes under $TMP with planted
# parts of this block's own. Part 1294 holds the slots, the gate and the log, part 1296 what a run loses (the ending
# under a short read timeout, a parent or a holder killed with -9); this part holds what ends a run: D6's signals,
# dispositions and holders, with R2 to R4 (every stopper, units that outlive their wrapper). Revision 8 fixes here:
# proc2 2 (the holder-streams file test while the unit runs), 5 (R4's two mechanisms apart), 6 (R18, the start-up
# check's name), 7a (TERM and HUP dispositions) and conf2 2 (the lingering child is no job of the unit's shell).
# Revision 9 fix here: proc3 4(b) (R27): the TERM-ignored and HUP-ignored dispositions runs no longer claim to show the
# ticker's reset. With TERM ignored at the parent every unit inherits it ignored, and the run ends normally, which ends the
# ticker with KILL, never TERM; the same holds of the run started with HUP ignored. So the ticker's reset cannot be observed
# in those runs and rests on review and on R13's measurement of a perl that sets them to their defaults; what the runs pin is
# that units read what a -j 1 run reads, that the run passes with exit 0 (not the runner's 124) and that nothing of its group is left.
# Revision 10 fixes here: proc4 2 (R34): the ps shim of the R2 cases counts only `ps -A` calls, as R19 defines the ending's listing, so a
# holder's `ps -o ppid= -p WRAPPER` (R20, every 10 s) never takes a number; and proc4 3 (R35): a case for R20's own check, that a holder's
# wrapper still has the -j parent as its parent, with a ps first on PATH that answers that one call with 1 once a gate file exists.
# Revision 11 fix here: ev1 2 (R38): the record run's TERM case (D6, "TERM to a record run under -j 2") sends its TERM only once red's suite has started its
# own sleeper children and holds, read from a file the red-only side writes (rup.NAME, written where FELIX_TEST_NO_MANIFEST=1, which only red's suite sees).
# Before, the TERM could land before red's suite had started a child, and the one-list stopper of a build without R1 (the base's tests/red and receipt.sh, as
# red's suite runs this part) then missed it: the case was red on some runs and not on others, so red.tsv could not be reproduced. The parts' up.NAME is now
# the record run's alone, so "both units up" is read of the record run's units, not of red's. The case's name and its checks stand.
# Revision 12 fix here: proc5 2 (R42 (d)): the record run's TERM case waits for rup.0010-sa.sh alone, 60 s at most, then at most 5 s for rup.0020-sb.sh, which only a
# -j 2 red's suite (the branch's) writes; against the base, red's suite is serial and holds in 0010-sa, so the old wait for both always ran its 60 s and the
# case's waits (90 + 15 + 60 + 0.5 + 45 s) passed its 150 s run bound. The run bound is 240 s. The case's name and its checks stand.
# Revision 14 fixes here: R45 (_db2_wh finds the hk case's holder by what only it carries, a perl whose command line holds " --part " and the case's key, and the wrapper as its
# parent, so no transient child of the -j parent can be taken for them) and R44 (the record run's TERM case waits for up.NAME and rup.NAME, and for the run to end after its
# TERM, until the case's own run bound has passed, and a wait whose event never came fails the name, with a got text saying so, instead of the TERM going on as though it had).
# Revision 15 fix here: R47 (the ps shim of the R2 cases counts only calls whose caller is the -j parent's ending, the -j parent or a $( ) or perl of it, and passes a call from below
# a holder, from a holder's wrapper or from a process the -j parent no longer holds to the real ps; each counted call is logged with its caller's chain and command line, and each r2-N
# case checks from that log that the call it failed was the one it meant, else its name fails with a got that says whose call it was).
# Revision 17 fixes here (R55 to R57): every run bound is 600 s (_db2_lim, the group control's run.pl included); every wait for an event of a run lasts until the
# run's bound has passed (_db2_evt), and so does the wait for a signalled parent (_db2_stop, which was 45 s); holds, planted holds and the sleepers a leftover check
# needs to outlive live B + 30 s (630 s; were 60 to 300 s, and the start-up case's units 0.6 s, which a leftover outlived no window by); the looks for what is left
# are 10 s (were 5 s, below R56's floor of 10 s). The lu and hk cases stop the -j parent (SIGSTOP to its recorded pid) while their window runs and continue it
# after: with W = 30 the parent's own tick could end the holder at any moment after the kill, so a build without the holder's check met any window by luck; their
# windows are 60 s and 20 s (were 3 s), the R20 case's 60 s (was 20 s). Each window, its kind and its L are in a comment beside it. Review fix: the comments beside
# the looks of the ps controls, of lu's pids, of R20's leftovers and of hs's pair now give what D's build does inside, the floor and the build that sets L.
# Revision 18 (R58, R59, R61, R62), from the contract alone. R59: the record run's TERM case (rrt) drains the run's group as a bound, until the run's bound has passed
# (B + 5 s from its start), ending as soon as the group is empty, where it drained 30 s; its red-suite units wait for release 3150 polls (B + 30 s), which the case
# never writes, so a build that leaves red's tree leaves them past the bound. R58: hk's 2.5 s watch after the slot is let go stays, since the same name's 20 s
# check of the holder catches the build it watches for; no other watch here. R61: every sleeper, child and unit wait this part plants (ign.pl and its sleepers, the
# sleeper units, the release, go and child-file loops, the ps controls' stand-ins, the group control's sleeper) ends once its case directory is gone, looked for at
# least once a second (sl.pl), and djk.pl's wait for a file and its listings end once the case's directory is gone, the wait also once the run has exited (after one
# more look); rrt's optional 5 s wait ends at the run's exit. R62: with DJX_MLOG naming a file, "1292 run CASE/LABEL bound B ms MS" for every run and "1292 margin
# CASE/LABEL T T-MS ms MS|none" for every margin and for the watch. R60 changes nothing here: no case takes R1's at-exit listings. No name changes.
# Readings (revision 18): a look counted in 50 polls of 0.2 s is logged with T 10000, its least length; the group control's 1 s drain is logged with T 90000, the
# sleeper's 100 s less 10 s, and the drain's own length as what was measured. Review fix (revision 18): a run's start-to-exit is the ms run.pl, its bounded
# runner, writes at its own exit, from just before its fork to its waitpid's return (or its KILL at B, which its alarm counts from the same fork); it was the
# time from just before the case started the run to the case's reaping of it.
# Names say the clause: D6 the runner, R2 R4 R13 R18 R20 R38 R40 R41 R42 the amendments.
#
# What every case does (R12): it points TMPDIR at a fixture directory under $TMP, so none touches the machine's
# slots; it runs the copy under a bounded runner (run.pl) that makes the run's process group and starts it with
# INT and QUIT as the case asks and HUP and TERM at their defaults, so the HUP and TERM cases hold under nohup;
# every wait is bounded; and when the run has ended it waits up to 30 s for that group to hold no live process,
# stopped or running (zombies aside), reads from ps, and fails with the processes it names when one is left; it
# then sends CONT and KILL to those pids. A process outside such a group is ended by the pid the case recorded.
# No signal goes to a pid found by a pattern: a process is found by its group, its command line or its id for
# the check, and killed only by group or by a recorded pid whose command line still carries the case's id.
#
# Readings taken where the contract leaves room, for the reviewers to confirm:
# - "no unit, holder or wrapper left" is read from ps after the parent has ended: nothing in the run's group,
#   with the copy's directory or the case's id in its command line, that is not a zombie, within 10 s (revision 17);
# - "no slot held" is a LOCK_EX|LOCK_NB that every slot file grants, and "the slot files keep their names and
#   inode numbers" is read from a stat of felix-suite-slots before the signal and after the exit (D6: no step
#   removes a slot);
# - "the holder's stdout and stderr are the unit's log" is read with lsof (or /proc) as: the holder's descriptors
#   1 and 2 name one regular file, and it is the file the unit's own descriptor 1 names;
# - a run read through a pipe, as out=$(tests/run ...) reads it, ends with the run: the pipe is closed within 10 s
#   of the driver's exit;
# - the lu and hk cases leave FELIX_TEST_SLOT_NOTE unset (W = 30) and stop the -j parent (SIGSTOP to the pid run.pl
#   recorded) from before the wrapper's kill -9 until their window has been judged, so that only the holder's own check
#   of its parent can end the holder and its unit; a parent that ran on would end them at its next tick, which can come
#   at any moment after the kill (revision 17);
# - "within 60 s" (lu), "within 20 s" (hk) and "within 60 s" (R20) are timed inside the perl (djk.pl) that takes the ps
#   listing, from the moment of the kill (or of the marker a unit writes right after killing, or of the gate file) to the
#   start of the first listing that shows what was asked for.
# An assertion whose name ends in (control) passes before D is built on purpose: it pins what makes the others
# mean something. Against a tree where -j is not understood every run below is a serial one, so each case that
# would pass serially also asks for something only -j gives.
DB2="$TMP/db2"; mkdir -p "$DB2/n" "$DB2/pp" "$DB2/psshim" "$DB2/oshim"
# _db2_lim is every run's bound B (R55: 600 s); _db2_gn is R12's drain, 150 polls of 0.2 s (30 s), which R56 keeps
_db2_E=(); _db2_I=DEFAULT; _db2_Q=DEFAULT; _db2_Tm=DEFAULT; _db2_Hu=DEFAULT; _db2_lim=600; _db2_S=8; _db2_td=""; _db2_hp=0; _db2_ctl=0; _db2_bg=0; _db2_rc=0; _db2_lab=""
_db2_leak=""; _db2_ino0=""; _db2_pipe=0; _db2_late=""; _db2_x=""; _db2_gn=150; _db2_dl=0; _db2_miss=""; _db2_gdl=""; _db2_t0=""
: > "$DB2/g-empty.tsv"; printf '1\tdjy seed\n' > "$DB2/man.tsv"
cat > "$DB2/run.pl" <<'DB2PL'
# run.pl LIMIT INT QUIT TERM HUP PIDFILE MSFILE CMD...: CMD leads a process group of its own, started with INT QUIT TERM and HUP as given (the cases
# give TERM and HUP their defaults unless they ask) and no descriptor above 2; at LIMIT seconds the group is killed (exit 124). Exits as bash
# reports CMD's status. MSFILE, when not empty, gets the ms from just before the fork to the waitpid's return or the KILL at LIMIT: the run's
# start-to-exit as this runner saw it (R62).
use POSIX ();
my ($t, $i, $q, $tm, $hu, $f, $m) = splice(@ARGV, 0, 7);
my $s = 0; if ($m ne "") { require Time::HiRes; $s = Time::HiRes::time() }
sub ms { if ($m ne "" && open(my $h, ">", $m)) { printf $h "%d\n", (Time::HiRes::time() - $s) * 1000; close $h } }
my $p = fork;
defined $p or exit 125;
if (!$p) { setpgrp(0, 0); $SIG{INT} = $i; $SIG{QUIT} = $q; $SIG{HUP} = $hu; $SIG{TERM} = $tm; POSIX::close($_) for 3 .. 255; exec @ARGV; exit 127 }
if (open(my $h, ">", "$f.t")) { print $h "$p\n"; close $h; rename "$f.t", $f }
$SIG{ALRM} = sub { kill "KILL", -$p; ms(); exit 124 };
alarm $t; waitpid $p, 0; my $w = $?; ms();
exit(($w & 127) ? 128 + ($w & 127) : $w >> 8);
DB2PL
cat > "$DB2/ign.pl" <<'DB2IGN'
# ign.pl DIR ID MODE: ignores TERM and sleeps. MODE h: each TERM it gets forks one sleeper; MODE s: from its first TERM on it forks one every
# 20 ms, 100 at most. Pids go to DIR/ign.pid and DIR/gc.pids; the sleepers carry ID in their command line. A sleeper lives 630 s, B + 30 (R56:
# a leftover must outlive every look for it, so that a build that leaves it is seen; was 300 s). R61: it, and each sleeper (sl.pl), ends once DIR, the case's
# directory, is gone
my ($d, $id, $mode) = @ARGV;
my ($t, $n) = (0, 0);
(my $sl = $0) =~ s{[^/]*$}{sl.pl};   # beside this file
sub spawn {
  return if $n >= 100;
  $n++;
  my $k = fork;
  return unless defined $k;
  if (!$k) { exec "perl", $sl, $d, 630, $id, "gc"; exit 1 }
  if (open(my $g, ">>", "$d/gc.pids")) { print $g "$k\n"; close $g }
}
$SIG{TERM} = sub { $t = 1; spawn() if $mode eq "h" };
open(my $h, ">", "$d/ign.pid") or exit 3; print $h "$$\n"; close $h;
while (-d $d) { select(undef, undef, undef, 0.02); spawn() if $t && $mode eq "s" }
DB2IGN
# sl.pl DIR SECONDS TAG...: R61's sleeper: it sleeps SECONDS, or until DIR, its case's directory, is gone, looked for once a second
printf '%s\n' 'my ($d, $s) = @ARGV; my $e = time + $s; sleep 1 while time < $e && -d $d;' > "$DB2/sl.pl"
cat > "$DB2/psshim/ps" <<'DB2PS'
#!/bin/sh
# The real ps ($DJ2_PSREAL), except that the DJ2_PSFAIL-th counted listing asked for once the file $DJ2_PSTRIG exists fails with no output and status 1. R47: a call is counted
# only when it is the -j parent's ending: a `ps -A` call whose arguments hold ppid= (R19, R34) and whose shape is a positive one, ps -> J or ps -> X -> J, where J is the -j
# parent (the pid in the file $DJ2_PSJP) and X is a $( ) of J (a process with J's own command line) or a perl of J whose command line holds no " --part ". The holder and wrapper
# exclusions stay: X is no holder (a perl whose command line holds " --part " and $DJ2_PSKEY) and no holder's wrapper (a child of J with such a holder as its child), and nothing
# of the chain between ps and J is a holder or a wrapper. Every other call goes to the real ps, uncounted and logged in $DJ2_PSCNT.pass with its reason: from below a holder
# (the tree listing of 0007's `grow` runs in a holder's ending as well), from a holder's wrapper, from a process J no longer holds (a holder at pid 1), from a chain deeper than
# the -j parent's own $( ) (ps -> X -> Y -> J, a $( ) of a $( )), or from an X that is neither a $( ) nor a perl of J. A wrapper that has outlived its holder is not seen as one; it
# is kept out by the depth and the shape alone. A holder's `ps -o ppid= -p WRAPPER` (R20, every 10 s) holds no -A and is never looked at. Each counted call is logged in
# $DJ2_PSCNT as "N<TAB>caller>...>-j parent<TAB>the caller's command line"; the case reads that log (_db2_psown) against the -j parent's own command line, which it reads itself.
case " $* " in *" -A "*ppid=*)
  if [ -e "$DJ2_PSTRIG" ]; then
    v="$("$DJ2_PSREAL" -A -ww -o pid= -o ppid= -o command= 2>/dev/null | S=$$ J="$(cat "$DJ2_PSJP" 2>/dev/null)" K="$DJ2_PSKEY" LC_ALL=C awk '
      { pid = $1; pp[pid] = $2; c = $0; sub(/^ *[0-9]+ +[0-9]+ +/, "", c); cm[pid] = c; split(c, a, " "); b = a[1]; sub(/.*\//, "", b)
        if (b ~ /^perl/ && index(c, " --part ") && index(c, ENVIRON["K"])) hold[pid] = 1 }
      END { J = ENVIRON["J"]; S = ENVIRON["S"]; for (h in hold) wr[pp[h]] = 1
        q = pp[S]; ch = ""; bad = ""; n = 0; k = 0; e1 = q
        while (q != "" && q != 0 && n < 30) { ch = ch (ch == "" ? "" : ">") q; k++
          if (q == J) break
          if (q in hold) bad = "below a holder"; else if (q in wr) bad = "below a holder wrapper"
          q = pp[q]; n++ }
        c1 = cm[e1]; split(c1, a1, " "); b1 = a1[1]; sub(/.*\//, "", b1)
        if (J == "" || q != J) print "pass\t" ch "\tnot reached from the -j parent"
        else if (bad != "") print "pass\t" ch "\t" bad
        else if (k > 2) print "pass\t" ch "\tdeeper than the -j parent'"'"'s own $( )"
        else if (k == 2 && c1 != cm[J] && !(b1 ~ /^perl/ && !index(c1, " --part "))) print "pass\t" ch "\tneither a $( ) nor a perl of the -j parent"
        else print "count\t" ch "\t" cm[pp[S]] }')"
    case "$v" in
      count"	"*)
        n="$({ wc -l < "$DJ2_PSCNT"; } 2>/dev/null | tr -d ' ')"; n=$(( ${n:-0} + 1 ))
        printf '%s\t%s\n' "$n" "${v#count	}" >> "$DJ2_PSCNT"
        [ "$n" != "$DJ2_PSFAIL" ] || exit 1 ;;
      pass"	"*) printf '%s\n' "${v#pass	}" >> "$DJ2_PSCNT.pass" ;;
    esac
  fi ;;
esac
exec "$DJ2_PSREAL" "$@"
DB2PS
chmod +x "$DB2/psshim/ps"
# R41 (a): a stand-in mktemp first on PATH in every nested run. Given no template (options only) it adds "$TMPDIR/tmp.XXXXXXXXXX", so the run's $TMP is below the
# case's TMPDIR on macOS too, where a template-less mktemp -d ignores TMPDIR; otherwise it passes its arguments on. It calls the host's mktemp by the path found
# before the stand-in was on PATH ($DJ2_MKREAL) and logs each path it made to $DJ2_MKLOG, one file for the whole part, which the closing assertion reads.
mkdir -p "$DB2/mkshim"; _db2_mkreal="$(command -v mktemp)"; : > "$DB2/mktemp.log"
cat > "$DB2/mkshim/mktemp" <<'DB2MK'
#!/bin/sh
t=
for a in "$@"; do case "$a" in -*) ;; *) t=1 ;; esac; done
[ -n "$t" ] || set -- "$@" "${TMPDIR:-/tmp}/tmp.XXXXXXXXXX"
p="$("$DJ2_MKREAL" "$@")" || exit $?
[ -z "${DJ2_MKLOG:-}" ] || printf '%s\n' "$p" >> "$DJ2_MKLOG"
printf '%s\n' "$p"
DB2MK
chmod +x "$DB2/mkshim/mktemp"
cat > "$DB2/djk.pl" <<'DB2DJK'
# djk.pl SIG KILLPID WAITFILE MAXMS MODE ARG...: sends SIG to KILLPID (0: none), waits for the file WAITFILE (- : none; at most 600 s, the run bound: R56,
# was 120 s), takes the time T0, then takes ps listings until what MODE asks about has gone or MAXMS ms have passed. MODE pids PID...: those pids; MODE
# pidfile FILE: the pids in that file (read after the wait); MODE group PGID KEY ID: every live process
# (zombies aside, not this perl) in group PGID or with KEY or ID in its command line. Prints "gone MS" (MS: from T0 to the start of the first listing that
# showed none of them), "left MS PID,PID..." or "nopids". R61: with DJ2_DIR (the case's directory) in its environment, the wait for WAITFILE and the listings end
# once that directory is gone; with DJ2_RUN (the pid of the run's leader), the wait for WAITFILE, an event only the running run makes, ends once the run has
# exited. Then one more look: a WAITFILE that has not come prints "nofile", which fails the name as the end of a bound does (before, it went on to the listings)
use Time::HiRes qw(time sleep);
my ($sig, $kp, $wf, $max, $mode, @a) = @ARGV;
my $dir = $ENV{DJ2_DIR} || "/"; my $run = $ENV{DJ2_RUN} || 0;
kill $sig, $kp if $kp;
if ($wf ne "-") { my $e = time + 600; while (!-e $wf && time < $e && -d $dir) { last if $run && !kill(0, $run); sleep 0.02 } -e $wf or do { print "nofile\n"; exit } }
my $t0 = time; my $t; my @left;
if ($mode eq "pidfile") { if (open(my $h, "<", $a[0])) { @a = map { split " " } <$h>; close $h } else { @a = () } $mode = "pids" }
if ($mode eq "pids" && !@a) { print "nopids\n"; exit }
while (1) {
  $t = time; @left = ();
  for my $l (split /\n/, `ps -A -ww -o pid= -o pgid= -o stat= -o command= 2>/dev/null`) {
    next unless $l =~ /^\s*(\d+)\s+(\d+)\s+(\S+)\s+(.*)$/;
    my ($p, $g, $s, $c) = ($1, $2, $3, $4);
    next if $s =~ /^Z/ || $p == $$;
    if ($mode eq "pids") { push @left, $p if grep { $_ == $p } @a }
    else { push @left, $p if ($a[0] && $g == $a[0]) || index($c, $a[1]) >= 0 || index($c, $a[2]) >= 0 }
  }
  last if !@left || ($t - $t0) * 1000 > $max || !-d $dir;
  sleep 0.05;
}
if (@left) { printf "left %d %s\n", (time - $t0) * 1000, join(",", @left) } else { printf "gone %d\n", ($t - $t0) * 1000 }
DB2DJK
_db2_until() { local n="$1" i=0; shift; while [ "$i" -lt "$n" ]; do "$@" && return 0; sleep 0.2; i=$((i + 1)); done; "$@"; }
_db2_cnt() { LC_ALL=C awk -v l="$2" '$0 == l { n++ } END { print n + 0 }' "$1" 2>/dev/null || echo 0; }   # FILE LINE: lines that are exactly LINE
_db2_pfx() { LC_ALL=C awk -v p="$2" 'index($0, p) == 1 { n++ } END { print n + 0 }' "$1" 2>/dev/null || echo 0; }   # FILE PREFIX: lines that start with it
_db2_ms()  { perl -MTime::HiRes=time -e 'printf "%d", time * 1000'; }
# R62: with DJX_MLOG naming a file, a line of evidence (never a verdict); _db2_now is the ms only when there is a log to write
_db2_ml()  { [ -z "${DJX_MLOG:-}" ] || printf '1292 %s\n' "$*" >> "$DJX_MLOG"; }
_db2_now() { [ -z "${DJX_MLOG:-}" ] || _db2_ms; }
_db2_since() { [ -n "$1" ] && echo $(( $(_db2_ms) - $1 )) || echo none; }   # T0: the ms since T0, or none without a log
# MSFILE T0: R62's start-to-exit, the ms run.pl (the bounded runner) wrote at its own exit, not the time to the case's reaping; were run.pl ever killed
# before it wrote, the ms since T0, the case's start of the run
_db2_rx() { local x; x="$(cat "$1" 2>/dev/null)"; case "$x" in ''|*[!0123456789]*) _db2_since "$2" ;; *) echo "$x" ;; esac; }
# LABEL PRED...: a look of 50 polls (_db2_until 50, 10 s at least), logged as "margin CASE/LABEL T 10000 ms MS|none" (R62); its status is the look's
_db2_lk() { local l="$1" t r; shift; t="$(_db2_now)"; _db2_until 50 "$@"; r=$?; _db2_ml margin "${_db2_c##*/}/$l" T 10000 ms "$([ "$r" = 0 ] && _db2_since "$t" || echo none)"; return "$r"; }
# LABEL T-MS DJK-OUTPUT: R62's line for a margin djk.pl timed: its ms when it printed "gone MS", else none
_db2_dk() { local m=none; case "$3" in "gone "*) m="${3#gone }" ;; esac; _db2_ml margin "${_db2_c##*/}/$1" T "$2" ms "$m"; }
_db2_sel() { _db2_c="$DB2/n/$1"; _db2_F="$_db2_c/f"; _db2_T="$_db2_F/engine/harness/tests"; _db2_tmp="${_db2_td:-$_db2_c/tmp}"; }
# CASE [--red] GROUPS MANIFEST STUB...: the copy at $DB2/n/CASE and its fixture TMPDIR; 1 when it could not be made. A MANIFEST of + is a manifest
# of one row for each STUB that says ok "djy $DJ2N", so that a run that passes has compared one and leaves a receipt; - is none
_db2_new() {
  local n="$1" r="" s m; shift
  [ "${1:-}" != --red ] || { r=--red; shift; }
  _db2_sel "$n"
  rm -rf "$_db2_c"; mkdir -p "$_db2_c" "$_db2_tmp" || return 1
  if [ "${2:-}" = + ]; then
    m="$_db2_c/manifest.gen"; : > "$m"
    for s in "${@:3}"; do ! grep -qF 'ok "djy $DJ2N"' "$s" || printf '1\tdjy %s\n' "${s##*/}" >> "$m"; done
    set -- "$1" "$m" "${@:3}"
  fi
  _suite_copy_tree ${r:+"$r"} "$_db2_F" "$@"
}
_db2_run() {   # ARG...: the copy's driver under run.pl, TMPDIR $_db2_tmp, INT and QUIT as _db2_I and _db2_Q, FELIX_TEST_SLOTS=$_db2_S (none when empty), _db2_E added; the mktemp stand-in first on PATH (R41)
  local e; local -a k; k=()
  for e in ${_db2_E[@]+"${_db2_E[@]}"}; do case "$e" in PATH=*) e="PATH=$DB2/mkshim:${e#PATH=}" ;; esac; k[${#k[@]}]="$e"; done   # a case's own PATH keeps the stand-in first
  ( cd "$_db2_F" && exec env -u FELIX_TEST_NO_MANIFEST -u FELIX_TEST_JOBS -u FELIX_TEST_SLOTS -u FELIX_TEST_SLOT_NOTE -u FELIX_TEST_PART_LOG \
      -u FELIX_TEST_PART_RAN -u FELIX_TEST_PART_END -u FELIX_TEST_PART_RECORD -u FELIX_TEST_RED_JOBS -u PERL5OPT TMPDIR="$_db2_tmp" \
      PATH="$DB2/mkshim:$PATH" DJ2_MKREAL="$_db2_mkreal" DJ2_MKLOG="$DB2/mktemp.log" \
      ${_db2_S:+FELIX_TEST_SLOTS=$_db2_S} ${k[@]+"${k[@]}"} perl "$DB2/run.pl" "$_db2_lim" "$_db2_I" "$_db2_Q" "$_db2_Tm" "$_db2_Hu" "$_db2_c/$_db2_lab.pid" \
      "${_db2_t0:+$_db2_c/$_db2_lab.ms}" "$BASH" "$_db2_T/run" "$@" )
}
# LABEL ARG...: the run in the background; its pid file is $_db2_c/LABEL.pid (the run's group), its output LABEL.out and LABEL.err. With _db2_pipe=1 the
# output goes through a pipe that a reader closes into LABEL.eof, as out=$(...) reads it, and the status goes to LABEL.rc
_db2_go() {
  _db2_lab="$1"; shift; _db2_t0="$(_db2_now)"; [ -z "$_db2_t0" ] || rm -f "$_db2_c/$_db2_lab.ms"   # R62: the run's start, and run.pl's ms file, for its line
  if [ "$_db2_pipe" = 1 ]; then
    { _db2_run "$@" 2> "$_db2_c/$_db2_lab.err"; echo $? > "$_db2_c/$_db2_lab.rc"; } | { cat > "$_db2_c/$_db2_lab.out"; : > "$_db2_c/$_db2_lab.eof"; } &
  else _db2_run "$@" > "$_db2_c/$_db2_lab.out" 2> "$_db2_c/$_db2_lab.err" &
  fi
  _db2_bg=$!
  _db2_dl=$((SECONDS + _db2_lim + 5))   # R44: the run's own bound (run.pl's KILL at _db2_lim) and 5 s more; a wait for an event of the run lasts until then
}
# R44: PRED ARG...: waits until PRED ARG... holds, the run has ended, or the run's own bound has passed (_db2_dl: _db2_lim + 5 s from _db2_go, by when run.pl has killed
# the run), and says which: 0 when it held, 1 when the event never came. Never a fixed wait shorter than the run's bound. When it did not come, _db2_why
# (set by the first miss only) says which stopped the wait: "the run ended" or "the bound of the run passed", for the got text.
_db2_evt() {
  while ! "$@"; do
    if ! kill -0 "$_db2_bg" 2>/dev/null; then _db2_why="${_db2_why:-the run ended}"; break; fi
    if [ "$SECONDS" -ge "$_db2_dl" ]; then _db2_why="${_db2_why:-the bound of the run passed}"; break; fi
    sleep 0.2
  done
  "$@"
}
_db2_pid() { cat "$_db2_c/$1.pid" 2>/dev/null; }
_db2_gl()  { ps -A -ww -o pid= -o pgid= -o stat= -o command= 2>/dev/null | G="$1" LC_ALL=C awk '$2 == ENVIRON["G"] && $3 !~ /^Z/ { c = $0; sub(/^ *[0-9]+ +[0-9]+ +[^ ]+ +/, "", c); printf "%s:%s:%s\n", $1, $3, substr(c, 1, 50) }'; }
# GROUP [DEADLINE]: waits up to 30 s (R12's drain, _db2_gn polls) for the run's group to hold no live process; what is left goes into _db2_leak, and is continued
# and killed. With DEADLINE, a value of $SECONDS, the wait is a bound (R59, for a record run ended by a signal): it lasts until then, at least the 30 s, and ends
# as soon as the group is empty; only what is still there at its end is left
_db2_grp() {
  local g="$1" d="${2:-}" i=0 l p
  [ -n "$g" ] || return 0
  while [ "$i" -lt "$_db2_gn" ] || { [ -n "$d" ] && [ "$SECONDS" -lt "$d" ]; }; do [ -z "$(_db2_gl "$g")" ] && break; sleep 0.2; i=$((i + 1)); done
  l="$(_db2_gl "$g")"
  [ -z "$l" ] || _db2_leak="$_db2_leak left in the run's group: $(printf '%s' "$l" | tr '\n' ' ')"
  for p in $(printf '%s\n' "$l" | sed 's/:.*//'); do kill -CONT "$p" 2>/dev/null; kill -KILL "$p" 2>/dev/null; done
}
# the end of a run, in two halves: _db2_wait0 collects its status, _db2_fin checks and ends its group and puts the knobs back
_db2_wait0() {
  if [ "$_db2_pipe" = 1 ]; then _db2_until $((_db2_lim * 5 + 50)) test -s "$_db2_c/$_db2_lab.rc"; _db2_rc="$(cat "$_db2_c/$_db2_lab.rc" 2>/dev/null)"
  else { wait "$_db2_bg"; } 2>/dev/null; _db2_rc=$?; fi
  [ -z "$_db2_t0" ] || _db2_ml run "${_db2_c##*/}/$_db2_lab" bound "$_db2_lim" ms "$(_db2_rx "$_db2_c/$_db2_lab.ms" "$_db2_t0")"; _db2_t0=""   # R62
}
_db2_fin() {
  _db2_grp "$(_db2_pid "$_db2_lab")" ${_db2_gdl:+"$_db2_gdl"}
  if [ "$_db2_pipe" = 1 ]; then _db2_until 50 _db2_dead "$_db2_bg" || kill -KILL "$_db2_bg" 2>/dev/null; { wait "$_db2_bg"; } 2>/dev/null; fi   # a drain after the run has ended (R56 keeps it)
  _db2_E=(); _db2_I=DEFAULT; _db2_Q=DEFAULT; _db2_Tm=DEFAULT; _db2_Hu=DEFAULT; _db2_lim=600; _db2_S=8; _db2_pipe=0; _db2_gdl=""
}
_db2_wait() { _db2_wait0; _db2_fin; }
# LABEL SIGNAL [bound]: SIGNAL to the driver, then a wait for it to end that lasts until the run's own bound has passed, at least 45 s (R44, R56: a bound; it was 45 s
# for every case but the record run's), where run.pl's KILL has ended it with 124; a run still there then is killed by group and _db2_late says so. With bound
# (a record run, R59), the drain of the run's group that follows is a bound too: until the run's bound has passed (_db2_dl), and over as soon as the group is empty
_db2_stop() {
  local p i=0 n w="there when the run's bound had passed"; p="$(_db2_pid "$1")"; _db2_late=""
  n=$(( (_db2_dl - SECONDS) * 5 )); [ "$n" -ge 225 ] || n=225
  [ -z "$p" ] || kill -"$2" "$p" 2>/dev/null
  while [ "$i" -lt "$n" ]; do kill -0 "$p" 2>/dev/null || break; sleep 0.2; i=$((i + 1)); done
  if kill -0 "$p" 2>/dev/null; then _db2_late=" the parent was still running $w;"; kill -KILL -- "-$p" 2>/dev/null; fi
  [ "${3:-}" != bound ] || _db2_gdl="$_db2_dl"
  _db2_wait
}
_db2_rcpt() { if [ -f "$_db2_F/.git/felix-suite-receipt" ]; then echo present; else echo absent; fi; }
_db2_id()   { printf '%s' "${TMP##*/}-${_db2_c##*/}"; }
_db2_key()  { printf '%s' "${DB2#/private}/n/${_db2_c##*/}/"; }
# GROUP: the live pids of the current case's run, for the check: in its group, or with its directory or its id in the command line (not mine at _db2_hp)
_db2_ps() {
  ps -A -ww -o pid= -o pgid= -o stat= -o command= 2>/dev/null | G="${1:-}" K="$(_db2_key)" I="$(_db2_id)" H="$_db2_hp" LC_ALL=C awk \
    '$3 !~ /^Z/ && $1 != ENVIRON["H"] && (($2 == ENVIRON["G"] && ENVIRON["G"] != "") || index($0, ENVIRON["K"]) || index($0, ENVIRON["I"])) { printf "%s ", $1 }'
}
_db2_clear() { [ -z "$(_db2_ps "$1")" ]; }
_db2_dead()  { ! _db2_alive "$1"; }
_db2_alive() { local s; s="$(ps -o stat= -p "$1" 2>/dev/null | tr -d ' ')"; [ -n "$s" ] && [ "${s#Z}" = "$s" ]; }   # PID: there, and not a zombie
_db2_kf() {   # FILE...: ends the pids those files record, each only while its command line still carries the case's id
  local f p
  for f in "$@"; do [ -f "$f" ] || continue
    for p in $(cat "$f" 2>/dev/null); do case "$(ps -o command= -p "$p" 2>/dev/null)" in *"$(_db2_id)"*) kill -CONT "$p" 2>/dev/null; kill -KILL "$p" 2>/dev/null ;; esac; done
  done
}
# the unit processes of the current case: bash run --part, not perl (the holder may carry the same words)
_db2_units() { ps -A -ww -o pid= -o stat= -o command= 2>/dev/null | K="$(_db2_key)" LC_ALL=C awk '$2 !~ /^Z/ && index($0, ENVIRON["K"]) && index($0, " --part ") && $3 !~ /perl/ { printf "%s ", $1 }'; }
# DRIVERPID: "wrapper holder" (R45). The holder is named by what only it carries: a perl whose command line holds " --part " and this case's key (as _db2_uh names a
# unit), and the wrapper is its parent, which must be a child of the driver. Not "a child of the driver that has a perl child": the -j parent's own transient
# children (the perls of its $( ), its lock probe) have a perl child for a moment, and none of them carries the case's key and " --part ".
_db2_wh() {
  ps -A -ww -o pid= -o ppid= -o command= 2>/dev/null | D="$1" K="$(_db2_key)" LC_ALL=C awk '{ pp[$1] = $2; c[$1] = $0; w[$1] = $3 }
    END { for (q in pp) if (w[q] ~ /perl/ && index(c[q], ENVIRON["K"]) && index(c[q], " --part ") && (pp[q] in pp) && pp[pp[q]] == ENVIRON["D"]) { print pp[q], q; exit } }'
}
# "unit holder": a bash run --part below a perl in the current case
_db2_uh() {
  ps -A -ww -o pid= -o ppid= -o command= 2>/dev/null | K="$(_db2_key)" LC_ALL=C awk '{ pp[$1] = $2; c[$1] = $0; w[$1] = $3 }
    END { for (q in pp) if (index(c[q], ENVIRON["K"]) && index(c[q], " --part ") && w[q] !~ /perl/ && (pp[q] in w) && w[pp[q]] ~ /perl/) { print q, pp[q]; exit } }'
}
_db2_fdn() {   # PID FD: the file descriptor FD of PID names, or nothing
  if [ -d /proc/self/fd ]; then readlink "/proc/$1/fd/$2" 2>/dev/null
  elif command -v lsof >/dev/null 2>&1; then lsof -a -p "$1" -d "$2" -Fn 2>/dev/null | LC_ALL=C awk '/^n/ { print substr($0, 2); exit }'
  fi
}
_db2_inos() {   # TMPDIR: name:kind:inode of each entry of felix-suite-slots, in name order
  perl -e 'for my $f (sort glob("$ARGV[0]/felix-suite-slots/*")) { my @s = lstat($f); (my $n = $f) =~ s{.*/}{}; print "$n:", (-f _ ? "f" : "x"), ":$s[1] " }' "$1"
}
_db2_held() {   # TMPDIR: the slot files under it that some process holds
  perl -e 'use Fcntl ":flock"; for my $f (sort glob("$ARGV[0]/felix-suite-slots/*")) { next unless -f $f; open(my $h, "<", $f) or next; flock($h, LOCK_EX | LOCK_NB) or print "$f "; close $h }' "$1"
}
# SLOTFILE: a perl of mine holds its lock until _db2_unhold; _db2_hp is its pid. R56: its own end is a bound, B + 30 s (R44's H; was 300 s), or sooner once its slots
# directory is gone; the wait for its "held" is the run bound, ended early if the perl has gone
_db2_hok() { [ -s "$_db2_c/hold.out" ] || ! kill -0 "$_db2_hp" 2>/dev/null; }
_db2_hold() {
  [ -d "${1%/*}" ] || mkdir -m 0700 "${1%/*}"
  perl -e 'use Fcntl ":flock"; open(my $h, ">>", $ARGV[0]) or exit 4; flock($h, LOCK_EX | LOCK_NB) or exit 3; $| = 1; print "held\n"; my $e = time + $ARGV[1]; sleep 1 while time < $e && -d $ARGV[2]' \
    "$1" "$((_db2_lim + 30))" "${1%/*}" > "$_db2_c/hold.out" 2>&1 &
  _db2_hp=$!
  _db2_until $((_db2_lim * 5)) _db2_hok
}
_db2_unhold() { [ "$_db2_hp" = 0 ] || { kill -KILL "$_db2_hp" 2>/dev/null; { wait "$_db2_hp"; } 2>/dev/null; }; _db2_hp=0; return 0; }
_db2_started() { local f r=""; for f in "$_db2_c"/started.*; do [ -e "$f" ] && r="$r${f##*/} "; done; printf '%s' "$r"; }
_db2_up() { test -e "$_db2_c/up.$1"; }
_db2_rup() { test -e "$_db2_c/rup.$1"; }   # NAME: R38, R42 (d): red's suite has started that sleeper and holds (a serial red's suite never starts 0020-sb)
_db2_pre()   { local f; for f in "$_db2_T"/parts/0006-*.sh; do printf '\n: > "%s/pre.done.$$"\n' "$_db2_c" >> "$f"; done; }   # the parent's prelude is done
_db2_pre_up() { ls "$_db2_c"/pre.done.* >/dev/null 2>&1; }
# "ok", or what an interrupted run left behind: LABEL STATUS (the slot files keep their names and inodes when _db2_ino0 was taken)
_db2_gone() {
  local l="$1" r="" g; g="$(_db2_pid "$l")"
  [ "$_db2_rc" = "$2" ] || r="$r exit $_db2_rc, not $2;"
  [ "$(_db2_cnt "$_db2_c/$l.out" reached)" = 0 ] || r="$r reached was printed;"
  # R56, a margin: once the parent has exited, what it ended has only to act on the KILL it was sent (no fork), floor 10 s (was 5 s); L is a leftover's own end,
  # 630 s after it started for every sleeper and unit these cases plant
  _db2_lk gone _db2_clear "$g" || r="$r still running: $(_db2_ps "$g");"
  [ -z "$(_db2_held "$_db2_tmp")" ] || r="$r a slot is still held;"
  [ -z "$_db2_ino0" ] || [ "$(_db2_inos "$_db2_tmp")" = "$_db2_ino0" ] || r="$r the slot files changed: [$_db2_ino0] became [$(_db2_inos "$_db2_tmp")];"
  [ "$(_db2_rcpt)" = absent ] || r="$r a receipt was left;"
  [ "$_db2_ctl" = 1 ] || r="$r no positive control, so these absences say nothing;"
  printf '%s' "${r:-ok}"
}
# NAME ACTUAL EXPECTED: is, with what the run's group had left added to the actual
_db2_is() { local a="$2"; [ -z "$_db2_leak" ] || a="$a [$_db2_leak ]"; _db2_leak=""; is "$1" "$a" "$3"; }
# CASE FILE: pp/CASE/FILE is stdin behind a header that names the case's directory, id, the part and this block's directory
_db2_w() {
  mkdir -p "$DB2/pp/$1" || return 1
  { printf 'DJ2D=%q; DJ2I=%q; DJ2N=%q; DJ2L=%q\n' "$DB2/n/$1" "${TMP##*/}-$1" "$2" "$DB2"
    printf '%s\n' "printf '\\ndjy-sec %s\\n' \"\$DJ2N\""; cat; } > "$DB2/pp/$1/$2"
}
_db2_q() {   # CASE: four quick parts that note they started and pass
  local f
  for f in 0010-qa.sh 0020-qb.sh 0030-qc.sh 0040-qd.sh; do _db2_w "$1" "$f" <<'X'
: > "$DJ2D/started.$DJ2N"
ok "djy $DJ2N"
X
  done
}
_db2_sl() {   # CASE: two parts that start a sleeping child and wait for a release file, and a third that only notes it started; up.NAME says so in a record run or a plain one, rup.NAME in red's suite (R38)
  local f
  # R59, R61: the release wait is 3150 polls of at least 0.2 s (B + 30 s, which outlasts the run's bound; it was unbounded), and it and the child end once the
  # case's directory is gone
  for f in 0010-sa.sh 0020-sb.sh; do _db2_w "$1" "$f" <<'X'
: > "$DJ2D/started.$DJ2N"
perl -e 'open(my $h, ">", $ARGV[0]); close $h; my $e = time + 630; sleep 1 while time < $e && -d $ARGV[1]' "$DJ2D/ch.$DJ2N" "$DJ2D" "$DJ2I" sl &
_k=$!
until [ -e "$DJ2D/ch.$DJ2N" ] || [ ! -d "$DJ2D" ]; do sleep 0.1; done
if [ "${FELIX_TEST_NO_MANIFEST:-0}" = 1 ]; then : > "$DJ2D/rup.$DJ2N"; else : > "$DJ2D/up.$DJ2N"; fi
_i=0; while [ ! -e "$DJ2D/release" ] && [ -d "$DJ2D" ] && [ "$_i" -lt 3150 ]; do sleep 0.2; _i=$((_i + 1)); done
kill "$_k" 2>/dev/null; wait "$_k" 2>/dev/null
ok "djy $DJ2N"
X
  done
  _db2_w "$1" 0030-sc.sh <<'X'
: > "$DJ2D/started.$DJ2N"
ok "djy $DJ2N"
X
}
# ---- end of the helpers

# ---- the control: released at once, the sleeper parts pass under -j 2 and leave a receipt
_db2_sl ctl; _db2_new ctl "$DB2/g-empty.tsv" + "$DB2/pp/ctl"/*.sh
: > "$_db2_c/release"; _db2_go c -j 2; _db2_wait
[ "$_db2_rc" = 0 ] && [ "$(_db2_rcpt)" = present ] && [ -e "$_db2_c/started.0030-sc.sh" ] && _db2_ctl=1
_db2_is "D6: the sleeper parts, released at once, pass under -j 2: exit 0, a receipt, and the third part ran (positive control)" "$_db2_rc $_db2_ctl" "0 1"
rm -rf "$DB2/n/ctl"

# ---- the controls for the checks that look at ps: units are counted and a perl carrying their words is not; a sleeper with the case's id is seen, and not once killed
_db2_sel snapctl; mkdir -p "$_db2_c"; mkfifo "$_db2_c/ff" 2>/dev/null
# R56: the four stand-ins live B + 30 s (a hold's own end; were 60 s) and are killed by pid below; the wait for them is a bound, the run bound. The look once they
# are killed and this shell has waited for them is a margin of the control, 50 polls (10 s at least; was 5 s): nothing of D runs in it, they have only to act on the
# KILL they were sent, so the floor is 10 s. What it tells apart is a check of the case's that takes a killed process for a live one; L is the stand-ins' own end,
# 630 s, were the KILL not to take. R61: each stand-in also ends once the case's directory is gone (the bash ones read their FIFO a second at a time)
printf 'exec 3<> "$1"; _i=0; while [ -d "$2" ] && [ "$_i" -lt %s ]; do read -t 1 -u 3 _x; _i=$((_i + 1)); done\n' "$((_db2_lim + 30))" > "$_db2_c/unit.sh"
bash "$_db2_c/unit.sh" "$_db2_c/ff" "$_db2_c" --part 0010-x.sh & _db2_p1=$!
bash "$_db2_c/unit.sh" "$_db2_c/ff" "$_db2_c" --part 0020-y.sh & _db2_p2=$!
perl "$DB2/sl.pl" "$_db2_c" "$((_db2_lim + 30))" "$_db2_c/unit.sh" --part 0030-z.sh & _db2_p3=$!
perl "$DB2/sl.pl" "$_db2_c" "$((_db2_lim + 30))" "$(_db2_id)" probe & _db2_p4=$!
_db2_four() { [ "$(set -- $(_db2_ps ''); echo $#)" = 4 ]; }
_db2_until $((_db2_lim * 5)) _db2_four
_db2_x="$(set -- $(_db2_units); echo $#) $(set -- $(_db2_ps ''); echo $#)"
kill -KILL "$_db2_p1" "$_db2_p2" "$_db2_p3" "$_db2_p4" 2>/dev/null
for _db2_p in "$_db2_p1" "$_db2_p2" "$_db2_p3" "$_db2_p4"; do { wait "$_db2_p"; } 2>/dev/null; done
_db2_y="$(_db2_lk gone _db2_clear '' && echo gone || echo "still [$(_db2_ps '')]")"
_db2_is "D6: the process checks below see what they should: two unit processes and not the perl that carries their words, four processes of the case in all, and none once killed (control)" "$_db2_x $_db2_y" "2 4 gone"
rm -rf "$DB2/n/snapctl"
# the group check finds a process left in a run's group after its leader has gone, names it, and ends it
_db2_sel gctl; mkdir -p "$_db2_c"; _db2_lab=g
# R55: the bound is 600 s (was 60 s; the leader exits at once). The control's 1 s drain (_db2_gn=5) is a margin of the control: its L is the sleeper's 100 s, so it stands.
# The look once the drain has killed it is a margin of the control, 50 polls (10 s at least; was 5 s): nothing of D runs in it, the sleeper has only to act on the
# drain's KILL (pid 1 reaps it), so the floor is 10 s. It tells apart a drain whose KILL did not take; L is the sleeper's own end, 100 s. R61: the sleeper also
# ends once the case's directory is gone (sl.pl)
_db2_t0="$(_db2_now)"; rm -f "$_db2_c/g.ms"
perl "$DB2/run.pl" "$_db2_lim" DEFAULT DEFAULT DEFAULT DEFAULT "$_db2_c/g.pid" "${_db2_t0:+$_db2_c/g.ms}" bash -c 'perl -e "\$e=time+100; sleep 1 while time<\$e && -d \$ARGV[0]" "$1" "$0" gc & exit 0' "$(_db2_id)" "$_db2_c" & _db2_p1=$!
{ wait "$_db2_p1"; } 2>/dev/null
[ -z "$_db2_t0" ] || _db2_ml run gctl/g bound "$_db2_lim" ms "$(_db2_rx "$_db2_c/g.ms" "$_db2_t0")"; _db2_t0="$(_db2_now)"
_db2_gn=5; _db2_grp "$(_db2_pid g)"; _db2_gn=150; _db2_ml margin gctl/drain T 90000 ms "$(_db2_since "$_db2_t0")"; _db2_t0=""
case "$_db2_leak" in *'perl -e $e=time+100; sleep 1'*) _db2_x=named ;; *) _db2_x="not named [$_db2_leak]" ;; esac   # not inside $( ): bash 3.2 ends the substitution at the pattern's )
_db2_x="$_db2_x $(_db2_lk gone _db2_clear '' && echo gone || echo still)"; _db2_leak=""
is "R12: the group check names a process left in the run's group after the leader exited, and ends it (control)" "$_db2_x" "named gone"
rm -rf "$DB2/n/gctl"

# ---- dispositions (D6, R13): a unit starts with INT and QUIT as the parent had them, in each of the four ways, and with TERM or HUP as it had them when the parent started with one of them ignored. The ticker's own reset of TERM and HUP cannot be seen here (R27): the units ignore them too, and the normal end KILLs the ticker
_db2_dp() {   # CASE: three parts that print what perl reads of INT QUIT TERM HUP, and whether they ran as a unit; the last two are a group
  local f
  for f in 0010-da.sh 0020-db.sh 0030-dc.sh; do _db2_w "$1" "$f" <<'X'
perl -e 'print "djy-sig:", join(",", map { $_ . "=" . ((defined $SIG{$_} && length $SIG{$_}) ? $SIG{$_} : "DEFAULT") } qw(INT QUIT TERM HUP)), "\n"'
case "$(ps -p $$ -o command= 2>/dev/null)" in *" --part "*) printf 'djy-mode:unit\n' ;; *) printf 'djy-mode:serial\n' ;; esac
ok "djy $DJ2N"
X
  done
}
printf 'dg\t0020-db.sh\ndg\t0030-dc.sh\n' > "$DB2/g-dis.tsv"
_db2_dp dis; _db2_new dis "$DB2/g-dis.tsv" + "$DB2/pp/dis"/*.sh
for _db2_m in "DEFAULT DEFAULT DEFAULT DEFAULT" "IGNORE IGNORE DEFAULT DEFAULT" "IGNORE DEFAULT DEFAULT DEFAULT" "DEFAULT IGNORE DEFAULT DEFAULT" "DEFAULT DEFAULT IGNORE DEFAULT" "DEFAULT DEFAULT DEFAULT IGNORE"; do
  read -r _db2_i _db2_qv _db2_tv _db2_hv <<< "$_db2_m"   # not set --: that would change the positional parameters of every part after this one
  _db2_I="$_db2_i"; _db2_Q="$_db2_qv"; _db2_Tm="$_db2_tv"; _db2_Hu="$_db2_hv"; _db2_go d3 -j 3; _db2_wait; _db2_r3="$_db2_rc"; _db2_l3="$_db2_leak"; _db2_leak=""
  _db2_I="$_db2_i"; _db2_Q="$_db2_qv"; _db2_Tm="$_db2_tv"; _db2_Hu="$_db2_hv"; _db2_go d1 -j 1; _db2_wait
  _db2_x3="$(grep '^djy-sig:' "$_db2_c/d3.out" | LC_ALL=C sort | tr '\n' ' ')"; _db2_x1="$(grep '^djy-sig:' "$_db2_c/d1.out" | LC_ALL=C sort | tr '\n' ' ')"
  _db2_k="$(grep -c "^djy-sig:INT=$_db2_i,QUIT=$_db2_qv,TERM=$_db2_tv,HUP=$_db2_hv\$" "$_db2_c/d1.out")"
  if [ "$_db2_tv$_db2_hv" = DEFAULTDEFAULT ]; then
    _db2_is "D6: -j 1 parts read INT $_db2_i and QUIT $_db2_qv from a parent started that way, TERM and HUP at their defaults, on all three parts (control)" "$_db2_k $(_db2_cnt "$_db2_c/d1.out" djy-mode:serial)" "3 3"
    _db2_leak="$_db2_l3"
    _db2_is "D6: from a parent with INT $_db2_i and QUIT $_db2_qv the three parts, two of them a group, ran as units under -j 3 and read the dispositions a -j 1 run reads" \
       "$(_db2_cnt "$_db2_c/d3.out" djy-mode:unit) $([ "$_db2_x3" = "$_db2_x1" ] && echo same || echo "differ [$_db2_x3] [$_db2_x1]")" "3 same"
  else
    _db2_w3=TERM; [ "$_db2_hv" = IGNORE ] && _db2_w3=HUP
    _db2_is "D6: -j 1 parts read $_db2_w3 ignored, and the other three signals at their defaults, from a parent started that way, on all three parts (control)" "$_db2_k $(_db2_cnt "$_db2_c/d1.out" djy-mode:serial)" "3 3"
    _db2_leak="$_db2_l3"
    _db2_is "R13: from a parent started with $_db2_w3 ignored the three parts ran as units under -j 3 and read what a -j 1 run reads, the run passed with exit 0 (not the runner's 124) and left nothing in its group" \
       "$(_db2_cnt "$_db2_c/d3.out" djy-mode:unit) $([ "$_db2_x3" = "$_db2_x1" ] && echo same || echo "differ [$_db2_x3] [$_db2_x1]") $_db2_r3" "3 same 0"
  fi
done
rm -rf "$DB2/n/dis"

# ---- an interrupt (D6): units are up, the signal goes to the parent, and the run ends as D6 says. The slot files are the same files afterwards (no step removes a slot)
# CASE SIGNAL STATUS [INT QUIT]: a -j 2 run of three parts, SIGNAL once the first two are up: _db2_x is "ok", or what was wrong
_db2_intr() {
  local c="$1" s="$2" w="$3" r="" g
  _db2_sl "$c"
  _db2_new "$c" "$DB2/g-empty.tsv" + "$DB2/pp/$c"/*.sh || { _db2_x="the copy could not be made"; return 0; }
  _db2_I="${4:-DEFAULT}"; _db2_Q="${5:-DEFAULT}"
  _db2_go i -j 2
  _db2_why=""; _db2_evt _db2_up 0010-sa.sh || r=" no unit came up;"   # R56: bounds that last until the run's bound (were 90 s and 15 s)
  _db2_evt _db2_up 0020-sb.sh || r="$r the second unit did not come up;"
  _db2_ino0="$(_db2_inos "$_db2_tmp")"; [ -n "$_db2_ino0" ] || r="$r no slot file before the signal;"
  sleep 0.5
  _db2_stop i "$s"; r="$r$_db2_late"
  g="$(_db2_gone i "$w")"; _db2_ino0=""; [ "$g" = ok ] || r="$r$g"
  [ ! -e "$_db2_c/started.0030-sc.sh" ] || r="$r the part that was queued started;"
  _db2_x="${r:-ok}"; rm -rf "$_db2_c"
}
_db2_intr i-term TERM 143
_db2_is "D6: TERM to the parent while two units run and a third waits: exit 143, no reached, nothing of the run left, no slot held, the slot files kept (names and inodes), no receipt, the queued unit never started" "$_db2_x" ok
_db2_intr i-int INT 130
_db2_is "D6: INT to a parent started with INT at its default: exit 130, with the same afterwards" "$_db2_x" ok
_db2_intr i-hup HUP 129
_db2_is "D6: HUP to the parent: exit 129, with the same afterwards" "$_db2_x" ok
_db2_intr i-quit QUIT 131
_db2_is "R4: QUIT to a parent started with QUIT at its default: exit 131, no reached, no unit, holder or wrapper left, no slot held, the slot files kept, no receipt" "$_db2_x" ok
_db2_intr i-ign TERM 143 IGNORE IGNORE
_db2_is "D6: TERM to a parent started with INT and QUIT both ignored: exit 143, with the same afterwards" "$_db2_x" ok

# ---- a child that ignores TERM and is moved to pid 1 when its unit dies, and what it forks (D6, the ending). With a ps first on PATH that fails the ending's Nth listing (R2)
# R47: FILE JP N JCMD: from the log of counted calls (N, TAB, the chain of pids from the caller up to the -j parent, TAB, the caller's command line), whose call the failed one was,
# checked against what the case read itself, after the run was up, from ps -o command= -p JP: JCMD, the -j parent's command line. Every logged call must have the -j parent (the
# pid JP of the case's pid file) at the top of its chain, at most one process between ps and the -j parent (a chain of one pid or of two), and a caller that is the -j parent itself
# or carries exactly JCMD (a $( ) of it). The check does not read the shim's own decision. Prints nothing when the call numbered N is in the log and every logged call keeps to that;
# else a sentence that says whose call it was, for the case's got text
_db2_psown() {
  [ -n "$4" ] || { printf ' the -j parent'"'"'s command line could not be read, so whose call listing %s was cannot be checked;' "$3"; return 0; }
  LC_ALL=C awk -F'\t' -v jp="$2" -v n="$3" -v jc="$4" '
    function trim(x) { sub(/^ +/, "", x); sub(/ +$/, "", x); return x }
    { m = split($2, a, ">"); top = a[m]; why = ""
      if (top != jp) why = "it did not come from the -j parent (" jp ") but from the top of the chain " $2
      else if (m > 2) why = "more than one process lies between ps and the -j parent"
      else if (a[1] != jp && trim($3) != trim(jc)) why = "its caller is no $( ) of the -j parent (its command line is not [" trim(jc) "])"
      if ($1 == n) { seen = 1; who = "pid " a[1] " (chain " $2 "; command line [" $3 "])" }
      if (why != "" && !bad) { bad = 1; bn = $1; bw = "pid " a[1] " (chain " $2 "; command line [" $3 "]): " why } }
    END { if (!seen) printf " listing %s, the one to fail, is not in the log of counted calls;", n
      else if (bad && bn == n) printf " listing %s failed was a call of %s, not the -j parent'"'"'s ending;", n, bw
      else if (bad) printf " counted call %s was a call of %s;", bn, bw }' "$1" 2>/dev/null
}
_db2_igr() {   # CASE MODE [N]: MODE n h s: a unit starts that child with & and waits, MODE u: the unit itself ignores TERM and forks a sleeper on it; TERM to the parent; afterwards nothing of the run runs, stopped or not
  local c="$1" m="$2" n="${3:-}" r="" g y
  # R61: the unit's loop, its sleepers (sl.pl) and the wait for ign.pid end once the case's directory is gone
  if [ "$m" = u ]; then _db2_w "$c" 0010-ka.sh <<'X'
trap 'perl "$DJ2L/sl.pl" "$DJ2D" 630 "$DJ2I" gc & echo $! >> "$DJ2D/gc.pids"' TERM
: > "$DJ2D/up.$DJ2N"
while [ -d "$DJ2D" ]; do sleep 0.1; done
X
  else _db2_w "$c" 0010-ka.sh <<'X'
perl "$DJ2L/ign.pl" "$DJ2D" "$DJ2I" "$(cat "$DJ2D/mode")" &
until [ -s "$DJ2D/ign.pid" ] || [ ! -d "$DJ2D" ]; do sleep 0.1; done
: > "$DJ2D/up.$DJ2N"
wait
X
  fi
  _db2_new "$c" "$DB2/g-empty.tsv" + "$DB2/pp/$c"/0010-ka.sh || { _db2_x="the copy could not be made"; return 0; }
  printf '%s' "$m" > "$_db2_c/mode"
  [ -z "$n" ] || _db2_E=(PATH="$DB2/psshim:$PATH" DJ2_PSREAL="$(command -v ps)" DJ2_PSFAIL="$n" DJ2_PSTRIG="$_db2_c/trig" DJ2_PSCNT="$_db2_c/pscnt" DJ2_PSJP="$_db2_c/i.pid" DJ2_PSKEY="$(_db2_key)")
  _db2_go i -j 2
  _db2_why=""; _db2_evt _db2_up 0010-ka.sh || r=" no unit came up;"   # R56: a bound that lasts until the run's bound (was 90 s)
  _db2_ino0="$(_db2_inos "$_db2_tmp")"; [ -n "$_db2_ino0" ] || r="$r no slot file before the signal;"
  _db2_jcmd=""; [ -z "$n" ] || _db2_jcmd="$(ps -ww -o command= -p "$(_db2_pid i)" 2>/dev/null | sed 's/^ *//; s/ *$//')"   # R47: the -j parent's command line, read here and not from the shim
  sleep 0.5; : > "$_db2_c/trig"
  _db2_stop i TERM; r="$r$_db2_late"
  g="$(_db2_gone i 143)"; _db2_ino0=""; [ "$g" = ok ] || r="$r$g"
  case "$m" in h|u) [ -s "$_db2_c/gc.pids" ] || r="$r the TERM never reached the child, which forked nothing;" ;; esac
  y="$({ wc -l < "$_db2_c/pscnt"; } 2>/dev/null | tr -d ' ')"
  [ -z "$n" ] || [ "${y:-0}" -ge "$n" ] || r="$r the ending asked for ${y:-0} listings, so listing $n never failed;"
  [ -z "$n" ] || r="$r$(_db2_psown "$_db2_c/pscnt" "$(_db2_pid i)" "$n" "$_db2_jcmd")"
  [ -z "$n" ] || [ -z "${DJX_PSLOG:-}" ] || { printf '== %s: failed call %s, counted calls (N, caller>...>-j parent, caller command), then passed calls\n' "$c" "$n"; cat "$_db2_c/pscnt" 2>/dev/null; echo "-- passed"; cat "$_db2_c/pscnt.pass" 2>/dev/null; } >> "$DJX_PSLOG"
  _db2_kf "$_db2_c/gc.pids" "$_db2_c/ign.pid"
  _db2_x="${r:-ok}"; rm -rf "$_db2_c"
}
_db2_igr g-ign n
_db2_is "D6: a child a unit started with & that ignores TERM, once the unit dies on TERM and the child is at pid 1, is gone when the parent has ended" "$_db2_x" ok
_db2_igr g-h h
_db2_is "D6: and so is the sleeper that child forked in its TERM handler, which is a descendant of a pid the parent had listed" "$_db2_x" ok
_db2_igr g-s s
_db2_is "D6: and so are the sleepers a child forks every 20 ms from its first TERM on, which only STOP can hold still" "$_db2_x" ok
for _db2_n in 1 2 3; do
  _db2_igr "r2-$_db2_n" u "$_db2_n"
  _db2_is "R2: with the ending's listing number $_db2_n failing (a ps first on PATH that exits 1 once), a unit that ignores TERM and forks a sleeper when it gets one leaves nothing, stopped or running, once the parent has exited with 143" "$_db2_x" ok
done

# ---- start-up (R18): TERM at a spread of short delays after the parent's prelude, over many units under -j 4, leaves no wrapper, holder or unit once the parent has exited. The fork window of R3 itself (microseconds) rests on review and on its 12-of-12 measurement, not on this case
# R56: each unit runs until it is ended, 630 s (B + 30). It ran 0.6 s, so a unit a build left behind ended by itself within R12's drain and this case's look, and a build
# that left one passed; L, the leftover's own end, is now far past both. The delays place the TERM (the case's subject) and are not windows
for _db2_n in 1 2 3 4 5 6 7 8 9 10 11 12; do _db2_w r3 "$(printf '%04d' $((_db2_n * 10)))-r$_db2_n.sh" <<'X'
: > "$DJ2D/started.$DJ2N"
perl "$DJ2L/sl.pl" "$DJ2D" 630 "$DJ2I" r3   # the case's id, so that a unit's sleeper left outside the run's group is seen too; R61: it ends once the case's directory is gone
ok "djy $DJ2N"
X
done
_db2_new r3 "$DB2/g-empty.tsv" + "$DB2/pp/r3"/*.sh; _db2_pre; _db2_x=""
for _db2_d in 0 0.02 0.05 0.08 0.12 0.2 0.35 0.6; do
  rm -f "$_db2_c"/pre.done.* "$_db2_c"/started.*; _db2_go t -j 4
  _db2_why=""; _db2_evt _db2_pre_up || _db2_x="$_db2_x [delay $_db2_d: the parent's prelude never ended]"; sleep "$_db2_d"; _db2_stop t TERM
  _db2_y="$(_db2_gone t 143)"; [ "$_db2_y" = ok ] || _db2_x="$_db2_x [delay $_db2_d:$_db2_y$_db2_late]"
done
_db2_is "D6: TERM at a spread of short delays during a -j 4 run's start-up (twelve units that each run until they are ended, eight delays from 0 to 0.6 s after the parent's prelude) ends everything: each time exit 143, and no wrapper, holder or unit runs once the parent has exited" "${_db2_x:-ok}" ok
rm -rf "$DB2/n/r3"

# ---- units that outlive their wrapper (R4). With FELIX_TEST_SLOT_NOTE unset the parent looks for a wrapper that is gone only on its ticks, every 30 s (R13); revision 17 also stops the parent while the window runs, since its next tick can come at any moment after the kill, so that the holder's own check is the only thing that can end the holder and its unit
# a wrapper killed with kill -9 while its unit runs a member longer than that silence: the holder and the unit are gone within 60 s, the unit has no mark, and neither it nor its holder runs once the parent has exited. The run is read through a pipe
# R56, a margin: T = 60 s from the kill to the first listing that shows neither. Inside it D's holder sees its parent change (each second) and ends the unit's tree as R2 says,
# with ps listings (forks), so the floor is 20 s. L: a holder without R4's check, with the parent stopped, leaves both running until the unit's own end, B + 30 s (3150 polls)
# after the kill, so T is far below L - 10 s. It was 3 s, below the floor, and with the parent running a tick could end them within it whatever the holder did
_db2_w lu 0010-wa.sh <<'X'
_d="$(cat "$DJ2D/w.pid")"; _p=$$; _w=""
while [ -n "$_p" ] && [ "$_p" -gt 1 ]; do
  _pp="$(ps -o ppid= -p "$_p" 2>/dev/null | tr -d ' ')"
  [ -n "$_pp" ] || break
  if [ "$_pp" = "$_d" ]; then _w="$_p"; break; fi
  _p="$_pp"
done
printf '%s %s\n' "$$" "$(ps -o ppid= -p $$ 2>/dev/null | tr -d ' ')" > "$DJ2D/lu.pids"
: > "$DJ2D/wrapper.${_w:-none}"
: > "$DJ2D/ready"
_i=0; until [ -e "$DJ2D/go" ] || [ ! -d "$DJ2D" ] || [ "$_i" -ge 3150 ]; do sleep 0.2; _i=$((_i + 1)); done
[ -z "$_w" ] || kill -KILL "$_w" 2>/dev/null
: > "$DJ2D/killed"
_i=0; until [ -e "$DJ2D/release" ] || [ ! -d "$DJ2D" ] || [ "$_i" -ge 3150 ]; do sleep 0.2; _i=$((_i + 1)); done
ok "djy $DJ2N"
X
_db2_w lu 0020-wb.sh <<'X'
ok "djy $DJ2N"
X
_db2_new lu "$DB2/g-empty.tsv" + "$DB2/pp/lu"/*.sh
_db2_pipe=1; _db2_go w -j 2
_db2_r=""; _db2_why=""; _db2_evt test -e "$_db2_c/ready" || _db2_r=" the unit never got ready (${_db2_why:-});"
_db2_jp="$(_db2_pid w)"; _db2_js=""
# the -j parent is stopped by the pid run.pl recorded, and only where the unit found a wrapper below it: a serial build may run the unit in that process itself
[ -n "$_db2_r" ] || for _db2_p in "$_db2_c"/wrapper.[0-9]*; do [ -e "$_db2_p" ] && _db2_js="$_db2_jp"; done
[ -z "$_db2_js" ] || kill -STOP "$_db2_js" 2>/dev/null
: > "$_db2_c/go"
_db2_x="$(DJ2_DIR="$_db2_c" DJ2_RUN="$_db2_jp" perl "$DB2/djk.pl" 0 0 "$_db2_c/killed" 60000 pidfile "$_db2_c/lu.pids")"; _db2_y="$(_db2_alive "$_db2_jp" && echo parent-there || echo parent-gone)"
[ -z "$_db2_js" ] || kill -CONT "$_db2_js" 2>/dev/null
_db2_dk kill-to-gone 60000 "$_db2_x"
_db2_is "R4: with the parent stopped by the case, so that only the holder's own check of its wrapper can act, a unit whose wrapper was killed with kill -9 is ended with its holder: within 60 s of the kill both are gone, and the parent is still there" "${_db2_x%% *} $_db2_y$_db2_r" "gone parent-there"
_db2_wait0
_db2_lk eof test -e "$_db2_c/w.eof"; _db2_x="$([ -e "$_db2_c/w.eof" ] && echo closed || echo open)"   # R56, a margin (floor 10 s: the reader acts on EOF, no fork); stands
# R56, a margin: 50 polls (10 s at least; was 5 s) for the unit and its parent (lu.pids) to be gone once the run has ended. Inside it D's build does nothing: R4 ended
# both within the window above, before the parent went on, so at most they act on a KILL already sent, no fork: floor 10 s. L: a build without R4's ending of a lost
# unit (no check of its own parent in the holder, no ending of the holder by the parent), whose parent fails the unit and exits, leaves both running until the unit's
# own end, 3150 polls of 0.2 s (B + 30 s) after go
_db2_mt="$(_db2_now)"; _db2_y=""; for _db2_p in $(cat "$_db2_c/lu.pids" 2>/dev/null); do _db2_until 50 _db2_dead "$_db2_p" && continue; _db2_y="$_db2_y $_db2_p"; done
_db2_ml margin lu/pids T 10000 ms "$([ -z "$_db2_y" ] && _db2_since "$_db2_mt" || echo none)"
_db2_x="$_db2_rc $(ls "$_db2_c" | grep -c '^wrapper\.[0-9]') $(_db2_cnt "$_db2_c/w.out" '  FAIL  part ended without its mark: 0010-wa.sh') $(_db2_pfx "$_db2_c/w.out" '  FAIL  part ended without its mark: 0020-wb.sh') $(_db2_rcpt) $_db2_x${_db2_y:+ still-running:$_db2_y}"
_db2_kf "$_db2_c/lu.pids"; _db2_fin
_db2_is "R4: the wrapper of a unit killed with kill -9 while the unit runs a member longer than the parent's silence: that unit alone fails without its mark, exit 1, no receipt, and once the parent has exited neither the unit nor its holder runs and the pipe it read is closed" "$_db2_x" "1 1 1 0 absent closed"
rm -rf "$DB2/n/lu"

# a wrapper killed with kill -9 while its holder waits for a slot another process holds: once the slot is let go no unit of that holder starts, and the holder is gone within 20 s
# R56, a margin: T = 20 s from the kill to the first listing without the holder. Inside it D's holder only sees its parent change (each second) and exits, with no fork:
# floor 10 s. L: a holder without R4's check while it waits, with the -j parent stopped (its tick could otherwise end the lost holder at any moment) and the slot held,
# waits on until the case lets the parent go, past T. It was 3 s, below the floor. The search for the wrapper is a bound that lasts until the run's bound (was 60 s)
_db2_q hk; _db2_td="$DB2/td-hk"; rm -rf "$_db2_td"; mkdir -p "$_db2_td"
_db2_new hk "$DB2/g-empty.tsv" + "$DB2/pp/hk"/0010-qa.sh
_db2_hold "$_db2_tmp/felix-suite-slots/0"; _db2_ino0="$(_db2_inos "$_db2_tmp")"
_db2_S=1; _db2_go h -j 2
_db2_r=""; _db2_wr=""
while :; do _db2_d="$(_db2_pid h)"; [ -z "$_db2_d" ] || _db2_wr="$(_db2_wh "$_db2_d")"; [ -z "$_db2_wr" ] || break; kill -0 "$_db2_bg" 2>/dev/null || break; [ "$SECONDS" -lt "$_db2_dl" ] || break; sleep 0.2; done
_db2_y=""
if [ -z "$_db2_wr" ]; then _db2_r=" no wrapper with a holder was found;"
else
  sleep 1.5; _db2_hd="${_db2_wr#* }"; _db2_jp="$(_db2_pid h)"
  # the slot is still held when the holder is looked for, and the -j parent is stopped (by the pid run.pl recorded): only the holder's own check of its parent can end it
  [ -z "$_db2_jp" ] || kill -STOP "$_db2_jp" 2>/dev/null
  _db2_y="$(DJ2_DIR="$_db2_c" perl "$DB2/djk.pl" KILL "${_db2_wr% *}" - 20000 pids "$_db2_hd")"; _db2_dk kill-to-gone 20000 "$_db2_y"
  _db2_alive "$_db2_jp" || _db2_r="$_db2_r the parent was gone when the holder was looked for;"
  case "$_db2_y" in gone*) ;; *) _db2_r="$_db2_r the holder was still there within 20 s of its wrapper being killed, the slot held ($_db2_y);" ;; esac
  _db2_unhold
  # R58, a watch: 2.5 s from the slot's release, then a look for a unit of the lost holder; the parent is let go only after it. It may stay short of R58's 20 s:
  # the build it watches for, a holder that goes on waiting once its wrapper is gone and starts its unit when the slot is let go, is a holder still there 20 s
  # after its wrapper's kill, which this name's djk.pl check above already fails; and with that holder gone and the parent stopped, nothing can start the unit
  sleep 2.5; _db2_mt=none
  [ -z "$(_db2_started)$(_db2_units)" ] || { _db2_r="$_db2_r a unit of that holder ran ($(_db2_started)$(_db2_units));"; _db2_mt=2500; }
  _db2_ml margin hk/freed T 2500 ms "$_db2_mt"
  [ -z "$_db2_jp" ] || kill -CONT "$_db2_jp" 2>/dev/null
fi
_db2_wait; _db2_x="$_db2_rc $(_db2_cnt "$_db2_c/h.out" '  FAIL  part ended without its mark: 0010-qa.sh') $(_db2_rcpt)${_db2_r}"
_db2_unhold; _db2_ino0=""
_db2_is "R4: the wrapper of a unit killed with kill -9 while its holder waits for a slot another process holds: with the parent stopped by the case the holder is gone within 20 s by its own check, the slot still held; once the slot is let go no unit starts; the unit has no mark, exit 1, no receipt" "$_db2_x" "1 1 absent"
rm -rf "$DB2/n/hk" "$DB2/td-hk"; _db2_td=""

# ---- R20, R35: a holder also asks, at least every 10 s and just before it forks, who its wrapper's parent is (ps -o ppid= -p WRAPPER), and takes a pid other than the -j parent's for the parent gone.
# The kill 0 of the parent's pid does not see that while the pid is alive, and R15's start-time comparison is the Linux clock-step hazard R20 removes. A ps first on PATH answers that one call (its arguments
# hold ppid= and -p and no -A) with 1 once a gate file exists, and logs each answer it gave in $DJ2_PSCNT. The gate is written once the unit is up: within 60 s the unit is gone, the parent fails it without its mark
# R56, a margin: T = 60 s from the gate to the first listing without the unit. Inside it D's holder asks at its next check (within 10 s) and ends the unit's tree with ps
# listings (forks): floor 20 s, and its own wait of up to 10 s is half of that, so T is 60 s (was 20 s). L: a holder without R20's check (kill 0 of a parent that lives,
# or R15's start-time comparison) never ends the unit, which runs until the case releases it after the window, B + 30 s at most (3150 polls; was 90 s)
cat > "$DB2/oshim/ps" <<'DB2OS'
#!/bin/sh
# The real ps ($DJ2_PSREAL), except that once the file $DJ2_GATE exists a call that holds ppid= and -p and no -A prints 1 (and is logged in $DJ2_PSCNT).
case " $* " in
  *" -A "*) ;;
  *ppid=*" -p "*) if [ -e "$DJ2_GATE" ]; then echo x >> "$DJ2_PSCNT"; echo 1; exit 0; fi ;;
esac
exec "$DJ2_PSREAL" "$@"
DB2OS
chmod +x "$DB2/oshim/ps"
_db2_w or 0010-oa.sh <<'X'
printf '%s %s\n' "$$" "$(ps -o ppid= -p $$ 2>/dev/null | tr -d ' ')" > "$DJ2D/or.pids"
: > "$DJ2D/up.$DJ2N"
_i=0; until [ -e "$DJ2D/release" ] || [ ! -d "$DJ2D" ] || [ "$_i" -ge 3150 ]; do sleep 0.2; _i=$((_i + 1)); done
ok "djy $DJ2N"
X
_db2_new or "$DB2/g-empty.tsv" + "$DB2/pp/or"/0010-oa.sh
_db2_E=(PATH="$DB2/oshim:$PATH" DJ2_PSREAL="$(command -v ps)" DJ2_GATE="$_db2_c/gate" DJ2_PSCNT="$_db2_c/oans")
_db2_go o -j 2
_db2_r=""; _db2_why=""; _db2_evt _db2_up 0010-oa.sh || _db2_r=" no unit came up (${_db2_why:-});"
_db2_ino0="$(_db2_inos "$_db2_tmp")"
: > "$_db2_c/gate"
_db2_y="$(DJ2_DIR="$_db2_c" perl "$DB2/djk.pl" 0 0 - 60000 pidfile "$_db2_c/or.pids")"; _db2_dk gate-to-gone 60000 "$_db2_y"
: > "$_db2_c/release"
_db2_wait
# the run is not interrupted: it ends by itself with the unit's failure, so it reaches its end (reached is printed) and _db2_gone's reached test does not apply
[ "$_db2_rc" = 1 ] || _db2_r="$_db2_r exit $_db2_rc, not 1;"
# R56, a margin: 50 polls (10 s at least; was 5 s) for nothing of the run to be left once it has ended, after R12's drain of its group. Inside it D's build does
# nothing: R20's holder ended the unit within the window above, and the parent's end leaves nothing (D6), so at most a process acts on a KILL already sent, no fork:
# floor 10 s. L: the unit ends by itself at the release written before this look, so what this look can find is a process a build leaves running after its parent's
# exit that does not end by itself (a holder that took its parent for gone and neither ends nor exits, outside the group): L is its own end, unbounded
_db2_lk left _db2_clear "$(_db2_pid o)" || _db2_r="$_db2_r still running: $(_db2_ps "$(_db2_pid o)");"
[ -z "$(_db2_held "$_db2_tmp")" ] || _db2_r="$_db2_r a slot is still held;"
[ "$(_db2_inos "$_db2_tmp")" = "$_db2_ino0" ] || _db2_r="$_db2_r the slot files changed;"
[ "$(_db2_rcpt)" = absent ] || _db2_r="$_db2_r a receipt was left;"
_db2_ino0=""
_db2_x="${_db2_y%% *} $([ "$(wc -l < "$_db2_c/oans" 2>/dev/null | tr -d ' ')" -ge 1 ] 2>/dev/null && echo asked || echo not-asked) $(_db2_cnt "$_db2_c/o.out" '  FAIL  part ended without its mark: 0010-oa.sh')${_db2_r:- ok}"
_db2_is "R20: a holder whose ps -o ppid= -p WRAPPER is answered with another pid than the -j parent's takes the parent for gone: within 60 s of that answer the unit is gone, the holder asked and was answered, the parent, still running, fails the unit without its mark, exit 1, no receipt, no slot held, and nothing of the run is left" "$_db2_x" "gone asked 1 ok"
rm -rf "$DB2/n/or"

# while a unit runs, its holder's stdout and stderr are the unit's log: one regular file, the one the unit's own stdout is
_db2_w hs 0010-ha.sh <<'X'
: > "$DJ2D/up.$DJ2N"
_i=0; until [ -e "$DJ2D/release" ] || [ ! -d "$DJ2D" ] || [ "$_i" -ge 3150 ]; do sleep 0.2; _i=$((_i + 1)); done
ok "djy $DJ2N"
X
_db2_n="R4: while a unit runs, its holder's stdout and stderr are the unit's log: both name one regular file, which is the file the unit's own stdout names, and the run then passes"
if [ ! -d /proc/self/fd ] && ! command -v lsof >/dev/null 2>&1; then skip "$_db2_n" "neither /proc nor lsof here to read a process's descriptors"
else
  _db2_new hs "$DB2/g-empty.tsv" + "$DB2/pp/hs"/0010-ha.sh; _db2_go s -j 2
  _db2_evt _db2_up 0010-ha.sh; _db2_uhv=""; _db2_k=0   # R56: a bound until the run's bound (was 90 s): the unit stays until it is released
  # R56, a margin: a look after that event, 50 polls (10 s at least; stands). Inside it D's build does nothing: its holder is the unit's parent before the unit
  # writes up, and both stay until release, so the first listing finds both; with no fork of D's inside, the floor is 10 s. L: a build without a holder for the
  # unit (a serial run, or a unit no holder started) never shows the pair, so L is unbounded
  _db2_mt="$(_db2_now)"; while [ "$_db2_k" -lt 50 ] && [ -z "$_db2_uhv" ]; do _db2_uhv="$(_db2_uh)"; [ -n "$_db2_uhv" ] || sleep 0.2; _db2_k=$((_db2_k + 1)); done
  _db2_ml margin hs/pair T 10000 ms "$([ -n "$_db2_uhv" ] && _db2_since "$_db2_mt" || echo none)"
  _db2_f1="$(_db2_fdn "${_db2_uhv#* }" 1)"; _db2_f2="$(_db2_fdn "${_db2_uhv#* }" 2)"; _db2_fu="$(_db2_fdn "${_db2_uhv% *}" 1)"
  _db2_ff="$([ -n "$_db2_f1" ] && [ -f "$_db2_f1" ] && echo file || echo not-a-file)"   # while the unit runs: its parent's EXIT trap removes $TMP, and the log with it, once the run has ended
  : > "$_db2_c/release"; _db2_wait
  _db2_is "$_db2_n" "$([ -n "$_db2_f1" ] && [ "$_db2_f1" = "$_db2_f2" ] && [ "$_db2_f1" = "$_db2_fu" ] && [ "$_db2_ff" = file ] && echo same || echo "holder 1 [$_db2_f1] 2 [$_db2_f2], unit 1 [$_db2_fu], $_db2_ff") $_db2_rc" "same 0"
  rm -rf "$DB2/n/hs"
fi

# a background child a unit leaves running holds no slot lock, and does not keep a pipe that reads the run open (out=$(tests/run -j 2 ...) returns when the run ends)
_db2_w lc 0010-la.sh <<'X'
( perl -e 'open(my $h, ">", $ARGV[0]); print $h "$$\n"; close $h; my $e = time + 630; sleep 1 while time < $e && -d $ARGV[2]' "$DJ2D/lc.pid" "$DJ2I" "$DJ2D" lc & )   # no job of this shell (R16): it is left behind as D6's Reach says; R61: it ends once the case's directory is gone
until [ -s "$DJ2D/lc.pid" ] || [ ! -d "$DJ2D" ]; do sleep 0.1; done
ok "djy $DJ2N"
X
_db2_w lc 0020-lb.sh <<'X'
ok "djy $DJ2N"
X
_db2_new lc "$DB2/g-empty.tsv" + "$DB2/pp/lc"/*.sh
_db2_pipe=1; _db2_go l -j 2; _db2_wait0
# R56, a margin: T = 10 s from the driver's exit to the pipe's EOF. D's build only has the pipe closed by the exit (no fork): floor 10 s. L: a build whose child
# keeps the pipe holds it open until the child ends, 630 s (B + 30; was 60 s, which a loaded run could outlast, and "child-alive" with it)
_db2_lk eof test -e "$_db2_c/l.eof"
_db2_x="$_db2_rc $([ -e "$_db2_c/l.eof" ] && echo closed || echo open) $(_db2_alive "$(cat "$_db2_c/lc.pid" 2>/dev/null)" && echo child-alive || echo child-gone) [$(_db2_held "$_db2_tmp")] $(_db2_cnt "$_db2_c/l.out" reached)"
_db2_kf "$_db2_c/lc.pid"; _db2_fin
_db2_is "D6: a background child a unit leaves running holds no slot lock: the run passes, the child is still there, and every slot file grants its lock" "${_db2_x% *}" "0 closed child-alive []"
_db2_is "R4: a run read through a pipe, as out=\$(tests/run -j 2 ...) reads it, ends with the run though a unit left a background child: the pipe is closed within 10 s and the output reached its end" "$(set -- $_db2_x; echo "$2 $5")" "closed 1"
rm -rf "$DB2/n/lc"

# ---- a record run that is interrupted writes no manifest (D6, what it leaves), and red's tree goes with it
_db2_sl rrt; _db2_new rrt --red "$DB2/g-empty.tsv" "$DB2/man.tsv" "$DB2/pp/rrt"/*.sh
_db2_go r -j 2 --record-assertions   # R44, R55: the waits below last until the run's bound (600 s, plus 5; was 240 s)
_db2_miss=""   # R44: each wait lasts until the run's own bound, and an event that never came fails the name (the got text says which) instead of the TERM going on as though it had
_db2_why=""; _db2_evt _db2_up 0010-sa.sh || _db2_miss="$_db2_miss up.0010-sa.sh"
_db2_evt _db2_up 0020-sb.sh || _db2_miss="$_db2_miss up.0020-sb.sh"
_db2_evt _db2_rup 0010-sa.sh || _db2_miss="$_db2_miss rup.0010-sa.sh"
# optional by R42 (d): only a -j 2 red's suite writes rup.0020-sb.sh, a serial one (the base's) never does, so it is not waited for to the bound
# R56: that 5 s is a pause, not a margin: whether it ran out or not, no name reads it (both-up is the record run's own up.0020-sb.sh, waited for above); it stands.
# R61: it also ends once the run has exited
_db2_k=0; while [ "$_db2_k" -lt 25 ] && ! _db2_rup 0020-sb.sh && kill -0 "$_db2_bg" 2>/dev/null; do sleep 0.2; _db2_k=$((_db2_k + 1)); done
sleep 0.5; _db2_ino0="$(_db2_inos "$_db2_tmp")"
# R59: the TERM ends the record run before red's tree, which its watcher then ends, giving red up to 30 s: so the drain of the run's group after it is a bound,
# until the run's bound has passed (_db2_stop's bound), over as soon as the group is empty, and only what is there at its end fails the name. L: a build whose record
# run, ended by a signal, leaves red's tree (no watcher, or one that does not end red) leaves red's units waiting for a release this case never writes, 3150 polls
# of at least 0.2 s (B + 30 s) from their start, which is past the bound's end
if [ -z "$_db2_miss" ]; then _db2_stop r TERM bound; else _db2_stop r KILL bound; _db2_miss=" [no TERM was sent: these never came before ${_db2_why:-the bound of the run passed}:$_db2_miss]"; fi
_db2_x="$([ -e "$_db2_c/up.0020-sb.sh" ] && echo both-up || echo one-up) $(cmp -s "$DB2/man.tsv" "$_db2_T/assertions.tsv" && echo same || echo changed) $(_db2_cnt "$_db2_c/r.out" reached) $(_db2_pfx "$_db2_c/r.out" '  recorded ') $(_db2_rcpt) $([ -n "$_db2_ino0" ] && [ "$(_db2_inos "$_db2_tmp")" = "$_db2_ino0" ] && echo slots-kept || echo slots-changed)${_db2_miss}${_db2_late}"; _db2_ino0=""; _db2_miss=""
_db2_is "D6: TERM to a record run under -j 2, both units up: exit 143, the manifest as it was, no reached, no recorded line, no receipt, the slot files kept, and nothing of red's tree left in the run's group" "$_db2_rc $_db2_x" "143 both-up same 0 0 absent slots-kept"
rm -rf "$DB2/n/rrt"

# ---- no unit holds the FIFO the parent reads (D6, the wrapper): no pipe descriptor above 2 in a unit that a serial part has not
_db2_w fd 0010-pf.sh <<'X'
_probe() { perl -e 'for my $n (3 .. 250) { open(my $h, "<&=", $n) or next; print "$n " if -p $h }'; }
printf 'djy-fds:[%s]\n' "$(_probe)"
if mkfifo "$DJ2D/ff.$$" 2>/dev/null; then exec 9<> "$DJ2D/ff.$$"; fi
printf 'djy-fds-ctl:[%s]\n' "$(_probe)"
exec 9>&-; rm -f "$DJ2D/ff.$$"
case "$(ps -p $$ -o command= 2>/dev/null)" in *" --part "*) printf 'djy-mode:unit\n' ;; *) printf 'djy-mode:serial\n' ;; esac
ok "djy $DJ2N"
X
_db2_new fd "$DB2/g-empty.tsv" + "$DB2/pp/fd"/*.sh; _db2_go f3 -j 3; _db2_wait; _db2_go f1 -j 1; _db2_wait
_db2_x3="$(sed -n 's/^djy-fds:\(.*\)$/\1/p' "$_db2_c/f3.out")"; _db2_x1="$(sed -n 's/^djy-fds:\(.*\)$/\1/p' "$_db2_c/f1.out")"; _db2_y3="$(sed -n 's/^djy-fds-ctl:\(.*\)$/\1/p' "$_db2_c/f3.out")"
case "$_db2_y3" in *9*) _db2_y3=sees-9 ;; *) _db2_y3="ctl [$_db2_y3]" ;; esac   # not inside $( ): bash 3.2 ends the substitution at the pattern's )
_db2_is "D6: a unit has no pipe or FIFO descriptor above 2 that the same part has not under -j 1, and the probe sees a FIFO a part opens itself" \
   "$([ "$_db2_x3" = "$_db2_x1" ] && echo same || echo "[$_db2_x3] differs from [$_db2_x1]") $_db2_y3 $(_db2_cnt "$_db2_c/f3.out" djy-mode:unit)" "same sees-9 1"
rm -rf "$DB2/n/fd"

# ---- R41 (a): what the stand-in made is all below this part's own case directories (the run's TMPDIR), so nothing of the nested runs is left in the host's temporary directory
_db2_x="$(LC_ALL=C awk -v a="$DB2/n/" -v b="$DB2/td-" 'index($0, a) == 1 || index($0, b) == 1 { n++; next } { o = o " " $0 } END { if (n > 0 && o == "") print "all below"; else print n + 0 " below, outside:" o }' "$DB2/mktemp.log" 2>/dev/null)"
is "R41: every path the mktemp stand-in logged for this part's nested runs is below one of the part's own case directories, and it logged some" "$_db2_x" "all below"

# ---- the part leaves the shell as it found it
_db2_unhold
rm -rf "${DB2:?}"
unset -f $(compgen -A function _db2_) 2>/dev/null
unset $(compgen -A variable _db2_) DB2 2>/dev/null
# <<< gate-friction-d-signals-blind
