printf '\na handoff fold already in flight is named, so a second session does not start one\n'
# The handoff upkeep row fell due for every session at once, and with ~20
# running, three folded the same pending set (#347, #351, #377) where only one
# could land. felix_handoff_in_flight (lib/handoff.sh) reads the remote-tracking
# refs as last fetched and names each branch that has already folded what main
# holds now; bin/handoff-in-flight says the same to a person and exits as grep
# does, so a maintenance check can end in it.
#
# One fixture repository with no remote configured: remote-tracking refs are
# written with update-ref, and every commit's committer time is set, so a tip's
# age is a fact of the fixture and not of when the suite happened to run.
# Remotes: origin holds main (its handoff at 0cg) and every case that must or
# must not count; ord1..ord3 hold fold order alone; calm holds nothing in
# flight; upstream holds a fold that belongs to another remote; age, built just
# before it is read, holds tips of chosen ages for the human line.
_bif_r="$TMP/bif-inflight"; mkdir -p "$_bif_r/docs/handoff/pending"
( _fx_cd "$_bif_r" && git init -q -b main && git config user.name t \
    && git config user.email t@example.invalid && git config commit.gpgsign false )
_bif_now="$(date +%s)"
_bif_git() { _fx_git "$_bif_r" "$@"; }
_bif_ago() { printf '%s' "$((_bif_now - $1))"; }
# HANDOFF.md with the marker `(after $1 comes $2)` in its preamble and, given a
# third argument, that phrase quoted again lower down, as a section may.
_bif_ho() {
  { printf '# Handoff\n\nWrite your section with felix handoff --section; the fold gives it the next id\n(after %s comes %s).\n\n---\n\n## Current state\n\n### %s. the current section\n\nIts body.\n' "$1" "$2" "$1"
    [ -n "${3:-}" ] && printf '\nA section may quote the rule, as in %s.\n' "$3"
    printf '\n---\n'; } > "$_bif_r/HANDOFF.md"
}
_bif_at() { _bif_git checkout -q --detach "$1"; }
# Commits the tree as it stands at committer time <epoch>, and prints the commit.
_bif_commit() {
  _bif_git add -A
  GIT_COMMITTER_DATE="@$1 +0000" GIT_AUTHOR_DATE="@$1 +0000" _bif_git commit -q --allow-empty -m "$2" \
    && _bif_git rev-parse HEAD
}
# A fold: cut from <base>, the marker moved to <id> (next <next>), tip at <epoch>.
_bif_fold() { _bif_at "$1" && _bif_ho "$2" "$3" "${5:-}" && _bif_commit "$4" "fold to $2"; }
_bif_pub() { _bif_git update-ref "refs/remotes/$1" "$2"; }

# main's history: M0 held 0ce; the fold to 0cg landed as M1; M2 took only a
# pending section, so main's handoff has not moved since M1.
_bif_ho 0ce 0cf
printf '### a section waiting\n\nIts body.\n' > "$_bif_r/docs/handoff/pending/20260101T000000Z-a.md"
_bif_M0="$(_bif_commit "$(_bif_ago 864000)" 'main, its handoff at 0ce')"
_bif_ho 0cg 0ch; rm -f "$_bif_r/docs/handoff/pending/20260101T000000Z-a.md"
_bif_M1="$(_bif_commit "$(_bif_ago 432000)" 'the fold to 0cg lands')"
printf '### b section waiting\n\nIts body.\n' > "$_bif_r/docs/handoff/pending/20260102T000000Z-b.md"
_bif_M2="$(_bif_commit "$(_bif_ago 345600)" 'a pending section lands')"
_bif_pub origin/main "$_bif_M2"
_bif_git symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/main

# In flight. Names, ids and tip times are chosen so that newest-first differs
# from name order and from id order, and one name holds two slashes.
_bif_pub origin/claude/handoff-fold-1001 "$(_bif_fold "$_bif_M2" 0cj 0ck "$(_bif_ago 2730)")"
# Cut from M1, before main took a pending section: its merge-base is not main's
# tip, but holds main's handoff as it is now, so it is in flight all the same.
_bif_pub origin/claude/a/older-base      "$(_bif_fold "$_bif_M1" 0ci 0cj "$(_bif_ago 9030)")"
# Its marker is 0cl; lower down it quotes an earlier id, which is not the marker.
_bif_pub origin/claude/quoted-later      "$(_bif_fold "$_bif_M2" 0cl 0cm "$(_bif_ago 20030)" '(after 0aa comes 0ab)')"
# Live but untouched for 72 hours: in flight only when no bound, or a wide one.
_bif_pub origin/claude/old-fold          "$(_bif_fold "$_bif_M2" 0ck 0cl "$(_bif_ago 259230)")"

# Not in flight, each for one reason, each with a recent tip so that the bound
# is never what leaves it out.
_bif_at "$_bif_M2"
printf '### c section waiting\n\nIts body.\n' > "$_bif_r/docs/handoff/pending/20260103T000000Z-c.md"
_bif_pub origin/claude/pending-only "$(_bif_commit "$(_bif_ago 100)" 'only a pending section')"
_bif_pub origin/claude/landed       "$_bif_M1"
_bif_pub origin/claude/stale        "$(_bif_fold "$_bif_M0" 0ci 0cj "$(_bif_ago 600)")"
_bif_pub origin/claude/behind       "$(_bif_fold "$_bif_M2" 0cb 0cc "$(_bif_ago 700)")"
_bif_pub origin/claude/quoted       "$(_bif_fold "$_bif_M2" 0cg 0ch "$(_bif_ago 1000)" '(after 0cz comes 0da)')"
_bif_at "$_bif_M2"; printf '# Handoff\n\nThis one carries no marker.\n' > "$_bif_r/HANDOFF.md"
_bif_pub origin/claude/no-marker    "$(_bif_commit "$(_bif_ago 900)" 'no marker')"
_bif_at "$_bif_M2"; _bif_git rm -q HANDOFF.md
_bif_pub origin/claude/no-handoff   "$(_bif_commit "$(_bif_ago 800)" 'no handoff')"
# A live fold that is a local branch only, and one under another remote.
_bif_git update-ref refs/heads/local-fold "$(_bif_fold "$_bif_M2" 0cm 0cn "$(_bif_ago 60)")"
_bif_pub upstream/claude/elsewhere  "$(_bif_fold "$_bif_M2" 0cn 0co "$(_bif_ago 30)")"

# Fold order alone: <remote>/main holds one id, <remote>/f is cut from it and
# folded to another.
_bif_ord() {
  _bif_om="$(_bif_fold "$_bif_M2" "$2" "$3" "$(_bif_ago 5000)")"; _bif_pub "$1/main" "$_bif_om"
  _bif_pub "$1/f" "$(_bif_fold "$_bif_om" "$4" "$5" "$(_bif_ago 1000)")"
}
_bif_ord ord1 0cz 0da 0da 0db
_bif_ord ord2 0zz 0aaa 0aaa 0aab
_bif_ord ord3 0aaa 0aab 0zz 0aaa
# Nothing in flight: main, a pending-only branch, a landed fold, a stale one.
_bif_pub calm/main "$_bif_M2"
_bif_pub calm/claude/pending-only "$(_bif_git rev-parse refs/remotes/origin/claude/pending-only)"
_bif_pub calm/claude/landed "$_bif_M1"
_bif_pub calm/claude/stale "$(_bif_git rev-parse refs/remotes/origin/claude/stale)"
# The working tree is left on a commit with no HANDOFF.md, so code that read
# the checkout's own file instead of the ref's could not pass.
_bif_at refs/remotes/origin/claude/no-handoff; mkdir -p "$_bif_r/deep/er"

_bif_fn()  { ( cd "$_bif_r" && . "$REAL_HARNESS/lib/handoff.sh" && felix_handoff_in_flight "$@" ) 2>/dev/null; }
_bif_run() { _bif_out="$(_bif_fn "$@")"; _bif_rc=$?; }
_bif_lines() { if [ -z "$1" ]; then printf 0; else printf '%s\n' "$1" | awk 'END { printf "%d", NR }'; fi; }
_bif_e() { printf '%s\t%s\t%s' "$1" "$2" "$(_bif_ago "$3")"; }
_bif_L_fold="$(_bif_e claude/handoff-fold-1001 0cj 2730)"
_bif_L_base="$(_bif_e claude/a/older-base 0ci 9030)"
_bif_L_quot="$(_bif_e claude/quoted-later 0cl 20030)"
_bif_L_old="$(_bif_e claude/old-fold 0ck 259230)"
_bif_all="$_bif_L_fold
$_bif_L_base
$_bif_L_quot
$_bif_L_old"
_bif_48="$_bif_L_fold
$_bif_L_base
$_bif_L_quot"
# <assertion> <branch>: the call exited 0 and named the live fold
# claude/handoff-fold-1001 somewhere, and names no branch that is <branch> or
# ends in /<branch> (so refs/heads/local-fold or upstream/claude/elsewhere are
# caught however they would be spelled). An absence is only evidence when the
# call that should have named something did, and each of these fails alone,
# for its own branch, whatever else the call got wrong.
_bif_named() { printf '%s\n' "$_bif_out" | awk -F'\t' -v b="$1" '
  $1 == b || (length($1) > length(b) && substr($1, length($1) - length(b)) == "/" b) { f = 1 }
  END { exit !f }'; }
_bif_not() {
  if [ "$_bif_rc" != 0 ] || ! _bif_named claude/handoff-fold-1001; then
    bad "$1" "rc $_bif_rc and the live fold not named, so an absence proves nothing: [$_bif_out]"
  elif _bif_named "$2"; then bad "$1" "[$_bif_out] names $2"
  else ok "$1"; fi
}

_bif_run "$_bif_r" refs/remotes/origin/main
# The whole answer, exactly: four folds in flight, newest tip first, each as
# branch, id and tip time, and exit 0.
is  "felix_handoff_in_flight names every fold in flight on origin, one <branch> <id> <epoch> line each, newest tip first, and exits 0" \
    "$_bif_rc:$_bif_out" "0:$_bif_all"
# The same, piece by piece, so a failure says which part is wrong. Each piece
# reads only the four live folds' lines, so a branch wrongly added fails the
# assertion about that branch below and not these as well.
_bif_live() { printf '%s\n' "$_bif_out" | awk -F'\t' '
  $1 ~ /(^|\/)claude\/(handoff-fold-1001|a\/older-base|quoted-later|old-fold)$/'; }
is  "the branch is named under the remote, without origin/ or refs/remotes/" \
    "$(_bif_live | cut -f1 | tr '\n' ' ')" "claude/handoff-fold-1001 claude/a/older-base claude/quoted-later claude/old-fold "
# Name order would put claude/a/older-base first and id order claude/quoted-
# later; only tip time puts claude/handoff-fold-1001 first.
is  "folds are ordered by tip time, newest first, not by name or by id" \
    "$(_bif_live | awk -F'\t' '{ sub(/.*\/claude\//, "claude/", $1); printf "%s ", $1 }')" \
    "claude/handoff-fold-1001 claude/a/older-base claude/quoted-later claude/old-fold "
# claude/quoted-later quotes (after 0aa comes 0ab) below its marker: its id is
# the first match, 0cl; a last-match reader would drop it as behind main.
is  "each id is the branch's current id from its first marker, not a phrase quoted lower down" \
    "$(_bif_live | awk -F'\t' '{ sub(/.*\/claude\//, "claude/", $1); print $1 "=" $2 }' | LC_ALL=C sort | tr '\n' ' ')" \
    "claude/a/older-base=0ci claude/handoff-fold-1001=0cj claude/old-fold=0ck claude/quoted-later=0cl "
is  "and the third field is the tip's committer time in Unix seconds" \
    "$(_bif_live | awk -F'\t' '$1 ~ /handoff-fold-1001$/ { print $3 }')" "$(_bif_ago 2730)"
# Each reason a branch is not a fold in flight, one by one.
_bif_not "a branch that only adds a pending file, its marker equal to main's, is not in flight" claude/pending-only
_bif_not "a fold main has already taken (its tip is in main, its marker is main's) is not in flight" claude/landed
# claude/stale's marker, 0ci, is after main's 0cg, so (a) alone would count it;
# its merge-base holds 0ce, so it folded a main that has since moved.
_bif_not "a fold cut from an older main whose handoff has since moved is stale, not in flight" claude/stale
# claude/behind is cut from main's tip and only its marker differs: a check of
# "different from main's" rather than "after main's" would count it.
_bif_not "a branch whose marker is behind main's, though cut from main's tip, is not in flight" claude/behind
_bif_not "a branch whose first marker is main's is not in flight, whatever id it quotes lower down" claude/quoted
_bif_not "a branch whose HANDOFF.md has no marker is not in flight" claude/no-marker
_bif_not "a branch with no HANDOFF.md is not in flight" claude/no-handoff
# The newest live fold in the fixture is a local branch: only what others can
# see on the remote is a fold another session would collide with.
_bif_not "a local branch (refs/heads) is never counted, though it holds a live fold" local-fold
_bif_not "a branch under another remote is not counted for origin/main" claude/elsewhere

# (c): a bound in seconds leaves out a fold nobody has touched for longer, so
# an abandoned fold lets the row fall due again rather than silencing it.
_bif_run "$_bif_r" refs/remotes/origin/main 172800
is  "given a bound of 48 hours in seconds, a fold whose tip is 72 hours old is left out" "$_bif_rc:$_bif_out" "0:$_bif_48"
_bif_run "$_bif_r" refs/remotes/origin/main 5000
is  "a bound of 5000 seconds keeps only the fold whose tip is 2730 seconds old" "$_bif_rc:$_bif_out" "0:$_bif_L_fold"
_bif_run "$_bif_r" refs/remotes/origin/main 0
is  "a bound of 0 is no bound" "$_bif_rc:$_bif_out" "0:$_bif_all"
_bif_run "$_bif_r" origin/main
is  "the short form origin/main is read as refs/remotes/origin/main" "$_bif_rc:$_bif_out" "0:$_bif_all"
_bif_out="$( ( cd "$TMP" && . "$REAL_HARNESS/lib/handoff.sh" && felix_handoff_in_flight "$_bif_r" refs/remotes/origin/main ) 2>/dev/null)"; _bif_rc=$?
is  "it examines the checkout it is given as <root>, from any working directory" "$_bif_rc:$_bif_out" "0:$_bif_all"
# origin/HEAD is a symbolic ref. Pointed at a live fold, it would name that
# fold a second time, as HEAD, if symbolic refs were not passed over.
_bif_git symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/claude/handoff-fold-1001
_bif_run "$_bif_r" refs/remotes/origin/main
_bif_git symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/main
is  "a symbolic ref such as origin/HEAD is never counted, even when it points at a fold in flight" "$_bif_rc:$_bif_out" "0:$_bif_all"
# Spec: no gh. A gh first on PATH records that it ran.
_bif_stub="$TMP/bif-stub"; mkdir -p "$_bif_stub"
printf '#!/bin/sh\n: > "%s/gh-ran"\nexit 1\n' "$_bif_stub" > "$_bif_stub/gh"; chmod +x "$_bif_stub/gh"
_bif_out="$(PATH="$_bif_stub:$PATH" _bif_fn "$_bif_r" refs/remotes/origin/main)"; _bif_rc=$?
is  "it reads the folds in flight from git alone and never runs gh" \
    "$_bif_rc:$_bif_out:$([ -e "$_bif_stub/gh-ran" ] && echo gh-ran)" "0:$_bif_all:"

# Fold order: a longer id is later, and ids of one length compare letter by
# letter. A string compare passes ord1 and fails ord2 and ord3 both ways round.
_bif_run "$_bif_r" refs/remotes/ord1/main
is  "fold order: 0da is after 0cz, so a fold to 0da from a main at 0cz is in flight" "$_bif_rc:$_bif_out" "0:$(_bif_e f 0da 1000)"
_bif_run "$_bif_r" refs/remotes/ord2/main
is  "fold order: 0aaa is after 0zz, though it sorts before it as a string" "$_bif_rc:$_bif_out" "0:$(_bif_e f 0aaa 1000)"
_bif_run "$_bif_r" refs/remotes/ord3/main
is  "fold order: 0zz is before 0aaa, though it sorts after it as a string, so it is not in flight" "$_bif_rc:$_bif_out" "0:"
_bif_run "$_bif_r" refs/remotes/calm/main
is  "with nothing in flight it prints nothing and exits 0" "$_bif_rc:$_bif_out" "0:"

# Cannot examine: exit 2 and one line on stdout saying why, never the silent
# exit 0 that means "nothing in flight", since the row would then read ok.
_bif_run "$_bif_r" refs/remotes/origin/nonesuch
is  "a ref that does not resolve cannot be examined: exit 2, one line on stdout" "$_bif_rc:$(_bif_lines "$_bif_out")" "2:1"
_bif_run "$_bif_r" "$_bif_M2"
is  "a bare commit is not a remote-tracking ref: exit 2, one line" "$_bif_rc:$(_bif_lines "$_bif_out")" "2:1"
# refs/heads/main holds the same commit as origin/main, so code that took any
# ref would answer as if for origin/main.
_bif_run "$_bif_r" refs/heads/main
is  "a local branch is not a remote-tracking ref, though it holds main's commit: exit 2, one line" "$_bif_rc:$(_bif_lines "$_bif_out")" "2:1"
_bif_run "$_bif_r" refs/remotes/origin/claude/no-handoff
is  "a ref with no HANDOFF.md cannot be examined: exit 2, one line" "$_bif_rc:$(_bif_lines "$_bif_out")" "2:1"
_bif_run "$_bif_r" refs/remotes/origin/claude/no-marker
is  "a ref whose HANDOFF.md has no marker cannot be examined: exit 2, one line" "$_bif_rc:$(_bif_lines "$_bif_out")" "2:1"

# The script. Its exit status follows grep's, so it can stand as the tail of a
# maintenance check: 0 named something, 1 found nothing, 2 could not look.
_bif_bin() { "$REAL_HARNESS/bin/handoff-in-flight" "$@" 2>/dev/null; }
# <dir> <args...>: runs it in <dir>, noting the clock either side of the run.
_bif_brun() {
  _bif_dir="$1"; shift
  _bif_t0="$(date +%s)"; _bif_out="$(cd "$_bif_dir" && _bif_bin "$@")"; _bif_rc=$?; _bif_t1="$(date +%s)"
}
# <now> then <branch> <id> <epoch> triples: the human lines the spec gives,
# `<branch> (folded to <id>; tip <age> old)`, <age> as whole minutes under an
# hour and whole hours otherwise, rounded down.
_bif_human() {
  _bif_hn="$1"; shift; _bif_hs=""
  while [ $# -ge 3 ]; do
    _bif_hd=$((_bif_hn - $3))
    if [ "$_bif_hd" -lt 3600 ]; then _bif_ha="$((_bif_hd / 60))m"; else _bif_ha="$((_bif_hd / 3600))h"; fi
    _bif_hs="$_bif_hs${_bif_hs:+
}$1 (folded to $2; tip $_bif_ha old)"; shift 3
  done
  printf '%s' "$_bif_hs"
}
# <assertion> <exit> <triples...>: the run's status and output equal the lines
# for the clock as it read just before the run or just after it, so a minute
# that turns over while it runs does not fail an age the script got right.
_bif_isage() {
  _bif_in="$1"; _bif_ix="$2"; shift 2
  _bif_ia="$_bif_ix:$(_bif_human "$_bif_t0" "$@")"; _bif_ib="$_bif_ix:$(_bif_human "$_bif_t1" "$@")"
  if [ "$_bif_rc:$_bif_out" = "$_bif_ia" ] || [ "$_bif_rc:$_bif_out" = "$_bif_ib" ]; then ok "$_bif_in"
  else bad "$_bif_in" "expected [$_bif_ia] got [$_bif_rc:$_bif_out]"; fi
}
# <assertion> <dir> <args...>: exit 2 and one stdout line starting "cannot examine".
_bif_cant() {
  _bif_cn="$1"; shift; _bif_brun "$@"
  case "$_bif_rc:$(_bif_lines "$_bif_out"):$_bif_out" in
    "2:1:cannot examine"*) ok "$_bif_cn" ;;
    *) bad "$_bif_cn" "expected exit 2 and one line starting 'cannot examine', got $_bif_rc: [$_bif_out]" ;;
  esac
}
_bif_T_fold="claude/handoff-fold-1001 0cj $(_bif_ago 2730)"
_bif_T_base="claude/a/older-base 0ci $(_bif_ago 9030)"
_bif_T_quot="claude/quoted-later 0cl $(_bif_ago 20030)"
_bif_T_old="claude/old-fold 0ck $(_bif_ago 259230)"

# The triples below are meant to split into words.
_bif_brun "$_bif_r/deep/er"
_bif_isage "bin/handoff-in-flight, run from a subdirectory with no arguments, reads origin/main within 48 hours and names each fold, newest first, exit 0" \
    0 $_bif_T_fold $_bif_T_base $_bif_T_quot
_bif_brun "$_bif_r" --within 0
_bif_isage "handoff-in-flight --within 0 is no bound, and a tip 72 hours old is said in hours" \
    0 $_bif_T_fold $_bif_T_base $_bif_T_quot $_bif_T_old
_bif_brun "$_bif_r" --within 3
_bif_isage "handoff-in-flight --within 3 is three hours: the 5-hour and 72-hour tips are left out" \
    0 $_bif_T_fold $_bif_T_base
_bif_brun "$_bif_r" --within 100
_bif_isage "handoff-in-flight --within 100 is a hundred hours, so the 72-hour tip is named" \
    0 $_bif_T_fold $_bif_T_base $_bif_T_quot $_bif_T_old
_bif_brun "$_bif_r" origin/main
_bif_isage "handoff-in-flight takes the ref as its argument, the short form included" \
    0 $_bif_T_fold $_bif_T_base $_bif_T_quot
# The same answer with a recording gh first on PATH, and the record still absent.
rm -f "$_bif_stub/gh-ran"
_bif_t0="$(date +%s)"; _bif_out="$(cd "$_bif_r" && PATH="$_bif_stub:$PATH" _bif_bin)"; _bif_rc=$?; _bif_t1="$(date +%s)"
[ -e "$_bif_stub/gh-ran" ] && _bif_out="$_bif_out (and gh ran)"
_bif_isage "handoff-in-flight answers from git alone and never runs gh" 0 $_bif_T_fold $_bif_T_base $_bif_T_quot
_bif_brun "$_bif_r" refs/remotes/calm/main
is  "handoff-in-flight with nothing in flight exits 1 and prints nothing, as grep does" "$_bif_rc:$_bif_out" "1:"

_bif_cant "handoff-in-flight on a ref that does not resolve exits 2: cannot examine" "$_bif_r" refs/remotes/origin/nonesuch
_bif_cant "handoff-in-flight on a local branch exits 2: not a remote-tracking ref" "$_bif_r" refs/heads/main
_bif_cant "handoff-in-flight on a ref with no marker exits 2: cannot examine" "$_bif_r" refs/remotes/origin/claude/no-marker
mkdir -p "$TMP/bif-nogit"
_bif_cant "handoff-in-flight outside any checkout exits 2, since origin/main does not resolve" "$TMP/bif-nogit"
# A bound that is not a whole number of hours, or an option it does not know,
# must not be read as "no bound" or as a ref: it cannot examine.
_bif_cant "handoff-in-flight --within abc exits 2: cannot examine" "$_bif_r" --within abc
_bif_cant "handoff-in-flight --within 1.5 exits 2, since hours are whole" "$_bif_r" --within 1.5
_bif_cant "handoff-in-flight --within with no value exits 2" "$_bif_r" --within
_bif_cant "handoff-in-flight with an unknown option exits 2" "$_bif_r" --frobnicate

# The age in the human line. Built now, just before it is read, at ages each
# about thirty seconds inside its unit: 0m under a minute, rounded down to 45m
# not 46m, 59m below the hour, 1h just past it, 2h for two and a half, and 72h
# rather than days.
_bif_n2="$(date +%s)"
_bif_pub age/main "$_bif_M2"
_bif_pub age/a0   "$(_bif_fold "$_bif_M2" 0ch 0ci "$((_bif_n2 - 10))")"
_bif_pub age/a1   "$(_bif_fold "$_bif_M2" 0ci 0cj "$((_bif_n2 - 90))")"
_bif_pub age/a45  "$(_bif_fold "$_bif_M2" 0cj 0ck "$((_bif_n2 - 2730))")"
_bif_pub age/a59  "$(_bif_fold "$_bif_M2" 0ck 0cl "$((_bif_n2 - 3570))")"
_bif_pub age/a60  "$(_bif_fold "$_bif_M2" 0cl 0cm "$((_bif_n2 - 3630))")"
_bif_pub age/a150 "$(_bif_fold "$_bif_M2" 0cm 0cn "$((_bif_n2 - 9030))")"
_bif_pub age/a72h "$(_bif_fold "$_bif_M2" 0cn 0co "$((_bif_n2 - 259230))")"
_bif_at refs/remotes/origin/claude/no-handoff
_bif_brun "$_bif_r" --within 0 refs/remotes/age/main
_bif_isage "the age is whole minutes under an hour and whole hours otherwise, rounded down: 0m 1m 45m 59m 1h 2h 72h" \
    0 a0 0ch "$((_bif_n2 - 10))" a1 0ci "$((_bif_n2 - 90))" a45 0cj "$((_bif_n2 - 2730))" \
      a59 0ck "$((_bif_n2 - 3570))" a60 0cl "$((_bif_n2 - 3630))" a150 0cm "$((_bif_n2 - 9030))" \
      a72h 0cn "$((_bif_n2 - 259230))"

printf '\na fold in flight: the shapes an adversarial review found\n'
# Four shapes the blind assertions above did not reach, each reproduced by a
# reviewer against the first version of this code and each shown red against
# it before the fix.
_brv="$TMP/brv"; mkdir -p "$_brv"
( _fx_cd "$_brv" && git init -q -b main && git config user.name t && git config user.email t@example.invalid )
_brv_c() {   # message, epoch, marker-id [, extra file]: commit HANDOFF.md holding that marker
  printf '# Handoff\n\nFold with felix handoff --rotate (after %s comes x).\n' "$3" \
    | sed "s/comes x/comes $(cd "$_brv" && . "$REAL_HARNESS/lib/handoff.sh" && felix_handoff_next_id "$3")/" > "$_brv/HANDOFF.md"
  [ -z "${4:-}" ] || printf '%s\n' "$4" > "$_brv/$4.txt"
  _fx_git "$_brv" add -A && GIT_COMMITTER_DATE="@$2 +0000" GIT_AUTHOR_DATE="@$2 +0000" _fx_git "$_brv" commit -q -m "$1"
  git -C "$_brv" rev-parse HEAD
}
_brv_if() { ( cd "$_brv" && . "$1/lib/handoff.sh" && felix_handoff_in_flight "$_brv" refs/remotes/origin/main "${2:-0}" ); }
_brv_now="$(date +%s)"

# 1. A criss-cross. F is cut from T0 and adds a file at f1; a fold lands on
# main as t1; F merges t1; main takes f1 with a true merge; F then folds
# main's current handoff. F's merge-bases with main are f1 (before main's
# fold) and t1 (after it), and git prints whichever its dates favour. Read
# alone, f1 hid a fold that could land.
_brv_t0="$(_brv_c T0 1000000000 0bz)"
_fx_git "$_brv" checkout -q -b F
_brv_f1="$(printf 'p4\n' > "$_brv/p4.txt"; _fx_git "$_brv" add -A && GIT_COMMITTER_DATE="@1000000250 +0000" _fx_git "$_brv" commit -q -m f1 && git -C "$_brv" rev-parse HEAD)"
_fx_git "$_brv" checkout -q -b G "$_brv_t0"
_brv_t1="$(_brv_c "fold G" 1000000200 0cc)"
_fx_git "$_brv" checkout -q F
GIT_COMMITTER_DATE="@1000000300 +0000" _fx_git "$_brv" merge -q --no-edit "$_brv_t1" >/dev/null 2>&1
_fx_git "$_brv" checkout -q -b land "$_brv_t1"
GIT_COMMITTER_DATE="@1000000400 +0000" _fx_git "$_brv" merge -q --no-ff --no-edit "$_brv_f1" >/dev/null 2>&1
_fx_git "$_brv" update-ref refs/remotes/origin/main "$(git -C "$_brv" rev-parse HEAD)"
_fx_git "$_brv" checkout -q F
_brv_f3="$(_brv_c "fold F" 1000000500 0cd)"
_fx_git "$_brv" update-ref refs/remotes/origin/claude/criss "$_brv_f3"
is  "a criss-cross fold has two merge-bases, one before main's fold and one after it" \
    "$(git -C "$_brv" merge-base --all "$_brv_f3" refs/remotes/origin/main | wc -l | tr -d ' ')" "2"
is  "and it is named however git orders its merge-bases, since every base is read" \
    "$(_brv_if "$REAL_HARNESS" | cut -f1,2)" "$(printf 'claude/criss\t0cd')"
_fx_git "$_brv" update-ref -d refs/remotes/origin/claude/criss

# 2. A branch pruned between the listing and the read. Every session shares
# refs/remotes, so a fetch --prune in another worktree can delete a ref the
# listing just returned. git grep resolves every name before it reads any and
# died on that one, printing nothing for the rest: main read as unmarked and
# the run as "cannot examine". The shim deletes the ref right after git lists
# it, which is the same thing on a fixed schedule.
_fx_git "$_brv" checkout -q -b main2 refs/remotes/origin/main
_brv_live="$(_brv_c live "$_brv_now" 0cd)"
_fx_git "$_brv" update-ref refs/remotes/origin/claude/live "$_brv_live"
_fx_git "$_brv" checkout -q -b old "$_brv_t0"
_brv_gone="$(_brv_c gone "$_brv_now" 0bz gone)"
_fx_git "$_brv" update-ref refs/remotes/origin/claude/gone "$_brv_gone"
mkdir -p "$_brv/shim"
_brv_git="$(command -v git)"
cat > "$_brv/shim/git" <<EOF
#!/usr/bin/env bash
"$_brv_git" "\$@"; rc=\$?
case " \$* " in *" for-each-ref "*) "$_brv_git" -C "$_brv" update-ref -d refs/remotes/origin/claude/gone ;; esac
exit \$rc
EOF
chmod +x "$_brv/shim/git"
_brv_out="$(PATH="$_brv/shim:$PATH" _brv_if "$REAL_HARNESS")"; _brv_rc=$?
is  "a branch pruned after it was listed does not blank the read: main is still read, the live fold still named" \
    "$_brv_rc:$(printf '%s\n' "$_brv_out" | cut -f1,2 | tr '\t' ' ')" "0:claude/live 0cd"
git -C "$_brv" rev-parse --verify --quiet refs/remotes/origin/claude/gone >/dev/null \
  && bad "and the shim did prune it, so the line above read the race" "the ref is still there" \
  || ok  "and the shim did prune it, so the line above read the race"

# 3. A tip dated ahead of this clock. It passed the age bound for as long as
# it stayed ahead, and the script showed it as 0m old.
_fx_git "$_brv" checkout -q -b ahead refs/remotes/origin/main
_fx_git "$_brv" update-ref -d refs/remotes/origin/claude/live
_brv_ahead="$(_brv_c ahead $((_brv_now + 7200)) 0cd)"
_fx_git "$_brv" update-ref refs/remotes/origin/claude/ahead "$_brv_ahead"
is  "a tip dated two hours ahead is not trusted as fresh under a bound" \
    "$(_brv_if "$REAL_HARNESS" 172800)" ""
is  "with no bound it is named" "$(_brv_if "$REAL_HARNESS" 0 | cut -f1)" "claude/ahead"
has "and the script says it is dated ahead, rather than 0m old" \
    "$(cd "$_brv" && "$REAL_HARNESS/bin/handoff-in-flight" --within 0)" "claude/ahead (folded to 0cd; tip dated ahead of this clock)"

# 4. A check that prints a control byte. It reached the session start's JSON,
# whose escaping knows backslash, quote, \n, \r and \t only, and one escape
# byte made the whole hook output unreadable.
_brv_wt="$FROOT/projects/widget/maintenance.tsv"
cp "$_brv_wt" "$TMP/brv-widget-maint.keep" 2>/dev/null || : > "$TMP/brv-widget-maint.keep"
printf 'brvesc\t0\talways\tprints an escape\tprintf '"'"'x\\033[31my\\001z\\n'"'"'\n' > "$_brv_wt"
_brv_st="$( ( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/detect.sh"
              . "$FROOT/harness/lib/maintenance.sh"; felix_maint_status "$FROOT/projects/widget" "$REPO" ) )"
is  "a holder keeps its text and drops its control bytes" \
    "$(printf '%s\n' "$_brv_st" | awk -F'\t' '$2 == "brvesc" { print $1 "|" $3 }')" "inflight|x[31myz"
_brv_out="$(cd "$REPO" && CLAUDE_PLUGIN_ROOT="$FROOT" "$FROOT/harness/hooks/session-start" 2>/dev/null)"
printf '%s' "$_brv_out" | python3 -c 'import json,sys; json.load(sys.stdin)' >/dev/null 2>&1 \
  && ok  "so the session start's output is still JSON" \
  || bad "so the session start's output is still JSON" "$(printf '%s' "$_brv_out" | head -c 300)"
has "and the line names it" "$_brv_out" "Already in flight, so not due: brvesc on x[31myz"
cp "$TMP/brv-widget-maint.keep" "$_brv_wt"

