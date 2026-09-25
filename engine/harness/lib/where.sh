# Where a command acts.
#
# A deny.tsv row is a regex over the command's text, and most rows protect the
# governed checkout: its binding, its remote, its remote-tracking refs, its
# index. The text cannot say which repository a command acts on. On 2026-09-23
# the refusals the hooks had logged were replayed: of 175, more than a hundred
# were real commands run in throwaway fixtures under the session scratchpad —
# `printf 'widget\n' > .felix` binding a fixture repository, `git remote add`
# in a fresh `git init`, `git update-ref refs/remotes/...` in a scratch clone,
# `git add -A` in a fixture — refused for protecting a checkout they never
# touched. Sessions routed around the rows or gave the work up.
#
# So a row may say, in a fourth column, that it applies only to the governed
# checkout (see lib/deny.sh), and this decides whether a matched command acts
# anywhere else. lib/where-read.sh reads the command as a shell would and writes
# every place each simple command can act on; this half judges those places
# against the disk. A row lifts only when every simple command it matches acts
# only on throwaway places, and once their own text is blanked the row
# matches nothing left: an occurrence in text no command carries — a
# here-document of data, a comment, something the reader skipped — keeps it.
#
# Throwaway means under a temporary root (the physical /tmp, or $TMPDIR), and
# not in, above, or in a worktree of the governed repository. A root that
# holds $HOME is no root, so $HOME and the .felix-home pointer in it are never
# throwaway, even under a test that moves $HOME. Closed, not open: another
# repository under ~/Documents is not throwaway, because the hook resolves one
# project from its own directory and that repository's rows are never asked.
#
# Invariant 2 in both directions. Bash, git and awk only, no network. And this
# can only ever turn a refusal into an allow, for a row that asked for it:
# whatever it cannot read, parse or find — an awk that fails, a path it cannot
# resolve, a command that runs text as code — reads as "cannot be told", and
# the row stands exactly as it would have without the column. Failing open
# here would mean failing to refuse what the table already refuses.
#
# What it cannot see, said once: a program that deletes and recreates a
# directory it was never told about; a file written by anything but a
# here-document, run by a name the line never spells; a gitdir: file planted
# to point a scratch path into the checkout. The floor is a floor.

. "${BASH_SOURCE[0]%/*}/where-read.sh" 2>/dev/null || _FELIX_WHERE_READ=""

# Whether a lifted row still stood, and why, for the refusal message.
_FELIX_WHERE_WHY=""

# The governed checkout, read once per process: its top level, its git
# common directory, $HOME, and the temporary roots.
_felix_where_ident() {
  local g="$1" out top common r root
  [ -n "${_FW_ID:-}" ] && [ "$_FW_ID" = "$g" ] && return 0
  out="$(cd "$g" 2>/dev/null && unset GIT_DIR GIT_WORK_TREE GIT_COMMON_DIR \
    && git rev-parse --show-toplevel --git-common-dir 2>/dev/null)" || out=""
  top="${out%%$'\n'*}"; common=""
  case "$out" in *$'\n'*) common="${out#*$'\n'}" ;; esac
  [ -n "$top" ] || top="$g"
  _FW_GTOP="$(cd -P "$top" 2>/dev/null && pwd -P)" || return 1
  _FW_GCOMMON=""
  [ -n "$common" ] && _FW_GCOMMON="$(cd "$g" 2>/dev/null && cd -P "$common" 2>/dev/null && pwd -P)"
  _FW_HOMEP="$(cd -P "$HOME" 2>/dev/null && pwd -P)" || _FW_HOMEP="$HOME"
  _FW_ROOTS=""
  for r in /tmp "${TMPDIR:-}"; do
    [ -n "$r" ] && [ -d "$r" ] || continue
    root="$(cd -P "$r" 2>/dev/null && pwd -P)" || continue
    # A temporary root that holds $HOME holds everything that matters, the
    # .felix-home pointer first, and / holds everything. Excluding it is also
    # what keeps $HOME itself from ever being throwaway.
    _felix_where_under "$_FW_HOMEP" "$root" && continue
    _FW_ROOTS="$_FW_ROOTS$root"$'\n'
  done
  _FW_COMMONS=""
  _FW_ID="$g"
}

# Whether path $1 is $2 or lies beneath it.
_felix_where_under() {
  [ "$2" = / ] && return 0
  case "$1" in "$2"|"$2"/*) return 0 ;; esac
  return 1
}

# The git common directory governing an existing directory, physically, or
# nothing. Cached, since fixtures put many places in one directory.
_felix_where_common() {
  local d="$1" line c
  while IFS= read -r line; do
    [ "${line%%$'\t'*}" = "$d" ] && { printf '%s' "${line#*$'\t'}"; return 0; }
  done <<EOF
$_FW_COMMONS
EOF
  c="$(cd "$d" 2>/dev/null && unset GIT_DIR GIT_WORK_TREE GIT_COMMON_DIR \
    && c="$(git rev-parse --git-common-dir 2>/dev/null)" && cd -P "$c" 2>/dev/null && pwd -P)" || c=""
  _FW_COMMONS="$_FW_COMMONS$d"$'\t'"$c"$'\n'
  printf '%s' "$c"
}

# The path with . and .. taken off by their spelling, the way cd reads it
# unless it is given -P: `$GOV/link/..` is the checkout to cd, whatever the
# link points at.
_felix_where_lexical() {
  local p="$1" c out="" IFS=/
  local -a parts
  read -r -a parts <<EOF
$p
EOF
  for c in ${parts[@]+"${parts[@]}"}; do
    case "$c" in
      ''|.) ;;
      ..) out="${out%/*}" ;;
      *) out="$out/$c" ;;
    esac
  done
  printf '%s' "${out:-/}"
}

# Whether one absolute path is throwaway: under a temporary root, and neither
# in, above, nor sharing a repository with the governed checkout.
# Judged physically, from the deepest part of it that exists now, and by its
# spelling as well, since cd reads .. by spelling.
_felix_where_throwaway() {
  local p="$1" hops="${2:-0}" d tail="" dir base phys full r intemp=0 c t
  case "$p" in
    *$'\032'*|'') _FELIX_WHERE_WHY="where it acts cannot be told"; return 1 ;;
    /*) ;;
    *) _FELIX_WHERE_WHY="where it acts cannot be told"; return 1 ;;
  esac
  d="$p"
  while [ ! -e "$d" ] && [ ! -L "$d" ]; do
    tail="/${d##*/}$tail"; d="${d%/*}"
    [ -n "$d" ] || { d=/; break; }
  done
  case "$tail" in
    */..|*/../*|*/.|*/./*)
      _FELIX_WHERE_WHY="$p climbs out of a directory that does not exist yet"; return 1 ;;
  esac
  if [ -d "$d" ]; then dir="$d"; base=""
  elif [ -L "$d" ]; then
    # A link to a file acts wherever the file is: follow it, a few hops.
    t="$(readlink "$d" 2>/dev/null)" && [ -n "$t" ] && [ "$hops" -lt 8 ] \
      || { _FELIX_WHERE_WHY="$d is a link that cannot be followed"; return 1; }
    case "$t" in /*) ;; *) t="${d%/*}/$t" ;; esac
    _felix_where_throwaway "$t$tail" $((hops + 1)); return
  else dir="${d%/*}"; [ -n "$dir" ] || dir=/; base="/${d##*/}"
  fi
  phys="$(cd -P "$dir" 2>/dev/null && pwd -P)" || { _FELIX_WHERE_WHY="$dir cannot be entered"; return 1; }
  full="${phys%/}$base$tail"; [ -n "$full" ] || full=/
  if _felix_where_under "$full" "$_FW_GTOP" \
     || { [ -n "$_FW_GCOMMON" ] && _felix_where_under "$full" "$_FW_GCOMMON"; }; then
    _FELIX_WHERE_WHY="it acts on $full, in the governed checkout"; return 1
  fi
  if _felix_where_under "$_FW_GTOP" "$full"; then
    _FELIX_WHERE_WHY="it acts on $full, which holds the governed checkout"; return 1
  fi
  c="$(_felix_where_lexical "$p")"
  if _felix_where_under "$c" "$_FW_GTOP" || _felix_where_under "$_FW_GTOP" "$c" \
     || { [ -n "$_FW_GCOMMON" ] && _felix_where_under "$c" "$_FW_GCOMMON"; }; then
    _FELIX_WHERE_WHY="it acts on $c, the governed checkout as cd spells it"; return 1
  fi
  while IFS= read -r r; do
    [ -n "$r" ] && _felix_where_under "$full" "$r" && { intemp=1; break; }
  done <<EOF
$_FW_ROOTS
EOF
  [ "$intemp" = 1 ] || { _FELIX_WHERE_WHY="it acts on $full, outside every temporary directory"; return 1; }
  c="$(_felix_where_common "$phys")"
  if [ -n "$c" ] && [ -n "$_FW_GCOMMON" ] && [ "$c" = "$_FW_GCOMMON" ]; then
    _FELIX_WHERE_WHY="it acts on $full, a worktree of the governed repository"; return 1
  fi
  return 0
}

# Whether mkdir -p of a path can succeed: it is a directory already, or the
# deepest part of it that exists is a writable directory.
_felix_where_makeable() {
  local d="$1"
  [ -d "$d" ] && return 0
  while [ ! -e "$d" ] && [ ! -L "$d" ]; do
    d="${d%/*}"; [ -n "$d" ] || d=/
  done
  [ -d "$d" ] && [ -w "$d" ]
}

# Whether every alternative in a place list is throwaway, skipping any that a
# guard rules out: one whose guard names directories that all exist now.
_felix_where_places() {
  local pl="$1" noguard="$2" alt path g item dirs dd out IFS
  local -a alts guards
  IFS=$'\036' read -r -a alts <<EOF
$pl
EOF
  for alt in ${alts[@]+"${alts[@]}"}; do
    [ -n "$alt" ] || continue
    path="${alt%%$'\035'*}"
    if [ "$noguard" = 0 ] && [ "$path" != "$alt" ]; then
      out=0
      IFS=$'\035' read -r -a guards <<EOF
${alt#*$'\035'}
EOF
      for item in ${guards[@]+"${guards[@]}"}; do
        [ -n "$item" ] || continue
        dirs=1
        IFS=$'\037' read -r -a dd <<EOF
$item
EOF
        for g in ${dd[@]+"${dd[@]}"}; do [ -d "$g" ] || { dirs=0; break; }; done
        [ "$dirs" = 1 ] && { out=1; break; }
      done
      [ "$out" = 1 ] && continue
    fi
    _felix_where_throwaway "$path" || return 1
  done
  return 0
}

# The command with the given raw byte spans blanked to spaces.
_felix_where_blank() {
  local s="$1" spans="$2" out="" pos=0 a b pad sorted
  sorted="$(printf '%s\n' $spans | sort -t, -k1,1n -u)"
  while IFS=, read -r a b; do
    [ -n "$a" ] && [ -n "$b" ] || continue
    [ "$a" -ge "$pos" ] || continue
    printf -v pad '%*s' $((b - a + 1)) ''
    out="$out${s:$pos:$((a - pos))}$pad"; pos=$((b + 1))
  done <<EOF
$sorted
EOF
  printf '%s' "$out${s:$pos}"
}

# felix_where_lifts PATTERN SUBJECT START GOVERNED
#
# Whether a Bash row scoped to the checkout lifts for this command: every
# simple command the pattern matches acts only in throwaway places, and once
# their text is blanked the pattern matches nothing left. Returns 0 to lift.
# On 1, _FELIX_WHERE_WHY says why the row stood.
felix_where_lifts() {
  local pattern="$1" subj="$2" start="$3" gdir="$4" LC_ALL=C
  local out line rest kind why text places sp matched=0 noguard=0 lifted="" rem
  _FELIX_WHERE_WHY="the command could not be read"
  [ -n "${_FELIX_WHERE_READ:-}" ] || return 1
  # The reader costs this awk about a microsecond per character per look, and
  # this runs inside a synchronous hook. Every command the replay lifted was
  # under 4.2K (median 1K); past 32K the row stands, as it did before.
  if [ "${#subj}" -gt 32768 ]; then
    _FELIX_WHERE_WHY="the command is ${#subj} bytes, longer than this reads (32768)"; return 1
  fi
  _felix_where_ident "$gdir" || { _FELIX_WHERE_WHY="the governed checkout could not be found"; return 1; }
  start="$(cd -P "$start" 2>/dev/null && pwd -P)" || start="$_FW_GTOP"
  out="$(printf '%s' "$subj" | LC_ALL=C awk -v CWD0="$start" -v HOMEV="$HOME" -v TMPV="${TMPDIR:-}" \
        -v CDP="${CDPATH:+1}" -v GITENV="${GIT_DIR:+1}${GIT_WORK_TREE:+1}" \
        "$_FELIX_WHERE_READ" 2>/dev/null)" || return 1
  case "$out" in E|*$'\n'E) ;; *) return 1 ;; esac
  while IFS= read -r line; do
    case "$line" in
      H$'\t'*) _FELIX_WHERE_WHY="${line#H	}"; return 1 ;;
      N) noguard=1 ;;
      M$'\t'*) _felix_where_makeable "${line#M	}" \
                 || { _FELIX_WHERE_WHY="mkdir -p ${line#M	} could fail, and then a cd into it would not move"; return 1; } ;;
      D$'\t'*) [ -d "${line#D	}" ] && [ -w "${line#D	}" ] \
                 || { _FELIX_WHERE_WHY="mktemp works in ${line#D	}, which is not a writable directory now"; return 1; } ;;
      X$'\t'*) [ -d "${line#X	}" ] \
                 && { _FELIX_WHERE_WHY="${line#X	} is named as a command and is a directory, which zsh's AUTO_CD would enter"; return 1; } ;;
    esac
  done <<EOF
$out
EOF
  while IFS= read -r line; do
    case "$line" in C$'\t'*) ;; *) continue ;; esac
    rest="${line#C	}"
    kind="${rest%%	*}"; rest="${rest#*	}"
    why="${rest%%	*}"; rest="${rest#*	}"
    text="${rest%%	*}"; rest="${rest#*	}"
    places="${rest%%	*}"; sp="${rest#*	}"
    if [ "$kind" = m ]; then
      _felix_where_places "$places" "$noguard" || { _FELIX_WHERE_WHY="\`${text:0:80}\` makes a path stand for another, and $_FELIX_WHERE_WHY"; return 1; }
      continue
    fi
    [[ "$text" =~ $pattern ]] || continue
    matched=1
    [ "$kind" = u ] && { _FELIX_WHERE_WHY="\`${text:0:80}\`: $why"; return 1; }
    _felix_where_places "$places" "$noguard" || { _FELIX_WHERE_WHY="\`${text:0:80}\`: $_FELIX_WHERE_WHY"; return 1; }
    [ "$sp" = - ] || lifted="$lifted $sp"
  done <<EOF
$out
EOF
  # The blanking below would refuse this too, since nothing was blanked; this
  # only says why in words a session can act on.
  [ "$matched" = 1 ] || { _FELIX_WHERE_WHY="the rule matched no one command it could read"; return 1; }
  rem="$(_felix_where_blank "$subj" "$lifted")"
  if [[ "$rem" =~ $pattern ]]; then
    _FELIX_WHERE_WHY="the rule also matched text no command it judged carries"; return 1
  fi
  _FELIX_WHERE_WHY=""
  return 0
}

# felix_where_path_lifts PATH START GOVERNED: the same, for a tool that names
# one path.
felix_where_path_lifts() {
  local p="$1" start="$2" gdir="$3" LC_ALL=C
  _FELIX_WHERE_WHY="where it acts cannot be told"
  case "$p" in *\\*) return 1 ;; esac
  _felix_where_ident "$gdir" || return 1
  case "$p" in /*) ;; *) p="$start/$p" ;; esac
  _felix_where_throwaway "$p"
}
