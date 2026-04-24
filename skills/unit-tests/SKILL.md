---
name: unit-tests
description: Write unit tests to the Goldilocks standard — meaningful coverage, no vanity tests
compatibility: opencode
---

Looking at the code, build or improve unit tests to the Goldilocks standard: thorough enough to catch real bugs and document behavior, lean enough to stay maintainable.

> [!NOTE]
> **When NOT to use:** Don't use for testing I/O, database operations, or multi-component flows — use `/integration-tests` instead. Don't add tests to hit a coverage percentage; coverage without confidence is vanity.

> [!TIP]
> **Effort:** S. A standard-tier model is sufficient for well-specified implementations; reserve a deeper tier for tests that require deep reasoning about edge cases in complex domain logic.

## Protocol

1. Read the implementation files.
2. Identify gaps in existing test coverage.
3. Write or improve tests — proceed without pausing for confirmation.
4. Confirm tests pass.
5. **Stopping condition** — when running in a loop, stop scheduling further invocations when the Goldilocks standard is met: happy path, edge cases, error paths, and security boundaries are covered for all meaningful units; no new gaps found this pass; no tests exist only to hit coverage numbers.

   Emit this exact phrase so a loop runner recognizes it:

   > **Loop exit:** Goldilocks coverage reached — no meaningful gaps remain. Stopping.

---

## What Good Tests Do

- **Document behavior** — the test suite reads like a spec for what the code does
- **Catch regressions** — fail loudly when behavior changes unexpectedly
- **Enable refactoring** — tests coupled to implementation details break on refactors, not bugs

---

## Structure

Use the **Given / When / Then** mental model:

```
describe("<unit under test>") {
  describe("<method or scenario>") {
    it("<what should happen given what context>")
    // Given: set up preconditions
    // When: invoke the unit
    // Then: assert the outcome
  }
}
```

---

## Coverage Targets (in priority order)

**Test these:**

1. Happy path — the primary success case
2. Edge cases — boundary values, empty inputs, maximum inputs
3. Error paths — invalid input, missing dependencies, failure states
4. Security boundaries — if the unit handles untrusted input

**Do not test:**

- Implementation details (private methods, internal data structures)
- The framework itself (third-party library behavior)
- Trivial getters/setters with no logic

**No vanity coverage.** A test that exists only to hit a line is worse than no test — it adds maintenance burden without catching bugs. 100% coverage is not the goal; meaningful coverage is. If you can't describe what bug a test would catch, it shouldn't exist.

---

## Test Doubles

Use the simplest double that makes the test work. Over-mocking produces tests that verify the mock, not the code.

| Type     | What it does                                  | When to use                                               |
| -------- | --------------------------------------------- | --------------------------------------------------------- |
| **Stub** | Returns a fixed value                         | Isolate from a dependency's return value                  |
| **Mock** | Verifies a call was made                      | Assert a side effect occurred (email sent, event emitted) |
| **Spy**  | Wraps real behavior, records calls            | Verify a call while keeping real logic intact             |
| **Fake** | Simplified real implementation (in-memory DB) | Integration-level isolation without real infrastructure   |

---

## Standards

- **Descriptive names**: `it("rejects orders with negative quantities")` not `it("test 3")` — the test name is documentation
- **Evergreen language**: tests remain accurate as code evolves — avoid "currently" or "for now"
- **Collective ownership**: use `we`/`our` in comments — tests belong to the team
- **One assertion per concept**: a failing test should identify one specific broken behavior, not several at once
- **Isolated**: each test sets up its own state; no test depends on another's side effects
- **Fast**: unit tests mock I/O (DB, network, filesystem) — integration tests hit real systems
