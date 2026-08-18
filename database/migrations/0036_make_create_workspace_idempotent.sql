-- =============================================================================
-- 0036 — Make create_workspace() idempotent and race-safe.
--
-- FOUND BY: the first end-to-end run of the product. Sign-up succeeded, landed
-- on /customers, and the page showed "That value is already used" (23505).
--
-- CAUSE: the client did router.push("/customers") immediately followed by
-- router.refresh(). Both trigger a server render of /customers, and BOTH ran
-- the workspace bootstrap concurrently. Each saw "no membership yet", each
-- called create_workspace(), and the second lost the race on workspaces.slug.
--
-- The app-side fix (dropping the redundant refresh) removes today's trigger,
-- but any double-submit, retry or refresh would hit the same thing. So the
-- function itself is made safe: calling it twice is now harmless.
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
  v_slug text;
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

  -- Idempotent: if the caller already belongs to a workspace, hand it back
  -- rather than creating a second one.
  select wm.workspace_id
    into v_workspace_id
  from public.workspace_members wm
  where wm.user_id = v_uid
  limit 1;

  if v_workspace_id is not null then
    return v_workspace_id;
  end if;

  v_slug := btrim(lower(p_slug));

  -- Race-safe insert. If a concurrent call won, take no action and read it back.
  insert into public.workspaces (name, slug)
  values (btrim(p_name), v_slug)
  on conflict (slug) do nothing
  returning id into v_workspace_id;

  if v_workspace_id is null then
    select w.id into v_workspace_id
    from public.workspaces w
    where w.slug = v_slug;
  end if;

  if v_workspace_id is null then
    raise exception 'could not create or find workspace with slug %', v_slug;
  end if;

  -- Same story for the membership row (PK is workspace_id, user_id).
  insert into public.workspace_members (workspace_id, user_id, role)
  values (v_workspace_id, v_uid, 'owner')
  on conflict (workspace_id, user_id) do nothing;

  return v_workspace_id;
end;
$$;

comment on function public.create_workspace(text, text) is
  'Creates a workspace and makes the caller its owner. Idempotent and race-safe: concurrent or repeated calls return the same workspace instead of raising a unique violation.';

revoke all on function public.create_workspace(text, text) from public, anon;
grant execute on function public.create_workspace(text, text) to authenticated;
