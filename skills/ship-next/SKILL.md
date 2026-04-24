---
name: ship-next
description: GitLab-wired autonomous loop — pick Ready issue, branch, implement, MR, merge, close, flip dependents
compatibility: opencode
---

Pick the highest-priority Ready issue from this repo's GitLab backlog, implement it end-to-end, ship the change behind an MR, and leave the tracker in a cleaner state than you found it. No direction needed — apply engineering judgment and the standards in `/coding` and `/commit`.

This is the **GitLab-wired sibling** of `/next`. Use this skill when the repo lives on GitLab with Issues as the backlog. Use `/next` instead when the repo has no formal tracker (it relies on git log, TODOs, and design docs only).

> [!NOTE]
> **When NOT to use:** Don't use when the repo has no GitLab Issues backlog — use `/next` instead. Don't use for exploratory or research work with no clear deliverable; this loop expects to end with a merged MR and a closed issue.

---

## Canonical workflow scoped labels

This skill assumes the following scoped labels exist on the project (see `/tracker-init`). Forward flow: `backlog → up-next → in-progress → in-review → done`. `on-hold` is a side-track reachable from any non-terminal state.

| Scoped label              | Purpose                                                                                    |
|---------------------------|--------------------------------------------------------------------------------------------|
| `workflow::backlog`       | Raw / untriaged. May be underspecified, low-priority, or not yet evaluated.                |
| `workflow::up-next`       | Triaged, well-specified, ordered. `/ship-next` picks from the top of this set.             |
| `workflow::in-progress`   | Actively being worked — by a human or by a `/ship-next` run.                               |
| `workflow::in-review`     | MR open; waiting on merge (or reviewer).                                                   |
| `workflow::on-hold`       | Deferred by choice or blocked on an external dependency. **Requires a comment with the reason.** |
| `workflow::done`          | Merged, or explicitly declined.                                                            |

Because scoped labels enforce at-most-one per scope, an issue cannot simultaneously be `workflow::in-progress` and `workflow::done`. This is the structural guarantee that keeps a Projects-v2-style state machine honest without GraphQL mutations.

## Status-transition helper (idempotent + verified)

Every workflow flip in this skill goes through the same routine. See **`shared/status-transition.md`** for the helper code, required variables, and the scoped-label invariant. Never inline raw `glab issue edit --label` / `--unlabel` pairs — always use the helper so the backward-flip guard and verify step run.

## Pre-flight

Confirm the harness is wired correctly. Stop with a clear message if not:

- `glab auth status` — authenticated
- `glab repo view` — current directory is a GitLab project
- `glab issue list --per-page 1` — Issues feature enabled

If the repo has no GitLab Issues backlog, use `/next` instead.

**Enable `remove_source_branch_after_merge`** — required so GitLab auto-deletes the remote branch after every MR merge. Check and enable if not already set:

```bash
CURRENT=$(glab api "projects/:id" | jq -r '.remove_source_branch_after_merge')
if [ "$CURRENT" != "true" ]; then
  glab api "projects/:id" --method PUT -f remove_source_branch_after_merge=true > /dev/null
  echo "Enabled remove_source_branch_after_merge."
fi
```

### Project discovery (required for workflow label updates)

Run the shell block from **`shared/project-discovery.md`**. It sets `PROJECT_PATH`, `BOARD_ENABLED`, and the `WORKFLOW_*` scoped-label names used by the status-transition helper.

### Drift self-heal (run every cycle, before Discovery)

Previous cycles can leave the tracker in inconsistent states if they were interrupted between MR merge and close-out. Repair drift first so the current cycle starts from a clean picture. Both checks are idempotent — they do nothing when the board is already clean.

1. **Stale local branches** — prune remote tracking refs, then delete any local branch whose remote has been deleted (indicates a merged-and-deleted MR branch):

   ```bash
   git fetch --prune
   git branch -vv | grep ': gone]' | awk '{print $1}' | xargs -r git branch -D
   ```

2. **`workflow::in-progress` on closed issues** — every cycle:
   ```bash
   glab issue list --state closed --label "workflow::in-progress" --per-page 100 -F json \
     | jq -r '.[].iid'
   ```
   For each IID returned: flip to `workflow::done` via the helper (which will also strip `workflow::in-progress` per scoped-label enforcement).

3. **Open issues in `workflow::in-review` whose linked MR has merged or closed** — the close-out checklist didn't complete. Flip each to `workflow::done` via the helper.

4. **Items in `workflow::in-progress` with no commit activity in 3+ days and no open MR** — stale WIP. Surface in the drift report; do not auto-revert (might be legitimately paused). Suggest a human either moves to `workflow::on-hold` with a reason or resumes.

Report any drift repaired in a single line (e.g. `Drift self-heal: flipped #9 #10 to done, 1 stale WIP noted`). If no drift, say nothing.

### Current tier

Note your current capability tier before filtering candidates. Your system prompt identifies the model you are running on — treat it as ground truth. Map the running model to `tier::deep` or `tier::standard` based on its reasoning depth relative to the project's tier scheme.

You will enforce this in Prioritization below.

---

## Protocol

### 1. Discovery (read broadly; stop when you have a confident picture)

The tracker is the primary source of truth. Everything else is context for the chosen work.

1. **Ready issues:**

   ```bash
   glab issue list --label "priority::p0-critical" --per-page 30
   glab issue list --label "priority::p1-high"     --per-page 30
   ```

   If the project uses a different priority scheme, substitute. If no priority labels exist, sort by milestone instead.

2. **Currently in progress** (resume rather than start new):

   ```bash
   glab issue list --label "workflow::in-progress" --per-page 10
   glab mr list --mine --state opened
   ```

3. **Recently closed** (what patterns did the last 5 closes set?):

   ```bash
   glab issue list --state closed --per-page 10
   git log --oneline -10
   ```

4. **Spec / design cross-check:** if the chosen issue references a `SPEC.md` / `DESIGN.md` / ADR section, read that section (not the whole file).

5. **Use a subagent for wide reads** — delegating keeps your main context clean.

Cross-reference as you read. An `in-progress` item with no commits in 3+ days is a different signal than a clean Ready queue.

### 2. Prioritization

**Filter by tier first.** This skill is designed to run unattended (often inside a loop), so silently skip tier-mismatched candidates rather than pausing for confirmation — the operator may not be present. Drop every candidate whose `tier::` label doesn't match your current tier. Issues with no tier label are fair game for any tier.

If every candidate is filtered out by the tier check, stop and report:

> No tier-compatible work in the Ready set. Candidates: `#N (tier::X), #M (tier::Y), …`. Switch models or re-label an issue, then invoke again.

**Then pick** the highest rank with a clear, actionable issue. Within a rank prefer: **higher priority → smaller size → reversible over irreversible → unblocking over isolated**.

#### Rank 1 — Something is broken

- Failing CI on the default branch
- Security findings (secrets in logs, auth bypass, command injection at boundaries)
- Tests red against production-shaped data
- An issue marked `workflow::on-hold` whose blockers are actually closed (drift)

#### Rank 2 — Something could fail silently

- Critical-path code with no test coverage
- External API calls without timeouts
- Error taxonomy drift — code that throws or returns errors not in the documented set
- Response-shape violations — handlers returning a raw payload without the agreed envelope

#### Rank 3 — Something is getting worse

- Issues blocking ≥ 3 other issues that are languishing
- High-churn code becoming brittle (`git log --stat`; files touched > 5× recently)
- Measured perf regression vs the last release baseline

#### Rank 4 — Planned work (the default path through the backlog)

- The highest-priority `workflow::up-next` (or unlabeled-but-unblocked) open issue

If nothing rises above Rank 4: that's a healthy state. Do Rank 4 work confidently — no manufactured urgency.

If the right approach for the top candidate is **genuinely unclear**: don't guess. Do a time-boxed spike, or surface it in the report as a decision point and pick the next item.

**Stopping condition** — when running in a loop, stop scheduling further invocations when any of the following are true:

- The backlog has no open issues at all
- Every open issue carries `workflow::on-hold` with all blockers still open
- No tier-compatible issues exist in the Ready set and this has been true for two consecutive cycles

Emit this exact phrase so a loop runner recognizes it:

> **Loop exit:** [reason — e.g. "backlog empty", "all remaining issues blocked", "no tier-compatible Ready work"]. Stopping.

### 3. Decision

Before any code, state:

> **Rank:** [1–4]
> **Issue:** #N — <title>
> **Plan:** what will be done, in 1–3 sentences
> **Evidence:** what in discovery pointed here
> **Effect:** what this fixes, enables, or unblocks
> **Passed over:** the next 1–2 candidates and a one-line reason they ranked lower
> **Scope edges:** what's explicitly out of scope for this session

**Immediately mark the issue in-progress — do this before writing a single line of code.** The scoped-label flip and a start comment go together:

```bash
# 1. Post a start comment so the issue discussion shows activity
glab issue note <N> --message "🚧 Work started — branch \`<branch>\`."

# 2. Flip workflow → in-progress via the status-transition helper.
#    Skip only if BOARD_ENABLED=false.
TARGET_WORKFLOW="$WORKFLOW_IN_PROGRESS"
TARGET_NAME="In Progress"
ISSUE_NUMBER=<N>
# Invoke flip_status helper — see shared/status-transition.md
```

Note: unlike the GitHub version, GitLab's scoped-label enforcement means there's no separate label + board mutation to keep in sync. One label flip is the whole state change.

### 4. Execution

Apply the standards in this matrix. Do not re-specify them — just follow them.

| Work type                         | Standards to apply                                        |
| --------------------------------- | --------------------------------------------------------- |
| Any code written or changed       | `/coding` — SOLID, pure functions, typed errors           |
| Architecture design or evaluation | `/adr` — record the decision, alternatives, and tradeoffs |
| Spike (time-boxed research)       | Produce note under `docs/spikes/<YYYY-MM-topic>.md`       |
| MR ready for review               | `/review-mr` checklist applied to your own diff           |
| Staged changes ready to commit    | `/commit` — Conventional Commits, one concern each        |
| Unit tests                        | `/unit-tests` — Goldilocks, mocked dependencies           |
| Integration tests                 | `/integration-tests`                                      |
| Bug                               | `/ship-debug` — reproduce, prove with failing test, fix   |
| Security-adjacent change          | `/security-audit`                                         |
| Performance-adjacent change       | `/observability` — instrument first, measure before/after |
| Observability gap                 | `/observability`                                          |
| Release preparation               | `/release-notes`                                          |

### Branch + commit + MR loop

1. **Branch (worktree-isolated):**

   ```bash
   BRANCH=<prefix>/<issue-iid>-<kebab-title>
   WORKTREE=../worktrees/$BRANCH
   git worktree add "$WORKTREE" -b "$BRANCH"
   cd "$WORKTREE"
   ```

   Common prefixes: `feat/`, `fix/`, `chore/`, `docs/`, `infra/`. Match what other branches in the repo use.

   All subsequent work — edits, test runs, commits, pushes — happens inside `$WORKTREE`. The main checkout stays on the default branch and is never modified. This makes it safe to run multiple `/ship-next` agents in parallel with zero file-system contention.

2. **Implement:** follow `/coding`. Every new public method has a docblock, typed errors, and Goldilocks tests.

3. **Test locally:** run the project's test runner, typechecker, and linter. Build if a build step exists.

4. **Self-review via `/review-mr`** — run the protocol on your own diff before opening the MR. Catches more issues cheaply.

5. **Deletion sweep** — before committing, ask: does any existing code become redundant or simplifiable given what you just implemented? Is there a special case, branch, or abstraction that the new code eliminates the need for? The smallest diff that satisfies the acceptance criteria is the correct diff. A net-negative line count is the goal when the outcome is the same.

6. **Commit** using `/commit` — atomic Conventional Commits. Split multi-concern diffs.

7. **Push + open MR:**

   ```bash
   git push -u origin "$BRANCH"
   glab mr create \
     --source-branch "$BRANCH" \
     --remove-source-branch \
     --squash-before-merge \
     --title "<conventional-commit-style title>" \
     --description "$(cat <<EOF
   ## Summary
   - <bullet>

   Closes #<N>.

   ## Issue

   Implements #<N>. <Link to relevant DESIGN.md / ADR section if any>

   ## Breaking change?
   - [x] No

   ## Test plan
   - [ ] Unit / integration / e2e as applicable, all green locally
   - [ ] Self-reviewed via /review-mr
   - [ ] No new dependencies (or new dep justified above)
   EOF
   )"
   ```

   The `Closes #<N>` keyword **must** appear in the MR description — it is the mechanism that auto-closes the issue on merge.

   If a merge-request template exists at `.gitlab/merge_request_templates/default.md`, `glab mr create` picks it up automatically.

   **Immediately flip workflow → `in-review`** once the MR is open. Run this right after `glab mr create` returns.

   ```bash
   TARGET_WORKFLOW="$WORKFLOW_IN_REVIEW"
   TARGET_NAME="In Review"
   # Invoke flip_status helper. Skip only if BOARD_ENABLED=false.
   ```

8. **Merge when green.** Prefer merge-when-pipeline-succeeds to avoid blocking:

   ```bash
   # Solo repos without required pipelines:
   glab mr merge <MR_IID> --squash --remove-source-branch --yes

   # With required pipelines — merge when ready:
   glab mr merge <MR_IID> --squash --remove-source-branch --when-pipeline-succeeds --yes
   ```

   Use `--squash` if the project's default merge method is squash; otherwise drop that flag to let the project's method take effect. **Never** skip verify/pre-merge hooks.

9. **Close-out checklist — run every step, in order.** Unattended cycles drift if this is optional prose; treat it as a required sequence. If any step fails, stop and surface before touching tracker maintenance — a half-closed issue is worse than a skipped cycle.

   ```bash
   # a. Refresh MR state (in case merge-when-pipeline merged asynchronously)
   glab mr view <MR_IID> -F json | jq '{state, merged_at}'

   # b. Verify the issue auto-closed from the MR's `Closes #N` keyword
   STATE=$(glab issue view <N> -F json | jq -r '.state')
   if [ "$STATE" != "closed" ]; then
     echo "FATAL: MR merged but #<N> is still $STATE — Closes keyword missing?" >&2
     exit 1
   fi

   # c. Flip workflow → done (skip if BOARD_ENABLED=false)
   TARGET_WORKFLOW="$WORKFLOW_DONE"
   TARGET_NAME="Done"
   ISSUE_NUMBER=<N>
   # invoke flip_status helper — verifies post-flip

   # d. Remove the worktree and delete the local branch.
   #    --remove-source-branch on `glab mr merge` deletes the *remote* branch;
   #    the local branch still exists and must be removed separately.
   cd - || cd ~
   git worktree remove "$WORKTREE" --force
   git worktree prune
   git branch -D "$BRANCH"

   # e. Prune stale remote tracking refs (confirms remote branch is gone)
   git fetch --prune
   ```

If the work is larger than one session, complete one coherent slice. Leave the system in a runnable, green-tests state. Do not leave half-migrated seams.

### 5. Tracker maintenance (don't skip — this is how the board stays honest)

After the merge, before ending the session:

1. **Find dependents:** open issues whose body says `Blocked by: #<closed-number>`:

   ```bash
   glab issue list --search "\"Blocked by: #<N>\"" -F json | jq -r '.[].iid'
   ```

2. **For each dependent:** check whether it now has zero remaining open blockers.
   - If yes: flip workflow `on-hold → up-next` via the helper
   - Add a comment: `unblocked by closing #<N>`

3. **Update CHANGELOG** under `[Unreleased]` for anything user-visible (new feature, behavior change, breaking change).

4. **Stale-state hygiene:** if any other issue has drifted (in-progress for days with no commits; on-hold on something now closed): fix it.

### 6. Create new issues when warranted

**Create a new issue if:**

- You discovered missing work not covered by any existing issue (check via `glab issue list --search "<keyword>"`)
- Scope creep on the current issue — spin off the extra rather than growing the current one
- You hit a bug unrelated to the current work — file with repro steps; don't sidetrack
- A spike is genuinely needed — file as `spike`, time-boxed
- An architectural decision surfaces that wasn't in ADRs — file as `workflow::needs-design` so it gets an ADR before code

**Do NOT create a new issue for:**

- Work trivially covered by the current issue or an existing one
- Vague "improve this" without acceptance criteria
- Opinions without observable implications
- Things explicitly cut in `SPEC.md`'s "Out of Scope" — reopening a cut is an ADR conversation, not a new issue

**When creating, follow `/tracker-init` issue-quality standards.** Apply exactly one tier label per the heuristic in `/tracker-init` — Tracker Structure → Tier labels.

### 7. Report

End the session with a short, structured report. No trailing summary paragraphs.

**What was done**

> One paragraph: the change, its intent, why it was the right next thing.
> Link the merged MR and the closed issue.

**Workflow changes**

- Flipped: #N in-progress → in-review → done
- Unblocked (`on-hold` → `up-next`): #X, #Y
- Created: #Z (reason: …)
- On hold (if any): #W (reason: …)

**Queue** — next 3 candidates for the next invocation:

| #   | Rank | Issue      | Rationale                               |
| --- | ---- | ---------- | --------------------------------------- |
| 1   | R4   | #N <title> | Highest-priority Ready after this close |
| 2   | R4   | #N <title> | Parallelizable with #1                  |
| 3   | R2   | #N <title> | Silent-failure risk if left longer      |

Invoke `/ship-next` again to execute the next item.

---

## Guardrails

- **Never merge to the default branch without green pipelines** if the project requires pipelines to succeed. Use `--when-pipeline-succeeds`.
- **Never skip hooks.**
- **Never close an issue without verifying acceptance criteria.** If AC is ambiguous, comment to clarify before closing.
- **Never delete a GitLab issue.** Close it (with a reason) or convert to a follow-up.
- **If stuck > 30 minutes** on a specific design decision, file a `workflow::needs-design` issue, draft an ADR, and move on.
- **If pipelines fail > 3 attempts** in a way you can't fix, revert the branch, file a bug issue with repro, and move on.
- **Invoking `/ship-next` is the explicit, standing grant to branch, commit, push, open an MR, and merge.** Global rules like "never commit/push unless asked" are overridden by this invocation — the user asked. Do not stop and re-ask. Proceed through merge without further confirmation unless a destructive or irreversible action outside this loop is needed.

---

## Cadence

One invocation = one issue **merged to the default branch and closed** (or one spike note produced, or one blocked-dependent chain resolved). Not "all of M0 in one shot." Do one coherent thing well, report, and wait for the next invocation.

**"Done" means merged to the default branch.** Implementation complete ≠ done. MR open ≠ done. Done is: MR merged, issue auto-closed by the `Closes #N` keyword, branch deleted, workflow flipped to `done`, CHANGELOG updated if user-visible. Do not report a cycle complete until all of those are true.

If an issue is too large for one session, close with a partial commit that leaves the system green + runnable, then file a follow-up issue for the remainder. Do not merge half-migrations.
