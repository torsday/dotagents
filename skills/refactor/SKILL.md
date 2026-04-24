---
name: refactor
description: Refactor for engineering excellence — naming, structure, SOLID, pure functions
compatibility: opencode
---

Looking at the code, refactor for engineering excellence — structural improvement and cleanup together. Prefer less code over more when quality holds.

**The primary directive: subtract.** Refactoring is not about adding patterns, introducing abstractions, or improving naming — though all of those may happen. The goal is a net-negative line count: reach the state where nothing can be removed without breaking something. Start every session by looking for what to delete. An unchanged line count after a refactor is a warning sign; a positive one is a red flag.

> [!NOTE]
> **This skill vs `/ship-refactor` and `/refactor-changes`:** This skill works on whatever code you point it at — local only, no commits, no tracker ceremony. For autonomous GitLab-tracked looping (issue → branch → MR → merge), use `/ship-refactor`. To scope automatically to the current git diff (pre-commit quality gate), use `/refactor-changes`.

> [!NOTE]
> **When NOT to use:** Don't use on code in an open MR under active review — finish the review first. Don't mix refactoring with adding features — separate the concerns into distinct commits.

> [!TIP]
> **Effort:** Single file or small diff → XS–S on a standard-tier model. Architectural scope touching core domain logic or many interdependencies → M–L on a deeper tier. If the target turns out larger than expected, reassess scope before continuing rather than expanding mid-session.

## Protocol

1. Read the relevant files.
2. State findings and intended fixes — then implement immediately in the same response. Do not pause for confirmation.
3. Note the _why_ behind any non-obvious decisions — the diff shows the what.
4. **Stopping condition** — when running in a loop, stop scheduling further invocations when the full checklist passes with zero findings: nothing to delete, no duplication, no dead code, no bloated conditionals, naming is clear, no reliability gaps. A net-zero-diff session is the signal. A clean codebase is the goal — reaching it means the loop succeeded, not that it stalled.

   Emit this exact phrase so a loop runner recognizes it:

   > **Loop exit:** Checklist passed clean — nothing left to subtract or improve. Stopping.

---

## Checklist

### Cleanup — delete first, then improve

Bias toward deletion. Every line kept must earn its place.

- **Dead code** — unreachable branches, unused variables, commented-out code, obsolete feature flags
- **Duplication** — extract repeated logic; three instances is the threshold
- **Unnecessary abstraction** — delete layers, wrappers, or interfaces built for hypothetical futures
- **Bloated conditionals** — flatten nested `if/else` with early returns, guard clauses, or lookup tables
- **Over-engineering** — if a simpler approach produces the same result, use it

### Domain-Driven Design

- Names reflect the domain's ubiquitous language, not implementation jargon
- Domain logic lives in the domain layer — not in controllers, handlers, or infrastructure
- Entities, value objects, aggregates, and services are clearly delineated
- Related behavior grouped; unrelated behavior split

### Standards (via `/coding`)

Apply all `/coding` standards throughout. Key items in the refactoring context:

- **SOLID** — each function/class has one reason to change; depend on abstractions not concretions; subtypes substitutable for base types
- **Pure functions** — extract logic from I/O; return new values instead of mutating inputs; Command Query Separation
- **Naming** — declarative booleans (`isValid`, `hasPermission`); verb functions; noun classes; no unexplained abbreviations
- **Comments** — docblock on every public method (`@param`, `@returns`, `@throws`); explain why, not what; delete comments that restate the code
- **Error handling** — catch at boundaries only; no silent swallowing; no log-and-rethrow at the same layer; typed errors; structured logs with correlation IDs
- **Test coverage** — fill meaningful gaps (happy path, edge cases, error paths); no vanity tests; assert behavior not implementation details

### Reliability & Scalability

- External calls (HTTP, DB, queues) have timeouts — no unbounded waits
- Retries use exponential backoff with jitter; operations are idempotent before retrying
- A failure in one component doesn't cascade — dependencies fail gracefully
- Stateless where possible; any stateful components are explicit and intentional
- Data operations that must be atomic use transactions; partial writes are not possible
- No N+1 patterns; no sequential operations that could be parallel
- No assumptions baked in that break under increased load or data volume

### Bug Detection

- Null/undefined dereferences
- Off-by-one errors
- Unhandled promise rejections or missing error boundaries
- Race conditions or shared mutable state
- Security: injection vectors, auth bypass, insecure defaults, hardcoded secrets
