---
name: spec
description: Interview the user to surface edge cases and constraints, then write a complete SPEC.md
compatibility: opencode
---

Looking at this idea or request — interview the operator to surface everything they haven't fully considered, then produce a complete spec ready for implementation planning.

> [!IMPORTANT]
> **Model capability check:** this skill produces meaningfully better output on a deep-reasoning model — interview synthesis and edge-case surfacing benefit from broader context juggling. If you're on a smaller or faster tier, pause and ask before proceeding: _"This skill benefits from a deeper model because spec quality hinges on surfacing non-obvious edge cases. Proceed on the current tier, or stop so you can switch?"_

> [!NOTE]
> **This skill vs `/tasking`:** This skill produces the spec that `/tasking` decomposes. Use it when the idea is still fuzzy — when you have a concept but not yet a written design. If you already have a spec or design doc, skip straight to `/tasking`.

> [!NOTE]
> **When NOT to use:** Don't use when requirements are already clearly written and agreed upon — skip straight to `/tasking`. Don't use to surface requirements for a change the operator has already fully specified.

> [!TIP]
> **Effort:** M–XL. A focused single-feature spec is M; a greenfield system or one with many interacting subsystems is L–XL. The interview phase is open-ended — scope can grow as constraints surface. Budget accordingly.

---

## Protocol

1. Open with one focused question to confirm what's being built. Do not ask several at once.
2. Interview one question at a time. Dig into the hard parts; skip the obvious ones.
3. Keep interviewing until nothing significant is unresolved.
4. Write the spec to `SPEC.md` in the project root (or a path the operator specifies).
5. Close by noting the spec is ready for `/tasking` → `/tracker-init`.

Do not design or implement during the interview. The output of this skill is a written spec, not a plan or code.

---

## Interview Guide

Don't work through this as a checklist — use it to shape the conversation. Ask what's unclear, dig where answers are thin, and stop when you have enough.

### The problem

- What outcome does this enable — and what's the real pain today without it?
- Who specifically has this problem, how often, and what do they do instead?
- Is this the right solution, or is there a simpler one that achieves the same outcome?

### Users and access

- Who are the distinct user types? What can each type do?
- Are there admin, operator, or service-level actors beyond end users?
- What authentication and authorization model does this need?

### Core flows

- Walk through the primary user journey step by step.
- What triggers the flow? What are the outputs or observable results?
- What does "done" look like from the user's perspective?

### Edge cases and failure

- What happens when a key dependency is unavailable?
- What if the user provides invalid or unexpected input at each step?
- What's the worst-case data volume or load scenario, and how should it behave?

### Scope boundary

- What is explicitly out of scope for the first version?
- What's deferred to a later phase — and what would trigger building it?

### Technical constraints

- Any existing systems this must integrate with?
- Performance, reliability, security, or compliance requirements?
- Strong technology preferences or hard constraints?

### Success criteria

- How will we know this is working correctly?
- What's the observable, testable definition of done?

---

## Spec Format

Write `SPEC.md` using this structure:

```markdown
# Spec: [Title]

**Status:** Draft
**Date:** YYYY-MM-DD

## Summary

One paragraph. What this is, who it's for, and what problem it solves.

## Users

| User type | What they can do |
| --------- | ---------------- |
| ...       | ...              |

## Functional Requirements

Must-haves for the first version — specific and testable:

- [ ] ...

## Non-Functional Requirements

- **Performance:** ...
- **Reliability:** ...
- **Security:** ...
- **Compliance:** ...

## Out of Scope

Explicitly excluded from this version (prevents scope creep):

- ...

## Key Flows

### [Flow name]

1. Step
2. Step

Edge cases: [Scenario] → [Expected behavior]

## Technical Notes

Integration points, constraints, architectural decisions already made.

## Open Questions

Unresolved items — must be decided before implementation begins:

- [ ] [Question] — owner: ...

## Success Criteria

Observable, testable outcomes that confirm the feature is complete:

- [ ] ...
```

## Done When

- No significant open questions remain unresolved
- Scope is explicitly bounded — what's in AND what's out
- Every functional requirement is specific enough to write a test for
- Success criteria are observable without reading the implementation
- `SPEC.md` is written and ready to hand to `/tasking` → `/tracker-init`
