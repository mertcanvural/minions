# System Architecture Reference

## Overview

One-shot coding agents modeled after Stripe's "Minions" architecture. Engineers prompt at the start, review at the end. The system runs unattended in between.

Key stats from Stripe: 1,300+ PRs/week with zero human-written code, ~500 MCP tools, 3M+ tests, processing $1.9T in payments (1.6% of global GDP).

## End-to-End Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                        ENTRY POINTS                             │
│   Slack (@minion)  │  CLI (minion_cli.py)  │  Web UI (planned) │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                  SANDBOX ISOLATION                               │
│   Per-task isolated workspace (git clone → branch → .gitignore) │
│   Warm DevBox Pool: pre-created sandboxes, claim/release cycle  │
│   Base dir: /tmp/minion-sandboxes/task-{id}                     │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                  CONTEXT HYDRATION                               │
│   Stack detection │ .mdc rules │ Git context │ File tree │ Docs │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                  AGENT ROUTING                                   │
│   6 profiles: frontend, backend, infra, docs, test, generalist  │
│   Task type detection │ Complexity estimation │ Decomposition    │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                  TOOL SHED + SKILLS                              │
│   7 curated tool sets │ 10 MCP servers │ Skill templates (.md)  │
│   Allowed/forbidden paths per task type                         │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                  BLUEPRINT ENGINE                                │
│   State machine: 12 nodes (5 agentic + 7 deterministic)         │
│   implement → lint → fix → commit → push → CI×3 → fix×2 → PR  │
│   Self-healing: max 2 CI retry rounds                           │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                  PR & REVIEW                                     │
│   gh CLI creates PR (deterministic, no LLM)                     │
│   Engineer reviews at the end — out-of-loop model               │
└─────────────────────────────────────────────────────────────────┘
```

## Supporting Infrastructure

```
┌──────────────────────┐    ┌──────────────────────┐    ┌──────────────────────┐
│    RULES FILES       │    │     TOOL SHED        │    │     AUDIT LOG        │
│                      │    │                      │    │                      │
│ - .mdc format        │    │ - 10 MCP servers     │    │ - JSON Lines format  │
│ - Scoped to subdirs  │    │ - Curated subsets    │    │ - Per-day log files  │
│ - Walk up to root    │    │   per task type      │    │ - ~/.minion/audit/   │
│ - Auto-attached to   │    │ - Tool discovery     │    │ - Every step logged  │
│   agent context      │    │   via npm list -g    │    │ - Thread-safe writes │
└──────────────────────┘    └──────────────────────┘    └──────────────────────┘
```

## Component Mapping: Stripe vs Ours

| Component | Stripe | Ours | Status |
|---|---|---|---|
| Entry Points | Slack, CLI, Web UI | Slack (@minion) + CLI (minion_cli.py) | Done |
| Agent Sandbox | Warm EC2 DevBox pool | SandboxManager + DevBoxPool (pre-warmed) | Done |
| Agent Harness | Forked Goose | Goose CLI v1.27.0 (unforked) via CLI flags | Done |
| Blueprint Engine | State machine (agent + deterministic nodes) | blueprint.py — 12 nodes, 5 agentic + 7 deterministic | Done |
| Context Engineering | Scoped rules files (.mdc) | context.py — stack detection, .mdc, git, file tree, docs | Done |
| Tool Shed | ~500 MCP tools, curated per agent | 10 MCP servers, 7 task-type tool sets | Done |
| Agent Routing | Specialized agents per domain | 6 agent profiles with model/prompt/timeout tuning | Done |
| Skills | Internal action templates | Markdown files with YAML frontmatter (~/.claude/skills/) | Done |
| Task Decomposition | Blueprint sub-agents | Keyword-based multi-domain splitting | Done |
| Validation | Pre-push lint + selective CI (3M+ tests) | Lint detection + local/GitHub Actions CI | Done |
| PR Creation | GitHub PRs following template | gh CLI (deterministic, no LLM) | Done |
| Observability | Internal dashboard | Audit logging (JSON Lines) | Done |
| Concurrency | Parallel devboxes | Threading (concurrent=10) + DevBox pool | Done |

## Key Design Principles

### 1. Interleave Determinism with Agents

Not everything needs an LLM. Linting, git ops, pushing = deterministic code. Implementing tasks, fixing failures = agent reasoning. The blueprint engine is the marriage of both.

### 2. Agents Get the Same Environment as Engineers

DevBox model. Same tools, same access, same setup. If you want agents to perform like you, give them your environment.

### 3. Shift Feedback Left

Catch failures as early as possible. Pre-push linting runs in under 1 second before the full CI suite. Known failures get auto-fixed before reaching the agent.

### 4. Specialization Over Generalization

Custom prompts, skills, rules, and harness tuned to specific repos and stacks. Frontend tasks get a frontend expert with React-focused prompts. Backend tasks get a backend expert with API-focused prompts.

### 5. Out-of-Loop by Default

Engineer prompts at the start, reviews at the end. Agent runs unattended in between — no confirmation prompts, no human-in-the-loop. The AUTONOMOUS_PREAMBLE enforces this.

### 6. Meta-Agentics

Tools that select tools (Tool Shed). Prompts that build prompts (build_agent_prompt). Skills that template skills. The system that builds the system.

## Runtime Environment

- **EC2 Instance**: Ubuntu 24.04.3 LTS
- **Agent**: Goose CLI v1.27.0
- **LLM**: GPT-4o via OpenAI (configurable per agent profile)
- **Entry**: Slack Bolt (Socket Mode, concurrency=10) + CLI
- **Process**: systemd service (minion-bridge.service)
- **Audit**: ~/.minion/audit/ (JSON Lines, one file per day)
- **Sandboxes**: /tmp/minion-sandboxes/
