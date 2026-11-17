# >>> lost-work-page-groups
printf '\nthe lost-work page, step 6: felix monitor groups, --tsv, counts, the text page, read-only (contract B1-B7, B9.26-28, 32-34, 39, blind)\n'
# Blind, from docs/2026-10-18-lost-work-page-contract.md alone, on part 1450's
# stubs, builders and readers. The page repository pg is also the Felix home
# (FELIX_HOME), as step 5's fixture is: projects/pg governs
# github.com/fixture/pg, with a land table and a risk table at origin/main and
# a pending handoff section. Its worktrees and branches hold one row for each
# group B9.26 names, and gh lists one open PR in each of step 5's states:
# #301 founder (needs-founder, green), #302 session (a failed check), #303
# lander (green, nothing else; its head b303 also carries lw-carried-q7),
# #304 nobody (a check still running), #305 unknown (exactly 100 files, green).
# Part 1480 runs the page again over this fixture. _lw_pg_build in
# tests/lib/lost-work.sh builds it (moved there for gate friction C).
_lw_build; _lw_pg_build
is "B9.26 fixture: lw-carried-q7 is a proper ancestor of #303's head, the shared branch is in two worktrees, and lw-landed-q8 is on main (fixture control)" \
   "$(_lw_anc "$PG" "$LWQ7X" "$LWH303")$(_lw_anc "$PG" "$LWQ7X" refs/remotes/origin/main)$(_lw_anc "$PG" "$LWPG0" refs/remotes/origin/main) $(_lwg "$PG" worktree list --porcelain 2>/dev/null | LC_ALL=C grep -c '^branch refs/heads/lw-shared-q1$')" \
   "yny 2"

# ---- the runs -----------------------------------------------------------------
# The page as --tsv and as text, each between read-only snapshots; then the two
# sources alone with the same options, as B9.27 asks.
_lw_snap() {  # REPO DIR...: refs, index, config, HEAD and object count of REPO, then each DIR's paths and file sums
  local r="$1" d; shift
  _lwg "$r" for-each-ref --format='%(objectname) %(refname)' 2>&1
  printf 'index %s\nconfig %s\nhead %s\n' "$(cksum < "$r/.git/index" 2>&1)" "$(cksum < "$r/.git/config" 2>&1)" "$(cat "$r/.git/HEAD" 2>&1)"
  _lwg "$r" count-objects -v 2>&1 | LC_ALL=C grep -E '^(count|in-pack|packs|size-pack):'
  for d in "$@"; do ( cd "$d" && find . -print | LC_ALL=C sort && find . -type f -exec cksum {} + | LC_ALL=C sort ) 2>&1; done
}
rm -rf "$LWL"; mkdir -p "$LWL"; rm -f "$PG/state/monitor.html"
_lwsnap0="$(_lw_snap "$PG" "$PG" "$LWM")"
_lw_run PT "$LW_HP" "$LW/cwd" monitor --tsv --repo "$PG"
_lwsnap1="$(_lw_snap "$PG" "$PG" "$LWM")"
_lw_run PX "$LW_HP" "$LW/cwd" monitor --repo "$PG"
_lwsnap2="$(_lw_snap "$PG" "$PG" "$LWM")"
LWTMP_LEFT="$(ls -A "$LWT")"; cp "$LWL/gh.log" "$LWX/page.gh.log" 2>/dev/null; cp "$LWL/launchctl.log" "$LWX/page.lc.log" 2>/dev/null
_lw_run IV "$LW_HP" "$LW/cwd" inventory --tsv --repo "$PG"
_lw_run LD "$LW_HP" "$LW/cwd" land --prs --tsv --repo "$PG"
_lw_run PC "$LW_HP" "$PGR" monitor --tsv
P="$(_lw_o PT)"; X="$(_lw_o PX)"
is "B8: the page over one readable repository exits 0, as --tsv and as text, and the TSV holds its 17 summaries" "$(_lw_rc PT)$(_lw_rc PX) $(_lw_n16 "$(_lw_o PT)")" "00 17"
is "B9.27 control: the two sources alone exit 0 and print rows" "$(_lw_rc IV)$(_lw_rc LD) $([ -s "$(_lw_o IV)" ] && [ -s "$(_lw_o LD)" ] && echo rows)" "00 rows"

# ---- B9.34: read-only ------------------------------------------------------------
# The first lines that differ, or "unchanged".
_lw_same() { if [ "$1" = "$2" ]; then printf unchanged; else diff <(printf '%s\n' "$1") <(printf '%s\n' "$2") | LC_ALL=C awk 'NR <= 4 { printf "%s; ", $0 }'; fi; }
is "B9.34: after felix monitor --tsv the repository's refs, index, config, HEAD and object count, the home and the memory root are unchanged" \
   "$(_lw_same "$_lwsnap0" "$_lwsnap1")" unchanged
is "B9.34: and after felix monitor as text" "$(_lw_same "$_lwsnap0" "$_lwsnap2")" unchanged
LW_RAN="$([ -s "$LWX/page.gh.log" ] && echo ran || echo 'sources never ran')"
is "B9.34: neither run wrote state/monitor.html" "$([ -e "$PG/state/monitor.html" ] && echo written || echo absent)" absent
is "B9.34: the page ran its sources, and its scratch directory and theirs are gone when it ends" "$LW_RAN|$LWTMP_LEFT" "ran|"
_lwo="$(LC_ALL=C awk 'index($0, "pr list") != 1 && index($0, "api") != 1' "$LWX/page.gh.log" 2>/dev/null | head -3 | LC_ALL=C tr '\n' '|')"
is "B9.34: gh was asked something, and only pr list and api" "$([ -s "$LWX/page.gh.log" ] && echo asked)|$_lwo" "asked|"
_lwo="$(LC_ALL=C grep '^api' "$LWX/page.gh.log" 2>/dev/null | LC_ALL=C grep -E -- '(^| )(-X|--method|-f|-F|--field|--raw-field|--input)( |=|$)' | head -2)"
is "B2: the page ran its sources, and every gh api call it caused is a GET" "$LW_RAN|$_lwo" "ran|"
_lwo="$(LC_ALL=C awk 'index($0, "print") != 1' "$LWX/page.lc.log" 2>/dev/null | head -3 | LC_ALL=C tr '\n' '|')"
is "B9.34: launchctl was asked, and only print" "$([ -s "$LWX/page.lc.log" ] && echo asked)|$_lwo" "asked|"
is "B2: the page ran its sources and opened nothing" "$LW_RAN|$([ -e "$LWL/open.log" ] && echo opened || echo none)" "ran|none"

# ---- B9.27: nothing dropped or added -------------------------------------------
# The page's rows other than summaries, the group cut off, against the two
# sources' rows, each put through B7's filter for bytes below 0x20 (tab and
# line feed kept) and 0x7f. The age_h cell and the digits of the detail are
# read as N on both sides: they are times, and the runs are seconds apart.
_lwa="$(LC_ALL=C awk -F'\t' '$2 != "summary"' "$P" | LC_ALL=C cut -f2- | _lw_norm)"
_lwb="$(cat "$(_lw_o IV)" "$(_lw_o LD)" | _lw_norm)"
is "B9.27: the page's non-summary rows, first column cut, equal the rows of felix inventory --tsv and felix land --prs --tsv as a multiset" \
   "$([ -n "$_lwb" ] && echo sources)|$_lwa" "sources|$_lwb"
is "B9.27: every page row has nine tab-separated columns" \
   "$(LC_ALL=C awk -F'\t' 'NF != 9 { b++ } END { print (NR ? b + 0 : "no rows") }' "$P")" 0
is "B5: a source row's repo cell is its source's own: the main worktree path for the inventory, the slug for land" \
   "$(LC_ALL=C awk -F'\t' '$2 == "cover" { c[$3] = 1 } $2 == "source" { s[$3] = 1 } END { for (k in c) printf "cover:%s ", k; for (k in s) printf "source:%s ", k }' "$P")" \
   "cover:$PGR source:fixture/pg "
is "B1: with no --repo the page reads the repository holding the current directory" \
   "$(_lw_rc PC) $(_lw_n16 "$(_lw_o PC)") $(LC_ALL=C awk -F'\t' '$2 == "summary" { printf "%s=%s ", $1, $8 }' "$(_lw_o PC)")" \
   "0 17 $(LC_ALL=C awk -F'\t' '$2 == "summary" { printf "%s=%s ", $1, $8 }' "$P")"

# ---- B9.26: groups -----------------------------------------------------------------
# B3 as the contract states it, applied to the page's own cells: land's source
# rows and the inventory's cover rows are cover; land's pr rows go by their
# owner; the inventory's other rows take the first group whose condition holds.
_lw_b3() { LC_ALL=C awk -F'\t' -v land="$2" '
  function h(x) { return index("," st ",", "," x ",") > 0 }
  $2 == "summary" { next }
  { st = $5; k = $2; g = "" }
  k == "cover" || k == "source" { g = "cover" }
  g == "" && k == "pr" && $3 == land { o = $6; g = (o == "founder" || o == "session" || o == "lander" || o == "unknown" || o == "nobody") ? "pr-" o : "?" }
  g == "" { u = 0; n = split(st, s, ","); for (i = 1; i <= n; i++) if (index(s[i], "unknown:") == 1 && s[i] != "unknown:live") u = 1
    if (h("hazard:shared-branch") || h("hazard:staged-revert")) g = "hazard"; else if (h("blocked")) g = "blocked"
    else if (h("question")) g = "question"; else if (h("live")) g = "running"
    else if (h("uncommitted") || h("unpushed") || h("unproposed") || h("pr-closed-unlanded") || h("chip-unstarted") || (h("orphan") && $8 != "landed")) g = "never-proposed"
    else if (h("pr-open")) g = "proposed"; else if (h("carried")) g = "carried"; else if (h("handoff-pending")) g = "handoff"
    else if (u || $8 == "not" || $8 == "partly") g = "undecided"; else if (h("landed")) g = "landed"; else g = "quiet" }
  $1 != g { b++; if (b <= 3) w = w " [" $2 " " $4 ": " $1 " not " g "]" }
  { r++ }
  END { printf "%d rows, %d in the wrong group%s", r, b, w }' "$1"; }
_lwo="$(_lw_b3 "$P" fixture/pg)"
case "$_lwo" in
  *" rows, 0 in the wrong group") [ "${_lwo%% *}" -ge 25 ] 2>/dev/null && ok "B9.26: every row's group is the one B3 gives" || bad "B9.26: every row's group is the one B3 gives" "too few rows: $_lwo" ;;
  *) bad "B9.26: every row's group is the one B3 gives" "$_lwo" ;;
esac
_lw_g() { _lw_col "$P" "$1" "$2" 0 1; }   # the group cell of the page row KIND REF
is "B9.26: the shared-branch worktrees are hazard" "$(_lw_g worktree "$LWW/share-a-q1") $(_lw_g worktree "$LWW/share-b-q1")" "hazard hazard"
is "B9.26: the blocked worktree is blocked, the question worktree question" "$(_lw_g worktree "$LWW/blocked-q2") $(_lw_g worktree "$LWW/ask-q3")" "blocked question"
is "B9.26: the live worktree with uncommitted work is running" "$(_lw_g worktree "$LWW/live-q4") $(_lw_holds "$P" worktree "$LWW/live-q4" uncommitted 1)" "running yes"
is "B9.26: the unproposed branch, the uncommitted worktree and the unstarted chip are never-proposed" \
   "$(_lw_g branch lw-unprop-q5) $(_lw_g worktree "$LWW/dirty-q9") $(_lw_g chip task_c0ffee01)" "never-proposed never-proposed never-proposed"
is "B9.26: the carried branch is carried, the landed branch landed" "$(_lw_g branch lw-carried-q7) $(_lw_g branch lw-landed-q8)" "carried landed"
is "B9.26: the pending handoff section is handoff" \
   "$(LC_ALL=C awk -F'\t' '$2 == "handoff" { printf "%s ", $1 }' "$P")" "handoff "
LW_REPO=fixture/pg
is "B9.26: land's PRs go by owner: #301 pr-founder, #302 pr-session, #303 pr-lander, #304 pr-nobody, #305 pr-unknown" \
   "$(_lw_g pr '#301') $(_lw_g pr '#302') $(_lw_g pr '#303') $(_lw_g pr '#304') $(_lw_g pr '#305')" "pr-founder pr-session pr-lander pr-nobody pr-unknown"
is "B9.26: and land's own rows say those owners (control)" \
   "$(_lw_col "$(_lw_o LD)" pr '#301' 5) $(_lw_col "$(_lw_o LD)" pr '#302' 5) $(_lw_col "$(_lw_o LD)" pr '#303' 5) $(_lw_col "$(_lw_o LD)" pr '#304' 5) $(_lw_col "$(_lw_o LD)" pr '#305' 5)" \
   "founder session lander nobody unknown"
LW_REPO=""

# ---- B9.28 and B4: summaries ------------------------------------------------------------
LW_GROUPS='hazard blocked question never-proposed pr-founder pr-session pr-lander pr-unknown undecided running helper pr-nobody proposed carried handoff landed quiet'
is "B9.28: the page opens with 17 summary rows, in B5's group order, each with ref the group and owner and age -" \
   "$(LC_ALL=C awk -F'\t' 'NR <= 17 { printf "%s%s", s, ($2 == "summary" && $4 == $1 && $6 == "-" && $7 == "-" && $3 == r) ? $1 : "[" $0 "]"; s = " " }' r="$PGR" "$P")" "$LW_GROUPS"
is "B9.28: and holds no other summary row" "$(LC_ALL=C awk -F'\t' '$2 == "summary" { n++ } END { print n + 0 }' "$P")" 17
# B4's completeness, from the cover rows, land's gh row and the rows' unknown:
# entries; the count said is the rows in the group, or unknown when it is
# incomplete with none; the detail is - when complete.
_lw_b4() { LC_ALL=C awk -F'\t' -v groups="$LW_GROUPS" '
  function first(x) { sub(/,.*/, "", x); return x }
  function has(x, w) { return index("," x ",", "," w ",") > 0 }
  $2 == "summary" { next }
  $2 == "cover" { cov[$4] = first($5) }
  $2 == "source" && $4 == "gh" { gh = first($5); ghseen = 1 }
  $2 != "cover" && $2 != "source" { n[$1]++
    if (has($5, "unknown:hazard:shared-branch") || has($5, "unknown:hazard:staged-revert")) ux["hazard"] = 1
    if (has($5, "unknown:blocked")) ux["blocked"] = 1; if (has($5, "unknown:question")) ux["question"] = 1; if (has($5, "unknown:live")) ux["running"] = 1; if (has($5, "unknown:helper")) ux["helper"] = 1
    if (has($5, "unknown:uncommitted") || has($5, "unknown:unpushed") || has($5, "unknown:unproposed") || has($5, "unknown:pr-closed-unlanded") || has($5, "unknown:orphan") || has($5, "unknown:chip-unstarted")) ux["never-proposed"] = 1 }
  END { ghbad = (!ghseen || (gh != "read" && gh != "none"))
    sess = (cov["sessions"] != "read")
    inc["hazard"] = ux["hazard"]; inc["blocked"] = sess || ux["blocked"]; inc["question"] = sess || ux["question"]; inc["running"] = sess || ux["running"]; inc["helper"] = sess || ux["helper"]
    inc["never-proposed"] = (cov["default"] != "read" || cov["prs"] != "read" || cov["chips"] != "read" || ux["never-proposed"])
    inc["pr-founder"] = inc["pr-session"] = inc["pr-lander"] = (ghbad || n["pr-unknown"] > 0); inc["pr-unknown"] = inc["pr-nobody"] = ghbad
    k = split(groups, g, " ")
    for (i = 1; i <= k; i++) { c = n[g[i]] + 0; printf "%s=%s:%s ", g[i], (inc[g[i]] ? "incomplete" : "complete"), ((inc[g[i]] && c == 0) ? "unknown" : c) } }' "$1"; }
_lw_sums() { LC_ALL=C awk -F'\t' -v groups="$LW_GROUPS" '$2 == "summary" { v[$1] = $5 ":" $8 } END { k = split(groups, g, " "); for (i = 1; i <= k; i++) printf "%s=%s ", g[i], v[g[i]] }' "$1"; }
is "B9.28: each summary's content is the number of rows in its group, and its state is the completeness B4 gives" "$(_lw_sums "$P")" "$(_lw_b4 "$P")"
is "B5: a complete summary's detail is -" \
   "$(LC_ALL=C awk -F'\t' '$2 == "summary" && $5 == "complete" && $9 != "-" { printf "%s ", $1 } $2 == "summary" && $5 == "complete" { c++ } END { if (!c) print "no complete summary" }' "$P")" ""
# B9.32
is "B9.32: with one PR in pr-unknown, pr-founder, pr-session and pr-lander are incomplete" \
   "$(_lw_g summary pr-founder) $(_lw_st "$P" summary pr-founder 1) $(_lw_st "$P" summary pr-session 1) $(_lw_st "$P" summary pr-lander 1)" \
   "pr-founder incomplete incomplete incomplete"
is "B9.32: and pr-founder's reason says 1 pull requests not decided" "$(_lw_elem "$P" summary pr-founder '1 pull requests not decided' 1)" yes
is "B9.32: pr-unknown and pr-nobody stay complete while gh was read" "$(_lw_st "$P" summary pr-unknown 1) $(_lw_st "$P" summary pr-nobody 1)" "complete complete"

# ---- B6, B9.33: the text page -----------------------------------------------------------
is "B6: the first line says what the page did and did not do, once" \
   "$(LC_ALL=C sed -n 1p "$X")|$(LC_ALL=C awk -v h="$LW_HEAD" '$0 == h { n++ } END { print n + 0 }' "$X")" "$LW_HEAD|1"
is "B6: the block is headed by the repository's path, then one read line per cover row, the inventory's then land's" \
   "$(LC_ALL=C sed -n 2p "$X")|$(LC_ALL=C awk '/^  read / { printf "%s ", $2 }' "$X")" \
   "$PGR|$(LC_ALL=C awk -F'\t' '$2 == "cover" || $2 == "source" { printf "%s ", $4 }' "$P")"
LW_LABELS='hazards|blocked sessions|open questions|work that never reached a PR|pull requests waiting on the founder|pull requests waiting on a session|pull requests ready for the lander|pull requests not decided|rows not decided'
is "B9.33: the needs-you headings are all there, in B6's order, under needs you" \
   "$(LC_ALL=C awk -v l="$LW_LABELS" 'BEGIN { n = split(l, t, "|") } $0 == "  needs you" { y = 1 } y { for (i = 1; i <= n; i++) if (index($0, "    " t[i] ": ") == 1) printf "%s|", t[i] }' "$X")" "$LW_LABELS|"
# Each heading as B4 says its count, from the --tsv run's summaries.
_lw_heads() { LC_ALL=C awk -F'\t' -v l="$LW_LABELS" '
  BEGIN { split(l, t, "|"); split("hazard blocked question never-proposed pr-founder pr-session pr-lander pr-unknown undecided", g, " "); for (i = 1; i <= 9; i++) lab[g[i]] = t[i] }
  $2 == "summary" && ($1 in lab) { c = ($5 == "complete") ? $8 : ($8 == "unknown" ? "unknown" : "at least " $8); if ($5 != "complete") c = c " (" $9 ")"; printf "    %s: %s\n", lab[$1], c }' "$1"; }
is "B6: each heading says its count as B4 says it, with the reasons after an incomplete group" \
   "$(_lw_heads "$P" | LC_ALL=C awk 'END { print NR }')|$(LC_ALL=C awk -v l="$LW_LABELS" 'BEGIN { n = split(l, t, "|") } { for (i = 1; i <= n; i++) if (index($0, "    " t[i] ": ") == 1) print }' "$X")" "9|$(_lw_heads "$P")"
_lwc="$(LC_ALL=C awk -F'\t' '$2 == "summary" { c[$1] = $8 } END { printf "  collapsed: running %s, helper worktrees %s, pull requests waiting on nobody %s, proposed %s, carried %s, handoff sections %s, landed %s, quiet %s", c["running"], c["helper"], c["pr-nobody"], c["proposed"], c["carried"], c["handoff"], c["landed"], c["quiet"] }' "$P")"
is "B9.33: the collapsed line comes last, after every heading, with the collapsed groups' counts" \
   "$(LC_ALL=C awk 'END { print }' "$X")|$(LC_ALL=C awk '/^    [a-z ]+: / { h = NR } /^  collapsed: / { c = NR } END { print (c > h && h > 0) ? "after" : "before" }' "$X")" "$_lwc|after"
# A listed row is a line that starts, after its indent, with the ref and a space.
_lw_tl() { LC_ALL=C awk -v r="$2 " '{ s = $0; sub(/^ +/, "", s); if (index(s, r) == 1) n++ } END { print n + 0 }' "$1"; }
_lw_tn() { LC_ALL=C awk -v r="$2" '{ s = $0; while ((i = index(s, r)) > 0) { z = substr(s, i + length(r), 1); if (z == "" || z == " " || z == ":" || z == ",") { n++; break } s = substr(s, i + length(r)) } } END { print n + 0 }' "$1"; }
is "B9.33: the hazard row is listed, while the running, carried and landed rows appear on no line of the text page" \
   "$(_lw_tl "$X" "$LWW/share-a-q1") $(_lw_tn "$X" "$LWW/live-q4") $(_lw_tn "$X" lw-carried-q7) $(_lw_tn "$X" lw-landed-q8)" "1 0 0 0"
_lwo="$(LC_ALL=C awk -F'\t' '$1 == "handoff" && $2 != "summary" { print $4; exit }' "$P")"
is "B9.33: nor the handoff row" "$([ -n "$_lwo" ] && _lw_tn "$X" "$_lwo" || echo 'no handoff row')" 0
is "B9.33: the hazard, blocked, question, unproposed, chip and PR rows are each listed once" \
   "$(for _lwi in "$LWW/share-a-q1" "$LWW/share-b-q1" "$LWW/blocked-q2" "$LWW/ask-q3" lw-unprop-q5 task_c0ffee01 '#301' '#302' '#303' '#305'; do printf '%s' "$(_lw_tl "$X" "$_lwi")"; done)" "1111111111"
is "B9.33: the PR waiting on a session is listed and the one waiting on nobody collapsed" "$(_lw_tl "$X" '#302') $(_lw_tn "$X" '#304')" "1 0"
_lwo="$(LC_ALL=C awk -F'\t' -v r="$LWW/blocked-q2" '$2 == "worktree" && $4 == r { print $5 "|" $6; exit }' "$P")"
is "B6: an inventory row line is <ref> <states>, then the session's first 8 characters" \
   "$(LC_ALL=C awk -v p="      $LWW/blocked-q2 ${_lwo%|*}" -v s=", session ${LWS_BLK:0:8}: " 'index($0, p) == 1 && index($0, s) { print "found"; exit }' "$X")" found
is "B6: a land pr row line is <ref> <states>" \
   "$(LC_ALL=C awk -v p="      #302 $(LC_ALL=C awk -F'\t' '$2 == "pr" && $4 == "#302" && $3 == "fixture/pg" { print $5; exit }' "$P")" 'index($0, p) == 1 { print "found"; exit }' "$X")" found

# ---- B9.39: the terminal filter -----------------------------------------------------------
is "B9.39 control: the inventory alone prints the chip's title with its ESC and BEL bytes" \
   "$(_lw_col "$(_lw_o IV)" chip task_c0ffee01 8)" "$LW_CHIPT"
is "B9.39: the TSV prints ? for the ESC and the BEL of a chip title" "$(_lw_col "$P" chip task_c0ffee01 8 1)" "Page chip ?[31m red ? bell"
is "B9.39: the text page prints them as ? too" "$(LC_ALL=C grep -c 'Page chip ?\[31m red ? bell' "$X")" 1
is "B9.39: the chip is on the page, and no ESC or BEL byte reaches either page" "$(_lw_kind "$P" task_c0ffee01 1) $(cat "$P" "$X" | LC_ALL=C tr -cd '\033\007' | LC_ALL=C wc -c | LC_ALL=C tr -d ' ')" "chip 0"
# <<< lost-work-page-groups
