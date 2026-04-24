# Skill Registry

Maps work types to the skill that handles them. Used by `/next` and `/ship-next` during execution. If a row lists a skill, use it — don't improvise a substitute.

| Work type                                              | Skill to apply                               |
| ------------------------------------------------------ | -------------------------------------------- |
| Requirements fuzzy or idea needs surfacing             | `/spec` — interview and write `SPEC.md`      |
| Architecture decision to record                        | `/adr`                                       |
| Feature from spec                                      | `/tasking` to sequence, then implement       |
| GitLab tracker initialization (labels, templates)      | `/tracker-init`                              |
| Project phase gate check or build workflow             | `/workflow`                                  |
| Any code written or changed                            | `/coding` throughout                         |
| Structural improvement (local, targeted, no ceremony)  | `/refactor`                                  |
| Structural improvement (GitLab-tracked, loopable)      | `/ship-refactor`                             |
| Refactor current working changes                       | `/refactor-changes`                          |
| Merge request ready for review                         | `/review-mr`                                 |
| Staged changes ready to commit                         | `/commit`                                    |
| Unit tests                                             | `/unit-tests`                                |
| Integration tests                                      | `/integration-tests`                         |
| Bug (local investigation, no tracker ceremony)         | `/debug`                                     |
| Bug (GitLab-tracked, loopable fix cycle)               | `/ship-debug`                                |
| Security audit                                         | `/security-audit`                            |
| Observability gaps                                     | `/observability`                             |
| Release preparation or CHANGELOG update                | `/release-notes`                             |
| CI/CD setup or audit (GitLab CI)                       | `/ci`                                        |
| Backlog grooming (full audit of open issues)           | `/groom`                                     |
| Autonomous next-issue selection (no tracker)           | `/next`                                      |
| Autonomous next-issue selection (GitLab backlog)       | `/ship-next`                                 |
| Architecture design or evaluation                      | `/systems-design`                            |
| API design (REST/contract-first)                       | `/api-design`                                |
| Database schema, migrations, query patterns            | `/database`                                  |
| Blameless incident postmortem                          | `/postmortem`                                |
| Performance optimization                               | `/performance`                               |
| Aggressive restructure (no legacy deference)           | `/overhaul`                                  |
| Feature audit (gaps and bloat)                         | `/feature-review`                            |
| Developer onboarding documentation                     | `/onboarding`                                |
| Dependency updates                                     | `/dependency-update`                         |
| Documentation refactor                                 | `/refactor-docs`                             |
| Build or improve an agentic system                     | `/agent-systems`                             |
| Audit agent/MCP wiring + app agent patterns            | `/agent-audit`                               |
| Apple platform UI audit (HIG)                          | `/apple-hig`                                 |
| Scaffold a new skill in this library                   | `/new-skill`                                 |

## Skill pairs (local vs GitLab-wired)

Most work types have two skills: a **local** variant (no tracker ceremony, good for targeted or exploratory use) and a **GitLab-wired** `ship-*` variant (issue → branch → MR → merge → loop).

| Local               | GitLab-wired         | Use case                   |
| ------------------- | -------------------- | -------------------------- |
| `/next`             | `/ship-next`         | Autonomous project work    |
| `/refactor`         | `/ship-refactor`     | Structural improvement     |
| `/debug`            | `/ship-debug`        | Bug discovery and fix      |

## Dependency chain

```
/spec → /tasking → /tracker-init → /ship-next ─────────────────→ /release-notes
                                  │
                     ┌────────────┤
                     │            │
              /ship-refactor  /ship-debug   (parallel quality loops)
                     │
              /coding (always-on) ─────────────────────────────┐
              /refactor-changes  (pre-commit quality gate)      │
              /review-mr         (pre-merge review)             │
              /commit            (final record)  ───────────────┘
```
