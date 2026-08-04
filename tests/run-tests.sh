#!/bin/sh
# Test harness for doc-lint.sh. Run from the skill root: sh tests/run-tests.sh
fails=0
assert() { # $1 desc, $2 expected-exit, $3 actual-exit, $4 output, $5 must-contain (empty = skip)
  if [ "$2" != "$3" ]; then echo "FAIL: $1 (exit $3, wanted $2)"; fails=$((fails+1)); return; fi
  if [ -n "$5" ] && ! printf '%s' "$4" | grep -q "$5"; then
    echo "FAIL: $1 (output missing: $5)"; fails=$((fails+1)); return; fi
  echo "ok: $1"
}

out=$(cd tests/fixtures/good-project && BUDGET_CLAUDE=5000 BUDGET_PLAN=5000 sh ../../../scripts/doc-lint.sh); rc=$?
assert "good project passes" 0 "$rc" "$out" ""

out=$(cd tests/fixtures/bad-project && BUDGET_CLAUDE=300 BUDGET_PLAN=5000 sh ../../../scripts/doc-lint.sh); rc=$?
assert "bad project fails" 1 "$rc" "$out" ""
assert "finds over-budget"      1 "$rc" "$out" "over budget"
assert "finds unfilled token"   1 "$rc" "$out" "unfilled"
assert "finds dead pointer"     1 "$rc" "$out" "unresolved pointer"
assert "finds circular pointer" 1 "$rc" "$out" "ledger-only-slug"
assert "finds orphan extract"   1 "$rc" "$out" "extract #9"
assert "finds no maintenance"   1 "$rc" "$out" "maintenance block"

# Single-violation fixtures: each isolates exactly one check so a broken
# check 3 or check 4 cannot hide behind checks 1/2/5 also firing on the same
# fixture (review finding: bad-project alone cannot prove checks 3/4 work).
out=$(cd tests/fixtures/dead-pointer-only && BUDGET_CLAUDE=5000 BUDGET_PLAN=5000 sh ../../../scripts/doc-lint.sh); rc=$?
assert "dead-pointer-only fails alone" 1 "$rc" "$out" "unresolved pointer"

out=$(cd tests/fixtures/orphan-extract-only && BUDGET_CLAUDE=5000 BUDGET_PLAN=5000 sh ../../../scripts/doc-lint.sh); rc=$?
assert "orphan-extract-only fails alone" 1 "$rc" "$out" "extract #7"

out=$(cd tests/fixtures/missing-claude-md && BUDGET_CLAUDE=5000 BUDGET_PLAN=5000 sh ../../../scripts/doc-lint.sh); rc=$?
assert "missing CLAUDE.md fails" 1 "$rc" "$out" "CLAUDE.md is missing"

[ "$fails" -eq 0 ] && echo "ALL PASS" || echo "$fails FAILURES"
exit "$fails"
