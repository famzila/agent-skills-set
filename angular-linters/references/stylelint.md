# Stylelint Configuration Reference

**Packages:**
- `stylelint` — Core CSS linter
- `stylelint-config-standard` — Standard shared config for CSS
- `stylelint-config-standard-scss` — Standard shared config for SCSS (only needed for SCSS projects)

**Docs:**
- https://stylelint.io/user-guide/get-started
- https://github.com/stylelint-scss/stylelint-config-standard-scss

**Purpose:** CSS/SCSS linting for consistent, error-free stylesheets.

> [!NOTE]
> **Prettier compatibility packages are NOT needed** with Stylelint v15+. Stylelint v15 deprecated formatting rules, and v16+ removed them entirely. Do NOT install `stylelint-config-prettier` or `stylelint-config-prettier-scss`.

---

## CSS Projects (Default)

**File:** `stylelint.config.mjs`

```javascript
/** @type {import('stylelint').Config} */
export default {
  extends: ['stylelint-config-standard'],
  rules: {
    'selector-class-pattern': null,
    'no-empty-source': null,
  },
};
```

**Packages:** `stylelint`, `stylelint-config-standard`

**Rules:**
- `selector-class-pattern: null` — Allows Angular's kebab-case component selectors
- `no-empty-source: null` — Angular generates empty component CSS files by default

---

## SCSS Projects (Optional)

If the project uses SCSS (`--style scss`), extend `stylelint-config-standard-scss` instead:

**File:** `stylelint.config.mjs`

```javascript
/** @type {import('stylelint').Config} */
export default {
  extends: ['stylelint-config-standard-scss'],
  rules: {
    'selector-class-pattern': null,
    'no-empty-source': null,
  },
};
```

**Packages:** `stylelint`, `stylelint-config-standard-scss`

> [!NOTE]
> `stylelint-config-standard-scss` includes the SCSS syntax parser and SCSS-specific rules automatically. No need to install them separately.

---

## Angular-Specific Rules (Optional)

Add these rules if using Tailwind CSS:

```javascript
rules: {
  'selector-class-pattern': null,
  'no-empty-source': null,
  'at-rule-no-unknown': [
    true,
    {
      ignoreAtRules: ['theme', 'apply', 'layer'],
    },
  ],
}
```

---

## Ignore File

**File:** `.stylelintignore`

```
/.angular
/.nx
/coverage
/dist
node_modules
```

---

## NPM Scripts

Adjust globs to match project style format:

```json
{
  "scripts": {
    "lint:styles": "stylelint \"src/**/*.css\"",
    "lint:styles:fix": "stylelint \"src/**/*.css\" --fix"
  }
}
```

For SCSS projects, use `*.scss` or `*.{css,scss}`.

---

## Lint-Staged Integration

```json
{
  "*.css": ["stylelint --fix", "prettier --write"]
}
```

For SCSS: `"*.{css,scss}"`.
