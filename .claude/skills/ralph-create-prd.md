# Ralph Create PRD - Interactive PRD Creation Helper

Guide users through creating a complete, well-structured PRD for Ralph Loop execution.

## Usage

```
/ralph-create-prd [spec-name]
```

## Instructions

When this skill is invoked:

### 1. Initialize PRD Creation

**Get Basic Information:**
- If spec-name not provided, ask for it
- Ask: "What problem does this solve?" (Problem Statement)
- Ask: "Who are the target users?" (Target Users)
- Ask: "What's the expected timeline?" (Planning purposes)

**Create PRD file:**
```
specs/prds/<spec-name>.prd.md
```

### 2. Problem Statement Section

Guide user with questions:
- "What is the background/context?"
- "What specific problem are you solving?"
- "What is the impact of not solving this?"

Write to PRD file.

### 3. User Stories Collection

**For each user story:**
- Ask: "Describe a user story (or 'done' to finish)"
- Format as: "As a [user], I want to [action], so that [benefit]"
- Assign ID: US-001, US-002, etc.
- Ask: "Priority? (high/medium/low)"

**Suggest stories** based on problem statement if user needs help.

Continue until user says "done" or has 3-10 stories.

### 4. Functional Requirements

**For each requirement:**
- Ask: "What is the functional requirement? (or 'done')"
- Assign ID: REQ-001, REQ-002, etc.
- Ask: "Priority? (high/medium/low)"
- Ask: "Related user stories? (US-XXX, US-YYY)"
- Ask: "Dependencies on other requirements? (REQ-XXX, REQ-YYY or 'none')"

**For each requirement, create acceptance criteria:**
- Ask: "What are the acceptance criteria? (testable conditions)"
- Suggest criteria based on requirement description
- Format as checklist:
  ```
  - [ ] Criterion 1
  - [ ] Criterion 2
  ```

**Analyze code impact:**
- If existing codebase, ask: "Which files/modules will this touch?"
- Use Glob/Grep to search relevant code
- Note potential conflicts with other requirements

**Validate dependencies:**
- Check for circular dependencies
- Suggest priority-based ordering if requirements touch same code
- Example: "REQ-002 and REQ-003 both modify auth.py. Which should be done first?"

Continue until user has all requirements defined.

### 5. Non-Functional Requirements

Ask about:
- **Performance:** "Any performance requirements? (e.g., response time < 200ms)"
- **Security:** "Security requirements? (e.g., encryption, auth)"
- **Accessibility:** "Accessibility requirements? (e.g., WCAG 2.1 AA)"
- **Scalability:** "Scalability needs? (e.g., concurrent users)"
- **Browser/Platform:** "Browser or platform requirements?"

For each mentioned, create NFREQ-XXX with acceptance criteria.

### 6. UI Testing Detection

**Analyze if UI tests needed:**
- Check for keywords: "UI", "interface", "page", "component", "form", "button"
- Check user stories: "user can see", "user clicks", "displays"
- If existing code, check for: `.tsx`, `.jsx`, `.vue`, `.svelte` files

**If UI tests detected:**
- Add to PRD metadata: `UI_TESTS_REQUIRED: true`
- Add NFREQ for UI testing requirements
- Note which requirements need browser testing

### 7. Success Metrics

Ask:
- "How will you measure success?"
- "What are the target values?"
- "What timeline for achieving metrics?"

Suggest metrics based on requirements (completion rate, performance, etc.)

### 8. Story Breakdown Analysis

**Analyze the complete PRD:**

**Detect dependencies:**
- Explicit: Already captured in step 4
- Auto-detect:
  - Requirements that modify same files/modules
  - Requirements that reference each other
  - Logical dependencies (e.g., "delete" depends on "create")

**Assign execution order:**
- Group by priority (high → medium → low)
- Within priority, order by dependencies
- Identify stories that can run in parallel (no shared code, no dependencies)

**Suggest breakdown:**
```
Execution Plan:
Phase 1 (parallel, max 3):
  - REQ-001 (no deps)
  - REQ-002 (no deps)
  - REQ-003 (no deps)

Phase 2 (sequential, touches same code):
  - REQ-004 (depends on REQ-001, modifies auth.py)
  - REQ-005 (depends on REQ-004, modifies auth.py)

Phase 3 (parallel):
  - REQ-006 (all deps satisfied)
  - REQ-007 (all deps satisfied)
```

Ask user: "Does this breakdown look correct? Any adjustments?"

### 9. Fill Gaps

**Check for completeness:**
- [ ] Problem statement clear?
- [ ] All requirements have acceptance criteria?
- [ ] Dependencies explicitly stated?
- [ ] Priorities assigned?
- [ ] Success metrics defined?
- [ ] Test requirements identified?

**If gaps found, ask questions:**
- "REQ-003 has no acceptance criteria. What conditions must be met?"
- "REQ-005 might depend on REQ-002. Should I add that dependency?"
- "No success metrics defined. How will you measure completion?"

### 10. Generate PRD Metadata

Add to PRD header:
```yaml
---
ralph_metadata:
  version: 1.0
  created: 2026-02-23T14:50:23Z
  ui_tests_required: true|false
  estimated_stories: 8
  estimated_phases: 3
  max_parallel: 3
  dependencies:
    REQ-001: []
    REQ-002: []
    REQ-003: [REQ-001]
  code_impact:
    REQ-001:
      files: [src/auth/login.py]
      conflicts: []
    REQ-002:
      files: [src/auth/session.py]
      conflicts: []
---
```

### 11. Validate PRD

Run validation checks:
- All REQ-XXX have acceptance criteria
- No circular dependencies
- All dependencies reference valid REQ-XXX
- All user stories referenced by at least one requirement
- Code impact analysis complete for existing codebases

If validation fails, ask user to fix issues.

### 12. Generate Story Breakdown File

Create: `specs/prds/<spec-name>.stories.json`

```json
{
  "spec": "<spec-name>",
  "totalStories": 8,
  "executionPhases": [
    {
      "phase": 1,
      "parallel": true,
      "stories": ["REQ-001", "REQ-002", "REQ-003"]
    },
    {
      "phase": 2,
      "parallel": false,
      "stories": ["REQ-004", "REQ-005"]
    }
  ],
  "dependencies": {
    "REQ-001": [],
    "REQ-002": [],
    "REQ-003": ["REQ-001"]
  },
  "codeImpact": {},
  "testRequirements": {
    "unit": true,
    "integration": true,
    "ui": true,
    "lint": true,
    "codeQuality": true
  }
}
```

### 13. Summary and Next Steps

Display:
```
[Ralph Create PRD] PRD Created: specs/prds/<spec-name>.prd.md
[Ralph Create PRD]
[Ralph Create PRD] Summary:
[Ralph Create PRD] - 8 functional requirements
[Ralph Create PRD] - 3 non-functional requirements
[Ralph Create PRD] - 5 user stories
[Ralph Create PRD] - 3 execution phases
[Ralph Create PRD] - Max 3 parallel stories
[Ralph Create PRD] - UI tests required: Yes
[Ralph Create PRD]
[Ralph Create PRD] Estimated completion: 3-5 hours
[Ralph Create PRD]
[Ralph Create PRD] Ready to start Ralph Loop!
[Ralph Create PRD]
[Ralph Create PRD] Next step: /ralph-loop specs/prds/<spec-name>.prd.md
```

## Suggestions Feature

If user is stuck, provide suggestions based on common patterns:

**For auth features:** Suggest login, logout, session, password reset requirements
**For CRUD features:** Suggest create, read, update, delete, list requirements
**For APIs:** Suggest endpoint definitions, validation, error handling requirements
**For UI:** Suggest component structure, interactions, accessibility requirements

## Examples

```
/ralph-create-prd user-authentication
```

Claude will guide through:
1. Problem statement
2. User stories (3-5)
3. Requirements (5-10)
4. Acceptance criteria for each
5. Dependencies
6. Non-functional requirements
7. Story breakdown
8. Validation

Result: Complete, validated PRD ready for Ralph Loop execution.
