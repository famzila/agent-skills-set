# Validation Testing Reference

Complete test strategy to confirm **all quality tools** are actively working. This step is **REQUIRED**.

> **Package Manager Convention:** Throughout this file, `[pkg-manager]` refers to the package manager confirmed during project setup (pnpm, npm, or yarn). `[exec]` maps to `pnpm exec` / `yarn exec` / `npx`.

---

> **Note:** If RxJS linting is disabled (Step 3.4 was skipped), omit the RxJS-related violations from `test-violations.component.ts` (the `rxjs` imports, `data$` subject, and nested subscribe in `onClick()`) and skip the "ESLint (RxJS-x)" row in the validation checklist below.

## 7.1: Create Test Files

### TypeScript Violations — `src/app/test-violations.component.ts`

```typescript
import { Observable, Subject, of } from "rxjs";
import { Component } from "@angular/core";
import { switchMap } from "rxjs/operators";

// ❌ unused import (unused-imports/no-unused-imports) — of, switchMap
// ❌ wrong import order (import-x/order) — rxjs before @angular

@Component({
  selector: "div",
  // ❌ component-selector: not prefixed with 'app', not kebab-case
  template: `
    <img src="test.png" />
    <!-- ❌ alt-text: missing alt attribute -->

    <div (click)="onClick()">Click me</div>
    <!-- ❌ click-events-have-key-events: missing keyup handler -->
    <!-- ❌ interactive-supports-focus: missing tabindex -->
  `,
})
export class TestViolationsComponent {
  private data$ = new Subject<string>();
  // ❌ prettier: inconsistent spacing

  unusedVar = 42;
  // ❌ unused-imports/no-unused-vars (if not referenced in template)

  onClick() {
    // ❌ rxjs-x/no-nested-subscribe
    this.data$.subscribe(() => {
      this.data$.subscribe(() => {
        console.log("nested");
      });
    });
  }
}
```

### CSS Violations — `src/app/test-violations.css`

```css
.test-class {
  font-family: "Helvetica";
  color: red;
}

.another {
  background: blue;
  font-family: cursive;
}
```

Violations:

- ❌ `font-family-no-missing-generic-family-keyword`: "Helvetica" missing generic fallback
- ❌ `declaration-colon-space-*`: wrong spacing around colons
- ❌ `value-keyword-case`: if applicable
- ❌ Prettier: inconsistent indentation, spacing

---

## 7.2: Verify Detection

Run each tool and confirm violations are detected:

```bash
# ESLint — should detect TS + HTML violations
[pkg-manager] run lint
# Expected: ~8-12 violations (import order, unused imports, accessibility, rxjs, selector, prettier)

# Stylelint — should detect CSS violations
[pkg-manager] run lint:styles
# Expected: ~3-5 violations (missing generic font, spacing)

# Prettier — should detect formatting violations
[pkg-manager] run format
# Expected: at least 2 files fail formatting check
```

> [!IMPORTANT]
> If any tool reports **zero violations**, something is misconfigured. Investigate before proceeding.

---

## 7.3: Verify Auto-Fix

```bash
# ESLint auto-fix — should fix import order, unused imports, formatting
[pkg-manager] run lint:fix

# Stylelint auto-fix — should fix CSS spacing
[pkg-manager] run lint:styles:fix

# Prettier auto-fix — should fix remaining formatting
[pkg-manager] run format:fix
```

After running all auto-fix commands, re-run detection to see what remains:

```bash
[pkg-manager] run lint && [pkg-manager] run lint:styles && [pkg-manager] run format
```

### Expected Remaining (manual fixes needed):

- `@angular-eslint/template/alt-text` — add `alt` attribute to `<img>`
- `@angular-eslint/template/click-events-have-key-events` — add `(keyup.enter)`
- `@angular-eslint/template/interactive-supports-focus` — add `tabindex="0"` or use `<button>`
- `@angular-eslint/component-selector` — rename selector to `app-test-violations`
- `rxjs-x/no-nested-subscribe` — refactor to use `switchMap`

---

## 7.4: Commitlint Validation

**Option A: Pipe validation (DEFAULT — preferred, no git cleanup needed)**

```bash
# ❌ Should REJECT — not conventional commit format
echo "added test stuff" | [pkg-manager] exec commitlint

# ✅ Should ACCEPT — conventional commit format
echo "test: add validation test files" | [pkg-manager] exec commitlint
```

**Option B: Full integration test (tests Husky + lint-staged + commitlint together)**

> [!IMPORTANT]
> If Option B is used, the agent **MUST** immediately run `git reset --soft HEAD~1` after the test, regardless of success or failure. Leaving test commits in git history is not acceptable.

```bash
# ❌ Should REJECT — triggers full Husky pipeline, commitlint rejects message
git add -A && git commit -m "added test stuff"

# ✅ Should ACCEPT — Husky runs lint-staged, commitlint accepts message
git add -A && git commit -m "test: add validation test files"

# MANDATORY — undo the test commit immediately
git reset --soft HEAD~1
```

> [!NOTE]
> Option A is sufficient to verify commitlint rules and is the **preferred** approach. Use Option B only if you also need to confirm the full Husky `commit-msg` hook pipeline end-to-end.

Verify:

- Commitlint rejects non-conventional commit messages
- Commitlint accepts conventional commit messages
- (If Option B) Husky `pre-commit` hook triggers lint-staged

---

## 7.5: Lint-Staged Verification

To specifically test lint-staged in isolation:

```bash
# Stage a file with violations
git add src/app/test-violations.component.ts

# Run lint-staged manually
[exec] lint-staged --verbose
```

Verify that lint-staged runs the configured commands:

- `*.ts` → `eslint --fix`
- `*.css` → `stylelint --fix` + `prettier --write`
- `*.html` → `eslint --fix` + `prettier --write`

---

## 7.6: Final Cleanup

After validation is complete:

```bash
# Delete test files
rm src/app/test-violations.component.ts
rm src/app/test-violations.css

# Undo any test commits
git reset --soft HEAD~1  # if a test commit was made

# Verify we're clean again
[pkg-manager] run lint && [pkg-manager] run lint:styles && [pkg-manager] run format
```

---

## Validation Checklist

| Tool                | Detected Violations? | Auto-Fixed? | Manual Fix Worked? |
| ------------------- | -------------------- | ----------- | ------------------ |
| ESLint (TypeScript) | ☐                    | ☐           | ☐                  |
| ESLint (HTML/a11y)  | ☐                    | N/A         | ☐                  |
| ESLint (RxJS-x)     | ☐                    | N/A         | ☐                  |
| Prettier            | ☐                    | ☐           | N/A                |
| Stylelint           | ☐                    | ☐           | ☐                  |
| Commitlint (reject) | ☐                    | N/A         | N/A                |
| Commitlint (accept) | ☐                    | N/A         | N/A                |
| Lint-staged         | ☐                    | ☐           | N/A                |

**All boxes must be checked before proceeding to Step 8.**
