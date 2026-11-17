printf '\nthe autonomy file has one writer at a time\n'
# 2026-10-08: felix autonomy is the only writer of a project's grant file and
# of its commission stamp, and nothing serialised it. Two runs at once
# interleaved: a revoke of commission read the file, a revoke of tidy then
# rewrote it, read it back and said "revoked: tidy", and the first run's move
# landed its stale copy, tidy still in it. Tidy is the grant that deletes files
# at session start. An allow racing a revoke lost its line the same way. These
# pin the lock that ends it: one empty directory, autonomy.lock, taken by every
# run given --allow or --revoke and gone after every exit, a signal's included;
# a run that finds it held refuses, writes nothing, leaves it where it was and
# says rmdir clears a stale one; a run that only reads takes none; and another
# project's lock stops nothing. Run A is paused inside its rewrite by an mv
# first on its PATH, which waits on a FIFO kept under the suite's temporary
# directory, and run B starts and ends meanwhile. A is started under job
# control so that SIGINT reaches it: a job started with & in a script ignores
# INT for good. INT goes to A's process group, as a Ctrl-C does, because bash
# waiting on a child that survives an INT carries on as if none came.
_lkp="$FROOT/projects/widget"; _lkL="$_lkp/autonomy.lock"; _lkk="$TMP/lock-keep"; mkdir -p "$_lkk"
_lkstart="$(ls -A "$_lkp" | LC_ALL=C sort)"
for _lkf in "$_lkp"/autonomy*; do { [ -e "$_lkf" ] || [ -L "$_lkf" ]; } && mv "$_lkf" "$_lkk/"; done
_lka=""; _lkbp=""; _lkreached=no
_lkallows() { ( . "$FROOT/harness/lib/autonomy.sh"; felix_autonomy_allows "$_lkp" "$1" && echo yes || echo no ); }
_lkclear() { rm -rf "$_lkp"/autonomy*; }   # every autonomy* entry of the widget, the lock included
_lkset() {   # FORMAT: the grant file written by printf FORMAT, beside a stamp for commission, and no lock
  _lkclear; printf "$1" > "$_lkp/autonomy"; printf 'stamp\n' > "$_lkp/autonomy.commission"
}
_lkstate() {   # the grant file and the stamp, each by checksum or as absent, then every name in the directory
  for _lkn in autonomy autonomy.commission; do
    if [ -e "$_lkp/$_lkn" ]; then printf '%s %s\n' "$_lkn" "$(cksum < "$_lkp/$_lkn")"
    else printf '%s absent\n' "$_lkn"; fi
  done
  ls -A "$_lkp" | LC_ALL=C sort
}
_lksame() { [ "$(_lkstate)" = "$_lkheld" ] && echo same || echo changed; }   # against _lkstate as _lkheld recorded it
_lklock() {   # the lock: absent, empty (a directory holding nothing), full, or other (not a directory)
  if [ -L "$_lkL" ]; then echo other
  elif [ ! -e "$_lkL" ]; then echo absent
  elif [ ! -d "$_lkL" ]; then echo other
  elif [ -n "$(ls -A "$_lkL" 2>/dev/null)" ]; then echo full
  else echo empty; fi
}
_lkrun() {   # ARGS...: felix autonomy ARGS from the widget checkout; sets _lkrc _lkout _lkerr
  # Given 30 s, so a run that waits on a held lock rather than refusing is a
  # failure and not a hang. Its status then names that, and is not a number.
  ( cd "$REPO" && exec "$FELIX" autonomy "$@" ) > "$TMP/lk.out" 2> "$TMP/lk.err" &
  _lkrp=$!
  if _lkuntil "$_lkrp"; then wait "$_lkrp"; _lkrc=$?
  else { kill -KILL "$_lkrp"; wait "$_lkrp"; } 2>/dev/null; _lkrc="still running after 30 s"; fi
  _lkout="$(cat "$TMP/lk.out")"; _lkerr="$(cat "$TMP/lk.err")"
}
_lkexit() { case "$1" in 0) echo "exit 0" ;; ''|*[!0-9]*) echo "${1:-no status}" ;; *) echo refused ;; esac; }   # STATUS
_lksaid() { case "$1" in *revoked:*|*allowed:*) echo said ;; *) echo silent ;; esac; }   # TEXT: reports a write?
_lkrv() { case "$1" in *revoked:*) echo said ;; *) echo silent ;; esac; }               # TEXT: says revoked:?
_lkhas() { case "$1" in *"$2"*) echo "$2" ;; *) echo "no [$2]" ;; esac; }               # TEXT WORD
_lkclaim() {   # STATUS TEXT LINE CAP WANT: broken when a run that exited 0 saying LINE leaves CAP's grant other than WANT
  case "$1:$2" in 0:*"$3"*) [ "$(_lkallows "$4")" = "$5" ] && echo holds || echo broken ;; *) echo holds ;; esac
}
_lkuntil() {   # PID: wait up to 30 s, far from a run's cost, for PID to be gone; 0 when it is
  _lki=0
  while kill -0 "$1" 2>/dev/null; do
    [ "$_lki" -ge 300 ] && return 1
    sleep 0.1; _lki=$((_lki+1))
  done
  return 0
}
# The mv run A finds first on its PATH. Armed, and moving onto the widget's
# grant file, it disarms, writes its pid to reached, and reads one line from
# the FIFO release; then, and in every other case at once, it is /bin/mv.
_lksh="$TMP/lock-shim"; mkdir -p "$_lksh"
{ printf '#!/bin/sh\n_d=%s\n' "'$_lksh'"
  cat <<'EOF'
_last=""; for _a in "$@"; do _last="$_a"; done
case "$_last" in
  */projects/widget/autonomy)
    if [ -e "$_d/armed" ] && /bin/rm "$_d/armed" 2>/dev/null; then
      echo "$$" > "$_d/reached"
      read -r _line < "$_d/release"
    fi ;;
esac
exec /bin/mv "$@"
EOF
} > "$_lksh/mv"; chmod +x "$_lksh/mv"
_lkgo() {   # run A, felix autonomy --revoke commission, in the background under job control, the shim first on its PATH
  _lka=""; _lkreached=no
  rm -f "$_lksh/reached" "$_lksh/release"; mkfifo "$_lksh/release" 2>/dev/null
  [ -p "$_lksh/release" ] || { _lkreached="no FIFO"; return; }
  : > "$_lksh/armed"; exec 8<>"$_lksh/release"
  set -m
  ( cd "$REPO" && PATH="$_lksh:$PATH" exec "$FELIX" autonomy --revoke commission ) \
    > "$TMP/lk-a.out" 2> "$TMP/lk-a.err" 8>&- &
  _lka=$!
  set +m
  _lki=0
  while [ "$_lki" -lt 100 ]; do
    [ -s "$_lksh/reached" ] && { _lkreached=yes; return; }
    sleep 0.1; _lki=$((_lki+1))
  done
}
_lkend() {   # release run A and reap it, then wait for its mv however A ended; sets _lkarc _lkaout _lkaerr
  { printf 'go\n' >&8; } 2>/dev/null; exec 8>&-
  _lkarc=""
  if [ -n "$_lka" ]; then
    _lkuntil "$_lka" || kill -KILL "$_lka" 2>/dev/null
    wait "$_lka"; _lkarc=$?
  fi
  _lksp="$(cat "$_lksh/reached" 2>/dev/null)"
  [ -n "$_lksp" ] && _lkuntil "$_lksp"
  rm -f "$_lksh/reached" "$_lksh/release" "$_lksh/armed"
  _lkaout="$(cat "$TMP/lk-a.out" 2>/dev/null)"; _lkaerr="$(cat "$TMP/lk-a.err" 2>/dev/null)"
}
_lkreq() {   # NAME VALUE EXPECTED: is, once run A paused in its rewrite; bad when it never did
  if [ "$_lkreached" = yes ]; then is "$1" "$2" "$3"
  else bad "$1" "run A never paused in the mv onto the grant file ($_lkreached)"; fi
}

# L2: a lock someone else holds. The run refuses, writes nothing, leaves the
# lock where it found it, and its stderr names the lock and says how to clear it.
_lkset 'tidy\ncommission\n'; mkdir "$_lkL"; _lkheld="$(_lkstate)"; _lkrun --revoke commission
is "with the lock held, a revoke of commission exits non-zero and says neither revoked: nor allowed:" \
   "$(_lkexit "$_lkrc"):$(_lksaid "$_lkout$_lkerr")" "refused:silent"
has "and the held-lock revoke names the lock's path on stderr" "$_lkerr" "projects/widget/autonomy.lock"
has "and the held-lock revoke says on stderr that rmdir clears a stale lock" "$_lkerr" "rmdir"
has "and the held-lock revoke says on stderr it was not revoked" "$_lkerr" "not revoked"
is "and the held-lock revoke leaves the grant file and the stamp byte-identical and adds nothing to the directory" \
   "$(_lksame)" "same"
is "and the held-lock revoke leaves the lock it found in place, still empty" "$(_lklock)" "empty"
_lkset 'commission\n'; mkdir "$_lkL"; _lkheld="$(_lkstate)"; _lkrun --allow tidy
is "with the lock held, an allow of tidy exits non-zero and says neither allowed: nor revoked:" \
   "$(_lkexit "$_lkrc"):$(_lksaid "$_lkout$_lkerr")" "refused:silent"
has "and the held-lock allow names the lock's path on stderr" "$_lkerr" "projects/widget/autonomy.lock"
has "and the held-lock allow says on stderr that rmdir clears a stale lock" "$_lkerr" "rmdir"
has "and the held-lock allow says on stderr it was not allowed" "$_lkerr" "not allowed"
is "and the held-lock allow leaves the grant file and the stamp byte-identical and adds nothing to the directory" \
   "$(_lksame)" "same"
is "and the held-lock allow leaves the lock it found in place, still empty" "$(_lklock)" "empty"
_lkset 'commission\n'; mkdir "$_lkL"; _lkheld="$(_lkstate)"; _lkrun --allow commission
is "with the lock held, an allow of commission already granted refuses, says no already allowed:, and leaves its stamp as it was" \
   "$(_lkexit "$_lkrc"):$(_lksaid "$_lkout$_lkerr"):$(_lksame)" "refused:silent:same"
_lkset 'commission\n'; mkdir "$_lkL"; _lkheld="$(_lkstate)"; _lkrun --allow tidy --revoke commission
is "with the lock held, a run given --allow and --revoke refuses, says not allowed and not revoked, and writes nothing" \
   "$(_lkexit "$_lkrc"):$(_lkhas "$_lkerr" 'not allowed'):$(_lkhas "$_lkerr" 'not revoked'):$(_lksaid "$_lkout$_lkerr"):$(_lksame)" \
   "refused:not allowed:not revoked:silent:same"
_lkclear; mkdir "$_lkL"; _lkheld="$(_lkstate)"; _lkrun --allow commission
is "with the lock held and neither a grant file nor a stamp, an allow of commission refuses and both stay absent" \
   "$(_lkexit "$_lkrc"):$(_lksaid "$_lkout$_lkerr"):$(_lksame)" "refused:silent:same"
_lkclear; mkdir "$_lkL"; _lkrun --revoke tidy
is "with the lock held and no grant file, a revoke of tidy still refuses and says nothing revoked" \
   "$(_lkexit "$_lkrc"):$(_lksaid "$_lkout$_lkerr")" "refused:silent"

# L3: the advice works. A refused run leaves the lock as it found it, rmdir
# takes it away, and the next run goes through.
_lkset 'tidy\ncommission\n'; mkdir "$_lkL"; _lkrun --revoke commission
if rmdir "$_lkL" 2>/dev/null; then _lkcl=cleared; else _lkcl=stuck; fi
_lkrun --revoke commission
is "rmdir clears the lock a refused run left in place, and the next revoke of commission exits 0, says so and takes the grant" \
   "$_lkcl:$_lkrc:$(_lkrv "$_lkout"):$(_lkallows commission)" "cleared:0:said:no"
is "and the revoke after the rmdir leaves no lock behind" "$(_lklock)" "absent"

# L4: a run that writes nothing takes no lock, and a held one does not stop it.
_lkset 'tidy\n'; mkdir "$_lkL"; _lkrun
is "with the lock held, felix autonomy given neither --allow nor --revoke exits 0, shows the status page and leaves the lock" \
   "$_lkrc:$(_lkhas "$_lkout" 'autonomy for widget'):$(_lklock)" "0:autonomy for widget:empty"

# L8: a refused argument never removes a lock somebody else holds.
_lkset 'tidy\ncommission\n'; mkdir "$_lkL"; _lkrun --revoke Commission
is "with the lock held, a revoke of the unknown capability Commission exits non-zero and leaves the lock in place" \
   "$(_lkexit "$_lkrc"):$(_lklock)" "refused:empty"
_lkrun --revoke tidy --revoke commission
is "with the lock held, a revoke given twice exits non-zero and leaves the lock in place" \
   "$(_lkexit "$_lkrc"):$(_lklock)" "refused:empty"

# L5: no lock outlives the run that took it, however that run ended short of a
# signal. Nothing here held a lock beforehand.
_lkset 'commission\n'; _lkrun --revoke commission
is "a revoke of commission that succeeds leaves no lock" "$_lkrc:$(_lkrv "$_lkout"):$(_lklock)" "0:said:absent"
_lkset 'commission\n'; _lkrun --allow tidy
is "an allow of tidy that succeeds leaves no lock" "$_lkrc:$(_lkhas "$_lkout" 'allowed: tidy'):$(_lklock)" "0:allowed: tidy:absent"
_lkset 'tidy\n'; _lkrun --allow tidy
is "an allow of tidy already granted, which says already allowed, leaves no lock" \
   "$_lkrc:$(_lkhas "$_lkout" 'already allowed: tidy'):$(_lklock)" "0:already allowed: tidy:absent"
_lkset 'commission\n'; _lkrun --revoke tidy
is "a revoke of tidy from a file that does not grant it leaves no lock" "$_lkrc:$(_lklock)" "0:absent"
_lkclear; _lkrun --revoke tidy
is "a revoke of tidy with no grant file leaves no lock" "$_lkrc:$(_lklock)" "0:absent"
_lkset '# a\000b\ncommission\n'; _lkrun --revoke commission
is "a revoke refused over a grant file holding a NUL byte leaves no lock" "$(_lkexit "$_lkrc"):$(_lklock)" "refused:absent"
_lkset 'commission\n'; _lkrun --revoke Commission
is "a revoke refused as an unknown capability leaves no lock" "$(_lkexit "$_lkrc"):$(_lklock)" "refused:absent"
_lkset 'commission\n'; _lkrun --revoke tidy --revoke commission
is "a revoke refused for naming --revoke twice leaves no lock" "$(_lkexit "$_lkrc"):$(_lklock)" "refused:absent"

# L7: the lock is per project. Another project's needs nothing but the lock.
_lkop="$FROOT/projects/gadget"
if [ -e "$_lkop" ]; then _lkop="$(mktemp -d "$FROOT/projects/lockother.XXXXXX")"; else mkdir "$_lkop"; fi
mkdir "$_lkop/autonomy.lock"
_lkset 'tidy\ncommission\n'; _lkrun --revoke commission
is "a lock in another project's directory does not stop a widget revoke of commission" \
   "$_lkrc:$(_lkrv "$_lkout"):$(_lkallows commission):$(_lklock)" "0:said:no:absent"
is "and the other project's lock is left where it was" "$([ -d "$_lkop/autonomy.lock" ] && echo kept || echo gone)" "kept"
rm -rf "$_lkop"

# L6: what a run reports is what holds once every run has ended. Run A, a
# revoke of commission, is paused in the mv that moves its rewrite onto the
# grant file; run B starts and ends; then A is released. B is given 30 s, and
# one that waited for the lock instead of refusing is reported as not ending.
_lkpair() {   # FORMAT ARGS...: the grant file by FORMAT and a stamp; run B, felix autonomy ARGS, while A is paused
  _lkset "$1"; shift
  _lkpaused=unreached; _lkafterb=unreached; _lkbsame=unreached; _lkbended="never started"; _lkbp=""; _lkbrc=""
  _lkgo
  if [ "$_lkreached" = yes ]; then
    _lkpaused="$(_lklock)"; _lkheld="$(_lkstate)"
    ( cd "$REPO" && exec "$FELIX" autonomy "$@" ) > "$TMP/lk-b.out" 2> "$TMP/lk-b.err" 8>&- &
    _lkbp=$!
    if _lkuntil "$_lkbp"; then
      _lkbended=ended; _lkafterb="$(_lklock)"; _lkbsame="$(_lksame)"
    else
      _lkbended="still running after 30 s"; _lkafterb="$_lkbended"; _lkbsame="$_lkbended"
    fi
  fi
  _lkend
  if [ -n "$_lkbp" ]; then
    _lkuntil "$_lkbp" || kill -KILL "$_lkbp" 2>/dev/null
    wait "$_lkbp"; _lkbrc=$?
  fi
  _lkbout="$(cat "$TMP/lk-b.out" 2>/dev/null)"; _lkberr="$(cat "$TMP/lk-b.err" 2>/dev/null)"
  _lkfinal="$(_lklock)"
}
_lkrace() {   # TAG: the assertions every interleaving shares, about the lock, run B and run A
  _lkreq "$1: while A is paused the lock exists and is an empty directory" "$_lkpaused" "empty"
  _lkreq "$1: B ends while A is paused, exits non-zero, and says neither revoked: nor allowed:" \
         "$_lkbended:$(_lkexit "$_lkbrc"):$(_lksaid "$_lkbout$_lkberr")" "ended:refused:silent"
  _lkreq "$1: B names the lock on stderr" "$(_lkhas "$_lkberr" 'projects/widget/autonomy.lock')" \
         "projects/widget/autonomy.lock"
  _lkreq "$1: B leaves the grant file and the stamp byte-identical and adds nothing to the directory" "$_lkbsame" "same"
  _lkreq "$1: after B ends, with A still paused, A's lock is still there and still empty" "$_lkafterb" "empty"
  _lkreq "$1: A exits 0, says revoked: commission, and commission is not granted once both have ended" \
         "$_lkarc:$(_lkhas "$_lkaout" 'revoked: commission'):$(_lkallows commission)" "0:revoked: commission:no"
  _lkreq "$1: the lock A held is gone once both have ended" "$_lkpaused:$_lkfinal" "empty:absent"
}
_lkpair 'tidy\ncommission\n' --revoke tidy
is "writer race (a), a revoke of tidy while a revoke of commission is paused: A pauses in the mv onto the grant file" \
   "$_lkreached" "yes"
_lkrace "writer race (a)"
_lkreq "writer race (a): what each run reported holds once both have ended" \
       "$(_lkclaim "$_lkarc" "$_lkaout$_lkaerr" 'revoked: commission' commission no):$(_lkclaim "$_lkbrc" "$_lkbout$_lkberr" 'revoked: tidy' tidy no)" \
       "holds:holds"
_lkpair 'commission\n' --allow tidy
is "writer race (b), an allow of tidy while a revoke of commission is paused: A pauses in the mv onto the grant file" \
   "$_lkreached" "yes"
_lkrace "writer race (b)"
_lkreq "writer race (b): what each run reported holds once both have ended" \
       "$(_lkclaim "$_lkarc" "$_lkaout$_lkaerr" 'revoked: commission' commission no):$(_lkclaim "$_lkbrc" "$_lkbout$_lkberr" 'allowed: tidy' tidy yes)" \
       "holds:holds"
# (c) has no such assertion: B allows what A revokes, so each run's report is
# excused by the other's and the invariant constrains nothing. What (c) adds is
# B's "already allowed" path, which re-stamps, refused like the rest.
_lkpair 'commission\n' --allow commission
is "writer race (c), an allow of commission while a revoke of commission is paused: A pauses in the mv onto the grant file" \
   "$_lkreached" "yes"
_lkrace "writer race (c)"

# L5, signals: a run killed while it holds the lock takes the lock with it and
# does not go on to say revoked:. SIGINT goes to A's process group, SIGTERM and
# SIGHUP to A alone. A signal this suite was started ignoring (nohup's HUP, a
# backgrounded parent's INT) reaches no child it starts, and is skipped.
_lkprobe() {   # SIG: yes when a bash started as run A is started can trap SIG
  set -m
  ( exec bash -c "trap 'exit 9' $1; kill -$1 \$\$; exit 0" ) > /dev/null 2>&1 8>&- &
  _lkpp=$!
  set +m
  wait "$_lkpp"; [ "$?" = 9 ] && echo yes || echo no
}
_lksig() {   # SIG: run A paused, sent SIG, released and reaped
  _lkset 'tidy\ncommission\n'; _lkpaused=unreached
  _lkgo
  if [ "$_lkreached" = yes ]; then
    _lkpaused="$(_lklock)"
    if [ "$1" = INT ]; then kill -INT -- "-$_lka"; else kill "-$1" "$_lka"; fi
    sleep 0.1
  fi
  _lkend
}
for _lks in TERM INT HUP; do
  _lkn1="a revoke killed with SIG$_lks while it holds the lock leaves no lock behind"
  _lkn2="and the revoke killed with SIG$_lks exits non-zero and does not say revoked:"
  if [ "$(_lkprobe "$_lks")" != yes ]; then
    skip "$_lkn1" "SIG$_lks cannot reach a process this suite starts: it was ignored when the suite began"
    skip "$_lkn2" "SIG$_lks cannot reach a process this suite starts: it was ignored when the suite began"
    continue
  fi
  # The shell's own "Terminated" and "Hangup" notices for A are not output.
  _lksig "$_lks" 2>/dev/null
  _lkreq "$_lkn1" "$_lkpaused:$(_lklock)" "empty:absent"
  _lkreq "$_lkn2" "$(_lkexit "$_lkarc"):$(_lkrv "$_lkaout$_lkaerr")" "refused:silent"
done


# Mutation follow-ups, 2026-10-08. Each pins a case the assertions above could
# not see, and each comment names the mutant of the fix that it kills.

# L1 and L6 under a signal (kills: no HUP/INT/TERM traps). bash runs a trap
# only once the foreground step has returned, so a revoke sent TERM or HUP
# while its move onto the grant file is in flight keeps the lock until that
# move has landed. A shell that died at once instead let the lock go with the
# move still pending: a revoke of tidy started then took the lock and said
# revoked:, and A's stale copy, tidy still in it, landed over it. A run that
# stopped at once is gone well inside the 10 s given; one that waits on its
# move is not.
_lkmid() {   # SIG: run A paused in its move and sent SIG; run B, a revoke of tidy, run meanwhile; both reaped
  _lkset 'tidy\ncommission\n'; _lkpaused=unreached; _lkkept=unreached; _lkbp=""; _lkbrc=""; _lkbended="never started"
  _lkgo
  if [ "$_lkreached" = yes ]; then
    _lkpaused="$(_lklock)"
    kill "-$1" "$_lka"
    _lki=0; while kill -0 "$_lka" 2>/dev/null && [ "$_lki" -lt 100 ]; do sleep 0.1; _lki=$((_lki+1)); done
    _lkkept="$(_lklock)"
    ( cd "$REPO" && exec "$FELIX" autonomy --revoke tidy ) > "$TMP/lk-b.out" 2> "$TMP/lk-b.err" 8>&- &
    _lkbp=$!
    if _lkuntil "$_lkbp"; then _lkbended=ended; else _lkbended="still running after 30 s"; kill -KILL "$_lkbp" 2>/dev/null; fi
    wait "$_lkbp"; _lkbrc=$?
  fi
  _lkend
  _lkbout="$(cat "$TMP/lk-b.out" 2>/dev/null)"; _lkberr="$(cat "$TMP/lk-b.err" 2>/dev/null)"
}
for _lks in TERM HUP; do
  _lkn1="a revoke sent SIG$_lks while its move onto the grant file is in flight holds the lock until that move has landed"
  _lkn2="and a revoke of tidy run while that move is in flight says revoked: only if tidy stays revoked once both have ended"
  if [ "$(_lkprobe "$_lks")" != yes ]; then
    skip "$_lkn1" "SIG$_lks cannot reach a process this suite starts: it was ignored when the suite began"
    skip "$_lkn2" "SIG$_lks cannot reach a process this suite starts: it was ignored when the suite began"
    continue
  fi
  _lkmid "$_lks" 2>/dev/null
  _lkreq "$_lkn1" "$_lkpaused:$_lkkept" "empty:empty"
  _lkreq "$_lkn2" "$_lkbended:$(_lkclaim "$_lkbrc" "$_lkbout$_lkberr" 'revoked: tidy' tidy no)" "ended:holds"
done

# L5 for SIGINT sent to the shell alone, as kill -INT PID sends it, and not to
# its process group as a Ctrl-C does (kills: no INT trap). The move in flight
# lands, and then the run ends, says nothing and lets the lock go. Untrapped,
# bash waiting on a child that survives an INT carries on as if none came, and
# says revoked:.
_lkn1="a revoke sent SIGINT alone, not its process group, while it holds the lock exits non-zero, does not say revoked: and leaves no lock"
if [ "$(_lkprobe INT)" != yes ]; then
  skip "$_lkn1" "SIGINT cannot reach a process this suite starts: it was ignored when the suite began"
else
  _lkint() {
    _lkset 'tidy\ncommission\n'; _lkpaused=unreached
    _lkgo
    if [ "$_lkreached" = yes ]; then _lkpaused="$(_lklock)"; kill -INT "$_lka"; sleep 0.1; fi
    _lkend
  }
  _lkint 2>/dev/null
  _lkreq "$_lkn1" "$_lkpaused:$(_lklock):$(_lkexit "$_lkarc"):$(_lkrv "$_lkaout$_lkaerr")" "empty:absent:refused:silent"
fi

# L2 for a lock of any age (kills: a lock older than N seconds is taken over).
# One found stale is still held: its run may only be slow or stopped (^Z), and
# two runs that both judged it stale would both take it.
_lkset 'tidy\ncommission\n'; mkdir "$_lkL"; touch -t 200001010000 "$_lkL"; _lkheld="$(_lkstate)"; _lkrun --revoke tidy
is "with a lock dated 2000 held, a revoke of tidy refuses, says nothing, writes nothing and leaves the lock" \
   "$(_lkexit "$_lkrc"):$(_lksaid "$_lkout$_lkerr"):$(_lksame):$(_lklock)" "refused:silent:same:empty"

# L2 and L6 after the last write (kills: the lock let go early by hand while
# the exit trap still releases it). A run's exit lets go only of a lock it
# still holds, so it never removes one another run took after its last write.
# Run A, the revoke of commission, is paused a second time, past its last
# write, in the basename its status page calls. Run B, a revoke of commission,
# starts then and pauses in its own move if it got the lock. A is let go and
# ends; run C, a revoke of tidy, runs; then B's move lands.
{ printf '#!/bin/sh\n_d=%s\n' "'$_lksh'"
  cat <<'EOF'
case "$1" in
  */projects/widget)
    if [ -e "$_d/barmed" ] && /bin/rm "$_d/barmed" 2>/dev/null; then
      echo "$$" > "$_d/breached"
      read -r _line < "$_d/brelease"
    fi ;;
esac
exec /usr/bin/basename "$@"
EOF
} > "$_lksh/basename"; chmod +x "$_lksh/basename"
_lklate() {   # sets _lkstage, _lkleft (B's state:the lock once A ended) and C's _lkcrc _lkcout _lkcerr
  _lkset 'tidy\ncommission\n'; _lkstage="A never paused in its move"; _lkleft=unreached
  _lkcrc=""; _lkcout=""; _lkcerr=""; _lkb3=""
  rm -f "$_lksh/breached" "$_lksh/brelease" "$_lksh/barmed"
  _lkgo
  mkfifo "$_lksh/brelease" 2>/dev/null; exec 7<>"$_lksh/brelease"
  if [ "$_lkreached" = yes ]; then
    _lkstage="A never paused in its status page"
    : > "$_lksh/barmed"; rm -f "$_lksh/reached"
    printf 'go\n' >&8
    _lki=0; while [ ! -s "$_lksh/breached" ] && [ "$_lki" -lt 300 ]; do sleep 0.1; _lki=$((_lki+1)); done
    if [ -s "$_lksh/breached" ]; then
      _lkstage=paused
      : > "$_lksh/armed"
      ( cd "$REPO" && PATH="$_lksh:$PATH" exec "$FELIX" autonomy --revoke commission ) \
        > "$TMP/lk-b.out" 2> "$TMP/lk-b.err" 7>&- 8>&- &
      _lkb3=$!
      _lki=0
      while [ ! -s "$_lksh/reached" ] && kill -0 "$_lkb3" 2>/dev/null && [ "$_lki" -lt 300 ]; do
        sleep 0.1; _lki=$((_lki+1))
      done
      if [ -s "$_lksh/reached" ]; then _lkb3st=holding; else _lkb3st=refused; rm -f "$_lksh/armed"; fi
      printf 'go\n' >&7
      _lkuntil "$_lka" || kill -KILL "$_lka" 2>/dev/null
      wait "$_lka"; _lka=""
      _lkleft="$_lkb3st:$(_lklock)"
      _lkrun --revoke tidy; _lkcrc="$_lkrc"; _lkcout="$_lkout"; _lkcerr="$_lkerr"
    fi
  fi
  { printf 'go\n' >&7; } 2>/dev/null; exec 7>&-
  _lkend
  if [ -n "$_lkb3" ]; then _lkuntil "$_lkb3" || kill -KILL "$_lkb3" 2>/dev/null; wait "$_lkb3"; fi
  rm -f "$_lksh/breached" "$_lksh/brelease" "$_lksh/barmed"
}
_lklate 2>/dev/null
case "$_lkleft" in refused:*|holding:empty) _lkverdict="left alone" ;; *) _lkverdict="removed ($_lkleft)" ;; esac
if [ "$_lkstage" = paused ]; then
  is "a run's exit removes no lock another run took after that run's last write" "$_lkverdict" "left alone"
  is "and a revoke of tidy that says revoked: while the other run's move is in flight leaves tidy not granted once all have ended" \
     "$(_lkclaim "$_lkcrc" "$_lkcout$_lkcerr" 'revoked: tidy' tidy no)" "holds"
else
  bad "a run's exit removes no lock another run took after that run's last write" "$_lkstage"
  bad "and a revoke of tidy that says revoked: while the other run's move is in flight leaves tidy not granted once all have ended" "$_lkstage"
fi
rm -f "$_lksh/basename"

# The lock is let go with rmdir, never rm -r (kills: unlock by rm -rf). A lock
# that has gained contents was not made by this run, and is left for a person.
# This pins the fix's choice: L5 as written says no lock outlives the run.
_lkset 'tidy\ncommission\n'; _lkgo
[ "$_lkreached" = yes ] && : > "$_lkL/someone-else"
_lkend 2>/dev/null
_lkreq "a run whose lock gained contents while it held it leaves that lock, contents and all, for a person" \
       "$(_lklock):$([ -e "$_lkL/someone-else" ] && echo kept || echo gone)" "full:kept"
rm -rf "$_lkL"


exec 8>&-
_lkclear; rm -rf "$_lksh"
rm -f "$TMP/lk.out" "$TMP/lk.err" "$TMP/lk-a.out" "$TMP/lk-a.err" "$TMP/lk-b.out" "$TMP/lk-b.err"
for _lkf in "$_lkk"/autonomy*; do { [ -e "$_lkf" ] || [ -L "$_lkf" ]; } && mv "$_lkf" "$_lkp/"; done
rmdir "$_lkk" 2>/dev/null
is "the widget's directory holds exactly what it held before the lock was tested" \
   "$(ls -A "$_lkp" | LC_ALL=C sort)" "$_lkstart"

printf '\nthe writer lock holds under signals, stray output and a person'"'"'s hand\n'
# 2026-10-08, from the two adversarial reviews of the first lock fix (the
# block above). That fix trapped HUP, INT and TERM, so they end a run only
# once the step in flight has returned. Measured against it on bash 3.2:
# every other signal that ends a process by default ended felix at once.
# ALRM, USR1 and the like ran the EXIT trap on the way out, so the lock went
# while the run's own mv was still to land; a revoke of tidy started then
# took the lock, said revoked:, and lost its revoke under the first run's
# stale copy. QUIT and PROF skipped the EXIT trap and left the lock for good.
# So did a closed stdout and a pipe nobody reads: bash kept the text it could
# not write and flushed it into the next command substitution, the exit
# trap's, so rmdir was handed the status page ahead of the lock's path. The
# lock was removed by name, so a run took away a lock somebody had put in its
# place, and one that had gained contents was left without a word. An INT
# that killed the mv left the run's autonomy.new.* behind. And a refusal gave
# a person nothing to judge a stale lock by.
#
# These pin L9 to L16 of that addendum. A run paused in its mv and sent one
# of these signals, to its pid alone, keeps the lock held and empty, and a
# second run is refused, until the mv returns; then it ends non-zero and
# silent, and the lock goes. Seven of the twelve are pinned only by the
# lock's absence at the end, as the addendum asks, and that cannot see a
# lock let go early. A closed stdout or a dead pipe leaks no lock. TERM at
# delays swept across a run's life, and INT to its group every 10 ms, never
# leave one. A run removes only the lock it made, and says so when it leaves
# one that gained contents. A lock of any age is never taken over, and the
# refusal says whether it is more than a minute old and that a stopped run
# still holds its lock. No autonomy.new.* outlives a signal, a refusal or a
# success. Run A is paused in its mv by a shim first on its PATH, as above;
# every helper here is this block's own.
_autonomy_lock_build

# L9: a signal to the run alone never releases the lock while its mv is in
# flight. Run A, a revoke of commission over tidy and commission, is paused in
# its mv and sent SIG to its pid alone. Half a second later, with the mv still
# paused, the lock is read, and with B given, run B, a revoke of tidy, runs in
# that window. Then A's mv is released.
_lwwin() {   # SIG [B]
  _lwset 'tidy\ncommission\n'
  _lwsigheld=unreached; _lwafterb=unreached; _lwbsame=unreached; _lwbrc="never started"; _lwbout=""; _lwberr=""
  _lwgo --revoke commission
  if [ "$_lwreached" = yes ]; then
    kill "-$1" "$_lwa" 2>/dev/null
    _lwbrief
    _lwsp="$(cat "$_lwsh/reached" 2>/dev/null)"
    if [ -n "$_lwsp" ] && kill -0 "$_lwsp" 2>/dev/null; then _lwmv=paused; else _lwmv=gone; fi
    _lwsigheld="$(_lwlock):mv $_lwmv"
    if [ -n "${2:-}" ]; then
      _lwheld="$(_lwstate)"
      ( cd "$REPO" && exec "$FELIX" autonomy --revoke tidy ) > "$TMP/lw-b.out" 2> "$TMP/lw-b.err" 8>&- &
      _lwreap $!; _lwbrc="$_lwrc"
      _lwafterb="$(_lwlock)"; _lwbsame="$(_lwsame)"
      _lwbout="$(cat "$TMP/lw-b.out")"; _lwberr="$(cat "$TMP/lw-b.err")"
    fi
  fi
  _lwend
  _lwfinal="$(_lwlock)"; _lwleft="$(_lwnew)"
}
for _lws in TERM HUP ALRM USR1 INT; do
  _lwt="a revoke of commission paused in its mv and sent SIG$_lws to its pid alone"
  _lwn1="$_lwt: half a second on, the mv still paused, the lock is still there and still empty"
  _lwn2="$_lwt: a revoke of tidy started then ends, exits non-zero, says neither revoked: nor allowed:, and names the lock, rmdir and not revoked"
  _lwn3="$_lwt: that revoke of tidy leaves the grant file, the stamp and the directory as they were, and the lock still empty"
  _lwn4="$_lwt: once the mv is released, it exits non-zero and says neither revoked: nor allowed:"
  _lwn5="$_lwt: the lock is gone once both runs have ended"
  _lwn6="$_lwt: what each run reported holds once both have ended"
  _lwn7="$_lwt: no autonomy.new.* is left in the widget's directory"
  if [ "$(_lwprobe "$_lws")" != yes ]; then
    for _lwn in "$_lwn1" "$_lwn2" "$_lwn3" "$_lwn4" "$_lwn5" "$_lwn6" "$_lwn7"; do skip "$_lwn" "$(_lwign "$_lws")"; done
    continue
  fi
  # The shell's own notices for A ("Terminated", "Alarm clock") are not output.
  _lwwin "$_lws" B 2>/dev/null
  _lwreq "$_lwn1" "$_lwsigheld" "empty:mv paused"
  _lwreq "$_lwn2" \
         "$(_lwended "$_lwbrc"):$(_lwexit "$_lwbrc"):$(_lwsaid "$_lwbout$_lwberr"):$(_lwhas "$_lwberr" 'projects/widget/autonomy.lock'):$(_lwhas "$_lwberr" rmdir):$(_lwhas "$_lwberr" 'not revoked')" \
         "ended:non-zero:silent:projects/widget/autonomy.lock:rmdir:not revoked"
  _lwreq "$_lwn3" "$_lwbsame:$_lwafterb" "same:empty"
  _lwreq "$_lwn4" "$(_lwexit "$_lwarc"):$(_lwsaid "$_lwaout$_lwaerr")" "non-zero:silent"
  _lwreq "$_lwn5" "$_lwfinal" "absent"
  _lwreq "$_lwn6" \
         "$(_lwclaim "$_lwarc" "$_lwaout$_lwaerr" 'revoked: commission' commission no):$(_lwclaim "$_lwbrc" "$_lwbout$_lwberr" 'revoked: tidy' tidy no)" \
         "holds:holds"
  _lwreq "$_lwn7" "$_lwleft" "0"
done
# The rest are pinned only as the contract asks: no lock once it has ended,
# and no revoked:.
for _lws in QUIT PIPE USR2 XCPU XFSZ VTALRM PROF; do
  _lwn1="a revoke of commission paused in its mv and sent SIG$_lws to its pid alone leaves no lock once it has ended, and does not say revoked:"
  if [ "$(_lwprobe "$_lws")" != yes ]; then skip "$_lwn1" "$(_lwign "$_lws")"; continue; fi
  _lwwin "$_lws" 2>/dev/null
  _lwreq "$_lwn1" "$_lwfinal:$(_lwrv "$_lwaout$_lwaerr")" "absent:silent"
done

# L10: output that cannot be written leaks no lock. Closed is >&-. The pipe is
# a FIFO the run is handed the write end of after its only reader has closed,
# so the first line the run writes gets EPIPE and SIGPIPE, every time: the
# suite opens it read-write (a reader, so its own open for writing does not
# wait), opens that write end, then closes the read-write descriptor before
# the run starts. A reader process that exits at once would race the run's
# first write unless reaped first, and this has no reader to reap. After
# each, the next writing run, a revoke of commission, is not refused.
_lwdead() {   # HOW FORMAT ARGS...: felix autonomy ARGS over FORMAT, stdout closed (HOW closed) or a dead pipe (HOW pipe)
  _lwhow="$1"; _lwset "$2"; shift 2
  if [ "$_lwhow" = closed ]; then
    ( cd "$REPO" && exec "$FELIX" autonomy "$@" ) >&- 2> "$TMP/lw.err" 8>&- &
    _lwreap $!
  else
    rm -f "$TMP/lw-pipe"; mkfifo "$TMP/lw-pipe" 2>/dev/null
    if [ -p "$TMP/lw-pipe" ]; then
      exec 7<>"$TMP/lw-pipe"; exec 6>"$TMP/lw-pipe"; exec 7<&-
      ( cd "$REPO" && exec "$FELIX" autonomy "$@" ) >&6 2> "$TMP/lw.err" 6>&- 8>&- &
      _lwreap $!
      exec 6>&-
    else _lwrc="no FIFO"; fi
    rm -f "$TMP/lw-pipe"
  fi
  _lwdrc="$_lwrc"; _lwdl="$(_lwlock)"
  _lwrun --revoke commission
}
for _lwhow in closed pipe; do
  if [ "$_lwhow" = closed ]; then _lwt="whose stdout is closed"; else _lwt="whose stdout is a pipe its reader has already left"; fi
  _lwdead "$_lwhow" 'tidy\ncommission\n' --revoke tidy 2>/dev/null
  is "a revoke of tidy $_lwt ends and leaves no lock, and the next revoke, of commission, exits 0 and says so" \
     "$(_lwended "$_lwdrc"):$_lwdl:$(_lwexit "$_lwrc"):$(_lwrv "$_lwout")" "ended:absent:exit 0:said"
  _lwdead "$_lwhow" 'commission\n' --allow tidy 2>/dev/null
  is "an allow of tidy $_lwt ends and leaves no lock, and the next revoke, of commission, exits 0 and says so" \
     "$(_lwended "$_lwdrc"):$_lwdl:$(_lwexit "$_lwrc"):$(_lwrv "$_lwout")" "ended:absent:exit 0:said"
done

# L11: a signal at any moment leaves no lock, taking and releasing included.
# A writing run's length is measured here, in the 0.1 s ticks the sweep
# sleeps in, so the sweep follows this machine's load. Then 16 runs are each
# sent TERM, to the pid alone, at delays spread from 0 to a quarter past the
# longer of the two, and 16 more are sent INT, to their process group, every
# 10 ms from such a delay until they end: 32 runs, 16 delays each way rather
# than every tick, to keep the block to a few minutes at a load of several
# hundred. Even runs revoke tidy and odd ones allow it. Each starts under job
# control, so INT is not ignored and the group is its own.
_lwlife() {   # FORMAT ARGS...: one writing run over FORMAT, no signal; _lwticks is its length in ticks, _lwlrc its status
  _lwset "$1"; shift
  ( cd "$REPO" && exec "$FELIX" autonomy "$@" ) > /dev/null 2>&1 8>&- &
  _lwlp=$!; _lwticks=0
  while kill -0 "$_lwlp" 2>/dev/null && [ "$_lwticks" -lt 300 ]; do sleep 0.1; _lwticks=$((_lwticks+1)); done
  _lwreap "$_lwlp"; _lwlrc="$_lwrc"
}
_lwlife 'tidy\ncommission\n' --revoke tidy; _lwd1="$_lwticks"; _lwr1="$(_lwexit "$_lwlrc"):$(_lwlock)"
_lwlife 'commission\n' --allow tidy; _lwd2="$_lwticks"; _lwr2="$(_lwexit "$_lwlrc"):$(_lwlock)"
is "a revoke and an allow sent no signal each exit 0 and leave no lock: the sweeps below are timed against them" \
   "$_lwr1:$_lwr2" "exit 0:absent:exit 0:absent"
_lwdur="$_lwd1"; [ "$_lwd2" -gt "$_lwdur" ] && _lwdur="$_lwd2"
_lwtop=$(( _lwdur + _lwdur / 4 + 1 ))
_lwsweep() {   # HOW: TERM, once to the pid alone, or INT, to the group every 10 ms until the run ends
  _lwleft=""; _lwcut=0; _lwj=0
  while [ "$_lwj" -lt 16 ]; do
    _lwd=$(( _lwj * _lwtop / 15 ))
    if [ $(( _lwj % 2 )) = 0 ]; then _lwset 'tidy\ncommission\n'; _lwv=--revoke; else _lwset 'commission\n'; _lwv=--allow; fi
    set -m
    ( ulimit -c 0 2>/dev/null; cd "$REPO" && exec "$FELIX" autonomy "$_lwv" tidy ) > /dev/null 2>&1 8>&- &
    _lwsr=$!
    set +m
    _lwi=0; while [ "$_lwi" -lt "$_lwd" ]; do sleep 0.1; _lwi=$((_lwi+1)); done
    if [ "$1" = TERM ]; then kill -TERM "$_lwsr" 2>/dev/null
    else
      _lwi=0
      while [ "$_lwi" -lt 3000 ] && kill -0 "$_lwsr" 2>/dev/null; do
        kill -INT -- "-$_lwsr" 2>/dev/null; sleep 0.01; _lwi=$((_lwi+1))
      done
    fi
    _lwreap "$_lwsr"
    case "$_lwrc" in 0) ;; *[!0-9]*) _lwleft="$_lwleft $_lwv@${_lwd}:hung" ;; *) _lwcut=$((_lwcut+1)) ;; esac
    if [ "$(_lwlock)" != absent ]; then _lwleft="$_lwleft $_lwv@$_lwd"; rm -rf "$_lwL"; fi
    _lwj=$((_lwj+1))
  done
  [ -n "$_lwleft" ] || _lwleft=none
}
_lwn1="TERM sent to a writing run alone, at 16 delays from 0 to past its usual length, cuts at least one run short"
_lwn2="and no run sent TERM at any of those delays leaves a lock, or runs on"
if [ "$(_lwprobe TERM)" != yes ]; then skip "$_lwn1" "$(_lwign TERM)"; skip "$_lwn2" "$(_lwign TERM)"
else
  _lwsweep TERM 2>/dev/null
  is "$_lwn1" "$([ "$_lwcut" -ge 1 ] && echo cut || echo "none of 16 cut")" "cut"
  is "$_lwn2" "$_lwleft" "none"
fi
_lwn1="INT sent to a writing run's process group every 10 ms, from 16 delays across its life, cuts at least one run short"
_lwn2="and no run sent that held-down INT leaves a lock, or runs on"
if [ "$(_lwprobe INT)" != yes ]; then skip "$_lwn1" "$(_lwign INT)"; skip "$_lwn2" "$(_lwign INT)"
else
  _lwsweep INT 2>/dev/null
  is "$_lwn1" "$([ "$_lwcut" -ge 1 ] && echo cut || echo "none of 16 cut")" "cut"
  is "$_lwn2" "$_lwleft" "none"
fi

# L12: a run removes only the lock it made. With A paused, its lock is
# replaced by another directory at the same path: made under $FROOT, on the
# same filesystem, while A's still exists, so it cannot have A's inode; given
# A's lock's mode; then A's is rmdir'd and the new one moved in.
_lwset 'tidy\ncommission\n'; _lwswap=unreached; _lwrepl=""
_lwgo --revoke commission
if [ "$_lwreached" = yes ]; then
  _lwswap=failed
  _lwmode="$(stat -c %a "$_lwL" 2>/dev/null || stat -f %Lp "$_lwL" 2>/dev/null)"
  if _lwrepl="$(mktemp -d "$FROOT/lw-lock.XXXXXX")"; then
    [ -z "$_lwmode" ] || chmod "$_lwmode" "$_lwrepl"
    rmdir "$_lwL" && mv "$_lwrepl" "$_lwL" && _lwswap=swapped
  fi
fi
_lwend
_lwreq "a revoke whose lock was replaced by another directory while its mv was paused leaves the new lock in place, still empty" \
       "$_lwswap:$(_lwlock)" "swapped:empty"
[ -z "$_lwrepl" ] || rm -rf "$_lwrepl"

# L13: a lock that gains contents while held is left for a person, and said.
_lwset 'tidy\ncommission\n'; _lwput=unreached
_lwgo --revoke commission
if [ "$_lwreached" = yes ]; then printf 'a person was here\n' > "$_lwL/note" && _lwput=put || _lwput=failed; fi
_lwend
_lwreq "a revoke whose lock gained a file while its mv was paused leaves the lock with that file in it" \
       "$_lwput:$(_lwlock):$([ -f "$_lwL/note" ] && echo kept || echo gone)" "put:full:kept"
_lwreq "and the revoke whose lock gained a file names the lock on stderr and says it was not removed" \
       "$(_lwhas "$_lwaerr" 'projects/widget/autonomy.lock'):$(_lwhas "$_lwaerr" 'not removed')" \
       "projects/widget/autonomy.lock:not removed"
_lwreq "and what the revoke whose lock gained a file reported holds" \
       "$(_lwclaim "$_lwarc" "$_lwaout$_lwaerr" 'revoked: commission' commission no)" "holds"

# L14 and L15: a held lock is never taken over, however old, and the refusal
# helps a person judge it: more than a minute old or not, that a stopped run
# (Ctrl-Z) still holds its lock, and, as L2 already asks, its path and rmdir.
_lwmtime() { stat -c %Y "$_lwL" 2>/dev/null || stat -f %m "$_lwL" 2>/dev/null; }
_lwdated() {   # the lock's year 2000 as touch -t gave it in any time zone, or what it is instead
  _lwm="$(_lwmtime)"
  case "$_lwm" in
    ''|*[!0-9]*) echo "no time" ;;
    *) if [ "$_lwm" -ge 946598400 ] && [ "$_lwm" -lt 978307200 ]; then echo "dated 2000"; else echo "dated $_lwm"; fi ;;
  esac
}
_lwset 'tidy\ncommission\n'; mkdir "$_lwL"; touch -t 200001010000 "$_lwL"
_lwid0="$(_lwid)"; _lwheld="$(_lwstate)"
_lwrun --revoke commission
is "with a lock dated 2000 held, a revoke of commission exits non-zero, says neither revoked: nor allowed:, and writes nothing" \
   "$(_lwexit "$_lwrc"):$(_lwsaid "$_lwout$_lwerr"):$(_lwsame)" "non-zero:silent:same"
is "and the refusal over the lock dated 2000 names the lock, says rmdir, and says not revoked" \
   "$(_lwhas "$_lwerr" 'projects/widget/autonomy.lock'):$(_lwhas "$_lwerr" rmdir):$(_lwhas "$_lwerr" 'not revoked')" \
   "projects/widget/autonomy.lock:rmdir:not revoked"
is "and the lock dated 2000 is left exactly where it was: the same directory, still empty, still dated 2000" \
   "$(_lwlock):$(_lwid):$(_lwdated)" "empty:$_lwid0:dated 2000"
is "and the refusal over the lock dated 2000 says it is more than a minute old" \
   "$(_lwhas "$_lwerr" 'more than a minute old')" "more than a minute old"
is "and the refusal over the lock dated 2000 says a stopped run still holds its lock" \
   "$(_lwhas "$_lwerr" stopped)" "stopped"
is "and the revoke refused by the lock dated 2000 leaves no autonomy.new.* in the widget's directory" "$(_lwnew)" "0"
# Ten minutes back: an age a person meets after a killed run, nowhere near
# 2000. Skipped where this machine's date can do neither -v nor -d.
_lwn1="with a lock dated ten minutes ago held, an allow of tidy refuses and says the lock is more than a minute old"
_lwn2="and the allow refused by the lock dated ten minutes ago leaves no autonomy.new.* in the widget's directory"
_lwago="$(date -v-10M +%Y%m%d%H%M 2>/dev/null || date -d '10 minutes ago' +%Y%m%d%H%M 2>/dev/null)"
case "$_lwago" in
  [0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9])
    _lwset 'commission\n'; mkdir "$_lwL"; touch -t "$_lwago" "$_lwL"
    _lwm="$(_lwmtime)"; _lwnow="$(date +%s)"
    if [ $(( _lwnow - ${_lwm:-$_lwnow} )) -gt 120 ]; then _lwold=older; else _lwold="not older than 2 minutes"; fi
    _lwrun --allow tidy
    is "$_lwn1" "$(_lwexit "$_lwrc"):$(_lwsaid "$_lwout$_lwerr"):$(_lwhas "$_lwerr" 'more than a minute old'):$_lwold" \
       "non-zero:silent:more than a minute old:older"
    is "$_lwn2" "$(_lwnew)" "0" ;;
  *) skip "$_lwn1" "date cannot name ten minutes ago here"; skip "$_lwn2" "date cannot name ten minutes ago here" ;;
esac
_lwset 'tidy\ncommission\n'; mkdir "$_lwL"; _lwrun --revoke commission
is "with a lock made just now held, a revoke of commission refuses and does not say the lock is more than a minute old" \
   "$(_lwexit "$_lwrc"):$(_lwhas "$_lwerr" 'more than a minute old')" "non-zero:no [more than a minute old]"
is "and the refusal over the lock made just now names the lock, says rmdir, and says a stopped run still holds its lock" \
   "$(_lwhas "$_lwerr" 'projects/widget/autonomy.lock'):$(_lwhas "$_lwerr" rmdir):$(_lwhas "$_lwerr" stopped):$(_lwlock)" \
   "projects/widget/autonomy.lock:rmdir:stopped:empty"

# L16: no autonomy.new.* outlives a run short of SIGKILL. The signals sent to
# the pid alone and the held-lock refusals are counted above. Here: INT to
# the process group, which kills the paused mv before it moves anything, for
# a revoke and an allow; the refusal of a grant file holding a NUL byte; and
# success.
_lwgrp() {   # FORMAT ARGS...: run A, felix autonomy ARGS over FORMAT, paused in its mv, sent INT to its group, then released
  _lwset "$1"; shift
  _lwgo "$@"
  if [ "$_lwreached" = yes ]; then kill -INT -- "-$_lwa" 2>/dev/null; _lwbrief; fi
  _lwend
  _lwfinal="$(_lwlock)"; _lwleft="$(_lwnew)"
}
_lwn1="a revoke of commission paused in its mv and sent INT to its process group leaves no autonomy.new.* in the widget's directory"
_lwn2="an allow of tidy paused in its mv and sent INT to its process group leaves no lock, and reports no grant that does not hold"
_lwn3="and that allow of tidy sent INT to its process group leaves no autonomy.new.* in the widget's directory"
if [ "$(_lwprobe INT)" != yes ]; then
  for _lwn in "$_lwn1" "$_lwn2" "$_lwn3"; do skip "$_lwn" "$(_lwign INT)"; done
else
  _lwgrp 'tidy\ncommission\n' --revoke commission 2>/dev/null
  _lwreq "$_lwn1" "$_lwleft" "0"
  _lwgrp 'commission\n' --allow tidy 2>/dev/null
  _lwreq "$_lwn2" "$_lwfinal:$(_lwclaim "$_lwarc" "$_lwaout$_lwaerr" 'allowed: tidy' tidy yes)" "absent:holds"
  _lwreq "$_lwn3" "$_lwleft" "0"
fi
_lwset '# a\000b\ncommission\n'; _lwrun --revoke commission
is "a revoke refused over a grant file holding a NUL byte leaves no autonomy.new.* in the widget's directory" \
   "$(_lwexit "$_lwrc"):$(_lwnew)" "non-zero:0"
_lwset '# a\000b\n'; _lwrun --allow tidy
is "an allow refused over a grant file holding a NUL byte leaves no autonomy.new.* in the widget's directory" \
   "$(_lwexit "$_lwrc"):$(_lwnew)" "non-zero:0"
_lwset 'tidy\ncommission\n'; _lwrun --revoke commission
is "a revoke of commission that succeeds leaves no autonomy.new.* in the widget's directory" \
   "$(_lwexit "$_lwrc"):$(_lwrv "$_lwout"):$(_lwnew)" "exit 0:said:0"
_lwset 'commission\n'; _lwrun --allow tidy
is "an allow of tidy that succeeds leaves no autonomy.new.* in the widget's directory" \
   "$(_lwexit "$_lwrc"):$(_lwhas "$_lwout" 'allowed: tidy'):$(_lwnew)" "exit 0:allowed: tidy:0"

# 2026-10-08, the lock's second adversarial review (of revision 2), pinned
# against its revision 3. NOT BLIND: written by that reviewer after reading
# the fix, so these test what the fix does as well as what was found. Each
# was red against a068acb3 unless its comment says otherwise. They use this
# block's helpers, its widget and its mv shim.
#
# F1. bash runs any pending trap before each command it starts, the EXIT
# trap's first command included. A signal that landed after a run's last
# command and before its release ran its handler there, and the handler's
# exit ended the EXIT trap, which bash never runs twice: the lock stayed,
# and so did a temp file. The reviewer hit it by sending TERM just after a
# run's last line, in 4 to 10 runs of 100. No timing from here can aim at a
# gap of microseconds, so this builds the state bash is in then: a shell that
# holds the widget's lock and a temp file and exits through an EXIT trap that
# runs the TERM handler first and its release after, as bash does.
_lwset 'tidy\n'
bash -c 'set -uo pipefail; . "$1/harness/lib/autonomy.sh"
  felix_autonomy_guard "$2" || exit 7
  _FELIX_AUTONOMY_TMP="$(mktemp "$2/autonomy.new.XXXXXX")" || exit 8
  trap "_felix_autonomy_signalled TERM; _felix_autonomy_release" EXIT
  exit 0' _ "$FROOT" "$_lwp" 8>&- 2>/dev/null
_lwrc=$?
is "a run holding the lock and a temp file, whose exit trap begins by running the TERM handler as a TERM pending then makes it, ends 143 and leaves no lock and no autonomy.new.*" \
   "$_lwrc:$(_lwlock):$(_lwnew)" "143:absent:0"
# The release clears what it released, so the exit trap's own call after the
# handler's takes nothing, not even a lock another run has made at the path
# since. Green against a068acb3 too: it pins what F1's fix leans on.
_lwset 'tidy\n'
bash -c 'set -uo pipefail; . "$1/harness/lib/autonomy.sh"
  felix_autonomy_guard "$2" || exit 7
  _felix_autonomy_release; mkdir "$2/autonomy.lock" || exit 8
  exit 0' _ "$FROOT" "$_lwp" 8>&- 2>/dev/null
_lwrc=$?
is "a release run a second time, by the exit trap after a handler ran it, leaves the lock another run made at the path in between" \
   "$_lwrc:$(_lwlock)" "0:empty"

# F2. Once an EXIT trap is set, bash also ends at once on ABRT, TRAP, SYS and
# EMT, running its EXIT trap with the mv still in flight (bash's handlers for
# its terminating signals: bash 5.2 sig.c, and CHECK_TERMSIG in jobs.c's
# wait). The lock went, and a revoke of tidy took it and said revoked:.
# These wait now, as the five above do. EMT is macOS's; Linux has none, and
# it is skipped where kill -l does not know it. ILL, FPE, BUS and SEGV wait
# the same way since revision 4 (below).
for _lws in ABRT TRAP SYS EMT ILL FPE BUS SEGV; do
  _lwt="a revoke of commission paused in its mv and sent SIG$_lws to its pid alone"
  _lwn1="$_lwt: half a second on, the mv still paused, the lock is still there and still empty"
  _lwn2="$_lwt: a revoke of tidy started then ends, exits non-zero, says neither revoked: nor allowed:, and names the lock, rmdir and not revoked"
  _lwn3="$_lwt: that revoke of tidy leaves the grant file, the stamp and the directory as they were, and the lock still empty"
  _lwn4="$_lwt: once the mv is released, it exits non-zero and says neither revoked: nor allowed:"
  _lwn5="$_lwt: the lock is gone once both runs have ended"
  _lwn6="$_lwt: what each run reported holds once both have ended"
  _lwn7="$_lwt: no autonomy.new.* is left in the widget's directory"
  if ! kill -l "$_lws" > /dev/null 2>&1; then
    for _lwn in "$_lwn1" "$_lwn2" "$_lwn3" "$_lwn4" "$_lwn5" "$_lwn6" "$_lwn7"; do skip "$_lwn" "SIG$_lws does not exist on this platform"; done
    continue
  fi
  if [ "$(_lwprobe "$_lws")" != yes ]; then
    for _lwn in "$_lwn1" "$_lwn2" "$_lwn3" "$_lwn4" "$_lwn5" "$_lwn6" "$_lwn7"; do skip "$_lwn" "$(_lwign "$_lws")"; done
    continue
  fi
  _lwwin "$_lws" B 2>/dev/null
  _lwreq "$_lwn1" "$_lwsigheld" "empty:mv paused"
  _lwreq "$_lwn2" \
         "$(_lwended "$_lwbrc"):$(_lwexit "$_lwbrc"):$(_lwsaid "$_lwbout$_lwberr"):$(_lwhas "$_lwberr" 'projects/widget/autonomy.lock'):$(_lwhas "$_lwberr" rmdir):$(_lwhas "$_lwberr" 'not revoked')" \
         "ended:non-zero:silent:projects/widget/autonomy.lock:rmdir:not revoked"
  _lwreq "$_lwn3" "$_lwbsame:$_lwafterb" "same:empty"
  _lwreq "$_lwn4" "$(_lwexit "$_lwarc"):$(_lwsaid "$_lwaout$_lwaerr")" "non-zero:silent"
  _lwreq "$_lwn5" "$_lwfinal" "absent"
  _lwreq "$_lwn6" \
         "$(_lwclaim "$_lwarc" "$_lwaout$_lwaerr" 'revoked: commission' commission no):$(_lwclaim "$_lwbrc" "$_lwbout$_lwberr" 'revoked: tidy' tidy no)" \
         "holds:holds"
  _lwreq "$_lwn7" "$_lwleft" "0"
done
# Revision 3 ignored ILL, FPE, BUS and SEGV, and a child inherits an ignored
# signal: on macOS a child that really faulted spun instead of dying, and the
# run hung holding the lock (the lock's third review, not blind). Revision 4
# traps them, as the loop above shows, and a trapped signal is reset in every
# child. An mv first on the run's PATH that sends itself SEGV stands for a
# child that faults: at its default it dies, and ignored it lives on and
# moves the file.
mkdir -p "$TMP/lw-fault"; rm -f "$TMP/lw-fault/lived"
{ printf '#!/bin/sh\nkill -SEGV $$\n'
  printf ': > %s\n' "'$TMP/lw-fault/lived'"
  printf 'exec %s "$@"\n' "'$(command -v mv)'"
} > "$TMP/lw-fault/mv"; chmod +x "$TMP/lw-fault/mv"
_lwset 'tidy\ncommission\n'; _lwheld="$(_lwstate)"
( cd "$REPO" && PATH="$TMP/lw-fault:$PATH" exec "$FELIX" autonomy --revoke commission ) > "$TMP/lw.out" 2> "$TMP/lw.err" 8>&- &
_lwreap $!; _lwout="$(cat "$TMP/lw.out")"; _lwerr="$(cat "$TMP/lw.err")"
is "a revoke whose mv takes SIGSEGV: the mv dies of it, and the run exits non-zero, says commission is not revoked and no revoked:, and leaves the widget's files as they were, no lock and no autonomy.new.* (not blind)" \
   "$([ -e "$TMP/lw-fault/lived" ] && echo lived || echo died):$(_lwexit "$_lwrc"):$(_lwrv "$_lwout"):$(_lwhas "$_lwerr" 'commission is not revoked'):$(_lwsame):$(_lwlock):$(_lwnew)" \
   "died:non-zero:silent:commission is not revoked:same:absent:0"

