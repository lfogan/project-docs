---
name: project-docs
description: Use when starting a new project ("set up project docs", "scaffold project documentation") or retrofitting one onto an existing repo — generates a context-economical doc system via a short interview: CLAUDE.md contract, CHANGELOG.md history, doc-lint, plus PLAN.md state and LEDGER.md decisions in full mode and optional TARGETS/baseline modules.
---

# project-docs — generate the project doc system

Templates live in `templates/` beside this file. Methodology and worked
examples live in `references/methodology.md` (read it only when a design
question comes up). Default CLAUDE.md budget: **45000 bytes**. Treat it as
a ceiling (see references/methodology.md's Budget provenance).

## Step 0 — existing files check (ALWAYS first)

List which of CLAUDE.md, AGENTS.md, PLAN.md, CHANGELOG.md, LEDGER.md,
TARGETS.md, docs/design/STATUS.md, scripts/doc-lint.sh already exist in the
target repo.

- **One or more exist → RETROFIT.** This applies even if only a single file
  is present (e.g. only CHANGELOG.md): any one existing file is enough to
  trigger retrofit mode. Never
  overwrite an existing file without that file's own explicit go-ahead —
  consent is per file, but GATHERED IN BATCHES, never serially: present every
  file needing a decision as one multi-select question (AskUserQuestion with
  multiSelect when available, otherwise a single message listing all of
  them), each file its own independently checkable item. Generate only the
  files that are missing. A file that already exists stays untouched unless
  its owner explicitly approved regenerating it. Then OFFER (never silently
  run) an extraction pass: propose constraints, ledger rows, and stack-table
  entries mined from git log + existing docs — again batched, up to ~10
  proposed items per multi-select question, each item its own checkbox.
  Approval stays per item, without per-item round trips.
- **None exist → greenfield.** Continue to Step 1.

## Step 1 — interview (harvest first, then batch)

**Harvest before asking.** Read the owner's opening request first: any
question whose answer it already contains is not asked again — carry the
harvested answer forward and restate it in the final summary for correction.
Ask only the gaps, batched (AskUserQuestion, up to 4 questions per call,
when available, otherwise one message listing the open questions). Ask
serially only when an answer genuinely gates a later question — Q0's mode
gates Q5, nothing else gates anything.

| # | Ask | Lands in |
|---|---|---|
| 0 | Scale: lite or full? **Default lite.** Recommend full only on real signals: multi-agent dispatch planned, many phases, several contributors, or an external design handoff to freeze. Lite→full is one documented upgrade session (see methodology), so under-choosing is cheap and over-choosing taxes every session. | file set |
| 1 | Product paragraph: what, who, platform, monetization? | `{{PRODUCT_PARAGRAPH}}` |
| 2 | Non-negotiable constraints (shipping blockers, 1–2 fine)? | `{{CONSTRAINTS}}` — numbered lines |
| 3 | Commands & layout: how to build, test, and run, plus where code lives (key directories)? For an existing repo, propose these from inspection and confirm rather than ask cold. | `{{COMMANDS_AND_LAYOUT}}` — one line per command/dir |
| 4 | Tech decisions already locked? (unknowns become `TBD — locked when <trigger>` rows, never guesses) | `{{STACK_ROWS}}` |
| 5 | (full only) Modules: TARGETS matrix? external design handoff to freeze? | which templates instantiate |
| 6 | Evidence standard — what counts as verified here? | `{{EVIDENCE_STANDARD}}` |

- `{{PROJECT_NAME}}` from the repo/product name.
- `{{GOAL_LINE}}` = one-sentence form of the product paragraph.
- `{{BUDGET_CLAUDE}}` = 45000 unless the owner sets another.

`{{PLATFORM_SECTIONS}}`: if Q1's platform is Android, fill with exactly the
block between the BEGIN/END markers (markers excluded. Keep one blank line
on EACH side of the inserted block — one above its `## On-Device QA` heading,
one below its last bullet — so it lands cleanly between the Workbench Notes
comment and `## Maintenance` without gluing to either); any other platform →
empty string. Android is the only v1 snippet — the interview's Q1 is where
the platform gets named, and no other platform has a snippet to fill.

<!-- BEGIN PLATFORM_SECTIONS (Android) -->
## On-Device QA

- Never eyeball tap coordinates from screenshots. Always run `adb shell uiautomator dump /sdcard/ui.xml && adb pull /sdcard/ui.xml` and tap the exact center of the resolved `bounds` rect.
- Account for device density/scaling before issuing `adb shell input tap`.
- Avoid taps within 100px of the nav bar; scroll the target into safe area first.
<!-- END PLATFORM_SECTIONS (Android) -->

`{{LITE_TASKS_SECTION}}` = empty in full mode. In lite mode, the block between
the BEGIN/END markers (markers excluded, blank line above `##` when it lands
in the file):

<!-- BEGIN LITE_TASKS_SECTION -->
## Tasks

<!-- lite mode: task state lives here. Cell rule: ≤200 chars — state + evidence + pointer if a story exists. An in-progress row names its branch + next concrete action. -->

| # | Task | Status |
|---|---|---|
<!-- END LITE_TASKS_SECTION -->


## Step 2 — generate

- Full: CLAUDE.md, AGENTS.md, PLAN.md, CHANGELOG.md, LEDGER.md, chosen
  modules (TARGETS.md; docs/design/STATUS.md from BASELINE-STATUS template —
  `{{BASELINE_PATH}}` = where the handoff was vendored, `{{FREEZE_DATE}}` =
  today), `scripts/doc-lint.sh`, and `docs/templates/bookkeeping-payload.md`
  (verbatim copy of the BOOKKEEPING-PAYLOAD template — no tokens to fill).
- Lite: CLAUDE.md (+Tasks section), AGENTS.md, CHANGELOG.md,
  `scripts/doc-lint.sh`.
- doc-lint.sh: copy from this skill's scripts/, then edit only its
  `BUDGET_CLAUDE=` default line to this project's `{{BUDGET_CLAUDE}}` — the
  script's shipped `BUDGET_CLAUDE` default is NOT the project's contract
  number, and the generated CLAUDE.md header and the lint must never
  disagree. Leave `BUDGET_PLAN=` at the script's shipped default (80000): no
  v1 interview question sets a plan-file budget, the methodology/backtest
  docs give no number for it either, and in lite mode there is no PLAN file
  for it to apply to. Only edit `BUDGET_PLAN=` later if the owner
  deliberately sets one.
- Fill every `{{TOKEN}}`: content tokens from the interview, mode tokens
  from the table below. Unknown stack cells get `TBD — locked when <trigger>`
  AND a Decisions Needed row (full) or a `⚠` task (lite).

### Mode tokens

The CLAUDE/AGENTS/CHANGELOG templates are shared between modes. Every
mode-varying line is a token. Fill each from its mode's value below at
generation time — there is NO post-fill edit pass, and doc-lint's check 2
fails on any token left behind. Multi-line values are filled as whole lines,
exactly as fenced.

- `{{NOT_HERE}}` (CLAUDE header comment)
  - full: `task state (PLAN.md), history (CHANGELOG.md), full decisions (LEDGER.md).`
  - lite: `history (CHANGELOG.md). Task state lives in the ## Tasks section below; decisions live directly in ## Active decisions.`
- `{{READ_ORDER_MODE_BULLETS}}` (CLAUDE read order; full = two bullets)
  - full:
    ```
    - Picking or landing work: PLAN.md.
    - Touching a ledgered area: its LEDGER.md row + cited entries.
    ```
  - lite: `- Picking or landing work: the ## Tasks section below.`
- `{{STATE_ROW}}` (CLAUDE read order, compaction bullet)
  - full: `PLAN.md row` · lite: `## Tasks row`
- `{{GREP_TARGETS}}` (CLAUDE read order, grep bullet)
  - full: `CHANGELOG*.md LEDGER.md` · lite: `CHANGELOG*.md`
- `{{TBD_ESCALATION}}` (CLAUDE Tech Stack comment)
  - full: `a Decisions Needed entry in PLAN.md` · lite: `a ⚠ task in the ## Tasks section`
- `{{ACTIVE_DECISIONS_COMMENT}}` (CLAUDE Active decisions; whole comment block)
  - full:
    ```
    <!-- One line per Active LEDGER.md row, ≤200 chars, format:
         #N: <rule> → CL YYYY-MM-DD (<slug>)
         The LEDGER row wins on any disagreement. Retiring a row deletes its
         line here; the row itself is immortal in LEDGER.md. doc-lint checks
         both directions: every extract needs its row, every Active row its
         extract. -->
    ```
  - lite:
    ```
    <!-- One line per decision, ≤200 chars: #N: <rule> → CL YYYY-MM-DD (<slug>).
         Lite mode has no separate ledger file — this section IS the decision
         record; retiring a decision deletes its line. -->
    ```
- `{{BOOKKEEPING_HOMES}}` (CLAUDE Working Agreements)
  - full: `which ledger row / changelog entry / PLAN row it updates`
  - lite: `which changelog entry it updates`
- `{{BLOCKED_HOME}}` (CLAUDE Working Agreements, statuses line)
  - full: `PLAN.md Decisions Needed` · lite: `the flagged row in ## Tasks`
- `{{STATE_BUDGET_LINE}}` (CLAUDE Maintenance; whole line after the `- `)
  - full: `PLAN.md over budget → close finished phases: one "phase closed" CHANGELOG entry absorbs every piece of evidence living only in its cells, then the phase collapses to a single summary row. Never trim cells to fit.`
  - lite: `## Tasks outgrowing one screen, or a second contributor arriving → upgrade to full mode: split the task table and the decision lines into their own state and ledger files (one session, no data loss — the recipe ships with the project-docs skill), recording the upgrade as a dated CHANGELOG entry.` (worded without naming the not-yet-existing files, so the lite sweep below stays at 0)
- `{{DEVIATION_ACTION}}` (CLAUDE Maintenance)
  - full: `LEDGER.md row + extract here + pointer` · lite: `an Active decisions line + pointer, here`
- `{{PRECEDENCE_ORDER}}` (CLAUDE Maintenance)
  - full: `code > CLAUDE.md > CHANGELOG > PLAN` · lite: `code > CLAUDE.md > CHANGELOG`
- `{{SUBAGENT_PAYLOAD_RULE}}` (CLAUDE Maintenance; rest of the line)
  - full: `subagents return the payload in docs/templates/bookkeeping-payload.md; the dispatcher writes every doc home from it and runs doc-lint before commit.`
  - lite: `subagents return a payload block (slug, entry draft, evidence with numbers pasted from command output); the main session writes CHANGELOG and the ## Tasks row from it and runs doc-lint before commit.`
- `{{DOC_SYSTEM_LINE}}` (AGENTS.md)
  - full: `PLAN.md (task state) · CHANGELOG.md (append-only history) · LEDGER.md (decision register).`
  - lite: `CLAUDE.md's ## Tasks section (task state) · CHANGELOG.md (append-only history).`
- `{{CL_NOT_HERE}}` (CHANGELOG header)
  - full: `rules (CLAUDE.md), task state (PLAN.md), the decision register (LEDGER.md).`
  - lite: `rules (CLAUDE.md). Task state and decisions also live in CLAUDE.md (its ## Tasks and ## Active decisions sections) — this file is history only.`
- `{{CL_EVIDENCE_LINE}}` (CHANGELOG header)
  - full: `Evidence may cite a PLAN cell instead of restating it.`
  - lite: `Evidence goes inline in the entry itself — there is no separate cell to cite in lite mode.`

**Verify after (both modes):** every `{{TOKEN}}` gone (`grep -c '{{'` = 0 per
generated file), and in lite mode additionally `grep -c "PLAN\|LEDGER"` (no
`.md` suffix — bare-word references like "ledger row" or "PLAN cell" count)
= 0 against generated CLAUDE.md, AGENTS.md, and CHANGELOG.md.

## Step 3 — init lint

`scripts/doc-lint.sh` was already copied into the target root and edited with
this project's budget in Step 2 — do not re-derive its checks by hand. Run it
for real: `sh scripts/doc-lint.sh` from the target root.

- **Greenfield: exit 0 is required, unconditionally.** Every file on disk was
  just generated by this run, so any finding is this run's own bug — fix it
  and re-run. Never report a greenfield finding as someone else's problem.
- **Retrofit: exit 0 is required only for files this run generated or
  filled.** A pre-existing file that Step 0 correctly left untouched can
  carry its own pre-existing findings (a hand-written CLAUDE.md missing its
  `## Maintenance` block, or already over budget, are the concrete cases —
  doc-lint.sh has no way to tell "pre-existing" from "just generated," so
  making this distinction is the generator's job). These are
  NEVER silently fixed — that would be exactly the overwrite Step 0 exists
  to prevent. Instead, propose each finding's specific edit as its own item
  in one batched multi-select question (same consent shape as Step 0) and
  let the owner approve or decline per item. A retrofit run's lint MAY
  legitimately exit 1 on pre-existing findings — that is not this run's
  failure, and the job here is to REPORT those findings clearly, never to
  force a clean exit by editing a file Step 0 protected.
- The first run writes `docs/doc-lint-log.csv` (one row per run: date, exit,
  findings, byte sizes, directive count). That file is expected — commit it
  with the doc system. Its trend is the system's only outcome measurement.
- Then check by hand only what the script never checks at all: each
  generated header names what does NOT live in that file.
- **Offer a lint allowlist entry** (offer — never silently edit settings):
  adding `Bash(sh scripts/doc-lint.sh)` to the target's
  `.claude/settings.json` `permissions.allow`. The lint runs once per task,
  and a permission prompt on every run is the friction that kills the habit.
- Report the file list, budget, and lint result to the owner — in retrofit,
  including every proposed pre-existing-file edit still awaiting their
  go-ahead. Suggest committing the doc system as its own commit.
