# >>> trust-step3-run-tree-bytes
printf '\ntrust plane step 3, slice 3: what the units read is what lands (spec-slice3 section 8, A22 and A23; blind)\n'
# Blind, written on 2026-11-09 from .felix/memory/felix/audits/2026-11-08-trust-plane-step3/spec-slice3.md, section 8
# (A22, A23 and its observable cases 1 to 5), with sections 0 to 2 read only for P, B, H, T, a unit, unknown SUITE and
# how a dry run reports a refusal, by an author who has not read lib/instrument*.sh, lib/bind.sh or lib/merge-judge.sh:
# felix merge is driven as a black box. Conventions and the fixture come from tests/lib/instrument-parts.sh
# (_ts3c_build), the headers and fixture use of parts 2180 and 2183, and tests/run's helpers. The fixture is part 2180's,
# here under $TMP/ts3g, removed at the end with $MEM/felix when this part made it. Main gains two instrument parts of P
# that read a candidate file, with the files they read: 2007-scan.sh (no line of engine/widget/scan.txt is exactly
# FORBIDDEN token, and the file holds no bare $Id$ keyword) and 2008-marker.sh (engine/widget/MARKER exists).
# Cases 5a and 5b were added the same day, after the fix for cases 1 to 4 (6ab2d37e) was committed on the branch, from
# the paragraphs of section 8 that begin "A23, amended after the automated security review" and "A22 and A23, the same
# review" and the new observable case 5 (the old case 5 is case 6), under the same terms: no lib file named above, and
# no git log -p of the branch's lib changes, was read. Case 6 was added later that day, the same way, from the
# paragraph beginning "A23, amended again after the plain-git check" and the new observable case 6 (old 6 is case 7),
# against 7ccb545e and a later commit that changes only blocker escaping. Its non-ASCII names are written with printf
# from their UTF-8 bytes, so this file stays ASCII: U+2C2F (Glagolitic capital) and U+2C5F (its small form).
# Cases 8 to 10 were added the same way against 32792d05, from the block beginning "A22 and A23, amended after the
# review of the filesystem's answer" and observable cases 8 to 11 (old 7 kept its number). For case 10 the author
# read, of lib/policy.sh and lib/merge-judge.sh, only the comment block directly above _felix_policy_copy, _mj_make and
# _mj_clean and their signature lines, and nothing that implements A22 or A23.
#
# Readings, where the spec leaves room (part 2180's stand on "refused", "passed", a blocker line and the trace):
# - Each candidate also appends a comment to the P part that judges it, so S8.1 counts that part changed and P's unit
#   runs in T. A candidate that changes no instrument part makes no T (S8.7) and is outside these cases.
# - What lands is the blob, whose bytes are set with hash-object --no-filters and update-index --cacheinfo. The file in
#   the checkout is written by git checkout under H's .gitattributes, as a checkout obeying the tree's own attributes
#   writes it; the fixture controls apply P's test to both.
# - Case 1's "refused for P's part (or as unknown SUITE)": an escape line for 2007-scan.sh saying P's version fails on
#   this tree with the assertion's name, or an unknown SUITE line naming engine/widget/scan.txt, the only path an
#   attribute here converts and so the first that can differ (A22).
# - "Naming both" is the unknown SUITE line holding both repository paths. "No unit runs" (A23) is read from the trace;
#   the honest candidate of case 2 shows that the trace records a unit the merge runs.
# - Folding is probed where each run's TMPDIR sits ($TS3C/t): a file made as Fold is found as fOLD. Case 3 asserts the
#   branch that applies and skips the other; cases 4, 5a and 5b are asserted where names fold and skipped where not.
# - Case 5a's "naming it and the directory it folds onto": the unknown SUITE line holds the candidate's whole path,
#   Engine/harness/tests/parts/2999-x.sh, and, as a word, engine or a path that begins engine/ (B's directory the
#   candidate's prefixes fold onto, or a path under it). A23's "no unit runs" is read as in cases 3 and 4.
# - Case 5b's fixture is case 4's shape with an ESC byte in both names; where names do not fold no SUITE line names
#   such a path, so 5b is skipped there. "Shows it as \x1b" is the SUITE line holding both paths with that byte written
#   as the four characters \x1b. "No raw control byte" counts bytes 0x00-0x08, 0x0b-0x1f and 0x7f over stdout and
#   stderr together (TAB and LF are not counted).
# - Case 6 gets a base of its own, a later main that adds P's 2009-glag.sh (instrument: engine/widget/MARK+U+2C2F
#   exists), that file, and a directory engine/wid+U+2C2F/ holding keep.txt, so the cases before it judge an unchanged
#   base. Whether the pair is one name is probed as for case 3, with the pair. Each half's control runs everywhere, its
#   expected value following that probe; each half's assertion is skipped where the pair is two names.
# - Case 6's "naming both": an unknown SUITE line holds both names as A22 and A23 amended print them, each byte outside
#   printable ASCII written as \xNN, with the hex digits in either case (and ASCII letters as printed). In 6b these
#   are the two directories, engine/wid\xe2\xb0\xaf and engine/wid\xe2\xb1\x9f, which a path under either also holds.
# - 6b's candidate is committed from what it stages, not with add -A: where the pair folds, its file lands on disk
#   inside B's directory, and git, which folds ASCII alone, would add it there a second time.
# - Case 8 uses case 3's probe, and each half is skipped where names do not fold; the spec's "where names do not fold,
#   neither is refused for A23" is not asserted. 8a's candidate moves all of engine/widget to engine/w2 before the
#   link, so P's parts still source widget/lib.sh; "naming the base's path" is a SUITE line holding
#   engine/widget/MARKER, and also marker, T's name, as the block's "naming the path walked and T's name" asks. 8b's
#   target is ../Engine/widget/list.txt, and "naming the link" is a SUITE line holding engine/x.conf.
# - Case 9 is case 4's shape with the four characters \x1b in both names, skipped where names do not fold; the SUITE
#   line must hold both with the backslash as \x5c, the hex digits in either case.
# - Case 10 copies from a repository of its own under $TS3C/c10, whose commit's engine/ holds the .gitattributes and
#   an executable harness/felix (so _mj_make can return 0). PREFIX is engine, DEST an empty directory, VERSION 9.9.9,
#   and TMPDIR for the calls is under $TS3C/c10. A copied file is looked for at its path under engine/ and then at its
#   whole path. "Git's own checkout" is checkout-index -a into a prefix, the command the block says the copies use.
#
# Not covered: case 7 and case 11 as assertions (red first is how this part is run, not what it asserts); A23's fold
# of the Unicode-decomposed form (only case is driven); the canary's copy, which A22 and A23 also judge (no candidate
# here changes the machinery); A22's checks of kind, executable bit, a link's target bytes and gitlink, and the filter
# attribute (it needs a driver configured where T is written); the cost; A23's "nothing here applies" where names do not fold (cases 4 to
# 6, 8 and 9 are skipped there); a name the filesystem refuses outright; a link walked past 40 links, to an absolute
# target or above T's root; the check's promptness under TERM; the machine's attributes file, which the base-side
# copies also obey; a control byte from any source other than a path (5b's paths are the only one driven); and what
# section 8 leaves open.
TS3C="$TMP/ts3g"; rm -rf "${TS3C:?}"; mkdir -p "$TS3C/repo" "$TS3C/gh" "$TS3C/home" "$TS3C/kc" "$TS3C/t" "$TS3C/ctl"
TS3C="$(cd "${TS3C:?}" && pwd -P)"; TS3CR="$TS3C/repo"; TS3CK="$TS3C/kc"; TS3CT=""; TS3CRC=0; TS3G_N=0
TS3G_MEM=kept; [ -e "$MEM/felix" ] || TS3G_MEM=made   # the merges write the project felix's memory, $MEM/felix
TS3GT_=engine/harness/tests; TS3GW=engine/widget; TS3G_NL='
'
TS3G_SF='scan: no line of scan.txt is FORBIDDEN token'; TS3G_SI='scan: scan.txt holds no bare Id keyword'
TS3G_SM='marker: the engine holds MARKER'; TS3G_FB="plain words${TS3G_NL}FORBIDDEN token$TS3G_NL"; TS3G_ID="plain words$TS3G_NL\$Id\$$TS3G_NL"

# ------------------------------------------------------------------ helpers ---
_ts3g_check() { if [ "$2" = "$3" ]; then ok "$1"; else bad "$1" "expected [$3] got [$2]${4:+: $4}"; fi; }   # NAME GOT WANT [DETAIL]
_ts3g_why() { printf 'exit %s; out: %s; err: %s' "$TS3CRC" "$(head -c 1500 "$TS3C/out" 2>/dev/null | tr '\n' ' ')" \
  "$(head -c 400 "$TS3C/err" 2>/dev/null | tr '\n' ' ')"; }
_ts3g_said() { cat "$TS3C/out" "$TS3C/err" 2>/dev/null | LC_ALL=C awk -v a="$1" 'index($0, a) { f = 1 } END { print (f ? "yes" : "no") }'; }
_ts3g_refused() { if [ "$TS3CRC" -ne 0 ] && [ "$(_ts3g_said 'not merging')" = yes ]; then printf refused; else printf 'exit %s' "$TS3CRC"; fi; }
_ts3g_passed() { if [ "$TS3CRC" -eq 0 ]; then printf passed; else printf 'exit %s' "$TS3CRC"; fi; }
_ts3g_bl() {   # KIND SUBJECT WORD WORD2 -> yes when the last run printed a blocker line as part 2180 reads one
  cat "$TS3C/out" "$TS3C/err" 2>/dev/null | LC_ALL=C awk -v k="$1" -v nm="$2" -v a="$3" -v b="$4" '
    function subj(s) { return nm == "-" || s == nm || (length(s) > length(nm) && substr(s, length(s) - length(nm)) == "/" nm) }
    index($0, "  ") == 1 && $1 == k && subj($2) && (a == "-" || index($0, a)) && (b == "-" || index($0, b)) { f = 1 }
    END { print (f ? "yes" : "no") }'
}
_ts3g_sha() { _fx_git "$TS3CR" rev-parse --verify -q "$1^{commit}" 2>/dev/null; }   # REV -> its commit in R
_ts3g_record() {   # part 2180's: a green gate receipt and a commission receipt for R as it stands, read against P's project
  local p="$TS3CPP"
  ( _fx_cd "$TS3CR" && FELIX_HOME="$TS3CR"; . "$FROOT/harness/lib/verify.sh"; . "$FROOT/harness/lib/probes.sh"; . "$FROOT/harness/lib/epoch.sh"
    felix_verify_record "$TS3CR" "$TS3CR" 0 "true" "$(felix_tree_id "$TS3CR" "$TS3CR")" "" "" "$(felix_epoch "$p" "$TS3CR")" \
      "$(felix_epoch_components "$p" "$TS3CR" | cut -f2 | paste -sd, -)" ) >/dev/null 2>&1
  ( _fx_cd "$TS3CR" && FELIX_HOME="$TS3CR"; FELIX_HOME_DIR="$TS3CR"; . "$FROOT/harness/lib/commission.sh"
    _o="$(felix_commission_run "$p" "$TS3CR" -)"
    felix_commission_receipt_write "$TS3CR" "$p" "$TS3CR" "$_o" "" ) >/dev/null 2>&1
}
_ts3g_prep() {   # the receipts, the provider stub at R's HEAD and origin/main, the trace emptied, and a fresh TS3CT
  _ts3g_record
  printf '7\tOPEN\tmain\t%s\n' "$(_ts3g_sha HEAD)" > "$TS3C/ctl/a"
  printf 'commit\t%s\n' "$(_ts3g_sha refs/remotes/origin/main)" > "$TS3C/ctl/q"
  : > "$TS3C/ctl/calls"; : > "$TS3C/trace"
  TS3G_N=$((TS3G_N + 1)); mkdir -p "$TS3C/t/$TS3G_N"; TS3CT="$(cd "$TS3C/t/$TS3G_N" && pwd -P)"
}
_ts3g_go() {   # [ARG...]: felix merge from the entry in R, as a child of this shell
  _fx_cd "$TS3CR" && exec env -u FELIX_KERNEL -u FELIX_MERGE_HANDED -u FELIX_INSTRUMENT_UNIT_SECONDS -u FELIX_INSTRUMENT_CANARY_SECONDS \
    HOME="$TS3C/home" PATH="$TS3C/gh:$PATH" TS3C_GHDIR="$TS3C/ctl" FELIX_HOME="$TS3CR" FELIX_KERNEL_CACHE="$TS3CK" \
    TMPDIR="$TS3CT" GIT_ALLOW_PROTOCOL=file "$TS3CK/1.0.0/harness/felix" merge "$@"
}
_ts3g_dry() { _ts3g_prep; ( _ts3g_go --dry-run ) > "$TS3C/out" 2> "$TS3C/err"; TS3CRC=$?; }
_ts3g_ran() { LC_ALL=C sort -u "$TS3C/trace" 2>/dev/null | tr '\n' ' '; }   # -> the parts of P that ran, by name
_ts3g_direct() {   # TREE-REV TESTS-REV PART...: TESTS-REV's driver runs PART... over TREE-REV's tree as git archive writes it
  local d="$TS3C/direct" tr="$1" ts="$2"; shift 2; rm -rf "${d:?}"; mkdir -p "$d"
  _fx_git "$TS3CR" archive -o "$TS3C/d.tar" "$tr" >/dev/null 2>&1 && tar -x -C "$d" -f "$TS3C/d.tar"
  rm -rf "${d:?}/$TS3GT_"
  _fx_git "$TS3CR" archive -o "$TS3C/d.tar" "$ts" "$TS3GT_" >/dev/null 2>&1 && tar -x -C "$d" -f "$TS3C/d.tar"
  rm -f "$TS3C/d.tar"; ( cd "$d" && bash "$TS3GT_/run" --part "$@" ) 2>&1; rm -rf "${d:?}"
}
_ts3g_fails() { LC_ALL=C awk 'index($0, "  FAIL  ") == 1 { printf "%s|", substr($0, 9) }'; }
_ts3g_main() {   # SHA: SHA is the provider's main, the entry its engine, and P's project directory its projects/felix
  _fx_git "$TS3CR" update-ref refs/remotes/origin/main "$1" >/dev/null 2>&1; _ts3c_entry "$1"
  rm -rf "${TS3C:?}/p"; mkdir -p "$TS3C/p"; _fx_git "$TS3CR" archive -o "$TS3C/p.tar" "$1" projects/felix >/dev/null 2>&1 \
    && tar -x -C "$TS3C/p" -f "$TS3C/p.tar"; rm -f "$TS3C/p.tar"; TS3CPP="$TS3C/p/projects/felix"
}
_ts3g_touch() { printf '# the candidate touched this part\n' >> "$TS3CR/$TS3GT_/parts/$1"; }   # PART: S8.1 counts it changed
_ts3g_put() {   # REPO PATH CONTENT: PATH's index entry in REPO holds CONTENT's bytes, through no attribute
  local s; printf '%s' "$3" > "$TS3C/blob.t"
  s="$(_fx_git "$1" hash-object -w --no-filters "$TS3C/blob.t" 2>/dev/null)"; rm -f "$TS3C/blob.t"
  _fx_git "$1" update-index --add --cacheinfo "100644,$s,$2" >/dev/null 2>&1
}
_ts3g_blob() { _ts3g_put "$TS3CR" "$1" "$2"; rm -f "$TS3CR/$1"; _fx_git "$TS3CR" checkout -- "$1" >/dev/null 2>&1; }   # PATH CONTENT, and its file is git checkout's
_ts3g_ci() { _fx_git "$1" -c user.name=t -c user.email=t@t -c commit.gpgsign=false -c maintenance.auto=false commit -qm "$2" >/dev/null 2>&1; }   # REPO MSG: what is staged
_ts3g_bytes() {   # REPO SHA PREFIX DIR -> how many files of SHA under PREFIX DIR holds as their blobs hold them, and which not
  local p f n=0 m=""
  while IFS= read -r p; do f="$4/${p#"$3"/}"; [ -f "$f" ] || f="$4/$p"
    if [ -f "$f" ] && [ "$(_fx_git "$1" hash-object --no-filters "$f" 2>/dev/null)" = "$(_fx_git "$1" rev-parse "$2:$p" 2>/dev/null)" ]; then n=$((n + 1)); else m="$m$p "; fi
  done < <(_fx_git "$1" ls-tree -r --name-only "$2" -- "$3" 2>/dev/null)
  printf 'same %s|differ [%s]' "$n" "$m"
}
_ts3g_cand() {   # BRANCH ATTRS CONTENT -> the commit of a candidate whose .gitattributes is ATTRS (none when empty), whose
                 # scan.txt blob is CONTENT, and which touches 2007-scan.sh; R is left checked out at it
  _ts3c_case "$1"; [ -z "$2" ] || { printf '%s\n' "$2" > "$TS3CR/.gitattributes"; _fx_git "$TS3CR" add .gitattributes >/dev/null 2>&1; }
  _ts3g_blob "$TS3GW/scan.txt" "$3"; _ts3g_touch 2007-scan.sh; _ts3c_commit "$TS3CR" "$1"; _ts3g_sha HEAD
}
_ts3g_hid() {   # SHA FLAG PATTERN -> how many lines P's test finds in scan.txt's blob at SHA, and in the file the checkout wrote
  printf 'blob %s|file %s' "$(_fx_git "$TS3CR" cat-file blob "$1:$TS3GW/scan.txt" 2>/dev/null | LC_ALL=C grep -c "$2" -- "$3")" \
    "$(LC_ALL=C grep -c "$2" -- "$3" "$TS3CR/$TS3GW/scan.txt" 2>/dev/null)"
}
_ts3g_part_bl() { _ts3g_bl escape "$1" "P's version fails on this tree" "$2"; }   # PART NAME -> yes when refused for it
_ts3g_ctl() { LC_ALL=C tr -cd '\000-\010\013-\037\177' | wc -c | tr -d ' '; }   # stdin -> its bytes in 0x00-0x08, 0x0b-0x1f, 0x7f
_ts3g_onto() {   # -> yes when an unknown SUITE line of the last run names TS3G_X and, as a word, engine or a path under it
  cat "$TS3C/out" "$TS3C/err" 2>/dev/null | LC_ALL=C awk -v x="$TS3G_X" 'index($0, "  ") == 1 && $1 == "unknown" && $2 == "SUITE" && index($0, x) &&
    $0 ~ /(^|[^A-Za-z0-9_.-])engine(\/|[^A-Za-z0-9_.-]|$)/ { f = 1 } END { print (f ? "yes" : "no") }'
}
_ts3g_suite2() {   # A B -> yes when an unknown SUITE line of the last run holds A and B, the hex digits of each \xNN in
                   # either case (A and B through ENVIRON, so awk leaves their backslashes as they are)
  cat "$TS3C/out" "$TS3C/err" 2>/dev/null | TS3G_KA="$1" TS3G_KB="$2" LC_ALL=C awk '
    function lowhex(s,   o) { o = ""; while (match(s, /\\x[0-9A-Fa-f][0-9A-Fa-f]/)) { o = o substr(s, 1, RSTART + 1) tolower(substr(s, RSTART + 2, 2)); s = substr(s, RSTART + RLENGTH) } return o s }
    BEGIN { a = lowhex(ENVIRON["TS3G_KA"]); b = lowhex(ENVIRON["TS3G_KB"]) }
    index($0, "  ") == 1 && $1 == "unknown" && $2 == "SUITE" { l = lowhex($0); if (index(l, a) && index(l, b)) f = 1 } END { print (f ? "yes" : "no") }'
}

# ---------------------------------------------------------------- fixture R ---
_ts3c_build; _ts3c_on main
_ts3c_part 2007-scan.sh 'is "scan: no line of scan.txt is FORBIDDEN token" "$(LC_ALL=C grep -c -x -- "FORBIDDEN token" "$W/scan.txt" 2>/dev/null)" 0
is "scan: scan.txt holds no bare Id keyword" "$(LC_ALL=C grep -c -F -- "\$Id\$" "$W/scan.txt" 2>/dev/null)" 0'
_ts3c_part 2008-marker.sh 'is "marker: the engine holds MARKER" "$([ -e "$W/MARKER" ] && echo yes || echo no)" yes'
printf 'plain words\n' > "$TS3CR/$TS3GW/scan.txt"; printf 'the base marker\n' > "$TS3CR/$TS3GW/MARKER"
LC_ALL=C awk '{ print } index($0, "/parts/2006-keep.sh\"") { print ". \"$HERE/parts/2007-scan.sh\""; print ". \"$HERE/parts/2008-marker.sh\"" }' \
  "$TS3CR/$TS3GT_/run" > "$TS3C/run.t" && cat "$TS3C/run.t" > "$TS3CR/$TS3GT_/run"; rm -f "$TS3C/run.t"
printf '2007-scan.sh\tinstrument\tguards what scan.txt holds\n2008-marker.sh\tinstrument\tguards the MARKER file\n' >> "$TS3CR/projects/felix/partition.tsv"
{ _ts3c_names; printf '%s\n' "$TS3G_SF" "$TS3G_SI" "$TS3G_SM"; } | LC_ALL=C sort | LC_ALL=C awk 'NF { printf "1\t%s\n", $0 }' > "$TS3CR/$TS3GT_/assertions.tsv"
_ts3c_commit "$TS3CR" scan; TS3C_M="$(_ts3g_sha HEAD)"; _ts3g_main "$TS3C_M"
: > "$TS3C/trace"; TS3G_D="$(_ts3g_direct "$TS3C_M" "$TS3C_M" 2001-sum.sh 2002-count.sh 2003-grp-a.sh 2004-grp-b.sh 2005-mul.sh 2006-keep.sh 2007-scan.sh 2008-marker.sh | _ts3g_fails)"
_ts3g_check "ts3g: (fixture control) main sources 2007-scan.sh and 2008-marker.sh, its partition marks both instrument, it holds scan.txt and MARKER, P's driver passes every part on main's tree and each part traces itself, and main is the provider's" \
  "$(_fx_git "$TS3CR" show "$TS3C_M:$TS3GT_/run" | LC_ALL=C grep -c -E '/parts/200[78]-')|$(_fx_git "$TS3CR" show "$TS3C_M:projects/felix/partition.tsv" | LC_ALL=C awk -F'\t' '$1 ~ /^200[78]-/ { printf "%s ", $2 }')|$(_fx_git "$TS3CR" ls-tree --name-only "$TS3C_M" -- "$TS3GW/scan.txt" "$TS3GW/MARKER" | tr '\n' ' ')|$TS3G_D|$(_ts3g_ran)|$(_ts3g_sha refs/remotes/origin/main)" \
  "2|instrument instrument |$TS3GW/MARKER $TS3GW/scan.txt ||2001-sum.sh 2002-count.sh 2003-grp-a.sh 2004-grp-b.sh 2005-mul.sh 2006-keep.sh 2007-scan.sh 2008-marker.sh |$TS3C_M"
mkdir -p "$TS3C/t/fold"; : > "$TS3C/t/fold/Fold"; TS3G_FOLD=no; [ -e "$TS3C/t/fold/fOLD" ] && TS3G_FOLD=yes; rm -rf "${TS3C:?}/t/fold"

# ----- A22, case 1: an attribute git's checkout obeys does not hide what lands -----
# Each candidate's .gitattributes gives scan.txt one attribute, and its blob holds what P's 2007-scan.sh refuses, in the
# bytes that attribute changes on checkout: a line FORBIDDEN token re-encoded as UTF-16LE, a bare $Id$ expanded by ident,
# and the same line given a CR before its LF by text eol=crlf, so that an exact-line match misses it.
for _ts3g_v in UTF16 ident crlf; do
  case "$_ts3g_v" in
    UTF16) TS3G_A=working-tree-encoding=UTF-16LE; TS3G_C="$TS3G_FB"; TS3G_F=-x; TS3G_P='FORBIDDEN token'; TS3G_S="$TS3G_SF" ;;
    ident) TS3G_A=ident; TS3G_C="$TS3G_ID"; TS3G_F=-F; TS3G_P='$Id$'; TS3G_S="$TS3G_SI" ;;
    crlf)  TS3G_A='text eol=crlf'; TS3G_C="$TS3G_FB"; TS3G_F=-x; TS3G_P='FORBIDDEN token'; TS3G_S="$TS3G_SF" ;;
  esac
  TS3G_H="$(_ts3g_cand "h-$_ts3g_v" "$TS3GW/scan.txt $TS3G_A" "$TS3G_C")"
  _ts3g_check "ts3g: A22, case 1, $TS3G_A (fixture control): the candidate's blob of scan.txt holds what P's 2007-scan.sh refuses, and the file git's checkout writes for it under the candidate's .gitattributes hides it from that test" \
    "$(_ts3g_hid "$TS3G_H" "$TS3G_F" "$TS3G_P")|$(_fx_git "$TS3CR" diff --name-only "$TS3C_M" "$TS3G_H" | tr '\n' ' ')" \
    "blob 1|file 0|.gitattributes $TS3GT_/parts/2007-scan.sh $TS3GW/scan.txt "
  _ts3g_dry
  _ts3g_check "ts3g: A22, case 1, $TS3G_A: a candidate whose .gitattributes gives scan.txt this attribute, and whose blob holds what P's part refuses, is refused for 2007-scan.sh (or as unknown SUITE naming scan.txt), and is not passed" \
    "$(_ts3g_refused)|$( { [ "$(_ts3g_part_bl 2007-scan.sh "$TS3G_S")" = yes ] || [ "$(_ts3g_bl unknown SUITE "$TS3GW/scan.txt" -)" = yes ]; } && echo caught || echo missed)" \
    "refused|caught" "$(_ts3g_why)"
done

# ----- A22, case 2: the controls -----
# The same candidates with no .gitattributes are refused by P's part as it runs; an honest candidate whose .gitattributes
# is ordinary (*.sh text eol=lf over LF files) is not refused for A22. The trace shows its judgement ran P's unit in T.
for _ts3g_v in line Id; do
  case "$_ts3g_v" in
    line) TS3G_L="FORBIDDEN-line (UTF-16LE, eol=crlf)"; TS3G_C="$TS3G_FB"; TS3G_F=-x; TS3G_P='FORBIDDEN token'; TS3G_S="$TS3G_SF" ;;
    Id)   TS3G_L="bare-Id (ident)"; TS3G_C="$TS3G_ID"; TS3G_F=-F; TS3G_P='$Id$'; TS3G_S="$TS3G_SI" ;;
  esac
  TS3G_H="$(_ts3g_cand "h-plain-$_ts3g_v" "" "$TS3G_C")"
  _ts3g_dry
  _ts3g_check "ts3g: A22, case 2 (control): the $TS3G_L candidate of case 1 with no .gitattributes holds what P's part refuses in its checkout too, and is refused with escape, 2007-scan.sh, P's version fails on this tree, and the assertion's name" \
    "$(_ts3g_hid "$TS3G_H" "$TS3G_F" "$TS3G_P")|$(_ts3g_refused)|$(_ts3g_part_bl 2007-scan.sh "$TS3G_S")" "blob 1|file 1|refused|yes" "$(_ts3g_why)"
done
TS3G_H="$(_ts3g_cand h-honest '*.sh text eol=lf' "plain words$TS3G_NL")"
_ts3g_check "ts3g: A22, case 2 (fixture control): the honest candidate's .gitattributes gives P's parts text and eol=lf, no .sh file of its tree holds a CR, and it changes only that file and 2007-scan.sh" \
  "$(_fx_git "$TS3CR" check-attr text eol -- "$TS3GT_/parts/2007-scan.sh" | LC_ALL=C awk '{ printf "%s ", $NF }')|$(_fx_git "$TS3CR" ls-files --eol -- '*.sh' | LC_ALL=C awk '$1 != "i/lf" && $1 != "i/none" { n++ } END { print n + 0 }')|$(_fx_git "$TS3CR" diff --name-only "$TS3C_M" "$TS3G_H" | tr '\n' ' ')" \
  "set lf |0|.gitattributes $TS3GT_/parts/2007-scan.sh "
_ts3g_dry
_ts3g_check "ts3g: A22, case 2 (control): the honest candidate's judgement ran P's unit holding 2007-scan.sh in T" "ran [$(_ts3g_ran)]" "ran [2007-scan.sh ]" "$(_ts3g_why)"
_ts3g_check "ts3g: A22, case 2: an honest candidate with an ordinary .gitattributes (*.sh text eol=lf over LF files) is not refused for A22: it passes, with no unknown SUITE line and no escape line" \
  "$(_ts3g_passed)|SUITE $(_ts3g_bl unknown SUITE - -)|escape $(_ts3g_bl escape - - -)" "passed|SUITE no|escape no" "$(_ts3g_why)"

# ----- A23, case 3: a name the tree does not hold does not answer -----
# The base holds engine/widget/MARKER; the candidate deletes it and adds engine/widget/marker. Where names fold, P's
# 2008-marker.sh, run over the tree as written here, still finds MARKER; where they do not, it fails.
_ts3c_case h-case; _fx_git "$TS3CR" rm -q "$TS3GW/MARKER" >/dev/null 2>&1; printf 'the candidate marker\n' > "$TS3CR/$TS3GW/marker"
_ts3g_touch 2008-marker.sh; _ts3c_commit "$TS3CR" case; TS3G_H="$(_ts3g_sha HEAD)"; TS3G_WANT=""; [ "$TS3G_FOLD" = yes ] || TS3G_WANT="$TS3G_SM|"
_ts3g_check "ts3g: A23, case 3 (fixture control): the candidate drops engine/widget/MARKER and adds engine/widget/marker, and P's 2008-marker.sh over its tree as written here passes where names fold and fails where they do not" \
  "$(_fx_git "$TS3CR" ls-tree --name-only "$TS3G_H" -- "$TS3GW/" | LC_ALL=C awk '/\/(MARKER|marker)$/ { printf "%s ", $0 }')|$(_ts3g_direct "$TS3G_H" "$TS3C_M" 2008-marker.sh | _ts3g_fails)" \
  "$TS3GW/marker |$TS3G_WANT" "names fold here: $TS3G_FOLD"
_ts3g_dry
if [ "$TS3G_FOLD" = yes ]; then
  _ts3g_check "ts3g: A23, case 3, where names fold: a candidate that deletes the base's MARKER and adds marker is refused as unknown SUITE naming both paths, and no unit runs" \
    "$(_ts3g_refused)|$(_ts3g_bl unknown SUITE "$TS3GW/MARKER" "$TS3GW/marker")|ran [$(_ts3g_ran)]" "refused|yes|ran []" "$(_ts3g_why)"
  skip "ts3g: A23, case 3, where names do not fold: a candidate that deletes the base's MARKER and adds marker is refused by P's 2008-marker.sh" "names fold under this TMPDIR"
else
  skip "ts3g: A23, case 3, where names fold: a candidate that deletes the base's MARKER and adds marker is refused as unknown SUITE naming both paths, and no unit runs" "names do not fold under this TMPDIR"
  _ts3g_check "ts3g: A23, case 3, where names do not fold: a candidate that deletes the base's MARKER and adds marker is refused by P's 2008-marker.sh" \
    "$(_ts3g_refused)|$(_ts3g_part_bl 2008-marker.sh "$TS3G_SM")" "refused|yes" "$(_ts3g_why)"
fi

# ----- A23, case 4: two paths of one tree that fold to one name -----
# The candidate's tree holds engine/widget/Twin.txt and engine/widget/twin.txt with the same bytes, so A22's hashes
# hold for each and only A23 can see them; it touches 2007-scan.sh, so P's unit would run.
_ts3c_case h-twin; _ts3g_blob "$TS3GW/Twin.txt" "a twin$TS3G_NL"; _ts3g_blob "$TS3GW/twin.txt" "a twin$TS3G_NL"
_ts3g_touch 2007-scan.sh; _ts3c_commit "$TS3CR" twin; TS3G_H="$(_ts3g_sha HEAD)"
_ts3g_check "ts3g: A23, case 4 (fixture control): the candidate's tree holds engine/widget/Twin.txt and engine/widget/twin.txt, one blob for both" \
  "$(_fx_git "$TS3CR" ls-tree "$TS3G_H" -- "$TS3GW/" | LC_ALL=C awk -F'\t' '$2 ~ /\/[Tt]win\.txt$/ { split($1, a, " "); printf "%s ", $2; b[a[3]] = 1 } END { n = 0; for (k in b) n++; printf "|%d", n }')" \
  "$TS3GW/Twin.txt $TS3GW/twin.txt |1"
if [ "$TS3G_FOLD" = yes ]; then
  _ts3g_dry
  _ts3g_check "ts3g: A23, case 4, where names fold: a candidate whose tree holds two paths differing only by case is refused as unknown SUITE naming both, and no unit runs" \
    "$(_ts3g_refused)|$(_ts3g_bl unknown SUITE "$TS3GW/Twin.txt" "$TS3GW/twin.txt")|ran [$(_ts3g_ran)]" "refused|yes|ran []" "$(_ts3g_why)"
else
  skip "ts3g: A23, case 4, where names fold: a candidate whose tree holds two paths differing only by case is refused as unknown SUITE naming both, and no unit runs" "names do not fold under this TMPDIR"
fi

# ----- A23 amended, case 5a: a directory prefix in other case does not reach P's test directory -----
# The candidate adds Engine/harness/tests/parts/2999-x.sh, which a case-sensitive replacement of engine/harness/tests
# by B's does not drop, and touches 2007-scan.sh, so T is made. That the file lands inside B's own test directory
# where names fold is shown by writing it, from H, over B's tests extracted here.
TS3G_X=Engine/harness/tests/parts/2999-x.sh
_ts3c_case h-prefix; _ts3g_blob "$TS3G_X" "# a candidate file under the test directory's name in other case$TS3G_NL"
_ts3g_touch 2007-scan.sh; _ts3c_commit "$TS3CR" prefix; TS3G_H="$(_ts3g_sha HEAD)"; rm -rf "${TS3C:?}/lay"; mkdir -p "$TS3C/lay"
_fx_git "$TS3CR" archive -o "$TS3C/lay.tar" "$TS3C_M" "$TS3GT_" >/dev/null 2>&1 && tar -x -C "$TS3C/lay" -f "$TS3C/lay.tar"
_fx_git "$TS3CR" archive -o "$TS3C/lay.tar" "$TS3G_H" "$TS3G_X" >/dev/null 2>&1 && tar -x -C "$TS3C/lay" -f "$TS3C/lay.tar"
TS3G_IN=no; [ -e "$TS3C/lay/$TS3GT_/parts/2999-x.sh" ] && TS3G_IN=yes; rm -rf "${TS3C:?}/lay" "$TS3C/lay.tar"
_ts3g_check "ts3g: A23 amended, case 5a (fixture control): the candidate adds Engine/harness/tests/parts/2999-x.sh and touches 2007-scan.sh, and that file written over B's tests here lands inside B's test directory where names fold, and not where they do not" \
  "$(_fx_git "$TS3CR" diff --name-only "$TS3C_M" "$TS3G_H" | tr '\n' ' ')|inside $TS3G_IN" "$TS3G_X $TS3GT_/parts/2007-scan.sh |inside $TS3G_FOLD"
if [ "$TS3G_FOLD" = yes ]; then
  _ts3g_dry
  _ts3g_check "ts3g: A23 amended, case 5a, where names fold: a candidate that adds a file under Engine/harness/tests/parts/ is refused as unknown SUITE naming that path and the directory it folds onto, and no unit runs" \
    "$(_ts3g_refused)|$(_ts3g_onto)|ran [$(_ts3g_ran)]" "refused|yes|ran []" "$(_ts3g_why)"
else
  skip "ts3g: A23 amended, case 5a, where names fold: a candidate that adds a file under Engine/harness/tests/parts/ is refused as unknown SUITE naming that path and the directory it folds onto, and no unit runs" "names do not fold under this TMPDIR"
fi

# ----- A22 and A23 amended, case 5b: a path is printed with its control bytes written out -----
# Case 4's shape, with an ESC byte in both names: engine/widget/E<ESC>sc.txt and engine/widget/e<ESC>sc.txt, one blob.
TS3G_E="$(printf '\033')"
_ts3c_case h-esc; _ts3g_blob "$TS3GW/E${TS3G_E}sc.txt" "an escape$TS3G_NL"; _ts3g_blob "$TS3GW/e${TS3G_E}sc.txt" "an escape$TS3G_NL"
_ts3g_touch 2007-scan.sh; _ts3c_commit "$TS3CR" esc; TS3G_H="$(_ts3g_sha HEAD)"
_ts3g_check "ts3g: A22 and A23 amended, case 5b (fixture control): the candidate's tree holds two paths under engine/widget that differ only by case and each hold a raw ESC byte, one blob for both, and the control-byte counter finds those two bytes in the tree's raw listing" \
  "$(_fx_git "$TS3CR" ls-tree -z "$TS3G_H" -- "$TS3GW/" | LC_ALL=C tr '\000' '\n' | LC_ALL=C awk -F'\t' '$2 ~ /sc\.txt$/ { split($1, a, " "); n++; b[a[3]] = 1 } END { m = 0; for (k in b) m++; printf "%d|%d", n, m }')|$(_fx_git "$TS3CR" ls-tree -z --name-only "$TS3G_H" -- "$TS3GW/" | LC_ALL=C tr -d '\000' | _ts3g_ctl)" \
  "2|1|2"
if [ "$TS3G_FOLD" = yes ]; then
  _ts3g_dry   # the -v words below hold \\, which awk reads as one backslash: the four characters \x1b
  _ts3g_check "ts3g: A22 and A23 amended, case 5b, where names fold: the unknown SUITE refusal of two paths holding an ESC byte names each with that byte written as backslash x1b" \
    "$(_ts3g_refused)|$(_ts3g_bl unknown SUITE 'engine/widget/E\\x1bsc.txt' 'engine/widget/e\\x1bsc.txt')" "refused|yes" "$(_ts3g_why | LC_ALL=C tr -d '\000-\010\013-\037\177')"
  _ts3g_check "ts3g: A22 and A23 amended, case 5b, where names fold: felix merge's whole output, stdout and stderr, holds no raw byte in 0x00-0x08, 0x0b-0x1f or 0x7f" \
    "$(cat "$TS3C/out" "$TS3C/err" 2>/dev/null | _ts3g_ctl)" 0
else
  skip "ts3g: A22 and A23 amended, case 5b, where names fold: the unknown SUITE refusal of two paths holding an ESC byte names each with that byte written as backslash x1b" "names do not fold under this TMPDIR"
  skip "ts3g: A22 and A23 amended, case 5b, where names fold: felix merge's whole output, stdout and stderr, holds no raw byte in 0x00-0x08, 0x0b-0x1f or 0x7f" "names do not fold under this TMPDIR"
fi

# ----- A23 amended again, case 6: the filesystem says which names are one -----
# A later base adds P's 2009-glag.sh, which requires engine/widget/MARK+U+2C2F, that file, and B's directory
# engine/wid+U+2C2F/. U+2C2F and U+2C5F are a case pair Unicode 14 added, which APFS folds and older tables do not.
TS3G_UC="$(printf '\xe2\xb0\xaf')"; TS3G_LC="$(printf '\xe2\xb1\x9f')"; TS3G_XC='\xe2\xb0\xaf'; TS3G_XL='\xe2\xb1\x9f'
mkdir -p "$TS3C/t/pair"; : > "$TS3C/t/pair/MARK$TS3G_UC"; TS3G_PAIR=no; [ -e "$TS3C/t/pair/MARK$TS3G_LC" ] && TS3G_PAIR=yes; rm -rf "${TS3C:?}/t/pair"
TS3G_SG='glag: the engine holds the base Glagolitic MARK'; _ts3c_on main
_ts3c_part 2009-glag.sh 'is "glag: the engine holds the base Glagolitic MARK" "$([ -e "$W/MARK$(printf "\xe2\xb0\xaf")" ] && echo yes || echo no)" yes'
printf 'the base Glagolitic mark\n' > "$TS3CR/$TS3GW/MARK$TS3G_UC"; mkdir -p "$TS3CR/engine/wid$TS3G_UC"
printf 'a file of the base directory\n' > "$TS3CR/engine/wid$TS3G_UC/keep.txt"
LC_ALL=C awk '{ print } index($0, "/parts/2008-marker.sh\"") { print ". \"$HERE/parts/2009-glag.sh\"" }' "$TS3CR/$TS3GT_/run" > "$TS3C/run.t" && cat "$TS3C/run.t" > "$TS3CR/$TS3GT_/run"; rm -f "$TS3C/run.t"
printf '2009-glag.sh\tinstrument\tguards the Glagolitic MARK file\n' >> "$TS3CR/projects/felix/partition.tsv"
{ _ts3c_names; printf '%s\n' "$TS3G_SF" "$TS3G_SI" "$TS3G_SM" "$TS3G_SG"; } | LC_ALL=C sort | LC_ALL=C awk 'NF { printf "1\t%s\n", $0 }' > "$TS3CR/$TS3GT_/assertions.tsv"
_ts3c_commit "$TS3CR" glag; TS3C_M="$(_ts3g_sha HEAD)"; _ts3g_main "$TS3C_M"
_ts3g_check "ts3g: A23 amended again, case 6 (fixture control): a later main sources 2009-glag.sh, its partition marks it instrument, it holds engine/widget/MARK+U+2C2F and engine/wid+U+2C2F/keep.txt, P's 2009-glag.sh passes on its tree, and it is the provider's main" \
  "$(_fx_git "$TS3CR" show "$TS3C_M:$TS3GT_/run" | LC_ALL=C grep -c '/parts/2009-glag.sh')|$(_fx_git "$TS3CR" show "$TS3C_M:projects/felix/partition.tsv" | LC_ALL=C awk -F'\t' '$1 == "2009-glag.sh" { print $2 }')|$(_fx_git "$TS3CR" ls-tree -r -z --name-only "$TS3C_M" -- "$TS3GW/MARK$TS3G_UC" "engine/wid$TS3G_UC" | tr '\000' ' ')|$(_ts3g_direct "$TS3C_M" "$TS3C_M" 2009-glag.sh | _ts3g_fails)|$(_ts3g_sha refs/remotes/origin/main)" \
  "1|instrument|$TS3GW/MARK$TS3G_UC engine/wid$TS3G_UC/keep.txt ||$TS3C_M"

# 6a: the candidate deletes the base's MARK+U+2C2F, adds MARK+U+2C5F, and touches 2009-glag.sh, the part that requires it.
_ts3c_case h-glag; _fx_git "$TS3CR" rm -q "$TS3GW/MARK$TS3G_UC" >/dev/null 2>&1; _ts3g_blob "$TS3GW/MARK$TS3G_LC" "the candidate Glagolitic mark$TS3G_NL"
_ts3g_touch 2009-glag.sh; _ts3c_commit "$TS3CR" glag-a; TS3G_H="$(_ts3g_sha HEAD)"; TS3G_WANT=""; [ "$TS3G_PAIR" = yes ] || TS3G_WANT="$TS3G_SG|"
_ts3g_check "ts3g: A23 amended again, case 6a (fixture control): the candidate drops engine/widget/MARK+U+2C2F, adds MARK+U+2C5F and touches 2009-glag.sh, and P's 2009-glag.sh over its tree as written here, needing the base's name, passes where this filesystem takes the pair for one name and fails where not" \
  "$(_fx_git "$TS3CR" diff -z --no-renames --name-only "$TS3C_M" "$TS3G_H" | tr '\000' ' ')|$(_ts3g_direct "$TS3G_H" "$TS3C_M" 2009-glag.sh | _ts3g_fails)" \
  "$TS3GT_/parts/2009-glag.sh $TS3GW/MARK$TS3G_UC $TS3GW/MARK$TS3G_LC |$TS3G_WANT" "the pair is one name here: $TS3G_PAIR"
if [ "$TS3G_PAIR" = yes ]; then
  _ts3g_dry
  _ts3g_check "ts3g: A23 amended again, case 6a, where the filesystem takes the pair for one name: a candidate that deletes the base's MARK+U+2C2F, adds MARK+U+2C5F and changes the P part that requires the base's name is refused as unknown SUITE naming both, and no unit runs" \
    "$(_ts3g_refused)|$(_ts3g_suite2 "$TS3GW/MARK$TS3G_XC" "$TS3GW/MARK$TS3G_XL")|ran [$(_ts3g_ran)]" "refused|yes|ran []" "$(_ts3g_why)"
else
  skip "ts3g: A23 amended again, case 6a, where the filesystem takes the pair for one name: a candidate that deletes the base's MARK+U+2C2F, adds MARK+U+2C5F and changes the P part that requires the base's name is refused as unknown SUITE naming both, and no unit runs" "this filesystem takes the pair for two names"
fi

# 6b: the candidate adds engine/wid+U+2C5F/x.txt beside B's engine/wid+U+2C2F/keep.txt, and touches 2007-scan.sh.
_ts3c_case h-wid; _ts3g_blob "engine/wid$TS3G_LC/x.txt" "a candidate file$TS3G_NL"; _ts3g_touch 2007-scan.sh
_fx_git "$TS3CR" add "$TS3GT_/parts/2007-scan.sh" >/dev/null 2>&1; _ts3g_ci "$TS3CR" wid; TS3G_H="$(_ts3g_sha HEAD)"
rm -rf "${TS3C:?}/lay"; mkdir -p "$TS3C/lay"
_fx_git "$TS3CR" archive -o "$TS3C/lay.tar" "$TS3C_M" "engine/wid$TS3G_UC" >/dev/null 2>&1 && tar -x -C "$TS3C/lay" -f "$TS3C/lay.tar"
_fx_git "$TS3CR" archive -o "$TS3C/lay.tar" "$TS3G_H" "engine/wid$TS3G_LC" >/dev/null 2>&1 && tar -x -C "$TS3C/lay" -f "$TS3C/lay.tar"
TS3G_IN=no; [ -e "$TS3C/lay/engine/wid$TS3G_UC/x.txt" ] && TS3G_IN=yes; rm -rf "${TS3C:?}/lay" "$TS3C/lay.tar"
_ts3g_check "ts3g: A23 amended again, case 6b (fixture control): the candidate's tree holds B's engine/wid+U+2C2F/keep.txt and its own engine/wid+U+2C5F/x.txt, it changes only that file and 2007-scan.sh, and its file, written over B's directory here, is found inside B's directory where this filesystem takes the pair for one name, and not where not" \
  "$(_fx_git "$TS3CR" ls-tree -r -z --name-only "$TS3G_H" -- "engine/wid$TS3G_UC" "engine/wid$TS3G_LC" | tr '\000' ' ')|$(_fx_git "$TS3CR" diff -z --no-renames --name-only "$TS3C_M" "$TS3G_H" | tr '\000' ' ')|inside $TS3G_IN" \
  "engine/wid$TS3G_UC/keep.txt engine/wid$TS3G_LC/x.txt |$TS3GT_/parts/2007-scan.sh engine/wid$TS3G_LC/x.txt |inside $TS3G_PAIR"
if [ "$TS3G_PAIR" = yes ]; then
  _ts3g_dry
  _ts3g_check "ts3g: A23 amended again, case 6b, where the filesystem takes the pair for one name: a candidate that adds a file under engine/wid+U+2C5F/ while B holds engine/wid+U+2C2F/ is refused as unknown SUITE naming both, and no unit runs" \
    "$(_ts3g_refused)|$(_ts3g_suite2 "engine/wid$TS3G_XC" "engine/wid$TS3G_XL")|ran [$(_ts3g_ran)]" "refused|yes|ran []" "$(_ts3g_why)"
else
  skip "ts3g: A23 amended again, case 6b, where the filesystem takes the pair for one name: a candidate that adds a file under engine/wid+U+2C5F/ while B holds engine/wid+U+2C2F/ is refused as unknown SUITE naming both, and no unit runs" "this filesystem takes the pair for two names"
fi

# ----- A23 amended after the filesystem's answer, case 8: a link is walked -----
# 8a: the candidate drops MARKER, moves engine/widget to engine/w2 and adds marker there, makes engine/widget a link to
# w2, and touches 2008-marker.sh, which requires engine/widget/MARKER. (MARKER goes first: git rm refuses a path git mv
# has just staged, and the new marker would then write over MARKER where names fold.)
_ts3c_case h-link; _fx_git "$TS3CR" rm -q "$TS3GW/MARKER" >/dev/null 2>&1; _fx_git "$TS3CR" mv "$TS3GW" engine/w2 >/dev/null 2>&1
printf 'the candidate marker\n' > "$TS3CR/engine/w2/marker"; ln -s w2 "$TS3CR/$TS3GW"; _ts3g_touch 2008-marker.sh; _ts3c_commit "$TS3CR" link
TS3G_H="$(_ts3g_sha HEAD)"; TS3G_WANT=""; [ "$TS3G_FOLD" = yes ] || TS3G_WANT="$TS3G_SM|"
_ts3g_check "ts3g: A23 amended after the filesystem's answer, case 8a (fixture control): the candidate's engine/widget is a link to w2 whose engine/w2 holds marker and no MARKER, and where names fold the base's engine/widget/MARKER answers through the link here and P's 2008-marker.sh passes over its tree as written here, and neither where not" \
  "$(_fx_git "$TS3CR" ls-tree "$TS3G_H" -- "$TS3GW" | cut -d' ' -f1)|$(_fx_git "$TS3CR" cat-file blob "$TS3G_H:$TS3GW" 2>/dev/null)|$(_fx_git "$TS3CR" ls-tree --name-only "$TS3G_H" -- engine/w2/ | LC_ALL=C awk '/\/(MARKER|marker)$/ { printf "%s ", $0 }')|answers $([ -e "$TS3CR/$TS3GW/MARKER" ] && echo yes || echo no)|$(_ts3g_direct "$TS3G_H" "$TS3C_M" 2008-marker.sh | _ts3g_fails)" \
  "120000|w2|engine/w2/marker |answers $TS3G_FOLD|$TS3G_WANT"
if [ "$TS3G_FOLD" = yes ]; then
  _ts3g_dry
  _ts3g_check "ts3g: A23 amended after the filesystem's answer, case 8a, where names fold: a candidate that deletes the base's MARKER, makes engine/widget a link to w2 holding marker and changes the P part that requires MARKER is refused as unknown SUITE naming the base's engine/widget/MARKER and T's marker, and no unit runs" \
    "$(_ts3g_refused)|$(_ts3g_bl unknown SUITE "$TS3GW/MARKER" marker)|ran [$(_ts3g_ran)]" "refused|yes|ran []" "$(_ts3g_why)"
else
  skip "ts3g: A23 amended after the filesystem's answer, case 8a, where names fold: a candidate that deletes the base's MARKER, makes engine/widget a link to w2 holding marker and changes the P part that requires MARKER is refused as unknown SUITE naming the base's engine/widget/MARKER and T's marker, and no unit runs" "names do not fold under this TMPDIR"
fi
# 8b: the candidate adds engine/x.conf, a link to ../Engine/widget/list.txt (B's file, its directory in other case).
_ts3c_case h-xconf; ln -s ../Engine/widget/list.txt "$TS3CR/engine/x.conf"; _ts3g_touch 2007-scan.sh; _ts3c_commit "$TS3CR" xconf; TS3G_H="$(_ts3g_sha HEAD)"
_ts3g_check "ts3g: A23 amended after the filesystem's answer, case 8b (fixture control): the candidate adds engine/x.conf, a link to ../Engine/widget/list.txt, and touches 2007-scan.sh, and here the link reaches B's list.txt where names fold and dangles where not" \
  "$(_fx_git "$TS3CR" ls-tree "$TS3G_H" -- engine/x.conf | cut -d' ' -f1)|$(_fx_git "$TS3CR" cat-file blob "$TS3G_H:engine/x.conf" 2>/dev/null)|$(_fx_git "$TS3CR" diff --no-renames --name-only "$TS3C_M" "$TS3G_H" | tr '\n' ' ')|reaches $([ -f "$TS3CR/engine/x.conf" ] && cmp -s "$TS3CR/engine/x.conf" "$TS3CR/$TS3GW/list.txt" && echo yes || echo no)" \
  "120000|../Engine/widget/list.txt|$TS3GT_/parts/2007-scan.sh engine/x.conf |reaches $TS3G_FOLD"
if [ "$TS3G_FOLD" = yes ]; then
  _ts3g_dry
  _ts3g_check "ts3g: A23 amended after the filesystem's answer, case 8b, where names fold: a candidate that adds a link engine/x.conf to ../Engine/widget/list.txt and changes a P part is refused as unknown SUITE naming the link, and no unit runs" \
    "$(_ts3g_refused)|$(_ts3g_bl unknown SUITE engine/x.conf -)|ran [$(_ts3g_ran)]" "refused|yes|ran []" "$(_ts3g_why)"
else
  skip "ts3g: A23 amended after the filesystem's answer, case 8b, where names fold: a candidate that adds a link engine/x.conf to ../Engine/widget/list.txt and changes a P part is refused as unknown SUITE naming the link, and no unit runs" "names do not fold under this TMPDIR"
fi

# ----- A22 and A23 amended after the filesystem's answer, case 9: a backslash in a printed path is written \x5c -----
# Case 4's shape, with the four characters \x1b in both names: engine/widget/B\x1bk.txt and engine/widget/b\x1bk.txt.
TS3G_BS='\x1b'; TS3G_BX='\x5cx1b'
_ts3c_case h-bslash; _ts3g_blob "$TS3GW/B${TS3G_BS}k.txt" "a backslash$TS3G_NL"; _ts3g_blob "$TS3GW/b${TS3G_BS}k.txt" "a backslash$TS3G_NL"
_ts3g_touch 2007-scan.sh; _ts3c_commit "$TS3CR" bslash; TS3G_H="$(_ts3g_sha HEAD)"
_ts3g_check "ts3g: A22 and A23 amended after the filesystem's answer, case 9 (fixture control): the candidate's tree holds two paths under engine/widget that differ only by case and each hold the four characters backslash x1b, one blob for both, and no control byte" \
  "$(_fx_git "$TS3CR" ls-tree -z "$TS3G_H" -- "$TS3GW/" | LC_ALL=C tr '\000' '\n' | LC_ALL=C awk -F'\t' '$2 ~ /k\.txt$/ { split($1, a, " "); printf "%s ", $2; b[a[3]] = 1 } END { m = 0; for (k in b) m++; printf "|%d", m }')|$(_fx_git "$TS3CR" ls-tree -z --name-only "$TS3G_H" -- "$TS3GW/" | LC_ALL=C tr -d '\000' | _ts3g_ctl)" \
  "$TS3GW/B${TS3G_BS}k.txt $TS3GW/b${TS3G_BS}k.txt |1|0"
if [ "$TS3G_FOLD" = yes ]; then
  _ts3g_dry
  _ts3g_check "ts3g: A22 and A23 amended after the filesystem's answer, case 9, where names fold: the unknown SUITE refusal of two paths holding the four characters backslash x1b writes each backslash as backslash x5c" \
    "$(_ts3g_refused)|$(_ts3g_suite2 "$TS3GW/B${TS3G_BX}k.txt" "$TS3GW/b${TS3G_BX}k.txt")" "refused|yes" "$(_ts3g_why)"
else
  skip "ts3g: A22 and A23 amended after the filesystem's answer, case 9, where names fold: the unknown SUITE refusal of two paths holding the four characters backslash x1b writes each backslash as backslash x5c" "names do not fold under this TMPDIR"
fi

# ----- A22 amended after the filesystem's answer, case 10: the base-side copies write each file as its blob holds it -----
# A repository of its own, whose commit's engine/ holds a .gitattributes giving crlf.txt text eol=crlf, id.txt ident and
# u16.txt working-tree-encoding=UTF-16LE, over blobs those change on checkout: LF lines, a bare $Id$, UTF-8 text.
TS3G_R10="$TS3C/c10/repo"; mkdir -p "$TS3G_R10/engine/harness" "$TS3C/c10/tmp" "$TS3C/c10/pol"
( _fx_cd "$TS3G_R10" && git init -q -b main && git config gc.auto 0 && git config maintenance.auto false ) >/dev/null 2>&1
printf 'crlf.txt text eol=crlf\nid.txt ident\nu16.txt working-tree-encoding=UTF-16LE\n' > "$TS3G_R10/engine/.gitattributes"
printf '#!/bin/sh\nexit 0\n' > "$TS3G_R10/engine/harness/felix"; chmod 755 "$TS3G_R10/engine/harness/felix"
_fx_git "$TS3G_R10" add engine/.gitattributes engine/harness/felix >/dev/null 2>&1
_ts3g_put "$TS3G_R10" engine/crlf.txt "one${TS3G_NL}two$TS3G_NL"; _ts3g_put "$TS3G_R10" engine/id.txt "keyword \$Id\$$TS3G_NL"
_ts3g_put "$TS3G_R10" engine/u16.txt "FORBIDDEN token$TS3G_NL"; _ts3g_ci "$TS3G_R10" c10
TS3G_S10="$(_fx_git "$TS3G_R10" rev-parse --verify -q 'HEAD^{commit}' 2>/dev/null)"
_fx_git "$TS3G_R10" checkout-index -a -f --prefix="$TS3C/c10/co/" >/dev/null 2>&1
_ts3g_check "ts3g: A22 amended, case 10 (fixture control): the commit's engine/ holds a .gitattributes naming text eol=crlf, ident and working-tree-encoding=UTF-16LE for three files, and git's own checkout-index of it here writes those three with bytes other than their blobs and the other two files as their blobs" \
  "$(_ts3g_bytes "$TS3G_R10" "$TS3G_S10" engine "$TS3C/c10/co")" "same 2|differ [engine/crlf.txt engine/id.txt engine/u16.txt ]"
TS3G_O="$( _fx_cd "$TS3G_R10" && export TMPDIR="$TS3C/c10/tmp" && . "$FROOT/harness/lib/resolve.sh" && . "$FROOT/harness/lib/policy.sh" \
  && { _felix_policy_copy "$TS3G_R10" "$TS3G_S10" engine "$TS3C/c10/pol" >/dev/null 2>&1; printf 'rc %s|%s' "$?" "$(_ts3g_bytes "$TS3G_R10" "$TS3G_S10" engine "$TS3C/c10/pol")"; } )"
_ts3g_check "ts3g: A22 amended, case 10: _felix_policy_copy of that commit's engine/ returns 0 and writes each file as its blob holds it" "$TS3G_O" "rc 0|same 5|differ []"
TS3G_O="$( _fx_cd "$TS3G_R10" && export TMPDIR="$TS3C/c10/tmp" && . "$FROOT/harness/lib/resolve.sh" && . "$FROOT/harness/lib/merge-judge.sh" \
  && { _mj_make "$TS3G_R10" "$TS3G_S10" 9.9.9 >/dev/null 2>&1; _ts3g_rc=$?
       printf 'rc %s|%s@@%s' "$_ts3g_rc" "$(_ts3g_bytes "$TS3G_R10" "$TS3G_S10" engine "${_MJ_COPY:-$TS3C/c10/none}/9.9.9")" "${_MJ_WHY:-}"; _mj_clean >/dev/null 2>&1; } )"
_ts3g_check "ts3g: A22 amended, case 10: _mj_make of that commit returns 0 and writes each file of its engine/ as its blob holds it" "${TS3G_O%%@@*}" "rc 0|same 5|differ []" "why [${TS3G_O#*@@}]"

_ts3c_on main
rm -rf "${TS3C:?}"; [ "$TS3G_MEM" != made ] || rm -rf "${MEM:?}/felix"
unset TS3C TS3CR TS3CK TS3CT TS3CPP TS3C_M TS3G_MEM TS3G_N TS3G_H TS3G_A TS3G_C TS3G_F TS3G_P TS3G_S TS3G_D TS3G_WANT TS3G_L TS3G_FOLD _ts3g_v TS3G_X TS3G_IN TS3G_E \
  TS3G_UC TS3G_LC TS3G_XC TS3G_XL TS3G_PAIR TS3G_SG TS3G_BS TS3G_BX TS3G_R10 TS3G_S10 TS3G_O
# <<< trust-step3-run-tree-bytes
