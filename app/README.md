# app/ — the product

The first product slice (SPEC-001): **sign up → workspace created → add a customer → see it
in a list**, with tenant isolation enforced by the database.

## Run it

```bash
cd app
cp .env.example .env.local     # publishable keys — safe in a browser
npm install
npm run dev                    # http://localhost:3000
```

## What's here

| Path                              | What it does                                               |
| :-------------------------------- | :--------------------------------------------------------- |
| `src/app/signup`, `src/app/login` | Supabase Auth, email + password                            |
| `src/app/customers/page.tsx`      | The list + add form                                        |
| `src/app/customers/actions.ts`    | Server actions: create workspace, add customer, sign out   |
| `src/lib/supabase-browser.ts`     | Browser client (client components only)                    |
| `src/lib/supabase-server.ts`      | Server client — carries the user's cookies, so RLS applies |
| `src/middleware.ts`               | Keeps the session fresh, redirects signed-out users        |
| `tests/e2e/first-slice.spec.ts`   | The ONE test that proves the slice                         |

Browser and server Supabase clients are deliberately in **separate files**: `next/headers`
is server-only, and importing it into a client component fails the build. The first build
of this app caught exactly that.

## The security boundary is the database, not this app

`customers/page.tsx` selects from `customers` with **no workspace filter**. That is
intentional. RLS scopes the query to the caller's workspaces inside Postgres. If the app
code were the boundary, one forgotten filter would leak another tenant's data.

New workspaces are created through the `create_workspace()` RPC (migration 0034), not a
direct insert — a brand-new user is not yet a member of any workspace and so cannot insert
one under RLS.

## Tests

**End-to-end (Playwright).** Signs up two users, adds a customer as the first, and asserts
the second cannot see it:

```bash
npx playwright install --with-deps chromium   # first time only
npm run test:e2e
```

It runs against the real Supabase project, so it needs network access and creates test
users (unique emails per run, prefixed `alice+` / `bob+` at `@kobiai-e2e.test`).

**Known gap — e2e is not yet a CI job.** It would create real users in the production
project on every push. CI currently runs typecheck + build here, and proves tenant
isolation at the database level in `database/tests/98_policy_smoke_test.sql`. Wiring e2e
into CI properly wants a throwaway Supabase project first — a good candidate for the next
factory improvement.
