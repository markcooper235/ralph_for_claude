# Ralph Loop Framework - Complete Workflow Guide

## Overview

This document outlines the **complete end-to-end workflow** from starting a Ralph Loop to final merge and cleanup.

---

## Phase 0: Pre-Loop (Initial State)

### Current State
```
Git branch: main (clean)
Git status: nothing to commit, working tree clean
Ralph state: None (ralph/.ralph/ does not exist)
```

### Validation Checks
```bash
# Check 1: No Ralph run in progress
if [ -d ralph/.ralph ]; then
  echo "ERROR: Ralph run already in progress"
  echo "Complete with /ralph-archive or abandon with /ralph-archive --abandon"
  exit 1
fi

# Check 2: Git working tree is clean
if [ -n "$(git status --porcelain)" ]; then
  echo "WARNING: Working tree has uncommitted changes"
  echo "Commit or stash changes before starting Ralph loop"
fi

# Check 3: On valid branch
CURRENT_BRANCH=$(git branch --show-current)
if [ -z "$CURRENT_BRANCH" ]; then
  echo "ERROR: Not on a git branch (detached HEAD)"
  exit 1
fi
```

---

## Phase 1: Create Specification

### Command
```bash
/ralph-create-prd user-authentication
```

### Process
1. Interactive Q&A session
2. Problem statement collection
3. User stories gathering
4. Requirements definition with acceptance criteria
5. Dependency detection (explicit + auto)
6. Code impact analysis
7. Story breakdown and execution planning
8. Validation and gap filling

### Output
```
[Ralph Create PRD] Starting interactive PRD creation
[Ralph Create PRD] Project: user-authentication
[Ralph Create PRD]

[Question 1/10] What problem does this solve?
> Users need secure authentication system

[Question 2/10] Who are the target users?
> Web application users, administrators

... (interactive Q&A continues)

[Ralph Create PRD] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[Ralph Create PRD] Analysis Complete
[Ralph Create PRD] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[Ralph Create PRD] Requirements Summary:
[Ralph Create PRD] - 8 functional requirements
[Ralph Create PRD] - 4 non-functional requirements
[Ralph Create PRD] - 5 user stories
[Ralph Create PRD] - UI tests required: Yes

[Ralph Create PRD] Dependency Analysis:
[Ralph Create PRD] - REQ-001: No dependencies
[Ralph Create PRD] - REQ-002: No dependencies
[Ralph Create PRD] - REQ-003: Depends on REQ-001
[Ralph Create PRD] - REQ-004: Depends on REQ-001, REQ-002
[Ralph Create PRD] - REQ-005: Depends on REQ-001
[Ralph Create PRD] - REQ-006: Depends on REQ-002
[Ralph Create PRD] - REQ-007: Depends on REQ-001
[Ralph Create PRD] - REQ-008: Depends on REQ-004

[Ralph Create PRD] Code Impact Analysis:
[Ralph Create PRD] - REQ-001, REQ-003, REQ-005: All modify auth/login.ts
[Ralph Create PRD]   → Will run sequentially by priority
[Ralph Create PRD] - REQ-002, REQ-006: Modify auth/session.ts
[Ralph Create PRD]   → Will run sequentially
[Ralph Create PRD] - REQ-004, REQ-008: Modify auth/password.ts
[Ralph Create PRD]   → REQ-008 depends on REQ-004

[Ralph Create PRD] Execution Plan:
[Ralph Create PRD]
[Ralph Create PRD] Phase 1 (parallel, no dependencies):
[Ralph Create PRD]   - REQ-001: User Login (high)
[Ralph Create PRD]   - REQ-002: Session Management (high)
[Ralph Create PRD]
[Ralph Create PRD] Phase 2 (mixed, dependencies satisfied):
[Ralph Create PRD]   - REQ-003: Logout (high, sequential after REQ-001)
[Ralph Create PRD]   - REQ-006: Session Refresh (medium, parallel)
[Ralph Create PRD]
[Ralph Create PRD] Phase 3 (parallel, dependencies satisfied):
[Ralph Create PRD]   - REQ-004: Password Reset (medium)
[Ralph Create PRD]   - REQ-005: Remember Me (low)
[Ralph Create PRD]   - REQ-007: OAuth Integration (low)
[Ralph Create PRD]
[Ralph Create PRD] Phase 4 (sequential, depends on Phase 3):
[Ralph Create PRD]   - REQ-008: 2FA (low, depends on REQ-004)
[Ralph Create PRD]
[Ralph Create PRD] Estimated completion: 3-4 hours
[Ralph Create PRD] Estimated quota: ~145K tokens
[Ralph Create PRD] May require 1 pause/resume cycle
[Ralph Create PRD]
[Ralph Create PRD] ✓ PRD created: ralph/specs/prds/user-authentication.prd.md
[Ralph Create PRD] ✓ Story breakdown: ralph/specs/prds/user-authentication.stories.json
[Ralph Create PRD]
[Ralph Create PRD] Ready to start Ralph Loop!
[Ralph Create PRD]
[Ralph Create PRD] Next: /ralph-loop ralph/specs/prds/user-authentication.prd.md
```

### Files Created
```
ralph/specs/prds/user-authentication.prd.md          # Full PRD
ralph/specs/prds/user-authentication.stories.json    # Story breakdown
```

---

## Phase 2: Start Ralph Loop

### Command
```bash
/ralph-loop ralph/specs/prds/user-authentication.prd.md
```

### 2.1: Initialization

#### Output
```
[Ralph Loop] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[Ralph Loop] Ralph Loop v2 Starting
[Ralph Loop] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[Ralph Loop] Specification: ralph/specs/prds/user-authentication.prd.md
[Ralph Loop] Run ID: user-authentication-20260223152030

[Ralph Loop] Checking prerequisites...
[Ralph Loop] ✓ No existing Ralph run in progress
[Ralph Loop] ✓ Git working tree is clean
[Ralph Loop] ✓ On branch: main

[Ralph Loop] Creating Ralph state directory...
[Ralph Loop] ✓ Created ralph/.ralph/
[Ralph Loop] ✓ Created ralph/.ralph/logs/
[Ralph Loop] ✓ Created ralph/.ralph/artifacts/
[Ralph Loop] ✓ Initialized state.json

[Ralph Loop] Creating git branch...
[Ralph Loop] Origin branch: main
[Ralph Loop] Ralph branch: ralph/user-authentication-20260223152030
[Ralph Loop] ✓ Branch created and checked out

[Ralph Loop] Git status:
[Ralph Loop]   On branch ralph/user-authentication-20260223152030
[Ralph Loop]   nothing to commit, working tree clean
```

#### Git State After Init
```
Current branch: ralph/user-authentication-20260223152030
Origin branch: main (will merge back here)
Commits: 0 new commits yet
```

#### State Files Created
```
ralph/.ralph/state.json           # Run state
ralph/.ralph/quota-config.json    # Quota configuration
```

### 2.2: Parse Specification (Subagent)

#### Output
```
[Ralph Loop] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[Ralph Loop] Phase: Parse Specification
[Ralph Loop] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[Ralph Loop] Launching parse subagent...
[Ralph Loop] Estimated cost: 3,000 tokens
[Ralph Loop] Quota check: 0K + 3K = 3K (1.5%) ✓

[Subagent: Parse] Reading PRD: ralph/specs/prds/user-authentication.prd.md
[Subagent: Parse] Extracting requirements...
[Subagent: Parse] Found 8 functional requirements
[Subagent: Parse] Found 4 non-functional requirements
[Subagent: Parse] Analyzing dependencies...
[Subagent: Parse] Detecting code conflicts...
[Subagent: Parse] Checking UI test requirements...
[Subagent: Parse] ✓ UI tests required (keywords: login form, session display)
[Subagent: Parse] Generating stories.json...
[Subagent: Parse] ✓ Parse complete

[Ralph Loop] ✓ Subagent completed
[Ralph Loop] Actual cost: 2,847 tokens
[Ralph Loop] Total quota used: 2,847/200,000 (1.4%)

[Ralph Loop] Creating Claude Tasks...
[Ralph Loop] ✓ Task 1: REQ-001 User Login
[Ralph Loop] ✓ Task 2: REQ-002 Session Management
[Ralph Loop] ✓ Task 3: REQ-003 Logout
[Ralph Loop] ✓ Task 4: REQ-004 Password Reset
[Ralph Loop] ✓ Task 5: REQ-005 Remember Me
[Ralph Loop] ✓ Task 6: REQ-006 Session Refresh
[Ralph Loop] ✓ Task 7: REQ-007 OAuth Integration
[Ralph Loop] ✓ Task 8: REQ-008 Two-Factor Auth

[Ralph Loop] Stories parsed: 8
[Ralph Loop] Execution phases: 4
```

#### State Files Updated
```
ralph/.ralph/state.json          # Status: parsing → architecture
ralph/.ralph/stories.json        # All stories with dependencies
```

### 2.3: Architecture Design (Subagent)

#### Output
```
[Ralph Loop] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[Ralph Loop] Phase: Architecture Design
[Ralph Loop] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[Ralph Loop] Launching architecture subagent...
[Ralph Loop] Estimated cost: 4,000 tokens
[Ralph Loop] Quota check: 2,847K + 4K = 6,847K (3.4%) ✓

[Subagent: Arch] Analyzing codebase...
[Subagent: Arch] Project type: Web Frontend (React + TypeScript)
[Subagent: Arch] Tech stack: React 18, TypeScript, Vite, Vitest
[Subagent: Arch] Test framework: Vitest (unit), Playwright (UI)
[Subagent: Arch] Linter: ESLint + Prettier

[Subagent: Arch] Designing implementation approach...
[Subagent: Arch] REQ-001: src/auth/login.ts + tests/auth/login.test.ts
[Subagent: Arch] REQ-002: src/auth/session.ts + tests/auth/session.test.ts
[Subagent: Arch] ... (8 more)

[Subagent: Arch] Test strategy:
[Subagent: Arch] - Lint: ESLint + Prettier (auto-fix enabled)
[Subagent: Arch] - Unit: Vitest with 80% coverage target
[Subagent: Arch] - UI: Playwright for login form, session display
[Subagent: Arch] - Quality: ESLint complexity checks

[Subagent: Arch] ✓ Architecture complete
[Subagent: Arch] Saved: ralph/.ralph/architecture.json

[Ralph Loop] ✓ Subagent completed
[Ralph Loop] Actual cost: 4,203 tokens
[Ralph Loop] Total quota used: 7,050/200,000 (3.5%)
```

### 2.4: Implementation Loop - Phase 1

#### Output
```
[Ralph Loop] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[Ralph Loop] Phase: Implementation (Phase 1 of 4)
[Ralph Loop] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[Ralph Loop] Phase 1: Parallel execution (2 stories, no dependencies)
[Ralph Loop] - REQ-001: User Login
[Ralph Loop] - REQ-002: Session Management

[Ralph Loop] Estimating costs...
[Ralph Loop] REQ-001: 12,500 tokens (medium, 4 criteria, auth/login.ts)
[Ralph Loop] REQ-002: 14,000 tokens (medium, 5 criteria, auth/session.ts)
[Ralph Loop] Phase total: ~15,000 tokens (parallel max)

[Ralph Loop] Quota check:
[Ralph Loop] Current: 7,050/200,000 (3.5%)
[Ralph Loop] After phase: ~22,050/200,000 (11%)
[Ralph Loop] Status: ✓ Safe to proceed

[Ralph Loop] Launching 2 parallel subagents...

╔════════════════════════════════════════════════════╗
║ Subagent 1: REQ-001 User Login                    ║
╚════════════════════════════════════════════════════╝

[Subagent REQ-001] Starting implementation
[Subagent REQ-001] Creating: src/auth/login.ts
[Subagent REQ-001] Creating: tests/auth/login.test.ts
[Subagent REQ-001] Implementation complete
[Subagent REQ-001] Running tests...
[Subagent REQ-001]   - Lint: ✓ Passed (0 errors, auto-fixed 2 warnings)
[Subagent REQ-001]   - Unit: ✓ Passed (4/4 tests, 92% coverage)
[Subagent REQ-001]   - Quality: ✓ Passed (complexity: 4/10)
[Subagent REQ-001] All tests passed!
[Subagent REQ-001] Files: src/auth/login.ts, tests/auth/login.test.ts
[Subagent REQ-001] Cost: 11,823 tokens

╔════════════════════════════════════════════════════╗
║ Subagent 2: REQ-002 Session Management            ║
╚════════════════════════════════════════════════════╝

[Subagent REQ-002] Starting implementation
[Subagent REQ-002] Creating: src/auth/session.ts
[Subagent REQ-002] Creating: tests/auth/session.test.ts
[Subagent REQ-002] Implementation complete
[Subagent REQ-002] Running tests...
[Subagent REQ-002]   - Lint: ✓ Passed
[Subagent REQ-002]   - Unit: ✓ Passed (5/5 tests, 88% coverage)
[Subagent REQ-002]   - Quality: ✓ Passed
[Subagent REQ-002] All tests passed!
[Subagent REQ-002] Files: src/auth/session.ts, tests/auth/session.test.ts
[Subagent REQ-002] Cost: 13,456 tokens

[Ralph Loop] ✓ Both subagents completed
[Ralph Loop] Phase 1 actual cost: 25,279 tokens
[Ralph Loop] Total quota used: 32,329/200,000 (16.2%)

[Ralph Loop] Committing stories...

[Ralph Loop] Creating commit for REQ-001...
[Ralph Loop] Staging: src/auth/login.ts, tests/auth/login.test.ts
[Ralph Loop] Commit: "REQ-001: User Login

Users can log in with email and password

Acceptance Criteria:
- User can enter email and password
- System validates credentials
- On success, user is redirected to dashboard
- On failure, error message is displayed

Tests: All passing
- Unit tests: 4/4 passed
- Lint: passed
- Code quality: passed
- Coverage: 92%

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"

[Ralph Loop] ✓ Commit created: a1b2c3d
[Ralph Loop] ✓ Task 1 updated: completed

[Ralph Loop] Creating commit for REQ-002...
[Ralph Loop] ✓ Commit created: e4f5g6h
[Ralph Loop] ✓ Task 2 updated: completed

[Ralph Loop] Phase 1 complete: 2/8 stories completed
[Ralph Loop] Git commits: 2
[Ralph Loop] Moving to Phase 2...
```

#### Git State After Phase 1
```
Current branch: ralph/user-authentication-20260223152030
Commits ahead of main: 2
  a1b2c3d REQ-001: User Login
  e4f5g6h REQ-002: Session Management
```

### 2.5: Implementation Loop - Phases 2, 3, 4

*(Similar process continues for remaining phases)*

#### Output Summary
```
[Ralph Loop] Phase 2 complete: 4/8 stories (REQ-003, REQ-006)
[Ralph Loop] Phase 3 complete: 7/8 stories (REQ-004, REQ-005, REQ-007)
[Ralph Loop] Total quota used: 155,234/200,000 (77.6%)

[Ralph Loop] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[Ralph Loop] Phase 4: Starting last story
[Ralph Loop] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[Ralph Loop] REQ-008: Two-Factor Authentication
[Ralph Loop] Estimated cost: 18,000 tokens
[Ralph Loop] Quota check:
[Ralph Loop] Current: 155,234/200,000 (77.6%)
[Ralph Loop] After task: 173,234/200,000 (86.6%)
[Ralph Loop] Status: ⚠️  Would exceed safety threshold (85%)

[Ralph Loop] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[Ralph Loop] PAUSING FOR QUOTA
[Ralph Loop] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[Ralph Loop] Reason: quota_safety_threshold
[Ralph Loop] Current phase: implementing
[Ralph Loop] Current story: REQ-008 (ready to start, not begun)
[Ralph Loop]
[Ralph Loop] Progress saved:
[Ralph Loop] ✓ 7/8 stories completed and committed
[Ralph Loop] ⏸ 1/8 stories pending (REQ-008)
[Ralph Loop]
[Ralph Loop] Quota Status:
[Ralph Loop] - Used: 155,234/200,000 (77.6%)
[Ralph Loop] - Estimated remaining: ~20,000 tokens
[Ralph Loop] - Safety threshold: 170,000 (85%)
[Ralph Loop]
[Ralph Loop] Git Status:
[Ralph Loop] - Branch: ralph/user-authentication-20260223152030
[Ralph Loop] - Commits: 7 (all pushed to local branch)
[Ralph Loop] - All changes committed ✓
[Ralph Loop]
[Ralph Loop] All progress preserved! Nothing lost.
[Ralph Loop]
[Ralph Loop] To resume after quota replenishment:
[Ralph Loop]   /ralph-resume
[Ralph Loop]
[Ralph Loop] To check status:
[Ralph Loop]   /ralph-status
```

#### Git State (Paused)
```
Current branch: ralph/user-authentication-20260223152030
Commits ahead of main: 7
Status: clean (all changes committed)
```

#### State Files (Paused)
```
ralph/.ralph/state.json:
  status: "paused_quota"
  pausedAt: "2026-02-23T16:45:00Z"
  pauseReason: "quota_safety_threshold"
  resumePhase: "implementing"
  currentStory: "REQ-008"
  quota:
    totalUsed: 155234
    estimatedRemaining: 20000
```

---

## Phase 3: Resume After Quota Replenishment

### Check Status First

#### Command
```bash
/ralph-status
```

#### Output
```
[Ralph Status] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[Ralph Status] Current Ralph Run
[Ralph Status] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[Ralph Status] Run ID: user-authentication-20260223152030
[Ralph Status] Specification: ralph/specs/prds/user-authentication.prd.md
[Ralph Status] Status: PAUSED (quota_safety_threshold)
[Ralph Status] Started: 2026-02-23T15:20:30Z
[Ralph Status] Paused: 2026-02-23T16:45:00Z
[Ralph Status] Time paused: 18 hours 30 minutes

[Ralph Status] Git Information:
[Ralph Status] - Origin: main
[Ralph Status] - Ralph: ralph/user-authentication-20260223152030
[Ralph Status] - Commits: 7

[Ralph Status] Progress:
[Ralph Status] - Total Stories: 8
[Ralph Status] - Completed: 7 (87.5%)
[Ralph Status] - In Progress: 0
[Ralph Status] - Pending: 1 (12.5%)

[Ralph Status] Quota Status:
[Ralph Status] - Used: 155,234/200,000 (77.6%)
[Ralph Status] - Estimated remaining need: ~20,000
[Ralph Status] - Current quota available: 200,000 (reset)
[Ralph Status] - Status: ✓ Sufficient quota to complete

[Ralph Status] Completed Stories:
[Ralph Status]   [COMPLETED] REQ-001: User Login
[Ralph Status]   [COMPLETED] REQ-002: Session Management
[Ralph Status]   [COMPLETED] REQ-003: Logout
[Ralph Status]   [COMPLETED] REQ-004: Password Reset
[Ralph Status]   [COMPLETED] REQ-005: Remember Me
[Ralph Status]   [COMPLETED] REQ-006: Session Refresh
[Ralph Status]   [COMPLETED] REQ-007: OAuth Integration

[Ralph Status] Pending Stories:
[Ralph Status]   [READY] REQ-008: Two-Factor Auth

[Ralph Status] Next Step: Resume execution
[Ralph Status]   /ralph-resume
```

### Resume Ralph Loop

#### Command
```bash
/ralph-resume
```

#### Output
```
[Ralph Resume] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[Ralph Resume] Resuming Ralph Run
[Ralph Resume] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[Ralph Resume] Run ID: user-authentication-20260223152030
[Ralph Resume] Paused at: implementing (REQ-008)
[Ralph Resume] Pause reason: quota_safety_threshold
[Ralph Resume] Time paused: 18 hours 30 minutes

[Ralph Resume] Checking quota availability...
[Ralph Resume] Quota used: 155,234 (from previous session)
[Ralph Resume] Quota available: 200,000 (reset)
[Ralph Resume] Quota needed: ~20,000
[Ralph Resume] Status: ✓ Sufficient quota

[Ralph Resume] Loading state...
[Ralph Resume] ✓ State loaded from ralph/.ralph/state.json
[Ralph Resume] ✓ Stories loaded from ralph/.ralph/stories.json
[Ralph Resume] ✓ Architecture loaded

[Ralph Resume] Resuming execution...
[Ralph Resume] Phase: implementing
[Ralph Resume] Story: REQ-008 (Two-Factor Authentication)

[Ralph Resume] Continuing Ralph Loop...

[Ralph Loop] Resumed from pause
[Ralph Loop] Continuing Phase 4...

[Subagent REQ-008] Starting implementation
[Subagent REQ-008] ... (implementation process)
[Subagent REQ-008] All tests passed!
[Subagent REQ-008] Cost: 17,234 tokens

[Ralph Loop] ✓ REQ-008 completed
[Ralph Loop] Creating commit...
[Ralph Loop] ✓ Commit created: i7j8k9l

[Ralph Loop] All stories complete: 8/8 (100%)
[Ralph Loop] Total quota used: 172,468/200,000 (86.2%)
[Ralph Loop] Moving to Prove phase...
```

### 2.6: Prove Requirements

#### Output
```
[Ralph Loop] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[Ralph Loop] Phase: Prove Requirements
[Ralph Loop] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[Ralph Loop] Running comprehensive validation...
[Ralph Loop] Estimated cost: 6,000 tokens
[Ralph Loop] Quota check: 172,468K + 6K = 178,468K (89.2%) ✓

[Ralph Loop] Running full test suite...
[Ralph Loop] - All unit tests: ✓ 42/42 passed
[Ralph Loop] - All lint checks: ✓ Passed
[Ralph Loop] - All UI tests: ✓ 8/8 passed
[Ralph Loop] - All quality checks: ✓ Passed
[Ralph Loop] - Overall coverage: 89%

[Ralph Loop] Validating requirements...
[Ralph Loop] ✓ REQ-001: All 4 criteria met
[Ralph Loop] ✓ REQ-002: All 5 criteria met
[Ralph Loop] ✓ REQ-003: All 2 criteria met
[Ralph Loop] ✓ REQ-004: All 3 criteria met
[Ralph Loop] ✓ REQ-005: All 3 criteria met
[Ralph Loop] ✓ REQ-006: All 2 criteria met
[Ralph Loop] ✓ REQ-007: All 4 criteria met
[Ralph Loop] ✓ REQ-008: All 5 criteria met

[Ralph Loop] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[Ralph Loop] ALL REQUIREMENTS PROVEN ✓
[Ralph Loop] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[Ralph Loop] Proof report: ralph/.ralph/artifacts/proof-report.md

[Ralph Loop] Total quota used: 178,651/200,000 (89.3%)
[Ralph Loop] Moving to Harvest phase...
```

### 2.7: Harvest Feedback

#### Output
```
[Ralph Loop] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[Ralph Loop] Phase: Harvest Feedback
[Ralph Loop] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[Ralph Loop] Collecting artifacts...
[Ralph Loop] - Test results: 8 files
[Ralph Loop] - Implementation summaries: 8 files
[Ralph Loop] - Proof report: 1 file
[Ralph Loop] - Git history: 8 commits

[Ralph Loop] Generating harvest summary...
[Ralph Loop] ✓ Summary saved: ralph/.ralph/artifacts/harvest-summary.md

[Ralph Loop] Final Statistics:
[Ralph Loop] - Stories: 8/8 completed (100%)
[Ralph Loop] - Commits: 8 (one per story)
[Ralph Loop] - Tests: 42 unit, 8 UI, all passed
[Ralph Loop] - Coverage: 89%
[Ralph Loop] - Total time: 2h 45m (includes 18h pause)
[Ralph Loop] - Active time: 45 minutes
[Ralph Loop] - Quota used: 178,651/200,000 (89.3%)
[Ralph Loop] - Iterations: 3 logic, 1 formatting

[Ralph Loop] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[Ralph Loop] RALPH RUN COMPLETE ✓
[Ralph Loop] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[Ralph Loop] Status: ready_for_archive

[Ralph Loop] Next step: /ralph-archive
[Ralph Loop]
[Ralph Loop] This will:
[Ralph Loop] 1. Validate all pre-merge checks
[Ralph Loop] 2. Archive all artifacts
[Ralph Loop] 3. Merge ralph branch to main
[Ralph Loop] 4. Clean up Ralph state
[Ralph Loop] 5. Prepare workspace for next run
```

#### Git State (Ready for Archive)
```
Current branch: ralph/user-authentication-20260223152030
Commits ahead of main: 8
All changes: committed
Working tree: clean
```

---

## Phase 4: Archive and Merge

### Command
```bash
/ralph-archive
```

### 4.1: Pre-Merge Validation

#### Output
```
[Ralph Archive] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[Ralph Archive] Starting Archive Process
[Ralph Archive] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[Ralph Archive] Run ID: user-authentication-20260223152030
[Ralph Archive] Status: ready_for_archive

[Ralph Archive] Pre-Merge Validation:
[Ralph Archive] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[Ralph Archive] Check 1: Test results
[Ralph Archive] Reading: ralph/.ralph/artifacts/artifacts-index.json
[Ralph Archive] ✓ allPassed: true (8/8 stories) — trusting Phase 4 results

[Ralph Archive] Check 2: No uncommitted changes
[Ralph Archive] Running: git status --porcelain
[Ralph Archive] ✓ Working tree clean

[Ralph Archive] Check 3: All stories completed
[Ralph Archive] ✓ completedStories (8) == totalStories (8)

[Ralph Archive] Check 4: No merge conflicts
[Ralph Archive] state.premergeChecks.checkedAt: 4 minutes ago (< 30 min threshold)
[Ralph Archive] ✓ Using cached Phase 7 result — skipping git fetch/merge-base

[Ralph Archive] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[Ralph Archive] ✓ All pre-merge checks passed
[Ralph Archive] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### 4.2: Create Archive

#### Output
```
[Ralph Archive] Creating archive directory...
[Ralph Archive] Archive path: ralph/archive/user-authentication-20260223152030/

[Ralph Archive] Copying artifacts...
[Ralph Archive] ✓ Spec: ralph/specs/prds/user-authentication.prd.md
[Ralph Archive] ✓ State files: 3 files → archive/*/state/
[Ralph Archive] ✓ Logs: 12 files → archive/*/logs/
[Ralph Archive] ✓ Artifacts: 17 files → archive/*/artifacts/
[Ralph Archive] ✓ Test results: 8 files → archive/*/tests/
[Ralph Archive] ✓ Coverage reports → archive/*/tests/coverage/

[Ralph Archive] Capturing git information...
[Ralph Archive] ✓ Branch info → archive/*/git-info/branch-info.txt
[Ralph Archive] ✓ Commit log → archive/*/git-info/commits.txt
[Ralph Archive] ✓ Diff summary → archive/*/git-info/diff-summary.txt
[Ralph Archive] ✓ Full diff → archive/*/git-info/full-diff.patch

[Ralph Archive] Generating summary...
[Ralph Archive] ✓ Human-readable → archive/*/summary.md
[Ralph Archive] ✓ Machine-readable → archive/*/metadata.json

[Ralph Archive] Archive created: 45 files
```

### 4.3: Validate Archive Completeness

#### Output
```
[Ralph Archive] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[Ralph Archive] Archive Completeness Validation
[Ralph Archive] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[Ralph Archive] Checking archive integrity...

[Ralph Archive] Check 1: Required directories exist
[Ralph Archive] ✓ ralph/archive/user-authentication-20260223152030/spec/
[Ralph Archive] ✓ ralph/archive/user-authentication-20260223152030/state/
[Ralph Archive] ✓ ralph/archive/user-authentication-20260223152030/logs/
[Ralph Archive] ✓ ralph/archive/user-authentication-20260223152030/artifacts/
[Ralph Archive] ✓ ralph/archive/user-authentication-20260223152030/tests/
[Ralph Archive] ✓ ralph/archive/user-authentication-20260223152030/git-info/

[Ralph Archive] Check 2: Required files exist
[Ralph Archive] ✓ summary.md (12,345 bytes)
[Ralph Archive] ✓ metadata.json (valid JSON)
[Ralph Archive] ✓ spec/user-authentication.prd.md (original spec)

[Ralph Archive] Check 3: State files complete
[Ralph Archive] ✓ state/state.json (final state)
[Ralph Archive] ✓ state/stories.json (8 stories)
[Ralph Archive] ✓ state/architecture.json (architecture decisions)

[Ralph Archive] Check 4: All story artifacts present
[Ralph Archive] ✓ REQ-001: Implementation + tests found
[Ralph Archive] ✓ REQ-002: Implementation + tests found
[Ralph Archive] ✓ REQ-003: Implementation + tests found
[Ralph Archive] ✓ REQ-004: Implementation + tests found
[Ralph Archive] ✓ REQ-005: Implementation + tests found
[Ralph Archive] ✓ REQ-006: Implementation + tests found
[Ralph Archive] ✓ REQ-007: Implementation + tests found
[Ralph Archive] ✓ REQ-008: Implementation + tests found

[Ralph Archive] Check 5: Test results archived
[Ralph Archive] ✓ Unit test results: 8 files
[Ralph Archive] ✓ UI test results: 8 files
[Ralph Archive] ✓ Coverage reports: Present
[Ralph Archive] ✓ Lint results: Present

[Ralph Archive] Check 6: Git information complete
[Ralph Archive] ✓ Branch info: 348 bytes
[Ralph Archive] ✓ Commit log: 8 commits listed
[Ralph Archive] ✓ Diff summary: 2,456 bytes
[Ralph Archive] ✓ Full diff: 45,678 bytes

[Ralph Archive] Check 7: Logs present
[Ralph Archive] ✓ Parse log: present
[Ralph Archive] ✓ Architecture log: present
[Ralph Archive] ✓ Implementation logs: 8 files
[Ralph Archive] ✓ Test logs: 8 files
[Ralph Archive] ✓ Prove log: present
[Ralph Archive] ✓ Harvest log: present

[Ralph Archive] Check 8: Archive structure valid
[Ralph Archive] Running: tree ralph/archive/user-authentication-20260223152030/
[Ralph Archive] ✓ All expected directories present
[Ralph Archive] ✓ No empty directories
[Ralph Archive] ✓ All files readable

[Ralph Archive] Check 9: Can restore from archive
[Ralph Archive] Testing: Load metadata.json
[Ralph Archive] Testing: Load state.json
[Ralph Archive] Testing: Load stories.json
[Ralph Archive] ✓ All critical files parseable

[Ralph Archive] Check 10: Quota tracking archived
[Ralph Archive] ✓ Quota usage data: Present (178,651 tokens)
[Ralph Archive] ✓ Phase breakdown: Present
[Ralph Archive] ✓ Pause/resume history: Present (1 pause)

[Ralph Archive] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[Ralph Archive] ✓ Archive Completeness: 100%
[Ralph Archive] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[Ralph Archive] Archive Statistics:
[Ralph Archive] - Total files: 45
[Ralph Archive] - Total size: 2.3 MB
[Ralph Archive] - Stories: 8/8 archived
[Ralph Archive] - Commits: 8 archived
[Ralph Archive] - Tests: 16 result files
[Ralph Archive] - Logs: 12 log files
[Ralph Archive] - All data: ✓ Preserved

[Ralph Archive] Archive validation: PASSED ✓
[Ralph Archive] Safe to proceed with merge and cleanup
```

#### If Archive Validation Fails

```
[Ralph Archive] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[Ralph Archive] ❌ Archive Validation FAILED
[Ralph Archive] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[Ralph Archive] Missing items:
[Ralph Archive] ✗ state/stories.json - File not found
[Ralph Archive] ✗ artifacts/REQ-005-impl.json - File not found
[Ralph Archive] ✗ tests/coverage/ - Directory empty

[Ralph Archive] ERROR: Archive incomplete
[Ralph Archive] Cannot proceed with merge and cleanup
[Ralph Archive]
[Ralph Archive] Action: Retrying archive creation...
[Ralph Archive] Attempt 2 of 3...
[Ralph Archive]
[Ralph Archive] If problem persists:
[Ralph Archive] 1. Check disk space
[Ralph Archive] 2. Check file permissions
[Ralph Archive] 3. Review ralph/.ralph/ contents
[Ralph Archive] 4. Contact support if needed
[Ralph Archive]
[Ralph Archive] Ralph state preserved for debugging
```

### 4.4: Merge to Origin Branch

#### Output
```
[Ralph Archive] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[Ralph Archive] Merging to Origin Branch
[Ralph Archive] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[Ralph Archive] Origin branch: main
[Ralph Archive] Ralph branch: ralph/user-authentication-20260223152030

[Ralph Archive] Switching to main...
[Ralph Archive] Running: git checkout main
[Ralph Archive] ✓ On branch main

[Ralph Archive] Merging Ralph branch...
[Ralph Archive] Running: git merge --no-ff ralph/user-authentication-20260223152030

[Ralph Archive] Merge strategy: regular merge (preserves all commits)
[Ralph Archive] Merge commit message:
────────────────────────────────────────────────────────
Merge Ralph Loop: user-authentication-20260223152030

Completed all requirements from ralph/specs/prds/user-authentication.prd.md

Stories completed: 8/8
Test coverage: 89%

All tests passing:
- Unit tests: 42/42 passed
- UI tests: 8/8 passed
- Lint: passed
- Code quality: passed

Archive: ralph/archive/user-authentication-20260223152030/

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
────────────────────────────────────────────────────────

[Ralph Archive] ✓ Merge successful
[Ralph Archive] Merge commit: m9n0p1q

[Ralph Archive] Git log (last 10 commits):
[Ralph Archive]   m9n0p1q Merge Ralph Loop: user-authentication-20260223152030
[Ralph Archive]   i7j8k9l REQ-008: Two-Factor Auth
[Ralph Archive]   ... (7 more story commits)
[Ralph Archive]   a1b2c3d REQ-001: User Login
```

### 4.5: Branch Handling Decision

#### Output
```
[Ralph Archive] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[Ralph Archive] Branch Management
[Ralph Archive] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[Ralph Archive] Ralph branch: ralph/user-authentication-20260223152030
[Ralph Archive]
[Ralph Archive] Options:
[Ralph Archive] A) Keep branch (recommended for audit trail)
[Ralph Archive] B) Delete branch (clean up branch list)
[Ralph Archive]
[Ralph Archive] Configuration: KEEP (default)
[Ralph Archive]
[Ralph Archive] ✓ Ralph branch preserved for reference
[Ralph Archive]
[Ralph Archive] To delete manually later:
[Ralph Archive]   git branch -d ralph/user-authentication-20260223152030
[Ralph Archive]
[Ralph Archive] To view Ralph branch history:
[Ralph Archive]   git log ralph/user-authentication-20260223152030
```

**My Recommendation: KEEP by default, with option to delete**

**Reasons to KEEP:**
- ✅ Complete audit trail
- ✅ Easy to review individual story commits
- ✅ Can compare implementations
- ✅ Debugging reference
- ✅ Learning from past approaches
- ✅ Compliance/documentation

**Reasons to DELETE:**
- Cleaner branch list
- Less clutter in git UI

**Compromise: Keep with auto-cleanup**
```json
// In ralph/.ralph/quota-config.json
{
  "archive": {
    "keepRalphBranch": true,        // Default: keep
    "autoDeleteAfterDays": 30,      // Optional: auto-delete after 30 days
    "keepLastN": 10                 // Optional: keep only last 10 Ralph branches
  }
}
```

### 4.6: Cleanup Ralph State

#### Output
```
[Ralph Archive] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[Ralph Archive] Cleanup
[Ralph Archive] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[Ralph Archive] Removing Ralph state directory...
[Ralph Archive] ✓ Removed ralph/.ralph/state.json
[Ralph Archive] ✓ Removed ralph/.ralph/stories.json
[Ralph Archive] ✓ Removed ralph/.ralph/architecture.json
[Ralph Archive] ✓ Removed ralph/.ralph/logs/ (12 files)
[Ralph Archive] ✓ Removed ralph/.ralph/artifacts/ (17 files)
[Ralph Archive] ✓ Removed ralph/.ralph/

[Ralph Archive] Removing temporary files...
[Ralph Archive] ✓ Cleaned up temp files
```

### 4.7: Post-Merge Validation

#### Output
```
[Ralph Archive] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[Ralph Archive] Post-Merge Validation
[Ralph Archive] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[Ralph Archive] Check 1: On origin branch
[Ralph Archive] Current branch: main ✓

[Ralph Archive] Check 2: Ralph state removed
[Ralph Archive] ralph/.ralph/ exists: No ✓

[Ralph Archive] Check 3: Working tree clean
[Ralph Archive] git status: nothing to commit, working tree clean ✓

[Ralph Archive] Check 4: All tests still passing
[Ralph Archive] Running: npm test
[Ralph Archive] Result: 42/42 passed ✓

[Ralph Archive] Check 5: Merge commit in history
[Ralph Archive] Latest commit: m9n0p1q (Merge Ralph Loop) ✓

[Ralph Archive] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[Ralph Archive] ✓ Workspace ready for next Ralph run
[Ralph Archive] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### 4.8: Final Summary

#### Output
```
[Ralph Archive] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[Ralph Archive] ARCHIVE COMPLETE ✓
[Ralph Archive] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[Ralph Archive] Run Summary:
[Ralph Archive] - Run ID: user-authentication-20260223152030
[Ralph Archive] - Duration: 45 minutes (active)
[Ralph Archive] - Stories: 8/8 completed
[Ralph Archive] - Commits: 8 stories + 1 merge = 9 total
[Ralph Archive] - Tests: All passed
[Ralph Archive] - Coverage: 89%

[Ralph Archive] Archive Location:
[Ralph Archive]   ralph/archive/user-authentication-20260223152030/

[Ralph Archive] Git Status:
[Ralph Archive] - Current branch: main
[Ralph Archive] - Ralph branch: Preserved (ralph/user-authentication-20260223152030)
[Ralph Archive] - Merge commit: m9n0p1q
[Ralph Archive] - Working tree: Clean

[Ralph Archive] Workspace Status:
[Ralph Archive] - Ralph state: ✓ Cleaned
[Ralph Archive] - Ready for next run: ✓ Yes

[Ralph Archive] To review this run:
[Ralph Archive]   cat ralph/archive/user-authentication-20260223152030/summary.md
[Ralph Archive]   git log m9n0p1q
[Ralph Archive]   git show ralph/user-authentication-20260223152030

[Ralph Archive] To start next run:
[Ralph Archive]   /ralph-create-prd <next-feature>
[Ralph Archive]   /ralph-loop ralph/specs/prds/<next-feature>.prd.md

[Ralph Archive] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[Ralph Archive] Ready for next Ralph Loop! 🚀
[Ralph Archive] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Final State

### Git Status
```bash
$ git status
On branch main
nothing to commit, working tree clean

$ git branch
* main
  ralph/user-authentication-20260223152030

$ git log --oneline -10
m9n0p1q Merge Ralph Loop: user-authentication-20260223152030
i7j8k9l REQ-008: Two-Factor Auth
... (7 more story commits)
a1b2c3d REQ-001: User Login
[previous commits...]
```

### File System
```
✓ ralph/.ralph/ - REMOVED
✓ ralph/archive/user-authentication-20260223152030/ - CREATED (45 files)
✓ src/ - UPDATED (8 new files)
✓ tests/ - UPDATED (8 new test files)
```

### Ready for Next Run
```
Checklist:
✓ No Ralph state exists
✓ On origin branch (main)
✓ Working tree clean
✓ All tests passing
✓ Previous run fully archived
✓ Ralph branch preserved (optional)

Status: READY FOR NEXT RALPH RUN ✓
```

---

## Complete Command Summary

```bash
# 1. Create specification
/ralph-create-prd user-authentication

# 2. Start Ralph Loop
/ralph-loop ralph/specs/prds/user-authentication.prd.md

# 3. (Optional) Check status during run
/ralph-status

# 4. (If paused) Resume after quota
/ralph-resume

# 5. Archive and merge
/ralph-archive

# 6. Start next feature
/ralph-create-prd next-feature
```

---

## Timeline Summary

```
T+0:00    /ralph-create-prd (10 minutes)
T+0:10    /ralph-loop starts
T+0:15    Phase 1 complete (2 stories, 2 commits)
T+0:25    Phase 2 complete (2 stories, 4 commits total)
T+0:40    Phase 3 complete (3 stories, 7 commits total)
T+0:45    PAUSE (quota threshold, before REQ-008)

[18 hour pause - quota replenishes]

T+18:45   /ralph-resume
T+18:50   Phase 4 complete (1 story, 8 commits total)
T+18:52   Prove complete
T+18:53   Harvest complete
T+18:53   Status: ready_for_archive

T+18:54   /ralph-archive starts
T+18:54   Pre-merge validation
T+18:55   Archive creation
T+18:56   Merge to main (9 commits total)
T+18:56   Branch preserved
T+18:57   Cleanup complete
T+18:57   DONE - Ready for next run

Total active time: ~47 minutes
Total elapsed time: ~19 hours (includes 18h pause)
```

---

## Key Decision Points

### When Does Merge Happen?
**Answer: During `/ralph-archive` command, NOT during `/ralph-loop`**

Reasons:
- Allows validation before merge
- User controls merge timing
- Can review before committing to main
- Can abandon if needed
- Separates implementation from integration

### Ralph Branch: Keep or Delete?
**Recommendation: KEEP by default**

Benefits of keeping:
- Complete audit trail
- Easy reference for future work
- Debugging failed runs
- Learning from past implementations
- Compliance requirements

Option to delete:
- Manual: `git branch -d ralph/...`
- Auto-cleanup: Configure in settings
- Keep last N branches

### Cleanup Checks

**Pre-Archive Checks (Before creating archive):**
1. ✓ All stories completed
2. ✓ All tests passing
3. ✓ No uncommitted changes
4. ✓ No merge conflicts
5. ✓ Code quality passed
6. ✓ Coverage thresholds met

**Archive Completeness Checks (After archive creation):**
7. ✓ Required directories exist (spec, state, logs, artifacts, tests, git-info)
8. ✓ Required files exist (summary.md, metadata.json, spec file)
9. ✓ All story artifacts present (8/8 stories)
10. ✓ Test results archived (unit, UI, coverage, lint)
11. ✓ Git information complete (commits, diffs, branch info)
12. ✓ All logs present (parse, arch, implement, test, prove)
13. ✓ Archive structure valid (no empty dirs, all files readable)
14. ✓ Can restore from archive (metadata parseable)
15. ✓ Quota tracking archived

**Post-Merge Checks (After merge and cleanup):**
16. ✓ Working tree clean
17. ✓ On origin branch
18. ✓ Ralph state removed
19. ✓ All tests still passing (regression check)
20. ✓ Merge commit in history
21. ✓ Ready for next run
