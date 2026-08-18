"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { createServerSupabase } from "@/lib/supabase-server";

export type Result<T> = { data: T | null; error: string | null };

/**
 * Turns a Supabase/PostgREST error into something a human can act on.
 * PGRST202 in particular means the RPC exists in the database but PostgREST
 * has not reloaded its schema cache yet — an easy failure to misread.
 */
function explain(error: { code?: string; message: string }): string {
  if (error.code === "PGRST202") {
    return (
      "The create_workspace function is not visible to the API yet. " +
      "Run `notify pgrst, 'reload schema';` in the Supabase SQL editor, then retry."
    );
  }
  if (error.code === "42501") {
    return "Permission denied by row-level security.";
  }
  if (error.code === "23505") {
    return "That value is already used.";
  }
  return error.message;
}

/**
 * Returns the caller's workspace id, creating their first workspace if they
 * have none. Creation goes through the create_workspace() RPC (migration 0034)
 * because a brand-new user is not yet a member of any workspace and therefore
 * cannot insert one directly under RLS.
 *
 * Returns errors instead of throwing: a throw here crashes the /customers
 * render, which shows the user nothing and leaves the sign-up button spinning.
 */
export async function ensureWorkspace(): Promise<Result<string>> {
  const supabase = await createServerSupabase();

  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) redirect("/login");

  const { data: existing, error: readError } = await supabase
    .from("workspace_members")
    .select("workspace_id")
    .limit(1);

  if (readError) return { data: null, error: explain(readError) };
  if (existing && existing.length > 0) {
    return { data: existing[0].workspace_id as string, error: null };
  }

  const base = (user.email ?? "workspace").split("@")[0];
  const slug = `${base.replace(/[^a-z0-9]+/gi, "-").toLowerCase()}-${user.id.slice(0, 8)}`;

  const { data: created, error: rpcError } = await supabase.rpc("create_workspace", {
    p_name: `${base}'s workspace`,
    p_slug: slug,
  });

  if (rpcError) return { data: null, error: explain(rpcError) };
  return { data: created as string, error: null };
}

export type AddCustomerState = { error: string | null };

export async function addCustomer(
  _prev: AddCustomerState,
  formData: FormData,
): Promise<AddCustomerState> {
  const name = String(formData.get("name") ?? "").trim();
  const customerCode = String(formData.get("customer_code") ?? "").trim();
  const email = String(formData.get("email") ?? "").trim();
  const phone = String(formData.get("phone") ?? "").trim();

  if (!name) return { error: "Name is required." };
  if (!customerCode) return { error: "Customer code is required." };

  const { data: workspaceId, error: wsError } = await ensureWorkspace();
  if (wsError || !workspaceId) {
    return { error: wsError ?? "Could not resolve your workspace." };
  }

  const supabase = await createServerSupabase();
  const { error } = await supabase.from("customers").insert({
    workspace_id: workspaceId,
    customer_code: customerCode,
    name,
    email: email || null,
    phone: phone || null,
  });

  if (error) {
    if (error.code === "23505") {
      return { error: `Customer code "${customerCode}" is already used.` };
    }
    return { error: explain(error) };
  }

  revalidatePath("/customers");
  return { error: null };
}

export async function signOut() {
  const supabase = await createServerSupabase();
  await supabase.auth.signOut();
  redirect("/login");
}
