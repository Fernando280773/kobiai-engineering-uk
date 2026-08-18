-- =============================================================================
-- 0035 — Harden the two SECURITY DEFINER functions added in 0033/0034.
--
-- After 0033/0034 the Supabase security advisor raised 4 warnings: both new
-- functions were reachable through the public REST API, including by `anon`.
-- We do not let a gate regress, so:
--
--   * user_workspace_ids() is an internal policy helper. It has no business
--     being an API endpoint -> move it to a `private` schema, which PostgREST
--     does not expose. Policies can still call it.
--   * create_workspace() MUST stay callable by signed-in users (it is how the
--     app creates a workspace), but anon has no reason to reach it -> revoke.
--
-- Result: 4 warnings -> 1, and the remaining one is intentional by design
-- (create_workspace is deliberately an authenticated API endpoint).
-- =============================================================================

create schema if not exists private;
grant usage on schema private to authenticated;

create or replace function private.user_workspace_ids()
returns setof uuid
language sql
security definer
stable
set search_path = ''
as $$
  select workspace_id
  from public.workspace_members
  where user_id = auth.uid()
$$;

revoke all on function private.user_workspace_ids() from public, anon;
grant execute on function private.user_workspace_ids() to authenticated;

-- Repoint the policy at the private helper.
drop policy if exists members_isolation_policy on public.workspace_members;

create policy members_isolation_policy on public.workspace_members
  for all
  to authenticated
  using (workspace_id in (select private.user_workspace_ids()));

-- Retire the public-schema copy now that nothing references it.
drop function if exists public.user_workspace_ids();

-- create_workspace stays in public (it is a real API endpoint) but anon is
-- locked out. The function also raises 'not authenticated' when auth.uid()
-- is null, so this is belt and braces.
revoke all on function public.create_workspace(text, text) from public, anon;
grant execute on function public.create_workspace(text, text) to authenticated;
