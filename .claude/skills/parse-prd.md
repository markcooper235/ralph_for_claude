# Parse PRD - Product Requirements Document Parser

Parse PRD documents and extract structured requirements for task creation.

## Usage

```
/parse-prd <prd-file-path>
```

## Instructions

When this skill is invoked:

1. **Read PRD Document**
   - Load the specified PRD file
   - Validate it follows PRD format (or adapt to actual format)
   - Extract metadata (project name, version, author, date)

2. **Parse Sections**

   Extract and structure these key sections:

   **Problem Statement**
   - Why this project exists
   - What problem it solves
   - Target users/audience

   **User Stories**
   - As a [user type]
   - I want to [action]
   - So that [benefit]

   **Functional Requirements**
   - Format: REQ-XXX: [requirement description]
   - Extract requirement ID, description, priority
   - Note dependencies between requirements

   **Non-Functional Requirements**
   - Performance requirements
   - Security requirements
   - Accessibility requirements
   - Scalability requirements

   **Acceptance Criteria**
   - For each requirement, list testable criteria
   - Format: Given/When/Then or checklist

   **Success Metrics**
   - How success will be measured
   - Quantifiable metrics
   - Target values

3. **Create Structured Output**

   Generate JSON structure:
   ```json
   {
     "metadata": {
       "projectName": "...",
       "version": "...",
       "author": "...",
       "date": "..."
     },
     "problemStatement": "...",
     "userStories": [
       {
         "id": "US-001",
         "as": "...",
         "want": "...",
         "so": "..."
       }
     ],
     "requirements": [
       {
         "id": "REQ-001",
         "type": "functional",
         "description": "...",
         "priority": "high",
         "acceptanceCriteria": [],
         "dependencies": [],
         "userStories": ["US-001"]
       }
     ],
     "successMetrics": []
   }
   ```

4. **Generate Tasks**
   - Use TaskCreate for each requirement
   - Task subject: REQ-XXX requirement description
   - Task description: Full details + acceptance criteria
   - Set dependencies using addBlockedBy
   - Add metadata linking to requirement ID

5. **Create Test Checklist**
   - Generate checklist of all acceptance criteria
   - Save to `specs/prds/<name>.checklist.md`
   - Format for easy `/test-spec` execution

6. **Output Summary**
   - Display parsed structure
   - Show task breakdown
   - Highlight any parsing issues or ambiguities
   - Ask user to confirm or clarify

## PRD Template Reference

Expected PRD format:
```markdown
# Project Name

## Problem Statement
[Description]

## User Stories
- US-001: As a [user], I want to [action], so that [benefit]

## Functional Requirements
- REQ-001: [Description] (Priority: High)
  - Acceptance Criteria:
    - [ ] Criterion 1
    - [ ] Criterion 2

## Non-Functional Requirements
- NFREQ-001: [Description]

## Success Metrics
- Metric 1: [Target value]
```

## Output Format

```
[Parse PRD] Reading: specs/prds/user-authentication.prd.md
[Parse PRD]
[Parse PRD] Project: User Authentication System
[Parse PRD] Version: 1.0
[Parse PRD]
[Parse PRD] Parsed Structure:
[Parse PRD] - 3 User Stories
[Parse PRD] - 8 Functional Requirements
[Parse PRD] - 4 Non-Functional Requirements
[Parse PRD] - 5 Success Metrics
[Parse PRD]
[Parse PRD] Requirements Breakdown:
[Parse PRD]
[Parse PRD] REQ-001: User login with email/password (Priority: High)
[Parse PRD]   - 3 acceptance criteria
[Parse PRD]   - Depends on: None
[Parse PRD]   - Related user stories: US-001
[Parse PRD]
[Parse PRD] REQ-002: Session management (Priority: High)
[Parse PRD]   - 4 acceptance criteria
[Parse PRD]   - Depends on: REQ-001
[Parse PRD]   - Related user stories: US-001, US-002
[Parse PRD]
[Parse PRD] ... (6 more requirements)
[Parse PRD]
[Parse PRD] Creating 8 tasks...
[Parse PRD] ✓ Task 1 created: REQ-001 User login
[Parse PRD] ✓ Task 2 created: REQ-002 Session management (blocked by Task 1)
[Parse PRD] ... (6 more tasks)
[Parse PRD]
[Parse PRD] Test checklist saved: specs/prds/user-authentication.checklist.md
[Parse PRD] Structured data saved: specs/prds/user-authentication.parsed.json
[Parse PRD]
[Parse PRD] Ready to start Ralph Loop? (y/n)
```

## Examples

```
/parse-prd specs/prds/user-authentication.prd.md
```

## Integration Points

- Used by `/ralph-loop` to ingest specifications
- Creates tasks automatically
- Generates test checklists for `/test-spec`
- Outputs structured data for tooling integration
