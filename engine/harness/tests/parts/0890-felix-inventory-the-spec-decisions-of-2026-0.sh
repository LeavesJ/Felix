# ---- spec decisions of 2026-09-24 ----------------------------------------
# Six decisions Felix took on the spec after review, each held to the rule it
# sets and each seen failing on the command as it stood before it was built:
#   D1 a session ended on a question when its final assistant text asks,
#      and no human text follows. Asks is the rule measured on 227 real
#      endings read by hand on 2026-09-24: fenced blocks, code spans,
#      double-quoted spans and blockquotes set aside, a ? ends a line in the
#      last three paragraphs, or the text makes one of ten offers (say the
#      word, want me to, your call, ...) not negated within its clause. The
#      note stays the text's last 160 characters, cut on a character boundary
#   D2 live is the newest mtime among a session's own file and every file
#      under its <session-id>/subagents/ (workflows/ too); blocked also needs
#      nothing there written within --blocked; question and blocked read the
#      session's own file only
#   D3 superseded 2026-10-01 (spec §5, §5.1): what was read is five cover
#      rows per repository, ref the facet; no row is of kind repo
#   D4 --days defaults to 14, and the human view states the window
#   D5 a worktree or orphan under $TMPDIR, /tmp, /private/tmp or
#      /private/var/folders carries the detail word temp, keeps its states,
#      and is listed in a group of its own after what needs action
#   D6 no code: pending/ only, which the handoff assertions above hold
# D1, D2 and D4 are built on a fourth repository, doohickey, so nothing above
# changes its fixture; D3 and D5 read the runs above as well.
printf '\nfelix inventory: the spec decisions of 2026-09-24\n'
_iv_build runs
_ivz_build runs
IVW4="$IV/work4"; IVK="$IVW4/doohickey"; IVKO="$IV/origin4.git"
mkdir -p "$IVW4"
_ivrepo "$IVKO" "$IVK" acme/doohickey
# Its one commit is ten days old, so a row's age comes from its sessions.
printf 'doohickey\n' > "$IVK/README.md"
( _ivx="$(( $(date +%s) - 864000 )) +0000"; export GIT_COMMITTER_DATE="$_ivx" GIT_AUTHOR_DATE="$_ivx"; _ivwc "$IVK" 'the first doohickey' )
_ivg -C "$IVK" push -q origin main; _ivg -C "$IVK" remote set-head origin main
for _ivn in midq boldq listq longq trail earlier blankws quoted code then offer plain agent flow stale mid two; do
  _ivg -C "$IVK" worktree add -q -b "topic/$_ivn" "$IVW4/wt-$_ivn" main
done
# D1: sessions two hours old, each ending on one final text. The texts are
# written as a transcript holds them, a line break as \n.
_ivk1() {  # worktree sid text
  _ivopen "$IVW4/$1" "$2"
  _au_say  "$(_ivago 122 iso)" 'report back'
  _au_stop "$(_ivago 120 iso)" "msg_$1" "$3"
  _ivtouch "$_AU_F" 120
}
IVK_TAIL='the rest of the paragraph runs on the rest of the paragraph runs on the rest of the paragraph runs on the rest of the paragraph runs on the rest of the paragraph runs on the rest of the paragraph runs on the rest of the paragraph runs on'
_ivk1 wt-midq    d1d1d1d1-0000-4000-8000-000000000001 'I rebased the branch and the suite is green.\n\nShall I push it? Or leave it for review.'
_ivk1 wt-boldq   d1d1d1d1-0000-4000-8000-000000000002 'The two layouts differ in one place.\n\n**Want me to merge it?** I can wait.'
_ivk1 wt-listq   d1d1d1d1-0000-4000-8000-000000000003 'Three options remain:\n- keep it\n- drop it\n- split it\nWhich one do you prefer?\nAny of them works.'
_ivk1 wt-longq   d1d1d1d1-0000-4000-8000-000000000004 "Done.\\n\\nShall I go on? $IVK_TAIL "
_ivk1 wt-trail   d1d1d1d1-0000-4000-8000-000000000005 'Here it is.\n\nWhich one do you want?\n\n'
# A ? four paragraphs back, in a text that makes no offer; and the same with
# the first break a line of spaces and a tab, which three paragraphs would
# reach if that line were not blank.
_ivk1 wt-earlier d1d1d1d1-0000-4000-8000-000000000006 'Is it pushed?\n\nOne thing is left.\n\nThe tests pass.\n\nThe branch is pushed.'
_ivk1 wt-blankws d1d1d1d1-0000-4000-8000-000000000007 'Is it pushed?\n \t \nOne thing is left.\n\nThe tests pass.\n\nThe branch is pushed.'
# What a ? in the last paragraph got wrong on real endings, each way: a
# question quoted from someone else, git status's ?? in a code span, a
# question with one more paragraph after it, an offer with no ?, and a
# summary whose one offer-like phrase is negated.
_ivk1 wt-quoted  d1d1d1d1-0000-4000-8000-000000000008 'I answered the one review comment, which asked \"is this realistic?\"'
_ivk1 wt-code    d1d1d1d1-0000-4000-8000-000000000009 'The tree is clean but for one scratch file, `?? notes.txt`, which stays out of the commit.'
_ivk1 wt-then    d1d1d1d1-0000-4000-8000-00000000000a 'Is the second layout the one to keep?\n\nEverything else is pushed.'
_ivk1 wt-offer   d1d1d1d1-0000-4000-8000-00000000000b 'The fix is on the branch. Say the word and I will open the pull request.'
_ivk1 wt-plain   d1d1d1d1-0000-4000-8000-00000000000c 'The branch is merged and the worktree is clean; nothing here needs your decision.'
# D2: sessions whose own file last moved two or three hours ago, on a call
# to a subagent that has had no result, and whose subagents/ holds a file
# last written some minutes ago.
_ivk2() {  # worktree sid own-age-min
  _ivopen "$IVW4/$1" "$2"
  _au_say  "$(_ivago $(($3 + 2)) iso)" 'look into it'
  _au_tool "toolu_$1" Agent '{"description":"Look into it","prompt":"look into it","subagent_type":"general-purpose"}'
  _au_a    "$(_ivago "$3" iso)" "msg_$1" '"tool_use"' "$_AU_B"
  _ivtouch "$_AU_F" "$3"
}
_ivk2sub() {  # worktree sid path-under-subagents age-min
  _au_open "$(_ive "$IVW4/$1")/$2/subagents/$3" "agent-$1"
  _au_say  "$(_ivago $(($4 + 1)) iso)" 'look into it'
  _au_stop "$(_ivago "$4" iso)" "msg_sub_$1" 'Found it. Anything else?'
  _ivtouch "$_AU_F" "$4"
}
_ivk2    wt-agent d2d2d2d2-0000-4000-8000-000000000001 120
_ivk2sub wt-agent d2d2d2d2-0000-4000-8000-000000000001 agent-a1.jsonl 2
_ivk2    wt-flow  d2d2d2d2-0000-4000-8000-000000000002 120
_ivk2sub wt-flow  d2d2d2d2-0000-4000-8000-000000000002 workflows/wf_1/agent-a2.jsonl 2
_ivk2    wt-stale d2d2d2d2-0000-4000-8000-000000000003 120
_ivk2sub wt-stale d2d2d2d2-0000-4000-8000-000000000003 agent-a3.jsonl 90
_ivk2    wt-mid   d2d2d2d2-0000-4000-8000-000000000004 120
_ivk2sub wt-mid   d2d2d2d2-0000-4000-8000-000000000004 agent-a4.jsonl 30
# wt-two: an older session, quiet three hours on a subagent that wrote two
# minutes ago, and a newer one that ended on a question ninety minutes ago.
_ivk2    wt-two   d2d2d2d2-0000-4000-8000-00000000000a 180
_ivk2sub wt-two   d2d2d2d2-0000-4000-8000-00000000000a agent-a5.jsonl 2
_ivopen "$IVW4/wt-two" d2d2d2d2-0000-4000-8000-00000000000b
_au_say  "$(_ivago 92 iso)" 'is it ready'
_au_stop "$(_ivago 90 iso)" msg_two_b 'It is ready. Shall I merge it?'
_ivtouch "$_AU_F" 90
# D4: a chip in a session ten days old, never started, and one in a session
# twenty days old.
IV_PK_PROMPT='Kappa task: make the importer skip a row whose checksum repeats the previous row, and test it on a file holding one row twice in a row.'
IV_PI_PROMPT='Iota task: teach the report to name the file each total came from, and test that a total built from two files names both of them.'
_ivopen "$IVK" d4d4d4d4-0000-4000-8000-00000000000a
_au_say  "$(_ivago 14402 iso)" 'note what is left'
_ivchip  "$(_ivago 14401 iso)" toolu_ck task_k4k4k4k4 'Kappa chip ten days old' "$IV_PK_PROMPT"
_au_stop "$(_ivago 14400 iso)" msg_ck 'Noted.'
_ivtouch "$_AU_F" 14400
_ivopen "$IVK" d4d4d4d4-0000-4000-8000-00000000000b
_au_say  "$(_ivago 28802 iso)" 'note what is left'
_ivchip  "$(_ivago 28801 iso)" toolu_ci task_i4i4i4i4 'Iota chip twenty days old' "$IV_PI_PROMPT"
_au_stop "$(_ivago 28800 iso)" msg_ci 'Noted.'
_ivtouch "$_AU_F" 28800

IVK_T1="$IV/k1.tsv"; _ivrun --cwd "$IVK" inventory --tsv --no-gh --repo "$IVK" > "$IVK_T1"; IVK_RC1=$?
IVK_T2="$IV/k2.tsv"; _ivrun --cwd "$IVK" inventory --tsv --no-gh --blocked 40 --repo "$IVK" > "$IVK_T2"
IVK_H1="$IV/k1.txt"; _ivrun --cwd "$IVK" inventory --no-gh --repo "$IVK" > "$IVK_H1"
IVK_H3="$IV/k3.txt"; _ivrun --cwd "$IVK" inventory --no-gh --days 3 --repo "$IVK" > "$IVK_H3"
# The temporary directories replaced by one outside the fixture, so its rows
# read as a checkout anywhere else would; and a HOME with no session records.
IVK_T4="$IV/k4.tsv"; _ivrun --cwd "$IVK" --troots "$TMP/elsewhere" inventory --tsv --no-gh --repo "$IVK" > "$IVK_T4"
IVK_H4="$IV/k4.txt"; _ivrun --cwd "$IVK" --troots "$TMP/elsewhere" inventory --no-gh --repo "$IVK" > "$IVK_H4"
mkdir -p "$IV/norecords"
IVK_H5="$IV/k5.txt"; _ivrun --cwd "$IVK" --home "$IV/norecords" inventory --no-gh --repo "$IVK" > "$IVK_H5"
is  "the decisions' runs: felix inventory --tsv over doohickey exits 0" "$IVK_RC1" "0"
# The row of one worktree, by its path exactly.
_ivk_sel() { LC_ALL=C awk -F'\t' -v r="$IVW4/$2" '$3 == r' "$1" > "$IV/sel"; }
_ivk_chk() {  # name file worktree mode arg
  _ivk_sel "$2" "$3"
  if _iv_q "$4" "$5"; then ok "$1"; else bad "$1" "$(_iv_diag)"; fi; }

# ---- D1: question ----
_ivk_chk "D1: an offer that asks and then goes on on the same line is a question" "$IVK_T1" wt-midq hold question
_ivk_chk "D1: a question in bold followed by a statement is a question" "$IVK_T1" wt-boldq hold question
_ivk_chk "D1: a last paragraph of single lines, one of them ending on ?, is a question" "$IVK_T1" wt-listq hold question
_ivk_chk "D1: blank lines after the question leave it in the last paragraphs, a question" "$IVK_T1" wt-trail hold question
_ivk_chk "D1: a ? four paragraphs back, in a text that makes no offer, is no question" "$IVK_T1" wt-earlier lack question
_ivk_chk "D1: a line of spaces and a tab is a blank line, so the ? before it is four paragraphs back" "$IVK_T1" wt-blankws lack question
_ivk_chk "D1: a question inside double quotes is no question" "$IVK_T1" wt-quoted lack question
_ivk_chk "D1: a ?? inside a code span is no question" "$IVK_T1" wt-code lack question
_ivk_chk "D1: a question followed by one more paragraph is a question" "$IVK_T1" wt-then hold question
_ivk_chk "D1: an offer with no ? is a question" "$IVK_T1" wt-offer hold question
_ivk_chk "D1: a plain summary, even one saying nothing needs your decision, is no question" "$IVK_T1" wt-plain lack question
_ivk_sel "$IVK_T1" wt-midq
has "D1: the note of a short question is the whole text, a line break read as a space" "$(cut -f8 "$IV/sel")" \
    "ended on: I rebased the branch and the suite is green.  Shall I push it? Or leave it for review."
_ivx="Done.  Shall I go on? $IVK_TAIL"; _ivx="${_ivx:$((${#_ivx} - 160))}"
_ivk_sel "$IVK_T1" wt-longq
if _iv_q hold question; then has "D1: the note of a long question is the text's last 160 characters" "$(cut -f8 "$IV/sel")" "ended on: $_ivx"
else bad "D1: the note of a long question is the text's last 160 characters" "$(_iv_diag)"; fi

# ---- D2: live and blocked ----
_ivk_chk "D2: a session quiet two hours on a subagent call is live when a file under its subagents/ was written 2 minutes ago" "$IVK_T1" wt-agent hold live
_ivk_chk "D2: and it is not blocked, since its subagents wrote within --blocked" "$IVK_T1" wt-agent lack blocked
_ivk_sel "$IVK_T1" wt-agent
is  "D2: and its age is its newest file's, 0 hours" "$(cut -f6 "$IV/sel")" "0"
_ivk_chk "D2: a file under subagents/workflows/ written 2 minutes ago counts as well" "$IVK_T1" wt-flow hold live
_ivk_sel "$IVK_T1" wt-stale
if _iv_q lack live && _iv_q hold blocked; then ok "D2: subagents that last wrote 90 minutes ago make it neither live nor unblocked"
else bad "D2: subagents that last wrote 90 minutes ago make it neither live nor unblocked" "$(_iv_diag)"; fi
_ivk_sel "$IVK_T1" wt-mid
if _iv_q hold live && _iv_q hold blocked; then ok "D2: subagents that last wrote 30 minutes ago make it live, and under the default --blocked 20 still blocked"
else bad "D2: subagents that last wrote 30 minutes ago make it live, and under the default --blocked 20 still blocked" "$(_iv_diag)"; fi
_ivk_chk "D2: and under --blocked 40 they keep it from being blocked" "$IVK_T2" wt-mid lack blocked
_ivk_sel "$IVK_T1" wt-two
if _iv_q hold live && _iv_q hold question; then ok "D2: an older session's subagent writing now makes the worktree live, and the newest session's question stands"
else bad "D2: an older session's subagent writing now makes the worktree live, and the newest session's question stands" "$(_iv_diag)"; fi

# ---- D3: repository-level rows ----
# Superseded by the settled contract (2026-10-01 spec §5, §5.1, §11 row 2): what
# was read is five rows of kind cover per repository, ref the facet name, and
# no row of kind repo is ever printed. Each check names the facet and a
# state its states column must hold.
# kind ref states, for every row of kind cover or repo, or with ref -.
_ivk_repo() { LC_ALL=C awk -F'\t' '$1 == "kind" && $4 == "states" { next } $1 == "cover" || $1 == "repo" || $3 == "-" { print $1 "\t" $3 "\t" $4 }' "$1"; }
_ivk_rchk() {  # name file facet state
  if [ -s "$2" ] && _ivk_repo "$2" | LC_ALL=C awk -F'\t' -v r="$3" -v s="$4" '$1 == "cover" && $2 == r && index("," $3 ",", "," s ",") { f = 1 } END { exit !f }'; then ok "$1"
  else bad "$1" "$(_ivrows "$2" "$(_ivk_repo "$2" | tr '\t\n' '|;')")"; fi; }
_ivk_rchk "D3: under --no-gh the open PRs not listed are stated on the cover row prs" "$IV_T3" prs unknown:pr-open
_ivk_rchk "D3: with no gh on PATH, likewise" "$IV_T5" prs unknown:pr-open
_ivk_rchk "D3: under --no-host the chips not read are stated on the cover row chips" "$IV_T4" chips unknown:chip-unstarted
_ivk_rchk "D3: when gh lists its limit of 1000, the cover row prs says partial,unknown:unproposed" "$IVZ_T3" prs partial,unknown:unproposed
_ivx=""
for _ivf in "$IV_T0" "$IV_T0W" "$IV_T1" "$IV_T3" "$IV_T4" "$IV_T5" "$IV_T6" "$IV/t7.tsv" "$IV_T8" "$IVZ_T1" "$IVZ_T3" "$IVZ_T4" "$IVZ_P1" "$IVZ_P2" "$IVK_T1" "$IVK_T2"; do
  [ -f "$_ivf" ] || continue
  _ivx="$_ivx$(_ivk_repo "$_ivf" | LC_ALL=C awk -F'\t' -v f="${_ivf##*/}" '$1 == "repo" || $2 == "-" { printf "%s: %s %s; ", f, $1, $2 }')"
done
is  "D3: across every run, no row is of kind repo and no row has ref -" "$_ivx" ""

# ---- D4: the chip window ----
_iv_selstate "$IVK_T1" chip-unstarted
if grep -qE 'Kappa chip|task_k4k4k4k4' "$IV/sel"; then ok "D4: by default a chip from a session 10 days old is listed"
else bad "D4: by default a chip from a session 10 days old is listed" "$(_iv_diag)"; fi
if [ -s "$IVK_T1" ] && ! grep -qE 'Iota chip|task_i4i4i4i4' "$IV/sel"; then ok "D4: and one from a session 20 days old is not"
else bad "D4: and one from a session 20 days old is not" "$(_ivrows "$IVK_T1" "$(_iv_diag)")"; fi
LC_ALL=C grep -qiE 'chips.*last 14 days' "$IVK_H1" && ok "D4: the human view states the window: chips from the last 14 days" \
  || bad "D4: the human view states the window: chips from the last 14 days" "$(head -n 8 "$IVK_H1" | tr '\n' ';')"
LC_ALL=C grep -qiE 'chips.*last 3 days' "$IVK_H3" && ok "D4: and under --days 3 it says 3 days" \
  || bad "D4: and under --days 3 it says 3 days" "$(head -n 8 "$IVK_H3" | tr '\n' ';')"

# ---- D5: temporary directories ----
_iv_chk "D5: a worktree under a temporary directory carries the word temp in its detail" "$IV_T1" wt-dirty word 8:temp
_iv_chk "D5: and its states are computed as for any other: it still leads with uncommitted" "$IV_T1" wt-dirty lead uncommitted
_iv_chk "D5: an orphan under one carries temp too" "$IV_T1" orphan-edit word 8:temp
_ivx="$(LC_ALL=C awk -F'\t' '$1 == "kind" && $4 == "states" { next }
  $1 != "worktree" && $1 != "orphan" && tolower($8) ~ /(^|[^a-z])temp([^a-z]|$)/ { printf "%s %s; ", $1, $3 }' "$IV_T1" "$IV_T3" "$IV_T4")"
is  "D5: no row that is not a directory carries temp: branches, remote branches, PRs, chips, handoff sections, cover rows" "$(_ivrows "$IV_T1" "$_ivx")" ""
# Every fixture lies in a temporary directory (the suite's TMP is one), so
# the one path outside every temporary directory is asked of the test the
# command applies, below the command: the libraries sourced, _fi_tmps reading
# TMPDIR and _fi_temp asked of each path.
_ivx="$(TMPDIR=/nowhere/t/ /bin/bash -c 'unset FELIX_INVENTORY_TEMP_ROOTS; for f in "$@"; do . "$f" || exit 1; done; _fi_tmps; for p in /home/u/x /tmpx/y /private/varx /nowhere/tt /nowhere/t/z /tmp/a /private/tmp /private/var/folders/q/r; do _fi_temp "$p" && printf "%s " "$p"; done; exit 0' _ "$IVLIB" ${IVPARTS[@]+"${IVPARTS[@]}"} 2>&1)"
is  "D5: of eight paths, the four under TMPDIR, /tmp, /private/tmp or /private/var/folders are temp, and no other" "$_ivx" "/nowhere/t/z /tmp/a /private/tmp /private/var/folders/q/r "
IV_HT="$(_ivln "$IV_HU" 'in temporary directories' 'in temporary directories')"
IV_HX="$(LC_ALL=C awk '/(^|[^a-z])live [0-9]/ && /landed [0-9]/ { print NR; exit }' "$IV_HU")"
IV_HN="$(_ivln "$IV_HU" 'Delta chip' task_d4d4d4d4)"; IV_HF="$(_ivln "$IV_HU" frobnicator frobnicator)"; IV_HW="$(_ivln "$IV_HU" wt-dirty wt-dirty)"
if [ -n "$IV_HT" ] && [ -n "$IV_HX" ] && [ -n "$IV_HN" ] && [ -n "$IV_HF" ] && [ -n "$IV_HW" ] \
   && [ "$IV_HN" -lt "$IV_HT" ] && [ "$IV_HF" -lt "$IV_HT" ] && [ "$IV_HT" -lt "$IV_HW" ] && [ "$IV_HW" -lt "$IV_HX" ]; then
  ok  "D5: the human view lists them under \"in temporary directories\", after the groups that need action and before the live and landed counts"
else bad "D5: the human view lists them under \"in temporary directories\", after the groups that need action and before the live and landed counts" \
         "lines: temp group ${IV_HT:-none}, chip ${IV_HN:-none}, handoff ${IV_HF:-none}, wt-dirty ${IV_HW:-none}, counts ${IV_HX:-none}"; fi

# ---- what review of the decisions found ----
# Each held to the rule it broke, and seen failing on the command before its
# fix. A human view's item line is "    kind     ref  [states]": the group it
# sits in is the last heading above it, and a ref is matched whole.
_ivk_item()  { LC_ALL=C awk -v n="$2" '/^    [^ ]/ { s = substr($0, 14); sub(/  \[.*$/, "", s); if (s == n) { print; exit } }' "$1"; }
_ivk_group() { LC_ALL=C awk -v n="$2" '/^  [^ ]/ { g = $0; sub(/^  /, "", g); sub(/  [0-9]+$/, "", g); next }
    /^    [^ ]/ { s = substr($0, 14); sub(/  \[.*$/, "", s); if (s == n) { print g; exit } }' "$1"; }
_ivx="$(_ivk_item "$IVK_H1" "$IVW4/wt-two")"
[ -n "$_ivx" ] && ok "the human view lists a live worktree whose newest session ended on a question, rather than only counting it live" \
  || bad "the human view lists a live worktree whose newest session ended on a question, rather than only counting it live" "$(grep -F wt-two "$IVK_H1" | head -n 3 | tr '\n' ';')"
_ivx="$(_ivk_item "$IVK_H4" "$IVW4/wt-two")"
case "$(_ivk_group "$IVK_H4" "$IVW4/wt-two"):$_ivx" in
  question:*live*) ok  "and outside a temporary directory it is listed under question, its listing saying live" ;;
  *)               bad "and outside a temporary directory it is listed under question, its listing saying live" "group [$(_ivk_group "$IVK_H4" "$IVW4/wt-two")], line [$_ivx]" ;;
esac
is  "a live worktree whose tool call has waited past --blocked is listed under blocked, rather than only counted" "$(_ivk_group "$IVK_H4" "$IVW4/wt-mid")" "blocked"
_ivx="$(LC_ALL=C awk '/nothing decided but unknown [0-9]/ { sub(/.*nothing decided but unknown /, ""); print; exit }' "$IVK_H1")"
if [ "$_ivx" = 0 ] && LC_ALL=C grep -qE '(^|[^a-z])prs([^a-z]|$).*--no-gh' "$IVK_H1"; then
  ok  "nothing decided but unknown counts items, not the repository's own unknowns, which its header states"
else bad "nothing decided but unknown counts items, not the repository's own unknowns, which its header states" "count [$_ivx]; $(head -n 6 "$IVK_H1" | tr '\n' ';')"; fi
LC_ALL=C grep -qE '(^|[^a-z])chips([^a-z]|$).*no session records' "$IVK_H5" && ok "with no session records to read, the header says the chips are unknown, since no count does" \
  || bad "with no session records to read, the header says the chips are unknown, since no count does" "$(head -n 7 "$IVK_H5" | tr '\n' ';')"
# Spec §4.1, §5.1: the row carries each unknown: entry its unread facet
# leaves, read from --tsv, since §8 no longer lists such a row.
_iv_sel "$IV_T3" wt-unproposed
if _iv_q hold unknown:unproposed && _iv_q hold unknown:pr-open && _iv_q hold unknown:pr-closed-unlanded \
   && LC_ALL=C awk -F'\t' 'index("," $4 ",", ",unknown:unproposed,unknown:pr-open,unknown:pr-closed-unlanded,") { f = 1 } END { exit f ? 0 : 1 }' "$IV/sel"; then ok "an undecided row lists every state it could not decide, the first of them too"
else bad "an undecided row lists every state it could not decide, the first of them too" "$(_iv_diag)"; fi
# D5's list, replaced: the unit, then the command.
_ivx="$(FELIX_INVENTORY_TEMP_ROOTS=/nowhere/a:/nowhere/b/ TMPDIR=/nowhere/t /bin/bash -c 'for f in "$@"; do . "$f" || exit 1; done; _fi_tmps; for p in /nowhere/a/x /nowhere/b/y /nowhere/t/z /tmp/a /nowhere/ab; do _fi_temp "$p" && printf "%s " "$p"; done; exit 0' _ "$IVLIB" ${IVPARTS[@]+"${IVPARTS[@]}"} 2>&1)"
is  "D5: FELIX_INVENTORY_TEMP_ROOTS, colon-separated, replaces the list: of five paths only the two under its roots are temp" "$_ivx" "/nowhere/a/x /nowhere/b/y "
_ivx="$(LC_ALL=C awk -F'\t' '$1 == "kind" && $4 == "states" { next } tolower($8) ~ /(^|[^a-z])temp([^a-z]|$)/ { printf "%s; ", $3 }' "$IVK_T4")"
_ivk_sel "$IVK_T4" wt-midq
if [ -s "$IVK_T4" ] && [ -z "$_ivx" ] && _iv_q hold question; then
  ok  "D5: with it naming a directory outside the fixture, no fixture row carries temp, and each keeps its states"
else bad "D5: with it naming a directory outside the fixture, no fixture row carries temp, and each keeps its states" "temp: [$_ivx]; $(_iv_diag)"; fi
is  "D5: and the human view lists a worktree whose session asked in its needs-action group, question" "$(_ivk_group "$IVK_H4" "$IVW4/wt-midq")" "question"

_ivx="$(grep -E 'bad substitution|syntax error|unbound variable|command not found|invalid option|not a valid identifier|division by 0|awk: |Permission denied' "$IV_ERR" | head -n 3 | tr '\n' ';')"
is  "the decisions' runs wrote no shell or awk error to stderr" "$_ivx" ""

