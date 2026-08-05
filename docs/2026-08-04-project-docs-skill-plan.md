# project-docs Skill Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the `project-docs` personal Claude Code skill: an init interview that generates a context-economical project documentation system (CLAUDE.md / PLAN.md / CHANGELOG.md / LEDGER.md + modules + lint), per spec `docs/2026-08-04-project-docs-skill-design.md` (revision 2).

**Architecture:** Pure content project — one SKILL.md generator, six markdown templates with `{{TOKEN}}` fill-ins, one dependency-free POSIX lint script (TDD'd against fixture projects), one methodology reference. No build system. Verification = sh test runner + two dummy-project acceptance generations.

**Tech Stack:** Markdown, POSIX sh (Git Bash compatible), grep/wc/sed only (no jq, no rg dependency — rg optional).

## Global Constraints

- Working directory for ALL tasks: `~/.claude/skills/project-docs/` (Windows: `C:\Users\lucas\.claude\skills\project-docs\`). The origin project's repo is READ-ONLY (Task 1 reads its CLAUDE.md; nothing ever writes there).
- `{{TOKEN}}` is the template placeholder syntax; lint must fail on any surviving `{{...}}` in generated files.
- CHANGELOG entry format (exact): `- YYYY-MM-DD <kebab-slug> — <summary>.` — slug kebab-case, unique within its date.
- Pointer format (exact): `→ CL YYYY-MM-DD (<slug>)`.
- Ledger extract format in CLAUDE.md (exact): `#N: <rule> → CL YYYY-MM-DD (<slug>)` (≤200 chars).
- Sub-budgets: ledger extract ≤200 chars; PLAN cell ≤200 chars; LEDGER row ≤600 chars. CLAUDE.md byte budget = Task 1's measured number (referenced below as `{{BUDGET_CLAUDE}}`; Task 1 records the concrete value).
- Status vocabularies (exact): tasks `[Todo] [In-Progress] [Done] [Partial] [N/A]` + `⚠`; ledger `Active / Active·amended <date> / Active·superseded <date> / Active·resolved <date> / Retired <date>`.
- Commit after every task. First task initializes git in the skill dir (owner offered versioning earlier; if the owner declines at execution time, skip the commit steps only — never skip verification steps).
- Spec cut list is binding: NO HANDOVER template, NO spec-sections template (its content lives in `references/methodology.md`).

---

### Task 1: Git init + budget backtest (read-only measurement)

**Files:**
- Create: `.gitignore`, `docs/2026-08-04-budget-backtest.md`
- Read only: the origin project's own `CLAUDE.md` (path known to the operator running this backtest)

**Interfaces:**
- Produces: the measured default byte budget `{{BUDGET_CLAUDE}}` (a concrete integer, e.g. `28000`), recorded in `docs/2026-08-04-budget-backtest.md` under heading `## Result`. Tasks 2, 3, 7, and 8 consume this number.

- [ ] **Step 1: Init repo**

```bash
cd ~/.claude/skills/project-docs && git init -b main
printf 'tests/tmp/\n' > .gitignore
git add .gitignore docs/ && git commit -m "chore: init project-docs skill repo with design spec + plan"
```

- [ ] **Step 2: Measure the origin project's CLAUDE.md per section**

Read the origin project's own `CLAUDE.md` section by section (`## ` headings). For each section record: (a) current bytes, (b) estimated rules-only residue after applying spec rule 8 — count every terse imperative the section would keep inline (1 line ≈ 100–200 bytes each) plus table skeletons; everything narrative (histories, verification stories, amendment sagas, "why we rejected X" prose) counts as pruned. For the Deviation Ledger specifically: residue = (count of Active rows) × 200 bytes (the extract cap), since full rows move to LEDGER.md.

- [ ] **Step 3: Write the backtest doc**

`docs/2026-08-04-budget-backtest.md`, exactly this structure:

```markdown
# Budget backtest — origin project CLAUDE.md distillation (read-only)

Method: spec rev-2 rule 8 applied on paper to every section of the origin
project's real CLAUDE.md (97 KB, 2026-08-04 state). Rules stay inline; stories priced as
pruned to CHANGELOG/LEDGER/notes. Ledger priced at 200 bytes per Active row.

## Per-section table

| Section | Bytes now | Rules residue (est.) | Notes |
|---|---|---|---|
| (one row per ## section) | | | |

## Result

Measured residue: <sum> bytes.
Shipping default {{BUDGET_CLAUDE}} = <residue × 1.3, THEN rounded UP to the next 5 KB> bytes.
```

Fill every row and both Result numbers from Step 2's measurements. No estimates left as ranges — single integers.

- [ ] **Step 4: Sanity-check the result**

Run: `grep -c "^| " docs/2026-08-04-budget-backtest.md`
Expected: row count ≥ 12 — that is 10+ data rows (the origin project has 10+ `##` sections) PLUS the table's header and separator rows, which `^| ` also matches. Fewer means sections were skipped — go back.
Also verify `## Result` contains two concrete integers (no `<`/`>` brackets remain): `grep -E "[0-9]{4,}" docs/2026-08-04-budget-backtest.md | head -3` shows numbers.

- [ ] **Step 5: Commit**

```bash
git add docs/2026-08-04-budget-backtest.md && git commit -m "feat: budget backtest — measured CLAUDE.md rules residue, shipping default set"
```

---

### Task 2: doc-lint.sh (TDD against fixture projects)

**Files:**
- Create: `scripts/doc-lint.sh`, `tests/run-tests.sh`, `tests/fixtures/good-project/{CLAUDE.md,CHANGELOG.md,LEDGER.md,PLAN.md}`, `tests/fixtures/bad-project/{CLAUDE.md,CHANGELOG.md,LEDGER.md,PLAN.md}`

**Interfaces:**
- Consumes: `{{BUDGET_CLAUDE}}` concept from Task 1 (script takes budgets as env vars with generated-in defaults).
- Produces: `scripts/doc-lint.sh` — run from a target project root; env overrides `BUDGET_CLAUDE`, `BUDGET_PLAN` (bytes); exit 0 clean, exit 1 with one `doc-lint: <finding>` line per finding on stdout. Checks: (1) CLAUDE.md/PLAN.md byte budgets, (2) surviving `{{...}}` tokens, (3) every `→ CL <date> (<slug>)` pointer resolves to a REAL target — an entry line `- <date> <slug>` in CHANGELOG*.md, or a docs/notes/ file whose NAME or `# ` HEADING carries the slug; LEDGER.md is deliberately not a resolution target (pointer text inside its rows would self-resolve dead pointers), (4) every CLAUDE.md extract `#N:` has a `| N |` row in LEDGER.md, (5) `## Maintenance` present in CLAUDE.md.

- [ ] **Step 1: Write the failing test harness + fixtures**

`tests/run-tests.sh`:

```sh
#!/bin/sh
# Test harness for doc-lint.sh. Run from the skill root: sh tests/run-tests.sh
fails=0
assert() { # $1 desc, $2 expected-exit, $3 actual-exit, $4 output, $5 must-contain (empty = skip)
  if [ "$2" != "$3" ]; then echo "FAIL: $1 (exit $3, wanted $2)"; fails=$((fails+1)); return; fi
  if [ -n "$5" ] && ! printf '%s' "$4" | grep -q "$5"; then
    echo "FAIL: $1 (output missing: $5)"; fails=$((fails+1)); return; fi
  echo "ok: $1"
}

out=$(cd tests/fixtures/good-project && BUDGET_CLAUDE=5000 BUDGET_PLAN=5000 sh ../../../scripts/doc-lint.sh); rc=$?
assert "good project passes" 0 "$rc" "$out" ""

out=$(cd tests/fixtures/bad-project && BUDGET_CLAUDE=300 BUDGET_PLAN=5000 sh ../../../scripts/doc-lint.sh); rc=$?
assert "bad project fails" 1 "$rc" "$out" ""
assert "finds over-budget"      1 "$rc" "$out" "over budget"
assert "finds unfilled token"   1 "$rc" "$out" "unfilled"
assert "finds dead pointer"     1 "$rc" "$out" "unresolved pointer"
assert "finds circular pointer" 1 "$rc" "$out" "ledger-only-slug"
assert "finds orphan extract"   1 "$rc" "$out" "extract #9"
assert "finds no maintenance"   1 "$rc" "$out" "maintenance block"

[ "$fails" -eq 0 ] && echo "ALL PASS" || echo "$fails FAILURES"
exit "$fails"
```

`tests/fixtures/good-project/CLAUDE.md`:

```markdown
# Good — Behavioral Contract

A tiny fixture project.

## Active decisions
#1: pill buttons only → CL 2026-08-01 (pill-buttons)

## Maintenance
- Run scripts/doc-lint.sh on edit.
```

`tests/fixtures/good-project/CHANGELOG.md`:

```markdown
# CHANGELOG — Good

---

- 2026-08-01 pill-buttons — All CTAs are pills. What: decided shape. Why: brand. Evidence: n/a. Limits: none.
```

`tests/fixtures/good-project/LEDGER.md`:

```markdown
# LEDGER — Good

| # | Status | Decision | Why | Story |
|---|---|---|---|---|
| 1 | Active | Pill buttons only | brand | → CL 2026-08-01 (pill-buttons) |
```

`tests/fixtures/good-project/PLAN.md`:

```markdown
# Plan — Good

| # | Task | Status |
|---|---|---|
| 0.1 | exists | [Done] — fixture |
```

`tests/fixtures/bad-project/CLAUDE.md` (violations: over 300-byte test budget via the filler paragraph, an unfilled token, a dead pointer, an orphan extract, no `## Maintenance`):

```markdown
# Bad — Behavioral Contract

{{PRODUCT_PARAGRAPH}}

Filler to exceed the tiny test budget: Lorem ipsum dolor sit amet, consectetur
adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna
aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris
nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit.

## Active decisions
#9: ghost rule → CL 2026-01-01 (never-written)
```

`tests/fixtures/bad-project/CHANGELOG.md`:

```markdown
# CHANGELOG — Bad

---
```

`tests/fixtures/bad-project/LEDGER.md` (the row's pointer is dead — its slug exists ONLY inside this ledger row's own pointer text; the old circular-resolution bug would have let it self-resolve, the fixed check must flag it):

```markdown
# LEDGER — Bad

| # | Status | Decision | Why | Story |
|---|---|---|---|---|
| 2 | Active | orphan decision | testing | → CL 2026-02-02 (ledger-only-slug) |
```

`tests/fixtures/bad-project/PLAN.md`:

```markdown
# Plan — Bad
```

- [ ] **Step 2: Run harness to verify it fails**

Run: `sh tests/run-tests.sh`
Expected: FAIL lines — doc-lint.sh does not exist yet, so `sh` exits **127** ("can't open"), which fails every assert including the exit-1 expectations (127 ≠ 1). All red is the correct RED state; do not "fix" the 127 by expecting it.

- [ ] **Step 3: Write doc-lint.sh**

```sh
#!/bin/sh
# doc-lint.sh — project-docs system lint. Run from the target project root.
# Env: BUDGET_CLAUDE, BUDGET_PLAN (bytes). Exit 0 clean; exit 1 with findings.
BUDGET_CLAUDE="${BUDGET_CLAUDE:-35000}"
BUDGET_PLAN="${BUDGET_PLAN:-80000}"
fail=0
note() { echo "doc-lint: $1"; fail=1; }

# 1. byte budgets (always-loaded files only)
for f_b in "CLAUDE.md $BUDGET_CLAUDE" "PLAN.md $BUDGET_PLAN"; do
  f=${f_b% *}; b=${f_b#* }
  if [ -f "$f" ]; then
    sz=$(wc -c < "$f" | tr -d ' ')
    [ "$sz" -gt "$b" ] && note "$f over budget ($sz > $b bytes)"
  fi
done

# 2. unfilled template tokens
for f in CLAUDE.md PLAN.md CHANGELOG.md LEDGER.md TARGETS.md AGENTS.md; do
  [ -f "$f" ] && grep -n "{{[A-Za-z_]*}}" "$f" >/dev/null 2>&1 && note "unfilled token in $f: $(grep -o '{{[A-Za-z_]*}}' "$f" | head -1)"
done

# 3. pointers resolve to a REAL target: "→ CL YYYY-MM-DD (slug)" needs an entry
#    line "- YYYY-MM-DD slug" in CHANGELOG*.md, or a docs/notes/ file whose
#    name or "# " heading carries the slug. LEDGER.md is NOT a target: pointer
#    text inside its rows would self-resolve dead pointers.
for f in CLAUDE.md PLAN.md LEDGER.md TARGETS.md; do
  [ -f "$f" ] || continue
  grep -o "→ CL [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9] ([a-z0-9-]*)" "$f" 2>/dev/null |
  while IFS= read -r p; do
    d=$(printf '%s' "$p" | sed 's/→ CL \([0-9-]*\) .*/\1/')
    s=$(printf '%s' "$p" | sed 's/.*(\(.*\))/\1/')
    if ! grep -q -- "- $d $s" CHANGELOG*.md 2>/dev/null \
       && ! { ls docs/notes 2>/dev/null | grep -q -- "$s"; } \
       && ! grep -q -- "^# .*$s" docs/notes/*.md 2>/dev/null; then
      echo "doc-lint: unresolved pointer in $f: $p"
    fi
  done | sort -u | { any=0; while IFS= read -r l; do echo "$l"; any=1; done; [ "$any" -eq 1 ] && exit 9; exit 0; } || fail=1
done

# 4. every CLAUDE.md extract "#N:" has a LEDGER.md row "| N |"
if [ -f CLAUDE.md ] && [ -f LEDGER.md ]; then
  grep -o "^#[0-9]*:" CLAUDE.md 2>/dev/null | tr -d '#:' | while IFS= read -r n; do
    grep -q "^| $n |" LEDGER.md || echo "doc-lint: extract #$n has no LEDGER.md row"
  done | { any=0; while IFS= read -r l; do echo "$l"; any=1; done; [ "$any" -eq 1 ] && exit 9; exit 0; } || fail=1
fi

# 5. maintenance block present
[ -f CLAUDE.md ] && ! grep -q "^## Maintenance" CLAUDE.md && note "maintenance block missing from CLAUDE.md"

exit "$fail"
```

(The `| { any=0; ... exit 9; } || fail=1` shape exists because the `while` bodies run in pipeline subshells — a bare `fail=1` inside them would be lost. The subshell signals via exit code instead.)

- [ ] **Step 4: Run harness to verify it passes**

Run: `sh tests/run-tests.sh`
Expected: `ALL PASS`, exit 0. If "bad project" assertions fail, check the fixture actually triggers each finding (budget 300 must be under the fixture's byte count — verify `wc -c tests/fixtures/bad-project/CLAUDE.md` > 300).

- [ ] **Step 5: Commit**

```bash
git add scripts/ tests/ && git commit -m "feat: doc-lint.sh with fixture-project test harness (5 checks, TDD)"
```

---

### Task 3: CLAUDE.template.md + AGENTS.template.md

**Files:**
- Create: `templates/CLAUDE.template.md`, `templates/AGENTS.template.md`

**Interfaces:**
- Consumes: `{{BUDGET_CLAUDE}}` (Task 1's integer, baked at generation by SKILL.md — the template keeps the token).
- Produces: templates whose tokens are exactly: `{{PROJECT_NAME}}`, `{{PRODUCT_PARAGRAPH}}`, `{{BUDGET_CLAUDE}}`, `{{CONSTRAINTS}}`, `{{STACK_ROWS}}`, `{{EVIDENCE_STANDARD}}`, `{{PLATFORM_SECTIONS}}` (platform QA snippet or empty — see Task 7), `{{LITE_TASKS_SECTION}}` (empty string in full mode; a `## Tasks` table in lite mode). Task 7's SKILL.md fills these; Task 8 verifies none survive.

- [ ] **Step 1: Write templates/CLAUDE.template.md**

````markdown
# {{PROJECT_NAME}} — Behavioral Contract

{{PRODUCT_PARAGRAPH}}

<!-- Always-loaded contract. Budget {{BUDGET_CLAUDE}} bytes (raises: none — a raise
     must state what was pruned first and be listed here). Rules live here, one
     line each; stories live once in CHANGELOG.md and are pointed to. NOT here:
     task state (PLAN.md), history (CHANGELOG.md), full decisions (LEDGER.md). -->

## Read order

- Always: this file.
- Picking or landing work: PLAN.md.
- Touching a ledgered area: its LEDGER.md row + cited entries.
- CHANGELOG/archives: only via pointer or grep — `rg "<slug>" CHANGELOG*.md LEDGER.md` (plain `grep -rn` if rg is unavailable) — never wholesale.

## Critical Constraints

<!-- Shipping blockers. Terse imperative, one line each. A constraint whose
     story has been pruned MUST carry a pointer of the form
     → CL YYYY-MM-DD (<slug>) -->
{{CONSTRAINTS}}

## Tech Stack (locked)

| Layer | Choice | Notes |
|---|---|---|
{{STACK_ROWS}}
<!-- Unknown = "TBD — locked when <trigger>" + a Decisions Needed entry in PLAN.md.
     Locking a row later = fill it + dated CHANGELOG entry, same commit. -->

## Active decisions

<!-- One line per Active LEDGER.md row, ≤200 chars, format:
     #N: <rule> → CL YYYY-MM-DD (<slug>)
     The LEDGER row wins on any disagreement. Retiring a row deletes its line
     here; the row itself is immortal in LEDGER.md. -->

## Working Agreements

- Evidence standard: {{EVIDENCE_STANDARD}}
- Evidence names what was run and observed. A claim sourced from a subagent report is unverified until re-run first-hand; unverified ⇒ [Partial], never [Done].
- A spec without a Bookkeeping section (which ledger row / changelog entry / PLAN row it updates) is incomplete — add it before implementing.
- Statuses: [Todo] [In-Progress] [Done] [Partial] [N/A]; ⚠ = blocked on an owner decision (PLAN.md Decisions Needed). [Partial] with the gap named beats a fake [Done].

## Workbench Notes

<!-- Recurring gotchas promoted from CHANGELOG entries: terse rule + pointer.
     Promote only what applies to every future session. -->
{{PLATFORM_SECTIONS}}
## Maintenance

- Landing work: update every doc home in the same commit, per the spec's Bookkeeping list. Never "docs later".
- Editing this file: run `scripts/doc-lint.sh`. Over budget → prune stories to CHANGELOG or docs/notes/ first, same commit, own dated entry. Never squeeze rules.
- Editing CHANGELOG: entries are immutable; append only. Over ~50 KB → rotate oldest entries (entry boundaries only) to `CHANGELOG-archive-<range>.md`, own commit, content-preserving, update the archive index in its header.
- Deviating from an approved design/copy: LEDGER.md row + extract here + pointer. Never silent.
- Touching an area: verify the inline rules naming its files/symbols still hold. A falsified rule is corrected + changelog-entried in the same commit.
- Precedence when files disagree: code > CLAUDE.md > CHANGELOG > PLAN. A mismatch becomes a correction entry, never a silent doc edit.
- CHANGELOG merge conflicts: keep both sides, re-sort by date, never drop an entry. Subagents never write the shared docs directly; the main session reconciles.
- Secrets: never paste credentials, tokens, keys, dumps, or third-party personal data into any doc — cite the artifact instead. Redaction is the only permitted in-place edit: replace with `[redacted YYYY-MM-DD: reason]` + a new dated entry recording it. If it was pushed, rotate the credential — git history keeps it.
{{LITE_TASKS_SECTION}}
````

- [ ] **Step 2: Write templates/AGENTS.template.md**

```markdown
# {{PROJECT_NAME}} — agent entry point

Read CLAUDE.md before any work — it is the project contract and doc-system authority.
Doc system: PLAN.md (task state) · CHANGELOG.md (append-only history) · LEDGER.md (decision register).
```

- [ ] **Step 3: Verify token inventory**

Run: `grep -oh "{{[A-Za-z_]*}}" templates/CLAUDE.template.md templates/AGENTS.template.md | sort -u`
Expected exactly: `{{BUDGET_CLAUDE}}`, `{{CONSTRAINTS}}`, `{{EVIDENCE_STANDARD}}`, `{{LITE_TASKS_SECTION}}`, `{{PLATFORM_SECTIONS}}`, `{{PRODUCT_PARAGRAPH}}`, `{{PROJECT_NAME}}`, `{{STACK_ROWS}}` — nothing else.

- [ ] **Step 4: Commit**

```bash
git add templates/ && git commit -m "feat: CLAUDE + AGENTS templates (read order, maintenance block, extracts section)"
```

---

### Task 4: CHANGELOG.template.md + LEDGER.template.md

**Files:**
- Create: `templates/CHANGELOG.template.md`, `templates/LEDGER.template.md`

**Interfaces:**
- Produces: templates with the single token `{{PROJECT_NAME}}`. Entry/pointer/row formats must match Task 2's lint regexes exactly (`- YYYY-MM-DD <slug> —`, `→ CL YYYY-MM-DD (<slug>)`, `| N |`).

- [ ] **Step 1: Write templates/CHANGELOG.template.md**

```markdown
# CHANGELOG — {{PROJECT_NAME}}

Append-only dated history, newest first. NOT here: rules (CLAUDE.md), task
state (PLAN.md), the decision register (LEDGER.md).

Entry format: `- YYYY-MM-DD <kebab-slug> — <one-line summary>. What: … Why: … Evidence: … Limits: …`
Slug kebab-case, unique within its date. Length as the story needs — no cap.
Evidence may cite a PLAN cell instead of restating it.

Entries are immutable from entry #1. Supersede with a new entry citing the old
`date (slug)`. The only permitted in-place edits: redaction
(`[redacted YYYY-MM-DD: reason]` + a new entry recording it; rotate any pushed
credential) and rotation moves (own commit, content-preserving, entry
boundaries only).

Archives (range → file): none yet.

---
```

- [ ] **Step 2: Write templates/LEDGER.template.md**

```markdown
# LEDGER — {{PROJECT_NAME}} decision register

Numbered register of deliberate decisions and deviations. Rows are immortal:
never deleted, never renumbered, numbers never reused. Row ≤ ~600 chars —
decision + why + pointer(s); the story lives in CHANGELOG. Every Active row
has a ≤200-char extract in CLAUDE.md ("Active decisions"); this file wins on
any disagreement. NOT here: stories (CHANGELOG), task state (PLAN.md).

Status: Active / Active·amended <date> / Active·superseded <date> /
Active·resolved <date> / Retired <date>. Amendments append pointers, they do
not rewrite the row's decision text.

| # | Status | Decision | Why | Story |
|---|---|---|---|---|
```

- [ ] **Step 3: Verify formats against the lint**

`mkdir -p tests/tmp/fmt` (tests/tmp/ is gitignored and may not exist), copy both templates in as `CHANGELOG.md`/`LEDGER.md` with `{{PROJECT_NAME}}` → `X` (`sed 's/{{PROJECT_NAME}}/X/'`), add a minimal `CLAUDE.md` containing `## Maintenance` + one extract `#1: rule → CL 2026-08-04 (seed)`, a LEDGER row `| 1 | Active | rule | why | → CL 2026-08-04 (seed) |` appended to the table, and a CHANGELOG entry `- 2026-08-04 seed — seeded. What: n/a Why: n/a Evidence: n/a Limits: n/a`.
Run: `cd tests/tmp/fmt && sh ../../../scripts/doc-lint.sh`
Expected: exit 0 (formats round-trip through the lint). Delete `tests/tmp/fmt` after.

- [ ] **Step 4: Commit**

```bash
git add templates/ && git commit -m "feat: CHANGELOG + LEDGER templates (entry format, immutability + redaction rules, register table)"
```

---

### Task 5: PLAN.template.md + TARGETS.template.md + BASELINE-STATUS.template.md

**Files:**
- Create: `templates/PLAN.template.md`, `templates/TARGETS.template.md`, `templates/BASELINE-STATUS.template.md`

**Interfaces:**
- Produces: PLAN template tokens `{{PROJECT_NAME}}`, `{{GOAL_LINE}}`; TARGETS token `{{PROJECT_NAME}}`, `{{EVIDENCE_STANDARD}}`; BASELINE-STATUS tokens `{{PROJECT_NAME}}`, `{{BASELINE_PATH}}`, `{{FREEZE_DATE}}`.

- [ ] **Step 1: Write templates/PLAN.template.md**

```markdown
# {{PROJECT_NAME}} — Implementation Plan

> Update the Status column as work lands: [Todo] → [In-Progress] → [Done] (+ one-line
> evidence). This file is task STATE only — narrative history lives in CHANGELOG.md.

**Goal:** {{GOAL_LINE}}

**Legend:** [Todo] · [In-Progress] · [Done] verified · [Partial] gap named in row · [N/A] de-scoped · ⚠ = blocked on an owner decision (see Decisions Needed)

**Layout:** numbered phases → Owed Verification (index — home rows win) → Decisions Needed.

<!-- Status cell ≤ ~200 chars: state + one-line evidence + pointer if a story
     exists. Evidence from a subagent report is unverified ⇒ [Partial] until
     re-run first-hand. A fully verified phase may collapse to one summary row
     ONLY after a "phase closed" CHANGELOG entry absorbs every piece of
     evidence living only in its cells. -->

## Phase 0 — Scaffolding

| # | Task | Status |
|---|---|---|
| 0.1 | (example row — replace) Repo init + doc system committed | [Todo] |

## Owed Verification (gate)

Index, not a home. If a row here disagrees with its home row, the home row wins.

| # | Owed | Home | Blocked on |
|---|---|---|---|

## Decisions Needed

<!-- Every ⚠ task and every "TBD — locked when <trigger>" stack row gets an entry. -->

| Decision | Trigger | Blocking |
|---|---|---|
```

- [ ] **Step 2: Write templates/TARGETS.template.md**

```markdown
# TARGETS — {{PROJECT_NAME}} tested environments

Living matrix of every environment/device/browser this project is PROVEN
against vs. unverified. Summary surface only — the home of any evidence is its
PLAN cell (or phase-closed CHANGELOG entry); if a row here disagrees with its
home, the home wins. Update on every environment test; keep detail where it
already lives.

Evidence standard: {{EVIDENCE_STANDARD}}

Status: ✅ pass · ⚠️ pass with open bug · ❌ blocked/fail · ➖ never ran

| Target | Version/spec | Tested | Result | Notes (one line + pointer) |
|---|---|---|---|---|

## Coverage gaps

<!-- What is NOT proven, dated. An empty gaps section is a claim — keep it honest. -->
```

- [ ] **Step 3: Write templates/BASELINE-STATUS.template.md**

```markdown
# Design baseline — STATUS: historical, NOT the current spec

**Read this before using anything in this folder.**

The files here ({{BASELINE_PATH}}) are the original external design handoff,
vendored verbatim on {{FREEZE_DATE}}. They were the source of truth at project
start. They are not the source of truth now.

1. **The shipped product wins** wherever it differs from these files —
   documented or not. An undocumented difference is far more likely to be
   deliberate polish nobody recorded than a bug.
2. **Never restore the product toward this handoff.** Absence of a recorded
   reason is not evidence of a mistake.
3. **All changes to shipped design/copy require the owner's explicit prior
   approval.** "The handoff says otherwise" is never sufficient authority.

Still useful for: original intent on unreworked areas, and as the diff
baseline LEDGER.md rows were written against. These files stay verbatim —
editing them would invalidate that baseline, which is why this warning is a
sibling file and not a banner inside them.
```

- [ ] **Step 4: Verify token inventory**

Run: `grep -oh "{{[A-Za-z_]*}}" templates/PLAN.template.md templates/TARGETS.template.md templates/BASELINE-STATUS.template.md | sort -u`
Expected exactly: `{{BASELINE_PATH}}`, `{{EVIDENCE_STANDARD}}`, `{{FREEZE_DATE}}`, `{{GOAL_LINE}}`, `{{PROJECT_NAME}}`.

- [ ] **Step 5: Commit**

```bash
git add templates/ && git commit -m "feat: PLAN, TARGETS, BASELINE-STATUS templates"
```

---

### Task 6: references/methodology.md

**Files:**
- Create: `references/methodology.md`

**Interfaces:**
- Consumes: Task 1's backtest number (cited with its doc path).
- Produces: the on-demand reference SKILL.md points to. Must contain sections: `## Why this shape`, `## Rule vs story — worked example`, `## Spec sections` (the definitions formerly destined for spec-sections.template.md), `## Lite → full upgrade`, `## Multi-writer repos`, `## Budget provenance`.

- [ ] **Step 1: Write references/methodology.md**

```markdown
# project-docs methodology — rationale and worked examples

Loaded on demand only. The generated files are the runtime authority; this
explains why they are shaped that way, for generation time and for humans.

## Why this shape

Origin: a full Android app build (2026), run agentically. Its
four-file system worked but its always-loaded contract grew to 97 KB because
stories (histories, amendment sagas, verification narratives) lived inline
beside the rules, and the same story was retold in a ledger row, a changelog
entry, and a plan cell. This skill keeps the proven separation and adds the
context-economy layer: rules inline, stories written once and pointed to,
unbounded structures (ledger, history) in on-demand files, budgets measured
not aspired to, and a 5-check lint for the failures that corrupt silently.
Full derivation: the design spec in ../docs/, revision 2 (internal adversarial
pass + 5-persona council review, both applied).

## Rule vs story — worked example

Ledger row as the origin project wrote it (condensed): several hundred words
on watermark copy, approval dates, review findings, a fix narrative. As this
system writes it:

- LEDGER.md row: `| 28 | Active·amended 2026-07-16 | Free-tier burned video carries a small text watermark naming the app, ~25% transparency, bottom-right | sell polish, not capability; free clips advertise the app | → CL 2026-07-13 (watermark-free-tier), → CL 2026-07-16 (watermark-text-shortened) |`
- CLAUDE.md extract: `#28: free-tier burns carry a watermark naming the app → CL 2026-07-13 (watermark-free-tier)`
- The several hundred words: two CHANGELOG entries, written once, grep-reachable.

## Spec sections

Every spec written in a project using this system includes:

- **Origin** — what prompted this, one paragraph.
- **Changes** — numbered, each independently reviewable.
- **Named consequences** — real effects flagged for the owner, not judged.
- **Deferred** — explicitly out of scope, with the trigger that revives each.
- **Bookkeeping** — the exact doc updates: which LEDGER row (new or amended),
  which CHANGELOG entry (date + slug), which PLAN row, same commit as landing.

The generated CLAUDE.md carries the one-line version ("a spec without a
Bookkeeping section is incomplete"); this is the full definition.

## Lite → full upgrade

Lite = CLAUDE.md (with inline `## Tasks` table) + CHANGELOG.md + AGENTS.md +
lint. Upgrade when the task table outgrows one screen or a second contributor
arrives: move the table to PLAN.md (from PLAN.template.md), move any accreted
decision lines to LEDGER.md rows + extracts, delete the `## Tasks` section,
record the upgrade as a dated CHANGELOG entry. One session, no data loss.

## Multi-writer repos

CLAUDE.md is an instruction surface: repo write access = changing agent
behavior for every future session. For repos with more than one writer, add a
CODEOWNERS entry for CLAUDE.md/LEDGER.md and review contract diffs with code-
level care. Never paste unreviewed external text into CLAUDE.md or docs/notes/.

## Budget provenance

The default CLAUDE.md budget shipped by SKILL.md is the measured rules-only
residue of the origin project's real 97 KB contract (+30% headroom), not a guess.
Measurement: ../docs/2026-08-04-budget-backtest.md. Re-run the method on any
project whose shape differs wildly and set the budget from YOUR number.
```

- [ ] **Step 2: Verify sections present**

Run: `grep -c "^## " references/methodology.md`
Expected: 6.

- [ ] **Step 3: Commit**

```bash
git add references/ && git commit -m "feat: methodology reference — rationale, worked example, spec sections, upgrade path"
```

---

### Task 7: SKILL.md (the generator)

**Files:**
- Create: `SKILL.md`

**Interfaces:**
- Consumes: every template token from Tasks 3–5 (exact names), `scripts/doc-lint.sh` (Task 2), the backtest number (Task 1 — bake as the concrete integer measured there; the plan text below shows `28000` as a stand-in in TWO places — the budget header line and the `{{BUDGET_CLAUDE}}` fill rule — replace BOTH with Task 1's real Result).
- Produces: the complete skill entry point. Frontmatter `name: project-docs`; description triggers on "set up project docs", new-project doc scaffolding, doc-system retrofit.

- [ ] **Step 1: Write SKILL.md**

````markdown
---
name: project-docs
description: Use when starting a new project ("set up project docs", "scaffold project documentation") or retrofitting one onto an existing repo — generates a context-economical doc system (CLAUDE.md contract, PLAN.md state, CHANGELOG.md history, LEDGER.md decisions, optional TARGETS/baseline modules, doc-lint) via a short interview.
---

# project-docs — generate the project doc system

Templates live in `templates/` beside this file; methodology and worked
examples in `references/methodology.md` (read it if a design question comes
up; do not load it otherwise). Default CLAUDE.md budget: **28000 bytes**
(measured — see references/methodology.md "Budget provenance").

## Step 0 — existing files check (ALWAYS first)

List which of CLAUDE.md, AGENTS.md, PLAN.md, CHANGELOG.md, LEDGER.md,
TARGETS.md, scripts/doc-lint.sh already exist in the target repo.

- Any exist → this is a RETROFIT: never overwrite any existing file without
  explicit per-file go-ahead. Generate missing files only. Then OFFER (never
  silently run) an extraction pass: propose constraints, ledger rows, and
  stack-table entries mined from git log + existing docs, owner approving each
  proposed item individually.
- None exist → greenfield, continue.

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
form of the product paragraph; `{{BUDGET_CLAUDE}}` = 28000 unless the owner
sets another.

`{{PLATFORM_SECTIONS}}`: if Q1's platform is Android, fill with exactly the
block between the BEGIN/END markers (markers excluded; keep one blank line
above `##` when it lands in the file); any other platform → empty string.

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

Run `sh scripts/doc-lint.sh` from the target root (exit 0 required — any
`{{TOKEN}}` or missing maintenance block fails). Then check by hand: each
generated header names what does NOT live in that file. Report the file list,
budget, and lint result to the owner. Suggest committing the doc system as its
own commit.
````

- [ ] **Step 2: Verify frontmatter + token coverage**

Run: `head -4 SKILL.md` — expect `---`, `name: project-docs`, `description: …`, `---`.
Run: `mkdir -p tests/tmp && grep -oh "{{[A-Za-z_]*}}" templates/*.md | sort -u > tests/tmp/have.txt && grep -oh "{{[A-Za-z_]*}}" SKILL.md | sort -u > tests/tmp/covered.txt && comm -23 tests/tmp/have.txt tests/tmp/covered.txt`
Expected: empty output (every template token is named in SKILL.md's fill instructions).

- [ ] **Step 3: Commit**

```bash
git add SKILL.md && git commit -m "feat: SKILL.md generator — retrofit guard, 6-question interview, lite/full generation, init lint"
```

---

### Task 8: Acceptance — generate two dummy projects, lint green

**Files:**
- Create (scratch, gitignored): `tests/tmp/dummy-lite/`, `tests/tmp/dummy-full/`

**Interfaces:**
- Consumes: everything. This is the spec's v1 acceptance gate: "generates clean on two dummy projects (one lite, one full), lint green on both."

- [ ] **Step 1: Generate dummy-full by hand-following SKILL.md**

Act as the skill's executor against `tests/tmp/dummy-full/` with canned answers: full mode; product "NoteJar — offline Android note-taking app, solo dev, freemium"; constraints "1. Zero telemetry. 2. Works fully offline."; stack "UI: Jetpack Compose; storage: TBD — locked when sync design lands"; modules: TARGETS yes, baseline no; evidence "unit tests green + manual check on a physical device". Fill every token per SKILL.md Step 2 (Android ⇒ `{{PLATFORM_SECTIONS}}` = the On-Device QA block), copy doc-lint.sh in.

- [ ] **Step 2: Lint dummy-full**

Run: `cd tests/tmp/dummy-full && sh scripts/doc-lint.sh; echo "exit=$?"`
Expected: `exit=0`. Then confirm the TBD row spawned a Decisions Needed entry: `grep -A3 "## Decisions Needed" PLAN.md` shows the storage decision with trigger "sync design lands". Then confirm the platform snippet landed: `grep -c "^## On-Device QA" CLAUDE.md` = 1 (and `grep -c "uiautomator" CLAUDE.md` = 1).

- [ ] **Step 3: Generate dummy-lite + lint**

Same against `tests/tmp/dummy-lite/`: lite mode; product "todo-cli — personal task CLI"; constraint "1. No network."; stack "Rust (locked)"; evidence "cargo test green".
Run: `cd tests/tmp/dummy-lite && sh scripts/doc-lint.sh; echo "exit=$?"`
Expected: `exit=0`; `ls` shows exactly CLAUDE.md, AGENTS.md, CHANGELOG.md, scripts/ (no PLAN.md, no LEDGER.md); `grep -c "## Tasks" CLAUDE.md` = 1.

- [ ] **Step 4: Full-suite re-run + spec sweep**

Run: `sh tests/run-tests.sh` — expected `ALL PASS`.
Sweep the spec's Produced-system table against dummy-full's file list; sweep the cut list (`ls templates/` must NOT contain HANDOVER or spec-sections). Fix any gap found, re-run lint.

- [ ] **Step 5: Record acceptance + commit**

Append to `docs/2026-08-04-budget-backtest.md` a final section `## v1 acceptance` with the two lint exit codes and the date. Commit:

```bash
git add -A && git commit -m "feat: v1 acceptance — lite + full dummy projects generate clean, lint green"
```

---

## Self-Review

- **Spec coverage:** rules 1–13 → Task 3 (CLAUDE maintenance block: rules 1, 2, 8, 11, 12, 13 + precedence + secrets), Task 4 (rules 2, 3, 10 formats), Task 5 (rules 4, 5, 6 in PLAN/TARGETS), Task 2 (lint = rule 9 enforcement + C11), Task 1 (rule 9 backtest = C2), Task 7 (interview M13/M7/C12, retrofit M6/C-research-8, lite C15), Task 6 (spec sections C15, multi-writer C-security-6, upgrade path). Read-order block C5 → Task 3. AGENTS stub → Task 3. Acceptance criterion → Task 8. Cut list (no HANDOVER/spec-sections) → global constraints + Task 8 sweep. No uncovered spec section found.
- **Placeholder scan:** the only `{{…}}` occurrences are deliberate template tokens, enumerated and verified per task; `28000` in Task 7 is explicitly flagged as a stand-in replaced by Task 1's measured Result.
- **Type consistency:** entry format, pointer format, extract format, and status vocabularies appear in Tasks 2, 3, 4, 5, 7 — all copied from Global Constraints verbatim; lint regexes in Task 2 match the formats in Tasks 3–4 (`- <date> <slug>`, `→ CL <date> (<slug>)`, `^| N |`, `^#N:`).
