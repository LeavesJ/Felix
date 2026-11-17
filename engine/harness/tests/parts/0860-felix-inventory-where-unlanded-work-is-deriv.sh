printf '\nfelix inventory: where unlanded work is, derived from disk, git, gh and the host\n'
_iv_build
# ---- the fixture holds what the assertions below say it holds ------------
IV_FX="$IV/fx"
_ivfx=""
[ "$(_ivq -C "$IVW/wt-revert" rev-parse HEAD)" = "$IV_R2" ] || _ivfx="$_ivfx HEAD is not the adopted commit;"
_ivq -C "$IVW/wt-revert" diff-index --cached --quiet "$IV_R1" || _ivfx="$_ivfx the index is not the first tip;"
_ivq -C "$IVW/wt-revert" diff-index --cached --quiet "$IV_R2" && _ivfx="$_ivfx the index equals HEAD;"
_ivq -C "$IVM" reflog show --format=%H topic/revert > "$IV_FX" 2>&1
grep -qx "$IV_R1" "$IV_FX" || _ivfx="$_ivfx the branch reflog lacks the first tip;"
[ -z "$_ivfx" ] && ok  "the fixture: wt-revert's HEAD moved on while its index holds the branch's earlier tip, which the reflog records" \
                || bad "the fixture: wt-revert's HEAD moved on while its index holds the branch's earlier tip, which the reflog records" "$_ivfx"
_ivfx=""
_ivq -C "$IVM" worktree list --porcelain > "$IV_FX"
[ "$(grep -c '^branch refs/heads/topic/shared$' "$IV_FX")" = 2 ] || _ivfx="$_ivfx topic/shared is not in two worktrees;"
grep -q 'orphan-' "$IV_FX" && _ivfx="$_ivfx git still lists an orphan;"
{ [ -f "$IVW/orphan-edit/.git" ] && [ -f "$IVW/orphan-clean/README.md" ]; } || _ivfx="$_ivfx an orphan lost its files;"
[ "$(_ivq -C "$IVM" symbolic-ref refs/remotes/origin/HEAD)" = refs/remotes/origin/main ] || _ivfx="$_ivfx origin/HEAD is not origin/main;"
[ "$(_ivq -C "$IVM" remote get-url origin)" = https://github.com/acme/widget.git ] || _ivfx="$_ivfx origin does not name GitHub;"
[ -z "$_ivfx" ] && ok  "the fixture: one branch sits in two worktrees, git lists neither orphan, and origin names GitHub with origin/HEAD at main" \
                || bad "the fixture: one branch sits in two worktrees, git lists neither orphan, and origin names GitHub with origin/HEAD at main" "$_ivfx"
_ivfx=""
_ivq -C "$IVM" merge-base --is-ancestor "$IV_S1" origin/main && _ivfx="$_ivfx the squash is an ancestor;"
[ "$(_ivq -C "$IVM" rev-parse "$IV_S1:src/squash.txt")" = "$(_ivq -C "$IVM" rev-parse origin/main:src/squash.txt)" ] || _ivfx="$_ivfx main lacks the squash content;"
_ivq -C "$IVM" merge-base --is-ancestor "$IV_P1" "$IV_P2" || _ivfx="$_ivfx P1 does not precede P2;"
[ "$(_ivq -C "$IVM" rev-parse "$IV_P1:src/precedes.txt")" = "$(_ivq -C "$IVM" rev-parse origin/main:src/precedes.txt)" ] && _ivfx="$_ivfx main holds P1's content;"
[ "$(_ivq -C "$IVM" rev-parse "$IV_X1:src/superseded.txt")" = "$(_ivq -C "$IVM" rev-parse origin/main:src/superseded.txt)" ] || _ivfx="$_ivfx main lacks superseded.txt;"
_ivq -C "$IVM" cat-file -e origin/main:src/closed.txt 2>/dev/null && _ivfx="$_ivfx main holds closed.txt;"
[ "$(_ivq -C "$IVM" rev-parse origin/topic/pr-hold)" = "$IV_H1" ] || _ivfx="$_ivfx origin/topic/pr-hold is not the head;"
[ "$(_ivq -C "$IVM" rev-parse origin/topic/precedes)" = "$IV_P2" ] || _ivfx="$_ivfx origin/topic/precedes is not P2;"
[ "$(_ivq -C "$IVM" rev-parse origin/topic/revert)" = "$IV_R2" ] || _ivfx="$_ivfx origin/topic/revert is not the adopted commit;"
for _ivn in topic/unpushed topic/partly topic/dup-one topic/dup-two; do
  [ "$(_ivq -C "$IVM" rev-list --count "$_ivn" --not --remotes)" = 1 ] || _ivfx="$_ivfx $_ivn is not one commit on no remote;"
done
_ivq -C "$IVM" rev-parse -q --verify refs/heads/topic/remote-only >/dev/null && _ivfx="$_ivfx topic/remote-only has a local copy;"
[ -z "$_ivfx" ] && ok  "the fixture: squash, precedes, superseded and closed hold main's content as built, and each push and non-push is where it was meant" \
                || bad "the fixture: squash, precedes, superseded and closed hold main's content as built, and each push and non-push is where it was meant" "$_ivfx"
_ivfx=""
for _ivn in src/squash.txt README.md; do
  [ "$(_ivq -C "$IVW/wt-same" hash-object "$_ivn")" = "$(_ivq -C "$IVM" rev-parse "origin/main:$_ivn")" ] || _ivfx="$_ivfx wt-same's $_ivn is not main's;"
done
_ivq -C "$IVM" cat-file -e origin/main:src/old.txt 2>/dev/null && _ivfx="$_ivfx main still has old.txt;"
_ivq -C "$IVW/wt-same" check-ignore -q debug.log || _ivfx="$_ivfx debug.log is not ignored;"
_ivq -C "$IVW/wt-dirty" status --porcelain > "$IV_FX"
[ "$(tr '\n' ';' < "$IV_FX")" = 'M  src/core.txt;?? src/untracked-new.txt;' ] || _ivfx="$_ivfx wt-dirty's status is [$(tr '\n' ';' < "$IV_FX")];"
_ivq -C "$IVW/wt-squash" status --porcelain > "$IV_FX"
[ -s "$IV_FX" ] && _ivfx="$_ivfx wt-squash is not clean;"
[ -z "$_ivfx" ] && ok  "the fixture: wt-same's changes are main's content and an ignored file, and wt-dirty holds a staged edit and an untracked file only" \
                || bad "the fixture: wt-same's changes are main's content and an ignored file, and wt-dirty holds a staged edit and an untracked file only" "$_ivfx"
if [ "$IV_JQ" = 1 ]; then
  _ivfx="$(PATH="$IVSTUB:$PATH" gh pr list --state all --json number,headRefName --jq 'length') $(PATH="$IVSTUB:$PATH" gh api "repos/acme/widget/commits/$IV_Y1/status" --jq .state) $(PATH="$IVSTUB:$PATH" gh pr list --json number --jq 'length') $(PATH="$IVSTUB:$PATH" gh api "repos/acme/widget/commits/$IV_H1/status" --jq .state)"
  is "the fixture: the gh stand-in lists nine pull requests, five open, with felix/ready on one head and not on another" "$_ivfx" "9 success 5 pending"
else
  skip "the fixture: the gh stand-in lists nine pull requests, five open, with felix/ready on one head and not on another" "no jq for the gh stand-in"
fi
PATH="$IVSTUB:$PATH" git --no-optional-locks -C "$IVM" rev-parse HEAD >/dev/null
has "the fixture: the git stand-in logs its calls and runs the real git" "$(cat "$IVGIT_LOG")" "--no-optional-locks -C $IVM rev-parse HEAD"
: > "$IVGH_LOG"; : > "$IVGIT_LOG"

