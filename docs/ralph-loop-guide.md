# Ralph Loop Framework - Complete Guide

## Table of Contents

1. [Introduction](#introduction)
2. [Core Concepts](#core-concepts)
3. [The Loop Phases](#the-loop-phases)
4. [Specification Formats](#specification-formats)
5. [Skills Reference](#skills-reference)
6. [Task Management](#task-management)
7. [Testing Strategies](#testing-strategies)
8. [Feedback Mechanisms](#feedback-mechanisms)
9. [Advanced Topics](#advanced-topics)
10. [Best Practices](#best-practices)

---

## Introduction

The Ralph Loop Framework is a specification-driven development system designed specifically for Claude Code. It combines formal specifications, automated testing, and intelligent task management to create a continuous feedback loop that ensures requirements are met.

### What Makes Ralph Loop Different?

**Traditional Development:**
```
Requirements → Code → Test → Debug → Hope it works
```

**Ralph Loop Development:**
```
Specification → Parse → Architecture → Implement (with continuous testing) → Prove → Harvest → Iterate
```

### Key Benefits

1. **Specification-First**: Requirements are formalized before coding begins
2. **Continuous Validation**: Every implementation is immediately tested
3. **Intelligent Adaptation**: Testing strategies adapt to project type
4. **Clear Progress Tracking**: Task system provides real-time status
5. **Automated Feedback**: Results feed back into the loop automatically

---

## Core Concepts

### The RALPH Acronym

- **R**equirement: Formal specification of what needs to be built
- **A**rchitecture: Design approach based on requirements and context
- **L**oop: Iterative implementation with continuous testing
- **P**rove: Comprehensive validation that requirements are met
- **H**arvest: Collection of feedback to inform next iteration

### Specifications as Contracts

Specifications in Ralph Loop are treated as contracts between intent and implementation:

```
INTENT (What we want) ←→ SPECIFICATION ←→ IMPLEMENTATION (What we build)
                              ↓
                           TESTS (How we prove it)
```

### Feedback Loop

```
┌─────────────┐
│ Requirement │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│Architecture │
└──────┬──────┘
       │
       ▼
┌─────────────┐     ┌──────────┐
│  Implement  │────→│   Test   │
└──────┬──────┘     └────┬─────┘
       │                 │
       ▼                 ▼
┌─────────────┐     ┌──────────┐
│    Prove    │←────│ Feedback │
└──────┬──────┘     └──────────┘
       │
       ▼
┌─────────────┐
│   Harvest   │────┐
└─────────────┘    │
       ▲           │
       └───────────┘
      (Loop if needed)
```

---

## The Loop Phases

### Phase 1: Requirement Intake

**Purpose**: Transform informal requirements into formal specifications

**Activities**:
- Parse PRD or OpenSpec documents
- Extract requirements and acceptance criteria
- Identify dependencies
- Create initial task breakdown

**Skills**: `/parse-prd`, `/parse-openspec`

**Output**:
- Structured requirement data
- Task list with dependencies
- Test checklist

### Phase 2: Architecture

**Purpose**: Design implementation approach

**Activities**:
- Analyze existing codebase
- Identify patterns and conventions
- Make architectural decisions
- Plan technical approach
- Ask clarifying questions if needed

**Skills**: Used internally by `/ralph-loop`

**Output**:
- Architecture decision records
- Implementation plan
- Technical approach document

### Phase 3: Loop Execution (Implementation)

**Purpose**: Implement requirements with continuous testing

**Activities**:
- For each task:
  1. Mark task as in-progress
  2. Implement requirement
  3. Write/update tests
  4. Run tests
  5. Mark complete if passing
  6. Create new tasks if issues found
- Continue until all tasks complete

**Skills**: `/test-spec`, `/browser-test`

**Output**:
- Implementation code
- Test code
- Test results
- Task progress updates

### Phase 4: Prove

**Purpose**: Comprehensive validation of all requirements

**Activities**:
- Run complete test suite
- Validate each acceptance criterion
- Check coverage metrics
- Generate proof report

**Skills**: `/prove-requirements`, `/test-spec --all`

**Output**:
- Proof report with per-requirement status
- Coverage metrics
- List of unmet requirements
- Recommendations

### Phase 5: Harvest

**Purpose**: Collect feedback and plan iteration

**Activities**:
- Analyze test results
- Identify failure patterns
- Create tasks for fixes
- Decide if another iteration needed
- Generate summary report

**Skills**: Used internally by `/ralph-loop`

**Output**:
- Feedback summary
- New tasks for next iteration
- Iteration decision
- Lessons learned

---

## Specification Formats

### PRD (Product Requirements Document)

**Best For:**
- Product features
- User-facing functionality
- Business requirements
- MVP definitions

**Structure:**
```markdown
# Project Name

## Problem Statement
What problem are we solving?

## User Stories
US-001: As a [user], I want [action], so that [benefit]

## Functional Requirements
REQ-001: [Description] (Priority: High/Medium/Low)
- Acceptance Criteria:
  - [ ] Criterion 1
  - [ ] Criterion 2

## Non-Functional Requirements
NFREQ-001: Performance, security, etc.

## Success Metrics
How do we measure success?
```

**Template**: `.claude/templates/prd-template.md`

### OpenSpec (Declarative Specification)

**Best For:**
- APIs and services
- Libraries and SDKs
- Technical specifications
- Systems with formal contracts

**Structure:**
```yaml
name: ProjectName
version: 1.0.0

types:
  TypeName:
    property: type
    constraints:
      - constraint description

contracts:
  functionName:
    signature: (args) -> return
    require:  # preconditions
      - condition
    ensure:   # postconditions
      - condition
    examples:
      - input: {...}
        output: {...}

properties:
  property_name:
    forAll: [variables]
    holds: condition
```

**Template**: `.claude/templates/openspec-template.yaml`

### Choosing Between PRD and OpenSpec

| Aspect | PRD | OpenSpec |
|--------|-----|----------|
| Formality | Moderate | High |
| Test Generation | Manual | Automatic |
| Best Domain | Product features | Technical systems |
| Learning Curve | Easy | Moderate |
| Precision | Good | Excellent |

**Recommendation**: Start with PRD for most projects, use OpenSpec for APIs and libraries.

---

## Skills Reference

### Core Loop Skills

#### `/ralph-loop`
**Purpose**: Main orchestrator for complete development cycle

**Usage:**
```bash
/ralph-loop <spec-file> [--phase=<phase>] [--resume=<checkpoint>]
```

**Examples:**
```bash
# Full loop
/ralph-loop ralph/specs/prds/feature.prd.md

# Specific phase
/ralph-loop ralph/specs/prds/feature.prd.md --phase=implement

# Resume from checkpoint
/ralph-loop --resume=feature-checkpoint-3
```

**When to Use**: Starting new feature development from spec

---

#### `/test-spec`
**Purpose**: Test implementation against specific requirements

**Usage:**
```bash
/test-spec [requirement-id] [--all] [--verbose]
```

**Examples:**
```bash
# Test one requirement
/test-spec REQ-001

# Test all
/test-spec --all

# Verbose output
/test-spec REQ-001 --verbose
```

**When to Use**: After implementing a requirement, during debugging

---

#### `/prove-requirements`
**Purpose**: Comprehensive validation of all requirements

**Usage:**
```bash
/prove-requirements <spec-file> [--report]
```

**Examples:**
```bash
/prove-requirements ralph/specs/prds/feature.prd.md --report
```

**When to Use**: Before deployment, milestone validation, demo preparation

---

### Parsing Skills

#### `/parse-prd`
**Purpose**: Parse PRD documents into structured tasks

**Usage:**
```bash
/parse-prd <prd-file>
```

**When to Use**: Before starting loop, validating spec format

---

#### `/parse-openspec`
**Purpose**: Parse OpenSpec and generate tests

**Usage:**
```bash
/parse-openspec <openspec-file>
```

**When to Use**: API development, contract-based testing

---

### Testing Skills

#### `/browser-test`
**Purpose**: Browser-based UI testing with Playwright

**Usage:**
```bash
/browser-test [component-path] [--interactive] [--visual-regression] [--a11y]
```

**Examples:**
```bash
# Test component
/browser-test src/components/LoginForm.tsx

# Interactive mode
/browser-test --interactive

# Full suite with visual and a11y
/browser-test --visual-regression --a11y
```

**When to Use**: UI components, user flows, accessibility validation

---

#### `/feedback-selector`
**Purpose**: Determine optimal feedback methods for project

**Usage:**
```bash
/feedback-selector [--analyze-only] [--setup]
```

**Examples:**
```bash
# Analyze and recommend
/feedback-selector

# Setup tools
/feedback-selector --setup
```

**When to Use**: Project start, when adding new project types

---

## Task Management

### How Tasks Work in Ralph Loop

1. **Creation**: Tasks are created from requirements
2. **Dependencies**: Linked via `blockedBy`/`blocks`
3. **Metadata**: Include requirement IDs, test status
4. **Updates**: Automatically updated by test results
5. **Completion**: Marked complete when tests pass

### Task Lifecycle

```
pending → in_progress → completed
   ↓
deleted (if obsolete)
```

### Task Best Practices

1. **One Task Per Requirement**: Each REQ-XXX maps to 1-3 tasks
2. **Clear Acceptance Criteria**: Include in task description
3. **Link to Tests**: Reference test files in task metadata
4. **Update Promptly**: Mark in_progress when starting, completed when done
5. **Add Context**: Include file paths, line numbers, relevant info

### Viewing Tasks

Use Claude's built-in task commands:
- `TaskList` - View all tasks
- `TaskGet <id>` - View specific task
- `TaskUpdate <id>` - Update task status

---

## Testing Strategies

### Unit Testing

**When**: Testing individual functions, components, classes

**Tools**: Jest, Vitest, pytest, go test, cargo test

**Generated By**: `/parse-prd`, `/parse-openspec`

**Example Structure**:
```
tests/
├── test_req_001_user_login.py
├── test_req_002_session.py
└── test_req_003_password_reset.py
```

### Integration Testing

**When**: Testing interactions between components, API endpoints

**Tools**: Supertest, requests, integration test frameworks

**Generated By**: `/parse-openspec` (for API contracts)

**Example Structure**:
```
tests/integration/
├── test_user_flow.py
└── test_api_endpoints.py
```

### Browser Testing

**When**: Testing UI, user interactions, visual consistency

**Tools**: Playwright (preferred), Puppeteer, Selenium

**Triggered By**: `/browser-test`, auto-detected by `/feedback-selector`

**Capabilities**:
- Functional testing (clicks, forms, navigation)
- Visual regression (screenshot comparison)
- Accessibility (WCAG compliance)
- Performance (Lighthouse metrics)

### Property-Based Testing

**When**: Testing mathematical properties, invariants, contracts

**Tools**: Hypothesis (Python), fast-check (JavaScript), QuickCheck (Haskell)

**Generated By**: `/parse-openspec` (from properties section)

**Example**:
```python
@given(st.emails(), st.text(min_size=8))
def test_login_deterministic(email, password):
    result1 = login(email, password)
    result2 = login(email, password)
    assert result1 == result2
```

### Contract Testing

**When**: Testing API contracts, service boundaries

**Tools**: Pact, Spring Cloud Contract

**Generated By**: `/parse-openspec` (from contracts section)

---

## Feedback Mechanisms

### How Feedback Works

```
Test Execution → Results → Analysis → Task Updates → Next Iteration
```

### Feedback Types

1. **Pass/Fail**: Binary test results
2. **Coverage**: Code coverage metrics
3. **Performance**: Timing, memory, resource usage
4. **Visual**: Screenshot comparisons
5. **Accessibility**: WCAG violations
6. **Static Analysis**: Linting, type errors

### Feedback Configuration

Auto-generated by `/feedback-selector` in `.claude/feedback-configs/feedback-config.json`:

```json
{
  "projectType": "frontend-web",
  "feedbackMethods": [
    {
      "method": "browser-test",
      "priority": "high",
      "frequency": "per-requirement",
      "tool": "playwright",
      "thresholds": {
        "passRate": 100,
        "a11yViolations": 0
      }
    }
  ]
}
```

### Customizing Feedback

Edit the config file to:
- Add new feedback methods
- Adjust thresholds
- Change execution frequency
- Configure CI/CD integration

---

## Advanced Topics

### Checkpoint System

**Purpose**: Save loop state for resumption

**Location**: `.claude/checkpoints/<spec-id>/`

**Contents**:
- Current phase
- Task states
- Test results
- Architecture decisions

**Usage**:
```bash
/ralph-loop --resume=<checkpoint-id>
```

### Multi-Spec Projects

For projects with multiple specifications:

```
specs/
├── prds/
│   ├── auth.prd.md
│   ├── dashboard.prd.md
│   └── api.prd.md
└── openspecs/
    └── api-contracts.openspec.yaml
```

Run loops independently or in sequence:
```bash
/ralph-loop ralph/specs/prds/auth.prd.md
/ralph-loop ralph/specs/prds/dashboard.prd.md --phase=implement
```

### CI/CD Integration

Ralph Loop can integrate with CI/CD:

```yaml
# .github/workflows/ralph-loop.yml
name: Ralph Loop CI

on: [push, pull_request]

jobs:
  prove-requirements:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Prove Requirements
        run: |
          # Run prove-requirements for each spec
          /prove-requirements ralph/specs/prds/*.prd.md
```

### Custom Skills

Create project-specific skills in `.claude/skills/`:

```markdown
# My Custom Skill

## Usage
/my-skill [args]

## Instructions
1. Step one
2. Step two
3. Output results
```

Claude will automatically detect and use custom skills.

---

## Best Practices

### Specification Writing

1. **Be Specific**: Vague requirements lead to vague implementations
2. **Make It Testable**: Every requirement should have measurable criteria
3. **Include Examples**: Concrete examples clarify intent
4. **Document Constraints**: State assumptions and limitations
5. **Prioritize**: Mark high/medium/low priority

### Task Management

1. **Small Tasks**: Break large requirements into 1-3 small tasks
2. **Clear Descriptions**: Include context, acceptance criteria, links
3. **Set Dependencies**: Use blockedBy for proper sequencing
4. **Update Promptly**: Keep task status current
5. **Add Metadata**: Link tasks to requirements and tests

### Testing

1. **Test Early**: Write tests as you implement
2. **Test Often**: Run `/test-spec` after each change
3. **Test Completely**: Use `/prove-requirements` before milestones
4. **Test Appropriately**: Use right tool (unit vs browser vs integration)
5. **Test Automatically**: Integrate with CI/CD

### Loop Execution

1. **Start Small**: Begin with core requirements
2. **Iterate Quickly**: Short loops are better than long ones
3. **Harvest Feedback**: Learn from each iteration
4. **Adapt Strategy**: Adjust based on feedback
5. **Document Decisions**: Record architectural choices

### Debugging Failed Tests

When tests fail:

1. **Read the Failure**: Understand what actually failed
2. **Check the Requirement**: Ensure it's correctly understood
3. **Review Implementation**: Look for logic errors
4. **Verify Test**: Confirm test correctly validates requirement
5. **Isolate Issue**: Use minimal reproduction
6. **Create Task**: Make a task for the fix

### Performance

1. **Parallelize**: Run independent tests in parallel
2. **Cache Results**: Reuse test results when code unchanged
3. **Optimize Slow Tests**: Identify and improve bottlenecks
4. **Use Appropriate Granularity**: Don't over-test
5. **Monitor Metrics**: Track test execution time

---

## Troubleshooting

### Common Issues

**Issue**: Loop gets stuck in implementation phase
**Solution**: Check task dependencies, ensure tests are executable

**Issue**: Tests always fail
**Solution**: Verify test setup, check test environment, review acceptance criteria

**Issue**: Cannot parse specification
**Solution**: Check format against template, ensure proper structure

**Issue**: Wrong feedback method selected
**Solution**: Override with custom config in `.claude/feedback-configs/`

**Issue**: Tasks not created from requirements
**Solution**: Ensure requirement IDs follow REQ-XXX format

---

## Conclusion

The Ralph Loop Framework transforms Claude Code into a specification-driven development system that ensures requirements are met through continuous testing and feedback.

**Key Takeaways:**

1. Write specifications first
2. Let the loop guide implementation
3. Test continuously
4. Harvest feedback
5. Iterate until proven

**Next Steps:**

1. Create your first specification from a template
2. Run `/ralph-loop` on it
3. Watch Claude implement with continuous testing
4. Review the proof report
5. Iterate based on feedback

Happy looping! 🔄
