-- =============================================================================
-- 0034 — Let a brand-new user create their first workspace.
--
-- PROBLEM: workspaces_isolation_policy is FOR ALL, so its USING clause also
-- governs INSERT. It requires you to already be a member of the workspace you
-- are inserting — impossible for a user's very first workspace. Chicken-and-egg.
--
-- FIX: one SECURITY DEFINER RPC that creates the workspace AND the owner
-- membership atomically. Direct inserts into workspaces stay blocked by RLS,
-- which is desirable: workspace creation now has exactly one door.
-- =============================================================================

create or replace function public.create_workspace(p_name text, p_slug text)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_workspace_id uuid;
begin
  if v_uid is null then
    raise exception 'not authenticated';
  end if;

  if p_name is null or btrim(p_name) = '' then
    raise exception 'workspace name is required';
  end if;

  if p_slug is null or btrim(p_slug) = '' then
    raise exception 'workspace slug is required';
  end if;

  insert into public.workspaces (name, slug)
  values (btrim(p_name), btrim(lower(p_slug)))
  returning id into v_workspace_id;

  insert into public.workspace_members (workspace_id, user_id, role)
  values (v_workspace_id, v_uid, 'owner');

  return v_workspace_id;
end;
$$;

comment on function public.create_workspace(text, text) is
  'Creates a workspace and makes the caller its owner, atomically. SECURITY DEFINER because a new user is not yet a member of any workspace and so cannot insert one directly under RLS.';

revoke all on function public.create_workspace(text, text) from public;
grant execute on function public.create_workspace(text, text) to authenticated;
