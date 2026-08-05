# project-docs

A Claude Code skill that scaffolds a context-economical documentation system for a software project: a contract file, a task-state file, an append-only history, and a decision register, wired together so they stay small and stop drifting apart.

## Why

Most "AI coding contract" files (CLAUDE.md, AGENTS.md, and similar) start small and grow without bound. Rules pile up next to the stories that explain them, decisions get retold in three places with three slightly different wordings, and eventually the file everyone reads before every task is tens of thousands of bytes of prose. This skill exists to stop that from happening, from day one of a new project.

It grew out of a real, fully shipped Android app whose own contract file reached about 100KB. That project's four-file system (contract, plan, changelog, device matrix) worked, but two problems kept recurring: the always-loaded file kept growing, and the same fact would get written down two or three times with the wording drifting each time. This skill keeps the parts that worked and fixes the two problems structurally.

## What it generates

| File | Purpose | Always loaded? |
|---|---|---|
| `CLAUDE.md` | Rules, constraints, one-line decision extracts | Yes |
| `AGENTS.md` | Two-line pointer for non-Claude agents | Yes |
| `PLAN.md` | Task state, phases, open decisions | Full mode only |
| `CHANGELOG.md` | Dated, append-only history | Yes |
| `LEDGER.md` | The full decision register, kept out of the always-loaded file on purpose | Full mode only |
| `TARGETS.md` | Optional environment or device matrix | Opt-in |
| `docs/design/STATUS.md` | Optional guard for a frozen external design handoff | Opt-in |
| `scripts/doc-lint.sh` | A small POSIX shell script that checks the invariants below | Yes |

Lite mode drops `PLAN.md` and `LEDGER.md` and folds task state into `CLAUDE.md` directly, for a smaller project that does not need the full separation yet.

## The core idea

1. **Rules stay inline.** A terse instruction someone needs to see before acting lives in `CLAUDE.md`, one line, forever.
2. **Stories live once.** The reasoning, the history, the "we tried X and it broke" narrative goes in `CHANGELOG.md`, written a single time, on the date it happened.
3. **Everything else points, it does not repeat.** A rule in `CLAUDE.md` that needs its backstory carries a pointer to the changelog entry instead of retelling it. The pointer format is fixed and grep-able.
4. **The decision register is its own file.** `LEDGER.md` can grow to dozens of rows without ever touching the budget of the file that loads every session.
5. **A budget is a measured number, not a guess.** The default byte budget shipped with this skill was derived by distilling a real, mature project's contract file down to its rules-only residue, then adding headroom. It is documented as a ceiling, not a target: a fresh project's contract landing anywhere near it on day one is a sign something has gone wrong, not a sign of thoroughness.
6. **A small script checks the invariants.** `doc-lint.sh` has no dependencies beyond a POSIX shell, `grep`, `sed`, and `wc`. It checks byte budgets, catches unfilled template placeholders, resolves pointers against real changelog entries, and flags decision extracts that have no matching row in the register.

## Using it

Inside a Claude Code session, say something like "set up project docs" or "scaffold project documentation" at the start of a new project, or on an existing repo to retrofit the system onto it. The skill asks a short set of questions (project scale, product summary, constraints, locked tech decisions, optional modules, evidence standard) and generates the files from there.

On a retrofit, no existing file is ever overwritten without asking first, file by file.

## Status

Built and reviewed through a full specify, implement, and review cycle: a written design, an adversarial self-review, an independent multi-persona council review, an eight-task implementation with a fresh review after every task, and a final whole-branch review before merge. The full paper trail, including the budget measurement and the design rationale, lives in `docs/` and `references/methodology.md`.

## License

MIT. See `LICENSE`.
