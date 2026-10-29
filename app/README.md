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

## Billing (Stripe)

Each workspace can subscribe to a plan. Stripe hosts the payment page and the billing
portal; the app never sees card details.

| Piece                        | Where                                       |
| ---------------------------- | ------------------------------------------- |
| Plans and prices             | `src/lib/billing.ts` (by Stripe lookup key) |
| Plan picker and status       | `src/app/billing/page.tsx`                  |
| Start checkout / open portal | `src/app/billing/actions.ts`                |
| Webhook (grants access)      | `src/app/api/stripe/webhook/route.ts`       |
| Local mirror of subscription | `workspace_billing` table (migration 0037)  |
| Proof users can't self-grant | `database/tests/97_billing_policy_test.sql` |

**Flow:** owner picks a plan on `/billing` → Stripe Checkout (14-day trial, card taken up
front) → Stripe calls the webhook → `workspace_billing` is updated → the app reads the
status. Upgrades, downgrades, cancellation (at period end), card changes and invoice
history all happen in the Stripe customer portal.

**The webhook is the only thing that grants access.** The success page just says
"confirming". Users have read-only access to `workspace_billing`; only the service-role
key can write it, and the billing policy test fails CI if that ever changes.

### Sandbox setup (Kobi AI Tech sandbox)

Already created in Stripe: products _KobiAI CRM Starter_ and _KobiAI CRM Pro_, prices
`kobiai_starter_monthly` (£19), `kobiai_starter_yearly` (£190), `kobiai_pro_monthly`
(£49), `kobiai_pro_yearly` (£490), tax code `txcd_10103001` (SaaS, business use), and a
customer-portal configuration allowing switching between those prices. These are
placeholder prices — change them in the Dashboard; the code follows the lookup keys.

1. **API key.** Stripe Dashboard → Developers → API keys → _Create restricted key_ with
   write access to: Customers, Checkout Sessions, Customer portal, Subscriptions; read
   access to: Prices, Products, Invoices. Put it in `.env.local` as `STRIPE_SECRET_KEY`.
2. **Supabase secret key** in `.env.local` as `SUPABASE_SECRET_KEY` (the webhook writes
   billing with it).
3. **Webhook, locally:** `stripe listen --forward-to localhost:3000/api/stripe/webhook`,
   then put the `whsec_...` it prints in `STRIPE_WEBHOOK_SECRET`.
4. **Webhook, on Vercel:** add an endpoint for `https://<your-domain>/api/stripe/webhook`
   with the events listed at the top of `route.ts`, and put its signing secret in the
   Vercel env vars along with the other values from `.env.example`.
5. **Migration:** apply `database/migrations/0037_create_workspace_billing.sql` to the
   Supabase project.

Test card: `4242 4242 4242 4242`, any future date, any CVC.

### Before going live

- **VAT.** `STRIPE_AUTOMATIC_TAX` stays `false` until a head-office address and a UK VAT
  registration are added in Stripe → Tax. With no registration, Stripe silently
  collects £0 tax. Prices are tax-exclusive.
- Create the same products and prices (same lookup keys) and portal settings in live mode.
- Smart Retries and failed-payment emails: Stripe → Billing → Revenue recovery.
- Invoice branding (logo, colours): Stripe → Settings → Branding. One-off invoices
  (setup or custom work) are sent from Stripe → Invoices; customers pay on the hosted
  invoice page.
- Refunds, disputes and fraud warnings are only logged by the webhook today — decide a
  policy before launch.
