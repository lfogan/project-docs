# {{PROJECT_NAME}} — Behavioral Contract

{{PRODUCT_PARAGRAPH}}

<!-- Always-loaded contract. Budget {{BUDGET_CLAUDE}} bytes (raises: none — a raise
     must state what was pruned first and be listed here). {{BUDGET_CLAUDE}}
     bytes is a ceiling, not a target — it was measured from an extreme-rule-
     density outlier project. A fresh contract landing near it on day one is
     diagnostic of a problem, not compliance. Rules live here, one line each;
     stories live once in CHANGELOG.md and are pointed to. NOT here: {{NOT_HERE}} -->

## Read order

- Always: this file.
{{READ_ORDER_MODE_BULLETS}}
- After compaction or any mid-task context reset: re-read your {{STATE_ROW}} for the task in hand before continuing — a compaction summary is not the state.
- CHANGELOG/archives: only via pointer or grep — `rg "<slug>" {{GREP_TARGETS}}` (plain `grep -rn` if rg is unavailable) — never wholesale.

## Critical Constraints

<!-- Shipping blockers. Terse imperative, one line each. A rule that would
     look wrong to fresh eyes without its reason — a prohibition that reads
     like a bug, a blocked shortcut, anything irreversible — carries a
     one-clause why inline: terse, never mysterious. Any other rule whose
     story has been pruned MUST carry a pointer of the form
     → CL YYYY-MM-DD (<slug>) -->
{{CONSTRAINTS}}

## Commands & Layout

<!-- Build/test/run commands + where code lives. Highest-traffic section:
     a wrong or missing line here costs every future session a round of
     re-discovery. One line per command; verify lines still work when
     touching the area they name. -->
{{COMMANDS_AND_LAYOUT}}

## Tech Stack (locked)

| Layer | Choice | Notes |
|---|---|---|
{{STACK_ROWS}}
<!-- Unknown = "TBD — locked when <trigger>" + {{TBD_ESCALATION}}.
     Locking a row later = fill it + dated CHANGELOG entry, same commit. -->

## Active decisions

{{ACTIVE_DECISIONS_COMMENT}}

## Working Agreements

- Evidence standard: {{EVIDENCE_STANDARD}}
- Evidence names what was run and observed. A claim sourced from a subagent report is unverified until re-run first-hand; unverified ⇒ [Partial], never [Done].
- A spec without a Bookkeeping section ({{BOOKKEEPING_HOMES}}) is incomplete — add it before implementing.
- Statuses: [Todo] [In-Progress] [Done] [Partial] [N/A]; ⚠ = blocked on an owner decision ({{BLOCKED_HOME}}). [Partial] with the gap named beats a fake [Done].
- An [In-Progress] row names its branch + next concrete action — a session can die anytime, and unlanded work has no other home.

## Workbench Notes

<!-- Recurring gotchas promoted from CHANGELOG entries: terse rule + pointer.
     Promote only what applies to every future session. -->
{{PLATFORM_SECTIONS}}
## Maintenance

- Landing work: update every doc home in the same commit, per the spec's Bookkeeping list. Never "docs later".
- Editing this file: run `scripts/doc-lint.sh`. Over budget → prune stories to CHANGELOG or docs/notes/ first, same commit, own dated entry. Never squeeze rules. Notes are named `docs/notes/YYYY-MM-DD-<slug>.md` so pointers to them resolve.
- {{STATE_BUDGET_LINE}}
- Editing CHANGELOG: entries are immutable; append only. Over ~50 KB → rotate oldest entries (entry boundaries only) to `CHANGELOG-archive-<range>.md`, own commit, content-preserving, update the archive index in its header.
- Deviating from an approved design/copy: {{DEVIATION_ACTION}}. Never silent.
- Touching an area: verify the inline rules naming its files/symbols still hold. A falsified rule is corrected + changelog-entried in the same commit.
- Precedence when files disagree: {{PRECEDENCE_ORDER}}. A mismatch becomes a correction entry, never a silent doc edit.
- Shared docs are written only by the main session, one docs pass per task: {{SUBAGENT_PAYLOAD_RULE}}
- CHANGELOG merge conflicts: keep both sides, re-sort by date, never drop an entry.
- Secrets: never paste credentials, tokens, keys, dumps, or third-party personal data into any doc — cite the artifact instead. Redaction is the only permitted in-place edit: replace with `[redacted YYYY-MM-DD: reason]` + a new dated entry recording it. If it was pushed, rotate the credential — git history keeps it.
{{LITE_TASKS_SECTION}}
