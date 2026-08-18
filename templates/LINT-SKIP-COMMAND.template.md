---
description: Skip the doc-lint gate for the NEXT commit only (audited - findings still print and log)
---

The owner typed /lint-skip. This valve is owner-only: never perform these
steps unprompted, never create the marker to get your own commit through, and
never suggest this command as the fix for a lint finding.

1. Locate the git dir: `git rev-parse --git-dir`.
2. Create the empty one-shot marker: `<git-dir>/doc-lint-skip`.
3. Tell the owner: the next commit passes the gate even with findings; the
   findings still print and land in docs/doc-lint-log.csv as exit=0 with
   findings>0; the commit after is fully gated again.
4. Check the trend: `awk -F, '$2==0 && $3>0' docs/doc-lint-log.csv | tail -3`.
   Three skip rows in a row means a check is fighting this repo - offer to fix
   the check (or its cap) instead of skipping again.
