# {{PROJECT_NAME}} — agent entry point

Read CLAUDE.md before any work — it is the project contract. Task state: TODO.md. Before audits or re-proposing anything: grep docs/SETTLED.md.
Subagents report evidence (commands run + output observed) and never edit CLAUDE.md, TODO.md, or docs/SETTLED.md — the main session writes those and commits.
