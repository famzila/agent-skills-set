# ESLint Prettier Integration Reference

**Packages:**

- `eslint-config-prettier` — Disables ESLint formatting rules that conflict with Prettier
- `eslint-plugin-prettier` — Runs Prettier as an ESLint rule (so `ng lint --fix` also formats)

**Docs:** https://github.com/prettier/eslint-config-prettier  
**Purpose:** Prettier handles formatting, while ESLint handles code quality. This integration ensures they do not "fight" by turning off all ESLint rules that are unnecessary or might conflict with Prettier.

> [!IMPORTANT]
> **Both packages are required.** `eslint-config-prettier` disables conflicts; `eslint-plugin-prettier/recommended` runs Prettier inside ESLint. Both must be the **last entries** in the `defineConfig` array.

---

## Flat Config Setup (CommonJS)

Both packages must be the **last entries** in the `defineConfig` array:

```javascript
const eslintConfigPrettier = require("eslint-config-prettier");
const prettierPlugin = require("eslint-plugin-prettier/recommended");

module.exports = defineConfig([
  // ... other configuration objects (Angular, TypeScript, etc.)

  // MUST be the last two items
  eslintConfigPrettier, // Disables conflicting rules
  prettierPlugin, // Runs Prettier as ESLint rule
]);
```

### What this Configuration Does:

1. Enables the prettier/prettier rule: Reports formatting issues as ESLint errors.
2. Disables Conflicting Rules: Automatically turns off stylistic rules from core ESLint, @typescript-eslint, and various other plugins.
3. Fixes Problematic Rules: Specifically handles rules like arrow-body-style and prefer-arrow-callback which can cause issues when using lint fix alongside Prettier.

---

## Companion Tool: Prettier Config

Angular v21+ auto-generates a `"prettier"` key in `package.json`. **Do not create a `.prettierrc` file.**

> [!IMPORTANT]
> Angular 21 now auto-generates the `"prettier"` key **including** the `"parser": "angular"` override for `*.html` files. **Verify the auto-generated config already contains the `overrides` block before adding it manually.** Only add it if it is missing.

**Expected auto-generated config in `package.json`** (verify, do not blindly overwrite):

```json
{
  "prettier": {
    "overrides": [
      {
        "files": "*.html",
        "options": {
          "parser": "angular"
        }
      }
    ]
  }
}
```

> [!NOTE]
> Angular CLI auto-generates the base Prettier config (e.g., `printWidth: 100`, `singleQuote: true`). **Do not override these values** unless your team has an explicit standard. Only add the `overrides` array with the Angular HTML parser if it is not already present.

---

**File:** `.prettierignore`

Create a `.prettierignore` file at the project root to exclude files and directories from Prettier:

```
/.angular
/.nx
/.vscode
/.agent
/coverage
/dist
node_modules
```

---

### Validation & Special Rules

CLI Helper Tool
To verify that no manual rule overrides in your config are still conflicting with Prettier,

- Run the CLI helper tool:
  `npx eslint-config-prettier path/to/main.ts`
  Replace path/to/main.ts with an actual file in the project. The tool will report if any enabled rules conflict with Prettier.
