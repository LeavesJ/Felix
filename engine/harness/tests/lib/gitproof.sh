# tests/lib/gitproof.sh: the fixture-git-proof stand-ins, children and helpers.
# Used by 0200 (builds them), 0201 and 0203 (the stand-in builder, the children
# and their readers; 0201 reads the child `same` 0200 ran, 0203 reads the child
# `url` 0201 ran). Moved from parts/0200-generated-constitution.sh:
# _gp_phys and _gp_get (lines 299-300), the stand-in builder script (315-333) and
# _gp_build and _gp_state (334-340), _gp_lint_is (778-783), the child helpers
# _gp_cutx, _gp_kid, _gp_run, _gp_rc, _gp_has, _gp_err, _gp_detail, _gp_samecfg
# and _gp_gone (831-834, 861-885) with the two child scripts (843-860); from
# parts/0201-continued.sh the child `url` (lines 31-43).
# Definitions only. Five builders, each guarded so that a later call in the
# serial run changes nothing:
#   _gitproof_base      the directory, its links, the stand-in builder and the
#                       stand-in home (_gp, _gp_home, _gp_homep, _gp_tmpp, _gp_url,
#                       _gp_start, _gp_rec0: the refusal record's length when the
#                       block began, kept once);
#   _gitproof_src       the suite as one file and the line of its first header;
#   _gitproof_kids      the child scripts, the harness copy and the no-checkout
#                       directory (_gp_hdr, _gp_mark, _gp_c5, _gp_c8, _gp_harness,
#                       _gp_none);
#   _gitproof_kid_same  the stand-in `stand-same` and the child `same` run in it;
#   _gitproof_kid_url   the stand-in `stand-url` and the child `url` run in it.
# _gitproof_build runs the first three, which every part after 0200 needs.

_gp_phys() { [ -n "${1:-}" ] && [ -d "$1" ] && ( cd -P "$1" && pwd -P ); }
_gp_get()  { printf '%s\n' "$1" | sed -n "s/^$2 //p"; }
_gp_build() { bash "$_gp/build.sh" "$1" "$TMP" "${2:-}" >/dev/null 2>&1; }
# What git reads in a stand-in, one key a line. Reads only.
_gp_state() {   # <checkout>
  printf 'url %s\n'  "$(git -C "$1" config --get remote.origin.url 2>/dev/null)"
  printf 'refs %s\n' "$(git -C "$1" for-each-ref refs/remotes/origin 2>/dev/null | wc -l | tr -d ' ')"
  printf 'up %s\n'   "$(git -C "$1" config --get branch.main.remote 2>/dev/null)"
}
_gp_lint_is() {   # <name> <file> <status wanted>
  local o rc
  if ! declare -F _fx_lint >/dev/null 2>&1; then bad "$1" "_fx_lint is not defined"; return 0; fi
  o="$(_fx_lint "$2" 2>/dev/null)"; rc=$?
  is "$1" "$o|rc=$rc" "$(grep -nE '\$\{?S_' "$2")|rc=$3"
}
_gp_cutx() {   # the lines from C5 and C8's header to the line before the marker
  GP_H="$_gp_hdr" GP_M="$_gp_mark" awk 'BEGIN { h = ENVIRON["GP_H"]; m = ENVIRON["GP_M"] }
    $0 == h { on = 1 } on && $0 == m { exit } on { print }' "$_gp_src"
}
_gp_kid() {   # <name> <cut: 0|1>, body on stdin: writes $_gp/kid/<name>/run
  local d="$_gp/kid/$1"; mkdir -p "$d"; cat > "$d/body.sh"
  { [ -n "$_gp_pre" ] && awk -v n="$_gp_pre" 'NR < n { print; if ($0 ~ /^REAL_HARNESS=/) print "REAL_HARNESS=\"$GP_HARNESS\"" }' "$_gp_src"
    cat "$_gp/kid-lib.sh" "$d/body.sh"
    if [ "$2" = 1 ]; then _gp_cutx; cat "$_gp/kid-tail.sh"; fi; } > "$d/run"
}
_gp_run() {   # <name> <start dir> [stand-in] [harness]: out, err and rc beside the child
  local d="$_gp/kid/$1"
  if [ -z "${2:-}" ] || [ ! -d "$2" ]; then printf 'not started' > "$d/err"; : > "$d/out"; printf 'x' > "$d/rc"; return 0; fi
  ( cd "$2" && GP_OUT="$d" GP_STAND="${3:-}" GP_TMPP="$_gp_tmpp" GP_HARNESS="${4:-$_gp_harness}" \
      bash "$d/run" > "$d/out" 2> "$d/err"; printf '%s' "$?" > "$d/rc" )
}
_gp_rc()   { cat "$_gp/kid/$1/rc" 2>/dev/null; }
_gp_has()  { grep -Fxq -- "$2" "$_gp/kid/$1/out" 2>/dev/null; }                 # <kid> <exact stdout line>
_gp_err()  { grep -c -- "^$2" "$_gp/kid/$1/err" 2>/dev/null | tr -d ' '; }      # <kid> <stderr line prefix>: how many
_gp_detail() {   # <kid> <assertion name>: what bad printed under it
  GP_N="  FAIL  $2" awk 'f && (/^  (ok|FAIL|skip)  / || /^gp-fail /) { exit } f { print } $0 == ENVIRON["GP_N"] { f = 1 }' \
    "$_gp/kid/$1/out" 2>/dev/null
}
_gp_samecfg() {   # <reported path> <stand-in>: the path is the stand-in's .git/config, physically
  [ "${1##*/}" = config ] && [ -n "$(_gp_phys "$2/.git")" ] && [ "$(_gp_phys "${1%/*}")" = "$(_gp_phys "$2/.git")" ]
}
_gp_gone() {   # <kid>: the child's $TMP no longer exists
  local t; t="$(cat "$_gp/kid/$1/tmp" 2>/dev/null)"; [ -n "$t" ] && [ ! -e "$t" ]
}

# _gitproof_base: the directory and what 0200:297-298, 301-306, 315-333 and 341 made.
_gitproof_base() {
  _gp="$TMP/fixture-git-proof"
  _gp_tmpp="$(_gp_phys "$TMP")"
  _gp_start="${_gp_start:-$(pwd -P)}"
  _gp_url="https://example.invalid/gp/stand-in.git"
  if [ -z "${_gp_rec0:-}" ]; then
    _gp_rec0=0
    [ -n "${FELIX_TEST_FXREFUSED:-}" ] && [ -f "$FELIX_TEST_FXREFUSED" ] \
      && _gp_rec0="$(wc -l < "$FELIX_TEST_FXREFUSED" | tr -d ' ')"
  fi
  if [ ! -f "$_gp/build.sh" ]; then
    mkdir -p "$_gp/plain" "$_gp/kid"
    : > "$_gp/afile"; ln -s / "$_gp/link-out"; ln -s "$_gp/plain" "$_gp/link-in"
# The stand-in builder. It refuses any target that is not physically under
# the directory it is given as $2, sheds the GIT_DIR family and GIT_CONFIG, and
# sets its own ceiling at the target's parent before git runs, so a failed
# `git init` cannot climb to a repository above. Each stand-in carries what
# the incident destroyed: an origin, a ref under refs/remotes/origin, and a
# branch whose upstream is origin. With "spare" it also gets a second remote
# with no refs. No fetch, so no URL is ever dialled.
cat > "$_gp/build.sh" <<'GPBUILD'
set -u
unset GIT_DIR GIT_WORK_TREE GIT_COMMON_DIR GIT_INDEX_FILE GIT_OBJECT_DIRECTORY GIT_ALTERNATE_OBJECT_DIRECTORIES GIT_CONFIG
[ -n "${1:-}" ] && [ -n "${2:-}" ] || exit 3
mkdir -p "$1/sub" || exit 3
t="$(cd -P "$2" && pwd -P)" && d="$(cd -P "$1" && pwd -P)" || exit 3
case "$d" in "$t"/?*) ;; *) exit 4 ;; esac
GIT_CEILING_DIRECTORIES="${d%/*}"; export GIT_CEILING_DIRECTORIES
cd "$d" || exit 3
git init -q -b main . >/dev/null 2>&1 && [ -d "$d/.git" ] || exit 5
[ "$(git rev-parse --absolute-git-dir 2>/dev/null)" = "$d/.git" ] || exit 6
git -c user.name=t -c user.email=t@t -c commit.gpgsign=false \
    commit -q --no-verify --allow-empty -m stand-in >/dev/null 2>&1 || exit 7
git remote add origin https://example.invalid/gp/stand-in.git || exit 8
git update-ref refs/remotes/origin/main HEAD || exit 8
git config branch.main.remote origin && git config branch.main.merge refs/heads/main || exit 8
if [ "${3:-}" = spare ]; then git remote add spare https://example.invalid/gp/spare.git || exit 8; fi
exit 0
GPBUILD
  fi
  _gp_home="$_gp/home"
  [ -d "$_gp_home/.git" ] || _gp_build "$_gp_home"
  _gp_homep="$(_gp_phys "$_gp_home")"
}

# _gitproof_src: the suite as one file (lib files inlined), and the line its first
# section header is on (0200:356-357).
_gitproof_src() {
  _gp_src="$(_suite_flat)"
  _gp_pre="$(grep -n "^printf '\\\\n" "$_gp_src" 2>/dev/null | head -1 | cut -d: -f1)"
}

# _gitproof_kids: what the children are made of (0200:827-830, 841-860).
_gitproof_kids() {
  _gp_hdr="printf '\\nthe run stayed inside its temporary directory\\n'"
  _gp_mark="printf '\\nreached\\n'"
  _gp_c5="no fixture git command was refused for a directory outside the suite's temporary directory"
  _gp_c8="the remotes of the checkout this run started in did not move while it ran"
  _gp_harness="$_gp/harness"; [ -d "$_gp_harness" ] || _copy_content "$REAL_HARNESS" "$_gp_harness"
  _gp_none="$_gp/none"; mkdir -p "$_gp_none"
  [ -f "$_gp/kid-tail.sh" ] && return 0
cat > "$_gp/kid-lib.sh" <<'GPKID'
# fixture git proof: what this child may do to its stand-in, and nothing else
_gpk_ok() {
  [ -n "${GP_STAND:-}" ] && [ -n "${GP_TMPP:-}" ] && [ -d "$GP_STAND/.git" ] || return 1
  case "$(cd -P "$GP_STAND" 2>/dev/null && pwd -P)/" in "$GP_TMPP"/?*) return 0 ;; esac
  return 1
}
_gpk_git() {
  _gpk_ok || { printf 'no stand-in [%s]\n' "${GP_STAND:-}" >> "$GP_OUT/kid.err"; return 3; }
  ( unset GIT_DIR GIT_WORK_TREE GIT_COMMON_DIR GIT_INDEX_FILE GIT_CONFIG
    git --git-dir="$GP_STAND/.git" "$@" ) >/dev/null 2>&1
}
printf '%s\n' "$TMP" > "$GP_OUT/tmp"
GPKID
cat > "$_gp/kid-tail.sh" <<'GPKID'
printf 'gp-fail %s\n' "$FAIL"
exit 0
GPKID
}

# _gitproof_build: base, src and kids, in that order.
_gitproof_build() { _gitproof_base; _gitproof_src; _gitproof_kids; }

# _gitproof_kid_same: the stand-in no remote moves in, and the child run in it
# (0200:907-916). 0201 reads its fork.limit, fork.err and out.
_gitproof_kid_same() {
  _gp_same="$_gp/stand-same"
  [ -f "$_gp/kid/same/rc" ] && return 0
  _gp_build "$_gp_same"
_gp_kid same 1 <<'GPKID'
ok "gp child: an assertion before anything else"
( ulimit -S -u 1 2>/dev/null || exit 0
  ulimit -S -u > "$GP_OUT/fork.limit"
  _ran "gp child: an assertion recorded with no fork available" 2> "$GP_OUT/fork.err" )
ok "gp child: an assertion after the fork probe"
true
GPKID
_gp_run same "$_gp_same/sub" "$_gp_same"
}

# _gitproof_kid_url: the stand-in whose origin the child moves twice, and the
# child run in it (0201:31-43). 0203 reads its origin-moved and out.
_gitproof_kid_url() {
  _gp_url1="$_gp/stand-url"
  [ -f "$_gp/kid/url/rc" ] && return 0
  _gp_build "$_gp_url1"
_gp_kid url 1 <<'GPKID'
ok "gp child: an assertion before the remote moves"
sleep 1
_gpk_git remote set-url origin https://example.invalid/gp/moved.git
ok "gp child: the first assertion after the remote moves"
sleep 1
_gpk_git remote set-url origin https://example.invalid/gp/moved-again.git
ok "gp child: the second assertion after the remote moves"
[ -e "$TMP/origin-moved" ] && cp "$TMP/origin-moved" "$GP_OUT/origin-moved"
true
GPKID
_gp_run url "$_gp_url1/sub" "$_gp_url1"
}
