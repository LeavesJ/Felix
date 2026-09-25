# Felix

The engineering OS, and the pilot of implementation. It turns intent into
verified, shipped code and **decides** how that happens rather than suggesting
it. It holds no product code.

Not a sandbox and not an advisor. A product that adopts Felix should get a
system that does whatever implementation takes — choosing tooling, installing
it, tracking what happened, correcting course — so the founder is left with
"what should we build next" and "should we add this".

Felix is a product for other people's projects, not only the founder's own.
Decided 2026-09-22, this replaces "Phase 1 of the guidebook and nothing past
it" as the statement of what Felix is for. It is built first, and best, on
Claude Code, and is host-independent by design: what it decides must not
depend on which agent did the work, and a second host comes once Claude Code
is right. So judge a change by whether it survives a stranger adopting it —
what it installs, where its ledger lives, whether its verdict holds on their
repository — and not only by whether it works here.

Felix still governs engineering and nothing past it. Billing, customers,
support and administration of the projects it governs are not its work; a
Stripe row in a template is a dormant capability, not a direction Felix grows
in. Design its surfaces so something other than a human can drive them.

## The split

**The founder owns what gets built.** Product thesis, vision, prioritisation,
pitching, and approval at the risk boundaries.

**What waits for the founder's yes is direction, and only direction.** Some
documents change what Felix is, who it is for, or the order it is built in:
- a roadmap, or a change to one;
- this charter's account of what Felix is and of this split;
- an amendment that overrides the founder's own architecture text.

Such a document is shown to the founder and merged only after a yes. Once it
lands, the founder gives the delivery one word: yes, partial or no.

Nothing else waits. Engineering, fixes, tables, action items, handoffs, and
documents that only record what the founder said all merge on green, as
before. Asking for a yes on any of those is a needless stop, the most common
way the founder's time went into the agent's job. Decided 2026-09-23, after a
roadmap merged and was withdrawn four minutes later.

**Felix owns how it gets built, optimally.** Which MCP, which plugin, which
skill, which agent, in which order, in one context or several. Then the whole
loop around that choice: read the project, plan the work, arrange the tooling,
verify, classify, ship, repair, and remember.

If the founder is thinking about tooling, Felix has failed at its job.

**Stealth in the middle.** A session should hear from Felix at its start and at
its end, and otherwise not at all. Everything between is either invisible —
context handed to the model, records written to disk — or a refusal, which by
definition had to interrupt. Status reaches the founder at the end, in the
session's closing notice, because nobody opened the monitor to find it; the
monitor stays as the deeper page for anyone who wants more (decided
2026-09-23). Status does not belong in the middle of a founder's session. A
report nobody asked for is the same defect as a decision nobody needed to make.

**One exception, allowed by the founder on 2026-09-23 and deliberately
narrow.** A session whose hooks run an older Felix than the one installed may
be told so on the person's screen once in its life:
- at a stop where Felix says nothing else;
- as a line that starts no model turn;
- naming `/reload-plugins`.

It is argued in `docs/2026-09-23-restart-moments-scope.md`, and it stays off
until the person has seen the line render. Any other mid-session line needs
that decision taken again.

One honest limit on "arrange the tooling": Claude Code cannot mount an MCP
server or switch on a plugin mid-session. Within a session Felix names what to
reach for; between sessions it writes the configuration so the next one boots
with the toolbox this work actually needs. Naming is the fallback, not the
design.

This is written down because the opposite was written down first. Felix called
itself "the governance layer" and built a complete vocabulary for saying no —
gate, classify, evidence, quarantine, guard, scope — and not one word for
saying "do this next." Every later decision followed that charter correctly.
The charter was the defect.

## What must stay true

1. **The engine names no project.** Anything under `engine/harness` that
   mentions a specific project is a bug, and the gate fails on it. Governing
   something new is a directory and a JSON file, never an edit to the engine.
2. **The enforcing path is bash and git only.** Hooks and the gate run in every
   session on every machine, and must work with no network, no key and no
   model. A command that advises may call a model, but its output is a proposal
   and never a verdict, and it may only ever narrow what the mechanical path
   already allowed. A model that could widen permission is the gate, and then
   there is no gate.

   **One exception, added 2026-08-12 and deliberately narrow.** A `reviewed`
   escape clears on a recorded reviewer verdict, and that widens. It exists
   because some surfaces have no mechanical verdict to override — a rubric that
   teaches the wrong thing passes every check there is — so the alternative to a
   reviewer is not a stricter check, it is nobody reading it. The exception is
   bounded three ways: a verdict clears `reviewed` and no other channel, so no
   review can release a secret, run CI or move a store; it is keyed to the exact
   tree and dies when the tree changes; and only `pass` clears, so a reviewer
   that never ran reads the same as one that refused. Argued in full in
   `engine/harness/lib/review.sh`. Do not widen it to a second channel without
   deciding that again.
3. **Felix acts on what is reversible and escalates what is not.** Printing a
   suggestion for something it could safely have done is a defect, not caution.
   Irreversible work still stops and asks.
4. **Felix installs what it has read and judged low-risk.** `felix discover`
   already fetches a candidate at its pinned sha and reads what it ships before
   saying anything; refusing to then act on that reading was the governance
   charter talking, not a limit. `risk=high` is still refused by every flag
   from every caller, and anything touching credentials, live keys or
   irreversible external writes still stops for a person. That boundary is the
   guidebook's autonomy ladder, not timidity.
5. **A gate that cannot fail is not a gate.** Anything claiming to verify must
   be shown failing before it is believed.
6. **Uninstalling never deletes a home, nor a memory root.** They were one
   directory until 2026-08-14 and are now two: the home holds doctrine, and
   `$FELIX_MEMORY` — `~/.felix/memory` by default — holds memory. They were
   split because a home *is* the checkout whenever Felix governs itself, so
   storing memory under it published every governed project's record along with
   the doctrine. Neither is Felix's to delete.

## Architecture

Three top-level directories carry all of it, and the split between them is what
makes invariant 1 enforceable rather than aspirational.

- **`engine/harness/`** — the engine, which names no project. `felix` is the
  CLI, `lib/` its forty-one sourced libraries, `hooks/` the entry points Claude
  Code calls, `templates/` the seeds a new project is cut from, and `tests/run`
  the suite whose recorded count lives in `tests/assertions.tsv`. Bash and git
  and nothing else, because it governs projects in languages it must not
  require.
- **`projects/<name>/`** — one directory per governed project: its `CLAUDE.md`,
  its `gate.sh`, a `project.json` naming the remote it matches, and its tables.
  Governing something new is a directory here and a JSON file, never an edit to
  the engine.
- **`state/`** — records the engine derives and re-derives: discovery caches,
  ledgers, route decisions, gate and commissioning receipts, the monitor page.
  Nothing here is authored by hand, and nothing here is authority.

Memory is the fourth thing and is deliberately not in the tree: `$FELIX_MEMORY`,
defaulting to `~/.felix/memory/<project>/`, computed from `$HOME` and never from
the home. Invariant 6 says why.

**The tables are the extension point, not the code.** `routes.tsv`,
`stack.tsv`, `profiles.tsv`, `probes.tsv`, `risk.tsv`, `evidence.tsv`,
`deny.tsv`, `maintenance.tsv` and `commissioning.tsv` are where behaviour is
added for one project; the matching file under `engine/harness/templates/` is
where it is added for every project at once. Ask which table already answers a
question before adding a library that answers it again.

## Non-obvious patterns

- **Engine deploys happen in the home checkout, not a worktree.** The marketplace
  is a directory marketplace pinned to one path, so a worktree's engine is never
  the one served, and `felix install` from a worktree re-points the marketplace
  at that worktree. Merging is not affected: since #239 the gate's `installed`
  check asks whether the engine main declares is the one deployed, which a
  worktree can answer, so engine work is done in a worktree, merged from there
  on green CI, and deployed by pulling the home and running `felix install`.
- **The gate gates the tree it is standing in, not the tree it lives in**, and
  it prints that path in its header. Read the header before believing a pass.
- **A tab-separated read applies its IFS to the substitution too.**
  `IFS=$'\t' read ... <<EOF $(...)` hands the tab IFS to the captured command as
  well, so a multi-line capture arrives as one field and everything after the
  first line is dropped in silence. The engine is TSV the whole way down; this
  costs a session every time it is rediscovered.
- **`lessons.md` under the memory root holds the rest**, and it is mounted per
  matched route rather than per session — so a session on an unmatched route is
  told none of it. A trap that cost real time belongs there, through
  `felix promote`, and not in this file.

## Tiers

Editing `engine/harness/lib` or the hook is adversarial: those run in every
session of every governed project, and a mistake there is silent. Templates and
per-project data under `projects/` are ordinary changes.

## Delivery

Run the suite and commit as one chain. A piped test run masks the exit status
and will commit a red tree.
