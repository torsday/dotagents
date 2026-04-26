---
name: review-mr
description: Merge request review across correctness, reliability, design, tests, and security
compatibility: opencode
---

Looking at the diff, review these changes as a thorough, constructive code reviewer — identify problems before they merge, not after.

> [!NOTE]
> **This skill vs `/refactor-changes`:** This skill reviews and reports — it produces feedback only, no fixes. If you want to fix the diff rather than review it, use `/refactor-changes`. A common sequence is `/refactor-changes` first (clean up the code), then `/review-mr` (assess the logic and design) before merging. Once review passes, use `/commit` to construct the final atomic commits.

> [!NOTE]
> **When NOT to use:** Don't use as a substitute for owning quality in code you wrote — fix known issues before requesting review. Don't use to review uncommitted or unfinished changes; the diff should represent a complete, working increment.

> [!NOTE]
> **Claude Code users:** Claude Code's built-in `/review` command invokes the same intent. This skill (`/review-mr`) is the library's explicit version and works identically in both Claude Code and OpenCode.

## Protocol

> [!TIP]
> For the most objective review, run this in a fresh session or a clean subagent — the reviewer won't be biased toward code it just wrote. Isolating the review in its own context window produces cleaner, more independent findings.

1. Run `git diff main...HEAD` (or review the provided diff — for a GitLab MR, `glab mr diff <iid>`; for a GitHub PR, `gh pr diff <number>`).
2. Read any context files needed to understand the change fully.
3. Produce findings organized by severity.
4. Do not apply fixes — produce feedback only.

---

## Review Lens

### Correctness

- Logic errors or off-by-one mistakes
- Edge cases the code doesn't handle
- Race conditions or incorrect assumptions about state
- Errors silently swallowed or caught at the wrong layer
- Error messages that are generic, missing context, or expose internals to users
- Missing correlation IDs or structured logging where they're needed
- Third-party errors propagated raw without domain context

### Reliability

- External calls have timeouts — no unbounded waits
- Retries are safe: operations are idempotent or explicitly guarded against double-execution
- A failure here — does it cascade, or degrade gracefully?
- Data mutations that must be atomic: are they in a transaction?
- Are there assumptions about availability of external dependencies that aren't guaranteed?

### Design

- Does this fit the existing architecture, or does it cut against it?
- Are responsibilities correctly placed (no domain logic leaking into controllers, etc.)?
- Is this the right abstraction, or is it over/under-engineered?
- SOLID or DDD violations introduced
- Scalability: any new N+1 patterns, unbounded queries, or assumptions that break at scale?

### Reduction

This lens is easy to skip — reviewers naturally assess what was added, not what could be removed. Force it explicitly.

- Is there code in this diff that could be deleted without changing behavior?
- Does this MR solve the problem with the minimum necessary code, or does it add more than the problem requires?
- Are there abstractions introduced here that solve a problem that doesn't exist yet?
- Are there new fallbacks, guards, or error handlers for scenarios that can't actually happen?
- Could any of the new logic replace existing code rather than sit alongside it?
- After this merges, will the codebase be smaller and simpler, or just different?

### Test Coverage

- Are the happy path, edge cases, and error paths tested?
- Do tests assert behavior or implementation details? (Implementation detail tests break on refactors, not bugs.)
- Would a real bug in this code cause a test to fail?
- Is coverage meaningful or vanity? A test that exists only to hit a line adds noise without confidence.
- Is there too much test ceremony for what's being tested? Over-engineered test setup is a maintainability smell.

### Security

- Untrusted input handled without validation
- Auth/authz assumptions
- Secrets, credentials, or PII in code or logs
- Injection vectors

### API & Contracts

- Does this change break any public interface — REST endpoint, event schema, function signature, exported type?
- If breaking: is it versioned, or must consumers update simultaneously?
- New response fields added as optional (safe) vs. required (breaking for existing clients)?
- Event or message schema changes: are consumers of this schema in scope and updated?

### Maintainability

- Names that obscure intent
- Missing or misleading docblocks
- Logic that will confuse the next person
- Coupling introduced between modules that should be independent
- Complexity added without clear justification — will this be understandable in six months?
- Is the change consistent with the surrounding codebase, or does it introduce a conflicting pattern?

### Documentation

- README updated if setup, usage, or architecture changed?
- New config options, environment variables, or endpoints documented?
- Does a significant decision here warrant an ADR?
- Are docblocks updated to reflect behavior changes?

---

## Output Format

Group findings by severity:

**Must fix** — correctness bugs, security issues, data loss risk
**Should fix** — design problems, missing tests, meaningful maintainability issues
**Consider** — style, naming, minor improvements worth noting but not blocking

For each finding: location → issue → why it matters → suggested approach (not full solution).
