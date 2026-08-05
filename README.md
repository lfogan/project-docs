# project-docs

A Claude Code skill that generates a system for project documentation: a rules file (CLAUDE.md), a task list, a changelog, and a decision log. They point at each other instead of repeating each other, and a lint fails when they outgrow their budget.

## The problem

CLAUDE.md files start small and grow without limit. Rules pile up next to the stories that explain them, decisions get written down two or three times with slightly different wording, and the file every session reads before doing anything becomes tens of thousands of bytes of prose. One real, shipped project's contract file reached about 100KB this way.

Size matters here. `CLAUDE.md` is read in full at the start of every session, and again after a long conversation is compacted. A skill costs almost nothing until invoked, but the contract file is always loaded, so every byte in it is paid for on every task in every session, relevant or not.

The cost is not just tokens. A rule competes for attention with whatever surrounds it, so a constraint buried in tens of thousands of bytes of narrative is followed less reliably than the same constraint in a short file.

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

`scripts/doc-lint.sh` checks byte budgets, unfilled template placeholders, broken pointers, and decision extracts with no matching ledger row. It needs nothing beyond a POSIX shell, grep, sed, and wc, and runs in about two seconds.

`CHANGELOG.md` is append-only. The only edits allowed are redacting a secret and rotating old entries into an archive once the file grows past budget.

## The budget

Two files carry a byte budget, because two files are always loaded: `CLAUDE.md` at 45,000 bytes and `PLAN.md` at 80,000. Everything else is read on demand, so it is left unbudgeted and free to grow.

The 45,000 comes out of a measurement. The origin project's contract file was 97,699 bytes. Stripped to rules-only content, with each surviving rule priced at 150 bytes and the narrative moved out to the changelog and ledger, it came to 30,990 bytes. Add 30% headroom, round up to the next 5KB, and the result is 45,000. The soft number in that is the per-rule price. Reprice across the plausible 100 to 200 byte band and the answer moves between 35,000 and 50,000, so 45,000 falls inside the band, one step above its midpoint.

That project was unusually rule-dense: LGPL licence text that cannot legally be compressed, a native build pipeline, and 42 active decisions. So 45,000 is a ceiling, not a target. A fresh project whose `CLAUDE.md` lands near it on day one is already carrying story that belongs somewhere else.

Override it for a project by editing the `BUDGET_CLAUDE` line in the generated `scripts/doc-lint.sh`, or for a single run with an environment variable:

```bash
BUDGET_CLAUDE=30000 sh scripts/doc-lint.sh
```

If your project's shape is very different, run the same distillation against your own contract file and set the budget from your number. The method is in `references/methodology.md`, the full worked measurement in `docs/2026-08-04-budget-backtest.md`.

## Install

Clone into your personal skills directory:

```bash
git clone https://github.com/lfogan/project-docs.git ~/.claude/skills/project-docs
```

Start a new Claude Code session and the skill is available in every project. Update later with `git pull` from that directory.

To scope it to a single project instead, clone into that project's `.claude/skills/` directory.

## Using it

Say "set up project docs" at the start of a project, or on an existing repo to retrofit it, or run `/project-docs` directly. The skill asks six questions: scale (lite or full), a one-paragraph product description, non-negotiable constraints, locked tech decisions, optional modules (full mode only), and what counts as verified evidence on this project.

If any target file already exists, the skill switches to retrofit mode and asks before touching each one, file by file.

Naming Android as the platform adds a short on-device QA section to `CLAUDE.md`, covering how to resolve tap coordinates from a UI dump instead of a screenshot.

After generation, the skill copies `doc-lint.sh` into the project and runs it. A greenfield project must pass clean. In a retrofit, a finding against a file that already existed is reported, not fixed.

## Works without superpowers

This skill is not part of [superpowers](https://github.com/obra/superpowers) and does not require it. superpowers owns the workflow: brainstorming, planning, execution. This skill owns the files a project keeps between sessions.

The two connect at one point: a spec written under superpowers is expected to end with a Bookkeeping section naming which changelog entry, ledger row, or plan row the work updates, and the generated `CLAUDE.md` states that rule. The same rule applies with any other process, or with none.

## License

MIT. See `LICENSE`.
