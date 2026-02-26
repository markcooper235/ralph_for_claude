# Ralph Resume - Resume Paused Ralph Run

Resume a Ralph run that was paused due to user interruption or error.

## Usage

```
/ralph-resume [--force]
```

## Instructions

Resume from saved Ralph state after interruption or error.

### 1. Check for Ralph State

```bash
if [ ! -f ralph/.ralph/state.json ]; then
  echo "[Ralph Resume] Error: No Ralph run to resume"
  echo "[Ralph Resume] No ralph/.ralph/state.json found"
  exit 1
fi
```

### 2. Load State

```bash
STATE=$(cat ralph/.ralph/state.json)
RUN_ID=$(jq -r '.runId' ralph/.ralph/state.json)
STATUS=$(jq -r '.status' ralph/.ralph/state.json)
PAUSED_AT=$(jq -r '.pausedAt // "unknown"' ralph/.ralph/state.json)
PAUSE_REASON=$(jq -r '.pauseReason // "unknown"' ralph/.ralph/state.json)
```

### 3. Verify Resumable

```
[Ralph Resume] Found paused Ralph run
[Ralph Resume] Run ID: ${RUN_ID}
[Ralph Resume] Status: ${STATUS}
[Ralph Resume] Paused at: ${PAUSED_AT}
[Ralph Resume] Reason: ${PAUSE_REASON}
```

**Check if resumable:**

```bash
case "$STATUS" in
  "paused_quota"|"paused_user"|"paused_error")
    echo "[Ralph Resume] Run is resumable"
    ;;
  "complete"|"ready_for_archive")
    echo "[Ralph Resume] Error: Run already complete"
    echo "[Ralph Resume] Use /ralph-archive to finish"
    exit 1
    ;;
  *)
    if [ "$FORCE" != "true" ]; then
      echo "[Ralph Resume] Warning: Run status is ${STATUS}"
      echo "[Ralph Resume] Use --force to resume anyway"
      exit 1
    fi
    ;;
esac
```

### 4. Notify if Paused for Quota

If `PAUSE_REASON` contains "quota": display a reminder that token counts are not tracked automatically — the user should verify context headroom in the Claude Code UI before continuing. Proceed regardless (no automated check possible).

```
[Ralph Resume] Note: Paused for quota — verify context headroom in Claude Code UI before continuing.
[Ralph Resume] Use --force to suppress this reminder.
```

### 5. Resume from Saved Phase

**Determine resume point:**

```bash
RESUME_PHASE=$(jq -r '.resumePhase // .status' ralph/.ralph/state.json)
CURRENT_STORY=$(jq -r '.currentStory // null' ralph/.ralph/state.json)

echo "[Ralph Resume] Resuming from phase: ${RESUME_PHASE}"
if [ "$CURRENT_STORY" != "null" ]; then
  echo "[Ralph Resume] Current story: ${CURRENT_STORY}"
fi
```

**Update state:**

```bash
# Update state.json
jq --arg now "$(date -Iseconds)" \
   '.status = .resumePhase | .resumedAt = $now | .paused = false | del(.pausedAt, .pauseReason, .resumePhase)' \
   ralph/.ralph/state.json > ralph/.ralph/state.json.tmp
mv ralph/.ralph/state.json.tmp ralph/.ralph/state.json

echo "[Ralph Resume] State updated, resuming execution..."
```

### 6. Call Ralph Loop to Resume

**Pass resume flag to ralph-loop:**

```
[Ralph Resume] Calling /ralph-loop with resume mode...

# The actual resume is handled by invoking ralph-loop
# which will detect existing state and continue from there
```

**Invoke ralph-loop:**
- Ralph-loop will detect `ralph/.ralph/state.json` exists
- Will load state and continue from current phase
- Will save state on pause

### 7. Display Resume Info

```
[Ralph Resume] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[Ralph Resume] Ralph Run Resumed
[Ralph Resume] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[Ralph Resume]
[Ralph Resume] Run ID: ${RUN_ID}
[Ralph Resume] Resumed Phase: ${RESUME_PHASE}
[Ralph Resume] Stories completed: ${COMPLETED}/${TOTAL}
[Ralph Resume]
[Ralph Resume] Continuing execution...
[Ralph Resume] Use /ralph-status to monitor progress
```

## Resume Scenarios

### Scenario 1: User Interruption (Ctrl+C)

```
Status: paused_user
Reason: user_interrupt
Resume: Can resume anytime with /ralph-resume
```

### Scenario 4: Error (with state saved)

```
Status: paused_error
Reason: test_failure (exceeded max iterations)
Resume: Fix issue, then /ralph-resume
```

## State Preservation

**What's preserved:**
- ✅ Current phase
- ✅ All completed stories with commits
- ✅ In-progress story state
- ✅ Test results and iteration counts
- ✅ Git branch and commits
- ✅ Architecture decisions
- ✅ All artifacts

**What's NOT lost on pause:**
- All previous work
- Test results
- Code changes (committed)
- State files

## Examples

### Resume after user interruption (example)

```bash
# Check status first
/ralph-status

# Resume
/ralph-resume

# Output:
# [Ralph Resume] Found paused Ralph run
# [Ralph Resume] Run ID: my-feature-20260223145023
# [Ralph Resume] Resuming from phase: implementing
# [Ralph Resume] Continuing with REQ-004...
```

### Resume after user interruption

```bash
# User pressed Ctrl+C during run
# State was saved automatically

# Later, resume:
/ralph-resume

# Output:
# [Ralph Resume] Resuming from user interruption
# [Ralph Resume] Phase: testing (REQ-003)
# [Ralph Resume] Continuing where we left off...
```

### Force resume (bypass status check)

```bash
/ralph-resume --force

# Output:
# [Ralph Resume] Warning: Run status is failed
# [Ralph Resume] Forcing resume...
```

## Integration with Ralph Loop

The `/ralph-loop` skill checks for existing state:

```bash
# In ralph-loop, before starting:
if [ -f ralph/.ralph/state.json ]; then
  STATUS=$(jq -r '.status' ralph/.ralph/state.json)
  if [[ "$STATUS" == paused_* ]]; then
    echo "Resuming from ${STATUS}"
    # Continue from saved phase
  fi
fi
```

## Safety

**Ralph Resume ensures:**
- ✅ No work is lost on pause
- ✅ Can resume multiple times
- ✅ User notified of pause reason
- ✅ All state preserved until `/ralph-archive`

## Notes

- Use `/ralph-status` to check if run is paused
- Each resume continues from exact pause point
- Multiple pause/resume cycles supported
- All state preserved until `/ralph-archive`
