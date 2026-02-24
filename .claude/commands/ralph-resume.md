# Ralph Resume - Resume Paused Ralph Run

Resume a Ralph run that was paused due to quota limits or user interruption.

## Usage

```
/ralph-resume [--force]
```

## Instructions

Resume from saved Ralph state after quota replenishment or interruption.

### 1. Check for Ralph State

```bash
if [ ! -f .ralph/state.json ]; then
  echo "[Ralph Resume] Error: No Ralph run to resume"
  echo "[Ralph Resume] No .ralph/state.json found"
  exit 1
fi
```

### 2. Load State

```bash
STATE=$(cat .ralph/state.json)
RUN_ID=$(jq -r '.runId' .ralph/state.json)
STATUS=$(jq -r '.status' .ralph/state.json)
PAUSED_AT=$(jq -r '.pausedAt // "unknown"' .ralph/state.json)
PAUSE_REASON=$(jq -r '.pauseReason // "unknown"' .ralph/state.json)
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

### 4. Check Quota Available (if paused for quota)

```bash
if [ "$PAUSE_REASON" = "quota_warning" ] || [ "$PAUSE_REASON" = "quota_limit" ]; then
  echo "[Ralph Resume] Checking quota availability..."

  # Load quota state
  QUOTA_USED=$(jq -r '.quota.totalUsed' .ralph/state.json)
  QUOTA_LIMIT=$(jq -r '.quota.limit' .ralph/state.json)
  QUOTA_AVAILABLE=$((QUOTA_LIMIT - QUOTA_USED))

  echo "[Ralph Resume] Quota used: ${QUOTA_USED}/${QUOTA_LIMIT}"
  echo "[Ralph Resume] Quota available: ${QUOTA_AVAILABLE}"

  # Check if enough quota to continue
  MIN_REQUIRED=$(jq -r '.quota.estimatedRemaining' .ralph/state.json)

  if [ "$QUOTA_AVAILABLE" -lt "$MIN_REQUIRED" ]; then
    echo "[Ralph Resume] Warning: Insufficient quota available"
    echo "[Ralph Resume] Required: ~${MIN_REQUIRED}"
    echo "[Ralph Resume] Available: ${QUOTA_AVAILABLE}"
    echo "[Ralph Resume]"
    echo "[Ralph Resume] Options:"
    echo "[Ralph Resume] 1. Wait for quota replenishment"
    echo "[Ralph Resume] 2. Use --force to try anyway (may pause again)"

    if [ "$FORCE" != "true" ]; then
      exit 1
    fi

    echo "[Ralph Resume] Forcing resume..."
  fi
fi
```

### 5. Resume from Saved Phase

**Determine resume point:**

```bash
RESUME_PHASE=$(jq -r '.resumePhase // .status' .ralph/state.json)
CURRENT_STORY=$(jq -r '.currentStory // null' .ralph/state.json)

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
   .ralph/state.json > .ralph/state.json.tmp
mv .ralph/state.json.tmp .ralph/state.json

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
- Ralph-loop will detect `.ralph/state.json` exists
- Will load state and continue from current phase
- Will respect quota limits
- Will save state on pause

### 7. Display Resume Info

```
[Ralph Resume] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[Ralph Resume] Ralph Run Resumed
[Ralph Resume] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[Ralph Resume]
[Ralph Resume] Run ID: ${RUN_ID}
[Ralph Resume] Resumed Phase: ${RESUME_PHASE}
[Ralph Resume] Time paused: ${TIME_PAUSED}
[Ralph Resume]
[Ralph Resume] Progress before pause:
[Ralph Resume] - Stories completed: X/Y
[Ralph Resume] - Tests passed: A/B
[Ralph Resume] - Quota used: ${QUOTA_USED}
[Ralph Resume]
[Ralph Resume] Continuing execution...
[Ralph Resume] Use /ralph-status to monitor progress
```

## Quota Management During Resume

**Monitor quota throughout execution:**

1. **Before each task:**
   - Estimate task cost
   - Check available quota
   - Skip task if insufficient (pause instead)

2. **During task execution:**
   - Track actual usage
   - Compare to estimate
   - Adjust future estimates

3. **After each task:**
   - Update quota usage in state
   - Check if approaching limit
   - Pause if needed

## Resume Scenarios

### Scenario 1: Paused for Quota Warning

```
Status: paused_quota
Reason: quota_warning (85% used)
Resume: Wait for quota reset, then /ralph-resume
```

### Scenario 2: Paused for Quota Limit

```
Status: paused_quota
Reason: quota_limit (approaching 95%)
Resume: Must wait for quota replenishment
```

### Scenario 3: User Interruption (Ctrl+C)

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
- ✅ Quota usage
- ✅ Git branch and commits
- ✅ Architecture decisions
- ✅ All artifacts

**What's NOT lost on pause:**
- All previous work
- Test results
- Code changes (committed)
- State files

## Examples

### Resume after quota replenishment

```bash
# Check status first
/ralph-status

# Resume when quota available
/ralph-resume

# Output:
# [Ralph Resume] Found paused Ralph run
# [Ralph Resume] Quota available: 180000/200000
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

### Force resume (ignore warnings)

```bash
/ralph-resume --force

# Output:
# [Ralph Resume] Warning: Only 15000 quota remaining
# [Ralph Resume] Estimated need: 25000
# [Ralph Resume] Forcing resume anyway...
# [Ralph Resume] May pause again if quota exhausted
```

## Integration with Ralph Loop

The `/ralph-loop` skill checks for existing state:

```bash
# In ralph-loop, before starting:
if [ -f .ralph/state.json ]; then
  STATUS=$(jq -r '.status' .ralph/state.json)
  if [[ "$STATUS" == paused_* ]]; then
    echo "Resuming from ${STATUS}"
    # Continue from saved phase
  fi
fi
```

## Quota Safety

**Ralph Resume ensures:**
- ✅ No work is lost on pause
- ✅ Can resume multiple times
- ✅ Quota checked before continuing
- ✅ User notified of quota status
- ✅ Graceful handling of quota exhaustion

## Notes

- Use `/ralph-status` to check if run is paused
- Quota resets daily (check Claude Code limits)
- Each resume continues from exact pause point
- Multiple pause/resume cycles supported
- All state preserved until `/ralph-archive`
