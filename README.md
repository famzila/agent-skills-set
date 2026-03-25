# agent-skills-set

A collection of AI-driven development skills designed to elevate Angular "vibe coding" to production-ready standards. This repository provides standardized, automated workflows for bootstrapping, linting, and documenting modern applications.

## 🚀 Key Skills

### 🛠️ [Angular Setup Project](./angular-setup-project)

The foundation for every new project. It automates the creation of a production-ready setup for an Angular application with modern defaults.

- **Version-Adaptive**: Detects Angular CLI version and derives defaults dynamically (Zoneless, SSR, etc.).
- **Standardized Scaffolding**: Automatically creates `core/`, `shared/`, and `features/` directory hierarchies.
- **Production Tuning**: Intelligent merging of TSConfig path aliases and optimized production budgets.
- **Quality First**: Automatically triggers the `angular-linters` skill for a day-one quality layer.

### 🧹 [Angular Linters](./angular-linters)

A comprehensive quality stack that ensures code consistency and identifies bugs before they reach production.

- **Integrated Tooling**: Setup for ESLint, Stylelint, Prettier, Husky, and Commitlint.
- **Best Practices**: Pre-configured for modern Angular, including conditional RxJS, accessibility, and import organization plugins.
- **Automated Hooks**: Git hooks for lint-staged and conventional commit message validation.
- **Strict Standards**: Mandatory `defineConfig` wrappers and type-aware linting.

### 📄 [LLMs.txt Generator](./llms-txt-generator)

Standardized documentation retrieval for AI-assisted development.

- **Official Source Protocol**: Fetches and synthesizes content directly from official library/framework documentation URLs.
- **AI-Optimized Output**: Generates `llms.txt` files structured for maximum context efficiency in LLM conversations.
- **Framework Aware**: Adjusts extraction patterns based on the target technology (React, Node.js, API services, etc.).

## 📦 Getting Started

These skills are designed to be used by AI coding assistants. To use them, simply point your assistant to the root of this repository or the specific `SKILL.md` file you need.

### Recommended Stack

- **Framework**: Modern Angular (latest CLI — version-adaptive)
- **Package Manager**: pnpm
- **Styling**: CSS or SCSS
- **Standards**: Conventional Commits, ESLint Flat Config

---

_Built for developers who want to move fast and consistently without repeating themselves._

