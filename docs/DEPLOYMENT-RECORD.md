# Deployment Record — KobiAI Engineering UK

**Date:** 20 July 2026
**Supabase project:** `kobiai-engineering-uk`
**Project ref:** `bvhafvntlhibpwtdofgj`
**Region:** London / `eu-west-2`
**URL:** <https://bvhafvntlhibpwtdofgj.supabase.co>
**Cost:** $10/month (approved by owner)

## Status: LIVE ✅ (verified)

| Item                      | Value                                                                             |
| :------------------------ | :-------------------------------------------------------------------------------- |
| Public tables             | 26                                                                                |
| RLS policies              | 73                                                                                |
| Tables without RLS        | 0                                                                                 |
| Security advisor warnings | 0                                                                                 |
| Immutable audit tables    | agent_execution_logs, workflow_executions, workflow_events, workforce_performance |
| Trigger functions         | hardened (`search_path = ''`)                                                     |

## How it was built

The 32 migrations in `database/migrations/` were applied in order (grouped into 4 chunks).
All user foreign keys point to Supabase's `auth.users` (not a non-existent `public.users`) —
the correction from the original repo is baked in here from the start.

## 18 Aug 2026 — RLS recursion fix (migrations 0033–0035)

While speccing the first product slice, a real authenticated user was run against the
schema. **All 26 tables were unreadable**: the `workspace_members` policy filtered the
table by selecting the same table, so Postgres recursed forever — and because every other
table's policy subqueries `workspace_members`, the failure spread everywhere.

Nothing above caught it. Every gate checked that policies **exist**; none checked that a
policy **works**.

| Migration | What it does                                                                      |
| :-------- | :-------------------------------------------------------------------------------- |
| 0033      | `SECURITY DEFINER` helper breaks the recursion; rewrites the members policy       |
| 0034      | `create_workspace()` RPC — a new user can create their first workspace atomically |
| 0035      | Moves the helper into a non-exposed `private` schema; locks `anon` out            |

**Verified after the fix:** 26/26 tables readable; create workspace → add customer → list
works end to end; a second tenant sees 0 rows. Security advisor: 4 warnings → 1, and that
one is intentional (`create_workspace` is deliberately an authenticated API endpoint).

**Gate added:** `database/tests/98_policy_smoke_test.sql` now runs in CI as a real signed-in
user. Proven honest both ways — it fails on the recursion bug, and it fails on a
deliberately leaky policy.

## Keys

- Publishable key: `sb_publishable_x9hj7deJRdZt2bcpgd3k5A_OGNFT2FP`
- Secret (service_role) key: get from Dashboard → Project Settings → API Keys (never commit it)
- See `../.env.example`.

## 25 Aug 2026 — Next.js 16 upgrade (app)

The app (`app/`) was upgraded from Next.js 15.5 to 16, on a branch, through CI, then merged to `main` (PR #1).

| Item              | Before              | After                           |
| ----------------- | ------------------- | ------------------------------- |
| next              | ^15.5.23            | 16.3.2                          |
| react / react-dom | 19.1.0              | 19.2.8                          |
| Middleware        | `src/middleware.ts` | `src/proxy.ts` (Next 16 rename) |
| Builder           | Webpack             | Turbopack (Next 16 default)     |

Run with the official `@next/codemod upgrade`. It renamed the Supabase session-refresh middleware to `proxy.ts` and added Cache Components `instant = false` opt-outs; those were removed (Cache Components not adopted) — the only build error and its fix. Verified before merge: typecheck clean, Turbopack production build succeeds (all 5 routes, `proxy.ts` recognised as middleware), e2e 2/2 passing. CI on PR #1 and on `main` after merge: all three gates green. Git: upgrade `e3580a7` → merge `3f573e0`.
