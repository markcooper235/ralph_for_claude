# Ralph Archive - Complete Ralph Run and Prepare for Next

Archive completed Ralph run, merge to origin branch, and reset state for next run.

## Usage

```
/ralph-archive [--abandon]
```

## Instructions

This skill completes a Ralph run by archiving artifacts and merging to origin branch.

### Pre-Check: Verify Run Status

**Check if Ralph run exists:**
```bash
if [ ! -f .ralph/state.json ]; then
  echo "Error: No Ralph run in progress"
  exit 1
fi
```

**Load state:**
- Read `.ralph/state.json`
- Check status field

**Verify ready for archive:**

If `--abandon` flag provided:
- Allow archival from any state
- Skip merge step
- Mark as abandoned

If normal archive (no flag):
- Required status: "ready_for_archive" or "complete"
- If status is "failed", "implementing", etc.:
  ```
  Error: Ralph run not complete
  Current status: implementing
  Options:
    - Complete the run first
    - Use --abandon flag to abandon run
  ```
  Exit

### Phase 1: Final Validation (Normal Archive Only)

**Run pre-merge checks:**

1. **Verify all tests pass:**
   ```bash
   # Run complete test suite based on project type
   case "$PROJECT_TYPE" in
     *js*|*ts*)
       npm test || exit 1
       ;;
     *python*)
       pytest || exit 1
       ;;
     *rust*)
       cargo test || exit 1
       ;;
     *go*)
       go test ./... || exit 1
       ;;
   esac
   ```

2. **Verify no uncommitted changes:**
   ```bash
   if [ -n "$(git status --porcelain)" ]; then
     echo "Error: Uncommitted changes detected"
     git status
     exit 1
   fi
   ```

3. **Verify all stories completed:**
   ```bash
   # Check .ralph/stories.json
   INCOMPLETE=$(jq -r '[.stories[] | select(.status != "completed")] | length' .ralph/stories.json)
   if [ "$INCOMPLETE" -gt 0 ]; then
     echo "Error: $INCOMPLETE stories not completed"
     exit 1
   fi
   ```

4. **Check for conflicts with origin:**
   ```bash
   ORIGIN_BRANCH=$(jq -r '.git.originBranch' .ralph/state.json)
   git fetch origin

   # Check if origin branch has moved
   git merge-base --is-ancestor origin/$ORIGIN_BRANCH HEAD
   if [ $? -ne 0 ]; then
     echo "Warning: Origin branch has new commits"
     echo "Attempting merge..."
     git merge origin/$ORIGIN_BRANCH || {
       echo "Error: Merge conflicts detected"
       echo "Resolve conflicts and run /ralph-archive again"
       exit 1
     }
   fi
   ```

**If any check fails:**
- Display error
- Do not proceed
- Exit with instructions

### Phase 2: Create Archive Directory

**Generate archive path:**
```bash
RUN_ID=$(jq -r '.runId' .ralph/state.json)
ARCHIVE_DIR="archive/${RUN_ID}"

mkdir -p "${ARCHIVE_DIR}"/{spec,state,logs,artifacts,feedback,tests,git-info}
```

### Phase 3: Collect and Copy Artifacts

**Copy all Ralph artifacts:**

```bash
# 1. Original specification
SPEC_FILE=$(jq -r '.specFile' .ralph/state.json)
cp "$SPEC_FILE" "${ARCHIVE_DIR}/spec/"

# 2. State files
cp -r .ralph/state/*.json "${ARCHIVE_DIR}/state/" 2>/dev/null || true
cp .ralph/state.json "${ARCHIVE_DIR}/state/"
cp .ralph/stories.json "${ARCHIVE_DIR}/state/"
cp .ralph/architecture.json "${ARCHIVE_DIR}/state/" 2>/dev/null || true

# 3. Logs
cp -r .ralph/logs/* "${ARCHIVE_DIR}/logs/" 2>/dev/null || true

# 4. Artifacts
cp -r .ralph/artifacts/* "${ARCHIVE_DIR}/artifacts/" 2>/dev/null || true

# 5. Feedback/test results
cp -r feedback/* "${ARCHIVE_DIR}/feedback/" 2>/dev/null || true

# 6. Test outputs (if any)
find . -name "*.test.log" -o -name "test-results*.json" | while read f; do
  cp "$f" "${ARCHIVE_DIR}/tests/"
done
```

**Capture test tool outputs:**

```bash
# Look for test output files
find . -path ./node_modules -prune -o -name "coverage" -type d -print | while read d; do
  cp -r "$d" "${ARCHIVE_DIR}/tests/coverage-$(basename $(dirname $d))"
done

# Playwright reports
if [ -d "playwright-report" ]; then
  cp -r playwright-report "${ARCHIVE_DIR}/tests/"
fi

# pytest reports
if [ -f ".coverage" ]; then
  cp .coverage "${ARCHIVE_DIR}/tests/"
fi
if [ -d "htmlcov" ]; then
  cp -r htmlcov "${ARCHIVE_DIR}/tests/"
fi

# Jest coverage
if [ -d "coverage" ]; then
  cp -r coverage "${ARCHIVE_DIR}/tests/jest-coverage"
fi
```

### Phase 4: Generate Git Info

**Capture git information:**

```bash
RALPH_BRANCH=$(jq -r '.git.ralphBranch' .ralph/state.json)
ORIGIN_BRANCH=$(jq -r '.git.originBranch' .ralph/state.json)

cat > "${ARCHIVE_DIR}/git-info/branch-info.txt" <<EOF
Ralph Branch: ${RALPH_BRANCH}
Origin Branch: ${ORIGIN_BRANCH}
Created: $(git log --format=%aI ${RALPH_BRANCH} | tail -1)
Completed: $(date -Iseconds)
EOF

# Commit log
git log ${ORIGIN_BRANCH}..${RALPH_BRANCH} --pretty=format:"%H|%an|%aI|%s" > "${ARCHIVE_DIR}/git-info/commits.txt"

# Detailed commit log
git log ${ORIGIN_BRANCH}..${RALPH_BRANCH} --stat > "${ARCHIVE_DIR}/git-info/commits-detailed.txt"

# Diff summary
git diff ${ORIGIN_BRANCH}..${RALPH_BRANCH} --stat > "${ARCHIVE_DIR}/git-info/diff-summary.txt"

# Full diff
git diff ${ORIGIN_BRANCH}..${RALPH_BRANCH} > "${ARCHIVE_DIR}/git-info/full-diff.patch"
```

### Phase 5: Generate Human-Readable Summary

**Create summary.md:**

```bash
cat > "${ARCHIVE_DIR}/summary.md" <<EOF
# Ralph Loop Run Summary

## Run Information
- **Run ID:** ${RUN_ID}
- **Specification:** ${SPEC_FILE}
- **Started:** $(jq -r '.createdAt' .ralph/state.json)
- **Completed:** $(date -Iseconds)
- **Status:** $(jq -r '.status' .ralph/state.json)

## Git Information
- **Origin Branch:** ${ORIGIN_BRANCH}
- **Ralph Branch:** ${RALPH_BRANCH}
- **Total Commits:** $(git rev-list --count ${ORIGIN_BRANCH}..${RALPH_BRANCH})

## Stories Summary
$(jq -r '
"- **Total Stories:** \(.stories | length)
- **Completed:** \([.stories[] | select(.status == "completed")] | length)
- **Failed:** \([.stories[] | select(.status == "failed")] | length)"
' .ralph/stories.json)

## Test Results
$(jq -r '
.testResults | to_entries | map("- **\(.key | ascii_upcase):** \(.value.status) (iterations: \(.value.iterations))") | join("\n")
' .ralph/state.json)

## Story Details

$(jq -r '
.stories[] |
"### \(.id): \(.title)
- **Priority:** \(.priority)
- **Status:** \(.status)
- **Tests:** \(.tests.status)
- **Commits:** \(.commits | length)
- **Logic Iterations:** \(.iterations.logic)
- **Format Iterations:** \(.iterations.formatting)

**Acceptance Criteria:**
\(.acceptanceCriteria | map("- \(.)") | join("\n"))

"
' .ralph/stories.json)

## Files Changed

$(git diff ${ORIGIN_BRANCH}..${RALPH_BRANCH} --name-status | head -50)

$(git diff ${ORIGIN_BRANCH}..${RALPH_BRANCH} --name-status | wc -l > /tmp/total_files)
$([ $(cat /tmp/total_files) -gt 50 ] && echo "... and $(expr $(cat /tmp/total_files) - 50) more files")

## Test Coverage

$(if [ -f .ralph/artifacts/proof-report.json ]; then
  jq -r '
  "- **Overall Coverage:** \(.overallCoverage)%
- **Requirements Proven:** \(.requirementsProven)/\(.totalRequirements)
- **Test Pass Rate:** \(.testPassRate)%"
  ' .ralph/artifacts/proof-report.json
fi)

## Artifacts Archived

- State files: $(find ${ARCHIVE_DIR}/state -type f | wc -l) files
- Logs: $(find ${ARCHIVE_DIR}/logs -type f | wc -l) files
- Test results: $(find ${ARCHIVE_DIR}/tests -type f | wc -l) files
- Other artifacts: $(find ${ARCHIVE_DIR}/artifacts -type f | wc -l) files

## Next Steps

This Ralph run has been archived and$([ "$ABANDON" != "true" ] && echo " merged to ${ORIGIN_BRANCH}" || echo " abandoned (not merged)").

The workspace is now clean and ready for the next Ralph run.

---
*Generated by Ralph Loop Framework*
*Archive: ${ARCHIVE_DIR}*
EOF
```

**Save metadata.json:**

```bash
jq -n \
  --arg runId "$RUN_ID" \
  --arg specFile "$SPEC_FILE" \
  --arg originBranch "$ORIGIN_BRANCH" \
  --arg ralphBranch "$RALPH_BRANCH" \
  --arg status "$(jq -r '.status' .ralph/state.json)" \
  --arg archived "$(date -Iseconds)" \
  --argjson abandoned "$([ '$ABANDON' = 'true' ] && echo true || echo false)" \
  '{
    runId: $runId,
    specFile: $specFile,
    originBranch: $originBranch,
    ralphBranch: $ralphBranch,
    status: $status,
    archivedAt: $archived,
    abandoned: $abandoned
  }' > "${ARCHIVE_DIR}/metadata.json"
```

### Phase 6: Merge to Origin Branch (Normal Archive Only)

**Switch to origin branch:**
```bash
git checkout "$ORIGIN_BRANCH"
```

**Merge Ralph branch:**
```bash
# Regular merge (not squash, preserves all commits)
git merge --no-ff "$RALPH_BRANCH" -m "$(cat <<EOF
Merge Ralph Loop: ${RUN_ID}

Completed all requirements from ${SPEC_FILE}

Stories completed: $(jq -r '[.stories[] | select(.status == "completed")] | length' .ralph/stories.json)
Test coverage: $(jq -r '.testResults.unit.coverage // "N/A"' .ralph/state.json)%

All tests passing:
- Lint: passed
- Unit tests: passed
- Code quality: passed
$(jq -r 'if .testResults.ui.status == "passed" then "- UI tests: passed" else "" end' .ralph/state.json)

Archive: ${ARCHIVE_DIR}

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
EOF
)"
```

**Verify merge:**
```bash
if [ $? -ne 0 ]; then
  echo "Error: Merge failed"
  echo "Manual intervention required"
  exit 1
fi
```

**Update archive with merge commit:**
```bash
MERGE_COMMIT=$(git rev-parse HEAD)
echo "Merge commit: ${MERGE_COMMIT}" >> "${ARCHIVE_DIR}/git-info/branch-info.txt"
```

### Phase 7: Cleanup Ralph State

**Remove Ralph working directory:**
```bash
rm -rf .ralph
```

**Delete Ralph branch (optional - keep for reference):**
```bash
# Optionally delete the branch after successful merge
# git branch -d "$RALPH_BRANCH"

# Or keep it for history
echo "Ralph branch preserved: ${RALPH_BRANCH}"
```

**Clear any temporary Ralph files:**
```bash
rm -f .ralph-*.json
```

### Phase 8: Verify Clean State

**Check workspace is clean:**
```bash
# Should have no Ralph state
if [ -d .ralph ]; then
  echo "Warning: .ralph directory still exists"
fi

# Should be on origin branch
CURRENT_BRANCH=$(git branch --show-current)
if [ "$CURRENT_BRANCH" != "$ORIGIN_BRANCH" ]; then
  echo "Warning: Not on origin branch (on ${CURRENT_BRANCH})"
fi

# No uncommitted changes
if [ -n "$(git status --porcelain)" ]; then
  echo "Warning: Uncommitted changes detected"
fi
```

### Phase 9: Display Completion Summary

**Normal archive completion:**

```
[Ralph Archive] ✓ Ralph run archived successfully!
[Ralph Archive]
[Ralph Archive] Archive Location: ${ARCHIVE_DIR}
[Ralph Archive]
[Ralph Archive] Summary:
[Ralph Archive] - Stories completed: 8/8
[Ralph Archive] - Commits created: 8
[Ralph Archive] - Merge commit: ${MERGE_COMMIT:0:7}
[Ralph Archive] - Branch: ${ORIGIN_BRANCH} (merged)
[Ralph Archive] - Ralph branch: ${RALPH_BRANCH} (preserved)
[Ralph Archive]
[Ralph Archive] Archived Artifacts:
[Ralph Archive] - Original spec: ${SPEC_FILE}
[Ralph Archive] - State files: X files
[Ralph Archive] - Execution logs: Y files
[Ralph Archive] - Test results: Z files
[Ralph Archive] - Git history: Full commit log and diffs
[Ralph Archive]
[Ralph Archive] Workspace Status:
[Ralph Archive] - Ralph state: Cleaned
[Ralph Archive] - Current branch: ${ORIGIN_BRANCH}
[Ralph Archive] - Status: Ready for next Ralph run
[Ralph Archive]
[Ralph Archive] To review this run:
[Ralph Archive]   cat ${ARCHIVE_DIR}/summary.md
[Ralph Archive]   git log ${MERGE_COMMIT}
[Ralph Archive]
[Ralph Archive] To start next run:
[Ralph Archive]   /ralph-create-prd <new-spec-name>
[Ralph Archive]   /ralph-loop specs/prds/<new-spec>.prd.md
```

**Abandoned run:**

```
[Ralph Archive] Run abandoned and archived
[Ralph Archive]
[Ralph Archive] Archive Location: ${ARCHIVE_DIR}
[Ralph Archive] Status: Abandoned (not merged)
[Ralph Archive] Ralph branch: ${RALPH_BRANCH} (preserved for review)
[Ralph Archive]
[Ralph Archive] Workspace cleaned and ready for next run.
```

## Error Handling

**If archive fails at any step:**
1. Log error to `.ralph/logs/archive-error.log`
2. Do NOT delete `.ralph/` directory
3. Do NOT merge branch
4. Display error with recovery instructions
5. Exit with error code

**Recovery from failed archive:**
- Fix the issue
- Run `/ralph-archive` again
- State preserved until successful archive

## Examples

**Normal completion:**
```bash
/ralph-archive
```

**Abandon failed run:**
```bash
/ralph-archive --abandon
```

## Integration

- Called after `/ralph-loop` completes successfully
- Prerequisite: Ralph run status must be "ready_for_archive" or "complete"
- After archive, workspace ready for next `/ralph-loop`

## Safety Features

1. **No data loss:** All artifacts archived before cleanup
2. **Verify before merge:** All checks must pass
3. **Preserve branch:** Ralph branch kept for reference
4. **Conflict detection:** Abort if merge conflicts
5. **Clean state guarantee:** Workspace always clean after archive

## Notes

- Archive directory never committed to git (in .gitignore)
- Archive preserves complete run history
- Can review past runs anytime from archive/
- Each run gets unique timestamped directory
- Merge preserves all individual story commits
