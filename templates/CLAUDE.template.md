# {{PROJECT_NAME}} — Behavioral Contract

{{PRODUCT_PARAGRAPH}}

<!-- Always-loaded contract. Budget {{BUDGET_CLAUDE}} bytes (raises: none — a raise
     must state what was pruned first and be listed here). Rules live here, one
     line each; stories live once in CHANGELOG.md and are pointed to. NOT here:
     task state (PLAN.md), history (CHANGELOG.md), full decisions (LEDGER.md). -->

## Read order

- Always: this file.
- Picking or landing work: PLAN.md.
- Touching a ledgered area: its LEDGER.md row + cited entries.
- CHANGELOG/archives: only via pointer or grep — `rg "<slug>" CHANGELOG*.md LEDGER.md` (plain `grep -rn` if rg is unavailable) — never wholesale.

## Critical Constraints

<!-- Shipping blockers. Terse imperative, one line each. A constraint whose
     story has been pruned MUST carry a pointer of the form
     → CL YYYY-MM-DD (<slug>) -->
{{CONSTRAINTS}}

## Tech Stack (locked)

| Layer | Choice | Notes |
|---|---|---|
{{STACK_ROWS}}
<!-- Unknown = "TBD — locked when <trigger>" + a Decisions Needed entry in PLAN.md.
     Locking a row later = fill it + dated CHANGELOG entry, same commit. -->

## Active decisions

<!-- One line per Active LEDGER.md row, ≤200 chars, format:
     #N: <rule> → CL YYYY-MM-DD (<slug>)
     The LEDGER row wins on any disagreement. Retiring a row deletes its line
     here; the row itself is immortal in LEDGER.md. -->

## Working Agreements

- Evidence standard: {{EVIDENCE_STANDARD}}
- Evidence names what was run and observed. A claim sourced from a subagent report is unverified until re-run first-hand; unverified ⇒ [Partial], never [Done].
- A spec without a Bookkeeping section (which ledger row / changelog entry / PLAN row it updates) is incomplete — add it before implementing.
- Statuses: [Todo] [In-Progress] [Done] [Partial] [N/A]; ⚠ = blocked on an owner decision (PLAN.md Decisions Needed). [Partial] with the gap named beats a fake [Done].

## Workbench Notes

<!-- Recurring gotchas promoted from CHANGELOG entries: terse rule + pointer.
     Promote only what applies to every future session. -->
{{PLATFORM_SECTIONS}}
## Maintenance

- Landing work: update every doc home in the same commit, per the spec's Bookkeeping list. Never "docs later".
- Editing this file: run `scripts/doc-lint.sh`. Over budget → prune stories to CHANGELOG or docs/notes/ first, same commit, own dated entry. Never squeeze rules. Notes are named `docs/notes/YYYY-MM-DD-<slug>.md` so pointers to them resolve.
- Editing CHANGELOG: entries are immutable; append only. Over ~50 KB → rotate oldest entries (entry boundaries only) to `CHANGELOG-archive-<range>.md`, own commit, content-preserving, update the archive index in its header.
- Deviating from an approved design/copy: LEDGER.md row + extract here + pointer. Never silent.
- Touching an area: verify the inline rules naming its files/symbols still hold. A falsified rule is corrected + changelog-entried in the same commit.
- Precedence when files disagree: code > CLAUDE.md > CHANGELOG > PLAN. A mismatch becomes a correction entry, never a silent doc edit.
- CHANGELOG merge conflicts: keep both sides, re-sort by date, never drop an entry. Subagents never write the shared docs directly; the main session reconciles.
- Secrets: never paste credentials, tokens, keys, dumps, or third-party personal data into any doc — cite the artifact instead. Redaction is the only permitted in-place edit: replace with `[redacted YYYY-MM-DD: reason]` + a new dated entry recording it. If it was pushed, rotate the credential — git history keeps it.
{{LITE_TASKS_SECTION}}
