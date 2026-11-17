# The sweep of checker qualification: the scratch trees a killed run left,
# found and removed by a later run, and nothing else touched.
#
# Each row of qualification.tsv runs in a base mktemp makes under TMPDIR,
# felix-qualify.XXXXXX, holding a worktree of HEAD at w that is registered in
# the user's repository (_felix_qualify_one, lib/qualify-run.sh). The row
# throws it away at its end, and its traps do on INT, TERM and HUP. No trap
# reaches SIGKILL: kill -9, or a tool's TERM-then-KILL. Three trees from runs
# killed that way were found in the founder's checkout on 2026-09-25, on disk
# and still in git worktree list. So each row first writes down which process
# owns its base, and each run, before its first row, removes the bases whose
# owner is shown dead, then the registrations whose base is gone.
#
# Several sessions share one TMPDIR, and their runs are alive. So every step
# below decides toward leaving a base:
#
#   - Only TMPDIR, as the row's template names it: T is ${TMPDIR:-/tmp} with
#     one trailing slash taken off. git records a tree's physical path, and on
#     macOS /var/folders/... is registered as /private/var/folders/...
#     (measured), so a registration matches T as given or as pwd -P says.
#   - A candidate is exactly what a row makes: named felix-qualify. and six
#     letters or digits, a directory and no symlink (never followed), the
#     user's own, holding owner as a symlink whose text is a record a row
#     writes, `<pid>` or `<pid> <start>` with one space (_felix_qualify_me).
#     A base from an older engine (tmp.*), a base with no record, a record in
#     a regular file, and any other text are left. A base whose owner cannot
#     be read, its search bit gone, is left.
#   - Dead only when shown dead. kill -0 that fails saying No such process,
#     under LC_ALL=C; any other failure is a process that exists (Operation
#     not permitted is another user's, pid 1 among them, measured on bash
#     3.2.57), and a message lost to a fork that failed is not a death. Or the
#     process exists, the record has a start, and its start now is another:
#     the pid is another process's now. A record with no start, or a start
#     that cannot be read now, is judged by kill -0 alone. On Linux the start
#     is read from /proc and names the pid namespace and the boot, and a
#     record of another namespace or boot is alive (_felix_qualify_since);
#     there a record that names none, a ps start or a pid alone, is alive
#     too, since this sweep cannot tell another host's from its own.
#   - Then the base gets its owner's rwx back, since a dead row's mutation may
#     have taken the write bit that a claim needs. That is the only mode a
#     sweep ever changes on a base it has not claimed, and only on one it has
#     judged dead. It is changed on the directory entered, never by name.
#   - The claim, because two runs starting together both judge the same dead
#     record. Only symlink(2) and rename(2), each checked after
#     (_felix_qualify_claim): this sweep's own record linked at claim, which
#     one sweep alone can make; owner checked to read the very text judged
#     dead; claim renamed over owner. owner is never moved, so it never goes
#     missing: a sweep killed before the rename leaves a claim naming itself,
#     dead, which a later sweep breaks, and one killed after leaves owner
#     naming itself, dead, and a later sweep takes the base over. The sweep
#     that does not hold claim leaves the base without a word. All of it
#     from inside the base, entered and checked, following no name in it: ln
#     -n at a name never taken, and mv with the flag (-h or -T, asked of mv)
#     that renames onto a symlink rather than into its directory. Where mv
#     takes neither, nothing is claimed and every base is left.
#   - The drop is the row's own, _felix_qualify_drop, with the root this
#     sweep was given: the tree, its registration when this root holds it,
#     and the base, its record last. It says, as it always has, only what is
#     really left; a base it cannot empty keeps a record, so each later run
#     tries again and says again that it is left.
#   - Orphans: a registration in this root of exactly <T>/felix-qualify.<six>/w
#     whose base is neither there nor a symlink, from a base swept by another
#     repository's run, or by a run of this root whose drop lost the
#     registration. One `git worktree remove -f -f` of that path each, which
#     removes a registration whose directory is gone (measured, rc 0 on git
#     2.54). The path is the entry exactly as listed, which git takes as
#     that entry: a base made a symlink since to a directory holding another
#     worktree of the root does not lead git there, since the tree's .git
#     names another entry and git refuses (the drop's own rule, review round
#     2). Never `git worktree prune`: it removes every stale entry, and
#     other sessions' and the user's own are not Felix's.
#
# It prints nothing on stdout, which the row loop's verdict lines own, and no
# line of its begins with two spaces, which felix gate counts rows by. It
# changes no verdict, count or status.
#
# What it cannot reach:
#   - A base made before this: a tmp.* name, or a felix-qualify.* base with no
#     record.
#   - A run killed between mktemp and its record: an empty base, no record.
#     And a drop or a sweep killed between removing the record, the base's
#     last entry, and the rmdir: an empty base, no record, no tree.
#   - A base whose owner cannot be read, because the row's mutation took the
#     owner's read or search bit off the base and the row was then killed.
#   - A base in another TMPDIR; only a later run under the same one sees it.
#   - A row whose own mutation removes or rewrites ../owner, which same-user
#     code can do and nothing here can stop. Removed, that row's tree is never
#     swept if it is killed. Forged dead, a concurrent sweep may drop the live
#     row's tree under it, and that row then reads unrunnable.
#   - Another repository's registration of a base swept here from disk. That
#     repository's own next sweep removes it as an orphan.
#   - A TMPDIR shared between machines that are not Linux: a record of the
#     start ps prints, or of a pid alone, names a pid of another machine
#     there, and a sweep on this one may read it dead. Linux records name
#     their pid namespace and boot and are judged in them alone, and a Linux
#     sweep judges no record that names none; a macOS sweep judges no record
#     that names one.
#   - On Linux, a row whose /proc could not be read when it wrote its record,
#     which is then a pid alone: no sweep there judges it, so if that row is
#     killed its tree is left.
#   - On Linux, a base left by a row killed before a reboot, or before a
#     container restart with a TMPDIR that persists: its record names the
#     old boot, so it reads alive for good and is never swept, and while the
#     base is there its registration is no orphan either (review round 3).
#   - The instant between a list of the root's worktrees and git's own read
#     of it, in the drop and the orphan step alike: an entry removed then by
#     another process leaves git to resolve the path, and through a base
#     swapped for a symlink in that same instant, to another worktree.
#   - Rarer interleavings than two sweeps on one base, such as three and a
#     kill inside the claim, may let two sweeps drop the same dead base. No
#     live row's tree is reached that way: only a record judged dead is ever
#     claimed.

# The letters and digits of a base's six, spelled out: a range in a bracket
# follows the locale's collation on bash 3.2.
_felix_qualify_alnum='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789'

# A symlink's text, every byte of it, in _felix_qualify_text, which the caller
# makes local: a record of a pid and a newline is not a record. readlink -n,
# because macOS's readlink adds its newline only to a text that does not end
# in one (measured 2026-10-01), so no newline can be taken off as its own; and
# a sentinel, because $(...) drops trailing newlines. Non-zero when it is not
# a symlink or cannot be read.
_felix_qualify_link() {   # path -> _felix_qualify_text
  local t
  _felix_qualify_text=""
  [ -L "$1" ] || return 1
  t="$(readlink -n "$1" 2>/dev/null && printf x)" || return 1
  _felix_qualify_text="${t%x}"
}

# Whether a text is a record a row writes: a pid of one to ten digits with no
# leading zero, then nothing, or one space and a start with no blank in it.
_felix_qualify_isrec() {   # text
  local p="${1%% *}" s
  case "$p" in ''|0*|*[!0123456789]*) return 1 ;; esac
  [ "${#p}" -le 10 ] || return 1
  [ "$1" = "$p" ] && return 0
  s="${1#"$p" }"
  [ -n "$s" ] && [ "$1" = "$p $s" ] || return 1
  case "$s" in *[[:space:]]*) return 1 ;; esac
}

# Where a process's start is read on Linux. Set here, never taken from the
# environment; the suite stages one by setting it after sourcing.
_felix_qualify_proc=/proc

# The start of a process, a text with no blank, in _felix_qualify_text, which
# the caller makes local; empty when it cannot be had.
#
# Where the proc filesystem names this process's pid namespace (Linux): field
# 22 of <proc>/<pid>/stat, the clock ticks after boot at which the process
# started, then @, the namespace, @ and the boot id, as
# `8842@pid:[4026531836]@6f1c...`. Not ps: procps prints lstart as boot time
# plus those ticks, and boot time moves when the wall clock is stepped
# (settimeofday, an NTP step, a VM resumed), so a live row's start would
# change and read as another process (review 2026-10-01). The ticks never
# change. The namespace, because a pid means nothing outside its own, and a
# TMPDIR shared between containers would show a sweep in one a row in
# another as no such process. The boot, because the first pid namespace has
# the same inode, 4026531836, on every Linux kernel, so the namespace alone
# tells no host, and no boot, from another (review round 2). Where the
# namespace is named but it or the boot cannot be read, no start: ps's is
# one such a host never judges.
#
# Elsewhere (macOS, where ps prints the start fixed at fork), ps -o lstart=,
# in local time and words, so TZ and the locale are fixed, every blank taken
# out, so a record holds exactly one space.
_felix_qualify_since() {   # pid
  local l w IFS=' '
  if [ -L "$_felix_qualify_proc/self/ns/pid" ]; then
    _felix_qualify_ns || return 0
    w="$_felix_qualify_text"; _felix_qualify_text=""
    l=""
    { read -r l < "$_felix_qualify_proc/$1/stat" || [ -n "$l" ]; } 2>/dev/null || return 0
    # The fields after the last ") ", which closes the command's name; the
    # 20th of them is field 22. Digits and a letter: no glob in the split.
    case "$l" in *") "*) l="${l##*) }" ;; *) return 0 ;; esac
    set -- $l
    case "${20:-}" in ''|*[!0123456789]*) return 0 ;; esac
    _felix_qualify_text="${20}@$w"
    return 0
  fi
  l="$(TZ=UTC0 LC_ALL=C ps -o lstart= -p "$1" 2>/dev/null)"
  _felix_qualify_text="${l//[[:space:]]/}"
}

# This process's pid namespace, as the proc filesystem names it, @ and this
# boot's id, in _felix_qualify_text. Non-zero where either cannot be had.
_felix_qualify_ns() {
  local t b=""
  _felix_qualify_text=""
  [ -L "$_felix_qualify_proc/self/ns/pid" ] || return 1
  t="$(readlink "$_felix_qualify_proc/self/ns/pid" 2>/dev/null)" || return 1
  case "$t" in ''|*[[:space:]]*|*@*) return 1 ;; esac
  { read -r b < "$_felix_qualify_proc/sys/kernel/random/boot_id" || [ -n "$b" ]; } 2>/dev/null || return 1
  case "$b" in ''|*[!0123456789abcdefABCDEF-]*) return 1 ;; esac
  _felix_qualify_text="$t@$b"
}

# Whether a record's process is shown dead. 0 only when it is; every other
# case, a check that could not be made among them, is alive. A start naming
# a pid namespace and boot is judged only in that one: from any other, or
# where none is named, the pid is not this sweep's to read. And where the
# proc filesystem names this sweep's namespace, a record naming none, a ps
# start or a pid alone, was written by a host or a tool this sweep cannot
# tell from its own, and is alive (review round 2).
_felix_qualify_dead() {   # pid, start or empty
  local said now _felix_qualify_text
  case "$2" in
    *@*) _felix_qualify_ns && [ "${2#*@}" = "$_felix_qualify_text" ] || return 1 ;;
    *)   if [ -L "$_felix_qualify_proc/self/ns/pid" ]; then return 1; fi ;;
  esac
  if said="$(LC_ALL=C builtin kill -0 "$1" 2>&1)"; then
    [ -n "$2" ] || return 1
    case "$2" in
      *@*) _felix_qualify_since "$1"; now="$_felix_qualify_text" ;;
      *)   now="$(TZ=UTC0 LC_ALL=C ps -o lstart= -p "$1" 2>/dev/null)"
           now="${now//[[:space:]]/}" ;;
    esac
    [ -n "$now" ] && [ "$now" != "$2" ]
    return
  fi
  case "$said" in *"No such process"*) return 0 ;; esac
  return 1
}

# The claim on a base whose record was judged dead: 0 when this sweep alone
# goes on to drop it. owner itself is never moved, so a sweep killed at any
# step leaves the base a candidate still: one killed between moving the dead
# record aside and linking its own left a base with no owner, which no later
# sweep took, and one that moved a record aside could lose the only copy of
# it to another's drop (review 2026-10-01).
#
# The lock is a second link, claim, made by one symlink(2), which fails when
# the name is taken, so no two sweeps hold it at once. Held, this sweep
# checks that owner still reads the record judged dead, then renames claim
# over owner, one rename(2): owner reads the dead record or this sweep's,
# never nothing. A claim held by a sweep shown dead is broken: renamed aside
# to a name carrying this sweep's pid, checked to be the very text judged
# dead, removed, and taken once more. A claim held by anything else is a
# sweep at work, or a text that is not a record, and the base is left.
#
# All of it from inside the base, entered and checked to be the base
# (_felix_qualify_in), every name relative to the directory entered, and no
# name in it ever followed: a claim planted as a symlink to a directory
# outside had ln make the link in that directory, and an owner whose text,
# read as a path from the base, named such a symlink had mv move claim into
# that directory, replacing a file of the name there, at every sweep (review
# round 2). So ln is given -n and a name already taken is never linked at,
# and every rename is given mv's flag that renames onto a symlink to a
# directory rather than into it (_felix_qualify_mvflag). The owner's rwx goes
# back to the base here too, on the directory entered.
_felix_qualify_claim() {   # base, the record judged dead, this sweep's record, mv's no-follow flag
  local _felix_qualify_was="$2" _felix_qualify_mine="$3" _felix_qualify_nf="$4"
  [ -n "$4" ] || return 1
  _felix_qualify_in "$1" _felix_qualify_claim_here
}
_felix_qualify_claim_here() {
  local brk="claim.${_felix_qualify_mine%% *}" held p s _felix_qualify_text
  chmod u+rwx . 2>/dev/null
  if [ -e claim ] || [ -L claim ] || ! ln -s -n -- "$_felix_qualify_mine" claim 2>/dev/null; then
    _felix_qualify_link claim || return 1
    held="$_felix_qualify_text"
    _felix_qualify_isrec "$held" || return 1
    p="${held%% *}"; s=""
    [ "$held" = "$p" ] || s="${held#* }"
    _felix_qualify_dead "$p" "$s" || return 1
    if [ -e "$brk" ] || [ -L "$brk" ]; then return 1; fi
    mv "$_felix_qualify_nf" -f claim "$brk" 2>/dev/null || return 1
    if ! _felix_qualify_link "$brk" || [ "$_felix_qualify_text" != "$held" ]; then
      [ -e claim ] || [ -L claim ] || mv "$_felix_qualify_nf" -f "$brk" claim 2>/dev/null
      return 1
    fi
    rm -f "$brk" 2>/dev/null
    if [ -e claim ] || [ -L claim ]; then return 1; fi
    ln -s -n -- "$_felix_qualify_mine" claim 2>/dev/null || return 1
  fi
  _felix_qualify_link claim && [ "$_felix_qualify_text" = "$_felix_qualify_mine" ] || return 1
  if ! _felix_qualify_link owner || [ "$_felix_qualify_text" != "$_felix_qualify_was" ]; then
    rm -f claim 2>/dev/null
    return 1
  fi
  mv "$_felix_qualify_nf" -f claim owner 2>/dev/null || { rm -f claim 2>/dev/null; return 1; }
  _felix_qualify_link owner && [ "$_felix_qualify_text" = "$_felix_qualify_mine" ]
}

# mv's flag that renames a file onto a destination that is a symlink to a
# directory, replacing the link, rather than into the directory: -h on macOS
# and the BSDs, -T on GNU. Asked of mv itself, never guessed from the
# system's name: each is tried on two empty names, which no rename can
# touch, and taken when mv answers about the file, not about the option. In
# _felix_qualify_text; non-zero when mv takes neither, and then no base is
# claimed.
_felix_qualify_mvflag() {
  local f o
  _felix_qualify_text=""
  for f in -h -T; do
    o="$(LC_ALL=C mv "$f" -f -- '' '' 2>&1)"
    case "$o" in
      *option*|*usage*|*Usage*) ;;
      *"No such file or directory"*) _felix_qualify_text="$f"; return 0 ;;
    esac
  done
  return 1
}

# Whether a registered path is an orphan of this sweep's: exactly
# <T>/felix-qualify.<six>/w, T as given or physical, its base shown absent.
_felix_qualify_orphan() {   # path, T, T physical or empty
  local b d n
  case "$1" in */w) ;; *) return 1 ;; esac
  b="${1%/w}"; d="${b%/*}"; n="${b##*/}"
  [ "$d" = "$2" ] || { [ -n "$3" ] && [ "$d" = "$3" ]; } || return 1
  case "$n" in felix-qualify.??????) ;; *) return 1 ;; esac
  case "${n#felix-qualify.}" in *[!"$_felix_qualify_alnum"]*) return 1 ;; esac
  _felix_qualify_absent "$d" "$n"
}

# Whether a directory holds no entry of a name, shown: it can be entered and
# listed, the listing lacks the name, and the name is neither there nor a
# symlink. A test of the path alone reads a base as absent when TMPDIR has
# lost its search bit, or a stat fails, and a live row's registration was
# removed for good (review 2026-10-01). Its own process, for the cd.
_felix_qualify_absent() {   # dir, name
  ( nl='
'
    CDPATH='' cd -- "$1" 2>/dev/null || exit 1
    l="$(ls -A . 2>/dev/null && printf x)" || exit 1
    case "$nl${l%x}" in *"$nl$2$nl"*) exit 1 ;; esac
    [ ! -e "$2" ] && [ ! -L "$2" ] )
}

# Its own process, so the glob options it sets (_felix_qualify_globs) reach
# no caller.
_felix_qualify_sweep() (   # root
  local root="$1" t="${TMPDIR:-/tmp}" tp b n rec p s me="" nf="" listed relisted rest line failed="" dropped="" nl='
'
  local _felix_qualify_text _felix_qualify_rec
  _felix_qualify_globs
  t="${t%/}"
  [ -n "$t" ] && [ -d "$t" ] || return 0
  # T's physical path, with any newline it ends in: $(...) alone would drop
  # it and name another directory.
  tp=""; _felix_qualify_phys "$t" && tp="$_felix_qualify_text"
  for b in "$t"/felix-qualify.??????; do
    n="${b##*/}"; n="${n#felix-qualify.}"
    case "$n" in *[!"$_felix_qualify_alnum"]*) continue ;; esac
    [ -d "$b" ] && [ ! -L "$b" ] && [ -O "$b" ] || continue
    _felix_qualify_link "$b/owner" || continue
    rec="$_felix_qualify_text"
    _felix_qualify_isrec "$rec" || continue
    p="${rec%% *}"; s=""
    [ "$rec" = "$p" ] || s="${rec#* }"
    _felix_qualify_dead "$p" "$s" || continue
    # This sweep's own record and mv's no-follow flag, once, and only for a
    # base judged dead: with either not to be had, nothing can be claimed,
    # and the bases are left.
    if [ -z "$me" ]; then
      _felix_qualify_me && me="$_felix_qualify_rec" || me=-
      _felix_qualify_mvflag && nf="$_felix_qualify_text"
    fi
    [ "$me" != - ] && [ -n "$nf" ] || continue
    _felix_qualify_claim "$b" "$rec" "$me" "$nf" || continue
    _felix_qualify_drop "$root" "$b"
    dropped="$dropped${b##*/}$nl"
  done
  # The orphans, off one list. A remove that failed is said only if a second
  # list still shows it: two sweeps remove the same orphan, and one of them
  # fails on a registration the other took. A second list that cannot be had
  # leaves the status to say it. A base this sweep dropped is passed over: its
  # drop has tried the remove twice and said what is left, and a third try
  # would say it again.
  listed="$(git -C "$root" worktree list --porcelain 2>/dev/null)" || return 0
  rest="$listed"
  while [ -n "$rest" ]; do
    line="${rest%%"$nl"*}"
    case "$rest" in *"$nl"*) rest="${rest#*"$nl"}" ;; *) rest="" ;; esac
    case "$line" in "worktree "*) ;; *) continue ;; esac
    p="${line#worktree }"
    n="${p%/w}"; n="${n##*/}"
    case "$nl$dropped" in *"$nl$n$nl"*) continue ;; esac
    _felix_qualify_orphan "$p" "$t" "$tp" || continue
    git -C "$root" worktree remove -f -f "$p" >/dev/null 2>&1 || failed="$failed$p$nl"
  done
  [ -n "$failed" ] || return 0
  relisted=yes
  listed="$(git -C "$root" worktree list --porcelain 2>/dev/null)" || relisted=no
  rest="$failed"
  while [ -n "$rest" ]; do
    p="${rest%%"$nl"*}"; rest="${rest#*"$nl"}"
    if [ "$relisted" = yes ]; then
      case "$nl$listed$nl" in *"${nl}worktree $p$nl"*) ;; *) continue ;; esac
    fi
    printf 'felix: %s still lists the scratch worktree %s, which could not be removed\n' "$root" "$p" >&2
  done
  return 0
)
