"use client";

import { useActionState, useEffect, useRef } from "react";
import { addCustomer, type AddCustomerState } from "./actions";

const initialState: AddCustomerState = { error: null };

export function AddCustomerForm() {
  const [state, formAction, pending] = useActionState(
    addCustomer,
    initialState,
  );
  const formRef = useRef<HTMLFormElement>(null);

  // Clear the form only after a successful submit.
  useEffect(() => {
    if (!pending && state.error === null) formRef.current?.reset();
  }, [state, pending]);

  return (
    <form ref={formRef} action={formAction}>
      <label htmlFor="name">Name</label>
      <input id="name" name="name" required placeholder="Acme Ltd" />

      <label htmlFor="customer_code">Customer code</label>
      <input
        id="customer_code"
        name="customer_code"
        required
        placeholder="CUST-001"
      />

      <label htmlFor="email">Email</label>
      <input id="email" name="email" type="email" placeholder="optional" />

      <label htmlFor="phone">Phone</label>
      <input id="phone" name="phone" placeholder="optional" />

      <button type="submit" disabled={pending}>
        {pending ? "Adding…" : "Add customer"}
      </button>

      {state.error && <p className="error">{state.error}</p>}
    </form>
  );
}
