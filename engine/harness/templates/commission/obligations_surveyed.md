# Request: propose the obligations {{PROJECT}} owes and nobody has named

Written by `felix commission` or `felix obligations --request` for a session's
model to act on. The engine cannot run a model (constitution invariant 2), so
it writes this request and reads back the answer file named at the end.
Topology `{{TOPOLOGY}}`. Epoch `{{EPOCH}}`.

This is obligation discovery, v3.2 §9, first increment: a baseline pass over
one product. Every row you write is a CANDIDATE. Nothing you write is admitted:
admission is a person copying a row into `{{PROJ_DIR}}/obligations.tsv` and
committing it, and the engine will refuse any row that claims otherwise.

Read `{{PROJ_DIR}}/CLAUDE.md`, then the product's checkout at `{{ROOT}}`.

The grounded facts — every probe the product declares, with its state and
count as last read. A candidate may ground only on a predicate listed here;
you may run these probe commands read-only from `{{ROOT}}` to see members:

{{PROBES}}

Already admitted, not to be re-proposed:

{{ADMITTED}}

Propose engineering obligations this product owes that nobody named — the
requirement that would block an incomplete deploy while an argument about
something else is going on, and that stops applying when the grounded system
stops making it applicable. Prefer few and grounded to many and vague.

Then write the answer file, exactly this shape, tab-separated, at most forty
rows:

    # topology {{TOPOLOGY}}
    # epoch {{EPOCH}}
    <obligation>	<class>	<applies>	<evidence>	<grounds>	<failure_mode>	<reason>
    done	<count of rows above>

to:

    {{OUT}}

What the reader enforces, so a row is not refused without a word:

- exactly seven tab-separated fields, tabs not spaces
- obligation matches `^[a-z][a-z0-9_]*$` and is not already admitted
- class is INFO or ADVISORY. A blocking class is refused, not downgraded: a
  single model finding is advisory only, and a person admits it with the
  class they can defend
- applies is a shell command that exits 0 when the obligation applies to a
  checkout and 1 when it does not, or `-` for always
- evidence is a shell command that exits 0 when the obligation holds, 1 when
  it fails, 2 when it cannot examine, and prints a verdict per member. Never
  `-`: a candidate nothing could discharge is a wish
- grounds is one or more predicates from the list above, comma-separated; `-`
  is refused, because a proposal grounded on nothing Felix reads from reality
  is the fabrication the spec forbids
- failure_mode is one token naming what goes wrong, e.g. uncontrolled_cost
- reason is one sentence of at most 300 characters

Neither applies nor evidence is executed by the engine on your word; a person
reads them first. There is no pathway column: the engine stamps every
candidate `probabilistic`.
