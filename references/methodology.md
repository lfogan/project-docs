# project-docs methodology — rationale and worked examples

Loaded on demand only. The generated files are the runtime authority; this
explains why they are shaped that way, for generation time and for humans.

## Why this shape

Origin: a full Android app build (2026), run agentically. Its
four-file system worked but its always-loaded contract grew to 97 KB because
stories (histories, amendment sagas, verification narratives) lived inline
beside the rules, and the same story was retold in a ledger row, a changelog
entry, and a plan cell. This skill keeps the proven separation and adds the
context-economy layer: rules inline, stories written once and pointed to,
unbounded structures (ledger, history) in on-demand files, budgets measured
not aspired to, and a 5-check lint for the failures that corrupt silently.
Full derivation: the design spec in ../docs/, revision 2 (internal adversarial
pass + 5-persona council review, both applied).

## Rule vs story — worked example

Ledger row as the origin project wrote it (condensed): several hundred words
on watermark copy, approval dates, review findings, a fix narrative. As this
system writes it:

- LEDGER.md row: `| 28 | Active·amended 2026-07-16 | Free-tier burned video carries a small text watermark naming the app, ~25% transparency, bottom-right | sell polish, not capability; free clips advertise the app | → CL 2026-07-13 (watermark-free-tier), → CL 2026-07-16 (watermark-text-shortened) |`
- CLAUDE.md extract: `#28: free-tier burns carry a watermark naming the app → CL 2026-07-13 (watermark-free-tier)`
- The several hundred words: two CHANGELOG entries, written once, grep-reachable.

Pointers can also resolve to a `docs/notes/` file instead of a CHANGELOG
entry; notes are named `docs/notes/YYYY-MM-DD-<slug>.md` so pointers to them
resolve.

## Spec sections

Every spec written in a project using this system includes:

- **Origin** — what prompted this, one paragraph.
- **Changes** — numbered, each independently reviewable.
- **Named consequences** — real effects flagged for the owner, not judged.
- **Deferred** — explicitly out of scope, with the trigger that revives each.
- **Bookkeeping** — the exact doc updates: which LEDGER row (new or amended),
  which CHANGELOG entry (date + slug), which PLAN row, same commit as landing.

The generated CLAUDE.md carries the one-line version ("a spec without a
Bookkeeping section is incomplete"); this is the full definition.

## Lite → full upgrade

Lite = CLAUDE.md (with inline `## Tasks` table) + CHANGELOG.md + AGENTS.md +
lint. Upgrade when the task table outgrows one screen or a second contributor
arrives: move the table to PLAN.md (from PLAN.template.md), move any accreted
decision lines to LEDGER.md rows + extracts, delete the `## Tasks` section,
record the upgrade as a dated CHANGELOG entry. One session, no data loss.

## Multi-writer repos

CLAUDE.md is an instruction surface: repo write access = changing agent
behavior for every future session. For repos with more than one writer, add a
CODEOWNERS entry for CLAUDE.md/LEDGER.md and review contract diffs with code-
level care. Never paste unreviewed external text into CLAUDE.md or docs/notes/.

## Budget provenance

The default CLAUDE.md budget shipped by SKILL.md is the measured rules-only
residue of the origin project's real 97 KB contract (+30% headroom), not a guess.
The number is 45000 bytes, measured from an extreme-rule-density outlier
(LGPL legal text, a native pipeline, 42 Active ledger rows). Treat it as a
ceiling, not a target — a fresh project's CLAUDE.md landing near it on day
one is diagnostic of a problem, not compliance.
Measurement: ../docs/2026-08-04-budget-backtest.md. Re-run the method on any
project whose shape differs wildly and set the budget from YOUR number.
