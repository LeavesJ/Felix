# >>> gate-friction-d-slots-blind
printf '\ngate friction D: slots, the slots directory, the gate and the log (blind, author 2; revision 18)\n'
# Blind, written on 2026-10-18 from contract D, then rewritten on 2026-10-19 against revision 7 (D1 to D8 and
# "Amended after review 1"), by an author who read no implementation. tests/run, tests/red and tests/receipt.sh
# are run, never read, in copies of this suite that _suite_copy_tree (part 0003) makes under $TMP with planted
# parts of this block's own. Part 1292 holds what ends a run (signals, endings, holders); this part holds the
# slots (D6, R5, R6), the gate (D1, R10), the interface and the log (D1 to D4, R7). Names say the clause.
#
# Revision 17 (R54 to R57), from the contract alone. R54: the D4 wait case is one slot and two units, the body that runs first (it makes first.d) holds the slot
# 30 s and the other runs 2 s; R7's name asks that the unit whose body ran second gets the one note, with S at least 30, and D4's that the duration written for
# that unit is less than S. R55: every run bound is 600 s (_db4_lim, gate.sh's run.pl included, 90 s before). R56: every wait for an event of a run lasts until the run's
# bound has passed (_db4_evt), and so does the wait for a signalled parent (_db4_stop); holds and planted holds live B + 30 s and end with their slots directory;
# _db4_gone's look is 10 s; the kill -9 slot case's window is 20 s (L: a slot a dead holder's mark keeps 30 s); R6's window is 15 s, counted from the first listing
# that shows the holder (L: a parent that reads with W = 30 prints 30 s after the wrapper's start); the watches before "no unit while held" and "the log shows
# neither" start once a holder waits and once the quick units have exited. Each window, its kind and its L are in a comment beside it.
# Revision 17's review fixes: R6's case plants the mark at the end of 0006 again and lag.pl gives mark-to-holder beside the lag, which DJX_MLOG logs: of a W = 30
# parent's 30 s at most that much falls before the window, so T = 15 s stays at most 20 s less its largest under burners. The R6 control's T = 20 s is said to
# guard D's build (a holder slow to take a free slot), not to be red-first. The kill -9 slot window is shown red against a slot a dead holder's mark keeps 30 s
# only; a holder that retries every 30 s is not claimed to fail it.
# Revision 18 (R58, R61, R62), from the contract alone. R58, the watches: "no unit while held" (hw) lasts 20 s from the first listing that shows a waiting holder
# (was 2.5 s); R6's "still once" lasts 10 s from the line (was 3 s; its name says 10 s now); D3's "the log shows neither" lasts 20 s from the quick units' exit (was
# 3 s). Each is a poll that ends early once it finds what it watches for, which fails the name, or once the run has ended. hw-term's 3 s after the slot is let go
# stays: the same name's group drain and _db4_gone's look catch the holder it watches for. R61: lag.pl's waits end once the run has exited (after one more look) or
# the case's directory is gone; djk.pl's listings end at the run's exit or with the directory; the ps control's stand-ins and the slow unit's release wait end once
# their case directory is gone. R62: with DJX_MLOG naming a file, "1294 run CASE/LABEL bound B ms MS" for every run (gate.sh's too) and "1294 margin CASE/LABEL T
# T-MS ms MS|none" for every margin and watch; R6's mark-to-holder is logged in that form as nt/mark-to-holder with T 5000, the most of it T = 15 s allows, and
# the R6 control logs its free slot's mark-to-holder against its T of 20 s. R59 and R60 change nothing here: no case ends a record run with a signal or takes R1's
# at-exit listings. Review fix (revision 18): a run line's ms is the run's start-to-exit as run.pl, its bounded runner, saw it, from just before its fork to its
# waitpid's return (or its KILL at B, which its alarm counts from the same fork), written by run.pl at its exit; it was the time to the case's reaping, which put
# the two-run cases' first run at the second's end.
#
# Every case follows R12, as in 1292: TMPDIR is a fixture directory under $TMP, the copy runs under a bounded
# runner (run.pl) that leads its own process group and starts it with INT and QUIT as the case asks and HUP and
# TERM at their defaults, every wait is bounded, and when the run has ended the case waits up to 30 s for that
# group to hold no live process (stopped or running, zombies aside), fails with what it names, and then sends CONT
# and KILL to those pids. A process outside the group (a slot holder of mine) is ended by the pid recorded.
# No signal goes to a pid found by a pattern.
#
# Readings taken where the contract leaves room, for the reviewers to confirm:
# - "A -j 1 run takes none" is read as: it is not held up by a slot another process holds;
# - the slots directory's refusal line is read as starting "tests/run: the slots directory [" and holding the
#   phrase R5 names for the failure, and an entry's as "tests/run: [D/NAME] is not a regular file" (R19);
# - R6's line is read as printed within 15 s of the start of the first ps listing that shows the waiting unit's
#   holder (a perl whose command line holds " --part " and the case's key, R45), timed in a perl (lag.pl), and the first pre.done.* mark's mtime is the
#   end of the parent's prelude, which comes before its ticker or its read begins (mark-to-holder, logged for the evidence); the 20 s
#   after a kill -9 is timed in the perl (djk.pl) that takes the ps listing, from the kill to the start of the first
#   listing that shows a unit (revision 17: both were 5 s and 2 s, below R56's floors);
# - the wait note is told from the tail's note by R7's shape alone; a case with a manifest of the stubs only has
#   both, and counts each by its own shape;
# - the holder's own failure (the parent's lock passed, the holder's did not) is a unit with no mark;
# - the red.tsv rows of a record run that failed in the runner are read as base - - - and run - - -, with tabs
#   or blanks between the fields.
# An assertion whose name ends in (control) passes before D is built on purpose.
DB4="$TMP/db4"; mkdir -p "$DB4/n" "$DB4/pp"
# _db4_lim is every run's bound B (R55: 600 s, a run bound is not a margin); _db4_gn is R12's drain, 150 polls of 0.2 s (30 s), which R56 keeps
_db4_E=(); _db4_I=DEFAULT; _db4_Q=DEFAULT; _db4_lim=600; _db4_S=8; _db4_td=""; _db4_hp=0; _db4_ctl=0; _db4_bg=0; _db4_rc=0; _db4_lab=""
_db4_leak=""; _db4_ino0=""; _db4_late=""; _db4_x=""; _db4_gn=150; _db4_gskip=""; _db4_nomk=0; _db4_dl=0
: > "$DB4/g-empty.tsv"; printf '1\tdjy seed\n' > "$DB4/man.tsv"
cat > "$DB4/run.pl" <<'DB4PL'
# run.pl LIMIT INT QUIT PIDFILE MSFILE CMD...: CMD leads a process group of its own, started with INT and QUIT as given, HUP and TERM at their
# defaults and no descriptor above 2; at LIMIT seconds the group is killed (exit 124). Exits as bash reports CMD's status. MSFILE, when not empty, gets
# the ms from just before the fork to the waitpid's return or the KILL at LIMIT: the run's start-to-exit as this runner saw it (R62).
use POSIX ();
my ($t, $i, $q, $f, $m) = splice(@ARGV, 0, 5);
my $s = 0; if ($m ne "") { require Time::HiRes; $s = Time::HiRes::time() }
sub ms { if ($m ne "" && open(my $h, ">", $m)) { printf $h "%d\n", (Time::HiRes::time() - $s) * 1000; close $h } }
my $p = fork;
defined $p or exit 125;
if (!$p) { setpgrp(0, 0); $SIG{INT} = $i; $SIG{QUIT} = $q; $SIG{HUP} = "DEFAULT"; $SIG{TERM} = "DEFAULT"; POSIX::close($_) for 3 .. 255; exec @ARGV; exit 127 }
if (open(my $h, ">", "$f.t")) { print $h "$p\n"; close $h; rename "$f.t", $f }
$SIG{ALRM} = sub { kill "KILL", -$p; ms(); exit 124 };
alarm $t; waitpid $p, 0; my $w = $?; ms();
exit(($w & 127) ? 128 + ($w & 127) : $w >> 8);
DB4PL
# R41 (a): a stand-in mktemp first on PATH in every nested run but the placement cases of R5 and R29 (_db4_nomk=1: those keep the mktemp they have). Given no
# template (options only) it adds "$TMPDIR/tmp.XXXXXXXXXX", so the run's $TMP is below the case's TMPDIR on macOS too, where a template-less mktemp -d ignores
# TMPDIR; otherwise it passes its arguments on. It calls the host's mktemp by the path found before the stand-in was on PATH ($DJ4_MKREAL) and logs each path it
# made to $DJ4_MKLOG, one file for the whole part, which the closing assertion reads.
mkdir -p "$DB4/mkstand"; _db4_mkreal="$(command -v mktemp)"; : > "$DB4/mktemp.log"
cat > "$DB4/mkstand/mktemp" <<'DB4MS'
#!/bin/sh
t=
for a in "$@"; do case "$a" in -*) ;; *) t=1 ;; esac; done
[ -n "$t" ] || set -- "$@" "${TMPDIR:-/tmp}/tmp.XXXXXXXXXX"
p="$("$DJ4_MKREAL" "$@")" || exit $?
[ -z "${DJ4_MKLOG:-}" ] || printf '%s\n' "$p" >> "$DJ4_MKLOG"
printf '%s\n' "$p"
DB4MS
chmod +x "$DB4/mkstand/mktemp"
cat > "$DB4/lag.pl" <<'DB4LAG'
# lag.pl KEY FILE LINE MAXSEC MARKDIR RUNPIDFILE: waits (at most MAXSEC s, the run's bound) for a ps listing that shows a holder of the case's run, a live perl whose
# command line holds " --part " and KEY (what only a holder carries, R45), then for FILE to hold a line that is exactly LINE. Prints two fields: the ms from the start of
# that listing to the line ("none" when the line did not come, "no-holder" when no holder came; "-" when FILE is -, which waits for no line), then the ms from the
# earliest pre.done.* mark in MARKDIR (its mtime, to the ms) to the start of that listing ("none" without a mark or a holder): mark-to-holder, how much of a W = 30
# parent's 30 s can fall before the window (R56, evidence). R61: both waits are for events only the running run makes, so each ends once the run (the pid in
# RUNPIDFILE, once it is there) has exited, after one more look, and once MARKDIR, the case's directory, is gone
use Time::HiRes qw(time sleep stat);
my ($k, $f, $l, $m, $d, $pf) = @ARGV;
my $end = time + $m; my $t0; my $rp = 0;
sub m2h { my $e; if (opendir(my $h, $d)) { for (readdir $h) { next unless /^pre\.done\./; my @s = stat("$d/$_"); $e = $s[9] if @s && (!defined $e || $s[9] < $e) } closedir $h }
  (defined $e && defined $t0) ? sprintf("%d", ($t0 - $e) * 1000) : "none" }
sub gone { if (!$rp && open(my $h, "<", $pf)) { ($rp) = (<$h> // "") =~ /(\d+)/; $rp ||= 0; close $h } $rp && !kill(0, $rp) }
sub over { my $g = shift; $g || time >= $end || !-d $d }
while (1) {
  my $g = gone(); my $t = time;   # the run seen gone before this look: the look is the last one
  for (split /\n/, `ps -A -ww -o stat= -o command= 2>/dev/null`) {
    next unless /^\s*(\S+)\s+(\S+)(.*)$/; my ($s, $c, $r) = ($1, $2, $3); next if $s =~ /^Z/;   # copied: a match that succeeds resets $1 to $3
    if ($c =~ /perl/ && index("$c$r", " --part ") >= 0 && index("$c$r", $k) >= 0) { $t0 = $t; last }
  }
  last if defined $t0 || over($g); sleep 0.1;
}
defined $t0 or do { print "no-holder none\n"; exit 0 };
$f eq "-" and do { printf "- %s\n", m2h(); exit 0 };
while (1) {
  my $g = gone();
  if (open(my $h, "<", $f)) { while (<$h>) { chomp; if ($_ eq $l) { printf "%d %s\n", (time - $t0) * 1000, m2h(); exit 0 } } close $h }
  last if over($g); sleep 0.02;
}
printf "none %s\n", m2h();
DB4LAG
cat > "$DB4/djk.pl" <<'DB4DJK'
# djk.pl KILLPID MAXMS KEY RUNPID: kills KILLPID with KILL, takes the time T0, then takes ps listings until one shows a live unit process (a --part process whose
# command line holds KEY, not perl, not a zombie) or MAXMS ms have passed. Prints "seen MS" (MS: from T0 to the start of that listing) or "none MS". R61: the unit
# is an event only the running run makes, so the listings also end once RUNPID has exited, after one more listing
use Time::HiRes qw(time sleep);
my ($kp, $max, $key, $rp) = @ARGV;
$kp > 1 or exit 2;   # never a signal to a process group
kill "KILL", $kp;
my $t0 = time; my $last = 0;
while (1) {
  $last = 1 if $rp && !kill(0, $rp);
  my $t = time;
  for my $l (split /\n/, `ps -A -ww -o pid= -o stat= -o command= 2>/dev/null`) {
    next unless $l =~ /^\s*(\d+)\s+(\S+)\s+(\S+)(.*)$/;
    next if $2 =~ /^Z/ || $1 == $$ || $3 =~ /perl/;
    printf "seen %d\n", ($t - $t0) * 1000 and exit 0 if index($l, $key) >= 0 && index($l, " --part ") >= 0;
  }
  if (($t - $t0) * 1000 > $max || $last) { printf "none %d\n", (time - $t0) * 1000; exit 0 }
  sleep 0.05;
}
DB4DJK
_db4_until() { local n="$1" i=0; shift; while [ "$i" -lt "$n" ]; do "$@" && return 0; sleep 0.2; i=$((i + 1)); done; "$@"; }
_db4_cnt() { LC_ALL=C awk -v l="$2" '$0 == l { n++ } END { print n + 0 }' "$1" 2>/dev/null || echo 0; }   # FILE LINE: lines that are exactly LINE
_db4_pfx() { LC_ALL=C awk -v p="$2" 'index($0, p) == 1 { n++ } END { print n + 0 }' "$1" 2>/dev/null || echo 0; }   # FILE PREFIX: lines that start with it
_db4_wn()  { LC_ALL=C awk '/^  note  [^ ]+ waited [0123456789]+ s for a slot$/ { n++ } END { print n + 0 }' "$1" 2>/dev/null || echo 0; }   # FILE: R7's wait notes
_db4_tn()  { LC_ALL=C awk '/^  note  [0123456789]+ assertion\(s\) ran that the manifest does not list\.$/ { n++ } END { print n + 0 }' "$1" 2>/dev/null || echo 0; }   # the tail's note
_db4_ms()  { perl -MTime::HiRes=time -e 'printf "%d", time * 1000'; }
# R62: with DJX_MLOG naming a file, a line of evidence (never a verdict); _db4_now is the ms only when there is a log to write
_db4_ml()  { [ -z "${DJX_MLOG:-}" ] || printf '1294 %s\n' "$*" >> "$DJX_MLOG"; }
_db4_now() { [ -z "${DJX_MLOG:-}" ] || _db4_ms; }
_db4_since() { [ -n "$1" ] && echo $(( $(_db4_ms) - $1 )) || echo none; }   # T0: the ms since T0, or none without a log
# V: a time lag.pl gave, for the log: V when it is a whole number of ms, 0 when it is below 0 (the listing that showed the holder began before the mark), else none
_db4_msv() { if [ "$1" -ge 0 ] 2>/dev/null; then echo "$1"; elif [ "$1" -lt 0 ] 2>/dev/null; then echo 0; else echo none; fi; }
# R58, a watch: SECS LABEL PRED...: looks every 0.2 s, for SECS s at least (by $SECONDS), for what PRED finds (only a build without the clause makes it), and ends
# early once PRED holds, which fails the name, or once the run has ended (R61), after one more look. 1 when PRED held; logs "margin CASE/LABEL T SECS ms none" (R62),
# or the ms from the watch's start to the find
_db4_watch() {
  local n="$1" l="$2" s="$SECONDS" t r=0; shift 2; t="$(_db4_now)"
  while [ $((SECONDS - s)) -le "$n" ]; do "$@" && { r=1; break; }; kill -0 "$_db4_bg" 2>/dev/null || break; sleep 0.2; done
  [ "$r" = 1 ] || ! "$@" || r=1
  _db4_ml margin "${_db4_c##*/}/$l" T "${n}000" ms "$([ "$r" = 1 ] && _db4_since "$t" || echo none)"
  [ "$r" = 0 ]
}
# sl.pl DIR SECONDS TAG...: R61's sleeper: it sleeps SECONDS, or until DIR, its case's directory, is gone, looked for once a second
printf '%s\n' 'my ($d, $s) = @ARGV; my $e = time + $s; sleep 1 while time < $e && -d $d;' > "$DB4/sl.pl"
_db4_cores() { local n; n="$(sysctl -n hw.ncpu 2>/dev/null)"; case "$n" in ''|*[!0123456789]*) n="$(getconf _NPROCESSORS_ONLN 2>/dev/null)" ;; esac
  case "$n" in ''|*[!0123456789]*) n=1 ;; esac; [ "$n" -ge 1 ] || n=1; [ "$n" -le 64 ] || n=64; printf '%s' "$n"; }
# The gate's N (R51): sysctl's performance-core count when it answers with digits only and at least 1; else the core count (_db4_cores: hw.ncpu, then getconf, then 1); held to 1 to 64.
# _db4_cores stays the slots' count (D6): the slots name below reads it, not this
_db4_gaten() { local n; n="$(sysctl -n hw.perflevel0.logicalcpu 2>/dev/null)"
  case "$n" in ''|*[!0123456789]*) n="" ;; *) n=$((10#$n)); [ "$n" -ge 1 ] || n="" ;; esac
  [ -n "$n" ] || n="$(_db4_cores)"; [ "$n" -le 64 ] || n=64; printf '%s' "$n"; }
_db4_sel() { _db4_c="$DB4/n/$1"; _db4_F="$_db4_c/f"; _db4_T="$_db4_F/engine/harness/tests"; _db4_tmp="${_db4_td:-$_db4_c/tmp}"; }
# CASE [--red] GROUPS MANIFEST STUB...: the copy at $DB4/n/CASE and its fixture TMPDIR; 1 when it could not be made. A MANIFEST of + is a manifest
# of one row for each STUB that says ok "djy $DJ4N", so that a run that passes has compared one and leaves a receipt; - is none
_db4_new() {
  local n="$1" r="" s m; shift
  [ "${1:-}" != --red ] || { r=--red; shift; }
  _db4_sel "$n"
  rm -rf "$_db4_c"; mkdir -p "$_db4_c" "$_db4_tmp" || return 1
  if [ "${2:-}" = + ]; then
    m="$_db4_c/manifest.gen"; : > "$m"
    for s in "${@:3}"; do ! grep -qF 'ok "djy $DJ4N"' "$s" || printf '1\tdjy %s\n' "${s##*/}" >> "$m"; done
    set -- "$1" "$m" "${@:3}"
  fi
  _suite_copy_tree ${r:+"$r"} "$_db4_F" "$@"
}
# LABEL ARG...: the copy's driver under run.pl in the background, TMPDIR $_db4_tmp, INT and QUIT as _db4_I and _db4_Q, FELIX_TEST_SLOTS=$_db4_S (none when
# empty), _db4_E added to its environment; its pid file is $_db4_c/LABEL.pid (the run's group), its output LABEL.out and LABEL.err
_db4_go() {
  _db4_lab="$1"; shift
  local e p="$DB4/mkstand:" t; local -a k pe; k=(); pe=(); t="$(_db4_now)"
  [ "$_db4_nomk" != 1 ] || p=""; [ -z "$t" ] || rm -f "$_db4_c/$_db4_lab.ms"
  [ -z "$p" ] || pe[0]="PATH=$p$PATH"
  for e in ${_db4_E[@]+"${_db4_E[@]}"}; do case "$e" in PATH=*) e="PATH=$p${e#PATH=}" ;; esac; k[${#k[@]}]="$e"; done   # a case's own PATH keeps the stand-in first
  ( cd "$_db4_F" && exec env -u FELIX_TEST_NO_MANIFEST -u FELIX_TEST_JOBS -u FELIX_TEST_SLOTS -u FELIX_TEST_SLOT_NOTE -u FELIX_TEST_PART_LOG \
      -u FELIX_TEST_PART_RAN -u FELIX_TEST_PART_END -u FELIX_TEST_PART_RECORD -u FELIX_TEST_RED_JOBS -u PERL5OPT TMPDIR="$_db4_tmp" \
      ${pe[@]+"${pe[@]}"} DJ4_MKREAL="$_db4_mkreal" DJ4_MKLOG="$DB4/mktemp.log" \
      ${_db4_S:+FELIX_TEST_SLOTS=$_db4_S} ${k[@]+"${k[@]}"} perl "$DB4/run.pl" "$_db4_lim" "$_db4_I" "$_db4_Q" "$_db4_c/$_db4_lab.pid" \
      "${t:+$_db4_c/$_db4_lab.ms}" "$BASH" "$_db4_T/run" "$@" ) > "$_db4_c/$_db4_lab.out" 2> "$_db4_c/$_db4_lab.err" &
  _db4_bg=$!
  _db4_dl=$((SECONDS + _db4_lim + 5))   # R56: the run's own bound (run.pl's KILL at _db4_lim) and 5 s more; a wait for an event of the run lasts until then
  [ -z "$t" ] || printf '%s %s %s %s\n' "${_db4_c##*/}/$_db4_lab" "$_db4_lim" "$t" "$_db4_c/$_db4_lab.ms" > "$DB4/t0.$_db4_bg"   # R62: CASE/LABEL, B, the start, run.pl's ms file
}
# MSFILE T0: R62's start-to-exit, the ms run.pl (the bounded runner) wrote at its own exit, not the time to the case's reaping; were run.pl ever killed
# before it wrote, the ms since T0, the case's start of the run
_db4_rx() { local x; x="$(cat "$1" 2>/dev/null)"; case "$x" in ''|*[!0123456789]*) _db4_since "$2" ;; *) echo "$x" ;; esac; }
_db4_mr() {   # BGPID: R62's line for the run that job was, "1294 run CASE/LABEL bound B ms START-TO-EXIT"
  local f="$DB4/t0.$1" c b t m
  [ -n "${DJX_MLOG:-}" ] && [ -f "$f" ] || return 0
  read -r c b t m < "$f"; rm -f "$f"; _db4_ml run "$c" bound "$b" ms "$(_db4_rx "$m" "$t")"
}
# R56: PRED ARG...: waits until PRED ARG... holds, the run has ended, or the run's bound has passed (_db4_dl); a bound, never a margin: 0 when it held, else 1
_db4_evt() {
  while ! "$@"; do kill -0 "$_db4_bg" 2>/dev/null || break; [ "$SECONDS" -lt "$_db4_dl" ] || break; sleep 0.2; done
  "$@"
}
_db4_pid() { cat "$_db4_c/$1.pid" 2>/dev/null; }
_db4_gl()  { ps -A -ww -o pid= -o pgid= -o stat= -o command= 2>/dev/null | G="$1" LC_ALL=C awk '$2 == ENVIRON["G"] && $3 !~ /^Z/ { c = $0; sub(/^ *[0-9]+ +[0-9]+ +[^ ]+ +/, "", c); printf "%s:%s:%s\n", $1, $3, substr(c, 1, 50) }'; }
# GROUP: waits up to 30 s for the run's group to hold no live process; what is left goes into _db4_leak, and is continued and killed
_db4_grp() {
  local g="$1" i=0 l p
  [ -n "$g" ] || return 0
  while [ "$i" -lt "$_db4_gn" ]; do [ -z "$(_db4_gl "$g")" ] && break; sleep 0.2; i=$((i + 1)); done
  l="$(_db4_gl "$g")"
  [ -z "$l" ] || _db4_leak="$_db4_leak left in the run's group: $(printf '%s' "$l" | tr '\n' ' ')"
  for p in $(printf '%s\n' "$l" | sed 's/:.*//'); do kill -CONT "$p" 2>/dev/null; kill -KILL "$p" 2>/dev/null; done
}
_db4_wait0() { { wait "$_db4_bg"; } 2>/dev/null; _db4_rc=$?; _db4_mr "$_db4_bg"; }
_db4_fin() { _db4_grp "$(_db4_pid "$_db4_lab")"; _db4_E=(); _db4_I=DEFAULT; _db4_Q=DEFAULT; _db4_lim=600; _db4_S=8; _db4_nomk=0; }
_db4_wait() { _db4_wait0; _db4_fin; }
# LABEL SIGNAL: SIGNAL to the driver, then a wait for it to end that lasts until the run's bound has passed, at least 45 s (R56: a bound; was 45 s, a fixed wait shorter
# than the run). A parent that never ends is then killed by run.pl at B, so its exit is 124, not the signal's; one still there is killed by group, and _db4_late says so
_db4_stop() {
  local p i=0 n; p="$(_db4_pid "$1")"; _db4_late=""; n=$(( (_db4_dl - SECONDS) * 5 )); [ "$n" -ge 225 ] || n=225
  [ -z "$p" ] || kill -"$2" "$p" 2>/dev/null
  while [ "$i" -lt "$n" ]; do kill -0 "$p" 2>/dev/null || break; sleep 0.2; i=$((i + 1)); done
  if kill -0 "$p" 2>/dev/null; then _db4_late=" the parent was still running when the run's bound had passed;"; kill -KILL -- "-$p" 2>/dev/null; fi
  _db4_wait
}
_db4_rcpt() { if [ -f "$_db4_F/.git/felix-suite-receipt" ]; then echo present; else echo absent; fi; }
_db4_last() { tail -n 1 "$_db4_c/$1.out" 2>/dev/null; }
_db4_id()   { printf '%s' "${TMP##*/}-${_db4_c##*/}"; }
_db4_key()  { printf '%s' "${DB4#/private}/n/${_db4_c##*/}/"; }
# GROUP: the live pids of the current case's run, for the check: in its group, or with its directory or its id in the command line (not mine at _db4_hp)
_db4_ps() {
  ps -A -ww -o pid= -o pgid= -o stat= -o command= 2>/dev/null | G="${1:-}" K="$(_db4_key)" I="$(_db4_id)" H="$_db4_hp" LC_ALL=C awk \
    '$3 !~ /^Z/ && $1 != ENVIRON["H"] && (($2 == ENVIRON["G"] && ENVIRON["G"] != "") || index($0, ENVIRON["K"]) || index($0, ENVIRON["I"])) { printf "%s ", $1 }'
}
_db4_clear() { [ -z "$(_db4_ps "$1")" ]; }
_db4_alive() { local s; s="$(ps -o stat= -p "$1" 2>/dev/null | tr -d ' ')"; [ -n "$s" ] && [ "${s#Z}" = "$s" ]; }   # PID: there, and not a zombie
_db4_dead()  { ! _db4_alive "$1"; }
# the unit processes of the current case: bash run --part, not perl (the holder may carry the same words)
_db4_units() { ps -A -ww -o pid= -o stat= -o command= 2>/dev/null | K="$(_db4_key)" LC_ALL=C awk '$2 !~ /^Z/ && index($0, ENVIRON["K"]) && index($0, " --part ") && $3 !~ /perl/ { printf "%s ", $1 }'; }
# KEY: how many unit processes (a --part process, not perl, not below another) of the copies with KEY in their path run now
_db4_snap() {
  ps -A -ww -o pid= -o ppid= -o stat= -o command= 2>/dev/null | K="$1" LC_ALL=C awk '
    { u[$1] = (index($0, " --part ") && index($0, ENVIRON["K"]) && $3 !~ /^Z/ && $4 !~ /perl/); pp[$1] = $2 }
    END { n = 0; for (p in u) if (u[p] && !((pp[p] in u) && u[pp[p]])) n++; print n }'
}
_db4_peak() {   # KEY BGPID...: samples until those jobs have ended, or for at most _db4_lim * 7 samples (bounded: a pid taken again would keep kill -0 true); _db4_pk is the most units seen at once
  local k="$1" m=0 n b alive i=0; shift
  while [ "$i" -lt $((_db4_lim * 7)) ]; do
    i=$((i + 1)); alive=0; for b in "$@"; do ! kill -0 "$b" 2>/dev/null || alive=1; done
    [ "$alive" = 1 ] || break
    n="$(_db4_snap "$k")"; [ "${n:-0}" -le "$m" ] || m="$n"
    sleep 0.15
  done
  _db4_pk="$m"
}
_db4_inos() {   # TMPDIR: name:kind:inode of each entry of felix-suite-slots, in name order
  perl -e 'for my $f (sort glob("$ARGV[0]/felix-suite-slots/*")) { my @s = lstat($f); (my $n = $f) =~ s{.*/}{}; print "$n:", (-f _ ? "f" : "x"), ":$s[1] " }' "$1"
}
_db4_held() {   # TMPDIR: the slot files under it that some process holds
  perl -e 'use Fcntl ":flock"; for my $f (sort glob("$ARGV[0]/felix-suite-slots/*")) { next unless -f $f; open(my $h, "<", $f) or next; flock($h, LOCK_EX | LOCK_NB) or print "$f "; close $h }' "$1"
}
# SLOTFILE: a perl of mine holds its lock until _db4_unhold; _db4_hp is its pid. R56: its own end is a bound, B + 30 s (R44's H), or sooner once its slots directory is
# gone (an interrupted part leaves it no longer); the wait for its "held" is a bound too, the run bound, ended early if the perl has gone
_db4_hok() { [ -s "$_db4_c/hold.out" ] || ! kill -0 "$_db4_hp" 2>/dev/null; }
_db4_hold() {
  [ -d "${1%/*}" ] || mkdir -m 0700 "${1%/*}"
  perl -e 'use Fcntl ":flock"; open(my $h, ">>", $ARGV[0]) or exit 4; flock($h, LOCK_EX | LOCK_NB) or exit 3; $| = 1; print "held\n"; my $e = time + $ARGV[1]; sleep 1 while time < $e && -d $ARGV[2]' \
    "$1" "$((_db4_lim + 30))" "${1%/*}" > "$_db4_c/hold.out" 2>&1 &
  _db4_hp=$!
  _db4_until $((_db4_lim * 5)) _db4_hok
}
# the holders of the current case's run (R45: a live perl whose command line holds " --part " and the case's key, what only a holder carries), and whether one is up
_db4_holders() { ps -A -ww -o pid= -o stat= -o command= 2>/dev/null | K="$(_db4_key)" LC_ALL=C awk '$2 !~ /^Z/ && $3 ~ /perl/ && index($0, ENVIRON["K"]) && index($0, " --part ") { printf "%s ", $1 }'; }
_db4_hup() { [ -n "$(_db4_holders)" ]; }
# NAME: the unit processes of the current case that run the part NAME (bash run --part ... NAME, not perl)
_db4_unitn() { ps -A -ww -o pid= -o stat= -o command= 2>/dev/null | K="$(_db4_key)" N=" $1" LC_ALL=C awk '$2 !~ /^Z/ && $3 !~ /perl/ && index($0, ENVIRON["K"]) && index($0, " --part ") && index($0 " ", ENVIRON["N"] " ") { printf "%s ", $1 }'; }
_db4_unhold() { [ "$_db4_hp" = 0 ] || { kill -KILL "$_db4_hp" 2>/dev/null; { wait "$_db4_hp"; } 2>/dev/null; }; _db4_hp=0; return 0; }
_db4_started() { local f r=""; for f in "$_db4_c"/started.*; do [ -e "$f" ] && r="$r${f##*/} "; done; printf '%s' "$r"; }
_db4_pre()   { local f; for f in "$_db4_T"/parts/0006-*.sh; do printf '\n: > "%s/pre.done.$$"\n' "$_db4_c" >> "$f"; done; }   # the parent's prelude is done
_db4_pre_up() { ls "$_db4_c"/pre.done.* >/dev/null 2>&1; }
# "ok", or what an interrupted run left behind: LABEL STATUS (the slot files keep their names and inodes when _db4_ino0 was taken)
_db4_gone() {
  local l="$1" r="" g t; g="$(_db4_pid "$l")"
  [ "$_db4_rc" = "$2" ] || r="$r exit $_db4_rc, not $2;"
  [ "$(_db4_cnt "$_db4_c/$l.out" reached)" = 0 ] || r="$r reached was printed;"
  # R56, a margin: once the parent has exited, what it ended has only to act on the KILL it was sent (no fork), floor 10 s (was 5 s); L is a leftover's own
  # end, B + 30 s for the holds and units these cases plant. R62: logged as "margin CASE/gone T 10000", 10 s being its least length
  t="$(_db4_now)"; if _db4_until 50 _db4_clear "$g"; then _db4_ml margin "${_db4_c##*/}/gone" T 10000 ms "$(_db4_since "$t")"
  else r="$r still running: $(_db4_ps "$g");"; _db4_ml margin "${_db4_c##*/}/gone" T 10000 ms none; fi
  [ -z "$(_db4_held "$_db4_tmp")" ] || r="$r a slot is still held;"
  [ -z "$_db4_ino0" ] || [ "$(_db4_inos "$_db4_tmp")" = "$_db4_ino0" ] || r="$r the slot files changed: [$_db4_ino0] became [$(_db4_inos "$_db4_tmp")];"
  [ "$(_db4_rcpt)" = absent ] || r="$r a receipt was left;"
  [ "$_db4_ctl" = 1 ] || r="$r no positive control, so these absences say nothing;"
  printf '%s' "${r:-ok}"
}
# NAME ACTUAL EXPECTED: is, with what the run's group had left added to the actual
_db4_is() { local a="$2"; [ -z "$_db4_leak" ] || a="$a [$_db4_leak ]"; _db4_leak=""; is "$1" "$a" "$3"; }
# CASE FILE: pp/CASE/FILE is stdin behind a header that names the case's directory, id, the part and this block's directory
_db4_w() {
  mkdir -p "$DB4/pp/$1" || return 1
  { printf 'DJ4D=%q; DJ4I=%q; DJ4N=%q; DJ4L=%q\n' "$DB4/n/$1" "${TMP##*/}-$1" "$2" "$DB4"
    printf '%s\n' "printf '\\ndjy-sec %s\\n' \"\$DJ4N\""; cat; } > "$DB4/pp/$1/$2"
}
_db4_q() {   # CASE: four quick parts that note how many had started before them, note they started, and pass
  local f
  for f in 0010-qa.sh 0020-qb.sh 0030-qc.sh 0040-qd.sh; do _db4_w "$1" "$f" <<'X'
_djn="$(ls "$DJ4D"/started.* 2>/dev/null | wc -l | tr -d ' ')"
: > "$DJ4D/started.$DJ4N"
printf '%s\n' "$_djn" > "$DJ4D/ord.$DJ4N"
ok "djy $DJ4N"
X
  done
}
# ---- end of the helpers

# ---- the control: four quick parts pass under -j 2 and leave a receipt; the ps checks count units and a perl carrying their words is not one
_db4_q ctl; _db4_new ctl "$DB4/g-empty.tsv" + "$DB4/pp/ctl"/*.sh
_db4_go c -j 2; _db4_wait
[ "$_db4_rc" = 0 ] && [ "$(_db4_rcpt)" = present ] && [ -e "$_db4_c/started.0040-qd.sh" ] && _db4_ctl=1
_db4_is "D6: four quick parts pass under -j 2: exit 0, a receipt, and the last part ran (positive control)" "$_db4_rc $_db4_ctl" "0 1"
rm -rf "$DB4/n/ctl"
_db4_sel snapctl; mkdir -p "$_db4_c"; mkfifo "$_db4_c/ff" 2>/dev/null
# R56: the three stand-ins live B + 30 s (a hold's own end) and are killed by pid below; the wait for them is a bound, the run bound. R61: each also ends once the
# case's directory is gone (the bash ones read their FIFO a second at a time)
printf 'exec 3<> "$1"; _i=0; while [ -d "$2" ] && [ "$_i" -lt %s ]; do read -t 1 -u 3 _x; _i=$((_i + 1)); done\n' "$((_db4_lim + 30))" > "$_db4_c/unit.sh"
bash "$_db4_c/unit.sh" "$_db4_c/ff" "$_db4_c" --part 0010-x.sh & _db4_p1=$!
bash "$_db4_c/unit.sh" "$_db4_c/ff" "$_db4_c" --part 0020-y.sh & _db4_p2=$!
perl "$DB4/sl.pl" "$_db4_c" "$((_db4_lim + 30))" "$_db4_c/unit.sh" --part 0030-z.sh & _db4_p3=$!
_db4_four() { [ "$(_db4_snap "$(_db4_key)")" = 2 ]; }
_db4_until $((_db4_lim * 5)) _db4_four
_db4_x="$(_db4_snap "$(_db4_key)") $(set -- $(_db4_units); echo $#)"
kill -KILL "$_db4_p1" "$_db4_p2" "$_db4_p3" 2>/dev/null
for _db4_p in "$_db4_p1" "$_db4_p2" "$_db4_p3"; do { wait "$_db4_p"; } 2>/dev/null; done
_db4_is "D6: the unit counter below sees two unit processes and not the perl that carries their words (control)" "$_db4_x" "2 2"
rm -rf "$DB4/n/snapctl"

# ---- an interrupt while a holder waits, and a slot freed by kill -9 (D6): one slot, held by a process of mine, two parts waiting for it. Slot 0 stays the file I locked
_db4_hw() {   # CASE MODE: MODE term sends TERM to the parent, MODE free kills my holder with kill -9; _db4_x is the verdict
  local c="$1" m="$2" r="" t0 g n0
  _db4_q "$c"; _db4_td="$DB4/td-$c"; rm -rf "$_db4_td"; mkdir -p "$_db4_td"
  if ! _db4_new "$c" "$DB4/g-empty.tsv" + "$DB4/pp/$c"/0010-qa.sh "$DB4/pp/$c"/0020-qb.sh; then _db4_x="the copy could not be made"; _db4_td=""; return 0; fi
  _db4_pre; _db4_hold "$_db4_tmp/felix-suite-slots/0"; _db4_ino0="$(_db4_inos "$_db4_tmp")"; n0="$_db4_ino0"
  _db4_S=1; _db4_go h -j 2
  _db4_evt _db4_pre_up || r=" the parent's prelude never ended;"
  # R58, a watch: 20 s (was 2.5 s) from the first listing that shows a waiting holder, the event after which a holder that starts its unit without the slot's lock
  # (D6's flock) would act. That build forks and execs the unit inside it, so its floor is 20 s. It looks every 0.2 s for a unit process or a unit's started file
  # and ends at the first, which fails the name; on D's build it waits its whole 20 s. No other check of either name catches that build: TERM can end its unit
  # before it writes its file, and in the free case a unit that came early still lets the run pass
  _db4_evt _db4_hup || r="$r no holder waited for the slot;"
  _db4_ran() { [ -n "$(_db4_started)$(_db4_units)" ]; }
  _db4_watch 20 held _db4_ran || r="$r a unit ran while the slot was held elsewhere ($(_db4_started)$(_db4_units));"
  if [ "$m" = term ]; then
    # 3 s: a watch for a holder left behind that takes the freed slot. R58 lets it stay short: that holder is still there after the parent's exit, so the same name's
    # group drain (_db4_fin, 30 s with the slot still held, whose finding _db4_is adds to the name) and _db4_gone's look for any process of the copy catch it
    _db4_stop h TERM; r="$r$_db4_late"; _db4_unhold; sleep 3; _db4_ml margin "$c/freed" T 3000 ms none
    g="$(_db4_gone h 143)"; [ "$g" = ok ] || r="$r$g"
    [ -z "$(_db4_started)" ] || r="$r a unit started after the parent had exited ($(_db4_started));"
    [ -z "$(_db4_units)" ] || r="$r a unit process ran after the parent had exited;"
  else
    # R56, a margin: T = 20 s from the kill -9 to the first listing that shows a unit. Inside it D's holder takes the slot at its next try (each second) and forks the
    # unit and a ps for unit.I (R22), so the floor is 20 s. L: a build whose slot stays taken for 30 s after its holder dies (a mark the dead holder left, kept
    # 30 s, where D6 has a lock the kernel frees at the death), whose unit comes 30 s or more after the kill: T = L - 10 s. The name is shown red against that build
    # alone. A holder that retries its slot only every 30 s is not claimed to fail it: its next try comes 30 s after its last, and load sets how far into that wait
    # the kill comes, so the try can fall inside T. Was 2 s, D8's figure, below the floor
    t0="$(perl "$DB4/djk.pl" "$_db4_hp" 20000 "$(_db4_key)" "$(_db4_pid h)")"; { wait "$_db4_hp"; } 2>/dev/null; _db4_hp=0
    _db4_ml margin "$c/kill9" T 20000 ms "$([ "${t0%% *}" = seen ] && echo "${t0#seen }" || echo none)"
    case "$t0" in
      seen*) [ "${t0#seen }" -lt 20000 ] || r="$r the unit appeared ${t0#seen } ms after the kill -9, timed in the perl that took the listing;" ;;
      *) r="$r no unit process within 20 s of the kill -9 ($t0);" ;;
    esac
    _db4_wait
    [ "$_db4_rc" = 0 ] || r="$r exit $_db4_rc, not 0;"
    [ "$(_db4_rcpt)" = present ] || r="$r no receipt;"
    [ "$(_db4_inos "$_db4_tmp")" = "$n0" ] || r="$r slot 0 is not the file I locked ([$n0] now [$(_db4_inos "$_db4_tmp")]);"
  fi
  _db4_unhold; _db4_ino0=""; _db4_td=""; rm -rf "$DB4/n/$c" "$DB4/td-$c"; _db4_x="${r:-ok}"
}
_db4_hw hw-term term
_db4_is "D6: with one slot, its lock held elsewhere and two parts waiting, TERM to the parent starts no unit, before the exit or after it, the exit is 143, and slot 0 is still the file the other process locked" "$_db4_x" ok
_db4_hw hw-free free
_db4_is "D6: a slot whose holder was killed with kill -9 is free at once: no unit while it was held, one within 20 s, the run then passes, and slot 0 is still the same file" "$_db4_x" ok

# ---- the slots (D6): two -j 4 runs share FELIX_TEST_SLOTS slots, and a run is held to its -j
_db4_two() {   # TMPDIR SLOTS JOBS: two runs of four quick parts at once, the same TMPDIR; _db4_pk is the most units seen at once, _db4_rc2 the two exit statuses
  local td="$1" k="$2" j="$3" ba bb r1
  rm -rf "$td"; mkdir -p "$td"; _db4_td="$td"
  _db4_q capa; _db4_q capb
  _db4_new capa "$DB4/g-empty.tsv" + "$DB4/pp/capa"/*.sh; _db4_new capb "$DB4/g-empty.tsv" + "$DB4/pp/capb"/*.sh
  _db4_sel capa; _db4_S="$k"; _db4_go a -j "$j"; ba="$_db4_bg"
  _db4_sel capb; _db4_S="$k"; _db4_go b -j "$j"; bb="$_db4_bg"
  _db4_peak "${DB4#/private}/n/cap" "$ba" "$bb"
  _db4_bg="$ba"; _db4_sel capa; _db4_lab=a; _db4_wait; r1="$_db4_rc"; _db4_bg="$bb"; _db4_sel capb; _db4_lab=b; _db4_wait
  _db4_rc2="$r1 $_db4_rc"; _db4_td=""; rm -rf "$DB4/n/capa" "$DB4/n/capb" "$td"
}
_db4_two "$DB4/td-c3" 3 4
_db4_is "D6: with FELIX_TEST_SLOTS=3, two -j 4 runs of four parts never have more than three units running at once, and both pass" "$([ "$_db4_pk" -le 3 ] && echo "at most 3" || echo "$_db4_pk") $_db4_rc2" "at most 3 0 0"
_db4_is "D6: and they do get to three at once, which is the slots and not the parts' own order holding them there" "$_db4_pk" 3
_db4_two "$DB4/td-c8" 8 4
_db4_is "D6: and with FELIX_TEST_SLOTS=8 the same two runs do have more than three at once, so the count above can fail" "$([ "$_db4_pk" -gt 3 ] && echo more || echo "$_db4_pk") $_db4_rc2" "more 0 0"
_db4_one() {   # CASE JOBS: one run of four quick parts with eight slots; _db4_pk is the most units seen at once
  _db4_q "$1"; _db4_td=""; _db4_new "$1" "$DB4/g-empty.tsv" + "$DB4/pp/$1"/*.sh
  _db4_S=8; _db4_go a -j "$2"; _db4_peak "${DB4#/private}/n/$1/" "$_db4_bg"; _db4_wait; rm -rf "$DB4/n/$1"
}
_db4_one nj2 2
_db4_is "D6: a run is held to its own N: -j 2 over four parts and plenty of slots has two units at once and never more, and passes" "$_db4_pk $_db4_rc" "2 0"
_db4_one nj4 4
_db4_is "D6: and -j 4 over the same parts has more than two at once, so the count above can fail" "$([ "$_db4_pk" -gt 2 ] && echo more || echo "$_db4_pk") $_db4_rc" "more 0"

# one slot free of two: the parts still run, one at a time; a -j 1 run is not held up by a slot held elsewhere
_db4_q fo; _db4_td="$DB4/td-fo"; rm -rf "$_db4_td"; mkdir -p "$_db4_td"; _db4_new fo "$DB4/g-empty.tsv" + "$DB4/pp/fo"/*.sh
_db4_hold "$_db4_tmp/felix-suite-slots/0"
_db4_S=2; _db4_go a -j 2; _db4_peak "${DB4#/private}/n/fo/" "$_db4_bg"; _db4_wait
_db4_is "D6: with slot 0 of 2 held elsewhere the four parts still run, through slot 1, one unit at a time (never none, never two), and pass" "$_db4_pk $_db4_rc $(_db4_started | wc -w | tr -d ' ')" "1 0 4"
rm -rf "$DB4/pp/fo"; _db4_q fo; rm -rf "$DB4/n/fo"; _db4_new fo "$DB4/g-empty.tsv" + "$DB4/pp/fo"/*.sh
_db4_S=1; _db4_go a -j 1; _db4_wait
_db4_is "D6: and a -j 1 run is not held up by the only slot being held elsewhere: it passes and runs all four parts (control)" "$_db4_rc $(_db4_started | wc -w | tr -d ' ')" "0 4"
_db4_unhold; _db4_td=""; rm -rf "$DB4/n/fo" "$DB4/td-fo"

# the slot files a run makes: K regular files, 0 to K-1 (K is FELIX_TEST_SLOTS, or the core count), in a directory made 0700 when it was missing (R5)
_db4_slotnames() { local f r=""; for f in "$1"/felix-suite-slots/*; do [ -e "$f" ] || continue; if [ -f "$f" ] && [ ! -L "$f" ]; then r="$r${f##*/} "; else r="$r(${f##*/}:not a file) "; fi; done; printf '%s' "$r"; }
_db4_mode() { perl -e 'printf "%o", (stat $ARGV[0])[2] & 07777' "$1"; }
_db4_q sf; _db4_td="$DB4/td-sf"; rm -rf "$_db4_td"; mkdir -p "$_db4_td"; _db4_new sf "$DB4/g-empty.tsv" + "$DB4/pp/sf"/*.sh
_db4_S=3; _db4_go a -j 2; _db4_wait; _db4_x="$(_db4_slotnames "$_db4_td")|$(_db4_held "$_db4_td")"
_db4_is "D6: a -j 2 run with FELIX_TEST_SLOTS=3 in a fresh TMPDIR leaves exactly the regular files 0, 1 and 2 in felix-suite-slots, none of them held" "$_db4_rc $_db4_x" "0 0 1 2 |"
_db4_is "R5: a slots directory that was missing is made with mode 0700" "$(_db4_mode "$_db4_td/felix-suite-slots")" 700
rm -rf "$_db4_td"; mkdir -p "$_db4_td"; _db4_S=""; _db4_go a -j 2; _db4_wait
_db4_x="$(_db4_slotnames "$_db4_td")"; _db4_y="$(set -- $_db4_x; echo $#)"
_db4_is "D6: with FELIX_TEST_SLOTS unset the slots are as many as the cores (sysctl, then getconf, then 1, held to 1 to 64), all regular files" "$_db4_rc $_db4_y $(printf '%s' "$_db4_x" | grep -c 'not a file')" "0 $(_db4_cores) 0"
_db4_td=""; rm -rf "$DB4/n/sf" "$DB4/td-sf"
# a TMPDIR relative to the directory the run started in is taken relative to it, so the parent and every holder name one directory (R5). ../reltmp from the copy's checkout F names $_db4_c/reltmp, outside F's
# checkout (0001 refuses a $TMP made inside it, ci456) and still under $TMP (R12)
_db4_q rl; _db4_td=""; _db4_new rl "$DB4/g-empty.tsv" + "$DB4/pp/rl"/*.sh; mkdir -p "$_db4_c/reltmp"; _db4_tmp=../reltmp
_db4_nomk=1; _db4_S=3; _db4_go a -j 2; _db4_wait   # R41: a placement case keeps its mktemp
_db4_is "R5: under a TMPDIR relative to the directory the run started in, the slot files are made below that directory, and the run passes: its holders found the files the parent made" "$_db4_rc $(_db4_slotnames "$_db4_c/reltmp") $(_db4_started | wc -w | tr -d ' ')" "0 0 1 2  4"
rm -rf "$DB4/n/rl"
# R29: a relative TMPDIR is made absolute against the directory the run started in, and exported, before 0001 makes $TMP. GNU mktemp honours TMPDIR, macOS's ignores it (ci456), so a GNU-style mktemp is put first on
# PATH: only a bare `mktemp -d` honours TMPDIR, makes ${TMPDIR:-/tmp}/tmp.N and prints it as TMPDIR gave it (relative when TMPDIR is), and when it cannot it prints mkdir's line and exits 1; every other form goes to the real one.
# A part stands in $TMP/cwd (and a unit's in its own run's), so a bare mktemp -d there reads the relative TMPDIR from the wrong place unless every process was given the absolute one
mkdir -p "$DB4/mkshim"
cat > "$DB4/mkshim/mktemp" <<'DB4MK'
#!/bin/sh
if [ "$#" = 1 ] && [ "$1" = -d ]; then
  d="${TMPDIR:-/tmp}"; i=0
  while [ -e "$d/tmp.$$.$i" ]; do i=$((i + 1)); done
  mkdir -m 0700 "$d/tmp.$$.$i" || exit 1
  printf '%s\n' "$d/tmp.$$.$i"; exit 0
fi
if [ -x /usr/bin/mktemp ]; then exec /usr/bin/mktemp "$@"; fi
exec /bin/mktemp "$@"
DB4MK
chmod +x "$DB4/mkshim/mktemp"
_db4_w mk 0010-ma.sh <<'X'
_mk="$(mktemp -d 2>"$DJ4D/mk.err")"; _mks=$?
printf '%s %s\n' "$_mks" "$_mk" > "$DJ4_MKOUT"
ok "djy $DJ4N"
X
_db4_mkc() {   # JOBS: the copy of case mk under -j JOBS with the shim first on PATH and TMPDIR ../reltmp; _db4_x is "STATUS PART-STATUS below" or what was found instead
  local j="$1" st=none nm="" ph="" bs="" bl
  _db4_td=""; _db4_new mk "$DB4/g-empty.tsv" + "$DB4/pp/mk"/0010-ma.sh || { _db4_x="the copy could not be made"; return 0; }
  mkdir -p "$_db4_c/reltmp"; _db4_tmp=../reltmp
  _db4_E=(PATH="$DB4/mkshim:$PATH" DJ4_MKOUT="$_db4_c/mk.out.txt")
  _db4_nomk=1; _db4_S=3; _db4_go a -j "$j"; _db4_wait   # R41: a placement case keeps its mktemp (its own GNU-style one)
  read -r st nm < "$_db4_c/mk.out.txt" 2>/dev/null
  bs="$(cd "$_db4_c/reltmp" && pwd -P)"
  case "$nm" in /*) [ -d "$nm" ] && ph="$(cd "$nm" && pwd -P)" ;; esac
  case "$ph" in "$bs"/?*) bl=below ;; *) bl="not-below [name ${nm:-none} physical ${ph:-none}; $(head -n 1 "$_db4_c/mk.err" 2>/dev/null)]" ;; esac
  _db4_x="$_db4_rc $st $bl"
  rm -rf "$DB4/n/mk"
}
_db4_mkc 2
_db4_is "R29: under a TMPDIR relative to the directory the run started in and a GNU-style mktemp first on PATH, a part's bare mktemp -d from its working directory lands below that directory, run under -j 2: the run passes and the part's status is 0" "$_db4_x" "0 0 below"
_db4_mkc 1
_db4_is "R29: and under -j 1 the same: exit 0, the part's mktemp -d status 0, and the directory it made is below that directory" "$_db4_x" "0 0 below"

# slots that cannot be taken: the parent refuses, exit 2 and one line, before it starts a unit
_db4_srv() {   # the -j 2 run in the current copy is refused; _db4_v is "ok" or what differed
  local r="" n
  _db4_go sr -j 2; _db4_wait
  n="$(awk 'END { print NR }' "$_db4_c/sr.err")"
  [ "$_db4_rc" = 2 ] || r="$r exit $_db4_rc, not 2;"
  [ "$n" = 1 ] || r="$r $n stderr lines, not 1;"
  [ -z "$(_db4_started)" ] || r="$r a unit started ($(_db4_started));"
  _db4_v="${r:-ok}"
}
cat > "$DB4/Djflock4.pm" <<'DB4PM'
package Djflock4;
use Errno qw(ENOLCK);
use Fcntl qw(O_CREAT O_EXCL O_WRONLY);
# DJ4_FLOCK=all: every flock but LOCK_UN fails with ENOLCK. DJ4_FLOCK=later: the first one, in whatever process asks first, succeeds
# (the parent's one lock), and every later one fails with ENOLCK (a holder's).
BEGIN {
  *CORE::GLOBAL::flock = sub {
    my ($fh, $op) = @_;
    return CORE::flock($fh, $op) if $op & 8;
    if (($ENV{DJ4_FLOCK} || "") eq "later" && sysopen(my $x, $ENV{DJ4_MARK}, O_CREAT | O_EXCL | O_WRONLY)) { close $x; return CORE::flock($fh, $op) }
    $! = ENOLCK; return 0;
  };
}
1;
DB4PM
_db4_fk() { perl -I"$DB4" -MDjflock4 -e 'use Fcntl ":flock"; open(my $h, "<", $ARGV[0]) or exit 3; for (1, 2) { print flock($h, LOCK_EX | LOCK_NB) ? "granted " : ($!{EWOULDBLOCK} ? "wouldblock " : "other ") }' "$DB4/man.tsv"; }
_db4_is "D6: the flock stand-in used below fails with an errno that is not EWOULDBLOCK in mode all, and only after the first call in mode later (control)" \
   "$(DJ4_FLOCK=all _db4_fk)| $(DJ4_FLOCK=later DJ4_MARK="$DB4/fk.mark" _db4_fk)" "other other | granted other "
_db4_q fl; _db4_td="$DB4/td-fl"; rm -rf "$_db4_td"; mkdir -p "$_db4_td"; _db4_new fl "$DB4/g-empty.tsv" + "$DB4/pp/fl"/*.sh
_db4_S=2; _db4_E=(PERL5OPT="-I$DB4 -MDjflock4" DJ4_FLOCK=all); _db4_srv
_db4_is "D6: where flock fails with ENOLCK, and not EWOULDBLOCK, the parent's one lock fails and the run is refused: exit 2, one stderr line, no unit" "$_db4_v" ok
rm -rf "$DB4/td-fl/felix-suite-slots" "$_db4_c/started".*; _db4_S=2; _db4_E=(PERL5OPT="-I$DB4 -MDjflock4" DJ4_FLOCK=later DJ4_MARK="$_db4_c/flock.mark"); _db4_go hf -j 2; _db4_wait
_db4_x=""
[ "$_db4_rc" = 1 ] || _db4_x="$_db4_x exit $_db4_rc, not 1;"
for _db4_p in 0010-qa.sh 0020-qb.sh; do [ "$(_db4_cnt "$_db4_c/hf.out" "  FAIL  part ended without its mark: $_db4_p")" = 1 ] || _db4_x="$_db4_x no runner failure for $_db4_p;"; done
[ -z "$(_db4_started)" ] || _db4_x="$_db4_x a unit started;"
[ "$(_db4_rcpt)" = absent ] || _db4_x="$_db4_x a receipt was left;"
_db4_is "D6: where the parent's lock is granted and a holder's flock fails with ENOLCK, the holder exits 2 before its unit starts: each unit has no mark, exit 1, no receipt" "${_db4_x:-ok}" ok
rm -rf "$DB4/n/fl" "$DB4/td-fl"; _db4_td=""

# ---- the slots directory (R5) and what is in it (D6): each of these makes a -j run refuse with exit 2 and one line, before any unit starts
_db4_rf() {   # CASE KIND PHRASE...: the directory, or an entry in it, is of KIND (FELIX_TEST_SLOTS=2); the line starts tests/run: and holds each PHRASE; _db4_v is ok, skip or what differed
  local c="$1" k="$2" r="" n d p; shift 2
  _db4_q "$c"; _db4_td="$DB4/td-$c"; rm -rf "$_db4_td"; mkdir -p "$_db4_td"; d="$_db4_td/felix-suite-slots"; _db4_v=""
  case "$k" in
    link)  mkdir -m 0700 "$_db4_td/real"; ln -s "$_db4_td/real" "$d" ;;
    m775)  mkdir "$d"; chmod 775 "$d" ;;
    m757)  mkdir "$d"; chmod 757 "$d" ;;
    file)  : > "$d" ;;
    dir0)  mkdir -m 0700 "$d"; mkdir "$d/0" ;;
    dir1)  mkdir -m 0700 "$d"; : > "$d/0"; mkdir "$d/1" ;;
    dotx)  mkdir -m 0700 "$d"; mkdir "$d/.x" ;;
    nine)  mkdir -m 0700 "$d"; mkdir "$d/9" ;;
    fifo0) mkdir -m 0700 "$d"; mkfifo "$d/0" 2>/dev/null; [ -p "$d/0" ] || _db4_v=skip ;;
    mode0) mkdir -m 0700 "$d"; : > "$d/0"; chmod 000 "$d/0"; [ ! -r "$d/0" ] || _db4_v=skip ;;
  esac
  if [ "$_db4_v" = skip ]; then :
  elif ! _db4_new "$c" "$DB4/g-empty.tsv" + "$DB4/pp/$c"/*.sh; then _db4_v="the copy could not be made"
  else
    _db4_S=2; _db4_srv; r=""; [ "$_db4_v" = ok ] || r="$_db4_v"
    for p in "$@"; do case "$(cat "$_db4_c/sr.err")" in "tests/run: "*"$p"*) ;; *) r="$r the line lacks [$p]: $(head -n 1 "$_db4_c/sr.err");" ;; esac; done
    _db4_v="${r:-ok}"
  fi
  chmod 755 "$d" 2>/dev/null; chmod 644 "$d/0" 2>/dev/null; rm -rf "$DB4/n/$c" "$_db4_td"; _db4_td=""
}
_db4_rn() {   # NAME CASE KIND PHRASE...: the assertion NAME for _db4_rf CASE KIND PHRASE..., or the same name as a skip
  local n="$1"; shift; _db4_rf "$@"
  if [ "$_db4_v" = skip ]; then skip "$n" "this system or user makes no such entry"; else _db4_is "$n" "$_db4_v" ok; fi
}
_db4_rn "D6: a directory at slot 0 makes a -j run refuse: exit 2, one stderr line, no unit" nd0 dir0 "is not a regular file"
_db4_rn "D6: a directory at slot 1 of 2, beside a regular file at 0, refuses the same way" nd1 dir1 "is not a regular file"
_db4_rn "D6: a FIFO at slot 0 refuses the same way and does not block the parent on opening it" nf0 fifo0 "is not a regular file"
_db4_rn "D6: a slot file the parent cannot open makes a -j run refuse: exit 2, one stderr line, no unit" nm0 mode0
_db4_rn "R5: the slots directory a symbolic link, whatever it points to, is refused with exit 2 and the line tests/run: the slots directory [D] is a symbolic link" r5-link link "the slots directory [" "is a symbolic link"
_db4_rn "R5: the slots directory at mode 0775, writable by its group, is refused: exit 2 and one line" r5-775 m775 "the slots directory [" "is writable by its group or by others"
_db4_rn "R5: the slots directory at mode 0757, writable by others, is refused: exit 2 and one line" r5-757 m757 "the slots directory [" "is writable by its group or by others"
_db4_rn "R5: a regular file where the slots directory should be is refused: exit 2 and one line" r5-file file "the slots directory [" "is not a directory"
_db4_rn "R5: a directory named .x in the slots directory, a name no slot has, is refused with exit 2 and the entry named" r5-dotx dotx "[" "/.x] is not a regular file"
_db4_rn "R5: a directory named 9 in the slots directory beside FELIX_TEST_SLOTS=2, a name beyond slot K-1, is refused with exit 2 and the entry named" r5-nine nine "[" "/9] is not a regular file"

# ---- a wait for a slot is visible while it lasts (R6). One part, one slot held by a perl of mine, FELIX_TEST_SLOT_NOTE=2
_db4_q nt; _db4_td="$DB4/td-nt"; rm -rf "$_db4_td"; mkdir -p "$_db4_td"; _db4_new nt "$DB4/g-empty.tsv" + "$DB4/pp/nt"/0010-qa.sh
_db4_pre; _db4_hold "$_db4_tmp/felix-suite-slots/0"
_db4_S=1; _db4_E=(FELIX_TEST_SLOT_NOTE=2); _db4_go n -j 2
_db4_nl='tests/run: 0010-qa.sh has waited 2 s for a slot and goes on waiting'
_db4_ln() { [ "$(_db4_cnt "$_db4_c/n.err" "$_db4_nl")" -ge 1 ]; }
# R56, a margin: T = 15 s from the first listing that shows the waiting unit's holder to the line. Inside it D's parent only acts on its ticks (W = T = 2), with no
# fork (the look reads the slot file and $SECONDS), so the floor is 10 s. L: a parent that reads with W = 30 (D6's read -t 30, W not taken from T) prints the line
# 30 s or more after its ticker or its read began, and both begin after the mark planted at the end of 0006 (_db4_pre). Of those 30 s, at most mark-to-holder (the
# ms from that mark to the start of the holder's first listing, lag.pl's second field) falls before the window, so L = 30 s less mark-to-holder, and T stays at most
# 20 s less it: T = 15 s holds while mark-to-holder is 5 s or less. With DJX_MLOG naming a file the case logs both fields; the evidence under burners (R57) gives the
# largest mark-to-holder, and T stays at most 20 s less that. Revision 17 first counted it from the mark itself (5 s before), which left the parent's sourcing of
# 0007 and its set-up (forks) inside the window. lag.pl's own wait is the run bound, and ends at the run's exit (R61). R62: the window is logged as nt/line, T 15000,
# and mark-to-holder as nt/mark-to-holder with T 5000, the most of it that T = 15 s allows (L - 10 s at least 15 s): its evidence decides this T
_db4_lagv="$(perl "$DB4/lag.pl" "$(_db4_key)" "$_db4_c/n.err" "$_db4_nl" "$_db4_lim" "$_db4_c" "$_db4_c/n.pid")"
_db4_ml margin nt/line T 15000 ms "$(_db4_msv "${_db4_lagv%% *}")"; _db4_ml margin nt/mark-to-holder T 5000 ms "$(_db4_msv "${_db4_lagv#* }")"
# R58, a watch: 10 s (was 3 s) from the line, the event after which a parent that printed it on every tick (R6's "once" missing) would print it again, at its next
# tick 2 s later. That parent only acts on its read's timeout and prints, with no fork, so the floor is 10 s. It ends early once a second line is there
_db4_twice() { [ "$(_db4_cnt "$_db4_c/n.err" "$_db4_nl")" -ge 2 ]; }
_db4_evt _db4_ln; _db4_x="$(_db4_cnt "$_db4_c/n.err" "$_db4_nl")"; _db4_watch 10 again _db4_twice
_db4_x="$_db4_x $(_db4_cnt "$_db4_c/n.err" "$_db4_nl") [$(_db4_started)] $(_db4_alive "$_db4_hp" && echo held || echo gone)"
_db4_unhold; _db4_wait; _db4_x="$_db4_x $_db4_rc $(_db4_cnt "$_db4_c/n.err" "$_db4_nl") $(_db4_rcpt)"
_db4_is "R6: with the only slot held by another process and FELIX_TEST_SLOT_NOTE=2, the parent's stderr names the waiting unit once while it waits (and still once 10 s later), nothing has started, and the run passes once the slot is let go" "$_db4_x" "1 1 [] held 0 1 present"
_db4_is "R6: the line comes within 15 s of the first ps listing that shows the waiting unit's holder, T being 2, timed in a perl that waits for that holder: a read that waited 30 s would print it 30 s after the unit's wrapper started" "$([ "${_db4_lagv%% *}" -lt 15000 ] 2>/dev/null && echo in-time || echo "after [${_db4_lagv%% *}] ms, mark to holder [${_db4_lagv#* }] ms")" in-time
_db4_td=""; rm -rf "$DB4/n/nt" "$DB4/td-nt"
# R56, a margin of a control. The name is a control: it passes before D is built, and no red-first list holds it. Its T guards D's build, not a build without a
# clause: with the slot free D's holder must take it (a fork and an exec of perl, then its first try) before the parent's T, or D's parent prints the line too.
# A window with a fork in it has R56's floor, so T is 20 s (was 10 s). R62: it is logged as nu/free-slot, T 20000, with what was measured the ms from the mark at
# the end of 0006 (planted for this) to the first listing that shows the holder, which bounds from above the time from its wrapper's start to its slot
_db4_q nu; _db4_new nu "$DB4/g-empty.tsv" + "$DB4/pp/nu"/0010-qa.sh; _db4_pre
_db4_E=(FELIX_TEST_SLOT_NOTE=20); _db4_go n -j 2
_db4_x=none; [ -z "${DJX_MLOG:-}" ] || _db4_x="$(perl "$DB4/lag.pl" "$(_db4_key)" - - "$_db4_lim" "$_db4_c" "$_db4_c/n.pid")"
_db4_ml margin nu/free-slot T 20000 ms "$(_db4_msv "${_db4_x#* }")"; _db4_wait
_db4_is "R6: with the slot free there is no such line, and the run passes (control)" "$_db4_rc $(grep -c 'has waited' "$_db4_c/n.err")" "0 0"
rm -rf "$DB4/n/nu"

# ---- the gate (D1, R10): projects/felix/gate.sh run whole in a fixture checkout, beside a stub tests/run that records $#:$* and FELIX_TEST_JOBS. Without a gate.sh each name below is a skip
DG="$DB4/gate"; DGC="$DG/c"
_db4_gs="$REAL_HARNESS/../../projects/felix/gate.sh"
[ -f "$_db4_gs" ] || _db4_gskip="no projects/felix/gate.sh beside this engine"
if [ -z "$_db4_gskip" ]; then
  mkdir -p "$DGC/engine/harness/bin" "$DGC/engine/harness/lib" "$DGC/engine/harness/tests" "$DGC/projects/felix" "$DG/tmp" "$DG/home" "$DG/shim" "$DG/out"
  cp "$_db4_gs" "$DGC/projects/felix/gate.sh"
  printf '#!/bin/sh\nexit 0\n' > "$DGC/engine/harness/bin/schema-check"
  printf '#!/bin/sh\n[ "${1:-}" = --paths ] && echo engine/harness/bin\nexit 0\n' > "$DGC/engine/harness/bin/independence-scan"
  printf '_gfg_probe() {\n  _felix_dep_grep "$root" "gfgzzword"\n}\n' > "$DGC/engine/harness/lib/detect.sh"
  printf '# kind\tfile\ttoken\treason\n' > "$DGC/engine/harness/ecosystem.tsv"
  cat > "$DGC/engine/harness/tests/run" <<'DB4ST'
#!/usr/bin/env bash
printf '%s:%s\n' "$#" "$*" >> "$DJ4_OUT/$DJ4_L.args"
printf '%s\n' "${FELIX_TEST_JOBS-unset}" >> "$DJ4_OUT/$DJ4_L.jobs"
if [ -n "${DJ4_EXIT2:-}" ]; then printf 'djy stub: first line of a refusal\n' >&2; printf 'djy stub: the last line of a refusal\n' >&2; exit 2; fi
printf 'reused the suite run that ended 09:00 on this tree (normal), not run again\n\n7 passed, 0 failed (reused)\n'
DB4ST
  chmod +x "$DGC/engine/harness/bin/schema-check" "$DGC/engine/harness/bin/independence-scan" "$DGC/engine/harness/tests/run"
  for _db4_t in sysctl getconf; do
    cat > "$DG/shim/$_db4_t" <<'DB4SH'
#!/bin/sh
# the tool of this name, unless DJ4_<name> is set: then it answers with that (and fails where it is empty)
# sysctl also answers hw.perflevel0.logicalcpu from DJ4_sysctl_perf and hw.ncpu from DJ4_sysctl_ncpu, each apart from the other and from DJ4_sysctl: a value answers with it,
# an empty value answers with an empty line and status 0, and djy-fail fails (status 1, no output). A key whose variable is unset goes on to DJ4_sysctl, then to the real sysctl
n="${0##*/}"
if [ "$n" = sysctl ]; then
  k=; for a in "$@"; do case "$a" in hw.*) k="$a" ;; esac; done
  case "$k" in
    hw.perflevel0.logicalcpu) v="${DJ4_sysctl_perf-djy-unset}" ;;
    hw.ncpu) v="${DJ4_sysctl_ncpu-djy-unset}" ;;
    *) v=djy-unset ;;
  esac
  case "$v" in djy-unset) ;; djy-fail) exit 1 ;; *) echo "$v"; exit 0 ;; esac
fi
eval "v=\${DJ4_$n-djy-unset}"
if [ "$v" != djy-unset ]; then [ -n "$v" ] || exit 1; echo "$v"; exit 0; fi
[ -x "@REAL@" ] || exit 1
exec "@REAL@" "$@"
DB4SH
    sed "s|@REAL@|$(command -v "$_db4_t" 2>/dev/null || echo /nonexistent)|g" "$DG/shim/$_db4_t" > "$DG/shim/$_db4_t.n" && mv "$DG/shim/$_db4_t.n" "$DG/shim/$_db4_t"
    chmod +x "$DG/shim/$_db4_t"
  done
  ( _fx_cd "${DGC:?}" && git init -q -b main && git add -A && git -c user.name=djy -c user.email=djy@example.invalid -c commit.gpgsign=false -c core.hooksPath=/dev/null commit -qm fixture ) >/dev/null 2>&1
fi
_db4_gate() {   # LABEL NAME=value...: gate.sh in the fixture; its output is $DG/out/LABEL.out, its status _db4_grc; what its group left is in LABEL.leak
  local l="$1" t; shift
  rm -f "$DG/out/$l.args" "$DG/out/$l.jobs" "$DG/out/$l.ms"; t="$(_db4_now)"
  ( cd "${DGC:?}" && exec env -u GITHUB_ACTIONS -u FELIX_TEST_JOBS -u FELIX_TEST_NO_MANIFEST -u DJ4_EXIT2 -u DJ4_sysctl -u DJ4_getconf -u DJ4_sysctl_perf -u DJ4_sysctl_ncpu HOME="$DG/home" \
      FELIX_KERNEL_CACHE="$DG/nocache" TMPDIR="$DG/tmp" PATH="$DG/shim:$PATH" DJ4_OUT="$DG/out" DJ4_L="$l" ${1+"$@"} \
      perl "$DB4/run.pl" "$_db4_lim" DEFAULT DEFAULT "$DG/out/$l.pid" "${t:+$DG/out/$l.ms}" bash projects/felix/gate.sh ) > "$DG/out/$l.out" 2>&1
  _db4_grc=$?; [ -z "$t" ] || _db4_ml run "gate/$l" bound "$_db4_lim" ms "$(_db4_rx "$DG/out/$l.ms" "$t")"   # R62
  _db4_leak=""; _db4_grp "$(cat "$DG/out/$l.pid" 2>/dev/null)"; printf '%s' "$_db4_leak" > "$DG/out/$l.leak"; _db4_leak=""
}
_db4_gj() { sed -n 1p "$DG/out/$1.jobs" 2>/dev/null; }
_db4_ga() { sed -n 1p "$DG/out/$1.args" 2>/dev/null; }
_db4_gc() {   # LABEL WANT NAME=value...: gate.sh with those; "ok" when the stub saw FELIX_TEST_JOBS=WANT and the arguments 1:--reuse
  local l="$1" w="$2"; shift 2
  _db4_gate "$l" ${1+"$@"}
  if [ "$(_db4_gj "$l") $(_db4_ga "$l")" = "$w 1:--reuse" ]; then printf ok; else printf '[%s] [%s]' "$(_db4_gj "$l")" "$(_db4_ga "$l")"; fi
  cat "$DG/out/$l.leak" 2>/dev/null
}
_db4_gm() {   # the core count's holds, six gates in one: ok six times, or what differed
  _db4_gc g5 64 DJ4_sysctl=200; printf ' '; _db4_gc g6 64 DJ4_sysctl= DJ4_getconf=100; printf ' '; _db4_gc g7 12 DJ4_sysctl= DJ4_getconf=12; printf ' '
  _db4_gc g8 1 DJ4_sysctl= DJ4_getconf=; printf ' '; _db4_gc g9 3 DJ4_sysctl=3 DJ4_getconf=9; printf ' '; _db4_gc g10 5 DJ4_sysctl=abc DJ4_getconf=5
}
_db4_gx() {   # a stub that exits 2 with two stderr lines: how many "tests FAIL" headings, whether the last line is under it, and whether the gate failed
  _db4_gate g11 DJ4_EXIT2=1
  printf '%s %s' "$(LC_ALL=C awk '/^  tests +FAIL$/ { f = 1; s = 1; next } /^  [A-Za-z-]+ +(ok|FAIL|skipped|reused)/ { f = 0 } f && index($0, "djy stub: the last line of a refusal") { h = 1 } END { print s + 0, h + 0 }' "$DG/out/g11.out" 2>/dev/null)" "$([ "$_db4_grc" != 0 ] && echo failed || echo passed)"
}
_db4_g() {   # NAME WANT CMD...: is NAME (the output of CMD... being WANT), or a skip of the same name where there is no gate
  local n="$1" w="$2"; shift 2
  if [ -n "$_db4_gskip" ]; then skip "$n" "$_db4_gskip"; else is "$n" "$("$@")" "$w"; fi
}
_db4_g "D1: with GITHUB_ACTIONS unset gate.sh sets FELIX_TEST_JOBS, for its call to tests/run, to the N this machine gives, from whichever step answers (sysctl or getconf), and its argument list stays --reuse" ok _db4_gc g1 "$(_db4_gaten)"
_db4_g "D1: with GITHUB_ACTIONS=true it sets nothing, and the argument list is --reuse (control)" ok _db4_gc g2 unset GITHUB_ACTIONS=true
_db4_g "D1: only the value true stops it: GITHUB_ACTIONS=false still sets the N this machine gives, from whichever step answers (sysctl or getconf)" ok _db4_gc g3 "$(_db4_gaten)" GITHUB_ACTIONS=false
_db4_g "D1: a FELIX_TEST_JOBS the caller already had is replaced by the N this machine gives, from whichever step answers (sysctl or getconf)" ok _db4_gc g4 "$(_db4_gaten)" FELIX_TEST_JOBS=7
_db4_g "R10: with GITHUB_ACTIONS=true and a FELIX_TEST_JOBS=7 the caller already had, the stub sees it unset, and the argument list is --reuse" ok _db4_gc g12 unset GITHUB_ACTIONS=true FELIX_TEST_JOBS=7
_db4_g "D1: with one sysctl answer given to every key, step 1 (the performance-core key) takes it: 200 is held to 64 and 3 is used; where every sysctl key fails or answers a non-number, getconf answers, then 1" "ok ok ok ok ok ok" _db4_gm
# R51: the performance-core count, apart from the core count. Each case gives the stub both keys (or fails one); a case that tests hw.ncpu's step makes the performance-core key fail.
_db4_gp() {   # (a) the performance-core count answers first, over a different hw.ncpu (and over a failing one, and over getconf)
  _db4_gc g13 6 DJ4_sysctl_perf=6 DJ4_sysctl_ncpu=12; printf ' '; _db4_gc g14 8 DJ4_sysctl_perf=8 DJ4_sysctl_ncpu=4; printf ' '
  _db4_gc g15 6 DJ4_sysctl_perf=6 DJ4_sysctl_ncpu=12 DJ4_getconf=9; printf ' '; _db4_gc g16 6 DJ4_sysctl_perf=6 DJ4_sysctl_ncpu=djy-fail DJ4_getconf=9
}
_db4_gb() {   # (b) LABEL VALUE: a performance-core count of VALUE (djy-fail: the call fails) falls to hw.ncpu, 12 here; beside it, a count of 6 over the same hw.ncpu is used
  _db4_gc "${1}a" 12 DJ4_sysctl_perf="$2" DJ4_sysctl_ncpu=12; printf ' '; _db4_gc "${1}b" 6 DJ4_sysctl_perf=6 DJ4_sysctl_ncpu=12
}
_db4_gf() {   # (b) with the performance-core key failing, hw.ncpu then getconf then 1, held to 64, as before; and a count of 6 over the same keys is used
  _db4_gc g25 3 DJ4_sysctl_perf=djy-fail DJ4_sysctl_ncpu=3 DJ4_getconf=9; printf ' '; _db4_gc g26 12 DJ4_sysctl_perf=djy-fail DJ4_sysctl_ncpu=djy-fail DJ4_getconf=12; printf ' '
  _db4_gc g27 1 DJ4_sysctl_perf=djy-fail DJ4_sysctl_ncpu=djy-fail DJ4_getconf=; printf ' '; _db4_gc g28 64 DJ4_sysctl_perf=djy-fail DJ4_sysctl_ncpu=200; printf ' '
  _db4_gc g29 5 DJ4_sysctl_perf=djy-fail DJ4_sysctl_ncpu=abc DJ4_getconf=5; printf ' '; _db4_gc g30 64 DJ4_sysctl_perf=0 DJ4_sysctl_ncpu=djy-fail DJ4_getconf=100; printf ' '
  _db4_gc g31 6 DJ4_sysctl_perf=6 DJ4_sysctl_ncpu=3 DJ4_getconf=9; printf ' '
  _db4_gc g39 1 DJ4_sysctl_perf=djy-fail DJ4_sysctl_ncpu=0 DJ4_getconf=9   # R52: a step 2 zero is a number, so it does not fall to getconf, and is held to 1
}
_db4_gh() {   # (c) a performance-core count above 64 is held to 64 (200, 65), 64 stays 64, and a count of 6 over the same hw.ncpu is not held
  _db4_gc g32 64 DJ4_sysctl_perf=200 DJ4_sysctl_ncpu=12; printf ' '; _db4_gc g33 64 DJ4_sysctl_perf=65 DJ4_sysctl_ncpu=3; printf ' '
  _db4_gc g34 64 DJ4_sysctl_perf=64 DJ4_sysctl_ncpu=12; printf ' '; _db4_gc g35 6 DJ4_sysctl_perf=6 DJ4_sysctl_ncpu=12
}
_db4_gz() {   # (R52) a count of 08 is digits only and is 8, and 09 is 9 (so a build that reads another key cannot pass by that key giving 8 on this machine); a count of exactly 1 is 1; each over an hw.ncpu of 12
  _db4_gc g36 8 DJ4_sysctl_perf=08 DJ4_sysctl_ncpu=12; printf ' '; _db4_gc g38 9 DJ4_sysctl_perf=09 DJ4_sysctl_ncpu=12; printf ' '; _db4_gc g37 1 DJ4_sysctl_perf=1 DJ4_sysctl_ncpu=12
}
_db4_g "R51: the performance-core count answers first: hw.perflevel0.logicalcpu 6 over a different hw.ncpu 12 gives 6, 8 over 4 gives 8, and a failing hw.ncpu or a getconf does not change it" "ok ok ok ok" _db4_gp
_db4_g "R51: a performance-core count whose call fails falls to hw.ncpu (12), where a count of 6 beside it is used" "ok ok" _db4_gb g17 djy-fail
_db4_g "R51: a performance-core count that is empty falls to hw.ncpu (12), where a count of 6 beside it is used" "ok ok" _db4_gb g18 ""
_db4_g "R51: a performance-core count of 0 falls to hw.ncpu (12), where a count of 6 beside it is used" "ok ok" _db4_gb g19 0
_db4_g "R51: a performance-core count of 00 falls to hw.ncpu (12), where a count of 6 beside it is used" "ok ok" _db4_gb g20 00
_db4_g "R51: a performance-core count that is not a number (abc) falls to hw.ncpu (12), where a count of 6 beside it is used" "ok ok" _db4_gb g21 abc
_db4_g "R51: a performance-core count that is not digits only (6x) falls to hw.ncpu (12), where a count of 6 beside it is used" "ok ok" _db4_gb g22 6x
_db4_g "R51: with the performance-core key (hw.perflevel0.logicalcpu) failing, or set to 0 in one case, hw.ncpu answers, then getconf, then 1, a count above 64 is held to 64, and a non-number falls on, as before; an hw.ncpu of 0 is a number that does not fall to getconf and is held to 1 (R52); a performance-core count of 6 over the same keys is used" "ok ok ok ok ok ok ok ok" _db4_gf
_db4_g "R51: a performance-core count of 200 is held to 64, so are 65 and the largest N 64 itself, and a count of 6 over the same hw.ncpu is not held" "ok ok ok ok" _db4_gh
_db4_g "R52: a performance-core count of 08 over an hw.ncpu of 12 gives 8 and 09 gives 9 (the leading zero is stripped), and a count of 1 over 12 gives 1" "ok ok ok" _db4_gz
_db4_g "D1: when tests/run exits 2 with one line on stderr the gate reports tests FAIL and shows the log's last line under it" "1 1 failed" _db4_gx

# ---- the interface: the largest N, six names of --part, and part mode keyed on its argument alone (D1, D2)
_db4_q acc; _db4_new acc "$DB4/g-empty.tsv" + "$DB4/pp/acc"/*.sh
_db4_go a -j 64; _db4_wait; _db4_x="$_db4_rc $(_db4_last a | grep -c ' (counted from lines)$')"
_db4_E=(FELIX_TEST_JOBS=64); _db4_go b; _db4_wait; _db4_x="$_db4_x | $_db4_rc $(_db4_last b | grep -c ' (counted from lines)$')"
_db4_is "D1: the largest N, 64, is accepted both as -j 64 and as FELIX_TEST_JOBS=64: exit 0 and a summary counted from lines" "$_db4_x" "0 1 | 0 1"
rm -rf "$DB4/n/acc"
_db4_q accr; _db4_new accr "$DB4/g-empty.tsv" + "$DB4/pp/accr"/*.sh
_db4_go a -j 3 --reuse; _db4_wait
_db4_is "D3: -j 3 --reuse with no receipt to reuse runs the suite: exit 0, a summary that ends (counted from lines) and not (reused), and a receipt left" \
   "$_db4_rc $(_db4_last a | grep -c ' (counted from lines)$') $(_db4_last a | grep -c ' (reused)$') $(_db4_rcpt)" "0 1 0 present"
rm -rf "$DB4/n/accr"
for _db4_i in 1 2 3 4 5 6; do _db4_w six "00${_db4_i}0-f$_db4_i.sh" <<'X'
ok "djy $DJ4N"
X
done
_db4_new six "$DB4/g-empty.tsv" + "$DB4/pp/six"/*.sh
_db4_go p --part 0010-f1.sh 0020-f2.sh 0030-f3.sh 0040-f4.sh 0050-f5.sh 0060-f6.sh; _db4_wait
_db4_x="$(grep '^@@' "$_db4_c/p.out" | tr '\n' '|')"
_db4_is "D2: --part takes six names and prints the prelude mark, a member mark for each in order, and the part mark naming all six, with exit 0" "$_db4_rc $_db4_x" \
   "0 @@prelude-done|@@member-done 0010-f1.sh|@@member-done 0020-f2.sh|@@member-done 0030-f3.sh|@@member-done 0040-f4.sh|@@member-done 0050-f5.sh|@@member-done 0060-f6.sh|@@part-done 0010-f1.sh 0020-f2.sh 0030-f3.sh 0040-f4.sh 0050-f5.sh 0060-f6.sh|"
_db4_go p1 --part 0030-f3.sh; _db4_wait
_db4_is "D2: and with one name the member sits between the two marks, and only that part's assertion after the prelude" \
   "$_db4_rc $(sed -n '/^@@prelude-done$/,$p' "$_db4_c/p1.out" | tr '\n' '|')" "0 @@prelude-done||djy-sec 0030-f3.sh|  ok    djy 0030-f3.sh|@@member-done 0030-f3.sh|@@part-done 0030-f3.sh|"
_db4_E=(FELIX_TEST_PART_LOG="$_db4_c/x.log" FELIX_TEST_PART_RAN="$_db4_c/x.ran" FELIX_TEST_PART_END="$_db4_c/x.end"); _db4_go e -j 1; _db4_wait
_db4_is "D1: the FELIX_TEST_PART_ variables alone do not make part mode: a run without --part reaches its end on stdout and writes none of the files (control)" \
   "$_db4_rc $(_db4_cnt "$_db4_c/e.out" reached) $(grep -c '^@@' "$_db4_c/e.out") $(ls "$_db4_c"/x.* 2>/dev/null | wc -l | tr -d ' ')" "0 1 0 0"
rm -rf "$DB4/n/six"

# ---- the durations file (D4): written whole by a -j run with no runner failure and by nothing else, read by a run that writes it and by no red run. Row 0040 is the longest
_db4_clr() { rm -f "$_db4_c"/started.* "$_db4_c"/ord.*; }
_db4_ord() { cat "$_db4_c/ord.0040-qd.sh" 2>/dev/null; }   # how many units had started when the unit with the longest recorded duration started
_db4_q dur; _db4_new dur "$DB4/g-empty.tsv" + "$DB4/pp/dur"/*.sh
_db4_dg="$_db4_F/.git/felix-suite-durations"; printf '0\t0010-qa.sh\n0\t0020-qb.sh\n0\t0030-qc.sh\n50\t0040-qd.sh\n5\tdjy-sentinel.sh\n' > "$_db4_dg"; cp "$_db4_dg" "$DB4/dur.seed"
_db4_E=(FELIX_TEST_NO_MANIFEST=1); _db4_go n -j 3; _db4_wait
_db4_x="$_db4_rc $(_db4_last n | grep -c ' (counted from lines)$') $(cmp -s "$_db4_dg" "$DB4/dur.seed" && echo kept || echo changed) $(_db4_rcpt)"
_db4_is "D4: a -j 3 run under FELIX_TEST_NO_MANIFEST=1, as red runs, counts from lines, writes no durations and leaves no receipt" "$_db4_x" "0 1 kept absent"
_db4_is "D4: and it reads none: the unit with the longest recorded duration, which a run that reads the file starts among the first three, started after at least three others had" "$([ "$(_db4_ord)" -ge 3 ] 2>/dev/null && echo late || echo "after $(_db4_ord) others")" late
_db4_clr; _db4_go j1 -j 1; _db4_wait; _db4_x="$_db4_rc $(cmp -s "$_db4_dg" "$DB4/dur.seed" && echo kept || echo changed) $(_db4_rcpt)"
_db4_go ru --reuse; _db4_wait; _db4_x="$_db4_x | $_db4_rc $(cmp -s "$_db4_dg" "$DB4/dur.seed" && echo kept || echo changed)"
_db4_is "D4: a -j 1 run and a --reuse after it neither remove nor rewrite the durations file (control)" "$_db4_x" "0 kept present | 0 kept"
_db4_clr; _db4_go j3 -j 3; _db4_wait
_db4_is "D4: a -j 3 run does write it, whole: the sentinel row gone, one row for each of the four parts" \
   "$_db4_rc $(grep -c 'djy-sentinel' "$_db4_dg") $(awk 'END { print NR }' "$_db4_dg") $(_db4_last j3 | grep -c ' (counted from lines)$')" "0 0 4 1"
_db4_is "D4: and a run that writes it reads it: the unit with the longest recorded duration starts among the first three, after fewer than three others" "$([ "$(_db4_ord)" -le 2 ] 2>/dev/null && echo early || echo "after $(_db4_ord) others")" early
rm -rf "$DB4/n/dur"
_db4_w dk 0010-ka.sh <<'X'
ok "djy $DJ4N"
X
_db4_w dk 0020-kb.sh <<'X'
ok "djy before"
kill -9 $$
X
_db4_new dk "$DB4/g-empty.tsv" + "$DB4/pp/dk"/*.sh
printf '5\t0010-ka.sh\n' > "$_db4_F/.git/felix-suite-durations"; cp "$_db4_F/.git/felix-suite-durations" "$DB4/dk.seed"
_db4_go k -j 3; _db4_wait
_db4_is "D4: a -j 3 run with a runner failure writes no durations: the file is as it was, and the failure is the unit's" \
   "$_db4_rc $(cmp -s "$_db4_F/.git/felix-suite-durations" "$DB4/dk.seed" && echo kept || echo changed) $(_db4_cnt "$_db4_c/k.out" '  FAIL  part ended without its mark: 0020-kb.sh')" "1 kept 1"
# the three assertions of 9990 judge the units' end states: a unit with no end file makes all three bad (D3)
_db4_n9a="no fixture git command was refused for a directory outside the suite's temporary directory"
_db4_n9b="fixture floor: at the end of the suite it still stands in cwd inside its temporary directory, under a ceiling at that directory's parent"
_db4_n9c="the remotes of the checkout this run started in did not move while it ran"
_db4_x="$(for _db4_a in "$_db4_n9a" "$_db4_n9b" "$_db4_n9c"; do grep -qF -e "$_db4_a" "$HERE"/parts/9990-*.sh && printf 'named '; done)"
_db4_is "D3: the three names the cases below read are 9990's (control)" "$_db4_x" "named named named "
_db4_is "D3: a unit killed with kill -9 has no end file, so 9990's floor, refusal and origin assertions each FAIL once, beside the unit's own failures" \
   "$(_db4_cnt "$_db4_c/k.out" "  FAIL  $_db4_n9b") $(_db4_cnt "$_db4_c/k.out" "  FAIL  $_db4_n9a") $(_db4_cnt "$_db4_c/k.out" "  FAIL  $_db4_n9c")" "1 1 1"
rm -rf "$DB4/n/dk"
# a unit's own origin verdict: a remote moved and put back inside one unit is still a move (the unit's record), and the parent, which never saw the config differ, must say so
_db4_w om 0010-oa.sh <<'X'
ok "djy $DJ4N"
X
_db4_w om 0020-ob.sh <<'X'
_cfg="$_og_start/.git/config"
cp -p "$_cfg" "$DJ4D/config.save"
sleep 1.2
printf '[remote "djyx"]\n\turl = /nonexistent/djyx.git\n\tfetch = +refs/heads/*:refs/remotes/djyx/*\n' >> "$_cfg"
ok "djy $DJ4N moved"
cp -p "$DJ4D/config.save" "$_cfg"
ok "djy $DJ4N put back"
X
_db4_new om "$DB4/g-empty.tsv" + "$DB4/pp/om"/*.sh
_db4_go o1 -j 1; _db4_wait; _db4_x="$_db4_rc $(_db4_cnt "$_db4_c/o1.out" "  FAIL  $_db4_n9c")"
_db4_is "D3: a remote moved and put back inside a part makes a -j 1 run's origin assertion FAIL (control for the case below)" "$_db4_x" "1 1"
_db4_go o3 -j 3; _db4_wait
_db4_is "D3: and inside a unit it does the same under -j 3: the unit's verdict is bad, so the origin assertion FAILs once and the run exits 1" \
   "$_db4_rc $(_db4_cnt "$_db4_c/o3.out" "  FAIL  $_db4_n9c") $(_db4_last o3 | grep -c ' (counted from lines)$')" "1 1 1"
rm -rf "$DB4/n/om"
# a record run with a runner failure ends in the runner, before 9990's lines and the record's, writes no manifest, and leaves nothing of red's tree (D4: _db4_fin's group drain, whose finding goes to the D4 name; R1, R48: the manifest and red.tsv's rows)
_db4_new rk --red "$DB4/g-empty.tsv" "$DB4/man.tsv" "$DB4/pp/dk"/*.sh
_db4_go r -j 3 --record-assertions; _db4_wait
_db4_x="$_db4_rc $(grep -cF -e "$_db4_n9a" -e "$_db4_n9b" -e "$_db4_n9c" "$_db4_c/r.out") $(_db4_pfx "$_db4_c/r.out" '  recorded ') $(_db4_cnt "$_db4_c/r.out" reached) $(_db4_cnt "$_db4_c/r.out" '  FAIL  part ended without its mark: 0020-kb.sh')"
_db4_is "D4: a record run with a unit killed exits 1 in the runner: none of 9990's three lines, no recorded line, no reached, and the unit's failure printed" "$_db4_x" "1 0 0 0 1"
_db4_is "R1: and it writes no manifest, and red.tsv holds exactly the rows base - - - and run - - -" \
   "$(cmp -s "$DB4/man.tsv" "$_db4_T/assertions.tsv" && echo same || echo changed) $(grep -v '^#' "$_db4_T/red.tsv" 2>/dev/null | tr '\t' ' ' | tr '\n' '|')" "same base - - -|run - - -|"
rm -rf "$DB4/n/rk"

# ---- the log is printed in the driver's order, once a unit and every unit before it have ended (D3)
# R56: the slow unit's hold on release.a lives B + 30 s (3150 polls of at least 0.2 s; was 400, 80 s), the case's waits for the units' files are bounds that last
# until the run's bound, and the watch (R56's floor: a parent that printed each unit's log as it ended would print these two once they have gone) starts once the
# two quick units have no process left, not when they write their files, before their ends. R61: the hold also ends once the case's directory is gone
_db4_w ord 0010-ea.sh <<'X'
: > "$DJ4D/up.$DJ4N"
_i=0; until [ -e "$DJ4D/release.a" ] || [ ! -d "$DJ4D" ] || [ "$_i" -ge 3150 ]; do sleep 0.2; _i=$((_i + 1)); done
ok "djy $DJ4N"
X
for _db4_a in 0020-eb.sh 0030-ec.sh; do _db4_w ord "$_db4_a" <<'X'
: > "$DJ4D/done.$DJ4N"
ok "djy $DJ4N"
X
done
_db4_new ord "$DB4/g-empty.tsv" + "$DB4/pp/ord"/*.sh
_db4_go o -j 3
_db4_noq() { [ -z "$(_db4_unitn 0020-eb.sh)$(_db4_unitn 0030-ec.sh)" ]; }
# R58, a watch: 20 s (was 3 s) from the quick units' exit, the event after which a parent that printed each unit's log as it ended (D3's order missing) would act:
# the holder's exit, the wrapper's line, the parent's read, and the printing of the log, which forks, so the floor is 20 s. This name rests on it alone. It ends
# early once either section is in the log, which fails the name
_db4_sect() { [ "$(_db4_cnt "$_db4_c/o.out" 'djy-sec 0020-eb.sh')$(_db4_cnt "$_db4_c/o.out" 'djy-sec 0030-ec.sh')" != 00 ]; }
_db4_evt test -e "$_db4_c/up.0010-ea.sh"; _db4_evt test -e "$_db4_c/done.0030-ec.sh"; _db4_evt test -e "$_db4_c/done.0020-eb.sh"; _db4_evt _db4_noq; _db4_watch 20 log _db4_sect
_db4_x="$(_db4_cnt "$_db4_c/o.out" 'djy-sec 0020-eb.sh') $(_db4_cnt "$_db4_c/o.out" 'djy-sec 0030-ec.sh')"; _db4_y="$([ -e "$_db4_c/done.0030-ec.sh" ] && echo ended-first || echo not-ended)"
: > "$_db4_c/release.a"; _db4_wait
_db4_is "D3: the two units after a slow first one end before it, and the log shows neither of them until the first has ended" "$_db4_y $_db4_x" "ended-first 0 0"
_db4_is "D3: once it has, the sections come in the driver's order, and the run passes, counted from lines, with no wait note and no prelude-prefixed line" \
   "$_db4_rc $(_db4_last o | grep -c ' (counted from lines)$') $(grep '^djy-sec ' "$_db4_c/o.out" | tr '\n' ' ')$(_db4_wn "$_db4_c/o.out") $(_db4_pfx "$_db4_c/o.out" '  | ')" "0 1 djy-sec 0010-ea.sh djy-sec 0020-eb.sh djy-sec 0030-ec.sh 0 0"
rm -rf "$DB4/n/ord"

# ---- a unit that waited for a slot (D3, D4, D6, R7, R54): the note says how long, in the shape R7 gives, apart from the tail's own note; the duration written does not count the wait.
# R54: one slot, -j 2. The body that runs first makes first.d before the other can, and holds the slot 30 s; the other body runs 2 s and writes its name to second. So the unit
# that waited is the one whose body ran second, whichever wrapper took the slot. R7's S is at least the 30 s the other held the slot: load only lengthens a wait, so this is a
# floor (R56). D4's duration for the unit the note names is its own prelude, 2 s and end, less than S; one that counted the wait would run from the unit's first try for a
# slot, S plus its own run in whole seconds, so at least S + 1. The name fails on D's build only if that unit's prelude and end took 28 s more than the holder's.
for _db4_a in 0010-wa.sh 0020-wb.sh; do _db4_w wt "$_db4_a" <<'X'
if mkdir "$DJ4D/first.d" 2>/dev/null; then printf '%s\n' "$DJ4N" > "$DJ4D/first.d/name"; perl -e 'sleep 30'; else printf '%s\n' "$DJ4N" > "$DJ4D/second"; perl -e 'sleep 2'; fi
ok "djy $DJ4N"
X
done
_db4_new wt "$DB4/g-empty.tsv" + "$DB4/pp/wt"/*.sh; _db4_S=1; _db4_go a -j 2; _db4_wait
_db4_nt="$(grep -E '^  note  [^ ]+ waited [0123456789]+ s for a slot$' "$_db4_c/a.out")"; _db4_nu="$(printf '%s' "$_db4_nt" | awk '{ print $2 }')"; _db4_ns="$(printf '%s' "$_db4_nt" | awk '{ print $4 }')"
_db4_sec="$(cat "$_db4_c/second" 2>/dev/null)"
_db4_dw="$(N="$_db4_nu" awk -F'\t' '$2 == ENVIRON["N"] { print $1 }' "$_db4_F/.git/felix-suite-durations" 2>/dev/null)"
_db4_dn="$(awk 'END { print NR }' "$_db4_F/.git/felix-suite-durations" 2>/dev/null)"
_db4_is "R7: with one slot the unit that waited, the one whose body ran second, gets exactly one line of the note's shape, whose seconds S are at least the 30 s the other held the slot, and the tail's own note, which the manifest of the stubs alone makes it print, is a separate line" \
   "$_db4_rc $(_db4_wn "$_db4_c/a.out") $([ -n "$_db4_nu" ] && [ "$_db4_nu" = "$_db4_sec" ] && echo second || echo "named [${_db4_nu:-none}] second [${_db4_sec:-none}]") $([ "${_db4_ns:-0}" -ge 30 ] 2>/dev/null && echo long || echo "S=${_db4_ns:-none}") $(_db4_tn "$_db4_c/a.out")" "0 1 second long 1"
case "$_db4_dw" in   # not inside $( ): bash 3.2 ends the substitution at the pattern's )
  ''|*[!0123456789]*) _db4_dv="no duration for [${_db4_nu:-none}] [$_db4_dw]" ;;
  *) if [ "$_db4_dw" -lt "${_db4_ns:-0}" ] 2>/dev/null; then _db4_dv=shorter; else _db4_dv="not shorter [$_db4_dw against S=${_db4_ns:-none}]"; fi ;;
esac
_db4_is "D4: and the duration written for the unit the note names is less than S, so it is not charged for the wait (one counted from its first try for a slot would be at least S + 1)" \
   "${_db4_dn:-0} $_db4_dv" "2 shorter"
rm -rf "$DB4/n/wt"

# ---- what the parent prints of a unit (D3): what comes after the mark stays as written, and no runner line shows
_db4_w fm 0010-fa.sh <<'X'
trap 'printf "djy-after-mark\n"; rm -rf "$TMP"' EXIT
ok "djy $DJ4N"
X
_db4_w fm 0020-fb.sh <<'X'
ok "djy $DJ4N"
X
_db4_new fm "$DB4/g-empty.tsv" + "$DB4/pp/fm"/*.sh; _db4_go f -j 3; _db4_wait
_db4_fo="$(LC_ALL=C awk '
  $0 == "djy-after-mark" { a = NR; na++ }
  $0 == "  ok    djy 0010-fa.sh" { o = NR }
  $0 == "  FAIL  part left the shell changed for the parts after it: 0010-fa.sh" { f = NR; nf++ }
  $0 == "  | trap on EXIT changed" { p = NR; np++ }
  $0 == "djy-sec 0020-fb.sh" { s2 = NR }
  END { printf "%d %d %d %s %s %s %s", na + 0, nf + 0, np + 0, (o && a > o) ? "after-its-lines" : "order-wrong", (a && f > a) ? "fail-after" : "fail-order-wrong", (f && p == f + 1) ? "detail-next" : "detail-wrong", (p && s2 > p) ? "in-its-place" : "place-wrong" }' "$_db4_c/f.out")"
_db4_is "R16: a line a unit's own EXIT trap prints after the mark is printed as written, once, after the unit's other lines, with no @@ line; after it come the unit's runner failure 'part left the shell changed for the parts after it' and, next, '  | trap on EXIT changed', before the next unit's section; the run exits 1 and leaves no receipt" \
   "$_db4_fo $(grep -c '^@@' "$_db4_c/f.out") $_db4_rc $(_db4_rcpt)" "1 1 1 after-its-lines fail-after detail-next in-its-place 0 1 absent"
rm -rf "$DB4/n/fm"

# ---- R41 (a): what the stand-in made is all below this part's own case directories (the run's TMPDIR), so nothing of the nested runs is left in the host's temporary directory
_db4_x="$(LC_ALL=C awk -v a="$DB4/n/" -v b="$DB4/td-" 'index($0, a) == 1 || index($0, b) == 1 { n++; next } { o = o " " $0 } END { if (n > 0 && o == "") print "all below"; else print n + 0 " below, outside:" o }' "$DB4/mktemp.log" 2>/dev/null)"
is "R41: every path the mktemp stand-in logged for this part's nested runs is below one of the part's own case directories, and it logged some" "$_db4_x" "all below"

# ---- the part leaves the shell as it found it
_db4_unhold
rm -rf "${DB4:?}"
unset -f $(compgen -A function _db4_) 2>/dev/null
unset $(compgen -A variable _db4_) DB4 DG DGC 2>/dev/null
# <<< gate-friction-d-slots-blind
