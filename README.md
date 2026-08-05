# project-docs

A Claude Code skill that scaffolds a context-economical documentation system for a software project: a contract file, a task-state file, an append-only history, and a decision register, wired together so they stay small and stop drifting apart.

## Why

Most "AI coding contract" files (CLAUDE.md, AGENTS.md, and similar) start small and grow without bound. Rules pile up next to the stories that explain them, decisions get retold in three places with three slightly different wordings, and eventually the file everyone reads before every task is tens of thousands of bytes of prose. This skill exists to stop that from happening, from day one of a new project.

It grew out of a real, fully shipped Android app whose own contract file reached about 100KB. That project's four-file system (contract, plan, changelog, device matrix) worked, but two problems kept recurring: the always-loaded file kept growing, and the same fact would get written down two or three times with the wording drifting each time. This skill keeps the parts that worked and fixes the two problems structurally.

## Relationship to the superpowers plugin

This skill does not replace [superpowers](https://github.com/obra/superpowers) (brainstorming, writing-plans, subagent-driven-development, and the rest). It is meant to sit alongside it, not instead of it.

superpowers owns the workflow: brainstorming an idea into a spec, turning a spec into an implementation plan, executing that plan task by task with reviews in between. This skill owns a different, narrower thing: the small set of files a project keeps around between sessions to remember its own rules, its own task state, and its own history, so that workflow has somewhere consistent to write down what it decided.

Concretely: a spec produced by superpowers' brainstorming skill is expected to end with a Bookkeeping section, naming which changelog entry, which ledger row, and which plan row the resulting work will update. The generated `CLAUDE.md` states this rule in one line and points at `references/methodology.md` for the full definition. Neither file tells superpowers how to write a spec or a plan. It only tells whoever is about to land the resulting work where the record of that work belongs.

Use both together: superpowers to get from idea to shipped change, project-docs so the trail that change leaves behind stays small, truthful, and in one place per fact.

## What it generates

| File | Purpose | Full mode | Lite mode |
|---|---|---|---|
| `CLAUDE.md` | Rules, constraints, one-line decision extracts, task table in lite mode | Always | Always |
| `AGENTS.md` | Two-line pointer for non-Claude agents to `CLAUDE.md` | Always | Always |
| `CHANGELOG.md` | Dated, append-only history, one entry per decision or change | Always | Always |
| `PLAN.md` | Task tables by phase, an open-decisions list, an owed-verification index | Yes | No, folded into `CLAUDE.md` |
| `LEDGER.md` | The full, numbered decision register | Yes | No, folded into `CLAUDE.md` |
| `TARGETS.md` | Environment, device, or browser matrix, if the project needs one | Opt-in | Not offered |
| `docs/design/STATUS.md` | Guard file for a frozen external design handoff, if one exists | Opt-in | Not offered |
| `scripts/doc-lint.sh` | The dependency-free shell script that checks everything below | Always | Always |

## Full mode versus lite mode

The skill's first question is which one to use, and it matters more than it sounds.

**Full mode** keeps four separate files: `CLAUDE.md` for rules, `PLAN.md` for what is being worked on right now, `CHANGELOG.md` for what already happened, and `LEDGER.md` for the numbered, permanent record of deliberate decisions. This is the shape a project with real staying power wants: `LEDGER.md` in particular can grow to dozens of rows over a project's life without ever touching the byte budget of the file that loads every session, because it lives on its own and only gets summarized into `CLAUDE.md` as short, one-line extracts.

**Lite mode** is one file lighter on each side: no `PLAN.md`, no `LEDGER.md`. Task state moves into a `## Tasks` section directly inside `CLAUDE.md`, and decisions get recorded as short lines in `CLAUDE.md` rather than full ledger rows, pointing straight at their `CHANGELOG.md` entry. This is the right choice for a small or early-stage project where a fourth file would be more overhead than the project has earned yet.

Choosing lite mode is not a one-way door. A project can move to full mode later: the task table moves out to a freshly generated `PLAN.md`, decision lines move out to a freshly generated `LEDGER.md`, and the change gets recorded as its own dated changelog entry, same as any other decision.

The two modes also produce genuinely different text, not just different files. Lite mode's `CLAUDE.md` and `AGENTS.md` are written so that neither one ever mentions a `PLAN.md` or `LEDGER.md` that does not exist. This sounds obvious and was the single hardest thing to get right during development: a template written once for both modes kept leaking references to files the other mode never creates, in places a simple find-and-replace could not catch, because the reference was not the literal filename but a phrase like "a PLAN row" or "the ledger." Getting this genuinely clean took two extra rounds of review specifically hunting for that leak. It is clean now, and it is exactly the kind of thing worth being suspicious of if this project is ever extended with a third mode.

## The core idea

1. **Rules stay inline.** A terse instruction someone needs to see before acting lives in `CLAUDE.md`, one line, forever.
2. **Stories live once.** The reasoning, the history, the "we tried X and it broke" narrative goes in `CHANGELOG.md`, written a single time, on the date it happened.
3. **Everything else points, it does not repeat.** A rule in `CLAUDE.md` that needs its backstory carries a pointer to the changelog entry instead of retelling it: `→ CL 2026-08-01 (some-slug)`, resolved against a real entry whose first line is `- 2026-08-01 some-slug - one line summary`. The format is fixed and grep-able on purpose.
4. **The decision register is its own file.** In full mode, `LEDGER.md` can grow to dozens of numbered, permanent rows without ever touching the budget of the file that loads every session. Rows are never deleted or renumbered, only marked retired.
5. **A budget is a measured number, not a guess.** The default byte budget shipped with this skill was derived by distilling a real, mature project's contract file down to its rules-only residue, then adding headroom. It ships stated as a ceiling, not a target: a fresh project's contract landing anywhere near it on day one is a sign something has gone wrong, not a sign of thoroughness.
6. **A small script checks the invariants.** `doc-lint.sh` has no dependencies beyond a POSIX shell, `grep`, `sed`, and `wc`, and runs in about two seconds. It checks byte budgets, catches unfilled template placeholders, resolves pointers against real changelog entries, flags decision extracts in `CLAUDE.md` that have no matching row in `LEDGER.md`, and fails outright if `CLAUDE.md` itself is missing.
7. **Redaction and rotation are the only allowed edits to history.** `CHANGELOG.md` is append-only. The two exceptions are redacting a secret that should never have been written down, and rotating old entries into a dated archive file once the changelog grows past its own budget. Nothing else ever gets edited in place.

## Using it

Inside a Claude Code session, say something like "set up project docs" or "scaffold project documentation" at the start of a new project, or say it on an existing repo to retrofit the system onto it.

The skill asks six questions, one at a time:

1. Scale: lite or full.
2. A one-paragraph description of the product: what it is, who it is for, the platform, how it makes money if relevant.
3. Non-negotiable constraints, the kind of thing that would block shipping if violated. One or two is a fine answer to start with.
4. Tech decisions already locked in. Anything not yet decided is recorded as an explicit "to be decided" row with a stated trigger for when it gets resolved, never guessed.
5. Full mode only: which optional modules to include, an environment matrix, a frozen external design handoff, both, or neither.
6. What counts as verified evidence on this project: passing tests, a manual device check, a screenshot, whatever fits.

If the target repo already has any of `CLAUDE.md`, `AGENTS.md`, `PLAN.md`, `CHANGELOG.md`, `LEDGER.md`, `TARGETS.md`, the design-handoff guard file, or the lint script, the skill switches into retrofit mode automatically. In retrofit mode it never overwrites an existing file without that specific file's own explicit go-ahead, asked one file at a time, and it can optionally propose constraints, decisions, and tech-stack rows mined from the existing repo's git history and docs for the owner to accept or reject individually.

One special case: if the product description names Android as the platform, the generated `CLAUDE.md` also gets a short "On-Device QA" section with three rules about resolving real tap coordinates from a UI dump rather than a screenshot. It is the only platform-specific block this version ships, added because that exact mistake caused a real, time-wasting false bug report during this skill's own development.

After generation, the skill copies its lint script into the new project and runs it once. In a brand new, greenfield project a clean run is required. In a retrofit, a finding against a file that already existed before this run is reported as a proposed edit for the owner to make themselves, never fixed silently, and does not count as this run's own failure.

## Status

Built and reviewed through a full specify, implement, and review cycle: a written design, an adversarial self-review, an independent multi-persona council review, an eight-task implementation with a fresh review after every task (several went through more than one round of fixes), and a final whole-branch review before merge that independently rebuilt sample projects from scratch to confirm the whole thing actually works end to end. The full paper trail, including the budget measurement and the design rationale, lives in `docs/` and `references/methodology.md`.

## License

MIT. See `LICENSE`.
