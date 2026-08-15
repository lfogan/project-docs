#!/bin/sh
# Test harness for doc-lint.sh. Run from the skill root: sh tests/run-tests.sh
# DOC_LINT_LOG=0 on every invocation: fixtures must never accrue run-log files.
fails=0
assert() { # $1 desc, $2 expected-exit, $3 actual-exit, $4 output, $5 must-contain (empty = skip)
  if [ "$2" != "$3" ]; then echo "FAIL: $1 (exit $3, wanted $2)"; fails=$((fails+1)); return; fi
  if [ -n "$5" ] && ! printf '%s' "$4" | grep -q "$5"; then
    echo "FAIL: $1 (output missing: $5)"; fails=$((fails+1)); return; fi
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

[ "$fails" -eq 0 ] && echo "ALL PASS" || echo "$fails FAILURES"
exit "$fails"
