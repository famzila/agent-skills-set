# Angular Skills Ecosystem Architecture

This document outlines the architecture, decision trees, and workflows for the Angular project setup and quality layering skills.

## 🏗 System Architecture

The ecosystem is designed with a **Meta-Skill** pattern, where a high-level orchestrator delegates specialized tasks to sub-skills and shell scripts.

```mermaid
graph TD
    User["User Request"] --> PreReq["Prerequisites Check (Node, ng, pnpm)"]
    PreReq --> SetupSkill["angular-setup-project (Meta-Skill)"]
    
    subgraph "Project Creation Phase"
        SetupSkill --> ScaffoldScript["scaffold_structure.sh"]
        SetupSkill --> AgentConfigs["Agent Manual Configs (Paths, Budgets)"]
        SetupSkill --> ServeVerify["ng serve / build Verification"]
    end
    
    subgraph "Quality Layer Phase"
        SetupSkill --> LinterSkill["angular-linters (Sub-Skill)"]
        LinterSkill --> ShellScript["configure_linters.sh"]
        ShellScript --> PNPM["pnpm install (ESLint, Prettier, Stylelint)"]
        ShellScript --> Husky["Husky & Commitlint Init"]
        
        LinterSkill --> AgentFinalize["Agent AI Handoff"]
        AgentFinalize --> Skeleton["eslint-config-template.md (Skeleton)"]
        Skeleton --> Refs["references/*.md (Plugin rules)"]
    end

    Refs --> ESLintConfig["eslint.config.js"]
    ESLintConfig --> LintVerify["ng lint Verification"]
```

---

## 🚦 Decision Tree: Project Bootstrapping

The following tree describes the interactive discovery and creation logic used by `angular-setup-project`.

```mermaid
flowchart TD
    Start([Start Setup]) --> PreVerify{System Requirements Check}
    PreVerify --> |Missing| Install[Install Node/CLI/pnpm]
    Install --> PreVerify
    
    PreVerify --> |Pass| Discovery{Discovery Dialogue}
    
    Discovery --> |Styles| StyleSelection[CSS or SCSS?]
    Discovery --> |Core| SSR{SSR Enabled?}
    Discovery --> |Core| Routing{Routing Enabled?}
    Discovery --> |Zoneless| ZoneJS{Disable Zoneless?}

    StyleSelection --> Params[Collect Parameters]
    SSR --> Params
    Routing --> Params
    ZoneJS --> Params

    Params --> NGNEW[Execute ng new]
    
    NGNEW --> Scaffold[Run scaffold_structure.sh]
    
    Scaffold --> P15[Phase 1.5: Production-Ready Configs]
    P15 --> P15Check{ng build Check}
    
    P15Check --> |Fail| Fix[Fix Configs]
    Fix --> P15Check
    
    P15Check --> |Pass| Quality[Start Phase 2: Quality Layer]
```

---

## 🛠 Quality Layer Integration Workflow

The integration follows a "Shell-Agent Handoff" model to combine deterministic installation with intelligent configuration.

1.  **Orchestration**: `angular-linters` runs `configure_linters.sh`.
2.  **Installation**: The script handles all `pnpm` dependencies and creates boilerplate config files.
3.  **Handoff**: The script signals the Agent to build the complex `eslint.config.js`.
4.  **Composition**: The Agent uses `eslint-config-template.md` as the structural base and populates it with logic from:
    - `parser-config.md`
    - `import-x-and-unused-imports.md`
    - `rxjs.md`
    - `prettier.md`
5.  **Validation**: Every integration step must be verified via `ng lint` or `stylelint`.

---

## 📁 Directory Structure

- `angular-setup-project/`
  |__ `scripts/`
  |__ `SKILL.md`
- `angular-linters/`
  |__ `scripts/`
  |__ `references/`
  |__ `SKILL.md`
