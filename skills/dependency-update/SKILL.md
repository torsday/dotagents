---
name: dependency-update
description: Audit, update, and verify dependencies safely — one at a time, prioritized by risk and CVE exposure
compatibility: opencode
---

Looking at the dependency manifest — audit, update, and verify dependencies safely, one at a time.

**Dependencies are code you didn't write.** Updating them carries real risk — but so does not updating them. CVEs accumulate in stale dependency trees. The goal is a deliberate, evidence-driven update process, not a bulk `upgrade --latest`.

> [!NOTE]
> **When NOT to use:** Don't use for greenfield projects with no dependency tree to audit. Don't use as a replacement for automation (Renovate, Dependabot) — those catch new advisories continuously; this skill is for directed audits and resolution.

## Protocol

1. Read the manifest (`package.json`, `go.mod`, `Gemfile`, `requirements.txt`, etc.) and any lockfile.
2. Identify outdated and potentially vulnerable dependencies.
3. Categorize each by risk (see below).
4. Update in priority order: security-critical first, then major, then minor, then patch.
5. After each update: run the full test suite before moving to the next.
6. Produce the output summary table when done.

Do not pause for confirmation — work through the full list.

---

## Risk Categories

| Update type                        | Risk         | Strategy                                                             |
| ---------------------------------- | ------------ | -------------------------------------------------------------------- |
| Security advisory (any version)    | **Critical** | Update immediately, regardless of semver bump                        |
| Major (`1.x` → `2.0.0`)            | **High**     | Read migration guide fully; expect breaking changes; test thoroughly |
| Minor (`1.2.x` → `1.3.0`)          | **Medium**   | Read CHANGELOG for behavior changes; run tests                       |
| Patch (`1.2.3` → `1.2.4`)          | **Low**      | Update confidently; verify tests pass                                |
| Abandoned (last release > 2 years) | **Variable** | Assess exposure and maintainer health; consider replacement          |

---

## For Each Update

1. **Check for CVEs first** — `npm audit`, `pip-audit`, `bundler-audit`, `govulncheck`, or [osv.dev](https://osv.dev). A security-motivated update changes the risk calculus.
2. **Read the CHANGELOG** for the relevant version range. Look for: deprecated APIs, behavior changes, removed features, new peer dependency requirements.
3. **Update the lockfile** — commit manifest change and lockfile together in the same commit.
4. **Run the full test suite** — not just tests related to the updated package. Transitive effects are common.
5. **Verify runtime behavior** for any package that touches a critical path.

---

## What Not to Update

- **Peer dependencies** declared as compatible by a dependent package — don't force-upgrade a peer before the dependent declares support
- **Major versions with no clear migration path** — flag for dedicated work; document the reason for staying on the old version in a comment in the manifest
- **Packages with a recent maintainer change** — a maintainer handoff is a supply chain risk vector; assess before upgrading

---

## Signals of a Healthy Dependency

| Signal             | What to check                                                                      |
| ------------------ | ---------------------------------------------------------------------------------- |
| Active maintenance | Recent commits, releases, issue responses                                          |
| Usage              | Download count; production use by known projects                                   |
| License            | Compatible with your project's license                                             |
| Scope              | Does one small thing well — not a monolith doing too much                          |
| Attack surface     | The fewer things it touches (filesystem, network, native code), the lower the risk |

---

## Output Summary

After completing updates, produce this table:

| Package   | From    | To      | Type    | Notes                                                        |
| --------- | ------- | ------- | ------- | ------------------------------------------------------------ |
| `express` | 4.18.1  | 4.21.0  | Minor   | No behavior changes affecting this codebase                  |
| `lodash`  | 4.17.19 | 4.17.21 | Patch   | CVE-2021-23337 resolved                                      |
| `react`   | 17.0.2  | —       | Skipped | v18 requires concurrent mode migration; flagged as tech debt |

---

## Stopping condition

When running in a loop, stop scheduling further invocations when: no security advisories apply to current versions, no major updates are available with a clear migration path, remaining minor/patch updates have been applied, and skipped updates are documented with a reason.

Emit this exact phrase so a loop runner recognizes it:

> **Loop exit:** Dependency tree clean — no outstanding security or safely-applicable updates. Stopping.
