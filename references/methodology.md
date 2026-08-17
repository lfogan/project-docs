# project-docs v2 methodology — rationale and evidence

Loaded on demand only. The generated files are the runtime authority.

## The v1 post-mortem (why v2 is shaped like this)

v1 (CLAUDE.md + PLAN + LEDGER + CHANGELOG + extract/pointer lint) was measured
across 7 live repos on 2026-08-17. The pilot repo (hard-graft, an Android app
5 days old, 140 commits, 14.8k lines of Kotlin) showed:

| Measurement | Value |
|---|---|
| Total doc bytes | 468 KB (vs 690 KB of code) |
| Always-loaded set (CLAUDE.md + PLAN.md) | ~105 KB per work-picking session |
| CLAUDE.md growth | +57% in 3 days; two-thirds of it decision extracts |
| Decision retirement | 1 of 78 ledger rows, ever |
| Directive-count warning | fired 42/42 runs; count rose 76→107 anyway |
| Hard lint failures | 4, each fixed by the very next run |
| Commits touching doc files | 99 of 140 (71%) |
| Extracts duplicating an existing test | ≥5 (named ArchitectureTest/ContrastTest inline) |

Conclusions carried into v2:

1. **Advisory checks change nothing; hard-failing checks are obeyed same-day.**
   Same agent, same week, both behaviors observed. v2 bans warnings.
2. **Per-file budgets get satisfied by relocation** (prune into CHANGELOG,
   rotate CHANGELOG into archives — the origin repo sat at 96%/99.7% of two
   budgets, green, with 652 KB total). v2 caps the only thing that loads.
3. **A rule a test can enforce should be a test.** The repo already had the
   tests; the prose was a second copy that could (and did) drift.
4. **Four homes per fact ⇒ documented precedence ladders and "knowingly
   ahead of source" annotations.** v2: one fact, one home; nothing can
   disagree.
5. **Git cannot record what was declined.** The one irreplaceable v1 content
   class was "raised and WITHDRAWN, do not re-raise" — cold audits re-raise
   settled findings forever without it. That class alone survives as
   docs/SETTLED.md.

## Budget provenance

The v2 CLAUDE.md skeleton is ~2.7 KB. The genuinely hot residue of the pilot
repo — commands, stack one-liners, and the 8–12 rules that pass the admission
test (untestable AND default-violated) — prices at ~4.5 KB. 6000 bytes is
that plus headroom, and roughly 7× smaller than v1's 45,000 ceiling, which
was derived from an outlier and reachable by relocation. 25 R-lines is an
alarm line, not a target; ~10 is the expected steady state. Overrides go in
the generated doc-lint.sh and are logged per run (rules_cap column), so a
bump is a visible trend event rather than a silent loosening.

## Lint check → observed failure it prevents

| Check | Prevents (observed instance) |
|---|---|
| 1 cap + no imports | hot-set regrowth (+57%/3 days); byte-smuggling past the one measured number |
| 2a rules grammar + cap | directive dilution (76→107 under an ignored warning) |
| 2b SETTLED grammar | narrative creep — one-line Don'ts make stories impossible |
| 3 TODO drain | the PLAN graveyard (62 stale [Partial] rows) |
| 4 forbidden v1 files | regrowth from muscle memory / agents imitating repo history |
| 5 paths resolve | dangling pointers (4 caught in 5 days; v1 itself shipped one) |
| 6 required sections | pilot's CLAUDE.md had NO build/test commands and nothing noticed for 5 days |
| 7 no unfilled tokens | broken generation passing silently |
| commit-msg design gate | silent edits to the owner's design source of truth |

## Outcome measurement

docs/doc-lint-log.csv, one row per lint run (the pre-commit hook stages the
row into its commit). Healthy directions:

- `rules_count` **down** — lessons graduating up the enforcement ladder.
- `docs_touched` share of commits **down** — less ceremony (v1: 71%).
- `claude_bytes` flat, far under cap — a fresh contract near the cap on day
  one is diagnostic of a problem.
- `settled_lines` up **slowly and only on owner "no"s**.
- `agent_bytes` unpoliced by design — bytes landing cold instead of hot is
  the system working.

## Where enforcement runs, and why

Two thin git hooks via `core.hooksPath`: pre-commit (all lint checks + CSV
staging) and commit-msg (design gate — it needs the message). Nothing runs
during editing: the owner chose commit-time-only for development speed. A
check that depends on an agent remembering to run it has the reliability of a
rule that depends on an agent remembering to follow it; at the pilot's pace
(140 commits/5 days) the commit gate fires constantly with zero memory
dependence. Known bypass: `--no-verify` (R4 forbids it; a missing CSV row
makes a bypass visible).
