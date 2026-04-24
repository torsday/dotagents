---
name: integration-tests
description: Build integration tests — contract verification, boundary coverage, contract testing
compatibility: opencode
---

Looking at the code and existing tests, build or improve integration tests to the Goldilocks standard: enough to verify that components wire together correctly and contracts hold, not so many that the suite becomes slow, fragile, or redundant with unit tests.

> [!NOTE]
> **When NOT to use:** Don't use when the logic is already thoroughly covered by unit tests — integration tests verify wiring, not business rules. Don't use to test implementation details; test the observable contract.

> [!TIP]
> **Effort:** S–M depending on the number of boundaries to cover. A standard-tier model is sufficient — integration test patterns follow established templates.

## Protocol

1. Read the implementation and any existing tests.
2. Identify coverage gaps at integration boundaries: HTTP endpoints, database queries, external services, message queues.
3. Write or improve tests targeting those boundaries — proceed without pausing for confirmation.
4. Confirm tests pass against a real (or realistic) environment.
5. **Stopping condition** — when running in a loop, stop scheduling further invocations when all integration boundaries are covered: HTTP contracts, DB interactions, auth flows, external service boundaries, and critical end-to-end flows all have tests; no new gaps found this pass.

   Emit this exact phrase so a loop runner recognizes it:

   > **Loop exit:** Integration boundaries fully covered — no gaps found this pass. Stopping.

---

## Integration vs. Unit

| Concern | Unit test             | Integration test                     |
| ------- | --------------------- | ------------------------------------ |
| Scope   | Single function/class | Multiple components working together |
| I/O     | Mocked                | Real (or realistic test double)      |
| Speed   | Fast (ms)             | Slower (acceptable)                  |
| Purpose | Logic correctness     | Contract and wiring correctness      |

---

## What to Test

- **API contracts** — correct status codes, response shapes, error responses
- **Database interactions** — queries return correct data, writes persist, constraints are enforced
- **Authentication & authorization** — protected routes reject unauthorized requests
- **External service boundaries** — correct request format sent, error responses handled
- **End-to-end flows** — a user action produces the correct observable outcome

---

## Do Not Test

- Logic already thoroughly covered by unit tests — integration tests verify wiring, not business rules
- The framework or third-party library internals
- Every permutation of a flow — pick the representative paths; trust unit tests for the variations

**No vanity coverage.** An integration test that duplicates unit test coverage adds slowness without adding confidence.

---

## Contract Testing

When this service is consumed by other services, consumer-driven contract tests verify that both sides agree on the interface — without requiring the full stack to be running.

- **Consumer** writes tests expressing what it expects from the provider
- **Provider** verifies it satisfies those expectations in CI
- Tools: [Pact](https://pact.io), [Spring Cloud Contract]

Use contract tests when: services are independently deployed, teams own opposite sides of an interface, or integration test environments are slow or unreliable.

---

## Standards

- **Isolated test data** — each test creates and cleans up its own data; no shared state between tests
- **Idempotent** — tests can run in any order and produce the same result
- **Realistic but minimal** — use real infrastructure (test DB, local queue) not production; seed only what the test needs
- **Descriptive names** — `it("returns 403 when user lacks admin role")` not `it("auth test")`
- **Test the contract, not the implementation** — assert on observable outputs, not internal state
