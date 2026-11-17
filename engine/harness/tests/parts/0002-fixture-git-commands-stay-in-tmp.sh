# ------------- a cd on a variable and a git -C on a variable stay in $TMP ----
# Two shapes of fixture line in this file edit a repository named by a
# variable: `( cd "$dir" && git remote set-url origin ... )`, and
# `git -C "$dir" ...`. These two are what this part covers; a fixture that
# reaches a repository another way, such as a helper of its own that runs git
# -C or the engine run after a raw cd, is not one of them (the section after
# the pipefail lint says what closes the second). When $dir is empty,
# bash 3.2 takes `cd ""` as a success and stays where it stands, and git -C ""
# does the same, so the command
# edits whatever repository encloses the working directory (measured on bash
# 3.2.57 and git 2.54, 2026-10-08). That is how felix-home's origin became
# acme/widget. A directory that exists but where `git init` never ran does the
# same through git's walk up to the first repository above it, and so does an
# inherited GIT_DIR.
#
# So a fixture does not cd and does not git -C on a variable before a git
# write. _fx_cd and
# _fx_git take the directory and prove it first: it must name a directory,
# whose physical path (symlinks resolved, as cd -P gives it) lies strictly
# below the physical $TMP; none of GIT_DIR, GIT_WORK_TREE, GIT_COMMON_DIR,
# GIT_INDEX_FILE, GIT_OBJECT_DIRECTORY, GIT_ALTERNATE_OBJECT_DIRECTORIES or
# GIT_CONFIG may be set; _fx_cd may not run in the suite's own shell, which it
# would move; and the first .git met walking up from the directory, short of
# $TMP, must be a directory, or a gitfile or symlink that points physically
# below $TMP, so a worktree's .git cannot hand git a repository elsewhere. A
# .git directory counts only when it is a valid git dir, as git's own walk
# counts it, and one whose commondir names a directory outside $TMP is
# refused. _fx_git also refuses -C, --git-dir and --work-tree before the
# subcommand, which would name another repository after the proof; -c k=v is
# allowed.
# $TMP itself is not under $TMP, since `cd "$TMP/$empty"` lands there. On
# success the shell stands in the directory, physically, with $TMP at the head
# of GIT_CEILING_DIRECTORIES, so git run there cannot find a repository at or
# above $TMP even where the directory holds no .git. A refusal changes no
# directory and no variable, appends a line to $FELIX_TEST_FXREFUSED, and
# says so on stderr. The line's number is BASH_LINENO's, which bash 3.2 gets
# wrong inside a $( ) that spans lines: there it reads the call's line plus the
# call's distance from the line that opened the $( (measured 2026-10-08). No
# converted fixture site sits inside one; the probes of the fixture git proof
# section do, and compare the record with $LINENO, which is off by the same
# amount. The line goes to a file because the fixtures redirect
# both streams to /dev/null and run in subshells, where a counter is lost; the
# end of the run reads the file and goes red on any line in it.
#
# No fork on the success path, so a fork that fails under load cannot become
# an empty answer that is taken for a proof: cd -P, $PWD, read and parameter
# expansion only. A relative directory is given a ./ because `cd -- -` still
# means OLDPWD.
FELIX_TEST_FXREFUSED="$TMP/fx-refused"
_fx_tmp=""; _og_phys "$TMP" && _fx_tmp="$_og_p"
# The roots a fixture directory may lie below, one physical path a line: $TMP,
# and any base a part made for its own fixtures outside $TMP and registered
# with _fx_root_add. Everything below that this comment block says of $TMP holds
# of each root, the ceiling included: it is the root the directory lies below.
_fx_roots="$_fx_tmp"
# The root the directory _fx_chdir is proving lies below. _fx_gitdir's walk stops
# there, and _fx_below accepts only a path below it, so a .git under $TMP never
# vouches for one under another root, nor the other way round.
_fx_walkroot=""
# PATH -> 0, with _fx_r set to the root PATH lies strictly below, or 1 and
# _fx_r empty. Parameter expansion only, no fork and no temporary file.
_fx_root_for() {
  local rest="$_fx_roots" r
  _fx_r=""
  while [ -n "$rest" ]; do
    r="${rest%%$'\n'*}"
    case "$rest" in *$'\n'*) rest="${rest#*$'\n'}" ;; *) rest="" ;; esac
    [ -n "$r" ] || continue
    case "$1/" in "$r"/?*) _fx_r="$r"; return 0 ;; esac
  done
  return 1
}
# DIR -> 0 when DIR is, or already lies below, a root. Parts 1100 and 1130 need a
# base whose every ancestor only root or this user can write (the reach read's
# R13), and where $TMP sits under a shared /tmp, as on a Linux runner, they
# make one elsewhere: XDG_RUNTIME_DIR, RUNNER_TEMP or HOME. They register it
# here at once, right after mktemp -d makes it, so their fixture git lines stand
# behind _fx_cd and _fx_git as every other fixture's do. Refused with a record,
# and nothing added, when DIR is empty, not absolute or no directory, when it is
# /, when its physical path holds a newline or a colon (the separators of this
# list and of GIT_CEILING_DIRECTORIES), when it already holds anything (a base
# that holds a checkout would vouch for it, and a fresh base holds nothing),
# and when a .git of any kind stands in DIR or in any directory above it: in a
# directory where `git init` never ran git walks up, only the root's ceiling
# stops it, and a root inside a checkout would hand that checkout a fixture's
# write. A refusal leaves the base unregistered, so every fixture line under it
# is refused in turn and the run goes red at its end; nothing reads as safe that
# was not proven. A DIR that is, or lies below, a root already adds nothing.
_fx_root_add() {
  local at="${BASH_LINENO[0]}" d="${1-}" p e back="$PWD" old="${OLDPWD-}" hadold="${OLDPWD+x}"
  case "$d" in /*) ;; *) _fx_refuse "$at" "$d" root-not-absolute; return 1 ;; esac
  if ! cd -P -- "$d" >/dev/null 2>&1; then _fx_refuse "$at" "$d" root-not-a-directory; return 1; fi
  p="$PWD"
  cd -- "$back" >/dev/null 2>&1
  if [ -n "$hadold" ]; then OLDPWD="$old"; else unset OLDPWD; fi
  [ "$p" != / ] || { _fx_refuse "$at" "$d" root-is-slash; return 1; }
  _fx_root_for "$p/." && return 0
  case "$p" in *$'\n'*|*:*) _fx_refuse "$at" "$d" root-unsafe-name; return 1 ;; esac
  for e in "$p"/* "$p"/.[!.]* "$p"/..?*; do
    if [ -e "$e" ] || [ -L "$e" ]; then _fx_refuse "$at" "$d" root-not-empty; return 1; fi
  done
  d="$p"
  while :; do
    if [ -e "$d/.git" ] || [ -L "$d/.git" ]; then _fx_refuse "$at" "$1" root-in-a-checkout; return 1; fi
    [ -n "$d" ] || break
    d="${d%/*}"
  done
  _fx_roots="$_fx_roots${_fx_roots:+$'\n'}$p"
  return 0
}
# DIR -> DIR is no longer a root, before the part that made it removes it, so a
# path that later reappears there is not vouched for. $TMP is never removed.
_fx_root_del() {
  local p rest="$_fx_roots" r out=""
  p="$(cd -P -- "${1:-/nonexistent}" 2>/dev/null && pwd -P)" || return 0
  [ "$p" != "$_fx_tmp" ] || return 0
  while [ -n "$rest" ]; do
    r="${rest%%$'\n'*}"
    case "$rest" in *$'\n'*) rest="${rest#*$'\n'}" ;; *) rest="" ;; esac
    [ -n "$r" ] && [ "$r" != "$p" ] && out="$out${out:+$'\n'}$r"
  done
  _fx_roots="$out"
  return 0
}
# LINE DIR WHY -> the refusal's line in the record, and its line on stderr.
_fx_refuse() {
  printf '%s\t%s\t%s\n' "$1" "$2" "$3" >> "${FELIX_TEST_FXREFUSED:-/dev/null}" 2>/dev/null
  printf 'tests/run: _fx_cd refused %s: line %s, directory [%s]\n' "$3" "$1" "$2" >&2
}
# ABSOLUTE-PATH STRICT -> 0 when the path lies physically strictly below the
# root _fx_chdir is proving, $_fx_walkroot; with none set, nothing is below it.
# The path is entered with cd -P and the shell is put back where it stood. A
# path that does not exist, a gitfile's pointer to a worktree since removed, is
# judged by the nearest directory above it that can be entered, with the rest
# appended, and a rest holding .. is refused. With STRICT non-empty the path
# itself must be entered: a symlink .git is judged by its target, and only cd
# can name a target without a fork, so a target that is not a directory is
# refused.
_fx_below() {
  local p="$1" rest="" back="$PWD" got
  [ -n "$_fx_walkroot" ] || return 1
  case "$p" in /*) ;; *) return 1 ;; esac
  until cd -P -- "${p:-/}" >/dev/null 2>&1; do
    [ -z "$2" ] && [ -n "$p" ] || return 1
    rest="/${p##*/}$rest"; p="${p%/*}"
  done
  got="${PWD%/}$rest"
  cd -P -- "$back" >/dev/null 2>&1 || return 1
  case "$rest/" in */../*) return 1 ;; esac
  case "$got/" in "$_fx_walkroot"/?*) return 0 ;; esac
  return 1
}
# GITDIR -> 0 when GITDIR holds no commondir, or one that names a directory
# physically below the root: a valid git directory that shares the config and
# refs of the directory its commondir names writes there. Read with the read
# builtin, relative to GITDIR when relative. One that cannot be read names
# nothing that can be proven, and is refused. A gitfile's target is held to
# this as a .git directory is: a worktree's gitdir under $TMP whose commondir
# names a repository outside it would hand git that repository's config.
_fx_commondir_ok() {
  local g="$1" l
  { [ -e "$g/commondir" ] || [ -L "$g/commondir" ]; } || return 0
  l=""
  IFS= read -r l 2>/dev/null < "$g/commondir" || [ -n "$l" ] || return 1
  l="${l%$'\r'}"
  [ -n "$l" ] || return 1
  case "$l" in /*) ;; *) l="$g/$l" ;; esac
  _fx_below "$l" ""
}
# -> 0 when the first .git entry that decides, walking up from $PWD with $TMP
# itself not reached, is a valid git directory, is a gitfile or a symlink that
# points physically below $TMP, or is not there at all, since the ceiling
# stops git at $TMP. The gitfile's pointer is its gitdir: line, read with the
# read builtin, and a relative one is relative to the directory holding the
# .git. A gitfile that cannot be read or holds no gitdir: line, and a .git of
# any other type, are refused: what they name cannot be proven.
#
# A .git directory decides only as git's own walk would have it decide: when
# it is a valid git dir, holding a regular file HEAD, a directory objects and
# a directory refs. An empty or partial one is passed over, as git passes it,
# and the walk goes on upward. A symlink .git must point below $TMP, and is
# then judged as the directory it names. A valid one that holds a commondir
# file shares the config and refs of the directory that file names, so that
# directory must lie physically below $TMP too: its first line, read with the
# read builtin, relative to the .git directory when relative. A commondir that
# cannot be read names nothing that can be proven, and is refused.
_fx_gitdir() {
  local d="$PWD" g l
  while :; do
    case "$d/" in "$_fx_walkroot"/?*) ;; *) return 0 ;; esac
    g="$d/.git"
    if [ -L "$g" ]; then _fx_below "$g" 1 || return 1; fi
    if [ -d "$g" ]; then
      if [ -f "$g/HEAD" ] && [ -d "$g/objects" ] && [ -d "$g/refs" ]; then
        _fx_commondir_ok "$g"; return
      fi
    elif [ -L "$g" ]; then return 1
    elif [ -f "$g" ]; then
      l=""
      IFS= read -r l 2>/dev/null < "$g" || [ -n "$l" ] || return 1
      l="${l%$'\r'}"
      case "$l" in "gitdir: "?*) l="${l#gitdir: }" ;; *) return 1 ;; esac
      case "$l" in /*) ;; *) l="$d/$l" ;; esac
      _fx_below "$l" "" || return 1
      _fx_commondir_ok "$l"; return
    elif [ -e "$g" ]; then return 1
    fi
    d="${d%/*}"
  done
}
_fx_chdir() {   # LINE DIR -> stands in DIR when it is proven, else returns 1 with a record
  local at="$1" d="${2-}" why="" t was="$PWD" old="${OLDPWD-}" hadold="${OLDPWD+x}" ent="" root=""
  if [ -z "$d" ]; then why=empty
  else
    case "$d" in /*) t="$d" ;; *) t="./$d" ;; esac
    if cd -P -- "$t" >/dev/null 2>&1; then
      ent=1; _fx_walkroot=""
      if _fx_root_for "$PWD"; then root="$_fx_r"; _fx_walkroot="$root"; else why=outside-tmp; fi
      if [ -z "$why" ]; then
        if [ -n "${GIT_DIR:-}${GIT_WORK_TREE:-}${GIT_COMMON_DIR:-}${GIT_INDEX_FILE:-}${GIT_OBJECT_DIRECTORY:-}${GIT_ALTERNATE_OBJECT_DIRECTORIES:-}${GIT_CONFIG:-}" ]; then why=git-env
        elif [ "$BASH_SUBSHELL" -eq 0 ]; then why=top-level
        elif ! _fx_gitdir; then why=gitdir-outside
        fi
      fi
    else why=not-a-directory
    fi
  fi
  if [ -n "$why" ]; then
    if [ -n "$ent" ]; then
      cd -- "$was" >/dev/null 2>&1
      if [ -n "$hadold" ]; then OLDPWD="$old"; else unset OLDPWD; fi
    fi
    _fx_refuse "$at" "$d" "$why"
    return 1
  fi
  OLDPWD="$was"
  GIT_CEILING_DIRECTORIES="$root${GIT_CEILING_DIRECTORIES:+:$GIT_CEILING_DIRECTORIES}"
  export GIT_CEILING_DIRECTORIES
  return 0
}
_fx_cd()  { _fx_chdir "${BASH_LINENO[0]}" "${1-}"; }
# LINE DIR ARGS... -> 1 with a record when an option anywhere before git's
# subcommand names a repository or a work tree of its own: -C, --git-dir and
# --work-tree, with the value as the next word or after =. -c k=v is allowed.
# The global options that take their value as a separate word, -c,
# --namespace, --config-env and --attr-source, have that word skipped, so a
# value is never read as the subcommand and the options after it are still
# seen.
_fx_gargs() {
  local at="$1" d="$2" a sk=""
  shift 2
  for a in "$@"; do
    if [ -n "$sk" ]; then sk=""; continue; fi
    case "$a" in
      -C|--git-dir|--git-dir=*|--work-tree|--work-tree=*) _fx_refuse "$at" "$d" git-args; return 1 ;;
      -c|--namespace|--config-env|--attr-source) sk=1 ;;
      -*) ;;
      *) return 0 ;;
    esac
  done
  return 0
}
_fx_git() { ( _fx_chdir "${BASH_LINENO[0]}" "${1-}" || exit 1
              _fx_gargs "${BASH_LINENO[0]}" "$@" || exit 1
              shift && command git "$@" ); }

