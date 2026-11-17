# tests/lib/qualify-sweep.sh: the side tree and the helpers the sweep parts drive
# runs of felix_qualify_run and the sweep through.
# Used by 0540 0550 0560, each of which builds the tree and clears what it built.
# Moved from parts/0540-qualification-a-later-run-sweeps-the-trees-a.sh lines
# 85-439 (the helpers verbatim; the statements that wrote the side tree became
# the builder) and the closing cleanup from parts/0560-continued.sh lines 271-298.
# Definitions only. _qualify_sweep_build sets its variables first and does
# nothing more once $QSWS/run-cli is there. A part that built the tree calls
# _qualify_sweep_cleanup at its end, which stops what the part started, gives
# its directories their bits back, clears immutable flags, prunes its own roots
# alone and removes the tree, so a part run alone leaves nothing behind.

_qsw5() { printf '%s\t%s\t%s\t%s\t%s\n' "$@"; }
_qsw6() { printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$@"; }
_qswphys() { ( cd "$1" 2>/dev/null && pwd -P ); }
_qswmode() { ls -ld "$1" 2>/dev/null | cut -c1-10; }
_qswroot() {   # dir -> a git root there, one commit holding base.txt; its physical path
  local p
  mkdir -p "$1"
  ( _fx_cd "$1" && git init -q -b main && printf 'clean\n' > base.txt && git add -A \
    && git -c user.name=t -c user.email=t@t commit -qm base ) >/dev/null 2>&1
  p="$(_qswphys "$1")"; printf '%s\n' "$p" >> "$QSWS/roots"; printf '%s' "$p"
}
_qswtab() { mkdir -p "$1"; _qsw5 plain 'test -f base.txt' restoration pass true > "$1/qualification.tsv"; }
_qswisdead() { [ -n "$1" ] || return 1; case "$(LC_ALL=C kill -0 "$1" 2>&1)" in *"No such process"*) return 0 ;; esac; return 1; }
_qswdead() {   # a pid kill -0 says there is no such process of: one a process started here had
  local p i=0
  while :; do
    sh -c 'exit 0' & p=$!
    wait "$p" 2>/dev/null
    _qswisdead "$p" && break
    i=$((i + 1)); [ "$i" -lt 20 ] || break
  done
  printf '%s' "$p"
}
# A process's start as a row records it: where /proc names this process's
# pid namespace, field 22 of /proc/<pid>/stat, @, that namespace, @ and the
# boot id; elsewhere ps -o lstart= under TZ=UTC0 and LC_ALL=C, every blank
# removed. _qswns is the namespace and boot, empty where /proc names none.
_qswns() {
  local n b
  [ -L /proc/self/ns/pid ] || return 0
  n="$(readlink /proc/self/ns/pid 2>/dev/null)"; b="$(cat /proc/sys/kernel/random/boot_id 2>/dev/null)"
  [ -n "$n" ] && [ -n "$b" ] && printf '%s@%s' "$n" "$b"
}
_qswstart() {
  local ns; ns="$(_qswns)"
  if [ -n "$ns" ]; then
    sed 's/.*) //' "/proc/$1/stat" 2>/dev/null | awk -v n="$ns" '$20 ~ /^[0-9]+$/ { printf "%s@%s", $20, n }'
  else
    TZ=UTC0 LC_ALL=C ps -o lstart= -p "$1" 2>/dev/null | tr -d ' \t\n'
  fi
}
_qswlive()  { [ -n "$1" ] || return 1; case "$(ps -o stat= -p "$1" 2>/dev/null | tr -d ' ')" in ''|Z*) return 1 ;; esac; return 0; }
_qswalive() { if _qswlive "$1"; then echo yes; else echo no; fi; }
_qswnotlive() { ! _qswlive "$1"; }
_qswreaped() { [ -z "$1" ] || [ -z "$(ps -o pid= -p "$1" 2>/dev/null | tr -d ' ')" ]; }
# A base planted as a killed row's would be, or not quite: T, name, a root
# to register its tree in or -, and its record: - for none, file:TEXT for a
# regular file, anything else the text of the symlink.
_qswplant() {
  local b="$1/$2"
  mkdir "$b" || return 1
  [ "$3" = - ] || _fx_git "$3" worktree add --detach -q "$b/w" HEAD >/dev/null 2>&1
  case "$4" in
    -) ;;
    file:*) printf '%s' "${4#file:}" > "$b/owner" ;;
    *) ln -s -- "$4" "$b/owner" ;;
  esac
}
_qswreggone() {   # root, path: a worktree registered there, then its directory taken away
  mkdir -p "${2%/*}"
  _fx_git "$1" worktree add --detach -q "$2" HEAD >/dev/null 2>&1
  rm -rf "$2"
}
_qswlisted() { git -C "$1" worktree list --porcelain 2>/dev/null | awk -v p="worktree $2" '$0 == p { f = 1 } END { print (f ? "yes" : "no") }'; }
_qswwt() { git -C "$1" worktree list --porcelain 2>/dev/null | awk '/^worktree / { w++ } END { printf "wt:%d", w - 1 }'; }
_qswthere() { if [ -e "$1" ] || [ -L "$1" ]; then echo there; else echo gone; fi; }
_qswswept() {   # base, root, registered path -> gone when neither the base nor its registration is left
  local t r
  t="$(_qswthere "$1")"; r="$(_qswlisted "$2" "$3")"
  if [ "$t" = gone ] && [ "$r" = no ]; then echo gone; else echo "left(base:$t,registered:$r)"; fi
}
# What a base was before a run, and whether it is gone after: gone only for
# a base that was there and registered before, so a plant that failed can
# never read as a sweep that worked.
_qswpre() { printf '%s,%s' "$(_qswthere "$1")" "$([ "$(_qswlisted "$2" "$3")" = yes ] && echo registered || echo unregistered)"; }
_qswgone() {   # what was there before, base, root, registered path
  if [ "$1" = there,registered ]; then _qswswept "$2" "$3" "$4"; else echo "never-planted($1)"; fi
}
_qswrec() {   # an owner path -> its text, every byte shown, or what is there instead
  if [ -L "$1" ]; then printf 'link[%s]' "$(readlink "$1" 2>/dev/null | od -An -c | tr -s ' \n' '  ')"
  elif [ -f "$1" ]; then printf 'file[%s]' "$(od -An -c < "$1" 2>/dev/null | tr -s ' \n' '  ')"
  elif [ -e "$1" ]; then printf other
  else printf none; fi
}
_qswsnap() {   # path, root, registered path -> what is there, its mode, record and entries, and whether git lists the tree
  local k
  if [ -L "$1" ]; then k="link>$(readlink "$1")"
  elif [ -d "$1" ]; then k=dir
  elif [ -e "$1" ]; then k=other
  else k=absent; fi
  printf '%s mode:%s owner:%s entries:%s reg:%s' "$k" "$(_qswmode "$1")" "$(_qswrec "$1/owner")" \
    "$(ls -A "$1" 2>/dev/null | LC_ALL=C sort | tr '\n' ',')" "$(_qswlisted "$2" "$3")"
}
# A record's shape: pid+start for <pid> <start> with one space and no other
# blank, pid for a pid alone, bad for anything else.
_qswshape() {
  local p="${1%% *}" s
  case "$p" in ''|0*|*[!0-9]*) echo bad; return ;; esac
  [ "$1" = "$p" ] && { echo pid; return; }
  s="${1#"$p" }"
  [ "$1" = "$p $s" ] && [ -n "$s" ] || { echo bad; return; }
  case "$s" in *[[:space:]]*) echo bad ;; *) echo pid+start ;; esac
}
_qswbase() { ls -A "$1" 2>/dev/null | awk '/^felix-qualify\./ { n++; b = $0 } END { if (n == 1) print b }'; }
_qswfelix() { awk '/^felix:/ { n++ } END { print n + 0 }' "$1" 2>/dev/null; }
_qswverd() { awk -F'\t' 'NF >= 5 { printf "%s%s %s", (n++ ? "; " : ""), $4, $5 }' "$1/out" 2>/dev/null; }
_qswt() { printf 't:[%s]' "$(ls -A "$1" 2>/dev/null | tr '\n' ' ')"; }
# Processes: those of group $1 not yet exited; every process below $1 in
# group $2; a poll until a test holds, with a deadline; and the stop, KILL
# to whatever is left of a group started here, then the reap.
_qswgroup() { ps -A -o pid=,pgid=,stat= 2>/dev/null | awk -v g="$1" '$2 == g && $3 !~ /^Z/ { print $1 }'; }
_qswbelow() { ps -A -o pid=,ppid=,pgid= 2>/dev/null | awk -v r="$1" -v g="$2" '
  { par[$1] = $2; grp[$1] = $3; ids[++n] = $1 }
  END { want[r] = 1; more = 1
        while (more) { more = 0
          for (i = 1; i <= n; i++) if (!(ids[i] in want) && (par[ids[i]] in want)) { want[ids[i]] = 1; more = 1 } }
        for (i = 1; i <= n; i++) if (ids[i] != r && (ids[i] in want) && grp[ids[i]] == g) print ids[i] }'; }
_qswempty() { [ -z "$(_qswgroup "$1")" ]; }
_qswheld()  { [ -s "$1" ] || ! _qswlive "$2"; }
_qswallin() { local f; for f in "$@"; do [ -s "$f" ] || return 1; done; }
_qswtill() {   # seconds, test...
  local t0=$SECONDS lim="$1"; shift
  while ! "$@"; do [ $((SECONDS - t0)) -lt "$lim" ] || return 1; sleep 1; done
}
# The group, the pid itself and what is below it, only while the pid is
# still this shell's child: once reaped, the pid is free, and so, once its
# group is empty, is the group's id, and either may be another session's.
_qswstop() {
  local k
  if [ "$(ps -o ppid= -p "$1" 2>/dev/null | tr -d ' ')" = "$$" ]; then
    kill -s KILL -- "-$1" 2>/dev/null
    for k in $(_qswbelow "$1" "$1"); do kill -s KILL "$k" 2>/dev/null; done
    kill -s KILL "$1" 2>/dev/null
  fi
  wait "$1" 2>/dev/null
}
# Whether $1 is a strict ancestor of $2, walked up by parent pid; and what a
# recorded pid is to a held run: row when it is an ancestor of the held
# checker and the caller is an ancestor of it, which is the process the row
# loop runs the row in; caller when it is the shell that called
# felix_qualify_run; otherwise other.
_qswanc() {   # ancestor, descendant
  local p="$2" n=0
  [ -n "$1" ] && [ -n "$p" ] || return 1
  while [ "$n" -lt 64 ]; do
    p="$(ps -o ppid= -p "$p" 2>/dev/null | tr -d ' ')"
    [ -n "$p" ] && [ "$p" != 0 ] || return 1
    [ "$p" = "$1" ] && return 0
    [ "$p" = 1 ] && return 1
    n=$((n + 1))
  done
  return 1
}
_qswrole() {   # recorded pid, held checker pid, caller pid
  if [ -z "$1" ]; then echo none
  elif [ "$1" = "$3" ]; then echo caller
  elif _qswanc "$1" "$2" && _qswanc "$3" "$1"; then echo row
  else echo "other[$1]"; fi
}
# The held row's process found without its record: the held checker's
# ancestor whose parent is the caller.
_qswrowof() {   # held pid, caller pid
  local p="$1" q n=0
  while [ -n "$p" ] && [ "$p" != 1 ] && [ "$n" -lt 64 ]; do
    q="$(ps -o ppid= -p "$p" 2>/dev/null | tr -d ' ')"
    [ -n "$q" ] || return 1
    if [ "$q" = "$2" ]; then printf '%s' "$p"; return 0; fi
    p="$q"; n=$((n + 1))
  done
  return 1
}
# Start a caller in a group of its own: dir for its files, T, root, go file
# or -, run | sweep, and felix_qualify_run's arguments. Its pid is _qswpid.
# _qswpath, when set, goes first on its PATH, and _qswxenv, when set, is one
# NAME=value more in its environment. TZ is not UTC, so a start read in local
# time differs from one read under TZ=UTC0 on every runner.
_qswbg() {
  local d="$1" t="$2" root="$3" go="$4" what="$5"; shift 5
  mkdir -p "$d"; : >> "$d/made"; : >> "$d/git"; rm -f "$d/caller"
  env ${_qswxenv:+"$_qswxenv"} TZ=JST-9 TMPDIR="$t" PATH="${_qswpath:+$_qswpath:}$QSWSHIM:$PATH" \
    QSW_GITLOG="$d/git" QSW_NORECORD="${_qswnorec:-}" \
    perl -e '$SIG{INT} = $SIG{TERM} = $SIG{HUP} = "DEFAULT"; setpgrp(0, 0) or exit 97; exec @ARGV or exit 98' \
    "$BASH" "$QSWL" "$FROOT" "$root" "$d/made" "$d/caller" "$go" "$what" "$@" </dev/null >"$d/out" 2>"$d/err" &
  _qswpid=$!
  printf '%s\n' "$_qswpid" >> "$QSWS/pids"
}
# Done is the caller itself ended and its group empty: the group is empty
# for a moment after the fork too, before perl has made it.
_qswdone() { ! _qswlive "$1" && _qswempty "$1"; }
_qswfinish() {   # pid, dir: done within 300 s, or stopped and said so in its stderr
  _qswtill 300 _qswdone "$1" || printf 'qsw: stuck, stopped\n' >> "$2/err"
  _qswstop "$1"
}
_qswrun() {   # dir, T, root, proj, [checker]
  local d="$1" t="$2" root="$3" proj="$4"; shift 4
  _qswbg "$d" "$t" "$root" - run "$proj" "$root" "$@"
  _qswfinish "$_qswpid" "$d"
}
# A run whose one row's checker writes its own pid to <case>/at and waits for
# <case>/release, 300 s at most, then passes when base.txt is there. Run a's
# pid is _qswa; 0 once the checker holds.
_qswhold() {   # case dir, T, root
  mkdir -p "$1/proj"
  _qsw5 held "exec perl -e 'open(my \$f, q(>), \$ARGV[1]) or exit 3; print \$f \$\$; close \$f; for (1 .. 300) { last if -e \$ARGV[0]; sleep 1 } exit((-e q(base.txt)) ? 0 : 1)' '$1/release' '$1/at'" \
        restoration pass true > "$1/proj/qualification.tsv"
  _qswbg "$1/a" "$2" "$3" - run "$1/proj" "$3"
  _qswa="$_qswpid"
  _qswtill 240 _qswheld "$1/at" "$_qswa"
  [ -s "$1/at" ]
}
_qswleft() {   # case dir, T, root, name, record, mode: a base the sweep must leave, and what it was
  _qswplant "$2" "$4" "$3" "$5"
  chmod "$6" "$2/$4"
  mkdir -p "$1/snap"
  _qswsnap "$2/$4" "$3" "$(_qswphys "$2")/$4/w" > "$1/snap/$4"
}
_qswleftis() {   # assertion, case dir, T, root, name, what became of the dead base beside it
  local was now reg=unregistered
  was="$(cat "$2/snap/$5" 2>/dev/null)"
  now="$(_qswsnap "$3/$5" "$4" "$(_qswphys "$3")/$5/w")"
  case "$was" in *" reg:yes") reg=registered ;; esac
  is "$1" "beside:$6 planted:$reg now:$now" "beside:gone planted:registered now:$was"
}

_qualify_sweep_build() {
  QSWS="$TMP/qual-sweep-side"; QSWSHIM="$QSWS/shim"; QSWHOLD="$QSWS/hold"; QSWL="$QSWS/launch"; QSWC="$QSWS/run-cli"
  QSWOLD='ThuJan100:00:001970'; QSWGIT="$(command -v git)"
  # A start no live process here has, in this host's own form: on a host whose
  # /proc names its pid namespace, tick 1 in that namespace and boot, since a
  # record of any other form is not one such a sweep may judge; elsewhere a ps
  # start long past. QSWDIFF is another such start; QSWPS is ps's form always.
  QSWPS="$QSWOLD"; QSWDIFF='MonJan100:00:002001'
  if [ -n "$(_qswns)" ]; then QSWOLD="1@$(_qswns)"; QSWDIFF="2@$(_qswns)"; fi
  : "${QSWLIVE=}" "${_qswpath=}" "${_qswxenv=}"
  [ -f "$QSWC" ] && return 0
QSWS="$TMP/qual-sweep-side"; mkdir -p "$QSWS"
: > "$QSWS/pids"; : > "$QSWS/roots"
QSWLIVE=""; _qswpath=""; _qswxenv=""
QSWGIT="$(command -v git)"
QSWSHIM="$QSWS/shim"; mkdir -p "$QSWSHIM"
cat > "$QSWSHIM/git" <<EOF
#!/bin/sh
if [ -n "\${QSW_GITLOG:-}" ]; then
  qsw_o=""
  case " \$* " in
    *" worktree add "*)
      for qsw_a in "\$@"; do
        case "\$qsw_a" in */w) if [ -L "\${qsw_a%/w}/owner" ]; then qsw_o=" owner:yes"; else qsw_o=" owner:no"; fi ;; esac
      done ;;
    *" worktree remove "*)
      for qsw_a in "\$@"; do qsw_l="\$qsw_a"; done
      case "\$qsw_l" in */w) qsw_o=" rec:[\$(readlink "\${qsw_l%/w}/owner" 2>/dev/null)] ppid:\$PPID" ;; esac ;;
  esac
  printf '%s%s\n' "\$*" "\$qsw_o" >> "\$QSW_GITLOG"
fi
# Given QSW_GITHOLD, a path: a worktree remove is noted there and held, never
# run, until the group it is in is killed.
if [ -n "\${QSW_GITHOLD:-}" ]; then
  case " \$* " in *" worktree remove "*) printf 'held\n' > "\$QSW_GITHOLD"; while :; do sleep 1; done ;; esac
fi
# Given QSW_GITSWAP, a directory: at the first worktree remove of a base's w,
# the base is renamed aside and a symlink to that directory put in its place,
# as a process a dead row left running could.
if [ -n "\${QSW_GITSWAP:-}" ] && [ ! -e "\$QSW_GITSWAP.done" ]; then
  case " \$* " in
    *" worktree remove "*)
      for qsw_a in "\$@"; do qsw_l="\$qsw_a"; done
      case "\$qsw_l" in
        */w) : > "\$QSW_GITSWAP.done"
             mv "\${qsw_l%/w}" "\${qsw_l%/w}.aside" && ln -s "\$QSW_GITSWAP" "\${qsw_l%/w}" ;;
      esac ;;
  esac
fi
# Given QSW_GITSWAPW, a directory: at the first worktree remove of a base's w,
# the tree itself is renamed aside and a symlink to that directory put in its
# place, the moment after whatever looked at it before git ran.
if [ -n "\${QSW_GITSWAPW:-}" ] && [ ! -e "\$QSW_GITSWAPW.done" ]; then
  case " \$* " in
    *" worktree remove "*)
      for qsw_a in "\$@"; do qsw_l="\$qsw_a"; done
      case "\$qsw_l" in
        */w|w) : > "\$QSW_GITSWAPW.done"
               mv "\$qsw_l" "\$qsw_l.aside" && ln -s "\$QSW_GITSWAPW" "\$qsw_l" ;;
      esac ;;
  esac
fi
# Given QSW_GITSWAPL, a directory: at the first worktree list, the one base
# in TMPDIR is renamed aside and a symlink to that directory put in its
# place, as the drop reads the root's list.
if [ -n "\${QSW_GITSWAPL:-}" ] && [ ! -e "\$QSW_GITSWAPL.done" ]; then
  case " \$* " in
    *" worktree list "*)
      for qsw_a in "\${TMPDIR%/}"/felix-qualify.??????; do
        if [ -d "\$qsw_a" ] && [ ! -L "\$qsw_a" ]; then
          : > "\$QSW_GITSWAPL.done"
          mv "\$qsw_a" "\$qsw_a.aside" && ln -s "\$QSW_GITSWAPL" "\$qsw_a"
          break
        fi
      done ;;
  esac
fi
exec '$QSWGIT' "\$@"
EOF
chmod +x "$QSWSHIM/git"
# mv, ln and rm that, given QSW_HOLDMV, QSW_HOLDLN or QSW_HOLDRM, a path, do
# their work, then note it there and hold until the group they are in is
# killed: a sweep stopped right after its first rename, its first link, or
# its first removal. A call whose last
# operand is empty, which is how the sweep asks mv which options it takes,
# is no rename and is not held.
QSWHOLD="$QSWS/hold"; mkdir -p "$QSWHOLD"
for _qswc in mv ln rm; do
  _qswv="QSW_HOLD$(printf '%s' "$_qswc" | tr a-z A-Z)"
  cat > "$QSWHOLD/$_qswc" <<EOF
#!/bin/sh
'$(command -v "$_qswc")' "\$@"; qsw_rc=\$?
qsw_l=""; for qsw_a in "\$@"; do qsw_l="\$qsw_a"; done
if [ -n "\${$_qswv:-}" ] && [ -n "\$qsw_l" ]; then printf 'held\n' > "\$$_qswv"; while :; do sleep 1; done; fi
exit \$qsw_rc
EOF
  chmod +x "$QSWHOLD/$_qswc"
done
# The caller of a run, as the CLI calls the runner: from inside the root,
# under set -uo pipefail, the libraries read, mktemp wrapped so every path it
# hands back is noted (and, for the one case that asks, left without its
# write bit when it is a row's base), its own pid written down, and, when
# given a go file, held until that file exists.
QSWL="$QSWS/launch"
cat > "$QSWL" <<'EOF'
set -uo pipefail
qsw_froot="$1"; qsw_root="$2"; qsw_made="$3"; qsw_caller="$4"; qsw_go="$5"; qsw_what="$6"; shift 6
cd "$qsw_root" || exit 1
. "$qsw_froot/harness/lib/resolve.sh"; . "$qsw_froot/harness/lib/qualify.sh"
# A staged proc filesystem, for the one case that asks.
[ -n "${QSW_PROC:-}" ] && _felix_qualify_proc="$QSW_PROC"
mktemp() {
  local p; p="$(command mktemp "$@")" || return
  printf '%s\n' "$p" >> "$qsw_made"
  if [ -n "${QSW_NORECORD:-}" ]; then
    case "$*" in *"/felix-qualify.XXXXXX"*) chmod a-w "$p" ;; esac
  fi
  printf '%s\n' "$p"
}
printf '%s\n' "$$" > "$qsw_caller"
if [ "$qsw_go" != - ]; then
  qsw_i=0
  while [ ! -e "$qsw_go" ] && [ "$qsw_i" -lt 3000 ]; do sleep 0.1 2>/dev/null || sleep 1; qsw_i=$((qsw_i + 1)); done
fi
case "$qsw_what" in
  run)   felix_qualify_run "$@" ;;
  sweep) _felix_qualify_sweep "$qsw_root" ;;
esac
EOF
QSWC="$QSWS/run-cli"
cat > "$QSWC" <<'EOF'
cd "$1" || exit 1
qsw_rc="$2"; shift 2
"$@"
printf '%s\n' "$?" > "$qsw_rc"
EOF
}

_qualify_sweep_cleanup() {
# What the section made, stopped and removed whatever the assertions said:
# its groups if any still run, the sleep, every path mktemp handed a run here,
# the immutable flags, its roots' registrations, then all of it.
[ -n "$QSWLIVE" ] && { kill -s KILL "$QSWLIVE" 2>/dev/null; wait "$QSWLIVE" 2>/dev/null; }
while IFS= read -r _qswp; do
  [ -n "$_qswp" ] || continue
  [ "$(ps -o ppid= -p "$_qswp" 2>/dev/null | tr -d ' ')" = "$$" ] && _qswstop "$_qswp"
done < "$QSWS/pids"
find "$QSWS" -type f -name made 2>/dev/null > "$TMP/qual-sweep-made"
while IFS= read -r _qswm; do
  while IFS= read -r _qswp; do
    case "$_qswp" in /?*) ;; *) continue ;; esac
    if [ -e "$_qswp" ] || [ -L "$_qswp" ]; then
      find "$_qswp" -type d -exec chmod u+rwx {} \; 2>/dev/null
      if command -v chflags >/dev/null 2>&1; then chflags -R nouchg "$_qswp" 2>/dev/null; fi
      rm -rf "$_qswp" 2>/dev/null
    fi
  done < "$_qswm"
done < "$TMP/qual-sweep-made"
rm -f "$TMP/qual-sweep-made"
find "$QSWS" -type d ! -perm -0700 -exec chmod u+rwx {} \; 2>/dev/null
if command -v chflags >/dev/null 2>&1; then chflags -R nouchg "$QSWS" 2>/dev/null; fi
while IFS= read -r _qswr; do
  [ -d "$_qswr/.git" ] || continue
  rm -f "$_qswr"/.git/worktrees/*/locked 2>/dev/null
  _fx_git "$_qswr" worktree prune >/dev/null 2>&1
done < "$QSWS/roots"
rm -rf "$QSWS"
  QSWLIVE=""
}
