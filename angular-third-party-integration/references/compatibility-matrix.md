# Compatibility Matrix

Pre-install guard for known library prerequisites and dependency requirements. The agent **MUST** check this matrix **BEFORE** starting the Sequential Execution Loop (Step 7).

## How to Use

1. For each requested library, look up its row in the matrix below.
2. If a **PREREQUISITE** is listed, reorder the installation to install the prerequisite first.
3. If the Angular version is outside the **SUPPORTED** range, **WARN** the user.
4. If the matrix has **no entry** for a library, log a warning and proceed — the matrix only covers known cases.

## Matrix

| Library | Prerequisites | Min Angular | Manual Actions | Notes |
|---------|--------------|-------------|----------------|-------|
| @angular/material | @angular/cdk (same version) | 17 | No | CDK installed automatically by `ng add` |
| @angular/cdk | -- | 17 | No | Often implicit; check if already present |
| tailwindcss | -- | 17 | No | v4 uses CSS-first config with `@tailwindcss/postcss`; v3 uses JS config |
| @spartan-ng/ui | tailwindcss, @angular/cdk | 17 | No | CLI uses fuzzy-search prompt; `expect` automation requires typing app name then Enter |
| prismjs | -- | -- | No | Pure JS library; add theme CSS to angular.json styles; use `afterNextRender` for SSR safety |
| @ngrx/signals | -- | 17 | No | Standalone injectable; no module registration needed |
| ngx-quill | quill ^2.0.0, @angular/forms | 19 | No | v29+ for Angular 21; `provideQuillConfig()` for standalone; syntax module requires prismjs |
| html2canvas | -- | -- | No | Browser-only; use dynamic `import()` for SSR apps |
| genkit | @angular/ssr (server routing) | 19 | Yes | Server-side only via Express routes; see llms.txt for required manual actions |

## Extending This Matrix

When the agent encounters a new prerequisite or version constraint during integration, it **MUST** add a row to this table before completing Step 10.

Keep entries factual:
- **Prerequisites**: Only list if the library will not install or function without the dependency.
- **Min Angular**: Only list if the library explicitly declares a minimum Angular peer dependency.
- **Manual Actions**: `Yes` if the library's llms.txt contains required manual actions; `No` otherwise. This is a quick flag — the details live in the llms.txt cache file.
- **Notes**: Brief, factual context. Do not editorialize.

## Pre-Install Guard Protocol

Before entering the sequential loop (Step 7):

1. Load this matrix.
2. For each requested library:
   a. Check if it has a row in the matrix.
   b. If it has prerequisites not already installed in the project, prepend them to the install order.
   c. If the project's Angular version is below the minimum, **WARN** the user and ask for confirmation.
3. Reorder the library list by dependency (prerequisites before dependents — topological sort).
4. Present the resolved install order to the user for confirmation.
5. Only then enter the Step 7 loop.
