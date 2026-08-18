-- =============================================================================
-- Test bootstrap — makes a plain Postgres look enough like Supabase to run
-- the migrations in CI WITHOUT a real Supabase project.
--
-- Supabase provides an `auth` schema, an `auth.users` table, `auth.uid()`, and
-- the roles `anon`, `authenticated`, `service_role`. A vanilla Postgres
-- container does not. We create minimal stand-ins so the migration test in CI
-- actually executes every migration against a real database and proves the
-- schema builds. This is the honest quality gate that replaces
-- "AUDIT PASSED — 100/100".
-- =============================================================================

-- Supabase's built-in roles. RLS policies are declared `TO authenticated`, so
-- these roles must exist for the policies to be created. No-login stand-ins.
do $$
begin
  if not exists (select 1 from pg_roles where rolname = 'anon') then
    create role anon nologin;
  end if;
  if not exists (select 1 from pg_roles where rolname = 'authenticated') then
    create role authenticated nologin;
  end if;
  if not exists (select 1 from pg_roles where rolname = 'service_role') then
    create role service_role nologin bypassrls;
  end if;
end
$$;

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
