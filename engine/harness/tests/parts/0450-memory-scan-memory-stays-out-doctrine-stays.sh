# ---------------------------------------------- memory-scan, the fourth checker ---
# Invariant 6, the half a gate can read, as a command. Blind controls found
# the inline check could not see an ignore rule swallowing a TRACKED
# maintenance.log — `git check-ignore` never reports a tracked file — nor the
# same lessons.md tracked one level up from memory/. One seed, copied per
# case, so no case depends on another having been undone. The seed's ignore
# file carries no memory rule on purpose: the property is what is tracked.
printf '\nmemory-scan: memory stays out, doctrine stays in\n'
MSS="$TMP/memory-scan-seed"; mkdir -p "$MSS/projects/alpha" "$MSS/projects/beta"
( _fx_cd "$MSS" && git init -q -b main && printf '*.log\n!projects/*/maintenance.log\n' > .gitignore \
  && printf 'run\n' > projects/alpha/maintenance.log && printf 'x\n' > projects/alpha/CLAUDE.md \
  && git add -A && git -c user.name=t -c user.email=t@t commit -qm seed ) >/dev/null 2>&1
_ms()  { ( cd "$1" && "$REAL_HARNESS/bin/memory-scan" 2>&1; echo "rc=$?" ); }
# Exact, for the reason the deploy-check block gives: "rc=1" as a substring is
# satisfied by rc=126 and rc=127, which are a checker that never ran.
_msrc() { printf '%s' "${1##*rc=}"; }
_msc() { ( _fx_cd "$1" && git add -A && git -c user.name=t -c user.email=t@t commit -qm case ) >/dev/null 2>&1; }
if [ -x "$REAL_HARNESS/bin/memory-scan" ]; then
  is  "a tree with doctrine tracked and no memory is clean" "$(_msrc "$(_ms "$MSS")")" "0"
  MS1="$TMP/memory-scan-1"; cp -R "$MSS" "$MS1"
  mkdir -p "$MS1/projects/alpha/memory"; printf 'l\n' > "$MS1/projects/alpha/memory/lessons.md"; _msc "$MS1"
  out="$(_ms "$MS1")"
  is  "memory tracked under projects/<p>/memory/ fails" "$(_msrc "$out")" "1"
  has "naming the file" "$out" "memory tracked: projects/alpha/memory/lessons.md"
  MS2="$TMP/memory-scan-2"; cp -R "$MSS" "$MS2"
  printf 'l\n' > "$MS2/projects/alpha/lessons.md"; _msc "$MS2"
  out="$(_ms "$MS2")"
  is  "the same file one level up fails by name, where the inline check was blind" "$(_msrc "$out")" "1"
  has "and says so" "$out" "memory tracked by name: projects/alpha/lessons.md"
  MS3="$TMP/memory-scan-3"; cp -R "$MSS" "$MS3"
  mkdir -p "$MS3/docs/memory"; printf 'memory lives elsewhere\n' > "$MS3/docs/memory/README.md"; _msc "$MS3"
  is  "a directory merely named memory, holding doctrine, outside projects/, is not memory" "$(_msrc "$(_ms "$MS3")")" "0"
  # Every project's log TRACKED, so plain check-ignore — the inline form this
  # replaced — reports nothing at all and the rc=1 below can only come from
  # the --no-index reading. The first version of this case left beta with no
  # log, and an untracked path is reported by the plain form too, so the
  # assertion named after tracked files was satisfied without them.
  MS4="$TMP/memory-scan-4"; cp -R "$MSS" "$MS4"
  printf 'run\n' > "$MS4/projects/beta/maintenance.log"; _msc "$MS4"
  is  "with every log tracked, the form this replaced sees nothing to report" \
      "$(_fx_cd "$MS4" && printf 'projects/*/maintenance.log\n' >> .gitignore
         git add -A >/dev/null 2>&1
         git -c user.name=t -c user.email=t@t commit -qm r >/dev/null 2>&1
         for d in projects/*/; do git check-ignore -q "${d}maintenance.log" 2>/dev/null && echo hit; done | grep -c .)" "0"
  out="$(_ms "$MS4")"
  is  "an ignore rule that swallows a TRACKED maintenance.log fails" "$(_msrc "$out")" "1"
  has "naming the doctrine" "$out" "doctrine ignored: projects/alpha/maintenance.log"
  has "and the second project, whose log is tracked too" "$out" "doctrine ignored: projects/beta/maintenance.log"
  cp "$MSS/.gitignore" "$MS4/.gitignore"; _msc "$MS4"
  is  "and putting the rule back clears it" "$(_msrc "$(_ms "$MS4")")" "0"
  # routes.log stores the founder's prompt text verbatim, one line per routed
  # prompt. The first name list was written from memory rather than from the
  # directory and omitted it, along with decisions.log and the ledger shards —
  # so the file this check exists to keep out of a repository was the one it
  # could not see.
  MS5="$TMP/memory-scan-5"; cp -R "$MSS" "$MS5"
  # The seed's own `*.log` rule would cover this file, and an untracked file
  # is not what the check is about - the property is what the repository
  # CARRIES. The rule goes for this case so the file is really tracked.
  printf '\n' > "$MS5/.gitignore"
  printf '2026-09-09T00:00:00Z\tharness\t7\tthe founder said this, verbatim\n' > "$MS5/projects/alpha/routes.log"; _msc "$MS5"
  out="$(_ms "$MS5")"
  is  "routes.log tracked under a project fails: it holds the prompts verbatim" "$(_msrc "$out")" "1"
  has "naming it" "$out" "memory tracked by name: projects/alpha/routes.log"
  # The lifecycle recorder (#281) writes lifecycle.log to the memory root, and
  # the name list did not learn it: the list drifting from what the engine
  # writes, the defect the paragraph above records, once more.
  printf '2026-09-22T00:00:00Z\tstartup\ts1\t0.1\t0.1\t-\t-\t-\t-\n' > "$MS5/projects/alpha/lifecycle.log"; _msc "$MS5"
  has "lifecycle.log tracked under a project fails too" "$(_ms "$MS5")" "memory tracked by name: projects/alpha/lifecycle.log"
  MS6="$TMP/memory-scan-6"; cp -R "$MSS" "$MS6"
  mkdir -p "$MS6/projects/alpha/ledger.d"; printf 'x\n' > "$MS6/projects/alpha/ledger.d/s1.tsv"; _msc "$MS6"
  has "a ledger shard under a memory directory fails" "$(_ms "$MS6")" "memory tracked in a memory directory: projects/alpha/ledger.d/s1.tsv"
  MS7="$TMP/memory-scan-7"; cp -R "$MSS" "$MS7"
  printf 'x\n' > "$MS7/projects/alpha/ledger.tsv.bak-20260816010302"; _msc "$MS7"
  has "and a rotated ledger is the same record with a date on it" "$(_ms "$MS7")" "memory tracked by name: projects/alpha/ledger.tsv.bak-20260816010302"
  # A tree with nothing tracked under projects/ is not a clean tree.
  MS8="$TMP/memory-scan-8"; mkdir -p "$MS8"
  ( _fx_cd "$MS8" && git init -q -b main && printf 'x\n' > README.md && git add -A \
    && git -c user.name=t -c user.email=t@t commit -qm s ) >/dev/null 2>&1
  out="$(_ms "$MS8")"
  has "a checkout with nothing tracked under projects/ cannot search" "$out" "cannot search"
  is  "rather than reporting clean" "$(_msrc "$out")" "1"
  has "outside a checkout it cannot search, and says so rather than passing" \
      "$(cd "$TMP" && "$REAL_HARNESS/bin/memory-scan" 2>&1; echo "rc=$?")" "cannot search"
  _MSG="$(cd "$REAL_HARNESS/../.." && pwd)/projects/felix"
  if [ -f "$_MSG/gate.sh" ] && [ -f "$_MSG/qualification.tsv" ]; then
    has "felix's gate runs the memory check through memory-scan" \
        "$(grep -v '^[[:space:]]*#' "$_MSG/gate.sh")" 'engine/harness/bin/memory-scan 2>&1'
    is  "and declares every control for it" \
        "$( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/qualify.sh"; felix_qualify_missing_controls "$_MSG" memory | tr '\n' ' ' )" ""
  else
    for a in "felix's gate runs the memory check through memory-scan" "and declares every control for it"; do
      skip "$a" "no projects/felix beside this harness"; done
  fi
else
  for a in "a tree with doctrine tracked and no memory is clean" "memory tracked under projects/<p>/memory/ fails" \
           "naming the file" "the same file one level up fails by name, where the inline check was blind" "and says so" \
           "a directory merely named memory, holding doctrine, outside projects/, is not memory" \
           "with every log tracked, the form this replaced sees nothing to report" \
           "an ignore rule that swallows a TRACKED maintenance.log fails" "naming the doctrine" \
           "and the second project, whose log is tracked too" "and putting the rule back clears it" \
           "routes.log tracked under a project fails: it holds the prompts verbatim" "naming it" \
           "lifecycle.log tracked under a project fails too" \
           "a ledger shard under a memory directory fails" \
           "and a rotated ledger is the same record with a date on it" \
           "a checkout with nothing tracked under projects/ cannot search" "rather than reporting clean" \
           "outside a checkout it cannot search, and says so rather than passing" \
           "felix's gate runs the memory check through memory-scan" "and declares every control for it"; do
    skip "$a" "no bin/memory-scan beside this harness"; done
fi

# Shrinking the ledger escapes, like every table that decides what stops.
has "obligations.tsv is one of the tables whose shrinkage escapes" \
    "$( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/escape.sh"
        printf '%s' "$FELIX_ESCAPE_TABLES" )" "obligations.tsv"

# The full command against a project that has rows, since every assertion above
# could pass while the CLI died on an unbound variable — the lesson this
# repository already carries about neutering the call site rather than the
# library.
{ printf 'present\t-\t-\tls -1 WIDGET.txt\ttest -f WIDGET.txt\n'
  printf 'blindrow\t-\t-\tls -1 nothing-here.rs\ttest -f WIDGET.txt\n'
} > "$FROOT/projects/widget/probes.tsv"
out="$(cd "$REPO" && "$FELIX" probes 2>&1)"; rc=$?
is  "felix probes reports without refusing"       "$rc" "0"
has "and names the project"                       "$out" "probes for widget"
has "and prints the state rather than a verdict"  "$out" "blind"
out="$(cd "$REPO" && "$FELIX" probes --gate 2>&1)"; rc=$?
is  "while gate mode turns that same state into a refusal" "$rc" "1"
# The surface that asks reality is the strongest claim to trustworthiness this
# engine prints, and its own weakest joint is enumeration: a member no probe
# names is missing from the counts rather than reported as a gap in them. Said
# every run, because there is no state in which it stops being true and a
# caveat that appears only sometimes reads as a finding about this run.
out="$(cd "$REPO" && "$FELIX" probes 2>&1)"
has "the probe report says what it cannot reach" "$out" "never found is never executed"
has "and that one authority writes both halves"  "$out" "writes both the work and the judgement"

{ printf 'present\t-\t-\tls -1 WIDGET.txt\ttest -f WIDGET.txt\n'
  printf 'switchedoff\t-\tfalse\tls -1 nothing-here\ttest -f WIDGET.txt\n'
} > "$FROOT/projects/widget/probes.tsv"
out="$(cd "$REPO" && "$FELIX" probes 2>&1)"
has "a row switched off by its when column is reported as not applying" \
    "$out" "not-applicable"
has "and the report says how much of the table asked nothing" \
    "$out" "did not apply here"

# felix coverage had no test at all, which for a command whose whole subject is
# "was every moment considered" is the joke telling itself. Driven here for the
# caveat it has always carried and the residual it now carries too.
out="$(cd "$REPO" && "$FELIX" coverage 2>&1)"; rc=$?
is  "felix coverage answers"                        "$rc" "0"
has "and says it judges consideration, not quality" "$out" "never that what runs at"
has "and states the residual no row can close"      "$out" "writes both the work and the judgement"
has "including the enumeration limit"               "$out" "never found is never executed"
out="$(cd "$REPO" && "$FELIX" probes --gate 2>&1)"; rc=$?
is  "which does not by itself fail the gate, since not applying is not a claim" "$rc" "0"
out="$(cd "$REPO" && "$FELIX" probes --wat 2>&1)"; rc=$?
is  "and an unknown flag is refused rather than ignored" "$rc" "1"

# A row nothing can run must stop the gate, not merely appear in the report.
# procedures.tsv shipped with exactly this hole: the malformed row was named
# and the surface still read as answered. Reproducing it in the file that
# documents it would be the same mistake made twice.
{ printf 'present\t-\t-\tls -1 WIDGET.txt\ttest -f WIDGET.txt\n'
  printf 'nocommand\t-\n'
} > "$FROOT/projects/widget/probes.tsv"
out="$(cd "$REPO" && "$FELIX" probes --gate 2>&1)"; rc=$?
is  "a malformed row stops the gate rather than only being listed" "$rc" "1"
has "and is named"                                                 "$out" "nocommand"
cp "$TMP/probes.keep" "$FROOT/projects/widget/probes.tsv"

# And a project created today is not born reading nothing. Seeded rows are
# questions git and the filesystem can always answer; the answers still come
# from the checkout, so this is not Felix authoring an enumeration.
NEWP="$TMP/probes-new"; mkdir -p "$NEWP"
( _fx_cd "$NEWP" && git init -q -b main && printf 'x\n' > a.txt \
  && git add -A && git -c user.name=t -c user.email=t@t commit -qm i ) >/dev/null 2>&1
_cmstub_build
# Through CMSTUB, as every felix new here is: felix new commissions, and run
# against the real claude it installed the catalog's always plugins into the
# real ~/.claude, and wrote the registry that made marketplace_root blind.
out="$(cd "$NEWP" && PATH="$CMSTUB:$PATH" "$FELIX" new probeseed "$NEWP" 2>&1)"
is "felix new seeds a probe table" \
   "$( [ -s "$FROOT/projects/probeseed/probes.tsv" ] && echo yes || echo no )" "yes"
# And a seeded stack.tsv says the catalogue's rows are a person's judgment.
# Asserted here, at a project felix new actually created, rather than over a
# glob: the tier in catalog.tsv was decided by somebody, and the engine writing
# it into the manifest does not make it the engine's.
is "and its seeded stack rows carry DECLARED" \
   "$(grep -vE '^[[:space:]]*(#|$)' "$FROOT/projects/probeseed/stack.tsv" 2>/dev/null \
      | awk -F'\t' '$6 != "DECLARED" { n++ } END { print n + 0 }')" "0"
# Against a number, not against another count of the same file: comparing
# `grep -c` to `grep -vc` is equal whenever the file is empty or absent, so the
# first draft passed when there was nothing to count at all.
_pseed="$(grep -cE $'\tDECLARED$' "$FROOT/projects/probeseed/stack.tsv" 2>/dev/null)" || _pseed=0
[ "${_pseed:-0}" -gt 0 ] && ok "and there is at least one of them" \
                         || bad "and there is at least one of them" "counted $_pseed DECLARED rows"
_pbseed() { ( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/probes.sh"; . "$FROOT/harness/lib/facts.sh"; . "$FROOT/harness/lib/obligations.sh"
              felix_probe_rows "$FROOT/projects/probeseed" | grep -c . ); }
case "$(_pbseed)" in
  0) bad "and the seed holds rows rather than only comments" "0 rows" ;;
  *) ok  "and the seed holds rows rather than only comments" ;;
esac
out="$(cd "$NEWP" && "$FELIX" probes 2>&1)"; rc=$?
is  "so a project created today reads something from reality" "$rc" "0"
has "and reports what it found"                               "$out" "found"
# And is not born BLOCKED. The seeded witnesses have to answer with their exit
# status: the first `test_file` witness ended in `| head -1`, whose status is
# head's rather than ls's, so it claimed every repository on earth has tests and
# every project without them started life blind. This repo has none, so `empty`
# is the correct answer and the gate must pass.
has "and calls an absent surface empty rather than blind" "$out" "empty"
out="$(cd "$NEWP" && "$FELIX" probes --gate 2>&1)"; rc=$?
is  "so a project created today is not born blocked" "$rc" "0"
# And not born blocked on a repository with NO commit either. `felix new` runs
# on `git init` alone all the time — the onboarding fixture above is exactly
# that — and the seeded tracked_file witness was `test -e .git`, which proves
# a repository exists and nothing about whether it tracks a file. So the index
# was empty, the witness said "surface present", and the first gate on a brand
# new project went red with `blind`. The honest state is `empty`, and the
# witness that says so is the last commit's tree, not the .git directory.
NEWQ="$TMP/probes-new-nocommit"; mkdir -p "$NEWQ"
( _fx_cd "$NEWQ" && git init -q -b main && printf 'x\n' > a.txt ) >/dev/null 2>&1
out="$(cd "$NEWQ" && PATH="$CMSTUB:$PATH" "$FELIX" new probeseedq "$NEWQ" 2>&1)"
out="$(cd "$NEWQ" && "$FELIX" probes 2>&1)"
has "on a repository with no commit, nothing tracked reads as empty, not blind" \
    "$(printf '%s\n' "$out" | grep -E '^  [a-z-]+ +tracked_file')" "empty"
out="$(cd "$NEWQ" && "$FELIX" probes --gate 2>&1)"; rc=$?
is  "so a project created on git init alone is not born blocked" "$rc" "0"
rm -rf "$FROOT/projects/probeseedq" "$MEM/probeseedq" "$NEWQ"
rm -rf "$FROOT/projects/probeseed" "$MEM/probeseed" "$NEWP"

printf '\nfelix new: the maturity a person gives is read back\n'
# The risk envelope's first key. felix new writes it when a person gives it,
# and the commissioning row `envelope` reads it with felix_json_str, which
# matches a quoted key only. It was written by `${maturity:+...}` inside an
# unquoted here-document, and bash removes the double quotes inside that
# expansion there, so the file said `maturity: prototype`: not JSON, not
# readable, and the row stayed held after a person had answered it. Measured
# 2026-09-21 on bash 3.2.57, the stock macOS /bin/bash, and on 5.2.21, the CI
# runner's: both drop them. Nothing caught it because no assertion set it.
MATP="$TMP/maturity-new"; mkdir -p "$MATP"
( _fx_cd "$MATP" && git init -q -b main ) >/dev/null 2>&1
out="$(cd "$MATP" && FELIX_MATURITY=prototype PATH="$CMSTUB:$PATH" "$FELIX" new maturityseed "$MATP" </dev/null 2>&1)"; rc=$?
# The detail names the bash and what the file held, because `got []` alone
# cannot tell a dropped quote from a felix new that never wrote the file.
_matj="$FROOT/projects/maturityseed/project.json"
_matv="$( . "$FROOT/harness/lib/resolve.sh"; felix_json_str "$_matj" maturity )"
[ "$_matv" = "prototype" ] \
  && ok  "felix new writes the maturity a person gave as a key felix_json_str reads back" \
  || bad "felix new writes the maturity a person gave as a key felix_json_str reads back" \
         "read [$_matv]; bash $BASH_VERSION, felix new rc=$rc, project.json: $(tr '\n' ' ' 2>/dev/null < "$_matj" || printf 'absent')"
rm -rf "$FROOT/projects/maturityseed" "$MEM/maturityseed" "$MATP"

printf '\nmaintenance: an event row that can come due from reality\n'
# A cadence of 0 means event-driven, and the format's own words were that such
# a row "is never reported as overdue". One project carried
# `graphify  0  always  refresh the map after a major merge` for fifteen days
# and two merges with a graph built once, and the row read `event` every time.
# "Nothing due" and "nothing is being checked" rendering identically — the
# lesson this project already holds, one table over.
MTP="$TMP/maint-proj"; mkdir -p "$MTP" "$MEM/maint-proj"
MTR="$TMP/maint-repo"; mkdir -p "$MTR"
( _fx_cd "$MTR" && git init -q -b main && printf 'x\n' > a.txt && git add -A \
  && git -c user.name=t -c user.email=t@t commit -qm i ) >/dev/null 2>&1
MTR="$(cd "$MTR" && pwd -P)"
printf 'graph\t0\talways\tkeep the map current\ttest -f map.json\n' > "$MTP/maintenance.tsv"
_mst() { ( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/detect.sh"
           . "$FROOT/harness/lib/maintenance.sh"; felix_maint_status "$MTP" "$1" ); }
has "an event row with a failing check is DUE"  "$(_mst "$MTR")" "due	graph"
printf 'm\n' > "$MTR/map.json"
has "and once the check passes it is ok"          "$(_mst "$MTR")" "ok	graph"
# Where no checkout is known — felix pulse is home-scoped — a checked row is
# `unchecked`, and that word is the whole point. It used to fall through to
# `event`, which is also what a row with no check emits, so the two became one
# line downstream and `felix pulse`, keeping only `due`, printed neither.
has "with no checkout in front of it the row reads unchecked" \
    "$(_mst "")" "unchecked	graph"
case "$(_mst "")" in
  *"event	graph"*) bad "an unaskable row must not read as one with nothing to ask" ;;
  *) ok "and never as event, which is what a row with no check says" ;;
esac
# A row written before the column existed has four fields and keeps working.
printf 'old\t0\talways\tno check here\n' >> "$MTP/maintenance.tsv"
has "a four-column row still reads as event"     "$(_mst "$MTR")" "event	old"
# A check that cannot run is due, not ok — a broken check is loud.
printf 'broken\t0\talways\tthe check is nonsense\tdefinitely-not-a-command-xyz\n' >> "$MTP/maintenance.tsv"
has "a check that cannot run reads as due rather than ok" "$(_mst "$MTR")" "due	broken"
# The seeded row fires on a checkout with no graph, and not on one whose graph
# is newer than its last commit — the two states that motivated the column.
#
# Mirrors Felix's own row, projects/felix/maintenance.tsv, which is due on a
# checkout with no graph (the template's row is not: audit b14), without its
# Markdown exclusion. If the two drift, this fixture stops testing what Felix runs.
printf 'graphify\t0\talways\tthe map\tG="$(dirname "$(git rev-parse --git-common-dir)")"; test -n "$(find "$G/graphify-out/graph.json" -newermt "$(git log -1 --format=%%cd --date=format-local:%%Y-%%m-%%dT%%H:%%M:%%S%%z "$(git -C "$G" rev-parse HEAD)" -- . ":(exclude)projects/*/maintenance.log")" 2>/dev/null)"\n' > "$MTP/maintenance.tsv"
has "the seeded graphify row is due on a checkout with no graph" "$(_mst "$MTR")" "due	graphify"
# One second, because BSD find compares -newermt at whole seconds: a graph
# written 799ms after the commit, inside the same second, is "not newer".
# Measured, not assumed. No real graph is built in the second its repository
# was last committed — graphify takes seconds to minutes — so this is the
# fixture being faster than the world, not a defect in the check.
sleep 1
mkdir -p "$MTR/graphify-out" && printf '{}\n' > "$MTR/graphify-out/graph.json"
has "and ok once a graph newer than the last commit exists"     "$(_mst "$MTR")" "ok	graphify"
# And one second the other way, for the other find. GNU find compares
# -newermt at sub-second precision: a commit made in the same second the
# graph was written has a whole-second stamp, and the graph's milliseconds
# read as newer than it — so on the Linux runner this read `ok` while BSD,
# comparing whole seconds, read `due`. Two finds, two precisions, one fixture
# faster than either. The gap puts the commit in a later second than the graph.
sleep 1
( _fx_cd "$MTR" && printf 'y\n' > b.txt && git add -A && git -c user.name=t -c user.email=t@t commit -qm later ) >/dev/null 2>&1
has "and due again after a commit the graph has not seen"       "$(_mst "$MTR")" "due	graphify"
# But recording that the refresh happened must not undo it.
#
# A cadence-0 row's run is recorded in maintenance.log, and that write has to be
# committed for the cadence to survive the machine — so the commit that says
# "the graph was refreshed" was itself a commit the graph had not seen, and the
# row came due the moment it was satisfied. Measured on a real project: due,
# refreshed, recorded, due, inside one pull request.
#
# Sound rather than convenient: the log is not in the graph's corpus, so a
# commit touching only it changes nothing the graph models.
sleep 1
mkdir -p "$MTR/graphify-out" && printf '{}\n' > "$MTR/graphify-out/graph.json"
has "a refreshed graph clears the row"                          "$(_mst "$MTR")" "ok	graphify"
sleep 1
mkdir -p "$MTR/projects/widget"
( _fx_cd "$MTR" && printf 'graphify\t1\t2026-09-05\n' >> projects/widget/maintenance.log \
  && git add -A && git -c user.name=t -c user.email=t@t commit -qm "record the run" ) >/dev/null 2>&1
has "and recording the run does not put it back"                "$(_mst "$MTR")" "ok	graphify"
# The exclusion is that narrow: anything else the same commit shape touches
# still counts, or the row would be a check that cannot come due.
sleep 1
( _fx_cd "$MTR" && printf 'z\n' > c.txt && git add -A \
  && git -c user.name=t -c user.email=t@t commit -qm content ) >/dev/null 2>&1
has "while any other commit still does"                         "$(_mst "$MTR")" "due	graphify"
# A worktree has no graphify-out/ of its own. The graph lives beside the
# repository's .git, and a check keyed on the current directory read due in
# every worktree session whatever the graph's age — sixteen of the seventeen
# session roots recorded for this project are worktrees, so the row was on
# almost always and said nothing. It looks for the graph beside the common git
# dir now: `.git` from the checkout that holds it, that checkout's .git in
# full from any worktree.
sleep 1
mkdir -p "$MTR/graphify-out" && printf '{}\n' > "$MTR/graphify-out/graph.json"
MTW="$TMP/maint-worktree"
( _fx_cd "$MTR" && git worktree add -q "$MTW" -b maint-wt ) >/dev/null 2>&1
MTW="$(cd "$MTW" && pwd -P)"
has "the checkout holding the graph is ok"                      "$(_mst "$MTR")" "ok	graphify"
has "and a worktree of it reads the same graph, and is ok too"  "$(_mst "$MTW")" "ok	graphify"
# The commit compared against is the one the checkout HOLDING the graph stands
# on, not the one the caller stands on. Work that exists only in a worktree is
# work no refresh would put in the graph — graphify reads the holding checkout
# — so calling the graph stale over it is a row that is on in every worktree
# session and cannot be satisfied by the thing it asks for.
sleep 1
( _fx_cd "$MTW" && printf 'w\n' > d.txt && git add -A \
  && git -c user.name=t -c user.email=t@t commit -qm "worktree commit" ) >/dev/null 2>&1
has "work committed only in a worktree does not make the graph stale" "$(_mst "$MTW")" "ok	graphify"
has "and the checkout the graph was built from reads ok as well"      "$(_mst "$MTR")" "ok	graphify"
# The holding checkout moving is the thing that does, and it reads the same
# from both places, because it is one fact about one graph.
sleep 1
( _fx_cd "$MTR" && printf 'e\n' > e.txt && git add -A \
  && git -c user.name=t -c user.email=t@t commit -qm "checkout commit" ) >/dev/null 2>&1
has "a commit in the checkout the graph was built from is due"        "$(_mst "$MTR")" "due	graphify"
has "and due from the worktree too, which is where the session is"    "$(_mst "$MTW")" "due	graphify"
# And the command renders a checked row as a fact, not as a clock. The ok
# branch printed `${age}d ago  every ${cadence}d`, which for a checked event
# row came out as `-d ago  every 0d` — a number nobody wrote, in a row that
# is about whether a check passed.
# Saved and put back: the widget's table is built by an earlier section and
# read by later ones, and a fixture left holding this section's rows would
# change what those sections see without any of them saying so.
# Kept only where it exists: run alone it is absent, and it is then taken away again below.
_maint_had=0; if [ -f "$FROOT/projects/widget/maintenance.tsv" ]; then cp "$FROOT/projects/widget/maintenance.tsv" "$TMP/maint.keep"; _maint_had=1; fi
printf 'graphify\t0\talways\tthe map\ttest -f WIDGET.txt\n' > "$FROOT/projects/widget/maintenance.tsv"
out="$(cd "$REPO" && "$FELIX" maintenance 2>&1)"
has "felix maintenance renders a passing check as such"   "$out" "check passed"
printf 'graphify\t0\talways\tthe map\ttest -f nothing-here\n' > "$FROOT/projects/widget/maintenance.tsv"
out="$(cd "$REPO" && "$FELIX" maintenance 2>&1)"
has "and a failing one as due for that reason"             "$out" "check failed"
case "$out" in
  *"-d ago"*|*"every 0d"*) bad "and never as a clock reading nobody wrote" "$out" ;;
  *)                       ok  "and never as a clock reading nobody wrote" ;;
esac
if [ "$_maint_had" = 1 ]; then cp "$TMP/maint.keep" "$FROOT/projects/widget/maintenance.tsv"; else rm -f "$FROOT/projects/widget/maintenance.tsv"; fi

