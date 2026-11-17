# >>> lost-work-inventory-carried
printf '\nthe lost-work page, step 6: the shared fixture, and felix inventory carried (contract A1, B9.1-12, blind)\n'
# Blind, written from docs/2026-10-18-lost-work-page-contract.md alone on
# 2026-10-17, before lib/lost-work.sh and the A1-A3 inventory changes existed.
# No engine code was read for an expected value: engine/harness/felix was read
# only for how inventory, land and monitor are dispatched. The stubs,
# builders, runner and readers are in tests/lib/lost-work.sh (moved there for
# gate friction C); _lw_build makes the shared fixture. Each of parts 1450-1490
# builds its own repositories under $LW, and only 1480 reads another's (1470's
# pg, through _lw_pg_build).
_lw_build

# ---- A1: the carried fixture ----------------------------------------------------
# ca: main is two commits; done5 sits at the first. Each case below is commits
# no checkout holds, pushed to the names given; "X child of Y" means X's parent
# is Y. No PR anywhere except #7 (open, head carry2), #60 (open, head pr6),
# #90 (closed unmerged, head b9), #100 (open, head b10), #101 (open, head c10).
_lw_repo ca; CA="$LW/ca"
LWCA0="$(_lwq "$CA" refs/heads/main)"
printf 'second\n' > "$CA/second.txt"; _lwg "$CA" add -A >/dev/null 2>&1; _lwg "$CA" commit -qm 'the second ca' >/dev/null 2>&1
_lwg "$CA" push -q origin main >/dev/null 2>&1
LWCAM="$(_lwq "$CA" refs/heads/main)"
_lw_mk "$CA" "$LWCAM" one c1.txt one;            LW1X="$LWC"; _lw_mk "$CA" "$LW1X" 'carries one' c1b.txt 'one b'; LW1Y="$LWC"
_lw_mk "$CA" "$LWCAM" two c2.txt two;            LW2X="$LWC"; _lw_mk "$CA" "$LW2X" 'carries two' c2b.txt 'two b'; LW2Y="$LWC"
_lw_mk "$CA" "$LWCAM" three c3.txt three;        LW3X="$LWC"
_lw_mk "$CA" "$LWCAM" 'twin tip' c3t.txt twin;   LW3Z="$LWC"
_lw_mk "$CA" "$LWCAM" four c4.txt four;          LW4X="$LWC"; _lw_mk "$CA" "$LW4X" 'carries four' c4b.txt 'four b'; LW4Y="$LWC"
_lw_mk "$CA" "$LWCAM" six c6.txt six;            LW6X="$LWC"; _lw_mk "$CA" "$LW6X" 'carries six' c6b.txt 'six b'; LW6Y="$LWC"
_lw_mk "$CA" "$LWCAM" seven c7.txt seven;        LW7X="$LWC"; _lw_mk "$CA" "$LW7X" 'carries seven' c7b.txt 'seven b'; LW7Y="$LWC"
_lw_mk "$CA" "$LWCAM" eight c8.txt eight;        LW8X="$LWC"; _lw_mk "$CA" "$LW8X" mid c8m.txt mid; LW8Y="$LWC"
_lw_mk "$CA" "$LW8Y" outer c8o.txt outer;        LW8Z="$LWC"
_lw_mk "$CA" "$LWCAM" 'eight b' c8b.txt 'eight b'; LW8B="$LWC"
for _lwi in 1 2 3 4; do _lw_mk "$CA" "$LW8B" "q$_lwi" "q$_lwi.txt" "q$_lwi"; eval "LW8Q$_lwi=\$LWC"; done
_lw_mk "$CA" "$LWCAM" nine c9.txt nine;          LW9X="$LWC"; _lw_mk "$CA" "$LW9X" 'carries nine' c9b.txt 'nine b'; LW9Y="$LWC"
_lw_mk "$CA" "$LWCAM" ten c10.txt ten;           LW10X="$LWC"; _lw_mk "$CA" "$LW10X" 'carries ten' c10b.txt 'ten b'; LW10Y="$LWC"
_lw_mk "$CA" "$LWCAM" eleven c11.txt eleven;     LW11X="$LWC"; _lw_mk "$CA" "$LW11X" 'carries eleven' c11b.txt 'eleven b'; LW11Y="$LWC"
_lw_mk "$CA" "$LW11X" 'eleven, unpushed' c11u.txt 'eleven u'; LW11W="$LWC"
_lwg "$CA" push -q origin "$LW1Y:refs/heads/carry" "$LW2Y:refs/heads/carry2" "$LW3X:refs/heads/other3" \
  "$LW3Z:refs/heads/twin-a" "$LW3Z:refs/heads/twin-b" "$LW4X:refs/heads/x4" "$LW4Y:refs/heads/y4" "$LW6Y:refs/heads/pr6" \
  "$LW7Y:refs/heads/c7" "$LW8Y:refs/heads/mid8" "$LW8Z:refs/heads/outer8" "$LW8Q1:refs/heads/q1" "$LW8Q2:refs/heads/q2" \
  "$LW8Q3:refs/heads/q3" "$LW8Q4:refs/heads/q4" "$LW9X:refs/heads/b9" "$LW9Y:refs/heads/c9" "$LW10X:refs/heads/b10" \
  "$LW10Y:refs/heads/c10" "$LW11Y:refs/heads/c11" "$LW2X:refs/heads/feat2" >/dev/null 2>&1   # feat2 is pushed under its own name: see the note on B9.2
_lwg "$CA" fetch -q origin >/dev/null 2>&1
for _lwi in "feat1 $LW1X" "feat2 $LW2X" "alias3 $LW3X" "done5 $LWCA0" "b8 $LW8X" "b8b $LW8B" "b9 $LW9X" "b10 $LW10X" "b11 $LW11W"; do
  _lwg "$CA" branch -q ${_lwi% *} ${_lwi#* } >/dev/null 2>&1
done
_lwg "$CA" branch -q --set-upstream-to=origin/b9 b9 >/dev/null 2>&1
_lwg "$CA" branch -q --set-upstream-to=origin/b10 b10 >/dev/null 2>&1
_lwg "$CA" worktree add -q --detach "$LW/ca-wt6" "$LW6X" >/dev/null 2>&1
_lwg "$CA" worktree add -q -b wt7 "$LW/ca-wt7" "$LW7X" >/dev/null 2>&1
printf 'not yet committed\n' > "$LW/ca-wt7/wip.txt"
_lw_prs fixture_ca "$(_lw_pr 7 carry2 "$LW2Y" green notes/7.md repo=fixture/ca)" "$(_lw_pr 60 pr6 "$LW6Y" green notes/60.md repo=fixture/ca)" \
  "$(_lw_pr 90 b9 "$LW9X" green notes/90.md state=CLOSED repo=fixture/ca)" "$(_lw_pr 100 b10 "$LW10X" green notes/100.md repo=fixture/ca)" \
  "$(_lw_pr 101 c10 "$LW10Y" green notes/101.md repo=fixture/ca)"
_lwo=""
for _lwi in "$LW1X:$LW1Y" "$LW2X:$LW2Y" "$LW4X:$LW4Y" "$LW6X:$LW6Y" "$LW7X:$LW7Y" "$LW8X:$LW8Y" "$LW8Y:$LW8Z" "$LW8B:$LW8Q4" \
             "$LW9X:$LW9Y" "$LW10X:$LW10Y" "$LW11X:$LW11Y" "$LW11X:$LW11W" "$LWCA0:$LWCAM"; do
  _lwo="$_lwo$(_lw_anc "$CA" "${_lwi%:*}" "${_lwi#*:}")"
done
_lwo="$_lwo$(_lw_anc "$CA" "$LW11W" "$LW11Y")$(_lw_anc "$CA" "$LW1X" refs/remotes/origin/main)"
is "A1 fixture: each carried tip is a proper ancestor of its carrier, the unpushed tip of none, and no case tip is on main (fixture control)" "$_lwo" "yyyyyyyyyyyyynn"
is "A1 fixture: origin holds every pushed name at its commit, and origin/HEAD is main (fixture control)" \
   "$(_lwq "$CA" refs/remotes/origin/carry)|$(_lwq "$CA" refs/remotes/origin/q4)|$(_lwg "$CA" symbolic-ref -q refs/remotes/origin/HEAD 2>/dev/null)" \
   "$LW1Y|$LW8Q4|refs/remotes/origin/main"
is "A1 fixture: b9 and b10 track their own names, and wt7 holds one untracked file (fixture control)" \
   "$(_lwg "$CA" rev-parse --abbrev-ref b9@{upstream} 2>/dev/null) $(_lwg "$CA" rev-parse --abbrev-ref b10@{upstream} 2>/dev/null) $(_lwg "$LW/ca-wt7" status --porcelain 2>/dev/null)" \
   "origin/b9 origin/b10 ?? wip.txt"

_lw_run CA1 "$LW/hA" "$LW/cwd" inventory --repo "$CA" --tsv
_lw_run CA2 "$LW/hA" "$LW/cwd" inventory --repo "$CA" --tsv --no-gh
is "A1: both inventory runs over ca exit 0 and print rows (control)" "$(_lw_rc CA1)$(_lw_rc CA2) $([ -s "$(_lw_o CA1)" ] && [ -s "$(_lw_o CA2)" ] && echo rows)" "00 rows"
T1="$(_lw_o CA1)"; T2="$(_lw_o CA2)"
# B9.1
is "B9.1: a branch whose tip a pushed branch strictly descends from, no PR anywhere, is carried and not unproposed" \
   "$(_lw_many "$T1" branch feat1 0 carried unproposed unknown:unproposed)" "carried=yes unproposed=no unknown:unproposed=no"
is "B9.1: its detail holds the element carried by origin/carry" "$(_lw_elem "$T1" branch feat1 'carried by origin/carry')" yes
is "B9.1: the carrier's own row, the remote origin/carry, stays unproposed and is not carried (control)" \
   "$(_lw_many "$T1" remote origin/carry 0 unproposed carried)" "unproposed=yes carried=no"
# B9.2. The review round (finding 3) pushed feat2 as origin/feat2 at its tip. Contract A1 says --no-gh
# "keeps unknown:pr-open as 5.1 says", and the inventory spec gives a branch never pushed under its own
# name no unknown:pr-* under --no-gh (it heads no PR), so only a branch with an origin ref of its own can
# keep the entry. feat2 is carried all the same, by origin/carry2, which strictly descends from it.
is "B9.2: with an open same-repository PR #7 headed carry2, the branch it holds is carried, not unproposed" \
   "$(_lw_many "$T1" branch feat2 0 carried unproposed pr-open)" "carried=yes unproposed=no pr-open=no"
is "B9.2: and its detail names the carrier as #7" "$(_lw_elem "$T1" branch feat2 'carried by #7')" yes
is "B9.2: under --no-gh it is still carried and keeps unknown:pr-open" "$(_lw_many "$T2" branch feat2 0 carried unknown:pr-open)" "carried=yes unknown:pr-open=yes"
is "B9.2: and under --no-gh the carrier is written origin/carry2" "$(_lw_elem "$T2" branch feat2 'carried by origin/carry2')" yes
# B9.3
is "B9.3: a local branch whose tip equals origin/other3's (another name, no upstream) is carried by it" \
   "$(_lw_holds "$T1" branch alias3 carried) $(_lw_elem "$T1" branch alias3 'carried by origin/other3')" "yes yes"
is "B9.3: two remote rows at one commit carry neither each other: both unproposed, neither carried (control)" \
   "$(_lw_many "$T1" remote origin/twin-a 0 carried unproposed) $(_lw_many "$T1" remote origin/twin-b 0 carried unproposed)" \
   "carried=no unproposed=yes carried=no unproposed=yes"
# B9.4
is "B9.4: a remote row origin/x4 that origin/y4 strictly descends from is carried, and the detail names origin/y4" \
   "$(_lw_many "$T1" remote origin/x4 0 carried unproposed) $(_lw_elem "$T1" remote origin/x4 'carried by origin/y4')" "carried=yes unproposed=no yes"
# B9.5
is "B9.5: a branch whose tip origin/main reaches is landed, never carried, though every carrier descends from it (control)" \
   "$(_lw_many "$T1" branch done5 0 landed carried)" "landed=yes carried=no"
# B9.6
is "B9.6: a detached worktree whose HEAD an open PR's head descends from is carried, by #60" \
   "$(_lw_holds "$T1" worktree "$LW/ca-wt6" carried) $(_lw_elem "$T1" worktree "$LW/ca-wt6" 'carried by #60')" "yes yes"
is "B9.6: under --no-gh the same worktree reads carried by origin/pr6 (A1 detail)" "$(_lw_elem "$T2" worktree "$LW/ca-wt6" 'carried by origin/pr6')" yes
# B9.7, B9.12
is "B9.7: a worktree with an uncommitted change on a carried tip reads uncommitted,carried" "$(_lw_st "$T1" worktree "$LW/ca-wt7")" "uncommitted,carried"
_lwo="$(_lw_order "$T1")"
is "B9.12: carried sits between pr-closed-unlanded and orphan: no row breaks the state order, and some row holds carried" \
   "${_lwo%|*} $([ "${_lwo#*|}" -gt 0 ] 2>/dev/null && echo carried || echo 'no carried row')" "0 carried"
# B9.8
is "B9.8: of two carriers, origin/outer8 descending from origin/mid8, only origin/outer8 is named" \
   "$(_lw_elem "$T1" branch b8 'carried by origin/outer8')" yes
is "B9.8: of four outermost carriers, three are named by name and the fourth counted" \
   "$(_lw_elem "$T1" branch b8b 'carried by origin/q1, origin/q2, origin/q3, and 1 more')" yes
# B9.9
is "B9.9: a branch whose newest PR was closed unmerged, and whose tip a carrier reaches, is carried and not pr-closed-unlanded" \
   "$(_lw_many "$T1" branch b9 0 carried pr-closed-unlanded unknown:pr-closed-unlanded)" "carried=yes pr-closed-unlanded=no unknown:pr-closed-unlanded=no"
# B9.10
is "B9.10: a branch with its own open PR, inside another PR's head, is pr-open and not carried (control)" \
   "$(_lw_many "$T1" branch b10 0 pr-open carried)" "pr-open=yes carried=no"
# B9.11
is "B9.11: a branch with one unpushed commit on a carried base is unpushed and not carried (control)" \
   "$(_lw_many "$T1" branch b11 0 unpushed carried)" "unpushed=yes carried=no"
# <<< lost-work-inventory-carried
