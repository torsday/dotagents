---
name: tracker-init
description: GitLab tracker initialization — bootstrap labels, milestones, and issue templates for a new project
compatibility: opencode
---

Looking at the project's design docs and specs — bootstrap the issue tracker so work is visible, sequenced, and ready to execute. This skill is a one-time setup tool; for ongoing triage and backlog health, use `/groom`.

> [!NOTE]
> **This skill vs `/tasking` and `/groom`:** `/tasking` decomposes a design into a session-level task plan. This skill translates that plan into persistent GitLab Issues that live outside the session and are visible to the whole team. For ongoing maintenance — closing stale issues, reordering the backlog, sprint planning — use `/groom`.
>
> **Design-phase pipeline:** `/spec` (write the spec) → `/tasking` (sequence the work) → `/tracker-init` (put it in the tracker).

> [!NOTE]
> **When NOT to use:** Don't use before `/tasking` has decomposed the work — creating issues into an unstructured backlog is harder to fix than starting right. Don't create issues for vague goals without acceptance criteria; those belong in `/spec` first. Don't use for mid-project triage or sprint planning — use `/groom`.

---

## Discovery

Read in this order. Stop when you have a confident picture.

1. **Design docs and specs** — `docs/`, `DESIGN.md`, `SPEC.md`, `RFC-*.md`
2. **ADRs** — decisions already locked in that constrain implementation
3. **`/tasking` output** — if a task breakdown exists in the current session or in `TASKS.md`, use it as primary input; do not re-derive
4. **Existing tracker state:** `glab issue list --all --per-page 100`, `glab milestone list`, `glab label list`
5. **`AGENTS.md` / `README.md`** — domain language, tech stack, conventions

---

## Tracker Structure

Establish scaffolding before creating any issues. Creating issues into an unstructured tracker is harder to fix than starting right.

### Scoped labels vs plain labels

GitLab has two label kinds:

- **Plain labels** — `bug`, `feature`, `auth` — an issue can carry many
- **Scoped labels** — `priority::p1-high`, `workflow::in-progress` — an issue can carry only **one** per scope (the double-colon separator is what makes a scope)

The workflow/priority/size/tier dimensions use scoped labels so they enforce a single state per issue. Domain and type labels are plain.

### Labels

Derive domain labels from the design. Only create labels that exist in the actual scope — no speculative ones.

| Category       | Kind      | Labels                                                                                                     |
| -------------- | --------- | ---------------------------------------------------------------------------------------------------------- |
| **Type**       | Plain     | `feature`, `bug`, `chore`, `spike`, `infra`, `docs`, `epic`                                                |
| **Priority**   | Scoped    | `priority::p0-critical`, `priority::p1-high`, `priority::p2-medium`, `priority::p3-low`                    |
| **Size**       | Scoped    | `size::xs`, `size::s`, `size::m`, `size::l`, `size::xl`                                                    |
| **Workflow**   | Scoped    | `workflow::backlog`, `workflow::up-next`, `workflow::in-progress`, `workflow::in-review`, `workflow::on-hold`, `workflow::done`, `workflow::needs-design` |
| **Tier**       | Scoped    | `tier::deep`, `tier::standard`                                                                             |
| **Domain**     | Plain     | Derived from design — e.g. `auth`, `api`, `ui`, `db`, `billing`, `infra`, `ml`                             |

Size calibration: XS = a few hours · S = ~1 day · M = 2–3 days · L = 4–5 days · XL = split before starting

#### Tier labels

Every open issue gets exactly one of `tier::deep` or `tier::standard`. This lets `/ship-next` filter the Ready queue by the current model's capability tier so parallel loop threads (one deep, one standard) never collide on the same issue.

| Label             | When                                                                                                                                                                                         |
| ----------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `tier::deep`      | Sustained reasoning, judgment calls, ambiguous requirements, central design, ADRs, security-adjacent changes, error taxonomy, complex algorithms, large refactors, spikes, tool descriptions |
| `tier::standard`  | Well-specified execution, CRUD, mapping layers, handler patterns following an established template, validation gates, mechanical tests, infra/CI scripts, docs, small bug fixes             |

When in doubt, label `tier::deep` — over-promoting is cheap (slightly more compute); under-promoting produces lower-quality work on hard problems. Re-label freely as you learn what's actually hard.

A healthy backlog typically lands around **1:2 deep:standard**. If the ratio skews far from that, recheck — you may be over- or under-promoting one tier.

### Milestones

Group issues by deliverable outcome, not by team or component. Each milestone answers: _"What can the system or user do when this is done?"_

- Name after outcomes: `User Authentication`, `Payment Integration`, `Public API v1`
- Set a due date only if one appears in the design — never invent one
- Prefer milestones that can ship independently

```bash
glab api "projects/:id/milestones" --method POST \
  -f title="User Authentication" \
  -f description="Password login, OAuth2, session management"
```

### Iterations (optional)

GitLab's Iterations feature (group-level) provides sprint planning — a fixed cadence calendar with start/end dates. If the team works in iterations, configure an iteration cadence at the group level in the UI; individual issues are then assigned to the current or upcoming iteration.

Iterations are not required. For single-developer or kanban-flow projects, milestones + `workflow::up-next` ordering is enough.

### Repository settings

Configure these once per project before creating any issues or MRs:

```bash
# Enable "Delete source branch after merge" as the default for new MRs
glab api "projects/:id" --method PUT \
  -f remove_source_branch_after_merge=true

# Optional but recommended for scoped-label enforcement
glab api "projects/:id" --method PUT \
  -f enforce_scoped_labels=true
```

Verify with `glab api "projects/:id" | jq '.remove_source_branch_after_merge'`.

### Issue board views

GitLab issue boards are a view over labels — no field creation required. Create one board per team or per scope:

1. In the project UI, go to **Issues → Boards → Create new board**
2. Set scope filters (milestone, assignee, labels) as needed
3. Add columns by clicking **+** and choosing `workflow::backlog`, `workflow::up-next`, `workflow::in-progress`, `workflow::in-review`, `workflow::on-hold`, `workflow::done` in that order

The board automatically renders issues grouped by their workflow scope. Dragging a card across columns flips the scoped label.

### Issue Templates

`glab issue create` accepts `--template <name>` which reads from `.gitlab/issue_templates/<name>.md`. Generate these files during setup so the team gets consistent structure.

**`.gitlab/issue_templates/feature.md`:**

```markdown
<!-- Set on creation: label "feature" -->

## Context

Why this work exists and what it enables. Link to the design doc section if one exists.

## Acceptance Criteria

- [ ] Observable, testable outcome — not an implementation step
- [ ] One criterion per line

## Technical Notes

Relevant files, patterns to follow, constraints, prior art. Omit if genuinely empty.

## Dependencies

- Blocked by: #N
- Blocks: #N

/label ~feature ~"workflow::backlog"
```

**`.gitlab/issue_templates/bug.md`:**

```markdown
<!-- Set on creation: label "bug" -->

## Description

What went wrong? What were you expecting instead?

## Steps to Reproduce

1. 
2. 
3. 

## Expected Behavior

## Actual Behavior

## Environment

OS, version, browser, runtime, etc.

## Technical Notes

Relevant files, logs, stack traces.

/label ~bug ~"workflow::backlog"
```

**`.gitlab/issue_templates/spike.md`:**

```markdown
<!-- Set on creation: label "spike" -->

## Question to Answer

One specific decision this spike produces — not a general investigation.

## Time Box

e.g. 2 days

## Output Artifact

What will be produced when this spike is done? ADR, design doc update, written recommendation.

## Options Under Consideration

What alternatives are being evaluated?

## Known Constraints

Constraints that will shape the decision.

/label ~spike ~"workflow::backlog"
```

The `/label` quick actions at the bottom fire automatically when the template is applied.

**Merge request template** — put at `.gitlab/merge_request_templates/default.md`:

```markdown
## Summary

- 

Closes #

## Breaking change?

- [ ] No
- [ ] Yes — see migration notes below

## Test plan

- [ ] Unit / integration / e2e as applicable, all green locally
- [ ] Self-reviewed via /review-mr
- [ ] No new dependencies (or new dep justified above)
```

---

## Issue Decomposition

### What becomes an issue

| Create an issue                                       | Do not create an issue                            |
| ----------------------------------------------------- | ------------------------------------------------- |
| A discrete, implementable unit of work                | A vague goal ("improve performance")              |
| Completable and reviewable in ≤ 5 days                | A milestone or epic (make it a milestone instead) |
| Produces a reviewable diff                            | A one-time local setup step                       |
| A spike with a time-box and a defined decision output | An architecture decision (write an ADR instead)   |
| A bug with reproduction steps                         | A question or discussion thread                   |

### Issue quality standard

Issue type belongs on the label, not in the title. Titles should be clean, verb-first imperatives — readable in notifications, MR close references, and the issue list without prefix noise.

**Title:** `Verb-first imperative — specific enough to scan`

| Good ✓                                                            | Bad ✗                       |
| ----------------------------------------------------------------- | --------------------------- |
| `Add JWT refresh token rotation` (label: `feature`)               | `Auth improvements`         |
| `Evaluate Redis vs Postgres for session storage` (label: `spike`) | `Look into session options` |
| `Fix race condition in order status update` (label: `bug`)        | `[bug] Order bug`           |

**Body template** — used with `--description-file` for CLI creation:

```markdown
## Context

Why this work exists and what it enables — one short paragraph.
Link to the relevant design doc section if one exists.

## Acceptance Criteria

- [ ] Observable, testable outcome — not an implementation step
- [ ] One criterion per line

## Technical Notes

Relevant files, patterns to follow, constraints, prior art. Omit if genuinely empty.

## Dependencies

- Blocked by: #N
- Blocks: #N
```

### Epic / parent issues

For feature areas too large for a single issue, use GitLab Epics (group-level, if on Premium/Ultimate) or create a parent issue with a task list. GitLab tracks task completion on checkbox lists; checking off items updates the parent's progress bar.

```markdown
Title: User Authentication (labels: epic, auth)

## Scope

What this epic delivers — one paragraph.

## Tasks

- [ ] Evaluate session storage options (#12)
- [ ] Implement password login (#13)
- [ ] Add OAuth2 via Google (#14)
- [ ] Build JWT refresh token rotation (#15)
- [ ] Write auth integration tests (#16)
```

---

## Sequencing and Dependencies

After drafting all issues:

1. **Map dependencies** — which issues must complete before others can start
2. **Identify the critical path** — the longest dependency chain; this is the schedule floor
3. **Promote blockers** — anything blocking ≥ 3 other issues gets `priority::p0-critical` and goes first
4. **Flag parallelizable work** — issues with no dependencies are the fastest path to early velocity

Represent dependencies in issue bodies with `Blocked by: #N`. GitLab's built-in "Linked items" feature on Premium/Ultimate provides a structured alternative; the text marker keeps it portable to Free tier.

---

## Plan Before Creating

Before writing anything to the tracker, produce a review table:

| #   | Title                                          | Labels                                                    | Tier            | Milestone           | Priority                 | Size       | Blocked by |
| --- | ---------------------------------------------- | --------------------------------------------------------- | --------------- | ------------------- | ------------------------ | ---------- | ---------- |
| 1   | Evaluate Redis vs Postgres for session storage | spike, auth                                               | tier::deep      | User Authentication | priority::p0-critical    | size::s    | —          |
| 2   | Add JWT refresh token rotation                 | feature, auth                                             | tier::standard  | User Authentication | priority::p1-high        | size::m    | #1         |
| 3   | Build session invalidation endpoint            | feature, auth                                             | tier::standard  | User Authentication | priority::p1-high        | size::s    | #1         |

> [!WARNING]
> Show this table and confirm before creating anything in the tracker. Tracker pollution (duplicate, stale, or malformed issues) is harder to clean up than it looks.

If running autonomously (no human in the loop), proceed after producing the table.

---

## Creation

```bash
# Labels — idempotent: running twice is safe, label creation fails silently if the label exists
create_label() {
  local name="$1" color="$2" desc="$3"
  glab label create --name "$name" --color "$color" ${desc:+--description "$desc"} 2>/dev/null || true
}

# Type
create_label "feature"  "#0075ca" "New functionality"
create_label "bug"      "#d73a4a" "Something isn't working"
create_label "spike"    "#e4e669" "Time-boxed research; output is a decision, not code"
create_label "chore"    "#bfd4f2" "Maintenance, tooling, deps"
create_label "infra"    "#c5def5" ""
create_label "docs"     "#d4e5f7" ""
create_label "epic"     "#7057ff" "Parent issue tracking a feature area"

# Priority (scoped)
create_label "priority::p0-critical" "#d73a4a" ""
create_label "priority::p1-high"     "#e99695" ""
create_label "priority::p2-medium"   "#f9d0c4" ""
create_label "priority::p3-low"      "#fef2c0" ""

# Size (scoped)
create_label "size::xs" "#d4c5f9" ""
create_label "size::s"  "#bfd4f2" ""
create_label "size::m"  "#a2eeef" ""
create_label "size::l"  "#e4e669" ""
create_label "size::xl" "#e99695" ""

# Workflow (scoped)
create_label "workflow::backlog"      "#cccccc" "Raw or untriaged"
create_label "workflow::up-next"      "#7057ff" "Triaged, next off the queue"
create_label "workflow::in-progress"  "#0052cc" "Actively being worked"
create_label "workflow::in-review"    "#fbca04" "MR open, awaiting merge"
create_label "workflow::on-hold"      "#e11d48" "Deferred or blocked"
create_label "workflow::done"         "#0e8a16" "Merged or declined"
create_label "workflow::needs-design" "#cccccc" "Approach unclear; ADR or spec needed"

# Tier (scoped)
create_label "tier::deep"     "#8B5CF6" "Reasoning-heavy — design, ADRs, ambiguous requirements"
create_label "tier::standard" "#06B6D4" "Well-specified execution"

# Domain labels — derive from the design
create_label "auth"    "#1f6feb" ""

# Milestone
glab api "projects/:id/milestones" --method POST \
  -f title="User Authentication" \
  -f state=active \
  -f description="Password login, OAuth2, session management"

# Issue — write body to a temp file to avoid shell quoting issues.
# Always include exactly one tier label per the heuristic above.
glab issue create \
  --title "Add JWT refresh token rotation" \
  --description-file issue-body.md \
  --label "feature,priority::p1-high,size::m,auth,tier::standard,workflow::backlog" \
  --milestone "User Authentication"
```

---

## Completion Checklist

- [ ] `remove_source_branch_after_merge=true` set on the project
- [ ] `enforce_scoped_labels=true` set on the project (keeps workflow/priority/size/tier single-valued)
- [ ] Canonical labels scaffolded (type + priority + size + workflow + tier + domain)
- [ ] Milestones created and named after outcomes, not components
- [ ] Issue board(s) created with workflow columns in canonical order
- [ ] Issue templates exist in `.gitlab/issue_templates/` (feature, bug, spike)
- [ ] Merge-request template exists at `.gitlab/merge_request_templates/default.md`
- [ ] Every issue has a body, type label, priority, size, **tier**, and milestone
- [ ] Every P0/P1 issue has at least two testable acceptance criteria
- [ ] Every spike has a time-box and a named output artifact
- [ ] Dependencies mapped; blockers carry `workflow::on-hold` (and will flip back to `up-next` when unblocked)
- [ ] Critical path identified (noted in milestone description or a pinned issue)
- [ ] `tier::deep` / `tier::standard` ratio is within 1:1 to 1:3 (sanity-check the split)
