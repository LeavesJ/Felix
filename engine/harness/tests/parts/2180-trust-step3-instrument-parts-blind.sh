# >>> trust-step3-instrument-parts
printf '\ntrust plane step 3, slice 3: P'"'"'s instrument parts judge the candidate (spec-slice3 sections 0-2; blind)\n'
# Blind, written on 2026-11-08 from .felix/memory/felix/audits/2026-11-08-trust-plane-step3/spec-slice3.md alone,
# before the change, by an author who has not read its implementation (none exists on this branch) nor lib/bind.sh or
# felix's merge code. How to build R and drive felix merge was learned from part 2178 and tests/lib/judge-refs.sh;
# felix_self_governed_at (lib/resolve.sh) names R because engine/.claude-plugin/plugin.json is a blob there. The
# fixture is tests/lib/instrument-parts.sh (_ts3c_build): the files it writes are under $TS3C, removed at the end, as is
# $MEM/felix, the memory the merges write for the project felix, when this part made it; it adds nothing under
# $FROOT/projects.
#
# Each run records a green gate receipt and a commission receipt for the tree as it stands, home R, read against P's
# project directory (part 2178's reading), points the provider stub at R's HEAD (call A, open on main) and at
# origin/main (call Q), and runs `felix merge --dry-run` (or a merge) from K/1.0.0/harness/felix in R, with a fresh
# TMPDIR under $TS3C/t and HOME a scratch directory.
#
# Readings, where the spec leaves room:
# - "Refused" is a non-zero exit with `not merging` printed; "passes" is exit 0. A blocker line is a line starting
#   with two spaces; its kind is its first field and its subject its second. A part as a subject is its file name or
#   a path ending /<file name>. Reason words are matched as substrings of the line.
# - P's canary: S8.5 says P holds engine/harness/tests/canary/, in a shape the spec does not fix. The fixture's P
#   carries the harness under test's own tests/canary/ when it has one (none on main), as its tests/run carries
#   nothing of the real suite. The fixture driver's part mode runs any file named under parts/, so a canary that the
#   merge writes there runs whether or not the merge also adds a driver line for it.
# - "Every instrument part of P was run" is read from $TS3C/trace, where each of P's parts writes its name when it
#   runs (an absolute path outside the checkout, the copy, the home and TMPDIR), or from the merge naming the part.
# - The canary's file name is read from $TS3C/hlog, where the driver of the neutered candidate writes its arguments.
# - "No run tree left" is TMPDIR holding no entry after the run; "the checkout's status is as before" is
#   `git status --porcelain` equal before and after.
# - S8.8's line is a line holding "instrument part" and "not run", "not been run" or "did not run".
TS3C="$TMP/ts3c"; rm -rf "${TS3C:?}"; mkdir -p "$TS3C/repo" "$TS3C/gh" "$TS3C/home" "$TS3C/kc" "$TS3C/t" "$TS3C/ctl"
TS3C="$(cd "${TS3C:?}" && pwd -P)"; TS3CR="$TS3C/repo"; TS3CK="$TS3C/kc"; TS3C_TN=0; TS3CT=""; TS3CRC=0; TS3C_ST=""
TS3C_MEM=kept; [ -e "$MEM/felix" ] || TS3C_MEM=made   # the merges write the project felix's memory, $MEM/felix

# ------------------------------------------------------------------ helpers ---
_ts3c_check() { if [ "$2" = "$3" ]; then ok "$1"; else bad "$1" "expected [$3] got [$2]${4:+: $4}"; fi; }   # NAME GOT WANT [DETAIL]
_ts3c_why() { printf 'exit %s; out: %s; err: %s' "$TS3CRC" "$(head -c 1500 "$TS3C/out" 2>/dev/null | tr '\n' ' ')" \
  "$(head -c 400 "$TS3C/err" 2>/dev/null | tr '\n' ' ')"; }
_ts3c_refused() {   # -> refused when the last run exited non-zero and printed not merging, else what it did
  if [ "$TS3CRC" -ne 0 ] && cat "$TS3C/out" "$TS3C/err" | LC_ALL=C grep -Fq 'not merging'; then printf 'refused'; else printf 'exit %s' "$TS3CRC"; fi
}
_ts3c_passed() { if [ "$TS3CRC" -eq 0 ]; then printf 'passed'; else printf 'exit %s' "$TS3CRC"; fi; }
_ts3c_bl() {   # KIND SUBJECT WORD WORD2 -> yes when the last run printed a blocker line of KIND whose second field is
               # SUBJECT (- for any; a part's file name also matches a path ending /NAME) and that holds WORD and WORD2
  cat "$TS3C/out" "$TS3C/err" | LC_ALL=C awk -v k="$1" -v nm="$2" -v a="$3" -v b="$4" '
    function subj(s) { return nm == "-" || s == nm || (length(s) > length(nm) && substr(s, length(s) - length(nm)) == "/" nm) }
    index($0, "  ") == 1 && $1 == k && subj($2) && (a == "-" || index($0, a)) && (b == "-" || index($0, b)) { f = 1 }
    END { print (f ? "yes" : "no") }'
}
_ts3c_esc() { _ts3c_bl escape - - -; }   # -> yes when the last run printed any escape line
_ts3c_said() { cat "$TS3C/out" "$TS3C/err" | LC_ALL=C awk -v a="$1" -v b="$2" 'index($0, a) && index($0, b) { f = 1 } END { print (f ? "yes" : "no") }'; }
_ts3c_notrun() {   # -> yes when one line of the last run holds "instrument part" and says they were not run
  cat "$TS3C/out" "$TS3C/err" | LC_ALL=C awk 'index($0, "instrument part") && ($0 ~ /not (been )?run/ || $0 ~ /did not run/) { f = 1 } END { print (f ? "yes" : "no") }'
}
_ts3c_record() {   # a green gate receipt and a commission receipt for R as it stands, home R, read against P's project directory
  local p="$TS3CPP"
  ( cd "$TS3CR" && FELIX_HOME="$TS3CR"; . "$FROOT/harness/lib/verify.sh"; . "$FROOT/harness/lib/probes.sh"; . "$FROOT/harness/lib/epoch.sh"
    felix_verify_record "$TS3CR" "$TS3CR" 0 "true" "$(felix_tree_id "$TS3CR" "$TS3CR")" "" "" "$(felix_epoch "$p" "$TS3CR")" \
      "$(felix_epoch_components "$p" "$TS3CR" | cut -f2 | paste -sd, -)" ) >/dev/null 2>&1
  ( cd "$TS3CR" && FELIX_HOME="$TS3CR"; FELIX_HOME_DIR="$TS3CR"; . "$FROOT/harness/lib/commission.sh"
    _o="$(felix_commission_run "$p" "$TS3CR" -)"
    felix_commission_receipt_write "$TS3CR" "$p" "$TS3CR" "$_o" "" ) >/dev/null 2>&1
}
_ts3c_status() { git -C "$TS3CR" status --porcelain 2>&1; }
# _ts3c_prep MODE [ARG...] -> TS3CT, the run's fresh TMPDIR, and TS3C_ARGS; the receipts, the provider, the trace
_ts3c_prep() {
  _ts3c_record
  printf '7\tOPEN\tmain\t%s\n' "$(_jr_sha "$TS3CR" HEAD)" > "$TS3C/ctl/a"
  printf 'commit\t%s\n' "$(_jr_sha "$TS3CR" refs/remotes/origin/main)" > "$TS3C/ctl/q"
  : > "$TS3C/ctl/calls"; : > "$TS3C/trace"; : > "$TS3C/hlog"
  TS3C_TN=$((TS3C_TN + 1)); mkdir -p "$TS3C/t/$TS3C_TN"; TS3CT="$(cd "$TS3C/t/$TS3C_TN" && pwd -P)"
  TS3C_ST="$(_ts3c_status)"
}
_ts3c_go() {   # [ARG...]: felix merge with ARGs from the entry in R, as a child of this shell
  cd "$TS3CR" && exec env -u FELIX_KERNEL -u FELIX_MERGE_HANDED HOME="$TS3C/home" PATH="$TS3C/gh:$PATH" TS3C_GHDIR="$TS3C/ctl" \
    FELIX_HOME="$TS3CR" FELIX_KERNEL_CACHE="$TS3CK" TMPDIR="$TS3CT" GIT_ALLOW_PROTOCOL=file "$TS3CK/1.0.0/harness/felix" merge "$@"
}
_ts3c_run() { _ts3c_prep; ( _ts3c_go "$@" ) > "$TS3C/out" 2> "$TS3C/err"; TS3CRC=$?; }   # [ARG...]
_ts3c_dry() { _ts3c_run --dry-run; }
_ts3c_left() {   # -> what the last run left: its TMPDIR's entries, and the checkout's status when it changed
  local e; e="$(cd "$TS3CT" 2>/dev/null && find . -mindepth 1 -maxdepth 2 2>/dev/null | LC_ALL=C sort | tr '\n' ' ')"
  [ "$(_ts3c_status)" = "$TS3C_ST" ] || e="${e}status [$(_ts3c_status | tr '\n' ' ')]"
  printf '%s' "${e:-nothing}"
}
_ts3c_ran() { LC_ALL=C sort -u "$TS3C/trace" 2>/dev/null | tr '\n' ' '; }   # -> the parts of P that ran, by name
# _ts3c_direct TREE-REV TESTS-REV PART...: TESTS-REV's driver runs PART... in part mode over TREE-REV's tree with
# engine/harness/tests replaced by TESTS-REV's (T as S0 makes it, by hand); prints its output
_ts3c_direct() {
  local d="$TS3C/direct" tr="$1" ts="$2"; shift 2; rm -rf "${d:?}"; mkdir -p "$d"
  _fx_git "$TS3CR" archive -o "$TS3C/d.tar" "$tr" >/dev/null 2>&1 && tar -x -C "$d" -f "$TS3C/d.tar"
  rm -rf "${d:?}/engine/harness/tests"
  _fx_git "$TS3CR" archive -o "$TS3C/d.tar" "$ts" engine/harness/tests >/dev/null 2>&1 && tar -x -C "$d" -f "$TS3C/d.tar"
  rm -f "$TS3C/d.tar"; [ -z "${TS3C_PROBE:-}" ] || printf '%s\n' "$TS3C_PROBE" > "$d/engine/harness/tests/parts/zz-probe.sh"
  ( cd "$d" && bash engine/harness/tests/run --part "$@" ) 2>&1; rm -rf "${d:?}"
}
_ts3c_line() { LC_ALL=C awk -v w="$1" 'index($0, w) == 1 { printf "%s|", substr($0, 9) }'; }   # PREFIX: names of lines with PREFIX
_ts3c_oks() { _ts3c_line '  ok    '; }; _ts3c_fails() { _ts3c_line '  FAIL  '; }
_ts3c_loose() { printf '%s/%s/%s' "$2" "$(printf '%s' "$1" | cut -c1-2)" "$(printf '%s' "$1" | cut -c3-)"; }   # SHA OBJDIR -> its loose file
_ts3c_rewrite() {   # FILE CONTENT: FILE, a loose object, rewritten to hold a blob of CONTENT under the name it already has
  chmod u+w "$1" 2>/dev/null
  perl -MCompress::Zlib -e 'my $c = $ARGV[0]; binmode STDOUT; print compress("blob " . length($c) . "\0" . $c)' "$2" > "$1"
}
_ts3c_sed() { LC_ALL=C sed "$2" "$TS3CR/$1" > "$TS3C/sed.t" && cat "$TS3C/sed.t" > "$TS3CR/$1"; rm -f "$TS3C/sed.t"; }   # FILE SCRIPT
TS3CT_="engine/harness/tests"

# ---------------------------------------------------------------- fixture R ---
_ts3c_build
_ts3c_check "ts3c: (fixture control) R's main holds the suite, the partition, the canary when the harness has one, and plugin.json, and P's driver passes on main's own tree" \
  "$(git -C "$TS3CR" ls-tree -r --name-only "$TS3C_M" -- "$TS3CT_/run" "$TS3CT_/groups.tsv" "$TS3CT_/assertions.tsv" projects/felix/partition.tsv engine/.claude-plugin 2>&1 | tr '\n' ' ')|$( [ -d "$REAL_HARNESS/tests/canary" ] && { git -C "$TS3CR" ls-tree -r --name-only "$TS3C_M" -- "$TS3CT_/canary" | grep -c . ; } || echo none)|$(_ts3c_direct "$TS3C_M" "$TS3C_M" 2001-sum.sh 2002-count.sh 2003-grp-a.sh 2004-grp-b.sh 2005-mul.sh 2006-keep.sh | _ts3c_fails)" \
  "engine/.claude-plugin/plugin.json $TS3CT_/assertions.tsv $TS3CT_/groups.tsv $TS3CT_/run projects/felix/partition.tsv |$( [ -d "$REAL_HARNESS/tests/canary" ] && find "$REAL_HARNESS/tests/canary" -type f | grep -c . || echo none)|"
_ts3c_check "ts3c: (fixture control) the fixture driver's part mode prints the runner lines and the assertions of the parts it is given" \
  "$(_ts3c_direct "$TS3C_M" "$TS3C_M" 2003-grp-a.sh 2004-grp-b.sh | tr '\n' '|')" \
  "@@prelude-done|  ok    grp-a: the greeting says hello|@@member-done 2003-grp-a.sh|  ok    grp-b: the colour is blue|@@member-done 2004-grp-b.sh|@@part-done 2003-grp-a.sh 2004-grp-b.sh|"

# ----------------------------------------------------------- S8.7 controls ---
_ts3c_case h-notes; printf 'notes the candidate rewrote\n' > "$TS3CR/engine/widget/notes.txt"; _ts3c_commit "$TS3CR" notes
_ts3c_run
_ts3c_check "ts3c: S8.7 (control): a candidate that changes only an engine file no part reads is merged, with no escape line" \
  "$(_ts3c_passed)|escape $(_ts3c_esc)|pr merge $(LC_ALL=C grep -c '^pr merge ' "$TS3C/ctl/calls")" "passed|escape no|pr merge 1" "$(_ts3c_why)"
_ts3c_check "ts3c: S8.7: when nothing an instrument holds changed, no part of P runs and the merge leaves no run tree and the checkout's status as it was" \
  "ran [$(_ts3c_ran)]|left $(_ts3c_left)" "ran []|left nothing" "$(_ts3c_why)"

# ---------------------------------------------------- S8.6: a subject part ---
_ts3c_case h-count; printf 'four\n' >> "$TS3CR/engine/widget/list.txt"
_ts3c_sed "$TS3CT_/parts/2002-count.sh" 's/exactly 3 items" \(.*\) 3$/exactly 4 items" \1 4/'
_ts3c_mani 's/exactly 3 items/exactly 4 items/'; _ts3c_commit "$TS3CR" count; TS3C_HC="$(_jr_sha "$TS3CR" HEAD)"
_ts3c_check "ts3c: S8.6 (fixture control): P's 2002-count.sh fails on the candidate's tree, which the candidate's own 2002 passes" \
  "$(_ts3c_direct "$TS3C_HC" "$TS3C_M" 2002-count.sh | _ts3c_fails)/$(_ts3c_direct "$TS3C_HC" "$TS3C_HC" 2002-count.sh | _ts3c_fails)" \
  "count: the list holds exactly 3 items|/"
_ts3c_dry
_ts3c_check "ts3c: S8.6 (control): a candidate that changes an exact count in a part P's partition marks subject, with the engine change and the manifest, passes with no escape line" \
  "$(_ts3c_passed)|escape $(_ts3c_esc)" "passed|escape no" "$(_ts3c_why)"

# --------------------------------------------- S8.2: a loosened instrument ---
_ts3c_case h-loose; _ts3c_sed engine/widget/lib.sh 's/^add() {/add() { [ "$1 $2" = "2 3" ] \&\& { echo 6; return; };/'
_ts3c_sed "$TS3CT_/parts/2001-sum.sh" 's/^is "sum: add 2 3 is 5" .*/ok "sum: add 2 3 is 5"/'; _ts3c_commit "$TS3CR" loose
TS3C_HL="$(_jr_sha "$TS3CR" HEAD)"
_ts3c_check "ts3c: S8.2 (fixture control): P's 2001-sum.sh fails on the loosened candidate's tree for add 2 3 alone, and the candidate's own 2001 passes" \
  "$(_ts3c_direct "$TS3C_HL" "$TS3C_M" 2001-sum.sh | _ts3c_fails)/$(_ts3c_direct "$TS3C_HL" "$TS3C_HL" 2001-sum.sh | _ts3c_fails)" "sum: add 2 3 is 5|/"
_ts3c_dry
_ts3c_check "ts3c: S8.2: a candidate that loosens an assertion of an instrument part, with the engine change that makes P's version fail, is refused with escape, the part, P's version fails on this tree, and that assertion's name, and the passing assertion is not named" \
  "$(_ts3c_refused)|$(_ts3c_bl escape 2001-sum.sh "P's version fails on this tree" 'sum: add 2 3 is 5')|$(_ts3c_bl escape - - 'sum: add 0 0 is 0')" "refused|yes|no" "$(_ts3c_why)"
_ts3c_check "ts3c: S8.2, S9: the refused judgement ran P's unit holding 2001-sum.sh, and only it, and left no run tree and the checkout's status as it was (S8.10)" \
  "ran [$(_ts3c_ran)]|left $(_ts3c_left)" "ran [2001-sum.sh ]|left nothing" "$(_ts3c_why)"

_ts3c_case h-unnamed; _ts3c_sed engine/widget/lib.sh 's/^mul() {/mul() { [ "$1 $2" = "2 3" ] \&\& { echo 7; return; };/'
_ts3c_sed "$TS3CT_/parts/2005-mul.sh" 's/^is "mul: mul 2 3 is 6" .*/ok "mul: mul 2 3 is 6"/'; _ts3c_commit "$TS3CR" unnamed
TS3C_HU="$(_jr_sha "$TS3CR" HEAD)"
_ts3c_check "ts3c: S0 (fixture control): P's partition has no row for 2005-mul.sh, and P's 2005 fails on the loosened candidate's tree" \
  "$(git -C "$TS3CR" show "$TS3C_M:projects/felix/partition.tsv" | LC_ALL=C grep -c '^2005-mul.sh')|$(_ts3c_direct "$TS3C_HU" "$TS3C_M" 2005-mul.sh | _ts3c_fails)" "0|mul: mul 2 3 is 6|"
_ts3c_dry
_ts3c_check "ts3c: S0, S8.2: a part P's partition does not name is instrument: loosened with the engine change, it is refused with escape, the part, P's version fails on this tree, and the assertion's name" \
  "$(_ts3c_refused)|$(_ts3c_bl escape 2005-mul.sh "P's version fails on this tree" 'mul: mul 2 3 is 6')" "refused|yes" "$(_ts3c_why)"

# ------------------------------------------------------ S8.3: names kept ---
_ts3c_case h-deleted; _fx_git "$TS3CR" rm -q "$TS3CT_/parts/2006-keep.sh" >/dev/null 2>&1
_ts3c_sed "$TS3CT_/run" '/parts\/2006-keep.sh"$/d'; _ts3c_mani '/^keep: /d'; _ts3c_commit "$TS3CR" deleted; TS3C_HD="$(_jr_sha "$TS3CR" HEAD)"
_ts3c_check "ts3c: S8.3 (fixture control): the engine still satisfies P's 2006-keep.sh on the tree that deletes it, and the candidate's manifest lists neither of its names" \
  "$(_ts3c_direct "$TS3C_HD" "$TS3C_M" 2006-keep.sh | _ts3c_oks)|$(git -C "$TS3CR" show "$TS3C_HD:$TS3CT_/assertions.tsv" | LC_ALL=C grep -c 'keep: ')" \
  "keep: the version file says 1|keep: the version file is one line||0"
_ts3c_dry
_ts3c_check "ts3c: S8.3: a candidate that deletes an instrument part and its names from the manifest, the engine still satisfying it, is refused with escape, the part, drops assertion, for each of its two names" \
  "$(_ts3c_refused)|$(_ts3c_bl escape 2006-keep.sh 'drops assertion' 'keep: the version file says 1')|$(_ts3c_bl escape 2006-keep.sh 'drops assertion' 'keep: the version file is one line')" "refused|yes|yes" "$(_ts3c_why)"

_ts3c_case h-unsourced; _ts3c_sed "$TS3CT_/run" '/parts\/2006-keep.sh"$/d'; _ts3c_mani '/^keep: /d'; _ts3c_commit "$TS3CR" unsourced
TS3C_HS="$(_jr_sha "$TS3CR" HEAD)"
_ts3c_check "ts3c: S8.1 (fixture control): the unsourcing candidate keeps 2006-keep.sh as P holds it and its driver has no line for it" \
  "$(git -C "$TS3CR" rev-parse "$TS3C_HS:$TS3CT_/parts/2006-keep.sh")|$(git -C "$TS3CR" show "$TS3C_HS:$TS3CT_/run" | LC_ALL=C grep -c '2006-keep')" \
  "$(git -C "$TS3CR" rev-parse "$TS3C_M:$TS3CT_/parts/2006-keep.sh")|0"
_ts3c_dry
_ts3c_check "ts3c: S8.1, S8.3: a candidate that keeps an instrument part's file but drops its line from the driver, and its names from the manifest, is refused with drops assertion for each of its two names" \
  "$(_ts3c_refused)|$(_ts3c_bl escape 2006-keep.sh 'drops assertion' 'keep: the version file says 1')|$(_ts3c_bl escape 2006-keep.sh 'drops assertion' 'keep: the version file is one line')" "refused|yes|yes" "$(_ts3c_why)"

_ts3c_case h-rename; _ts3c_sed "$TS3CT_/parts/2006-keep.sh" 's/keep: the version file says 1/keep: the version file names release 1/'
_ts3c_mani 's/keep: the version file says 1/keep: the version file names release 1/'; _ts3c_commit "$TS3CR" rename; TS3C_HR="$(_jr_sha "$TS3CR" HEAD)"
_ts3c_check "ts3c: S8.3 (fixture control): P's 2006-keep.sh passes on the renaming candidate's tree, whose manifest holds the new name and not the old" \
  "$(_ts3c_direct "$TS3C_HR" "$TS3C_M" 2006-keep.sh | _ts3c_fails)|$(git -C "$TS3CR" show "$TS3C_HR:$TS3CT_/assertions.tsv" | LC_ALL=C grep -c 'says 1')$(git -C "$TS3CR" show "$TS3C_HR:$TS3CT_/assertions.tsv" | LC_ALL=C grep -c 'names release 1')" "|01"
_ts3c_dry
_ts3c_check "ts3c: S8.3: a candidate that renames one assertion of an instrument part, and its manifest to match, is refused with drops assertion and the old name, and the name it kept is not named" \
  "$(_ts3c_refused)|$(_ts3c_bl escape 2006-keep.sh 'drops assertion' 'keep: the version file says 1')|$(_ts3c_bl escape - 'drops assertion' 'keep: the version file is one line')" "refused|yes|no" "$(_ts3c_why)"

# --------------------------------------------------------- S8.2: a group ---
_ts3c_case h-group; printf '# the greeting, unchanged\n' >> "$TS3CR/$TS3CT_/parts/2003-grp-a.sh"; printf 'red\n' > "$TS3CR/engine/widget/color.txt"
_ts3c_sed "$TS3CT_/parts/2004-grp-b.sh" 's/colour is blue" \(.*\) blue$/colour is red" \1 red/'; _ts3c_mani 's/colour is blue/colour is red/'
_ts3c_commit "$TS3CR" group; TS3C_HG="$(_jr_sha "$TS3CR" HEAD)"
_ts3c_check "ts3c: S8.2 (fixture control): P's unit g1 on the group candidate's tree passes 2003-grp-a.sh and fails 2004-grp-b.sh, its subject member" \
  "$(_ts3c_direct "$TS3C_HG" "$TS3C_M" 2003-grp-a.sh 2004-grp-b.sh | tr '\n' '|')" \
  "@@prelude-done|  ok    grp-a: the greeting says hello|@@member-done 2003-grp-a.sh|  FAIL  grp-b: the colour is blue|        expected [blue] got [red]|@@member-done 2004-grp-b.sh|@@part-done 2003-grp-a.sh 2004-grp-b.sh|"
_ts3c_dry
_ts3c_check "ts3c: S8.2, S8.6: a candidate that changes one member of a group, where P's version of the subject member would fail, is not refused for the subject member" \
  "$(_ts3c_bl escape 2004-grp-b.sh - -)|$(_ts3c_said 'grp-b: the colour is blue' escape)" "no|no" "$(_ts3c_why)"
_ts3c_check "ts3c: S8.2, S9: the group candidate's judgement ran P's unit g1, both its members and nothing else, and passed, leaving no run tree (S8.10)" \
  "ran [$(_ts3c_ran)]|$(_ts3c_passed)|left $(_ts3c_left)" "ran [2003-grp-a.sh 2004-grp-b.sh ]|passed|left nothing" "$(_ts3c_why)"

# ------------------------------------------------------- S7: the partition ---
TS3C_PT=projects/felix/partition.tsv
_ts3c_case h-table; _ts3c_sed "$TS3C_PT" 's/^2001-sum.sh	instrument	/2001-sum.sh	subject	/'; _ts3c_commit "$TS3CR" table
_ts3c_check "ts3c: S7 (fixture control): P's partition marks 2001-sum.sh instrument and the candidate's marks it subject" \
  "$(git -C "$TS3CR" show "$TS3C_M:$TS3C_PT" | LC_ALL=C awk -F'\t' '$1 == "2001-sum.sh" { print $2 }')|$(LC_ALL=C awk -F'\t' '$1 == "2001-sum.sh" { print $2 }' "$TS3CR/$TS3C_PT")" "instrument|subject"
_ts3c_dry
_ts3c_check "ts3c: S7.2: a candidate that moves an instrument row of the partition to subject is refused with escape, projects/felix/partition.tsv, marks 2001-sum.sh subject" \
  "$(_ts3c_refused)|$(_ts3c_bl escape "$TS3C_PT" 'marks 2001-sum.sh subject' -)" "refused|yes" "$(_ts3c_why)"

_ts3c_case h-tight; _ts3c_sed "$TS3C_PT" '/^2002-count.sh	/d; s/	guards add$/	guards add, and says so/'
printf '2005-mul.sh\tinstrument\tguards mul\n' >> "$TS3CR/$TS3C_PT"; _ts3c_commit "$TS3CR" tight
_ts3c_check "ts3c: S7.2 (fixture control): the tightening candidate's partition differs from P's by the 2005 row added, the 2002 row removed and 2001's why" \
  "$(git -C "$TS3CR" diff -U0 "$TS3C_M" HEAD -- "$TS3C_PT" | LC_ALL=C grep '^[-+][0-9]' | cut -f1,2 | tr '\t\n' ': ')" \
  "-2001-sum.sh:instrument -2002-count.sh:subject +2001-sum.sh:instrument +2005-mul.sh:instrument "
_ts3c_dry
_ts3c_check "ts3c: S7.2: a candidate that adds an instrument row, removes a row and rewords a why is not refused for the partition" \
  "$(_ts3c_bl escape "$TS3C_PT" - -)|$(_ts3c_said marks subject)" "no|no" "$(_ts3c_why)"

_ts3c_case h-both h-loose; _ts3c_sed "$TS3C_PT" 's/^2001-sum.sh	instrument	/2001-sum.sh	subject	/'; _ts3c_commit "$TS3CR" both
_ts3c_check "ts3c: S7.1 (fixture control): the candidate's table marks 2001-sum.sh subject, and P's 2001 fails on its tree" \
  "$(LC_ALL=C awk -F'\t' '$1 == "2001-sum.sh" { print $2 }' "$TS3CR/$TS3C_PT")|$(_ts3c_direct "$(_jr_sha "$TS3CR" HEAD)" "$TS3C_M" 2001-sum.sh | _ts3c_fails)" "subject|sum: add 2 3 is 5|"
_ts3c_dry
_ts3c_check "ts3c: S7.1, S8.2: a candidate that moves 2001-sum.sh to subject and loosens it in the same change is refused for both: the table line, and P's version of the part (P's table says instrument)" \
  "$(_ts3c_refused)|$(_ts3c_bl escape "$TS3C_PT" 'marks 2001-sum.sh subject' -)|$(_ts3c_bl escape 2001-sum.sh "P's version fails on this tree" 'sum: add 2 3 is 5')" "refused|yes|yes" "$(_ts3c_why)"

# ------------------------------------------- S8.4, S8.5: the machinery ---
TS3C_PROBE='bad "probe: bad"; is "probe: is" a b; has "probe: has" abc z; ok "probe: ok"'
TS3C_HLOG="printf '%s\\n' \"\$*\" >> \"$TS3C/hlog\""
_ts3c_mach() {   # BRANCH BAD-BODY IS-BODY [LINE]: a candidate whose driver has these bodies, and LINE after its HERE=
  _ts3c_case "$1"; _ts3c_driver "$TS3CR/$TS3CT_/run" "$2" "$3" "${4:-}"; _ts3c_commit "$TS3CR" "$1"; _jr_sha "$TS3CR" HEAD
}
_ts3c_all() {   # -> the instrument parts of P the last run did not run (not in the trace, nor named by the merge)
  local p m=""; for p in 2001-sum.sh 2003-grp-a.sh 2005-mul.sh 2006-keep.sh; do
    LC_ALL=C grep -qx "$p" "$TS3C/trace" 2>/dev/null || [ "$(_ts3c_said "$p" "$p")" = yes ] || m="$m$p "; done; printf '[%s]' "$m"
}
TS3C_HB="$(_ts3c_mach h-nbad 'PASS=$((PASS+1)); _ran "$1"; printf '"'"'  ok    %s\n'"'"' "$1"; return 0;' "$(_ts3c_honest_is)" "$TS3C_HLOG")"
_ts3c_check "ts3c: S8.5 (fixture control): the neutered candidate's driver reports bad, is and has as passes, where P's reports them failed" \
  "$(_ts3c_direct "$TS3C_HB" "$TS3C_HB" zz-probe.sh | _ts3c_fails)/$(_ts3c_direct "$TS3C_HB" "$TS3C_M" zz-probe.sh | _ts3c_fails)" "/probe: bad|probe: is|probe: has|"
_ts3c_dry
_ts3c_check "ts3c: S8.5: a candidate whose driver's bad() counts a pass is refused with escape, machinery, and the canary" \
  "$(_ts3c_refused)|$(_ts3c_bl escape machinery canary -)" "refused|yes" "$(_ts3c_why)"
_ts3c_check "ts3c: S8.4: when the machinery changed, every instrument part of P was run (2001, 2003, 2005 and 2006), none missing" \
  "missing $(_ts3c_all)" "missing []" "ran [$(_ts3c_ran)]; $(_ts3c_why)"
_ts3c_check "ts3c: S8.10: the judgement that ran the canary under the candidate's driver left no run tree or canary copy under TMPDIR, and the checkout's status as it was" \
  "canary ran $([ -s "$TS3C/hlog" ] && echo yes || echo no)|left $(_ts3c_left)" "canary ran yes|left nothing" "$(_ts3c_why)"
TS3C_C1="$(LC_ALL=C awk '$1 == "--part" { $1 = ""; print }' "$TS3C/hlog" | tr -d ' ' | LC_ALL=C sort -u | tr '\n' ' ')"
# A11 (spec-slice3 section 5): A5 keeps a machinery judgement, and a second judgement of the same pair reads it and runs
# no canary. For the two canary names to be taken across two real runs, remove what the first judgement kept (the files
# under the home naming the canary, 2181's reading), so the two cannot share a key. The assertion below is unchanged.
grep -rlF canary "$TS3CR/state" "$TS3C/home" 2>/dev/null | while IFS= read -r _ts3c_k; do [ -z "$_ts3c_k" ] || rm -f "$_ts3c_k"; done
_ts3c_dry
TS3C_C2="$(LC_ALL=C awk '$1 == "--part" { $1 = ""; print }' "$TS3C/hlog" | tr -d ' ' | LC_ALL=C sort -u | tr '\n' ' ')"
_ts3c_check "ts3c: S8.5: two judgements of the same candidate run the canary under its driver with different part file names, neither a part the candidate holds" \
  "$([ -n "$TS3C_C1" ] && [ -n "$TS3C_C2" ] && echo named)|$([ "$TS3C_C1" != "$TS3C_C2" ] && echo differ)|$(for _n in $TS3C_C1 $TS3C_C2; do git -C "$TS3CR" cat-file -e "$TS3C_HB:$TS3CT_/parts/$_n" 2>/dev/null && printf '%s ' "$_n"; done)" \
  "named|differ|" "first [$TS3C_C1] second [$TS3C_C2]; $(_ts3c_why)"

TS3C_HI="$(_ts3c_mach h-nis "$(_ts3c_honest_bad)" 'ok "$1";' "$TS3C_HLOG")"
_ts3c_check "ts3c: S8.5 (fixture control): the candidate whose is() counts a pass reports is as passed, and bad and has still failed" \
  "$(_ts3c_direct "$TS3C_HI" "$TS3C_HI" zz-probe.sh | _ts3c_fails)" "probe: bad|probe: has|"
_ts3c_dry
_ts3c_check "ts3c: S8.5: a candidate whose driver's is() counts a pass is refused with escape, machinery, and the canary" \
  "$(_ts3c_refused)|$(_ts3c_bl escape machinery canary -)" "refused|yes" "$(_ts3c_why)"

TS3C_HW="$(_ts3c_mach h-word "$(_ts3c_honest_bad | LC_ALL=C sed 's/        %s/        because: %s/')" "$(_ts3c_honest_is)")"
_ts3c_check "ts3c: S8.5 (fixture control): the candidate that rewords bad()'s detail still reports bad, is and has failed and ok passed" \
  "$(_ts3c_direct "$TS3C_HW" "$TS3C_HW" zz-probe.sh | _ts3c_fails)$(_ts3c_direct "$TS3C_HW" "$TS3C_HW" zz-probe.sh | _ts3c_oks)|$(git -C "$TS3CR" diff --name-only "$TS3C_M" "$TS3C_HW" | tr '\n' ' ')" \
  "probe: bad|probe: is|probe: has|probe: ok||$TS3CT_/run "
_ts3c_dry
_ts3c_check "ts3c: S8.5: a candidate that changes a helper's wording only is not refused for the canary" \
  "$(_ts3c_bl escape machinery - -)|$(_ts3c_said canary escape)" "no|no" "$(_ts3c_why)"
_ts3c_check "ts3c: S8.4: the honest machinery change still ran every instrument part of P" "missing $(_ts3c_all)" "missing []" "ran [$(_ts3c_ran)]; $(_ts3c_why)"
TS3C_PROBE=""

# ------------------------------------------- S8.9, S8.11, S8.8: other bases ---
_ts3c_loosen() {   # the loosened guard of h-loose, on the branch checked out
  _ts3c_sed engine/widget/lib.sh 's/^add() {/add() { [ "$1 $2" = "2 3" ] \&\& { echo 6; return; };/'
  _ts3c_sed "$TS3CT_/parts/2001-sum.sh" 's/^is "sum: add 2 3 is 5" .*/ok "sum: add 2 3 is 5"/'
}
_ts3c_case main-nd; _fx_git "$TS3CR" rm -q "$TS3CT_/run" >/dev/null 2>&1; _ts3c_commit "$TS3CR" no-driver; TS3C_BN="$(_jr_sha "$TS3CR" HEAD)"
_ts3c_case h-nd main-nd; _ts3c_loosen; _ts3c_commit "$TS3CR" nd-loose
_fx_git "$TS3CR" update-ref refs/remotes/origin/main "$TS3C_BN" >/dev/null 2>&1; _ts3c_entry "$TS3C_BN"
_ts3c_check "ts3c: S8.9 (fixture control): the base without a driver holds P's parts and no tests/run, and is the provider's main" \
  "$(git -C "$TS3CR" ls-tree --name-only "$TS3C_BN" "$TS3CT_/" | tr '\n' ' ')|$(_jr_sha "$TS3CR" refs/remotes/origin/main)" \
  "$TS3CT_/assertions.tsv $TS3CT_/canary $TS3CT_/groups.tsv $TS3CT_/lib $TS3CT_/parts $TS3CT_/receipt.sh $TS3CT_/red |$TS3C_BN"
_ts3c_dry
_ts3c_check "ts3c: S8.9: with P's driver missing at B, a candidate that changes an instrument part is refused with a blocker of kind unknown, subject SUITE" \
  "$(_ts3c_refused)|$(_ts3c_bl unknown SUITE - -)" "refused|yes" "$(_ts3c_why)"

_ts3c_case main-pr; _fx_git "$TS3CR" rm -q engine/.claude-plugin/plugin.json >/dev/null 2>&1; _ts3c_commit "$TS3CR" product; TS3C_BP="$(_jr_sha "$TS3CR" HEAD)"
_ts3c_case h-pr main-pr; _ts3c_loosen; _ts3c_commit "$TS3CR" pr-loose; TS3C_HP="$(_jr_sha "$TS3CR" HEAD)"
_fx_git "$TS3CR" update-ref refs/remotes/origin/main "$TS3C_BP" >/dev/null 2>&1; _ts3c_entry "$TS3C_M"
_ts3c_check "ts3c: S8.11 (fixture control): the product's base and candidate hold no engine/.claude-plugin/plugin.json, and P's 2001 fails on the candidate's tree" \
  "$(git -C "$TS3CR" cat-file -t "$TS3C_BP:engine/.claude-plugin/plugin.json" 2>/dev/null)$(git -C "$TS3CR" cat-file -t "$TS3C_HP:engine/.claude-plugin/plugin.json" 2>/dev/null)|$(_ts3c_direct "$TS3C_HP" "$TS3C_BP" 2001-sum.sh | _ts3c_fails)" \
  "|sum: add 2 3 is 5|"
_ts3c_dry
_ts3c_check "ts3c: S8.11: in a repository felix_self_governed_at does not name, the same loosened guard is not refused for this: no escape line for the part, no P's version line, no SUITE line, and no part of P runs" \
  "$(_ts3c_bl escape 2001-sum.sh - -)|$(_ts3c_said "P's version" "P's version")|$(_ts3c_bl unknown SUITE - -)|ran [$(_ts3c_ran)]" "no|no|no|ran []" "$(_ts3c_why)"
_fx_git "$TS3CR" update-ref refs/remotes/origin/main "$TS3C_M" >/dev/null 2>&1

_ts3c_on h-loose
TS3C_OBJ="$(git -C "$TS3CR" rev-parse --path-format=absolute --git-path objects 2>/dev/null)"
TS3C_KB="$(git -C "$TS3CR" rev-parse "$TS3C_M:$TS3CT_/parts/2006-keep.sh" 2>/dev/null)"; TS3C_KF="$(_ts3c_loose "$TS3C_KB" "$TS3C_OBJ")"
cp -p "$TS3C_KF" "$TS3C/keep.loose" 2>/dev/null; _ts3c_rewrite "$TS3C_KF" 'ok "keep: forged"
'
_ts3c_check "ts3c: S8.8 (fixture control): P's 2006-keep.sh is loose, and its loose file now holds a body that is not what its name says" \
  "$(git -C "$TS3CR" cat-file -p "$TS3C_KB" 2>/dev/null)" 'ok "keep: forged"'
_ts3c_dry
_ts3c_check "ts3c: S8.8: a loosened candidate that slice 2 refuses with objects is refused with objects, and the merge says P's instrument parts were not run" \
  "$(_ts3c_refused)|$(_ts3c_bl objects - - -)|$(_ts3c_notrun)|ran [$(_ts3c_ran)]" "refused|yes|yes|ran []" "$(_ts3c_why)"
chmod u+w "$TS3C_KF" 2>/dev/null; cat "$TS3C/keep.loose" > "$TS3C_KF"; chmod 444 "$TS3C_KF" 2>/dev/null

# ------------------------------------------------- S8.10: a run killed ---
_ts3c_case h-slow; _ts3c_sed engine/widget/lib.sh 's/^add() {/add() { sleep 3;/'; printf '# slow\n' >> "$TS3CR/$TS3CT_/parts/2001-sum.sh"
_ts3c_commit "$TS3CR" slow
_ts3c_check "ts3c: S8.10 (fixture control): the slow candidate changes 2001-sum.sh and its add sleeps before it answers" \
  "$(git -C "$TS3CR" diff --name-only "$TS3C_M" HEAD | tr '\n' ' ')|$(LC_ALL=C grep -c '^add() { sleep 3;' "$TS3CR/engine/widget/lib.sh")" "engine/harness/tests/parts/2001-sum.sh engine/widget/lib.sh |1"
_ts3c_prep
( _ts3c_go --dry-run ) > "$TS3C/out" 2> "$TS3C/err" & TS3C_PID=$!
_ts3c_i=0; while [ "$_ts3c_i" -lt 600 ] && kill -0 "$TS3C_PID" 2>/dev/null && ! LC_ALL=C grep -qx 2001-sum.sh "$TS3C/trace"; do
  sleep 0.1; _ts3c_i=$((_ts3c_i + 1)); done
TS3C_MID=no; LC_ALL=C grep -qx 2001-sum.sh "$TS3C/trace" && kill -0 "$TS3C_PID" 2>/dev/null && TS3C_MID=yes
kill -TERM "$TS3C_PID" 2>/dev/null; wait "$TS3C_PID" 2>/dev/null; TS3CRC=$?
_ts3c_i=0; while [ "$_ts3c_i" -lt 100 ] && [ "$(_ts3c_left)" != nothing ]; do sleep 0.1; _ts3c_i=$((_ts3c_i + 1)); done
_ts3c_check "ts3c: S8.10: a dry run killed with SIGTERM while P's part runs in T leaves no run tree or canary copy under TMPDIR, and the checkout's status as it was" \
  "killed mid-run $TS3C_MID|left $(_ts3c_left)" "killed mid-run yes|left nothing" "$(_ts3c_why)"

_ts3c_on main; _ts3c_entry "$TS3C_M"
rm -rf "${TS3C:?}"; [ "$TS3C_MEM" != made ] || rm -rf "${MEM:?}/felix"
unset TS3C TS3CR TS3CK TS3CT TS3CPP TS3C_PROBE TS3C_HLOG TS3C_PID TS3C_MID TS3C_MEM
# <<< trust-step3-instrument-parts
