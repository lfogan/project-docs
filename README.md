# project-docs

A Claude Code skill that generates a small, mechanically enforced doc system
for agent-driven projects, and migrates repos off the old
PLAN/LEDGER/CHANGELOG scaffold.

## Principles

- One fact, one home. Design lives in `docs/design/DESIGN.md` (owner-approved
  edits only), behavior in tests, active tasks in `TODO.md`, finished rows in
  `DONE.md`, rejections in `docs/SETTLED.md`, stories in commit message
  bodies. Git is the history: no CHANGELOG, LEDGER, or PLAN files, and the
  lint fails any commit that adds one.
- A new lesson lands at the first rung that can hold it: deny-hook, then
  test, then lint check, then a CLAUDE.md rule, then a `docs/agent/` note.
  Prose rules are the last resort, and the rule count should fall over time
  as lessons turn into tests and hooks.
- Every check fails the commit. There are no warnings.
- `CLAUDE.md` is the only always-loaded file, so it is the only capped one:
  6000 bytes, 25 rules, no imports. Cold files (`docs/agent/`,
  `docs/SETTLED.md`, `DONE.md`) are uncapped.

## What it generates

| File | Purpose |
|---|---|
| `CLAUDE.md` | The contract: product line, commands and layout, stack, up to 25 R-rules, pointers |
| `TODO.md` | Active work ([todo]/[partial]/[in-progress]), read every session |
| `DONE.md` | Finished rows, moved verbatim from `TODO.md`; append-only, never read wholesale |
| `docs/SETTLED.md` | Owner-rejected proposals and withdrawn findings, one Don't-line each |
| `docs/design/DESIGN.md` | The design source of truth; edits land only with `[design-approved]` in the commit message |
| `docs/agent/*.md` | Activity guides read before that kind of work: device QA lore, the environments-proven matrix, release steps and setup |
| `AGENTS.md` | Three lines for other harnesses |
| `scripts/doc-lint.sh` | The lint plus a CSV trend row per run |
| `.githooks/pre-commit`, `.githooks/commit-msg` | The commit gate, installed with `git config core.hooksPath .githooks` |
| `.claude/commands/lint-skip.md` | Owner-only `/lint-skip`: pass the NEXT commit despite findings, one commit, audited |

## The lint

`scripts/doc-lint.sh` runs from `.githooks/pre-commit` on every commit and
fails it on: CLAUDE.md over cap or using imports, a broken rules section, a
done marker left in TODO.md, a malformed TODO, DONE, or SETTLED row, a
legacy file, a referenced path that does not exist, a missing required
section, or an unfilled template token. The commit-msg hook blocks changes
under `docs/design/` - and any design-gated code path listed on its
`GATED_PATHS` line, e.g. an Android `/ui/theme/` package - unless the message
contains `[design-approved]`. Design values living in code are the design;
the gate follows the values.

Each run appends a row to `docs/doc-lint-log.csv` with sizes, rule count,
cap value, and whether the commit touched docs. The trend is how you judge
the system: rule count and the share of commits touching docs should fall,
and a cap raise shows up as a changed `rules_cap` value.

The gate has one valve: `/lint-skip` (or `DOC_LINT_SKIP=1 git commit ...`)
lets the next commit pass with findings. The lint still runs, findings still
print, and the CSV row records `exit=0` with `findings>0` - a combination a
normal run cannot produce, so skips are self-auditing. The marker is one-shot;
the following commit is fully gated. Owner-typed only, never an agent's move.
Three skip rows in a row means a check is fighting the repo: fix the check.

## Using it

Say "set up project docs" on a new repo. On a repo with a legacy scaffold it
runs the migration instead. On a repo already using this system it offers to
refresh drifted scripts and templates. Every overwrite and deletion is a
checkbox you approve; declined items are left alone.

Tests: `sh tests/run-tests.sh` (the suite prints its own count, including a hook test in a
throwaway repo).

## License

MIT. See `LICENSE`.
