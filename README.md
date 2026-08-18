# project-docs (v2)

A Claude Code skill that generates a minimal, mechanically enforced doc
system for agent-driven projects — and retrofits the v1 system away.

## The problem, twice

v1 of this skill solved "CLAUDE.md grows without limit" by splitting facts
into files (rules, plan, ledger, changelog) with per-file byte budgets and a
lint. Measured after weeks of real agent use across 7 repos, that system had
failed in a more interesting way: a 5-day-old app carried 468 KB of docs,
71% of its commits touched doc files, its always-loaded set was ~105 KB, its
only advisory lint check had been ignored 42 runs straight, and each decision
was recorded in four places — which is four chances to disagree, and they did.
Meanwhile its four hard-failing checks were obeyed same-day, every time.

v2 keeps what worked (mechanical enforcement, the trend log) and deletes the
rest.

## Principles

- **One fact, one home.** Design → `docs/design/DESIGN.md` (owner-approved
  edits only) · behavior → tests · active task state → `TODO.md` · finished
  rows → `DONE.md` · rejections → `docs/SETTLED.md` · stories → commit message
  bodies. Git is the history — there is no CHANGELOG, no LEDGER, no PLAN, and
  the lint forbids them.
- **Cold files absorb; they do not rewrite.** A finished row moves into
  `DONE.md` verbatim — single line, no What/Why/Evidence block, 300-byte
  ceiling, all lint-enforced. That shape is what stops an archive becoming
  the 258 KB changelog nobody read.
- **Enforcement ladder.** deny-hook > test > lint check > CLAUDE.md rule >
  `docs/agent/` note. A prose rule is last-resort debt; the healthy rule
  count trends *down* as lessons graduate into tests and hooks.
- **Every check hard-fails at commit.** Advisory checks are banned: measured
  agents ignore warnings and obey exit codes.
- **Hot cap.** `CLAUDE.md` ≤ 6000 bytes, ≤ 25 rules, no imports. It is the
  only always-loaded file, so it is the only capped file. Cold files
  (`docs/agent/`, `docs/SETTLED.md`) are deliberately unpoliced — bytes
  landing there instead of the hot set is the system working.

## What it generates

| File | Purpose |
|---|---|
| `CLAUDE.md` | The contract: product line, commands & layout, stack, ≤25 R-rules, pointers |
| `TODO.md` | Active work only ([todo]/[partial]/[in-progress]) — read every session |
| `DONE.md` | Finished rows, moved verbatim from `TODO.md`. Append-only, never read wholesale, so it costs no context |
| `docs/SETTLED.md` | The record of "no": owner-rejected proposals and withdrawn findings, one Don't-line each, so cold audits stop re-raising them |
| `docs/design/DESIGN.md` | The single design source of truth; edits land only with `[design-approved]` in the commit message |
| `docs/agent/*.md` | On-demand activity guides: device/QA lore plus the matrix of which environments are proven, release steps plus what is already set up. Read before that kind of work |
| `AGENTS.md` | Three lines for other harnesses |
| `scripts/doc-lint.sh` | 10 hard-failing checks + a CSV trend row per run |
| `.githooks/pre-commit`, `.githooks/commit-msg` | The commit gate — installed with `git config core.hooksPath .githooks` |

## The lint

All checks hard-fail: cap + no imports · rules grammar and cap · SETTLED
grammar · no done-rows in TODO · TODO marker grammar · DONE.md row shape ·
forbidden v1 files · every referenced path exists · required sections present
+ no unfilled tokens. The commit-msg hook adds the design gate. Each check maps to a failure observed in the field —
the map is in `references/methodology.md`.

`docs/doc-lint-log.csv` gets one row per run (staged into the commit by the
hook): sizes, rule count, cap value, and whether the commit touched docs.
That trend is the system's only outcome measurement — rule count and
docs-touched share should fall, and a cap bump is a visible event, not a
silent loosening.

## Using it

Say "set up project docs" on a new repo, or run it on a repo carrying the v1
system (PLAN/LEDGER/CHANGELOG) to migrate: the retrofit triages old ledger
rows into tests, rules, SETTLED lines, or deletion — with batched owner
approval at every destructive step. Everything deleted stays in git.

Tests: `sh tests/run-tests.sh` (19 checks, including an end-to-end hook test
in a throwaway repo).

## License

MIT. See `LICENSE`.
