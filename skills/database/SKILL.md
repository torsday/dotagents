---
name: database
description: Design or improve the database layer for correctness, performance, and safe evolution — schema, indexes, migrations, query design, constraints
compatibility: opencode
---

Looking at the data model, schema, and queries — design or improve the database layer for correctness, performance, and safe evolution over time.

> [!NOTE]
> **When NOT to use:** Don't use for application-layer data validation — the database is the last line of defense, not the first. Don't use for ORM-specific patterns; this skill focuses on schema and query fundamentals that are portable across ORMs.

## Protocol

1. Read existing schema, models, migrations, and queries.
2. Identify issues: missing constraints, missing indexes, unsafe migration patterns, query anti-patterns.
3. State findings and intended changes — then implement. Do not pause for confirmation.

---

## Schema Design

### Naming

- Tables: `snake_case`, plural (`orders`, `line_items`) — not `Order`, `tblOrders`
- Columns: `snake_case`, explicit (`created_at`, `user_id`) — not `ts`, `uid`
- Primary keys: `id` (UUID v4/v7 preferred over sequential integers — opaque, safe to expose, shard-friendly)
- Foreign keys: `{table_singular}_id` (`user_id`, `order_id`)
- Booleans: positive form (`is_active`, `has_confirmed`) — never `not_deleted`
- Timestamps: `created_at` and `updated_at` on every table; always UTC

### Normalization

- **3NF by default** — eliminate transitive dependencies and redundant storage
- Denormalize **intentionally and explicitly** when query performance demands it — document the tradeoff in a comment or ADR
- Don't store computed values unless caching them is a deliberate, profiled decision

### Constraints

Constraints are free correctness — the database enforces them even when application code has bugs:

- `NOT NULL` on every column that must always have a value
- `UNIQUE` on columns that must be unique (including composite unique constraints)
- `FOREIGN KEY` with explicit `ON DELETE` / `ON UPDATE` behavior — no implicit cascades
- `CHECK` for domain validation (`CHECK (amount > 0)`, `CHECK (status IN ('pending', 'complete', 'failed'))`)
- Sensible `DEFAULT` values where meaningful

---

## Indexes

An unindexed query on a large table is a future incident. An over-indexed table has a slow write path.

**Always index:**

- Primary keys (automatic)
- Foreign key columns (not automatic in most databases — add them)
- Columns in frequent `WHERE` clauses on large tables
- Columns in `ORDER BY` or `GROUP BY` on large tables
- Composite indexes when queries filter on multiple columns together

**Be cautious indexing:**

- Low-cardinality columns (booleans, status enums with 3–4 values) — the planner may ignore the index anyway
- Columns written very frequently — indexes add write overhead
- "Just in case" indexes on unused query patterns

**Always run `EXPLAIN ANALYZE`** on non-trivial queries. Never assume the query plan is what you expect.

---

## Migrations

### The Expand-Contract Pattern

The only safe way to change a live schema without downtime or data loss:

1. **Expand** — add the new structure (column, table, index). Old code still works. New code can start using it.
2. **Migrate** — backfill data; update application code to use the new structure.
3. **Contract** — remove the old structure. Old code is gone; only the new code remains.

Renaming a column in a single migration is a breaking change. The correct path: add the new name → backfill → switch code → remove the old name.

### Migration Rules

- **Forward-only** — do not write rollback logic in migrations; write a separate migration to undo
- **Idempotent** — running a migration twice produces the same result as running it once
- **Non-locking where possible** — add nullable columns, create indexes `CONCURRENTLY`, use `NOT VALID` then `VALIDATE CONSTRAINT` separately
- **One change per migration** — easier to diagnose, easier to sequence
- **Never modify a committed migration** — it's history; write a new one

### What Makes a Migration Dangerous

| Pattern                              | Risk                             | Safer Alternative                        |
| ------------------------------------ | -------------------------------- | ---------------------------------------- |
| Renaming a column                    | Breaks running code immediately  | Expand-contract                          |
| Adding `NOT NULL` without a default  | Fails if any rows exist          | Add nullable → backfill → add constraint |
| Dropping a column still used by code | Runtime errors                   | Remove from code first                   |
| Adding a non-concurrent index        | Table lock during build          | `CREATE INDEX CONCURRENTLY`              |
| Modifying enum values                | Can require a full table rewrite | Add new enum type, migrate, drop old     |

---

## Query Design

- **Fetch only what you need** — name columns explicitly; `SELECT *` hides schema dependencies
- **No N+1 patterns** — load related records in bulk (`JOIN` or batch `WHERE id IN (...)`)
- **Parameterize all inputs** — never concatenate user input into a query string
- **Paginate large result sets** — cursor-based for stability; offset for small stable sets only
- **Transactions for multi-step mutations** — if steps 1 and 2 must both succeed or both fail, they belong in a transaction
- **Statement timeouts** — a query without a timeout can hold locks indefinitely and take down the DB under load

---

## Data Integrity

The database is the last line of defense. Application code has bugs; well-designed constraints don't.

- Enforce uniqueness at the DB level, not only in application code
- Validate at application boundaries, and also constrain in the DB — belt and suspenders
- Soft deletes: use `deleted_at TIMESTAMP NULL` — not `is_deleted BOOLEAN` which is easy to forget in queries
- For audit trails: append-only event tables beat mutable `updated_at` columns
- Sensitive data: encrypt at rest; never store credentials, tokens, or PII in plaintext
