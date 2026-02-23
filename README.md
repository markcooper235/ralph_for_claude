# Ralph Loop Framework for Claude Code

A Claude Code-focused iterative development framework for PRD/OpenSpec-style coding tasks with integrated feedback loops, testing harnesses, and intelligent task management.

## What is Ralph Loop?

The Ralph Loop Framework is a structured approach to software development that combines:
- **Specification-driven development** (PRD or OpenSpec formats)
- **Continuous feedback loops** (automated testing and validation)
- **Intelligent task management** (Claude's built-in task system)
- **Adaptive testing strategies** (project-aware feedback selection)

The name "Ralph" represents the continuous cycle: **R**equirement → **A**rchitecture → **L**oop → **P**rove → **H**arvest

## Quick Start

1. **Create a specification:**
   ```bash
   # Use the PRD template
   cp .claude/templates/prd-template.md specs/prds/my-feature.prd.md
   # Edit the PRD with your requirements

   # Or use the OpenSpec template
   cp .claude/templates/openspec-template.yaml specs/openspecs/my-api.openspec.yaml
   # Edit the OpenSpec with your contracts
   ```

2. **Start the Ralph Loop:**
   ```bash
   /ralph-loop specs/prds/my-feature.prd.md
   ```

3. **Claude will automatically:**
   - Parse your specification
   - Break it into tasks
   - Design the architecture
   - Implement with continuous testing
   - Prove all requirements are met
   - Harvest feedback for iteration

## Core Concepts

### The Loop Phases

1. **Requirement Intake**: Parse PRD or OpenSpec documents into structured requirements
2. **Architecture**: Design implementation approach based on requirements and codebase
3. **Loop Execution**: Implement features with continuous testing and feedback
4. **Prove**: Validate all requirements are met through comprehensive testing
5. **Harvest**: Collect feedback, identify gaps, and iterate

### Specification Formats

**PRD (Product Requirements Document)**
- Traditional requirement format
- User stories and acceptance criteria
- Functional and non-functional requirements
- Best for: Product features, business requirements

**OpenSpec (Declarative Specification)**
- Behavioral contracts with pre/post conditions
- Property-based specifications
- Type signatures and constraints
- Best for: APIs, libraries, technical specifications

## Available Skills

### Core Loop Skills

- **`/ralph-loop`** - Main orchestrator for the entire development cycle
- **`/test-spec`** - Test implementation against specification requirements
- **`/prove-requirements`** - Comprehensive validation of all requirements

### Parsing Skills

- **`/parse-prd`** - Parse PRD documents into structured tasks
- **`/parse-openspec`** - Parse OpenSpec documents into contracts and tests

### Testing Skills

- **`/browser-test`** - Browser-based UI testing with Playwright
- **`/feedback-selector`** - Intelligent feedback method selection

## Project Structure

```
ralph_for_claude/
├── .claude/
│   ├── skills/              # Custom Ralph Loop skills
│   │   ├── ralph-loop.md
│   │   ├── test-spec.md
│   │   ├── browser-test.md
│   │   ├── feedback-selector.md
│   │   ├── parse-prd.md
│   │   ├── parse-openspec.md
│   │   └── prove-requirements.md
│   ├── templates/           # Specification templates
│   │   ├── prd-template.md
│   │   └── openspec-template.yaml
│   └── feedback-configs/    # Auto-generated feedback configurations
├── specs/
│   ├── prds/               # Product Requirements Documents
│   └── openspecs/          # OpenSpec format specifications
├── implementations/         # Organized by specification
├── tests/                  # Tests organized by specification
├── feedback/               # Test results and feedback reports
├── examples/               # Example specs and implementations
└── docs/                   # Documentation

```

## Example Workflows

### Workflow 1: Building a Feature from PRD

```bash
# 1. Create your PRD from template
cp .claude/templates/prd-template.md specs/prds/user-authentication.prd.md
# Edit the PRD with your requirements

# 2. Parse and validate
/parse-prd specs/prds/user-authentication.prd.md

# 3. Run the complete loop
/ralph-loop specs/prds/user-authentication.prd.md

# 4. Claude will:
#    - Create tasks for each requirement
#    - Design architecture
#    - Implement with continuous testing
#    - Prove all requirements
#    - Generate feedback report
```

### Workflow 2: Building an API from OpenSpec

```bash
# 1. Create OpenSpec
cp .claude/templates/openspec-template.yaml specs/openspecs/user-api.openspec.yaml
# Define your contracts, types, and properties

# 2. Parse and generate tests
/parse-openspec specs/openspecs/user-api.openspec.yaml

# 3. Run the loop
/ralph-loop specs/openspecs/user-api.openspec.yaml

# 4. Claude will generate:
#    - Property-based tests
#    - Contract validation tests
#    - Example-based tests
#    - Complete implementation
```

### Workflow 3: Testing Existing Code

```bash
# 1. Let Claude determine best feedback method
/feedback-selector

# 2. Test specific requirement
/test-spec REQ-001

# 3. Test all requirements
/test-spec --all

# 4. For UI components, use browser testing
/browser-test src/components/LoginForm.tsx --visual-regression --a11y

# 5. Comprehensive proof of all requirements
/prove-requirements specs/prds/user-authentication.prd.md
```

## Task Management Integration

The framework leverages Claude's task management system:

```bash
# View all tasks
Use TaskList tool in Claude Code

# Tasks are automatically:
# - Created from requirements
# - Updated with test results
# - Linked with dependencies
# - Tracked through completion
```

Each task includes:
- Clear acceptance criteria
- Links to requirements
- Test coverage status
- Implementation progress

## Testing Strategies

### Unit Testing
- Generated from functional requirements
- Test IDs match requirement IDs
- Supports: Python (pytest), JavaScript (Jest/Vitest), Go, Rust

### Browser Testing
- Playwright-based automation
- Visual regression testing
- Accessibility (WCAG 2.1) validation
- Performance metrics (Lighthouse)

### Contract Testing
- API endpoint validation
- Request/response contracts
- Integration testing

### Property-Based Testing
- From OpenSpec properties
- Uses Hypothesis (Python), fast-check (JS)
- Validates invariants

## Feedback Loop Mechanisms

The framework adapts testing to your project type:

| Project Type | Primary Feedback Method | Secondary Methods |
|--------------|------------------------|-------------------|
| Web Frontend | Browser Testing | Visual Regression, A11y |
| Web Backend | Integration Tests | Unit Tests, Load Tests |
| API/Service | Contract Tests | Integration, Performance |
| Library/SDK | Unit Tests | Type Checking, Examples |
| CLI Tool | Command Tests | Output Validation |
| Mobile App | E2E Tests | Visual Regression |

## Advanced Usage

### Resume from Checkpoint

```bash
/ralph-loop --resume=user-auth-checkpoint-3
```

### Run Specific Phase

```bash
/ralph-loop specs/prds/feature.prd.md --phase=architecture
/ralph-loop specs/prds/feature.prd.md --phase=implement
/ralph-loop specs/prds/feature.prd.md --phase=prove
```

### Interactive Browser Testing

```bash
/browser-test src/components/Dashboard.tsx --interactive
```

### Custom Feedback Configuration

```bash
/feedback-selector --setup
# Generates: .claude/feedback-configs/feedback-config.json
# Customize thresholds, tools, and methods
```

## Best Practices

1. **Write specs first** - Always start with PRD or OpenSpec before coding
2. **Small, testable requirements** - Each requirement should map to 1-3 tasks
3. **Continuous testing** - Run `/test-spec` after each implementation
4. **Use appropriate feedback** - Let `/feedback-selector` choose the right tools
5. **Iterate on failures** - Feedback creates new tasks automatically
6. **Track progress** - Use task management to see overall status

## Examples

See the `examples/` directory for:
- Complete PRD with implementation
- OpenSpec with generated tests
- Multi-phase loop execution
- Feedback integration patterns

## Extending the Framework

### Adding Custom Skills

Create new skill files in `.claude/skills/`:

```markdown
# My Custom Skill

## Usage
/my-skill [args]

## Instructions
[Step-by-step instructions for Claude]
```

### Creating Custom Templates

Add templates to `.claude/templates/`:
- Custom specification formats
- Project-specific requirements
- Test templates

### Custom Feedback Methods

Edit `.claude/feedback-configs/feedback-config.json`:
- Add new testing tools
- Customize thresholds
- Define project-specific strategies

## Troubleshooting

**Loop gets stuck?**
```bash
/ralph-loop status
```

**Need to reset?**
```bash
/ralph-loop reset
```

**Check feedback history:**
```bash
ls feedback/<spec-id>/
```

## Philosophy

The Ralph Loop Framework is built on these principles:

1. **Specification-Driven**: Clear requirements lead to clear implementations
2. **Continuous Feedback**: Test early, test often, test automatically
3. **Intelligent Adaptation**: Testing strategies adapt to project context
4. **Task-Centric**: Break complex problems into manageable tasks
5. **Iterative Refinement**: Each loop improves based on feedback

## Requirements

The framework works with any Claude Code installation. Individual skills may require:
- **Browser testing**: Playwright (`npm install -D @playwright/test`)
- **Property testing**: Hypothesis (Python) or fast-check (JavaScript)
- **Visual regression**: Percy or BackstopJS
- **Accessibility**: axe-core

The framework will detect missing dependencies and offer to install them.

## Contributing

To contribute to the framework:
1. Add skills to `.claude/skills/`
2. Create templates in `.claude/templates/`
3. Share example specifications in `examples/`
4. Improve feedback configurations

## License

This framework is designed for use with Claude Code and can be freely adapted to your needs.

---

## Getting Help

- Read `CLAUDE.md` for Claude-specific instructions
- Check `docs/` for detailed documentation
- Review `examples/` for working examples
- Use `/help` in Claude Code for general help

---

**Start your first Ralph Loop:**

```bash
/ralph-loop
```

Claude will guide you through creating your first specification and running the complete development cycle.
