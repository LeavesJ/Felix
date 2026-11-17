# The runs behind lib/instrument.sh (trust-plane step 3, slice 3, spec S8.2, S8.5, S8.10, A7, A8 to A10, A12, A14,
# A15, A17): where they run, the run tree T and the canary's copy, the units of P's suite in part mode at the gate's
# job count, their time limits, and their removal on any exit. Split from instrument.sh for its length; that file
# says what is judged and why.
#
# - A7.5, A17: T and the canary's copy are made under the caller's TMPDIR when it is absolute and outside the
#   checkout, and under /tmp otherwise, except where A17 needs the units to be given the caller's TMPDIR itself
#   (felix_instr_dirs says when); the units' TMPDIR never holds T. A7.8, A8, A14: the judge's own records (each
#   supervisor's group file, the build's indexes) are in a directory R outside that TMPDIR and outside the checkout,
#   and each unit's end, ran and log files are the only files in a directory made for that unit alone, in a parent
#   beside R. A unit's exit status is the judge's, held in memory from what the kernel hands it.
# - A10, A17: each unit, and the canary, runs with FELIX_HOME_DIR and FELIX_HOME unset and HOME a directory of its
#   own under the caller's HOME, which holds no .felix-home.
# - A12: the canary's copy is made after the last unit has ended, and P's files in T are listed before the first unit
#   and after the last (_felix_instr_tlist).
# - A7.6: T and the copy each hold the objects they need, history with it, copied in through one pack, and name no
#   other store: neither the checked copy nor the checkout's objects are handed to the candidate's code in a unit.
# - A7.2, A7.3: each unit runs under a supervisor of the judge's (perl), in a process group of its own. The
#   supervisor ends that group, TERM then KILL, when the unit ends, when its time is up (30 minutes, 5 for the
#   canary, lowered only by FELIX_INSTRUMENT_UNIT_SECONDS and FELIX_INSTRUMENT_CANARY_SECONDS), when it is told
#   to, and when the judge is gone. The judge ends what is left of the group too, and of every group at the end.
# - A7.4, A9: TERM, INT, HUP and QUIT end the judgement with T, the records and the units' directories removed,
#   within about two seconds, at any point: every git that builds T or the copy runs in a group of its own and is
#   waited for (felix_instr_grp), since bash runs a trap only once a foreground child has returned.
#
# Not bound: a unit's process that leaves its process group (setsid) is not ended by any of this; the unit runs as
# the same user, so a store or a directory it finds by other means (R, another unit's directory, the home by its
# path) is still open to it (spec section 3), and so is its own log, which is its output.

# A9. COMMAND... in the background, in a process group of its own, waited for; its status is returned. A signal the
# shell traps interrupts the wait at once, where a foreground child holds the trap until it returns (round 1,
# finding 2: a history pack of twelve seconds, and the hand-off's KILL after eight). The group is _FELIX_GRP while it
# runs, so that felix_instr_grpend, from a trap or an exit, ends it with every process the command started. Also
# used by bind.sh for slice 2's copy, which a signal reached in the same way (a reading of A9's "at any point").
felix_instr_grp() {   # COMMAND...
  local p rc
  perl -e 'setpgrp(0, 0); exec { $ARGV[0] } @ARGV; exit 127' "$@" <&0 &
  p=$!; _FELIX_GRP="$p"
  while :; do wait "$p" 2>/dev/null; rc=$?; kill -0 "$p" 2>/dev/null || break; done
  _FELIX_GRP=""
  return "$rc"
}
felix_instr_grpend() {
  local p="${_FELIX_GRP:-}"
  _FELIX_GRP=""
  case "$p" in ''|*[!0123456789]*|0|1) return 0 ;; esac
  { kill -TERM -- "-$p"; kill -0 -- "-$p" && { sleep 0.2; kill -KILL -- "-$p"; }; wait "$p"; } 2>/dev/null
  return 0
}

# The gate's job count (projects/<name>/gate.sh, contract D1 as R51 and R52 replace it), computed the same way.
_felix_instr_jobs() {
  local n=""
  if [ "${GITHUB_ACTIONS:-}" != true ]; then
    n="$(sysctl -n hw.perflevel0.logicalcpu 2>/dev/null)"
    case "$n" in ''|*[!0123456789]*) n="" ;; esac
    n="${n#"${n%%[!0]*}"}"
    if [ -z "$n" ]; then
      n="$(sysctl -n hw.ncpu 2>/dev/null)"
      case "$n" in ''|*[!0123456789]*) n="$(getconf _NPROCESSORS_ONLN 2>/dev/null)" ;; esac
      case "$n" in ''|*[!0123456789]*) n=1 ;; esac
      n="${n#"${n%%[!0]*}"}"
    fi
  fi
  case "$n" in '') n=1 ;; ?|??) ;; *) n=64 ;; esac
  [ "$n" -le 64 ] || n=64
  printf '%s' "$n"
}

# A7.2. The time limit: DEFAULT seconds, or the caller's VALUE when it is a whole number below it. Never above.
_felix_instr_limit() {   # DEFAULT VALUE
  local v="$2"
  case "$v" in ''|*[!0123456789]*) printf '%s' "$1"; return 0 ;; esac
  v="${v#"${v%%[!0]*}"}"; [ -n "$v" ] || v=1
  if [ "${#v}" -le 9 ] && [ "$v" -lt "$1" ]; then printf '%s' "$v"; else printf '%s' "$1"; fi
}

# A7.5. The TMPDIR T is made under and the units are given: the caller's when it is absolute and, physically,
# neither the checkout ROOT nor inside it; /tmp otherwise. Also read by bind.sh for slice 2's copy, which the
# same rule binds (a reading: spec A7.5 names T and the run directory).
felix_instr_tmpbase() {   # ROOT
  local t="${TMPDIR:-}" p r
  case "$t" in /*) ;; *) printf '/tmp'; return 0 ;; esac
  p="$(cd "$t" 2>/dev/null && pwd -P)" || p="$t"
  r="$(cd "${1:-/nonexistent}" 2>/dev/null && pwd -P)" || r=""
  if [ -n "$r" ]; then case "${p%/}/" in "${r%/}"/*) printf '/tmp'; return 0 ;; esac; fi
  printf '%s' "$t"
}
_felix_instr_inside() { case "${1%/}/" in "${2%/}"/*) return 0 ;; esac; return 1; }   # PATH DIR, both physical

# A7.5, A7.8, A14, A15, A17, S8.10. The directories of the run, outside the checkout: the run directory J (T, the
# canary's copy), the records R and the parent of the units' own directories outside the units' TMPDIR, and the
# units' HOMEs. A15: the traps are set first, and each directory is known to the clean-up in the statement that
# makes it. A17, the layout, so that a part sees where it runs as the checkout's suite does:
#   - T is not under the units' TMPDIR, and the directory a bare `mktemp -d` makes (the suite's own) is under it
#     exactly when it is under the caller's. Where mktemp honours TMPDIR, or lands outside the caller's TMPDIR, J is
#     under the caller's TMPDIR (A7.5) and the units are given a fresh directory beside T. Where it ignores TMPDIR
#     and lands under the caller's (macOS's per-user directory), the units are given the caller's TMPDIR, and J goes
#     under /var/tmp or /tmp, whichever is outside it and the checkout (a departure from A7.5 it forces).
#   - HOME: lib/where.sh holds that a temporary root holding HOME is no root, so each unit's HOME is a directory of
#     its own under the caller's HOME (A10), and only when that cannot be made under J.
# A14: the units' directories are made in one parent of mode 0311, which its owner cannot list without changing it.
# A watchdog (perl, in a group of its own, deaf to TERM, INT, HUP and QUIT) removes all of it, and bind.sh's copy
# with what git wrote there moved to the checkout as bind.sh does, when the judge is gone (KILL). 1, with one
# unknown SUITE line and nothing left behind, when a directory cannot be made.
felix_instr_dirs() {   # ROOT
  local root="$1" base pb r0 q rb="" tb="" m="" inx="" hon="" h ph
  _FELIX_INSTR_J=""; _FELIX_INSTR_R=""; _FELIX_INSTR_UP=""; _FELIX_INSTR_HP=""; _FELIX_INSTR_PROBE=""; _FELIX_INSTR_WD=""
  _FELIX_INSTR_UT=""; _FELIX_INSTR_UD=(); _FELIX_INSTR_RC=(); _FELIX_INSTR_T0=(); _FELIX_INSTR_SUB=()
  _FELIX_INSTR_OWNER="${BASHPID:-$(exec /bin/sh -c 'echo "$PPID"')}"
  trap '_felix_instr_stop 143' TERM; trap '_felix_instr_stop 130' INT; trap '_felix_instr_stop 129' HUP; trap '_felix_instr_stop 131' QUIT
  if command -v _felix_bind_exit >/dev/null 2>&1; then trap '_felix_instr_clean 2>/dev/null; _felix_bind_exit' EXIT; else trap '_felix_instr_clean 2>/dev/null' EXIT; fi
  base="$(felix_instr_tmpbase "$root")"; _FELIX_INSTR_BASE="$base"
  pb="$(cd "$base" 2>/dev/null && pwd -P)" || pb="$base"
  r0="$(cd "$root" 2>/dev/null && pwd -P)" || r0="$root"
  for q in /tmp /var/tmp; do
    q="$(cd "$q" 2>/dev/null && pwd -P)" || continue
    [ "$pb" != / ] && ! _felix_instr_inside "$q" "$pb" && ! _felix_instr_inside "$q" "$r0" && { rb="$q"; break; }
  done
  _FELIX_INSTR_RB="$rb"
  [ -z "$rb" ] || _FELIX_INSTR_R="$(mktemp -d "$rb/felix-instrument-r.XXXXXX" 2>/dev/null)"
  [ -z "$_FELIX_INSTR_R" ] || _FELIX_INSTR_R="$(cd "$_FELIX_INSTR_R" 2>/dev/null && pwd -P)"
  if [ -n "$_FELIX_INSTR_R" ] && chmod 700 "$_FELIX_INSTR_R" 2>/dev/null; then
    _FELIX_INSTR_PROBE="$(TMPDIR="$base" mktemp -d 2>/dev/null)"
    m="$(cd "${_FELIX_INSTR_PROBE:-/nonexistent}" 2>/dev/null && pwd -P)"; [ -z "$_FELIX_INSTR_PROBE" ] || rmdir "$_FELIX_INSTR_PROBE" 2>/dev/null
    _FELIX_INSTR_PROBE=""; [ -n "$m" ] && _felix_instr_inside "$m" "$pb" && inx=1
    if [ -n "$inx" ]; then
      _FELIX_INSTR_PROBE="$(TMPDIR="$_FELIX_INSTR_R" mktemp -d 2>/dev/null)"
      m="$(cd "${_FELIX_INSTR_PROBE:-/nonexistent}" 2>/dev/null && pwd -P)"; [ -z "$_FELIX_INSTR_PROBE" ] || rmdir "$_FELIX_INSTR_PROBE" 2>/dev/null
      _FELIX_INSTR_PROBE=""; [ -n "$m" ] && _felix_instr_inside "$m" "$_FELIX_INSTR_R" && hon=1
      [ -n "$hon" ] || for q in /var/tmp /tmp; do
        q="$(cd "$q" 2>/dev/null && pwd -P)" || continue
        [ "$pb" != / ] && ! _felix_instr_inside "$q" "$pb" && ! _felix_instr_inside "$q" "$r0" && ! _felix_instr_inside "$pb" "$q" && { tb="$q"; break; }
      done
    fi
    _FELIX_INSTR_J="$(mktemp -d "${tb:-${base%/}}/felix-instrument.XXXXXX" 2>/dev/null)"
    [ -z "$_FELIX_INSTR_J" ] || _FELIX_INSTR_J="$(cd "$_FELIX_INSTR_J" 2>/dev/null && pwd -P)"
    _FELIX_INSTR_UP="$(mktemp -d "$rb/felix-instrument-u.XXXXXX" 2>/dev/null)"
  fi
  _FELIX_INSTR_TB="${tb:-$base}"
  if [ -z "$_FELIX_INSTR_J" ] || [ -z "$_FELIX_INSTR_UP" ] || ! chmod 311 "$_FELIX_INSTR_UP" 2>/dev/null \
     || { [ -z "$tb" ] && ! mkdir "$_FELIX_INSTR_J/tmp" 2>/dev/null; }; then
    _felix_instr_clean 2>/dev/null
    _felix_instr_add unknown SUITE "no directory could be made under $base for the run tree, or outside it for the run's records"
    return 1
  fi
  if [ -n "$tb" ]; then _FELIX_INSTR_UT="$base"; else _FELIX_INSTR_UT="$_FELIX_INSTR_J/tmp"; fi
  h="${HOME:-}"; ph=""
  case "$h" in /*) ph="$(cd "$h" 2>/dev/null && pwd -P)" || ph="" ;; esac
  if [ -n "$ph" ] && [ "$ph" != / ] && ! _felix_instr_inside "$ph" "$r0"; then
    _FELIX_INSTR_HP="$(mktemp -d "$ph/.felix-instrument-h.XXXXXX" 2>/dev/null)"
  fi
  if [ -z "$_FELIX_INSTR_HP" ] || ! chmod 700 "$_FELIX_INSTR_HP" 2>/dev/null; then
    [ -z "$_FELIX_INSTR_HP" ] || rm -rf "$_FELIX_INSTR_HP" 2>/dev/null
    _FELIX_INSTR_HP="$_FELIX_INSTR_J/h"; mkdir "$_FELIX_INSTR_HP" 2>/dev/null
  fi
  _felix_instr_watch
}
# A14. The watchdog: it waits for its parent, the judge, to be gone (the judge hands it its pid, as a supervisor is
# handed its parent's, for a judge KILLed before the watchdog first looks), then moves what git wrote into bind.sh's copy
# to the checkout (bind.sh's _felix_bind_salvage, the same rule) and removes the copy and every directory of the
# run. USR1 ends it, unused, once the judge has removed them itself.
_felix_instr_wdpl='use File::Path (); use File::Copy (); use File::Glob qw(bsd_glob);
my ($pp, $from, $to, $keep, @rm) = @ARGV; $pp = getppid() unless $pp =~ /^[1-9][0-9]*$/; setpgrp(0, 0);
$SIG{$_} = "IGNORE" for qw(TERM INT HUP QUIT PIPE); $SIG{USR1} = sub { exit 0 };
while (getppid() == $pp) { select(undef, undef, undef, 0.25) }
chdir "/";
if ($from ne "" && $to ne "" && -d $from && -d $to) {
  for my $f (bsd_glob("$from/[0-9a-f][0-9a-f]/*"), bsd_glob("$from/pack/*")) { next unless -f $f;
    my $rel = substr($f, length($from) + 1); next if $keep ne "" && index($rel, "pack/$keep.") == 0;
    next if -e "$to/$rel"; my $dd = $rel; $dd =~ s{/[^/]*$}{}; mkdir "$to/$dd"; File::Copy::move($f, "$to/$rel") } }
for my $d (@rm) { next if $d eq "" || !-e $d; chmod 0700, $d if -d $d && !-l $d; File::Path::remove_tree($d) }
exit 0;'
_felix_instr_watch() {
  local bd="" bh="" bp="" pp
  pp="${BASHPID:-$(exec /bin/sh -c 'echo "$PPID"')}"   # this shell, the judge; before the fork, which expands the arguments
  if [ -n "${_FELIX_BIND_DIR:-}" ] && [ "${_FELIX_BIND_OWNER:-}" = "$_FELIX_INSTR_OWNER" ]; then
    bd="$_FELIX_BIND_DIR"; bh="${_FELIX_BIND_HOME:-}"; bp="${_FELIX_BIND_PACK:-}"
  fi
  perl -e "$_felix_instr_wdpl" "$pp" "${bh:+$bd/objects}" "$bh" "$bp" "$_FELIX_INSTR_J" "$_FELIX_INSTR_R" "$_FELIX_INSTR_UP" \
    "$_FELIX_INSTR_HP" ${bd:+"$bd"} ${bd:+"$bd.list"} </dev/null >/dev/null 2>&1 &
  _FELIX_INSTR_WD=$!
}
# A12. P's files in T as they are (DIR, then the paths T takes from P): one line an entry, its path in hex, size,
# modification and change times to the nanosecond, inode and mode, from lstat, directories walked; sorted bytewise.
_felix_instr_tpl='use Time::HiRes (); my ($t, @q) = @ARGV;
while (@q) { my $p = shift @q; my @s = Time::HiRes::lstat("$t/$p") or next;
  printf "%s %s %.9f %.9f %s %o\n", unpack("H*", $p), $s[7], $s[9], $s[10], $s[1], $s[2];
  next if ($s[2] & 0170000) != 0040000; opendir(my $h, "$t/$p") or do { printf "fail %s\n", unpack("H*", $p); next };
  push @q, map { "$p/$_" } grep { $_ ne "." && $_ ne ".." } readdir $h }'
_felix_instr_tlist() {   # DIR PATH...
  { perl -e "$_felix_instr_tpl" "$@" 2>/dev/null || printf 'fail\n'; } | LC_ALL=C sort
}
# A12. The first path two such listings differ on, read back from its hex, or "its listing" when none can be named.
_felix_instr_tdiff() {   # BEFORE AFTER
  local x
  x="$(printf '%s\n@@\n%s\n' "$1" "$2" | LC_ALL=C awk '$0 == "@@" { s = 1; next } !s { a[$0] = 1; next } { b[$0] = 1; if (!($0 in a) && w == "") w = $1 }
    END { if (w == "") for (l in a) if (!(l in b)) { split(l, f, " "); w = f[1]; break }; print w }')"
  case "$x" in ''|*[!0123456789abcdef]*) printf 'its listing'; return 0 ;; esac
  printf '%s' "$x" | perl -ne 'print pack("H*", $_)' 2>/dev/null
}

# git in a repository this run made: none of the copy's object variables, no machine-local configuration, an
# identity of its own.
_felix_instr_git() {   # DIR git-args...
  local d="$1"; shift
  felix_instr_grp env -u GIT_OBJECT_DIRECTORY -u GIT_ALTERNATE_OBJECT_DIRECTORIES -u GIT_DIR -u GIT_WORK_TREE -u GIT_INDEX_FILE \
      -u GIT_COMMON_DIR -u GIT_GRAFT_FILE HOME="$d" XDG_CONFIG_HOME="$d" GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 \
      GIT_AUTHOR_NAME=felix GIT_AUTHOR_EMAIL=felix@localhost GIT_COMMITTER_NAME=felix GIT_COMMITTER_EMAIL=felix@localhost \
      git -C "$d" -c core.excludesFile=/dev/null -c core.ignoreCase=false -c core.autocrlf=false -c core.hooksPath=/dev/null "$@"
}
# git in the checkout with an index of the run's own, writing what it makes into the store the merging shell writes
# to (bind.sh's copy when one is set): no hooks, no signing, an identity of its own. Both run in a group of their own
# (A9), and _felix_instr_rgo reads the one line a command prints through a file of R, not a substitution, which
# would hold a trap as a foreground child does.
_felix_instr_rg() {   # ROOT INDEX-FILE git-args...
  local root="$1" ix="$2"; shift 2
  felix_instr_grp env GIT_INDEX_FILE="$ix" GIT_AUTHOR_NAME=felix GIT_AUTHOR_EMAIL=felix@localhost GIT_COMMITTER_NAME=felix \
    GIT_COMMITTER_EMAIL=felix@localhost git -C "$root" -c core.hooksPath=/dev/null -c commit.gpgSign=false \
    -c core.autocrlf=false -c core.safecrlf=false "$@"
}
_felix_instr_rgo() {   # VAR ROOT INDEX-FILE git-args...: VAR is the first line it printed, and 1 when it failed or printed none
  local _fi_v="$1" _fi_o="$_FELIX_INSTR_R/o" _fi_l=""; shift
  printf -v "$_fi_v" '%s' ""
  _felix_instr_rg "$@" > "$_fi_o" 2>/dev/null </dev/null || return 1
  { IFS= read -r _fi_l < "$_fi_o"; } 2>/dev/null; rm -f "$_fi_o" 2>/dev/null
  [ -n "$_fi_l" ] || return 1
  printf -v "$_fi_v" '%s' "$_fi_l"
}

# T (WANT-T 1): the merge's tree MT with engine/harness/tests, the gate and the workflows replaced by B's. The
# canary's copy (WANT-C 1; A12, built only once the last unit has ended): MT with the canary's part and driver,
# written into the records from the judge's memory just before. Each is committed with H as its parent, and copied
# with its history into a repository of its own through a pack (A7.6).
_felix_instr_build() {   # ROOT MT B H GATE-PATH BRANCH LB WANT-T WANT-C
  local root="$1" mt="$2" b="$3" h="$4" gp="$5" br="$6" lb="$7" r="$_FELIX_INSTR_R" tp="$_FELIX_INSTR_TP" tc="" cc="" t p s d m
  if [ "$8" = 1 ]; then
    _felix_instr_rg "$root" "$r/t.idx" read-tree "$mt" >/dev/null 2>&1 </dev/null \
      && _felix_instr_rg "$root" "$r/t.idx" ls-files -z -- "$tp" ${gp:+"$gp"} .github/workflows > "$r/t.drop" 2>/dev/null </dev/null \
      && _felix_instr_rg "$root" "$r/t.idx" update-index -z --force-remove --stdin < "$r/t.drop" >/dev/null 2>&1 || return 1
    for p in "$tp" .github/workflows; do
      printf '%s\n' "$lb" | LC_ALL=C awk -v p="$p/" 'index($0, "\t" p) { f = 1 } END { exit !f }' || continue
      _felix_instr_rg "$root" "$r/t.idx" read-tree --prefix="$p/" "$b:$p" >/dev/null 2>&1 </dev/null || return 1
    done
    if [ -n "$gp" ] && s="$(_felix_instr_sha "$lb" "$gp")" && [ -n "$s" ]; then
      m="$(printf '%s\n' "$lb" | LC_ALL=C awk -v p="$gp" '{ i = index($0, "\t") } i && substr($0, i + 1) == p { print $1; exit }')"
      _felix_instr_rg "$root" "$r/t.idx" update-index --add --cacheinfo "$m,$s,$gp" >/dev/null 2>&1 </dev/null || return 1
    fi
    _felix_instr_rgo t "$root" "$r/t.idx" write-tree || return 1
    _felix_instr_rgo tc "$root" "$r/t.idx" commit-tree "$t" -p "$h" -m "felix merge: P's suite over what the squash would land" || return 1
  fi
  if [ "$9" = 1 ]; then
    { printf '%s' "${_FELIX_INSTR_CPART:-}" > "$r/canary.part" && printf '%s' "${_FELIX_INSTR_CDRV:-}" > "$r/canary.drv"; } 2>/dev/null || return 1
    _felix_instr_rg "$root" "$r/c.idx" read-tree "$mt" >/dev/null 2>&1 </dev/null || return 1
    _felix_instr_rgo s "$root" "$r/c.idx" hash-object -w --no-filters "$r/canary.part" \
      && _felix_instr_rgo d "$root" "$r/c.idx" hash-object -w --no-filters "$r/canary.drv" \
      && _felix_instr_rg "$root" "$r/c.idx" update-index --add --cacheinfo "100644,$s,$tp/parts/9989-$_FELIX_INSTR_CID.sh" >/dev/null 2>&1 </dev/null \
      && _felix_instr_rg "$root" "$r/c.idx" update-index --add --cacheinfo "$_FELIX_INSTR_CDMODE,$d,$tp/run" >/dev/null 2>&1 </dev/null \
      && _felix_instr_rgo t "$root" "$r/c.idx" write-tree \
      && _felix_instr_rgo cc "$root" "$r/c.idx" commit-tree "$t" -p "$h" -m "felix merge: the canary" || return 1
  fi
  printf '%s\n' $tc $cc > "$r/v.revs" || return 1
  _felix_instr_rg "$root" "$r/none.idx" pack-objects --revs --stdout -q --window=0 < "$r/v.revs" > "$r/v.pack" 2>/dev/null || return 1
  # A23: B's paths, for a name the tree lacks that this filesystem would answer for.
  _felix_instr_rg "$root" "$r/none.idx" ls-tree -r -z --name-only --full-tree "$b" > "$r/b.paths" 2>/dev/null </dev/null || return 1
  [ -z "$tc" ] || _felix_instr_repo "$_FELIX_INSTR_J/t" "$tc" "$br" "$r/v.pack" "$r/b.paths" || return 1
  [ -z "$cc" ] || _felix_instr_repo "$_FELIX_INSTR_J/c" "$cc" "$br" "$r/v.pack" "$r/b.paths" || return 1
  rm -f "$r/v.pack" "$r/v.revs" "$r/t.idx" "$r/c.idx" "$r/t.drop" "$r/b.paths" 2>/dev/null
  return 0
}
# A22, A23: whether the files written at DIR are the index's: the first difference on stdout and 1, else 0. Which
# names are one is the filesystem's answer, not a table's. Beside DIR, a directory's names in the index (its paths and
# their prefixes) are made, exclusively, in a scratch directory of their own, and a name refused as existing is one
# with the name made before it: two such names are the difference. Then each path of B (BASE-PATHS, NUL-separated),
# and each symbolic link's target from the link's directory, is walked through the index as the filesystem resolves
# it, following links in any name but the last: a name the index lacks that the scratch answers with another name of
# the index is the difference, and so is an answer that names none. A path is printed with bytes outside printable
# ASCII, and the backslash, as \xNN. A file is its bytes, a symbolic link its target, hashed as git hashes a blob;
# kind and executable bit follow the entry's mode, and a gitlink is a directory.
_felix_instr_tcpl='use strict; use Fcntl qw(O_WRONLY O_CREAT O_EXCL); use File::Path (); use Digest::SHA ();
my ($d, $fmt, $ls, $bl) = @ARGV; my $j = $d; $j =~ s{/[^/]*$}{}; my $s = "$j/fold-$$";
END { local $?; File::Path::remove_tree($s) if defined $s && -d $s }
sub show { my $s = $_[0]; $s =~ s/([^\x20-\x5b\x5d-\x7e])/sprintf("\\x%02x", ord $1)/ge; $s }
local $/ = "\0"; open(my $l, "<", $ls) or do { print "the index of the run tree could not be read"; exit 1 };
my (@e, %g, %rep, %mode, %sd, %i); my $n = 0;
sub at { my ($u, $c) = split /\0/, $_[0], 2; length $u ? "$u/$c" : $c }
while (my $r = <$l>) { chomp $r; my ($m, $o, undef, $p) = $r =~ /^([0-7]+) ([0-9a-f]+) ([0-3])\t(.*)$/s or next;
  push @e, [$m, $o, $p]; $mode{$p} = $m; my @c = split m{/}, $p, -1;
  for my $x (0 .. $#c) { my $u = $x ? join("/", @c[0 .. $x - 1]) : ""; my $k = "$u\0$c[$x]";
    next if exists $rep{$k}; push @{$g{$u}}, $c[$x]; $rep{$k} = $p } }
sub mk { my $u = $_[0]; return $sd{$u} if exists $sd{$u}; my $q = "$s/" . $n++;
  mkdir $q or do { print "the names could not be made beside the run tree"; exit 1 }; $sd{$u} = $q;
  for my $c (sort(@{$g{$u}})) { my $k = "$u\0$c";
    if (sysopen(my $h, "$q/$c", O_WRONLY | O_CREAT | O_EXCL)) { $i{$u}{(stat $h)[1]} = $k; close $h; next }
    my $ee = $!{EEXIST}; my @st = lstat "$q/$c"; my $w = $ee && @st ? $i{$u}{$st[1]} : undef;
    if (!defined $w) { print "its ", show($rep{$k}), " has a name this filesystem ", ($ee ? "answers for with a name it does not identify"
      : "will not make"), " (", show(at($k)), ")"; exit 1 }
    my ($pa, $pb, $xa, $xb) = ($rep{$w}, $rep{$k}, at($w), at($k));
    print "it holds ", show($pa), " and ", show($pb), ($pa eq $xa && $pb eq $xb ? ", which this filesystem takes for one name"
      : ", whose " . show($xa) . " and " . show($xb) . " this filesystem takes for one name"); exit 1 }
  $q }
sub walk { my ($u, $cs, $what) = @_; my @c = @$cs; my $hops = 0;
  while (@c) { my $c = shift @c; next if $c eq "" || $c eq ".";
    if ($c eq "..") { return if $u eq ""; $u =~ s{/?[^/]*$}{}; next }
    my $x = length $u ? "$u/$c" : $c;
    if (exists $rep{"$u\0$c"}) { if (($mode{$x} // "") eq "120000" && @c) { my $t = readlink "$d/$x";
        return if ++$hops > 40 || !defined $t || $t =~ m{^/}; unshift @c, split(m{/}, $t, -1); next }
      return unless exists $g{$x}; $u = $x; next }
    return unless exists $g{$u}; my @st = lstat(mk($u) . "/$c"); return unless @st; my $w = $i{$u}{$st[1]};
    print $what, " ", show($x), ", which this filesystem takes for ", (defined $w ? "its " . show(at($w)) : "a name it does not identify"); exit 1 } }
mkdir $s or do { print "the names could not be made beside the run tree"; exit 1 };
for my $u (sort(keys %g)) { mk($u) if @{$g{$u}} > 1 }
open(my $b, "<", $bl) or do { print "the base\x27s paths could not be read"; exit 1 };
while (my $p = <$b>) { chomp $p; walk("", [split m{/}, $p, -1], show($p) . " of the base, which it lacks, reaches") }
for (@e) { next unless $_->[0] eq "120000"; my $p = $_->[2]; my $t = readlink "$d/$p"; next if !defined $t || $t =~ m{^/};
  (my $u = $p) =~ s{/?[^/]*$}{}; walk($u, [split m{/}, $t, -1], "its link " . show($p) . " reaches") }
File::Path::remove_tree($s);
for (@e) { my ($m, $o, $p) = @$_; my $w = "$d/$p"; my $c;
  my $s = show($p);
  if ($m eq "160000") { next if -d $w && !-l $w; print "$s is not the directory its entry names"; exit 1 }
  if ($m eq "120000") { $c = readlink $w; defined $c or do { print "$s is not the symbolic link its entry names"; exit 1 } }
  else { if (-l $w || !-f _) { print "$s is not the file its entry names"; exit 1 }
    if (((stat _)[2] & 0100 ? "100755" : "100644") ne $m) { print "$s does not have the mode its entry names"; exit 1 }
    open(my $h, "<:raw", $w) or do { print "$s could not be read"; exit 1 }; local $/; $c = <$h>; $c = "" unless defined $c }
  my $g = Digest::SHA->new($fmt eq "sha256" ? 256 : 1); $g->add("blob " . length($c) . "\0", $c);
  next if $g->hexdigest eq $o; print "$s does not hold the bytes of its blob"; exit 1 }'
_felix_instr_repo() {   # DEST COMMIT BRANCH PACK BASE-PATHS: a repository of its own at DEST, checked out at COMMIT on BRANCH
  local d="$1" c="$2" br="$3" fmt x
  _FELIX_INSTR_TWHY=""
  mkdir -p "$d" 2>/dev/null && _felix_instr_git "$d" init -q --template= >/dev/null 2>&1 </dev/null || return 1
  _felix_instr_git "$d" index-pack --stdin < "$4" >/dev/null 2>&1 || return 1
  _felix_instr_git "$d" check-ref-format "refs/heads/$br" >/dev/null 2>&1 </dev/null || br=felix-run
  # A22: info/attributes outranks every .gitattributes, so no attribute converts what the checkout writes.
  { mkdir -p "$d/.git/info" && printf '* -text -eol -crlf -ident -filter -working-tree-encoding\n' > "$d/.git/info/attributes"; } \
    2>/dev/null || return 1
  _felix_instr_git "$d" read-tree "$c" >/dev/null 2>&1 </dev/null \
    && _felix_instr_git "$d" update-ref "refs/heads/$br" "$c" >/dev/null 2>&1 </dev/null \
    && _felix_instr_git "$d" symbolic-ref HEAD "refs/heads/$br" >/dev/null 2>&1 </dev/null \
    && _felix_instr_git "$d" checkout-index -a -f >/dev/null 2>&1 </dev/null || return 1
  _felix_instr_git "$d" update-index -q --refresh >/dev/null 2>&1 </dev/null
  # A22, A23: the files written are the tree's, checked before any unit runs.
  fmt="$(_felix_instr_git "$d" rev-parse --show-object-format 2>/dev/null </dev/null)" || fmt=sha1
  _felix_instr_git "$d" ls-files -s -z > "$_FELIX_INSTR_R/t.ls" 2>/dev/null </dev/null \
    || { _FELIX_INSTR_TWHY="its index could not be listed"; return 1; }
  # In a group of its own and waited for (A9), so a signal during the check is handled at once.
  felix_instr_grp perl -e "$_felix_instr_tcpl" "$d" "$fmt" "$_FELIX_INSTR_R/t.ls" "$5" > "$_FELIX_INSTR_R/t.why" 2>/dev/null </dev/null \
    || { x="$(cat "$_FELIX_INSTR_R/t.why" 2>/dev/null)"; _FELIX_INSTR_TWHY="${x:-the files written could not be checked}"
         rm -f "$_FELIX_INSTR_R/t.ls" "$_FELIX_INSTR_R/t.why"; return 1; }
  rm -f "$_FELIX_INSTR_R/t.ls" "$_FELIX_INSTR_R/t.why" 2>/dev/null
  return 0
}

# The supervisor of one unit (A7.2, A7.3, A7.8): LIMIT LOG GROUP-FILE J R U COMMAND... It leaves the judge's process
# group, starts the unit in a group of its own with its output to LOG, writes that group's number, and waits. When
# the unit ends, its time is up, it is told to stop, or the judge is gone, it ends the unit's group, TERM and then
# KILL a second later, and exits with the unit's status (124: the time limit; 125: stopped). The shell that starts it
# hands it its own pid (PARENT), so that a judge gone before the supervisor first looks is seen as gone (read from
# getppid at the start, a judge KILLed in that window read as pid 1, and the supervisor waited on). A judge that is gone
# was killed by a signal it could not trap (KILL, or one it does not trap): the supervisor then removes J, R, the
# unit's own directory U, the parent of the units' directories (A14) and the units' HOMEs.
_felix_instr_pl='use POSIX ();
my ($pp, $lim, $log, $pf, $jd, $rd, $ud, $up, $hp, @cmd) = @ARGV; $pp = getppid() unless $pp =~ /^[1-9][0-9]*$/; setpgrp(0, 0);
my $u = fork(); exit 125 unless defined $u;
if (!$u) { setpgrp(0, 0); $SIG{$_} = "DEFAULT" for qw(INT QUIT TERM HUP PIPE ALRM);
  open(STDIN, "<", "/dev/null"); open(STDOUT, ">>", $log) or POSIX::_exit(126); open(STDERR, ">&", \*STDOUT) or POSIX::_exit(126);
  exec { $cmd[0] } @cmd; POSIX::_exit(127) }
if (open(my $h, ">", $pf)) { print $h "$u\n"; close $h }
my ($stop, $st, $why) = (0, undef, 0); $SIG{$_} = sub { $stop = 1 } for qw(TERM HUP INT QUIT);
my $end = time + $lim;
while (1) { my $r = waitpid($u, POSIX::WNOHANG());
  if ($r == $u) { $st = $?; last } if ($r < 0) { $why = 125; last }
  if ($stop) { $why = 125; last } if (getppid() != $pp) { $why = 126; last } if (time >= $end) { $why = 124; last }
  select(undef, undef, undef, 0.2) }
kill "TERM", -$u;
for (1 .. 10) { last unless kill 0, -$u; select(undef, undef, undef, 0.1);
  if (!defined $st && waitpid($u, POSIX::WNOHANG()) == $u) { $st = $? } }
kill "KILL", -$u; waitpid($u, 0) unless defined $st;
if ($why == 126) { chdir "/"; require File::Path; chmod 0700, $up; File::Path::remove_tree($jd, $rd, $ud, $up, $hp); exit 125 }
exit $why if $why; exit(($st & 127) ? 128 + ($st & 127) : ($st >> 8));'
# One unit of a suite in part mode, in DIR, under its supervisor, in the background: the copy's object variables,
# bind's other settings and felix merge's own variables unset, the units' TMPDIR (A7.5, A17), and A10's home:
# FELIX_HOME_DIR and FELIX_HOME unset, HOME a directory of its own (A17: under the caller's HOME). A8: its log, ran
# and end files are in a directory made for it alone (U, _FELIX_INSTR_UD), in A14's parent, outside that TMPDIR. N 0
# is the canary, which is given no end or ran file. A directory that cannot be made is a unit that did not finish
# (status 126).
_felix_instr_launch() {   # N DIR LIMIT MEMBER...
  local n="$1" dir="$2" lim="$3" r="$_FELIX_INSTR_R" u="" hm="$_FELIX_INSTR_HP/$1" pp
  shift 3
  pp="${BASHPID:-$(exec /bin/sh -c 'echo "$PPID"')}"   # this shell, the supervisor's parent
  local -a ev=()
  # One assignment, so that no trap runs between the directory's making and its being known to the clean-up.
  _FELIX_INSTR_UD[n]="$(mktemp -d "${_FELIX_INSTR_UP:-/nonexistent}/u.XXXXXX" 2>/dev/null)"
  u="${_FELIX_INSTR_UD[n]}"
  if [ -z "$u" ] || ! chmod 700 "$u" 2>/dev/null || ! mkdir "$hm" 2>/dev/null; then
    _FELIX_INSTR_RC[n]=126; _FELIX_INSTR_KEEP=""; return 0   # says nothing about the tree: not kept
  fi
  [ "$n" = 0 ] || ev=("FELIX_TEST_PART_RAN=$u/ran" "FELIX_TEST_PART_END=$u/end")
  ( cd "$dir" 2>/dev/null || exit 1
    exec env -u GIT_OBJECT_DIRECTORY -u GIT_ALTERNATE_OBJECT_DIRECTORIES -u GIT_GRAFT_FILE -u GIT_NO_REPLACE_OBJECTS \
      -u GIT_CONFIG_COUNT -u GIT_CONFIG_KEY_0 -u GIT_CONFIG_VALUE_0 -u GIT_CONFIG_KEY_1 -u GIT_CONFIG_VALUE_1 \
      -u FELIX_MERGE_DRY_RUN -u FELIX_MERGE_BASE_AT -u FELIX_MERGE_BASE_REF -u FELIX_MERGE_HANDED -u FELIX_KERNEL \
      -u FELIX_TEST_JOBS -u FELIX_TEST_PART_RECORD -u FELIX_TEST_PART_RAN -u FELIX_TEST_PART_END -u FELIX_TEST_PART_LOG \
      -u FELIX_INSTRUMENT_UNIT_SECONDS -u FELIX_INSTRUMENT_CANARY_SECONDS -u FELIX_HOME_DIR -u FELIX_HOME HOME="$hm" \
      TMPDIR="$_FELIX_INSTR_UT" ${ev[@]+"${ev[@]}"} \
      perl -e "$_felix_instr_pl" "$pp" "$lim" "$u/log" "$r/$n.pid" "$_FELIX_INSTR_J" "$r" "$u" "$_FELIX_INSTR_UP" "$_FELIX_INSTR_HP" \
      "${BASH:-bash}" engine/harness/tests/run --part "$@" \
      </dev/null >/dev/null 2>&1 ) &
  _FELIX_INSTR_SUB[n]=$!; _FELIX_INSTR_T0[n]=$SECONDS
}
# 0 when unit N has ended (its supervisor has exited, or outlived the unit's LIMIT by 20 s and is killed). The
# judge then holds the exit status the kernel handed it (_FELIX_INSTR_RC), and ends what is left of the unit's group.
_felix_instr_ended() {   # N LIMIT
  local n="$1" p="${_FELIX_INSTR_SUB[$1]:-}" rc
  [ -n "$p" ] || return 0
  if kill -0 "$p" 2>/dev/null; then
    [ "$SECONDS" -ge $(( ${_FELIX_INSTR_T0[$n]:-0} + $2 + 20 )) ] || return 1
    kill -KILL "$p" 2>/dev/null
  fi
  wait "$p" 2>/dev/null; rc=$?
  _felix_instr_endgroup "$_FELIX_INSTR_R/$n.pid"
  _FELIX_INSTR_RC[n]="$rc"
  unset "_FELIX_INSTR_SUB[$n]"
  return 0
}
_felix_instr_endgroup() {   # GROUP-FILE: what is left of a unit's process group, killed
  local pg=""
  { read -r pg < "$1"; } 2>/dev/null
  case "$pg" in ''|*[!0123456789]*|0|1) return 0 ;; esac
  kill -0 -- "-$pg" 2>/dev/null || return 0
  kill -TERM -- "-$pg" 2>/dev/null; sleep 0.2; kill -KILL -- "-$pg" 2>/dev/null
  return 0
}
# Units 1 to COUNT of _FELIX_INSTR_U in DIR, JOBS at a time; returns when each has ended.
_felix_instr_runall() {   # JOBS DIR COUNT
  local jobs="$1" dir="$2" n="$3" next=1 run=0 i live=" " lim
  lim="$(_felix_instr_limit 1800 "${FELIX_INSTRUMENT_UNIT_SECONDS:-}")"; _FELIX_INSTR_ULIM="$lim"
  while :; do
    while [ "$run" -lt "$jobs" ] && [ "$next" -le "$n" ]; do
      # shellcheck disable=SC2086
      _felix_instr_launch "$next" "$dir" "$lim" ${_FELIX_INSTR_U[next]}
      live="$live$next "; run=$((run + 1)); next=$((next + 1))
    done
    [ "$run" -gt 0 ] || break
    sleep 0.2
    for i in $live; do
      _felix_instr_ended "$i" "$lim" || continue
      live="${live/ $i / }"; run=$((run - 1))
    done
  done
}

# A7.3, S8.10. Every supervisor still running is told to stop and given 1.5 s, which ends its unit's group; then
# every unit group still alive and every supervisor is killed. Then the run's directories go. Only the process that
# made them removes them (the owner is read as bind.sh reads its own, never $$).
_felix_instr_kill() {
  local p f i=0 live
  felix_instr_grpend
  for p in ${_FELIX_INSTR_SUB[@]+"${_FELIX_INSTR_SUB[@]}"}; do kill -TERM "$p" 2>/dev/null; done
  while [ "$i" -lt 15 ]; do
    live=""; for p in ${_FELIX_INSTR_SUB[@]+"${_FELIX_INSTR_SUB[@]}"}; do kill -0 "$p" 2>/dev/null && { live=1; break; }; done
    [ -n "$live" ] || break
    sleep 0.1; i=$((i + 1))
  done
  [ -z "${_FELIX_INSTR_R:-}" ] || for f in "$_FELIX_INSTR_R"/*.pid; do [ -f "$f" ] && _felix_instr_endgroup "$f"; done
  for p in ${_FELIX_INSTR_SUB[@]+"${_FELIX_INSTR_SUB[@]}"}; do kill -KILL "$p" 2>/dev/null; wait "$p" 2>/dev/null; done
  _FELIX_INSTR_SUB=()
}
# The end of the run on any path. A13: once every unit has ended, the kept judgements' sweep and the marker
# (instrument-keep.sh), for a judgement not kept unless its normal end kept it already. Then the directories, and
# last the watchdog, which they no longer need.
_felix_instr_clean() {
  local u
  [ -n "${_FELIX_INSTR_J:-}${_FELIX_INSTR_R:-}${_FELIX_INSTR_UP:-}${_FELIX_INSTR_HP:-}${_FELIX_INSTR_PROBE:-}${_FELIX_INSTR_WD:-}${_FELIX_INSTR_KRUN:-}" ] || return 0
  [ "${BASHPID:-$(exec /bin/sh -c 'echo "$PPID"')}" = "${_FELIX_INSTR_OWNER:-}" ] || return 0
  _felix_instr_kill
  ! command -v _felix_instr_kend >/dev/null 2>&1 || _felix_instr_kend 0
  [ -z "${_FELIX_INSTR_PROBE:-}" ] || rmdir "$_FELIX_INSTR_PROBE" 2>/dev/null
  [ -z "${_FELIX_INSTR_J:-}" ] || rm -rf "$_FELIX_INSTR_J" 2>/dev/null
  [ -z "${_FELIX_INSTR_R:-}" ] || rm -rf "$_FELIX_INSTR_R" 2>/dev/null
  for u in ${_FELIX_INSTR_UD[@]+"${_FELIX_INSTR_UD[@]}"}; do [ -z "$u" ] || rm -rf "$u" 2>/dev/null; done
  [ -z "${_FELIX_INSTR_UP:-}" ] || { chmod 700 "$_FELIX_INSTR_UP"; rm -rf "$_FELIX_INSTR_UP"; } 2>/dev/null
  [ -z "${_FELIX_INSTR_HP:-}" ] || rm -rf "$_FELIX_INSTR_HP" 2>/dev/null
  [ -z "${_FELIX_INSTR_WD:-}" ] || { kill -USR1 "$_FELIX_INSTR_WD"; wait "$_FELIX_INSTR_WD"; } 2>/dev/null
  _FELIX_INSTR_J=""; _FELIX_INSTR_R=""; _FELIX_INSTR_UD=(); _FELIX_INSTR_UP=""; _FELIX_INSTR_HP=""; _FELIX_INSTR_PROBE=""; _FELIX_INSTR_WD=""
}
_felix_instr_stop() {   # EXIT-STATUS: a signal reached felix merge while P's suite ran
  trap '' TERM INT HUP QUIT
  _felix_instr_clean 2>/dev/null
  exit "$1"
}
