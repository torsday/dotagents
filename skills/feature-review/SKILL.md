---
name: feature-review
description: Evidence-based product audit — which features are missing, which should be removed, and which earn their complexity
compatibility: opencode
---

Looking at the codebase, domain context, and any design docs — assess whether the application is missing features worth adding, and whether any existing features are good candidates for removal. No recommendation is a valid and common outcome.

> [!NOTE]
> **This skill vs `/next`:** `/next` scans the full project, picks the single highest-value action across all categories (bugs, tests, debt, docs, features), and executes it immediately. This skill is a focused, deliberate product-level audit across two dimensions — additions and removals — that produces a recommendation, not an implementation. Use it when you want to step back and evaluate the feature set as a whole rather than act on the next urgent thing.

> [!NOTE]
> **When NOT to use:** Don't use to manufacture feature recommendations from a checklist — if the scan finds nothing warranted, say so. Don't use as a substitute for user or stakeholder research; this is evidence-from-code only.

> [!TIP]
> If the scope or purpose of the system is ambiguous, pause and ask before scanning — what the system is designed to do, who its users are, and what "in scope" means for this project. A scoped audit produces sharper recommendations than a broad one that surfaces features the team never intended to build.

Recommendations must be grounded in evidence from the code — partial implementations, design gaps, disabled functionality, or clear domain needs the system doesn't address. Speculation without evidence is not a recommendation.

---

## Discovery

Read in this order. Stop when you have a confident picture of what the system does and what it doesn't.

1. **README and docs** — stated purpose, intended users, scope of the system
2. **Design docs and specs** — `DESIGN.md`, `SPEC.md`, `docs/`, ADRs — what was planned vs. what shipped
3. **`git log --oneline -20`** — recent direction; what's been added, removed, or quietly abandoned
4. **In-code signals** — `grep -r "TODO\|FIXME\|HACK\|WIP\|planned\|future"` — deferred intentions and partial work
5. **Feature flags and dead branches** — code toggled off, disabled, or unreachable in production
6. **Underused paths** — functionality with no tests, no callers, no documentation
7. **Core domain files** — primary user-facing flows and key business logic

> [!TIP]
> Delegate deep subsystem exploration to a subagent — _"Use a subagent to read src/payments and identify feature gaps."_ Keeps your main context clean for synthesis.

---

## What Warrants a Recommendation

### Adding a feature

Evidence that something is missing:

| Signal                              | Example                                                                          |
| ----------------------------------- | -------------------------------------------------------------------------------- |
| Partial implementation exists       | Stubbed code, TODOs pointing to next steps                                       |
| Spec or ADR describes it as planned | Design doc marks it "phase 2" or "coming soon"                                   |
| Obvious domain gap                  | System handles orders but not refunds; users but not roles                       |
| Domain precedent is universal       | Every system in this domain has X; this one doesn't and there's no stated reason |
| Clear operator need with no path    | Auth exists but no password reset; API exists but no rate limiting               |

**Do not recommend adding a feature because:**

- It would be nice to have
- Similar apps include it — without evidence it's needed here
- It's technically interesting
- It appears on a generic best-practices checklist

### Removing a feature

Evidence that something isn't earning its complexity:

| Signal                             | Example                                                    |
| ---------------------------------- | ---------------------------------------------------------- |
| Feature flag permanently disabled  | `enabled: false` with no recent activity                   |
| No callers, no tests               | Code exists; nothing uses it; nothing verifies it          |
| Overlaps with a canonical path     | Two ways to do the same thing; one is clearly the standard |
| Was temporary, became permanent    | `tmpFeature`, `legacyHandler`, scaffolding that shipped    |
| High maintenance cost, unclear use | Frequently changed, complex code with no visible consumer  |

---

## Output

### Features to Add

If there are no warranted additions: **No additions recommended.** Don't pad this section.

For each recommendation:

**[Feature name]**

- **Evidence:** what in the code or docs points to this gap
- **Value:** what it enables for users or operators
- **Complexity:** Small / Medium / Large — and what it would touch
- **Priority:** High / Medium / Low

---

### Features to Remove

If there are no candidates: **No removals recommended.**

For each recommendation:

**[Feature / location]**

- **Evidence:** why this is a removal candidate
- **Risk:** what could break or be lost
- **Approach:** delete outright / extract salvageable parts then delete / deprecate first / disable and monitor

---

### Summary

One short paragraph: the overall health of the feature set. Is it lean and well-matched to its domain? Carrying partial work that's dragging on complexity? Missing something the domain clearly calls for? If the answer is "the feature set looks right" — say that.

---

## Stopping condition

When running in a loop, stop scheduling further invocations when the audit produces no additions and no removals — the feature set matches the domain cleanly and every feature earns its place.

Emit this exact phrase so a loop runner recognizes it:

> **Loop exit:** Feature set clean — no additions or removals warranted. Stopping.
