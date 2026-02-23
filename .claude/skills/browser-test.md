# Browser Test - UI Testing Harness Skill

Launch browser-based testing for UI components and workflows with visual validation.

## Usage

```
/browser-test [component-path] [--interactive] [--visual-regression] [--a11y]
```

## Instructions

When this skill is invoked:

1. **Setup Test Environment**
   - Detect if Playwright is installed (prefer) or Puppeteer/Selenium
   - If not installed, offer to install: `npm install -D @playwright/test`
   - Initialize browser testing configuration if needed
   - Set up test fixtures and helpers

2. **Identify Test Targets**
   - If component-path provided, test that specific component/page
   - Otherwise, scan for UI components needing tests
   - Look for related requirements in specs (UI-REQ-XXX)
   - Find existing browser tests or create new ones

3. **Test Categories**

   **Functional Tests**
   - User interactions (clicks, typing, navigation)
   - Form submissions and validations
   - Dynamic content loading
   - State changes and updates

   **Visual Tests** (--visual-regression)
   - Screenshot comparison
   - Layout consistency
   - Responsive design breakpoints
   - Cross-browser rendering

   **Accessibility Tests** (--a11y)
   - ARIA attributes
   - Keyboard navigation
   - Screen reader compatibility
   - Color contrast
   - Focus management

4. **Generate Test Code**
   - Create Playwright test file if it doesn't exist
   - Structure: `tests/browser/test_<component>.spec.js`
   - Include:
     - Setup and teardown
     - Navigation to component
     - Interaction tests
     - Assertion validations
     - Screenshot captures

5. **Execute Tests**
   - Run browser tests in headless mode (default)
   - If --interactive flag, run in headed mode for debugging
   - Capture:
     - Test results (pass/fail)
     - Screenshots on failure
     - Console errors
     - Network requests
     - Performance metrics (LCP, FID, CLS)

6. **Visual Regression** (if enabled)
   - Take screenshots of component in various states
   - Compare against baseline images
   - Highlight visual differences
   - Store baselines in `tests/browser/screenshots/baseline/`
   - Store comparison results in `feedback/visual-regression/`

7. **Accessibility Audit**
   - Run axe-core or Lighthouse accessibility tests
   - Check WCAG 2.1 compliance
   - Identify violations with severity levels
   - Generate accessibility report

8. **Generate Report**
   - Create comprehensive test report
   - Include:
     - Test execution summary
     - Screenshots (baseline, actual, diff)
     - Accessibility violations
     - Performance metrics
     - Console errors/warnings
     - Network issues
   - Save to `feedback/<spec-id>/browser-tests/`

9. **Interactive Mode** (--interactive)
   - Launch browser with Playwright Inspector
   - Allow user to manually test and explore
   - Record interactions for test generation
   - Provide debugging console

10. **Update Tasks and Feedback**
    - Update related tasks based on test results
    - Create new tasks for visual regressions or a11y issues
    - Add test coverage information to task descriptions

## Test Template Generation

If no tests exist, generate from this template:

```javascript
const { test, expect } = require('@playwright/test');

test.describe('ComponentName', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('http://localhost:3000/component-path');
  });

  test('REQ-XXX: requirement description', async ({ page }) => {
    // Arrange

    // Act
    await page.click('button[data-testid="submit"]');

    // Assert
    await expect(page.locator('.result')).toBeVisible();
  });

  test('visual regression', async ({ page }) => {
    await expect(page).toHaveScreenshot('component-name.png');
  });

  test('accessibility', async ({ page }) => {
    const accessibilityScanResults = await new AxeBuilder({ page })
      .analyze();
    expect(accessibilityScanResults.violations).toEqual([]);
  });
});
```

## Output Format

```
[Browser Test] Launching browser test harness
[Browser Test] Target: src/components/LoginForm.tsx
[Browser Test] Mode: headless
[Browser Test]
[Browser Test] Running functional tests...
[Browser Test] ✓ User can enter email and password
[Browser Test] ✓ Form submits on Enter key
[Browser Test] ✓ Error displays for invalid credentials
[Browser Test]
[Browser Test] Running visual regression tests...
[Browser Test] ✓ Login form baseline matches
[Browser Test] ✗ Error state has visual differences (2.3% diff)
[Browser Test]   - Screenshot saved: feedback/visual-regression/error-state-diff.png
[Browser Test]
[Browser Test] Running accessibility tests...
[Browser Test] ✗ 3 accessibility violations found:
[Browser Test]   - Critical: Form input missing label (WCAG 1.3.1)
[Browser Test]   - Serious: Insufficient color contrast (WCAG 1.4.3)
[Browser Test]   - Moderate: Missing landmark regions (WCAG 1.3.1)
[Browser Test]
[Browser Test] Results: 5/7 tests passed (71.4%)
[Browser Test] Report: feedback/login-form/browser-test-20260223.html
[Browser Test]
[Browser Test] Create tasks for accessibility fixes? (y/n)
```

## Project Detection

Auto-detect UI framework and adjust tests:
- **React**: Use data-testid attributes
- **Vue**: Use test-id or ref attributes
- **Svelte**: Use data-testid attributes
- **Angular**: Use data-testid or id attributes
- **HTML/Vanilla**: Use semantic selectors

## Examples

### Test specific component
```
/browser-test src/components/LoginForm.tsx
```

### Interactive debugging mode
```
/browser-test src/components/Dashboard.tsx --interactive
```

### Full test suite with visual regression
```
/browser-test --visual-regression --a11y
```

## Dependencies

This skill will install if needed:
- `@playwright/test`
- `axe-core` (for accessibility)
- `pixelmatch` (for visual diffing)

## Integration Points

- Integrates with `/test-spec` for UI requirements
- Generates feedback for Ralph Loop
- Can be triggered automatically for UI-related tasks
- Supports CI/CD pipeline integration
