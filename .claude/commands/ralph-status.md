# Ralph Status - Check Current Ralph Run Status

Display current Ralph run status, progress, and next steps.

## Usage

```
/ralph-status
```

## Instructions

Display detailed status of current Ralph run or confirm clean state.

### Check for Ralph Run

```bash
if [ ! -f ralph/.ralph/state.json ]; then
  echo "No Ralph run in progress"
  echo "Workspace is clean and ready for new run"
  echo ""
  echo "To start new run:"
  echo "  /ralph-create-prd <spec-name>"
  echo "  /ralph-loop ralph/specs/prds/<spec>.prd.md"
  exit 0
fi
```

### Load State

```bash
STATE=$(cat ralph/.ralph/state.json)
STORIES=$(cat ralph/.ralph/stories.json)
```

### Display Status

```
[Ralph Status] Current Ralph Run
[Ralph Status] ==================
[Ralph Status]
[Ralph Status] Run ID: $(jq -r '.runId' ralph/.ralph/state.json)
[Ralph Status] Specification: $(jq -r '.specFile' ralph/.ralph/state.json)
[Ralph Status] Status: $(jq -r '.status' ralph/.ralph/state.json | tr '[:lower:]' '[:upper:]')
[Ralph Status] Started: $(jq -r '.createdAt' ralph/.ralph/state.json)
[Ralph Status] Updated: $(jq -r '.updatedAt' ralph/.ralph/state.json)
[Ralph Status]
[Ralph Status] Git Information:
[Ralph Status] - Origin Branch: $(jq -r '.git.originBranch' ralph/.ralph/state.json)
[Ralph Status] - Ralph Branch: $(jq -r '.git.ralphBranch' ralph/.ralph/state.json)
[Ralph Status] - Commits: $(jq -r '.git.commits | length' ralph/.ralph/state.json)
[Ralph Status]
[Ralph Status] Progress:
[Ralph Status] - Total Stories: $(jq -r '.progress.totalStories' ralph/.ralph/state.json)
[Ralph Status] - Completed: $(jq -r '.progress.completedStories' ralph/.ralph/state.json)
[Ralph Status] - In Progress: $(jq -r '.progress.inProgressStories' ralph/.ralph/state.json)
[Ralph Status] - Failed: $(jq -r '.progress.failedStories' ralph/.ralph/state.json)
[Ralph Status] - Pending: $(jq -r '.progress.totalStories - .progress.completedStories - .progress.inProgressStories - .progress.failedStories' ralph/.ralph/state.json)
[Ralph Status]
[Ralph Status] Test Results:
$(jq -r '.testResults | to_entries | map("  - \(.key | ascii_upcase): \(.value.status) (iterations: \(.value.iterations)/\(if .key == "lint" or .key == "codeQuality" then 3 else 5 end))") | join("\n")' ralph/.ralph/state.json)
[Ralph Status]
[Ralph Status] Stories:
$(jq -r '.stories[] | "  [\(.status | ascii_upcase)] \(.id): \(.title) (priority: \(.priority))"' ralph/.ralph/stories.json)
```

### Display Next Steps

**Based on current status:**

```bash
STATUS=$(jq -r '.status' ralph/.ralph/state.json)

case "$STATUS" in
  "parsing")
    echo "[Ralph Status] Next: Waiting for spec parsing to complete"
    ;;
  "architecture")
    echo "[Ralph Status] Next: Waiting for architecture design"
    ;;
  "implementing")
    echo "[Ralph Status] Next: Stories being implemented in parallel"
    READY=$(jq -r '[.stories[] | select(.status == "ready")] | length' ralph/.ralph/stories.json)
    IN_PROG=$(jq -r '[.stories[] | select(.status == "in_progress")] | length' ralph/.ralph/stories.json)
    echo "[Ralph Status]   - Ready: $READY stories"
    echo "[Ralph Status]   - In progress: $IN_PROG stories"
    ;;
  "testing")
    echo "[Ralph Status] Next: Running comprehensive tests"
    ;;
  "proving")
    echo "[Ralph Status] Next: Proving all requirements met"
    ;;
  "harvesting")
    echo "[Ralph Status] Next: Collecting feedback"
    ;;
  "ready_for_archive"|"complete")
    echo "[Ralph Status] Next: Archive and merge"
    echo "[Ralph Status]   /ralph-archive"
    ;;
  "failed")
    echo "[Ralph Status] Status: FAILED"
    echo "[Ralph Status] Options:"
    echo "[Ralph Status]   - Fix issues and resume"
    echo "[Ralph Status]   - Abandon run: /ralph-archive --abandon"
    ;;
esac
```

### Display Warnings

**Check for issues:**

```bash
# Failed stories
FAILED=$(jq -r '[.stories[] | select(.status == "failed")] | length' ralph/.ralph/stories.json)
if [ "$FAILED" -gt 0 ]; then
  echo ""
  echo "[Ralph Status] ⚠ WARNING: $FAILED failed stories"
  jq -r '.stories[] | select(.status == "failed") | "  - \(.id): \(.title)"' ralph/.ralph/stories.json
fi

# Iteration limits
jq -r '.stories[] | select(.iterations.logic >= 5 or .iterations.formatting >= 3) | "[Ralph Status] ⚠ WARNING: \(.id) at iteration limit (logic: \(.iterations.logic)/5, format: \(.iterations.formatting)/3)"' ralph/.ralph/stories.json

# Blocked stories
BLOCKED=$(jq -r '[.stories[] | select(.status == "blocked")] | length' ralph/.ralph/stories.json)
if [ "$BLOCKED" -gt 0 ]; then
  echo ""
  echo "[Ralph Status] ⚠ WARNING: $BLOCKED blocked stories"
  jq -r '.stories[] | select(.status == "blocked") | "  - \(.id): \(.title) (blocked by: \(.blockedBy | join(", ")))"' ralph/.ralph/stories.json
fi
```

### File Locations

```
[Ralph Status]
[Ralph Status] State Files:
[Ralph Status] - Main state: ralph/.ralph/state.json
[Ralph Status] - Stories: ralph/.ralph/stories.json
[Ralph Status] - Architecture: ralph/.ralph/architecture.json
[Ralph Status] - Logs: ralph/.ralph/logs/
[Ralph Status] - Artifacts: ralph/.ralph/artifacts/
```

## Examples

**No run in progress:**
```
[Ralph Status] No Ralph run in progress
[Ralph Status] Workspace is clean and ready for new run
[Ralph Status]
[Ralph Status] To start new run:
[Ralph Status]   /ralph-create-prd <spec-name>
[Ralph Status]   /ralph-loop ralph/specs/prds/<spec>.prd.md
```

**Run in progress:**
```
[Ralph Status] Current Ralph Run
[Ralph Status] ==================
[Ralph Status]
[Ralph Status] Run ID: user-auth-20260223145023
[Ralph Status] Specification: ralph/specs/prds/user-auth.prd.md
[Ralph Status] Status: IMPLEMENTING
[Ralph Status] Started: 2026-02-23T14:50:23Z
[Ralph Status] Updated: 2026-02-23T15:05:41Z
[Ralph Status]
[Ralph Status] Git Information:
[Ralph Status] - Origin Branch: main
[Ralph Status] - Ralph Branch: ralph/user-auth-20260223145023
[Ralph Status] - Commits: 3
[Ralph Status]
[Ralph Status] Progress:
[Ralph Status] - Total Stories: 8
[Ralph Status] - Completed: 3
[Ralph Status] - In Progress: 2
[Ralph Status] - Failed: 0
[Ralph Status] - Pending: 3
[Ralph Status]
[Ralph Status] Test Results:
[Ralph Status]   - LINT: passed (iterations: 1/3)
[Ralph Status]   - UNIT: passed (iterations: 2/5)
[Ralph Status]   - UI: passed (iterations: 1/5)
[Ralph Status]   - CODEQUALITY: passed (iterations: 1/3)
[Ralph Status]
[Ralph Status] Stories:
[Ralph Status]   [COMPLETED] REQ-001: User Login (priority: high)
[Ralph Status]   [COMPLETED] REQ-002: Session Management (priority: high)
[Ralph Status]   [COMPLETED] REQ-003: Logout (priority: high)
[Ralph Status]   [IN_PROGRESS] REQ-004: Password Reset (priority: medium)
[Ralph Status]   [IN_PROGRESS] REQ-005: Email Verification (priority: medium)
[Ralph Status]   [READY] REQ-006: Remember Me (priority: low)
[Ralph Status]   [PENDING] REQ-007: OAuth Integration (priority: low)
[Ralph Status]   [PENDING] REQ-008: Two-Factor Auth (priority: low)
[Ralph Status]
[Ralph Status] Next: Stories being implemented in parallel
[Ralph Status]   - Ready: 1 stories
[Ralph Status]   - In progress: 2 stories
```

## Notes

- Quickly check current run status
- Identify blocked or failed stories
- See iteration counts approaching limits
- Know what's next in the loop
