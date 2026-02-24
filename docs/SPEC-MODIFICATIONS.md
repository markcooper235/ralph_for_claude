# Ralph Loop - Specification Modifications During Run

## Overview

Real-world development requires flexibility. Requirements evolve, gaps are discovered, and priorities shift. Ralph Loop allows modifying specifications **during execution** without losing progress.

## Why This Matters

**Traditional approach:**
- Discover gap → Abandon run → Update spec → Start over → Lose all progress ❌

**Ralph Loop approach:**
- Discover gap → Pause → Modify spec → Resume → Keep all progress ✅

## When to Modify Specs

### 1. Gap Discovered
**Scenario:** Implementing REQ-004, realize REQ-009 needed first

**Action:**
```bash
/ralph-modify-spec --add-requirements
```

**Outcome:**
- REQ-009 added with dependencies
- REQ-004 now depends on REQ-009
- Execution plan updated
- REQ-009 implemented before REQ-004

### 2. Unclear Acceptance Criteria
**Scenario:** REQ-003 criteria ambiguous, can't implement

**Action:**
```bash
/ralph-modify-spec --update-criteria REQ-003
```

**Outcome:**
- Add 2 clarifying criteria
- If already completed: revert and re-implement
- If pending: update before implementation

### 3. Priority Change
**Scenario:** Business decides 2FA is urgent (was low priority)

**Action:**
```bash
/ralph-modify-spec --change-priorities
```

**Outcome:**
- REQ-008 (2FA): low → high
- Moved to earlier phase
- Dependencies checked
- Execution plan reordered

### 4. Dependency Discovered
**Scenario:** REQ-007 actually needs REQ-005 complete first

**Action:**
```bash
/ralph-modify-spec --update-dependencies
```

**Outcome:**
- Add REQ-005 as dependency of REQ-007
- REQ-007 blocked until REQ-005 done
- Phases adjusted

### 5. Scope Change
**Scenario:** Feature cut from release

**Action:**
```bash
/ralph-modify-spec --remove-requirements
```

**Outcome:**
- Requirement removed from spec
- Story removed from plan
- Total stories count updated

## Modification Process

### Step-by-Step Flow

```
1. Working on implementation
   ↓
2. Discover gap/issue
   ↓
3. /ralph-modify-spec
   ├─ Current work paused
   ├─ Spec backed up (v1 → v1.backup)
   ├─ Interactive modification
   ├─ Spec updated (v2)
   ├─ Dependencies re-analyzed
   ├─ Execution plan updated
   ├─ Tasks updated
   └─ Modification archived
   ↓
4. /ralph-resume (or continues automatically)
   ↓
5. Implementation continues with updated spec
   ↓
6. Archive includes all spec versions
```

### Visual Example

**Original Spec (v1):**
```
REQ-001: User Login ✓ (completed)
REQ-002: Session Management ✓ (completed)
REQ-003: Logout ⏸ (pending)
REQ-004: Password Reset ⏸ (pending)
```

**Gap Discovered:** Need email verification before password reset

**Modified Spec (v2):**
```
REQ-001: User Login ✓ (completed, no change)
REQ-002: Session Management ✓ (completed, no change)
REQ-003: Logout ⏸ (pending, no change)
REQ-004: Password Reset ⏸ (now depends on REQ-009)
REQ-009: Email Verification 🆕 (new, high priority, deps: REQ-001, REQ-002)
```

**New Execution Plan:**
```
Phase 3 (immediate):
  - REQ-009: Email Verification (new, deps satisfied)

Phase 4 (after REQ-009):
  - REQ-003: Logout (original plan)
  - REQ-004: Password Reset (now unblocked)
```

## Commands

### Full Modification (Interactive)
```bash
/ralph-modify-spec
```
Presents menu of options, walks through modification process.

### Quick Add Requirement
```bash
/ralph-add-requirement "Email verification" --priority=high --depends-on=REQ-001,REQ-002
```
Fast way to add single requirement.

### Specific Modifications
```bash
# Add multiple requirements
/ralph-modify-spec --add-requirements

# Update criteria
/ralph-modify-spec --update-criteria REQ-003

# Change priorities
/ralph-modify-spec --change-priorities

# Update dependencies
/ralph-modify-spec --update-dependencies REQ-004
```

## Handling Completed Stories

### If Modified Story Already Completed

**Options:**

**A) Revert and Re-implement (Recommended)**
```
1. Revert commit for story
2. Update spec with new criteria
3. Re-implement with updated spec
4. Re-test with new criteria
5. Create new commit
```

**B) Add New Commit**
```
1. Keep original commit
2. Add new commit with changes
3. Both commits in history
```

**C) Skip Modification**
```
1. Keep as-is
2. Mark as "completed with original spec"
3. Add note about spec version
```

### Example: Revert and Re-implement

```
[Modify Spec] REQ-003 completed but modified

Original commit: a3b4c5d (REQ-003: Logout)
Original criteria: 2 acceptance criteria
New criteria: 4 acceptance criteria (+2)

[Modify Spec] Reverting a3b4c5d...
[Modify Spec] ✓ Reverted (unstaged changes)
[Modify Spec] Updating story: completed → pending
[Modify Spec] Adding to execution queue
[Modify Spec] Will re-implement with 4 criteria

When re-implemented:
  New commit: x7y8z9a (REQ-003: Logout [revised v2])
  Git history:
    a3b4c5d REQ-003: Logout
    b4c5d6e Revert "REQ-003: Logout"
    x7y8z9a REQ-003: Logout [revised v2]
```

## Spec Versioning

### Version Tracking

Every modification increments spec version:

```
v1: Original spec (from /ralph-create-prd)
v2: First modification (added REQ-009)
v3: Second modification (updated REQ-003 criteria)
```

### Backup Files

```
ralph/specs/prds/user-authentication.prd.md              # v3 (current)
ralph/specs/prds/user-authentication.prd.md.v1.backup    # Original
ralph/specs/prds/user-authentication.prd.md.v2.backup    # First mod
```

### Modification Metadata

Each spec includes modification history:

```markdown
---
## Modification History

### Version 2 - 2026-02-23T16:30:00Z
**Reason:** Gap discovered - email verification needed
**Modified by:** Ralph Loop (during run user-authentication-20260223152030)
**Phase:** Implementing (REQ-004)

**Changes:**
- Added: REQ-009 Email Verification (high priority)
- Updated dependencies: REQ-004 now depends on REQ-009
- Execution plan: Added Phase 3 for REQ-009

**Previous version:** user-authentication.prd.md.v1.backup

### Version 3 - 2026-02-23T17:15:00Z
**Reason:** Acceptance criteria clarification
**Modified by:** Ralph Loop (during run user-authentication-20260223152030)
**Phase:** Testing (REQ-003 failed, criteria unclear)

**Changes:**
- Modified: REQ-003 acceptance criteria (+2 criteria)
- Reverted: REQ-003 commit a3b4c5d
- Status: REQ-003 completed → pending
- Will re-implement: With updated 4 criteria

**Previous version:** user-authentication.prd.md.v2.backup
```

## Archive Includes All Versions

### Archive Structure

```
ralph/archive/user-authentication-20260223152030/
├── spec/
│   ├── user-authentication.prd.md              # v3 (final)
│   ├── user-authentication.prd.md.v1.backup    # Original
│   ├── user-authentication.prd.md.v2.backup    # First mod
│   ├── spec-modifications.md                   # Change log
│   └── modification-history.json               # Machine-readable
├── artifacts/
│   ├── spec-modification-1.json                # First mod details
│   ├── spec-modification-2.json                # Second mod details
│   └── ...
├── summary.md                                  # Includes mod summary
└── ...
```

### Summary Includes Modifications

```markdown
# Ralph Loop Run Summary

## Specification Modifications

**Modifications during run:** 2

### Modification 1 - Version 2
- **When:** 2026-02-23T16:30:00Z (Phase: Implementing REQ-004)
- **Reason:** Gap discovered - email verification needed
- **Impact:** +1 requirement, +1 phase, +15K estimated quota
- **Changes:**
  - Added: REQ-009 Email Verification
  - Updated: REQ-004 dependencies

### Modification 2 - Version 3
- **When:** 2026-02-23T17:15:00Z (Phase: Testing REQ-003)
- **Reason:** Acceptance criteria unclear
- **Impact:** 1 story reverted and re-implemented
- **Changes:**
  - Modified: REQ-003 criteria (+2)
  - Reverted: commit a3b4c5d
  - Re-implemented: with 4 criteria total
```

## Impact on Execution

### Quota Impact

Modifications may affect quota:

```
Original estimate: 145K tokens (8 requirements)
After adding REQ-009: 160K tokens (9 requirements)
After revising REQ-003: 165K tokens (re-implementation)

Quota tracking:
- Original plan: 145K
- Modifications: +20K
- Total: 165K
- May require additional pause/resume cycle
```

### Timeline Impact

```
Original timeline: 45 minutes active time
+ REQ-009 implementation: +12 minutes
+ REQ-003 re-implementation: +8 minutes
New timeline: 65 minutes active time
```

### Phase Impact

```
Original: 4 phases
After modification: 5 phases (+1 for REQ-009)

Phase schedule adjusted:
- Phases 1-2: Unchanged (already completed)
- Phase 3: NEW (REQ-009)
- Phase 4: Original Phase 3 (now includes REQ-004 unblocked)
- Phase 5: Original Phase 4
```

## Best Practices

### 1. Modify Early
Better to discover gaps early than late. Don't hesitate to modify spec when issues found.

### 2. Document Reasoning
Always provide clear reason for modification. Helps future reference.

### 3. Check Dependencies
After adding requirements, verify dependencies are correct.

### 4. Update Priorities
Use modification to reprioritize based on learnings.

### 5. Archive Review
Review modification history in archive to learn patterns.

## Safety Features

✅ **Automatic backups** - Original always preserved
✅ **Version tracking** - All versions saved with timestamps
✅ **Impact analysis** - Shows what will change before applying
✅ **Dependency validation** - Catches circular dependencies
✅ **Conflict detection** - Identifies code file conflicts
✅ **Revert capability** - Can undo modifications
✅ **No work lost** - Completed work never lost
✅ **Clean resumption** - Seamless continuation after modification

## Integration with Ralph Loop

**Automatic detection:**

Ralph Loop automatically detects spec modifications:

```python
# Before each phase
if spec_version_changed():
    print("Spec modified, reloading...")
    reload_stories()
    recalculate_phases()
    update_tasks()
    continue_with_updated_plan()
```

**No manual intervention needed** - Loop adapts automatically.

## Examples

### Example 1: Mid-Implementation Gap

```bash
# Currently implementing REQ-004
# Realize REQ-009 needed first

/ralph-add-requirement "Email verification" --priority=high --depends-on=REQ-001,REQ-002

# Result:
# - REQ-004 paused (pending REQ-009)
# - REQ-009 implemented next
# - REQ-004 resumes after REQ-009
```

### Example 2: Failed Test Due to Unclear Criteria

```bash
# REQ-003 tests failing
# Acceptance criteria ambiguous

/ralph-modify-spec --update-criteria REQ-003

# Add 2 clarifying criteria
# Revert REQ-003 commit
# Re-implement with clear criteria
# New commit created
```

### Example 3: Priority Shift

```bash
# Business requirement: 2FA now urgent

/ralph-modify-spec --change-priorities

# REQ-008: low → high
# Move to earlier phase
# Implement sooner
```

## Troubleshooting

### Modification Conflicts

**Problem:** Modified requirement conflicts with pending work

**Solution:**
```
[Modify Spec] Warning: REQ-004 and REQ-009 both modify auth/password.ts
[Modify Spec] Recommend: Make REQ-004 depend on REQ-009
[Modify Spec] This ensures sequential execution
[Modify Spec] Add dependency? (y/n)
```

### Circular Dependencies

**Problem:** Modification creates circular dependency

**Solution:**
```
[Modify Spec] Error: Circular dependency detected
[Modify Spec] REQ-009 → REQ-004 → REQ-005 → REQ-009
[Modify Spec] Cannot proceed
[Modify Spec] Remove dependency: REQ-005 → REQ-009? (y/n)
```

### Too Many Modifications

**Problem:** Spec heavily modified, may need restart

**Solution:**
```
[Modify Spec] Warning: 5 modifications made
[Modify Spec] Spec significantly changed from original
[Modify Spec] Consider:
[Modify Spec] A) Continue (keep all progress)
[Modify Spec] B) Restart with updated spec (clean start)
[Modify Spec] Recommendation: Continue (A)
```

## Summary

Ralph Loop's spec modification system allows:

✅ **Add requirements** during implementation
✅ **Modify requirements** when unclear
✅ **Change priorities** based on learnings
✅ **Update dependencies** when discovered
✅ **Remove requirements** if scope changes
✅ **Revert completed work** if needed
✅ **Track all changes** in archive
✅ **Resume seamlessly** after modifications
✅ **No progress lost** - all work preserved

**Key principle:** Specs are never perfect upfront. Ralph Loop adapts to reality.

---

**Start modifying specs flexibly:**
```bash
# Discover gap during implementation
/ralph-add-requirement "Missing requirement description"

# Or use full modification interface
/ralph-modify-spec
```

The framework handles the complexity, you focus on getting requirements right.
