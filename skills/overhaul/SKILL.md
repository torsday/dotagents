---
name: overhaul
description: Aggressive restructure — design the target from today's knowledge, then migrate; legacy structure is reference, not constraint
compatibility: opencode
---

Looking at what this system is supposed to do — not how it currently does it — design and execute a complete restructure to reach coding excellence. Existing structure, naming, and patterns are reference material, not constraints.

> [!NOTE]
> **This skill vs `/refactor` and `/refactor-changes`:** This skill is for complete restructures — design-first, no legacy deference, rebuild it correctly from today's knowledge. For incremental improvement of specific code, use `/refactor`. For a scoped pass over the current git diff, use `/refactor-changes`.

> [!NOTE]
> **When NOT to use:** Don't use without a trusted test suite — aggressive restructuring without tests is guessing. Don't use for incremental quality work; prefer `/refactor` or `/ship-refactor`. Don't use when consumers depend on the current public interface and can't be coordinated with.

> [!IMPORTANT]
> **Model capability check:** a full restructure requires holding the current implementation, the target architecture, the gap analysis, and the migration plan in mind simultaneously. A deeper-tier model produces meaningfully better output. If you're on a smaller tier, pause and ask before proceeding.

**This is not an incremental refactor.** Legacy deference is explicitly off. The question is not "how do I improve this?" — it is "how would I build this correctly if starting today?" The target architecture should be leaner than what it replaces: fewer files, fewer abstractions, less code. Every component must earn its place against the requirements as they actually exist, not as they were once imagined.

---

## Prerequisites

**Do not proceed without a trusted test suite.** Aggressive restructuring without tests is guessing. The suite is the only way to verify the rebuilt system is behaviourally equivalent to the old one. If meaningful test coverage doesn't exist, write it first against the current implementation before touching structure.

---

## Protocol

### 1. Understand the Domain — Before Reading the Implementation

Read documentation, specs, and interfaces. Understand:

- What this system does (its purpose and responsibilities)
- Who depends on it and how (consumers, integrations, contracts)
- What the core domain concepts are (entities, operations, rules)

Resist reading the implementation in detail at this stage. Existing code anchors thinking to existing mistakes.

### 2. Design the Target Architecture

Produce the ideal structure independently of what exists. Define:

- **Module and layer boundaries** — what are the distinct concerns, and where do they live?
- **Domain model** — entities, value objects, aggregates, services in the ubiquitous language of the domain
- **Interfaces and contracts** — what does each module expose? What does it depend on?
- **File and directory structure** — where does each thing live in the target layout?
- **Data flow** — how does a request or event move through the system?

Apply: DDD for domain structure, Hexagonal Architecture to isolate domain from infrastructure, SOLID throughout, pure functions for business logic, side effects at the edges.

Produce a written target design — even a brief one — before writing any code.

### 3. Gap Analysis — Current → Target

> [!TIP]
> Reading the full implementation is expensive — it fills context fast. Delegate specific subsystems to a subagent: _"Use a subagent to read src/payments and map it against this target design."_ The subagent reports back findings without consuming your main context window.

Now read the existing implementation in full. Map it against the target design:

| Current                           | Target                                       | Action           |
| --------------------------------- | -------------------------------------------- | ---------------- |
| `UserController.processPayment()` | `PaymentService.process()` in domain layer   | Move + rename    |
| `utils/helpers.js`                | Split across `domain/` and `infrastructure/` | Decompose        |
| Inline DB calls throughout        | `OrderRepository` interface + implementation | Extract + invert |
| ...                               | ...                                          | ...              |

Categorise each item: **Move**, **Rename**, **Rewrite**, **Extract**, **Delete**, **Keep**.

### 4. Migration Plan — Sequence the Work

Aggressive restructuring done all at once produces a half-migrated mess. Sequence the changes so the system is always in a runnable, testable state.

Order work by:

1. **Foundational first** — establish new module structure and interfaces before moving code into them
2. **Leaf nodes before roots** — move utilities and helpers before the services that depend on them
3. **One layer at a time** — complete domain restructure before touching infrastructure
4. **Delete last** — remove old code only after the replacement is live and tests pass

Produce an ordered list of phases, then execute — do not pause for confirmation between phases unless a genuine decision point requires input.

### 5. Execute Phase by Phase

Work one phase at a time. After each phase:

- Tests pass
- System is runnable
- No half-migrated seams left exposed

Do not start the next phase until the current one is clean.

---

## Target Architecture Standards

### Structure

- **Domain layer** — entities, value objects, aggregates, domain services; zero infrastructure dependencies
- **Application layer** — use cases / command handlers; orchestrates domain; no business logic
- **Infrastructure layer** — DB, HTTP, queues, external APIs; implements domain interfaces
- **Interface layer** — controllers, CLI handlers, event consumers; thin; delegates immediately

### Code

- All standards from `/coding` apply without exception — including the Core Goals: Reliability, Scalability, Maintainability
- Pure functions for all business logic; side effects isolated to infrastructure
- No magic values; no implicit dependencies; no global mutable state
- Every public interface documented with intent, not mechanics
- External calls have timeouts; failures degrade gracefully; stateless where possible

### Tests

- Unit tests on domain logic (fast, no I/O)
- Integration tests on infrastructure implementations
- End-to-end or contract tests on the interface layer
- Goldilocks coverage: meaningful, not exhaustive

---

## What "No Legacy Deference" Means

- Rename anything that doesn't reflect the domain's ubiquitous language
- Split files that bundle unrelated concerns, even if they've always been together
- Collapse layers that exist for historical reasons but serve no architectural purpose
- Delete abstractions that were built for flexibility that never came
- Change public interfaces if they're wrong — coordinate with consumers, but don't preserve bad contracts out of inertia

The only reason to keep something is that it's right. Not that it exists.
