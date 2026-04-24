# Project discovery (GitLab)

Resolves GitLab issue-board metadata. Used by `/ship-next`, `/ship-refactor`, and `/ship-debug`. Run once per cycle before the Protocol section — the variables it sets are referenced by the status-transition helper and by every `glab` call that needs the project slug.

Unlike GitHub Projects v2 (which uses single-select custom fields and requires GraphQL mutations to flip columns), GitLab issue boards are driven by **scoped labels**. A label like `workflow::in-progress` makes the issue appear in the `In Progress` column automatically. This keeps the helper small — no GraphQL, no field IDs, just label add/remove with glab.

## Shell block

```bash
# Resolve the current repo's GitLab project path (e.g. "group/subgroup/repo").
# `glab repo view` prints "namespace/path" by default; capture that.
PROJECT_PATH=$(glab repo view -F json 2>/dev/null | jq -r '.path_with_namespace // empty')

if [ -z "$PROJECT_PATH" ]; then
  echo "FATAL: not inside a GitLab project (glab repo view failed)" >&2
  exit 1
fi

# Confirm Issues feature is enabled. If no issues exist yet, this still returns
# an empty array with HTTP 200 — the exit code is the truthy check.
if glab issue list --per-page 1 > /dev/null 2>&1; then
  BOARD_ENABLED=true
else
  BOARD_ENABLED=false
  echo "Issues feature disabled for $PROJECT_PATH — board status updates will be skipped."
fi

# Canonical workflow scoped-label names. A scoped label is a label with a `::`
# separator; GitLab enforces that only one label per scope can be applied to
# an issue at a time. That's what makes them behave like a Status field.
#
# The bare names (right of the `::`) are what the board columns display.
WORKFLOW_BACKLOG="workflow::backlog"
WORKFLOW_UP_NEXT="workflow::up-next"
WORKFLOW_IN_PROGRESS="workflow::in-progress"
WORKFLOW_IN_REVIEW="workflow::in-review"
WORKFLOW_ON_HOLD="workflow::on-hold"
WORKFLOW_DONE="workflow::done"
```

## Variables produced

| Variable | Used for |
|---|---|
| `PROJECT_PATH` | All subsequent `glab` calls that accept `--repo` |
| `BOARD_ENABLED` | Gate all board operations |
| `WORKFLOW_*` | Scoped labels that drive board columns |

## Project-local overrides

Projects that use different scoped-label names (e.g. `status::*` instead of `workflow::*`) should hard-code the overrides in a project-local config file so every run uses the same names. The helper accepts any scope — only the defaults above assume `workflow::*`.

## Why labels, not a Projects v2 equivalent

GitLab has **issue boards** (per-project and per-group), but they are a *view* over scoped labels — the labels are the source of truth. Flipping a column is just `glab issue edit --label`/`--unlabel`. No field IDs, no GraphQL position mutations, no item IDs. This makes the helper stateless and idempotent by construction.

GitLab does also have **Iterations** (sprint-equivalent) and **Milestones** (release-equivalent) as first-class objects. Those are handled separately — the workflow labels only track *where in the pipeline* an issue sits, not *which iteration owns it*.
