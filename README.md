# KobiAI Engineering UK

**A software factory.** We do not build software here — we build the _line that builds software_, and we prove it by pushing one small real product through it, then hardening whatever station hurt.

- **How the factory runs:** [`FACTORY-OPERATING-MODEL.md`](FACTORY-OPERATING-MODEL.md) — one page, 7 stations, the human gates, the AI roles, and the real quality checks.
- **The plan from here:** [`PLAN.md`](PLAN.md) — start-to-end, step by step, to the first shipped product slice.

---

## What's already real (built and verified)

- **Database:** Supabase project `kobiai-engineering-uk` (London / `eu-west-2`) — 26 tables, 73 RLS policies, multi-tenant, security advisor clean. Schema lives in [`database/migrations/`](database/migrations/).
- **A real quality gate:** [`.github/workflows/ci.yml`](.github/workflows/ci.yml) actually runs — it lints docs, checks formatting, and **runs the migration test** (spins a throwaway Postgres, applies every migration, asserts the tables + RLS exist). A green tick here means the work truly passed. No placeholders, no self-scoring.

Run the quality gate locally:

```bash
# needs Docker OR a local postgres; CI runs it automatically on every push
DATABASE_URL=postgres://postgres:postgres@localhost:5432/kobiai_test npm run test:migrations
npm run lint:md
npm run format:check
```

---

## First product slice (what we build next)

Sign up → create a workspace → add a customer → see the customer in a list. Real auth, real database, real screen. See `PLAN.md` Phase 1. The app will live in [`app/`](app/).

---

## Push this repo to GitHub (2 minutes)

This package is a ready-to-push git-less folder. To put it on GitHub:

```bash
# 1. On github.com, create a new EMPTY repo named:  kobiai-engineering-uk
#    (no README, no .gitignore, no license — keep it empty)

# 2. In this folder:
git init
git add .
git commit -m "chore: initial KobiAI Engineering UK factory scaffold"
git branch -M main
git remote add origin https://github.com/Fernando280773/kobiai-engineering-uk.git
git push -u origin main
```

After the push, open the repo's **Actions** tab and watch the CI run. Green = your factory's quality-control station is live and honest.

---

## The rules that make this a factory (not a workshop)

1. A factory is proven by the products it makes — build the factory BY building products through it.
2. No AI grades its own homework. Machines (CI) and your own eyes decide "done."
3. One small real thing shipped beats a hundred specs that never run.
4. Improve the line at every point where it jammed. That is how the reusable system is earned.

---

## Layout

```text
kobiai-engineering-uk/
├── FACTORY-OPERATING-MODEL.md   # the production line (run this)
├── PLAN.md                      # start-to-end plan
├── README.md
├── .env.example                 # copy to .env, fill secrets
├── package.json                 # real scripts
├── .github/workflows/ci.yml     # REAL quality gates
├── database/
│   ├── migrations/              # 0001–0032 (Supabase-correct, auth.users)
│   └── tests/                   # bootstrap + schema assertions
├── scripts/test-migrations.sh   # the real migration test
├── app/                         # the product (built in Phase 1)
└── docs/
```
