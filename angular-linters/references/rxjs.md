# ESLint RxJS Reference

**Package:** `eslint-plugin-rxjs-x`  
**Docs:** [https://github.com/JasonWeinzierl/eslint-plugin-rxjs-x](https://github.com/JasonWeinzierl/eslint-plugin-rxjs-x)  
**Purpose:** Modern ESLint rules for RxJS — core correctness, memory leak prevention, and common pitfalls. Native ESLint v9 flat config support.

> [!WARNING]
> `eslint-plugin-rxjs-x@1.x` declares `eslint@^10.0.0` as a peer dependency, but current Angular CLI ships with ESLint 9.x. This produces a peer dependency warning during installation — **it is safe to ignore.** The plugin works correctly with ESLint 9.

---

## Parser Requirements

This plugin requires type-aware linting. Configure:

- `parserOptions.projectService: true` (recommended, modern typescript-eslint API)
- OR `parserOptions.project` pointing to your tsconfig

Angular projects from `ng add @angular-eslint/schematics` typically already have the TypeScript parser. If you see "You have attempted to use a lint rule which requires the full TypeScript type-checker" errors, ensure `parserOptions.projectService` or `parserOptions.project` is set in your TypeScript block.

---

## Flat Config Setup (CommonJS)

Add within the TypeScript configuration object in your `defineConfig` array, using the **shared config** approach:

```javascript
// ⚠️  eslint-plugin-rxjs-x uses __esModule with a `default` export.
// In CommonJS (require), you MUST use .default to access configs and rules.
const rxjsX = require('eslint-plugin-rxjs-x').default;

// Inside the TypeScript config object (files: ["**/*.ts"]):
{
  files: ['**/*.ts'],
  extends: [
    // ... other configs (eslint, tseslint, angular)
    rxjsX.configs.recommended,
  ],
  languageOptions: {
    parserOptions: {
      projectService: true,
      tsconfigRootDir: __dirname,
    },
  },
}
```

### Shared Configs

| Config                      | Description                                                    |
| --------------------------- | -------------------------------------------------------------- |
| `rxjsX.configs.recommended` | Core correctness + safety rules (recommended for all projects) |
| `rxjsX.configs.strict`      | All recommended + additional strict rules                      |

---

## Rules Reference

### Recommended (Core Correctness)

| Rule                             | Description                                                                               |
| -------------------------------- | ----------------------------------------------------------------------------------------- |
| `rxjs-x/no-async-subscribe`      | Forbids passing async functions to subscribe                                              |
| `rxjs-x/no-floating-observables` | Forbids ignoring observables returned by functions (replaces old `no-ignored-observable`) |
| `rxjs-x/no-ignored-subscription` | Forbids ignoring the subscription returned by subscribe                                   |
| `rxjs-x/no-nested-subscribe`     | Forbids calling subscribe within a subscribe callback                                     |
| `rxjs-x/no-unbound-methods`      | Forbids passing unbound methods to operators                                              |
| `rxjs-x/throw-error`             | Enforces passing Error values to error notifications                                      |

### Safety (Memory Leaks & Pitfalls)

| Rule                            | Description                                          |
| ------------------------------- | ---------------------------------------------------- |
| `rxjs-x/no-unsafe-takeuntil`    | Forbids the application of operators after takeUntil |
| `rxjs-x/no-unsafe-subject-next` | Forbids unsafe optional next calls on Subjects       |

### Optional (Stylistic)

| Rule                     | Description                                    |
| ------------------------ | ---------------------------------------------- |
| `rxjs-x/finnish`         | Enforces Finnish notation (e.g. `observable$`) |
| `rxjs-x/no-finnish`      | Forbids Finnish notation                       |
| `rxjs-x/suffix-subjects` | Enforces Subject suffix naming                 |

---

## Integration Guidelines

- **Location:** Add `rxjsX.configs.recommended` in the TypeScript block's `extends` array
- **Order:** Place before the Prettier finalizer in the `defineConfig` array
- **Parser:** Ensure `parserOptions.projectService: true` (or `parserOptions.project`) for type-aware rules
