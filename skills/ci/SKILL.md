---
name: ci
description: GitLab CI/CD — audit, scaffold, and improve pipelines for security, performance, and reliability
compatibility: opencode
---

Audit or scaffold `.gitlab-ci.yml`. The primary use case is improvement: most CI configs accumulate cruft, security debt, and performance drag over time. Apply the deletion bias — a smaller pipeline that does the same thing is always the better pipeline.

> [!NOTE]
> **When NOT to use:** Don't use to paper over flaky tests — fix the tests. Don't add CI steps as a substitute for local quality gates. A CI pipeline should catch what local tooling missed, not replace it.

> [!TIP]
> **Effort:** XS–S on standard tier for single-pipeline audits. M on a deeper tier for complex multi-stage pipelines with deployment environments, matrix builds, or dynamic child pipelines.

---

## Mode

| Mode | When |
|------|------|
| **Audit** | `.gitlab-ci.yml` (and any includes) already exist — assess and improve |
| **Setup** | No pipeline yet — scaffold minimum viable CI for this repo |

Default to **Audit** if `.gitlab-ci.yml` exists.

---

## Audit Protocol

1. Read `.gitlab-ci.yml` and everything it `include`s (local, project, template, remote).
2. Check project settings: protected branches, required-before-merge pipelines, merge-request pipelines, SAST/DAST/Dependency Scanning enabled.
3. Score against the checklist below — find what to delete before finding what to add.
4. Implement fixes (don't just report).
5. Report what changed and net line delta.

```bash
ls .gitlab-ci.yml .gitlab/ 2>/dev/null
# Resolve full merged config (handy when includes are in play)
glab ci view --web  # or use the API:
glab api "projects/:id/ci/lint" --field "content=$(cat .gitlab-ci.yml)"
glab ci list --per-page 20
```

---

## Checklist

### Security — fix these first

**Pin third-party images and include refs to a commit SHA or exact version, not `latest` or a floating tag.**

```yaml
# Bad — tag is mutable
image: node:22

# Good — pinned to digest
image: node:22.11.0-bookworm@sha256:<digest>
```

`include:` the same way:

```yaml
# Bad
include:
  - project: 'org/ci-templates'
    file: '/base.yml'
    ref: main         # mutable

# Good
include:
  - project: 'org/ci-templates'
    file: '/base.yml'
    ref: 'v1.4.0'     # or a commit SHA
```

**Minimal job permissions via `id_tokens` / `CI_JOB_TOKEN` scope.** Don't grant a job broader API scope than it needs. Configure `CI_JOB_TOKEN` allowlists on the project if jobs cross-authenticate to other projects.

**No secrets in `script:` echoes or `variables:` defaults.** Secrets live in project/group CI/CD variables with `Masked` and `Protected` set. `Protected` means the variable is only exposed on protected branches / tags — without this, any developer who can push a feature branch can exfiltrate the secret.

```yaml
# Bad — value echoed to logs
script:
  - echo "$API_TOKEN"

# Bad — secret in variables block
variables:
  API_TOKEN: "sk_live_..."
```

Protected variables must be paired with a protected branch or tag pattern. Unprotected feature branches will not see them — that's the feature.

**Review MR pipelines on fork contributions.** By default, merge-request pipelines from forks run with the **target** project's permissions if the target-project setting `Run pipelines for merge requests from forks` is enabled — that's the GitLab equivalent of `pull_request_target`. Keep it disabled unless you've thought carefully about what fork authors can do with your CI variables.

**No hardcoded credentials anywhere** in the YAML or include tree.

### Performance

**Cache dependencies with a content-addressed key.**

```yaml
cache:
  key:
    files:
      - package-lock.json
  paths:
    - node_modules/
  policy: pull-push  # use pull-only in downstream jobs
```

**Use `rules:changes` to skip jobs when only unrelated files change.**

```yaml
lint:
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
      changes:
        - "**/*.{ts,tsx,js,jsx}"
        - package.json
        - .eslintrc*
```

**Parallelize with `parallel:` or independent jobs in the same stage.** Only chain what actually depends.

```yaml
stages: [quality, test, build]

lint:
  stage: quality
test:
  stage: quality  # parallel with lint

build:
  stage: build
  needs: [lint, test]  # DAG — runs as soon as both finish, even if other quality jobs are still going
```

**Prefer `needs:` over stage-only ordering.** `needs:` builds a DAG and avoids waiting for irrelevant jobs in the same stage.

**Job timeouts.** Every job needs one — `timeout:` overrides the project default. A runaway job silently burns CI minutes.

```yaml
test:
  timeout: 15 minutes
```

**`interruptible: true` on branch pipelines; `interruptible: false` on release pipelines.** GitLab automatically cancels older interruptible pipelines when a newer one starts on the same ref.

```yaml
default:
  interruptible: true

deploy_prod:
  interruptible: false
```

### Reliability

**Required pipelines must be reliable.** A flaky test in a required-for-merge pipeline blocks every MR. Fix it or remove it from required — `allow_failure: true` is not a solution.

**Network-dependent steps need retry.** GitLab's built-in retry respects a list of failure reasons:

```yaml
deploy:
  retry:
    max: 2
    when:
      - runner_system_failure
      - api_failure
      - scheduler_failure
```

**Document every `allow_failure: true`** with an inline comment — otherwise it silently hides failures.

### Maintenance — delete first

- **Redundant before_script** — steps that duplicate what the image or `default:` section already does
- **Dead rules** — `rules:` branches that can never match (e.g., old branch names)
- **Duplicate jobs** — two jobs doing the same thing in different stages; merge them with `rules:` or `extends:`
- **Stale matrix entries** — Node 16 in a parallel matrix for a project that no longer supports it
- **Unused `extends:` chains** — YAML anchors and extends trees grown beyond what's used
- **Descriptive names** — every job needs a name that describes behavior, not mechanics

---

## Dependency update automation

GitLab's built-in option is the [Renovate Bot template](https://gitlab.com/renovate-bot) or Dependabot running in external CI. Wire one of them up so actions, images, and packages refresh on a schedule — don't hand-bump.

---

## Minimum Viable CI (Setup mode)

Start with one pipeline, two stages. Split into more stages only when a single stage exceeds ~10 minutes or you need a hard ordering gate (e.g., deploy after test).

```yaml
# .gitlab-ci.yml
default:
  image: node:22.11.0-bookworm@sha256:<digest>
  interruptible: true
  timeout: 15 minutes

workflow:
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
    - if: $CI_COMMIT_TAG

stages:
  - quality
  - test

.node_cache: &node_cache
  cache:
    key:
      files: [package-lock.json]
    paths: [node_modules/]
    policy: pull-push

install:
  stage: quality
  <<: *node_cache
  script:
    - npm ci

lint:
  stage: quality
  needs: [install]
  <<: *node_cache
  script:
    - npm run lint

typecheck:
  stage: quality
  needs: [install]
  <<: *node_cache
  script:
    - npm run typecheck

test:
  stage: test
  needs: [install]
  <<: *node_cache
  script:
    - npm test
```

---

## Stopping condition

When running in a loop, stop scheduling further invocations when the audit produces zero Must Fix or Should Fix findings: all images/includes pinned, permissions minimal, dependency automation configured, no dead rules, no redundant steps. Only Consider items (or none) remain. A clean pipeline is a valid terminal state.

Emit this exact phrase so a loop runner recognizes it:

> **Loop exit:** Pipeline is clean — no Must Fix or Should Fix items remain. Stopping.

---

## Report Format

```
CI AUDIT
========
Files reviewed: .gitlab-ci.yml, .gitlab/ci/*.yml
Renovate / Dependabot: present / missing
Protected branches: <list>
Required pipeline: <yes/no>

Must fix
--------
[finding] — [why] — [what was done]

Should fix
----------
[finding] — [why] — [what was done]

Consider
--------
[finding] — [why]

Deleted
-------
[what was removed and why]

Net change: -N lines across M files
```
