-- =============================================================================
-- 0037 — Stripe billing per workspace.
--
-- One row per workspace that has ever started checkout. Stripe is the source
-- of truth; this table is a local mirror kept current by the webhook handler
-- (app/src/app/api/stripe/webhook/route.ts), so the app can gate features
-- without calling Stripe on every page load.
--
-- WRITES: only the server, using the Supabase secret (service_role) key, which
-- bypasses RLS. Signed-in users get read-only access to their own workspace's
-- row. There is deliberately no insert/update/delete policy: a user must never
-- be able to mark their own workspace as "active".
-- =============================================================================

create table if not exists public.workspace_billing (
    workspace_id uuid primary key references public.workspaces(id) on delete cascade,
    stripe_customer_id text not null unique,
    stripe_subscription_id text unique,
    stripe_price_id text,
    plan text,
    -- Mirrors Stripe's subscription.status: trialing, active, past_due,
    -- unpaid, canceled, incomplete, incomplete_expired, paused.
    status text,
    trial_end timestamptz,
    current_period_end timestamptz,
    cancel_at_period_end boolean not null default false,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

alter table public.workspace_billing enable row level security;

drop policy if exists workspace_billing_select on public.workspace_billing;
create policy workspace_billing_select on public.workspace_billing
    for select
    to authenticated
    using (workspace_id in (select private.user_workspace_ids()));

revoke insert, update, delete on public.workspace_billing from anon, authenticated;

comment on table public.workspace_billing is
  'Local mirror of each workspace''s Stripe customer + subscription. Written only by the Stripe webhook (service role); readable by workspace members.';

-- -----------------------------------------------------------------------------
-- Webhook idempotency. Stripe retries deliveries, so every event id is recorded
-- once and a repeat delivery is acknowledged without being processed again.
-- RLS on with no policies: invisible to users, writable only by service role.
-- -----------------------------------------------------------------------------
create table if not exists public.stripe_webhook_events (
    id text primary key,
    type text not null,
    received_at timestamptz not null default now()
);

alter table public.stripe_webhook_events enable row level security;

revoke all on public.stripe_webhook_events from anon, authenticated;

comment on table public.stripe_webhook_events is
  'Stripe event ids already processed by the webhook handler. Service role only.';
