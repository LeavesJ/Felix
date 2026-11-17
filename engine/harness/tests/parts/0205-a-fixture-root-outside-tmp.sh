printf '\na fixture root outside $TMP\n'
# Parts 1100 and 1130 make their fixtures under a base whose every ancestor
# only root or this user can write. On a Linux runner $TMP sits under a shared
# /tmp, so they make that base elsewhere (XDG_RUNTIME_DIR, RUNNER_TEMP, HOME),
# outside $TMP, where _fx_cd and _fx_git would refuse every fixture line under
# it. _fx_root_add (part 0002) registers such a base as a root the guard
# accepts as it accepts $TMP, after proving it empty and no .git in it or above
# it, and _fx_root_del takes it back before the base is removed.
# Not blind: the carrier's ruling of 2026-10-13, when 3+3b met #431's and #434's
# parts on main, and its review. Every base sits in one directory beside $TMP,
# removed at the end. Each probe, and each registration made here, hands the
# guard a refusal record of its own, so nothing reaches the record the end of
# the run judges, and the roots are put back so no later part may touch more.
_fr_was="$_fx_roots"
_fr_P="$(mktemp -d "$TMP/../fx-roots.XXXXXX")"; _fr_P="$(cd "${_fr_P:?}" && pwd -P)"
_fr_rec() { : > "$TMP/fr-$1"; printf '%s' "$TMP/fr-$1"; }
_fr_why() { awk -F'\t' '{ printf "%s ", $NF }' "$1"; }
_fr_in() {   # RECORD DIR -> "in" when _fx_cd enters DIR, and the record's reasons
  printf '%s|%s' "$(FELIX_TEST_FXREFUSED="$1"; ( _fx_cd "$2" && printf in ) 2>/dev/null)" "$(_fr_why "$1")"
}
mkdir "$_fr_P/ok" "$_fr_P/okx" "$_fr_P/out" "$_fr_P/co" "$_fr_P/co/.git" "$_fr_P/co/inner" \
      "$_fr_P/full" "$_fr_P/full/repo" "$_fr_P/full/repo/.git" "$_fr_P/a:b"
_fr_ok="$_fr_P/ok"

# Unregistered, a directory outside $TMP is refused, as before.
is  "an unregistered directory outside \$TMP is refused by _fx_cd, as outside-tmp" \
    "$(_fr_in "$(_fr_rec unreg)" "$_fr_ok")" "|outside-tmp "

# Never roots: a name that is empty or not absolute, a path that is no
# directory, /, a name holding git's list separator, a base that already holds
# a checkout, and a base a .git stands above.
_fr_r="$(_fr_rec bad)"
( FELIX_TEST_FXREFUSED="$_fr_r"
  _fx_root_add ""; _fx_root_add ok; _fx_root_add -; _fx_root_add "$_fr_P/none"; _fx_root_add /
  _fx_root_add "$_fr_P/a:b"; _fx_root_add "$_fr_P/full"; _fx_root_add "$_fr_P/co/inner" ) 2>/dev/null
is  "_fx_root_add refuses each name that cannot be a root, with a record naming why" "$(_fr_why "$_fr_r")" \
    "root-not-absolute root-not-absolute root-not-absolute root-not-a-directory root-is-slash root-unsafe-name root-not-empty root-in-a-checkout "
is  "and none of them became a root: _fx_cd still refuses the full base's checkout and the base under a .git" \
    "$(_fr_in "$(_fr_rec full)" "$_fr_P/full/repo")/$(_fr_in "$(_fr_rec co)" "$_fr_P/co/inner")|$_fx_roots" \
    "|outside-tmp /|outside-tmp |$_fr_was"

# $TMP, and a directory below it, add nothing.
_fr_r="$(_fr_rec tmp)"
FELIX_TEST_FXREFUSED="$_fr_r" _fx_root_add "$TMP" 2>/dev/null
FELIX_TEST_FXREFUSED="$_fr_r" _fx_root_add "$TMP/cwd" 2>/dev/null
is  "_fx_root_add on \$TMP, and on a directory below it, adds no root and refuses nothing" \
    "$_fx_roots|$(cat "$_fr_r")" "$_fr_was|"

# Registered while empty, the base is a root: a directory below it is entered,
# git stops at it, and a write there runs.
_fr_r="$(_fr_rec reg)"
FELIX_TEST_FXREFUSED="$_fr_r" _fx_root_add "$_fr_ok" 2>/dev/null
mkdir "$_fr_ok/sub" "$_fr_ok/gf-out" "$_fr_ok/gf-in" "$_fr_ok/gd"
_fr_o="$(FELIX_TEST_FXREFUSED="$_fr_r"; ( _fx_cd "$_fr_ok/sub" && printf '%s|%s' "$(pwd -P)" "${GIT_CEILING_DIRECTORIES%%:*}" ) 2>/dev/null)"
is  "a registered base outside \$TMP is entered by _fx_cd, with git's ceiling at that base, and no refusal" \
    "$_fr_o|$(cat "$_fr_r")" "$_fr_ok/sub|$_fr_ok|"
_fr_o="$(FELIX_TEST_FXREFUSED="$_fr_r"; _fx_git "$_fr_ok/sub" init -q >/dev/null 2>&1; printf '%s' "$?")"
is  "and _fx_git runs a write there: git init makes the fixture's own repository" \
    "$_fr_o|$([ -d "$_fr_ok/sub/.git" ] && printf made)|$(cat "$_fr_r")" "0|made|"
_fr_n="$(printf '%s\n' "$_fx_roots" | grep -c .)"
FELIX_TEST_FXREFUSED="$_fr_r" _fx_root_add "$_fr_ok/sub" 2>/dev/null
is  "registering a directory below a root adds nothing" "$(printf '%s\n' "$_fx_roots" | grep -c .)|$(cat "$_fr_r")" "$_fr_n|"

# Strictly below, and below by path, not by name.
is  "the registered base itself is refused, as \$TMP itself is: a fixture stands strictly below its root" \
    "$(_fr_in "$(_fr_rec self)" "$_fr_ok")" "|outside-tmp "
is  "a sibling whose name starts with the base's name is refused" \
    "$(_fr_in "$(_fr_rec sib)" "$_fr_P/okx")" "|outside-tmp "

# A gitfile is proven against the root its directory lies below, and only that one.
printf 'gitdir: %s\n' "$_fr_P/out/.git" > "$_fr_ok/gf-out/.git"
printf 'gitdir: %s\n' "$_fr_ok/gd" > "$_fr_ok/gf-in/.git"
mkdir "$TMP/fr-gf-root" "$TMP/fr-gf-cd" "$TMP/fr-gd-cd" "$TMP/fr-gf-cdin" "$TMP/fr-gd-cdin"
printf 'gitdir: %s\n' "$_fr_ok/gd" > "$TMP/fr-gf-root/.git"
printf 'gitdir: %s\n' "$TMP/fr-gd-cd" > "$TMP/fr-gf-cd/.git"
printf '%s\n' "$_fr_P/out" > "$TMP/fr-gd-cd/commondir"
printf 'gitdir: %s\n' "$TMP/fr-gd-cdin" > "$TMP/fr-gf-cdin/.git"
printf '%s\n' "$TMP/fr-gd-cdin" > "$TMP/fr-gd-cdin/commondir"
is  "under the base, a gitfile naming a directory outside every root is refused, and one naming a directory below the base is entered" \
    "$(_fr_in "$(_fr_rec gfo)" "$_fr_ok/gf-out")/$(_fr_in "$(_fr_rec gfi)" "$_fr_ok/gf-in")" "|gitdir-outside /in|"
is  "under \$TMP, a gitfile naming a directory below the registered base is refused: one root never vouches for another" \
    "$(_fr_in "$(_fr_rec gfr)" "$TMP/fr-gf-root")" "|gitdir-outside "
is  "a gitfile's git directory whose commondir names a directory outside the root is refused, and one naming a directory inside is entered" \
    "$(_fr_in "$(_fr_rec gcd)" "$TMP/fr-gf-cd")/$(_fr_in "$(_fr_rec gci)" "$TMP/fr-gf-cdin")" "|gitdir-outside /in|"

# Taken back, the base is refused again, and $TMP is never taken back.
_fx_root_del "$TMP"
_fx_root_del "$_fr_ok"
is  "after _fx_root_del the roots are as they were, \$TMP kept, and the base is refused again" \
    "$_fx_roots/$(_fr_in "$(_fr_rec after)" "$_fr_ok/sub")" "$_fr_was/|outside-tmp "
_fx_roots="$_fr_was"
rm -rf "${_fr_P:?}" "$TMP"/fr-g[fd]-*
