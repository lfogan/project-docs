# Bookkeeping payload — subagent → dispatcher

Subagents never edit the shared doc files (CLAUDE.md, PLAN.md, CHANGELOG.md,
LEDGER.md, TARGETS.md — see the Maintenance rule in CLAUDE.md). Instead, a
subagent that lands work ends its final report with the block below, filled.
The dispatcher writes every doc home from it — once per task — and runs
`sh scripts/doc-lint.sh` before commit.

Filling rules (for the subagent):

- Every number (test counts, callsite counts, byte sizes) is PASTED from
  command output quoted in `evidence` — never recalled, never recomputed by
  hand. A number with no quoted command behind it is a defect.
- Leave `#N` unassigned and write no dates. The dispatcher assigns ledger
  numbers and stamps dates; parallel agents guessing numbers is how
  collisions and renumbering churn happen.
- Anything not observed first-hand goes in `not-claimed`, never `evidence`.
  Per the Working Agreements, unclaimed ⇒ the task row is [Partial].
- The block must stand alone: no "see above", no references to earlier
  messages in your transcript.

```
BOOKKEEPING PAYLOAD
slug: <kebab-case, unique for today; becomes the CHANGELOG slug>
headline: <one line — what changed, plain voice>
what: <2–6 sentences for the entry's What: clause — files, symbols, behaviour>
why: <1–4 sentences for Why: — reason; name the audit item / owner call / finding>
evidence: <commands run + observed output, numbers verbatim; artifact paths>
limits: <what remains unverified, or "none">
decision: <"none", or ledger-caliber decision text (≤600 chars, decision + why);
  the dispatcher assigns #N and derives the ≤200-char CLAUDE.md extract from it>
plan-row: <PLAN.md row id + proposed status + ≤200-char cell text, or "none">
files-touched: <code/test/asset paths only — never doc files>
not-claimed: <explicit list of things this report does NOT establish>
```

Dispatcher checklist (per task, one docs pass):

1. Verify `evidence` names real commands and output; re-run at least one
   claim first-hand (Working Agreements: subagent claims are unverified
   until re-run; unverified ⇒ [Partial]).
2. Read the LEDGER tail, assign the next `#N`, stamp today's date.
3. Append the CHANGELOG entry — `- YYYY-MM-DD <slug> — <headline>. What: …
   Why: … Evidence: … Limits: …` — append-only, never touch an existing
   entry. Trailing space after the slug (doc-lint check 3 greps for it).
4. If `decision` ≠ none: write the LEDGER row and the CLAUDE.md extract,
   both pointing `→ CL YYYY-MM-DD (<slug>)`.
5. Update the PLAN row if named, downgrading to [Partial] where
   `not-claimed` covers the row's evidence.
6. `sh scripts/doc-lint.sh` → exit 0, then commit code + docs together. Run
   it silently: exit 0 gets no announcement and no summary, exit 1 quotes the
   findings and fixes them before the commit.
