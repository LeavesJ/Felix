_autonomy_revoke_vars
_autonomy_lock_build
# F3. With stdout closed, bash 3.2 kept a "revoked:" it could not print in
# its buffer, and the next command substitution or subshell flushed it into
# what it captured or wrote. A revoke of tidy with an allow of commission
# then left an autonomy.new.* and refused the allow; with no grant file, a
# revoke and allow of tidy wrote "revoked: tidy" into the new one; an allow
# of commission alone wrote no stamp. Revision 3 sends a closed stdout to
# /dev/null before anything prints. Measured red on bash 3.2 (macOS). bash 4
# and later purge that buffer in a command substitution's child, so on 5.2
# some of these may pass against a068acb3 as well.
_lwshut() {   # FORMAT|none ARGS...: felix autonomy ARGS, stdout closed, over FORMAT (none: no grant file and no stamp); sets _lwrc
  if [ "$1" = none ]; then _lwclear; else _lwset "$1"; fi
  shift
  ( cd "$REPO" && exec "$FELIX" autonomy "$@" ) >&- 2> "$TMP/lw.err" 8>&- &
  _lwreap $!
}
_lwpage() {   # the commission row of the status page: [x] stamped over this table, [!] granted but not, [ ] not granted
  ( cd "$REPO" && exec "$FELIX" autonomy ) 2>/dev/null 8>&- | sed -n 's/^ *\(\[.\]\) commission .*/\1/p'
}
_lwshut 'tidy\n' --revoke tidy --allow commission 2>/dev/null
is "a revoke of tidy with an allow of commission, stdout closed, exits 0 and leaves no lock and no autonomy.new.*" \
   "$(_lwexit "$_lwrc"):$(_lwlock):$(_lwnew)" "exit 0:absent:0"
is "and that run leaves tidy not granted, and commission granted and stamped over this table: the status page says [x]" \
   "tidy $(_lwallows tidy):commission $(_lwallows commission):$(_lwpage)" "tidy no:commission yes:[x]"
_lwshut none --revoke tidy --allow tidy 2>/dev/null
is "with no grant file, a revoke of tidy with an allow of tidy, stdout closed, exits 0 and leaves no lock and no autonomy.new.*" \
   "$(_lwexit "$_lwrc"):$(_lwlock):$(_lwnew)" "exit 0:absent:0"
is "and the grant file that run writes grants tidy and holds no revoked: line" \
   "$(_lwallows tidy):$(grep -c 'revoked:' "$_lwp/autonomy" 2>/dev/null)" "yes:0"
_lwshut 'tidy\n' --allow commission 2>/dev/null
is "an allow of commission, stdout closed, exits 0, leaves no lock and no autonomy.new.*, and stamps it: the status page says [x]" \
   "$(_lwexit "$_lwrc"):$(_lwlock):$(_lwnew):$(_lwpage)" "exit 0:absent:0:[x]"

# A stdout that is open but refuses every write did the same as a closed one,
# and worse: revision 3 sent only a closed stdout to /dev/null first. The
# failed "revoked:" went into the grant's byte count, set -u stopped the
# grant's subshell, bash 3.2 ended it with status 0, and an empty file
# replaced the grants (the lock's third review, not blind). Revision 4 prints
# each of those lines in a child. A read-only stdout stands for every way a
# write fails; red on bash 3.2.
: > "$TMP/lw-ro"
_lwro() {   # FORMAT ARGS...: felix autonomy ARGS over FORMAT, stdout open read-only; sets _lwrc
  _lwset "$1"; shift
  ( cd "$REPO" && exec "$FELIX" autonomy "$@" ) 1< "$TMP/lw-ro" 2> "$TMP/lw.err" 8>&- &
  _lwreap $!
}
_lwro '# grants\ntidy\nsomething-else\n' --revoke tidy --allow commission
is "a revoke of tidy with an allow of commission, stdout open read-only, exits 0 and leaves no lock and no autonomy.new.* (not blind)" \
   "$(_lwexit "$_lwrc"):$(_lwlock):$(_lwnew)" "exit 0:absent:0"
is "and that run keeps the grant file's other lines, leaves tidy not granted, and grants commission, stamped over this table with nothing else in the stamp (not blind)" \
   "$(grep -cx '# grants' "$_lwp/autonomy" 2>/dev/null):$(grep -cx 'something-else' "$_lwp/autonomy" 2>/dev/null):tidy $(_lwallows tidy):commission $(_lwallows commission):$(_lwpage):$(grep -c 'revoked\|allowed' "$_lwp/autonomy.commission" 2>/dev/null)" \
   "1:1:tidy no:commission yes:[x]:0"
_lwro 'commission\n' --allow commission
is "an allow of commission already granted, stdout open read-only, exits 0 and stamps it over this table with nothing else in the stamp (not blind)" \
   "$(_lwexit "$_lwrc"):$(_lwlock):$(_lwpage):$(grep -c 'allowed' "$_lwp/autonomy.commission" 2>/dev/null)" "exit 0:absent:[x]:0"

# The grant's subshell ended 0 when set -u stopped it, on bash 3.2, and 0 was
# "written": the empty temp file then replaced the grants. Revision 4 gave
# written a status of its own. That was not enough (revoke's fifth review): a
# stop in $(( )) leaves the status of the command before it, so a wc that
# answered a word and exited 10 read as written too. Revision 5 checks wc's
# answer as digits and never puts it through $(( )). A wc first on the run's
# PATH that prints a word stands for anything that answers one: exiting 0,
# and exiting 10. bash 5.2 ends a stopped subshell non-zero, so the first is
# red on bash 3.2 only; the second is red on both.
mkdir -p "$TMP/lw-wc"
for _lwws in 0 10; do
  printf '#!/bin/sh\necho stray\nexit %s\n' "$_lwws" > "$TMP/lw-wc/wc"; chmod +x "$TMP/lw-wc/wc"
  _lwset '# grants\ntidy\n'; _lwheld="$(_lwstate)"
  ( cd "$REPO" && PATH="$TMP/lw-wc:$PATH" exec "$FELIX" autonomy --allow commission ) > "$TMP/lw.out" 2> "$TMP/lw.err" 8>&- &
  _lwreap $!; _lwout="$(cat "$TMP/lw.out")"; _lwerr="$(cat "$TMP/lw.err")"
  is "an allow of commission whose wc answers a word and exits $_lwws exits non-zero, says commission is not allowed and no allowed:, and leaves the widget's files as they were, no lock and no autonomy.new.* (not blind)" \
     "$(_lwexit "$_lwrc"):$(_lwsaid "$_lwout"):$(_lwhas "$_lwerr" 'commission is not allowed'):$(_lwsame):$(_lwlock):$(_lwnew)" \
     "non-zero:silent:commission is not allowed:same:absent:0"
done

# A caller of the library that printed to a dead stdout before the grant
# left the text in bash 3.2's buffer, and the grant's first child took it:
# the mktemp substitution made it part of the temp file's name, and the grant
# refused. Revision 5 flushes the buffer to /dev/null first, as revoke does
# (revoke's sixth review). A failed printf of "tidy" stands for any; the
# grant asked for is commission, and tidy must not come with it. Red on bash
# 3.2 only: later bash purges that buffer in a child.
_lwset '# grants\n'; rm -f "$_lwp/autonomy.commission"
bash -c 'set -uo pipefail; . "$1/harness/lib/autonomy.sh"; printf "tidy\n"; felix_autonomy_grant "$2" commission; echo "rc=$?" >&2' \
  _ "$FROOT" "$_lwp" >&- 2> "$TMP/lw.err" 8>&-
is "a grant called after a printf of tidy failed on a closed stdout grants commission, and tidy does not come with it (not blind)" \
   "$(grep -o 'rc=[0-9]*' "$TMP/lw.err"):tidy $(_lwallows tidy):commission $(_lwallows commission):$(_lwnew)" "rc=0:tidy no:commission yes:0"

# F5. The release removes the lock through find, and said nothing when find
# could not do it; the lock stayed and the next run was refused. Revision 3
# says so. A find first on the run's PATH that fails stands for any find
# that cannot run. A held lock a person makes unreadable is the other way in,
# skipped where this suite can read a directory of mode 000 anyway (root).
# Measured with macOS's find, which skips an unreadable starting directory
# and exits non-zero; GNU find reports one and exits non-zero too (not run
# here).
mkdir -p "$TMP/lw-nofind"; printf '#!/bin/sh\nexit 1\n' > "$TMP/lw-nofind/find"; chmod +x "$TMP/lw-nofind/find"
_lwset 'tidy\ncommission\n'
( cd "$REPO" && PATH="$TMP/lw-nofind:$PATH" exec "$FELIX" autonomy --revoke commission ) > "$TMP/lw.out" 2> "$TMP/lw.err" 8>&- &
_lwreap $!; _lwout="$(cat "$TMP/lw.out")"; _lwerr="$(cat "$TMP/lw.err")"
is "a revoke of commission whose release cannot run find still revokes, and its stderr names the lock and says it may not have been removed" \
   "$(_lwexit "$_lwrc"):$(_lwrv "$_lwout"):$(_lwallows commission):$(_lwhas "$_lwerr" 'projects/widget/autonomy.lock'):$(_lwhas "$_lwerr" 'may not have been removed')" \
   "exit 0:said:no:projects/widget/autonomy.lock:may not have been removed"
_lwn1="a revoke whose lock a person made unreadable while its mv was paused leaves that lock, and its stderr names the lock and says it may not have been removed"
mkdir -p "$TMP/lw-shut"; chmod 000 "$TMP/lw-shut"
if ls "$TMP/lw-shut" > /dev/null 2>&1; then _lwroot=yes; else _lwroot=no; fi
chmod 755 "$TMP/lw-shut"; rmdir "$TMP/lw-shut"
if [ "$_lwroot" = yes ]; then skip "$_lwn1" "this suite can read a directory of mode 000 here (root)"
else
  _lwset 'tidy\ncommission\n'; _lwmode0=unreached
  _lwgo --revoke commission
  if [ "$_lwreached" = yes ]; then chmod 000 "$_lwL" && _lwmode0=unreadable || _lwmode0=failed; fi
  _lwend 2>/dev/null
  _lwreq "$_lwn1" \
         "$_lwmode0:$([ -d "$_lwL" ] && echo left || echo gone):$(_lwhas "$_lwaerr" 'projects/widget/autonomy.lock'):$(_lwhas "$_lwaerr" 'may not have been removed')" \
         "unreadable:left:projects/widget/autonomy.lock:may not have been removed"
  chmod 755 "$_lwL" 2>/dev/null
fi

# S1. On Linux a freed inode number can come straight back, so a lock a
# person rmdir'd and another run made again could carry the first run's
# inode, and the first run's release, which goes by inode, would take it.
# Revision 3 keeps the lock directory open (on fd 9, and since revision 4 on
# the first of fds 9 to 3 the run did not inherit) until it has removed it,
# and an open directory's inode is not freed. APFS never reuses an inode
# number, so on macOS the second assertion passes against a068acb3 too (not
# run on Linux here); the first, the open descriptor, read through /proc or lsof, is
# red against it everywhere.
_lwfdheld() {   # PID INODE: held when PID holds INODE open on any fd; none; or unreadable when neither /proc nor lsof is here
  if [ -d "/proc/$1/fd" ]; then
    for _lwfp in /proc/"$1"/fd/*; do [ "$(stat -L -c %i "$_lwfp" 2>/dev/null)" = "$2" ] && { echo held; return; }; done
    echo none
  elif command -v lsof > /dev/null 2>&1; then
    _lwfi="$(lsof -a -p "$1" -Fi 2>/dev/null | sed -n 's/^i//p')"
    [ "$(printf '%s\n' "$_lwfi" | grep -cx "$2")" -gt 0 ] && echo held || echo none
  else echo unreadable; fi
}
_lwn1="a revoke paused in its mv holds its lock directory open"
_lwset 'tidy\ncommission\n'; _lwfd=unreached
_lwgo --revoke commission
if [ "$_lwreached" = yes ]; then
  _lwlino="$(stat -c %i "$_lwL" 2>/dev/null || stat -f %i "$_lwL" 2>/dev/null)"
  _lwfd="$(_lwfdheld "$_lwa" "$_lwlino")"
fi
_lwend
if [ "$_lwfd" = unreadable ]; then skip "$_lwn1" "neither /proc nor lsof can read another process's descriptors here"
else _lwreq "$_lwn1" "$_lwfd" "held"; fi
_lwset 'tidy\ncommission\n'; _lwswap=unreached
_lwgo --revoke commission
if [ "$_lwreached" = yes ]; then _lwswap=failed; rmdir "$_lwL" && mkdir "$_lwL" && _lwswap=remade; fi
_lwend
_lwreq "a revoke whose lock a person rmdir'd and another made again at the same path while its mv was paused leaves the new lock in place, still empty" \
       "$_lwswap:$(_lwlock)" "remade:empty"

# Revision 3 took fd 9 whatever it held, so a caller's flock on fd 9 (flock's
# own example) was let go the moment the lock was made (the lock's third
# review, not blind). Revision 4 keeps the lock open on the first of fds 9 to
# 3 it did not inherit. Built at the library, where the descriptors can be
# read: /dev/fd/N is the open file, followed.
: > "$TMP/lw-fd9"
_lwset 'tidy\n'
_lwkept="$(bash -c 'set -uo pipefail; . "$1/harness/lib/autonomy.sh"
  i() { stat -L -c %i "$1" 2>/dev/null || stat -L -f %i "$1" 2>/dev/null; }
  felix_autonomy_guard "$2" || exit 7
  f="${_felix_autonomy_lock_fd:-}"
  if [ "$(i /dev/fd/9)" = "$(i "$3")" ]; then printf kept; else printf taken; fi
  if [ -n "$f" ] && [ "$f" != 9 ] && [ "$(i "/dev/fd/$f")" = "$(i "$2/autonomy.lock")" ]; then printf :held; else printf ":not held (${f:-none})"; fi
  _felix_autonomy_release
  if [ "$(i /dev/fd/9)" = "$(i "$3")" ]; then printf :kept; else printf :taken; fi
  ' _ "$FROOT" "$_lwp" "$TMP/lw-fd9" 9< "$TMP/lw-fd9" 8>&- 2>/dev/null)"
is "a run whose caller holds fd 9 open keeps it, holds its lock open on another fd, and still holds the caller's fd 9 once it has released (not blind)" \
   "$_lwkept:$(_lwlock)" "kept:held:kept:absent"

# The signal lists were split by the caller's IFS. A library caller whose IFS
# held no space ('2', the digits, a tab) got the lock with no trap set, so a
# signal mid-mv released it at once (from revoke's seventh review, which
# found an unquoted $(( )) under such an IFS; not blind). Each split now sets
# IFS to a space itself. felix's own runs cannot carry one: bash ignores an
# IFS in the environment.
for _lwifs in 2 0123456789 tab; do
  _lwset 'tidy\n'
  _lwtr="$(bash -c '. "$1/harness/lib/autonomy.sh"
    if [ "$3" = tab ]; then IFS="	"; else IFS="$3"; fi
    felix_autonomy_guard "$2" || exit 7
    case "$(trap -p TERM)" in *_felix_autonomy_signalled*) printf TERM ;; *) printf "no TERM" ;; esac
    case "$(trap -p SEGV)" in *_felix_autonomy_signalled*) printf :SEGV ;; *) printf ":no SEGV" ;; esac
    ' _ "$FROOT" "$_lwp" "$_lwifs" 8>&- 2>/dev/null)"
  is "a guard taken under a caller's IFS of $_lwifs sets its TERM and SEGV traps, and releases the lock at exit (not blind)" \
     "$_lwtr:$(_lwlock)" "TERM:SEGV:absent"
done

# F4. mktemp ran with the signals at their defaults, so a Ctrl-C to the group
# between its making the file and the name reaching the shell left the file.
# The real gap is microseconds. A mktemp shim, first on run A's PATH, makes it
# wide: it runs the real mktemp, then waits on this block's FIFO before it
# prints the name. Revision 3 runs mktemp with the signals ignored, so the
# shim outlives the INT and the run removes the file. Last here, because the
# shim pauses before the mv shim does; it is removed straight after.
_lwmkt="$(command -v mktemp)"
{ printf '#!/bin/sh\n_d=%s\n_m=%s\n' "'$_lwsh'" "'$_lwmkt'"
  cat <<'EOF'
_n="$("$_m" "$@")" || exit 1
case "$_n" in
  */projects/widget/autonomy.new.*)
    if [ -e "$_d/armed" ] && /bin/rm "$_d/armed" 2>/dev/null; then
      echo "$$" > "$_d/reached"
      read -r _line < "$_d/release"
    fi ;;
esac
printf '%s\n' "$_n"
EOF
} > "$_lwsh/mktemp"; chmod +x "$_lwsh/mktemp"
_lwn1="a revoke of commission paused in mktemp, its temp file made and not yet named, and sent INT to its process group, exits non-zero, says nothing, and leaves no lock, no autonomy.new.* and the widget's files as they were"
_lwn2="an allow of tidy paused in mktemp the same way and sent INT to its process group exits non-zero, says nothing, and leaves no lock, no autonomy.new.* and the widget's files as they were"
if [ "$(_lwprobe INT)" != yes ]; then skip "$_lwn1" "$(_lwign INT)"; skip "$_lwn2" "$(_lwign INT)"
else
  for _lwv in revoke allow; do
    if [ "$_lwv" = revoke ]; then _lwset 'tidy\ncommission\n'; _lwn="$_lwn1"; else _lwset 'commission\n'; _lwn="$_lwn2"; fi
    _lwheld="$(_lwstate)"
    if [ "$_lwv" = revoke ]; then _lwgo --revoke commission; else _lwgo --allow tidy; fi
    [ "$_lwreached" = yes ] && kill -INT -- "-$_lwa" 2>/dev/null
    _lwend
    _lwreq "$_lwn" "$(_lwexit "$_lwarc"):$(_lwsaid "$_lwaout$_lwaerr"):$(_lwlock):$(_lwnew):$(_lwsame)" "non-zero:silent:absent:0:same"
  done 2>/dev/null
fi
rm -f "$_lwsh/mktemp"

exec 8>&-
_lwclear; rm -rf "$_lwsh" "$TMP/lw-nofind"
rm -f "$TMP/lw.out" "$TMP/lw.err" "$TMP/lw-a.out" "$TMP/lw-a.err" "$TMP/lw-b.out" "$TMP/lw-b.err" "$TMP/lw-pipe"
for _lwf in "$_lwk"/autonomy*; do { [ -e "$_lwf" ] || [ -L "$_lwf" ]; } && mv "$_lwf" "$_lwp/"; done
rmdir "$_lwk" 2>/dev/null
is "the widget's directory holds exactly what it held before the lock was tested under signals and a person's hand" \
   "$(ls -A "$_lwp" | LC_ALL=C sort)" "$_lwstart"

printf '\nrevoke then allow on a last line with no newline\n'
# 2026-10-08: the third review found that a revoke keeping an unended last line,
# followed by an --allow that appended without ending it, glued the new grant
# onto the old one: '# h\ntidy\ncommission' revoked of tidy and then allowed
# tidy read 'commissiontidy', and the CLI still said "allowed: tidy". Revoke
# keeps every byte it does not remove, so the unended line stays unended, and
# --allow must end it before it appends. --allow is fixed by another change
# (felix_end_line, slot .274), so this block is red on this branch until that
# lands, and green on main, where revoke always wrote a final newline.
RV5K="$TMP/revoke-keep-5"; mkdir -p "$RV5K"
_r5start="$(ls -A "$RVP" | LC_ALL=C sort)"
for _rvf in "$RVP"/autonomy*; do [ -e "$_rvf" ] && mv "$_rvf" "$RV5K/"; done
_r5bytes() { od -An -c "$RVP/autonomy" | tr -s ' \n' ' '; }   # the grant file's bytes, spelled out

# F1: revoke tidy, then allow tidy, on '# h\ntidy\ncommission' with no final newline.
_rvset '# h\ntidy\ncommission'; _rwcli --revoke tidy
is "a revoke of tidy from a file whose last line commission is unended exits 0 and says revoked: tidy" \
   "$_rvrc:$(_rwsaid 'revoked: tidy')" "0:said"
printf '# h\ncommission' > "$TMP/rw.want"
is "and the file is then '# h' and commission, still unended" "$(_rwis)" "same"
_rwcli --allow tidy
is "then an --allow of tidy exits 0 and says allowed: tidy" "$_rvrc:$(_rwsaid 'allowed: tidy')" "0:said"
printf '# h\ncommission\ntidy\n' > "$TMP/rw.want"
is "and the file is then exactly '# h', commission and tidy, each on its own ended line" \
   "$(_rwis):$(_r5bytes)" "same:$(od -An -c "$TMP/rw.want" | tr -s ' \n' ' ')"
_rwuis "and tidy and commission both read as granted under C and under UTF-8" \
   "$(_rwboth tidy):$(_rwboth commission)" "yes:yes:yes:yes"

# F1, mirrored: revoke commission, then allow commission, on '# h\ncommission\ntidy'.
_rvset '# h\ncommission\ntidy'; _rwcli --revoke commission
is "a revoke of commission from a file whose last line tidy is unended exits 0 and says revoked: commission" \
   "$_rvrc:$(_rwsaid 'revoked: commission')" "0:said"
printf '# h\ntidy' > "$TMP/rw.want"
is "and the file is then '# h' and tidy, still unended" "$(_rwis)" "same"
_rwcli --allow commission
is "then an --allow of commission exits 0 and says allowed: commission" \
   "$_rvrc:$(_rwsaid 'allowed: commission')" "0:said"
printf '# h\ntidy\ncommission\n' > "$TMP/rw.want"
is "and the file is then exactly '# h', tidy and commission, each on its own ended line" \
   "$(_rwis):$(_r5bytes)" "same:$(od -An -c "$TMP/rw.want" | tr -s ' \n' ' ')"
_rwuis "and commission and tidy both read as granted under C and under UTF-8 after the re-arm" \
   "$(_rwboth commission):$(_rwboth tidy)" "yes:yes:yes:yes"

rm -f "$RVP"/autonomy* "$TMP/rw.want"
for _rvf in "$RV5K"/autonomy*; do [ -e "$_rvf" ] && mv "$_rvf" "$RVP/"; done
rmdir "$RV5K" 2>/dev/null
is "the widget's directory holds exactly what it held before revoke then allow was tested" \
   "$(ls -A "$RVP" | LC_ALL=C sort)" "$_r5start"

printf '\nrevoke refuses what it could not read or write, and stays linear in a long line\n'
# 2026-10-08: a fourth review of the revoke fix found mutants the blocks above
# let through. Upper-case letters beside the capability were not pinned as
# letters, so a names rule that looked only for lower case could take TIDYtidy
# for a tidy grant. A line read that fails was not pinned to a refusal, so a
# loop that stopped at its first failed read could say there was nothing to
# remove. A write that fails on the file's last line was not pinned, so a
# rewrite that checked every write but the last could rename a cut-short file
# into place. The refused rename was pinned only through chflags, which Linux
# does not have, so CI never ran it. The here-string cases ran over a file of
# about 3 KB, which bash 5.1 and later send through a pipe rather than a
# temporary file, so they could not fail on CI. And the revoke was linear in
# the number of lines but not in the length of one: a single line of half a
# megabyte took it seconds. These pin each of those, the long-line cases in
# CPU, as E3 does.
RV6K="$TMP/revoke-keep-6"; mkdir -p "$RV6K"
_r6start="$(ls -A "$RVP" | LC_ALL=C sort)"
for _rvf in "$RVP"/autonomy*; do [ -e "$_rvf" ] && mv "$_rvf" "$RV6K/"; done
_r6held() { cp "$RVP/autonomy" "$TMP/rv.held"; _rvbefore="$(_rvrest)"; }   # record the file and the directory
_r6new() { [ "$(_rvrest)" = "$_rvbefore" ] && echo nothing-new || echo left-behind; }
_r6xs() { head -c "$1" /dev/zero | LC_ALL=C tr '\0' "$2"; }   # N BYTE: N copies of BYTE, no loop
_r6cpu() {   # CAP: revoke CAP from the widget's file in a fresh bash under a CPU limit -> 'returned N:within'
  _r6t="$( ( ulimit -t 12; LC_ALL=C "$BASH" -c '. "$1/harness/lib/autonomy.sh"
             felix_autonomy_revoke "$2" "$3" >/dev/null 2>&1; echo "returned $?"; times' _ "$FROOT" "$RVP" "$1" ) 2>/dev/null )"
  printf '%s\n' "$_r6t" | LC_ALL=C awk 'NR == 1 { a = $0; next }
      { for (i = 1; i <= NF; i++) { split($i, p, "m"); sub(/s$/, "", p[2]); t += p[1] * 60 + p[2] } }
      END { if (NR < 3) print "killed"; else printf "%s:%s\n", a, (t <= 6 ? "within" : "over " t) }'
}

# G1: an upper-case letter beside the capability is a letter.
_rvset '# h\nTIDYtidy\ntidyX\nZtidy\ntidy\n'; _rwloc C tidy
printf '# h\nTIDYtidy\ntidyX\nZtidy\n' > "$TMP/rw.want"
is "a revoke of tidy keeps TIDYtidy, tidyX and Ztidy byte for byte and removes the tidy line" \
   "$_rvrc:$(_rwis)" "0:same"

# G2: a revoke whose line reads fail is a refusal. The whole-file read with -d
# still works, and every other read fails.
_r6g2() {   # run felix_autonomy_revoke tidy with every read but read -d failing -> 'returned N'
  "$BASH" -c '. "$1/harness/lib/autonomy.sh"
    read() { local a; for a; do [ "$a" != -d ] || { builtin read "$@"; return; }; done; return 1; }
    felix_autonomy_revoke "$2" tidy >/dev/null 2>&1; echo "returned $?"' _ "$FROOT" "$RVP" 2>/dev/null
}
_rvset '# h\ntidy\n'; _r6held
is "a revoke of tidy whose line reads fail returns 1" "$(_r6g2)" "returned 1"
is "and the revoke whose line reads fail leaves the tidy grant file byte-identical and nothing new behind" \
   "$(_r3cmp "$TMP/rv.held" "$RVP/autonomy"):$(_r6new)" "same:nothing-new"
_rvset '# h\ntidy\302\240\n'; _r6held
is "a revoke of tidy whose line reads fail over a line only older engines grant returns 1" "$(_r6g2)" "returned 1"
is "and that refused revoke keeps the older engines' grant line, byte-identical" \
   "$(_r3cmp "$TMP/rv.held" "$RVP/autonomy"):$(_r6new)" "same:nothing-new"

# G3: a write that fails on the file's last line. The only kept line is one
# comment of about 2.9 KB, and it crosses the two-block limit.
rm -f "$RVP"/autonomy*
{ printf 'tidy\n# '; _r6xs 2900 x; printf '\n'; } > "$RVP/autonomy"
printf 'stamp\n' > "$RVP/autonomy.commission"; _r6held; _r4cut tidy
is "under a two-block file-size limit a revoke of tidy whose one kept line crosses the limit exits non-zero and says nothing revoked" \
   "$(_rwexit):$(_rwsaid revoked:)" "refused:silent"
is "and the revoke cut short on its last line leaves the grant file byte-identical and nothing new behind" \
   "$(_r3cmp "$TMP/rv.held" "$RVP/autonomy"):$(_r6new)" "same:nothing-new"

# G4: a refused rename, on any system. A mv first in PATH refuses any move
# onto a path ending in /autonomy and passes every other through.
_r6bin="$TMP/r6.bin"; mkdir -p "$_r6bin"
printf '%s\n' '#!/bin/sh' 'for _a in "$@"; do _l="$_a"; done' \
  'case "${_l:-}" in */autonomy) exit 1 ;; esac' 'exec /bin/mv "$@"' > "$_r6bin/mv"
chmod 755 "$_r6bin/mv"
_rvset '# h\ntidy\ncommission\n'; _r6held
( export PATH="$_r6bin:$PATH"; cd "$REPO" && "$FELIX" autonomy --revoke commission ) > "$TMP/rv.out" 2> "$TMP/rv.err"
_rvrc=$?; _rvout="$(cat "$TMP/rv.out")"; _rverr="$(cat "$TMP/rv.err")"
rm -rf "$_r6bin"
is "a revoke of commission whose rename onto the grant file is refused by mv exits non-zero and says nothing revoked" \
   "$(_rwexit):$(_rwsaid revoked:)" "refused:silent"
is "and the rename refused by mv is not blamed on another writer" \
   "$(_r3has "$_rvout$_rverr" 'another writer' claimed honest)" "honest"
is "and the rename refused by mv leaves the grant file byte-identical and the stamp in place" \
   "$(_r3cmp "$TMP/rv.held" "$RVP/autonomy"):$(_rvstamp)" "same:kept"
is "and the rename refused by mv leaves nothing new in the project directory" "$(_r6new)" "nothing-new"

# G5: E1b and E1c over a file of about 80 KB, past any pipe buffer, so the
# shell cannot hand a here-string of it through a pipe.
_r6big() {   # LAST: '# h', 1000 comment lines of about 80 bytes, then LAST as printf writes it, beside a stamp
  rm -f "$RVP"/autonomy*; _r6i=0
  { printf '# h\n'
    while [ "$_r6i" -lt 1000 ]; do
      printf '# kept line %04d, one of a thousand that carry this file past any pipe buffer\n' "$_r6i"
      _r6i=$((_r6i+1))
    done
    printf "$1\\n"; } > "$RVP/autonomy"
  printf 'stamp\n' > "$RVP/autonomy.commission"; _r6held
}
_r6big 'tidy\302\240'; _r4cut tidy
is "under a two-block file-size limit a revoke of tidy over an 80 KB file ending in a no-break-space line exits non-zero and says nothing revoked" \
   "$(_rwexit):$(_rwsaid revoked:)" "refused:silent"
is "and the refused revoke of the 80 KB file leaves it byte-identical and nothing new behind" \
   "$(_r3cmp "$TMP/rv.held" "$RVP/autonomy"):$(_r6new)" "same:nothing-new"
_r6big 'commission'; _r4cut commission
has "under a two-block file-size limit a refused revoke of commission from an 80 KB file says it could not be read whole or rewritten" \
    "$_rverr" "could not be read whole or rewritten"
is "and the refusal over the 80 KB file says nothing of another writer" \
   "$(_r3has "$_rverr" 'another writer' claimed honest)" "honest"
is "and the refused revoke of commission from the 80 KB file exits non-zero, keeps the stamp and leaves the file byte-identical" \
   "$(_rwexit):$(_rvstamp):$(_r3cmp "$TMP/rv.held" "$RVP/autonomy")" "refused:kept:same"

# G6: a revoke is linear in the length of a line. Each long line is 512 KB.
rm -f "$RVP"/autonomy*
{ printf '# h\n'; _r6xs 524288 x; printf '\ntidy\n'; } > "$RVP/autonomy"
{ printf '# h\n'; _r6xs 524288 x; printf '\n'; } > "$TMP/rw.want"
is "a revoke of tidy below one 512 KB line of x returns 0 using at most 6 seconds of CPU" \
   "$(_r6cpu tidy)" "returned 0:within"
is "and that revoke leaves no tidy line and the 512 KB line of x whole" \
   "$(LC_ALL=C grep -cx tidy "$RVP/autonomy"):$(LC_ALL=C sed -n 2p "$RVP/autonomy" | wc -c | tr -d ' '):$(_rwis)" \
   "0:524289:same"
rm -f "$RVP"/autonomy*
{ printf 'tidy\n# '; _r6xs 524288 x; printf ' tidy\n'; } > "$RVP/autonomy"
{ printf '# '; _r6xs 524288 x; printf ' tidy\n'; } > "$TMP/rw.want"
is "a revoke of tidy above a 512 KB comment that mentions tidy returns 0 using at most 6 seconds of CPU" \
   "$(_r6cpu tidy)" "returned 0:within"
is "and that revoke leaves only the 512 KB comment, byte for byte" "$(_rwis)" "same"
rm -f "$RVP"/autonomy*
{ _r6xs 524288 '\201'; printf 'tidy\n# h\n'; } > "$RVP/autonomy"
printf '# h\n' > "$TMP/rw.want"
is "a revoke of tidy over one line of 512 KB of 0x81 bytes and then tidy returns 0 using at most 6 seconds of CPU" \
   "$(_r6cpu tidy)" "returned 0:within"
is "and that revoke removes the long line that names tidy and leaves exactly '# h'" "$(_rwis)" "same"

rm -f "$RVP"/autonomy* "$TMP/rw.want" "$TMP/rv.held"
for _rvf in "$RV6K"/autonomy*; do [ -e "$_rvf" ] && mv "$_rvf" "$RVP/"; done
rmdir "$RV6K" 2>/dev/null
is "the widget's directory holds exactly what it held before failed reads, failed writes and long lines were tested" \
   "$(ls -A "$RVP" | LC_ALL=C sort)" "$_r6start"

printf '\nrevoke and the reader take no stopped subshell for an answer\n'
# 2026-10-08: the writer lock's third review found that, under bash 3.2, a set -u
# stop in an arithmetic expansion need not fail a subshell. In a script file
# under set -u, a subshell that reads an unset name inside $(( )) ends with the
# status of the last command it ran before the stop, which was 0 in every case
# here, where bash -c gives 127 and a plain unbound word gives 1, so a revoke
# pass or a grant read stopped part-way can look like one that finished.
# felix runs as a script under set -uo pipefail, so every fault here is
# injected through a script file run by "$BASH", never "$BASH -c". H1 and H3
# hand back 'revoked: tidy' from every wc after the first, which is no count;
# H2 stops the grant read itself. On bash 5.2 (Linux CI) the stop exits
# non-zero, so this block is green on every revision there, and can fail only
# under bash 3.2, as on macOS.
RV7K="$TMP/revoke-keep-7"; mkdir -p "$RV7K"
_r7start="$(ls -A "$RVP" | LC_ALL=C sort)"
for _rvf in "$RVP"/autonomy*; do [ -e "$_rvf" ] && mv "$_rvf" "$RV7K/"; done
_r7calls="$TMP/r7.calls"
_r7exit() { case "$1" in 'returned 0') echo 'returned 0' ;; 'returned '[1-9]*) echo refused ;; *) echo "no status [$1]" ;; esac; }

# H1: a revoke pass stopped part-way is a refusal, not a rewrite. With STOP as
# its fourth word the script's wc is real once and then prints no count.
cat > "$TMP/r7.h1" <<'R7H1'
set -uo pipefail
. "$1/harness/lib/autonomy.sh"
_r7c="$3"
if [ "$4" = stop ]; then
  wc() {
    if [ -e "$_r7c" ]; then printf 'call\n' >> "$_r7c"; printf 'revoked: tidy\n'; return 0; fi
    printf 'call\n' > "$_r7c"; command wc "$@"
  }
fi
felix_autonomy_revoke "$2" tidy >/dev/null 2>&1
echo "returned $?"
R7H1
rm -f "$_r7calls"; _rvset '# h\ntidy\ncommission\n'; _r6held
_r7h1="$("$BASH" "$TMP/r7.h1" "$FROOT" "$RVP" "$_r7calls" stop 2>/dev/null)"
is "a revoke of tidy in a script under set -u whose wc prints no count after its first call returns non-zero" \
   "$(_r7exit "$_r7h1")" "refused"
is "and that stopped revoke leaves the grant file byte-identical, tidy granted, the stamp kept and nothing new behind" \
   "$(_r3cmp "$TMP/rv.held" "$RVP/autonomy"):$(_rvallows tidy):$(_rvstamp):$(_r6new)" "same:yes:kept:nothing-new"
rm -f "$_r7calls"; _rvset '# h\ntidy\ncommission\n'
_r7h1="$("$BASH" "$TMP/r7.h1" "$FROOT" "$RVP" "$_r7calls" real 2>/dev/null)"
is "and the same script with the real wc revokes tidy, returns 0 and keeps commission" \
   "$(_r7exit "$_r7h1"):$(_rvallows tidy):$(_rvallows commission)" "returned 0:no:yes"

# H2: a grant read stopped part-way is no grant. With STOP as its third word
# the script's grant read stops in an arithmetic expansion of an unset name.
cat > "$TMP/r7.h2" <<'R7H2'
set -uo pipefail
. "$1/harness/lib/autonomy.sh"
if [ "$3" = stop ]; then
  _felix_autonomy_grants() { local x; x=$(( h2_never_set )); }
fi
if felix_autonomy_allows "$2" tidy; then echo grant; else echo none; fi
R7H2
_rvset 'tidy\n'
is "a grant read of tidy in a script under set -u stopped by an unset name in arithmetic is no grant" \
   "$("$BASH" "$TMP/r7.h2" "$FROOT" "$RVP" stop 2>/dev/null)" "none"
is "and the same script without the stop reads tidy over 'tidy' as a grant" \
   "$("$BASH" "$TMP/r7.h2" "$FROOT" "$RVP" plain 2>/dev/null)" "grant"

# H3: the CLI end to end, with an executable wc first in PATH that is the real
# wc once and then prints no count. No stamp is written.
_r7bin="$TMP/r7.bin"; mkdir -p "$_r7bin"; _r7wc="$(command -v wc)"
{ printf '#!/bin/sh\n'; printf "c='%s'; w='%s'\n" "$_r7calls" "$_r7wc"
  cat <<'R7WC'
if [ -e "$c" ]; then printf 'call\n' >> "$c"; printf 'revoked: tidy\n'; exit 0; fi
printf 'call\n' > "$c"; exec "$w" "$@"
R7WC
} > "$_r7bin/wc"; chmod 755 "$_r7bin/wc"
rm -f "$_r7calls"; _rvset '# h\ntidy\ncommission\n'; rm -f "$RVP/autonomy.commission"; _r6held
( cd "$REPO" && PATH="$_r7bin:$PATH" "$FELIX" autonomy --revoke tidy ) > "$TMP/rv.out" 2> "$TMP/rv.err"
_rvrc=$?; _rvout="$(cat "$TMP/rv.out")"; _rverr="$(cat "$TMP/rv.err")"
rm -rf "$_r7bin"
is "a felix autonomy --revoke tidy whose wc prints no count after its first call exits non-zero" "$(_rwexit)" "refused"
is "and the stopped CLI revoke prints no revoked: on stdout" "$(_r3has "$_rvout" 'revoked:' said silent)" "silent"
is "and the stopped CLI revoke leaves the grant file byte-identical and nothing new behind" \
   "$(_r3cmp "$TMP/rv.held" "$RVP/autonomy"):$(_r6new)" "same:nothing-new"

rm -f "$RVP"/autonomy* "$TMP/rv.held" "$_r7calls" "$TMP/r7.h1" "$TMP/r7.h2"
for _rvf in "$RV7K"/autonomy*; do [ -e "$_rvf" ] && mv "$_rvf" "$RVP/"; done
rmdir "$RV7K" 2>/dev/null
is "the widget's directory holds exactly what it held before stopped subshells were tested" \
   "$(ls -A "$RVP" | LC_ALL=C sort)" "$_r7start"

printf '\nrevoke knows every letter, stays linear after the capability, and takes no stop for an answer\n'
# 2026-10-08: the fifth review of the revoke fix found three gaps the blocks
# above leave open. G1 pinned upper-case neighbours with three letters, so a
# names rule that knew only some of the alphabet still passed; every ASCII
# letter, on either side of either capability, is pinned here. G6 measured a
# long line that does not begin with the capability, and a revoke that matched
# the capability at the start of a line and then walked the letters after it
# could still cost seconds on one line of half a megabyte. And block 7 took a
# set -u stop in a subshell to exit 0. Under bash 3.2, in a script file, it
# exits with the status of the last command run before the stop, so a stop can
# leave any status, 10 or 4 or 2 among them, including one the engine itself
# uses to mean success or a NUL byte. The cases here do not stop a pass: they
# stub wc, which from some call on answers 'revoked: tidy' and no count and
# returns a chosen status, and a revoke given that answer must be refused
# whatever status comes with it, without claiming a NUL the file does not
# hold. The block after this one stops the names test itself. These cases are
# script files run by "$BASH", as block 7's are.
RV8K="$TMP/revoke-keep-8"; mkdir -p "$RV8K"
_r8start="$(ls -A "$RVP" | LC_ALL=C sort)"
for _rvf in "$RVP"/autonomy*; do [ -e "$_rvf" ] && mv "$_rvf" "$RV8K/"; done

# I1: every ASCII letter beside a capability is a letter. For each of A-Z and
# a-z, four lines: the letter then tidy, tidy then the letter, the letter then
# commission, and commission then the letter, built as printf octal escapes.
_r8fmt=''; _r8d=65
while [ "$_r8d" -le 122 ]; do
  if [ "$_r8d" -le 90 ] || [ "$_r8d" -ge 97 ]; then
    _r8o="$(printf '%03o' "$_r8d")"
    _r8fmt="$_r8fmt\\${_r8o}tidy\\ntidy\\${_r8o}\\n\\${_r8o}commission\\ncommission\\${_r8o}\\n"
  fi
  _r8d=$((_r8d+1))
done
_rvset "${_r8fmt}tidy\\ncommission\\n"
is "before any revoke a file of 208 lettered lines and bare tidy and commission lines holds 210 lines and grants both, under C and UTF-8" \
   "$(wc -l < "$RVP/autonomy" | tr -d ' '):$(_rwboth tidy):$(_rwboth commission)" "210:yes:yes:yes:yes"
_rwloc C tidy; printf "${_r8fmt}commission\\n" > "$TMP/rw.want"
is "a revoke of tidy under C beside every ASCII letter on both sides of both capabilities exits 0 and removes only the bare tidy line" \
   "$_rvrc:$(_rwis)" "0:same"
_rvset "${_r8fmt}tidy\\ncommission\\n"; _rwloc C commission; printf "${_r8fmt}tidy\\n" > "$TMP/rw.want"
is "a revoke of commission under C beside every ASCII letter on both sides of both capabilities exits 0 and removes only the bare commission line" \
   "$_rvrc:$(_rwis)" "0:same"

# I2: a revoke is linear when the capability comes first and letters follow.
rm -f "$RVP"/autonomy*
{ printf '# h\ntidy'; _r6xs 524288 x; printf '\ntidy\n'; } > "$RVP/autonomy"
{ printf '# h\ntidy'; _r6xs 524288 x; printf '\n'; } > "$TMP/rw.want"
is "a revoke of tidy below one line of tidy and then 512 KB of x returns 0 using at most 6 seconds of CPU" \
   "$(_r6cpu tidy)" "returned 0:within"
is "and that revoke keeps the line of tidy and 512 KB of x byte for byte" "$(_rwis)" "same"
rm -f "$RVP"/autonomy*
{ printf '# h\ntidy'; _r6xs 524288 t; printf '\ntidy\n'; } > "$RVP/autonomy"
{ printf '# h\ntidy'; _r6xs 524288 t; printf '\n'; } > "$TMP/rw.want"
is "a revoke of tidy below one line of tidy and then 512 KB of t returns 0 using at most 6 seconds of CPU" \
   "$(_r6cpu tidy)" "returned 0:within"
is "and that revoke keeps the line of tidy and 512 KB of t byte for byte" "$(_rwis)" "same"
_r8s='commissio '; _r8i=0
while [ "$_r8i" -lt 15 ]; do _r8s="$_r8s$_r8s"; _r8i=$((_r8i+1)); done
_r8s="${_r8s:0:262140}"
rm -f "$RVP"/autonomy*
printf '# h\ncommission%s\ncommission\n' "$_r8s" > "$RVP/autonomy"
printf '# h\ncommission%s\n' "$_r8s" > "$TMP/rw.want"
is "a revoke of commission below one line of commission and then 256 KB of 'commissio ' returns 0 using at most 6 seconds of CPU" \
   "$(_r6cpu commission)" "returned 0:within"
is "and that revoke keeps the line of commission and 256 KB of 'commissio ' byte for byte" "$(_rwis)" "same"
_r8s=''

# I3: a wc that answers no count is refused whatever status it returns.
# The script's wc counts its calls in a file, and from call FROM onward prints
# no count but 'revoked: tidy' and returns CODE; before that it is the real wc.
_r8calls="$TMP/r8.calls"
cat > "$TMP/r8.i3" <<'R8I3'
set -uo pipefail
. "$1/harness/lib/autonomy.sh"
_r8c="$3"; _r8from="$4"; _r8code="$5"
wc() {
  printf 'call\n' >> "$_r8c"
  _r8n=$(( $(command wc -l < "$_r8c") ))
  if [ "$_r8n" -ge "$_r8from" ]; then printf 'revoked: tidy\n'; return "$_r8code"; fi
  command wc "$@"
}
felix_autonomy_revoke "$2" tidy >/dev/null 2>&1
echo "returned $?"
R8I3
_r8run() {   # FROM CODE: the script above over the widget's file -> 'returned N'
  rm -f "$_r8calls"; "$BASH" "$TMP/r8.i3" "$FROOT" "$RVP" "$_r8calls" "$1" "$2" 2>/dev/null
}
for _r8code in 10 4 5; do
  _rvset '# h\ntidy\ncommission\n'; _r6held; _r8out="$(_r8run 2 "$_r8code")"
  is "a revoke of tidy in a script under set -u whose wc from its second call returns $_r8code without a count returns non-zero, leaves the file byte-identical and nothing new" \
     "$(_r7exit "$_r8out"):$(_r3cmp "$TMP/rv.held" "$RVP/autonomy"):$(_r6new)" "refused:same:nothing-new"
done
_rvset '# h\ntidy\ncommission\n'; _r8out="$(_r8run 1000000 10)"; printf '# h\ncommission\n' > "$TMP/rw.want"
is "and the same script with a wc that is real on every call revokes tidy, returns 0 and keeps commission" \
   "$_r8out:$(_rwis)" "returned 0:same"
for _r8code in 4 2; do
  _rvset '# h\ntidy\302\240\n'; _r6held; _r8out="$(_r8run 1 "$_r8code")"
  is "a revoke of tidy over a no-break-space line in a script under set -u whose wc from its first call returns $_r8code without a count returns exactly 1 and keeps the line byte for byte" \
     "$_r8out:$(_r3cmp "$TMP/rv.held" "$RVP/autonomy")" "returned 1:same"
done

# I3, the CLI: an executable wc first in PATH that from its first call prints
# 'revoked: tidy' and exits 2, the status a NUL byte is refused with.
_r8bin="$TMP/r8.bin"; mkdir -p "$_r8bin"
printf '%s\n' '#!/bin/sh' "printf 'revoked: tidy\\n'" 'exit 2' > "$_r8bin/wc"; chmod 755 "$_r8bin/wc"
_rvset '# h\ntidy\302\240\n'; _r6held
( cd "$REPO" && PATH="$_r8bin:$PATH" "$FELIX" autonomy --revoke tidy ) > "$TMP/rv.out" 2> "$TMP/rv.err"
_rvrc=$?; _rvout="$(cat "$TMP/rv.out")"; _rverr="$(cat "$TMP/rv.err")"
rm -rf "$_r8bin"
is "a felix autonomy --revoke tidy whose wc exits 2 with no count from its first call exits non-zero and leaves the file byte-identical" \
   "$(_rwexit):$(_r3cmp "$TMP/rv.held" "$RVP/autonomy")" "refused:same"
is "and that stopped CLI revoke prints no revoked: on stdout" "$(_r3has "$_rvout" 'revoked:' said silent)" "silent"
is "and that stopped CLI revoke does not claim a NUL byte the file does not hold" \
   "$(_r3has "$_rverr" 'NUL' claimed honest)" "honest"

rm -f "$RVP"/autonomy* "$TMP/rw.want" "$TMP/rv.held" "$_r8calls" "$TMP/r8.i3"
for _rvf in "$RV8K"/autonomy*; do [ -e "$_rvf" ] && mv "$_rvf" "$RVP/"; done
rmdir "$RV8K" 2>/dev/null
is "the widget's directory holds exactly what it held before every letter, long capability lines and stopped passes were tested" \
   "$(ls -A "$RVP" | LC_ALL=C sort)" "$_r8start"

printf '\nrevoke writes no stale output, takes one count from wc, and no stop for an answer\n'
# 2026-10-08: the sixth review of the revoke fix found three gaps the blocks
# above leave open. Under bash 3.2 a printf that fails on a closed stdout keeps
# its text in the shell's stdout buffer, and every subshell forked after that
# flushes the buffer into its own stdout, a $( ) capture included, before or
# after its own output. A caller that printed into a closed stdout before revoking could
# so hand the revoke text it never read from the grant file: a NUL byte, a
# newline, a line saying revoked, or a line only older engines grant. K1 pins
# that none of it reaches the grant file. Block 8's wc printed no count at all;
# K2 pins that a wc that prints a true count and then more, two numbers, or a
# true count with a failing status is no answer either, beside a control whose
# wc is real. Block 8 stubbed wc's answer and status and never stopped a pass;
# K3 stops the names test itself under set -u, in the first pass and in the
# second, after each of several statuses, and a revoke whose pass stopped must
# return 1 whatever status the stop left. K4 is the CLI under K2's first stub.
# Every case is a script file run by "$BASH", as blocks 7 and 8 are.
RV9K="$TMP/revoke-keep-9"; mkdir -p "$RV9K"
_r9start="$(ls -A "$RVP" | LC_ALL=C sort)"
for _rvf in "$RVP"/autonomy*; do [ -e "$_rvf" ] && mv "$_rvf" "$RV9K/"; done
_r9calls="$TMP/r9.calls"
_r9last() { printf '%s\n' "$1" | tail -n 1; }   # TEXT: its last line

# K1: a stale stdout buffer never reaches the grant file. The script closes
# stdout, fails a printf of STALE into it, points stdout at /dev/null, revokes
# tidy, and then prints the status on the stdout it saved.
cat > "$TMP/r9.k1" <<'R9K1'
set -uo pipefail
. "$1/harness/lib/autonomy.sh"
exec 3>&1 1>&-
printf "$3" 2>/dev/null
exec 1>/dev/null
felix_autonomy_revoke "$2" tidy 2>/dev/null
_r9rc=$?
exec 1>&3
echo "returned $_r9rc"
R9K1
_r9k1() {   # STALE LABEL: the K1 script over '# h', tidy and commission
  _rvset '# h\ntidy\ncommission\n'; _r6held
  _r9out="$("$BASH" "$TMP/r9.k1" "$FROOT" "$RVP" "$1" < /dev/null 2>/dev/null)"
  printf '# h\ncommission\n' > "$TMP/rw.want"
  is "a revoke of tidy after a printf of $2 failed on a closed stdout returns 0, leaves exactly '# h' and commission and nothing new" \
     "$(_r9last "$_r9out"):$(_rwis):$(_r6new)" "returned 0:same:nothing-new"
}
_r9k1 '\0' 'a NUL byte'
_r9k1 '\n' 'a newline'
_r9k1 'revoked: tidy\n' "'revoked: tidy'"
_r9k1 'tidy\302\240\n' 'tidy and a no-break space'

# K2: wc must answer one count. The script's wc, defined after the lib is
# sourced, is one of four stubs; the last is the control.
cat > "$TMP/r9.k2" <<'R9K2'
set -uo pipefail
. "$1/harness/lib/autonomy.sh"
case "$3" in
  text)  wc() { command wc "$@"; printf 'revoked: tidy\n'; return 0; } ;;
  two)   wc() { printf '2 0\n'; return 0; } ;;
  fails) wc() { command wc "$@"; return 1; } ;;
  real)  wc() { command wc "$@"; return 0; } ;;
esac
felix_autonomy_revoke "$2" tidy >/dev/null 2>&1
echo "returned $?"
R9K2
_r9k2() {   # STUB LABEL: the K2 script over the 20-byte '# h', tidy and commission, refused
  _rvset '# h\ntidy\ncommission\n'; _r6held
  _r9out="$("$BASH" "$TMP/r9.k2" "$FROOT" "$RVP" "$1" < /dev/null 2>/dev/null)"
  is "a revoke of tidy in a script under set -u whose wc $2 returns 1, leaves the file byte-identical and nothing new" \
     "$(_r9last "$_r9out"):$(_r3cmp "$TMP/rv.held" "$RVP/autonomy"):$(_r6new)" "returned 1:same:nothing-new"
}
_r9k2 text "prints a true count and then the line 'revoked: tidy'"
_r9k2 two "prints '2 0' over a 20-byte file"
_r9k2 fails "prints a true count and exits 1"
_rvset '# h\ntidy\ncommission\n'; _r6held
_r9out="$("$BASH" "$TMP/r9.k2" "$FROOT" "$RVP" real < /dev/null 2>/dev/null)"
printf '# h\ncommission\n' > "$TMP/rw.want"
is "and the same script whose wc prints a true count and exits 0 returns 0, leaves exactly '# h' and commission and nothing new" \
   "$(_r9last "$_r9out"):$(_rwis):$(_r6new)" "returned 0:same:nothing-new"

# K3: a pass stopped part-way is refused whatever status the stop leaves. The
# script wraps the names test, counts its calls in a file, and on call N runs
# (exit CODE) and then reads an unset name in arithmetic, which stops the
# subshell with CODE under bash 3.2. Over '# h' and a no-break-space tidy line
# the first pass asks about lines 1 and 2 (calls 1 and 2), the second about
# both again (calls 3 and 4).
cat > "$TMP/r9.k3" <<'R9K3'
set -uo pipefail
. "$1/harness/lib/autonomy.sh"
_r9c="$3"; _r9n="$4"; _r9code="$5"
eval "_k3_real_$(declare -f _felix_autonomy_names)"
_felix_autonomy_names() {
  printf 'call\n' >> "$_r9c"
  if [ "$(command wc -l < "$_r9c" | tr -d ' ')" = "$_r9n" ]; then
    (exit "$_r9code"); _r9x=$(( never_set_k3 ))
  fi
  _k3_real__felix_autonomy_names "$@"
}
felix_autonomy_revoke "$2" tidy >/dev/null 2>&1
echo "returned $?"
R9K3
_r9k3() {   # N CODE: the K3 script over '# h' and a no-break-space tidy line -> 'returned N'
  rm -f "$_r9calls"
  "$BASH" "$TMP/r9.k3" "$FROOT" "$RVP" "$_r9calls" "$1" "$2" < /dev/null 2>/dev/null
}
_rvset '# h\ntidy\302\240\n'; _r9out="$(_r9k3 1000000 0)"; printf '# h\n' > "$TMP/rw.want"
_r9asked="$(cat "$_r9calls" 2>/dev/null | wc -l | tr -d ' ')"
is "a revoke of tidy over a no-break-space line whose names test is wrapped but never stopped returns 0, leaves exactly '# h' and asks the names test at least three times" \
   "$(_r9last "$_r9out"):$(_rwis):$([ "${_r9asked:-0}" -ge 3 ] && echo asked || echo "asked ${_r9asked:-0}")" \
   "returned 0:same:asked"
for _r9case in 1:0 1:1 1:2 1:4 1:5 1:10 3:0 3:1 3:2 3:4 3:10; do
  _r9n="${_r9case%%:*}"; _r9code="${_r9case#*:}"
  case "$_r9n" in 1) _r9pass=first ;; *) _r9pass=second ;; esac
  _rvset '# h\ntidy\302\240\n'; _r6held; _r9out="$(_r9k3 "$_r9n" "$_r9code")"
  is "a revoke of tidy over a no-break-space line whose names test stops under set -u on call $_r9n, in the $_r9pass pass, after status $_r9code returns exactly 1, leaves the file byte-identical and nothing new" \
     "$(_r9last "$_r9out"):$(_r3cmp "$TMP/rv.held" "$RVP/autonomy"):$(_r6new)" "returned 1:same:nothing-new"
done

# K4: the CLI under K2's first stub. An executable wc first in PATH prints the
# true count and then a line of text; a second one only passes to the real wc,
# as a control. No stamp is written.
_r9bin="$TMP/r9.bin"; _r9ctl="$TMP/r9.ctl"; mkdir -p "$_r9bin" "$_r9ctl"; _r9wc="$(command -v wc)"
{ printf '#!/bin/sh\n'; printf "w='%s'\n" "$_r9wc"; printf '%s\n' '"$w" "$@"' "printf 'revoked: tidy\\n'" 'exit 0'; } > "$_r9bin/wc"
{ printf '#!/bin/sh\n'; printf "exec '%s' \"\$@\"\n" "$_r9wc"; } > "$_r9ctl/wc"
chmod 755 "$_r9bin/wc" "$_r9ctl/wc"
_r9cli() {   # BIN: felix autonomy --revoke tidy with BIN first in PATH; sets _rvrc _rvout _rverr
  ( cd "$REPO" && PATH="$1:$PATH" "$FELIX" autonomy --revoke tidy ) > "$TMP/rv.out" 2> "$TMP/rv.err" < /dev/null
  _rvrc=$?; _rvout="$(cat "$TMP/rv.out")"; _rverr="$(cat "$TMP/rv.err")"
}
_rvset '# h\ntidy\ncommission\n'; rm -f "$RVP/autonomy.commission"; _r6held; _r9cli "$_r9bin"
is "a felix autonomy --revoke tidy whose wc prints a true count and then a line of text exits non-zero, prints no revoked: on stdout, leaves the file byte-identical and nothing new" \
   "$(_rwexit):$(_r3has "$_rvout" 'revoked:' said silent):$(_r3cmp "$TMP/rv.held" "$RVP/autonomy"):$(_r6new)" \
   "refused:silent:same:nothing-new"
_rvset '# h\ntidy\ncommission\n'; rm -f "$RVP/autonomy.commission"; _r6held; _r9cli "$_r9ctl"
printf '# h\ncommission\n' > "$TMP/rw.want"
is "and the same CLI revoke whose wc in PATH only passes to the real wc exits 0 and leaves exactly '# h' and commission" \
   "$_rvrc:$(_rwis)" "0:same"
rm -rf "$_r9bin" "$_r9ctl"

rm -f "$RVP"/autonomy* "$TMP/rw.want" "$TMP/rv.held" "$_r9calls" "$TMP/r9.k1" "$TMP/r9.k2" "$TMP/r9.k3"
for _rvf in "$RV9K"/autonomy*; do [ -e "$_rvf" ] && mv "$_rvf" "$RVP/"; done
rmdir "$RV9K" 2>/dev/null
is "the widget's directory holds exactly what it held before stale output, wc's answers and stopped names tests were tested" \
   "$(ls -A "$RVP" | LC_ALL=C sort)" "$_r9start"

printf '\nrevoke holds with stdout closed throughout, a file changed between its passes, and any IFS\n'
# 2026-10-08: the seventh review of the revoke fix found three gaps the blocks
# above leave open. K1 pointed stdout at /dev/null before the revoke, so a
# stale buffer was only ever flushed into /dev/null or a capture; L1 keeps
# stdout closed from the failed printf through the revoke, and the revoke must
# still read only the grant file and rewrite it. The revoke reads the file in
# two passes, and nothing pinned what it does when the file changes between
# them; L2 changes it from a mktemp defined after the lib is sourced, which
# replaces every mktemp the lib calls by that name, so the second pass reads
# the changed file: a file that no longer grants tidy is left as it now is with
# status 0, and one that now ends in a NUL byte is refused with 2 and left as
# it now is. A stub that writes a marker outside the project shows it ran.
# And an unquoted $(( )) or $( ) in the lib is word-split on the caller's IFS,
# which a shell function inherits, so an IFS holding a digit split a count and
# the revoke refused or kept the grant; L3 revokes under several such IFS
# values. Every case is a script file run by "$BASH", as blocks 7 to 9 are.
RV10K="$TMP/revoke-keep-10"; mkdir -p "$RV10K"
_r10start="$(ls -A "$RVP" | LC_ALL=C sort)"
for _rvf in "$RVP"/autonomy*; do [ -e "$_rvf" ] && mv "$_rvf" "$RV10K/"; done
_r10mark="$TMP/r10.marker"

# L1: the flush holds when stdout stays closed through the revoke. The script
# closes stdout, fails a printf of STALE into it, revokes tidy with stdout
# still closed, and then prints the status on the stdout it saved.
cat > "$TMP/r10.l1" <<'R10L1'
set -uo pipefail
. "$1/harness/lib/autonomy.sh"
exec 3>&1 1>&-
printf "$3" 2>/dev/null
felix_autonomy_revoke "$2" tidy 2>/dev/null
_r10rc=$?
exec 1>&3
echo "returned $_r10rc"
R10L1
_r10l1() {   # STALE LABEL: the L1 script over '# h', tidy and commission
  _rvset '# h\ntidy\ncommission\n'; _r6held
  _r10out="$("$BASH" "$TMP/r10.l1" "$FROOT" "$RVP" "$1" < /dev/null 2>/dev/null)"
  printf '# h\ncommission\n' > "$TMP/rw.want"
  is "a revoke of tidy with stdout closed from a failed printf of $2 through the revoke returns 0, leaves exactly '# h' and commission and nothing new" \
     "$(_r9last "$_r10out"):$(_rwis):$(_r6new)" "returned 0:same:nothing-new"
}
_r10l1 '\0' 'a NUL byte'
_r10l1 '\n' 'a newline'
_r10l1 'revoked: tidy\n' "'revoked: tidy'"
_r10l1 'tidy\302\240\n' 'tidy and a no-break space'

# L2: the file changes between the two passes. The script's mktemp writes
# CASE's content to the grant file and a line to a marker outside the
# project, and then makes the temporary file; the control's mktemp only makes
# it. Adapted at the merge into the writer lock: there, revoke runs mktemp
# with `exec`, which never calls a shell function, so the stub is a mktemp
# first on the script's PATH instead of a function defined after the lib.
# The marker assertion still fails if the stub never runs.
_r10shim="$TMP/r10.shim"; mkdir -p "$_r10shim"
{ printf '#!/bin/sh\n'
  printf 'case "$R10_CASE" in\n'
  printf '  gone) printf "stub\\n" >> "$R10_MARK"; printf "# h\\ncommission\\n" > "$R10_GRANT" ;;\n'
  printf '  nul)  printf "stub\\n" >> "$R10_MARK"; printf "# h\\ntidy\\ncommission\\n\\0" > "$R10_GRANT" ;;\n'
  printf 'esac\n'
  printf 'exec %s "$@"\n' "'$(command -v mktemp)'"
} > "$_r10shim/mktemp"; chmod +x "$_r10shim/mktemp"
cat > "$TMP/r10.l2" <<'R10L2'
set -uo pipefail
. "$1/harness/lib/autonomy.sh"
R10_GRANT="$2/autonomy"; R10_MARK="$3"; R10_CASE="$4"; export R10_GRANT R10_MARK R10_CASE
PATH="$5:$PATH"
felix_autonomy_revoke "$2" tidy >/dev/null 2>&1
echo "returned $?"
R10L2
_r10l2() {   # CASE: the L2 script over '# h', tidy and commission -> 'returned N'
  rm -f "$_r10mark"; _rvset '# h\ntidy\ncommission\n'
  "$BASH" "$TMP/r10.l2" "$FROOT" "$RVP" "$_r10mark" "$1" "$_r10shim" < /dev/null 2>/dev/null
}
_r10ran() { [ -s "$_r10mark" ] && echo stub-ran || echo stub-never-ran; }
_r10out="$(_r10l2 gone)"; printf '# h\ncommission\n' > "$TMP/rw.want"
is "a revoke of tidy whose mktemp first rewrites the grant file without tidy returns 0, leaves exactly '# h' and commission and nothing new, and the stub ran" \
   "$(_r9last "$_r10out"):$(_rwis):$(_r6new):$(_r10ran)" "returned 0:same:nothing-new:stub-ran"
_r10out="$(_r10l2 nul)"; printf '# h\ntidy\ncommission\n\0' > "$TMP/rw.want"
is "a revoke of tidy whose mktemp first rewrites the grant file to end in a NUL byte returns 2, leaves the file byte-identical to what the stub wrote and nothing new, and the stub ran" \
   "$(_r9last "$_r10out"):$(_rwis):$(_r6new):$(_r10ran)" "returned 2:same:nothing-new:stub-ran"
_r10out="$(_r10l2 control)"; printf '# h\ncommission\n' > "$TMP/rw.want"
is "and the same script whose mktemp only runs the real mktemp revokes tidy, returns 0 and leaves exactly '# h' and commission and nothing new" \
   "$(_r9last "$_r10out"):$(_rwis):$(_r6new)" "returned 0:same:nothing-new"

# L3: a caller's IFS changes nothing. The script sets IFS to the value under
# test after sourcing the lib, revokes CAP, and restores the default IFS before
# it reports the status.
cat > "$TMP/r10.l3" <<'R10L3'
set -uo pipefail
. "$1/harness/lib/autonomy.sh"
IFS="$4"
felix_autonomy_revoke "$2" "$3" >/dev/null 2>&1
_r10rc=$?
IFS=$' \t\n'
echo "returned $_r10rc"
R10L3
_r10l3() {   # CAP IFS: the L3 script over '# h', tidy and commission -> 'returned N'
  _rvset '# h\ntidy\ncommission\n'
  "$BASH" "$TMP/r10.l3" "$FROOT" "$RVP" "$1" "$2" < /dev/null 2>/dev/null
}
for _r10ifs in 2 5 0123456789 ' 2'; do
  _r10out="$(_r10l3 tidy "$_r10ifs")"; printf '# h\ncommission\n' > "$TMP/rw.want"
  is "a revoke of tidy in a script whose IFS is '$_r10ifs' returns 0, leaves exactly '# h' and commission and nothing new" \
     "$(_r9last "$_r10out"):$(_rwis):$(_r6new)" "returned 0:same:nothing-new"
done
_r10out="$(_r10l3 commission 2)"; printf '# h\ntidy\n' > "$TMP/rw.want"
is "a revoke of commission in a script whose IFS is '2' returns 0, leaves exactly '# h' and tidy and nothing new" \
   "$(_r9last "$_r10out"):$(_rwis):$(_r6new)" "returned 0:same:nothing-new"

rm -f "$RVP"/autonomy* "$TMP/rw.want" "$TMP/rv.held" "$_r10mark" "$TMP/r10.l1" "$TMP/r10.l2" "$TMP/r10.l3"
for _rvf in "$RV10K"/autonomy*; do [ -e "$_rvf" ] && mv "$_rvf" "$RVP/"; done
rmdir "$RV10K" 2>/dev/null
is "the widget's directory holds exactly what it held before a closed stdout, a file changed between passes and a caller's IFS were tested" \
   "$(ls -A "$RVP" | LC_ALL=C sort)" "$_r10start"
