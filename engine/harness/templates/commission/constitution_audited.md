# Request: audit the constitution of {{PROJECT}}

Written by `felix commission` for a session's model to act on. The engine
cannot run a skill (constitution invariant 2), so it writes this request and
reads back the answer file named at the end. Topology `{{TOPOLOGY}}`.

Run the skill:

    /claude-md-management:claude-md-improver
    Audit {{PROJ_DIR}}/CLAUDE.md against {{ROOT}}.
    Felix already covers verification, capabilities and risk tiers; add
    architecture and non-obvious patterns, and leave the invariants alone:
    those accrete from felix promote rather than being invented.

The skill edits CLAUDE.md under its own approval flow; Felix does not read
those edits. What Felix reads is one line: the score the skill's quality
report gave the file, so the row can move from awaiting to answered and the
number is on record.

Then write the answer file, exactly this shape, tab-separated:

    # topology {{TOPOLOGY}}
    score	<n>/100	<grade>
    done	1

to:

    {{OUT}}

The first line must repeat the topology hash above, exactly as
`# topology {{TOPOLOGY}}` — column 0, one space after `#`, no trailing
whitespace, LF line endings, no byte-order mark; an answer written for
another topology is stale and is not read. The one data row is exactly three
tab-separated fields: the word `score`, then `<n>/100`, then a grade. The
last line is `done` <TAB> `1`; a file without it is partial and is not read.
No backtick, `$(`, `;`, `|` or `&` anywhere in the file.
