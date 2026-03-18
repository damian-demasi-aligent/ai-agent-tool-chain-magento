# Onboarding — Development with Claude Code

> New to this repo? Read this first. It covers the project structure, the key mental models you need, and how to use the AI tooling to get up to speed quickly.

---

## What this project is

Read **CLAUDE.md** at the repo root for the full project overview, including the Magento version, vendor namespace, frontend approach (React + Vite, PWA, Hyvä, or pure Luma), theme path, and module inventory. CLAUDE.md is the single source of truth for project-specific details.

If the project uses a hybrid Magento + React architecture, these two worlds coexist on every page. Understanding where the boundary is — and how data crosses it — is the single most important mental model for working here.

---

## Repository structure

The project follows a standard Magento 2 layout. Check CLAUDE.md's **Architecture** section for the full directory tree, including:

- **Custom modules** under `app/code/<VendorNamespace>/` (vendor namespace is in CLAUDE.md → Project Overview)
- **React/frontend source** (if applicable) — location and structure documented in CLAUDE.md → Architecture → React + Vite Integration
- **Theme** — path and parent theme documented in CLAUDE.md → Architecture → Magento Theme
- **docs/** — feature documentation, implementation plans, and these manuals

---

## Key mental models

### 1. PHP renders the shell, React fills islands

*(Applicable to projects with React + Vite integration)*

Magento PHP templates (`.phtml`) render a `<div>` with a widget-mounting attribute. A Vite-compiled ES module script then finds that div and mounts a React component tree into it. Everything between PHP and React passes through **HTML data attributes** — there are no globals, no inline JSON scripts. See CLAUDE.md's **Architecture** section for the exact mounting convention.

### 2. GraphQL is the API contract

React components talk to Magento exclusively through GraphQL (`/graphql`). The GraphQL provider singleton is documented in CLAUDE.md. Custom modules declare schema types and resolvers in `etc/schema.graphqls`. TypeScript types are maintained by hand to match the schema — see CLAUDE.md for the types file location.

### 3. Build output is NOT committed

The compiled JS/CSS bundles are **not committed to git** — they are produced by the deployment pipeline. A pre-commit hook automatically removes any staged build artifacts. Run the build command (from CLAUDE.md → Commands) locally for development and testing only.

### 4. Pre-commit hooks run PHP checks automatically

The project's CLI wrapper runs PHPCS and PHPStan on staged `.php` and `.phtml` files before every commit. TypeScript and ESLint do not run automatically — use `/preflight react` or the `preflight` agent (which also runs a focused a11y audit for changed React components) before committing. See CLAUDE.md → Commands for the exact commands.

---

## Getting oriented with AI tools

These are the tools best suited for orientation when you're new to a part of the codebase.

### Understand a module you've never seen

```
/module-overview <VendorNamespace>_<ModuleName>
```

Returns a concise summary: what files exist, what the module does, how it integrates with other parts, any GraphQL extensions. Check CLAUDE.md's **Custom Magento Modules** table for the list of available modules.

### Ask "how does X work?"

```
@codebase-qa How does the [feature] form submit to the backend?
```

The `codebase-qa` agent reads actual source files and traces the full chain — from React component through Apollo through GraphQL resolver — with file paths and line references.

### Understand what a layout override does

```
/layout-diff Magento_Catalog
```

Compares the theme override against the Magento vendor original and explains what changed, why it might be fragile, and whether it could be written more surgically.

### Read feature documentation

The `docs/features/` folder contains architecture documents for implemented features. These include Mermaid flow diagrams showing the full frontend ↔ backend interaction. Start here when picking up an existing feature.

---

## Recommended first steps

1. **Read CLAUDE.md** thoroughly — it documents the project's architecture, conventions, module inventory, and reference features
2. Run `/module-overview` on the React/frontend module (if applicable) to understand the frontend structure
3. Run `/module-overview` on a reference feature module — CLAUDE.md's **Reuse Before Reimplementing** section names the cleanest full-stack examples
4. Read `docs/features/` — existing architecture documents show fully documented features with every layer described
5. Browse `docs/manuals/05-concepts/` — architectural insights about how the codebase works under the surface (plugins vs observers, GraphQL contracts, data bridging, caching)
6. Ask `@codebase-qa` anything you're unsure about — it reads the source and answers with file references

---

## How the AI tooling is structured

The `.claude/` directory contains agents, skills, and hooks. These are **project-portable** — they contain generic methodology and patterns, not hardcoded project details. Project-specific information lives in two places:

- **`CLAUDE.md`** — vendor namespace, module inventory, file paths, conventions, commands, and reuse references. All skills, agents, and hooks read from this file.
- **`.claude/hooks/config.sh`** — project-specific paths for shell hook scripts (vendor namespace, React source root, build output directories, GraphQL layer paths). Each hook sources this file automatically.

When reusing this `.claude/` setup in another Magento project, edit these two files — everything else works unchanged.

---

## Local development

Check CLAUDE.md's **Commands** section for the exact commands for this project. The typical structure is:

```bash
# Node (use nvm if .nvmrc exists)
nvm use

# Install dependencies
<package-manager> install

# Dev server (if React/Vite)
<dev-command>

# Production build
<build-command>

# Quality checks
<lint-command>       # ESLint
<type-check-command> # TypeScript
```

For PHP checks (PHPCS + PHPStan), see CLAUDE.md → Commands → PHP / Magento (Composer).

After merging a new Magento module, see CLAUDE.md → Commands → Magento CLI for the `setup:upgrade`, `setup:di:compile`, and `cache:flush` commands.
