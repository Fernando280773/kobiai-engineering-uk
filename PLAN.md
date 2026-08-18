# KobiAI Engineering UK — Start-to-End Plan

**Goal:** Build the software _factory_ by pushing one small real product slice through it, end to end, and hardening the line as we go.
**First product slice (the "Model T" of this factory):** Sign up → create a workspace → add a customer → see the customer in a list. Real auth, real database, real screen.
**Why this slice:** it exercises the whole line (auth, DB, API, UI, tests, deploy) while staying tiny, and the database for it is already built and deployed.

---

## Phase 0 — Foundation (this week) ✅ mostly done today

| Step | What                                                     | Status                          |
| :--- | :------------------------------------------------------- | :------------------------------ |
| 0.1  | New Supabase project `kobiai-engineering-uk` (London)    | ✅ created today                |
| 0.2  | Clean, corrected schema applied (auth.users fixed)       | ✅ applied today                |
| 0.3  | New repo `kobiai-engineering-uk` with REAL quality gates | ✅ built today (this package)   |
| 0.4  | Push repo to GitHub                                      | ⬜ you (steps in README)        |
| 0.5  | Confirm CI runs green on GitHub                          | ⬜ you push → watch Actions tab |

At the end of Phase 0 you have a factory floor: a clean database, a repo, and a machine that checks work automatically.

---

## Phase 1 — First slice through the line (Week 1–2)

Follow the 7 stations in FACTORY-OPERATING-MODEL.md. One slice:

1. **Order (you):** "As a user I can sign up, create my workspace, add a customer, and see it in a list."
2. **Spec (Architect AI):** ½-page spec — tables (`workspaces`, `workspace_members`, `customers`), one API per action, one list screen, one test.
3. **Gate A (you):** approve the ½ page.
4. **Build (Builder AI):** a minimal app (Next.js + Supabase Auth) with those screens + one end-to-end test.
5. **Quality Gate (CI):** lint + typecheck + migration test + the new test all green.
6. **Gate B (you):** open it in your browser, sign up, add a customer, see it listed.
7. **Ship + Learn:** deploy (Vercel free tier), then note the one thing that was clumsy and fix it.

**Definition of done for Phase 1:** you can show another human a live URL where they sign up and add a customer. That is your factory's first real product off the line.

---

## Phase 2 — Prove repeatability (Week 3–4)

Run the line twice more with equally small slices, e.g.:

- Slice 2: edit / delete a customer.
- Slice 3: add a "contact" under a customer (uses the `contacts` table).

The point is NOT features. The point is proving the line runs the same way every time, faster each time. After Slice 3, write down your factory's real, earned rules (a short "how we build" doc) — extracted from what actually happened, not guessed.

---

## Phase 3 — First real product surface (Month 2)

Pick ONE product to make genuinely good first. Recommended: **the CRM** (customers → contacts → opportunities → activities), because the schema is furthest along there and it's the beating heart of a Business OS. Everything else (website builder, marketing, AI workforce, etc.) is future backlog — not now.

Ship a CRM a real small business could actually use for their contacts and deals. Get ONE real user (even a friend's business). Their feedback becomes your next tickets.

---

## Phase 4 — Scale the factory, not the scope (Month 3+)

Only now do you invest again in the "engineering system" — but this time you're documenting a factory that has actually produced things. Add reusable build-kit templates, more automated checks, and a second Builder AI running slices in parallel. The maturity model measures _shipped_, not _specified_.

---

## What we deliberately are NOT doing (for now)

- ❌ No new ADRs, handbook volumes, or maturity levels until Phase 2 is done.
- ❌ No building 10 products at once. One surface (CRM) first.
- ❌ No AI self-scores as sign-off. Machines and your eyes decide.
- ❌ No direct psql/IPv6 rabbit holes — the Supabase connector and CI handle the DB.

---

## The one metric that matters

**Weeks since the last real thing shipped.** Keep it at 1. If it climbs, the factory has stopped — go make the smallest real thing and ship it.

---

## Where things live

- **Database:** Supabase project `kobiai-engineering-uk` (London / eu-west-2). Keys in `.env` (built for you).
- **Code + factory docs:** this repo `kobiai-engineering-uk`.
- **Old repo `kobiai-engineering`:** keep it as an archive/reference. Do not delete — it holds the good schema thinking and the vision. But new work happens here.
