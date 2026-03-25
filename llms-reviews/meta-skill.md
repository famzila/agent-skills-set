Opus 4.6 review:

## Full Structured Review: Angular Skill System

### WHAT WORKS WELL

1. **Incremental verification model in `angular-linters`**: The "add one plugin, lint, verify, proceed" pipeline is the single most valuable pattern in this system. It prevents cascading failures and makes debugging trivial. Do not change this.

2. **Sequential library loop in `angular-third-party-integration`**: Installing one library at a time with build verification and rollback per library is the correct architecture. The git-based rollback (`git reset --hard HEAD && git clean -fd`) on failure is aggressive but appropriate for this use case.

3. **Reference files as source of truth**: The `references/` directory in `angular-linters` is well-structured. Each file covers one concern, includes exact code snippets, and links to upstream docs. This is the right way to prevent hallucination for known configurations.

4. **Interactive CLI handling (Tier 1/2/3)**: The three-tier `expect` strategy in `angular-third-party-integration` is genuinely well-thought-out. The escalation from flags to automation to human handoff covers real-world failure modes.

5. **Failure recovery clauses**: Both `angular-setup-project` (delete failed project) and `angular-linters` (git reset --hard) have explicit failure recovery. Most skills don't.

6. **The llms.txt generation protocol**: Forcing the agent to fetch and structure documentation before touching anything is a strong anti-hallucination measure. The "Context Lock" step where the user approves before execution is particularly good.

7. **Validation testing with intentional violations**: `references/validation-testing.md` is excellent. Creating known-bad files and verifying detection is the only way to prove the linting stack actually works. The cleanup checklist is thorough.

---

### GENERICITY ISSUES

**G1. Angular version hardcoded as "21" in `angular-setup-project`**

Lines 58, 74, 77 all reference Angular 21 specifically:

> "Zoneless: enabled (Angular 21 default — no flag needed)"
> "Angular 21 is zoneless by default — do NOT pass `--zoneless`"

This will break the moment Angular 22 ships, or if someone uses this skill on Angular 19/20. The skill should detect the installed Angular CLI version and adapt.

**Fix**: Replace all Angular 21 references with dynamic detection:

```
1. Run `ng version` and parse the major version.
2. If major >= 21: Zoneless is the default. Do NOT pass `--zoneless`.
3. If major < 21: Zoneless is opt-in. Pass `--zoneless` if the user wants it.
4. If major < 19: Zoneless is not available. Inform the user.
```

**G2. Package manager hardcoded as `pnpm run` throughout `angular-linters`**

The skill accepts `--package-manager` in Step 1, but every subsequent step says `pnpm run lint`, `pnpm run lint:styles`, `pnpm run format`, etc. Steps 3.1 through 6 all hardcode `pnpm`.

**Fix**: Use `[pkg-manager] run` placeholder consistently, or add a clear instruction at the top: "In all commands below, replace `pnpm` with the package manager detected or specified in Step 1."

**G3. `scripts/` paths are ambiguous across skills**

`angular-setup-project` says "Run `scripts/scaffold_structure.sh`" — relative to what? The skill directory? The current working directory? The project root? This is critical because skills live in a different directory than the target project.

**Fix**: Every script reference must use an absolute path pattern:

```
Run `<SKILL_DIRECTORY>/scripts/scaffold_structure.sh <PROJECT_ROOT>`
```

Or add an explicit instruction: "All script paths are relative to THIS SKILL's directory, not the project directory."

**G4. CommonJS-only ESLint configuration**

All reference files use `require()` / `module.exports`. If the target project has `"type": "module"` in `package.json`, every config file will fail. The `eslint.config.js` extension should be `.cjs` in that case, or the skill should detect the module system.

**Fix**: Add a detection step: "Check `package.json` for `\"type\": \"module\"`. If present, use `.cjs` extension for config files or adjust to ESM syntax."

**G5. `defineConfig` enforcement is version-fragile**

The Fundamental Principle in `angular-linters` says:

> "For Angular v19+ and v21+, `defineConfig` from `eslint/config` is the mandatory wrapper."

This "v19+ and v21+" phrasing is odd (what about v20?), and the word "mandatory" is too strong — it's the Angular schematic's default, not the only valid approach. A future Angular version could change the default.

**Fix**: Reword to: "Preserve whatever wrapper the Angular CLI generated in `eslint.config.js`. As of Angular 19+, this is `defineConfig` from `eslint/config`. Do NOT replace it with a different wrapper unless the official Angular schematics change."

---

### ROBUSTNESS GAPS

**R1. `git reset --hard` in `angular-linters` assumes clean working directory**

The failure recovery says: "If any step fails, the Agent MUST run `git reset --hard`." But if the user had uncommitted changes before starting, this nukes them.

**Fix**: Add a pre-condition: "Before running this skill, verify the git working directory is clean (`git status --porcelain` returns empty). If it is not clean, instruct the user to stash or commit first. This is required because the failure recovery uses `git reset --hard`."

The pre-condition is actually stated ("ensure the git working directory is clean") but there's no enforcement step. Add:

```
Run `git status --porcelain`. If output is non-empty, STOP and tell the user:
"Your working directory has uncommitted changes. Please commit or stash them before proceeding."
```

**R2. `git reset --hard HEAD && git clean -fd` in `angular-third-party-integration` Step 7E can destroy unrelated work**

If verification fails, the rollback wipes everything since the last commit. But what if there were manual user changes between Step 7A and 7E?

**Fix**: Before each library integration loop, create a restore point: `git stash push -m "pre-integration-[library]"` or commit a checkpoint. On failure, revert to that specific checkpoint, not to HEAD.

Better yet: Each library integration should start with `git rev-parse HEAD` saved as `$RESTORE_POINT`, and failure rollback should be `git reset --hard $RESTORE_POINT`.

**R3. No timeout or hang detection for lint/build commands**

Multiple steps say "Run `pnpm run lint`" with "MUST pass" but never address what happens if the command hangs (infinite loop in a plugin, locked file, etc.).

**Fix**: Add a global instruction: "If any lint or build command has not produced output for 60 seconds, kill the process and investigate. Common causes: missing `tsconfigRootDir` causing infinite file search, or a circular dependency in plugin resolution."

**R4. `references/common-integrations-edge-cases.md` doesn't exist**

`angular-third-party-integration` Section 8 says "Read `references/common-integrations-edge-cases.md`" but this file is not present in the skill directory. The file listing only shows `scripts/run_with_expect.sh`, `scripts/README.md`, and `SKILL.md`.

**Fix**: Either create the file with an initial structure, or add: "If `references/common-integrations-edge-cases.md` does not exist, create it with a header and empty sections. Do not skip this step."

**R5. `references/cache/` directory doesn't exist and is never created**

The skill says "check `references/cache/`" and "save into `references/cache/`" but this directory doesn't exist in the skill structure.

**Fix**: Add to Step 3: "Create `references/cache/` if it does not exist: `mkdir -p <SKILL_DIR>/references/cache/`"

**R6. No handling for `ng add @angular-eslint/schematics` failure in the shell script**

`configure_linters.sh` line 71 runs `npx -y ng add @angular-eslint/schematics --skip-confirmation`. If this fails (network issues, version conflict), `set -e` exits the script but the agent has no specific recovery guidance beyond the generic "git reset --hard".

**Fix**: Add error-specific guidance: "If `ng add @angular-eslint/schematics` fails, check: (1) network connectivity, (2) Angular version compatibility, (3) existing ESLint configuration conflicts. Do NOT retry without diagnosing the failure."

**R7. Dev server port collision in Step 7C**

Step 7C says "Start the Angular dev server" but doesn't handle the case where port 4200 is already in use (from a previous failed loop iteration, or another process).

**Fix**: Add: "Before starting the dev server, ensure no process is already using port 4200: `lsof -ti:4200 | xargs kill -9 2>/dev/null || true`. If port 4200 cannot be freed, use `--port 0` to auto-assign."

---

### HALLUCINATION RISKS

**H1. No runtime version verification in `angular-setup-project`**

The skill assumes Angular 21 behavior without verifying. If the installed CLI is Angular 20 or 22, the agent will apply incorrect flags (e.g., passing or not passing `--zoneless`).

**Fix**: After `ng version`, parse the output and store the major version. All version-dependent decisions must reference this parsed value, not a hardcoded assumption.

**H2. Reference files are trusted without version-pinning**

The reference files in `angular-linters/references/` contain specific code snippets for specific package versions. If the installed packages are newer or older, the snippets could be wrong. There's no instruction to cross-check reference content against installed versions.

**Fix**: Add to the Fundamental Principles: "After installing packages, compare the installed version (from `package.json`) against the version documented in the reference file header. If they differ significantly (major version mismatch), warn the user and suggest updating the reference file."

Reference files should include a version header: `**Tested with:** eslint-plugin-rxjs-x@1.x, Angular 21.x`

**H3. Web search fallback in `angular-third-party-integration` has no guardrails**

Section 2 says "Do not proceed with web search-based alternatives without explicit user consent." But after consent is given, there are zero constraints on what the agent does with web search results. The agent could find outdated blog posts and treat them as truth.

**Fix**: Add: "If the user consents to web search, restrict searches to: (1) the library's official documentation domain, (2) angular.dev, (3) github.com/[library-org]. Do NOT use blog posts, Stack Overflow answers, or tutorial sites as primary sources. Web search results must be cross-validated against the installed library version."

**H4. No enforcement that the agent actually reads reference files before configuring**

`angular-linters` says "Read all files in the `references/` directory" in Step 1, but there's no verification that this happened. An overconfident agent could skip reading and rely on training data.

**Fix**: Make it structural: "For each step that references a file (e.g., 'consult references/rxjs.md'), you MUST quote the specific code snippet from the reference file in your response before applying it. If you cannot quote it, you have not read it."

**H5. `angular-third-party-integration` llms.txt content is not validated against installed version**

The llms.txt file is generated from documentation URLs but never cross-referenced against the actual installed version. If docs describe v4 but `pnpm add` installs v3, the agent will apply v4 configuration to v3.

**Fix**: After installation in Step 7A, add: "Verify the installed version matches the version documented in the llms.txt file. Run `[pkg-manager] list [library-name]` and compare. If they differ, warn the user and adjust configuration accordingly."

---

### OVERFITTING ISSUES

**O1. `// @ts-ignore` instruction for import-x plugin**

`angular-linters` Step 3.3 says:

> "Add `// @ts-ignore` above the `'import-x': importX` line (known type incompatibility with ESLint's Plugin type)."

This is a workaround for a specific version of `eslint-plugin-import-x`. When the library fixes its types, this instruction becomes wrong and introduces an unnecessary suppression.

**Fix**: Rewrite as a conditional: "If `// @ts-check` is enabled at the top of `eslint.config.js` and TypeScript reports a type error on the `import-x` plugin registration, add `// @ts-ignore` with the comment `-- import-x Plugin type mismatch, see [github issue URL]`. If no type error occurs, do NOT add the suppression."

**O2. Budget values in `angular-setup-project` Phase 1.5**

The budget override (`2MB warning / 4MB error`) is presented as a universal recommendation, but it's actually just "our projects got big." A small utility app should have tighter budgets.

**Fix**: Rewrite as guidance, not prescription: "Review the default budgets (`500kB warning / 1MB error`). If the project will include third-party component libraries, internationalization, or heavy dependencies, consider raising to `2MB/4MB`. Otherwise, keep the defaults tight and loosen only when specific build warnings appear."

**O3. Step 7.0A (Continuous Improvement Capture) in `angular-third-party-integration`**

This entire section is a formalization of "learn from mistakes during execution." While the concept is sound, the implementation (capture issues → propose at end → modify skill files) means the skill accumulates patches over time rather than being redesigned when patterns emerge.

**Fix**: Separate the concerns. The runtime fix should happen immediately. The "improvement point" capture should be limited to: "If the issue reveals a GAP in this skill's process (not just a library-specific quirk), note it for post-session review." Library-specific quirks should go into the llms.txt cache, not the SKILL.md.

**O4. "DOCUMENTATION SOURCE RULE" favoring angular.dev in Section 8**

> "Always favor the official framework documentation over the library's generic documentation"

This is a patch for a specific past mistake (probably used tailwindcss.com instead of angular.dev for Tailwind setup). It's good advice but it should be a general principle, not a one-liner rule buried in edge cases.

**Fix**: Move this to Section 3 (Documentation Retrieval Protocol) and generalize: "When a library has framework-specific installation docs (e.g., angular.dev/guide/tailwind instead of tailwindcss.com), prefer the framework-specific version. Ask the user to provide the Angular-specific URL if only the generic one was given."

---

### CLARITY IMPROVEMENTS

**C1. "Invoke the angular-linters skill" — HOW?**

`angular-setup-project` Phase 2 says "Invoke the angular-linters skill" but never defines the invocation mechanism. Does the agent read the SKILL.md file? Call a function? The agent has no way to know.

**Rewrite**: "Read the `angular-linters/SKILL.md` file from the skill directory and execute its workflow starting from Step 1. Pass the `--style` and `--package-manager` values confirmed in Phase 1."

**C2. Script paths need explicit anchoring**

`angular-setup-project` line 80:

> "Run `scripts/scaffold_structure.sh` to create the hierarchy."

**Rewrite**: "Run the scaffold script located at `<THIS_SKILL_DIR>/scripts/scaffold_structure.sh`, passing the project root as the first argument: `bash <THIS_SKILL_DIR>/scripts/scaffold_structure.sh <PROJECT_ROOT>`"

**C3. "Browser Subagent" tool reference is wrong**

`angular-third-party-integration` Step 7D says:

> "Use the Browser Subagent tool (`browser_subagent`)"

This tool name doesn't match any real tool. In Cursor, it's the `browser-use` subagent type in the Task tool, or the `cursor-ide-browser` MCP server.

**Rewrite**: "Use the available browser automation capabilities (e.g., browser MCP tools, browser subagent, or equivalent) to navigate to the dev server URL and verify the playground injection renders correctly. If no browser automation is available, ask the user to manually verify."

**C4. "or a similar root component" is too vague in Step 7C**

> "Temporarily modify `src/app/app.component.html` (or a similar root component)"

**Rewrite**: "Temporarily modify the application's root component template (typically `src/app/app.component.html` — verify by checking the `bootstrap` or `appComponent` configuration in `app.config.ts` or `main.ts`)."

**C5. "Create 2-3 specific improvement targets" is an arbitrary number**

Step 10 says "Create 2-3 specific improvement targets." What if there are zero issues? What if there are 7?

**Rewrite**: "Review all improvement points captured during integration. Present every actionable improvement, grouped by category (skill process, library references, edge cases). If no issues were encountered, state that explicitly."

**C6. Step 5 lint-staged config hardcodes `*.css`**

The lint-staged example in `angular-linters` Step 5 uses `"*.css"` but the project might use SCSS. The instruction says to adjust globs in Step 3.0 but Step 5's example doesn't mention this.

**Rewrite**: Add a note after the lint-staged example: "Adjust the style glob to match the project's style format: use `*.css` for CSS projects, `*.scss` for SCSS projects, or `*.{css,scss}` if both are present."

---

### COMPATIBILITY GUARD GAPS

**CG1. No compatibility matrix between third-party libraries**

`angular-third-party-integration` installs libraries one-by-one but never checks if they conflict with each other. Examples: Angular Material and Spartan UI both provide button components; NgRx and NGXS are competing state management solutions; two CSS frameworks can fight.

**Fix**: Add a pre-installation step: "Before starting the sequential loop, review the full list of requested libraries for known conflicts. Known conflict patterns: (1) Multiple component libraries (Material + Spartan + PrimeNG), (2) Multiple state management libraries (NgRx + NGXS + Akita), (3) Multiple CSS frameworks (Tailwind + Bootstrap). If conflicts are detected, present them to the user and ask which to keep."

Create a `references/compatibility-matrix.md` that maps known conflicts and can be extended without changing SKILL.md.

**CG2. No Angular version compatibility check for third-party libraries**

When generating the llms.txt file, there's no step that verifies the library supports the project's Angular version. Many libraries lag behind Angular releases.

**Fix**: Add to Step 7A: "Before installing, check the library's `peerDependencies` for Angular version compatibility. Run `npm info [library] peerDependencies` and compare against the project's Angular version. If incompatible, STOP and inform the user."

**CG3. No ESLint plugin compatibility verification**

`angular-linters` installs multiple ESLint plugins but never checks if their versions are compatible with each other or with the installed ESLint version.

**Fix**: After Step 1 installation, add: "Verify no peer dependency warnings were produced during installation. If warnings exist, list them and assess whether they are safe to ignore (document why) or require version pinning."

---

### SYSTEM INTEGRITY GAPS

**SI1. Missing `references/common-integrations-edge-cases.md` breaks the third-party skill**

`angular-third-party-integration` Section 8 explicitly instructs the agent to read and write to `references/common-integrations-edge-cases.md`, but this file does not exist in the skill directory. The first run will either fail or silently skip the step.

**Fix**: Create the file with an initial structure, or add an explicit creation step: "If `references/common-integrations-edge-cases.md` does not exist, create it from the template below."

**SI2. Missing `references/cache/` directory breaks the caching protocol**

Same issue. The directory is referenced but doesn't exist. Neither `SKILL.md` nor any script creates it.

**Fix**: Add `mkdir -p references/cache` as the first action in Step 3, or include an empty `.gitkeep` in the directory.

**SI3. Package manager detected in `angular-setup-project` is not reliably passed to child skills**

`angular-setup-project` detects the package manager in Phase 1 and passes it to `angular-linters` via `--package-manager`. But `angular-linters` then hardcodes `pnpm run` in every example. The contract says "I'll tell you the package manager" but the child skill ignores it.

This is the most damaging system integrity bug. If a user chooses `npm`, the linter skill will generate instructions that reference `pnpm run` commands, which will fail.

**Fix**: `angular-linters` must use `[pkg-manager]` placeholders in all command examples, with a clear instruction at the top: "Replace `[pkg-manager]` with the value passed via `--package-manager` (or auto-detected in Step 1)."

**SI4. Style format contract is incomplete**

`angular-setup-project` passes `--style css|scss` to `angular-linters`. But the linter skill's script only handles these two values. Angular CLI also supports `less` and `sass`. If the user picks `less`, the script will install the wrong Stylelint config.

**Fix**: Either restrict the allowed values in `angular-setup-project` ("Styles: `css` or `scss` only. `less` and `sass` are not supported by the quality stack.") or extend `configure_linters.sh` to handle all four formats.

**SI5. No defined contract for "skill invocation"**

`angular-setup-project` says "Invoke the angular-linters skill" and "Invoke the angular-third-party-integration skill" but never defines what "invoke" means. Is it "read the SKILL.md and follow its instructions"? Is it "call a tool"? Different agents in different environments will interpret this differently.

**Fix**: Add a System Contract section to `angular-setup-project`:

```
## Skill Invocation Contract
To invoke a sub-skill:
1. Read the sub-skill's SKILL.md from its directory.
2. Follow its workflow from Step 1, passing the required parameters.
3. The sub-skill's workflow is complete when its final step succeeds.
4. Return to the parent skill's next phase.
```

**SI6. Adding a new sub-skill requires modifying the meta-skill**

If someone creates a new skill (e.g., `angular-testing-setup`), they must edit `angular-setup-project/SKILL.md` to add a new phase. There's no plugin or hook system.

This is acceptable for now given the skill count, but worth noting. No immediate fix needed unless the system grows beyond 4-5 skills.

---

### TOP 3 PRIORITIES

**1. Fix the package manager propagation gap (SI3 + G2)**

This is the highest priority because it causes guaranteed failures for any user who doesn't use pnpm. The `angular-linters` skill hardcodes `pnpm run` in approximately 15 places while accepting `--package-manager` as input. Every npm or yarn user will hit broken instructions. Fix by replacing all hardcoded `pnpm` references with the detected package manager throughout `angular-linters/SKILL.md` and its reference files.

**2. Remove hardcoded Angular 21 assumptions (G1 + H1)**

The second highest priority because this causes the skill to age badly. Angular 22 will ship, and every version-specific instruction (zoneless defaults, `defineConfig` wrapper, Prettier auto-generation) will silently produce wrong behavior. Replace all version-specific instructions with version-detection logic that reads the actual installed CLI version and branches accordingly.

**3. Create missing referenced files (SI1 + SI2 + R4 + R5)**

The third priority because missing files cause either silent skips or hard errors depending on the agent. `references/common-integrations-edge-cases.md` and `references/cache/` are referenced as mandatory read/write targets but don't exist. Create them with initial templates, or add explicit "create if missing" instructions.

--
Sonnet 4.6 review
Here is my full structured review of all three skills.

## ✅ WHAT WORKS WELL

**`angular-setup-project`**

- The mandatory interactive discovery dialogue before `ng new` is excellent — it prevents silent assumption-based failures.
- The hard stop on detecting an existing Angular project (`angular.json`) is a solid guardrail.
- The clean separation into phases (Create → Quality → Third-Party) is a coherent architecture.
- Requiring `--style` and `--package-manager` to be passed explicitly into `angular-linters` is a correct, typed handoff.
- The cleanup rule (delete the generated directory before retrying a failed `ng new`) prevents corrupted state from propagating.

**`angular-linters`**

- The incremental plugin verification model (add one plugin, run `pnpm run lint`, MUST pass before next) is the right strategy for catching regressions at the exact step that introduced them.
- The "continuous pipeline" directive (steps 1–8, no pausing) is explicit and correct for an agent context.
- The `references/` directory as source of truth is the right pattern — it keeps the SKILL.md thin and delegates detail to versioned reference files.
- Validation testing (Step 7) intentionally creating violations to confirm rules are active is a mature quality gate most agent skills skip.

**`angular-third-party-integration`**

- The llms.txt generation protocol is the strongest anti-hallucination mechanism in the entire system. Forcing a fetch-first policy before any installation is excellent.
- The three-tier interactive CLI prompt handling (non-interactive flags → expect TTY → user fallback) is pragmatic and covers real-world scenarios well.
- The "Playground Injection" concept (Step 7C/7D) is exactly right: a successful build does not mean the library works at runtime.
- The rollback on runtime failure (`git reset --hard HEAD && git clean -fd`) is a strong hard stop.
- The Post-Integration Reflection loop (Step 10) actively improves the skill's own knowledge base — this is a rare and valuable self-improvement mechanism.
- The Security Context Rule is clear, mandatory, and covers the right threat model (client-side secret exposure).

---

## ⚠️ GENERICITY ISSUES

**1. Angular version baked into `angular-setup-project`**

```
Zoneless: enabled (Angular 21 default — no flag needed)
```

This will be wrong for users on Angular 18, 19, 20, or 22+. The skill hardcodes Angular 21 behavior in two places (Phase 1 Discovery and Phase 1 Technical). If zoneless becomes opt-in again in a future version, or if the flag changes, this instruction produces a broken project silently.

**Fix:** Replace this with a runtime check: "Run `ng version` to detect the installed Angular version. If v21+, zoneless is the default and no flag is needed. If v17–20, pass `--zoneless` explicitly. Verify the current zoneless behavior in `ng new --help`."

---

**2. Hardcoded folder structure in `angular-setup-project`**

```json
"@core/*": ["./src/app/core/"],
"@shared/*": ["./src/app/shared/"],
"@features/*": ["./src/app/features/"]
```

This assumes every project uses the `core/shared/features` hierarchy, which `scripts/scaffold_structure.sh` enforces. A project using a flat structure, a domain-driven structure (`domains/`), or a Nx library structure would get path aliases pointing to directories that don't exist.

**Fix:** Add a step that reads the actual folder structure created by the scaffold script and derives the path aliases from it, rather than hardcoding them. Or explicitly state: "Adjust these paths to match the actual project folder structure."

---

**3. `pnpm run` hardcoded in `angular-linters` verification steps**

Step 3.0: "Run `pnpm run` to list available scripts and confirm they were added." Step 3.1 through 3.4, Step 4, Steps 6 all use `pnpm run lint` explicitly. But the skill accepts `--package-manager [pnpm|npm|yarn]` as a parameter. If `npm` or `yarn` is passed, these commands are wrong.

**Fix:** Replace all `pnpm run` references with `[pkg-manager] run` and instruct the agent to resolve this from the parameter received from `angular-setup-project` (or detected from `package.json` if invoked standalone).

---

**4. `eslint-plugin-rxjs-x` assumed for all Angular projects**

Step 3.4 adds the RxJS ESLint plugin as a standard step in the pipeline. But Angular 21+ is signals-first. A project built entirely on signals with no RxJS usage will have this plugin installed and configured for zero benefit — and it adds type-aware rule overhead. A green-field Angular 21+ project may never use `Observable` at all.

**Fix:** Make Step 3.4 conditional. Before adding `eslint-plugin-rxjs-x`, check if `rxjs` is in `package.json` dependencies. If not, skip Step 3.4 and log: "RxJS not detected in dependencies — skipping rxjs ESLint plugin."

---

**5. Port 4200 hardcoded in `angular-third-party-integration`**

Step 7D: "navigate to `http://localhost:4200`". A project with a custom `port` in `angular.json` will cause the browser subagent to check the wrong address.

**Fix:** Before starting the dev server in Step 7C, read `angular.json` to detect the configured `port` value. Fall back to 4200 only if not set.

---

## 🔴 ROBUSTNESS GAPS

**1. `scripts/scaffold_structure.sh` has no existence check**

Phase 1, Step 3: "Run `scripts/scaffold_structure.sh`." There is no check that this file exists, is readable, or is executable. If it doesn't exist — which is likely when this skill is used outside its original context — the phase fails with a confusing shell error and no recovery path.

**Fix:** Add an explicit check before running: "Verify `scripts/scaffold_structure.sh` exists and is executable. If not, STOP and inform the user: 'The scaffold script is missing. Please provide it or manually create the `core/`, `shared/`, and `features/` directories under `src/app/`.'"

---

**2. `ng serve` in Phase 1.5 Verification hangs the agent**

"Run `ng serve` and verify the application compiles and serves without errors or warnings." `ng serve` is a blocking long-running process. An agent executing this will hang indefinitely waiting for it to exit.

**Fix:** Replace with: "Run `ng build` to verify the application compiles without errors. If you need to verify the development server, run `ng serve &` in the background, wait 15 seconds, check for startup errors, then kill the process with `kill %1`."

---

**3. `git reset --hard` in `angular-linters` is destructive without a safety check**

"Before running this skill, ensure the git working directory is clean." This is a warning, not an enforced check. If the user ignores it and has uncommitted work, `git reset --hard` in the failure recovery path will silently destroy their changes.

**Fix:** Make this a hard pre-condition: "Run `git status` before starting. If the working directory is not clean (uncommitted changes exist), ABORT and tell the user: 'Your working directory has uncommitted changes. Please stash or commit them before running this skill, as the failure recovery uses `git reset --hard`.'"

---

**4. Retry loop in `angular-third-party-integration` Step 7B has no exit condition**

"Run `[pkg-manager] run build` again until it passes with Exit Code 0." No maximum retry count, no escalation protocol, no condition under which the agent admits it cannot fix the build and stops trying.

**Fix:** Add: "Retry up to 3 times. If the build does not pass after 3 attempts, STOP the loop. Run `git reset --hard HEAD && git clean -fd` to roll back, then notify the user: 'I was unable to resolve the build failure for [library] after 3 attempts. Here is the last error: [error]. Please inspect and fix manually.'"

---

**5. `git clean -fd` in Step 7E rollback destroys the llms.txt cache**

The rollback command `git reset --hard HEAD && git clean -fd` will delete any newly created `references/cache/*.llms.txt` files because they were untracked. This destroys the documentation work generated in Steps 2–5.

**Fix:** Before the rollback, explicitly copy cache files to a safe location, or add cache files to `.gitignore` so `git clean` skips them. Or use `git clean -fd --exclude='references/cache/'`.

---

**6. Test commit in `angular-linters` Step 5 is permanent**

"Perform a test commit to verify Husky pre-commit hook triggers lint-staged." If this test commit uses a real file or changes, it becomes a permanent part of the git history. The skill never says to undo it.

**Fix:** Specify the exact test commit procedure: "Create a temporary file (e.g., `touch /tmp/hook-test.ts`), stage it with `git add`, attempt a commit with message `test: verify hooks`. After verification succeeds, immediately run `git reset HEAD~1` to undo the commit and `git checkout -- .` to clean the working tree."

---

## 🧠 HALLUCINATION RISKS

**1. `defineConfig` mandate in `angular-linters` is baked-in knowledge with no fetch guard**

The Fundamental Principles section states: "`defineConfig` from `eslint/config` is the mandatory wrapper for ESLint config. Do NOT replace it with `tseslint.config`." This is asserted as fact with no instruction to verify it against current Angular or `@angular-eslint` documentation. If Angular schematics change their default wrapper (which they have between major versions), the agent will confidently apply the wrong standard.

**Fix:** Add a mandatory step before any ESLint configuration: "Check the installed version of `@angular-eslint/schematics`. Fetch the corresponding release notes or changelog from `https://github.com/angular-eslint/angular-eslint/releases` to confirm the correct ESLint config wrapper for this version. Only then apply the configuration standard."

---

**2. `angular-setup-project` Phase 1.5 applies path alias syntax without a version check**

The `tsconfig.json` path alias block is applied with a specific warning about `./` relative prefixes. This is correct for the `esbuild` builder in Angular 17+, but the behavior of TypeScript path resolution differs depending on whether `baseUrl` is set. The skill embeds this as a fixed rule with no instruction to verify it against the current `@angular/build` or TypeScript version being used.

**Fix:** Add: "Before applying path aliases, read the `tsconfig.json` to check if `baseUrl` is already set. If it is, the `./` prefix constraint changes. Cross-reference with the Angular version's `tsconfig` documentation before writing values."

---

**3. Cache in `angular-third-party-integration` has no staleness check**

Step 3 says: "If a `.llms.txt` file for the requested library and version already exists, use it immediately and skip the web fetching." But what if the cache file is 6 months old and the library has had breaking changes? The file naming includes a version (`[library-name]-v[version].llms.txt`) but the skill never checks if the cached version matches the version that will actually be installed.

**Fix:** When reading a cache file, also check: (1) the version in the file header matches the version in `package.json` or the user's requested version, and (2) the generated date is within an acceptable window (e.g., 30 days). If either fails, regenerate the file from the official URL.

---

**4. `references/common-integrations-edge-cases.md` is read without an existence check**

Section 8 says: "Read `references/common-integrations-edge-cases.md`." If this file doesn't exist (first-time use), the agent may silently skip it or — worse — fabricate content based on its own knowledge of common edge cases.

**Fix:** Add: "Check if `references/common-integrations-edge-cases.md` exists. If it does not, create an empty file with a header and proceed. Never assume knowledge about edge cases that is not in this file."

---

## 🔧 OVERFITTING ISSUES

**1. The Spartan UI `expect` example in `angular-third-party-integration`**

The `expect` template is immediately followed by a fully working Spartan UI example command:

```bash
spawn pnpm exec ng g @spartan-ng/cli:ui button --directory libs/ui
```

This reads as a specific past problem with Spartan UI that was solved and embedded into the general skill. An agent working with a different library (Angular Material, PrimeNG) will not find this example helpful and may not recognize it as a specific example rather than a template to follow literally.

**Fix:** Remove the Spartan-specific example from the main skill body. Keep the universal `expect` template only. Move the Spartan-specific example to `references/common-integrations-edge-cases.md` under a "Spartan UI" section.

---

**2. The `// @ts-ignore` directive in `angular-linters`**

"Add `// @ts-ignore` above the `'import-x': importX` line (known type incompatibility with ESLint's `Plugin` type)." This is a workaround for a specific, versioned type incompatibility in `eslint-plugin-import-x`. There's no instruction to check if the current version still has this issue, and no note about when to remove it.

**Fix:** Replace with: "Check the current `eslint-plugin-import-x` version. Run `pnpm run lint` first without `// @ts-ignore`. If you get a TypeScript type error on the plugin registration line, add `// @ts-ignore` above it and add a comment explaining the issue and the affected versions. Check if the issue is resolved in a newer version."

---

**3. Budget values in `angular-setup-project` are a past-project patch**

The budget section starts with: "Angular CLI's defaults (`500kB` warning, `1MB` error) are quickly exceeded by real projects..." and immediately overrides them to 2MB/4MB. This reads as a reaction to hitting Angular's defaults in a real project rather than a principled strategy.

**Fix:** Instead of hardcoding 2MB/4MB, teach the agent the principle: "Angular's default budgets are conservative baselines. Set them based on the expected complexity of the project. For a minimal project without component libraries: keep defaults. For a project with Material/Tailwind/NgRx: start at 2MB/4MB. Document the chosen value in the README so future engineers understand the rationale."

---

**4. `globals` package note in `angular-linters` Step 1**

"Note: The `globals` package is installed as part of this setup." This is a bare fact with no explanation of why it is needed. It reads like a dependency that was found missing once and was added without explanation.

**Fix:** Either explain why it is needed ("ESLint flat config requires explicit global definitions for browser/Node environments; the `globals` package provides them") or integrate this into the installation script documentation where it belongs.

---

## 📝 CLARITY IMPROVEMENTS

**1. The origin of `scripts/scaffold_structure.sh` and `scripts/configure_linters.sh` is never explained**

Both skills reference these scripts as if they are pre-existing. A developer using either skill standalone has no idea where these scripts come from, whether they are part of the skill package, or whether they need to be created.

**Fix:** At the top of each skill that depends on a script, add: "This skill depends on `scripts/configure_linters.sh` (located in the `angular-linters` skill directory). Before running, copy or symlink this script to the project root's `scripts/` directory and make it executable with `chmod +x`."

---

**2. Step 5 test commit in `angular-linters` is under-specified**

"Perform a test commit to verify: Husky pre-commit hook triggers lint-staged. Commitlint validates conventional commit messages."

What file should be staged? What commit message? What counts as success? An agent following this literally might commit a random file with a non-compliant message to test Commitlint, or nothing at all.

**Fix:** Rewrite as: "Create a temporary test file (`echo '' > /tmp/lint-staged-test.ts && cp /tmp/lint-staged-test.ts src/lint-staged-test.ts`). Stage it with `git add src/lint-staged-test.ts`. Attempt a commit with a bad message (`git commit -m 'bad commit'`) — Commitlint MUST reject it. Then attempt with a valid message (`git commit -m 'test: verify hooks'`) — it MUST succeed. Immediately undo with `git reset HEAD~1` and remove the test file."

---

**3. Phase 1.5 JSON merging is labeled "intelligent merging" with no guidance**

"These configuration changes cannot be scripted because they require intelligent JSON merging. The Agent handles them directly." But there is no guidance on what to do when existing values conflict with the values being added (e.g., `tsconfig.json` already has a `paths` key, or `angular.json` already has budgets configured).

**Fix:** Add: "Before writing any value, read the existing file. If the key already exists, compare the current value with the intended value. If they conflict, report the conflict to the user and ask which value to keep. Never silently overwrite existing configuration."

---

**4. The Pre-Requisite Dependency Check in `angular-third-party-integration` is ambiguous**

"If the requested library explicitly references a foundational peer dependency (e.g., a core CSS library, state management library, or any other required peer dependency), you MUST fetch (if exist in extracted llms.txt content) or prompt the user for the documentation URL of that underlying library as well if it's missing."

The phrase "if exist in extracted llms.txt content" makes this sentence nearly incomprehensible.

**Fix:** Rewrite as: "After generating the llms.txt file for a library, scan the 'Installation & Setup' section for required peer dependencies. For each peer dependency listed: (1) check if it is already installed in `package.json`; (2) if it is not installed, ask the user to provide the documentation URL for that dependency before proceeding with the main library integration."

---

## 🛡️ COMPATIBILITY GUARD GAPS

**1. No compatibility guard exists anywhere in the system**

None of the three skills have a compatibility matrix. `angular-setup-project` hands off to `angular-third-party-integration` with a raw list of user-requested libraries. `angular-third-party-integration` installs them sequentially with no pre-check for mutual incompatibility.

A user requesting `[Tailwind CSS, Angular Material, Bootstrap]` will get all three installed, which is a valid but likely conflicting combination. The only detection is a failed build at Step 7B — after the first library is already committed.

**Fix:** Add a pre-loop compatibility check to `angular-third-party-integration` Step 7 before the sequential loop starts: "Before beginning the sequential installation loop, scan the full list of requested libraries and flag known incompatible combinations from `references/common-integrations-edge-cases.md`. Present conflicts to the user and require explicit confirmation before proceeding."

---

**2. `angular-linters` has no ESLint version compatibility check**

The skill assumes flat config (`eslint.config.js`) throughout. ESLint flat config became the default in ESLint 9+. If the project has ESLint 8 installed, `ng add @angular-eslint/schematics` may generate the legacy `.eslintrc.json` format instead. The skill has no detection or recovery path for this case.

**Fix:** After Step 1 (installation), check which ESLint config file was generated. If `.eslintrc.json` or `.eslintrc.js` exists instead of `eslint.config.js`, STOP and tell the user: "Your project uses the legacy ESLint config format. This skill requires ESLint 9+ with flat config. Please upgrade ESLint or run `ng add @angular-eslint/schematics` to migrate."

---

**3. The `angular-linters` plugin stack assumes no conflicts with Angular's auto-generated config**

Step 3.2 adds `eslint-plugin-prettier/recommended` and `eslint-config-prettier` as the last two entries in `defineConfig`. Step 3.3 adds `import-x`. Step 3.4 adds `rxjs-x`. But the auto-generated Angular ESLint config from `ng add @angular-eslint/schematics` already includes certain rules. If there are conflicts between Angular's template rules and Prettier's formatting rules, the skill relies on Prettier being last as an implicit resolution — but this is not stated as a principle, just a position.

**Fix:** Add: "Prettier integration entries MUST be last in the `defineConfig` array. This is required because `eslint-config-prettier` disables all formatting rules from all preceding configs. Adding any config after Prettier may re-enable formatting conflicts."

---

## 🔗 SYSTEM INTEGRITY GAPS

**1. The contract between `angular-setup-project` and `angular-linters` is informal**

`angular-setup-project` says: "Pass the `--style` and `--package-manager` values." But there is no formal definition of what `angular-linters` expects, what it returns, or what "success" looks like from the parent skill's perspective. If `angular-linters` fails partway through (e.g., at Step 3.3), should `angular-setup-project` retry from scratch, retry from Step 3.3, or abort?

**Fix:** Define an explicit contract at the top of `angular-linters`: "**Inputs**: `--style [css|scss]`, `--package-manager [npm|yarn|pnpm]`. **Success condition**: All steps 1–8 complete with `ng lint`, `lint:styles`, and `format` passing. **On failure**: Report the failed step and command to the parent skill. Do not attempt partial recovery — the parent skill must decide whether to retry or abort."

---

**2. `angular-linters` and `angular-third-party-integration` both depend on a clean git state, but neither defines what "clean" means**

"Ensure the git working directory is clean" appears in both skills. But "clean" can mean different things: no unstaged changes, no staged changes, no untracked files. `git status` distinguishes between all three. If the definition is inconsistent, one skill might run safely while another fails unexpectedly.

**Fix:** Standardize the definition across all skills: "A clean working directory means `git status` reports `nothing to commit, working tree clean`. Staged but uncommitted changes count as unclean. Run `git status` and check the exact output before proceeding."

---

**3. Adding a new sub-skill would require rewriting `angular-setup-project`'s Phase 3 section**

The Phase 3 transition explicitly names `angular-third-party-integration` as the next skill. If a new sub-skill is added (e.g., `angular-i18n-setup` or `angular-auth-setup`), Phase 3 must be manually updated. There is no generic skill dispatch mechanism.

**Fix:** Replace the hardcoded skill name in Phase 3 with a generic routing instruction: "After the quality layer is complete, present the user with the available post-setup skills and ask which integrations they want to apply. Invoke the appropriate skill based on the user's response." Maintain a list of available post-setup skills in a separate file or at the top of `angular-setup-project`.

---

**4. The `references/cache/` directory in `angular-third-party-integration` is implicitly shared across projects**

The cache is written to `references/cache/` within the skill's directory — not within the project being set up. This means cache files are shared across all projects using this skill. If two projects use different versions of the same library, the cache could serve stale content to one of them without warning.

**Fix:** Either scope the cache to the project (e.g., write to `[project-root]/.angular-skill-cache/`) or add a mandatory version validation step when reading from cache, as noted in the hallucination section above.

---

## 🎯 TOP 3 PRIORITIES

**Priority 1: Hallucination risk in `angular-linters` — no fetch-first guard for ESLint configuration**

This is the most dangerous gap in the system. The `angular-linters` skill embeds specific API knowledge (`defineConfig`, plugin registration patterns, `@ts-ignore` workarounds) as fixed facts, but Angular's ESLint tooling has changed significantly between v17 and v21, and will continue to change. The agent will silently apply stale knowledge with high confidence because the Fundamental Principles section states it as a mandate rather than a live reference. The `references/` files partially solve this, but they are not version-pinned and not validated at invocation time. The fix is a mandatory version check + documentation fetch step before any ESLint configuration begins.

**Priority 2: No compatibility guard in the system — libraries can be installed blindly**

The three skills together form a complete Angular project setup pipeline, but there is zero cross-library compatibility checking at any point. `angular-setup-project` collects a list of third-party libraries and passes it directly to `angular-third-party-integration`, which installs them sequentially with no pre-screening. The only failure detection is a broken build (Step 7B), which happens after one library is already committed. Two mutually incompatible CSS frameworks, a conflicting state management library, or a peer dependency version mismatch will not be caught until the build fails — and the rollback at that point is destructive. A compatibility check before the loop begins is mandatory.

**Priority 3: Shell script dependencies are unvalidated hard failures**

Both `angular-setup-project` (`scripts/scaffold_structure.sh`) and `angular-linters` (`scripts/configure_linters.sh`) depend on shell scripts that are never validated before being called. Neither skill explains where these scripts come from, how to obtain them if missing, or what to do if they fail. These scripts are the most critical steps in their respective skills — the entire Phase 1 and Phase 1.5 depend on them. An agent encountering a missing script will produce a confusing shell error with no recovery path, and a developer using these skills standalone (without the full `cye` workspace) has no way to know these scripts need to exist. Each skill must validate script existence, explain its origin, and define a clear fallback.

--
GPT 5.4 review

### ✅ WHAT WORKS WELL

- `angular-setup-project` has a sane high-level flow: discovery first, scaffold second, quality layer third, third-party integrations last. That ordering is good.
- `angular-linters` correctly treats config changes as an incremental pipeline with `MUST pass` gates. That is the right shape for reducing compound failures.
- `angular-third-party-integration` has the right core instinct: require official docs, integrate one library at a time, verify build and runtime, and treat secrets as a separate security decision.
- The third-party skill’s “proof of life” idea is strong. Build success alone is not enough for UI libraries and runtime integrations.
- The linters skill’s use of local reference files as an explicit source of truth is better than leaving the agent to improvise config structure from memory.

### ⚠️ GENERICITY ISSUES

- `angular-setup-project` is over-tied to Angular 21. Statements like “Zoneless: enabled (Angular 21 default — no flag needed)” are version-specific and will age badly.
  Fix: replace with “Detect Angular version first, then derive the correct CLI flags and defaults from Angular CLI docs or project version.”
- `angular-setup-project` hardcodes a specific app structure: `core/`, `shared/`, `features/`.
  Why it is a problem: that is an opinionated architecture, not a generic bootstrap requirement.
  Fix: make this an optional project structure preset, not a mandatory step.
- `angular-setup-project` hardcodes path aliases `@core`, `@shared`, `@features`.
  Why it is a problem: these aliases only make sense if that exact folder model exists.
  Fix: define aliases only if the selected structure preset requires them.
- `angular-setup-project` hardcodes bundle budgets (`2MB`/`4MB`) as “real-world” defaults.
  Why it is a problem: that is policy, not a universal truth. It may be too loose for some teams and too strict for others.
  Fix: frame budgets as configurable profiles like `strict`, `balanced`, `permissive`.
- `angular-linters` claims `defineConfig` is mandatory for Angular `v19+ and v21+`.
  Why it is a problem: this is oddly version-shaped and already smells stale.
  Fix: say “use the current Angular-generated flat config pattern for the detected Angular version.”
- `angular-linters` uses `pnpm run ...` in multiple validation steps even though the skill claims to support `pnpm`, `npm`, and `yarn`.
  Fix: abstract every command as `[pkg-manager] run <script>` and define the mapping once.
- `angular-third-party-integration` assumes all integrations can be validated by temporarily editing `src/app/app.component.html`.
  Why it is a problem: that breaks for libraries without UI output, libraries integrated at route level, workspace libraries, or nonstandard app roots.
  Fix: require a library-specific verification target chosen from the docs: DOM proof, HTTP call proof, provider registration proof, CLI output proof, etc.
- `angular-third-party-integration` assumes docs URLs are sufficient for compatibility decisions.
  Why it is a problem: many official docs do not spell out the exact Angular/peer/version matrix.
  Fix: also check package metadata and peer dependencies before install.

### 🔴 ROBUSTNESS GAPS

- `angular-linters` says “ensure the git working directory is clean” and then “if any step fails, MUST run `git reset --hard`.”
  Why it is a problem: this is destructive, unsafe, and will wipe unrelated user work.
  Fix: replace with “stop, report the failure, and either use a dedicated worktree/stash/commit checkpoint or ask before rollback.”
- `angular-third-party-integration` says runtime failure should trigger `git reset --hard HEAD` and `git clean -fd`.
  Why it is a problem: same issue, worse. This can destroy untracked files too.
  Fix: create an explicit rollback boundary before each integration using a temporary branch, worktree, or user-approved commit.
- `angular-setup-project` says failed project creation must delete the generated project directory.
  Why it is a problem: it never defines how to safely identify the exact generated directory, so a bad path calculation could delete the wrong folder.
  Fix: record the target directory before creation and only remove it if it was created by the current run and contains the expected Angular scaffold markers.
- `angular-third-party-integration` requires the user to confirm the foundation works, but has no path if the user says “it mostly works” or gives an incomplete answer.
  Fix: define three branches: `confirmed healthy`, `unclear`, `failing`. Only the first continues; the others switch to diagnosis.
- `angular-linters` has many “MUST pass before proceeding” checks but no failure taxonomy.
  Why it is a problem: not every failure should stop the whole pipeline. Missing git for Husky is a hard block for hook setup, but not for ESLint/Prettier.
  Fix: label checks as `hard stop`, `soft stop`, or `warn and continue`.
- `angular-third-party-integration` has a pseudo-TTY strategy, but no explicit timeout, no retry limit, and no post-prompt sanity check beyond “continue with build.”
  Fix: add “one non-interactive attempt, one PTY attempt, then handoff; after any successful prompt flow, verify actual file changes occurred.”
- `angular-setup-project` says Phase 1.5 changes “cannot be scripted.”
  Why it is a problem: that is both false and operationally weak. If an agent can do it manually, a deterministic transform can also be designed.
  Fix: say “these changes require schema-aware edits and verification” instead.

### 🧠 HALLUCINATION RISKS

- None of the three skills enforce Angular CLI MCP usage even though these are Angular-specific and version-sensitive workflows.
  Why it is a problem: the agent can silently rely on stale Angular knowledge.
  Fix: add a mandatory first step: `list_projects` or workspace detection, then `get_best_practices`, then `search_documentation`/`find_examples` for version-sensitive behavior.
- `angular-linters` treats local `references/` as the absolute source of truth.
  Why it is a problem: local references can become stale, and the skill gives the agent no way to detect that.
  Fix: make references “primary local baseline,” but require cross-checking version-sensitive package behavior against official docs/package metadata.
- `angular-third-party-integration` says generate `.llms.txt` from docs and then use that as the primary context.
  Why it is a problem: the generation step itself can hallucinate or omit crucial constraints.
  Fix: require source-attributed extraction: every command, version constraint, and config change in `.llms.txt` must include the source URL section it came from.
- `angular-third-party-integration` allows cache reuse from `references/cache/` without any freshness rule.
  Why it is a problem: cached docs can silently become outdated.
  Fix: add cache invalidation criteria: library version mismatch, Angular version mismatch, or cache older than a defined threshold.
- `angular-setup-project` hardcodes claims about defaults and flags instead of requiring the agent to verify them from Angular docs first.
  Fix: replace assertions with “detect, fetch, verify, then execute.”

### 🔧 OVERFITTING ISSUES

- `angular-setup-project` says “Do NOT suggest advanced features like Tailwind CSS, Spartan UI, or SignalStore in this phase.”
  Why it is a problem: this reads like a patch for a past conversation, not a generic rule.
  Fix: replace with “Do not introduce optional third-party integrations during foundational project creation.”
- `angular-linters` says to add `// @ts-ignore` above the `'import-x': importX` line.
  Why it is a problem: that is a workaround for one known type mismatch, not a general policy.
  Fix: phrase it as conditional guidance: “If the detected package versions trigger the known plugin typing issue, apply the minimal documented suppression and annotate why.”
- `angular-third-party-integration` names specific failure examples like “SSR bundling quirks” and “style layering conflicts,” then tells the agent to remember them as improvement points.
  Why it is a problem: the intent is good, but the wording is history-shaped.
  Fix: define a generic rule: “Capture any recurring failure class that required non-obvious intervention.”
- `angular-third-party-integration` strongly centers `expect` on macOS/Linux.
  Why it is a problem: this is a tactical patch around one environment limitation.
  Fix: define the principle first: “prefer non-interactive mode, then PTY automation if available, then human handoff.” Put `expect` under “example implementation,” not as the canonical path.
- `angular-setup-project` mandates the quality stack as always included.
  Why it is a problem: it may be reasonable for this author’s environment, but it is not inherently universal.
  Fix: make it a skill policy with a clear rationale and an explicit escape hatch if the user asks for a minimal prototype.

### 📝 CLARITY IMPROVEMENTS

- Ambiguous: “verify the availability of critical dependencies.”
  Rewrite: “Run explicit checks for `node`, `ng`, the selected package manager, and `git`. If any required binary is missing, stop and report the exact missing command and install step.”
- Ambiguous: “check if `angular.json` already exists in the current directory or parent directories.”
  Rewrite: “Search upward from the current directory to the filesystem root for `angular.json`. If found, stop and report the exact workspace path. Do not create a new Angular app inside an existing Angular workspace unless the user explicitly asked for a nested workspace.”
- Ambiguous: “These configuration changes cannot be scripted.”
  Rewrite: “These configuration changes require schema-aware edits and post-edit verification. Apply them with structured edits, then validate the modified JSON.”
- Ambiguous: “Read all files in the `references/` directory.”
  Rewrite: “Read the specific reference files needed for the current step before editing. At minimum: `eslint-config-template.md`, the plugin-specific reference for the plugin being added, and `validation-testing.md` before Step 7.”
- Ambiguous: “Perform a test commit to verify.”
  Rewrite: “Create a temporary validation change in a disposable file, stage it, run a conventional test commit, confirm both Husky hooks ran, then remove the test artifact without rewriting unrelated history.”
- Ambiguous: “Use your URL reading tools to retrieve the EXACT URL.”
  Rewrite: “Fetch the exact user-provided URL directly. If the fetch returns a non-doc page, redirect, auth wall, or partial preview, stop and ask the user for a better official doc page instead of substituting another source.”
- Ambiguous: “Present the complete generated `.llms.txt` files to the user for review.”
  Rewrite: “Save the generated `.llms.txt` files, then present a concise summary of the extracted install steps, detected compatibility constraints, and planned file changes. Only print full file contents if the user asks.”
- Ambiguous: “Browser Subagent.”
  Rewrite: “Use the available browser automation tool or browser-focused subagent to verify the runtime behavior. If no browser automation is available, ask the user for manual confirmation.”

### 🛡️ COMPATIBILITY GUARD GAPS

- There is no actual compatibility matrix anywhere.
  Why it is a problem: the skills talk about compatibility, but they do not encode it in a maintainable form.
  Fix: add a data file like `references/compatibility-matrix.json` keyed by Angular major, package manager, SSR mode, style format, and tool/library family.
- The guard does not clearly run before installation in `angular-linters`.
  Fix: before any install, validate Angular major, Node major, package manager, git availability, and known package incompatibilities.
- `angular-third-party-integration` checks peer dependencies only if the requested library “explicitly references” them.
  Why it is a problem: many packages rely on peer deps that are not obvious from docs.
  Fix: inspect package metadata for `peerDependencies` and compare them against the detected project versions before install.
- There is no compatibility guard for `@angular-eslint`, ESLint, and Angular major alignment.
  Fix: encode a guard that selects supported major combinations and stops with a human-readable conflict explanation when unsupported.
- There is no compatibility guard for CSS vs SCSS stylelint config beyond installing one of two packages.
  Fix: verify the project’s actual style files and builder configuration before picking Stylelint packages and script globs.
- There is no compatibility guard for SSR-sensitive libraries in the third-party skill.
  Fix: add a pre-install check: “Does the library document SSR support, browser-only APIs, or required server config?” If unknown, mark as risky before install.
- There is no compatibility guard for Windows in the prompt automation flow.
  Fix: define platform-specific strategies up front and mark unsupported automation paths clearly before execution starts.

### 🔗 SYSTEM INTEGRITY GAPS

- The biggest system break: the skills use relative paths like `scripts/scaffold_structure.sh`, `scripts/configure_linters.sh`, and `references/...` without defining whether those paths are relative to the skill directory or the target project.
  Why it is a problem: after `ng new`, the working directory is the Angular project, so these relative paths will not resolve.
  Fix: define a strict contract: “All skill-owned assets are resolved relative to the skill file’s directory, never the project root.”
- `angular-setup-project` depends on `angular-linters`, but the contract is informal.
  Missing contract: what inputs are passed, what success artifacts are returned, and what constitutes completion.
  Fix: define explicit input/output:
  Input: project root, package manager, style format.
  Output: installed deps, config files created, scripts added, verification results.
- `angular-setup-project` depends on `angular-third-party-integration`, but again no explicit contract exists.
  Fix: define required inputs:
  project root, Angular version, package manager, selected libraries, official doc URLs.
  Define output:
  per-library verification result, files changed, unresolved risks.
- `angular-third-party-integration` refers to `references/cache/` and `references/common-integrations-edge-cases.md`, but those files/directories do not exist in the skill.
  Why it is a problem: this is a broken runtime dependency, not just a documentation issue.
  Fix: add the missing directories/files or rewrite the skill to create them on demand before use.
- `angular-third-party-integration` refers to `browser_subagent`, but the actual tooling contract is not defined that way.
  Fix: name the capability generically and reference the actual available mechanism, not a made-up interface.
- `angular-linters` mixes script-generated config, agent-authored config, and reference-driven config, but never defines ownership boundaries cleanly.
  Why it is a problem: future edits can easily clobber generated files or duplicate responsibilities.
  Fix: explicitly mark which files the script owns, which files the agent owns, and which files are shared merge targets.
- Adding a new third-party integration sub-skill would currently require editing the meta-skill logic because the system is not data-driven.
  Fix: move library-specific knowledge into cache/reference files and keep the orchestrator generic.

### 🎯 TOP 3 PRIORITIES

1. Remove destructive recovery instructions.
   Why first: `git reset --hard` and `git clean -fd` make the skills unsafe by default. A skill that can destroy user work is not production-ready, no matter how good the rest is.

2. Fix the cross-skill contract and path resolution model.
   Why first: right now the system is internally inconsistent. Relative paths are undefined, referenced files are missing, and tool names do not match reality. That means the skills can fail even when the agent behaves correctly.

3. Replace hardcoded version assumptions with a fetch-first compatibility layer.
   Why first: Angular, ESLint, and third-party libraries change too fast for static claims like “Angular 21 default” or “use this wrapper” to stay reliable. The skills need explicit version detection, official-doc verification, and a maintainable compatibility matrix before installation starts.

---

Cursor's Composer 2

Here is a structured review of the three skills as a single system.

---

### ✅ WHAT WORKS WELL

- **Clear sequencing**: Setup → linters → third-party is a sensible pipeline; setup explicitly defers advanced integrations to the orchestrator skill.
- **angular-linters “references first”**: Stating that `references/` is the source of truth and pairing it with incremental ESLint steps and MUST-pass gates reduces config drift.
- **angular-setup-project safety**: Aborting when `angular.json` already exists and requiring explicit confirmation before `ng new` avoids destructive mistakes.
- **angular-third-party-integration**: One-library-at-a-time loop, build-before-playground, and explicit rollback on failed verification are strong patterns for real integrations.
- **Documentation URL requirement** (third-party): Asking for official URLs and blocking blind web search without consent directly targets hallucinated install steps.
- **Interactive CLI handling**: Tiered approach (flags → expect → user) acknowledges a real failure mode (non-TTY generators) instead of pretending every project is the same.

---

### ⚠️ GENERICITY ISSUES

- **Angular 21 / zoneless baked in** (`angular-setup-project`): Text assumes “Angular 21 default — no flag needed” and specific `ng new` behavior. That breaks on Angular 18–20 or future majors with different defaults. **Fix:** Add a single “version discovery” step: read `ng version` / target from user _before_ stating defaults, and phrase “zoneless” as “match current CLI defaults for the detected major version” with a pointer to `ng new --help` for that version.
- **Default package manager** (`angular-setup-project`): Defaulting to `pnpm` is an opinion, not universal (corporate npm mirrors, yarn-only CI). **Fix:** Default to “detect from lockfile or user choice; if none, present all three equally.”
- **`scripts/scaffold_structure.sh` and `scripts/configure_linters.sh`**: Skills assume these paths exist next to the skill or in the repo. On a greenfield repo with only the skill copied, the script is missing. **Fix:** State the contract: “These scripts MUST ship with the skill bundle; if missing, STOP and tell the user to install the full skill package or run equivalent steps manually.”
- **`pnpm run` everywhere** (`angular-linters`): Steps 3.1–6.6 use `pnpm run lint` while Phase 1 may have chosen npm/yarn. **Fix:** Always use `[package-manager]` or “the package manager from Phase 1 / `package.json` engines” in every command example.
- **Lint-staged globs** (`angular-linters`): Example shows `*.css` only; SCSS projects need `*.scss` or combined patterns. **Fix:** Tie globs to the `--style` from the script: “mirror `configure_linters.sh` style flag in lint-staged.”
- **`browser_subagent`** (`angular-third-party-integration`): Tool name may not exist in the user’s environment. **Fix:** “Use whatever browser automation / MCP is available; if none, fall back to user verification” with a single detection rule, not a hardcoded tool name.
- **`references/cache/`** path: Assumes the skill is installed with writable cache. **Fix:** Allow project-local cache (e.g. `.angular-integration-cache/`) when the skill directory is read-only.

---

### 🔴 ROBUSTNESS GAPS

- **`git reset --hard` on any failure** (`angular-linters`): Destroys uncommitted work unrelated to the skill if the user had a dirty tree (violates the stated “clean working directory” prerequisite in practice). **Fix:** HARD stop if `git status` is not clean; on failure, prefer `git stash push` or revert only touched files listed at skill start, not wholesale `--hard`.
- **Delete failed `ng new` directory** (`angular-setup-project`): Good intent, but risky if `ng new` partially created files in a non-empty directory or mixed with user files. **Fix:** Only delete the path explicitly passed to `ng new` and confirm it is empty or solely created by the failed run (e.g. check for only expected scaffolding).
- **User must “run start script” manually** (`angular-third-party-integration` §1): Blocks automation; also “no proceed until user confirms” can deadlock in CI. **Fix:** Define two modes: **interactive** (current) and **CI/automation** (agent runs `build` + `test` as foundation proof, user confirmation optional).
- **Fetch/cache failure** (`angular-third-party-integration`): No explicit “if URL returns 403/404/empty” branch. **Fix:** HARD failure with message; offer retry with mirror URL, different doc version, or user-pasted HTML; never silent fallback to model knowledge.
- **`expect` on Linux** (`angular-third-party-integration`): “Ships on macOS, common on Linux” is false for minimal Linux images. **Fix:** Tier 2 should start with `command -v expect` or document failure → Tier 3 immediately.
- **Parallel dev server + port** (`angular-third-party-integration` 7C): `localhost:4200` may be wrong. **Fix:** Read port from `angular.json` / env or parse `ng serve` output.
- **Rollback on verification failure** (`angular-third-party-integration` 7E): `git reset --hard` loses commits if integration was committed in a broken state; here it says rollback before commit — good — but if someone commits early, the instruction is dangerous. **Fix:** “Rollback only uncommitted changes; if committed, revert commit SHA.”

---

### 🧠 HALLUCINATION RISKS

- **“Angular v21+ auto-generates prettier in package.json”** (`angular-linters`): Version-specific claim can be wrong for older or newer schematics. **Fix:** “Read `package.json` after `ng add`; if no `prettier` key, follow `references/prettier.md` to add one” — never assume without reading the file.
- **Exclude “Deprecated APIs” from llms.txt** (`angular-third-party-integration` §5): Requires judgment; the model might drop still-needed deprecations. **Fix:** “Exclude deprecated APIs **only when** the official page marks them deprecated and an alternative is shown; otherwise include with deprecation note.”
- **“DOCUMENTATION SOURCE RULE: favor angular.dev for Tailwind”** (`angular-third-party-integration` §8): Can produce incomplete Tailwind v4+ install if Angular’s guide lags. **Fix:** Require **primary** official URL user provided + **supplement** with framework guide when both exist, with explicit conflict resolution: “prefer user’s install URL for package names; use angular.dev for Angular-specific wiring.”
- **Path aliases in Phase 1.5** (`angular-setup-project`): Snippet omits `baseUrl` — the doc warns about TS5090 but the JSON block doesn’t show `baseUrl: "."`. **Fix:** Include `baseUrl` in the canonical example so agents don’t copy a broken fragment.

---

### 🔧 OVERFITTING ISSUES

- **`// @ts-ignore` for import-x** (`angular-linters`): Looks like a one-off type workaround. **Fix:** Prefer `// @ts-expect-error` with one-line reason, or a typed adapter pattern from references; frame as “ESLint plugin typing mismatch” as a general class of plugin issues.
- **Specific budget numbers** (`angular-setup-project`): 2MB/4MB is a past pain tolerance, not a universal law. **Fix:** “Set budgets from team SLO; default starter values are X with rationale; tighten when bundle analysis is in place.”
- **Spartan CLI `expect` example** (`angular-third-party-integration`): Very specific; good as an example but risks copy-paste to wrong projects. **Fix:** Keep in `references/` as an example; in SKILL, say “see examples in references/pty-generators.md” only.
- **“Improvement points” messaging** (`angular-third-party-integration` 7.0A): Meta-process is useful but can bloat every session. **Fix:** Only capture when a **new** failure mode appears, not every minor friction.

---

### 📝 CLARITY IMPROVEMENTS

- **“Each configuration step must pass linting before proceeding”** (`angular-setup-project` Phase 2): **Ambiguous** — does “each step” mean each sub-step in angular-linters or each plugin? **Rewrite:** “In `angular-linters`, do not add the next ESLint plugin until `pnpm|npm|yarn run lint` exits 0 for the current config.”
- **“Read all files in `references/`”** (`angular-linters` Step 1): **Too broad** for large dirs. **Rewrite:** “Read `references/README.md` (or an index) if present; then read only files referenced by the current step’s checklist.”
- **“MUST complete validation checklist”** (`angular-linters` Step 7): **Ambiguous** whether creating real rule violations in the user repo is acceptable. **Rewrite:** “Perform validation in a disposable branch or restore files after; do not leave intentional violations in `main`.”
- **“Present complete llms.txt to user for review”** (`angular-third-party-integration`): **Ambiguous** for huge docs. **Rewrite:** “Present the file path + section summary + installation command block; full file optional on request.”

---

### 🛡️ COMPATIBILITY GUARD GAPS

- **No matrix**: None of the three skills define a structured compatibility matrix (Angular major × Node × ESLint flat config × library). **Fix:** In `angular-third-party-integration`, add a **pre-install** table: rows = requested libraries; columns = detected Angular version, Node, package manager; cells = peer deps from official docs or “unknown — confirm with URL.” Block install on **known** peer conflicts until user acknowledges.
- **Order of integrations**: “Sequential loop” helps but doesn’t encode **dependency order** (e.g. CDK before Material). **Fix:** “Topological sort: peer deps and official doc ‘prerequisites’ sections before dependents.”
- **ESLint / TypeScript / parserOptions** (`angular-linters`): RxJS-x needs type-aware rules — good — but no guard for “Angular version doesn’t support `projectService` the same way.” **Fix:** One reference file “minimum ESLint–TS–Angular matrix” updated per major.

---

### 🔗 SYSTEM INTEGRITY GAPS

- **No explicit I/O contract**: Meta-skill doesn’t define **artifacts passed** between skills (e.g. “Phase 1 outputs: `projectName`, `packageManager`, `style`, `ssr`, `zoneless` as a small manifest”). Linters and third-party infer from files only. **Fix:** Add a **PROJECT_SETUP.md** or JSON snippet generated in Phase 1 that downstream skills MUST read.
- **angular-linters** doesn’t reference **angular-third-party-integration** and vice versa — OK, but **third-party** runs `lint`/`format` assuming linters skill completed; if not, commands fail with no “invoke angular-linters first.” **Fix:** In third-party, “If `lint` script missing, STOP: run `angular-linters` or minimal ESLint setup.”
- **Adding a new sub-skill**: No extension point (e.g. “angular-testing” after linters). **Fix:** Document ordered hooks: `setup → linters → [optional testing skill] → third-party`.
- **Cache location in skill repo** (`angular-third-party-integration`): Committed cache can bloat the repo; `.gitignore` policy not stated. **Fix:** “Cache is local-only; never commit unless team policy says otherwise.”

---

### 🎯 TOP 3 PRIORITIES

1. **Align package manager and commands across all three skills** — Right now `angular-setup-project` allows npm/yarn but `angular-linters` examples are pnpm-heavy; this causes real execution failures and is the highest-impact fix.

2. **Replace destructive git behavior with scoped recovery** — `git reset --hard` as default failure recovery is unsafe; it undermines trust and can destroy user work. Narrow rollback to touched paths or explicit stash.

3. **Harden the third-party “no hallucination” path when fetches fail** — You already require URLs; add explicit HARD/SOFT outcomes for failed fetches, empty pages, and doc–CLI version skew, and forbid silent model improvisation. This is the core promise of that skill.

---

If you want follow-up work, the highest leverage edits are: (1) a short **cross-skill manifest** + package-manager placeholder convention, and (2) a **failure-mode appendix** (fetch, git, expect) with HARD vs SOFT rules in `angular-third-party-integration` and `angular-linters` only where destructive actions are mentioned.
