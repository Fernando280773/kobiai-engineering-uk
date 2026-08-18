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
const alice = {
  email: `alice+${stamp}@kobiai-e2e.test`,
  password: "e2e-password-123",
};
const bob = {
  email: `bob+${stamp}@kobiai-e2e.test`,
  password: "e2e-password-123",
};
const CUSTOMER = `Acme Ltd ${stamp}`;

async function signUp(page: Page, user: { email: string; password: string }) {
  await page.goto("/signup");
  await page.getByLabel("Email").fill(user.email);
  await page.getByLabel("Password").fill(user.password);
  await page.getByRole("button", { name: /create account/i }).click();
  await expect(page).toHaveURL(/\/customers/, { timeout: 30_000 });
}

test("first slice: sign up, add a customer, and stay isolated", async ({
  browser,
}) => {
  // --- Alice ---------------------------------------------------------------
  const aliceCtx = await browser.newContext();
  const alicePage = await aliceCtx.newPage();

  await signUp(alicePage, alice);

  // A brand-new user lands on an empty list, not an error.
  await expect(alicePage.getByText(/no customers yet/i)).toBeVisible();

  await alicePage.getByLabel("Name").fill(CUSTOMER);
  await alicePage.getByLabel("Customer code").fill(`CUST-${stamp}`);
  await alicePage.getByRole("button", { name: /add customer/i }).click();

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
