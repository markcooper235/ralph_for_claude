# Parse OpenSpec - OpenSpec Format Parser

Parse OpenSpec declarative specifications and extract behavioral contracts.

## Usage

```
/parse-openspec <openspec-file-path>
```

## Instructions

When this skill is invoked:

1. **Read OpenSpec Document**
   - Load the specified OpenSpec file
   - Validate format and syntax
   - Extract metadata and declarations

2. **Parse OpenSpec Sections**

   **Type Declarations**
   - Interface definitions
   - Type signatures
   - Data structures
   - Constraints and invariants

   **Behavioral Contracts**
   - Pre-conditions (require)
   - Post-conditions (ensure)
   - Invariants (maintain)
   - Side effects

   **Property-Based Specifications**
   - Properties that must hold for all inputs
   - Generators for test data
   - Invariant checks

   **Examples**
   - Concrete example inputs/outputs
   - Edge cases
   - Error scenarios

3. **Generate Test Strategy**

   From OpenSpec, derive:
   - **Type tests**: Validate type constraints
   - **Property tests**: Use property-based testing
   - **Example tests**: Convert examples to unit tests
   - **Contract tests**: Validate pre/post conditions

4. **Create Structured Output**

   ```json
   {
     "metadata": {
       "name": "...",
       "version": "..."
     },
     "types": [
       {
         "name": "User",
         "properties": [],
         "constraints": []
       }
     ],
     "contracts": [
       {
         "function": "login",
         "preconditions": [],
         "postconditions": [],
         "invariants": []
       }
     ],
     "properties": [
       {
         "name": "login_idempotent",
         "property": "login(u) == login(login(u))"
       }
     ],
     "examples": []
   }
   ```

5. **Generate Tasks**
   - Create task for each major contract
   - Create task for property-based test setup
   - Create task for example implementations
   - Set dependencies based on type dependencies

6. **Generate Test Code**
   - Create property-based tests (using Hypothesis, fast-check, etc.)
   - Create contract validation tests
   - Create example-based tests
   - Save to appropriate test directory

## OpenSpec Template Reference

Expected format:
```yaml
name: UserAuthentication
version: 1.0

types:
  User:
    email: string
    passwordHash: string
    constraints:
      - email matches /^[^\s@]+@[^\s@]+\.[^\s@]+$/

contracts:
  login:
    signature: (email: string, password: string) -> Result<Session, Error>
    require:
      - email is valid email format
      - password length >= 8
    ensure:
      - if success, session.user.email == email
      - if success, session.expiresAt > now()
      - if failure, no session is created
    examples:
      - input: { email: "user@example.com", password: "securepass123" }
        output: { success: true, session: {...} }
      - input: { email: "invalid", password: "short" }
        output: { success: false, error: "INVALID_CREDENTIALS" }

properties:
  login_deterministic:
    forAll: [email, password]
    holds: login(email, password) == login(email, password)
```

## Output Format

```
[Parse OpenSpec] Reading: specs/openspecs/user-auth.openspec.yaml
[Parse OpenSpec]
[Parse OpenSpec] Specification: UserAuthentication v1.0
[Parse OpenSpec]
[Parse OpenSpec] Parsed Structure:
[Parse OpenSpec] - 3 Type definitions
[Parse OpenSpec] - 5 Behavioral contracts
[Parse OpenSpec] - 8 Properties to verify
[Parse OpenSpec] - 12 Examples
[Parse OpenSpec]
[Parse OpenSpec] Contracts:
[Parse OpenSpec]
[Parse OpenSpec] login(email, password) -> Result<Session, Error>
[Parse OpenSpec]   Preconditions: 2
[Parse OpenSpec]   Postconditions: 3
[Parse OpenSpec]   Examples: 4
[Parse OpenSpec]   Properties: 2 (deterministic, idempotent)
[Parse OpenSpec]
[Parse OpenSpec] Test Strategy:
[Parse OpenSpec] - Property-based tests: 8 properties to check
[Parse OpenSpec] - Contract tests: 5 contracts to validate
[Parse OpenSpec] - Example tests: 12 examples to implement
[Parse OpenSpec] - Type tests: 3 types to validate
[Parse OpenSpec]
[Parse OpenSpec] Generating test code...
[Parse OpenSpec] ✓ Property tests: tests/properties/test_user_auth_properties.py
[Parse OpenSpec] ✓ Contract tests: tests/contracts/test_user_auth_contracts.py
[Parse OpenSpec] ✓ Example tests: tests/examples/test_user_auth_examples.py
[Parse OpenSpec]
[Parse OpenSpec] Creating 5 tasks...
[Parse OpenSpec] ✓ Task 1: Implement User type with constraints
[Parse OpenSpec] ✓ Task 2: Implement login contract
[Parse OpenSpec] ✓ Task 3: Implement logout contract (blocked by Task 2)
[Parse OpenSpec] ✓ Task 4: Setup property-based testing framework
[Parse OpenSpec] ✓ Task 5: Validate all contracts
[Parse OpenSpec]
[Parse OpenSpec] Structured data saved: specs/openspecs/user-auth.parsed.json
[Parse OpenSpec]
[Parse OpenSpec] Ready to start Ralph Loop? (y/n)
```

## Test Generation

Automatically generate:

**Property-Based Tests (Python with Hypothesis)**
```python
from hypothesis import given, strategies as st

@given(st.emails(), st.text(min_size=8))
def test_login_deterministic(email, password):
    result1 = login(email, password)
    result2 = login(email, password)
    assert result1 == result2
```

**Contract Tests**
```python
def test_login_contract():
    # Precondition checks
    with pytest.raises(ValueError):
        login("invalid-email", "password")

    # Valid execution
    result = login("user@example.com", "password123")

    # Postcondition checks
    assert result.session.user.email == "user@example.com"
    assert result.session.expiresAt > datetime.now()
```

## Examples

```
/parse-openspec specs/openspecs/user-auth.openspec.yaml
```

## Integration Points

- Used by `/ralph-loop` for specification intake
- Generates property-based tests automatically
- Creates contract validation tests
- Integrates with `/test-spec` for execution
