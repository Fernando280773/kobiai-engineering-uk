-- =============================================================================
-- 0033 — Fix infinite recursion in RLS policies.
--
-- ROOT CAUSE: members_isolation_policy on workspace_members filtered the table
-- by SELECTing the same table, so Postgres re-applied the policy forever.
-- Because every other table's policy subqueries workspace_members to check
-- membership, the recursion made ALL 26 tables unreadable:
--
--   select count(*) from customers
--     -> ERROR: infinite recursion detected in policy for "workspace_members"
--
-- FIX: a SECURITY DEFINER helper runs as the owner and therefore bypasses RLS
-- on the membership lookup, breaking the loop. Fixing this one policy repairs
-- every other table, because their subqueries now hit a non-recursive policy.
--
-- Found by running a real authenticated user against the schema while speccing
-- the first product slice. No existing gate caught it: all of them checked that
-- policies EXIST, none checked that a policy WORKS. See 98_policy_smoke_test.sql
-- for the gate added so this class of bug can never pass again.
-- =============================================================================

create or replace function public.user_workspace_ids()
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

comment on function public.user_workspace_ids() is
  'Returns workspace ids for the current user. SECURITY DEFINER so it bypasses RLS on workspace_members and cannot recurse.';

revoke all on function public.user_workspace_ids() from public;
grant execute on function public.user_workspace_ids() to authenticated;

drop policy if exists members_isolation_policy on public.workspace_members;

create policy members_isolation_policy on public.workspace_members
  for all
  to authenticated
  using (workspace_id in (select public.user_workspace_ids()));
