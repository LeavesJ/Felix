# felix inventory's orphans: directories a repository's checkouts left behind
# that git no longer lists, for lib/inventory.sh, and which of its directories
# sit in a temporary directory. Read-only as the rest is: every git call is
# _fi_git, and find and git only list and hash.
#
# An orphan is a directory beside the worktrees whose .git file names a
# gitdir inside this repository's; or, in a directory inside the main
# worktree, a gitdir that no longer exists at all, or no .git and nothing
# tracked. Elsewhere that is no evidence: beside a checkout sit other
# projects, and a temp directory every process's scratch. Where to look is
# every directory holding a linked worktree git lists, and, since pruning
# every one of them leaves nothing listed, every directory inside the main
# worktree, untracked or ignored, whose tree holds within three levels a .git
# file naming a gitdir inside this repository's, or one gone. A directory
# holding only other repositories' checkouts is never one to look in.
#
# What an orphan holds is read as a checkout of the repository would be:
# with its own ignore files, or, lacking one at its top, the main worktree's,
# so a plain directory does not count a build tree the repository ignores.
# Ignored files are counted apart, and read up to 1 MiB each and 2000 in
# all, since an ignored directory can hold gigabytes and a file there can
# still be the only copy of something (a local settings file, a notes file
# under an ignored .claude/); what was passed over is said, so no count of
# 0 stands for files nobody read.

# The orphans into $T/orph ("path detail", - for none), the directories
# inside the main worktree that hold them into $T/scope, and, for the main
# worktree's status, the paths of its linked worktrees and orphans inside it,
# relative, into $T/nest.
_fi_orphan_find() {
  local p o g x in reg
  : > "$T/orph"; : > "$T/scope"; : > "$T/nest"
  reg="$_FI_NL$(cut -f1 "$T/wt")$_FI_NL"
  { awk -F'\t' 'NR > 1 && $4 !~ /linebreak/ { p = $1; sub(/\/[^\/]*$/, "", p); if (p != "") print p }' "$T/wt"; _fi_orphan_parents; } \
    | LC_ALL=C sort -u > "$T/parents"
  while IFS= read -r p <&3; do
    in=0; [ -n "$_FI_MAIN" ] && case "$p/" in "$_FI_MAIN"/?*/) in=1; printf '%s/\n' "$p" >> "$T/scope" ;; esac
    for o in "$p"/*/; do
      o="${o%/}"; [ -d "$o" ] || continue
      case "$reg" in *"$_FI_NL$o$_FI_NL"*) continue ;; esac
      [ -d "$o/.git" ] || { [ -f "$o/HEAD" ] && [ -d "$o/objects" ]; } && continue
      if [ -f "$o/.git" ]; then
        g="$(_fi_gitdir "$o")" || continue
        # Ours, or gone with its whole repository (one since moved) from a
        # directory inside our main worktree; a live one elsewhere is another's.
        case "$g" in "$_FI_COMMON"/*) ;; *) [ "$in" = 1 ] && [ ! -e "$g" ] || continue ;; esac
        x="its .git names $g, which git here does not list"
      elif [ "$in" = 0 ] || [ -n "$(_fi_git -C "$_FI_MAIN" ls-files -- "${o#"$_FI_MAIN"/}" 2>/dev/null | head -1)" ]; then continue
      else x=-; fi
      printf '%s\t%s\n' "$o" "$x" >> "$T/orph"
    done
  done 3< "$T/parents"
  [ -n "$_FI_MAIN" ] || return 0
  { tail -n +2 "$T/wt" | cut -f1; cut -f1 "$T/orph"; } | while IFS= read -r o; do
    case "$o" in "$_FI_MAIN"/?*) printf '%s\n' "${o#"$_FI_MAIN"/}" ;; esac
  done > "$T/nest"
}
# The gitdir a directory's .git file names, absolute, resolved as far as it exists.
# Both callers test `-f` first, and it is tested here again, so a pipe put at
# .git between their test and this read is never opened (2026-10-08): the
# readers lint judges an open by its own function.
_fi_gitdir() {
  local g x
  [ -f "$1/.git" ] || return 1
  g="$(sed -n 's/^gitdir: //p' "$1/.git" 2>/dev/null | head -1)"
  case "$g" in /*) ;; ?*) g="$1/$g" ;; *) return 1 ;; esac
  x="$(cd "${g%/*}" 2>/dev/null && pwd -P)" && g="$x/${g##*/}"
  printf '%s' "$g"
}
# Directories inside the main worktree that hold what a pruned worktree left.
_fi_orphan_parents() {
  local e m g
  [ -n "$_FI_MAIN" ] || return 0
  { _fi_git -C "$_FI_MAIN" ls-files -z --others --directory --exclude-standard
    _fi_git -C "$_FI_MAIN" ls-files -z --others --ignored --directory --exclude-standard; } 2>/dev/null | tr '\000' '\n' | grep '/$' > "$T/mo"
  while IFS= read -r e <&3; do
    find "$_FI_MAIN/${e%/}" -maxdepth 3 -name .git -type f -print 2>/dev/null
  done 3< "$T/mo" | while IFS= read -r m; do
    m="${m%/.git}"; g="$(_fi_gitdir "$m")" || continue
    case "$g" in "$_FI_COMMON"/*) ;; *) [ -e "$g" ] && continue ;; esac
    printf '%s\n' "${m%/*}"
  done
}

# The temporary directories: $TMPDIR as set and as it resolves, /tmp,
# /private/tmp and /private/var/folders (a Mac's per-user temp), into _FI_TMPS.
# FELIX_INVENTORY_TEMP_ROOTS, when set, replaces that list: its directories,
# colon-separated, each as given and as it resolves. It exists for tests,
# whose fixtures all lie in a temporary directory, so the path every real
# checkout takes, listed in its needs-action group, can be driven too.
_fi_tmps() {
  local r rest
  _FI_TMPS=()
  if [ -z "${FELIX_INVENTORY_TEMP_ROOTS+set}" ]; then
    _FI_TMPS=(/tmp /private/tmp /private/var/folders); _fi_tmp_add "${TMPDIR:-}"; return 0
  fi
  rest="$FELIX_INVENTORY_TEMP_ROOTS"
  while [ -n "$rest" ]; do
    r="${rest%%:*}"; case "$rest" in *:*) rest="${rest#*:}" ;; *) rest="" ;; esac
    _fi_tmp_add "$r"
  done
  return 0
}
# One directory into _FI_TMPS, its trailing slashes off, as given and as it
# resolves; nothing for an empty one or /.
_fi_tmp_add() {
  local t="$1" p
  while [ "${t%/}" != "$t" ]; do t="${t%/}"; done
  [ -n "$t" ] || return 0
  _FI_TMPS[${#_FI_TMPS[@]}]="$t"; p="$(cd "$t" 2>/dev/null && pwd -P)" && [ -n "$p" ] && _FI_TMPS[${#_FI_TMPS[@]}]="$p"
  return 0
}
_fi_temp() { local t; for t in ${_FI_TMPS[@]+"${_FI_TMPS[@]}"}; do case "$1/" in "$t"/*) return 0 ;; esac; done; return 1; }

_fi_orphan_rows() {
  local o x when
  while IFS="$_FI_TAB" read -r o x <&3; do
    _fi_uniq "$o"; _FI_DET="$_FI_UQ"; [ "$x" = - ] || _fi_add "$x"
    _fi_host "$o"
    when="$(date -r "$o" +%s 2>/dev/null)"; case "$when" in *[!0123456789]*|'') when=0 ;; esac
    case "${_FI_H[1]}" in *[!0123456789]*|'') ;; *) [ "${_FI_H[1]}" -gt "$when" ] && when="${_FI_H[1]}" ;; esac
    _fi_states "$_FI_OC" live="${_FI_H[2]}" question="${_FI_H[3]}" blocked="${_FI_H[4]}" orphan=yes helper="$_FI_HLP"; _fi_age "$when"
    ! _fi_temp "$o" || _fi_add temp
    _fi_row orphan "$o" "$_FI_S" "${_FI_H[0]}" "$_FI_A" "$_FI_OC" "$_FI_DET" - -
  done 3< "$T/orph"
}

# How many files in a directory hold content in no object of the repository,
# said as one detail (_FI_UQ): the files the ignore rules keep, then the ignored
# ones; and its content (_FI_OC): not when any holds content no object has,
# landed when none does and nothing was passed over or unreadable, else unknown.
# A file the run cannot open is counted in no k and said ("u files could not
# be read"), as is a directory the listing cannot enter and a file hash-object
# stopped at; it makes the content unknown, not landed.
_fi_uniq() {
  local o="$1" ex="" f n k m ki=0 u ui nf big=0 past=0 past2=0 lr
  [ -f "$o/.gitignore" ] || [ -z "$_FI_MAIN" ] || [ ! -f "$_FI_MAIN/.gitignore" ] || ex="--exclude-from=$_FI_MAIN/.gitignore"
  # A listing that fails (the directory itself cannot be entered) lists nothing: that is not a directory of no files.
  GIT_INDEX_FILE="$_FI_T/no-index" _fi_git --git-dir="$_FI_COMMON" --work-tree="$o" ls-files -z --others --exclude-standard ${ex:+"$ex"} \
    > "$T/ofz" 2> "$T/ofe"; lr=$?
  tr '\000' '\n' < "$T/ofz" > "$T/of"
  u="$(grep -c 'could not open directory' "$T/ofe")"; [ "$lr" = 0 ] || u=$((u + 1))
  while IFS= read -r f <&3; do
    case "$f" in */) continue ;; esac; [ -f "$o/$f" ] && [ ! -L "$o/$f" ] && printf '%s\n' "$o/$f"
  done 3< "$T/of" > "$T/of1"
  _fi_readable "$T/of1" "$T/of2"; nf="$_FI_UN"
  n="$(wc -l < "$T/of2" | tr -d ' ')"
  _fi_hashed "$T/of2" 20000; k="$_FI_UK"
  _FI_UQ="$k of $((_FI_UG + nf)) files hold content in no object of the repository"
  [ "$n" -le 20000 ] || { _FI_UQ="$_FI_UQ; files past the first 20000 not read"; past=1; }
  u=$((u + nf + _FI_UG - _FI_UH))
  [ "$u" = 0 ] || _FI_UQ="$_FI_UQ; $u files could not be read"
  GIT_INDEX_FILE="$_FI_T/no-index" _fi_git --git-dir="$_FI_COMMON" --work-tree="$o" ls-files -z --others --ignored --exclude-standard \
    --directory ${ex:+"$ex"} > "$T/oiz" 2> "$T/oie"; lr=$?
  tr '\000' '\n' < "$T/oiz" > "$T/oi"
  if [ -s "$T/oi" ]; then
    while IFS= read -r f <&3; do
      find "$o/${f%/}" -name .git -prune -o -type f -size -2049 -print -o -type f -exec printf '\001%s\n' {} + 2>> "$T/oie"
    done 3< "$T/oi" | awk -v st="$T/oib" 'substr($0, 1, 1) == "\001" { b++; next } ++n > 2000 { p = 1; exit } { print }
      END { printf "%d %d\n", b, p > st }' > "$T/oi1"
    read -r big past2 < "$T/oib"
    _fi_readable "$T/oi1" "$T/oi2"; nf="$_FI_UN"
    _fi_hashed "$T/oi2" 2000; ki="$_FI_UK"
    m=$((_FI_UG + nf))
    _FI_UQ="$_FI_UQ; $ki of $m ignored files hold content in no object"
    [ "${big:-0}" = 0 ] || _FI_UQ="$_FI_UQ; $big ignored files over 1 MiB not read"
    [ "${past2:-0}" = 0 ] || { _FI_UQ="$_FI_UQ; ignored files past the first 2000 not read"; past=1; }
  else nf=0; _FI_UG=0; _FI_UH=0
  fi
  ui=$(($(grep -c -e 'could not open directory' -e 'Permission denied' "$T/oie") + nf + _FI_UG - _FI_UH + (lr != 0)))
  [ "$ui" = 0 ] || _FI_UQ="$_FI_UQ; $ui ignored files could not be read"
  [ "$_FI_PARTIAL" = 0 ] || [ "$k$ki" = 00 ] || _FI_UQ="$_FI_UQ; a partial clone, whose remote may hold that content"
  if [ "$k" -gt 0 ] || [ "$ki" -gt 0 ]; then _FI_OC=not
  elif [ "$past" = 0 ] && [ "${big:-0}" = 0 ] && [ "$u" = 0 ] && [ "$ui" = 0 ]; then _FI_OC=landed
  else _FI_OC=unknown; fi
}
# The paths of file $1 that can be read into $2; _FI_UN is how many cannot.
_fi_readable() {
  local f; _FI_UN=0
  while IFS= read -r f <&3; do if [ -r "$f" ]; then printf '%s\n' "$f"; else _FI_UN=$((_FI_UN + 1)); fi; done 3< "$1" > "$2"
}
# The first $2 paths of file $1, hashed without filters and asked of the object
# store: _FI_UK of them hold content in no object, _FI_UG were given and _FI_UH
# hashed. hash-object stops at a file it cannot open, so fewer hashed than given
# says some were never read.
_fi_hashed() {
  head -n "$2" "$1" > "$T/ohp"
  _fi_git --git-dir="$_FI_COMMON" hash-object --no-filters --stdin-paths < "$T/ohp" > "$T/oh" 2>/dev/null
  _FI_UG="$(wc -l < "$T/ohp" | tr -d ' ')"; _FI_UH="$(wc -l < "$T/oh" | tr -d ' ')"
  _FI_UK="$(_fi_git --git-dir="$_FI_COMMON" cat-file --batch-check < "$T/oh" 2>/dev/null | grep -c ' missing$')"
}
