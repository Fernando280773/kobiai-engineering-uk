import { createBrowserClient } from "@supabase/ssr";

/**
 * Browser client — used by the sign-up / sign-in forms.
 * Kept in its own file so client components never pull in `next/headers`,
 * which is server-only and breaks the build if bundled for the browser.
 */
export function createClient() {
  return createBrowserClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
  );
}
