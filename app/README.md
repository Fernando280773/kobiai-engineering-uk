# app/ — the product

This folder holds the actual customer-facing product built through the factory.

It is intentionally empty right now. The **first slice** (Phase 1 in `../PLAN.md`) goes here:
sign up → create a workspace → add a customer → see the customer in a list, wired to the
live Supabase database (`kobiai-engineering-uk`).

Recommended stack for the first slice (small, fast, deployable free):

- Next.js (App Router) + TypeScript
- `@supabase/supabase-js` + Supabase Auth
- Deploy on Vercel free tier

The Builder AI fills this in from an approved half-page spec — never before.
