---
name: project-docs
description: Use when starting a new project ("set up project docs", "scaffold project documentation") or retrofitting one onto an existing repo — generates a context-economical doc system (CLAUDE.md contract, PLAN.md state, CHANGELOG.md history, LEDGER.md decisions, optional TARGETS/baseline modules, doc-lint) via a short interview.
---

# project-docs — generate the project doc system

Templates live in `templates/` beside this file; methodology and worked
examples in `references/methodology.md` (read it if a design question comes
up; do not load it otherwise). Default CLAUDE.md budget: **45000 bytes** —
a ceiling, not a target (see references/methodology.md's Budget provenance).

## Step 0 — existing files check (ALWAYS first)

List which of CLAUDE.md, AGENTS.md, PLAN.md, CHANGELOG.md, LEDGER.md,
TARGETS.md, docs/design/STATUS.md, scripts/doc-lint.sh already exist in the
target repo.

- **One or more exist → RETROFIT.** This applies even if only a single file
  is present (e.g. only CHANGELOG.md) — it is not "all of them" or "most of
  them," any one existing file is enough to trigger retrofit mode. Never
  overwrite an existing file without that file's own explicit go-ahead,
  asked per file, not once for the whole batch. Generate only the files that
  are missing; a file that already exists stays untouched unless its owner
  explicitly approves regenerating it. Then OFFER (never silently run) an
  extraction pass: propose constraints, ledger rows, and stack-table entries
  mined from git log + existing docs, owner approving each proposed item
  individually.
- **None exist → greenfield.** Continue to Step 1.

## Step 1 — interview (one question at a time)

| # | Ask | Lands in |
|---|---|---|
| 0 | Scale: lite (solo/small — contract + changelog only) or full? | file set |
| 1 | Product paragraph: what, who, platform, monetization? | `{{PRODUCT_PARAGRAPH}}` |
| 2 | Non-negotiable constraints (shipping blockers; 1–2 fine)? | `{{CONSTRAINTS}}` — numbered lines |
| 3 | Tech decisions already locked? (unknowns become `TBD — locked when <trigger>` rows, never guesses) | `{{STACK_ROWS}}` |
| 4 | (full only) Modules: TARGETS matrix? external design handoff to freeze? | which templates instantiate |
| 5 | Evidence standard — what counts as verified here? | `{{EVIDENCE_STANDARD}}` |

`{{PROJECT_NAME}}` from the repo/product name; `{{GOAL_LINE}}` = one-sentence
form of the product paragraph; `{{BUDGET_CLAUDE}}` = 45000 unless the owner
sets another.

`{{PLATFORM_SECTIONS}}`: if Q1's platform is Android, fill with exactly the
block between the BEGIN/END markers (markers excluded; keep one blank line
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

`{{LITE_TASKS_SECTION}}` = empty in full mode; in lite mode, the block between
the BEGIN/END markers (markers excluded, blank line above `##` when it lands
in the file):

<!-- BEGIN LITE_TASKS_SECTION -->
## Tasks

<!-- lite mode: task state lives here. Cell rule: ≤200 chars — state + evidence + pointer if a story exists. -->

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
- Fill every `{{TOKEN}}`. Unknown stack cells get `TBD — locked when <trigger>`
  AND a Decisions Needed row (full) or a `⚠` task (lite).
- **Lite-mode-only post-fill pass.** The CLAUDE and AGENTS templates are
  shared between both modes and their static prose (not tokens — plain text
  that survives unconditionally) names PLAN.md/LEDGER.md, neither of which
  lite mode creates. After filling tokens, when mode is lite, apply these
  exact edits to the generated files (verified against the actual committed
  template text — quote-checked, not paraphrased):
  - In generated CLAUDE.md:
    - Top comment: `NOT here: task state (PLAN.md), history (CHANGELOG.md), full decisions (LEDGER.md).` → `NOT here: history (CHANGELOG.md). Task state lives in the ## Tasks section below; decisions live directly in ## Active decisions.`
    - Read order: `Picking or landing work: PLAN.md.` → `Picking or landing work: the ## Tasks section below.` (below, not above — the Tasks section lands at the end of the file, after Read order)
    - Read order: delete the bullet `Touching a ledgered area: its LEDGER.md row + cited entries.` entirely — lite mode's decisions live in this same file (the `## Active decisions` section below), already covered by the "Always: this file" bullet.
    - Read order: `` `rg "<slug>" CHANGELOG*.md LEDGER.md` `` → `` `rg "<slug>" CHANGELOG*.md` ``
    - Tech Stack comment: `+ a Decisions Needed entry in PLAN.md.` → `+ a ⚠ task in the ## Tasks section.`
    - Active decisions comment (the whole `<!-- One line per Active LEDGER.md row ... -->` block) → `<!-- One line per decision, ≤200 chars: #N: <rule> → CL YYYY-MM-DD (<slug>). Lite mode has no separate ledger file — this section IS the decision record; retiring a decision deletes its line. -->`
    - Working Agreements: `blocked on an owner decision (PLAN.md Decisions Needed)` → `blocked on an owner decision (see the flagged row in ## Tasks)`
    - Working Agreements: `A spec without a Bookkeeping section (which ledger row / changelog entry / PLAN row it updates) is incomplete — add it before implementing.` → `A spec without a Bookkeeping section (which changelog entry it updates) is incomplete — add it before implementing.` (lite mode has no LEDGER.md and no separate PLAN row; a lite Bookkeeping obligation is CHANGELOG only)
    - Maintenance: `Deviating from an approved design/copy: LEDGER.md row + extract here + pointer. Never silent.` → `Deviating from an approved design/copy: an Active decisions line + pointer, here. Never silent.`
    - Maintenance: `subagents return the payload in docs/templates/bookkeeping-payload.md; the dispatcher writes every doc home from it and runs doc-lint before commit.` → `subagents return a payload block (slug, entry draft, evidence with numbers pasted from command output); the main session writes CHANGELOG and the ## Tasks row from it and runs doc-lint before commit.` (lite mode generates no `docs/templates/` file — the payload contract lives in this line alone)
    - Maintenance: `Precedence when files disagree: code > CLAUDE.md > CHANGELOG > PLAN.` → `Precedence when files disagree: code > CLAUDE.md > CHANGELOG.` (no separate plan file exists in lite mode to rank)
  - In generated AGENTS.md:
    - `Doc system: PLAN.md (task state) · CHANGELOG.md (append-only history) · LEDGER.md (decision register).` → `Doc system: CLAUDE.md's ## Tasks section (task state) · CHANGELOG.md (append-only history).`
  - In generated CHANGELOG.md (same defect class, found during verification of
    this fix — not one of the two files above, but CHANGELOG.md is also
    generated in lite mode and its template has the identical problem):
    - `Append-only dated history, newest first. NOT here: rules (CLAUDE.md), task state (PLAN.md), the decision register (LEDGER.md).` → `Append-only dated history, newest first. NOT here: rules (CLAUDE.md). Task state and decisions also live in CLAUDE.md (its ## Tasks and ## Active decisions sections) — this file is history only.`
    - `Evidence may cite a PLAN cell instead of restating it.` → `Evidence goes inline in the entry itself — there is no separate cell to cite in lite mode.`
  - Verify after — and this is the REAL acceptance bar, not the narrower one
    used earlier: run `grep -c "PLAN\|LEDGER"` (no `.md` suffix required) —
    NOT `grep -c "PLAN\.md\|LEDGER\.md"`, which misses bare-word references
    like "ledger row", "PLAN row", or "PLAN cell" — against all three
    generated files. Expect 0 in every one.

## Step 3 — init lint

`scripts/doc-lint.sh` was already copied into the target root and edited with
this project's budget in Step 2 — do not re-derive its checks by hand. Run it
for real: `sh scripts/doc-lint.sh` from the target root.

- **Greenfield: exit 0 is required, unconditionally.** Every file on disk was
  just generated by this run, so any finding is this run's own bug — fix it
  and re-run; never report a greenfield finding as someone else's problem.
- **Retrofit: exit 0 is required only for files this run generated or
  filled.** A pre-existing file that Step 0 correctly left untouched can
  carry its own pre-existing findings (a hand-written CLAUDE.md missing its
  `## Maintenance` block, or already over budget, are the concrete cases —
  doc-lint.sh has no way to tell "pre-existing" from "just generated," so
  this distinction is the generator's job, not the script's). These are
  NEVER silently fixed — that would be exactly the overwrite Step 0 exists
  to prevent. Instead, for each finding against a pre-existing file, propose
  the specific edit as its own per-file suggestion and let the owner approve
  or decline it, the same as Step 0's extraction-pass offer. A retrofit
  run's lint MAY legitimately exit 1 on pre-existing findings — that is not
  this run's failure, and the job here is to REPORT those findings clearly,
  never to force a clean exit by editing a file Step 0 protected.
- doc-lint.sh's unfilled-token check (its check 2) only scans `CLAUDE.md
  PLAN.md CHANGELOG.md LEDGER.md TARGETS.md AGENTS.md` — it does NOT see
  `docs/design/STATUS.md`, so a stray `{{TOKEN}}` left in that file lints
  clean. When that module was generated, add it to the by-hand check below.
- Then check by hand only what the script never checks at all: each
  generated header names what does NOT live in that file, and — per the
  point above — `docs/design/STATUS.md` for any surviving `{{TOKEN}}`.
- Report the file list, budget, and lint result to the owner — in retrofit,
  including every proposed pre-existing-file edit still awaiting their
  go-ahead. Suggest committing the doc system as its own commit.
