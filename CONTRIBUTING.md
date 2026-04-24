# Contributing

Thanks for wanting to improve this library. Its value depends on every skill being specific, composable, and honest about tradeoffs. A skill that papers over tension produces worse agent behavior than no skill at all.

## Add a new skill

**Easiest path:** invoke [`/new-skill`](skills/new-skill/SKILL.md) in an agent that has this library installed. It scaffolds the file, fills in the contract, and updates the registry.

**Manual path:**

1. Pick a recurring task the agent should handle consistently. Vague goals ("improve the codebase") are not skills — they're a symptom.
2. Copy [`templates/SKILL-template.md`](templates/SKILL-template.md) to `skills/<name>/SKILL.md`.
3. Fill in the frontmatter. `name` must match the directory and the pattern `^[a-z0-9]+(-[a-z0-9]+)*$`. `description` must be specific enough for an agent to select this skill over its siblings.
4. Write the body:
   - One-sentence opening statement of what the skill does
   - `When NOT to use` admonition — specificity is the point
   - Protocol as numbered steps, not prose
   - Report format if the skill produces output
   - Stopping condition with an explicit `Loop exit: …` phrase if the skill is loop-safe
5. Add a row to [`registry.md`](registry.md) mapping the work type to the new skill.
6. Add an entry under `[Unreleased]` in [`CHANGELOG.md`](CHANGELOG.md).
7. Run `./scripts/validate-skills.sh` locally. Fix every error before opening a PR.
8. Open a PR. CI will re-run validation.

## Review criteria

A skill that gets merged is:

- **Specific** — "audit the diff for N+1 queries" beats "make it faster"
- **Composable** — references other skills (`/coding`, `/commit`, `/review-mr`) rather than duplicating their rules
- **Exitable** — if loop-safe, emits a clear `Loop exit: …` phrase when the checklist passes clean
- **Honest about tradeoffs** — surfaces design tension; doesn't paper over it
- **Frontmatter-valid** — passes `scripts/validate-skills.sh`
- **Cross-reference-valid** — every `skills/<name>/SKILL.md` and `shared/<name>.md` link resolves

## Run the validator

```bash
./scripts/validate-skills.sh
```

Checks every `SKILL.md` against the [OpenCode Agent Skills spec](https://opencode.ai/docs/skills) and verifies every markdown link to a skill or shared helper points at a real file. No Node, Python, or other toolchain required — pure bash + awk + grep.

## Change an existing skill

- **Behavioral changes** (what the skill does, how it decides, what it emits) warrant a note under `[Unreleased]` in `CHANGELOG.md`.
- **Editorial changes** (wording, typos, clarity) don't need a changelog entry.
- **Renaming a skill** is a breaking change — update every cross-reference, update `registry.md`, and bump the minor version per SemVer.
- **Deleting a skill** is a breaking change — bump the major version.

## Commit style

This library uses [Conventional Commits](https://www.conventionalcommits.org/). Common types in this repo:

| Type       | For                                                    |
| ---------- | ------------------------------------------------------ |
| `feat`     | A new skill, new shared helper, or new capability      |
| `fix`      | A correction to an existing skill's protocol or rules  |
| `docs`     | README, CONTRIBUTING, registry, or frontmatter edits   |
| `refactor` | Restructuring skill bodies without changing behavior   |
| `chore`    | Validator, CI, tooling, repo hygiene                   |

## Local override

Projects that need a private or project-specific skill shouldn't send it here. Drop it at `.agents/skills/<name>/SKILL.md` in the consuming project — OpenCode discovers the project-local path first and overrides the global one.

## Questions

Open an issue. A skill worth writing is often a skill worth discussing first.
