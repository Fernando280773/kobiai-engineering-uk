-- =============================================================================
-- POLICY SMOKE TEST — the gate added after the recursion bug of 18 Aug 2026.
--
-- Why this exists: we shipped a schema with 26 tables, 73 policies, RLS on
-- everything, a passing migration test and a clean security advisor — and not
-- one table was readable by a real user. Every gate we had checked that
-- policies EXIST. None checked that a policy WORKS.
--
-- This test acts as an actual signed-in user and:
--   1. reads every table in public (catches recursion / broken policies)
--   2. walks the real product path: create workspace -> add customer -> list it
--   3. proves tenant isolation: a second user must NOT see the first's data
--
-- Any failure raises, psql exits non-zero, CI goes red. No overrides.
-- =============================================================================

-- Supabase grants the `authenticated` role table privileges; a vanilla test
-- Postgres does not. Without this, failures would be "permission denied"
-- rather than genuine RLS behaviour.
grant usage on schema public to authenticated;
grant select, insert, update, delete on all tables in schema public to authenticated;

-- ---------------------------------------------------------------------------
-- 1) Every table must be readable by an authenticated user.
-- ---------------------------------------------------------------------------
do $$
declare
  t text; n int; broken text := '';
begin
  perform set_config('request.jwt.claims',
    json_build_object('sub','00000000-0000-0000-0000-0000000000f1','role','authenticated')::text, true);

  for t in select tablename from pg_tables where schemaname = 'public' order by tablename loop
    begin
      execute 'set local role authenticated';
      execute format('select count(*) from public.%I', t) into n;
      execute 'set local role postgres';
    exception when others then
      execute 'set local role postgres';
      broken := broken || format('%s (%s); ', t, SQLERRM);
    end;
  end loop;

  if length(broken) > 0 then
    raise exception 'POLICY SMOKE TEST FAILED — unreadable tables: %', broken;
  end if;
  raise notice 'OK: all public tables readable by an authenticated user';
end $$;

-- ---------------------------------------------------------------------------
-- 2) + 3) The real product path, and tenant isolation.
-- ---------------------------------------------------------------------------
do $$
declare
  u1 uuid := '00000000-0000-0000-0000-0000000000f1';
  u2 uuid := '00000000-0000-0000-0000-0000000000f2';
  ws uuid; n_owner int; n_other int;
begin
  insert into auth.users (id, email)
  values (u1,'owner@smoke.test'), (u2,'other@smoke.test')
  on conflict (id) do nothing;

  -- Owner: create workspace, add a customer, list it.
  perform set_config('request.jwt.claims',
    json_build_object('sub',u1,'role','authenticated')::text, true);
  set local role authenticated;
  ws := public.create_workspace('Smoke Co','smoke-co');
  insert into public.customers (workspace_id, customer_code, name)
  values (ws, 'SMOKE-1', 'Acme Ltd');
  select count(*) into n_owner from public.customers where name = 'Acme Ltd';
  set local role postgres;

  if n_owner <> 1 then
    raise exception 'POLICY SMOKE TEST FAILED — owner sees % rows, expected 1', n_owner;
  end if;

  -- Other tenant: must see nothing.
  perform set_config('request.jwt.claims',
    json_build_object('sub',u2,'role','authenticated')::text, true);
  set local role authenticated;
  select count(*) into n_other from public.customers where name = 'Acme Ltd';
  set local role postgres;

  if n_other <> 0 then
    raise exception 'POLICY SMOKE TEST FAILED — TENANT LEAK: other user sees % rows', n_other;
  end if;

  raise notice 'OK: create workspace -> add customer -> list (owner sees 1, other sees 0)';

  -- Clean up so the test is repeatable.
  delete from public.customers where customer_code = 'SMOKE-1';
  delete from public.workspace_members where user_id in (u1, u2);
  delete from public.workspaces where slug = 'smoke-co';
  delete from auth.users where id in (u1, u2);
end $$;

select 'POLICY SMOKE TEST PASSED' as result;
