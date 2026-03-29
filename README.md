# agent-skills-set

A collection of AI-driven development skills designed to elevate Angular “vibe coding” to production-ready standards. This repository provides standardized workflows for bootstrapping, linting, integrating third-party libraries, and generating LLM-friendly docs.

## Skills in this repo

| Skill | Path | Role |
|-------|------|------|
| Angular Setup Project | [`angular-setup-project/`](./angular-setup-project) | Create and scaffold new Angular apps |
| Angular Linters | [`angular-linters/`](./angular-linters) | ESLint, Stylelint, Prettier, Husky, Commitlint |
| Angular Third-Party Integration | [`angular-third-party-integration/`](./angular-third-party-integration) | Safe, sequential library integration from official docs |
| LLMs.txt Generator | [`llms-txt-generator/`](./llms-txt-generator) | Build structured `llms.txt` from official URLs |

[`skill-creator/`](./skill-creator) is included for convenience only; it comes from [Anthropic’s official Claude skills repository](https://github.com/anthropics/skills), not from this project.

## Key skills

### [Angular Setup Project](./angular-setup-project)

The foundation for every new project. It automates the creation of a production-ready setup for an Angular application with modern defaults.

- **Version-adaptive**: Detects Angular CLI version and derives defaults dynamically (zoneless, SSR, etc.).
- **Project manifest**: Writes `PROJECT_MANIFEST.json` so downstream skills share one source of truth.
- **Standardized scaffolding**: Creates `core/`, `shared/`, and `features/` directory hierarchies.
- **Production tuning**: TSConfig path aliases and configurable bundle budget profiles.
- **Quality first**: Invokes the `angular-linters` skill for a day-one quality layer.

### [Angular Linters](./angular-linters)

A quality stack that keeps code consistent and catches issues before production.

- **Integrated tooling**: ESLint, Stylelint, Prettier, Husky, and Commitlint.
- **Modern Angular**: Conditional RxJS linting, accessibility and import-organization plugins where configured.
- **Automated hooks**: lint-staged and conventional commit message validation.
- **Strict config**: Flat ESLint config with type-aware linting patterns.

### [Angular Third-Party Integration](./angular-third-party-integration)

Orchestrates integrating third-party libraries (Tailwind, Material, NgRx, Genkit, etc.) into an existing Angular app using **official documentation URLs** first—reducing hallucinated install steps.

- **Verify foundation**: Clean git tree, working app, reads `PROJECT_MANIFEST.json`.
- **Fetch-first context**: Version-aware cache under `references/cache/` (`*.llms.txt`).
- **Pre-install guard**: `compatibility-matrix.md` for prerequisites, order, and manual-action flags.
- **Sequential loop**: One library at a time—build, optional playground proof, format/lint, commit, then surface **required manual actions** (API keys, env vars, external setup).
- **Edge cases**: `common-integrations-edge-cases.md` for known CLI and SSR quirks.

### [LLMs.txt Generator](./llms-txt-generator)

Standardized documentation retrieval for AI-assisted development (any stack, not only Angular).

- **Official source protocol**: Fetches and synthesizes content from official documentation URLs.
- **AI-optimized output**: `llms.txt` structured for efficient LLM context.
- **Framework-aware**: Extraction patterns tuned to the target technology.

## Getting started

These skills are meant for AI coding assistants. Point your assistant at this repository root or at the specific `SKILL.md` inside the skill directory you need.

### Recommended Angular stack

- **Framework**: Modern Angular (CLI version detected at runtime by setup skill)
- **Package manager**: pnpm, npm, or yarn (manifest + lockfile-aware)
- **Styling**: CSS or SCSS
- **Standards**: Conventional Commits, ESLint flat config

---

_Built for developers who want to move fast and consistently without repeating themselves._
