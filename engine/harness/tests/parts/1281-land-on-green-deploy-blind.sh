# >>> land-on-green-deploy
printf '\nland on green: deploy what main holds, and install the job (contract G3, G7, G9, blind)\n'
# Blind, written from docs/2026-10-15-land-on-green-contract.md alone on
# 2026-10-15, with part 1280, on the fixture 1280 builds. Nothing here was read
# off an implementation.
#
# A deploy is made owed by taking main's entry out of the cache, by putting a
# stray file in it, or by pushing a newer version to origin/main. The home's
# felix stub answers install by copying the home's engine/harness into the
# cache under the version the home declares, so a deploy that pulls before it
# installs leaves the new version there. "A gate is running" is a line in
# ctl/procs that the pgrep stub matches with grep -E. The contract does not say
# whether a tick that completes an owed deploy goes on to merge in the same
# tick, so the deploy scenarios list no pull request where that would matter.
_lg_build after-1280
_lg_paused_same() {   # WHAT EVENT -> paused holds the reason the EVENT row gives
  local p d; p="$(cat "$LAND/paused" 2>/dev/null)"; d="$(_lg_f "$2" "" 7)"
  if [ -n "$p" ] && [ -n "$d" ] && { case "$d" in *"$p"*) true ;; *) case "$p" in *"$d"*) true ;; *) false ;; esac ;; esac; }; then
    ok "G7: $1 also writes paused with the same reason"
  else bad "G7: $1 also writes paused with the same reason" "paused [$p], row [$d]"; fi
}

_lg_reset; rm -rf "$LGV/9.0.0"; ( cd "$LGH" && "$LGH/engine/harness/felix" install --no-bump >/dev/null 2>&1 )
is "the land fixture: the home's felix stub installs its engine into the cache under the home's version (fixture control)" \
   "$(diff -rq "$LGV/9.0.0/harness" "$LGH/engine/harness" 2>&1 | wc -l | tr -d ' ')" "0"
_lg_cache 9.0.0

# --------------------------------------------------------------------- G3 ---
_lg_reset; rm -rf "$LGV/9.0.0"; _lg_prs "$(_lg_pr 42)"; _lg_green 42
printf '/bin/bash /Users/someone/Felix/engine/harness/tests/run\n' > "$LGK/procs"
_lg_land --tick
is "G3, G7: with main's version missing from the cache and a suite running, the tick exits 0" "$LGRC" 0
is "G7: it writes one deploy-owed row" "$(_lg_n deploy-owed)" "1"
has "G7: reading a gate or suite is running" "$(_lg_f deploy-owed "" 7)" "a gate or suite is running"
is "G3: while a deploy is owed, nothing is merged" "$(_lg_merges)" ""
is "G7: and nothing is installed" "$(_lg_ninst)" "0"
case "$(_lg_logs pgrep)" in *-f*) ok "G7: the running suite is looked for with pgrep -f" ;;
  *) bad "G7: the running suite is looked for with pgrep -f" "pgrep saw: $(_lg_logs pgrep | head -3 | tr '\n' '|')" ;; esac
_lg_reset; _lg_prs "$(_lg_pr 42)"; _lg_green 42; printf '/bin/bash /Users/someone/Felix/gate.sh widget\n' > "$LGK/procs"
_lg_land --tick
is "G7: a running /gate.sh also leaves the deploy owed" "$(_lg_n deploy-owed)$(_lg_merges)$(_lg_ninst)" "10"
_lg_cache 9.0.0; printf 'stray\n' > "$LGV/9.0.0/harness/stray"
_lg_reset; _lg_prs "$(_lg_pr 42)"; _lg_green 42; printf '/bin/bash /x/engine/harness/tests/run\n' > "$LGK/procs"
_lg_land --tick
is "G3: a cache entry that diff -rq finds different from origin/main's engine/harness owes a deploy, and nothing merges" \
   "$(_lg_n deploy-owed)$(_lg_merges)" "1"
_lg_cache 9.0.0

# --------------------------------------------------------------------- G7 ---
rm -rf "$LGV/9.0.0"; _lg_reset
_fx_git "$LGH" checkout -q -b side >/dev/null 2>&1
_lg_land --tick
is "G7: with a deploy owed and the home off main, the tick exits 0 with one deploy-owed row" "$LGRC$(_lg_n deploy-owed)" "01"
_lg_paused_same "a home off main" deploy-owed
is "G7: and installs nothing" "$(_lg_ninst)" "0"
_fx_git "$LGH" checkout -q main >/dev/null 2>&1; _fx_git "$LGH" branch -q -D side >/dev/null 2>&1
_lg_reset; printf 'a tracked change\n' >> "$LGH/README.md"
_lg_land --tick
is "G7: with the home holding a tracked change, one deploy-owed row" "$LGRC$(_lg_n deploy-owed)" "01"
_lg_paused_same "a dirty home" deploy-owed
is "G7: and installs nothing" "$(_lg_ninst)" "0"
_fx_git "$LGH" checkout -q -- README.md >/dev/null 2>&1

_lg_reset; printf 'not tracked\n' > "$LGH/untracked-note.txt"
_lg_land --tick
is "G7: an untracked file in the home is no tracked change: the owed deploy runs and writes deployed" \
   "$LGRC$(_lg_n deploy-owed)$(_lg_n deployed)" "001"
is "G7: install runs once, as the home's engine/harness/felix install --no-bump, from the home" \
   "$(_lg_ninst)|$(_lg_inst | cut -f1-3 | tr '\t' '|')" "1|$LGH/engine/harness/felix|$LGH|install --no-bump"
_lgo="$(_lg_logs hook | head -1)"
is "G7: the verify runs the home's hooks/session-start" "$(printf '%s' "$_lgo" | cut -f1)" "$LGH/engine/harness/hooks"
has "G7: and hands it the stub payload's session_id, felix-land-verify" "$_lgo" '"session_id":"felix-land-verify"'
has "G7: and hands it the stub payload's source, startup" "$_lgo" '"source":"startup"'
has "G7: and hands it the stub payload's cwd, the home" "$_lgo" "\"cwd\":\"$LGH\""
is "G7: the verify runs felix gate --quick in the home" \
   "$(_lg_logs felix | LC_ALL=C awk -F'\t' -v h="$LGH" '$3 == "gate --quick" && $2 == h' | wc -l | tr -d ' ')" "1"
_lg_osa 'with title "Felix: deployed' "G8: the deployed row is sent titled Felix: deployed"
[ -f "$LAND/paused" ] && bad "G7: a verified deploy writes no paused" "[$(cat "$LAND/paused")]" || ok "G7: a verified deploy writes no paused"
rm -f "$LGH/untracked-note.txt"
_lg_unv() {   # WORD WHAT -> a failed check writes deploy-failed naming it, and paused
  _lg_land --tick
  is "G7: when $2 fails, the tick writes one deploy-failed row and no deployed row" \
     "$LGRC$(_lg_n deploy-failed)$(_lg_n deployed)" "010"
  has "G7: naming the check, $2" "$(_lg_lc "$(_lg_f deploy-failed "" 7)")" "$1"
  _lg_paused_same "a deploy-failed for $2" deploy-failed
  _lg_osa 'with title "Felix: deploy-failed' "G8: the deploy-failed row for $2 is sent as a notification"
}
rm -rf "$LGV/9.0.0"; _lg_reset; printf '1\n' > "$LGK/hook.rc"; _lg_unv session-start "the session-start hook"
rm -rf "$LGV/9.0.0"; _lg_reset; printf '1\n' > "$LGK/gate.rc"; _lg_unv gate "felix gate --quick"
rm -rf "$LGV/9.0.0"; _lg_reset; : > "$LGK/install.taint"; _lg_unv diff "the diff of the cache entry against the home"
_lg_cache 9.0.0

# origin/main moves ahead of the home: the version it declares is not in the
# cache, so the tick pulls and installs that version.
_fx_git "$LGH" worktree add -q -b ahead "$LGW/ahead" main >/dev/null 2>&1
printf 'core 1\n' > "$LGW/ahead/engine/harness/lib/core.sh"
printf '{ "name": "felix", "version": "9.0.1" }\n' > "$LGW/ahead/engine/.claude-plugin/plugin.json"
_fx_git "$LGW/ahead" -c user.name=t -c user.email=t@t commit -qam ahead >/dev/null 2>&1
_fx_git "$LGW/ahead" push -q origin HEAD:main >/dev/null 2>&1
_fx_git "$LGH" worktree remove --force "$LGW/ahead" >/dev/null 2>&1; _fx_git "$LGH" branch -q -D ahead >/dev/null 2>&1
is "the land fixture: origin/main now declares 9.0.1 and the home's main does not (fixture control)" \
   "$(git -C "$LGO" show main:engine/.claude-plugin/plugin.json 2>&1 | tr -d '\n') $(git -C "$LGH" show main:engine/.claude-plugin/plugin.json 2>&1 | tr -d '\n')" \
   '{ "name": "felix", "version": "9.0.1" } { "name": "felix", "version": "9.0.0" }'
_lg_reset; _lg_land --tick
is "G3: the version read is origin/main's: a newer one there is deployed" "$LGRC$(_lg_n deployed)" "01"
is "G7: the home is pulled to origin/main first" "$(git -C "$LGH" rev-parse HEAD 2>&1)" "$(git -C "$LGO" rev-parse main 2>&1)"
is "G7: and the install that follows puts origin/main's engine in the cache under its version" \
   "$(cat "$LGV/9.0.1/harness/lib/core.sh" 2>/dev/null)" "core 1"

# A landing that changes engine/ deploys after it lands.
_fx_git "$LGH" worktree add -q -b b51 "$LGW/b51" main >/dev/null 2>&1
printf 'core 2\n' > "$LGW/b51/engine/harness/lib/core.sh"
printf '{ "name": "felix", "version": "9.0.2" }\n' > "$LGW/b51/engine/.claude-plugin/plugin.json"
_fx_git "$LGW/b51" -c user.name=t -c user.email=t@t commit -qam b51 >/dev/null 2>&1
printf '51\t%s\n' "$(git -C "$LGW/b51" rev-parse HEAD)" >> "$LG/shas"
_lg_reset; _lg_prs "$(_lg_pr 51)"; _lg_green 51; : > "$LGK/merge.b51.push"
printf 'engine/harness/lib/core.sh\nengine/.claude-plugin/plugin.json\n' > "$LGK/files.51"
_lg_land --tick
is "G7: a landing whose changed paths include engine/ lands, then deploys" \
   "$(LC_ALL=C awk -F'\t' '$2 == "landed" || $2 == "deployed" { printf "%s ", $2 }' "$LAND/ledger.tsv" 2>/dev/null)" "landed deployed "
is "G7: installing once, the version the landing brought" "$(_lg_ninst)|$(cat "$LGV/9.0.2/harness/lib/core.sh" 2>/dev/null)" "1|core 2"

# --------------------------------------------------------------------- G9 ---
_lg_reset; LGUID="$(id -u)"
LGPL="$LGU/Library/LaunchAgents/felix.land.lgh.plist"; LGTR="$LGU/Library/Application Support/felix/land/lgh/tick"
_lg_land --install
is "G9: --install exits 0" "$LGRC" 0
[ -f "$LGPL" ] && ok "G9: --install writes ~/Library/LaunchAgents/felix.land.<p>.plist" \
  || bad "G9: --install writes ~/Library/LaunchAgents/felix.land.<p>.plist" "no $LGPL"
[ -f "$LGTR" ] && [ -x "$LGTR" ] && ok "G9: and an executable trampoline at ~/Library/Application Support/felix/land/<p>/tick" \
  || bad "G9: and an executable trampoline at ~/Library/Application Support/felix/land/<p>/tick" "no $LGTR"
_lgp="$( { tr -d ' \t\r\n' < "$LGPL"; } 2>/dev/null)"
has "G9: the plist's label is felix.land.<p>" "$_lgp" "<key>Label</key><string>felix.land.lgh</string>"
has "G9: its StartInterval is 300" "$_lgp" "<key>StartInterval</key><integer>300</integer>"
has "G9: RunAtLoad is true" "$_lgp" "<key>RunAtLoad</key><true/>"
has "G9: ProcessType is Interactive" "$_lgp" "<key>ProcessType</key><string>Interactive</string>"
case "$_lgp" in *LowPriorityIO*) bad "G9: it sets no LowPriorityIO" "$_lgp" ;; *) ok "G9: it sets no LowPriorityIO" ;; esac
# A16 amends G9's PATH: the fixture HOME's .local/bin comes first.
has "G9: it sets the explicit PATH" "$_lgp" "<key>PATH</key><string>$(printf '%s' "$LGU" | tr -d ' ')/.local/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin</string>"
has "G9: its EnvironmentVariables name FELIX_HOME_DIR as the home" "$_lgp" "<key>EnvironmentVariables</key><dict>"
has "G9: FELIX_HOME_DIR is the home" "$_lgp" "<key>FELIX_HOME_DIR</key><string>$(printf '%s' "$LGH" | tr -d ' ')</string>"
has "G9: its stdout goes to land/launchd.log" "$_lgp" "<key>StandardOutPath</key><string>$LAND/launchd.log</string>"
has "G9: its stderr goes to land/launchd.log" "$_lgp" "<key>StandardErrorPath</key><string>$LAND/launchd.log</string>"
has "G9: it runs the trampoline" "$_lgp" "$(printf '%s' "$LGTR" | tr -d ' ')"
if command -v plutil >/dev/null 2>&1; then
  plutil -lint -s "$LGPL" >/dev/null 2>&1 && ok "G9: the plist is one plutil reads" || bad "G9: the plist is one plutil reads" "$(plutil -lint "$LGPL" 2>&1 | head -2)"
else skip "G9: the plist is one plutil reads" "no plutil on this machine"; fi
has "G9: --install bootstraps it with launchctl bootstrap gui/<uid> <plist>" "$(_lg_logs launchctl)" "bootstrap gui/$LGUID $LGPL"
: > "$LGK/loaded"; _lg_land --status --tsv
is "G9: --status --tsv says installed yes and loaded yes once installed and loaded" \
   "$(sed -n 1,2p "$LG/out" | tr '\t\n' ':|')" "installed:yes|loaded:yes|"
rm -f "$LGK/loaded"; _lg_land --status --tsv
is "G9: and loaded no when launchctl does not have it" "$(sed -n 2p "$LG/out")" "$(printf 'loaded\tno')"

# The trampoline, run as launchd would: an empty environment but for HOME,
# FELIX_HOME_DIR and PATH, from a directory that is not the home. The plugin
# cache is then $HOME/.claude/plugins/cache, which the fixture links to its own.
_fx_git "$LGH" fetch -q origin >/dev/null 2>&1; _fx_git "$LGH" checkout -q main >/dev/null 2>&1
_fx_git "$LGH" reset -q --hard origin/main >/dev/null 2>&1
_lg_tramp() { ( cd "$TMP/cwd" || exit 97
  exec env -i HOME="$LGU" FELIX_HOME_DIR="$LGH" PATH="$LGB:$PATH" GIT_CEILING_DIRECTORIES="$GIT_CEILING_DIRECTORIES" \
    "$LGTR" ) > "$LG/out.tramp" 2>&1; }
_lg_lt() { _lg_logs felix | LC_ALL=C awk -F'\t' '$3 == "land --tick"' | tail -1; }
_lgv="$(_lg_mainv)"; [ -n "$_lgv" ] && { [ -d "$LGV/$_lgv" ] || _lg_cache "$_lgv"; }
_lg_reset; _lg_tramp
is "G9: the trampoline runs the installed engine's felix land --tick at main's version" \
   "$(_lg_lt | cut -f1,3 | tr '\t' '|')" "$LGV/${_lgv:-none}/harness/felix|land --tick"
is "G1: the trampoline changes into FELIX_HOME_DIR before it runs" "$(_lg_lt | cut -f2)" "$LGH"
printf '{ "name": "felix", "version": "9.0.9" }\n' > "$LGH/engine/.claude-plugin/plugin.json"
_fx_git "$LGH" -c user.name=t -c user.email=t@t commit -qam bump >/dev/null 2>&1
_fx_git "$LGH" push -q origin main >/dev/null 2>&1; _lg_cache 9.0.9
_lg_reset; _lg_tramp
is "G9: it resolves main's version when it runs, not when it was installed" "$(_lg_lt | cut -f1)" "$LGV/9.0.9/harness/felix"
_lg_reset; _lg_land --uninstall
is "G9: --uninstall exits 0" "$LGRC" 0
has "G9: --uninstall runs launchctl bootout gui/<uid>/felix.land.<p>" "$(_lg_logs launchctl)" "bootout gui/$LGUID/felix.land.lgh"
{ [ -e "$LGPL" ] || [ -e "$LGTR" ]; } && bad "G9: and removes the plist and the trampoline" "one is left" \
  || ok "G9: and removes the plist and the trampoline"
_lg_land --uninstall
is "G9: --uninstall with nothing installed is not an error" "$LGRC" 0
