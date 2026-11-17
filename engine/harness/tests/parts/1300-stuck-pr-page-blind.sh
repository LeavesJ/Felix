# >>> stuck-pr-page
printf '\nthe stuck-PR page: felix land --prs and --queue, the fixture, usage and the unread readings (spec v2, blind)\n'
# Blind, written from the stuck-PR spec v2 (audits/2026-10-01-report-v5-review/
# specs/stuck-pr/spec-v2.md) alone on 2026-10-17, before lib/pr-status.sh
# existed. No engine code was read for an expected value: lib/green-tick.sh was
# read only for where the spec's ledger, lock, paused file and job plist live.
# Parts 1310 and 1320 run on the same fixture, and 1320 removes it. _sp_build in tests/lib/stuck-pr.sh builds it.
#
# The fixture: three bare origins whose paths end github.com/fixture/home.git,
# two.git and three.git, so each slug is fixture/<name> and the governed
# account is fixture. home is cloned from the first and is also the Felix home:
# it holds projects/felix (remote_match github.com/fixture/home), projects/two,
# projects/three and projects/loose (no remote_match). Its origin/main is the
# second of two commits, so a ledger row can name the current main or an older
# one. two is a clone with a pushed main; three is a clone of an empty origin
# with an unpushed main, so it has no origin/main and no origin/HEAD. Memory is
# a fixture directory, so each project's land/ directory is $SPM/<p>/land.
#
# gh and launchctl are stubs first on PATH, each logging its argv. gh answers
# pr list from ctl/prs.<owner>_<name>.json, the repository taken from -R or
# --repo, else from the origin of the directory it runs in, and fails as
# ctl/prs.<key>.rc says; it answers api GETs of the Actions billing from a
# fixed body, or fails as ctl/api.rc says. It answers a GET of repos/fixture/home
# or repos/fixture/two with the default branch main, as GitHub would: the queue
# has no checkout of two to read origin/HEAD from (review F5; without this
# answer every pull request of two was unknown, and the cross-project check in
# 1310 passed on no rows). It logs the XDG state and cache
# directories and GH_CONFIG_DIR it was handed. launchctl print succeeds only
# while ctl/loaded exists. ps is the real one: a lock names this shell's pid.
# The home's engine/harness/felix is a tripwire that logs if anything runs it.
# HOME is a fixture directory on every run, so nothing reaches ~/Library.
_sp_build

# ---- fixture controls -------------------------------------------------------
_spo="$(printf '%s %s' "$SPMAIN" "$SPOLD" | LC_ALL=C awk '{ for (i = 1; i <= 2; i++) if ($i ~ /^[0123456789abcdef]+$/ && length($i) == 40) n++ } END { print n + 0 }')"
is "the stuck-PR fixture: origin/main and the older main are two commits (fixture control)" "$_spo|$([ "$SPMAIN" != "$SPOLD" ] && echo two)" "2|two"
is "the stuck-PR fixture: origin/HEAD names main, and three has no origin/main and no origin/HEAD (fixture control)" \
   "$(git -C "$SPH" symbolic-ref -q refs/remotes/origin/HEAD 2>&1)|$(git -C "$SP3" rev-parse -q --verify refs/remotes/origin/main 2>/dev/null)|$(git -C "$SP3" symbolic-ref -q refs/remotes/origin/HEAD 2>/dev/null)" \
   "refs/remotes/origin/main||"
is "the stuck-PR fixture: the landdir founder row is on origin/main and the wtonly row only in the working tree (fixture control)" \
   "$(git -C "$SPH" show refs/remotes/origin/main:projects/felix/land.tsv 2>&1 | LC_ALL=C cut -f1 | LC_ALL=C tr '\n' ' ')|$(LC_ALL=C cut -f1 "$SPH/projects/felix/land.tsv" | LC_ALL=C tr '\n' ' ')" \
   "landdir/.* |landdir/.* wtonly/.* "
_sp_prs fixture_home "$(_sp_pr 7 notes/7.md:0 green)"
is "the stuck-PR fixture: the gh stub serves the home's pull requests from the home's directory (fixture control)" \
   "$( cd "$SPH" && PATH="$SPB:$PATH" gh pr list --state open --limit 1000 --json number 2>&1 | LC_ALL=C grep -o '"number":7,' )" '"number":7,'
_sp_prs fixture_two "$(_sp_pr 8 notes/8.md:0 green repo=fixture/two)"
is "the stuck-PR fixture: and two's from -R fixture/two, whatever directory it runs in (fixture control)" \
   "$( cd "$SPH" && PATH="$SPB:$PATH" gh pr list -R fixture/two --state open 2>&1 | LC_ALL=C grep -o '"number":8,' )" '"number":8,'
if command -v jq >/dev/null 2>&1; then
  is "the stuck-PR fixture: every pull request object the builder writes is JSON gh could have printed (fixture control)" \
     "$(_sp_pr 9 'a.md:0 b.md:2' red labels=felix:hold,needs-founder title='a\ttab' | jq -r '[.number, .labels[1].name, .files[1].deletions, .statusCheckRollup[1].conclusion, (.title | length)] | @tsv' 2>&1)" \
     "$(printf '9\tneeds-founder\t2\tFAILURE\t5')"
else skip "the stuck-PR fixture: every pull request object the builder writes is JSON gh could have printed (fixture control)" "no jq"; fi
is "the stuck-PR fixture: the land directory holds the ledger, a dead lock and paused (fixture control)" \
   "$(cd "$SPLAND" && find . -type f | LC_ALL=C sort | LC_ALL=C tr '\n' ' ')" "./ledger.tsv ./lock/pid ./lock/started ./paused "
_sp_logs0; : > "$SPL/gh.log"

# ------------------------------------------------- usage and exit status (§1, §7) -
_sp_land "$SPH"
is "case 19: felix land alone exits 2" "$SPRC" 2
has "case 19: and its usage names --prs" "$(cat "$SPX/both")" "--prs"
has "case 19: and --queue" "$(cat "$SPX/both")" "--queue"
_sp_land "$SPH" --prs --queue
is "case 19: felix land --prs --queue exits 2" "$SPRC" 2
has "case 19: and prints the usage, which names --prs" "$(cat "$SPX/both")" "--prs"
_sp_land "$SPH" --prs --tick
is "case 19: felix land --prs --tick exits 2" "$SPRC" 2
has "case 19: and prints the usage, which names --prs" "$(cat "$SPX/both")" "--prs"
_sp_land "$SPH" --queue --repo x
is "case 19: felix land --queue --repo x exits 2: --repo belongs to --prs" "$SPRC" 2
has "case 19: and prints the usage, which names --prs" "$(cat "$SPX/both")" "--prs"
_sp_land "$SPH" --prs --repo "$SPH" --repo "$SP2"
is "spec §1: two --repo options exit 2: one --repo only" "$SPRC" 2
_sp_land "$SPH" --prs --sideways
is "spec §1: --prs with an argument it does not know exits 2" "$SPRC" 2
is "spec §2: no usage run asked gh or launchctl anything" "$(_sp_cnt gh)$(_sp_cnt launchctl)" "00"
_sp_land "$SPH" --status
_spo="$(LC_ALL=C sed -n 1,3p "$SPX/out" | LC_ALL=C awk '{ k = $1; gsub(/[^a-z]/, "", k); printf "%s ", k }')"
is "case 19: felix land --status still exits 0" "$SPRC" 0
is "case 19: and still prints installed, loaded and paused, first and in that order" "$_spo" "installed loaded paused "
_sp_land "$SP/norepo" --prs
is "spec §7: --prs where no repository holds the directory exits 1" "$SPRC" 1
_sp_land "$SPH" --prs --repo "$SP/norepo"
is "spec §7: --prs --repo naming a directory no repository holds exits 1" "$SPRC" 1

# ------------------------------------------- gh failing, gh empty, --no-gh (§5) ---
_sp_logs0; _sp_ghfail fixture_home "HTTP 502: Bad Gateway (https://api.github.com/graphql)"
_sp_land "$SPH" --prs --tsv; _sp_keep ghfail.tsv
_sp_land "$SPH" --prs; _sp_keep ghfail.txt
is "case 12: gh failing still exits 0 with --tsv" "$(cat "$SPX/ghfail.tsv.rc")" 0
is "case 12: and without it" "$(cat "$SPX/ghfail.txt.rc")" 0
is "case 12: gh failing prints no pr row" "$(_sp_prn "$SPX/ghfail.tsv")" 0
is "case 12: the gh source row says unread" "$(_sp_srcf "$SPX/ghfail.tsv" gh 4)" "unread"
has "case 12: and gives gh's reason" "$(_sp_srcf "$SPX/ghfail.tsv" gh 8)" "HTTP 502"
has "case 12: the text page says pull requests not read, with the reason" "$(cat "$SPX/ghfail.txt")" "pull requests not read: "
_sp_lacks "case 12: and never no open pull requests" "$(cat "$SPX/ghfail.txt")" "no open pull requests"
is "case 12: the page asked gh for the list once in each run" "$(_sp_prl "$SPL/gh.log")" 2

_sp_logs0; _sp_prs fixture_home
_sp_land "$SPH" --prs --tsv; _sp_keep empty.tsv
_sp_land "$SPH" --prs; _sp_keep empty.txt
is "case 13: gh answering [] exits 0" "$(cat "$SPX/empty.tsv.rc")$(cat "$SPX/empty.txt.rc")" "00"
is "case 13: the gh source row says none" "$(_sp_srcf "$SPX/empty.tsv" gh 4)" "none"
is "case 13: and there is no pr row" "$(_sp_prn "$SPX/empty.tsv")" 0
has "case 13: the text page says no open pull requests" "$(cat "$SPX/empty.txt")" "no open pull requests"
_sp_lacks "case 13: and not that they were not read" "$(cat "$SPX/empty.txt")" "not read: "

_sp_logs0; _sp_prs fixture_home "$(_sp_pr 105 notes/105.md:0 green)"
_sp_land "$SPH" --prs --tsv --no-gh; _sp_keep nogh.tsv
_sp_land "$SPH" --prs --no-gh; _sp_keep nogh.txt
is "spec §1: --no-gh exits 0" "$(cat "$SPX/nogh.tsv.rc")$(cat "$SPX/nogh.txt.rc")" "00"
is "spec §1: --no-gh asks gh nothing" "$(_sp_cnt gh)" 0
is "spec §5: with --no-gh there is no pr row, though gh would have listed one" "$(_sp_prn "$SPX/nogh.tsv")" 0
is "spec §5: the gh source row says unread" "$(_sp_srcf "$SPX/nogh.tsv" gh 4)" "unread"
is "spec §4.4: and the budget row says unread, gh not asked" "$(_sp_srcf "$SPX/nogh.tsv" budget 4)" "unread"
has "spec §5: the text page says pull requests not read" "$(cat "$SPX/nogh.txt")" "pull requests not read: "
_sp_lacks "spec §5: and never no open pull requests" "$(cat "$SPX/nogh.txt")" "no open pull requests"
is "spec §6.1: --no-gh still prints the six source rows, in the order gh land ledger lander budget origin" \
   "$(LC_ALL=C awk -F'\t' '$1 == "source" { printf "%s ", $3 }' "$SPX/nogh.tsv")" "gh land ledger lander budget origin "
# <<< stuck-pr-page
