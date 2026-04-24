---
name: coding
description: Core engineering standards — SOLID, DRY, error handling, testing, security
compatibility: opencode
---

You are an expert software engineer. Apply these standards to all code you write or modify.

> [!TIP]
> **Using as `AGENTS.md`:** Drop relevant sections into your project's `AGENTS.md` as an always-on context file — but keep it lean. Remove sections that don't apply to your stack (e.g. TypeScript, Docker). Bloated instruction files cause agents to lose track of the rules that matter most. For each section you keep, ask: _"Would removing this cause the agent to make mistakes?"_ If not, cut it.

> [!NOTE]
> **This skill vs `/refactor`:** This skill is a foundation — always-on standards for writing new code or reviewing work against a quality bar. Use `/refactor` when actively restructuring existing code toward those standards.

> [!NOTE]
> **When NOT to use:** Don't paste entire sections into `AGENTS.md` without pruning irrelevant ones — bloated context degrades instruction-following. Remove sections that don't apply to your stack.

---

## Core Goals

Every technical decision should serve three objectives:

- **Reliability** — the system does what it's supposed to do, consistently, even under adverse conditions. Errors are handled. Failures degrade gracefully. Data integrity is preserved.
- **Scalability** — the system handles growth in load, data, and complexity without requiring redesign. Bottlenecks are avoided. Stateless where possible. No assumptions that break at scale.
- **Maintainability** — the system can be understood, safely modified, and confidently extended by future developers. Names reveal intent. Structure reflects domain. Tests provide a safety net.

When a decision has tradeoffs, name them explicitly. The principles below exist in service of these goals.

---

## Design Principles

- **Net-deficit by default** — The goal of every session is a net-negative or net-neutral line count. A feature is often a special case waiting to be deleted, not a branch waiting to be added. Before writing new code, ask whether the desired behavior can be achieved by removing something instead. For every line added, ask what existing line it displaces. A net-positive diff is not wrong — but it needs to justify itself. The Goldilocks codebase is the smallest one that fully does what it needs to: nothing more, nothing less.
- **SOLID** — enforce single responsibility, open/closed, Liskov substitution, interface segregation, dependency inversion.
- **DRY** — extract shared logic; no copy-paste patterns.
- **No magic values** — refactor magic numbers, strings, and config data into named constants or config objects.
- **Functional lean** — minimize side effects; prefer pure functions where practical.
- **Domain language** — name things using the domain's ubiquitous language, not implementation jargon.
- **Clarity > brevity** — multi-condition expressions span multiple lines, aligned per condition.

---

## Naming

Names reveal intent without a comment to explain them.

- Booleans: declarative (`isReady`, `hasAccess`) — never `flag` or `status`
- Functions: verb phrases (`calculateTax`, `fetchUser`)
- Classes: noun phrases (`OrderProcessor`)
- No unexplained abbreviations

---

## Comments & Docblocks

Every public method, function, and class gets a docblock:

- One-line summary
- `@param` — type + purpose
- `@returns` — type + what it represents
- `@throws` — when and why

Inline comments explain the _why_ behind non-obvious decisions — not the mechanics. Delete comments that restate what the code already says.

---

## Code Organization

- Logical sections with commented headings: `// Configuration`, `// Public API`, `// Private Helpers`
- Related behavior grouped; unrelated behavior split
- Files stay focused and manageable in size

---

## Pure Functions & Side Effects

Prefer pure functions: same inputs always produce the same output, with no observable side effects. They are trivially testable, safe to parallelize, and easy to reason about.

**A side effect is:** mutating external state, writing to DB/filesystem/network, modifying input arguments, reading mutable global state, or depending on time or randomness.

**Push side effects to the edges.** Keep business logic pure; perform I/O at the outermost layer and pass results inward as arguments.

```
// Instead of:
function processOrder(orderId) {
  const order = db.find(orderId)   // side effect inside logic
  order.status = 'processed'       // mutation
  db.save(order)                   // side effect
}

// Prefer:
function applyProcessed(order) { return { ...order, status: 'processed' } }  // pure
// caller handles db.find / db.save
```

**Return new values; don't mutate inputs.** Treat arguments as read-only. Return transformed copies.

**Command Query Separation:** a function either returns a value (query) or causes an effect (command) — not both. A function named `getUser` should not also write a log entry.

**When pure isn't practical** (DB layers, file processors, external integrations): isolate side effects into clearly named functions. Don't scatter them throughout business logic.

---

## Error Handling

**Where to catch:** At system boundaries (HTTP handlers, message consumers, scheduled jobs, CLI entry points) — not deep inside domain logic. Let errors propagate up with context added at each layer.

**Never:**

- Swallow errors silently (empty `catch` blocks)
- Log _and_ re-throw at the same layer — coordinate across layers instead
- Expose stack traces, internal paths, or schema details to end users
- Use a generic message where a specific one is possible

**Error messages must answer:**

- What operation was being performed (`"Failed to process payment"`)
- What the relevant identifiers were (`orderId`, `userId`, `filePath`)
- Why it failed, if determinable (`"Card declined: insufficient funds"`)
- What the operator or caller should do next

**Developer-facing (logs):** structured JSON with full context and correlation IDs:

```json
{
  "event": "payment.process.failed",
  "orderId": "ord_123",
  "userId": "usr_456",
  "reason": "gateway_timeout",
  "correlationId": "req_abc",
  "durationMs": 3012
}
```

**User-facing:** friendly, actionable, no internals. Map domain errors to appropriate HTTP status codes.

**Typed errors:** use custom error classes to distinguish categories (validation, not-found, authorization, external-service) so callers can handle each appropriately without string-matching messages.

---

## Testing

Apply the Goldilocks principle: enough tests to catch real bugs and document behavior, not so many that the suite becomes a maintenance burden. No vanity coverage.

- Descriptive: `describe("OrderService")` → `it("rejects orders with negative quantities")`
- Evergreen language — tests read as living documentation, not implementation notes
- Use `we`/`our` to reinforce shared ownership
- Cover happy paths, edge cases, and error paths — no more, no less
- Assert behavior, not implementation details — tests should survive a refactor
- If you can't describe what bug a test would catch, it shouldn't exist

---

## TypeScript

- Respect `@typescript-eslint/no-explicit-any`. If `any` is unavoidable, document it with a reason in the docblock.
- Precise interfaces over broad types.

---

## Docker

- Multi-stage builds: stable layers first (base images, deps), application code last.
- Never mount host `node_modules` into a container. Always build `node_modules` inside the container, for that container's architecture.

---

## Dependency Management

- Prefer established, actively maintained libraries over building from scratch — but evaluate each dependency's: maintenance health, download count, license, and attack surface.
- Pin exact versions in lockfiles; commit lockfiles to version control.
- Run `npm audit` / `pip-audit` / `govulncheck` in CI — catch CVEs before they reach production.
- Dev-only tools (linters, test runners) go in dev dependencies, not production ones.
- No dependency that does one trivial thing easily written inline (rule of thumb: if reading it takes longer than writing it, write it).

---

## Security

- Validate at system boundaries (user input, external APIs, file uploads). Trust internal code.
- No SQL injection, XSS, command injection, path traversal, or insecure defaults.
- Secrets never hardcoded — environment variables or a secrets manager only.
- Auth checked before any protected resource is accessed; authorization checked at the resource level, not just the route.
- See `/security-audit` for a full security checklist.
