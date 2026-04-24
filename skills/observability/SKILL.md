---
name: observability
description: Build observability — structured logging, RED/USE metrics, distributed tracing, alerting
compatibility: opencode
---

Looking at the codebase and infrastructure, build or improve the observability solution — structured logging, metrics, and distributed tracing — so the system's internal state is understandable from its external outputs. Observability is the foundation of reliability: you cannot maintain what you cannot see.

> [!NOTE]
> **When NOT to use:** Don't use as a substitute for fixing bugs that produce incorrect behavior — observability makes problems visible; it doesn't fix them. Don't instrument every function; instrument boundaries and critical paths only.

> [!TIP]
> **Effort:** M. A standard-tier model is sufficient for standard instrumentation patterns; reserve a deeper tier for complex distributed infrastructure with novel tracing or sampling requirements.

## Protocol

1. Read the existing instrumentation, infrastructure constraints, and deployment environment.
2. Identify gaps: what questions can't currently be answered from the system's outputs?
3. State the chosen stack and instrumentation plan, then implement — do not pause for confirmation.
4. Verify signals appear correctly before moving on.

---

## Stack Selection

Choose based on constraints. Default to OpenTelemetry instrumentation regardless of backend — it keeps instrumentation vendor-neutral.

### Full-featured (no significant resource constraints)

**LGTM stack** — Grafana's open-source suite:

- **Loki** — log aggregation (label-based, not full-text indexed; low storage overhead vs. Elasticsearch)
- **Grafana** — unified visualization for logs, metrics, and traces
- **Tempo** — distributed tracing backend
- **Mimir** or **Prometheus** — metrics (Mimir for scale/long retention; Prometheus for single-node)
- **Alloy** (formerly Grafana Agent) — unified collector for all three signal types

### Resource-constrained (low memory / low swap / small footprint)

- **VictoriaMetrics** — Prometheus-compatible, ~5× lower memory than Prometheus
- **Loki** (still lean, especially with filesystem storage and small label cardinality)
- **Tempo** or **Jaeger** with in-memory or local storage
- **Vector** — lightweight log/metric pipeline (replaces heavier agents like Logstash)
- **SQLite** — viable for single-node structured log storage in very small deployments

### Managed / commercial (when operational overhead matters more than cost)

- **Datadog**, **New Relic**, **Honeycomb** — full observability with minimal self-hosting
- **Grafana Cloud** — LGTM stack as a service
- **GitLab Observability** — integrated with your project if you're already on GitLab

---

## The Three Pillars

### Logs

Logs capture discrete events. Every log line must be structured (JSON) and answer: _what happened, in what context, and with what identifiers._

Required fields on every log entry:

```json
{
  "timestamp": "2025-03-24T14:32:01Z",
  "level": "error",
  "service": "order-service",
  "traceId": "abc123",
  "spanId": "def456",
  "message": "payment gateway timeout",
  "orderId": "ord_789",
  "durationMs": 3012
}
```

Standards:

- Use log levels correctly: `debug` (dev only), `info` (normal operation), `warn` (degraded but recoverable), `error` (action required)
- Include correlation/trace IDs on every line — essential for tracing a request across services
- Never log secrets, PII, or credentials
- Log at boundaries (incoming requests, outgoing calls, job starts/completions) — not inside every function
- Errors include context: what was being attempted, relevant IDs, why it failed

### Metrics

Metrics capture numeric measurements over time. Apply the **RED** method for services and **USE** method for resources.

**RED** (per service/endpoint):

- **Rate** — requests per second
- **Errors** — error rate (count and percentage)
- **Duration** — latency distribution (p50, p95, p99 — not just averages)

**USE** (per resource):

- **Utilization** — % of time the resource is busy
- **Saturation** — queue depth or backlog
- **Errors** — error events

Instrumentation standards:

- Use histograms for latency, not gauges (percentiles require histograms)
- Label cardinality matters — avoid high-cardinality labels (user IDs, order IDs) on metrics; those belong in traces/logs
- Expose a `/metrics` endpoint (Prometheus scrape format) or push via OTLP
- Name metrics consistently: `<service>_<noun>_<unit>` (e.g., `order_payment_duration_seconds`)

### Traces

Traces capture the path of a request across services. Use **OpenTelemetry** SDK — instrument once, export to any backend.

Standards:

- Instrument at service boundaries: HTTP handlers, DB calls, external API calls, queue producers/consumers
- Propagate trace context across service calls via standard headers (`traceparent`)
- Add meaningful span attributes: `db.statement`, `http.method`, `http.status_code`, relevant business IDs
- Mark spans as error when exceptions are caught
- Keep span names stable and low-cardinality (e.g., `POST /orders` not `POST /orders/ord_789`)

---

## Alerting

Alerts should be actionable. An alert that fires without a clear response is noise.

- **Alert on symptoms, not causes** — alert on high error rate or high latency, not on CPU usage (which may or may not matter)
- **SLO-based alerts** — define Service Level Objectives (e.g., p99 latency < 500ms, error rate < 0.1%); alert when burn rate threatens the SLO
- Every alert needs a runbook or clear description: what is broken, who owns it, what to check first
- Avoid alert fatigue — fewer, higher-signal alerts are better than comprehensive, noisy ones
- Use multi-window burn rate alerts for SLOs (fast burn + slow burn) to catch both spikes and slow degradations

---

## Dashboards

A dashboard should answer a specific question for a specific audience.

- **Service health dashboard** — RED metrics per endpoint; error rate and latency over time
- **Infrastructure dashboard** — USE metrics per host/container
- **Business dashboard** — domain-level signals (orders per minute, payment success rate)
- **Trace explorer** — link from a dashboard panel directly to example traces for that time window

Standards:

- Every panel has a title and a description explaining what it measures and why it matters
- Use consistent time ranges across panels in a dashboard
- Link logs, metrics, and traces together — a spike in errors should be one click from the relevant log lines and traces
- Dashboards are code — store in version control (Grafana JSON or Terraform)

---

## Goldilocks

Instrument enough to answer: _is the system healthy, where is it slow, and what happened when it broke?_ No more.

- Don't instrument every function — instrument boundaries and critical paths
- Don't create metrics for every possible label combination — high cardinality kills performance
- Don't alert on everything that could go wrong — alert on what requires a human response

---

## Stopping condition

When running in a loop, stop scheduling further invocations when the Goldilocks state is reached: structured logging at all boundaries, RED/USE metrics exposed, distributed tracing instrumented and propagating context, alerts defined on symptoms with runbooks, and dashboards cover service health, infrastructure, and business signals. No critical gaps remain.

Emit this exact phrase so a loop runner recognizes it:

> **Loop exit:** Observability stack complete — all three pillars instrumented, alerts configured, no critical gaps remain. Stopping.
