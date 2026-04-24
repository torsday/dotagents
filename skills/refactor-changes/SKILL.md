---
name: refactor-changes
description: Pre-commit quality gate — refactor the current git diff plus one hop of linked files
compatibility: opencode
---

Looking at the current git diff — staged and unstaged — refactor every touched file, and the files directly linked to them, to engineering excellence. Leave the working tree in a state that's ready to commit with confidence.

> [!NOTE]
> **This skill vs `/refactor` and `/ship-refactor`:** This skill auto-scopes to the current git diff plus one hop of linked files — use it as a pre-commit quality gate. For a manually targeted refactor of any code, use `/refactor`. For an autonomous GitLab-tracked refactor loop (issue → branch → MR → merge), use `/ship-refactor`.

> [!NOTE]
> **When NOT to use:** Don't use when staged changes span the whole codebase — scope is intentionally one hop; use `/refactor` on a specific directory instead. Don't use when staged changes aren't finalized and you're still mid-implementation.

> [!TIP]
> **Effort:** XS–S depending on diff size. A standard-tier model is sufficient — this is a scoped, mechanical quality gate on a bounded diff.

---

## Scope

### 1. Identify changed files

```bash
git diff --name-only          # unstaged changes
git diff --name-only --staged # staged changes
```

Collect the union. These are the primary targets.

### 2. Expand one hop to linked files

For each changed file, find:

- **Files it imports** — modules, packages, or local files it depends on
- **Files that import it** — callers, consumers, anything that depends on the changed interface

Use language-appropriate tooling:

```bash
# Find imports within a file (examples)
grep -n "^import\|^from\|^require\|^use " <file>

# Find files that import a changed module
grep -rl "from.*<module>\|require.*<module>\|import.*<module>" src/
```

Limit expansion to **one hop**. Do not recurse into the full dependency graph — the goal is to catch interfaces that need updating, not to refactor the whole codebase.

### 3. Confirm scope before refactoring

List the full set of files (primary + linked) before making any changes. If the linked set is unexpectedly large (more than ~10 files), flag it and ask whether to proceed or narrow the scope.

---

## Refactoring Standard

Apply the `/refactor` checklist throughout — do not re-read it, just follow it. Key priorities given the diff context:

- **Interface consistency** — if a signature, type, or contract changed in a primary file, propagate it cleanly through all linked files; don't leave mismatches
- **Naming** — rename anything in linked files that no longer reflects the domain correctly after the change
- **Dead code** — changes often leave behind old branches, unused imports, or superseded helpers; delete them
- **Error handling** — new code paths introduced by the change need the same boundary handling as the rest of the system
- **Test coverage** — if tests exist for the changed code, update them; if a critical path now has no test, add one

---

## Protocol

1. Run both `git diff` commands and collect the primary file set.
2. Expand one hop to linked files.
3. List the full scope.
4. Read each file in scope — understand the change before touching anything.
5. Refactor. Work file by file; finish each before moving to the next.
6. Do not pause between files for confirmation — complete the full scope.
7. If a genuine decision point arises mid-refactor (e.g., a linked file would require a substantial redesign), surface it in a note at the end rather than stopping mid-stream.

---

## What This Is Not

- **Not a review** — findings are fixed, not reported. For review-only feedback, use `/review-mr`.
- **Not a full codebase refactor** — scope is the diff plus one hop, not the whole project. For that, use `/refactor` pointed at a specific directory.
- **Not a commit** — this leaves the working tree improved and dirty. When done, run `/commit` to construct the commit.

---

## Done When

- All files in scope pass the `/refactor` checklist
- No introduced regressions — existing tests pass
- Interface changes are consistent across all linked files
- Dead code from the change is removed
- Working tree is clean enough to commit with confidence
