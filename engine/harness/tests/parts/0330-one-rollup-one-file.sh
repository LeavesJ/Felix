printf '\none rollup, one file\n'
# Issue #32, reproduced twice by a 15-agent concurrency audit and once more by
# an independent refuter running the registered SessionEnd hook verbatim. The
# rollup was an unlocked read-modify-write of one shared file: it read what
# every other session had committed, spent ~0.17s on per-row work, then renamed
# its own snapshot over the top. Anything committed in between was not merely
# missed, it was deleted, and the file could shrink. Twelve worktrees ending at
# once left 1 of 12; the same twelve run one at a time left 12 of 12.
#
# The input was already per-session, so the fix is to stop sharing the output
# rather than to make sharing safe. A lock was the other candidate and is worse
# for this data: it keeps one writer for rows that have exactly one owner, and a
# lock that is dropped rather than retried loses the same measurement.
LC="$TMP/ledgerconc"; LCP="$LC/projects/widgetconc"
mkdir -p "$LCP" "$MEM/widgetconc"
printf 'plugin\tsuperpowers@x\t-\tlow\talways\n' > "$LCP/stack.tsv"
_ledsnap() { ( cd "$1" 2>/dev/null && find . -type f -exec cksum {} \; | LC_ALL=C sort ); }

# Deterministic, and it is the exact property the race exploits: at the moment
# a rollup runs, every byte already in the memory directory belongs to some
# other session.
( . "$FROOT/harness/lib/ledger.sh"
  felix_ledger_record "$LC" first "tool	Bash"
  felix_ledger_rollup "$LCP" "$LC" first 2026-08-14 )
ledb="$(_ledsnap "$MEM/widgetconc")"
( . "$FROOT/harness/lib/ledger.sh"
  felix_ledger_record "$LC" second "tool	Read"
  felix_ledger_rollup "$LCP" "$LC" second 2026-08-14 )
leda="$(_ledsnap "$MEM/widgetconc")"
ledgone=""
while IFS= read -r _line; do
  [ -n "$_line" ] || continue
  grep -qxF "$_line" <<<"$leda" || ledgone="$ledgone $_line"
done <<EOF
$ledb
EOF
is "a rollup rewrites no file another session wrote" "$ledgone" ""

# The audit's own reproduction, at the scale that lost 11 of 12. Under the fix
# there is no shared file left to lose, so this is deterministic rather than
# probabilistic — the count is the one the retire threshold reads.
_i=1
while [ "$_i" -le 12 ]; do
  ( . "$FROOT/harness/lib/ledger.sh"; felix_ledger_record "$LC" "race$_i" "tool	Bash" )
  _i=$((_i+1))
done
_i=1
while [ "$_i" -le 12 ]; do
  ( . "$FROOT/harness/lib/ledger.sh"
    felix_ledger_rollup "$LCP" "$LC" "race$_i" 2026-08-14 ) &
  _i=$((_i+1))
done
wait
ledsum="$( . "$FROOT/harness/lib/ledger.sh"; felix_ledger_summary "$LCP" )"
is "twelve sessions ending at once are all still counted" \
   "$(printf '%s\n' "$ledsum" | awk -F'\t' '$1 == "superpowers" { print $2 }')" "14"

# Memory already on disk was written as one file, and it is data rather than a
# format to be dropped. The reader takes both, and a session re-rolled into its
# own file replaces its old rows instead of being counted twice.
LL="$TMP/ledgerboth"; LLP="$LL/projects/widgetboth"
mkdir -p "$LLP" "$MEM/widgetboth"
: > "$LLP/stack.tsv"
printf 'old\t2026-08-01\ttool\tBash\t3\t1\nkept\t2026-08-02\ttool\tRead\t2\t1\n' \
  > "$MEM/widgetboth/ledger.tsv"
( . "$FROOT/harness/lib/ledger.sh"
  felix_ledger_record "$LL" old "tool	Bash"
  felix_ledger_rollup "$LLP" "$LL" old 2026-08-14 )
ledsum="$( . "$FROOT/harness/lib/ledger.sh"; felix_ledger_summary "$LLP" )"
has "a ledger written as one file is still read"     "$ledsum" "Read	1	2"
has "and re-rolling a session replaces its old rows" "$ledsum" "Bash	1	1"


# ----------------------------------------------- what a zero can mean -------
# An audit of the measurement layer found the retire list built on three
# structural zeros, none of them disuse. This block is the three of them.
LZ2="$TMP/lz2"; LZ2P="$LZ2/projects/wzero"; mkdir -p "$LZ2P" "$MEM/wzero/ledger.d"
printf 'plugin\tsecurity-guidance@x\t-\tlow\talways\nplugin\tplain@x\t-\tlow\talways\nplugin\tplaywright@x\t-\tlow\talways\n' > "$LZ2P/stack.tsv"

# (1) The MCP server a plugin ships is reached as plugin_<plugin>_<server>, and
# the summary stripped "@..." and ":..." off a name but never that prefix, so
# routes naming `playwright` and 393 reaches recorded as
# `plugin_playwright_playwright` were two capabilities that never met.
# playwright sat on the retire list with 773 reaches across three projects.
printf 'z1\t2026-09-01\tmcp\tplugin_playwright_playwright\t5\t0\nz1\t2026-09-01\tnamed\tplaywright\t0\t1\n' > "$MEM/wzero/ledger.d/z1.tsv"
_zsum() { ( . "$FROOT/harness/lib/ledger.sh"; felix_ledger_summary "$LZ2P" ); }
is "an mcp server reached under its plugin prefix credits the plugin" \
   "$(_zsum | awk -F'\t' '$1 == "playwright" { print $3 "/" $4 }')" "5/1"
is "and the prefixed name is not a capability of its own" \
   "$(_zsum | grep -c '^plugin_playwright')" "0"
printf 'z2\t2026-09-01\tmcp\tplugin_ecc_chrome-devtools\t2\t0\n' > "$MEM/wzero/ledger.d/z2.tsv"
is "a hyphenated server name still credits the plugin that ships it" \
   "$(_zsum | awk -F'\t' '$1 == "ecc" { print $3 }')" "2"
# (2) An agent row joins to its plugin the way a skill row does.
printf 'z3\t2026-09-01\tagent\tcode-simplifier:code-simplifier\t3\t0\n' > "$MEM/wzero/ledger.d/z3.tsv"
is "an agent reached is credited to the plugin that ships it" \
   "$(_zsum | awk -F'\t' '$1 == "code-simplifier" { print $3 }')" "3"

# (3) A hook leaves no tool call. PostToolUse sees tool calls and nothing else;
# another plugin's hook firing is invisible to it by construction, so a plugin
# whose contribution is a hook reads zero forever however much it does. That
# zero is not disuse and must not be reported as it — the recorded lesson,
# utilisation is not utility and the ledger was punishing prevention, made
# mechanical. But "ships a hook" is three things, not one, and the review of
# the first draft showed that on the real ledger the one row it reclassified
# was a plugin shipping a hook AND an MCP server AND a skill.
LZH="$TMP/lz2-home"
mkdir -p "$LZH/.claude/plugins" "$LZH/cache/security-guidance/1.0.0/hooks" "$LZH/cache/plain/1.0.0" \
         "$LZH/cache/mixed/1.0.0/hooks" "$LZH/cache/mixed/1.0.0/skills/x"
printf '{"hooks":{"PreToolUse":[]}}\n' > "$LZH/cache/security-guidance/1.0.0/hooks/hooks.json"
printf '{"hooks":{"PreToolUse":[]}}\n' > "$LZH/cache/mixed/1.0.0/hooks/hooks.json"
# The registry is read bounded to the entry. `nopath` sits FIRST with no
# installPath so that a scan which leaks into the next entry would classify it
# as the hooked plugin that follows it.
cat > "$LZH/.claude/plugins/installed_plugins.json" <<EOF
{"version": 2, "plugins": {
  "nopath@x": [],
  "security-guidance@x": [{"scope": "user", "installPath": "$LZH/cache/security-guidance/1.0.0", "version": "1.0.0"}],
  "mixed@x": [{"scope": "user", "installPath": "$LZH/cache/mixed/1.0.0", "version": "1.0.0"}],
  "plain@x": [{"scope": "user", "installPath": "$LZH/cache/plain/1.0.0", "version": "1.0.0"}]
}}
EOF
# One bounded reader, shared. Two libraries carried the same unbounded shape
# independently — the ledger's hook classifier and the commissioning
# provenance — and it failed the same two ways in both: an entry lacking the
# field returned the NEXT plugin's value, and a minified registry returned the
# last plugin's for every name. A wrong provenance is a declared row traceable
# to the wrong release, which is the one thing that row exists to prevent.
cat > "$LZH/.claude/plugins/reg-fields.json" <<EOF
{"plugins": {
  "nofield@x": [{"scope": "user"}],
  "second@x":  [{"scope": "user", "version": "2.0.0", "gitCommitSha": "bbbb"}],
  "third@x":   [{"scope": "user", "version": "3.0.0", "gitCommitSha": "cccc"}]
}}
EOF
_rf() { ( . "$FROOT/harness/lib/resolve.sh"; felix_registry_field "$1" "$2" "$LZH/.claude/plugins/reg-fields.json" ); }
is "an entry with no such field yields nothing, not the next entry's value" "$(_rf nofield version)"     ""
is "and the entry that has one still answers"                               "$(_rf second version)"      "2.0.0"
is "and a second field of the same entry too"                               "$(_rf second gitCommitSha)" "bbbb"
is "a plugin not in the registry yields nothing"                            "$(_rf absent version)"      ""
tr -d '\n' < "$LZH/.claude/plugins/reg-fields.json" > "$LZH/.claude/plugins/reg-min.json"
_rfm() { ( . "$FROOT/harness/lib/resolve.sh"; felix_registry_field "$1" "$2" "$LZH/.claude/plugins/reg-min.json" ); }
is "a one-line registry answers for the right plugin, not the last one"     "$(_rfm second version)"     "2.0.0"
is "and still yields nothing for the entry that lacks the field"            "$(_rfm nofield version)"    ""
# Neither caller reads the registry itself any more, which is the property
# that stops a second copy regrowing. Counting how many times each NAMES the
# shared function was the first draft, and a comment mentioning it counted too.
is "the ledger no longer opens the registry itself" \
   "$(grep -c 'installed_plugins.json' "$FROOT/harness/lib/ledger.sh")" "0"
# commission-provider.sh still names the file, for a presence grep, and that
# is correct: the fault being fixed is a per-entry FIELD lookup returning a
# neighbour's value, and a boolean over the whole file has no neighbour.
# Not "only one library names the file": ready.sh names it too and is right to.
# It ENUMERATES which plugins exist, which is a different question from looking
# a field up inside one named entry, and the unbounded scan cannot mislead it.
# The property is that nothing looks a field up outside the shared reader.
is "the field lookup lives in one place" \
   "$(grep -c 'index(line, p)' "$FROOT/harness/lib/"*.sh | awk -F: '$2 > 0 { n++ } END { print n + 0 }')" "1"

_zshape() { ( HOME="$LZH"; . "$FROOT/harness/lib/ledger.sh"; felix_ledger_hook_shape "$1" ); }
is "a plugin shipping hooks and nothing countable is hook-only"     "$(_zshape security-guidance)" "only"
is "one shipping hooks and a skill is mixed"                        "$(_zshape mixed)"             "mixed"
is "one shipping no hooks is plain"                                 "$(_zshape plain)"             "none"
is "one not installed at all is plain, because nothing says otherwise" "$(_zshape ghost)"          "none"
is "an entry with no path does not inherit the next entry's answer" "$(_zshape nopath)"            "none"
# The same registry minified to one line reads the same way.
LZM="$TMP/lz2-min"; mkdir -p "$LZM/.claude/plugins"
tr -d '\n' < "$LZH/.claude/plugins/installed_plugins.json" > "$LZM/.claude/plugins/installed_plugins.json"
_zshapem() { ( HOME="$LZM"; . "$FROOT/harness/lib/ledger.sh"; felix_ledger_hook_shape "$1" ); }
is "a one-line registry answers for the right plugin"               "$(_zshapem security-guidance)" "only"
is "and for the plain one"                                          "$(_zshapem plain)"             "none"
is "and the path-less one still inherits nothing"                   "$(_zshapem nopath)"            "none"

# All three cross the retire threshold identically: five sessions, named,
# never reached. They land in three different places.
for _i in 1 2 3 4 5; do
  printf 'h%s\t2026-09-0%s\tnamed\tsecurity-guidance\t0\t1\nh%s\t2026-09-0%s\tnamed\tplain\t0\t1\nh%s\t2026-09-0%s\tnamed\tmixed\t0\t1\n' "$_i" "$_i" "$_i" "$_i" "$_i" "$_i" > "$MEM/wzero/ledger.d/h$_i.tsv"
done
_zl() { ( HOME="$LZH"; . "$FROOT/harness/lib/ledger.sh"; "$1" "$LZ2P" | cut -f1 | tr '\n' ' ' ); }
is "the retire list keeps the zero that is disuse"                    "$(_zl felix_ledger_retire)"     "plain "
is "the unmeasurable list takes the hook-only zero"                   "$(_zl felix_ledger_unobserved)" "security-guidance "
is "and the partly-countable list takes the mixed one"                "$(_zl felix_ledger_partly)"     "mixed "

# The report renders all three and proposes the right thing for each: the row
# and the play for disuse, nothing for hook-only, the play alone for mixed.
# Rendered text, not a grep for a function name: the first draft asserted that
# the source mentioned felix_ledger_unobserved, which could not fail however
# wrong the sentence was.
mkdir -p "$MEM/widget/ledger.d"
for _i in 1 2 3 4 5; do cp "$MEM/wzero/ledger.d/h$_i.tsv" "$MEM/widget/ledger.d/zshape-h$_i.tsv"; done
_zrep="$(cd "$REPO" && HOME="$LZH" PATH="/usr/bin:/bin" "$FELIX" ledger 2>&1)"
has "felix ledger proposes retiring the disuse zero"            "$_zrep" "plain "
has "and says to remove its row and its play"                   "$_zrep" "Remove the row from"
has "it names the hook-only zero as unmeasurable"               "$_zrep" "unmeasurable: their contribution is a hook"
has "and proposes nothing for it"                               "$_zrep" "Nothing is proposed for these"
has "it names the mixed zero as only partly countable"          "$_zrep" "only partly countable"
has "and scopes that proposal to the play, keeping the row"     "$_zrep" "keep the row"
rm -f "$MEM/widget/ledger.d"/zshape-h*.tsv
is "and the widget ledger is as this block found it"            "$(ls "$MEM/widget/ledger.d"/zshape-* 2>/dev/null | wc -l | tr -d ' ')" "0"

# The unrouted block's closing caveat is evaluated, not printed.
#
# It used to be a straight-line "Weak while few sessions are recorded", keyed
# to nothing: the same sentence over two sessions, where it is apt, and over
# sixty-six, where the rows two lines above contradict it. felix_ledger_unrouted
# carries no session threshold — unlike retire, and correctly, since a
# one-session row here is legitimate — so this sentence is the only thing
# standing where retire has a filter, and prose cannot do a filter's job.
mkdir -p "$MEM/widget/ledger.d"
printf 'uw1\t2026-09-01\tplugin\tunrouted-thin@x\t0\t0\n' > "$MEM/widget/ledger.d/uw1.tsv"
_urep="$(cd "$REPO" && HOME="$LZH" PATH="/usr/bin:/bin" FELIX_LEDGER_MIN=5 "$FELIX" ledger 2>&1)"
has "a one-session routing gap is called weak, with the number"  "$_urep" "rests on 1 session(s)"
for _i in 2 3 4 5 6; do
  printf 'uw%s\t2026-09-0%s\tplugin\tunrouted-thin@x\t0\t0\n' "$_i" "$_i" \
    > "$MEM/widget/ledger.d/uw$_i.tsv"
done
_urep="$(cd "$REPO" && HOME="$LZH" PATH="/usr/bin:/bin" FELIX_LEDGER_MIN=5 "$FELIX" ledger 2>&1)"
has "and the same rows over more sessions are not"  "$_urep" "session(s) or more"
case "$_urep" in
  *"rests on 1 session"*) bad "so the caveat can become untrue" "$_urep" ;;
  *)                      ok  "so the caveat can become untrue" ;;
esac
rm -f "$MEM/widget/ledger.d"/uw*.tsv
# The banner carries none of this. It names the one thing worth acting on; an
# unmeasurable row proposes nothing, and a report nobody asked for is the same
# defect as a decision nobody needed to make.
is "the session banner does not carry the unmeasurable list" \
   "$(grep -c 'felix_ledger_unobserved\|felix_ledger_partly' "$FROOT/harness/hooks/session-start")" "0"

printf '\nreading the ledger, in the one direction that is honest\n'
# Written rows nothing reads is the same half-built shape as installing a tool
# no route can reach. Aggregation reduces to the owner, because a package is
# declared as superpowers@marketplace and invoked as superpowers:brainstorming.
LR="$TMP/ledgerread"; mkdir -p "$LR" "$MEM/ledgerread"
cat > "$MEM/ledgerread/ledger.tsv" <<'EOF'
s1	2026-08-01	skill	superpowers:brainstorming	3	1
s1	2026-08-01	plugin	playwright@x	0	1
s1	2026-08-01	plugin	context7@x	0	0
s2	2026-08-02	plugin	superpowers@x	0	1
s2	2026-08-02	plugin	playwright@x	0	1
s2	2026-08-02	mcp	context7	2	0
EOF
sum="$( . "$FROOT/harness/lib/ledger.sh"; felix_ledger_summary "$LR" )"
has "counts a package and its skill as one thing" "$sum" "superpowers	2	3"
has "sums invocations across sessions"            "$sum" "context7	2	2"
has "and keeps a never-invoked one at zero"       "$sum" "playwright	2	0"

# The asymmetry: only absence of use given presence is unconfounded, so only
# retirement is ever proposed and never the reverse.
p="$( . "$FROOT/harness/lib/ledger.sh"; FELIX_LEDGER_MIN=2 felix_ledger_retire "$LR" | tr '\n' ' ' )"
has "proposes retiring what was mounted and never reached for" "$p" "playwright"
case "$p" in
  *superpowers*) bad "never proposes retiring something that was used" "$p" ;;
  *context7*)    bad "never proposes retiring something that was used" "$p" ;;
  *)             ok  "never proposes retiring something that was used" ;;
esac
# Two sessions is not evidence. The window is sessions, not time, and a capability
# unused across two of them may simply not have come up yet.
p="$( . "$FROOT/harness/lib/ledger.sh"; FELIX_LEDGER_MIN=5 felix_ledger_retire "$LR" | tr -d '\n ' )"
is "and says nothing below the session threshold" "$p" ""

printf '\nzero is not one number\n'
# The design said a zero "has no alternative explanation: it was mounted, it was
# in scope, and it was ignored every time." That is false, and the false half is
# the half Felix controls. Felix decides what routes name. A capability no route
# ever named was never in scope in any sense the session could act on, so its
# zero measures Felix's own priors and retiring on it is a loop closing on
# itself — the recommender-bias shape, where logged data confounded by the
# logging policy looks like evidence for a year and is not.
#
# So the policy's decision is recorded next to the outcome. `named` is how many
# times a route pointed at a capability; `calls` is how often it was reached
# for. Two different zeros, and only one of them is about the capability.
LN="$TMP/ledgernamed"; mkdir -p "$LN" "$MEM/ledgernamed"
cat > "$MEM/ledgernamed/ledger.tsv" <<'EOF'
s1	2026-08-01	plugin	pointed-at@x	0	4
s1	2026-08-01	plugin	never-named@x	0	0
s2	2026-08-02	plugin	pointed-at@x	0	3
s2	2026-08-02	plugin	never-named@x	0	0
EOF
p="$( . "$FROOT/harness/lib/ledger.sh"; FELIX_LEDGER_MIN=2 felix_ledger_retire "$LN" | tr '\n' ' ' )"
has "retires what Felix pointed at and nobody reached for" "$p" "pointed-at"
case "$p" in
  *never-named*) bad "never retires what no route ever named" "$p" ;;
  *)             ok  "never retires what no route ever named" ;;
esac
u="$( . "$FROOT/harness/lib/ledger.sh"; felix_ledger_unrouted "$LN" | tr '\n' ' ' )"
has "reports it as a routing gap instead" "$u" "never-named"
case "$u" in
  *pointed-at*) bad "and not the one that was pointed at" "$u" ;;
  *)            ok  "and not the one that was pointed at" ;;
esac

# A kind with no invocation form is not a routing gap.
#
# The rollup writes a zero row for every stack.tsv line whatever its kind and
# everything downstream is kind-agnostic, so a marketplace entered the
# capability namespace as an equal. It is where plugins come from: no play
# form, no legal route entry, so its named=0 and calls=0 are a fact about the
# kind. It was being classified as the one thing routes.tsv can fix, and
# `felix next` handed out an action nobody can perform.
printf 'marketplace\tsomewhere\t-\tlow\talways\n' > "$LN/stack.tsv"
printf 's1\t2026-08-01\tmarketplace\tsomewhere\t0\t0\n' >> "$MEM/ledgernamed/ledger.tsv"
u="$( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/ledger.sh"
      felix_ledger_unrouted "$LN" | tr '\n' ' ' )"
case "$u" in
  *somewhere*) bad "a marketplace is not reported as a route that never fired" "$u" ;;
  *)           ok  "a marketplace is not reported as a route that never fired" ;;
esac
has "while the capability that can be named still is" "$u" "never-named"

# Rows written before the column existed say nothing either way. Reading a
# missing field as "named" would resurrect the overclaim in the one place
# nobody would look for it: the data already on disk.
LG="$TMP/ledgerlegacy"; mkdir -p "$LG" "$MEM/ledgerlegacy"
printf 's1\t2026-08-01\tplugin\told-shape@x\t0\ns2\t2026-08-02\tplugin\told-shape@x\t0\n' \
  > "$MEM/ledgerlegacy/ledger.tsv"
p="$( . "$FROOT/harness/lib/ledger.sh"; FELIX_LEDGER_MIN=2 felix_ledger_retire "$LG" | tr -d '\n ' )"
is "a row from before the column proposes nothing" "$p" ""
u="$( . "$FROOT/harness/lib/ledger.sh"; felix_ledger_unrouted "$LG" | tr -d '\n ' )"
is "and is not a routing gap either; it is unknown" "$u" ""

# And the recording end: what a route names is written down as it is named.
LH2="$TMP/ledgernote"; mkdir -p "$LH2/projects/widgetnote" "$MEM/widgetnote"
( . "$FROOT/harness/lib/ledger.sh"
  felix_ledger_record "$LH2" sn "tool	Bash"
  felix_ledger_note_named "$LH2" sn "superpowers:brainstorming code-review"
  felix_ledger_note_named "$LH2" sn "code-review" )
( . "$FROOT/harness/lib/ledger.sh"; felix_ledger_rollup "$LH2/projects/widgetnote" "$LH2" sn 2026-08-12 )
led="$(cat "$MEM/widgetnote/ledger.d/sn.tsv")"
has "a named capability carries its count"      "$led" "code-review	0	2"
has "and one named once carries one"            "$led" "superpowers:brainstorming	0	1"
has "while a tool that ran keeps its calls"     "$led" "tool	Bash	1"

printf '\nscope could not see what the diff added\n'
# `felix scope` is the unattended gate — red means a person decides. It asked
# felix_incident_severity, which takes PATHS, so it could only ever apply path
# rules. Both risk tables carry content rules (a credential in the added lines,
# destructive SQL), and scope was blind to every one of them.
#
# So a diff adding a live key to a documentation file printed "In scope.
# Reversible enough for an unattended attempt" and exited 0, while felix
# classify called the same diff red. Reproduced before it was believed.
SC="$TMP/scoperepo"; mkdir -p "$SC"
( _fx_cd "$SC" && git init -q -b main )
SC="$(cd "$SC" && pwd -P)"
printf 'widget\n' > "$SC/.felix"; printf 'notes\n' > "$SC/a.md"
( _fx_cd "$SC" && git add -A >/dev/null 2>&1 && git -c user.name=t -c user.email=t@t commit -qm base >/dev/null 2>&1 )
cp "$REAL_HARNESS/templates/risk.tsv" "$FROOT/projects/widget/risk.tsv"
printf 'api_key = "sk-ant''-api03-QQQQQQQQQQQQQQQQQQQQQQQQ"\n' >> "$SC/a.md"   # must_flag
( _fx_cd "$SC" && git add -A >/dev/null 2>&1 && git -c user.name=t -c user.email=t@t commit -qm leak >/dev/null 2>&1 )

out="$( cd "$SC" && "$FELIX" scope --base HEAD~1 2>&1 )"; rc=$?
is  "a credential added to a green path is out of scope" "$rc" "3"
has "and scope says which tier it reached"               "$out" "red"

# Bare paths carry no diff, so content rules cannot be applied at all. It must
# say so rather than report a tier that looks complete.
out="$( cd "$SC" && "$FELIX" scope a.md 2>&1 )"; rc=$?
is  "scoping a bare path still answers"      "$rc" "0"
has "but admits it never read the changes"   "$out" "content"

# A base that names nothing compared nothing. The diff it could not read came
# back empty, which read as nothing to scope, and with a change in the tree
# the classifier called it unknown, which is not red, so scope said "In
# scope". Both exited 0, the status the unattended verify step pushes on.
out="$( cd "$SC" && "$FELIX" scope --base no-such-ref 2>&1 )"; _sbc=$?
printf 'more notes\n' >> "$SC/a.md"
out="$out$( cd "$SC" && "$FELIX" scope --base no-such-ref 2>&1 )"; _sbd=$?
( _fx_cd "$SC" && git checkout -q -- a.md )
is  "a --base that names nothing is refused, not scoped, clean tree or not" \
    "clean:$_sbc changed:$_sbd" "clean:1 changed:1"
has "and it says nothing was compared" "$out" "names nothing here"

# The content rules then read one source of the three the paths come from.
# felix_classify_diff took its paths from felix_changed_paths (the branch, the
# index and the worktree) and its added lines from `base...HEAD` alone, so an
# uncommitted line was a path with no content: named, rated by its extension,
# never read. A credential typed into a documentation file and not committed
# yet was "In scope". The unattended verify step only missed it by committing
# before it asked. The control comes first, so the red below cannot be read as
# "anything uncommitted is red".
( _fx_cd "$SC" && git reset -q --hard HEAD ) >/dev/null 2>&1
printf 'more notes\n' >> "$SC/a.md"
out="$( cd "$SC" && "$FELIX" scope --base HEAD 2>&1 )"; rc=$?
is  "an uncommitted edit with nothing in it stays in scope" "$rc" "0"
# `sk-` and not `sk-ant-`: must_flag excuses a fixture line to secret-scan only
# when no hard shape is on it, and `sk-ant-` is one. The risk table's rule reads
# both, so the rule under test is the same.
printf 'token = "sk-RRRRRRRRRRRRRRRRRRRRRRRR"\n' >> "$SC/a.md"   # must_flag
out="$( cd "$SC" && "$FELIX" scope --base HEAD 2>&1 )"; rc=$?
is  "an uncommitted credential added to a green path is out of scope" "$rc" "3"
has "and scope names the tier the line reached"                        "$out" "highest tier: red"
( _fx_cd "$SC" && git add a.md ) >/dev/null 2>&1
out="$( cd "$SC" && "$FELIX" scope --base HEAD 2>&1 )"; rc=$?
is  "and so is a staged one" "$rc" "3"
# Every other caller of felix_classify_diff reads the same staged line, since a
# library assertion passes while a call site stays broken (#65).
has "classify reads it too"                  "$( cd "$SC" && "$FELIX" classify --base HEAD 2>&1 )" "tier:  red"
has "and so does the tier a pull request would be labelled with" \
    "$( cd "$SC" && "$FELIX" pr --base HEAD 2>&1 )" "tier:     red"
has "and the receipt's risk tier"            "$( cd "$SC" && "$FELIX" receipt --base HEAD 2>&1 )" '"tier": "red"'
( _fx_cd "$SC" && git reset -q --hard HEAD ) >/dev/null 2>&1

# And on a stacked branch the content rules read three-dot, which the paths
# stopped doing for #51. A squash freezes the merge-base, so every line the
# branch below added was read again as this branch's own: a docs-only branch
# was out of scope for a credential main already held.
SK="$TMP/scopestack"; mkdir -p "$SK"
( _fx_cd "$SK" && git init -q -b main
  git config user.email t@t; git config user.name t
  printf 'widget\n' > .felix; printf 'notes\n' > a.md; git add -A; git commit -qm init
  git checkout -q -b feat-a
  printf 'api_key = "sk-QQQQQQQQQQQQQQQQQQQQQQQQ"\n' >> a.md   # must_flag
  git add -A; git commit -qm "A: a credential"
  git checkout -q -b feat-b
  printf 'more\n' > NOTES.md; git add -A; git commit -qm "B: docs only"
  git checkout -q main; git merge -q --squash feat-a; git commit -qm "A squashed (#1)"
  git checkout -q feat-b ) >/dev/null 2>&1
SK="$(cd "$SK" && pwd -P)"
is "the squash leaves this merge-base behind main as well" \
   "$( cd "$SK" && [ "$(git merge-base main HEAD)" = "$(git rev-parse main)" ] && echo same || echo behind )" \
   "behind"
out="$( cd "$SK" && "$FELIX" scope --base main 2>&1 )"; rc=$?
is "a stacked branch is not out of scope for a credential its base already merged" "$rc" "0"
# The control that keeps it honest: a fix that narrowed everything would pass
# the line above and stop enforcing.
printf 'api_key = "sk-SSSSSSSSSSSSSSSSSSSSSSSS"\n' >> "$SK/NOTES.md"   # must_flag
( _fx_cd "$SK" && git add -A && git -c user.name=t -c user.email=t@t commit -qm "B: its own" ) >/dev/null 2>&1
out="$( cd "$SK" && "$FELIX" scope --base main 2>&1 )"; rc=$?
is "but a credential the branch adds itself still is" "$rc" "3"

