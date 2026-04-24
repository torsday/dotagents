---
name: refactor-docs
description: Refactor documentation for clarity, accuracy, and appropriate scope — delete outdated content, sharpen what remains
compatibility: opencode
---

Looking at the documentation, refactor and improve it for clarity, accuracy, and appropriate scope. Apply the Goldilocks principle: not too much, not too little.

> [!NOTE]
> **When NOT to use:** Don't use to add documentation for code that isn't done — docs for aspirational behavior mislead with authority. Don't use to generate README content from scratch for a project you haven't read; inaccurate docs are worse than none.

## Protocol

1. Read all existing documentation.
2. Identify what's missing, stale, or excessive.
3. Apply improvements — proceed without pausing for confirmation.
4. Note the _why_ behind non-obvious decisions made — the diff shows the what.

---

## README Standards

A good README answers these questions — nothing more:

1. **What is this?** — one-paragraph description of purpose and scope
2. **Why does it exist?** — the problem it solves
3. **How do I run it?** — minimal, copy-pasteable quickstart
4. **How do I contribute?** — link to contributing guide or brief instructions
5. **What's the structure?** — high-level map of key directories/files (only if non-obvious)

Cut anything that: repeats what the code already shows, explains the obvious, or belongs in a more specific doc.

---

## Mermaid Diagrams

Use Mermaid for:

- System architecture and component relationships (`graph TD`, `C4Context`)
- Complex interaction sequences (`sequenceDiagram`)
- State machines (`stateDiagram-v2`)
- Entity relationships (`erDiagram`)

Diagram standards:

- Show essential relationships — omit noise
- Label edges meaningfully
- Use names consistent with the codebase
- Verify diagrams render without syntax errors

---

## What to Delete

Outdated docs are worse than no docs — they mislead with authority. Delete without hesitation:

- Instructions that describe how something used to work
- Setup steps that no longer apply
- Sections that say "coming soon" or "TODO" and have been there for months
- Duplicate content that exists in a more authoritative place
- Commentary that restates what the code already makes obvious

When deleting, check whether anything links to the section — update or remove those links too.

---

## Inline & API Documentation

For public interfaces, libraries, or any code consumed by other developers:

- Every exported function, class, and type gets a docblock: one-line summary, `@param`, `@returns`, `@throws`
- Document the **why and when** — not the mechanics (the code shows those)
- For REST APIs: keep an OpenAPI spec in sync with the implementation; outdated specs are liabilities
- Link inline docs to the relevant ADR if the design decision behind an interface is non-obvious

---

## General Documentation Principles

- **Accurate** — reflects current code, not aspirational state
- **Maintained** — outdated docs are worse than none; mark stale sections clearly
- **Linked** — cross-reference related docs; don't duplicate content across files
- **Audience-aware** — write for the actual reader (new dev, ops, end user) — the same information reads differently for each
- **Versioned** — note which version a doc applies to if relevant

---

## Stopping condition

When running in a loop, stop scheduling further invocations when: docs reflect current code, no stale sections remain, every exported interface has an accurate docblock, no duplicate content across files, and no "coming soon" / "TODO" placeholders older than a sprint.

Emit this exact phrase so a loop runner recognizes it:

> **Loop exit:** Documentation clean — no stale, missing, or duplicated content remains. Stopping.
