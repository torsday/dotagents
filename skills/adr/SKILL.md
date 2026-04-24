---
name: adr
description: Write an Architecture Decision Record — context, options, decision, consequences, references
compatibility: opencode
---

Write an Architecture Decision Record (ADR) for the decision described here. Use the format and standards below.

> [!IMPORTANT]
> **Model capability check:** this skill produces meaningfully better output on a deep-reasoning model — tradeoff analysis and consequence enumeration reward depth. If you're running a smaller or faster model tier, pause and ask the operator before proceeding: _"This skill benefits from a deeper model because ADR quality hinges on tradeoff analysis depth. Proceed on the current tier, or stop so you can switch?"_

> [!NOTE]
> **Upstream:** If you're still exploring architectural options (rather than recording a decision already made), do that exploration first — this skill records a decision that has already been evaluated and chosen.

> [!NOTE]
> **When NOT to use:** Don't write an ADR for naming conventions, minor refactors, or decisions that follow an obvious, established pattern in the codebase. Don't use for ephemeral decisions — if the decision belongs in a commit message or inline comment, put it there.

## Format

```markdown
# ADR-NNNN: <title — short noun phrase describing the decision>

**Date:** YYYY-MM-DD
**Status:** Proposed | Accepted | Deprecated | Superseded by ADR-NNNN

---

## Context

What situation forced this decision? Include constraints, pressures, and relevant background.
What would happen if no decision were made?

## Decision

The choice made. State it clearly and directly — "We will..." not "We could..."

## Options Considered

| Option | Pros | Cons |
| ------ | ---- | ---- |
| ...    | ...  | ...  |

## Consequences

**Positive:** what gets better
**Negative:** what gets harder or more constrained
**Risks:** what could go wrong, and how it will be mitigated

## References

- Related ADRs, tickets, docs, or prior art
```

---

## When to Write an ADR

Write one when the decision is:

- **Hard to reverse** — changing it later would be expensive, risky, or require coordination
- **Genuinely contested** — reasonable people could disagree; the reasoning needs to be on record
- **Cross-cutting** — affects multiple teams, services, or systems
- **Technology-selecting** — choosing a database, framework, protocol, or external service
- **Likely to be questioned** — future developers will wonder "why did we do it this way?"

You do not need an ADR for naming conventions, minor refactors, or decisions that follow an obvious, established pattern in the codebase.

---

## Standards

- **One decision per ADR** — if two decisions are entangled, write two ADRs and cross-reference.
- **Capture the why, not just the what** — the code shows what was decided; the ADR explains why.
- **Be honest about tradeoffs** — an ADR that only lists pros is not trustworthy.
- **Write for future-you** — someone reading this in two years should understand the context without needing to ask anyone.

Store in `docs/adr/` with filename format `NNNN-short-title.md`.
