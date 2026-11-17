printf '\nthe record this branch carries\n'
# Raised by the same review. After a rebase, red.tsv held two runs' records
# concatenated, against a base two merges back, naming an assertion this suite
# no longer has, and the engine's version was below the one main had taken.
# These read the tree's own record and, where origin/main is known, git. The
# first three skip while --record-assertions is about to rewrite the record,
# and all four in the red run, which stands in the base's tree and would read
# the base's record. Every other assertion in this block asks this tree's own
# helpers, of records and repositories built here or of the history the suite
# stands in, and runs in the red run as in any other, since the run placed in
# the base is this tree's: until #371 they sat behind the red run's test with
# the four, and a red run reached none of them.
_rtn1="red.tsv is one record, written whole: one base row, one run row, failed names that add up to the run's failed count, and a run that counts at least as many assertions as the manifest lists"
_rtn2="every assertion red.tsv names as red is one the manifest lists"
_rtn3="red.tsv was recorded against the engine origin/main held where this tree branched from it"
_rtn4="this engine's version is above origin/main's when this tree holds commits origin/main lacks"
# Whether a red.tsv is one record as tests/red writes one: ok, or bad and why,
# on one line. Beyond one base row, one run row and names that add up to the
# failed count, the rows must agree, both - when no red run was made and both
# real when one was, and a real run counts at least one assertion, since
# tests/red refuses a run that reached none. A run row of - beside any base
# once passed, so a sha pasted into a retraction's base row answered _rtn3's
# failure of it (#371, second review, 2026-09-25). Given the manifest beside
# the record, a real run also counts at least the manifest's total: tests/red
# counts every name the manifest lists, reached or red by its shortfall, so a
# run that counts fewer was not written by it against this manifest. It was
# written by a tests/red that did not compare, of a suite cut short, as 0 of
# 270 was against some 3,700, or of one that reached its end with assertions
# lost on the way, as main's own record at 27573cbe counts 3,894 against
# 3,900; or the manifest changed after it was written (#371's follow-up). A
# manifest that is not there is not compared.
_rt_record_whole() {   # <red.tsv> [<manifest>] -> ok, or bad <detail>
  local b r f s m=""
  [ -n "${2:-}" ] && [ -f "$2" ] && m="$(awk -F'\t' '$1 ~ /^[0-9]+$/ { t += $1 } END { printf "%.0f", t }' "$2")"
  read -r b r f s <<< "$(awk -F'\t' '/^#/ || !NF { next }
    $1 == "base" { b++; next } $1 == "run" { r++; f = $2; next } { s += $NF }
    END { printf "%d %d %s %d\n", b, r, (f == "" ? "?" : f), s }' "$1")"
  [ "$b" = 1 ] && [ "$r" = 1 ] && { [ "$f" = "$s" ] || { [ "$f" = "-" ] && [ "$s" = 0 ]; }; } \
    || { echo "bad base rows: $b, run rows: $r, the run's failed: $f, the names' total: $s"; return 0; }
  _RT_M="$m" awk -F'\t' '/^#/ || !NF { next }
    $1 == "base" { base = $3; next } $1 == "run" { f = $2; p = $3; k = $4; next } { n++ }
    END {
      run = "[" f " " p " " k "]"; dash = (f == "-" && p == "-" && k == "-"); again = ": re-record with tests/run --record-assertions"
      if (base == "-" && !dash) print "bad the base is - beside a run row of " run ", and tests/red writes both rows - or both real" again
      else if (dash && base != "-") print "bad the run row is - beside a base of " (base == "" ? "(none)" : base) ", and tests/red writes both rows - or both real" again
      else if (dash && n) print "bad the base and run rows are -, yet " n " names are listed below them" again
      else if (dash) print "ok"
      else if (f !~ /^[0-9]+$/ || p !~ /^[0-9]+$/ || k !~ /^[0-9]+$/) print "bad the run row reads " run ", which is not three counts of zero or more" again
      else if (f + p + k < 1) print "bad the run row counts no assertion, a run tests/red refuses to record" again
      else if (ENVIRON["_RT_M"] != "" && f + p + k < ENVIRON["_RT_M"] + 0)
        print "bad the run row counts " f + p + k " assertions, fewer than the " ENVIRON["_RT_M"] " the manifest lists, and tests/red counts every one it lists, reached or red" again
      else print "ok"
    }' "$1"
}
# How _rtn1 and _rtn3 report a check's verdict line, written once so that it
# can be asked of lines written for it below: each wrote the mapping out, and
# turning its bad into skip or ok left the suite green (#371, third review).
# A line that is none of the three, empty or more than one included, fails,
# naming what it read, since a check that said nothing readable has not passed.
_rt_report() {   # <name> <verdict line>
  case "$2" in
    *$'\n'*)   bad  "$1" "the check's verdict is more than one line: [$2]" ;;
    ok)        ok   "$1" ;;
    "skip "?*) skip "$1" "${2#skip }" ;;
    "bad "?*)  bad  "$1" "${2#bad }" ;;
    *)         bad  "$1" "the check's verdict reads [$2], which is none of ok, skip <reason> or bad <detail>" ;;
  esac
}
# Reads this suite's own repository, which sits outside $TMP, so it names its
# subcommand: the lint reads a parameter in that place as a write, and _fx_git
# refuses a directory outside $TMP.
_rtg() { git -C "$REAL_HARNESS" rev-list "$@" 2>/dev/null; }
_rtv() { sed -n '/"version"/{s/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p;q;}'; }
# Whether every base the record names is a commit in this repository. The
# record names its base by id, and a published snapshot carries the private
# repository's record into a history where that id was never a commit, so
# the base question cannot be asked there. Found by the first run of
# projects/felix/snapshot.sh, 2026-09-22: the public build failed on it. It
# asks the checkout named second, this suite's own when none is, so that the
# base check can be asked of a fixture (#371).
_rt_base_in() {   # <bases, space-separated> [<checkout>]
  local b; [ -n "$1" ] || return 1
  for b in $1; do git -C "${2:-$REAL_HARNESS}" cat-file -e "$b^{commit}" 2>/dev/null || return 1; done; return 0
}
# Both answers, on this repository's own history: an id that is no commit
# here, and its root, which is.
_rtroot="$(_rtg --max-parents=0 HEAD | head -1)"
# What kind of base the record names, one word of four. tests/red records a
# base of - when it made no red run, and - is no commit either, so the base
# check skipped a retraction as though it were a published snapshot and an
# engine change whose red run was never made passed (#371). Any other base is
# one commit id as tests/red writes it, forty lower-case hex digits: a commit
# here, or a snapshot's when it is not. Anything else is malformed, an empty
# base, more than one, and a value git resolves but tests/red never writes.
# A base edited by hand to origin/main read as a commit and, resolving afresh
# after every merge of main, never went stale; a branch or an abbreviated id
# is refused with it, since tests/red never writes those either (#371, third
# review). Asked on this repository's own history, as the two above are: its
# root is a commit here, forty zeros a full id that is not, and deadbeef an
# abbreviated one that is not. Like _rt_base_in, it asks the checkout named
# second, this suite's by default.
_rt_base_kind() {   # <the base field of every base row, space-separated> [<checkout>] -> one word
  case "$1" in
    -) echo retracted; return 0 ;;
    ''|*[!0123456789abcdef]*) echo malformed; return 0 ;;
  esac
  if [ "${#1}" -ne 40 ]; then echo malformed
  elif _rt_base_in "$1" "${2:-}"; then echo commit
  else echo snapshot; fi
}
_rtkn1="a red.tsv base of - reads as retracted, not as a published snapshot"
_rtkn2="and a base that is a commit here reads as a commit"
_rtkn3="and a full commit id that is no commit here reads as a snapshot"
_rtkn4="and an abbreviated id that is no commit here reads as malformed, not as a snapshot"
_rtkn5="and an empty base, as a record with no base row gives, reads as malformed"
_rtkn6="and two bases, even one a commit here, read as malformed"
# And four at the edges, so that loosening the rule fails here rather than
# letting a base written by hand pass for one tests/red wrote: two bases that
# are each a commit here are still two, and a snapshot's base is one commit
# id as git prints it, forty lower-case hex digits, which forty letters that
# are not hex, forty-one digits and forty upper-case ones are not. The six
# above left each of those loosenings green (#371, second review, 2026-09-25).
_rtkn7="and two bases that are each a commit here read as malformed, not as a commit"
_rtkn8="and forty characters that are not hex digits read as malformed, not as a snapshot"
_rtkn9="and forty-one hex digits read as malformed, not as a snapshot"
_rtkn10="and forty upper-case hex digits that are no commit here read as malformed, not as a snapshot"
# And a commit is one as tests/red writes a base, the forty lower-case hex
# digits git rev-parse prints, that is a commit here. Any value git resolved
# read as a commit, ref names included, so a base edited by hand to
# origin/main passed _rtn3 after every merge of main and never went stale
# (#371, third review); main and an abbreviated id are refused with it, since
# tests/red never writes those either. Asked with HEAD, since this suite's
# own checkout may have no origin/main, and with the root above cut to twelve
# characters and spelled in upper case.
_rtkn11="and HEAD, which git resolves to a commit here, reads as malformed, since tests/red writes a base as a full id"
_rtkn12="and the first twelve characters of a commit here read as malformed, not as a commit"
_rtkn13="and a commit here spelled in forty upper-case hex digits reads as malformed, not as a commit"
if [ -n "$_rtroot" ]; then
  _rt_base_in 0000000000000000000000000000000000000000 \
    && bad "a red.tsv base that is no commit here is told apart, so the base check skips in a published snapshot" "0000… read as a commit" \
    || ok  "a red.tsv base that is no commit here is told apart, so the base check skips in a published snapshot"
  _rt_base_in "$_rtroot" \
    && ok  "and a base that is a commit here is still compared, so a stale record still fails" \
    || bad "and a base that is a commit here is still compared, so a stale record still fails" "root $_rtroot not read as a commit"
  is "$_rtkn1" "$(_rt_base_kind -)" retracted
  is "$_rtkn2" "$(_rt_base_kind "$_rtroot")" commit
  is "$_rtkn3" "$(_rt_base_kind 0000000000000000000000000000000000000000)" snapshot
  is "$_rtkn4" "$(_rt_base_kind deadbeef)" malformed
  is "$_rtkn5" "$(_rt_base_kind "")" malformed
  is "$_rtkn6" "$(_rt_base_kind "$_rtroot -")" malformed
  is "$_rtkn7" "$(_rt_base_kind "$_rtroot $_rtroot")" malformed
  is "$_rtkn8" "$(_rt_base_kind gggggggggggggggggggggggggggggggggggggggg)" malformed
  is "$_rtkn9" "$(_rt_base_kind 00000000000000000000000000000000000000000)" malformed
  is "$_rtkn10" "$(_rt_base_kind AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA)" malformed
  is "$_rtkn11" "$(_rt_base_kind HEAD)" malformed
  is "$_rtkn12" "$(_rt_base_kind "${_rtroot:0:12}")" malformed
  is "$_rtkn13" "$(_rt_base_kind "$(printf '%s' "$_rtroot" | tr abcdef ABCDEF)")" malformed
else
  skip "a red.tsv base that is no commit here is told apart, so the base check skips in a published snapshot" "no git history beside this suite"
  skip "and a base that is a commit here is still compared, so a stale record still fails" "no git history beside this suite"
  for _n in "$_rtkn1" "$_rtkn2" "$_rtkn3" "$_rtkn4" "$_rtkn5" "$_rtkn6" "$_rtkn7" "$_rtkn8" "$_rtkn9" "$_rtkn10" \
            "$_rtkn11" "$_rtkn12" "$_rtkn13"; do
    skip "$_n" "no git history beside this suite"
  done
fi
# Whether the engine in this checkout is origin/main's, working tree
# included. The record and the version belong to the engine: a branch that
# changes only docs or a project's doctrine carries main's record and main's
# version, rightly, and asking it for a new one failed every such branch
# (found on 2026-09-22, the first docs-only pull request after these checks
# merged). A change under engine/, tests included, still owes both.
_rt_engine_same() { git -C "$1" diff --quiet refs/remotes/origin/main -- :/engine 2>/dev/null; }
# Both answers on a repository built here: a commit to docs keeps main's
# engine, a commit to engine/ does not.
_rtes="$TMP/rt-engine-same"; mkdir -p "$_rtes/engine" "$_rtes/docs"
( _fx_cd "$_rtes" && git init -q && git config user.email t@t && git config user.name t \
    && echo a > engine/x && echo a > docs/y && git add -A && git commit -qm base \
    && git update-ref refs/remotes/origin/main HEAD \
    && echo b > docs/y && git commit -qam docs ) >/dev/null 2>&1
_rt_engine_same "$_rtes" \
  && ok  "a branch that changes only docs keeps main's engine, so it owes no new red.tsv and no new version" \
  || bad "a branch that changes only docs keeps main's engine, so it owes no new red.tsv and no new version" "the docs-only fixture read as an engine change"
( _fx_cd "$_rtes" && echo b > engine/x && git commit -qam engine ) >/dev/null 2>&1
_rt_engine_same "$_rtes" \
  && bad "and a branch that changes engine/ still owes both" "the engine fixture read as main's engine" \
  || ok  "and a branch that changes engine/ still owes both"
# Whether red.tsv still describes the base this tree stands on. The record is
# this tree's assertions run against the engine at its base, so what it must
# match is that engine, not the commit around it. Until 2026-09-22 the check
# compared commits, and a merge to main that touched no engine file (#290,
# projects/felix/CLAUDE.md alone) staled every open engine pull request's
# record: each owed an eight-minute red run whose answer could not have
# changed, and one's CI failed on it (#291). Compared as engine/ trees, which
# hold the harness, this suite and plugin.json, a docs or projects merge
# leaves the record standing and any change under engine/ on main stales it.
_rt_engine_tree() { [ -n "$2" ] && git -C "$1" rev-parse -q --verify "$2:engine" 2>/dev/null; }
_rt_record_holds() {   # <checkout> <red.tsv's base sha>
  local mb t
  mb="$(git -C "$1" merge-base HEAD refs/remotes/origin/main 2>/dev/null)" || return 1
  t="$(_rt_engine_tree "$1" "$2")" || return 1
  [ "$t" = "$(_rt_engine_tree "$1" "$mb")" ]
}
# Both answers on a repository built here. The record is taken on main, main
# takes a docs commit, and the branch is rebased onto it; then main takes an
# engine commit and the branch is rebased again.
_rtrh="$TMP/rt-record-holds"; mkdir -p "$_rtrh/engine" "$_rtrh/docs"
( _fx_cd "$_rtrh" && git init -q && git config user.email t@t && git config user.name t \
    && echo a > engine/x && echo a > docs/y && git add -A && git commit -qm record \
    && echo b > docs/y && git commit -qam 'main: docs' \
    && git update-ref refs/remotes/origin/main HEAD \
    && echo b > engine/x && git commit -qam 'branch: engine' ) >/dev/null 2>&1
_rtrr="$(git -C "$_rtrh" rev-parse -q --verify 'HEAD~2' 2>/dev/null)"
_rtrn="a docs commit on main after red.tsv was recorded leaves the record standing, since the engine it ran against is the one the branch now stands on"
if [ -n "$_rtrr" ] && _rt_record_holds "$_rtrh" "$_rtrr"; then
  ok  "$_rtrn"
else
  bad "$_rtrn" "record ${_rtrr:-(none)}, merge-base $(git -C "$_rtrh" merge-base HEAD refs/remotes/origin/main 2>/dev/null)"
fi
( _fx_cd "$_rtrh" && git checkout -q --detach refs/remotes/origin/main \
    && echo c > engine/z && git add -A && git commit -qm 'main: engine' \
    && git update-ref refs/remotes/origin/main HEAD \
    && git checkout -q -b rebased && echo b > engine/x && git commit -qam 'branch: engine' ) >/dev/null 2>&1
# Fails for its own reason only when the fixture stands where it says: the
# branch's merge-base is main's engine commit, the record two commits back.
_rtrm="$(git -C "$_rtrh" merge-base HEAD refs/remotes/origin/main 2>/dev/null)"
_rtrn="and an engine commit on main after it stales the record"
if [ -n "$_rtrr" ] && [ "$(git -C "$_rtrh" log -1 --format=%s "$_rtrm" 2>/dev/null)" = "main: engine" ] \
   && ! _rt_record_holds "$_rtrh" "$_rtrr"; then
  ok  "$_rtrn"
else
  bad "$_rtrn" "record ${_rtrr:-(none)}, merge-base ${_rtrm:-(none)} ($(git -C "$_rtrh" log -1 --format=%s "$_rtrm" 2>/dev/null))"
fi
# The base question alone, asked of a checkout: ok, or skip and why, or bad
# and why, on one line. An engine change owes a red run, so a retraction
# (base -), which once skipped as a published snapshot and let an engine
# change whose red run was never made pass (#371), fails, as does a base
# that is not one full commit id; only a snapshot's full id still skips. The
# decision sat inside _rtn3, where no fixture reached it, so undoing it left
# this suite green (second review of #371); it is asked of fixtures below.
# Whether the question is owed at all is _rt_judge's. A published snapshot
# carrying a retraction fails too, rightly, since its engine's red run was
# never shown either, but it cannot re-record there, so the detail says where
# (#371, third review).
_rt_base_check() {   # <checkout> -> ok, skip <reason> or bad <detail>
  local bs mb
  bs="$(awk -F'\t' '$1 == "base" { printf "%s%s", s, $3; s = " " }' "$1/engine/harness/tests/red.tsv" 2>/dev/null)"
  case "$(_rt_base_kind "$bs" "$1")" in
    retracted)
      echo "bad red.tsv records that no red run was made (base -), and tests/red's stdout said why, if it finished: re-record with tests/run --record-assertions in the repository where the engine change was made" ;;
    malformed)
      echo "bad the record's base reads [$bs], which is neither - nor one commit id in forty lower-case hex digits, as tests/red writes it: re-record with tests/run --record-assertions" ;;
    snapshot)
      echo "skip its base is no commit in this repository's history, as in a published snapshot" ;;
    *)
      if _rt_record_holds "$1" "$bs"; then
        echo ok
      else
        mb="$(git -C "$1" merge-base HEAD refs/remotes/origin/main 2>/dev/null)"
        echo "bad the record's base ${bs:-(none)} holds engine $(_rt_engine_tree "$1" "$bs" || echo '(none)'), the merge-base ${mb:-(none)} holds $(_rt_engine_tree "$1" "$mb" || echo '(none)'): re-record with tests/run --record-assertions"
      fi ;;
  esac
}
# The whole judgment of a checkout's record: _rtn1 to _rtn4, each reported
# through ok, skip and bad, and whether each is asked, from the checkout's
# red.tsv, manifest, plugin.json and git. It reads them under
# <checkout>/engine, so it assumes the <root>/engine/harness layout, the one
# gate.sh, CI and snapshot.sh run this suite in. Made for this suite's own
# checkout alone, its report of _rtn3, then of _rtn1, could be a plain ok and
# leave every assertion green (#371, fourth review), so it is also asked of
# one below. Record mode, --record-assertions, in which the first three
# skip, is FELIX_TEST_RECORD at exactly 1, as the suite sets it, read here
# rather than passed in by the suite's one call, where no assertion asked it
# (#371, fifth review). And an engine change with no red.tsv at all, as a
# red.tsv merge conflict resolved by removing the file leaves, fails _rtn3,
# since it still owes a record: the missing file skipped _rtn1 to _rtn3, and
# such a change passed (#371, fifth review). Where no record is owed, a
# missing red.tsv skips _rtn3 as it skips the first two. A red run,
# FELIX_TEST_NO_MANIFEST at exactly 1 as tests/red sets it, stands in the
# base's tree and would judge the base's record, so all four skip there; it
# is read here too, since decided at the suite's one call, a test there that
# took an unset variable for a red run skipped all four on every run with
# every assertion green (#371, sixth review).
_rt_judge() {   # <checkout>
  local c="$1" t="$1/engine/harness/tests/red.tsv" a="$1/engine/harness/tests/assertions.tsv" r="" s="" w n vh vm
  if [ "${FELIX_TEST_NO_MANIFEST:-}" = 1 ]; then
    for n in "$_rtn1" "$_rtn2" "$_rtn3" "$_rtn4"; do skip "$n" "a red run reads the base's record"; done
    return 0
  fi
  [ "${FELIX_TEST_RECORD:-}" = 1 ] && r="--record-assertions rewrites red.tsv after this run"
  s="$r"; [ -z "$s" ] && [ ! -f "$t" ] && s="no red.tsv beside this suite"
  if [ -n "$s" ]; then
    for n in "$_rtn1" "$_rtn2"; do skip "$n" "$s"; done
  else
    _rt_report "$_rtn1" "$(_rt_record_whole "$t" "$a")"
    if [ -f "$a" ]; then
      n="$(awk -F'\t' 'NR == FNR { m[$2] = 1; next } /^#/ || !NF || $1 == "base" || $1 == "run" { next }
                       !($1 in m) { print $1 }' "$a" "$t")"
      [ -z "$n" ] && ok "$_rtn2" || bad "$_rtn2" "not in the manifest: $(printf '%s\n' "$n" | head -3)"
    else
      skip "$_rtn2" "no manifest beside this suite"
    fi
  fi
  if ! git -C "$c" rev-parse -q --verify refs/remotes/origin/main >/dev/null 2>&1; then
    w="no origin/main to compare against"
    skip "$_rtn3" "${s:-$w}"
    skip "$_rtn4" "$w"
  elif git -C "$c" merge-base --is-ancestor HEAD refs/remotes/origin/main 2>/dev/null; then
    w="this tree holds no commit origin/main lacks"
    skip "$_rtn3" "${s:-$w}"
    skip "$_rtn4" "$w"
  elif _rt_engine_same "$c"; then
    w="this tree changes no engine file, so origin/main's record is still this engine's"
    skip "$_rtn3" "${s:-$w}"
    skip "$_rtn4" "this tree changes no engine file, so it keeps origin/main's version"
  else
    if [ -n "$r" ]; then
      skip "$_rtn3" "$r"
    elif [ -n "$s" ]; then
      bad "$_rtn3" "no red.tsv, and this tree changes engine files: record one with tests/run --record-assertions"
    else
      _rt_report "$_rtn3" "$(_rt_base_check "$c")"
    fi
    vh="$(_rtv < "$c/engine/.claude-plugin/plugin.json" 2>/dev/null)"
    vm="$(git -C "$c" show refs/remotes/origin/main:engine/.claude-plugin/plugin.json 2>/dev/null | _rtv)"
    [ -n "$vh" ] && [ -n "$vm" ] && [ "$(awk -v a="$vh" -v b="$vm" 'BEGIN {
        n = split(a, A, "."); m = split(b, B, "."); k = (n > m) ? n : m; r = 0
        for (i = 1; i <= k && !r; i++) r = (A[i] + 0 > B[i] + 0) ? 1 : (A[i] + 0 < B[i] + 0) ? -1 : 0
        print (r > 0) ? "above" : "not" }')" = "above" ] \
      && ok  "$_rtn4" \
      || bad "$_rtn4" "this tree declares ${vh:-nothing}, origin/main declares ${vm:-nothing}"
  fi
}
# This suite's own checkout, judged once; in a red run _rt_judge skips all four.
_rt_judge "$REAL_HARNESS/../.."
# That call is the one line here no fixture reaches. An assignment before it,
# a subshell around it or a test in front of it left every assertion green
# while the four checks skipped or went uncounted (#371, seventh review), so
# this file must hold it as one line of its own, unindented, and name the
# suite's checkout to _rt_judge nowhere else.
# restated, not blind (gate friction step 1, 2026-10-12): this asked for one
# call in the whole suite, and a record run now judges the record it wrote a
# second time, after red has finished rewriting red.tsv (tests/run, contract C3),
# so the driver holds a second call, indented, inside its record-mode branch.
# The parts still hold exactly one, bare and unindented, which is the one
# thing the seventh review of #371 needed, and the driver's is found by what it
# names and where it stands: one line naming the suite's checkout, none of them
# bare, and that line between the `if` that opens record mode and its `fi`.
# Nothing else in the driver or the parts names it.
_rtcall="_rt_judge \"\$REAL_HARNESS/../..\""
# The parts and the lib files: "nowhere else" holds of tests/lib too (contract C3).
_rtfiles=(); while IFS= read -r _rtf; do case "$_rtf" in */run) ;; *) _rtfiles[${#_rtfiles[@]}]="$_rtf" ;; esac; done < <(_suite_files)
_rtgot="$(_C="$_rtcall" awk '/^[[:space:]]*#/ { next } $0 == ENVIRON["_C"] { x++ } index($0, ENVIRON["_C"]) { y++ }
                          END { printf "%d exact, %d naming it", x, y }' "${_rtfiles[@]}")|$(_C="$_rtcall" awk '/^[[:space:]]*#/ { next }
                          /^if \[ "\$FELIX_TEST_RECORD" -eq 1 \]; then$/ { r = 1 } r && /^fi$/ { r = 0 }
                          $0 == ENVIRON["_C"] { x++ } index($0, ENVIRON["_C"]) { y++; if (r) z++ }
                          END { printf "%d exact, %d naming it, %d in the record branch", x, y, z }' "$HERE/run")"
# A count that is off says which files name the call, for whoever reads the red.
[ "$_rtgot" = "1 exact, 1 naming it|0 exact, 1 naming it, 1 in the record branch" ] \
  || _rtgot="$_rtgot [named in: $(grep -lF -- "$_rtcall" "${_rtfiles[@]}" "$HERE/run" | tr '\n' ' ')]"
is "the suite judges its own checkout's record with one bare call at the top level of its parts, and once more in the driver's record-mode branch, and nowhere else" \
   "$_rtgot" \
   "1 exact, 1 naming it|0 exact, 1 naming it, 1 in the record branch"
# Whether a helper printed one line whose first word is the verdict asked for
# and whose rest holds each phrase given.
_rt_said() {   # <name> <what the helper printed> <ok|skip|bad> [<phrase>...]
  local n="$1" o="$2" w="$3" r="" p; shift 3
  case "$o" in *' '*) r="${o#* }" ;; esac
  case "$o" in
    *$'\n'*) bad "$n" "more than one line: [$o]"; return 0 ;;
    "$w"|"$w "*) ;;
    *) bad "$n" "expected [$w ...] got [$o]"; return 0 ;;
  esac
  for p in "$@"; do case "$r" in *"$p"*) ;; *) bad "$n" "[$o] lacks [$p]"; return 0 ;; esac; done
  ok "$n"
}
# How _rtn1 and _rtn3 report a check's verdict line: _rt_report <name>
# <verdict> reports ok for ok, skip and the reason for skip <reason>, bad and
# the detail for bad <detail>, and bad, naming the line, for any line it
# cannot read. The mapping was written out in each, judged only against this
# repository's own red.tsv, so turning bad into skip or ok there, which
# reopens #371, left every assertion green (third review of #371). It is
# asked here with ok, skip and bad printing what they were asked to report, in
# a subshell, so that what is judged is the mapping alone and nothing counts.
_rt_reported() {   # <name> <verdict line> -> ok|<name>, skip|<name>|<reason> or bad|<name>|<detail>
  ( ok()   { printf 'ok|%s\n' "$1"; }
    skip() { printf 'skip|%s|%s\n' "$1" "${2-}"; }
    bad()  { printf 'bad|%s|%s\n' "$1" "${2-}"; }
    _rt_report "$1" "$2" )
}
_rtpn1="a check's verdict of ok is reported as a pass of the assertion it is reported for"
_rtpn2="and skip with a reason as a skip of it, giving the reason"
_rtpn3="and bad with a detail as a failure of it, giving the detail, not as a skip or a pass"
_rtpn4="and an empty verdict as a failure, with a detail, since a check that said nothing has not passed"
_rtpn5="and a verdict it cannot read, okay, as a failure whose detail names what it read"
is "$_rtpn1" "$(_rt_reported "a name" ok)" "ok|a name"
is "$_rtpn2" "$(_rt_reported "a name" "skip the reason, in words")" "skip|a name|the reason, in words"
is "$_rtpn3" "$(_rt_reported "a name" "bad the detail, in words")" "bad|a name|the detail, in words"
_rtpo="$(_rt_reported "a name" "")"
case "$_rtpo" in
  *$'\n'*)       bad "$_rtpn4" "more than one line: [$_rtpo]" ;;
  "bad|a name|"?*) ok  "$_rtpn4" ;;
  *)              bad "$_rtpn4" "expected [bad|a name|<a detail>] got [$_rtpo]" ;;
esac
_rtpo="$(_rt_reported "a name" okay)"
case "$_rtpo" in
  *$'\n'*)             bad "$_rtpn5" "more than one line: [$_rtpo]" ;;
  "bad|a name|"*okay*) ok  "$_rtpn5" ;;
  *)                   bad "$_rtpn5" "expected [bad|a name|<a detail naming okay>] got [$_rtpo]" ;;
esac
# And a verdict of more than one line is unreadable even when its first line
# reads as one: without the arm that says so, skip and the rest of the text
# passed for a skip (#371, fourth review). Reported once, as a failure; its
# detail holds the text it read, newline included, so the reports are counted
# as the lines that begin with a verdict.
_rtpn6="and a verdict of more than one line as one failure, even when its first line reads as a skip"
_rtpo="$(_rt_reported "a name" "$(printf 'skip a\nbad b')")"
case "$(printf '%s\n' "$_rtpo" | awk '/^(ok|skip|bad)[|]/ { n++ } END { print n + 0 }')/$_rtpo" in
  "1/bad|a name|"?*) ok  "$_rtpn6" ;;
  *)                 bad "$_rtpn6" "expected one report, [bad|a name|<a detail>], got [$_rtpo]" ;;
esac
# The base check, asked of a checkout rather than of this suite's own record.
# _rtn3 was judged only against this repository's red.tsv, which on any branch
# is one record, so no fixture reached the decision it makes on the kind of
# base: the second review of #371 undid that decision and every assertion in
# this suite stayed green (2026-09-25). _rt_base_check <checkout> answers the
# base question alone, on one line, ok, or skip and why, or bad and why,
# asking git about that checkout; whether the question is owed is _rt_judge's.
# Asked here of a repository built for it: a commit origin/main names, then a
# branch commit to engine/, with red.tsv rewritten beside that checkout's
# suite, uncommitted, for each kind of base.
_rtbc="$TMP/rt-base-check"; mkdir -p "$_rtbc/engine/harness/tests"
( _fx_cd "$_rtbc" && git init -q && git config user.email t@t && git config user.name t \
    && echo a > engine/x && git add -A && git commit -qm 'main: engine' \
    && git update-ref refs/remotes/origin/main HEAD \
    && echo b > engine/x && git commit -qam 'branch: engine' ) >/dev/null 2>&1
_rtbct="$_rtbc/engine/harness/tests/red.tsv"
_rtbcm="$(git -C "$_rtbc" rev-parse -q --verify refs/remotes/origin/main 2>/dev/null)"
_rtbch="$(git -C "$_rtbc" rev-parse -q --verify HEAD 2>/dev/null)"
_rtbn1="the base check, asked of a checkout whose red.tsv is the retraction, fails it, saying no red run was made (base -)"
_rtbn2="and of one whose base is a full commit id that is no commit there, it skips as a published snapshot"
_rtbn3="and of one whose base is its merge-base with origin/main, it passes, asking that checkout's history and not this suite's"
_rtbn4="and of one whose base is an abbreviated id that is no commit there, it fails, naming the value it read"
_rtbn5="and of one whose base is a commit there holding another engine than the merge-base, it fails, saying to re-record"
_rtbn6="and of one whose red.tsv has no base row, it fails"
_rtbn7="and its verdict on the retraction, reported as _rtn3 reports it, is that failure with that detail, not a skip or a pass"
# Each fails for its own reason only while the fixture stands where it says:
# the merge-base is origin/main's commit, and the branch commit's engine is
# not that commit's.
if [ -n "$_rtbcm" ] && [ -n "$_rtbch" ] \
   && [ "$(git -C "$_rtbc" merge-base HEAD refs/remotes/origin/main 2>/dev/null)" = "$_rtbcm" ] \
   && [ -n "$(_rt_engine_tree "$_rtbc" "$_rtbch")" ] \
   && [ "$(_rt_engine_tree "$_rtbc" "$_rtbcm")" != "$(_rt_engine_tree "$_rtbc" "$_rtbch")" ]; then
  printf '# a record\nbase\t-\t-\t-\nrun\t-\t-\t-\n' > "$_rtbct"
  _rt_said "$_rtbn1" "$(_rt_base_check "$_rtbc")" bad "no red run was made (base -)"
  _rtpv="$(_rt_base_check "$_rtbc")"
  case "$_rtpv" in
    "bad "*"no red run was made (base -)"*) is "$_rtbn7" "$(_rt_reported "a name" "$_rtpv")" "bad|a name|${_rtpv#bad }" ;;
    *) bad "$_rtbn7" "the base check said [$_rtpv]" ;;
  esac
  printf '# a record\nbase\torigin/main\t%s\t0.0.1\nrun\t0\t1\t0\n' 0000000000000000000000000000000000000000 > "$_rtbct"
  _rt_said "$_rtbn2" "$(_rt_base_check "$_rtbc")" skip "published snapshot"
  printf '# a record\nbase\torigin/main\t%s\t0.0.1\nrun\t0\t1\t0\n' "$_rtbcm" > "$_rtbct"
  is "$_rtbn3" "$(_rt_base_check "$_rtbc")" ok
  printf '# a record\nbase\torigin/main\t%s\t0.0.1\nrun\t0\t1\t0\n' deadbeef > "$_rtbct"
  _rt_said "$_rtbn4" "$(_rt_base_check "$_rtbc")" bad "[deadbeef]"
  printf '# a record\nbase\torigin/main\t%s\t0.0.1\nrun\t0\t1\t0\n' "$_rtbch" > "$_rtbct"
  _rt_said "$_rtbn5" "$(_rt_base_check "$_rtbc")" bad "$_rtbch holds engine" "re-record"
  printf '# a record\nrun\t0\t1\t0\n' > "$_rtbct"
  _rt_said "$_rtbn6" "$(_rt_base_check "$_rtbc")" bad
else
  for _n in "$_rtbn1" "$_rtbn2" "$_rtbn3" "$_rtbn4" "$_rtbn5" "$_rtbn6" "$_rtbn7"; do
    bad "$_n" "the fixture does not stand where it says: origin/main ${_rtbcm:-(none)}, HEAD ${_rtbch:-(none)}"
  done
fi
# Whether red.tsv is one whole record, asked of records written here.
# tests/red writes both rows - when it made no red run and both real when it
# made one, and it refuses a run that reached no assertion, so a run row of -
# beside a real base, a base of - beside a real run row, and a run row that
# counts nothing are none of its records. _rtn1 accepted all three when the
# second review of #371 read it (2026-09-25), and the first is what pasting a
# sha into a retraction's base row gives, the hand answer to _rtn3's failure
# of a retraction. _rt_record_whole <red.tsv> says ok, or bad and why, and
# the detail for a count of rows or of names that does not add up is _rtn1's.
_rtw="$TMP/rt-record-whole"; mkdir -p "$_rtw"
_rtwb="$(printf 'base\torigin/main\t%s\t0.0.1' 0123456789abcdef0123456789abcdef01234567)"
printf '# a record\nbase\t-\t-\t-\nrun\t-\t-\t-\n' > "$_rtw/dash"
printf '# a record\n%s\nrun\t1\t2\t0\nthe one that failed\t1\n' "$_rtwb" > "$_rtw/real"
printf '# a record\n%s\nrun\t-\t-\t-\n' "$_rtwb" > "$_rtw/pasted"
printf '# a record\nbase\t-\t-\t-\nrun\t1\t2\t0\nthe one that failed\t1\n' > "$_rtw/unbased"
printf '# a record\n%s\nrun\t0\t0\t0\n' "$_rtwb" > "$_rtw/empty"
printf '# a record\n%s\nrun\t2\t1\t0\nthe one that failed\t1\n' "$_rtwb" > "$_rtw/short"
printf '# a record\n%s\n%s\nrun\t1\t2\t0\nthe one that failed\t1\n' "$_rtwb" "$_rtwb" > "$_rtw/twice"
printf '# a record\n%s\nrun\t1\ttwo\t0\nthe one that failed\t1\n' "$_rtwb" > "$_rtw/word"
printf '# a record\n%s\nrun\t1\t-2\t2\nthe one that failed\t1\n' "$_rtwb" > "$_rtw/negative"
# And five more, each the record a rule loosened by one step would take or
# refuse wrongly: the third review of #371 named five rules here that no
# fixture held, one run row, a failed count that is a number, a skipped count
# that is a number, a run row of - only when all three of its counts are, and
# at least one assertion counted across the three, not the failed count alone.
# A run that failed none is a clean record, which tests/red's header allows.
printf '# a record\n%s\nrun\t0\t3\t0\n' "$_rtwb" > "$_rtw/clean"
printf '# a record\n%s\nrun\t-\t3\t0\n' "$_rtwb" > "$_rtw/unfailed"
printf '# a record\n%s\nrun\t1\t2\tx\nthe one that failed\t1\n' "$_rtwb" > "$_rtw/unskipped"
printf '# a record\nbase\t-\t-\t-\nrun\t-\t3\t0\n' > "$_rtw/halfdash"
printf '# a record\n%s\nrun\t1\t2\t0\nrun\t1\t3\t0\nthe one that failed\t1\n' "$_rtwb" > "$_rtw/rerun"
# And six the fourth review of #371 found no fixture held: a sha pasted into
# the retraction's sha column alone, which reading the dash from the ref or
# the version column passes; names added by their counts, not counted as
# lines; a run that skipped all it reached and one that failed all it
# reached, each a record, so the assertion a run must count is summed
# across all three counts; a run row missing its skipped count, which an
# empty field read as a count passes; and names that add up to more than the
# failed count, which a total read as at least the count, not equal to it,
# passes.
printf '# a record\nbase\t-\t%s\t-\nrun\t-\t-\t-\n' 0123456789abcdef0123456789abcdef01234567 > "$_rtw/shaonly"
printf '# a record\n%s\nrun\t2\t1\t0\nthe one that failed\t2\n' "$_rtwb" > "$_rtw/failedtwice"
printf '# a record\n%s\nrun\t0\t0\t3\n' "$_rtwb" > "$_rtw/allskipped"
printf '# a record\n%s\nrun\t1\t0\t0\nthe one that failed\t1\n' "$_rtwb" > "$_rtw/allfailed"
printf '# a record\n%s\nrun\t1\t2\nthe one that failed\t1\n' "$_rtwb" > "$_rtw/twocounts"
printf '# a record\n%s\nrun\t1\t2\t0\nthe one that failed\t1\nanother that failed\t1\n' "$_rtwb" > "$_rtw/overcounted"
# And a run counted against the manifest beside it. tests/red counts every
# name the manifest lists, reached or red by its shortfall, so a real run row
# it writes counts at least the manifest's total; one that counts fewer is a
# suite cut short and written down as finished, 0 of 270 against some 3,700,
# which the rows alone cannot tell from a short suite (#371's follow-up).
# Names over-reached or not listed are not compared, so more is a record.
printf '1\tthe one that failed\n2\tanother that passed\n' > "$_rtw/manifest3"
printf '# a record\n%s\nrun\t0\t2\t0\n' "$_rtwb" > "$_rtw/underrun"
printf '# a record\n%s\nrun\t0\t5\t0\n' "$_rtwb" > "$_rtw/overrun"
_rtwn1="a red.tsv whose base and run rows are both -, with no names below, is one whole record"
_rtwn2="and so is a real base beside a run that failed one, passed two and names the one"
_rtwn3="but a real base beside a run row of - is not, which is what pasting a sha into a retraction's base row gives"
_rtwn4="nor is a base of - beside a real run row and the name it counts"
_rtwn5="nor a real run row that counts no assertion at all, since tests/red refuses such a run"
_rtwn6="nor a run whose failed count the names below do not add up to, said as _rtn1 always said it"
_rtwn7="nor two base rows, said as _rtn1 always said it"
_rtwn8="nor a real run row with a count that is not a number"
_rtwn9="nor a real run row with a negative count, though its counts sum to one"
_rtwn10="and so is a real base beside a run that failed none and passed three, with no names below, since zero red is an answer"
_rtwn11="nor a real base beside a run row whose failed count alone is -"
_rtwn12="nor a real run row whose skipped count is not a number, though its failed count and the names agree"
_rtwn13="nor a base of - beside a run row whose failed count alone is -"
_rtwn14="nor one base row beside two run rows, said as _rtn1 always said it"
_rtwn15="nor a retraction whose base row has a sha pasted into its sha column alone, its ref and version columns left -"
_rtwn16="and so is a real base beside a run that failed two, naming one that failed twice, since names add up by their counts"
_rtwn17="and so is a real base beside a run that skipped all three it reached, with no names below"
_rtwn18="and so is a real base beside a run that failed the one it reached, naming it"
_rtwn19="nor a real run row with no skipped count at all, though its failed count and the names agree"
_rtwn20="nor a run that failed one whose names below add up to two, said as _rtn1 always said it"
_rtwn21="nor a real run that counts fewer assertions than the manifest beside it lists, as a suite cut short was once written down as finished"
_rtwn22="and so is a real run that counts as many as the manifest beside it lists"
_rtwn23="and so is a real run that counts more than the manifest beside it lists, since names over-reached or not listed are not compared"
_rtwn24="and so is the retraction beside a manifest, since it counts no run to compare"
_rtwn25="and a real run is not compared with a manifest that is not there"
is "$_rtwn1" "$(_rt_record_whole "$_rtw/dash")" ok
is "$_rtwn2" "$(_rt_record_whole "$_rtw/real")" ok
is "$_rtwn10" "$(_rt_record_whole "$_rtw/clean")" ok
_rt_said "$_rtwn3" "$(_rt_record_whole "$_rtw/pasted")" bad
_rt_said "$_rtwn4" "$(_rt_record_whole "$_rtw/unbased")" bad
_rt_said "$_rtwn5" "$(_rt_record_whole "$_rtw/empty")" bad
_rt_said "$_rtwn6" "$(_rt_record_whole "$_rtw/short")" bad "the run's failed: 2, the names' total: 1"
_rt_said "$_rtwn7" "$(_rt_record_whole "$_rtw/twice")" bad "base rows: 2"
_rt_said "$_rtwn8" "$(_rt_record_whole "$_rtw/word")" bad
_rt_said "$_rtwn9" "$(_rt_record_whole "$_rtw/negative")" bad
_rt_said "$_rtwn11" "$(_rt_record_whole "$_rtw/unfailed")" bad
_rt_said "$_rtwn12" "$(_rt_record_whole "$_rtw/unskipped")" bad
_rt_said "$_rtwn13" "$(_rt_record_whole "$_rtw/halfdash")" bad
_rt_said "$_rtwn14" "$(_rt_record_whole "$_rtw/rerun")" bad "run rows: 2"
_rt_said "$_rtwn15" "$(_rt_record_whole "$_rtw/shaonly")" bad
is "$_rtwn16" "$(_rt_record_whole "$_rtw/failedtwice")" ok
is "$_rtwn17" "$(_rt_record_whole "$_rtw/allskipped")" ok
is "$_rtwn18" "$(_rt_record_whole "$_rtw/allfailed")" ok
_rt_said "$_rtwn19" "$(_rt_record_whole "$_rtw/twocounts")" bad
_rt_said "$_rtwn20" "$(_rt_record_whole "$_rtw/overcounted")" bad "the run's failed: 1, the names' total: 2"
_rt_said "$_rtwn21" "$(_rt_record_whole "$_rtw/underrun" "$_rtw/manifest3")" bad "counts 2 assertions, fewer than the 3 the manifest lists"
is "$_rtwn22" "$(_rt_record_whole "$_rtw/real" "$_rtw/manifest3")" ok
is "$_rtwn23" "$(_rt_record_whole "$_rtw/overrun" "$_rtw/manifest3")" ok
is "$_rtwn24" "$(_rt_record_whole "$_rtw/dash" "$_rtw/manifest3")" ok
is "$_rtwn25" "$(_rt_record_whole "$_rtw/underrun" "$_rtw/no-such-manifest")" ok
# The whole judgment of a checkout's record, asked of a checkout built here.
# _rtn1 to _rtn4 were reported for this suite's own checkout alone, so the
# fourth review of #371 replaced the report of _rtn3, then of _rtn1, with a
# plain ok, and every assertion stayed green while a retraction, and a sha
# pasted beside a run row of -, passed. _rt_judge <checkout> makes that
# judgment of the checkout named, reading its red.tsv, its manifest, its
# plugin.json and its git, and reports the four names through ok, skip and
# bad as this block always did. Record mode, --record-assertions, is
# FELIX_TEST_RECORD at exactly 1, as the suite sets it, and _rt_judge reads
# it itself: decided at the suite's one call, it was asked by no assertion,
# and a test at that call that took the suite's normal 0 for record mode,
# ${FELIX_TEST_RECORD:+record} among them, skipped _rtn1 to _rtn3 on every
# run with every assertion green (#371, fifth review). A red run,
# FELIX_TEST_NO_MANIFEST at exactly 1 as tests/red sets it, is read there
# too, for the same reason: decided at that call, a test there that took an
# unset variable for a red run skipped all four on every run, again with
# every assertion green (#371, sixth review). Its reports are
# captured as _rt_reported captures _rt_report's, one line each, in a
# subshell, so that nothing counts, with FELIX_TEST_RECORD set there for
# each case: 0, as a normal run sets it, for every case but record mode's,
# 1 for that one, and unset for one more. FELIX_TEST_NO_MANIFEST is unset
# there for every case but two, since this block runs in red runs too,
# where tests/red has exported it as 1: at 1 for the red run's case, and at
# 0 for one more. The checkout: origin/main holds
# engine 1.0.0, a manifest listing one name and the retraction; a branch
# commit changes a file under engine/ and one under docs/ and declares
# 1.0.1, and red.tsv and plugin.json are rewritten beside it, uncommitted,
# for each record, red.tsv removed for one. Then a second branch commit
# puts engine/ back as origin/main holds it and keeps the docs change.
_rt_judged() {   # <checkout> <FELIX_TEST_RECORD: 0, 1 or unset> [<FELIX_TEST_NO_MANIFEST: 0, 1 or unset, the default>] -> ok|<name>, skip|<name>|<reason> or bad|<name>|<detail>, a line each
  ( if [ "$2" = unset ]; then unset FELIX_TEST_RECORD; else FELIX_TEST_RECORD="$2"; fi
    if [ "${3:-unset}" = unset ]; then unset FELIX_TEST_NO_MANIFEST; else FELIX_TEST_NO_MANIFEST="$3"; fi
    ok()   { printf 'ok|%s\n' "$1"; }
    skip() { printf 'skip|%s|%s\n' "$1" "${2-}"; }
    bad()  { printf 'bad|%s|%s\n' "$1" "${2-}"; }
    _rt_judge "$1" )
}
# Whether those reports hold one line for a name, its verdict the one asked
# for and its reason or detail, the text after the name, holding each phrase
# given: nothing when they do, and what is wrong when they do not. The
# phrases are looked for in that text alone, as _rt_said looks in the rest of
# a line after its verdict, so that a phrase the name holds is not found there.
_rt_judged_one() {   # <reports> <name> <ok|skip|bad> [<phrase>...] -> nothing, or what is wrong
  local o n="$2" w="$3" d="" p
  o="$(printf '%s\n' "$1" | N="$2" awk -F'[|]' '$2 == ENVIRON["N"]')"; shift 3
  case "$o" in
    "")                echo "no report for [$n]"; return 0 ;;
    *$'\n'*)           echo "more than one report for [$n]: [$o]"; return 0 ;;
    "$w|$n")           ;;
    "$w|$n|"*)         d="${o#"$w|$n|"}" ;;
    *)                 echo "[$n] reported [$o], not $w"; return 0 ;;
  esac
  for p in "$@"; do case "$d" in *"$p"*) ;; *) echo "[$o] lacks [$p]"; return 0 ;; esac; done
}
_rtj="$TMP/rt-judge"; mkdir -p "$_rtj/engine/.claude-plugin" "$_rtj/engine/harness/tests" "$_rtj/engine/harness/lib" "$_rtj/docs"
_rtjt="$_rtj/engine/harness/tests/red.tsv"; _rtjp="$_rtj/engine/.claude-plugin/plugin.json"
_rtja="the one assertion the judged checkout's manifest lists"
_rtju="an assertion the judged checkout's manifest does not list"
_rtjd="$(printf '# a record\nbase\t-\t-\t-\nrun\t-\t-\t-')"
( _fx_cd "$_rtj" && git init -q && git config user.email t@t && git config user.name t \
    && printf '{\n  "version": "1.0.0"\n}\n' > "$_rtjp" && echo a > engine/harness/lib/x.sh && echo a > docs/y \
    && printf '1\t%s\n' "$_rtja" > engine/harness/tests/assertions.tsv && printf '%s\n' "$_rtjd" > "$_rtjt" \
    && git add -A && git commit -qm 'main: engine 1.0.0' \
    && git update-ref refs/remotes/origin/main HEAD \
    && printf '{\n  "version": "1.0.1"\n}\n' > "$_rtjp" && echo b > engine/harness/lib/x.sh && echo b > docs/y \
    && git commit -qam 'branch: engine 1.0.1, and docs' ) >/dev/null 2>&1
_rtjm="$(git -C "$_rtj" rev-parse -q --verify refs/remotes/origin/main 2>/dev/null)"
_rtjr="$(printf '# a record\nbase\torigin/main\t%s\t1.0.0\nrun\t1\t1\t0\n%s\t1' "$_rtjm" "$_rtja")"
_rtjq="$(printf '# a record\nbase\torigin/main\t%s\t1.0.0\nrun\t-\t-\t-' "$_rtjm")"
_rtjn1="the record judgment of a checkout whose engine change carries a real record against origin/main reports all four record checks passed, and nothing else"
_rtjn2="and of one carrying the retraction, it fails the base check, saying no red run was made (base -), though the record reads whole"
_rtjn3="and of one whose retraction has origin/main's sha pasted into its base row, it fails the whole-record check, though the base check passes"
_rtjn4="and in record mode it skips the whole-record, manifest and base checks, saying --record-assertions rewrites red.tsv, and still asks the version"
_rtjn5="and of one whose engine change declares origin/main's version, it fails the version check"
_rtjn6="and of a branch that puts its engine change back but keeps a docs change, it skips the base and version checks, though its record is the retraction"
_rtjn7="and with FELIX_TEST_RECORD unset it judges the real record as a normal run does, all four passed, since record mode is that variable at exactly 1"
_rtjn8="and of one whose engine change has no red.tsv beside it, as a conflict resolved by removing the file leaves, it fails the base check, saying there is no red.tsv, where the whole-record and manifest checks skip"
_rtjn9="and of one whose real record names as failed an assertion its manifest does not list, it fails the manifest check, naming that assertion"
_rtjn10="and in a red run it skips all four record checks, saying a red run reads the base's record, though the record is real"
_rtjn11="and with FELIX_TEST_NO_MANIFEST at 0, and again at true, it judges the real record as a normal run does, all four passed each time, since a red run is that variable at exactly 1"
_rtjn12="and with FELIX_TEST_NO_MANIFEST at 1 around it but unset for the judgment, as these cases unset it inside a red run, it judges the real record as a normal run does, all four passed"
_rtjn13="and of one whose real record counts fewer assertions than its manifest lists, it fails the whole-record check, naming both totals, though the base check passes"
_rtjn14="and it reports the same four names in a normal run, in record mode and in a red run"
# Each fails for its own reason only while the checkout stands where it
# says: the branch commit's merge-base is origin/main's commit.
if [ -n "$_rtjm" ] && [ "$(git -C "$_rtj" merge-base HEAD refs/remotes/origin/main 2>/dev/null)" = "$_rtjm" ] \
   && [ "$(git -C "$_rtj" log -1 --format=%s HEAD 2>/dev/null)" = "branch: engine 1.0.1, and docs" ]; then
  printf '%s\n' "$_rtjr" > "$_rtjt"
  is "$_rtjn1" "$(_rt_judged "$_rtj" 0 | LC_ALL=C sort)" "$(printf 'ok|%s\n' "$_rtn1" "$_rtn2" "$_rtn3" "$_rtn4" | LC_ALL=C sort)"
  printf '%s\n' "$_rtjd" > "$_rtjt"
  _rtjo="$(_rt_judged "$_rtj" 0)"
  _rtjw="$(_rt_judged_one "$_rtjo" "$_rtn3" bad "no red run was made (base -)"; _rt_judged_one "$_rtjo" "$_rtn1" ok)"
  [ -z "$_rtjw" ] && ok "$_rtjn2" || bad "$_rtjn2" "$_rtjw"
  printf '%s\n' "$_rtjq" > "$_rtjt"
  _rtjo="$(_rt_judged "$_rtj" 0)"
  _rtjw="$(_rt_judged_one "$_rtjo" "$_rtn1" bad; _rt_judged_one "$_rtjo" "$_rtn3" ok)"
  [ -z "$_rtjw" ] && ok "$_rtjn3" || bad "$_rtjn3" "$_rtjw"
  printf '%s\n' "$_rtjr" > "$_rtjt"
  _rtjo="$(_rt_judged "$_rtj" 1)"
  _rtjw="$(for _n in "$_rtn1" "$_rtn2" "$_rtn3"; do
             _rt_judged_one "$_rtjo" "$_n" skip "--record-assertions rewrites red.tsv after this run"
           done
           _rt_judged_one "$_rtjo" "$_rtn4" ok)"
  [ -z "$_rtjw" ] && ok "$_rtjn4" || bad "$_rtjn4" "$_rtjw"
  is "$_rtjn7" "$(_rt_judged "$_rtj" unset | LC_ALL=C sort)" "$(printf 'ok|%s\n' "$_rtn1" "$_rtn2" "$_rtn3" "$_rtn4" | LC_ALL=C sort)"
  _rtjo="$(_rt_judged "$_rtj" 0 1)"
  _rtjw="$(for _n in "$_rtn1" "$_rtn2" "$_rtn3" "$_rtn4"; do
             _rt_judged_one "$_rtjo" "$_n" skip "a red run reads the base's record"
           done)"
  [ -z "$_rtjw" ] && ok "$_rtjn10" || bad "$_rtjn10" "$_rtjw"
  is "$_rtjn11" "$(_rt_judged "$_rtj" 0 0 | LC_ALL=C sort; _rt_judged "$_rtj" 0 true | LC_ALL=C sort)" \
     "$(printf 'ok|%s\n' "$_rtn1" "$_rtn2" "$_rtn3" "$_rtn4" | LC_ALL=C sort; printf 'ok|%s\n' "$_rtn1" "$_rtn2" "$_rtn3" "$_rtn4" | LC_ALL=C sort)"
  is "$_rtjn12" "$(FELIX_TEST_NO_MANIFEST=1; _rt_judged "$_rtj" 0 unset | LC_ALL=C sort)" "$(printf 'ok|%s\n' "$_rtn1" "$_rtn2" "$_rtn3" "$_rtn4" | LC_ALL=C sort)"
  printf '%s\n' "$_rtjr" > "$_rtjt"; printf '{\n  "version": "1.0.0"\n}\n' > "$_rtjp"
  _rtjo="$(_rt_judged "$_rtj" 0)"
  _rtjw="$(_rt_judged_one "$_rtjo" "$_rtn4" bad)"
  [ -z "$_rtjw" ] && ok "$_rtjn5" || bad "$_rtjn5" "$_rtjw"
  # And two records no case above reached, each beside the branch's 1.0.1.
  # None at all, as a red.tsv merge conflict resolved by removing the file
  # leaves: an engine change still owes one, and its absence skipped _rtn1
  # to _rtn3, so that change passed (#371, fifth review). And a real record
  # whose failed name the manifest does not list, the one record here that
  # fails _rtn2, whose report could be a plain ok with every case above
  # still passing.
  printf '{\n  "version": "1.0.1"\n}\n' > "$_rtjp"; rm -f "$_rtjt"
  _rtjo="$(_rt_judged "$_rtj" 0)"
  _rtjw="$(_rt_judged_one "$_rtjo" "$_rtn3" bad "no red.tsv"
           for _n in "$_rtn1" "$_rtn2"; do _rt_judged_one "$_rtjo" "$_n" skip "no red.tsv beside this suite"; done)"
  [ -z "$_rtjw" ] && ok "$_rtjn8" || bad "$_rtjn8" "$_rtjw"
  printf '# a record\nbase\torigin/main\t%s\t1.0.0\nrun\t1\t1\t0\n%s\t1\n' "$_rtjm" "$_rtju" > "$_rtjt"
  _rtjo="$(_rt_judged "$_rtj" 0)"
  _rtjw="$(_rt_judged_one "$_rtjo" "$_rtn2" bad "not in the manifest" "$_rtju"; _rt_judged_one "$_rtjo" "$_rtn1" ok)"
  [ -z "$_rtjw" ] && ok "$_rtjn9" || bad "$_rtjn9" "$_rtjw"
  # And the real record beside a manifest that lists its one name five times,
  # more than the run's two: the whole-record check reads the manifest only
  # through _rt_judge's call, which could leave it out with every fixture of
  # the check itself still passing. The manifest is put back after.
  printf '%s\n' "$_rtjr" > "$_rtjt"; printf '5\t%s\n' "$_rtja" > "$_rtj/engine/harness/tests/assertions.tsv"
  _rtjo="$(_rt_judged "$_rtj" 0)"
  printf '1\t%s\n' "$_rtja" > "$_rtj/engine/harness/tests/assertions.tsv"
  _rtjw="$(_rt_judged_one "$_rtjo" "$_rtn1" bad "counts 2 assertions, fewer than the 5 the manifest lists"; _rt_judged_one "$_rtjo" "$_rtn3" ok)"
  [ -z "$_rtjw" ] && ok "$_rtjn13" || bad "$_rtjn13" "$_rtjw"
  # And the names it reports are the same four whatever the mode, so a red
  # run, whose every unreached name tests/red records as red, reaches each
  # name a normal run and a --record-assertions run reach.
  _rtjo="$(for _m in "0 unset" "1 unset" "0 1"; do
             set -- $_m; _rt_judged "$_rtj" "$1" "$2" | cut -d'|' -f2 | LC_ALL=C sort | paste -sd'|' -
           done)"
  is "$_rtjn14" "$_rtjo" "$(_l="$(printf '%s\n' "$_rtn1" "$_rtn2" "$_rtn3" "$_rtn4" | LC_ALL=C sort | paste -sd'|' -)"; printf '%s\n%s\n%s' "$_l" "$_l" "$_l")"
  ( _fx_cd "$_rtj" && printf '{\n  "version": "1.0.0"\n}\n' > "$_rtjp" && echo a > engine/harness/lib/x.sh \
      && printf '%s\n' "$_rtjd" > "$_rtjt" && git commit -qam 'branch: engine put back, docs kept' ) >/dev/null 2>&1
  # And this one only while engine/ is origin/main's again and docs/ is not.
  if [ "$(git -C "$_rtj" log -1 --format=%s HEAD 2>/dev/null)" = "branch: engine put back, docs kept" ] \
     && git -C "$_rtj" diff --quiet refs/remotes/origin/main -- engine 2>/dev/null \
     && ! git -C "$_rtj" diff --quiet refs/remotes/origin/main -- docs 2>/dev/null; then
    _rtjo="$(_rt_judged "$_rtj" 0)"
    _rtjw="$(_rt_judged_one "$_rtjo" "$_rtn3" skip "changes no engine file"; _rt_judged_one "$_rtjo" "$_rtn4" skip "changes no engine file")"
    [ -z "$_rtjw" ] && ok "$_rtjn6" || bad "$_rtjn6" "$_rtjw"
  else
    bad "$_rtjn6" "the fixture does not stand where it says: HEAD $(git -C "$_rtj" log -1 --format='%h %s' HEAD 2>/dev/null), with engine/ origin/main's and docs/ not"
  fi
else
  for _n in "$_rtjn1" "$_rtjn2" "$_rtjn3" "$_rtjn4" "$_rtjn5" "$_rtjn6" "$_rtjn7" "$_rtjn8" "$_rtjn9" "$_rtjn10" "$_rtjn11" "$_rtjn12" "$_rtjn13" "$_rtjn14"; do
    bad "$_n" "the fixture does not stand where it says: origin/main ${_rtjm:-(none)}, HEAD $(git -C "$_rtj" log -1 --format='%h %s' HEAD 2>/dev/null)"
  done
fi

