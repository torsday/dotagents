---
name: postmortem
description: Write a blameless postmortem after an incident — timeline, root cause analysis, action items that actually reduce future risk
compatibility: opencode
---

Looking at this incident — produce a blameless postmortem that makes the system harder to break next time.

> [!NOTE]
> **This skill vs `/debug`:** Use `/debug` while the incident is still active — it finds and fixes the root cause. Use this skill after the system is stable, to document what happened, understand why, and prevent recurrence. The typical sequence is `/debug` → `/postmortem`.

> [!NOTE]
> **When NOT to use:** Don't use while an incident is still active — stabilize first, then write. Don't use for minor bugs that didn't cause observable impact — they belong in a bug ticket, not a postmortem.

**Blame is not the goal. Understanding is.** Systems fail because of accumulated conditions, not because individuals are careless. The postmortem's job is to surface those conditions so they can be addressed systematically.

## Protocol

1. Gather the facts: timeline, signals observed, actions taken.
2. Identify contributing factors — there is almost never a single root cause.
3. Assess impact honestly — neither minimize nor dramatize.
4. Generate action items that actually reduce future risk.
5. Write for someone who wasn't present: full context, no assumed knowledge.

Do not write an apology. Write an engineering analysis.

---

## Format

```markdown
# Postmortem: <short title — what broke>

**Date:** YYYY-MM-DD
**Duration:** Xh Ym (detection to resolution)
**Severity:** P1 Critical | P2 Major | P3 Minor
**Status:** Draft | In Review | Resolved
**Author(s):** ...

---

## Summary

One paragraph. What broke, how long it lasted, what the impact was, what resolved it.

## Impact

| Dimension         | Detail                     |
| ----------------- | -------------------------- |
| Users affected    | N users (or N% of traffic) |
| Services affected | list                       |
| Data loss         | Yes/No — describe if yes   |
| SLA breach        | Yes/No                     |
| Revenue impact    | if applicable              |

## Timeline

| Time (UTC) | Event                                                 |
| ---------- | ----------------------------------------------------- |
| 14:03      | Alert: p99 latency on /orders exceeded 2000ms         |
| 14:07      | On-call acknowledged                                  |
| 14:22      | Identified connection pool exhaustion as likely cause |
| 14:31      | Rolled back deploy; latency recovered                 |
| 14:45      | Confirmed stable; incident closed                     |

Every action taken belongs here — including wrong turns. Completeness matters more than looking competent.

## Root Cause Analysis

### What happened

Technical explanation of the failure mechanism — precise enough that an engineer unfamiliar with the system can follow it.

### Contributing factors

Use the 5 Whys: trace each factor back until you reach something actionable.

- **Factor 1:** The deploy introduced a query that held transactions open longer than expected
  - Why? The query was not reviewed against the connection pool limits
  - Why? No load test covers connection pool saturation
- **Factor 2:** The alert threshold was set too high — the signal arrived 18 minutes after degradation began
- **Factor 3:** ...

No single factor is "the" root cause. List all of them.

### What prevented earlier detection

Why didn't tests, staging, or monitoring catch this before users were affected?

## What Went Well

- ...
- (Be honest — not every incident has a silver lining, and pretending otherwise undermines trust in the document)

## What Went Poorly

- ...

## Action Items

| Action                                                | Owner     | Due        | Priority |
| ----------------------------------------------------- | --------- | ---------- | -------- |
| Add alert for connection pool utilization > 80%       | @infra    | 2025-04-01 | High     |
| Add circuit breaker to DB client                      | @platform | 2025-04-15 | High     |
| Add connection pool saturation scenario to load tests | @platform | 2025-04-30 | Medium   |
| Document rollback procedure for schema migrations     | @platform | 2025-05-01 | Low      |
```

---

## Action Item Standards

An action item must be:

- **Specific** — "improve monitoring" is not an action item; "add alert for connection pool utilization > 80%" is
- **Owned** — named person or team, not "the team" or "someone"
- **Time-bound** — a due date, even if approximate
- **Proportional** — prioritize by how much each item reduces future risk, not by how easy it is

Fewer items that get done beat comprehensive lists that don't. Five good action items, all completed, is worth more than twenty that aren't.

---

## Standards

- **Blameless** — individuals are not causes. "An engineer made a mistake" is not an action item. "Our deploy process permits force-push to the default branch without approval" is.
- **Complete timeline** — include wrong turns and things that didn't help. The timeline is evidence, not PR.
- **Honest impact** — underreporting erodes trust in the postmortem process itself.
- **Shared** — circulate to relevant teams within a week of the incident. Learning should spread.
- **Followed through** — a postmortem whose action items are never completed is theater. Track them.
