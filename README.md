# Agents · Skills

A curated library of agent-agnostic **skills** — reusable, invocable prompts that teach any LLM coding agent how to do one specific software-engineering job well.

Each skill is a single `SKILL.md` that documents a recurring task: write an ADR, decompose a spec, audit a CI pipeline, ship a bug fix through the tracker. The agent reads the skill, follows the protocol, and applies the standards. No skill files are copy-pasted into prompts; they are discovered and invoked by the agent harness.

**Contract:** these skills follow the [OpenCode Agent Skills spec](https://opencode.ai/docs/skills) — specifically the **global agent-compatible** layout (`~/.agents/skills/<name>/SKILL.md`). That's the same location OpenCode, Claude Code, and any other skill-aware agent will discover.

---

## Why this repo exists

Coding agents need judgment, not just capability. A model that can write code will not always write the _right_ code — the kind that passes review, fits the surrounding architecture, ships behind a proper commit trail, and doesn't invent a new convention every sitting.

These skills encode that judgment once so every invocation reuses it:

- **Standards are prose, not prompts.** Each skill is written for a human engineer to read and an agent to apply. The same file documents the reasoning for you and constrains the behavior of the agent.
- **Skills compose.** A `/ship-next` run calls into `/coding` for every change, `/commit` for every commit, `/review-mr` on its own diff, and `/release-notes` when it's time to cut a version. You get a pipeline of well-specified behaviors out of one invocation.
- **Audit trail is free.** The GitLab-wired skills (`/ship-*`, `/groom`, `/tracker-init`) always leave a clean tracker — every change has an issue, every issue has a merge request, every merge request has a pipeline, every state change has a reason.

If you've ever wished an agent "would just work the way my team works," a skill library is how you encode that.

---

## What's inside

36 skills, organized by phase. Every skill includes a `When NOT to use` section; pay attention to it — skills are specific tools, not a default.

### Design & planning

| Skill                                                   | What it does                                                  | Comes before       |
| ------------------------------------------------------- | ------------------------------------------------------------- | ------------------ |
| [`/spec`](skills/spec/SKILL.md)                         | Interview the operator, then write `SPEC.md`                  | `/tasking`         |
| [`/systems-design`](skills/systems-design/SKILL.md)     | Explore architectural options — DDD, hexagonal, CQRS, etc.    | `/adr`             |
| [`/adr`](skills/adr/SKILL.md)                           | Record an architecture decision — context, options, tradeoffs | —                  |
| [`/tasking`](skills/tasking/SKILL.md)                   | Decompose a spec into sequenced, risk-flagged tasks           | `/tracker-init`    |
| [`/tracker-init`](skills/tracker-init/SKILL.md)         | Bootstrap GitLab labels, milestones, issue templates          | implementation     |
| [`/workflow`](skills/workflow/SKILL.md)                 | 6-phase gate model (design → review → tasking → tracker → build → release) | — |
| [`/feature-review`](skills/feature-review/SKILL.md)     | Evidence-based feature audit — what to add, what to remove    | any phase          |

### Implementation

| Skill                                                   | What it does                                                  | Notes                           |
| ------------------------------------------------------- | ------------------------------------------------------------- | ------------------------------- |
| [`/coding`](skills/coding/SKILL.md)                     | Always-on engineering standards                               | Foundation; referenced by others |
| [`/api-design`](skills/api-design/SKILL.md)             | REST/contract-first API design — versioning, errors, pagination | —                             |
| [`/database`](skills/database/SKILL.md)                 | Schema, indexes, migrations, query design                     | Expand-contract migrations       |
| [`/debug`](skills/debug/SKILL.md)                       | Investigate → document → prove with a failing test            | Local; when root cause is fuzzy |
| [`/ship-debug`](skills/ship-debug/SKILL.md)             | Discover → fix → ship (GitLab-wired loop)                     | Commits to the full fix cycle   |
| [`/observability`](skills/observability/SKILL.md)       | Structured logging, RED/USE metrics, traces, alerting         | OpenTelemetry-first             |
| [`/security-audit`](skills/security-audit/SKILL.md)     | Full-scope security review                                    | Use a deep-tier model           |
| [`/performance`](skills/performance/SKILL.md)           | Profile-driven optimization — algorithms, I/O, memory, caching | Measure first                  |
| [`/ci`](skills/ci/SKILL.md)                             | GitLab CI/CD audit and scaffold                               | —                               |

### Code quality

| Skill                                                       | What it does                                  | Scope                          |
| ----------------------------------------------------------- | --------------------------------------------- | ------------------------------ |
| [`/refactor`](skills/refactor/SKILL.md)                     | Structural improvement on any target          | Local, no commits              |
| [`/ship-refactor`](skills/ship-refactor/SKILL.md)           | Refactor loop (GitLab-wired)                  | Issue → branch → MR → merge    |
| [`/refactor-changes`](skills/refactor-changes/SKILL.md)     | Pre-commit quality gate                       | Current git diff + 1 hop       |
| [`/refactor-docs`](skills/refactor-docs/SKILL.md)           | Documentation refactor — clarity, accuracy    | Docs in `docs/` and inline     |
| [`/overhaul`](skills/overhaul/SKILL.md)                     | Aggressive restructure, no legacy deference   | Target design → migration      |
| [`/review-mr`](skills/review-mr/SKILL.md)                   | Review and report — no fixes                  | Diff under review              |
| [`/commit`](skills/commit/SKILL.md)                         | Atomic Conventional Commits                   | Final step before push         |
| [`/dependency-update`](skills/dependency-update/SKILL.md)   | Safe dependency updates, CVE-prioritized      | Manifest + lockfile            |

### Testing

| Skill                                                       | What it does                      | Use when               |
| ----------------------------------------------------------- | --------------------------------- | ---------------------- |
| [`/unit-tests`](skills/unit-tests/SKILL.md)                 | Goldilocks unit tests             | Logic correctness      |
| [`/integration-tests`](skills/integration-tests/SKILL.md)   | Contract and wiring tests         | Component boundaries   |

### Autonomous execution

| Skill                                                 | What it does                                              | Prerequisite                |
| ----------------------------------------------------- | --------------------------------------------------------- | --------------------------- |
| [`/next`](skills/next/SKILL.md)                       | Autonomous prioritization + execution (no tracker)        | Git log, TODOs, design docs |
| [`/ship-next`](skills/ship-next/SKILL.md)             | GitLab-wired loop: issue → branch → MR → merge → close    | GitLab Issues backlog       |
| [`/groom`](skills/groom/SKILL.md)                     | Backlog audit, drift repair, kanban reorder               | Existing tracker            |

### Release

| Skill                                                       | What it does                                |
| ----------------------------------------------------------- | ------------------------------------------- |
| [`/release-notes`](skills/release-notes/SKILL.md)           | CHANGELOG, release notes, migration guide   |

### Incident response

| Skill                                           | What it does                                                       |
| ----------------------------------------------- | ------------------------------------------------------------------ |
| [`/postmortem`](skills/postmortem/SKILL.md)     | Blameless postmortem — timeline, root cause, action items          |

### Developer experience

| Skill                                           | What it does                                                       |
| ----------------------------------------------- | ------------------------------------------------------------------ |
| [`/onboarding`](skills/onboarding/SKILL.md)     | Onboarding docs accurate enough for day-one productivity           |

### Platform-specific

| Skill                                           | What it does                                                       |
| ----------------------------------------------- | ------------------------------------------------------------------ |
| [`/apple-hig`](skills/apple-hig/SKILL.md)       | Audit UI against Apple Human Interface Guidelines (all platforms)  |

### Agent systems

| Skill                                                 | What it does                                                             |
| ----------------------------------------------------- | ------------------------------------------------------------------------ |
| [`/agent-systems`](skills/agent-systems/SKILL.md)     | Build or improve an agentic system — tools, memory, capabilities, observability |
| [`/agent-audit`](skills/agent-audit/SKILL.md)         | Audit agent/MCP wiring + application agent patterns                      |

### Meta

| Skill                                                 | What it does                                                      |
| ----------------------------------------------------- | ----------------------------------------------------------------- |
| [`/new-skill`](skills/new-skill/SKILL.md)             | Scaffold a new skill — frontmatter, body sections, registry entry |

---

## Shared utilities

Referenced by the `ship-*` and `/groom` skills. Not invoked directly.

| File                                                        | Used by                                               |
| ----------------------------------------------------------- | ----------------------------------------------------- |
| [`shared/project-discovery.md`](shared/project-discovery.md) | `/ship-next`, `/ship-refactor`, `/ship-debug`, `/groom` |
| [`shared/status-transition.md`](shared/status-transition.md) | `/ship-next`, `/ship-refactor`, `/ship-debug`, `/groom` |

---

## Design choices

### Skills follow the OpenCode contract

Every `SKILL.md` has YAML frontmatter with `name`, `description`, and `compatibility: opencode`. Bodies are Markdown. Skill names match `^[a-z0-9]+(-[a-z0-9]+)*$`. Descriptions are short and specific enough for an agent to decide whether to invoke.

Skills live under `skills/<name>/SKILL.md` and — when installed to `~/.agents/skills/` — are auto-discovered by any harness that respects the **global agent-compatible** path.

### GitLab-native, not GitLab-port

These skills were translated from a GitHub-wired library. The port isn't a `s/gh/glab/` pass; the workflow primitives are different enough that a mechanical translation would produce a worse tracker. Specifically:

- **GitHub Projects v2** uses single-select custom fields and requires GraphQL mutations with field IDs and option IDs to flip a status column. **GitLab issue boards** are a view over [scoped labels](https://docs.gitlab.com/ee/user/project/labels.html#scoped-labels) — a label like `workflow::in-progress` is both the state and the column signal, and the double-colon scope means GitLab enforces "at most one per scope" automatically. The entire status-transition helper collapses from a GraphQL mutation with four IDs to two label edits.
- **PR → MR.** The `/review-pr` skill became `/review-mr`; every `gh pr` call became `glab mr`; the `--delete-branch` flag became `--remove-source-branch` on the MR (or the project-level `remove_source_branch_after_merge` default).
- **`.github/workflows/` → `.gitlab-ci.yml`.** The `/ci` skill is a full GitLab CI/CD audit, not a GitHub Actions one. Different primitives (`rules:`, `needs:`, `interruptible:`, scoped `CI_JOB_TOKEN`), different pinning model (image digests, `include:` refs).
- **Issue templates** moved from `.github/ISSUE_TEMPLATE/*.yml` (form schema) to `.gitlab/issue_templates/*.md` (plain Markdown with `/label` quick actions).

The skills read naturally on GitLab — they don't feel like someone's first week on the platform.

### Capability tiers, not vendor model names

The original library used `model: opus` / `model: sonnet` labels to route work to the right capability tier. This repo uses **`tier::deep`** and **`tier::standard`** instead — same idea (reasoning-heavy vs well-specified-execution), no vendor lock. Substitute any model you want at each tier; the skill-level heuristic for _what kind of task needs which tier_ is the same.

### Every skill can exit a loop cleanly

Most skills include a **Stopping condition** section with an explicit exit phrase. Agent loop runners (OpenCode's `/loop`, Claude Code's `/loop`, or anything that polls a skill on a schedule) can detect completion and stop scheduling — a clean codebase, a clean pipeline, a clean backlog are valid terminal states. Skills should not manufacture work to stay alive.

### Deletion bias

Every skill treats _net-negative line count_ as a primary goal, not a side effect. `/refactor`, `/review-mr`, `/ship-*`, and `/ship-refactor` all include an explicit "Deletion sweep" step. A smaller codebase that does the same thing is always the better codebase.

---

## Installation

These skills are auto-discovered by any OpenCode-compatible agent when placed at `~/.agents/skills/` (the **global agent-compatible** path from the OpenCode spec).

```bash
# Clone to the global agent-compatible location
git clone https://github.com/torsday/dotagents.git ~/.agents
```

Per-project override — add skills that only apply to a specific repo:

```bash
# In the project root
mkdir -p .agents/skills/<name>
# Write .agents/skills/<name>/SKILL.md
```

The project path takes priority over the global path during discovery.

### Using with OpenCode

Skills are listed by the `skill` tool and invoked via `skill({ name: "<skill-name>" })`. See [OpenCode's skill configuration](https://opencode.ai/docs/skills) for permission rules (`opencode.json` → `permission.skill`).

### Using with Claude Code

Claude Code also reads `~/.agents/skills/` as an agent-compatible path. No configuration change needed — the skills appear as slash commands (`/refactor`, `/ship-next`, …) and in the skill discovery list.

### Using with other agents

Any agent harness that reads `SKILL.md` files with standard frontmatter will work. The body is plain Markdown; no runtime, no bundled scripts.

---

## Validation

Every skill in this library is checked against the OpenCode contract on every push. Run the validator locally before opening a PR:

```bash
./scripts/validate-skills.sh
```

It verifies:

- Every `SKILL.md` has valid frontmatter (`name` matches the directory and the kebab-case pattern, `description` is non-empty and ≤1024 chars, `compatibility: opencode` is set)
- Every markdown link to `skills/<name>/SKILL.md` or `shared/<name>.md` resolves to a real file
- Every bare `shared/<name>.md` prose reference resolves

No Node, Python, or other toolchain required — pure bash + awk + grep. GitHub Actions re-runs it automatically; see [`.github/workflows/validate.yml`](.github/workflows/validate.yml).

---

## How a typical session looks

**Fuzzy idea → shipped v1.0:**

```
/spec          # interview, write SPEC.md
/tasking       # decompose into sequenced tasks
/tracker-init  # bootstrap GitLab labels, milestones, templates
/ship-next     # autonomous loop: pick issue, branch, MR, merge, close, unblock next
/ship-next     # (again)
/release-notes # CHANGELOG + GitLab Release
```

**In-flight quality work, running in parallel:**

```
/ship-refactor   # one refactoring finding per invocation, tracker-audited
/ship-debug      # one bug, reproduced + proved + fixed per invocation
/groom           # periodically — repair drift, reorder Up Next
```

**Pre-commit, in a normal developer flow:**

```
/refactor-changes  # clean the current diff + one hop of linked files
/review-mr         # independent review pass on the same diff
/commit            # atomic Conventional Commits
```

---

## Contributing

See [`CONTRIBUTING.md`](CONTRIBUTING.md) for the full guide. In short:

- **Easiest path:** invoke [`/new-skill`](skills/new-skill/SKILL.md) — it scaffolds the file, fills in the contract, and updates the registry.
- **Manual path:** copy [`templates/SKILL-template.md`](templates/SKILL-template.md), fill it in, add a row to [`registry.md`](registry.md), note the change under `[Unreleased]` in [`CHANGELOG.md`](CHANGELOG.md), and run the validator before opening a PR.

Skills that get merged are:

- **Specific** — "audit the diff for N+1 queries" beats "make it faster"
- **Composable** — reference other skills (`/coding`, `/commit`) rather than duplicating their rules
- **Exitable** — loop-safe skills emit a clear `Loop exit: …` phrase when the checklist passes clean
- **Honest about tradeoffs** — surface design tension; don't paper over it

---

## License

[MIT](LICENSE). Reuse freely.

## Origin

This library is the platform-portable core of a larger, GitHub-wired skill set — GitLab-native where the original was GitHub-native, agent-agnostic where the original was harness-specific, and stripped of anything that would tie it to a single operator's setup. The engineering ideas — Goldilocks testing, net-deficit refactoring, verified status transitions, scoped-label drift repair — are all intact; only the vendor plumbing changed.

A notable irony: the library teaches GitLab workflows but the repo itself is hosted on GitHub. The skill content is platform-portable — a project on GitHub, GitLab, Gitea, or anywhere else can consume this library and invoke `/coding`, `/review-mr`, or `/spec` just fine. The `ship-*` skills are what's GitLab-native; use them where they fit, swap the CLI for the ones on your platform, or contribute a sibling skill targeting a different tracker.
