# >>> gate-friction-a-receipt
printf '\ngate friction A: the receipt helpers and the tree id\n'
# Blind, written from contract A alone (docs/2026-10-12-gate-friction-contract-a.md,
# C4, C5 and C8) on 2026-10-12, before the code it describes existed. Nothing
# here was read off an implementation. tests/receipt.sh is sourced in a child
# bash of its own, as the driver's bash would be, and asked about fixture
# repositories built under $TMP; felix_tree_id is asked through lib/verify.sh,
# sourced in a subshell. An assertion whose name ends in (control) passes on
# the code before the change on purpose: it pins something the contract keeps.
#
# Readings of the contract taken here, where its words allow more than one:
# "git hash-object of $PATH" is taken as the hash of PATH's bytes with or
# without one trailing newline, both accepted; "LC_ALL, else LC_CTYPE, else
# LANG" is asked only with each variable either unset or set to a non-empty
# value; a receipt is "one line" when it holds one newline-ended line.
GFA="$TMP/gfa-receipt"; mkdir -p "$GFA/plain"
GFA_R="$REAL_HARNESS/tests/receipt.sh"
_gfa_git() { git -c user.name=gfa -c user.email=gfa@example.invalid -c commit.gpgsign=false -c core.hooksPath=/dev/null "$@"; }
# <dir>: a repository on main with one commit holding a.txt, b.txt, state/x
# and the two record files, so that every exclusion has something to exclude.
_gfa_repo() {
  mkdir -p "${1:?}/engine/harness/tests" "${1:?}/state" || return 1
  printf 'a\n' > "$1/a.txt"; printf 'b\n' > "$1/b.txt"; printf 's\n' > "$1/state/x"
  printf '1\tone\n' > "$1/engine/harness/tests/assertions.tsv"
  printf 'base\t-\t-\t-\nrun\t-\t-\t-\n' > "$1/engine/harness/tests/red.tsv"
  ( cd "${1:?}" && _gfa_git init -q -b main && _gfa_git add -A && _gfa_git commit -qm seed ) >/dev/null 2>&1
}
# A receipt.sh helper, in a child bash that sources the file and nothing else.
# Exit 97 when the file cannot be sourced; otherwise the helper's own status.
_gfa_sr() { bash -c '. "$1" >/dev/null 2>&1 || exit 97; shift; "$@"' _ "$GFA_R" "$@" 2>/dev/null; }
_gfa_srs() { local o; o="$(_gfa_sr "$@")"; printf '%s|%s' "$o" "$?"; }   # output|status
_gfa_tid() { ( . "$REAL_HARNESS/lib/verify.sh" >/dev/null 2>&1; felix_tree_id "$@" ) 2>/dev/null; }
# What a value must equal, or a placeholder no helper prints when the value
# itself could not be computed, so two empty answers never agree.
_gfa_want() { printf '%s' "${1:-<nothing was computed to compare with>}"; }
_gfa_line() { printf 'v1\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$@"; }   # tree mode passed failed skipped env start end

# ---- _sr_path
GFA_G="$GFA/g"; _gfa_repo "$GFA_G"; GFA_G="$(cd "${GFA_G:?}" && pwd -P)"
is  "_sr_path names felix-suite-receipt in the checkout's git directory, as an absolute path" \
    "$(_gfa_srs _sr_path "$GFA_G")" "$GFA_G/.git/felix-suite-receipt|0"
_gfa_git -C "${GFA_G:?}" worktree add -q --detach "$GFA/gw" HEAD >/dev/null 2>&1
GFA_GW="$(cd "${GFA:?}/gw" 2>/dev/null && pwd -P)"
_gfa_gwp="$(git -C "${GFA_GW:?}" rev-parse --git-path felix-suite-receipt 2>/dev/null)"
case "$_gfa_gwp" in /*) ;; *) _gfa_gwp="$GFA_GW/$_gfa_gwp" ;; esac
is  "_sr_path in a linked worktree names that worktree's own git path, not the main checkout's" \
    "$(_gfa_srs _sr_path "$GFA_GW")" "$_gfa_gwp|0"
is  "_sr_path of a directory that is no git checkout prints nothing and returns 1" \
    "$(_gfa_srs _sr_path "$GFA/plain")" "|1"

# ---- _sr_tree
is  "_sr_tree of a checkout is felix_tree_id of it with an empty home" \
    "$(_gfa_srs _sr_tree "$GFA_G")" "$(_gfa_want "$(_gfa_tid "$GFA_G" "")")|0"
printf 'a2\n' > "$GFA_G/a.txt"; printf 'u\n' > "$GFA_G/untracked.txt"; printf 's2\n' > "$GFA_G/state/x"
is  "and on a dirty tree, state included since an empty home excludes nothing, it is still that id" \
    "$(_gfa_srs _sr_tree "$GFA_G")" "$(_gfa_want "$(_gfa_tid "$GFA_G" "")")|0"
is  "_sr_tree of a directory that is no git checkout prints nothing and returns 1" \
    "$(_gfa_srs _sr_tree "$GFA/plain")" "|1"
GFA_K="$GFA/k"; _gfa_repo "$GFA_K"; GFA_K="$(cd "${GFA_K:?}" && pwd -P)"
printf '1\n' > "$GFA_K/u1"; printf '2\n' > "$GFA_K/u2"; printf '3\n' > "$GFA_K/u3"
_gfa_coarse="$( ( FELIX_UNTRACKED_CAP=2; . "$REAL_HARNESS/lib/verify.sh" >/dev/null 2>&1; felix_tree_id "$GFA_K" "" ) 2>/dev/null)"
case "$_gfa_coarse" in
  coarse:*) is "_sr_tree of a tree whose id is coarse prints nothing and returns 1, as one it cannot compute" \
                "$(FELIX_UNTRACKED_CAP=2 _gfa_srs _sr_tree "$GFA_K")" "|1" ;;
  *) bad "_sr_tree of a tree whose id is coarse prints nothing and returns 1, as one it cannot compute" \
         "the fixture's id is not coarse: [$_gfa_coarse]" ;;
esac
GFA_S="$GFA/s"; _gfa_repo "$GFA_S"; GFA_S="$(cd "${GFA_S:?}" && pwd -P)"
printf 'b2\n' > "$GFA_S/b.txt"
_gfa_f0="$(_gfa_sr _sr_tree "$GFA_S")"; _gfa_s0="$(_gfa_sr _sr_tree "$GFA_S" stable)"
is  "on a tree whose two record files match HEAD, the stable id is the full id" "$_gfa_s0" "$(_gfa_want "$_gfa_f0")"
printf '2\tone\n' > "$GFA_S/engine/harness/tests/assertions.tsv"
_gfa_f1="$(_gfa_sr _sr_tree "$GFA_S")"; _gfa_s1="$(_gfa_sr _sr_tree "$GFA_S" stable)"
is  "a change to assertions.tsv leaves the stable id as it was" "$_gfa_s1" "$(_gfa_want "$_gfa_s0")"
[ -n "$_gfa_f1" ] && [ "$_gfa_f1" != "$_gfa_f0" ] \
  && ok  "while the same change moves the full id" \
  || bad "while the same change moves the full id" "full id before [$_gfa_f0] after [$_gfa_f1]"
printf 'base\tmain\tx\t1\n' > "$GFA_S/engine/harness/tests/red.tsv"
is  "a change to red.tsv leaves the stable id as it was too" "$(_gfa_sr _sr_tree "$GFA_S" stable)" "$(_gfa_want "$_gfa_s0")"
printf 'b3\n' > "$GFA_S/b.txt"
_gfa_s3="$(_gfa_sr _sr_tree "$GFA_S" stable)"
[ -n "$_gfa_s3" ] && [ "$_gfa_s3" != "$_gfa_s0" ] \
  && ok  "a change to any other file moves the stable id" \
  || bad "a change to any other file moves the stable id" "stable id before [$_gfa_s0] after [$_gfa_s3]"

# ---- sourced on its own
GFA_P="$(dirname "$(command -v git)"):/usr/bin:/bin"
_gfa_alone() { env -i PATH="$GFA_P" HOME="$HOME" "$@"; }
is  "receipt.sh sourced by a bash given nothing but PATH and HOME answers _sr_tree" \
    "$(_gfa_alone bash -c '. "$1" >/dev/null 2>&1 && _sr_tree "$2"' _ "$GFA_R" "$GFA_G" 2>/dev/null)" \
    "$(_gfa_want "$(_gfa_tid "$GFA_G" "")")"
is  "and sourcing it leaves no felix_verify_ function in the shell that sourced it" \
    "$(_gfa_alone bash -c '. "$1" >/dev/null 2>&1 || { echo not sourced; exit 0; }; declare -F | awk "\$3 ~ /^felix_verify_/ { n++ } END { print n + 0 }"' _ "$GFA_R" 2>/dev/null)" "0"

# ---- _sr_env
_gfa_bv="$(_gfa_alone bash -c 'printf %s "$BASH_VERSION"' 2>/dev/null)"
_gfa_ph1="$(printf '%s' "$GFA_P" | git hash-object --stdin)"; _gfa_ph2="$(printf '%s\n' "$GFA_P" | git hash-object --stdin)"
_gfa_cl="$(_gfa_alone bash -c 'command -v claude >/dev/null 2>&1 && echo yes || echo no' 2>/dev/null)"
_gfa_env() { _gfa_alone "$@" bash -c '. "$1" >/dev/null 2>&1 || exit 97; _sr_env' _ "$GFA_R" 2>/dev/null; }
# The host, by contract B4.1: scutil's LocalHostName when /usr/sbin/scutil is
# executable, exits 0 and prints one non-empty line of ASCII letters, digits
# and hyphens; else uname -n.
_gfa_h="$(uname -n)"
if [ -x /usr/sbin/scutil ] && _gfa_lh="$(/usr/sbin/scutil --get LocalHostName 2>/dev/null)"; then
  case "$_gfa_lh" in
    ""|*[!ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-]*) ;;
    *) _gfa_h="$_gfa_lh" ;;
  esac
fi
_gfa_e0="$(_gfa_env)"
case "$_gfa_e0" in
  "host=$_gfa_h;bash=$_gfa_bv;locale=;path=$_gfa_ph1;claude=$_gfa_cl"|"host=$_gfa_h;bash=$_gfa_bv;locale=;path=$_gfa_ph2;claude=$_gfa_cl")
    ok  "_sr_env is one line of host, bash version, an empty locale when none is set, the hash of PATH and claude, in that order" ;;
  *) bad "_sr_env is one line of host, bash version, an empty locale when none is set, the hash of PATH and claude, in that order" \
         "got [$_gfa_e0]" ;;
esac
_gfa_loc() { _gfa_env "$@" | sed -n 's/^.*;locale=\([^;]*\);path=.*$/\1/p'; }
is  "_sr_env's locale is LC_ALL when it is set" "$(_gfa_loc LC_ALL=gfa-all LC_CTYPE=gfa-ctype LANG=gfa-lang)" "gfa-all"
is  "and LC_CTYPE when LC_ALL is not" "$(_gfa_loc LC_CTYPE=gfa-ctype LANG=gfa-lang)" "gfa-ctype"
is  "and LANG when neither is" "$(_gfa_loc LANG=gfa-lang)" "gfa-lang"
mkdir -p "$GFA/bin"; printf '#!/bin/sh\nexit 0\n' > "$GFA/bin/claude"; chmod +x "$GFA/bin/claude"
_gfa_e1="$(_gfa_alone PATH="$GFA/bin:$GFA_P" bash -c '. "$1" >/dev/null 2>&1 || exit 97; _sr_env' _ "$GFA_R" 2>/dev/null)"
case "$_gfa_e1" in
  *";claude=yes") ok  "_sr_env says claude=yes when a claude command is on PATH" ;;
  *) bad "_sr_env says claude=yes when a claude command is on PATH" "got [$_gfa_e1]" ;;
esac
if [ "$_gfa_cl" = no ]; then
  case "$_gfa_e0" in
    *";claude=no") ok  "and claude=no when none is" ;;
    *) bad "and claude=no when none is" "got [$_gfa_e0]" ;;
  esac
else
  skip "and claude=no when none is" "a claude command is on $GFA_P"
fi
[ -n "$_gfa_e1" ] && [ "${_gfa_e1%%;path=*}" = "${_gfa_e0%%;path=*}" ] && [ "$_gfa_e1" != "$_gfa_e0" ] \
  && [ "${_gfa_e1#*;path=}" != "${_gfa_e0#*;path=}" ] \
  && ok  "a different PATH gives a different path hash" \
  || bad "a different PATH gives a different path hash" "[$_gfa_e0] against [$_gfa_e1]"

# ---- _sr_check
GFA_C="$GFA/c"; _gfa_repo "$GFA_C"; GFA_C="$(cd "${GFA_C:?}" && pwd -P)"
GFA_CP="$GFA_C/.git/felix-suite-receipt"
_gfa_T="$(_gfa_sr _sr_tree "$GFA_C")"; _gfa_E="$(_gfa_sr _sr_env)"
_gfa_now() { date +%s; }
_gfa_put() { rm -rf "${GFA_CP:?}"; printf '%s' "$1" > "$GFA_CP"; }
_gfa_chk() { _gfa_srs _sr_check "${1:-$GFA_C}"; }
is  "_sr_check of a directory that is no git checkout says run no checkout, and returns 0" "$(_gfa_chk "$GFA/plain")" "run no checkout|0"
rm -rf "${GFA_CP:?}"
is  "_sr_check with nothing at the receipt path says run no receipt" "$(_gfa_chk)" "run no receipt|0"
_gfa_n="$(_gfa_now)"; _gfa_end=$((_gfa_n - 100))
_gfa_put "$(_gfa_line "$_gfa_T" record 7 0 2 "$_gfa_E" $((_gfa_n - 160)) "$_gfa_end")
"
is  "_sr_check of a sound receipt for this tree and this environment says reuse with its counts, end and mode" \
    "$(_gfa_chk)" "reuse 7 0 2 $_gfa_end record|0"
_gfa_put "$(_gfa_line "$_gfa_T" normal 3 0 0 "$_gfa_E" $((_gfa_n - 160)) "$_gfa_end")
"
is  "and a normal run's receipt is reused with mode normal" "$(_gfa_chk)" "reuse 3 0 0 $_gfa_end normal|0"
cp "$GFA_CP" "$GFA/sound.receipt"
is  "a linked worktree does not read the main checkout's receipt" "$(_gfa_chk "$GFA_GW")" "run no receipt|0"
rm -f "$GFA_CP"; ln -s "$GFA/sound.receipt" "$GFA_CP"
is  "a receipt path that is a symbolic link, even to a sound receipt, is not a regular file" "$(_gfa_chk)" "run not a regular file|0"
rm -f "$GFA_CP"; mkdir "$GFA_CP"
is  "a receipt path that is a directory is not a regular file" "$(_gfa_chk)" "run not a regular file|0"
rmdir "$GFA_CP"; mkfifo "$GFA_CP" 2>/dev/null
if [ -p "$GFA_CP" ]; then
  ( _gfa_chk > "$GFA/fifo.out" ) & _gfa_fp=$!; _gfa_fn=0
  while kill -0 "$_gfa_fp" 2>/dev/null && [ "$_gfa_fn" -lt 100 ]; do sleep 0.1; _gfa_fn=$((_gfa_fn + 1)); done
  if kill -0 "$_gfa_fp" 2>/dev/null; then
    ( exec 9<>"$GFA_CP" ) 2>/dev/null; sleep 0.2; kill -9 "$_gfa_fp" 2>/dev/null
    bad "a receipt path that is a FIFO is not a regular file, said without opening it" "it had not answered after 10 s"
  else
    is "a receipt path that is a FIFO is not a regular file, said without opening it" "$(cat "$GFA/fifo.out")" "run not a regular file|0"
  fi
  wait "$_gfa_fp" 2>/dev/null
  rm -f "$GFA_CP"
else
  skip "a receipt path that is a FIFO is not a regular file, said without opening it" "mkfifo made no FIFO here"
fi
cp "$GFA/sound.receipt" "$GFA_CP"; chmod 000 "$GFA_CP"
if [ -r "$GFA_CP" ]; then
  skip "a receipt that cannot be read is an unreadable receipt" "this user reads a file of mode 000"
else
  is  "a receipt that cannot be read is an unreadable receipt" "$(_gfa_chk)" "run unreadable receipt|0"
fi
chmod 600 "$GFA_CP"
# Malformed, each against an otherwise sound receipt: a label, then the line.
_gfa_n="$(_gfa_now)"; _gfa_st=$((_gfa_n - 160)); _gfa_en=$((_gfa_n - 100)); _gfa_tab="$(printf '\t')"
_gfa_ok_line="$(_gfa_line "$_gfa_T" normal 3 0 0 "$_gfa_E" "$_gfa_st" "$_gfa_en")"
_gfa_mal() {   # <name> <receipt text>
  _gfa_put "$2"; is "$1" "$(_gfa_chk)" "run malformed receipt|0"
}
_gfa_mal "a receipt of eight fields is malformed" \
  "$(printf 'v1\t%s\tnormal\t3\t0\t0\t%s\t%s' "$_gfa_T" "$_gfa_E" "$_gfa_en")
"
_gfa_mal "a receipt of ten fields is malformed" "$_gfa_ok_line${_gfa_tab}extra
"
_gfa_mal "a receipt of two sound lines is malformed" "$_gfa_ok_line
$_gfa_ok_line
"
_gfa_mal "an empty receipt is malformed" ""
_gfa_mal "a receipt beginning v2 is malformed" "v2${_gfa_ok_line#v1}
"
_gfa_mal "a receipt whose mode is neither normal nor record is malformed" \
  "$(_gfa_line "$_gfa_T" quick 3 0 0 "$_gfa_E" "$_gfa_st" "$_gfa_en")
"
_gfa_mal "a receipt whose passed count is not decimal digits is malformed" \
  "$(_gfa_line "$_gfa_T" normal 3a 0 0 "$_gfa_E" "$_gfa_st" "$_gfa_en")
"
_gfa_mal "a receipt whose failed count is negative is malformed, not a failure recorded" \
  "$(_gfa_line "$_gfa_T" normal 3 -1 0 "$_gfa_E" "$_gfa_st" "$_gfa_en")
"
_gfa_mal "a receipt whose skipped count is empty is malformed" \
  "$(_gfa_line "$_gfa_T" normal 3 0 "" "$_gfa_E" "$_gfa_st" "$_gfa_en")
"
_gfa_mal "a receipt whose start is not decimal digits is malformed" \
  "$(_gfa_line "$_gfa_T" normal 3 0 0 "$_gfa_E" "x$_gfa_st" "$_gfa_en")
"
_gfa_mal "a receipt whose start is after its end is malformed" \
  "$(_gfa_line "$_gfa_T" normal 3 0 0 "$_gfa_E" "$((_gfa_en + 5))" "$_gfa_en")
"
_gfa_mal "a receipt whose end is more than 60 seconds in the future is malformed" \
  "$(_gfa_line "$_gfa_T" normal 3 0 0 "$_gfa_E" "$_gfa_st" "$((_gfa_n + 600))")
"
_gfa_mal "a receipt with a failure and a mode that is no mode is malformed first" \
  "$(_gfa_line "$_gfa_T" Record 3 1 0 "$_gfa_E" "$_gfa_st" "$_gfa_en")
"
_gfa_put "$(_gfa_line "$_gfa_T" normal 3 0 0 "$_gfa_E" "$((_gfa_n - 10))" "$((_gfa_n + 30))")
"
is  "a receipt whose end is 30 seconds ahead is not malformed, and is reused" "$(_gfa_chk)" "reuse 3 0 0 $((_gfa_n + 30)) normal|0"
_gfa_put "$(_gfa_line "$_gfa_T" normal 3 1 0 "$_gfa_E" "$_gfa_st" "$_gfa_en")
"
is  "a sound receipt that records a failure says run failures recorded" "$(_gfa_chk)" "run failures recorded|0"
_gfa_put "$(_gfa_line "0$_gfa_T" normal 3 1 0 "$_gfa_E" "$_gfa_st" "$_gfa_en")
"
is  "a failure recorded is said before another tree" "$(_gfa_chk)" "run failures recorded|0"
_gfa_put "$(_gfa_line "0$_gfa_T" normal 3 0 0 "$_gfa_E" "$_gfa_st" "$_gfa_en")
"
is  "a receipt for another tree id says run another tree" "$(_gfa_chk)" "run another tree|0"
_gfa_put "$(_gfa_line "0$_gfa_T" normal 3 0 0 "x$_gfa_E" "$_gfa_st" "$_gfa_en")
"
is  "another tree is said before another environment" "$(_gfa_chk)" "run another tree|0"
_gfa_put "$(_gfa_line "$_gfa_T" normal 3 0 0 "x$_gfa_E" "$_gfa_st" "$_gfa_en")
"
is  "a receipt from another environment says run another environment" "$(_gfa_chk)" "run another environment|0"
_gfa_put "$(_gfa_line "$_gfa_T" normal 3 0 0 "x$_gfa_E" "$((_gfa_n - 43400))" "$((_gfa_n - 43300))")
"
is  "another environment is said before older than 12 hours" "$(_gfa_chk)" "run another environment|0"
_gfa_put "$(_gfa_line "$_gfa_T" normal 3 0 0 "$_gfa_E" "$((_gfa_n - 43400))" "$((_gfa_n - 43300))")
"
is  "a receipt that ended more than 43200 seconds ago is older than 12 hours" "$(_gfa_chk)" "run older than 12 hours|0"
_gfa_put "$(_gfa_line "$_gfa_T" normal 3 0 0 "$_gfa_E" "$((_gfa_n - 43200))" "$((_gfa_n - 43100))")
"
is  "and one that ended 43100 seconds ago is still reused" "$(_gfa_chk)" "reuse 3 0 0 $((_gfa_n - 43100)) normal|0"
# The tree _sr_check compares is the full one: a record run's stable id, taken
# while the record files differ from HEAD, is another tree's.
printf '5\tone\n' > "$GFA_C/engine/harness/tests/assertions.tsv"
_gfa_put "$(_gfa_line "$(_gfa_sr _sr_tree "$GFA_C" stable)" record 3 0 0 "$_gfa_E" "$_gfa_st" "$_gfa_en")
"
is  "a receipt holding the stable id of a tree whose manifest changed is for another tree" "$(_gfa_chk)" "run another tree|0"
# A tree whose id is coarse cannot be computed, so even its own coarse id is
# another tree's.
printf '%s' "$(_gfa_line "$_gfa_coarse" normal 3 0 0 "$_gfa_E" "$_gfa_st" "$_gfa_en")
" > "$GFA_K/.git/felix-suite-receipt"
is  "a receipt for a tree whose id is coarse now says run another tree, its own coarse id notwithstanding" \
    "$(FELIX_UNTRACKED_CAP=2 _gfa_chk "$GFA_K")" "run another tree|0"

# ---- C8: felix_tree_id takes extra exclusions
GFA_OLD="$GFA/old-verify.sh"
if git -C "$REAL_HARNESS" show 2fc0c6715b3067c6e07cbfca10bbebbc3c70f451:engine/harness/lib/verify.sh > "$GFA_OLD" 2>/dev/null; then
  GFA_8="$GFA/t8"; _gfa_repo "$GFA_8"; GFA_8="$(cd "${GFA_8:?}" && pwd -P)"
  _gfa_same() {   # args...: same, when the function before this change and the one now print one non-empty id
    local n o
    n="$(_gfa_tid "$@")"; o="$( ( . "$GFA_OLD" >/dev/null 2>&1; felix_tree_id "$@" ) 2>/dev/null)"
    [ -n "$n" ] && [ "$n" = "$o" ] && echo same || echo "differs($*)"
  }
  _gfa_r1="$(_gfa_same "$GFA_8" "")"
  printf 'a2\n' > "$GFA_8/a.txt"; printf 'u\n' > "$GFA_8/u.txt"
  _gfa_r2="$(_gfa_same "$GFA_8" "")"
  printf 's2\n' > "$GFA_8/state/x"
  is  "with two arguments or fewer felix_tree_id prints what the function before this change printed (control)" \
      "$_gfa_r1 $_gfa_r2 $(_gfa_same "$GFA_8" "$GFA_8") $(_gfa_same "$GFA_8")" "same same same same"
else
  skip "with two arguments or fewer felix_tree_id prints what the function before this change printed (control)" \
       "the commit before the change is not in this repository"
fi
GFA_9="$GFA/t9"; _gfa_repo "$GFA_9"; GFA_9="$(cd "${GFA_9:?}" && pwd -P)"
_gfa_x0="$(_gfa_tid "$GFA_9" "" ':(exclude)a.txt')"
printf 'a2\n' > "$GFA_9/a.txt"
is  "a change to a path a third argument excludes leaves felix_tree_id's id as it was" \
    "$(_gfa_tid "$GFA_9" "" ':(exclude)a.txt')" "$(_gfa_want "$_gfa_x0")"
_gfa_x1="$(_gfa_tid "$GFA_9" "" ':(exclude)a.txt')"; printf 'b2\n' > "$GFA_9/b.txt"
_gfa_x2="$(_gfa_tid "$GFA_9" "" ':(exclude)a.txt')"
[ -n "$_gfa_x2" ] && [ "$_gfa_x2" != "$_gfa_x1" ] \
  && ok  "while a change to a path no argument excludes still moves it (control)" \
  || bad "while a change to a path no argument excludes still moves it (control)" "[$_gfa_x1] then [$_gfa_x2]"
_gfa_x3="$(_gfa_tid "$GFA_9" "" ':(exclude)a.txt' ':(exclude)v.txt')"
printf 'v\n' > "$GFA_9/v.txt"; printf 'a3\n' > "$GFA_9/a.txt"
is  "every argument after the second excludes, an untracked file as much as a tracked one" \
    "$(_gfa_tid "$GFA_9" "" ':(exclude)a.txt' ':(exclude)v.txt')" "$(_gfa_want "$_gfa_x3")"
_gfa_h0="$(_gfa_tid "$GFA_9" "$GFA_9" ':(exclude)b.txt')"
printf 's2\n' > "$GFA_9/state/x"; printf 'b3\n' > "$GFA_9/b.txt"
is  "given a home inside the root, the extra exclusions apply beside the home's own" \
    "$(_gfa_tid "$GFA_9" "$GFA_9" ':(exclude)b.txt')" "$(_gfa_want "$_gfa_h0")"
_gfa_g0="$(_gfa_tid "$GFA_9" "" ':(exclude,glob)**/*.gfalog')"
mkdir -p "$GFA_9/d/e"; printf 'l\n' > "$GFA_9/d/e/x.gfalog"
is  "an extra exclusion reaches git as given, its pathspec magic included" \
    "$(_gfa_tid "$GFA_9" "" ':(exclude,glob)**/*.gfalog')" "$(_gfa_want "$_gfa_g0")"
_gfa_git -C "${GFA_G:?}" worktree remove --force "$GFA/gw" >/dev/null 2>&1
