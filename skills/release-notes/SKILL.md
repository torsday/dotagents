---
name: release-notes
description: Generate CHANGELOG entries, release notes, and migration guides for version bumps
compatibility: opencode
---

Looking at the git log since the last release — generate a CHANGELOG entry and release notes.

> [!NOTE]
> **When NOT to use:** Don't use for changes with no user-visible impact (internal refactors, test-only changes, dev tooling). Don't use before changes are merged to the release branch — the log must be final.

> [!TIP]
> **Effort:** XS–S. A standard-tier model is sufficient — this is structured summarization from git log.

## Steps

1. Run `git tag --sort=-version:refname | head -5` to find the last release tag.
2. Run `git log <last-tag>..HEAD --oneline` to see all commits since then.
3. Read any commits that need more context to summarize accurately.
4. Derive the version bump from commit types (see below).
5. Produce the output in two forms: CHANGELOG entry and human-readable release notes.
6. If this is a MAJOR bump, produce a Migration Guide.
7. On GitLab, a release is created from a tag. After merging the CHANGELOG update, tag the release commit and use `glab release create <tag>` (or the GitLab UI) to publish the notes.

---

## Version Bump Rules

| Commit type                                      | Bump                                     |
| ------------------------------------------------ | ---------------------------------------- |
| Any `feat`                                       | MINOR                                    |
| Any `feat!`, `fix!`, or `BREAKING CHANGE` footer | MAJOR                                    |
| Only `fix`, `perf`, `chore`, `refactor`, etc.    | PATCH                                    |
| No user-facing changes                           | No release needed — note this explicitly |

---

## CHANGELOG Entry

Follow [Keep a Changelog](https://keepachangelog.com) format. Only include sections that have entries:

```markdown
## [X.Y.Z] — YYYY-MM-DD

### Added

- ...

### Changed

- ...

### Fixed

- ...

### Deprecated

- ...

### Removed

- ...

### Security

- ...
```

---

## Release Notes

A short summary for a broad audience (GitLab release page, announcement post):

- Lead with the most impactful change
- Group related changes naturally
- Skip internal refactors and chores unless they affect users
- Link to relevant issues or MRs where helpful
- If there are no user-facing changes, say so clearly — don't pad

---

## Migration Guide (MAJOR bumps only)

When the version bump is MAJOR, produce a migration guide alongside the release notes:

```markdown
## Migrating from vX to vY

### Breaking Changes

For each breaking change:
**What changed:** description
**Why:** rationale
**Before:**
[code or config example showing the old way]
**After:**
[code or config example showing the new way]

### Deprecations

List anything deprecated in this release and what replaces it.

### Upgrade Steps

Numbered, copy-pasteable steps to upgrade cleanly.
```

Migration guides are for the people upgrading, not for the people who built the feature. Write them at the level of someone who hasn't read the commit history.

---

## Publishing on GitLab

```bash
# After the CHANGELOG commit is merged to the release branch:
git tag -a v1.2.0 -m "v1.2.0"
git push origin v1.2.0

# Create the release and attach the notes
glab release create v1.2.0 \
  --name "v1.2.0" \
  --notes-file CHANGELOG-v1.2.0.md
```

Milestones can be associated with the release via `--milestone <name>` — the release page will then show all issues closed under that milestone.
