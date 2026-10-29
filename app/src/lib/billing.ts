import "server-only";
import type Stripe from "stripe";
import { stripe } from "./stripe";
import { supabaseAdmin } from "./supabase-admin";

/**
 * The plans on sale. Prices are referenced by Stripe LOOKUP KEY, not price id,
 * so the same code works in the sandbox and in live mode (create live prices
 * with the same lookup keys) and a price change never needs a deploy.
 */
export const PLANS = [
  {
    id: "starter",
    name: "Starter",
    blurb: "One small business, everything you need to run your customers.",
    monthly: { lookupKey: "kobiai_starter_monthly", label: "£19 / month" },
    yearly: { lookupKey: "kobiai_starter_yearly", label: "£190 / year" },
  },
  {
    id: "pro",
    name: "Pro",
    blurb: "For a growing team with more users and more pipeline.",
    monthly: { lookupKey: "kobiai_pro_monthly", label: "£49 / month" },
    yearly: { lookupKey: "kobiai_pro_yearly", label: "£490 / year" },
  },
] as const;

export type PlanId = (typeof PLANS)[number]["id"];
export type Interval = "monthly" | "yearly";

export const TRIAL_DAYS = 14;

/** Subscription statuses that should unlock the product. */
export const ENTITLED_STATUSES = new Set(["trialing", "active"]);

const LOOKUP_TO_PLAN = new Map<string, PlanId>(
  PLANS.flatMap((p) => [
    [p.monthly.lookupKey, p.id],
    [p.yearly.lookupKey, p.id],
  ]),
);

export function lookupKeyFor(plan: string, interval: string): string | null {
  const p = PLANS.find((x) => x.id === plan);
  if (!p || (interval !== "monthly" && interval !== "yearly")) return null;
  return p[interval].lookupKey;
}

export async function priceIdForLookupKey(lookupKey: string): Promise<string> {
  const { data } = await stripe().prices.list({ lookup_keys: [lookupKey], active: true, limit: 1 });
  if (!data[0]) {
    throw new Error(`No active Stripe price with lookup key "${lookupKey}". Create it in the Stripe Dashboard.`);
  }
  return data[0].id;
}

function customerId(c: string | Stripe.Customer | Stripe.DeletedCustomer): string {
  return typeof c === "string" ? c : c.id;
}

function toIso(seconds: number | null | undefined): string | null {
  return seconds ? new Date(seconds * 1000).toISOString() : null;
}

/**
 * Re-reads a subscription from Stripe and mirrors it into workspace_billing.
 *
 * Always refetching (instead of trusting the event payload) makes the webhook
 * order-independent and safe to replay: whatever order events arrive in, the
 * row ends up matching Stripe's current state.
 *
 * The workspace is found through the Stripe CUSTOMER id we stored when the
 * workspace first went to checkout — Stripe's object graph, not metadata.
 */
export async function syncSubscription(subscriptionId: string): Promise<void> {
  const sub = await stripe().subscriptions.retrieve(subscriptionId);
  const cus = customerId(sub.customer);

  const db = supabaseAdmin();
  const { data: row, error: findError } = await db
    .from("workspace_billing")
    .select("workspace_id, stripe_subscription_id")
    .eq("stripe_customer_id", cus)
    .maybeSingle();

  if (findError) throw new Error(`workspace_billing lookup failed: ${findError.message}`);
  if (!row) {
    // A customer we did not create (e.g. made by hand in the Dashboard).
    // Nothing in the app to update; log so it is visible, but do not fail the
    // webhook — Stripe would just keep retrying an event we can never apply.
    console.warn(`[stripe] subscription ${sub.id} belongs to unknown customer ${cus}; ignored`);
    return;
  }

  // One live subscription per workspace. If this event is about an older,
  // ended subscription, do not let it overwrite a newer one.
  if (
    row.stripe_subscription_id &&
    row.stripe_subscription_id !== sub.id &&
    !ENTITLED_STATUSES.has(sub.status)
  ) {
    return;
  }

  const item = sub.items.data[0];
  const price = item?.price;

  const { error: updateError } = await db
    .from("workspace_billing")
    .update({
      stripe_subscription_id: sub.id,
      stripe_price_id: price?.id ?? null,
      plan: (price?.lookup_key && LOOKUP_TO_PLAN.get(price.lookup_key)) ?? null,
      status: sub.status,
      trial_end: toIso(sub.trial_end),
      // Since API 2025-03-31 the billing period lives on the subscription item.
      current_period_end: toIso(item?.current_period_end),
      cancel_at_period_end: sub.cancel_at_period_end,
      updated_at: new Date().toISOString(),
    })
    .eq("workspace_id", row.workspace_id);

  if (updateError) throw new Error(`workspace_billing update failed: ${updateError.message}`);
}

/** The subscription an invoice belongs to (API 2025-03-31+ object graph). */
export function subscriptionIdFromInvoice(invoice: Stripe.Invoice): string | null {
  const sub = invoice.parent?.subscription_details?.subscription;
  if (!sub) return null;
  return typeof sub === "string" ? sub : sub.id;
}
