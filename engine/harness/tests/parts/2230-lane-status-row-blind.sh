# >>> lane-status-row
printf '\nlane status row: felix status gains the lane row, last, in every case C6 names, with the status shape, L-DET and L-RO (slice 0, design 6.5 item 2 and 6.6, C6, L-NEVER-OK; blind)\n'
# Blind, written on 2026-10-29 from docs/2026-10-29-capability-lane-first-slices-design.md and the slice 0 plan's
# Contracts (C1-C13) alone, before lib/lane.sh existed, without reading lib/, hooks/, bin/ or felix. Felix is run as a
# black box; the builders are tests/lib/lane-fixture.sh's. C11's row for this part: section 6.5 item 2 and 6.6 "felix
# status --tsv": exactly one row more, at the end, every row before it byte-identical; every C6 case, an unreadable ref
# giving state unknown and value -; the status shape; L-DET and L-RO for status.
#
# The home apart (C9): H holds project sr, and each checkout is bound to sr by an untracked .felix. H's lanes.tsv is
# committed, replaced and removed by commits as the cases need, and every case checks that H's HEAD holds what it names.
# Each checkout's root is a month before the clock, its landings (_lf_chain) five days before it, an hour apart.
# Readings where the Contracts leave room:
# - "Byte-identical without the lane row's input" is read in one checkout and one home, before lanes.tsv is first
#   committed and after: every row but the lane row is compared, and that comparison is the control C10 names.
# - The status shape is D16's (part 1100's awk), checked over every felix status --tsv this part runs, together with
#   the ten rows ending in lane, so it is red on main.
# - Besides C6's cases: the first data row speaks when it sits under a comment and a blank line, when the row after it
#   is broken and when it is broken itself; the detail takes W and n/d from the table; with FELIX_LANE_NOW unset or
#   empty the machine clock is read (C9); plain felix status aligns the row as C6 says.
# - L-RO's marker is touched a second after the fixture's last write, and what the runs leave newer is printed in the
#   assertion. The checkout's refs and worktree list are compared before and after.
# - The review's second amendment (2026-10-30, design 11 item 45, still blind) adds C11's 1 day (F11) and a count that
#   ends early (F1), after the shape check.
# - The second review's round 2 (2026-10-30, still blind) adds, at the end, R2B-F1: a resolution by remote_match that
#   does not finish, in felix status --tsv, plain felix status and felix lane --tsv.
# - Design item 46 (2026-10-30, still blind) adds, at the end, I46-11 to I46-20: C6's last row for a resolution that did
#   not finish, under C9's probes inside felix_resolve_project, and the none row of the misses that stand (C2).
# - The third review's round 1 (2026-10-30, still blind) adds, at the end, V3R1-F1 and V3R1-F2: the status row when the
#   reads of a project.json's remote_match fail under the resolver, or under it and the lane's check alike (C2, C6).
# - The third review's round 2 (2026-10-30, still blind) adds, at the end, V3R2-F3: an origin URL that ends in LF binds
#   as the resolver binds it, with no read failed, so the row is C6's none row, never the unknown one (C2).
# - The third review's round 3 (2026-10-30, still blind) adds, at the end, V3R3-F1: the nine rows before the lane row
#   take the shared resolver's answer, under a fault in a read only the lane's check makes and for a project directory
#   whose name ends in LF, and only the lane row reads the lane's resolution (C6 as 8630c9b3 amended it).
LNTN=1793000000; LNTDAY=86400; LNTK=0
LNTNINE='settings schedule pulse reach gate land hooks alerts icloud '
LNTTEN="${LNTNINE}lane "
_lf_dir "$TMP/lane-2230"; LNTD="$LF_DIR"; mkdir -p "$LNTD/plain" "$LNTD/st"
_lf_stubs "$LNTD"; LNTB="$LF_BIN"
_lf_home "$LNTD/home" sr 1792600000; LNTH="$LF_HOME"; LNTP="$LF_PROJ"
_lf_use "$LNTH" "$LNTD/memory" "$LNTD/user" "$LNTB"
LNTLANES=$'# The lanes this fixture counts.\n\ncapability\t^engine/\t1/2\t14\n'
LNTUNG="$(_lf_tsv lane none - 'this directory is not a governed checkout')"
LNTNONE="$(_lf_tsv lane none - "$LNTP/lanes.tsv has no committed row, so no lane is counted")"
LNTVOK="$(_lf_tsv lane value ok '1 of 2 engine landings in 14 days, target 1/2')"
LNTPOK="$(printf '%-9s %-12s %s' lane ok '1 of 2 engine landings in 14 days, target 1/2')"

# NAME SPEC... -> LNTR a checkout $LNTD/NAME bound to sr, its root a month before the clock, then SPEC's landings
# (_lf_chain: m, u, md, ud) from five days before it, an hour apart, published. LNTE "built" when the first-parent chain
# of refs/remotes/origin/main holds the root and every landing.
_lnt_chk() {
  local n="$1"
  shift
  LNTE="not built: $n"; LNTR=""
  _lf_checkout "$LNTD/$n" sr $((LNTN - 30 * LNTDAY)) || return 1
  LNTR="$LF_REPO"
  _lf_chain "$LNTR" capability $((LNTN - 5 * LNTDAY)) 3600 "$@" || return 1
  [ "$(_lf_spine "$LNTR" | LC_ALL=C awk '{ print NF }')" = "$(($# + 1))" ] && LNTE=built
}
# DIR [NOW] -> felix status --tsv from DIR at the clock LNTN (or NOW: - unset, anything else as given, empty
# included), kept as $LNTD/st/<k>.out for the shape check at the end. LNTF the stem, LNTROWS the row names, a space
# after each, LNTLAST the last row, LF_RC the status.
_lnt_st() {
  LNTK=$((LNTK + 1)); LNTF="$LNTD/st/$LNTK"
  _lf_run "$LNTF" "$1" "${2-$LNTN}" "$FELIX" status --tsv
  LNTROWS="$(LC_ALL=C awk -F'\t' '{ printf "%s ", $1 }' "$LNTF.out")"
  LNTLAST="$(_lf_last "$LNTF.out")"
}
# LABEL BYTES -> H's lanes.tsv holds BYTES, committed at the next time; LNTT "built" when H's HEAD holds exactly them.
_lnt_put() {
  local f="$LNTD/put"
  LNTK=$((LNTK + 1)); LNTT="not built: lanes.tsv $1"
  rm -f "$LNTP/lanes.tsv"
  _lf_table "$LNTP" $((1792600000 + 100 * LNTK)) lanes.tsv "$2" "lanes.tsv: $1"$'\n' || return 1
  printf '%s' "$2" > "$f.want"
  ( _fx_cd "$LNTH" || exit 1; _lf_g 1700000000 cat-file blob HEAD:projects/sr/lanes.tsv ) > "$f.got" 2>/dev/null
  cmp -s "$f.want" "$f.got" && LNTT=built
}
# LABEL -> H's HEAD holds no lanes.tsv: a commit removes it when HEAD holds one. LNTT "built" when HEAD holds none.
_lnt_absent() {
  LNTK=$((LNTK + 1)); LNTT="not built: $1"
  if ( _fx_cd "$LNTH" && _lf_g 1700000000 cat-file -e HEAD:projects/sr/lanes.tsv ) >/dev/null 2>&1; then
    _lf_commit "$LNTP" $((1792600000 + 100 * LNTK)) "lanes.tsv removed: $1"$'\n' -lanes.tsv || return 1
  fi
  ( _fx_cd "$LNTH" && _lf_g 1700000000 cat-file -e HEAD:projects/sr/lanes.tsv ) >/dev/null 2>&1 || LNTT=built
}

# ---- one row more, at the end, and every row before it unchanged ----------------------------------------------------------
_lnt_chk ok m u; LNTOK="$LNTR"; LNTOKE="$LNTE"
_lnt_absent "never committed"; _lnt_st "$LNTOK"; LNTF0="$LNTF"
is "lane status row: with no lanes.tsv ever committed, felix status --tsv exits 0 with ten rows, main's nine in their order and then lane none - <PROJ>/lanes.tsv has no committed row, so no lane is counted" \
   "$LNTOKE|$LNTT|$LF_RC|$LNTROWS|$LNTLAST" "built|built|0|$LNTTEN|$LNTNONE"
_lnt_put "the capability row" "$LNTLANES"; _lnt_st "$LNTOK"; LNTF1="$LNTF"
is "lane status row: with lanes.tsv committed, felix status --tsv prints exactly one row more than main, ten, the lane row last: lane value ok 1 of 2 engine landings in 14 days, target 1/2" \
   "$LNTOKE|$LNTT|$LF_RC|$LNTROWS|$LNTLAST" "built|built|0|$LNTTEN|$LNTVOK"
LC_ALL=C awk -F'\t' '$1 != "lane"' "$LNTF0.out" > "$LNTD/before.0"
LC_ALL=C awk -F'\t' '$1 != "lane"' "$LNTF1.out" > "$LNTD/before.1"
is "lane status row: every row but the lane row is byte-identical with no lanes.tsv committed and with one committed, in the same checkout and home (control)" \
   "$LNTOKE|$LNTT|$(_lf_count "$LNTD/before.0")|$(_lf_count "$LNTD/before.1")|$(cmp -s "$LNTD/before.0" "$LNTD/before.1" && echo identical || echo different)" \
   "built|built|9|9|identical"
_lf_run "$LNTD/plain-ok" "$LNTOK" "$LNTN" "$FELIX" status
is "lane status row: plain felix status prints the lane row last, aligned as every row is: lane, the state word ok, the detail" \
   "$LNTOKE|$LNTT|$LF_RC|$(_lf_count "$LNTD/plain-ok.out")|$(_lf_last "$LNTD/plain-ok.out")" "built|built|0|10|$LNTPOK"

# ---- C6: no lane is counted -----------------------------------------------------------------------------------------------
_lnt_put "comments and a blank line, no row" $'# No lane is counted yet.\n\n'; _lnt_st "$LNTOK"
is "lane status row: a committed lanes.tsv holding only a comment and a blank line reads lane none - with the no-committed-row detail, last of ten" \
   "$LNTOKE|$LNTT|$LF_RC|$LNTROWS|$LNTLAST" "built|built|0|$LNTTEN|$LNTNONE"
_lnt_absent "removed by a later commit"; printf '%s' "$LNTLANES" > "$LNTP/lanes.tsv"; _lnt_st "$LNTOK"
is "lane status row: a lanes.tsv with a row in the home's working tree, after a commit removed it, counts no lane: lane none - with the no-committed-row detail" \
   "$LNTOKE|$LNTT|$LF_RC|$LNTROWS|$LNTLAST" "built|built|0|$LNTTEN|$LNTNONE"
_lf_run "$LNTD/plain-none" "$LNTOK" "$LNTN" "$FELIX" status
is "lane status row: plain felix status aligns the none row with the state word none in the value column" \
   "$LNTOKE|$LNTT|$LF_RC|$(_lf_last "$LNTD/plain-none.out")" \
   "built|built|0|$(printf '%-9s %-12s %s' lane none "$LNTP/lanes.tsv has no committed row, so no lane is counted")"

# ---- C6: no project governs ---------------------------------------------------------------------------------------------------
_lnt_put "the capability row again" "$LNTLANES"
_lnt_st "$LNTD/plain"
is "lane status row: in a directory no project governs, outside any repository, the lane row is lane none - this directory is not a governed checkout, last of ten" \
   "$LF_RC|$LNTROWS|$LNTLAST" "0|$LNTTEN|$LNTUNG"
LNTa="not built: an unbound repository"
_lf_init "$LNTD/unbound" && _lf_commit "$LNTD/unbound" $((LNTN - LNTDAY)) $'engine: a repository no project binds\n' engine/x.sh \
  && _lf_publish "$LNTD/unbound" && [ ! -e "$LNTD/unbound/.felix" ] && LNTa=built
_lnt_st "$LNTD/unbound"
is "lane status row: in a repository with refs/remotes/origin/main and an engine landing that no project binds (no .felix, no remote), the lane row is the same none row" \
   "$LNTa|$LF_RC|$LNTROWS|$LNTLAST" "built|0|$LNTTEN|$LNTUNG"
_lf_run "$LNTD/plain-ung" "$LNTD/plain" "$LNTN" "$FELIX" status
is "lane status row: plain felix status in a directory no project governs ends with lane, none, this directory is not a governed checkout, aligned" \
   "$LF_RC|$(_lf_last "$LNTD/plain-ung.out")" "0|$(printf '%-9s %-12s %s' lane none 'this directory is not a governed checkout')"

# ---- C6: the first lane's state ---------------------------------------------------------------------------------------------
_lnt_chk short m u u u
_lnt_st "$LNTR"
is "lane status row: L 1 of T 4 at share 1/2 reads lane value short 1 of 4 engine landings in 14 days, target 1/2" \
   "$LNTE|$LNTT|$LF_RC|$LNTROWS|$LNTLAST" "built|built|0|$LNTTEN|$(_lf_tsv lane value short '1 of 4 engine landings in 14 days, target 1/2')"
_lnt_chk zero u u
_lnt_st "$LNTR"
is "lane status row: L 0 of T 2 reads lane value zero 0 of 2 engine landings in 14 days, target 1/2" \
   "$LNTE|$LNTT|$LF_RC|$LNTROWS|$LNTLAST" "built|built|0|$LNTTEN|$(_lf_tsv lane value zero '0 of 2 engine landings in 14 days, target 1/2')"
_lnt_chk idle
_lnt_st "$LNTR"
is "lane status row: no landing in the window reads lane value idle 0 of 0 engine landings in 14 days, target 1/2" \
   "$LNTE|$LNTT|$LF_RC|$LNTROWS|$LNTLAST" "built|built|0|$LNTTEN|$(_lf_tsv lane value idle '0 of 0 engine landings in 14 days, target 1/2')"

# ---- the first data row speaks, its window and share from the table -----------------------------------------------------
_lnt_put "another lane first, window 9, share 2/5" $'# Two lanes.\n\ntrust_b\t^engine/\t2/5\t9\ncapability\t^engine/\t1/2\t14\n'
_lnt_st "$LNTOK"
is "lane status row: the row speaks for the first data row, under a comment and a blank line, with its window and share from the table: lane trust_b reads value zero, 0 of 2 engine landings in 9 days, target 2/5" \
   "$LNTOKE|$LNTT|$LF_RC|$LNTROWS|$LNTLAST" "built|built|0|$LNTTEN|$(_lf_tsv lane value zero '0 of 2 engine landings in 9 days, target 2/5')"
_lnt_put "a broken second row" $'capability\t^engine/\t1/2\t14\ndocs\t^docs/\t0/2\t14\n'
_lnt_st "$LNTOK"
is "lane status row: a second row whose share is 0/2 leaves the row speaking for the first: lane value ok 1 of 2 engine landings in 14 days, target 1/2" \
   "$LNTOKE|$LNTT|$LF_RC|$LNTROWS|$LNTLAST" "built|built|0|$LNTTEN|$LNTVOK"
_lnt_put "a broken first row" $'capability\t(\t1/2\t14\ndocs\t^docs/\t1/2\t14\n'
_lnt_st "$LNTOK"
is "lane status row L-NEVER-OK: a first row whose counts is ( reads lane unknown - with R7 for that lane, never the value ok, though the row after it is valid" \
   "$LNTOKE|$LNTT|$LF_RC|$LNTROWS|$LNTLAST" \
   "built|built|0|$LNTTEN|$(_lf_tsv lane unknown - 'the counts pattern of lane capability is not an ERE grep accepts')"

# ---- C6: unknown ------------------------------------------------------------------------------------------------------------------
_lnt_put "the capability row, for the unknown cases" "$LNTLANES"
_lf_checkout "$LNTD/noref" sr $((LNTN - 30 * LNTDAY)); LNTNR="$LF_REPO"; LNTa="not built: a checkout with no ref"
_lf_commit "$LNTNR" $((LNTN - LNTDAY)) $'engine: x\n\nFelix-Lane: capability\n' engine/x.sh \
  && LNTa="$( _fx_cd "$LNTNR" || exit 1; _lf_g 1700000000 rev-parse --verify -q refs/remotes/origin/main >/dev/null 2>&1 && echo has-ref || echo built )"
LNTR1="refs/remotes/origin/main cannot be read in $LNTNR"
_lnt_st "$LNTNR"
is "lane status row L-NEVER-OK: an unreadable ref (no refs/remotes/origin/main) gives state unknown and value -: lane unknown - refs/remotes/origin/main cannot be read in <repo>, never a calm value" \
   "$LNTa|$LNTT|$LF_RC|$LNTROWS|$LNTLAST" "built|built|0|$LNTTEN|$(_lf_tsv lane unknown - "$LNTR1")"
_lf_run "$LNTD/plain-r1" "$LNTNR" "$LNTN" "$FELIX" status
is "lane status row L-NEVER-OK: plain felix status aligns the unknown row with the state word unknown in the value column" \
   "$LNTa|$LNTT|$LF_RC|$(_lf_last "$LNTD/plain-r1.out")" "built|built|0|$(printf '%-9s %-12s %s' lane unknown "$LNTR1")"
_lnt_st "$LNTOK" 12a
is "lane status row L-NEVER-OK: FELIX_LANE_NOW=12a over a valid table reads lane unknown - FELIX_LANE_NOW is not a whole number of seconds" \
   "$LNTOKE|$LNTT|$LF_RC|$LNTROWS|$LNTLAST" "built|built|0|$LNTTEN|$(_lf_tsv lane unknown - 'FELIX_LANE_NOW is not a whole number of seconds')"
_lnt_put "a CR in its row" $'capability\t^engine/\t1/2\t14\r\n'
_lnt_st "$LNTOK"
is "lane status row L-NEVER-OK: a committed lanes.tsv the shape check refuses (a CR in its row) reads lane unknown - <PROJ>/lanes.tsv cannot be read as lanes.tsv" \
   "$LNTOKE|$LNTT|$LF_RC|$LNTROWS|$LNTLAST" "built|built|0|$LNTTEN|$(_lf_tsv lane unknown - "$LNTP/lanes.tsv cannot be read as lanes.tsv")"

# ---- the clock: unset or empty is the machine's (C9) ---------------------------------------------------------------------------
_lnt_put "the capability row, for the clock" "$LNTLANES"
LNTNOW="$(date +%s)"; LNTa="not built: the clock checkout"
_lf_checkout "$LNTD/clock" sr $((LNTNOW - 30 * LNTDAY)); LNTCK="$LF_REPO"
_lf_chain "$LNTCK" capability $((LNTNOW - 3 * LNTDAY)) "$LNTDAY" m u \
  && [ "$(_lf_spine "$LNTCK")" = "$((LNTNOW - 2 * LNTDAY)):1 $((LNTNOW - 3 * LNTDAY)):1 $((LNTNOW - 30 * LNTDAY)):0" ] && LNTa=built
_lnt_st "$LNTCK" -; LNTb="$LF_RC|$LNTLAST"
_lnt_st "$LNTCK" ""; LNTb="$LNTb|$LF_RC|$LNTLAST"
_lnt_st "$LNTCK" $((LNTNOW - 4 * LNTDAY)); LNTb="$LNTb|$LF_RC|$LNTLAST"
is "lane status row: with FELIX_LANE_NOW unset, and set and empty, now is the machine clock, so landings three and two days back read value ok 1 of 2; with the clock four days back they read idle 0 of 0" \
   "$LNTa|$LNTT|$LNTb" \
   "built|built|0|$LNTVOK|0|$LNTVOK|0|$(_lf_tsv lane value idle '0 of 0 engine landings in 14 days, target 1/2')"

# ---- L-DET ---------------------------------------------------------------------------------------------------------------------------
_lnt_put "the capability row, for L-DET and L-RO" "$LNTLANES"
for LNTk in 1 2; do
  _lf_run "$LNTD/det-t$LNTk" "$LNTOK" "$LNTN" "$FELIX" status --tsv
  _lf_run "$LNTD/det-p$LNTk" "$LNTOK" "$LNTN" "$FELIX" status
  _lf_run "$LNTD/det-u$LNTk" "$LNTNR" "$LNTN" "$FELIX" status --tsv
  [ "$LNTk" = 2 ] || sleep 1
done
LNTa=""
for LNTk in det-t det-p det-u; do cmp -s "$LNTD/${LNTk}1.out" "$LNTD/${LNTk}2.out" && LNTa="$LNTa|same" || LNTa="$LNTa|differ"; done
is "lane status row L-DET: two runs a second apart of felix status --tsv and of felix status, same fixture and FELIX_LANE_NOW, print identical bytes, each ending with the expected lane row" \
   "$LNTOKE|$LNTT${LNTa%|*}|$(_lf_last "$LNTD/det-t1.out")|$(_lf_last "$LNTD/det-p1.out")" "built|built|same|same|$LNTVOK|$LNTPOK"
is "lane status row L-DET L-NEVER-OK: two runs of felix status --tsv in the checkout with no ref print identical bytes, ending with the unknown row" \
   "$LNTT|${LNTa##*|}|$(_lf_last "$LNTD/det-u1.out")" "built|same|$(_lf_tsv lane unknown - "$LNTR1")"

# ---- L-RO and the uncommitted edit ---------------------------------------------------------------------------------------------
# LABEL -> a marker touched a second after the last write, then felix status --tsv and felix status in the ok checkout;
# what they left newer under H (.git and its index included), the memory root and the checkout (.git included), and
# the checkout's refs and worktree list before and after.
_lnt_ro() {
  local f="$LNTD/ro" r1 r2 w1 w2 nw
  sleep 1; touch "$f.marker"
  r1="$( _fx_cd "$LNTOK" && _lf_g 1700000000 for-each-ref )"; w1="$( _fx_cd "$LNTOK" && _lf_g 1700000000 worktree list --porcelain )"
  _lf_run "$f-t" "$LNTOK" "$LNTN" "$FELIX" status --tsv; r2="$LF_RC"
  _lf_run "$f-p" "$LNTOK" "$LNTN" "$FELIX" status; r2="$r2|$LF_RC"
  nw="$(find "$LNTH" "$LNTD/memory" "$LNTOK" -newer "$f.marker" 2>&1)"
  w2="$( _fx_cd "$LNTOK" && _lf_g 1700000000 worktree list --porcelain )"
  r2="$r2|$([ -n "$r1" ] && [ "$r1" = "$( _fx_cd "$LNTOK" && _lf_g 1700000000 for-each-ref )" ] && echo same || echo changed)"
  is "lane status row L-RO: $1: felix status --tsv and felix status exit 0, leave nothing newer under the home, the memory root and the checkout, leave the checkout's refs and worktree list as they were, and print the committed lane row" \
     "$LNTOKE|$LNTT|newer[${nw}]|$r2|$([ -n "$w1" ] && [ "$w1" = "$w2" ] && echo same || echo changed)|$(_lf_last "$f-t.out")|$(_lf_last "$f-p.out")" \
     "built|built|newer[]|0|0|same|same|$LNTVOK|$LNTPOK"
}
_lnt_ro "as built"
touch "$LNTP/lanes.tsv"
_lnt_ro "after a touch of lanes.tsv, its content unchanged"
printf '%s' $'# The lanes this fixture counts.\n\ncapability\t^engine/\t1/4\t7\n' > "$LNTP/lanes.tsv"
_lnt_ro "after an uncommitted edit to lanes.tsv (share 1/4, window 7)"
printf '%s' "$LNTLANES" > "$LNTP/lanes.tsv"

# ---- the status shape, over every felix status --tsv above -------------------------------------------------------------------
LNTo=""; LNTc=0
for LNTw in "$LNTD"/st/*.out; do
  [ -f "$LNTw" ] || continue
  LNTc=$((LNTc + 1))
  LNTl="$(LC_ALL=C awk -F'\t' '{ printf "%s ", $1 }' "$LNTw")"
  [ "$LNTl" = "$LNTTEN" ] || LNTo="$LNTo [run ${LNTw##*/}: rows $LNTl]"
  LNTl="$(LC_ALL=C awk -F'\t' 'NF != 4 || $2 !~ /^(value|none|unknown)$/ || ($2 != "value" && $3 != "-") || $4 == "" || $3 ~ / / { print NR ": " $0 }' "$LNTw")"
  [ -z "$LNTl" ] || LNTo="$LNTo [run ${LNTw##*/}: line $LNTl]"
done
is "lane status row: every felix status --tsv this part ran prints ten rows ending in lane, and no row breaks D16's shape: four tab fields, a known state, - unless the state is value, a detail, a value with no space" \
   "$LNTc runs:$LNTo" "18 runs:"

# ---- the review's second amendment: 1 day (F11) and a count that ends early (F1) --------------------------------------
# Added on 2026-10-30, still blind, after the shape check, whose count of runs stands; these runs are not kept in st/.
_lnt_put "the capability row, window 1" $'capability\t^engine/\t1/2\t1\n'
_lf_run "$LNTD/f11" "$LNTOK" "$LNTN" "$FELIX" status --tsv
is "lane status row F11-one-day-reads-1-days: with window 1 and no landing in the last day, the row reads lane value idle 0 of 0 engine landings in 1 day, target 1/2, never 1 days, the last of ten" \
   "$LNTOKE|$LNTT|$LF_RC|$(LC_ALL=C awk -F'\t' '{ printf "%s ", $1 }' "$LNTD/f11.out")|$(_lf_last "$LNTD/f11.out")" \
   "built|built|0|$LNTTEN|$(_lf_tsv lane value idle '0 of 0 engine landings in 1 day, target 1/2')"
# C9's fault through _lf_fault kill, with TMPDIR a directory of the fixture's own, in the ok checkout: when the read of
# the landings starts, the shell that runs it has its parent, then itself, killed. C6 and C9 allow two rows, and the
# assertion accepts exactly these: the lane count did not finish in <repo>, or, where the process ended was one read's
# own, R2. felix status still exits 0 with its ten rows (C6).
_lnt_put "the capability row, for a count that ends early" "$LNTLANES"
LNTkt="$LNTD/f1k-tmp"; rm -rf "$LNTkt"; mkdir -p "$LNTkt"
_lf_fault kill "$LNTD/f1k.fired" "$LNTkt" _lf_run "$LNTD/f1k" "$LNTOK" "$LNTN" "$FELIX" status --tsv
LNTa="$(_lf_last "$LNTD/f1k.out")"
case "$LNTa" in
  ("$(_lf_tsv lane unknown - "the lane count did not finish in $LNTOK")"|"$(_lf_tsv lane unknown - "git could not read the landings on refs/remotes/origin/main in $LNTOK")") LNTa="C3 or R2" ;;
  (*) LNTa="last row [$LNTa]" ;;
esac
is "lane status row F1-count-ends-early L-NEVER-OK: the parent of the shell that runs the read of the landings, then that shell, killed (C9): felix status --tsv exits 0 with ten rows, the last lane unknown - the lane count did not finish in <repo>, or lane unknown - with R2; never a value, the none row or no lane row" \
   "$LNTOKE|$LNTT|$LF_FIRE|$LF_RC|$(LC_ALL=C awk -F'\t' '{ printf "%s ", $1 }' "$LNTD/f1k.out")|$LNTa" "built|built|fired|0|$LNTTEN|C3 or R2"

# ---- the second review's round 1: a resolution that fails, and plain status losing rows (R2-F3, R2-F7) ----------------
# Added on 2026-10-30 from the second review's findings (their inputs and observed output only), still blind, after the
# shape check, whose count of runs stands. In the review's home-apart fixture (_lf_r2, the clock at LNTN), where the lane
# row reads value zero 0 of 2. The faults are the review's probes (_lf_fork), by the words and calling functions it
# names, inputs of the findings: R2-F3 a fork that fails at tr -d [:space:] in felix_resolve_project under
# felix_status_rows; R2-F7 a function command that lowers the limit at command -v felix_capture, so the shell that asked
# fails at its next fork (it reaches the land and hooks rows too, as the review says). Readings: C6's none row is for a
# directory no project governs, so a resolution that did not finish gives the value row, lane unknown - with a reason,
# or, as C3 says of a fork that fails in the surface's own shell, felix status ended with status 128; plain felix status
# prints ten rows ending in the lane row, value or unknown, aligned, or ends with 128, never exit 0 without the lane row.
# Each assertion also compares the run without the fault, so it is red on main.
LNTRT="$LNTD/r2-tmp"; mkdir -p "$LNTRT"; LNTRA="not built: the second review's fixture"; LNTtb=$'\t'
_lf_r2 "$LNTD/r2" p "$LNTN" && LNTRA=built
LNTRC="$LF_REPO"
_lf_use "$LF_HOME" "$LNTD/memory" "$LNTD/user" "$LNTB"
LNTRV="$(_lf_tsv lane value zero '0 of 2 engine landings in 14 days, target 1/2')"
LNTRP="$(printf '%-9s %-12s %s' lane zero '0 of 2 engine landings in 14 days, target 1/2')"
_lf_run "$LNTD/r2f3-0" "$LNTRC" "$LNTN" "$FELIX" status --tsv
LNTb="$LF_RC|$(LC_ALL=C awk -F'\t' '{ printf "%s ", $1 }' "$LNTD/r2f3-0.out")|$(_lf_last "$LNTD/r2f3-0.out")"
_lf_fork fork tr "*' -d [:space:] '*" "*' felix_resolve_project felix_status_rows '*|*' felix_resolve_project '*' felix_status_rows '*" \
  "$LNTD/r2f3.fired" "$LNTRT" _lf_run "$LNTD/r2f3" "$LNTRC" "$LNTN" "$FELIX" status --tsv
LNTa="$(_lf_last "$LNTD/r2f3.out")"; LNTc="$(LC_ALL=C awk -F'\t' '{ printf "%s ", $1 }' "$LNTD/r2f3.out")"
case "$LF_RC|$LNTc|$LNTa" in
  ("128|"*|"0|$LNTTEN|$LNTRV") LNTa="value, unknown or 128" ;;
  ("0|$LNTTEN|lane${LNTtb}unknown${LNTtb}-${LNTtb}"?*) case "${LNTa##*"$LNTtb"}" in (-) LNTa="status 0, last [$LNTa]" ;; (*) LNTa="value, unknown or 128" ;; esac ;;
  (*) LNTa="status $LF_RC, rows [$LNTc], last [$LNTa]" ;;
esac
is "lane status row R2-F3-status-none-row-when-resolution-fails L-NEVER-OK: a fork that fails while felix status --tsv resolves the project (tr -d [:space:] in felix_resolve_project, under felix_status_rows), in a checkout the project governs: the lane row is the value zero 0 of 2 or lane unknown - with a reason, the last of ten, or felix status ends with 128; never the none row this directory is not a governed checkout" \
   "$LNTRA|unfaulted $LNTb|$LF_FIRE|$LNTa" "built|unfaulted 0|$LNTTEN|$LNTRV|fired|value, unknown or 128"
_lf_run "$LNTD/r2f7-0" "$LNTRC" "$LNTN" "$FELIX" status; LNTb="$LF_RC|$(_lf_count "$LNTD/r2f7-0.out")|$(_lf_last "$LNTD/r2f7-0.out")"
_lf_fork lower command "' -v felix_capture '" '*' "$LNTD/r2f7.fired" "$LNTRT" _lf_run "$LNTD/r2f7" "$LNTRC" "$LNTN" "$FELIX" status
LNTa="$(_lf_last "$LNTD/r2f7.out")"; LNTc="$(_lf_count "$LNTD/r2f7.out")"
case "$LF_RC|$LNTc|$LNTa" in
  ("128|"*|"0|10|$LNTRP"|"0|10|$(printf '%-9s %-12s ' lane unknown)"?*) LNTa="ten rows or 128" ;;
  (*) LNTa="status $LF_RC, $LNTc rows, last [$LNTa]" ;;
esac
is "lane status row R2-F7-plain-status-loses-rows-with-exit-0 L-NEVER-OK: plain felix status with a function command that lowers the process limit at command -v felix_capture, so the shell that asked fails at its next fork: ten rows ending in the lane row, zero or unknown, aligned, or felix status ends with 128; never exit 0 without the lane row" \
   "$LNTRA|unfaulted $LNTb|$LF_FIRE|$LNTa" "built|unfaulted 0|10|$LNTRP|fired|ten rows or 128"

# ---- the second review's round 2: a resolution by remote_match that does not finish (R2B-F1) ---------------------------
# Added on 2026-10-30 from the second review's round 2 findings (their inputs and observed output only), still blind. The
# review's home-apart fixture again (_lf_r2), its checkout's untracked .felix removed, so that neither the checkout nor the
# home has a .felix and the checkout is bound to p by remote_match alone (C2: the marker first, then a project.json
# remote_match; p's names o/r, the checkout's origin is https://github.com/o/r.git). Without the fault the lane row reads
# value zero 0 of 2 and felix lane --tsv prints cap's and sec's lines. The fault is the review's fork probe (_lf_fork) at
# the one git call whose words hold get-url, made under felix_resolve_project. Readings: a resolution that did not finish
# is not a directory no project governs, so C6's none row is never its row (C9: never none); the row is lane unknown -
# the lane count did not finish in <repo> (C6), or the value the count gives if the project is found another way, or,
# as C3 says of a fork that fails in the surface's own shell, felix status ends with 128; plain status the same,
# aligned. felix lane --tsv prints nothing on stdout and either ends as C3's count that did not finish (exit 1), or
# exits 2 with a first stderr line of felix's naming the checkout that is not C5's no project governs <dir>. (the
# finding's: a resolution that did not finish is status 2), or ends with 128; or prints the two lines.
LNTMA="not built: R2B-F1's checkout"; LNTMC="$LNTD/r2b/c"
if _lf_r2 "$LNTD/r2b" p "$LNTN"; then
  LNTMC="$LF_REPO"; rm -f "$LNTMC/.felix"
  [ ! -e "$LNTMC/.felix" ] && [ ! -e "$LF_HOME/.felix" ] && [ -n "$(LC_ALL=C awk '/"remote_match":"o\/r"/' "$LF_PROJ/project.json")" ] \
    && [ "$( _fx_cd "$LNTMC" && _lf_g 1700000000 config --get remote.origin.url )" = https://github.com/o/r.git ] && LNTMA=built
fi
LNTML="$LF_R2"; LNTMU="$(_lf_tsv lane unknown - "the lane count did not finish in $LNTMC")"
_lf_use "$LF_HOME" "$LNTD/memory" "$LNTD/user" "$LNTB"
_lf_run "$LNTD/r2bf1-0" "$LNTMC" "$LNTN" "$FELIX" status --tsv
LNTb="$LF_RC|$(LC_ALL=C awk -F'\t' '{ printf "%s ", $1 }' "$LNTD/r2bf1-0.out")|$(_lf_last "$LNTD/r2bf1-0.out")"
_lf_fork fork git '*get-url*' "*' felix_resolve_project '*" "$LNTD/r2bf1.fired" "$LNTRT" _lf_run "$LNTD/r2bf1" "$LNTMC" "$LNTN" "$FELIX" status --tsv
LNTa="$(_lf_last "$LNTD/r2bf1.out")"; LNTc="$(LC_ALL=C awk -F'\t' '{ printf "%s ", $1 }' "$LNTD/r2bf1.out")"
case "$LF_RC|$LNTc|$LNTa" in
  ("0|$LNTTEN|$LNTRV"|"0|$LNTTEN|$LNTMU") LNTa="value, did not finish or 128" ;;
  ("128|"*) [ -z "$(LC_ALL=C awk -F'\t' '$1 == "lane" && $2 != "unknown"' "$LNTD/r2bf1.out")" ] && LNTa="value, did not finish or 128" ;;
esac
is "lane status row R2B-F1-remote-match-resolution-reads-ungoverned L-NEVER-OK: in a checkout bound by remote_match alone, a fork that fails in the git read of its origin's URL (get-url, felix_resolve_project on the stack): felix status --tsv's last of ten rows is lane unknown - the lane count did not finish in <repo>, or the value zero 0 of 2, or felix status ends with 128; never lane none - this directory is not a governed checkout" \
   "$LNTMA|unfaulted $LNTb|$LF_FIRE|status $LF_RC, last [$LNTa]" "built|unfaulted 0|$LNTTEN|$LNTRV|fired|status $LF_RC, last [value, did not finish or 128]"
_lf_run "$LNTD/r2bf1p-0" "$LNTMC" "$LNTN" "$FELIX" status; LNTb="$LF_RC|$(_lf_count "$LNTD/r2bf1p-0.out")|$(_lf_last "$LNTD/r2bf1p-0.out")"
_lf_fork fork git '*get-url*' "*' felix_resolve_project '*" "$LNTD/r2bf1p.fired" "$LNTRT" _lf_run "$LNTD/r2bf1p" "$LNTMC" "$LNTN" "$FELIX" status
LNTa="$(_lf_last "$LNTD/r2bf1p.out")"
case "$LF_RC|$(_lf_count "$LNTD/r2bf1p.out")|$LNTa" in
  ("0|10|$LNTRP"|"0|10|$(printf '%-9s %-12s %s' lane unknown "the lane count did not finish in $LNTMC")") LNTa="value, did not finish or 128" ;;
  ("128|"*) case "$LNTa" in ("$(printf '%-9s %-12s ' lane none)"*) ;; (*) LNTa="value, did not finish or 128" ;; esac ;;
esac
is "lane status row R2B-F1-remote-match-resolution-reads-ungoverned L-NEVER-OK: the same fault in plain felix status: ten rows, the last lane, unknown, the lane count did not finish in <repo>, aligned, or the value zero, or felix status ends with 128; never lane none this directory is not a governed checkout" \
   "$LNTMA|unfaulted $LNTb|$LF_FIRE|status $LF_RC, last [$LNTa]" "built|unfaulted 0|10|$LNTRP|fired|status $LF_RC, last [value, did not finish or 128]"
_lf_run "$LNTD/r2bf1t-0" "$LNTMC" "$LNTN" "$FELIX" lane --tsv; LNTb="$LF_RC|$(cat "$LNTD/r2bf1t-0.out")"
_lf_fork fork git '*get-url*' "*' felix_resolve_project '*" "$LNTD/r2bf1t.fired" "$LNTRT" _lf_run "$LNTD/r2bf1t" "$LNTMC" "$LNTN" "$FELIX" lane --tsv
LNTa="status $LF_RC, stdout [$(cat "$LNTD/r2bf1t.out")], stderr [$(LC_ALL=C awk 'NR == 1' "$LNTD/r2bf1t.err")]"
LNTc="$(LC_ALL=C awk 'NR == 1' "$LNTD/r2bf1t.err")"
if [ "$(_lf_ended "$LNTD/r2bf1t" "$LNTMC")" = ended ] || [ "$LF_RC|$(cat "$LNTD/r2bf1t.out")" = "0|$LNTML" ] \
   || { [ "$LF_RC" = 128 ] && [ ! -s "$LNTD/r2bf1t.out" ]; }; then LNTa="unfinished, or the lines"
elif [ "$LF_RC" = 2 ] && [ ! -s "$LNTD/r2bf1t.out" ] && [ "$LNTc" != "felix: no project governs $LNTMC." ]; then
  case "$LNTc" in ("felix: "*"$LNTMC"*) LNTa="unfinished, or the lines" ;; esac
fi
is "lane status row R2B-F1-remote-match-resolution-reads-ungoverned L-NEVER-OK: the same fault in felix lane --tsv in that checkout: nothing on stdout and C3's the lane count did not finish in <repo> with exit 1, or exit 2 with a first stderr line naming the checkout that is not felix: no project governs <dir>., or exit 128; or the two lines it prints without the fault" \
   "$LNTMA|unfaulted $LNTb|$LF_FIRE|$LNTa" "built|unfaulted 0|$LNTML|fired|unfinished, or the lines"

# ---- design item 46: the status row of a resolution that did not finish, and of the misses that stand ---------------------
# Added on 2026-10-30 from design 11 item 46 (C2's bullet The lane's resolution, C6's last row), still blind, last, after
# the shape check, whose count of runs stands. A home-apart fixture of its own (_lf_r2: LNTI/home holds p, remote_match
# o/r; LNTI/c its checkout), whose checkout _lf_bind puts in a layout; bound by its .felix alone (felix) or by
# remote_match alone (remote), the lane row is the value zero 0 of 2. Readings:
# - I46-11 to I46-14: C9's fork and kill probes (_lf_probe) every time a read the miss stands on is made inside
#   felix_resolve_project (felix: tr -d [:space:], the read of the marker; remote: git remote get-url origin): felix status
#   --tsv exits 0 with ten rows, the last exactly lane unknown - the lane count did not finish in <repo>. Only where a
#   probe reached felix itself (LF_SELF) may it end with 137 (kill, C9) or 128 (fork, C3) and print no lane row.
# - I46-15 to I46-20, no fault: in the layouts none, other, tie, nosuch, empty and closed the miss stands, and the last of
#   ten rows is lane none - this directory is not a governed checkout; each first runs a layout that binds, so it is red
#   on main, which prints no lane row.
LNTIA="not built: item 46's fixture"; LNTIT="$LNTD/i46-tmp"
_lf_r2 "$LNTD/i46" p "$LNTN" && LNTIA=built
LNTIH="$LF_HOME"; LNTIC="$LF_REPO"
LNTIV="$(_lf_tsv lane value zero '0 of 2 engine landings in 14 days, target 1/2')"
LNTIU="$(_lf_tsv lane unknown - "the lane count did not finish in $LNTIC")"
_lf_use "$LNTIH" "$LNTD/memory" "$LNTD/user" "$LNTB"
# OUT -> the rows of felix status --tsv's OUT.out, a space after each.
_lnt_rows() { LC_ALL=C awk -F'\t' '{ printf "%s ", $1 }' "$1.out" 2>/dev/null; }
# LAYOUT MODE NAME WORDS -> the checkout in LAYOUT; felix status --tsv there; then felix status --tsv under _lf_probe MODE
# NAME WORDS, felix_resolve_project on the stack, with a fresh TMPDIR. LNTa what was built and the unfaulted lane row,
# LNTb the probe's LF_FIRE and "did not finish" when the run ended as the readings above say, else its status and rows.
_lnt_i46f() {
  local r l
  _lf_bind "$LNTIC" "$LNTIH" p "$1"; LNTa="$LNTIA|$LF_BOUND"
  _lf_run "$LNTD/i46-0" "$LNTIC" "$LNTN" "$FELIX" status --tsv; LNTa="$LNTa|unfaulted $LF_RC|$(_lf_last "$LNTD/i46-0.out")"
  rm -rf "$LNTIT"; mkdir -p "$LNTIT"
  _lf_probe "$2" "$3" "$4" "*' felix_resolve_project '*" "$LNTD/i46f.fired" "$LNTIT" _lf_run "$LNTD/i46f" "$LNTIC" "$LNTN" "$FELIX" status --tsv
  r="$(_lnt_rows "$LNTD/i46f")"; l="$(_lf_last "$LNTD/i46f.out")"
  LNTb="$LF_FIRE|status $LF_RC, rows [$r], last [$l]"
  if [ "$LF_RC|$r|$l" = "0|$LNTTEN|$LNTIU" ]; then LNTb="$LF_FIRE|did not finish"
  elif [ "$LF_SELF" = self ] && [ -z "$(LC_ALL=C awk -F'\t' '$1 == "lane"' "$LNTD/i46f.out")" ]; then
    case "$2:$LF_RC" in (kill:137|fork:128) LNTb="$LF_FIRE|did not finish" ;; esac
  fi
}
LNTa5='felix status --tsv exits 0 with ten rows, the last exactly lane unknown - the lane count did not finish in <repo>'
_lnt_i46f felix fork tr "*' -d [:space:] '*"
is "I46-11 lane status row, in a checkout its .felix alone binds, with C9's fork probe at the read of the marker inside felix_resolve_project (tr -d [:space:]): $LNTa5 (or 128 with no lane row, where the fork failed in felix's own shell); the probe fired, and unfaulted the row is the value zero" \
   "$LNTa|$LNTb" "built|built|unfaulted 0|$LNTIV|fired|did not finish"
_lnt_i46f felix kill tr "*' -d [:space:] '*"
is "I46-12 lane status row, in a checkout its .felix alone binds, with C9's kill probe at the read of the marker inside felix_resolve_project (tr -d [:space:]): $LNTa5 (or 137 with no lane row, where the kill reached felix itself); the probe fired, and unfaulted the row is the value zero" \
   "$LNTa|$LNTb" "built|built|unfaulted 0|$LNTIV|fired|did not finish"
_lnt_i46f remote fork git "*' remote get-url origin '*"
is "I46-13 lane status row, in a checkout remote_match alone binds, with C9's fork probe at git remote get-url origin inside felix_resolve_project: $LNTa5 (or 128 with no lane row, where the fork failed in felix's own shell); the probe fired, and unfaulted the row is the value zero" \
   "$LNTa|$LNTb" "built|built|unfaulted 0|$LNTIV|fired|did not finish"
_lnt_i46f remote kill git "*' remote get-url origin '*"
is "I46-14 lane status row, in a checkout remote_match alone binds, with C9's kill probe at git remote get-url origin inside felix_resolve_project: $LNTa5 (or 137 with no lane row, where the kill reached felix itself); the probe fired, and unfaulted the row is the value zero" \
   "$LNTa|$LNTb" "built|built|unfaulted 0|$LNTIV|fired|did not finish"

# MISS BIND -> the checkout in BIND and felix status --tsv there, then in MISS and felix status --tsv there. LNTa what
# was built and BIND's lane row, LNTb MISS's status, rows and last row.
_lnt_i46m() {
  _lf_bind "$LNTIC" "$LNTIH" p "$2"; LNTa="$LNTIA|$2 $LF_BOUND"
  _lf_run "$LNTD/i46b" "$LNTIC" "$LNTN" "$FELIX" status --tsv; LNTa="$LNTa|$LF_RC|$(_lf_last "$LNTD/i46b.out")"
  _lf_bind "$LNTIC" "$LNTIH" p "$1"; LNTa="$LNTa|$1 $LF_BOUND"
  _lf_run "$LNTD/i46m" "$LNTIC" "$LNTN" "$FELIX" status --tsv; LNTb="$LF_RC|$(_lnt_rows "$LNTD/i46m")|$(_lf_last "$LNTD/i46m.out")"
}
LNTa5='the last of felix status --tsv'"'"'s ten rows is lane none - this directory is not a governed checkout, never unknown'
_lnt_i46m none felix
is "I46-15 lane status row, a miss that stands: in a checkout with no .felix and no origin remote, $LNTa5; with its .felix naming p the row is the value zero" \
   "$LNTa|$LNTb" "built|felix built|0|$LNTIV|none built|0|$LNTTEN|$LNTUNG"
_lnt_i46m other remote
is "I46-16 lane status row, a miss that stands: in a checkout whose origin no project's remote_match names, $LNTa5; with an origin p's remote_match names the row is the value zero" \
   "$LNTa|$LNTb" "built|remote built|0|$LNTIV|other built|0|$LNTTEN|$LNTUNG"
_lnt_i46m tie remote
is "I46-17 lane status row, a miss that stands: in a checkout whose origin two projects' remote_match name equally, a tie, $LNTa5; with p's alone naming it the row is the value zero" \
   "$LNTa|$LNTb" "built|remote built|0|$LNTIV|tie built|0|$LNTTEN|$LNTUNG"
_lnt_i46m nosuch felix
is "I46-18 lane status row, a miss that stands: in a checkout whose .felix names no project, $LNTa5; with its .felix naming p the row is the value zero" \
   "$LNTa|$LNTb" "built|felix built|0|$LNTIV|nosuch built|0|$LNTTEN|$LNTUNG"
_lnt_i46m empty felix
is "I46-19 lane status row, a miss that stands: in a checkout whose .felix is empty, $LNTa5; with its .felix naming p the row is the value zero" \
   "$LNTa|$LNTb" "built|felix built|0|$LNTIV|empty built|0|$LNTTEN|$LNTUNG"
LNTa6="I46-20 lane status row, a miss that stands: in a checkout whose .felix exists and cannot be opened (mode 000), $LNTa5; with its .felix naming p the row is the value zero"
if [ "$(id -u)" = 0 ]; then skip "$LNTa6" "the suite runs as root, which opens a .felix of mode 000"
else
  _lnt_i46m closed felix
  is "$LNTa6" "$LNTa|$LNTb" "built|felix built|0|$LNTIV|closed built|0|$LNTTEN|$LNTUNG"
fi
_lf_bind "$LNTIC" "$LNTIH" p felix

# ---- the third review's round 1: the lane's own check of the resolution (V3R1-F1, V3R1-F2) ------------------------------
# Added on 2026-10-30 from the third review's round 1 findings (their inputs and observed output only) and C2 as 777e6c2d
# amended it, still blind, last. Readings:
# - V3R1-F1: item 46's checkout bound by remote_match alone (_lf_bind remote), with C9's fork probe (_lf_probe) at every
#   sed whose words hold remote_match, whatever calls it: the resolver's read and the check's own (a sed of its own, C2)
#   both fail, so the resolution did not finish: felix status --tsv exits 0 with ten rows, the last exactly lane unknown -
#   the lane count did not finish in <repo> (C6), or ends with 128 and no lane row where the fork failed in felix's own
#   shell; never the none row this directory is not a governed checkout.
# - V3R1-F2: _lf_two's home of two projects and its checkout (apart), which remote_match alone binds to z, whose
#   github.com/o/r is longer than p's o/r: unfaulted the row is the value zero 0 of 1 engine landings in 7 days, target
#   1/2. C9's fork and kill probes at sed naming projects/z/project.json inside felix_resolve_project let the resolver bind
#   p while the check binds z, another project, so the resolution did not finish (C2; design item 47): the unknown row
#   above (or 128 or 137 with no lane row, where the probe reached felix itself); never p's value zero 0 of 1 engine
#   landings in 14 days, and never z's value row as without the fault (from the disputes on round 1: an engine that put
#   its own binding in place of the resolver's would print it).
# STACK MODE NAME WORDS DIR -> felix status --tsv in DIR under _lf_probe MODE NAME WORDS STACK with a fresh TMPDIR. LNTb
# the probe's LF_FIRE and "as C6 says" when the run ended as the readings say, else its status, rows and last row.
_lnt_v3() {
  local r l
  rm -rf "$LNTIT"; mkdir -p "$LNTIT"
  _lf_probe "$2" "$3" "$4" "$1" "$LNTD/v3f.fired" "$LNTIT" _lf_run "$LNTD/v3f" "$5" "$LNTN" "$FELIX" status --tsv
  r="$(_lnt_rows "$LNTD/v3f")"; l="$(_lf_last "$LNTD/v3f.out")"
  LNTb="$LF_FIRE|status $LF_RC, rows [$r], last [$l]"
  if [ "$LF_RC|$r" = "0|$LNTTEN" ] && [ "$l" = "$(_lf_tsv lane unknown - "the lane count did not finish in $5")" ]; then
    LNTb="$LF_FIRE|as C6 says"
  elif [ "$LF_SELF" = self ] && [ -z "$(LC_ALL=C awk -F'\t' '$1 == "lane"' "$LNTD/v3f.out")" ]; then
    case "$2:$LF_RC" in (kill:137|fork:128) LNTb="$LF_FIRE|as C6 says" ;; esac
  fi
}
_lf_bind "$LNTIC" "$LNTIH" p remote; LNTa="$LNTIA|$LF_BOUND"
_lf_run "$LNTD/v3-0" "$LNTIC" "$LNTN" "$FELIX" status --tsv; LNTa="$LNTa|unfaulted $LF_RC|$(_lf_last "$LNTD/v3-0.out")"
_lnt_v3 '*' fork sed '*remote_match*' "$LNTIC"
is "lane status row V3R1-F1-remote-match-read-fault-reads-ungoverned L-NEVER-OK: in a checkout remote_match alone binds, C9's fork probe at every sed whose words hold remote_match, the resolver's read and the lane check's own: felix status --tsv exits 0 with ten rows, the last exactly lane unknown - the lane count did not finish in <repo> (or 128 with no lane row, where the fork failed in felix's own shell); never the none row this directory is not a governed checkout; the probe fired, and unfaulted the row is the value zero" \
   "$LNTa|$LNTb" "built|built|unfaulted 0|$LNTIV|fired|as C6 says"
_lf_bind "$LNTIC" "$LNTIH" p felix

LNTVA="not built: V3R1-F2's home and checkout"; LNTVC="$LNTD/v3f2/c"
_lf_two "$LNTD/v3f2" apart "$LNTN" && LNTVA=built
_lf_use "$LNTD/v3f2/home" "$LNTD/memory" "$LNTD/user" "$LNTB"
LNTVZ="$(_lf_tsv lane value zero '0 of 1 engine landings in 7 days, target 1/2')"
_lf_run "$LNTD/v3f2-0" "$LNTVC" "$LNTN" "$FELIX" status --tsv; LNTa="$LNTVA|unfaulted $LF_RC|$(_lf_last "$LNTD/v3f2-0.out")"
LNTa6='felix status --tsv exits 0 with ten rows, the last exactly lane unknown - the lane count did not finish in <repo>, since the check binds z where the resolver found p (C2, C6)'
_lnt_v3 "*' felix_resolve_project '*" fork sed '*projects/z/project.json*' "$LNTVC"
is "lane status row V3R1-F2-shorter-remote-match-binds L-NEVER-OK: in a checkout whose origin two projects' remote_match name, z's github.com/o/r the longer, so the row is the value zero 0 of 1 engine landings in 7 days, target 1/2, C9's fork probe at sed naming projects/z/project.json inside felix_resolve_project, where the resolver can bind p's shorter o/r: $LNTa6 (or 128 with no lane row, where the fork failed in felix's own shell); never p's value zero 0 of 1 engine landings in 14 days, nor z's value row as without the fault; the probe fired" \
   "$LNTa|$LNTb" "built|unfaulted 0|$LNTVZ|fired|as C6 says"
_lnt_v3 "*' felix_resolve_project '*" kill sed '*projects/z/project.json*' "$LNTVC"
is "lane status row V3R1-F2-shorter-remote-match-binds L-NEVER-OK: the same checkout, C9's kill probe at sed naming projects/z/project.json inside felix_resolve_project: $LNTa6 (or 137 with no lane row, where the kill reached felix itself); never p's value zero 0 of 1 engine landings in 14 days, nor z's value row as without the fault; the probe fired" \
   "$LNTa|$LNTb" "built|unfaulted 0|$LNTVZ|fired|as C6 says"
_lf_use "$LNTH" "$LNTD/memory" "$LNTD/user" "$LNTB"

# ---- the third review's round 2: an origin URL that ends in LF (V3R2-F3) ----------------------------------------------
# Added on 2026-10-30 from the third review's round 2 finding V3R2-F3, its layout (a) (inputs and observed output only),
# and C2 as 5e632334 amended it, still blind, last. No fault is injected and no read fails. A home of its own holds q
# alone, its project.json naming remote_match g/r (_lf_match), and no lanes.tsv; a checkout with no .felix whose
# remote.origin.url, set with git config, is https://gitlab.example/g/r.git and one LF, so that git remote get-url origin
# prints the URL, an LF and git's own LF. C2: the check takes the URL with its trailing LFs dropped, as the resolver's
# substitution takes it, and binds q as the resolver does; so felix lane --tsv exits 0 with nothing on stdout (no
# lanes.tsv, C5), and the status row is C6's none row for q, never lane unknown - the lane count did not finish in
# <repo>. Layout (b), a project directory whose name ends in LF, is a limit C2 states, and is not asserted.
LNTWA="not built: V3R2-F3's home and checkout"; LNTWC="$LNTD/v3r2f3/c"; LNTWP="$LNTD/v3r2f3/home/projects/q"
if _lf_home "$LNTD/v3r2f3/home" q $((LNTN - 40 * LNTDAY)) && _lf_match "$LF_PROJ" g/r && _lf_init "$LNTWC" \
   && printf 'a checkout of q\n' > "$LNTWC/README" && _lf_commit "$LNTWC" $((LNTN - 30 * LNTDAY)) $'the root\n' =README && _lf_publish "$LNTWC"; then
  LNTWC="$(cd -P -- "$LNTWC" && pwd -P)"; LNTWH="$LF_HOME"; LNTWP="$LF_PROJ"
  ( _fx_cd "$LNTWC" || exit 1; _lf_g 1700000000 config remote.origin.url $'https://gitlab.example/g/r.git\n' ) >/dev/null 2>&1
  ( _fx_cd "$LNTWC" || exit 1; _lf_g 1700000000 remote get-url origin ) > "$LNTD/v3r2f3.url" 2>/dev/null
  printf 'https://gitlab.example/g/r.git\n\n' > "$LNTD/v3r2f3.want"
  cmp -s "$LNTD/v3r2f3.url" "$LNTD/v3r2f3.want" && [ ! -e "$LNTWC/.felix" ] && [ ! -L "$LNTWC/.felix" ] && [ ! -e "$LNTWP/lanes.tsv" ] \
    && [ "$(ls "$LNTWH/projects")" = q ] && [ -n "$(LC_ALL=C awk '/"remote_match":"g\/r"/' "$LNTWP/project.json")" ] && LNTWA=built
  _lf_use "$LNTWH" "$LNTD/memory" "$LNTD/user" "$LNTB"
fi
_lf_run "$LNTD/v3r2f3-t" "$LNTWC" "$LNTN" "$FELIX" lane --tsv; LNTa="$LF_RC|$(wc -c < "$LNTD/v3r2f3-t.out" | tr -d ' ')"
_lf_run "$LNTD/v3r2f3-s" "$LNTWC" "$LNTN" "$FELIX" status --tsv; LNTa="$LNTa|$LF_RC|$(_lnt_rows "$LNTD/v3r2f3-s")|$(_lf_last "$LNTD/v3r2f3-s.out")"
is "lane status row V3R2-F3-origin-url-trailing-lf-reads-unresolved: in a checkout with no .felix whose origin URL, https://gitlab.example/g/r.git, ends in an LF of its own, and whose home's only project q names remote_match g/r and commits no lanes.tsv, no read failing: felix lane --tsv exits 0 with nothing on stdout, and felix status --tsv exits 0 with ten rows, the last lane none - <PROJ>/lanes.tsv has no committed row, so no lane is counted; never lane unknown - the lane count did not finish in <repo>" \
   "$LNTWA|$LNTa" "built|0|0|0|$LNTTEN|$(_lf_tsv lane none - "$LNTWP/lanes.tsv has no committed row, so no lane is counted")"
_lf_use "$LNTH" "$LNTD/memory" "$LNTD/user" "$LNTB"

# ---- the third review's round 3: the rows before the lane row take the shared resolver's answer (V3R3-F1) -------------
# Added on 2026-10-30 from the third review's round 3 finding V3R3-F1 (its inputs and observed output only) and C6 as
# 8630c9b3 amended it (design 11 item 49), still blind, last. C6: every row before the lane row is byte-identical to what
# origin/main prints in the same directory, because those rows take the project from felix_resolve_project before any of
# the lane's code runs; only the lane row reads the lane's resolution (C2). Readings:
# - Layout (a): _lf_r2's home of p (remote_match o/r; lanes.tsv cap, then sec; lane-next.tsv) and its checkout, bound by
#   its .felix and with the origin https://github.com/o/r.git (C); then the same checkout with its .felix removed, bound
#   by remote_match alone (CR). Unfaulted, each prints ten rows, none of the first nine reading this directory is not a
#   governed checkout, the last the value zero 0 of 2. C9's fork and kill probes (_lf_probe) act at a read only the
#   lane's check makes, keyed to the function names the finding gives: in C, tr whose words hold -d and [:space:] with
#   _lane_marker on the stack; in CR, git remote get-url origin with _lane_origin on it, and sed whose words hold
#   remote_match with _lane_remote_match on it. main never meets them, so its rows there are the unfaulted ones: rows 1
#   to 9 under the probe are byte-identical to the same checkout's rows 1 to 9 with none, and the tenth and last row is
#   exactly lane unknown - the lane count did not finish in <repo> (C6). Only where the probe reached felix itself
#   (LF_SELF) may felix end with 128 (fork, C3) or 137 (kill, C9) and no lane row, each row it printed then the
#   unfaulted one of its line.
# - Layout (b), no fault: _lf_v3r3's home, whose only project directory is named q and one LF (remote_match o/r), and
#   its checkout with no .felix and the origin https://github.com/o/r.git. The shared resolver's answer, through a
#   command substitution, is q, a project with no directory, and main prints q's rows (reach none - q declares no plugin
#   or mcp rows; gate value no-gate <home>/projects/q/project.json does not exist, ...; land none - no land-on-green job
#   for q; ...). The rows the same engine prints for q are read in the same home and checkout once _lf_v3r3q adds a
#   directory projects/q (a CLAUDE.md, no project.json) and a .felix naming q, which every resolution binds (on
#   origin/main at cc238b25 the nine rows of the two layouts were byte-identical, run by hand on 2026-10-30). Rows 1 to 9
#   of (b) are byte-identical to those, and its tenth and last row is lane unknown - the lane count did not finish in
#   <repo>, the limit C2 states for a directory name that ends in LF.
LNTXA="not built: V3R3-F1's home and checkout"; LNTXT="$LNTD/v3r3-tmp"; LNTXC="$LNTD/v3r3/c"
if _lf_r2 "$LNTD/v3r3" p "$LNTN" && [ -f "$LF_REPO/.felix" ] \
   && [ "$( _fx_cd "$LF_REPO" && _lf_g 1700000000 config --get remote.origin.url )" = https://github.com/o/r.git ]; then
  LNTXA=built; LNTXC="$LF_REPO"
  _lf_use "$LF_HOME" "$LNTD/memory" "$LNTD/user" "$LNTB"
fi
LNTXW="unfaulted 0|$LNTTEN|0 of the nine ungoverned|$(_lf_tsv lane value zero '0 of 2 engine landings in 14 days, target 1/2')"
# DIR -> felix status --tsv in DIR with no probe. LNTXU its status, its rows, how many of rows 1 to 9 read this directory
# is not a governed checkout, and its last row; $LNTD/v3r3-0.nine its rows 1 to 9.
_lnt_v3r3u() {
  _lf_run "$LNTD/v3r3-0" "$1" "$LNTN" "$FELIX" status --tsv
  LC_ALL=C awk 'NR <= 9' "$LNTD/v3r3-0.out" > "$LNTD/v3r3-0.nine"
  LNTXU="unfaulted $LF_RC|$(_lnt_rows "$LNTD/v3r3-0")|$(LC_ALL=C awk -F'\t' '$4 == "this directory is not a governed checkout" { n++ } END { print n + 0 }' "$LNTD/v3r3-0.nine") of the nine ungoverned|$(_lf_last "$LNTD/v3r3-0.out")"
}
# A B -> nothing when every line of B is the line of A at the same number and B has no more lines than A, else the
# first line of B that is not, with its number.
_lnt_v3r3k() { LC_ALL=C awk 'FILENAME == ARGV[1] { u[FNR] = $0; next } !(FNR in u) || $0 != u[FNR] { print FNR ": " $0; exit }' "$1" "$2" 2>/dev/null; }
# MODE NAME WORDS STACK DIR -> felix status --tsv in DIR under _lf_probe MODE NAME WORDS STACK, with a fresh TMPDIR,
# against the rows of the last _lnt_v3r3u. LNTb the probe's LF_FIRE and "as C6 says" when the run ended as the readings
# say, else its status, its rows, its first row unlike the unfaulted run's, and its last row.
_lnt_v3r3() {
  local r l k
  rm -rf "$LNTXT"; mkdir -p "$LNTXT"
  _lf_probe "$1" "$2" "$3" "$4" "$LNTD/v3r3f.fired" "$LNTXT" _lf_run "$LNTD/v3r3f" "$5" "$LNTN" "$FELIX" status --tsv
  r="$(_lnt_rows "$LNTD/v3r3f")"; l="$(_lf_last "$LNTD/v3r3f.out")"
  LC_ALL=C awk 'NR <= 9' "$LNTD/v3r3f.out" > "$LNTD/v3r3f.nine"
  k="$(_lnt_v3r3k "$LNTD/v3r3-0.nine" "$LNTD/v3r3f.nine")"
  LNTb="$LF_FIRE|status $LF_RC, rows [$r], first row unlike the unfaulted one [$k], last [$l]"
  if [ "$LF_RC|$r" = "0|$LNTTEN" ] && [ -z "$k" ] && cmp -s "$LNTD/v3r3-0.nine" "$LNTD/v3r3f.nine" \
     && [ "$l" = "$(_lf_tsv lane unknown - "the lane count did not finish in $5")" ]; then
    LNTb="$LF_FIRE|as C6 says"
  elif [ "$LF_SELF" = self ] && [ -z "$k" ] && [ "$(_lf_count "$LNTD/v3r3f.out")" -le 9 ]; then
    case "$1:$LF_RC" in (kill:137|fork:128) LNTb="$LF_FIRE|as C6 says" ;; esac
  fi
}
LNTa5='felix status --tsv'"'"'s rows 1 to 9 are byte-identical to its rows with no probe, as origin/main prints them there, and the tenth and last row is exactly lane unknown - the lane count did not finish in <repo>'
LNTa6='the probe fired, and unfaulted the rows are ten, none of the first nine reading this directory is not a governed checkout, the last the value zero 0 of 2'
_lnt_v3r3u "$LNTXC"; LNTa="$LNTXA|$LNTXU"
_lnt_v3r3 fork tr "*' -d '*'[:space:]'*" "*' _lane_marker '*" "$LNTXC"
is "lane status row V3R3-F1-rows-before-the-lane-row-read-ungoverned L-NEVER-OK: (a) in a checkout bound by its .felix, with the origin p's remote_match names, C9's fork probe at tr -d [:space:] with _lane_marker on the stack, a read only the lane's check makes: $LNTa5 (or 128 with no lane row, where the fork failed in felix's own shell); $LNTa6" \
   "$LNTa|$LNTb" "built|$LNTXW|fired|as C6 says"
_lnt_v3r3 kill tr "*' -d '*'[:space:]'*" "*' _lane_marker '*" "$LNTXC"
is "lane status row V3R3-F1-rows-before-the-lane-row-read-ungoverned L-NEVER-OK: (a) the same checkout, C9's kill probe at tr -d [:space:] with _lane_marker on the stack: $LNTa5 (or 137 with no lane row, where the kill reached felix itself); $LNTa6" \
   "$LNTa|$LNTb" "built|$LNTXW|fired|as C6 says"
LNTXR="not built: V3R3-F1's checkout with its .felix removed"
rm -f "$LNTXC/.felix"
[ "$LNTXA" = built ] && [ ! -e "$LNTXC/.felix" ] && [ ! -L "$LNTXC/.felix" ] \
  && [ "$( _fx_cd "$LNTXC" && _lf_g 1700000000 config --get remote.origin.url )" = https://github.com/o/r.git ] && LNTXR=built
_lnt_v3r3u "$LNTXC"; LNTa="$LNTXR|$LNTXU"
_lnt_v3r3 fork git "*' remote get-url origin '*" "*' _lane_origin '*" "$LNTXC"
is "lane status row V3R3-F1-rows-before-the-lane-row-read-ungoverned L-NEVER-OK: (a) the same checkout with its .felix removed, bound by remote_match alone, C9's fork probe at git remote get-url origin with _lane_origin on the stack, a read only the lane's check makes: $LNTa5 (or 128 with no lane row, where the fork failed in felix's own shell); $LNTa6" \
   "$LNTa|$LNTb" "built|$LNTXW|fired|as C6 says"
_lnt_v3r3 kill git "*' remote get-url origin '*" "*' _lane_origin '*" "$LNTXC"
is "lane status row V3R3-F1-rows-before-the-lane-row-read-ungoverned L-NEVER-OK: (a) the checkout bound by remote_match alone, C9's kill probe at git remote get-url origin with _lane_origin on the stack: $LNTa5 (or 137 with no lane row, where the kill reached felix itself); $LNTa6" \
   "$LNTa|$LNTb" "built|$LNTXW|fired|as C6 says"
_lnt_v3r3 fork sed '*remote_match*' "*' _lane_remote_match '*" "$LNTXC"
is "lane status row V3R3-F1-rows-before-the-lane-row-read-ungoverned L-NEVER-OK: (a) the checkout bound by remote_match alone, C9's fork probe at sed whose words hold remote_match with _lane_remote_match on the stack, a read only the lane's check makes: $LNTa5 (or 128 with no lane row, where the fork failed in felix's own shell); $LNTa6" \
   "$LNTa|$LNTb" "built|$LNTXW|fired|as C6 says"
_lnt_v3r3 kill sed '*remote_match*' "*' _lane_remote_match '*" "$LNTXC"
is "lane status row V3R3-F1-rows-before-the-lane-row-read-ungoverned L-NEVER-OK: (a) the checkout bound by remote_match alone, C9's kill probe at sed whose words hold remote_match with _lane_remote_match on the stack: $LNTa5 (or 137 with no lane row, where the kill reached felix itself); $LNTa6" \
   "$LNTa|$LNTb" "built|$LNTXW|fired|as C6 says"

LNTYA="not built: V3R3-F1's home of q and an LF, and its checkout"; LNTYH=""; LNTYC=""; LNTYb="not run"; LNTYq="not run"; LNTYk="not run"
if _lf_v3r3 "$LNTD/v3r3b" "$LNTN"; then
  LNTYA=built; LNTYH="$LF_V3RH"; LNTYC="$LF_V3RC"
  _lf_use "$LNTYH" "$LNTD/memory" "$LNTD/user" "$LNTB"
  _lf_run "$LNTD/v3r3b-0" "$LNTYC" "$LNTN" "$FELIX" status --tsv
  LNTYb="$LF_RC|$(_lnt_rows "$LNTD/v3r3b-0")|$(_lf_last "$LNTD/v3r3b-0.out")"
  _lf_v3r3q "$LNTYH" "$LNTYC"; LNTYA="$LNTYA|$LF_V3RQ"
  _lf_run "$LNTD/v3r3b-q" "$LNTYC" "$LNTN" "$FELIX" status --tsv
  LNTYq="$LF_RC|$(_lnt_rows "$LNTD/v3r3b-q")|$(LC_ALL=C awk -F'\t' '$1 == "reach"' "$LNTD/v3r3b-q.out")|$(_lf_last "$LNTD/v3r3b-q.out")"
  LC_ALL=C awk 'NR <= 9' "$LNTD/v3r3b-0.out" > "$LNTD/v3r3b-0.nine"; LC_ALL=C awk 'NR <= 9' "$LNTD/v3r3b-q.out" > "$LNTD/v3r3b-q.nine"
  LNTYk="$(_lnt_v3r3k "$LNTD/v3r3b-q.nine" "$LNTD/v3r3b-0.nine")"
  if [ -z "$LNTYk" ] && cmp -s "$LNTD/v3r3b-q.nine" "$LNTD/v3r3b-0.nine" && [ "$(_lf_count "$LNTD/v3r3b-0.nine")" = 9 ]; then LNTYk="nine identical"
  else LNTYk="first row unlike q's [$LNTYk]"; fi
fi
is "lane status row V3R3-F1-rows-before-the-lane-row-read-ungoverned L-NEVER-OK: (b) no fault, in a checkout with no .felix whose origin is named by the remote_match of the home's only project, a directory named q and an LF: felix status --tsv exits 0 with ten rows, rows 1 to 9 byte-identical to the rows the same engine prints for q in that home and checkout once a directory projects/q and a .felix naming q bind it, as origin/main's are (reach none - q declares no plugin or mcp rows, ...), and the tenth and last exactly lane unknown - the lane count did not finish in <repo> (the limit C2 states); with q bound, the reach row is that one and the lane row C6's none row for projects/q" \
   "$LNTYA|$LNTYb|$LNTYq|$LNTYk" \
   "built|built|0|$LNTTEN|$(_lf_tsv lane unknown - "the lane count did not finish in $LNTYC")|0|$LNTTEN|$(_lf_tsv reach none - 'q declares no plugin or mcp rows')|$(_lf_tsv lane none - "$LNTYH/projects/q/lanes.tsv has no committed row, so no lane is counted")|nine identical"
_lf_use "$LNTH" "$LNTD/memory" "$LNTD/user" "$LNTB"
# <<< lane-status-row
