---
name: workflow
description: 6-phase gate-based build workflow — design, review, tasking, tracker setup, implementation, release
compatibility: opencode
---

Follow this workflow for all software projects. Phases are sequential and gated — do not begin a phase until the previous one is complete. State which phase you are in at the start of each session.

If joining a project already in progress, determine the current phase before doing anything else: check what design docs exist, what issues exist, and what has been implemented.

> [!NOTE]
> **This skill vs `/next`:** `/workflow` governs the meta-process — which phase you're in, what the gates are, and whether a phase is complete. `/next` is the execution engine _within_ a phase — it reads the codebase, picks the highest-value slice, and does the work. Use `/workflow` as a standing instruction in `AGENTS.md`; invoke `/next` when you want autonomous execution within the current phase.

> [!NOTE]
> **When NOT to use:** Don't use for small, single-concern changes that don't need a gate-based approach. Don't use when spec and tasking phases are already complete — jump to the current phase directly.

> [!IMPORTANT]
> **Tier:** Deep. Workflow governs the planning and gate-judgment layer — which phase to be in, whether a gate is satisfied, what decisions need ADRs. The quality of those calls shapes everything downstream. A standard tier handles individual execution phases well; the meta-level coordination warrants the deeper tier.

---

## Phase 1 — Design

Produce a written spec, architectural documentation, and ADRs for all significant decisions.

| Skill      | Use when                                            |
| ---------- | --------------------------------------------------- |
| `/spec`    | Interviewing to surface requirements and edge cases |
| `/adr`     | Recording any decision with real alternatives       |

**Done means:**

- `SPEC.md` exists with no TBDs remaining
- Every significant architectural decision has an ADR
- All open questions are resolved or explicitly deferred to a named future version — not left open

---

## Phase 2 — Design Review

Actively critique and refine the design before committing to a backlog. The goal: the design should be the _right_ solution, not just _a_ solution. A design that has not been critiqued is an untested assumption.

**Done means:**

- The design has been actively critiqued, not just read
- No unnecessary complexity — every design decision earns its place
- No missing pieces that would surface as surprises during implementation
- Docs are clear enough that a developer could implement from them without asking questions
- You would be proud to show this design to a senior engineer

---

## Phase 3 — Tasking

Decompose the design into atomic, sequenced issues. No implementation begins without a complete backlog.

| Skill      | Use when                                    |
| ---------- | ------------------------------------------- |
| `/tasking` | Decomposing the design into sequenced tasks |

**Done means:**

- Every piece of v1.0 work is represented as a task or issue
- Every task has acceptance criteria and a size estimate
- Dependencies between tasks are identified
- No vague titles, no missing bodies, no orphaned tasks

---

## Phase 4 — Tracker Setup

Build the project board so it is a complete, navigable representation of the plan. The board should tell the project's story at a glance.

| Skill           | Use when                                                     |
| --------------- | ------------------------------------------------------------ |
| `/tracker-init` | GitLab Issues — labels, scoped labels, milestones, templates |

**Done means:**

- Labels (canonical taxonomy + domain labels) are configured
- Scoped labels drive board columns (workflow, priority, size, tier)
- Milestones created and named after outcomes, not components
- All issues live under a milestone and carry the minimum label set
- Critical path is identified

---

## Phase 5 — Implementation

Build slice by slice. Each slice is a vertical cut through the system — shippable, tested, and reviewed before the next begins. No horizontal layers.

| Skill                | Use when                                                                                                      |
| -------------------- | ------------------------------------------------------------------------------------------------------------- |
| `/coding`            | Throughout — all code written or changed                                                                      |
| `/ship-next`         | Autonomous slice selection and execution (GitLab-wired: branch → MR → merge → close → label flip)             |
| `/ship-refactor`     | Autonomous refactoring loop alongside feature work (GitLab-wired: scan → issue → branch → MR → merge)         |
| `/unit-tests`        | Alongside each slice                                                                                          |
| `/integration-tests` | After slices that cross system or service boundaries                                                          |
| `/observability`     | When a slice introduces a new critical path or external call                                                  |
| `/review-mr`         | Before closing any issue                                                                                      |
| `/debug`             | When a bug blocks a slice and root cause is unclear                                                           |
| `/ship-debug`        | Autonomous bug fix loop when root cause is known (GitLab-wired: reproduce → failing test → fix → MR → merge)  |
| `/security-audit`    | For any slice touching auth, payments, or user input                                                          |
| `/adr`               | When implementation decisions diverge from the spec                                                           |
| `/groom`             | Periodically — keep the board accurate as work progresses                                                     |

**Done means (per slice):**

- Implementation matches the acceptance criteria
- Tests written and passing
- MR reviewed and merged
- Issue closed and workflow scope flipped to `done`

**Done means (phase complete):**

- All v1.0 issues closed
- Milestone marked complete
- No known regressions
- Board fully reflects reality (run `/groom` before declaring done)

---

## Phase 6 — Release

Ship v1.0. Done should be visible, not implicit.

| Skill            | Use when                               |
| ---------------- | -------------------------------------- |
| `/release-notes` | Generating CHANGELOG and release notes |

**Done means:**

- Version tagged in git
- CHANGELOG updated
- GitLab Release published against the tag
- All issues closed; board fully in `workflow::done`
- No open `workflow::in-progress` labels remaining

---

## Rules

1. **No phase-skipping.** Do not begin Phase N+1 while Phase N has open items. If asked to skip, flag the gate rather than comply silently.
2. **No silent "good enough."** If a gate criterion is not met, say so explicitly. Do not paper over incomplete work.
3. **State the current phase** at the start of each session and again after completing a gate.
4. **Platform:** Use GitLab Issues + scoped labels + Milestones, established in Phase 4. Don't switch platforms mid-project.
5. **Design review is not optional.** It is its own phase for a reason — skip it and the backlog becomes a commitment to the wrong design.
6. **Slices, not layers.** Each implementation increment must be end-to-end shippable. Do not build the full data layer before the API layer before the UI. Build one complete slice at a time.
