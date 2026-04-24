# Status-transition helper (GitLab)

Used by `/ship-next`, `/ship-refactor`, and `/ship-debug`. Provides an idempotent, verified workflow flip with a never-backward guard.

Because GitLab issue boards are driven by scoped labels (`workflow::in-progress` etc.), a status flip is just: remove the current workflow label, add the target workflow label. GitLab's scoped-label constraint guarantees only one `workflow::*` label can exist on an issue at a time, so there's no race-y mid-state.

## Required variables in scope

| Variable | Source |
|---|---|
| `PROJECT_PATH` | Project discovery block |
| `TARGET_WORKFLOW` | The destination scoped label (e.g. `workflow::in-progress`) |
| `TARGET_NAME` | Human label for logs (e.g. `"In Progress"`) |
| `ISSUE_NUMBER` | The issue being moved |

## Helper

```bash
# flip_status: set a single issue's workflow scope.
# Requires: PROJECT_PATH, TARGET_WORKFLOW, TARGET_NAME, ISSUE_NUMBER
# Assumes scoped-label constraint enforcement is enabled on the project.

# 1. Read current workflow label.
CURRENT=$(glab issue view "$ISSUE_NUMBER" -F json \
  | jq -r '[.labels[] | select(startswith("workflow::"))] | .[0] // empty')

if [ "$CURRENT" = "$TARGET_WORKFLOW" ]; then
  echo "status unchanged for #$ISSUE_NUMBER (already $TARGET_NAME)"
else
  # 2. Never-backward-flip guard.
  #    Forward order: backlog < up-next < in-progress < in-review < done.
  #    on-hold is lateral from any non-done state.
  #    done is terminal — only humans move items out of done.
  #    If the requested flip would move backward, STOP and surface the request.
  #    Do not silently override a state a human may have set deliberately.
  rank() {
    case "$1" in
      workflow::backlog)      echo 0 ;;
      workflow::up-next)      echo 1 ;;
      workflow::in-progress)  echo 2 ;;
      workflow::in-review)    echo 3 ;;
      workflow::done)         echo 4 ;;
      workflow::on-hold|"")   echo -1 ;;
      *)                      echo -1 ;;
    esac
  }
  CUR_RANK=$(rank "$CURRENT")
  TGT_RANK=$(rank "$TARGET_WORKFLOW")
  if [ "$CUR_RANK" -ge 0 ] && [ "$TGT_RANK" -lt "$CUR_RANK" ] \
       && [ "$TARGET_WORKFLOW" != "workflow::on-hold" ]; then
    echo "REFUSING: backward flip #$ISSUE_NUMBER ($CURRENT → $TARGET_WORKFLOW). Surface to operator." >&2
    return 1
  fi

  # 3. Flip — remove the current workflow label (if any), add the target.
  if [ -n "$CURRENT" ]; then
    glab issue edit "$ISSUE_NUMBER" --unlabel "$CURRENT" > /dev/null
  fi
  glab issue edit "$ISSUE_NUMBER" --label "$TARGET_WORKFLOW" > /dev/null

  # 4. Re-query to verify the mutation landed. Label writes can race with
  #    webhook-driven automations; verification is cheap and catches it.
  VERIFIED=$(glab issue view "$ISSUE_NUMBER" -F json \
    | jq -r '[.labels[] | select(startswith("workflow::"))] | .[0] // empty')
  if [ "$VERIFIED" != "$TARGET_WORKFLOW" ]; then
    echo "FATAL: #$ISSUE_NUMBER status flip to $TARGET_NAME did not persist (got: $VERIFIED)" >&2
    exit 1
  fi
  echo "status: #$ISSUE_NUMBER → $TARGET_NAME"
fi
```

## Label ↔ Status invariant

The `workflow::in-progress` label **is** the status — there is no separate signal to drift. That's an advantage over trackers where a label and a board column can fall out of sync.

What can still drift:
- **Workflow label on a closed issue.** When an issue is closed via MR-merge or manual close, nothing automatically strips the workflow label. Always flip to `workflow::done` as part of close-out. `/groom` repairs this drift every pass.
- **Multiple workflow labels.** Scoped-label enforcement prevents this at write time *if enabled* on the project. Projects that were created before scoped-label enforcement was standard may permit multiple — check the project setting `enforce_scoped_labels` during `/tracker-init`.

## Why this is simpler than the Projects v2 equivalent

No project ID, no field ID, no single-select option IDs, no GraphQL mutations, no item-by-item position logic. GitLab's scoped labels collapse all of that into two label ops plus a verify read.
