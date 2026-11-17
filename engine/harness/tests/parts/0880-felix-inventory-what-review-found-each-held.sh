# ---- what review found --------------------------------------------------
# Three reviewers read the command against the spec and against real input.
# Each defect they found that is a defect in the command, not in the spec,
# is held here to the contract it broke, on a third repository built for it,
# so no assertion above changes its fixture. Each was seen failing on the
# command as it stood before the fix.
printf '\nfelix inventory: what review found, each held to the contract it broke\n'
_iv_build
_ivz_build
# ---- the fixture holds what the assertions below say ---------------------
_ivfx=""
[ -e "$IVZX/filter-ran" ] && _ivfx="$_ivfx the filter already ran;"
[ -e "$IVZC/wt-q/.git" ] && _ivfx="$_ivfx wt-q still has its .git;"
_ivq -C "$IVZ" worktree list --porcelain | grep -q "^worktree $IVZD\$" || _ivfx="$_ivfx the line break does not spell the decoy;"
[ "$(_ivq -C "$IVZ" config branch.topic/feat2.merge)" = refs/heads/main ] || _ivfx="$_ivfx feat2 does not track main;"
[ "$(_ivq -C "$IVZ" rev-parse origin/topic/feat2)" = "$IVZ_F2" ] || _ivfx="$_ivfx feat2 is not pushed;"
_ivq -C "$IVZ" merge-base --is-ancestor origin/topic/diverge topic/diverge && _ivfx="$_ivfx origin/topic/diverge is behind the local branch;"
_ivq -C "$IVZC/wt-m3" diff-index --cached --quiet "$IVZ_X1" || _ivfx="$_ivfx wt-m3's index is not X1;"
[ "$(_ivq -C "$IVZC/wt-m3" rev-parse HEAD)" = "$IVZ_X2" ] || _ivfx="$_ivfx wt-m3's HEAD is not X2;"
_ivq -C "$IVZC/wt-m3" symbolic-ref -q HEAD >/dev/null && _ivfx="$_ivfx wt-m3 is not detached;"
_ivq -C "$IVZ" worktree list --porcelain | grep -q '\.lost/' && _ivfx="$_ivfx git still lists .lost;"
_ivq -C "$IVZ" ls-files -- "$IVZC/k*" | grep -q kept || _ivfx="$_ivfx k* does not glob to kept;"
[ "$(_ivq -C "$IV/pc1" config remote.origin.promisor)" = true ] || _ivfx="$_ivfx pc1 is no partial clone;"
# Asked with lazy fetching off, since asking would otherwise fetch it.
( export GIT_NO_LAZY_FETCH=1; _ivq -C "$IV/pc1" cat-file -e "$(_ivq -C "$IV/pc1" rev-parse origin/main:docs/handoff/pending/20260924T000000Z-gizmo.md)" ) 2>/dev/null \
  && _ivfx="$_ivfx pc1 already holds the section;"
[ -z "$_ivfx" ] && ok  "the fixture: gizmo holds each finding's shape, and neither partial clone holds the handoff section" \
                || bad "the fixture: gizmo holds each finding's shape, and neither partial clone holds the handoff section" "$_ivfx"

_ivz_runs
# The rows of one ref, exactly.
_ivz_sel() { LC_ALL=C awk -F'\t' -v r="$2" '$3 == r' "$1" > "$IV/sel"; }
_ivz_chk() {  # name file ref mode arg
  _ivz_sel "$2" "$3"
  if _iv_q "$4" "$5"; then ok "$1"; else bad "$1" "$(_iv_diag)"; fi; }
_ivz_det() { LC_ALL=C awk -F'\t' -v e="$1" '$8 ~ e { f = 1 } END { exit !(NR && f) }' "$IV/sel"; }

# Filters (a clean filter is a program the repository's config runs; git-lfs
# stores what it is handed): none runs, and a path one would have cleaned is
# not called uncommitted on its raw bytes.
[ -s "$IVZ_T1" ] && [ ! -e "$IVZX/filter-ran" ] && ok "no clean filter the repository configures runs, in any run" \
  || bad "no clean filter the repository configures runs, in any run" "$(_ivrows "$IVZ_T1" "the filter left $(wc -l < "$IVZX/filter-ran" 2>/dev/null | tr -d ' ') marks")"
_ivz_sel "$IVZ_T1" "$IVZC/wt-filter"
if _iv_q lack uncommitted && _iv_q word 0:unknown; then ok "a worktree whose only changed-looking file sits under a clean filter is not called uncommitted, and says unknown"
else bad "a worktree whose only changed-looking file sits under a clean filter is not called uncommitted, and says unknown" "$(_iv_diag)"; fi
# Worktree paths: a line break spells no second worktree, and a directory git
# lists whose .git file is gone is read as what it is.
if [ -s "$IVZ_T1" ] && ! LC_ALL=C awk -F'\t' -v r="$IVZD" '$3 == r { f = 1 } END { exit !f }' "$IVZ_T1" \
   && ! grep -qF -- "-C $IVZD " "$IVGIT_LOG"; then ok "a worktree whose path holds a line break makes no row of the directory the break spells, and no git runs there"
else bad "a worktree whose path holds a line break makes no row of the directory the break spells, and no git runs there" "$(grep -F -- "$IVZD" "$IVZ_T1" "$IVGIT_LOG" | head -n 3 | tr '\t\n' '|;')"; fi
_ivz_chk "a listed worktree whose .git file is gone is an orphan of the repository, not the checkout around it" "$IVZ_T1" "$IVZC/wt-q" hold orphan
_ivz_chk "and it is not landed" "$IVZ_T1" "$IVZC/wt-q" lack landed
_ivz_chk "and its row says git marks it prunable" "$IVZ_T1" "$IVZC/wt-q" word 8:prunable
_ivz_chk "the main worktree does not count its linked worktrees' and orphans' files as its own changes" "$IVZ_T1" "$IVZ" lack uncommitted
# Branches: the default branch is told by name, and a remote branch ahead of
# its local namesake is read.
_ivz_chk "a worktree on a branch tracking origin/main, pushed under its own name with an open pull request, is pr-open" "$IVZ_T1" "$IVZC/wt-feat2" hold pr-open
_ivz_chk "and not landed" "$IVZ_T1" "$IVZC/wt-feat2" lack landed
_ivz_chk "a branch tracking origin/main, pushed under its own name with no pull request, is unproposed" "$IVZ_T1" topic/feat3 hold unproposed
_ivz_chk "a remote branch that moved on from its local namesake, content not on main and no pull request, has a row, unproposed" "$IVZ_T1" origin/topic/diverge hold unproposed
_ivz_chk "a detached worktree whose index holds an earlier HEAD's tree leads with hazard:staged-revert" "$IVZ_T1" "$IVZC/wt-m3" lead hazard:staged-revert
_ivz_sel "$IVZ_T1" "$IVZC/wt-f2"
if _iv_q hold uncommitted && _ivz_det ', 0 of them holding content in no object'; then ok "an uncommitted worktree whose changed file's content an object holds says none of its content is in no object"
else bad "an uncommitted worktree whose changed file's content an object holds says none of its content is in no object" "$(_iv_diag)"; fi
# Orphans.
_ivz_chk "a directory named with a glob character is an orphan, not hidden by the tracked directory its name globs to" "$IVZ_T1" "$IVZC/k*" lead orphan
_ivz_sel "$IVZ_T1" "$IVZC/plain"
if _iv_q lead orphan && _ivz_det '^1 of 1 files'; then ok "a plain directory's orphan count leaves out what the repository's ignore file ignores"
else bad "a plain directory's orphan count leaves out what the repository's ignore file ignores" "$(_iv_diag)"; fi
_ivz_sel "$IVZ_T1" "$IVZC/ign"
if _iv_q lead orphan && _ivz_det '(^|; )1 of 1 ignored files hold content in no object'; then ok "an orphan's ignored file whose content is in no object is counted, not passed over"
else bad "an orphan's ignored file whose content is in no object is counted, not passed over" "$(_iv_diag)"; fi
_ivz_chk "a worktree pruned from a directory where git lists no worktree any more is still an orphan" "$IVZ_T1" "$IVZ/.lost/g1" lead orphan
# The host's records.
_ivz_chk "a live session in a non-ASCII directory, filed as Claude Code files it, makes it live" "$IVZ_T1" "$IVZ_JOSE" hold live
_ivz_chk "a live session in a directory whose record name Claude Code cuts at 200 makes it live" "$IVZ_T1" "$IVZ_LONG" hold live
_ivz_sel "$IVZ_T1" "$IVZC/wt-tab"
if _iv_q hold live && _iv_q lack question && _iv_q lack blocked; then ok "a live session whose file name holds a tab is live, and neither a question nor blocked"
else bad "a live session whose file name holds a tab is live, and neither a question nor blocked" "$(_iv_diag)"; fi
_ivz_chk "a newest session that is not JSON says unknown, rather than passing as ended on no question" "$IVZ_T1" "$IVZC/wt-garbage" word 0:unknown
_ivz_chk "a question whose note is cut inside a character is still a question" "$IVZ_T1" "$IVZC/wt-utf8" hold question
if [ -s "$IVZ_T1" ] && iconv -f UTF-8 -t UTF-8 < "$IVZ_T1" > /dev/null 2>&1; then ok "and every --tsv byte is valid UTF-8"
else bad "and every --tsv byte is valid UTF-8" "$(_ivrows "$IVZ_T1" "iconv rejects it")"; fi
_iv_selstate "$IVZ_T1" chip-unstarted
if grep -qF 'Title with C:\path' "$IV/sel" && ! LC_ALL=C grep -q "$(printf '\001')" "$IV/sel"; then ok "a chip title's backslash prints as a backslash, with no control byte"
else bad "a chip title's backslash prints as a backslash, with no control byte" "$(_iv_diag | od -c | head -n 3 | tr '\n' ' ')"; fi
# What gh cannot say.
# Spec §4.3 rule 5 and §8: under --no-gh a pushed tip's not reads unknown, so
# the row is undecided with content not not or partly: counted, not listed.
# The count is the view's own: it equals the --tsv rows of the same reading
# that are undecided (an unknown: headline, or states - or live alone) with
# content neither not nor partly, so a view that drops feat3 uncounted fails.
_ivx="$(LC_ALL=C awk '/nothing decided but unknown [0-9]/ { sub(/.*nothing decided but unknown /, ""); print; exit }' "$IVZ_H2")"
_ivy="$(LC_ALL=C awk -F'\t' '$1 != "cover" { h = $4; sub(/,.*/, "", h); if ((h ~ /^unknown:/ || $4 == "-" || $4 == "live") && $7 != "not" && $7 != "partly") n++ } END { print n + 0 }' "$IVZ_T2NG")"
_ivz_sel "$IVZ_T2NG" topic/feat3
[ -s "$IVZ_H2" ] && ! grep -qF topic/feat3 "$IVZ_H2" && [ -n "$_ivx" ] && [ "$_ivx" = "$_ivy" ] \
  && LC_ALL=C awk -F'\t' '$7 == "unknown" && $4 ~ /^unknown:/ { f = 1 } END { exit !f }' "$IV/sel" \
  && ok "under --no-gh the human view counts a pushed branch whose content cannot be confirmed off main, rather than listing it" \
  || bad "under --no-gh the human view counts a pushed branch whose content cannot be confirmed off main, rather than listing it" "count [$_ivx] derived [$_ivy] row [$(_iv_diag)] $(grep -F topic/feat3 "$IVZ_H2" | head -n 2 | tr '\n' ';')$(tail -n 4 "$IVZ_H2" | tr '\n' ';')"
_ivz_sel "$IVZ_T3" topic/feat3
if _iv_q lack unproposed && _iv_q word 0:unknown; then ok "when gh lists its limit of pull requests, a pushed branch with none among them is unknown, not unproposed"
else bad "when gh lists its limit of pull requests, a pushed branch with none among them is unknown, not unproposed" "$(_iv_diag)"; fi
[ ! -e "$IVH/.local/state" ] && [ -s "$IVZ_T1" ] && ok "what gh keeps of its own lands in no file under HOME" \
  || bad "what gh keeps of its own lands in no file under HOME" "$(_ivrows "$IVZ_T1" "$(find "$IVH/.local" -type f 2>/dev/null | head -n 2 | tr '\n' ' ')")"
# Scratch, signals and here-documents.
_ivz_sel "$IVZ_T4" "$IVZC/wt-clean"
if _iv_q lack uncommitted && [ -z "$(ls -A "$IVZC/wt-clean/tmpdir-here")" ]; then ok "with TMPDIR inside a clean worktree, that worktree is not called uncommitted, and nothing is left there"
else bad "with TMPDIR inside a clean worktree, that worktree is not called uncommitted, and nothing is left there" "$(_iv_diag)"; fi
( cd "$IVZ" || exit 97; ulimit -c 0
  unset FELIX_HOME FELIX_MEMORY GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_CEILING_DIRECTORIES
  export HOME="$IVH" TMPDIR="$IV/tq" PATH="$IVSTUB4:$IVSTUB:$PATH" XDG_CONFIG_HOME="$IVH/.config" GIT_CONFIG_NOSYSTEM=1 \
         GIT_ALLOW_PROTOCOL=file GIT_TERMINAL_PROMPT=0 GIT_CEILING_DIRECTORIES="$IV"
  exec perl -e '$SIG{QUIT} = "DEFAULT"; $SIG{INT} = "DEFAULT"; exec @ARGV or exit 127' "$IVF" inventory --tsv --no-host --repo "$IVZ" ) > /dev/null 2>&1 &
_ivzq=$!; _ivn=0
while [ ! -s "$IV/gh-slow.log" ] && [ "$_ivn" -lt 600 ] && kill -0 "$_ivzq" 2>/dev/null; do sleep 0.2; _ivn=$((_ivn + 1)); done
_ivx="$(ls -A "$IV/tq" | tr '\n' ' ')"
kill -QUIT "$_ivzq" 2>/dev/null; wait "$_ivzq" 2>/dev/null; _ivzqr=$?
if [ ! -s "$IV/gh-slow.log" ]; then bad "a QUIT mid-run leaves no scratch behind" "gh was never reached, so no signal was sent (rc $_ivzqr)"
elif [ -z "$_ivx" ]; then bad "a QUIT mid-run leaves no scratch behind" "no scratch was there to leave while gh ran"
else is "a QUIT mid-run leaves no scratch behind" "$(ls -A "$IV/tq" | tr '\n' ' ')" ""; fi
_iv_heredoc() { _ivcode "$IVLIB" "$IVLIBH" ${IVPARTS[@]+"${IVPARTS[@]}"} | grep -E '<<-?[[:space:]]*[A-Za-z_"'"'"']|<<<' | _ivwhere 'a here-document'; }
is  "no library feeds anything from a here-document or here-string, which bash 3.2 writes to a file outside the scratch" "$(_iv_heredoc)" ""
# Partial clones: nothing fetched, and what could not be read is unknown.
[ -s "$IVZ_P1" ] && [ "$(_ivz_pack "$IV/pc1")" = "$_ivz_pc1" ] && ok "reading a partial clone fetches nothing into it" \
  || bad "reading a partial clone fetches nothing into it" "$(_ivrows "$IVZ_P1" "$(diff <(printf '%s\n' "$_ivz_pc1") <(_ivz_pack "$IV/pc1") | head -n 4 | tr '\n' ';')")"
_iv_selstate "$IVZ_P2" handoff-pending
if [ -s "$IV/sel" ] && ! grep -qF 'no Next lines' "$IV/sel"; then ok "a pending section a partial clone cannot read is not said to have no Next lines"
else bad "a pending section a partial clone cannot read is not said to have no Next lines" "$(_iv_diag)"; fi
_ivz_after="$(_ivz_snap)"
[ -s "$IVZ_T1" ] && [ "$_ivz_after" = "$_ivz_before" ] && ok "no file under gizmo, its origin or the decoy changed across these runs" \
  || bad "no file under gizmo, its origin or the decoy changed across these runs" "$(diff <(printf '%s\n' "$_ivz_before") <(printf '%s\n' "$_ivz_after") | head -n 6 | tr '\n' ';')"
_ivx="$(grep -E 'bad substitution|syntax error|unbound variable|command not found|invalid option|not a valid identifier|division by 0|awk: |Permission denied' "$IV_ERR" | head -n 3 | tr '\n' ';')"
is  "no run wrote a shell or awk error to stderr, nor a failed redirection" "$_ivx" ""

