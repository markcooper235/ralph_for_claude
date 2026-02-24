# Ralph Modify Spec - Modify Specification During Run

Handle spec modifications, gaps, and clarifications discovered during implementation.

## Usage

```
/ralph-modify-spec [--add-requirements] [--change-priorities] [--update-criteria]
```

## Instructions

### 1. Check Current State

```bash
[ ! -f ralph/.ralph/state.json ] && echo "[Modify Spec] Error: No Ralph run in progress" && exit 1
```

Load: runId, specFile, status, currentStory from state.json.

### 2. Pause Current Work

If status is "implementing": update state to `paused_spec_modification`, paused=true, resumePhase="implementing".

### 3. Display Current Spec State

Show all stories with [STATUS] REQ-XXX: title (priority), plus completed/total count.

### 4. Present Modification Options

Ask the user which type of modification:

| Option | Action |
|---|---|
| 1. Add requirements | New REQ-XXX for discovered gaps |
| 2. Modify existing | Update title, description, or criteria |
| 3. Change priorities | Reorder execution |
| 4. Update acceptance criteria | Add/modify/remove criteria |
| 5. Modify dependencies | Add/remove story dependencies |
| 6. Remove requirements | Scope reduction |
| 7. Interactive review | Guided walk-through |

### 5. Process Each Modification Type

**Add requirements (option 1):**
- Collect: description, priority, acceptance criteria, dependencies, affected files
- Assign next sequential REQ-ID
- Analyze code impact and detect conflicts with existing stories
- Add to spec file and stories.json
- Update execution phases

**Modify existing (option 2):**
- If story is completed: warn user. Options: A) revert+re-implement, B) new additive commit, C) skip
  - If A: `git revert <commit> --no-commit`, set story status back to "pending"
- Update spec file and stories.json

**Change priorities (option 3):** Update priority fields and re-sort execution phases.

**Update criteria (option 4):** Add/remove/edit acceptance criteria lines. If story completed, trigger revert+re-implement flow.

**Modify dependencies (option 5):** Add/remove REQ-XXX from dependencies[]. Re-validate execution order.

**Remove requirements (option 6):** Remove from spec, stories.json. If committed: `git revert` the story commit.

### 6. Version the Spec

```bash
SPEC_VERSION=$(jq -r '.specVersion // 1' ralph/.ralph/state.json)
NEW_VERSION=$((SPEC_VERSION + 1))
cp "$SPEC_FILE" "${SPEC_FILE}.v${SPEC_VERSION}.backup"
# Write changes to spec file
# Append modification history block to spec
```

### 7. Re-analyze Execution Plan

Launch a brief subagent to:
- Load modified stories.json
- Re-detect dependencies and code conflicts
- Rebuild execution phases respecting completed stories
- Return: new phase count, any newly-blocked/unblocked stories

### 8. Save Modification Record

Write `ralph/.ralph/artifacts/spec-modification-${SPEC_VERSION}.json`:
```json
{
  "version": <new>, "previousVersion": <old>, "modifiedAt": "<iso>",
  "reason": "<user input>", "runId": "<id>",
  "changes": {"newRequirements": [], "modifiedRequirements": [], "removedRequirements": []},
  "impact": {"storiesAdded": 0, "storiesModified": 0, "storiesReverted": 0}
}
```

### 9. Update State and Resume

```bash
jq '.specVersion = <new> | .status = "implementing" | .paused = false |
    del(.pausedAt, .pauseReason)' ralph/.ralph/state.json > tmp && mv tmp ralph/.ralph/state.json
```

Display summary: spec version, stories added/modified/reverted, next steps (`/ralph-status`, `/ralph-resume`).

## Key Rules

- **Completed stories modified** → always offer revert+re-implement as default
- **Backup always created** before modifying spec file
- **Modification archived** to artifacts/ for inclusion in final archive
- **Dependencies re-validated** after every modification
- **Resumption is seamless** — ralph-loop continues from updated stories.json
