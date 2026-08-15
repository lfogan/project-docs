# project-docs

A Claude Code skill that generates a documentation system for a project: rules (CLAUDE.md), tasks, history, and decisions, each in its own file, plus optional modules for an environment matrix and a frozen design handoff. Each fact lives in one file and the others point at it. A lint script catches drift.

## The problem

CLAUDE.md files start small and grow without limit. Rules pile up next to the reasoning that explains them, decisions get written down three times with slightly different wording, and the file every session reads becomes tens of thousands of bytes of prose. One shipped project's CLAUDE.md hit about 100KB this way.

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

Lite mode drops `PLAN.md` and `LEDGER.md` and folds task state into `CLAUDE.md`. It's the default. A small project rarely needs more, and upgrading to full later is a single step the skill records as its own changelog entry.

## Section by section

**`CLAUDE.md`** - always loaded, so every section here is paid for on every task.

| Section | Holds |
|---|---|
| Title + product paragraph | What the project is, in a few lines |
| Read order | Which file to read when, and when to re-read after compaction |
| Critical Constraints | Shipping blockers, one terse line each |
| Commands & Layout | Build, test, run, and where the code lives |
| Tech Stack (locked) | Table of Layer / Choice / Notes, with `TBD - locked when …` for open ones |
| Active decisions | One ≤200-char line per active ledger row, each pointing at its changelog entry |
| Working Agreements | Evidence standard, status vocabulary, the spec Bookkeeping rule |
| Workbench Notes | Recurring gotchas promoted out of the changelog |
| On-Device QA | Android only: `uiautomator` tap rules, density, nav-bar safe area |
| Maintenance | How to edit each doc, budget rules, precedence, secrets handling |
| Tasks | Lite mode only: the task table that full mode puts in `PLAN.md` |

**`PLAN.md`** - task state only, full mode.

| Section | Holds |
|---|---|
| Goal | One line: what this plan delivers |
| Legend | `[Todo] [In-Progress] [Done] [Partial] [N/A]` and `⚠` for owner-blocked |
| Phase *N* - *name* | Table of # / Task / Status, one per phase |
| Decisions Needed | Table of Decision / Trigger / Blocking, one row per `⚠` and per TBD stack row |

**`CHANGELOG.md`** - append-only history.

| Section | Holds |
|---|---|
| Header | Entry format, slug rule, immutability rule, permitted edits |
| Archive index | Which date ranges have been rotated out, and to which file |
| Entries | Newest first: `- YYYY-MM-DD slug - summary. What: … Why: … Evidence: … Limits: …` |

**`LEDGER.md`** - decision register, full mode.

| Section | Holds |
|---|---|
| Header | Row rules: immortal, never renumbered, ≤600 chars, wins on disagreement |
| Status key | Active / Active·amended / ·superseded / ·resolved / Retired, each dated |
| Register | Table of # / Status / Decision / Why / Story |

**`TARGETS.md`** - environment matrix, optional.

| Section | Holds |
|---|---|
| Header | Evidence standard, and that the PLAN cell or changelog entry wins on disagreement |
| Status key | ✅ pass · ⚠️ pass with open bug · ❌ blocked/fail · ➖ never ran |
| Matrix | Table of Target / Version / Tested / Result / Notes |
| Coverage gaps | What is not proven, dated |

**`AGENTS.md`** - three lines: read `CLAUDE.md` first, what the doc system is, and that subagents report rather than write docs.

**`docs/design/STATUS.md`** - optional guard on a frozen design handoff: the freeze date, and three rules - the shipped product wins, never restore toward the handoff, changes need the owner's prior approval.

## How it works

Rules stay inline in `CLAUDE.md`, one line each. The reasoning for any rule, or why something broke, is written once in `CHANGELOG.md`. A rule that needs its reasoning points at the entry: `→ CL 2026-08-01 (some-slug)`. A rule that looks like a mistake without its reason keeps a short explanation inline, since a later session may "correct" an odd-looking rule without checking the changelog first.

Commands & Layout survives the pruning even though it's long. Every session needs it first, and re-discovering it each time costs more than the space it takes.

In full mode the decision log lives in `LEDGER.md`, so it can grow to dozens of numbered entries without touching the always-loaded budget.

## The lint

`scripts/doc-lint.sh` fails on: a file over budget, unfilled template placeholders, pointers that resolve to nothing, decision summaries with no ledger row, and active ledger rows with no summary in `CLAUDE.md`. That last one means a live decision no session can see.

It also warns, without failing, when `CLAUDE.md` carries more than 75 directive lines, and appends one line per run to `docs/doc-lint-log.csv` so failure rate and budget headroom show up as a trend. Plain POSIX shell, runs in a couple of seconds.

## The budget

Two files carry a byte budget because two files are always loaded: `CLAUDE.md` at 45,000 bytes and `PLAN.md` at 80,000. Everything else is read on demand and free to grow.

The 45,000 is derived from a measurement. The origin project's CLAUDE.md was 97,699 bytes. Stripped to rules only, it came to 30,990. Add 30% headroom, round up to the next 5KB: 45,000. That project was unusually rule-dense (LGPL licence text, a native build pipeline, 42 active decisions), so treat the number as a ceiling. A fresh project landing near it on day one is already carrying reasoning that belongs in the changelog.

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

On an existing repo it never touches a file without asking, and it asks once with a checklist rather than file by file. The skill reports findings against pre-existing files and never fixes them.

Naming Android as the platform adds a short on-device QA section to `CLAUDE.md`.

## Works without superpowers

This skill is not part of [superpowers](https://github.com/obra/superpowers) and does not require it. superpowers owns the workflow (brainstorming, planning, execution). This skill owns the files a project keeps between sessions. They connect at one point: a spec is expected to end with a Bookkeeping section naming which doc entries the work updates, and the generated `CLAUDE.md` states that rule. It applies under any process, or none.

## License

MIT. See `LICENSE`.
