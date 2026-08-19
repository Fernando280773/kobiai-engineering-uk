"use client";

import { useState, useTransition } from "react";
import { updateCustomer, deleteCustomer } from "./actions";

export type Customer = {
  id: string;
  customer_code: string;
  name: string;
  email: string | null;
  phone: string | null;
};

type Mode = "view" | "edit" | "confirm-delete";

export function CustomerRow({ customer }: { customer: Customer }) {
  const [mode, setMode] = useState<Mode>("view");
  const [error, setError] = useState<string | null>(null);
  const [pending, startTransition] = useTransition();
  const [form, setForm] = useState({
    name: customer.name,
    customer_code: customer.customer_code,
    email: customer.email ?? "",
    phone: customer.phone ?? "",
  });

  function save() {
    setError(null);
    startTransition(async () => {
      const { error } = await updateCustomer(customer.id, form);
      if (error) setError(error);
      else setMode("view");
    });
  }

  function remove() {
    setError(null);
    startTransition(async () => {
      const { error } = await deleteCustomer(customer.id);
      // On success the row disappears with the revalidated list, so there is
      // nothing to reset here.
      if (error) {
        setError(error);
        setMode("view");
      }
    });
  }

  function cancelEdit() {
    setForm({
      name: customer.name,
      customer_code: customer.customer_code,
      email: customer.email ?? "",
      phone: customer.phone ?? "",
    });
    setError(null);
    setMode("view");
  }

  if (mode === "edit") {
    return (
      <tr data-testid="customer-row">
        <td>
          <input
            data-testid="edit-name"
            aria-label="Edit name"
            value={form.name}
            onChange={(e) => setForm({ ...form, name: e.target.value })}
          />
        </td>
        <td>
          <input
            data-testid="edit-code"
            aria-label="Edit customer code"
            value={form.customer_code}
            onChange={(e) => setForm({ ...form, customer_code: e.target.value })}
          />
        </td>
        <td>
          <input
            data-testid="edit-email"
            aria-label="Edit email"
            value={form.email}
            onChange={(e) => setForm({ ...form, email: e.target.value })}
          />
        </td>
        <td>
          <input
            data-testid="edit-phone"
            aria-label="Edit phone"
            value={form.phone}
            onChange={(e) => setForm({ ...form, phone: e.target.value })}
          />
        </td>
        <td className="actions">
          <button type="button" onClick={save} disabled={pending}>
            {pending ? "Saving…" : "Save"}
          </button>
          <button type="button" onClick={cancelEdit} disabled={pending}>
            Cancel
          </button>
          {error && (
            <p className="error" role="alert" data-testid="form-error">
              {error}
            </p>
          )}
        </td>
      </tr>
    );
  }

  return (
    <tr data-testid="customer-row">
      <td data-testid="customer-name">{customer.name}</td>
      <td>{customer.customer_code}</td>
      <td>{customer.email ?? "—"}</td>
      <td>{customer.phone ?? "—"}</td>
      <td className="actions">
        {mode === "view" ? (
          <>
            <button type="button" onClick={() => setMode("edit")}>
              Edit
            </button>
            <button type="button" onClick={() => setMode("confirm-delete")}>
              Delete
            </button>
          </>
        ) : (
          // Inline confirm on purpose. A browser confirm() dialog blocks
          // automation entirely and is worse UX besides.
          <span className="confirm">
            <span className="sub">Delete this customer?</span>
            <button type="button" onClick={remove} disabled={pending}>
              {pending ? "Removing…" : "Yes, remove"}
            </button>
            <button type="button" onClick={() => setMode("view")} disabled={pending}>
              Cancel
            </button>
          </span>
        )}
        {error && (
          <p className="error" role="alert" data-testid="form-error">
            {error}
          </p>
        )}
      </td>
    </tr>
  );
}
