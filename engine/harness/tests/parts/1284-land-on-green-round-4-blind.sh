# >>> land-on-green-round-4
printf '\nland on green: the amendments A17-A22 (contract A17-A22, blind)\n'
# Blind, from the contract's "Amended after the final review" alone, on the
# fixture parts 1280-1283 build: lib/green-tick.sh, lib/green-install.sh,
# felix_land and cmd_land were not read. lib/resolve.sh was, for the two
# functions A17 names. What the contract leaves open is not asserted: the words
# of a row, what land/verifying holds, and which event a tick that cannot
# resolve its project writes. A20's watchdog, logout and reboot have no seam;
# a land/verifying left in place stands for all three.
#
# main's engine gains two lines in its felix stub here, committed and pushed,
# so every cache entry after it carries them: gate logs whether land/verifying
# exists while it runs, and land execs ctl/land.exec when that file is there,
# which is how the trampoline is made to run a tick that cannot resolve its
# project (A22).
_lg_build amend
L4="$LG/round4"; mkdir -p "$L4/noproj"
_fx_git "$LGH" fetch -q origin >/dev/null 2>&1; _fx_git "$LGH" checkout -q main >/dev/null 2>&1
_fx_git "$LGH" reset -q --hard refs/remotes/origin/main >/dev/null 2>&1
_l4a='[ "${1:-}" = gate ] && { [ -e "$LG/mem/lgh/land/verifying" ] && echo yes || echo no; } >> "$LG/log/verifying.log"'
_l4b='[ "${1:-}" = land ] && [ -x "$K/land.exec" ] && exec "$K/land.exec" "$@"'
LC_ALL=C awk -v a="$_l4a" -v b="$_l4b" 'index($0, "case \"${1:-}\" in") == 1 && !d { print a; print b; d = 1 } { print }' \
  "$LGH/engine/harness/felix" > "$L4/felix.new" && cat "$L4/felix.new" > "$LGH/engine/harness/felix"
_fx_git "$LGH" -c user.name=t -c user.email=t@t commit -qam 'round 4 stub' >/dev/null 2>&1
_fx_git "$LGH" push -q origin main >/dev/null 2>&1
L4V="$(_l3_mainv)"; [ -n "$L4V" ] && _lg_cache "$L4V"; L4E="$LGV/$L4V/harness/felix"
L4M="$(git -C "$LGH" rev-parse refs/remotes/origin/main 2>/dev/null)"
is "the land fixture: main's felix stub carries the round 4 lines, the home is at origin's main, and main's check accepts its entry (fixture control)" \
   "$(LC_ALL=C grep -cE 'land\.exec|verifying\.log' "$L4E" 2>/dev/null)|$(git -C "$LGH" rev-parse HEAD 2>&1)|$(_l4_acc refs/remotes/origin/main)" \
   "2|$(git -C "$LGO" rev-parse main 2>&1)|0"

# -------------------------------------------------------------------- A17 ---
# felix_base_ref itself, on two small repositories: br has main, a remote
# main, and a decoy commit named by a tag and a branch that are each spelled
# origin/<a full ref name>; br2 has a local main only.
mkdir -p "$L4/br" "$L4/br2"
for _l4r in br br2; do
  _fx_git "$L4/$_l4r" init -q -b main >/dev/null 2>&1; printf 'a\n' > "$L4/$_l4r/a"
  _fx_git "$L4/$_l4r" add -A >/dev/null 2>&1; _fx_git "$L4/$_l4r" -c user.name=t -c user.email=t@t commit -qm a >/dev/null 2>&1
done
_l4ba="$(git -C "$L4/br" rev-parse HEAD 2>/dev/null)"
_fx_git "$L4/br" checkout -q -b side >/dev/null 2>&1; printf 'b\n' > "$L4/br/b"
_fx_git "$L4/br" add -A >/dev/null 2>&1; _fx_git "$L4/br" -c user.name=t -c user.email=t@t commit -qm b >/dev/null 2>&1
_l4bb="$(git -C "$L4/br" rev-parse HEAD 2>/dev/null)"; _fx_git "$L4/br" checkout -q main >/dev/null 2>&1
_fx_git "$L4/br" update-ref refs/remotes/origin/main "$_l4ba" >/dev/null 2>&1
for _l4r in origin/refs/remotes/origin/main origin/refs/heads/absent; do
  _fx_git "$L4/br" tag "$_l4r" "$_l4bb" >/dev/null 2>&1; _fx_git "$L4/br" branch -q "$_l4r" "$_l4bb" >/dev/null 2>&1
done
_fx_git "$L4/br" tag l4tree "$(git -C "$L4/br" rev-parse 'HEAD^{tree}' 2>/dev/null)" >/dev/null 2>&1
is "the land fixture: in br, origin/refs/remotes/origin/main names the decoy, refs/remotes/origin/main names main, l4tree a tree (fixture control)" \
   "$(git -C "$L4/br" rev-parse origin/refs/remotes/origin/main refs/heads/origin/refs/remotes/origin/main refs/remotes/origin/main 2>/dev/null | tr '\n' ' ')$(git -C "$L4/br" cat-file -t refs/tags/l4tree 2>/dev/null)" \
   "$_l4bb $_l4bb $_l4ba tree"
_l4_br() {   # REPO BASE -> felix_base_ref's output|status, from this tree's lib/resolve.sh
  ( . "$REAL_HARNESS/lib/resolve.sh" >/dev/null 2>&1; felix_base_ref "$L4/$1" "$2"; printf '|%s' "$?" )
}
is "A17: felix_base_ref given refs/remotes/origin/main returns exactly that ref, though a tag and a branch named origin/refs/remotes/origin/main exist" \
   "$(_l4_br br refs/remotes/origin/main)" "refs/remotes/origin/main|0"
is "A17: given a refs/ name that does not resolve, it tries nothing else: origin/refs/heads/absent resolves, and it still fails, printing nothing" \
   "$(_l4_br br refs/heads/absent)" "|1"
is "A17: given a refs/ name that resolves to a tree, not a commit, it fails, printing nothing" "$(_l4_br br refs/tags/l4tree)" "|1"
is "A17: given refs/heads/main it returns it as it is" "$(_l4_br br refs/heads/main)" "refs/heads/main|0"
# 2026-10-18 (judge refs): the same refs, now returned by their full names (contract A1, A3).
is "A17: given main, with origin/main there, it returns refs/remotes/origin/main" "$(_l4_br br main)" "refs/remotes/origin/main|0"
is "A17: given main, with no origin/main, it returns refs/heads/main" "$(_l4_br br2 main)" "refs/heads/main|0"
is "A17: given a short name that resolves neither way, it fails, as before" "$(_l4_br br2 nope)" "|1"

# The decoy in the home: a commit no one pushed, at main's version number, with
# an engine that is not main's. A branch installed it, so the cache entry at
# main's version is its engine. A tag keeps it while no decoy name does.
_fx_git "$LGH" worktree add -q -b l4-decoy "$L4/decoy" main >/dev/null 2>&1
printf 'core decoy\n' > "$L4/decoy/engine/harness/lib/core.sh"
_fx_git "$L4/decoy" -c user.name=t -c user.email=t@t commit -qam decoy >/dev/null 2>&1
L4X="$(git -C "$L4/decoy" rev-parse HEAD 2>/dev/null)"; rm -rf "$L4/rogue-harness"; mkdir -p "$L4/rogue-harness"; cp -R "$L4/decoy/engine/." "$L4/rogue-harness/"   # 2026-10-18: the whole engine, since the entry is compared whole
_fx_git "$LGH" tag l4-keep "$L4X" >/dev/null 2>&1
_fx_git "$LGH" worktree remove --force "$L4/decoy" >/dev/null 2>&1; _fx_git "$LGH" branch -q -D l4-decoy >/dev/null 2>&1
_l4_rogue() { rm -rf "$LGV/$L4V"; mkdir -p "$LGV/$L4V"; cp -R "$L4/rogue-harness/." "$LGV/$L4V/"; }
_l4_decoy() { _fx_git "$LGH" tag origin/refs/remotes/origin/main "$L4X" >/dev/null 2>&1
  _fx_git "$LGH" branch -q origin/refs/remotes/origin/main "$L4X" >/dev/null 2>&1; }
_l4_nodecoy() { _fx_git "$LGH" tag -d origin/refs/remotes/origin/main >/dev/null 2>&1
  _fx_git "$LGH" branch -q -D origin/refs/remotes/origin/main >/dev/null 2>&1; }
_l4_rogue
is "the land fixture: the entry at main's version is the decoy commit's engine: main's check, asked about that commit, accepts it, and asked about main, rejects it (fixture control)" \
   "$(_l4_acc "$L4X")|$(_l4_acc refs/remotes/origin/main)|$(_l3_mainv)" "0|1|$L4V"
_l4_decoy
is "the land fixture: a tag and a branch named origin/refs/remotes/origin/main name the decoy, and refs/remotes/origin/main names main (fixture control)" \
   "$(git -C "$LGH" rev-parse refs/tags/origin/refs/remotes/origin/main refs/heads/origin/refs/remotes/origin/main refs/remotes/origin/main 2>/dev/null | tr '\n' ' ')" \
   "$L4X $L4X $L4M "
is "A17: with the decoy names, felix_accepted_deploy_diff given refs/remotes/origin/main judges main: the decoy's engine is rejected" \
   "$(_l4_acc refs/remotes/origin/main)" "1"
_lg_cache "$L4V"
is "A17: and main's own engine is accepted" "$(_l4_acc refs/remotes/origin/main)" "0"
_l4_nodecoy

_lg_reset; _lg_land --install
_l4_e2e() {   # WHAT -> the trampoline and the tick with the decoy's engine at main's version
  _lg_reset; _l4_rogue; _la_tramp; _la_tramp
  is "A17: $1: the trampoline runs no felix land --tick, from that entry or any" "$(_la_ticks)" "0"
  is "A17: $1: two trampoline runs write one deploy-owed row and exit 1" "$(_lg_n deploy-owed)|$LARC" "1|1"
  _lg_reset; _lg_prs "$(_lg_pr 42)"; _lg_green 42; printf '/bin/bash /x/engine/harness/tests/run\n' > "$LGK/procs"; _lg_land --tick
  is "A17: $1: the tick finds the deploy owed: one deploy-owed row, nothing installed, nothing merged" \
     "$(_lg_n deploy-owed)|$(_lg_ninst)|$(_lg_merges)" "1|0|"
}
_l4_e2e "control, with no decoy name"
_l4_decoy
_l4_e2e "with a tag and a branch named origin/refs/remotes/origin/main at the decoy"
_lg_cache "$L4V"; _lg_reset; _la_tramp
is "A17: with the decoy names and main's entry in place, the trampoline runs main's entry's felix land --tick" \
   "$(_la_ticks)|$(_lg_logs felix | LC_ALL=C awk -F'\t' '$3 == "land --tick" { print $1 }')" "1|$L4E"
is "A17: and writes no deploy-owed row" "$(_lg_n deploy-owed)" "0"
_lg_reset; _lg_prs "$(_lg_pr 42)"; _lg_green 42; _lg_land --tick
is "A17: with the decoy names and main's entry in place, the tick owes no deploy and merges a green pull request through main's entry" \
   "$(_lg_n deploy-owed)|$(_lg_ninst)|$(_lg_merges)|$(_l3_mpath)" "0|0|b42|$L4E "
rm -rf "$LGV/$L4V"; _lg_reset; _lg_land --tick
is "A17, A21: with the decoy names, an owed deploy of main's engine verifies against main: deployed, not deploy-failed" \
   "$(_lg_n deployed)|$(( $(_lg_n deploy-failed) + $(_lg_n deployed-unverified) ))" "1|0"
[ -e "$LAND/paused" ] && bad "A17: and nothing is paused" "[$(cat "$LAND/paused")]" || ok "A17: and nothing is paused"
_l4_nodecoy; _lg_cache "$L4V"

# -------------------------------------------------------------------- A18 ---
printf '70\t%s\n' "$(_lg_branch b70 notes/b70.md)" >> "$LG/shas"
printf '71\t%s\n' "$(_lg_branch b71 notes/b71.md)" >> "$LG/shas"
_lg_reset; _lg_prs "$(_lg_pr 70)"; _lg_green 70; _lg_land --tick
is "A18: (control) a green pull request whose worktree path is plain lands" "$(_lg_n landed 70)|$(_lg_merges)" "1|b70"
L4T="$LGW/$(printf 'tab\t70')"; L4N="$LGW/$(printf 'nl\n71')"
_fx_git "$LGH" worktree move "$LGW/b70" "$L4T" >/dev/null 2>&1; _fx_git "$LGH" worktree move "$LGW/b71" "$L4N" >/dev/null 2>&1
is "the land fixture: the worktree of 70 holds a tab in its path, that of 71 a newline, each on its branch at its pull request's head (fixture control)" \
   "$(git -C "$L4T" symbolic-ref HEAD 2>&1) $(git -C "$L4T" rev-parse HEAD 2>&1) $(git -C "$L4N" symbolic-ref HEAD 2>&1) $(git -C "$L4N" rev-parse HEAD 2>&1)" \
   "refs/heads/b70 $(_lg_sha 70) refs/heads/b71 $(_lg_sha 71)"
_lg_reset; _lg_prs "$(_lg_pr 70)" "$(_lg_pr 71)"; _lg_green 70 71; _lg_land --tick
is "A18: a green pull request whose worktree path holds a tab gets one session row" "$(_lg_n session 70)" "1"
is "A18: one whose worktree path holds a newline gets one session row" "$(_lg_n session 71)" "1"
is "A18: neither is merged, and felix merge runs in neither worktree" "$(_lg_merges)|$(_lg_n landed)|$(_lg_n refused)" "|0|0"
_l4o="$(LC_ALL=C awk -F'\t' 'NF != 7' "$LAND/ledger.tsv" 2>/dev/null | wc -l | tr -d ' ')"
[ "$(_lg_rows)" -gt 0 ] && [ "$_l4o" = 0 ] && ok "A18: every ledger line has exactly seven tab-separated fields" \
  || bad "A18: every ledger line has exactly seven tab-separated fields" "$(_lg_rows) lines, $_l4o of another shape"
_fx_git "$LGH" worktree remove --force "$L4T" >/dev/null 2>&1; _fx_git "$LGH" worktree remove --force "$L4N" >/dev/null 2>&1
_fx_git "$LGH" worktree prune >/dev/null 2>&1; _fx_git "$LGH" branch -q -D b70 b71 >/dev/null 2>&1

# -------------------------------------------------------------------- A19 ---
printf '72\t%s\n' "$(_lg_branch b72 notes/b72.md)" >> "$LG/shas"
_l4_pr() {   # N HEAD-NAME HEAD-SHA [BASE] -> one pull request as gh lists it
  printf '{"number":%s,"headRefName":"%s","headRefOid":"%s","isDraft":false,"labels":[],"mergeable":"MERGEABLE","isCrossRepository":false,"baseRefName":"%s"}' \
    "$1" "$2" "$3" "${4:-main}"
}
_lg_reset; _lg_prs "$(_lg_pr 72)"; _lg_green 72; _lg_land --tick
is "A19: (control) a green pull request alone on its head branch lands" "$(_lg_n landed 72)|$(_lg_merges)" "1|b72"
_lg_reset; _lg_prs "$(_l4_pr 73 b72 "$(_lg_sha 72)")" "$(_lg_pr 72)"; _lg_green 72; _lg_land --tick
is "A19: two green open pull requests with one headRefName: neither is merged" "$(_lg_merges)|$(_lg_n landed)" "|0"
is "A19: and each gets one skip row" "$(_lg_n skip 72)|$(_lg_n skip 73)" "1|1"
_lg_reset; _lg_prs "$(_lg_pr 72)" "$(_l4_pr 74 b72 "$(_lg_sha 72)" release)"; _lg_green 72; _lg_land --tick
is "A19: a candidate whose head branch is also the head of an open pull request into another base gets one skip row and is not merged" \
   "$(_lg_n skip 72)|$(_lg_merges)" "1|"
_fx_git "$LGH" worktree remove --force "$LGW/b72" >/dev/null 2>&1; _fx_git "$LGH" branch -q -D b72 >/dev/null 2>&1

# -------------------------------------------------------------------- A20 ---
_lg_reset; _lg_prs "$(_lg_pr 42)"; _lg_green 42; _lg_land --tick
is "A20: (control) with no land/verifying and main's entry in place, a green pull request merges and nothing is installed" \
   "$(_lg_merges)|$(_lg_ninst)" "b42|0"
_lg_reset; mkdir -p "$LAND"; : > "$LAND/verifying"; _lg_prs "$(_lg_pr 42)"; _lg_green 42; _lg_land --tick
is "A20: a leftover land/verifying makes the next tick redo the deploy: one install, one deployed row" "$(_lg_ninst)|$(_lg_n deployed)" "1|1"
is "A20: and that tick merges nothing" "$(_lg_merges)" ""
[ -e "$LAND/verifying" ] && bad "A20: a verify that writes deployed removes land/verifying" "it is still there" \
  || ok "A20: a verify that writes deployed removes land/verifying"
is "A20: the deploy wrote land/verifying before its verify ran felix gate --quick" "$(_lg_logs verifying | tail -1)" "yes"
_lg_land --tick
is "A20: the tick after it merges, with nothing installed again" "$(_lg_merges)|$(_lg_ninst)" "b42|1"
rm -rf "$LGV/$L4V"; _lg_reset; _lg_prs "$(_lg_pr 42)"; _lg_green 42; printf '1\n' > "$LGK/gate.rc"; _lg_land --tick
is "A20: (setup) an owed deploy whose felix gate --quick fails ends deploy-failed, after one install" \
   "$(_lg_n deploy-failed)|$(_lg_n deployed)|$(_lg_ninst)" "1|0|1"
[ -e "$LAND/verifying" ] && ok "A20: land/verifying stays after a verify that did not write deployed" \
  || bad "A20: land/verifying stays after a verify that did not write deployed" "it is gone"
rm -f "$LGK/gate.rc"; _lg_land --resume; _lg_land --tick
is "A20: once resumed, a tick that finds land/verifying deploys again, though main's entry is in place, and merges nothing" \
   "$(_lg_ninst)|$(_lg_n deployed)|$(_lg_merges)" "2|1|"
[ -e "$LAND/verifying" ] && bad "A20: and its deployed verify removes land/verifying" "it is still there" \
  || ok "A20: and its deployed verify removes land/verifying"
_lg_reset; mkdir -p "$LAND"; : > "$LAND/verifying"; _lg_prs "$(_lg_pr 42)"; _lg_green 42
printf '/bin/bash /x/engine/harness/tests/run\n' > "$LGK/procs"; _lg_land --tick
is "A20: a leftover land/verifying with a suite running: one deploy-owed row, nothing installed, nothing merged" \
   "$(_lg_n deploy-owed)|$(_lg_ninst)|$(_lg_merges)" "1|0|"
[ -e "$LAND/verifying" ] && ok "A20: and land/verifying stays" || bad "A20: and land/verifying stays" "it is gone"
_lg_cache "$L4V"

# -------------------------------------------------------------------- A21 ---
rm -rf "$LGV/$L4V"; _lg_reset; _lg_prs "$(_lg_pr 42)"; _lg_green 42; _lg_land --tick
is "A21: (control) an owed deploy with nothing untracked in the home's engine ends deployed" \
   "$(_lg_n deployed)|$(( $(_lg_n deploy-failed) + $(_lg_n deployed-unverified) ))" "1|0"
rm -rf "$LGV/$L4V"; _lg_reset; _lg_prs "$(_lg_pr 42)"; _lg_green 42
printf 'not main\n' > "$LGH/engine/harness/a21-extra.txt"; _lg_land --tick
# A24, later, stops this deploy before its install with a deploy-owed row; A21
# alone ended it deploy-failed. Under either it is never deployed.
is "the land fixture: the file is untracked in the home (fixture control)" \
   "$(git -C "$LGH" status --porcelain -- engine 2>&1 | tr '\n' '|')" "?? engine/harness/a21-extra.txt|"
is "A21, A24: an untracked file under the home's engine/harness at deploy time never ends deployed" \
   "$(_lg_n deployed)|$(( $(_lg_n deploy-failed) + $(_lg_n deploy-owed) ))" "0|1"
[ -s "$LAND/paused" ] && ok "A21: and writes paused" || bad "A21: and writes paused" "no paused"
is "A21: and merges nothing" "$(_lg_merges)" ""
rm -f "$LGH/engine/harness/a21-extra.txt"; _lg_cache "$L4V"

# -------------------------------------------------------------------- A22 ---
_l4_np() {   # LEDGER -> felix land --tick where no project resolves, FELIX_LAND_LEDGER as given
  ( cd "$L4/noproj" || exit 97
    exec env -u FELIX_ALLOW_RED -u FELIX_KERNEL -u FELIX_KERNEL_CACHE HOME="$LGU" FELIX_HOME="$LGH" FELIX_HOME_DIR="$LGH" \
      FELIX_MEMORY="$LGM" FELIX_PLUGIN_CACHE="$LGC" FELIX_LAND_LEDGER="$1" PATH="$LGB:$PATH" "$FELIX" land --tick ) > "$LG/out" 2>&1
}
_lg_reset; rm -f "$L4/carried.tsv"; _l4_np "$L4/carried.tsv"; _l4_np "$L4/carried.tsv"
is "A22: a tick that cannot resolve its project writes one row into FELIX_LAND_LEDGER over two identical runs, and sends one notification" \
   "$(awk 'END { print NR }' "$L4/carried.tsv" 2>/dev/null)|$(_lg_cnt osa)" "1|1"
_l4o="$(LC_ALL=C awk -F'\t' 'NF != 7' "$L4/carried.tsv" 2>/dev/null | wc -l | tr -d ' ')"
is "A22: and that row is one of seven tab-separated fields" "$_l4o" "0"
_lg_reset; rm -f "$L4/elsewhere.tsv"; printf '1\n' > "$LGK/gh-auth.rc"; LGX=("FELIX_LAND_LEDGER=$L4/elsewhere.tsv"); _lg_land --tick; LGX=()
is "A22: a tick that resolves its project writes to its own ledger, not to FELIX_LAND_LEDGER" \
   "$(_lg_n gh)|$([ -e "$L4/elsewhere.tsv" ] && echo written)" "1|"
# The trampoline, as launchd runs it, runs main's entry, whose land execs a
# tick from a directory no project resolves.
_lg_put "$L4/land.exec" <<'L4STUB'
#!/bin/bash
LG='@LG@'
printf '%s\t%s\n' "${FELIX_LAND_LEDGER-unset}" "$(pwd -P)" >> "$LG/log/landexec.log"
cd "$LG/round4/noproj" || exit 97
exec env -u FELIX_ALLOW_RED -u FELIX_KERNEL -u FELIX_KERNEL_CACHE FELIX_HOME="$LG/home" FELIX_MEMORY="$LG/mem" \
  FELIX_PLUGIN_CACHE="$LG/cache" "$(cat "$LG/round4/felix.path")" land --tick
L4STUB
printf '%s\n' "$FELIX" > "$L4/felix.path"
_lg_reset; cp "$L4/land.exec" "$LGK/land.exec"; _la_tramp; _la_tramp
is "the land fixture: both trampoline runs ran main's entry, whose land ran the tick from no project (fixture control)" \
   "$(_la_ticks)|$(_lg_logs felix | LC_ALL=C awk -F'\t' '$3 == "land --tick" { print $1 }' | LC_ALL=C sort -u)|$(_lg_cnt landexec)" "2|$L4E|2"
_l4l="$(_lg_logs landexec | cut -f1 | LC_ALL=C sort -u)"
_l4p="$(cd -P "$(dirname "$_l4l")" 2>/dev/null && pwd -P)/${_l4l##*/}"
is "A22: the trampoline exports the ledger it carries as FELIX_LAND_LEDGER, the same on both runs" "$_l4p" "$LAND/ledger.tsv"
is "A22: the trampoline's unresolved tick leaves one row in that ledger, and one notification, across two runs" \
   "$(_lg_rows)|$(_lg_cnt osa)" "1|1"

_lg_reset; _lg_land --uninstall; _fx_git "$LGH" tag -d l4-keep >/dev/null 2>&1
