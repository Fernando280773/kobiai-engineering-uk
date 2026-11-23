import "server-only";
import Stripe from "stripe";

/**
 * Server-only Stripe client. Created lazily so `next build` does not need the
 * key present (it is only read at request time).
 *
 * Use a RESTRICTED key (rk_...) — see app/README.md for the exact permissions.
 * Never expose this key to the browser; nothing in this app needs a
 * publishable key because checkout and the portal are Stripe-hosted.
 */
let client: Stripe | null = null;

export function stripe(): Stripe {
  if (client) return client;
  const key = process.env.STRIPE_SECRET_KEY;
  if (!key) {
    throw new Error("STRIPE_SECRET_KEY is not set. Add it to .env.local (and Vercel env vars).");
  }
  client = new Stripe(key, {
    // Pin the API version so a Dashboard upgrade can never silently change
    // the shape of objects this code reads.
    apiVersion: "2026-09-30.endive",
    appInfo: { name: "kobiai-app", url: "https://kobiai.tech" },
  });
  return client;
}

/** The public origin of this app, used for Checkout and portal return URLs. */
export function appUrl(): string {
  const url = process.env.APP_URL ?? process.env.NEXT_PUBLIC_APP_URL;
  if (url) return url.replace(/\/$/, "");
  if (process.env.VERCEL_URL) return `https://${process.env.VERCEL_URL}`;
  return "http://localhost:3000";
}
