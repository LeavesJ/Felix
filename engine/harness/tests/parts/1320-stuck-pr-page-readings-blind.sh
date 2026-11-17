# >>> stuck-pr-page-readings
printf '\nthe stuck-PR page: the queue once, the lock, the ledger, --repo and the unread readings (spec v2 cases 1, 11, 14, 28, 29 and section 5, blind)\n'
# Blind, from spec v2 alone, on the fixture part 1300 builds. Each section
# sets its own gh answers, ledger and lock, and the last one moves origin/main,
# so it runs last. The fixture is removed at the end of this part.
_sp_build

# ---- case 1: exactly one entry, however many rules and labels (§6.3) ----------
_sp_ledger; _sp_logs0
_sp_prs fixture_home "$(_sp_pr 101 "projects/felix/risk.tsv:1 projects/felix/qualification.tsv:1 projects/felix/ecosystem.tsv:0" green labels=needs-founder,felix:founder)"
_sp_ghfail fixture_two "HTTP 503: Service Unavailable"
_sp_prs fixture_three
_sp_land "$SPH" --prs --tsv; _sp_keep once.tsv
_sp_land "$SPH" --queue --tsv; _sp_keep once.queue.tsv
_sp_land "$SPH" --queue; _sp_keep once.queue.txt
is "case 1: with a second and third escape table and two founder labels, #101 is still founder" "$(_sp_state "$SPX/once.tsv" 101)" founder
is "case 1: in one --prs row" "$(_sp_nrow "$SPX/once.tsv" 101)" 1
is "case 1: and once in --queue --tsv" \
   "$(LC_ALL=C awk -F'\t' '$1 == "pr" && $3 == "#101"' "$SPX/once.queue.tsv" | LC_ALL=C awk 'END { print NR }')" 1
is "case 1: and on one line of the --queue text" "$(_sp_tline "$SPX/once.queue.txt" 101 | LC_ALL=C awk 'END { print NR }')" 1
is "spec §6.1: a project whose gh failed has its gh source row in --queue, unread" \
   "$(LC_ALL=C awk -F'\t' '$1 == "source" && $3 == "gh" && $2 == "fixture/two" { print $4 }' "$SPX/once.queue.tsv")" "unread"
has "spec §6.2: the --queue text says that project was not read, and why" "$(cat "$SPX/once.queue.txt")" "two: not read: "
has "spec §6.2: and a project with no founder pull request says so" "$(cat "$SPX/once.queue.txt")" "three: no founder entries"
is "spec §7: --queue exits 0 though one project was not read" "$(cat "$SPX/once.queue.txt.rc")$(cat "$SPX/once.queue.tsv.rc")" "00"

# ---- case 14: the lander source row (§4.3) ------------------------------------
_sp_prs fixture_home; _sp_prs fixture_two
SPSTART="$(LC_ALL=C ps -o lstart= -p "$$" 2>/dev/null | LC_ALL=C sed 's/^ *//; s/ *$//')"
is "the stuck-PR fixture: ps gives this shell's start time (fixture control)" "$([ -n "$SPSTART" ] && kill -0 "$$" 2>/dev/null && echo yes)" "yes"
_sp_lock() { rm -rf "$SPLAND/lock"; mkdir -p "$SPLAND/lock"; printf '%s\n' "$1" > "$SPLAND/lock/pid"; printf '%s' "$2" > "$SPLAND/lock/started"; }
_sp_ledger; _sp_lock "$$" "$SPSTART"
_sp_land "$SPH" --prs --tsv --no-gh
is "case 14: a lock with a live pid and its start time: the lander row says live" "$(_sp_srcf "$SPX/out" lander 4)" "live"
_sp_lock "$$" "Thu Jan  1 00:00:00 1970"
_sp_land "$SPH" --prs --tsv --no-gh
is "case 14: a live pid under another start time was reused: not-live" "$(_sp_srcf "$SPX/out" lander 4)" "not-live"
_sp_lock "$$" ""
_sp_land "$SPH" --prs --tsv --no-gh
is "case 14: a live pid with an empty started: live" "$(_sp_srcf "$SPX/out" lander 4)" "live"
rm -rf "$SPLAND/lock"
_sp_land "$SPH" --prs --tsv --no-gh
is "case 14: no lock: not-live" "$(_sp_srcf "$SPX/out" lander 4)" "not-live"
mkdir -p "$SPU/Library/LaunchAgents"; printf '<plist/>\n' > "$SPU/Library/LaunchAgents/felix.land.felix.plist"; : > "$SPK/loaded"
printf 'deploy window\nthe rest of it\n' > "$SPLAND/paused"
_sp_land "$SPH" --prs --tsv --no-gh; _spo="$(_sp_srcf "$SPX/out" lander 8)"
has "case 14: a paused file holding a reason: paused yes" "$_spo" "paused yes"
has "case 14: and the reason in the detail" "$_spo" "deploy window"
_sp_lacks "case 14: its first line only" "$_spo" "the rest of it"
has "spec §4.3: the job's plist there: installed yes" "$_spo" "installed yes"
has "spec §4.3: launchctl print succeeding: loaded yes" "$_spo" "loaded yes"
rm -f "$SPLAND/paused"
_sp_land "$SPH" --prs --tsv --no-gh
has "spec §4.3: no paused file: paused no" "$(_sp_srcf "$SPX/out" lander 8)" "paused no"
rm -f "$SPU/Library/LaunchAgents/felix.land.felix.plist" "$SPK/loaded"

# ---- case 28: the ledger unreadable, and absent (§4.3, §5) ----------------------
_sp_ledger; _sp_logs0
_sp_prs fixture_home "$(_sp_pr 105 notes/105.md:0 green)"
rm -f "$SPLAND/ledger.tsv"; mkdir -p "$SPLAND/ledger.tsv"
_sp_land "$SPH" --prs --tsv; _sp_keep ledgerdir.tsv
is "case 28: a directory where the ledger should be: the ledger row says unread" "$(_sp_srcf "$SPX/ledgerdir.tsv" ledger 4)" "unread"
_sp_is "case 28: and a pull request that would otherwise be ready" "$SPX/ledgerdir.tsv" 105 unknown unknown
has "spec §5: its detail says the lander's ledger was not read" "$(_sp_f "$SPX/ledgerdir.tsv" 105 8)" "the lander's ledger not read"
rm -rf "$SPLAND/ledger.tsv"
_sp_land "$SPH" --prs --tsv; _sp_keep noledger.tsv
is "case 28: no ledger at all: the ledger row says none" "$(_sp_srcf "$SPX/noledger.tsv" ledger 4)" "none"
_sp_is "case 28: and the pull request" "$SPX/noledger.tsv" 105 ready lander

# ---- case 29: --repo DIR reads that repository and that project's ledger ---------
_sp_ledger; _sp_logs0; mkdir -p "$SP2/deep/er"
_sp_list; _sp_prs fixture_home "${SPLIST[@]}"
_sp_prs fixture_two "$(_sp_pr 202 notes/202.md:0 green sha="$(_sp_two 202)" repo=fixture/two)" \
                    "$(_sp_pr 201 notes/201.md:0 green sha="$(_sp_two 201)" repo=fixture/two)"
_sps0="$(_sp_snapall)"
_sp_land "$SPH" --prs --tsv --repo "$SP2/deep/er"; _sp_keep repo.tsv
R="$SPX/repo.tsv"
is "case 29: --repo exits 0" "$(cat "$R.rc")" 0
is "case 29: every row names the second repository" "$(LC_ALL=C cut -f2 "$R" | LC_ALL=C sort -u)" "fixture/two"
is "case 29: its pull requests, and none of the current repository's" "$(LC_ALL=C awk -F'\t' '$1 == "pr" { printf "%s ", $3 }' "$R")" "#201 #202 "
_sp_is "case 29: that project's ledger names #201's head in a session row" "$R" 201 refused session
has "case 29: and its detail is that ledger's" "$(_sp_f "$R" 201 8)" "the lander cannot use it: the gated head is in no checkout of two"
_sp_is "case 29: the current project's ledger row for 202 is not read" "$R" 202 ready lander
is "case 29: gh was asked for one list" "$(_sp_prl "$SPL/gh.log")" 1
is "case 17: --repo prints its page and leaves both repositories and every land directory byte-identical" "$(cat "$R.rc")|$(_sp_snapall)" "0|$_sps0"
rm -rf "$SP2/deep"

# ---- §4.2, §5: no origin/main and no origin/HEAD -------------------------------
_sp_logs0
_sp_prs fixture_three "$(_sp_pr 301 notes/301.md:0 green labels=needs-founder repo=fixture/three)"   # the case-1 section above left three at []
_sp_land "$SPH" --prs --tsv --repo "$SP3"; _sp_keep three.tsv
is "spec §7: a repository with no origin/main still exits 0" "$(cat "$SPX/three.tsv.rc")" 0
has "spec §5: the origin source row says no origin/main" "$(_sp_src "$SPX/three.tsv" origin)" "no origin/main"
is "spec §5: and the land table is unread" "$(_sp_srcf "$SPX/three.tsv" land 4)" "unread"
_sp_is "spec §4.2: with neither origin/HEAD nor origin/main, a pull request labelled needs-founder" "$SPX/three.tsv" 301 unknown unknown
has "spec §4.2: its detail says the default branch was not read" "$(_sp_f "$SPX/three.tsv" 301 8)" "default branch not read"

# ---- §4.4: the budget unread ------------------------------------------------------
_sp_logs0; _sp_prs fixture_home
_spl="HTTP 404: Not Found (https://api.github.com/users/fixture/settings/billing/usage): the login may not read it"
while [ "${#_spl}" -lt 120 ]; do _spl="$_spl."; done
printf '1\n' > "$SPK/api.rc"; printf '%sZZZZZZZZZZZZZZZZZZZZ\nsecond line of the error\n' "$_spl" > "$SPK/api.err"
_sp_land "$SPH" --prs --tsv; _sp_keep budget.tsv
is "spec §4.4: a failing billing GET: the budget row says unread" "$(_sp_srcf "$SPX/budget.tsv" budget 4)" "unread"
has "spec §4.4: and gives gh's first error line" "$(_sp_srcf "$SPX/budget.tsv" budget 8)" "$_spl"
_sp_lacks "spec §4.4: cut at 120 characters" "$(_sp_srcf "$SPX/budget.tsv" budget 8)" "Z"
_sp_lacks "spec §4.4: its first line only" "$(_sp_srcf "$SPX/budget.tsv" budget 8)" "second line"
is "spec §7: and the page still exits 0" "$(cat "$SPX/budget.tsv.rc")" 0
rm -f "$SPK/api.rc" "$SPK/api.err"

# ---- case 11 and §5: a malformed land table at origin/main ------------------------
_fx_git "$SP" clone -q "$SPO" mal >/dev/null 2>&1
printf 'notes/zz.md\tmerge-ours\t-\t-\n' >> "$SP/mal/projects/felix/land.tsv"
_sp_commit "$SP/mal" "a land row of a kind the engine does not define"
_fx_git "$SP/mal" push -q origin HEAD:refs/heads/main >/dev/null 2>&1
_fx_git "$SPH" fetch -q origin >/dev/null 2>&1
is "the stuck-PR fixture: origin/main now holds a land row of an undefined kind (fixture control)" \
   "$(git -C "$SPH" show refs/remotes/origin/main:projects/felix/land.tsv 2>&1 | LC_ALL=C cut -f2 | LC_ALL=C tr '\n' ' ')" "founder merge-ours "
_sp_ledger; _sp_logs0
_sp_prs fixture_home "$(_sp_pr 141 projects/felix/CLAUDE.md:0 green)" "$(_sp_pr 139 notes/139.md:0 green labels=NEEDS-FOUNDER)" \
                     "$(_sp_pr 122 projects/felix/ecosystem.tsv:0 green)" "$(_sp_pr 114 landdir/x.md:0 green)"
_sp_land "$SPH" --prs --tsv; _sp_keep malformed.tsv
M="$SPX/malformed.tsv"
is "spec §5: a land table felix_land_malformed refuses is unread" "$(_sp_srcf "$M" land 4)" "unread"
_sp_is "case 11: a pull request that reaches founder by a land row alone" "$M" 114 unknown unknown
has "spec §5: its detail says the land table was not read" "$(_sp_f "$M" 114 8)" "land table not read: "
_sp_is "spec §5: the escape-table rules still decide founder" "$M" 122 founder founder
_sp_is "spec §5: and the direction rule" "$M" 141 founder founder
_sp_is "spec §5: and the labels" "$M" 139 founder founder

# ---- the fixture is removed -------------------------------------------------------
rm -rf "$SP"
[ -e "$SP" ] && bad "the stuck-PR fixture is removed when its parts end" "$SP is still there" || ok "the stuck-PR fixture is removed when its parts end"
# <<< stuck-pr-page-readings
