-- =============================================================================
-- Test bootstrap — makes a plain Postgres look enough like Supabase to run
-- the migrations in CI WITHOUT a real Supabase project.
--
-- Supabase provides an `auth` schema, an `auth.users` table, and `auth.uid()`.
-- A vanilla Postgres container does not. We create minimal stand-ins so the
-- migration test in CI actually executes every migration against a real
-- database and proves the schema builds. This is the honest quality gate that
-- replaces "AUDIT PASSED — 100/100".
-- =============================================================================

create schema if not exists auth;

create table if not exists auth.users (
  id uuid primary key default gen_random_uuid(),
  email text
);

-- Supabase's auth.uid() reads the JWT; in tests we just return a fixed UUID.
create or replace function auth.uid()
returns uuid
language sql
stable
as $$ select '00000000-0000-0000-0000-000000000000'::uuid $$;
