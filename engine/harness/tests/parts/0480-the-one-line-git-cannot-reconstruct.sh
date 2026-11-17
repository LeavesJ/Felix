# The cache-filling path end to end, with the marketplace and the source both
# stubbed. The candidate's blurb is written to be chosen from and says llm; the
# copy on disk ships storybook/css skills and no description at all. The blurb
# is how a tracing plugin and an inference provider were both misfiled; the
# cache row must carry what the thing ships.
_widget_repo_build
_recon_build
printf 'llm\nfrontend\n' > "$FROOT/projects/reconproj/capabilities"
DQSRC="$TMP/discover-quiet-src"
mkdir -p "$DQSRC/skills/storybook-css" "$DQSRC/.claude-plugin"
# git tracks files, not directories: an empty skill directory would vanish in
# the fetch and the inspect would read a plugin that ships nothing.
printf '# storybook-css\n' > "$DQSRC/skills/storybook-css/SKILL.md"
printf '{"name": "shipster"}\n' > "$DQSRC/.claude-plugin/plugin.json"
( _fx_cd "$DQSRC" && git init -q -b main && git add -A \
  && git -c user.email=t@t.t -c user.name=t commit -qm fixture )
DQB="$TMP/discover-quiet-bin"; mkdir -p "$DQB"
cat > "$DQB/claude" <<EOF
#!/usr/bin/env bash
cat <<JSON
[
  {
    "name": "shipster",
    "description": "an llm prompt evaluation kit",
    "source": {
      "url": "file://$DQSRC",
      "path": ""
    }
  }
]
JSON
EOF
chmod +x "$DQB/claude"
out="$(cd "$RREPO" && PATH="$DQB:$PATH" "$FELIX" discover --quiet 2>&1)"
has "the cache row carries the capability the skills serve" "$out" "shipster	frontend	low"
case "$out" in
  *"shipster	llm"*) bad "and the blurb no longer outranks the manifest" "$out" ;;
  *)                 ok  "and the blurb no longer outranks the manifest" ;;
esac

# The same path for a candidate whose copy ships nothing that runs and whose
# marketplace entry declares an LSP server. The listing names the marketplace,
# the registry names its catalogue, and the row carries what the entry says.
DQE="$TMP/discover-quiet-entry"
mkdir -p "$DQE/src/skills/storybook-css" "$DQE/mkt/.claude-plugin" "$DQE/bin"
printf '# storybook-css\n' > "$DQE/src/skills/storybook-css/SKILL.md"
( _fx_cd "$DQE/src" && git init -q -b main && git add -A \
  && git -c user.email=t@t.t -c user.name=t commit -qm fixture )
printf '{"name":"entrymkt","plugins":[{"name":"lspster","source":"./x","strict":false,"lspServers":{"css":{"command":"css-ls"}}}]}\n' \
  > "$DQE/mkt/.claude-plugin/marketplace.json"
printf '{"entrymkt":{"installLocation":"%s"}}\n' "$DQE/mkt" > "$DQE/known.json"
cat > "$DQE/bin/claude" <<EOF
#!/usr/bin/env bash
cat <<JSON
[
  {
    "name": "lspster",
    "description": "an llm prompt evaluation kit",
    "marketplaceName": "entrymkt",
    "source": {
      "url": "file://$DQE/src",
      "path": ""
    }
  }
]
JSON
EOF
chmod +x "$DQE/bin/claude"
out="$(cd "$RREPO" && PATH="$DQE/bin:$PATH" FELIX_KNOWN_MARKETPLACES="$DQE/known.json" "$FELIX" discover --quiet 2>&1)"
is "the cache row carries the tier its marketplace entry declares" \
   "$(printf '%s\n' "$out" | awk -F'\t' '$1 == "lspster" { print $3 }')" "medium"

printf '\nthe one line git cannot reconstruct\n'
# The handoff regenerates the whole file, so whoever filled in "what was in
# progress" lost it the next time anything ran — while the mechanical half,
# which git can rebuild at any moment, survived. The only irreplaceable line
# was the only one being erased.
HP="$TMP/handoffproj"; mkdir -p "$HP" "$MEM/handoffproj"
( . "$FROOT/harness/lib/memory.sh"; felix_mem_handoff "$HP" "$REPO" "gate.sh" "mid-refactor" )
has "a note reaches the file" "$(cat "$MEM/handoffproj/SESSION_HANDOFF.md")" "mid-refactor"
( . "$FROOT/harness/lib/memory.sh"; felix_mem_handoff "$HP" "$REPO" "gate.sh" )
has "and survives a regeneration that was given none" \
    "$(cat "$MEM/handoffproj/SESSION_HANDOFF.md")" "mid-refactor"
( . "$FROOT/harness/lib/memory.sh"; felix_mem_handoff "$HP" "$REPO" "gate.sh" "something else" )
has "a new note replaces it" "$(cat "$MEM/handoffproj/SESSION_HANDOFF.md")" "something else"
# The placeholder must not be carried forward as though it were a real note.
rm -f "$MEM/handoffproj/SESSION_HANDOFF.md"
( . "$FROOT/harness/lib/memory.sh"; felix_mem_handoff "$HP" "$REPO" "gate.sh" )
( . "$FROOT/harness/lib/memory.sh"; felix_mem_handoff "$HP" "$REPO" "gate.sh" )
has "and the placeholder stays a placeholder" \
    "$(cat "$MEM/handoffproj/SESSION_HANDOFF.md")" "fill this in"

printf '\na handoff nobody regenerated is refused, not regenerated over\n'
# Authored blind, against the written contract, before the guard existed. The
# incident: a 212,864-byte handoff written by hand, with no Regenerated line,
# would have been replaced by about 565 bytes of git state. Regeneration now
# owns only what it wrote: no file, the empty placeholder, or its own shape
# (line 1 exactly `# Handoff`, line 3 `Regenerated YYYY-MM-DD.`). Anything else
# is refused unless REPLACE=1 / --replace, and every write lands by rename.
HG="$TMP/handguard"; HGM="$MEM/handguard"; HGF="$HGM/SESSION_HANDOFF.md"
mkdir -p "$HG" "$HGM"; printf 'unrelated\n' > "$HGM/DEVLOG.md"
_hg()     { ( . "$FROOT/harness/lib/memory.sh"; felix_mem_handoff "$HG" "$REPO" "gate.sh" "$@" ); }
_hgsz()   { wc -c < "$1" | tr -d ' '; }
_hgls()   { ls -A "$1" | sort | tr '\n' ' '; }
_hgino()  { ls -i "$1" | awk '{print $1}'; }
_hgnote() { sed -n 's/^- what was in progress: //p' "$1" | head -1; }
_hgl3()   { sed -n 3p "$1" | grep -qE '^Regenerated [0-9]{4}-[0-9]{2}-[0-9]{2}\.'; }
# The incident's exact size, deterministic, and titled `# Handoff` so that only
# line 3 can tell it from the generated shape.
_hgbig() { awk -v n=212864 'BEGIN {
  s = "# Handoff\n\nWritten by hand over a long session; none of it is regenerated.\n\n"
  for (i = 1; ; i++) {
    if (t + length(s) >= n) { printf "%s", substr(s, 1, n - t); exit }
    printf "%s", s; t += length(s)
    s = sprintf("- step %04d: context a person kept that git cannot rebuild, and why\n", i) } }' > "$1"; }

_hgbig "$HGF"; cp "$HGF" "$TMP/handguard.keep"
_hge="$(_hg "an overwrite nobody asked for" 2>&1 >/dev/null)"; _hgrc=$?
[ "$_hgrc" -ne 0 ] && ok "a hand-written handoff is refused by the library" \
  || bad "a hand-written handoff is refused by the library" "returned 0"
is  "and keeps all 212864 of its bytes" "$(_hgsz "$HGF")" "212864"
cmp -s "$HGF" "$TMP/handguard.keep" && ok "and every byte is the one it had" \
  || bad "and every byte is the one it had" "the content changed"
has "the refusal on stderr names the size in bytes" "$_hge" "212864"
is  "and a refusal leaves no file beside it" "$(_hgls "$HGM")" "DEVLOG.md SESSION_HANDOFF.md "

# REPLACE=1 is the way through, and it lands by rename: a file rewritten in
# place keeps its inode, one renamed over it does not. Rebuilt first, so that
# an engine which overwrote it above cannot pass what follows for that reason.
_hgbig "$HGF"; _hgi="$(_hgino "$HGF")"
_hg "taken over on purpose" 1 >/dev/null 2>&1; _hgrc=$?
is  "REPLACE=1 overwrites a hand-written handoff" "$_hgrc" "0"
[ "$(sed -n 1p "$HGF")" = "# Handoff" ] && _hgl3 "$HGF" \
  && ok "with the generated shape" || bad "with the generated shape" "$(sed -n 1,3p "$HGF")"
is  "and the note it was given" "$(_hgnote "$HGF")" "taken over on purpose"
if grep -q 'step 0001' "$HGF"; then bad "and none of the hand-written lines" "still there"
else ok "and none of the hand-written lines"; fi
[ "$(_hgino "$HGF")" != "$_hgi" ] && ok "the write is renamed into place, not rewritten in it" \
  || bad "the write is renamed into place, not rewritten in it" "same inode $_hgi"
is  "and a write leaves no file beside it" "$(_hgls "$HGM")" "DEVLOG.md SESSION_HANDOFF.md "

# Its own shape, and the placeholder, are regenerated as before.
_hg "second note" >/dev/null 2>&1; _hgrc=$?
is  "its own shape is regenerated without asking" "$_hgrc" "0"
is  "and a new note replaces the old one" "$(_hgnote "$HGF")" "second note"
_hg >/dev/null 2>&1
is  "and is carried when none is given" "$(_hgnote "$HGF")" "second note"
printf '# Handoff\n\nRegenerated 2025-01-02. Anything below is the state of the tree,\nnot a summary of intent.\n\n- what was in progress: an old stamped note\n\nappended by hand\n' > "$HGF"
_hg >/dev/null 2>&1; _hgrc=$?
is  "a stamped handoff from another day is regenerated" "$_hgrc" "0"
sed -n 3p "$HGF" | grep -q "^Regenerated $(date +%Y-%m-%d)\." && ! grep -q 'appended by hand' "$HGF" \
  && ok "into today's shape" || bad "into today's shape" "$(sed -n 1,3p "$HGF")"
is  "with its note carried forward" "$(_hgnote "$HGF")" "an old stamped note"
: > "$HGF"
_hg >/dev/null 2>&1; _hgrc=$?
is  "the empty placeholder is regenerated" "$_hgrc" "0"
_hgl3 "$HGF" && ok "into the generated shape" || bad "into the generated shape" "$(sed -n 1,3p "$HGF")"
rm -f "$HGF"; _hg "from nothing" >/dev/null 2>&1
is  "a first write leaves only the handoff beside what was there" "$(_hgls "$HGM")" "DEVLOG.md SESSION_HANDOFF.md "

# The shape is two exact lines, not a word found anywhere.
_hgref() {
  printf '%b' "$2" > "$HGF"; cp "$HGF" "$TMP/handguard.keep"
  if _hg "should not land" >/dev/null 2>&1; then bad "$1" "returned 0"
  elif cmp -s "$HGF" "$TMP/handguard.keep"; then ok "$1"
  else bad "$1" "refused, but the file changed"; fi
}
_hgref "a # Handoff title with no stamp on line 3 is refused" '# Handoff\n\nNotes kept by hand.\n'
_hgref "a stamp on a line other than 3 is refused" '# Handoff\n\nNotes kept by hand.\n\nRegenerated 2026-09-01. Anything below\n'
_hgref "a stamp under a different title is refused" '# Handoff, by hand\n\nRegenerated 2026-09-01. Anything below\n'
_hgref "a stamp with no date is refused" '# Handoff\n\nRegenerated by hand, last week.\n'
_hgref "a stamp with no full stop after the date is refused" '# Handoff\n\nRegenerated 2026-09-01 by hand\n'
_hgref "a file of one newline is not the empty placeholder" '\n'

# The CLI. The widget's handoff is saved first and put back after.
[ -e "$MEM/widget/lifecycle.log" ] || : > "$MEM/widget/lifecycle.log"
WHF="$MEM/widget/SESSION_HANDOFF.md"
cp -p "$WHF" "$TMP/widget-handoff.saved" 2>/dev/null; _hgw=$?
_hgbig "$WHF"; cp "$WHF" "$TMP/widget-big.keep"; _hgwl="$(_hgls "$MEM/widget")"
_ho="$(cd "$MEMREPO" && "$FELIX" handoff an overwrite nobody asked for 2>&1)"; _hrc=$?
[ "$_hrc" -ne 0 ] && ok "felix handoff refuses a hand-written handoff" \
  || bad "felix handoff refuses a hand-written handoff" "exited 0"
cmp -s "$WHF" "$TMP/widget-big.keep" && ok "and leaves it as it was, byte for byte" \
  || bad "and leaves it as it was, byte for byte" "$(_hgsz "$WHF") bytes now"
has "and says how many bytes it would have destroyed" "$_ho" "212864"
has "and names --replace as the way through" "$_ho" "--replace"
case "$_ho" in
  *"wrote $WHF"*) bad "and does not print that it wrote the handoff" "$_ho" ;;
  *)              ok  "and does not print that it wrote the handoff" ;;
esac
is  "and leaves no new file in the project's memory" "$(_hgls "$MEM/widget")" "$_hgwl"
_hgbig "$WHF"
_ho="$(cd "$MEMREPO" && "$FELIX" handoff --was "replaced on purpose" --replace 2>&1)"; _hrc=$?
is  "felix handoff --replace overwrites it" "$_hrc" "0"
_hgl3 "$WHF" && ok "and writes the generated shape in its place" \
  || bad "and writes the generated shape in its place" "$(sed -n 1,3p "$WHF")"
is  "with the note --was gave it" "$(_hgnote "$WHF")" "replaced on purpose"
is  "and still no new file beside it" "$(_hgls "$MEM/widget")" "$_hgwl"
: > "$WHF"
_ho="$(cd "$MEMREPO" && "$FELIX" handoff 2>&1)"; _hrc=$?
is  "the CLI still regenerates the empty placeholder" "$_hrc" "0"
has "and says it wrote it" "$_ho" "wrote $WHF"
if [ "$_hgw" = 0 ]; then cp -p "$TMP/widget-handoff.saved" "$WHF"; else rm -f "$WHF"; fi

# A handoff that is itself a symlink is written through to the file it names,
# as the redirection the rename replaced did. Renamed onto the link, the link
# would become a regular file and the file it named would go stale in silence.
# Both spellings of a link: absolute, and relative to the memory directory.
HL="$TMP/handlink"; HLM="$MEM/handlink"; mkdir -p "$HL" "$HLM" "$TMP/handlink-abs" "$MEM/handlink-rel"
( . "$FROOT/harness/lib/memory.sh"; felix_mem_handoff "$HL" "$REPO" "gate.sh" "before the link" )
cp "$HLM/SESSION_HANDOFF.md" "$TMP/handlink-abs/SESSION_HANDOFF.md"
cp "$HLM/SESSION_HANDOFF.md" "$MEM/handlink-rel/SESSION_HANDOFF.md"
rm -f "$HLM/SESSION_HANDOFF.md"
ln -s "$TMP/handlink-abs/SESSION_HANDOFF.md" "$HLM/SESSION_HANDOFF.md"
( . "$FROOT/harness/lib/memory.sh"; felix_mem_handoff "$HL" "$REPO" "gate.sh" "through an absolute link" )
[ -L "$HLM/SESSION_HANDOFF.md" ] && ok  "a symlinked handoff is still a symlink after a write" \
                                 || bad "a symlinked handoff is still a symlink after a write"
has "and the file it names holds the new handoff" \
    "$(cat "$TMP/handlink-abs/SESSION_HANDOFF.md")" "through an absolute link"
rm -f "$HLM/SESSION_HANDOFF.md"
ln -s ../handlink-rel/SESSION_HANDOFF.md "$HLM/SESSION_HANDOFF.md"
( . "$FROOT/harness/lib/memory.sh"; felix_mem_handoff "$HL" "$REPO" "gate.sh" "through a relative link" )
[ -L "$HLM/SESSION_HANDOFF.md" ] && ok  "a relative link survives a write too" \
                                 || bad "a relative link survives a write too"
has "and the file it names, relative to the link, holds the new handoff" \
    "$(cat "$MEM/handlink-rel/SESSION_HANDOFF.md")" "through a relative link"
# A link to a link: every hop, each relative to the link it came from. One hop
# would land the rename on the middle link and strand the file at the end.
mkdir -p "$MEM/handlink-mid" "$MEM/handlink-end"
cp "$MEM/handlink-rel/SESSION_HANDOFF.md" "$MEM/handlink-end/SESSION_HANDOFF.md"
ln -s ../handlink-end/SESSION_HANDOFF.md "$MEM/handlink-mid/SESSION_HANDOFF.md"
rm -f "$HLM/SESSION_HANDOFF.md"
ln -s ../handlink-mid/SESSION_HANDOFF.md "$HLM/SESSION_HANDOFF.md"
( . "$FROOT/harness/lib/memory.sh"; felix_mem_handoff "$HL" "$REPO" "gate.sh" "through two links" )
[ -L "$HLM/SESSION_HANDOFF.md" ] && [ -L "$MEM/handlink-mid/SESSION_HANDOFF.md" ] \
  && ok  "a chain of links keeps every link" \
  || bad "a chain of links keeps every link" "$(ls -l "$HLM/SESSION_HANDOFF.md" "$MEM/handlink-mid/SESSION_HANDOFF.md")"
has "and the file at the end of it holds the new handoff" \
    "$(cat "$MEM/handlink-end/SESSION_HANDOFF.md")" "through two links"

# The redirection kept the file's mode, because it rewrote the same file. A
# rename puts a new file there, so the mode is carried across by hand: somebody
# who closed a handoff to other users should not find it open again.
HM="$TMP/handmode"; HMM="$MEM/handmode"; mkdir -p "$HM" "$HMM"
( . "$FROOT/harness/lib/memory.sh"; felix_mem_handoff "$HM" "$REPO" "gate.sh" "first" )
chmod 600 "$HMM/SESSION_HANDOFF.md"
( . "$FROOT/harness/lib/memory.sh"; felix_mem_handoff "$HM" "$REPO" "gate.sh" "second" )
is  "a regenerated handoff keeps the mode it had" \
    "$(ls -l "$HMM/SESSION_HANDOFF.md" | cut -c1-10)" "-rw-------"

# The temporary file exists only between the write and the rename, never while
# git is being asked: the git calls are the slow part and the part a person
# interrupts, and a temporary file left there would be committed by the next
# pulse. A git that looks for one before answering.
HT="$TMP/handtmp"; HTM="$MEM/handtmp"; HTB="$TMP/handtmp-bin"; mkdir -p "$HT" "$HTM" "$HTB"
: > "$TMP/handtmp.seen"
cat > "$HTB/git" <<EOF
#!/usr/bin/env bash
printf 'asked\n' >> "$TMP/handtmp.seen"
ls -A "$HTM" | grep -q 'SESSION_HANDOFF.md.' && printf 'present\n' >> "$TMP/handtmp.seen"
exec "$(command -v git)" "\$@"
EOF
chmod +x "$HTB/git"
( PATH="$HTB:$PATH"; . "$FROOT/harness/lib/memory.sh"; felix_mem_handoff "$HT" "$REPO" "gate.sh" "watched" )
[ "$(grep -c asked "$TMP/handtmp.seen")" -gt 0 ] && ok  "the watching git was asked" \
                                                 || bad "the watching git was asked" "the stub never ran"
is  "no temporary file exists while git is being asked" "$(grep -c present "$TMP/handtmp.seen")" "0"

printf '\nFelix noticing its own gaps\n'
# Two coverage gaps were found today by a person noticing, not by any check.
# Absence has no line number: nothing greps for a hook that was never written.
# The stance table turns that into something that fails.
CVT="$TMP/cov"; mkdir -p "$CVT"
printf 'Stop\twired\trefuse completion\nNotification\tdeclined\tnothing to add\n' > "$CVT/lifecycle.tsv"
printf '{"hooks":{"Stop":[{}]}}\n' > "$CVT/hooks.json"
out="$( . "$FROOT/harness/lib/coverage.sh"; felix_coverage_check "$CVT" "$CVT/hooks.json" )"
has "a wired moment with a stance is ok"   "$out" "ok	Stop"
has "and a declined one is ok too"         "$out" "ok	Notification"

# Declared wired, nothing wiring it. A hook deleted in a refactor looks exactly
# like this and looks like nothing at all without the table.
printf 'Stop\twired\trefuse completion\n' > "$CVT/lifecycle.tsv"
printf '{"hooks":{}}\n' > "$CVT/hooks.json"
out="$( . "$FROOT/harness/lib/coverage.sh"; felix_coverage_check "$CVT" "$CVT/hooks.json" )"
has "a hook that stopped being wired is caught" "$out" "missing	Stop"

# Wired with nothing saying why. Someone adds a hook and never argues for it.
printf 'Stop\twired\trefuse completion\n' > "$CVT/lifecycle.tsv"
printf '{"hooks":{"Stop":[{}],"PreToolUse":[{}]}}\n' > "$CVT/hooks.json"
out="$( . "$FROOT/harness/lib/coverage.sh"; felix_coverage_check "$CVT" "$CVT/hooks.json" )"
has "a hook nobody explained is caught" "$out" "undeclared	PreToolUse"

# The row that matters: a moment the platform offers that nobody has considered.
# This is the check that would have named SubagentStop out loud.
#
# The roster is discovered from what this machine binds, so on a bare runner it
# is empty and this asserted nothing while reporting ok — the exact failure the
# roster was rewritten to avoid, reproduced one level up in the test for it. A
# fixture HOME binds two known events, so the discovery runs against something
# on every machine instead of against whatever the laptop happens to have.
CVH="$TMP/coverage-home"; mkdir -p "$CVH/.claude"
printf '{"hooks":{"SessionStart":[],"SubagentStop":[]}}\n' > "$CVH/.claude/settings.json"
printf 'Stop\twired\trefuse completion\n' > "$CVT/lifecycle.tsv"
out="$( HOME="$CVH" . "$FROOT/harness/lib/coverage.sh"
        HOME="$CVH" felix_coverage_unconsidered "$CVT" | tr '\n' ' ' )"
has "an unconsidered moment is named"  "$out" "SubagentStop"
has "and so is every other one"        "$out" "SessionStart"

# A decline is permanent by construction: nothing ever re-reads whether the
# reason still holds. PreCompact is declined *because* the SessionStart matcher
# contains `compact`, so narrowing that matcher makes the decline false and
# nothing says so. The fourth column names the literal the reason rests on.
printf 'PreCompact\tdeclined\tSessionStart matches on compact\tcompact\n' > "$CVT/lifecycle.tsv"
printf '{"hooks":{"SessionStart":[{"matcher":"startup|clear|compact"}]}}\n' > "$CVT/hooks.json"
out="$( . "$FROOT/harness/lib/coverage.sh"; felix_coverage_check "$CVT" "$CVT/hooks.json" )"
has "a decline whose premise still holds is ok" "$out" "ok	PreCompact"

printf '{"hooks":{"SessionStart":[{"matcher":"startup|clear"}]}}\n' > "$CVT/hooks.json"
out="$( . "$FROOT/harness/lib/coverage.sh"; felix_coverage_check "$CVT" "$CVT/hooks.json" )"
has "a decline whose premise died is caught" "$out" "stale-reason	PreCompact"
has "and it names the literal that went missing" "$out" "'compact' is no longer in hooks.json"

# `-` is allowed. A decline resting on judgement rather than on a literal is
# honest, and forcing everyone to invent a token would just produce fake ones.
# It is counted rather than accepted silently, so "N declines rest on nothing
# checkable" is visible instead of the excuses being invisible.
printf 'Notification\tdeclined\tnothing to add\t-\n' > "$CVT/lifecycle.tsv"
printf '{"hooks":{}}\n' > "$CVT/hooks.json"
out="$( . "$FROOT/harness/lib/coverage.sh"; felix_coverage_check "$CVT" "$CVT/hooks.json" )"
has "a decline resting on nothing checkable is still ok" "$out" "ok	Notification"
out="$( . "$FROOT/harness/lib/coverage.sh"; felix_coverage_unchecked "$CVT" )"
is "but it is counted" "$out" "1"

# A three-column table is the old format and must keep working, or every
# governed project's table breaks the day the engine updates.
printf 'Notification\tdeclined\tnothing to add\n' > "$CVT/lifecycle.tsv"
out="$( . "$FROOT/harness/lib/coverage.sh"; felix_coverage_check "$CVT" "$CVT/hooks.json" )"
has "a table with no holds column still works" "$out" "ok	Notification"
out="$( . "$FROOT/harness/lib/coverage.sh"; felix_coverage_unchecked "$CVT" )"
is "and its declines count as unchecked" "$out" "1"

# The shipped table must not regress into unfalsifiable declines. Every one it
# carries either names a literal or is deliberately counted.
out="$( . "$FROOT/harness/lib/coverage.sh"
        felix_coverage_check "$REAL_HARNESS/templates" "$REAL_HARNESS/../hooks/hooks.json" \
        | grep -c '^stale-reason' || true )"
is "no shipped decline rests on a dead premise" "$out" "0"

# And the real table, which must have an opinion on every moment there is.
out="$( . "$FROOT/harness/lib/coverage.sh"
        felix_coverage_unconsidered "$REAL_HARNESS/templates" | tr -d '\n ' )"
is "the shipped table considers every moment" "$out" ""
out="$( . "$FROOT/harness/lib/coverage.sh"
        felix_coverage_check "$REAL_HARNESS/templates" "$REAL_HARNESS/../hooks/hooks.json" \
        | grep -vc '^ok' || true )"
is "and the shipped wiring matches its stance" "$out" "0"

printf '\na bundled plugin is present, not missing\n'
# `claude plugin list` reports what came from a marketplace and nothing else, so
# a plugin compiled into the binary is absent from it while being live in every
# session. Checking presence against only that source reported three real tools
# as missing on every session — the kind of false alarm that teaches somebody to
# skim a pre-flight check until it says nothing they believe.
BP="$TMP/bundleproj"; mkdir -p "$BP"
printf 'plugin\tanthropic-skills\t-\tlow\talways\n' > "$BP/stack.tsv"
# The report walks what routes name, not stdin, so the row has to exist for the
# tool to be asked about at all.
printf 'doc\tpdf slide\tcore\tanthropic-skills:pdf\n' > "$BP/routes.tsv"
# Run with the claude CLI off PATH, which is the case this exists for and was
# also the case these assertions were quietly not testing. They passed here and
# failed on CI for a year's worth of commits' worth of reasons: on a laptop the
# CLI answers, so the bundled branch was never the branch being reached. A
# machine with no CLI is the honest fixture, and every runner is one.
NOCLI=/usr/bin:/bin
out="$( PATH="$NOCLI" . "$FROOT/harness/lib/ready.sh"
        # The narrow source knows nothing; the inventory knows it is bundled.
        felix_ready_inventory() { printf 'plugin\tanthropic-skills\n'; }
        PATH="$NOCLI" felix_ready_report "$BP" )"
has "a bundled plugin reads as usable" "$out" "usable"
has "and says why"                     "$out" "bundled"
# With no CLI and nothing bundled, `absent` would be a guess wearing a verdict's
# clothes: Felix cannot tell "not installed" from "installed where I cannot
# look". Saying so is the whole point of the unknown row, and claiming absent
# here would be the same false alarm the bundled fix was written to stop.
out="$( PATH="$NOCLI" . "$FROOT/harness/lib/ready.sh"
        felix_ready_inventory() { printf 'plugin\tsomething-else\n'; }
        PATH="$NOCLI" felix_ready_report "$BP" )"
has "with no CLI and nothing bundled, Felix says it cannot tell" "$out" "cannot check"

# And where the CLI can answer, not installed still means absent.
# Only where the CLI can see a plugin installed here: a unit of P's run has a HOME of its own (slice 3, A17), and
# under the land tick's environment the CLI then lists none, which reads as a machine with nothing installed.
if has_claude && [ "$(claude plugin list --json 2>/dev/null | LC_ALL=C grep -c '"id"')" -gt 0 ]; then
  out="$( . "$FROOT/harness/lib/ready.sh"
          felix_ready_inventory() { printf 'plugin\tsomething-else\n'; }
          felix_ready_report "$BP" )"
  has "one genuinely absent still reads absent" "$out" "absent"
else
  skip "one genuinely absent still reads absent" "no claude CLI on this machine, or one that lists no plugin"
fi

printf '\nevery command says it exists\n'
# Thirty-four commands dispatched and help printed eight. Twenty-six were
# undiscoverable, including `install`, which is how the engine is deployed, and
# `new`, which is how anything is governed at all. Four of them were added the
# same day by somebody who edited the comment block at the top of the file and
# believed that was the help text.
_dispatched="$(sed -n '/^case "${1:-help}"/,/^esac/p' "$FROOT/harness/felix" \
  | grep -oE '^  [a-z-]+\)' | tr -d ' )' | grep -vE '^(help)$' | LC_ALL=C sort -u)"
_helped="$("$FELIX" help 2>&1)"
_undocumented=""
while IFS= read -r c; do
  [ -n "$c" ] || continue
  case "$_helped" in *"felix $c"*) ;; *) _undocumented="$_undocumented $c" ;; esac
done <<EOF
$_dispatched
EOF
[ -z "$_undocumented" ] && ok "help covers every command that dispatches" \
                        || bad "help covers every command that dispatches" "missing:$_undocumented"

printf '\nshape reaches the session that needs it\n'
# Computing shape and waiting to be asked is the same half-built shape as
# installing a tool no route can reach. The moment it matters is the moment
# somebody points at a plan, which is a thing the prompt hook can see.
SR="$TMP/shaperepo"; mkdir -p "$SR/docs"
cat > "$SR/docs/p.md" <<'EOF'
### Task 1: One

**Files:**
- Create: `lib/a.sh`

### Task 2: Two

**Files:**
- Modify: `lib/a.sh`

### Task 3: Three

**Files:**
- Modify: `docs/z.md`
EOF
_named() { ( . "$FROOT/harness/lib/shape.sh"; felix_shape_named "$1" "$SR" ); }
is "finds a plan the prompt points at" \
   "$(_named '{"prompt":"execute docs/p.md now"}')" "docs/p.md"
is "and one written as a path"          \
   "$(_named '{"prompt":"work through ./docs/p.md"}')" "docs/p.md"
is "ignores a file that does not exist" "$(_named '{"prompt":"read docs/nope.md"}')" ""
# A markdown file with no tasks is not a plan, and treating one as a plan would
# put a confident empty answer in front of every prompt naming a readme.
printf '# just prose\n' > "$SR/docs/notes.md"
is "and a document that is not a plan"  "$(_named '{"prompt":"see docs/notes.md"}')" ""
# The envelope names the transcript path, which ends in .jsonl but has been a
# source of phantom matches before. It must never be read as a plan.
is "never the transcript in the envelope" \
   "$(_named '{"transcript_path":"/x/docs/p.md","prompt":"hello"}')" ""

out="$( . "$FROOT/harness/lib/shape.sh"; felix_shape_brief "$SR/docs/p.md" )"
has "briefs which tasks are one unit" "$out" "1,2"
has "and which stand alone"           "$out" "3"

