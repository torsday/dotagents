---
name: tasking
description: Decompose a design doc or specification into a sequenced task list with spikes and risk flags
compatibility: opencode
---

Looking at the design document or specification — decompose it into a structured, sequenced task list. Convert design intent into concrete work that can be picked up and completed independently.

> [!IMPORTANT]
> **Model capability check:** this skill produces meaningfully better output on a deep-reasoning model — decomposition judgment (what becomes a task vs a spike vs a note) rewards depth. If you're on a smaller or faster tier, pause and ask before proceeding: _"This skill benefits from a deeper model because task decomposition requires weighing scope, dependencies, and risk simultaneously. Proceed on the current tier, or stop so you can switch?"_

> [!NOTE]
> **This skill takes a spec as input.** If requirements are still fuzzy or unwritten, use `/spec` first to interview and surface edge cases. If you already have a spec or design doc, you're ready for tasking.

> [!NOTE]
> **This skill vs `/tracker-init`:** This skill produces a session-level task plan the agent uses to sequence implementation. To translate that plan into persistent GitLab Issues and a board, follow up with `/tracker-init`.

> [!NOTE]
> **When NOT to use:** Don't use without a spec or design doc — run `/spec` first if requirements are fuzzy. Don't use for single-task work that doesn't need sequencing.

> [!TIP]
> If the spec is incomplete or the scope is uncertain, interview the operator before decomposing. Ask about edge cases, technical unknowns, and tradeoffs the spec doesn't address. A five-minute clarification beats a misdirected task breakdown.

## Protocol

1. Read the design doc(s) or specification in full.
2. Identify unknowns that need a spike before implementation can begin.
3. Decompose known work into atomic tasks — each completable and verifiable independently.
4. Identify sequencing dependencies: what must come first?
5. Flag risks and open questions.
6. Produce the full task list — as a structured document, or via whatever progress-tracking mechanism your agent provides.

---

## Task Qualities

Each task must be:

- **Actionable** — starts with a verb (`Implement`, `Add`, `Migrate`, `Write`, `Configure`, `Remove`, `Delete`)
- **Scoped** — narrow enough to complete in one sitting (a few hours, not a few days)
- **Verifiable** — has a clear, specific definition of done
- **Sequenced** — dependencies identified so work flows without blocking
- **Tier-labeled** — every task gets exactly one capability tier (see below)

---

## Tier Assignment

Assign a capability tier during decomposition — it flows through to the GitLab issue when `/tracker-init` creates it, and `/ship-next` uses it to filter the ready queue to the current running tier.

For the full heuristic table, see **`/tracker-init` → Tracker Structure → Tier labels** — that's the canonical reference. Summary: `tier::deep` for reasoning-heavy work (design, ADRs, complex algorithms, spikes); `tier::standard` for well-specified execution (CRUD, mapping layers, mechanical tests, infra/CI scripts).

When in doubt, label `tier::deep` — over-promoting is cheap (slightly more compute); under-promoting produces lower-quality output on hard problems. Re-label freely as you learn what's actually hard.

A healthy task breakdown typically lands around **1:2 deep:standard**. If your decomposition is skewed far from that, recheck.

---

## Spikes

When a task can't be estimated or designed because of a genuine unknown, write a spike instead of a task:

```
Spike: Evaluate Stripe vs. Braintree for recurring billing (time-box: 4h)
  Goal: decision + written recommendation, not implementation
  Output: ADR-0012 with recommendation
```

A spike is time-boxed research that produces a decision or recommendation — not code. Never let an unknown block the whole plan; spike it and proceed around it.

---

## Decomposition Model

```
Epic: User Authentication
  Feature: Password Login
    Task: Implement PasswordHasher service using bcrypt  [tier::standard]
      Acceptance: Hash produced; verified round-trip; unit tested
    Task: Add POST /auth/login endpoint with rate limiting  [tier::standard]
      Acceptance: Returns JWT on success; 429 after 5 failed attempts; integration tested
    Task: Write unit tests for AuthService  [tier::standard]
      Acceptance: Happy path, wrong password, locked account all covered
  Feature: OAuth2 Login
    Spike: Evaluate OAuth library options (time-box: 2h)  [tier::deep]
    Task: ...
```

---

## Risk Flags

For each task or feature, note if it carries risk:

| Flag               | Meaning                                                             |
| ------------------ | ------------------------------------------------------------------- |
| 🔴 **High risk**   | Touches production data, payment flows, auth, or external contracts |
| 🟡 **Medium risk** | Complex logic, performance-sensitive, or spans multiple services    |
| 🟢 **Low risk**    | Self-contained, well-understood, easily reversible                  |

High-risk tasks get extra: a test-first requirement, a review step, or a phased rollout.

---

## After Creating Tasks

Produce a brief summary:

- **Phases** — implementation order, grouped by dependency
- **Critical path** — the sequence that determines how fast the whole thing can ship
- **Cross-cutting concerns** — error handling, logging, migrations, feature flags, documentation that touches multiple tasks
- **Risks and open questions** — what could derail the plan and who owns the answer
