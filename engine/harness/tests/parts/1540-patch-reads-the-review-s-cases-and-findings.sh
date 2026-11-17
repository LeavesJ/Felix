printf '\nwhat the engine reads from a patch: the cases its review found\n'
# Not blind. Written by the implementer of claude/no-diff-drivers-in-parsed-diffs
# after its adversarial review (2026-10-08). Each case is a finding the blind
# block above had no clause for, and each was shown red against the fix with the
# one piece it names reverted. Under diff.renames=copies a copied file showed no
# line, so felix_added_lines pins -M. Under diff.ignoreSubmodules=all, or
# `ignore = all` in a committed .gitmodules, a moved submodule pointer hashed as
# the clean tree. A binary-marked file named like an option, `-c1`, was handed
# to head, which read one byte of the record stream instead. With
# GIT_LITERAL_PATHSPECS=1 the `:(literal)` magic first used matched nothing.
# A type change prints its header twice. A pair whose old side is binary is
# left as git's default leaves it, unread, since reading it was the cost the
# design set out to avoid. And under core.abbrev=4 the tree id saw 16 bits of a
# binary file's blob id, so an edit found to share them hashed as the one before
# (measured after the review). Not pinned here: the 512 MiB size rule, which no
# fixture can afford, and the count check on a read again, which no git this
# suite can drive misses a path for.
DDQ="$(mktemp -d "$TMP/ddq.XXXXXX" 2>/dev/null)" && DDQ="$(cd -- "${DDQ:?}" && pwd -P)" && [ -n "$DDQ" ] || DDQ="$TMP/ddq-missing"
DDQK="$(printf '%s%s' sk- QQQQQQQQQQQQQQQQQQQQQQQQ)"
DDQFX=""; DDQR=""
_ddq_g() { git -c user.name=ddq -c user.email=ddq@example.invalid -c commit.gpgsign=false -c protocol.file.allow=always "$@"; }
_ddq_in() {   # repo snippet: run in the repository, under the ceiling
  ( cd -- "${1:?}" && GIT_CEILING_DIRECTORIES="${DDQ:?}" && export GIT_CEILING_DIRECTORIES && eval "$2" ) >/dev/null 2>&1 \
    || { [ -n "$DDQFX" ] || DDQFX="a step in ${1##*/} failed: $2"; }
}
_ddq_new() {   # tag -> DDQR, a repository whose main holds a.txt, on branch feat
  local d
  DDQFX=""
  d="$(mktemp -d "$DDQ/$1.XXXXXX" 2>/dev/null)" && d="$(cd -- "${d:?}" && pwd -P)" && [ -n "$d" ] \
    || { DDQR="$DDQ/missing-$1"; DDQFX="the directory for $1 could not be made"; return 0; }
  DDQR="$d"
  _ddq_in "$DDQR" 'git init -q -b main && printf "x\n" > a.txt && _ddq_g add -A && _ddq_g commit -qm base && git checkout -q -b feat'
}
_ddq_scan() {   # repo [VAR=value...] -> the scanner's status
  local r="${1:?}"; shift
  ( cd -- "$r" && GIT_CEILING_DIRECTORIES="${DDQ:?}" env "$@" perl -e 'alarm shift; exec @ARGV or exit 127' 90 "$FROOT/harness/bin/secret-scan" main ) >/dev/null 2>&1
}
_ddq_added() {   # repo [VAR=value...] -> felix_added_lines' lines, then rc=N
  local r="${1:?}"; shift
  ( cd -- "$r" && export GIT_CEILING_DIRECTORIES="${DDQ:?}" && { [ "$#" -eq 0 ] || export "$@"; } \
      && . "$FROOT/harness/lib/resolve.sh" && { felix_added_lines "$r" main; printf 'rc=%s' "$?"; } ) 2>/dev/null
}
_ddq_tid() { ( r="${1:?}"; export GIT_CEILING_DIRECTORIES="${DDQ:?}"; . "$FROOT/harness/lib/resolve.sh" && . "$FROOT/harness/lib/verify.sh" && felix_tree_id "$r" ) 2>/dev/null; }
_ddq_is() { if [ -n "$DDQFX" ]; then bad "$1" "fixture: $DDQFX"; else is "$1" "$2" "$3"; fi; }
_ddq_has() { case "$1" in *"$2"*) printf 'printed' ;; *) printf 'not printed' ;; esac; }   # text needle
_ddq_rc() { printf '%s' "${1##*rc=}"; }

# Q1: a copy, under diff.renames=copies. -M keeps git's default, which shows it.
_ddq_new q1
_ddq_in "$DDQR" 'printf "DROP TABLE users;\nselect 1;\n" > a.sql && _ddq_g add -A && _ddq_g commit -qm sql \
  && git checkout -q main && git merge -q feat && git checkout -q -b copy && cp a.sql b.sql && printf "select 2;\n" >> a.sql \
  && _ddq_g add -A && _ddq_g commit -qm copy'
DDQO="$(_ddq_added "$DDQR")"
_ddq_is "with no rename setting, felix_added_lines prints the lines of a file the branch copied, as today (after review)" \
        "$(_ddq_has "$DDQO" '+DROP TABLE users;')" "printed"
_ddq_in "$DDQR" 'git config diff.renames copies'
DDQO="$(_ddq_added "$DDQR")"
_ddq_is "under diff.renames=copies, felix_added_lines still prints the lines of a file the branch copied (after review)" \
        "$(_ddq_has "$DDQO" '+DROP TABLE users;')" "printed"

# Q2: a submodule pointer the branch moves, under the two settings that hide one.
DDQFX=""
DDQS="$(mktemp -d "$DDQ/q2.XXXXXX" 2>/dev/null)" && DDQS="$(cd -- "${DDQS:?}" && pwd -P)" && [ -n "$DDQS" ] \
  || { DDQS="$DDQ/missing-q2"; DDQFX="the directory for q2 could not be made"; }
mkdir -p "$DDQS/lib" "$DDQS/top" 2>/dev/null
_ddq_in "$DDQS/lib" 'git init -q -b main && printf "l\n" > l.txt && _ddq_g add -A && _ddq_g commit -qm one && printf "m\n" >> l.txt && _ddq_g commit -qam two'
_ddq_in "$DDQS/top" 'git init -q -b main && printf "x\n" > a.txt && _ddq_g submodule add -q "$DDQS/lib" lib && _ddq_g add -A && _ddq_g commit -qm base'
_ddq_in "$DDQS/top" '[ -f lib/l.txt ]'
DDQT0="$(_ddq_tid "$DDQS/top")"
_ddq_in "$DDQS/top/lib" 'git checkout -q HEAD~1'
_ddq_is "a moved submodule pointer changes the tree id, as today (after review)" \
        "$([ -n "$DDQT0" ] && [ "$(_ddq_tid "$DDQS/top")" != "$DDQT0" ] && echo changed)" "changed"
_ddq_in "$DDQS/top" 'git config diff.ignoreSubmodules all'
_ddq_is "under diff.ignoreSubmodules=all, a moved submodule pointer still changes the tree id (after review)" \
        "$([ -n "$DDQT0" ] && [ "$(_ddq_tid "$DDQS/top")" != "$DDQT0" ] && echo changed)" "changed"
_ddq_in "$DDQS/top" 'git config --unset diff.ignoreSubmodules && git -C lib checkout -q main \
  && git config -f .gitmodules submodule.lib.ignore all && _ddq_g add .gitmodules && _ddq_g commit -qm ignore'
DDQT0="$(_ddq_tid "$DDQS/top")"
_ddq_in "$DDQS/top/lib" 'git checkout -q HEAD~1'
_ddq_is "under ignore = all in a committed .gitmodules, a moved submodule pointer still changes the tree id (after review)" \
        "$([ -n "$DDQT0" ] && [ "$(_ddq_tid "$DDQS/top")" != "$DDQT0" ] && echo changed)" "changed"

# Q3: a binary-marked text file named like an option.
_ddq_new q3
_ddq_in "$DDQR" 'printf "* -diff\n" > .git/info/attributes && printf "api_key = \"%s\"\n" "$DDQK" > ./-c1 \
  && _ddq_g add -- -c1 && _ddq_g commit -qm k && printf "token = \"%s\"\n" "$DDQK" >> ./-c1'
_ddq_scan "$DDQR"; DDQRC=$?
_ddq_is "secret-scan finds a key in a -diff file named -c1, exit 1 (after review)" "$DDQRC" "1"
DDQO="$(_ddq_added "$DDQR")"
_ddq_is "and felix_added_lines prints its committed line (after review)" "$(_ddq_has "$DDQO" '+api_key')" "printed"
_ddq_is "and its unstaged line (after review)" "$(_ddq_has "$DDQO" '+token')" "printed"

# Q4: pathspec settings in the caller's environment.
_ddq_new q4
_ddq_in "$DDQR" 'printf "creds*.txt -diff\n" > .git/info/attributes && printf "api_key = \"%s\"\n" "$DDQK" > "creds[1].txt" \
  && _ddq_g add -A && _ddq_g commit -qm k'
_ddq_scan "$DDQR" GIT_LITERAL_PATHSPECS=1; DDQRC=$?
_ddq_is "with GIT_LITERAL_PATHSPECS=1, secret-scan finds a key in a -diff file named creds[1].txt, exit 1 (after review)" "$DDQRC" "1"
DDQO="$(_ddq_added "$DDQR" GIT_LITERAL_PATHSPECS=1)"
_ddq_is "and felix_added_lines prints it (after review)" "$(_ddq_has "$DDQO" '+api_key')" "printed"
_ddq_scan "$DDQR" GIT_GLOB_PATHSPECS=1; DDQRC=$?
_ddq_is "with GIT_GLOB_PATHSPECS=1, which makes git refuse a literal path, the scan does not call the change clean (after review, U2)" \
        "$([ "$DDQRC" -ne 0 ] && echo "not clean")" "not clean"
DDQO="$(_ddq_added "$DDQR" GIT_GLOB_PATHSPECS=1)"
_ddq_is "and felix_added_lines prints the line or fails (after review, U2)" \
        "$({ [ "$(_ddq_rc "$DDQO")" != 0 ] || [ "$(_ddq_has "$DDQO" '+api_key')" = printed ]; } && echo ok)" "ok"

# Q5: a binary-marked file turned into a link prints its path's header twice.
_ddq_new q5
_ddq_in "$DDQR" 'printf "*.txt -diff\n" > .git/info/attributes && printf "y\n" > u.txt && _ddq_g add -A && _ddq_g commit -qm u \
  && rm a.txt && ln -s u.txt a.txt'
_ddq_scan "$DDQR"; DDQRC=$?
_ddq_is "a -diff file turned into a link is read, and the scan exits 0, not 2 (after review)" "$DDQRC" "0"
DDQO="$(_ddq_added "$DDQR")"
_ddq_is "and felix_added_lines exits 0 (after review)" "$(_ddq_rc "$DDQO")" "0"

# Q6: a pair whose old side is binary, as git's default leaves it.
_ddq_new q6
_ddq_in "$DDQR" 'git checkout -q main && printf "x\0y\n" > f.dat && _ddq_g add -A && _ddq_g commit -qm bin \
  && git checkout -q feat && git merge -q main && printf "BINTOTEXT plain line\n" > f.dat && _ddq_g commit -qam text'
DDQO="$(_ddq_added "$DDQR")"
_ddq_is "a binary file the branch replaces with text is not read as text, as git's default leaves it (after review, N1)" \
        "$(_ddq_has "$DDQO" 'BINTOTEXT')" "not printed"
_ddq_in "$DDQR" 'printf "f.dat -diff\n" > .git/info/attributes'
DDQO="$(_ddq_added "$DDQR")"
_ddq_is "nor when an attribute also marks it (after review, B3)" "$(_ddq_has "$DDQO" 'BINTOTEXT')" "not printed"

# Q7: core.abbrev, which shortens the `index` line, all the tree id sees of a
# binary file's edit. The second edit is found by its blob id's first four hex
# digits, which perl computes as git does and git hash-object then confirms.
_ddq_new q7
_ddq_in "$DDQR" 'printf "x\0y\n" > f.bin && _ddq_g add -A && _ddq_g commit -qm bin && printf "x\0%s\n" 0 > f.bin'
DDQN="$(perl -MDigest::SHA=sha1_hex -e 'my $b = sub { my $c = "x\0$_[0]\n"; sha1_hex("blob " . length($c) . "\0" . $c) };
  my $t = substr($b->(0), 0, 4); for my $i (1 .. 4000000) { if (substr($b->($i), 0, 4) eq $t) { print $i; exit 0 } } exit 1' 2>/dev/null)" \
  || { [ -n "$DDQFX" ] || DDQFX="no second edit sharing four hex digits was found"; }
_ddq_in "$DDQR" '[ -n "$DDQN" ] && [ "$(printf "x\0%s\n" "$DDQN" | git hash-object --stdin | cut -c1-4)" = "$(git hash-object f.bin | cut -c1-4)" ]'
DDQT0="$(_ddq_tid "$DDQR")"
_ddq_in "$DDQR" 'git config core.abbrev 4'
DDQT1="$(_ddq_tid "$DDQR")"
_ddq_is "core.abbrev=4 does not change the tree id of a binary file's edit (after review)" \
        "$([ -n "$DDQT0" ] && [ "$DDQT1" = "$DDQT0" ] && echo same)" "same"
_ddq_in "$DDQR" 'printf "x\0%s\n" "$DDQN" > f.bin'
_ddq_is "under core.abbrev=4, a second binary edit whose blob id shares four hex digits with the first has another tree id (after review)" \
        "$([ -n "$DDQT1" ] && [ "$(_ddq_tid "$DDQR")" != "$DDQT1" ] && echo different)" "different"

# Q8: a text file named like a glob, beside a binary file the glob would match.
# git matches a pathspec literally before it tries it as a glob, so a lone
# creds[1].txt reads the same either way; only a second match shows the read
# again naming its path as a pattern (mutation survivors M16 and M17).
_ddq_new q8
_ddq_in "$DDQR" 'printf "*.txt -diff\n" > .git/info/attributes && printf "api_key = \"%s\"\n" "$DDQK" > "a*.txt" \
  && printf "x\0y\n" > ab.txt && _ddq_g add -A && _ddq_g commit -qm k'
_ddq_scan "$DDQR"; DDQRC=$?
_ddq_is "secret-scan finds a key in a -diff file named a*.txt beside a binary ab.txt, exit 1 (mutation survivor)" "$DDQRC" "1"
DDQO="$(_ddq_added "$DDQR")"
_ddq_is "and felix_added_lines prints it and returns 0 (mutation survivor)" \
        "$(_ddq_has "$DDQO" '+api_key') $(_ddq_rc "$DDQO")" "printed 0"

unset -f _ddq_g _ddq_in _ddq_new _ddq_scan _ddq_added _ddq_tid _ddq_is _ddq_has _ddq_rc
unset DDQ DDQK DDQFX DDQR DDQO DDQRC DDQS DDQT0 DDQT1 DDQN

printf '\nwhat the engine reads from a patch: the review'"'"'s findings, blind\n'
# Blind, from contract-review.md (clauses R1 to R7 and N), written 2026-10-08.
# contract.md was read for its definitions of the readers: S (bin/secret-scan),
# A (felix_added_lines) and T (felix_tree_id). The author did not read
# lib/resolve.sh, lib/verify.sh, lib/escape.sh, bin/secret-scan or the
# implementer's own blocks for this change, so each expectation here comes from
# a sentence of the contract, and the clause it serves is named at the end of
# the assertion. Those marked (guard) check that a fixture means what it says;
# they pass on the stacked base as well.
#
# The contract's terms, as built here. A binary marking is `* -diff` or
# `* binary` in .git/info/attributes, or core.bigFileThreshold=8, which is
# below the size of every text file a marking is meant to cover. A credential
# is api_key = "sk-" and 24 letters, assembled at run time so this file holds
# none. Committed means branch feat against main. Staged and unstaged mean the
# index and the work tree against HEAD.
#
# Every repository lives under one mktemp root below $TMP. Every git call runs
# in a subshell that stands in one of them, with GIT_CEILING_DIRECTORIES at
# that root. No config but the repository's own is read: the global and system
# files are switched off and XDG_CONFIG_HOME points at nothing, so "no setting"
# really means none. Each reader runs under perl's alarm, so a reader that
# hangs is a FAIL (status 142) and not a suite that never ends. When a fixture
# cannot be built, every assertion resting on it fails and says why.
DDV="$(mktemp -d "$TMP/ddv.XXXXXX" 2>/dev/null)" && DDV="$(cd "${DDV:?}" && pwd -P)" || DDV="$TMP/ddv.missing"
DDV_FX=""; DDV_ENV=""; DDV_R=""; DDV_OUT=""; DDV_RC=""
[ -d "$DDV" ] && : > "$DDV/empty.cfg"
DDV_CRED="$(printf '%s_%s = "%s%s"' api key sk- QWkRtYuPaSdFgHjKlZxCvBnM)"

_ddv_in() {   # dir cmd...: cmd in a subshell standing in dir, which must lie under $DDV
  ( _ddv_d="${1:?}"; shift
    case "$_ddv_d" in "$DDV"/?*) ;; *) exit 97 ;; esac
    cd "$_ddv_d" || exit 97
    unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY GIT_EXTERNAL_DIFF GIT_DIFF_OPTS \
          GIT_CONFIG_PARAMETERS GIT_CONFIG_COUNT GIT_LITERAL_PATHSPECS GIT_GLOB_PATHSPECS \
          GIT_NOGLOB_PATHSPECS GIT_ICASE_PATHSPECS
    export GIT_CEILING_DIRECTORIES="$DDV" GIT_CONFIG_NOSYSTEM=1 GIT_ATTR_NOSYSTEM=1 \
           GIT_CONFIG_GLOBAL="$DDV/empty.cfg" XDG_CONFIG_HOME="$DDV/no-xdg"
    [ -z "$DDV_ENV" ] || export "$DDV_ENV"
    "$@" )
}
_ddv_git() { git -c user.name=x -c user.email=x@example.invalid -c commit.gpgsign=false -c protocol.file.allow=always "$@"; }
_ddv_new() {   # tag -> DDV_R, a fresh directory under the root, with DDV_FX cleared
  DDV_FX=""
  DDV_R="$(mktemp -d "$DDV/$1.XXXXXX" 2>/dev/null)" && DDV_R="$(cd "${DDV_R:?}" && pwd -P)" && return 0
  DDV_R="$DDV/missing"; DDV_FX="no directory for $1 could be made under $DDV"
}
_ddv_at() {   # dir why cmd...: cmd in dir; a failure marks the fixture broken, and says why
  local d="$1" why="$2"; shift 2
  [ -n "$DDV_FX" ] && return 0
  _ddv_in "$d" "$@" >/dev/null 2>&1 || DDV_FX="$why failed in $d"
}
_ddv_do() { _ddv_at "$DDV_R" "$@"; }

# The readers. S's status (142: the alarm stopped it). A's lines with NULs
# dropped, then rc=<its status>; no rc line means the alarm stopped it. T's id.
_ddv_S() {   # dir [base]
  local d="$1"; shift
  _ddv_in "$d" perl -e 'alarm shift; exec @ARGV or exit 127' 60 "$FROOT/harness/bin/secret-scan" "$@" >/dev/null 2>&1
  printf '%s' "$?"
}
_ddv_A() {   # dir
  _ddv_in "$1" perl -e 'alarm shift; exec @ARGV or exit 127' 60 bash -c \
    'set -uo pipefail; . "$1/lib/resolve.sh"; felix_added_lines "$2" main; printf "rc=%s\n" "$?"' _ "$FROOT/harness" "$1" 2>/dev/null \
    | LC_ALL=C tr -d '\000'
}
_ddv_T() {   # dir
  _ddv_in "$1" perl -e 'alarm shift; exec @ARGV or exit 127' 60 bash -c \
    'set -u; . "$1/lib/resolve.sh"; . "$1/lib/verify.sh"; felix_tree_id "$2"' _ "$FROOT/harness" "$1" 2>/dev/null
}
_ddv_split() {   # A's capture -> DDV_OUT (its lines) and DDV_RC (its status, or none)
  local o="$1" last
  last="${o##*$'\n'}"
  case "$last" in
    rc=*) DDV_RC="${last#rc=}"
          if [ "$o" = "$last" ]; then DDV_OUT=""; else DDV_OUT="${o%$'\n'*}"; fi ;;
    *) DDV_RC=none; DDV_OUT="$o" ;;
  esac
}
# What git's own patches add, with no setting: the committed range, then the
# staged change, then the unstaged one, as contract.md describes A.
_ddv_added_by_git() { { git diff main...HEAD && git diff --cached && git diff; } | LC_ALL=C awk '/^\+/ && !/^\+\+\+/'; }
# The id the stacked base gives a born HEAD with nothing untracked, by the
# recipe the fail-closed section writes down for it (its T5): HEAD, then the
# patch against HEAD, hashed as one document.
_ddv_tree_recipe() {
  local head diff
  [ -z "$(git ls-files --others --exclude-standard -- .)" ] || return 1
  head="$(git rev-parse HEAD 2>/dev/null)" || return 1
  diff="$(git diff HEAD -- . 2>/dev/null)"
  printf '%s\n%s\n%s' "$head" "$diff" "" | git hash-object --stdin
}

_ddv_is()    { if [ -n "$DDV_FX" ]; then bad "$1" "fixture: $DDV_FX"; else is "$1" "$2" "$3"; fi; }
_ddv_has()   { if [ -n "$DDV_FX" ]; then bad "$1" "fixture: $DDV_FX"; else has "$1" "$2" "$3"; fi; }
_ddv_lacks() {
  if [ -n "$DDV_FX" ]; then bad "$1" "fixture: $DDV_FX"
  else case "$2" in *"$3"*) bad "$1" "[$2] holds [$3]" ;; *) ok "$1" ;; esac; fi
}
_ddv_same() {   # name a b: one non-empty id, twice
  if [ -n "$DDV_FX" ]; then bad "$1" "fixture: $DDV_FX"
  elif [ -n "$2" ] && [ "$2" = "$3" ]; then ok "$1"
  else bad "$1" "expected one non-empty id twice, got [$2] and [$3]"; fi
}
_ddv_differ() {   # name a b: two different non-empty ids
  if [ -n "$DDV_FX" ]; then bad "$1" "fixture: $DDV_FX"
  elif [ -n "$2" ] && [ -n "$3" ] && [ "$2" != "$3" ]; then ok "$1"
  else bad "$1" "expected two different non-empty ids, got [$2] and [$3]"; fi
}
_ddv_found_or_unread() {   # name status: 1 or 2, never 0
  if [ -n "$DDV_FX" ]; then bad "$1" "fixture: $DDV_FX"
  else case "$2" in 1|2) ok "$1" ;; *) bad "$1" "expected exit 1 or 2, got [$2]" ;; esac; fi
}
_ddv_line_or_nz() {   # name: from DDV_OUT and DDV_RC, the credential's line or a non-zero status
  if [ -n "$DDV_FX" ]; then bad "$1" "fixture: $DDV_FX"
  else case "$DDV_RC" in
         none) bad "$1" "A gave no status: the alarm stopped it" ;;
         0) case "$DDV_OUT" in *"+$DDV_CRED"*) ok "$1" ;; *) bad "$1" "status 0 without the line: [$DDV_OUT]" ;; esac ;;
         *) ok "$1" ;;
       esac; fi
}

_ddv_mark() {   # marking: applied in the repository the caller stands in
  case "$1" in
    none) return 0 ;;
    -diff) mkdir -p .git/info && printf '* -diff\n' > .git/info/attributes ;;
    binary) mkdir -p .git/info && printf '* binary\n' > .git/info/attributes ;;
    bigFileThreshold) git config core.bigFileThreshold 8 ;;
    *) return 1 ;;
  esac
}
_ddv_ml() {
  case "$1" in
    none) printf 'with no setting' ;; -diff) printf 'under * -diff' ;;
    binary) printf 'under * binary' ;; bigFileThreshold) printf 'under core.bigFileThreshold=8' ;;
  esac
}
_ddv_src() { case "$1" in C) printf committed ;; S) printf staged ;; U) printf unstaged ;; esac; }
_ddv_holds() { case "$1" in *"+$DDV_CRED"*) return 0 ;; *) return 1 ;; esac; }

# A target file, DDV_N, and its look-alikes: names a glob, a pathspec, a split
# word or a stripped directory would reach instead of it. DDV_DB are changed
# with it in every source and hold a NUL, so they are binary by content and
# must never be read as text; each change adds a credential after that NUL.
# DDV_DT are text holding a credential and are in no change at all.
_ddv_r1_pick() {   # 1..10
  DDV_DB=(); DDV_DT=(); DDV_HASDECOY=yes
  case "$1" in
    1) DDV_N='-c1'; DDV_L='a name -c1'; DDV_HASDECOY=no ;;
    2) DDV_N='--x'; DDV_L='a name --x'; DDV_HASDECOY=no ;;
    3) DDV_N='-n'; DDV_L='a name -n'; DDV_HASDECOY=no ;;
    4) DDV_N='creds[1].txt'; DDV_L='a name creds[1].txt'; DDV_DB=('creds1.txt') ;;
    5) DDV_N='a*b.txt'; DDV_L='a name a*b.txt'; DDV_DB=('aZb.txt'); DDV_DT=('ab.txt') ;;
    6) DDV_N='q?.txt'; DDV_L='a name q?.txt'; DDV_DB=('qZ.txt'); DDV_DT=('qY.txt') ;;
    7) DDV_N=':x.txt'; DDV_L='a name :x.txt'; DDV_DB=('x.txt') ;;
    8) DDV_N='my creds.txt'; DDV_L='a name with a space'; DDV_DB=('creds.txt'); DDV_DT=('my') ;;
    9) DDV_N="$(printf 'cl\303\251.env')"; DDV_L='a name past ASCII'; DDV_HASDECOY=no ;;
    10) DDV_N='sub/dir/creds.txt'; DDV_L='a name in a subdirectory'; DDV_DB=('creds.txt'); DDV_DT=('dir/creds.txt') ;;
    # "whatever its name": the contract's list, then names past it, under * -diff only.
    11) DDV_N='-'; DDV_L='a name - alone'; DDV_HASDECOY=no ;;
    12) DDV_N=':/top.txt'; DDV_L='a name :/top.txt'; DDV_DB=('top.txt') ;;
    13) DDV_N=':(glob)a*.txt'; DDV_L='a name :(glob)a*.txt'; DDV_DB=('aZ.txt') ;;
    14) DDV_N=':!x.txt'; DDV_L='a name :!x.txt'; DDV_DB=('other.bin') ;;
    15) DDV_N='q"uote.txt'; DDV_L='a name holding a double quote'; DDV_HASDECOY=no ;;
    16) DDV_N='back\slash.txt'; DDV_L='a name holding a backslash'; DDV_HASDECOY=no ;;
    17) DDV_N="$(printf 'tab\there.txt')"; DDV_L='a name holding a tab'; DDV_HASDECOY=no ;;
    18) DDV_N="$(printf 'new\nline.txt')"; DDV_L='a name holding a newline'; DDV_HASDECOY=no ;;
    19) DDV_N='x b/y.txt'; DDV_L='a name holding " b/"'; DDV_DB=('y.txt') ;;
    20) DDV_N='trail.txt '; DDV_L='a name ending in a space'; DDV_DB=('trail.txt') ;;
    21) DDV_N='HEAD'; DDV_L='a name HEAD'; DDV_HASDECOY=no ;;
    22) DDV_N='main'; DDV_L='a name main'; DDV_HASDECOY=no ;;
  esac
}
_ddv_r1_build() {   # marking: main holds the target and its look-alikes, then the marking, then branch feat
  local f
  git init -q -b main || return 1
  mkdir -p "./$(dirname -- "$DDV_N")" && printf 'hello world\n' > "./$DDV_N" || return 1
  for f in ${DDV_DB[@]+"${DDV_DB[@]}"}; do
    mkdir -p "./$(dirname -- "$f")" && printf '\000seed\n' > "./$f" || return 1
  done
  for f in ${DDV_DT[@]+"${DDV_DT[@]}"}; do
    mkdir -p "./$(dirname -- "$f")" && printf 'DDV-DECOY-TEXT %s\n' "$DDV_CRED" > "./$f" || return 1
  done
  git add -A && _ddv_git commit -qm base && _ddv_mark "$1" && git checkout -q -b feat
}
_ddv_r1_touch() {   # tag line: the line onto the target, a credential after the NUL of each changed look-alike
  local f
  printf '%s\n' "$2" >> "./$DDV_N" || return 1
  for f in ${DDV_DB[@]+"${DDV_DB[@]}"}; do printf 'DDV-DECOY-BIN-%s %s\n' "$1" "$DDV_CRED" >> "./$f" || return 1; done
}
_ddv_r1_clean() {   # every source changes the target by a clean line and the look-alikes by a credential
  _ddv_r1_touch C 'a clean line, committed' && git add -A && _ddv_git commit -qm clean \
    && _ddv_r1_touch S 'a clean line, staged' && git add -A \
    && _ddv_r1_touch U 'a clean line, unstaged'
}
_ddv_r1_committed() {
  git reset -q --hard main -- && _ddv_r1_touch C "$DDV_CRED" && git add -A && _ddv_git commit -qm key \
    && _ddv_holds "$(git --literal-pathspecs diff --text main...HEAD -- "$DDV_N")"
}
_ddv_r1_staged() {
  git reset -q --hard main -- && _ddv_r1_touch S "$DDV_CRED" && git add -A \
    && _ddv_holds "$(git --literal-pathspecs diff --text --cached -- "$DDV_N")"
}
_ddv_r1_unstaged() { git reset -q && _ddv_holds "$(git --literal-pathspecs diff --text -- "$DDV_N")"; }

# ------------------------------------------------------ guard: the credential ----
DDV_N='creds.txt'; DDV_DB=(); DDV_DT=(); DDV_HASDECOY=no
_ddv_new guard
_ddv_do "the base commit" _ddv_r1_build none
for _ddv_s in committed staged unstaged; do
  _ddv_do "the $_ddv_s credential" "_ddv_r1_$_ddv_s"
  _ddv_is "(guard) with no setting, S finds a $_ddv_s credential in a text file, exit 1" "$(_ddv_S "$DDV_R" main)" 1
  _ddv_split "$(_ddv_A "$DDV_R")"
  _ddv_is "with no setting, A prints what git's own patches add, $_ddv_s, as the stacked base (N)" \
          "$DDV_OUT" "$(_ddv_in "$DDV_R" _ddv_added_by_git 2>/dev/null)"
done

# --------------------------------------------------------- R1: a path is a path ----
for _ddv_m in -diff binary bigFileThreshold; do
  _ddv_i=0
  while [ "$_ddv_i" -lt 22 ]; do
    _ddv_i=$((_ddv_i + 1))
    [ "$_ddv_i" -le 10 ] || [ "$_ddv_m" = -diff ] || continue
    _ddv_r1_pick "$_ddv_i"
    _ddv_new "r1-$_ddv_i"
    _ddv_do "the base commit" _ddv_r1_build "$_ddv_m"
    if [ "$DDV_HASDECOY" = yes ]; then
      _ddv_do "the clean change" _ddv_r1_clean
      _ddv_is "$(_ddv_ml "$_ddv_m"), $DDV_L, credentials only in its look-alikes, in every source: S reads none of them, exit 0 (R1)" \
              "$(_ddv_S "$DDV_R" main)" 0
    fi
    for _ddv_s in committed staged unstaged; do
      _ddv_do "the $_ddv_s credential" "_ddv_r1_$_ddv_s"
      _ddv_is "$(_ddv_ml "$_ddv_m"), $DDV_L: S finds the $_ddv_s credential, exit 1 (R1)" "$(_ddv_S "$DDV_R" main)" 1
      _ddv_split "$(_ddv_A "$DDV_R")"
      _ddv_is "$(_ddv_ml "$_ddv_m"), $DDV_L: A prints the $_ddv_s credential's line and no byte of another file (R1)" \
              "$DDV_OUT" "+$DDV_CRED"
    done
  done
done

# ------------------------------------------- R2: a pair with a binary side ----
# Each source has its own files: a-* turn from NUL-led to text, b-* from text
# to NUL-holding, and c-* and d-* are added with a NUL and a credential after
# it: c-* at their first byte, d-* at their 8000th, the last byte git's rule
# looks at (measured: a NUL at offset 7999 is binary to git, at 8000 text).
_ddv_r2_build() {   # marking
  local s
  git init -q -b main || return 1
  for s in c s u; do printf '\000old\n' > "a-$s.dat" && printf 'R2B old text\n' > "b-$s.dat" || return 1; done
  git add -A && _ddv_git commit -qm base && _ddv_mark "$1" && git checkout -q -b feat
}
_ddv_r2_pairs() {   # C|S|U
  local s
  case "$1" in C) s=c ;; S) s=s ;; U) s=u ;; *) return 1 ;; esac
  printf 'R2A-%s one\nR2A-%s two\n' "$1" "$1" > "a-$s.dat" \
    && printf 'R2B-%s one\n\000R2B-%s two\n' "$1" "$1" > "b-$s.dat" || return 1
  [ "$1" = U ] && return 0
  printf '\000\nR2C-%s\n%s\n' "$1" "$DDV_CRED" > "c-$s.bin" \
    && perl -e 'print "x" x 7999, "\0\nR2D-$ARGV[0]\n$ARGV[1]\n"' "$1" "$DDV_CRED" > "d-$s.bin"
}
_ddv_r2_committed() {
  _ddv_r2_pairs C && git add -A && _ddv_git commit -qm pairs || return 1
  case "$(git diff main...HEAD -- a-c.dat)" in *Binary*) return 0 ;; *) return 1 ;; esac
}
_ddv_r2_staged() { _ddv_r2_pairs S && git add -A; }
_ddv_r2_unstaged() { _ddv_r2_pairs U; }
DDV_R2NONE=""
for _ddv_m in none -diff binary bigFileThreshold; do
  _ddv_ln="$(_ddv_ml "$_ddv_m")"
  _ddv_new r2
  _ddv_do "the base commit" _ddv_r2_build "$_ddv_m"
  _ddv_do "the committed pairs" _ddv_r2_committed
  _ddv_is "$_ddv_ln, files added with a NUL at byte 1 and at byte 8000, committed: S does not flag the credential after it, exit 0 (R2)" \
          "$(_ddv_S "$DDV_R" main)" 0
  _ddv_do "the staged pairs" _ddv_r2_staged
  _ddv_is "$_ddv_ln, files added with a NUL at byte 1 and at byte 8000, staged: S does not flag the credential after it, exit 0 (R2)" \
          "$(_ddv_S "$DDV_R" main)" 0
  _ddv_do "the unstaged pairs" _ddv_r2_unstaged
  _ddv_split "$(_ddv_A "$DDV_R")"
  for _ddv_s in C S U; do
    _ddv_lacks "$_ddv_ln, old side with a NUL, new side text, $(_ddv_src "$_ddv_s"): A prints none of the new side's lines (R2)" \
               "$DDV_OUT" "R2A-$_ddv_s"
    _ddv_lacks "$_ddv_ln, old side text, new side with a NUL, $(_ddv_src "$_ddv_s"): A prints none of the new side's bytes (R2)" \
               "$DDV_OUT" "R2B-$_ddv_s"
  done
  for _ddv_s in C S; do
    _ddv_lacks "$_ddv_ln, a file added with a NUL at byte 1, $(_ddv_src "$_ddv_s"): A prints none of it (R2)" \
               "$DDV_OUT" "R2C-$_ddv_s"
    _ddv_lacks "$_ddv_ln, a file added with a NUL at byte 8000, $(_ddv_src "$_ddv_s"): A prints none of it (R2)" \
               "$DDV_OUT" "R2D-$_ddv_s"
  done
  if [ "$_ddv_m" = none ]; then
    _ddv_is "with no setting, A prints nothing at all for these pairs, as the stacked base (R2, N)" "$DDV_OUT" ""
    DDV_R2NONE="$DDV_OUT"
  else
    _ddv_is "$_ddv_ln, A reads these pairs exactly as with no setting (R2)" "$DDV_OUT" "$DDV_R2NONE"
  fi
done

# A NUL past byte 8000 leaves a file text, by git's rule. Here it is byte 8001,
# the first one past: a hundred lines of eighty bytes come before it.
_ddv_late() { perl -e 'printf "late text line %03d %s\n", $_, "x" x 60 for 1 .. 100; print "\0 a NUL past byte 8000\n"; print "tail $_\n" for 1 .. 5'; }
_ddv_late_build() { git init -q -b main && _ddv_late > late.txt && git add -A && _ddv_git commit -qm base && _ddv_mark "$1" && git checkout -q -b feat; }
_ddv_late_committed() { printf '%s\n' "$DDV_CRED" >> late.txt && git add -A && _ddv_git commit -qm key; }
_ddv_late_staged() { git reset -q --hard main -- && printf '%s\n' "$DDV_CRED" >> late.txt && git add -A; }
_ddv_late_unstaged() { git reset -q; }
_ddv_late_unborn() { git init -q -b main && _ddv_mark "$1" && { _ddv_late; printf '%s\n' "$DDV_CRED"; } > late.txt && git add -A; }
for _ddv_m in none -diff binary bigFileThreshold; do
  _ddv_ln="$(_ddv_ml "$_ddv_m")"
  if [ "$_ddv_m" = none ]; then _ddv_c='R2, guard'; else _ddv_c=R2; fi
  _ddv_new late
  _ddv_do "the base commit" _ddv_late_build "$_ddv_m"
  for _ddv_s in committed staged unstaged; do
    _ddv_do "the $_ddv_s credential" "_ddv_late_$_ddv_s"
    _ddv_is "$_ddv_ln, a NUL past byte 8000 leaves a file text: S finds the $_ddv_s credential added to it, exit 1 ($_ddv_c)" \
            "$(_ddv_S "$DDV_R" main)" 1
  done
  _ddv_new late-unborn
  _ddv_do "the unborn repository" _ddv_late_unborn "$_ddv_m"
  _ddv_is "$_ddv_ln, a NUL past byte 8000 leaves a file text: S finds the credential staged on an unborn HEAD, exit 1 ($_ddv_c)" \
          "$(_ddv_S "$DDV_R")" 1
done

# ----------------------------------------- R3: a submodule pointer is the tree's ----
_ddv_r3_src() { git init -q -b main && printf 'one\n' > f && git add -A && _ddv_git commit -qm one && printf 'two\n' >> f && _ddv_git commit -qam two; }
_ddv_r3_sup() {   # source [ignore]: a superproject with the source as submodule sub
  git init -q -b main && printf 'top\n' > top.txt && git add -A && _ddv_git commit -qm top \
    && _ddv_git submodule add -q -- "$1" sub && [ -e sub/.git ] \
    && { [ -z "${2:-}" ] || git config -f .gitmodules submodule.sub.ignore all; } \
    && git add -A && _ddv_git commit -qm sub && [ -z "$(git status --porcelain)" ]
}
_ddv_r3_hidden() { [ -z "$(git diff HEAD)" ]; }   # the setting has teeth: git's own patch hides the move
_ddv_r3_shown()  { case "$(git diff HEAD)" in *'Subproject commit'*) return 0 ;; *) return 1 ;; esac; }
_ddv_new r3
_ddv_do "the directories" mkdir src sup sup2
_ddv_at "$DDV_R/src" "the submodule's source" _ddv_r3_src
_ddv_at "$DDV_R/sup" "the superproject" _ddv_r3_sup "$DDV_R/src"
DDV_SUP="$DDV_R/sup"
DDV_T0="$(_ddv_T "$DDV_SUP")"
_ddv_is "T of a clean tree holding a submodule is byte for byte the stacked base's (N)" \
        "$DDV_T0" "$(_ddv_in "$DDV_SUP" _ddv_tree_recipe 2>/dev/null)"
# key value hides: each setting, and whether git's own patch loses the moved pointer under it
DDV_R3SET='diff.ignoreSubmodules all yes
diff.ignoreSubmodules dirty no
diff.ignoreSubmodules untracked no
submodule.sub.ignore all yes'
DDV_TC=()
while read -r _ddv_k _ddv_v _ddv_h <&3; do
  _ddv_at "$DDV_SUP" "setting $_ddv_k" git config "$_ddv_k" "$_ddv_v"
  _ddv_t="$(_ddv_T "$DDV_SUP")"; DDV_TC+=("$_ddv_t")
  _ddv_at "$DDV_SUP" "unsetting $_ddv_k" git config --unset "$_ddv_k"
  _ddv_same "$_ddv_k=$_ddv_v: T of the clean tree is the id it has with no setting (R3)" "$_ddv_t" "$DDV_T0"
done 3<<EOF
$DDV_R3SET
EOF
_ddv_at "$DDV_SUP/sub" "moving the submodule's checkout" git checkout -q HEAD~1
_ddv_at "$DDV_SUP" "seeing the move with no setting" _ddv_r3_shown
DDV_T1="$(_ddv_T "$DDV_SUP")"
_ddv_differ "with no setting, T differs between the clean tree and the submodule's checkout moved (R3)" "$DDV_T0" "$DDV_T1"
_ddv_is "T of the tree with the submodule moved is byte for byte the stacked base's (N)" \
        "$DDV_T1" "$(_ddv_in "$DDV_SUP" _ddv_tree_recipe 2>/dev/null)"
_ddv_n=0
while read -r _ddv_k _ddv_v _ddv_h <&3; do
  _ddv_at "$DDV_SUP" "setting $_ddv_k" git config "$_ddv_k" "$_ddv_v"
  [ "$_ddv_h" = no ] || _ddv_at "$DDV_SUP" "hiding the move from git under $_ddv_k=$_ddv_v" _ddv_r3_hidden
  _ddv_t="$(_ddv_T "$DDV_SUP")"
  _ddv_at "$DDV_SUP" "unsetting $_ddv_k" git config --unset "$_ddv_k"
  _ddv_same "$_ddv_k=$_ddv_v: T of the tree with the submodule moved is the id it has with no setting (R3)" "$_ddv_t" "$DDV_T1"
  _ddv_differ "$_ddv_k=$_ddv_v: T still tells the moved tree from the clean one (R3)" "$_ddv_t" "${DDV_TC[$_ddv_n]:-}"
  _ddv_n=$((_ddv_n + 1))
done 3<<EOF
$DDV_R3SET
EOF
_ddv_at "$DDV_R/sup2" "the superproject with ignore = all committed" _ddv_r3_sup "$DDV_R/src" ignore
DDV_T2="$(_ddv_T "$DDV_R/sup2")"
_ddv_at "$DDV_R/sup2/sub" "moving the submodule's checkout" git checkout -q HEAD~1
_ddv_at "$DDV_R/sup2" "hiding the move from git under the committed .gitmodules" _ddv_r3_hidden
DDV_T3="$(_ddv_T "$DDV_R/sup2")"
_ddv_differ "ignore = all for the submodule in a committed .gitmodules: T still differs when its checkout moves (R3)" "$DDV_T2" "$DDV_T3"

# ------------------------------------------------------- R4: rename settings ----
_ddv_r4_change() {   # where: rename one file, copy another beside an edit to it, edit a third
  git mv ren-old.txt ren-new.txt && cp orig.txt copy.txt && printf 'orig edited\n' >> orig.txt \
    && printf 'third edited\n' >> third.txt || return 1
  if [ "$1" = moved ]; then mkdir src && git mv fixtures/key.txt src/key.txt || return 1; fi
  git add -A
}
_ddv_r4_build() {   # where: none|renamed|copied|moved, the one file holding a credential
  git init -q -b main || return 1
  printf 'rename line %s\n' 1 2 3 4 5 > ren-old.txt && printf 'orig line %s\n' 1 2 3 4 5 > orig.txt \
    && printf 'third line %s\n' 1 2 3 > third.txt || return 1
  case "$1" in
    renamed) printf '%s\n' "$DDV_CRED" >> ren-old.txt ;;
    copied) printf '%s\n' "$DDV_CRED" >> orig.txt ;;
    moved) mkdir fixtures && printf '%s\n' "$DDV_CRED" > fixtures/key.txt ;;
  esac || return 1
  git add -A && _ddv_git commit -qm base && git checkout -q -b feat && _ddv_r4_change "$1" && _ddv_git commit -qm change
}
_ddv_r4_teeth() {   # git's default patch shows the rename, and diff.renames=copies hides the copy's lines
  case "$(git diff main...HEAD)" in *'rename to ren-new.txt'*) ;; *) return 1 ;; esac
  case "$(git -c diff.renames=copies diff main...HEAD)" in *'copy to copy.txt'*) ;; *) return 1 ;; esac
}
_ddv_r4_set() { if [ "$1" = unset ]; then git config --unset diff.renames; return 0; fi; git config diff.renames "$1"; }
_ddv_new r4
_ddv_do "the branch" _ddv_r4_build none
_ddv_do "the settings' teeth" _ddv_r4_teeth
DDV_R4UNSET=""; DDV_R4TRUE=""; DDV_R4FALSE=""; DDV_R4COPIES=""
for _ddv_v in unset true false copies; do
  _ddv_do "diff.renames=$_ddv_v" _ddv_r4_set "$_ddv_v"
  _ddv_split "$(_ddv_A "$DDV_R")"
  case "$_ddv_v" in
    unset) DDV_R4UNSET="$DDV_OUT" ;; true) DDV_R4TRUE="$DDV_OUT" ;;
    false) DDV_R4FALSE="$DDV_OUT" ;; copies) DDV_R4COPIES="$DDV_OUT" ;;
  esac
  _ddv_has "diff.renames ${_ddv_v}: A prints the copied file's lines (R4)" "$DDV_OUT" "$(printf '+orig line %s\n' 1 2 3 4 5)"
done
_ddv_do "diff.renames unset" _ddv_r4_set unset
_ddv_is "diff.renames unset: A prints what git's own patch adds, as the stacked base (N)" \
        "$DDV_R4UNSET" "$(_ddv_in "$DDV_R" _ddv_added_by_git 2>/dev/null)"
_ddv_is "diff.renames=true: A's output is byte for byte the one with it unset (R4)" "$DDV_R4TRUE" "$DDV_R4UNSET"
_ddv_is "diff.renames=false: A's output is byte for byte the one with it unset (R4)" "$DDV_R4FALSE" "$DDV_R4UNSET"
_ddv_is "diff.renames=copies: A's output is byte for byte the one with it unset (R4)" "$DDV_R4COPIES" "$DDV_R4UNSET"
_ddv_do "the same change, staged on main" git reset -q --soft main
_ddv_is "T of a tree with a staged rename, copy and edits is byte for byte the stacked base's (N)" \
        "$(_ddv_T "$DDV_R")" "$(_ddv_in "$DDV_R" _ddv_tree_recipe 2>/dev/null)"
for _ddv_w in renamed copied moved; do
  case "$_ddv_w" in
    renamed) _ddv_wl='the renamed file' ;; copied) _ddv_wl='the copy' ;;
    moved) _ddv_wl='a file moved from fixtures/ to src/' ;;
  esac
  _ddv_new "r4-$_ddv_w"
  _ddv_do "the branch" _ddv_r4_build "$_ddv_w"
  _ddv_do "the settings' teeth" _ddv_r4_teeth
  for _ddv_v in unset true false copies; do
    _ddv_do "diff.renames=$_ddv_v" _ddv_r4_set "$_ddv_v"
    _ddv_is "diff.renames ${_ddv_v}: S finds a credential in $_ddv_wl, exit 1 (R4)" "$(_ddv_S "$DDV_R" main)" 1
  done
done

# ------------------------------------- R5: pathspec settings in the environment ----
DDV_N='creds[1].txt'; DDV_DB=(); DDV_DT=(); DDV_HASDECOY=no
for _ddv_m in -diff binary bigFileThreshold; do
  _ddv_ln="$(_ddv_ml "$_ddv_m")"
  _ddv_new r5
  _ddv_do "the base commit" _ddv_r1_build "$_ddv_m"
  for _ddv_s in committed staged unstaged; do
    [ "$_ddv_m" = -diff ] || [ "$_ddv_s" = committed ] || continue
    _ddv_do "the $_ddv_s credential" "_ddv_r1_$_ddv_s"
    for _ddv_e in LITERAL GLOB NOGLOB ICASE; do
      DDV_ENV="GIT_${_ddv_e}_PATHSPECS=1"
      _ddv_rc="$(_ddv_S "$DDV_R" main)"; _ddv_split "$(_ddv_A "$DDV_R")"
      DDV_ENV=""
      if [ "$_ddv_e" = LITERAL ]; then
        _ddv_is "$_ddv_ln, creds[1].txt $_ddv_s, GIT_LITERAL_PATHSPECS=1: S finds the credential, exit 1 (R5)" "$_ddv_rc" 1
        _ddv_has "$_ddv_ln, creds[1].txt $_ddv_s, GIT_LITERAL_PATHSPECS=1: A prints its line (R5)" "$DDV_OUT" "+$DDV_CRED"
      else
        _ddv_found_or_unread "$_ddv_ln, creds[1].txt $_ddv_s, GIT_${_ddv_e}_PATHSPECS=1: S never exits 0 (R5)" "$_ddv_rc"
        _ddv_line_or_nz "$_ddv_ln, creds[1].txt $_ddv_s, GIT_${_ddv_e}_PATHSPECS=1: A prints the line or returns non-zero (R5)"
      fi
    done
  done
done

# ---------------------------------------- R6: a type change is no failure to read ----
_ddv_r6_build() {   # marking
  git init -q -b main && printf 'plain text file\n' > t.txt && printf 'target text file\n' > target.txt \
    && ln -s target.txt l.txt && printf 'echo hello world\n' > m.sh && chmod 644 m.sh \
    && git add -A && _ddv_git commit -qm base && _ddv_mark "$1" \
    && [ "$(git config --bool core.filemode)" = true ]
}
_ddv_r6_shows()  { case "$(git diff --raw)" in *"$1"*) return 0 ;; *) return 1 ;; esac; }
_ddv_r6_link()   { unlink t.txt && ln -s target.txt t.txt && _ddv_r6_shows ':100644 120000'; }
_ddv_r6_unlink() { unlink l.txt && printf 'regular file now\n' > l.txt && _ddv_r6_shows ':120000 100644'; }
_ddv_r6_mode()   { chmod 755 m.sh && _ddv_r6_shows ':100644 100755'; }
for _ddv_m in -diff binary bigFileThreshold; do
  _ddv_ln="$(_ddv_ml "$_ddv_m")"
  for _ddv_w in link unlink mode; do
    case "$_ddv_w" in
      link) _ddv_wl='a tracked file replaced by a symbolic link' ;;
      unlink) _ddv_wl='a tracked link replaced by a regular file' ;;
      mode) _ddv_wl='a file whose mode alone changed' ;;
    esac
    _ddv_new "r6-$_ddv_w"
    _ddv_do "the base commit" _ddv_r6_build "$_ddv_m"
    _ddv_do "the change" "_ddv_r6_$_ddv_w"
    for _ddv_s in unstaged staged; do
      [ "$_ddv_s" = unstaged ] || _ddv_do "staging the change" git add -A
      _ddv_is "$_ddv_ln, $_ddv_wl, $_ddv_s, nothing secret: S exits 0, not 2 (R6)" "$(_ddv_S "$DDV_R" main)" 0
      _ddv_split "$(_ddv_A "$DDV_R")"
      _ddv_is "$_ddv_ln, $_ddv_wl, $_ddv_s, nothing secret: A returns 0 (R6)" "$DDV_RC" 0
    done
  done
done

# ------------------------------------------ R7: blob ids at their full strength ----
# Two contents "\0ddv <n>\n" whose blob ids share their first four hex digits
# and differ within the first seven, found by perl as the contract says.
DDV_PAIR="$(perl -MDigest::SHA=sha1_hex -e 'my %s; for my $i (0 .. 400000) { my $c = "\0ddv $i\n";
  my $h = sha1_hex("blob " . length($c) . "\0" . $c); my $p = substr($h, 0, 4);
  if (exists $s{$p} && substr($s{$p}[1], 0, 7) ne substr($h, 0, 7)) { print "$s{$p}[0] $i\n"; exit 0 }
  $s{$p} = [$i, $h] } exit 1' 2>/dev/null)"
DDV_I="${DDV_PAIR% *}"; DDV_J="${DDV_PAIR#* }"
_ddv_r7_build() { git init -q -b main && printf '\000seed\n' > blob.bin && git add -A && _ddv_git commit -qm base; }
_ddv_r7_edit()  { perl -e 'print "\0ddv $ARGV[0]\n"' "$1" > blob.bin; }
_ddv_r7_index() { git -c core.abbrev=4 diff HEAD | LC_ALL=C awk '/^index /'; }
_ddv_r7_abbrev() { if [ "$1" = unset ]; then git config --unset core.abbrev; return 0; fi; git config core.abbrev "$1"; }
_ddv_new r7
[ -n "$DDV_PAIR" ] || DDV_FX="no pair of blob ids sharing four hex digits was found"
_ddv_do "the base commit" _ddv_r7_build
_ddv_do "the first edit" _ddv_r7_edit "$DDV_I"
DDV_BI="$(_ddv_in "$DDV_R" git hash-object blob.bin 2>/dev/null)"; DDV_XI="$(_ddv_in "$DDV_R" _ddv_r7_index 2>/dev/null)"
DDV_T7="$(_ddv_T "$DDV_R")"; DDV_T4I=""
_ddv_is "T of a tree whose only change is a binary edit is byte for byte the stacked base's (N)" \
        "$DDV_T7" "$(_ddv_in "$DDV_R" _ddv_tree_recipe 2>/dev/null)"
for _ddv_v in 4 12 40 no; do
  _ddv_do "core.abbrev=$_ddv_v" _ddv_r7_abbrev "$_ddv_v"
  _ddv_t="$(_ddv_T "$DDV_R")"; [ "$_ddv_v" = 4 ] && DDV_T4I="$_ddv_t"
  _ddv_do "core.abbrev unset" _ddv_r7_abbrev unset
  _ddv_same "core.abbrev=$_ddv_v: T of a binary edit is the id it has with core.abbrev unset (R7)" "$_ddv_t" "$DDV_T7"
done
# "Whatever core.abbrev says" holds at every level, so the same 4 from the
# caller's environment and from the global file. Each one first shown to cut
# git's own index line to four hex digits.
[ -d "$DDV" ] && printf '[core]\n\tabbrev = 4\n' > "$DDV/abbrev4.cfg"
_ddv_r7_index_plain() { git diff HEAD | LC_ALL=C awk '/^index /'; }
_ddv_r7_env() {   # i|j: T under each environment's core.abbrev=4, into DDV_TP<i|j> and DDV_TG<i|j>
  local e w t x
  for w in P G; do
    case "$w" in P) e="GIT_CONFIG_PARAMETERS='core.abbrev=4'" ;; G) e="GIT_CONFIG_GLOBAL=$DDV/abbrev4.cfg" ;; esac
    DDV_ENV="$e"; t="$(_ddv_T "$DDV_R")"; x="$(_ddv_in "$DDV_R" _ddv_r7_index_plain 2>/dev/null)"; DDV_ENV=""
    if [ -z "$DDV_FX" ] && { [ -z "$x" ] || [ "$x" != "$(_ddv_in "$DDV_R" _ddv_r7_index 2>/dev/null)" ]; }; then
      DDV_FX="under $e git's own index line is [$x], not the four-digit one"
    fi
    eval "DDV_T$w$1=\$t"
  done
}
DDV_TPi=""; DDV_TGi=""; DDV_TPj=""; DDV_TGj=""
_ddv_r7_env i
_ddv_same "core.abbrev=4 in GIT_CONFIG_PARAMETERS: T of a binary edit is the id it has with core.abbrev unset (R7)" "$DDV_TPi" "$DDV_T7"
_ddv_same "core.abbrev=4 in the global config file: T of a binary edit is the id it has with core.abbrev unset (R7)" "$DDV_TGi" "$DDV_T7"
_ddv_do "the second edit" _ddv_r7_edit "$DDV_J"
DDV_BJ="$(_ddv_in "$DDV_R" git hash-object blob.bin 2>/dev/null)"; DDV_XJ="$(_ddv_in "$DDV_R" _ddv_r7_index 2>/dev/null)"
if [ -z "$DDV_FX" ]; then
  if [ -z "$DDV_BI" ] || [ "${DDV_BI:0:4}" != "${DDV_BJ:0:4}" ] || [ "${DDV_BI:0:7}" = "${DDV_BJ:0:7}" ]; then
    DDV_FX="git hash-object gives [$DDV_BI] and [$DDV_BJ], not four shared hex digits then a difference"
  elif [ -z "$DDV_XI" ] || [ "$DDV_XI" != "$DDV_XJ" ]; then
    DDV_FX="under core.abbrev=4 git's own index lines differ ([$DDV_XI], [$DDV_XJ]), so the setting has no teeth here"
  fi
fi
DDV_TJ="$(_ddv_T "$DDV_R")"
_ddv_differ "(guard) with core.abbrev unset, the two binary edits give two different ids" "$DDV_T7" "$DDV_TJ"
_ddv_do "core.abbrev=4" _ddv_r7_abbrev 4
DDV_T4J="$(_ddv_T "$DDV_R")"
_ddv_do "core.abbrev unset" _ddv_r7_abbrev unset
_ddv_differ "core.abbrev=4: two binary edits whose blob ids share their first four hex digits give two different ids (R7)" \
            "$DDV_T4I" "$DDV_T4J"
_ddv_r7_env j
_ddv_differ "core.abbrev=4 in GIT_CONFIG_PARAMETERS: the two edits give two different ids (R7)" "$DDV_TPi" "$DDV_TPj"
_ddv_differ "core.abbrev=4 in the global config file: the two edits give two different ids (R7)" "$DDV_TGi" "$DDV_TGj"

unset -f _ddv_in _ddv_git _ddv_new _ddv_at _ddv_do _ddv_S _ddv_A _ddv_T _ddv_split _ddv_added_by_git \
  _ddv_tree_recipe _ddv_is _ddv_has _ddv_lacks _ddv_same _ddv_differ _ddv_found_or_unread _ddv_line_or_nz \
  _ddv_mark _ddv_ml _ddv_src _ddv_holds _ddv_r1_pick _ddv_r1_build _ddv_r1_touch _ddv_r1_clean \
  _ddv_r1_committed _ddv_r1_staged _ddv_r1_unstaged _ddv_r2_build _ddv_r2_pairs _ddv_r2_committed \
  _ddv_r2_staged _ddv_r2_unstaged _ddv_late _ddv_late_build _ddv_late_committed _ddv_late_staged \
  _ddv_late_unstaged _ddv_late_unborn _ddv_r3_src _ddv_r3_sup _ddv_r3_hidden _ddv_r3_shown \
  _ddv_r4_change _ddv_r4_build _ddv_r4_teeth _ddv_r4_set _ddv_r6_build _ddv_r6_shows _ddv_r6_link \
  _ddv_r6_unlink _ddv_r6_mode _ddv_r7_build _ddv_r7_edit _ddv_r7_index _ddv_r7_abbrev _ddv_r7_index_plain _ddv_r7_env
unset DDV_TPi DDV_TGi DDV_TPj DDV_TGj
unset DDV DDV_FX DDV_ENV DDV_R DDV_OUT DDV_RC DDV_CRED DDV_N DDV_L DDV_DB DDV_DT DDV_HASDECOY DDV_R2NONE \
  DDV_SUP DDV_T0 DDV_T1 DDV_T2 DDV_T3 DDV_R3SET DDV_TC DDV_R4UNSET DDV_R4TRUE DDV_R4FALSE DDV_R4COPIES \
  DDV_PAIR DDV_I DDV_J DDV_BI DDV_BJ DDV_XI DDV_XJ DDV_T7 DDV_T4I DDV_T4J DDV_TJ \
  _ddv_m _ddv_i _ddv_s _ddv_ln _ddv_c _ddv_k _ddv_v _ddv_h _ddv_t _ddv_n _ddv_w _ddv_wl _ddv_e _ddv_rc

