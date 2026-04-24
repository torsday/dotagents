---
name: api-design
description: Design or improve an API for correctness, consistency, and longevity — contract-first, with versioning, errors, pagination, and idempotency
compatibility: opencode
---

Looking at the API requirements and consumer needs — design or improve this API for correctness, consistency, and longevity.

**Design the contract first. Code is an implementation detail.**

> [!NOTE]
> **When NOT to use:** Don't use for internal function signatures — this is for APIs crossing a trust or deployment boundary (HTTP, RPC, event schemas). Don't use before you know who the consumers are and what they're trying to accomplish.

## Protocol

1. Understand who the consumers are and what they need to accomplish.
2. Design the API surface: resources, operations, request/response shapes, error cases.
3. Document the contract (OpenAPI spec or equivalent) before writing implementation code.
4. Implement — do not pause for confirmation.
5. Verify the implementation matches the spec.

---

## REST Naming & Structure

- Resources are **nouns**, not verbs: `/orders`, `/users/{id}` — not `/getUser` or `/processOrder`
- Use plural nouns for collections: `/orders`, `/products`
- Nest only for true ownership: `/users/{id}/orders` ✓ — not for loose associations
- Max 2 levels deep — deeper nesting is a coupling smell
- Actions that don't map cleanly to CRUD: use a sub-resource verb as a last resort: `POST /orders/{id}/cancel`

### HTTP Methods

| Method   | Use                             | Idempotent? | Safe? |
| -------- | ------------------------------- | ----------- | ----- |
| `GET`    | Read                            | ✓           | ✓     |
| `POST`   | Create or non-idempotent action | ✗           | ✗     |
| `PUT`    | Full replacement                | ✓           | ✗     |
| `PATCH`  | Partial update                  | ✗           | ✗     |
| `DELETE` | Remove                          | ✓           | ✗     |

### Status Codes

| Code  | When                                                                      |
| ----- | ------------------------------------------------------------------------- |
| `200` | Success with body                                                         |
| `201` | Resource created (include `Location` header pointing to the new resource) |
| `204` | Success, no body (DELETE, some PUT/PATCH)                                 |
| `400` | Malformed request                                                         |
| `401` | Not authenticated                                                         |
| `403` | Authenticated but not authorized                                          |
| `404` | Resource not found                                                        |
| `409` | Conflict — duplicate, precondition failed, state mismatch                 |
| `422` | Valid syntax but semantically invalid (failed business validation)        |
| `429` | Rate limited (include `Retry-After` header)                               |
| `500` | Server error — never leak internals                                       |

---

## Request & Response Design

**Consistency is more important than perfection.** Inconsistency across endpoints is the one design mistake that can never be fixed without breaking clients.

- Field names: `camelCase` or `snake_case` — pick one, never mix
- Wrap all collection responses in an envelope — a raw top-level array makes adding pagination later a breaking change:
  ```json
  { "data": [...], "pagination": { "cursor": "abc", "hasMore": true } }
  ```
- Timestamps: ISO 8601 (`2025-03-24T14:32:01Z`) — always UTC, always strings
- IDs: opaque strings, not sequential integers — safe to expose, portable, not enumerable

### Pagination

| Pattern          | When                                                            |
| ---------------- | --------------------------------------------------------------- |
| **Cursor-based** | Default — stable during pagination, scales to large datasets    |
| Offset/limit     | Acceptable only for small, stable datasets                      |
| Page number      | Avoid — results shift as items are added/removed mid-pagination |

---

## Error Responses

Every error returns the same envelope — clients should handle errors programmatically, not by string-matching messages:

```json
{
  "error": {
    "code": "validation_failed",
    "message": "Human-readable explanation safe for developer tooling",
    "details": [{ "field": "email", "issue": "invalid_format" }],
    "requestId": "req_abc123"
  }
}
```

- `code` — machine-readable, stable, lowercase with underscores
- `message` — for developers, not necessarily for end users
- `details` — array for per-field validation breakdowns
- `requestId` — links to server-side logs; always include

---

## Versioning

- Version in the URL path: `/v1/orders` — explicit, easy to route, visible in logs
- Support the current and previous version simultaneously during transitions
- Deprecate with intent: `Deprecation: true` and `Sunset: <date>` response headers

**Breaking changes (require a new version):**

- Removing or renaming a field
- Changing a field's type
- Changing required/optional status
- Changing a status code or error code contract

**Non-breaking (no new version needed):**

- Adding new optional fields to responses
- Adding new optional request parameters
- Adding new endpoints
- Adding new ignorable enum values

---

## Idempotency

- `GET`, `PUT`, `DELETE` must be naturally idempotent by design
- `POST` operations safe to retry: accept an `Idempotency-Key` header; return the same response for the same key within a reasonable window
- Critical for: payment processing, order placement, any operation with real-world consequences

---

## OpenAPI / Contract-First

Write the spec before writing the implementation:

1. Define paths, operations, and schemas in OpenAPI 3.x
2. Generate server stubs and client SDKs from the spec
3. Validate the running implementation against the spec in CI
4. Commit the spec alongside the code — it is the source of truth for docs, mocks, and contract tests

---

## Pre-Ship Checklist

- [ ] All endpoints return consistent error shapes
- [ ] No field names leak implementation internals (`rec_id`, `tmp_flag`, `__v`)
- [ ] All collection endpoints are paginated
- [ ] Breaking changes are versioned
- [ ] OpenAPI spec committed and matches the implementation
- [ ] Auth and authorization verified on every protected route
- [ ] Rate limiting on public or expensive endpoints
- [ ] All IDs are opaque strings, not sequential integers
- [ ] `Idempotency-Key` supported on state-mutating POST operations
