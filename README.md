# project-docs

A Claude Code skill that generates a documentation system for a project: a rules file (CLAUDE.md), a task list, a changelog, and a decision log. The files point at each other instead of repeating each other, and a lint catches drift.

## The problem

CLAUDE.md files start small and grow without limit. Rules pile up next to the stories that explain them, decisions get written down three times with slightly different wording, and the file every session reads becomes tens of thousands of bytes of prose. One shipped project's contract file hit about 100KB this way.

That file is read in full at the start of every session and again after every compaction, so every byte is paid for on every task, relevant or not. A rule also competes with everything around it for attention: a constraint buried in narrative gets followed less reliably than the same constraint in a short file.

This skill splits the file into pieces, one home per kind of information, so growth in one piece never bloats the one that always loads.

## What it generates

| File | Purpose | Full mode | Lite mode |
|---|---|---|---|
| `CLAUDE.md` | Rules, constraints, one-line decision summaries | Yes | Yes, also holds the task list |
| `AGENTS.md` | Pointer to `CLAUDE.md` for other agents | Yes | Yes |
| `CHANGELOG.md` | Dated, append-only history | Yes | Yes |
| `PLAN.md` | Task tables, open decisions | Yes | No |
| `LEDGER.md` | Full numbered decision log | Yes | No |
| `TARGETS.md` | Environment or device matrix | Optional | Not offered |
| `docs/design/STATUS.md` | Guard for a frozen external design handoff | Optional | Not offered |
| `scripts/doc-lint.sh` | Checks everything above | Yes | Yes |

Lite mode drops `PLAN.md` and `LEDGER.md` and folds task state into `CLAUDE.md`. It's the default; a small project rarely needs more, and upgrading to full later is a single step the skill records as its own changelog entry.

## How it works

Rules stay inline in `CLAUDE.md`, one line each. Stories, meaning the reasoning behind a rule or what broke and why, go in `CHANGELOG.md`, written once. A rule that needs its backstory points at the entry: `→ CL 2026-08-01 (some-slug)`. A rule that would look wrong without its reason keeps a short why inline instead, because nobody follows a pointer before "fixing" something that looks like a mistake.

The contract also carries a Commands & Layout section: how to build, test, and run, and where the code lives. That's what every session needs first, and re-discovering it each time costs more than any amount of pruned narrative ever saves.

In full mode the decision log lives in `LEDGER.md`, so it can grow to dozens of numbered entries without touching the always-loaded budget.

`CHANGELOG.md` is append-only. The only edits allowed are redacting a secret and rotating old entries into an archive.

## The lint

`scripts/doc-lint.sh` fails on: a file over budget, unfilled template placeholders, pointers that resolve to nothing, decision summaries with no ledger row, and active ledger rows with no summary in `CLAUDE.md`. That last one matters most, since it means a live decision no session can see.

It also warns, without failing, when `CLAUDE.md` carries more than 75 directive lines, and appends one line per run to `docs/doc-lint-log.csv` so failure rate and budget headroom show up as a trend. Plain POSIX shell, runs in a couple of seconds.

## The budget

Two files carry a byte budget because two files are always loaded: `CLAUDE.md` at 45,000 bytes and `PLAN.md` at 80,000. Everything else is read on demand and free to grow.

The 45,000 is measured, not guessed. The origin project's contract file was 97,699 bytes; stripped to rules only, it came to 30,990. Add 30% headroom, round up to the next 5KB: 45,000. That project was unusually rule-dense (LGPL licence text, a native build pipeline, 42 active decisions), so treat the number as a ceiling. A fresh project landing near it on day one is already carrying story that belongs somewhere else.

Override it by editing the `BUDGET_CLAUDE` line in the generated script, or for one run:

```bash
BUDGET_CLAUDE=30000 sh scripts/doc-lint.sh
```

The measurement method is in `references/methodology.md` if your project's shape is different enough to warrant its own number.

## Install

Clone into your personal skills directory:

```bash
git clone https://github.com/lfogan/project-docs.git ~/.claude/skills/project-docs
```

Start a new Claude Code session and the skill is available in every project. Update later with `git pull`. To scope it to a single project instead, clone into that project's `.claude/skills/` directory.

## Using it

Say "set up project docs" at the start of a project, on an existing repo to retrofit it, or run `/project-docs` directly. The skill pulls answers from whatever you wrote in your opening message and asks only about the gaps: scale, what the product is, hard constraints, build and test commands, locked tech choices, optional modules, and what counts as evidence.

On an existing repo it never touches a file without asking, and it asks once with a checklist rather than file by file. A finding against a pre-existing file is reported, not fixed.

Naming Android as the platform adds a short on-device QA section to `CLAUDE.md`.

## Works without superpowers

This skill is not part of [superpowers](https://github.com/obra/superpowers) and does not require it. superpowers owns the workflow (brainstorming, planning, execution); this skill owns the files a project keeps between sessions. The one connection point: a spec is expected to end with a Bookkeeping section naming which doc entries the work updates, and the generated `CLAUDE.md` states that rule. It applies under any process, or none.

## License

MIT. See `LICENSE`.
