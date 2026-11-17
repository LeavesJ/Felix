# >>> land-tick-retries-a-refusal
printf '\nthe land tick retries a refusal its blocker can lift, and says when (audit b02, B1-B9, A1-A24, blind)\n'
# Blind, written on 2026-10-24 from docs/2026-10-24-audit-fixes/b02-land-tick-never-refuses-or-waits-silentl.md
# alone (section 4, "Fixture for 1650" and "Part 1650 assertions"), on the fixture of tests/lib/land-on-green.sh
# that parts 1280-1289 use. lib/green-tick.sh, lib/green-install.sh, the felix CLI and every other engine file
# were not read: the tick is run as every land part runs it, and judged by its ledger, felix.log and osascript.
#
# One pull request, 50, green on its head, held by worktree b50 on its branch. Each case starts from an empty
# land/ and empty logs, with neither receipt there, and answers felix merge with one of the contract's outputs
# (OUT-R, OUT-C, OUT-F, OUT-E, OUT-T, OUT-0, OUT-G, OUT-M), its blocker lines laid out as cmd_merge's
# '  %-11s %-22s %s'. M50 is how many felix.log rows ran `merge` in b50's directory. L50RC50, the contract's
# RC50, is b50's gate receipt, at the path the contract derives from b50's physical path; L50CC, its CC, is the
# commission receipt of project lgh (named apart from CC, which a caller may export for its C compiler). To
# rewrite one is to write a line holding a fresh counter, so its bytes always change. Rows are aged only as part
# 1280's _lg_age ages them, the year moved back by one; 1280 defines that function, so --part alone needs this
# part's own copy. A seeded row's head and worktree columns take the form the tick itself wrote for 50 earlier in
# this part, its time the contract's UTC YYYY-MM-DDTHH:MM:SSZ. Where the contract leaves the words open (the
# blocker's spacing, an exit-0 retry's output), nothing is asserted of them.
_lg_build amend
L50="$LG/round50"; mkdir -p "$L50"; : > "$L50/all.tsv"
L50HOLD='[{"id":"L1","name":"felix:hold","description":"","color":"ededed"}]'
_fx_git "$LGH" fetch -q origin >/dev/null 2>&1; _fx_git "$LGH" checkout -q main >/dev/null 2>&1
_fx_git "$LGH" reset -q --hard refs/remotes/origin/main >/dev/null 2>&1
L50V="$(_l3_mainv)"; [ -n "$L50V" ] && _lg_cache "$L50V"
rm -rf "${LGH:?}/state"
if [ -d "$LGW/b50" ]; then L50H="$(git -C "$LGW/b50" rev-parse HEAD 2>/dev/null)"; else L50H="$(_lg_branch b50 notes/b50.md)"; fi
[ -n "$(_lg_sha 50)" ] || printf '50\t%s\n' "$L50H" >> "$LG/shas"
L50W="$(cd "$LGW/b50" 2>/dev/null && pwd -P)"
L50RC50="$LGH/state/gate/$(printf '%s' "$L50W" | git hash-object --stdin 2>/dev/null)"
L50CC="$LGH/state/commission/lgh"
L50HF=""; L50WF=""; L50N=0

_l50_bl() { printf '  %-11s %-22s %s\n' "$1" "$2" "$3"; }
_l50_out() {   # NAME -> felix merge's output NAME, as section 4 gives it (L: a landing's)
  case "$1" in
    L) printf 'merged\n' ;;
    R) printf 'not merging\n\n'; _l50_bl not-green tree 'the tree changed since the receipt'
       printf '\nNothing here escapes the tree.\n' ;;
    C) printf 'not merging\n\n'; _l50_bl commission receipt 'the table set moved'
       printf '\nAsk them to run, in order:\n\n  felix autonomy --allow commission\n  felix commission\n' ;;
    F) printf 'not merging\n\n'; _l50_bl not-green tree 'the tree changed since the receipt'
       _l50_bl evidence notes/b50.md 'the change owes a test'; printf '\nNothing here escapes the tree.\n' ;;
    E) printf 'not merging\n\n'; _l50_bl escape write 'notes/b50.md: outside the tree' ;;
    T) printf 'not merging\n\n'; _l50_bl commission table 'projects/lgh/commissioning.tsv: unreadable' ;;
    0) printf 'not merging\n\n' ;;
    G) printf 'GraphQL: Something went wrong\nfelix: gh pr merge failed, for the reason gh gave above. Nothing was merged.\n' ;;
    M) printf 'not merging\n\n  tree       edited under it, uncommitted or untracked\n\nThe working tree was edited while this ran.\n' ;;
    P) printf 'not merging\n\n'; _l50_bl base provider 'the provider could not be asked which commit it would squash onto (gh api for the base branch main failed), so the base judged here is not known to be its base, and nothing was merged' ;;
    D) printf 'not merging\n\n'; _l50_bl base 0123456789abcdef0123456789abcdef01234567 'the base judged is not the base the provider would squash onto: main is another commit on GitHub. Fetch, and run this again' ;;
  esac
}
_l50_keep() { [ -f "$LAND/ledger.tsv" ] && cat "$LAND/ledger.tsv" >> "$L50/all.tsv"; return 0; }
_l50_case() {   # OUT STATUS -> a fresh land/, logs and controls, no receipt, 50 alone and green, felix merge answering OUT with STATUS
  _l50_keep
  _lg_reset; rm -f "$L50RC50" "$L50CC"; _lg_prs "$(_lg_pr 50)"; _lg_green 50
  _l50_out "$1" > "$LGK/merge.b50.out"; printf '%s\n' "$2" > "$LGK/merge.b50.rc"
}
_l50_m() { _lg_logs felix | LC_ALL=C awk -F'\t' -v d="$L50W" '$2 == d && $3 == "merge" { n++ } END { print n + 0 }'; }
_l50_rw() { L50N=$((L50N + 1)); mkdir -p "$(dirname "$1")"; printf 'receipt %s\n' "$L50N" > "$1"; }
_l50_age() {   # every ledger row's year moved back by one, as part 1280's _lg_age does
  [ -f "$LAND/ledger.tsv" ] || return 0
  LC_ALL=C awk -F'\t' -v OFS='\t' -v y="$(date -u +%Y)" '{ if (index($1, y)) sub(y, y - 1, $1); print }' \
    "$LAND/ledger.tsv" > "$LAND/ledger.aged" && /bin/mv "$LAND/ledger.aged" "$LAND/ledger.tsv"
}
_l50_has() { case "$1" in *"$2"*) printf yes ;; *) printf no ;; esac; }
_l50_osa() { _lg_logs osa | LC_ALL=C awk -v t="with title \"$1\"" 'index($0, t) { n++ } END { print n + 0 }'; }
_l50_main() { git -C "$LGH" rev-parse refs/remotes/origin/main 2>/dev/null; }
_l50_head() {   # -> 50's head, cut to the length of the head the tick wrote for 50 (whole when it wrote none)
  if [ -n "$L50HF" ]; then _lg_sha 50 | cut -c1-"${#L50HF}"; else _lg_sha 50; fi
}
_l50_seed() {   # DETAIL -> land/ holds a ledger of one refused row for 50 at its head, timed now, and nothing else
  mkdir -p "$LAND"
  printf '%s\trefused\t50\t%s\t%s\t0\t%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$(_l50_head)" "${L50WF:-$L50W}" "$1" > "$LAND/ledger.tsv"
}
L50CR='(tried again when a new gate or commission receipt is written)'
L50CF='(final until the head or main moves)'
L50CH='(tried again an hour after this row)'

# ------------------------------------------------------- the fixture, checked ---
is "the land fixture: the home is on main at origin's main, main's check accepts its entry, b50 is on its branch at 50's head, and RC50 is a path under the home's state/gate (fixture control)" \
   "$(git -C "$LGH" rev-parse HEAD 2>&1)|$(_la_accepts)|$(git -C "$LGW/b50" symbolic-ref HEAD 2>&1)|$(git -C "$LGW/b50" rev-parse HEAD 2>&1)|$(_l50_has "$L50RC50" "$LGH/state/gate/")" \
   "$(git -C "$LGO" rev-parse main 2>&1)|0|refs/heads/b50|$(_lg_sha 50)|yes"
_l50_case L 0; _lg_land --tick
is "the land fixture: green 50 lands on one tick when felix merge exits 0, felix merge run once in b50, which M50 counts (fixture control)" \
   "$LGRC|$(_lg_n landed 50)|$(_l50_m)" "0|1|1"

# ------------------------------------------- B1, B2, B4: a receipt refusal ---
_l50_case R 3; _lg_land --tick
L50D="$(_lg_f refused 50 7)"; L50HF="$(_lg_f refused 50 4)"; L50WF="$(_lg_f refused 50 5)"
is "A1 (B1, B2): a not-green refusal (exit 3, one blocker line of kind not-green) writes one refused row for 50 whose detail says it is tried again when a new gate or commission receipt is written" \
   "$(_lg_n refused 50)|$(_l50_has "$L50D" "$L50CR")" "1|yes"
# "Begins not-green" is read past leading blanks: B2 keeps the blocker as today, and today's keeps the two
# spaces its blocker line begins with (seen on main 69b51a61 when this part was first run, A2 being a control).
L50DT="${L50D#"${L50D%%[! ]*}"}"
case "$L50DT" in "not-green"*" [main $(_l50_main)]") ok "A2 (B2): that detail still begins with the blocker, not-green (leading blanks aside), and still ends with a space and [main <sha of refs/remotes/origin/main>]" ;;
  *) bad "A2 (B2): that detail still begins with the blocker, not-green (leading blanks aside), and still ends with a space and [main <sha of refs/remotes/origin/main>]" "[$L50D], main [$(_l50_main)]" ;; esac
_lg_land --tick
is "A5 (B4): with neither receipt touched, a second tick neither runs felix merge again nor writes a row: M50 is 1, one refused row" \
   "$(_l50_m)|$(_lg_n refused 50)" "1|1"
_l50_rw "$L50RC50"; _lg_land --tick
is "A6 (B4): once b50's gate receipt is written where none was, the next tick runs felix merge once more: M50 is 2" "$(_l50_m)" "2"
_lg_land --tick
is "A7 (B4): the tick after, with nothing touched, runs it no more: M50 stays 2" "$(_l50_m)" "2"
rm -f "$L50RC50"; _lg_land --tick
is "A8 (B4): a gate receipt present then and absent now has changed: the next tick runs felix merge once more, M50 is 3" "$(_l50_m)" "3"

_l50_case C 3; _lg_land --tick; L50A="$(_l50_m)"; _l50_rw "$L50CC"; _lg_land --tick
is "A9 (B1, B4): a refusal whose one blocker is commission receipt is lifted by the commission receipt: once it is written the next tick runs felix merge once more, the two-space felix lines after the block being no blocker" \
   "$L50A|$(_l50_m)" "1|2"

_l50_case R 3; _lg_land --tick; printf '0\n' > "$LGK/merge.b50.rc"; _l50_rw "$L50RC50"; _lg_land --tick
is "A10 (B4, B7): a retry, after the gate receipt is written, that exits 0 writes one landed row for 50 and one notification titled Felix: landed #50" \
   "$(_lg_n landed 50)|$(_l50_osa 'Felix: landed #50')" "1|1"

_l50_case R 3; _lg_land --tick; _l50_rw "$L50RC50"; _lg_land --tick
is "A11 (B7): a retry refused the same way writes a second refused row for 50 and no second notification, its blocker, class and head being the previous row's" \
   "$(_l50_m)|$(_lg_n refused 50)|$(_l50_osa 'Felix: refused #50')" "2|2|1"

# ---------------------------------------------------------- B3: final ---
_l50_final() {   # OUT ITEM WHAT -> refused, then both receipts rewritten and the rows aged: no tick runs felix merge again
  _l50_case "$1" 3; _lg_land --tick; L50D="$(_lg_f refused 50 7)"
  _l50_rw "$L50RC50"; _l50_rw "$L50CC"; _l50_age; _lg_land --tick
  is "$2 (B1, B3): a refusal with $3 is final: with both receipts rewritten and its row a year old, the next tick does not run felix merge, M50 stays 1" \
     "$(_l50_m)" "1"
}
_l50_final F A12 "an evidence blocker beside the not-green one"
L50DF="$L50D"
_l50_final E A13 "an escape blocker"
_l50_final T A14 "a commission blocker whose subject is table, not receipt"
_l50_final 0 A15 "an empty blocker block (not merging, and nothing under it)"
is "A3 (B1, B2): a refusal holding a blocker of another kind (evidence) beside not-green says (final until the head or main moves)" \
   "$(_l50_has "$L50DF" "$L50CF")" "yes"

# --------------------------------------------------------- B5: hourly ---
_l50_case G 1; _lg_land --tick; L50DG="$(_lg_f refused 50 7)"; _lg_land --tick
is "A16 (B5): a refusal that exits 1 (gh pr merge failed) is not tried again within the hour: two ticks, M50 is 1" "$(_l50_m)" "1"
_l50_age; _lg_land --tick; L50A="$(_l50_m)"; _lg_land --tick
is "A17 (B5, B7): once its row is an hour old or older, the next tick runs felix merge once more, and the tick after, inside the new row's hour, does not" \
   "$L50A|$(_l50_m)" "2|2"
_l50_case M 4; _lg_land --tick; L50DM="$(_lg_f refused 50 7)"; _l50_age; _lg_land --tick
is "A18 (B5): a refusal that exits 4 (the tree was edited under it) is tried again once its row is an hour old: M50 is 2" "$(_l50_m)" "2"
is "A4 (B1, B2): exit 1 (OUT-G) and exit 4 (OUT-M) are hourly: each refused row's detail says (tried again an hour after this row)" \
   "$(_l50_has "$L50DG" "$L50CH")|$(_l50_has "$L50DM" "$L50CH")" "yes|yes"

# ----------------------------------- not blind: slice 2's review, 2026-11-08 ---
# OUT-P and OUT-D are felix merge's two base lines since trust step 3 slice 2 (lib/bind.sh): the provider gave no
# answer, and the provider names a base that is not the one judged. Written after that review found the first
# classed final, which parked an honest pull request until its head or main moved.
_l50_case P 3; _lg_land --tick; L50DP="$(_lg_f refused 50 7)"; _lg_land --tick; L50A="$(_l50_m)"; _l50_age; _lg_land --tick
is "A25 (slice 2 review, not blind): a refusal whose one blocker is base provider (no answer from the provider) is hourly: its row says (tried again an hour after this row), a tick inside the hour does not run felix merge again, and once the row is an hour old one does" \
   "$(_l50_has "$L50DP" "$L50CH")|$L50A|$(_l50_m)" "yes|1|2"
_l50_final D A26 "a base blocker naming a commit, the provider's base being another"

# ----------------------------------------------- B6, B9: rows it did not write ---
_l50_case R 3; _l50_seed "the receipt is stale [main $(_l50_main)]"; _l50_age; _l50_rw "$L50RC50"; _l50_rw "$L50CC"
_lg_land --tick
is "A19 (B6): a refused row written before this change, with none of the clauses, a year old, on 50's head and main, is final: with both receipts written a tick does not run felix merge (M50 is 0)" \
   "$(_l50_m)" "0"
_l50_case R 3; _l50_seed "x $L50CR [main $(_l50_main)]"
is "the land fixture: land/ holds the ledger alone, its one row refused for 50 on its head and main with the receipt clause (fixture control)" \
   "$( (cd "$LAND" && ls -A) 2>&1 | tr '\n' ' ')|$(_lg_rows)|$(_lg_n refused 50)" "ledger.tsv |1|1"
_lg_land --tick; L50A="$(_l50_m)"; _lg_land --tick
is "A20 (B9): a receipt-clause refusal whose receipts the tick holds no record of is unknown, not unchanged: a tick runs felix merge once, and the tick after, with nothing changed, does not" \
   "$L50A|$(_l50_m)" "1|1"

# ------------------------------------------------ B8, and contract A13 kept ---
_l50_case R 3; _lg_land --tick; _lg_prs "$(_lg_pr 50 false "$L50HOLD")"; _l50_rw "$L50RC50"; _lg_land --tick
is "A21 (B8): a refused pull request now labelled felix:hold gets its skip row and no retry, though its gate receipt was written: M50 stays 1" \
   "$(_lg_n skip 50)|$(_l50_m)" "1|1"
_l50_case R 3; _lg_land --tick
L50H="$(_lg_more b50 notes/b50.md)"
LC_ALL=C awk -F'\t' -v OFS='\t' -v s="$L50H" '$1 == "50" { $2 = s } { print }' "$LG/shas" > "$L50/shas" && /bin/mv "$L50/shas" "$LG/shas"
_lg_prs "$(_lg_pr 50)"; _lg_green 50; _lg_land --tick
is "A22 (B4, contract A13): a receipt refusal whose pull request's head moves is run again on the next tick: M50 is 2" "$(_l50_m)" "2"
_l50_case F 3; _lg_land --tick; rm -rf "${LGH:?}/state"; _l3_commit notes/l50-a23.md a23; _lg_land --tick
is "A23 (B3, contract A13): a final refusal is run again on the next tick once main moves: M50 is 2" "$(_l50_m)" "2"

# ------------------------------------------------------------------ G8 ---
_l50_keep
L50A="$(LC_ALL=C awk -F'\t' 'NF != 7 { b++ } END { printf "%d %d", NR, b + 0 }' "$L50/all.tsv")"
case "$L50A" in "0 "*|*" "[123456789]*) bad "A24 (G8): every row this part's ticks wrote, and every row it seeded, is one row of seven tab-separated fields" "rows, then rows of another shape: $L50A" ;;
  *) ok "A24 (G8): every row this part's ticks wrote, and every row it seeded, is one row of seven tab-separated fields" ;; esac

_lg_reset; rm -rf "${LGH:?}/state" "$L50"
is "the land fixture: the part leaves the home on main at origin's main, no tracked change, with main's check accepting its entry (fixture control)" \
   "$(git -C "$LGH" rev-parse --abbrev-ref HEAD 2>&1)|$(git -C "$LGH" rev-parse HEAD 2>&1)|$(git -C "$LGH" status --porcelain --untracked-files=no 2>&1)|$(_la_accepts)" \
   "main|$(git -C "$LGO" rev-parse main 2>&1)||0"
