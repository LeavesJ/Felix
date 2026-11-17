printf '\nwhat a revert cannot undo\n'
_widget_repo_build
# A tier used to be a function of which file you touched, and that is what sent
# a one-line dependency-floor correction to the founder for a day. The question
# a stop must answer is not "is this file important" but "does merging write
# something outside this tree that a revert cannot reach".
#
# Escapes are engine constants. A project may add to them and may never declare
# one away, so this is not a table anybody can weaken into agreement.
_esc() { ( cd "$REPO" && . "$FROOT/harness/lib/escape.sh"; . "$FROOT/harness/lib/obligations.sh"
           felix_escapes "$FROOT/projects/widget" HEAD~1 "$REPO" ); }
# L-25 again: this section appends rows to the widget's table, and every later
# assertion in the file reads that table. Snapshot it here, restore at the end,
# and assert the restore rather than trusting it.
cp "$FROOT/projects/widget/risk.tsv" "$TMP/risk.keep"

printf 'notes and more notes\n' > "$REPO/README.md"; _stage
is "a documentation change escapes nothing" "$(_esc)" ""
_reset

# Merging this runs the job, holding every secret the repository has. Reverting
# restores the YAML; it does not un-run the job or un-read the key.
mkdir -p "$REPO/.github/workflows"; printf 'on: push\n' > "$REPO/.github/workflows/ci.yml"; _stage
has "a workflow change escapes as execute" "$(_esc)" "execute"

# Merging this grants Felix a power it then holds in every session after it.
# The file IS the permission — writing it is granting it — and that is exactly
# what a `git add -A` swept into a pull request whose own body said the grant
# was ungranted. Nothing stopped it, because nothing named the file. A revert
# takes the word back and does not un-run the sessions Felix ran with it, which
# is the marker's own argument one file over. Any change fires, in either
# direction: a revoke is the safe direction and costs one look.
mkdir -p "$REPO/projects/anyproj"; printf 'commission\n' > "$REPO/projects/anyproj/autonomy"; _stage
has "a grant of authority escapes"                      "$(_esc)" "authority"
_reset
mkdir -p "$REPO/projects/anyproj"; printf 'deadbeef\n' > "$REPO/projects/anyproj/autonomy.commission"; _stage
has "and so does the stamp that says what it was read against" "$(_esc)" "authority	projects/anyproj/autonomy.commission"
_reset

# The marker is the binding: break it and every hook resolves nothing, which
# is not something a revert of the word undoes for the sessions that ran while
# it was wrong. A tier alone would have said "look carefully" to nobody in
# particular, so the row carries a channel and stops the merge.
printf 'widget\n\n' > "$REPO/.felix"; _stage
has "a change to the project marker escapes" "$(_esc)" "verifier"
_reset

# The table of exemptions. Every other enforcing table narrows by removal and
# the channel fires on removal only. ecosystem.tsv narrows by ADDITION — an
# allow row is a file the check stops reading, a mute row a word it stops
# seeing — so a branch could add the exemption for the very file it was about
# to break invariant 1 in, and merge green. Any change to it fires.
printf '# kind\tpath\twords\tnote\n' > "$REPO/ecosystem.tsv"; _stage
printf 'allow\tlib/x.sh\tcargo\tprose\n' >> "$REPO/ecosystem.tsv"; _stage
has "adding a row to the ecosystem table escapes as verifier" "$(_esc)" "verifier"
has "and says why growth is the narrowing direction there" "$(_esc)" "exempt"
_reset
printf '# a reworded comment\n' >> "$REPO/ecosystem.tsv"; _stage
is "a comment added to it is still free" "$(_esc | grep -c verifier)" "0"
_reset; _reset

# The qualification table. Its rows are the controls the gate's `qualified`
# check holds each checker to, and the gate reads the table the branch edited,
# so a branch that deletes a control or flips what it expects is judged by the
# table it weakened and passes. A contract review found it on 2026-09-22, and a
# scratch clone confirmed that nothing on the merge path looked. Adding a
# control is free, as it is in every enforcing table but the exemptions.
_qesc_head="$( cd "$REPO" && git rev-parse --short HEAD )"
_qesc() { printf 'demo\t! grep -rqI BAD .\t%s\t%s\tprintf BAD > b.txt\n' "$1" "$2"; }
_qesc_edit() { awk -F'\t' -v OFS='\t' "$1" "$REPO/projects/thing/qualification.tsv" > "$TMP/qesc" \
                 && mv "$TMP/qesc" "$REPO/projects/thing/qualification.tsv"; _stage; }
mkdir -p "$REPO/projects/thing"
{ printf '# checker\tcommand\tcontrol\texpect\tmutation\n'
  _qesc violation fail; _qesc restoration pass
} > "$REPO/projects/thing/qualification.tsv"; _stage
_qesc alternate fail >> "$REPO/projects/thing/qualification.tsv"; _stage
is "adding a control to the qualification table escapes nothing" "$(_esc)" ""
_reset
_qesc_edit '$3 != "violation"'
has "deleting a control from it escapes as verifier" "$(_esc)" "verifier	projects/thing/qualification.tsv"
_reset
_qesc_edit '$3 == "violation" { $4 = "pass" } 1'
has "and so does flipping the verdict a control expects" "$(_esc)" "verifier	projects/thing/qualification.tsv"
_reset
_qesc_edit '$3 == "violation" { $5 = "true" } 1'
has "and so does swapping its mutation for one that changes nothing" "$(_esc)" "verifier	projects/thing/qualification.tsv"
_reset
_qesc_edit '$3 == "violation" { $0 = "# " $0 } 1'
has "and so does commenting a control out" "$(_esc)" "verifier	projects/thing/qualification.tsv"
_reset
printf '# a reworded comment\n' >> "$REPO/projects/thing/qualification.tsv"; _stage
is "while a comment added to it is free" "$(_esc | grep -c verifier)" "0"
_reset; _reset
is "and the fixture is back where the qualification block found it" \
   "$( cd "$REPO" && git rev-parse --short HEAD )" "$_qesc_head"

# #56. The same workflow, judged against a base git cannot name. Every git error
# in felix_changed_paths goes to /dev/null, so an unresolvable base produced no
# paths and no complaint, and felix_escapes returned "nothing escaped" from its
# `[ -n "$paths" ] || return 0` line — before a single channel was consulted,
# `execute` included, which risk.tsv's own header calls unconditional.
#
# It stayed latent because both governed repositories are on `main`. It fires on
# a --base typo, on a repository whose default branch is `master`, on a clone
# with no local `main`, and on the next governed project. The precondition is a
# clean tree, because a dirty one still yields a working-tree diff — and a clean
# tree is exactly what felix merge requires, so that softens nothing.
_esc_at() { ( cd "$REPO" && . "$FROOT/harness/lib/escape.sh"; . "$FROOT/harness/lib/obligations.sh"
              felix_escapes "$FROOT/projects/widget" "$1" "$REPO" ); }
has "a base that does not resolve is unknown, not clean" "$(_esc_at no-such-ref)" "unknown"
case "$(_esc_at no-such-ref)" in
  *execute*) bad "and does not name a channel it never got to consult" "$(_esc_at no-such-ref)" ;;
  *)         ok  "and does not name a channel it never got to consult" ;;
esac
# The lesson felix_kernel_dir already carried: `git rev-parse --verify <40-hex>`
# exits 0 for a sha no repository holds, because a full-length hex string is a
# syntactically valid object name and --verify alone checks syntax. Peeling to a
# commit is what makes it an existence test. Without `^{commit}` this reads as a
# resolvable base and clears the merge exactly as before.
has "a full-length sha nothing holds is unknown too" \
    "$(_esc_at 0000000000000000000000000000000000000000)" "unknown"
# And the good case is not collateral: a base that resolves still answers.
has "a base that resolves still names the channel" "$(_esc)" "execute"
# An empty base is a deliberate no-base — working tree only — and not a failure
# to resolve one. felix_changed_paths has always meant it that way.
is "an empty base is not reported as unknown" "$(_esc_at '')" ""
_reset

mkdir -p "$REPO/migrations"; printf 'x\n' > "$REPO/migrations/003.sql"; _stage
has "a migration escapes as durable" "$(_esc)" "durable"
_reset

# The trailing marker is a scanner exclusion, and it sits in a shell comment so
# it never reaches leak.py — the fixture file still holds a clean credential for
# the scanner under test to find. Without it Felix's own gate goes red on this
# line, which is the scanner working on the suite that tests the scanner.
printf 'api_key = "sk-ant''-api03-BBBBBBBBBBBBBBBBBBBBBBBB"\n' > "$REPO/leak.py"; _stage  # must_flag
has "a credential in added lines escapes as disclose" "$(_esc)" "disclose"
_reset

# The verifier channel. A green produced by a narrowed judge certifies itself,
# so shrinking what judges is the one edit that cannot be checked by the thing
# it shrank. Adding to a table is free; removing from it is not.
#
# The table has to be inside the repository being merged for a diff to contain
# it. For a governed product that is never true — its tables live in the Felix
# home — so this channel fires when Felix's *own* repository is the one being
# merged, which is exactly where those tables are edited. Indirect, and complete.
_block_head="$( cd "$REPO" && git rev-parse --short HEAD )"
mkdir -p "$REPO/projects/thing"
{ printf '# tier\tkind\tpattern\treason\n'
  printf 'red\tpath\t^secrets/\tsecret material\n'
  printf 'red\tpath\t^auth/\tauthorization model\n'
} > "$REPO/projects/thing/risk.tsv"; _stage
printf 'green\tpath\t^extra/\tan added row\n' >> "$REPO/projects/thing/risk.tsv"; _stage
is "adding a row to an enforcing table escapes nothing" "$(_esc)" ""
_reset

# JSON punishes line-identity comparison. Adding a key rewrites the line above
# it, because that line gains a comma — so a naive shrink test reads every
# addition as a removal, and fires on the single most common edit anyone makes
# to project.json. Observed on the commit that declared consumers.
printf '{\n  "name": "thing",\n  "gate": "g.sh"\n}\n' > "$REPO/projects/thing/project.json"; _stage
printf '{\n  "name": "thing",\n  "gate": "g.sh",\n  "consumers": "none"\n}\n' > "$REPO/projects/thing/project.json"; _stage
is "adding a key to json escapes nothing" "$(_esc)" ""
_reset
printf '{\n  "name": "thing"\n}\n' > "$REPO/projects/thing/project.json"; _stage
has "but removing one still escapes" "$(_esc)" "verifier"
_reset; _reset
sed '/^red.path.\^auth/d' "$REPO/projects/thing/risk.tsv" > "$TMP/rt" && mv "$TMP/rt" "$REPO/projects/thing/risk.tsv"
_stage
has "removing one escapes as verifier" "$(_esc)" "verifier"
has "and names the table"              "$(_esc)" "projects/thing/risk.tsv"
_reset
# L-25: restore the fixture and assert the restore, or every later assertion in
# this file runs against a repository this block quietly changed.
_reset
# By head, not by _esc — and this is #56 caught in the suite's own fixture.
#
# This assertion used to read `is "..." "$(_esc)" ""`, and _esc scans against
# HEAD~1. Measured, not inferred: at this point the fixture is at its ROOT
# commit, depth 1, so HEAD~1 names nothing. git diff exits 128,
# felix_changed_paths sent that to /dev/null, and the scan returned empty for
# every possible state of the repository. The guard L-25 wrote to catch a
# quietly changed fixture could not observe one, and it passed for four months
# on an instrument that had gone blind at exactly the state it was checking.
# Adding felix_base_resolves is what made it visible.
#
# A head comparison is the claim this line was always making, and unlike the
# scan it can fail. The porcelain check is the half _esc could still see —
# uncommitted drift — kept rather than dropped.
is "and the repository is back to where it started" \
   "$( cd "$REPO" && git rev-parse --short HEAD )" "$_block_head"
is "and nothing is left uncommitted under it" \
   "$( cd "$REPO" && git status --porcelain )" ""

# Confinement, which is the whole reason PR #4 should not have waited. The
# manifest is dual-use: it declares dependencies AND configures the gate. So the
# row stays, and stops firing only when every changed line is a version
# constraint and the package names are the same on both sides.
{ printf 'red\tpath\t^pyproject\\.toml$\tmanifest is also gate config\tverifier\t'
  printf '^[-+][[:space:]]*"?[A-Za-z0-9._-]+[[:space:]]*[<>=!~^,"]\n'
} >> "$FROOT/projects/widget/risk.tsv"
printf '[project]\ndependencies = [\n  "anthropic>=0.40",\n]\n' > "$REPO/pyproject.toml"; _stage
printf '[project]\ndependencies = [\n  "anthropic>=0.120",\n]\n' > "$REPO/pyproject.toml"; _stage
is "a version bump alone escapes nothing" "$(_esc)" ""
_reset

# The evil twin: same file, same PR shape, one extra line that deletes tests
# from the gate without touching a single test.
printf '[project]\ndependencies = [\n  "anthropic>=0.120",\n]\n[tool.pytest.ini_options]\naddopts = "--ignore=tests/test_judgment.py"\n' > "$REPO/pyproject.toml"; _stage
has "the same file with an unconfined line escapes" "$(_esc)" "pyproject.toml"
_reset; _reset
cp "$TMP/risk.keep" "$FROOT/projects/widget/risk.tsv"

# A verifier row counts rather than compares. The suite is the thing that
# judges, so weakening it must stop — but comparing line identity would fire on
# every refactor and on every ordinary edit, and a stop that fires constantly is
# one people route around. What must not go down is the number of assertions.
{ printf 'yellow\tpath\t^suite\\.sh$\tweakening the suite is how a gate stops being one\tverifier\t'
  printf 'count:^[[:space:]]*(ok|is|has) \n'
} >> "$FROOT/projects/widget/risk.tsv"
printf 'ok one\nis two\nhas three\n' > "$REPO/suite.sh"; _stage
printf 'ok one\nis two\nhas three\nok four\n' > "$REPO/suite.sh"; _stage
is "adding an assertion escapes nothing" "$(_esc)" ""
_reset
printf 'ok one\nis two\n' > "$REPO/suite.sh"; _stage
has "removing one escapes as verifier" "$(_esc)" "verifier"
_reset
# Rewriting every line while keeping the count is a refactor, not a weakening.
printf 'ok ONE\nis TWO\nhas THREE\n' > "$REPO/suite.sh"; _stage
is "rewriting assertions without losing any escapes nothing" "$(_esc)" ""
_reset; _reset
cp "$TMP/risk.keep" "$FROOT/projects/widget/risk.tsv"

# #77 item 2, against the SHIPPED gate and the SHIPPED confine rather than a
# stand-in, because the defect is a property of that exact file's shape.
#
# The confine is anchored to line start. Three of the gate's seven checks report
# mid-line — `[ -z "$BAD" ] && pass syntax || {...}`, the same for executable,
# and `; then pass secret` / `else fail secret` — so they can be deleted whole
# without the count dropping. Measured: the count is 9 before, and 9 after
# `sed 34d` removes the entire syntax report. The reason column on that row
# reads "a gate that cannot fail is not a gate".
#
# A `check <name>` marker line would NOT fix this, which is why it is not what
# landed. It detects deleting a whole check block and leaves the marker standing
# when only the reporting line goes — the smaller and more deniable weakening,
# and the exact shape the issue describes.
REAL_GATE="$(cd "$REAL_HARNESS/../.." && pwd)/projects/felix/gate.sh"
if [ -f "$REAL_GATE" ]; then
  cp "$TMP/risk.keep" "$FROOT/projects/widget/risk.tsv"
  printf 'yellow\tpath\t^projects/[^/]+/gate\\.sh$\ta gate that cannot fail is not a gate\tverifier\tcount:^[[:space:]]*(pass|fail|check) \n' \
    >> "$FROOT/projects/widget/risk.tsv"
  mkdir -p "$REPO/projects/thing"
  cp "$REAL_GATE" "$REPO/projects/thing/gate.sh"; _stage

  # Every check the gate reports must be behind the confine. Named individually
  # so a failure says WHICH one slipped out rather than that a number moved.
  #
  # ENUMERATED FROM THE GATE, not listed here. This was seven names typed by
  # hand, and it went stale the first time the gate grew an eighth check: the
  # new one was outside the confine and no assertion said so, while seven `ok`
  # lines printed. That is the same defect the coverage table exists to catch
  # and the same one the `executable` check above already records — a list of
  # things to check is a list that stops matching what exists — arriving in the
  # test written to keep the gate honest.
  #
  # Read before the loop, because the loop rewrites the file it would read.
  _GCHECKS="$(grep -oE '^[[:space:]]*(pass|fail) [a-z][a-z-]*' "$REPO/projects/thing/gate.sh" \
              | awk '{print $2}' | LC_ALL=C sort -u | tr '\n' ' ')"
  [ -n "$_GCHECKS" ] || bad "the gate reports checks this suite can enumerate" \
                            "no 'pass <name>' or 'fail <name>' lines in $REAL_GATE"
  for _c in $_GCHECKS; do
    _n_before="$(grep -cE '^[[:space:]]*(pass|fail|check) ' "$REPO/projects/thing/gate.sh")"
    grep -vE "^[[:space:]]*(pass|fail) $_c\$" "$REPO/projects/thing/gate.sh" \
      | grep -vE "^[[:space:]]*(pass|fail) $_c;" > "$TMP/gt" && mv "$TMP/gt" "$REPO/projects/thing/gate.sh"
    _n_after="$(grep -cE '^[[:space:]]*(pass|fail|check) ' "$REPO/projects/thing/gate.sh")"
    [ "$_n_after" -lt "$_n_before" ] \
      && ok "the $_c check is behind the verifier confine" \
      || bad "the $_c check is behind the verifier confine" \
             "removing its report left the count at $_n_after"
    cp "$REAL_GATE" "$REPO/projects/thing/gate.sh"
  done

  # And end to end: deleting one must actually fire the channel, not merely move
  # a number. This is the assertion #77 asks for by name.
  grep -v 'pass syntax' "$REPO/projects/thing/gate.sh" | grep -v 'fail syntax' > "$TMP/gt" \
    && mv "$TMP/gt" "$REPO/projects/thing/gate.sh"; _stage
  has "and deleting the syntax check escapes as verifier" "$(_esc)" "verifier"
  has "naming the gate it was removed from" "$(_esc)" "projects/thing/gate.sh"
  _reset; _reset
  cp "$TMP/risk.keep" "$FROOT/projects/widget/risk.tsv"
else
  skip "the syntax check is behind the verifier confine" "no shipped gate"
fi

# A row with no channel is advisory. Every table written before this column
# existed is exactly that, and must keep classifying without ever stopping a
# merge on its own.
printf 'red\tpath\t^legacy/\tno channel named\n' >> "$FROOT/projects/widget/risk.tsv"
mkdir -p "$REPO/legacy"; printf 'x\n' > "$REPO/legacy/a.txt"; _stage
is "a red row naming no channel stops nothing" "$(_esc)" ""
out="$( cd "$REPO" && "$FELIX" classify --base HEAD~1 2>&1 )"
has "but it still classifies red" "$out" "tier:  red"
_reset
cp "$TMP/risk.keep" "$FROOT/projects/widget/risk.tsv"

# `unknown` is the engine's word for "nothing was scanned", and felix merge
# prints a whole paragraph off it saying no finding describes the branch. A
# table that could declare that word would make a row which DID fire render as
# a scan that never ran — the same false all-clear #56 is about, one layer up.
# Renamed rather than skipped, because a project may add to the escapes and may
# never declare one away.
printf 'red\tpath\t^reserved/\ttrying to wear the reserved name\tunknown\n' \
  >> "$FROOT/projects/widget/risk.tsv"
mkdir -p "$REPO/reserved"; printf 'x\n' > "$REPO/reserved/a.txt"; _stage
has "a table declaring the reserved channel still stops the merge" \
    "$(_esc)" "trying to wear the reserved name"
case "$(_esc)" in
  unknown[[:space:]]*) bad "but cannot impersonate an unscanned diff" "$(_esc)" ;;
  *)                   ok  "but cannot impersonate an unscanned diff" ;;
esac
# Inline rather than via _blk, which this file does not define until the merging
# section below. The claim is at the merge layer, so it is asserted there.
_resv_blk="$( cd "$REPO" && . "$FROOT/harness/lib/escape.sh"; . "$FROOT/harness/lib/obligations.sh"
              . "$FROOT/harness/lib/evidence.sh"; . "$FROOT/harness/lib/verify.sh"
              felix_merge_blockers "$FROOT/projects/widget" HEAD~1 "$REPO" "$FROOT" )"
has "and it reaches merge as an escape, not as unknown" "$_resv_blk" "escape"
# On the kind field, not on a substring: `declared-unknown` ends in the reserved
# word, so a glob for it matched the very rename that proves the fix works.
is "and merge does not call it an unscanned diff" \
   "$(printf '%s\n' "$_resv_blk" | awk -F'\t' '$1=="unknown"{print "found"}')" ""
_reset
cp "$TMP/risk.keep" "$FROOT/projects/widget/risk.tsv"

is "the widget's table is exactly as this section found it" \
   "$(diff -q "$TMP/risk.keep" "$FROOT/projects/widget/risk.tsv" >/dev/null && echo same)" "same"

