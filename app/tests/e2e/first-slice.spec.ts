import { test, expect, type Page } from "@playwright/test";

/**
 * SPEC-001 — the ONE test that proves the first slice works.
 *
 *   sign up -> workspace created -> add a customer -> see it in the list
 *   then: a SECOND user must NOT see the first user's customer.
 *
 * That last clause is the point. It proves tenant isolation actually holds
 * through the real app, rather than trusting that RLS is switched on.
 */

const stamp = Date.now();

// example.com is a reserved, syntactically valid domain. Reserved TLDs such as
// .test are rejected by some Supabase email validation settings.
const alice = { email: `alice+${stamp}@example.com`, password: "e2e-password-123" };
const bob = { email: `bob+${stamp}@example.com`, password: "e2e-password-123" };
const CUSTOMER = `Acme Ltd ${stamp}`;

/**
 * Signs up and waits to land on /customers.
 *
 * Rather than waiting blindly on the URL, this fails fast with the app's own
 * error text. A bare `toHaveURL` timeout only tells you the page did not move;
 * it does not tell you why — which is exactly what happened the first time this
 * test ran against a misconfigured backend.
 */
async function signUp(page: Page, user: { email: string; password: string }) {
  await page.goto("/signup");
  await page.getByLabel("Email").fill(user.email);
  await page.getByLabel("Password").fill(user.password);
  await page.getByRole("button", { name: /create account/i }).click();

  // getByTestId, not getByRole("alert"): Next.js renders its own
  // #__next-route-announcer__ with role="alert", which makes that role
  // ambiguous in strict mode. role="alert" is kept on the element for
  // screen readers; the test id is what makes it addressable.
  const alert = page.getByTestId("form-error");

  await expect(async () => {
    if (await alert.isVisible()) {
      throw new Error(`Sign-up failed for ${user.email}: ${await alert.innerText()}`);
    }
    expect(new URL(page.url()).pathname).toBe("/customers");
  }).toPass({ timeout: 30_000 });
}

test("first slice: sign up, add a customer, and stay isolated", async ({ browser }) => {
  // --- Alice ---------------------------------------------------------------
  const aliceCtx = await browser.newContext();
  const alicePage = await aliceCtx.newPage();

  await signUp(alicePage, alice);

  // A brand-new user lands on an empty list, not an error.
  await expect(alicePage.getByText(/no customers yet/i)).toBeVisible();

  await alicePage.getByLabel("Name").fill(CUSTOMER);
  await alicePage.getByLabel("Customer code").fill(`CUST-${stamp}`);
  await alicePage.getByRole("button", { name: /add customer/i }).click();

  // Surface a rejected insert instead of waiting out the row assertion.
  await expect(alicePage.getByTestId("form-error")).toHaveCount(0);

  // She sees it in her list.
  await expect(alicePage.getByTestId("customer-name")).toHaveText(CUSTOMER, {
    timeout: 20_000,
  });

  // --- Bob (separate browser context = separate session) --------------------
  const bobCtx = await browser.newContext();
  const bobPage = await bobCtx.newPage();

  await signUp(bobPage, bob);

  // The whole point: Bob must not see Alice's customer.
  await expect(bobPage.getByText(CUSTOMER)).toHaveCount(0);
  await expect(bobPage.getByText(/no customers yet/i)).toBeVisible();

  await aliceCtx.close();
  await bobCtx.close();
});
