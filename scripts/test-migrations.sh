#!/usr/bin/env bash
# =============================================================================
# REAL migration test. Applies bootstrap -> all migrations (in order) -> asserts.
# Exits non-zero on the first failure. This is the factory's quality-control
# station: it proves the schema actually builds, on every change.
#
# Usage (CI provides DATABASE_URL to a throwaway Postgres):
#   DATABASE_URL=postgres://user:pass@localhost:5432/db ./scripts/test-migrations.sh
# =============================================================================
set -euo pipefail

: "${DATABASE_URL:?Set DATABASE_URL to a throwaway Postgres before running}"

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PSQL="psql --no-psqlrc -v ON_ERROR_STOP=1 -q $DATABASE_URL"

echo "== 1/4  bootstrap (fake Supabase auth schema) =="
$PSQL -f "$ROOT/database/tests/00_test_bootstrap.sql"

echo "== 2/4  applying migrations in order =="
for f in "$ROOT"/database/migrations/*.sql; do
  echo "   -> $(basename "$f")"
  $PSQL -f "$f"
done

echo "== 3/4  policy smoke test (acts as a real signed-in user) =="
$PSQL -f "$ROOT/database/tests/98_policy_smoke_test.sql"

echo "== 4/4  asserting schema =="
$PSQL -f "$ROOT/database/tests/99_assert_schema.sql"

echo ""
echo "✅ MIGRATION TEST PASSED — schema builds, policies work, tenants isolated."
