import "server-only";
import { createClient, type SupabaseClient } from "@supabase/supabase-js";

/**
 * Service-role Supabase client. BYPASSES ROW-LEVEL SECURITY.
 *
 * Only for trusted server code that writes workspace_billing, which users
 * cannot write themselves: the Stripe webhook, and saving a new Stripe
 * customer id in billing/actions.ts (for a workspace id taken from the
 * caller's own membership). Never let user input decide which rows it touches.
 */
let admin: SupabaseClient | null = null;

export function supabaseAdmin(): SupabaseClient {
  if (admin) return admin;
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const secret = process.env.SUPABASE_SECRET_KEY;
  if (!url || !secret) {
    throw new Error("NEXT_PUBLIC_SUPABASE_URL and SUPABASE_SECRET_KEY must be set for the Stripe webhook.");
  }
  admin = createClient(url, secret, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
  return admin;
}
