# >>> trust-merge-dir-renames
printf '\ntrust plane step 3, S6.7: the merge the change readers take detects no directory renames (blind)\n'
# Blind, written on 2026-11-09 from .felix/memory/felix/audits/2026-11-08-trust-plane-step3/merge-dir-renames/spec.md
# (rule S6.7 and its "What must be observable" list) and the finding beside it (README.md), before the fix. Read in
# lib/resolve.sh: _felix_merge_refs's signature, its header comment and the line that prints "<base>^{tree} <tree>",
# and the arguments and output of felix_changed_paths and felix_added_lines; not how the merge is made. Seen in passing,
# before the fixture was written: a grep for GIT_CONFIG_ names in resolve.sh, whose hits in the merge set
# GIT_CONFIG_GLOBAL=/dev/null and GIT_CONFIG_NOSYSTEM=1. Read after the red run, to explain one pass: the diff flags of
# _felix_git_patch. Read for the conventions: tests/run, parts 0002, 0003 and 0007 (fixture git, its lint, part mode)
# and part 2179.
#
# Scope: cases 1 to 5 of the list. Each calls _felix_merge_refs, felix_changed_paths or felix_added_lines with base main,
# from a subshell that stands in the fixture's checkout (_fx_cd) and sources $FROOT/harness/lib/resolve.sh, as part 2179
# does. Every repository is under $TMP/tmdr, and every git call into one goes through _fx_git or _fx_cd.
#
# The fixture, one instance of the spec's shape: R holds d/a, d/b and d/c, six lines each. The candidate, cut from R and
# checked out on cand, renames all three into e/, with e/c's last line changed (the "nearly so"). main, after R, adds
# d/new, one line. A second fixture, "one deleted", has d/k in R as well, which the candidate deletes.
#
# Readings, where the spec leaves room:
# - "All but at most one": the one not renamed is deleted, not left in d/. A throwaway probe with plain git 2.56 in a
#   scratch directory found that with one file left in d/, git detects no directory rename in any of the three modes,
#   so that fixture would not exercise the rule.
# - "Names a tree": exit 0, and the output is main^{tree}, a space and an id git cat-file -t calls a tree in the
#   checkout. "With main's bytes": the tree's d/new has main:d/new's blob id. "The renamed files are at e/": the tree's
#   e/a, e/b and e/c have cand's blob ids there, and the tree holds no d/a, d/b or d/c. Each check of the tree reads
#   "no tree" when there is none, so no assertion passes on a missing tree.
# - Case 2's environments, one at a time, each exported in the subshell that calls the function: GIT_CONFIG_COUNT=1 with
#   KEY_0 merge.directoryRenames and VALUE_0 true, and again with conflict; GIT_CONFIG_GLOBAL naming a file that sets it
#   true; and the checkout's own .git/config setting it true, in a fixture of its own. Two more come from the rule's "no
#   config file and no GIT_CONFIG_* variable" and are not in the list: GIT_CONFIG_PARAMETERS carrying
#   'merge.directoryRenames'='true' after the suite's own pins, and GIT_CONFIG_SYSTEM naming a file that sets it true,
#   with GIT_CONFIG_NOSYSTEM unset. A fixture control shows that each of the six moves d/new for a plain git merge-tree.
# - Case 3, "name neither d/new nor e/new": the changed paths hold neither path, and the added lines hold no + line of
#   main's d/new. d/new has one line, so the added lines cannot tell which path it landed at. Each reader must also show
#   the candidate's own change (e/a among the paths, e/c's changed line among the lines), so an empty output does not
#   pass. Asked on the plain fixture, then once per reader under each case-2 environment. The added-lines half is no
#   witness of a move: that reader's patch pairs renames (-M), so d/new moved unchanged to e/new adds no line. In the red
#   run on 0.49.336, GIT_CONFIG_COUNT and GIT_CONFIG_PARAMETERS setting true reached the merge, which exited 0 with d/new
#   at e/new; the changed paths then named d/new and e/new, and the added lines held no line of d/new.
# - Case 4: R holds x/f; main and the candidate change its third line differently. "Exit 1" is _felix_merge_refs's exit
#   status alone. "Fall back to three-dot", as part 2179 reads it: every path git diff --name-only main...HEAD names, and
#   every + line its patch adds, appears in the reader's output.
# - Case 5: R holds p/f and q/g; main changes p/f and the candidate changes q/g. "The same tree as before" is the tree a
#   plain git merge-tree writes in the checkout, which a fixture control shows is the same tree in all three modes and
#   holds main's p/f and the candidate's q/g. _felix_merge_refs must print exactly main^{tree} and that tree, and exit 0.
#
# Not covered:
# - Case 6: this part's red run is case 6, not an assertion in it.
# - felix merge itself and slice 3's A1 over a Felix-shaped fixture (the spec says not required here; parts 2180 to 2183
#   build one).
# - The rest of S6.6 that S6.7 leaves standing (the made bare repository, attributes, the checked copy's stores inside
#   felix merge, the fallback when no directory can be made): part 2179's.
# - Other merge and rename settings (merge.renames, diff.renames, merge.renameLimit), config reached by include or
#   includeIf, a directory renamed into its own parent, and the spec's open items (lib/pr-status.sh, the lander's own
#   reads, GitHub's merge settings beyond the one pair observed).
TMDR="$TMP/tmdr"; rm -rf "${TMDR:?}"; mkdir -p "$TMDR"
_tmdr_new="main's own new file in d, tmdr"
_tmdr_cl="d/c line 6, changed on the candidate"
_tmdr_git() { _fx_git "$1" -c core.hooksPath=/dev/null -c commit.gpgsign=false "${@:2}"; }
_tmdr_commit() { _tmdr_git "$1" add -A >/dev/null 2>&1; _tmdr_git "$1" commit -qm "$2" >/dev/null 2>&1; }
_tmdr_six() {   # NAME [K LINE] -> six lines named after NAME, with line K replaced by LINE
  local i
  for i in 1 2 3 4 5 6; do
    if [ "$i" = "${2:-}" ]; then printf '%s\n' "$3"; else printf '%s line %s\n' "$1" "$i"; fi
  done
}
_tmdr_init() {   # DIR PATH...: a repository on main whose one commit R holds each PATH, six lines named after it
  local p
  mkdir -p "$1"
  ( _fx_cd "$1" && git init -q -b main && git config user.name t && git config user.email t@example.invalid ) >/dev/null 2>&1
  for p in "${@:2}"; do mkdir -p "$1/${p%/*}"; _tmdr_six "$p" > "$1/$p"; done
  _tmdr_commit "$1" R
}
_tmdr_dirs() {   # DIR [k]: the finding's shape, cand checked out; with k, R holds d/k too and the candidate deletes it
  if [ -n "${2:-}" ]; then _tmdr_init "$1" d/a d/b d/c d/k; else _tmdr_init "$1" d/a d/b d/c; fi
  _tmdr_git "$1" checkout -q -b cand >/dev/null 2>&1
  mkdir -p "$1/e"
  _tmdr_git "$1" mv d/a d/b d/c e/ >/dev/null 2>&1
  _tmdr_six d/c 6 "$_tmdr_cl" > "$1/e/c"
  [ -z "${2:-}" ] || _tmdr_git "$1" rm -q d/k >/dev/null 2>&1
  _tmdr_commit "$1" "the candidate renames d/ into e/"
  _tmdr_git "$1" checkout -q main >/dev/null 2>&1
  printf '%s\n' "$_tmdr_new" > "$1/d/new"
  _tmdr_commit "$1" "main adds d/new"
  _tmdr_git "$1" checkout -q cand >/dev/null 2>&1
}
_tmdr_two() {   # DIR PATH K: cut cand from R changing line K of PATH, then main changing the same line differently
  _tmdr_git "$1" checkout -q -b cand >/dev/null 2>&1
  _tmdr_six "$2" "$3" "$2 line $3, on the candidate" > "$1/$2"; _tmdr_commit "$1" candidate
  _tmdr_git "$1" checkout -q main >/dev/null 2>&1
  _tmdr_six "$2" "$3" "$2 line $3, on main" > "$1/$2"; _tmdr_commit "$1" "main moves"
  _tmdr_git "$1" checkout -q cand >/dev/null 2>&1
}
_tmdr_env() {   # [NAME=VALUE | -NAME]...: export each assignment, unset each -NAME (for the subshells below)
  local a
  for a in "$@"; do case "$a" in -*) unset "${a#-}" ;; *) export "$a" ;; esac; done
}
_tmdr_refs() (   # DIR [NAME=VALUE | -NAME]... -> rc N|what _felix_merge_refs printed, from DIR with base main
  _tmdr_env "${@:2}"
  _fx_cd "$1" || exit 1
  . "$FROOT/harness/lib/resolve.sh" 2>/dev/null
  o="$(_felix_merge_refs "$PWD" main 2>/dev/null)"; rc=$?
  printf 'rc %s|%s' "$rc" "$o"
)
_tmdr_read() (   # DIR READER [NAME=VALUE | -NAME]... -> READER's output over DIR with base main, then a line rc N
  _tmdr_env "${@:3}"
  _fx_cd "$1" || exit 1
  . "$FROOT/harness/lib/resolve.sh" 2>/dev/null
  "$2" "$PWD" main 2>/dev/null
  printf 'rc %s\n' "$?"
)
_tmdr_mt() (   # DIR MODE [NAME=VALUE | -NAME]... -> rc N|the tree plain git merge-tree --write-tree main cand writes in
               # DIR, given -c merge.directoryRenames=MODE unless MODE is -
  _tmdr_env "${@:3}"
  if [ "$2" = - ]; then t="$(_fx_git "$1" merge-tree --write-tree main cand 2>/dev/null)"; rc=$?
  else t="$(_fx_git "$1" -c merge.directoryRenames="$2" merge-tree --write-tree main cand 2>/dev/null)"; rc=$?; fi
  printf 'rc %s|%s' "$rc" "${t%%$'\n'*}"
)
_tmdr_obj() { _fx_git "$1" rev-parse -q --verify "$2" 2>/dev/null; }   # DIR REV -> its object id, or nothing
_tmdr_plain() {   # DIR MODE [NAME=VALUE | -NAME]... -> rc N, at d/new|e/new|both|neither: where main's d/new lands
  local x t d e w
  x="$(_tmdr_mt "$@")"; t="${x#*|}"
  d="$(_tmdr_obj "$1" "${t:-none}:d/new")"; e="$(_tmdr_obj "$1" "${t:-none}:e/new")"
  if [ -n "$d" ] && [ -n "$e" ]; then w=both; elif [ -n "$d" ]; then w=d/new; elif [ -n "$e" ]; then w=e/new; else w=neither; fi
  printf '%s, at %s' "${x%%|*}" "$w"
}
_tmdr_tree() {   # OUT -> the tree id a _tmdr_refs output names after main^{tree}, or nothing
  local t="${1#*|}"
  case "$t" in "main^{tree} "?*) printf '%s' "${t#"main^{tree} "}" ;; esac
}
_tmdr_shape() {   # DIR OUT -> rc N|main^{tree} and a tree, or rc N|printed [...]
  local t; t="$(_tmdr_tree "$2")"
  if [ -n "$t" ] && [ "$(_fx_git "$1" cat-file -t "$t" 2>/dev/null)" = tree ]; then printf '%s|main^{tree} and a tree' "${2%%|*}"
  else printf '%s|printed [%s]' "${2%%|*}" "${2#*|}"; fi
}
_tmdr_dnew() {   # DIR TREE -> d/new: main's bytes | other bytes | absent, or no tree
  local b
  [ -n "$2" ] || { printf 'no tree'; return; }
  b="$(_tmdr_obj "$1" "$2:d/new")"
  if [ -z "$b" ]; then printf 'd/new: absent'
  elif [ "$b" = "$(_tmdr_obj "$1" main:d/new)" ]; then printf "d/new: main's bytes"
  else printf 'd/new: other bytes'; fi
}
_tmdr_enew() {   # DIR TREE -> e/new: absent | present, or no tree
  [ -n "$2" ] || { printf 'no tree'; return; }
  if [ -n "$(_tmdr_obj "$1" "$2:e/new")" ]; then printf 'e/new: present'; else printf 'e/new: absent'; fi
}
_tmdr_moved() {   # DIR TREE -> renamed: at e/, or the files of a b c not at e/ with cand's bytes or still at d/; or no tree
  local f b off=""
  [ -n "$2" ] || { printf 'no tree'; return; }
  for f in a b c; do
    b="$(_tmdr_obj "$1" "$2:e/$f")"
    if [ -z "$b" ] || [ "$b" != "$(_tmdr_obj "$1" "cand:e/$f")" ] || [ -n "$(_tmdr_obj "$1" "$2:d/$f")" ]; then off="$off $f"; fi
  done
  if [ -z "$off" ]; then printf 'renamed: at e/'; else printf 'renamed: not at e/ [%s]' "${off# }"; fi
}
_tmdr_judge() {   # DIR OUT -> the four checks of case 1 on what _felix_merge_refs printed, joined by |
  local t; t="$(_tmdr_tree "$2")"
  printf '%s|%s|%s|%s' "$(_tmdr_shape "$1" "$2")" "$(_tmdr_dnew "$1" "$t")" "$(_tmdr_enew "$1" "$t")" "$(_tmdr_moved "$1" "$t")"
}
_tmdr_want="rc 0|main^{tree} and a tree|d/new: main's bytes|e/new: absent|renamed: at e/"
_tmdr_pnames() {   # OUTPUT -> whether e/a, d/new and e/new are among its lines
  printf '%s\n' "$1" | LC_ALL=C awk '$0 == "e/a" { a = 1 } $0 == "d/new" { d = 1 } $0 == "e/new" { e = 1 }
    END { printf "e/a %s|d/new %s|e/new %s", (a ? "named" : "not named"), (d ? "named" : "not named"), (e ? "named" : "not named") }'
}
_tmdr_lnames() {   # OUTPUT -> whether the candidate's changed e/c line and main's d/new line are among its + lines
  local r
  r="$(printf '%s\n' "$1" | LC_ALL=C awk -v c="+$_tmdr_cl" -v m="+$_tmdr_new" '$0 == c { a = 1 } $0 == m { n = 1 }
    END { printf "%s|%s", (a ? "added" : "not added"), (n ? "added" : "not added") }')"
  printf "candidate's line %s|main's line %s" "${r%%|*}" "${r#*|}"
}
_tmdr_pwant="e/a named|d/new not named|e/new not named"
_tmdr_lwant="candidate's line added|main's line not added"
_tmdr_dir() { case "$1" in checkout) printf '%s' "$TMDR/cfg" ;; *) printf '%s' "$TMDR/fx" ;; esac; }   # ENV -> its fixture
_tmdr_in() {   # ENV FUNC [ARG]: FUNC DIR [ARG] with case 2's environment ENV, DIR the fixture ENV is set in
  local d; d="$(_tmdr_dir "$1")"
  case "$1" in
    "count true")     "$2" "$d" ${3:+"$3"} GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=merge.directoryRenames GIT_CONFIG_VALUE_0=true ;;
    "count conflict") "$2" "$d" ${3:+"$3"} GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=merge.directoryRenames GIT_CONFIG_VALUE_0=conflict ;;
    global)           "$2" "$d" ${3:+"$3"} GIT_CONFIG_GLOBAL="$TMDR/global.cfg" ;;
    parameters)       "$2" "$d" ${3:+"$3"} "GIT_CONFIG_PARAMETERS=${GIT_CONFIG_PARAMETERS:+$GIT_CONFIG_PARAMETERS }'merge.directoryRenames'='true'" ;;
    system)           "$2" "$d" ${3:+"$3"} GIT_CONFIG_SYSTEM="$TMDR/system.cfg" -GIT_CONFIG_NOSYSTEM ;;
    checkout)         "$2" "$d" ${3:+"$3"} ;;
  esac
}
# An array and not an IFS split: an IFS set here would reach resolve.sh's functions, which split their refs on a space.
_tmdr_envs=("count true" "count conflict" global parameters system checkout)
_tmdr_each() {   # READER VIEW WANT -> ENV: held, or ENV: [what VIEW said], for each case-2 environment, joined by |
  local n v s=""
  for n in "${_tmdr_envs[@]}"; do
    v="$("$2" "$(_tmdr_in "$n" _tmdr_read "$1")")"
    if [ "$v" = "$3" ]; then s="$s|$n: held"; else s="$s|$n: [$v]"; fi
  done
  printf '%s' "${s#|}"
}
_tmdr_envplain() {   # -> ENV: where a plain git merge-tree puts d/new under ENV and no -c, for each case-2 environment
  local n s=""
  for n in "${_tmdr_envs[@]}"; do s="$s|$n: $(_tmdr_in "$n" _tmdr_plain -)"; done
  printf '%s' "${s#|}"
}
_tmdr_3paths() { _fx_git "$1" diff --name-only --no-renames main...HEAD 2>/dev/null; }
_tmdr_3lines() {
  _fx_git "$1" diff --no-ext-diff --no-textconv --no-color main...HEAD 2>/dev/null | LC_ALL=C grep '^+' | LC_ALL=C grep -v '^+++'
}
_tmdr_missing() {   # WANT GOT -> the non-empty lines of WANT that GOT lacks, joined by |, or none
  printf '%s\n' "$1" > "$TMDR/want"; printf '%s\n' "$2" > "$TMDR/got"
  LC_ALL=C awk 'FILENAME == ARGV[1] { a[$0] = 1; next } $0 != "" && !($0 in a) { printf "%s%s", s, $0; s = "|"; m = 1 }
                END { if (!m) printf "none" }' "$TMDR/got" "$TMDR/want"
}
_tmdr_flat() { printf '%s\n' "$1" | LC_ALL=C awk 'NF { printf "%s%s", s, $0; s = "|" }'; }

# ----------------------------------------------------------------- fixtures ---
_tmdr_dirs "$TMDR/fx"; _tmdr_dirs "$TMDR/del" k; _tmdr_dirs "$TMDR/cfg"
_tmdr_git "$TMDR/cfg" config merge.directoryRenames true >/dev/null 2>&1
printf '[merge]\n\tdirectoryRenames = true\n' > "$TMDR/global.cfg"
printf '[merge]\n\tdirectoryRenames = true\n' > "$TMDR/system.cfg"
_tmdr_base() {   # DIR -> base R, main moved, when main's tip is past cand's merge-base and that base is R
  local r; r="$(_fx_git "$1" rev-list --max-parents=0 main 2>/dev/null)"
  if [ -n "$r" ] && [ "$(_fx_git "$1" merge-base main cand 2>/dev/null)" = "$r" ] && [ "$(_tmdr_obj "$1" main)" != "$r" ]; then
    printf 'base R, main moved'; else printf 'not the shape'; fi
}
is  "tmdr: (fixture control) the finding's shape: main has moved since R, the candidate's base; the candidate holds e/a, e/b and e/c and no d/; and plain git merge-tree of main and the candidate in the checkout moves d/new to e/new with merge.directoryRenames=conflict (exit 1) and =true (exit 0), and leaves it at d/new with =false (exit 0)" \
    "$(_tmdr_base "$TMDR/fx")|$(_tmdr_flat "$(_fx_git "$TMDR/fx" ls-tree -r --name-only cand 2>&1)")|conflict: $(_tmdr_plain "$TMDR/fx" conflict)|true: $(_tmdr_plain "$TMDR/fx" true)|false: $(_tmdr_plain "$TMDR/fx" false)" \
    "base R, main moved|e/a|e/b|e/c|conflict: rc 1, at e/new|true: rc 0, at e/new|false: rc 0, at d/new"
is  "tmdr: (fixture control) one deleted: R also holds d/k, which the candidate deletes while it renames the rest of d/ into e/; plain git merge-tree moves d/new to e/new with merge.directoryRenames=conflict (exit 1) and =true, and leaves it at d/new with =false" \
    "$(_tmdr_base "$TMDR/del")|$(_tmdr_flat "$(_fx_git "$TMDR/del" ls-tree -r --name-only main~1 2>&1)")|$(_tmdr_flat "$(_fx_git "$TMDR/del" ls-tree -r --name-only cand 2>&1)")|conflict: $(_tmdr_plain "$TMDR/del" conflict)|true: $(_tmdr_plain "$TMDR/del" true)|false: $(_tmdr_plain "$TMDR/del" false)" \
    "base R, main moved|d/a|d/b|d/c|d/k|e/a|e/b|e/c|conflict: rc 1, at e/new|true: rc 0, at e/new|false: rc 0, at d/new"
is  "tmdr: (fixture control) each case-2 environment reaches a plain git merge-tree in the checkout: GIT_CONFIG_COUNT setting merge.directoryRenames to true exits 0 and to conflict exits 1, both with d/new at e/new; GIT_CONFIG_GLOBAL, GIT_CONFIG_PARAMETERS, GIT_CONFIG_SYSTEM and the checkout's own config, each setting it true, move d/new to e/new and exit 0" \
    "$(_tmdr_envplain)" \
    "count true: rc 0, at e/new|count conflict: rc 1, at e/new|global: rc 0, at e/new|parameters: rc 0, at e/new|system: rc 0, at e/new|checkout: rc 0, at e/new"
_tmdr_tt="$(_tmdr_mt "$TMDR/fx" true)"; _tmdr_tt="${_tmdr_tt#*|}"
is  "tmdr: (fixture control) case 3 can see a move: git diff --name-only --no-renames from main's tree to the tree plain git merge-tree writes with merge.directoryRenames=true names e/a, d/new and e/new" \
    "$(_tmdr_pnames "$(_fx_git "$TMDR/fx" diff --name-only --no-renames "main^{tree}" "${_tmdr_tt:-none}" 2>&1)")" "e/a named|d/new named|e/new named"

# ------------------------------------------------------------------- case 1 ---
_tmdr_o1="$(_tmdr_refs "$TMDR/fx")"; _tmdr_t1="$(_tmdr_tree "$_tmdr_o1")"
is  "tmdr: case 1: from the checkout of a candidate that renames all of d/ into e/ while main added d/new, _felix_merge_refs with base main exits 0 and prints main^{tree} and the id of a tree" \
    "$(_tmdr_shape "$TMDR/fx" "$_tmdr_o1")" "rc 0|main^{tree} and a tree"
is  "tmdr: case 1: in the tree _felix_merge_refs names for that candidate, d/new is at d/new with main's bytes" \
    "$(_tmdr_dnew "$TMDR/fx" "$_tmdr_t1")" "d/new: main's bytes"
is  "tmdr: case 1: in the tree _felix_merge_refs names for that candidate, e/new does not exist" \
    "$(_tmdr_enew "$TMDR/fx" "$_tmdr_t1")" "e/new: absent"
is  "tmdr: case 1: in the tree _felix_merge_refs names for that candidate, the files it renamed are at e/ with its bytes, the nearly unchanged one included, and not at d/" \
    "$(_tmdr_moved "$TMDR/fx" "$_tmdr_t1")" "renamed: at e/"
is  "tmdr: case 1, one deleted: when the candidate deletes d/k and renames the rest of d/ into e/, _felix_merge_refs exits 0 and names a tree with d/new at d/new in main's bytes, no e/new, and the renamed files at e/" \
    "$(_tmdr_judge "$TMDR/del" "$(_tmdr_refs "$TMDR/del")")" "$_tmdr_want"

# ------------------------------------------------------------------- case 2 ---
is  "tmdr: case 2: with GIT_CONFIG_COUNT=1, GIT_CONFIG_KEY_0=merge.directoryRenames and GIT_CONFIG_VALUE_0=true in the caller's environment, _felix_merge_refs still exits 0 and names a tree with d/new at d/new in main's bytes, no e/new, and the renamed files at e/" \
    "$(_tmdr_judge "$(_tmdr_dir "count true")" "$(_tmdr_in "count true" _tmdr_refs)")" "$_tmdr_want"
is  "tmdr: case 2: with GIT_CONFIG_COUNT=1, GIT_CONFIG_KEY_0=merge.directoryRenames and GIT_CONFIG_VALUE_0=conflict in the caller's environment, _felix_merge_refs still exits 0 and names a tree with d/new at d/new in main's bytes, no e/new, and the renamed files at e/" \
    "$(_tmdr_judge "$(_tmdr_dir "count conflict")" "$(_tmdr_in "count conflict" _tmdr_refs)")" "$_tmdr_want"
is  "tmdr: case 2: with GIT_CONFIG_GLOBAL naming a file that sets merge.directoryRenames true, _felix_merge_refs still exits 0 and names a tree with d/new at d/new in main's bytes, no e/new, and the renamed files at e/" \
    "$(_tmdr_judge "$(_tmdr_dir global)" "$(_tmdr_in global _tmdr_refs)")" "$_tmdr_want"
is  "tmdr: case 2: with the checkout's own .git/config setting merge.directoryRenames true, _felix_merge_refs still exits 0 and names a tree with d/new at d/new in main's bytes, no e/new, and the renamed files at e/" \
    "$(_tmdr_judge "$(_tmdr_dir checkout)" "$(_tmdr_in checkout _tmdr_refs)")" "$_tmdr_want"
is  "tmdr: case 2, beyond the list: with GIT_CONFIG_PARAMETERS carrying merge.directoryRenames=true after the suite's own pins, _felix_merge_refs still exits 0 and names a tree with d/new at d/new in main's bytes, no e/new, and the renamed files at e/" \
    "$(_tmdr_judge "$(_tmdr_dir parameters)" "$(_tmdr_in parameters _tmdr_refs)")" "$_tmdr_want"
is  "tmdr: case 2, beyond the list: with GIT_CONFIG_SYSTEM naming a file that sets merge.directoryRenames true and GIT_CONFIG_NOSYSTEM unset, _felix_merge_refs still exits 0 and names a tree with d/new at d/new in main's bytes, no e/new, and the renamed files at e/" \
    "$(_tmdr_judge "$(_tmdr_dir system)" "$(_tmdr_in system _tmdr_refs)")" "$_tmdr_want"

# ------------------------------------------------------------------- case 3 ---
is  "tmdr: case 3: on the candidate that renames d/ into e/, the changed paths with base main name e/a, the candidate's own rename, and neither d/new nor e/new" \
    "$(_tmdr_pnames "$(_tmdr_read "$TMDR/fx" felix_changed_paths)")" "$_tmdr_pwant"
# A guard, not a test of the move: the added lines pair renames, so main's d/new moved unchanged adds no line in any
# rename mode (review of S6.7, 2026-11-09). Only the changed-paths assertions above and below see the move.
is  "tmdr: case 3: on the candidate that renames d/ into e/, the added lines with base main hold the candidate's changed e/c line and no line of main's d/new" \
    "$(_tmdr_lnames "$(_tmdr_read "$TMDR/fx" felix_added_lines)")" "$_tmdr_lwant"
is  "tmdr: case 3, each case-2 environment: under each of case 2's environments in turn, the changed paths still name e/a and neither d/new nor e/new" \
    "$(_tmdr_each felix_changed_paths _tmdr_pnames "$_tmdr_pwant")" \
    "count true: held|count conflict: held|global: held|parameters: held|system: held|checkout: held"
is  "tmdr: case 3, each case-2 environment: under each of case 2's environments in turn, the added lines still hold the candidate's changed e/c line and no line of main's d/new" \
    "$(_tmdr_each felix_added_lines _tmdr_lnames "$_tmdr_lwant")" \
    "count true: held|count conflict: held|global: held|parameters: held|system: held|checkout: held"

# ------------------------------------------------------------------- case 4 ---
_tmdr_init "$TMDR/cfl" x/f; _tmdr_two "$TMDR/cfl" x/f 3
is  "tmdr: (fixture control) a content conflict: main and the candidate change x/f's third line differently since R; plain git merge-tree exits 1 in all three directory-rename modes; three-dot names x/f and adds the candidate's line" \
    "$(_tmdr_base "$TMDR/cfl")|$(for _tmdr_m in conflict true false; do _tmdr_x="$(_tmdr_mt "$TMDR/cfl" "$_tmdr_m")"; printf '%s: %s|' "$_tmdr_m" "${_tmdr_x%%|*}"; done)$(_tmdr_flat "$(_tmdr_3paths "$TMDR/cfl")")|$(_tmdr_flat "$(_tmdr_3lines "$TMDR/cfl")")" \
    "base R, main moved|conflict: rc 1|true: rc 1|false: rc 1|x/f|+x/f line 3, on the candidate"
_tmdr_o4="$(_tmdr_refs "$TMDR/cfl")"
is  "tmdr: case 4: when main and the candidate change the same line of x/f differently, _felix_merge_refs with base main still exits 1" \
    "${_tmdr_o4%%|*}" "rc 1"
# These two hold for the conflicted tree too, which keeps the candidate's line between markers: the fallback itself
# is the exit status above (review of S6.7, 2026-11-09).
is  "tmdr: case 4: on that content conflict, the changed paths still hold every path the three-dot diff names" \
    "$(_tmdr_missing "$(_tmdr_3paths "$TMDR/cfl")" "$(_tmdr_read "$TMDR/cfl" felix_changed_paths)")" "none"
is  "tmdr: case 4: on that content conflict, the added lines still hold every line the three-dot diff adds" \
    "$(_tmdr_missing "$(_tmdr_3lines "$TMDR/cfl")" "$(_tmdr_read "$TMDR/cfl" felix_added_lines)")" "none"

# ------------------------------------------------------------------- case 5 ---
_tmdr_init "$TMDR/plain" p/f q/g
_tmdr_git "$TMDR/plain" checkout -q -b cand >/dev/null 2>&1
_tmdr_six q/g 6 "q/g line 6, on the candidate" > "$TMDR/plain/q/g"; _tmdr_commit "$TMDR/plain" candidate
_tmdr_git "$TMDR/plain" checkout -q main >/dev/null 2>&1
_tmdr_six p/f 6 "p/f line 6, on main" > "$TMDR/plain/p/f"; _tmdr_commit "$TMDR/plain" "main moves"
_tmdr_git "$TMDR/plain" checkout -q cand >/dev/null 2>&1
_tmdr_t5="$(_tmdr_mt "$TMDR/plain" conflict)"; _tmdr_t5="${_tmdr_t5#*|}"
_tmdr_same() {   # -> one tree, when the three modes write the same tree and exit 0
  local m x
  for m in conflict true false; do x="$(_tmdr_mt "$TMDR/plain" "$m")"; [ "$x" = "rc 0|$_tmdr_t5" ] || { printf 'differ'; return; }; done
  printf 'one tree'
}
is  "tmdr: (fixture control) no renames: main changes p/f and the candidate q/g since R; plain git merge-tree exits 0 and writes one tree in all three directory-rename modes, and that tree holds main's p/f and the candidate's q/g" \
    "$(_tmdr_base "$TMDR/plain")|$(_tmdr_same)|$([ "$(_tmdr_obj "$TMDR/plain" "${_tmdr_t5:-none}:p/f")" = "$(_tmdr_obj "$TMDR/plain" main:p/f)" ] && printf "main's p/f")|$([ "$(_tmdr_obj "$TMDR/plain" "${_tmdr_t5:-none}:q/g")" = "$(_tmdr_obj "$TMDR/plain" cand:q/g)" ] && printf "the candidate's q/g")" \
    "base R, main moved|one tree|main's p/f|the candidate's q/g"
is  "tmdr: case 5: with no renames on a moved base, _felix_merge_refs exits 0 and prints main^{tree} and the tree a plain git merge-tree writes" \
    "$(_tmdr_refs "$TMDR/plain")" "rc 0|main^{tree} ${_tmdr_t5:-no tree}"

rm -rf "${TMDR:?}"
# <<< trust-merge-dir-renames
