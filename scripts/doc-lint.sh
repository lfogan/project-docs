#!/bin/sh
# doc-lint.sh — project-docs system lint. Run from the target project root.
# Env: BUDGET_CLAUDE, BUDGET_PLAN (bytes); DIRECTIVES_WARN (count, warn only);
#      DOC_LINT_LOG=0 disables the run log.
# Exit 0 clean; exit 1 with findings. Warnings never affect the exit code.
#
# Checks 2, 3 and 4 are single-pass rewrites of per-file / per-match subshell
# loops. Motivation, measured on the dev box (Git Bash / MSYS): the loops cost
# process spawns, not work (check 3 alone ~1.1s of a 2.5s clean run), and the
# per-pointer nested command substitutions intermittently DEADLOCK under MSYS
# fork storms (observed repeatedly, always at that site). Output is
# byte-identical to the loop version — same text, same order, same duplicate
# behavior, same findings count, same exit — verified by an identity harness
# across all fixtures. Ordering that the old code got from per-file sort -u is
# reproduced with the same sort(1), not reimplemented in awk, so collation
# cannot drift. No {n} interval regexes, no multibyte-sensitive offsets: the
# pointer arrow (3 bytes) is matched as explicit bytes and sliced via
# RSTART/RLENGTH only, so byte-counting and character-counting awks agree.
BUDGET_CLAUDE="${BUDGET_CLAUDE:-45000}"
BUDGET_PLAN="${BUDGET_PLAN:-80000}"
DIRECTIVES_WARN="${DIRECTIVES_WARN:-75}"
fail=0
findings=0
note() { echo "doc-lint: $1"; fail=1; findings=$((findings+1)); }
warn() { echo "doc-lint (warn): $1"; }
emit() { # $1 = newline-separated findings, possibly empty
  [ -n "$1" ] || return 0
  printf '%s\n' "$1"
  fail=1
  findings=$((findings + $(printf '%s\n' "$1" | grep -c .)))
}
D='[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]'   # date, longhand (no {n})

# 1. byte budgets (always-loaded files only)
for f_b in "CLAUDE.md $BUDGET_CLAUDE" "PLAN.md $BUDGET_PLAN"; do
  f=${f_b% *}; b=${f_b#* }
  if [ -f "$f" ]; then
    sz=$(wc -c < "$f" | tr -d ' ')
    [ "$sz" -gt "$b" ] && note "$f over budget ($sz > $b bytes)"
  fi
done

# 2. unfilled template tokens. One grep over every existing file, one line of
#    findings per file (was 4 spawns x 7 files). /dev/null pads the arg list
#    so grep always prefixes filenames (no -H, which POSIX grep lacks).
#    Tokens are keyed "fileindex token" and deduped/ordered by the same
#    sort(1) the old per-file `sort -u` used; the second awk reassembles one
#    line per file, files in list order, tokens in sort order — byte-identical
#    to the loop this replaces. Filenames are the fixed list below (no spaces,
#    no colons), so first-colon and first-space splits are unambiguous.
set --
for f in CLAUDE.md PLAN.md CHANGELOG.md LEDGER.md TARGETS.md AGENTS.md docs/design/STATUS.md; do
  [ -f "$f" ] && set -- "$@" "$f"
done
if [ "$#" -gt 0 ]; then
  out=$(grep -o '{{[^}]*}}' "$@" /dev/null 2>/dev/null | awk '
    {
      p = index($0, ":"); f = substr($0, 1, p - 1); t = substr($0, p + 1)
      if (!(f in idx)) { idx[f] = ++n; print "0 " n " " f }
      print idx[f] " " t
    }' | sort -k1,1n -k2 -u | awk '
    $1 == "0" { name[$2] = $3; next }
    {
      t = substr($0, length($1) + 2)
      if ($1 != cur) {
        if (cur) print "doc-lint: unfilled token in " name[cur] ": " toks
        cur = $1; toks = t
      } else toks = toks " " t
    }
    END { if (cur) print "doc-lint: unfilled token in " name[cur] ": " toks }')
  emit "$out"
fi

# 3. pointers resolve to a REAL target. Semantics unchanged: a pointer
#    "→ CL YYYY-MM-DD (slug)" resolves via an entry LINE "- YYYY-MM-DD slug "
#    in CHANGELOG*.md (trailing space required, so a slug that is a prefix of
#    another cannot resolve), or a docs/notes/YYYY-MM-DD-<slug>.md whose PATH
#    or "# " heading carries the slug — the date always comes from that
#    file's own name, never from the slug text. LEDGER.md is NOT a resolution
#    target: pointer text inside its own rows would self-resolve dead
#    pointers.
#    One awk per source file (was ~8 spawns per POINTER — the MSYS deadlock
#    site). The index (changelog keys, note names from ARGV, note headings)
#    is rebuilt per source file from the files themselves — nothing large
#    rides in the environment, which Windows caps at 32K. Per-file
#    `| sort -u` and per-file emit exactly as before.
set --
for c in CHANGELOG*.md; do [ -f "$c" ] && set -- "$@" "$c"; done
for nf in docs/notes/*.md; do [ -f "$nf" ] && set -- "$@" "$nf"; done
for f in CLAUDE.md PLAN.md LEDGER.md TARGETS.md; do
  [ -f "$f" ] || continue
  out=$(awk -v D="$D" -v TGT="$f" '
    BEGIN {
      PTR = "\342\206\222 CL " D " \\([a-z0-9-]*\\)"   # → as explicit bytes
      # Note files bucketed by the date their own NAME starts with, from
      # ARGV so an empty note file still counts. "docs/notes/" is 11 ASCII
      # chars — safe under byte- and character-counting awks alike.
      for (i = 1; i < ARGC; i++) {
        a = ARGV[i]
        if (substr(a, 1, 11) == "docs/notes/" && match(substr(a, 12), "^" D "-"))
          nd[substr(a, 12, 10)] = nd[substr(a, 12, 10)] "\n" a
      }
    }
    FILENAME != TGT {
      if (FILENAME ~ /^CHANGELOG/) {
        # Entry key "DATE slug", first token after the date, trailing space
        # required — same as the old grep "^- $d $s ".
        if (match($0, "^- " D " [^ ]+ ")) cl[substr($0, 3, RLENGTH - 3)] = 1
      } else if (/^# /) hd[FILENAME] = hd[FILENAME] "\n" $0
      next
    }
    {
      line = $0
      while (match(line, PTR)) {
        ptr  = substr(line, RSTART, RLENGTH)        # slice, never an offset
        line = substr(line, RSTART + RLENGTH)
        d = ptr; sub(/^.*CL /, "", d); sub(/ .*$/, "", d)
        s = ptr; sub(/^.*\(/, "", s); sub(/\).*$/, "", s)
        if ((d " " s) in cl) continue
        resolved = 0
        m = split(nd[d], C, "\n")
        for (j = 1; j <= m && !resolved; j++) {
          if (C[j] == "") continue
          if (index(C[j], s)) { resolved = 1; break }
          k = split(hd[C[j]], H, "\n")
          for (q = 1; q <= k; q++)
            if (H[q] ~ ("^# .*" s)) { resolved = 1; break }
        }
        if (!resolved) print "doc-lint: unresolved pointer in " TGT ": " ptr
      }
    }' "$@" "$f" | sort -u)
  emit "$out"
done

# 4. extract <-> row match, BOTH directions, one pass over both files (was
#    one grep per extract and one per Active row). 4a: every CLAUDE.md
#    extract "#N:" has a LEDGER.md row "| N |". 4b: every Active LEDGER.md
#    row has a CLAUDE.md extract — the behaviorally dangerous direction: an
#    Active decision with no extract is invisible to every session. Retired
#    rows exempt. Duplicates are NOT collapsed — a doubled extract or row
#    yields a doubled finding, as before. 4a then 4b, each in source order.
#    Asymmetry preserved from the grep version: the 4a row lookup is RIGID
#    ("| N |", single spaces — grep "^| $n |"), while the 4b Active-row
#    capture is flexible ("| *N *| *Active"). A row padded "|  7  |"
#    therefore fails 4a even though 4b sees it — as before.
if [ -f CLAUDE.md ] && [ -f LEDGER.md ]; then
  out=$(awk '
    FILENAME ~ /CLAUDE\.md$/ && /^#[0-9]*:/ {
      n = $0; sub(/^#/, "", n); sub(/:.*$/, "", n)
      exord[++ne] = n; ex[n] = 1; next
    }
    FILENAME ~ /LEDGER\.md$/ {
      if ($0 ~ /^\| [0-9]* \|/) {            # rigid: what "^| $n |" greps hit
        m = $0; sub(/^\| /, "", m); sub(/ \|.*$/, "", m)
        rowx[m] = 1
      }
      if ($0 ~ /^\| *[0-9][0-9]* *\| *Active/) {   # flexible, as the old 4b grep
        n = $0; sub(/^\| */, "", n); sub(/ *\|.*$/, "", n)
        active[++na] = n
      }
    }
    END {
      for (i = 1; i <= ne; i++)
        if (!(exord[i] in rowx)) print "doc-lint: extract #" exord[i] " has no LEDGER.md row"
      for (i = 1; i <= na; i++)
        if (!(active[i] in ex)) print "doc-lint: Active LEDGER.md row #" active[i] " has no CLAUDE.md extract"
    }' CLAUDE.md LEDGER.md)
  emit "$out"
fi

# 5. maintenance block present
[ -f CLAUDE.md ] && ! grep -q "^## Maintenance" CLAUDE.md && note "maintenance block missing from CLAUDE.md"

# 6. CLAUDE.md must exist — an empty or botched generation must not lint
#    clean just because every other check above is guarded by [ -f ... ].
[ -f CLAUDE.md ] || note "CLAUDE.md is missing"

# 7. directive count (WARN only, never fails the run)
dirs=0
if [ -f CLAUDE.md ]; then
  dirs=$(grep -E -c "^(- |[0-9]+\. |#[0-9]+:)" CLAUDE.md)
  [ "$dirs" -gt "$DIRECTIVES_WARN" ] && warn "CLAUDE.md carries $dirs directive lines (> $DIRECTIVES_WARN) — every added rule dilutes the others; consolidate or retire before adding more"
fi

# 8. run log (never a finding)
if [ "${DOC_LINT_LOG:-1}" != "0" ]; then
  cb=0; pb=0
  [ -f CLAUDE.md ] && cb=$(wc -c < CLAUDE.md | tr -d ' ')
  [ -f PLAN.md ] && pb=$(wc -c < PLAN.md | tr -d ' ')
  mkdir -p docs 2>/dev/null
  [ -f docs/doc-lint-log.csv ] || echo "date,exit,findings,claude_bytes,plan_bytes,directives" > docs/doc-lint-log.csv 2>/dev/null
  echo "$(date +%Y-%m-%d),$fail,$findings,$cb,$pb,$dirs" >> docs/doc-lint-log.csv 2>/dev/null
fi

exit "$fail"
