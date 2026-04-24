---
name: groom
description: Backlog grooming — audit all open issues, validate dependency graph, fix drift, normalize labels, unblock dependents, close stale tickets, and leave the tracker in best-in-class shape.
compatibility: opencode
---

Perform a full backlog grooming pass on this project. Read the tracker broadly, act on what you find, and leave it cleaner than you found it.

> [!IMPORTANT]
> **Context window check:** Groom reads up to ~200 full issue bodies, builds a dependency graph, holds tracker state, and makes triage judgment calls — all at once. A large context window (ideally 1M tokens) keeps the entire backlog in scope without compression mid-pass. Standard context windows (200k or less) will truncate on non-trivial backlogs. If you're on a smaller window, either reduce `--per-page` limits below, or split the pass into per-milestone slices.

> [!TIP]
> For GitLab-backed projects, this skill handles workflow-label drift, label normalization, stale-issue closure, dependency unblocking, **sprint planning (Up Next reorder)**, and kanban-order triage. Sprint planning lives here — not in `/tracker-init`.

> [!NOTE]
> **When NOT to use:** Don't use in the first days of a project before the backlog has settled — labels and milestones need to exist first. Don't use as a substitute for maintaining good issue hygiene continuously; grooming cleans up drift, not neglect.

---

## Canonical workflow columns

This skill assumes scoped labels `workflow::*` per `/tracker-init`.

| Column            | Scoped label                | Purpose                                                                                       |
|-------------------|-----------------------------|-----------------------------------------------------------------------------------------------|
| **Backlog**       | `workflow::backlog`         | Raw / untriaged. Lands here by default on issue creation.                                     |
| **Up Next**       | `workflow::up-next`         | Triaged, well-specified, **ordered — top item is what `/ship-next` picks**.                   |
| **In Progress**   | `workflow::in-progress`     | Actively being worked.                                                                        |
| **In Review**     | `workflow::in-review`       | MR open; waiting on merge.                                                                    |
| **On Hold**       | `workflow::on-hold`         | Deferred by choice or external block. **Requires a comment with the reason.**                 |
| **Done**          | `workflow::done`            | Merged, or explicitly declined.                                                               |
| **Needs Design**  | `workflow::needs-design`    | Approach unclear; ADR or spec required before the issue can move forward.                     |

---

## Canonical Taxonomy (enforce, don't accommodate)

These names are the standard. Groom enforces conformance — it does not silently map non-standard names or leave drift in place. If the project uses different names, rename them. A grooming pass that accepts non-canonical naming leaves the tracker in a state that future automation and skills (especially `/ship-next`) cannot rely on.

### Canonical label names

| Category     | Canonical labels                                                                                                 |
|--------------|------------------------------------------------------------------------------------------------------------------|
| **Type**     | `feature`, `bug`, `chore`, `spike`, `infra`, `docs`, `epic`                                                      |
| **Priority** | `priority::p0-critical`, `priority::p1-high`, `priority::p2-medium`, `priority::p3-low`                          |
| **Size**     | `size::xs`, `size::s`, `size::m`, `size::l`, `size::xl`                                                          |
| **Workflow** | `workflow::backlog`, `workflow::up-next`, `workflow::in-progress`, `workflow::in-review`, `workflow::on-hold`, `workflow::done`, `workflow::needs-design` |
| **Tier**     | `tier::deep`, `tier::standard`                                                                                   |

Common drift → canonical rename map:

| Found                                              | Rename to               |
|----------------------------------------------------|-------------------------|
| `p0`, `P0`, `critical`, `urgent`                   | `priority::p0-critical` |
| `p1`, `P1`, `high`, `high-priority`                | `priority::p1-high`     |
| `p2`, `P2`, `medium`, `med-priority`               | `priority::p2-medium`   |
| `p3`, `P3`, `low`, `low-priority`                  | `priority::p3-low`      |
| `in-progress`, `wip`, `in progress`                | `workflow::in-progress` |
| `blocked`, `on hold`, `on-hold`                    | `workflow::on-hold`     |
| `ready`                                            | `workflow::up-next`     |
| `deep`, `opus`, `large-model`                      | `tier::deep`            |
| `standard`, `sonnet`, `small-model`                | `tier::standard`        |
| `enhancement`, `feat`, `new-feature`               | `feature`               |
| `fix`, `fixes`, `defect`                           | `bug`                   |

Any label not in the canonical taxonomy and not a valid domain label (e.g. `auth`, `billing`, `api`) should be deleted.

To rename a label, `glab label` does not currently support rename in-place — use the API:

```bash
glab api "projects/:id/labels/<old-name>" --method PUT -f new_name="<new-name>"
```

All issues carrying `<old-name>` will automatically reflect the new name.

---

## Project Discovery (run once before Phase 1)

Run the shell block from **`shared/project-discovery.md`** — it sets `PROJECT_PATH`, `BOARD_ENABLED`, and the `WORKFLOW_*` scoped labels referenced throughout.

---

## Phase 1 — Drift Self-Heal

Fix tracker inconsistencies before any analysis. All repairs are idempotent.

**`workflow::in-progress` on CLOSED issues**

```bash
for iid in $(glab issue list --state closed --label "workflow::in-progress" --per-page 100 -F json | jq -r '.[].iid'); do
  TARGET_WORKFLOW="$WORKFLOW_DONE"
  TARGET_NAME="Done"
  ISSUE_NUMBER="$iid"
  # Invoke flip_status helper (see shared/status-transition.md)
done
```

**CLOSED issues whose workflow label is not `workflow::done`** — same loop but broader filter:

```bash
glab issue list --state closed --not-label "workflow::done" --per-page 100 -F json \
  | jq -r '.[].iid'
# For each: flip to workflow::done via the helper
```

Report drift repaired in one line. If none, stay silent.

---

## Phase 2 — Full Audit

Collect data for grooming decisions. Parallelize reads.

```bash
glab issue list --per-page 200 -F json > /tmp/open-issues.json
```

Identify:

### 2a. Label gaps
Issues missing any of: **type**, **priority**, **size**, **tier**.

### 2b. Workflow drift
- Open issues with no `workflow::*` label (should be `workflow::backlog` or `workflow::up-next`)
- `workflow::in-progress` items with no commit activity in 3+ days and no open MR — stale WIP; candidate for `workflow::on-hold` with a reason
- `workflow::in-review` items whose linked MR has merged or closed — forgotten close-out; flip to `workflow::done`
- Items in `workflow::up-next` that still have open blockers in their body — should be `workflow::on-hold` or `workflow::backlog` until unblocked
- Items in `workflow::on-hold` whose stated blocker is now closed — should return to `workflow::up-next`

### 2c. Newly unblockable dependents
For each issue recently closed, search open issues whose body references it as a blocker:

```bash
glab issue list --state opened --search "\"Blocked by: #N\"" -F json
```

For each, check whether **all** listed blockers are now closed. If yes → flip workflow to `up-next` and post an "unblocked by closing #N" comment.

### 2d. Dependency audit

Build and validate the full dependency graph across all open issues. This is a comprehensive correctness pass.

**Step 1 — Extract all dependency edges**

```bash
# Extract every "Blocked by: #N" reference as a (dependent, blocker) edge
jq -r '.[] | .iid as $dep |
  ((.description // "") | scan("Blocked by: #([0-9]+)") | {dep: $dep, blocker: (.[0] | tonumber)})' \
  /tmp/open-issues.json > /tmp/dep-edges.json
# Result: each line is {"dep": <iid>, "blocker": <iid>}
```

**Step 2 — Validate each edge**

For each (dependent → blocker) pair, check:

| Check                                                                         | Signal                         | Action                                       |
|-------------------------------------------------------------------------------|--------------------------------|----------------------------------------------|
| Blocker doesn't exist                                                         | `glab issue view $N` returns 404 | Dead reference — remove from body            |
| Blocker is closed                                                             | `.state == "closed"`           | Stale reference — remove, re-check if fully unblocked |
| Blocker is open and in body, but dependent lacks `workflow::on-hold`          | Label missing                  | Add `workflow::on-hold`                      |
| Dependent has `workflow::on-hold` but body has zero "Blocked by: #N" lines    | Label orphan                   | Flip to `workflow::backlog` or `workflow::up-next` depending on readiness |

**Step 3 — Transitive unblocking**

When a stale reference is removed and the dependent now has zero remaining open blockers, it becomes fully unblocked. Walk the chain: unblocking #M may unblock #P, which may unblock #Q. Recurse until no new issues become unblocked.

For each transitively unblocked issue:
- Flip workflow `on-hold → up-next` via the helper
- Post a comment: `Unblocked — all blockers now closed (transitively via #N closing).`

**Step 4 — Cycle detection**

Build an adjacency list from the remaining valid edges. Run a DFS to detect cycles (A → B → C → A). Cycles cannot be auto-resolved — flag each one in the report and comment on the lowest-numbered issue in the cycle:

> Dependency cycle detected: #A → #B → #C → #A. Human resolution needed — one of these "Blocked by" references is likely stale or incorrect.

### 2e. Stale issues

```bash
# No activity in 90+ days
glab issue list --updated-before "$(date -v-90d +%Y-%m-%d 2>/dev/null || date -d '90 days ago' +%Y-%m-%d)" \
  --per-page 200 -F json
```

### 2f. Oversized issues

```bash
glab issue list --label "size::xl" --per-page 100 -F json
```

XL issues that aren't `spike` or `epic` are split candidates.

### 2g. Tier ratio health

Count `tier::deep` vs `tier::standard`. Flag if ratio falls outside 1:1 to 1:3.

### 2h. Missing milestones

```bash
glab issue list --milestone "None" --per-page 200 -F json
```

---

## Phase 3 — Triage Plan

Before acting, print this table to the conversation:

```
GROOMING PLAN
=============
Drift fixed:        [N closed-not-done flipped]
Label gaps:         [issue IIDs missing labels]
Workflow fixes:     [issues with wrong state → proposed fix]
Dependency audit:
  Stale references: [#dep → #blocker (closed) — will remove]
  Dead references:  [#dep → #blocker (not found) — will remove]
  Label orphans:    [on-hold with no open blocker in body — will fix]
  Label missing:    [has open blocker in body but no on-hold — will fix]
  Transitively unblocked: [issues that become free once stale refs removed]
  Cycles detected:  [#A → #B → #C → #A — human resolution needed]
Unblockable:        [issues to flip backlog/on-hold → up-next]
Stale (close):      [issues to close — 90d+ no activity, no milestone, no P0/P1]
XL split candidates:[XL non-spike issues to flag]
Tier ratio:         [X deep : Y standard — healthy / skewed]
Missing milestone:  [issue IIDs with no milestone]
Up Next reorder:    [N items will shift; top 5 shown in Phase 4.5 preview]
```

---

## Phase 4 — Execute

Work through the plan systematically.

### Fix workflow drift

Use the status-transition helper with the appropriate `TARGET_WORKFLOW` for each finding.

### Repair dependency graph

1. **Remove dead references** — edit the issue body to delete `Blocked by: #N` lines where #N doesn't exist.

2. **Remove stale references** — edit the issue body to delete `Blocked by: #N` lines where #N is closed. After each removal, re-count the issue's remaining open blockers.

   ```bash
   glab issue update <iid> --description "$(glab issue view <iid> -F json | jq -r '.description' | sed '/Blocked by: #<stale-N>/d')"
   ```

3. **Walk transitive unblocking** — after stale reference removal, collect all issues now at zero open blockers. For each:
   - Flip workflow `on-hold → up-next` via the helper
   - Post comment: `Unblocked — all blockers now closed. Moving to up-next.`
   - Check what *this* issue was blocking in turn — recurse until the chain terminates

4. **Flag cycles** — for each detected cycle, post a comment on the lowest-numbered issue in the cycle and add it to the report. Do not auto-repair — cycles require human judgment.

### Normalize labels — canonical names, no exceptions

First, rename any non-canonical labels to their canonical equivalents. Then add missing labels to issues. Do not leave non-canonical names in place — rename the label itself, not just the issues using it.

```bash
# Rename via GitLab API (updates all issues using it automatically)
glab api "projects/:id/labels/wip"       --method PUT -f new_name="workflow::in-progress"
glab api "projects/:id/labels/enhancement" --method PUT -f new_name="feature"

# Delete labels not in canonical taxonomy and not valid domain labels
glab api "projects/:id/labels/high-priority" --method DELETE

# Add missing labels to individual issues
glab issue update <iid> --label "priority::p2-medium,size::s,tier::standard"
```

### Close stale issues

Comment first, then close:

```bash
glab issue note <iid> --message "Grooming pass: no activity in 90+ days and no milestone. Closing as stale — reopen with updated context if still relevant."
glab issue close <iid>
```

**Never close a P0 or P1 for staleness alone.** These may be deferred, not forgotten.

### Flag XL split candidates

Note them in the report. Do not split without user instruction — splitting requires scope judgment.

---

## Phase 4.5 — Reorder the Up Next column (kanban triage)

The `workflow::up-next` set is a **deliberate queue** — its order is the order `/ship-next` will pull work in. GitLab doesn't expose a direct "column position" for labelled issues on a board the way Projects v2 does; the order is instead derived from the issue board's sort rule (usually **manual order by weight** or **priority**).

### Sort key (in priority order)

For each item currently carrying `workflow::up-next`:

1. **Priority**: `priority::p0-critical` → `priority::p1-high` → `priority::p2-medium` → `priority::p3-low` → null. Lower rank ships first.
2. **Milestone / phase**: earlier milestone ships first.
3. **Unblocks-count DESC**: number of other open issues whose body says `Blocked by: #<this>`. Items that unblock more others ship earlier.
4. **Size ASC**: `size::xs` → `size::s` → `size::m` → `size::l` → `size::xl` → null. Smaller ships first.
5. **`updated_at` DESC**: tiebreaker. Freshly-touched items ship first.

### Apply the reorder

GitLab boards support **manual ordering** via the `moveAfterId` / `moveBeforeId` parameters on issue reorder API calls:

```bash
# Move an issue to be placed after another in the board
glab api "projects/:id/issues/<iid>/reorder" --method PUT \
  -f move_after_id="<other-iid>"
```

This works when the board is configured to sort by **Manual** (otherwise the moves are overridden by the board's sort rule). If the board uses **Priority** or **Weight** sort, update the weight instead:

```bash
glab api "projects/:id/issues/<iid>" --method PUT -f weight=<n>
```

### Emit a preview before mutating

```
PROPOSED UP NEXT ORDER  (current → new)
=======================================
 1. (was 3)  #N P0/M0/S  unblocks 4  "Read pool + write queue"
 2. (was 1)  #M P0/M0/M  unblocks 2  "Lifecycle manager"
 3. (was 5)  #K P0/M1/M  unblocks 1  "TaskService + task_list"
 ...
```

### Idempotency + safety

- Idempotent: re-running groom on a clean queue should produce zero reorders.
- **Only reorder `up-next`.** Don't touch `in-progress`, `in-review`, `on-hold`, or `done`.
- **Never demote a P0 below a P1.** Flag priority inversions in the report instead.
- **Cap at 50 moves per run.**

---

## Phase 5 — Report

**Drift repairs**
- Flipped to done: #N, #M

**Workflow fixes**
- State corrected: [issue → from → to]

**Labels normalized**
- Fixed N issues with missing type / priority / size / tier labels

**Dependency audit**
- Stale references removed: [#dep had "Blocked by: #blocker" — blocker was closed]
- Dead references removed: [#dep had "Blocked by: #N" — #N not found]
- Label orphans fixed: [had on-hold, no open blocker in body]
- Labels added: [had open blocker in body, missing on-hold]
- Transitively unblocked: [chain of issues freed, e.g. #N → #M → #P]
- Cycles flagged (human action needed): [#A → #B → #A]

**Unblocked**
- on-hold → up-next: #N, #M (blockers now closed)

**Closed (stale)**
- #N — [title] (90d+ no activity, no milestone)

**Flagged for follow-up**
- XL split candidates: #N [title], #M [title]
- Tier ratio: [X:Y] — [healthy / review needed]
- Missing milestone: #N, #M
- Bugs worth fixing → delegate to `/ship-debug`: #N [title]
- Refactor opportunities → delegate to `/ship-refactor`: #N [title]

**Up Next reorder**
- Items moved: N (capped at 50/run)
- Top 5 after reorder: #A, #B, #C, #D, #E
- Priority-inversion flags (P1 ranked above P0): none / [list]

**Board health**

| Column           | Count | Notes                                    |
|------------------|-------|------------------------------------------|
| Backlog          | N     | untriaged                                |
| Up Next          | N     | ordered; `/ship-next` picks from the top |
| In Progress      | N     | healthy ≤ 2 at a time                    |
| In Review        | N     | MRs awaiting merge                       |
| On Hold          | N     | each should have a reason comment        |
| Done             | N     |                                          |

**Queue** — top 3 items in up-next, post-reorder:

| # | Issue | Priority | Size | Tier |
|---|-------|----------|------|------|

---

## Stopping condition

When running in a loop, stop scheduling further invocations when the grooming pass produces zero actions across all phases: no drift repaired, no label gaps, no stale issues closed, dependency graph clean, up-next already in canonical order, tier ratio healthy. A clean tracker is a valid terminal state.

Emit this exact phrase so a loop runner recognizes it:

> **Loop exit:** Tracker is in clean state — no actions taken this pass. Stopping.

---

## Guardrails

- **Never silently change priorities** — flag disagreements in the report instead.
- **Never close a P0 or P1 for staleness** — they may be deferred, not forgotten.
- **Never split an XL issue** without user instruction.
- **Never auto-resolve dependency cycles** — flag them in the report and comment on the issue; cycles need a human to decide which reference is wrong.
- **Never create new issues** during a grooming pass — that's for the bug/feature skills.
- **Surface bugs and refactor opportunities in the report; don't fix them here.** Delegate bugs to `/ship-debug` and structural improvements to `/ship-refactor` — grooming keeps the tracker clean, not the code.
- **Always comment before closing** — a closed issue with no comment is a mystery.
- **Always verify label mutations took effect** by re-querying after each change.
