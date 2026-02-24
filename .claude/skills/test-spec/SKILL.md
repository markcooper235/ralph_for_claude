---
name: test-spec
description: Test implementation against specification requirements. Validates acceptance criteria, runs appropriate test suites (pytest, Jest, go test, cargo test), updates task status, and generates detailed feedback reports.
argument-hint: [requirement-id] [--all] [--verbose]
disable-model-invocation: true
---

# Test Spec - Requirement Validation Skill

Test implementation against specification requirements with detailed feedback.

## Usage

```
/test-spec [requirement-id] [--all] [--verbose]
```

## NX Workspace Detection

Before executing any tests, check for an NX workspace:
- Check `.ralph/nx-workspace.json` — exists if project was created with `--type nx`
- Or check `nx.json` in project root

If NX workspace, determine which project(s) to scope tests to:
1. Read the requirement's `nx_projects` field from the PRD metadata (if present)
2. If not specified, check `.ralph/nx-workspace.json` for all project names and ask user which applies
3. Use `nx run <project>:test` instead of bare test commands

## Instructions

When this skill is invoked:

1. **Load Specification**
   - Find the active specification (from task metadata or ask user)
   - Parse all requirements and acceptance criteria
   - If requirement-id provided, focus on that specific requirement
   - If --all flag, test all requirements in spec

2. **Identify Tests**
   - Map requirements to test files
   - Convention: REQ-001 → test_req_001 or req_001_test
   - Support multiple test frameworks:
     - Python: pytest, unittest
     - JavaScript: Jest, Mocha, Vitest
     - Go: go test
     - Rust: cargo test
   - If tests don't exist, create them based on acceptance criteria

3. **Execute Tests**
   - Run tests for the specified requirement(s)
   - Capture:
     - Pass/fail status
     - Execution time
     - Error messages
     - Stack traces
     - Coverage data (if available)
   - Use appropriate test command based on project type

4. **Analyze Results**
   - Compare test results against acceptance criteria
   - Identify which criteria are met vs. not met
   - Determine if requirement is fully satisfied
   - Generate detailed feedback

5. **Update Tasks**
   - If tests pass: update related task to 'completed'
   - If tests fail: keep task as 'in_progress', add failure details to task description
   - Create new tasks for failing test cases if needed

6. **Generate Report**
   - Create test report in `feedback/<spec-id>/test-results/`
   - Include:
     - Timestamp
     - Requirements tested
     - Pass/fail status for each
     - Coverage metrics
     - Performance metrics
     - Recommendations for fixes

7. **Feedback Loop**
   - For failures, provide actionable feedback:
     - What failed
     - Why it likely failed
     - Suggested fixes
     - Related code locations
   - Offer to fix issues immediately or create tasks

## Test Execution by Project Type

### NX Monorepo Projects
```bash
# Run tests for a specific NX project
nx run <project>:test

# Run with test name filter (Jest)
nx run <project>:test -- --testNamePattern="REQ-001"

# Run with test name filter (Vitest)
nx run <project>:test -- --reporter=verbose -t "REQ-001"

# Run all projects
nx run-many -t test

# Run only affected projects (CI-friendly)
nx affected -t test --base=main

# Run lint for a specific project
nx run <project>:lint
```

### Python Projects
```bash
pytest tests/test_req_*.py -v --cov
```

### JavaScript/TypeScript
```bash
npm test -- --testNamePattern="REQ-001"
# or
npx vitest run -t "REQ-001"
```

### Go Projects
```bash
go test ./... -run TestReq001
```

### Rust Projects
```bash
cargo test req_001 -- --nocapture
```

## Output Format

```
[Test Spec] Testing requirement: REQ-001 (User Authentication)
[Test Spec] Running: pytest tests/test_req_001_*.py
[Test Spec] ✓ Acceptance criteria 1: User can log in with email
[Test Spec] ✓ Acceptance criteria 2: Invalid credentials return error
[Test Spec] ✗ Acceptance criteria 3: Session persists after login
[Test Spec]
[Test Spec] Results: 2/3 criteria met (66.7%)
[Test Spec] Status: FAILING
[Test Spec]
[Test Spec] Failure Analysis:
[Test Spec] - Session token not being stored correctly
[Test Spec] - Suggested fix: Check session middleware configuration
[Test Spec] - Location: src/auth/session.py:45
[Test Spec]
[Test Spec] Create task to fix this issue? (y/n)
```

## Examples

### Test specific requirement
```
/test-spec REQ-001
```

### Test all requirements
```
/test-spec --all
```

### Verbose output with debug info
```
/test-spec REQ-001 --verbose
```

## Integration Points

- Updates Claude tasks based on test results
- Generates feedback for Ralph Loop harvest phase
- Can trigger browser tests for UI requirements
- Integrates with CI/CD pipelines
