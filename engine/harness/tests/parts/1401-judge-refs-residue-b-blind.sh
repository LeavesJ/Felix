# >>> judge-refs-residue-b
printf '\njudge refs and residue: residue from the committed rules of main (contract B1-B10, blind)\n'
# Blind, from the same contract as part 1400, whose helpers (_jr_*) and merge
# and gate fixtures (JS, JG) this part uses, from tests/lib/judge-refs.sh,
# building its own (gate friction C); the same files were not read. The
# comparison is driven as 1282 and 1284 drive it: this tree's lib/resolve.sh,
# the plugins cache root in FELIX_PLUGIN_CACHE, and FELIX_KERNEL_CACHE unset.
#
# The home's main ships engine/{harness,hooks,commands}, keep.log force-added
# under *.log, and a file named out that the rule out/ names only as a
# directory. Its rules are the root's .gitignore and engine/harness/tests'
# (scratch/). E is the cache entry for main's 4.0.0, cut from the commit.
JB="$TMP/jr-b"; JBR="$JB/home"; JBC="$JB/cache"; JBV="$JBC/felix/felix"; JBE="$JBV/4.0.0"
mkdir -p "$JBR/engine/harness/lib" "$JBR/engine/harness/tests" "$JBR/engine/hooks" "$JBR/engine/commands" "$JBV"
JBR="$(cd "$JBR" && pwd -P)"
printf '.claude-flow/\n*.log\n.DS_Store\ndata/\n*.tmp\n!keep.tmp\nout/\n' > "$JBR/.gitignore"
printf 'real\n' > "$JBR/engine/harness/felix"; printf 'x\n' > "$JBR/engine/harness/lib/x.sh"
printf 'suite\n' > "$JBR/engine/harness/tests/run"; printf 'scratch/\n' > "$JBR/engine/harness/tests/.gitignore"
printf 'kept\n' > "$JBR/engine/harness/keep.log"; printf 'out\n' > "$JBR/engine/harness/out"
printf '{}\n' > "$JBR/engine/hooks/hooks.json"; printf '# felix\n' > "$JBR/engine/commands/felix.md"
( _fx_cd "$JBR" && git init -q -b main && git add -f engine/harness/keep.log ) >/dev/null 2>&1
_jr_commit "$JBR" main engine/.claude-plugin/plugin.json '{ "name": "felix", "version": "4.0.0" }'
JB_M="$(_jr_sha "$JBR" HEAD)"; _jr_on "$JBR" "$JB_M" refs/remotes/origin/main
is "B1-B4, B9 (fixture control): the residue fixture: main tracks keep.log, force-added under *.log, and out, which out/ names only as a directory" \
   "$(git -C "$JBR" ls-files engine/harness/keep.log engine/harness/out engine/harness/tests/.gitignore 2>&1 | tr '\n' ' ')|$(git -C "$JBR" status --porcelain 2>&1)" \
   "engine/harness/keep.log engine/harness/out engine/harness/tests/.gitignore |"
_jb_cut() {   # SHA DIR -> DIR holds the commit's engine/{harness,hooks,commands}, and nothing else
  rm -rf "$2" "$JB/x" "$JB/x.tar"; mkdir -p "$2" "$JB/x"
  _fx_git "$JBR" archive -o "$JB/x.tar" "$1" engine >/dev/null 2>&1 && tar -x -C "$JB/x" -f "$JB/x.tar"
  for _d in harness hooks commands .claude-plugin; do [ -d "$JB/x/engine/$_d" ] && cp -R "$JB/x/engine/$_d" "$2/$_d"; done
  rm -rf "$JB/x" "$JB/x.tar"
}
_jb_entry() { _jb_cut "$JB_M" "$JBE"; }
_jb_call() {   # [NAME] -> JBRC, and JBO felix_accepted_deploy_diff's stdout on the home; JB_HOME stands in for HOME
  ( unset FELIX_KERNEL_CACHE GIT_CONFIG_GLOBAL; export FELIX_PLUGIN_CACHE="$JBC"
    [ -z "${JB_HOME:-}" ] || export HOME="$JB_HOME" XDG_CONFIG_HOME="$JB_HOME/.config"
    . "$REAL_HARNESS/lib/resolve.sh" >/dev/null 2>&1
    felix_accepted_deploy_diff "$JBR" "${1:-main}" ) > "$JB/out" 2> "$JB/err" < /dev/null
  JBRC=$?; JBO="$(cat "$JB/out")"
}
_jb_names() {   # REL -> named when JBO names REL: its own path, or an Only in line for it or a directory above it
  local d="" r="$1" c
  case "$JBO" in *"$1"*) printf named; return 0 ;; esac
  while [ -n "$r" ]; do
    c="${r%%/*}"
    [ -z "$d" ] || case "$JBO" in *"$d: $c"*) printf named; return 0 ;; esac
    case "$r" in */*) r="${r#*/}"; d="${d:+$d/}$c" ;; *) r="" ;; esac
  done
}
_jb_isentry() {   # [DIR] -> entry when JBO is one line naming DIR (E by default), physically
  local p e
  case "$JBO" in ""|*$'\n'*) return 0 ;; esac
  p="$(cd -P "$JBO" 2>/dev/null && pwd -P)"; e="$(cd -P "${1:-$JBE}" 2>/dev/null && pwd -P)"
  [ -n "$p" ] && [ "$p" = "$e" ] && printf entry
}
_jb_plus() { _jb_entry; mkdir -p "$(dirname "$JBE/$1")"; printf 'only in the entry\n' > "$JBE/$1"; _jb_call; }   # REL: E is main plus REL
_jb_res()   { _jb_plus "$2"; is "$1: an entry that is main plus $2 exits 0, that line not printed" "$JBRC|$(_jb_names "$2")" "0|"; }
_jb_drift() { _jb_plus "$2"; is "$1: an entry that is main plus $2 exits 1 and names it" "$JBRC|$(_jb_names "$2")" "1|named"; }

# The variants of B1, each on its own. The fixture control for each shows git
# in the home now reads it: a path the entry alone will hold reads as ignored.
_jb_var() {   # VARIANT on|off
  case "$1:$2" in
    a:on) printf '*\n' > "$JBR/engine/.gitignore" ;;            a:off) rm -f "$JBR/engine/.gitignore" ;;
    b:on) printf '*\n' > "$JBR/engine/commands/.gitignore" ;;   b:off) rm -f "$JBR/engine/commands/.gitignore" ;;
    c:on) printf '*\n' > "$JBR/engine/harness/.gitignore" ;;    c:off) rm -f "$JBR/engine/harness/.gitignore" ;;
    d:on) printf '*\n' >> "$JBR/.gitignore" ;;                  d:off|h:off) _fx_git "$JBR" checkout -q -- .gitignore >/dev/null 2>&1 ;;
    e:on) cp "$JBR/.git/info/exclude" "$JB/exclude.keep" 2>/dev/null; printf '*\n' >> "$JBR/.git/info/exclude" ;;
    e:off) if [ -f "$JB/exclude.keep" ]; then cp "$JB/exclude.keep" "$JBR/.git/info/exclude"; else rm -f "$JBR/.git/info/exclude"; fi ;;
    f:on) ( _fx_cd "$JBR" && git checkout -q -b jr-side && printf '*\n' >> .gitignore \
            && git -c user.name=t -c user.email=t@t commit -qam side ) >/dev/null 2>&1 ;;
    f:off) ( _fx_cd "$JBR" && git checkout -q main && git branch -q -D jr-side ) >/dev/null 2>&1 ;;
    g:on) printf '*\n' > "$JB/star"; _fx_git "$JBR" config core.excludesFile "$JB/star" >/dev/null 2>&1 ;;
    g:off) _fx_git "$JBR" config --unset core.excludesFile >/dev/null 2>&1 ;;
    h:on) rm -f "$JBR/.gitignore" ;;
  esac
}
_jb_ign() { git -C "$JBR" check-ignore -q --no-index "$1" 2>/dev/null && printf ignored; }   # PATH -> ignored when git there says so
for _jb_v in none a b c d e f g h; do
  _jb_l="$_jb_v"; [ "$_jb_v" != none ] || _jb_l="no variant"
  _jb_var "$_jb_v" on
  case "$_jb_v" in
    none) ;;
    b) is "B1 ($_jb_l) (fixture control): git in the home now ignores engine/commands/jr-x" "$(_jb_ign engine/commands/jr-x)" ignored ;;
    c) is "B1 ($_jb_l) (fixture control): git in the home now ignores engine/harness/jr-x" "$(_jb_ign engine/harness/jr-x)" ignored ;;
    f) is "B1 ($_jb_l) (fixture control): the home is on a branch whose .gitignore ignores engine/hooks/jr-x" \
          "$(git -C "$JBR" symbolic-ref --short HEAD 2>&1)|$(_jb_ign engine/hooks/jr-x)" "jr-side|ignored" ;;
    h) is "B1 ($_jb_l) (fixture control): the root .gitignore is gone from the working tree, and git there ignores nothing of main's" \
          "$([ -e "$JBR/.gitignore" ] && echo there)|$(_jb_ign engine/harness/tests/x.log)" "|" ;;
    *) is "B1 ($_jb_l) (fixture control): git in the home now ignores engine/hooks/jr-x" "$(_jb_ign engine/hooks/jr-x)" ignored ;;
  esac
  for _jb_d in harness hooks commands; do
    _jb_plus "$_jb_d/jr-extra.txt"
    is "B1 ($_jb_l): an entry that is main plus one extra file under $_jb_d/ exits 1, and the line names that file" \
       "$JBRC|$(_jb_names "$_jb_d/jr-extra.txt")" "1|named"
  done
  _jb_entry; _jb_call
  is "B1 ($_jb_l): an entry equal to main exits 0 and prints the entry" "$JBRC|$(_jb_isentry)" "0|entry"
  if [ "$_jb_v" = h ]; then
    _jb_res "B3 (root .gitignore deleted from the working tree)" harness/tests/x.log
    _jb_res "B3 (root .gitignore deleted from the working tree)" harness/tests/.claude-flow/x.json
  else
    _jb_entry; printf 'drift\n' >> "$JBE/harness/keep.log"; _jb_call
    is "B2 ($_jb_l): an entry whose harness/keep.log, which main force-added under *.log, differs exits 1 and names it" \
       "$JBRC|$(_jb_names harness/keep.log)" "1|named"
    _jb_entry; printf 'drift\n' >> "$JBE/harness/lib/x.sh"; _jb_call
    is "B2 ($_jb_l): an entry whose harness/lib/x.sh differs from main exits 1 and names it" "$JBRC|$(_jb_names harness/lib/x.sh)" "1|named"
    _jb_entry; rm -f "$JBE/harness/lib/x.sh"; _jb_call
    is "B2 ($_jb_l): an entry that lacks harness/lib/x.sh, which main ships, exits 1 and names it" "$JBRC|$(_jb_names harness/lib/x.sh)" "1|named"
  fi
  _jb_var "$_jb_v" off
done
_jb_entry; rm -f "$JBE/harness/keep.log"; _jb_call
is "B2: an entry that lacks harness/keep.log, which main force-added under *.log, exits 1 and names it" "$JBRC|$(_jb_names harness/keep.log)" "1|named"
is "B1-B4, B9 (fixture control): the residue fixture: every variant is undone, and the home is on main with nothing to report" \
   "$(git -C "$JBR" symbolic-ref --short HEAD 2>&1)|$(git -C "$JBR" status --porcelain --ignored 2>&1)|$(git -C "$JBR" config --local --get core.excludesFile 2>&1)" "main||"

# ------------------------------------------------------------------- B3 ---
_jb_res "B3 (control)" harness/tests/.claude-flow/x.json
_jb_res "B3 (control)" harness/tests/x.log
_jb_res "B3 (control), the nested rule" harness/tests/scratch/y
_jb_res "B3 (control), the negation" harness/other.tmp
_jb_drift "B3 (control), the negation" harness/keep.tmp
_jb_drift "B3 (control)" harness/jr-unmatched.sh
rm -f "$JBR/engine/harness/tests/.gitignore"
is "B3 (nested rule deleted from the working tree) (fixture control): git in the home no longer ignores engine/harness/tests/scratch/y" \
   "$(_jb_ign engine/harness/tests/scratch/y)" ""
_jb_res "B3 (nested rule deleted from the working tree)" harness/tests/scratch/y
printf 'scratch/\n!*.log\n' > "$JBR/engine/harness/tests/.gitignore"
is "B3 (nested rule negated in the working tree) (fixture control): git in the home no longer ignores engine/harness/tests/x.log" \
   "$(_jb_ign engine/harness/tests/x.log)" ""
_jb_res "B3 (nested rule negated in the working tree)" harness/tests/x.log
_fx_git "$JBR" checkout -q -- engine/harness/tests/.gitignore >/dev/null 2>&1
# engine/'s own .gitignore, held by a commit off main (jr-rules, still 4.0.0)
# and not by the working tree, which stays on main.
JB3="$(_jr_side "$JBR" "$JB_M" eng-rules engine/.gitignore '*.bak')"; _jr_on "$JBR" "$JB3" refs/remotes/origin/jr-rules
is "B3 (fixture control): jr-rules holds engine/.gitignore with *.bak and the working tree does not, and git there does not ignore engine/harness/x.bak" \
   "$(git -C "$JBR" show "$JB3:engine/.gitignore" 2>&1)|$([ -e "$JBR/engine/.gitignore" ] && echo there)|$(_jb_ign engine/harness/x.bak)" "*.bak||"
_jb_plus harness/x.bak; _jb_call
is "B3 (control): against main, which has no such rule, an entry that is main plus harness/x.bak exits 1 and names it" "$JBRC|$(_jb_names harness/x.bak)" "1|named"
# 2026-10-18 (Part C): the entry is compared whole, so the entry for jr-rules is cut
# from jr-rules, whose engine/.gitignore it must hold, plus the one extra file.
_jb_cut "$JB3" "$JBE"; git -C "$JBR" show "$JB3:engine/.gitignore" > "$JBE/.gitignore" 2>/dev/null
printf 'only in the entry\n' > "$JBE/harness/x.bak"; _jb_call jr-rules
is "B3: against jr-rules, whose engine/.gitignore ignores *.bak, the same entry exits 0, that line not printed" "$JBRC|$(_jb_names harness/x.bak)" "0|"
_jr_off "$JBR" refs/remotes/origin/jr-rules

# ------------------------------------------------------------------- B4 ---
_jb_drift "B4" commands/data/evil.md
_jb_drift "B4" commands/.claude-flow/evil.md
_jb_drift "B4" commands/x.log
_jb_res "B4 (control), main's data/ rule outside commands/" harness/data/evil.md

# ------------------------------------------------------------------- B5 ---
# Two commits off main: m1 declares 5.0.0, m2 after it 5.0.1 with lib/x.sh
# changed, and the cache holds each one's entry. Read whole from either, the
# call accepts; read in part from each, it cannot. A git first on PATH counts
# its calls and, after call K, points refs/remotes/origin/jr5 at m2. K runs
# over every call an unmoved run makes, since no one call is "the read".
JB5="$JB/b5"; mkdir -p "$JB5/bin"
( _fx_cd "$JBR" && git checkout -q -b jr5-tmp ) >/dev/null 2>&1
_jr_commit "$JBR" m1 engine/.claude-plugin/plugin.json '{ "name": "felix", "version": "5.0.0" }'; JB5_1="$(_jr_sha "$JBR" HEAD)"
printf 'x two\n' > "$JBR/engine/harness/lib/x.sh"
_jr_commit "$JBR" m2 engine/.claude-plugin/plugin.json '{ "name": "felix", "version": "5.0.1" }'; JB5_2="$(_jr_sha "$JBR" HEAD)"
( _fx_cd "$JBR" && git checkout -q main && git branch -q -D jr5-tmp ) >/dev/null 2>&1
_jb_cut "$JB5_1" "$JBV/5.0.0"; _jb_cut "$JB5_2" "$JBV/5.0.1"
command -v git > "$JB5/realgit"; git -C "$JBR" rev-parse --absolute-git-dir > "$JB5/gitdir" 2>/dev/null; printf '%s\n' "$JB5_2" > "$JB5/m2"
sed "s|@D@|$JB5|g" > "$JB5/bin/git" <<'JB5STUB'
#!/bin/bash
D='@D@'; RG="$(cat "$D/realgit")"
n=$(( $(cat "$D/count" 2>/dev/null || echo 0) + 1 )); printf '%s\n' "$n" > "$D/count"
"$RG" "$@"; rc=$?
if [ "$n" = "$(cat "$D/k" 2>/dev/null)" ]; then
  "$RG" --git-dir="$(cat "$D/gitdir")" update-ref refs/remotes/origin/jr5 "$(cat "$D/m2")" && printf 'moved\n' >> "$D/moved"
fi
exit "$rc"
JB5STUB
chmod +x "$JB5/bin/git"
_jb5() {   # K -> JBRC, JBO: the call on jr5 with the stub first on PATH, the ref moved after git call K (0: never)
  _jr_on "$JBR" "$JB5_1" refs/remotes/origin/jr5; printf '%s\n' "$1" > "$JB5/k"; rm -f "$JB5/count" "$JB5/moved"
  ( PATH="$JB5/bin:$PATH"; _jb_call jr5; printf '%s\n%s\n' "$JBRC" "$JBO" > "$JB5/res" )
  JBRC="$(sed -n 1p "$JB5/res")"; JBO="$(sed -n '2,$p' "$JB5/res")"
}
_jr_on "$JBR" "$JB5_1" refs/remotes/origin/jr5; _jb_call jr5; _jb5_a="$JBRC|$(_jb_isentry "$JBV/5.0.0")"
_jr_on "$JBR" "$JB5_2" refs/remotes/origin/jr5; _jb_call jr5; _jb5_b="$JBRC|$(_jb_isentry "$JBV/5.0.1")"
is "B5 (fixture control): with no stub, each commit alone is accepted against its own version's entry" "$_jb5_a $_jb5_b" "0|entry 0|entry"
_jb5 0; JB5_N="$(cat "$JB5/count" 2>/dev/null || echo 0)"
is "B5 (fixture control): unmoved, the call runs at least two git commands through the stub, exits 0 and prints the entry for m1's version" \
   "$([ "$JB5_N" -ge 2 ] && echo yes)|$JBRC|$(_jb_isentry "$JBV/5.0.0")" "yes|0|entry"
_jb5_bad=""; _jb5_k=1; _jb5_m=0
while [ "$_jb5_k" -le "$JB5_N" ]; do
  _jb5 "$_jb5_k"; [ -s "$JB5/moved" ] && _jb5_m=$((_jb5_m + 1))
  case "$JBRC|$(_jb_isentry "$JBV/5.0.0")$(_jb_isentry "$JBV/5.0.1")" in "0|entry") ;; *) _jb5_bad="$_jb5_bad after-call-$_jb5_k:$JBRC" ;; esac
  _jb5_k=$((_jb5_k + 1))
done
is "B5 (fixture control): in every moved run the stub moved refs/remotes/origin/jr5 to m2" "$_jb5_m" "$JB5_N"
is "B5: with refs/remotes/origin/jr5 moved to m2 after any one of the call's git commands, the verdict is one commit's: exit 0 and that commit's entry" \
   "$_jb5_bad" ""
_jr_off "$JBR" refs/remotes/origin/jr5

# ------------------------------------------------------------------- B6 ---
JB_G="$JB/ghome"; mkdir -p "$JB_G/.config/git"; printf '*\n' > "$JB_G/star"; printf '*\n' > "$JB_G/.config/git/ignore"
printf '[core]\n\texcludesFile = %s\n' "$JB_G/star" > "$JB_G/.gitconfig"
is "B6 (fixture control): with the machine's global config naming an excludes file of *, git in the home ignores engine/harness/jr-x" \
   "$( ( unset GIT_CONFIG_GLOBAL; HOME="$JB_G" XDG_CONFIG_HOME="$JB_G/.config" git -C "$JBR" check-ignore -q engine/harness/jr-x ) 2>/dev/null && echo ignored)" ignored
JB_HOME="$JB_G"
_jb_plus harness/jr-extra.txt
is "B6: under that global config, an entry that is main plus one extra file exits 1 and names it" "$JBRC|$(_jb_names harness/jr-extra.txt)" "1|named"
_jb_entry; _jb_call
is "B6: and an entry equal to main exits 0 and prints the entry" "$JBRC|$(_jb_isentry)" "0|entry"
JB_HOME=""

# ------------------------------------------------------------------- B7 ---
# TMPDIR an empty directory, and a mktemp first on PATH that writes down what
# it made; after each return nothing it made may be left. Stdin is a file: a
# call that reads from it leaves less of it to the cat after.
JB7="$JB/b7"; mkdir -p "$JB7/bin"; printf 'jr stdin one\njr stdin two\n' > "$JB7/stdin"
printf '#!/bin/sh\nout="$("%s" "$@")" || exit $?\nprintf "%%s\\n" "$out" >> "%s"\nprintf "%%s\\n" "$out"\n' \
  "$(command -v mktemp)" "$JB7/made" > "$JB7/bin/mktemp"; chmod +x "$JB7/bin/mktemp"
_jb7() {   # NAME -> rc|left|stdin: the exit, how many made things remain, same when stdin was not read
  rm -rf "$JB7/tmp"; mkdir -p "$JB7/tmp"; : > "$JB7/made"
  ( PATH="$JB7/bin:$PATH"; export TMPDIR="$JB7/tmp" FELIX_PLUGIN_CACHE="$JBC"; unset FELIX_KERNEL_CACHE
    . "$REAL_HARNESS/lib/resolve.sh" >/dev/null 2>&1
    felix_accepted_deploy_diff "$JBR" "$1" > "$JB7/out" 2>&1; echo "$?" > "$JB7/rc"; cat > "$JB7/rest" ) < "$JB7/stdin"
  _jb7_l=0; while IFS= read -r _jb7_p; do [ -z "$_jb7_p" ] || [ ! -e "$_jb7_p" ] || _jb7_l=$((_jb7_l + 1)); done < "$JB7/made"
  _jb7_l=$((_jb7_l + $(ls -A "$JB7/tmp" | wc -l | tr -d ' ')))
  printf '%s|%s|%s' "$(cat "$JB7/rc")" "$_jb7_l" "$(cmp -s "$JB7/stdin" "$JB7/rest" && echo same)"
}
_jb_entry
is "B7: a call that exits 0 leaves nothing it made behind and reads nothing from stdin" "$(_jb7 main)" "0|0|same"
printf 'extra\n' > "$JBE/harness/jr-extra.txt"
is "B7: a call that exits 1 leaves nothing it made behind and reads nothing from stdin" "$(_jb7 main)" "1|0|same"
is "B7: a call that exits 2 leaves nothing it made behind and reads nothing from stdin" "$(_jb7 jr-no-such)" "2|0|same"

# ------------------------------------------------------------------- B8 ---
JB8="$(_jr_side "$JBR" "$JB_M" nover engine/.claude-plugin/plugin.json '{ "name": "felix", "version": "7.7.7" }')"
_jr_on "$JBR" "$JB8" refs/remotes/origin/jr-nover
_jb_entry; _jb_call
is "B8: exit 0 prints the entry path, one line, and nothing else" "$JBRC|$(_jb_isentry)" "0|entry"
printf 'drift\n' >> "$JBE/harness/lib/x.sh"; _jb_call
is "B8: a content difference exits 1 with a line in diff's own shape, Files A and B differ" \
   "$JBRC|$(LC_ALL=C grep -cE '^Files .*/harness/lib/x\.sh and .*/harness/lib/x\.sh differ$' "$JB/out")" "1|1"
_jb_plus harness/jr-extra.txt
is "B8: a file one side holds exits 1 with a line in diff's own shape, Only in <dir>: <name>" \
   "$JBRC|$(LC_ALL=C grep -cE '^Only in .*/harness: jr-extra\.txt$' "$JB/out")" "1|1"
_jb_says() {   # GLOB -> says when JBO matches GLOB, given unquoted so its * match
  case "$JBO" in $1) printf says ;; esac
}
_jb_call jr-nover
is "B8: a version main declares with nothing installed at it exits 1 with the one line that says so" \
   "$JBRC|$(printf '%s\n' "$JBO" | awk 'END { print NR }')|$(_jb_says '*declares 7.7.7 and nothing is installed at that version*')" "1|1|says"
_jb_call jr-no-such
is "B8: a base that names nothing exits 2 and prints cannot examine" "$JBRC|$(_jb_says 'cannot examine: *')" "2|says"
_jr_off "$JBR" refs/remotes/origin/jr-nover

# ------------------------------------------------------------------- B9 ---
JBL="$JB/live"
_jb_dd() { ( . "$REAL_HARNESS/lib/resolve.sh" >/dev/null 2>&1; felix_deploy_diff "$JBR/engine" "$JBL" "$JBR" ) > "$JB/out" 2>&1; JBRC=$?; JBO="$(cat "$JB/out")"; }
_jb_cut "$JB_M" "$JBL"; _jb_dd
is "B9 (control): felix_deploy_diff on the home's engine and a copy of main's exits 0" "$JBRC" "0"
printf 'drift\n' >> "$JBL/harness/lib/x.sh"; _jb_dd
is "B9 (control): a content difference in lib/x.sh exits 1 and names it" "$JBRC|$(_jb_names harness/lib/x.sh)" "1|named"
_jb_cut "$JB_M" "$JBL"; printf 'drift\n' >> "$JBL/harness/keep.log"; _jb_dd
is "B9: a content difference in harness/keep.log, tracked and force-added under *.log, exits 1 and names it" "$JBRC|$(_jb_names harness/keep.log)" "1|named"
_jb_cut "$JB_M" "$JBL"; printf 'drift\n' >> "$JBL/harness/out"; _jb_dd
is "B9: a content difference in harness/out, tracked, which out/ names only as a directory, exits 1 and names it" "$JBRC|$(_jb_names harness/out)" "1|named"
_jb_cut "$JB_M" "$JBL"; mkdir -p "$JBR/engine/harness/tests/.claude-flow"; printf 'x\n' > "$JBR/engine/harness/tests/.claude-flow/x"; _jb_dd
is "B9 (control): an untracked, ignored stray in SRC stays residue: exit 0" "$JBRC" "0"
rm -rf "$JBR/engine/harness/tests/.claude-flow"; mkdir -p "$JBL/harness/tests/.claude-flow"; printf 'x\n' > "$JBL/harness/tests/.claude-flow/x"; _jb_dd
is "B9 (control): and so does one in LIVE: exit 0" "$JBRC" "0"

# -------------------------------------------------- B10: the callers judge so ---
# E is main plus commands/extra.md, in a home whose engine/ holds an untracked
# .gitignore of *. 1400's checkouts, built again here: JS for felix merge, JG for
# the gate.
_jr_project; _js_build; _js_entry; _jg_build; [ "$JG_ON" = 1 ] && _jg_entry
_js_entry; printf 'not main\n' > "$JSK/1.0.0/commands/extra.md"; _js_dry
_js_refused "B10 (no .gitignore) (fixture control): with the entry main plus commands/extra.md, felix merge --dry-run refuses: the judge is not the engine main accepted"
printf '*\n' > "$JSR/engine/.gitignore"; _js_dry
_js_refused "B10: with an untracked engine/.gitignore of * in the checkout, felix merge --dry-run still refuses because the judge is not the engine main accepted"
rm -f "$JSR/engine/.gitignore"; _js_entry
[ "$JG_ON" = 1 ] && { _jg_entry; printf 'not main\n' > "$JGC/0.0.1/commands/extra.md"; }
_jg_check "B10 (no .gitignore) (fixture control): with the entry main plus commands/extra.md, installed fails" "FAIL|0"
[ "$JG_ON" = 1 ] && printf '*\n' > "$JGT/engine/.gitignore"
_jg_check "B10: with an untracked engine/.gitignore of * in the home, installed still fails" "FAIL|0"
[ "$JG_ON" = 1 ] && { rm -f "$JGT/engine/.gitignore"; _jg_entry; }

# The project and checkouts this part made are taken away again.
rm -rf "$FROOT/projects/jrr" "$MEM/jrr" "$JS" "$JG" "$JB"
