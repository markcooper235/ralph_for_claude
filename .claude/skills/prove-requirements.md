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
   - Run complete test suite
   - Run `/test-spec --all` to execute requirement tests
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
   - Create comprehensive report in `feedback/<spec-id>/proof-report.md`
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
[Prove Requirements] ✓ REQ-002: Session management
[Prove Requirements]   Implementation: src/auth/session.py:22
[Prove Requirements]   Tests: tests/test_req_002_session.py
[Prove Requirements]   Status: PROVEN (4/4 criteria met)
[Prove Requirements]   Coverage: 100%
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
[Prove Requirements] ... (4 more requirements)
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
[Prove Requirements] Full report: feedback/user-auth/proof-report-20260223.md
[Prove Requirements]
[Prove Requirements] Create tasks for blockers? (y/n)
```

## Proof Report Format

Generated markdown report:

```markdown
# Proof Report: [Specification Name]

**Date:** 2026-02-23
**Status:** Partial
**Overall Progress:** 75% (6/8 requirements)

## Executive Summary

- 6 requirements fully proven
- 1 requirement partially proven
- 1 requirement not implemented
- Average test coverage: 87%

## Detailed Results

### ✓ REQ-001: User login with email/password

**Status:** PROVEN
**Implementation:** `src/auth/login.py:15-82`
**Tests:** `tests/test_req_001_login.py`
**Coverage:** 95%

**Acceptance Criteria:**
- ✓ User can log in with email and password
- ✓ Invalid credentials return appropriate error
- ✓ Successful login creates session

**Test Results:**
- test_login_success: PASSED (45ms)
- test_login_invalid_credentials: PASSED (32ms)
- test_login_creates_session: PASSED (38ms)

### ⚠ REQ-003: Password reset flow

**Status:** PARTIAL (2/3 criteria met)
**Implementation:** `src/auth/reset.py:10-65`
**Tests:** `tests/test_req_003_reset.py`
**Coverage:** 78%

**Acceptance Criteria:**
- ✓ User can request password reset
- ✗ Email with reset link is sent
- ✓ Reset link expires after 1 hour

**Test Results:**
- test_request_reset: PASSED (51ms)
- test_email_notification: FAILED (Error: SMTP connection refused)
- test_link_expiry: PASSED (42ms)

**Failure Analysis:**
Email service not properly configured in test environment.

**Recommended Fix:**
Mock email service in tests or configure test SMTP server.

### ✗ REQ-004: Two-factor authentication

**Status:** NOT IMPLEMENTED
**Implementation:** MISSING
**Tests:** MISSING

**Acceptance Criteria:**
- ✗ User can enable 2FA
- ✗ TOTP codes are validated
- ✗ Backup codes are generated
- ✗ 2FA is required after login
- ✗ Recovery flow exists

**Recommendations:**
1. Create implementation tasks for 2FA
2. Set up TOTP library (pyotp or similar)
3. Design database schema for 2FA secrets
4. Implement UI for 2FA setup

## Dependency Graph

```
REQ-001 (User login) ← REQ-002 (Session management)
REQ-001 (User login) ← REQ-004 (2FA) [BLOCKED]
REQ-003 (Password reset) [No dependencies]
...
```

## Test Coverage by Module

| Module | Coverage | Status |
|--------|----------|--------|
| auth/login.py | 95% | ✓ |
| auth/session.py | 100% | ✓ |
| auth/reset.py | 78% | ⚠ |
| auth/2fa.py | 0% | ✗ |

## Next Steps

1. **High Priority:**
   - Fix email notification in REQ-003
   - Begin implementation of REQ-004

2. **Medium Priority:**
   - Increase coverage for auth/reset.py
   - Add integration tests for complete flows

3. **Low Priority:**
   - Performance testing
   - Security audit
```

## Integration Points

- Used in Ralph Loop "Prove" phase
- Triggers `/test-spec --all` internally
- Can trigger `/browser-test` for UI requirements
- Updates tasks based on proof status
- Generates artifacts for documentation

## Examples

```
/prove-requirements specs/prds/user-auth.prd.md
```

```
/prove-requirements specs/openspecs/api-spec.openspec.yaml --report
```
