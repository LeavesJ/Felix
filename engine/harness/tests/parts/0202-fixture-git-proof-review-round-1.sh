printf '\nfixture git proof: review round 1\n'
# Review round 1 of the fixture git proof (contract C13, amendments A1 to A6)
# found seven ways past it. These assertions were written blind, from the
# contract alone, and test what the amendments added:
# - A1: `remote -v` is a read only when nothing, `get-url` or `show` follows it.
# - A2: `builtin cd` and `command cd` are a cd, and `env`, `exec`, `time`,
#   `nice` and `nohup` do not hide the command after them.
# - A3: _fx_cd refuses a directory whose repository lives outside $TMP, and
#   the environment variables that point git elsewhere; _fx_git refuses the
#   global options that do the same.
# - A4: the origin guard watches every key that can redirect a remote, and the
#   upstreams, and not the keys sessions and the gh CLI change all day.
# - A5: a remote moved and put back within one run is still a red run.
# - A6: a run started inside a bare repository is watched.
#
# The rules the first blind block keeps hold here too:
# - Every probe that could write starts inside a stand-in under $TMP.
# - Stand-ins are built, and moved, by scripts written below and run as
#   children. Those shed the GIT_* variables that point git elsewhere and check
#   their target's physical path themselves, so no git write in this block
#   goes through the code under test.
# - A3 needs a repository outside $TMP. A child run supplies one: its $TMP is
#   a fresh directory of its own, so a stand-in under THIS run's $TMP is
#   outside the child's. Should _fx_cd or _fx_git fail open there, the damage
#   lands in that stand-in, where the assertion reads it.
# - Whether git ran is read from a shim on PATH that logs each call and then
#   runs the real git. C2 says _fx_git runs `command git`, which PATH finds; a
#   control shows the shim is seen.
_g2="$TMP/fixture-git-proof-r1"; mkdir -p "$_g2/lint" "$_g2/kid" "$_g2/shim" "$_g2/none"
_g2_phys() { [ -n "${1:-}" ] && [ -d "$1" ] && ( cd -P "$1" && pwd -P ); }
_g2_get()  { printf '%s\n' "$1" | sed -n "s/^$2 //p"; }
_g2_tmpp="$(_g2_phys "$TMP")"
_g2_src="$(_suite_flat)"
_g2_pre="$(grep -n "^printf '\\\\n" "$_g2_src" 2>/dev/null | head -1 | cut -d: -f1)"
_g2_rec0=0
[ -n "${FELIX_TEST_FXREFUSED:-}" ] && [ -f "$FELIX_TEST_FXREFUSED" ] \
  && _g2_rec0="$(wc -l < "$FELIX_TEST_FXREFUSED" | tr -d ' ')"

# ------------------------------------------------------------ A1 and A2 ----
# _fx_lint over synthetic files, as the first blind block does it: a line the
# lint must report holds a variable whose name starts S_, and no other line
# does, so the expected output is grep -n of those lines. N_ lines are ones
# it must pass over.
_g2_lint_is() {   # <name> <file> <status wanted>
  local o rc
  if ! declare -F _fx_lint >/dev/null 2>&1; then bad "$1" "_fx_lint is not defined"; return 0; fi
  o="$(_fx_lint "$2" 2>/dev/null)"; rc=$?
  is "$1" "$o|rc=$rc" "$(grep -nE '\$\{?S_' "$2")|rc=$3"
}
# A1. git 2.54 takes `remote -v add` and `remote --verbose remove` as the
# writes they name, and exits 0. Through a raw cd and through git -C.
cat > "$_g2/lint/a1-writes" <<'G2LINT'
( cd "$S_v_add" && git remote -v add o https://example.invalid/x.git )
( cd "$S_verbose_rm" && git remote --verbose remove origin )
( cd "$S_v_rm" && git remote -v remove origin )
( cd "$S_verbose_add" && git remote --verbose add o https://example.invalid/x.git )
( cd "$S_vv_add" && git remote -v -v add o https://example.invalid/x.git )
( cd "$S_v_seturl" && git remote -v set-url origin https://example.invalid/y.git )
( cd "$S_v_rename" && git remote -v rename origin upstream )
( cd "$S_v_prune" && git remote -v prune origin )
y="$(cd "$S_v_dollar" && git remote -v add o https://example.invalid/x.git)"
git -C "$S_c_v_add" remote -v add o https://example.invalid/x.git
git -C "$S_c_verbose_rm" remote --verbose remove origin
git -C "${S_c_v_rm}" remote -v remove origin
git -C "$S_c_verbose_add" remote --verbose add o https://example.invalid/x.git
command git -C "$S_c_cmd" remote -v add o https://example.invalid/x.git
git --no-pager -C "$S_c_glob" remote --verbose set-url origin https://example.invalid/y.git
G2LINT
cat > "$_g2/lint/a1-reads" <<'G2LINT'
( cd "$N_r" && git remote -v )
( cd "$N_r" && git remote --verbose )
( cd "$N_r" && git remote -v show origin )
( cd "$N_r" && git remote --verbose show origin )
( cd "$N_r" && git remote get-url origin )
( cd "$N_r" && git remote -v get-url origin )
( cd "$N_r" && git remote get-url --push origin )
( cd "$N_r" && git remote show -n origin )
x="$(cd "$N_r" && git remote -v)"
git -C "$N_r" remote -v
git -C "$N_r" remote --verbose
git -C "$N_r" remote -v show origin
git -C "$N_r" remote get-url origin
git -C "$N_r" remote --verbose get-url --push origin
command git -C "$N_r" remote -v
x="$(git -C "$N_r" remote -v)"
G2LINT
_g2_lint_is "_fx_lint reports remote -v add, remote --verbose remove and their kin as writes, after a raw cd and a raw git -C" "$_g2/lint/a1-writes" 1
_g2_lint_is "_fx_lint still passes over remote -v alone, remote -v show and remote get-url, after a raw cd and a raw git -C" "$_g2/lint/a1-reads" 0
# A2. builtin cd and command cd are a cd.
cat > "$_g2/lint/a2-cd" <<'G2LINT'
( builtin cd "$S_builtin" && git config k v )
( command cd "$S_command" && git remote add o https://example.invalid/x.git )
( builtin cd -- "$S_builtin_dd" && git config k v )
( command cd -P "$S_command_p" && git update-ref refs/x HEAD )
builtin cd "$S_builtin_line" && git config k v
if builtin cd "$S_builtin_if"; then git branch -D old; fi
y="$(command cd "$S_command_dollar" && git remote remove origin)"
( builtin cd "$S_builtin_multi"
  git remote add o https://example.invalid/x.git
)
G2LINT
# env, exec, time, nice and nohup before git, alone, chained, after a raw cd,
# and with the option, digit and NAME=value words the contract skips.
cat > "$_g2/lint/a2-prefix" <<'G2LINT'
env GIT_X=1 git -C "$S_env" commit -qm x
nice -n 5 git -C "$S_nice" commit -qm x
time git -C "$S_time" commit -qm x
exec git -C "$S_exec" commit -qm x
nohup git -C "$S_nohup" commit -qm x
env git -C "$S_env_bare" commit -qm x
env -i PATH=/usr/bin GIT_X=1 git -C "$S_env_i" commit -qm x
time -p git -C "$S_time_p" commit -qm x
nice -5 git -C "$S_nice_dash" commit -qm x
env GIT_X=1 nice -n 5 git -C "$S_chain" commit -qm x
nohup nice git -C "$S_chain2" remote add o https://example.invalid/x.git
x="$(nice -n 5 git -C "$S_nice_dollar" commit -qm x)"
if time git -C "$S_time_if" commit -qm x; then :; fi
( cd "$S_cd_env" && env GIT_X=1 git config k v )
( cd "$S_cd_nohup" && nohup git remote add o https://example.invalid/x.git )
( cd "$S_cd_nice" && nice -n 5 git branch -D old )
G2LINT
cat > "$_g2/lint/a2-reads" <<'G2LINT'
env GIT_X=1 git -C "$N_t" log -1
nice -n 5 git -C "$N_t" status --porcelain
time git -C "$N_t" rev-parse HEAD
exec git -C "$N_t" config --get remote.origin.url
nohup git -C "$N_t" show HEAD
env GIT_X=1 nice -n 5 git -C "$N_t" remote -v
( builtin cd "$N_t" && git log -1 )
( command cd "$N_t" && git status )
( builtin cd /literal/path && git config k v )
( command cd sub && git remote add o https://example.invalid/x.git )
( cd "$N_t" && env A=1 git rev-parse HEAD )
( cd "$N_t" && nohup git remote get-url origin )
echo env GIT_X=1 git -C "$N_t" commit -qm x
nohup echo git -C "$N_t" commit -qm x
( builtin cd "$N_t" && echo git config k v )
env GIT_X=1 _fx_git "$N_t" commit -qm x
G2LINT
_g2_lint_is "_fx_lint reports builtin cd and command cd on a variable before a git write" "$_g2/lint/a2-cd" 1
_g2_lint_is "_fx_lint sees git -C on a variable past env, exec, time, nice and nohup, and git after them past a raw cd" "$_g2/lint/a2-prefix" 1
_g2_lint_is "_fx_lint passes over the read forms of those shapes, and words that are not in command position" "$_g2/lint/a2-reads" 0

# -------------------------------------------------------- the stand-ins ----
# The builder. It refuses a target not physically under the bound it is
# given, sheds every GIT_* variable that points git elsewhere, and sets its own
# ceiling at the target's parent. Each stand-in has a committed file `f` whose
# content names the stand-in, a tracked sub/keep, an origin with a ref under
# refs/remotes/origin, a branch tracking origin, and a second commit kept at
# refs/g2/next, off refs/remotes. With "two", a second branch tracks origin.
cat > "$_g2/build.sh" <<'G2BUILD'
set -u
unset GIT_DIR GIT_WORK_TREE GIT_COMMON_DIR GIT_INDEX_FILE GIT_OBJECT_DIRECTORY GIT_ALTERNATE_OBJECT_DIRECTORIES GIT_CONFIG
[ -n "${1:-}" ] && [ -n "${2:-}" ] || exit 3
mkdir -p "$1" || exit 3
t="$(cd -P "$2" && pwd -P)" && d="$(cd -P "$1" && pwd -P)" || exit 3
case "$d" in "$t"/?*) ;; *) exit 4 ;; esac
GIT_CEILING_DIRECTORIES="${d%/*}"; export GIT_CEILING_DIRECTORIES
cd "$d" || exit 3
git init -q -b main . >/dev/null 2>&1 && [ -d "$d/.git" ] || exit 5
[ "$(git rev-parse --absolute-git-dir 2>/dev/null)" = "$d/.git" ] || exit 6
mkdir -p sub && printf 'content of %s\n' "$d" > f && : > sub/keep || exit 7
git add f sub/keep || exit 7
G="git -c user.name=t -c user.email=t@t -c commit.gpgsign=false"
$G commit -q --no-verify -m stand-in >/dev/null 2>&1 || exit 7
git remote add origin https://example.invalid/g2/stand-in.git || exit 8
git update-ref refs/remotes/origin/main HEAD || exit 8
git config branch.main.remote origin && git config branch.main.merge refs/heads/main || exit 8
n="$($G commit-tree -p HEAD -m next 'HEAD^{tree}')" && git update-ref refs/g2/next "$n" || exit 8
if [ "${3:-}" = two ]; then
  git branch b2 && git config branch.b2.remote origin && git config branch.b2.merge refs/heads/b2 || exit 8
fi
exit 0
G2BUILD
# A bare stand-in: a repository with no .git anywhere, holding an origin and a
# ref under refs/remotes/origin.
cat > "$_g2/bare.sh" <<'G2BUILD'
set -u
unset GIT_DIR GIT_WORK_TREE GIT_COMMON_DIR GIT_INDEX_FILE GIT_OBJECT_DIRECTORY GIT_ALTERNATE_OBJECT_DIRECTORIES GIT_CONFIG
[ -n "${1:-}" ] && [ -n "${2:-}" ] || exit 3
mkdir -p "$1" || exit 3
t="$(cd -P "$2" && pwd -P)" && d="$(cd -P "$1" && pwd -P)" || exit 3
case "$d" in "$t"/?*) ;; *) exit 4 ;; esac
GIT_CEILING_DIRECTORIES="${d%/*}"; export GIT_CEILING_DIRECTORIES
git init -q --bare "$d" >/dev/null 2>&1 || exit 5
B="git --git-dir=$d -c user.name=t -c user.email=t@t -c commit.gpgsign=false"
[ "$($B rev-parse --is-bare-repository 2>/dev/null)" = true ] || exit 6
tr="$($B mktree < /dev/null)" && c="$($B commit-tree -m bare "$tr")" || exit 7
$B update-ref refs/heads/main "$c" && $B update-ref refs/remotes/origin/main "$c" || exit 8
$B remote add origin https://example.invalid/g2/bare.git || exit 8
exit 0
G2BUILD
# Git on a stand-in's git dir, named outright, for setting up a case before a
# child starts. It refuses a git dir not physically under the bound.
cat > "$_g2/sgit.sh" <<'G2BUILD'
set -u
unset GIT_DIR GIT_WORK_TREE GIT_COMMON_DIR GIT_INDEX_FILE GIT_OBJECT_DIRECTORY GIT_ALTERNATE_OBJECT_DIRECTORIES GIT_CONFIG
[ -n "${1:-}" ] && [ -n "${2:-}" ] && [ -d "$1" ] || exit 3
t="$(cd -P "$2" && pwd -P)" && g="$(cd -P "$1" && pwd -P)" || exit 3
case "$g" in "$t"/?*) ;; *) exit 4 ;; esac
shift 2
git --git-dir="$g" "$@"
G2BUILD
# A real `git worktree add` of a stand-in, at a path whose parent exists.
cat > "$_g2/wtadd.sh" <<'G2BUILD'
set -u
unset GIT_DIR GIT_WORK_TREE GIT_COMMON_DIR GIT_INDEX_FILE GIT_OBJECT_DIRECTORY GIT_ALTERNATE_OBJECT_DIRECTORIES GIT_CONFIG
[ -n "${1:-}" ] && [ -n "${2:-}" ] && [ -n "${3:-}" ] || exit 3
t="$(cd -P "$3" && pwd -P)" && s="$(cd -P "$1" && pwd -P)" && p="$(cd -P "${2%/*}" && pwd -P)" || exit 3
case "$s" in "$t"/?*) ;; *) exit 4 ;; esac
case "$p/" in "$t"/?*) ;; *) exit 4 ;; esac
GIT_CEILING_DIRECTORIES="${s%/*}"; export GIT_CEILING_DIRECTORIES
cd "$s" || exit 3
git worktree add -q --detach "$p/${2##*/}" HEAD >/dev/null 2>&1
G2BUILD
_g2_build() { bash "$_g2/build.sh" "$1" "$TMP" "${2:-}" >/dev/null 2>&1; }
_g2_sgit()  { bash "$_g2/sgit.sh" "$1" "$TMP" "${@:2}" >/dev/null 2>&1; }
# The git shim: logs each call, then runs the real git.
_g2_realgit="$(command -v git)"
cat > "$_g2/shim/git" <<'G2SHIM'
#!/bin/sh
printf '%s\n' "$*" >> "${G2_SHIMLOG:-/dev/null}"
exec "${G2_REALGIT:-git-not-found}" "$@"
G2SHIM
chmod +x "$_g2/shim/git"

# -------------------------------------------------------- child runs ----
# As in the first blind block: the preamble cut at the line before its first
# section header, REAL_HARNESS set to a copy of the harness under test, then a
# body, and for some children the lines from C5 and C8's header to the line
# before the completion marker, then a tail that prints FAIL and exits 0. A
# child that moves a stand-in's remote does it through _g2k_git, which names
# the stand-in's git dir outright, after checking it sits physically under
# this run's $TMP.
#
# C7 compares mtimes in whole seconds, so a child sleeps a second before it
# changes anything.
_g2_hdr="printf '\\nthe run stayed inside its temporary directory\\n'"
_g2_mark="printf '\\nreached\\n'"
_g2_c8="the remotes of the checkout this run started in did not move while it ran"
_g2_cutx() {
  G2_H="$_g2_hdr" G2_M="$_g2_mark" awk 'BEGIN { h = ENVIRON["G2_H"]; m = ENVIRON["G2_M"] }
    $0 == h { on = 1 } on && $0 == m { exit } on { print }' "$_g2_src"
}
_g2_harness="$_g2/harness"; _copy_content "$REAL_HARNESS" "$_g2_harness"
cat > "$_g2/kid-lib.sh" <<'G2KID'
# fixture git proof, review round 1: what this child may touch, and nothing else
_g2k_ok() {
  [ -n "${G2_GITDIR:-}" ] && [ -n "${G2_TMPP:-}" ] && [ -d "$G2_GITDIR" ] || return 1
  case "$(cd -P "$G2_GITDIR" 2>/dev/null && pwd -P)/" in "$G2_TMPP"/?*) return 0 ;; esac
  return 1
}
_g2k_no() { printf 'no stand-in [%s]\n' "${G2_GITDIR:-}" >> "$G2_OUT/kid.err"; return 3; }
_g2k_git() {
  _g2k_ok || { _g2k_no; return 3; }
  ( unset GIT_DIR GIT_WORK_TREE GIT_COMMON_DIR GIT_INDEX_FILE GIT_OBJECT_DIRECTORY GIT_ALTERNATE_OBJECT_DIRECTORIES GIT_CONFIG
    git --git-dir="$G2_GITDIR" "$@" ) >/dev/null 2>&1
}
_g2k_file() {   # <path in the git dir> <content, printf %b>
  _g2k_ok || { _g2k_no; return 3; }
  printf '%b' "$2" > "$G2_GITDIR/$1"
}
_g2k_chmod() {   # <mode> <path in the git dir>
  _g2k_ok || { _g2k_no; return 3; }
  chmod "$1" "$G2_GITDIR/$2"
}
printf '%s\n' "$TMP" > "$G2_OUT/tmp"
G2KID
cat > "$_g2/kid-tail.sh" <<'G2KID'
printf 'g2-fail %s\n' "$FAIL"
exit 0
G2KID
_g2_kid() {   # <name> <cut: 0|1>, body on stdin
  local d="$_g2/kid/$1"; mkdir -p "$d"; cat > "$d/body.sh"
  { [ -n "$_g2_pre" ] && awk -v n="$_g2_pre" 'NR < n { print; if ($0 ~ /^REAL_HARNESS=/) print "REAL_HARNESS=\"$G2_HARNESS\"" }' "$_g2_src"
    cat "$_g2/kid-lib.sh" "$d/body.sh"
    if [ "$2" = 1 ]; then _g2_cutx; cat "$_g2/kid-tail.sh"; fi; } > "$d/run"
}
_g2_run() {   # <name> <start dir> [git dir it may touch]
  local d="$_g2/kid/$1"
  if [ -z "${2:-}" ] || [ ! -d "$2" ]; then printf 'not started' > "$d/err"; : > "$d/out"; printf 'x' > "$d/rc"; return 0; fi
  ( cd "$2" && G2_OUT="$d" G2_GITDIR="${3:-}" G2_TMPP="$_g2_tmpp" G2_HARNESS="$_g2_harness" \
      G2_REALGIT="$_g2_realgit" G2_SHIM="$_g2/shim" G2_BUILD="$_g2/build.sh" G2_WTADD="$_g2/wtadd.sh" \
      G2_OUTSIDE="${_g2_outp:-}" G2_OBJFILE="$_g2/objfile" \
      bash "$d/run" > "$d/out" 2> "$d/err"; printf '%s' "$?" > "$d/rc" )
}
_g2_rc()  { cat "$_g2/kid/$1/rc" 2>/dev/null; }
_g2_has() { grep -Fxq -- "$2" "$_g2/kid/$1/out" 2>/dev/null; }
_g2_err() { grep -c -- "^$2" "$_g2/kid/$1/err" 2>/dev/null | tr -d ' '; }
_g2_said() { grep -F -- "$_g2_c8" "$_g2/kid/$1/out" 2>/dev/null | tr '\n' ' '; }
_g2_detail() {
  G2_N="  FAIL  $2" awk 'f && (/^  (ok|FAIL|skip)  / || /^g2-fail /) { exit } f { print } $0 == ENVIRON["G2_N"] { f = 1 }' \
    "$_g2/kid/$1/out" 2>/dev/null
}
_g2_samedir() {   # <reported config path> <git dir>: the path is that git dir's config, physically
  [ "${1##*/}" = config ] && [ -n "$(_g2_phys "$2")" ] && [ "$(_g2_phys "${1%/*}")" = "$(_g2_phys "$2")" ]
}
# One A4 case: a stand-in, a child with C5 and C8 cut in, started in its sub
# directory, that makes the change on stdin between two assertions.
_g2_mut() {   # <kid> <stand-in>, change on stdin
  { printf 'ok "g2 child: an assertion before the change"\nsleep 1\n'; cat
    printf '%s\n' 'ok "g2 child: an assertion after the change"' \
      '[ -e "$TMP/origin-moved" ] && cp "$TMP/origin-moved" "$G2_OUT/origin-moved"' 'true'; } | _g2_kid "$1" 1
  _g2_run "$1" "$2/sub" "$2/.git"
}
_g2_c8is() {   # <kid> <FAIL|ok> <name> <exercised: 1|0> <what did not happen>
  if [ "$4" != 1 ]; then
    bad "$3" "not exercised: $5 [$(cat "$_g2/kid/$1/kid.err" 2>/dev/null)]"
  elif [ "$2" = FAIL ]; then
    if _g2_has "$1" "  FAIL  $_g2_c8"; then ok "$3"
    else bad "$3" "status [$(_g2_rc "$1")]; C8 said: $(_g2_said "$1")stderr: $(head -3 "$_g2/kid/$1/err" 2>/dev/null | tr '\n' ' ')"; fi
  else
    if _g2_has "$1" "  ok    $_g2_c8" && [ ! -e "$_g2/kid/$1/origin-moved" ]; then ok "$3"
    else bad "$3" "C8 said: $(_g2_said "$1")detail: $(_g2_detail "$1" "$_g2_c8" | tr '\n' ' ')C7 record: $(tr '\t\n' '| ' 2>/dev/null < "$_g2/kid/$1/origin-moved")"; fi
  fi
}
# Config reads on a stand-in, each spelled as the read it is.
_g2_cfg()    { git -C "$1" config --get "$2" 2>/dev/null; }
_g2_cfgre()  { git -C "$1" config --get-regexp "$2" 2>/dev/null; }
_g2_cfgall() { git -C "$1" config --get-all "$2" 2>/dev/null; }
_g2_cfginc() { git --git-dir="$1/.git" config --includes --get "$2" 2>/dev/null; }

# -------------------------------------------------------------------- A3 ----
# The outside repository, under this run's $TMP and so outside the child's.
_g2_out="$_g2/outside"; _g2_build "$_g2_out"; _g2_outp="$(_g2_phys "$_g2_out")"
printf 'g2 object probe %s\n' "$_g2_tmpp" > "$_g2/objfile"
_g2_kid fx 0 <<'G2KID'
_g2k_in="$TMP/g2-in"; _g2k_in2="$TMP/g2-in2"
for _g2k_d in "$_g2k_in" "$_g2k_in2" "$TMP/g2-wtbase"; do
  bash "$G2_BUILD" "$_g2k_d" "$TMP" >/dev/null 2>&1 || printf 'build %s: %s\n' "$_g2k_d" "$?" >> "$G2_OUT/kid.err"
done
mkdir -p "$TMP/g2-wts"
bash "$G2_WTADD" "$TMP/g2-wtbase" "$TMP/g2-wts/wt" "$TMP" || printf 'worktree add: %s\n' "$?" >> "$G2_OUT/kid.err"
# Four ways for a directory under this child's $TMP to belong to the outside
# repository: a .git file, a .git symlink, a directory below a .git file, and
# a .git file whose gitdir: line is relative.
mkdir -p "$TMP/g2-gf" "$TMP/g2-gl" "$TMP/g2-gb/deep/er" "$TMP/g2-gr"
printf 'gitdir: %s\n' "$G2_OUTSIDE/.git" > "$TMP/g2-gf/.git"
ln -s "$G2_OUTSIDE/.git" "$TMP/g2-gl/.git"
printf 'gitdir: %s\n' "$G2_OUTSIDE/.git" > "$TMP/g2-gb/.git"
_g2k_p="$(cd -P "$TMP/g2-gr" && pwd -P)"; _g2k_up=""; _g2k_r="$_g2k_p"
while [ -n "$_g2k_r" ]; do _g2k_up="../$_g2k_up"; _g2k_r="${_g2k_r%/*}"; done
printf 'gitdir: %s\n' "${_g2k_up}${G2_OUTSIDE#/}/.git" > "$TMP/g2-gr/.git"
printf 'insub %s\nwt %s\nrel %s\n' "$(cd -P "$_g2k_in/sub" && pwd -P)" "$(cd -P "$TMP/g2-wts/wt" 2>/dev/null && pwd -P)" \
  "$(cd -P "$TMP/g2-gr" && git rev-parse --absolute-git-dir 2>/dev/null)" > "$G2_OUT/paths"
# What reads of the outside repository show. Run with none of the probe's
# variables set.
_g2k_state() {
  local g="$G2_OUTSIDE/.git"
  printf 'config %s\n' "$(git --git-dir="$g" config --file "$g/config" --list 2>&1 | tr '\n' ' ')"
  printf 'refs %s\n' "$(git --git-dir="$g" for-each-ref 2>&1 | tr '\n' ' ')"
  printf 'index %s\n' "$(cksum < "$g/index" 2>&1)"
  printf 'objects %s\n' "$(find "$g/objects" -type f 2>/dev/null | wc -l | tr -d ' ')"
  printf 'f %s\n' "$(cat "$G2_OUTSIDE/f" 2>&1)"
  printf 'worktrees %s\n' "$(ls "$g/worktrees" 2>/dev/null | tr '\n' ' ')"
}
# The shim is seen: git through it logs once.
( PATH="$G2_SHIM:$PATH"; G2_SHIMLOG="$G2_OUT/shimctl"; export G2_SHIMLOG G2_REALGIT; git --version >/dev/null 2>&1 )
_g2k_cd() {   # <case> <dir> <NAME=value or ->: _fx_cd from inside the stand-in
  : > "$G2_OUT/$1.cdrec"
  ( cd "$_g2k_in/sub" || exit 0
    [ "$3" != - ] && export "$3"
    FELIX_TEST_FXREFUSED="$G2_OUT/$1.cdrec"
    _fx_cd "$2" >/dev/null 2>&1; printf 'rc %s\n' "$?"; printf 'pwd %s\n' "$(pwd -P)" ) > "$G2_OUT/$1.cd" 2>/dev/null
}
_g2k_gitp() {   # <case> <dir> <NAME=value or -> <git args...>: _fx_git from inside the stand-in
  local c="$1" d="$2" e="$3"; shift 3
  : > "$G2_OUT/$c.rec"; : > "$G2_OUT/$c.shim"
  _g2k_state > "$G2_OUT/$c.before"
  ( cd "$_g2k_in/sub" || exit 0
    [ "$e" != - ] && export "$e"
    PATH="$G2_SHIM:$PATH"; G2_SHIMLOG="$G2_OUT/$c.shim"; export G2_SHIMLOG G2_REALGIT
    FELIX_TEST_FXREFUSED="$G2_OUT/$c.rec"
    _fx_git "$d" "$@" > "$G2_OUT/$c.stdout" 2>/dev/null; printf '%s' "$?" > "$G2_OUT/$c.rc" )
  _g2k_state > "$G2_OUT/$c.after"
}
_g2k_cd   env-index   "$_g2k_in" "GIT_INDEX_FILE=$G2_OUTSIDE/.git/index"
_g2k_gitp env-index   "$_g2k_in" "GIT_INDEX_FILE=$G2_OUTSIDE/.git/index" read-tree --empty
_g2k_cd   env-objects "$_g2k_in" "GIT_OBJECT_DIRECTORY=$G2_OUTSIDE/.git/objects"
_g2k_gitp env-objects "$_g2k_in" "GIT_OBJECT_DIRECTORY=$G2_OUTSIDE/.git/objects" hash-object -w "$G2_OBJFILE"
_g2k_cd   env-alt     "$_g2k_in" "GIT_ALTERNATE_OBJECT_DIRECTORIES=$G2_OUTSIDE/.git/objects"
_g2k_gitp env-alt     "$_g2k_in" "GIT_ALTERNATE_OBJECT_DIRECTORIES=$G2_OUTSIDE/.git/objects" config g2.alt ran
_g2k_cd   env-config  "$_g2k_in" "GIT_CONFIG=$G2_OUTSIDE/.git/config"
_g2k_gitp env-config  "$_g2k_in" "GIT_CONFIG=$G2_OUTSIDE/.git/config" config g2.envconfig ran
_g2k_cd   gd-file  "$TMP/g2-gf" -
_g2k_gitp gd-file  "$TMP/g2-gf" - remote add g2x-file https://example.invalid/g2/x.git
_g2k_cd   gd-link  "$TMP/g2-gl" -
_g2k_gitp gd-link  "$TMP/g2-gl" - remote add g2x-link https://example.invalid/g2/x.git
_g2k_cd   gd-below "$TMP/g2-gb/deep/er" -
_g2k_gitp gd-below "$TMP/g2-gb/deep/er" - remote add g2x-below https://example.invalid/g2/x.git
_g2k_cd   gd-rel   "$TMP/g2-gr" -
_g2k_gitp gd-rel   "$TMP/g2-gr" - remote add g2x-rel https://example.invalid/g2/x.git
_g2k_cd   wt-ok    "$TMP/g2-wts/wt" -
_g2k_gitp wt-ok    "$TMP/g2-wts/wt" - rev-parse --show-toplevel
_g2k_cd   wt-below "$TMP/g2-wts/wt/sub" -
_g2k_gitp wt-below "$TMP/g2-wts/wt/sub" - rev-parse --show-prefix
_g2k_gitp ga-dashC "$_g2k_in" - -C "$G2_OUTSIDE" remote add g2x-ga-c https://example.invalid/g2/x.git
_g2k_gitp ga-gd    "$_g2k_in" - --git-dir "$G2_OUTSIDE/.git" remote add g2x-ga-gd https://example.invalid/g2/x.git
_g2k_gitp ga-gdeq  "$_g2k_in" - "--git-dir=$G2_OUTSIDE/.git" remote add g2x-ga-gdeq https://example.invalid/g2/x.git
_g2k_gitp ga-wt    "$_g2k_in" - --work-tree "$G2_OUTSIDE" checkout HEAD -- f
_g2k_gitp ga-wteq  "$_g2k_in2" - "--work-tree=$G2_OUTSIDE" checkout HEAD -- f
_g2k_gitp ga-conf  "$_g2k_in" - -c g2.probe=allowed config --get g2.probe
_g2k_gitp ga-after "$_g2k_in" - log -1 -C --format=%s
true
G2KID
_g2_run fx "$_g2/none"
_g2_fx="$_g2/kid/fx"
_g2_ct="$(cat "$_g2_fx/tmp" 2>/dev/null)"
_g2_o="$(cat "$_g2_fx/paths" 2>/dev/null)"
_g2_insub="$(_g2_get "$_g2_o" insub)"; _g2_wtp="$(_g2_get "$_g2_o" wt)"
_g2_shimok=0; [ "$(wc -l < "$_g2_fx/shimctl" 2>/dev/null | tr -d ' ')" = 1 ] && _g2_shimok=1
# Controls on the fixture. They pass on any suite: the shim sees git, the
# relative gitdir: line does resolve to the outside repository, and the
# worktree was made.
if [ "$_g2_shimok" = 1 ] && [ -n "$_g2_ct" ] && [ -n "$_g2_insub" ]; then
  ok  "fixture git proof r1: the child built its stand-ins, and a git shim on PATH logs each git it runs"
else
  bad "fixture git proof r1: the child built its stand-ins, and a git shim on PATH logs each git it runs" \
      "shim log [$(cat "$_g2_fx/shimctl" 2>/dev/null)]; child TMP [$_g2_ct]; paths [$(tr '\n' ' ' < "$_g2_fx/paths" 2>/dev/null)]; kid.err [$(cat "$_g2_fx/kid.err" 2>/dev/null)]; stderr: $(head -3 "$_g2_fx/err" | tr '\n' ' ')"
fi
is "fixture git proof r1: the relative gitdir: line resolves to the outside repository" "$(_g2_get "$_g2_o" rel)" "$_g2_outp/.git"
_g2_rcd() {   # <case> <what> <dir as given> <reason>
  local n="_fx_cd refuses $2 with reason $4, and its caller stays where it stood" o rc pwd rec
  o="$(cat "$_g2_fx/$1.cd" 2>/dev/null)"; rc="$(_g2_get "$o" rc)"; pwd="$(_g2_get "$o" pwd)"
  rec="$(cut -f2- "$_g2_fx/$1.cdrec" 2>/dev/null)|$(wc -l < "$_g2_fx/$1.cdrec" 2>/dev/null | tr -d ' ')"
  if [ -z "$o" ]; then bad "$n" "the child did not reach this probe; stderr: $(head -3 "$_g2_fx/err" | tr '\n' ' ')"
  elif [ -n "$rc" ] && [ "$rc" != 0 ] && [ -n "$_g2_insub" ] && [ "$pwd" = "$_g2_insub" ] \
       && [ "$rec" = "$(printf '%s\t%s|1' "$3" "$4")" ]; then ok "$n"
  else bad "$n" "it returned [$rc], its caller stood in [$pwd] not [$_g2_insub], and the record reads [$(tr '\t\n' '| ' < "$_g2_fx/$1.cdrec" 2>/dev/null)]"
  fi
}
_g2_rgit() {   # <case> <name> <dir as given> <reason>
  local n="$2" rc sh rec
  rc="$(cat "$_g2_fx/$1.rc" 2>/dev/null)"; sh="$(wc -l < "$_g2_fx/$1.shim" 2>/dev/null | tr -d ' ')"
  rec="$(cut -f2- "$_g2_fx/$1.rec" 2>/dev/null)|$(wc -l < "$_g2_fx/$1.rec" 2>/dev/null | tr -d ' ')"
  if [ "$_g2_shimok" != 1 ]; then bad "$n" "not exercised: the git shim logged nothing even for a git it ran"
  elif ! grep -q '^config .*remote\.origin\.url=' "$_g2_fx/$1.before" 2>/dev/null; then
    bad "$n" "not exercised: the outside repository could not be read before the probe [$(head -1 "$_g2_fx/$1.before" 2>/dev/null)]"
  elif [ -n "$rc" ] && [ "$rc" != 0 ] && [ "$sh" = 0 ] && cmp -s "$_g2_fx/$1.before" "$_g2_fx/$1.after" \
       && [ "$rec" = "$(printf '%s\t%s|1' "$3" "$4")" ]; then ok "$n"
  else
    bad "$n" "it returned [$rc]; git ran [$sh] times [$(tr '\n' ';' < "$_g2_fx/$1.shim" 2>/dev/null)]; the outside repository changed: $(diff "$_g2_fx/$1.before" "$_g2_fx/$1.after" 2>&1 | grep '^[<>]' | tr '\n' ' ')record [$(tr '\t\n' '| ' < "$_g2_fx/$1.rec" 2>/dev/null)]"
  fi
}
for _g2_v in GIT_INDEX_FILE:env-index GIT_OBJECT_DIRECTORY:env-objects GIT_ALTERNATE_OBJECT_DIRECTORIES:env-alt GIT_CONFIG:env-config; do
  _g2_rcd  "${_g2_v#*:}" "a stand-in under \$TMP while ${_g2_v%%:*} names the outside repository" "$_g2_ct/g2-in" git-env
  _g2_rgit "${_g2_v#*:}" "_fx_git with ${_g2_v%%:*} set refuses with git-env; git never runs and the outside repository reads as it was" "$_g2_ct/g2-in" git-env
done
_g2_rcd  gd-file  "a directory whose .git file points outside \$TMP" "$_g2_ct/g2-gf" gitdir-outside
_g2_rgit gd-file  "_fx_git on a directory whose .git file points outside \$TMP refuses; git never runs and the outside repository reads as it was" "$_g2_ct/g2-gf" gitdir-outside
_g2_rcd  gd-link  "a directory whose .git is a symlink outside \$TMP" "$_g2_ct/g2-gl" gitdir-outside
_g2_rgit gd-link  "_fx_git on a directory whose .git is a symlink outside \$TMP refuses; git never runs and the outside repository reads as it was" "$_g2_ct/g2-gl" gitdir-outside
_g2_rcd  gd-below "a directory with no .git, below a checkout whose .git file points outside \$TMP" "$_g2_ct/g2-gb/deep/er" gitdir-outside
_g2_rgit gd-below "_fx_git below a checkout whose .git file points outside \$TMP refuses; git never runs and the outside repository reads as it was" "$_g2_ct/g2-gb/deep/er" gitdir-outside
_g2_rcd  gd-rel   "a directory whose .git file has a relative gitdir: line resolving outside \$TMP" "$_g2_ct/g2-gr" gitdir-outside
_g2_rgit gd-rel   "_fx_git on a directory whose relative gitdir: line resolves outside \$TMP refuses; git never runs and the outside repository reads as it was" "$_g2_ct/g2-gr" gitdir-outside
_g2_rgit ga-dashC "_fx_git refuses -C before the subcommand with git-args; git never runs and the outside repository reads as it was" "$_g2_ct/g2-in" git-args
_g2_rgit ga-gd    "_fx_git refuses --git-dir before the subcommand with git-args; git never runs and the outside repository reads as it was" "$_g2_ct/g2-in" git-args
_g2_rgit ga-gdeq  "_fx_git refuses --git-dir= before the subcommand with git-args; git never runs and the outside repository reads as it was" "$_g2_ct/g2-in" git-args
_g2_rgit ga-wt    "_fx_git refuses --work-tree before the subcommand with git-args; git never runs and the outside work tree reads as it was" "$_g2_ct/g2-in" git-args
_g2_rgit ga-wteq  "_fx_git refuses --work-tree= before the subcommand with git-args; git never runs and the outside work tree reads as it was" "$_g2_ct/g2-in2" git-args
# What A3 leaves allowed. A worktree made by `git worktree add` has a .git
# file too, but it points inside $TMP. -c k=v stays allowed, and so does a -C
# after the subcommand, which is that subcommand's own option.
_g2_allow() {   # <case> <name> <stdout wanted>
  local o="$_g2_fx/$1"
  if [ "$_g2_shimok" != 1 ]; then bad "$2" "not exercised: the git shim logged nothing even for a git it ran"
  else is "$2" "$(cat "$o.rc" 2>/dev/null)|$(cat "$o.stdout" 2>/dev/null)|$(wc -l < "$o.shim" 2>/dev/null | tr -d ' ')|$(tr '\t\n' '| ' < "$o.rec" 2>/dev/null)" "0|$3|1|"
  fi
}
if [ -z "$_g2_wtp" ]; then
  _g2_x="not exercised: git worktree add made no worktree [$(cat "$_g2_fx/kid.err" 2>/dev/null)]"
  bad "_fx_cd on a git worktree of a stand-in inside \$TMP succeeds and stands there, recording nothing" "$_g2_x"
  bad "_fx_git in a git worktree of a stand-in inside \$TMP runs git once, there, recording nothing" "$_g2_x"
  bad "_fx_git below a git worktree of a stand-in inside \$TMP runs git once, there, recording nothing" "$_g2_x"
else
  is "_fx_cd on a git worktree of a stand-in inside \$TMP succeeds and stands there, recording nothing" \
     "$(_g2_get "$(cat "$_g2_fx/wt-ok.cd" 2>/dev/null)" rc)|$(_g2_get "$(cat "$_g2_fx/wt-ok.cd" 2>/dev/null)" pwd)|$(tr '\t\n' '| ' < "$_g2_fx/wt-ok.cdrec" 2>/dev/null)" \
     "0|$_g2_wtp|"
  _g2_allow wt-ok "_fx_git in a git worktree of a stand-in inside \$TMP runs git once, there, recording nothing" "$_g2_wtp"
  _g2_allow wt-below "_fx_git below a git worktree of a stand-in inside \$TMP runs git once, there, recording nothing" "sub/"
fi
_g2_allow ga-conf "_fx_git allows -c k=v before the subcommand: git runs once and sees the value" "allowed"
_g2_allow ga-after "_fx_git allows -C after the subcommand, where it is the subcommand's own option" "stand-in"

# -------------------------------------------------------------------- A4 ----
# What the guard reads as moved. Each case is checked to have happened before
# its verdict counts.
_g2_s="$_g2/st-insteadof"; _g2_build "$_g2_s"
_g2_mut insteadof "$_g2_s" <<'G2KID'
_g2k_git config url.https://example.invalid/g2/elsewhere/.insteadOf https://example.invalid/g2/
G2KID
_g2_x=0; [ -n "$(_g2_cfgre "$_g2_s" '^url\..*\.insteadof$')" ] && _g2_x=1
_g2_c8is insteadof FAIL "the origin check reads a url.<base>.insteadOf added during the run as moved" "$_g2_x" "no insteadOf was added"

_g2_s="$_g2/st-pushinsteadof"; _g2_build "$_g2_s"
_g2_mut pushinsteadof "$_g2_s" <<'G2KID'
_g2k_git config url.https://example.invalid/g2/elsewhere/.pushInsteadOf https://example.invalid/g2/
G2KID
_g2_x=0; [ -n "$(_g2_cfgre "$_g2_s" '^url\..*\.pushinsteadof$')" ] && _g2_x=1
_g2_c8is pushinsteadof FAIL "the origin check reads a url.<base>.pushInsteadOf added during the run as moved" "$_g2_x" "no pushInsteadOf was added"

_g2_s="$_g2/st-include"; _g2_build "$_g2_s"
printf '[remote "origin"]\n\tpushurl = https://example.invalid/g2/included.git\n' > "$_g2_s/.git/g2-inc"
_g2_mut include "$_g2_s" <<'G2KID'
_g2k_git config include.path g2-inc
G2KID
_g2_x=0; [ "$(_g2_cfginc "$_g2_s" remote.origin.pushurl)" = https://example.invalid/g2/included.git ] && _g2_x=1
_g2_c8is include FAIL "the origin check reads an include.path added during the run, whose file sets a remote pushurl, as moved" "$_g2_x" "the include was not added"
# The include was there from the start, and only what it supplies changed.
# A config write to a key the guard does not watch makes the config newer,
# so the guard re-reads it; only a read that follows the include sees a move.
_g2_s="$_g2/st-include-pre"; _g2_build "$_g2_s"
printf '[g2]\n\tinc = 1\n' > "$_g2_s/.git/g2-inc"; _g2_sgit "$_g2_s/.git" config include.path g2-inc
_g2_mut include-pre "$_g2_s" <<'G2KID'
_g2k_file g2-inc '[g2]\n\tinc = 1\n[remote "origin"]\n\tpushurl = https://example.invalid/g2/included.git\n'
_g2k_git config g2.touch 1
G2KID
_g2_x=0; [ "$(_g2_cfginc "$_g2_s" remote.origin.pushurl)" = https://example.invalid/g2/included.git ] \
  && [ "$(_g2_cfg "$_g2_s" include.path)" = g2-inc ] && _g2_x=1
_g2_c8is include-pre FAIL "the origin check follows an include present from the start: a pushurl the included file gains is a move" "$_g2_x" "the included file did not gain the pushurl"

_g2_s="$_g2/st-wtconfig"; _g2_build "$_g2_s"
_g2_mut wtconfig "$_g2_s" <<'G2KID'
_g2k_file config.worktree '[remote "origin"]\n\tpushurl = https://example.invalid/g2/worktree.git\n'
_g2k_git config core.repositoryformatversion 1
_g2k_git config extensions.worktreeConfig true
G2KID
_g2_x=0; [ "$(_g2_cfg "$_g2_s" extensions.worktreeconfig)" = true ] && [ -s "$_g2_s/.git/config.worktree" ] && _g2_x=1
_g2_c8is wtconfig FAIL "the origin check reads extensions.worktreeConfig turned on during the run, with config.worktree setting a pushurl, as moved" "$_g2_x" "worktreeConfig was not turned on"
# worktreeConfig on from the start: config.worktree is watched in its own
# right, and gaining a pushurl there is a move though the common config is
# untouched.
_g2_s="$_g2/st-wtconfig-pre"; _g2_build "$_g2_s"
_g2_sgit "$_g2_s/.git" config core.repositoryformatversion 1
_g2_sgit "$_g2_s/.git" config extensions.worktreeConfig true
printf '[g2]\n\twt = 1\n' > "$_g2_s/.git/config.worktree"
_g2_mut wtconfig-pre "$_g2_s" <<'G2KID'
_g2k_file config.worktree '[g2]\n\twt = 1\n[remote "origin"]\n\tpushurl = https://example.invalid/g2/worktree.git\n'
G2KID
_g2_x=0; [ "$(_g2_cfg "$_g2_s" extensions.worktreeconfig)" = true ] \
  && [ "$(git config --file "$_g2_s/.git/config.worktree" --get remote.origin.pushurl 2>/dev/null)" = https://example.invalid/g2/worktree.git ] && _g2_x=1
_g2_c8is wtconfig-pre FAIL "with worktreeConfig on from the start, a pushurl config.worktree gains during the run is a move" "$_g2_x" "config.worktree did not gain the pushurl"

_g2_s="$_g2/st-fetch"; _g2_build "$_g2_s"
_g2_mut fetch "$_g2_s" <<'G2KID'
_g2k_git config remote.origin.fetch +refs/heads/main:refs/remotes/origin/g2-elsewhere
G2KID
_g2_x=0; [ "$(_g2_cfgall "$_g2_s" remote.origin.fetch)" = +refs/heads/main:refs/remotes/origin/g2-elsewhere ] && _g2_x=1
_g2_c8is fetch FAIL "the origin check reads a remote's fetch refspec changed during the run as moved" "$_g2_x" "the refspec did not change"

_g2_s="$_g2/st-push"; _g2_build "$_g2_s"
_g2_mut push "$_g2_s" <<'G2KID'
_g2k_git config remote.origin.push refs/heads/main:refs/heads/g2-elsewhere
G2KID
_g2_x=0; [ "$(_g2_cfg "$_g2_s" remote.origin.push)" = refs/heads/main:refs/heads/g2-elsewhere ] && _g2_x=1
_g2_c8is push FAIL "the origin check reads a remote.<name>.push added during the run as moved" "$_g2_x" "no push refspec was added"

_g2_s="$_g2/st-upstream"; _g2_build "$_g2_s"
_g2_mut upstream "$_g2_s" <<'G2KID'
_g2k_git config --unset branch.main.remote
G2KID
_g2_x=0; [ -z "$(_g2_cfgre "$_g2_s" '^branch\..*\.remote$')" ] \
  && [ -n "$(git -C "$_g2_s" for-each-ref refs/remotes/origin 2>/dev/null)" ] \
  && [ "$(_g2_cfg "$_g2_s" remote.origin.url)" = https://example.invalid/g2/stand-in.git ] && _g2_x=1
_g2_c8is upstream FAIL "the origin check reads a remote no branch tracks any more, its url and refs as they were, as moved" "$_g2_x" "the upstream was not removed, or more than it changed"

_g2_s="$_g2/st-refs000"; _g2_build "$_g2_s"
if [ "$(id -u)" = 0 ]; then
  skip "the origin check reads a refs/remotes directory made unreadable during the run as moved, not as no refs" "root reads a mode-000 directory"
elif [ ! -d "$_g2_s/.git/refs/remotes/origin" ]; then
  bad "the origin check reads a refs/remotes directory made unreadable during the run as moved, not as no refs" \
      "not exercised: this git keeps no refs/remotes directory"
else
  _g2_mut refs000 "$_g2_s" <<'G2KID'
_g2k_chmod 000 refs/remotes
_g2k_git config g2.touch 1
G2KID
  _g2_x=0; [ ! -r "$_g2_s/.git/refs/remotes" ] && _g2_x=1
  chmod 755 "$_g2_s/.git/refs/remotes" 2>/dev/null
  _g2_c8is refs000 FAIL "the origin check reads a refs/remotes directory made unreadable during the run as moved, not as no refs" "$_g2_x" "refs/remotes stayed readable"
fi

# The same directory unreadable from the start. Read as "no refs", the
# snapshot would hold a remote with none, and nothing after could read as a
# move; A4 has the snapshot mark it unreadable instead, which fails C8.
_g2_s="$_g2/st-refs000-pre"; _g2_build "$_g2_s"
_g2_n="a refs/remotes directory unreadable from the start fails the origin check, rather than reading as a remote with no refs"
if [ "$(id -u)" = 0 ]; then
  skip "$_g2_n" "root reads a mode-000 directory"
elif [ ! -d "$_g2_s/.git/refs/remotes/origin" ]; then
  bad "$_g2_n" "not exercised: this git keeps no refs/remotes directory"
else
  chmod 000 "$_g2_s/.git/refs/remotes"
  _g2_kid refs000pre 1 <<'G2KID'
ok "g2 child: an assertion in a run whose remote refs cannot be read"
true
G2KID
  _g2_run refs000pre "$_g2_s/sub" "$_g2_s/.git"
  chmod 755 "$_g2_s/.git/refs/remotes" 2>/dev/null
  if _g2_has refs000pre "  FAIL  $_g2_c8"; then ok "$_g2_n"
  else bad "$_g2_n" "status [$(_g2_rc refs000pre)]; C8 said: $(_g2_said refs000pre)stderr: $(head -3 "$_g2/kid/refs000pre/err" | tr '\n' ' ')"; fi
fi

# What the guard reads as not moved. Each change also makes the config newer
# where it would not already, so the guard re-reads before it decides.
_g2_s="$_g2/st-oneof2"; _g2_build "$_g2_s" two
_g2_mut oneof2 "$_g2_s" <<'G2KID'
_g2k_git config --unset branch.b2.remote
G2KID
_g2_x=0; [ "$(_g2_cfg "$_g2_s" branch.main.remote)" = origin ] && [ -z "$(_g2_cfg "$_g2_s" branch.b2.remote)" ] && _g2_x=1
_g2_c8is oneof2 ok "one branch's upstream removed while another still tracks the remote is not a move" "$_g2_x" "b2's upstream was not removed"

_g2_s="$_g2/st-ghres"; _g2_build "$_g2_s"
_g2_mut ghres "$_g2_s" <<'G2KID'
_g2k_git config remote.origin.gh-resolved base
G2KID
_g2_x=0; [ "$(_g2_cfg "$_g2_s" remote.origin.gh-resolved)" = base ] && _g2_x=1
_g2_c8is ghres ok "remote.origin.gh-resolved added during the run is not a move" "$_g2_x" "gh-resolved was not added"

_g2_s="$_g2/st-merge"; _g2_build "$_g2_s"
_g2_mut merge "$_g2_s" <<'G2KID'
_g2k_git config branch.g2new.merge refs/heads/g2new
G2KID
_g2_x=0; [ "$(_g2_cfg "$_g2_s" branch.g2new.merge)" = refs/heads/g2new ] && _g2_x=1
_g2_c8is merge ok "a new branch.<b>.merge added during the run is not a move" "$_g2_x" "the merge entry was not added"

_g2_s="$_g2/st-gain"; _g2_build "$_g2_s"
_g2_mut gain "$_g2_s" <<'G2KID'
_g2k_git update-ref refs/remotes/origin/g2-gained HEAD
_g2k_git config g2.touch 1
G2KID
_g2_x=0; [ -n "$(git -C "$_g2_s" for-each-ref refs/remotes/origin/g2-gained 2>/dev/null)" ] && _g2_x=1
_g2_c8is gain ok "a remote that gained a ref during the run has not moved" "$_g2_x" "no ref was gained"

_g2_s="$_g2/st-refval"; _g2_build "$_g2_s"
_g2_mut refval "$_g2_s" <<'G2KID'
_g2k_git update-ref refs/remotes/origin/main refs/g2/next
_g2k_git config g2.touch 1
G2KID
_g2_x=0; [ -n "$(git -C "$_g2_s" rev-parse -q --verify refs/g2/next 2>/dev/null)" ] \
  && [ "$(git -C "$_g2_s" rev-parse -q --verify refs/remotes/origin/main 2>/dev/null)" = "$(git -C "$_g2_s" rev-parse -q --verify refs/g2/next 2>/dev/null)" ] && _g2_x=1
_g2_c8is refval ok "a remote ref whose value changed during the run has not moved" "$_g2_x" "the ref did not move"

# -------------------------------------------------------------------- A5 ----
# The remote moves, an assertion is recorded, and the remote is put back. The
# end state equals the snapshot; the run is red all the same.
cat > "$_g2/back.sh" <<'G2KID'
ok "g2 child: an assertion before the remote moves"
sleep 1
_g2k_git remote set-url origin https://example.invalid/g2/moved.git
ok "g2 child: an assertion after the remote moves"
git --git-dir="$G2_GITDIR" config --get remote.origin.url > "$G2_OUT/mid" 2>/dev/null
sleep 1
_g2k_git remote set-url origin https://example.invalid/g2/stand-in.git
ok "g2 child: an assertion after the remote is put back"
true
G2KID
_g2_back() {   # <kid> <cut> <stand-in>: exercised 1 or 0
  _g2_kid "$1" "$2" < "$_g2/back.sh"; _g2_run "$1" "$3/sub" "$3/.git"
  if [ "$(cat "$_g2/kid/$1/mid" 2>/dev/null)" = https://example.invalid/g2/moved.git ] \
     && [ "$(_g2_cfg "$3" remote.origin.url)" = https://example.invalid/g2/stand-in.git ]; then printf 1; else printf 0; fi
}
_g2_s="$_g2/st-back"; _g2_build "$_g2_s"
_g2_x="$(_g2_back back 1 "$_g2_s")"
_g2_n="a remote moved and put back within one run fails the origin check, naming the config"
if [ "$_g2_x" != 1 ]; then bad "$_g2_n" "not exercised: the remote did not move and come back [$(cat "$_g2/kid/back/kid.err" 2>/dev/null)]"
elif _g2_has back "  FAIL  $_g2_c8" && case "$(_g2_detail back "$_g2_c8")" in *st-back/.git/config*) true ;; *) false ;; esac; then ok "$_g2_n"
else bad "$_g2_n" "C8 said: $(_g2_said back)detail: $(_g2_detail back "$_g2_c8" | tr '\n' ' ')"
fi
_g2_s="$_g2/st-backrun"; _g2_build "$_g2_s"
_g2_x="$(_g2_back backrun 0 "$_g2_s")"
_g2_n="a section runner whose remote moved and was put back exits 1, its trap naming the config"
_g2_y="$(grep '^tests/run: remotes moved while this run ran: ' "$_g2/kid/backrun/err" 2>/dev/null | head -1)"
if [ "$_g2_x" != 1 ]; then bad "$_g2_n" "not exercised: the remote did not move and come back [$(cat "$_g2/kid/backrun/kid.err" 2>/dev/null)]"
elif [ "$(_g2_rc backrun)" = 1 ] && [ "$(_g2_err backrun 'tests/run: remotes moved while this run ran: ')" = 1 ] \
     && _g2_samedir "${_g2_y#tests/run: remotes moved while this run ran: }" "$_g2_s/.git"; then ok "$_g2_n"
else bad "$_g2_n" "status [$(_g2_rc backrun)]; stderr: $(head -4 "$_g2/kid/backrun/err" 2>/dev/null | tr '\n' ' ')"
fi

# -------------------------------------------------------------------- A6 ----
# A run started inside a bare repository: no .git above it, and git names it
# all the same. Its config is watched.
for _g2_b in bare-same bare-moved bare-run; do
  bash "$_g2/bare.sh" "$_g2/$_g2_b.git" "$TMP" >/dev/null 2>&1 || printf 'bare build %s: %s\n' "$_g2_b" "$?" >> "$_g2/bare.err"
done
_g2_bare_ok() {   # <bare>: built, with an origin and a ref, and no .git in it
  [ "$(git --git-dir="$1" config --get remote.origin.url 2>/dev/null)" = https://example.invalid/g2/bare.git ] \
    && [ -n "$(git --git-dir="$1" for-each-ref refs/remotes/origin 2>/dev/null)" ] && [ ! -e "$1/.git" ]
}
_g2_kid bare-same 1 <<'G2KID'
ok "g2 child: an assertion in a run started inside a bare repository"
true
G2KID
_g2_run bare-same "$_g2/bare-same.git" "$_g2/bare-same.git"
_g2_n="a run started inside a bare repository runs the origin check and passes it, rather than skipping it"
if ! _g2_bare_ok "$_g2/bare-same.git"; then bad "$_g2_n" "not exercised: the bare stand-in was not built [$(cat "$_g2/bare.err" 2>/dev/null)]"
elif _g2_has bare-same "  ok    $_g2_c8"; then ok "$_g2_n"
else bad "$_g2_n" "C8 said: $(_g2_said bare-same)stderr: $(head -3 "$_g2/kid/bare-same/err" | tr '\n' ' ')"
fi
cat > "$_g2/bare-move.sh" <<'G2KID'
ok "g2 child: an assertion before the bare repository's remote moves"
sleep 1
_g2k_git remote set-url origin https://example.invalid/g2/moved.git
ok "g2 child: an assertion after the bare repository's remote moves"
true
G2KID
_g2_kid bare-moved 1 < "$_g2/bare-move.sh"; _g2_run bare-moved "$_g2/bare-moved.git" "$_g2/bare-moved.git"
_g2_n="a remote moved in a bare repository the run started in fails the origin check, naming its config"
if [ "$(git --git-dir="$_g2/bare-moved.git" config --get remote.origin.url 2>/dev/null)" != https://example.invalid/g2/moved.git ]; then
  bad "$_g2_n" "not exercised: the bare repository's remote did not move [$(cat "$_g2/bare.err" "$_g2/kid/bare-moved/kid.err" 2>/dev/null)]"
elif _g2_has bare-moved "  FAIL  $_g2_c8" && case "$(_g2_detail bare-moved "$_g2_c8")" in *bare-moved.git/config*) true ;; *) false ;; esac; then ok "$_g2_n"
else bad "$_g2_n" "C8 said: $(_g2_said bare-moved)detail: $(_g2_detail bare-moved "$_g2_c8" | tr '\n' ' ')"
fi
_g2_kid bare-run 0 < "$_g2/bare-move.sh"; _g2_run bare-run "$_g2/bare-run.git" "$_g2/bare-run.git"
_g2_n="a section runner started inside a bare repository whose remote moved exits 1, its trap naming the config"
_g2_y="$(grep '^tests/run: remotes moved while this run ran: ' "$_g2/kid/bare-run/err" 2>/dev/null | head -1)"
if [ "$(git --git-dir="$_g2/bare-run.git" config --get remote.origin.url 2>/dev/null)" != https://example.invalid/g2/moved.git ]; then
  bad "$_g2_n" "not exercised: the bare repository's remote did not move [$(cat "$_g2/bare.err" "$_g2/kid/bare-run/kid.err" 2>/dev/null)]"
elif [ "$(_g2_rc bare-run)" = 1 ] && _g2_samedir "${_g2_y#tests/run: remotes moved while this run ran: }" "$_g2/bare-run.git"; then ok "$_g2_n"
else bad "$_g2_n" "status [$(_g2_rc bare-run)]; stderr: $(head -4 "$_g2/kid/bare-run/err" 2>/dev/null | tr '\n' ' ')"
fi

# Last: nothing this block provoked reached the suite's own refusal record.
_g2_rec1=0
[ -n "${FELIX_TEST_FXREFUSED:-}" ] && [ -f "$FELIX_TEST_FXREFUSED" ] \
  && _g2_rec1="$(wc -l < "$FELIX_TEST_FXREFUSED" | tr -d ' ')"
is "no refusal review round 1's block provoked reached the suite's own refusal record" "$_g2_rec1" "$_g2_rec0"

