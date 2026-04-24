---
name: next
description: Autonomous project prioritization — read broadly, decide what most needs doing, do it
compatibility: opencode
---

Looking at the project — read broadly, decide what most needs doing, and do it. No direction needed. Apply engineering judgment.

> [!TIP]
> If the repo lives on GitLab with Issues as the backlog, use `/ship-next` instead — same prioritization, plus a wired branch → commit → MR → merge → close → flip-dependents loop.

> [!NOTE]
> **When NOT to use:** Don't use when the repo has a GitLab Issues backlog — use `/ship-next` instead. Don't use when you have explicit direction on what to work on next; this is for undirected autonomous work.

> [!TIP]
> **Tier:** Standard tier is sufficient for routine backlog work in a well-understood codebase — prioritization is clear and the right next thing is obvious. Switch to a deeper tier when priorities are genuinely ambiguous, the codebase is large and unfamiliar, or multiple competing concerns have real trade-offs. When in doubt, start standard; if the Decision step feels hard, that's the signal to switch.

---

## Discovery

> [!TIP]
> The discovery phase reads many files. In a large codebase, delegate to a subagent so the main conversation stays clean: _"Use a subagent to investigate X."_ The subagent reads files in its own context window and reports back a summary — your main session stays uncluttered for execution.

Read in this order. Stop reading each source when you have a confident picture — don't read everything, read enough.

1. **`git log --oneline -20`** — where recent activity has been; high-churn files are instability signals
2. **`git diff HEAD~5..HEAD --stat`** — what's actively changing and what's been touched together
3. **Open tasks** — TODO files, issue lists, project boards, whatever tracker is in use
4. **Design docs and specs** — what's intended versus what currently exists
5. **README and documentation** — accuracy, completeness, obvious gaps
6. **Core implementation files** — entry points, domain logic, recently changed files
7. **Test files** — what's covered, what isn't, where critical paths have thin or no coverage
8. **In-code debt markers** — `grep -r "TODO\|FIXME\|HACK\|XXX" --include="*.{ts,js,go,py,rb}" .`

Cross-reference as you read. A TODO near a recently changed file with no tests is a different priority than the same TODO in stable, well-tested code.

---

## Prioritization

Pick the highest tier with a clear, actionable item. Within a tier, prefer: higher impact over lower, reversible over irreversible, unblocking over isolated.

### Tier 1 — Something is broken

The system is doing the wrong thing, right now.

- Reproducible bugs in production paths
- Security vulnerabilities: injection, auth bypass, secret exposure, unvalidated input at boundaries
- Data integrity risks: non-atomic mutations, missing transactions, partial-write states
- Tests that are broken or silently passing incorrect behavior

### Tier 2 — Something could fail silently

The system appears to work but has no safety net in a critical area.

- Critical paths with no test coverage — a bug here would go undetected
- Error handling missing at system boundaries (HTTP handlers, consumers, jobs)
- External calls without timeouts, retries, or graceful degradation
- Design or spec intentions clearly not yet implemented — the gap between what was designed and what exists

### Tier 3 — Something is getting worse

The system works today but has trajectory problems.

- High-churn code becoming increasingly brittle or hard to change
- Architecture that's actively impeding feature development (the wrong abstraction in the wrong place)
- Performance bottlenecks with measurable evidence — not intuition
- Feature gaps: things partially built that would be substantially more valuable if completed

### Tier 4 — Something could be better

Quality and sustainability improvements with no acute urgency.

- Clarity: naming, structure, comments, docblocks
- Documentation accuracy or completeness
- Test coverage on non-critical paths
- Dead code, duplication, unnecessary complexity
- Dependency hygiene

**If nothing rises above Tier 4:** that's a healthy codebase. Do Tier 4 work confidently — don't manufacture urgency.

**If the right approach to something is genuinely unclear:** don't guess. Flag it as a decision point in the report and move to the next item.

**Stopping condition** — when running in a loop, stop scheduling further invocations when Tier 1–3 are empty and Tier 4 items are all genuinely minor (cosmetic naming, trivial docs, no reliability or maintainability impact). A clean, stable codebase is a valid terminal state — don't manufacture work to keep the loop running.

Emit this exact phrase so a loop runner recognizes it:

> **Loop exit:** Codebase is in clean, stable shape — no Tier 1–3 work found, remaining Tier 4 items are cosmetic. Stopping.

---

## Decision

State the chosen action before executing:

> **Tier:** [1–4]
> **Action:** what will be done, in one sentence
> **Evidence:** what in the discovery phase pointed here
> **Effect:** what this fixes, prevents, or unblocks
> **Passed over:** the next 1–2 candidates and the one-line reason they ranked lower

---

## Execution

Execute fully. Apply the relevant standards — do not re-specify them, just follow them. Consult `registry.md` for the full work-type → skill mapping.

If the work is larger than one session, complete one coherent slice — leave the system in a better, runnable state. Do not leave half-migrated seams. Do not pause mid-execution for confirmation. If a genuine decision point changes scope, surface it in the report, not mid-stream.

---

## Report

**What was done:** one paragraph — the change, its intent, and why it was the right next thing.

**Queue:** the next 3 items from the prioritization scan, in order:

| #   | Tier | Action                                                           | Rationale                                               |
| --- | ---- | ---------------------------------------------------------------- | ------------------------------------------------------- |
| 1   | T2   | Add timeout to payment gateway client                            | Only external call without one; silent hang risk        |
| 2   | T3   | Extract OrderValidator from OrderController                      | Controller is 400 lines; half of it is validation logic |
| 3   | T4   | Update README quickstart — docker command changed in last deploy | New developers will hit this immediately                |

Run this skill again to execute the next item in the queue.
