# tests/lib/autonomy-lock.sh: what the autonomy parts share. The revoke helpers
# of 0571 that 0574 uses, and the helpers of the writer-lock block of 0573 that
# 0574 finishes.
# Used by 0571 (_rv* and _rw* helpers, builds _rwu), 0573 (builds the lock
# block), 0574 (both). Moved from parts/0571-revoke-is-the-inverse-of-the-reader.sh:
# _rvallows _rvset _rvrest _rvstamp (lines 13-18, 24), _rwal _rwboth _rwuis _rwcli
# _rwloc _rwexit _rwsaid _rwis (lines 133-148, 152), _r3cmp and _r3has (lines
# 320-321), _r4cut (lines 553-556); _rwu from lines 129-132. From
# parts/0573-the-autonomy-file-has-one-writer-at-a-time.sh lines 478-600: every
# _lw helper from _lwallows to _lwbrief, and the statements that set the block
# up (the widget's autonomy entries moved aside to $_lwk, the mv shim).
# Definitions only. _autonomy_revoke_vars sets RVP, which 0100 also assigns for
# its own review home, so it is set by the call and not at source time, and the
# UTF-8 locale _rwu. _autonomy_lock_build sets _lwp _lwL _lwk _lwsh first and
# does nothing more once $_lwk is there: in the serial run 0573's call moves the
# entries aside and 0574's call finds that done, and the entries go back at the
# end of the block, which sits in 0574.

_rvallows() { ( . "$FROOT/harness/lib/autonomy.sh"; felix_autonomy_allows "$RVP" "$1" && echo yes || echo no ); }
_rvset() {   # FORMAT: F written by printf FORMAT, beside a stamp for commission, and nothing else named autonomy*
  rm -f "$RVP"/autonomy*; printf "$1" > "$RVP/autonomy"; printf 'stamp\n' > "$RVP/autonomy.commission"
  _rvbefore="$(_rvrest)"
}
_rvrest() { ls -A "$RVP" | LC_ALL=C sort | grep -vxF autonomy.commission; }   # the directory, less the stamp
_rvstamp() { [ -e "$RVP/autonomy.commission" ] && echo kept || echo gone; }
_rwal() {   # LOCALE CAP: the reader's verdict on the widget's file, under LC_ALL=LOCALE
  ( export LC_ALL="$1"; . "$FROOT/harness/lib/autonomy.sh"
    felix_autonomy_allows "$RVP" "$2" && echo yes || echo no ) 2>/dev/null
}
_rwboth() { printf '%s:%s' "$(_rwal C "$1")" "$(_rwal "${_rwu:-C}" "$1")"; }   # CAP: under C, then UTF-8
_rwuis() { if [ -n "$_rwu" ]; then is "$@"; else skip "$1" "no UTF-8 locale is installed"; fi; }
_rwcli() {   # ARGS...: felix autonomy ARGS from the widget checkout; sets _rvrc _rvout _rverr
  ( cd "$REPO" && "$FELIX" autonomy "$@" ) > "$TMP/rv.out" 2> "$TMP/rv.err"; _rvrc=$?
  _rvout="$(cat "$TMP/rv.out")"; _rverr="$(cat "$TMP/rv.err")"
}
_rwloc() {   # LOCALE CAP: felix autonomy --revoke CAP run under LC_ALL=LOCALE
  ( export LC_ALL="$1"; cd "$REPO" && "$FELIX" autonomy --revoke "$2" ) > "$TMP/rv.out" 2> "$TMP/rv.err"; _rvrc=$?
  _rvout="$(cat "$TMP/rv.out")"; _rverr="$(cat "$TMP/rv.err")"
}
_rwexit() { [ "$_rvrc" -ne 0 ] && echo refused || echo "exit $_rvrc"; }
_rwsaid() { case "$_rvout$_rverr" in *"$1"*) echo said ;; *) echo silent ;; esac; }   # WORD on stdout or stderr
_rwis() { cmp -s "$TMP/rw.want" "$RVP/autonomy" && echo same || echo differs; }
_r3cmp() { cmp -s "$1" "$2" && echo same || echo differs; }   # A B
_r3has() { case "$1" in *"$2"*) echo "$3" ;; *) echo "$4" ;; esac; }   # TEXT WORD IF-HELD IF-NOT
_r4cut() {   # CAP: felix autonomy --revoke CAP under C, SIGXFSZ ignored, files limited to 2 blocks
  _rvout="$( ( trap '' XFSZ; ulimit -f 2; export LC_ALL=C; cd "$REPO" && "$FELIX" autonomy --revoke "$1" ) 2> "$TMP/rv.err" )"
  _rvrc=$?; _rverr="$(cat "$TMP/rv.err")"
}

_autonomy_revoke_vars() {
  RVP="$FROOT/projects/widget"
  [ -n "${_rwu+x}" ] && return 0
  _rwnl=$'\n'; _rwlocs="$(locale -a 2>/dev/null)"; _rwu=""
  for _rwl in en_US.UTF-8 C.UTF-8 en_US.utf8 C.utf8; do
    case "$_rwnl$_rwlocs$_rwnl" in *"$_rwnl$_rwl$_rwnl"*) _rwu="$_rwl"; break ;; esac
  done
}

_lwallows() { ( . "$FROOT/harness/lib/autonomy.sh"; felix_autonomy_allows "$_lwp" "$1" && echo yes || echo no ); }
_lwclear() { rm -rf "$_lwp"/autonomy*; }   # every autonomy* entry of the widget: the lock and any autonomy.new.* too
_lwset() {   # FORMAT: the grant file written by printf FORMAT, beside a stamp for commission, and no lock
  _lwclear; printf "$1" > "$_lwp/autonomy"; printf 'stamp\n' > "$_lwp/autonomy.commission"
}
_lwstate() {   # the grant file and the stamp, each by checksum or as absent, then every name in the directory
  for _lwn in autonomy autonomy.commission; do
    if [ -e "$_lwp/$_lwn" ]; then printf '%s %s\n' "$_lwn" "$(cksum < "$_lwp/$_lwn")"
    else printf '%s absent\n' "$_lwn"; fi
  done
  ls -A "$_lwp" | LC_ALL=C sort
}
_lwsame() { [ "$(_lwstate)" = "$_lwheld" ] && echo same || echo changed; }   # against _lwstate as _lwheld recorded it
_lwlock() {   # the lock: absent, empty (a directory holding nothing), full, or other (not a directory)
  if [ -L "$_lwL" ]; then echo other
  elif [ ! -e "$_lwL" ]; then echo absent
  elif [ ! -d "$_lwL" ]; then echo other
  elif [ -n "$(ls -A "$_lwL" 2>/dev/null)" ]; then echo full
  else echo empty; fi
}
_lwnew() {   # how many autonomy.new.* entries the widget's directory holds
  _lwc=0
  for _lwf in "$_lwp"/autonomy.new.*; do { [ -e "$_lwf" ] || [ -L "$_lwf" ]; } && _lwc=$((_lwc+1)); done
  echo "$_lwc"
}
_lwid() {   # the lock's inode and modification time, in seconds
  stat -c '%i %Y' "$_lwL" 2>/dev/null || stat -f '%i %m' "$_lwL" 2>/dev/null
}
_lwexit() { case "$1" in 0) echo "exit 0" ;; ''|*[!0-9]*) echo "${1:-no status}" ;; *) echo non-zero ;; esac; }   # STATUS
_lwended() { case "$1" in ''|*[!0-9]*) echo "${1:-no status}" ;; *) echo ended ;; esac; }   # STATUS: did it end?
_lwsaid() { case "$1" in *revoked:*|*allowed:*) echo said ;; *) echo silent ;; esac; }   # TEXT: reports a write?
_lwrv() { case "$1" in *revoked:*) echo said ;; *) echo silent ;; esac; }               # TEXT: says revoked:?
_lwhas() { case "$1" in *"$2"*) echo "$2" ;; *) echo "no [$2]" ;; esac; }               # TEXT WORDS
_lwclaim() {   # STATUS TEXT LINE CAP WANT: broken when a run that exited 0 saying LINE leaves CAP's grant other than WANT
  case "$1:$2" in 0:*"$3"*) [ "$(_lwallows "$4")" = "$5" ] && echo holds || echo broken ;; *) echo holds ;; esac
}
_lwuntil() {   # PID: wait up to 30 s, far from a run's cost, for PID to be gone; 0 when it is
  _lwu=0
  while kill -0 "$1" 2>/dev/null; do
    [ "$_lwu" -ge 300 ] && return 1
    sleep 0.1; _lwu=$((_lwu+1))
  done
  return 0
}
_lwreap() {   # PID: reap this suite's child PID, given 30 s; _lwrc is its status, or says it did not end
  if _lwuntil "$1"; then wait "$1"; _lwrc=$?
  else kill -KILL "$1" 2>/dev/null; wait "$1" 2>/dev/null; _lwrc="still running after 30 s"; fi
}
_lwrun() {   # ARGS...: felix autonomy ARGS from the widget checkout; sets _lwrc _lwout _lwerr
  ( cd "$REPO" && exec "$FELIX" autonomy "$@" ) > "$TMP/lw.out" 2> "$TMP/lw.err" 8>&- &
  _lwreap $!
  _lwout="$(cat "$TMP/lw.out")"; _lwerr="$(cat "$TMP/lw.err")"
}
_lwprobe() {   # SIG: yes when a bash started the way run A is started can trap SIG
  set -m
  ( exec bash -c "trap 'exit 9' $1; kill -$1 \$\$; exit 0" ) > /dev/null 2>&1 8>&- &
  _lwpp=$!
  set +m
  wait "$_lwpp"; [ "$?" = 9 ] && echo yes || echo no
}
_lwign() { echo "SIG$1 cannot reach a process this suite starts: it was ignored when the suite began"; }   # SIG
_lwgo() {   # ARGS...: run A, felix autonomy ARGS, in the background under job control, the shim first on its PATH
  # No core file: an engine that leaves QUIT, XCPU or XFSZ to its default
  # would otherwise dump one into the checkout.
  _lwa=""; _lwreached=no
  rm -f "$_lwsh/reached" "$_lwsh/release"; mkfifo "$_lwsh/release" 2>/dev/null
  [ -p "$_lwsh/release" ] || { _lwreached="no FIFO"; return; }
  : > "$_lwsh/armed"; exec 8<>"$_lwsh/release"
  set -m
  ( ulimit -c 0 2>/dev/null; cd "$REPO" && PATH="$_lwsh:$PATH" exec "$FELIX" autonomy "$@" ) \
    > "$TMP/lw-a.out" 2> "$TMP/lw-a.err" 8>&- &
  _lwa=$!
  set +m
  _lwg=0
  while :; do
    [ -s "$_lwsh/reached" ] && { _lwreached=yes; return; }
    kill -0 "$_lwa" 2>/dev/null || { _lwreached="it ended first"; return; }
    [ "$_lwg" -ge 300 ] && { _lwreached="not within 30 s"; return; }
    sleep 0.1; _lwg=$((_lwg+1))
  done
}
_lwend() {   # release run A's mv and reap both, however A ended; sets _lwarc _lwaout _lwaerr
  # fd 8 stays open until the mv is gone. A FIFO drops what it holds when its
  # last descriptor closes, and an mv not yet at its read would then wait for
  # a line that never comes.
  { printf 'go\n' >&8; } 2>/dev/null
  _lwsp="$(cat "$_lwsh/reached" 2>/dev/null)"
  if [ -n "$_lwsp" ]; then _lwuntil "$_lwsp" || kill -KILL "$_lwsp" 2>/dev/null; fi
  exec 8>&-
  _lwarc=""
  if [ -n "$_lwa" ]; then _lwreap "$_lwa"; _lwarc="$_lwrc"; fi
  rm -f "$_lwsh/reached" "$_lwsh/release" "$_lwsh/armed"
  _lwaout="$(cat "$TMP/lw-a.out" 2>/dev/null)"; _lwaerr="$(cat "$TMP/lw-a.err" 2>/dev/null)"
}
_lwreq() {   # NAME VALUE EXPECTED: is, once run A paused in its mv; bad when it never did
  if [ "$_lwreached" = yes ]; then is "$1" "$2" "$3"
  else bad "$1" "run A never paused in the mv onto the grant file ($_lwreached)"; fi
}
_lwbrief() {   # up to half a second, cut short when run A's shell is gone
  _lwi=0; while [ "$_lwi" -lt 5 ] && kill -0 "$_lwa" 2>/dev/null; do sleep 0.1; _lwi=$((_lwi+1)); done
}

_autonomy_lock_build() {
  _lwp="$FROOT/projects/widget"; _lwL="$_lwp/autonomy.lock"; _lwk="$TMP/lw-keep"; _lwsh="$TMP/lw-shim"
  : "${_lwstart=}" "${_lwa=}" "${_lwreached=no}"
  [ -d "$_lwk" ] && return 0
_lwp="$FROOT/projects/widget"; _lwL="$_lwp/autonomy.lock"; _lwk="$TMP/lw-keep"; mkdir -p "$_lwk"
_lwstart="$(ls -A "$_lwp" | LC_ALL=C sort)"
for _lwf in "$_lwp"/autonomy*; do { [ -e "$_lwf" ] || [ -L "$_lwf" ]; } && mv "$_lwf" "$_lwk/"; done
_lwa=""; _lwreached=no
# The mv run A finds first on its PATH, as in the block above: armed, and
# moving onto the widget's grant file, it disarms, writes its pid to reached
# and reads one line from the FIFO release; then, and in every other case at
# once, it is /bin/mv.
_lwsh="$TMP/lw-shim"; mkdir -p "$_lwsh"
{ printf '#!/bin/sh\n_d=%s\n' "'$_lwsh'"
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
} > "$_lwsh/mv"; chmod +x "$_lwsh/mv"
}
