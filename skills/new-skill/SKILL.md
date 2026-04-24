---
name: new-skill
description: Scaffold a new skill in this library — frontmatter contract, body sections, registry entry, validator pass
compatibility: opencode
---

Create a new skill following the library's contract so it fits cleanly alongside the existing skills and passes the validator on first push.

> [!NOTE]
> **When NOT to use:** Don't use to duplicate an existing skill — improve the existing one instead. Don't use for single-project conventions that shouldn't live in the public library; put those in your project's local `.agents/skills/` override. Don't use for prompts that aren't tasks — skills are invocable units of work, not essays or checklists.

> [!TIP]
> **Effort:** S. A clear, specific skill is ~100–200 lines of Markdown; a deeper-tier skill handling a complex process can reach 300–400 lines. If you're over 500, split it.

## Protocol

1. Ask the operator: skill name (kebab-case), one-sentence description, whether it's loop-safe, and which capability tier fits.
2. Check for collision — if `skills/<name>/` already exists, stop and surface it. Don't silently overwrite.
3. Copy `templates/SKILL-template.md` to `skills/<name>/SKILL.md`.
4. Fill in frontmatter:
   - `name` matches the directory and `^[a-z0-9]+(-[a-z0-9]+)*$`
   - `description` is ≤1024 chars and specific enough to aid agent selection
   - `compatibility: opencode`
5. Write the body, in this order:
   - One-sentence opening that makes the skill's job unmistakable
   - `When NOT to use` admonition — pick the two most common misuses and name them
   - Protocol as numbered steps, not prose
   - Report format if the skill produces structured output
   - Stopping condition with explicit `Loop exit: …` phrase if the skill is loop-safe
6. Add a row to `registry.md` mapping the work type to the new skill. Place it in the section that matches the skill's phase.
7. Add an `[Unreleased]` entry in `CHANGELOG.md` under `### Added`.
8. Run `scripts/validate-skills.sh`. Fix every error before declaring the skill done.
9. If the new skill references other skills or shared helpers, click through each link locally to verify the path resolves.

---

## Contract (enforced by validator)

- `name` in frontmatter equals the directory name and matches `^[a-z0-9]+(-[a-z0-9]+)*$`
- `description` present, non-empty, ≤1024 chars
- `compatibility: opencode`
- Every `(skills/<name>/SKILL.md)` markdown link resolves
- Every `(shared/<name>.md)` markdown link resolves
- Every bare `shared/<name>.md` prose reference resolves

---

## Principles (enforced by review)

- **Specific** — "audit the diff for N+1 queries" beats "make it faster." An agent should never have to guess which of two overlapping skills to invoke.
- **Composable** — reference existing skills (`/coding`, `/commit`, `/review-mr`) rather than duplicating their rules. When an existing skill covers a step, link to it; don't re-specify.
- **Exitable** — loop-safe skills emit a clear `Loop exit: <reason>. Stopping.` phrase when their checklist passes clean. A skill that can't recognize its own terminal state shouldn't claim to be loop-safe.
- **Honest about tradeoffs** — surface design tension. If the skill trades off coverage for speed, or safety for simplicity, say so. Papering over tradeoffs produces worse agent behavior than naming them.
- **Deletion bias** — skills that cover "improvement" work (refactor, review, audit) treat _net-negative line count_ as a primary goal, not a side effect.

---

## Report format

```
NEW SKILL
=========
Name:         <name>
Description:  <description>
Loop-safe:    <yes / no>
Tier:         <tier::deep / tier::standard / either>
Size:         <final SKILL.md line count>

Registry entry: <work-type row added>
Changelog:      <[Unreleased] entry added>
Validator:      <PASS / FAIL — errors if any>
```
