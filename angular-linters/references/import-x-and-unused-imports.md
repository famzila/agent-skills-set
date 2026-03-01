# ESLint Import Organization & Unused Imports Reference

**Packages:**
- `eslint-plugin-import-x`
- `eslint-import-resolver-typescript`
- `eslint-plugin-unused-imports`

---

## 1. Import Organization (import-x)

**Plugin:** `eslint-plugin-import-x`  
**Docs:** [https://github.com/un-ts/eslint-plugin-import-x](https://github.com/un-ts/eslint-plugin-import-x)  
**Purpose:** Import organization, circular dependency detection, and TypeScript path resolution

### Flat Config Setup with `defineConfig` (CommonJS)

The official pattern registers `importX` as a plugin and uses `extends` string references for the shared configs:

```javascript
const { importX } = require("eslint-plugin-import-x");
const { createTypeScriptImportResolver } = require("eslint-import-resolver-typescript");

// Inside the configuration object targeting TS files:
{
  files: ["**/*.ts"],
  extends: [
    'import-x/flat/recommended',
    'import-x/flat/typescript',
  ],
  plugins: {
    // @ts-ignore -- known type incompatibility between import-x and ESLint Plugin types
    "import-x": importX,
  },
  settings: {
    // resolver-next is the modern API for Flat Config
    "import-x/resolver-next": [
      createTypeScriptImportResolver({
        alwaysTryTypes: true,
        project: "./tsconfig.json",
      }),
    ],
  },
  rules: {
    // Enforce consistent organization for Angular projects
    "import-x/order": ["error", {
      groups: ["builtin", "external", "internal", ["parent", "sibling"], "index", "type"],
      pathGroups: [
        { pattern: "@angular/**", group: "external", position: "before" },
        { pattern: "@core/**", group: "internal" },
        { pattern: "@shared/**", group: "internal" },
      ],
      alphabetize: { order: "asc", caseInsensitive: true },
      "newlines-between": "always",
    }],
    "import-x/no-cycle": ["error", { maxDepth: 10 }], // Detect circular dependencies
    "import-x/no-duplicates": "error", // Prevent repeated imports from same module
    "import-x/no-named-as-default-member": "off", // Angular-specific exception
  },
}
```

> [!IMPORTANT]
> **`@ts-ignore` is required** when using `// @ts-check`. The `importX` object's `configs` property includes legacy configs with `parser: null`, which conflicts with ESLint's `Plugin` type (`string | undefined`). This is a known type mismatch in the library — safe to suppress.

> [!NOTE]
> **`import-x/flat/typescript`** enables TypeScript-specific import rules. Always include it alongside `import-x/flat/recommended` in Angular/TypeScript projects.

### Critical Rules for Angular

| Rule | Purpose | Severity |
|------|---------|----------|
| `import-x/order` | Enforces consistent import organization | error |
| `import-x/no-cycle` | Detects circular dependencies | error |
| `import-x/no-duplicates` | Prevents duplicate imports | error |
| `import-x/no-dynamic-require` | Warns about dynamic requires | warn |

### TypeScript Resolver

**Required Package:** `eslint-import-resolver-typescript`

Enables:
- Path alias resolution (`@core`, `@shared`)
- TypeScript project references
- Automatic type imports detection

---

## 2. Smart Unused Imports (unused-imports)

**Plugin:** `eslint-plugin-unused-imports`  
**Docs:** [https://github.com/sweepline/eslint-plugin-unused-imports](https://github.com/sweepline/eslint-plugin-unused-imports)  
**Purpose:** Finds and removes unused ES6 module imports specifically. It separates the logic for unused imports (which should be auto-removed) from unused variables (which might be intentional if prefixed with `_`).

### Flat Config Setup (CommonJS)

This plugin must be added to the plugins section of the TypeScript configuration object within `defineConfig`:

```javascript
const unusedImports = require("eslint-plugin-unused-imports");

// Inside the configuration object targeting TS files:
{
  files: ["**/*.ts"],
  plugins: {
    "unused-imports": unusedImports,
  },
  rules: {
    // CRITICAL: Disable core rules to let the plugin handle reporting
    "no-unused-vars": "off",
    "@typescript-eslint/no-unused-vars": "off",

    // Rule for Imports: Automatically removes unused module imports on --fix
    "unused-imports/no-unused-imports": "error",

    // Rule for Variables: Allows unused vars/args if they match the ignore pattern
    "unused-imports/no-unused-vars": [
      "warn",
      {
        "vars": "all",
        "varsIgnorePattern": "^_",
        "args": "after-used",
        "argsIgnorePattern": "^_",
      },
    ],
  },
}
```

---

## Integration Guidelines

- **Location**: Both plugins should be configured within the TypeScript-specific object (targeting `**/*.ts`) in the `defineConfig` array.
- **Extends**: Use `extends: ['import-x/flat/recommended', 'import-x/flat/typescript']` string references with `defineConfig` (official pattern from [import-x docs](https://github.com/un-ts/eslint-plugin-import-x#using-defineconfig)).
- **Resolution**: Always use `import-x/resolver-next` with `createTypeScriptImportResolver` so import-x can resolve Angular path aliases defined in `tsconfig.json`.
- **Prettier**: These rules should appear before the Prettier finalizer in the `defineConfig` array to ensure Prettier has the final say on any formatting changes.
- **Type Safety**: When using `// @ts-check`, add `// @ts-ignore` above the `'import-x': importX` plugin registration line.