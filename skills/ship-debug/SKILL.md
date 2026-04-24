---
name: ship-debug
description: GitLab-wired bug loop — discover bugs, document with excellent tickets, prove with failing tests, fix, ship
compatibility: opencode
---

Scan the codebase for the highest-priority reproducible bug, document it as a GitLab issue, prove it with a failing test, fix it, and ship behind an MR. Loop until no P0–P2 bugs remain.

This is the **GitLab-wired sibling** of `/debug`. Use `/debug` instead when root cause is unclear and you need to investigate before committing to a fix, or when you don't want tracker ceremony. Use this when you want autonomous, loopable bug elimination with a full audit trail.

> [!NOTE]
> **When NOT to use:** Don't use when root cause is unknown and investigation may exceed one session — use `/debug` first to understand the bug, then `/ship-debug` to fix it. Don't use for intermittent bugs that can't be reliably reproduced — prove reproducibility before invoking. Don't use when all known P0–P2 bugs already have active in-progress work.

> [!IMPORTANT]
> **Model capability check:** standard tier for clear bugs (obvious stack trace, single suspect file). Deeper tier for hard bugs (concurrency, intermittent, cross-system, no clear root cause). When in doubt, start standard; if root cause doesn't surface within one investigation pass, that's the signal to switch.

---

## Canonical workflow scoped labels

Uses the same scoped labels as `/ship-next`. See `/ship-next` for full definitions.

## Status-transition helper

See **`shared/status-transition.md`** for the code, required variables, and the scoped-label invariant. Never inline raw label mutations.

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

```bash
# 1. Prune stale local branches
git fetch --prune
git branch -vv | grep ': gone]' | awk '{print $1}' | xargs -r git branch -D

# 2. Remove workflow::in-progress from closed issues (flip to workflow::done)
for iid in $(glab issue list --state closed --label "workflow::in-progress" --per-page 100 -F json | jq -r '.[].iid'); do
  TARGET_WORKFLOW="$WORKFLOW_DONE"
  TARGET_NAME="Done"
  ISSUE_NUMBER="$iid"
  # Invoke flip_status helper
done
```

Report drift repaired in a single line. If none, say nothing.

---

## Protocol

### 1. Discovery

Check existing issues first — don't create duplicates, and don't re-investigate something already being worked.

```bash
# Known open bugs, highest priority first
glab issue list --label "bug,priority::p0-critical" --per-page 20
glab issue list --label "bug,priority::p1-high"     --per-page 20
glab issue list --label "bug,priority::p2-medium"   --per-page 20

# Skip any with workflow::in-progress — already being worked
glab issue list --label "bug,workflow::in-progress" --per-page 20
```

If known unworked bugs exist at P0–P2, pick the highest-priority one and skip to Decision — no need to scan for new bugs.

If the known bug backlog is empty or all bugs are in-progress, scan for undiscovered bugs:

```bash
git log --oneline -20                      # recent churn = instability signals
glab ci list --per-page 10                 # CI failures often signal real bugs
grep -r "TODO\|FIXME\|HACK\|XXX" --include="*.{ts,js,go,py,rb}" .
```

Focus the scan on: unhandled error paths, auth flows, data mutations without transactions, external calls without timeouts, concurrency-adjacent code.

### 2. Decision

Pick the single highest-priority reproducible bug. Prefer: higher severity → deterministic over intermittent → more users affected.

State before any code:

> **Bug:** one-sentence description of the observable failure
> **Severity:** P0–P3 and why
> **Location:** file(s) and line range(s) if known
> **Reproducibility:** deterministic or intermittent
> **Fix complexity:** S / M / L estimate
> **Evidence:** what in discovery pointed here
> **Passed over:** next 1–2 candidates and why they ranked lower

**Stopping condition** — when running in a loop, stop scheduling further invocations when:
- No P0–P2 bugs exist in the open backlog, and
- The discovery scan finds no new reproducible bugs above P3

Emit this exact phrase so a loop runner recognizes it:

> **Loop exit:** No P0–P2 bugs found — backlog clear and scan clean. Stopping.

### 3. Reproduce

Before writing a single line of code, confirm the bug is real and reliably triggerable.

- Identify the exact inputs and conditions that trigger the failure
- Confirm it fails in a clean environment (not local misconfiguration)
- Document the minimal reproduction case

**If you cannot reproduce it:** update the issue with what you tried, label it with a `needs-repro` plain label (create if missing), and loop to the next candidate. Do not guess at a fix for an unconfirmed bug.

### 4. Root cause analysis

Work through in order — don't skip ahead:

1. **Read** the relevant code paths before forming hypotheses
2. **Isolate** to the smallest scope where the failure occurs
3. **Hypothesize** one specific, falsifiable hypothesis
4. **Verify** — eliminate before moving to the next

Check the boring things first: wrong environment, stale build, off-by-one, null input, wrong branch.

**Bug archaeology** — find when it was introduced:

```bash
git log --format="%h %ci %s" -- <file>
git log --format="%h %ci %s" -S "<symptom string>"
```

**If root cause remains unclear after one focused investigation pass:** stop. File the issue (Step 5) with your investigation notes, and use `/debug` (not this skill) for deeper exploration. Don't force a fix onto an undiagnosed bug.

### 5. Create or update issue

Check whether an issue already exists (Step 1). If yes, update it with your reproduction and root cause findings. If no, create one using the full bug ticket format from `/debug` Phase 4 — labels, priority, fix options, reproduction steps, blast radius, acceptance criteria.

```bash
ISSUE_IID=$(glab issue create \
  --title "<imperative: what the bug does>" \
  --label "bug,priority::p1-high,size::m,tier::standard,workflow::backlog" \
  --description-file /tmp/bug-body.md \
  -F json | jq -r '.iid')
```

### 6. Execution

**Branch (worktree-isolated):**

```bash
SLUG=<kebab-description>
BUG_TEST_BRANCH="bug-test/${ISSUE_IID}-${SLUG}"
FIX_BRANCH="fix/${ISSUE_IID}-${SLUG}"

git worktree add "../worktrees/$BUG_TEST_BRANCH" -b "$BUG_TEST_BRANCH"
cd "../worktrees/$BUG_TEST_BRANCH"
```

**Mark in-progress immediately:**

```bash
glab issue note "$ISSUE_IID" --message "🚧 Work started — branch \`$BUG_TEST_BRANCH\`."
TARGET_WORKFLOW="$WORKFLOW_IN_PROGRESS"
TARGET_NAME="In Progress"
ISSUE_NUMBER="$ISSUE_IID"
# Invoke flip_status helper (skip if BOARD_ENABLED=false)
```

**Write a failing test** — prove the bug exists before fixing it:

- Asserts the **correct** behavior that currently fails
- Named for the behavior: `it("returns 400 when inventory_count is null")` not `it("bug #N test")`
- Minimal setup — the least scaffolding that still reproduces the bug

```bash
git add <test-file>
git commit -m "test(<scope>): prove bug #${ISSUE_IID} — <what the test asserts>"
git push -u origin "$BUG_TEST_BRANCH"

glab mr create \
  --source-branch "$BUG_TEST_BRANCH" \
  --title "test: failing test for #${ISSUE_IID} — <short description>" \
  --description "$(cat <<EOF
## Failing test for #${ISSUE_IID}

> [!IMPORTANT]
> **CI failure is expected and intentional.** This test asserts the correct behavior the bug currently prevents. It turns green when the fix lands.

Refs #${ISSUE_IID}
EOF
)"
```

**Fix branch — based on the bug-test branch** so the now-passing test is included:

```bash
git worktree add "../worktrees/$FIX_BRANCH" -b "$FIX_BRANCH" "origin/$BUG_TEST_BRANCH"
cd "../worktrees/$FIX_BRANCH"
```

Implement the fix. Confirm the failing test now passes. Run the full test suite — no regressions.

**Deletion sweep** — does the fix make any existing code redundant? Remove it.

**Self-review** via `/review-mr` on your own diff before opening the fix MR.

**Commit** using `/commit` — Conventional Commits, atomic.

### 7. Ship

```bash
git push -u origin "$FIX_BRANCH"
glab mr create \
  --source-branch "$FIX_BRANCH" \
  --target-branch "$BUG_TEST_BRANCH" \
  --remove-source-branch \
  --title "fix(<scope>): <imperative summary>" \
  --description "$(cat <<EOF
## Summary

<What the fix does and why it works.>

Closes #${ISSUE_IID}.

## Test plan

- [ ] Failing test from bug-test MR now passes
- [ ] Full test suite green
- [ ] Self-reviewed via /review-mr
- [ ] No regressions in adjacent behavior
EOF
)"
```

Note: the fix MR targets the bug-test branch, not the default branch. When the bug-test MR merges (after the fix MR merges into it), both land on the default branch together, with the test turning green in the same pipeline that ships the fix.

Flip workflow → `in-review` once MR is open (skip if `BOARD_ENABLED=false`).

**Merge when green:**

```bash
# Merge the fix MR into the bug-test branch first
glab mr merge <FIX_MR_IID> --squash --remove-source-branch --when-pipeline-succeeds --yes

# Then merge the bug-test branch into the default branch
glab mr merge <BUG_TEST_MR_IID> --squash --remove-source-branch --when-pipeline-succeeds --yes
```

Never skip hooks.

**Close-out checklist — every step in order:**

```bash
# a. Refresh MR state
glab mr view <BUG_TEST_MR_IID> -F json | jq '{state, merged_at}'

# b. Verify issue auto-closed
STATE=$(glab issue view "$ISSUE_IID" -F json | jq -r '.state')
[ "$STATE" = "closed" ] || { echo "FATAL: #$ISSUE_IID still $STATE — Closes keyword missing?" >&2; exit 1; }

# c. Flip workflow → done (skip if BOARD_ENABLED=false)
TARGET_WORKFLOW="$WORKFLOW_DONE"
TARGET_NAME="Done"
ISSUE_NUMBER="$ISSUE_IID"
# Invoke flip_status helper

# d. Remove worktrees and local branches
cd - || cd ~
git worktree remove "../worktrees/$FIX_BRANCH" --force
git worktree remove "../worktrees/$BUG_TEST_BRANCH" --force 2>/dev/null || true
git worktree prune
git branch -D "$FIX_BRANCH"
git branch -D "$BUG_TEST_BRANCH" 2>/dev/null || true

# e. Prune stale remote tracking refs
git fetch --prune
```

### 8. Tracker maintenance

After the merge, before ending the session:

1. **Find dependents** blocked by the just-closed issue:
   ```bash
   glab issue list --search "\"Blocked by: #$ISSUE_IID\"" -F json | jq -r '.[].iid'
   ```
2. **For each** with no remaining open blockers: flip workflow `on-hold → up-next` via the helper and post `unblocked by closing #<N>`.
3. **Stale hygiene:** fix any other issue with a drifted state.

### 9. Report

**What was done** — one paragraph: the bug, its root cause, the fix, why it was the right next thing. Link the merged MR and closed issue.

**Workflow changes:**
- Flipped: #N in-progress → in-review → done
- Unblocked (on-hold → up-next): #X, #Y (if any)

**Queue** — next 3 bug candidates:

| # | Severity | Issue / finding | Rationale |
|---|----------|-----------------|-----------|
| 1 | P1 | #N `<title>` | Highest priority unworked bug |
| 2 | P2 | #N `<title>` | Reproducible, moderate impact |
| 3 | P2 | `src/foo.ts:88` | Undiscovered — unhandled null in payment path |

Invoke `/ship-debug` again to execute the next item.

---

## Cadence

One invocation = one bug **found, proved, fixed, and merged**. Not a sweep of all known bugs in one shot — one bug, done completely, then loop.

**"Done" means merged to the default branch.** Fix implemented ≠ done. MR open ≠ done. Done is: fix MR merged into the bug-test branch, bug-test MR merged into the default branch, issue auto-closed, branches deleted, workflow flipped to `done`.

If the fix is unclear or high-risk after investigation: stop at the failing test MR. File the issue for `/ship-next` to pick up when the approach is better understood.

---

## Guardrails

- **Never fix without reproducing.** A fix for an unconfirmed bug may mask the real issue.
- **Never merge the fix without the failing test passing.** The test is the acceptance criterion.
- **The fix branch must be based on the bug-test branch** so the test comes with it.
- **Never merge without green pipelines** (beyond the intentionally-failing test MR).
- **Never skip hooks.**
- **Never delete a GitLab issue.** Close it with a reason if it's invalid.
- **If stuck > 20 minutes** without progress on root cause: step back, re-read reproduction steps, check the boring things. If still stuck after two direction changes, stop and use `/debug` for deeper exploration.
- **Invoking `/ship-debug` is the explicit, standing grant to branch, commit, push, open MRs, and merge.**
