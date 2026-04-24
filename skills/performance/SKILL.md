---
name: performance
description: Find and fix performance problems — profile first, then optimize algorithms, I/O, memory, concurrency, and caching
compatibility: opencode
---

Looking at the code, identify and apply performance improvements — faster execution, lower memory pressure, fewer unnecessary operations — in service of scalability and reliability, without sacrificing correctness or maintainability.

**Measure first. Never optimize by intuition alone.**

> [!NOTE]
> **When NOT to use:** Don't use for premature optimization — measure the bottleneck first. Don't use as a substitute for better algorithmic choices; a profiler-confirmed slow O(n²) should become O(n log n), not "fast O(n²)."

## Protocol

1. Read the relevant code paths.
2. Identify where time or resources are actually being spent — use profiler output, query plans, or benchmark results if available. If not, reason from first principles about what the bottleneck is likely to be.
3. State findings (issue, likely impact, intended fix) — then implement immediately. Do not pause for confirmation.
4. Apply changes one at a time so each improvement is independently verifiable.
5. Measure after. Confirm the change produced the expected gain without breaking behavior.

---

## Rules

- **Correctness before performance** — an optimization that introduces a bug is not an optimization.
- **Don't guess the bottleneck** — optimizing the wrong thing wastes time and adds complexity. Profile or reason from evidence.
- **Readability is not free to sacrifice** — micro-optimizations that obscure intent and don't meaningfully move the needle are not worth it. Document any that are.
- **Measure before and after** — an untested optimization is a hypothesis, not a fix.

---

## What to Look For

### Algorithmic Complexity

- O(n²) or worse where O(n log n) or O(n) is achievable
- Nested loops over the same data set
- Linear scans where indexed lookups are possible
- Repeated sorting of data that could be sorted once

### Database & I/O

- N+1 queries — loading related records one at a time instead of in bulk
- Missing indexes on frequently filtered or joined columns
- Fetching more columns or rows than needed (over-fetching)
- Synchronous I/O blocking where async or batching is viable
- Repeated reads of the same file or resource within a request

### Memory

- Large object allocations inside hot loops
- Unnecessary copying of data structures (prefer references/views where safe)
- Retaining references longer than needed, preventing garbage collection
- Building large intermediate collections when streaming would suffice

### Caching

- Expensive computations repeated with identical inputs — memoize or cache
- External calls (API, DB, filesystem) made repeatedly for stable data
- Cache invalidation: ensure cached values are evicted when the underlying data changes

### Concurrency

- Sequential operations that are independent and could run in parallel
- Blocking calls that could be made async
- Over-locking (holding locks longer than necessary)

### Serialization & Parsing

- Deserializing the same payload multiple times
- Parsing strings or dates in tight loops
- Using verbose formats (XML, JSON) where a binary format is justified by volume

---

## Output Format

For each finding:

**[Impact: High / Medium / Low]** `location` — what is slow and why → the fix → expected gain

---

## Stopping condition

When running in a loop, stop scheduling further invocations when the profile is clean: no hot paths with obvious inefficiency, no N+1 query patterns, no memory allocations in tight loops, no sequential operations that could parallelize without complication. Remaining gains would require design-level changes.

Emit this exact phrase so a loop runner recognizes it:

> **Loop exit:** Profile clean — no remaining high- or medium-impact hotspots. Stopping.
