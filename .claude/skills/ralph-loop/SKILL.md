---
name: ralph-loop
description: Execute the complete Ralph Loop development cycle - Requirement, Architecture, Loop, Prove, Harvest. Use when starting a new Ralph Loop run from a PRD or OpenSpec specification file.
argument-hint: <spec-file> [--phase=<phase>] [--resume=<checkpoint>]
disable-model-invocation: true
---

# Ralph Loop - Main Orchestration Skill

Execute the complete Ralph Loop development cycle: Requirement → Architecture → Loop → Prove → Harvest.

## Usage

```
/ralph-loop [spec-file] [--phase=<phase>] [--resume=<checkpoint>]
```

## NX Workspace Detection

Before starting any phase, check if this is an NX monorepo:
- Check for `.ralph/nx-workspace.json` (written by installer)
- Or check for `nx.json` in the project root

If NX workspace detected, read `.ralph/nx-workspace.json` to get:
- `frontends` — frontend project names (e.g., `react-app`)
- `backends` — backend project names (e.g., `nest-api`)
- `unit_test` — default runner (jest/vitest)

**NX command substitutions:**
| Standard command | NX equivalent |
|---|---|
| `npm test` | `nx run <project>:test` |
| `npm run build` | `nx run <project>:build` |
| `npm run lint` | `nx run <project>:lint` |
| Run all tests | `nx run-many -t test` |
| Run affected only | `nx affected -t test --base=main` |

## Instructions

When this skill is invoked:

1. **Parse the Specification**
   - If spec-file is provided, read and parse it (PRD or OpenSpec format)
   - If no file provided, ask user for specification location or details
   - Identify all requirements (REQ-XXX format or similar)
   - Extract acceptance criteria and success metrics

2. **Create Task Breakdown**
   - Use TaskCreate to break down each requirement into actionable tasks
   - Set task dependencies based on requirement relationships
   - Prioritize tasks (infrastructure first, then features, then polish)
   - Each task should map to specific requirements

3. **Architecture Phase** (--phase=architecture or first run)
   - Analyze existing codebase structure (if any)
   - Design implementation approach for all requirements
   - Identify technical dependencies and tools needed
   - Create architecture decision records
   - Use AskUserQuestion to confirm approach if multiple options exist

4. **Implementation Loop Phase** (--phase=implement)
   - For each pending task (use TaskList):
     - Update task status to 'in_progress' (TaskUpdate)
     - Implement the requirement
     - Write corresponding tests
     - Run `/test-spec` for the specific requirement
       - **NX workspace:** `/test-spec` will automatically scope to the correct NX project(s) listed in the requirement's `nx_projects` metadata
     - Update task status to 'completed' if tests pass
     - If tests fail, create new tasks for fixes
   - Continue until all tasks are completed or blocked

5. **Prove Phase** (--phase=prove)
   - Run `/test-spec --all` to validate all requirements
   - Execute appropriate test harness based on project type:
     - UI: `/browser-test`
     - API: Integration test suite
     - Library: Unit test suite with coverage
   - **NX workspace:** use `nx run-many -t test,lint` to validate all projects,
     or `nx affected -t test --base=main` to test only changed projects
   - Generate test report in feedback/ directory
   - Identify any failing requirements

6. **Harvest Phase** (--phase=harvest)
   - Collect all feedback from test runs
   - Analyze failure patterns
   - Create tasks for any unmet requirements
   - Generate summary report
   - Ask user if another loop iteration is needed

7. **Checkpoint Management**
   - Save checkpoint after each phase completion
   - Checkpoints stored in `.claude/checkpoints/<spec-id>/`
   - Include: current phase, task states, test results
   - Allow resume with `--resume=<checkpoint>`

## Loop Iteration

If any requirements are not met after Harvest:
- Create new tasks based on feedback
- Return to Implementation Loop phase
- Continue until all requirements pass

## Output Format

Provide clear progress updates:
```
[Ralph Loop] Phase: Architecture
[Ralph Loop] Analyzing specification: feature-x.prd.md
[Ralph Loop] Created 8 tasks from 3 requirements
[Ralph Loop] Architecture design complete
[Ralph Loop] Moving to Implementation phase...
```

## Integration with Tasks

- Always use TaskCreate for requirement breakdown
- Use TaskUpdate to track progress
- Use TaskList to find next work
- Tasks should have clear acceptance criteria in description

## Examples

### Full loop from PRD
```
/ralph-loop specs/prds/user-auth.prd.md
```

### Resume from checkpoint
```
/ralph-loop --resume=user-auth-checkpoint-3
```

### Run specific phase only
```
/ralph-loop specs/prds/user-auth.prd.md --phase=prove
```
