# >>> trust-step3-instrument-parts-b
printf '\ntrust plane step 3, slice 3: the amendments after the first build'"'"'s review (spec-slice3 section 4, A1-A7; blind)\n'
# Blind, written on 2026-11-08 from .felix/memory/felix/audits/2026-11-08-trust-plane-step3/spec-slice3.md, section 4
# above all, by an author who has not read lib/instrument.sh or lib/instrument-run.sh: felix merge is driven as a black
# box. The fixture is part 2180's (tests/lib/instrument-parts.sh, _ts3c_build), here under $TMP/ts3d, removed at the end
# with $MEM/felix when this part made it. One change to it: main's driver also writes its arguments to $TS3C/hlog (an
# absolute path outside every tree) and holds one blank line, so that P's driver and the candidate's both say what they
# were given, and a candidate can free that blank line (A2).
#
# Readings, where the spec leaves room (part 2180's stand: "refused", "passed", a blocker line, the trace, "left"):
# - "The canary ran" is a line `--part NAME` in $TS3C/hlog naming no part file of the fixture: P's driver logs P's
#   units, and the canary runs under the candidate's driver, which logs it too. "A full run" is every instrument part
#   of P (2001, 2003, 2005, 2006) in the trace.
# - A5's kept judgement is found as the files under the home (R's state/, and HOME) that hold the word canary after the
#   first judgement of a candidate refused for its canary, and did not before it.
# - A7.5, A7.6: where T is is read from inside a unit. The candidate's engine, which P's 2001-sum.sh calls in T, writes
#   $PWD, the lines of git's objects/info/alternates (when that file exists) and git's top level to $TS3C/where.
# - A7.2: a unit that never ends is an add() that sleeps 20 s in a perl whose arguments carry a token made for this
#   run; a lowered limit of 3 s must end it, and afterwards no process carries the token. A limit raised above 1800
#   cannot be seen without a 30-minute unit: it is read only as the report not naming the raised value.
# - A7.4: the merge is started through perl, which puts INT and QUIT back to their default, since a background job of
#   a non-interactive bash inherits them ignored.
TS3C="$TMP/ts3d"; rm -rf "${TS3C:?}"; mkdir -p "$TS3C/repo" "$TS3C/gh" "$TS3C/home" "$TS3C/kc" "$TS3C/t" "$TS3C/ctl"
TS3C="$(cd "${TS3C:?}" && pwd -P)"; TS3CR="$TS3C/repo"; TS3CK="$TS3C/kc"; TS3CT=""; TS3CRC=0; TS3D_N=0; TS3D_ST=""
TS3D_TMP=""; TS3D_ENV=""; TS3D_PROBE=""; TS3D_NL='
'; TS3D_TOK="ts3dhang$$x$RANDOM"; TS3DT_="engine/harness/tests"; TS3D_PT=projects/felix/partition.tsv
TS3D_INST="2001-sum.sh 2003-grp-a.sh 2005-mul.sh 2006-keep.sh"; TS3D_HLOG="printf '%s\\n' \"\$*\" >> \"$TS3C/hlog\""
TS3D_MEM=kept; [ -e "$MEM/felix" ] || TS3D_MEM=made   # the merges write the project felix's memory, $MEM/felix

# ------------------------------------------------------------------ helpers ---
_ts3d_check() { if [ "$2" = "$3" ]; then ok "$1"; else bad "$1" "expected [$3] got [$2]${4:+: $4}"; fi; }   # NAME GOT WANT [DETAIL]
_ts3d_why() { printf 'exit %s; out: %s; err: %s' "$TS3CRC" "$(head -c 1500 "$TS3C/out" 2>/dev/null | tr '\n' ' ')" \
  "$(head -c 400 "$TS3C/err" 2>/dev/null | tr '\n' ' ')"; }
_ts3d_said() { cat "$TS3C/out" "$TS3C/err" 2>/dev/null | LC_ALL=C awk -v a="$1" -v b="$2" 'index($0, a) && index($0, b) { f = 1 } END { print (f ? "yes" : "no") }'; }
_ts3d_refused() { if [ "$TS3CRC" -ne 0 ] && [ "$(_ts3d_said 'not merging' 'not merging')" = yes ]; then printf refused; else printf 'exit %s' "$TS3CRC"; fi; }
_ts3d_passed() { if [ "$TS3CRC" -eq 0 ]; then printf passed; else printf 'exit %s' "$TS3CRC"; fi; }
_ts3d_bl() {   # KIND SUBJECT WORD WORD2 -> yes when the last run printed a blocker line as part 2180 reads one
  cat "$TS3C/out" "$TS3C/err" 2>/dev/null | LC_ALL=C awk -v k="$1" -v nm="$2" -v a="$3" -v b="$4" '
    function subj(s) { return nm == "-" || s == nm || (length(s) > length(nm) && substr(s, length(s) - length(nm)) == "/" nm) }
    index($0, "  ") == 1 && $1 == k && subj($2) && (a == "-" || index($0, a)) && (b == "-" || index($0, b)) { f = 1 }
    END { print (f ? "yes" : "no") }'
}
_ts3d_esc() { _ts3d_bl escape - - -; }
_ts3d_lines() { cat "$TS3C/out" "$TS3C/err" 2>/dev/null | LC_ALL=C awk 'index($0, "  ") == 1 && ($1 == "escape" || $1 == "unknown")' | LC_ALL=C sort; }
_ts3d_subj() { _ts3d_lines | LC_ALL=C awk '{ s = $2; sub(/.*\//, "", s); print $1 ":" s }' | LC_ALL=C sort -u | tr '\n' ' '; }   # KIND:PART of each
_ts3d_record() {   # part 2180's: a green gate receipt and a commission receipt for R as it stands, read against P's project
  local p="$TS3CPP"
  ( cd "$TS3CR" && FELIX_HOME="$TS3CR"; . "$FROOT/harness/lib/verify.sh"; . "$FROOT/harness/lib/probes.sh"; . "$FROOT/harness/lib/epoch.sh"
    felix_verify_record "$TS3CR" "$TS3CR" 0 "true" "$(felix_tree_id "$TS3CR" "$TS3CR")" "" "" "$(felix_epoch "$p" "$TS3CR")" \
      "$(felix_epoch_components "$p" "$TS3CR" | cut -f2 | paste -sd, -)" ) >/dev/null 2>&1
  ( cd "$TS3CR" && FELIX_HOME="$TS3CR"; FELIX_HOME_DIR="$TS3CR"; . "$FROOT/harness/lib/commission.sh"
    _o="$(felix_commission_run "$p" "$TS3CR" -)"
    felix_commission_receipt_write "$TS3CR" "$p" "$TS3CR" "$_o" "" ) >/dev/null 2>&1
}
_ts3d_status() { git -C "$TS3CR" status --porcelain 2>&1; }
_ts3d_prep() {   # the receipts, the provider stub at R's HEAD and origin/main, the logs emptied, and a fresh TS3CT
  _ts3d_record
  printf '7\tOPEN\tmain\t%s\n' "$(_jr_sha "$TS3CR" HEAD)" > "$TS3C/ctl/a"
  printf 'commit\t%s\n' "$(_jr_sha "$TS3CR" refs/remotes/origin/main)" > "$TS3C/ctl/q"
  : > "$TS3C/ctl/calls"; : > "$TS3C/trace"; : > "$TS3C/hlog"; : > "$TS3C/where"
  TS3D_N=$((TS3D_N + 1)); mkdir -p "$TS3C/t/$TS3D_N"; TS3CT="$(cd "$TS3C/t/$TS3D_N" && pwd -P)"; TS3D_ST="$(_ts3d_status)"
}
_ts3d_go() {   # [ARG...]: felix merge from the entry in R, through perl (INT, QUIT at their default), TMPDIR $TS3D_TMP or
               # the run's own, and $TS3D_ENV, when set, one NAME=VALUE more
  cd "$TS3CR" && exec perl -e '$SIG{INT} = "DEFAULT"; $SIG{QUIT} = "DEFAULT"; exec { $ARGV[0] } @ARGV; exit 127' \
    env -u FELIX_KERNEL -u FELIX_MERGE_HANDED -u FELIX_INSTRUMENT_UNIT_SECONDS -u FELIX_INSTRUMENT_CANARY_SECONDS \
    HOME="$TS3C/home" PATH="$TS3C/gh:$PATH" TS3C_GHDIR="$TS3C/ctl" FELIX_HOME="$TS3CR" FELIX_KERNEL_CACHE="$TS3CK" \
    TMPDIR="${TS3D_TMP:-$TS3CT}" GIT_ALLOW_PROTOCOL=file ${TS3D_ENV:+"$TS3D_ENV"} "$TS3CK/1.0.0/harness/felix" merge "$@"
}
_ts3d_dry() { _ts3d_prep; ( _ts3d_go --dry-run ) > "$TS3C/out" 2> "$TS3C/err"; TS3CRC=$?; }
_ts3d_left() {   # -> what the last run left: its TMPDIR's entries, and the checkout's status when it changed
  local e; e="$(cd "$TS3CT" 2>/dev/null && find . -mindepth 1 -maxdepth 2 2>/dev/null | LC_ALL=C sort | tr '\n' ' ')"
  [ "$(_ts3d_status)" = "$TS3D_ST" ] || e="${e}status [$(_ts3d_status | tr '\n' ' ')]"
  printf '%s' "${e:-nothing}"
}
_ts3d_ran() { LC_ALL=C sort -u "$TS3C/trace" 2>/dev/null | tr '\n' ' '; }
_ts3d_full() { local p m=""; for p in $TS3D_INST; do LC_ALL=C grep -qx "$p" "$TS3C/trace" 2>/dev/null || m="$m$p "; done; printf '[%s]' "$m"; }   # -> P's instrument parts not run
_ts3d_canary() { LC_ALL=C awk '$1 == "--part" { for (i = 2; i <= NF; i++) if ($i !~ /^200[1-7]-[a-z-]+\.sh$/) f = 1 } END { print (f ? "yes" : "no") }' "$TS3C/hlog" 2>/dev/null; }
_ts3d_direct() {   # TREE-REV TESTS-REV PART...: TESTS-REV's driver runs PART... over TREE-REV's tree (part 2180's _ts3c_direct)
  local d="$TS3C/direct" tr="$1" ts="$2"; shift 2; rm -rf "${d:?}"; mkdir -p "$d"
  _fx_git "$TS3CR" archive -o "$TS3C/d.tar" "$tr" >/dev/null 2>&1 && tar -x -C "$d" -f "$TS3C/d.tar"
  rm -rf "${d:?}/engine/harness/tests"
  _fx_git "$TS3CR" archive -o "$TS3C/d.tar" "$ts" engine/harness/tests >/dev/null 2>&1 && tar -x -C "$d" -f "$TS3C/d.tar"
  rm -f "$TS3C/d.tar"; [ -z "$TS3D_PROBE" ] || printf '%s\n' "$TS3D_PROBE" > "$d/engine/harness/tests/parts/zz-probe.sh"
  ( cd "$d" && bash engine/harness/tests/run --part "$@" ) 2>&1; rm -rf "${d:?}"
}
_ts3d_fails() { LC_ALL=C awk 'index($0, "  FAIL  ") == 1 { printf "%s|", substr($0, 9) }'; }
_ts3d_sed() { LC_ALL=C sed "$2" "$TS3CR/$1" > "$TS3C/sed.t" && cat "$TS3C/sed.t" > "$TS3CR/$1"; rm -f "$TS3C/sed.t"; }   # FILE SCRIPT
_ts3d_awk() { LC_ALL=C awk "$2" "$TS3CR/$1" > "$TS3C/awk.t" && cat "$TS3C/awk.t" > "$TS3CR/$1"; rm -f "$TS3C/awk.t"; }   # FILE PROGRAM
_ts3d_drv() { _ts3c_driver "$TS3CR/$TS3DT_/run" "$1" "$2" "$TS3D_HLOG$TS3D_NL${3:+$3$TS3D_NL}"; }   # BAD IS [LINE]: logs, LINE, a blank line
_ts3d_mani() { { _ts3c_names; [ "$#" -eq 0 ] || printf '%s\n' "$@"; } | LC_ALL=C sort | LC_ALL=C awk 'NF { printf "1\t%s\n", $0 }' > "$TS3CR/$TS3DT_/assertions.tsv"; }   # [EXTRA-NAME...]
_ts3d_diff() { git -C "$TS3CR" diff -U0 "$1" "$2" -- "$3" 2>/dev/null | LC_ALL=C awk '/^[-+]/ && !/^(---|\+\+\+) / { printf "%s|", $0 }'; }   # A B PATH -> the lines changed
_ts3d_names() { git -C "$TS3CR" diff --name-only "$1" "$2" 2>/dev/null | tr '\n' ' '; }   # A B -> the paths changed
_ts3d_rows() { git -C "$TS3CR" show "$1:$TS3D_PT" 2>/dev/null | LC_ALL=C awk -F'\t' -v p="$2" '$1 == p { printf "%s ", $2 }'; }   # REV PART -> its classes
_ts3d_main() {   # SHA: SHA is the provider's main, the entry its engine, and P's project directory its projects/felix
  _fx_git "$TS3CR" update-ref refs/remotes/origin/main "$1" >/dev/null 2>&1; _ts3c_entry "$1"
  rm -rf "${TS3C:?}/p"; mkdir -p "$TS3C/p"; _fx_git "$TS3CR" archive -o "$TS3C/p.tar" "$1" projects/felix >/dev/null 2>&1 \
    && tar -x -C "$TS3C/p" -f "$TS3C/p.tar"; rm -f "$TS3C/p.tar"; TS3CPP="$TS3C/p/projects/felix"
}
_ts3d_alive() { ps -A -o args= 2>/dev/null | LC_ALL=C awk -v t="perl -e sleep 20 $1" 'index($0, t) == 1 { n++ } END { print n + 0 }'; }   # TOKEN
_ts3d_hangs() { local i=0 n; while :; do n="$(_ts3d_alive "$1")"; { [ "$n" -eq 0 ] || [ "$i" -ge 30 ]; } && break; sleep 0.1; i=$((i + 1)); done; printf '%s' "$n"; }
_ts3d_hang() {   # BRANCH TOKEN: add() sleeps 20 s in a perl carrying TOKEN before it answers 2 plus anything; 2001 gains a comment
  _ts3c_case "$1"; _ts3d_sed engine/widget/lib.sh 's/^add() {/add() { [ "$1" != 2 ] || perl -e "sleep 20" '"$2"';/'
  printf '# a unit of this candidate never ends\n' >> "$TS3CR/$TS3DT_/parts/2001-sum.sh"; _ts3c_commit "$TS3CR" "$1"
}
_ts3d_loosen_mul() {   # part 2180's h-unnamed: mul 2 3 answers 7, and 2005-mul.sh no longer checks it
  _ts3d_sed engine/widget/lib.sh 's/^mul() {/mul() { [ "$1 $2" = "2 3" ] \&\& { echo 7; return; };/'
  _ts3d_sed "$TS3DT_/parts/2005-mul.sh" 's/^is "mul: mul 2 3 is 6" .*/ok "mul: mul 2 3 is 6"/'
}

# ---------------------------------------------------------------- fixture R ---
_ts3c_build; _ts3c_on main; _ts3d_drv "$(_ts3c_honest_bad)" "$(_ts3c_honest_is)"; _ts3c_commit "$TS3CR" logging
TS3C_M="$(_jr_sha "$TS3CR" HEAD)"; _ts3d_main "$TS3C_M"; TS3D_ALL="2001-sum.sh 2002-count.sh 2003-grp-a.sh 2004-grp-b.sh 2005-mul.sh 2006-keep.sh"
_ts3d_check "ts3d: (fixture control) main's driver logs its arguments and holds one blank line, P holds the canary, P's driver passes every part on main's tree, and main is the provider's" \
  "$(git -C "$TS3CR" show "$TS3C_M:$TS3DT_/run" | LC_ALL=C grep -c '^$')|$(git -C "$TS3CR" show "$TS3C_M:$TS3DT_/run" | LC_ALL=C grep -cF "$TS3C/hlog")|$(git -C "$TS3CR" ls-tree -r --name-only "$TS3C_M" -- "$TS3DT_/canary" | LC_ALL=C grep -c .)|$(_ts3d_direct "$TS3C_M" "$TS3C_M" $TS3D_ALL | _ts3d_fails)|$(_jr_sha "$TS3CR" refs/remotes/origin/main)" \
  "1|1|$(find "$REAL_HARNESS/tests/canary" -type f 2>/dev/null | LC_ALL=C grep -c .)||$TS3C_M"

# ------------------------------------------------------------ A4: H = B ---
_ts3c_case h-same; _fx_git "$TS3CR" -c user.name=t -c user.email=t@t -c commit.gpgsign=false -c maintenance.auto=false commit --allow-empty -qm same >/dev/null 2>&1
_ts3d_check "ts3d: A4 (fixture control): the candidate is a commit of its own whose tree is main's" \
  "$([ "$(_jr_sha "$TS3CR" HEAD)" != "$TS3C_M" ] && echo own)|$(git -C "$TS3CR" rev-parse HEAD^{tree})" "own|$(git -C "$TS3CR" rev-parse "$TS3C_M^{tree}")"
_ts3d_dry
_ts3d_check "ts3d: A4: P judged against its own tree is clean: passed, no escape line, no line of P's version" \
  "$(_ts3d_passed)|escape $(_ts3d_esc)|$(_ts3d_said "P's version" "P's version")" "passed|escape no|no" "$(_ts3d_why)"

# ------------------------------------------- A3: the machinery fails closed ---
_ts3c_case h-helpers; printf 'notes for the suite, which no driver reads\n' > "$TS3CR/$TS3DT_/helpers.txt"; _ts3c_commit "$TS3CR" helpers
_ts3d_check "ts3d: A3 (fixture control): the candidate adds engine/harness/tests/helpers.txt and changes nothing else" \
  "$(_ts3d_names "$TS3C_M" HEAD)" "$TS3DT_/helpers.txt "
_ts3d_dry
_ts3d_check "ts3d: A3: a new file under engine/harness/tests/ outside parts/ is machinery: every instrument part of P runs, and the canary runs under the candidate's driver" \
  "missing $(_ts3d_full)|canary $(_ts3d_canary)" "missing []|canary yes" "ran [$(_ts3d_ran)]; $(_ts3d_why)"
_ts3d_check "ts3d: A4: P's instrument units run over a tree that is P's but for a file no driver reads all pass: passed, no escape line, no line of P's version, and every one ran" \
  "$(_ts3d_passed)|escape $(_ts3d_esc)|$(_ts3d_said "P's version" "P's version")|missing $(_ts3d_full)" "passed|escape no|no|missing []" "$(_ts3d_why)"

# ------------------------------------------- A2: the driver's blank lines ---
_ts3c_case h-addpart; _ts3c_part 2007-new.sh 'is "new: mul 3 3 is 9" "$(mul 3 3)" 9'
_ts3d_awk "$TS3DT_/run" '!/^$/ { print } /parts\/2006-keep.sh"$/ { print ". \"$HERE/parts/2007-new.sh\"" }'
_ts3d_mani 'new: mul 3 3 is 9'; _ts3c_commit "$TS3CR" addpart; TS3D_HA="$(_jr_sha "$TS3CR" HEAD)"
_ts3d_check "ts3d: A2 (fixture control): the candidate's driver differs from P's by its blank line deleted and one part line added, and its own driver passes the new part" \
  "$(_ts3d_diff "$TS3C_M" "$TS3D_HA" "$TS3DT_/run")/$(_ts3d_direct "$TS3D_HA" "$TS3D_HA" 2007-new.sh | _ts3d_fails)" "-|+. \"\$HERE/parts/2007-new.sh\"|/"
_ts3d_dry
_ts3d_check "ts3d: A2: a candidate that adds a part and its driver line and frees a blank line is no machinery change: passed, no escape line, no unit run, no canary" \
  "$(_ts3d_passed)|escape $(_ts3d_esc)|ran [$(_ts3d_ran)]|canary $(_ts3d_canary)" "passed|escape no|ran []|canary no" "$(_ts3d_why)"

_ts3c_case h-semi; _ts3c_part 2007-new.sh 'is "new: mul 3 3 is 9" "$(mul 3 3)" 9'
_ts3d_awk "$TS3DT_/run" '{ print } /parts\/2006-keep.sh"$/ { print ". \"$HERE/parts/2007-new.sh\"; PASS=$((PASS+0))" }'
_ts3d_mani 'new: mul 3 3 is 9'; _ts3c_commit "$TS3CR" semi; TS3D_HM="$(_jr_sha "$TS3CR" HEAD)"
_ts3d_check "ts3d: A2 (fixture control): the candidate's driver differs from P's by one added line that starts as a part line and runs more after it" \
  "$(_ts3d_diff "$TS3C_M" "$TS3D_HM" "$TS3DT_/run")" "+. \"\$HERE/parts/2007-new.sh\"; PASS=\$((PASS+0))|"
_ts3d_dry
_ts3d_check "ts3d: A2: a driver line '. \"\$HERE/parts/x.sh\"; <more>' is machinery: every instrument part of P runs, and the canary runs" \
  "missing $(_ts3d_full)|canary $(_ts3d_canary)" "missing []|canary yes" "ran [$(_ts3d_ran)]; $(_ts3d_why)"

# ---------------------------------------------- A5: the judgement is kept ---
_ts3c_case h-nbad; _ts3d_drv 'PASS=$((PASS+1)); _ran "$1"; printf '"'"'  ok    %s\n'"'"' "$1"; return 0;' "$(_ts3c_honest_is)"
_ts3c_commit "$TS3CR" nbad; TS3D_HB="$(_jr_sha "$TS3CR" HEAD)"
TS3D_PROBE='bad "probe: bad"; is "probe: is" a b; has "probe: has" abc z; ok "probe: ok"'
_ts3d_check "ts3d: A5 (fixture control): the candidate changes only its driver, whose bad() counts a pass where P's reports a failure" \
  "$(_ts3d_names "$TS3C_M" "$TS3D_HB")|$(_ts3d_direct "$TS3D_HB" "$TS3D_HB" zz-probe.sh | _ts3d_fails)/$(_ts3d_direct "$TS3D_HB" "$TS3C_M" zz-probe.sh | _ts3d_fails)" \
  "$TS3DT_/run |/probe: bad|probe: is|probe: has|"
TS3D_PROBE=""
_ts3d_kept() { grep -rlF canary "$TS3CR/state" "$TS3C/home" 2>/dev/null | LC_ALL=C sort; }   # the files under the home naming the canary
TS3D_K0="$(_ts3d_kept)"; _ts3d_dry; TS3D_L1="$(_ts3d_lines)"
TS3D_KN="$(_ts3d_kept | LC_ALL=C awk -v k0="$TS3D_K0" 'BEGIN { n = split(k0, a, "\n"); for (i = 1; i <= n; i++) s[a[i]] = 1 } NF && !($0 in s)')"
_ts3d_check "ts3d: A5 (control): the first judgement of the neutered candidate ran P's units and the canary, and is refused for the canary" \
  "$(_ts3d_refused)|$(_ts3d_bl escape machinery canary -)|missing $(_ts3d_full)|canary $(_ts3d_canary)" "refused|yes|missing []|canary yes" "$(_ts3d_why)"
_ts3d_dry
_ts3d_check "ts3d: A5: a second dry run of the same machinery-changing candidate at the same base runs no unit and no canary, and prints the same blocker lines" \
  "$(_ts3d_refused)|ran [$(_ts3d_ran)]|canary $(_ts3d_canary)|$([ "$(_ts3d_lines)" = "$TS3D_L1" ] && echo same || echo differ)" "refused|ran []|canary no|same" \
  "kept [$(printf '%s' "$TS3D_KN" | tr '\n' ' ')]; $(_ts3d_why)"
printf '%s\n' "$TS3D_KN" | while IFS= read -r _ts3d_f; do [ -z "$_ts3d_f" ] || chmod 000 "$_ts3d_f"; done
_ts3d_dry
_ts3d_check "ts3d: A5: a kept judgement made unreadable is not used: the judgement runs again, and refuses for the canary again" \
  "found $([ -n "$TS3D_KN" ] && echo yes || echo no)|$(_ts3d_refused)|$(_ts3d_bl escape machinery canary -)|ran $([ -n "$(_ts3d_ran)" ] && echo yes || echo no)" "found yes|refused|yes|ran yes" "$(_ts3d_why)"
printf '%s\n' "$TS3D_KN" | while IFS= read -r _ts3d_f; do [ -z "$_ts3d_f" ] || chmod 644 "$_ts3d_f"; done
TS3D_KT="$(_ts3d_kept)"
printf '%s\n' "$TS3D_KT" | while IFS= read -r _ts3d_f; do [ -n "$_ts3d_f" ] || continue
  head -c "$(( $(wc -c < "$_ts3d_f") / 2 ))" "$_ts3d_f" > "$TS3C/half.t"; chmod u+w "$_ts3d_f"; cat "$TS3C/half.t" > "$_ts3d_f"; done; rm -f "$TS3C/half.t"
_ts3d_dry
_ts3d_check "ts3d: A5: a kept judgement cut to half its bytes is not used: the judgement runs again, and refuses for the canary again" \
  "found $([ -n "$TS3D_KT" ] && echo yes || echo no)|$(_ts3d_refused)|$(_ts3d_bl escape machinery canary -)|ran $([ -n "$(_ts3d_ran)" ] && echo yes || echo no)" "found yes|refused|yes|ran yes" "$(_ts3d_why)"

# ------------------------------------------ A6: duplicate partition rows ---
_ts3c_case h-dup; printf '2002-count.sh\tsubject\ta second row for the same part\n2001-sum.sh\tsubject\tone of two rows, the other instrument\n' >> "$TS3CR/$TS3D_PT"
_ts3c_commit "$TS3CR" dup
_ts3d_check "ts3d: A6 (fixture control): the candidate's partition names 2001-sum.sh instrument then subject, and 2002-count.sh subject twice; P's once each" \
  "$(_ts3d_rows HEAD 2001-sum.sh)|$(_ts3d_rows HEAD 2002-count.sh)|$(_ts3d_rows "$TS3C_M" 2001-sum.sh)|$(_ts3d_rows "$TS3C_M" 2002-count.sh)" "instrument subject |subject subject |instrument |subject "
_ts3d_dry
_ts3d_check "ts3d: A6: duplicate rows that change no part's class are not refused: passed, no partition line, no escape line" \
  "$(_ts3d_passed)|$(_ts3d_bl escape "$TS3D_PT" - -)|escape $(_ts3d_esc)" "passed|no|escape no" "$(_ts3d_why)"

# --------------------------------------------- A7: failure and cleanup ---
perl -e 'sleep 20' "${TS3D_TOK}e" & TS3D_PID=$!; sleep 0.3; TS3D_C1="$(_ts3d_alive "${TS3D_TOK}e")"
kill "$TS3D_PID" 2>/dev/null; wait "$TS3D_PID" 2>/dev/null
_ts3d_check "ts3d: A7 (fixture control): ps lists this shell and a process carrying a token while it lives, and not after it is stopped" \
  "$(ps -A -o pid= 2>/dev/null | LC_ALL=C awk -v p="$$" '$1 == p { f = 1 } END { print (f ? "yes" : "no") }')|$TS3D_C1|$(_ts3d_hangs "${TS3D_TOK}e")" "yes|1|0"
_ts3d_hang h-hang "${TS3D_TOK}a"
_ts3d_check "ts3d: A7.2 (fixture control): the hanging candidate changes 2001-sum.sh and an add() that sleeps in a perl carrying its token" \
  "$(_ts3d_names "$TS3C_M" HEAD)|$(LC_ALL=C grep -c "perl -e \"sleep 20\" ${TS3D_TOK}a;" "$TS3CR/engine/widget/lib.sh")" "$TS3DT_/parts/2001-sum.sh engine/widget/lib.sh |1"
TS3D_ENV=FELIX_INSTRUMENT_UNIT_SECONDS=3; _ts3d_dry; TS3D_ENV=""
_ts3d_check "ts3d: A7.2, A7.3: a unit that never ends, under a limit lowered to 3 s, counts as not finished and refuses; no process of it is left, nor any run tree" \
  "$(_ts3d_refused)|$(_ts3d_bl escape 2001-sum.sh 'did not finish' -)|alive $(_ts3d_hangs "${TS3D_TOK}a")|left $(_ts3d_left)" "refused|yes|alive 0|left nothing" "$(_ts3d_why)"

_ts3c_case h-chang; _ts3d_drv "$(_ts3c_honest_bad)" "$(_ts3c_honest_is)" "[ \"\${1:-}\" != --part ] || perl -e \"sleep 20\" ${TS3D_TOK}b"
_ts3c_commit "$TS3CR" chang
_ts3d_check "ts3d: A7.2 (fixture control): the candidate's driver differs from P's by one line, which sleeps in part mode in a perl carrying its token" \
  "$(_ts3d_diff "$TS3C_M" HEAD "$TS3DT_/run")" "+[ \"\${1:-}\" != --part ] || perl -e \"sleep 20\" ${TS3D_TOK}b|"
TS3D_ENV=FELIX_INSTRUMENT_CANARY_SECONDS=3; _ts3d_dry; TS3D_ENV=""
_ts3d_check "ts3d: A7.2: a canary that never ends under the candidate's driver, under a limit lowered to 3 s, refuses for the machinery; no process of it is left" \
  "$(_ts3d_refused)|$(_ts3d_bl escape machinery canary -)|alive $(_ts3d_hangs "${TS3D_TOK}b")|left $(_ts3d_left)" "refused|yes|alive 0|left nothing" "$(_ts3d_why)"

_ts3c_case h-where; printf '%s\n' '_ts3d_w() { { printf "pwd %s\n" "$PWD"; _a="$(git rev-parse --path-format=absolute --git-path objects/info/alternates 2>/dev/null)" && [ -f "$_a" ] && sed "s/^/alt /" "$_a"; printf "top %s\n" "$(git rev-parse --show-toplevel 2>/dev/null)"; } >> "'"$TS3C/where"'"; }' >> "$TS3CR/engine/widget/lib.sh"
_ts3d_sed engine/widget/lib.sh 's/^add() {/add() { _ts3d_w;/'; printf '# where it runs\n' >> "$TS3CR/$TS3DT_/parts/2001-sum.sh"; _ts3c_commit "$TS3CR" where
_ts3d_where() { LC_ALL=C awk -v p="$1" '$1 == "pwd" { n++; if (index($2, p) == 1) in_ = 1 } END { printf "ran %s|under %s", (n ? "yes" : "no"), (in_ ? "yes" : "no") }' "$TS3C/where" 2>/dev/null; }   # PREFIX
: > "$TS3C/where.all"
TS3D_ENV=FELIX_INSTRUMENT_UNIT_SECONDS=99999; _ts3d_dry; TS3D_ENV=""; cat "$TS3C/where" >> "$TS3C/where.all"
_ts3d_check "ts3d: A7.5: with an absolute TMPDIR outside the checkout, P's unit runs in a tree under it, and passes" \
  "$(_ts3d_passed)|$(_ts3d_where "$TS3CT/")|left $(_ts3d_left)" "passed|ran yes|under yes|left nothing" "where [$(tr '\n' ' ' < "$TS3C/where")]; $(_ts3d_why)"
_ts3d_check "ts3d: A7.2: FELIX_INSTRUMENT_UNIT_SECONDS set to 99999 is not the limit the merge reports (read only if it says one)" \
  "$(cat "$TS3C/out" "$TS3C/err" | LC_ALL=C awk '/(^|[^0-9a-f])99999([^0-9a-f]|$)/ { f = 1 } END { print (f ? "yes" : "no") }')" "no" "$(_ts3d_why)"
TS3D_TMP=tmprel; _ts3d_dry; TS3D_TMP=""; cat "$TS3C/where" >> "$TS3C/where.all"
_ts3d_check "ts3d: A7.5: with a relative TMPDIR, felix merge leaves nothing in the checkout: no tmprel made there, and the checkout's status as it was" \
  "made $([ -e "$TS3CR/tmprel" ] && echo yes || echo no)|status $([ "$(_ts3d_status)" = "$TS3D_ST" ] && echo same || _ts3d_status | tr '\n' ' ')" "made no|status same" "$(_ts3d_why)"
_ts3d_check "ts3d: A7.5: with a relative TMPDIR, P's unit still runs, in a tree outside the checkout, and the judgement passes" \
  "$(_ts3d_passed)|$(_ts3d_where "$TS3CR/")" "passed|ran yes|under no" "where [$(tr '\n' ' ' < "$TS3C/where")]; $(_ts3d_why)"
rm -rf "${TS3CR:?}/tmprel"; mkdir -p "$TS3CR/inside"
TS3D_TMP="$TS3CR/inside"; _ts3d_dry; TS3D_TMP=""; cat "$TS3C/where" >> "$TS3C/where.all"
_ts3d_check "ts3d: A7.5: with TMPDIR inside the checkout, felix merge leaves nothing there, and the checkout's status as it was" \
  "inside [$(find "$TS3CR/inside" -mindepth 1 -maxdepth 1 2>/dev/null | tr '\n' ' ')]|status $([ "$(_ts3d_status)" = "$TS3D_ST" ] && echo same || _ts3d_status | tr '\n' ' ')" "inside []|status same" "$(_ts3d_why)"
_ts3d_check "ts3d: A7.5: with TMPDIR inside the checkout, P's unit runs in a tree outside the checkout, and the judgement passes" \
  "$(_ts3d_passed)|$(_ts3d_where "$TS3CR/")" "passed|ran yes|under no" "where [$(tr '\n' ' ' < "$TS3C/where")]; $(_ts3d_why)"
rm -rf "${TS3CR:?}/inside"
_ts3d_check "ts3d: A7.6: T's alternates, wherever a unit found them, name neither the checkout's objects nor a felix-objects directory" \
  "$(LC_ALL=C awk '$1 == "alt" && (index($0, "ts3d/repo/.git") || index($0, "felix-objects")) { printf "%s|", $0 }' "$TS3C/where.all")" "" \
  "seen [$(LC_ALL=C awk '$1 != "pwd"' "$TS3C/where.all" | LC_ALL=C sort -u | tr '\n' ' ')]"

_ts3d_kill() {   # SIGNAL: a dry run of the candidate checked out, sent SIGNAL once P's 2001-sum.sh has started in T
  local i=0; _ts3d_prep; ( _ts3d_go --dry-run ) > "$TS3C/out" 2> "$TS3C/err" & TS3D_PID=$!
  while [ "$i" -lt 600 ] && kill -0 "$TS3D_PID" 2>/dev/null && ! LC_ALL=C grep -qx 2001-sum.sh "$TS3C/trace"; do sleep 0.1; i=$((i + 1)); done
  TS3D_MID=no; LC_ALL=C grep -qx 2001-sum.sh "$TS3C/trace" && kill -0 "$TS3D_PID" 2>/dev/null && TS3D_MID=yes
  sleep 0.5; kill -"$1" "$TS3D_PID" 2>/dev/null; wait "$TS3D_PID" 2>/dev/null; TS3CRC=$?
  i=0; while [ "$i" -lt 100 ] && [ "$(_ts3d_left)" != nothing ]; do sleep 0.1; i=$((i + 1)); done
}
for _ts3d_sig in TERM:c INT:d; do
  _ts3d_hang "h-sig-${_ts3d_sig%%:*}" "${TS3D_TOK}${_ts3d_sig#*:}"; _ts3d_kill "${_ts3d_sig%%:*}"
  _ts3d_check "ts3d: A7.3, A7.4: a ${_ts3d_sig%%:*} signal sent to felix merge while P's unit runs leaves no run tree under TMPDIR, no process of the unit, and the checkout's status as it was" \
    "killed mid-run $TS3D_MID|alive $(_ts3d_hangs "${TS3D_TOK}${_ts3d_sig#*:}")|left $(_ts3d_left)" "killed mid-run yes|alive 0|left nothing" "$(_ts3d_why)"
done

# -------------------------------------- A1: what the squash lands is judged ---
TS3D_M1="$TS3C_M"
_ts3c_case h-docs "$TS3D_M1"; mkdir -p "$TS3CR/docs"; printf '# a note no part reads\n' > "$TS3CR/docs/note.md"; _ts3c_commit "$TS3CR" docs; TS3D_HD="$(_jr_sha "$TS3CR" HEAD)"
_ts3c_case h-behind "$TS3D_M1"; _ts3d_loosen_mul; _ts3c_commit "$TS3CR" behind; TS3D_HL="$(_jr_sha "$TS3CR" HEAD)"
_ts3c_case h-conflict "$TS3D_M1"; printf 'hello there\n' > "$TS3CR/engine/widget/greet.txt"; _ts3d_sed "$TS3DT_/parts/2003-grp-a.sh" 's/" hello$/" hel/'
_ts3c_commit "$TS3CR" conflict; TS3D_HX="$(_jr_sha "$TS3CR" HEAD)"
_ts3c_on main; printf 'hello world, and welcome\n' > "$TS3CR/engine/widget/greet.txt"
_ts3c_part 2003-grp-a.sh 'has "grp-a: the greeting says hello" "$(cat "$W/greet.txt")" hello
has "grp-a: the greeting welcomes" "$(cat "$W/greet.txt")" welcome'
_ts3d_sed "$TS3D_PT" 's/^2002-count.sh	subject	/2002-count.sh	instrument	/'; _ts3d_mani 'grp-a: the greeting welcomes'
_ts3c_commit "$TS3CR" tighten; TS3C_M="$(_jr_sha "$TS3CR" HEAD)"; _ts3d_main "$TS3C_M"
_ts3d_check "ts3d: A1 (fixture control): main's last landing tightened 2003-grp-a.sh with the greeting it checks, and moved 2002-count.sh from subject to instrument" \
  "$(_ts3d_names "$TS3D_M1" "$TS3C_M")|$(_ts3d_rows "$TS3D_M1" 2002-count.sh)$(_ts3d_rows "$TS3C_M" 2002-count.sh)|$(_ts3d_direct "$TS3C_M" "$TS3C_M" 2003-grp-a.sh | _ts3d_fails)" \
  "$TS3DT_/assertions.tsv $TS3DT_/parts/2003-grp-a.sh engine/widget/greet.txt $TS3D_PT |subject instrument |"
_ts3d_check "ts3d: A1 (fixture control): the docs candidate was cut before that landing and changes docs/note.md alone, and P's 2003 fails on its own tree" \
  "$(_fx_git "$TS3CR" merge-base "$TS3D_HD" "$TS3C_M" 2>/dev/null)|$(_ts3d_names "$TS3D_M1" "$TS3D_HD")|$(_ts3d_direct "$TS3D_HD" "$TS3C_M" 2003-grp-a.sh | _ts3d_fails)" \
  "$TS3D_M1|docs/note.md |grp-a: the greeting welcomes|"
_ts3c_on h-docs; _ts3d_dry
_ts3d_check "ts3d: A1: a candidate cut before main's last landing that changes only a docs file is judged as the squash lands it: passed, no escape line, no unit run" \
  "$(_ts3d_passed)|escape $(_ts3d_esc)|ran [$(_ts3d_ran)]" "passed|escape no|ran []" "$(_ts3d_why)"
_ts3c_on h-behind; _ts3d_dry
_ts3d_check "ts3d: A1: a candidate behind main that loosens a part main did not touch is refused for that part only, P's version failing on its assertion" \
  "$(_ts3d_refused)|$(_ts3d_subj)|$(_ts3d_bl escape 2005-mul.sh "P's version fails on this tree" 'mul: mul 2 3 is 6')" "refused|escape:2005-mul.sh |yes" "$(_ts3d_why)"
_ts3d_check "ts3d: A1, S9: that judgement ran P's unit holding 2005-mul.sh, and only it" "ran [$(_ts3d_ran)]" "ran [2005-mul.sh ]" "$(_ts3d_why)"
_ts3d_check "ts3d: A1 (fixture control): the conflicting candidate, cut before main's last landing, does not merge onto main" \
  "$(_fx_git "$TS3CR" merge-tree --write-tree "$TS3C_M" "$TS3D_HX" >/dev/null 2>&1; echo "$?")" "1"
_ts3c_on h-conflict; _ts3d_dry
_ts3d_check "ts3d: A1: a candidate whose merge onto main conflicts is refused with a blocker of kind unknown, subject SUITE" \
  "$(_ts3d_refused)|$(_ts3d_bl unknown SUITE - -)" "refused|yes" "$(_ts3d_why)"

# --------------------------------- A6: duplicate rows in P's own partition ---
_ts3c_on main; printf '2005-mul.sh\tinstrument\tone of two rows for mul\n2005-mul.sh\tsubject\tthe other, and the last, says subject\n' >> "$TS3CR/$TS3D_PT"
_ts3c_commit "$TS3CR" duplicate; TS3C_M="$(_jr_sha "$TS3CR" HEAD)"; _ts3d_main "$TS3C_M"
_ts3c_case h-dupl; _ts3d_loosen_mul; _ts3c_commit "$TS3CR" dupl
_ts3d_check "ts3d: A6 (fixture control): P's partition names 2005-mul.sh instrument, then subject last, and P's 2005 fails on the loosened candidate's tree" \
  "$(_ts3d_rows "$TS3C_M" 2005-mul.sh)|$(_ts3d_direct HEAD "$TS3C_M" 2005-mul.sh | _ts3d_fails)|$(_ts3d_names "$TS3C_M" HEAD)" \
  "instrument subject |mul: mul 2 3 is 6||$TS3DT_/parts/2005-mul.sh engine/widget/lib.sh "
_ts3d_dry
_ts3d_check "ts3d: A6: a part one of whose duplicate rows says subject stays instrument: its loosened guard is refused, P's version failing on its assertion" \
  "$(_ts3d_refused)|$(_ts3d_bl escape 2005-mul.sh "P's version fails on this tree" 'mul: mul 2 3 is 6')" "refused|yes" "$(_ts3d_why)"

_ts3c_on main
rm -rf "${TS3C:?}"; [ "$TS3D_MEM" != made ] || rm -rf "${MEM:?}/felix"
unset TS3C TS3CR TS3CK TS3CT TS3CPP TS3D_PROBE TS3D_HLOG TS3D_PID TS3D_MID TS3D_MEM TS3D_ENV TS3D_TMP TS3D_KN TS3D_KT TS3D_K0 TS3D_L1
# <<< trust-step3-instrument-parts-b
