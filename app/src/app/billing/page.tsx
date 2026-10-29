import Link from "next/link";
import { createServerSupabase } from "@/lib/supabase-server";
import { ENTITLED_STATUSES, PLANS, TRIAL_DAYS } from "@/lib/billing";
import { ensureWorkspace } from "../customers/actions";
import { openPortal, startCheckout } from "./actions";

export const dynamic = "force-dynamic";

const STATUS_LABEL: Record<string, string> = {
  trialing: "Free trial",
  active: "Active",
  past_due: "Payment failed — please update your card",
  unpaid: "Unpaid",
  canceled: "Cancelled",
  incomplete: "Waiting for payment",
  incomplete_expired: "Checkout expired",
  paused: "Paused",
};

function date(iso: string | null): string {
  return iso ? new Date(iso).toLocaleDateString("en-GB", { day: "numeric", month: "long", year: "numeric" }) : "";
}

export default async function BillingPage({
  searchParams,
}: {
  searchParams: Promise<{ checkout?: string }>;
}) {
  const { checkout } = await searchParams;
  const { data: workspaceId, error: workspaceError } = await ensureWorkspace();

  const supabase = await createServerSupabase();
  const { data: billing } = workspaceId
    ? await supabase
        .from("workspace_billing")
        .select("plan, status, trial_end, current_period_end, cancel_at_period_end, stripe_subscription_id")
        .eq("workspace_id", workspaceId)
        .maybeSingle()
    : { data: null };

  const status = (billing?.status as string | null) ?? null;
  const entitled = status !== null && ENTITLED_STATUSES.has(status);
  const planName = PLANS.find((p) => p.id === billing?.plan)?.name ?? null;
  const neverSubscribed = !billing?.stripe_subscription_id;

  return (
    <>
      <div className="row">
        <div>
          <h1>Billing</h1>
          <p className="sub">Your KobiAI plan, invoices and payment details.</p>
        </div>
        <Link href="/customers">Back to customers</Link>
      </div>

      {workspaceError && (
        <div className="card">
          <p className="error" role="alert">
            {workspaceError}
          </p>
        </div>
      )}

      {checkout === "success" && !entitled && (
        <div className="card" data-testid="checkout-pending">
          <p>Thanks — we&apos;re confirming your payment with Stripe. Refresh in a few seconds.</p>
        </div>
      )}

      {status && (
        <div className="card" data-testid="billing-status">
          <p>
            <strong>{planName ?? "Plan"}</strong> — {STATUS_LABEL[status] ?? status}
          </p>
          {status === "trialing" && billing?.trial_end && (
            <p className="sub">Trial ends {date(billing.trial_end as string)}. You won&apos;t be charged before then.</p>
          )}
          {entitled && billing?.current_period_end && (
            <p className="sub">
              {billing.cancel_at_period_end ? "Ends" : "Renews"} {date(billing.current_period_end as string)}
            </p>
          )}
          <form action={openPortal}>
            <button type="submit">Manage billing &amp; invoices</button>
          </form>
        </div>
      )}

      {!entitled &&
        PLANS.map((plan) => (
          <div className="card" key={plan.id}>
            <h1 style={{ fontSize: 18 }}>{plan.name}</h1>
            <p className="sub">{plan.blurb}</p>
            <div className="row" style={{ justifyContent: "flex-start" }}>
              {(["monthly", "yearly"] as const).map((interval) => (
                <form action={startCheckout} key={interval}>
                  <input type="hidden" name="plan" value={plan.id} />
                  <input type="hidden" name="interval" value={interval} />
                  <button type="submit">{plan[interval].label}</button>
                </form>
              ))}
            </div>
            {neverSubscribed && <p className="sub">{TRIAL_DAYS}-day free trial. Prices exclude VAT.</p>}
          </div>
        ))}
    </>
  );
}
