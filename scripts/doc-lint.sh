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

# 2. unfilled template tokens: any surviving {{...}}, not just identifier-
#    shaped ones — reports every distinct token in a file in one line, not
#    one per lint round.
for f in CLAUDE.md PLAN.md CHANGELOG.md LEDGER.md TARGETS.md AGENTS.md; do
  [ -f "$f" ] || continue
  toks=$(grep -o '{{[^}]*}}' "$f" 2>/dev/null | sort -u | tr '\n' ' ' | sed 's/ *$//')
  [ -n "$toks" ] && note "unfilled token in $f: $toks"
done

# 3. pointers resolve to a REAL target: "→ CL YYYY-MM-DD (slug)" needs an
#    entry LINE "- YYYY-MM-DD slug " in CHANGELOG*.md, or a docs/notes/ file
#    following the docs/notes/YYYY-MM-DD-<slug>.md convention whose name or
#    "# " heading carries the slug — the date always comes from that file's
#    own name, never from the slug text alone. LEDGER.md is NOT a resolution
#    target: pointer text inside its own rows would self-resolve dead
#    pointers. Uses command substitution (not a trailing pipeline subshell)
#    so failure propagates on every shell, including lastpipe ones.
for f in CLAUDE.md PLAN.md LEDGER.md TARGETS.md; do
  [ -f "$f" ] || continue
  out=$(grep -o "→ CL [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9] ([a-z0-9-]*)" "$f" 2>/dev/null | while IFS= read -r p; do
    d=$(printf '%s' "$p" | sed 's/→ CL \([0-9-]*\) .*/\1/')
    s=$(printf '%s' "$p" | sed 's/.*(\(.*\))/\1/')
    resolved=0
    grep -q "^- $d $s " CHANGELOG*.md 2>/dev/null && resolved=1
    for nf in docs/notes/"$d"-*.md; do
      [ -f "$nf" ] || continue
      case "$nf" in *"$s"*) resolved=1 ;; esac
      grep -q "^# .*$s" "$nf" 2>/dev/null && resolved=1
    done
    [ "$resolved" -eq 0 ] && echo "doc-lint: unresolved pointer in $f: $p"
  done | sort -u)
  [ -n "$out" ] && { printf '%s\n' "$out"; fail=1; }
done

# 4. every CLAUDE.md extract "#N:" has a LEDGER.md row "| N |". Uses command
#    substitution for the same cross-shell reason as check 3.
if [ -f CLAUDE.md ] && [ -f LEDGER.md ]; then
  out=$(grep -o "^#[0-9]*:" CLAUDE.md 2>/dev/null | tr -d '#:' | while IFS= read -r n; do
    grep -q "^| $n |" LEDGER.md || echo "doc-lint: extract #$n has no LEDGER.md row"
  done)
  [ -n "$out" ] && { printf '%s\n' "$out"; fail=1; }
fi

# 5. maintenance block present
[ -f CLAUDE.md ] && ! grep -q "^## Maintenance" CLAUDE.md && note "maintenance block missing from CLAUDE.md"

# 6. CLAUDE.md must exist — an empty or botched generation must not lint
#    clean just because every other check above is guarded by [ -f ... ].
[ -f CLAUDE.md ] || note "CLAUDE.md is missing"

exit "$fail"
