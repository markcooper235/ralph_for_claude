---
name: prove-requirements
description: Comprehensive validation that all requirements from a specification are fully implemented and tested. Locates implementations, verifies test coverage for each acceptance criterion, runs the full test suite, and generates a proof report.
argument-hint: "[spec-file] [--report]"
disable-model-invocation: true
---

# Prove Requirements - Comprehensive Requirement Validation

Validate that all requirements from a specification are fully implemented and tested.

## Usage

```
/prove-requirements [spec-file] [--report]
```

## Instructions

When this skill is invoked:

1. **Load Specification**
   - Read the specification file (PRD or OpenSpec)
   - Extract all requirements and acceptance criteria
   - Build requirement dependency graph

2. **Find Implementation**
   - For each requirement, locate implementing code
   - Use Grep to find requirement IDs in code comments
   - Map requirements to source files

3. **Find Tests**
   - Locate test files for each requirement
   - Verify test coverage for acceptance criteria
   - Check that tests actually validate the requirement

4. **Execute All Tests**
   - Check for NX workspace (`ralph/nx-workspace.json` or `nx.json`)
   - **Standard project:** run complete test suite, then `/test-spec --all`
   - **Python:** If `venv/` directory exists, run `venv/bin/pytest tests/ -v --cov` for the complete suite (not bare `pytest`)
   - **NX workspace:**
     - Run `nx run-many -t test,lint` to validate all projects
     - Or use `nx affected -t test --base=main` for changed projects only (faster in CI)
     - Map each failing test back to its NX project for scoped re-runs
   - If UI requirements exist, run `/browser-test`
   - Collect all test results

5. **Validate Acceptance Criteria**
   - For each requirement, check each acceptance criterion
   - Mark criterion as:
     - ✓ Proven: Implementation exists, tests pass
     - ⚠ Partial: Implementation exists, some tests fail
     - ✗ Missing: No implementation or no tests
     - ? Unknown: Cannot determine status

6. **Check Dependencies**
   - Ensure all requirement dependencies are satisfied
   - Verify that dependent requirements are proven first
   - Flag any circular dependencies

7. **Generate Proof Report**
   - Create comprehensive report in `ralph/feedback/<spec-id>/proof-report.md`
   - Include:
     - Overall status (All proven / Partial / Failed)
     - Per-requirement status
     - Test coverage metrics
     - Missing implementations
     - Failing tests
     - Recommendations

8. **Provide Summary**
   - Display high-level metrics
   - Highlight any blockers or failures
   - Suggest next steps

## Validation Levels

**Level 1: Implementation Exists**
- Code exists for requirement
- Code is linked to requirement ID

**Level 2: Tests Exist**
- Test file exists for requirement
- Tests cover all acceptance criteria

**Level 3: Tests Pass**
- All tests execute successfully
- No failures or errors

**Level 4: Complete Proof**
- Implementation + Tests + All Passing
- Requirement is fully proven

## Output Format

```
[Prove Requirements] Loading specification: user-auth.prd.md
[Prove Requirements] Found 8 requirements, 27 acceptance criteria
[Prove Requirements]
[Prove Requirements] Validating implementations...
[Prove Requirements] Executing test suite...
[Prove Requirements]
[Prove Requirements] ============================================
[Prove Requirements] PROOF REPORT: User Authentication System
[Prove Requirements] ============================================
[Prove Requirements]
[Prove Requirements] Overall Status: PARTIAL (6/8 requirements proven)
[Prove Requirements]
[Prove Requirements] Requirements Breakdown:
[Prove Requirements]
[Prove Requirements] ✓ REQ-001: User login with email/password
[Prove Requirements]   Implementation: src/auth/login.py:15
[Prove Requirements]   Tests: tests/test_req_001_login.py
[Prove Requirements]   Status: PROVEN (3/3 criteria met)
[Prove Requirements]   Coverage: 95%
[Prove Requirements]
[Prove Requirements] ⚠ REQ-003: Password reset flow
[Prove Requirements]   Implementation: src/auth/reset.py:10
[Prove Requirements]   Tests: tests/test_req_003_reset.py
[Prove Requirements]   Status: PARTIAL (2/3 criteria met)
[Prove Requirements]   Failures:
[Prove Requirements]     - Email notification not sending
[Prove Requirements]   Coverage: 78%
[Prove Requirements]
[Prove Requirements] ✗ REQ-004: Two-factor authentication
[Prove Requirements]   Implementation: MISSING
[Prove Requirements]   Tests: MISSING
[Prove Requirements]   Status: NOT IMPLEMENTED (0/5 criteria met)
[Prove Requirements]
[Prove Requirements] Summary:
[Prove Requirements] - Fully Proven: 6/8 (75%)
[Prove Requirements] - Partially Proven: 1/8 (12.5%)
[Prove Requirements] - Not Implemented: 1/8 (12.5%)
[Prove Requirements] - Overall Coverage: 87%
[Prove Requirements]
[Prove Requirements] Blockers:
[Prove Requirements] 1. REQ-004 has no implementation
[Prove Requirements] 2. REQ-003 has failing email notification test
[Prove Requirements]
[Prove Requirements] Recommendations:
[Prove Requirements] 1. Implement REQ-004 (estimated: 3 tasks)
[Prove Requirements] 2. Fix email notification in REQ-003
[Prove Requirements] 3. Increase test coverage for REQ-003 to 90%+
[Prove Requirements]
[Prove Requirements] Full report: ralph/feedback/user-auth/proof-report-20260223.md
[Prove Requirements]
[Prove Requirements] Create tasks for blockers? (y/n)
```

## Integration Points

- Used in Ralph Loop "Prove" phase
- Triggers `/test-spec --all` internally
- Can trigger `/browser-test` for UI requirements
- Updates tasks based on proof status
- Generates artifacts for documentation

## Examples

```
/prove-requirements ralph/specs/prds/user-auth.prd.md
```

```
/prove-requirements ralph/specs/openspecs/api-spec.openspec.yaml --report
```
