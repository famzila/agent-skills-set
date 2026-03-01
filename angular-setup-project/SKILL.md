---
name: angular-setup-project
description: Generic workflow for bootstrapping a production-ready Angular project with modern defaults (pnpm, latest Angular, default test runner) and modular feature selection.
---

# Angular Setup Project Skill

This skill provides a standardized workflow for bootstrapping a production-ready Angular setup application with modern defaults and modular feature selection.

## Prerequisites Check

Before beginning setup, verify the availability of critical dependencies:

**System Requirements:**

- **Node.js** → Active LTS version (v18+ recommended)
- **Angular CLI** → Latest version (`npm install -g @angular/cli`)
- **Package Manager** → pnpm (recommended) or npm or yarn

**Critical (Quality Foundation):**

- `angular-linters` skill → Required for ESLint, Stylelint, Husky, and Commitlint setup

**Action:** Validate system requirements:

1. Check Node.js: `node --version` (should be v18+)
2. Check Angular CLI: `ng version` (install if missing)
3. Check pnpm: `pnpm --version` (optional, will fall back to npm or yarn)

**Action: Safety Check (EXISTING PROJECT)**:

1.  **Verify**: Before running `ng new`, check if `angular.json` already exists in the current directory or parent directories.
2.  **Stop**: If an existing Angular project is detected, **ABORT**. Inform the user: _"An existing Angular project was detected in this directory. This skill only supports bootstrapping new projects."_

**Action: If critical skills are missing:**

1. Inform the user: _"The `angular-linters` skill is missing. This skill is required for setting up code quality tools."_
2. Offer alternatives:
   - Provide the skill file if available
   - Continue with manual linter setup (less reliable)

**Failure Recovery:**

> **Critical:** If the creation or scaffolding phase fails, the Agent **MUST** delete the generated project directory before attempting validation or retrying. Do not attempt to "repair" a failed `ng new` execution.

---

## Workflow: Interactive Discovery

> **CRITICAL:** You **MUST NOT** assume preferences from previous conversations or context. **ALWAYS** present the defaults below and ask for explicit confirmation before running `ng new`. Even if the user seems to want the same setup as before, ask.

1.  **Discovery**: Ask: "What foundational Angular features would you like to configure (e.g., SSR, Routing, Zoneless, CSS/SCSS)?"
2.  **Present Defaults**: Show the foundational defaults and ask for confirmation or changes:
    - **Package Manager**: `pnpm` (default), `npm`, or `yarn`
    - **Styles**: `css` (default) or `scss`
    - **SSR**: `disabled`
    - **Routing**: `enabled`
    - **Zoneless**: `enabled` (Angular 21 default — no flag needed) → Ask: "Would you like to disable zoneless and enable zone.js (legacy mode)?"
    - **Environment files**: `optional`
3.  **Core Focus**: Do NOT suggest advanced features like Tailwind CSS, Spartan UI, or SignalStore in this phase.
4.  **Quality Layer**: The quality stack (ESLint, Stylelint, Prettier, Husky, Commitlint) is **MANDATORY** and always included. Do NOT list it as an optional integration or ask the user whether they want it.

---

## Technical Phases

### Phase 1: Interactive Discovery & Creation

1.  **Mandatory Discovery Dialogue**: Before running `ng new`, present the defaults and ask for confirmation:
    - **Package Manager**: `pnpm` (or `npm`, `yarn`)
    - **Styling**: `css` (or `scss`)
    - **SSR**: `disabled` (or `enabled`)
    - **Routing**: `enabled`
    - **Zoneless**: `enabled` (Angular 21 default — no flag needed)
    - **Git**: `enabled` (Required for Husky)
    - **Environment files**: `optional`
2.  **Creation**: Once confirmed, execute the command. Angular 21 is zoneless by default — do **NOT** pass `--zoneless` unless opting out.
    - **Standard (Zoneless)**: `ng new [project-name] --package-manager [pnpm|npm|yarn] --style [style] --ssr [ssr-bool] --defaults`
    - **Legacy (Zone.js)**: `ng new [project-name] --package-manager [pnpm|npm|yarn] --style [style] --ssr [ssr-bool] --zoneless false --defaults`
3.  **Structural Scaffolding**: Run `scripts/scaffold_structure.sh` to create the `core/`, `shared/`, and `features/` hierarchy.
4.  **Environment files** (if requested): Run `ng generate environments` to generate the environment files.

### Phase 1.5: Production-Ready Setup Configuration

These configuration changes **cannot be scripted** because they modify complex JSON structures that require intelligent merging. The Agent handles them directly.

1. **TSConfig Path Aliases**: Add path aliases to `tsconfig.json` for clean imports:
   > **CAUTION:** Paths **must** use a leading `./` (relative) prefix. Without `baseUrl` set, TypeScript and Angular's esbuild builder will throw `TS5090: Non-relative paths are not allowed when 'baseUrl' is not set`.
   ```json
   {
     "compilerOptions": {
       "paths": {
         "@core/*": ["./src/app/core/*"],
         "@shared/*": ["./src/app/shared/*"],
         "@features/*": ["./src/app/features/*"]
       }
     }
   }
   ```
2. **Angular Budget Tuning**: Update `angular.json` budgets to real-world production project potential limits. Angular CLI's defaults (`500kB` warning, `1MB` error) are quickly exceeded by real projects with third-party libraries, component libraries, or i18n. Start permissive and tighten incrementally as you optimize:
   ```json
   {
     "budgets": [
       { "type": "initial", "maximumWarning": "2MB", "maximumError": "4MB" },
       {
         "type": "anyComponentStyle",
         "maximumWarning": "10kB",
         "maximumError": "20kB"
       }
     ]
   }
   ```
3. **EditorConfig Alignment**: Verify `.editorconfig` aligns with Prettier defaults. Confirm:
   - `indent_style = space` and `indent_size = 2`
   - `insert_final_newline = true`
   - `charset = utf-8`
4. **README**: Replace the boilerplate README.md with a project-specific template:
   - Project name and description placeholder
   - Available NPM scripts table (`start`, `build`, `test`, `lint`, `lint:styles`, `format`)
   - Quality tools summary (ESLint, Stylelint, Prettier, Husky, Commitlint)
   - Conventional Commit format reference
   - License placeholder

### Phase 1.5 Verification

- Run `ng serve` and verify the application compiles and serves without errors or warnings.
- If warnings appear (e.g., path alias errors like `TS5090`), fix before proceeding to Phase 2.

### Phase 2: Autonomous Quality Layer (MANDATORY)

> **This phase is NOT optional.** Quality tooling is always set up regardless of user preferences.

Invoke the **`angular-linters`** skill to set up the complete quality stack (ESLint, Stylelint, Prettier, Husky, Commitlint).

The `angular-linters` skill will:

1. Run `scripts/configure_linters.sh --style [css|scss] --package-manager [pnpm|npm|yarn]` for automated installation. Pass the `--style` and `--package-manager` values confirmed in Phase 1 so the correct Stylelint variant is installed with the correct package manager.
2. Verify all generated configuration files exist.
3. Incrementally add and verify ESLint plugins (Prettier → import-x/unused-imports → RxJS).
4. Validate Stylelint configuration.
5. Test Git hooks (Husky + Commitlint).
6. Perform final verification and cleanup.

**Critical**: Each configuration step in `angular-linters` must pass linting before proceeding to the next step.

## Resources

- **scripts/scaffold_structure.sh**: Deterministic folder hierarchy generator.
- Phase 1.5 tasks (path aliases, budgets, editorconfig) are handled by the Agent, not scripts, because they require intelligent JSON merging.
