# Context Hydration & Rules

## Overview

Before the agent loop begins, context is deterministically fetched and injected into the prompt. This "hydrates" the agent with full project knowledge before execution — no guessing, no hallucinating project structure.

Stripe faces this at massive scale: agents can't read 100M+ lines of code. The solution is scoped context — rules, docs, and structure relevant to the specific task.

## Context Hydration Pipeline

`hydrate_context(project_path, task)` assembles all context into a single formatted block:

```
=== CONTEXT HYDRATION ===

Git Context:
- Repository: https://github.com/user/repo
- Current branch: minion/a1b2c3d4
- Recent commits: ...

Stack Information:
- Type: Next.js
- Framework: my-app
- Test Framework: Jest
- Linter: ESLint

Changed files: ...

=== PROJECT FILE TREE ===
my-app/
  src/
    components/
      Button.tsx
      Header.tsx
    ...

=== SCOPED RULES ===
(contents of .mdc files)

=== PROJECT DOCUMENTATION ===
(contents of priority docs)

=== TASK ===
Add a new dashboard page

=== EXECUTION INSTRUCTIONS ===
1. WRITE THE CODE NOW...
```

## Stack Detection

`detect_stack(project_path)` identifies:

| Indicator | Detected Stack |
|---|---|
| `package.json` with "next" in dependencies | Next.js |
| `package.json` with "nest" in dependencies | NestJS |
| `package.json` (other) | Node.js |
| `Package.swift` | Swift |
| `gradlew` | Kotlin/Java (Gradle) |
| `Makefile` | Makefile |
| (none) | Unknown |

Also detects:
- **Test framework**: jest.config.js → Jest, vitest.config.js → Vitest
- **Linter**: .eslintrc.json or .eslintrc.js → ESLint

## Scoped .mdc Rules

Rules files use the `.mdc` format (Cursor's rule format). They are scoped to directories — not global.

### How Rules Are Loaded

`load_scoped_rules(project_path, file_path)`:
1. Start from the target file's directory (or project root)
2. Walk UP the directory tree toward the project root
3. At each level, check for a `.mdc` file
4. Concatenate all found rules (innermost last, so they override)
5. Return combined rules text

### Example .mdc File

```markdown
# Next.js Project Rules

## File Structure
- Pages: app/ or pages/
- Components: src/components/ (use named exports)
- Styles: src/styles/ or tailwind.config.js

## Code Patterns
- Use server components by default ("use client" sparingly)
- Prefer async/await for data fetching
- Use TypeScript for all new code
- Import from @/ aliases, not relative paths

## Testing
- Jest + React Testing Library
- Test files: __tests__/*.test.ts

## Pre-commit
- Check: npm run build && npm test
```

### Template Generation

`load_template_mdc(stack_type)` generates scaffold rules for:
- Next.js
- NestJS
- Swift
- Generic (default)

Available via `/minion-template` Slack command.

### Stripe's Approach

- Rules scoped to subdirectories via glob patterns in frontmatter
- Auto-attached as agent traverses the filesystem
- Synced across minions, Cursor, and Claude Code
- Solves the "agents can't read 100M lines of code" problem

## Project File Tree

`get_file_tree(project_path, max_depth=3, max_files=80)` generates a depth-limited tree.

**Skipped directories**: node_modules, .next, .git, build, dist, __pycache__, .venv, venv, .cache, .turbo, coverage, .nyc_output

**Skipped files**: .DS_Store, package-lock.json, yarn.lock, pnpm-lock.yaml

**Truncation**: After 80 files, output is truncated with "... (truncated)"

## Git Context

`get_git_context(project_path)` fetches:
- Repository URL (from `git remote get-url origin`)
- Current branch name
- Last 3 commits (one-line format)

`get_changed_files(project_path)` fetches:
- Unstaged changes (`git diff --name-only`)
- Staged changes (`git diff --cached --name-only`)

All git commands use `timeout=5` to prevent hanging.

## Documentation Loading

`load_documentation(project_path)` reads from `docs/` directory:

**Priority files** (loaded first):
1. README.md
2. ARCHITECTURE.md
3. CONTRIBUTING.md

Each file is limited to 1,000 characters to keep prompt size manageable.

## Execution Instructions

Every hydrated context ends with autonomous execution directives:

```
1. WRITE THE CODE NOW. Create or modify files directly.
2. DO NOT ask questions. DO NOT request more information.
3. If anything is ambiguous, make a reasonable decision and implement it.
4. Read the scoped rules above — they define patterns and conventions.
5. Follow the stack information to use the correct tools and frameworks.
6. Match the style of recent commits.
7. Run tests locally before committing.
8. Output a brief summary of what you changed — nothing else.
```
