# Ralph Loop Framework - Quick Start Guide

Get started with the Ralph Loop Framework in 5 minutes.

## Prerequisites

- Claude Code CLI installed
- Basic understanding of software specifications
- A project idea in mind

## 1. Create Your First Specification

Choose a format based on what you're building:

### For Product Features (PRD)

```bash
# Copy the PRD template
cp .claude/templates/prd-template.md ralph/specs/prds/my-feature.prd.md

# Edit the file with your requirements
# Focus on these sections:
# - Problem Statement: What are you solving?
# - User Stories: Who benefits and how?
# - Functional Requirements: What should it do?
# - Acceptance Criteria: How do you know it works?
```

**Example Requirements:**
```markdown
## Functional Requirements

### REQ-001: User Login (Priority: High)
**Description:** Users can log in with email and password.

**Acceptance Criteria:**
- [ ] User enters email and password
- [ ] System validates credentials
- [ ] On success, user is redirected to dashboard
- [ ] On failure, error message is displayed
```

### For APIs or Libraries (OpenSpec)

```bash
# Copy the OpenSpec template
cp .claude/templates/openspec-template.yaml ralph/specs/openspecs/my-api.openspec.yaml

# Edit the file with your contracts
# Focus on these sections:
# - types: Data structures
# - contracts: Function behaviors with pre/post conditions
# - properties: Invariants that always hold
# - examples: Concrete test cases
```

**Example Contract:**
```yaml
contracts:
  login:
    signature: (email: string, password: string) -> Result<Session, Error>
    require:
      - email is valid format
      - password length >= 8
    ensure:
      - if success, session is created
      - if failure, error code is set
    examples:
      - input: { email: "user@example.com", password: "pass123" }
        output: { success: true }
```

## 2. Run the Ralph Loop

Start the development cycle:

```bash
/ralph-loop ralph/specs/prds/my-feature.prd.md
```

### What Happens Next

Claude will automatically:

1. **Parse** your specification
   - Extract requirements (REQ-001, REQ-002, etc.)
   - Create tasks with dependencies
   - Generate test checklist

2. **Design** the architecture
   - Analyze existing code (if any)
   - Choose appropriate patterns
   - Ask clarifying questions if needed

3. **Implement** with continuous testing
   - For each task:
     - Write implementation code
     - Write tests
     - Run tests
     - Mark complete when passing
   - Continue until all tasks done

4. **Prove** all requirements
   - Run comprehensive test suite
   - Validate each acceptance criterion
   - Generate proof report

5. **Harvest** feedback
   - Collect test results
   - Identify gaps
   - Create tasks for next iteration if needed

## 3. Monitor Progress

While the loop runs, you can check status:

```bash
# View current status, story progress, quota usage
/ralph-status

# Test specific requirement
/test-spec REQ-001

# Test everything
/test-spec --all
```

## 4. Review Results

After the loop completes, review:

### Proof Report
Located at: `ralph/feedback/<spec-name>/proof-report.md`

Contains:
- ✓ Fully implemented requirements
- ⚠ Partially implemented requirements
- ✗ Missing requirements
- Test coverage metrics
- Recommendations

### Implementation
Your code will be organized logically with:
- Clear requirement IDs in comments
- Comprehensive tests
- Documentation

## Common Workflows

### Workflow 1: Quick Feature (5-10 minutes)

```bash
# 1. Create minimal PRD
cat > ralph/specs/prds/quick-feature.prd.md << EOF
# Quick Feature

## Functional Requirements

### REQ-001: Add Greeting Function
**Description:** Function that greets user by name.

**Acceptance Criteria:**
- [ ] Function accepts name parameter
- [ ] Function returns "Hello, {name}!"
- [ ] Function handles empty string
EOF

# 2. Run the loop
/ralph-loop ralph/specs/prds/quick-feature.prd.md

# 3. Done! Check implementations/ directory
```

### Workflow 2: Full Feature (1+ hour)

```bash
# 1. Start with template
cp .claude/templates/prd-template.md ralph/specs/prds/user-auth.prd.md

# 2. Write detailed requirements (8-10 requirements)
# Include:
# - User stories
# - Functional requirements with acceptance criteria
# - Non-functional requirements (performance, security)
# - Success metrics

# 3. Let Claude determine best approach
/feedback-selector

# 4. Run the loop
/ralph-loop ralph/specs/prds/user-auth.prd.md

# 5. For UI features, also run browser tests
/browser-test src/components/LoginForm.tsx --a11y

# 6. Prove everything works
/prove-requirements ralph/specs/prds/user-auth.prd.md
```

### Workflow 3: API Development

```bash
# 1. Start with OpenSpec
cp .claude/templates/openspec-template.yaml ralph/specs/openspecs/user-api.openspec.yaml

# 2. Define contracts with:
# - Type definitions
# - Pre/post conditions
# - Properties (invariants)
# - Examples

# 3. Parse and generate tests
/parse-openspec ralph/specs/openspecs/user-api.openspec.yaml

# 4. Run the loop (tests already generated!)
/ralph-loop ralph/specs/openspecs/user-api.openspec.yaml

# 5. Tests include:
# - Property-based tests
# - Contract validation
# - Example-based tests
```

## Tips for Success

### 1. Start Simple
- Begin with 2-3 requirements
- Get comfortable with the flow
- Add more complexity gradually

### 2. Be Specific
- Vague requirement: "Make it fast"
- Specific requirement: "API response time < 200ms for 95th percentile"

### 3. Make It Testable
Every acceptance criterion should answer: "How do I know this works?"

Good:
- ✓ "Function returns array of length 3"
- ✓ "Button click triggers API call"
- ✓ "Error message is displayed"

Bad:
- ✗ "Function works correctly"
- ✗ "UI is intuitive"
- ✗ "Code is clean"

### 4. Use Examples
Include concrete examples in your spec:
```markdown
Example: login("user@example.com", "pass123")
Expected: { success: true, sessionId: "abc..." }

Example: login("invalid", "")
Expected: { success: false, error: "INVALID_CREDENTIALS" }
```

### 5. Iterate
The first loop might not be perfect. That's OK!
- Review the proof report
- Refine requirements
- Run another loop

## Next Steps

### Learn More
- Read the complete guide: `docs/ralph-loop-guide.md`
- Study the example: `examples/example-todo-app.prd.md`
- Understand specifications: See `.claude/templates/`

### Try Advanced Features

**Resume after quota pause or interruption:**
```bash
/ralph-resume
```

**Check status and quota usage:**
```bash
/ralph-status
```

**Modify spec mid-run (discovered a gap?):**
```bash
/ralph-modify-spec
# Or quick add:
/ralph-add-requirement "Email verification" --priority=high
```

**Interactive browser testing:**
```bash
/browser-test --interactive
```

**Custom feedback config:**
```bash
/feedback-selector --setup
# Edit .claude/feedback-configs/feedback-config.json
```

### Extend the Framework

**Add custom skills (subdirectory format):**
```bash
# Create skill subdirectory
mkdir -p .claude/skills/my-skill
# Create SKILL.md with YAML frontmatter and "When this skill is invoked:"
vim .claude/skills/my-skill/SKILL.md

# Use it
/my-skill
```

**Create project templates:**
```bash
# Add to templates directory
vim .claude/templates/my-project-template.md
```

## Troubleshooting

**Q: Loop gets stuck or paused?**
```bash
/ralph-status
/ralph-resume
```

**Q: Tests keep failing?**
- Check acceptance criteria are correct
- Verify test environment setup
- Run `/test-spec REQ-XXX --verbose` for details

**Q: Wrong tests generated?**
- Review specification clarity
- Check that requirements are testable
- Use `/feedback-selector` to verify correct strategy

**Q: Task dependencies wrong?**
- Explicitly state dependencies in spec
- Use TaskUpdate to fix blockedBy relationships

## Getting Help

- Read `CLAUDE.md` for Claude-specific instructions
- Check `docs/ralph-loop-guide.md` for detailed documentation
- Review `examples/` for working examples
- Use `/help` in Claude Code

## Quick Reference

```bash
# Main workflow
/ralph-create-prd <name>             # Create PRD interactively
/ralph-loop <spec-file>              # Run complete loop
/ralph-status                        # Check progress and quota
/ralph-resume                        # Resume paused run
/ralph-modify-spec                   # Modify spec mid-run
/ralph-add-requirement "..."         # Quick add requirement
/ralph-archive                       # Complete, merge, and archive
/ralph-archive --abandon             # Abandon failed run

# Testing
/test-spec <REQ-ID>                  # Test one requirement
/test-spec --all                     # Test everything
/prove-requirements <spec-file>      # Comprehensive validation
/browser-test <component>            # UI testing

# Parsing
/parse-prd <file>                    # Parse PRD
/parse-openspec <file>               # Parse OpenSpec

# Utilities
/feedback-selector                   # Determine test strategy
/ralph-quota                         # Check quota usage
```

## Example: Complete Flow

```bash
# 1. Create spec (2 minutes)
cp .claude/templates/prd-template.md ralph/specs/prds/calculator.prd.md
# Edit: Add REQ-001 (add), REQ-002 (subtract), REQ-003 (multiply), REQ-004 (divide)

# 2. Run loop (5 minutes)
/ralph-loop ralph/specs/prds/calculator.prd.md

# Claude creates 4 tasks, implements calculator, writes tests, runs tests

# 3. Review (1 minute)
# Check ralph/feedback/calculator/proof-report.md
# All requirements ✓ proven!

# Total time: 8 minutes
# Result: Fully tested calculator with comprehensive test suite
```

---

Ready to start? Create your first spec and run `/ralph-loop`! 🚀
