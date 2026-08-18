"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { createServerSupabase } from "@/lib/supabase-server";

/**
 * Returns the caller's workspace id, creating their first workspace if they
 * have none. Creation goes through the create_workspace() RPC (migration 0034)
 * because a brand-new user is not yet a member of any workspace and therefore
 * cannot insert one directly under RLS.
 */
export async function getOrCreateWorkspaceId(): Promise<string> {
  const supabase = await createServerSupabase();

  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) redirect("/login");

  const { data: existing, error: readError } = await supabase
    .from("workspace_members")
    .select("workspace_id")
    .limit(1);

  if (readError) throw new Error(readError.message);
  if (existing && existing.length > 0) return existing[0].workspace_id;

  const base = (user.email ?? "workspace").split("@")[0];
  const slug = `${base.replace(/[^a-z0-9]+/gi, "-").toLowerCase()}-${user.id.slice(0, 8)}`;

  const { data: created, error: rpcError } = await supabase.rpc(
    "create_workspace",
    { p_name: `${base}'s workspace`, p_slug: slug },
  );

  if (rpcError) throw new Error(rpcError.message);
  return created as string;
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

  const supabase = await createServerSupabase();
  const workspaceId = await getOrCreateWorkspaceId();

  const { error } = await supabase.from("customers").insert({
    workspace_id: workspaceId,
    customer_code: customerCode,
    name,
    email: email || null,
    phone: phone || null,
  });

  if (error) {
    // Friendlier message for the per-workspace unique constraint.
    if (error.code === "23505") {
      return { error: `Customer code "${customerCode}" is already used.` };
    }
    return { error: error.message };
  }

  revalidatePath("/customers");
  return { error: null };
}

export async function signOut() {
  const supabase = await createServerSupabase();
  await supabase.auth.signOut();
  redirect("/login");
}
