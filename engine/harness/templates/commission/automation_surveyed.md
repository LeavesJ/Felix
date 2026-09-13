# Request: survey the automations {{PROJECT}} implies

Written by `felix commission` for a session's model to act on. The engine
cannot run a skill (constitution invariant 2), so it writes this request and
reads back the answer file named at the end. Topology `{{TOPOLOGY}}`.

Run the skill:

    /claude-code-setup:claude-automation-recommender
    Project {{PROJECT}}, at {{ROOT}}. Felix already detected: {{CAPS}}
    Already declared, do not repeat these: {{DECLARED}}
    Recommend hooks, subagents, skills, plugins and MCP servers this stack
    implies that are not in that list. Read-only: Felix decides what to adopt.

Then write the answer file, exactly this shape, tab-separated, one row per
recommendation, at most forty rows:

    # topology {{TOPOLOGY}}
    <kind>	<name>	<source>	<capability>	<why>
    done	<count of rows above>

to:

    {{OUT}}

kind is one of plugin, mcp, hook, skill, subagent. name is the plugin or
server or skill name as the marketplace or registry spells it, no spaces.
source is a URL or `-`. capability is one of the capabilities Felix detected
or declared above, or `-`. why is one sentence, and one sentence is what the
300-character ceiling below is for. There is no risk column:
risk is not the model's to assign, and a row carrying one is malformed.

What the reader enforces, so a row is not refused without a word:

- exactly five tab-separated fields per row, tabs not spaces; a sixth field
  is refused as a risk column
- name matches `^[A-Za-z0-9@._:-]+$` — no slash, no space, no brackets; a
  URL belongs in source, not in name
- no backtick, `$(`, `;`, `|` or `&` anywhere in a row, in any field
  including why — the row is never executed, and the ban is how that stays
  true
- at most forty rows; rows past the ceiling are refused
- source at most 200 characters, capability at most 64, why at most 300 —
  a longer field is refused, not shortened. The ceilings are the log's:
  an accepted row is appended to an append-only record that outlives this
  file, so a field it could not hold whole would be lost rather than clipped
- line 1 is exactly `# topology {{TOPOLOGY}}`: column 0, one space after `#`,
  no trailing whitespace, LF line endings, no byte-order mark
- the last non-blank line is `done` <TAB> the count of rows above it; the
  count must equal the rows, or the file reads as partial and nothing is read

Nothing in this file is installed by being written here. A plugin row is
fetched at its pinned commit, read, tiered and corroborated by the engine
before anything is declared, and only a low tier installs; an mcp row is
never installed from a request; hook, skill and subagent rows are recorded
and reported, because Felix authors none of those.
