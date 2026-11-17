# tests/lib/router.sh: the widget's lessons and the intent router's tables.
# Used by 0200 (builds the lessons), 0230 (builds the router tables and reads the
# lessons), 0240, 0250 and 0590 (the router tables; 0240 and 0230 share _route;
# 0250 reads the mandates the sections before it rendered). Moved from
# parts/0200-generated-constitution.sh: the lessons.md heredoc (lines 64-76); from
# parts/0230-the-intent-router.sh: _route (line 13) and the tables (lines 4-11),
# and the three rows 0230 appends to routes.tsv (lines 51-53, 58 and 66-68) as
# the state `routed`. _says_mandates_build is new: it stands for the hook runs of
# 0230 and 0240 that 0250's decisions report counts.
# Definitions only. Each builder is guarded: a call in the serial run, where the
# fixture is already there, changes nothing (_router_build tables, which 0230 calls
# first, rewrites the same four files).

# _route PROMPT [DIR]: what felix route says for a prompt, in the widget repository (0230:13).
_route() { ( cd "${2:-$REPO}" && "$FELIX" route --for "$1" 2>&1 ); }

# _lessons_build [force]: the widget's lessons.md, with L-1 and L-2. Written when
# the file does not hold L-1 yet, or always with "force" (0200 writes it so).
_lessons_build() {
  [ "${1:-}" = force ] || ! grep -q 'L-1 Migrations need a rollback path' "$MEM/widget/lessons.md" 2>/dev/null || return 0
cat > "$MEM/widget/lessons.md" <<'LES'
# widget lessons

## Checklist
1. run the gate
2. update the devlog

## Seeded principles
- **L-1 Migrations need a rollback path.** Long evidence about a migration that
  went wrong, with detail nobody needs mounted on every single turn.
- **L-2 Browser tests belong on critical flows.** More evidence, equally long,
  equally irrelevant until someone is actually touching the browser layer.
LES
}

# _router_build <state>: the widget's routing tables.
#   tables  the shipped routes and profiles, a stack of three tools and two
#           capabilities (0230:4-11 of the base tree). Written whenever it is called.
#   routed  `tables` and the three rows 0230 appends to routes.tsv by the end of
#           its first block (0230:51-68 of the base tree): a play entry nobody declared, a row
#           with no tabs, and a row keyed on the payload's own field names. A
#           call finds that last row there and changes nothing.
_router_build() {
  local rt="$FROOT/projects/widget/routes.tsv"
  case "${1:-tables}" in
  tables)
cp "$REAL_HARNESS/templates/routes.tsv"   "$FROOT/projects/widget/routes.tsv"
cp "$REAL_HARNESS/templates/profiles.tsv" "$FROOT/projects/widget/profiles.tsv"
cat > "$FROOT/projects/widget/stack.tsv" <<'EOF'
plugin	frontend-design@claude-plugins-official	-	low	frontend
plugin	playwright@claude-plugins-official	-	low	e2e
skill	impeccable	-	low	frontend
EOF
printf 'frontend\ne2e\n' > "$FROOT/projects/widget/capabilities"
    ;;
  routed)
    grep -q "^envelope$(printf '\t')prompt session transcript permission$(printf '\t')frontend$(printf '\t')-\$" "$rt" 2>/dev/null && return 0
    _router_build tables
    cat >> "$rt" <<'ROUTEROWS'
ghost	nonesuch	frontend	not-declared-anywhere
ROUTEROWS
    printf 'broken-row-with-no-tabs\n' >> "$rt"
    cat >> "$rt" <<'ROUTEROWS'
envelope	prompt session transcript permission	frontend	-
ROUTEROWS
    ;;
  esac
}

# _says_mandates_build: the widget's says.log holds the mandates the prompt hook
# rendered in the sections before 0250 (0230's first block and 0240 ran the hook
# for sessions routed to frontend and backend: six of them said "Use this now"
# before 0250 began). 0250's decisions report needs those to count more mandates
# than its declines and skips. Run when fewer than six are there: each missing
# one is a session of its own given the prompt 0230 first used, through the hook.
_says_mandates_build() {
  local n i
  n="$(grep -c 'Use this now' "$MEM/widget/says.log" 2>/dev/null)"
  [ "${n:-0}" -ge 6 ] && return 0
  _user_prompt_hook_vars
  i="${n:-0}"
  while [ "$i" -lt 6 ]; do
    i=$((i + 1))
    ( cd "$REPO" && printf '{"session_id":"mandate-%s","prompt":"let us build the results page"}' "$i" | "$RHK" ) >/dev/null 2>&1
  done
}
