# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Ralph Loop Framework v2

This repository implements the **Ralph Loop Framework v2** - an enhanced Claude-focused iterative development system with:
- **Parallel subagent execution** (max 3 concurrent)
- **Git branch management** (feature branches with safe merging)
- **State persistence** (between iterations and phases)
- **Comprehensive testing** (lint, unit, UI, code quality)
- **Story-based development** (with dependency management)
- **Automatic archival** (complete run history preservation)

### Core Concept

The Ralph Loop is a continuous feedback cycle with state management:
1. **Requirement Intake** - Parse PRD/OpenSpec, analyze dependencies
2. **Architecture** - Design implementation approach with test strategy
3. **Loop Execution** - Parallel implementation (max 3) with dependency resolution
4. **Prove/Verify** - Comprehensive testing against specifications
5. **Harvest Feedback** - Collect results, iterate if needed
6. **Archive & Merge** - Archive artifacts, merge to origin branch

### Key Features

**Parallel Execution**
- Max 3 concurrent subagent tasks
- Dependency-aware scheduling (only run stories with satisfied deps)
- Code conflict detection (stories touching same files run sequentially)
- Each story = 1 Claude Task

**State Management**
- All state in `ralph/.ralph/` directory (not tracked in git)
- State persists between iterations
- Full audit trail of decisions and changes
- Resume capability if interrupted

**Git Integration**
- Each run creates feature branch: `ralph/<spec-name>-<timestamp>`
- Branched from main/master/development (user's choice)
- Each story gets single commit
- Regular merge (not squash) - preserves all commits
- Safe: never works directly on main branches

**Testing Strategy**
- **Lint/Format**: Auto-fix, max 3 iterations
- **Unit Tests**: Logic validation, max 5 iterations
- **Code Quality**: Complexity, duplication checks
- **UI Tests**: Playwright (if applicable), max 5 iterations
- **Integration Tests**: Full system validation
- Iteration not complete until ALL tests pass

**Spec Modification** ⭐ NEW
- Modify specs during run without losing progress
- Add requirements when gaps discovered
- Clarify criteria when ambiguous
- Reprioritize based on learnings
- Update dependencies when found
- Revert completed stories if needed
- All versions archived with history
- Seamless resumption after changes

**Archival System**
- Complete run archived to `ralph/archive/<spec-name>-<timestamp>/`
- Includes: spec, state, logs, test results, git history
- Workspace cleaned after archive
- Ready for next run immediately

### Installation & Setup

The Ralph Loop Framework includes an installation script for easy setup:

```bash
# Install skills globally
./install-ralph-loop.sh --install-global

# Create new project with Ralph Loop
./install-ralph-loop.sh --install-global --new-project <name> --type <language>

# Add to existing project
cd /path/to/project
./install-ralph-loop.sh --install-global --init
```

**Features:**
- Installs all 15 Ralph skills to `~/.claude/skills/`
- Auto-detects existing project type and tools
- Interactive configuration (package manager, test framework, etc.)
- Backs up existing files before modifying
- Supports TypeScript, Python, Go, Rust, Angular, React, Next.js, Express, Flask, Ruby
- Creates complete project structure with documentation

See `docs/INSTALLATION.md` for detailed installation guide.

### Available Skills

#### Primary Workflow Skills

**`/ralph-create-prd`** - Interactive PRD creation with story breakdown
- Guides through problem statement, user stories, requirements
- Auto-detects dependencies and code conflicts
- Suggests story breakdown with parallel execution plan
- Validates completeness
- Fills gaps with targeted questions
- Generates execution phases

**`/ralph-loop`** - Main orchestrator using Task subagents
- Parses specification into stories
- Creates Claude Tasks for each story
- Designs architecture
- Implements stories in parallel (max 3, dependency-aware)
- Tests each story comprehensively
- Commits each story individually
- Proves all requirements met
- Marks ready for archive

**`/ralph-archive`** - Complete run and prepare for next
- Archives all artifacts to timestamped directory
- Merges to origin branch (regular merge)
- Cleans Ralph state
- Verifies workspace ready for next run
- Preserves Ralph branch for reference

**`/ralph-status`** - Check current run status
- Display run progress
- Show story statuses
- Check iteration counts
- Identify blockers
- Show next steps

**`/ralph-resume`** - Resume paused Ralph run
- Resume after user interruption
- Resume after error fix
- Continues from exact pause point

**`/ralph-modify-spec`** - Modify specification during run ⭐ NEW
- Add new requirements (discovered gaps)
- Modify existing requirements (clarify criteria)
- Change priorities (reprioritize based on learnings)
- Update dependencies (add/remove dependencies)
- Remove requirements (scope changes)
- Handles completed stories (revert and re-implement)
- Maintains all progress
- Spec versioning tracked

**`/ralph-add-requirement`** - Quick add single requirement ⭐ NEW
- Fast way to add discovered gap
- Simplified version of ralph-modify-spec
- Single requirement addition
- Automatic dependency analysis

#### Testing Skills

**`/test-spec`** - Test specific requirement
- Validates acceptance criteria
- Runs appropriate test suite
- Captures output
- Updates task status

**`/browser-test`** - UI testing with Playwright
- Functional testing
- Visual regression
- Accessibility (WCAG 2.1)
- Performance metrics

**`/feedback-selector`** - Determine optimal testing strategy
- Analyzes project type
- Recommends test tools
- Configures thresholds
- Sets up test infrastructure

#### Parsing Skills

**`/parse-prd`** - Parse PRD documents
**`/parse-openspec`** - Parse OpenSpec documents
**`/prove-requirements`** - Comprehensive validation

### Workflow

#### Complete Workflow Example

```bash
# 1. Create PRD (interactive, with story breakdown)
/ralph-create-prd user-authentication

# Claude will:
# - Guide through problem statement
# - Collect user stories
# - Define requirements with acceptance criteria
# - Auto-detect dependencies
# - Analyze code conflicts
# - Suggest execution phases
# - Validate completeness

# 2. Start Ralph Loop (creates branch, runs in parallel)
/ralph-loop ralph/specs/prds/user-authentication.prd.md

# Claude will:
# - Create branch: ralph/user-authentication-20260223145023
# - Parse spec into 8 stories
# - Create 8 Claude Tasks
# - Design architecture
# - Phase 1: Implement REQ-001, REQ-002, REQ-003 (parallel)
# - Test each story (lint, unit, UI, quality)
# - Commit each story individually
# - Phase 2: Implement REQ-004, REQ-005 (parallel, deps satisfied)
# - Continue until all stories complete
# - Prove all requirements met
# - Status: ready_for_archive

# 3. Check status anytime
/ralph-status

# 4. Archive and merge
/ralph-archive

# Claude will:
# - Verify all tests pass
# - Archive to ralph/archive/user-authentication-20260223145023/
# - Merge to main (regular merge, preserves commits)
# - Clean ralph/.ralph/ state
# - Workspace ready for next run

# 5. Start next feature
/ralph-create-prd dashboard-widgets
/ralph-loop ralph/specs/prds/dashboard-widgets.prd.md
```

#### Quick Workflow (Existing PRD)

```bash
# If you already have a PRD
/ralph-loop ralph/specs/prds/existing-feature.prd.md

# Check progress
/ralph-status

# Complete
/ralph-archive
```

### Story Breakdown Rules

**Story Creation**
- Each REQ-XXX becomes 1 story
- Each story = 1 Claude Task
- Each story gets 1 commit when complete

**Dependencies**
- Explicit: Defined in PRD `Dependencies:` field
- Auto-detected: Code file conflicts, logical dependencies
- Both respected: Explicit takes precedence

**Parallel Execution**
- Stories with NO dependencies run in parallel
- Stories with ALL dependencies satisfied run in parallel
- Stories touching same code run sequentially (by priority)
- Max 3 stories in parallel at once

**Priority Ordering**
- High priority stories first
- Within priority: dependency order
- Code conflicts resolved by priority

**Example Execution Plan:**
```
Phase 1 (parallel, no deps):
  - REQ-001 (high, no deps, touches: auth/login.ts)
  - REQ-002 (high, no deps, touches: auth/session.ts)
  - REQ-003 (high, no deps, touches: auth/logout.ts)

Phase 2 (sequential, same file):
  - REQ-004 (medium, deps: REQ-001, touches: auth/login.ts)
  - REQ-005 (medium, deps: REQ-004, touches: auth/login.ts)

Phase 3 (parallel, deps satisfied):
  - REQ-006 (low, deps: REQ-002, touches: auth/token.ts)
  - REQ-007 (low, deps: REQ-001, touches: ui/login-form.tsx)
```

### Testing Requirements

**Every story MUST pass all applicable tests:**

1. **Lint/Format** (max 3 iterations)
   - ESLint (JavaScript/TypeScript)
   - Black (Python)
   - Clippy (Rust)
   - Auto-fix when possible

2. **Unit Tests** (max 5 iterations)
   - Test all acceptance criteria
   - One test per criterion
   - Coverage tracked

3. **Code Quality** (max 3 iterations)
   - Complexity checks
   - Duplication detection
   - Best practices validation

4. **UI Tests** (max 5 iterations, if applicable)
   - Playwright browser tests
   - Visual regression
   - Accessibility (WCAG 2.1)
   - Triggered by: keywords, file patterns, explicit flag

5. **Integration Tests** (max 5 iterations)
   - Full system validation
   - Cross-component testing

**Test Failure Handling:**
- Pause immediately on failure
- Create fix task
- Increment iteration counter
- Retry after fix
- If max iterations reached: require user intervention

**Iteration Limits:**
- Logic errors: 5 iterations max
- Lint/formatting: 3 iterations max
- After limit: pause for user

### State Files

**All state in `ralph/.ralph/` (NOT tracked in git):**

```
ralph/.ralph/
├── state.json              # Current run state
├── stories.json            # All stories with status/deps
├── architecture.json       # Architecture decisions
├── logs/
│   ├── parse.log
│   ├── architecture.log
│   ├── implement-phase1.log
│   └── tests.log
└── artifacts/
    ├── REQ-001-impl.json
    ├── REQ-001-tests.json
    ├── proof-report.json
    └── harvest-summary.md
```

**State persists:**
- Between phases
- Between iterations
- After failures (for resume)

**State cleared:**
- After successful `/ralph-archive`
- Ready for next run

### Archive Structure

**Complete run archived to `ralph/archive/<spec-name>-<timestamp>/`:**

```
ralph/archive/user-auth-20260223145023/
├── summary.md              # Human-readable summary
├── metadata.json           # Run metadata
├── spec/
│   └── user-auth.prd.md   # Original spec
├── state/
│   ├── state.json
│   ├── stories.json
│   └── architecture.json
├── logs/                   # All execution logs
├── artifacts/              # All generated artifacts
├── tests/                  # Test outputs and coverage
│   ├── coverage/
│   ├── playwright-report/
│   └── test-results/
├── feedback/               # Feedback reports
└── git-info/
    ├── branch-info.txt
    ├── commits.txt
    ├── diff-summary.txt
    └── full-diff.patch
```

### Git Branch Management

**Branch Creation:**
- Format: `ralph/<spec-name>-<timestamp>`
- Example: `ralph/user-auth-20260223145023`
- Created from: current branch (main/master/development)

**Commit Strategy:**
- One commit per story
- Commit when story tests pass
- Message includes: story ID, title, acceptance criteria, test status

**Merge Strategy:**
- Regular merge (not squash, not rebase)
- Preserves all story commits
- Each commit visible in history
- Merge commit includes: run summary, test status

**Branch Cleanup:**
- Ralph branch preserved after merge (for reference)
- Can be deleted manually if desired
- Not automatically deleted

### Pre-Merge Checks

**All must pass before merge:**
- [ ] All stories completed
- [ ] All tests passing
- [ ] No uncommitted changes
- [ ] No merge conflicts with origin
- [ ] Code quality thresholds met
- [ ] Coverage requirements met

**If any check fails:**
- Archive does not proceed
- User notified of issue
- Can fix and retry `/ralph-archive`

### UI Test Detection

**UI tests triggered when:**
1. **Keywords in spec:** "UI", "interface", "page", "component", "form", "button", "display"
2. **File patterns:** `.tsx`, `.jsx`, `.vue`, `.svelte`, `.html` with JS
3. **Explicit flag:** `UI_TESTS_REQUIRED: true` in spec metadata
4. **Capability exists:** Playwright can be installed/configured

**If UI tests needed:**
- Added to test requirements
- Playwright configured automatically
- Visual regression baselines created
- Accessibility tests included

### Error Recovery

**If Ralph run fails:**
1. State preserved in `ralph/.ralph/`
2. Error logged to `ralph/.ralph/logs/error.log`
3. Status set to "failed"
4. User can:
   - Fix issue and resume
   - Check status: `/ralph-status`
   - Abandon: `/ralph-archive --abandon`

**To abandon failed run:**
```bash
/ralph-archive --abandon
```
- Archives artifacts (marked as abandoned)
- Does NOT merge to origin
- Cleans state
- Ready for new run

### Best Practices

1. **Always use `/ralph-create-prd`** for new specs
   - Ensures proper story breakdown
   - Detects dependencies automatically
   - Validates completeness

2. **Check status regularly** with `/ralph-status`
   - Monitor progress
   - Identify blockers early
   - Track iteration counts

3. **Let parallel execution work** (max 3)
   - Don't manually intervene unless necessary
   - Trust dependency resolution
   - Stories will run when ready

4. **Review archives** for learning
   - Check `ralph/archive/*/summary.md`
   - Review test outputs
   - Learn from iterations

5. **Keep specs focused**
   - 5-10 requirements per spec
   - Larger features → multiple specs
   - Better parallelization with smaller specs

### Troubleshooting

**"Ralph run already in progress"**
- Complete current run: `/ralph-archive`
- Or abandon it: `/ralph-archive --abandon`
- Check status: `/ralph-status`

**Tests keep failing**
- Check iteration count: `/ralph-status`
- If at limit: manual intervention needed
- Review `ralph/.ralph/artifacts/*-tests.json`

**Story blocked**
- Check dependencies: `/ralph-status`
- Verify dependency stories completed
- Check for circular dependencies in spec

**Merge conflicts**
- Fix conflicts manually
- Run `/ralph-archive` again
- Or rebase Ralph branch

**Archive fails**
- Check error in `ralph/.ralph/logs/error.log`
- Fix issue
- Retry `/ralph-archive`
- State preserved until successful archive

### Integration Points

**CI/CD Integration:**
- Can run Ralph Loop in CI
- Archive artifacts to CI storage
- Merge via pull request instead of direct merge

**Issue Tracking:**
- Story IDs can link to GitHub issues
- Commits reference stories
- Traceability maintained

**Documentation:**
- Archive includes complete run history
- Generate docs from proof reports
- Test outputs show coverage

### Commands Quick Reference

```bash
# Create new PRD interactively
/ralph-create-prd <spec-name>

# Start Ralph Loop
/ralph-loop ralph/specs/prds/<spec-name>.prd.md

# Check status
/ralph-status

# Resume paused run
/ralph-resume

# Modify spec during run (if gap discovered)
/ralph-modify-spec
# Or quick add single requirement
/ralph-add-requirement "Email verification" --priority=high

# Complete and archive
/ralph-archive

# Abandon failed run
/ralph-archive --abandon

# Test specific requirement
/test-spec REQ-001

# Test all requirements
/test-spec --all

# Browser test component
/browser-test src/components/MyComponent.tsx

# Determine test strategy
/feedback-selector
```

### Examples Directory

See `examples/` for:
- `example-todo-app.prd.md` - Complete PRD example
- Working implementations
- Test suites
- Archive samples

### Documentation

- `README.md` - Framework overview
- `docs/QUICKSTART.md` - 5-minute getting started
- `docs/ralph-loop-guide.md` - Complete guide
- `docs/COMPLETE-WORKFLOW.md` - End-to-end workflow with all commands
- `docs/SPEC-MODIFICATIONS.md` - Modifying specs during run ⭐ NEW
- `ralph/archive/*/summary.md` - Per-run summaries

---

## For Future Claude Instances

When you see a Ralph run in progress (`ralph/.ralph/` exists):
1. Check status first: `/ralph-status`
2. Understand current phase and progress
3. Continue from current state
4. Do not restart unless instructed
5. Respect iteration limits
6. Wait for test passes before proceeding
7. Complete with `/ralph-archive` when ready

The Ralph Loop Framework ensures systematic, tested, traceable development with automatic archival and clean state management.
