---
name: angular-third-party-integration
description: Orchestrates the safe, reliable integration of third-party libraries (TailwindCSS, Angular Material, NgRx, etc.) into an Angular project. Generates and uses standardized llms.txt documentation files for accurate context and prevents hallucinated commands.
---

# Angular Third-Party Integration Orchestrator

This skill orchestrates the safe integration of third-party libraries into an existing, production-ready Angular application. It enforces a strict "Verify Foundation First" rule, mandates the generation of standardized llms.txt documentation directly from official URLs, and executes the integration strictly based on that generated context.

## 1. The Pre-Integration Pause (MANDATORY)

**CRITICAL**: Before asking the user for the list of libraries to integrate, fetching any documentation, or modifying any configuration files, you **MUST** ensure the foundational setup is working perfectly.

### Foundation Verification Process
1. **Verify Angular Context**: Check for `angular.json` in the workspace. If it does not exist, tell the user they must be in an Angular project and abort.
2. **Detect Environment**: Inspect `package.json` to determine the current **Angular version** and the **package manager** (npm, yarn, pnpm, bun) being used.
3. **Prompt the User**: Tell the user exactly this:
   > "Before we integrate any third-party libraries, please take a moment to verify that your foundational Angular setup is working perfectly. Run your start script (e.g., `[detected-pkg-manager] start`) and ensure the app compiles and loads without errors."
4. **DO NOT PROCEED** to ask for libraries or fetch documentation until the user explicitly confirms the foundation is working.

## 2. Documentation Request & Missing URLs

Once the user confirms the foundation is verified, ask them to provide a list of the third-party libraries they wish to install along with their **official documentation URLs**.

If the user requests integration without providing URL(s):
1. Ask the user to provide the official documentation URL(s).
2. Explain that official documentation URLs are needed to prevent hallucinated configurations or incompatible versions with the project's Angular [Detected Version].
3. Example response: "I'll need the official documentation URL for [library]. Please provide the link so I can generate accurate integration steps."

Do not proceed with web search-based alternatives without explicit user consent.

### Pre-Requisite Dependency Check (MANDATORY)

If the requested library explicitly references a foundational peer dependency (e.g., a core CSS library, state management library, or any other required peer dependency), you **MUST** fetch (if exist in extracted llms.txt content) or prompt the user for the documentation URL of that underlying library as well if it's missing.

## 3. Documentation Retrieval Protocol

**CRITICAL**: This skill requires fetching exact URL content, not search results.

### Fetching Process
1. **Use your URL reading tools** to retrieve the EXACT URL provided by the user.
2. **Check Cache:** First, check `references/cache/` within this skill's directory. If a `.llms.txt` file for the requested library and version already exists, use it immediately and skip the web fetching.
   - If you need to generate a new file, save it into `references/cache/[library-name]-v[version].llms.txt` when you're done.
3. **Never substitute with web search** if the exact URL is available.

### Validation
Before processing retrieved content, confirm:
- ✓ Content is from the actual documentation page.
- ✓ Contains complete information with API references, code examples, or usage patterns.
- ✗ Content is NOT search engine snippets, error pages, or truncated previews.

## 4. Standard llms.txt Structure

For *each* library requested, generate an `llms.txt` file following this exact template structure.

### Required Sections
1. **Header Block** (Library/Framework name, Version, Official source URL, Generation date)
2. **Overview** (Brief description, primary use case, key features)
3. **Installation & Setup** (Exact installation commands and required peer dependencies)
4. **Core Concepts** (Main abstractions, architecture overview, key terminology)
5. **API Reference** (Main functions/methods/components, parameters, return types, TypeScript types if applicable)
6. **Common Usage Patterns** (Practical code examples, frequent use cases, integration patterns)
7. **Error Handling** (Common errors, error handling patterns, debugging tips)
8. **Best Practices** (Recommended patterns, performance considerations, common pitfalls to avoid)

### Optional Sections (include if present in docs)
- Authentication/Authorization
- Advanced Features
- Framework-Specific Integration

## 5. Extraction Guidelines

### Content Quality
- **CRITICAL EXTRACTION RULE**: You MUST extract and copy full, working code snippets from the documentation. Do not just summarize.
- **Prioritize official examples** over third-party code.
- **Preserve TypeScript types** exactly as documented.
- **Keep examples concise** but functional.
- **Extract API signatures** with parameter types and return types.

### What to Include
- Installation commands using the detected package manager.
- Core API methods and UI component setup.
- Practical usage examples (especially those using Angular Signals, standalone components, or SSR if applicable).
- Error handling patterns.

### What to Exclude
- Marketing copy and promotional language.
- Excessive background/history.
- Deprecated APIs.

## 6. Output Format & Presentation

### File Naming
Use kebab-case: `[library-name]-v[version].llms.txt`
Save them strictly to the `references/cache/` directory.

### File Structure Example
```
# Library Name

**Version:** X.X.X
**Source:** [Official Documentation URL]
**Generated:** YYYY-MM-DD

## Overview
[Content]

## Installation & Setup
[Content]

[... remaining sections ...]
```

### Presentation
After generation:
1. Present the complete generated (or cached) `.llms.txt` files to the user for review.
2. Confirm the exact installation steps and files meet their needs.
3. **Context Lock:** Once the user approves the `.llms.txt` files, use them as your primary context for the Execution Phase.

## 7. The Sequential Playground Execution Protocol (CRITICAL)

When the user approves the context files, you MUST NOT install all libraries at once. You must perform the following **Sequential Loop** for each requested library, one by one:

### Step 7.0A: Continuous Improvement Capture (MANDATORY)

During the integration loop, you will occasionally encounter real-world issues (interactive prompts that hang, peer dependency conflicts, SSR bundling quirks, style layering conflicts, etc.). When this happens:

1. **Fix the issue** to unblock the integration (keep the project building and verified).
2. **Remember it as an “improvement point”** for later:
   - the skill (`SKILL.md`) process, and/or
   - the library reference (`references/cache/*.llms.txt`), and/or
   - `references/common-integrations-edge-cases.md`.
3. **Send the user a very short message immediately**, exactly like:
   > "Noted — I’ll keep this as an improvement point and suggest it at the end."

At the end of all integrations (Step 10), you MUST propose these captured improvement points as global improvements as well as your global reflection about the whole experience during the third party integration process.

### Step 7.0: Interactive CLI Prompt Handling (CRITICAL)

Some library integrations rely on interactive CLI generators (Angular schematics, `ng add`, `ng g`, `npx ...`, etc.). These generators often use prompt UIs that require a real TTY. In non-interactive shells, they may hang, auto-exit, or appear to "succeed" without applying changes.

This skill MUST follow this prompt-handling strategy whenever it runs a generator-like command.

#### Tier 1 — Prefer non-interactive flags (always try first)

Before running any generator, inspect its help output and prefer flags that disable prompts:

- `--defaults`
- `--interactive=false` (or `--no-interactive`)
- `-y` / `--yes`
- Explicit arguments (e.g., `ng g ... button`, `ng add ... --project=...` when supported)

If the generator provides a `--project`/`--app` or other flag, you MUST use it to avoid prompts.

#### Tier 2 — Detect prompts and switch to pseudo‑TTY automation (macOS/Linux)

If Tier 1 still triggers prompts (typical lines contain one of: `? Choose`, `Select`, `Pick`, `Use arrow keys`, `No matching choices`, or text input prompts like `? What ... should be used`), re-run the generator under a pseudo‑TTY and feed deterministic answers.

On macOS/Linux, the most reliable built-in approach is `expect` (ships on macOS, common on Linux).

**Default automation policy (deterministic):**
- For **single-choice selects**: press Enter to accept the default selection.
- For **free-text prompts**: press Enter to accept the default (or auto-detected) value.
- For **yes/no confirmations**: answer `y` then Enter.

**Universal inline expect template:**

```bash
expect -c '
set timeout 180
spawn <FULL_COMMAND_HERE>
expect {
    -re {\?.*›} { send "\r"; exp_continue }
    -re {\?.*\(y/N\)} { send "y\r"; exp_continue }
    -re {\?.*\(Y/n\)} { send "y\r"; exp_continue }
    -re {>\s*$} { send "\r"; exp_continue }
    eof
}
catch wait result
exit [lindex $result 3]
' 2>&1
```

**Pattern explanation:**
| Pattern | Matches | Action |
|---------|---------|--------|
| `{\?.*›}` | Any prompt with `?` and `›` (default value indicator) | Accept default (Enter) |
| `{\?.*\(y/N\)}` | Yes/No confirmation (default No) | Answer `y` |
| `{\?.*\(Y/n\)}` | Yes/No confirmation (default Yes) | Answer `y` |
| `{>\s*$}` | Fallback for any trailing `>` prompt | Accept default (Enter) |

**Example usage for Spartan CLI:**

```bash
cd /path/to/project && expect -c '
set timeout 180
spawn pnpm exec ng g @spartan-ng/cli:ui button --directory libs/ui
expect {
    -re {\?.*›} { send "\r"; exp_continue }
    -re {\?.*\(y/N\)} { send "y\r"; exp_continue }
    -re {\?.*\(Y/n\)} { send "y\r"; exp_continue }
    -re {>\s*$} { send "\r"; exp_continue }
    eof
}
catch wait result
exit [lindex $result 3]
' 2>&1
```

If the generator requires a non-default selection (e.g., not the first app), DO NOT guess. Fall back to Tier 3 (user answers the prompt).

#### Tier 3 — Ask the user to answer prompts in-place (portable fallback)

If pseudo‑TTY automation is unavailable (Windows without a PTY runner, missing `expect`, or prompts are not safely automatable), the skill MUST still run the command itself, then pause and ask the user to answer the prompt in their terminal.

**Required wording:**
> "Action required: the command is waiting for interactive input in your terminal. Please answer the prompt (choose X / confirm Y). Reply 'done' here when finished so I can continue."

Then the skill continues with build/lint/runtime verification.

### Step 7A: Install & Configure
1. Read the specific `references/cache/[library].llms.txt` file.
2. Install the library using the detected package manager.
3. Configure the files (`angular.json`, `styles.scss`, `server.ts`, etc.) exactly as described in the context file.
4. **TypeScript Boundary Check:** If the integration generates scaffolding or code outside of the standard `src/app` directory (e.g., library workspaces or UI component folders), you **MUST** actively update the `include` arrays in the relevant `tsconfig` files (e.g., `tsconfig.app.json`, `tsconfig.spec.json`) so that ESLint and the Angular compiler can track the new paths without AST parsing failures.

### Step 7B: Build Verification (MANDATORY)
1. Run `[pkg-manager] run build` to ensure the SSR and browser bundles do not crash from unresolved modules, peer dependency conflicts, or configuration typings.
2. **If the build fails:**
   - Investigate the error (e.g., rigid paths, missing `externalDependencies` config for Angular bundle tree-shaking rules, TypeScript strictly typed interfaces).
   - Fix the broken configuration files directly.
   - Run `[pkg-manager] run build` again until it passes with **Exit Code 0**. 
   - DO NOT proceed to create Playground Injection widgets until a clean build establishes that the integration setup is foundationally sound.

> **CRITICAL — Root Cause over Quick Fix:** When encountering any error or bug (build failures, typing errors, module resolution, etc.), DO NOT apply quick hacks. You **MUST** investigate and fix the root cause to ensure a clean solution before committing.

### Step 7C: The Playground Injection
You cannot trust that a successful build means the library works in the browser. You must prove it.
1. Temporarily modify `src/app/app.component.html` (or a similar root component) to inject a "Proof of Life" element.
   - *Example (Tailwind):* `<div id="tw-test" class="bg-red-500 text-white p-4">Tailwind works</div>`
   - *Example (Genkit):* `<button id="genkit-test" (click)="test()">Test Genkit</button><p id="genkit-result">{{ result() }}</p>`
2. Start the Angular dev server (`[pkg-manager] start &`) in the background.

### Step 7D: Automated Subagent Verification (Option A)
1. Use the **Browser Subagent** tool (`browser_subagent`) to navigate to `http://localhost:4200` (or otherwise configured active dev server port).
2. Instruct the subagent to interact with the playground injection and wait for the result to appear in the DOM.
3. Wait for the subagent to confirm the library is functionally working at runtime.
4. If Browser Subagent is not available ask the user to confirm that it works.

### Step 7E: Clean-Up & Commit
- **If Verification Succeeds:** 
  1. Stop the Angular dev server.
  2. Undo/Revert the temporary playground injections in `app.component` to keep the workspace tidy.
  3. Run `[pkg-manager] run format` and `[pkg-manager] run lint`.
  4. Explicitly commit the working integration: `git add .` and `git commit -m "chore: integrate [library-name]"`.
- **If Verification Fails:**
  1. Immediately run `git reset --hard HEAD` and `git clean -fd` to wipe out the broken integration.
  2. Stop the loop and notify the user: *"The integration for [library] failed at runtime. I have rolled back the project. Let's debug."*

**REPEAT this loop for every requested library.**

## 8. Context-Aware Generation (Edge Cases)

Detect the framework/context from the documentation URL and adjust structure:
- **DOCUMENTATION SOURCE RULE:** Always favor the official framework documentation over the library's generic documentation if it exists (e.g., use `angular.dev` guides for Tailwind CSS rather than `tailwindcss.com`).
- Read `references/common-integrations-edge-cases.md`. If the library is listed there, append those edge-case instructions into the generated `.llms.txt` file for that library.
- **Documenting New Edge Cases:** If you encounter a framework bug or version incompatibility during the Sequential Execution loop and solve it, you MUST document the solution in `references/common-integrations-edge-cases.md` so future agents remember it.

### Security Context Rule (MANDATORY)

Whenever an integration involves sensitive credentials (API keys, tokens, secrets), **NEVER** suggest or implement insecure patterns (e.g., hardcoding secrets in client-side code, exposing them in browser bundles, or committing them to source control). You must:
1. Analyze the security context deeply.
2. Suggest multiple secure approaches (e.g., server-side `process.env`, local auth flows, cloud-managed service accounts, dedicated secret managers).
3. Explicitly exclude insecure options from your suggestions.
4. Prompt the user for their preferred secure architecture **before** writing the code.

## 9. Final Verification

After the sequential loop finishes and all libraries are verified and committed individually:
1. Suggest the user run their start script one final time to view their fully loaded application state.

## 10. Post-Integration Reflection & Continuous Improvement

Once all verified libraries are individual committed and individual loops end:

1.  **Catalog Improvements**: Review any bugs, syntax crashes, or rigid template variables fixed on-the-fly during building or playground interactions.
2.  **Formulate Recommendations**: Create 2-3 specific improvement targets targeting:
    -   The cached `references/cache/*.llms.txt` references.
    -   The generic edge case library documentation (`common-integrations-edge-cases.md`).
    -   This `SKILL.md` logic setup itself.
3.  **Prompt the User**: Summarize these recommendations clearly at the very end. Ask the user which specific items they want you to implement on-the-spot to continuously improve the workspace's training documents. Do not close the session or task set until confirming this preference.
