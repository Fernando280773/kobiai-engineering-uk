"use server";

import { redirect } from "next/navigation";
import { createServerSupabase } from "@/lib/supabase-server";
import { supabaseAdmin } from "@/lib/supabase-admin";
import { appUrl, stripe } from "@/lib/stripe";
import { ENTITLED_STATUSES, TRIAL_DAYS, lookupKeyFor, priceIdForLookupKey } from "@/lib/billing";
import { ensureWorkspace } from "../customers/actions";

// Tags these sessions in the Stripe Dashboard so this checkout flow can be
// compared with any others added later.
const INTEGRATION_ID = "kobiai_subscription_checkout_qhtzmwra";

type Billing = {
  stripe_customer_id: string;
  stripe_subscription_id: string | null;
  status: string | null;
};

/**
 * Resolves the caller's workspace and checks they may manage its billing.
 * The workspace id comes from the caller's own membership (RLS), never from
 * the form — so nobody can start checkout or open the portal for someone
 * else's workspace.
 */
async function billingContext() {
  const { data: workspaceId, error } = await ensureWorkspace();
  if (error || !workspaceId) throw new Error(error ?? "Could not resolve your workspace.");

  const supabase = await createServerSupabase();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) redirect("/login");

  const { data: member } = await supabase
    .from("workspace_members")
    .select("role")
    .eq("workspace_id", workspaceId)
    .eq("user_id", user.id)
    .maybeSingle();

  if (!member || !["owner", "admin"].includes(member.role as string)) {
    throw new Error("Only a workspace owner or admin can manage billing.");
  }

  const { data: billing } = await supabase
    .from("workspace_billing")
    .select("stripe_customer_id, stripe_subscription_id, status")
    .eq("workspace_id", workspaceId)
    .maybeSingle();

  return { workspaceId, user, billing: billing as Billing | null };
}

/**
 * One Stripe customer per workspace, created on first checkout and recorded in
 * workspace_billing. The idempotency key means a double-click cannot create
 * two customers. The row is written with the service role because users have
 * no write access to workspace_billing (see migration 0037).
 */
async function ensureStripeCustomer(workspaceId: string, email: string | undefined): Promise<string> {
  const customer = await stripe().customers.create(
    { email, metadata: { workspace_id: workspaceId } },
    { idempotencyKey: `kobiai-customer-${workspaceId}` },
  );

  const { error } = await supabaseAdmin()
    .from("workspace_billing")
    .upsert(
      { workspace_id: workspaceId, stripe_customer_id: customer.id },
      { onConflict: "workspace_id", ignoreDuplicates: true },
    );
  if (error) throw new Error(`Could not save billing customer: ${error.message}`);

  // If a concurrent request saved first, use whatever is stored.
  const { data: saved } = await supabaseAdmin()
    .from("workspace_billing")
    .select("stripe_customer_id")
    .eq("workspace_id", workspaceId)
    .single();
  return (saved?.stripe_customer_id as string | undefined) ?? customer.id;
}

export async function startCheckout(formData: FormData): Promise<void> {
  const lookupKey = lookupKeyFor(String(formData.get("plan")), String(formData.get("interval")));
  if (!lookupKey) throw new Error("Unknown plan.");

  const { workspaceId, user, billing } = await billingContext();

  // Already paying or trialling: plan changes happen in the portal, so a
  // workspace can never end up with two subscriptions.
  if (billing?.status && ENTITLED_STATUSES.has(billing.status)) {
    return openPortal();
  }

  const customer = billing?.stripe_customer_id ?? (await ensureStripeCustomer(workspaceId, user.email));
  const price = await priceIdForLookupKey(lookupKey);

  // Free trial only for a workspace that has never had a subscription.
  const firstSubscription = !billing?.stripe_subscription_id;

  const session = await stripe().checkout.sessions.create({
    mode: "subscription",
    customer,
    client_reference_id: workspaceId,
    line_items: [{ price, quantity: 1 }],
    // No payment_method_types: Stripe shows the best methods per customer,
    // configured in Dashboard > Settings > Payment methods.
    subscription_data: {
      billing_mode: { type: "flexible" },
      metadata: { workspace_id: workspaceId },
      ...(firstSubscription ? { trial_period_days: TRIAL_DAYS } : {}),
    },
    allow_promotion_codes: true,
    // B2B: lets UK/EU businesses enter a VAT number for the invoice.
    tax_id_collection: { enabled: true },
    customer_update: { name: "auto", address: "auto" },
    // Off until a VAT registration exists in Stripe Tax — see app/README.md.
    ...(process.env.STRIPE_AUTOMATIC_TAX === "true" ? { automatic_tax: { enabled: true } } : {}),
    integration_identifier: INTEGRATION_ID,
    success_url: `${appUrl()}/billing?checkout=success`,
    cancel_url: `${appUrl()}/billing?checkout=cancelled`,
  });

  if (!session.url) throw new Error("Stripe did not return a checkout URL.");
  redirect(session.url);
}

export async function openPortal(): Promise<void> {
  const { billing } = await billingContext();
  if (!billing?.stripe_customer_id) throw new Error("No billing account yet — choose a plan first.");

  const session = await stripe().billingPortal.sessions.create({
    customer: billing.stripe_customer_id,
    return_url: `${appUrl()}/billing`,
  });
  redirect(session.url);
}
