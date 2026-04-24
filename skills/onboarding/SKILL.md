---
name: onboarding
description: Generate developer onboarding documentation accurate enough that a new developer is productive within their first day
compatibility: opencode
---

Looking at this codebase — generate developer onboarding documentation accurate enough that a new developer can be productive within their first day, without needing to ask anyone to explain how things work.

**Goldilocks scope:** enough to orient and unblock. Not a comprehensive manual. A new developer should be able to: run the project, understand its structure, write code that fits in, and know where to find the rest.

> [!NOTE]
> **When NOT to use:** Don't use to generate aspirational docs that describe what the project should be — onboarding docs must reflect current reality. Don't pad with generic advice the target reader already knows.

## Protocol

1. Read the codebase: README, package manifest, directory structure, key domain files, config, CI/CD pipeline.
2. Identify what's non-obvious about running, contributing to, or extending this project.
3. Generate the documentation below. Write for the reader — a competent developer who has never seen this project.
4. Flag anything that cannot be determined from the code (credentials, non-obvious external dependencies, environment-specific setup) — do not fabricate.

**Do not pad with obvious instructions** (don't explain what `git clone` does). **Do not omit non-obvious steps** (a missing env var that causes a cryptic error costs 30 minutes).

---

## Format

### What Is This?

One paragraph. The system's purpose, who uses it, and what problem it solves. No tech stack yet.

### Quick Start

Copy-pasteable commands from zero to running. Mentally trace each step — every command must work:

```bash
# Prerequisites (list exact versions if they matter)
node >= 20.x, docker >= 24.x

# Clone and install
git clone ...
cd project
cp .env.example .env  # fill in X and Y (see Environment Variables below)
npm install

# Run
docker compose up -d  # starts postgres and redis
npm run dev           # starts the dev server on :3000

# Verify
curl http://localhost:3000/health  # should return {"status":"ok"}

# Run tests
npm test              # unit tests
npm run test:int      # integration tests (requires docker compose)
```

### Environment Variables

List every required variable, what it controls, and where to get it. Use `.env.example` as the source of truth — keep this section in sync with it.

| Variable       | Required | Description                 | Where to get it                                         |
| -------------- | -------- | --------------------------- | ------------------------------------------------------- |
| `DATABASE_URL` | ✓        | Postgres connection string  | Local: see docker-compose.yml; staging: secrets manager |
| `JWT_SECRET`   | ✓        | Signing key for auth tokens | Generate locally: `openssl rand -hex 32`                |
| `STRIPE_KEY`   | Dev only | Payment processing          | Stripe dashboard test keys                              |

### Architecture

- What this system is made of (services, databases, key dependencies)
- How they connect — a Mermaid diagram if the relationships aren't obvious from the description
- Which directory houses which concern
- What to read first to understand the core domain

Keep this to one screen. Depth belongs in ADRs and inline documentation.

### Domain Concepts

A glossary of terms that have specific meaning in this system — the ubiquitous language. Only include terms that aren't obvious from the name alone:

| Term            | Meaning in this system                                                                            |
| --------------- | ------------------------------------------------------------------------------------------------- |
| **Settlement**  | The process of moving funds from escrow to the merchant's account — distinct from payment capture |
| **Fulfillment** | The warehouse-side process after an order is placed — not the same as delivery                    |

### Development Workflow

- Branch naming convention
- MR process and required reviews
- Lint and format: `npm run lint`, `npm run format`
- How tests are organized and how to run a single file
- What CI checks must pass before merging

### Deployment

- Where this runs and how
- Environment tiers (local → staging → production) and what's different between them
- How a change gets from merged to live

### Troubleshooting

The most common things that go wrong for new developers:

**Problem:** `Cannot connect to database`
**Symptom:** `ECONNREFUSED 127.0.0.1:5432` on startup
**Fix:** Run `docker compose up -d postgres` — the DB container isn't running

**Problem:** Tests fail intermittently on CI but pass locally
**Symptom:** Timeout errors or missing fixture data
**Fix:** Tests depend on insertion order — see `tests/fixtures/README.md`

_(Add the real ones for this codebase.)_

---

## Standards

- **Accurate over comprehensive** — an inaccurate doc is worse than none
- **Trace the quickstart yourself** — every command must work in sequence
- **Written for the reader** — no patronizing explanations of industry-standard concepts; full explanations of project-specific ones
- **Maintained** — mark stale sections: `<!-- TODO: verify accurate as of YYYY-MM-DD -->`
