-- =============================================================================
-- Schema assertions — run AFTER all migrations. If any assertion fails, psql
-- exits non-zero and CI goes red. This is the machine deciding "done", not us.
-- =============================================================================

-- 1) Expect the 26 core tables to exist.
do $$
declare
  n int;
begin
  select count(*) into n
  from information_schema.tables
  where table_schema = 'public' and table_type = 'BASE TABLE';
  if n < 26 then
    raise exception 'Expected at least 26 public tables, found %', n;
  end if;
  raise notice 'OK: % public tables present', n;
end $$;

-- 2) Every public table must have RLS enabled (multi-tenant safety).
do $$
declare
  bad text;
begin
  select string_agg(tablename, ', ') into bad
  from pg_tables
  where schemaname = 'public' and rowsecurity = false;
  if bad is not null then
    raise exception 'Tables missing RLS: %', bad;
  end if;
  raise notice 'OK: RLS enabled on all public tables';
end $$;

-- 3) Spot-check a few key tables exist by name.
do $$
declare
  t text;
  missing text := '';
begin
  foreach t in array array['workspaces','workspace_members','customers','contacts','ai_agents','workflows']
  loop
    if not exists (select 1 from information_schema.tables
                   where table_schema='public' and table_name=t) then
      missing := missing || t || ' ';
    end if;
  end loop;
  if length(missing) > 0 then
    raise exception 'Missing expected tables: %', missing;
  end if;
  raise notice 'OK: key tables present';
end $$;

select 'ALL SCHEMA ASSERTIONS PASSED' as result;
