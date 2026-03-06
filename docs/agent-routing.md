# Agent Routing System

## Overview

Instead of one-size-fits-all, tasks are routed to specialized agent profiles. Each profile has its own model, system prompt, timeout, and domain focus. Based on Stripe's approach where different agents get different configurations per domain.

## 6 Agent Profiles

| Profile | Model | Timeout | Task Types | Focus |
|---|---|---|---|---|
| Frontend Expert | gpt-4o-mini | 180s | frontend | React, CSS, responsive design, component architecture |
| Backend Expert | gpt-4o | 300s | backend, database | API design, database, auth, service architecture |
| Infra Expert | gpt-4o-mini | 120s | infra | Docker, CI/CD, Terraform, deployment |
| Docs Expert | gpt-4o-mini | 120s | docs | Technical documentation, READMEs, changelogs |
| Test Expert | gpt-4o-mini | 180s | testing | Jest, Vitest, coverage, mocking |
| Generalist | gpt-4o | 300s | general | Full-stack, any task type |

### AgentProfile Dataclass

```python
@dataclass
class AgentProfile:
    name: str
    display_name: str
    model: str
    system_prompt: str
    task_types: list[str]
    max_files: int
    timeout_seconds: int
```

## Task Type Detection

`detect_task_type(task)` uses keyword pattern matching to classify tasks:

- **frontend**: component, button, page, ui, css, style, layout, modal, form, dashboard, spinner, loading, card, menu, sidebar, etc.
- **backend**: api, endpoint, route, controller, service, auth, jwt, webhook, socket, cors, graphql, etc.
- **database**: migration, schema, database, prisma, sql, table, column, seed, etc.
- **infra**: docker, terraform, deploy, ci/cd, pipeline, kubernetes, aws, ec2, etc.
- **docs**: readme, documentation, docs, changelog, contributing, etc.
- **testing**: test, spec, coverage, mock, jest, vitest, playwright, etc.
- **general**: fallback when no keywords match

Scoring: each keyword match adds to the category score. Highest score wins. Special case: if "write/add/create/fix tests" is detected, testing always wins.

## Complexity Estimation

`estimate_complexity(task)` returns "simple", "medium", or "complex" using heuristics:

- **Word count**: >50 words = +2, >25 words = +1
- **Complexity keywords**: refactor, multiple, rewrite, migrate, redesign, overhaul, architect, integrate (+1 each)
- **Multi-file indicators**: across, everywhere, all files, many, several (+1 each)
- **Conjunction patterns**: "and also/then/additionally" (+1)

Thresholds: score >= 4 = complex, >= 2 = medium, else simple.

### Model Upgrades for Complex Tasks

When complexity is "complex", certain profiles get upgraded models:
- frontend_expert: gpt-4o-mini → gpt-4o
- infra_expert: gpt-4o-mini → gpt-4o
- test_expert: gpt-4o-mini → gpt-4o
- All complex tasks get +120s timeout extension

## Task Decomposition

`decompose_task(task, task_type)` splits multi-domain tasks:

1. Looks for "and" or "then" splitting the task text
2. Detects domain for each part using keyword patterns
3. Only splits if domains are different (e.g., frontend + testing)
4. Returns list of subtasks with individual task types

Example:
```
Input: "add a dashboard component and write tests for it"
Output: [
  {"task": "add a dashboard component", "task_type": "frontend"},
  {"task": "write tests for it", "task_type": "testing"}
]
```

Subtasks execute sequentially (RAM constraint on t2.micro).

## AUTONOMOUS_PREAMBLE

Injected at the top of every agent prompt to enforce autonomous execution:

```
=== AUTONOMOUS EXECUTION MODE ===
You are running UNATTENDED inside an automated pipeline. There is NO human to answer questions.

RULES:
1. NEVER ask questions, request clarification, or say "Could you provide...".
2. NEVER output placeholder code like "// TODO" or "implement here".
3. ALWAYS write complete, working code directly into files.
4. If requirements are ambiguous, make a reasonable decision and implement it.
5. If you need information, read the codebase - do not ask for it.
6. If a dependency is missing, install it.
7. If a file doesn't exist, create it.
8. Your ONLY output should be file changes and a brief summary of what you did.
9. Start coding IMMEDIATELY. Do not introduce yourself or explain what you plan to do.
```

## Prompt Construction

`build_agent_prompt()` assembles the full prompt in this order:

1. **AUTONOMOUS_PREAMBLE** — enforce unattended execution
2. **Agent header** — profile name and model
3. **System prompt** — domain-specific instructions
4. **Skills prompt** — step-by-step templates (if any matched)
5. **Base context** — hydrated project info (stack, rules, git, docs, file tree)
6. **Tool instructions** — allowed/forbidden paths
7. **Task description** — the actual work to do

## Skills Registry

Skills are markdown files with YAML frontmatter stored in `~/.claude/skills/`:

```markdown
---
name: add-react-component
description: Create a new React component
task_types: [frontend]
keywords: [component, page, form, modal]
---
1. Check existing component patterns in the project
2. Create the component file following naming conventions
3. Add TypeScript types/interfaces
4. Export from the appropriate index file
5. Run lint and tests
```

`get_skills_for_task(task, task_type)` matches by task type and keyword relevance. Matched skills are injected into the prompt as step-by-step templates.
