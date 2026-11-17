_qualify_sweep_build
# 3b. The pid from a sh that forks: a sh first on PATH that runs /bin/sh
# without exec, as a wrapper may. While its row holds, the record names the
# row's own live process; or there is none, and the row ran nothing. Never a
# pid already gone while the row is alive, which another run would sweep.
d="$QSWS/fork-sh"; T="$d/t"; mkdir -p "$T" "$d/bin"; R="$(_qswroot "$d/root")"
printf '#!/bin/bash\n/bin/sh "$@"\n' > "$d/bin/sh"; chmod +x "$d/bin/sh"
_qswpath="$d/bin"; _qswhold "$d" "$T" "$R"; _qswpath=""
_qswcaller="$(cat "$d/a/caller" 2>/dev/null)"; _qswheldp="$(cat "$d/at" 2>/dev/null)"
_qswb="$(_qswbase "$T")"; _qswr=""
[ -n "$_qswb" ] && _qswr="$(readlink "$T/$_qswb/owner" 2>/dev/null)"
_qswfk="ran-nothing"
[ -s "$d/at" ] && _qswfk="held pid:$(_qswrole "${_qswr%% *}" "$_qswheldp" "$_qswcaller") alive:$(_qswalive "${_qswr%% *}")"
: > "$d/release"; _qswfinish "$_qswa" "$d/a"
case "$_qswfk $(_qswverd "$d/a")" in
  "held pid:row alive:yes pass met"|"ran-nothing unrunnable unrunnable") _qswfk=ok ;;
  *) _qswfk="$_qswfk $(_qswverd "$d/a")" ;;
esac
is  "with a sh first on PATH that forks rather than execs, a row whose checker holds records its own live process, and ends pass and met, or records none and reads unrunnable having run nothing: never a pid already gone while the row is alive" \
    "$_qswfk" "ok"

# 4. The row's process alone killed, its caller left running: the tree is
# removed by another run's sweep. The caller alone killed, the row alive:
# the sweep leaves it, and the row removes it at its end.
# The run has a second row that holds in turn, so its caller is still running
# when the later run sweeps, and a record of the caller's pid would be seen.
d="$QSWS/row-killed"; T="$d/t"; mkdir -p "$T" "$d/proj"; R="$(_qswroot "$d/root")"; Tp="$(_qswphys "$T")"; _qswtab "$d/projb"
for _qswi in 1 2; do
  _qsw5 "held$_qswi" "exec perl -e 'open(my \$f, q(>), \$ARGV[1]) or exit 3; print \$f \$\$; close \$f; for (1 .. 300) { last if -e \$ARGV[0]; sleep 1 } exit((-e q(base.txt)) ? 0 : 1)' '$d/release$_qswi' '$d/at$_qswi'" \
        restoration pass true
done > "$d/proj/qualification.tsv"
_qswbg "$d/a" "$T" "$R" - run "$d/proj" "$R"; _qswa="$_qswpid"
_qswtill 240 _qswheld "$d/at1" "$_qswa"
_qswcaller="$(cat "$d/a/caller" 2>/dev/null)"; _qswheldp="$(cat "$d/at1" 2>/dev/null)"
_qswb="$(_qswbase "$T")"; _qswr=""
[ -n "$_qswb" ] && _qswr="$(readlink "$T/$_qswb/owner" 2>/dev/null)"
# The pid the record names when it names the row's process, else the row's
# process found by ancestry, so the kill lands on the row alone either way.
_qswrowp="${_qswr%% *}"
[ "$(_qswrole "$_qswrowp" "$_qswheldp" "$_qswcaller")" = row ] || _qswrowp="$(_qswrowof "$_qswheldp" "$_qswcaller")"
_qswp1="none-made"; [ -n "$_qswb" ] && _qswp1="$(_qswpre "$T/$_qswb" "$R" "$Tp/$_qswb/w")"
[ -n "$_qswrowp" ] && kill -s KILL "$_qswrowp" 2>/dev/null
_qswtill 60 _qswreaped "$_qswrowp"
_qswtill 240 _qswheld "$d/at2" "$_qswa"
_qswrun "$d/b" "$T" "$R" "$d/projb"
_qswres="$([ -n "$_qswb" ] && _qswgone "$_qswp1" "$T/$_qswb" "$R" "$Tp/$_qswb/w" || echo no-base-was-made) caller:$(_qswalive "$_qswcaller") second:$([ -s "$d/at2" ] && _qswalive "$(cat "$d/at2")" || echo none)"
: > "$d/release1"; : > "$d/release2"; _qswfinish "$_qswa" "$d/a"
is  "a row whose own process alone is SIGKILLed while its checker holds, its caller left running on into a second row that holds in turn, has its base and registration removed by the sweep of a run started once it is gone, the caller and the second row still running then" \
    "$_qswres $(_qswverd "$d/b")" "gone caller:yes second:yes pass met"

d="$QSWS/caller-killed"; T="$d/t"; mkdir -p "$T"; R="$(_qswroot "$d/root")"; Tp="$(_qswphys "$T")"; _qswtab "$d/projb"
_qswhold "$d" "$T" "$R"
_qswcaller="$(cat "$d/a/caller" 2>/dev/null)"; _qswheldp="$(cat "$d/at" 2>/dev/null)"
_qswb="$(_qswbase "$T")"; _qswr=""
[ -n "$_qswb" ] && _qswr="$(readlink "$T/$_qswb/owner" 2>/dev/null)"
_qswwho="$(_qswrole "${_qswr%% *}" "$_qswheldp" "$_qswcaller")"
_qswrowp="${_qswr%% *}"
[ "$_qswwho" = row ] || _qswrowp="$(_qswrowof "$_qswheldp" "$_qswcaller")"
[ -n "$_qswcaller" ] && { disown "$_qswa" 2>/dev/null; kill -s KILL "$_qswcaller" 2>/dev/null; }
_qswtill 60 _qswnotlive "$_qswcaller"
_qswp1="none-made"; [ -n "$_qswb" ] && _qswp1="$(_qswpre "$T/$_qswb" "$R" "$Tp/$_qswb/w")"
_qswwas="$([ -n "$_qswb" ] && _qswsnap "$T/$_qswb" "$R" "$Tp/$_qswb/w")"
_qswrun "$d/b" "$T" "$R" "$d/projb"
_qswnow="$([ -n "$_qswb" ] && _qswsnap "$T/$_qswb" "$R" "$Tp/$_qswb/w")"
is  "a run whose caller alone is SIGKILLed while its row holds keeps that row's owner record naming the row's live process, and a later run's sweep leaves that base, record and registration as they were" \
    "pid:$_qswwho alive:$(_qswalive "${_qswr%% *}") same:$([ "$_qswnow" = "$_qswwas" ] && echo yes || echo no) owner:$([ -n "$_qswb" ] && [ -L "$T/$_qswb/owner" ] && echo link || echo none) registered:$([ -n "$_qswb" ] && _qswlisted "$R" "$Tp/$_qswb/w" || echo no)" \
    "pid:row alive:yes same:yes owner:link registered:yes"
: > "$d/release"
_qswtill 240 _qswreaped "$_qswrowp"
_qswfinish "$_qswa" "$d/a"
is  "and released, that row runs to its end and removes its own base and registration" \
    "$([ -n "$_qswb" ] && _qswgone "$_qswp1" "$T/$_qswb" "$R" "$Tp/$_qswb/w" || echo no-base-was-made) $(_qswwt "$R")" "gone wt:0"

# 5. Planted bases. Three with a dead owner are swept; beside them, every
# base that is not exactly one a row makes, with a record exactly as a row
# writes it, is left as it was: mode, record, entries and registration.
# The bases to be left are made 0555 first (the one with no search bit,
# 0600), so a sweep that gave one its bits back before judging it is seen.
d="$QSWS/planted"; T="$d/t"; mkdir -p "$T"; R="$(_qswroot "$d/root")"; Tp="$(_qswphys "$T")"; _qswtab "$d/proj"
_qswd1="$(_qswdead)"; _qswd2="$(_qswdead)"; _qswd3="$(_qswdead)"; _qswdx="$(_qswdead)"
_qswplant "$T" felix-qualify.DEADP1 "$R" "$_qswd1"
_qswplant "$T" felix-qualify.DEADP2 "$R" "$_qswd2 $QSWOLD"; chmod 0555 "$T/felix-qualify.DEADP2"
mkdir -p "$d/outside/dir"; printf 'kept\n' > "$d/outside/file"; printf 'kept\n' > "$d/outside/dir/inner"
chmod 0444 "$d/outside/file" "$d/outside/dir/inner"; chmod 0555 "$d/outside/dir"
_qswplant "$T" felix-qualify.DEADP3 "$R" "$_qswd3 $QSWOLD"
ln -s "$d/outside/file" "$T/felix-qualify.DEADP3/w/lf"; ln -s "$d/outside/dir" "$T/felix-qualify.DEADP3/w/ld"
chmod a-w "$T/felix-qualify.DEADP3/w"
_qswleft "$d" "$T" "$R" felix-qualify.NOREC1 - 0555
_qswleft "$d" "$T" "$R" felix-qualify.FILREC "file:$_qswdx" 0555
_qswleft "$d" "$T" "$R" felix-qualify.PIDZER 0 0555
_qswleft "$d" "$T" "$R" felix-qualify.NEGPID "-$_qswdx" 0555
_qswleft "$d" "$T" "$R" felix-qualify.NONDIG abc 0555
_qswemptyok=no
( cd "$d" && ln -s '' empty-probe ) 2>/dev/null && [ -L "$d/empty-probe" ] && _qswemptyok=yes
[ "$_qswemptyok" = yes ] && _qswleft "$d" "$T" "$R" felix-qualify.EMPTYR '' 0555
_qswleft "$d" "$T" "$R" felix-qualify.TWOSPC "$_qswdx  $QSWOLD" 0555
_qswleft "$d" "$T" "$R" felix-qualify.TRLSPC "$_qswdx " 0555
_qswleft "$d" "$T" "$R" felix-qualify.TABSTA "$_qswdx Thu"$'\t'"Jan100:00:001970" 0555
_qswleft "$d" "$T" "$R" felix-qualify.LEADZR "0$_qswdx" 0555
_qswleft "$d" "$T" "$R" felix-qualify.NEWLIN "$_qswdx"$'\n' 0555
_qswleft "$d" "$T" "$R" felix-qualify.NOSRCH "$_qswdx $QSWOLD" 0600
_qswleft "$d" "$T" "$R" tmp.Ab12Cd "$_qswdx $QSWOLD" 0555
_qswleft "$d" "$T" "$R" felix-qualify.abcde "$_qswdx $QSWOLD" 0555
_qswleft "$d" "$T" "$R" felix-qualify.abcdefg "$_qswdx $QSWOLD" 0555
_qswleft "$d" "$T" "$R" felix-qualify.abc-ef "$_qswdx $QSWOLD" 0555
_qswleft "$d" "$T" "$R" felix-qualify-abcdef "$_qswdx $QSWOLD" 0555
_qswplant "$d" linktarget "$R" "$_qswdx $QSWOLD"; chmod 0555 "$d/linktarget"
ln -s "$d/linktarget" "$T/felix-qualify.SYMLNK"
_qswlt="$(_qswphys "$d/linktarget")/w"
_qswlinkwas="$(_qswsnap "$T/felix-qualify.SYMLNK" "$R" "$_qswlt") | $(_qswsnap "$d/linktarget" "$R" "$_qswlt")"
_qswp1="$(_qswpre "$T/felix-qualify.DEADP1" "$R" "$Tp/felix-qualify.DEADP1/w")"
_qswp2="$(_qswpre "$T/felix-qualify.DEADP2" "$R" "$Tp/felix-qualify.DEADP2/w")"
_qswp3="$(_qswpre "$T/felix-qualify.DEADP3" "$R" "$Tp/felix-qualify.DEADP3/w")"
_qswrun "$d/run" "$T" "$R" "$d/proj"
_qswctl="$(_qswgone "$_qswp2" "$T/felix-qualify.DEADP2" "$R" "$Tp/felix-qualify.DEADP2/w")"
# Where /proc names the pid namespace, a pid alone may be another host's or
# another boot's, so it is never judged there (review round 2).
if [ -n "$(_qswns)" ]; then
  skip "a base in the TMPDIR named felix-qualify. and six letters or digits, holding owner as a symlink whose text is a dead pid alone, is swept with its tree's registration, and the run's own row still reads pass and met" "this host's /proc names its pid namespace, where a pid alone is left"
  is  "where /proc names this host's pid namespace, a base holding owner as a symlink whose text is a dead pid alone, no start naming that namespace and boot, is left and stays registered, beside a dead base swept, and the run's own row still reads pass and met" \
      "beside:$_qswctl base:$(_qswthere "$T/felix-qualify.DEADP1") registered:$(_qswlisted "$R" "$Tp/felix-qualify.DEADP1/w") $(_qswverd "$d/run")" "beside:gone base:there registered:yes pass met"
else
  is  "a base in the TMPDIR named felix-qualify. and six letters or digits, holding owner as a symlink whose text is a dead pid alone, is swept with its tree's registration, and the run's own row still reads pass and met" \
      "$(_qswgone "$_qswp1" "$T/felix-qualify.DEADP1" "$R" "$Tp/felix-qualify.DEADP1/w") $(_qswverd "$d/run")" "gone pass met"
  skip "where /proc names this host's pid namespace, a base holding owner as a symlink whose text is a dead pid alone, no start naming that namespace and boot, is left and stays registered, beside a dead base swept, and the run's own row still reads pass and met" "this host's /proc names no pid namespace"
fi
is  "a dead base whose own mode was taken down to 0555 is given its bits back and swept, registration included" \
    "$_qswctl" "gone"
is  "a dead base whose tree holds symlinks to a 0444 file and a 0555 directory outside, in a directory left unwritable, is swept, and the file and directory keep their modes and content" \
    "$(_qswgone "$_qswp3" "$T/felix-qualify.DEADP3" "$R" "$Tp/felix-qualify.DEADP3/w") $(_qswmode "$d/outside/file") $(_qswmode "$d/outside/dir") $(_qswmode "$d/outside/dir/inner") $(cat "$d/outside/file" "$d/outside/dir/inner" 2>/dev/null | tr '\n' ' ')" \
    "gone -r--r--r-- dr-xr-xr-x -r--r--r-- kept kept "
_qswleftis "a base with no owner record is left as it was, mode, entries and registration, by the run that swept the dead base beside it" "$d" "$T" "$R" felix-qualify.NOREC1 "$_qswctl"
_qswleftis "a base whose owner is a regular file holding a dead pid, not a symlink, is left as it was, registration included" "$d" "$T" "$R" felix-qualify.FILREC "$_qswctl"
_qswleftis "a base whose record is pid 0 is left as it was, registration included" "$d" "$T" "$R" felix-qualify.PIDZER "$_qswctl"
_qswleftis "a base whose record is a dead pid with a minus sign before it is left as it was, registration included" "$d" "$T" "$R" felix-qualify.NEGPID "$_qswctl"
_qswleftis "a base whose record is letters, not digits, is left as it was, registration included" "$d" "$T" "$R" felix-qualify.NONDIG "$_qswctl"
if [ "$_qswemptyok" = yes ]; then
  _qswleftis "a base whose record is an empty text is left as it was, registration included" "$d" "$T" "$R" felix-qualify.EMPTYR "$_qswctl"
else
  skip "a base whose record is an empty text is left as it was, registration included" "symlink(2) refuses an empty target here"
fi
_qswleftis "a base whose record has two spaces between a dead pid and its start is left as it was, registration included" "$d" "$T" "$R" felix-qualify.TWOSPC "$_qswctl"
_qswleftis "a base whose record is a dead pid and one space with no start after it is left as it was, registration included" "$d" "$T" "$R" felix-qualify.TRLSPC "$_qswctl"
_qswleftis "a base whose record's start holds a tab is left as it was, registration included" "$d" "$T" "$R" felix-qualify.TABSTA "$_qswctl"
_qswleftis "a base whose record's pid begins with a zero is left as it was, registration included" "$d" "$T" "$R" felix-qualify.LEADZR "$_qswctl"
_qswleftis "a base whose record is a dead pid followed by a newline is left as it was, registration included" "$d" "$T" "$R" felix-qualify.NEWLIN "$_qswctl"
_qswleftis "a base with a dead record whose search bit is off, so owner cannot be read, is left as it was, its mode 0600 included" "$d" "$T" "$R" felix-qualify.NOSRCH "$_qswctl"
_qswleftis "a base named tmp. and six characters, as an older engine named them, with a dead record is left as it was" "$d" "$T" "$R" tmp.Ab12Cd "$_qswctl"
_qswleftis "a base named felix-qualify. and five characters, with a dead record, is left as it was" "$d" "$T" "$R" felix-qualify.abcde "$_qswctl"
_qswleftis "a base named felix-qualify. and seven characters, with a dead record, is left as it was" "$d" "$T" "$R" felix-qualify.abcdefg "$_qswctl"
_qswleftis "a base named felix-qualify. and six characters one of which is a dash, with a dead record, is left as it was" "$d" "$T" "$R" felix-qualify.abc-ef "$_qswctl"
_qswleftis "a base named felix-qualify- and six letters, a dash where the dot goes, with a dead record, is left as it was" "$d" "$T" "$R" felix-qualify-abcdef "$_qswctl"
is  "a base that is a symlink to a directory holding a dead record and a registered tree is never followed: the link, its target, the target's mode, record and entries, and the tree's registration are all as they were, beside a dead base the run swept" \
    "beside:$_qswctl now:$(_qswsnap "$T/felix-qualify.SYMLNK" "$R" "$_qswlt") | $(_qswsnap "$d/linktarget" "$R" "$_qswlt")" \
    "beside:gone now:$_qswlinkwas"

# 6. Liveness. A live pid's base is left whether its record has no start or
# its true start; a live pid with another start, and a dead pid with any
# start, are swept; pid 1, which kill -0 may not signal, is left.
d="$QSWS/liveness"; T="$d/t"; mkdir -p "$T"; R="$(_qswroot "$d/root")"; Tp="$(_qswphys "$T")"; _qswtab "$d/proj"
sleep 900 & QSWLIVE=$!
_qswls="$(_qswstart "$QSWLIVE")"; _qswdy="$(_qswdead)"
_qswleft "$d" "$T" "$R" felix-qualify.LIVENO "$QSWLIVE" 0555
_qswleft "$d" "$T" "$R" felix-qualify.LIVETR "$QSWLIVE $_qswls" 0555
# Where /proc names the pid namespace, a record of pid 1 alone would be left
# by the rule that a record naming none is not judged there, before kill -0
# is tried. So there it carries pid 1's start, and what leaves it is kill
# -0's Operation not permitted or, for root, a start that matches.
_qswone=1; [ -n "$(_qswns)" ] && { _qswst1="$(_qswstart 1)"; _qswone="1${_qswst1:+ $_qswst1}"; }
_qswleft "$d" "$T" "$R" felix-qualify.PIDONE "$_qswone" 0555
_qswplant "$T" felix-qualify.LIVEDF "$R" "$QSWLIVE $QSWDIFF"; chmod 0555 "$T/felix-qualify.LIVEDF"
_qswplant "$T" felix-qualify.DEADST "$R" "$_qswdy $_qswls"
_qswp1="$(_qswpre "$T/felix-qualify.DEADST" "$R" "$Tp/felix-qualify.DEADST/w")"
_qswp2="$(_qswpre "$T/felix-qualify.LIVEDF" "$R" "$Tp/felix-qualify.LIVEDF/w")"
_qswrun "$d/run" "$T" "$R" "$d/proj"
_qswctl="$(_qswgone "$_qswp1" "$T/felix-qualify.DEADST" "$R" "$Tp/felix-qualify.DEADST/w")"
is  "a base whose record names a dead pid with a start is swept, registration included" \
    "$_qswctl start:$([ -n "$_qswls" ] && echo known || echo unknown)" "gone start:known"
_qswleftis "a base whose record names a live pid alone, with no start, is left as it was, registration included" "$d" "$T" "$R" felix-qualify.LIVENO "$_qswctl"
_qswleftis "a base whose record names a live pid with that process's true start is left as it was, registration included" "$d" "$T" "$R" felix-qualify.LIVETR "$_qswctl"
_qswleftis "a base whose record names pid 1, which kill -0 may not signal, is left as it was: a failure that is not No such process is a process that exists" "$d" "$T" "$R" felix-qualify.PIDONE "$_qswctl"
is  "a base whose record names a live pid with a start that is not that process's is swept, registration included, and the live process is still running" \
    "$(_qswgone "$_qswp2" "$T/felix-qualify.LIVEDF" "$R" "$Tp/felix-qualify.LIVEDF/w") live:$(_qswalive "$QSWLIVE")" "gone live:yes"

# 6b. Liveness read through a proc filesystem that names a pid namespace,
# as Linux's does, staged here so it runs everywhere: a start is the stat's
# field 22, which a step of the wall clock does not move, then @, the
# namespace, @ and the boot id. The staged namespace is pid:[777] and the
# boot 0b1c2d3e-..., and the live sleep's stat says it started at tick
# 424242, its command's name holding ") ". Every Linux host's first pid
# namespace has the same inode, so the namespace alone tells no host from
# another; the boot does (review round 2). And on such a host a record whose
# start names no namespace, a ps start or none, was written where this
# sweep cannot judge it, and is left.
d="$QSWS/liveness-proc"; T="$d/t"; mkdir -p "$T" "$d/proc/self/ns" "$d/proc/$QSWLIVE" "$d/proc/sys/kernel/random"; R="$(_qswroot "$d/root")"; Tp="$(_qswphys "$T")"
ln -s 'pid:[777]' "$d/proc/self/ns/pid"
_qswbt='0b1c2d3e-4f50-4617-8293-a4b5c6d7e8f9'; printf '%s\n' "$_qswbt" > "$d/proc/sys/kernel/random/boot_id"
{ printf '%s (sl) eep) S' "$QSWLIVE"; for _qswi in 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21; do printf ' 0'; done; printf ' 424242 0 0\n'; } > "$d/proc/$QSWLIVE/stat"
_qswdz="$(_qswdead)"
_qswleft "$d" "$T" "$R" felix-qualify.LXSAME "$QSWLIVE 424242@pid:[777]@$_qswbt" 0555
_qswleft "$d" "$T" "$R" felix-qualify.LXFORN "$_qswdz 424242@pid:[888]@$_qswbt" 0555
_qswleft "$d" "$T" "$R" felix-qualify.LXBOOT "$_qswdz 424242@pid:[777]@ffffffff-0000-4000-8000-000000000000" 0555
_qswleft "$d" "$T" "$R" felix-qualify.LXNOBT "$_qswdz 424242@pid:[777]" 0555
_qswleft "$d" "$T" "$R" felix-qualify.LXPSST "$_qswdz $QSWPS" 0555
_qswleft "$d" "$T" "$R" felix-qualify.LXPIDA "$_qswdz" 0555
_qswleft "$d" "$T" "$R" felix-qualify.LXNOST "$$ 5@pid:[777]@$_qswbt" 0555
_qswplant "$T" felix-qualify.LXDIFF "$R" "$QSWLIVE 1@pid:[777]@$_qswbt"
_qswplant "$T" felix-qualify.LXDEAD "$R" "$_qswdz 424242@pid:[777]@$_qswbt"
_qswp1="$(_qswpre "$T/felix-qualify.LXDEAD" "$R" "$Tp/felix-qualify.LXDEAD/w")"
_qswp2="$(_qswpre "$T/felix-qualify.LXDIFF" "$R" "$Tp/felix-qualify.LXDIFF/w")"
_qswxenv="QSW_PROC=$d/proc"; _qswbg "$d/s" "$T" "$R" - sweep; _qswxenv=""; _qswfinish "$_qswpid" "$d/s"
_qswctl="$(_qswgone "$_qswp1" "$T/felix-qualify.LXDEAD" "$R" "$Tp/felix-qualify.LXDEAD/w")"
is  "with a proc filesystem that names the pid namespace pid:[777] and a boot id, a base whose record names a dead pid with a start in that namespace and boot is swept, registration included" \
    "$_qswctl" "gone"
_qswleftis "with that proc filesystem, a base whose record names a live pid with its stat's field 22, that namespace and that boot is left as it was, whatever ps says of its start" "$d" "$T" "$R" felix-qualify.LXSAME "$_qswctl"
_qswleftis "with that proc filesystem, a base whose record names a dead pid with a start in another namespace, pid:[888], is left as it was: the pid is not this sweep's to read" "$d" "$T" "$R" felix-qualify.LXFORN "$_qswctl"
_qswleftis "with that proc filesystem, a base whose record names a dead pid in that namespace but another boot is left as it was: another host's or another boot's pid is not this sweep's to read" "$d" "$T" "$R" felix-qualify.LXBOOT "$_qswctl"
_qswleftis "with that proc filesystem, a base whose record names a dead pid in that namespace with no boot after it is left as it was" "$d" "$T" "$R" felix-qualify.LXNOBT "$_qswctl"
_qswleftis "with that proc filesystem, a base whose record names a dead pid with a start ps prints, naming no namespace, is left as it was: a host whose /proc names its namespace cannot judge it" "$d" "$T" "$R" felix-qualify.LXPSST "$_qswctl"
_qswleftis "with that proc filesystem, a base whose record names a dead pid alone is left as it was: a host whose /proc names its namespace cannot judge it" "$d" "$T" "$R" felix-qualify.LXPIDA "$_qswctl"
_qswleftis "with that proc filesystem, a base whose record names a live pid that has no stat there to read is left as it was" "$d" "$T" "$R" felix-qualify.LXNOST "$_qswctl"
is  "with that proc filesystem, a base whose record names a live pid with another start in that namespace and boot is swept, registration included, and the live process is still running" \
    "$(_qswgone "$_qswp2" "$T/felix-qualify.LXDIFF" "$R" "$Tp/felix-qualify.LXDIFF/w") live:$(_qswalive "$QSWLIVE")" "gone live:yes"

# 6c. A ps that prints nothing, as a fork that failed under load does: a
# live pid is judged by kill -0 alone, whatever start its record holds.
d="$QSWS/liveness-ps"; T="$d/t"; mkdir -p "$T" "$d/bin"; R="$(_qswroot "$d/root")"; Tp="$(_qswphys "$T")"
printf '#!/bin/sh\nexit 0\n' > "$d/bin/ps"; chmod +x "$d/bin/ps"
_qswleft "$d" "$T" "$R" felix-qualify.PSNOTR "$QSWLIVE $(_qswstart "$QSWLIVE")" 0555
[ -n "$(_qswns)" ] || _qswleft "$d" "$T" "$R" felix-qualify.PSNODF "$QSWLIVE MonJan100:00:002001" 0555
_qswplant "$T" felix-qualify.PSNODE "$R" "$(_qswdead) $QSWOLD"
_qswp1="$(_qswpre "$T/felix-qualify.PSNODE" "$R" "$Tp/felix-qualify.PSNODE/w")"
_qswpath="$d/bin"; _qswbg "$d/s" "$T" "$R" - sweep; _qswpath=""; _qswfinish "$_qswpid" "$d/s"
_qswctl="$(_qswgone "$_qswp1" "$T/felix-qualify.PSNODE" "$R" "$Tp/felix-qualify.PSNODE/w")"
_qswleftis "with a ps on PATH that prints nothing, a base whose record names a live pid with its true start is left as it was" "$d" "$T" "$R" felix-qualify.PSNOTR "$_qswctl"
if [ -n "$(_qswns)" ]; then
  skip "with a ps on PATH that prints nothing, a base whose record names a live pid with a start that is not its own is left as it was: a start that cannot be read now shows no other process" "this host's /proc names its pid namespace, where a record whose start names none is left before kill -0 or ps is asked, so the ps that prints nothing is never reached"
else
  _qswleftis "with a ps on PATH that prints nothing, a base whose record names a live pid with a start that is not its own is left as it was: a start that cannot be read now shows no other process" "$d" "$T" "$R" felix-qualify.PSNODF "$_qswctl"
fi
skip "a record whose kill -0 fails with an empty message, a fork that failed, is alive" "a failed fork cannot be staged here without replacing the kill builtin"
skip "a base in the TMPDIR owned by another user, with a dead record, is never a candidate" "it needs a second user, which the suite does not have"

# 7. Orphans: a registration whose base is gone, and only of the one shape.
d="$QSWS/orphans"; T="$d/t"; mkdir -p "$T"; R="$(_qswroot "$d/root")"; Tp="$(_qswphys "$T")"; _qswtab "$d/proj"
_qswdp="$(_qswphys "$d")"
_qswreggone "$R" "$T/felix-qualify.ORPH01/w"; rm -rf "$T/felix-qualify.ORPH01"
_qswreggone "$R" "$T/other/w"; rm -rf "$T/other"
_qswreggone "$R" "$T/felix-qualify.ORPH02/x"; rm -rf "$T/felix-qualify.ORPH02"
_qswreggone "$R" "$d/elsewhere/felix-qualify.ORPH03/w"; rm -rf "$d/elsewhere/felix-qualify.ORPH03"
_fx_git "$R" worktree add --detach -q "$d/userwt" HEAD >/dev/null 2>&1; printf 'mine\n' > "$d/userwt/uncommitted.txt"
_qswreggone "$R" "$d/gonewt"
_qswreggone "$R" "$T/felix-qualify.ORPH5/w"; rm -rf "$T/felix-qualify.ORPH5"
_qswreggone "$R" "$T/felix-qualify.ORPH04/w"
_qswreggone "$R" "$T/felix-qualify.ORPH06/w"; rm -rf "$T/felix-qualify.ORPH06"; ln -s "$d/nowhere" "$T/felix-qualify.ORPH06"
_qswo1="$(_qswlisted "$R" "$Tp/felix-qualify.ORPH01/w")"
_qswo2="$(_qswlisted "$R" "$Tp/other/w")"
_qswo3="$(_qswlisted "$R" "$Tp/felix-qualify.ORPH02/x")"
_qswo4="$(_qswlisted "$R" "$_qswdp/elsewhere/felix-qualify.ORPH03/w")"
_qswo5="$(_qswlisted "$R" "$_qswdp/userwt")"
_qswo6="$(_qswlisted "$R" "$_qswdp/gonewt")"
_qswo7="$(_qswlisted "$R" "$Tp/felix-qualify.ORPH5/w")"
_qswo8="$(_qswlisted "$R" "$Tp/felix-qualify.ORPH04/w")"
_qswo9="$(_qswlisted "$R" "$Tp/felix-qualify.ORPH06/w")"
_qswrun "$d/run" "$T" "$R" "$d/proj"
_qswoc="$([ "$_qswo1" = yes ] && [ "$(_qswlisted "$R" "$Tp/felix-qualify.ORPH01/w")" = no ] && echo removed || echo "kept(was:$_qswo1)")"
is  "a registration of <T>/felix-qualify.XXXXXX/w whose base is gone is removed by the next run, matched through the TMPDIR's physical path as git records it, and that run's own row still reads pass and met" \
    "orphan:$_qswoc $(_qswverd "$d/run")" "orphan:removed pass met"
is  "a registration of <T>/other/w whose directory is gone stays listed, by the run that removed a felix-qualify orphan beside it" \
    "orphan:$_qswoc was:$_qswo2 listed:$(_qswlisted "$R" "$Tp/other/w")" "orphan:removed was:yes listed:yes"
is  "a registration of <T>/felix-qualify.XXXXXX/x whose base is gone stays listed" \
    "orphan:$_qswoc was:$_qswo3 listed:$(_qswlisted "$R" "$Tp/felix-qualify.ORPH02/x")" "orphan:removed was:yes listed:yes"
is  "a registration of a felix-qualify.XXXXXX/w whose base is gone but lies outside the TMPDIR stays listed" \
    "orphan:$_qswoc was:$_qswo4 listed:$(_qswlisted "$R" "$_qswdp/elsewhere/felix-qualify.ORPH03/w")" "orphan:removed was:yes listed:yes"
is  "a live user worktree stays listed, its uncommitted file intact" \
    "orphan:$_qswoc was:$_qswo5 listed:$(_qswlisted "$R" "$_qswdp/userwt") file:$(cat "$d/userwt/uncommitted.txt" 2>/dev/null || echo gone)" "orphan:removed was:yes listed:yes file:mine"
is  "a prunable worktree elsewhere, not Felix's, stays listed" \
    "orphan:$_qswoc was:$_qswo6 listed:$(_qswlisted "$R" "$_qswdp/gonewt")" "orphan:removed was:yes listed:yes"
is  "a registration of <T>/felix-qualify. and five characters /w whose base is gone stays listed" \
    "orphan:$_qswoc was:$_qswo7 listed:$(_qswlisted "$R" "$Tp/felix-qualify.ORPH5/w")" "orphan:removed was:yes listed:yes"
is  "a registration of <T>/felix-qualify.XXXXXX/w whose base is still there, holding no record, stays listed and the base stays" \
    "orphan:$_qswoc was:$_qswo8 listed:$(_qswlisted "$R" "$Tp/felix-qualify.ORPH04/w") base:$(_qswthere "$T/felix-qualify.ORPH04")" "orphan:removed was:yes listed:yes base:there"
is  "a registration of <T>/felix-qualify.XXXXXX/w whose base is a dangling symlink stays listed and the symlink stays" \
    "orphan:$_qswoc was:$_qswo9 listed:$(_qswlisted "$R" "$Tp/felix-qualify.ORPH06/w") link:$([ -L "$T/felix-qualify.ORPH06" ] && echo there || echo gone)" "orphan:removed was:yes listed:yes link:there"
is  "no git command that run made was a worktree prune or a gc" \
    "orphan:$_qswoc prunes:$(awk '/(^| )(prune|gc)( |$)/ { n++ } END { print n + 0 }' "$d/run/git" 2>/dev/null)" "orphan:removed prunes:0"
d="$QSWS/orphan-link"; mkdir -p "$d/treal"; ln -s "$d/treal" "$d/tlink"; R="$(_qswroot "$d/root")"; _qswtab "$d/proj"
_qswreggone "$R" "$d/treal/felix-qualify.ORPHL1/w"; rm -rf "$d/treal/felix-qualify.ORPHL1"
_qswP="$(_qswphys "$d/treal")/felix-qualify.ORPHL1/w"
_qswwas="$(_qswlisted "$R" "$_qswP")"
_qswrun "$d/run" "$d/tlink/" "$R" "$d/proj"
is  "with TMPDIR a symlink to a directory, given with a trailing slash, a registration of that directory's physical path, felix-qualify.XXXXXX/w, whose base is gone is removed" \
    "before:$_qswwas after:$(_qswlisted "$R" "$_qswP")" "before:yes after:no"
d="$QSWS/notdir"; mkdir -p "$d"; R="$(_qswroot "$d/root")"; _qswtab "$d/proj"
_qswnd="$(_qswphys "$d")/t"
mkdir -p "$_qswnd/felix-qualify.NODIR1"; _fx_git "$R" worktree add --detach -q "$_qswnd/felix-qualify.NODIR1/w" HEAD >/dev/null 2>&1
rm -rf "$_qswnd"
_qswrun "$d/r1" "$_qswnd" "$R" "$d/proj"
_qswwas="$(_qswlisted "$R" "$_qswnd/felix-qualify.NODIR1/w")"
mkdir -p "$_qswnd"
_qswrun "$d/r2" "$_qswnd" "$R" "$d/proj"
is  "a registration of <T>/felix-qualify.XXXXXX/w is left by a run whose TMPDIR, T, is not a directory, and once T is a directory again the next run removes it as an orphan" \
    "t-missing:$_qswwas t-back:$(_qswlisted "$R" "$_qswnd/felix-qualify.NODIR1/w")" "t-missing:yes t-back:no"
if command -v chflags >/dev/null 2>&1; then
  d="$QSWS/stuck-orphan"; T="$d/t"; mkdir -p "$T"; R="$(_qswroot "$d/root")"; Tp="$(_qswphys "$T")"; _qswtab "$d/proj"
  _qswreggone "$R" "$T/felix-qualify.STUCK1/w"; rm -rf "$T/felix-qualify.STUCK1"
  _qswP="$Tp/felix-qualify.STUCK1/w"; _qswadm=""
  for _qswa2 in "$R"/.git/worktrees/*; do
    [ "$(cat "$_qswa2/gitdir" 2>/dev/null)" = "$_qswP/.git" ] && _qswadm="$_qswa2"
  done
  [ -n "$_qswadm" ] && chflags uchg "$_qswadm"
  _qswrun "$d/r1" "$T" "$R" "$d/proj"
  _qswsaid="$(awk -v l="felix: $R still lists the scratch worktree $_qswP, which could not be removed" '$0 == l { n++ } END { print n + 0 }' "$d/r1/err" 2>/dev/null)"
  _qswwas="$(_qswlisted "$R" "$_qswP")"
  [ -n "$_qswadm" ] && chflags nouchg "$_qswadm"
  _qswrun "$d/r2" "$T" "$R" "$d/proj"
  is  "an orphan registration git cannot remove, its admin directory made immutable, stays listed and is said in the drop's own words, felix: <root> still lists the scratch worktree <P>, which could not be removed, and the next run once it can be removes it" \
      "admin:$([ -n "$_qswadm" ] && echo found || echo none) listed:$_qswwas said:$_qswsaid then:$(_qswlisted "$R" "$_qswP")" "admin:found listed:yes said:1 then:no"
  # A dead base whose registration git cannot remove: its drop says so, and
  # the orphan step of the same sweep, finding the base gone, does not again.
  d="$QSWS/stuck-dead"; T="$d/t"; mkdir -p "$T"; R="$(_qswroot "$d/root")"; Tp="$(_qswphys "$T")"
  _qswplant "$T" felix-qualify.STUCK2 "$R" "$(_qswdead) $QSWOLD"
  _qswP="$Tp/felix-qualify.STUCK2/w"; _qswadm=""
  for _qswa2 in "$R"/.git/worktrees/*; do
    [ "$(cat "$_qswa2/gitdir" 2>/dev/null)" = "$_qswP/.git" ] && _qswadm="$_qswa2"
  done
  [ -n "$_qswadm" ] && chflags uchg "$_qswadm"
  _qswbg "$d/s1" "$T" "$R" - sweep; _qswfinish "$_qswpid" "$d/s1"
  _qswsaid="$(awk -v a="felix: $R still lists the scratch worktree " -v z="/felix-qualify.STUCK2/w, which could not be removed" 'index($0, a) == 1 && substr($0, length($0) - length(z) + 1) == z { n++ } END { print n + 0 }' "$d/s1/err" 2>/dev/null)"
  _qswwas="$(_qswlisted "$R" "$_qswP")"
  [ -n "$_qswadm" ] && chflags nouchg "$_qswadm"
  _qswbg "$d/s2" "$T" "$R" - sweep; _qswfinish "$_qswpid" "$d/s2"
  is  "a dead base whose registration git cannot remove, its admin directory made immutable, has its base removed, and the sweep says once, not twice, that the root still lists its tree; once the flag is cleared the next sweep removes the registration" \
      "admin:$([ -n "$_qswadm" ] && echo found || echo none) base:$(_qswthere "$T/felix-qualify.STUCK2") listed:$_qswwas said:$_qswsaid then:$(_qswlisted "$R" "$_qswP")" "admin:found base:gone listed:yes said:1 then:no"
else
  skip "an orphan registration git cannot remove, its admin directory made immutable, stays listed and is said in the drop's own words, felix: <root> still lists the scratch worktree <P>, which could not be removed, and the next run once it can be removes it" "no chflags here"
  skip "a dead base whose registration git cannot remove, its admin directory made immutable, has its base removed, and the sweep says once, not twice, that the root still lists its tree; once the flag is cleared the next sweep removes the registration" "no chflags here"
fi

# 7b. A TMPDIR that cannot be searched while a sweep runs: no base in it can
# be shown absent, so a live row's registration there stays. T is given by
# its physical path, the one git records, since its physical path cannot be
# had while it cannot be searched.
d="$QSWS/nosearch"; mkdir -p "$d/t"; T="$(_qswphys "$d/t")"; R="$(_qswroot "$d/root")"; Tp="$T"
_qswplant "$T" felix-qualify.LIVENS "$R" "$QSWLIVE $(_qswstart "$QSWLIVE")"
_qswwas="$(_qswlisted "$R" "$Tp/felix-qualify.LIVENS/w")"
chmod 0600 "$T"; _qswbg "$d/s" "$T" "$R" - sweep; _qswfinish "$_qswpid" "$d/s"; chmod 0700 "$T"
is  "a sweep run while its TMPDIR has lost its search bit leaves the registration of a live row's base there, and the base, as they were" \
    "live:$(_qswalive "$QSWLIVE") was:$_qswwas registered:$(_qswlisted "$R" "$Tp/felix-qualify.LIVENS/w") base:$(_qswthere "$T/felix-qualify.LIVENS/owner")" \
    "live:yes was:yes registered:yes base:there"

# 7c. A TMPDIR whose name ends in a newline: its physical path keeps the
# newline, so a registration in the directory named without it is not one
# of its orphans.
d="$QSWS/newline"; T="$d/x
"; mkdir -p "$T" "$d/x"; R="$(_qswroot "$d/root")"
_qswreggone "$R" "$d/x/felix-qualify.NLOUT1/w"; rm -rf "$d/x/felix-qualify.NLOUT1"
_qswP="$(_qswphys "$d/x")/felix-qualify.NLOUT1/w"; _qswwas="$(_qswlisted "$R" "$_qswP")"
_qswplant "$T" felix-qualify.NLDEAD - "$(_qswdead) $QSWOLD"
_qswbg "$d/s" "$T" "$R" - sweep; _qswfinish "$_qswpid" "$d/s"
is  "with TMPDIR a directory whose name ends in a newline, a sweep that removes a dead base there leaves the registration of a felix-qualify base gone from the directory of the same name without the newline, outside its TMPDIR" \
    "dead:$(_qswthere "$T/felix-qualify.NLDEAD") was:$_qswwas listed:$(_qswlisted "$R" "$_qswP")" "dead:gone was:yes listed:yes"

# 8. Another repository's dead base in this TMPDIR: gone from disk, and
# this root's own list untouched; that repository's next run removes the
# orphan it is left with.
d="$QSWS/other-repo"; T="$d/t"; mkdir -p "$T"; R="$(_qswroot "$d/root")"; R2="$(_qswroot "$d/root2")"; _qswtab "$d/proj"
_fx_git "$R" worktree add --detach -q "$d/u1" HEAD >/dev/null 2>&1; printf 'mine\n' > "$d/u1/uncommitted.txt"
_qswreggone "$R" "$d/r1gone"
_qswplant "$T" felix-qualify.OTHERX "$R2" "$(_qswdead) $QSWOLD"
_qswwas="$(git -C "$R" worktree list --porcelain 2>/dev/null)"
_qswp1="$(_qswpre "$T/felix-qualify.OTHERX" "$R2" "$(_qswphys "$T")/felix-qualify.OTHERX/w")"
_qswrun "$d/r1" "$T" "$R" "$d/proj"
is  "a dead base in the TMPDIR whose tree another repository registered is removed from disk by a run in this root, and this root's worktree list, a live worktree with uncommitted work and a prunable one, is exactly as it was" \
    "was:$_qswp1 base:$(_qswthere "$T/felix-qualify.OTHERX") list:$([ "$(git -C "$R" worktree list --porcelain 2>/dev/null)" = "$_qswwas" ] && echo same || echo changed) work:$(cat "$d/u1/uncommitted.txt" 2>/dev/null || echo gone)" \
    "was:there,registered base:gone list:same work:mine"
_qswrun "$d/r2" "$T" "$R2" "$d/proj"
is  "and that other repository's own next run in the same TMPDIR removes the registration it was left holding, so it lists only itself" \
    "$(_qswwt "$R2")" "wt:0"

# 9. A dead base whose w was swapped for a symlink to another worktree.
d="$QSWS/w-link"; T="$d/t"; mkdir -p "$T"; R="$(_qswroot "$d/root")"; Tp="$(_qswphys "$T")"; _qswtab "$d/proj"
_fx_git "$R" worktree add --detach -q "$d/other" HEAD >/dev/null 2>&1
_qswO="$(_qswphys "$d/other")"; printf 'mine\n' > "$d/other/uncommitted.txt"
_qswplant "$T" felix-qualify.WLINK1 "$R" "$(_qswdead) $QSWOLD"
mv "$T/felix-qualify.WLINK1/w" "$T/felix-qualify.WLINK1/w.orig"; ln -s "$_qswO" "$T/felix-qualify.WLINK1/w"
_qswp1="$(_qswpre "$T/felix-qualify.WLINK1" "$R" "$Tp/felix-qualify.WLINK1/w")"
_qswrun "$d/run" "$T" "$R" "$d/proj"
is  "a dead base whose w was swapped for a symlink to another worktree of the root is swept, its own registration included, and that other worktree, its uncommitted file and its registration survive" \
    "$(_qswgone "$_qswp1" "$T/felix-qualify.WLINK1" "$R" "$Tp/felix-qualify.WLINK1/w") other:$(cat "$_qswO/uncommitted.txt" 2>/dev/null || echo gone) registered:$(_qswlisted "$R" "$_qswO")" \
    "gone other:mine registered:yes"

# 9b. A dead base swapped for a symlink to another directory while its drop
# runs, between git's remove and the clearing of what is left, as a process
# the dead row left running could: that directory is never followed into.
d="$QSWS/swap"; T="$d/t"; mkdir -p "$T" "$d/decoy/dir"; R="$(_qswroot "$d/root")"
printf 'kept\n' > "$d/decoy/precious.txt"; printf 'kept\n' > "$d/decoy/dir/f"
_qswplant "$T" felix-qualify.SWAP01 "$R" "$(_qswdead) $QSWOLD"
_qswxenv="QSW_GITSWAP=$d/decoy"; _qswbg "$d/s" "$T" "$R" - sweep; _qswxenv=""; _qswfinish "$_qswpid" "$d/s"
is  "a dead base renamed aside and replaced by a symlink to another directory while the sweep's drop runs leaves that directory and everything in it as it was" \
    "swapped:$([ -L "$T/felix-qualify.SWAP01" ] && echo yes || echo no) decoy:[$(cd "$d/decoy" 2>/dev/null && find . -mindepth 1 | LC_ALL=C sort | tr '\n' ' ')]" \
    "swapped:yes decoy:[./dir ./dir/f ./precious.txt ]"
# And when the directory swapped in holds, at w, another worktree of the root
# with uncommitted work, and T is given through a symlink, as macOS's
# default TMPDIR is: git matched the logical path it was given to no
# registration, fell back to resolving it, and removed that other worktree
# (review round 2). The other worktree is added before the dead base's tree
# and after it, so its entry is read before and after the dead base's. And
# the same with the tree itself swapped for a symlink to the other worktree
# just after the drop has looked at it, as git starts.
for _qswo in before after; do
  for _qswk in base tree; do
    case "$_qswk" in base) _qswwhat="the dead base itself" ;; tree) _qswwhat="the dead base's tree" ;; esac
    d="$QSWS/swap-$_qswk-$_qswo"; mkdir -p "$d/t" "$d/decoy"; ln -s "$d/t" "$d/tlink"; T="$d/tlink"; Tp="$(_qswphys "$d/t")"
    R="$(_qswroot "$d/root")"
    [ "$_qswo" = before ] && _fx_git "$R" worktree add --detach -q "$d/decoy/w" HEAD >/dev/null 2>&1
    _qswplant "$T" felix-qualify.SWAPWT "$R" "$(_qswdead) $QSWOLD"
    [ "$_qswo" = after ] && _fx_git "$R" worktree add --detach -q "$d/decoy/w" HEAD >/dev/null 2>&1
    printf 'mine\n' > "$d/decoy/w/uncommitted.txt"; _qswD="$(_qswphys "$d/decoy/w")"
    _qswwas="$(_qswlisted "$R" "$_qswD"),$(_qswlisted "$R" "$Tp/felix-qualify.SWAPWT/w")"
    case "$_qswk" in base) _qswxenv="QSW_GITSWAP=$d/decoy" ;; tree) _qswxenv="QSW_GITSWAPW=$_qswD" ;; esac
    _qswbg "$d/s" "$T" "$R" - sweep; _qswxenv=""; _qswfinish "$_qswpid" "$d/s"
    is  "with T given through a symlink, $_qswwhat swapped for a symlink to a directory holding another worktree of the root, added $_qswo the dead base's tree, as the sweep's drop starts git, leaves that worktree, its uncommitted file and its registration as they were" \
        "planted:$_qswwas swapped:$([ -e "$d/decoy.done" ] || [ -e "$_qswD.done" ] && echo yes || echo no) file:$(cat "$_qswD/uncommitted.txt" 2>/dev/null || echo gone) registered:$(_qswlisted "$R" "$_qswD")" \
        "planted:yes,yes swapped:yes file:mine registered:yes"
  done
done

# 9c. Names in a dead base that lead out of it, as a dead row's mutation
# could leave them: a claim that is a symlink to a directory outside, and an
# entry named as owner's text, a symlink to a directory outside, so owner
# read as a path from the base leads there. Each outside directory holds a
# regular file named claim. The claim's ln was made inside the first
# directory and its rename moved claim into the second, replacing that file,
# at every sweep (review round 2). A claim that is not a record is another
# sweep's or no one's, so that base is left; owner's base is claimed and
# swept like any other, its link to outside removed as a link.
d="$QSWS/follow"; T="$d/t"; mkdir -p "$T" "$d/outa" "$d/outb"; R="$(_qswroot "$d/root")"; Tp="$(_qswphys "$T")"
printf 'precious\n' > "$d/outa/claim"; printf 'precious\n' > "$d/outb/claim"
_qswplant "$T" felix-qualify.FOLLWA "$R" "$(_qswdead) $QSWOLD"; ln -s "$d/outa" "$T/felix-qualify.FOLLWA/claim"
_qswr="$(_qswdead) $QSWOLD"
_qswplant "$T" felix-qualify.FOLLWB "$R" "$_qswr"; ln -s "$d/outb" "$T/felix-qualify.FOLLWB/$_qswr"
mkdir -p "$d/snap"; _qswsnap "$T/felix-qualify.FOLLWA" "$R" "$Tp/felix-qualify.FOLLWA/w" > "$d/snap/a"
_qswp1="$(_qswpre "$T/felix-qualify.FOLLWB" "$R" "$Tp/felix-qualify.FOLLWB/w")"
_qswout() { printf '[%s] claim:%s' "$(ls -A "$1" 2>/dev/null | LC_ALL=C sort | tr '\n' ' ')" \
  "$(if [ -L "$1/claim" ]; then echo link; elif [ -f "$1/claim" ]; then cat "$1/claim"; else echo none; fi)"; }
for _qswi in 1 2; do _qswbg "$d/s$_qswi" "$T" "$R" - sweep; _qswfinish "$_qswpid" "$d/s$_qswi"; done
_qswctl="$(_qswgone "$_qswp1" "$T/felix-qualify.FOLLWB" "$R" "$Tp/felix-qualify.FOLLWB/w")"
is  "a dead base holding an entry named as its owner text, a symlink to a directory outside that holds a regular file named claim, is swept, registration included, and over two sweeps that directory keeps its file and gains nothing" \
    "$_qswctl outside:$(_qswout "$d/outb")" "gone outside:[claim ] claim:precious"
is  "a dead base whose claim is a symlink to a directory outside that holds a regular file named claim is left as it was, claim included, and over two sweeps that directory keeps its file and gains nothing, beside the dead base the sweeps removed" \
    "beside:$_qswctl same:$([ "$(_qswsnap "$T/felix-qualify.FOLLWA" "$R" "$Tp/felix-qualify.FOLLWA/w")" = "$(cat "$d/snap/a")" ] && echo yes || echo no) outside:$(_qswout "$d/outa")" \
    "beside:gone same:yes outside:[claim ] claim:precious"

# 9d. A dead base whose tree the sweep's root does not list: registered in
# another repository, or nowhere. With T given through a symlink, the base
# is swapped for a symlink to a directory whose w is another worktree of the
# sweep's root, with uncommitted work, as the drop first reads the root's
# list. The drop hands git nothing when the root lists no such entry: a path
# it does not list, git resolves, and through that link it removed the other
# worktree (review round 3).
for _qswk in other none; do
  case "$_qswk" in other) _qswwhat="registered in another repository" ;; none) _qswwhat="registered nowhere" ;; esac
  d="$QSWS/unlisted-$_qswk"; mkdir -p "$d/t" "$d/decoy"; ln -s "$d/t" "$d/tlink"; T="$d/tlink"
  R="$(_qswroot "$d/root")"
  if [ "$_qswk" = other ]; then
    R2="$(_qswroot "$d/root2")"
    _qswplant "$T" felix-qualify.UNLIST "$R2" "$(_qswdead) $QSWOLD"
    _qswwas="$(_qswlisted "$R2" "$(_qswphys "$d/t")/felix-qualify.UNLIST/w")"
  else
    _qswplant "$T" felix-qualify.UNLIST - "$(_qswdead) $QSWOLD"
    mkdir "$T/felix-qualify.UNLIST/w" && printf 'x\n' > "$T/felix-qualify.UNLIST/w/f" && _qswwas=no
  fi
  _fx_git "$R" worktree add --detach -q "$d/decoy/w" HEAD >/dev/null 2>&1
  printf 'mine\n' > "$d/decoy/w/uncommitted.txt"; _qswD="$(_qswphys "$d/decoy/w")"
  _qswwas="$_qswwas,$(_qswlisted "$R" "$_qswD")"
  _qswxenv="QSW_GITSWAPL=$d/decoy"; _qswbg "$d/s" "$T" "$R" - sweep; _qswxenv=""; _qswfinish "$_qswpid" "$d/s"
  is  "with T given through a symlink, a dead base whose tree is $_qswwhat, swapped for a symlink to a directory whose w is another worktree of the sweep's root as the drop first reads the root's list, has no worktree remove made for it, and that worktree, its uncommitted file and its registration are as they were" \
      "planted:$_qswwas swapped:$([ -e "$d/decoy.done" ] && echo yes || echo no) removes:$(awk '/ worktree remove / && /felix-qualify\.UNLIST/ { n++ } END { print n + 0 }' "$d/s/git" 2>/dev/null) file:$(cat "$_qswD/uncommitted.txt" 2>/dev/null || echo gone) registered:$(_qswlisted "$R" "$_qswD")" \
      "planted:$([ "$_qswk" = other ] && echo yes || echo no),yes swapped:yes removes:0 file:mine registered:yes"
done

# 9e. A row whose mutation swaps its own base for a symlink to a directory
# outside that holds a file named err, the name of the column stderr file
# beside the tree. The runner removed that file once the column had run,
# by the base's name, which led outside by then (review round 3).
d="$QSWS/errswap"; T="$d/t"; mkdir -p "$T" "$d/outside" "$d/proj"; R="$(_qswroot "$d/root")"
printf 'precious\n' > "$d/outside/err"; printf 'other\n' > "$d/outside/keep"
_qsw5 errswap 'test -f base.txt' restoration pass "b=\"\$(cd .. && pwd -P)\"; mv \"\$b\" \"\$b.aside\" && ln -s '$d/outside' \"\$b\"" > "$d/proj/qualification.tsv"
_qswrun "$d/r" "$T" "$R" "$d/proj"
is  "a row whose mutation swaps its own base for a symlink to a directory outside holding a file named err leaves that directory's files as they were" \
    "swapped:$(ls -A "$T" 2>/dev/null | awk '/^felix-qualify\.[A-Za-z0-9]+\.aside$/ { n++ } END { print n + 0 }') outside:[$(ls -A "$d/outside" 2>/dev/null | LC_ALL=C sort | tr '\n' ' ')] err:$(cat "$d/outside/err" 2>/dev/null || echo gone)" \
    "swapped:1 outside:[err keep ] err:precious"

_qualify_sweep_cleanup
