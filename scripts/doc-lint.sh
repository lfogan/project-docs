#!/bin/sh
# doc-lint.sh — project-docs system lint. Run from the target project root.
# Env: BUDGET_CLAUDE, BUDGET_PLAN (bytes). Exit 0 clean; exit 1 with findings.
BUDGET_CLAUDE="${BUDGET_CLAUDE:-35000}"
BUDGET_PLAN="${BUDGET_PLAN:-80000}"
fail=0
note() { echo "doc-lint: $1"; fail=1; }

# 1. byte budgets (always-loaded files only)
for f_b in "CLAUDE.md $BUDGET_CLAUDE" "PLAN.md $BUDGET_PLAN"; do
  f=${f_b% *}; b=${f_b#* }
  if [ -f "$f" ]; then
    sz=$(wc -c < "$f" | tr -d ' ')
    [ "$sz" -gt "$b" ] && note "$f over budget ($sz > $b bytes)"
  fi
done

# 2. unfilled template tokens
for f in CLAUDE.md PLAN.md CHANGELOG.md LEDGER.md TARGETS.md AGENTS.md; do
  [ -f "$f" ] && grep -n "{{[A-Za-z_]*}}" "$f" >/dev/null 2>&1 && note "unfilled token in $f: $(grep -o '{{[A-Za-z_]*}}' "$f" | head -1)"
done

# 3. pointers resolve to a REAL target: "→ CL YYYY-MM-DD (slug)" needs an entry
#    line "- YYYY-MM-DD slug" in CHANGELOG*.md, or a docs/notes/ file whose
#    name or "# " heading carries the slug. LEDGER.md is NOT a target: pointer
#    text inside its rows would self-resolve dead pointers.
for f in CLAUDE.md PLAN.md LEDGER.md TARGETS.md; do
  [ -f "$f" ] || continue
  grep -o "→ CL [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9] ([a-z0-9-]*)" "$f" 2>/dev/null |
  while IFS= read -r p; do
    d=$(printf '%s' "$p" | sed 's/→ CL \([0-9-]*\) .*/\1/')
    s=$(printf '%s' "$p" | sed 's/.*(\(.*\))/\1/')
    if ! grep -q -- "- $d $s" CHANGELOG*.md 2>/dev/null \
       && ! { ls docs/notes 2>/dev/null | grep -q -- "$s"; } \
       && ! grep -q -- "^# .*$s" docs/notes/*.md 2>/dev/null; then
      echo "doc-lint: unresolved pointer in $f: $p"
    fi
  done | sort -u | { any=0; while IFS= read -r l; do echo "$l"; any=1; done; [ "$any" -eq 1 ] && exit 9; exit 0; } || fail=1
done

# 4. every CLAUDE.md extract "#N:" has a LEDGER.md row "| N |"
if [ -f CLAUDE.md ] && [ -f LEDGER.md ]; then
  grep -o "^#[0-9]*:" CLAUDE.md 2>/dev/null | tr -d '#:' | while IFS= read -r n; do
    grep -q "^| $n |" LEDGER.md || echo "doc-lint: extract #$n has no LEDGER.md row"
  done | { any=0; while IFS= read -r l; do echo "$l"; any=1; done; [ "$any" -eq 1 ] && exit 9; exit 0; } || fail=1
fi

# 5. maintenance block present
[ -f CLAUDE.md ] && ! grep -q "^## Maintenance" CLAUDE.md && note "maintenance block missing from CLAUDE.md"

exit "$fail"
