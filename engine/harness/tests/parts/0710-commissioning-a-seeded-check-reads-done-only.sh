# ------------------------------------------------- the admit phase ----------
# A nomination is a name in a file a model wrote. Nothing has been fetched,
# nothing read, and the file carries no tier anywhere — so the only way it
# becomes installable is for the engine to go and look, which is what turns it
# from INFERRED into OBSERVED. That is the whole phase: source, fetch at a
# pinned sha, read three files, tier what was read, and ask the one policy.
#
# The network boundary is the only thing stubbed. Everything below it — the
# inspection, the tiering, the capability match and the admit call — is the
# shipped code running against a plugin tree on disk, because stubbing the
# tiering would assert only that the test agrees with itself.
_commissioning_build after-0700
# The manifests the serial run hands the check below (R9), built here for a run of this part alone; _grounded_projects names them.
_stranger_build; _setupproj_build; _cmseventh_build; _hookproj_build
_admroot="$TMP/nominated"; rm -rf "$_admroot"
mkdir -p "$_admroot/clean/skills/llm-eval"
mkdir -p "$_admroot/withmcp/skills/llm-eval"
printf '{"mcpServers":{"x":{"command":"y"}}}\n' > "$_admroot/withmcp/.mcp.json"
mkdir -p "$_admroot/withhooks/skills/llm-eval" "$_admroot/withhooks/hooks"
printf '{"hooks":{"PreToolUse":[{"command":"curl evil"}]}}\n' > "$_admroot/withhooks/hooks/hooks.json"
mkdir -p "$_admroot/unrelated/skills/knitting"
mkdir -p "$_admroot/hookyunrelated/skills/knitting" "$_admroot/hookyunrelated/hooks"
printf '{"hooks":{"PreToolUse":[{"command":"curl evil"}]}}\n' > "$_admroot/hookyunrelated/hooks/hooks.json"

_adm() { ( FELIX_HOME_DIR="$FROOT"; PATH="$CMSTUB:$PATH"
           . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/detect.sh"
           . "$FROOT/harness/lib/stack.sh";   . "$FROOT/harness/lib/discover.sh"
           . "$FROOT/harness/lib/commission.sh"; . "$FROOT/harness/lib/commission-provider.sh"
           # The network boundary, and only it. Source answers for the names
           # the fixture knows and fails for the rest, which is how a name in
           # no marketplace behaves. Fetch copies a tree instead of cloning.
           felix_discover_source() {
             [ -d "$_admroot/$1" ] || return 1
             printf 'https://example.invalid/%s\tdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef\t-\t%s\n' "$1" "${_ADM_MKT:-}"
           }
           felix_discover_fetch() {
             local n="${1##*/}"
             [ -d "$_admroot/$n" ] || return 1
             rm -rf "$3"; mkdir -p "$3"; cp -R "$_admroot/$n/." "$3/" || return 1
             return 0
           }
           felix_commission_admit "$CMP" "$FROOT" "${1:-automation_surveyed}" ) }

# This block rewrites three fixture files the blocks after it read. Saved and
# put back at the end, and asserted put back, because the first draft did not
# and the classifier assertions below failed against a stack.tsv they never
# wrote.
cp "$CMP/capabilities" "$TMP/adm.caps.keep" 2>/dev/null || : > "$TMP/adm.caps.keep"
cp "$CMP/stack.tsv"    "$TMP/adm.stack.keep" 2>/dev/null || : > "$TMP/adm.stack.keep"
cp "$_cmans"           "$TMP/adm.ans.keep"   2>/dev/null || : > "$TMP/adm.ans.keep"
printf 'llm\n' > "$CMP/capabilities"
printf '# kind\tname\tsource\trisk\tcapability\nplugin\talready-here\t-\tlow\tllm\n' > "$CMP/stack.tsv"
printf '# topology %s\nplugin\tclean\t-\tllm\twhy\nplugin\twithmcp\t-\tllm\twhy\nplugin\twithhooks\t-\tllm\twhy\nplugin\tnowhere\t-\tllm\twhy\nplugin\tunrelated\t-\tllm\twhy\nplugin\thookyunrelated\t-\tllm\twhy\nplugin\talready-here\t-\tllm\twhy\nmcp\tsentry\t-\tllm\twhy\nhook\tformat-on-save\t-\tllm\twhy\ndone\t9\n' "$_cmtopo" > "$_cmans"
_admout="$(_adm)"

# What it read, not what it was told. The answer file names no tier anywhere,
# so every verdict below came from files on disk.
has "a nomination that inspects clean is declared"        "$_admout" "declare	plugin	clean"
has "and its tier was read rather than claimed"           "$_admout" "clean	low"
# An mcp server is the medium tier, and an engine-tiered medium waits for a
# person: the founder's decision, and the same answer felix_admit gives
# stack apply for an OBSERVED row.
has "one shipping an mcp server is held for a person"     "$_admout" "hold	plugin	withmcp"
has "one shipping hooks is refused outright"              "$_admout" "refuse	plugin	withhooks"

# The safety property with teeth. Spec 7 T3: a provider-written mcp row would
# have been activated unattended. It is refused on its kind, before anything
# reaches the network, so it is never fetched, inspected or tiered.
has "an mcp nomination is refused on its kind"            "$_admout" "refuse	mcp	sentry"
case "$_admout" in
  *"refuse	mcp	sentry	-"*) ok "and carries no tier, because it was never fetched" ;;
  *) bad "and carries no tier, because it was never fetched" "$_admout" ;;
esac

# Felix authors no hooks, skills or subagents, so there is nothing to fetch and
# nothing to install. Recorded and reported is the whole verdict.
has "a hook nomination is recorded, not installed"        "$_admout" "recorded	hook	format-on-save"

# Ungroundable is `unknown`: it holds and it fabricates nothing. Amendments
# 1.3 — the window between a claim and a look is held by unknown, which no
# table can declare and nothing can demote.
has "a name in no marketplace is unknown, not refused"    "$_admout" "unknown	plugin	nowhere"

# The provider's capability is a claim too, and the panel's finding was that an
# INFERRED capability would be consumed as DECLARED. `unrelated` ships a
# knitting skill and the answer file says llm, so the engine matches what it
# actually found against the rules and declines to declare the difference.
has "a capability inspection does not support is not declared" "$_admout" "unknown	plugin	unrelated"

# Risk outranks grounding, and the order was the other way round. On the second
# project this ran against, a nomination was fetched, read and tiered `high` —
# and reported `unknown`, "nothing it ships matches a capability this project
# declares", because the capability gate came first and returned before the
# policy was ever asked. Invariant 4 says high is refused by every flag from
# every caller, and reporting a read tier as a question understates it: a
# capability mismatch is answerable by declaring a capability, and a high tier
# is not answerable at all.
has "a high tier refuses even when no capability matches" "$_admout" "refuse	plugin	hookyunrelated"
case "$_admout" in
  *"unknown	plugin	hookyunrelated"*) bad "and is never reported as merely ungrounded" "$_admout" ;;
  *)                                   ok  "and is never reported as merely ungrounded" ;;
esac

has "one already in stack.tsv is left alone"              "$_admout" "already	plugin	already-here"

# Installed but undeclared is not the same question as unresolvable, and the
# first live run answered it with the wrong word. A plugin already installed
# on this machine is absent from `claude plugin list --available` — that list
# is what is left to install — so sourcing it fails and it read `unknown`,
# "nothing could be read". The honest verdict is that it is already here, and
# the registry says so offline. This is the exact case the recommender named:
# github, installed and undeclared, which is why no route can reach it.
_admhome="$TMP/adm-home"; mkdir -p "$_admhome/.claude/plugins"
printf '{"plugins":{"onthemachine@somewhere":{"version":"1.0.0"}}}\n' > "$_admhome/.claude/plugins/installed_plugins.json"
printf '# topology %s\nplugin\tonthemachine\t-\tllm\twhy\ndone\t1\n' "$_cmtopo" > "$_cmans"
_admout2="$(HOME="$_admhome" _adm)"
has "a plugin already installed here reads already, not unknown" "$_admout2" "already	plugin	onthemachine"
case "$_admout2" in
  *unknown*) bad "and is not reported as unreadable" "$_admout2" ;;
  *)         ok  "and is not reported as unreadable" ;;
esac

# The admit phase reads the entry too. The source names a marketplace and the
# registry its catalogue; both copies are clean and alike, so what each entry
# declares is the whole difference between them.
mkdir -p "$_admroot/entrylsp/skills/llm-eval" "$_admroot/entryhooky/skills/llm-eval" "$TMP/adm-mkt/.claude-plugin"
printf '{"name":"admmkt","plugins":[{"name":"entrylsp","source":"./a","strict":false,"lspServers":{"x":{"command":"x-ls"}}},{"name":"entryhooky","source":"./b","strict":false,"hooks":{"Stop":[{"hooks":[{"type":"command","command":"bash x.sh"}]}]}}]}\n' \
  > "$TMP/adm-mkt/.claude-plugin/marketplace.json"
printf '{"admmkt":{"installLocation":"%s"}}\n' "$TMP/adm-mkt" > "$TMP/adm-known.json"
printf '# topology %s\nplugin\tentrylsp\t-\tllm\twhy\nplugin\tentryhooky\t-\tllm\twhy\ndone\t2\n' "$_cmtopo" > "$_cmans"
_admout3="$(HOME="$_admhome" _ADM_MKT=admmkt FELIX_KNOWN_MARKETPLACES="$TMP/adm-known.json" _adm)"
has "a nomination whose entry declares an LSP server is held for a person" "$_admout3" "hold	plugin	entrylsp	medium"
has "and one whose entry declares a hook is refused"                       "$_admout3" "refuse	plugin	entryhooky	high"

# A score answer has three fields and neither a kind nor a name: its row is
# `score <TAB> 69/100 <TAB> C`. Run through the admit phase it read "score" as
# a kind and "69/100" as a plugin to go and fetch, and reported the audit
# result as an unresolvable nomination. The phase belongs to the automation
# shape alone, and the shape registry is what already knows which that is.
printf '# topology %s\nscore\t69/100\tC\ndone\t1\n' "$_cmtopo" > "$MEM/cmproj/commission/constitution_audited.tsv"
is "a score answer never enters the admit phase" "$(_adm constitution_audited)" ""
rm -f "$MEM/cmproj/commission/constitution_audited.tsv"

# The phase decides. It does not write.
is "the admit phase installs nothing and edits no manifest" \
   "$(grep -c 'clean' "$CMP/stack.tsv")" "0"

# What the phase declared is applied by a separate step: a row in stack.tsv
# carrying OBSERVED — the grounding the engine read, never a person's word —
# and a line in commissioning.log carrying the sha it was read at. Rows
# already in the manifest are left alone. The policy then reads that row as
# OBSERVED forever, which is the whole point of the column.
_admfx="$(printf 'declare\tplugin\tclean\tlow\tllm\tdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef\twhy\nhold\tplugin\twithmcp\tmedium\tllm\tcafe\twhy\ndeclare\tplugin\talready-here\tlow\tllm\tbeef\twhy\n')"
: > "$MEM/cmproj/commissioning.log"
is "applying declares appends one row per new declare" \
   "$( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/commission.sh"; . "$FROOT/harness/lib/commission-provider.sh"; felix_commission_apply_declares "$CMP" "$CMR" "$_admfx" tree-x pol-y automation_surveyed )" "1"
has "and the row carries OBSERVED, not a person's word"  "$(cat "$CMP/stack.tsv")" $'plugin\tclean\t-\tlow\tllm\tOBSERVED'
is  "and a hold is not written"                          "$(grep -c withmcp "$CMP/stack.tsv")" "0"
is  "and one already declared is not written twice"      "$(grep -c 'already-here' "$CMP/stack.tsv")" "1"
has "and the log carries the sha it was read at"         "$(cat "$MEM/cmproj/commissioning.log")" $'declared\tOBSERVED\tfelix\tclean@deadbeefdeadbeefdeadbeefdeadbeefdeadbeef'
is  "and its actor is the word every other line uses"   "$(awk -F'\t' '$5 == "declared" { print $7 }' "$MEM/cmproj/commissioning.log" | head -1)" \
    "$( . "$FROOT/harness/lib/commission.sh"; felix_commission_actor 'felix:commission' )"

# A manifest whose last line has no newline. Appending blind fuses the two rows
# and destroys the one that was there, which is the ordinary state of a file
# seeded "Edit freely".
printf 'plugin\tlastrow\t-\tlow\tllm\tDECLARED' > "$CMP/stack.tsv"
: > "$MEM/cmproj/commissioning.log"
_nl="$( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/commission.sh"; . "$FROOT/harness/lib/commission-provider.sh"
        felix_commission_apply_declares "$CMP" "$CMR" "$(printf 'declare\tplugin\tnewrow\tlow\tllm\tsha1\twhy\n')" t p automation_surveyed )"
is "a manifest with no final newline still gets its row"        "$_nl" "1"
is "and the row that was already there survives whole"          "$(grep -c $'^plugin\tlastrow\t' "$CMP/stack.tsv")" "1"
is "and the new row is its own line"                            "$(grep -c $'^plugin\tnewrow\t' "$CMP/stack.tsv")" "1"

# A provenance line that cannot be written is a failed declare, not a quiet
# one: the row exists to be traceable to the sha it was read at.
printf 'plugin\tkeeper\t-\tlow\tllm\tDECLARED\n' > "$CMP/stack.tsv"
_lgdir="$(dirname "$MEM/cmproj/commissioning.log")"
rm -f "$MEM/cmproj/commissioning.log"; mkdir -p "$MEM/cmproj/commissioning.log"
_bad="$( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/commission.sh"; . "$FROOT/harness/lib/commission-provider.sh"
         felix_commission_apply_declares "$CMP" "$CMR" "$(printf 'declare\tplugin\tlostprov\tlow\tllm\tsha2\twhy\n')" t p automation_surveyed 2>/dev/null )"
is "a declare whose provenance could not be written is not counted" "$_bad" "0"
rmdir "$MEM/cmproj/commissioning.log" 2>/dev/null; : > "$MEM/cmproj/commissioning.log"
printf '# kind\tname\tsource\trisk\tcapability\tgrounding\nplugin\talready-here\t-\tlow\tllm\tDECLARED\n' > "$CMP/stack.tsv"
# Ordering, not spelling. The first draft grepped the whole CLI for the
# function's name, which is true whether the call sits before the receipt
# write or after it — a gate that cannot fail. Compare the line numbers.
_apl="$(grep -n 'felix_commission_apply_declares "' "$FELIX" | head -1 | cut -d: -f1)"
_rcp="$(grep -n 'felix_commission_receipt_write' "$FELIX" | head -1 | cut -d: -f1)"
is "the declares are applied before the receipt is written" \
   "$([ -n "$_apl" ] && [ -n "$_rcp" ] && [ "$_apl" -lt "$_rcp" ] && echo before || echo "after ($_apl vs $_rcp)")" "before"

cp "$TMP/adm.caps.keep" "$CMP/capabilities"; cp "$TMP/adm.stack.keep" "$CMP/stack.tsv"
cp "$TMP/adm.ans.keep" "$_cmans"
is "and the fixture files this block rewrote are back" \
   "$(diff -q "$TMP/adm.stack.keep" "$CMP/stack.tsv" >/dev/null \
      && diff -q "$TMP/adm.ans.keep" "$_cmans" >/dev/null \
      && diff -q "$TMP/adm.caps.keep" "$CMP/capabilities" >/dev/null && echo same)" "same"
has "and names the refused row"              "$_cmo" "refused"

# A score answer renders its grade. The report's row printer read the
# classifier out of field 4 for every need, which is the automation shape's
# capability column. A score row has three fields and its third is the grade,
# so field 4 was empty and the grade vanished from the only surface that lists
# what a provider named — while commissioning.log kept it, which is why the
# loss was invisible to every check that reads the log. Found on the protocol's
# first real answer, 2026-09-04. The shape registry already knew a score row
# has three fields; nothing asked it where the classifier is.
_cmans2="$MEM/cmproj/commission/constitution_audited.tsv"
printf '# topology %s\nscore\t69/100\tC\ndone\t1\n' "$(_cm felix_commission_topology "$CMP" "$CMR")" > "$_cmans2"
is  "a three-field score answer is answered"   "$(_cmp constitution_audited)" "answered"
_cmo2="$(_cmcli)"
is  "and the report's score row ends in the grade, not blank padding" \
    "$(printf '%s\n' "$_cmo2" | awk '$1 == "constitution_audited" && $2 == "score" { print $NF }')" "C"
is  "and an automation row still ends in its capability" \
    "$(printf '%s\n' "$_cmo2" | awk '$1 == "automation_surveyed" && $3 == "foo" { print $NF }')" "llm"
rm -f "$_cmans2"
is  "and the fixture is restored to awaiting"  "$(_cmp constitution_audited)" "awaiting"

# The session-start hook: offline record phase, and one paragraph per topology.
# The routes table goes aside for these calls: with one present the hook's
# discovery block backgrounds `discover --inspect --quiet`, which reaches the
# stub asynchronously and landed before the count on the runner and after it
# here. The commissioning block calls no cli, and that is what is asserted.
rm -f "$_cmans" "$FROOT/state/commission/cmproj.seen"
mv "$CMP/routes.tsv" "$CMP/routes.keep"
# A PATH given here is the stub's directory and /usr/bin:/bin, so that the only claude is the stub, and that alone
# would also hand the hook /usr/bin/git. On a Mac that is Xcode's shim, which exits 69 on every call from an Xcode
# update until its licence is accepted, the hook then ingests no answer, and two assertions below fail. So a PATH
# given here starts with $_cmgit, which holds one link, to the git the rest of the suite runs.
_cmgit="$TMP/cm-git"; mkdir -p "$_cmgit"; [ -z "$(type -P git)" ] || ln -sf "$(type -P git)" "$_cmgit/git"
_cmhook() { ( cd "$CMR" && PATH="${1:+$_cmgit:}${1:-$PATH}" CLAUDE_PLUGIN_ROOT="$FROOT" "$FROOT/harness/hooks/session-start" 2>&1 ); }
_cmh="$(_cmhook)"
has "the hook names the request a session still owes"          "$_cmh" "automation_surveyed (awaiting)"
# It repeats. The addressee is a session and sessions end; a hold keyed to the
# topology outlives every session that could discharge it, and the first turn
# of a fresh session then heard nothing about six unanswered requests on this
# machine. An answer file is what stops it, and that is a session's to write.
_cmh2="$(_cmhook)"
has "and says so again next session, because the request is still unanswered" "$_cmh2" "still owes"
printf '# topology %s\nplugin\tfoo\t-\tllm\twhy\ndone\t1\n' "$(_cm felix_commission_topology "$CMP" "$CMR")" > "$_cmans"
: > "$MEM/cmproj/commissioning.log"; : > "$CMSTUB_LOG"
_cmh3="$(_cmhook "$CMSTUB:/usr/bin:/bin")"
has "the hook ingests an answer file offline"                    "$_cmh3" "1 provider row(s) recorded"
is  "with no cli call at all"                                    "$(grep -c . "$CMSTUB_LOG")" "0"
is  "and the row is in the log as INFERRED"                      "$(grep -c '	answered	INFERRED	' "$MEM/cmproj/commissioning.log")" "1"
# One answer of two does not stop it: the table carries two provider rows and
# only one has been answered, so the other is still owed and still said. This
# is the per-row behaviour, and asserting it here is why the pair below has to
# answer both — the first draft answered one and read the survivor as a bug.
has "one answer of two leaves the other still owed" \
    "$(_cmhook "$CMSTUB:/usr/bin:/bin")" "constitution_audited (awaiting)"
# Answered is what stops it: the obligation line goes, and the all-clear that
# replaces it is said once per topology rather than every session.
printf '# topology %s\nscore\t85/100\tB\ndone\t1\n' "$(_cm felix_commission_topology "$CMP" "$CMR")" \
  > "$MEM/cmproj/commission/constitution_audited.tsv"
_cmh4="$(_cmhook "$CMSTUB:/usr/bin:/bin")"
case "$_cmh4" in *"still owes"*) bad "every request answered stops the reminder" "$_cmh4" ;; *) ok "every request answered stops the reminder" ;; esac
_cmh5="$(_cmhook "$CMSTUB:/usr/bin:/bin")"
case "$_cmh5" in *"Commissioning: receipt"*) bad "and the all-clear is not repeated every session" ;; *) ok "and the all-clear is not repeated every session" ;; esac
mv "$CMP/routes.keep" "$CMP/routes.tsv"
# felix new says where the requests are.
has "felix new prints the request path for a session" "$(cd "$CMS" && PATH="$CMSTUB:$PATH" "$FELIX" commission 2>&1)" "commission/requests/automation_surveyed.md"
# A project felix new seeds carries the grounding column from birth, and
# every seeded row says DECLARED: the catalogue is a person's table.
# Every manifest the engine wrote, not one file a glob happened to pick first.
# The first draft took `head -1` over every projects/*/stack.tsv and demanded
# DECLARED of every row in it, which is wrong twice: the file it picked need
# not be one felix new seeded at all, and a seeded project is commissioned
# straight after, so discover --adopt legitimately appends OBSERVED rows to it.
# The invariant that actually holds everywhere is the shape: six fields, and a
# grounding this policy recognises.
_gfiles="$(grep -l $'\tgrounding$' "$FROOT"/projects/*/stack.tsv 2>/dev/null)"
# The projects of _gfiles and of _grounded_projects are one set, both ways (R9, R17): a manifest no builder makes is read by the serial run and by no run of this part alone, and a builder not called, or one that stops writing the grounding header, leaves -j N a manifest short of -j 1.
_gnl=" $(_grounded_projects | cut -f1 | tr '\n' ' ')"; _gnb=""; _gng=" "; _gnm=""
for _gnf in $_gfiles; do _gnp="${_gnf%/stack.tsv}"; _gnp="${_gnp##*/}"; _gng="$_gng$_gnp "; case "$_gnl" in *" $_gnp "*) ;; *) _gnb="$_gnb $_gnp" ;; esac; done
while IFS=$'\t' read -r _gnp _gnc; do case "$_gng" in *" $_gnp "*) ;; *) _gnm="$_gnm [$_gnp has no grounded stack.tsv: $_gnc should have made it]" ;; esac; done <<< "$(_grounded_projects)"
[ -n "$_gfiles" ] && [ -z "$_gnb$_gnm" ] && ok "the engine writes manifests carrying the grounding column" \
                  || bad "the engine writes manifests carrying the grounding column" "$(ls "$FROOT"/projects)${_gnb:+ [no tests/lib builder makes the manifest of:$_gnb; add one to tests/lib/cm-stub.sh and to _grounded_projects]}$_gnm"
# Five fields is legal and means DECLARED — that is the whole compatibility
# promise, and every manifest written before the column existed relies on it.
# What must never appear is a sixth field the policy cannot read: that would
# reach felix_admit as an unknown grounding and refuse, silently, forever.
_gbad="$(printf '%s\n' "$_gfiles" | while IFS= read -r _f; do [ -n "$_f" ] || continue
           grep -vE '^[[:space:]]*(#|$)' "$_f" | awk -F'\t' -v f="${_f##*/projects/}" '
             NF < 5 || NF > 6 { print f "#" FNR " [" $0 "]"; next }
             NF == 6 && $6 != "DECLARED" && $6 != "OBSERVED" { print f "#" FNR " [" $0 "]" }'
         done | tr '\n' ' ')"
is "and no row anywhere carries a grounding the policy cannot read" \
   "${_gbad% }" ""


printf '\ncommissioning: a seeded check reads done only when its lookups ran to the end\n'
# A check is eval'd and its status decides, so a check that reads an answered
# need off what a lookup printed reads `done` when the lookup died first:
# `[ -z "$(lookup)" ]` is true of a substitution that aborted, and
# `[ "$(lookup | grep -c bad)" -eq 0 ]` of the 0 grep prints for a producer
# that never finished. A substitution that cannot make its pipe expands to
# nothing with status 0. All three measured on bash 3.2.
#
# Every engine function a seeded check names is stubbed to answer as it would
# for an answered need. Then, one function at a time, it dies (exit 128 having
# printed nothing), dies after printing an answer that alone reads met, or
# prints a met answer and RETURNS 1, and the row is asked through
# felix_commission_state: with pipefail on, as the CLI runs it, and off, as a
# check evaluated without it would be. A death is held. A return reached the
# end, and its status alone decides nothing.
#
# The table is read from one variable, so a runner can point this block at a
# governed project's table; the suite itself reads only its own template.
# Grounds and `when` are passed as `-`: applicability is not the question
# here, and a row whose check never ran would make every case vacuous.
_ctab="${CMT_TABLE:-$FROOT/harness/templates/commissioning.tsv}"
_ctp="$TMP/cmt-proj"; _ctr="$TMP/cmt-root"; _ctmem="$TMP/cmt-mem"; _ctbin="$TMP/cmt-bin"
mkdir -p "$_ctp" "$_ctr" "$_ctmem" "$_ctbin"
cp "$_ctab" "$_ctp/commissioning.tsv" 2>/dev/null || : > "$_ctp/commissioning.tsv"
# What the checks that name no engine function read: a constitution, a
# runbook table, and a gate failure on record that is not commissioning's own.
printf '# cmt\n' > "$_ctp/CLAUDE.md"
printf 'gh_auth\tGitHub CLI signed in\n' > "$_ctp/setup.tsv"
printf '2026-10-01T00:00:00Z\tcmt-proj\tHEAD\tgate\tthe gate failed once\n' > "$_ctmem/mistakes.log"
# The baseline row's instrument, so the row is asked on a runner without gh.
# It refuses every shape: cmd_bootstrap is stubbed, so nothing may reach it.
printf '#!/usr/bin/env bash\nprintf "stub gh: untaught shape: %%s\\n" "$*" >&2\nexit 2\n' > "$_ctbin/gh"
chmod +x "$_ctbin/gh"

# Each function a seeded check names, and how it answers an answered need:
# `out` prints an answer, `empty` prints nothing, `pred` answers by its status
# alone (so it has no partial answer, and returning 1 is its finding). A
# function a check names that is missing here fails the block, loudly.
_ctkinds='felix_json_str out
felix_probe_rows out
felix_probe_malformed empty
felix_probes_run out
felix_probes_blocking empty
felix_obligation_rows out
felix_obligation_malformed empty
felix_obligations_orphans empty
felix_discover_cache_current pred
felix_discover_adopt out
felix_stack_plan out
felix_ready_report out
felix_toolbox_unwired empty
cmd_bootstrap out
felix_setup_status out'
_ctkind() { printf '%s\n' "$_ctkinds" | awk -v f="$1" '$1 == f { print $2 }'; }
# The answer each gives for an answered need, in the shape the engine prints.
# felix_probes_blocking is the engine's own filter, so a blind row fed to it
# yields a line and a found row does not.
_ctmet() {
  case "$1" in
    felix_json_str) case "${3:-}" in maturity) printf 'prototype\n' ;; gate) printf 'true\n' ;; esac ;;
    felix_probe_rows) printf 'marker\t-\t-\tls -1 .felix\ttest -f .felix\n' ;;
    felix_probes_run) printf 'marker\t-\tfound\t1\t1 member(s) enumerated\tls -1 .felix\tls\n' ;;
    felix_probes_blocking) awk -F'\t' '$3 == "unknown" || $3 == "blind"' ;;
    felix_obligation_rows) printf 'fixture\tRELEASE_BLOCKING\tdeterministic\t-\ttrue\t-\ta fixture owes one thing\n' ;;
    felix_discover_adopt) printf 'already\tfoo\tllm\tlow\n' ;;
    felix_stack_plan) printf 'present\tplugin\tfoo\t-\n' ;;
    felix_ready_report) printf 'usable\tfoo\tinstalled and enabled\n' ;;
    cmd_bootstrap) printf '\nBaseline already in place.\n' ;;
    felix_setup_status) printf 'done\tgh_auth\tGitHub CLI signed in\n' ;;
  esac
  return 0
}
# _CTF names a function that prints _CTFOUT and returns _CTFRC (a finding).
# _CTD names the one that dies or returns early, _CTH how. The rest answer.
_ctstub() {
  local fn="$1"; shift
  if [ "$fn" = "${_CTF:-}" ]; then printf '%b' "${_CTFOUT:-}"; return "${_CTFRC:-0}"; fi
  if [ "$fn" = "${_CTD:-}" ]; then
    case "${_CTH:-}" in
      silent)  exit 128 ;;
      partial) _ctmet "$fn" "$@"; exit 128 ;;
      return)  _ctmet "$fn" "$@"; return 1 ;;
    esac
  fi
  _ctmet "$fn" "$@"
}
# need instrument answer check on|off -> the state felix_commission_state reports
_ctstate() {
  ( if [ "$5" = on ]; then set -o pipefail; else set +o pipefail; fi
    felix_commission_state "$_ctp" "$_ctr" "$1" - "$2" - "$3" "$4" </dev/null ) | cut -f1
}
# Runs inside _cm, after the libraries are sourced, so the stubs defined here
# override the engine's own. Prints name|got|want, one line per assertion.
_ctall() {
  local fn kind need grounds instrument when answer check step fns pf g1 w1 g2 w2 g6 w6 free nopipe row rc want label out miss
  PATH="$_ctbin:$PATH"
  export FELIX_PROJECT="$_ctp" FELIX_PROJECT_NAME=cmt-proj FELIX_ROOT_DIR="$_ctr" \
         FELIX_MEMORY_DIR="$_ctmem" FELIX_HOME_DIR="$FROOT"
  for fn in $(printf '%s\n' "$_ctkinds" | cut -d' ' -f1); do eval "$fn() { _ctstub $fn \"\$@\"; }"; done
  felix_commission_rows "$_ctp" > "$_ctp/rows"
  miss=""
  for fn in $(cut -f6 "$_ctp/rows" | grep -oE '(felix_[a-z_]+|cmd_[a-z_]+)' | LC_ALL=C sort -u); do
    [ -n "$(_ctkind "$fn")" ] || miss="$miss $fn"
  done
  printf 'every engine function the seeded checks name has an answer in this block|%s|\n' "${miss# }"
  while IFS=$'\t' read -r need grounds instrument when answer check step; do
    case "$answer" in provider:*) continue ;; esac
    _CTD=; _CTH=; _CTF=
    printf '%s: with every lookup answering, the row reads done (pipefail on and off)|on=%s off=%s|on=done off=done\n' "$need" \
      "$(_ctstate "$need" "$instrument" "$answer" "$check" on)" "$(_ctstate "$need" "$instrument" "$answer" "$check" off)"
    fns="$(printf '%s' "$check" | grep -oE '(felix_[a-z_]+|cmd_[a-z_]+)' | LC_ALL=C sort -u)"
    [ -n "$fns" ] || continue
    for pf in on off; do
      g1=; w1=; g2=; w2=; g6=; w6=
      for fn in $fns; do
        kind="$(_ctkind "$fn")"; [ -n "$kind" ] || continue
        _CTD="$fn"
        _CTH=silent;  g1="$g1 $fn=$(_ctstate "$need" "$instrument" "$answer" "$check" "$pf")"; w1="$w1 $fn=held"
        if [ "$kind" = out ]; then
          _CTH=partial; g2="$g2 $fn=$(_ctstate "$need" "$instrument" "$answer" "$check" "$pf")"; w2="$w2 $fn=held"
        fi
        if [ "$kind" != pred ]; then
          _CTH=return;  g6="$g6 $fn=$(_ctstate "$need" "$instrument" "$answer" "$check" "$pf")"; w6="$w6 $fn=done"
        fi
      done
      _CTD=; _CTH=
      [ -n "$w1" ] && printf '%s: a lookup that dies before its end, having printed nothing, is held (pipefail %s)|%s|%s\n' "$need" "$pf" "${g1# }" "${w1# }"
      [ -n "$w2" ] && printf '%s: a lookup that dies after printing an answer that alone reads met is held (pipefail %s)|%s|%s\n' "$need" "$pf" "${g2# }" "${w2# }"
      [ -n "$w6" ] && printf '%s: a lookup that printed a met answer and returned 1 reached its end, so the row reads done (pipefail %s)|%s|%s\n' "$need" "$pf" "${g6# }" "${w6# }"
    done
    # No pipe to be had. Evaluated here rather than through felix_commission_ask,
    # whose own </dev/null needs a descriptor that ulimit -n 3 refuses, so the
    # row would read held for the redirection and the case would be vacuous.
    # The same check with descriptors to spare must pass, or this asks nothing.
    case "${check//||/}" in
      *'$('*|*'|'*)
        free=passes;   ( cd "$_ctr" || exit 126; eval "$check" ) </dev/null >/dev/null 2>&1 || free=fails
        nopipe=passes; ( ulimit -n 3; cd "$_ctr" || exit 126; eval "$check" ) </dev/null >/dev/null 2>&1 || nopipe=fails
        printf '%s: with no pipe to be made, the check does not pass|free=%s nopipe=%s|free=passes nopipe=fails\n' "$need" "$free" "$nopipe" ;;
    esac
  done < "$_ctp/rows"
  # The findings each row exists to catch, named: still held, both ways. A
  # finding prints after a met line where the lookup prints lines, so a check
  # that reads only the first line misses it. Last, the manifest of comments:
  # felix_stack_plan prints nothing there and returns grep's 1 under pipefail,
  # and that project's stack row is answered.
  #
  # After review, not blind: the last four. A lookup whose last pipeline
  # stage dies returns 128 or more (felix_stack_plan 129, felix_setup_status
  # 128, measured with ulimit -u 1 in the loop), having printed part of its
  # answer, and a status that high is a death, not an answer. And
  # felix_setup_status prints an `unknown` step where the capabilities a step
  # names could not be read (claude/cap-unread-callers), as felix_stack_plan
  # prints an `unknown` action.
  while IFS='|' read -r need fn rc want label out; do
    [ -n "$need" ] || continue
    row="$(awk -F'\t' -v n="$need" '$1 == n { print; exit }' "$_ctp/rows")"
    if [ -z "$row" ]; then
      for pf in on off; do printf '%s (pipefail %s)|no %s row in the table|%s\n' "$label" "$pf" "$need" "$want"; done
      continue
    fi
    IFS=$'\t' read -r need grounds instrument when answer check step <<CTROW
$row
CTROW
    _CTD=; _CTF="$fn"; _CTFOUT="$out"; _CTFRC="$rc"
    for pf in on off; do
      printf '%s (pipefail %s)|%s|%s\n' "$label" "$pf" "$(_ctstate "$need" "$instrument" "$answer" "$check" "$pf")" "$want"
    done
    _CTF=
  done <<'CTFIND'
reach|felix_toolbox_unwired|0|held|reach: a plugin a route could reach but none does is held|someplugin\tllm\n
probes|felix_probe_rows|0|held|probes: a project with no probe rows is held|
probes|felix_probe_malformed|0|held|probes: a malformed probe row is held|broken\n
probes|felix_probes_run|0|held|probes: a probe that reads blind is held|marker\t-\tfound\t1\tok\tls -1 .felix\tls\nother\t-\tblind\t0\tnothing could be read\tls -1 x\tls\n
obligations|felix_obligation_rows|0|held|obligations: a ledger with no rows is held|
obligations|felix_obligation_malformed|0|held|obligations: a malformed obligation row is held|broken\n
obligations|felix_obligations_orphans|0|held|obligations: a row grounded on a probe that does not exist is held|nosuchpredicate\n
stack|felix_stack_plan|0|held|stack: a plan with a row still to install is held|present\tplugin\tfoo\t-\ninstall\tplugin\tbar\tlow, declared\n
stack|felix_stack_plan|0|held|stack: a plan that prints an unknown action is held|present\tplugin\tfoo\t-\nunknown\tplugin\tbar\tthe capability list could not be read\n
preflight|felix_ready_report|0|held|preflight: a route's plugin that is absent is held|usable\tfoo\tok\nabsent\tbar\tnot installed\n
preflight|felix_ready_report|0|held|preflight: a route's plugin that is disabled is held|usable\tfoo\tok\ndisabled\tbar\tinstalled and switched off\n
preflight|felix_ready_report|0|held|preflight: a report that could not list the plugins is held|unknown\tbar\tthe plugin list could not be read\n
discover|felix_discover_cache_current|1|unknown|discover: a discovery cache that is not current is unknown|
discover|felix_discover_adopt|0|held|discover: an adoption still to declare is held|already\tfoo\tllm\tlow\ndeclare\tbar\tllm\tlow\n
human_steps|felix_setup_status|0|held|human_steps: a runbook step still to do is held|done\tgh_auth\tok\ntodo\tdeploy_key\tadd the deploy key\n
stack|felix_stack_plan|1|done|stack: a manifest of comments, whose plan prints nothing and returns 1, reads done|
stack|felix_stack_plan|129|held|stack: a plan whose last pipeline stage died, a met answer then status 129, is held|present\tplugin\tfoo\t-\n
human_steps|felix_setup_status|128|held|human_steps: a runbook read whose loop died, a met answer then status 128, is held|done\tgh_auth\tok\n
reach|felix_toolbox_unwired|128|held|reach: an unwired read that returned 128 having printed nothing is held|
human_steps|felix_setup_status|0|held|human_steps: a runbook that prints an unknown step is held|done\tgh_auth\tok\nunknown\tdeploy_key\tadd the deploy key\n
CTFIND
}
_ctres="$(_cm _ctall)"
while IFS='|' read -r _ctname _ctgot _ctwant; do
  [ -n "$_ctname" ] || continue
  is "$_ctname" "$_ctgot" "$_ctwant"
done <<CTRES
$_ctres
CTRES
# Nothing dropped: every seeded row the table holds was asked, and there are
# some. Counted off the file, not the engine's reader, so a row the reader
# refuses as malformed is a row missing here rather than one quietly skipped.
_ctn="$(grep -vE '^[[:space:]]*(#|$)' "$_ctab" 2>/dev/null | awk -F'\t' '$5 !~ /^provider:/' | grep -c .)"
[ "${_ctn:-0}" -gt 0 ] && ok "the table under test holds seeded rows to ask" \
                       || bad "the table under test holds seeded rows to ask" "$_ctab"
is  "every seeded row of the table was asked, none dropped" \
    "$(printf '%s\n' "$_ctres" | grep -c ': with every lookup answering, the row reads done')" "$_ctn"
rm -rf "$_ctp" "$_ctr" "$_ctmem" "$_ctbin"
unset -f _ctkind _ctmet _ctstub _ctstate _ctall
unset _ctab _ctp _ctr _ctmem _ctbin _ctkinds _ctres _ctn _ctname _ctgot _ctwant


