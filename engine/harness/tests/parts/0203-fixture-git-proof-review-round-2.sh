printf '\nfixture git proof: review round 2\n'
# Review round 2 of the fixture git proof (contract C14, amendments B1 to B7).
# Written blind, from the contract alone, and testing what the amendments add:
# - B1: a re-read that cannot read the watched config is not a move. A tick
#   that hits one records nothing; an end that still cannot read says so in
#   words of its own and never says "moved"; a real move between readable
#   states still reads moved.
# - B2: the floor's probe function is pinned by its cksum, and a copy of this
#   suite with one git write added inside it fails the pin.
# - B3: _fx_cd follows git's own walk. An invalid .git directory does not stop
#   it, and a valid one whose commondir leads outside $TMP is refused.
# - B4: _fx_git skips the value of --config-env and --attr-source, so a -C
#   after them is still seen.
# - B5: the lint sees git past env -u, exec -a, command -p and timeout, and
#   past global options before git's -C.
# - B7: a start inside a bare repository that git cannot be asked about is
#   unreadable, not "no repository".
#
# The rules of the earlier blind blocks hold here:
# - Every probe that could write starts inside a stand-in under $TMP. The
#   stand-ins are built by scripts written below and run as children; those
#   shed the GIT_* variables that point git elsewhere and check their target's
#   physical path themselves.
# - A child run's $TMP is a fresh directory of its own, so a stand-in under
#   THIS run's $TMP is outside the child's. Should _fx_cd or _fx_git fail open
#   there, the damage lands in that stand-in, where the assertion reads it.
# - Whether git ran is read from a shim on PATH that logs each call and then
#   runs the real git.
# - Unreadable files are made with chmod, inside a stand-in, and put back by
#   this block after the child has ended. As root, chmod 000 hides nothing, so
#   those cases skip.
#
# Measured on git 2.54 (2026-10-08): `git config --file F --get-regexp` on a
# mode-000 F prints a warning and exits 1, the status of "no match", so a
# re-read that trusts git's status alone reads an unreadable config as one
# with no entries. Inside a bare repository whose config is mode 000, `git
# rev-parse --git-common-dir` exits 128 saying "unable to access 'config'",
# not "not a git repository": the failure B7 is about, with no stub.
#
# The names of B2's assertion and of C3's are split across two string parts
# below, so that this block, once spliced into the suite, is never taken for
# the section that holds them.
_g3="$TMP/fixture-git-proof-r2"; mkdir -p "$_g3/lint" "$_g3/kid" "$_g3/shim" "$_g3/none" "$_g3/b2"
_g3_phys() { [ -n "${1:-}" ] && [ -d "$1" ] && ( cd -P "$1" && pwd -P ); }
_g3_get()  { printf '%s\n' "$1" | sed -n "s/^$2 //p"; }
_g3_tmpp="$(_g3_phys "$TMP")"
_g3_src="$(_suite_flat)"
_g3_hdrline() { grep -n "^printf '\\\\n" "$1" 2>/dev/null | head -1 | cut -d: -f1; }
_g3_pre="$(_g3_hdrline "$_g3_src")"
_g3_root=0; [ "$(id -u)" = 0 ] && _g3_root=1
_g3_rec0=0
[ -n "${FELIX_TEST_FXREFUSED:-}" ] && [ -f "$FELIX_TEST_FXREFUSED" ] \
  && _g3_rec0="$(wc -l < "$FELIX_TEST_FXREFUSED" | tr -d ' ')"

# -------------------------------------------------------------------- B5 ----
# _fx_lint over synthetic files: a line it must report holds a variable whose
# name starts S_, and no other line does, so the expected output is grep -n of
# those lines. N_ lines are ones it must pass over.
_g3_lint_is() {   # <name> <file> <status wanted>
  local o rc
  if ! declare -F _fx_lint >/dev/null 2>&1; then bad "$1" "_fx_lint is not defined"; return 0; fi
  o="$(_fx_lint "$2" 2>/dev/null)"; rc=$?
  is "$1" "$o|rc=$rc" "$(grep -nE '\$\{?S_' "$2")|rc=$3"
}
cat > "$_g3/lint/env-u" <<'G3LINT'
env -u NAME git -C "$S_env_u" commit -qm x
x="$(env -u NAME git -C "$S_env_u_dollar" commit -qm x)"
G3LINT
cat > "$_g3/lint/env-more" <<'G3LINT'
env --unset NAME git -C "$S_env_unset" commit -qm x
env -C /tmp git -C "$S_env_chdir_short" commit -qm x
env --chdir /tmp git -C "$S_env_chdir_long" commit -qm x
G3LINT
cat > "$_g3/lint/exec-a" <<'G3LINT'
exec -a NAME git -C "$S_exec_a" commit -qm x
G3LINT
cat > "$_g3/lint/command-p" <<'G3LINT'
command -p git -C "$S_command_p" commit -qm x
if command -p git -C "$S_command_p_if" commit -qm x; then :; fi
G3LINT
cat > "$_g3/lint/timeout" <<'G3LINT'
timeout 5 git -C "$S_timeout" commit -qm x
timeout --preserve-status 5 git -C "$S_timeout_opt" commit -qm x
G3LINT
cat > "$_g3/lint/gitopts" <<'G3LINT'
git --no-optional-locks -C "$S_no_optional_locks" commit -qm x
git -p -C "$S_paginate" commit -qm x
G3LINT
cat > "$_g3/lint/cdgroup" <<'G3LINT'
( cd "$S_cd_command_p" && command -p git remote add o https://example.invalid/x.git )
( cd "$S_cd_timeout" && timeout 5 git remote add o https://example.invalid/x.git )
G3LINT
cat > "$_g3/lint/reads" <<'G3LINT'
git -C "$N_t" --no-optional-locks status
git --no-optional-locks -C "$N_t" rev-parse HEAD
G3LINT
cat > "$_g3/lint/notcmd" <<'G3LINT'
env -u NAME echo git -C "$N_t" commit -qm x
exec -a NAME echo git -C "$N_t" commit -qm x
timeout 5 echo git -C "$N_t" commit -qm x
command -p git -C "$N_t" log -1
timeout 5 git -C "$N_t" rev-parse HEAD
git -p -C "$N_t" status
( cd "$N_t" && command -p git remote -v )
G3LINT
_g3_lint_is "_fx_lint sees git -C on a variable past env -u NAME" "$_g3/lint/env-u" 1
_g3_lint_is "_fx_lint sees git -C on a variable past env --unset NAME, env -C DIR and env --chdir DIR" "$_g3/lint/env-more" 1
_g3_lint_is "_fx_lint sees git -C on a variable past exec -a NAME" "$_g3/lint/exec-a" 1
_g3_lint_is "_fx_lint sees git -C on a variable past command -p" "$_g3/lint/command-p" 1
_g3_lint_is "_fx_lint sees git -C on a variable past timeout and its duration, options included" "$_g3/lint/timeout" 1
_g3_lint_is "_fx_lint sees git's -C on a variable after --no-optional-locks or -p" "$_g3/lint/gitopts" 1
_g3_lint_is "_fx_lint reports a raw cd on a variable before command -p git or timeout 5 git with a write" "$_g3/lint/cdgroup" 1
_g3_lint_is "_fx_lint passes over git -C on a variable with --no-optional-locks before or after it when the subcommand is a read" "$_g3/lint/reads" 0
_g3_lint_is "_fx_lint skips exactly the argument env -u, exec -a and timeout take, and passes over reads behind command -p, timeout and -p" "$_g3/lint/notcmd" 0

# -------------------------------------------------------- the stand-ins ----
# The builder refuses a target not physically under the bound it is given,
# sheds every GIT_* variable that points git elsewhere, and sets its own
# ceiling at the target's parent. Each stand-in has a committed file `f`
# naming it, a sub directory, an origin, and a branch tracking origin. It
# writes no remote-tracking ref: nothing below needs one.
cat > "$_g3/build.sh" <<'G3BUILD'
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
git -c user.name=t -c user.email=t@t -c commit.gpgsign=false commit -q --no-verify -m stand-in >/dev/null 2>&1 || exit 7
git remote add origin https://example.invalid/g3/stand-in.git || exit 8
git config branch.main.remote origin && git config branch.main.merge refs/heads/main || exit 8
exit 0
G3BUILD
# A bare stand-in: a repository with no .git anywhere in it, with an origin.
cat > "$_g3/bare.sh" <<'G3BUILD'
set -u
unset GIT_DIR GIT_WORK_TREE GIT_COMMON_DIR GIT_INDEX_FILE GIT_OBJECT_DIRECTORY GIT_ALTERNATE_OBJECT_DIRECTORIES GIT_CONFIG
[ -n "${1:-}" ] && [ -n "${2:-}" ] || exit 3
mkdir -p "$1" || exit 3
t="$(cd -P "$2" && pwd -P)" && d="$(cd -P "$1" && pwd -P)" || exit 3
case "$d" in "$t"/?*) ;; *) exit 4 ;; esac
GIT_CEILING_DIRECTORIES="${d%/*}"; export GIT_CEILING_DIRECTORIES
git init -q --bare "$d" >/dev/null 2>&1 || exit 5
[ "$(git --git-dir="$d" rev-parse --is-bare-repository 2>/dev/null)" = true ] || exit 6
git --git-dir="$d" remote add origin https://example.invalid/g3/bare.git || exit 8
exit 0
G3BUILD
_g3_build() { bash "$_g3/build.sh" "$1" "$TMP" >/dev/null 2>&1; }
# The git shim: logs each call, then runs the real git.
_g3_realgit="$(command -v git)"
cat > "$_g3/shim/git" <<'G3SHIM'
#!/bin/sh
printf '%s\n' "$*" >> "${G3_SHIMLOG:-/dev/null}"
exec "${G3_REALGIT:-git-not-found}" "$@"
G3SHIM
chmod +x "$_g3/shim/git"

# -------------------------------------------------------- child runs ----
# As in the earlier blind blocks: the preamble cut at the line before its
# first section header, REAL_HARNESS set to a copy of the harness under test,
# then a body, and for some children the lines from C5 and C8's header to the
# line before the completion marker, then a tail that prints FAIL and exits 0.
# A child changes its stand-in only through _g3k_*, which first check that the
# git dir it was handed sits physically under this run's $TMP.
#
# C7 compares mtimes in whole seconds, so a child sleeps a second before it
# touches or changes anything.
_g3_hdr="printf '\\nthe run stayed inside its temporary directory\\n'"
_g3_mark="printf '\\nreached\\n'"
_g3_c8="the remotes of the checkout this run started in did not move while it ran"
_g3_reread="could not re-read the remotes at the end: "
_g3_cutx() {
  G3_H="$_g3_hdr" G3_M="$_g3_mark" awk 'BEGIN { h = ENVIRON["G3_H"]; m = ENVIRON["G3_M"] }
    $0 == h { on = 1 } on && $0 == m { exit } on { print }' "$_g3_src"
}
_g3_harness="$_g3/harness"; _copy_content "$REAL_HARNESS" "$_g3_harness"
cat > "$_g3/kid-lib.sh" <<'G3KID'
# fixture git proof, review round 2: what this child may touch, and nothing else
_g3k_ok() {
  [ -n "${G3_GITDIR:-}" ] && [ -n "${G3_TMPP:-}" ] && [ -d "$G3_GITDIR" ] || return 1
  case "$(cd -P "$G3_GITDIR" 2>/dev/null && pwd -P)/" in "$G3_TMPP"/?*) return 0 ;; esac
  return 1
}
_g3k_no() { printf 'no stand-in [%s]\n' "${G3_GITDIR:-}" >> "$G3_OUT/kid.err"; return 3; }
_g3k_git() {
  _g3k_ok || { _g3k_no; return 3; }
  ( unset GIT_DIR GIT_WORK_TREE GIT_COMMON_DIR GIT_INDEX_FILE GIT_OBJECT_DIRECTORY GIT_ALTERNATE_OBJECT_DIRECTORIES GIT_CONFIG
    git --git-dir="$G3_GITDIR" "$@" ) >/dev/null 2>&1
}
_g3k_chmod() { _g3k_ok || { _g3k_no; return 3; }; chmod "$1" "$G3_GITDIR/$2"; }
_g3k_touch() { _g3k_ok || { _g3k_no; return 3; }; touch "$G3_GITDIR/$1"; }
_g3k_readable() { if [ -r "$G3_GITDIR/config" ]; then printf 'readable\n'; else printf 'unreadable\n'; fi; }
printf '%s\n' "$TMP" > "$G3_OUT/tmp"
G3KID
cat > "$_g3/kid-tail.sh" <<'G3KID'
printf 'g3-fail %s\n' "$FAIL"
exit 0
G3KID
_g3_kid() {   # <name> <cut: 0|1>, body on stdin
  local d="$_g3/kid/$1"; mkdir -p "$d"; cat > "$d/body.sh"
  { [ -n "$_g3_pre" ] && awk -v n="$_g3_pre" 'NR < n { print; if ($0 ~ /^REAL_HARNESS=/) print "REAL_HARNESS=\"$G3_HARNESS\"" }' "$_g3_src"
    cat "$_g3/kid-lib.sh" "$d/body.sh"
    if [ "$2" = 1 ]; then _g3_cutx; cat "$_g3/kid-tail.sh"; fi; } > "$d/run"
}
_g3_run() {   # <name> <start dir> [git dir it may touch]
  local d="$_g3/kid/$1"
  if [ -z "${2:-}" ] || [ ! -d "$2" ]; then printf 'not started' > "$d/err"; : > "$d/out"; printf 'x' > "$d/rc"; return 0; fi
  ( cd "$2" && G3_OUT="$d" G3_GITDIR="${3:-}" G3_TMPP="$_g3_tmpp" G3_HARNESS="$_g3_harness" \
      G3_REALGIT="$_g3_realgit" G3_SHIM="$_g3/shim" G3_BUILD="$_g3/build.sh" G3_OUTSIDE="${_g3_outp:-}" \
      bash "$d/run" > "$d/out" 2> "$d/err"; printf '%s' "$?" > "$d/rc" )
}
_g3_rc()   { cat "$_g3/kid/$1/rc" 2>/dev/null; }
_g3_has()  { grep -Fxq -- "$2" "$_g3/kid/$1/out" 2>/dev/null; }
_g3_said() { grep -F -- "$_g3_c8" "$_g3/kid/$1/out" 2>/dev/null | tr '\n' ' '; }
_g3_detail() {   # <out file> <assertion name>: what bad printed under it
  G3_N="  FAIL  $2" awk 'f && (/^  (ok|FAIL|skip)  / || /^g3-fail /) { exit } f { print } $0 == ENVIRON["G3_N"] { f = 1 }' \
    "$1" 2>/dev/null
}
_g3_tline() { grep -- "^$2" "$_g3/kid/$1/err" 2>/dev/null | head -1; }   # <kid> <stderr prefix>: the first such line
_g3_samedir() {   # <reported config path> <git dir>: the path is that git dir's config, physically
  [ "${1##*/}" = config ] && [ -n "$(_g3_phys "$2")" ] && [ "$(_g3_phys "${1%/*}")" = "$(_g3_phys "$2")" ]
}
_g3_startswith() {   # <text> <git dir>: text begins with that git dir's config path, as given or physically, then ends or leaves the path
  local g p
  for g in "$2" "$(_g3_phys "$2")"; do
    p="$g/config"
    case "$1" in "$p"|"$p"[!A-Za-z0-9._/-]*) return 0 ;; esac
  done
  return 1
}
_g3_sum() { cksum < "$1" 2>/dev/null; }

# -------------------------------------------------------------------- B1 ----
# The config is touched, so its mtime moves and C7's next tick re-reads it,
# and made unreadable for that tick. Its content never changes. In the first
# pair of children it is readable again before the end; in the second it is
# not; in the third a real move follows the unreadable tick.
cat > "$_g3/heal.sh" <<'G3KID'
ok "g3 child: an assertion before the config is touched"
sleep 1
_g3k_touch config
_g3k_chmod 000 config
_g3k_readable > "$G3_OUT/at-tick"
ok "g3 child: an assertion recorded while the config cannot be read"
_g3k_chmod 644 config
_g3k_readable > "$G3_OUT/at-end"
ok "g3 child: an assertion after the config can be read again"
[ -e "$TMP/origin-moved" ] && cp "$TMP/origin-moved" "$G3_OUT/origin-moved"
true
G3KID
cat > "$_g3/stuck.sh" <<'G3KID'
ok "g3 child: an assertion before the config is touched"
sleep 1
_g3k_touch config
_g3k_chmod 000 config
_g3k_readable > "$G3_OUT/at-tick"
ok "g3 child: an assertion recorded while the config cannot be read"
[ -e "$TMP/origin-moved" ] && cp "$TMP/origin-moved" "$G3_OUT/origin-moved"
true
G3KID
cat > "$_g3/real.sh" <<'G3KID'
ok "g3 child: an assertion before the config is touched"
sleep 1
_g3k_touch config
_g3k_chmod 000 config
_g3k_readable > "$G3_OUT/at-tick"
ok "g3 child: an assertion recorded while the config cannot be read"
_g3k_chmod 644 config
sleep 1
_g3k_git remote set-url origin https://example.invalid/g3/elsewhere.git
git --git-dir="$G3_GITDIR" config --get remote.origin.url > "$G3_OUT/mid" 2>/dev/null
ok "g3 child: an assertion after the remote moves"
sleep 1
_g3k_git remote set-url origin https://example.invalid/g3/stand-in.git
ok "g3 child: an assertion after the remote is put back"
[ -e "$TMP/origin-moved" ] && cp "$TMP/origin-moved" "$G3_OUT/origin-moved"
true
G3KID
_g3_b1() {   # <kid> <cut> <body file>: builds a stand-in, runs the child in it, puts the config's mode back
  local s="$_g3/st-$1"
  _g3_build "$s"; _g3_sum "$s/.git/config" > "$_g3/kid-$1.sum0"
  _g3_kid "$1" "$2" < "$3"; _g3_run "$1" "$s/sub" "$s/.git"
  if [ -r "$s/.git/config" ]; then printf 'readable\n'; else printf 'unreadable\n'; fi > "$_g3/kid/$1/after-child"
  chmod 644 "$s/.git/config" 2>/dev/null
}
_g3_ex() {   # <kid> <readable after the child: readable|unreadable>: 1 when the config was unreadable at the tick, came out as wanted, and its content is unchanged
  local d="$_g3/kid/$1"
  [ "$(cat "$d/at-tick" 2>/dev/null)" = unreadable ] && [ "$(cat "$d/after-child" 2>/dev/null)" = "$2" ] \
    && [ -s "$_g3/kid-$1.sum0" ] && [ "$(_g3_sum "$_g3/st-$1/.git/config")" = "$(cat "$_g3/kid-$1.sum0")" ] && printf 1 || printf 0
}
_g3_noex() { printf 'not exercised: at the tick the config was [%s], after the child [%s] [%s]' \
  "$(cat "$_g3/kid/$1/at-tick" 2>/dev/null)" "$(cat "$_g3/kid/$1/after-child" 2>/dev/null)" "$(cat "$_g3/kid/$1/kid.err" 2>/dev/null)"; }

_g3_n1="a tick that cannot re-read the config, readable and unchanged again by the end, records no move and the origin check passes"
_g3_n2="a section runner whose config could not be read at one tick, readable and unchanged by the end, exits 0 with its trap silent"
_g3_n3="a config still unreadable at the end fails the origin check with 'could not re-read the remotes at the end: ' and its path, and never says moved"
_g3_n4="a section runner whose config is still unreadable at the end exits 1, its trap saying it could not re-read the remotes at the end, not that they moved"
_g3_n5="a remote moved between readable states and put back, after a tick that could not read the config, still fails the origin check as a move"
_g3_n6="the C7 record of a run whose config could not be read at one tick names the assertion after the real move, not that tick"
if [ "$_g3_root" = 1 ]; then
  for _g3_x in "$_g3_n1" "$_g3_n2" "$_g3_n3" "$_g3_n4" "$_g3_n5" "$_g3_n6"; do skip "$_g3_x" "root reads a mode-000 file"; done
else
  _g3_b1 heal 1 "$_g3/heal.sh"
  if [ "$(_g3_ex heal readable)" != 1 ] || [ "$(cat "$_g3/kid/heal/at-end" 2>/dev/null)" != readable ]; then bad "$_g3_n1" "$(_g3_noex heal)"
  elif _g3_has heal "  ok    $_g3_c8" && [ ! -e "$_g3/kid/heal/origin-moved" ]; then ok "$_g3_n1"
  else bad "$_g3_n1" "C8 said: $(_g3_said heal)detail: $(_g3_detail "$_g3/kid/heal/out" "$_g3_c8" | tr '\n' ' ')C7 record: $(tr '\t\n' '| ' 2>/dev/null < "$_g3/kid/heal/origin-moved")"
  fi

  _g3_b1 healrun 0 "$_g3/heal.sh"
  if [ "$(_g3_ex healrun readable)" != 1 ]; then bad "$_g3_n2" "$(_g3_noex healrun)"
  elif [ "$(_g3_rc healrun)" = 0 ] && [ -z "$(grep '^tests/run:' "$_g3/kid/healrun/err" 2>/dev/null)" ]; then ok "$_g3_n2"
  else bad "$_g3_n2" "status [$(_g3_rc healrun)]; stderr: $(head -4 "$_g3/kid/healrun/err" 2>/dev/null | tr '\n' ' ')"
  fi

  _g3_b1 stuck 1 "$_g3/stuck.sh"
  _g3_d="$(_g3_detail "$_g3/kid/stuck/out" "$_g3_c8")"
  _g3_l="$(printf '%s\n' "$_g3_d" | sed -n '1s/^ *//p')"
  _g3_s="$_g3/st-stuck/.git"
  _g3_y="$(printf '%s\n' "$_g3_d" | G3_A="$_g3_s/config" G3_B="$(_g3_phys "$_g3_s")/config" awk '{ gsub(ENVIRON["G3_A"], ""); gsub(ENVIRON["G3_B"], ""); print }' | grep -i moved)"
  if [ "$(_g3_ex stuck unreadable)" != 1 ]; then bad "$_g3_n3" "$(_g3_noex stuck)"
  elif _g3_has stuck "  FAIL  $_g3_c8" && case "$_g3_l" in "$_g3_reread"*) true ;; *) false ;; esac \
       && _g3_startswith "${_g3_l#"$_g3_reread"}" "$_g3_s" && [ -z "$_g3_y" ] && [ ! -e "$_g3/kid/stuck/origin-moved" ]; then ok "$_g3_n3"
  else bad "$_g3_n3" "C8 said: $(_g3_said stuck)detail: $(printf '%s' "$_g3_d" | tr '\n' ' ') C7 record: $(tr '\t\n' '| ' 2>/dev/null < "$_g3/kid/stuck/origin-moved")"
  fi

  _g3_b1 stuckrun 0 "$_g3/stuck.sh"
  _g3_y="$(_g3_tline stuckrun "tests/run: $_g3_reread")"
  if [ "$(_g3_ex stuckrun unreadable)" != 1 ]; then bad "$_g3_n4" "$(_g3_noex stuckrun)"
  elif [ "$(_g3_rc stuckrun)" = 1 ] && [ -n "$_g3_y" ] && _g3_samedir "${_g3_y#"tests/run: $_g3_reread"}" "$_g3/st-stuckrun/.git" \
       && [ -z "$(_g3_tline stuckrun 'tests/run: remotes moved while this run ran: ')" ]; then ok "$_g3_n4"
  else bad "$_g3_n4" "status [$(_g3_rc stuckrun)]; stderr: $(head -4 "$_g3/kid/stuckrun/err" 2>/dev/null | tr '\n' ' ')"
  fi

  _g3_b1 real 1 "$_g3/real.sh"
  _g3_x=0
  [ "$(_g3_ex real readable)" = 1 ] && [ "$(cat "$_g3/kid/real/mid" 2>/dev/null)" = https://example.invalid/g3/elsewhere.git ] \
    && [ "$(git --git-dir="$_g3/st-real/.git" config --get remote.origin.url 2>/dev/null)" = https://example.invalid/g3/stand-in.git ] && _g3_x=1
  _g3_d="$(_g3_detail "$_g3/kid/real/out" "$_g3_c8")"
  _g3_l="$(printf '%s\n' "$_g3_d" | sed -n '1s/^ *//p')"
  if [ "$_g3_x" != 1 ]; then bad "$_g3_n5" "$(_g3_noex real); mid [$(cat "$_g3/kid/real/mid" 2>/dev/null)]"
  elif _g3_has real "  FAIL  $_g3_c8" && case "$_g3_l" in "$_g3_reread"*) false ;; *) true ;; esac; then ok "$_g3_n5"
  else bad "$_g3_n5" "C8 said: $(_g3_said real)detail: $(printf '%s' "$_g3_d" | tr '\n' ' ')"
  fi
  _g3_y="$(head -1 "$_g3/kid/real/origin-moved" 2>/dev/null | cut -f3)"
  if [ "$_g3_x" != 1 ]; then bad "$_g3_n6" "$(_g3_noex real)"
  else is "$_g3_n6" "$_g3_y" "g3 child: an assertion after the remote moves"
  fi
fi

# -------------------------------------------------------------------- B7 ----
# A start inside a bare repository whose config is mode 000. git exits 128
# there, but not with "not a git repository", so the start cannot be asked
# about and the run must not read it as no repository. A control: the same
# kind of bare repository, readable, is watched and passes.
for _g3_b in b7-same b7-stuck b7-stuckrun; do
  bash "$_g3/bare.sh" "$_g3/$_g3_b.git" "$TMP" >/dev/null 2>&1 || printf 'bare build %s: %s\n' "$_g3_b" "$?" >> "$_g3/bare.err"
done
_g3_kid b7-same 1 <<'G3KID'
ok "g3 child: an assertion in a run started inside a readable bare repository"
true
G3KID
_g3_run b7-same "$_g3/b7-same.git" "$_g3/b7-same.git"
_g3_n="fixture git proof r2: a run started inside a readable bare repository passes the origin check"
if [ "$(git --git-dir="$_g3/b7-same.git" config --get remote.origin.url 2>/dev/null)" != https://example.invalid/g3/bare.git ]; then
  bad "$_g3_n" "not exercised: the bare stand-in was not built [$(cat "$_g3/bare.err" 2>/dev/null)]"
elif _g3_has b7-same "  ok    $_g3_c8"; then ok "$_g3_n"
else bad "$_g3_n" "C8 said: $(_g3_said b7-same)stderr: $(head -3 "$_g3/kid/b7-same/err" 2>/dev/null | tr '\n' ' ')"
fi
_g3_n1="a run started inside a bare repository git cannot be asked about, exiting 128 but not 'not a git repository', fails the origin check rather than skipping it"
_g3_n2="a section runner started inside a bare repository git cannot be asked about exits 1, saying it could not read the remotes this run started with"
_g3_b7ask() {   # <bare>: rc=<status> and whether stderr, in the C locale, says "not a git repository"
  local e rc
  e="$( cd "$1" 2>/dev/null || exit 9; LC_ALL=C git -C "$1" rev-parse --git-common-dir 2>&1 >/dev/null )"; rc=$?
  case "$e" in *"not a git repository"*) printf 'rc=%s notrepo' "$rc" ;; *) printf 'rc=%s other' "$rc" ;; esac
}
if [ "$_g3_root" = 1 ]; then
  skip "$_g3_n1" "root reads a mode-000 file"; skip "$_g3_n2" "root reads a mode-000 file"
else
  chmod 000 "$_g3/b7-stuck.git/config" "$_g3/b7-stuckrun.git/config" 2>/dev/null
  _g3_q1="$(_g3_b7ask "$_g3/b7-stuck.git")"; _g3_q2="$(_g3_b7ask "$_g3/b7-stuckrun.git")"
  _g3_kid b7-stuck 1 <<'G3KID'
ok "g3 child: an assertion in a run started inside a bare repository git cannot be asked about"
true
G3KID
  _g3_run b7-stuck "$_g3/b7-stuck.git" "$_g3/b7-stuck.git"
  _g3_kid b7-stuckrun 0 <<'G3KID'
ok "g3 child: an assertion in a section runner started inside a bare repository git cannot be asked about"
true
G3KID
  _g3_run b7-stuckrun "$_g3/b7-stuckrun.git" "$_g3/b7-stuckrun.git"
  chmod 644 "$_g3/b7-stuck.git/config" "$_g3/b7-stuckrun.git/config" 2>/dev/null
  if [ "$_g3_q1" != "rc=128 other" ]; then bad "$_g3_n1" "not exercised: asked from inside it, git said [$_g3_q1], not 128 with another message [$(cat "$_g3/bare.err" 2>/dev/null)]"
  elif _g3_has b7-stuck "  FAIL  $_g3_c8"; then ok "$_g3_n1"
  else bad "$_g3_n1" "C8 said: $(_g3_said b7-stuck)stderr: $(head -3 "$_g3/kid/b7-stuck/err" 2>/dev/null | tr '\n' ' ')"
  fi
  if [ "$_g3_q2" != "rc=128 other" ]; then bad "$_g3_n2" "not exercised: asked from inside it, git said [$_g3_q2], not 128 with another message"
  elif [ "$(_g3_rc b7-stuckrun)" = 1 ] && [ -n "$(_g3_tline b7-stuckrun 'tests/run: could not read the remotes this run started with: ')" ]; then ok "$_g3_n2"
  else bad "$_g3_n2" "status [$(_g3_rc b7-stuckrun)]; stderr: $(head -4 "$_g3/kid/b7-stuckrun/err" 2>/dev/null | tr '\n' ' ')"
  fi
fi

# ------------------------------------------------------------ B3 and B4 ----
# The outside repository, under this run's $TMP and so outside the child's.
_g3_out="$_g3/outside"; _g3_build "$_g3_out"; _g3_outp="$(_g3_phys "$_g3_out")"
_g3_kid fx 0 <<'G3KID'
_g3k_in="$TMP/g3-in"; _g3k_base="$TMP/g3-base"
for _g3k_d in "$_g3k_in" "$_g3k_base"; do
  bash "$G3_BUILD" "$_g3k_d" "$TMP" >/dev/null 2>&1 || printf 'build %s: %s\n' "$_g3k_d" "$?" >> "$G3_OUT/kid.err"
done
_g3k_p() { ( cd -P "$1" 2>/dev/null && pwd -P ); }
_g3k_valid() {   # <dir> <commondir line, or ->: a .git directory holding HEAD, objects and refs
  mkdir -p "$1/.git/objects" "$1/.git/refs" && printf 'ref: refs/heads/main\n' > "$1/.git/HEAD" \
    && { [ "$2" = - ] || printf '%s\n' "$2" > "$1/.git/commondir"; }
}
_g3k_toroot() { local r="$1" u=""; while [ -n "$r" ]; do u="../$u"; r="${r%/*}"; done; printf '%s' "$u"; }
# Refused: an empty .git directory, and one with HEAD and refs but no
# objects, each below a .git file pointing outside; a valid .git directory
# whose commondir names the outside repository, absolutely and relatively.
mkdir -p "$TMP/g3-ib/inner/.git" "$TMP/g3-ip/inner/.git/refs"
printf 'gitdir: %s\n' "$G3_OUTSIDE/.git" > "$TMP/g3-ib/.git"
printf 'gitdir: %s\n' "$G3_OUTSIDE/.git" > "$TMP/g3-ip/.git"
printf 'ref: refs/heads/main\n' > "$TMP/g3-ip/inner/.git/HEAD"
_g3k_valid "$TMP/g3-ca" "$G3_OUTSIDE/.git"
mkdir -p "$TMP/g3-cr/.git"
_g3k_valid "$TMP/g3-cr" "$(_g3k_toroot "$(_g3k_p "$TMP/g3-cr/.git")")${G3_OUTSIDE#/}/.git"
# Allowed: a valid .git directory whose commondir names a repository inside
# $TMP, absolutely and relatively, and an empty .git directory with no
# repository above it inside $TMP.
_g3k_valid "$TMP/g3-cia" "$(_g3k_p "$_g3k_base/.git")"
_g3k_valid "$TMP/g3-cir" "../../g3-base/.git"
mkdir -p "$TMP/g3-ia/inner/.git"
# What git itself makes of each, with nothing of the code under test.
_g3k_common() {   # <dir>: the common dir git finds from <dir>, physically, or rc=<status>
  ( unset GIT_DIR GIT_WORK_TREE GIT_COMMON_DIR GIT_INDEX_FILE GIT_OBJECT_DIRECTORY GIT_ALTERNATE_OBJECT_DIRECTORIES GIT_CONFIG
    GIT_CEILING_DIRECTORIES="$(_g3k_p "$TMP")"; export GIT_CEILING_DIRECTORIES
    cd -P "$1" 2>/dev/null || { printf 'nodir'; exit 0; }
    c="$(git rev-parse --git-common-dir 2>/dev/null)"; rc=$?
    if [ "$rc" = 0 ] && [ -n "$c" ] && cd -P "$c" 2>/dev/null; then pwd -P; else printf 'rc=%s' "$rc"; fi )
}
for _g3k_c in ib:g3-ib/inner ip:g3-ip/inner ca:g3-ca cr:g3-cr cia:g3-cia cir:g3-cir ia:g3-ia/inner; do
  printf '%s %s\n' "${_g3k_c%%:*}" "$(_g3k_common "$TMP/${_g3k_c#*:}")" >> "$G3_OUT/common"
done
printf 'outside %s\nbase %s\ntp %s\ninsub %s\n' "$(_g3k_p "$G3_OUTSIDE/.git")" "$(_g3k_p "$_g3k_base/.git")" \
  "$(_g3k_p "$TMP")" "$(_g3k_p "$_g3k_in/sub")" >> "$G3_OUT/common"
# git honours a -C after each of B4's options. Read only.
for _g3k_o in "--config-env x.y=HOME" "--attr-source HEAD" "--no-optional-locks"; do
  printf '%s\n' "$( cd "$_g3k_in/sub" && git $_g3k_o -C "$G3_OUTSIDE" rev-parse --show-toplevel 2>/dev/null )" >> "$G3_OUT/b4ctl"
done
printf '%s' "$HOME" > "$G3_OUT/home"
_g3k_state() {
  local g="$G3_OUTSIDE/.git"
  printf 'config %s\n' "$(git --git-dir="$g" config --file "$g/config" --list 2>&1 | tr '\n' ' ')"
  printf 'refs %s\n' "$(git --git-dir="$g" for-each-ref 2>&1 | tr '\n' ' ')"
  printf 'head %s\n' "$(cat "$g/HEAD" 2>&1)"
  printf 'objects %s\n' "$(find "$g/objects" -type f 2>/dev/null | wc -l | tr -d ' ')"
  printf 'f %s\n' "$(cat "$G3_OUTSIDE/f" 2>&1)"
}
( PATH="$G3_SHIM:$PATH"; G3_SHIMLOG="$G3_OUT/shimctl"; export G3_SHIMLOG G3_REALGIT; git --version >/dev/null 2>&1 )
_g3k_cd() {   # <case> <dir>: _fx_cd from inside the stand-in
  : > "$G3_OUT/$1.cdrec"
  ( cd "$_g3k_in/sub" || exit 0
    FELIX_TEST_FXREFUSED="$G3_OUT/$1.cdrec"
    _fx_cd "$2" >/dev/null 2>&1; printf 'rc %s\n' "$?"; printf 'pwd %s\n' "$(pwd -P)" ) > "$G3_OUT/$1.cd" 2>/dev/null
}
_g3k_gitp() {   # <case> <dir> <git args...>: _fx_git from inside the stand-in
  local c="$1" d="$2"; shift 2
  : > "$G3_OUT/$c.rec"; : > "$G3_OUT/$c.shim"
  _g3k_state > "$G3_OUT/$c.before"
  ( cd "$_g3k_in/sub" || exit 0
    PATH="$G3_SHIM:$PATH"; G3_SHIMLOG="$G3_OUT/$c.shim"; export G3_SHIMLOG G3_REALGIT
    FELIX_TEST_FXREFUSED="$G3_OUT/$c.rec"
    _fx_git "$d" "$@" > "$G3_OUT/$c.stdout" 2>/dev/null; printf '%s' "$?" > "$G3_OUT/$c.rc" )
  _g3k_state > "$G3_OUT/$c.after"
  : > "$G3_OUT/$c.common"
  # Only a non-empty answer is resolved: bash takes `cd ""` as a success that stays put.
  [ -s "$G3_OUT/$c.stdout" ] \
    && ( cd -P "$d" 2>/dev/null && cd -P "$(cat "$G3_OUT/$c.stdout")" 2>/dev/null && pwd -P ) > "$G3_OUT/$c.common"
  return 0
}
for _g3k_c in ib:g3-ib/inner ip:g3-ip/inner ca:g3-ca cr:g3-cr; do
  _g3k_cd   "${_g3k_c%%:*}" "$TMP/${_g3k_c#*:}"
  _g3k_gitp "${_g3k_c%%:*}" "$TMP/${_g3k_c#*:}" remote add "g3x-${_g3k_c%%:*}" https://example.invalid/g3/x.git
done
for _g3k_c in cia:g3-cia cir:g3-cir ia:g3-ia/inner; do
  _g3k_cd   "${_g3k_c%%:*}" "$TMP/${_g3k_c#*:}"
  _g3k_gitp "${_g3k_c%%:*}" "$TMP/${_g3k_c#*:}" rev-parse --git-common-dir
done
_g3k_gitp ce   "$_g3k_in" --config-env x.y=HOME -C "$G3_OUTSIDE" remote add g3x-ce https://example.invalid/g3/x.git
_g3k_gitp as   "$_g3k_in" --attr-source HEAD -C "$G3_OUTSIDE" remote add g3x-as https://example.invalid/g3/x.git
_g3k_gitp nol  "$_g3k_in" --no-optional-locks -C "$G3_OUTSIDE" remote add g3x-nol https://example.invalid/g3/x.git
_g3k_gitp ceok "$_g3k_in" --config-env x.y=HOME config --get x.y
true
G3KID
_g3_run fx "$_g3/none"
_g3_fx="$_g3/kid/fx"
_g3_ct="$(cat "$_g3_fx/tmp" 2>/dev/null)"
_g3_o="$(cat "$_g3_fx/common" 2>/dev/null)"
_g3_insub="$(_g3_get "$_g3_o" insub)"; _g3_tp="$(_g3_get "$_g3_o" tp)"
_g3_oc="$(_g3_get "$_g3_o" outside)"; _g3_bc="$(_g3_get "$_g3_o" base)"
_g3_shimok=0; [ "$(wc -l < "$_g3_fx/shimctl" 2>/dev/null | tr -d ' ')" = 1 ] && _g3_shimok=1
# Controls on the fixture. They pass on any suite: the shim sees git, git
# itself takes each directory B3 refuses to the outside repository and each
# it allows to one inside $TMP or to none, and git honours a -C after each of
# B4's options.
if [ "$_g3_shimok" = 1 ] && [ -n "$_g3_ct" ] && [ -n "$_g3_insub" ]; then
  ok  "fixture git proof r2: the child built its stand-ins, and a git shim on PATH logs each git it runs"
else
  bad "fixture git proof r2: the child built its stand-ins, and a git shim on PATH logs each git it runs" \
      "shim log [$(cat "$_g3_fx/shimctl" 2>/dev/null)]; child TMP [$_g3_ct]; paths [$(tr '\n' ' ' < "$_g3_fx/common" 2>/dev/null)]; kid.err [$(cat "$_g3_fx/kid.err" 2>/dev/null)]; stderr: $(head -3 "$_g3_fx/err" | tr '\n' ' ')"
fi
is "fixture git proof r2: git takes each directory B3 refuses to the outside repository, and each it allows to one inside \$TMP or to none" \
   "$(for _g3_c in ib ip ca cr cia cir ia; do printf '%s ' "$(_g3_get "$_g3_o" "$_g3_c")"; done)" \
   "$_g3_outp/.git $_g3_outp/.git $_g3_outp/.git $_g3_outp/.git $_g3_bc $_g3_bc rc=128 "
is "fixture git proof r2: git honours a -C given after --config-env x.y=HOME, --attr-source HEAD and --no-optional-locks" \
   "$(tr '\n' ' ' < "$_g3_fx/b4ctl" 2>/dev/null)" "$_g3_outp $_g3_outp $_g3_outp "
_g3_rcd() {   # <case> <what> <dir as given> <reason>
  local n="_fx_cd refuses $2 with reason $4, and its caller stays where it stood" o rc pwd rec
  o="$(cat "$_g3_fx/$1.cd" 2>/dev/null)"; rc="$(_g3_get "$o" rc)"; pwd="$(_g3_get "$o" pwd)"
  rec="$(cut -f2- "$_g3_fx/$1.cdrec" 2>/dev/null)|$(wc -l < "$_g3_fx/$1.cdrec" 2>/dev/null | tr -d ' ')"
  if [ -z "$o" ]; then bad "$n" "the child did not reach this probe; stderr: $(head -3 "$_g3_fx/err" | tr '\n' ' ')"
  elif [ -n "$rc" ] && [ "$rc" != 0 ] && [ -n "$_g3_insub" ] && [ "$pwd" = "$_g3_insub" ] \
       && [ "$rec" = "$(printf '%s\t%s|1' "$3" "$4")" ]; then ok "$n"
  else bad "$n" "it returned [$rc], its caller stood in [$pwd] not [$_g3_insub], and the record reads [$(tr '\t\n' '| ' < "$_g3_fx/$1.cdrec" 2>/dev/null)]"
  fi
}
_g3_rgit() {   # <case> <name> <dir as given> <reason>
  local n="$2" rc sh rec
  rc="$(cat "$_g3_fx/$1.rc" 2>/dev/null)"; sh="$(wc -l < "$_g3_fx/$1.shim" 2>/dev/null | tr -d ' ')"
  rec="$(cut -f2- "$_g3_fx/$1.rec" 2>/dev/null)|$(wc -l < "$_g3_fx/$1.rec" 2>/dev/null | tr -d ' ')"
  if [ "$_g3_shimok" != 1 ]; then bad "$n" "not exercised: the git shim logged nothing even for a git it ran"
  elif ! grep -q '^config .*remote\.origin\.url=' "$_g3_fx/$1.before" 2>/dev/null; then
    bad "$n" "not exercised: the outside repository could not be read before the probe [$(head -1 "$_g3_fx/$1.before" 2>/dev/null)]"
  elif [ -n "$rc" ] && [ "$rc" != 0 ] && [ "$sh" = 0 ] && cmp -s "$_g3_fx/$1.before" "$_g3_fx/$1.after" \
       && [ "$rec" = "$(printf '%s\t%s|1' "$3" "$4")" ]; then ok "$n"
  else
    bad "$n" "it returned [$rc]; git ran [$sh] times [$(tr '\n' ';' < "$_g3_fx/$1.shim" 2>/dev/null)]; the outside repository changed: $(diff "$_g3_fx/$1.before" "$_g3_fx/$1.after" 2>&1 | grep '^[<>]' | tr '\n' ' ')record [$(tr '\t\n' '| ' < "$_g3_fx/$1.rec" 2>/dev/null)]"
  fi
}
_g3_rcd  ib "an empty .git directory below a .git file that points outside \$TMP" "$_g3_ct/g3-ib/inner" gitdir-outside
_g3_rgit ib "_fx_git on an empty .git directory below a .git file pointing outside \$TMP refuses; git never runs and the outside repository reads as it was" "$_g3_ct/g3-ib/inner" gitdir-outside
_g3_rcd  ip "a .git directory with HEAD and refs but no objects, below a .git file that points outside \$TMP" "$_g3_ct/g3-ip/inner" gitdir-outside
_g3_rgit ip "_fx_git on a .git directory lacking objects below a .git file pointing outside \$TMP refuses; git never runs and the outside repository reads as it was" "$_g3_ct/g3-ip/inner" gitdir-outside
_g3_rcd  ca "a valid .git directory whose commondir names a repository outside \$TMP" "$_g3_ct/g3-ca" gitdir-outside
_g3_rgit ca "_fx_git on a valid .git directory whose commondir is outside \$TMP refuses; git never runs and the outside repository reads as it was" "$_g3_ct/g3-ca" gitdir-outside
_g3_rcd  cr "a valid .git directory whose relative commondir resolves outside \$TMP" "$_g3_ct/g3-cr" gitdir-outside
_g3_rgit cr "_fx_git on a valid .git directory whose relative commondir resolves outside \$TMP refuses; git never runs and the outside repository reads as it was" "$_g3_ct/g3-cr" gitdir-outside
_g3_rgit ce  "_fx_git refuses -C after --config-env and its value with git-args; git never runs and the outside repository reads as it was" "$_g3_ct/g3-in" git-args
_g3_rgit as  "_fx_git refuses -C after --attr-source and its value with git-args; git never runs and the outside repository reads as it was" "$_g3_ct/g3-in" git-args
_g3_rgit nol "_fx_git refuses -C after --no-optional-locks with git-args; git never runs and the outside repository reads as it was" "$_g3_ct/g3-in" git-args
# What B3 and B4 leave allowed.
_g3_acd() {   # <case> <name> <physical dir wanted>
  local o="$(cat "$_g3_fx/$1.cd" 2>/dev/null)"
  if [ -z "$_g3_tp" ]; then bad "$2" "not exercised: the child did not report its own \$TMP"
  else is "$2" "$(_g3_get "$o" rc)|$(_g3_get "$o" pwd)|$(tr '\t\n' '| ' < "$_g3_fx/$1.cdrec" 2>/dev/null)" "0|$3|"
  fi
}
_g3_agit() {   # <case> <name> <status wanted> <what it printed, resolved, wanted>
  local o="$_g3_fx/$1" x
  if [ "$_g3_shimok" != 1 ]; then bad "$2" "not exercised: the git shim logged nothing even for a git it ran"; return 0; fi
  x="$(cat "$o.common" 2>/dev/null)"; [ "$1" = ceok ] && x="$(cat "$o.stdout" 2>/dev/null)"
  is "$2" "$(cat "$o.rc" 2>/dev/null)|$x|$(wc -l < "$o.shim" 2>/dev/null | tr -d ' ')|$(tr '\t\n' '| ' < "$o.rec" 2>/dev/null)" "$3|$4|1|"
}
_g3_acd  cia "_fx_cd on a valid .git directory whose commondir names a repository inside \$TMP succeeds, records nothing and stands there" "$_g3_tp/g3-cia"
_g3_agit cia "_fx_git on a valid .git directory whose commondir names a repository inside \$TMP runs git once, which finds that repository" 0 "$_g3_bc"
_g3_acd  cir "_fx_cd on a valid .git directory whose relative commondir resolves inside \$TMP succeeds, records nothing and stands there" "$_g3_tp/g3-cir"
_g3_agit cir "_fx_git on a valid .git directory whose relative commondir resolves inside \$TMP runs git once, which finds that repository" 0 "$_g3_bc"
_g3_acd  ia  "_fx_cd on an empty .git directory with no repository above it inside \$TMP succeeds, records nothing and stands there" "$_g3_tp/g3-ia/inner"
_g3_agit ia  "_fx_git on an empty .git directory with no repository above it inside \$TMP runs git once, which finds none" 128 ""
_g3_agit ceok "_fx_git allows --config-env x.y=HOME with no -C: git runs once and sees the value" 0 "$(cat "$_g3_fx/home" 2>/dev/null)"

# -------------------------------------------------------------------- B2 ----
# The pin, read from outside. The C3 section is found in the suite under test
# as the section that holds both its own assertion and B2's; it runs in a
# child whose harness is a copy, from the copy's tests directory, so that
# REAL_HARNESS/tests/run and HERE/run both name the copy. The copies differ
# from the suite only by one git write added inside _ff_case. That write is
# never run; were it run, its -C names a directory that does not exist.
_g3_b2n="the fixture floor's _ff_case is the probe the lint's set-aside"" was reviewed against"
_g3_c3n="no fixture in this suite runs a git write from a raw cd"" or a raw git -C on a variable"
_g3_c3sec() {   # <file>: "first last" lines of the first section holding both names
  G3_A="$_g3_b2n" G3_B="$_g3_c3n" G3_P="printf '\\n" awk '
    BEGIN { a = ENVIRON["G3_A"]; b = ENVIRON["G3_B"]; p = ENVIRON["G3_P"] }
    index($0, p) == 1 { if (s && ha && hb) { print s, NR - 1; done = 1; exit } s = NR; ha = 0; hb = 0; next }
    s && index($0, a) { ha = 1 }
    s && index($0, b) { hb = 1 }
    END { if (!done && s && ha && hb) print s, NR }' "$1" 2>/dev/null
}
_g3_ffcase() {   # <file>: "first last" lines of _ff_case, from its opening line to the brace that closes it at the same indent
  awk '!s && /^[[:space:]]*_ff_case\(\)[[:space:]]*\{/ { s = NR; ind = $0; sub(/_ff_case.*/, "", ind); next }
       s && !e && substr($0, 1, length(ind) + 1) == ind "}" && substr($0, length(ind) + 2) ~ /^[[:space:]]*$/ { e = NR; exit }
       END { if (s && e) print s, e }' "$1" 2>/dev/null
}
_g3_sec="$(_g3_c3sec "$_g3_src")"; _g3_ff="$(_g3_ffcase "$_g3_src")"
_g3_b2w='git -C "$TMP/g3-b2-absent" config g3.b2probe x'
_g3_b2copy() {   # <name> <top|end>: a harness copy whose tests/run has the write added inside _ff_case
  local h="$_g3/b2/$1" s="${_g3_ff% *}" e="${_g3_ff#* }"
  mkdir -p "$h"; cp -R "$_g3/b2/same/." "$h/"
  G3_W="$_g3_b2w" awk -v s="$s" -v e="$e" -v at="$2" '
    NR == s { ind = $0; sub(/_ff_case.*/, "", ind) }
    at == "end" && NR == e { print ind "  " ENVIRON["G3_W"] }
    { print }
    at == "top" && NR == s { print ind "  " ENVIRON["G3_W"] }' "$_g3_src" > "$h/tests/run"
}
_g3_b2kid() {   # <name>: runs the C3 section of its copy in a child; out, err, rc beside it
  local h="$_g3/b2/$1" sec pre
  sec="$(_g3_c3sec "$h/tests/run")"; pre="$(_g3_hdrline "$h/tests/run")"
  [ -n "$sec" ] && [ -n "$pre" ] || { printf 'no section' > "$_g3/b2/$1.err"; : > "$_g3/b2/$1.out"; return 0; }
  { awk -v n="$pre" 'NR < n { print; if ($0 ~ /^REAL_HARNESS=/) print "REAL_HARNESS=\"$G3_HARNESS\"" }' "$h/tests/run"
    sed -n "${sec% *},${sec#* }p" "$h/tests/run"
    cat "$_g3/kid-tail.sh"; } > "$h/tests/g3-b2-child"
  ( cd "$_g3/none" && G3_HARNESS="$h" bash "$h/tests/g3-b2-child" > "$_g3/b2/$1.out" 2> "$_g3/b2/$1.err"; printf '%s' "$?" > "$_g3/b2/$1.rc" )
}
_g3_b2line() { grep -F -- "$_g3_b2n" "$_g3/b2/$1.out" 2>/dev/null | grep -E '^  (ok|FAIL|skip)  ' | tr '\n' ' '; }
_g3_n0="the C3 section of the suite under test, run on an unchanged copy, holds and passes the assertion pinning _ff_case"
_g3_n1="the C3 section holds the CRC and the byte count cksum gives for _ff_case's text"
_g3_n2="a copy of the suite with a git write added at the top of _ff_case fails the pin"
_g3_n3="a copy of the suite with a git write added just before _ff_case's closing brace fails the pin"
_g3_n4="the pin's failure detail names _ff_case and the cksum it asks the reader to update"
_g3_n5="fixture git proof r2: each _ff_case copy differs from the suite under test by one added line inside _ff_case"
if [ -z "$_g3_ff" ]; then
  for _g3_x in "$_g3_n0" "$_g3_n1" "$_g3_n2" "$_g3_n3" "$_g3_n4" "$_g3_n5"; do
    bad "$_g3_x" "not exercised: no _ff_case function was found in $_g3_src"
  done
elif [ -z "$_g3_sec" ]; then
  for _g3_x in "$_g3_n0" "$_g3_n1" "$_g3_n2" "$_g3_n3" "$_g3_n4"; do
    bad "$_g3_x" "no section of $_g3_src holds both C3's assertion and the one B2 names"
  done
  _g3_sec=none
else
  _copy_content "$REAL_HARNESS" "$_g3/b2/same"
  # The copy's tests/run is the driver; B2 reads sections, so it gets the suite as one file, as top and end do.
  cp "$_g3_src" "$_g3/b2/same/tests/run"
  _g3_b2copy top top; _g3_b2copy end end
  for _g3_x in same top end; do _g3_b2kid "$_g3_x"; done
  if grep -Fxq -- "  ok    $_g3_b2n" "$_g3/b2/same.out" 2>/dev/null; then ok "$_g3_n0"
  else bad "$_g3_n0" "the child said [$(_g3_b2line same)]; status [$(cat "$_g3/b2/same.rc" 2>/dev/null)]; stderr: $(head -3 "$_g3/b2/same.err" 2>/dev/null | tr '\n' ' ')"
  fi
  _g3_y="$(sed -n "${_g3_ff% *},${_g3_ff#* }p" "$_g3_src" | cksum)"
  sed -n "${_g3_sec% *},${_g3_sec#* }p" "$_g3_src" > "$_g3/b2/section"
  if grep -qw -- "${_g3_y% *}" "$_g3/b2/section" && grep -qw -- "${_g3_y#* }" "$_g3/b2/section"; then ok "$_g3_n1"
  else bad "$_g3_n1" "cksum of lines ${_g3_ff% *} to ${_g3_ff#* } gives [$_g3_y], and the section, lines $_g3_sec, does not hold both numbers"
  fi
  if grep -Fxq -- "  FAIL  $_g3_b2n" "$_g3/b2/top.out" 2>/dev/null; then ok "$_g3_n2"
  else bad "$_g3_n2" "the child said [$(_g3_b2line top)]; stderr: $(head -3 "$_g3/b2/top.err" 2>/dev/null | tr '\n' ' ')"
  fi
  if grep -Fxq -- "  FAIL  $_g3_b2n" "$_g3/b2/end.out" 2>/dev/null; then ok "$_g3_n3"
  else bad "$_g3_n3" "the child said [$(_g3_b2line end)]; stderr: $(head -3 "$_g3/b2/end.err" 2>/dev/null | tr '\n' ' ')"
  fi
  _g3_d="$(_g3_detail "$_g3/b2/top.out" "$_g3_b2n")"
  case "$_g3_d" in
    *_ff_case*) case "$(printf '%s' "$_g3_d" | tr 'A-Z' 'a-z')" in *cksum*) ok "$_g3_n4" ;; *) bad "$_g3_n4" "detail: [$_g3_d]" ;; esac ;;
    *) bad "$_g3_n4" "detail: [$_g3_d]" ;;
  esac
fi
if [ -n "$_g3_ff" ]; then
  [ -f "$_g3/b2/top/tests/run" ] || { _copy_content "$REAL_HARNESS" "$_g3/b2/same"; _g3_b2copy top top; _g3_b2copy end end; }
  _g3_x="$(diff "$_g3_src" "$_g3/b2/top/tests/run" | grep -c '^[<>]')|$(diff "$_g3_src" "$_g3/b2/end/tests/run" | grep -c '^[<>]')"
  _g3_y="$(_g3_ffcase "$_g3/b2/top/tests/run")|$(_g3_ffcase "$_g3/b2/end/tests/run")"
  _g3_s="${_g3_ff% *}"; _g3_e="${_g3_ff#* }"
  is "$_g3_n5" "$_g3_x|$_g3_y" "1|1|$_g3_s $((_g3_e + 1))|$_g3_s $((_g3_e + 1))"
fi

# Last: nothing this block provoked reached the suite's own refusal record.
_g3_rec1=0
[ -n "${FELIX_TEST_FXREFUSED:-}" ] && [ -f "$FELIX_TEST_FXREFUSED" ] \
  && _g3_rec1="$(wc -l < "$FELIX_TEST_FXREFUSED" | tr -d ' ')"
is "no refusal review round 2's block provoked reached the suite's own refusal record" "$_g3_rec1" "$_g3_rec0"

printf '\nfixture git proof: what the mutation runner found\n'
# These were NOT written blind. The mutation runner of 2026-10-08 wrote them
# after it had read the implementation, each to kill a mutant the blind block
# above let survive (the F, G and L ids are its names for them; contract C13,
# A10). So they can share the implementation's blind spots, and they lean on
# the blind block's helpers, stand-ins and children (_gp_*), which is why they
# sit directly after it. Changed on the way in, and why, so each can fail for
# the reason it names:
# - X1 compares the whole probe and the refusal's reason, so a probe that
#   never ran, or a suite with no _fx_cd, is red rather than equal to itself.
# - X3 adds origin's fetch back after the reorder: with every remote.* key
#   watched (A4), a fetch left out would fail the check whatever the order.
# - X7 builds its packed refs through _fx_cd, as the lint requires, and is
#   red as not exercised when there are no packed refs to lock.
# - X14 and X15 build their stand-ins through _fx_cd, as the lint requires.
# - X26 skips only where date -j is missing, and is red when C7 left no time.
# - X21 counts only where the ulimit held and C7 is shown to exist, as the
#   blind block's own fork probe does.

_gitproof_build; _gitproof_kid_same; _gitproof_kid_url
# F15: a refusal that enters the directory first (outside-tmp) restores OLDPWD too.
: > "$_gp/rec.x1"
_gx_o="$(cd "$_gp_home/sub" || exit 0; cd "$_gp_home" || exit 0; cd "$_gp_home/sub" || exit 0
         _a="${OLDPWD-unset}"; FELIX_TEST_FXREFUSED="$_gp/rec.x1"
         _fx_cd / >/dev/null 2>&1; printf '%s|%s' "$_a" "${OLDPWD-unset}")"
is "X1 _fx_cd refusing an outside directory it entered restores OLDPWD as well" \
   "$_gx_o|$(cut -f3 "$_gp/rec.x1" 2>/dev/null)" "$_gp_home|$_gp_home|outside-tmp"

# F25: a relative DIR never reaches cd's "-" (OLDPWD) or CDPATH.
_gx_o="$(cd "$_gp/plain" || exit 0; cd "$_gp_home/sub" || exit 0
         FELIX_TEST_FXREFUSED="$_gp/rec.x2a"; _fx_cd - >/dev/null 2>&1; printf '%s %s' "$?" "$(pwd -P)")"
is "X2a _fx_cd - does not follow OLDPWD: it refuses and the caller stays" "$_gx_o" "1 $_gp_homep/sub"
_gx_o="$(cd "$_gp_home/sub" || exit 0; CDPATH="$_gp"; export CDPATH
         FELIX_TEST_FXREFUSED="$_gp/rec.x2b"; _fx_cd plain >/dev/null 2>&1; printf '%s %s' "$?" "$(pwd -P)")"
is "X2b _fx_cd on a bare relative name does not search CDPATH" "$_gx_o" "1 $_gp_homep/sub"

# G03: the same url entries in another order are a move.
_gp_ord="$_gp/stand-order"; _gp_build "$_gp_ord" spare
_gp_kid order 1 <<'GPKID'
ok "gp child: an assertion before the remotes are reordered"
sleep 1
_gpk_git config --remove-section remote.origin
_gpk_git config remote.origin.url https://example.invalid/gp/stand-in.git
_gpk_git config remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*'
ok "gp child: an assertion after the remotes are reordered"
true
GPKID
_gp_run order "$_gp_ord/sub" "$_gp_ord"
_gx_pre="$(git -C "$_gp_ord" config --get-regexp '^remote\..*\.url$' 2>/dev/null | sed -n 1p | cut -d' ' -f1)"
_gx_f="$(git -C "$_gp_ord" config --get remote.origin.fetch 2>/dev/null)"
if [ "$_gx_pre" != remote.spare.url ] || [ "$_gx_f" != '+refs/heads/*:refs/remotes/origin/*' ]; then
  bad "X3 the same urls in another file order fail the origin check" "not exercised: first entry is [$_gx_pre], origin's fetch [$_gx_f]"
elif _gp_has order "  FAIL  $_gp_c8"; then ok "X3 the same urls in another file order fail the origin check"
else bad "X3 the same urls in another file order fail the origin check" "C8 said: $(grep -F -- "$_gp_c8" "$_gp/kid/order/out" | tr '\n' ' ')"; fi

# G05a, G05b: right after the snapshot the shell stands where it started, with
# OLDPWD as it was (unset). Read at the line before TMP= is made, where the
# snapshot ends. Since the fixture floor, the preamble moves the shell into
# $TMP/cwd on purpose after that line, and the floor's walk (cd -P .) sets
# OLDPWD, so the end of the preamble says nothing about the snapshot any more
# (restated at the merge with claude/suite-fixture-floor, 2026-10-08).
_gx_tl="$(grep -n '^TMP="\$(mktemp -d)"$' "$_gp_src" 2>/dev/null | head -1 | cut -d: -f1)"
mkdir -p "$_gp/kid/st"
{ [ -n "$_gx_tl" ] && awk -v n="$_gx_tl" 'NR < n { print; if ($0 ~ /^REAL_HARNESS=/) print "REAL_HARNESS=\"$GP_HARNESS\"" }' "$_gp_src"
  cat <<'GPKID'
printf 'pwd %s\noldpwd %s\n' "$(pwd -P)" "${OLDPWD-unset}" > "$GP_OUT/st"
GPKID
} > "$_gp/kid/st/run"
( cd "$_gp_same/sub" && env -u OLDPWD GP_OUT="$_gp/kid/st" GP_STAND= GP_TMPP="$_gp_tmpp" GP_HARNESS="$_gp_harness" bash "$_gp/kid/st/run" >/dev/null 2>&1 )
_gx_o="$(cat "$_gp/kid/st/st" 2>/dev/null)"
is "X5a after the snapshot the shell stands in the directory it started in" "${_gx_tl:+found}|$(_gp_get "$_gx_o" pwd)" "found|$(_gp_phys "$_gp_same/sub")"
is "X5b after the snapshot OLDPWD is as the shell found it" "${_gx_tl:+found}|$(_gp_get "$_gx_o" oldpwd)" "found|unset"

# G07, G08: a checkout whose refs cannot be read is unreadable, not empty.
_gp_pk="$_gp/stand-packed"; _gp_build "$_gp_pk"
( _fx_cd "$_gp_pk" && case "$(pwd -P)/" in "$_gp_tmpp"/?*) GIT_CEILING_DIRECTORIES="${_gp_pk%/*}" git pack-refs --all ;; esac ) >/dev/null 2>&1
chmod 000 "$_gp_pk/.git/packed-refs" 2>/dev/null
if [ ! -f "$_gp_pk/.git/packed-refs" ]; then
  bad "X7 a stand-in whose packed refs cannot be read fails the origin check" "not exercised: the stand-in has no packed-refs"
elif [ -r "$_gp_pk/.git/packed-refs" ]; then
  skip "X7 a stand-in whose packed refs cannot be read fails the origin check" "this user reads a mode-000 file"
else
  _gp_kid pkd 1 <<'GPKID'
ok "gp child: an assertion in a run whose refs could not be read"
true
GPKID
  _gp_run pkd "$_gp_pk/sub" "$_gp_pk"
  if _gp_has pkd "  FAIL  $_gp_c8"; then ok "X7 a stand-in whose packed refs cannot be read fails the origin check"
  else bad "X7 a stand-in whose packed refs cannot be read fails the origin check" "C8 said: $(grep -F -- "$_gp_c8" "$_gp/kid/pkd/out" | tr '\n' ' ')"; fi
fi
chmod 644 "$_gp_pk/.git/packed-refs" 2>/dev/null

# G12: the checkout around the harness is watched even when the run starts in none.
_gp_hw="$_gp/stand-hw"; _gp_build "$_gp_hw"; _copy_content "$_gp_harness" "$_gp_hw/harness"
_gp_kid hw 1 <<'GPKID'
ok "gp child: an assertion before the remote moves"
sleep 1
_gpk_git remote set-url origin https://example.invalid/gp/moved-hw.git
ok "gp child: an assertion after the remote moves"
true
GPKID
_gp_run hw "$_gp_none" "$_gp_hw" "$_gp_hw/harness"
if [ "$(git -C "$_gp_hw" config --get remote.origin.url 2>/dev/null)" != "https://example.invalid/gp/moved-hw.git" ]; then
  bad "X12 a remote that moved in the checkout around the harness fails the origin check, though the run started in no checkout" "not exercised"
elif _gp_has hw "  FAIL  $_gp_c8"; then ok "X12 a remote that moved in the checkout around the harness fails the origin check, though the run started in no checkout"
else bad "X12 a remote that moved in the checkout around the harness fails the origin check, though the run started in no checkout" "C8 said: $(grep -F -- "$_gp_c8" "$_gp/kid/hw/out" | tr '\n' ' ')"; fi

# G14: a linked worktree (.git is a file) is a checkout; its config is the shared one. The incident's own shape.
_gp_wsrc="$_gp/stand-wt-src"; _gp_build "$_gp_wsrc"; _gp_wt="$_gp/stand-wt"
( _fx_cd "$_gp_wsrc" && case "$(pwd -P)/" in "$_gp_tmpp"/?*) GIT_CEILING_DIRECTORIES="${_gp_wsrc%/*}" git worktree add -q --detach "$_gp_wt" HEAD ;; esac ) >/dev/null 2>&1
_gp_kid wt 1 <<'GPKID'
ok "gp child: an assertion before the remote moves"
sleep 1
_gpk_git remote set-url origin https://example.invalid/gp/moved-wt.git
ok "gp child: an assertion after the remote moves"
true
GPKID
if [ ! -f "$_gp_wt/.git" ]; then
  bad "X14 a remote that moved under a run started in a linked worktree fails the origin check" "not exercised: no worktree"
else
  _gp_run wt "$_gp_wt" "$_gp_wsrc"
  if _gp_has wt "  FAIL  $_gp_c8"; then ok "X14 a remote that moved under a run started in a linked worktree fails the origin check"
  else bad "X14 a remote that moved under a run started in a linked worktree fails the origin check" "C8 said: $(grep -F -- "$_gp_c8" "$_gp/kid/wt/out" | tr '\n' ' ')"; fi
fi

# G15: a remote whose name holds a dot keeps its refs under its whole name.
_gp_dot="$_gp/stand-dot"; _gp_build "$_gp_dot"
( _fx_cd "$_gp_dot" && case "$(pwd -P)/" in "$_gp_tmpp"/?*) export GIT_CEILING_DIRECTORIES="${_gp_dot%/*}"
    git remote add my.fork https://example.invalid/gp/fork.git && git update-ref refs/remotes/my.fork/main HEAD ;; esac ) >/dev/null 2>&1
_gp_kid dot 1 <<'GPKID'
ok "gp child: an assertion before the dotted remote loses its ref"
sleep 1
_gpk_git update-ref -d refs/remotes/my.fork/main
ok "gp child: an assertion after the dotted remote loses its ref"
true
GPKID
_gp_run dot "$_gp_dot/sub" "$_gp_dot"
if [ -n "$(git -C "$_gp_dot" for-each-ref refs/remotes/my.fork 2>/dev/null)" ] || [ -z "$(git -C "$_gp_dot" config --get remote.my.fork.url 2>/dev/null)" ]; then
  bad "X15 a remote named with a dot that loses its refs fails the origin check" "not exercised"
elif _gp_has dot "  FAIL  $_gp_c8"; then ok "X15 a remote named with a dot that loses its refs fails the origin check"
else bad "X15 a remote named with a dot that loses its refs fails the origin check" "C8 said: $(grep -F -- "$_gp_c8" "$_gp/kid/dot/out" | tr '\n' ' ')"; fi

# G16, G26: the detail says the remotes moved while the run ran, and C7's time is the UTC now.
_gp_d="$(_gp_detail url "$_gp_c8")"
has "X16 the origin check's detail says the remotes moved while this run ran" "$_gp_d" "moved while this run ran"
_gx_t="$(head -1 "$_gp/kid/url/origin-moved" 2>/dev/null | cut -f1)"
_gx_e="$(date -u -j -f '%Y-%m-%dT%H:%M:%SZ' "$_gx_t" +%s 2>/dev/null)"; _gx_n="$(date -u +%s)"
if ! date -u -j -f '%s' 0 +%s >/dev/null 2>&1; then skip "X26 C7's time is UTC" "date -j is not here"
elif [ -z "$_gx_t" ] || [ -z "$_gx_e" ]; then bad "X26 C7's time is UTC" "C7's record has no time that reads as %Y-%m-%dT%H:%M:%SZ: [$_gx_t]"
elif [ $((_gx_n - _gx_e)) -ge 0 ] && [ $((_gx_n - _gx_e)) -lt 3600 ]; then ok "X26 C7's time is UTC"
else bad "X26 C7's time is UTC" "[$_gx_t] is $((_gx_n - _gx_e)) s from the UTC now"; fi

# G21: after a config write that moved nothing the stamp is refreshed, so the next assertion costs no fork.
_gp_tch="$_gp/stand-touch"; _gp_build "$_gp_tch"
_gp_kid tch 1 <<'GPKID'
ok "gp child: an assertion before the config is touched"
sleep 1
_gpk_git config gp.touched yes
ok "gp child: the assertion that sees the touch"
( ulimit -S -u 1 2>/dev/null || exit 0
  ulimit -S -u > "$GP_OUT/fork.limit2"
  _ran "gp child: an assertion recorded with no fork after a touch" 2> "$GP_OUT/fork.err2" )
ok "gp child: an assertion after the second probe"
true
GPKID
_gp_run tch "$_gp_tch/sub" "$_gp_tch"
if [ "$(git -C "$_gp_tch" config --get gp.touched 2>/dev/null)" != yes ] || [ ! -s "$_gp/kid/url/origin-moved" ]; then
  bad "X21 the guard refreshes its stamp, so an assertion after a seen config change costs no fork" \
      "not exercised: the touch [$(git -C "$_gp_tch" config --get gp.touched 2>/dev/null)], or no C7 record in the moved-remote child to show a guard is there"
elif [ "$(cat "$_gp/kid/tch/fork.limit2" 2>/dev/null)" != 1 ]; then
  skip "X21 the guard refreshes its stamp, so an assertion after a seen config change costs no fork" "ulimit -S -u 1 did not hold in the child"
else
  is "X21 the guard refreshes its stamp, so an assertion after a seen config change costs no fork" \
     "$(cat "$_gp/kid/tch/fork.err2" 2>/dev/null)|$(grep -c 'gp child: an assertion after the second probe' "$_gp/kid/tch/out")" "|1"
fi

# G04: the snapshot code is above TMP=.
_gx_a="$(grep -n '^_og_add "\$_og_start"' "$_gp_src" | head -1 | cut -d: -f1)"; _gx_b="$(grep -n '^TMP="\$(mktemp -d)"' "$_gp_src" | head -1 | cut -d: -f1)"
if [ -n "$_gx_a" ] && [ -n "$_gx_b" ] && [ "$_gx_a" -lt "$_gx_b" ]; then ok "X4 the snapshot is taken above TMP=\$(mktemp -d)"
else bad "X4 the snapshot is taken above TMP=\$(mktemp -d)" "snapshot at line [$_gx_a], TMP= at line [$_gx_b]"; fi

# L22, L23, L25 and L11b: lint shapes the synthetic files do not hold.
mkdir -p "$_gp/lint"
cat > "$_gp/lint/more" <<'GPLINT'
printf x | git -C "$S_pipe1" remote add o https://example.invalid/x.git
cd "$S_pipe2" |
  git config k v
case "$m" in a) cd "$S_case1" && git config k v ;; esac
case "$m" in a) git -C "$S_case2" config k v ;; esac
cd "$S_bs" \
  && git config k v
GPLINT
_gp_lint_is "X22 _fx_lint reads a git after |, a cd continued by a trailing |, a command right after a case pattern's ), and a cd continued by a backslash at top level" "$_gp/lint/more" 1
mkdir -p "$_gp/stubbin"; printf '#!/bin/sh\nexit 3\n' > "$_gp/stubbin/awk"; chmod 755 "$_gp/stubbin/awk"
_gx_o="$( PATH="$_gp/stubbin:$PATH"; _fx_lint "$_gp/lint/writes" 2>/dev/null; printf 'rc=%s' "$?" )"
is "X11 _fx_lint does not read a failed awk as a clean file" "$_gx_o" "rc=2"

printf '\nthe suite copies only a harness\n'
# The 18:04 incident on 2026-10-08: a section runner handed this file a harness
# path that did not exist, REAL_HARNESS came out empty, and the fixture copy ran
# as `cp -R /.`. Not written blind: the carrier ruled it into this branch after
# both blind rounds. Neither probe can copy anything if the check it tests is
# missing. The child is the suite's lines before `TMP=`, which read and never
# write, and the copy probe runs _copy_content with cp, tar and git shadowed.
# That copy wrote 123 GB before it was killed. Later the same day a runner whose
# own REAL_HARNESS landed above the driver's left it naming the runner's
# directory, and with the runner in TMPDIR the copy spent 48 minutes copying
# TMPDIR into itself. The driver's check refuses both.
_rh_src="$(_suite_flat)"
_rh="$TMP/real-harness-check"; mkdir -p "$_rh/cwd" "$_rh/bare" "$_rh/ok/lib"; : > "$_rh/ok/felix"
_rh_tl="$(grep -n '^TMP="\$(mktemp -d)"' "$_rh_src" | head -1 | cut -d: -f1)"
if [ -z "$_rh_tl" ]; then
  bad "tests/run exits 2 before it makes its temporary directory when REAL_HARNESS names no harness, and goes on when it names one" \
      "no TMP=\"\$(mktemp -d)\" line in $_rh_src"
else
  awk -v n="$_rh_tl" 'NR < n { print; if ($0 ~ /^REAL_HARNESS=/) print "REAL_HARNESS=\"$RH_H\"" } END { print "printf '"'"'survived\\n'"'"'" }' \
    "$_rh_src" > "$_rh/head.sh"
  _rh_one() {   # LABEL HARNESS -> LABEL:rc=N:said|survived|
    local o e rc
    o="$(cd "$_rh/cwd" && RH_H="$2" bash "$_rh/head.sh" 2>"$_rh/err")"; rc=$?
    case "$(cat "$_rh/err")" in "tests/run: REAL_HARNESS ["*"] is not a harness"*) e=said ;; *) e=quiet ;; esac
    printf '%s:rc=%s:%s|%s|' "$1" "$rc" "$e" "$o"
  }
  _rh_x="$(_rh_one empty ''; _rh_one missing "$_rh/missing"; _rh_one bare "$_rh/bare"; _rh_one root /; _rh_one ok "$_rh/ok")"
  is "tests/run exits 2 before it makes its temporary directory when REAL_HARNESS names no harness, and goes on when it names one" \
     "$_rh_x" "empty:rc=2:said||missing:rc=2:said||bare:rc=2:said||root:rc=2:said||ok:rc=0:quiet|survived|"
fi
awk '/^_copy_content\(\) \{/ { f = 1 } f { print } f && /^}$/ { exit }' "$_rh_src" > "$_rh/cc.sh"
mkdir -p "$_rh/src"
_rh_x="$(cd "$_rh/cwd" && RH="$_rh" bash -c '
  cp()  { printf "cp %s\n" "$*" >> "$RH/log"; }
  tar() { printf "tar %s\n" "$*" >> "$RH/log"; }
  git() { return 1; }
  . "$RH/cc.sh" || exit 9
  _copy_content "" "$RH/d-empty" 2>/dev/null; a=$?
  _copy_content "$RH/missing" "$RH/d-missing" 2>/dev/null; b=$?
  [ -s "$RH/log" ] && n=copied || n=none
  [ -e "$RH/d-empty" ] || [ -e "$RH/d-missing" ] && m=made || m=unmade
  _copy_content "$RH/src" "$RH/d-src"; c=$?
  printf "%s %s %s %s %s|%s" "$( [ "$a" != 0 ] && echo refused || echo rc=$a )" \
    "$( [ "$b" != 0 ] && echo refused || echo rc=$b )" "$n" "$m" "$c" "$(cat "$RH/log" 2>/dev/null)"')"
is "_copy_content copies nothing and makes no directory from a source that is empty or not a directory, and copies from one that is" \
   "$_rh_x" "refused refused none unmade 0|cp -R $_rh/src/. $_rh/d-src/"

