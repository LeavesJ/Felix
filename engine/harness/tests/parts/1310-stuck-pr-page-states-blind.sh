# >>> stuck-pr-page-states
printf '\nthe stuck-PR page: one run over every state, the queue, and the read-only contract (spec v2 cases 1-10, 15-18, 20-27, blind)\n'
# Blind, from spec v2 alone, on the fixture part 1300 builds. One gh answer
# holds a pull request for each state and reading section 8 names; gh lists
# them in descending order, so the page's ascending order is its own. Every
# pull request is fifty hours old. "Plain" below means a path no founder rule,
# land row, risk row or trust base names: notes/N.md.
_sp_build
_sp_list
_sp_prs fixture_home "${SPLIST[@]}"
_sp_prs fixture_two "$(_sp_pr 202 notes/202.md:0 green sha="$(_sp_two 202)" repo=fixture/two)" \
                    "$(_sp_pr 201 notes/201.md:0 green sha="$(_sp_two 201)" repo=fixture/two)" \
                    "$(_sp_pr 101 notes/t101.md:0 green sha="$(_sp_two 101)" labels=needs-founder repo=fixture/two)"
_sp_prs fixture_three "$(_sp_pr 301 notes/301.md:0 green labels=needs-founder repo=fixture/three)"
rm -f "$SPK/api.rc" "$SPK/loaded" "$SPU/Library/LaunchAgents/felix.land.felix.plist"
_sp_ledger
SPN="${#SPLIST[@]}"

# ---- the four runs, each between snapshots (case 17) -------------------------
_sp_logs0
_sps0="$(_sp_snapall)"
_sp_land "$SPH" --prs --tsv; _sp_keep main.tsv; cp "$SPL/gh.log" "$SPX/main.gh.log" 2>/dev/null; cp "$SPL/gh.env" "$SPX/main.gh.env" 2>/dev/null
is "case 17: --prs --tsv prints its page and leaves the repositories and the land directories byte-identical" "$SPRC|$(_sp_snapall)" "0|$_sps0"
_sp_land "$SPH" --prs; _sp_keep main.txt
is "case 17: --prs prints its page and leaves them byte-identical" "$SPRC|$(_sp_snapall)" "0|$_sps0"
_sp_land "$SPH" --queue --tsv; _sp_keep queue.tsv
is "case 17: --queue --tsv prints its page and leaves them byte-identical" "$SPRC|$(_sp_snapall)" "0|$_sps0"
_sp_land "$SPH" --queue; _sp_keep queue.txt
is "case 17: --queue prints its page and leaves them byte-identical" "$SPRC|$(_sp_snapall)" "0|$_sps0"
is "spec §7: each of the four runs exits 0" \
   "$(cat "$SPX/main.tsv.rc")$(cat "$SPX/main.txt.rc")$(cat "$SPX/queue.tsv.rc")$(cat "$SPX/queue.txt.rc")" "0000"
_spo="$(LC_ALL=C awk 'index($0, "pr list") != 1 && index($0, "api") != 1' "$SPL/gh.log" 2>/dev/null | head -3 | LC_ALL=C tr '\n' '|')"
if [ "$(_sp_cnt gh)" -gt 0 ] && [ -z "$_spo" ]; then ok "case 17: gh was called with pr list and api only"
else bad "case 17: gh was called with pr list and api only" "$(_sp_cnt gh) calls, others: [$_spo]"; fi
_spo="$(LC_ALL=C awk 'index($0, "api") == 1' "$SPL/gh.log" 2>/dev/null | LC_ALL=C grep -E -- '(^| )(-X|--method|-f|-F|--field|--raw-field|--input)( |=|$)' | head -2)"
is "spec §2: every gh api call is a GET: no method, field or input option" "$_spo" ""
_spo="$(LC_ALL=C awk 'index($0, "print") != 1' "$SPL/launchctl.log" 2>/dev/null | head -3 | LC_ALL=C tr '\n' '|')"
is "case 17: launchctl was called with print only" "$_spo" ""
is "spec §4.3: the lander row's loaded is read with launchctl print, as --status reads it" "$([ "$(_sp_cnt launchctl)" -gt 0 ] && echo asked)" "asked"
is "spec §2: nothing ran the home's engine/harness/felix" "$(_sp_cnt trip)" 0
is "spec §2: --prs lists the pull requests with one gh pr list call" "$(_sp_prl "$SPX/main.gh.log")" 1
_spo="$(LC_ALL=C grep '^pr list' "$SPX/main.gh.log" 2>/dev/null | head -1)"
has "spec §3: the gh pr list call asks for open pull requests" "$_spo" "--state open"
has "spec §3: and up to 1000 of them" "$_spo" "--limit 1000"
_spo="$(LC_ALL=C grep '^api' "$SPX/main.gh.log" 2>/dev/null | LC_ALL=C grep 'settings/billing/usage' | head -1)"
has "spec §4.4: the budget is one gh api GET of the governed account's Actions billing" "$_spo" "fixture/settings/billing/usage"
_spo="$(LC_ALL=C awk -F'\t' -v s="$SPU/.state-caller" -v c="$SPU/.cache-caller" '
  $1 == "unset" || $2 == "unset" || $1 == s || $2 == c { b++ } END { print NR "|" b + 0 }' "$SPX/main.gh.env" 2>/dev/null)"
case "$_spo" in 0\|*|"") bad "spec §2: gh runs with its state and cache directories in a scratch directory, not the caller's" "[$_spo]" ;;
  *\|0) ok "spec §2: gh runs with its state and cache directories in a scratch directory, not the caller's" ;;
  *) bad "spec §2: gh runs with its state and cache directories in a scratch directory, not the caller's" "calls|wrong: [$_spo]" ;; esac
_spo="$(LC_ALL=C awk -F'\t' '$1 != "unset" { print $1 } $2 != "unset" { print $2 }' "$SPX/main.gh.env" 2>/dev/null | LC_ALL=C sort -u \
        | while IFS= read -r _spd; do [ -e "$_spd" ] && printf '%s ' "$_spd"; done)"
is "spec §2: and the run removes that scratch directory" "$_spo$([ -s "$SPX/main.gh.env" ] || echo 'gh never ran')" ""
is "spec §2: gh's configuration is left alone: GH_CONFIG_DIR is the caller's" \
   "$(LC_ALL=C cut -f3 "$SPX/main.gh.env" 2>/dev/null | LC_ALL=C sort -u)" "$SPU/.config/gh"

# ---- the TSV's shape (§6.1, case 18) ----------------------------------------
T="$SPX/main.tsv"
_spo="$(LC_ALL=C awk -F'\t' 'NF != 8 { b++ } END { print NR "|" b + 0 }' "$T")"
case "$_spo" in 0\|*) bad "spec §6.1: every line of --prs --tsv has eight tab-separated columns" "no lines" ;;
  *\|0) ok "spec §6.1: every line of --prs --tsv has eight tab-separated columns" ;;
  *) bad "spec §6.1: every line of --prs --tsv has eight tab-separated columns" "lines|other: [$_spo]" ;; esac
is "spec §6.1: every row is a source row or a pr row" "$(LC_ALL=C awk -F'\t' '$1 != "source" && $1 != "pr"' "$T" | head -2)$([ -s "$T" ] || echo empty)" ""
is "spec §6.1: the repo column is the owner/name slug on every row" "$(LC_ALL=C cut -f2 "$T" | LC_ALL=C sort -u)" "fixture/home"
is "spec §6.1: the six source rows come in the order gh land ledger lander budget origin" \
   "$(LC_ALL=C awk -F'\t' '$1 == "source" { printf "%s ", $3 }' "$T")" "gh land ledger lander budget origin "
is "spec §6.1: sources come first, then pull requests" \
   "$(LC_ALL=C awk -F'\t' '$1 == "pr" { p = 1 } $1 == "source" { s = 1; if (p) b = 1 } END { print (s && p) ? b + 0 : "absent" }' "$T")" 0
is "spec §6.1: pull requests come in ascending number" \
   "$(LC_ALL=C awk -F'\t' '$1 == "pr" { c++; n = substr($3, 2) + 0; if (n <= l) b = 1; l = n } END { print c ? b + 0 : "none" }' "$T")" 0
is "spec §6.1: one pr row per open pull request gh listed" "$(_sp_prn "$T")" "$SPN"
is "spec §6.1: a source row's owner, age_h and content are -" "$(_sp_srcf "$T" gh 5)|$(_sp_srcf "$T" gh 6)|$(_sp_srcf "$T" gh 7)" "-|-|-"
is "case 18: a title holding a tab gives one row" "$(_sp_nrow "$T" 118)" 1
is "case 18: of eight columns" "$(_sp_row "$T" 118 | LC_ALL=C awk -F'\t' '{ print NF }')" 8
is "spec §6.1: content is the full head SHA" "$(_sp_f "$T" 105 7)" "$(_sp_sha 105)"
_spo="$(_sp_f "$T" 105 6 | LC_ALL=C sed 's/[.].*//')"
case "$_spo" in 49|50) ok "spec §6.1: age_h is the hours since updatedAt" ;; *) bad "spec §6.1: age_h is the hours since updatedAt" "fifty hours old, age_h [$(_sp_f "$T" 105 6)]" ;; esac

# ---- the source rows of a full read -------------------------------------------
is "spec §6.1: gh answered: its source row says read" "$(_sp_srcf "$T" gh 4)" "read"
is "spec §2: the land table at origin/main was read" "$(_sp_srcf "$T" land 4)" "read"
is "spec §4.3: the ledger is there: its source row says read" "$(_sp_srcf "$T" ledger 4)" "read"
is "spec §4.3: a lock whose pid is dead names no live tick: the lander row says not-live" "$(_sp_srcf "$T" lander 4)" "not-live"
_spo="$(_sp_srcf "$T" lander 8)"
has "spec §4.3: the lander row says installed no without the job's plist" "$_spo" "installed no"
has "spec §4.3: and loaded no while launchctl print fails" "$_spo" "loaded no"
has "spec §4.3: and paused yes while paused exists" "$_spo" "paused yes"
has "spec §4.3: and gives the first line of paused" "$_spo" "held for a while"
_sp_lacks "spec §4.3: and only the first line" "$_spo" "the second line of the reason"
is "spec §4.4: the budget was read" "$(_sp_srcf "$T" budget 4)" "read"
has "spec §4.4: it gives the minutes used" "$(_sp_srcf "$T" budget 8)" "123"
has "spec §4.4, R13: and the net amount, with no included minutes to state" "$(_sp_srcf "$T" budget 8)" 'net $0.00'
is "spec §2: origin/main is there: the origin row says read" "$(_sp_srcf "$T" origin 4)" "read"

# ---- states, cases 1-10, 15, 16, 20-27 -------------------------------------
_sp_is "case 1: risk.tsv changed, checks green" "$T" 101 founder founder
has "spec §2: a founder row decided by a path says path-level" "$(_sp_f "$T" 101 8)" "path-level"
_sp_is "case 2: the same with one failed check" "$T" 102 red session
_sp_is "case 3: the same with a check still running" "$T" 103 pending nobody
_sp_is "case 4: mergeable CONFLICTING" "$T" 104 needs-session session
_sp_not "case 4: mergeable UNKNOWN is not a conflict" "$T" 147 needs-session
has "case 4: and is the flag mergeable-unknown" "$(_sp_flags "$T" 147)" ",mergeable-unknown"
_sp_is "case 5: green, not a draft, its own head branch, no founder or trust-base path, no ledger row" "$T" 105 ready lander
is "case 5: a ready pull request with no flag has the bare state" "$(_sp_f "$T" 105 4)" "ready"
is "spec §4.2: a green head is SUCCESS, SKIPPED and NEUTRAL checks only, and #105 had all three (control)" \
   "$(printf '%s\n' "${SPLIST[@]}" | LC_ALL=C grep '^{"number":105,' | LC_ALL=C grep -o '"conclusion":"[A-Z]*"' | LC_ALL=C sort -u | LC_ALL=C tr '\n' ' ')" \
   '"conclusion":"NEUTRAL" "conclusion":"SKIPPED" "conclusion":"SUCCESS" '
_sp_is "case 6: felix:hold on a conflicting, red pull request" "$T" 106 held session
_sp_is "case 6: Felix:Hold the same" "$T" 107 held session
_sp_is "spec §3: FELIX:HOLD on a green founder-lane pull request: held comes before founder" "$T" 150 held session
_sp_is "case 7: a head in a fork, with an escape path" "$T" 108 outside nobody
_sp_is "case 7: another author, with an escape path" "$T" 109 outside nobody
_sp_is "case 8: base claude/other" "$T" 110 stacked nobody
has "case 8: the base is named in the detail" "$(_sp_f "$T" 110 8)" "claude/other"
_sp_is "case 9: engine/harness/felix changed, green" "$T" 111 ready lander
_sp_is "case 10: exactly 100 files, green, no label" "$T" 112 unknown unknown
has "spec §5: its detail says the files were not read" "$(_sp_f "$T" 112 8)" "files not read: GitHub lists at most 100"
_sp_is "case 10: exactly 100 files with a failed check: state 5 comes before 7" "$T" 113 red session
_sp_is "case 11: a land-table founder row on origin/main matching a changed path" "$T" 114 founder founder
has "spec §4.5: its detail names the rule land" "$(_sp_f "$T" 114 8)" "land"
has "spec §2: and says path-level" "$(_sp_f "$T" 114 8)" "path-level"
_sp_not "case 11: the same kind of row only in the working tree makes nothing founder" "$T" 115 founder
_sp_is "case 15: BEHIND: the state is decided by the rest" "$T" 116 ready lander
is "case 15: and carries the flag behind" "$(_sp_f "$T" 116 4)" "ready,behind"
_sp_is "case 16: a head with no checks" "$T" 117 unready session
has "case 16: its detail says no checks ran on the head" "$(_sp_f "$T" 117 8)" "no checks ran on the head"
_sp_not "case 20: qualification.tsv with only added lines is not founder" "$T" 120 founder
_sp_is "case 20: qualification.tsv with one deleted line" "$T" 121 founder founder
has "case 20: by the rule verifier" "$(_sp_f "$T" 121 8)" "verifier"
has "spec §2: and says path-level" "$(_sp_f "$T" 121 8)" "path-level"
_sp_is "case 20: ecosystem.tsv with only added lines" "$T" 122 founder founder
has "case 20: by the rule exemption" "$(_sp_f "$T" 122 8)" "exemption"
_sp_is "case 20: .github/workflows/x.yml" "$T" 123 founder founder
has "case 20: by the rule execute" "$(_sp_f "$T" 123 8)" "execute"
_sp_is "case 20: projects/felix/autonomy" "$T" 124 founder founder
has "case 20: by the rule authority" "$(_sp_f "$T" 124 8)" "authority"
_sp_is "case 20: stack.tsv with only added lines" "$T" 125 founder founder
has "case 20: by the rule commission" "$(_sp_f "$T" 125 8)" "commission"
_sp_is "case 21: risk.tsv and engine/harness/felix, green" "$T" 119 founder founder
has "case 21: and the detail also says trust base" "$(_sp_f "$T" 119 8)" "trust base"
_sp_is "case 22: a risk path row with a channel and no confine" "$T" 128 founder founder
has "case 22: by the rule risk" "$(_sp_f "$T" 128 8)" "risk"
has "spec §2: and says path-level" "$(_sp_f "$T" 128 8)" "path-level"
_sp_not "case 22: the same row with a confine makes nothing founder" "$T" 129 founder
has "case 22: and the detail says the row was not evaluated" "$(_sp_f "$T" 129 8)" "risk row not evaluated: content confine"
_sp_not "spec §4.5: a risk row only in the working tree makes nothing founder" "$T" 127 founder
_sp_is "case 23: the last ledger row refused this head on the current origin/main" "$T" 130 refused session
has "case 23: the detail holds the refusal's detail" "$(_sp_f "$T" 130 8)" "the lander was refused: blocker one: the receipt is stale"
_sp_lacks "spec §4.3: without its [main] part" "$(_sp_f "$T" 130 8)" "[main"
_sp_is "case 23: the same row on an older main decides nothing" "$T" 131 ready lander
has "spec §4.3: its detail says what the lander last saw" "$(_sp_f "$T" 131 8)" "the lander last saw $(_sp_sha 131 | LC_ALL=C cut -c1-7): refused"
_sp_is "case 23: the same row for an older head decides nothing" "$T" 132 ready lander
has "case 23: and the detail says the lander last saw that head" "$(_sp_f "$T" 132 8)" "the lander last saw $(_sp_old 132 | LC_ALL=C cut -c1-7): refused"
_sp_is "case 23: a session row on the head" "$T" 133 refused session
has "spec §4.3: its detail says the lander cannot use it" "$(_sp_f "$T" 133 8)" "the lander cannot use it: no checkout holds the gated head"
_sp_is "case 23: a landed row on an older head decides nothing, nor a refused row of pull request 1340" "$T" 134 ready lander
has "spec §4.3: its detail says the lander last saw the older head land" "$(_sp_f "$T" 134 8)" "the lander last saw $(_sp_old 134 | LC_ALL=C cut -c1-7): landed"
_sp_is "spec §4.3: only the last row counts: a skip after a refusal on the same head and main decides nothing" "$T" 135 ready lander
has "spec §4.3: it is listed as the lander, the event, its detail" "$(_sp_f "$T" 135 8)" "the lander: skip: waiting on its gate run"
_sp_is "case 24: a green draft with nothing else" "$T" 136 unready session
is "case 24: with the flag draft" "$(_sp_f "$T" 136 4)" "unready,draft"
has "case 24: and the detail a draft: the tick merges no draft" "$(_sp_f "$T" 136 8)" "a draft: the tick merges no draft"
is "spec §4: a draft is a flag on every state: a red draft" "$(_sp_f "$T" 145 4)" "red,draft"
is "spec §6.1: the flags follow the state in the order draft, behind, mergeable-unknown" "$(_sp_f "$T" 146 4)" "unready,draft,behind,mergeable-unknown"
_sp_is "case 25: two open green pull requests with one head branch" "$T" 137 unready session
_sp_is "case 25: both of them" "$T" 138 unready session
has "case 25: each detail names the other: #137's" "$(_sp_f "$T" 137 8)" "head branch shared-b is also #138's"
has "case 25: each detail names the other: #138's" "$(_sp_f "$T" 138 8)" "head branch shared-b is also #137's"
_sp_is "case 26: NEEDS-FOUNDER on a green pull request with no founder path" "$T" 139 founder founder
_sp_is "case 26: Felix:Founder the same" "$T" 140 founder founder
_sp_is "case 27: projects/felix/CLAUDE.md" "$T" 141 founder founder
has "case 27: by the rule direction" "$(_sp_f "$T" 141 8)" "direction"
_sp_is "case 27: projects/felix/claude.md" "$T" 142 founder founder
has "case 27: by the rule direction" "$(_sp_f "$T" 142 8)" "direction"
_sp_is "case 27: docs/2026-09-23-roadmap.md" "$T" 143 founder founder
has "case 27: by the rule direction" "$(_sp_f "$T" 143 8)" "direction"
_sp_is "case 27: a path holding a byte outside printable ASCII" "$T" 144 founder founder
has "case 27: by the rule path-bytes" "$(_sp_f "$T" 144 8)" "path-bytes"
_sp_is "spec §4: a StatusContext in state ERROR is a failed check" "$T" 148 red session
_sp_is "spec §4: a StatusContext in state PENDING has not finished" "$T" 149 pending nobody

# ---- the text page (§6.2) ------------------------------------------------------
X="$SPX/main.txt"
is "spec §6.2: each pull request takes one line: one line for #118, whose title holds a tab" "$(_sp_tline "$X" 118 | LC_ALL=C awk 'END { print NR }')" 1
has "spec §6.2: a line is #N state title: detail" "$(_sp_tline "$X" 101)" "#101 founder Change 101: "
_spo="$(_sp_tline "$X" 105)"
has "spec §6.2: the title is cut at 60" "$_spo" "#105 ready $_spt$_spt"
_sp_lacks "spec §6.2: and nothing of it past 60 is printed" "$_spo" "AB"
_spo="$(_sp_tno "$X" 101) $(_sp_tno "$X" 104) $(_sp_tno "$X" 105) $(_sp_tno "$X" 110) $(_sp_tno "$X" 112)"
is "spec §6.2: founder first, then sessions, then the lander, then nobody, then unknown" \
   "$(printf '%s' "$_spo" | LC_ALL=C awk 'NF == 5 && $1 < $2 && $2 < $3 && $3 < $4 && $4 < $5 { print "in order" }')" "in order"
_spo="$(_sp_tno "$X" 101) $(_sp_tno "$X" 114) $(_sp_tno "$X" 144) $(_sp_tno "$X" 102) $(_sp_tno "$X" 104) $(_sp_tno "$X" 111)"
is "spec §6.2: within a group in ascending number" \
   "$(printf '%s' "$_spo" | LC_ALL=C awk 'NF == 6 && $1 < $2 && $2 < $3 && $4 < $5 && $5 < $6 { print "in order" }')" "in order"
_spo="$(LC_ALL=C sed -n '$p' "$X")"
has "spec §6.2: the last line counts the pull requests per state: founder" "$_spo" "founder"
has "spec §6.2: and ready" "$_spo" "ready"
has "spec §6.2: and unknown" "$_spo" "unknown"

# ---- the queue (§6.1, §6.3) ---------------------------------------------------
Q="$SPX/queue.tsv"
is "spec §6.1: --queue --tsv prints eight columns on every line" "$(LC_ALL=C awk -F'\t' 'NF != 8' "$Q" | head -2)$([ -s "$Q" ] || echo empty)" ""
is "spec §6.1: --queue --tsv prints pr rows in state founder only" \
   "$(LC_ALL=C awk -F'\t' '$1 == "pr" && $4 !~ /^founder(,|$)/' "$Q" | head -2)" ""
is "spec §6.1: the home's founder pull requests, each once, in ascending order" \
   "$(LC_ALL=C awk -F'\t' '$1 == "pr" && $2 == "fixture/home" { printf "%s ", $3 }' "$Q")" \
   "#101 #114 #119 #121 #122 #123 #124 #125 #128 #139 #140 #141 #142 #143 #144 "
is "case 1: #101 appears in --queue exactly once" "$(LC_ALL=C awk -F'\t' '$1 == "pr" && $2 == "fixture/home" && $3 == "#101"' "$Q" | LC_ALL=C awk 'END { print NR }')" 1
is "case 2: the red #102 is absent from --queue" "$(LC_ALL=C awk -F'\t' '$1 == "pr" && $3 == "#102"' "$Q")" ""
is "case 3: the pending #103 is absent from --queue" "$(LC_ALL=C awk -F'\t' '$1 == "pr" && $3 == "#103"' "$Q")" ""
is "case 7: outside pull requests are never in --queue, escape paths and all" "$(LC_ALL=C awk -F'\t' '$1 == "pr" && ($3 == "#108" || $3 == "#109")' "$Q")" ""
is "spec §6.1: --queue gives one gh source row per project naming a remote_match" \
   "$(LC_ALL=C awk -F'\t' '$1 == "source" && $3 == "gh" { print $2 }' "$Q" | LC_ALL=C sort | LC_ALL=C tr '\n' ' ')" "fixture/home fixture/three fixture/two "
is "spec §6.1: and no other source row" "$(LC_ALL=C awk -F'\t' '$1 == "source" && $3 != "gh"' "$Q" | head -2)" ""
is "spec §6.3: two projects never list the same pull request: no row pairs one repository with the other's head" \
   "$(LC_ALL=C awk -F'\t' -v h="$(_sp_sha 101)" -v t="$(_sp_two 101)" '$1 == "pr" && (($2 == "fixture/home" && $7 == t) || ($2 == "fixture/two" && $7 == h))' "$Q")" ""
# Review F5: the check above passed on no rows while two's pull requests were
# all unknown in the queue. Two's founder #101 must be there for it to mean
# anything: once, under fixture/two, with two's head, beside home's #101.
is "spec §6.3: --queue lists two's founder pull request #101 exactly once, under fixture/two, with two's head" \
   "$(LC_ALL=C awk -F'\t' '$1 == "pr" && $2 == "fixture/two" && $3 == "#101" { printf "%s|", $7 }' "$Q")" "$(_sp_two 101)|"
is "spec §6.3: and home's #101 exactly once, under fixture/home, with home's head" \
   "$(LC_ALL=C awk -F'\t' '$1 == "pr" && $2 == "fixture/home" && $3 == "#101" { printf "%s|", $7 }' "$Q")" "$(_sp_sha 101)|"
is "spec §6.1: two's founder pull requests in --queue are #101 alone: its ready and refused ones are not founder" \
   "$(LC_ALL=C awk -F'\t' '$1 == "pr" && $2 == "fixture/two" { printf "%s ", $3 }' "$Q")" "#101 "
has "spec §6.2: the queue's text lists the founder pull request" "$(cat "$SPX/queue.txt")" "#101 founder"
# <<< stuck-pr-page-states
