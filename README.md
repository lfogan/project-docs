# project-docs

A Claude Code skill that scaffolds a documentation system for a project: a rules file, a task list, a changelog, and a decision log, structured so they stay small and don't repeat each other.

## The problem

CLAUDE.md files start small and grow without limit. Rules pile up next to the stories that explain them, decisions get written down two or three times with slightly different wording, and the file every session reads before doing anything becomes tens of thousands of bytes of prose. One real, shipped project's contract file reached about 100KB this way.

This skill splits that single file into pieces, one home per kind of information, so growth in one piece never bloats the file that loads every session.

## What it generates

| File | Purpose | Full mode | Lite mode |
|---|---|---|---|
| `CLAUDE.md` | Rules, constraints, one-line decision summaries | Yes | Yes, also holds the task list |
| `AGENTS.md` | Two-line pointer to `CLAUDE.md` for other agents | Yes | Yes |
| `CHANGELOG.md` | Dated, append-only history | Yes | Yes |
| `PLAN.md` | Task tables, open decisions | Yes | No |
| `LEDGER.md` | Full numbered decision log | Yes | No |
| `TARGETS.md` | Environment or device matrix | Optional | Not offered |
| `docs/design/STATUS.md` | Guard for a frozen external design handoff | Optional | Not offered |
| `scripts/doc-lint.sh` | Checks everything above | Yes | Yes |

Lite mode drops `PLAN.md` and `LEDGER.md` and folds task state into `CLAUDE.md` directly. It suits a small or early project. Moving to full mode later is one step: the skill splits the files back out and logs the move as its own changelog entry.

## How it works

Rules stay inline in `CLAUDE.md`, one line each. Stories, meaning the reasoning behind a rule or what broke and why, go in `CHANGELOG.md`, written once. A rule that needs its backstory points at the changelog entry instead of repeating it: `→ CL 2026-08-01 (some-slug)`.

In full mode the decision log lives in its own file, `LEDGER.md`, so it can grow to dozens of numbered entries without touching the byte budget of the file every session loads.

The default `CLAUDE.md` budget was measured, not guessed: taken from a real, shipped project's contract file, stripped down to its rules-only content, with headroom added. It ships as a ceiling, not a target.

`scripts/doc-lint.sh` checks byte budgets, unfilled template placeholders, broken pointers, and decision extracts with no matching ledger row. It needs nothing beyond a POSIX shell, grep, sed, and wc, and runs in about two seconds.

`CHANGELOG.md` is append-only. The only edits allowed are redacting a secret and rotating old entries into an archive once the file grows past budget.

## Using it

Say "set up project docs" at the start of a project, or on an existing repo to retrofit it. The skill asks six questions: scale (lite or full), a one-paragraph product description, non-negotiable constraints, locked tech decisions, optional modules (full mode only), and what counts as verified evidence on this project.

If any target file already exists, the skill switches to retrofit mode and asks before touching each one, file by file.

Naming Android as the platform adds a short on-device QA section to `CLAUDE.md`, covering how to resolve tap coordinates from a UI dump instead of a screenshot.

After generation, the skill copies `doc-lint.sh` into the project and runs it. A greenfield project must pass clean. In a retrofit, a finding against a file that already existed is reported, not fixed.

## Works without superpowers

This skill is not part of [superpowers](https://github.com/obra/superpowers) and does not require it. superpowers owns the workflow: brainstorming, planning, execution. This skill owns the files a project keeps between sessions.

The two connect at one point: a spec written under superpowers is expected to end with a Bookkeeping section naming which changelog entry, ledger row, or plan row the work updates, and the generated `CLAUDE.md` states that rule. The same rule applies with any other process, or with none.

## License

MIT. See `LICENSE`.
