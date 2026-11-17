printf '\nstack provisioning\n'
_cmstub_build; _plain_build
# Classification is where the safety policy lives, so that is what is asserted.
# These rows never install anything: the two that would are deliberately fake.
{
  printf 'plugin\tsuperpowers@claude-plugins-official\t-\tlow\talways\n'
  printf 'plugin\tfelix-test-absent@nowhere\t-\tlow\tbilling\n'
  printf 'plugin\tfelix-test-dangerous@nowhere\t-\thigh\talways\n'
} > "$FROOT/projects/widget/stack.tsv"

out="$(cd "$REPO" && "$FELIX" stack plan 2>&1)"
case "$out" in
  *"blocked"*"felix-test-dangerous"*) ok "high risk classifies as blocked" ;;
  *) bad "high risk classifies as blocked" "$out" ;;
esac
case "$out" in
  *"dormant"*"felix-test-absent"*) ok "undeclared capability classifies as dormant" ;;
  *) bad "undeclared capability classifies as dormant" "$out" ;;
esac
# Present needs the plugin installed, which the CLI existing does not say. A
# fresh cloud VM has the CLI and no plugin, so there felix said install, which
# was right, and this failed; asked of the list felix reads, it skips instead.
_sp_have=0
has_claude && case "$(claude plugin list 2>/dev/null)" in
  *superpowers@claude-plugins-official*) _sp_have=1 ;;
esac
if [ "$_sp_have" -eq 1 ]; then
  has "already-installed rows report present" "$out" "present"
elif has_claude; then
  skip "already-installed rows report present" "superpowers is not installed on this machine"
else
  skip "already-installed rows report present" "no claude CLI here"
fi

# A bundled plugin is present. It is a `<name>@inline` key in ~/.claude.json
# and appears in no plugin list, so the row read absent and was installed on
# every run, which the cli refuses. A fixture home with the key and no cli.
INLH="$TMP/inline-home"; mkdir -p "$INLH"
printf '{ "pluginUsage": { "anthropic-skills@inline": {} } }\n' > "$INLH/.claude.json"
printf 'plugin\tanthropic-skills\t-\tlow\talways\n' >> "$FROOT/projects/widget/stack.tsv"
out="$(cd "$REPO" && HOME="$INLH" PATH=/usr/bin:/bin "$FELIX" stack plan 2>&1)"
case "$out" in
  *"present"*"anthropic-skills"*) ok "a bundled plugin reads present with no cli at all" ;;
  *) bad "a bundled plugin reads present with no cli at all" "$out" ;;
esac
grep -v 'anthropic-skills' "$FROOT/projects/widget/stack.tsv" > "$TMP/stack.tmp"; mv "$TMP/stack.tmp" "$FROOT/projects/widget/stack.tsv"

# A tier the policy cannot read is not a licence. The old plan tested only for
# the literal string "high", so every other value fell through to the install
# branch: an empty column, a typo, and `HIGH` in capitals were all installable
# unattended. Nothing exploited it, and nothing would have reported it either.
# Routing the decision through one fail-closed policy is what closed it, so it
# is asserted here rather than left as a property of the refactor.
{
  printf 'plugin\tfelix-test-typo@nowhere\t-\thgih\talways\n'
  printf 'plugin\tfelix-test-shouty@nowhere\t-\tHIGH\talways\n'
  printf 'plugin\tfelix-test-blank@nowhere\t-\t\talways\n'
} >> "$FROOT/projects/widget/stack.tsv"
out="$(cd "$REPO" && "$FELIX" stack plan 2>&1)"
for _bad in felix-test-typo felix-test-shouty felix-test-blank; do
  # Scoped to the row's own line. Matched against the whole report, the glob
  # finds the word "install" in some other row and passes for the wrong reason.
  _badline="$(printf '%s\n' "$out" | grep -- "$_bad" | head -1)"
  case "$_badline" in
    *blocked*) ok  "an unreadable tier does not install: $_bad" ;;
    "")        bad "an unreadable tier does not install: $_bad" "no verdict at all" ;;
    *)         bad "an unreadable tier does not install: $_bad" "$_badline" ;;
  esac
done
has "and says the tier is what it could not read" "$out" "not a tier and a grounding this policy recognises"
grep -v 'felix-test-typo\|felix-test-shouty\|felix-test-blank' "$FROOT/projects/widget/stack.tsv" > "$TMP/stack.tmp"
mv "$TMP/stack.tmp" "$FROOT/projects/widget/stack.tsv"
is "and the fixture is restored" "$(grep -c 'felix-test-typo' "$FROOT/projects/widget/stack.tsv")" "0"

# A row carries its grounding in a sixth column, and the policy reads it.
# The decision behind this: the engine writes stack.tsv rows itself, and a row
# it wrote after reading a plugin must not read back next run as a row a
# person wrote — because person-written is the one grounding that installs
# medium unattended. A row with no sixth column is a person's (or a
# template's) and reads DECLARED, which is what every row was until now.
{
  printf 'plugin\tfelix-test-obs-medium@nowhere\t-\tmedium\talways\tOBSERVED\n'
  printf 'plugin\tfelix-test-dec-medium@nowhere\t-\tmedium\talways\tDECLARED\n'
  printf 'plugin\tfelix-test-bare-medium@nowhere\t-\tmedium\talways\n'
} >> "$FROOT/projects/widget/stack.tsv"
out="$(cd "$REPO" && "$FELIX" stack plan 2>&1)"
_pl() { printf '%s\n' "$out" | grep -- "$1" | head -1; }
case "$(_pl felix-test-obs-medium)" in *blocked*) ok "a medium row the engine grounded waits for a person" ;; *) bad "a medium row the engine grounded waits for a person" "$(_pl felix-test-obs-medium)" ;; esac
has  "and says so in the policy's words"                    "$(_pl felix-test-obs-medium)" "a person decides"
case "$(_pl felix-test-dec-medium)" in *install*) ok "a medium row a person declared installs, as it always has" ;; *) bad "a medium row a person declared installs, as it always has" "$(_pl felix-test-dec-medium)" ;; esac
case "$(_pl felix-test-bare-medium)" in *install*) ok "and a row with no grounding column is a person's" ;; *) bad "and a row with no grounding column is a person's" "$(_pl felix-test-bare-medium)" ;; esac
grep -v 'felix-test-obs-medium\|felix-test-dec-medium\|felix-test-bare-medium' "$FROOT/projects/widget/stack.tsv" > "$TMP/stack.tmp"
mv "$TMP/stack.tmp" "$FROOT/projects/widget/stack.tsv"
is "and the fixture is restored" "$(grep -c 'felix-test-.*-medium' "$FROOT/projects/widget/stack.tsv")" "0"

out="$(cd "$REPO" && "$FELIX" stack apply 2>&1)"
has "apply without --yes changes nothing" "$out" "Nothing changed"

# The safety property: no flag promotes a high-risk row into the apply set.
# Through CMSTUB, because the superpowers row above is real: on a machine that
# lacks it, --yes installed it into the real ~/.claude with the real claude.
out="$(cd "$REPO" && PATH="$CMSTUB:$PATH" "$FELIX" stack apply --yes 2>&1)"
case "$out" in
  *"installed  plugin felix-test-dangerous"*)
    bad "--yes never installs high risk" "high-risk row was applied" ;;
  *) ok "--yes never installs high risk" ;;
esac
has "and says why it was left alone" "$out" "No flag installs those"

printf '\nthe one install policy\n'
# felix_admit is the single place that decides whether something may be
# installed with nobody present. It was three places: stack.sh's
# FELIX_RISK_AUTO, which auto-applies low and medium; discover.sh's adopt,
# which declares low and refuses medium; and ready --fix, which reached across
# into stack.sh's helper. Two of those disagreed about medium.
#
# The disagreement was not a bug and is not collapsed here. A person who writes
# a medium row into stack.tsv has decided something the engine's own tiering
# has not, so the policy takes the grounding as its second argument and says
# both answers in one place, in v3.2's own vocabulary: DECLARED, OBSERVED,
# INFERRED.
_adm() { ( . "$FROOT/harness/lib/admit.sh"; felix_admit "${1:-}" "${2:-}" ); }

is "a person's low row installs"                      "$(_adm low DECLARED)"     "install"
is "and a person's medium row installs, as it always has" "$(_adm medium DECLARED)" "install"
is "what the engine tiered low installs"              "$(_adm low OBSERVED)"     "install"
# The founder's decision, recorded 2026-09-04: an engine-tiered medium ships an
# MCP server, was read from three files and never sandboxed, and waits for a
# person. Amendments 1.2 is why — sandbox-exec confines but does not report, so
# there is no mechanism behind the spec's T2 on this machine.
is "and what the engine tiered medium holds"          "$(_adm medium OBSERVED)"  "hold"
# Grounding is required. A provider names a plugin in a file a model wrote, and
# nothing has fetched it, read it or tiered it — so the file's own claim of
# `low` is not evidence of anything. Inspecting it is what makes it OBSERVED,
# and that is the only door from a nomination to an install.
is "what a provider merely named holds, whatever it tiered itself" "$(_adm low INFERRED)" "hold"
is "and its medium holds too"                         "$(_adm medium INFERRED)"  "hold"

# Constitution invariant 4: high is refused by every flag from every caller.
for _admp in DECLARED OBSERVED INFERRED; do
  is "high is refused however it was grounded: $_admp" "$(_adm high "$_admp")" "refuse"
done

# It fails closed. An unreadable tier or an unrecognised grounding is not a
# reason to proceed, and this is the property a later edit is likeliest to
# lose, because every wrong answer here still looks like a working install.
is "an unknown tier refuses"        "$(_adm banana DECLARED)" "refuse"
is "an unknown grounding refuses"   "$(_adm low PROBABLY)"    "refuse"
is "an empty tier refuses"          "$(_adm '' DECLARED)"     "refuse"
is "an empty grounding refuses"     "$(_adm low '')"          "refuse"
is "and no arguments at all refuse" "$(_adm)"                 "refuse"

# The claim is that there is now one policy rather than three. Asserted on the
# source, because a second copy that agrees today is exactly what drifts later,
# and no behavioural test can see a duplicate that still gives the same answer.
has "stack plan asks the policy"     "$(cat "$FROOT/harness/lib/stack.sh")"    "felix_admit"
has "discover adopt asks the policy" "$(cat "$FROOT/harness/lib/discover.sh")" "felix_admit"
has "ready --fix asks the policy"    "$(cat "$FELIX")"                         "felix_admit"
is  "and no caller keeps a tier list of its own" \
    "$(cat "$FROOT/harness/lib/stack.sh" "$FROOT/harness/lib/discover.sh" "$FELIX" | grep -c 'FELIX_RISK_AUTO=')" "0"

# Sourced alone, the way the suite sources every library and the way discover.sh
# says it must stay sourceable. A policy call that resolved to nothing would
# refuse silently, which reads exactly like a correct refusal.
is "discover.sh alone can still reach the policy" \
   "$( . "$FROOT/harness/lib/discover.sh"; command -v felix_admit >/dev/null 2>&1 && echo reachable || echo missing )" "reachable"
is "and stack.sh alone can too" \
   "$( . "$FROOT/harness/lib/stack.sh"; command -v felix_admit >/dev/null 2>&1 && echo reachable || echo missing )" "reachable"

printf '\nprofiles\n'
printf 'core\talways\nbilling\tbilling\n' > "$FROOT/projects/widget/profiles.tsv"
out="$(cd "$REPO" && "$FELIX" profile core 2>&1)"
has "core profile mounts unconditional rows" "$out" "superpowers"
case "$out" in
  *"felix-test-absent"*) bad "core profile excludes other capabilities" "$out" ;;
  *) ok "core profile excludes other capabilities" ;;
esac

# Every reader of a manifest row takes the grounding column, not only the
# policy. A trailing `read` variable absorbs the last field AND its tab, so a
# five-variable reader silently gets "always<TAB>DECLARED" where it expected
# "always". felix profile answered with an empty activates list — a wrong
# answer that reads exactly like the right one and exits 0 — and the monitor
# payload carried the glued string as a capability. Asserted together so a
# seventh column cannot repeat it in either place.
printf 'plugin\tfelix-test-prof@nowhere\t-\tlow\talways\tDECLARED\n' >> "$FROOT/projects/widget/stack.tsv"
_prof="$(cd "$REPO" && "$FELIX" profile core 2>&1)"
has "felix profile lists a row carrying the grounding column" "$_prof" "felix-test-prof@nowhere"
_mon="$( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/monitor.sh"
         _felix_mon_project "$FROOT/projects/widget" "$FROOT" 2>/dev/null )"
case "$_mon" in
  *'felix-test-prof'*'"capability":"always"'*) ok "and the monitor reports its capability unglued from the grounding" ;;
  *'felix-test-prof'*)                         bad "and the monitor reports its capability unglued from the grounding" "$(printf '%s' "$_mon" | tr ',' '\n' | grep -A2 'felix-test-prof' | head -4)" ;;
  *)                                           skip "and the monitor reports its capability unglued from the grounding" "no payload for widget" ;;
esac
grep -v 'felix-test-prof' "$FROOT/projects/widget/stack.tsv" > "$TMP/stack.tmp"
mv "$TMP/stack.tmp" "$FROOT/projects/widget/stack.tsv"
is "and the widget manifest is as this block found it" \
   "$(grep -c 'felix-test-prof' "$FROOT/projects/widget/stack.tsv")" "0"

# A count is not a window's length. The payload bounds each log with `tail -n`,
# which is right — the page does not need 773 rows to draw a list — but the
# template rendered `array.length` as a labelled TOTAL, so "things said" read
# 60 over a log holding 773 and "times held" read 20 where the file holds 112.
# The count now travels beside the window instead of being derived from it.
mkdir -p "$MEM/widget"
: > "$MEM/widget/says.log"
for _i in $(seq 1 75); do printf 'x\theld\tbody %s\n' "$_i" >> "$MEM/widget/says.log"; done
for _i in $(seq 1 5); do printf 'x\tsaid\tbody\n' >> "$MEM/widget/says.log"; done
_mp="$( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/monitor.sh"
        _felix_mon_project "$FROOT/projects/widget" "$FROOT" 2>/dev/null )"
is "the payload carries the whole count, not the window's length" \
   "$(printf '%s' "$_mp" | tr ',' '\n' | sed -n 's/.*"saysTotal":\([0-9]*\).*/\1/p' | head -1)" "80"
is "and counts what was held over the whole file too" \
   "$(printf '%s' "$_mp" | tr ',' '\n' | sed -n 's/.*"heldTotal":\([0-9]*\).*/\1/p' | head -1)" "75"
# A file that is not there counts zero rather than erroring, which is the guard
# clause above. There is no assertion here for "counts a log with high bytes":
# the defect that seemed to motivate one was my own shell shadowing grep with
# ugrep -I, and an assertion written from a false premise is worse than none.
is "and a file that does not exist counts zero" \
   "$( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/monitor.sh"
       _felix_mon_count "$MEM/widget/nosuchlog.log" )" "0"
rm -f "$MEM/widget/says.log"
# The template reads the totals rather than the arrays.
_mt="$(cat "$FROOT/harness/templates/monitor.html")"
has "the page renders the says total"     "$_mt" "p.saysTotal"
has "and the gate-failure total"          "$_mt" "p.mistakesTotal"
has "and the held total"                  "$_mt" "p.heldTotal"
has "and says when a rate is over a window only" "$_mt" "last '+vl.length+' of '"

printf '\nhuman setup steps\n'
{
  printf 'always-done\tA step that is already satisfied\talways\ttrue\n'
  printf 'always-todo\tA step nobody has done\talways\tfalse\n'
  printf 'later\tA step for a capability not present yet\tbilling\tfalse\n'
} > "$FROOT/projects/widget/setup.tsv"
mkdir -p "$FROOT/projects/widget/setup"
printf '# Do the thing\n\nStep one.\n' > "$FROOT/projects/widget/setup/always-todo.md"

out="$(cd "$REPO" && "$FELIX" setup 2>&1)"
has "a satisfied step reports done"    "$out" "[x] always-done"
has "an unmet step reports todo"       "$out" "[ ] always-todo"
has "a dormant capability is deferred" "$out" "not needed yet"
case "$out" in
  *"[ ] later"*) bad "dormant steps never nag" "$out" ;;
  *) ok "dormant steps never nag" ;;
esac

out="$(cd "$REPO" && "$FELIX" setup always-todo 2>&1)"
has "a runbook prints in full" "$out" "Step one."

out="$(cd "$REPO" && "$FELIX" setup later 2>&1)"; rc=$?
[ "$rc" -ne 0 ] && ok "a missing runbook fails loudly" \
                || bad "a missing runbook fails loudly" "silently returned 0"

printf '\nrepair loop\n'
# The ceiling is the safety property: past it the answer stops being "retry".
out="$(FELIX_REPAIR_MAX=3 bash -c '
  . '"$FROOT"'/harness/lib/repair.sh
  echo "$FELIX_REPAIR_MAX"')"
is "ceiling defaults to 3" "$out" "3"
out="$(FELIX_REPAIR_MAX=1 bash -c '
  . '"$FROOT"'/harness/lib/repair.sh
  echo "$FELIX_REPAIR_MAX"')"
is "ceiling is overridable" "$out" "1"

# A repo with no GitHub remote must say so rather than guess.
out="$(cd "$PLAIN" && "$FELIX" repair 2>&1)"; rc=$?
[ "$rc" -ne 0 ] && ok "repair refuses outside a governed GitHub repo" \
                || bad "repair refuses outside a governed GitHub repo" "$out"
# And with its own status. It exited resolution's 2, which is repair's
# ceiling, and the unattended template escalated a checkout nothing governs to
# a person as a spent ceiling. A marker naming a project that does not exist is
# the other way resolution fails, and takes the same status. Every other
# command keeps 2: "ungoverned repo refuses to run a gate" holds that.
is  "repair exits 4 in a checkout no project governs, not the ceiling's 2" "$rc" "4"
RBRK="$TMP/repair-broken"; mkdir -p "$RBRK"
( _fx_cd "$RBRK" && git init -q -b main && printf 'nonexistent\n' > .felix )
out="$(cd "$RBRK" && "$FELIX" repair 2>&1)"; rc=$?
is  "and 4 where the .felix marker names a project that does not exist" "$rc" "4"
has "and names the broken binding rather than asking for a marker" "$out" "nonexistent"

printf '\nissue intake\n'
# The first of the two p41 exit criteria nothing met: take an issue. felix brief
# keeps felix repair's shape - brief on stdout, scope verdict in the exit code.
# Read through the mapping unattended.yml gives repair, 0 is every brief to act
# on, the one naming no real file included, and proceeds; 3 is a red path and
# escalates; 1 is an issue that could not be read and fails the job. Its 2 is an
# unresolved binding, before any brief exists, and that mapping would escalate
# it as a spent ceiling: repair exits 4 there since #321, brief still exits 2.
# No template calls felix brief yet.
mkdir -p "$REPO/src"
printf 'x\n' > "$REPO/src/widget.py"
cp "$REAL_HARNESS/templates/risk.tsv" "$FROOT/projects/widget/risk.tsv"
# Declared here rather than inherited. The evidence fixture is written further
# down this file, and a section that depends on state another section happens to
# set up reads like a product bug the day the order changes.
printf 'code\t^src/\t^tests?/\tbehaviour changed and nothing proves it\n' \
  > "$FROOT/projects/widget/evidence.tsv"
# Same reason. This fixture has no routes.tsv until much further down the file,
# so a brief asking which play applies would silently have nothing to answer
# with — and the assertion would have been written to match that emptiness.
cp "$REAL_HARNESS/templates/routes.tsv" "$FROOT/projects/widget/routes.tsv"
_brief() { ( cd "$REPO" && bash -c '
  . '"$FROOT"'/harness/lib/classify.sh
  . '"$FROOT"'/harness/lib/incident.sh
  . '"$FROOT"'/harness/lib/route.sh
  . '"$FROOT"'/harness/lib/intake.sh
  felix_brief_render "'"$FROOT"'/projects/widget" "'"$REPO"'" "$1" "$2"' _ "$1" "$2" ); }

out="$(_brief "the widget renders twice" "src/widget.py double-renders on mount")"
has "the brief names the file the issue names" "$out" "src/widget.py"
has "and states the tier"                      "$out" "tier"
has "and what a fix will have to prove"        "$out" "prove"
has "and the play this project already chose"  "$out" "play"

# Scope before detail. Telling a model what it may not touch after handing it
# the details is the wrong order: by then it has a plan.
mkdir -p "$REPO/.github/workflows"; printf 'on: push\n' > "$REPO/.github/workflows/ci.yml"
out="$(_brief "ci is wrong" ".github/workflows/ci.yml needs a job")"; rc=$?
is  "a red path exits 3"            "$rc" "3"
has "and says so before the detail" "$out" "OUT OF SCOPE"

out="$(_brief "nothing real" "this names no path that exists")"; rc=$?
is  "an issue naming no real file still exits 0" "$rc" "0"
has "and says it cannot be scoped"               "$out" "no file"

# --from - is what makes this testable and what makes it usable before any
# issue tracker is wired, the same reason felix incident reads stdin. The suite
# stubs no gh and never has, so a design that could only fetch would be a design
# whose interesting half was untestable.
out="$(cd "$REPO" && printf 'src/widget.py double-renders on mount\n' \
       | "$FELIX" brief --from - --title "the widget renders twice" 2>&1)"; rc=$?
is  "brief reads an issue from stdin" "$rc" "0"
has "and briefs the file it names"    "$out" "src/widget.py"
out="$(cd "$PLAIN" && printf 'x\n' | "$FELIX" brief --from - --title t 2>&1)"; rc=$?
[ "$rc" -ne 0 ] && ok "brief refuses outside a governed repo" \
                || bad "brief refuses outside a governed repo" "$out"
out="$(cd "$REPO" && "$FELIX" brief 2>&1)"; rc=$?
[ "$rc" -ne 0 ] && ok "and refuses with no issue and no input" \
                || bad "and refuses with no issue and no input"

# Preview by default, act behind a flag: the pattern incident --create and
# classify --apply already set, against discover which refuses --yes outright.
# A symbolic ref when there is one, the commit otherwise. This fixture sits on a
# detached HEAD, so `rev-parse --abbrev-ref` returns the literal string HEAD,
# and checking that out fails — silently, leaving the branch where it was.
_base_branch="$(cd "$REPO" && { git symbolic-ref --quiet --short HEAD 2>/dev/null \
                                || git rev-parse HEAD 2>/dev/null; })"
# Two commits, where there used to be one. #63 found why that mattered: this
# fixture has no commits before the branch is cut, so `main` is unborn and the
# default base named nothing. The preview was therefore reducing an EMPTY diff
# to a tier and printing it — the exact defect under test three sections down —
# and it passed because `has ... "tier"` matches the label and never the value.
# The comment on the restore below already knew main was unborn; nothing
# connected that to the base this assertion was using.
#
# A parent commit on the branch itself, rather than a base commit on main,
# because a later section makes the first commit on main and the restore here
# depends on it still being unborn.
( _fx_cd "$REPO" && git checkout -qb feature/thing 2>/dev/null
  git add -A >/dev/null 2>&1
  git -c user.name=t -c user.email=t@t commit -qm "fixture base" >/dev/null 2>&1
  printf 'y\n' >> src/widget.py
  git add -A >/dev/null 2>&1
  git -c user.name=t -c user.email=t@t commit -qm "fix: stop the double render" >/dev/null 2>&1 )
out="$(cd "$REPO" && "$FELIX" pr --base HEAD~1 2>&1)"; rc=$?
is  "pr previews and exits 0"    "$rc" "0"
has "naming the branch's commit" "$out" "stop the double render"
has "and the tier it carries"    "$out" "tier"
# The value, not the label, so a tier computed from nothing cannot satisfy it.
case "$out" in
  *"tier:     green"*|*"tier:     yellow"*|*"tier:     red"*)
    ok  "and it is a tier, not the word" ;;
  *) bad "and it is a tier, not the word" "$out" ;;
esac
# And the default base, `main`, which is unborn here. It must refuse rather than
# preview a tier it could not compute. This is the assertion the restore
# comment below implies and nothing ever made.
out="$(cd "$REPO" && "$FELIX" pr 2>&1)"; rc=$?
[ "$rc" -ne 0 ] && ok "an unborn default base refuses rather than previews" \
                || bad "an unborn default base refuses rather than previews" "$out"
has "and says which base it could not resolve" "$out" "main"
case "$out" in
  *created*) bad "and creates nothing without --create" "$out" ;;
  *)         ok  "and creates nothing without --create" ;;
esac
# Asserted by naming the current branch as the base, rather than by checking out
# a branch called main: `git init` does not promise that name, and a checkout
# that silently fails would leave this passing against the wrong branch.
out="$(cd "$REPO" && "$FELIX" pr --base feature/thing 2>&1)"; rc=$?
[ "$rc" -ne 0 ] && ok "pr refuses to open a branch against itself" \
                || bad "pr refuses to open a branch against itself" "$out"

# The title a pull request gets when --title gives none. It was HEAD's
# subject, and a branch landed by merging main in last ends on that merge: #395
# reached main as "Merge remote-tracking branch 'origin/main' into
# claude/red-counts-unreached". What the landing writes after the merge, the
# version slot, the suite's record and the handoff section, says no more about
# the change.
#
# A repository of its own, so nothing here borrows the fixture above. Every
# commit has a fixed date, because which commit is newest must not rest on two
# commits made in the same second.
PTTL="$TMP/prtitle"; mkdir -p "$PTTL"
( _fx_cd "$PTTL" || exit 1
  n=0
  c() { n=$((n+1)); d="2099-01-01T00:00:$(printf %02d "$n")Z"
        GIT_AUTHOR_DATE="$d" GIT_COMMITTER_DATE="$d" git "$@"; }
  bk() { mkdir -p engine/harness/tests engine/.claude-plugin
         printf '%s\n' "$2" >> "$1"; git add "$1"; }
  git init -q -b main; git config user.email t@t; git config user.name t
  printf 'widget\n' > .felix; printf 'a\n' > a.txt; git add -A; c commit -qm init
  # Its own work, main moving on, and main merged in.
  git checkout -qb claude/merged
  printf 'b\n' >> a.txt; c commit -qam "fix(thing): the change this branch carries"
  git checkout -q main; printf 'm\n' > m.txt; git add m.txt; c commit -qm "chore: main moved on"
  git checkout -q claude/merged
  c merge -q --no-ff main -m "Merge remote-tracking branch 'origin/main' into claude/merged"
  # Then the landing: a version slot, main merged again, the suite's record,
  # and the session's handoff section.
  git checkout -qb claude/landed
  bk engine/.claude-plugin/plugin.json 1; c commit -qm "chore(version): 0.0.2, the slot the carrier assigned"
  git checkout -q main; printf 'n\n' >> m.txt; c commit -qam "chore: main moved again"
  git checkout -q claude/landed
  c merge -q --no-ff main -m "Merge remote-tracking branch 'origin/main' into claude/landed"
  bk engine/harness/tests/assertions.tsv 1; bk engine/harness/tests/red.tsv 1
  c commit -qm "test(record): 2 assertions, 1 red against main"
  mkdir -p docs/handoff/pending; printf '### s\n' > docs/handoff/pending/20991231T000000Z-claude-landed.md
  git add docs/handoff/pending; c commit -qm "docs(handoff): this branch's section"
  # A commit that changes the record and something else is the branch's own.
  git checkout -qb claude/mixed
  printf 'c\n' >> a.txt; bk engine/harness/tests/red.tsv 2; git add a.txt
  c commit -qm "fix(thing): a second change, recorded with it"
  bk engine/harness/tests/red.tsv 3; c commit -qm "test(red): re-run against main"
  # A commit that changes nothing is not one the landing wrote.
  git checkout -qb claude/empty
  c commit -q --allow-empty -m "ci: an empty commit, made by hand"
  bk engine/harness/tests/red.tsv 4; c commit -qm "test(red): re-run once more"
  # Only those paths are the landing's: not the directory they sit in, not a
  # file elsewhere with a record's name, and not a subject a record could carry.
  git checkout -qb claude/engineown main
  mkdir -p engine/harness/lib; printf 'x\n' > engine/harness/lib/thing.sh; git add engine/harness/lib
  c commit -qm "test(record): an engine change whose subject reads like a record's"
  bk engine/harness/tests/red.tsv 1; c commit -qm "test(red): the record after it"
  git checkout -qb claude/samename main
  mkdir -p tables; printf 'x\n' > tables/red.tsv; git add tables
  c commit -qm "fix(tables): a table that shares the record's file name"
  bk engine/harness/tests/red.tsv 1; c commit -qm "test(red): the record after it"
  # Stacked: this branch merged another branch's head before that one landed.
  # A squash merge means main never holds the other branch's commits, and its
  # commit is the newer, so newest-first it would be the title.
  git checkout -qb claude/stacked main
  printf 's\n' > s.txt; git add s.txt; c commit -qm "fix(stacked): this branch's change"
  git checkout -qb claude/other main
  printf 'o\n' > o.txt; git add o.txt; c commit -qm "feat(other): another branch's change, not landed"
  git checkout -q claude/stacked
  c merge -q --no-ff claude/other -m "Merge commit 'claude/other' into claude/stacked"
  # A branch that made nothing but the landing's own commits.
  git checkout -qb claude/recordonly main
  bk engine/harness/tests/red.tsv 1; c commit -qm "test(record): 0 assertions, 0 red against main"
  bk engine/harness/tests/red.tsv 2; c commit -qm "test(record): re-run, the newest record"
  c merge -q --no-ff claude/other -m "Merge branch 'claude/other' into claude/recordonly"
  # And one that made no commit of its own at all.
  git checkout -qb claude/nothing main
  c merge -q --no-ff claude/other -m "Merge branch 'claude/other' into claude/nothing"
  # A record that is a root commit, in a history main does not share.
  rt() { local t; t="$(printf '100644 blob %s\tred.tsv\n' "$1" | git mktree)"
         t="$(printf '040000 tree %s\ttests\n' "$t" | git mktree)"
         t="$(printf '040000 tree %s\tharness\n' "$t" | git mktree)"
         printf '040000 tree %s\tengine\n' "$t" | git mktree; }
  r1="$(c commit-tree "$(rt "$(printf '1\n' | git hash-object -w --stdin)")" -m "test(record): the first record, a root commit")"
  r2="$(c commit-tree "$(rt "$(printf '2\n' | git hash-object -w --stdin)")" -p "$r1" -m "test(record): the second record")"
  git branch claude/orphan "$r2"
  # Both commits signed with ssh, the branch's own and the record over it, so
  # the read of the branch and the read of the title each meet a signature.
  # Signed where this git and ssh-keygen can, and made unsigned otherwise so
  # the index is left clean; the check below skips then.
  git checkout -qb claude/signed main
  sg=""
  ssh-keygen -q -t ed25519 -N '' -C t@t -f "$PTTL.key" </dev/null \
    && printf 't@t %s\n' "$(cat "$PTTL.key.pub")" > "$PTTL.signers" \
    && git config gpg.format ssh && git config user.signingkey "$PTTL.key.pub" \
    && git config gpg.ssh.allowedSignersFile "$PTTL.signers" && sg=-S
  printf 'g\n' > g.txt; git add g.txt
  c commit $sg -qm "fix(signed): the change under a signed record" \
    || c commit -qm "fix(signed): the change under a signed record"
  bk engine/harness/tests/red.tsv 1
  c commit $sg -qm "test(red): a signed record" || c commit -qm "test(red): a signed record"
  # Last, because it leaves a file named HEAD in the tree: a tracked one, on a
  # branch that made nothing of its own.
  git checkout -qb claude/headside main
  printf 'h\n' > HEAD; git add HEAD; c commit -qm "feat(headside): a file named HEAD"
  git checkout -qb claude/headfile main
  c merge -q --no-ff claude/headside -m "Merge branch 'claude/headside' into claude/headfile"
) >/dev/null 2>&1
_ptt() { ( _fx_cd "$PTTL" && git checkout -q "$1" && "$FELIX" pr ${2:+--title "$2"} 2>&1 ) | grep '^title:'; }
is  "a branch ending on a merge of main is titled by its own last commit" \
    "$(_ptt claude/merged)" "title:    fix(thing): the change this branch carries"
is  "and so is one the landing then gave a version slot, a record and a handoff section" \
    "$(_ptt claude/landed)" "title:    fix(thing): the change this branch carries"
is  "a commit that changes the record and more is the branch's own" \
    "$(_ptt claude/mixed)" "title:    fix(thing): a second change, recorded with it"
is  "an empty commit is not passed over as the landing's" \
    "$(_ptt claude/empty)" "title:    ci: an empty commit, made by hand"
is  "an engine change under a record's subject is the branch's own" \
    "$(_ptt claude/engineown)" "title:    test(record): an engine change whose subject reads like a record's"
is  "and so is a file elsewhere that shares a record's name" \
    "$(_ptt claude/samename)" "title:    fix(tables): a table that shares the record's file name"
is  "a branch that merged another unlanded branch is titled by its own work, not that branch's" \
    "$(_ptt claude/stacked)" "title:    fix(stacked): this branch's change"
is  "a branch of nothing but record commits is titled by the newest of them, not the merge" \
    "$(_ptt claude/recordonly)" "title:    test(record): re-run, the newest record"
is  "a branch with no commit of its own keeps HEAD's subject, as before" \
    "$(_ptt claude/nothing)" "title:    Merge branch 'claude/other' into claude/nothing"
is  "and --title still wins over all of it" \
    "$(_ptt claude/landed "the title given")" "title:    the title given"
# Asked of the function, since felix pr refuses a base that shares no history.
is  "a root commit made only of a record is the landing's too" \
    "$( _fx_cd "$PTTL" && git checkout -q claude/orphan && . "$FROOT/harness/lib/intake.sh" \
        && felix_pr_title "$PTTL" main )" "test(record): the second record"
if [ "$(git -C "$PTTL" log -2 --format=%G? claude/signed 2>/dev/null | tr -d '\n')" = GG ]; then
  _fx_git "$PTTL" config log.showSignature true
  is  "signed commits leave the title the branch's own under log.showSignature" \
      "$(_ptt claude/signed)" "title:    fix(signed): the change under a signed record"
  _fx_git "$PTTL" config --unset log.showSignature
else
  skip "signed commits leave the title the branch's own under log.showSignature" \
       "this git or ssh-keygen could not make an ssh-signed commit"
fi
is  "a tracked file named HEAD leaves HEAD's subject readable" \
    "$(_ptt claude/headfile)" "title:    Merge branch 'claude/headside' into claude/headfile"

# Put back what this section borrowed. Declaring the state you depend on is half
# the rule; restoring the state you changed is the other half. Seeding a route
# table here made a later assertion about the prompt hook being silent fail,
# because that assertion had been passing on the absence of routes rather than
# on the absence of lessons — which is what it says it tests.
# The branch first, and forced. Routing scores the branch name, and a fixture
# left on `feature/thing` sent four later prompts to the `build` route, whose
# keywords include `feature`. Leaving state behind is not only about files.
#
# Forced, and before the files are removed: deleting a tracked path dirties the
# tree, and a plain checkout then fails silently, which is how the first attempt
# at this cleanup left the branch exactly where it found it.
#
# Restored by pointing HEAD back rather than by checking anything out. This
# fixture has no commits yet — a later section makes the first one — so `main`
# is an unborn branch and `git checkout main` has nothing to check out. The
# branch created here was the first that ever had a commit on it, which is why
# every attempt to return to `main` failed quietly.
( _fx_cd "$REPO" && git symbolic-ref HEAD "refs/heads/${_base_branch:-main}" 2>/dev/null
  git branch -qD feature/thing 2>/dev/null
  git reset -q 2>/dev/null ) || true
rm -f "$FROOT/projects/widget/routes.tsv" "$FROOT/projects/widget/evidence.tsv"
rm -rf "$REPO/.github"
# Asserted, not assumed. A cleanup nobody checks is the same as no cleanup.
_after="$(cd "$REPO" && { git symbolic-ref --quiet --short HEAD 2>/dev/null \
                          || git rev-parse HEAD 2>/dev/null; })"
[ "$_after" = "$_base_branch" ] && ok "the fixture is left as it was found" \
  || bad "the fixture is left as it was found" "on $_after, expected $_base_branch"

