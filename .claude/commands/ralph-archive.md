# Ralph Archive - Complete Ralph Run and Prepare for Next

Archive completed Ralph run, merge to origin branch, and reset state for next run.

## Usage

```
/ralph-archive [--abandon]
```

## Instructions

### Pre-Check

```bash
[ ! -f ralph/.ralph/state.json ] && echo "Error: No Ralph run in progress" && exit 1
```

Load state.json. Check status field.

**Normal archive** requires status "ready_for_archive" or "complete". Any other status: display error and exit (unless `--abandon` flag given).

**Abandon** (`--abandon` flag): skip merge, mark as abandoned, proceed to archive.

### Phase 1: Final Validation (Normal Archive Only)

1. Read `ralph/.ralph/artifacts/artifacts-index.json` — if `allPassed` is false or the file is missing, display "Some stories failed testing — fix before archiving" and halt. (Tests were already run per-story in Phase 4; trust those results.)
2. `git status --porcelain` — if output is not empty, commit all remaining changes before proceeding:
   ```bash
   git add -A
   git commit -m "chore: commit uncommitted files before archive merge

   Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
   ```
3. Check `state.completedStories == state.totalStories` — must be equal (no jq on stories.json needed if state is current).
4. Check `state.premergeChecks.checkedAt`:
   - If within the last 30 minutes: skip git fetch + merge-base (Phase 7 already validated, results still fresh).
   - If older than 30 minutes or missing: re-run `git fetch origin && git merge-base --is-ancestor origin/$ORIGIN_BRANCH HEAD` — if fails, attempt `git merge origin/$ORIGIN_BRANCH` and abort on conflict.

If checks 3 or 4 fail: display reason, exit. Do not proceed.

### Phase 2: Create Archive Directory

```bash
RUN_ID=$(jq -r '.runId' ralph/.ralph/state.json)
ARCHIVE_DIR="ralph/archive/${RUN_ID}"
mkdir -p "${ARCHIVE_DIR}"/{spec,state,logs,artifacts,feedback,tests,git-info}
```

### Phase 3: Collect Artifacts

Copy to archive:
- Spec file → `archive/spec/`
- `ralph/.ralph/state.json`, `stories.json`, `architecture.json` → `archive/state/`
- `ralph/.ralph/logs/` → `archive/logs/`
- `ralph/.ralph/artifacts/` → `archive/artifacts/`
- `ralph/feedback/` → `archive/feedback/`
- Test output dirs (coverage/, playwright-report/, htmlcov/, .coverage) → `archive/tests/`

### Phase 4: Git Info

```bash
git log ${ORIGIN_BRANCH}..${RALPH_BRANCH} --pretty=format:"%H|%an|%aI|%s" > "${ARCHIVE_DIR}/git-info/commits.txt"
git diff ${ORIGIN_BRANCH}..${RALPH_BRANCH} --stat > "${ARCHIVE_DIR}/git-info/diff-summary.txt"
git diff ${ORIGIN_BRANCH}..${RALPH_BRANCH} > "${ARCHIVE_DIR}/git-info/full-diff.patch"
```

### Phase 5: Generate Summary

Write `${ARCHIVE_DIR}/summary.md` with: run ID, spec file, start/end times, git branches, story counts (completed/failed), test results summary, files changed count, coverage from proof-report.json.

Write `${ARCHIVE_DIR}/metadata.json` with: runId, specFile, originBranch, ralphBranch, status, archivedAt, abandoned (bool).

### Phase 5b: Commit Archive to Ralph Branch

```bash
git add "${ARCHIVE_DIR}"
git commit -m "chore: add run archive ${RUN_ID}

Archive: ${ARCHIVE_DIR}
Stories: $(jq '[.stories[] | select(.status=="completed")] | length' ralph/.ralph/stories.json) completed

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

### Phase 6: Merge (Normal Archive Only)

```bash
git checkout "$ORIGIN_BRANCH"
git merge --no-ff "$RALPH_BRANCH" -m "Merge Ralph Loop: ${RUN_ID}

Stories: $(jq '[.stories[] | select(.status=="completed")] | length' ralph/.ralph/stories.json) completed
Archive: ${ARCHIVE_DIR}

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

Record merge commit and write to archive, then commit:
```bash
MERGE_COMMIT=$(git rev-parse HEAD)
echo "Merge commit: ${MERGE_COMMIT}" > "${ARCHIVE_DIR}/git-info/branch-info.txt"
git add "${ARCHIVE_DIR}/git-info/branch-info.txt"
git commit -m "chore: record merge commit hash for ${RUN_ID}

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

### Phase 7: Cleanup

```bash
rm -rf ralph/.ralph
```

Ralph branch is preserved for reference (not auto-deleted).

### Phase 8: Verify Clean State

Check: no `ralph/.ralph/` directory, on origin branch, no uncommitted changes.

Display completion:
```
[Ralph Archive] ✓ Archived to ${ARCHIVE_DIR}
[Ralph Archive] Merged to ${ORIGIN_BRANCH} | Branch: ${RALPH_BRANCH} preserved
[Ralph Archive] Ready for next run: /ralph-create-prd or /ralph-loop
```

## Error Handling

On any failure: log to `ralph/.ralph/logs/archive-error.log`, do NOT delete `ralph/.ralph/` or merge branch. Display error and exit. Fix issue and retry `/ralph-archive`.
