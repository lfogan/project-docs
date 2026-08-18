---
name: project-docs
description: Use when starting a new project ("set up project docs", "scaffold project documentation") or retrofitting an existing repo — generates the v2 minimal doc system (CLAUDE.md contract ≤6KB/≤25 rules, TODO.md state, docs/SETTLED.md rejection record, owner-gated docs/design/DESIGN.md, hard-failing commit-gate lint) and migrates v1 scaffolds (PLAN/LEDGER/CHANGELOG) to v2.
---

# project-docs v2 — minimal docs, mechanically enforced

Templates in `templates/`, lint in `scripts/doc-lint.sh`, git hooks in
`scripts/hooks/`. Rationale and the v1 post-mortem: `references/methodology.md`
(read only when a design question comes up).

Principles the generated system encodes — do not weaken them while filling:

- **One fact, one home.** Design → docs/design/DESIGN.md · behavior → tests ·
  active task state → TODO.md · finished task rows → DONE.md (verbatim, never
  read wholesale) · rejections → docs/SETTLED.md · stories → commit message
  bodies. Nothing is recorded twice; git is the history. No CHANGELOG, no
  LEDGER, no PLAN — the lint forbids them.
- **Hot files are small because cold files absorb, not because facts vanish.**
  TODO.md carries only [todo]/[partial]/[in-progress]; the moment a row is
  [done] it moves to DONE.md unchanged. Moving is a cut-and-paste, never a
  rewrite — a row that grows a What/Why/Evidence block on the way is a
  changelog being reborn, and the lint rejects it.
- **Enforcement ladder.** deny-hook > test > lint check > CLAUDE.md R-line >
  docs/agent/ note. A prose rule is last-resort debt; healthy rules_count
  trends down.
- **Every check hard-fails at commit.** Advisory checks are banned (v1's only
  warning was ignored 42/42 runs while hard failures were fixed same-day).
- **Hot cap.** CLAUDE.md ≤ 6000 bytes, ≤ 25 R-lines, no @-imports.

## Step 0 — existing files check (ALWAYS first)

Look for: CLAUDE.md, TODO.md, docs/SETTLED.md, AGENTS.md, PLAN.md, LEDGER.md,
CHANGELOG*.md, scripts/doc-lint.sh.

- **v1 files present** (PLAN.md, LEDGER.md, or CHANGELOG*.md) → Retrofit
  (section below).
- **v2 files present** → maintenance. Two jobs, both offer-only — never
  overwrite anything without its own explicit go-ahead, consent gathered in
  ONE batched multi-select (AskUserQuestion, each item its own checkbox):
  1. **Drift check.** The skill evolves after deployment, and a deployed copy
     that lags is silent until a check misbehaves. Detect: byte-diff the
     repo's scripts/doc-lint.sh, .githooks/pre-commit and .githooks/commit-msg
     against this skill's copies (`diff -q`); list v2 files the current skill
     generates that are missing (DONE.md is the common one — older
     deployments predate it); flag doc header comments contradicting current
     templates (a TODO.md header still saying done rows are deleted). Offer
     each finding as its own item. A script/hook refresh is a verbatim
     recopy; a header refresh touches the comment block only, never the
     owner's rows.
  2. **Generate what is missing**, each absent file its own consent item.
- **Nothing** → greenfield, continue.

## Step 1 — interview (harvest first, then one batch)

Read the owner's opening request first; anything it already answers is not
asked again. Ask only the gaps, batched (AskUserQuestion, up to 4 per call).
For an existing repo, PROPOSE answers from inspection (build files, tree,
`gradlew tasks`, package.json) and confirm — never ask cold what the repo
already answers.

| # | Ask | Lands in |
|---|---|---|
| 1 | Product paragraph: what, who, platform, monetization? | `{{PRODUCT_PARAGRAPH}}` |
| 2 | Non-negotiable constraints? Apply the admission test to each — no test or hook can catch it AND a competent agent would violate it by default. Pass → R8+ lines. Testable instead → a TODO row "write <TestName>". | `{{PROJECT_RULES}}` |
| 3 | Build/test/run commands + where code lives? | `{{COMMANDS_AND_LAYOUT}}` |
| 4 | Tech locked? Unknowns = `TBD — locked when <trigger>` row + a Blocked-on-owner TODO row, never a guess. | `{{STACK_ROWS}}` |
| 5 | Evidence standard — what counts as verified here? | `{{EVIDENCE_STANDARD}}` |
| 6 | Design surface? (handoff/mockups to vendor beside DESIGN.md, or seed text, or none) | `{{DESIGN_SEED}}` |
| 7 | First task? | `{{FIRST_TASK}}` |
| 8 | Does shipping involve state outside the repo (app store, signing keys, hosting, domains, accounts)? If yes: what is already set up, and what are the per-release steps? | `{{RELEASE_SETUP}}`, `{{RELEASE_STEPS}}` |
| 9 | Which environments must this be proven against (devices, browsers, OS/runtime versions)? Seed every one named, using `➖` for those never run — the never-run rows are the point. | `{{COVERAGE_ROWS}}` |

`{{PROJECT_NAME}}` comes from the repo/product name — never asked.

`{{POINTER_EXTRAS}}`: one real newline plus one bullet per activity module
generated, in this order; no module → contribute nothing. The token must be
deleted from the line when empty, leaving no gap.

- Android (Q1) → docs/agent/device-qa.md from DEVICE-QA.template.md; bullet:
  `- docs/agent/device-qa.md — read before any adb/device/emulator work; also the record of which environments are proven.`
- Any other project with a real coverage surface (browsers, OS or runtime
  versions, screen sizes) → docs/agent/environments.md from the same
  template, keeping only its `## Environments proven` section; bullet:
  `- docs/agent/environments.md — which environments are proven, and which have never been run.`
- External release state (Q8 answered yes) → docs/agent/release.md from
  RELEASE.template.md; bullet:
  `- docs/agent/release.md — read before any release, store, or deploy work, and add a dated line there after completing setup git cannot show (keys, console state, accounts).`

Caps are fixed defaults: 6000 bytes / 25 rules. If the owner overrides, edit
the copied doc-lint.sh's `BUDGET_CLAUDE=`/`RULES_CAP=` defaults and state the
override in the final report — the CSV logs the cap per run, so a bump is a
visible trend event.

## Step 2 — generate

Always: CLAUDE.md, AGENTS.md, TODO.md, DONE.md, docs/SETTLED.md,
scripts/doc-lint.sh (verbatim copy from this skill's scripts/, then apply any
owner cap override), .githooks/pre-commit and .githooks/commit-msg (verbatim
copies from scripts/hooks/).

If a design surface exists: docs/design/DESIGN.md (assets vendored beside it).
If Android: docs/agent/device-qa.md. If Q8 found external release state:
docs/agent/release.md.

Fill every `{{TOKEN}}` — the lint fails on leftovers. Verify:
`grep -c '{{' <file>` = 0 for each generated file.

## Step 3 — install and verify

1. `git config core.hooksPath .githooks`; on POSIX systems also
   `chmod +x .githooks/pre-commit .githooks/commit-msg` (Git for Windows runs
   them via sh regardless).
2. `sh scripts/doc-lint.sh` from the repo root. **Greenfield: exit 0 is
   required, unconditionally** — every file was just generated by this run,
   so any finding is this run's own bug. Fix and re-run.
3. Offer (never silently apply) an allowlist entry in .claude/settings.json
   `permissions.allow`: `Bash(sh scripts/doc-lint.sh)`.
4. Report the file list and lint result; suggest committing the doc system as
   one commit — **with `[design-approved]` in the message when DESIGN.md or
   design assets are part of it** (creating them counts as a design change;
   the owner is present at setup, so the token is honest). The first run
   creates docs/doc-lint-log.csv — commit it; its trend is the system's only
   outcome measurement.

## Retrofit — v1 → v2 (one session, one `docs-v2` commit)

Consent shape throughout: batched multi-select, each item independently
checkable, ~10 items per question. Deletions are proposed, never silent; git
preserves everything deleted.

1. **Baseline.** Record current sizes (CLAUDE.md, PLAN.md, LEDGER.md,
   CHANGELOG* totals, directive count) in the report — the before-numbers the
   first v2 CSV row is read against.
2. **Commands & Layout.** Derive fresh from inspection and confirm with the
   owner. Do not assume the v1 file has this section — generated v1 files
   have shipped without it.
3. **Rules triage.** From v1 Critical Constraints + Active LEDGER rows,
   classify each: already test-enforced → drop (the test is the record) ·
   testable but untested → TODO row "write <TestName>" · untestable AND
   default-violated → R-line candidate · history/superseded/copy-churn →
   drop. Owner multi-selects R-candidates; 7 seeds + approved ≤ 25.
   Calibration from the pilot repo: 77 active rows → expect 8–12 R-lines.
4. **SETTLED harvest.** Search v1 LEDGER + CHANGELOG for withdrawn findings,
   owner-rejected proposals, "do not re-raise" markers. Propose Don't-lines;
   owner multi-selects. Expect a handful, not dozens.
5. **TODO and DONE.** TODO.md carries active work only: [Todo]/[In-Progress]
   rows, [Partial] → a "verify <x>" row, Decisions Needed → Blocked on owner.
   Every [Done] row moves verbatim into DONE.md — one line each, in the v1
   PLAN's own order, no rewriting or enrichment. A v1 PLAN cell over 300
   chars is trimmed to its task text (the evidence prose stays in git), which
   is the only editing permitted during the move.
   Additionally: done rows recording state OUTSIDE the repo (store console,
   signing keys, accounts, hosting, review submissions) also get a dated line
   in docs/agent/release.md. DONE.md is never read, so an archived row alone
   will not be found when a release session needs it. Scan the v1 PLAN and
   CHANGELOG for these specifically — a release phase is where they hide.
5b. **Coverage.** A v1 TARGETS.md becomes the `## Environments proven` table
   in docs/agent/device-qa.md (or environments.md). Carry every row, and fold
   the old "Coverage gaps" section in as `➖` rows rather than keeping a second
   surface. Dates and results are external-world facts git cannot reconstruct
   — losing them means re-running the tests.
6. **Design.** docs/design/DESIGN.md seeded by the owner or from the handoff;
   existing handoff assets stay beside it under the same gate; v1
   docs/design/STATUS.md and its "historical baseline" doctrine retire with
   the file.
7. **Delete v1 files** (owner-approved batch): PLAN.md, LEDGER.md,
   CHANGELOG*.md, docs/templates/bookkeeping-payload.md,
   docs/design/STATUS.md, scripts/doc-lint-hook.sh, and any Stop-hook entry
   in .claude/settings.json. Keep docs/notes/ if the owner wants the audit
   reports; they are cold.
8. Generate the v2 set (Step 2), install hooks (Step 3), lint → exit 0
   required, commit everything as `docs-v2`.

## Subagents

No payload protocol. AGENTS.md carries the whole rule: subagents report
evidence (commands run + observed output) and never edit CLAUDE.md, TODO.md,
or docs/SETTLED.md — the main session writes those and commits.
