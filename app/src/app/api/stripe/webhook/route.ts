import type Stripe from "stripe";
import { stripe } from "@/lib/stripe";
import { supabaseAdmin } from "@/lib/supabase-admin";
import { subscriptionIdFromInvoice, syncSubscription } from "@/lib/billing";

// Needs the raw request body for signature verification, and must never be
// cached or statically rendered.
export const runtime = "nodejs";
export const dynamic = "force-dynamic";

/**
 * Stripe webhook — the ONLY thing that turns a workspace's plan on or off.
 * The Checkout success page shows a "confirming" message; access is granted
 * here, because renewals, failed payments and cancellations all happen
 * without the customer ever visiting the app.
 *
 * Subscribe the endpoint (Dashboard > Developers > Webhooks) to exactly:
 *   checkout.session.completed
 *   customer.subscription.created / updated / deleted / paused / resumed
 *   customer.subscription.trial_will_end
 *   invoice.paid
 *   invoice.payment_failed
 *   charge.refunded
 *   charge.dispute.created
 *   radar.early_fraud_warning.created
 */
export async function POST(request: Request): Promise<Response> {
  const secret = process.env.STRIPE_WEBHOOK_SECRET;
  const signature = request.headers.get("stripe-signature");
  if (!secret || !signature) {
    return new Response("Webhook not configured", { status: 400 });
  }

  let event: Stripe.Event;
  try {
    const body = await request.text();
    event = stripe().webhooks.constructEvent(body, signature, secret);
  } catch (err) {
    console.warn("[stripe] webhook signature verification failed", (err as Error).message);
    return new Response("Invalid signature", { status: 400 });
  }

  const db = supabaseAdmin();

  // Already handled this exact event? Acknowledge and stop.
  const { data: seen } = await db.from("stripe_webhook_events").select("id").eq("id", event.id).maybeSingle();
  if (seen) return Response.json({ received: true, duplicate: true });

  try {
    await handle(event);
  } catch (err) {
    // Non-2xx makes Stripe retry with backoff, which is what we want for a
    // transient database or network failure.
    console.error(`[stripe] failed to process ${event.type} ${event.id}`, err);
    return new Response("Processing failed", { status: 500 });
  }

  // Recorded only after success, so a failed attempt is retried in full.
  await db.from("stripe_webhook_events").upsert({ id: event.id, type: event.type }, { onConflict: "id" });

  return Response.json({ received: true });
}

async function handle(event: Stripe.Event): Promise<void> {
  switch (event.type) {
    case "checkout.session.completed": {
      const session = event.data.object;
      if (session.mode === "subscription" && session.subscription) {
        const id = typeof session.subscription === "string" ? session.subscription : session.subscription.id;
        await syncSubscription(id);
      }
      return;
    }

    case "customer.subscription.created":
    case "customer.subscription.updated":
    case "customer.subscription.deleted":
    case "customer.subscription.paused":
    case "customer.subscription.resumed":
      await syncSubscription(event.data.object.id);
      return;

    case "customer.subscription.trial_will_end":
      // Stripe emails the customer (if enabled in Billing settings). Kept as a
      // hook point for an in-app reminder.
      console.info(`[stripe] trial ending soon for subscription ${event.data.object.id}`);
      return;

    case "invoice.paid":
    case "invoice.payment_failed": {
      // Smart Retries and Stripe's dunning emails handle recovery; the app
      // only needs the subscription status (past_due / active) kept current.
      const id = subscriptionIdFromInvoice(event.data.object);
      if (id) await syncSubscription(id);
      return;
    }

    case "charge.refunded":
    case "charge.dispute.created":
    case "radar.early_fraud_warning.created":
      // Money at risk. Logged loudly so it is never missed; decide on a policy
      // (e.g. cancel the subscription on fraud warnings) before going live.
      console.warn(`[stripe] ATTENTION ${event.type} ${event.id} — review in the Stripe Dashboard`);
      return;

    default:
      return;
  }
}
