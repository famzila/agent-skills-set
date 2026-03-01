# ESLint Flat Config Skeleton — Structural Guide

**Target:** Angular projects with ESLint v9+ flat config
**Purpose:** This is a **pure structural guide**. It defines **WHERE** configurations should be placed. Detailed plugin rules, settings, and parser options **MUST** be retrieved from their respective reference files in the `references/` directory.

---

## The Skeleton (`eslint.config.js`)

```javascript
// @ts-check

// 1. IMPORTS
// ----------------------------------------------------------------------------
const eslint = require('@eslint/js');
const { defineConfig, globalIgnores } = require('eslint/config');
const tseslint = require('typescript-eslint');
const angular = require('angular-eslint');
const globals = require('globals');

// Add plugin requires here as you integrate them:
// - parser-config.md (tsParser)
// - import-x-and-unused-imports.md (importX, createTypeScriptImportResolver, unusedImports)
// - rxjs.md (rxjsX)
// - prettier.md (eslintConfigPrettier, prettierPlugin)

module.exports = defineConfig([
  // ----------------------------------------------------------------------------
  // A. GLOBAL IGNORES
  // ----------------------------------------------------------------------------
  globalIgnores([
    '.angular/**',
    '.nx/**',
    'coverage/**',
    'dist/**',
    'node_modules/**',
  ]),

  // ----------------------------------------------------------------------------
  // B. TYPESCRIPT BLOCK (files: ['**/*.ts'])
  // ----------------------------------------------------------------------------
  {
    files: ['**/*.ts'],
    extends: [
      // 1. Base Angular/TS Configs
      eslint.configs.recommended,
      tseslint.configs.recommended,
      tseslint.configs.stylistic,
      angular.configs.tsRecommended,

      // 2. Plugin Configs (Add incrementally)
      // - See references/rxjs.md for rxjsX.configs.recommended
      // - See references/import-x-and-unused-imports.md for 'import-x/flat/...'
    ],
    processor: angular.processInlineTemplates,

    languageOptions: {
      // - See references/parser-config.md for parser and parserOptions
      globals: {
        ...globals.browser,
        ...globals.node,
      },
    },

    plugins: {
      // - See references/import-x-and-unused-imports.md for 'import-x' and 'unused-imports'
    },

    settings: {
      // - See references/import-x-and-unused-imports.md for 'import-x/resolver-next'
    },

    rules: {
      // 1. Base Angular rules (already included in extends)
      // 2. Custom/Override rules for plugins (See individual reference files)
      // - import-x rules
      // - unused-imports rules
      // - rxjs-x rules
    },
  },

  // ----------------------------------------------------------------------------
  // C. HTML BLOCK (files: ['**/*.html'])
  // ----------------------------------------------------------------------------
  {
    files: ['**/*.html'],
    extends: [
      angular.configs.templateRecommended,
      angular.configs.templateAccessibility,
    ],
    rules: {
      // Add HTML-specific overrides here
    },
  },

  // ----------------------------------------------------------------------------
  // D. PRETTIER INTEGRATION (MUST BE LAST)
  // ----------------------------------------------------------------------------
  // - See references/prettier.md for eslintConfigPrettier and prettierPlugin
]);
```

---

## Scalability Map

To maintain a scalable and clean configuration, follow this mapping when adding new features:

| Integration Area | Anchor Section | Reference File |
| :--- | :--- | :--- |
| **Parsing Logic** | `languageOptions` | `parser-config.md` |
| **Import Rules** | `extends` + `plugins` + `rules` | `import-x-and-unused-imports.md` |
| **RxJS Safety** | `extends` | `rxjs.md` |
| **Formatting** | *End of Array* | `prettier.md` |
| **Custom Plugins** | Match area above | *New Reference File* |

---

## Verification Logic

After adding any block from a reference file to this skeleton:
1. Run `pnpm run lint` to verify syntax.
2. If it fails, check the respective reference file and try to fix the issue.
3. Proceed to the next plugin only after the current one is verified.
