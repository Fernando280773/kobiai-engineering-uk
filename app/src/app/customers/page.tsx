import { createServerSupabase } from "@/lib/supabase-server";
import { getOrCreateWorkspaceId, signOut } from "./actions";
import { AddCustomerForm } from "./add-customer-form";

export const dynamic = "force-dynamic";

export default async function CustomersPage() {
  // Ensures a first-time user has a workspace before we list anything.
  await getOrCreateWorkspaceId();

  const supabase = await createServerSupabase();

  // No workspace filter here on purpose: RLS scopes this to the caller's
  // workspaces at the database level. If this ever leaked, the policy smoke
  // test in CI would already have gone red.
  const { data: customers, error } = await supabase
    .from("customers")
    .select("id, customer_code, name, email, phone")
    .order("created_at", { ascending: false });

  return (
    <>
      <div className="row">
        <div>
          <h1>Customers</h1>
          <p className="sub">Everything in your workspace.</p>
        </div>
        <form action={signOut}>
          <button type="submit">Sign out</button>
        </form>
      </div>

      <div className="card">
        <h1 style={{ fontSize: 16 }}>Add a customer</h1>
        <AddCustomerForm />
      </div>

      <div className="card">
        {error && <p className="error">{error.message}</p>}

        {!error && (!customers || customers.length === 0) ? (
          <p className="empty">No customers yet. Add your first one above.</p>
        ) : (
          <table>
            <thead>
              <tr>
                <th>Name</th>
                <th>Code</th>
                <th>Email</th>
                <th>Phone</th>
              </tr>
            </thead>
            <tbody>
              {customers?.map((c) => (
                <tr key={c.id}>
                  <td data-testid="customer-name">{c.name}</td>
                  <td>{c.customer_code}</td>
                  <td>{c.email ?? "—"}</td>
                  <td>{c.phone ?? "—"}</td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>
    </>
  );
}
