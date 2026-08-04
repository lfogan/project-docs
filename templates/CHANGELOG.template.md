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
