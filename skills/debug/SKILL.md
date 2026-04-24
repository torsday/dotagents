---
name: debug
description: Discover or investigate bugs — reproduce, document with excellent tickets, prove with failing tests, optionally fix
compatibility: opencode
---

Looking at the error, unexpected behavior, or codebase — work through this systematically. The primary deliverable is an excellent bug ticket and a failing test MR that proves the bug. Fixing is an optional final step.

> [!IMPORTANT]
> **Model capability check:** for simple bugs (clear stack trace, one suspect file), a standard tier handles this fine. For **hard bugs** (intermittent, concurrency, cross-system, no obvious root cause), pause and ask: _"This bug looks <simple | hard — briefly explain>. Hard bugs benefit from a deeper tier for hypothesis ranking. Proceed on the current tier, switch, or cancel?"_ Skip the check if the bug is obviously simple or you're already on a deep tier.

> [!NOTE]
> **This skill vs `/ship-debug`:** This skill is local and investigative — it stops at a documented ticket + failing test, with an optional fix. For autonomous GitLab-tracked looping (discover → prove → fix → MR → merge), use `/ship-debug`.

> [!NOTE]
> **When NOT to use:** Don't use when the root cause is already known — go straight to fixing it. Don't use for performance investigations where profiling tools are the right first step. Don't use for code review or refactoring.

---

## Mode

Identify which mode applies before proceeding:

| Mode | When | Starting point |
| ---- | ---- | -------------- |
| **Investigation** | A specific bug or error has been reported | Skip to Phase 2 — reproduce the specific issue |
| **Discovery** | No specific bug; scan the repo for undiscovered bugs | Start at Phase 1 — check issues, then explore |

---

## Phase 1 — Check existing issues

Before investing in investigation, check whether this bug is already known. Avoid duplicate tickets.

```bash
# Check open bugs
glab issue list --label "bug" --per-page 100

# Search closed bugs for similar symptoms
glab issue list --state closed --label "bug" --search "<symptom keywords>" --per-page 20
```

**If a matching issue exists:**
- Update it with any new findings — don't create a duplicate
- Check whether it's already being worked on (`workflow::in-progress` scoped label)
- If it's assigned and active, stop — don't duplicate the work

**Discovery mode — scan for undiscovered bugs:**
- `git log --oneline -20` — recent high-churn areas are instability signals
- `grep -r "TODO\|FIXME\|HACK\|XXX" --include="*.{ts,js,go,py,rb}" .` — in-code debt markers that often flag known issues
- `glab ci list --per-page 10` — recent CI failures; flaky jobs often signal real bugs
- Code paths that handle errors, edge inputs, concurrent access, or external failures
- Focus on Tier 1: unhandled errors, auth paths, data mutations without transactions, missing timeouts

---

## Phase 2 — Reproduce

Confirm the bug is real and reliably reproducible before investing in root cause analysis.

- Identify the exact inputs and conditions that trigger the failure
- Determine if the failure is deterministic or intermittent
- Confirm it fails in a clean environment (not just a local misconfiguration)
- Document the minimal reproduction case — the simplest inputs that still trigger the bug

**Do not form a root cause hypothesis before reproducing.** Read first, theorize second.

---

## Phase 3 — Root cause analysis

Work through these steps in order. Do not skip ahead.

1. **Read** — read the relevant code paths before forming hypotheses
2. **Isolate** — narrow to the smallest scope where the failure occurs
3. **Hypothesize** — form one specific, falsifiable hypothesis
4. **Verify** — test the hypothesis; eliminate before moving to the next

**Check the boring things first:** wrong environment, stale build, misconfigured dependency, off-by-one, null input, wrong branch.

**Explain the mechanism** — the analysis isn't done until you can state exactly why the bug occurs, not just where.

### Bug archaeology

Find when the bug was introduced and what change brought it in. Do not surface who introduced it — the goal is context, not blame.

```bash
# Find commits that touched the relevant code
git log --format="%h %ci %s" -- <file>

# Find the commit that introduced a specific string or pattern
git log --format="%h %ci %s" -S "<symptom string or function name>"

# Find the commit that changed a specific line (bisect if needed)
git bisect start
git bisect bad HEAD
git bisect good <last-known-good-tag>
# git bisect run <test command>
```

Extract from the results:
- **When** the change landed (commit date)
- **What** changed (commit message — often references a ticket or MR)
- **Which MR/issue** it came from (if the commit message has `Closes #N` or `Refs #N`, or `See merge request !N`)

This context belongs in the bug ticket under "Introduced in."

---

## Phase 4 — Bug ticket

Create an excellent GitLab issue. Check Phase 1 first — update an existing issue if one already covers this bug.

### Labels

Apply the minimum label set:

| Category | Options |
| -------- | ------- |
| Type | `bug` (always) |
| Priority | `priority::p0-critical`, `priority::p1-high`, `priority::p2-medium`, `priority::p3-low` |
| Size | `size::xs`, `size::s`, `size::m`, `size::l`, `size::xl` (estimated fix scope) |
| Workflow | `workflow::backlog` by default; `workflow::needs-design` if approach is unclear; `workflow::on-hold` if dependencies exist |
| Tier | `tier::deep` (complex fix, architecture involved) or `tier::standard` (clear, mechanical fix) |

**Priority heuristic:**

| Priority | Condition |
| -------- | --------- |
| `priority::p0-critical` | Data loss, security vulnerability, complete feature failure for all users |
| `priority::p1-high` | Significant degradation, most users affected, no workaround |
| `priority::p2-medium` | Notable defect, workaround exists, subset of users affected |
| `priority::p3-low` | Cosmetic or edge-case, minimal user impact |

### Issue body

```markdown
## What's happening

[One paragraph: the observable symptom, who's affected, and under what conditions. Be specific — "the checkout fails" is not enough; "POST /checkout returns 500 when cart contains a product with null inventory_count" is.]

## Steps to reproduce

1. ...
2. ...
3. Observe: ...

## Expected behavior

[What should happen.]

## Actual behavior

[What does happen. Include the full error message, stack trace, or screenshot.]

## Root cause

[Best diagnosis. Reference the specific file and line if traced. If uncertain, say so and explain reasoning.]

## Blast radius

[Which other features, flows, or users are affected. Be concrete — name the endpoints, components, or user segments.]

## Fix options

| Option | Description | Effort | Risk | Notes |
| ------ | ----------- | ------ | ---- | ----- |
| **Minimal patch** | [Side-step the issue with the smallest possible change] | XS | Low | Only if release urgency outweighs tech debt |
| **Targeted fix** | [Fix the actual root cause cleanly] | S–M | Low | Recommended default |
| **Structural improvement** | [Fix + refactor the surrounding code] | M | Medium | Worthwhile if this area is high-churn |
| **Redesign** | [Address the underlying architectural issue] | L–XL | High | Consider if this bug pattern recurs |

## Introduced in

- Commit: `<hash>` — `<date>` — `<commit message>`
- Related MR/issue: !N / #N (if traceable from commit message)

## Environment

- Branch / version: ...
- OS / runtime / relevant config: ...

## Linked

- Failing test MR: !N (link after creation)

## Acceptance criteria

- [ ] The failing test in !N passes
- [ ] No regression in adjacent behavior
```

```bash
ISSUE=$(glab issue create \
  --title "<verb-first imperative: what the bug does>" \
  --label "bug,priority::p1-high,size::m,tier::standard,workflow::backlog" \
  --description-file /tmp/bug-body.md \
  -F json | jq -r '.iid')
```

**Title standard:** imperative, specific, no `[bug]` prefix (that's the label). `"Return 500 when cart contains null inventory_count"` beats `"Checkout is broken"`.

---

## Phase 5 — Failing test MR

Write a test that proves the bug exists. This MR should fail CI — that's the point. It becomes the acceptance criterion for the fix.

### What to write

- A test that asserts the **correct** behavior that currently fails
- Named for the behavior, not the bug: `it("returns 400 when inventory_count is null")` not `it("bug #42 test")`
- Placed in the correct test file alongside related tests
- Minimal setup — reproduce the bug with the least scaffolding possible

### Branch and MR

```bash
# Create a worktree-isolated branch
ISSUE=<issue-iid>
SLUG=<kebab-description>
BRANCH="bug-test/${ISSUE}-${SLUG}"
git worktree add "../worktrees/$BRANCH" -b "$BRANCH"
cd "../worktrees/$BRANCH"

# Write the failing test, then commit
git add <test-file>
git commit -m "test(<scope>): prove bug #${ISSUE} — <what the test asserts>"
git push -u origin "$BRANCH"

glab mr create \
  --source-branch "$BRANCH" \
  --title "test: failing test for #${ISSUE} — <short description>" \
  --description "$(cat <<EOF
## Failing test for #${ISSUE}

Adds a test that reproduces the bug documented in #${ISSUE}.

> [!IMPORTANT]
> **CI failure is expected and intentional.** This test asserts the correct behavior that the bug currently prevents. It will turn green when the fix lands.

## What the test proves

[One sentence: the correct behavior this test verifies.]

## When to merge

After the fix MR that makes this test pass. Do not merge while the test is red.

Refs #${ISSUE}
EOF
)"
```

After the MR is open:

1. Edit the issue to fill in `Failing test MR: !<MR-iid>` in the Linked section.
2. Flip workflow → `in-review` to signal that an MR exists. Use the shared status-transition helper (see `shared/status-transition.md`).

> **Note on GitLab keyword behavior:** `Refs #N` creates a cross-reference mention on the issue but does **not** auto-close on merge. The fix MR in Phase 6 uses `Closes #N`, which is the MR that will close the issue. This is intentional — the failing-test MR must not close the issue.

---

## Phase 6 — Fix (optional)

If the fix is clear, low-risk, and within scope for this session, apply it now. The fix branch should be based on the bug-test branch so the now-passing test is included in the same merge.

```bash
# Base the fix branch on the bug-test branch so the test comes with it
FIX_BRANCH="fix/${ISSUE}-${SLUG}"
git worktree add "../worktrees/$FIX_BRANCH" -b "$FIX_BRANCH" "origin/$BRANCH"
cd "../worktrees/$FIX_BRANCH"

# Implement the fix, confirm the failing test now passes, then commit
git add <changed-files>
git commit -m "fix(<scope>): <what was fixed>"
git push -u origin "$FIX_BRANCH"

glab mr create \
  --source-branch "$FIX_BRANCH" \
  --title "fix(<scope>): <imperative summary>" \
  --description "$(cat <<EOF
## Summary

[What the fix does and why it works.]

## Test

The failing test from !<test-MR-iid> now passes. No regressions in adjacent behavior.

Closes #${ISSUE}
EOF
)"
```

`Closes #<issue-iid>` in the fix MR auto-closes the issue when merged.

After merge: confirm the issue is closed and both branches have been deleted (GitLab removes the source branch if `remove_source_branch` was set on the MR, or if project default "Delete source branch after merge" is on).

If the fix is unclear, high-risk, or large: stop at Phase 5. File the ticket, open the failing test MR, and let `/ship-next` pick it up in a future cycle when the approach is better understood.

---

## Intermittent bugs

Intermittent failures are harder to fix because they're hard to reproduce. Common causes:

| Cause | Signal | Approach |
| ----- | ------ | -------- |
| **Race condition** | Fails under load or concurrent access | Add logging to expose ordering; reduce concurrency to isolate |
| **Timing assumption** | Fails on slow machines or under load | Look for `sleep`, polling loops, or hardcoded timeouts |
| **External non-determinism** | Correlates with network calls or third-party APIs | Check for missing retries, unhandled timeouts, non-idempotent calls |
| **Resource exhaustion** | Fails at scale or after long uptime | Check connection pools, file descriptors, memory pressure |
| **Test ordering** | Passes alone, fails in suite | Tests sharing state they shouldn't — check global mutation, DB state, module caches |

To reproduce: add structured logging to make the intermittent state visible; run under artificial concurrency or load; use a fault injection tool if available.

---

## If you're stuck

If you've been working on the same hypothesis for more than 20 minutes without progress:

1. Step back — re-read the original error and reproduction steps from scratch
2. State the problem in plain language (rubber duck debugging works)
3. Check the boring things: wrong environment, stale build, off-by-one, null input, wrong branch
4. Widen the search — the bug may not be where the error surfaces
5. **Start fresh** — if you've corrected course twice with no progress, the context is polluted. Open a new session with a sharper prompt that incorporates what you've ruled out.
