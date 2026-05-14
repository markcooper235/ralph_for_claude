---
name: ralph-loop
description: Execute the complete Ralph Loop development cycle with parallel subagent execution, state management, and git integration. Use when starting a new Ralph Loop run from a PRD or OpenSpec specification file.
argument-hint: <spec-file>
disable-model-invocation: true
---

## Instructions

When this skill is invoked:

### Phase 0: Initialization

Check for existing run:
- If `ralph/.ralph/state.json` **exists**:
  - Read `STATUS=$(jq -r '.status' ralph/.ralph/state.json)`
  - If status starts with `paused_`: **Resume mode** — load state; build `completed` set from stories.json (all stories with status="completed"); set `ITER` from `state.iter` (default 1); skip directly to the phase in `state.resumePhase` (typically Phase 3)
  - Otherwise: exit with "Error: Ralph run in progress (status: ${STATUS}). Use /ralph-archive to complete or abandon."
- If `ralph/.ralph/state.json` **does not exist**: Fresh run — proceed:

```bash
mkdir -p ralph/.ralph/{logs,artifacts,stories}
```

Initialize `ralph/.ralph/state.json` (use `ralph/.ralph-state-template.json` if it exists, otherwise create inline):
```json
{"runId":"<spec-name>-<timestamp>","specFile":"<path>","status":"parsing","createdAt":"<ISO>","completedStories":0,"totalStories":0,"iter":1,"git":{"commits":[]}}
```

Create git branch:
```bash
ORIGIN_BRANCH=$(git branch --show-current)
SPEC_NAME=$(basename "$SPEC_FILE" .prd.md)
RALPH_BRANCH="ralph/${SPEC_NAME}-$(date +%Y%m%d%H%M%S)"
git checkout -b "$RALPH_BRANCH"
```
Save both branches to state.json.

**NX workspace check:** If `nx.json` or `ralph/nx-workspace.json` exists, load NX config (frontends, backends, unit_test runner). Use `nx run <project>:<cmd>` instead of `npm run <cmd>` throughout.

### Phase 1: Parse Specification

```python
result = Task(
    subagent_type="general-purpose",
    description="Parse PRD specification",
    prompt=f"""
Parse the PRD at {spec_file}.

Extract all REQ-XXX requirements with: id, title, description, priority, acceptanceCriteria[], dependencies[], codeImpact.files[].

Auto-detect additional dependencies:
- REQ-XXX references in text
- Logical (delete depends on create)
- Code conflicts: requirements touching same files run sequentially (by priority)

UI test flag — set testRequirements.ui = true if ANY of the following are present (any one is sufficient):
1. PRD metadata contains `ui_tests_required: true` — AUTHORITATIVE, always sets ui = true regardless of other signals
2. Requirement text contains UI keywords: "UI", "interface", "page", "component", "form", "button", "display", "visual", "browser", "screen"
3. codeImpact.files contains UI file extensions: .tsx, .jsx, .vue, .svelte, .html paired with JS/TS
Rule: ui defaults to false; any signal above sets it to true. Keyword absence must never override explicit metadata.

Integration test flag — set testRequirements.integration = true if ANY of the following are present:
1. projectType is a server/API type: express, nextjs, flask, python, reflex, adk-python, go, adk-go, adk-ts, adk-java, actix, rocket, rails, ruby, dotnet (webapi/mvc/blazor sub-types only)
2. OR PRD text contains API keywords: "API", "endpoint", "REST", "route", "POST", "GET", "PUT", "DELETE", "CRUD", "HTTP", "middleware", "authentication", "authorization"
3. OR projectType is adk-python, adk-go, adk-ts, or adk-java (ADK agents always benefit from end-to-end conversation tests)
Never set true for: react, angular, dotnet blazorwasm, nx.

Save ralph/.ralph/stories.json:
{{"stories":[{{"id","title","description","priority","status":"pending","acceptanceCriteria":[],"dependencies":[],"codeImpact":{{"files":[]}}}}],"testRequirements":{{"unit":true,"lint":true,"codeQuality":true,"ui":false,"integration":false}}}}

For each story, write ralph/.ralph/stories/<ID>-brief.md:
```
# <ID>: <title>
Priority: <priority>
Dependencies: <list or none>

## Description
<description>

## Acceptance Criteria
- <criterion 1>
- <criterion 2>

## Code Impact
Files: <file list>
```

Write full parse details to ralph/.ralph/logs/parse-1.log
All analysis and details go to the log — NOT returned to the orchestrator.
Return ONE LINE ONLY to the orchestrator: "PARSE: OK | <N> stories | <first-ID> to <last-ID>"
"""
)
```

Read `ralph/.ralph/stories.json`. Validate structure. Display: story count, dependency map, UI tests required (yes/no).
Update state: status="architecture".

### Phase 2: Architecture

```python
result = Task(
    subagent_type="general-purpose",
    description="Design architecture",
    prompt="""
Load ralph/.ralph/stories.json. Analyze the codebase (structure, patterns, tech stack, test setup).

Design implementation approach per requirement. Select test tools:
- lint: eslint/black/clippy (by language)
- unit: jest/pytest/cargo test
- ui: playwright command (e.g. `npx playwright test`) if testRequirements.ui = true, otherwise empty string ""
- codeQuality: complexity/duplication
- coverage: command that produces coverage data alongside unit tests
- integration: in-process API test command if testRequirements.integration = true, otherwise empty string ""
  By project type:
  express / nextjs / typescript / javascript: `npx jest --testPathPattern=tests/integration`
  flask:                                      `venv/bin/pytest tests/integration/ -v`
  python / reflex:                            `venv/bin/pytest tests/integration/ -v`
  adk-python:                                 `venv/bin/pytest tests/integration/ -v` (in-process agent invocation; do NOT call Gemini — mock the model or use ADK test harness)
  adk-go:                                     `go test -run TestIntegration ./...` (use the NewAgent factory with a fake API key; do NOT call Gemini)
  adk-ts:                                     `npx vitest run tests/integration` (import rootAgent and assert config; do NOT call Gemini)
  adk-java:                                   `mvn -Dtest='*IntegrationTest' test` (use HelloTimeAgent.buildAgent() with fake API key; do NOT call the model)
  go:                                         `go test -run TestIntegration ./...`
  actix / rocket:                             `cargo test --test integration`
  rust (basic):                               `cargo test --test integration`
  rails:                                      `bundle exec rspec spec/requests/ --format progress`
  ruby (non-Rails):                           `bundle exec rspec spec/integration/`
  dotnet (webapi / mvc / blazor server):      `dotnet test --filter Category=Integration`
  react / angular / dotnet blazorwasm / nx:   "" (frontend only — no integration tests)

Coverage tool selection by language/framework:
- Jest (JS/TS): `jest --coverage` — built-in, no extra tool needed
- Vitest (React/Vite): `vitest run --coverage` — requires @vitest/coverage-v8 (already in package.json)
- pytest (Python): `pytest --cov=src --cov-report=term-missing` — pytest-cov is in requirements.txt
- Go: `go test -cover ./...` — built-in, no extra tool needed
- Rust: `cargo tarpaulin` if `cargo tarpaulin --version` succeeds; otherwise skip coverage
- Ruby/RSpec with simplecov: `bundle exec rspec` — simplecov auto-reports on exit
- Angular: `ng test --no-watch --code-coverage`
- .NET: `dotnet test --collect:"XPlat Code Coverage"` — coverlet.collector is pre-installed in the xUnit template
Write `testTools.coverage` as the full command string (empty string if not available).

**Python venv:** If `venv/` directory exists in the project root (always present for Ralph-created Python/Flask/Reflex/ADK-Python projects), prefix ALL Python tool commands with `venv/bin/`:
- testTools.unit → `venv/bin/pytest`
- testTools.coverage → `venv/bin/pytest --cov=src --cov-report=term-missing`
- testTools.lint → `venv/bin/black` (or `venv/bin/ruff` if ruff is in requirements.txt)
- Record the full binary path in architecture.json so Phase 4 and ralph-archive use it verbatim — no shell activation needed.

Save ralph/.ralph/architecture.json:
{{"projectType","techStack":[],"testTools":{{"lint","unit","coverage","ui","codeQuality","integration"}},"implementation":{{"REQ-XXX":{{"files":[],"tests":[],"approach":""}}}}}}

For each story, append its implementation section to ralph/.ralph/stories/<ID>-brief.md:
```
## Implementation Approach
Files: <implementation.REQ-XXX.files list>
Tests: <implementation.REQ-XXX.tests list>
Approach: <implementation.REQ-XXX.approach>

## Integration Tests (only include this section if testTools.integration is set)
File: tests/integration/test_{story_id_lower}.{ext}
Test this story's HTTP routes using in-process test client (no live server needed):
  Flask:    app.test_client()            Express:  supertest(app)
  Go:       httptest.NewRecorder()       Rails:    RSpec request spec (rack-based)
  .NET:     WebApplicationFactory        actix:    actix_web::test::init_service()
  rocket:   rocket::local::blocking::Client::tracked()
Test: status codes, response body shape, auth/middleware per acceptance criteria.
Name pattern: test_{story_id_lower}_integration (pytest/go), {storyId}.integration (jest/rspec)
```

Write full architecture details to ralph/.ralph/logs/architecture-1.log
All analysis and details go to the log — NOT returned to the orchestrator.
Return ONE LINE ONLY to the orchestrator: "ARCH: OK | <tech> | <test-tools>"
"""
)
```

Read `ralph/.ralph/architecture.json`. Update state: status="implementing", testTools=<architecture.testTools>.

### Phase 3: Implementation Loop

Execution loop (`ITER` starts at 1, increments each outer pass):
1. Find ready stories — all dependencies in `completed` set, story not yet completed
2. Group ready stories by code-file overlap; same-file stories run sequentially by priority, not in parallel
3. Select up to 3 non-conflicting stories; launch all as parallel subagents; wait for all to finish
4. Per result:
   - **FAIL**: read `ralph/.ralph/logs/progress-{story.id}-{ITER}.log`; increment `state.impl_iterations[story.id]`; if ≤ 2 re-launch impl subagent with brief + failure detail injected into prompt; if > 2 set `status="paused_error"`, log error, halt
   - **PASS**: run Phase 4 tests → run Phase 5 commit → add story to `completed`
5. Update `state.completedStories = len(completed)`; `ITER += 1`; repeat until all stories completed

**Impl subagent (launched per story):**
```python
# Orchestrator: read brief once before launching (eliminates subagent file-read startup cost)
# brief = read_file(f"ralph/.ralph/stories/{story_id}-brief.md")
Task(
    subagent_type="general-purpose",
    description=f"Implement {story_id}",
    prompt=f"""
Implement story {story_id} using the following spec:

{brief}

Implement all acceptance criteria. Write tests (one per criterion, named test_{story_id_lower}_N).
List all files created/modified.

Save ralph/.ralph/artifacts/{story_id}-impl.json:
{{"storyId":"{story_id}","status":"completed","files":[],"tests":[],"testResults":"pending","iterations":1}}

Do NOT commit (commits happen after testing).

Write full implementation log to ralph/.ralph/logs/progress-{story_id}-{ITER}.log
All code decisions, file changes, and working notes go to the log — NOT returned to the orchestrator.
Return ONE LINE ONLY to the orchestrator: "{story_id}: OK|FAIL | <N> files | <M> tests"
"""
)
```

### Phase 4: Testing Loop

**Test subagent (per story, after impl succeeds):**
```python
Task(
    subagent_type="general-purpose",
    description=f"Test {story_id}",
    prompt=f"""
Run all tests for {story_id}. Test tools (injected from state — no file read needed): lint={testTools['lint']} | unit={testTools['unit']} | coverage={testTools['coverage']} | ui={testTools['ui']} | codeQuality={testTools['codeQuality']} | integration={testTools['integration']}

A. Lint/Format: run linter, auto-fix where possible, max 3 iterations
B. Unit tests: scope to this story only — filter pattern is the story ID lowercased with hyphens→underscores (REQ-001 → `test_req_001`). Use `-k test_req_001` for pytest, `--testNamePattern test_req_001` for jest, equivalent for other frameworks. Max 5 iterations for logic failures
C. Code quality: complexity and duplication checks
D. UI tests (only if testTools.ui set): playwright, max 5 iterations — before running Playwright, ensure the dev server is running: check `curl -s -o /dev/null -w "%{http_code}" <BASE_URL>` and start it in background if not responsive (see browser-test skill server table for commands/ports by project type)
E. Integration tests (only if testTools.integration set): run integration command scoped to this story's test name pattern (same lowercased ID convention as unit tests). Tests must be hermetic — use in-process test clients, not a live server. Max 5 iterations for failures.

Save ralph/.ralph/artifacts/{story_id}-tests.json:
{{"storyId":"{story_id}","overall":"passed|failed","lint":{{"status","iterations":0}},"unit":{{"status","iterations":0,"coverage":0}},"codeQuality":{{"status"}},"ui":{{"status","iterations":0}},"integration":{{"status","iterations":0}}}}

Update ralph/.ralph/artifacts-index.json:
- Load or create: {{"stories":{{}},"allPassed":true,"avgCoverage":0}}
- Set stories.{story_id}: {{"status":"passed|failed","coverage":<unit.coverage>}}
- Set allPassed: true only if ALL entries in stories have status "passed"
- Update avgCoverage: mean of all coverage values across stories in the index

Write full test log to ralph/.ralph/logs/test-{story_id}-{ITER}.log
All test output, error details, and fix iterations go to the log — NOT returned to the orchestrator.
Return ONE LINE ONLY to the orchestrator: "{story_id}: PASS|FAIL | lint:<s> unit:<s> quality:<s> integration:<s>"
"""
)
```

**On FAIL:** Read `ralph/.ralph/logs/test-{story_id}-{ITER}.log`. Check iteration count vs limits (lint≤3, logic≤5). If under limit: create fix task and re-run. If over limit: pause for user intervention, update state status="paused_error".

**On PASS:** Update story status="completed" in stories.json. Proceed to Phase 5.

### Phase 5: Commit Story

For each story that passes testing:
```bash
jq -r '.files[], .tests[]' ralph/.ralph/artifacts/${STORY_ID}-impl.json | xargs -d '\n' git add --
git commit -m "$(cat <<EOF
${STORY_ID}: ${STORY_TITLE}

Tests: lint/unit/quality passing
Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
EOF
)"
COMMIT_HASH=$(git rev-parse HEAD)

# Mop-up: commit any side-effect files (lock files, generated assets, etc.)
DIRTY=$(git status --porcelain)
if [ -n "$DIRTY" ]; then
    git add -A
    git commit -m "${STORY_ID}: commit side-effect files (lock files, generated assets)

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
fi
```
Save commit hash to story in stories.json and to state.git.commits[].

### Phase 6: Prove Requirements

**Pre-prove check (incremental proof — uses artifacts index):**
```python
# Read single index file instead of N artifact files
if os.path.exists("ralph/.ralph/artifacts-index.json"):
    index = read_json("ralph/.ralph/artifacts-index.json")
    all_passed = index.get("allPassed", False) and len(index["stories"]) == len(all_stories)
else:
    # Fallback: read all artifacts individually
    artifacts = [read_json(f"ralph/.ralph/artifacts/{s.id}-tests.json") for s in all_stories]
    all_passed = all(a["overall"] == "passed" for a in artifacts)

if all_passed:
    # Aggregate existing results — no prove subagent needed
    proof = {
        "status": "passed",
        "source": "artifact-aggregation",
        "stories": {s.id: {"status": "passed", "testFile": f"{s.id}-tests.json"} for s in all_stories},
        "coverage": index.get("avgCoverage", 0)
    }
    write_json("ralph/.ralph/artifacts/proof-report.json", proof)
    write("ralph/.ralph/artifacts/proof-report.md", format_proof_summary(proof))
    update_state(proofStatus="passed", proofSource="artifact-aggregation")
    print("PROVE: PASS | all story tests passed, aggregated from artifacts")

else:
    # Some stories failed — run full prove subagent
    prove_iter = state.get("proveIterations", 0) + 1
    update_state(proveIterations=prove_iter)
    if prove_iter > 5:
        update_state(status="paused_error")
        display("Prove failed after 5 iterations — user intervention required")
        exit()

    result = Task(
        subagent_type="general-purpose",
        description="Prove all requirements",
        prompt="""
Load ralph/.ralph/stories.json and ralph/.ralph/artifacts-index.json.
Load testTools from ralph/.ralph/architecture.json.

For each story where index shows status != "passed":
- Read ralph/.ralph/artifacts/{story_id}-tests.json for details
- Verify implementation files exist
- Re-run unit tests using testTools.unit scoped to this story
- Check each acceptance criterion from the story brief file

Save ralph/.ralph/artifacts/proof-report.json:
{{"status":"passed|failed","stories":{{"REQ-XXX":{{"status","gaps":[]}}}},"coverage":0,"failedStories":[]}}
Save ralph/.ralph/artifacts/proof-report.md (human-readable summary).

Write full prove log to ralph/.ralph/logs/prove-{prove_iter}.log
All verification details and gap analysis go to the log — NOT returned to the orchestrator.
Return ONE LINE ONLY to the orchestrator: "PROVE: PASS|FAIL | <N>/<total> requirements verified"
"""
    )

    if "FAIL" in result:
        detail = read(f"ralph/.ralph/logs/prove-{prove_iter}.log")
        # Create fix tasks for failing stories, return to Phase 3
```

### Phase 7: Harvest & Pre-Merge Validation

Collect all artifacts and generate harvest summary:
```bash
cat > ralph/.ralph/artifacts/harvest-summary.md << EOF
# Ralph Run Summary - ${RUN_ID}
- Stories: ${COMPLETED}/${TOTAL} complete
- Commits: ${COMMIT_COUNT} (one per story)
- Coverage: ${COVERAGE}%
- All requirements: PROVEN
EOF
```

Run pre-merge checks:
```bash
git status --porcelain          # must be empty
git fetch origin
git merge-base --is-ancestor origin/$ORIGIN_BRANCH HEAD  # no conflicts ahead
jq '[.stories[] | select(.status != "completed")] | length == 0' ralph/.ralph/stories.json  # all complete
```

If any check fails: display reason and halt. User fixes, then retries `/ralph-archive`.

After all checks pass, update state:
- status="ready_for_archive"
- premergeChecks={gitClean:true, mergeBaseSafe:true, allStoriesComplete:true, checkedAt:<current-ISO-timestamp>}
- totalStories=<total story count from stories.json>

Display completion:
```
[Ralph] ✓ All requirements PROVEN
[Ralph] Stories: 8/8 | Coverage: 92% | Branch: ralph/spec-20260223145023
[Ralph] Next step: /ralph-archive
```

Do NOT merge — that happens in `/ralph-archive`.

### Error Handling

On any failure:
1. Log error to `ralph/.ralph/logs/error.log`
2. Update state: status="failed", with error details
3. Display error and options:
   - Fix and resume: `/ralph-resume`
   - Abandon: `/ralph-archive --abandon`

State is always preserved on failure — no work is lost.

### State Persistence

After each phase save:
- `ralph/.ralph/state.json` — current state
- `ralph/.ralph/stories.json` — all stories with status
- `ralph/.ralph/logs/<phase>.log` — full phase execution log
- `ralph/.ralph/artifacts/` — all generated artifacts

State is never committed to git.

## Examples

```bash
/ralph-loop ralph/specs/prds/user-auth.prd.md
```

Creates branch → parses 8 stories (writes brief files) → designs architecture (updates briefs with impl approach) → implements in parallel phases (max 3) → tests each (maintains artifact index) → commits each → proves via index → marks ready for archive.
