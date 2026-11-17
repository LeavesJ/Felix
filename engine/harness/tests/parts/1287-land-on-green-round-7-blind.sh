# >>> land-on-green-round-7
printf '\nland on green: the amendment A30 (contract A30, blind)\n'
# Blind, from the contract's "Amended before install, 2026-10-16" alone, on the
# fixture parts 1280-1286 build: lib/green-tick.sh, lib/green-install.sh,
# lib/resolve.sh and the felix CLI were not read. The tick is run as every land
# part runs it.
#
# Every held pull request here is green on its head, a worktree holds that head
# on its branch, it is MERGEABLE, not a draft, not cross-repository, touches no
# direction document, and felix merge would take it: the fixture controls first
# land 40 and 42 exactly so, unlabelled. A label is then the only reason left
# not to merge, so a tick that hands the pull request to felix merge ignored it.
# The contract leaves the skip row's words open, so its detail is held only to
# naming the label as the pull request carries it, case and all.
_lg_build amend
_l8_lab() {   # NAME... -> a labels array as gh lists it, one object per name
  local n s="" o="" i=0
  for n in "$@"; do
    i=$((i+1)); o="$o$s{\"id\":\"L8$i\",\"name\":\"$n\",\"description\":\"\",\"color\":\"ededed\"}"; s=","
  done
  printf '[%s]' "$o"
}
_l8_tick() {   # N LABELS -> a fresh ledger, pull request N alone and green carrying LABELS, one tick
  _lg_reset; _lg_prs "$(_lg_pr "$1" false "$2")"; _lg_green "$1"; _lg_land --tick
}

# --------------------------------------------------------- fixture controls ---
for _l8n in 40 42; do
  _l8_tick "$_l8n" "$(_l8_lab)"
  is "the land fixture: green, unlabelled and held by its worktree, $_l8n lands on one tick, felix merge run once there (fixture control)" \
     "$LGRC|$(_lg_n landed "$_l8n")|$(_lg_merges)|$(_lg_n skip)" "0|1|b$_l8n|0"
done
_lg_reset; _lg_prs "$(_lg_pr 42 false "$(_l8_lab bug Needs-Founder)")"
if command -v jq >/dev/null 2>&1; then
  is "the land fixture: the gh stub lists a pull request's labels by name, case as carried (fixture control)" \
     "$(PATH="$LGB:$PATH" gh pr list --state open --json labels --jq '.[].labels[].name' | tr '\n' ' ')" "bug Needs-Founder "
else skip "the land fixture: the gh stub lists a pull request's labels by name, case as carried (fixture control)" "no jq"; fi

# ---------------------------------------------------- A30: the held labels ---
_l8_held() {   # LABEL WHAT -> 42 carrying LABEL alone is held on one tick
  _l8_tick 42 "$(_l8_lab "$1")"
  is "A30: $2: the tick exits 0, hands 42 to felix merge nowhere and lands nothing" \
     "$LGRC|$(_lg_merges)|$(_lg_n landed 42)" "0||0"
  is "A30: $2: and writes exactly one skip row for 42" "$(_lg_n skip 42)" "1"
  has "A30: $2: and that skip row's detail names the label as 42 carries it" "$(_lg_f skip 42 7)" "$1"
}
_l8_held needs-founder "a green pull request labelled needs-founder"
_l8_held felix:founder "a green pull request labelled felix:founder"
_l8_held felix:hold "a green pull request labelled felix:hold"
_l8_held Needs-Founder "case: Needs-Founder holds as needs-founder does"
_l8_held FELIX:FOUNDER "case: FELIX:FOUNDER holds as felix:founder does"
_l8_held Felix:Hold "case: Felix:Hold holds as felix:hold does"

# A held name among others, neither first nor last, still holds.
_l8_tick 42 "$(_l8_lab bug needs-founder documentation)"
is "A30: a green pull request labelled bug, needs-founder and documentation is handed to felix merge nowhere and lands nothing" \
   "$(_lg_merges)|$(_lg_n landed 42)" "|0"
is "A30: and gets exactly one skip row" "$(_lg_n skip 42)" "1"
has "A30: whose detail names needs-founder" "$(_lg_f skip 42 7)" "needs-founder"

# ---------------------------------------------------- A30: the near misses ---
for _l8l in not-needs-founder needs-founder-later felix:holder; do
  _l8_tick 42 "$(_l8_lab "$_l8l")"
  is "A30: a label that only contains a held name, $_l8l, holds nothing: green 42 lands on that tick, felix merge run once there, no skip row" \
     "$(_lg_n landed 42)|$(_lg_merges)|$(_lg_n skip 42)" "1|b42|0"
done
_l8_tick 42 "$(_l8_lab)"
is "A30: (control) a green pull request with no label lands on that tick, felix merge run once there" \
   "$(_lg_n landed 42)|$(_lg_merges)" "1|b42"

# ------------------------------------------------- A30, A6: a waiting hold ---
_l8_tick 42 "$(_l8_lab needs-founder)"; _lg_land --tick
is "A30, A6: two ticks over the same held 42 write one skip row for it, not two" "$(_lg_n skip 42)" "1"
is "A30, A6: and neither tick hands it to felix merge" "$(_lg_merges)|$(_lg_n landed 42)" "|0"

# ------------------------------------------ A30, G4: the tick moves on past it ---
# Listed descending, as gh lists them; the tick takes them ascending, so the
# held 40 comes first and 42 is the next candidate.
_lg_reset; _lg_prs "$(_lg_pr 42)" "$(_lg_pr 40 false "$(_l8_lab felix:founder)")"; _lg_green 40 42; _lg_land --tick
is "A30, G4: a held 40 does not stop the tick: green unlabelled 42 after it lands on the same tick, the only felix merge run" \
   "$(_lg_n landed 42)|$(_lg_merges)" "1|b42"
is "A30, G4: and 40 gets one skip row and no landing" "$(_lg_n skip 40)|$(_lg_n landed 40)" "1|0"

_lg_reset
