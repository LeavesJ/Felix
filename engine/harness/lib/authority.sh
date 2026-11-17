# The authority that holds main: its parameters, its store's identity and its standing.
#
# Trust-plane step 4, stage 1, slice 1 (docs/2026-11-13-trust-step4-shadow-slice1.md; the hosted-authority design
# of 2026-11-09 and the door design of 2026-11-10). An authority is a store it alone writes, a judgement, and a
# record. This slice builds the store, the door that takes the founder's statements (lib/door.sh), the reading of
# them (lib/door-read.sh) and the decision for a candidate up to the judge (lib/authority-tick.sh). It lands
# nothing, in either standing.
#
# SHADOW IS THE DEFAULT, AND NOTHING READS IT. The founder's decision of 2026-11-13: the authority judges and
# records, but nothing it says counts and it holds nothing until it runs as its own login, the reach test has
# passed, and he has given the first start at that login's console. Until then the standing is `shadow`, each
# line it prints for a candidate starts with that word, and each statement kept says it was given in shadow and
# never counts. No code outside this slice's five libraries reads the store, the log or the ledger to decide anything, so
# what a shadow authority says changes no merge. Under the founder's own login a worker can write every file
# here. That is why it is shadow, and no check in this file is a wall there.
#
# THE PARAMETERS (W1 to W3). One file, AH/authority.conf, one row a key: the key, a tab, the value. AH is
# $FELIX_AUTHORITY_HOME, or $HOME/.felix/authority. Moving the authority to another login is a change of these
# rows and of that variable. Nothing here takes the user, the home, the store or the door's directory from
# anywhere else. The file is read as data and never sourced.
#
# GIT (W10). felix_authority_gitenv gives each git this process runs no configuration, attributes or replacement
# from the caller, the user or the system. It changes the process's own environment, which is why only
# `felix authority` and `felix door` call it: they run nothing else afterwards.
#
# Bash 3.2. No project is named here.

FELIX_AUTH_KEYS='user workers source source-main store door lock'
FELIX_AUTH_ZERO=0000000000000000000000000000000000000000

felix_authority_home() { printf '%s' "${FELIX_AUTHORITY_HOME:-$HOME/.felix/authority}"; }

_fa_sha() { local LC_ALL=C; case "${1:-}" in ""|*[!0123456789abcdef]*) return 1 ;; esac; [ "${#1}" -eq 40 ]; }
_fa_login() { local LC_ALL=C; case "${1:-}" in ""|[!A-Za-z_]*|*[!A-Za-z0-9_.-]*) return 1 ;; esac; return 0; }
_fa_abs() { case "${1:-}" in /*) return 0 ;; esac; return 1; }
# Each git of the authority's. core.attributesFile is named because GIT_CONFIG_GLOBAL does not turn off the
# user's attributes file ($XDG_CONFIG_HOME/git/attributes), and with `* merge=union` there a head that
# conflicts merged clean (review F3). The store's own info/attributes is refused by felix_authority_open.
_fa_g() { git -c core.attributesFile=/dev/null --git-dir="$_FA_STORE" "$@"; }

# W2. The rows of a configuration, from its text on stdin. Sets the _FA_* variables and returns 0, or returns 1
# with _FA_WHY. A value is printable ASCII, so a second tab in a row makes the file unreadable.
_fa_parse() {   # HOME <- text
  local line k v seen=" " w rest LC_ALL=C
  _FA_HOME="$1"; _FA_WHY=""
  _FA_USER=""; _FA_WORKERS=""; _FA_SOURCE=""; _FA_SRCMAIN="refs/heads/main"
  _FA_STORE="$_FA_HOME/store.git"; _FA_DOOR="$_FA_HOME/door"; _FA_LOCK=""
  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in ""|"#"*) continue ;; esac
    case "$line" in *$'\t'*) ;; *) _FA_WHY="authority.conf holds a row with no tab"; return 1 ;; esac
    k="${line%%$'\t'*}"; v="${line#*$'\t'}"
    # A key is one of the list's, whole: "store door lock" is in the list as a run of words and is no key.
    case "$k" in *" "*) _FA_WHY="authority.conf holds a key this engine does not know"; return 1 ;; esac
    case " $FELIX_AUTH_KEYS " in *" $k "*) ;; *) _FA_WHY="authority.conf holds a key this engine does not know"; return 1 ;; esac
    case "$seen" in *" $k "*) _FA_WHY="authority.conf holds the key $k twice"; return 1 ;; esac
    seen="$seen$k "
    case "$v" in ""|*[!\ -~]*) _FA_WHY="authority.conf gives $k no value, or one with a byte outside printable ASCII"; return 1 ;; esac
    case "$k" in
      user)    _fa_login "$v" || { _FA_WHY="authority.conf names a user that is not a login name"; return 1; }; _FA_USER="$v" ;;
      workers) case "$v" in *[!A-Za-z0-9_.,-]*|,*|*,|*,,*) _FA_WHY="authority.conf names a worker that is not a login name"; return 1 ;; esac
               rest="$v,"
               while [ -n "$rest" ]; do
                 w="${rest%%,*}"; rest="${rest#*,}"
                 _fa_login "$w" || { _FA_WHY="authority.conf names a worker that is not a login name"; return 1; }
               done
               _FA_WORKERS="$v" ;;
      # A source is an absolute path or a URL of a transport named here. It is never read as an option of git
      # (a value that starts with a dash) or as a transport that runs a program of the value's choosing.
      source)  case "$v" in
                 /*|file://?*|https://?*|ssh://?*) ;;
                 *) _FA_WHY="authority.conf names a source that is not an absolute path or a file, https or ssh URL"; return 1 ;;
               esac
               _FA_SOURCE="$v" ;;
      source-main)
               case "$v" in refs/*) ;; *) _FA_WHY="authority.conf names a source-main that is not a ref"; return 1 ;; esac
               git check-ref-format "$v" 2>/dev/null || { _FA_WHY="authority.conf names a source-main that is not a ref"; return 1; }
               _FA_SRCMAIN="$v" ;;
      store)   _fa_abs "$v" || { _FA_WHY="authority.conf names a store that is not an absolute path"; return 1; }; _FA_STORE="$v" ;;
      door)    _fa_abs "$v" || { _FA_WHY="authority.conf names a door that is not an absolute path"; return 1; }; _FA_DOOR="$v" ;;
      lock)    _fa_abs "$v" || { _FA_WHY="authority.conf names a lock that is not an absolute path"; return 1; }; _FA_LOCK="$v" ;;
    esac
  done
  [ -n "$_FA_USER" ] || { _FA_WHY="authority.conf names no user"; return 1; }
  [ -n "$_FA_WORKERS" ] || { _FA_WHY="authority.conf names no workers"; return 1; }
  [ -n "$_FA_SOURCE" ] || { _FA_WHY="authority.conf names no source"; return 1; }
  return 0
}

# The parameters of the authority set up at AH. Returns 1 with _FA_WHY when there is none or its file is unreadable.
felix_authority_load() {
  local home f
  home="$(felix_authority_home)"; f="$home/authority.conf"; _FA_WHY=""
  _fa_abs "$home" || { _FA_WHY="the authority's home, $home, is not an absolute path"; return 1; }
  [ -f "$f" ] && [ ! -L "$f" ] || { _FA_WHY="no authority is set up at $home (felix authority init makes one)"; return 1; }
  _fa_parse "$home" < "$f" || return 1
  [ -d "$_FA_STORE" ] && [ ! -L "$_FA_STORE" ] || { _FA_WHY="the store, $_FA_STORE, is not a directory"; return 1; }
  return 0
}

# W10. Nothing of the caller's, the user's or the system's reaches a git this process runs from here on. Each
# variable whose name starts with GIT_ is removed, and not a list of the ones known today: a list is the ones
# found so far, and git reads a new one with each release. Then the few this code means are set.
felix_authority_gitenv() {
  local v
  for v in ${!GIT_@}; do unset "$v" 2>/dev/null; done
  # And nothing of the caller's stands in for what this code has read: with _FP_AT and its companions
  # exported, the policy read as already read, with no rows (review F4). Each variable these libraries keep
  # state in starts with one of these prefixes, and each is removed before the first read.
  for v in ${!_FA_@} ${!_FP_@} ${!_FD@} ${!_DL_@} ${!_FW_@}; do unset "$v" 2>/dev/null; done
  export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 GIT_ATTR_NOSYSTEM=1 GIT_NO_REPLACE_OBJECTS=1 \
         GIT_TERMINAL_PROMPT=0 LC_ALL=C LANGUAGE=C \
         GIT_AUTHOR_NAME=felix-authority GIT_AUTHOR_EMAIL=authority@felix.invalid \
         GIT_COMMITTER_NAME=felix-authority GIT_COMMITTER_EMAIL=authority@felix.invalid
  umask 077
}

# W5. The store's identity: the id of a blob made once, at init, from the system's random source.
felix_authority_id() {   # [STORE] -> 40 hex, or 1
  local id
  id="$(git --git-dir="${1:-$_FA_STORE}" rev-parse --verify --quiet refs/felix/identity 2>/dev/null)" || return 1
  _fa_sha "$id" || return 1
  [ "$(git --git-dir="${1:-$_FA_STORE}" cat-file -t "$id" 2>/dev/null)" = blob ] || return 1
  printf '%s' "$id"
}

# W4. Returns 0 with the id in _FA_ID, or 1 with _FA_WHY. Each refusal comes before the first write.
felix_authority_init() {   # USER WORKERS SOURCE SRCMAIN STORE DOOR LOCK (each "" for its default)
  local home text me w rest nonce id f
  home="$(felix_authority_home)"; f="$home/authority.conf"; _FA_WHY=""
  _fa_abs "$home" || { _FA_WHY="the authority's home, $home, is not an absolute path"; return 1; }
  [ ! -e "$f" ] && [ ! -L "$f" ] || { _FA_WHY="an authority is already set up at $home"; return 1; }
  # A value is one row: a newline inside an argument would write a second one (review F13).
  for w in "$@"; do
    case "$w" in *[!\ -~]*) _FA_WHY="an argument holds a byte outside printable ASCII"; return 1 ;; esac
  done
  text="$(printf 'user\t%s\nworkers\t%s\nsource\t%s\n' "$1" "$2" "$3"
          [ -z "$4" ] || printf 'source-main\t%s\n' "$4"
          [ -z "$5" ] || printf 'store\t%s\n' "$5"
          [ -z "$6" ] || printf 'door\t%s\n' "$6"
          [ -z "$7" ] || printf 'lock\t%s\n' "$7")"
  _fa_parse "$home" <<EOF || return 1
$text
EOF
  me="$(id -un 2>/dev/null)"
  [ "$_FA_USER" = "$me" ] || { _FA_WHY="this login is $me, not $_FA_USER: an authority is set up by the login it runs as"; return 1; }
  rest="$_FA_WORKERS,"
  while [ -n "$rest" ]; do
    w="${rest%%,*}"; rest="${rest#*,}"
    id -u "$w" >/dev/null 2>&1 || { _FA_WHY="$w is not a login of this machine"; return 1; }
  done
  if [ -e "$_FA_STORE" ] || [ -L "$_FA_STORE" ]; then
    [ -d "$_FA_STORE" ] && [ ! -L "$_FA_STORE" ] && [ -z "$(ls -A "$_FA_STORE" 2>/dev/null)" ] \
      || { _FA_WHY="the store's path, $_FA_STORE, exists and is not an empty directory"; return 1; }
  fi
  mkdir -p "$home" "$_FA_DOOR" && chmod 700 "$home" "$_FA_DOOR" || { _FA_WHY="$home could not be made"; return 1; }
  git init -q --bare --template= "$_FA_STORE" >/dev/null 2>&1 && chmod 700 "$_FA_STORE" \
    && _fa_g symbolic-ref HEAD refs/heads/main || { _FA_WHY="the store could not be made at $_FA_STORE"; return 1; }
  # The store takes no push. Under another login the file system says so; this hook says so to a push by mistake
  # from the same login, which the file system would take.
  mkdir -p "$_FA_STORE/hooks" \
    && printf '#!/bin/sh\necho "this store takes no push: the authority alone writes it" >&2\nexit 1\n' > "$_FA_STORE/hooks/pre-receive" \
    && chmod 700 "$_FA_STORE/hooks/pre-receive" || { _FA_WHY="the store could not be closed to pushes"; return 1; }
  nonce="$(od -An -N16 -tx1 /dev/urandom 2>/dev/null | tr -d ' \n')"
  [ "${#nonce}" -eq 32 ] || { _FA_WHY="the system's random source could not be read"; return 1; }
  id="$(printf 'felix-authority/v1\nnonce: %s\n' "$nonce" | _fa_g hash-object -w --stdin 2>/dev/null)" \
    && _fa_g update-ref refs/felix/identity "$id" "$FELIX_AUTH_ZERO" 2>/dev/null \
    || { _FA_WHY="the store's identity could not be written"; return 1; }
  printf '%s\n' "$text" > "$f.new.$$" && mv "$f.new.$$" "$f" || { _FA_WHY="$f could not be written"; return 1; }
  _FA_ID="$id"
}

# W6 e. Prints each path of the code this process runs that a login workers run as owns or can write: every
# path under the engine's root (FELIX_ROOT, the directory above the one felix is in) at every depth, the root
# with them (C1 of the setup slice, 0.49.351: the lock program and the witness the launchers run are under
# it, and so is every file felix sources); each directory PATH names and each program in one; the directory
# `git --exec-path` prints for the git first on PATH, read as a PATH directory is (C2: on this Mac /usr/bin/git
# runs Xcode's git, whose programs sit under /Applications, which the admin group writes); the lock with its
# directory; and each directory above any of these (C3, _fa_above), one of them that is not there yet with them. Directories, and not a list of the tools'
# names: a list is the tools found so far, and the first one written here named twenty and left out one the
# door runs. A link is read as itself and as what it points at. "Can write" is: owns it, or it is writable by
# every login, or by a group a worker is in, or it carries an access-control entry that allows. A path a third
# login owns (a system's role account) is not a worker's. Each path is printed with no trailing slash. NOT
# READ: the libraries a program loads, what a link in a PATH directory points into beyond its own directories
# above, and a login not named in workers; the setup slice's section 8 lists them.
_fa_code_offenders() {
  { _fa_code_offenders_raw; } | LC_ALL=C awk '
    substr($0, 1, 1) == "/" { s = $0; t = ""; i = index(s, " ("); if (i) { t = substr(s, i); s = substr(s, 1, i - 1) }
      while (length(s) > 1 && substr(s, length(s)) == "/") s = substr(s, 1, length(s) - 1)
      $0 = s t }
    { print }'
}
# C3. Prints each directory above DIR up to /, along DIR as written and along its physical path (cd -P), one a
# line. A path with a newline in it is read as two, and the directories above the real one are then not read.
_fa_above() {   # DIR
  local p q
  for p in "$1" "$(cd -P -- "$1" 2>/dev/null && pwd -P)"; do
    case "$p" in /*) ;; *) continue ;; esac
    while :; do
      case "$p" in /) break ;; */) p="${p%/}"; continue ;; esac
      q="${p%/*}"; [ -n "$q" ] || q=/
      printf '%s\n' "$q"; p="$q"
    done
  done
}
# C3. Adds each line of LINES, a directory above the code, to the caller's ups (or upl, for a link) once.
_fa_up_add() {   # LINES
  local y
  while IFS= read -r y; do
    [ -n "$y" ] || continue
    case "$seen" in *$'\n'"$y"$'\n'*) continue ;; esac
    seen="$seen$y"$'\n'
    if [ -L "$y" ]; then upl[${#upl[@]}]="$y"; else ups[${#ups[@]}]="$y"; fi
  done <<EOF
$1
EOF
}
_fa_code_offenders_raw() {
  local d w rest g u x p q e="${SCRIPT_DIR:-/nonexistent}" r ifs="$IFS" seen=$'\n'
  local -a a=() dirs=() grp=() own=() ups=() upl=() wr=() m=() mq=()
  r="${FELIX_ROOT:-${e%/*}}"; [ -n "$r" ] || r=/
  if [ -n "$_FA_LOCK" ]; then
    a[${#a[@]}]="$_FA_LOCK"; a[${#a[@]}]="${_FA_LOCK%/*}/"
    [ -e "${_FA_LOCK%/*}/" ] || m[${#m[@]}]="${_FA_LOCK%/*}"
    # rev 3 (security review): a lock that is a link runs whatever is at the end of it, in a directory not read
    # here, or made later where a link to nothing points. The lock authority-engine writes is a file.
    [ ! -L "$_FA_LOCK" ] || printf '%s\n' "$_FA_LOCK (a lock that is a link: it runs wherever the link points)"
  fi
  case ":${PATH:-}:" in *::*) printf '%s\n' "PATH (an empty entry: the directory the command is run from)" ;; esac
  IFS=:
  for d in ${PATH:-}; do
    case "$d" in
      "") ;;
      /*) if [ -d "$d" ]; then dirs[${#dirs[@]}]="$d/"; a[${#a[@]}]="$d/"; else m[${#m[@]}]="$d"; fi ;;
      *)  printf '%s\n' "PATH (an entry that is not absolute: $d)" ;;
    esac
  done
  IFS="$ifs"
  # C2. The git that runs is the first on PATH, so it is asked, with --exec-path its first word. Printing nothing,
  # failing, or naming no directory adds nothing: a git that cannot run runs nothing from there.
  x="$(git --exec-path 2>/dev/null)" || x=""
  case "$x" in /*) if [ -d "$x" ]; then dirs[${#dirs[@]}]="$x/"; a[${#a[@]}]="$x/"; else m[${#m[@]}]="$x"; fi ;; esac
  # C3, for a directory that is not there yet (review C3-missing-path): a login that can write the deepest one
  # above it that is there can make it, and put a program in it, sticky bit or not, since no one owns that name
  # yet. Each directory above it is read as for one that is there, and that deepest one, along the path as
  # written and along its physical path, offends when a worker owns it or can write it. Not there is not a
  # directory (rev 3, security review): a file or a link to one can be swapped for a directory by a login that
  # can write where it sits. A link met on the way up that leads to no directory offends itself: what it will
  # lead to is wherever its target is made, which the path as written does not show.
  for p in ${m[@]+"${m[@]}"}; do
    q="$p"
    while :; do
      case "$q" in /) break ;; */) q="${q%/}"; continue ;; esac
      [ ! -d "$q" ] || break
      [ ! -L "$q" ] || printf '%s\n' "$q (a link on the way to the code that leads to no directory)"
      q="${q%/*}"; [ -n "$q" ] || q=/
    done
    x="$(cd -P -- "$q" 2>/dev/null && pwd -P)" || x=""
    [ -L "$q" ] || mq[${#mq[@]}]="$q"
    case "$x" in /*) mq[${#mq[@]}]="$x" ;; esac
  done
  rest="$_FA_WORKERS,"
  while [ -n "$rest" ]; do
    w="${rest%%,*}"; rest="${rest#*,}"
    u="$(id -u "$w" 2>/dev/null)" || continue
    case "$u" in ""|*[!0123456789]*) continue ;; esac
    [ ${#own[@]} -eq 0 ] || own[${#own[@]}]="-o"
    own[${#own[@]}]="-user"; own[${#own[@]}]="$u"
    for g in $(id -G "$w" 2>/dev/null); do
      case "$g" in ""|*[!0123456789]*) continue ;; esac
      [ ${#grp[@]} -eq 0 ] || grp[${#grp[@]}]="-o"
      grp[${#grp[@]}]="-group"; grp[${#grp[@]}]="$g"
    done
  done
  [ ${#own[@]} -gt 0 ] || { own=(-user "$_FA_USER" -a ! -user "$_FA_USER"); }   # no worker is a login here: nothing is a worker's
  [ ${#grp[@]} -gt 0 ] || { grp=(-group 0 -a ! -group 0); }
  wr=(\( "${own[@]}" \) -o -perm -002 -o \( -perm -020 \( "${grp[@]}" \) \))
  # C1. The root and every path under it, each read as itself and, through -L, as what a link in it points at.
  find "$r" \( "${own[@]}" \) -print 2>/dev/null
  find -L "$r" \( "${wr[@]}" \) -print 2>/dev/null
  if [ ${#a[@]} -gt 0 ]; then
    find "${a[@]}" -prune \( "${own[@]}" \) -print 2>/dev/null
    find -L "${a[@]}" -prune \( "${wr[@]}" \) -print 2>/dev/null
  fi
  if [ ${#dirs[@]} -gt 0 ]; then
    find "${dirs[@]}" -mindepth 1 -maxdepth 1 -type l \( "${own[@]}" \) -print 2>/dev/null
    find -L "${dirs[@]}" -mindepth 1 -maxdepth 1 ! -type d \( "${wr[@]}" \) -print 2>/dev/null
  fi
  # C3. The directories above the root and above each directory read here. A link among them is read for its
  # owner alone: its own mode says nothing (777 on Linux), and what it points at is on the physical path, read
  # too. Writable by every login or by a worker's group offends only without the sticky bit, which keeps a
  # login that can write the directory from renaming or removing what another login owns in it.
  # A directory not there (m) is read for the directories above it as written; the deepest one there (mq) is
  # read as itself too, and along its physical path.
  for p in "$r" ${a[@]+"${a[@]}"}; do [ ! -d "$p" ] || _fa_up_add "$(_fa_above "$p")"; done
  for p in ${m[@]+"${m[@]}"}; do _fa_up_add "$(_fa_above "$p")"; done
  for p in ${mq[@]+"${mq[@]}"}; do _fa_up_add "$p"$'\n'"$(_fa_above "$p")"; done
  { [ ${#upl[@]} -eq 0 ] || find "${upl[@]}" -prune \( "${own[@]}" \) -print 2>/dev/null
    [ ${#mq[@]} -eq 0 ] || find "${mq[@]}" -prune \( -perm -002 -o \( -perm -020 \( "${grp[@]}" \) \) \) -print 2>/dev/null
    if [ ${#ups[@]} -gt 0 ]; then
      find "${ups[@]}" -prune \( \( "${own[@]}" \) -o \( ! -perm -1000 \( -perm -002 -o \( -perm -020 \( "${grp[@]}" \) \) \) \) \) -print 2>/dev/null
      if ls -lde / >/dev/null 2>&1; then
        ls -lde "${ups[@]}" 2>/dev/null | LC_ALL=C awk '
          /^ [0-9]+: / { if ($0 !~ / deny / && last != "") { print last; last = "" } next }
          { last = $0; sub(/^([^ ]+ +)([^ ]+ +)([^ ]+ +)([^ ]+ +)([^ ]+ +)([^ ]+ +)([^ ]+ +)([^ ]+ +)/, "", last) }'
      else
        ls -ld "${ups[@]}" 2>/dev/null | LC_ALL=C awk 'substr($1, 11, 1) == "+" { sub(/^([^ ]+ +)([^ ]+ +)([^ ]+ +)([^ ]+ +)([^ ]+ +)([^ ]+ +)([^ ]+ +)([^ ]+ +)/, ""); print }'
      fi
    fi
  } | LC_ALL=C awk '$0 != "" { print $0 " (a directory above the code)" }'
  # An access-control entry that is not a deny can let a login write what the owner and the mode say it
  # cannot, so the same paths are read for one. Whose entry it is is not read: any that allows is named.
  if ls -lLde "$r" >/dev/null 2>&1; then
    { find -L "$r" -exec ls -lLde {} + 2>/dev/null
      [ ${#a[@]} -eq 0 ] || ls -lLde "${a[@]}" 2>/dev/null
      [ ${#dirs[@]} -eq 0 ] || find -L "${dirs[@]}" -mindepth 1 -maxdepth 1 ! -type d -exec ls -lLde {} + 2>/dev/null
    } | LC_ALL=C awk '
      /^ [0-9]+: / { if ($0 !~ / deny / && last != "") { print last " (an access-control entry that allows)"; last = "" } next }
      { last = $0; sub(/^([^ ]+ +)([^ ]+ +)([^ ]+ +)([^ ]+ +)([^ ]+ +)([^ ]+ +)([^ ]+ +)([^ ]+ +)/, "", last) }'
  else
    { find -L "$r" -exec ls -lLd {} + 2>/dev/null
      [ ${#a[@]} -eq 0 ] || ls -lLd "${a[@]}" 2>/dev/null
      [ ${#dirs[@]} -eq 0 ] || find -L "${dirs[@]}" -mindepth 1 -maxdepth 1 ! -type d -exec ls -lLd {} + 2>/dev/null
    } | LC_ALL=C awk 'substr($1, 11, 1) == "+" { sub(/^([^ ]+ +)([^ ]+ +)([^ ]+ +)([^ ]+ +)([^ ]+ +)([^ ]+ +)([^ ]+ +)([^ ]+ +)/, ""); print $0 " (an access-control list)" }'
  fi
  return 0
}

# W6 b. Prints the first path under DIR that carries an access-control list. The entries themselves are read
# where ls prints them (`ls -lde`, a line that starts with a space, a number and a colon): the mark after the
# mode is "@" and not "+" on a path that also has extended attributes, so the mark alone missed them. Where ls
# takes no -e, the mark is "+" and nothing stands in its place.
_fa_acl() {   # DIR
  if ls -lde "$1" >/dev/null 2>&1; then
    find "$1" -exec ls -lde {} + 2>/dev/null | LC_ALL=C awk '
      /^ [0-9]+: / { if (last != "") { print last; exit } next }
      { last = $0 }' | LC_ALL=C sed -n 1p
  else
    find "$1" -exec ls -ld {} + 2>/dev/null | LC_ALL=C awk 'substr($1, 11, 1) == "+" { print; exit }' | LC_ALL=C sed -n 1p
  fi
}

# W6 a, b and e. Sets _FA_OWN to one line for each condition that does not hold, and returns 0 when each
# holds. Read once a process, and again when asked: the door asks again when it keeps a statement.
felix_authority_own() {   # [again]
  local me rest w p bad n LC_ALL=C
  if [ -n "${_FA_OWN_READ:-}" ] && [ "${1:-}" != again ]; then [ -z "$_FA_OWN" ]; return; fi
  _FA_OWN=""
  me="$(id -un 2>/dev/null)"
  [ "$me" = "$_FA_USER" ] \
    || _FA_OWN="not its own login: this process runs as ${me:-?}, and the authority's user is $_FA_USER"
  rest="$_FA_WORKERS,"
  while [ -n "$rest" ]; do
    w="${rest%%,*}"; rest="${rest#*,}"
    [ "$w" != "$_FA_USER" ] || _FA_OWN="${_FA_OWN:+$_FA_OWN$'\n'}not its own login: $_FA_USER is also a login workers run as"
    # Root writes every file, so nothing is the authority's alone from a worker that is root.
    [ "$(id -u "$w" 2>/dev/null)" != 0 ] || _FA_OWN="${_FA_OWN:+$_FA_OWN$'\n'}not its own login: $w is a login workers run as, and it writes every file"
  done
  # b. Each file and directory under the three, and not their modes alone: with the store at 755 and its
  # refs/felix at 777, anyone could replace the log's ref (review F7).
  for p in "$_FA_HOME" "$_FA_STORE" "$_FA_DOOR"; do
    case "$p" in "$_FA_HOME"/*) [ ! -d "$p" ] || [ -L "$p" ] || continue ;; esac   # read with the home
    bad=""
    if [ ! -d "$p" ] || [ -L "$p" ]; then bad="$p"
    else
      bad="$(find "$p" \( ! -user "$_FA_USER" -o \( ! -type l \( -perm -020 -o -perm -002 \) \) \) -print 2>/dev/null | sed -n 1p)"
      [ -n "$bad" ] || [ -n "$(find "$p" -prune -user "$_FA_USER" 2>/dev/null)" ] || bad="$p"
    fi
    [ -z "$bad" ] || _FA_OWN="${_FA_OWN:+$_FA_OWN$'\n'}not the authority's alone: $(_fa_esc "$bad" 200) is not owned by $_FA_USER, or someone else can write it"
  done
  for p in "$_FA_HOME" "$_FA_STORE" "$_FA_DOOR"; do
    case "$p" in "$_FA_HOME"/*) [ ! -d "$p" ] || [ -L "$p" ] || continue ;; esac   # read with the home
    [ -d "$p" ] && [ ! -L "$p" ] || continue
    [ -z "$(_fa_acl "$p")" ] \
      || _FA_OWN="${_FA_OWN:+$_FA_OWN$'\n'}not the authority's alone: a path under $(_fa_esc "$p" 200) carries an access-control list"
  done
  # e. The code it runs. FIRST is printed as the setup slice's section 0 says (_fa_show): as it is when it is
  # printable ASCII with no backslash or double quote, escaped and quoted otherwise.
  bad="$(_fa_code_offenders | LC_ALL=C sort -u)"
  if [ -n "$bad" ]; then
    n="$(printf '%s\n' "$bad" | wc -l | tr -d ' ')"
    _FA_OWN="${_FA_OWN:+$_FA_OWN$'\n'}not the authority's alone: it runs $(_fa_show "${bad%%$'\n'*}" 200), which a login workers run as owns or can write ($n such)"
  fi
  _FA_OWN_READ=1
  [ -z "$_FA_OWN" ]
}

# W8. How a statement given now is given: shadow, console or desktop. The console is this machine with no
# process whose real or effective user is a login workers run as: after a restart, before the founder logs in
# as himself. Every process is listed once, with both users. A list that fails, or that lacks process 1 or
# this process, is not the whole list (a system that hides other logins' processes), and the answer is then
# desktop, the one that asks for more. Asking ps for one user's processes read an error as "none": on this
# Mac `ps -U` refused the uid of `nobody` and printed nothing (review F6).
felix_authority_given() {   # [again]
  local rest w uid list
  felix_authority_own "${1:-}" || { printf 'shadow'; return 0; }
  list="$(ps -A -o pid= -o ruid= -o uid= 2>/dev/null)" || { printf 'desktop'; return 0; }
  printf '%s\n' "$list" | LC_ALL=C awk -v me="$$" '($1 "") == "1" { a = 1 } ($1 "") == (me "") { b = 1 } END { exit !(a && b) }' \
    || { printf 'desktop'; return 0; }
  rest="$_FA_WORKERS,"
  while [ -n "$rest" ]; do
    w="${rest%%,*}"; rest="${rest#*,}"
    uid="$(id -u "$w" 2>/dev/null)" || { printf 'desktop'; return 0; }
    case "$uid" in ""|*[!0123456789]*) printf 'desktop'; return 0 ;; esac
    # A uid above 2^31 is printed by some systems as a negative number: both spellings are looked for.
    if printf '%s\n' "$list" | LC_ALL=C awk -v u="$uid" '
         BEGIN { alt = (u + 0 > 2147483647) ? sprintf("%d", u - 4294967296) : u }
         ($2 "") == (u "") || ($3 "") == (u "") || ($2 "") == (alt "") || ($3 "") == (alt "") { f = 1 }
         END { exit !f }'; then printf 'desktop'; return 0; fi
  done
  printf 'console'
}

# W6. Sets _FA_STANDING (live or shadow) and _FA_WHYS (one line a reason). The log is read first by the caller
# (felix_door_log_read); a log that does not read back is one more reason.
felix_authority_standing() {
  _FA_STANDING=live; _FA_WHYS=""
  felix_authority_own || { _FA_STANDING=shadow; _FA_WHYS="$_FA_OWN"; }
  if [ -n "${_DL_BAD:-}" ]; then
    _FA_STANDING=shadow; _FA_WHYS="${_FA_WHYS:+$_FA_WHYS$'\n'}the door's log does not read back: statement $_DL_BAD"
    return 0
  fi
  if [ "${_DL_N:-0}" -eq 0 ] || [ "${_DL_VERB[0]}" != start ] || [ "${_DL_GIVEN[0]}" != console ]; then
    _FA_STANDING=shadow; _FA_WHYS="${_FA_WHYS:+$_FA_WHYS$'\n'}no first start at the console"
  fi
  if [ "${_DL_REACH:-0}" -ne 1 ]; then
    _FA_STANDING=shadow; _FA_WHYS="${_FA_WHYS:+$_FA_WHYS$'\n'}the reach test has not passed"
  fi
  return 0
}

# `felix authority status`. The caller has loaded the parameters and read the log.
felix_authority_status() {
  local id main why word
  id="$(felix_authority_id)" || id="-"
  felix_authority_standing
  printf 'authority: %s\nstanding: %s\n' "$id" "$_FA_STANDING"
  while IFS= read -r why; do [ -z "$why" ] || printf 'why: %s\n' "$why"; done <<EOF
$_FA_WHYS
EOF
  main="$(_fa_g rev-parse --verify --quiet refs/heads/main 2>/dev/null)" || main="-"
  word=go; [ -z "$(felix_word_stop)" ] || word=stop
  printf 'user: %s\nworkers: %s\nhome: %s\nstore: %s\ndoor: %s\nsource: %s\nsource-main: %s\nlock: %s\nmain: %s\nstatements: %s\nword: %s\n' \
    "$_FA_USER" "$_FA_WORKERS" "$_FA_HOME" "$_FA_STORE" "$_FA_DOOR" "$_FA_SOURCE" "$_FA_SRCMAIN" "${_FA_LOCK:--}" \
    "$main" "${_DL_N:-0}" "$word"
}
