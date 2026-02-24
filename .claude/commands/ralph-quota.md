# Ralph Quota - Quota Management and Estimation

Manage context quota limits, estimate costs, and make smart decisions about task execution.

## Purpose

This is a utility skill used internally by other Ralph skills to:
- Track quota usage
- Estimate task costs
- Decide when to pause
- Prevent mid-task quota exhaustion

## Quota Tracking

**Initialize quota tracking:**

```bash
# Load or create quota config
if [ -f ralph/.ralph/quota-config.json ]; then
  QUOTA_CONFIG=$(cat ralph/.ralph/quota-config.json)
else
  cp ralph/.ralph-quota-config.json ralph/.ralph/quota-config.json
  QUOTA_CONFIG=$(cat ralph/.ralph/quota-config.json)
fi

QUOTA_LIMIT=$(jq -r '.limits.contextWindow' ralph/.ralph/quota-config.json)
SAFETY_THRESHOLD=$(jq -r '.limits.safetyThreshold' ralph/.ralph/quota-config.json)
WARNING_THRESHOLD=$(jq -r '.limits.warningThreshold' ralph/.ralph/quota-config.json)
```

## Cost Estimation

**Estimate story implementation cost:**

```python
def estimate_story_cost(story):
    """Estimate quota cost for implementing a story."""

    base_cost = 1000  # Base overhead

    # Acceptance criteria count
    criteria_cost = len(story['acceptanceCriteria']) * 500

    # Code complexity (estimate lines of code)
    if 'codeImpact' in story:
        file_count = len(story['codeImpact']['files'])
        loc_estimate = file_count * 50  # avg 50 lines per file
        code_cost = loc_estimate * 0.5  # 0.5 tokens per LOC estimate
    else:
        code_cost = 3000  # default

    # Priority factor
    priority_factor = {
        'high': 1.2,    # high priority might be more complex
        'medium': 1.0,
        'low': 0.8
    }.get(story.get('priority', 'medium'), 1.0)

    # Dependency factor (more deps = more context needed)
    dep_factor = 1 + (len(story.get('dependencies', [])) * 0.1)

    # Calculate implementation cost
    impl_cost = (base_cost + criteria_cost + code_cost) * priority_factor * dep_factor

    # Test costs
    test_costs = {
        'unit': 3000,
        'lint': 1000,
        'ui': story.get('requiresUI', False) * 5000,
        'integration': 4000,
        'codeQuality': 2000
    }

    total_test_cost = sum(test_costs.values())

    # Total cost
    total = impl_cost + total_test_cost

    # Size category
    if total < 10000:
        size = 'small'
    elif total < 20000:
        size = 'medium'
    else:
        size = 'large'

    return {
        'total': int(total),
        'implementation': int(impl_cost),
        'testing': int(total_test_cost),
        'size': size,
        'breakdown': test_costs
    }
```

**Estimate phase costs:**

```python
def estimate_phase_cost(stories, phase_type):
    """Estimate cost for a phase of parallel stories."""

    if phase_type == 'parallel':
        # Parallel execution: max of story costs (they run concurrently)
        # Plus some overhead for coordination
        max_cost = max(estimate_story_cost(s)['total'] for s in stories)
        overhead = 1000 * len(stories)
        return max_cost + overhead
    else:
        # Sequential: sum of story costs
        return sum(estimate_story_cost(s)['total'] for s in stories) + 1000
```

## Quota Checks

**Check if task can start:**

```bash
check_quota_before_task() {
    local task_type=$1
    local estimated_cost=$2

    # Get current quota usage
    local used=$(jq -r '.quota.totalUsed' ralph/.ralph/state.json)
    local limit=$(jq -r '.quota.limit' ralph/.ralph/state.json)
    local available=$((limit - used))
    local safety=$((limit * 85 / 100))  # 85% safety threshold

    # Reserve for exit operations
    local reserve=$(jq -r '.limits.reserveForExit' ralph/.ralph/quota-config.json)
    local effective_available=$((available - reserve))

    echo "[Quota Check] Task: ${task_type}"
    echo "[Quota Check] Estimated cost: ${estimated_cost}"
    echo "[Quota Check] Available quota: ${available}/${limit}"
    echo "[Quota Check] Effective available: ${effective_available}"

    # Decision logic
    if [ $((used + estimated_cost)) -gt $limit ]; then
        echo "[Quota Check] ❌ Would exceed quota limit"
        return 1  # Cannot start
    fi

    if [ $((used + estimated_cost)) -gt $safety ]; then
        echo "[Quota Check] ⚠️  Would exceed safety threshold (85%)"
        echo "[Quota Check] Recommend pausing before this task"
        return 2  # Should pause first
    fi

    if [ $estimated_cost -gt $effective_available ]; then
        echo "[Quota Check] ❌ Insufficient quota (need reserve for exit)"
        return 1  # Cannot start
    fi

    echo "[Quota Check] ✓ Safe to proceed"
    return 0  # Can start
}
```

**Monitor quota during execution:**

```bash
update_quota_usage() {
    local phase=$1
    local actual_cost=$2

    # Update state.json
    jq --arg phase "$phase" \
       --arg cost "$actual_cost" \
       --arg now "$(date -Iseconds)" \
       '.quota.totalUsed += ($cost | tonumber) |
        .quota.currentSessionUsed += ($cost | tonumber) |
        .quota.phaseUsage[$phase] += ($cost | tonumber) |
        .quota.lastCheck = $now' \
       ralph/.ralph/state.json > ralph/.ralph/state.json.tmp
    mv ralph/.ralph/state.json.tmp ralph/.ralph/state.json

    # Check thresholds
    local total_used=$(jq -r '.quota.totalUsed' ralph/.ralph/state.json)
    local limit=$(jq -r '.quota.limit' ralph/.ralph/state.json)
    local warning=$(jq -r '.quota.warningThreshold' ralph/.ralph/state.json)
    local safety=$(jq -r '.quota.safetyThreshold' ralph/.ralph/state.json)

    if [ $total_used -gt $safety ]; then
        echo "[Quota Monitor] 🚨 SAFETY THRESHOLD EXCEEDED"
        return 2  # Must pause
    elif [ $total_used -gt $warning ]; then
        echo "[Quota Monitor] ⚠️  Warning threshold exceeded"
        return 1  # Should consider pausing
    fi

    return 0  # OK
}
```

## Pause Decision

**Decide if should pause:**

```bash
should_pause_for_quota() {
    local next_task_cost=$1

    # Get quota state
    local used=$(jq -r '.quota.totalUsed' ralph/.ralph/state.json)
    local limit=$(jq -r '.quota.limit' ralph/.ralph/state.json)
    local safety=$(jq -r '.quota.safetyThreshold' ralph/.ralph/state.json)

    local available=$((limit - used))
    local percent_used=$((used * 100 / limit))

    echo "[Pause Decision] Quota used: ${percent_used}%"

    # Already exceeded safety threshold
    if [ $used -gt $safety ]; then
        echo "[Pause Decision] ✓ Pause: Safety threshold exceeded"
        return 0  # Yes, pause
    fi

    # Next task would exceed safety
    if [ $((used + next_task_cost)) -gt $safety ]; then
        echo "[Pause Decision] ✓ Pause: Next task would exceed safety"
        return 0  # Yes, pause
    fi

    # Check if behavior config says to pause on warning
    local pause_on_warning=$(jq -r '.behavior.pauseOnQuotaWarning' ralph/.ralph/quota-config.json)
    local warning=$(jq -r '.quota.warningThreshold' ralph/.ralph/state.json)

    if [ "$pause_on_warning" = "true" ] && [ $used -gt $warning ]; then
        echo "[Pause Decision] ✓ Pause: Warning threshold + pauseOnQuotaWarning enabled"
        return 0  # Yes, pause
    fi

    echo "[Pause Decision] ✗ Continue: Quota sufficient"
    return 1  # No, don't pause
}
```

## Pause Execution

**Gracefully pause Ralph run:**

```bash
pause_ralph_run() {
    local reason=$1  # quota_warning, quota_limit, user_request, error
    local current_phase=$2
    local current_story=$3

    echo "[Ralph Pause] Pausing Ralph run"
    echo "[Ralph Pause] Reason: ${reason}"
    echo "[Ralph Pause] Current phase: ${current_phase}"

    # Save current phase for resume
    jq --arg reason "$reason" \
       --arg phase "$current_phase" \
       --arg story "$current_story" \
       --arg now "$(date -Iseconds)" \
       '.status = "paused_quota" |
        .paused = true |
        .pausedAt = $now |
        .pauseReason = $reason |
        .resumePhase = $phase |
        .currentStory = $story' \
       ralph/.ralph/state.json > ralph/.ralph/state.json.tmp
    mv ralph/.ralph/state.json.tmp ralph/.ralph/state.json

    # Calculate estimated quota needed to complete
    local remaining_stories=$(jq -r '[.stories[] | select(.status != "completed")] | length' ralph/.ralph/stories.json)
    local avg_story_cost=15000  # rough average
    local estimated_remaining=$((remaining_stories * avg_story_cost))

    jq --arg est "$estimated_remaining" \
       '.quota.estimatedRemaining = ($est | tonumber)' \
       ralph/.ralph/state.json > ralph/.ralph/state.json.tmp
    mv ralph/.ralph/state.json.tmp ralph/.ralph/state.json

    # Display pause information
    echo ""
    echo "[Ralph Pause] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "[Ralph Pause] Ralph Run PAUSED"
    echo "[Ralph Pause] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "[Ralph Pause]"
    echo "[Ralph Pause] Reason: ${reason}"
    echo "[Ralph Pause] Paused at: ${current_phase}"
    if [ -n "$current_story" ]; then
        echo "[Ralph Pause] Current story: ${current_story}"
    fi
    echo "[Ralph Pause]"

    local used=$(jq -r '.quota.totalUsed' ralph/.ralph/state.json)
    local limit=$(jq -r '.quota.limit' ralph/.ralph/state.json)
    local percent=$((used * 100 / limit))

    echo "[Ralph Pause] Quota Status:"
    echo "[Ralph Pause] - Used: ${used}/${limit} (${percent}%)"
    echo "[Ralph Pause] - Estimated remaining need: ~${estimated_remaining}"
    echo "[Ralph Pause]"
    echo "[Ralph Pause] All progress has been saved"
    echo "[Ralph Pause] Nothing is lost - all commits preserved"
    echo "[Ralph Pause]"
    echo "[Ralph Pause] To resume after quota replenishment:"
    echo "[Ralph Pause]   /ralph-resume"
    echo "[Ralph Pause]"
    echo "[Ralph Pause] To check status:"
    echo "[Ralph Pause]   /ralph-status"
    echo "[Ralph Pause] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # Save pause log
    mkdir -p ralph/.ralph/logs
    echo "[$(date -Iseconds)] Paused: ${reason} at ${current_phase}" >> ralph/.ralph/logs/pause-resume.log

    # Exit gracefully
    exit 0
}
```

## Max Iterations Tracking

**Track global iterations:**

```bash
check_max_iterations() {
    local iteration_type=$1  # story, logic, formatting, global

    # Check if max iterations enabled
    local enabled=$(jq -r '.maxIterations.enabled' ralph/.ralph/state.json)
    if [ "$enabled" != "true" ]; then
        return 0  # No limit
    fi

    # Get current count and limit
    local current=$(jq -r ".maxIterations.${iteration_type}_count // 0" ralph/.ralph/state.json)
    local limit=$(jq -r ".maxIterations.${iteration_type}" ralph/.ralph/state.json)

    if [ "$limit" = "null" ] || [ -z "$limit" ]; then
        return 0  # No limit for this type
    fi

    echo "[Max Iterations] ${iteration_type}: ${current}/${limit}"

    if [ $current -ge $limit ]; then
        echo "[Max Iterations] ❌ Limit reached"
        return 1  # Limit reached
    fi

    # Warning at 80%
    local warning=$((limit * 80 / 100))
    if [ $current -ge $warning ]; then
        echo "[Max Iterations] ⚠️  Approaching limit (${current}/${limit})"
    fi

    return 0  # OK to continue
}

increment_iteration_count() {
    local iteration_type=$1

    jq --arg type "$iteration_type" \
       '.maxIterations[($type + "_count")] += 1' \
       ralph/.ralph/state.json > ralph/.ralph/state.json.tmp
    mv ralph/.ralph/state.json.tmp ralph/.ralph/state.json
}
```

## Usage in Ralph Loop

**Before starting a story:**

```bash
# Estimate cost
STORY_COST=$(estimate_story_cost "$STORY")

# Check quota
check_quota_before_task "story_${STORY_ID}" "$STORY_COST"
QUOTA_CHECK=$?

if [ $QUOTA_CHECK -eq 1 ]; then
    # Cannot start - pause
    pause_ralph_run "quota_limit" "implementing" "$STORY_ID"
elif [ $QUOTA_CHECK -eq 2 ]; then
    # Should pause first
    if should_pause_for_quota "$STORY_COST"; then
        pause_ralph_run "quota_warning" "implementing" "$STORY_ID"
    fi
fi

# Check max iterations
check_max_iterations "global"
if [ $? -ne 0 ]; then
    pause_ralph_run "max_iterations" "implementing" "$STORY_ID"
fi

# OK to proceed
echo "Starting story ${STORY_ID}..."
```

**After completing a task:**

```bash
# Update quota usage with actual cost
ACTUAL_COST=12345  # from subagent execution
update_quota_usage "implementing" "$ACTUAL_COST"

# Check if should pause after this task
if [ $? -eq 2 ]; then
    pause_ralph_run "quota_safety" "implementing" "completed_${STORY_ID}"
fi
```

## Configuration

Users can customize in `ralph/.ralph/quota-config.json`:

```json
{
  "limits": {
    "contextWindow": 200000,      // Total context limit
    "safetyThreshold": 0.85,      // 85% = pause
    "warningThreshold": 0.75      // 75% = warn
  },
  "maxIterations": {
    "enabled": true,              // Enable iteration limits
    "global": 100,                // Max 100 total iterations
    "perStory": 20,              // Max 20 iterations per story
    "warningAt": 80              // Warn at 80 iterations
  }
}
```

## Benefits

✅ **No work lost**: Pause before quota exhaustion
✅ **Smart scheduling**: Don't start tasks that won't finish
✅ **Transparent**: User always knows quota status
✅ **Configurable**: Adjust thresholds and limits
✅ **Resume friendly**: Clean pause points for easy resume
