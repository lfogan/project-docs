# FixtureApp

Tiny fixture project for the v2 doc-lint test harness.

## Commands & Layout

- build: `make build`
- test: `make test`
- code: `src/`

## Stack

| Layer | Choice |
|---|---|
| Language | POSIX sh |

## Rules

<!-- fixture rules — grammar R<n>: <imperative> — <one-clause why> -->
R1: Evidence = commands run + output observed.
R2: A subagent claim is unverified until re-run first-hand — unverified means Partial, never done.
R3: Never edit docs/design/** — propose a diff and stop; landing needs [design-approved] in the commit message.
R4: Never bypass the pre-commit hook (--no-verify) or edit .githooks/.
R5: Grep docs/SETTLED.md before raising an audit finding or re-proposing a change.
R6: Artifacts are the record — write a SETTLED line only on an owner "no".
R7: No secrets in any doc or commit message.

## Pointers

- TODO.md — open work.
- docs/SETTLED.md — the record of "no".
- docs/agent/ — activity guides.
- docs/design/DESIGN.md — design truth.
