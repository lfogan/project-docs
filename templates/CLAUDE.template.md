# {{PROJECT_NAME}}

{{PRODUCT_PARAGRAPH}}

<!-- Hard cap: 6000 bytes, whole file, no @-imports — the pre-commit lint fails
     past it. One fact, one home: design in docs/design/, behavior in tests,
     task state in TODO.md, rejections in docs/SETTLED.md, stories in commit
     message bodies. Nothing is recorded twice, so nothing can disagree.
     Enforcement ladder for any new lesson — land it at the FIRST rung that
     holds it: deny-hook > test > lint check > rule line here > docs/agent/
     note. A rule line is the last resort and is debt: graduate it up the
     ladder and delete it. Healthy rules_count trends DOWN. -->

## Commands & Layout

<!-- Build/test/run + where code lives. Highest-traffic section: a wrong line
     here costs every session a re-discovery. Verify lines when touching the
     area they name; delete dead ones — git remembers. -->
{{COMMANDS_AND_LAYOUT}}

## Stack

| Layer | Choice |
|---|---|
{{STACK_ROWS}}
<!-- One line per layer, no narrative. Unknown = "TBD — locked when <trigger>"
     + a Blocked-on-owner row in TODO.md. -->

## Rules

<!-- Cap: 25 R-lines (lint-checked, grammar `R<n>: <imperative> — <one-clause
     why>`). Admission test, BOTH must hold: (a) no test or hook can catch the
     violation, (b) a competent agent would violate it by default. Fails
     either → it becomes a test, a lint check, or a docs/agent/ note — not a
     rule. Adding line 26 means retiring one first. -->
R1: Evidence = commands run + output observed. {{EVIDENCE_STANDARD}}
R2: A subagent claim is unverified until re-run first-hand — unverified ⇒ [Partial], never done.
R3: Never edit docs/design/** — it is the owner-approved source of truth; propose a diff and stop. Landing an approved change requires [design-approved] in the commit message.
R4: Never bypass the pre-commit hook (--no-verify) or edit .githooks/ — the lint is the contract.
R5: Grep docs/SETTLED.md before raising an audit finding or re-proposing a change — settled stays settled unless the owner reopens it.
R6: Artifacts are the record. Write a SETTLED line only when the owner kills a proposal or a finding proves wrong — never to log a choice.
R7: No secrets, tokens, dumps, or third-party personal data in any doc or commit message — cite the artifact path instead.
{{PROJECT_RULES}}

## Pointers

- TODO.md — open work; read when picking or landing work.
- docs/SETTLED.md — the record of "no".
- docs/agent/ — activity guides; read the matching file before that work.{{POINTER_EXTRAS}}
- docs/design/DESIGN.md — read before any UI, copy, or design-touching work; the source of truth, assets beside it (R3).
- History and rationale: `git log --grep=<term>` before re-deriving old reasoning.
