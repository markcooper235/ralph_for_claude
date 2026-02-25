---
name: feedback-selector
description: Analyze project structure and requirements to determine the optimal testing and feedback strategy. Recommends tools, configures thresholds, and sets up test infrastructure based on project type (frontend, backend, API, library, CLI, etc.).
argument-hint: "[--analyze-only] [--recommend] [--setup]"
disable-model-invocation: true
---

# Feedback Selector - Intelligent Feedback Method Selection

Analyze project structure and requirements to determine optimal feedback mechanisms.

## Usage

```
/feedback-selector [--analyze-only] [--recommend] [--setup]
```

## Instructions

When this skill is invoked:

1. **Analyze Project Structure**
   - Scan directory structure and file types
   - Identify programming languages
   - Detect frameworks and libraries
   - Examine dependencies (package.json, requirements.txt, Cargo.toml, etc.)
   - Review existing test infrastructure

2. **Classify Project Type**

   Determine primary project category:
   - **Web Application (Frontend)**: React, Vue, Svelte, Angular, HTML/CSS/JS
   - **Web Application (Backend)**: Express, Flask, Django, FastAPI, Rails
   - **API/Service**: REST, GraphQL, gRPC services
   - **Library/SDK**: Reusable code packages
   - **CLI Tool**: Command-line applications
   - **Mobile App**: React Native, Flutter, native iOS/Android
   - **Desktop App**: Electron, Tauri, native apps
   - **Data Pipeline**: ETL, data processing
   - **Machine Learning**: Model training, inference services

3. **Analyze Requirements**
   - Load active specification
   - Categorize requirements by type:
     - Functional (business logic)
     - UI/UX (visual, interaction)
     - Performance (speed, resource usage)
     - Security (auth, encryption, validation)
     - Accessibility (a11y compliance)
     - Integration (external services)
   - Identify success metrics and acceptance criteria

4. **Select Feedback Methods**

   Based on project type and requirements, recommend:

   **Web Application (Frontend)**
   - Browser testing (Playwright) for user flows
   - Visual regression testing for UI consistency
   - Accessibility testing (axe-core) for a11y requirements
   - Lighthouse for performance metrics
   - Jest/Vitest for component unit tests

   **Web Application (Backend)**
   - Integration tests for API endpoints
   - Unit tests for business logic
   - Load testing (k6, Artillery) for performance
   - Security scanning (OWASP ZAP) for security requirements

   **API/Service**
   - Contract testing (Pact) for API compatibility
   - Integration tests for endpoint behavior
   - Load testing for performance requirements
   - API documentation validation (Swagger/OpenAPI)

   **Library/SDK**
   - Unit tests with high coverage (95%+)
   - Type checking (TypeScript, mypy, etc.)
   - Example code execution tests
   - API surface validation (detect breaking changes)
   - Documentation generation and validation

   **CLI Tool**
   - Command execution tests
   - Output validation (stdout/stderr)
   - Error handling tests
   - Help text validation
   - Cross-platform testing

   **Mobile App**
   - Detox/Appium for E2E tests
   - Unit tests for logic
   - Visual regression for screens
   - Performance profiling (React Native Profiler)

   **Data Pipeline**
   - Data quality tests (Great Expectations)
   - Schema validation
   - End-to-end pipeline tests
   - Performance benchmarks

5. **Generate Feedback Configuration**
   - Create config file in `.claude/feedback-configs/`
   - Specify:
     - Feedback methods to use
     - Frequency (per-commit, per-requirement, per-loop)
     - Success thresholds
     - Required tools and setup commands
     - Integration points

6. **Setup Recommendation**
   - List tools that need to be installed
   - Provide installation commands
   - Generate test configuration files
   - Create sample test templates
   - Set up CI/CD integration if applicable

7. **Provide Usage Instructions**
   - Explain how each feedback method works
   - Show command examples
   - Describe when each method should be used
   - Explain how results feed back into Ralph Loop

## Selection Matrix

```
Project Type         | Feedback Methods (Priority Order)
---------------------|---------------------------------------
Frontend Web         | Browser Test > Visual Regression > Unit Test > A11y Test
Backend Web          | Integration Test > Unit Test > Load Test > Security Scan
API/Service          | Contract Test > Integration Test > Load Test > Doc Validation
Library/SDK          | Unit Test > Type Check > Example Test > API Validation
CLI Tool             | Command Test > Output Validation > Cross-Platform Test
Mobile App           | E2E Test > Unit Test > Visual Regression > Performance
Data Pipeline        | Data Quality Test > Schema Validation > E2E Pipeline Test
ML Service           | Model Test > Integration Test > Performance Test > Drift Detection
```

## Output Format

```
[Feedback Selector] Analyzing project structure...
[Feedback Selector]
[Feedback Selector] Project Analysis:
[Feedback Selector] - Type: Web Application (Frontend)
[Feedback Selector] - Primary Language: TypeScript
[Feedback Selector] - Framework: React 18.2
[Feedback Selector] - Build Tool: Vite
[Feedback Selector] - Test Framework: Vitest (detected)
[Feedback Selector]
[Feedback Selector] Requirements Analysis:
[Feedback Selector] - 8 UI/UX requirements → Need browser testing
[Feedback Selector] - 3 accessibility requirements → Need a11y testing
[Feedback Selector] - 2 performance requirements → Need Lighthouse metrics
[Feedback Selector] - 5 functional requirements → Need unit tests
[Feedback Selector]
[Feedback Selector] Recommended Feedback Methods:
[Feedback Selector]
[Feedback Selector] 1. Browser Testing (Playwright) - HIGH PRIORITY
[Feedback Selector]    - Covers: UI/UX requirements, user interaction flows
[Feedback Selector]    - Setup: npm install -D @playwright/test
[Feedback Selector]    - Usage: /browser-test [component]
[Feedback Selector]
[Feedback Selector] 2. Accessibility Testing (axe-core) - HIGH PRIORITY
[Feedback Selector]    - Covers: A11y requirements, WCAG compliance
[Feedback Selector]    - Setup: npm install -D axe-core
[Feedback Selector]    - Usage: /browser-test --a11y
[Feedback Selector]
[Feedback Selector] 3. Visual Regression (Percy/BackstopJS) - MEDIUM PRIORITY
[Feedback Selector]    - Covers: UI consistency, design specs
[Feedback Selector]    - Setup: npm install -D @percy/cli
[Feedback Selector]    - Usage: /browser-test --visual-regression
[Feedback Selector]
[Feedback Selector] 4. Component Unit Tests (Vitest) - MEDIUM PRIORITY
[Feedback Selector]    - Covers: Component logic, edge cases
[Feedback Selector]    - Setup: Already configured ✓
[Feedback Selector]    - Usage: /test-spec REQ-XXX
[Feedback Selector]
[Feedback Selector] 5. Performance Testing (Lighthouse) - LOW PRIORITY
[Feedback Selector]    - Covers: Performance requirements
[Feedback Selector]    - Setup: npm install -D @playwright/test lighthouse
[Feedback Selector]    - Usage: Run as part of browser tests
[Feedback Selector]
[Feedback Selector] Configuration saved: .claude/feedback-configs/feedback-config.json
[Feedback Selector]
[Feedback Selector] Setup all recommended tools? (y/n)
```

## Configuration File Format

Generated as `.claude/feedback-configs/feedback-config.json`:

```json
{
  "projectType": "frontend-web",
  "primaryLanguage": "typescript",
  "framework": "react",
  "feedbackMethods": [
    {
      "method": "browser-test",
      "priority": "high",
      "frequency": "per-requirement",
      "tool": "playwright",
      "command": "npx playwright test {testFile}",
      "coverageTypes": ["functional", "visual", "accessibility"],
      "thresholds": {
        "passRate": 100,
        "a11yViolations": 0
      }
    },
    {
      "method": "unit-test",
      "priority": "medium",
      "frequency": "per-commit",
      "tool": "vitest",
      "command": "npx vitest run {testPattern}",
      "coverageTypes": ["functional"],
      "thresholds": {
        "coverage": 80,
        "passRate": 100
      }
    }
  ],
  "integrations": {
    "ralph-loop": true,
    "ci-cd": "github-actions",
    "coverage-report": "codecov"
  }
}
```

## Examples

### Analyze and recommend
```
/feedback-selector
```

### Analyze without setup
```
/feedback-selector --analyze-only
```

### Auto-setup recommended tools
```
/feedback-selector --setup
```

## Integration Points

- Used by `/ralph-loop` during architecture phase
- Configures `/test-spec` execution strategy
- Determines when to use `/browser-test`
- Generates CI/CD pipeline configurations
- Updates task metadata with feedback requirements
