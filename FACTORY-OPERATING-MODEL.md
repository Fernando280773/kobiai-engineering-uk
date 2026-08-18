# KobiAI Software Factory — Operating Model (v1)

**One page you can run this week.** This is not the product. This is the *line that builds products*. You prove the factory by pushing one small real product through it — then you harden whatever station hurt.

---

## The core rule

> A factory is proven by the products it makes — never before.
> We build the factory BY building one product through it.

No new governance documents, ADRs, or maturity levels are created until a product slice has passed all the way through the line. The framework we already have is enough for v1.

---

## The production line (7 stations)

Every unit of work (one small feature) flows left to right. It cannot skip a station. A station either **passes it on** or **sends it back**.

| # | Station | Who runs it | Input → Output | Pass rule (Definition of Done) |
|:--|:--------|:------------|:---------------|:-------------------------------|
| 1 | **Order** | 👤 You | Idea → one-line job ticket | One sentence a customer would recognise. "As a user I can add a customer and see it in a list." |
| 2 | **Spec** | 🤖 Architect AI | Ticket → tiny spec (½ page max) | Names the tables touched, the API route, the screen, and the ONE test that proves it works. |
| 3 | **Human Gate A** | 👤 You | Spec → approved spec | You read ½ page and say "build it" or "change X." 2 minutes. |
| 4 | **Build** | 🤖 Builder AI | Spec → code + its test | Code compiles, the one test is written, runs locally, and passes. |
| 5 | **Quality Gate** | ⚙️ Machine (CI) | Code → green or red | Automated: lint + format + typecheck + the migration/test all pass. **No human can override red.** |
| 6 | **Human Gate B** | 👤 You | Green build → you click it | You open the screen and use it yourself. Works → approve. Doesn't → back to Station 4. |
| 7 | **Ship + Learn** | 👤 You + 🤖 | Approved → merged & deployed | Merged to main, live on the UK Supabase DB. Then: *what part of the line was clumsy?* Fix that one thing. |

---

## The three roles (never blur them)

- 👤 **You — the Owner.** You own Stations 1, 3, 6, 7. Vision, approval, and the final "yes." You never write specs or code. Your job is to decide and to judge the result with your own eyes.
- 🤖 **Architect AI** (e.g. ChatGPT / Claude). Owns Station 2. Turns a ticket into a tiny spec. Does **not** grade its own work.
- 🤖 **Builder AI** (e.g. Anti-Gravity / a coding agent). Owns Station 4. Writes code + the test. Does **not** approve its own work.

The rule that fixes the old system: **no AI grades its own homework.** The Architect specs, the Builder builds, and an *independent machine* (CI) and *you* decide if it passed. That is the difference between a factory and a workshop.

---

## The quality gates (where "done" is decided, not claimed)

1. **Machine gate (Station 5 — the important one).** CI runs on every change. It lints, formats, typechecks, and **runs the real migration test** (applies all SQL to a throwaway database and asserts the tables exist). Green means it actually works. Red blocks the merge. This is the gate that would have caught the `public.users` bug. It replaces every fake "AUDIT PASSED — 100/100."
2. **Human gate (Station 6).** You use the thing. A screen you can click beats any score an AI gives itself.

---

## What "improving the factory" means

After each product slice ships (Station 7), ask one question: **where did the line jam?**
- Spec was vague? → improve the spec template.
- Builder made the same mistake twice? → add a rule to the builder's instructions.
- A bug reached you? → add a test so that class of bug can never pass Station 5 again.

Each fix is a permanent factory upgrade. This is how the reusable engineering system is *earned* — extracted from real production, Toyota-style — instead of written in advance.

---

## The weekly rhythm (sustainable — this is a marathon)

- **Mon:** You write 1–3 job tickets (Station 1).
- **Tue–Thu:** Spec → approve → build → CI → you click it (Stations 2–6). Aim for 1 slice fully shipped.
- **Fri:** Ship what's green (Station 7) + one factory improvement. Stop. Rest.

One shipped slice a week beats ten specs that never run. Small, real, repeated.

---

## Success test for the factory itself

The factory is real when: **a new small feature can go from your one-line ticket to live-on-screen, with a machine — not an AI's opinion — certifying it works, in under a week, repeatedly.** Hit that three times and you don't have a plan for a factory. You have a factory.
