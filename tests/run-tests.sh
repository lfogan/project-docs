#!/bin/sh
# v2 lint + hook harness. Run from the skill root: sh tests/run-tests.sh
cd "$(dirname "$0")/.." || exit 1
ROOT=$(pwd)
LINT="$ROOT/scripts/doc-lint.sh"
TMP="$ROOT/tests/tmp"
pass=0; failn=0
result() { # $1 name, $2 ok(1/0), $3 detail
  if [ "$2" -eq 1 ]; then pass=$((pass+1)); echo "PASS $1"
  else failn=$((failn+1)); echo "FAIL $1 — $3"; fi
}
fresh() { rm -rf "$TMP/case"; mkdir -p "$TMP"; cp -r "$ROOT/tests/fixtures/good" "$TMP/case"; }
run() { # $1 extra env (may be empty). Sets OUT and RC.
  OUT=$(cd "$TMP/case" && env DOC_LINT_LOG=0 $1 sh "$LINT" 2>&1); RC=$?
}
expect() { # $1 name, $2 want_rc, $3 grep pattern or "-"
  ok=1; det=""
  [ "$RC" -eq "$2" ] || { ok=0; det="exit=$RC want=$2"; }
  if [ "$3" != "-" ]; then
    printf '%s' "$OUT" | grep -q "$3" || { ok=0; det="$det; missing pattern: $3; got: $OUT"; }
  fi
  result "$1" "$ok" "$det"
}

# 1. clean fixture passes
fresh; run ""; expect "clean fixture exits 0" 0 -

# 2. byte cap
fresh; run "BUDGET_CLAUDE=100"; expect "over-cap CLAUDE.md fails" 1 "over cap"

# 3. rules cap
fresh; run "RULES_CAP=3"; expect "rules over cap fail" 1 "exceed the cap"

# 4. rules grammar
fresh; printf 'stray prose line\n' >> "$TMP/case/tmp.$$"; rm -f "$TMP/case/tmp.$$"
sed -i '/^R7:/a this is not an R line' "$TMP/case/CLAUDE.md"
run ""; expect "non-R line in Rules fails" 1 "non-R line"

# 5. TODO drain
fresh; printf -- '- [x] finished thing\n' >> "$TMP/case/TODO.md"
run ""; expect "done row in TODO fails" 1 "done row still in TODO.md"

# 5b. the drain check is scoped to TODO.md: a release record in docs/agent/
#     carries dated done-marks for work git cannot show, and must lint clean.
fresh; printf -- '- Play signing key enrolled [done 2026-08-17]\n- [x] store listing published\n' \
  >> "$TMP/case/docs/agent/device-qa.md"
run ""; expect "done marks in docs/agent/ are allowed" 0 -

# 6. forbidden v1 files
fresh; printf '# old\n' > "$TMP/case/CHANGELOG.md"
run ""; expect "CHANGELOG.md presence fails" 1 "forbidden v1 file"

# 7. dangling path
fresh; sed -i 's|^- TODO.md — open work.|- TODO.md — open work.\n- docs/NOPE.md — ghost.|' "$TMP/case/CLAUDE.md"
run ""; expect "missing referenced path fails" 1 "missing path: docs/NOPE.md"

# 8. required section
fresh; sed -i '/^## Pointers$/d' "$TMP/case/CLAUDE.md"
run ""; expect "missing section fails" 1 "required section missing"

# 9. unfilled token
fresh; printf '{{LEFTOVER}}\n' >> "$TMP/case/TODO.md"
run ""; expect "unfilled token fails" 1 "unfilled template token"

# 10. SETTLED grammar
fresh; printf -- '- Do add narrative here because reasons\n' >> "$TMP/case/docs/SETTLED.md"
run ""; expect "bad SETTLED line fails" 1 "SETTLED line breaks grammar"

# 11. CSV row shape
fresh
OUT=$(cd "$TMP/case" && sh "$LINT" 2>&1); RC=$?
ok=1; det=""
[ "$RC" -eq 0 ] || { ok=0; det="exit=$RC"; }
[ -f "$TMP/case/docs/doc-lint-log.csv" ] || { ok=0; det="$det; no csv"; }
n=$(awk -F, 'NR==1{print NF}' "$TMP/case/docs/doc-lint-log.csv" 2>/dev/null)
[ "$n" = "10" ] || { ok=0; det="$det; header fields=$n want 10"; }
rows=$(grep -c . "$TMP/case/docs/doc-lint-log.csv" 2>/dev/null)
[ "$rows" = "2" ] || { ok=0; det="$det; rows=$rows want 2"; }
result "CSV logged with 10 columns" "$ok" "$det"

# 12. hooks end-to-end in a real repo
rm -rf "$TMP/repo"; mkdir -p "$TMP/repo"
cp -r "$ROOT/tests/fixtures/good/." "$TMP/repo/"
mkdir -p "$TMP/repo/scripts" "$TMP/repo/.githooks"
cp "$ROOT/scripts/doc-lint.sh" "$TMP/repo/scripts/"
cp "$ROOT/scripts/hooks/pre-commit" "$ROOT/scripts/hooks/commit-msg" "$TMP/repo/.githooks/"
chmod +x "$TMP/repo/.githooks/pre-commit" "$TMP/repo/.githooks/commit-msg" 2>/dev/null
(
  cd "$TMP/repo" || exit 9
  git init -q .
  git config user.email test@test && git config user.name test
  git config core.hooksPath .githooks
  git add -A
  git commit -qm "init docs-v2 [design-approved]" || exit 1
  git show --name-only --format= HEAD | grep -q "docs/doc-lint-log.csv" || exit 2
  echo "tweak" >> docs/design/DESIGN.md
  git add -A
  git commit -qm "design tweak, no token" 2>/dev/null && exit 3
  git commit -qm "design tweak [design-approved]" || exit 4
  exit 0
)
rc=$?
case $rc in
  0) result "hooks: gate + CSV-in-commit e2e" 1 "";;
  1) result "hooks: gate + CSV-in-commit e2e" 0 "initial commit blocked unexpectedly";;
  2) result "hooks: gate + CSV-in-commit e2e" 0 "CSV row not inside the commit";;
  3) result "hooks: gate + CSV-in-commit e2e" 0 "design edit committed WITHOUT token";;
  4) result "hooks: gate + CSV-in-commit e2e" 0 "design edit with token was blocked";;
  *) result "hooks: gate + CSV-in-commit e2e" 0 "setup failure rc=$rc";;
esac

echo "----"
echo "$pass passed, $failn failed"
[ "$failn" -eq 0 ] && echo "ALL PASS"
exit "$failn"
