#!/bin/sh
# doc-lint.sh — project-docs system lint. Run from the target project root.
# Env: BUDGET_CLAUDE, BUDGET_PLAN (bytes); DIRECTIVES_WARN (count, warn only);
#      DOC_LINT_LOG=0 disables the run log.
# Exit 0 clean; exit 1 with findings. Warnings never affect the exit code.
BUDGET_CLAUDE="${BUDGET_CLAUDE:-45000}"
BUDGET_PLAN="${BUDGET_PLAN:-80000}"
DIRECTIVES_WARN="${DIRECTIVES_WARN:-75}"
fail=0
findings=0
note() { echo "doc-lint: $1"; fail=1; findings=$((findings+1)); }
warn() { echo "doc-lint (warn): $1"; }
emit() { # $1 = newline-separated findings from a subshell loop, possibly empty
  [ -n "$1" ] || return 0
  printf '%s\n' "$1"
  fail=1
  findings=$((findings + $(printf '%s\n' "$1" | grep -c .)))
}

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
#    one per lint round. Includes docs/design/STATUS.md (module file), so a
#    stray token there no longer needs a by-hand check.
for f in CLAUDE.md PLAN.md CHANGELOG.md LEDGER.md TARGETS.md AGENTS.md docs/design/STATUS.md; do
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
  emit "$out"
done

# 4. extract ↔ row match, BOTH directions. 4a: every CLAUDE.md extract "#N:"
#    has a LEDGER.md row "| N |" (a bookkeeping defect). 4b: every Active
#    LEDGER.md row has a CLAUDE.md extract — the behaviorally dangerous
#    direction: an Active decision with no extract is invisible to every
#    session. Retired rows are exempt. Command substitution as in check 3.
if [ -f CLAUDE.md ] && [ -f LEDGER.md ]; then
  out=$(grep -o "^#[0-9]*:" CLAUDE.md 2>/dev/null | tr -d '#:' | while IFS= read -r n; do
    grep -q "^| $n |" LEDGER.md || echo "doc-lint: extract #$n has no LEDGER.md row"
  done)
  emit "$out"
  out=$(grep "^| *[0-9][0-9]* *| *Active" LEDGER.md 2>/dev/null | sed 's/^| *\([0-9][0-9]*\) *|.*/\1/' | while IFS= read -r n; do
    grep -q "^#$n:" CLAUDE.md || echo "doc-lint: Active LEDGER.md row #$n has no CLAUDE.md extract"
  done)
  emit "$out"
fi

# 5. maintenance block present
[ -f CLAUDE.md ] && ! grep -q "^## Maintenance" CLAUDE.md && note "maintenance block missing from CLAUDE.md"

# 6. CLAUDE.md must exist — an empty or botched generation must not lint
#    clean just because every other check above is guarded by [ -f ... ].
[ -f CLAUDE.md ] || note "CLAUDE.md is missing"

# 7. directive count (WARN only, never fails the run): the byte budget is the
#    contract, but rule-following dilutes with the NUMBER of active
#    directives, and one-line-per-rule compression raises directives per
#    byte. Counts bullet/numbered/extract lines in CLAUDE.md.
dirs=0
if [ -f CLAUDE.md ]; then
  dirs=$(grep -E -c "^(- |[0-9]+\. |#[0-9]+:)" CLAUDE.md)
  [ "$dirs" -gt "$DIRECTIVES_WARN" ] && warn "CLAUDE.md carries $dirs directive lines (> $DIRECTIVES_WARN) — every added rule dilutes the others; consolidate or retire before adding more"
fi

# 8. run log (never a finding): one CSV row per run appended to
#    docs/doc-lint-log.csv — the trend the checks alone cannot show: failure
#    rate and budget headroom over time. DOC_LINT_LOG=0 skips it (tests).
if [ "${DOC_LINT_LOG:-1}" != "0" ]; then
  cb=0; pb=0
  [ -f CLAUDE.md ] && cb=$(wc -c < CLAUDE.md | tr -d ' ')
  [ -f PLAN.md ] && pb=$(wc -c < PLAN.md | tr -d ' ')
  mkdir -p docs 2>/dev/null
  [ -f docs/doc-lint-log.csv ] || echo "date,exit,findings,claude_bytes,plan_bytes,directives" > docs/doc-lint-log.csv 2>/dev/null
  echo "$(date +%Y-%m-%d),$fail,$findings,$cb,$pb,$dirs" >> docs/doc-lint-log.csv 2>/dev/null
fi

exit "$fail"
