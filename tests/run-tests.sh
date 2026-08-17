#!/bin/sh
# Test harness for doc-lint.sh. Run from the skill root: sh tests/run-tests.sh
# DOC_LINT_LOG=0 on every invocation: fixtures must never accrue run-log files.
fails=0
assert() { # $1 desc, $2 expected-exit, $3 actual-exit, $4 output, $5 must-contain (empty = skip)
  if [ "$2" != "$3" ]; then echo "FAIL: $1 (exit $3, wanted $2)"; fails=$((fails+1)); return; fi
  # -F: expected strings carry regex metacharacters — pointer slugs are
  # parenthesised, e.g. "(alph)". Literal matching, never accidental regex.
  if [ -n "$5" ] && ! printf '%s' "$4" | grep -qF "$5"; then
    echo "FAIL: $1 (output missing: $5)"; fails=$((fails+1)); return; fi
  echo "ok: $1"
}
absent() { # $1 desc, $2 output, $3 must-NOT-contain
  if printf '%s' "$2" | grep -qF "$3"; then
    echo "FAIL: $1 (unexpected: $3)"; fails=$((fails+1)); return; fi
  echo "ok: $1"
}
count_is() { # $1 desc, $2 output, $3 pattern (literal), $4 expected count
  n=$(printf '%s\n' "$2" | grep -cF "$3")
  if [ "$n" != "$4" ]; then
    echo "FAIL: $1 ($3 x$n, wanted $4)"; fails=$((fails+1)); return; fi
  echo "ok: $1"
}

out=$(cd tests/fixtures/good-project && DOC_LINT_LOG=0 BUDGET_CLAUDE=5000 BUDGET_PLAN=5000 sh ../../../scripts/doc-lint.sh); rc=$?
assert "good project passes" 0 "$rc" "$out" ""

out=$(cd tests/fixtures/bad-project && DOC_LINT_LOG=0 BUDGET_CLAUDE=300 BUDGET_PLAN=5000 sh ../../../scripts/doc-lint.sh); rc=$?
assert "bad project fails" 1 "$rc" "$out" ""
assert "finds over-budget"      1 "$rc" "$out" "over budget"
assert "finds unfilled token"   1 "$rc" "$out" "unfilled"
assert "finds dead pointer"     1 "$rc" "$out" "unresolved pointer"
assert "finds circular pointer" 1 "$rc" "$out" "ledger-only-slug"
assert "finds orphan extract"   1 "$rc" "$out" "extract #9"
assert "finds missing extract"  1 "$rc" "$out" "row #2 has no CLAUDE.md extract"
assert "finds no maintenance"   1 "$rc" "$out" "maintenance block"

# Single-violation fixtures: each isolates exactly one check so a broken
# check 3 or check 4 cannot hide behind checks 1/2/5 also firing on the same
# fixture (review finding: bad-project alone cannot prove checks 3/4 work).
out=$(cd tests/fixtures/dead-pointer-only && DOC_LINT_LOG=0 BUDGET_CLAUDE=5000 BUDGET_PLAN=5000 sh ../../../scripts/doc-lint.sh); rc=$?
assert "dead-pointer-only fails alone" 1 "$rc" "$out" "unresolved pointer"

out=$(cd tests/fixtures/orphan-extract-only && DOC_LINT_LOG=0 BUDGET_CLAUDE=5000 BUDGET_PLAN=5000 sh ../../../scripts/doc-lint.sh); rc=$?
assert "orphan-extract-only fails alone" 1 "$rc" "$out" "extract #7"

out=$(cd tests/fixtures/missing-extract-only && DOC_LINT_LOG=0 BUDGET_CLAUDE=5000 BUDGET_PLAN=5000 sh ../../../scripts/doc-lint.sh); rc=$?
assert "missing-extract-only fails alone" 1 "$rc" "$out" "row #3 has no CLAUDE.md extract"
assert "retired row is exempt" 1 "$rc" "$out" ""
if printf '%s' "$out" | grep -q "row #4"; then
  echo "FAIL: retired LEDGER row #4 wrongly flagged"; fails=$((fails+1))
else
  echo "ok: retired row not flagged"
fi

out=$(cd tests/fixtures/missing-claude-md && DOC_LINT_LOG=0 BUDGET_CLAUDE=5000 BUDGET_PLAN=5000 sh ../../../scripts/doc-lint.sh); rc=$?
assert "missing CLAUDE.md fails" 1 "$rc" "$out" "CLAUDE.md is missing"

# Directive-count warning must never change the exit code (warn-only check 7).
out=$(cd tests/fixtures/good-project && DOC_LINT_LOG=0 DIRECTIVES_WARN=0 BUDGET_CLAUDE=5000 BUDGET_PLAN=5000 sh ../../../scripts/doc-lint.sh); rc=$?
assert "directive warn keeps exit 0" 0 "$rc" "$out" "doc-lint (warn)"

# Run log: writes docs/doc-lint-log.csv when enabled; scratch dir, cleaned.
rm -rf tests/tmp/log-check && mkdir -p tests/tmp/log-check
cp tests/fixtures/good-project/*.md tests/tmp/log-check/
out=$(cd tests/tmp/log-check && BUDGET_CLAUDE=5000 BUDGET_PLAN=5000 sh ../../../scripts/doc-lint.sh); rc=$?
if [ -f tests/tmp/log-check/docs/doc-lint-log.csv ] && [ "$(wc -l < tests/tmp/log-check/docs/doc-lint-log.csv | tr -d ' ')" = "2" ]; then
  echo "ok: run log written (header + one row)"
else
  echo "FAIL: run log missing or wrong shape"; fails=$((fails+1))
fi
rm -rf tests/tmp/log-check

# --- Checks 2/3/4 are single-pass rewrites of per-file / per-match subshell
# loops. The fixtures below pin the corners those loops had but the original
# six fixtures never exercised, so a future rewrite cannot quietly change
# them. Behaviours marked "as before" were verified byte-identical against
# the pre-rewrite script across all twelve fixtures.

# Check 3 semantics: two pointers on ONE line (the match-advance), a slug
# that is a PREFIX of a real one (the CHANGELOG trailing-space guard), a note
# resolving by filename with no heading at all, a note resolving by heading
# only, and a right-slug/wrong-date pointer (the date comes from the note's
# own filename, never the slug text).
out=$(cd tests/fixtures/pointer-edge && DOC_LINT_LOG=0 BUDGET_CLAUDE=5000 BUDGET_PLAN=5000 sh ../../../scripts/doc-lint.sh); rc=$?
assert "pointer-edge fails"                   1 "$rc" "$out" "unresolved pointer"
assert "2nd pointer on one line is scanned"   1 "$rc" "$out" "(deadsecond)"
assert "prefix slug does not resolve"         1 "$rc" "$out" "(alph)"
assert "wrong-date note does not resolve"     1 "$rc" "$out" "2026-08-09 (nameonly)"
count_is "exactly three unresolved" "$out" "unresolved pointer" 3
absent "changelog slug resolves"        "$out" "(alpha)"
absent "note resolves by filename only" "$out" "2026-08-05 (nameonly)"
absent "note resolves by heading only"  "$out" "(headingonly)"
# The pointer literal "→" is three bytes: awks differ on whether substr
# counts bytes or characters, so the byte-mode locale must agree exactly.
outc=$(cd tests/fixtures/pointer-edge && LC_ALL=C DOC_LINT_LOG=0 BUDGET_CLAUDE=5000 BUDGET_PLAN=5000 sh ../../../scripts/doc-lint.sh)
if [ "$out" = "$outc" ]; then echo "ok: LC_ALL=C output identical"
else echo "FAIL: output is locale-dependent"; fails=$((fails+1)); fi

# Check 2 mechanics: a token containing ':' must not be mistaken for the
# grep filename delimiter, repeats collapse, and one line is emitted per
# file (not per token) with tokens in sort order.
out=$(cd tests/fixtures/token-edge && DOC_LINT_LOG=0 BUDGET_CLAUDE=5000 BUDGET_PLAN=5000 sh ../../../scripts/doc-lint.sh); rc=$?
assert "token-edge fails"              1 "$rc" "$out" "unfilled token"
assert "colon inside a token survives" 1 "$rc" "$out" "{{BAR:BAZ}}"
assert "tokens in sort order"          1 "$rc" "$out" "{{BAR:BAZ}} {{FOO}}"
count_is "repeated token reported once" "$out" "{{FOO}}"           1
count_is "one token line per file"      "$out" "unfilled token in" 1

# Duplicates are DATA, not noise: a repeated LEDGER row number yields a
# repeated finding, as before. Pinned so a future dedupe is a conscious call.
out=$(cd tests/fixtures/dup-active && DOC_LINT_LOG=0 BUDGET_CLAUDE=5000 BUDGET_PLAN=5000 sh ../../../scripts/doc-lint.sh); rc=$?
assert "dup-active fails" 1 "$rc" "$out" "row #5 has no CLAUDE.md extract"
count_is "duplicate row reported twice" "$out" "row #5 has no" 2

# Ordering: findings and tokens are sorted per file, NOT in document order.
# Fixture puts {{ZED}} before {{ALPHA}} and (zulu-dead) before (aaa-dead).
out=$(cd tests/fixtures/order-hostile && DOC_LINT_LOG=0 BUDGET_CLAUDE=5000 BUDGET_PLAN=5000 sh ../../../scripts/doc-lint.sh); rc=$?
assert "order-hostile fails"      1 "$rc" "$out" "unresolved pointer"
assert "tokens sorted, not doc order" 1 "$rc" "$out" "{{ALPHA}} {{ZED}}"
first=$(printf '%s\n' "$out" | grep "unresolved" | head -1)
assert "findings sorted, not doc order" 1 "$rc" "$first" "(aaa-dead)"
count_is "duplicate extract reported twice" "$out" "extract #7 has no" 2
absent "Retired row exempt from 4b" "$out" "row #1"

# Check 4's two directions match rows DIFFERENTLY, and always did: 4a's row
# lookup is rigid ("| N |", single spaces) while 4b's Active capture is
# padding-tolerant. A padded row therefore fails 4a while 4b still sees it.
# Preserved deliberately — pinned here so the asymmetry stays visible.
out=$(cd tests/fixtures/ledger-spacing && DOC_LINT_LOG=0 BUDGET_CLAUDE=5000 BUDGET_PLAN=5000 sh ../../../scripts/doc-lint.sh); rc=$?
assert "padded row fails rigid 4a" 1 "$rc" "$out" "extract #7 has no LEDGER.md row"
assert "missing extract found"     1 "$rc" "$out" "row #8 has no CLAUDE.md extract"
absent "no 4b double-report on padded row" "$out" "row #7 has no"

# Scale: a 2500-entry (~176 KB) CHANGELOG. The rewrite feeds the index to awk
# as input FILES rather than through the environment, so Windows' 32 KB
# environment block is never in play. Also a rough perf canary.
out=$(cd tests/fixtures/big-changelog && DOC_LINT_LOG=0 BUDGET_CLAUDE=50000 BUDGET_PLAN=5000 sh ../../../scripts/doc-lint.sh); rc=$?
assert "big-changelog finds dead pointer" 1 "$rc" "$out" "(slug-9999)"
absent "resolves at scale" "$out" "(slug-1234)"

# --- doc-lint-hook.sh: the optional Stop-hook wrapper. Its whole job is
# translating doc-lint's exit code into the Stop-hook protocol (0 = let the
# turn end, 2 + stderr = block and hand the message to Claude), so the exit
# codes ARE the contract and each one is asserted directly.
HOOK=$(pwd)/scripts/doc-lint-hook.sh
rm -rf tests/tmp/hook && mkdir -p tests/tmp/hook/scripts
cp scripts/doc-lint.sh tests/tmp/hook/scripts/
cp tests/fixtures/good-project/*.md tests/tmp/hook/
HP=$(pwd)/tests/tmp/hook

# Streams are kept SEPARATE. The hook's whole contract is that the message
# for Claude goes to stderr — on a blocking Stop hook, stdout does not reach
# Claude — so a harness that merged them with 2>&1 would still pass if the
# `>&2` were deleted, which is the one regression that matters most here.
hook_run() { # $1 = stdin JSON; echoes "<exit>|<stderr>" (stdout discarded)
  o=$(printf '%s' "$1" | CLAUDE_PROJECT_DIR="$HP" BUDGET_CLAUDE=5000 BUDGET_PLAN=5000 sh "$HOOK" 2>&1 1>/dev/null); printf '%s|%s' "$?" "$o"
}
hook_stdout() { # $1 = stdin JSON; echoes stdout only
  printf '%s' "$1" | CLAUDE_PROJECT_DIR="$HP" BUDGET_CLAUDE=5000 BUDGET_PLAN=5000 sh "$HOOK" 2>/dev/null
}
hook_expect() { # $1 desc, $2 stdin JSON, $3 expected exit, $4 expect-silent (yes/no)
  r=$(hook_run "$2"); e=${r%%|*}; o=${r#*|}
  if [ "$e" != "$3" ]; then echo "FAIL: $1 (exit $e, wanted $3)"; fails=$((fails+1)); return; fi
  if [ "$4" = yes ] && [ -n "$o" ]; then echo "FAIL: $1 (expected silence, got: $o)"; fails=$((fails+1)); return; fi
  if [ "$4" = no ] && [ -z "$o" ]; then echo "FAIL: $1 (expected output, got none)"; fails=$((fails+1)); return; fi
  echo "ok: $1"
}

# Clean project: the turn must end with nothing said at all. This is the
# common case and the entire point of running the lint from a hook.
hook_expect "hook silent on clean project" '{"stop_hook_active":false}' 0 yes
# The hook must not write the run log: that log is one row per bookkeeping
# pass, and a hook firing every turn would bury the signal and dirty the tree.
if [ -f tests/tmp/hook/docs/doc-lint-log.csv ]; then
  echo "FAIL: hook wrote the run log"; fails=$((fails+1))
else echo "ok: hook does not write the run log"; fi

# Break the fixture, then assert the blocking path.
sed -i 's/^## Maintenance/## Maintenanc/' tests/tmp/hook/CLAUDE.md
hook_expect "hook blocks on findings" '{"stop_hook_active":false}' 2 no
# Pass the REAL exit code to assert. Hardcoding the expected and actual both
# to 2 makes the exit comparison unfalsifiable, leaving only the string match:
# the hook could regress to exit 0 (findings narrated, turn not blocked) and
# these would still report ok.
r=$(hook_run '{"stop_hook_active":false}'); e=${r%%|*}; o=${r#*|}
assert "block message carries the findings" 2 "$e" "$o" "maintenance block missing"
assert "block message names the budget escape" 2 "$e" "$o" "over budget"
assert "block message names the retrofit escape" 2 "$e" "$o" "already had before"
assert "block message admits it will not re-run" 2 "$e" "$o" "will not run again this turn"
# The message must be on STDERR specifically: stdout is not delivered to
# Claude when a Stop hook blocks, so a message printed there is lost.
so=$(hook_stdout '{"stop_hook_active":false}')
if [ -z "$so" ]; then echo "ok: block message goes to stderr, not stdout"
else echo "FAIL: hook wrote to stdout (invisible to Claude): $so"; fails=$((fails+1)); fi
# Loop guard: the Stop event AFTER a block sets stop_hook_active=true. Without
# this, a finding Claude cannot fix alone (over budget) blocks every turn until
# Claude Code's own block cap stops it.
hook_expect "loop guard stops a second block" '{"stop_hook_active":true}' 0 yes
hook_expect "loop guard tolerates JSON spacing" '{ "stop_hook_active" : true }' 0 yes
# A repo without the lint installed must be left completely alone.
rm -rf tests/tmp/hook-empty && mkdir -p tests/tmp/hook-empty
o=$(printf '{"stop_hook_active":false}' | CLAUDE_PROJECT_DIR="$(pwd)/tests/tmp/hook-empty" sh "$HOOK" 2>&1); e=$?
if [ "$e" = 0 ] && [ -z "$o" ]; then echo "ok: hook ignores a non-project-docs repo"
else echo "FAIL: hook acted on a repo with no lint (exit $e: $o)"; fails=$((fails+1)); fi
# A repo that SHIPS the lint without being linted by it — this skill's own
# repo is the case — must also be left alone. Guarding on the script alone
# would block every turn on "CLAUDE.md is missing" with nothing to fix.
rm -rf tests/tmp/hook-noclaude && mkdir -p tests/tmp/hook-noclaude/scripts
cp scripts/doc-lint.sh tests/tmp/hook-noclaude/scripts/
o=$(printf '{"stop_hook_active":false}' | CLAUDE_PROJECT_DIR="$(pwd)/tests/tmp/hook-noclaude" sh "$HOOK" 2>&1); e=$?
if [ "$e" = 0 ] && [ -z "$o" ]; then echo "ok: hook ignores a repo shipping the lint without using it"
else echo "FAIL: hook blocked a repo with no CLAUDE.md (exit $e: $o)"; fails=$((fails+1)); fi
rm -rf tests/tmp/hook tests/tmp/hook-empty tests/tmp/hook-noclaude

[ "$fails" -eq 0 ] && echo "ALL PASS" || echo "$fails FAILURES"
exit "$fails"
