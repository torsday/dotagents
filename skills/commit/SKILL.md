---
name: commit
description: Construct atomic Conventional Commits from staged changes
compatibility: opencode
---

Looking at the git diff and staged changes — construct one or more atomic commits following the Conventional Commits specification.

> [!NOTE]
> **Upstream:** Run `/refactor-changes` to clean the diff and `/review-mr` to assess logic and design before committing. This skill is the final step — it assumes the changes are correct and ready to record.

> [!NOTE]
> **When NOT to use:** Don't commit WIP checkpoints — use `git stash` or a draft branch. Don't commit until `/refactor-changes` and `/review-mr` have passed.

> [!TIP]
> **Effort:** XS. Commit construction is mechanical and well-specified; a small or fast model handles it fine.

## Steps

1. Run `git diff --staged` to review staged changes.
2. Run `git log --oneline -10` to observe commit style and scope conventions in use.
3. Group changes into logical units. If staged changes span more than one concern, split into separate commits using `git commit -- <paths>`.
4. For each commit: write the message, then execute.

---

## Format

```
<type>(<scope>): <imperative summary, ≤72 chars>

- bullet points explaining WHY (the diff shows what)

[BREAKING CHANGE: description]
[Closes #123 | Refs #123]
```

### Type → Semver

| Type       | Use case                        | Semver |
| ---------- | ------------------------------- | ------ |
| `feat`     | New capability                  | MINOR  |
| `fix`      | Bug correction                  | PATCH  |
| `feat!`    | Breaking feature change         | MAJOR  |
| `fix!`     | Breaking bug fix                | MAJOR  |
| `refactor` | Restructure, no behavior change | —      |
| `perf`     | Performance improvement         | —      |
| `test`     | Tests only                      | —      |
| `docs`     | Documentation only              | —      |
| `chore`    | Tooling, deps, config           | —      |
| `ci`       | CI/CD pipeline                  | —      |
| `build`    | Build system                    | —      |

`!` and `BREAKING CHANGE:` footer are equivalent — both trigger a MAJOR bump.

### Rules

- **Scope**: affected module or domain (`auth`, `payments`, `api`, `db`) — omit if the change is truly cross-cutting
- **Summary**: imperative mood, lowercase, no trailing period
- **Body**: bullet points — explain _why_, not _what_; reference issues where relevant

---

## Example

```
feat(auth): add PKCE flow for public OAuth2 clients

- Implicit grant flow deprecated per RFC 9700
- PKCE allows public clients to authorize without a client secret

Closes #418
```
