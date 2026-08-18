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

## Keys

- Publishable key: `sb_publishable_x9hj7deJRdZt2bcpgd3k5A_OGNFT2FP`
- Secret (service_role) key: get from Dashboard → Project Settings → API Keys (never commit it)
- See `../.env.example`.
