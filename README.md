# Ralph Loop Framework for Claude Code

A Claude Code-focused iterative development framework for PRD/OpenSpec-style coding tasks with integrated feedback loops, parallel subagent execution, git branch management, and intelligent quota management.

## What is Ralph Loop?

The Ralph Loop Framework is a structured approach to software development that combines:
- **Specification-driven development** (PRD or OpenSpec formats)
- **Parallel subagent execution** (max 3 concurrent, dependency-aware)
- **Continuous feedback loops** (automated testing and validation)
- **Git branch management** (feature branches with safe merging)
- **Quota management** (graceful pause/resume before exhaustion)
- **Complete archival** (timestamped run history with full audit trail)

The name "Ralph" represents the continuous cycle: **R**equirement → **A**rchitecture → **L**oop → **P**rove → **H**arvest

## Installation

### Quick Install

Install Ralph Loop Framework globally and add to a new or existing project:

```bash
# Clone or download the framework
git clone <framework-repo-url>
cd ralph_for_claude

# Install globally + create new project
./install-ralph-loop.sh --install-global --new-project my-app --type typescript

# OR: Install globally + add to existing project
cd /path/to/existing/project
/path/to/ralph_for_claude/install-ralph-loop.sh --install-global --init

# OR: Install skills globally only
./install-ralph-loop.sh --install-global
```

### Supported Project Types

18 project type/sub-type combinations are supported:

| Type flag | What's created |
|---|---|
| `typescript` | TypeScript + Jest + ESLint |
| `javascript` | Plain JavaScript + Jest + ESLint (no TypeScript) |
| `express` | Express.js API + Supertest + ESLint |
| `react` | React + Vite + Vitest (via create-vite) |
| `nextjs` | Next.js App Router + TypeScript (via create-next-app) |
| `angular` | Angular 19 workspace (via @angular/cli) |
| `python` | Python basic/flask/reflex (prompted) |
| `flask` | Flask + pytest + venv (shortcut) |
| `reflex` | Python Reflex + pytest + venv (shortcut) |
| `go` | Go module + standard testing |
| `ruby` | Ruby basic/rails (prompted) |
| `rails` | Ruby on Rails + SQLite3 (shortcut) |
| `rust` | Rust basic/actix/rocket (prompted) |
| `actix` | Rust Actix Web server (shortcut) |
| `rocket` | Rust Rocket server (shortcut) |
| `dotnet` | .NET (webapi/mvc/blazorwasm/blazor sub-choice) |
| `nx` | Nx monorepo workspace |

**Sub-type groupings:** When using the parent type (`python`, `ruby`, `rust`), the installer asks which framework:
- `--type python` → asks: basic / flask / reflex
- `--type ruby` → asks: basic / rails
- `--type rust` → asks: basic / actix / rocket

Shortcuts like `--type flask`, `--type rails`, `--type actix` skip the sub-type question.

See `docs/INSTALLATION.md` for detailed installation guide including:
- Auto-detection of existing projects
- Interactive configuration per project type
- Sub-type selection
- Backup system and troubleshooting

## Quick Start

1. **Create a specification:**
   ```bash
   # Interactive PRD creation (recommended)
   /ralph-create-prd my-feature

   # Or use templates manually
   cp .claude/templates/prd-template.md ralph/specs/prds/my-feature.prd.md
   # Edit the PRD with your requirements
   ```

2. **Start the Ralph Loop:**
   ```bash
   /ralph-loop ralph/specs/prds/my-feature.prd.md
   ```

3. **Claude will automatically:**
   - Parse your specification into stories
   - Design the architecture
   - Implement with parallel subagents (max 3)
   - Test each story (lint, unit, UI, code quality)
   - Commit each story individually
   - Prove all requirements are met
   - Archive for the next iteration

4. **Archive and merge:**
   ```bash
   /ralph-archive
   ```

## Core Concepts

### The Loop Phases

1. **Requirement Intake**: Parse PRD or OpenSpec documents into structured stories with dependencies
2. **Architecture**: Design implementation approach based on requirements and codebase
3. **Loop Execution**: Implement stories in parallel (max 3, dependency-aware) with continuous testing
4. **Prove**: Validate all requirements are met through comprehensive testing
5. **Harvest**: Collect feedback, generate summary, archive artifacts

### Specification Formats

**PRD (Product Requirements Document)**
- Traditional requirement format with user stories and acceptance criteria
- Each `REQ-XXX` becomes one story → one Claude Task → one git commit
- Best for: Product features, business requirements

**OpenSpec (Declarative Specification)**
- Behavioral contracts with pre/post conditions
- Property-based specifications with type signatures and constraints
- Best for: APIs, libraries, technical specifications

### Git Integration

- Each run creates branch: `ralph/<spec-name>-<timestamp>`
- Each story gets its own commit when all tests pass
- Archive merges to origin branch with regular merge (preserves all commits)
- Ralph branch preserved for audit trail

### Quota Management

Ralph monitors context quota usage throughout a run:
- **Warning** (75%): User notified
- **Safety** (85%): Pauses gracefully BEFORE starting next task
- **Resume**: `/ralph-resume` continues from exact pause point — nothing is lost

## Available Skills

### Core Loop Skills

- **`/ralph-create-prd`** - Interactive PRD creation with story breakdown, dependency detection, execution planning
- **`/ralph-loop`** - Main orchestrator: parallel implementation (max 3), story commits, prove, harvest
- **`/ralph-archive`** - Validate, archive artifacts, merge to origin branch, clean state
- **`/ralph-status`** - Progress monitoring with story statuses and quota usage
- **`/ralph-resume`** - Resume after quota pause or interruption

### Spec Modification Skills

- **`/ralph-modify-spec`** - Modify specification during run (add/change/remove requirements)
- **`/ralph-add-requirement`** - Quick add single requirement discovered mid-run

### Testing Skills

- **`/test-spec`** - Test specific requirement against acceptance criteria
- **`/prove-requirements`** - Comprehensive validation of all requirements
- **`/browser-test`** - Browser-based UI testing with Playwright
- **`/feedback-selector`** - Intelligent feedback method selection

### Parsing Skills

- **`/parse-prd`** - Parse PRD documents into structured tasks
- **`/parse-openspec`** - Parse OpenSpec documents into contracts and tests

## Project Structure

After running the installer, your project will have:

```
project/
├── .claude/
│   ├── skills/                     # Custom Ralph skills (subdirectory format)
│   └── templates/
│       ├── prd-template.md
│       └── openspec-template.yaml
├── ralph/
│   ├── .ralph/                     # Runtime state (not tracked in git)
│   ├── archive/                    # Completed run archives
│   ├── specs/
│   │   ├── prds/                   # PRD files
│   │   └── openspecs/              # OpenSpec files
│   ├── docs/                       # Ralph documentation
│   ├── tests/browser/              # Playwright tests
│   ├── feedback/                   # Test results
│   ├── .ralph-quota-config.json    # Quota config template
│   ├── .ralph-state-template.json  # State template
│   └── .ralph-story-template.json  # Story template
├── CLAUDE.md                       # Claude guidance
└── README.md                       # Project readme
```

### Global Skills (~/.claude/)

Skills are installed as subdirectories; commands as flat files:

```
~/.claude/skills/
├── ralph-loop/SKILL.md
├── ralph-create-prd/SKILL.md
├── test-spec/SKILL.md
├── browser-test/SKILL.md
├── feedback-selector/SKILL.md
├── parse-prd/SKILL.md
├── parse-openspec/SKILL.md
└── prove-requirements/SKILL.md

~/.claude/commands/
├── ralph-archive.md
├── ralph-status.md
├── ralph-resume.md
├── ralph-modify-spec.md
├── ralph-add-requirement.md
├── ralph-loop-v2.md
└── ralph-quota.md
```

## Example Workflows

### Workflow 1: New Project from Scratch

```bash
# 1. Create project with Ralph Loop pre-configured
./install-ralph-loop.sh --install-global --new-project my-api --type express

# 2. Create a spec
cd my-api
/ralph-create-prd user-endpoints

# 3. Run the loop
/ralph-loop ralph/specs/prds/user-endpoints.prd.md

# 4. Archive and merge when complete
/ralph-archive
```

### Workflow 2: Building a Feature from PRD

```bash
# 1. Create your PRD (interactive)
/ralph-create-prd user-authentication

# 2. Run the complete loop
/ralph-loop ralph/specs/prds/user-authentication.prd.md

# 3. Check progress anytime
/ralph-status

# 4. If quota paused, resume later
/ralph-resume

# 5. Archive when ready
/ralph-archive
```

### Workflow 3: Building an API from OpenSpec

```bash
# 1. Create OpenSpec
cp .claude/templates/openspec-template.yaml ralph/specs/openspecs/user-api.openspec.yaml
# Define contracts, types, and properties

# 2. Run the loop
/ralph-loop ralph/specs/openspecs/user-api.openspec.yaml
```

### Workflow 4: Adding to an Existing Project

```bash
cd /path/to/my-existing-app

# Auto-detect project type and tools
./install-ralph-loop.sh --install-global --init

# Create PRD
/ralph-create-prd new-feature

# Run loop
/ralph-loop ralph/specs/prds/new-feature.prd.md
```

## Task Management Integration

The framework uses Claude's built-in task system:

- Each `REQ-XXX` from your spec becomes one Claude Task
- Tasks are created, updated, and completed automatically
- Dependencies are tracked and respected (no story starts before its deps complete)
- Max 3 stories run in parallel at any time

**Story execution planning:**
```
Phase 1 (parallel, no deps):
  - REQ-001 (high, touches: auth/login.ts)
  - REQ-002 (high, touches: auth/session.ts)

Phase 2 (sequential, same file):
  - REQ-003 (medium, deps: REQ-001, touches: auth/login.ts)

Phase 3 (parallel, deps satisfied):
  - REQ-004 (low, deps: REQ-002)
  - REQ-005 (low, deps: REQ-001)
```

## Testing Strategies

### Per Story (Every story must pass all applicable tests):

1. **Lint/Format** (max 3 iterations) — ESLint, Black, Clippy; auto-fix when possible
2. **Unit Tests** (max 5 iterations) — one test per acceptance criterion
3. **Code Quality** (max 3 iterations) — complexity, duplication checks
4. **UI Tests** (max 5 iterations, if applicable) — Playwright, visual regression, accessibility
5. **Integration Tests** (max 5 iterations) — cross-component validation

### Browser Testing Defaults (Smart per type):

| Framework | Browser testing default |
|---|---|
| angular, react, nextjs | yes (UI frameworks) |
| ruby/rails, python/reflex | yes (full-stack UI) |
| dotnet mvc, dotnet blazor, dotnet blazorwasm | yes (UI templates) |
| typescript, javascript, express | no (backend/utility) |
| go, python/basic, python/flask | no (API/CLI) |
| rust/basic, rust/actix, rust/rocket | no (API frameworks) |
| dotnet webapi | no (REST API) |

### Testing by Project Type:

| Project Type | Primary Feedback Method | Secondary Methods |
|---|---|---|
| Web Frontend | Browser Testing | Visual Regression, A11y |
| Web Backend | Integration Tests | Unit Tests, Load Tests |
| API/Service | Contract Tests | Integration, Performance |
| Library/SDK | Unit Tests | Type Checking, Examples |
| CLI Tool | Command Tests | Output Validation |

## Best Practices

1. **Always use `/ralph-create-prd`** for new specs — ensures proper story breakdown, detects dependencies
2. **5-10 requirements per spec** — larger features → multiple specs for better parallelization
3. **Check status regularly** with `/ralph-status` — monitor progress, track quota usage
4. **Review archives** in `ralph/archive/*/summary.md` — learn from each run
5. **Write testable acceptance criteria** — "response time < 200ms" beats "must be fast"
6. **Let parallel execution work** — trust dependency resolution, don't intervene unless necessary

## Troubleshooting

**Loop gets stuck or paused?**
```bash
/ralph-status
/ralph-resume
```

**Need to abandon a failed run?**
```bash
/ralph-archive --abandon
# Archives artifacts (marked abandoned), does NOT merge
```

**Want to add a requirement mid-run?**
```bash
/ralph-add-requirement "Email verification" --priority=high
# Or full spec edit:
/ralph-modify-spec
```

**Check feedback history:**
```bash
ls ralph/feedback/
cat ralph/archive/<run-id>/summary.md
```

## Requirements

The framework works with any Claude Code installation. Individual skills may require:
- **Browser testing**: Playwright (`npm install -D @playwright/test`)
- **Property testing**: Hypothesis (Python) or fast-check (JavaScript)
- **Visual regression**: Percy or BackstopJS
- **Accessibility**: axe-core

The framework detects missing dependencies and offers to install them.

## Philosophy

The Ralph Loop Framework is built on these principles:

1. **Specification-Driven**: Clear requirements lead to clear implementations
2. **Parallel by Default**: Max throughput with dependency-aware scheduling
3. **Never Lose Work**: Quota-aware execution with graceful pause/resume
4. **Traceable**: Every story = one commit, every run = one archive
5. **Iterative Refinement**: Each loop improves based on feedback

## Documentation

- `docs/QUICKSTART.md` - 5-minute getting started
- `docs/INSTALLATION.md` - Detailed installation guide with all project types
- `docs/COMPLETE-WORKFLOW.md` - End-to-end workflow with full command output examples
- `docs/QUOTA-MANAGEMENT.md` - Quota management guide
- `docs/SPEC-MODIFICATIONS.md` - Modifying specs during a run
- `ralph/archive/*/summary.md` - Per-run summaries (after running)

---

**Start your first Ralph Loop:**

```bash
# Install globally
./install-ralph-loop.sh --install-global

# Create a new project
./install-ralph-loop.sh --install-global --new-project my-app --type typescript

# Start the loop
cd my-app
/ralph-create-prd
/ralph-loop ralph/specs/prds/<spec>.prd.md
```
