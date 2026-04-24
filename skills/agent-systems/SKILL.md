---
name: agent-systems
description: Build or improve agentic systems — tool design, memory, capability grants, reliability, observability
compatibility: opencode
---

Looking at the agent architecture, tool definitions, and runtime configuration — build or improve this agentic system for maximum agency, reliability, and observability. An agent is only as capable as its tools, only as reliable as its error handling, and only as trustworthy as its configurability.

> [!NOTE]
> **This skill vs `/agent-audit`:** This skill is for building or improving an agentic system you're committed to. `/agent-audit` is the prior question: _should_ agent patterns exist here at all, and which tools should the agent harness have?

> [!NOTE]
> **When NOT to use:** Don't use when a single prompt handles the task reliably — you don't need an agent. Don't use to add tools speculatively; every extra tool adds noise to the model's decision space.

## Protocol

1. Read existing tool definitions, orchestration logic, memory patterns, and config.
2. Identify gaps: tools that are too coarse or too fine-grained, missing tunables, opaque errors, missing observability, hardcoded behaviors that should be runtime-configurable.
3. State findings and intended improvements — then implement. Do not pause for confirmation.
4. Verify each tool works end-to-end before moving to the next.

---

## Tool Design

The tool description is the API for the model. A poorly described tool is a broken tool — the model can't use what it can't understand.

### Tool Descriptions

Every tool definition must answer:

- **What it does** — in plain language, one sentence
- **When to use it** — and crucially, when _not_ to (disambiguate from similar tools)
- **What it returns** — shape and meaning of the response, including error cases
- **Side effects** — does it mutate state? Is it safe to retry?

```json
{
  "name": "search_files",
  "description": "Search file contents using a regex pattern. Returns matching lines with file paths and line numbers. Use this to find code patterns, not to read a specific known file (use read_file for that). Safe to call multiple times — read-only.",
  "inputSchema": {
    "type": "object",
    "properties": {
      "pattern": {
        "type": "string",
        "description": "Regex pattern to search for"
      },
      "path": {
        "type": "string",
        "description": "Directory to search in. Defaults to current working directory."
      },
      "fileGlob": {
        "type": "string",
        "description": "Optional glob to filter files, e.g. '**/*.ts'"
      }
    },
    "required": ["pattern"]
  }
}
```

### Tool Shape Principles

- **Atomic** — one tool, one responsibility. A `read_and_summarize_file` tool is two tools poorly combined.
- **Composable** — tools should work together naturally. The output of one should be usable as input to another without transformation.
- **Idempotent by default** — read tools always; write tools where possible. Document when a tool is not idempotent.
- **Rich responses** — don't return only success/failure. Return the data the agent needs to decide what to do next:
  ```json
  // Instead of: { "success": true }
  // Return:
  {
    "written": true,
    "path": "/src/auth/service.ts",
    "linesChanged": 14,
    "warnings": ["File was previously empty — consider adding imports"]
  }
  ```
- **Actionable errors** — errors must tell the agent what to try next:
  ```json
  // Instead of: { "error": "Not found" }
  // Return:
  {
    "error": "file_not_found",
    "path": "/src/auth/servce.ts",
    "suggestion": "Did you mean /src/auth/service.ts? Run list_files to see available files."
  }
  ```

### Tool vs. Resource vs. Prompt

| Primitive    | Use for                                 | When the model needs to...                              |
| ------------ | --------------------------------------- | ------------------------------------------------------- |
| **Tool**     | Actions and queries with dynamic inputs | Execute something or fetch computed data                |
| **Resource** | Static or slowly-changing content       | Read a file, config, or reference document              |
| **Prompt**   | Reusable instruction templates          | Apply a consistent pattern (e.g., code review template) |

Don't expose everything as a tool. Resources don't consume tool call budget and are cheaper to expose for reference data.

---

## Hot Tunables

A well-designed agent system externalizes its behavioral policies so they can be changed at runtime without code deploys. Every hardcoded behavior is a future incident or a constraint on the agent's usefulness.

### Capability Grants

Control what the agent is permitted to do at runtime — not at deploy time:

```yaml
capabilities:
  filesystem:
    read: true
    write: true
    delete: false # off by default; enable explicitly per session
    allowed_paths:
      - /src
      - /tests
    denied_paths:
      - /src/secrets
      - .env
  network:
    outbound: true
    allowed_hosts:
      - api.github.com
      - registry.npmjs.org
    denied_hosts: []
  shell:
    enabled: false # highest risk; off unless explicitly granted
    allowed_commands: []
```

Think of capabilities like Unix permissions — the principle of least privilege, configurable per session or per agent instance.

### Per-Tool Policy

Each tool gets its own runtime policy, not just a global one:

```yaml
tool_policies:
  run_tests:
    timeout_ms: 120000
    max_calls_per_session: 10
    require_confirmation: false
    retry:
      max_attempts: 2
      backoff: exponential
  deploy:
    timeout_ms: 300000
    max_calls_per_session: 1
    require_confirmation: true # always ask before deploying
    retry:
      max_attempts: 1 # never auto-retry deploys
  web_search:
    timeout_ms: 10000
    max_calls_per_session: 20
    require_confirmation: false
    cache_ttl_seconds: 300 # cache results to avoid redundant calls
```

### Autonomy Level

Define how much agency the agent exercises without human input:

```yaml
autonomy:
  level: supervised # autonomous | supervised | confirmation_required | read_only

  # Per-category overrides:
  overrides:
    file_deletion: confirmation_required
    external_api_calls: supervised
    code_execution: supervised
    read_operations: autonomous

  # Escalate to human when:
  escalate_on:
    - tool_failure_count >= 3
    - consecutive_same_tool_calls >= 5 # likely stuck in a loop
    - confidence_below: 0.4 # agent expresses uncertainty
    - destructive_operation: true
```

### Context Window Strategy

Control how the agent manages its context as sessions grow:

```yaml
context:
  max_tokens: 180000
  strategy: sliding_window # sliding_window | summarize | truncate_oldest

  # What to preserve regardless of window pressure:
  pinned:
    - system_prompt
    - current_task_description
    - last_N_tool_results: 5

  # Summarization trigger:
  summarize_when: context_above_80_percent
  summary_target_tokens: 2000
```

### Dynamic System Prompt Injection

Compose the system prompt at runtime from versioned, swappable modules rather than a single monolithic string:

```yaml
system_prompt:
  base: prompts/base_agent.md
  modules:
    - prompts/coding_standards.md # inject when working in code
    - prompts/security_posture.md # inject when touching auth/payments
    - prompts/repo_context.md # generated at session start from repo state
  tone: concise # concise | detailed | step_by_step
```

This lets you tune agent behavior per task type without redeploying.

---

## Memory Architecture

### Working Memory (In-Context)

The agent's in-context state — fast, ephemeral, limited by token budget:

- Current task and subgoal
- Recent tool results (last N)
- Decisions made and their rationale
- Open questions or blockers

Keep working memory dense and relevant. Summarize or externalize anything the agent doesn't need right now.

### External Memory (Persistent)

For information that must survive beyond a context window:

| Pattern             | Use for                                         | Storage                   |
| ------------------- | ----------------------------------------------- | ------------------------- |
| **Key-value store** | Facts the agent should recall across sessions   | Redis, SQLite             |
| **Vector store**    | Semantic lookup of past decisions or documents  | pgvector, Chroma          |
| **Append-only log** | Audit trail of all tool calls and decisions     | Structured file, DB table |
| **Scratchpad file** | Long-running work the agent writes and re-reads | Filesystem                |

Expose memory as tools so the agent can decide what to store and retrieve:

```json
{ "name": "remember", "description": "Store a key fact for recall in this or future sessions." }
{ "name": "recall",   "description": "Retrieve a previously stored fact by key or semantic search." }
{ "name": "forget",   "description": "Delete a stored fact that is no longer accurate." }
```

---

## Reliability

### Circuit Breaker Per Tool

If a tool fails repeatedly, stop calling it — don't let a broken tool consume the entire context:

```yaml
circuit_breaker:
  failure_threshold: 3 # open after N consecutive failures
  timeout_seconds: 60 # try again after this window
  fallback: skip_and_continue # skip_and_continue | escalate | abort
```

### Idempotency Keys

For tools that create or mutate resources, accept an idempotency key so the agent can safely retry:

```json
{
  "name": "create_merge_request",
  "inputSchema": {
    "properties": {
      "idempotencyKey": {
        "type": "string",
        "description": "Stable key for this operation (e.g. branch name). Prevents duplicate MRs if called twice."
      }
    }
  }
}
```

### Loop Detection

Agents can get stuck calling the same tool repeatedly with no progress:

- Track tool call history within the session
- Alert or escalate when the same tool is called with identical inputs 3+ times
- Surface the stuck state to the agent explicitly: _"You have called `search_files` with pattern `TODO` four times. The results are unchanged. Consider a different approach."_

### Human Escalation

Define clear escalation paths — the agent should know when to ask rather than guess:

```yaml
escalation:
  triggers:
    - all_approaches_exhausted: true
    - consecutive_tool_failures: 3
    - confidence_below_threshold: true
    - destructive_action_required: true
  channel: inline_question # inline_question | async_notification | block_and_wait
  timeout_seconds: 300 # if no human response, take fallback action
  fallback: abort_with_summary
```

---

## Observability

Every agent action is a span. Every decision is a log entry. You cannot debug an agent you cannot see.

### Trace Every Tool Call

```json
{
  "traceId": "agent-session-abc123",
  "spanId": "tool-call-007",
  "tool": "run_tests",
  "inputs": { "path": "./src/auth" },
  "durationMs": 4231,
  "result": "success",
  "tokensConsumed": 842,
  "callNumber": 7,
  "sessionTotal": 12
}
```

### Log Decisions and Reasoning

At each decision point, emit a structured log:

```json
{
  "event": "agent.decision",
  "decision": "run_tests before committing",
  "reasoning": "Changed auth logic — tests must pass before any commit",
  "alternatives_considered": ["commit first", "skip tests"],
  "confidence": "high"
}
```

### Key Metrics to Track

| Metric                     | Why                                                                  |
| -------------------------- | -------------------------------------------------------------------- |
| Tool calls per session     | Detects runaway agents; informs tool budget tuning                   |
| Token consumption per task | Tracks cost; flags inefficient context usage                         |
| Tool error rate per tool   | Surfaces broken or poorly described tools                            |
| Human escalation rate      | Too high = agent lacks capability; too low = agent is over-confident |
| Task completion rate       | The only metric that ultimately matters                              |
| Time-to-first-tool-call    | Long delays may indicate poor task framing or context overload       |

---

## Goldilocks

An agent with too few capabilities is useless. An agent with too many is dangerous. Get the balance right:

- **Tools:** enough to complete the task class the agent is designed for — no more. Every extra tool adds noise to the model's decision space.
- **Autonomy:** default to supervised for anything destructive; autonomous for anything read-only.
- **Context:** carry enough to act without constant re-reading; summarize aggressively before the window fills.
- **Tunables:** every behavioral policy should be configurable — but defaults should be safe. A new agent instance should do the right thing without manual configuration.
