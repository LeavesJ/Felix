# ---- the runs ------------------------------------------------------------
_iv_build
# The help may go to either stream; _ivrun keeps stderr in $IV_ERR, empty
# until now.
case "$(_ivrun)$(cat "$IV_ERR")" in
  *"felix inventory"*) ok  "felix with no arguments lists felix inventory in the grouped help" ;;
  *)                   bad "felix with no arguments lists felix inventory in the grouped help" "no felix inventory line in the help" ;;
esac
: > "$IV_ERR"

_iv_build live
_iv_snap() {
  local d
  for d in "$IVW" "$IVW2" "$IVO" "$IVO2" "$IVH"; do
    ( cd "$d" && find . -print | LC_ALL=C sort && find . -type f -exec "$_iv_sum" {} + | LC_ALL=C sort ) 2>&1
  done
  _ivg -C "$IVM" count-objects -v; _ivg -C "$IVG" count-objects -v
}
_iv_before="$(_iv_snap)"
: > "$IV/marker"


# ---- --tsv ---------------------------------------------------------------
# Every run that reads items names the repository with --repo, from inside
# it, so a fault in finding the repository one stands in fails the two
# assertions about that below and not every item's.
IV_T1="$IV/t1.tsv"; _ivrun inventory --tsv --repo "$IVM" > "$IV_T1"; IV_RC1=$?
IV_D1="rc=$IV_RC1; stdout: $(head -c 300 "$IV_T1" | tr '\t\n' '|;'); stderr: $(tail -c 300 "$IV_ERR" | tr '\n' ' ')"
is  "felix inventory --tsv exits 0 over a repository it can read" "$IV_RC1" "0"
_ivx="$(_iv_fields "$IV_T1")"
if [ -s "$IV_T1" ] && [ -z "$_ivx" ]; then ok "every --tsv row has eight tab-separated fields, and there are rows"
else bad "every --tsv row has eight tab-separated fields, and there are rows" "${_ivx:-no rows; $IV_D1}"; fi
_ivx="$(_iv_blank "$IV_T1")"
if [ -s "$IV_T1" ] && [ -z "$_ivx" ]; then ok "every row fills its kind, repo, ref and states"
else bad "every row fills its kind, repo, ref and states" "${_ivx:-no rows}"; fi
_ivx="$(_iv_repos "$IV_T1")"
case "$_ivx" in
  *widget*) [ "$(printf '%s\n' "$_ivx" | wc -l | tr -d ' ')" = 1 ] && ok "every row names the one repository it was run in" \
            || bad "every row names the one repository it was run in" "repos: $(printf '%s' "$_ivx" | tr '\n' ';')" ;;
  *) bad "every row names the one repository it was run in" "repos: [$(printf '%s' "$_ivx" | tr '\n' ';')]" ;;
esac
_ivx="$(_iv_order "$IV_T1")"
if [ -s "$IV_T1" ] && [ -z "$_ivx" ]; then ok "every row prints its states in the spec's table order, so the first is its headline"
else bad "every row prints its states in the spec's table order, so the first is its headline" "${_ivx:-no rows}"; fi
_ivx="$(_iv_landx "$IV_T1")"
if [ -s "$IV_T1" ] && [ -z "$_ivx" ]; then ok "no row is landed together with any state but live"
else bad "no row is landed together with any state but live" "${_ivx:-no rows}"; fi
_ivx="$(_iv_named "$IV_T1" $IV_WTS orphan-edit orphan-clean topic/superseded topic/partly topic/precedes topic/dup-one topic/dup-two topic/remote-only 4103 4104 4105 4106 4109)"
[ -s "$IV_T1" ] && [ -z "$_ivx" ] && ok "every worktree, orphan, unchecked-out branch, remote-only branch and open pull request in the fixture has a row naming it" \
  || bad "every worktree, orphan, unchecked-out branch, remote-only branch and open pull request in the fixture has a row naming it" "unnamed:${_ivx:- all, no rows}"
# The runs compared with another below give the same states only while every
# age in the fixture stays on one side of each threshold. The tool call written
# 3 minutes old crosses --blocked's default of 20 after 17 minutes, and on
# 2026-10-15 a machine under load took longer than that between here and the
# bash 3.2 run: three FAILs in a gate, none about inventory. So each compared
# run, and the baseline it is compared with, passes thresholds no suite run
# outlasts. The default thresholds stay asserted on IV_T1, read once at the start.
IV_CMP=(--live 999999 --blocked 999999)
IV_T1C="$IV/t1c.tsv"; _ivrun inventory --tsv --repo "$IVM" "${IV_CMP[@]}" > "$IV_T1C"
# Standing in the repository, in the main clone or in a linked worktree of it,
# reads the same repository.
IV_T0="$IV/t0.tsv"; _ivrun inventory --tsv "${IV_CMP[@]}" > "$IV_T0"; IV_RC0=$?
[ "$IV_RC0" -eq 0 ] && [ -s "$IV_T1C" ] && [ "$(_iv_kinds "$IV_T0")" = "$(_iv_kinds "$IV_T1C")" ] \
  && ok "standing in the main clone with no --repo gives the items and states --repo naming it gives" \
  || bad "standing in the main clone with no --repo gives the items and states --repo naming it gives" \
         "rc=$IV_RC0; $(_ivnr "$IV_T0") rows standing in, $(_ivnr "$IV_T1C") with --repo"
IV_T0W="$IV/t0w.tsv"; _ivrun --cwd "$IVW/wt-squash" inventory --tsv "${IV_CMP[@]}" > "$IV_T0W"; IV_RC0W=$?
[ "$IV_RC0W" -eq 0 ] && [ -s "$IV_T1C" ] && [ "$(_iv_kinds "$IV_T0W")" = "$(_iv_kinds "$IV_T1C")" ] \
  && ok "and standing in a linked worktree reads the same repository" \
  || bad "and standing in a linked worktree reads the same repository" \
         "rc=$IV_RC0W; $(_ivnr "$IV_T0W") rows standing in, $(_ivnr "$IV_T1C") with --repo"
if [ "$IV_JQ" != 1 ]; then skip "felix inventory consults gh when gh is on PATH" "no jq for the gh stand-in"
elif [ -s "$IVGH_LOG" ]; then ok "felix inventory consults gh when gh is on PATH"
else bad "felix inventory consults gh when gh is on PATH" "the stand-in logged no call"; fi

# Worktrees, one state each.
_iv_sel "$IV_T1" wt-squash
_ivgh is "a clean worktree on a squash-merged branch, its pull request's head at the tip, is landed and nothing else" "$(_iv_states)" "landed"
_iv_chk "a worktree with a staged edit and an untracked file whose contents main lacks leads with uncommitted" "$IV_T1" wt-dirty lead uncommitted
_iv_chk "and a staged edit that no earlier tip holds is no staged revert" "$IV_T1" wt-dirty lack hazard:staged-revert
_iv_sel "$IV_T1" wt-same
is  "a worktree whose changed files hold main's content, whose deleted file main lacks too, and whose other file is ignored, is landed and nothing else" "$(_iv_states)" "landed"
_iv_chk "a branch with a commit on no remote leads with unpushed" "$IV_T1" wt-unpushed lead unpushed
_ivgh _iv_chk "and it is not unproposed, since it is on no remote" "$IV_T1" wt-unpushed lack unproposed
_ivgh _iv_chk "a pushed branch with no pull request, its content not on main, leads with unproposed" "$IV_T1" wt-unproposed lead unproposed
_iv_chk "and it is not unpushed" "$IV_T1" wt-unproposed lack unpushed
_ivgh _iv_chk "a remote branch with no pull request and no local copy is unproposed" "$IV_T1" topic/remote-only hold unproposed
_iv_chk "a local branch changing two paths, one of which main holds, is unpushed" "$IV_T1" topic/partly hold unpushed
_iv_chk "and its content column says partly" "$IV_T1" topic/partly word 7:partly
_ivgh _iv_chk "a local branch whose tip precedes a merged pull request's head is landed, though main's squash of it was edited" "$IV_T1" topic/precedes lead landed
_ivgh _iv_chk "a branch whose pull request was closed but whose content main holds is landed" "$IV_T1" topic/superseded lead landed
_ivgh _iv_chk "a worktree whose pull request was closed unmerged, its content not on main, leads with pr-closed-unlanded" "$IV_T1" wt-closed lead pr-closed-unlanded
_ivgh _iv_chk "and it is not unproposed, since a closed pull request has it as head" "$IV_T1" wt-closed lack unproposed
_iv_sel "$IV_T1" wt-share
if [ "$(_ivnr "$IV/sel")" = 2 ] && _iv_q lead hazard:shared-branch; then
  ok  "both worktrees holding one branch lead with hazard:shared-branch"
else bad "both worktrees holding one branch lead with hazard:shared-branch" "$(_iv_diag)"; fi
_iv_chk "a worktree whose index holds its branch's earlier tip, after the branch moved on from another checkout, leads with hazard:staged-revert" "$IV_T1" wt-revert lead hazard:staged-revert
_iv_chk "a directory beside the worktrees that git no longer lists is an orphan" "$IV_T1" orphan-edit lead orphan
_iv_chk "and its detail counts the 2 files whose content is in no object, and not its .git link" "$IV_T1" orphan-edit dnum 2:2
# None is the number 0, or a detail with no number at all that says no or
# none; "1 file in no object" is one, not none.
_iv_none() { LC_ALL=C awk -F'\t' '{ n++; d = tolower($8)
    if (d ~ /(^|[^0-9.])0([^0-9.]|$)/) g = 1
    else if (d !~ /[0-9]/ && d ~ /(^|[^a-z])(no|none)([^a-z]|$)/) g = 1 }
  END { exit (n && g) ? 0 : 1 }' "$IV/sel"; }
_iv_sel "$IV_T1" orphan-clean
if _iv_q lead orphan && _iv_none; then
  ok  "an orphan whose every file is in an object counts none"
else bad "an orphan whose every file is in an object counts none" "$(_iv_diag)"; fi
_iv_chk "two unpushed branches making the same change are each marked possible-duplicate: the first" "$IV_T1" topic/dup-one word 0:possible-duplicate
_iv_chk "two unpushed branches making the same change are each marked possible-duplicate: the second" "$IV_T1" topic/dup-two word 0:possible-duplicate
_iv_chk "a clean worktree that changed nothing is no possible-duplicate of the others that changed nothing" "$IV_T1" wt-query noword 0:possible-duplicate

# Pull requests.
_ivx=""
for _ivn in 4103 4104 4105 4106 4109; do _iv_sel "$IV_T1" "$_ivn"; _iv_q hold pr-open || _ivx="$_ivx $_ivn"; done
if [ "$IV_JQ" != 1 ]; then skip "each of the five open pull requests has a row that is pr-open" "no jq for the gh stand-in"
elif [ -z "$_ivx" ]; then ok "each of the five open pull requests has a row that is pr-open"
else bad "each of the five open pull requests has a row that is pr-open" "not pr-open:$_ivx"; fi
_ivgh _iv_chk "the pull request labelled felix:hold says hold in its detail" "$IV_T1" 4103 word 8:hold
_ivgh _iv_chk "and not ready, though felix/ready sits on its head's parent" "$IV_T1" 4103 noword 8:ready
_ivgh _iv_chk "the pull request with felix/ready on its head says ready" "$IV_T1" 4104 word 8:ready
_ivgh _iv_chk "and its label felix:founder says founder" "$IV_T1" 4104 word 8:founder
_ivgh _iv_chk "and it does not say hold" "$IV_T1" 4104 noword 8:hold
_ivgh _iv_chk "the label needs-founder says founder too" "$IV_T1" 4106 word 8:founder
_ivgh _iv_chk "the pull request GitHub calls conflicting says conflicting" "$IV_T1" 4105 word 8:conflicting
_iv_sel "$IV_T1" 4105
if [ "$IV_JQ" = 1 ]; then
  if _iv_q noword 8:ready && _iv_q noword 8:hold && _iv_q noword 8:founder; then ok "and it says none of ready, hold or founder"
  else bad "and it says none of ready, hold or founder" "$(_iv_diag)"; fi
else skip "and it says none of ready, hold or founder" "no jq for the gh stand-in"; fi
_ivgh _iv_chk "the pull request last updated 30 hours ago carries 29 to 31 hours, in age_h or its detail" "$IV_T1" 4103 num 29:31
_ivgh _iv_chk "and the one updated 2 hours ago carries 1 to 3, its own age" "$IV_T1" 4104 num 1:3

# What only the host's session records say.
_iv_chk "a worktree whose newest session was written 3 minutes ago leads with live" "$IV_T1" wt-live lead live
_iv_chk "and it is landed too, live being the one state landed allows" "$IV_T1" wt-live hold landed
_iv_chk "and its tool call with no result, 3 minutes old, is not yet blocked" "$IV_T1" wt-live lack blocked
_iv_chk "a worktree whose newest session ended on a question with nothing human after leads with question" "$IV_T1" wt-query lead question
_iv_chk "a question answered by a later human message is no question, and an older session's question is not the newest's" "$IV_T1" wt-answered lack question
# Decision D2 of 2026-09-24: a file under a session's subagents/ directory
# counts toward live (this assertion said it did not), and is still read for
# no question, which the one above holds.
_iv_chk "a fresh subagent transcript under the newest session makes its worktree live, though it ends on a question (D2)" "$IV_T1" wt-answered hold live
_iv_chk "a question ending in ?** and followed only by a system envelope still leads with question" "$IV_T1" wt-bold lead question
_iv_chk "a worktree whose newest session ends on a tool call with no result, 2 hours old, leads with blocked" "$IV_T1" wt-blocked lead blocked
if [ -r "$IV_UNREAD" ]; then
  skip "a worktree whose newest session cannot be read says unknown rather than passing as clean" "this user reads a mode-000 file"
else
  _iv_chk "a worktree whose newest session cannot be read says unknown rather than passing as clean" "$IV_T1" wt-unread word 0:unknown
fi
is  "exactly one chip is chip-unstarted: of five, one was started, one dismissed, one is older than the default 14 days of --days (D4) and one is another repository's" \
    "$(_iv_count "$IV_T1" chip-unstarted)" "1"
_iv_selstate "$IV_T1" chip-unstarted
if grep -qE 'Delta chip|task_d4d4d4d4' "$IV/sel" && ! grep -qE 'Alpha|Gamma|Epsilon|Zeta|task_a1a1a1a1|task_c3c3c3c3|task_e5e5e5e5|task_f6f6f6f6' "$IV/sel"; then
  ok  "and it is the chip neither started nor dismissed, named by its title or task id"
else bad "and it is the chip neither started nor dismissed, named by its title or task id" "$(_iv_diag)"; fi
_iv_selstate "$IV_T1" handoff-pending
if grep -qF 'Build the frobnicator' "$IV/sel" && grep -qF 'Measure the frobnicator' "$IV/sel"; then
  ok  "a section waiting in docs/handoff/pending on main is handoff-pending, carrying both of its Next lines"
else bad "a section waiting in docs/handoff/pending on main is handoff-pending, carrying both of its Next lines" "$(_iv_diag)"; fi
[ -s "$IV/sel" ] && ! grep -qF 'trap line' "$IV/sel" && ok "and not the lines of its other lists" \
  || bad "and not the lines of its other lists" "$(_iv_diag)"

# ---- the human report ----------------------------------------------------
IV_HU="$IV/human.txt"; _ivrun inventory --repo "$IVM" > "$IV_HU"; IV_RCH=$?
is  "felix inventory with no flag exits 0" "$IV_RCH" "0"
IV_HH="$(_ivmin "$(_ivln "$IV_HU" wt-revert topic/revert)" "$(_ivln "$IV_HU" wt-share topic/shared)" "$(_ivlnw "$IV_HU" hazard)")"
IV_HL="$(_ivmin "$(_ivlnw "$IV_HU" landed)" "$(_ivln "$IV_HU" wt-squash topic/squash)")"
if [ -n "$IV_HH" ] && [ -n "$IV_HL" ] && [ "$IV_HH" -lt "$IV_HL" ]; then ok "its human output lists hazards before any landed item or count"
else bad "its human output lists hazards before any landed item or count" "first hazard line ${IV_HH:-none}, first landed line ${IV_HL:-none}"; fi
IV_HQ="$(_ivmin "$(_ivln "$IV_HU" wt-query topic/query)" "$(_ivln "$IV_HU" wt-bold topic/bold)")"
IV_HD="$(_ivln "$IV_HU" wt-dirty topic/dirty)"; IV_HP="$(_ivln "$IV_HU" wt-unpushed topic/unpushed)"
IV_HR="$(_ivln "$IV_HU" wt-unproposed topic/unproposed)"
# Every fixture directory lies in a temporary directory (the suite's TMP), so
# under decision D5 these worktrees are listed in the group "in temporary
# directories", and this is the order inside it.
if [ -n "$IV_HH" ] && [ -n "$IV_HQ" ] && [ -n "$IV_HD" ] && [ -n "$IV_HP" ] && [ -n "$IV_HR" ] \
   && [ "$IV_HH" -lt "$IV_HQ" ] && [ "$IV_HQ" -lt "$IV_HD" ] && [ "$IV_HD" -lt "$IV_HP" ] && [ "$IV_HP" -lt "$IV_HR" ]; then
  ok  "and what needs action comes in the spec's order: hazards, questions, uncommitted, unpushed, unproposed"
else bad "and what needs action comes in the spec's order: hazards, questions, uncommitted, unpushed, unproposed" \
         "first lines: hazard ${IV_HH:-none}, question ${IV_HQ:-none}, uncommitted ${IV_HD:-none}, unpushed ${IV_HP:-none}, unproposed ${IV_HR:-none}"; fi
_ivcnt "$IV_HU" live && _ivcnt "$IV_HU" landed && ok "and it ends with counts of live and landed" \
  || bad "and it ends with counts of live and landed" "$(tail -n 6 "$IV_HU" | tr '\n' ';')"

# ---- --no-gh -------------------------------------------------------------
_ivg0="$(wc -l < "$IVGH_LOG" | tr -d ' ')"
IV_T3="$IV/t3.tsv"; _ivrun inventory --tsv --no-gh --repo "$IVM" > "$IV_T3"; IV_RC3=$?
is  "felix inventory --tsv --no-gh exits 0" "$IV_RC3" "0"
is  "--no-gh asks gh nothing" "$(_ivrows "$IV_T3" "$(( $(wc -l < "$IVGH_LOG") - _ivg0 ))")" "0"
is  "--no-gh reports no row pr-open or pr-closed-unlanded" "$(_ivrows "$IV_T3" "$(_iv_count "$IV_T3" pr-open) $(_iv_count "$IV_T3" pr-closed-unlanded)")" "0 0"
grep -qi unknown "$IV_T3" && ok "--no-gh says unknown for what only GitHub could say" \
  || bad "--no-gh says unknown for what only GitHub could say" "no unknown in $(head -c 300 "$IV_T3" | tr '\t\n' '|;')"
_iv_chk "under --no-gh a pushed branch whose pull requests cannot be seen says unknown" "$IV_T3" wt-unproposed word 0:unknown
_iv_chk "and it is not called unproposed, since no pull request is known to be absent" "$IV_T3" wt-unproposed lack unproposed
_iv_chk "under --no-gh an open pull request's branch still has a row, and it says unknown" "$IV_T3" topic/pr-hold word 0:unknown
_iv_chk "under --no-gh a branch only a merged pull request shows landed is not called landed" "$IV_T3" topic/precedes lack landed
_iv_sel "$IV_T3" wt-revert; _ivx=0; _iv_q lead hazard:staged-revert || _ivx=1
_iv_sel "$IV_T3" wt-unpushed; _iv_q hold unpushed || _ivx=1
[ "$_ivx" = 0 ] && ok "under --no-gh what git alone decides stands: the staged revert and the unpushed branch" \
  || bad "under --no-gh what git alone decides stands: the staged revert and the unpushed branch" "$(_iv_diag)"

# ---- --no-host -----------------------------------------------------------
IV_T4="$IV/t4.tsv"; _ivrun inventory --tsv --no-host --repo "$IVM" > "$IV_T4"; IV_RC4=$?
is  "felix inventory --tsv --no-host exits 0" "$IV_RC4" "0"
is  "--no-host reports no row live, question, blocked or chip-unstarted" \
    "$(_ivrows "$IV_T4" "$(_iv_count "$IV_T4" live) $(_iv_count "$IV_T4" question) $(_iv_count "$IV_T4" blocked) $(_iv_count "$IV_T4" chip-unstarted)")" "0 0 0 0"
_iv_chk "--no-host says unknown for the worktree whose session asked a question" "$IV_T4" wt-query word 0:unknown
_iv_sel "$IV_T4" wt-revert; _ivx=0; _iv_q lead hazard:staged-revert || _ivx=1
_iv_sel "$IV_T4" wt-dirty; _iv_q hold uncommitted || _ivx=1
if [ "$IV_JQ" = 1 ]; then _iv_sel "$IV_T4" 4103; _iv_q hold pr-open || _ivx=1; fi
[ "$_ivx" = 0 ] && ok "under --no-host what git and gh decide stands: the staged revert, the uncommitted worktree and an open pull request" \
  || bad "under --no-host what git and gh decide stands: the staged revert, the uncommitted worktree and an open pull request" "$(_iv_diag)"

# ---- no gh on PATH at all ------------------------------------------------
_iv_nogh
if PATH="$IV/nogh" command -v gh >/dev/null 2>&1 || ! PATH="$IV/nogh" command -v git >/dev/null 2>&1; then
  bad "the fixture: a PATH that holds git and no gh" "gh: $(PATH="$IV/nogh" command -v gh) git: $(PATH="$IV/nogh" command -v git)"
else
  ok  "the fixture: a PATH that holds git and no gh"
fi
IV_T5="$IV/t5.tsv"; _ivrun --path "$IV/nogh" inventory --tsv --repo "$IVM" > "$IV_T5"; IV_RC5=$?
is  "with no gh on PATH at all, felix inventory --tsv still exits 0" "$IV_RC5" "0"
if grep -qi unknown "$IV_T5" && [ "$(_iv_count "$IV_T5" pr-open)" = 0 ]; then
  ok  "and it says unknown, claiming no pull request open or absent"
else bad "and it says unknown, claiming no pull request open or absent" "$(head -c 300 "$IV_T5" | tr '\t\n' '|;')"; fi

# ---- --repo --------------------------------------------------------------
IV_T6="$IV/t6.tsv"; _ivrun --cwd "$IV/cwd" inventory --tsv --repo "$IVM" --repo "$IVG" "${IV_CMP[@]}" > "$IV_T6"; IV_RC6=$?
is  "felix inventory --tsv --repo DIR --repo DIR, run from outside any repository, exits 0" "$IV_RC6" "0"
_iv_chk "each --repo is read: the second repository's unpushed branch has its row, and it is unpushed" "$IV_T6" topic/gadget-only hold unpushed
_iv_sel "$IV_T6" topic/gadget-only; IV_RG="$(_iv_col2)"
_iv_sel "$IV_T6" wt-squash;         IV_RW="$(_iv_col2)"
[ -n "$IV_RG" ] && [ -n "$IV_RW" ] && [ "$IV_RG" != "$IV_RW" ] && ok "and each row names its own repository" \
  || bad "and each row names its own repository" "gadget [$IV_RG], widget [$IV_RW]"
[ -s "$IV_T1C" ] && [ -n "$IV_RG" ] && [ "$(_iv_kinds "$IV_T6" "$IV_RG")" = "$(_iv_kinds "$IV_T1C")" ] \
  && ok "and the first repository's rows are the ones reading it alone gives" \
  || bad "and the first repository's rows are the ones reading it alone gives" "$(diff <(_iv_kinds "$IV_T1C") <(_iv_kinds "$IV_T6" "$IV_RG") 2>&1 | head -n 6 | tr '\n' ';')"
_ivrun --cwd "$IV/cwd" inventory --tsv --repo "$IV/cwd" > /dev/null; IV_RC6B=$?
[ "$IV_RC6" -eq 0 ] && [ "$IV_RC6B" -ne 0 ] && ok "felix inventory --repo on a directory that is no repository exits nonzero, since it cannot read one" \
  || bad "felix inventory --repo on a directory that is no repository exits nonzero, since it cannot read one" "exit $IV_RC6B there, $IV_RC6 over two repositories"

# ---- bash 3.2 ------------------------------------------------------------
if /bin/bash -c 'case "$BASH_VERSION" in 3.*) exit 0 ;; esac; exit 1' 2>/dev/null; then
  mkdir -p "$IV/b32"; ln -sf /bin/bash "$IV/b32/bash"
  IV_T7="$IV/t7.tsv"; _ivrun --path "$IV/b32:$IVSTUB:$PATH" --bash /bin/bash inventory --tsv --repo "$IVM" "${IV_CMP[@]}" > "$IV_T7"
  [ -s "$IV_T1C" ] && [ "$(_iv_kinds "$IV_T7")" = "$(_iv_kinds "$IV_T1C")" ] \
    && ok "under /bin/bash 3.2 felix inventory --tsv gives the same items and states" \
    || bad "under /bin/bash 3.2 felix inventory --tsv gives the same items and states" "$(diff <(_iv_kinds "$IV_T1C") <(_iv_kinds "$IV_T7") 2>&1 | head -n 6 | tr '\n' ';')"
else
  skip "under /bin/bash 3.2 felix inventory --tsv gives the same items and states" "/bin/bash here is not 3.2"
fi

# ---- --live, --blocked, --days ------------------------------------------
IV_T8="$IV/t8.tsv"; _ivrun inventory --tsv --repo "$IVM" --live 1 --blocked 1 --days 1 > "$IV_T8"
_iv_chk "--live 1 makes a session 3 minutes old not live" "$IV_T8" wt-live lack live
_iv_chk "--blocked 1 makes its tool call with no result blocked" "$IV_T8" wt-live hold blocked
[ -s "$IV_T8" ] && [ "$(_iv_count "$IV_T8" chip-unstarted)" = 0 ] && ok "--days 1 leaves out the chips of a session two days old" \
  || bad "--days 1 leaves out the chips of a session two days old" "$(_iv_count "$IV_T8" chip-unstarted) chip-unstarted rows"

# ---- it wrote nothing ----------------------------------------------------
# Read-only holds trivially for a command that never ran, so each of these
# needs the first run to have given rows.
_iv_after="$(_iv_snap)"
if [ ! -s "$IV_T1" ]; then
  bad "no file under the fixture's repositories or the scratch HOME changed across every run, nor git's object count" "no run gave rows"
elif [ "$_iv_after" = "$_iv_before" ]; then
  ok  "no file under the fixture's repositories or the scratch HOME changed across every run, nor git's object count"
else
  printf '%s\n' "$_iv_before" > "$IV/snap.before"; printf '%s\n' "$_iv_after" > "$IV/snap.after"
  bad "no file under the fixture's repositories or the scratch HOME changed across every run, nor git's object count" \
      "$(diff "$IV/snap.before" "$IV/snap.after" | head -n 8 | tr '\n' ';')"
fi
_ivx="$(find "$IVW" "$IVW2" "$IVO" "$IVO2" "$IVH" -newer "$IV/marker" -print 2>/dev/null | head -n 5 | tr '\n' ' ')"
[ -s "$IV_T1" ] && [ -z "$_ivx" ] && ok "nothing under them was created, removed or touched after the first run began" \
  || bad "nothing under them was created, removed or touched after the first run began" "$(_ivrows "$IV_T1" "newer: $_ivx")"
# macOS mktemp -d with no template ignores TMPDIR (measured on Darwin 25), so
# there a leftover lands where this cannot see it.
_ivtp="$(TMPDIR="$IVT" mktemp -d 2>/dev/null)"
case "$_ivtp" in
  "$IVT"/*) rmdir "$_ivtp"
            is  "it left nothing in TMPDIR" "$(_ivrows "$IV_T1" "$(ls -A "$IVT" | tr '\n' ' ')")" "" ;;
  *)        [ -n "$_ivtp" ] && rmdir "$_ivtp" 2>/dev/null
            skip "it left nothing in TMPDIR" "this mktemp -d ignores TMPDIR" ;;
esac
_iv_gitparse() { LC_ALL=C awk -F'\t' '
  { n = split($2, w, " "); i = 1; l = ($1 == "0")
    while (i <= n) {
      if (w[i] == "-C" || w[i] == "-c" || w[i] == "--git-dir" || w[i] == "--work-tree" || w[i] == "--namespace") { i += 2; continue }
      if (w[i] == "--no-optional-locks") { l = 1; i++; continue }
      if (w[i] ~ /^-/) { i++; continue }
      break }
    r = ""; for (k = i + 1; k <= n; k++) r = r " " w[k]
    print (l ? "L" : "-") "\t" (i <= n ? w[i] : "-") "\t" r }' "$IVGIT_LOG"; }
_iv_gitlocks() { _iv_gitparse | LC_ALL=C awk -F'\t' '$1 == "-" && ($2 == "status" || $2 == "diff" || $2 == "diff-index" || $2 == "diff-files" || $2 == "describe") { printf "git %s%s; ", $2, $3 }'; }
_iv_gitwrites() { _iv_gitparse | LC_ALL=C awk -F'\t' '
  BEGIN { n = split("fetch pull push ls-remote commit commit-tree write-tree update-index update-ref read-tree mktree gc prune repack pack-refs reset checkout switch restore add rm mv merge rebase cherry-pick revert clean apply am notes replace maintenance", a, " ")
          for (i = 1; i <= n; i++) w[a[i]] = 1 }
  { v = $2; r = " " $3 " "; b = (v in w)
    if (v == "merge-tree") { np = 0; k = split($3, t, " "); for (i = 1; i <= k; i++) if (t[i] !~ /^-/) np++
                             if (index(r, " --write-tree ") || (!index(r, " --trivial-merge ") && np != 3)) b = 1 }
    if (v == "hash-object" && (index(r, " -w ") || index(r, " --write "))) b = 1
    if (v == "stash" && !index(r, " list ") && !index(r, " show ")) b = 1
    if (v == "worktree" && match(r, / (add|remove|prune|move|lock|unlock|repair) /)) b = 1
    if (v == "reflog" && match(r, / (expire|delete) /)) b = 1
    if (v == "branch" && match(r, / (-d|-D|-m|-M|-c|-C|-f|--delete|--move|--copy|--force|-u|--set-upstream-to|--unset-upstream|--edit-description) /)) b = 1
    if (v == "remote" && match(r, / (add|remove|rm|rename|set-head|set-url|set-branches|prune|update) /)) b = 1
    if (v == "config" && match(r, / (--add|--unset|--unset-all|--replace-all|--rename-section|--remove-section|--edit|-e) /)) b = 1
    if (b) printf "git %s%s; ", v, $3 }'; }
if [ -s "$IVGIT_LOG" ]; then
  is  "every git status, diff or describe it ran carries --no-optional-locks" "$(_iv_gitlocks)" ""
  is  "it ran no git command that writes, or that reaches a remote" "$(_iv_gitwrites)" ""
else
  skip "every git status, diff or describe it ran carries --no-optional-locks" "the git stand-in saw no call"
  skip "it ran no git command that writes, or that reaches a remote" "the git stand-in saw no call"
fi
_iv_ghwrites() { LC_ALL=C awk '
  { n = split($0, w, " "); c = w[1]; s = w[2]; k = 0
    if (c == "pr" && (s == "list" || s == "view" || s == "checks" || s == "status" || s == "diff")) k = 1
    else if (c == "repo" && s == "view") k = 1
    else if (c == "auth" && s == "status") k = 1
    else if (c == "--version" || c == "version") k = 1
    else if (c == "api") { k = 1; m = ""; f = 0
      for (i = 2; i <= n; i++) {
        if ((w[i] == "-X" || w[i] == "--method") && i < n) m = toupper(w[i + 1])
        else if (w[i] ~ /^--method=/) m = toupper(substr(w[i], 10))
        else if (w[i] == "-f" || w[i] == "-F" || w[i] == "--field" || w[i] == "--raw-field" || w[i] == "--input" || w[i] ~ /^--(field|raw-field|input)=/) f = 1 }
      if ((m != "" && m != "GET") || (f && m != "GET")) k = 0 }
    if (!k) printf "gh %s; ", $0 }' "$IVGH_LOG"; }
is  "every gh call it made is a read: pr list, view or checks, repo view, auth status, or an api GET" "$(_ivrows "$IV_T1" "$(_iv_ghwrites)")" ""
_ivx="$(grep -E 'bad substitution|syntax error|unbound variable|command not found|invalid option|not a valid identifier|division by 0|awk: |Permission denied' "$IV_ERR" | head -n 3 | tr '\n' ';')"
is  "no run wrote a shell or awk error to stderr" "$_ivx" ""

# ---- the code ------------------------------------------------------------
_iv_hostin() { _ivcode "$IVLIB" ${IVPARTS[@]+"${IVPARTS[@]}"} | grep -E '\.claude/projects|spawn_task|dismiss_task|tool_use|tool_result|\.jsonl' | _ivwhere 'names a transcript detail'; }
_iv_ghin()   { _ivcode "$IVLIBH" "$IVLIBC" | grep -E '(^|[^A-Za-z0-9_./-])gh[[:space:]]+(pr|api|repo|auth|issue|run|release|workflow|search)([[:space:]]|$)' | _ivwhere 'calls gh'; }
_iv_bash4()  { _ivcode "$IVLIB" "$IVLIBH" "$IVLIBC" ${IVPARTS[@]+"${IVPARTS[@]}"} | grep -E '(declare|local|typeset)[[:space:]]+-[a-zA-Z]*A|(^|[^a-z_])(mapfile|readarray|coproc)([^a-z_]|$)|\$\{[#!]?[A-Za-z_][A-Za-z0-9_]*(\[[^]]*\])?(,,?|\^\^?)[^}]*\}|&>>|\|&|\$\{[A-Za-z_][A-Za-z0-9_]*:([[:space:]]+|\()-[0-9]' | _ivwhere 'bash 4 or later'; }
# Strings and regular-expression literals are blanked before counting match's
# arguments, so a regex holding commas is not a third argument.
_iv_gawk()   { _ivcode "$IVLIB" "$IVLIBH" "$IVLIBC" ${IVPARTS[@]+"${IVPARTS[@]}"} | LC_ALL=C awk '
  { s = $0; gsub(/"([^"\\]|\\.)*"/, "\"\"", s); gsub(/\/([^\/\\]|\\.)+\//, "//", s)
    if (s ~ /(^|[^a-z_])(gensub|asorti?|strftime|systime|patsplit)[[:space:]]*\(/ || s ~ /match\([^()]*,[^()]*,[^()]*\)/) print }' | _ivwhere 'gawk only'; }
_iv_gitw()   { _ivcode "$IVLIB" "$IVLIBH" "$IVLIBC" ${IVPARTS[@]+"${IVPARTS[@]}"} | grep -E 'write-tree|stash[[:space:]]+create|update-index|update-ref|hash-object[^|;&]*[[:space:]]-w([[:space:]]|$)' | _ivwhere 'a git write'; }
IV_NAMES='lib/inventory|inventory\.sh|inventory-host|felix_inventory|cmd_inventory|felix inventory'
_iv_enforcing() {
  grep -lE "$IV_NAMES" "$REAL_HARNESS"/hooks/* 2>/dev/null | tr '\n' ' '
  LC_ALL=C awk '/^cmd_gate\(\)/ { f = 1 } f { print } f && /^}/ { exit }' "$REAL_HARNESS/felix" > "$IV/gate.body"
  grep -qE "$IV_NAMES" "$IV/gate.body" && printf 'cmd_gate'
  [ -s "$IV/gate.body" ] || printf 'no cmd_gate found in felix'
}
[ -f "$IVLIB" ] && [ -f "$IVLIBH" ] && ok "lib/inventory.sh and lib/inventory-host.sh exist, the core and the host adapter" \
  || bad "lib/inventory.sh and lib/inventory-host.sh exist, the core and the host adapter" "missing: $([ -f "$IVLIB" ] || printf 'inventory.sh ')$([ -f "$IVLIBH" ] || printf 'inventory-host.sh')"
_ivx=""
for _ivf in "$IVLIB" "$IVLIBH" "$IVLIBC" ${IVPARTS[@]+"${IVPARTS[@]}"}; do [ -f "$_ivf" ] && [ "$(wc -l < "$_ivf")" -ge 500 ] && _ivx="$_ivx ${_ivf##*/}"; done
is  "each of them stays under 500 lines" "$_ivx" ""
_ivx="$(_iv_hostin)"
[ -f "$IVLIB" ] && [ -z "$_ivx" ] && ok "lib/inventory.sh reads no Claude Code transcript, which is the adapter's" \
  || bad "lib/inventory.sh reads no Claude Code transcript, which is the adapter's" "${_ivx:-no lib/inventory.sh}"
_ivx="$(_iv_ghin)"
[ -f "$IVLIBH" ] && [ -z "$_ivx" ] && ok "lib/inventory-host.sh calls no gh, which is the core's" \
  || bad "lib/inventory-host.sh calls no gh, which is the core's" "${_ivx:-no lib/inventory-host.sh}"
is  "neither library uses a construct bash 3.2 lacks" "$(_iv_bash4)" ""
is  "no awk in either library uses a gawk-only function or match's third argument" "$(_iv_gawk)" ""
is  "neither library names write-tree, stash create, update-index, update-ref or hash-object -w" "$(_iv_gitw)" ""
is  "no hook and nothing in felix's gate names the inventory: it is advisory, off the enforcing path" "$(_iv_enforcing)" ""

