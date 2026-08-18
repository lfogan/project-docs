# {{PROJECT_NAME}} - agent entry point

Read CLAUDE.md before any work - it is the project contract. Task state: TODO.md. Before audits or re-proposing anything: grep docs/SETTLED.md.
Subagents report evidence (commands run + output observed) and never edit CLAUDE.md, TODO.md, or docs/SETTLED.md - the main session writes those and commits.
The lint skip valve (/lint-skip, the doc-lint-skip marker, DOC_LINT_SKIP=1) is owner-typed only - no agent creates the marker, sets the variable, or proposes the skip as the fix for a finding.
