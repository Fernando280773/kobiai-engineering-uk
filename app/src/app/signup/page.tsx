"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import Link from "next/link";
import { createClient } from "@/lib/supabase-browser";

export default function SignupPage() {
  const router = useRouter();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  async function onSubmit(e: React.FormEvent) {
    e.preventDefault();
    setBusy(true);
    setError(null);

    const supabase = createClient();
    const { data, error } = await supabase.auth.signUp({ email, password });

    if (error) {
      setError(error.message);
      setBusy(false);
      return;
    }

    // If the project requires email confirmation there is no session yet.
    if (!data.session) {
      setError("Check your email to confirm your account, then sign in.");
      setBusy(false);
      return;
    }

    router.push("/customers");
    router.refresh();
  }

  return (
    <div className="card">
      <h1>Create your account</h1>
      <p className="sub">Your workspace is created automatically.</p>

      <form onSubmit={onSubmit}>
        <label htmlFor="email">Email</label>
        <input
          id="email"
          name="email"
          type="email"
          required
          value={email}
          onChange={(e) => setEmail(e.target.value)}
        />

        <label htmlFor="password">Password</label>
        <input
          id="password"
          name="password"
          type="password"
          required
          minLength={6}
          value={password}
          onChange={(e) => setPassword(e.target.value)}
        />

        <button type="submit" disabled={busy}>
          {busy ? "Creating…" : "Create account"}
        </button>
      </form>

      {error && <p className="error">{error}</p>}

      <p className="sub" style={{ marginTop: 20 }}>
        Already have an account? <Link href="/login">Sign in</Link>
      </p>
    </div>
  );
}
