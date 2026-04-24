---
name: ship-refactor
description: GitLab-wired refactor loop — scan for the highest-value refactoring opportunity, open an issue, branch, implement, MR, merge, repeat
compatibility: opencode
---

Scan the codebase for the highest-value refactoring opportunity, document it as a GitLab issue, implement it on a branch, ship it behind an MR, and loop. No direction needed — apply the `/refactor` checklist and engineering judgment.

This is the **GitLab-wired sibling** of `/refactor`. Use this when you want autonomous, tracked, loopable refactoring with a clean audit trail. Use `/refactor` instead for targeted, local, uncommitted work on a specific file or area.

> [!NOTE]
> **When NOT to use:** Don't use when you have a specific refactor target in mind and don't want tracker ceremony — use `/refactor` instead. Don't use on code in an open MR under active review — finish the review first. Don't mix refactoring with feature work — separate concerns into distinct commits.

> [!TIP]
> **Effort:** Standard tier for single-file or naming/structure cleanup. Deeper tier for architectural scope touching core domain logic or many interdependencies. When in doubt, start standard; if the finding feels complex to reason about, that's the signal to switch.

---

## Canonical workflow scoped labels

Uses the same scoped labels as `/ship-next`. See `/ship-next` for full definitions. Forward flow: `backlog → up-next → in-progress → in-review → done`. `on-hold` is a side-track reachable from any non-terminal state.

## Status-transition helper

Every workflow flip goes through the shared helper. See **`shared/status-transition.md`** for the code, required variables, and the scoped-label invariant. Never inline raw label mutations.

---

## Pre-flight

- `glab auth status` — authenticated
- `glab repo view` — current directory is a GitLab project

**Enable `remove_source_branch_after_merge`:**

```bash
CURRENT=$(glab api "projects/:id" | jq -r '.remove_source_branch_after_merge')
if [ "$CURRENT" != "true" ]; then
  glab api "projects/:id" --method PUT -f remove_source_branch_after_merge=true > /dev/null
fi
```

### Project discovery

Run the shell block from **`shared/project-discovery.md`**. It sets `PROJECT_PATH`, `BOARD_ENABLED`, and the `WORKFLOW_*` scoped-label names.

### Drift self-heal (run every cycle, before Discovery)

Previous cycles can leave stale state if interrupted between merge and close-out. Both checks are idempotent.

1. **Stale local branches** — prune remote tracking refs, delete local branches whose remote is gone:

   ```bash
   git fetch --prune
   git branch -vv | grep ': gone]' | awk '{print $1}' | xargs -r git branch -D
   ```

2. **`workflow::in-progress` on closed issues:**

   ```bash
   glab issue list --state closed --label "workflow::in-progress" --per-page 100 -F json \
     | jq -r '.[].iid'
   ```
   For each: flip to `workflow::done` via the helper.

3. **Open issues in `workflow::in-review` whose MR has merged or closed** — flip to `workflow::done` via the helper.

Report any drift repaired in a single line. If none, say nothing.

---

## Protocol

### 1. Discovery

Read broadly. Stop when you have a confident picture of the highest-value refactoring opportunity.

1. **Recent churn** — high-touch files are instability signals:
   ```bash
   git log --oneline -20
   git diff HEAD~5..HEAD --stat
   ```

2. **Debt markers:**
   ```bash
   grep -r "TODO\|FIXME\|HACK\|XXX" --include="*.{ts,js,go,py,rb}" .
   ```

3. **Core implementation files** — entry points, domain logic, recently changed files.

4. **Existing refactor issues** — don't duplicate open work:
   ```bash
   glab issue list --label "chore" --search "refactor" --per-page 20
   ```

Apply the `/refactor` checklist to what you read:

- **Cleanup:** dead code, duplication (≥3 instances), unnecessary abstraction, bloated conditionals
- **Domain-Driven Design:** names reflect domain language; domain logic in the domain layer
- **SOLID:** single responsibility, dependency inversion, Liskov substitution
- **Pure functions:** logic extracted from I/O; no mutation of inputs
- **Reliability:** unbounded external calls, missing error handling at boundaries, N+1 patterns

Cross-reference: a TODO near a recently changed file with no tests is a different priority than the same TODO in stable, well-tested code.

### 2. Decision

Pick the single highest-value finding. Prefer: higher impact → more isolated (lower blast radius) → reversible.

State before any code:

> **Finding:** what the problem is, in one sentence
> **Location:** file(s) and line range(s)
> **Checklist item:** which `/refactor` checklist category this falls under
> **Evidence:** what in discovery pointed here
> **Effect:** what this cleans up, prevents, or enables
> **Passed over:** the next 1–2 candidates and why they ranked lower
> **Net-deficit goal:** expected line delta (negative = good)

**Stopping condition** — when running in a loop, stop scheduling further invocations when the `/refactor` checklist passes clean across the codebase: nothing to delete, no duplication, no dead code, no bloated conditionals, naming is clear, no reliability gaps. A pass that produces a net-zero-diff finding is the signal.

Emit this exact phrase so a loop runner recognizes it:

> **Loop exit:** Checklist passed clean — nothing left to subtract or improve. Stopping.

### 3. Create Issue

Open a GitLab issue documenting the refactoring before writing any code. This is the audit trail.

```bash
ISSUE_IID=$(glab issue create \
  --title "refactor: <concise description>" \
  --label "chore,tier::standard,workflow::backlog" \
  --description "$(cat <<EOF
## Finding

<What the problem is and where it lives — file:line range>

## Checklist Item

<Which /refactor checklist category: dead code / duplication / unnecessary abstraction / bloated conditionals / naming / SOLID / pure functions / reliability>

## Acceptance Criteria

- [ ] <Observable, testable outcome>
- [ ] Net-deficit line count (or justified exception)
- [ ] All code follows \`/coding\` standards
- [ ] Tests updated if behavior surface changed

## Technical Notes

<Files, patterns, constraints>
EOF
)" -F json | jq -r '.iid')
```

Use `tier::deep` instead of `tier::standard` if the finding requires deep architectural reasoning.

### 4. Execution

```bash
BRANCH=refactor/${ISSUE_IID}-<kebab-description>
WORKTREE=../worktrees/$BRANCH
git worktree add "$WORKTREE" -b "$BRANCH"
cd "$WORKTREE"
```

All edits, test runs, and commits happen inside `$WORKTREE`. The main checkout stays on the default branch.

**Mark in-progress immediately — before writing any code:**

```bash
# 1. Post start comment
glab issue note "$ISSUE_IID" --message "🚧 Work started — branch \`$BRANCH\`."

# 2. Flip workflow → in-progress via the helper (skip if BOARD_ENABLED=false)
TARGET_WORKFLOW="$WORKFLOW_IN_PROGRESS"
TARGET_NAME="In Progress"
ISSUE_NUMBER="$ISSUE_IID"
# Invoke flip_status helper — see shared/status-transition.md
```

**Implement:**

- Apply the `/refactor` checklist to the specific finding
- The primary directive: **subtract**. Start by looking for what to delete
- Every line kept must earn its place; net-negative line count is the goal
- Don't introduce new behavior — this is a pure structural improvement

**Deletion sweep** — before committing, ask: does any existing code become redundant given what you just changed? A net-positive diff needs justification.

**Self-review** — run the `/review-mr` protocol on your own diff before opening the MR.

**Test:** run the test suite. If tests break, fix them or (if asserting implementation details, not behavior) delete the test.

**Commit** using `/commit` — atomic Conventional Commits.

### 5. Ship

```bash
git push -u origin "$BRANCH"
glab mr create \
  --source-branch "$BRANCH" \
  --remove-source-branch \
  --title "refactor: <description>" \
  --description "$(cat <<EOF
## Summary

- <bullet describing structural change>

Closes #${ISSUE_IID}.

## Breaking change?
- [x] No

## Net change

<+X / -Y lines across Z files>

## Test plan

- [ ] Test suite green locally
- [ ] Self-reviewed via /review-mr
- [ ] No behavior changes — pure structural improvement
EOF
)"
```

**Immediately flip workflow → `in-review`** (skip if `BOARD_ENABLED=false`):

```bash
TARGET_WORKFLOW="$WORKFLOW_IN_REVIEW"
TARGET_NAME="In Review"
# Invoke flip_status helper
```

**Merge** when green:

```bash
glab mr merge <MR_IID> --squash --remove-source-branch --when-pipeline-succeeds --yes
```

Never skip hooks.

**Close-out checklist — run every step in order:**

```bash
# a. Refresh MR state
glab mr view <MR_IID> -F json | jq '{state, merged_at}'

# b. Verify the issue auto-closed
STATE=$(glab issue view "$ISSUE_IID" -F json | jq -r '.state')
if [ "$STATE" != "closed" ]; then
  echo "FATAL: MR merged but #$ISSUE_IID is still $STATE — Closes keyword missing?" >&2
  exit 1
fi

# c. Flip workflow → done (skip if BOARD_ENABLED=false)
TARGET_WORKFLOW="$WORKFLOW_DONE"
TARGET_NAME="Done"
ISSUE_NUMBER="$ISSUE_IID"
# Invoke flip_status helper

# d. Remove the worktree and delete the local branch
cd - || cd ~
git worktree remove "$WORKTREE" --force
git worktree prune
git branch -D "$BRANCH"

# e. Prune stale remote tracking refs
git fetch --prune
```

### 6. Tracker maintenance

After the merge, before ending the session:

1. **Find dependents** blocked by the just-closed issue:

   ```bash
   glab issue list --search "\"Blocked by: #$ISSUE_IID\"" -F json | jq -r '.[].iid'
   ```

2. **For each dependent** with no remaining open blockers: flip workflow `on-hold → up-next` via the helper, and post a comment (`unblocked by closing #<N>`).

3. **Stale-state hygiene:** fix any other issue that has drifted.

### 7. Report

**What was done** — one paragraph: the structural change, what it cleaned up, why it was the right next thing. Link the merged MR and the closed issue.

**Net change:** `+X / -Y lines across Z files`

**Workflow changes:**
- Flipped: #N in-progress → in-review → done
- Unblocked (on-hold → up-next): #X, #Y (if any)

**Queue** — next 3 refactoring candidates:

| # | Checklist item | Location | Rationale |
|---|----------------|----------|-----------|
| 1 | Dead code | `src/foo.ts:42` | Unreachable branch, confirmed by coverage |
| 2 | Duplication | `src/bar.ts`, `src/baz.ts` | Same 15-line block in both |
| 3 | Bloated conditional | `src/handler.ts:88` | 4-level nested if, extractable to guard clauses |

Invoke `/ship-refactor` again to execute the next item.

---

## Cadence

One invocation = one refactoring finding **merged to the default branch and closed**. Not a sweeping multi-file overhaul in one shot — one coherent structural improvement, reported, then loop.

**"Done" means merged to the default branch.** Implementation complete ≠ done. MR open ≠ done. Done is: MR merged, issue auto-closed by `Closes #N`, branch deleted, workflow flipped to `done`.

If a finding is too large for one session, complete one coherent slice that leaves the system green and runnable, then file a follow-up issue for the remainder.

---

## Guardrails

- **No behavior changes.** If a refactoring accidentally changes behavior, stop, revert, and file a bug issue.
- **Never merge without green pipelines.**
- **Never skip hooks.**
- **Never delete a GitLab issue.** Close it with a reason if it's invalid.
- **If the finding evaporates mid-implementation** (already removed, or smaller than it looked): close the issue with a comment explaining why, and loop to the next candidate.
- **If stuck > 30 minutes** on a structural decision: file a `workflow::needs-design` issue, draft an ADR, and move on.
- **Invoking `/ship-refactor` is the explicit, standing grant to branch, commit, push, open an MR, and merge.**
