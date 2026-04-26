<!--
This is a starting point for a new skill. Copy it to `skills/<name>/SKILL.md`
and replace every <angle-bracketed placeholder>. Delete sections that don't
apply — a skill should be the minimum structure that communicates its job.

Contract (enforced by scripts/validate-skills.sh):
  - `name` must match the directory name and `^[a-z0-9]+(-[a-z0-9]+)*$`
  - `description` must be ≤ 1024 chars and specific enough to aid agent selection
  - `compatibility: opencode` signals the OpenCode Agent Skills contract
  - `model` (optional) pins OpenCode to a specific model ID for this skill;
    use for skills that genuinely need deep reasoning (e.g. security-audit).
    Omit for tier-conditional skills — they surface the tier choice in prose
    so any capable model can execute them. Model IDs are environment-specific
    (Claude, Qwen, MiniMax, etc.) — the validator only checks the field is
    non-empty, not which provider it names.

After copying, delete this HTML comment.
-->
---
name: <kebab-case-name-matches-directory>
description: <one-sentence statement — specific enough for an agent to decide whether to invoke, ≤1024 chars>
compatibility: opencode
# model: <provider-specific-model-id>   # uncomment to pin model; omit for tier-conditional skills
---

<One-sentence opening. Skip fluff. A reader should know in five seconds whether this is the right skill for the task at hand.>

> [!NOTE]
> **When NOT to use:** <Single most common misuse — be specific about what doesn't belong here.> Don't use <another common trap>.

> [!TIP]
> **Effort:** <XS / S / M / L / XL>. <Optional: which capability tier suits this — `tier::deep` for reasoning-heavy work, `tier::standard` for well-specified execution.>

## Protocol

1. <First concrete step.>
2. <Second concrete step.>
3. <Continue until the skill's job is done.>

---

## <Optional body section — checklist, review lens, examples, whatever the skill needs>

- <Bullet>
- <Bullet>

---

## Report format

<If the skill produces structured output, document the shape here so the agent emits consistent reports across invocations.>

```
REPORT
======
<Structured output shape>
```

---

## Stopping condition

<Delete this section if the skill isn't loop-safe.>

When running in a loop, stop scheduling further invocations when <the specific terminal condition this skill recognizes>.

Emit this exact phrase so a loop runner recognizes it:

> **Loop exit:** <specific reason stating what's clean or complete>. Stopping.
