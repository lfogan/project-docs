#!/bin/sh
# doc-lint.sh — project-docs v2 lint. Run from the repo root; the installed
# .githooks/pre-commit runs it on every commit.
#
# v2 contract: every check hard-fails. Advisory checks are banned by design —
# the v1 system's only warning was ignored on 42 consecutive runs while its
# hard failures were fixed same-day (see references/methodology.md). A check
# either blocks the commit or it does not exist.
#
# Env: BUDGET_CLAUDE (bytes, default 6000), RULES_CAP (default 25),
#      DOC_LINT_LOG=0 disables the CSV row.
# The design-approval gate lives in .githooks/commit-msg — it needs the commit
# message, which pre-commit never sees. Everything else is here.
BUDGET_CLAUDE="${BUDGET_CLAUDE:-6000}"
RULES_CAP="${RULES_CAP:-25}"
fail=0
findings=0
note() { echo "doc-lint: $1"; fail=1; findings=$((findings+1)); }
emit() { # $1 = newline-separated findings, possibly empty
  [ -n "$1" ] || return 0
  printf '%s\n' "$1"
  fail=1
  findings=$((findings + $(printf '%s\n' "$1" | grep -c .)))
}

# 1. CLAUDE.md exists, fits the cap, imports nothing. The file IS the whole
#    hot set — an @-import would smuggle bytes past the only measured number.
if [ -f CLAUDE.md ]; then
  sz=$(wc -c < CLAUDE.md | tr -d ' ')
  [ "$sz" -gt "$BUDGET_CLAUDE" ] && note "CLAUDE.md over cap ($sz > $BUDGET_CLAUDE bytes) — retire or relocate before adding"
  grep -nE '(^|[[:space:]])@([.~/]|[A-Za-z0-9_-]+/)' CLAUDE.md >/dev/null 2>&1 \
    && note "CLAUDE.md uses @-imports — forbidden: the file is the whole hot set"
else
  note "CLAUDE.md is missing"
fi

# 2a. Rules section: every content line is an R-line; R-lines <= cap.
#     Section runs from '## Rules' to the next '## ' heading. HTML comments
#     and blank lines are free; anything else must match '^R<n>: '.
if [ -f CLAUDE.md ]; then
  out=$(awk -v cap="$RULES_CAP" '
    /^## Rules$/ { insec=1; next }
    insec && /^## / { insec=0 }
    !insec { next }
    {
      if (incmt) { if (index($0, "-->")) incmt = 0; next }
      if ($0 ~ /^[[:space:]]*$/) next
      if (index($0, "<!--")) { if (!index($0, "-->")) incmt = 1; next }
      if ($0 ~ /^R[0-9]+: /) { n++; next }
      print "doc-lint: non-R line in Rules section (grammar R<n>: ...): " substr($0, 1, 60)
    }
    END { if (n > cap) print "doc-lint: " n " R-lines exceed the cap (" cap ") — retire one to add one" }
  ' CLAUDE.md)
  emit "$out"
fi

# 2b. SETTLED grammar: every content line is one Don't-line —
#     starts "- Don't ", carries "settled YYYY-MM-DD (", ends ")".
#     One-line entries make narrative structurally impossible.
if [ -f docs/SETTLED.md ]; then
  out=$(awk '
    {
      if (incmt) { if (index($0, "-->")) incmt = 0; next }
      if ($0 ~ /^[[:space:]]*$/ || $0 ~ /^# /) next
      if (index($0, "<!--")) { if (!index($0, "-->")) incmt = 1; next }
      ok = ($0 ~ /^- Don.t /) \
        && ($0 ~ / settled [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9] \(/) \
        && ($0 ~ /\)$/)
      if (!ok) print "doc-lint: SETTLED line breaks grammar (- Don'"'"'t <x> — settled YYYY-MM-DD (<why>)): " substr($0, 1, 60)
    }
  ' docs/SETTLED.md)
  emit "$out"
fi

# 3a. TODO drain: a finished row leaves TODO.md the moment it is marked, moved
#     verbatim to DONE.md. A [done] row that lingers is the PLAN graveyard
#     coming back — TODO.md is read every session, so its size is the cost.
if [ -f TODO.md ]; then
  out=$(grep -nE '\[[xX]\]|\[[Dd]one|\[DONE' TODO.md 2>/dev/null \
    | sed 's/^/doc-lint: done row still in TODO.md (move it verbatim to DONE.md): /')
  emit "$out"
fi

# 3b. DONE.md stays an archive of rows, not a changelog. Rows arrive verbatim,
#     one line each. The two things that turned v1's task list into 258 KB of
#     unread prose were multi-line entries and What/Why/Evidence/Limits keys,
#     so both are rejected here. Length cap makes narrative impossible rather
#     than merely discouraged.
if [ -f DONE.md ]; then
  out=$(awk '
    {
      if (incmt) { if (index($0, "-->")) incmt = 0; next }
      if ($0 ~ /^[[:space:]]*$/ || $0 ~ /^#/) next
      if (index($0, "<!--")) { if (!index($0, "-->")) incmt = 1; next }
      if ($0 ~ /^(What|Why|Evidence|Limits|Origin|Changes):/) {
        print "doc-lint: DONE.md line " NR " uses a changelog key (" $1 ") — rows move verbatim, they do not grow a story"
        next
      }
      if ($0 !~ /^- /) {
        print "doc-lint: DONE.md line " NR " is not a task row (must start \"- \"): " substr($0, 1, 50)
        next
      }
      if (length($0) > 300)
        print "doc-lint: DONE.md line " NR " is " length($0) " chars (> 300) — move rows verbatim, do not enrich them"
    }' DONE.md)
  emit "$out"
fi

# 4. Forbidden v1 files: history lives in git, decisions in docs/SETTLED.md,
#    state in TODO.md. Agents imitate repo history — without this check the
#    old files regrow from muscle memory.
for f in CHANGELOG*.md LEDGER.md PLAN.md DEVIATIONS.md \
         docs/CHANGELOG*.md docs/LEDGER.md docs/PLAN.md docs/DEVIATIONS.md; do
  [ -f "$f" ] && note "forbidden v1 file: $f — history=git, decisions=docs/SETTLED.md, state=TODO.md"
done

# 5. Paths referenced by CLAUDE.md resolve. A pointer to a missing file is the
#    purest "agent reads it and gets confused" bug. Candidates: the first
#    token of each Pointers bullet (when path-shaped), plus every docs/ or
#    scripts/ token anywhere in the file (trailing glob stars stripped).
if [ -f CLAUDE.md ]; then
  cands=$( { awk '
      /^## Pointers$/ { insec=1; next }
      insec && /^## / { insec=0 }
      insec && /^- / {
        line = $0; sub(/^- /, "", line)
        split(line, a, " "); t = a[1]
        gsub(/\*+$/, "", t); sub(/[.,;:]$/, "", t)
        if (t ~ /^[A-Za-z0-9_.\/-]+$/ && (index(t, "/") || t ~ /\.md$/)) print t
      }' CLAUDE.md
      grep -oE '(docs|scripts)/[A-Za-z0-9_./-]*[A-Za-z0-9]' CLAUDE.md
    } | sort -u)
  out=""
  for p in $cands; do
    [ -e "$p" ] || out="${out}doc-lint: CLAUDE.md references missing path: $p
"
  done
  emit "$out"
fi

# 6. Required sections present. Learned from the field: a generated file
#    silently missing Commands & Layout cost every session a re-discovery
#    and nothing noticed for five days.
if [ -f CLAUDE.md ]; then
  for h in "## Commands & Layout" "## Rules" "## Pointers"; do
    grep -q "^$h" CLAUDE.md || note "required section missing from CLAUDE.md: $h"
  done
fi

# 7. No unfilled template tokens in any v2 doc file.
out=$(grep -n '{{[A-Za-z_]*}}' CLAUDE.md AGENTS.md TODO.md DONE.md docs/SETTLED.md \
      docs/design/DESIGN.md docs/agent/*.md /dev/null 2>/dev/null \
  | sed 's/^/doc-lint: unfilled template token: /')
emit "$out"

# 8. Run log (never a finding). One row per run; the pre-commit hook stages it
#    so the row rides inside the commit. Trend semantics: rules_count healthy
#    DOWN (lessons graduating to tests/hooks), docs_touched share healthy DOWN
#    (less ceremony), settled_lines slow UP only on real owner "no"s.
if [ "${DOC_LINT_LOG:-1}" != "0" ]; then
  cb=0; tb=0; db=0; sl=0; ab=0; rc=0; dt="-"
  [ -f CLAUDE.md ] && cb=$(wc -c < CLAUDE.md | tr -d ' ')
  [ -f TODO.md ] && tb=$(wc -c < TODO.md | tr -d ' ')
  [ -f DONE.md ] && db=$(grep -c "^- " DONE.md)
  [ -f docs/SETTLED.md ] && sl=$(grep -c "^- Don" docs/SETTLED.md)
  ab=$(cat docs/agent/*.md 2>/dev/null | wc -c | tr -d ' ')
  [ -f CLAUDE.md ] && rc=$(grep -cE '^R[0-9]+: ' CLAUDE.md)
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    if git diff --cached --name-only 2>/dev/null \
       | grep -qE '^(CLAUDE\.md|TODO\.md|AGENTS\.md|docs/SETTLED\.md|docs/agent/|docs/design/)'; then
      dt=1
    else
      dt=0
    fi
  fi
  mkdir -p docs 2>/dev/null
  [ -f docs/doc-lint-log.csv ] || echo "date,exit,findings,claude_bytes,todo_bytes,done_rows,settled_lines,agent_bytes,rules_count,rules_cap,docs_touched" > docs/doc-lint-log.csv 2>/dev/null
  echo "$(date +%Y-%m-%d),$fail,$findings,$cb,$tb,$db,$sl,$ab,$rc,$RULES_CAP,$dt" >> docs/doc-lint-log.csv 2>/dev/null
fi

exit "$fail"
