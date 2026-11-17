# >>> land-on-green-round-3
printf '\nland on green: the amendments A8-A16 (contract A8-A16, blind)\n'
# Blind, from the contract's "Amended after the second review" alone, on the
# fixture parts 1280-1282 build: lib/green-tick.sh, lib/green-install.sh,
# felix_land and cmd_land were not read. What the contract leaves open is not
# asserted: the event and words of A10's rows, and where a tick that cannot
# resolve its project keeps a ledger. A15's watchdog half has no seam that
# shortens 30 minutes, and is skipped. The lock-takeover half is driven through
# mv as PATH finds it, and skipped when the takeover does not rename that way.
_lg_build amend
L3="$LG/round3"; mkdir -p "$L3/noproj"
L3TR="$LGU/Library/Application Support/felix/land/lgh/tick"
_l3_mc() { _lg_merges | wc -w | tr -d ' '; }
_l3_tramp() {   # HOME-DIR -> the trampoline as launchd runs it, FELIX_HOME_DIR as given; status in L3RC
  ( cd "$TMP/cwd" 2>/dev/null || cd "$LG" || exit 97
    exec env -i HOME="$LGU" FELIX_HOME_DIR="$1" PATH="$LGB:$PATH" GIT_CEILING_DIRECTORIES="${GIT_CEILING_DIRECTORIES-}" \
      "$L3TR" ) > "$LG/out.tramp" 2>&1
  L3RC=$?
}
_fx_git "$LGH" fetch -q origin >/dev/null 2>&1; _fx_git "$LGH" checkout -q main >/dev/null 2>&1
_fx_git "$LGH" reset -q --hard origin/main >/dev/null 2>&1
L3V="$(_l3_mainv)"; [ -n "$L3V" ] && _lg_cache "$L3V"
is "the land fixture: the home is on main at origin's main, which declares a version whose entry main's check accepts (fixture control)" \
   "$(git -C "$LGH" rev-parse HEAD 2>&1)|$(git -C "$LGH" rev-parse --abbrev-ref HEAD 2>&1)|$([ -n "$L3V" ] && echo v)|$(_la_accepts)" \
   "$(git -C "$LGO" rev-parse main 2>&1)|main|v|0"
L3E="$LGV/$L3V/harness/felix"

# -------------------------------------------------------------------- A16 ---
_lg_reset; _lg_land --install
_l3p="$( { tr -d ' \t\r\n' < "$LGU/Library/LaunchAgents/felix.land.lgh.plist"; } 2>/dev/null)"
has "A16: the plist's PATH is the fixture HOME's .local/bin, then the listed directories" "$_l3p" \
    "<key>PATH</key><string>$(printf '%s' "$LGU" | tr -d ' ')/.local/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin</string>"
case "$_l3p" in *'$HOME'*|*'~/'*) bad "A16: with HOME expanded when it is written" "[$_l3p]" ;; *) ok "A16: with HOME expanded when it is written" ;; esac

# --------------------------------------------------------------------- A8 ---
# A commit no one pushed declares 9.8.0, and its lib/resolve.sh is main's with
# a check appended that accepts anything. 9.8.0's cache entry holds a felix
# that logs its path like every other, and an engine that is not that commit's.
_fx_git "$LGH" worktree add -q -b l3-rogue "$L3/rogue" main >/dev/null 2>&1
printf '{ "name": "felix", "version": "9.8.0" }\n' > "$L3/rogue/engine/.claude-plugin/plugin.json"
printf 'core rogue\n' > "$L3/rogue/engine/harness/lib/core.sh"
cat >> "$L3/rogue/engine/harness/lib/resolve.sh" <<'L3ROGUE'

# A branch's check that accepts anything.
felix_accepted_deploy_diff() { printf '%s\n' "${FELIX_KERNEL_CACHE:-${FELIX_PLUGIN_CACHE:-$HOME/.claude/plugins/cache}/felix/felix}/9.8.0"; return 0; }
L3ROGUE
_fx_git "$L3/rogue" -c user.name=t -c user.email=t@t commit -qam rogue >/dev/null 2>&1
L3X="$(git -C "$L3/rogue" rev-parse HEAD 2>/dev/null)"
_fx_git "$LGH" worktree remove --force "$L3/rogue" >/dev/null 2>&1; _lg_cache 9.8.0
L3M="$(git -C "$LGH" rev-parse refs/remotes/origin/main 2>/dev/null)"
_l3_a8() {   # WHAT -> the trampoline and the tick, with a ref named origin/main at the rogue commit
  is "the land fixture: origin/main, short, names the rogue commit; refs/remotes/origin/main does not (fixture control, $1)" \
     "$(git -C "$LGH" rev-parse origin/main 2>/dev/null)|$(git -C "$LGH" rev-parse refs/remotes/origin/main 2>/dev/null)" "$L3X|$L3M"
  _lg_reset; _l3_tramp "$LGH"
  is "A8: with $1, the trampoline runs main's accepted entry, not the one the short name declares" \
     "$(_la_ticks)|$(_lg_logs felix | LC_ALL=C awk -F'\t' '$3 == "land --tick" { print $1 }')" "1|$L3E"
  is "A8: with $1, the trampoline writes no deploy-owed row" "$(_lg_n deploy-owed)" "0"
  _lg_reset; _lg_prs "$(_lg_pr 42)"; _lg_green 42; _lg_land --tick
  is "A8: with $1, the tick compares main's version: no deploy is owed, and a green pull request merges" \
     "$(_lg_n deploy-owed)|$(_lg_merges)" "0|b42"
  is "A8: with $1, felix merge is main's entry's, and nothing at 9.8.0 runs" "$(_l3_mpath)" "$L3E "
  [ -e "$LAND/paused" ] && bad "A8: with $1, nothing is paused" "[$(cat "$LAND/paused")]" || ok "A8: with $1, nothing is paused"
}
_lg_reset; _lg_prs "$(_lg_pr 42)"; _lg_green 42; _lg_land --tick
is "the land fixture: with no ref named origin/main, a green pull request merges through main's entry (fixture control)" \
   "$(_lg_merges)|$(_l3_mpath)" "b42|$L3E "
_fx_git "$LGH" tag origin/main "$L3X" >/dev/null 2>&1
_l3_a8 "a tag named origin/main"
_fx_git "$LGH" tag -d origin/main >/dev/null 2>&1; _fx_git "$LGH" branch -q origin/main "$L3X" >/dev/null 2>&1
_l3_a8 "a local branch named origin/main"
_fx_git "$LGH" branch -q -D origin/main l3-rogue >/dev/null 2>&1; rm -rf "$LGV/9.8.0"

# -------------------------------------------------------------------- A10 ---
_lg_reset; _l3_tramp "$L3/no-home"; _l3_tramp "$L3/no-home"
is "A10: a trampoline that cannot enter FELIX_HOME_DIR runs no felix land --tick" "$(_la_ticks)" "0"
is "A10: and writes one row into the ledger written into it, over two identical runs" "$(_lg_rows)" "1"
is "A10: and sends one notification, over two identical runs" "$(_lg_cnt osa)" "1"
_lg_reset
( cd "$L3/noproj" || exit 97
  exec env -u FELIX_ALLOW_RED -u FELIX_KERNEL -u FELIX_KERNEL_CACHE HOME="$LGU" FELIX_HOME="$LGH" FELIX_HOME_DIR="$LGH" \
    FELIX_MEMORY="$LGM" FELIX_PLUGIN_CACHE="$LGC" PATH="$LGB:$PATH" "$FELIX" land --tick ) > "$LG/out" 2>&1
is "A10: a tick that cannot resolve its project sends a notification" "$(_lg_cnt osa)" "1"
skip "A10: and writes a row" "the contract names no ledger for a tick with no project"
_lg_reset; printf '1\n' > "$LGK/gh-auth.rc"; _lg_land --tick; _lg_land --tick
is "A10: gh auth status failing is written once and notified once over two identical ticks" "$(_lg_n gh)|$(_lg_cnt osa)" "1|1"
_lg_put "$LGB/git" <<'LGSTUB'
#!/bin/bash
LG='@LG@'; s=""; k=""
for a in "$@"; do
  if [ -n "$k" ]; then k=""; continue; fi
  case "$a" in -C|-c|--git-dir|--work-tree|--namespace|--config-env) k=1 ;; -*) ;; *) s="$a"; break ;; esac
done
if [ "$s" = fetch ] && [ -f "$LG/ctl/fetch.rc" ]; then
  printf 'fetch\n' >> "$LG/log/fetchfail.log"; echo "fatal: unable to access origin: Could not resolve host" >&2; exit "$(cat "$LG/ctl/fetch.rc")"
fi
exec "$(cat "$LG/amend/realgit")" "$@"
LGSTUB
_lg_reset; printf '128\n' > "$LGK/fetch.rc"; _lg_land --tick; _lg_land --tick; rm -f "$LGB/git"
is "the land fixture: the tick's fetch failed (fixture control)" "$([ "$(_lg_cnt fetchfail)" -ge 1 ] && echo yes)" "yes"
is "A10: a failing fetch is written once and notified once over two identical ticks" "$(_lg_rows)|$(_lg_cnt osa)" "1|1"
_la_names "A10: and its row names the fetch" "$(LC_ALL=C awk -F'\t' '{ d = $2 " " $7 } END { print d }' "$LAND/ledger.tsv" 2>/dev/null)" fetch
rm -rf "$LGV/$L3V"; _lg_reset; printf '/bin/bash /x/engine/harness/tests/run\n' > "$LGK/procs"
_lg_land --tick; _lg_land --tick
is "A10: a deploy owed is written once and notified once over two identical ticks" "$(_lg_n deploy-owed)|$(_lg_cnt osa)" "1|1"
_lg_cache "$L3V"

# -------------------------------------------------------------------- A11 ---
rm -rf "$LGV/$L3V"; _lg_reset; _lg_prs "$(_lg_pr 42)"; _lg_green 42; _lg_land --tick
is "A11: a tick that deploys, and verifies, merges nothing though a green candidate waits" "$(_lg_n deployed)|$(_lg_merges)" "1|"
_lg_land --tick
is "A11: the next tick merges it" "$(_lg_n landed 42)|$(_lg_merges)" "1|b42"
is "A11: with the engine just deployed" "$(_l3_mpath)" "$L3E "
rm -rf "$LGV/$L3V"; _lg_reset; _lg_prs "$(_lg_pr 42)"; _lg_green 42; printf '1\n' > "$LGK/gate.rc"; _lg_land --tick
is "A11: a tick whose deploy ends deploy-failed merges nothing" "$(_lg_n deploy-failed)|$(_lg_merges)" "1|"
_lg_cache "$L3V"

# -------------------------------------------------------------------- A12 ---
_lg_reset; _lg_prs "$(_lg_pr 42 false '[]' MERGEABLE false release)"; _lg_green 42; _lg_land --tick
is "A12: a green pull request into release, not main, gets one skip row and is not merged" "$(_lg_n skip 42)|$(_lg_merges)" "1|"
_la_names "A12: and the skip row names the base" "$(_lg_f skip 42 7)" base release main
has "A12: the tick asks gh pr list for baseRefName" "$(_lg_logs gh | grep '^pr list' | head -1)" baseRefName

# -------------------------------------------------------------------- A13 ---
_lg_reset; _lg_prs "$(_lg_pr 40)"; _lg_green 40
printf 'felix merge: refused\n  blocker: the receipt is stale\n' > "$LGK/merge.b40.out"; printf '1\n' > "$LGK/merge.b40.rc"
_lg_land --tick; _l3a="$(_l3_mc)"; _lg_land --tick
is "A13: a refused pull request is not passed to felix merge again on a tick with the same head and main" \
   "$_l3a|$(_l3_mc)|$(_lg_n refused 40)" "1|1|1"
_l3h="$(_lg_more b40 notes/b40.md)"
LC_ALL=C awk -F'\t' -v OFS='\t' -v s="$_l3h" '$1 == "40" { $2 = s } { print }' "$LG/shas" > "$L3/shas" && mv "$L3/shas" "$LG/shas"
_lg_prs "$(_lg_pr 40)"; _lg_green 40; _lg_land --tick; _l3a="$(_l3_mc)"; _lg_land --tick
is "A13: once its head moves, felix merge runs once more, and not again on the tick after" "$_l3a|$(_l3_mc)" "2|2"
_l3_commit notes/l3-a13.md a13; _lg_land --tick; _l3a="$(_l3_mc)"; _lg_land --tick
is "A13: once refs/remotes/origin/main moves, felix merge runs once more, and not again on the tick after" "$_l3a|$(_l3_mc)" "3|3"

# -------------------------------------------------------------------- A14 ---
rm -rf "$LGV/$L3V"; _lg_reset; printf 'bash engine/harness/tests/run\n' > "$LGK/procs"; _lg_land --tick
is "A14: a suite started as bash engine/harness/tests/run, with no leading slash, makes the deploy wait" \
   "$(_lg_n deploy-owed)|$(_lg_ninst)|$(_lg_n deployed)" "1|0|0"
has "A14: and the row says a gate or suite is running" "$(_lg_f deploy-owed "" 7)" "a gate or suite is running"
[ -f "$L3/pgrep.1280" ] || mv "$LGB/pgrep" "$L3/pgrep.1280"
_lg_put "$LGB/pgrep" <<'LGSTUB'
#!/bin/bash
LG='@LG@'
if [ -f "$LG/ctl/pgrep.rc" ]; then printf '%s\n' "$*" >> "$LG/log/pgrep.log"; echo "pgrep: cannot read the process table" >&2; exit "$(cat "$LG/ctl/pgrep.rc")"; fi
exec "$LG/round3/pgrep.1280" "$@"
LGSTUB
rm -rf "$LGV/$L3V"; _lg_reset; printf '2\n' > "$LGK/pgrep.rc"; _lg_land --tick
is "the land fixture: the tick asked pgrep (fixture control)" "$([ "$(_lg_cnt pgrep)" -ge 1 ] && echo yes)" "yes"
is "A14: a pgrep that exits 2 counts as a suite running: the deploy waits" "$(_lg_n deploy-owed)|$(_lg_ninst)|$(_lg_n deployed)" "1|0|0"
_lg_cache "$L3V"

# --------------------------------------------------------------------- A9 ---
# Each path is a real commit on a worktree at the gated head; gh lists what it
# would, a tab or newline JSON-escaped, and a rename by its new path only.
_l3_commit "$(printf 'notes/na\303\257ve.md')" "a9 base"
_l3_br() { printf '%s\t%s\n' "$1" "$(_lg_branch "b$1" "$2")" >> "$LG/shas"; }
# This Mac's file system folds projectſ into projects, so a file written there
# is projects/lgh/CLAUDE.md: the hazard A9 names. 60's path goes into git's
# index without touching the disk.
_fx_git "$LGH" worktree add -q -b b60 "$LGW/b60" main >/dev/null 2>&1
_l3b="$(printf 'b60\n' | _fx_git "$LGW/b60" hash-object -w --stdin 2>/dev/null)"
_fx_git "$LGW/b60" update-index --add --cacheinfo "100644,$_l3b,$(printf 'project\305\277/lgh/CLAUDE.md')" >/dev/null 2>&1
_fx_git "$LGW/b60" -c user.name=t -c user.email=t@t commit -qm b60 >/dev/null 2>&1
printf '60\t%s\n' "$(git -C "$LGW/b60" rev-parse HEAD)" >> "$LG/shas"
_l3_br 61 "$(printf 'notes/caf\303\251.md')"
_l3_br 62 "$(printf 'notes/tab\there.md')"
_l3_br 63 "$(printf 'notes/new\nline.md')"
_l3_br 69 docs/notes.md
_fx_git "$LGH" worktree add -q -b b64 "$LGW/b64" main >/dev/null 2>&1
_fx_git "$LGW/b64" mv "$(printf 'notes/na\303\257ve.md')" notes/naive.md >/dev/null 2>&1
_fx_git "$LGW/b64" -c user.name=t -c user.email=t@t commit -qm b64 >/dev/null 2>&1
printf '64\t%s\n' "$(git -C "$LGW/b64" rev-parse HEAD)" >> "$LG/shas"
_l3o=""; for _l3k in 60 61 62 63; do _l3o="$_l3o$(git -C "$LGH" diff -z --no-renames --name-only refs/remotes/origin/main "b$_l3k" | tr '\0' '|')"; done
is "the land fixture: each of 60-63 changes exactly its one path, as git diff -z names it (fixture control)" "$_l3o" \
   "$(printf 'project\305\277/lgh/CLAUDE.md|notes/caf\303\251.md|notes/tab\there.md|notes/new\nline.md|')"
is "the land fixture: git diff -z --no-renames names a rename's old path and its new one (fixture control)" \
   "$(git -C "$LGH" diff -z --no-renames --name-only refs/remotes/origin/main b64 | tr '\0' '|')" "$(printf 'notes/naive.md|notes/na\303\257ve.md|')"
_l3_a9() {   # N GH-PATH WHAT -> one founder row, no merge
  _lg_reset; _lg_prs "$(_lg_pr "$1")"; _lg_green "$1"; printf '%s\n' "$2" > "$LGK/files.$1"; _lg_land --tick
  is "A9: a pull request whose changed path holds $3 gets one founder row and is not merged" "$(_lg_n founder "$1")|$(_lg_merges)" "1|"
}
_l3_a9 60 "$(printf 'project\305\277/lgh/CLAUDE.md')" "U+017F (projectſ/lgh/CLAUDE.md)"
_l3_a9 61 "$(printf 'notes/caf\303\251.md')" "a byte >= 0x80 (notes/café.md)"
_l3_a9 62 'notes/tab\there.md' "a tab"
_l3_a9 63 'notes/new\nline.md' "a newline"
_l3_a9 64 notes/naive.md "a byte >= 0x80 only in its old name, renamed away"
_lg_reset; _lg_prs "$(_lg_pr 69)"; _lg_green 69; printf 'docs/notes.md\n' > "$LGK/files.69"; _lg_land --tick
is "A9: a plain ASCII docs/notes.md still merges" "$(_lg_n founder 69)|$(_lg_n landed 69)|$(_lg_merges)" "0|1|b69"

# -------------------------------------------------------------------- A15 ---
# A live tick holds the lock, held inside gh auth status in a process group of
# its own. Its lock is set aside and a dead one put in its place. mv, as PATH
# finds it, puts the live tick's pid and started back into the lock the moment
# a second tick renames it aside, as a third tick taking the lock between the
# second's judgement and its rename would. The second must not take it.
skip "A15: the watchdog compares its tick's start time before it signals" "the contract gives no way to shorten 30 minutes"
_lg_put "$LGB/mv" <<'LGSTUB'
#!/bin/bash
LG='@LG@'; src=""
for a in "$@"; do case "$a" in -*) ;; *) src="$a"; break ;; esac; done
sw="$(cat "$LG/ctl/mv-swap" 2>/dev/null)"
case "$src" in */land/lock|*/land/lock/|lock|lock/|./lock)
  if [ -n "$sw" ] && [ -d "$sw" ] && mkdir "$LG/ctl/mv-swapped" 2>/dev/null; then
    cp "$sw/pid" "$src/pid"; cp "$sw/started" "$src/started"
  fi ;;
esac
exec /bin/mv "$@"
LGSTUB
sh -c 'exit 0' & L3DEAD=$!; wait "$L3DEAD"
_lg_reset; : > "$LGK/gh-block"; _la_bg held3; L3HB=$LABG; _l3i=0
while [ "$_l3i" -lt 100 ]; do
  { [ -s "$LAND/lock/pid" ] && [ -s "$LAND/lock/started" ] && [ -d "$LGK/gh-block-taken" ]; } && break
  kill -0 "$L3HB" 2>/dev/null || break
  sleep 0.1; _l3i=$((_l3i+1))
done
L3PID="$(cat "$LAND/lock/pid" 2>/dev/null)"
rm -rf "$L3/held-lock"; /bin/mv "$LAND/lock" "$L3/held-lock" 2>/dev/null
mkdir -p "$LAND/lock"; printf '%s\n' "$L3DEAD" > "$LAND/lock/pid"; cat "$L3/held-lock/started" > "$LAND/lock/started" 2>/dev/null
printf '%s\n' "$L3/held-lock" > "$LGK/mv-swap"; _lg_land --tick
if [ -n "$L3PID" ] && kill -0 "$L3PID" 2>/dev/null; then L3LIVE=1; else L3LIVE=0; fi
is "the land fixture: a live tick held the lock while the second ran (fixture control)" "$L3LIVE holder [$L3PID]" "1 holder [$L3PID]"
if [ "$L3LIVE" != 1 ]; then
  :
elif [ ! -d "$LGK/mv-swapped" ]; then
  skip "A15: a takeover that finds another pid in the lock it moved aside does not take it" "the takeover did not rename the lock through PATH's mv"
else
  is "A15: a takeover that finds another pid in the lock it moved aside does not take it: only the live tick asked gh" \
     "$(_lg_logs gh | grep -c '^auth status')" "1"
  kill -0 "$L3PID" 2>/dev/null && ok "A15: and the live tick is not signalled" || bad "A15: and the live tick is not signalled" "$L3PID is gone"
fi
rm -f "$LGB/mv" "$LGK/mv-swap"
_l3pg="$(ps -o pgid= -p "${L3PID:-0}" 2>/dev/null | tr -d ' ')"; _l3me="$(ps -o pgid= -p "$$" 2>/dev/null | tr -d ' ')"
case "$_l3pg" in ""|*[!0123456789]*|0|1) _l3pg="" ;; esac
[ "$_l3pg" = "$_l3me" ] && _l3pg=""
if [ -n "$_l3pg" ]; then kill -TERM -- "-$_l3pg" 2>/dev/null
elif [ -n "$L3PID" ]; then kill -TERM "$L3PID" 2>/dev/null; else kill -TERM "$L3HB" 2>/dev/null; fi
rm -f "$LGK/gh-block"; _la_reap "$L3HB"; [ -z "$L3PID" ] || _la_reap "$L3PID"
_lg_reset; _lg_land --uninstall
