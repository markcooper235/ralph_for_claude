# Ralph Loop v2 - Enhanced Orchestration with Subagents

Execute complete Ralph Loop with parallel subagent execution, state management, and git integration.

## Usage

```
/ralph-loop <spec-file>
```

## Instructions

This skill orchestrates the complete Ralph Loop using Task subagents for heavy operations.

### Phase 0: Initialization

**Check for existing Ralph run:**
```bash
if [ -f ralph/.ralph/state.json ]; then
  echo "Error: Ralph run already in progress"
  echo "Complete or archive current run first: /ralph-archive"
  exit 1
fi
```

**Create Ralph state directory:**
```bash
mkdir -p ralph/.ralph/{state,logs,artifacts}
```

**Initialize state file:**
- Read `ralph/.ralph-state-template.json`
- Create `ralph/.ralph/state.json` with:
  - runId: `<spec-name>-<timestamp>`
  - specFile: path provided
  - status: "parsing"
  - createdAt: current timestamp
  - git.originBranch: current branch (detect with `git branch --show-current`)

**Create git branch:**
```bash
# Get current branch
ORIGIN_BRANCH=$(git branch --show-current)

# Generate branch name
SPEC_NAME=$(basename "$SPEC_FILE" .prd.md)
TIMESTAMP=$(date +%Y%m%d%H%M%S)
RALPH_BRANCH="ralph/${SPEC_NAME}-${TIMESTAMP}"

# Create and checkout branch
git checkout -b "$RALPH_BRANCH"

# Update state
```

Save origin and ralph branch to `ralph/.ralph/state.json`

### Phase 1: Parse Specification (Subagent)

**Launch Task subagent** to parse specification:

```
Task(
  subagent_type="general-purpose",
  description="Parse PRD specification",
  prompt=f"""
Parse the PRD specification at {spec_file}.

1. Read the PRD file
2. Extract all requirements (REQ-XXX format)
3. For each requirement, extract:
   - ID, title, description
   - Priority (high/medium/low)
   - Acceptance criteria
   - Explicit dependencies (Dependencies: field)
   - Related user stories
4. Auto-detect additional dependencies:
   - Requirements mentioning other REQ-XXX
   - Logical dependencies (delete depends on create, etc.)
   - Code impact conflicts (if existing codebase)
5. Analyze code impact:
   - Use Glob/Grep to find files each requirement will touch
   - Identify requirements modifying same files
   - Add priority-based dependencies for conflicts
6. Check for UI test requirements:
   - Keywords: UI, interface, component, page, form, button
   - File patterns: .tsx, .jsx, .vue, .svelte
   - Explicit flag: UI_TESTS_REQUIRED
7. Save parsed data to ralph/.ralph/stories.json in this format:
   {{
     "stories": [
       {{
         "id": "REQ-001",
         "title": "...",
         "description": "...",
         "priority": "high",
         "acceptanceCriteria": [...],
         "dependencies": [],  // explicit + auto-detected
         "codeImpact": {{"files": [...], "modules": [...]}}
       }}
     ],
     "testRequirements": {{
       "unit": true,
       "lint": true,
       "codeQuality": true,
       "ui": true/false,
       "integration": true
     }}
   }}
8. Return summary of parsed stories and dependencies
"""
)
```

**Wait for subagent completion**

**Load results:**
- Read `ralph/.ralph/stories.json`
- Validate structure
- Display summary to user

**Create Claude Tasks:**
- For each story in stories.json:
  - Use TaskCreate with:
    - subject: story title
    - description: full details + acceptance criteria
    - metadata: { requirementId: "REQ-XXX", storyFile: "REQ-XXX.json" }
  - Save taskId to story data
  - Update `ralph/.ralph/stories.json` with taskIds

**Update state:**
- status: "architecture"
- stories: loaded from stories.json
- progress.totalStories: count

### Phase 2: Architecture (Subagent)

**Launch Task subagent** for architecture design:

```
Task(
  subagent_type="general-purpose",
  description="Design architecture approach",
  prompt=f"""
Design implementation architecture for the parsed requirements.

1. Load stories from ralph/.ralph/stories.json
2. Analyze existing codebase:
   - Project structure
   - Existing patterns
   - Technology stack
   - Test setup
3. Design approach:
   - Where each requirement will be implemented
   - What patterns to use
   - What new files/modules needed
   - Test strategy per requirement
4. Determine test tools:
   - Lint: ESLint/Black/Clippy (based on language)
   - Unit: Jest/pytest/cargo test
   - UI: Playwright (if ui tests required)
   - Code quality: SonarLint/complexity metrics
5. Create architecture decision record
6. Save to ralph/.ralph/architecture.json:
   {{
     "projectType": "web-frontend|backend|api|library|cli",
     "techStack": [...],
     "testTools": {{
       "lint": "eslint",
       "unit": "jest",
       "ui": "playwright",
       "codeQuality": "sonar"
     }},
     "implementation": {{
       "REQ-001": {{
         "files": ["src/auth/login.ts"],
         "tests": ["tests/auth/login.test.ts"],
         "approach": "..."
       }}
     }}
   }}
7. Return architecture summary
"""
)
```

**Wait for completion**

**Update state:**
- status: "implementing"

### Phase 3: Implementation Loop (Parallel Subagents)

**Determine execution phases:**

```python
# Pseudo-code for phase determination
phases = []
completed = set()

while stories_remaining:
    # Find ready stories (no deps or all deps satisfied)
    ready = [s for s in stories if all(d in completed for d in s.dependencies)]

    # Group by code impact (stories touching same files must be sequential)
    conflict_groups = group_by_code_conflicts(ready)

    # Phase contains up to 3 non-conflicting stories
    phase_stories = select_up_to_3_non_conflicting(ready, conflict_groups)

    phases.append(phase_stories)
```

**For each phase:**

**Launch parallel subagents (max 3):**

```python
subagents = []
for story in phase_stories:
    subagent = Task(
        subagent_type="general-purpose",
        description=f"Implement {story['id']}",
        prompt=f"""
Implement story {story['id']}: {story['title']}

Story details:
- Description: {story['description']}
- Acceptance Criteria: {story['acceptanceCriteria']}
- Files to modify: {story['codeImpact']['files']}

Instructions:
1. Load architecture plan from ralph/.ralph/architecture.json
2. Implement the requirement following the plan
3. Write tests for all acceptance criteria:
   - Test file: {test_file}
   - One test per acceptance criterion
   - Test names: test_req_xxx_criterion_n
4. Run tests locally to verify
5. List all files created/modified
6. Save implementation summary to ralph/.ralph/artifacts/{story['id']}-impl.json:
   {{
     "storyId": "{story['id']}",
     "status": "completed",
     "files": [...],
     "tests": [...],
     "testResults": "passed|failed",
     "iterations": 1
   }}
7. DO NOT commit yet (commits happen later)
8. Return implementation summary
""",
        run_in_background=False
    )
    subagents.append(subagent)
```

**Wait for all phase subagents to complete**

**Check results:**
- For each story in phase:
  - Read `ralph/.ralph/artifacts/{story-id}-impl.json`
  - Check status
  - Update story status in `ralph/.ralph/stories.json`
  - Update TaskUpdate with status

**Mark completed stories:**
- Add to completed set
- Move to next phase

### Phase 4: Testing Loop (After Each Story)

**For each completed story, run comprehensive tests:**

**Launch test subagent:**

```
Task(
  subagent_type="Bash",
  description=f"Test story {story_id}",
  prompt=f"""
Run comprehensive tests for {story_id}.

1. Load test tools from ralph/.ralph/architecture.json
2. Run all tests in sequence:

   A. Lint/Format:
      - Run appropriate linter (eslint/black/clippy)
      - Capture full output
      - Auto-fix if possible
      - Max 3 iterations for formatting issues

   B. Unit Tests:
      - Run tests for this story
      - Capture output and coverage
      - Max 5 iterations for logic failures

   C. Code Quality:
      - Run quality checks (complexity, duplication)
      - Capture output

   D. UI Tests (if required):
      - Run Playwright tests for affected components
      - Capture screenshots and results
      - Max 5 iterations

3. Save results to ralph/.ralph/artifacts/{story_id}-tests.json:
   {{
     "storyId": "{story_id}",
     "lint": {{"status": "passed", "output": "...", "iterations": 1}},
     "unit": {{"status": "passed", "output": "...", "coverage": 85}},
     "ui": {{"status": "passed", "output": "..."}},
     "codeQuality": {{"status": "passed", "output": "..."}}
   }}

4. Overall status: "passed" only if ALL tests pass

5. Return test summary with pass/fail status
"""
)
```

**Handle test failures:**

If any test fails:
1. Check iteration limits:
   - Formatting: max 3
   - Logic: max 5
2. If under limit:
   - Create fix task: TaskCreate
   - Assign fix task to story subagent
   - Re-run tests
   - Increment iteration count
3. If over limit:
   - Pause execution
   - Ask user for intervention
   - Wait for user fixes
   - Resume when user ready

**When all tests pass:**
- Update story status: "completed"
- Update TaskUpdate: status="completed"
- Save test results to `ralph/.ralph/artifacts/`

### Phase 5: Commit Story

**For each completed story, create single commit:**

```bash
# Get story files
FILES=$(jq -r '.files[]' ralph/.ralph/artifacts/${STORY_ID}-impl.json)
TEST_FILES=$(jq -r '.tests[]' ralph/.ralph/artifacts/${STORY_ID}-impl.json)

# Stage files
git add $FILES $TEST_FILES

# Create commit message
COMMIT_MSG="$(cat <<EOF
${STORY_ID}: ${STORY_TITLE}

${STORY_DESCRIPTION}

Acceptance Criteria:
$(echo "$CRITERIA" | sed 's/^/- /')

Tests: All passing
- Unit tests: passed
- Lint: passed
- Code quality: passed
$([ "$UI_REQUIRED" = "true" ] && echo "- UI tests: passed")

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
EOF
)"

# Commit
git commit -m "$COMMIT_MSG"

# Save commit hash
COMMIT_HASH=$(git rev-parse HEAD)
```

**Update state:**
- Add commit to story.commits[]
- Add commit to state.git.commits[]

### Phase 6: Prove Requirements (After All Stories Complete)

**Launch prove subagent:**

```
Task(
  subagent_type="general-purpose",
  description="Prove all requirements met",
  prompt="""
Comprehensive validation that all requirements are met.

1. Load all stories from ralph/.ralph/stories.json
2. For each story:
   - Verify implementation exists
   - Verify tests exist and pass
   - Verify all acceptance criteria met
   - Check test coverage
3. Run full test suite:
   - All unit tests
   - All integration tests
   - All UI tests (if applicable)
   - Lint entire codebase
   - Code quality on all files
4. Generate proof report:
   - Per-requirement status
   - Overall coverage
   - Any gaps or failures
5. Save to ralph/.ralph/artifacts/proof-report.json and .md
6. Return summary: passed/failed with details
"""
)
```

**Check proof results:**
- If any requirement not proven:
  - Create fix tasks
  - Return to implementation loop
  - Max 5 iterations total
- If all proven:
  - Continue to harvest

### Phase 7: Harvest Feedback

**Update state:**
- status: "harvesting"

**Collect all artifacts:**
- All test results
- All implementation summaries
- Proof report
- Git commit history
- Iteration counts

**Generate harvest summary:**
```
ralph/.ralph/artifacts/harvest-summary.md:
- Total stories: X
- Total commits: Y
- Test coverage: Z%
- Iterations used: A logic, B formatting
- Total time: HH:MM:SS
- All requirements: PROVEN
```

**Update state:**
- status: "complete"
- feedback: summary

### Phase 8: Pre-Merge Validation

**Run final checks:**

1. **All tests pass:**
   ```bash
   # Run complete test suite
   npm test  # or pytest, cargo test, etc.
   ```

2. **No uncommitted changes:**
   ```bash
   git status --porcelain
   # Should be empty
   ```

3. **No conflicts with origin:**
   ```bash
   git fetch origin
   git merge-base --is-ancestor origin/$ORIGIN_BRANCH HEAD
   ```

4. **All stories completed:**
   - Check `ralph/.ralph/stories.json`
   - All status: "completed"

5. **No inter-story conflicts:**
   - Check for any merge conflicts between story commits
   - Resolve if any found

**If any check fails:**
- Display failure reason
- Ask user to fix
- Do not proceed to merge

**If all checks pass:**
- Display success message
- Proceed to completion

### Phase 9: Mark Ready for Archive

**Update state:**
- status: "ready_for_archive"

**Display completion message:**

```
[Ralph Loop] ✓ All requirements PROVEN!
[Ralph Loop]
[Ralph Loop] Summary:
[Ralph Loop] - Stories completed: 8/8
[Ralph Loop] - Test coverage: 92%
[Ralph Loop] - Commits: 8 (one per story)
[Ralph Loop] - Branch: ralph/user-auth-20260223145023
[Ralph Loop]
[Ralph Loop] Next step: /ralph-archive
[Ralph Loop]
[Ralph Loop] This will:
[Ralph Loop] 1. Archive all artifacts to ralph/archive/user-auth-20260223145023/
[Ralph Loop] 2. Merge to {origin_branch}
[Ralph Loop] 3. Clean up Ralph state
[Ralph Loop] 4. Prepare for next run
```

**Do not merge yet** - that's done by `/ralph-archive`

### Error Handling

**At any phase, if error occurs:**
1. Save error to `ralph/.ralph/state.json`
2. Log to `ralph/.ralph/logs/error.log`
3. Update status: "failed"
4. Display error to user
5. Provide recovery options:
   - Fix and resume
   - Abandon run (requires /ralph-archive --abandon)

### State Persistence

**After each phase, save:**
- `ralph/.ralph/state.json` - current state
- `ralph/.ralph/stories.json` - all stories with status
- `ralph/.ralph/logs/<phase>.log` - phase execution log
- `ralph/.ralph/artifacts/` - all artifacts generated

**State is never committed to git** - only archived

## Examples

```bash
# Start new Ralph run
/ralph-loop ralph/specs/prds/user-auth.prd.md

# Claude will:
# 1. Create branch: ralph/user-auth-20260223145023
# 2. Parse spec and create 8 stories
# 3. Design architecture
# 4. Implement in phases with max 3 parallel
# 5. Test each story comprehensively
# 6. Commit each story individually
# 7. Prove all requirements
# 8. Mark ready for archive
```

## Integration with Other Skills

- Uses `/ralph-create-prd` for spec creation
- Uses `/test-spec` internally (via subagents)
- Uses `/browser-test` for UI tests
- Prepares for `/ralph-archive` for completion

## Notes

- This skill orchestrates; subagents do the work
- Max 3 parallel subagents at a time
- Each story = 1 Claude Task
- State persists across all phases
- Git branch created at start
- Merge happens in `/ralph-archive`
