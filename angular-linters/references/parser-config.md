# ESLint Parser Configuration Reference

**Purpose:** Troubleshoot type-aware linting issues with `@typescript-eslint` and Angular.

---

## Recommended: `projectService` (typescript-eslint v8+)

Use `projectService: true` for automatic TSConfig discovery — no need to specify individual tsconfig files:

```javascript
{
  files: ['**/*.ts'],
  languageOptions: {
    parser: require('@typescript-eslint/parser'),
    parserOptions: {
      projectService: true,
      tsconfigRootDir: __dirname,
      sourceType: 'module',
    },
  },
}
```

> [!TIP]
> `projectService: true` replaces the old `project: ['./tsconfig.app.json', './tsconfig.spec.json']` approach. It automatically discovers the correct tsconfig for each file.

---

## Common Errors & Fixes

### "Parsing error: Cannot read file tsconfig.json"
**Cause:** `tsconfigRootDir` is missing or incorrect.

**Fix:**
```javascript
parserOptions: {
  projectService: true,
  tsconfigRootDir: __dirname,  // CommonJS
  // tsconfigRootDir: import.meta.dirname,  // ESM
},
```

### "You have used a rule which requires type-checking"
**Cause:** Parser not configured for type-aware linting.

**Fix:** Ensure `projectService: true` (or `project`) is set in the TypeScript block's `parserOptions`.

### Config files not in tsconfig (e.g., `eslint.config.js`)
**Cause:** Config files at root aren't included in `tsconfig.app.json`.

**Fix:**
```javascript
parserOptions: {
  projectService: {
    allowDefaultProject: ['*.config.js', '*.config.cjs'],
  },
  tsconfigRootDir: __dirname,
},
```

---

## Quick Reference

| Option | Value | When to Use |
|--------|-------|-------------|
| `projectService: true` | Auto-discover | **Default for Angular** |
| `project: ['./tsconfig.app.json']` | Explicit paths | Legacy or specific needs |
| `allowDefaultProject` | Config files | Root config files outside tsconfig |
| `tsconfigRootDir: __dirname` | CJS projects | **Always set** |

---

## Related
- [rxjs.md](./rxjs.md) — `eslint-plugin-rxjs-x` requires type-aware parser
- [import-x-and-unused-imports.md](./import-x-and-unused-imports.md) — path resolution uses `import-x/resolver-next`
