# Red has started (or is not to be): the N a record run under -j N handed it
# (part 0001) goes now, so that no part, unit or fixture sees it.
unset FELIX_TEST_RED_JOBS
# MEM, the session unset and resolve.sh moved here from the driver with
# _copy_content below, 2026-10-17, for the same 500 lines; they ran just
# before this part there, so they run in the same order here.
# Memory has lived outside any checkout since 2026-08-14, so the fixture needs a
# root of its own rather than a directory inside the fixture home.
#
# Exported, and that is not a detail. This suite drives the real CLI and the real
# hooks as child processes; an unexported value would leave every one of them
# resolving felix_mem_root to the default and writing the fixture's invented
# projects into the developer's own memory — which is both a corrupted test and
# a corrupted record, and neither would announce itself.
MEM="$TMP/memory"
export FELIX_MEMORY="$MEM"
mkdir -p "$MEM"

# No session, as on the CI runner. The gate files each catch under the session
# its shell was given, and the Stop hook asks a session only about its own, so
# a suite run from inside a session would file every fixture's catch under
# that session and judge the hooks differently from CI. Cases that need one
# set it where they need it.
unset CLAUDE_CODE_SESSION_ID

# Every lib that writes memory calls felix_mem_dir, which resolve.sh defines and
# which the CLI and both hooks always source first. The subshells below source
# one lib at a time, so without this they run under a load order production
# never has. Worth stating because of how that fails: bash reports "command not
# found" on stderr, the append is redirected to /dev/null, and the assertion
# then reads as "memory was not written" — a wrong answer about the code rather
# than about the test. Functions defined here are inherited by every subshell.
. "$REAL_HARNESS/lib/resolve.sh"

# _copy_content is defined here, at the head of the first part that calls it,
# and not in the driver: moved 2026-10-16 (contract C), when the driver's lib
# lines took it past 1040's 500 lines. This part is in _suite_preamble, so every
# copy of the driver keeps it.
# Every copy this suite takes of the real tree goes through here, and it copies
# CONTENT: what git tracks under the source, plus what is untracked and not
# ignored, because work not yet added is still work under test. What git ignores
# stays behind. `cp -R` copied a directory listing instead, residue included,
# and the fixtures below that commit such a copy as "main" and cut a cache entry
# from it then disagreed with themselves: measured 2026-09-19, a claude-flow
# hook had dropped .claude-flow/ into engine/harness — ignored, so git status
# stayed clean — and fifteen assertions failed, each leading with the judge and
# the plugin cache and carrying the directory's name only at the tail of a
# temporary path, which is where nobody reads. The mechanism, by experiment: the
# fixture's `git add -A` obeys the machine's GLOBAL excludes file, which named
# .claude-flow/, so the fixture's main left the stray out; the raw copy in the
# fixture's cache kept it; and the judge, which shuts the global file off on
# purpose, called the difference drift. A runner with no global excludes commits
# the stray on both sides and the judge, measured on that pair, reports nothing
# — so this was only ever red on a developer's machine. Production is not
# sensitive, measured at 0.49.122: felix_accepted_deploy_diff reads its source
# side from the commit, and felix_deploy_diff asks the repository's own ignore
# rules about the rest. It was sensitive once, and #86 is what ended that.
#
# --exclude-standard, global file included, deliberately: whatever this
# machine's git would refuse to add to a fixture is exactly what must not be
# carried into one.
#
# The git path is taken only when git TRACKS something under the source. "Is
# it inside a repository" is the wrong question, measured on the same day: the
# plugin cache, where a copy of this suite also sits, was inside a repository
# — a home directory under version control — that tracked none of it, and one ignore
# rule there would have listed an empty harness. Where git tracks nothing it
# has nothing to say, and the directory is copied whole, as it always was.
# A tracked file deleted from the working tree is listed by git and absent
# from disk, and it is skipped before tar is handed the list. Measured on
# bsdtar: tar does not stop on such a name — it archives the rest and exits
# non-zero — and under this suite's pipefail that exit becomes the copy's
# status, so a developer's unstaged deletion would read as a copy that
# failed. GNU tar was not there to measure; skipping means it is never asked.
# A skipped name is no failure of the loop either (R42): the body is an if, so the
# status of the loop is 0 when the last name git lists is one it skipped.
_copy_content() {   # <source dir> <dest dir>: dest holds what source holds, less what git ignores
  local src="$1" dest="$2" f arc rc
  # An empty source would be copied as "/." (the 18:04 incident at the
  # driver's REAL_HARNESS check), so a source that is not a directory copies nothing.
  [ -n "$src" ] && [ -d "$src" ] || {
    printf 'tests/run: _copy_content refused source [%s]: not a directory\n' "$src" >&2; return 1; }
  mkdir -p "$dest" || return 1
  if [ -n "$(git -C "$src" ls-files -c . 2>/dev/null | head -1)" ]; then
    # The archive is written whole to a file of this call's own, then read: an extractor
    # that stops at the end-of-archive marker (bsdtar) must not sit at the end of a pipe
    # under pipefail, where the writer's next write fails (R37).
    arc="$(mktemp "${TMP:-${TMPDIR:-/tmp}}/copy-content.XXXXXX")" || return 1
    ( cd "$src" && git ls-files -co --exclude-standard -z . \
        | while IFS= read -r -d '' f; do
            if [ -e "$f" ] || [ -L "$f" ]; then printf '%s\0' "$f"; fi
          done \
        | tar -c --null -T - -f "$arc" ); rc=$?
    [ "$rc" -eq 0 ] && { tar -x -f "$arc" -C "$dest"; rc=$?; }
    rm -f "$arc"
    return "$rc"
  else
    cp -R "$src/." "$dest/"
  fi
}

# The claim under test is that Felix governs a project it knows nothing about.
# So this suite never touches another governed project. It builds a throwaway Felix root holding
# a single invented project whose gate is a shell one-liner, in a checkout with
# no git remote, and drives the real CLI and the real hook against it.
#
# If Felix ever grows a hidden assumption about Python, about a remote naming
# scheme, or about another governed project specifically, these tests are where it surfaces.
# ---------------------------------------------------------------- fixture ----
# A Felix root with the real harness and one invented project.
FROOT="$TMP/felix"
mkdir -p "$FROOT/projects/widget" "$MEM/widget"
_copy_content "$REAL_HARNESS" "$FROOT/harness"

cat > "$FROOT/projects/widget/project.json" <<'EOF'
{
  "name": "widget",
  "remote_match": "example.com/widget",
  "gate": "sh -c 'test -f WIDGET.txt && echo widget-gate-ran'"
}
EOF
printf '# widget\n' > "$FROOT/projects/widget/CLAUDE.md"

# One row, deliberately the most boring true thing about this checkout: the
# marker that binds it. It must never come back `blind`, or every merge
# assertion in this file would be measuring the probe rather than the merge —
# so it reads a file the fixture creates and keeps, and if something does
# remove it the honest answer is `empty`, which blocks nothing.
printf 'marker\t-\t-\tls -1 .felix\ttest -f .felix\n' \
  > "$FROOT/projects/widget/probes.tsv"
cp "$FROOT/projects/widget/probes.tsv" "$TMP/probes.keep"

# And one admitted obligation, for the same reason: the merge boundary refuses
# a project that has admitted nothing, so every merge assertion below would
# otherwise be measuring the empty ledger. Always applicable, discharged by a
# command that cannot fail, grounded on nothing — the least an obligation can
# be while still being one.
printf 'fixture\tRELEASE_BLOCKING\tdeterministic\t-\ttrue\t-\ta fixture owes one thing, and it holds\n' \
  > "$FROOT/projects/widget/obligations.tsv"
cp "$FROOT/projects/widget/obligations.tsv" "$TMP/obligations.keep"

# The same for commissioning: one row a person answers, whose check reads the
# marker the fixture keeps, so the merge boundary is measuring the merge and
# not this table. The receipt it needs is stamped by _cm_stamp beside every
# green gate receipt below, because both are keyed to the tables the tests
# hand-edit, and a receipt for the wrong tables is exactly what must block.
printf 'marker\t-\t-\t-\t-\ttest -f .felix\t9\n' > "$FROOT/projects/widget/commissioning.tsv"
cp "$FROOT/projects/widget/commissioning.tsv" "$TMP/commissioning.keep"
_cm_stamp() { ( _r="${1:-$REPO}"; cd "$_r" && FELIX_HOME_DIR="$FROOT"; . "$FROOT/harness/lib/commission.sh"
                _o="$(felix_commission_run "$FROOT/projects/widget" "$_r" -)"
                felix_commission_receipt_write "$FROOT" "$FROOT/projects/widget" "$_r" "$_o" "" >/dev/null ); }

FELIX="$FROOT/harness/felix"
# Pin the home. Resolution consults ~/.felix-home, so without this the suite
# runs against whatever the machine has installed, writes test projects into it,
# and reports failures about the wrong tree. Observed exactly that.
export FELIX_HOME="$FROOT"

# A checkout with NO git remote, bound by marker file alone.
REPO="$TMP/some-customer-repo"
mkdir -p "$REPO/deep/nested"
( _fx_cd "$REPO" && git init -q -b main )
# macOS resolves /var to /private/var, and git reports the resolved path. Compare
# against what the filesystem actually calls this directory, not what mktemp said.
REPO="$(cd "$REPO" && pwd -P)"
printf 'widget\n' > "$REPO/.felix"
printf 'contents\n'  > "$REPO/WIDGET.txt"
