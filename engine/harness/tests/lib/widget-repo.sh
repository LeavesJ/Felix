# tests/lib/widget-repo.sh: the widget repository's risk table and root commit,
# and the three helpers that stage, classify and undo a commit in it.
# Used by 0080 (builds), 0090 0100 0110 0120 0370 0480 0500 0510 0520 0570 0580
# 0600 and those of 0200 0210 0230 0280 0320 that need REPO committed.
# Moved from parts/0080-risk-classification.sh: _classify, _stage and _reset
# from lines 6-9 (verbatim); _widget_repo_build reproduces lines 2-5.
# Definitions only. The builder is guarded step by step: in the serial run 0070
# has already put the table there and 0080's call makes the root commit, so each
# later call finds every step done and does nothing.

_classify() { ( cd "$REPO" && "$FELIX" classify --base HEAD~0 2>/dev/null ); }
_stage() { ( _fx_cd "$REPO" && git add -A >/dev/null 2>&1 && \
             git -c user.name=t -c user.email=t@t commit -qm c >/dev/null 2>&1 ); }
_reset() { ( _fx_cd "$REPO" && git reset -q --hard HEAD~1 >/dev/null 2>&1 ); }

# _widget_repo_build: three steps, each skipped when already done.
#   1. the shipped risk table is copied into the widget project (when it has none);
#   2. a copy of that table is kept at $TMP/risk.keep (when there is none);
#   3. $REPO gets its root commit "base" (when HEAD does not resolve yet).
# Needs TMP, FROOT, REPO and REAL_HARNESS; it runs no felix command.
_widget_repo_build() {
  [ -f "$FROOT/projects/widget/risk.tsv" ] \
    || cp "$REAL_HARNESS/templates/risk.tsv" "$FROOT/projects/widget/risk.tsv"
  [ -f "$TMP/risk.keep" ] || cp "$FROOT/projects/widget/risk.tsv" "$TMP/risk.keep"
  ( _fx_cd "$REPO" && git rev-parse -q --verify HEAD >/dev/null 2>&1 ) && return 0
  ( _fx_cd "$REPO" && git add -A >/dev/null 2>&1
    git -c user.name=t -c user.email=t@t commit -qm base >/dev/null 2>&1 )
}
