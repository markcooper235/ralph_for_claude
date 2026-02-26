# Ralph Status - Check Current Ralph Run Status

Display current Ralph run status, progress, and next steps.

## Usage

```
/ralph-status
```

## Instructions

### Check for Ralph Run

```bash
if [ ! -f ralph/.ralph/state.json ]; then
  echo "No Ralph run in progress. Workspace ready."
  echo "Start: /ralph-create-prd <name> or /ralph-loop <spec>"
  exit 0
fi
```

### Load State

Read `ralph/.ralph/state.json` and `ralph/.ralph/stories.json`.

### Display Status

```
[Ralph Status] Run ID: <runId>
[Ralph Status] Spec: <specFile>
[Ralph Status] Status: <STATUS>
[Ralph Status] Started: <createdAt> | Updated: <updatedAt>
[Ralph Status]
[Ralph Status] Git: <originBranch> → <ralphBranch> (<N> commits)
[Ralph Status]
[Ralph Status] Progress: <completed>/<total> stories
[Ralph Status]   Completed: N | In Progress: N | Failed: N | Pending: N
[Ralph Status]
[Ralph Status] Stories:
  [<STATUS>] REQ-XXX: <title> (priority: <priority>)
  ...
```

### Display Next Steps

Based on status:
- `parsing` / `architecture` → "Waiting for current phase to complete"
- `implementing` → "Stories being implemented — ready: N, in progress: N"
- `testing` / `proving` → "Running tests / proving requirements"
- `ready_for_archive` / `complete` → "Run: /ralph-archive"
- `paused_user` / `paused_quota` → "Run: /ralph-resume"
- `paused_error` → "Fix issue then: /ralph-resume"
- `failed` → "Fix or abandon: /ralph-archive --abandon"

### Display Warnings

Check and report:
- Stories with status "failed" → list them
- Stories at iteration limit (logic ≥ 5 or formatting ≥ 3) → warn
- Stories with status "blocked" → list with blockedBy
