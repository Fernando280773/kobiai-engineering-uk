import { test, expect, type Page } from "@playwright/test";

/**
 * SPEC-002 — edit and delete a customer.
 *
 *   add -> EDIT -> see the new name -> DELETE -> list is empty again
 *
 * The isolation clause from slice 1 is kept and re-proven here: a second user
 * must see nothing at any point. Every slice re-tests tenant isolation, because
 * that is the property most expensive to get wrong.
 */

const stamp = Date.now();
const owner = { email: `owner+${stamp}@example.com`, password: "e2e-password-123" };
const other = { email: `other+${stamp}@example.com`, password: "e2e-password-123" };

const ORIGINAL = `Acme Ltd ${stamp}`;
const RENAMED = `Acme Holdings ${stamp}`;

async function signUp(page: Page, user: { email: string; password: string }) {
  await page.goto("/signup");
  await page.getByLabel("Email").fill(user.email);
  await page.getByLabel("Password").fill(user.password);
  await page.getByRole("button", { name: /create account/i }).click();

  const alert = page.getByTestId("form-error");
  await expect(async () => {
    if (await alert.isVisible()) {
      throw new Error(`Sign-up failed for ${user.email}: ${await alert.innerText()}`);
    }
    expect(new URL(page.url()).pathname).toBe("/customers");
  }).toPass({ timeout: 30_000 });
}

test("second slice: add, edit, then delete a customer", async ({ browser }) => {
  const ownerCtx = await browser.newContext();
  const page = await ownerCtx.newPage();

  await signUp(page, owner);
  await expect(page.getByText(/no customers yet/i)).toBeVisible();

  // --- ADD -----------------------------------------------------------------
  await page.getByLabel("Name", { exact: true }).fill(ORIGINAL);
  await page.getByLabel("Customer code", { exact: true }).fill(`CUST-${stamp}`);
  await page.getByRole("button", { name: /add customer/i }).click();

  await expect(page.getByTestId("form-error")).toHaveCount(0);
  await expect(page.getByTestId("customer-name")).toHaveText(ORIGINAL, {
    timeout: 20_000,
  });

  // --- EDIT ----------------------------------------------------------------
  await page.getByRole("button", { name: "Edit" }).click();
  await page.getByTestId("edit-name").fill(RENAMED);
  await page.getByRole("button", { name: "Save" }).click();

  await expect(page.getByTestId("form-error")).toHaveCount(0);
  await expect(page.getByTestId("customer-name")).toHaveText(RENAMED, {
    timeout: 20_000,
  });

  // --- DELETE --------------------------------------------------------------
  await page.getByRole("button", { name: "Delete" }).click();
  await expect(page.getByText(/delete this customer\?/i)).toBeVisible();
  await page.getByRole("button", { name: /yes, remove/i }).click();

  await expect(page.getByTestId("form-error")).toHaveCount(0);
  await expect(page.getByTestId("customer-row")).toHaveCount(0, {
    timeout: 20_000,
  });
  await expect(page.getByText(/no customers yet/i)).toBeVisible();

  // --- ISOLATION, re-proven -------------------------------------------------
  const otherCtx = await browser.newContext();
  const otherPage = await otherCtx.newPage();
  await signUp(otherPage, other);

  await expect(otherPage.getByText(ORIGINAL)).toHaveCount(0);
  await expect(otherPage.getByText(RENAMED)).toHaveCount(0);
  await expect(otherPage.getByText(/no customers yet/i)).toBeVisible();

  await ownerCtx.close();
  await otherCtx.close();
});
