_autocomm_build revoked
_cmstub_build
_widget_repo_build
_discover_fixtures_build
[ -s "$FROOT/projects/widget/capabilities" ] || printf 'frontend\ne2e\n' > "$FROOT/projects/widget/capabilities"
# The background resume refuses on each of those, and is silent about it —
# an ungranted project must not learn that a grant exists from a log entry.
_bg() { ( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/detect.sh"
          . "$FROOT/harness/lib/commission.sh"; . "$FROOT/harness/lib/autonomy.sh"
          cd "$REPO" && felix_commission_resume_bg "$AUC" "$TMP/autocomm-home" "$FELIX"
          sleep 1 ); }
_bg
is "an ungranted project starts no background run" \
   "$([ -f "$TMP/autocomm-home/state/commission/autocomm.bg.log" ] && echo ran || echo silent)" "silent"

# And the load-bearing claim, made falsifiable: a granted run DECLARES and
# installs nothing.
#
# The claim is that the grant governs when a declaration happens, never what
# gets installed. That is not a promise about intent — it is a property of the
# path: felix_commission_apply_declares appends a stack.tsv row and a log line,
# and no installer is downstream of it. Installing those rows is still
# felix stack apply, which a person still runs.
#
# Asserted against the stub CLI's log, because "installs nothing" is a
# statement about what reached `claude`, not about what the source intends.
# Asserted at the function that applies a verdict, because that is where an
# install would have to happen if one happened at all. A first draft asserted
# it over a whole `felix commission` run and found an empty stub log — which
# passed, and meant only that the run never reached the CLI. The positive
# control below is what caught that: the row must appear, or "nothing was
# installed" is a statement about a path nothing walked.
AUD="$TMP/applydecl"; mkdir -p "$AUD" "$MEM/applydecl"
printf '# kind\tname\n' > "$AUD/stack.tsv"
: > "$CMSTUB_LOG"
( PATH="$CMSTUB:$PATH"
  . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/detect.sh"
  . "$FROOT/harness/lib/admit.sh"; . "$FROOT/harness/lib/commission.sh"
  . "$FROOT/harness/lib/commission-provider.sh"
  felix_commission_apply_declares "$AUD" "$REPO" \
    "$(printf 'declare\tplugin\tsomeplugin@x\tlow\talways\tdeadbeef\tinspected\n')" \
    treeid policyv someneed ) >/dev/null 2>&1
is "an admitted nomination becomes a declared row" \
   "$(grep -c 'someplugin' "$AUD/stack.tsv" 2>/dev/null | tr -d ' ')" "1"
has "carrying the grounding that says the engine read it" \
    "$(cat "$AUD/stack.tsv")" "OBSERVED"
is "and nothing was installed to put it there" \
   "$(wc -l < "$CMSTUB_LOG" 2>/dev/null | tr -d ' ')" "0"

printf '\ntidying, with the checks that make it safe\n'
# Felix removing a file from a product repository unattended is the sharpest
# trust boundary in the system. Every check below must hold, and the file must
# still exist somewhere afterwards.
TR="$TMP/tidyrepo"; TH2="$TMP/tidyhome"; TP2="$TH2/projects/widget"
mkdir -p "$TR/scripts" "$TP2"
( _fx_cd "$TR" && git init -q . && git config user.email t@t && git config user.name t )
printf 'tidy\n' > "$TP2/autonomy"
printf '#!/bin/sh\necho felix\n' > "$TP2/prepush.sh"
# 1. untracked, and Felix holds a copy of that name -> removable
printf '#!/bin/sh\necho repo\n' > "$TR/scripts/prepush.sh"
# 2. TRACKED, even though Felix holds it -> deleting changes the repo's tracked
#    state, which is a different and much larger act than removing a stray file
printf '#!/bin/sh\necho felix\n' > "$TP2/gate.sh"
printf '#!/bin/sh\necho tracked\n' > "$TR/scripts/gate.sh"
( _fx_cd "$TR" && git add scripts/gate.sh && git commit -qm base )
# 3. Felix holds nothing of that name -> may be the only copy anywhere
printf '#!/bin/sh\necho only\n' > "$TR/scripts/verify-mine.sh"
chmod +x "$TR"/scripts/*.sh

out="$( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/detect.sh"; . "$FROOT/harness/lib/autonomy.sh"
        felix_tidy_safe "$TP2" "$TR" "$TH2" )"
[ -f "$TR/scripts/prepush.sh" ] && bad "removes an untracked copy Felix holds" \
                                || ok  "removes an untracked copy Felix holds"
[ -f "$TR/scripts/gate.sh" ]    && ok  "keeps a tracked one, whatever else is true" \
                                || bad "keeps a tracked one, whatever else is true"
[ -f "$TR/scripts/verify-mine.sh" ] && ok  "keeps one Felix holds no copy of" \
                                    || bad "keeps one Felix holds no copy of"
has "and says what it removed" "$out" "scripts/prepush.sh"
ls "$TH2/state/rivals"/*prepush* >/dev/null 2>&1 \
  && ok "the removed file still exists somewhere" || bad "the removed file still exists somewhere"

# Opt-out is absolute: no autonomy file, no removal, however safe it looks.
rm -f "$TP2/autonomy"
printf '#!/bin/sh\necho repo2\n' > "$TR/scripts/prepush.sh"; chmod +x "$TR/scripts/prepush.sh"
( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/detect.sh"; . "$FROOT/harness/lib/autonomy.sh"; felix_tidy_safe "$TP2" "$TR" "$TH2" ) >/dev/null
[ -f "$TR/scripts/prepush.sh" ] && ok  "without opting in, nothing is touched" \
                                || bad "without opting in, nothing is touched"

printf '\nexecution shape, computed rather than felt\n'
# Whether work fans out or stays in one context was decided by taste every time,
# which means it held on one machine for one person. Files that overlap cannot
# be worked in parallel: that half is mechanical, it is a refusal, and it binds.
SP="$TMP/plan.md"
cat > "$SP" <<'EOF'
### Task 1: One

**Files:**
- Create: `lib/a.sh`
- Test: `tests/run`

### Task 2: Two

**Files:**
- Modify: `lib/a.sh:12-20`
- Test: `tests/run`

### Task 3: Three

**Files:**
- Modify: `docs/x.md`

### Task 4: Four

**Files:**
- Modify: `README.md`
EOF
u="$( . "$FROOT/harness/lib/shape.sh"; felix_shape_units "$SP" | tr '\n' ' ' )"
has "reads the files a task declares"  "$u" "1	lib/a.sh"
has "and strips a line range"          "$u" "2	lib/a.sh"

g="$( . "$FROOT/harness/lib/shape.sh"; felix_shape_groups "$SP" )"
has "tasks sharing a file are one unit"     "$g" "1,2"
# 3 and 4 touch nothing anyone else touches, so they are genuinely separable.
has "and one that shares nothing stands alone" "$g" "3"
has "as does another"                          "$g" "4"
n="$(printf '%s\n' "$g" | grep -c . )"
is "three groups from four tasks" "$n" "3"

# A plan with no Files blocks cannot be judged, and saying so is the answer.
printf '# a plan with no files\n\n### Task 1: x\n\nnothing declared\n' > "$TMP/bare.md"
g="$( . "$FROOT/harness/lib/shape.sh"; felix_shape_groups "$TMP/bare.md" | tr -d '\n ' )"
is "a plan declaring no files yields nothing" "$g" ""

printf '\ndoctor fixes what it can instead of reporting it\n'
# A founder should never be told where a duplicate script lives. Felix holds the
# authoritative copy, so removing the lookalike loses nothing and is exactly the
# reversible work the charter says to do rather than escalate.
mkdir -p "$REPO/scripts"
printf '#!/bin/sh\necho felix copy\n' > "$FROOT/projects/widget/prepush.sh"
printf '#!/bin/sh\necho stale repo copy\n' > "$REPO/scripts/prepush.sh"
chmod +x "$FROOT/projects/widget/prepush.sh" "$REPO/scripts/prepush.sh"
# A gate-named script Felix does NOT hold. Removing this would destroy the only
# copy, so it stays and is reported.
printf '#!/bin/sh\necho mine\n' > "$REPO/scripts/gate-extra.sh"; chmod +x "$REPO/scripts/gate-extra.sh"

out="$(cd "$REPO" && "$FELIX" doctor --fix 2>&1)"
[ -f "$REPO/scripts/prepush.sh" ] && bad "removes a copy of a file Felix holds" \
                                  || ok  "removes a copy of a file Felix holds"
[ -f "$REPO/scripts/gate-extra.sh" ] && ok  "and keeps one Felix does not hold" \
                                     || bad "and keeps one Felix does not hold"
has "saying why it kept it" "$out" "gate-extra.sh"
# Nothing is destroyed. The copy is recoverable even though git never tracked it.
ls "$FROOT/state/rivals"/*prepush* >/dev/null 2>&1 \
  && ok "backs the removed copy up first" || bad "backs the removed copy up first"
out="$(cd "$REPO" && "$FELIX" doctor --fix 2>&1)"
case "$out" in
  *"prepush.sh"*) bad "and says nothing about it afterwards" "$out" ;;
  *)              ok  "and says nothing about it afterwards" ;;
esac
rm -rf "$REPO/scripts" "$FROOT/projects/widget/prepush.sh"

printf '\nthe toolbox: reach, analyse, and whether anything can route it\n'
# Felix could read a plugin it had fetched from a marketplace and could not read
# one already installed, which is the one it will actually be asked about. The
# shape is identical, so this is a path resolver rather than a second analyser.
TB="$TMP/plugincache"
mkdir -p "$TB/mkt/alpha/1.9.0/skills/one" "$TB/mkt/alpha/1.10.0/skills/one" \
         "$TB/mkt/alpha/1.10.0/skills/two" "$TB/mkt/hooky/0.1.0/hooks"
printf '{"hooks":{}}\n' > "$TB/mkt/hooky/0.1.0/hooks/hooks.json"

p="$( . "$FROOT/harness/lib/toolbox.sh"; FELIX_PLUGIN_CACHE="$TB" felix_toolbox_path alpha )"
is "resolves an installed plugin to its newest version" "$(basename "$p")" "1.10.0"
# 1.10.0 beats 1.9.0 only under -V. The gate's installed check was once wrong
# for exactly this reason, picking a directory nothing loads.
p="$( . "$FROOT/harness/lib/toolbox.sh"; FELIX_PLUGIN_CACHE="$TB" felix_toolbox_path nosuch )" || true
is "and reports nothing for one it does not have" "$p" ""

sk="$( . "$FROOT/harness/lib/toolbox.sh"
       FELIX_PLUGIN_CACHE="$TB" felix_toolbox_skills "$(FELIX_PLUGIN_CACHE="$TB" felix_toolbox_path alpha)" | tr '\n' ' ' )"
has "lists the skills a plugin ships" "$sk" "one"
has "all of them"                    "$sk" "two"

# The last column is the point. A tool no route names is never reached for and
# costs context in every session anyway.
TP="$TMP/tbproj"; mkdir -p "$TP"
printf 'core\talways\nbackend\tapi,database\n'                        > "$TP/profiles.tsv"
printf 'web\tendpoint handler\tbackend\tplaywright\n'                 > "$TP/routes.tsv"
r="$( . "$FROOT/harness/lib/toolbox.sh"; felix_toolbox_routed "$TP" playwright && echo yes || echo no )"
is "sees a plugin a route already names" "$r" "yes"
r="$( . "$FROOT/harness/lib/toolbox.sh"; felix_toolbox_routed "$TP" deepeval && echo yes || echo no )"
is "and one no route names"              "$r" "no"

r="$( . "$FROOT/harness/lib/toolbox.sh"; felix_toolbox_route_for "$TP" database | tr '\n' ' ' )"
has "finds the route a capability belongs to" "$r" "web"
# The empty answer is the useful one: another governed project declares llm, no profile covers
# it, and that is exactly why three tools adopted for llm can never be reached.
r="$( . "$FROOT/harness/lib/toolbox.sh"; felix_toolbox_route_for "$TP" llm | tr -d '\n ' )"
is "and says so plainly when none does" "$r" ""
# `always` must not act as a wildcard, or every capability routes to core and
# the report succeeds at everything and reports nothing.
r="$( . "$FROOT/harness/lib/toolbox.sh"; felix_toolbox_route_for "$TP" frontend | tr -d '\n ' )"
is "always is a profile, not a wildcard" "$r" ""

# Wiring a tool in. Appended, never reordered: a play is ordered and the router
# names the first unused entry, so inserting would change what gets reached for
# first, which is not what "also make this reachable" means.
printf '# a comment that explains why the row is here\n' >  "$TP/routes.tsv"
printf 'web\tendpoint handler\tbackend\tplaywright\n'     >> "$TP/routes.tsv"
printf 'bare\tthing\tbackend\t-\n'                        >> "$TP/routes.tsv"
( . "$FROOT/harness/lib/route.sh"; felix_route_append_play "$TP" web deepeval ) \
  && ok "wires a tool into a route" || bad "wires a tool into a route"
has "appended after what was there" "$(grep '^web' "$TP/routes.tsv")" "playwright deepeval"
has "and the comment survives"      "$(head -1 "$TP/routes.tsv")"     "explains why"
( . "$FROOT/harness/lib/route.sh"; felix_route_append_play "$TP" web deepeval ) \
  && bad "wiring the same tool twice is refused" || ok "wiring the same tool twice is refused"
( . "$FROOT/harness/lib/route.sh"; felix_route_append_play "$TP" nosuch deepeval ) \
  && bad "wiring into a route that does not exist is refused" \
  || ok "wiring into a route that does not exist is refused"
# `-` means no play. Appending to it would name a tool called "-".
( . "$FROOT/harness/lib/route.sh"; felix_route_append_play "$TP" bare semgrep ) >/dev/null
is "an empty play is replaced, not appended to" "$(grep '^bare' "$TP/routes.tsv" | cut -f4)" "semgrep"

printf '\ndiscovery declares what it has read and judged safe\n'
# Felix already read the candidate at its pinned sha and already scored the
# risk. Stopping there and handing the founder a shopping list was the
# governance charter talking: if the founder is thinking about tooling, Felix
# has failed. Declaring is a manifest edit, which detection was always allowed
# to do unattended.
AH="$TMP/adopthome"; mkdir -p "$AH/state/discover"
AP="$AH/projects/widget"; mkdir -p "$AP"
printf 'plugin\tlangfuse@x\t-\tlow\tllm\n' > "$AP/stack.tsv"
# A real cache: three tiers, one already declared, and — from the actual felix
# cache — prose where rows were expected. A parser that adopts a sentence is
# worse than one that adopts nothing.
{ _dstamp; cat; } > "$AH/state/discover/widget.tsv" <<'EOF'
deepeval	llm	low
langfuse	llm	low
figma	frontend	medium
outputai	llm	high
Nothing in the marketplaces matches what widget declares.
EOF
out="$( . "$FROOT/harness/lib/discover.sh"; felix_discover_adopt "$AP" "$AH" )"
has "a low-risk candidate is declared"        "$out" "declare	deepeval"
has "a medium one is refused"                 "$out" "refuse	figma"
has "and a high one is refused"               "$out" "refuse	outputai"
has "one already declared is left alone"      "$out" "already	langfuse"
case "$out" in
  *Nothing*|*marketplaces*) bad "prose in the cache is not adopted" "$out" ;;
  *)                        ok  "prose in the cache is not adopted" ;;
esac

# The cache carries the provenance of its verdicts. On the first live
# commissioning run a five-day-old cache written by a since-fixed matcher
# declared and installed a storage plugin under llm, twice, because nothing
# the adopt path read had changed when the matcher did. A cache without the
# current stamp is absent to every reader, and discover --adopt refills it.
printf 'deepeval\tllm\tlow\n' > "$AH/state/discover/widget.tsv"
is "a cache with no stamp adopts nothing" \
   "$( . "$FROOT/harness/lib/discover.sh"; felix_discover_adopt "$AP" "$AH" )" ""
( . "$FROOT/harness/lib/discover.sh"; felix_discover_stale "$AP" "$AH" ) \
  && ok "and reads stale whatever its age" || bad "and reads stale whatever its age"
is "and surfaces nothing as new" \
   "$( . "$FROOT/harness/lib/discover.sh"; felix_discover_unseen "$AP" "$AH" )" ""
{ printf '# stamp 0000000000000000000000000000000000000000\n'; printf 'deepeval\tllm\tlow\n'; } > "$AH/state/discover/widget.tsv"
is "a cache stamped by other rules adopts nothing either" \
   "$( . "$FROOT/harness/lib/discover.sh"; felix_discover_adopt "$AP" "$AH" )" ""
DRS="$TMP/other-rules"; mkdir -p "$DRS"; printf 'llm\tllm rag\n' > "$DRS/discover-rules.tsv"
case "$( . "$FROOT/harness/lib/discover.sh"; _felix_discover_stamp "$DRS" )" in
  "$( . "$FROOT/harness/lib/discover.sh"; _felix_discover_stamp "$FROOT/harness/templates" )") bad "the stamp changes with the rules table" ;;
  *) ok "the stamp changes with the rules table" ;;
esac
# Through the command, with the stub cli: a mismatched cache is refilled
# before anything is adopted, and an empty result is a stamp and no prose.
# In a home of its own, state/ and all: a refresh an earlier block's hook forked writes
# $FROOT/state/discover/widget.tsv whenever it finishes (part 0290 holds one open to show it).
RFH="$TMP/refill-home"; mkdir -p "$RFH/state/discover"
[ -e "$RFH/projects" ] || ln -s "$FROOT/projects" "$RFH/projects"
printf 'stalerow\tllm\tlow\n' > "$RFH/state/discover/widget.tsv"
out="$(cd "$REPO" && PATH="$CMSTUB:$PATH" FELIX_HOME="$RFH" "$FELIX" discover --adopt 2>&1)"
has "discover --adopt refills a cache the current rules did not write" "$out" "filling the discovery cache"
is  "and the refilled cache begins with the stamp" \
    "$(head -1 "$RFH/state/discover/widget.tsv")" "$(_dstamp | tr -d '\n')"
is  "and holds no prose when nothing matched" "$(grep -vc '^#' "$RFH/state/discover/widget.tsv")" "0"
case "$out" in *stalerow*) bad "and the stale row was not adopted" "$out" ;; *) ok "and the stale row was not adopted" ;; esac
n="$(printf '%s\n' "$out" | grep -c '^declare' || true)"
is "exactly one declaration from that cache" "$n" "1"

why="$( . "$FROOT/harness/lib/discover.sh"; felix_discover_why "$(felix_discover_inspect "$DF/creds")" )"
has "and says which variable it sends" "$why" "environment variable"

# The whole safety argument is that fetched source is read and never run. A
# fixture whose hook would create a sentinel proves it: if the file appears,
# this stage has stopped being static analysis.
mkdir -p "$DF/hostile/hooks"
printf '{"hooks":{"SessionStart":[{"hooks":[{"command":"touch %s/PWNED"}]}]}}\n' "$DF" > "$DF/hostile/hooks/hooks.json"
( . "$FROOT/harness/lib/discover.sh"; felix_discover_inspect "$DF/hostile" >/dev/null 2>&1 )
[ -e "$DF/PWNED" ] && bad "inspecting a plugin never runs it" "sentinel was created" \
                   || ok "inspecting a plugin never runs it"

# It recommends. It must never acquire.
#
# Against a catalogue this suite writes. Both runs used to inherit the PATH, so
# felix discover ran the real claude, read this machine's whole plugin
# catalogue and scored every entry: 516 s of CPU on 2026-10-13, a quarter of
# the suite, from this one assertion (docs/2026-10-13-gate-friction-contract-b.md).
# On a machine with no claude it stopped before reading anything, so "writes
# nothing" held over a run that read nothing. Now a stub claude stands first on
# PATH, logs every call, answers the one listing felix discover asks for from a
# three-entry catalogue and refuses any shape it was not taught, as CMSTUB does.
# Two entries are candidates for widget under templates/discover-rules.tsv, a
# keyword in an entry's name scoring 3, the threshold: storybook-helper for
# frontend, which widget declares by here (with e2e, measured 2026-10-13), and
# llm-eval-kit for llm, which part 1270 declares when it re-runs this block
# alone. The plain run lists and fetches nothing, so the catalogue is all it
# reads.
DSTUB="$TMP/discover-stub"; mkdir -p "$DSTUB"; DSLOG="$TMP/discover-stub.log"; : > "$DSLOG"
cat > "$DSTUB/catalogue.json" <<'DSCAT'
[
  {
    "name": "storybook-helper",
    "description": "Storybook component stories and tailwind css helpers",
    "marketplaceName": "suite-market"
  },
  {
    "name": "llm-eval-kit",
    "description": "Evaluate llm prompts",
    "marketplaceName": "suite-market"
  },
  {
    "name": "pasta-recipes",
    "description": "Dinner ideas for a weeknight",
    "marketplaceName": "suite-market"
  }
]
DSCAT
cat > "$DSTUB/claude" <<DSSTUB
#!/bin/sh
printf '%s\n' "\$*" >> "$DSLOG"
case "\$*" in
  "plugin list --json --available") cat "$DSTUB/catalogue.json" ;;
  *) printf 'stub: untaught shape: %s\n' "\$*" >&2; exit 2 ;;
esac
DSSTUB
chmod +x "$DSTUB/claude"
# Serially widget's stack.tsv holds the three rows _router_build tables writes (0230 is the last
# part before this one to change it); run alone it is absent, and a discover that rewrote an
# existing file would show only serially. So when it is absent the block writes those rows,
# and takes them away again after its last read.
_dstk_wrote=0
if [ ! -f "$FROOT/projects/widget/stack.tsv" ]; then
  printf 'plugin\tfrontend-design@claude-plugins-official\t-\tlow\tfrontend\nplugin\tplaywright@claude-plugins-official\t-\tlow\te2e\nskill\timpeccable\t-\tlow\tfrontend\n' > "$FROOT/projects/widget/stack.tsv" && _dstk_wrote=1
fi
before="$(cksum < "$FROOT/projects/widget/stack.tsv")"
out="$(cd "$REPO" && PATH="$DSTUB:$PATH" "$FELIX" discover 2>&1)"; rc=$?
after="$(cksum < "$FROOT/projects/widget/stack.tsv")"
[ "$_dstk_wrote" = 1 ] && rm -f "$FROOT/projects/widget/stack.tsv"
is "discovery writes nothing" "$after" "$before"
# Without this, "writes nothing" can pass over a run that matched nothing or
# stopped early: a statement about a path nothing walked. The decoy must not
# list, or a discover that printed the whole catalogue unfiltered would pass.
case "$out" in
  *pasta-recipes*) bad "discovery lists the catalogue's matching entry, from the stub's catalogue" "the decoy listed: $out" ;;
  *storybook-helper*|*llm-eval-kit*) ok "discovery lists the catalogue's matching entry, from the stub's catalogue" ;;
  *) bad "discovery lists the catalogue's matching entry, from the stub's catalogue" "$out" ;;
esac
out="$(cd "$REPO" && PATH="$DSTUB:$PATH" "$FELIX" discover --yes 2>&1)"; rc=$?
[ "$rc" -ne 0 ] && ok "there is no --yes" || bad "there is no --yes" "$out"

printf '\nseeing the whole toolbox\n'
# No single source knows every plugin. The CLI misses everything bundled into
# the binary; the on-disk registry misses it too; only the config records it.
# Felix has to work on somebody else's laptop, laid out however they left it,
# so the inventory unions every source and each one is optional.
INV="$( . "$FROOT/harness/lib/ready.sh"; felix_ready_inventory 2>/dev/null )"
# Only where the CLI can see a plugin installed here: a unit of P's run has a HOME of its own (slice 3, A17), and
# under the land tick's environment the CLI then lists none, which reads as a machine with nothing installed.
if has_claude && [ "$(claude plugin list --json 2>/dev/null | LC_ALL=C grep -c '"id"')" -gt 0 ]; then
  n_plug="$(printf '%s\n' "$INV" | grep -c '^plugin' || true)"
  # A static name. It read `ok "finds plugins ($n_plug)"`, and the count is how
  # many plugins THIS machine has — so the name differed between the machine
  # that recorded the manifest and every other one, and the skip on line below
  # uses a third spelling again. The manifest reported it as an assertion that
  # never ran, which was its own false alarm. An assertion's name identifies it;
  # anything varying by machine belongs in the detail, not the name.
  [ "${n_plug:-0}" -gt 0 ] && ok "finds plugins" || bad "finds plugins" "none"
else
  skip "finds plugins" "no claude CLI, or one that lists no plugin"
fi
# Nothing may appear twice however many sources reported it.
dupes="$(printf '%s\n' "$INV" | sort | uniq -d | grep -c . || true)"
is "no entry is listed twice" "${dupes:-0}" "0"
# A version string is not a plugin. The @inline scan picks them up otherwise.
case "$INV" in
  *"	1.0.0"*|*"	2.0.0"*) bad "version strings are not mistaken for plugins" "$INV" ;;
  *) ok "version strings are not mistaken for plugins" ;;
esac
# With no config and no CLI it must still answer from disk rather than die.
out="$( . "$FROOT/harness/lib/ready.sh"; HOME="$TMP/empty-home" felix_ready_inventory 2>&1 )"; rc=$?
is "survives a machine laid out differently" "$rc" "0"

printf '\ndetection reads what a project depends on\n'
DREPO="$TMP/detectrepo"; mkdir -p "$DREPO/src/web/static"
printf '[project]\ndependencies = ["anthropic>=0.40", "fastapi"]\n' > "$DREPO/pyproject.toml"
for i in 1 2 3; do printf 'x\n' > "$DREPO/src/web/static/a$i.js"; done
caps="$( . "$FROOT/harness/lib/detect.sh"; felix_detect "$DREPO" | sort -u | tr '\n' ' ' )"
has "an SDK dependency makes it an llm project" "$caps" "llm"
# package.json was the entire frontend test, which misses every web surface
# served by a backend.
has "a web surface counts without package.json" "$caps" "frontend"
printf '[package]\nname = "x"\n' > "$DREPO/Cargo.toml"
caps="$( . "$FROOT/harness/lib/detect.sh"; felix_detect "$DREPO" | sort -u | tr '\n' ' ' )"
has "a cargo crate is a rust project" "$caps" "rust"

