import { createServerSupabase } from "@/lib/supabase-server";
import { ensureWorkspace, signOut } from "./actions";
import { AddCustomerForm } from "./add-customer-form";
import { CustomerRow, type Customer } from "./customer-row";

export const dynamic = "force-dynamic";

export default async function CustomersPage() {
  // A first-time user gets their workspace here. If this fails we render the
  // reason rather than throwing — a throw would blank the page and leave the
  // sign-up button spinning with nothing to explain why.
  const { error: workspaceError } = await ensureWorkspace();

  const supabase = await createServerSupabase();

  // No workspace filter on purpose: RLS scopes this to the caller's workspaces
  // at the database level. If this ever leaked, the policy smoke test in CI
  // would already have gone red.
  const { data: customers, error: listError } = workspaceError
    ? { data: null, error: null }
    : await supabase
        .from("customers")
        .select("id, customer_code, name, email, phone")
        .order("created_at", { ascending: false });

  const error = workspaceError ?? listError?.message ?? null;

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

      {error && (
        <div className="card">
          <p className="error" role="alert" data-testid="form-error">
            {error}
          </p>
        </div>
      )}

      {!error && (
        <>
          <div className="card">
            <h1 style={{ fontSize: 16 }}>Add a customer</h1>
            <AddCustomerForm />
          </div>

          <div className="card">
            {!customers || customers.length === 0 ? (
              <p className="empty">No customers yet. Add your first one above.</p>
            ) : (
              <table>
                <thead>
                  <tr>
                    <th>Name</th>
                    <th>Code</th>
                    <th>Email</th>
                    <th>Phone</th>
                    <th></th>
                  </tr>
                </thead>
                <tbody>
                  {customers.map((c) => (
                    <CustomerRow key={c.id} customer={c as Customer} />
                  ))}
                </tbody>
              </table>
            )}
          </div>
        </>
      )}
    </>
  );
}
