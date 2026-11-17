# >>> lost-work-review-fixes
printf '\nthe lost-work page, step 6: the review round (findings 1, 2, 5 and 6 of audits/2026-10-18-lost-work-page/review.md)\n'
# Written after part 1450-1480 and the Opus review, one assertion set for each
# finding, red against the code the review read (30264fa6) and green against
# the fix. It uses the stubs, builders and readers in tests/lib/lost-work.sh,
# which were part 1450's. Finding 3 is part 1450's own fixture (feat2 is
# pushed under its own name there now) and finding 4 has no assertion: it is
# reachable only through a land die message holding a backslash.
#
#   xb  one open PR (#11, head pb), one pending handoff section: finding 1.
#   xc  feat-a and feat-b, two pushed names at one commit, each with a local
#       branch that tracks it, and feat-c, a local name never pushed at that
#       commit; u, whose own name origin/u is older than its upstream origin/w
#       at its tip: findings 2 and 6.
_lw_build
_lw44_sum() { LC_ALL=C awk -F'\t' -v g="$2" -v k="$3" '$2 == "summary" && $1 == g { print $k; exit }' "$1" 2>/dev/null; }
_lw44_cell() {  # TEXT-PAGE NAME: the count the collapsed line says for NAME
  LC_ALL=C awk -v w="$2" '/^  collapsed: / { s = $0; i = index(s, w " "); if (i) { s = substr(s, i + length(w) + 1); sub(/,.*/, "", s); print s } exit }' "$1" 2>/dev/null; }
_lw44_has() {  # TEXT ELEMENT-PREFIX: whether a "; "-joined cell holds an element that begins so
  printf '%s\n' "$1" | LC_ALL=C awk -v w="$2" '{ n = split($0, e, "; "); for (i = 1; i <= n; i++) if (index(e[i], w) == 1) f = 1 } END { print (f ? "yes" : "no") }'; }

LW44H="$LW/h44"; mkdir -p "$LW44H/.claude/projects"   # this part's own HOME, so it needs no other part's
_lw_repo xb; XB="$LW/xb"
mkdir -p "$XB/docs/handoff/pending"
printf '### 2026-10-17 - a waiting section\n\nWhat was done.\n\n**Next:**\n- Do the next thing.\n' > "$XB/docs/handoff/pending/20261017T101010Z-lw44-handoff.md"
_lwg "$XB" add -A >/dev/null 2>&1; _lwg "$XB" commit -qm 'a pending handoff section' >/dev/null 2>&1
_lwg "$XB" push -q origin main >/dev/null 2>&1
_lw_mk "$XB" "$(_lwq "$XB" refs/heads/main)" 'the work' b11.txt b11; LW44B="$LWC"
_lwg "$XB" push -q origin "$LW44B:refs/heads/pb" >/dev/null 2>&1; _lwg "$XB" fetch -q origin >/dev/null 2>&1
LW44PR="$(_lw_pr 11 pb "$LW44B" green notes/11.md repo=fixture/xb)"
_lw_prs fixture_xb "$LW44PR"
# A git that fails the one listing of the pending directory, ahead of the real one on PATH.
LW44S="$LW/shim"; mkdir -p "$LW44S"
printf '#!/bin/bash\nfor a in "$@"; do [ "$a" != docs/handoff/pending/ ] || exit 128; done\nexec "%s" "$@"\n' "$(command -v git)" > "$LW44S/git"
chmod +x "$LW44S/git"

# ---- finding 1: proposed and handoff say a complete 0 when their source was not read --------
_lw_run X1G "$LW44H" "$LW/cwd" monitor --tsv --repo "$XB" --no-host
_lw_run X1N "$LW44H" "$LW/cwd" monitor --tsv --repo "$XB" --no-host --no-gh
_lw_run X1NX "$LW44H" "$LW/cwd" monitor --repo "$XB" --no-host --no-gh
_lw_ghfail fixture_xb 'HTTP 502: Bad Gateway (https://api.github.com/graphql)'
_lw_run X1F "$LW44H" "$LW/cwd" monitor --tsv --repo "$XB" --no-host
_lw_run X1FX "$LW44H" "$LW/cwd" monitor --repo "$XB" --no-host
_lw_prs fixture_xb "$LW44PR"
_lw44_path="$PATH"; PATH="$LW44S:$PATH"
_lw_run X1H "$LW44H" "$LW/cwd" monitor --tsv --repo "$XB" --no-host
_lw_run X1HX "$LW44H" "$LW/cwd" monitor --repo "$XB" --no-host
_lw_run X1I "$LW44H" "$LW/cwd" inventory --tsv --repo "$XB" --no-host
PATH="$_lw44_path"
_lw_run X1R "$LW44H" "$LW/cwd" inventory --tsv --repo "$XB" --no-host
is "finding 1: the five runs over xb exit 0 and the TSV runs hold 17 summaries (control)" \
   "$(_lw_rc X1G)$(_lw_rc X1N)$(_lw_rc X1NX)$(_lw_rc X1F)$(_lw_rc X1FX)$(_lw_rc X1H)$(_lw_rc X1HX) $(for _lwk in X1G X1N X1F X1H; do LC_ALL=C awk -F'\t' '$2 == "summary" { n++ } END { printf "%d ", n + 0 }' "$(_lw_o $_lwk)"; done)" \
   "0000000 17 17 17 17 "
# finding 1 (control): with gh read the proposed group is complete and says its rows; the pending section is one handoff row.
is "finding 1: with gh read, proposed is complete and the pending section is one complete handoff row (control)" \
   "$(_lw44_sum "$(_lw_o X1G)" proposed 5) $(_lw44_sum "$(_lw_o X1G)" handoff 5):$(_lw44_sum "$(_lw_o X1G)" handoff 8)" "complete complete:1"
# finding 1: --no-gh leaves the prs cover row unknown, so no pr-open row could be listed.
is "finding 1: under --no-gh proposed is incomplete and its content unknown, not 0" \
   "$(_lw44_sum "$(_lw_o X1N)" proposed 5):$(_lw44_sum "$(_lw_o X1N)" proposed 8)" "incomplete:unknown"
is "finding 1: and its reason names the prs cover row" "$(_lw44_has "$(_lw44_sum "$(_lw_o X1N)" proposed 9)" 'prs unknown')" yes
is "finding 1: the text page says proposed unknown under --no-gh, never proposed 0" "$(_lw44_cell "$(_lw_o X1NX)" proposed)" unknown
# finding 1: gh failing leaves the prs cover row unknown as well.
is "finding 1: with gh failing proposed is incomplete and unknown" \
   "$(_lw44_sum "$(_lw_o X1F)" proposed 5):$(_lw44_sum "$(_lw_o X1F)" proposed 8)" "incomplete:unknown"
is "finding 1: and the text page says proposed unknown" "$(_lw44_cell "$(_lw_o X1FX)" proposed)" unknown
# finding 1: a pending listing that fails is said in the default cover row's states, and handoff reads unknown.
is "finding 1: with the pending listing failed the default cover row keeps read and adds unknown:handoff-pending (the control reads read alone)" \
   "$(_lw_col "$(_lw_o X1R)" cover default 4) $(_lw_col "$(_lw_o X1I)" cover default 4)" "read read,unknown:handoff-pending"
is "finding 1: so handoff is incomplete with no rows and says unknown, naming the default cover row" \
   "$(_lw44_sum "$(_lw_o X1H)" handoff 5):$(_lw44_sum "$(_lw_o X1H)" handoff 8) $(_lw44_has "$(_lw44_sum "$(_lw_o X1H)" handoff 9)" 'default ')" "incomplete:unknown yes"
is "finding 1: the text page says handoff sections unknown, never handoff sections 0" "$(_lw44_cell "$(_lw_o X1HX)" 'handoff sections')" unknown
is "finding 1: and the failed listing does not make never-proposed incomplete for the default facet, which was read (control)" \
   "$(_lw44_has "$(_lw44_sum "$(_lw_o X1H)" never-proposed 9)" 'default ')" no

_lw_repo xc; XC="$LW/xc"
_lw_mk "$XC" "$(_lwq "$XC" refs/heads/main)" 'shared work' xc1.txt xc1; LW44X="$LWC"
_lw_mk "$XC" "$(_lwq "$XC" refs/heads/main)" 'u, older' xc2.txt xc2; LW44P="$LWC"
_lw_mk "$XC" "$LW44P" 'u, tip' xc3.txt xc3; LW44T="$LWC"
_lwg "$XC" push -q origin "$LW44X:refs/heads/feat-a" "$LW44X:refs/heads/feat-b" "$LW44P:refs/heads/u" "$LW44T:refs/heads/w" >/dev/null 2>&1
_lwg "$XC" fetch -q origin >/dev/null 2>&1
for _lwi in feat-a feat-b; do
  _lwg "$XC" branch -q "$_lwi" "$LW44X" >/dev/null 2>&1; _lwg "$XC" branch -q --set-upstream-to="origin/$_lwi" "$_lwi" >/dev/null 2>&1
done
_lwg "$XC" branch -q feat-c "$LW44X" >/dev/null 2>&1
_lwg "$XC" branch -q u "$LW44T" >/dev/null 2>&1; _lwg "$XC" branch -q --set-upstream-to=origin/w u >/dev/null 2>&1
_lw_prs fixture_xc
is "finding 2 fixture: feat-a, feat-b and feat-c sit at one commit, origin holds the first two there, u tracks origin/w at its tip while origin/u is its parent (fixture control)" \
   "$(_lwq "$XC" refs/heads/feat-a | cut -c1-8) $(_lwq "$XC" refs/remotes/origin/feat-a)$(_lwq "$XC" refs/remotes/origin/feat-b)$(_lwq "$XC" refs/heads/feat-c)|$(_lwg "$XC" rev-parse --abbrev-ref u@{upstream} 2>/dev/null) $(_lw_anc "$XC" "$LW44P" "$LW44T")$(_lwq "$XC" refs/remotes/origin/u)$(_lwq "$XC" refs/remotes/origin/w)" \
   "$(printf '%s' "$LW44X" | cut -c1-8) $LW44X$LW44X$LW44X|origin/w y$LW44P$LW44T"
_lw_run X2 "$LW44H" "$LW/cwd" inventory --tsv --repo "$XC" --no-host
_lw_run X2N "$LW44H" "$LW/cwd" inventory --tsv --repo "$XC" --no-host --no-gh
_lw_run X2P "$LW44H" "$LW/cwd" monitor --tsv --repo "$XC" --no-host
is "finding 2: the runs over xc exit 0 (control)" "$(_lw_rc X2)$(_lw_rc X2N)$(_lw_rc X2P)" 000
# finding 2: two pushed names at one commit, each with a local branch, do not carry each other.
is "finding 2: feat-a, with its own name pushed at its tip and only feat-b's name at the same commit, is unproposed and not carried" \
   "$(_lw_many "$(_lw_o X2)" branch feat-a 0 unproposed carried)" "unproposed=yes carried=no"
is "finding 2: and so is feat-b" "$(_lw_many "$(_lw_o X2)" branch feat-b 0 unproposed carried)" "unproposed=yes carried=no"
is "finding 2: the page lists both under work that never reached a PR" \
   "$(_lw_col "$(_lw_o X2P)" branch feat-a 0 1) $(_lw_col "$(_lw_o X2P)" branch feat-b 0 1)" "never-proposed never-proposed"
# finding 2 (control): a local name never pushed at that commit is carried by a pushed name there, as B9.3 has it.
is "finding 2: feat-c, never pushed under its own name, is carried by an equal tip and not unproposed (control)" \
   "$(_lw_many "$(_lw_o X2)" branch feat-c 0 carried unproposed)" "carried=yes unproposed=no"
# finding 3: the clause the review would not let the one-liner break. A never-pushed branch heads no PR (section 5.1), so --no-gh gives it no unknown:pr-open.
is "finding 3: under --no-gh a never-pushed branch is still carried and gains no unknown:pr-open (inventory spec 5.1)" \
   "$(_lw_many "$(_lw_o X2N)" branch feat-c 0 carried unknown:pr-open)" "carried=yes unknown:pr-open=no"
# finding 6: a branch's upstream is not its carrier whichever of the two names, its own or its upstream's, is the one pushed at its tip.
is "finding 6: u, whose upstream origin/w holds its tip while origin/u is older, is not carried by its own upstream" \
   "$(_lw_many "$(_lw_o X2)" branch u 0 carried) $(_lw_elem "$(_lw_o X2)" branch u 'carried by origin/w')" "carried=no no"

# ---- finding 5: GIT_DIR in the caller's environment ----------------------------------------------
_lw44_gd() {  # NAME GITDIR ARGS...: part 1450's _lw_run with GIT_DIR set after the variables it unsets
  local n="$1" gd="$2"; shift 2
  ( cd "$LW/cwd" || exit 97
    exec env -u FELIX_ALLOW_RED -u FELIX_KERNEL -u FELIX_KERNEL_CACHE -u CLAUDE_CODE_SESSION_ID -u CLAUDE_CONFIG_DIR \
      -u CLAUDE_PLUGIN_ROOT -u GIT_DIR -u GIT_WORK_TREE -u GIT_INDEX_FILE -u GIT_COMMON_DIR -u GIT_OBJECT_DIRECTORY -u GIT_OPTIONAL_LOCKS \
      HOME="$LW44H" FELIX_HOME="$LW_FH" FELIX_HOME_DIR="$LW_FH" FELIX_MEMORY="$LWM" FELIX_PLUGIN_CACHE="$LW/cache" \
      FELIX_INVENTORY_TEMP_ROOTS="$LW/temproot" XDG_CONFIG_HOME="$LW44H/.config" XDG_STATE_HOME="$LW44H/.state" XDG_CACHE_HOME="$LW44H/.cache" \
      GH_CONFIG_DIR="$LW44H/.config/gh" GIT_CONFIG_NOSYSTEM=1 GIT_TERMINAL_PROMPT=0 GIT_CEILING_DIRECTORIES="$LW" \
      TMPDIR="$LWT" PATH="$LWB:$PATH" GIT_DIR="$gd" GIT_WORK_TREE="$LW/xb" "$FELIX" "$@" ) > "$LWX/$n.out" 2> "$LWX/$n.err"
  printf '%s\n' "$?" > "$LWX/$n.rc"
}
_lw44_gd X5 "$XB/.git" monitor --tsv --repo "$XB" --no-host
is "finding 5: with GIT_DIR and GIT_WORK_TREE set the page still exits 0 and prints its 17 summaries" \
   "$(_lw_rc X5) $(LC_ALL=C awk -F'\t' '$2 == "summary" { n++ } END { print n + 0 }' "$(_lw_o X5)")" "0 17"
is "finding 5: and says nothing on stderr" "$(cat "$LWX/X5.err")" ""
# <<< lost-work-review-fixes
