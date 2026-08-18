# {{PROJECT_NAME}}

{{PRODUCT_PARAGRAPH}}

<!-- Hard cap 6000 bytes, no @-imports; the pre-commit lint enforces.
     One fact, one home: design -> docs/design/DESIGN.md · behavior -> tests ·
     active tasks -> TODO.md · finished rows -> DONE.md · rejections ->
     docs/SETTLED.md · stories -> commit message bodies. Record nothing twice.
     A new lesson lands at the FIRST rung that holds it:
     deny-hook > test > lint check > rule line here > docs/agent/ note. -->

## Commands & Layout

<!-- Build/test/run + where code lives. Verify a line when touching its area;
     delete dead lines. -->
{{COMMANDS_AND_LAYOUT}}

## Stack

| Layer | Choice |
|---|---|
{{STACK_ROWS}}
<!-- One line per layer. Unknown = "TBD - locked when <trigger>" + a
     Blocked-on-owner row in TODO.md. -->

## Rules

<!-- Max 25 R-lines, grammar `R<n>: <imperative> - <one-clause why>`
     (lint-checked). A rule belongs here only if no test or hook can catch
     the violation AND an agent would commit it by default; otherwise write
     the test, lint check, or docs/agent/ note instead. At the cap: retire
     one to add one. -->
R1: Evidence = commands run + output observed. {{EVIDENCE_STANDARD}}
R2: A subagent claim is unverified until re-run first-hand - unverified means [partial], never done.
R3: Never edit docs/design/** or the design-gated code paths in .githooks/commit-msg GATED_PATHS - propose a diff and stop; landing an approved change requires [design-approved] in the commit message. <!-- delete this R-line (and renumber nothing) when no design surface exists -->
R4: Never bypass the pre-commit hook (--no-verify) or edit .githooks/.
R5: Grep docs/SETTLED.md before raising an audit finding or re-proposing a change.
R6: Write a SETTLED line only when the owner rejects a proposal or a finding proves wrong - never to log a choice.
R7: No secrets, tokens, dumps, or third-party personal data in any doc or commit message - cite the artifact path instead.
{{PROJECT_RULES}}

## Pointers

- TODO.md - active work; read when picking or landing work. Done rows move verbatim to DONE.md (never read wholesale; grep to check whether something was already done).
- docs/SETTLED.md - the record of "no".
<!-- Conditional bullets - the lint fails on pointers to paths that do not
     exist. Delete the docs/agent/ line when no docs/agent/ file was
     generated; delete the DESIGN.md line (and R3 above) when there is no
     design surface. -->
- docs/agent/ - activity guides; read the matching file before that work.{{POINTER_EXTRAS}}
- docs/design/DESIGN.md - read before any UI, copy, or design work; the source of truth, assets beside it (R3).
- History and rationale: `git log --grep=<term>` before re-deriving old reasoning.
