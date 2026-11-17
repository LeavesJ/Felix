printf '\na base ref that is behind its remote\n'
_widget_repo_build
# #74, and the sibling of the section below. There the base ref was current and
# the merge-base was frozen; here the base REF itself is behind.
#
# Every command defaults to base="main", and `main` is a local ref. In a
# worktree it is a SHARED local ref naming whatever the primary checkout last
# pulled — and a worktree cannot check main out, so nothing in that workflow
# ever advances it. Observed on this repository: local main sat three merges
# behind origin/main while work continued in a worktree.
#
# It fails in BOTH directions, which is what separates it from the rest of the
# family. Over-reporting is the #51 symptom by a second route. Under-reporting
# is new and worse: an evidence rule can be satisfied by a file that is in the
# diff only BECAUSE the base is stale, which is an all-clear nothing earned.
STALE="$TMP/stalebase"; mkdir -p "$STALE"
( _fx_cd "$STALE" && git init -q -b main
  git config user.email t@t; git config user.name t
  printf 'a\n' > a.txt; git add -A; git commit -qm one
  # main stays at one. origin/main advances to two, as a fetch would leave it.
  git checkout -q -b ahead
  printf 'b\n' > b.txt; git add -A; git commit -qm two
  git update-ref refs/remotes/origin/main HEAD
  git checkout -q -b feat
  printf 'c\n' > c.txt; git add -A; git commit -qm work
  git branch -q -D ahead ) >/dev/null 2>&1
STALE="$(cd "$STALE" && pwd -P)"

is "the fixture really has a base ref behind its remote" \
   "$( cd "$STALE" && [ "$(git rev-parse main)" = "$(git rev-parse origin/main)" ] && echo same || echo behind )" \
   "behind"

# felix_base_ref is what every command should resolve its base through.
_bref() { ( cd "$STALE" && . "$FROOT/harness/lib/resolve.sh"
            felix_base_ref "$STALE" "$1" 2>/dev/null || printf 'NONE' ); }
# 2026-10-18 (judge refs): felix_base_ref now returns the FULL name of the ref it
# chose, since the short name origin/main is read by git after tags and local
# branches any session can plant. The ref chosen is the same.
is "a bare branch name prefers the remote-tracking ref" "$(_bref main)" "refs/remotes/origin/main"
# And only when that ref exists. A sha, a HEAD~n, or a purely local branch must
# be taken exactly as given — rewriting those would invent a base nobody named.
is "a revision expression is taken as given"  "$(_bref 'HEAD~1')" "HEAD~1"
# 2026-10-18 (judge refs): a branch that lives only here is returned by its full name.
is "a local-only branch is taken by its full name" "$(_bref feat)"     "refs/heads/feat"
is "a base that names nothing is refused"     "$(_bref no-such)"  "NONE"

_stale_paths() { ( cd "$STALE" && . "$FROOT/harness/lib/resolve.sh"
                   felix_changed_paths "$STALE" "$(felix_base_ref "$STALE" main)" ); }
is "so the branch is not blamed for what the remote already had" \
   "$(_stale_paths)" "c.txt"

# And the call sites, because the six assertions above pin the LIBRARY and #65
# was a fix that every library assertion passed while the caller stayed broken.
# A command that resolves nothing would satisfy all of them.
printf 'widget\n' > "$STALE/.felix"
_stale_cmd() { ( cd "$STALE" && "$FELIX" "$@" 2>&1 ); }

# The reported base is the ref actually compared, not the name typed. Printing
# `main` while diffing origin/main would be the same answer wearing a lie.
has "classify names the ref it compared"  "$(_stale_cmd classify --base main)" "origin/main"
# A second call site, because one proves the line and not the pattern. The
# widget has no evidence table this early in the file, so this seeds a rule and
# takes it away again rather than relying on one the later sections own.
[ -f "$FROOT/projects/widget/evidence.tsv" ] && cp "$FROOT/projects/widget/evidence.tsv" "$TMP/ev.stale.keep"
printf 'anything\t.\t^tests?/\tevery change needs a test\n' > "$FROOT/projects/widget/evidence.tsv"
has "and evidence does too"               "$(_stale_cmd evidence --base main)" "origin/main"
rm -f "$FROOT/projects/widget/evidence.tsv"
[ -f "$TMP/ev.stale.keep" ] && mv "$TMP/ev.stale.keep" "$FROOT/projects/widget/evidence.tsv"
# The payoff: b.txt belongs to the remote, not to this branch.
case "$(_stale_cmd classify --base main)" in
  *b.txt*) bad "and the remote's own file is not listed against the branch" \
               "$(_stale_cmd classify --base main)" ;;
  *)       ok  "and the remote's own file is not listed against the branch" ;;
esac
has "while the branch's own file still is" "$(_stale_cmd classify --base main)" "c.txt"
rm -f "$STALE/.felix"

printf '\nstacked on a squashed base\n'
# #51. felix merge squashes, so merging a branch's base does NOT advance
# merge-base(main, branch) — the squash commit is not a descendant of the branch.
# Three-dot therefore keeps blaming the stacked branch for every path its base
# touched, permanently, even though main now holds those exact bytes.
#
# Observed on #50 stacked on #49: a documentation change classified red because
# it inherited engine/.claude-plugin/plugin.json from the branch below it.
#
# The fixture is the smallest thing that reproduces it, and the file the base
# adds is a workflow on purpose: .github/workflows is the `execute` channel, so
# the over-report is not only a wrong tier — it escalates a docs-only branch to
# the founder as writing outside the tree.
STK="$TMP/stacked"; mkdir -p "$STK"
( _fx_cd "$STK" && git init -q -b main
  git config user.email t@t; git config user.name t
  printf 'base\n' > base.txt; git add -A; git commit -qm init
  git checkout -q -b feat-a
  mkdir -p .github/workflows; printf 'on: push\n' > .github/workflows/ci.yml
  git add -A; git commit -qm "A: adds a workflow"
  git checkout -q -b feat-b
  printf 'notes\n' > NOTES.md; git add -A; git commit -qm "B: docs only"
  # Squashed, exactly as felix merge does it. A plain merge would advance the
  # merge-base and the bug would not exist.
  git checkout -q main; git merge -q --squash feat-a; git commit -qm "A squashed (#1)"
  git checkout -q feat-b ) >/dev/null 2>&1
STK="$(cd "$STK" && pwd -P)"
printf 'widget\n' > "$STK/.felix"

# The premise, asserted rather than assumed: the merge-base really is frozen
# behind main. If this stops being true the rest of the section proves nothing.
is "the squash leaves the merge-base behind main" \
   "$( cd "$STK" && [ "$(git merge-base main HEAD)" = "$(git rev-parse main)" ] && echo same || echo behind )" \
   "behind"

_stk_paths() { ( cd "$STK" && . "$FROOT/harness/lib/resolve.sh"
                 felix_changed_paths "$STK" main ); }
is "a stacked branch is not blamed for what its base already merged" \
   "$(_stk_paths)" "NOTES.md"

_stk_esc() { ( cd "$STK" && . "$FROOT/harness/lib/escape.sh"; . "$FROOT/harness/lib/obligations.sh"
               felix_escapes "$FROOT/projects/widget" main "$STK" ); }
case "$(_stk_esc)" in
  *execute*) bad "and its base's workflow is not escalated as this branch's escape" "$(_stk_esc)" ;;
  *)         ok  "and its base's workflow is not escalated as this branch's escape" ;;
esac

# The control that keeps this honest: the branch's OWN escape must still fire.
# A fix that simply narrowed everything would pass both assertions above and
# quietly stop enforcing.
( _fx_cd "$STK" && mkdir -p .github/workflows && printf 'on: pull_request\n' > .github/workflows/own.yml
  git add -A && git commit -qm "B: adds its own workflow" ) >/dev/null 2>&1
has "but a workflow this branch adds itself still escapes" "$(_stk_esc)" "execute"
has "and it is named"                                      "$(_stk_esc)" "own.yml"
( _fx_cd "$STK" && git reset -q --hard HEAD~1 )

# And an ordinary unstacked branch is untouched by any of this.
UNS="$TMP/unstacked"; mkdir -p "$UNS"
( _fx_cd "$UNS" && git init -q -b main
  git config user.email t@t; git config user.name t
  printf 'base\n' > base.txt; git add -A; git commit -qm init
  git checkout -q -b feat; printf 'x\n' > src.txt; git add -A; git commit -qm work ) >/dev/null 2>&1
UNS="$(cd "$UNS" && pwd -P)"
is "an unstacked branch reports exactly what it changed" \
   "$( cd "$UNS" && . "$FROOT/harness/lib/resolve.sh"; felix_changed_paths "$UNS" main )" "src.txt"

# A rename is two paths. git detects renames by default and then names only
# where a file went, so a table renamed away was asked about under its new
# name, which no rule knows. Committed, staged and unstaged, since those are
# the three sources and each has its own diff.
REN="$TMP/renamed"; mkdir -p "$REN/projects/p"
( _fx_cd "$REN" && git init -q -b main
  git config user.email t@t; git config user.name t
  printf 'Bash\tgit push --force\tforce push drops commits\nBash\tgit commit --no-verify\tno\n' > projects/p/deny.tsv
  git add -A; git commit -qm init; git checkout -q -b feat
  git mv projects/p/deny.tsv projects/p/deny-archived.tsv; git commit -qm "archive the deny table" ) >/dev/null 2>&1
REN="$(cd "$REN" && pwd -P)"
_renpaths() { ( cd "$REN" && . "$FROOT/harness/lib/resolve.sh"; felix_changed_paths "$REN" main | tr '\n' ' ' ); }
is  "a committed rename lists the name it left as well as the one it took" \
    "$(_renpaths)" "projects/p/deny-archived.tsv projects/p/deny.tsv "
( _fx_cd "$REN" && git reset -q --soft HEAD~1 ) >/dev/null 2>&1
is  "and so does a staged one" "$(_renpaths)" "projects/p/deny-archived.tsv projects/p/deny.tsv "
( _fx_cd "$REN" && git reset -q HEAD -- . && git add projects/p/deny-archived.tsv ) >/dev/null 2>&1
has "and an unstaged deletion beside a staged copy names the table it removed" "$(_renpaths)" "projects/p/deny.tsv"
( _fx_cd "$REN" && git add -A && git commit -qm "archive the deny table" ) >/dev/null 2>&1
# What the rename was hiding: the enforcing table's rows go, and the verifier
# that guards them sees it.
has "renaming an enforcing table away fires the verifier on the table it removed" \
    "$( cd "$REN" && . "$FROOT/harness/lib/escape.sh"; . "$FROOT/harness/lib/obligations.sh"
        felix_escapes "$FROOT/projects/widget" main "$REN" )" "verifier	projects/p/deny.tsv"

printf '\nevidence policy\n'
{
  printf 'unit\t^src/\t^tests?/\tcode changes need a test\n'
  printf 'db\t\\.sql$\t^tests?/.*db\tschema changes need a database test\n'
} > "$FROOT/projects/widget/evidence.tsv"

mkdir -p "$REPO/src"; printf 'x\n' > "$REPO/src/thing.js"; _stage
out="$( cd "$REPO" && "$FELIX" evidence --base HEAD~1 2>&1 )"
has "code with no test is a gap" "$out" "[!] unit"
has "and reads as a requirement"  "$out" "code changes need a test"
( cd "$REPO" && "$FELIX" evidence --base HEAD~1 --strict >/dev/null 2>&1 ); rc=$?
is "--strict exits non-zero on a gap" "$rc" "1"
( cd "$REPO" && "$FELIX" evidence --base HEAD~1 >/dev/null 2>&1 ); rc=$?
is "without --strict it only reports"  "$rc" "0"
_reset

mkdir -p "$REPO/src" "$REPO/tests"
printf 'x\n' > "$REPO/src/thing.js"; printf 'x\n' > "$REPO/tests/thing.test.js"; _stage
out="$( cd "$REPO" && "$FELIX" evidence --base HEAD~1 2>&1 )"
has "a matching test closes the gap" "$out" "[x] unit"
has "untouched surfaces are n/a"     "$out" "[-] db"
_reset

printf 'notes\n' > "$REPO/README.md"; _stage
out="$( cd "$REPO" && "$FELIX" evidence --base HEAD~1 2>&1 )"
has "a docs-only change requires nothing" "$out" "No evidence gaps"

# #63. The advisory half of #56, and it is not purely advisory.
#
# felix_changed_paths sends git's exit-128 to /dev/null, so a base that names
# nothing produced an empty path list and every evidence row fell to n/a —
# "this change does not touch that surface", asserted about a diff nobody
# computed — and the command signed off with "No evidence gaps." #56 closed the
# merge path; these three read the same emptiness and still answer.
#
# Same fixture, same clean tree, only the base changed.
ev_unk="$( cd "$REPO" && "$FELIX" evidence --base no-such-ref 2>&1 )"
case "$ev_unk" in
  *"No evidence gaps"*) bad "an unresolvable base is not an evidence all-clear" "$ev_unk" ;;
  *)                    ok  "an unresolvable base is not an evidence all-clear" ;;
esac
case "$ev_unk" in
  *"does not touch that surface"*)
    bad "and claims nothing about surfaces it never compared" "$ev_unk" ;;
  *) ok "and claims nothing about surfaces it never compared" ;;
esac
has "and names the base it could not resolve" "$ev_unk" "no-such-ref"

# classify. `No changes against X` reads as a finding about the branch; it is a
# report that the question was never asked.
cl_unk="$( cd "$REPO" && "$FELIX" classify --base no-such-ref 2>&1 )"
has "an unresolvable base classifies as unknown" "$cl_unk" "unknown"
case "$cl_unk" in
  *"tier:  green"*|*"tier:  yellow"*|*"tier:  red"*)
    bad "and never reports a tier it could not compute" "$cl_unk" ;;
  *) ok "and never reports a tier it could not compute" ;;
esac

# The one that writes, and the reason this is not filed as cosmetic. cmd_pr
# reduces the same empty findings to a tier and then LABELS the pull request
# risk-<tier>. felix_classify_tier returns green for no findings, and cmd_pr
# defaults to green again if that came back empty. Green is the tier that can
# auto-merge, so an unresolvable base labelled a branch as safe to merge itself.
# Preview only here — no --create, so nothing is written.
pr_unk="$( cd "$REPO" && "$FELIX" pr --base no-such-ref 2>&1 )"
case "$pr_unk" in
  *"tier:     green"*) bad "an unresolvable base never labels a pr green" "$pr_unk" ;;
  *)                   ok  "an unresolvable base never labels a pr green" ;;
esac

# The library level, so the fix cannot be a message change in three commands.
_ev_at() { ( cd "$REPO" && . "$FROOT/harness/lib/evidence.sh"
             felix_evidence_check "$FROOT/projects/widget" "$1" "$REPO" ); }
_cl_at() { ( cd "$REPO" && . "$FROOT/harness/lib/classify.sh"
             felix_classify_diff "$FROOT/projects/widget" "$1" "$REPO" ); }
has "felix_evidence_check reports unknown, not n/a" "$(_ev_at no-such-ref)" "unknown"
has "felix_classify_diff reports unknown, not empty" "$(_cl_at no-such-ref)" "unknown"
# Not knowing outranks everything — receipt.sh's stated precedence, because a
# verdict computed from inputs nobody read is the confident wrong answer.
is "and the tier reducer agrees" \
   "$( . "$FROOT/harness/lib/classify.sh"; felix_classify_tier "$(_cl_at no-such-ref)" )" "unknown"
# The good case is not collateral.
has "a base that resolves still classifies normally" "$(_cl_at HEAD~1)" "green"
_reset

# Green tier plus an evidence gap. Unreachable with the default rules, since
# green covers docs and tests while evidence fires on src. It becomes reachable
# the moment a project declares any src path green, which is allowed, so the
# branch is exercised here rather than shipped untested.
printf 'green\tpath\t^src/safe/\tdeclared safe by this project\n' \
  >> "$FROOT/projects/widget/risk.tsv"
mkdir -p "$REPO/src/safe"; printf 'x\n' > "$REPO/src/safe/x.js"; _stage
out="$( cd "$REPO" && "$FELIX" classify --base HEAD~1 2>&1 )"
has "green tier is still reported"        "$out" "tier:  green"
has "but auto-merge is withheld on a gap" "$out" "Not auto-merge eligible"
_reset

printf '\nengine and home are separate\n'
# A plugin install is a frozen copy of the whole repository. Treating its
# projects/ as a home would govern from a constitution frozen at install time and
# write memory into a directory the next plugin update deletes, both silently.
FAKE_CACHE="$TMP/.claude/plugins/cache/felix/felix/0.1.0"
mkdir -p "$FAKE_CACHE/projects/stale" "$TMP/plainrepo/projects/live"
out="$( unset FELIX_HOME; HOME="$TMP/nohome"; . "$FROOT/harness/lib/resolve.sh"; felix_home "$FAKE_CACHE" )"
case "$out" in
  *"plugins/cache"*) bad "a plugin cache is never treated as home" "$out" ;;
  *) ok "a plugin cache is never treated as home" ;;
esac
out="$( unset FELIX_HOME; HOME="$TMP/nohome"; . "$FROOT/harness/lib/resolve.sh"; felix_home "$TMP/plainrepo" )"
is "a plain checkout with projects/ is a home" "$out" "$TMP/plainrepo"
out="$( FELIX_HOME="$TMP/explicit"; . "$FROOT/harness/lib/resolve.sh"; felix_home "$TMP/plainrepo" )"
is "an explicit FELIX_HOME wins" "$out" "$TMP/explicit"
mkdir -p "$TMP/pointed"
out="$( unset FELIX_HOME; HOME="$TMP/withpointer"; mkdir -p "$HOME"
        printf '%s\n' "$TMP/pointed" > "$HOME/.felix-home"
        . "$FROOT/harness/lib/resolve.sh"; felix_home "$TMP/plainrepo" )"
is "the pointer file beats a sibling projects/" "$out" "$TMP/pointed"

# The test above covers felix_home's use of it. This covers the predicate
# itself, because #55 gave it a second caller: felix install must not treat a
# deployed copy as the tree it is deploying FROM, and the two must agree. A
# frozen copy is byte-identical to its checkout and carries no marker, so where
# it sits is the only evidence there is.
_pc() { ( . "$FROOT/harness/lib/resolve.sh"
          felix_plugin_copy "$1" && printf 'copy' || printf 'checkout' ); }
is "a cache path is a plugin copy" \
   "$(_pc "$HOME/.claude/plugins/cache/felix/felix/0.49.9")" "copy"
# The marketplaces/ half of the pattern, which nothing reached before.
is "a marketplaces path is one too" \
   "$(_pc "$HOME/.claude/plugins/marketplaces/felix/engine")" "copy"
is "an ordinary checkout is not"      "$(_pc "$TMP/plainrepo/engine")" "checkout"
is "and neither is a worktree"        "$(_pc "$TMP/r/.claude/worktrees/w/engine")" "checkout"
is "an empty path is not a copy"      "$(_pc "")"                     "checkout"
# One definition, asserted rather than intended. Two copies of this pattern is
# how it drifts, and a drifted copy fails open in both callers at once: a stale
# home governs from a frozen constitution, and install certifies the cache
# against itself. Counted in the library, where it belongs.
is "the pattern is written down exactly once" \
   "$(grep -c 'plugins/cache/\*|' "$FROOT/harness/lib/resolve.sh")" "1"

# #65. The tree being operated on is not the tree the script lives in — the same
# rule #55 established for felix install, and cmd_bootstrap breaks it one
# function along. It asks "what GitHub repo should CI check out to fetch the
# harness" and answers by running `git remote get-url origin` in whatever
# directory the running script sits in. From the deployed CLI that is the plugin
# cache, which has no remote, so it printed "none, CI cannot fetch the harness"
# about an engine whose remote exists — and on a machine whose home directory is
# itself a git repo with an origin, it would print THAT slug instead, straight
# into a generated workflow's `repository:` beside a deploy key.
#
# HOME is redirected for every call. felix_marketplace_root reads
# $HOME/.claude/plugins/known_marketplaces.json, and on this machine that names
# the real Felix checkout — so without this the assertions would pass by reading
# the developer's own install rather than the fixture.
_ESRC="$TMP/enginesrc"
mkdir -p "$_ESRC/engine/harness"
# Resolved, for the reason stated where $REPO is built: macOS spells /var as
# /private/var and git reports the resolved form, so felix_repo_root returns a
# different string for the same directory than mktemp handed out. Comparing
# against the unresolved name failed here on exactly that.
_ESRC="$(cd "$_ESRC" && pwd -P)"
printf '#!/usr/bin/env bash\nexit 0\n' > "$_ESRC/engine/harness/felix"
chmod +x "$_ESRC/engine/harness/felix"
( _fx_cd "$_ESRC" && git init -q -b main \
  && git remote add origin https://github.com/someone/felixsrc.git )
_ECACHE="$TMP/ehome/.claude/plugins/cache/felix/felix/0.1.0"
mkdir -p "$_ECACHE/harness" "$TMP/ehome" "$TMP/nowhere"

# $1 = cwd to stand in, $2 = the engine the script thinks it is
_esrc() { ( cd "$1" && HOME="$TMP/ehome" . "$FROOT/harness/lib/resolve.sh"
            HOME="$TMP/ehome" felix_engine_source "$2" "$3" 2>/dev/null || printf 'NONE' ); }
_eslug() { ( cd "$1" && HOME="$TMP/ehome" . "$FROOT/harness/lib/resolve.sh"
             . "$FROOT/harness/lib/detect.sh"
             s="$(HOME="$TMP/ehome" felix_engine_source "$2" "$3" 2>/dev/null)" \
               && felix_repo_slug "$s" || printf 'NONE' ); }

is "an engine that is a checkout is its own source" \
   "$(_esrc "$_ESRC" "$_ESRC/engine" "$_ESRC")" "$_ESRC/engine"
# The defect: the script is the cache, the checkout is elsewhere and reachable.
is "a deployed engine resolves the checkout, not itself" \
   "$(_esrc "$_ESRC" "$_ECACHE" "$_ESRC")" "$_ESRC/engine"
is "and the slug comes from the checkout's remote" \
   "$(_eslug "$_ESRC" "$_ECACHE" "$_ESRC")" "someone/felixsrc"
# The honest negative. No checkout anywhere is a real answer, and different from
# guessing one — a home that happens to be a git repo must not qualify just by
# having an origin, only by carrying an engine.
is "no reachable checkout resolves to nothing" \
   "$(_esrc "$TMP/nowhere" "$_ECACHE" "$TMP/nowhere")" "NONE"
# One definition. cmd_install grew this resolution first; a second copy in
# cmd_bootstrap is how the two drift, and a drifted copy points CI at the wrong
# repository.
is "the resolution is written down exactly once" \
   "$(grep -c 'felix_marketplace_root)" "$(felix_repo_root' "$FROOT/harness/felix" "$FROOT/harness/lib/resolve.sh" 2>/dev/null | awk -F: '{s+=$2} END {print s+0}')" "1"

# And the call site, which is where the defect actually is. The five assertions
# above pin felix_engine_source and every one of them passed with cmd_bootstrap
# still calling felix_repo_slug "$FELIX_ROOT" — a fix nothing would notice being
# reverted. Caught by neutering the call site and watching the suite stay green,
# which is the check this repository keeps learning to run.
#
# The CLI has to be a deployed copy for the bug to exist at all, so it is run
# from a cache path rather than from $FELIX.
_EDEPLOY="$TMP/ehome/.claude/plugins/cache/felix/felix/0.2.0"
mkdir -p "$_EDEPLOY"
cp -R "$FROOT/harness" "$_EDEPLOY/harness"
printf 'widget\n' > "$_ESRC/.felix"
bs_out="$( cd "$_ESRC" && HOME="$TMP/ehome" FELIX_HOME="$FROOT" \
             "$_EDEPLOY/harness/felix" bootstrap 2>&1 )"
# The `felix repo:` line specifically, not the output. The product's own `repo:`
# line carries the same slug in this fixture, so matching the whole output
# passed against the neutered call site — the label-not-the-value mistake, one
# assertion after correcting the same mistake in the pr preview.
is "bootstrap names the checkout's repo, not the cache's absence" \
   "$(printf '%s\n' "$bs_out" | sed -n 's/^felix repo: *//p')" "someone/felixsrc"
case "$bs_out" in
  *"CI cannot fetch the harness"*)
    bad "and never reports no remote for an engine that has one" "$bs_out" ;;
  *) ok "and never reports no remote for an engine that has one" ;;
esac
# The pin, through the same call site. The checkout has no commit yet, so there
# is nothing origin could hold; then it has one that origin/main names.
has "bootstrap with no commit to pin says the workflow gets the placeholder" \
    "$(printf '%s\n' "$bs_out" | sed -n 's/^felix ref: *//p')" "{{FELIX_REF}}"
# gh from here on is a stub that answers nothing, so labels and protection
# fail where no network is asked.
mkdir -p "$TMP/pinghbin"; printf '#!/bin/sh\nexit 1\n' > "$TMP/pinghbin/gh"; chmod +x "$TMP/pinghbin/gh"
_bspin() { ( cd "$_ESRC" && HOME="$TMP/ehome" FELIX_HOME="${1:-$FROOT}" PATH="$TMP/pinghbin:$PATH" \
               "$_EDEPLOY/harness/felix" bootstrap ${2:+"$2"} 2>&1 ) | sed -n 's/^felix ref: *//p'; }
( _fx_cd "$_ESRC" && git -c user.name=t -c user.email=t@t commit -q --allow-empty -m pin \
  && git update-ref refs/remotes/origin/main HEAD ) >/dev/null 2>&1
is  "and pins the source checkout's commit once origin's default branch holds it" \
    "$(_bspin)" "$(git -C "$_ESRC" rev-parse HEAD)"
# And writes it. The header and the renderer's argument are two uses of one
# variable, so the header passed with the argument dropped at the call site;
# the file CI runs is what is read here.
_bspin "$FROOT" --yes >/dev/null
is  "and the gate workflow bootstrap writes checks Felix out at that commit" \
    "$(grep -A1 'repository: someone/felixsrc' "$_ESRC/.github/workflows/gate.yml" 2>/dev/null | sed -n 2p | tr -d ' ')" \
    "ref:'$(git -C "$_ESRC" rev-parse HEAD)'"
rm -rf "$_ESRC/.github" "$_ESRC/.claude"
# A project that lives in the engine's checkout, as every project in a Felix
# home does, is pinned only at a commit that holds it: CI resolves it from the
# Felix it checked out. Uncommitted first, then merged.
mkdir -p "$_ESRC/projects"; cp -R "$FROOT/projects/widget" "$_ESRC/projects/widget"
has "a project no commit on the default branch holds yet is not pinned" \
    "$(_bspin "$_ESRC")" "{{FELIX_REF}}"
( _fx_cd "$_ESRC" && git add projects && git -c user.name=t -c user.email=t@t commit -q -m widget \
  && git update-ref refs/remotes/origin/main HEAD ) >/dev/null 2>&1
is  "and is pinned once the default branch holds it" \
    "$(_bspin "$_ESRC")" "$(git -C "$_ESRC" rev-parse HEAD)"
rm -f "$_ESRC/.felix"

printf '\nincident loop\n'
mkdir -p "$REPO/src" "$REPO/migrations" "$REPO/docs"
printf 'x\n' > "$REPO/src/thing.js"
printf 'x\n' > "$REPO/migrations/003.sql"
printf 'x\n' > "$REPO/docs/guide.md"
( _fx_cd "$REPO" && git add -A >/dev/null 2>&1
  git -c user.name=t -c user.email=t@t commit -qm "incident fixture" >/dev/null 2>&1 )

# A trace never carries repo-relative paths. It carries wherever the process ran.
TRACE_RED='Error: boom
    at handler (/app/migrations/003.sql:12:3)
    at run (/home/runner/work/x/x/src/thing.js:44:9)'
out="$(cd "$REPO" && printf '%s\n' "$TRACE_RED" | "$FELIX" incident 2>&1)"
has "extracts files from container-absolute paths" "$out" "src/thing.js"
has "and from CI-absolute paths"                   "$out" "migrations/003.sql"
has "severity derives from the risk rules"         "$out" "severity:  red"
has "and says not to fix it unattended"            "$out" "SEV1"
has "names the suspect commit"                     "$out" "incident fixture"
has "states that urgency does not bypass gates"    "$out" "Urgency does not bypass"

TRACE_GREEN='Warning raised in /srv/app/docs/guide.md line 3'
out="$(cd "$REPO" && printf '%s\n' "$TRACE_GREEN" | "$FELIX" incident 2>&1)"
has "a docs-only signal is routine" "$out" "severity:  green"

# A brief built from nothing would be believed. Refusing is the correct output.
out="$(cd "$REPO" && printf 'Segfault in /usr/lib/libc.so.6\n' | "$FELIX" incident 2>&1)"
has "refuses to invent a brief from unknown paths" "$out" "No file in this checkout"
case "$out" in
  *"severity:"*) bad "and reports no severity for it" "$out" ;;
  *) ok "and reports no severity for it" ;;
esac

out="$(cd "$REPO" && printf '%s\n' "$TRACE_RED" | "$FELIX" incident 2>&1)"
has "lists what the fix must prove" "$out" "the fix will have to prove"
_reset

