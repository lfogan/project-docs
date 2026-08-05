# project-docs skill — design

**Date:** 2026-08-04
**Status:** approved (owner, 2026-08-04); **revision 2** — first revised after an internal adversarial pass (15 findings, S1–S4/M5–M15), then after an external council review (octo council, 5 personas, unanimous REVISE; findings tagged C# inline; owner decisions 2026-08-04: ledger → own file, minimal lint script allowed, all YAGNI cuts applied). Amended 2026-08-04 (owner): platform-snippet mechanism added — see Init interview.
**Origin:** the origin project's four-file doc system (CLAUDE.md / PLAN.md / CHANGELOG.md / DEVICES.md + specs/plans/handovers) proved itself across a full app build, but two structural pain points emerged and the conventions that made it work were invented mid-project. This skill packages the system — improved — as a reusable starting point for future Claude-driven projects. The origin project itself is explicitly out of scope: its files are never written to. Reading them (for the budget backtest) is allowed.

## Goals

1. **Context economy — targeted at the always-loaded file.** The origin project's CLAUDE.md reached 97 KB and loads every session; that is the context tax. CHANGELOG loads only on demand (S1) — its bulk is handled by rotation, not caps. The system keeps CLAUDE.md small **by structure**: stories live elsewhere, unbounded structures live in on-demand files (C1), and a minimal lint mechanizes the checks whose silent failure would corrupt the scheme (C11 — this revises the earlier "behavioral only" stance, which contradicted this goal).
2. **No duplication/drift.** The same fact was retold in a ledger row, a changelog entry, and a plan status cell, with wording drifting between them. The system makes retelling structurally unnecessary.
3. **Day-1 rules.** Conventions the origin project adopted late (changelog immutability, entry format, status vocabulary, precedence between files) are baked into the templates from the first commit (C8).

## Non-goals

- Replacing the superpowers brainstorming/writing-plans flows (see Integration).
- Retrofitting the origin project.
- Platform-specific content in the core (device matrices, store gates are optional modules).
- Heavy enforcement infrastructure. One ~20-line dependency-free lint script ships (C11); hooks and CI do not. Anything beyond the script stays behavioral, and that residual limitation is accepted.

## Skill anatomy

Personal Claude Code skill at `~/.claude/skills/project-docs/`:

```
project-docs/
├── SKILL.md                        # trigger + init interview + generation instructions (lean)
├── templates/
│   ├── CLAUDE.template.md          # contract skeleton: read-order block, maintenance block,
│   │                               #   active-rule ledger extracts, budget header
│   ├── LEDGER.template.md          # full decision ledger, own file, on-demand (C1)
│   ├── PLAN.template.md            # phase tables, Decisions Needed, owed-verification index
│   ├── CHANGELOG.template.md       # header rules + archive index + entry skeleton
│   ├── TARGETS.template.md         # optional module: evidence matrix
│   └── BASELINE-STATUS.template.md # optional module: frozen-handoff guard
├── scripts/
│   └── doc-lint.sh                 # ~20 lines, dependency-free; copied into target project (C11)
├── references/
│   └── methodology.md              # rationale, worked examples, spec-section definitions (C15)
└── docs/
    └── 2026-08-04-project-docs-skill-design.md   # this file
```

Cut from v1 (C15): `HANDOVER.template.md` (a fourth home for state — violates rule 1; PLAN + CHANGELOG + context summarization cover it; re-add if a project asks) and `spec-sections.template.md` (duplicated the CLAUDE.md line that is the actual runtime authority; its content is now a section of `methodology.md`).

**SKILL.md is a generator, not a runtime authority (S2).** A session doing feature work in a target project will never trigger this skill, and a cloned repo must work on a machine without `~/.claude`. Every rule the target project needs day-to-day lives in the generated files themselves. SKILL.md holds only the interview, fill-in logic, and init lint instructions.

## Produced doc system (in a target project)

| File | Tier | Role | Generated |
|---|---|---|---|
| CLAUDE.md | contract (always loaded) | rules, constraints, active-rule ledger extracts, read order, maintenance block | always |
| AGENTS.md | shim | 3-line stub pointing at CLAUDE.md, for non-Claude agents (C-security) | always |
| LEDGER.md | decisions (on-demand) | full numbered ledger rows, immortal numbers (C1) | full mode |
| PLAN.md | state | task tables, statuses, Decisions Needed, owed-verification index | full mode |
| CHANGELOG.md + `CHANGELOG-archive-<range>.md` | history | dated append-only narrative + dated archives (C3) | always |
| scripts/doc-lint.sh | enforcement | size/placeholder/pointer checks (C11) | always |
| docs/notes/ + docs/notes/README.md | overflow | pruned detail + long reports; README is a one-line-per-note index; notes are pointer-reachable only, never read by default (C-code-reviewer 11) | dir on first use |
| TARGETS.md | evidence matrix | environments proven against; summarizes, never home — "home row wins" (C-code-reviewer 4, rule 6) | module |
| docs/design/STATUS.md | baseline guard | frozen external handoff + "shipped app wins" rules | module |
| specs / implementation plans | per-workstream | via superpowers flows | no |

**Lite mode (C15):** small projects get CLAUDE.md (with an inline task-table section replacing PLAN.md) + CHANGELOG.md + AGENTS.md + lint. Upgrade to full = one ask: the task table extracts to PLAN.md, ledger extracts to LEDGER.md. Chosen by interview Q0.

## The rules

### Kept from the origin project (proven), now day-1

1. **One home per fact.** Contract = rules. LEDGER = decisions. PLAN = state. CHANGELOG = narrative. TARGETS = summary of evidence whose home is elsewhere. Every file's header names what does NOT live in it.
2. **Append-only history, two sanctioned mutations only (C9, C-code-reviewer 7).** CHANGELOG entries are immutable. The only permitted in-place edits are: (a) **redaction** of secrets/PII/legal content — replace with `[redacted YYYY-MM-DD: reason]` plus a new dated entry recording the redaction; if the content was ever pushed, rotate the credential — git history keeps it; (b) **rotation** moves (rule 11). Each is its own commit, content-preserving, diff-provable. Never paste credentials, tokens, keys, dumps, or third-party personal data into any doc — cite the artifact instead.
3. **Ledger rows immortal, in LEDGER.md (C1).** Rows are numbered, never deleted or renumbered; numbers are never reused. LEDGER.md is on-demand, so retired rows cost zero context. For each **Active** row, CLAUDE.md carries a one-line extracted rule + pointer (`#42: portrait-bottom margin 25% → CL 2026-07-19 (caption-margins)`); retiring the row removes the extract.
4. **Status vocabularies.** Tasks: `[Todo] [In-Progress] [Done] [Partial] [N/A]`, plus `⚠` = blocked on an owner decision (listed in Decisions Needed). Ledger: `Active / Active·amended <date> / Active·superseded <date> / Active·resolved <date> / Retired <date>`. `[Partial]` with the gap named beats a fake `[Done]`.
5. **Evidence inline, one home, first-hand (M9, C-security 5).** A `[Done]` cell carries its one-line evidence (commit, test count, device) and is that evidence's home; CHANGELOG cites the row, never restates. Evidence names what was run and observed. **A claim sourced from a subagent report is `unverified` until re-run first-hand, and unverified ⇒ `[Partial]`** — the origin project's own workbench notes record subagent reports being stale or fabricated.
6. **Index subordination.** Every index/summary surface (owed-verification table, TARGETS.md, CLAUDE.md's ledger extracts) explicitly declares "the home row wins."
7. **Promotion path.** Incident → CHANGELOG entry → recurs or universal → contract Workbench Note (terse rule + pointer; story stays in CHANGELOG).

### The context-economy layer

8. **Rule vs story (S4) — with teeth.** Rules = terse imperatives an agent must see before acting; they stay inline. Stories = how/why/history; they live once, in CHANGELOG (or a note), pointed to. Applies to every CLAUDE.md section. **Every rule whose story has been pruned carries a pointer — a pruned rule with no pointer is a lint finding (C-strategy 2):** a bare rule with no reachable why gets reversed by a later session, the exact failure the origin project's design-baseline rules exist to prevent. **Staleness duty (C-code-reviewer 8):** when touching an area, verify the inline rules naming its files/symbols still hold; a falsified rule is corrected + changelog-entried in the same commit.
9. **Budgets in bytes, backtested (C2, C10).** CLAUDE.md's default cap is **set by measurement, not aspiration**: implementation includes a read-only backtest distilling the origin project's real 97 KB CLAUDE.md through rule 8 and measuring the residue; the default ships as that number (working assumption ~15–35 KB until measured). Sub-budgets in characters, not "lines" (a line is unbounded): ledger extract ≤ ~200 chars, PLAN cell ≤ ~200 chars, LEDGER row ≤ ~600 chars. CHANGELOG is uncapped (S1) — skeleton + rotation, not truncation. **Raise ratchet (C-security 9):** a budget raise must state what was pruned first, and cumulative raises are listed beside the budget in CLAUDE.md's header so drift is visible.
10. **Pointer discipline, anchored and shallow.** A story is written once; everything else cites `→ CL 2026-07-13 (watermark)`. **Anchor is guaranteed by the entry format (C4):** every entry begins `- YYYY-MM-DD <kebab-slug> — summary.`, slug unique within its date. **Retrieval is grep, not reading (C-research 5):** the generated CLAUDE.md states the command — `rg "<slug>" CHANGELOG*.md LEDGER.md`. **Depth 1 (C-agy):** pointers point at stories; stories do not chain onward pointers.
11. **Rotation that survives year two (C3).** CHANGELOG > ~50 KB → oldest entries move to a date-ranged archive (`CHANGELOG-archive-2026-H1.md`), cut on entry boundaries only, never mid-entry. CHANGELOG's header keeps a two-line archive index (range → file). Rotation is its own commit and content-preserving. PLAN phase collapse only after a "phase closed" entry absorbs every piece of evidence living only in its cells (M5).
12. **Same-commit bookkeeping.** A landed change updates all its doc homes in that commit, driven by the spec's Bookkeeping section. Guard at the spec, not after the commit (C-code-reviewer 10): CLAUDE.md states **"a spec without a Bookkeeping section is incomplete — add it before implementing."**
13. **Concurrency (C6).** CHANGELOG merge conflicts: keep both sides, re-sort by date, never drop an entry. Subagents do not write the shared docs directly — they return results; the main session reconciles and appends.

### Named trade-offs (accepted)

- Pointer discipline means reading the cited entry when working in that area; rule 8 keeps warnings inline so the cost applies to stories only.
- Enforcement beyond `doc-lint.sh` is behavioral. The script covers the three checks whose silent failure corrupts the system (budgets, placeholders, pointer resolution); the rest degrades gracefully.
- CLAUDE.md is an instruction surface (C-security 6): repo-write access changes agent behavior for every future session. Mitigation is procedural — contract changes get code-level review care; unreviewed external text is never pasted into CLAUDE.md or `docs/notes/`. CODEOWNERS is suggested in methodology.md for multi-writer repos, not generated by default.

## Init interview

Triggered by "set up project docs" at greenfield start. **Retrofit (M6, C-research 8):** the skill lists which target files already exist and refuses to overwrite any without explicit per-file go-ahead; generates missing files only. It then **offers** (never silently runs) an extraction pass: propose constraints, ledger rows, and stack entries from git log + existing docs, owner approving each — "backfills nothing" by default was judged an adoption-killer.

Questions, one at a time, answers landing in named locations (M13):

| # | Question | Lands in |
|---|---|---|
| 0 | Scale — lite or full? (C15; lite = CLAUDE+CHANGELOG only, see above) | file set |
| 1 | Product paragraph — what, who, platform, monetization | CLAUDE.md header |
| 2 | Non-negotiable constraints (1–2 is fine, grows later) | CLAUDE.md Critical Constraints |
| 3 | Locked tech decisions so far | CLAUDE.md stack table |
| 4 | Modules — TARGETS? design baseline to freeze? release gates? (full mode only) | which templates instantiate |
| 5 | Evidence standard — what counts as verified | CLAUDE.md Working Agreements |

**Blanks are typed (C12):** `{{FILL}}` tokens must not survive init (lint fails on them); deliberate unknowns are written `TBD — locked when <trigger>` and each spawns a Decisions Needed entry. Locking a dependency later fills its row + a dated changelog entry, same commit (C-research 10). PLAN.md Phase 0 generates as an empty table + one example row (M7); PLAN includes Decisions Needed and a self-describing Layout line (M8).

Generated CLAUDE.md opens with a 4-line **read-order block (C5):** always this file; PLAN when picking or landing work; LEDGER when touching a ledgered area; CHANGELOG/archives only via pointer or grep, never wholesale.

**Platform snippets (owner amendment 2026-08-04):** when Q1 names a platform with a known snippet, SKILL.md appends that platform's standing QA rules to the generated CLAUDE.md (template token `{{PLATFORM_SECTIONS}}`, empty for platforms without one). v1 ships one snippet: Android **On-Device QA** (owner-supplied verbatim: uiautomator-bounds tap resolution, density/scaling before `input tap`, nav-bar safe area) — mirrored from the origin project's same-day CLAUDE.md addition.

## Maintenance behavior — carried by the generated CLAUDE.md (S2)

- Landing work → same-commit bookkeeping (rule 12).
- Writing a spec → include Origin, Changes, Named consequences, Deferred, **Bookkeeping** (the exact ledger row / changelog entry / PLAN row updates). This line is how the requirement reaches superpowers flows, which read project context.
- Editing CLAUDE.md → run `scripts/doc-lint.sh`; over budget = prune stories first (to CHANGELOG or docs/notes/), same commit, own dated entry.
- Editing CHANGELOG → rotation check (rule 11).
- Deviating from an approved design/copy → LEDGER row + CLAUDE.md extract + pointer, never silent.
- Touching an area → staleness check on its inline rules (rule 8).
- Precedence when files disagree (C8): **code > CLAUDE.md > CHANGELOG > PLAN**; a discovered mismatch becomes a correction entry, never a silent doc edit.

## doc-lint.sh (C11)

~20 lines, dependency-free (sh + grep/wc; `rg` optional), copied into the target project, run by checklist not hook:

1. CLAUDE.md (and PLAN.md, full mode) within stated byte budgets;
2. no `{{FILL}}` tokens anywhere;
3. every `→ CL <date> (<slug>)` pointer resolves to a real target: an entry line `- <date> <slug>` in CHANGELOG*.md, or a docs/notes/ file whose name or heading carries the slug. LEDGER.md is NOT a resolution target — pointer text inside ledger rows would self-resolve dead pointers (a pointer *to* a ledger row is `#N`, not `→ CL`);
4. every CLAUDE.md ledger extract's row number exists in LEDGER.md;
5. maintenance block present.

Init lint = the same script plus "headers state their non-homes" (checklist-only). Pointer checks are vacuous at init and meaningful forever after (M12).

## Integration with superpowers

Specs and implementation plans remain superpowers' job. The required spec sections reach those flows through the generated CLAUDE.md's one-liner (the runtime authority); `references/methodology.md` holds the fuller definitions for generation time (C15). Bookkeeping is what makes rule 12 executable; the "spec without Bookkeeping is incomplete" guard catches the failure at spec time.

## Bookkeeping (for this design itself)

- Next step: superpowers:writing-plans → implementation plan. Plan task 0 = the budget backtest (read-only distillation of the origin project's CLAUDE.md, sets the shipping default for rule 9).
- Acceptance for v1 (C-strategy e): generates clean on two dummy projects (one lite, one full), lint green on both, plus the backtest number recorded in methodology.md.
- Origin project's repo: read for the backtest, never written.
