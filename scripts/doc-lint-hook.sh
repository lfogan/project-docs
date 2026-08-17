#!/bin/sh
# doc-lint-hook.sh — Stop-hook wrapper around doc-lint.sh. Optional: the lint
# works exactly the same without it.
#
# Why a wrapper rather than pointing the hook straight at doc-lint.sh: a Stop
# hook's exit code is a protocol, and doc-lint's is not the same protocol.
# Exit 1 from a Stop hook is a NON-BLOCKING error — the turn ends anyway and
# the findings are only logged, which is the opposite of what this is for.
# Blocking requires exit 2, with the message for Claude on STDERR. This script
# does that translation and nothing else.
#
# Contract:
#   exit 0, silent  — lint clean, nothing to lint, or a Stop hook already
#                     blocked this turn (see the guard below: the flag is set
#                     by ANY Stop hook blocking, not just this one)
#   exit 2 + stderr — findings; the turn is blocked and stderr goes to Claude
#
# Known limits, so nobody mistakes this for the whole story:
#   - It blocks AT MOST ONCE per turn, and never re-runs to confirm the fix
#     landed. The next turn's run is what confirms it.
#   - Check 7's directive-count WARNING never surfaces here. Warnings leave
#     the lint's exit at 0, and a Stop hook exiting 0 shows nothing. The
#     warning appears when the lint is run directly, which the bookkeeping
#     pass still does.
#   - The run log is suppressed (see DOC_LINT_LOG below), so a project that
#     leans on the hook and stops running the lint by hand will stop
#     accruing trend rows.
#
# Reads the hook's JSON payload on stdin. Dependency-free POSIX sh: no jq, to
# match doc-lint.sh itself.
input=$(cat)

# Loop guard. Claude Code sets stop_hook_active=true on the Stop event that
# follows a block, so blocking again would re-enter the same fix cycle. Most
# findings converge on their own (Claude fixes them, the next run is clean),
# but the ones that CANNOT — CLAUDE.md over budget is the standard case, since
# pruning is the owner's call, not Claude's — would otherwise block repeatedly
# until Claude Code's own block cap cuts them off. One cycle, then out.
case "$input" in
  *'"stop_hook_active"'*)
    active=$(printf '%s' "$input" | sed -n \
      's/.*"stop_hook_active"[[:space:]]*:[[:space:]]*\([a-z]*\).*/\1/p')
    [ "$active" = "true" ] && exit 0
    ;;
esac

# CLAUDE_PROJECT_DIR is the project root. The fallback to the current
# directory is for the test suite, which pipes the payload in. Note this
# script reads stdin first, so running it from an interactive shell will sit
# waiting for input until EOF — to try it by hand, feed it a payload:
#   printf '{"stop_hook_active":false}' | sh scripts/doc-lint-hook.sh
cd "${CLAUDE_PROJECT_DIR:-.}" 2>/dev/null || exit 0

# Not a project-docs project (or the lint was removed): stay out of the way.
# BOTH files are required, not just the script. A repo can carry
# scripts/doc-lint.sh without being a project that uses it — this skill's own
# repo is exactly that, since it SHIPS the lint rather than being linted by
# it. Checking only for the script there would block every turn on
# "CLAUDE.md is missing", forever, with nothing to fix.
#
# doc-lint's own missing-CLAUDE.md check is not weakened by this: it exists to
# catch a botched generation, which Step 3 checks by running the lint directly.
# Run from a hook the same finding means something different — "this is not a
# doc-system project" — and the right response is to say nothing.
[ -f scripts/doc-lint.sh ] && [ -f CLAUDE.md ] || exit 0

# DOC_LINT_LOG=0 deliberately, and this is a trade rather than a free win.
# Logging here would append a row on EVERY turn — including turns that touched
# no docs at all — leaving the working tree dirty after each one and swamping a
# trend meant to be read per landed change. What it costs: a project that
# adopts the hook AND lets the by-hand habit lapse quietly stops accruing trend
# rows, because the bookkeeping pass running the lint directly is what feeds
# the log. The hook is a safety net under that habit, not a replacement for it.
out=$(DOC_LINT_LOG=0 sh scripts/doc-lint.sh 2>&1); rc=$?
[ "$rc" -eq 0 ] && exit 0

# Findings. Everything below goes to Claude, so it says what to do with them —
# including the case Claude must NOT try to fix on its own.
{
  [ -n "$out" ] && printf '%s\n\n' "$out"
  cat <<'MSG'
doc-lint reported the above. Fix it before ending the turn.

This hook will not run again this turn, so nothing here re-checks the fix:
say plainly what you changed, and if you could not fix something, say that
instead of implying it passed.

Two things are NOT yours to fix alone:
  - A file over budget. Deciding what to prune is the owner's call. Never
    delete or compress rules to get under the limit. Say what is over, and
    propose what could move to CHANGELOG.md or docs/notes/.
  - A finding in a file this project already had before the doc system was
    installed. Retrofits are allowed to carry those. Report it and leave it.
MSG
} >&2
exit 2
