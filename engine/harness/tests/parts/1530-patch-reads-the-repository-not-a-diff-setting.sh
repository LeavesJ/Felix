printf '\nwhat the engine reads from a patch is the repository'"'"'s, not a diff setting'"'"'s\n'
# Written blind, from the contract alone and before any implementation existed:
# "what the engine reads from a patch is the repository's, not a diff setting's"
# (felix-home, 2026-10-08, for claude/no-diff-drivers-in-parsed-diffs, stacked on
# claude/git-reads-fail-closed, ccb88d1d and then 34a1bc3a). Four readers parse
# or hash what porcelain `git diff` prints: secret-scan (S), felix_added_lines
# (A), _felix_escape_confined (C) and felix_tree_id (T). Porcelain diff hands the
# patch to an external diff or a driver's command when the repository names one,
# prints a textconv's output in place of the file, prints "Binary files differ"
# for a text file marked -diff, binary or binary=true or over
# core.bigFileThreshold, and names paths under whatever prefix and relative
# setting the configuration gives. On the stacked base each of those reaches the
# readers: a branch that commits a .gitattributes saying `*.txt -diff` blinds
# its own scan. The rule: what the readers read is the repository's content, and
# no setting moves it. The clause each assertion serves is named at its end in
# the contract's letters (D drivers, B binary marking, P paths, U a scan that
# could not read, N what does not move, L the lint). Those marked "as today" and
# the N1 controls pass on the stacked base by design, as the behaviour that must
# not move. Those marked (rule) go past the lettered clauses to the rule they
# serve: color.ui or color.diff set to always, and rename detection, each change
# what porcelain diff prints for a line the branch adds, and no clause names them;
# and under a driver, a floor raised in place is read as the confined change it
# is, which D4 alone would let a reader refuse by firing on every change.
#
# Every setting sits in the fixture repository's own config, its attribute in
# .git/info/attributes or in a .gitattributes the branch commits, or, for
# GIT_EXTERNAL_DIFF and GIT_CONFIG_COUNT, in the environment of the one call, so
# a case means the same on a runner whose global config is empty. Each fixture is
# a repository of its own under one directory; every git call there stands below
# it with GIT_CEILING_DIRECTORIES at it. A setting git turns out not to apply is
# a FAIL naming it, since a case it leaves untouched tests nothing, except a
# prefix setting older git does not know, which is a skip. Keys are assembled at
# run time, so this file never carries one. Every reader call runs under a time
# limit that is a guard against a hang, not a measurement.
#
# The probes and the readers run without GIT_CONFIG_PARAMETERS, where the
# driver puts its own colour pin (2026-10-17, carried with the colour change).
# Under the pin a porcelain git prints no colour whatever the repository says,
# so a colour case found nothing to test, and a reader would pass by the
# suite's setting rather than its own flags. A kind that needs the variable
# sets it in DDRE, which applies after it is removed.
DDR="$(mktemp -d "$TMP/ddr.XXXXXX" 2>/dev/null)" || DDR=""
if [ -n "$DDR" ] && [ -d "$DDR" ]; then DDR="$(cd -- "${DDR:?}" && pwd -P)"; fi
[ -n "$DDR" ] && [ -d "$DDR" ] || DDR="$TMP/ddr-missing"
DDRK="$(printf '%s%s' sk- QQQQQQQQQQQQQQQQQQQQQQQQ)"
DDRKL="$(printf '%s = "%s"' api_key "$DDRK")"
DDRAPP='the application, line one'
DDRCONF='^[-+]lib[a-z]*>=[0-9.]+$'
DDRGIT="$(type -P git)"
DDRFX=""; DDRSKIP=""; DDRA=""; DDRR=""; DDRE=()

# An external diff that prints a made-up patch for any path, a floor raised in
# place; a textconv that reads any file naming evil as one floor and every other
# file as another; and, for U2, a git that runs as git every read the stacked
# base's readers make and fails partway every other one.
DDRFAKE="$DDR/made-up-patch"; DDRTC="$DDR/rewrite-textconv"
cat 2>/dev/null > "$DDRFAKE" <<'EOF'
#!/bin/sh
printf 'diff --git a/%s b/%s\n--- a/%s\n+++ b/%s\n@@ -1 +1 @@\n-liba>=1.0\n+liba>=2.0\n' "$1" "$1" "$1" "$1"
EOF
cat 2>/dev/null > "$DDRTC" <<'EOF'
#!/bin/sh
if grep -q evil "$1"; then printf 'liba>=2.0\n'; else printf 'liba>=1.0\n'; fi
EOF
mkdir "$DDR/fakegit" 2>/dev/null
cat 2>/dev/null > "$DDR/fakegit/git" <<'EOF'
#!/bin/sh
# A read the stacked base makes runs as git: rev-parse, merge-base, merge-tree,
# hash-object, config, `ls-files --others`, and a content diff up to the base's
# count of them. Any other read, a listing, a content check or a content diff
# past that count, prints the first half of what git would and exits 128.
skip=0; sub=""
for a do
  if [ "$skip" = 1 ]; then skip=0; continue; fi
  case "$a" in
    -C|-c|--git-dir|--work-tree|--namespace|--exec-path|--super-prefix|--config-env) skip=1 ;;
    -*) ;;
    *) sub="$a"; break ;;
  esac
done
pass=0
case "$sub" in
  rev-parse|merge-base|merge-tree|hash-object|config|version|var|"") pass=1 ;;
  ls-files) for a do case "$a" in -o|--others) pass=1 ;; esac; done ;;
  diff)
    pass=1
    for a do
      case "$a" in
        --numstat|--name-only|--name-status|--raw|--stat|--stat=*|--shortstat|--summary|--check|--dirstat|--dirstat=*|--quiet|--exit-code) pass=0 ;;
      esac
    done
    if [ "$pass" = 1 ]; then
      n=$(( $(cat "$DDR_FAKE_N" 2>/dev/null || echo 0) + 1 ))
      printf '%s\n' "$n" > "$DDR_FAKE_N"
      [ "$n" -le "$DDR_FAKE_K" ] || pass=0
    fi ;;
esac
[ "$pass" = 1 ] && exec "$DDR_REAL_GIT" "$@"
printf '%s\n' "$*" >> "$DDR_FAKE_LOG"
out="$("$DDR_REAL_GIT" "$@" 2>/dev/null)"
n="$(printf '%s\n' "$out" | wc -l)"; h=$(( n / 2 ))
[ "$h" -gt 0 ] && printf '%s\n' "$out" | head -n "$h"
printf 'fatal: this read was made to fail partway\n' >&2
exit 128
EOF
chmod +x "$DDRFAKE" "$DDRTC" "$DDR/fakegit/git" 2>/dev/null

_ddr_g() { git -c user.name=ddr -c user.email=ddr@example.invalid -c commit.gpgsign=false "$@"; }
# A snippet in a shell of its own standing in the repository, under the
# ceiling; a failure says which fixture step it was, once.
_ddr_in() {   # repo snippet [reason]
  ( cd -- "${1:?}" && GIT_CEILING_DIRECTORIES="${DDR:?}" && export GIT_CEILING_DIRECTORIES && eval "$2" ) >/dev/null 2>&1 \
    || { [ -n "$DDRFX" ] || DDRFX="${3:-a step in ${1##*/} failed: $2}"; }
}
# main holds app.txt and deps.txt in one commit. When it cannot be made, DDRR
# names a directory that does not exist, so nothing below writes anywhere else.
_ddr_dir() {   # tag -> DDRR, an empty directory of its own
  local d
  DDRFX=""; DDRSKIP=""
  d="$(mktemp -d "$DDR/$1.XXXXXX" 2>/dev/null)" && [ -n "$d" ] && d="$(cd -- "${d:?}" && pwd -P)" && [ -n "$d" ] \
    && DDRR="$d" && return 0
  DDRR="$DDR/missing-$1"; DDRFX="the directory for $1 could not be made"; return 1
}
_ddr_new() {   # tag -> DDRR
  _ddr_dir "$1" || return 0
  _ddr_in "$DDRR" 'git init -q -b main && printf "%s\n" "$DDRAPP" > app.txt && printf "liba>=1.0\n" > deps.txt \
    && _ddr_g add -A && _ddr_g commit -qm base' "the repository for $1 could not be made"
}
# No commit, app.txt holding the key and not yet added.
_ddr_unborn() {   # tag -> DDRR
  _ddr_dir "$1" || return 0
  _ddr_in "$DDRR" 'git init -q -b main && printf "%s\n%s\n" "$DDRAPP" "$DDRKL" > app.txt' \
    "the unborn repository for $1 could not be made"
}
# The kind's setting, where the contract puts it. A .gitattributes the branch
# commits is committed on the branch, or only staged when there is no commit.
_ddr_set() {   # repo kind [unborn]
  local c="" a="" w=""
  DDRE=()
  case "$2" in
    ext-true)     c='_ddr_g config diff.external true' ;;
    ext-fake)     c='_ddr_g config diff.external "$DDRFAKE"' ;;
    env-ext)      DDRE=(GIT_EXTERNAL_DIFF="$DDRFAKE") ;;
    cnt-ext)      DDRE=(GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=diff.external GIT_CONFIG_VALUE_0="$DDRFAKE") ;;
    drv-cmd)      a='*.txt diff=ddr'; w=info;   c='_ddr_g config diff.ddr.command "$DDRFAKE"' ;;
    tc-empty)     a='*.txt diff=ddr'; w=info;   c='_ddr_g config diff.ddr.textconv "sed d"' ;;
    tc-empty-c)   a='*.txt diff=ddr'; w=commit; c='_ddr_g config diff.ddr.textconv "sed d"' ;;
    tc-rewrite)   a='*.txt diff=ddr'; w=info;   c='_ddr_g config diff.ddr.textconv "$DDRTC"' ;;
    tc-rewrite-c) a='*.txt diff=ddr'; w=commit; c='_ddr_g config diff.ddr.textconv "$DDRTC"' ;;
    nodiff)       a='*.txt -diff';    w=info ;;
    nodiff-c)     a='*.txt -diff';    w=commit ;;
    binary-c)     a='*.txt binary';   w=commit ;;
    attrfile)     a='*.txt -diff';    w=file;   c='_ddr_g config core.attributesFile "$PWD/.git/ddr-attributes"' ;;
    drv-binary)   a='*.txt diff=ddr'; w=info;   c='_ddr_g config diff.ddr.binary true' ;;
    bigfile)      c='_ddr_g config core.bigFileThreshold 16' ;;
    color-ui)     c='_ddr_g config color.ui always' ;;
    color-diff)   c='_ddr_g config color.diff always' ;;
  esac
  DDRA="$a"
  [ -z "$c" ] || _ddr_in "$1" "$c" "the setting for $2 could not be made"
  case "$w" in
    info) _ddr_in "$1" 'mkdir -p .git/info && printf "%s\n" "$DDRA" > .git/info/attributes' ;;
    file) _ddr_in "$1" 'printf "%s\n" "$DDRA" > .git/ddr-attributes' ;;
    commit)
      if [ "${3:-}" = unborn ]; then _ddr_in "$1" 'printf "%s\n" "$DDRA" > .gitattributes && _ddr_g add .gitattributes'
      else _ddr_in "$1" 'printf "%s\n" "$DDRA" > .gitattributes && _ddr_g add .gitattributes && _ddr_g commit -qm attributes'; fi ;;
  esac
}
_ddr_unset() {   # repo kind: the kind's setting taken away again, where it is not content
  DDRE=()
  case "$2" in
    ext-true|ext-fake)           _ddr_in "$1" '_ddr_g config --unset diff.external' ;;
    drv-cmd|tc-empty|tc-rewrite) _ddr_in "$1" ': > .git/info/attributes' ;;
  esac
}
# Porcelain git diff over an edit to app.txt must print something other than
# the plain patch, or the setting is not in force here and the case tests nothing.
_ddr_probe() {   # repo kind
  local v
  [ -n "$DDRFX" ] && return 0
  v="$( _fx_cd "${1:?}" && GIT_CEILING_DIRECTORIES="${DDR:?}" && export GIT_CEILING_DIRECTORIES \
        && printf 'probe\n' >> app.txt \
        && p="$(env -u GIT_CONFIG_PARAMETERS ${DDRE[@]+"${DDRE[@]}"} git diff 2>&1)" \
        && q="$(git diff --no-ext-diff --no-textconv --no-color --text 2>&1)" \
        && git checkout -q -- app.txt && [ -n "$q" ] && if [ "$p" = "$q" ]; then echo same; else echo moved; fi )"
  [ "$v" = moved ] || DDRFX="porcelain git diff here prints the plain patch under $2, so nothing is tested"
}
# The porcelain diff named must hold the text named, or the setting is unknown to this git.
_ddr_effect() {   # dir text git-args...: sets DDRSKIP when the text is absent
  local d="$1" t="$2" v; shift 2
  [ -n "$DDRFX" ] && return 0
  v="$( _fx_cd "${d:?}" && GIT_CEILING_DIRECTORIES="${DDR:?}" && export GIT_CEILING_DIRECTORIES \
        && env -u GIT_CONFIG_PARAMETERS git "$@" 2>&1 )"
  case "$v" in *"$t"*) ;; *) DDRSKIP="this git prints no [$t] for git $*, so it does not apply the setting" ;; esac
}

# The readers, each standing in a directory under the ceiling, with the kind's environment.
_ddr_scan() {   # dir args... -> secret-scan's status
  local d="$1"; shift
  ( cd -- "${d:?}" && GIT_CEILING_DIRECTORIES="${DDR:?}" && export GIT_CEILING_DIRECTORIES \
      && env -u GIT_CONFIG_PARAMETERS ${DDRE[@]+"${DDRE[@]}"} perl -e 'alarm shift; exec @ARGV or exit 127' 300 \
           "$FROOT/harness/bin/secret-scan" "$@" ) >/dev/null 2>"$DDR/scan.err"
}
_ddr_sh() {   # dir snippet args...: the snippet sees the harness as $1 and the arguments after it
  local d="$1" c="$2"; shift 2
  ( cd -- "${d:?}" && GIT_CEILING_DIRECTORIES="${DDR:?}" && export GIT_CEILING_DIRECTORIES \
      && env -u GIT_CONFIG_PARAMETERS ${DDRE[@]+"${DDRE[@]}"} perl -e 'alarm shift; exec @ARGV or exit 127' 300 \
           bash -c "$c" _ "$FROOT/harness" "$@" ) 2>/dev/null
}
_ddr_added()   { _ddr_sh "$1" 'set -o pipefail; . "$1/lib/resolve.sh"; felix_added_lines "$2" "${3:-}"' "$1" "${2:-}"; }
_ddr_changed() { _ddr_sh "$1" 'set -o pipefail; . "$1/lib/resolve.sh"; felix_changed_paths "$2" "${3:-}"' "$1" "${2:-}"; }
_ddr_tid()     { _ddr_sh "$1" 'set -u; . "$1/lib/resolve.sh"; . "$1/lib/verify.sh"; felix_tree_id "$2"' "$1"; }
_ddr_conf() {   # root base file confine
  _ddr_sh "$1" 'set -u; . "$1/lib/resolve.sh"; . "$1/lib/verify.sh"; . "$1/lib/escape.sh"
    _felix_escape_confined "$2" "$3" "$4" "$5"' "$1" "$2" "$3" "$4"
}
# The id the stacked base's felix_tree_id (34a1bc3a) gives a tree with no home,
# computed here from git by the same recipe: HEAD and the diff against it, or
# `unborn` and the staged diff (when there is one) above the unstaged one; then
# size and mtime of each untracked file, listed with quotePath off; hashed as one
# document. origin/main left the staged diff out, so its id of an unborn HEAD
# with something staged is not this one.
_ddr_recipe() {   # root
  ( _fx_cd "${1:?}" && GIT_CEILING_DIRECTORIES="${DDR:?}" && export GIT_CEILING_DIRECTORIES || exit 1
    head="$(git rev-parse HEAD 2>/dev/null)" || head=""
    if [ -z "$head" ]; then
      head=unborn; diff="$(git diff -- . 2>/dev/null)"; cached="$(git diff --cached -- . 2>/dev/null)"
      [ -z "$cached" ] || diff="$cached
$diff"
    else diff="$(git diff HEAD -- . 2>/dev/null)"; fi
    un="$(git -c core.quotePath=false ls-files --others --exclude-standard -- . 2>/dev/null | LC_ALL=C sort)"; meta=""
    if [ -n "$un" ]; then
      files=()
      while IFS= read -r f; do [ -n "$f" ] && files+=("$PWD/$f"); done <<EOF
$un
EOF
      if stat -c '%s' /dev/null >/dev/null 2>&1; then meta="$(stat -c '%n %s %Y' "${files[@]}" 2>/dev/null)"
      else meta="$(stat -f '%N %z %m' "${files[@]}" 2>/dev/null)"; fi
    fi
    printf '%s\n%s\n%s' "$head" "$diff" "$meta" | git hash-object --stdin )
}

_ddr_is() {
  if [ -n "$DDRFX" ]; then bad "$1" "the fixture was not built: $DDRFX"
  elif [ -n "$DDRSKIP" ]; then skip "$1" "$DDRSKIP"
  else is "$1" "$2" "$3"; fi
}
_ddr_nz()    { if [ "$1" -ne 0 ]; then printf 'non-zero'; else printf 'exit 0'; fi; }
_ddr_line()  { printf '%s\n' "$1" | DDRL="$2" awk '$0 == ENVIRON["DDRL"] { f = 1 } END { print (f ? "printed" : "not printed") }'; }
_ddr_holds() { case "$1" in *"$2"*) printf 'holds' ;; *) printf 'lacks' ;; esac; }
_ddr_two()   { if [ -z "$1" ] || [ -z "$2" ]; then printf 'no id'; elif [ "$1" = "$2" ]; then printf 'same'; else printf 'differ'; fi; }
_ddr_unpipe() {   # path: whatever waits on the pipe is let go, then it is removed
  [ -p "$1" ] || return 0
  perl -e 'use Fcntl; sysopen(my $r, $ARGV[0], O_RDONLY|O_NONBLOCK); sysopen(my $w, $ARGV[0], O_WRONLY|O_NONBLOCK); close $w if $w; close $r if $r' "$1" 2>/dev/null
  unlink "$1" 2>/dev/null
}

# ------------------------------------------------- one setting, every reader ----
# The branch is cut from main, the setting put in place, then a key appended to
# app.txt: committed, then staged (the commit undone, soft), then unstaged (the
# index reset). S and A read each. Then deps.txt has its floor swapped for
# another package, which C must not call confined; then T is asked about the
# clean tree, one edit and another; then, under a binary marking or none, a file
# binary by content is committed with a key past its NUL; then a key staged in a
# fresh repository with no commit, under the same setting.
_ddr_battery() {   # kind class label
  local k="$1" c="$2" l="$3" cs="" ca="" ct="" cc="" cr="" R="" rc=0 out="" t0="" t1="" t2="" t3="" r0="" r2=""
  case "$c" in
    D) cs=D1 ca=D2 ct=D3 cc=D4 cr=rule ;;
    B) cs=B1 ca=B2 ct=B4 ;;
    N) cs=N1 ca=N1 ct=N1 cc=N1 cr=N1 ;;
    R) cs=rule ca=rule ;;
  esac
  _ddr_new "$k"; R="$DDRR"
  _ddr_in "$R" '_ddr_g checkout -q -b feat'
  _ddr_set "$R" "$k"
  [ "$c" = N ] || _ddr_probe "$R" "$k"

  _ddr_in "$R" 'printf "%s\n" "$DDRKL" >> app.txt && _ddr_g commit -qam key'
  _ddr_scan "$R" main; rc=$?
  _ddr_is "$l, secret-scan finds a key the branch committed to a text file, exit 1 ($cs)" "$rc" 1
  out="$(_ddr_added "$R" main)"
  if [ "$c" = N ]; then _ddr_is "$l, felix_added_lines prints exactly the committed line, as today ($ca)" "$out" "+$DDRKL"
  else _ddr_is "$l, felix_added_lines prints the line the branch committed ($ca)" "$(_ddr_line "$out" "+$DDRKL")" printed; fi
  case "$k" in ext-fake|nodiff)
    _ddr_is "$l, felix_changed_paths still lists app.txt, as today (N2)" "$(_ddr_line "$(_ddr_changed "$R" main)" app.txt)" printed ;;
  esac

  _ddr_in "$R" '_ddr_g reset -q --soft HEAD~1'
  _ddr_scan "$R" main; rc=$?
  _ddr_is "$l, secret-scan finds the same key staged, exit 1 ($cs)" "$rc" 1
  out="$(_ddr_added "$R" main)"
  if [ "$c" = N ]; then _ddr_is "$l, felix_added_lines prints exactly the staged line, as today ($ca)" "$out" "+$DDRKL"
  else _ddr_is "$l, felix_added_lines prints the staged line ($ca)" "$(_ddr_line "$out" "+$DDRKL")" printed; fi

  _ddr_in "$R" '_ddr_g reset -q'
  _ddr_scan "$R" main; rc=$?
  _ddr_is "$l, secret-scan finds the same key unstaged, exit 1 ($cs)" "$rc" 1
  out="$(_ddr_added "$R" main)"
  if [ "$c" = N ]; then _ddr_is "$l, felix_added_lines prints exactly the unstaged line, as today ($ca)" "$out" "+$DDRKL"
  else _ddr_is "$l, felix_added_lines prints the unstaged line ($ca)" "$(_ddr_line "$out" "+$DDRKL")" printed; fi

  if [ "$c" = D ] || [ "$c" = N ]; then
    # D4's example: deps.txt confined to a floor's shape. The branch swaps the
    # package; a textconv reads the old file as liba>=1.0 and the new as
    # liba>=2.0, and the made-up patch prints the same pair.
    _ddr_in "$R" '_ddr_g checkout -q -- . && printf "evilpkg>=1.0\n" > deps.txt && _ddr_g commit -qam swap'
    _ddr_conf "$R" main deps.txt "$DDRCONF"; rc=$?
    _ddr_is "$l, a floor the branch swapped for another package is not called confined, so the row fires ($cc)" "$rc" 1
    _ddr_in "$R" '_ddr_g reset -q HEAD~1 && printf "liba>=1.1\n" > deps.txt'
    _ddr_conf "$R" main deps.txt "$DDRCONF"; rc=$?
    _ddr_is "$l, a floor raised in place, unstaged, is read as confined and the row demoted ($cr)" "$rc" 0
  fi

  if [ "$c" != R ]; then
    _ddr_in "$R" '_ddr_g checkout -q -- .'
    t0="$(_ddr_tid "$R")"; [ "$c" = N ] && r0="$(_ddr_recipe "$R")"
    _ddr_in "$R" 'printf "edit one\n" >> app.txt'
    t1="$(_ddr_tid "$R")"
    _ddr_is "$l, felix_tree_id tells the clean tree from one with app.txt edited ($ct)" "$(_ddr_two "$t0" "$t1")" differ
    if [ "$c" != B ]; then
      _ddr_in "$R" 'printf "%s\nedit two\n" "$DDRAPP" > app.txt'
      t2="$(_ddr_tid "$R")"; [ "$c" = N ] && r2="$(_ddr_recipe "$R")"
      _ddr_is "$l, and tells two different edits of app.txt apart ($ct)" "$(_ddr_two "$t1" "$t2")" differ
    fi
    if [ "$c" = N ]; then
      _ddr_is "$l, felix_tree_id of the clean tree is the stacked base's, byte for byte (N1)" "$t0" "$r0"
      _ddr_is "$l, and of the edited tree too (N1)" "$t2" "$r2"
    fi
    case "$k" in ext-true|ext-fake|env-ext|cnt-ext|drv-cmd|tc-empty|tc-rewrite)
      _ddr_unset "$R" "$k"; t3="$(_ddr_tid "$R")"
      _ddr_is "$l, the edited tree's id is the one it has once the setting is taken away (D3)" "$(_ddr_two "$t2" "$t3")" same ;;
    esac
  fi

  if [ "$c" = B ] || [ "$c" = N ]; then
    _ddr_in "$R" '_ddr_g checkout -q -- . && { printf "x\000y\n"; printf "ddr-binary-marker\n"; printf "%s\n" "$DDRKL"; } > blob.txt \
      && ! LC_ALL=C tr -d "\000" < blob.txt | cmp -s - blob.txt && _ddr_g add blob.txt && _ddr_g commit -qm blob' \
      "no file holding a NUL could be committed for $k"
    _ddr_scan "$R" main; rc=$?
    _ddr_is "$l, a key past the NUL of a file the branch committed, binary by content, is not flagged, exit 0, as today (B3)" "$rc" 0
    out="$(_ddr_added "$R" main)"
    _ddr_is "$l, and felix_added_lines prints no line of that file, as today (B3)" "$(_ddr_holds "$out" ddr-binary-marker)" lacks
    if [ "$c" = N ]; then
      _ddr_in "$R" '{ printf "more\000\n"; printf "ddr-binary-marker-two\n"; printf "%s\n" "$DDRKL"; } >> blob.txt'
      _ddr_scan "$R" main; rc=$?
      _ddr_is "$l, nor a key appended past a NUL and left unstaged, exit 0, as today (B3)" "$rc" 0
      out="$(_ddr_added "$R" main)"
      _ddr_is "$l, and felix_added_lines prints none of that either, as today (B3)" "$(_ddr_holds "$out" ddr-binary-marker-two)" lacks
      _ddr_is "$l, felix_tree_id of a tree with a binary file edited is the stacked base's (N1)" "$(_ddr_tid "$R")" "$(_ddr_recipe "$R")"
      _ddr_in "$R" 'printf "u\n" > untracked.txt'
      _ddr_is "$l, and with an untracked file beside it too (N1)" "$(_ddr_tid "$R")" "$(_ddr_recipe "$R")"
    fi
    _ddr_unborn "$k-unborn"; R="$DDRR"
    _ddr_set "$R" "$k" unborn
    _ddr_in "$R" '_ddr_g add -A && ! git rev-parse -q --verify HEAD' "the unborn repository for $k has a commit"
    [ "$c" = N ] || _ddr_probe "$R" "$k"
    _ddr_scan "$R"; rc=$?
    _ddr_is "$l, secret-scan finds a key staged on an unborn HEAD, exit 1 ($cs)" "$rc" 1
    [ "$c" = N ] && _ddr_is "$l, felix_tree_id of an unborn HEAD is the stacked base's (N1)" "$(_ddr_tid "$R")" "$(_ddr_recipe "$R")"
  fi
  DDRE=()
}

# A branch whose base moved after it was cut, so felix_added_lines reads the
# committed side through the two refs _felix_merge_refs prints.
_ddr_stacked() {   # kind class label clause
  local R out
  _ddr_new "st-$1"; R="$DDRR"
  _ddr_in "$R" '_ddr_g checkout -q -b feat'
  _ddr_set "$R" "$1"
  [ "$2" = N ] || _ddr_probe "$R" "$1"
  _ddr_in "$R" 'printf "%s\n" "$DDRKL" >> app.txt && _ddr_g commit -qam key && _ddr_g checkout -q main \
    && printf "other\n" > other.md && _ddr_g add other.md && _ddr_g commit -qm other && _ddr_g checkout -q feat'
  [ -n "$DDRFX" ] || _ddr_sh "$R" '. "$1/lib/resolve.sh"; _felix_merge_refs "$2" main >/dev/null' "$R" \
    || DDRFX="the stacked branch does not take the merge-tree path here"
  out="$(_ddr_added "$R" main)"
  _ddr_is "$3, on a branch whose base moved on, felix_added_lines prints the committed line through the merge-tree refs ($4)" \
          "$(_ddr_line "$out" "+$DDRKL")" printed
  DDRE=()
}

_ddr_battery none N "with no diff setting"
_ddr_battery ext-true D "under diff.external naming true"
_ddr_battery ext-fake D "under diff.external naming a program that prints a made-up patch"
_ddr_battery env-ext D "under GIT_EXTERNAL_DIFF naming that program in the reader's environment"
_ddr_battery cnt-ext D "under diff.external carried in GIT_CONFIG_COUNT"
_ddr_battery drv-cmd D "under a diff driver whose command is that program, its attribute in .git/info/attributes"
_ddr_battery tc-empty D "under a textconv that prints nothing, its attribute in .git/info/attributes"
_ddr_battery tc-empty-c D "under a textconv that prints nothing, its attribute in a .gitattributes the branch commits"
_ddr_battery tc-rewrite D "under a textconv that rewrites the content, its attribute in .git/info/attributes"
_ddr_battery tc-rewrite-c D "under a textconv that rewrites the content, its attribute in a .gitattributes the branch commits"
_ddr_battery nodiff B "under -diff in .git/info/attributes"
_ddr_battery nodiff-c B "under -diff in a .gitattributes the branch commits"
_ddr_battery binary-c B "under binary in a .gitattributes the branch commits"
_ddr_battery attrfile B "under -diff in the file core.attributesFile names"
_ddr_battery drv-binary B "under a diff driver set binary=true"
_ddr_battery bigfile B "under core.bigFileThreshold below the file's size"
_ddr_battery color-ui R "under color.ui=always"
_ddr_battery color-diff R "under color.diff=always"

_ddr_stacked none N "with no diff setting" N1
_ddr_stacked ext-fake D "under diff.external naming a made-up patch" D2
_ddr_stacked tc-rewrite D "under a textconv that rewrites the content" D2
_ddr_stacked nodiff B "under -diff in .git/info/attributes" B2

# B3's line is git's own: a NUL within the first 8000 bytes. A file whose only
# NUL lies past them is text to git, and so must be text under a marking too.
_ddr_late() {   # kind label clause expect
  local R rc
  _ddr_new "late-$1"; R="$DDRR"
  _ddr_in "$R" '_ddr_g checkout -q -b feat'
  if [ "$1" != none ]; then _ddr_set "$R" "$1"; _ddr_probe "$R" "$1"; fi
  _ddr_in "$R" '{ printf "%s\n" "$DDRKL"; i=0; while [ "$i" -lt 150 ]; do printf "filler, to push the one NUL past the first eight thousand bytes\n"; i=$((i + 1)); done
      printf "late\000nul\n"; } > late.txt \
    && [ "$(head -c 8000 late.txt | LC_ALL=C tr -d "\000" | wc -c)" -eq 8000 ] && ! LC_ALL=C tr -d "\000" < late.txt | cmp -s - late.txt \
    && _ddr_g add late.txt && _ddr_g commit -qm late' "late.txt could not be made with its one NUL past byte 8000"
  _ddr_scan "$R" main; rc=$?
  _ddr_is "$2, a key in a file whose only NUL lies past its first 8000 bytes is found, exit 1 ($3)" "$rc" 1
}
_ddr_late none "with no diff setting" "B3"
_ddr_late nodiff "under -diff in .git/info/attributes" "B1"

# -------------------------------------------------- P: paths in secret-scan ----
# main also holds creds.py, fixtures/creds.py, a_fixtures/creds.py,
# testdata/creds.py, creds.example, creds.sample and sub/s.txt, harmless, and
# the branch is checked out.
_ddr_pnew() {   # tag -> DDRR
  _ddr_new "$1"
  _ddr_in "$DDRR" 'mkdir -p fixtures a_fixtures testdata sub \
    && for f in creds.py fixtures/creds.py a_fixtures/creds.py testdata/creds.py creds.example creds.sample sub/s.txt; do
         printf "harmless = 1\n" > "$f" || exit 1; done \
    && _ddr_g add -A && _ddr_g commit -qm paths && _ddr_g checkout -q -b feat'
}
_ddr_key() { _ddr_in "$1" 'for f in '"$2"'; do printf "%s\n" "$DDRKL" >> "$f" || exit 1; done'; }

_ddr_pnew p1-dst; DDRPR="$DDRR"
_ddr_in "$DDRPR" '_ddr_g config diff.dstPrefix b/fixtures/'
_ddr_key "$DDRPR" creds.py; _ddr_in "$DDRPR" '_ddr_g commit -qam key'
_ddr_effect "$DDRPR" "+++ b/fixtures/creds.py" diff main...HEAD
_ddr_scan "$DDRPR" main; DDRRC=$?
_ddr_is "under diff.dstPrefix=b/fixtures/, a key the branch committed to creds.py is judged as creds.py, exit 1 (P1)" "$DDRRC" 1
_ddr_in "$DDRPR" '_ddr_g reset -q --soft HEAD~1'
_ddr_scan "$DDRPR" main; DDRRC=$?
_ddr_is "under diff.dstPrefix=b/fixtures/, and the same key staged, exit 1 (P1)" "$DDRRC" 1
_ddr_in "$DDRPR" '_ddr_g reset -q'
_ddr_scan "$DDRPR" main; DDRRC=$?
_ddr_is "under diff.dstPrefix=b/fixtures/, and the same key unstaged, exit 1 (P1)" "$DDRRC" 1

_ddr_pnew p1-srcprefix; DDRPR="$DDRR"
_ddr_in "$DDRPR" '_ddr_g config diff.srcPrefix QQQ/'
_ddr_key "$DDRPR" creds.py; _ddr_in "$DDRPR" '_ddr_g commit -qam key'
_ddr_effect "$DDRPR" "--- QQQ/creds.py" diff main...HEAD
_ddr_scan "$DDRPR" main; DDRRC=$?
_ddr_is "under diff.srcPrefix=QQQ/, a key the branch committed to creds.py is found, exit 1, as today (P1)" "$DDRRC" 1

_ddr_pnew p1-noprefix; DDRPR="$DDRR"
_ddr_in "$DDRPR" '_ddr_g config diff.noprefix true'
_ddr_key "$DDRPR" a_fixtures/creds.py; _ddr_in "$DDRPR" '_ddr_g commit -qam key'
_ddr_effect "$DDRPR" "+++ a_fixtures/creds.py" diff main...HEAD
_ddr_scan "$DDRPR" main; DDRRC=$?
_ddr_is "under diff.noprefix, a key committed to a_fixtures/creds.py, not a fixtures directory, is found, exit 1 (P1)" "$DDRRC" 1

_ddr_pnew p1-noprefix-fx; DDRPR="$DDRR"
_ddr_in "$DDRPR" '_ddr_g config diff.noprefix true'
_ddr_key "$DDRPR" fixtures/creds.py; _ddr_in "$DDRPR" '_ddr_g commit -qam key'
_ddr_effect "$DDRPR" "+++ fixtures/creds.py" diff main...HEAD
_ddr_scan "$DDRPR" main; DDRRC=$?
_ddr_is "under diff.noprefix, a key committed to a real fixtures/creds.py is still excluded, exit 0 (P1)" "$DDRRC" 0

_ddr_pnew p1-mnemonic; DDRPR="$DDRR"
_ddr_in "$DDRPR" '_ddr_g config diff.mnemonicPrefix true'
_ddr_key "$DDRPR" fixtures/creds.py
_ddr_effect "$DDRPR" "+++ w/fixtures/creds.py" diff HEAD
_ddr_scan "$DDRPR" main; DDRRC=$?
_ddr_is "under diff.mnemonicPrefix, an unstaged key in fixtures/creds.py is excluded, exit 0, as today (P1)" "$DDRRC" 0
_ddr_key "$DDRPR" creds.py
_ddr_scan "$DDRPR" main; DDRRC=$?
_ddr_is "under diff.mnemonicPrefix, and one in creds.py beside it is found, exit 1, as today (P1)" "$DDRRC" 1

# The path a line is judged against is git's from the top of the work tree,
# whichever directory the scan is run from.
_ddr_pnew p1-relative-fx; DDRPR="$DDRR"
_ddr_in "$DDRPR" '_ddr_g config diff.relative true'
_ddr_key "$DDRPR" fixtures/creds.py; _ddr_in "$DDRPR" '_ddr_g commit -qam key'
_ddr_effect "$DDRPR/fixtures" "+++ b/creds.py" diff main...HEAD
_ddr_scan "$DDRPR/fixtures" main; DDRRC=$?
_ddr_is "run from fixtures/ under diff.relative, a key committed to fixtures/creds.py is judged as fixtures/creds.py, excluded, exit 0 (P1)" "$DDRRC" 0
_ddr_pnew p1-untracked-fx; DDRPR="$DDRR"
_ddr_in "$DDRPR" 'printf "%s\n" "$DDRKL" > fixtures/u.py'
_ddr_scan "$DDRPR/fixtures" main; DDRRC=$?
_ddr_is "run from fixtures/, an untracked key in fixtures/u.py is judged as fixtures/u.py, excluded, exit 0 (P1)" "$DDRRC" 0

_ddr_pnew p2-relative; DDRPR="$DDRR"
_ddr_in "$DDRPR" '_ddr_g config diff.relative true'
_ddr_key "$DDRPR" creds.py; _ddr_in "$DDRPR" '_ddr_g commit -qam key'
DDRV="$( cd -- "${DDRPR:?}/sub" && GIT_CEILING_DIRECTORIES="${DDR:?}" git diff main...HEAD 2>&1 )"
[ -n "$DDRFX" ] || [ -z "$DDRV" ] || DDRFX="diff.relative does not narrow porcelain git diff run from sub/ here"
_ddr_scan "$DDRPR/sub" main; DDRRC=$?
_ddr_is "run from sub/ under diff.relative, a key the branch committed to creds.py outside it is found, exit 1 (P2)" "$DDRRC" 1
_ddr_in "$DDRPR" '_ddr_g reset -q --soft HEAD~1'
_ddr_scan "$DDRPR/sub" main; DDRRC=$?
_ddr_is "run from sub/ under diff.relative, and the same key staged, exit 1 (P2)" "$DDRRC" 1
_ddr_in "$DDRPR" '_ddr_g reset -q'
_ddr_scan "$DDRPR/sub" main; DDRRC=$?
_ddr_is "run from sub/ under diff.relative, and the same key unstaged, exit 1 (P2)" "$DDRRC" 1
_ddr_pnew p2-untracked; DDRPR="$DDRR"
_ddr_in "$DDRPR" 'printf "%s\n" "$DDRKL" > outside.py'
_ddr_scan "$DDRPR/sub" main; DDRRC=$?
_ddr_is "run from sub/, an untracked key in outside.py at the top is found, exit 1 (P2)" "$DDRRC" 1
_ddr_pnew p2-control; DDRPR="$DDRR"
_ddr_key "$DDRPR" creds.py; _ddr_in "$DDRPR" '_ddr_g commit -qam key'
_ddr_scan "$DDRPR/sub" main; DDRRC=$?
_ddr_is "run from sub/ with no setting, a key committed to creds.py outside it is found, exit 1, as today (P2)" "$DDRRC" 1
_ddr_pnew p2-inside; DDRPR="$DDRR"
_ddr_in "$DDRPR" '_ddr_g config diff.relative true'
_ddr_key "$DDRPR" sub/s.txt; _ddr_in "$DDRPR" '_ddr_g commit -qam key'
_ddr_scan "$DDRPR/sub" main; DDRRC=$?
_ddr_is "run from sub/ under diff.relative, a key committed inside sub/ is found, exit 1, as today (P2)" "$DDRRC" 1

_ddr_pnew p3; DDRPR="$DDRR"
_ddr_key "$DDRPR" "fixtures/creds.py testdata/creds.py creds.example creds.sample"; _ddr_in "$DDRPR" '_ddr_g commit -qam key'
_ddr_scan "$DDRPR" main; DDRRC=$?
_ddr_is "keys committed under fixtures/ and testdata/ and in .example and .sample files are excluded, exit 0, as today (P3)" "$DDRRC" 0
_ddr_in "$DDRPR" 'printf "%s\n" "$DDRKL" > fixtures/u.py'
_ddr_scan "$DDRPR" main; DDRRC=$?
_ddr_is "and so is an untracked key under fixtures/, exit 0, as today (P3)" "$DDRRC" 0
_ddr_key "$DDRPR" a_fixtures/creds.py; _ddr_in "$DDRPR" '_ddr_g commit -qam more'
_ddr_scan "$DDRPR" main; DDRRC=$?
_ddr_is "while a key in a_fixtures/, which is not a fixtures directory, is found, exit 1, as today (P3)" "$DDRRC" 1
# Read through a setting, the fixture rule still holds.
for DDRKIND in nodiff-c tc-rewrite; do
  case "$DDRKIND" in
    nodiff-c) DDRV="under -diff in a .gitattributes the branch commits" ;;
    *)        DDRV="under a textconv that rewrites the content" ;;
  esac
  _ddr_new "p3-$DDRKIND"; DDRPR="$DDRR"
  _ddr_in "$DDRPR" '_ddr_g checkout -q -b feat && mkdir fixtures && printf "harmless\n" > fixtures/creds.txt && _ddr_g add -A && _ddr_g commit -qm fx'
  _ddr_set "$DDRPR" "$DDRKIND"; _ddr_probe "$DDRPR" "$DDRKIND"
  _ddr_key "$DDRPR" fixtures/creds.txt; _ddr_in "$DDRPR" '_ddr_g commit -qam key'
  _ddr_scan "$DDRPR" main; DDRRC=$?
  _ddr_is "$DDRV, a key committed to fixtures/creds.txt is still excluded, exit 0 (P3)" "$DDRRC" 0
  DDRE=()
done

# ------------------------------------------------- U: a scan that could not read ----
_ddr_new u1; DDRPR="$DDRR"
_ddr_in "$DDRPR" '_ddr_g checkout -q -b feat && printf "%s\n" "$DDRKL" >> app.txt && _ddr_g commit -qam key'
DDRE=(GIT_CONFIG_PARAMETERS="'color.ui ")
_ddr_scan "$DDRPR" main; DDRRC=$?
_ddr_is "with GIT_CONFIG_PARAMETERS malformed, so git refuses every call, secret-scan exits 2, not 0 (U1)" "$DDRRC" 2
_ddr_scan "$DDRPR"; DDRRC=$?
_ddr_is "and exits 2 with no base named too (U1)" "$DDRRC" 2
DDRE=()

# U2 by a git that fails partway any read the stacked base's readers never make:
# a listing, a content check, a content diff past the base's count (two for
# secret-scan on a branch with a base, three for felix_added_lines). Over a clean
# change under -diff, holding a file binary by content, an answer is right only
# as exit 2 when such a read was made, and as the clean answer when none was.
_ddr_new u2-fake; DDRPR="$DDRR"
_ddr_in "$DDRPR" 'printf "z\n" > zz.txt && _ddr_g add zz.txt && _ddr_g commit -qm zz && _ddr_g checkout -q -b feat \
  && mkdir -p .git/info && printf "*.txt -diff\n" > .git/info/attributes \
  && printf "a clean line\n" >> app.txt && { printf "x\000y\n"; printf "binary\n"; } > blob.txt && _ddr_g add -A && _ddr_g commit -qm change \
  && printf "staged clean\n" > staged.txt && _ddr_g add staged.txt && printf "unstaged clean\n" >> deps.txt && printf "u\n" > untracked.txt'
DDRE=(PATH="$DDR/fakegit:$PATH" DDR_REAL_GIT="$DDRGIT" DDR_FAKE_LOG="$DDR/fake.log" DDR_FAKE_N="$DDR/fake.n" DDR_FAKE_K=2)
: > "$DDR/fake.log" 2>/dev/null; : > "$DDR/fake.n" 2>/dev/null
DDRV="$( cd -- "${DDRPR:?}" && GIT_CEILING_DIRECTORIES="${DDR:?}" env "${DDRE[@]}" sh -c 'command -v git; git diff --numstat HEAD >/dev/null 2>&1; echo "$?"' 2>/dev/null | tr '\n' ' ')"
[ -n "$DDRFX" ] || [ "$DDRV" = "$DDR/fakegit/git 128 " ] || DDRFX="the failing git is not the one a reader runs: [$DDRV]"
: > "$DDR/fake.log" 2>/dev/null; : > "$DDR/fake.n" 2>/dev/null
_ddr_scan "$DDRPR" main; DDRRC=$?
DDRV="$(tr '\n' ';' < "$DDR/fake.log" 2>/dev/null)"
if [ -n "$DDRV" ]; then DDRX=2; else DDRX=0; fi
if [ -z "$DDRFX" ] && [ "$DDRRC" != "$DDRX" ]; then
  bad "secret-scan whose every read past the stacked base's own fails partway exits 2 when it made one, and 0 over this clean change when it made none (U2)" \
      "expected [$DDRX] got [$DDRRC]; reads made to fail: [${DDRV:-none}]"
else
  _ddr_is "secret-scan whose every read past the stacked base's own fails partway exits 2 when it made one, and 0 over this clean change when it made none (U2)" "$DDRRC" "$DDRX"
fi
DDRE=(PATH="$DDR/fakegit:$PATH" DDR_REAL_GIT="$DDRGIT" DDR_FAKE_LOG="$DDR/fake.log" DDR_FAKE_N="$DDR/fake.n" DDR_FAKE_K=3)
: > "$DDR/fake.log" 2>/dev/null; : > "$DDR/fake.n" 2>/dev/null
_ddr_added "$DDRPR" main >/dev/null; DDRRC=$?
DDRV="$(tr '\n' ';' < "$DDR/fake.log" 2>/dev/null)"
if [ -n "$DDRV" ]; then DDRX=non-zero; else DDRX="exit 0"; fi
if [ -z "$DDRFX" ] && [ "$(_ddr_nz "$DDRRC")" != "$DDRX" ]; then
  bad "felix_added_lines whose every read past the stacked base's own fails partway fails when it made one, and exits 0 when it made none (U2)" \
      "expected [$DDRX] got [$DDRRC]; reads made to fail: [${DDRV:-none}]"
else
  _ddr_is "felix_added_lines whose every read past the stacked base's own fails partway fails when it made one, and exits 0 when it made none (U2)" "$(_ddr_nz "$DDRRC")" "$DDRX"
fi
DDRE=()

# A content check that opens the file: a tracked path under -diff that is a
# named pipe, then one nobody may read. Each read through git fails today; a
# read the branch adds must fail too, and must not block.
_ddr_new u2-pipe; DDRPR="$DDRR"
_ddr_in "$DDRPR" 'printf "z\n" > zz.txt && _ddr_g add zz.txt && _ddr_g commit -qm zz && _ddr_g checkout -q -b feat \
  && mkdir -p .git/info && printf "*.txt -diff\n" > .git/info/attributes && printf "a clean line\n" >> app.txt \
  && unlink zz.txt && mkfifo zz.txt && [ -p zz.txt ] && [ -n "$(git ls-files -- zz.txt)" ]' "no tracked pipe could be made at zz.txt"
_ddr_scan "$DDRPR" main; DDRRC=$?
_ddr_is "under -diff, with a tracked path a named pipe, secret-scan exits 2 (U2)" "$DDRRC" 2
_ddr_added "$DDRPR" main >/dev/null; DDRRC=$?
_ddr_is "and felix_added_lines fails (U2)" "$(_ddr_nz "$DDRRC")" "non-zero"
_ddr_unpipe "$DDRPR/zz.txt"
_ddr_new u2-unreadable; DDRPR="$DDRR"
_ddr_in "$DDRPR" 'printf "z\n" > zz.txt && _ddr_g add zz.txt && _ddr_g commit -qm zz && _ddr_g checkout -q -b feat \
  && mkdir -p .git/info && printf "*.txt -diff\n" > .git/info/attributes && printf "a clean line\n" >> app.txt \
  && printf "zz edited\n" >> zz.txt && chmod 000 zz.txt'
if [ -z "$DDRFX" ] && [ -r "$DDRPR/zz.txt" ]; then
  skip "under -diff, with a tracked file nobody may read, secret-scan exits 2 (U2)" "this user can read a mode-000 file"
else
  _ddr_scan "$DDRPR" main; DDRRC=$?
  _ddr_is "under -diff, with a tracked file nobody may read, secret-scan exits 2 (U2)" "$DDRRC" 2
fi
chmod 644 "$DDRPR/zz.txt" 2>/dev/null

# ------------------------------------------------- rename detection, the rule ----
# A key a fixture holds on main, moved out of fixtures/ by the branch, or copied
# out of it while the fixture is edited. Rename detection prints the move as a
# rename and the copy as a copy, with no added line, so what is read depends on
# diff.renames.
_ddr_new ren-true; DDRPR="$DDRR"
_ddr_in "$DDRPR" 'mkdir -p fixtures src && printf "%s\nline two\nline three\n" "$DDRKL" > fixtures/creds.py && _ddr_g add -A \
  && _ddr_g commit -qm fixture && _ddr_g checkout -q -b feat && _ddr_g config diff.renames true \
  && _ddr_g mv fixtures/creds.py src/creds.py && _ddr_g commit -qm move'
_ddr_effect "$DDRPR" "rename from fixtures/creds.py" diff main...HEAD
[ -z "$DDRSKIP" ] || { DDRFX="rename detection is not in force: $DDRSKIP"; DDRSKIP=""; }
_ddr_scan "$DDRPR" main; DDRRC=$?
_ddr_is "under diff.renames=true, a key the branch moves out of fixtures/ into src/ is found, exit 1 (rule)" "$DDRRC" 1
_ddr_new ren-copies; DDRPR="$DDRR"
_ddr_in "$DDRPR" 'mkdir -p fixtures src && printf "%s\nline two\nline three\n" "$DDRKL" > fixtures/creds.py && _ddr_g add -A \
  && _ddr_g commit -qm fixture && _ddr_g checkout -q -b feat && _ddr_g config diff.renames copies \
  && cp fixtures/creds.py src/creds.py && printf "four\n" >> fixtures/creds.py && _ddr_g add -A && _ddr_g commit -qm copy'
_ddr_effect "$DDRPR" "copy from fixtures/creds.py" diff main...HEAD
[ -z "$DDRSKIP" ] || { DDRFX="copy detection is not in force: $DDRSKIP"; DDRSKIP=""; }
_ddr_scan "$DDRPR" main; DDRRC=$?
_ddr_is "under diff.renames=copies, a key the branch copies out of fixtures/ into src/ is found, exit 1 (rule)" "$DDRRC" 1

# --------------------------------------------------------------- L: the lint ----
# An engine source line that runs porcelain `git diff` carries --no-ext-diff and
# --no-textconv on that same line. Engine source is felix, bin/*, lib/*.sh,
# hooks/* and tests/red. A line runs porcelain git diff when, not being a
# comment, it holds the word git, then any of git's global options (-C <dir>,
# -c <key=value>, --no-pager, --git-dir=..., --work-tree=...), then the word
# diff and a blank or the end of the line; one that also carries --name-only or
# --name-status is exempt. Prints file:line for each offender, relative to the
# directory, and returns 1; 0 when there is none, 2 when there is no engine.
# Widened after review (2026-10-08): any long global option may stand before
# diff, not only the four the contract named, because the fix itself runs
# `git --literal-pathspecs … diff`, and the closed list did not see that line.
_ddr_lint() {   # harness dir
  [ -n "$1" ] && [ -d "$1/lib" ] || return 2
  ( cd -- "${1:?}" || exit 2
    set --
    for f in felix bin/* lib/*.sh hooks/* tests/red; do [ -f "$f" ] && set -- "$@" "$f"; done
    [ "$#" -gt 0 ] || exit 2
    LC_ALL=C awk '
      BEGIN {
        a  = "(\"[^\"]*\"|\047[^\047]*\047|[^ \t]+)"
        o  = "(-C[ \t]+" a "|-c[ \t]+" a "|--[a-z][a-z-]*(=" a ")?)"
        re = "[^A-Za-z0-9_]git([ \t]+" o ")*[ \t]+diff[ \t]"
        cm = "^[ \t]*#"
      }
      $0 ~ cm { next }
      { l = " " $0 " " }
      l !~ re { next }
      index(l, "--name-only") || index(l, "--name-status") { next }
      index(l, "--no-ext-diff") && index(l, "--no-textconv") { next }
      { print FILENAME ":" FNR; n++ }
      END { exit (n > 0 ? 1 : 0) }' "$@" )
}
DDRFX=""; DDRSKIP=""
DDROUT="$(_ddr_lint "$REAL_HARNESS")"; DDRRC=$?
if [ "$DDRRC" -eq 0 ] && [ -z "$DDROUT" ]; then
  ok "no engine source line runs porcelain git diff without --no-ext-diff and --no-textconv beside it (L)"
else
  bad "no engine source line runs porcelain git diff without --no-ext-diff and --no-textconv beside it (L)" \
      "status $DDRRC, offending: $(printf '%s' "$DDROUT" | tr '\n' ' ')"
fi

# A skeleton engine, every file holding a comment that names git diff and a
# compliant call; each case copies it and appends one line to one file.
DDRLS="$DDR/lint-skeleton"
mkdir -p "$DDRLS/bin" "$DDRLS/lib" "$DDRLS/hooks" "$DDRLS/tests" 2>/dev/null || DDRFX="the lint skeleton could not be made"
for DDRF in felix bin/tool lib/a.sh hooks/stop tests/red tests/run; do
  printf '#!/usr/bin/env bash\n# git diff HEAD, as a person types it\n%s\n' \
    '  out="$(git -C "$root" diff --no-ext-diff --no-textconv HEAD)"' > "$DDRLS/$DDRF" 2>/dev/null \
    || DDRFX="the lint skeleton could not be made"
done
DDROUT="$(_ddr_lint "$DDRLS")"; DDRRC=$?
_ddr_is "the lint passes the clean skeleton: comments and compliant calls only (L)" "$DDRRC|$DDROUT" "0|"
_ddr_plant() {   # tag file line -> DDRP, the skeleton with the line appended to file; DDRPN its line number
  DDRP="$DDR/lint-$1"; DDRPN=""
  cp -R "$DDRLS" "$DDRP" 2>/dev/null && printf '%s\n' "$3" >> "$DDRP/$2" 2>/dev/null \
    && DDRPN="$(awk 'END { print NR }' "$DDRP/$2")" || { [ -n "$DDRFX" ] || DDRFX="the lint copy for $1 could not be made"; }
}
_ddr_flags() {   # name tag file line: the lint reports exactly that line
  _ddr_plant "$2" "$3" "$4"
  DDROUT="$(_ddr_lint "$DDRP")"; DDRRC=$?
  _ddr_is "$1" "$DDRRC|$DDROUT" "1|$3:$DDRPN"
}
_ddr_passes() {   # name tag file line: the lint reports nothing
  _ddr_plant "$2" "$3" "$4"
  DDROUT="$(_ddr_lint "$DDRP")"; DDRRC=$?
  _ddr_is "$1" "$DDRRC|$DDROUT" "0|"
}
_ddr_flags "the lint reports a bare git diff planted in felix (L)" felix felix 'd="$(git diff HEAD)"'
_ddr_flags "the lint reports git -C <dir> diff planted in bin/ (L)" bin bin/tool '  git -C "$root" diff --cached'
_ddr_flags "the lint reports one planted in a new file in bin/ (L)" bin-new bin/other 'git diff HEAD -- .'
_ddr_flags "the lint reports git diff at the end of a line planted in lib/*.sh (L)" lib lib/a.sh '  git diff'
_ddr_flags "the lint reports one planted in a new lib/*.sh (L)" lib-new lib/new.sh 'x="$(git diff "$base...HEAD")"'
_ddr_flags "the lint reports git --no-pager diff planted in hooks/ (L)" hooks hooks/stop 'git --no-pager diff HEAD -- .'
_ddr_flags "the lint reports git -c <key=value> diff planted in tests/red (L)" red tests/red 'git -c core.quotePath=false diff "$base...HEAD"'
_ddr_flags "the lint reports git --git-dir=... diff (L)" gitdir lib/a.sh 'git --git-dir="$g" diff HEAD'
_ddr_flags "the lint reports git --work-tree=... diff (L)" worktree lib/a.sh 'git --work-tree=/w diff HEAD'
_ddr_flags "the lint reports git with several global options before diff (L)" globals lib/a.sh 'git -C "$a" -c x.y=z --no-pager diff HEAD'
_ddr_flags "the lint reports git --literal-pathspecs diff, a global option the contract did not name (L, after review)" literal lib/a.sh 'git --literal-pathspecs -C "$r" diff HEAD'
_ddr_flags "the lint reports a line carrying --no-textconv without --no-ext-diff (L)" no-ext lib/a.sh 'git -C "$r" diff --no-textconv HEAD'
_ddr_flags "the lint reports a line carrying --no-ext-diff without --no-textconv (L)" no-tc lib/a.sh 'git -C "$r" diff --no-ext-diff HEAD'
_ddr_flags "the lint reports git diff --stat, which is no exempt listing (L)" stat lib/a.sh 'git diff --stat HEAD'
_ddr_flags "the lint reports git diff --quiet, which is no exempt listing (L)" quiet lib/a.sh 'git diff --quiet HEAD'
_ddr_passes "the lint passes git diff --name-only (L)" name-only lib/a.sh 'git diff --name-only HEAD'
_ddr_passes "the lint passes git -C <dir> diff --name-status (L)" name-status lib/a.sh 'git -C "$r" diff --name-status --cached'
_ddr_passes "the lint passes git diff-tree (L)" diff-tree lib/a.sh 'git diff-tree -p HEAD'
_ddr_passes "the lint passes git diff-index (L)" diff-index lib/a.sh 'git diff-index -p HEAD'
_ddr_passes "the lint passes git diff-files (L)" diff-files lib/a.sh 'git diff-files -p'
_ddr_passes "the lint passes git difftool (L)" difftool lib/a.sh 'git difftool HEAD'
_ddr_passes "the lint passes a comment line naming git diff (L)" comment lib/a.sh '# git diff HEAD'
_ddr_passes "the lint passes an indented comment line naming git diff (L)" comment-indented hooks/stop '    # out="$(git diff HEAD)"'
_ddr_passes "the lint passes a line carrying both flags, in either order (L)" both lib/a.sh 'git diff --no-textconv HEAD --no-ext-diff'
_ddr_passes "the lint does not read tests/run (L)" run tests/run 'git diff HEAD'
_ddr_passes "the lint does not read a file in lib/ that is not *.sh (L)" notes lib/notes.txt 'git diff HEAD'
# And on a copy of the real engine, where a planted line is among whatever else it reports.
DDRP="$DDR/lint-real"
mkdir -p "$DDRP/tests" 2>/dev/null && cp -R "$REAL_HARNESS/felix" "$REAL_HARNESS/bin" "$REAL_HARNESS/lib" "$REAL_HARNESS/hooks" "$DDRP/" 2>/dev/null \
  && cp "$REAL_HARNESS/tests/red" "$DDRP/tests/red" 2>/dev/null && printf '%s\n' 'git -C "$root" diff HEAD' >> "$DDRP/lib/resolve.sh" 2>/dev/null \
  || DDRFX="the copy of the real engine could not be made"
DDROUT="$(_ddr_lint "$DDRP")"; DDRRC=$?
_ddr_is "on a copy of the real engine, the lint reports a line planted at the end of lib/resolve.sh (L)" \
        "$DDRRC $(_ddr_line "$DDROUT" "lib/resolve.sh:$(awk 'END { print NR }' "$DDRP/lib/resolve.sh" 2>/dev/null)")" "1 printed"

unset -f _ddr_g _ddr_in _ddr_dir _ddr_new _ddr_unborn _ddr_set _ddr_unset _ddr_probe _ddr_effect _ddr_scan _ddr_sh \
  _ddr_added _ddr_changed _ddr_tid _ddr_conf _ddr_recipe _ddr_is _ddr_nz _ddr_line _ddr_holds _ddr_two _ddr_unpipe \
  _ddr_battery _ddr_stacked _ddr_late _ddr_pnew _ddr_key _ddr_lint _ddr_plant _ddr_flags _ddr_passes
unset DDR DDRK DDRKL DDRAPP DDRCONF DDRGIT DDRFX DDRSKIP DDRA DDRR DDRE DDRFAKE DDRTC DDRPR DDRRC DDRV DDRX DDRKIND \
  DDROUT DDRLS DDRF DDRP DDRPN

