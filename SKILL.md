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
TARGETS.md, scripts/doc-lint.sh already exist in the target repo.

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
above `##` when it lands in the file); any other platform → empty string.
Android is the only v1 snippet — the interview's Q1 is where the platform
gets named, and no other platform has a snippet to fill.

<!-- BEGIN PLATFORM_SECTIONS (Android) -->
## On-Device QA

- Never eyeball tap coordinates from screenshots. Always run `adb shell uiautomator dump /sdcard/ui.xml && adb pull /sdcard/ui.xml` and tap the exact center of the resolved `bounds` rect.
- Account for device density/scaling before issuing `adb shell input tap`.
- Avoid taps within 100px of the nav bar; scroll the target into safe area first.
<!-- END PLATFORM_SECTIONS (Android) -->

`{{LITE_TASKS_SECTION}}` = empty in full mode; in lite mode, the block between
the BEGIN/END markers (markers excluded, blank line above `##`):

<!-- BEGIN LITE_TASKS_SECTION -->
## Tasks

<!-- lite mode: task state lives here. Cell rules = PLAN template's. -->

| # | Task | Status |
|---|---|---|
<!-- END LITE_TASKS_SECTION -->


## Step 2 — generate

- Full: CLAUDE.md, AGENTS.md, PLAN.md, CHANGELOG.md, LEDGER.md, chosen
  modules (TARGETS.md; docs/design/STATUS.md from BASELINE-STATUS template —
  `{{BASELINE_PATH}}` = where the handoff was vendored, `{{FREEZE_DATE}}` =
  today), `scripts/doc-lint.sh`.
- Lite: CLAUDE.md (+Tasks section), AGENTS.md, CHANGELOG.md,
  `scripts/doc-lint.sh`.
- doc-lint.sh: copy from this skill's scripts/, then edit its two default
  lines (`BUDGET_CLAUDE=`, `BUDGET_PLAN=`) to this project's budgets — the
  script's shipped defaults are NOT the project's contract numbers, and the
  generated CLAUDE.md header and the lint must never disagree.
- Fill every `{{TOKEN}}`. Unknown stack cells get `TBD — locked when <trigger>`
  AND a Decisions Needed row (full) or a `⚠` task (lite).

## Step 3 — init lint

`scripts/doc-lint.sh` was already copied into the target root and edited with
this project's budgets in Step 2 — do not re-derive its checks by hand. Run
it for real: `sh scripts/doc-lint.sh` from the target root (exit 0 required —
any `{{TOKEN}}` or missing maintenance block fails). Then check by hand only
what the script does NOT check: each generated header names what does NOT
live in that file — the script has no check for this. Report the file list,
budget, and lint result to the owner. Suggest committing the doc system as its
own commit.
