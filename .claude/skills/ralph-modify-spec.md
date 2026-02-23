# Ralph Modify Spec - Modify Specification During Run

Handle spec modifications, gaps, and clarifications discovered during implementation.

## Usage

```
/ralph-modify-spec [--add-requirements] [--change-priorities] [--update-criteria]
```

## Use Cases

1. **Gap discovered during implementation** - Missing requirements found
2. **Unclear acceptance criteria** - Need clarification/refinement
3. **Priority changes** - Reprioritize based on learnings
4. **Dependency changes** - New dependencies discovered
5. **Scope adjustments** - Add/remove/modify requirements

## Instructions

This skill allows modifying specs during a Ralph run without losing progress.

### 1. Check Current State

```bash
if [ ! -f .ralph/state.json ]; then
  echo "[Modify Spec] Error: No Ralph run in progress"
  echo "[Modify Spec] Start a run first: /ralph-loop <spec>"
  exit 1
fi

# Load current state
RUN_ID=$(jq -r '.runId' .ralph/state.json)
SPEC_FILE=$(jq -r '.specFile' .ralph/state.json)
STATUS=$(jq -r '.status' .ralph/state.json)
CURRENT_STORY=$(jq -r '.currentStory // "none"' .ralph/state.json)

echo "[Modify Spec] Current Ralph Run: ${RUN_ID}"
echo "[Modify Spec] Status: ${STATUS}"
echo "[Modify Spec] Spec: ${SPEC_FILE}"
```

### 2. Pause Current Work

```bash
if [ "$STATUS" = "implementing" ]; then
  echo "[Modify Spec] Pausing current implementation..."
  echo "[Modify Spec] Current story: ${CURRENT_STORY}"

  # Update state to paused_spec_modification
  jq --arg now "$(date -Iseconds)" \
     --arg story "$CURRENT_STORY" \
     '.status = "paused_spec_modification" |
      .paused = true |
      .pausedAt = $now |
      .pauseReason = "spec_modification" |
      .resumePhase = "implementing" |
      .currentStory = $story' \
     .ralph/state.json > .ralph/state.json.tmp
  mv .ralph/state.json.tmp .ralph/state.json

  echo "[Modify Spec] ✓ Work paused safely"
fi
```

### 3. Display Current Spec State

```bash
echo "[Modify Spec] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "[Modify Spec] Current Specification State"
echo "[Modify Spec] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Show current stories
echo "[Modify Spec]"
echo "[Modify Spec] Current Stories:"
jq -r '.stories[] |
  "[Modify Spec]   [\(.status | ascii_upcase)] \(.id): \(.title) (priority: \(.priority))"' \
  .ralph/stories.json

echo "[Modify Spec]"
echo "[Modify Spec] Progress:"
COMPLETED=$(jq -r '[.stories[] | select(.status == "completed")] | length' .ralph/stories.json)
TOTAL=$(jq -r '.stories | length' .ralph/stories.json)
echo "[Modify Spec]   Completed: ${COMPLETED}/${TOTAL}"
```

### 4. Modification Options

Present user with options:

```
[Modify Spec] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[Modify Spec] Modification Options
[Modify Spec] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[Modify Spec] What would you like to modify?
[Modify Spec]
[Modify Spec] 1. Add new requirements (discovered gap)
[Modify Spec] 2. Modify existing requirements (clarify/refine)
[Modify Spec] 3. Change priorities (reorder execution)
[Modify Spec] 4. Update acceptance criteria (add/modify/remove)
[Modify Spec] 5. Modify dependencies (add/remove dependencies)
[Modify Spec] 6. Remove requirements (out of scope)
[Modify Spec] 7. Interactive spec review (guided)
[Modify Spec]
[Modify Spec] Enter choice (1-7):
```

### 5. Add New Requirements (Option 1)

**If user chooses to add requirements:**

```
[Modify Spec] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[Modify Spec] Add New Requirements
[Modify Spec] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[Modify Spec] Current highest REQ-ID: REQ-008
[Modify Spec] New requirements will start at: REQ-009
[Modify Spec]
[Modify Spec] Describe the gap/missing requirement:
> [User input]

[Modify Spec] Priority (high/medium/low):
> [User input]

[Modify Spec] Acceptance criteria (one per line, 'done' when finished):
> [User inputs criteria]

[Modify Spec] Dependencies (existing REQ-IDs, comma-separated, or 'none'):
> [User input]

[Modify Spec] Files this will modify (for conflict detection):
> [User input or auto-detect]

[Modify Spec] Add another requirement? (y/n)
```

**For each new requirement:**

1. Assign new REQ-ID (sequential)
2. Analyze code impact
3. Detect conflicts with existing/pending stories
4. Set priority
5. Determine dependencies
6. Add to spec file
7. Add to stories.json
8. Create Claude Task
9. Update execution phases

### 6. Modify Existing Requirements (Option 2)

```
[Modify Spec] Which requirement to modify?
[Modify Spec] Enter REQ-ID:
> REQ-005

[Modify Spec] Current: REQ-005 Remember Me (priority: low)
[Modify Spec]   Status: completed
[Modify Spec]   Acceptance criteria: 3
[Modify Spec]
[Modify Spec] Warning: REQ-005 is already completed
[Modify Spec] Modifications will:
[Modify Spec]   - Revert commit for this story
[Modify Spec]   - Re-implement with new spec
[Modify Spec]   - Re-test
[Modify Spec]   - Create new commit
[Modify Spec]
[Modify Spec] Continue? (y/n)

[Modify Spec] What to modify?
[Modify Spec] 1. Title/Description
[Modify Spec] 2. Priority
[Modify Spec] 3. Acceptance criteria (add/modify/remove)
[Modify Spec] 4. Dependencies
```

### 7. Update Spec File

**Save modifications to spec file:**

```bash
# Backup original spec
SPEC_VERSION=$(jq -r '.specVersion // 1' .ralph/state.json)
NEW_VERSION=$((SPEC_VERSION + 1))
BACKUP_FILE="${SPEC_FILE}.v${SPEC_VERSION}.backup"

cp "$SPEC_FILE" "$BACKUP_FILE"
echo "[Modify Spec] ✓ Backed up original: ${BACKUP_FILE}"

# Update spec file with modifications
# ... (write new requirements, update existing)

# Add modification metadata to spec
cat >> "$SPEC_FILE" <<EOF

---
## Modification History

### Version ${NEW_VERSION} - $(date -Iseconds)
**Reason:** ${MODIFICATION_REASON}
**Modified by:** Ralph Loop (during run ${RUN_ID})

**Changes:**
${CHANGE_LIST}

**Previous version:** ${BACKUP_FILE}
EOF

echo "[Modify Spec] ✓ Spec updated to version ${NEW_VERSION}"
```

### 8. Re-analyze Dependencies and Priorities

**Launch re-planning subagent:**

```
[Modify Spec] Re-analyzing specification...

[Subagent: Replan] Loading modified spec
[Subagent: Replan] Loading current progress (${COMPLETED}/${TOTAL} completed)
[Subagent: Replan]
[Subagent: Replan] New requirements:
[Subagent: Replan]   - REQ-009: Email Verification (high)
[Subagent: Replan]   - REQ-010: Rate Limiting (medium)
[Subagent: Replan]
[Subagent: Replan] Modified requirements:
[Subagent: Replan]   - REQ-003: Updated acceptance criteria (+2 criteria)
[Subagent: Replan]
[Subagent: Replan] Analyzing dependencies...
[Subagent: Replan]   - REQ-009 depends on: REQ-001, REQ-002
[Subagent: Replan]   - REQ-010 has no dependencies
[Subagent: Replan]
[Subagent: Replan] Analyzing code conflicts...
[Subagent: Replan]   - REQ-009 modifies: auth/verify.ts (new file)
[Subagent: Replan]   - REQ-010 modifies: middleware/rate-limit.ts (new file)
[Subagent: Replan]   - REQ-003 modifies: auth/logout.ts (existing, already completed)
[Subagent: Replan]
[Subagent: Replan] Re-calculating execution phases...
```

### 9. Update Execution Plan

```
[Modify Spec] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[Modify Spec] Updated Execution Plan
[Modify Spec] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[Modify Spec] Original plan: 8 stories in 4 phases
[Modify Spec] Updated plan: 10 stories in 5 phases (+2 stories)
[Modify Spec]
[Modify Spec] Completed (no changes needed):
[Modify Spec]   ✓ REQ-001: User Login
[Modify Spec]   ✓ REQ-002: Session Management
[Modify Spec]
[Modify Spec] To be revised (modified requirements):
[Modify Spec]   ⟲ REQ-003: Logout (criteria updated, will re-implement)
[Modify Spec]
[Modify Spec] Pending (no changes):
[Modify Spec]   ⏸ REQ-004: Password Reset
[Modify Spec]   ⏸ REQ-005: Remember Me
[Modify Spec]   ... (3 more)
[Modify Spec]
[Modify Spec] New requirements:
[Modify Spec]   🆕 REQ-009: Email Verification (high)
[Modify Spec]      Dependencies: REQ-001, REQ-002 (satisfied ✓)
[Modify Spec]      Can run in: Next available phase
[Modify Spec]   🆕 REQ-010: Rate Limiting (medium)
[Modify Spec]      Dependencies: None
[Modify Spec]      Can run in: Next available phase (parallel)
[Modify Spec]
[Modify Spec] New execution plan:
[Modify Spec]
[Modify Spec] Immediate (can start now):
[Modify Spec]   - REQ-009: Email Verification (deps satisfied)
[Modify Spec]   - REQ-010: Rate Limiting (no deps, parallel)
[Modify Spec]
[Modify Spec] Next phase (after REQ-009 complete):
[Modify Spec]   - REQ-004: Password Reset (original plan)
[Modify Spec]   - REQ-005: Remember Me (original plan)
[Modify Spec]
[Modify Spec] Revision phase (after new requirements):
[Modify Spec]   - REQ-003: Logout (re-implement with new criteria)
[Modify Spec]
[Modify Spec] Final phase:
[Modify Spec]   - REQ-006, REQ-007, REQ-008 (original plan)
```

### 10. Update State and Tasks

```bash
# Update state.json
jq --arg version "$NEW_VERSION" \
   --arg modified "$(date -Iseconds)" \
   '.specVersion = ($version | tonumber) |
    .specModified = $modified |
    .specModifications += 1' \
   .ralph/state.json > .ralph/state.json.tmp
mv .ralph/state.json.tmp .ralph/state.json

# Update stories.json with new/modified stories
# ...

# Create Claude Tasks for new requirements
for NEW_REQ in $NEW_REQUIREMENTS; do
  # TaskCreate for each new requirement
  echo "[Modify Spec] ✓ Task created: ${NEW_REQ}"
done

# Update existing tasks if modified
for MODIFIED_REQ in $MODIFIED_REQUIREMENTS; do
  # TaskUpdate with new description/criteria
  echo "[Modify Spec] ✓ Task updated: ${MODIFIED_REQ}"
done

echo "[Modify Spec] ✓ Stories updated: ${TOTAL_STORIES} total"
echo "[Modify Spec] ✓ Tasks synchronized"
```

### 11. Handle Modified Completed Stories

**If modifying already-completed requirements:**

```
[Modify Spec] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[Modify Spec] Handling Completed Story Modifications
[Modify Spec] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[Modify Spec] REQ-003 was completed but now modified
[Modify Spec]
[Modify Spec] Options:
[Modify Spec] A) Revert commit, re-implement, new commit (recommended)
[Modify Spec] B) Keep original, add new commit with changes
[Modify Spec] C) Skip modification (keep as-is)
[Modify Spec]
[Modify Spec] Choice (A/B/C):
> A

[Modify Spec] Reverting commit for REQ-003...
[Modify Spec] Commit: a3b4c5d (REQ-003: Logout)
[Modify Spec] Running: git revert a3b4c5d --no-commit
[Modify Spec] ✓ Commit reverted (changes staged)

[Modify Spec] Re-opening story: REQ-003
[Modify Spec] Status: completed → pending
[Modify Spec] New criteria: Added 2 acceptance criteria
[Modify Spec] Will re-implement with updated spec

[Modify Spec] Adding to execution queue...
```

### 12. Archive Modification

```bash
# Save modification record
MODIFICATION_FILE=".ralph/artifacts/spec-modification-${SPEC_VERSION}.json"

cat > "$MODIFICATION_FILE" <<EOF
{
  "version": ${NEW_VERSION},
  "previousVersion": ${SPEC_VERSION},
  "modifiedAt": "$(date -Iseconds)",
  "reason": "${MODIFICATION_REASON}",
  "modifiedBy": "user_during_run",
  "runId": "${RUN_ID}",
  "runStatus": "${STATUS}",
  "changes": {
    "newRequirements": ${NEW_REQS_JSON},
    "modifiedRequirements": ${MODIFIED_REQS_JSON},
    "removedRequirements": ${REMOVED_REQS_JSON},
    "priorityChanges": ${PRIORITY_CHANGES_JSON},
    "dependencyChanges": ${DEPENDENCY_CHANGES_JSON}
  },
  "impact": {
    "storiesAdded": ${STORIES_ADDED},
    "storiesModified": ${STORIES_MODIFIED},
    "storiesReverted": ${STORIES_REVERTED},
    "phasesAdded": ${PHASES_ADDED},
    "executionPlanChanged": ${PLAN_CHANGED}
  }
}
EOF

echo "[Modify Spec] ✓ Modification archived: ${MODIFICATION_FILE}"
```

### 13. Resume Execution

```
[Modify Spec] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[Modify Spec] Modification Complete
[Modify Spec] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[Modify Spec] Spec updated: ${SPEC_FILE} (v${NEW_VERSION})
[Modify Spec] Backup saved: ${BACKUP_FILE}
[Modify Spec] Stories updated: ${TOTAL_STORIES} total
[Modify Spec] Tasks updated: ${TASK_COUNT} total
[Modify Spec] Execution plan: Updated
[Modify Spec]
[Modify Spec] Changes summary:
[Modify Spec]   + ${NEW_REQS_COUNT} new requirements
[Modify Spec]   ✎ ${MODIFIED_REQS_COUNT} modified requirements
[Modify Spec]   − ${REMOVED_REQS_COUNT} removed requirements
[Modify Spec]   ⟲ ${REVERTED_COUNT} completed stories to re-implement
[Modify Spec]
[Modify Spec] Ready to resume execution
[Modify Spec]
[Modify Spec] Next steps:
[Modify Spec] 1. /ralph-status (review updated plan)
[Modify Spec] 2. /ralph-resume (continue with updated spec)
[Modify Spec]
[Modify Spec] Or continue with /ralph-loop (resumes automatically)
```

### 14. Update State

```bash
# Update state to resume execution
jq --arg now "$(date -Iseconds)" \
   '.status = "implementing" |
    .paused = false |
    del(.pausedAt, .pauseReason) |
    .specModificationCompleted = $now' \
   .ralph/state.json > .ralph/state.json.tmp
mv .ralph/state.json.tmp .ralph/state.json

echo "[Modify Spec] State updated: ready to resume"
```

## Modification Scenarios

### Scenario 1: Gap Discovered Mid-Implementation

```
Story: REQ-004 (Password Reset)
Problem: Discovered we need email verification first
Action: Add REQ-009 (Email Verification) as dependency
Result: REQ-004 now blocked until REQ-009 complete
```

### Scenario 2: Acceptance Criteria Unclear

```
Story: REQ-003 (Logout)
Problem: Unclear how to handle active sessions
Action: Add 2 new acceptance criteria with details
Result: REQ-003 reverted, re-implemented with new criteria
```

### Scenario 3: Priority Change

```
Story: REQ-008 (2FA) - currently low priority
Problem: Security audit requires 2FA immediately
Action: Change priority low → high, update dependencies
Result: REQ-008 moved to earlier phase
```

### Scenario 4: Scope Reduction

```
Story: REQ-007 (OAuth Integration)
Problem: Out of scope for this release
Action: Remove REQ-007 from spec
Result: Story removed, plan updated, total 7 stories
```

## Integration with Ralph Loop

**Automatic continuation:**

After modification, `/ralph-loop` automatically:
1. Detects spec was modified (version changed)
2. Loads updated stories.json
3. Continues with updated plan
4. Uses new priorities and dependencies
5. Implements new requirements
6. Re-implements modified requirements

## Archive Includes Modification History

Final archive contains:
```
archive/user-auth-20260223152030/
├── spec/
│   ├── user-authentication.prd.md (v3 - final)
│   ├── user-authentication.prd.md.v1.backup (original)
│   ├── user-authentication.prd.md.v2.backup (first mod)
│   └── spec-modifications.md (change log)
├── artifacts/
│   ├── spec-modification-1.json (first modification)
│   └── spec-modification-2.json (second modification)
└── summary.md (includes modification summary)
```

## Safety Features

✅ **Backup before modify** - Original always preserved
✅ **Version tracking** - All versions saved
✅ **Impact analysis** - Shows what changes
✅ **Dependency validation** - Catches conflicts
✅ **Revert capability** - Can undo modifications
✅ **No work lost** - Completed stories preserved
✅ **Clean resumption** - Seamless continuation

## Examples

```bash
# During implementation, discover gap
/ralph-modify-spec --add-requirements

# Need to clarify existing requirement
/ralph-modify-spec --update-criteria REQ-005

# Reprioritize based on learnings
/ralph-modify-spec --change-priorities

# Interactive modification (recommended)
/ralph-modify-spec
```

## Notes

- Modifications can happen at any point during run
- Completed stories can be modified (will re-implement)
- All modifications archived with reasoning
- Spec versions tracked in archive
- Can modify multiple times per run
- Each modification updates execution plan
