# >>> judge-refs-residue
printf '\njudge refs and residue: the base ref by its full name (contract A1-A11, blind)\n'
# Blind, from docs/2026-10-18-judge-refs-residue-contract.md alone, as amended
# by c933e688 (A1-A4 look up exact names). Not read: lib/resolve.sh,
# lib/exceptions.sh, the merge body of the felix CLI, and the installed block
# of projects/felix/gate.sh. How to drive them was learned from the parts that
# already do: 0110 and 1284 for felix_base_ref, 0340 for felix_kernel_dir and
# the self-governed merge, 0440 for the gate's installed check. A7 reads
# lib/resolve.sh only mechanically: awk cuts each definition out and each is
# run on its own. Every fixture is this part's own, under $TMP, and a project
# of its own, jrr, binds the checkouts the CLI is run in; it removes them at its end.
#
# A decoy is a ref at another commit than the one meant, under a name git's
# short-name order reads first: refs/<x>, refs/tags/<x>, refs/heads/<x>, then
# refs/remotes/<x>. "|0" after an output is exit 0, "|X" any other exit.
JR="$TMP/jr"; mkdir -p "$JR"
_jr_all() { local r="$1" s="$2" f o=""; shift 2; for f in "$@"; do [ "$(_jr_sha "$r" "$f")" = "$s" ] || o="$o $f"; done; printf '%s' "$o"; }   # the refs not at the commit

# The project the fixtures bind, made as 0004 makes the widget, so the merge
# boundary measures the judge and not an empty ledger or a stale stamp.
_jr_project

# ----------------------------------------------------------- the base ref ---
# ar: c1 <- c2 (main, checked out) <- r (refs/remotes/origin/main), and d off
# c1, the decoy. origin/HEAD names origin/main, as in every clone. v1 tags c1,
# jr-tree a tree. a3 has no remote: main, feat off it, and its own decoy.
JAR="$JR/ar"; JA3="$JR/a3"; mkdir -p "$JAR" "$JA3"; JAR="$(cd "$JAR" && pwd -P)"; JA3="$(cd "$JA3" && pwd -P)"
for _jr_r in "$JAR" "$JA3"; do ( _fx_cd "$_jr_r" && git init -q -b main ) >/dev/null 2>&1; done
_jr_commit "$JAR" one a.txt; JA_C1="$(_jr_sha "$JAR" HEAD)"
_jr_commit "$JAR" two b.txt; JA_C2="$(_jr_sha "$JAR" HEAD)"
JA_R="$(_jr_side "$JAR" "$JA_C2" remote r.txt)"; JA_D="$(_jr_side "$JAR" "$JA_C1" decoy d.txt)"
_jr_on "$JAR" "$JA_R" refs/remotes/origin/main
_fx_git "$JAR" symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/main >/dev/null 2>&1
_fx_git "$JAR" tag v1 "$JA_C1" >/dev/null 2>&1
_fx_git "$JAR" tag jr-tree "$(git -C "$JAR" rev-parse 'HEAD^{tree}' 2>/dev/null)" >/dev/null 2>&1
_jr_commit "$JA3" one a.txt; _jr_commit "$JA3" two b.txt; JA3_M="$(_jr_sha "$JA3" HEAD)"
JA3_F="$(_jr_side "$JA3" "$JA3_M" feat f.txt)"; _jr_on "$JA3" "$JA3_F" refs/heads/feat
JA3_D="$(_jr_side "$JA3" "$(_jr_sha "$JA3" HEAD~1)" decoy d.txt)"
is "A1-A7 (fixture control): the base-ref fixture: main, refs/remotes/origin/main and the decoy are three commits, origin/HEAD names origin/main, and HEAD~1 is not origin/HEAD~1" \
   "$(_jr_sha "$JAR" refs/heads/main)|$(_jr_sha "$JAR" refs/remotes/origin/main)|$(git -C "$JAR" symbolic-ref refs/remotes/origin/HEAD 2>&1)|$(_jr_sha "$JAR" HEAD~1)|$(_jr_sha "$JAR" origin/HEAD~1)|$([ -n "$JA_D" ] && [ "$JA_D" != "$JA_R" ] && [ "$JA_D" != "$JA_C2" ] && echo distinct)" \
   "$JA_C2|$JA_R|refs/remotes/origin/main|$JA_C1|$JA_C2|distinct"
is "A1-A7 (fixture control): the base-ref fixture: in the repository with no remote, main, feat and its decoy are three commits" \
   "$(_jr_sha "$JA3" refs/heads/main)|$(_jr_sha "$JA3" refs/heads/feat)|$([ -n "$JA3_D" ] && [ "$JA3_D" != "$JA3_F" ] && [ "$JA3_D" != "$JA3_M" ] && echo distinct)|$(git -C "$JA3" for-each-ref refs/remotes 2>&1)" \
   "$JA3_M|$JA3_F|distinct|"

_ja_libs() {   # -> the libraries felix sources at its top level, in its order, as harness-relative paths
  LC_ALL=C awk '/^\. "\$\{SCRIPT_DIR\}\/lib\/[A-Za-z0-9_.-]+\.sh"$/ { s = $0; sub(/^\. "\$\{SCRIPT_DIR\}\//, "", s); sub(/"$/, "", s); print s }' "$REAL_HARNESS/felix"
}
_ja_br() {   # ROOT NAME -> felix_base_ref's stdout, then |0 or |X; JA_DEF loads one definition after the library, JA_LOAD=felix loads felix's libraries
  ( if [ "${JA_LOAD:-}" = felix ]; then
      SCRIPT_DIR="$REAL_HARNESS"; FELIX_ROOT="$(cd "$REAL_HARNESS/.." && pwd)"
      for _l in $(_ja_libs); do . "$REAL_HARNESS/$_l" >/dev/null 2>&1; done
    else . "$REAL_HARNESS/lib/resolve.sh" >/dev/null 2>&1; fi
    [ -z "${JA_DEF:-}" ] || . "$JA_DEF" >/dev/null 2>&1
    _o="$(felix_base_ref "$1" "$2" 2>/dev/null)"; _r=$?
    if [ "$_r" -eq 0 ]; then printf '%s|0' "$_o"; else printf '%s|X' "$_o"; fi )
}
_ja_cm() { case "$2" in *"|0") _jr_sha "$1" "${2%|0}" ;; esac; }   # REPO OUT -> the commit OUT's ref names
_ja_show() {   # TEXT EMPTY-WORD -> TEXT for an assertion name: a sha, which changes from run to run, as "its sha"
  case "$1" in "") printf '%s' "$2" ;; *[!0-9a-f]*) printf '%s' "$1" ;; *) [ "${#1}" -ge 40 ] && printf 'its sha' || printf '%s' "$1" ;; esac
}
_ja_case() {   # ITEM REPO NAME WANT-REF WANT-COMMIT DECOY-SHA LABEL REF...: the decoys on, two assertions, the decoys off
  local it="$1" r="$2" n="$3" w="$4" c="$5" s="$6" l="$7" o says; shift 7
  _jr_on "$r" "$s" "$@"
  [ "$#" -eq 0 ] || is "$it ($l) (fixture control): each decoy names the decoy commit" "$(_jr_all "$r" "$s" "$@")" ""
  o="$(_ja_br "$r" "$n")"
  if [ -n "$w" ]; then says="exactly $(_ja_show "$w") and exits 0"; else says="nothing and exits non-zero"; fi
  is "$it ($l): felix_base_ref given $(_ja_show "$n" 'an empty name') prints $says" "$o" "$w|$([ -n "$w" ] && echo 0 || echo X)"
  [ -z "$w" ] || is "$it ($l): and what it prints names the commit $(_ja_show "$w") names" "$(_ja_cm "$r" "$o")" "$c"
  _jr_off "$r" "$@"
}
JA_A1="refs/tags/origin/main refs/heads/origin/main refs/origin/main refs/tags/main refs/main refs/remotes/main"
for _ja_k in none $JA_A1 all; do
  case "$_ja_k" in none) _ja_rs="" ;; all) _ja_rs="$JA_A1" ;; *) _ja_rs="$_ja_k" ;; esac
  _ja_case A1 "$JAR" main refs/remotes/origin/main "$JA_R" "$JA_D" "decoys: ${_ja_k}" $_ja_rs
done
JA_A2="refs/tags/origin/main refs/heads/origin/main refs/origin/main refs/remotes/origin/origin/main"
for _ja_k in none $JA_A2 all; do
  case "$_ja_k" in none) _ja_rs="" ;; all) _ja_rs="$JA_A2" ;; *) _ja_rs="$_ja_k" ;; esac
  _ja_case A2 "$JAR" origin/main refs/remotes/origin/main "$JA_R" "$JA_D" "decoys: ${_ja_k}" $_ja_rs
done
JA_A2G="refs/tags/origin/jr-gone refs/heads/origin/jr-gone refs/origin/jr-gone refs/remotes/origin/origin/jr-gone"
for _ja_k in none $JA_A2G all; do
  case "$_ja_k" in none) _ja_rs="" ;; all) _ja_rs="$JA_A2G" ;; *) _ja_rs="$_ja_k" ;; esac
  _ja_case A2 "$JAR" origin/jr-gone "" "" "$JA_D" "no refs/remotes/origin/jr-gone, decoys: ${_ja_k}" $_ja_rs
done
JA_A3="refs/tags/feat refs/feat refs/remotes/feat"
for _ja_k in none $JA_A3 all; do
  case "$_ja_k" in none) _ja_rs="" ;; all) _ja_rs="$JA_A3" ;; *) _ja_rs="$_ja_k" ;; esac
  _ja_case A3 "$JA3" feat refs/heads/feat "$JA3_F" "$JA3_D" "decoys: ${_ja_k}" $_ja_rs
done
_ja_case A3 "$JA3" main refs/heads/main "$JA3_M" "$JA3_D" "decoys: refs/remotes/main" refs/remotes/main
_ja_case A4 "$JAR" "$JA_C2" "$JA_C2" "$JA_C2" "$JA_D" "a commit by its sha"
_ja_case A4 "$JAR" HEAD~1 HEAD~1 "$JA_C1" "$JA_D" "a revision suffix, with refs/remotes/origin/HEAD present"
_ja_case A4 "$JAR" main~1 main~1 "$JA_C1" "$JA_D" "a branch with a revision suffix, with refs/remotes/origin/main present"
_ja_case A4 "$JAR" v1 v1 "$JA_C1" "$JA_D" "a tag by its name"
_ja_case A4 "$JAR" jr-nope "" "" "$JA_D" "a name that resolves nowhere"
_ja_case A4 "$JAR" "$(git -C "$JAR" rev-parse 'HEAD^{tree}' 2>/dev/null)" "" "" "$JA_D" "a tree by its sha"
_ja_case A5 "$JAR" refs/heads/main refs/heads/main "$JA_C2" "$JA_D" "refs/heads/main"
_ja_case A5 "$JAR" refs/remotes/origin/main refs/remotes/origin/main "$JA_R" "$JA_D" "every decoy for origin/main in place" \
  refs/tags/origin/main refs/heads/origin/main refs/origin/main refs/remotes/origin/origin/main
_ja_case A5 "$JAR" refs/heads/jr-absent "" "" "$JA_D" "a refs/ name that names nothing, origin/refs/heads/jr-absent there" \
  refs/tags/origin/refs/heads/jr-absent refs/heads/origin/refs/heads/jr-absent
_ja_case A5 "$JAR" refs/tags/jr-tree "" "" "$JA_D" "a refs/ name that names a tree"
_ja_case A6 "$JAR" "" refs/remotes/origin/main "$JA_R" "$JA_D" "with refs/remotes/origin/main"
_ja_case A6 "$JA3" "" refs/heads/main "$JA3_M" "$JA3_D" "with a local main only"
is "A6: an empty ROOT, called from inside a repository that has refs/remotes/origin/main, exits non-zero and prints nothing" \
   "$( ( _fx_cd "$JAR" && _ja_br "" main ) 2>/dev/null )" "|X"
is "A6: and so it does from inside a repository with a local main only" "$( ( _fx_cd "$JA3" && _ja_br "" main ) 2>/dev/null )" "|X"

# A7. Each definition is cut out of the file by awk and loaded after the whole
# library, so it is the one that answers; then the library as felix loads it.
# The cases are A1-A6's, with every decoy above in place at once.
JA7="$JR/a7"; mkdir -p "$JA7"; : > "$JA7/list"; _ja7_n=0; _ja7_bad=""
for _ja7_f in "$REAL_HARNESS/felix" "$REAL_HARNESS"/lib/*.sh "$REAL_HARNESS"/bin/* "$REAL_HARNESS"/hooks/*; do
  [ -f "$_ja7_f" ] || continue
  _ja7_c="$(LC_ALL=C awk '/^felix_base_ref[ \t]*\(\)[ \t]*\{/ { n++ } END { print n + 0 }' "$_ja7_f")"
  _ja7_i=1
  while [ "$_ja7_i" -le "${_ja7_c:-0}" ]; do
    _ja7_n=$((_ja7_n + 1))
    LC_ALL=C awk -v want="$_ja7_i" '
      !on && /^felix_base_ref[ \t]*\(\)[ \t]*\{/ { n++; if (n == want) { on = 1; print; if ($0 ~ /\}[ \t]*$/) exit; next } }
      on { print } on && /^\}/ { exit }' "$_ja7_f" > "$JA7/def.$_ja7_n"
    bash -n "$JA7/def.$_ja7_n" 2>/dev/null || _ja7_bad="$_ja7_bad def.$_ja7_n"
    printf '%s\n' "$JA7/def.$_ja7_n" >> "$JA7/list"; _ja7_i=$((_ja7_i + 1))
  done
done
is "A7 (fixture control): at least one felix_base_ref definition was found under engine/harness, and each one cut out parses on its own" \
   "$([ "$_ja7_n" -ge 1 ] && echo found)|$_ja7_bad" "found|"
is "A7 (fixture control): loading the libraries felix sources at its top level, in its order, includes lib/resolve.sh and defines felix_base_ref" \
   "$(_ja_libs | LC_ALL=C grep -cx 'lib/resolve.sh')|$( ( SCRIPT_DIR="$REAL_HARNESS"; FELIX_ROOT="$(cd "$REAL_HARNESS/.." && pwd)"
       for _l in $(_ja_libs); do . "$REAL_HARNESS/$_l" >/dev/null 2>&1; done; type -t felix_base_ref ) 2>/dev/null )" "1|function"
cat > "$JA7/cases" <<JA7CASES
A1;ar;main;refs/remotes/origin/main|0
A2;ar;origin/main;refs/remotes/origin/main|0
A2;ar;origin/jr-gone;|X
A3;a3;feat;refs/heads/feat|0
A3;a3;main;refs/heads/main|0
A4;ar;HEAD~1;HEAD~1|0
A4;ar;main~1;main~1|0
A4;ar;$JA_C2;$JA_C2|0
A4;ar;v1;v1|0
A4;ar;jr-nope;|X
A5;ar;refs/heads/main;refs/heads/main|0
A5;ar;refs/tags/jr-tree;|X
A6;ar;;refs/remotes/origin/main|0
A6;a3;;refs/heads/main|0
A6;cwd;main;|X
JA7CASES
_ja_battery() {   # -> one line for each case the felix_base_ref now loaded answers wrongly
  local it rp n w g
  while IFS=';' read -r it rp n w; do
    [ -n "$it" ] || continue
    case "$rp" in
      cwd) g="$( ( _fx_cd "$JAR" && _ja_br "" "$n" ) 2>/dev/null )" ;;
      a3)  g="$(_ja_br "$JA3" "$n")" ;;
      *)   g="$(_ja_br "$JAR" "$n")" ;;
    esac
    [ "$g" = "$w" ] || printf '%s %s %s: got [%s] want [%s]\n' "$JA7_SRC" "$it" "${n:-(empty)}" "$g" "$w"
  done < "$JA7/cases"
}
_jr_on "$JAR" "$JA_D" $JA_A1 refs/remotes/origin/origin/main $JA_A2G; _jr_on "$JA3" "$JA3_D" $JA_A3 refs/remotes/main
: > "$JA7/fails"; _ja7_k=0
while IFS= read -r JA_DEF; do
  _ja7_k=$((_ja7_k + 1)); JA7_SRC="definition-$_ja7_k"; _ja_battery >> "$JA7/fails"
done < "$JA7/list"
JA_DEF=""; JA_LOAD=felix; JA7_SRC="felix-load"; _ja_battery >> "$JA7/fails"; JA_LOAD=""
for _ja7_it in A1 A2 A3 A4 A5 A6; do
  is "A7: every felix_base_ref definition under engine/harness, each on its own, and the library as felix loads it, satisfy $_ja7_it" \
     "$(LC_ALL=C grep -F " $_ja7_it " "$JA7/fails" | tr '\n' ';')" ""
done
_jr_off "$JAR" $JA_A1 refs/remotes/origin/origin/main $JA_A2G; _jr_off "$JA3" $JA_A3 refs/remotes/main

# -------------------------------------------------------- felix_kernel_dir ---
# main declares 1.0.0; the decoy, a commit off it, declares 6.6.6; the cache
# holds both. 0340 drives felix_kernel_dir the same way.
JK="$JR/k"; JKC="$JR/kcache"; mkdir -p "$JK" "$JKC/1.0.0/harness/lib" "$JKC/6.6.6/harness/lib"; JK="$(cd "$JK" && pwd -P)"
( _fx_cd "$JK" && git init -q -b main ) >/dev/null 2>&1
printf 'x\n' > "$JKC/1.0.0/harness/lib/x.sh"; printf 'x\n' > "$JKC/6.6.6/harness/lib/x.sh"
mkdir -p "$JK/engine/harness/lib"; printf 'x\n' > "$JK/engine/harness/lib/x.sh"
_jr_commit "$JK" base engine/.claude-plugin/plugin.json '{ "name": "felix", "version": "1.0.0" }'
_jr_on "$JK" "$(_jr_sha "$JK" HEAD)" refs/remotes/origin/main
JK_D="$(_jr_side "$JK" HEAD decoy engine/.claude-plugin/plugin.json '{ "name": "felix", "version": "6.6.6" }')"
is "A8 (fixture control): refs/remotes/origin/main declares 1.0.0, the decoy 6.6.6, and the cache holds an entry for each" \
   "$(git -C "$JK" show refs/remotes/origin/main:engine/.claude-plugin/plugin.json 2>&1 | tr -d '\n')|$(git -C "$JK" show "$JK_D:engine/.claude-plugin/plugin.json" 2>&1 | tr -d '\n')|$(ls "$JKC" | tr '\n' ' ')" \
   '{ "name": "felix", "version": "1.0.0" }|{ "name": "felix", "version": "6.6.6" }|1.0.0 6.6.6 '
_jk_kd() { ( . "$REAL_HARNESS/lib/resolve.sh" >/dev/null 2>&1; FELIX_KERNEL_CACHE="$JKC" felix_kernel_dir "$JK" "$@" 2>/dev/null ); }
for _jk_k in none refs/tags/origin/main refs/heads/origin/main refs/origin/main; do
  _jk_rs="$_jk_k"; [ "$_jk_k" != none ] || _jk_rs=""
  _jr_on "$JK" "$JK_D" $_jk_rs
  is "A8 (decoys: $_jk_k): felix_kernel_dir given main prints the entry for the version refs/remotes/origin/main declares" "$(_jk_kd main)" "$JKC/1.0.0/harness"
  is "A8 (decoys: $_jk_k): and so does felix_kernel_dir given no name" "$(_jk_kd)" "$JKC/1.0.0/harness"
  _jr_off "$JK" $_jk_rs
done

# ----------------------------------------------- A11: a CLI reader, classify ---
# zero <- one (refs/remotes/origin/main, local main) <- work (feat, checked
# out). The decoy is zero, so read through it the branch would also own a.txt.
JC="$JR/c"; mkdir -p "$JC"; JC="$(cd "$JC" && pwd -P)"
( _fx_cd "$JC" && git init -q -b main ) >/dev/null 2>&1
_jr_commit "$JC" zero z.txt; JC_0="$(_jr_sha "$JC" HEAD)"; _jr_commit "$JC" one a.txt
_jr_on "$JC" "$(_jr_sha "$JC" HEAD)" refs/remotes/origin/main
( _fx_cd "$JC" && git checkout -q -b feat ) >/dev/null 2>&1; _jr_commit "$JC" work c.txt
printf 'jrr\n' > "$JC/.felix"
_jc_check() {   # NAME -> ok when felix classify --base main lists c.txt and not a.txt; the output is the detail
  local o c="" a=""
  o="$( cd "$JC" && "$FELIX" classify --base main 2>&1 )"
  case "$o" in *c.txt*) c=c ;; esac
  case "$o" in *a.txt*) a=a ;; esac
  if [ "$c|$a" = "c|" ]; then ok "$1"; else bad "$1" "expected [c|] got [$c|$a]: $(printf '%s\n' "$o" | head -12 | tr '\n' ' ')"; fi
}
for _jc_k in none refs/tags/origin/main refs/heads/origin/main; do
  _jc_rs="$_jc_k"; [ "$_jc_k" != none ] || _jc_rs=""
  _jr_on "$JC" "$JC_0" $_jc_rs
  [ -z "$_jc_rs" ] || is "A11 (decoys: $_jc_k) (fixture control): git's own short name origin/main now names the decoy" "$(_jr_sha "$JC" origin/main)" "$JC_0"
  _jc_check "A11 (decoys: $_jc_k): felix classify --base main lists the branch's own c.txt and not a.txt, which refs/remotes/origin/main holds"
  _jr_off "$JC" $_jc_rs
done

# ------------------------------------- A9: felix merge's judge (0340's shape) ---
# A self-governed checkout whose main is this tree's engine, on a prose branch
# off main, and a kernel cache whose entry for main's 1.0.0 is cut from main.
_js_build
is "A9 (fixture control): the decoy commit's resolve.sh defines a felix_accepted_deploy_diff that prints the entry and exits 0" \
   "$( ( git -C "$JSR" show "$JS_D:engine/harness/lib/resolve.sh" > "$JS/decoy.sh" 2>/dev/null; . "$JS/decoy.sh" >/dev/null 2>&1
        felix_accepted_deploy_diff "$JSR" main; printf '|%s' "$?" ) 2>/dev/null )" "$JSK/1.0.0
|0"
_js_entry; _js_dry
is "A9 (fixture control): with the cache entry main's engine and no decoy, the dry run passes the judge: it says the judge is byte-identical to main" \
   "$JSRC|$(LC_ALL=C grep -Fc 'byte-identical to main' "$JS/out")" "0|1"
printf '# one more line than main accepted\n' >> "$JSK/1.0.0/harness/lib/say.sh"; _js_dry
_js_refused "A9 (no decoy) (fixture control): with the cache entry one comment off main's engine, felix merge --dry-run refuses: the judge is not the engine main accepted"
for _js_k in refs/tags/origin/main refs/heads/origin/main; do
  _jr_on "$JSR" "$JS_D" "$_js_k"
  is "A9 ($_js_k at the decoy) (fixture control): git's own short name origin/main names the decoy" "$(_jr_sha "$JSR" origin/main)" "$JS_D"
  _js_dry
  _js_refused "A9 ($_js_k at the decoy): with the cache entry one comment off, felix merge --dry-run still refuses because the judge is not the engine main accepted"
  _jr_off "$JSR" "$_js_k"
done
_js_entry

# --------------------------------------- A10: the gate's installed check ---
# 0440's fixture: the gate cut at its tests marker, a claude stub naming the
# live entry, a home whose cache holds main's 0.0.1 cut from the commit.
_jg_build
[ "$JG_ON" = 1 ] && _jg_entry
_jg_check "A10 (fixture control): with the cache entry main's engine and no decoy, installed is ok" "ok|0"
[ "$JG_ON" = 1 ] && _jr_on "$JGT" "$JG_D" refs/tags/origin/main
_jg_check "A10 (refs/tags/origin/main at a decoy whose resolve.sh always accepts): with the cache entry main's engine, installed is ok, and nothing the decoy prints reaches it" "ok|0"
[ "$JG_ON" = 1 ] && { _jr_off "$JGT" refs/tags/origin/main; printf '# one more line than main accepted\n' >> "$JGC/0.0.1/harness/lib/say.sh"; }
_jg_check "A10 (no decoy) (fixture control): with the cache entry one comment off main's engine, installed fails" "FAIL|0"
for _jg_k in refs/tags/origin/main refs/heads/origin/main; do
  [ "$JG_ON" = 1 ] && _jr_on "$JGT" "$JG_D" "$_jg_k"
  _jg_check "A10 ($_jg_k at a decoy whose resolve.sh always accepts): with the cache entry one comment off, installed still fails, and nothing the decoy prints reaches it" "FAIL|0"
  [ "$JG_ON" = 1 ] && _jr_off "$JGT" "$_jg_k"
done
[ "$JG_ON" = 1 ] && _jg_entry

# ------------------------------- found after the blind round (not blind) ---
# Two things an automated security review of 2ce3a4b5 found, added here by the
# implementer from the coordinator's report; they are not derived from the
# contract alone and A12 was extended with the second. Each pair is red on
# 2ce3a4b5 and green on the fix.
#
# (1) git reads A-F as hex, so the upper-case spelling of a full sha is still an
# object name, and a branch planted under that spelling must not shadow it.
JA_U="$(printf '%s' "$JA_C2" | tr 'a-f' 'A-F')"
_jr_on "$JAR" "$JA_D" "refs/heads/$JA_U"
is "found after the blind round (not blind) (fixture control): git reads the upper-case spelling of main's sha as that commit, though a branch of that name exists at the decoy" \
   "$(_jr_sha "$JAR" "$JA_U")|$(_jr_sha "$JAR" "refs/heads/$JA_U")" "$JA_C2|$JA_D"
is "found after the blind round (not blind): felix_base_ref given the upper-case spelling of a sha prints it unchanged, and does not print the branch of that name" \
   "$(_ja_br "$JAR" "$JA_U")" "$JA_U|0"
_jr_off "$JAR" "refs/heads/$JA_U"
# (2) felix merge judges and merges against a full ref name or not at all. A
# base that felix_base_ref resolves only as given (A4) is refused, naming that.
_js_dryb() {   # BASE -> JSRC and $JS/out: felix merge --dry-run --base BASE in the checkout, a fresh receipt first
  _jr_record "$JSR"; : > "$JS/gh.log"
  ( cd "$JSR" && env -u FELIX_KERNEL PATH="$JS/gh:$PATH" GHSTUB_LOG="$JS/gh.log" FELIX_KERNEL_CACHE="$JSK" \
      "$FELIX" merge --dry-run --base "$1" ) > "$JS/out" 2>&1; JSRC=$?
}
_js_fullname() {   # NAME BASE -> ok when the dry run refused saying a full ref name is required
  local r="" j=""
  [ "$JSRC" -eq 0 ] || r=refused
  ! LC_ALL=C grep -Fq 'full ref name' "$JS/out" || j=says
  if [ "$r|$j" = "refused|says" ]; then ok "$1"; else bad "$1" "expected [refused|says] got [$r|$j], exit $JSRC: $(head -6 "$JS/out" | tr '\n' ' ')"; fi
}
_js_entry
_js_dryb main
is "found after the blind round (not blind) (fixture control): with --base main, which refs/remotes/origin/main carries, the dry run passes the judge" \
   "$JSRC|$(LC_ALL=C grep -Fc 'byte-identical to main' "$JS/out")" "0|1"
_js_dryb "$JS_M"
_js_fullname "found after the blind round (not blind): felix merge --dry-run --base <a sha> refuses, saying it judges and merges against a full ref name"
_fx_git "$JSR" tag jr-prose "$JS_D" >/dev/null 2>&1
_js_dryb jr-prose~1
_js_fullname "found after the blind round (not blind): felix merge --dry-run --base jr-prose~1, with a tag named jr-prose at a decoy, refuses, saying it judges and merges against a full ref name"
_fx_git "$JSR" tag -d jr-prose >/dev/null 2>&1
_js_entry

# This part's project and checkouts are taken away again; 1401 builds its own.
rm -rf "$FROOT/projects/jrr" "$MEM/jrr" "$JR" "$JS" "$JG"
