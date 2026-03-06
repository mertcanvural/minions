# Minions: Stripe-Grade Agentic Engineering System

One-shot coding agents modeled after [Stripe's Minions architecture](https://stripe.dev/blog/minions-stripes-one-shot-end-to-end-coding-agents). Engineers prompt at the start, review at the end. The system runs unattended in between.

## How It Works

```
Slack / CLI  -->  Sandbox  -->  Context Hydration  -->  Agent Routing
                                                            |
PR  <--  Blueprint Engine  <--  Tool Shed + Skills  <-------+
```

1. **Entry**: Engineer sends a task via Slack (`@minion`) or CLI (`minion_cli.py`)
2. **Sandbox**: Isolated workspace created (git clone, unique branch, .mdc rules copied)
3. **Context**: Stack detection, scoped rules, git history, file tree, docs loaded
4. **Routing**: Task classified, specialized agent selected, complexity estimated
5. **Tools + Skills**: Curated tool subset and action templates injected into prompt
6. **Blueprint**: 12-node state machine — agent implements, deterministic steps lint/test/push
7. **PR**: `gh pr create` (deterministic, no LLM) — engineer reviews

## Key Design Principles

- **Interleave determinism with agents** — not everything needs an LLM
- **Agents get the same environment as engineers** — DevBox model
- **Shift feedback left** — catch failures early (lint before CI)
- **Specialization over generalization** — domain-expert agents
- **Out-of-loop by default** — prompt once, review at end
- **Meta-agentics** — tools that select tools, prompts that build prompts

## Architecture Components

| Component | Module | Description |
|---|---|---|
| Bridge | `minion_bridge.py` | Slack + CLI entry, orchestration |
| Blueprint Engine | `blueprint.py` | 12-node state machine (5 agentic + 7 deterministic) |
| Agent Router | `agent_router.py` | 6 specialized profiles, complexity estimation, decomposition |
| Context Hydration | `context.py` | Stack detection, .mdc rules, git context, file tree |
| Tool Shed | `tool_shed.py` | 7 curated tool sets, allowed/forbidden paths |
| MCP Config | `mcp_config.py` | 10 MCP servers, dynamic discovery, registry |
| Sandbox | `sandbox.py` | Per-task isolation, warm DevBox pool |
| Skills | `skills.py` | Reusable action templates from markdown files |
| Audit Log | `audit_log.py` | Persistent JSON Lines event logging |
| CLI | `minion_cli.py` | Command-line interface with dry-run mode |

## Documentation

| Doc | Description |
|---|---|
| [Architecture](docs/architecture.md) | System architecture reference with flow diagrams and component mapping |
| [Blueprint Engine](docs/blueprint-engine.md) | Deep dive into the 12-node state machine |
| [DevBox Model](docs/devbox-model.md) | Sandbox isolation and warm pool mechanics |
| [Agent Routing](docs/agent-routing.md) | Specialized agent profiles, task detection, decomposition |
| [Tool Shed](docs/tool-shed.md) | MCP integration, curated tool subsets, Goose CLI flags |
| [Context Engineering](docs/context-engineering.md) | Context hydration pipeline, .mdc rules, stack detection |
| [API Reference](docs/api-reference.md) | Module-level API reference for all Python modules |

## Quick Start

### Slack
```
@minion add a login page project=myapp
```

### CLI
```bash
python minion_cli.py "add a login page" --project myapp
python minion_cli.py "refactor sidebar" --dry-run
python minion_cli.py --status
```

## Runtime

- **Agent**: Goose CLI v1.27.0
- **LLM**: GPT-4o via OpenAI (configurable per agent profile)
- **Infrastructure**: AWS EC2 Ubuntu 24.04, systemd service
- **Concurrency**: Threaded execution (10 parallel tasks)
- **Audit**: `~/.minion/audit/` (JSON Lines, one file per day)
