import Link from "next/link";

export default function Home() {
  return (
    <div className="card">
      <h1>KobiAI</h1>
      <p className="sub">First product slice — customers.</p>
      <p>
        <Link href="/signup">Create an account</Link> &nbsp;·&nbsp;{" "}
        <Link href="/login">Sign in</Link>
      </p>
    </div>
  );
}
