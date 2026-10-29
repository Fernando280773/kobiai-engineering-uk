-- =============================================================================
-- BILLING POLICY TEST — proves workspace_billing is safe (migration 0037).
--
--   1. A workspace member can read their own billing row.
--   2. Another tenant cannot see it.
--   3. A signed-in user cannot write billing rows (no self-upgrades).
--   4. stripe_webhook_events is invisible to signed-in users.
--
-- Any failure raises, psql exits non-zero, CI goes red.
-- =============================================================================

grant usage on schema public to authenticated;
grant select, insert, update, delete on all tables in schema public to authenticated;

do $$
declare
  u1 uuid := '00000000-0000-0000-0000-0000000000b1';
  u2 uuid := '00000000-0000-0000-0000-0000000000b2';
  ws uuid;
  n int;
  blocked boolean;
begin
  insert into auth.users (id, email) values (u1, 'billing-owner@test'), (u2, 'billing-other@test');

  -- Owner creates a workspace through the real RPC.
  perform set_config('request.jwt.claims',
    json_build_object('sub',u1,'role','authenticated')::text, true);
  set local role authenticated;
  ws := public.create_workspace('Billing Co','billing-co');
  set local role postgres;

  -- The webhook (service role / table owner) writes the billing row.
  insert into public.workspace_billing (workspace_id, stripe_customer_id, status, plan)
  values (ws, 'cus_test_billing', 'active', 'starter');
  insert into public.stripe_webhook_events (id, type) values ('evt_test_1', 'invoice.paid');

  -- 1) Owner reads it.
  set local role authenticated;
  select count(*) into n from public.workspace_billing where workspace_id = ws;
  set local role postgres;
  if n <> 1 then
    raise exception 'BILLING TEST FAILED — owner sees % billing rows, expected 1', n;
  end if;

  -- 3) Owner cannot change it.
  set local role authenticated;
  update public.workspace_billing set status = 'active', plan = 'pro' where workspace_id = ws;
  get diagnostics n = row_count;
  set local role postgres;
  if n <> 0 then
    raise exception 'BILLING TEST FAILED — a user updated their own billing row';
  end if;

  blocked := false;
  begin
    set local role authenticated;
    insert into public.workspace_billing (workspace_id, stripe_customer_id, status)
    values (ws, 'cus_forged', 'active');
    set local role postgres;
  exception when others then
    set local role postgres;
    blocked := true;
  end;
  if not blocked then
    raise exception 'BILLING TEST FAILED — a user inserted a billing row';
  end if;

  -- 4) Webhook ledger is invisible.
  set local role authenticated;
  select count(*) into n from public.stripe_webhook_events;
  set local role postgres;
  if n <> 0 then
    raise exception 'BILLING TEST FAILED — user can read stripe_webhook_events';
  end if;

  -- 2) Other tenant sees nothing.
  perform set_config('request.jwt.claims',
    json_build_object('sub',u2,'role','authenticated')::text, true);
  set local role authenticated;
  select count(*) into n from public.workspace_billing;
  set local role postgres;
  if n <> 0 then
    raise exception 'BILLING TEST FAILED — TENANT LEAK: other user sees % billing rows', n;
  end if;

  raise notice 'OK: billing row readable by owner only, not writable by users, ledger hidden';

  delete from public.stripe_webhook_events where id = 'evt_test_1';
  delete from public.workspace_billing where workspace_id = ws;
  delete from public.workspace_members where user_id in (u1, u2);
  delete from public.workspaces where slug = 'billing-co';
  delete from auth.users where id in (u1, u2);
end $$;

select 'BILLING POLICY TEST PASSED' as result;
