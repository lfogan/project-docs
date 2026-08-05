# Budget backtest — PocketScript CLAUDE.md distillation (read-only)

Method: spec rev-2 rule 8 applied on paper to every section of PocketScript's
real CLAUDE.md (97 KB, 2026-08-04 state). Rules stay inline; stories priced as
pruned to CHANGELOG/LEDGER/notes. Ledger priced at 200 bytes per Active row.

Pricing conventions, applied uniformly so the numbers are reproducible:
a surviving rule = one terse imperative an agent must see BEFORE acting
(constraint, invariant, warning, or a stack-table row with its Choice value),
priced at **150 bytes** — the midpoint of the 100–200 byte band. Narrative is
pruned: histories, verification stories, amendment sagas, "why we rejected X"
prose, review findings, dated device-pass writeups. Two caps keep the estimate
honest: **residue never exceeds a section's current bytes** (already-terse
sections cannot grow under distillation), and structural surfaces that *are*
the rule — the token table, the file tree — are priced from their measured
bytes minus their embedded prose, not by unit count. Source file measured at
97,699 bytes / 220 lines, CRLF; per-section byte counts sum to exactly that.

## Per-section table

| Section | Bytes now | Rules residue (est.) | Notes |
|---|---|---|---|
| (preamble) H1 + product paragraph + Design baseline block | 2980 | 1500 | 10 units. Survives: title, product paragraph (2 units), the 3 design-baseline rules, "every screen accepted as shipped", "README useful for two things only", living-documents rule, same-commit rule. Pruned: the declined-per-screen-list story, the "absence of a reason" justification prose. Rule-dense block, ~50% retention. |
| Tech Stack (locked) | 6545 | 2800 | 14 stack rows x 150 + 100 table header/separator + 4 x 150 for hard warnings that will not fit a row cell (useLegacyPackaging is required-not-a-knob; never "align" applicationId/namespace; billing plain-type seam; ggml CPU-variant dispatch). Pruned: the entire Notes column's narrative — the Nav3/AGP-floor investigation (~700 B alone), the WSL2-vs-Docker choice, the libass/fribidi merge rationale, the Billing 8.3.0 version-drift story. |
| Critical Constraints (violating any of these is a shipping blocker) | 4622 | 4050 | 27 units — the densest section in the file, ~88% retention and correctly so. Constraint 1 alone is 7 units (6 LGPL sub-rules + the verbatim FreeType FTL credit sentence, which is fixed by licence and cannot be compressed). Pruned: only parentheticals — the FTL year-derivation note, "verified against the 8.0.0 AAR manifest", "(PLAN Phase 8 gate)". |
| OKLCH Theme Rules | 2233 | 1810 | 7 prose units (1050) + token table priced structurally (760 = measured 960 minus ~200 B of story inside the Legal-body-text row). Table is already at one line per token and survives near-verbatim. Pruned: the colorjs.io escape-hatch method note, the "same fall-back-to-hex pattern as on-mint/on-gold" explanation. |
| File Structure | 2677 | 2450 | Structural, not unit-priced: a file tree IS the rule surface (where code goes), so ~92% of the fenced block (measured 2654) survives plus the heading. Pruned: the deepest per-file enumerations inside a few comments. |
| Architecture Invariants | 4202 | 3600 | 24 units across 6 bullets (Screens 3, Segments 5, Playback highlight 5, Pipeline 4, Import preflight 2, Burn-in 5), ~86% retention. Cross-checks against subtraction: the prunable narrative here is the "highlighting almost never works" bug story, the "Phase 10 finding" framing, and "confirmed by reproducing the exact hang" — together ~600 B, and 4202 - 600 = 3600. |
| Mid-Device Performance Contract (owner priority: mid-range phones, no overheating, no crashes) | 4496 | 3300 | 22 units, ~73% retention. Survives: one-native-job rule, codec discipline, the 3 governor tiers + its required user-facing copy string, 1080p cap, ETA rules, 4 battery-gate rules incl. "a burn failure must NOT change project status", chunking policy, editor scale, crash-visibility rule. Pruned: the charging-sprint 6-to-3 saga, "bumped from 2000 in Phase 14", the owed base.en RSS re-measure (belongs in PLAN, not the contract). |
| Deviation Ledger (approved divergences from the design baseline) | 64820 | 8400 | Mandated formula: 42 Active rows x 200 B extract cap. 43 rows total, 1 Retired (#15) contributing 0. Full rows move to LEDGER.md. This one section is 66% of the file today and 27% of the residue. |
| Working Agreements | 588 | 550 | Cap applied: 4 bullets already terse imperatives, all survive; unit pricing (5 x 150 = 750) would exceed current bytes, so residue is capped at current minus the one pruned parenthetical ("raised 2026-07-16: dual bundled English models"). |
| Workbench Notes (recurring gotchas) | 3934 | 1950 | 13 units, ~50% retention — the section with the most story per rule. Each bullet keeps its operative recipe (install APKs manually + am instrument + internal cacheDir + run-as applicationId + MSYS_NO_PATHCONV; re-unlock in-process; distrust task reports; Bundle-storable keys; init-block ordering + its cheap guard; 4 device-run rules; emulator cannot burn). Pruned: the incident narratives those rules were learned from. |
| On-Device QA | 369 | 350 | Cap applied: 3 terse imperatives, already minimal, survive whole. This is the section SKILL.md ships as the Android platform snippet, so its residue is effectively its shipped size. |
| Changelog | 233 | 230 | Pointer section — a link plus the "do not append entries here" rule. Survives whole by construction. |

## Result

Measured residue: 30990 bytes.
Shipping default {{BUDGET_CLAUDE}} = 45000 bytes.

(30990 x 1.3 = 40287, rounded up to the next whole 5 KB = 45000.)

Sensitivity — the estimate's one real free variable is the per-rule price.
121 of the residue's units are prose-priced at 150 B; the other sections are
capped or structurally measured. Repricing those 121 units across the allowed
100–200 B band moves residue to 24940 (at 100) or 37040 (at 200). Running each
through this document's own formula — x1.3 first, then round up to the next
5000 — gives 24940 x 1.3 = 32422, which rounds up to **35000**; and
37040 x 1.3 = 48152, which rounds up to **50000**. The band is therefore
**35000–50000**.

45000 is **not** the midpoint of that band. The midpoint is 42500, which the
formula can never emit at all, since it only produces multiples of 5000. What
is true: 30990 is exactly the midpoint of the *residue* band, but the round-up
step is non-linear, so a midpoint residue lands one step above the midpoint
budget. 45000 is one step high, not central.

Sharper, and the thing to actually carry forward: 30990 clears the threshold
for 45000 by only **220 bytes (0.71%)**. Any residue of 30769 or below ships
40000 instead. This result sits one small estimation error away from moving a
whole 5 KB step, and the per-rule price is what would move it. 45000 remains
the number tasks 2, 3, 7 and 8 consume.

## v1 acceptance

**Date:** 2026-08-05.

This is the plan's formal Task 8 acceptance gate — executed cold, by hand,
against SKILL.md's current committed text (post the two Task 7 review-fix
rounds), by a fresh reader rather than the implementer/reviewer who wrote it.
It is distinct from Task 7's own review-round builds, which were scratch and
produced no durable record.

- **dummy-full** (`tests/tmp/dummy-full/`, gitignored scratch): NoteJar,
  Android, full mode, TARGETS module yes, baseline module no. `sh
  scripts/doc-lint.sh` → **exit=0**. TBD storage stack row correctly spawned a
  `## Decisions Needed` row in PLAN.md (trigger "sync design lands"); the
  Android `{{PLATFORM_SECTIONS}}` snippet landed as exactly one `## On-Device
  QA` block (1 occurrence) containing `uiautomator` (1 occurrence), with a
  blank line on each side per SKILL.md's spacing requirement. Generated file
  set: CLAUDE.md, AGENTS.md, PLAN.md, CHANGELOG.md, LEDGER.md, TARGETS.md,
  scripts/doc-lint.sh — matches full mode + a requested TARGETS module with no
  baseline module, exactly.
- **dummy-lite** (`tests/tmp/dummy-lite/`, gitignored scratch): todo-cli,
  Rust, lite mode. `sh scripts/doc-lint.sh` → **exit=0**. Generated file set is
  exactly CLAUDE.md, AGENTS.md, CHANGELOG.md, scripts/ — no PLAN.md, no
  LEDGER.md. The `## Tasks` section heading appears exactly once (anchored
  check); the widened `grep -c "PLAN\|LEDGER"` sweep (interface note 2 — not
  the narrower `.md`-suffixed check) returned **0 for all three generated
  files**, confirming the 10 CLAUDE.md + 1 AGENTS.md + 2 CHANGELOG.md
  lite-mode post-fill edits were all applied correctly with no dangling
  PLAN/LEDGER references.
- **Harness:** `sh tests/run-tests.sh` → **11/11 ALL PASS**, no regression
  from anything Task 7 touched.
- **Templates cut-list sweep:** `ls templates/` does not contain
  `HANDOVER.template.md` or `spec-sections.template.md` — clean.
- **Spec sweep:** the design spec's "Produced doc system" table
  (`docs/2026-08-04-project-docs-skill-design.md`) was checked against
  dummy-full's actual generated file list. Every table row applicable to
  dummy-full's choices (full mode, TARGETS requested, baseline declined) has
  a corresponding generated file, and every generated file has a
  corresponding table row; `docs/notes/` (dir on first use), `docs/design/
  STATUS.md` (module, declined), and specs/plans (via superpowers, not this
  skill) were correctly absent. **Zero discrepancies found.**

Both dummy projects generate clean; both lint green; the harness has no
regression; the cut list holds; the spec sweep is clean. v1 acceptance
criterion (design spec's own Bookkeeping section: "generates clean on two
dummy projects (one lite, one full), lint green on both, plus the backtest
number recorded in methodology.md") is met.
