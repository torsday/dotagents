---
name: agent-audit
description: Audit this project's agent wiring — which tools/MCPs the agent harness should have, and whether the application code should add, refactor, or remove its own agent patterns
compatibility: opencode
---

Looking at the project's codebase, workflows, and agent harness configuration — produce evidence-based recommendations across two dimensions: which tools or MCP servers the agent should have to work on this project, and whether the application code itself should add, refactor, or remove agent patterns.

> [!NOTE]
> **This skill vs `/agent-systems`:** `/agent-systems` is for building or improving an agentic system you're already committed to. This skill asks the prior question: _should_ agent patterns exist here, and if so, which ones — both in the application code and in the harness's own tooling.

> [!NOTE]
> **When NOT to use:** Don't use to manufacture recommendations — if the current wiring is well-matched to the project, say so. Don't use to force a specific framework choice; this audit is framework-neutral.

---

## Discovery

Read in this order. Stop when you have a confident picture of both what the project does and how it currently uses (or doesn't use) LLMs.

1. **Agent harness config** — `.opencode/`, `opencode.json`, `.claude/settings.json`, `.mcp.json`, `.agents/`; list every skill, tool, and MCP server, its permissions, and scope
2. **Custom project-level skills / commands** — `.opencode/skills/`, `.claude/commands/`, `.agents/skills/`; what project-specific automation already exists
3. **LLM usage in the codebase** — search for API clients and SDK imports (`openai`, `anthropic`, `langchain`, `langgraph`, `crewai`, `llm`, `agent`, `tool`); find every place the application calls an LLM
4. **Agent frameworks in use** — LangGraph, AutoGen, CrewAI, Semantic Kernel, raw SDK tool-use loops, custom orchestrators; identify which (if any) are already present
5. **Tech stack and external services** — package manifest, CI config, `docker-compose.yml`; what external services and databases does the project depend on?
6. **`AGENTS.md` / `CLAUDE.md` / README** — team conventions, deployment environment, integrations

Cross-reference throughout: code that makes sequential LLM calls with hardcoded steps may need an agent; code that already has an agent loop with no clear termination condition may need to be simplified.

---

## Part 1 — Harness Configuration (Tools & MCP Servers)

### Evaluate what's already configured

| Question                                                  | Signal                                                  |
| --------------------------------------------------------- | ------------------------------------------------------- |
| Does the project use the service this tool connects to?   | Not found anywhere → prune                              |
| Does it duplicate a native harness capability?            | Redundant → prune                                       |
| Does it duplicate another configured tool?                | Overlap → prune the weaker one                          |
| Is it scoped to least privilege?                          | Root filesystem or admin credentials → configure better |
| Is the server actively maintained?                        | No activity in 6+ months → flag as risk                 |

### A tool or MCP earns its place if it:

- Eliminates context-switching to a service the agent currently can't reach
- Gives the agent access to live data it needs to reason correctly — issues, errors, DB state, deployed config
- Automates a workflow that appears repeatedly in the git history or team runbooks
- Covers an external service the project already depends on in production

### Recommendation tables

Produce only the tables that have entries. Don't pad with speculative suggestions.

**Add**

| Priority | Tool / MCP                  | Rationale                                               | Evidence                            |
| -------- | --------------------------- | ------------------------------------------------------- | ----------------------------------- |
| High     | `server-gitlab` MCP         | Project uses GitLab Issues but the agent can't read them | Remote URL; MR references in git log |

**Prune**

| Priority | Tool / MCP         | Reason                                       | Risk if kept                    |
| -------- | ------------------ | -------------------------------------------- | ------------------------------- |
| High     | `mcp-server-slack` | No Slack integration in codebase or config   | Unnecessary credential exposure |

**Configure Better**

| Tool / MCP   | Current issue | Recommended change                                                     |
| ------------ | ------------- | ---------------------------------------------------------------------- |
| `filesystem` | Scoped to `/` | Restrict to project root; read-only unless write is genuinely required |

**Custom skills / commands to add**

| Skill      | Purpose                  | Replaces what manual work                |
| ---------- | ------------------------ | ---------------------------------------- |
| `/deploy`  | Run deployment checklist | Team does this 3× per week via a runbook |

### MCP ecosystem reference

The ecosystem evolves quickly — verify availability and maintenance status before recommending. Authoritative registry: [modelcontextprotocol.io](https://modelcontextprotocol.io).

| Category             | Common servers                                                        |
| -------------------- | --------------------------------------------------------------------- |
| **Source control**   | `server-github`, `server-gitlab`                                      |
| **Issue tracking**   | `server-linear`, `server-jira`                                        |
| **Error monitoring** | `server-sentry`                                                       |
| **Databases**        | `server-postgres`, `server-sqlite`, `server-redis`, `server-bigquery` |
| **Infrastructure**   | `server-kubernetes`, `server-aws`, `server-cloudflare`                |
| **Communication**    | `server-slack`, `server-notion`, `server-google-drive`                |
| **Web**              | `server-brave-search`, `server-fetch`, `server-puppeteer`             |

---

## Part 2 — Application Agent Architecture

This section applies whether or not the codebase currently uses agents. It asks: given what this application does, is the agent architecture right-sized?

### When agents are the right tool

An agent pattern earns its place in application code when:

| Condition                                                           | Why it calls for an agent                                     |
| ------------------------------------------------------------------- | ------------------------------------------------------------- |
| The number of steps is not known in advance                         | A fixed pipeline can't handle dynamic depth                   |
| The task requires choosing tools based on intermediate results      | Static sequencing can't adapt to what was learned             |
| The task benefits from iteration — try, evaluate, retry             | A single pass isn't enough; the model needs to course-correct |
| Multiple specialized capabilities need to be composed dynamically   | Routing to different tools based on content type or context   |
| The workflow requires external data before the next step is decided | Branching on retrieved or computed information                |

### When agents are not the right tool

| Condition                                                              | Simpler alternative                                    |
| ---------------------------------------------------------------------- | ------------------------------------------------------ |
| A single well-crafted prompt handles the task reliably                 | Prompt engineering, not an agent                       |
| The workflow is fixed and deterministic                                | A pipeline or chain — no dynamic tool selection needed |
| Latency or cost budget is tight and the task doesn't require iteration | Single-shot call; optimize the prompt                  |
| The output needs to be predictable and auditable                       | Avoid the non-determinism of agent loops               |
| The "agent" just calls one tool and stops                              | Not an agent — it's a function with an LLM in it       |

### Evaluate existing agent code

For each agent pattern found in the codebase:

| Question                                                                | Problem signal                                                       |
| ----------------------------------------------------------------------- | -------------------------------------------------------------------- |
| Is the termination condition explicit?                                  | Unbounded loops are bugs waiting to happen                           |
| Are tools atomic and composable?                                        | Monolithic tools that do too much are brittle and hard to test       |
| Is every tool call logged with its input, output, and decision context? | Silent agents are undebuggable                                       |
| Are errors in tool execution handled gracefully?                        | Unhandled tool failures crash the agent silently                     |
| Is the agent observable — can you see what it decided and why?          | No → it's a black box; add structured logging per `/observability`   |
| Does the agent have idempotent tool calls?                              | Non-idempotent tools + retry = double-writes                         |
| Is there a human escalation path when the agent is stuck?               | Infinite retry loops have no circuit breaker                         |

### Recommendation tables

**Add agent capability**

| Location                  | What to add                                      | Why it earns the complexity                                                                             |
| ------------------------- | ------------------------------------------------ | ------------------------------------------------------------------------------------------------------- |
| `src/reports/generate.ts` | Tool-use loop for fetching and synthesizing data | Currently makes 4 sequential hardcoded API calls; dynamic retrieval would handle variable report shapes |

**Simplify or remove**

| Location            | Current pattern   | Recommended change                   | Why                                                                |
| ------------------- | ----------------- | ------------------------------------ | ------------------------------------------------------------------ |
| `lib/summarizer.py` | 5-step agent loop | Single prompt with structured output | Every step is deterministic; the loop adds latency with no benefit |

**Refactor existing agent**

| Location                 | Issue                                          | Fix                                                   |
| ------------------------ | ---------------------------------------------- | ----------------------------------------------------- |
| `agents/orchestrator.js` | No termination limit; tools are not idempotent | Add max-iteration guard; make each tool safe to retry |

### Framework guidance

If the codebase has no agent framework and one is warranted:

| Choose                | When                                                                                      |
| --------------------- | ----------------------------------------------------------------------------------------- |
| **Raw SDK tool-use**  | Simple single-agent with ≤ 5 tools; keep it transparent                                   |
| **LangGraph**         | Multi-step stateful workflows; graph-based control flow needed                            |
| **AutoGen / CrewAI**  | Multi-agent collaboration; different roles / specializations                              |
| **MCP (server-side)** | You want your application's capabilities exposed as tools to external agents or harnesses |
| **No framework**      | A well-prompted single call does the job — don't add framework for its own sake           |

---

## Security Principles

These apply to both harness configuration and application agent code:

- **Read-only by default** — grant write access only when the workflow genuinely requires it
- **Scope to project** — filesystem and database access must be scoped to what the task actually needs
- **Credentials via env vars** — no tokens hardcoded in config files or agent tool definitions
- **Least-privilege tools** — a tool that searches issues should not also be able to close them
- **Remove what isn't used** — idle tools and dormant agent code with broad permissions are pure attack surface

> [!WARNING]
> An agent with write access to a production database, deployment system, or messaging platform is a high-trust capability. The agent — or the application — will use it when it seems appropriate. Make sure the team has explicitly decided that's acceptable, not just assumed it.

---

## Summary

Close with one paragraph: the current state in one sentence, the two or three highest-value changes, and what they unblock. If both the harness config and the application agent architecture are already well-matched to the project, say so — don't manufacture recommendations.

---

## Stopping condition

When running in a loop, stop scheduling further invocations when: all configured tools are used and scoped to least privilege, no missing tools are warranted by evidence, application agent code (if any) has explicit termination, idempotent tools, observability, and escalation paths.

Emit this exact phrase so a loop runner recognizes it:

> **Loop exit:** Agent wiring clean — no warranted additions, prunes, or refactors. Stopping.
