"use client";

import { useEffect } from "react";

/**
 * Last line of defence. Without this, a server-side throw renders a blank page
 * (and, if it happened during a client navigation, left the button that
 * triggered it spinning forever with no explanation). Now the reason is always
 * on screen and always assertable by the e2e test via role="alert".
 */
export default function Error({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  useEffect(() => {
    console.error(error);
  }, [error]);

  return (
    <div className="card">
      <h1>Something went wrong</h1>
      <p className="error" role="alert" data-testid="form-error">
        {error.message || "Unknown error"}
      </p>
      {error.digest && (
        <p className="sub">
          Reference: <code>{error.digest}</code>
        </p>
      )}
      <button type="button" onClick={reset}>
        Try again
      </button>
    </div>
  );
}
