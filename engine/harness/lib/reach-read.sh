# Reach, the read: `claude mcp list` run once, and parsed into server rows.
#
# Sourced by lib/reach.sh, which classifies what this reads against a project's
# declared plugin and mcp rows (the head of that file says why none of it may
# ever sit on the enforcing path). This file holds the one place Felix runs
# `claude mcp list` for reach, and the rules for where it may run.
#
# A detail never carries a URL's query string, which can hold a key: the target
# column of a list line is never copied, and the status text is cut before its
# first question mark. It is not truncated by bytes, because a byte cut can
# split a multibyte character and one bad byte empties a macOS UTF-8 sort.
#
# THE LIST IS READ FROM AN EMPTY DIRECTORY, NEVER THE CHECKOUT. `claude mcp list`
# starts the servers it lists, a project-scoped one included once it is approved
# or auto-enabled (enableAllProjectMcpServers), and this runs at every session
# start of every governed project, repositories opened to hunt for bugs among
# them. Measured 2026-10-12 with the real CLI: a server pending approval is
# listed and not started, so reading in the checkout was safe only while Claude
# Code's approval state held; from an empty directory it is not listed at all,
# but the CLI walks up to a parent's .mcp.json, so a scratch directory with one
# above it is refused. felix_reach_read makes a fresh directory under TMPDIR
# (never the checkout, never $HOME, itself a repository here), reads from there,
# removes it, and when it cannot reads nothing, never in the caller's directory.
# A server only a project's .mcp.json declares is not seen: unknown, not not-listed.
#
# AND TMPDIR MUST BE A DIRECTORY NOBODY ELSE CAN WRITE. The first version fell
# back to /tmp, and checking for a .mcp.json above the scratch directory does not
# make that safe: /tmp is world-writable (sticky stops a delete, not a create),
# so another local user can plant /tmp/.mcp.json after the check and before the
# read, and the CLI then finds it from the parent. A check cannot close a race;
# a place where no one else can write can. So the scratch directory is made only
# under a TMPDIR that is absolute, owned by the user with no group or other write
# bit, with every ancestor up to / owned by root or the user and writable by
# neither group nor others (read on the physical path, so a symlink is judged by
# where it leads). Anything else, an unset or relative TMPDIR included, runs no
# claude: unknown, with the sentence that says why. macOS's per-user temporary
# directory passes; a Linux machine whose TMPDIR is unset or under /tmp does not,
# and reads unknown until TMPDIR names a private directory. Other processes of
# the same user are not a boundary here, and an ACL granting someone else write
# is not read.

# Sourced by path because the suite sources libraries alone, in subshells, and a
# call that resolved to nothing would degrade to saying nothing (house pattern).
if ! command -v _felix_mcp_line_set >/dev/null 2>&1; then
  . "$(dirname "${BASH_SOURCE[0]:-$0}")/stack.sh"
fi

# One line of the list as a server row `key<TAB>state<TAB>detail`, or nothing
# for a line that is not a server line. A server line holds `: ` and the text
# before the first `: ` (its key) holds no space, so the health header, the
# blank line and prose are ignored. Reads the list on stdin.
_felix_reach_parse() {
  local line key state phrase d tab=$'\t' cr=$'\r'
  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in *": "*) ;; *) continue ;; esac
    key="${line%%: *}"
    case "$key" in ''|*" "*) continue ;; esac
    _felix_mcp_line_set "$line"; state="$_FELIX_MCP_STATE"
    case "$state" in
      failed)     phrase="Failed to connect" ;;
      needs-auth) phrase="Needs authentication" ;;
      connected)  phrase="Connected" ;;
      *)          phrase="" ;;
    esac
    if [ -n "$phrase" ]; then
      d="$phrase${line#*"$phrase"}"
    else
      state=unknown
      case "$line" in *" - "*) d="${line##* - }" ;; *) d="" ;; esac
    fi
    d="${d%%\?*}"
    d="${d//$tab/ }"; d="${d//$cr/ }"
    [ -n "$d" ] || d="-"
    key="${key//$tab/ }"; key="${key//$cr/ }"
    printf '%s\t%s\t%s\n' "$key" "$state" "$d"
  done
}

# Remove a scratch directory felix_neutral_dir made, and whatever was left in
# it. Only a path shaped as mktemp gave it from <prefix>, absolute and not a
# symlink; a prefix that is not lowercase letters and dashes removes nothing.
# Always 0.
felix_neutral_rm() {
  local lc=abcdefghijklmnopqrstuvwxyz
  case "${2:-}" in ''|[!$lc]*|*[!$lc-]*) return 0 ;; esac
  case "${1:-}" in
    /*/"$2".??????) [ -d "$1" ] && [ ! -L "$1" ] && rm -rf "$1" 2>/dev/null ;;
  esac
  return 0
}

# 0 when no directory from $1 up to / holds a .mcp.json (the CLI reads a parent's).
_felix_reach_neutral() {
  local d="$1"
  while :; do
    [ -e "$d/.mcp.json" ] && return 1
    [ -n "$d" ] || return 0
    d="${d%/*}"
  done
}

# `uid mode` of the directory $1, or nothing when no way of asking can say. GNU
# stat (-c) is tried first because BSD stat has no -c and fails at once; then
# BSD stat (-f), which on GNU means something else and prints no two numbers;
# each answer must be a decimal uid and octal permission digits, or it is not
# taken. Where neither stat answers, `ls -ldn` is read: its uid is the third
# field, and the group and other write bits are the 6th and 9th characters of
# its mode string, from which the mode is rebuilt as those bits alone.
_felix_reach_owner_mode() {
  local d="$1" m u p perm links o=0 form
  for form in c f; do
    case "$form" in
      c) m="$(stat -c '%u %a' "$d" 2>/dev/null)" || m="" ;;
      *) m="$(stat -f '%u %Lp' "$d" 2>/dev/null)" || m="" ;;
    esac
    case "$m" in *" "*) ;; *) continue ;; esac
    u="${m%% *}"; p="${m#* }"
    case "$u" in ''|*[!0123456789]*) continue ;; esac
    case "$p" in ''|*[!01234567]*) continue ;; esac
    [ "${#p}" -le 5 ] || continue
    printf '%s %s' "$u" "$p"; return 0
  done
  m="$(ls -ldn -- "$d" 2>/dev/null)" || m=""
  [ -n "$m" ] || return 0
  read -r perm links u _ <<< "$m"
  case "$u" in ''|*[!0123456789]*) return 0 ;; esac
  case "$perm" in d?????????*) ;; *) return 0 ;; esac
  [ "${perm:5:1}" = w ] && o=$((o + 16))
  [ "${perm:8:1}" = w ] && o=$((o + 2))
  printf '%s %o' "$u" "$o"
}

# 0 when nobody but the current user (and root) can write into the directory $1
# or into any directory above it. $1 is a physical path (pwd -P). The directory
# is the user's own (test -O); it and every ancestor up to / is owned by root or
# the user and has neither the group nor the other write bit. When nothing can
# say who owns a directory or what its mode is, it is not taken to be private.
_felix_reach_private() {
  local d="$1" me om u m
  me="$(id -u 2>/dev/null)"
  case "$me" in ''|*[!0123456789]*) return 1 ;; esac
  case "$d" in /*) ;; *) return 1 ;; esac
  [ -d "$d" ] && [ -O "$d" ] || return 1
  while :; do
    om="$(_felix_reach_owner_mode "$d")"
    [ -n "$om" ] || return 1
    u="${om%% *}"; m="${om#* }"
    [ "$u" = 0 ] || [ "$u" = "$me" ] || return 1
    [ "$(( 8#$m & 8#22 ))" -eq 0 ] || return 1
    [ "$d" != / ] || return 0
    d="${d%/*}"; [ -n "$d" ] || d=/
  done
}

# A fresh empty directory to run a command in when that command must not see the
# checkout: this is the directory-making half of felix_reach_read, moved here so
# the one other thing that needs it (felix_neutral_run, below) calls the same
# code instead of copying it. It is made as "$phys/<prefix>.XXXXXX" under the
# physical path of $TMPDIR, only when TMPDIR is absolute and private by the rules
# in the head of this file, and it is not a place a .mcp.json can reach. 0 with
# the physical path in _FELIX_NEUTRAL_DIR; otherwise nothing it made is left and
# the status says why:
#   1  TMPDIR is not an absolute path
#   2  TMPDIR is not a private directory (_felix_reach_private)
#   3  the directory could not be made, entered or trusted, a TMPDIR of / and a
#      <prefix> that is not lowercase letters and dashes included
#   4  a .mcp.json sits at or above the directory (_felix_reach_neutral)
felix_neutral_dir() {
  local prefix="${1:-}" phys made dir="" lc=abcdefghijklmnopqrstuvwxyz
  _FELIX_NEUTRAL_DIR=""
  case "$prefix" in ''|[!$lc]*|*[!$lc-]*) return 3 ;; esac
  case "${TMPDIR:-}" in /*) ;; *) return 1 ;; esac
  phys="$(cd "$TMPDIR" 2>/dev/null && pwd -P)" || phys=""
  case "$phys" in ''|/) return 3 ;; esac
  _felix_reach_private "$phys" || return 2
  made="$(mktemp -d "$phys/$prefix.XXXXXX" 2>/dev/null)" || made=""
  case "$made" in /*/"$prefix".??????) ;; *) made="" ;; esac
  if [ -n "$made" ] && [ -d "$made" ] && [ ! -L "$made" ]; then
    dir="$(cd "$made" 2>/dev/null && pwd -P)" || dir=""
  fi
  if [ -z "$dir" ]; then felix_neutral_rm "$made" "$prefix"; return 3; fi
  if ! _felix_reach_neutral "$dir"; then felix_neutral_rm "$made" "$prefix"; return 4; fi
  _FELIX_NEUTRAL_DIR="$dir"
  return 0
}

# Run <cmd> [args...] in a fresh neutral directory and not in the checkout, as
# the project <proj> (a path under the Felix home): `felix_neutral_run <proj>
# <prefix> <cmd> [args...]`. The directory holds one file, a .felix naming the
# project, which is the marker mechanism used as designed (the binding is by
# marker, and this directory is one Felix made itself), so a command that
# resolves its project from $PWD finds the same one it would have in the
# checkout without reading a byte of it. The command's stdout is passed
# through, its stdin is closed, and its status is returned after the directory
# is gone. 125 when the command was not run: no neutral directory (any
# felix_neutral_dir status), a marker that could not be written, or a directory
# git or the environment places inside a repository (felix_repo_root must name
# the directory itself, or the marker would not be the one read). It never runs
# the command in any other directory. A command may exit 125 itself, so the
# status alone does not say whether it started: _FELIX_NEUTRAL_NOTRUN does, 0
# once it was started, and otherwise why not (1 to 4 felix_neutral_dir's
# statuses, 5 the marker, the repository test or the arguments).
felix_neutral_run() {
  local proj="${1:-}" prefix="${2:-}" dir rc
  _FELIX_NEUTRAL_NOTRUN=5
  [ "$#" -ge 3 ] && [ -n "$proj" ] || return 125
  shift 2
  felix_neutral_dir "$prefix" || { _FELIX_NEUTRAL_NOTRUN=$?; return 125; }
  dir="$_FELIX_NEUTRAL_DIR"
  if ! printf '%s\n' "$(basename "$proj")" > "$dir/.felix" 2>/dev/null \
     || [ "$(felix_repo_root "$dir")" != "$dir" ]; then
    felix_neutral_rm "$dir" "$prefix"; return 125
  fi
  _FELIX_NEUTRAL_NOTRUN=0
  ( cd "$dir" 2>/dev/null || exit 125; "$@" </dev/null )
  rc=$?
  felix_neutral_rm "$dir" "$prefix"
  return "$rc"
}

# Run `claude mcp list` once, from a fresh empty directory (the head of this file
# says why). 0 when read, with the server table in _FELIX_REACH_SRV and the
# directory it ran in in _FELIX_REACH_CWD; 1 when not, one sentence in
# _FELIX_REACH_WHY. The directory is made under $TMPDIR with a template (a bare
# mktemp on macOS ignores TMPDIR), only when TMPDIR is absolute and private
# (_felix_reach_private; there is no default to fall back to), and removed once
# the command returns, on every path. When it cannot be made, entered or
# trusted, claude is not run at all.
# Output, exit status and a sentinel come back in one substitution: one that
# cannot make its pipe expands to nothing with status 0 on bash 3.2, and that
# must read as unread, never as an empty list. stderr is discarded. No timeout:
# nobody waits on the background read, a person running --reach can interrupt it,
# and macOS ships no `timeout` binary to bound it with.
felix_reach_read() {
  local out rc body parsed nl=$'\n' ws=$' \t\r\n' dir=""
  _FELIX_REACH_OK=0; _FELIX_REACH_WHY=""; _FELIX_REACH_SRV=""; _FELIX_REACH_CWD=""
  if ! command -v claude >/dev/null 2>&1; then
    _FELIX_REACH_WHY="no claude CLI on PATH"; return 1
  fi
  # No default: an unset TMPDIR would send it to a shared place, and a relative
  # one to a directory under the caller's own. The sentences are this read's;
  # what makes the directory, and what each status means, is felix_neutral_dir.
  felix_neutral_dir felix-reach; rc=$?
  case "$rc" in
    0) dir="$_FELIX_NEUTRAL_DIR" ;;
    1) _FELIX_REACH_WHY="TMPDIR is not an absolute path, so there is no private directory to run claude mcp list in"; return 1 ;;
    2) _FELIX_REACH_WHY="TMPDIR is not a private directory, so claude mcp list was not run: it must be owned by you and writable by no one else, under parents only you or root can write"; return 1 ;;
    4) _FELIX_REACH_WHY="a .mcp.json sits above the scratch directory, so claude mcp list could start a project-scoped server there"; return 1 ;;
    *) _FELIX_REACH_WHY="could not make an empty directory to run claude mcp list in"; return 1 ;;
  esac
  out="$(cd "$dir" 2>/dev/null && claude mcp list 2>/dev/null </dev/null; printf '\n.%s' "$?")"
  felix_neutral_rm "$dir" felix-reach
  case "$out" in
    *"$nl."[0123456789]*) ;;
    *) _FELIX_REACH_WHY="the list's output could not be captured"; return 1 ;;
  esac
  rc="${out##*"$nl."}"
  case "$rc" in
    ''|*[!0123456789]*) _FELIX_REACH_WHY="the list's output could not be captured"; return 1 ;;
  esac
  body="${out%"$nl.$rc"}"
  if [ "$rc" != 0 ]; then
    _FELIX_REACH_WHY="claude mcp list exited $rc"; return 1
  fi
  # Tested with case and not by stripping the whitespace out with ${body//..//}:
  # on bash 3.2 a global substitution over a list this size is quadratic, three
  # seconds for a hundred lines.
  case "$body" in
    *[!$ws]*) ;;
    *) _FELIX_REACH_WHY="claude mcp list printed nothing"; return 1 ;;
  esac
  parsed="$(printf '%s\n' "$body" | _felix_reach_parse; printf '.')"
  case "$parsed" in
    *.) _FELIX_REACH_SRV="${parsed%.}" ;;
    *)  _FELIX_REACH_WHY="the list's output could not be captured"; return 1 ;;
  esac
  _FELIX_REACH_CWD="$dir"
  _FELIX_REACH_OK=1
  return 0
}
