printf '\nthe reconciler reads the record: reached beside needed\n'
# Decision C step 3 (2026-08-30). The ledger records which MCP servers were
# reached beside which a play named; stack.tsv records which are declared.
# The reconciler proposes from that record and only that record — it installs
# nothing, removes nothing, and edits nothing.
# The fixture holds every shape the pipeline actually writes. figma is the
# declared-named-never-reached case in both its shapes: the rollup records a
# play-named-unreached entry with kind `named`, and bleed-era data recorded it
# as an mcp zero row — the unmount rule must see both, which is why it reads
# the kind-agnostic summary. ghost is the residue after a person obeys an
# unmount and deletes the row: its named counts are Felix's own routing
# priors, and proposing a mount from them would flip the same rows back and
# forth forever. idle is an undeclared server with no evidence at all — the
# row an unconditional mount branch would trip over.
# The widget declares the capabilities 0230 gives it; this part alone finds none.
[ -f "$FROOT/projects/widget/capabilities" ] || printf 'frontend\ne2e\n' > "$FROOT/projects/widget/capabilities"
# The reconciler asks the plugin registry whether a reached name is a plugin,
# so the registry has to be a fixture. Read from $HOME, and unpinned these
# assertions would answer differently on a laptop that happens to have a plugin
# by the fixture's name installed than on a runner that does not — a suite that
# passes in CI and fails at the desk, or the reverse. `provided` is a plugin
# here and `context7` deliberately is not.
RCH="$TMP/recon-home"; mkdir -p "$RCH/.claude/plugins"
printf '{"plugins":{"provided@x":{"version":"1.0.0","installPath":"/tmp/provided"}}}\n' \
  > "$RCH/.claude/plugins/installed_plugins.json"
RCL="$TMP/reconlib"; mkdir -p "$RCL" "$MEM/reconlib"
cat > "$MEM/reconlib/ledger.tsv" <<'EOF'
s1	2026-08-01	mcp	context7	4	0
s2	2026-08-02	mcp	context7	2	0
s1	2026-08-01	named	figma	0	1
s2	2026-08-02	named	figma	0	1
s3	2026-08-03	mcp	figma@x	0	1
s1	2026-08-01	mcp	gh	5	1
s1	2026-08-01	mcp	quiet	0	0
s2	2026-08-02	mcp	quiet	0	0
s3	2026-08-03	mcp	quiet	0	0
s1	2026-08-01	mcp	ghost	0	2
s2	2026-08-02	mcp	ghost	0	2
s3	2026-08-03	mcp	ghost	0	2
s1	2026-08-01	mcp	idle	0	0
s1	2026-08-01	named	wanted	0	2
s1	2026-08-01	mcp	dup	1	0
s1	2026-08-01	mcp	dup@x	2	0
s1	2026-08-01	tool	Bash	9	0
s1	2026-08-01	plugin	superpowers@x	3	1
EOF
m="$( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/ledger.sh"
      felix_ledger_mcp "$RCL" )"
has "the mcp record aggregates a server across sessions" "$m" "context7	2	6	0"
has "two rows in one session are one session, calls summed" "$m" "dup	1	3	0"
case "$m" in
  *Bash*|*superpowers*|*wanted*) bad "and reads only mcp rows" "$m" ;;
  *)                             ok  "and reads only mcp rows" ;;
esac

{ printf 'mcp\tfigma@x\t-\tmedium\talways\n'
  printf 'mcp\tgh\t-\tmedium\talways\n'
  printf 'mcp\tquiet\t-\tmedium\talways\n'
  printf 'mcp\tdup\t-\tlow\talways\n'
} > "$RCL/stack.tsv"
r="$( HOME="$RCH"; . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/ledger.sh"
      . "$FROOT/harness/lib/stack.sh"; FELIX_LEDGER_MIN=3 felix_stack_reconcile "$RCL" )"
has "proposes mounting what was reached and never declared" "$r" "mount	context7"
has "proposes unmounting what was named and never reached, whatever shape recorded it" \
    "$r" "unmount	figma	named 3 time(s) across 3 session(s)"
is  "a reach is the only mount evidence there is" \
    "$(printf '%s\n' "$r" | grep -c '^mount')" "1"
is  "and the unmount above is the only other proposal" \
    "$(printf '%s\n' "$r" | grep -c '^unmount')" "1"
case "$r" in
  *"	gh	"*) bad "never proposes unmounting what was reached" "$r" ;;
  *)          ok  "never proposes unmounting what was reached" ;;
esac
case "$r" in
  *quiet*) bad "a declared server no play ever named is left alone" "$r" ;;
  *)       ok  "a declared server no play ever named is left alone" ;;
esac
case "$r" in
  *ghost*) bad "rows outliving a deleted declaration do not propose a mount" "$r" ;;
  *)       ok  "rows outliving a deleted declaration do not propose a mount" ;;
esac
r="$( HOME="$RCH"; . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/ledger.sh"
      . "$FROOT/harness/lib/stack.sh"; FELIX_LEDGER_MIN=5 felix_stack_reconcile "$RCL" )"
is "an unmount below the session threshold is not evidence" \
   "$(printf '%s\n' "$r" | grep -c '^unmount' | tr -d ' ')" "0"
has "while a mount needs no threshold: the reach already happened" "$r" "mount	context7"

# A server a plugin provides is a plugin row, not an mcp row.
#
# felix_ledger_mcp folds `plugin_<plugin>_<server>` to `<plugin>`, so the name
# that arrives here is the plugin's. `declared` reads kind mcp and nothing
# else, so a project that declares the plugin and reaches for its server was
# told "no row declares it" — one governed project had the same capability on
# the mount list for hundreds of reaches and on the retire list for zero
# invocations at once. And the proposal a person was sent to act on named a
# kind that could never match what the ledger records: `claude mcp add` has
# nothing to add for a server a plugin ships.
printf 's9	2026-08-01	mcp	plugin_provided_srv	4	0
' >> "$MEM/reconlib/ledger.tsv"
r="$( HOME="$RCH"; . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/ledger.sh"
      . "$FROOT/harness/lib/stack.sh"; FELIX_LEDGER_MIN=3 felix_stack_reconcile "$RCL" )"
has "a server the registry says a plugin provides is proposed as a plugin row" \
    "$r" "declare	provided"
case "$r" in
  *"mount	provided"*) bad "and never as an mcp row nothing could add" "$r" ;;
  *)                   ok  "and never as an mcp row nothing could add" ;;
esac
# And declaring that plugin answers it. This is the contradiction closing: the
# same name can no longer be proposed for mounting while a row declares it.
printf 'plugin	provided@x	-	low	always
' >> "$RCL/stack.tsv"
r="$( HOME="$RCH"; . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/ledger.sh"
      . "$FROOT/harness/lib/stack.sh"; FELIX_LEDGER_MIN=3 felix_stack_reconcile "$RCL" )"
case "$r" in
  *provided*) bad "a declared plugin's server is proposed no further" "$r" ;;
  *)          ok  "a declared plugin's server is proposed no further" ;;
esac
# The plugin declaration is for the mount side alone. Widening the unmount
# set to plugin rows would have this propose unmounting everything
# felix_ledger_retire already proposes retiring — one finding, two
# vocabularies, from one table.
is "and declaring a plugin does not turn the retire rule into an unmount" \
   "$(printf '%s\n' "$r" | grep -c '^unmount' | tr -d ' ')" "1"

# A project that never declared a stack still has a record worth reading.
RNS="$TMP/reconnostack"; mkdir -p "$RNS" "$MEM/reconnostack"
printf 's1\t2026-08-01\tmcp\tcontext7\t4\t0\n' > "$MEM/reconnostack/ledger.tsv"
r="$( HOME="$RCH"; . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/ledger.sh"
      . "$FROOT/harness/lib/stack.sh"; felix_stack_reconcile "$RNS" )"
has "no stack.tsv means nothing is declared, not nothing to say" "$r" "mount	context7"

# The CLI surface, driven end to end against a governed fixture. The command
# must render the proposals, act on none of them, and exit 0 — drift reported
# is not a failure.
_recon_build
_stack_before="$(cat "$FROOT/projects/reconproj/stack.tsv")"
out="$(cd "$RREPO" && FELIX_LEDGER_MIN=3 "$FELIX" stack reconcile 2>&1)"; rc=$?
is  "felix stack reconcile exits 0"                    "$rc" "0"
has "it renders the mount"                             "$out" "context7"
has "it renders the unmount with its evidence"         "$out" "never reached"
has "and says plainly that it acted on nothing"        "$out" "Proposals only"
is  "stack.tsv is byte-identical after a reconcile" \
    "$(cat "$FROOT/projects/reconproj/stack.tsv")" "$_stack_before"
mv "$FROOT/projects/reconproj/stack.tsv" "$TMP/reconproj-stack-aside"
out="$(cd "$RREPO" && "$FELIX" stack reconcile 2>&1)"; rc=$?
is  "reconcile answers even where no stack.tsv exists" "$rc" "0"
has "and still proposes from the record"               "$out" "context7"
mv "$TMP/reconproj-stack-aside" "$FROOT/projects/reconproj/stack.tsv"

# The session boundary is the only place a mount decision can land, so the
# proposal has to surface there — one line, and the command holds the evidence.
# Once. A proposal shown and left unacted is an answer, and a host-provided
# server nobody should declare would otherwise nag at every session start
# forever, which is how a signal becomes wallpaper.
out="$(cd "$RREPO" && CLAUDE_PLUGIN_ROOT="$FROOT" FELIX_LEDGER_MIN=3 \
       "$FROOT/harness/hooks/session-start" 2>&1)"
has "session start surfaces the reconcile proposals" "$out" "felix stack reconcile"
out="$(cd "$RREPO" && CLAUDE_PLUGIN_ROOT="$FROOT" FELIX_LEDGER_MIN=3 \
       "$FROOT/harness/hooks/session-start" 2>&1)"
has "the second session is still bound" "$out" "Project: reconproj"
case "$out" in
  *"stack reconcile"*) bad "a proposal shown once is not volunteered again" "$out" ;;
  *)                   ok  "a proposal shown once is not volunteered again" ;;
esac

# But "once" is only safe for a proposal a later fold cannot overturn.
#
# A mount comes from a reach — calls above zero, which further folding can only
# confirm. An unmount comes from calls at zero, which is exactly what an
# unfolded session's reaches would falsify. This hook cannot fold, so it holds
# the zero-backed half rather than showing it and marking it seen: a held
# proposal returns on its own, a marked one is gone whether it was right or
# not. The retire line eleven lines above it has carried a hedge for this since
# it was written; the reconcile line carried none.
mkdir -p "$FROOT/projects/holdproj" "$MEM/holdproj"
cat > "$FROOT/projects/holdproj/project.json" <<'EOF'
{"name": "holdproj", "remote_match": "example.com/holdproj", "gate": "true"}
EOF
printf '# holdproj\n' > "$FROOT/projects/holdproj/CLAUDE.md"
printf 'mcp\tquietgh\t-\tmedium\talways\n' > "$FROOT/projects/holdproj/stack.tsv"
{ printf 'h1\t2026-08-01\tmcp\tquietgh\t0\t2\n'
  printf 'h2\t2026-08-01\tmcp\tquietgh\t0\t2\n'
  printf 'h3\t2026-08-01\tmcp\tquietgh\t0\t2\n'; } > "$MEM/holdproj/ledger.tsv"
HREPO="$TMP/hold-repo"; mkdir -p "$HREPO"
( _fx_cd "$HREPO" && git init -q -b main && printf 'x\n' > a.txt && git add -A \
  && git -c user.name=t -c user.email=t@t commit -qm i ) >/dev/null 2>&1
printf 'holdproj\n' > "$HREPO/.felix"
mkdir -p "$FROOT/state/ledger" "$FROOT/state/session"
printf '%s\n' "$(cd "$HREPO" && git rev-parse HEAD)" > "$FROOT/state/session/hstrand"
printf 'tool\tBash\n' > "$FROOT/state/ledger/hstrand.tsv"
out="$(cd "$HREPO" && CLAUDE_PLUGIN_ROOT="$FROOT" FELIX_LEDGER_MIN=3 \
       "$FROOT/harness/hooks/session-start" 2>&1)"
has "an unmount is held while calls sit unfolded on disk" "$out" "Held: 1 unmount proposal"
case "$out" in
  *"unmount:quietgh"*) bad "and is not proposed over a partial record" "$out" ;;
  *)                   ok  "and is not proposed over a partial record" ;;
esac
# Held, not hedged. The seen-gate never saw it, so it comes back by itself.
( cd "$HREPO" && FELIX_LEDGER_MIN=3 "$FELIX" ledger >/dev/null 2>&1 )
out="$(cd "$HREPO" && CLAUDE_PLUGIN_ROOT="$FROOT" FELIX_LEDGER_MIN=3 \
       "$FROOT/harness/hooks/session-start" 2>&1)"
has "and returns once the record is complete" "$out" "unmount:quietgh"

# And the command folds before it reads, which is what makes its own silence
# mean anything. It reads felix_ledger_summary directly, so without the fold
# "the record and the manifest agree" was said over whichever sessions
# happened to exit cleanly.
printf '%s\n' "$(cd "$HREPO" && git rev-parse HEAD)" > "$FROOT/state/session/hstrand2"
printf 'tool\tRead\n' > "$FROOT/state/ledger/hstrand2.tsv"
out="$(cd "$HREPO" && FELIX_LEDGER_MIN=3 "$FELIX" stack reconcile 2>&1)"
has "felix stack reconcile folds what nothing folded before reporting" \
    "$out" "whose record was behind what is on disk"
rm -f "$FROOT/state/ledger/hstrand.tsv" "$FROOT/state/ledger/hstrand2.tsv" \
      "$FROOT/state/session/hstrand" "$FROOT/state/session/hstrand2"
mkdir -p "$FROOT/projects/quietproj" "$MEM/quietproj"
cat > "$FROOT/projects/quietproj/project.json" <<'EOF'
{"name": "quietproj", "remote_match": "example.com/quietproj", "gate": "true"}
EOF
printf '# quietproj\n' > "$FROOT/projects/quietproj/CLAUDE.md"
printf 'mcp\tgh\t-\tmedium\talways\n' > "$FROOT/projects/quietproj/stack.tsv"
printf 's1\t2026-08-01\tmcp\tgh\t5\t1\n' > "$MEM/quietproj/ledger.tsv"
QREPO="$TMP/quiet-repo"; mkdir -p "$QREPO"
( _fx_cd "$QREPO" && git init -q -b main )
printf 'quietproj\n' > "$QREPO/.felix"
out="$(cd "$QREPO" && CLAUDE_PLUGIN_ROOT="$FROOT" \
       "$FROOT/harness/hooks/session-start" 2>&1)"
has "the quiet control did bind its project" "$out" "Project: quietproj"
case "$out" in
  *"stack reconcile"*) bad "a consistent record says nothing at session start" "$out" ;;
  *)                   ok  "a consistent record says nothing at session start" ;;
esac

# An empty answer has two honest readings, and only one of them is agreement.
# quietproj holds a record that agrees with its manifest; emptyrec holds no
# record at all, and calling that agreement would be a verdict produced by
# reading nothing.
out="$(cd "$QREPO" && "$FELIX" stack reconcile 2>&1)"
has "a consistent record is called agreement" "$out" "the record and the manifest agree"
mkdir -p "$FROOT/projects/emptyrec"
cat > "$FROOT/projects/emptyrec/project.json" <<'EOF'
{"name": "emptyrec", "remote_match": "example.com/emptyrec", "gate": "true"}
EOF
printf '# emptyrec\n' > "$FROOT/projects/emptyrec/CLAUDE.md"
EREPO="$TMP/empty-repo"; mkdir -p "$EREPO"
( _fx_cd "$EREPO" && git init -q -b main )
printf 'emptyrec\n' > "$EREPO/.felix"
out="$(cd "$EREPO" && "$FELIX" stack reconcile 2>&1)"; rc=$?
is  "no record still answers cleanly" "$rc" "0"
has "and is not called agreement"     "$out" "No record yet"

# The named column is owner-anchored, driven through the real writers rather
# than hand-written rows. A play naming context7-docs used to count as naming
# context7 — substring, not identity — and enough such sessions read as
# "pointed at and ignored", the exact evidence retire and the reconciler act
# on. The control: an owner-reduced play entry must still name its plugin.
BLH="$TMP/bleedhome"; BLP="$TMP/bleedproj"; mkdir -p "$BLH" "$BLP" "$MEM/bleedproj"
{ printf 'mcp\tcontext7\t-\tmedium\talways\n'
  printf 'plugin\tsuperpowers@x\t-\tlow\talways\n'
} > "$BLP/stack.tsv"
( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/ledger.sh"
  felix_ledger_note_named "$BLH" s1 "context7-docs superpowers:brainstorming"
  felix_ledger_record "$BLH" s1 "mcp	context7-docs"
  felix_ledger_rollup "$BLP" "$BLH" s1 2026-08-30 )
row="$(cat "$MEM/bleedproj/ledger.d/s1.tsv" 2>/dev/null)"
case "$row" in
  *"	context7	0	0"*) ok  "a play naming a superstring does not name its prefix" ;;
  *)                     bad "a play naming a superstring does not name its prefix" "$row" ;;
esac
sum="$( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/ledger.sh"
        felix_ledger_summary "$BLP" )"
has "while an owner-reduced play entry still names its plugin" "$sum" "superpowers	1	0	1"

# And a built-in skill is not the plugin that shares its name.
#
# The host provides skills into the same identity space unqualified, while
# every plugin-provided item is recorded with its provider prefix. So a bare
# `skill` row is the host's, and folding it onto the declaration of the same
# name — which reduces to that same bare string — donates its reaches. On this
# machine that gave a plugin shipping no skill at all four reaches and six
# namings, and the donation is what kept it off every list: retire needs calls
# at zero, unrouted needs named at zero, and the borrowed numbers disqualified
# it from both. The capability with no evidence of its own was the only one
# nothing reported.
BIH="$TMP/builtinhome"; BIP="$TMP/builtinproj"; mkdir -p "$BIH" "$BIP" "$MEM/builtinproj"
printf 'plugin	code-review@x	-	low	always
' > "$BIP/stack.tsv"
( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/ledger.sh"
  felix_ledger_note_named "$BIH" b1 "code-review"
  felix_ledger_record "$BIH" b1 "skill	code-review"
  felix_ledger_record "$BIH" b1 "skill	superpowers:brainstorming"
  felix_ledger_rollup "$BIP" "$BIH" b1 2026-08-30 )
bsum="$( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/ledger.sh"
         felix_ledger_summary "$BIP" )"
has "a bare skill row is counted as the host's, not the plugin's" \
    "$bsum" "code-review (built-in)	1	1	"
is "so the declared plugin keeps none of its reaches" \
   "$(printf '%s\n' "$bsum" | awk -F'\t' '$1 == "code-review" { print $3 }')" "0"
# A prefixed skill still belongs to the plugin that ships it: the rule is
# "unqualified means the host", not "skills do not join".
is "while a provider-prefixed skill still joins to its plugin" \
   "$(printf '%s\n' "$bsum" | awk -F'\t' '$1 == "superpowers" { print $3 }')" "1"
case "$bsum" in
  *"superpowers (built-in)"*) bad "and a prefixed skill is never called a built-in" "$bsum" ;;
  *)                          ok  "and a prefixed skill is never called a built-in" ;;
esac
# The declared plugin still has a row, with none of the reaches.
#
# This is the second half, and without it the first half is worse than the
# defect: the rollup's zero-row loop skips a declared capability whose name it
# has already seen this session, so a bare skill reach used to suppress the
# plugin's row entirely — leaving it absent exactly in the sessions where the
# built-in ran, rather than present with nothing to its name.
is "the declared plugin still has its presence row" \
   "$(printf '%s\n' "$bsum" | awk -F'\t' '$1 == "code-review" { print $2 }')" "1"
# The play named a bare `code-review`, which nothing can disambiguate: the
# route wrote a name both providers answer to. It is counted for both rather
# than assigned to one, because assigning it would be a guess and the guess
# would decide a retire verdict. No verdict turns on the duplication — the
# built-in was reached, so calls disqualify it from retire whatever its
# namings say.
is "an ambiguous play naming is counted for the declared plugin" \
   "$(printf '%s\n' "$bsum" | awk -F'\t' '$1 == "code-review" { print $4 }')" "1"
is "and for the built-in too, because nothing can tell which was meant" \
   "$(printf '%s\n' "$bsum" | awk -F'\t' '$1 == "code-review (built-in)" { print $4 }')" "1"
# Which is the finding the donation had been suppressing.
has "so the plugin with no evidence of its own reaches the retire list" \
    "$( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/ledger.sh"
        FELIX_LEDGER_MIN=1 felix_ledger_retire "$BIP" )" "code-review	1	1"
r="$( HOME="$RCH"; . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/ledger.sh"
      . "$FROOT/harness/lib/stack.sh"; FELIX_LEDGER_MIN=1 felix_stack_reconcile "$BLP" )"
case "$r" in
  *"unmount	context7"*) bad "so no false unmount is proposed from it" "$r" ;;
  *)                     ok  "so no false unmount is proposed from it" ;;
esac
has "while the genuinely reached server is proposed" "$r" "mount	context7-docs"

# What discovery judged capability-less is not adopt material. `-` is
# inspection's own verdict — the copy on disk ships nothing serving any
# declared capability — and declaring under it would act on the claim
# inspection just refuted.
ADH2="$TMP/adopthome-dash"; ADP2="$TMP/adoptproj-dash"
mkdir -p "$ADH2/state/discover" "$ADP2"
printf '# kind\tname\tsource\trisk\tcapability\n' > "$ADP2/stack.tsv"
{ _dstamp; printf 'noname\t-\tlow\ngood\tllm\tlow\n'; } > "$ADH2/state/discover/adoptproj-dash.tsv"
out="$( . "$FROOT/harness/lib/discover.sh"; felix_discover_adopt "$ADP2" "$ADH2" )"
has "a capability match is still adopt material" "$out" "declare	good"
case "$out" in
  *noname*) bad "a row inspection judged capability-less is not" "$out" ;;
  *)        ok  "a row inspection judged capability-less is not" ;;
esac

printf '\nprocedures: enumerated from reality, never from a list Felix wrote\n'
# The rule this whole surface exists to obey, and the reason it exists.
#
# Told about an audit that found five things on a governed project, Felix got
# a command with checks for the two that were mechanizable and silently
# dropped the third — a missing request ceiling — because there was no table
# of what a deploy moment must answer. A list of checks cannot report the
# check nobody wrote.
#
# The fix is not a better list. `lifecycle.tsv` already works for hook events
# and it does not work by being well written: felix_coverage_events reads what
# the PLATFORM binds, the table holds only stances, and the gap is what
# reality has and the table does not. Felix never authors the enumeration.
#
# So here: items come from what the checkout HAS and what has actually BITTEN.
# Stances are judgement and belong to a person. An item with no stance is the
# product, not an error.
PRT="$TMP/procedures-tpl"; mkdir -p "$PRT"
printf '# moment\tdescription\npre-deploy\tbefore anything is served\nsession-start\twhat this session should reach for\n' \
  > "$PRT/moments.tsv"
PRP="$TMP/procedures-proj"; mkdir -p "$PRP" "$MEM/procedures-proj"
printf 'deploy\napi\n' > "$PRP/capabilities"
printf '2026-08-01\tmain\tabc\tsecret lint\n2026-08-02\tmain\tdef\tsecret\n' \
  > "$MEM/procedures-proj/mistakes.log"

_pitems() { ( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/detect.sh"
              . "$FROOT/harness/lib/procedures.sh"; felix_procedures_items "$PRP" ); }
has "a declared surface is an item"            "$(_pitems)" "capability:deploy"
has "and so is a second one"                   "$(_pitems)" "capability:api"
# The claim this file makes about itself is that items come from reality. The
# first version read the DECLARED file — a curated snapshot — so a surface the
# checkout grew after adoption produced no item, no gap, and a clean bill.
# felix_undeclared exists precisely to compare the tree against that file, and
# not using it made "enumerate from reality" false for half the enumerator.
mkdir -p "$PRP/repo/.github/workflows"
printf 'on: push\n' > "$PRP/repo/.github/workflows/ci.yml"
printf 'FROM python:3.12\n' > "$PRP/repo/Dockerfile"
_pitemsr() { ( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/detect.sh"
               . "$FROOT/harness/lib/procedures.sh"; felix_procedures_items "$PRP" "$PRP/repo" ); }
has "a surface detected in the tree is an item even if nobody declared it" \
    "$(_pitemsr)" "capability:ci"
has "and a declared one the tree no longer shows is still an item" \
    "$(_pitemsr)" "capability:api"
# What has bitten is the other half, and it is the half Felix cannot invent:
# it is whatever the gate actually caught, however many times.
has "a check that has actually failed is an item" "$(_pitems)" "failure:secret"
has "including one that failed alongside another" "$(_pitems)" "failure:lint"
is  "and each item appears once however often it bit" \
    "$(_pitems | grep -c '^failure:secret$')" "1"

# Day one: no stance file at all. Every item is a gap, and saying so is the
# whole point — this is the output that would have named the request ceiling.
_pgaps() { ( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/detect.sh"
             . "$FROOT/harness/lib/procedures.sh"; felix_procedures_gaps "$PRP" ); }
is "with no stances taken, every item is a gap" \
   "$(_pgaps | grep -c .)" "$(_pitems | grep -c .)"

# A stance closes exactly one gap and nothing else. It is authored, arguable,
# and recorded — which is what makes it different from an enumeration.
printf '# item\tmoment\tanswered by\tnote\ncapability:deploy\tpre-deploy\tfelix preflight\tlisteners and modes\n' \
  > "$PRP/procedures.tsv"
case "$(_pgaps)" in
  *capability:deploy*) bad "an item with a stance is no longer a gap" "$(_pgaps)" ;;
  *)                   ok  "an item with a stance is no longer a gap" ;;
esac
has "while the others still are" "$(_pgaps)" "capability:api"
has "and so does a failure nobody answered" "$(_pgaps)" "failure:secret"

# A stance naming a moment nobody declared is itself a gap — otherwise a typo
# silently answers nothing, which is the failure this file is named after.
printf 'capability:api\tpre-lunch\tsomething\t-\n' >> "$PRP/procedures.tsv"
_pbad() { ( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/detect.sh"
            . "$FROOT/harness/lib/procedures.sh"; felix_procedures_unknown_moments "$PRP" "$PRT" ); }
# The review's red, and it is the design's own defect reproduced inside the
# fix: a row whose first column names an item closed the gap whether or not
# it named a moment or an answerer — and then every display path skipped it,
# because they all key on the moment. The item vanished from the gap list, the
# stance list, and the unknown-moment list at once, and the report printed
# "every item has a stance". A row that records no judgement is not a stance.
printf 'failure:secret\n' >> "$PRP/procedures.tsv"
has "a row naming no moment does not close its gap" "$(_pgaps)" "failure:secret"
_pmal() { ( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/detect.sh"
            . "$FROOT/harness/lib/procedures.sh"; felix_procedures_malformed "$PRP" ); }
has "and the row itself is reported as recording nothing" "$(_pmal)" "failure:secret"
# The well-formed one is untouched by any of this.
case "$(_pmal)" in
  *capability:deploy*) bad "while a complete stance is not called malformed" "$(_pmal)" ;;
  *)                   ok  "while a complete stance is not called malformed" ;;
esac

# A stance for something nothing enumerates is a claim about a surface that is
# gone. lifecycle.tsv checks both directions; this checked one.
printf 'capability:ghost\tpre-deploy\tsomething\t-\n' >> "$PRP/procedures.tsv"
_porph() { ( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/detect.sh"
             . "$FROOT/harness/lib/procedures.sh"; felix_procedures_orphans "$PRP" ); }
has "a stance for something nothing enumerates is named" "$(_porph)" "capability:ghost"
case "$(_porph)" in
  *capability:deploy*) bad "and a stance for a real item is not" "$(_porph)" ;;
  *)                   ok  "and a stance for a real item is not" ;;
esac

# And an unreachable stance does not close a gap either, which is the same
# sentence applied consistently: it was reported as unknown AND still counted
# as an answer, so the report named the typo while the item quietly left the
# unanswered list.
_pgapst() { ( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/detect.sh"
              . "$FROOT/harness/lib/procedures.sh"; felix_procedures_gaps "$PRP" "" "$PRT" ); }
has "a stance at a moment nobody declared answers nothing" "$(_pgapst)" "capability:api"
case "$(_pgapst)" in
  *capability:deploy*) bad "while one at a declared moment still does" "$(_pgapst)" ;;
  *)                   ok  "while one at a declared moment still does" ;;
esac

has "a stance at a moment nobody declared is named" "$(_pbad)" "pre-lunch"
case "$(_pbad)" in
  *pre-deploy*) bad "and a declared moment is not" "$(_pbad)" ;;
  *)            ok  "and a declared moment is not" ;;
esac

# The command, not only the library. Every assertion above passed while the
# CLI died on an unbound variable, because nothing here ran it — which is the
# lesson this repository already carries about neutering the call site rather
# than the library, arriving again in the file written to stop a method
# failure.
out="$(cd "$REPO" && "$FELIX" procedures 2>&1)"; rc=$?
is  "felix procedures runs"            "$rc" "0"
has "and names the project"            "$out" "procedures for widget"
has "and reports what nothing answers" "$out" "nothing answers these"
out="$(cd "$REPO" && "$FELIX" procedures --wat 2>&1)"; rc=$?
is  "and an unknown flag is refused rather than ignored" "$rc" "1"


