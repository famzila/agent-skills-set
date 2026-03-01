# Validation Testing Reference

Complete test strategy to confirm **all quality tools** are actively working. This step is **REQUIRED**.

---

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
pnpm run lint
# Expected: ~8-12 violations (import order, unused imports, accessibility, rxjs, selector, prettier)

# Stylelint — should detect CSS violations
pnpm run lint:styles
# Expected: ~3-5 violations (missing generic font, spacing)

# Prettier — should detect formatting violations
pnpm run format
# Expected: at least 2 files fail formatting check
```

> [!IMPORTANT]
> If any tool reports **zero violations**, something is misconfigured. Investigate before proceeding.

---

## 7.3: Verify Auto-Fix

```bash
# ESLint auto-fix — should fix import order, unused imports, formatting
pnpm run lint:fix

# Stylelint auto-fix — should fix CSS spacing
pnpm run lint:styles:fix

# Prettier auto-fix — should fix remaining formatting
pnpm run format:fix
```

After running all auto-fix commands, re-run detection to see what remains:

```bash
pnpm run lint && pnpm run lint:styles && pnpm run format
```

### Expected Remaining (manual fixes needed):

- `@angular-eslint/template/alt-text` — add `alt` attribute to `<img>`
- `@angular-eslint/template/click-events-have-key-events` — add `(keyup.enter)`
- `@angular-eslint/template/interactive-supports-focus` — add `tabindex="0"` or use `<button>`
- `@angular-eslint/component-selector` — rename selector to `app-test-violations`
- `rxjs-x/no-nested-subscribe` — refactor to use `switchMap`

---

## 7.4: Commitlint Validation

**Option A: Pipe validation (preferred — no git cleanup needed)**

```bash
# ❌ Should REJECT — not conventional commit format
echo "added test stuff" | pnpm exec commitlint

# ✅ Should ACCEPT — conventional commit format
echo "test: add validation test files" | pnpm exec commitlint
```

**Option B: Full integration test (tests Husky + lint-staged + commitlint together)**

```bash
# ❌ Should REJECT — triggers full Husky pipeline, commitlint rejects message
git add -A && git commit -m "added test stuff"

# ✅ Should ACCEPT — Husky runs lint-staged, commitlint accepts message
git add -A && git commit -m "test: add validation test files"

# Undo the test commit if Option B was used
git reset --soft HEAD~1
```

> [!NOTE]
> Option A is sufficient to verify commitlint rules. Use Option B if you also want to confirm the Husky `commit-msg` hook fires correctly end-to-end.

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
npx lint-staged --verbose
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
pnpm run lint && pnpm run lint:styles && pnpm run format
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
