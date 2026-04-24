# Changelog

All notable changes to this library are recorded here. Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/); version numbers follow [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added

- **`opencode.json`** — checked-in permissions config and three pre-built custom agents (`review`, `ship`, `groomer`) so clone-to-`~/.agents` is zero-configuration

### Changed

- `review-mr/SKILL.md` — added a note for Claude Code users (the built-in `/review` command covers the same intent); step 1 now mentions `glab mr diff` explicitly
- `templates/SKILL-template.md` — added `model:` as a documented optional frontmatter field with guidance on when to use it vs. leaving tier choice in prose; kept provider-agnostic so Claude, Qwen, MiniMax, and other environments can all pin their own model IDs
- `scripts/validate-skills.sh` — new `model:` frontmatter check: warns when the key is present but empty, without constraining which provider's model IDs are valid

## [0.1.0] — 2026-04-24

### Added

- Initial public release of 36 skills and 2 shared helpers
- **Design & planning:** `/spec`, `/systems-design`, `/adr`, `/tasking`, `/tracker-init`, `/workflow`, `/feature-review`
- **Implementation:** `/coding`, `/api-design`, `/database`, `/debug`, `/ship-debug`, `/observability`, `/security-audit`, `/performance`, `/ci`
- **Code quality:** `/refactor`, `/ship-refactor`, `/refactor-changes`, `/refactor-docs`, `/overhaul`, `/review-mr`, `/commit`, `/dependency-update`
- **Testing:** `/unit-tests`, `/integration-tests`
- **Autonomous execution:** `/next`, `/ship-next`, `/groom`
- **Release:** `/release-notes`
- **Incident response:** `/postmortem`
- **Developer experience:** `/onboarding`
- **Platform-specific:** `/apple-hig` (iOS, iPadOS, macOS, watchOS, tvOS, visionOS)
- **Agent systems:** `/agent-systems`, `/agent-audit`
- **Meta:** `/new-skill` — scaffolds new skills following the library's contract
- `shared/project-discovery.md` and `shared/status-transition.md` helpers for the GitLab-wired `ship-*` and `/groom` skills
- Contract validator at `scripts/validate-skills.sh` and GitHub Actions workflow that runs it on every push and pull request
- `templates/SKILL-template.md` — starting point for new skills
- `registry.md` — work-type → skill mapping
- `CONTRIBUTING.md` — how to add or improve a skill

### Contract

Every `SKILL.md` conforms to the [OpenCode Agent Skills spec](https://opencode.ai/docs/skills):
- Located at `skills/<name>/SKILL.md` (agent-discoverable under `~/.agents/skills/` or `.agents/skills/`)
- Frontmatter: kebab-case `name`, specific `description` (≤1024 chars), explicit `compatibility: opencode`
- Body is plain Markdown — no bundled scripts or runtime dependencies

### Origin

Platform-portable core of a larger, GitHub-wired library. Vendor-specific plumbing (`gh` CLI, GitHub Projects v2, harness-specific tool names) was replaced with portable equivalents (`glab` CLI, GitLab scoped-label issue boards, agent-neutral phrasing, capability tiers). Engineering ideas — Goldilocks testing, net-deficit refactoring, verified status transitions, scoped-label drift repair — were preserved.

[Unreleased]: https://github.com/torsday/dotagents/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/torsday/dotagents/releases/tag/v0.1.0
