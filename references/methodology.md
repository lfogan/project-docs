# project-docs methodology

Loaded on demand only. The generated files are the runtime authority; this
file records why they are shaped the way they are.

## Design rules

1. Advisory checks do not work. Agents ignore warnings and obey failing exit
   codes, so every lint check fails the commit or does not exist.
2. Per-file byte budgets fail when content can move between files: the capped
   file stays green while the total grows. So the cap sits on the one file
   that always loads, and cold files are uncapped.
3. A rule a test or hook can enforce is written as that test or hook, not as
   prose. A prose rule earns its place only when nothing mechanical can catch
   the violation and an agent would commit it by default.
4. Each fact has exactly one home, so no two files can disagree and no
   precedence order is needed.
5. Git records what was done, not what was declined. Rejected proposals and
   withdrawn findings go in docs/SETTLED.md so cold audits stop re-raising
   them.

## Caps

The generated CLAUDE.md skeleton is about 2.3 KB; commands, stack rows, and
a realistic rule set bring it to roughly 4.5 KB. The cap is 6000 bytes:
headroom to work in, tight enough that narrative cannot accumulate. 25 rules
is an alarm level; around 10 is the expected steady state. Override either
by editing BUDGET_CLAUDE or RULES_CAP in the generated doc-lint.sh. The lint
logs the cap per run, so a raise is visible in the trend.

## TODO and DONE

TODO.md is read every session, so it holds only active rows. A finished row
moves to DONE.md verbatim in the landing commit. Where the task produced
code, that is the commit carrying the work, or the last of several. Where
it produced none, it is simply the next commit of any kind: bookkeeping
never earns a commit of its own.

Archiving rather than deleting keeps one complete record, in the owner's
words, of everything done. Sharpest where a task produces no code (a
passing device walk, a verification pass, an audit that finds nothing), but
the rule is uniform: every finished row lands in DONE.md, whether or not
git already shows the work. The owner reads the list as a progress record,
so DONE.md is never rotated, trimmed, or summarised.

The lint stops the archive from becoming a changelog by shape: rows are
single lines under 300 characters with no What/Why/Evidence keys. That rows
arrive only by moving from TODO.md is convention the lint cannot see - the
shape check makes violating it pointless, since a story-shaped entry fails
either way.

## Work that completes outside the repo

Store console state, signing keys, accounts, DNS, and review submissions
leave no trace in git, so their record lives in docs/agent/release.md as
dated lines that are never deleted. The row still moves to DONE.md like any
other. release.md answers "where does the release stand" without
reconstructing it from DONE.md. Such a task appears twice on purpose, as
record in DONE.md and as status in release.md; not duplication to collapse.

Git replaces the changelog, not TODO and DONE. That a stranger could read
the work out of git is never a reason to skip the DONE.md row.

## What each check prevents

| Check | Prevents |
|---|---|
| 0 core files exist | the doc system being dismantled file by file |
| 1 cap + no imports | unbounded growth of the always-loaded file |
| 2a rules grammar + cap | rule sprawl, and prose smuggled into the rules section |
| 2b SETTLED grammar | narrative growing where one-line entries belong |
| 3a TODO drain | finished rows piling up in the file every session reads |
| 3b DONE shape | the archive growing stories instead of rows |
| 3c TODO markers | rows whose state the next session cannot tell |
| 4 forbidden legacy files | CHANGELOG/LEDGER/PLAN growing back |
| 5 paths resolve | pointers to files that do not exist |
| 6 required sections | a generated CLAUDE.md missing its commands section |
| 6b coverage table | the environments record being emptied or deleted silently |
| 7 unfilled tokens | broken generation passing silently |
| commit-msg design gate | design edits landing without owner approval |

## The trend log

docs/doc-lint-log.csv gets one row per lint run; the pre-commit hook stages
the row into its commit. Healthy directions: rules_count falling,
docs_touched share falling, claude_bytes flat and well under cap,
settled_lines rising only on owner rejections. agent_bytes has no target;
bytes landing in cold files instead of CLAUDE.md is the intended direction.

## Where enforcement runs

Two hooks installed via `git config core.hooksPath .githooks`: pre-commit
runs every lint check and stages the CSV row; commit-msg holds the design
gate, which needs the message. Nothing runs while editing; the owner chose
commit-time only. `git commit --no-verify` skips both hooks: R4, the generated
rule against bypassing the hooks, forbids it, and a bypassed commit leaves
a gap in the CSV.
