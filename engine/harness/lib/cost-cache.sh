# felix cost's readings: one scan at a time on this Mac, and every caller served
# from the last one (docs/2026-11-06-load-governor-design.md section 5, C1-C13).
#
# Why. Before this, every call scanned every transcript of its window: 15.7 s of
# CPU over 1236 MB on 2026-11-06, 19 hours into the week, and growing with it.
# The dash mod asked every 5 minutes from every session, behind a lock in its
# store that two sessions could both pass in one tick (three did, at 07:11Z),
# and its timeout killed felix alone, leaving the scan's subshell, grep and awk
# running at ppid 1.
#
# A reading is stage 1's output (lib/cost.sh) for one key: the records root as
# a physical path, the window's start and end ("-" for --since), and the
# checksum of this file and cost.sh. It lives in $HOME/.cache/felix/cost as
# r.<cksum of the key>: a header H, <scan start, epoch>, <as_of>, <key>; stage
# 1's C and R rows; and E last. Its mtime is its scan's start, the lock's as
# touched when the scan began (see _fcc_coarse for coarse filesystems), so a
# reading is current while no *.jsonl and no directory under the root, the root
# included, changed status after it: one find -cnewer. Not under ~/.felix: the
# pulse adds everything there.
#
# The lock is a kernel flock on $dir/lock, taken without waiting by a perl
# supervisor that holds it for exactly the run's life. The supervisor forks the
# scan into a process group of its own, kills that group at the deadline (TERM,
# then KILL 5 s on) and whatever is left of it when the scan ends, and ignores
# INT, QUIT, HUP and TSTP. It holds none of the caller's streams, so a caller
# killed by a timeout leaves a run that finishes and writes its reading. The
# caller waits for it with the wait builtin, which a trapped INT interrupts.
#
# What it cannot do is said in the design's limits: without perl nothing is
# coalesced (the inline scan of before); a root find cannot read cleanly is
# never current; a supervisor killed with KILL leaves its scan unbounded.

# _FCC_DIR: the cache directory, made if need be. 1 when there is no HOME, no
# perl, or the directory cannot be made or written (C10).
_fcc_dir() {
  local d
  _FCC_DIR=""
  [ -n "${HOME:-}" ] || return 1
  command -v perl >/dev/null 2>&1 || return 1
  d="$HOME/.cache/felix/cost"
  case "$d" in -*) d="./$d" ;; esac
  [ -d "$d" ] || mkdir -p -m 700 -- "$d" 2>/dev/null || return 1
  [ -d "$d" ] && [ -w "$d" ] && [ -x "$d" ] || return 1
  _FCC_DIR="$d"
}

# ROOT START END -> _FCC_KEY and _FCC_NAME. 1 when the engine files cannot be
# summed, or the root's path holds a newline (a header is one line).
_fcc_key() {
  local root="$1" pr lib sum nm nl=$'\n'
  pr="$(CDPATH='' cd -- "$root" 2>/dev/null && pwd -P)" || pr=""
  if [ -z "$pr" ]; then case "$root" in /*) pr="$root" ;; *) pr="$PWD/$root" ;; esac; fi
  case "$pr" in *"$nl"*) return 1 ;; esac
  lib="${BASH_SOURCE[0]%/*}"
  [ -r "$lib/cost.sh" ] && [ -r "$lib/cost-cache.sh" ] || return 1
  sum="$(cat -- "$lib/cost.sh" "$lib/cost-cache.sh" 2>/dev/null | cksum)" || return 1
  sum="${sum%% *}"
  case "$sum" in ''|*[!0123456789]*) return 1 ;; esac
  _FCC_KEY="felix cost reading 1	root $pr	start $2	end ${3:--}	engine $sum"
  nm="$(printf '%s' "$_FCC_KEY" | cksum)"; nm="${nm%% *}"
  case "$nm" in ''|*[!0123456789]*) return 1 ;; esac
  _FCC_NAME="r.$nm"
}

# 0 when READING is whole and is the reading of _FCC_KEY; sets _FCC_EP (its
# scan's start, epoch seconds) and _FCC_ASOF. A file that is not, is absent (C9).
_fcc_valid() {
  local LC_ALL=C
  local r="$1" line ep rest asof last
  _FCC_EP=""; _FCC_ASOF=""
  [ -f "$r" ] && [ -r "$r" ] || return 1
  IFS= read -r line < "$r" 2>/dev/null || return 1
  case "$line" in "H	"*) line="${line#H	}" ;; *) return 1 ;; esac
  ep="${line%%	*}"; rest="${line#*	}"
  asof="${rest%%	*}"
  [ "${rest#*	}" = "$_FCC_KEY" ] || return 1
  case "$ep" in ''|*[!0123456789]*) return 1 ;; esac
  [[ "$asof" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}Z$ ]] || return 1
  last="$(tail -n 1 -- "$r" 2>/dev/null)"
  [ "$last" = E ] || return 1
  _FCC_EP="$ep"; _FCC_ASOF="$asof"
}

# 0 when nothing under ROOT changed status after READING's mtime, and find said
# nothing at all: a name it printed, or an error, is a change (C3). Under -L a
# link find can still call a link is dangling, and BSD find reports one as the
# link itself, with no error; the scan counts such a *.jsonl unread, and its
# target can appear where nothing under the root changes, so it is never current.
_fcc_current() {
  local out
  out="$(find -L "$1" \( \( -name '*.jsonl' -type l \) -o \( \( -type d -o -name '*.jsonl' \) -cnewer "$2" \) \) \
          -print 2>&1 | head -n 1)"
  [ -z "$out" ]
}

# The scan, as the supervisor's child, in its own process group, under the lock:
# DIR NAME KEY ROOT TEST VALUE ANY ASOF. If the reading became current while
# this run waited to start, it does nothing. Status 0 when a reading is there.
_fcc_make() {
  local d="$1" r="$1/$2" t="$1/t.$$" ep kr pr rows
  _FCC_KEY="$3"
  if _fcc_valid "$r" && _fcc_current "$4" "$r"; then return 0; fi
  ep="$(date -u +%s)" || return 1
  case "$ep" in ''|*[!0123456789]*) return 1 ;; esac
  kr="${3#*	root }"; kr="${kr%%	start *}"
  # The lock is the scan's start stamp: only the run that holds it writes it,
  # and a reader passes it over, so the directory gains no file (C9).
  touch -- "$d/lock" || return 1
  # Stage 1 prints its rows only at its end, so they are held here and the
  # temporary file is made after the scan: while a scan runs, the directory
  # holds nothing a reader could take for a reading, and a scan cut at its
  # deadline leaves no file at all (C7).
  rows="$(_fc_scan "$4" "$5" "$6" "$7")" || return 1
  [ "${rows##*$'\n'}" = E ] || return 1
  if printf 'H\t%s\t%s\t%s\n%s\n' "$ep" "$8" "$3" "$rows" > "$t" \
     && [ "$(tail -n 1 -- "$t")" = E ]; then
    # A root reached through a link that was moved during the scan read another
    # directory than the key names: its numbers are not this key's.
    pr="$(CDPATH='' cd -- "$4" 2>/dev/null && pwd -P)" || pr=""
    if { [ -z "$pr" ] || [ "$pr" = "$kr" ]; } \
       && touch -r "$d/lock" -- "$t" && _fcc_coarse "$4" "$t" "$ep" \
       && mv -f -- "$t" "$r"; then
      find "$d" -maxdepth 1 -type f -name 'r.*' -mmin +20160 -exec rm -f -- {} + 2>/dev/null
      find "$d" -maxdepth 1 -type f -name 't.*' -mmin +1440 -exec rm -f -- {} + 2>/dev/null
      return 0
    fi
  fi
  rm -f -- "$t"
  return 1
}

# ROOT TEMP EPOCH: a root whose own status time carries no fraction of a
# second is on a filesystem with coarse times (HFS+ keeps whole seconds, FAT
# two). There a change made just after the scan began carries a time at or
# before the scan's start, and C3 would call the reading current (review,
# 2026-11-06, reproduced on HFS+). Such a reading is dated two seconds before
# the second the scan began in, which costs a needless rescan at most.
_fcc_coarse() {
  perl -MTime::HiRes=stat -e '@s = stat($ARGV[0]) or exit 0; exit($s[10] == int($s[10]) ? 1 : 0)' -- "$1" \
    && return 0
  perl -e 'utime($ARGV[0], $ARGV[0], $ARGV[1]) == 1 or exit 1' -- "$(($3 - 2))" "$2"
}

# The supervisor: DIR LIMIT CMD... Exit 75 when another run holds the lock, 2
# when it cannot be taken at all, 124 when the scan met its deadline, 143 when
# it was itself sent TERM, else the scan's own status: 1 when the reading could
# not be made or written (a full disk), which the caller meets by scanning
# inline, as C10 does.
# shellcheck disable=SC2016
_FCC_PL='
use strict; use warnings; use Fcntl qw(:flock); use POSIX ();
my ($dir, $limit, @cmd) = @ARGV;
# What the caller left open above stderr is not held for the run: a pipe it was
# handed must close when the caller dies.
POSIX::close($_) for 3 .. 255;
open(my $lk, ">>", "$dir/lock") or exit 2;
flock($lk, LOCK_EX | LOCK_NB) or exit($!{EWOULDBLOCK} ? 75 : 2);
# Ctrl-C, Ctrl-backslash and Ctrl-Z at the terminal, and the terminal closing,
# reach the whole group of the caller, this process included: none of them
# stops the run.
$SIG{INT} = $SIG{QUIT} = $SIG{HUP} = $SIG{TSTP} = "IGNORE";
my ($pid, $done, $cut) = (undef, 0, 0);
sub tidy { unlink "$dir/t.$pid" if defined $pid }
# The CHLD handler is set before the fork. On macOS a CHLD whose action is the
# default is discarded even while blocked, so a child that ended before the
# handler was set left the loop below waiting for good, the lock held (review,
# 2026-11-06, reproduced 3 in 300 at load 49).
$SIG{CHLD} = sub { $done = 1 };
my $set = POSIX::SigSet->new(POSIX::SIGTERM(), POSIX::SIGCHLD());
POSIX::sigprocmask(POSIX::SIG_BLOCK(), $set);
$pid = fork;
defined $pid or exit 2;
if (!$pid) {
  setpgrp(0, 0);
  $SIG{$_} = "DEFAULT" for qw(INT QUIT HUP TSTP TERM CHLD ALRM);
  POSIX::sigprocmask(POSIX::SIG_UNBLOCK(), $set);
  open(STDIN, "<", "/dev/null"); open(STDOUT, ">", "/dev/null"); open(STDERR, ">", "/dev/null");
  exec { $cmd[0] } @cmd or POSIX::_exit(127);
}
setpgrp($pid, $pid);
$SIG{TERM} = sub { kill "KILL", -$pid; waitpid($pid, 0); tidy(); exit 143 };
$SIG{ALRM} = sub { if ($cut++) { kill "KILL", -$pid } else { kill "TERM", -$pid; alarm 5 } };
POSIX::sigprocmask(POSIX::SIG_UNBLOCK(), $set);
alarm $limit;
# Once the KILL has gone out, the child is reaped whatever became of its CHLD.
until ($done) {
  select(undef, undef, undef, 0.2);
  $done = 2 if $cut > 1 && waitpid($pid, POSIX::WNOHANG()) == $pid;
}
alarm 0;
# The leader is a zombie until it is reaped, so its group id cannot be reused
# while what is left of the group is killed.
kill "KILL", -$pid;
my $st = $done == 2 ? $? : (waitpid($pid, 0) == $pid ? $? : 0);
tidy() if $st;
# A deadline that came after the reading was written leaves it written.
exit 124 if $cut && $st;
exit(($st & 127) ? 128 + ($st & 127) : $st >> 8);
'

# Serve the call (C3-C9): ROOT TEST VALUE ANY REAL MAXAGE DEADLINE, the window
# and view in _FC_V, the key in _FCC_KEY and _FCC_NAME.
_fcc_serve() {
  local root="$1" real="$5" maxage="$6" lim="$7" r="$_FCC_DIR/$_FCC_NAME" age p rc why lib
  if _fcc_valid "$r"; then
    if [ -n "$maxage" ]; then
      # A reading from the future (the clock was set back) is never aged.
      age=$((real - _FCC_EP))
      if [ "$age" -ge 0 ] && [ "$age" -le "$maxage" ]; then
        _fc_sum aged "the reading made at $_FCC_ASOF, $age s ago (--max-age $maxage)" "" "$_FCC_ASOF" < "$r"
        return
      fi
    fi
    if _fcc_current "$root" "$r"; then _fc_sum "" "" "" < "$r"; return; fi
  fi
  lib="${BASH_SOURCE[0]%/*}"
  trap 'exit 130' INT
  perl -e "$_FCC_PL" "$_FCC_DIR" "$lim" "$BASH" -c '. "$1" && . "$2" && shift 2 && _fcc_make "$@"' \
    felix-cost "$lib/cost.sh" "$lib/cost-cache.sh" \
    "$_FCC_DIR" "$_FCC_NAME" "$_FCC_KEY" "$root" "$2" "$3" "$4" "${_FC_V[3]}" </dev/null >/dev/null 2>&1 &
  p=$!
  wait "$p"; rc=$?
  trap - INT
  case "$rc" in
    0)   if _fcc_valid "$r"; then _fc_sum "" "" "" < "$r"; return; fi
         why="the new reading could not be read" ;;
    1|2) _fc_scan "$root" "$2" "$3" "$4" | _fc_sum "" "" ""; return ;;
    75)  why="another felix cost run is reading now" ;;
    124) why="the new reading did not finish within $lim s" ;;
    *)   why="the new reading failed (status $rc)" ;;
  esac
  if _fcc_valid "$r"; then
    _fc_sum last "the reading made at $_FCC_ASOF; $why" "" "$_FCC_ASOF" < "$r"
  elif [ "$rc" = 124 ]; then
    _fc_sum none "" "the reading did not finish within $lim s, and no earlier reading of this window is kept" </dev/null
  else
    _fc_sum none "" "${why}, and no earlier reading of this window is kept" </dev/null
  fi
}
