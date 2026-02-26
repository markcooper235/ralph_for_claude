# Ralph Loop - Quota Management Guide

## Overview

Ralph Loop v2 includes comprehensive quota management to handle Claude Code's context limits intelligently.

## Problem

Claude Code has context window limits (typically 200K tokens). Long Ralph runs could:
- ❌ Run out of quota mid-task
- ❌ Leave code in inconsistent state
- ❌ Waste quota on tasks that can't complete
- ❌ Require manual intervention

## Solution

Ralph Loop's quota management:
- ✅ Monitors quota usage throughout run
- ✅ Estimates cost before starting tasks
- ✅ Pauses gracefully before exhaustion
- ✅ Saves state for seamless resume
- ✅ Never starts tasks that won't finish
- ✅ Configurable limits and thresholds

> **Note:** Fine-grained quota tracking (per-phase token counts, `totalUsed` field) is aspirational — Claude agents cannot introspect their own token usage at runtime. Context cycling has been removed: the orchestrator's context footprint is ~40K tokens on a typical 8-story run, well within the 200K budget, so cycling is unnecessary. Pause/resume (for user interruption or errors), state preservation, and `/ralph-resume` all work as described.

## How It Works

### 1. Quota Tracking

Ralph tracks quota usage at multiple levels:

```
Run Level:
├── Total quota used across all phases
├── Current session usage (since last resume)
└── Phase-specific usage
    ├── Parsing: 3,000
    ├── Architecture: 4,500
    ├── Implementing: 45,000
    ├── Testing: 18,000
    └── Proving: 6,000

Story Level:
├── REQ-001: 12,000 (impl: 8,000, test: 4,000)
├── REQ-002: 15,000 (impl: 10,000, test: 5,000)
└── REQ-003: 9,000 (impl: 6,000, test: 3,000)
```

### 2. Cost Estimation

Before starting any task, Ralph estimates its cost:

**Story Cost Factors:**
- Base overhead: 1,000 tokens
- Acceptance criteria: 500 tokens each
- Estimated lines of code: 0.5 tokens/line
- Priority multiplier: high=1.2x, medium=1.0x, low=0.8x
- Dependency factor: +10% per dependency
- Test costs: unit (3K), lint (1K), UI (5K), integration (4K)

**Example:**
```
REQ-004: Password Reset
- Base: 1,000
- Acceptance criteria (4): 2,000
- Estimated code (150 lines): 75 * 0.5 = 37.5 ≈ 38
- Code complexity: 3,000
- Priority (high): 1.2x multiplier
- Dependencies (1): 1.1x multiplier
- Tests: 3,000 + 1,000 + 5,000 = 9,000

Implementation: (1,000 + 2,000 + 3,000) * 1.2 * 1.1 = 7,920
Testing: 9,000
Total: ~17,000 tokens
```

### 3. Quota Checks

**Before Each Task:**

```
[Quota Check] Task: REQ-004 (Password Reset)
[Quota Check] Estimated cost: 17,000
[Quota Check] Current usage: 155,000/200,000 (77.5%)
[Quota Check] Available: 45,000
[Quota Check] After task: 172,000/200,000 (86%)
[Quota Check] ⚠️  Would exceed safety threshold (85%)
[Quota Check] Decision: PAUSE before this task
```

**Decision Tree:**
```
Will task + reserve exceed limit?
├─ Yes → CANNOT START (pause)
└─ No → Will task exceed safety threshold (85%)?
    ├─ Yes → SHOULD PAUSE (configurable)
    └─ No → Will task exceed warning threshold (75%)?
        ├─ Yes → WARN USER (continue)
        └─ No → PROCEED (safe)
```

### 4. Graceful Pause

When quota threshold reached:

```
[Ralph Pause] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[Ralph Pause] Ralph Run PAUSED
[Ralph Pause] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[Ralph Pause]
[Ralph Pause] Reason: quota_warning (85% threshold)
[Ralph Pause] Paused at: implementing (before REQ-004)
[Ralph Pause]
[Ralph Pause] Quota Status:
[Ralph Pause] - Used: 155,000/200,000 (77.5%)
[Ralph Pause] - Estimated remaining need: ~85,000
[Ralph Pause]
[Ralph Pause] All progress has been saved:
[Ralph Pause] ✓ REQ-001: Completed and committed
[Ralph Pause] ✓ REQ-002: Completed and committed
[Ralph Pause] ✓ REQ-003: Completed and committed
[Ralph Pause] ⏸  REQ-004: Ready to start (not begun)
[Ralph Pause]
[Ralph Pause] Nothing is lost - all work preserved
[Ralph Pause]
[Ralph Pause] To resume after quota replenishment:
[Ralph Pause]   /ralph-resume
[Ralph Pause] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### 5. Resume After Replenishment

When quota is available again:

```bash
/ralph-resume

[Ralph Resume] Found paused Ralph run
[Ralph Resume] Run ID: user-auth-20260223145023
[Ralph Resume] Paused at: implementing (before REQ-004)
[Ralph Resume] Time paused: 2 hours 15 minutes
[Ralph Resume]
[Ralph Resume] Checking quota availability...
[Ralph Resume] Quota available: 185,000/200,000
[Ralph Resume] Estimated need: ~85,000
[Ralph Resume] ✓ Sufficient quota to continue
[Ralph Resume]
[Ralph Resume] Resuming execution...
[Ralph Resume] Starting REQ-004: Password Reset
```

## Configuration

### Default Configuration

Located at `ralph/.ralph-quota-config.json` (template):

```json
{
  "limits": {
    "contextWindow": 200000,        // Total context limit
    "safetyThreshold": 0.85,        // Pause at 85%
    "warningThreshold": 0.75,       // Warn at 75%
    "reserveForExit": 5000          // Reserve for cleanup
  },

  "estimation": {
    "parseSpec": 3000,
    "architecture": 4000,
    "implementStory": {
      "small": 8000,
      "medium": 15000,
      "large": 25000
    },
    "testStory": {
      "unit": 3000,
      "lint": 1000,
      "ui": 5000,
      "integration": 4000
    }
  },

  "maxIterations": {
    "enabled": false,               // Enable global iteration limits
    "global": 100,                  // Max iterations across all stories
    "perStory": 20,                 // Max iterations per story
    "warningAt": 80                 // Warn at 80% of limit
  },

  "behavior": {
    "pauseOnQuotaWarning": true,    // Pause at warning threshold
    "skipNewTasksWhenLow": true,    // Don't start new tasks when low
    "saveStateOnPause": true,       // Always save state
    "notifyUser": true              // Notify of quota status
  }
}
```

### Custom Configuration

Create `ralph/.ralph/quota-config.json` to override defaults:

```json
{
  "limits": {
    "safetyThreshold": 0.90         // More aggressive (90%)
  },
  "maxIterations": {
    "enabled": true,                // Enable iteration limits
    "global": 50                    // Limit to 50 total iterations
  }
}
```

## Max Iterations

### Purpose

Limit total iterations to conserve quota on problematic runs.

### Configuration

```json
{
  "maxIterations": {
    "enabled": true,
    "global": 100,          // Max 100 iterations total across all stories
    "perStory": 20,         // Max 20 iterations per story
    "warningAt": 80         // Warn when reaching 80 iterations
  }
}
```

### Behavior

**Global Limit:**
```
Total iterations: 85/100
[Max Iterations] ⚠️  Approaching limit (85/100)

Total iterations: 100/100
[Max Iterations] ❌ Global limit reached
[Ralph Pause] Pausing: max_iterations_global
```

**Per-Story Limit:**
```
REQ-004 iterations: 18/20
[Max Iterations] ⚠️  Story approaching limit (18/20)

REQ-004 iterations: 20/20
[Max Iterations] ❌ Story iteration limit reached
[Ralph Pause] Pausing: max_iterations_story (REQ-004)
```

### Use Cases

1. **Development on limited quota**
   - Set `global: 50` for quick prototyping
   - Prevents runaway iteration loops

2. **Testing a new spec**
   - Set `perStory: 10` to catch problematic requirements
   - Fail fast on unclear requirements

3. **CI/CD constraints**
   - Set strict limits for automated runs
   - Predictable resource usage

## Commands

### Check Quota Status

```bash
/ralph-status

[Ralph Status] Quota Status:
  - Total used: 155,000/200,000 (77.5%)
  - Session used: 45,000
  - Warning threshold: 150,000 (75%)
  - Safety threshold: 170,000 (85%)
  - Status: ⚠️  Approaching warning threshold
```

### Resume After Pause

```bash
/ralph-resume

# Checks quota availability
# Resumes from exact pause point
# Continues with quota monitoring
```

### Force Resume (Ignore Warnings)

```bash
/ralph-resume --force

[Ralph Resume] Warning: Only 25,000 quota remaining
[Ralph Resume] Estimated need: 85,000
[Ralph Resume] Forcing resume anyway...
[Ralph Resume] Run may pause again if quota exhausted
```

## Pause Scenarios

### 1. Quota Warning Threshold (75%)

```
Status: Running
Quota: 150,000/200,000 (75%)
Action: ⚠️  Warning displayed, continues
Next: Monitor closely
```

### 2. Quota Safety Threshold (85%)

```
Status: Paused (paused_quota)
Quota: 170,000/200,000 (85%)
Action: 🛑 Graceful pause before next task
Next: Wait for replenishment, then /ralph-resume
```

### 3. Quota Would Exceed with Next Task

```
Status: Paused (paused_quota)
Quota: 160,000/200,000 (80%)
Next task: 45,000 (would reach 102.5%)
Action: 🛑 Pause to prevent mid-task exhaustion
Next: Resume when quota available
```

### 4. Max Iterations Reached

```
Status: Paused (paused_iterations)
Iterations: 100/100
Action: 🛑 Pause, user intervention needed
Next: Increase limit or fix issues, then /ralph-resume --force
```

## State Preservation

### What's Saved on Pause

```
ralph/.ralph/state.json:
├── status: "paused_quota"
├── pausedAt: "2026-02-23T16:45:00Z"
├── pauseReason: "quota_safety_threshold"
├── resumePhase: "implementing"
├── currentStory: "REQ-004"
└── All completed work preserved

Git commits:
├── REQ-001: Completed ✓
├── REQ-002: Completed ✓
└── REQ-003: Completed ✓

REQ-004: Not started (clean state)
```

### Resume Behavior

```
1. Load saved state
2. Validate quota available
3. Continue from resumePhase
4. Start currentStory (if specified)
5. Continue monitoring quota
6. Can pause/resume multiple times
```

## Best Practices

### 1. Monitor Regularly

```bash
# Check status during long runs
/ralph-status

# Shows:
# - Current quota usage
# - Estimated remaining
# - Stories completed vs pending
```

### 2. Configure for Your Use Case

**Heavy development (lots of quota):**
```json
{
  "limits": {
    "safetyThreshold": 0.90         // More aggressive
  },
  "maxIterations": {
    "enabled": false                // No iteration limits
  }
}
```

**Limited quota (budget conscious):**
```json
{
  "limits": {
    "safetyThreshold": 0.80         // Conservative
  },
  "maxIterations": {
    "enabled": true,
    "global": 50,                   // Strict limit
    "perStory": 10
  }
}
```

### 3. Plan Spec Size

**Small specs (5-7 requirements):**
- Typically complete in one session
- ~100K-150K quota

**Medium specs (8-12 requirements):**
- May need 1-2 pauses
- ~150K-250K quota (spans sessions)

**Large specs (13+ requirements):**
- Plan for 2-3 pause/resume cycles
- Break into multiple smaller specs if possible

### 4. Understand Estimation

Estimates are conservative (intentionally):
- Better to pause early than mid-task
- Actual usage often lower than estimate
- Improves over time with historical data

### 5. Use Force Resume Carefully

```bash
# Only use --force if:
# 1. You understand the risks
# 2. Task is critical and small
# 3. You're okay with potential re-pause

/ralph-resume --force
```

## Troubleshooting

### "Insufficient quota" on resume

**Problem:**
```
[Ralph Resume] Error: Insufficient quota
[Ralph Resume] Need: 85,000
[Ralph Resume] Available: 30,000
```

**Solution:**
- Wait for daily quota reset
- Or use `--force` to try with reduced scope

### Frequent pauses

**Problem:** Ralph pauses every 2-3 stories

**Solutions:**
1. Increase safety threshold (more risk)
2. Reduce spec size (split into multiple PRDs)
3. Enable max iterations to catch problematic stories early

### Estimates seem high

**Problem:** Tasks estimated at 20K only use 12K

**Solution:** This is intentional - better to overestimate than run out mid-task. Estimates will improve with historical data.

## FAQ

**Q: How often does quota reset?**
A: Typically daily (check Claude Code documentation)

**Q: Can I resume multiple times?**
A: Yes, unlimited pause/resume cycles

**Q: What if I run out of quota mid-task?**
A: Ralph monitors continuously and pauses BEFORE starting tasks that won't finish

**Q: Does pause/resume affect git commits?**
A: No - each completed story is committed. Pauses only happen between stories.

**Q: Can I change quota config mid-run?**
A: Yes, edit `ralph/.ralph/quota-config.json` anytime

**Q: What happens to running subagents on pause?**
A: Current task completes, then pause. Never interrupts mid-task.

## Summary

Ralph's quota management ensures:
- ✅ No work lost to quota exhaustion
- ✅ Smart task scheduling
- ✅ Clean pause points
- ✅ Seamless resume
- ✅ Configurable limits
- ✅ Transparent monitoring

**Key principle:** Better to pause between tasks than run out mid-task.

---

**Start using quota management:**
```bash
# All quota features enabled by default
/ralph-loop ralph/specs/prds/my-feature.prd.md

# Ralph will automatically:
# - Monitor quota
# - Estimate costs
# - Pause when needed
# - Allow resume when ready
```
