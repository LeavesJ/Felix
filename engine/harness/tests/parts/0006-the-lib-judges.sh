# The judges of tests/lib (contract C2, amended 2026-10-16, third round):
# _lib_runs_nothing FILE, which says whether sourcing a lib file does anything
# but define functions, and _lib_clashes, which says whether a function a lib
# file defines takes a name the suite or the shell already has. Both are defined
# here and not in part 0003, beside _suite_files, because 0003 would pass the
# 1,000 lines part 1040 allows; they are defined before the driver writes
# lib-before.names, so a lib file that defines either is a clash.
#
# The rule: sourced, a tests/lib file defines functions and nothing else. It
# runs no command and sets no variable, not even a plain assignment, because
# the list of variables that change how bash or the suite behaves (FAIL, IFS,
# GLOBIGNORE, POSIXLY_CORRECT, FELIX_TEST_NO_MANIFEST, ...) is open. A builder,
# or a _<name>_vars function, sets variables when a part calls it. A function's
# body runs when a part calls it and is part code like any other.
#
# Both judges read a lib file by sourcing it in a child, and never carry out
# what it holds. The child is a new /bin/bash --noprofile --norc under env -i
# with PATH and HOME, TMPDIR, TMP, FROOT, MEM, REPO, FELIX_HOME and FELIX
# pointing into a fresh scratch directory under $TMP, under set -u and -o
# pipefail, with extdebug on and a DEBUG trap that records each command the file
# would run and returns non-zero, so that command is skipped.
#
# Measured on /bin/bash 3.2.57(1)-release (arm64), in a sourced file:
# - A non-zero status from the DEBUG trap skips the command it fired for, with
#   extdebug on (and set -T, functrace, for the trap to fire inside a sourced
#   file at all). An echo prints nothing, an assignment sets nothing, ": > f"
#   and a bare "> f" create no file, "sleep 20 &" starts no sleep, "$(date)"
#   runs no date: the command substitution inherits the trap and skips its own
#   commands. The skipped command leaves status 0, so a loop whose test is
#   skipped never ends: "while _x=1; do _y=1; done" fires _x=1 and _y=1 forever.
# - A function definition fires nothing, in all three spellings (name() {,
#   name () {, function name {), and not when it sits inside { } or an if. It
#   defines the function, and its body fires only when it is called.
# - Compound commands: if, while, until and { } do not fire for themselves,
#   only for the commands inside, and { } holds a definition without firing at
#   all. for, case, select, (( )) and [[ ]] fire for their header ("for i in
#   1 2" once for each pass, "case a in "), and a skipped for or case skips its
#   body. ( ) and a pipeline run their commands in subshells that have the
#   trap, so those fire there. "time W=1" fires W=1 and prints its timing, to
#   stderr. A skipped test returns status 0, so "if false; then A=1; fi" fires
#   false and then A=1, and "a || b" fires a and not b.
# - What runs before the trap can fire is a redirect on a compound command: "{
#   :; } > f" creates f, and "{ :; } > ${V:=x}" sets V, before the ":" fires.
#   The command is recorded, so the file fails; but the file f is made. That
#   reaches outside the scratch directory if the path says so. A redirect on a
#   simple command is skipped with it.
# - A status of 2 from the trap, in a sourced file, makes the shell return from
#   the file, as extdebug documents. The trap gets it from [[ x =~ ( ]], a
#   regular expression that does not compile (status 2, no message), because
#   "return 2" would be looked up as a function first: a lib file can define
#   return, builtin, printf, declare, or any name, and the trap and everything
#   the child does after the source use only keywords, assignments and
#   absolute paths. The trap returns after 100 recorded commands, so an endless
#   loop in a lib file ends at once instead of at the time limit.
# - set -a makes a function defined in the file an exported one, and /usr/bin/env
#   -0 prints it as a record "BASH_FUNC_name%%=() {...}" (NUL between records,
#   so a here-document in a body that holds a line like that is not a second
#   record). That is how the names come out of the child, with no command of the
#   child's own that a function of the same name could take over. Any variable
#   the file set would be exported the same way, and appear in the second dump.
#
# What the judge does with it, the five conditions of _lib_runs_nothing:
#   1. no command was recorded;
#   2. nothing was printed to stdout or stderr;
#   3. nothing under the scratch directory changed (find -newer a file made
#      just before the run, and the directories still there);
#   4. the child's set of variable names is the same after sourcing as before
#      (the dumps of /usr/bin/env -0, one before the trap is set and one after
#      the file is sourced);
#   5. the child ended normally, within 10 s of wall time (a watcher kills it
#      and leaves a mark; an end mark is made by the child's last command).
# A file with a top-level { } that holds only definitions passes: the group
# runs no command and sets no variable.
#
# The child leaves one file for each command it records, in a directory beside
# the scratch one, named "NNNN text": a bare redirect is the only way to write
# from a trap that no function of the file can replace, and a subshell's
# record, which a variable would lose, survives in the directory.

_lrn_limit=10
read -r -d '' _lrn_child <<'LRN_CHILD_SCRIPT' || true
set -uTao pipefail
shopt -s extdebug
_lrn_f=$1; _lrn_w=$2; _lrn_n=1000; _lrn_bad='('; _lrn_ws=$'\n\r\t'; _lrn_sl=$'\001'
readonly _lrn_f _lrn_w _lrn_bad _lrn_ws _lrn_sl
cd -- "$TMP" || exit 99
_lrn_canary() { :; }
/usr/bin/env -0 > "$_lrn_w/env.before"
trap 'if [[ ${BASH_SOURCE[0]-} == "$_lrn_f" ]]; then _lrn_n=$((_lrn_n + 1)); _lrn_t=${BASH_COMMAND//[$_lrn_ws]/ }; _lrn_t=${_lrn_t//\//$_lrn_sl}; > "$_lrn_w/rec/$_lrn_n ${_lrn_t:0:100}"; if [[ $_lrn_n -gt 1100 ]]; then [[ x =~ $_lrn_bad ]]; else [[ -z . ]]; fi; fi' DEBUG
. "$_lrn_f"
/usr/bin/env -0 > "$_lrn_w/env.after"
> "$_lrn_w/end"
LRN_CHILD_SCRIPT

# _lib_read_env FILE: the names in a dump of /usr/bin/env -0, in _lj_vars (the
# variables) and _lj_fns (the functions), each name ending a line.
_lib_read_env() {
  local rec nm
  _lj_vars=""; _lj_fns=""
  [ -r "${1-}" ] || return 1
  while IFS= read -r -d '' rec; do
    case "$rec" in
      BASH_FUNC_*%%=\(\)*) nm="${rec#BASH_FUNC_}"; nm="${nm%%%%=()*}"; _lj_fns="$_lj_fns$nm"$'\n' ;;
      *=*) nm="${rec%%=*}"; _lj_vars="$_lj_vars$nm"$'\n' ;;
    esac
  done < "$1"
  return 0
}

# _lib_judge FILE: sources FILE in a child as described above and sets, in the
# caller's scope (the caller makes them local): _lj_said, empty when FILE does
# nothing but define functions, else what it did, starting "sourcing it ", and
# _lj_funcs, the names of the functions it defined, one a line, when the child
# got that far (_lj_have is then 1). Status 0 when it judged, 2 when it could
# not start (no such file, no scratch directory).
_lib_judge() {
  local f="${1-}" s w cpid wd rc x k nm timedout=0 vb va _lj_vars _lj_fns
  _lj_said=""; _lj_funcs=""; _lj_have=0
  case "$f" in /*) ;; *) f="$PWD/$f" ;; esac
  if [ -z "${1-}" ] || [ ! -f "$f" ]; then _lj_said="no such lib file to source"; return 2; fi
  w="$(mktemp -d "$TMP/lib-runs-nothing.XXXXXX")" && [ -n "$w" ] || { _lj_said="no scratch directory to source it in"; return 2; }
  s="$w/s"
  mkdir "$s" "$s/home" "$s/tmp" "$s/froot" "$s/memory" "$s/repo" "$s/felix-home" "$w/rec" && : > "$w/ref" \
    || { _lj_said="no scratch directory to source it in"; return 2; }
  env -i PATH="$PATH" HOME="$s/home" TMPDIR="$s/tmp" TMP="$s" FROOT="$s/froot" MEM="$s/memory" REPO="$s/repo" \
    FELIX_HOME="$s/felix-home" FELIX="$s/felix" /bin/bash --noprofile --norc -c "$_lrn_child" lrn "$f" "$w" \
    > "$w/out" 2>&1 < /dev/null &
  cpid=$!
  ( trap 'kill "${sp-}" 2>/dev/null; exit 0' TERM
    sleep "$_lrn_limit" & sp=$!; wait "$sp"; : > "$w/timeout"; kill -9 "$cpid" ) > /dev/null 2>&1 &
  wd=$!
  { wait "$cpid"; } 2>/dev/null; rc=$?
  kill "$wd" 2>/dev/null; { wait "$wd"; } 2>/dev/null
  [ ! -f "$w/timeout" ] || timedout=1
  k=""
  for x in "$w/rec"/*; do
    [ -e "$x" ] || break
    k="${x##*/}"; k="${k#* }"; k="${k//$'\001'//}"; break
  done
  if [ -f "$w/end" ] && _lib_read_env "$w/env.before"; then
    vb="$_lj_vars"
    if _lib_read_env "$w/env.after"; then
      va="$_lj_vars"
      case $'\n'"$_lj_fns" in
        *$'\n_lrn_canary\n'*) _lj_have=1 ;;
      esac
      if [ "$_lj_have" -eq 1 ]; then
        while IFS= read -r nm; do
          case "$nm" in ''|_lrn_canary) ;; *) _lj_funcs="$_lj_funcs$nm"$'\n' ;; esac
        done <<<"$_lj_fns"
      fi
    fi
  fi
  if [ -n "$k" ]; then _lj_said="ran [$k]"
  elif [ "$timedout" -eq 1 ]; then _lj_said="went past its ${_lrn_limit} s time limit"
  elif [ ! -f "$w/end" ]; then _lj_said="ended the shell before the source returned (status $rc)"
  elif [ "$_lj_have" -ne 1 ]; then _lj_said="left no function table to read"
  elif [ -s "$w/out" ]; then
    _lj_said="printed $(wc -c < "$w/out" | tr -d ' ') byte(s) to stdout or stderr, the first line [$(head -1 "$w/out" | LC_ALL=C tr -d '\r' | cut -c1-60)]"
  else
    nm=""
    while IFS= read -r x; do
      case "$x" in ''|_|_lrn_*) continue ;; esac
      case $'\n'"$vb" in *$'\n'"$x"$'\n'*) ;; *) nm="$nm $x" ;; esac
    done <<<"$va"
    while IFS= read -r x; do
      case "$x" in ''|_|_lrn_*) continue ;; esac
      case $'\n'"$va" in *$'\n'"$x"$'\n'*) ;; *) nm="$nm -$x" ;; esac
    done <<<"$vb"
    if [ -n "$nm" ]; then _lj_said="changed the set of variable names:$nm"
    else
      for x in s s/home s/tmp s/froot s/memory s/repo s/felix-home; do
        [ -d "$w/$x" ] || { _lj_said="removed a directory of its scratch directory: ${x#s/}"; break; }
      done
      if [ -z "$_lj_said" ]; then
        k="$(LC_ALL=C find "$s" -newer "$w/ref" | head -3 | sed "s|^$s/*||" | LC_ALL=C tr '\n' ' ')"
        [ -z "$k" ] || _lj_said="changed its scratch directory: $k"
      fi
    fi
  fi
  [ -z "$_lj_said" ] || _lj_said="sourcing it $_lj_said"
  rm -rf "$w"
  return 0
}

# _lib_runs_nothing FILE -> 0 when sourcing FILE does nothing but define
# functions, 1 and one line naming FILE and the first thing it did (the command
# text, the variable set, the time limit, ...) when it does. See above.
_lib_runs_nothing() {
  local _lj_said _lj_funcs _lj_have
  _lib_judge "${1-}"
  if [ -z "$_lj_said" ]; then return 0; fi
  case "${1-}" in /*) ;; *) set -- "$PWD/${1-}" ;; esac
  printf '%s: %s\n' "${1-}" "$_lj_said" | LC_ALL=C tr '\n' ' ' | sed 's/ $//'; printf '\n'
  return 1
}

# _lib_clashes -> one line NAME<TAB>LIBFILE<TAB>WHAT for each function that a
# tests/lib file defines and that is
# - in $TMP/lib-before.names, the names the driver held before the lib block
#   (WHAT: defined before the lib block);
# - a bash builtin, a keyword, an alias, or a command found on PATH (WHAT: a
#   builtin, a keyword, an alias, or the command's path), so a lib file cannot
#   take over [, ., printf or git for every later part;
# - defined by another lib file (WHAT: that file's path);
# - defined by another file of _suite_files, a part or the driver (WHAT: that
#   file's path), read by the shape of the line, name() or function name at the
#   start of a line: a here-document in it that holds such a line is read as a
#   definition, which can only add a clash, never hide one.
# and nothing when there is none, so "prints nothing" is the verdict. The names
# of a lib file's functions come from the child that sourced it (_lib_judge), not
# from its text, so a definition inside { }, an if or a quoted string is seen as
# the shell sees it. A variable is no clash and no concern of this one: a lib
# file that sets one fails _lib_runs_nothing. A lib file the child could not
# read to the end (a time limit, an exit), no lib-before.names beside lib files,
# or no file to read is status 2 and a message on stderr, not an empty verdict.
# The files are read from $HERE (the tests directory, the driver's or a copy's)
# and the names from $TMP.
_lcl_awk='
BEGIN {
  n = split(ENVIRON["LCL_DEFS"], d, "\n")
  for (i = 1; i <= n; i++) if (d[i] != "") { split(d[i], p, "\t"); defs[p[1]] = defs[p[1]] SUBSEP p[2] }
}
index($0, "()") || index($0, "function") {
  s = $0; sub(/^[ \t]+/, "", s); nm = ""
  if (s ~ /^function[ \t]+[A-Za-z_]/) { sub(/^function[ \t]+/, "", s); match(s, /^[A-Za-z_][A-Za-z0-9_:.+@%-]*/); nm = substr(s, 1, RLENGTH) }
  else if (match(s, /^[A-Za-z_][A-Za-z0-9_:.+@%-]*[ \t]*\(\)/)) { nm = substr(s, 1, RLENGTH); sub(/[ \t]*\(\)$/, "", nm) }
  if (nm != "" && (nm in defs) && !((nm SUBSEP FILENAME) in seen)) {
    seen[nm SUBSEP FILENAME] = 1
    m = split(defs[nm], o, SUBSEP)
    for (j = 2; j <= m; j++) print nm "\t" o[j] "\t" FILENAME
  }
}'
_lib_clashes() {
  local f libs=0 files=() others=() libfiles=() nm lf before kinds bi ke al defs="" out="" what rc=0 d p
  local _lj_said _lj_funcs _lj_have
  while IFS= read -r f; do
    files[${#files[@]}]="$f"
    case "$f" in "$HERE"/lib/*) libs=1; libfiles[${#libfiles[@]}]="$f" ;; *) others[${#others[@]}]="$f" ;; esac
  done < <(_suite_files)
  [ "$libs" -eq 1 ] || return 0
  [ -r "$TMP/lib-before.names" ] || {
    printf '_lib_clashes: no %s/lib-before.names to read the names defined before the lib block from\n' "$TMP" >&2; return 2; }
  before=$'\n'
  while IFS= read -r nm; do before="$before$nm"$'\n'; done < "$TMP/lib-before.names"
  kinds="$(compgen -b; printf '@@\n'; compgen -k; printf '@@\n'; compgen -a)"
  bi="${kinds%%@@*}"; ke="${kinds#*@@}"; al="${ke#*@@}"; ke="${ke%%@@*}"
  bi=$'\n'"$bi"; ke=$'\n'"$ke"; al=$'\n'"$al"$'\n'
  for lf in "${libfiles[@]}"; do
    _lib_judge "$lf"; rc=$?
    if [ "$rc" -ne 0 ] || [ "$_lj_have" -ne 1 ]; then
      printf '_lib_clashes: could not read the functions of %s: sourcing it %s\n' "$lf" "${_lj_said:-left no function table to read}" >&2
      return 2
    fi
    while IFS= read -r nm; do
      [ -n "$nm" ] || continue
      defs="$defs$nm"$'\t'"$lf"$'\n'
      case "$before" in *$'\n'"$nm"$'\n'*) out="$out$nm"$'\t'"$lf"$'\t'"defined before the lib block"$'\n' ;; esac
      what=""
      case "$al" in *$'\n'"$nm"$'\n'*) what="an alias" ;; esac
      [ -n "$what" ] || case "$ke" in *$'\n'"$nm"$'\n'*) what="a keyword" ;; esac
      [ -n "$what" ] || case "$bi" in *$'\n'"$nm"$'\n'*) what="a builtin" ;; esac
      if [ -z "$what" ]; then
        if [[ "$nm" == */* ]]; then [ -f "$nm" ] && [ -x "$nm" ] && what="$nm"
        else
          p="$PATH"
          while :; do
            d="${p%%:*}"
            [ -n "$d" ] || d="."
            if [ -f "$d/$nm" ] && [ -x "$d/$nm" ]; then what="$d/$nm"; break; fi
            case "$p" in *:*) p="${p#*:}" ;; *) break ;; esac
          done
        fi
      fi
      [ -z "$what" ] || out="$out$nm"$'\t'"$lf"$'\t'"$what"$'\n'
    done <<<"$_lj_funcs"
  done
  # the same function defined by two lib files: a line for each
  while IFS=$'\t' read -r nm lf; do
    [ -n "$nm" ] || continue
    while IFS=$'\t' read -r d p; do
      [ "$d" = "$nm" ] && [ "$p" != "$lf" ] && out="$out$nm"$'\t'"$lf"$'\t'"$p"$'\n'
    done <<<"$defs"
  done <<<"$defs"
  {
    printf '%s' "$out"
    [ "${#others[@]}" -eq 0 ] || LCL_DEFS="$defs" LC_ALL=C awk "$_lcl_awk" "${others[@]}"
  } | LC_ALL=C sort -u
}
# The variables the lib files' functions read are set by the driver, once, after
# the lib lines, by the _vars function of each file that has them: a lib file
# sets none as it is sourced (C2). A copy of the driver (_suite_copy_driver) drops
# the lib lines and has no lib.
