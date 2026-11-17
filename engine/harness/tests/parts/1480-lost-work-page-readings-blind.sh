# >>> lost-work-page-readings
printf '\nthe lost-work page, step 6: unknown is said, the log page, usage, exit status, two repositories (contract B1, B4, B6, B8, B9.29-31, 35-38, blind)\n'
# Blind, from docs/2026-10-18-lost-work-page-contract.md alone, on part 1470's
# page fixture pg and part 1450's helpers, both now in tests/lib/lost-work.sh.
# nop is a second repository no
# project governs. No run here passes --open past argument checking; open is
# a stub besides, so a page that still opens opens nothing.
_lw_build; _lw_pg_build
_lw_sum() { LC_ALL=C awk -F'\t' -v g="$2" -v k="$3" -v r="${4:-}" '$2 == "summary" && $1 == g && (r == "" || $3 == r) { print $k; exit }' "$1" 2>/dev/null; }
_lw_line() { LC_ALL=C awk -v p="    $2: " 'index($0, p) == 1 { print; exit }' "$1" 2>/dev/null; }

# ---- B9.29: --no-host ------------------------------------------------------------
_lw_run NH "$LW_HP" "$LW/cwd" monitor --tsv --repo "$PG" --no-host
_lw_run NHX "$LW_HP" "$LW/cwd" monitor --repo "$PG" --no-host
N="$(_lw_o NH)"; NX="$(_lw_o NHX)"
is "B9.29: under --no-host the page exits 0 and the TSV holds its 17 summaries" "$(_lw_rc NH)$(_lw_rc NHX) $(_lw_n16 "$N")" "00 17"
is "B9.29: the blocked, question and running summaries are incomplete, with content unknown" \
   "$(_lw_sum "$N" blocked 5):$(_lw_sum "$N" blocked 8) $(_lw_sum "$N" question 5):$(_lw_sum "$N" question 8) $(_lw_sum "$N" running 5):$(_lw_sum "$N" running 8)" \
   "incomplete:unknown incomplete:unknown incomplete:unknown"
has "B9.29: and blocked's reason names sessions unknown: --no-host" "$(_lw_sum "$N" blocked 9)" "sessions unknown: --no-host"
_lwo="$(_lw_line "$NX" 'blocked sessions')"
case "$_lwo" in
  "    blocked sessions: unknown ("*"sessions unknown: --no-host"*")") ok "B9.29: the text says blocked sessions: unknown, with the reason" ;;
  *) bad "B9.29: the text says blocked sessions: unknown, with the reason" "[$_lwo]" ;;
esac
is "B9.29: the text has one blocked sessions heading, and never blocked sessions: 0" \
   "$(LC_ALL=C grep -c '^    blocked sessions: ' "$NX") $(LC_ALL=C grep -c '^    blocked sessions: 0' "$NX")" "1 0"
is "B9.29: the collapsed line says running unknown" \
   "$(LC_ALL=C awk '/^  collapsed: / { s = $0; sub(/^  collapsed: running /, "", s); sub(/,.*/, "", s); print s }' "$NX")" unknown

# ---- B9.30: --no-gh, B9.31: gh failing ---------------------------------------------
_lw_run NG "$LW_HP" "$LW/cwd" monitor --tsv --repo "$PG" --no-gh
_lw_run NGX "$LW_HP" "$LW/cwd" monitor --repo "$PG" --no-gh
_lw_ghfail fixture_pg 'HTTP 502: Bad Gateway (https://api.github.com/graphql)'
rm -rf "$LWL"; mkdir -p "$LWL"
_lw_run GF "$LW_HP" "$LW/cwd" monitor --tsv --repo "$PG"
_lw_run GFX "$LW_HP" "$LW/cwd" monitor --repo "$PG"
_lwgf="$(LC_ALL=C awk 'index($0, "pr list") == 1 { n++ } END { print n + 0 }' "$LWL/gh.log" 2>/dev/null)"
rm -f "$LWK/prs.fixture_pg.rc" "$LWK/prs.fixture_pg.err"
for _lwk in NG GF; do
  _lwt="$(_lw_o "$_lwk")"; _lwx="$(_lw_o "${_lwk}X")"
  case "$_lwk" in NG) _lwc="B9.30: under --no-gh" ;; *) _lwc="B9.31: with gh failing" ;; esac
  is "$_lwc every pr- summary is incomplete, with content unknown" \
     "$(for _lwgg in pr-founder pr-session pr-lander pr-unknown pr-nobody; do printf '%s:%s ' "$(_lw_sum "$_lwt" "$_lwgg" 5)" "$(_lw_sum "$_lwt" "$_lwgg" 8)"; done)" \
     "incomplete:unknown incomplete:unknown incomplete:unknown incomplete:unknown incomplete:unknown "
  _lwo="$(_lw_line "$_lwx" 'pull requests waiting on the founder')"
  case "$_lwo" in
    "    pull requests waiting on the founder: unknown ("*")") ok "$_lwc the text says pull requests waiting on the founder: unknown" ;;
    *) bad "$_lwc the text says pull requests waiting on the founder: unknown" "[$_lwo]" ;;
  esac
  is "$_lwc the uncommitted worktree is still in never-proposed" \
     "$(_lw_col "$_lwt" worktree "$LWW/dirty-q9" 0 1) $(_lw_holds "$_lwt" worktree "$LWW/dirty-q9" uncommitted 1)" "never-proposed yes"
  _lwn="$(LC_ALL=C awk -F'\t' '$1 == "never-proposed" && $2 != "summary" { n++ } END { print n + 0 }' "$_lwt")"
  is "$_lwc never-proposed is incomplete and its content is its row count" \
     "$(_lw_sum "$_lwt" never-proposed 5):$(_lw_sum "$_lwt" never-proposed 8)" "incomplete:$_lwn"
  is "$_lwc never-proposed's reasons name the prs cover row" \
     "$(_lw_sum "$_lwt" never-proposed 9 | LC_ALL=C awk '{ n = split($0, e, "; "); for (i = 1; i <= n; i++) if (index(e[i], "prs ") == 1) f = 1 } END { print (f ? "named" : "unnamed") }')" named
  _lwo="$(_lw_line "$_lwx" 'work that never reached a PR')"
  case "$_lwo" in
    "    work that never reached a PR: at least $_lwn ("*"prs "*")") ok "$_lwc the text says work that never reached a PR: at least its row count, naming prs" ;;
    *) bad "$_lwc the text says work that never reached a PR: at least its row count, naming prs" "[$_lwo], wanted at least $_lwn" ;;
  esac
done
is "B9.31: gh failing still exits 0, as --tsv and as text, with the TSV's 17 summaries" "$(_lw_rc GF)$(_lw_rc GFX) $(_lw_n16 "$(_lw_o GF)")" "00 17"
is "B9.31: the page's sources asked the stub for the pull requests, and it failed them" "$([ "$_lwgf" -gt 0 ] 2>/dev/null && echo asked)" asked
is "B9.30: --no-gh exits 0, with the TSV's 17 summaries" "$(_lw_rc NG)$(_lw_rc NGX) $(_lw_n16 "$(_lw_o NG)")" "00 17"

# ---- B9.35, B1: the log page and usage ---------------------------------------------
LW_FH="$LW/loghome"; mkdir -p "$LW_FH/projects/pg"; cp "$PG/projects/pg/project.json" "$PG/projects/pg/CLAUDE.md" "$LW_FH/projects/pg/"
rm -rf "$LWL"; mkdir -p "$LWL"
_lw_run LOG "$LW_HP" "$PG" monitor --log
is "B9.35: felix monitor --log exits 0 and writes state/monitor.html under the home" \
   "$(_lw_rc LOG) $([ -s "$LW_FH/state/monitor.html" ] && echo written || echo absent)" "0 written"
rm -f "$LW_FH/state/monitor.html"
_lw_run EVERY "$LW_HP" "$PG" monitor --every 5
is "B9.35: felix monitor --every 5 implies --log: it renders once, writes the page and exits 0" \
   "$(_lw_rc EVERY) $([ -s "$LW_FH/state/monitor.html" ] && echo written || echo absent)" "0 written"
_lw_usage() {  # NAME LABEL ARGS...: exit 2, nothing on stdout, a reason and the usage naming --log on stderr
  local n="$1" l="$2"; shift 2
  _lw_run "$n" "$LW_HP" "$PG" monitor "$@"
  is "$l: exit 2 and nothing on stdout" "$(_lw_rc "$n")|$(cat "$(_lw_o "$n")")" "2|"
  has "$l: the usage on stderr names --log" "$(cat "$LWX/$n.err")" "--log"
}
_lw_usage U1 "B9.35: felix monitor --log --tsv" --log --tsv
_lw_usage U2 "B9.35: felix monitor --open --repo x" --open --repo x
_lw_usage U3 "B9.35: felix monitor --bogus" --bogus
_lw_usage U4 "B1: a page option with --every" --every 5 --no-gh
_lw_usage U5 "B1: a value the inventory would refuse, --days abc" --days abc
_lw_usage U6 "B1: --live of seven digits" --live 1234567
_lw_usage U7 "B1: an option missing its value, --repo" --repo
is "B9.35: no usage run opened anything" "$([ -e "$LWL/open.log" ] && echo opened || echo none)" none
_lw_run HELP "$LW_HP" "$PG" monitor --help
_lw_run HELP2 "$LW_HP" "$PG" monitor -h
is "B1: --help and -h print the usage to stdout, naming --log, and exit 0" \
   "$(_lw_rc HELP)$(_lw_rc HELP2) $(LC_ALL=C awk 'index($0, "--log") { f = 1 } END { print (f ? "named" : "unnamed") }' "$(_lw_o HELP)") $(LC_ALL=C awk 'index($0, "--log") { f = 1 } END { print (f ? "named" : "unnamed") }' "$(_lw_o HELP2)")" \
   "00 named named"
_lw_run FHELP "$LW_HP" "$PG" help
is "B1: the line for monitor in felix help names --log" \
   "$(LC_ALL=C awk '/felix monitor/ { print (index($0, "--log") ? "named" : "unnamed"); exit }' "$(_lw_o FHELP)")" named
LW_FH="$PG"

# ---- B9.36, B8: exit 1 ------------------------------------------------------------------
_lw_run E1 "$LW_HP" "$LW/cwd" monitor --repo "$LW/norepo" --repo "$PG"
is "B9.36: a --repo naming no repository, then the fixture: exit 1" "$(_lw_rc E1)" 1
is "B9.36: a stderr line names the first" "$([ "$(LC_ALL=C grep -c -F "$LW/norepo" "$LWX/E1.err")" -ge 1 ] && echo named || echo unnamed)" named
is "B9.36: and the fixture's block is printed" \
   "$(LC_ALL=C awk -v r="$PGR" '$0 == r { p = 1 } p && $0 == "  needs you" { y = 1 } p && /^  collapsed: / { c = 1 } END { print p + 0 "" y + 0 "" c + 0 }' "$(_lw_o E1)")" 111
_lw_run E0 "$LW_HP" "$LW/cwd" monitor --repo "$LW/norepo"
is "B6, B8: with no repository read at all, exit 1 and the first line only" "$(_lw_rc E0)|$(cat "$(_lw_o E0)")" "1|$LW_HEAD"

# ---- B9.37, B9.38: two repositories, and one no project governs -------------------------
_lw_repo nop; NOP="$LW/nop"; NOPR="$(_lw_mainwt "$NOP")"; _lw_prs fixture_nop
_lw_run TW "$LW_HP" "$LW/cwd" monitor --tsv --repo "$PG" --repo "$NOP"
_lw_run TWX "$LW_HP" "$LW/cwd" monitor --repo "$PG" --repo "$NOP"
_lw_run NV "$LW_HP" "$LW/cwd" inventory --tsv --repo "$NOP"
_lw_run NL "$LW_HP" "$LW/cwd" land --prs --tsv --repo "$NOP"
_lw_run IV2 "$LW_HP" "$LW/cwd" inventory --tsv --repo "$PG"
_lw_run LD2 "$LW_HP" "$LW/cwd" land --prs --tsv --repo "$PG"
_lw_run NP "$LW_HP" "$LW/cwd" monitor --tsv --repo "$NOP"
W2="$(_lw_o TW)"
is "B9.37: two --repo options exit 0, and the TSV holds 17 summaries for each" "$(_lw_rc TW)$(_lw_rc TWX) $(_lw_n16 "$W2")" "00 34"
is "B9.37: the text has two blocks, the first repository's first, under one first line" \
   "$(LC_ALL=C awk -v a="$PGR" -v b="$NOPR" -v h="$LW_HEAD" '$0 == h { hh++ } $0 == a { pa = NR } $0 == b { pb = NR } $0 == "  needs you" { y++ } END { print hh + 0 "|" ((pa > 0 && pb > pa) ? "ordered" : "unordered") "|" y + 0 }' "$(_lw_o TWX)")" \
   "1|ordered|2"
is "B9.37: the TSV holds 17 summaries for each, the first repository's first" \
   "$(LC_ALL=C awk -F'\t' -v a="$PGR" -v b="$NOPR" '$2 == "summary" { s = s ($3 == a ? "a" : ($3 == b ? "b" : "?")) } END { print s }' "$W2")" \
   "aaaaaaaaaaaaaaaaabbbbbbbbbbbbbbbbb"
is "B9.37: every row of the first repository comes before every row of the second" \
   "$(LC_ALL=C awk -F'\t' -v b="$NOPR" -v l="$(LC_ALL=C awk -F'\t' '$1 == "source" { print $2; exit }' "$(_lw_o NL)")" '{ x = ($3 == b || $3 == l) ? 2 : 1; if (x < m) bad++; if (x > m) m = x } END { print (m == 2) ? bad + 0 : "no second block" }' "$W2")" 0
_lwa="$(LC_ALL=C awk -F'\t' '$2 != "summary"' "$W2" | LC_ALL=C cut -f2- | _lw_norm)"
_lwb="$(cat "$(_lw_o IV2)" "$(_lw_o LD2)" "$(_lw_o NV)" "$(_lw_o NL)" | _lw_norm)"
is "B9.37: each source row is its source's own, repo cell and all: the rows equal the four source runs' as a multiset" \
   "$([ -n "$_lwb" ] && echo sources)|$_lwa" "sources|$_lwb"
is "B9.38: a repository no project governs: the page exits 0 and prints its 17 summaries" "$(_lw_rc NP) $(_lw_n16 "$(_lw_o NP)")" "0 17"
is "B9.38: and land's land, ledger and lander rows are unread" \
   "$(for _lwr in land ledger lander; do printf '%s ' "$(_lw_st "$(_lw_o NP)" source "$_lwr" 1)"; done)" "unread unread unread "
is "B9.38: with step 5's detail, as land alone prints it" \
   "$(for _lwr in land ledger lander; do printf '%s|' "$(_lw_col "$(_lw_o NP)" source "$_lwr" 8 1)"; done)" \
   "$(for _lwr in land ledger lander; do printf '%s|' "$(_lw_col "$(_lw_o NL)" source "$_lwr" 8)"; done)"
is "B9.38: and land alone says the same three are unread (control)" \
   "$(for _lwr in land ledger lander; do printf '%s ' "$(_lw_st "$(_lw_o NL)" source "$_lwr")"; done)" "unread unread unread "
# <<< lost-work-page-readings
