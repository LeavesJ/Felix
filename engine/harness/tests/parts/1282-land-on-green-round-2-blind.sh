# >>> land-on-green-round-2
printf '\nland on green: review round 1, and the amendments A1-A7 (contract G2-G9, A1-A7, blind)\n'
# Blind, on the fixture parts 1280 and 1281 build. The review round 1 section
# below is part 1280's, moved here verbatim when 1280 passed 500 lines. It ran
# before 1281 there and runs after it here, so the fixture is first put back
# the way 1280 leaves it: origin's main at the base commit, which declares
# 9.0.0, the home on main at it, and the cache holding 9.0.0 as a copy of the
# home's engine and no other entry 1281 installed.
_lg_build after-1280
_lgb2="$(git -C "$LGH" rev-parse "$(_lg_sha 21)^" 2>/dev/null)"
_fx_git "$LGH" push -q -f origin "$_lgb2:refs/heads/main" >/dev/null 2>&1
_fx_git "$LGH" fetch -q origin >/dev/null 2>&1; _fx_git "$LGH" checkout -q main >/dev/null 2>&1
_fx_git "$LGH" reset -q --hard origin/main >/dev/null 2>&1
rm -rf "$LGV/9.0.1" "$LGV/9.0.2" "$LGV/9.0.9"; _lg_cache 9.0.0; _lg_reset
is "the land fixture: origin's main is back at the base, declaring 9.0.0, and the home is on main at it (fixture control)" \
   "$(_lg_mainv)|$(git -C "$LGH" rev-parse HEAD 2>&1)|$(git -C "$LGH" rev-parse --abbrev-ref HEAD 2>&1)" "9.0.0|$_lgb2|main"

# ------------------------------------------------------- review round 1 ---
# Blind, from the contract and the review's findings alone; lib/green-tick.sh
# was not read. Each block cites the clause it holds the tick to, and leaves
# the fixture as part 1281 expects it: the home on main at origin/main, which
# declares 9.0.0, the cache holding 9.0.0 as a copy of the home's engine, and
# no trampoline installed.
LGV1="$LGC/felix/felix"
# 2026-10-18 (judge refs, Part C): the entry is compared whole, so it holds main's manifest too.
_lgr1_cache() { rm -rf "$LGV1/$1"; mkdir -p "$LGV1/$1/.claude-plugin"; cp -R "$LGH/engine/harness" "$LGV1/$1/harness"
                printf '{ "name": "felix", "version": "%s" }\n' "$1" > "$LGV1/$1/.claude-plugin/plugin.json"; }
_lgr1_home() {   # back to origin/main, and main's entry cached from it
  _fx_git "$LGH" fetch -q origin >/dev/null 2>&1; _fx_git "$LGH" checkout -q main >/dev/null 2>&1
  _fx_git "$LGH" reset -q --hard origin/main >/dev/null 2>&1; _lgr1_cache 9.0.0
}

# G3, G7.2, G7.4: while a deploy is owed and not completed, the tick merges
# nothing. A deploy that stops at a home off main, or whose verify fails, has
# not completed, and a green pull request with a matched worktree is listed.
rm -rf "$LGV1/9.0.0"; _lg_reset; _lg_prs "$(_lg_pr 42)"; _lg_green 42
_fx_git "$LGH" checkout -q -b side1 >/dev/null 2>&1
_lg_land --tick
is "G3, G7.2 (review 1): a deploy owed and stopped at a home off main merges nothing in that tick" \
   "$(_lg_n deploy-owed)|$(_lg_merges)" "1|"
_fx_git "$LGH" checkout -q main >/dev/null 2>&1; _fx_git "$LGH" branch -q -D side1 >/dev/null 2>&1
for _lgk in hook gate; do
  rm -rf "$LGV1/9.0.0"; _lg_reset; _lg_prs "$(_lg_pr 42)"; _lg_green 42; printf '1\n' > "$LGK/$_lgk.rc"
  _lg_land --tick
  is "G3, G7.4 (review 1): a deploy whose $_lgk check fails is not completed: deploy-failed, and nothing merges in that tick" \
     "$(_lg_n deploy-failed)|$(_lg_merges)" "1|"
done
_lgr1_home

# G3: the version is read from origin/main after a git fetch. origin's main is
# moved from a clone that is not the home, so the home's origin/main is stale
# until the tick fetches.
_fx_git "$LG" clone -q "$LGO" other1 >/dev/null 2>&1
_lgr1_base="$(git -C "$LGH" rev-parse HEAD 2>/dev/null)"
printf 'core r1\n' > "$LG/other1/engine/harness/lib/core.sh"
printf '{ "name": "felix", "version": "9.0.1" }\n' > "$LG/other1/engine/.claude-plugin/plugin.json"
_fx_git "$LG/other1" -c user.name=t -c user.email=t@t commit -qam r1 >/dev/null 2>&1
_fx_git "$LG/other1" push -q origin HEAD:main >/dev/null 2>&1
is "the land fixture: origin's main moved and the home's origin/main did not (fixture control)" \
   "$(git -C "$LGH" rev-parse origin/main 2>&1) $(git -C "$LGO" rev-parse main 2>&1 | cut -c1-7)" \
   "$_lgr1_base $(git -C "$LG/other1" rev-parse HEAD 2>&1 | cut -c1-7)"
_lg_reset; _lg_land --tick
is "G3 (review 1): the tick fetches before it reads origin/main's version: a main pushed from elsewhere is deployed" \
   "$(_lg_n deployed)|$(cat "$LGV1/9.0.1/harness/lib/core.sh" 2>/dev/null)" "1|core r1"
is "G3 (review 1): and the home's origin/main is origin's main after the tick" \
   "$(git -C "$LGH" rev-parse origin/main 2>&1)" "$(git -C "$LGO" rev-parse main 2>&1)"
_fx_git "$LG/other1" push -q -f origin "$_lgr1_base:refs/heads/main" >/dev/null 2>&1
rm -rf "$LG/other1" "$LGV1/9.0.1"; _lgr1_home

# G3 "Deploy what main already holds", G7.3 "The home's engine is main's": a
# home whose main holds an unpushed engine commit is not installed as main's,
# and no deployed row stands while the cache entry for origin/main's version
# still differs from origin/main's engine/harness, which G3 calls owed. What the
# tick does instead (a row, a pause) the contract does not say.
printf 'core local\n' > "$LGH/engine/harness/lib/core.sh"
_fx_git "$LGH" -c user.name=t -c user.email=t@t commit -qam unpushed >/dev/null 2>&1
rm -rf "$LGV1/9.0.0"; _lg_reset; _lg_land --tick
_lgo="$(cat "$LGV1/9.0.0/harness/lib/core.sh" 2>/dev/null)"
case "$_lgo" in "core local") bad "G3, G7.3 (review 1): an unpushed engine commit in the home is never installed as main's" "the cache entry holds [$_lgo]" ;;
  *) ok "G3, G7.3 (review 1): an unpushed engine commit in the home is never installed as main's" ;; esac
case "$(_lg_n deployed):$_lgo" in 0:*|*":core 0") ok "G3 (review 1): no deployed row while the cache entry differs from origin/main's engine/harness" ;;
  *) bad "G3 (review 1): no deployed row while the cache entry differs from origin/main's engine/harness" "deployed $(_lg_n deployed), cache core [$_lgo]" ;; esac
_lgr1_home

# G5: a pull request that renames a direction document away changes it, so it
# is held with a founder row. gh's files list names only the new path, as gh
# does for a rename.
_fx_git "$LGH" worktree add -q -b b36 "$LGW/b36" main >/dev/null 2>&1
_fx_git "$LGW/b36" mv projects/lgh/CLAUDE.md projects/lgh/CONSTITUTION.old >/dev/null 2>&1
_fx_git "$LGW/b36" -c user.name=t -c user.email=t@t commit -qm b36 >/dev/null 2>&1
printf '36\t%s\n' "$(git -C "$LGW/b36" rev-parse HEAD)" >> "$LG/shas"
_lg_reset; _lg_prs "$(_lg_pr 36)"; _lg_green 36; printf 'projects/lgh/CONSTITUTION.old\n' > "$LGK/files.36"
_lg_land --tick
is "G5 (review 1): a pull request that renames projects/*/CLAUDE.md away is held with a founder row and not merged" \
   "$(_lg_n founder 36)|$(_lg_merges)" "1|"
_fx_git "$LGH" worktree remove --force "$LGW/b36" >/dev/null 2>&1; _fx_git "$LGH" branch -q -D b36 >/dev/null 2>&1

# G9: the trampoline runs main's version, resolved at run time, and never
# another. A candidate's newer entry sits in the cache, as every gated branch
# leaves one. With main's entry missing, or origin/main unreadable because git
# fails (exit 69, as after an Xcode update), it runs no other version's felix.
# What it does instead the contract does not say.
_lg_reset; _lg_land --install
LGTR1="$LGU/Library/Application Support/felix/land/lgh/tick"
mkdir -p "$LG/bin-nogit"; printf '#!/bin/sh\nexit 69\n' > "$LG/bin-nogit/git"; chmod +x "$LG/bin-nogit/git"
_lgr1_tramp() { ( cd "$TMP/cwd" 2>/dev/null || cd "$LG" || exit 97
  exec env -i HOME="$LGU" FELIX_HOME_DIR="$LGH" PATH="$1$LGB:$PATH" GIT_CEILING_DIRECTORIES="$GIT_CEILING_DIRECTORIES" \
    "$LGTR1" ) > "$LG/out.tramp" 2>&1; }
_lgr1_other() { _lg_logs felix | LC_ALL=C awk -F'\t' -v m="$LGV1/9.0.0/harness/felix" '$3 == "land --tick" && $1 != m { print $1 }' | head -3 | tr '\n' ' '; }
_lgr1_cache 9.1.0
[ -x "$LGTR1" ] && [ -x "$LGV1/9.1.0/harness/felix" ] && ok "the land fixture: a trampoline is installed and a candidate 9.1.0 sits in the cache (fixture control)" \
  || bad "the land fixture: a trampoline is installed and a candidate 9.1.0 sits in the cache (fixture control)" "no $LGTR1 or no candidate"
rm -rf "$LGV1/9.0.0"; _lg_reset; _lgr1_tramp ""
is "G9 (review 1): with main's entry missing, the trampoline runs no other version's felix land --tick" "$(_lgr1_other)" ""
_lgr1_cache 9.0.0; _lg_reset; _lgr1_tramp "$LG/bin-nogit:"
is "G9 (review 1): with git failing, the trampoline runs no felix land --tick but main's" "$(_lgr1_other)" ""
_lg_reset; _lgr1_tramp ""
is "the land fixture: with main's entry there and git working, the trampoline runs main's felix land --tick (fixture control)" \
   "$(_lg_logs felix | LC_ALL=C awk -F'\t' '$3 == "land --tick" { print $1 }' | tail -1)" "$LGV1/9.0.0/harness/felix"
_lg_reset; _lg_land --uninstall; rm -rf "$LGV1/9.1.0" "$LG/bin-nogit"; _lgr1_home

# ---------------------------------------------------- amendments A1-A7 ---
# Blind, from the amended contract alone: lib/green-tick.sh, cmd_land and the
# dispatcher's land code were not read. lib/resolve.sh's
# felix_accepted_deploy_diff and cmd_merge's judge block were, as A1 names them
# the check to reuse. What the contract leaves open is not asserted: a row's
# words beyond the case it names, and whether a tick that completes an owed
# deploy goes on to merge. Two bounds have no seam a test can move, 45 minutes
# for a stuck lock and 30 for the watchdog: those are skipped, and their
# testable halves asserted. The trampoline's ledger is the one felix_mem_dir
# names under launchd's environment, which the fixture links to its own.
_lg_build amend

# --------------------------------------------------------------------- A7 ---
_lg_reset; _lg_land --pause first second
is "A7: felix land --pause with two reasons prints usage and exits 2" "$LGRC" 2
[ -e "$LAND/paused" ] && bad "A7: and writes no paused file" "[$(cat "$LAND/paused")]" || ok "A7: and writes no paused file"

# --------------------------------------------------------------------- A1 ---
# The trampoline is run as launchd runs it. A candidate's newer entry, 9.1.0,
# sits in the cache throughout, as every gated branch leaves one.
_lg_reset; _lg_land --install; _lg_cache 9.1.0
: > "$LA/details"
_la_owed() {   # CASE PATH-PREFIX WORD... -> two runs in CASE run nothing and say it once
  local what="$1" pre="$2" r1 r2; shift 2
  _lg_reset; _la_tramp "$pre"; r1=$LARC; _la_tramp "$pre"; r2=$LARC
  is "A1: $what: the trampoline runs no felix land --tick, from any cache entry or tree" "$(_la_ticks)" "0"
  is "A1: $what: it exits 1, both runs" "$r1 $r2" "1 1"
  is "A1: $what: two runs write one deploy-owed row" "$(_lg_n deploy-owed)" "1"
  is "A1: $what: and send one notification" "$(_lg_cnt osa)" "1"
  _la_names "A1: $what: the row names the case" "$(_lg_f deploy-owed "" 7)" "$@"
  printf '%s\n' "$(_lg_f deploy-owed "" 7)" >> "$LA/details"
}
# The base commit 1280 builds holds lib/resolve.sh; main drops it here, so its
# check cannot be loaded, and gets it back below.
_fx_git "$LGH" rm -q engine/harness/lib/resolve.sh >/dev/null 2>&1
_fx_git "$LGH" -c user.name=t -c user.email=t@t commit -qm 'main without its resolve.sh' >/dev/null 2>&1
_fx_git "$LGH" push -q origin main >/dev/null 2>&1; _lg_cache 9.0.0
[ -x "$LATR" ] && ! git -C "$LGH" cat-file -e origin/main:engine/harness/lib/resolve.sh 2>/dev/null \
  && ok "the land fixture: a trampoline is installed, and origin/main holds no lib/resolve.sh yet (fixture control)" \
  || bad "the land fixture: a trampoline is installed, and origin/main holds no lib/resolve.sh yet (fixture control)" "no $LATR, or resolve.sh is there"
_la_owed "when main's check cannot be loaded (no lib/resolve.sh at origin/main)" "" load resolve accepted_deploy

cp "$REAL_HARNESS/lib/resolve.sh" "$LGH/engine/harness/lib/resolve.sh"
_fx_git "$LGH" add -A >/dev/null 2>&1
_fx_git "$LGH" -c user.name=t -c user.email=t@t commit -qm 'main holds its resolve.sh' >/dev/null 2>&1
_fx_git "$LGH" push -q origin main >/dev/null 2>&1; _lg_cache 9.0.0; _lg_cache 9.1.0
LAMAIN="$(git -C "$LGH" rev-parse origin/main 2>/dev/null)"
is "the land fixture: origin/main holds lib/resolve.sh, and its check accepts the 9.0.0 entry (fixture control)" "$(_la_accepts)" "0"
_lg_reset; _la_tramp
is "A1: an entry main's check accepts runs: its felix land --tick is the one tick invoked" \
   "$(_la_ticks)|$(_lg_logs felix | LC_ALL=C awk -F'\t' '$3 == "land --tick" { print $1 }')" "1|$LGV/9.0.0/harness/felix"
is "A1: and the trampoline writes no deploy-owed row" "$(_lg_n deploy-owed)" "0"

rm -rf "$LGV/9.0.0"
_la_owed "with main's entry missing" "" missing "not installed" "nothing is installed" "no entry" absent "no such"
_lg_cache 9.0.0; chmod -x "$LGV/9.0.0/harness/felix"
_la_owed "with main's entry not executable" "" execut
chmod +x "$LGV/9.0.0/harness/felix"
printf 'core of a branch\n' > "$LGV/9.0.0/harness/lib/core.sh"
is "the land fixture: a branch's install at main's version number sits in the cache, and main's check rejects it (fixture control)" \
   "$(_la_accepts)" "1"
_la_owed "with an entry at main's version that differs from origin/main's engine (a branch's install)" "" differ "not main" "not the engine"
_lg_cache 9.0.0
_fx_git "$LGH" checkout -q -b la-nover main >/dev/null 2>&1
printf '{ "name": "felix" }\n' > "$LGH/engine/.claude-plugin/plugin.json"
_fx_git "$LGH" -c user.name=t -c user.email=t@t commit -qam 'no version' >/dev/null 2>&1
_fx_git "$LGH" update-ref refs/remotes/origin/main "$(git -C "$LGH" rev-parse HEAD 2>/dev/null)" >/dev/null 2>&1
_fx_git "$LGH" checkout -q main >/dev/null 2>&1; _fx_git "$LGH" branch -q -D la-nover >/dev/null 2>&1
is "the land fixture: origin/main declares no version, and main's entry is in place (fixture control)" \
   "$(_lg_mainv)|$([ -x "$LGV/9.0.0/harness/felix" ] && echo there)" "|there"
_la_owed "with origin/main's version unreadable" "" version
_fx_git "$LGH" update-ref refs/remotes/origin/main "$LAMAIN" >/dev/null 2>&1
_la_owed "with git failing (exit 69)" "$LA/git69:" git version
is "A1: each case is named apart from the others in its row" \
   "$(sed -n 1,5p "$LA/details" | LC_ALL=C sort -u | wc -l | tr -d ' ')" "5"
_lg_reset; _lg_land --uninstall; rm -rf "$LGV/9.1.0"

# --------------------------------------------------------------- A2, A4 ---
# origin's main moves on from another clone, and the entry for the version it
# declares is already cached, byte for byte main's engine, as the author's gate
# leaves it. Only the home is behind. A git first on PATH logs the environment
# of every fetch and pull, then runs the real git.
_fx_git "$LG" clone -q "$LGO" la-o2 >/dev/null 2>&1
printf 'core a2\n' > "$LG/la-o2/engine/harness/lib/core.sh"
printf '{ "name": "felix", "version": "9.0.3" }\n' > "$LG/la-o2/engine/.claude-plugin/plugin.json"
_fx_git "$LG/la-o2" -c user.name=t -c user.email=t@t commit -qam a2 >/dev/null 2>&1
_fx_git "$LG/la-o2" push -q origin HEAD:main >/dev/null 2>&1
rm -rf "$LGV/9.0.3"; mkdir -p "$LGV/9.0.3/.claude-plugin"; cp -R "$LG/la-o2/engine/harness" "$LGV/9.0.3/harness"
printf '{ "name": "felix", "version": "9.0.3" }\n' > "$LGV/9.0.3/.claude-plugin/plugin.json"
_fx_git "$LGH" fetch -q origin >/dev/null 2>&1
is "the land fixture: main's check accepts origin/main's 9.0.3 entry, and the home's HEAD is behind origin/main (fixture control)" \
   "$(_la_accepts)|$(git -C "$LGH" merge-base --is-ancestor HEAD origin/main 2>/dev/null && echo behind)|$(_lg_mainv)" "0|behind|9.0.3"
_lg_put "$LGB/git" <<'LGSTUB'
#!/bin/bash
LG='@LG@'; s=""; k=""
for a in "$@"; do
  if [ -n "$k" ]; then k=""; continue; fi
  case "$a" in -C|-c|--git-dir|--work-tree|--namespace|--config-env) k=1 ;; -*) ;; *) s="$a"; break ;; esac
done
case "$s" in fetch|pull) printf '%s\t%s\t%s\t%s\n' "$s" "${GIT_TERMINAL_PROMPT-unset}" "${GIT_HTTP_LOW_SPEED_LIMIT-unset}" \
  "${GIT_HTTP_LOW_SPEED_TIME-unset}" >> "$LG/log/gitenv.log" ;; esac
exec "$(cat "$LG/amend/realgit")" "$@"
LGSTUB
_lg_reset; _lg_land --tick; rm -f "$LGB/git"
is "A2: a home behind origin/main, whose entry is already main's, owes a deploy: one install and one deployed row" \
   "$LGRC|$(_lg_ninst)|$(_lg_n deployed)" "0|1|1"
is "A2: the home is at origin/main after it" "$(git -C "$LGH" rev-parse HEAD 2>&1)" "$(git -C "$LGO" rev-parse main 2>&1)"
is "A2, A4: the tick fetched, and pulled the home" "$(_lg_logs gitenv | cut -f1 | LC_ALL=C sort -u | tr '\n' ' ')" "fetch pull "
is "A4: every git fetch and git pull runs with GIT_TERMINAL_PROMPT=0, GIT_HTTP_LOW_SPEED_LIMIT=1000 and GIT_HTTP_LOW_SPEED_TIME=60" \
   "$(_lg_logs gitenv | LC_ALL=C awk -F'\t' '$2 != "0" || $3 != "1000" || $4 != "60"' | wc -l | tr -d ' ')" "0"
_la_home() {   # WHAT -> a home not at origin/main, with main's entry accepted: owed, paused, nothing installed
  _lg_reset; _lg_prs "$(_lg_pr 42)"; _lg_green 42; _lg_land --tick
  is "A2: a home $1 origin/main writes one deploy-owed row" "$LGRC|$(_lg_n deploy-owed)" "0|1"
  if [ -s "$LAND/paused" ]; then ok "A2: a home $1 origin/main also writes paused"
  else bad "A2: a home $1 origin/main also writes paused" "no paused"; fi
  is "A2: a home $1 origin/main installs nothing, deploys nothing and merges nothing" \
     "$(_lg_ninst)|$(_lg_n deployed)|$(_lg_merges)" "0|0|"
}
mkdir -p "$LGH/notes" "$LG/la-o2/notes"; printf 'ahead\n' > "$LGH/notes/la-ahead.md"
_fx_git "$LGH" add -A >/dev/null 2>&1; _fx_git "$LGH" -c user.name=t -c user.email=t@t commit -qm ahead >/dev/null 2>&1
_la_home "ahead of"
_fx_git "$LGH" reset -q --hard origin/main >/dev/null 2>&1
printf 'origin side\n' > "$LG/la-o2/notes/la-div.md"
_fx_git "$LG/la-o2" add -A >/dev/null 2>&1; _fx_git "$LG/la-o2" -c user.name=t -c user.email=t@t commit -qm div >/dev/null 2>&1
_fx_git "$LG/la-o2" push -q origin HEAD:main >/dev/null 2>&1
mkdir -p "$LGH/notes"; printf 'home side\n' > "$LGH/notes/la-home.md"
_fx_git "$LGH" add -A >/dev/null 2>&1; _fx_git "$LGH" -c user.name=t -c user.email=t@t commit -qm home >/dev/null 2>&1
_la_home "diverged from"
_fx_git "$LGH" fetch -q origin >/dev/null 2>&1; _fx_git "$LGH" reset -q --hard origin/main >/dev/null 2>&1
is "the land fixture: the home is back at origin/main, and main's check accepts its entry (fixture control)" \
   "$(git -C "$LGH" rev-parse HEAD 2>&1)|$(_la_accepts)" "$(git -C "$LGO" rev-parse main 2>&1)|0"

# --------------------------------------------------------------------- A3 ---
_lg_reset; _lg_prs "$(_lg_pr 43)"; _lg_green 43; printf 'docs/2026-x-notes.md\n' > "$LGK/files.43"; _lg_land --tick
is "A3: a pull request touching no direction document lands (control for the cases below)" "$(_lg_n landed 43)|$(_lg_merges)" "1|b43"
_la_dir() {   # N PATH -> a pull request listing PATH is held with a founder row and not merged
  _lg_reset; _lg_prs "$(_lg_pr "$1")"; _lg_green "$1"; printf '%s\n' "$2" > "$LGK/files.$1"; _lg_land --tick
  is "A3: a pull request touching $2 is held with one founder row and not merged" "$(_lg_n founder "$1")|$(_lg_merges)" "1|"
}
_la_dir 40 projects/lgh/claude.md
_la_dir 41 Projects/lgh/CLAUDE.MD
_la_dir 43 docs/2026-x-ROADMAP.md
# A rename away from a roadmap main holds; gh names only the new path, as it
# does for a rename.
mkdir -p "$LGH/docs"; printf 'plan\n' > "$LGH/docs/2026-10-01-roadmap.md"
_fx_git "$LGH" add -A >/dev/null 2>&1; _fx_git "$LGH" -c user.name=t -c user.email=t@t commit -qm roadmap >/dev/null 2>&1
_fx_git "$LGH" push -q origin main >/dev/null 2>&1
_fx_git "$LGH" worktree add -q -b b37 "$LGW/b37" main >/dev/null 2>&1; mkdir -p "$LGW/b37/notes"
_fx_git "$LGW/b37" mv docs/2026-10-01-roadmap.md notes/old-plan.md >/dev/null 2>&1
_fx_git "$LGW/b37" -c user.name=t -c user.email=t@t commit -qm b37 >/dev/null 2>&1
printf '37\t%s\n' "$(git -C "$LGW/b37" rev-parse HEAD)" >> "$LG/shas"
_lg_reset; _lg_prs "$(_lg_pr 37)"; _lg_green 37; printf 'notes/old-plan.md\n' > "$LGK/files.37"; _lg_land --tick
is "A3: a pull request that renames docs/*roadmap* away is held with one founder row and not merged" \
   "$(_lg_n founder 37)|$(_lg_merges)" "1|"
_fx_git "$LGH" worktree remove --force "$LGW/b37" >/dev/null 2>&1; _fx_git "$LGH" branch -q -D b37 >/dev/null 2>&1
_lg_reset; _lg_prs "$(_lg_pr 40)"; _lg_green 40; printf '1\n' > "$LGK/files.40.rc"; _lg_land --tick
is "G5, A3: the tick asked gh for the file list" "$(_lg_logs gh | grep -c '^pr view 40')" "1"
is "A3: a pull request whose file list cannot be read gets one skip row and is not merged" \
   "$(_lg_n skip 40)|$(_lg_merges)|$(_lg_n landed 40)" "1||0"
_la_names "A3: and the skip row says the files could not be read" "$(_lg_f skip 40 7)" file

# --------------------------------------------------------------------- A6 ---
_lg_reset; _lg_prs "$(_lg_pr 40)" "$(_lg_pr 34)" "$(_lg_pr 31)"; _lg_green 31 34 40
printf 'projects/someone-else/CLAUDE.md\n' > "$LGK/files.34"
printf 'felix merge: refused\n  blocker: the receipt is stale\n' > "$LGK/merge.b40.out"; printf '1\n' > "$LGK/merge.b40.rc"
_lg_land --tick; _lg_land --tick
is "A6: two identical ticks write one founder row for a held pull request" "$(_lg_n founder 34)" "1"
is "A6: one refused row for a refused one" "$(_lg_n refused 40)" "1"
is "A6: one session row for one no checkout holds" "$(_lg_n session 31)" "1"
is "A6: and one notification each for the founder and the refused row" \
   "$(_lg_logs osa | grep -c 'Felix: founder #34')|$(_lg_logs osa | grep -c 'Felix: refused #40')" "1|1"
# A13: felix merge is re-run on a known refusal only once its head or main
# moves, so main moves here, pushed from the home, which stays at it.
mkdir -p "$LGH/notes"; printf 'a6\n' > "$LGH/notes/la-a6.md"; _fx_git "$LGH" add -A >/dev/null 2>&1
_fx_git "$LGH" -c user.name=t -c user.email=t@t commit -qm a6 >/dev/null 2>&1; _fx_git "$LGH" push -q origin main >/dev/null 2>&1
printf 'felix merge: refused\n  blocker: the version is behind main\n' > "$LGK/merge.b40.out"; _lg_land --tick
is "A6: a refusal whose detail changed writes one new refused row and one new notification" \
   "$(_lg_n refused 40)|$(_lg_logs osa | grep -c 'Felix: refused #40')" "2|2"

# --------------------------------------------------------------------- A4 ---
# One tick is held inside gh auth status, as 1280 holds one, but in a process
# group of its own, so a TERM to the group the watchdog would signal never
# reaches this suite.
_lg_reset; : > "$LGK/gh-block"; _la_bg held; LAHB=$LABG; _lai=0
while [ "$_lai" -lt 100 ]; do
  { [ -s "$LAND/lock/pid" ] && [ -d "$LGK/gh-block-taken" ]; } && break
  kill -0 "$LAHB" 2>/dev/null || break
  sleep 0.1; _lai=$((_lai+1))
done
LAPID="$(cat "$LAND/lock/pid" 2>/dev/null)"
_lg_land --tick
is "A4: a tick finding a live lock younger than 45 minutes writes no stuck row" "$(_lg_n stuck)" "0"
[ -n "$LAPID" ] && kill -0 "$LAPID" 2>/dev/null && ok "A4: and does not signal the lock's holder" \
  || bad "A4: and does not signal the lock's holder" "holder [$LAPID] is gone"
skip "A4: a live lock older than 45 minutes gives one stuck row and one notification over two ticks, and its holder is not signalled" \
  "no seam ages a live lock: its started line must match its holder's real start time"
skip "A4: the watchdog sends TERM after 30 minutes" "the contract gives no way to shorten 30 minutes"
_lapg="$(ps -o pgid= -p "${LAPID:-0}" 2>/dev/null | tr -d ' ')"; _lame="$(ps -o pgid= -p "$$" 2>/dev/null | tr -d ' ')"
case "$_lapg" in ""|*[!0123456789]*|0|1) _lapg="" ;; esac
[ "$_lapg" = "$_lame" ] && _lapg=""
if [ -n "$_lapg" ]; then kill -TERM -- "-$_lapg" 2>/dev/null
elif [ -n "$LAPID" ]; then kill -TERM "$LAPID" 2>/dev/null; else kill -TERM "$LAHB" 2>/dev/null; fi
rm -f "$LGK/gh-block"; _la_reap "$LAHB"; [ -z "$LAPID" ] || _la_reap "$LAPID"
is "A4: a tick whose process group gets TERM, as the watchdog sends it, writes one timeout row" "$(_lg_n timeout)" "1"
is "A4: and sends one notification for it" "$(_lg_logs osa | grep -c 'Felix: timeout')" "1"
[ -d "$LAND/lock" ] && bad "A4: and releases the lock" "lock/ is left" || ok "A4: and releases the lock"

# --------------------------------------------------------------------- A5 ---
sleep 60 & LASLP=$!
for _lak in absent empty; do
  _lg_reset; mkdir -p "$LAND/lock"; printf '%s\n' "$LASLP" > "$LAND/lock/pid"
  [ "$_lak" = empty ] && : > "$LAND/lock/started"
  _lg_land --tick
  is "A5: a lock whose pid is live and whose started is $_lak is not taken: the tick asks gh nothing" \
     "$(_lg_logs gh | grep -c '^auth status')" "0"
  is "A5: and that lock is left as it was" "$(cat "$LAND/lock/pid" 2>/dev/null)" "$LASLP"
  kill -0 "$LASLP" 2>/dev/null && ok "A5: and its holder is not signalled" || bad "A5: and its holder is not signalled" "$LASLP is gone"
done
kill "$LASLP" 2>/dev/null; wait "$LASLP" 2>/dev/null
# Two ticks race one dead lock. Whichever takes it is held inside gh auth
# status, so a second taker, if there were one, would be counted there too.
sh -c 'exit 0' & _ladead=$!; wait "$_ladead"
_la_race=""
for _lak in 1 2 3 4 5; do
  _lg_reset; : > "$LGK/gh-block"; mkdir -p "$LAND/lock"
  printf '%s\n' "$_ladead" > "$LAND/lock/pid"; printf '%s\n' "${LGSTART:-}" > "$LAND/lock/started"
  _la_bg r1; _la1=$LABG; _la_bg r2; _la2=$LABG; _lai=0
  while [ "$_lai" -lt 150 ]; do
    [ -d "$LGK/gh-block-taken" ] && { ! kill -0 "$_la1" 2>/dev/null || ! kill -0 "$_la2" 2>/dev/null; } && break
    sleep 0.1; _lai=$((_lai+1))
  done
  _la_race="$_la_race $(_lg_logs gh | grep -c '^auth status')"
  rm -f "$LGK/gh-block"; _la_reap "$_la1"; _la_reap "$_la2"
done
is "A5: two ticks racing one dead lock leave exactly one taker, in each of five rounds" "$_la_race" " 1 1 1 1 1"
[ -d "$LAND/lock" ] && bad "A5: and the lock is released after the race" "lock/ is left" || ok "A5: and the lock is released after the race"
