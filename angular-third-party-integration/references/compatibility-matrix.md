# Compatibility Matrix

Pre-install guard for known library prerequisites and dependency requirements. The agent **MUST** check this matrix **BEFORE** starting the Sequential Execution Loop (Step 7).

## How to Use

1. For each requested library, look up its row in the matrix below.
2. If a **PREREQUISITE** is listed, reorder the installation to install the prerequisite first.
3. If the Angular version is outside the **SUPPORTED** range, **WARN** the user.
4. If the matrix has **no entry** for a library, log a warning and proceed — the matrix only covers known cases.

## Matrix

| Library | Prerequisites | Min Angular | Notes |
|---------|--------------|-------------|-------|
| @angular/material | @angular/cdk (same version) | 17 | CDK installed automatically by `ng add` |
| @angular/cdk | -- | 17 | Often implicit; check if already present |
| tailwindcss | -- | 17 | v4 uses CSS-first config; v3 uses JS config |
| @spartan-ng/ui | @angular/cdk | 17 | Depends on CDK primitives |

## Extending This Matrix

When the agent encounters a new prerequisite or version constraint during integration, it **MUST** add a row to this table before completing Step 10.

Keep entries factual:
- **Prerequisites**: Only list if the library will not install or function without the dependency.
- **Min Angular**: Only list if the library explicitly declares a minimum Angular peer dependency.
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
