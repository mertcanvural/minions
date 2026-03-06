# Tool Shed & MCP Integration

## Overview

Stripe's Tool Shed serves ~500 MCP tools. Each agent gets a curated subset — not all 500 at once. This prevents token explosion and keeps agents focused. We replicate this with 10 MCP servers and 7 task-type tool sets.

The Tool Shed is a meta-tool pattern: a tool that selects tools. This is meta-agentics in action.

## 7 Task-Type Tool Sets

Each task type gets its own `ToolSet` with allowed paths, forbidden paths, commands, and instructions:

### Frontend Tools
- **Allowed**: src/components/, src/pages/, src/app/, src/styles/, src/hooks/, src/lib/, src/utils/, public/, app/, pages/, components/
- **Forbidden**: src/server/, src/api/, prisma/, migrations/, terraform/, infra/, .github/workflows/
- **Commands**: npm run dev, npm run build, npm test, npm run lint
- **Focus**: UI components, pages, styles, hooks, utils only

### Backend Tools
- **Allowed**: src/server/, src/api/, src/services/, src/controllers/, src/models/, src/middleware/, src/dtos/, src/entities/, api/, server/, lib/
- **Forbidden**: src/components/, src/pages/, src/styles/, public/, terraform/, infra/, .github/workflows/
- **Commands**: npm test, npm run lint, npm run build
- **Focus**: Server code, API routes, services, controllers, models

### Database Tools
- **Allowed**: prisma/, migrations/, src/models/, src/entities/, db/, schema/
- **Forbidden**: src/components/, src/pages/, public/, terraform/, .github/workflows/
- **Commands**: npx prisma generate, npx prisma migrate dev, npm test
- **Focus**: Schemas, migrations, models, entities

### Infra Tools
- **Allowed**: terraform/, infra/, .github/workflows/, docker/, Dockerfile, docker-compose.yml, .env.example
- **Forbidden**: src/, app/, pages/, components/
- **Commands**: terraform plan, docker build, docker-compose up
- **Focus**: Terraform, Docker, CI/CD, deployment configs

### Docs Tools
- **Allowed**: docs/, README.md, CONTRIBUTING.md, CHANGELOG.md, .mdc, LICENSE
- **Forbidden**: src/, app/, terraform/, infra/
- **Commands**: npm run docs, npm run build
- **Focus**: Documentation files only

### Testing Tools
- **Allowed**: __tests__/, tests/, test/, spec/, *.test.ts, *.test.tsx, *.spec.ts, *.spec.tsx, jest.config.*, vitest.config.*
- **Forbidden**: terraform/, infra/, .github/workflows/
- **Commands**: npm test, npm test -- --coverage, npm run lint
- **Focus**: Test files, can read source for understanding

### General Tools
- **Allowed**: * (all paths)
- **Forbidden**: (none)
- **Commands**: npm test, npm run lint, npm run build
- **Focus**: Full access, follow .mdc rules

## 10 MCP Servers

| Server | Package | Description | Task Types |
|---|---|---|---|
| github | @modelcontextprotocol/server-github | PRs, issues, code search, branches | frontend, backend, database, infra, testing, general |
| filesystem | @modelcontextprotocol/server-filesystem | Scoped file read/write | all types |
| fetch | @modelcontextprotocol/server-fetch | HTTP requests for docs/APIs | frontend, backend, docs, general |
| memory | @modelcontextprotocol/server-memory | Persistent key-value store | general |
| postgres | @modelcontextprotocol/server-postgres | Database queries, schema inspection | backend, database |
| sqlite | @modelcontextprotocol/server-sqlite | Lightweight database ops | backend, database |
| brave-search | @modelcontextprotocol/server-brave-search | Web search for research | docs, general |
| puppeteer | @modelcontextprotocol/server-puppeteer | Browser automation | frontend, testing |
| sequential-thinking | @modelcontextprotocol/server-sequential-thinking | Complex reasoning chains | backend, infra, general |
| slack | @modelcontextprotocol/server-slack | Notifications | general |

## Tool Discovery

`TOOL_DISCOVERY_KEYWORDS` maps MCP server names to keyword patterns for automatic detection:

```python
TOOL_DISCOVERY_KEYWORDS = {
    "postgres": [r"\b(postgres|postgresql|pg_dump|psql)\b"],
    "sqlite": [r"\b(sqlite|sqlite3|\.db\b)"],
    "brave-search": [r"\b(research|search|lookup|find.?docs|web.?search)\b"],
    "puppeteer": [r"\b(browser|puppeteer|headless|screenshot|scrape|crawl)\b"],
    "sequential-thinking": [r"\b(reason|reasoning|chain.?of.?thought|step.?by.?step|analyze)\b"],
    "slack": [r"\b(slack|notify|notification|message.?channel)\b"],
}
```

### Discovery via npm

`discover_installed_servers()` runs `npm list -g --json --depth=0` to find globally installed `@modelcontextprotocol/server-*` packages. Results are cached in `~/.minion/mcp_registry.json`.

### Registry

The registry tracks which servers are installed:

```json
{
  "servers": {
    "github": {"name": "github", "description": "...", "installed": true},
    "postgres": {"name": "postgres", "description": "...", "installed": false}
  },
  "last_refreshed": "2026-03-06T..."
}
```

Refresh via `/minion-discover` Slack command or `refresh_registry()`.

## Goose CLI Flags

Instead of config files, we pass configuration via CLI flags:

```bash
goose run \
  -i task.prompt.txt \     # Input prompt file
  --no-session \           # No persistent session
  -q \                     # Quiet mode
  --max-turns 20 \         # Limit reasoning rounds
  --provider openai \      # LLM provider
  --model gpt-4o \         # Model selection
  --system "You are..." \  # System prompt
```

This enables per-task configuration without file conflicts during parallel execution.

## Goose Config Generation

`generate_goose_config()` creates a complete Goose config with:
- Provider and model from env vars or overrides
- MCP servers filtered by task type
- Filesystem server scoped to allowed paths

```python
config = generate_goose_config(
    task_type="frontend",
    project_path="/home/ubuntu/Projects/myapp",
    allowed_paths=["src/components/", "src/pages/"],
    model="gpt-4o-mini"
)
```

## Stripe's ~500 Tools vs Our 10

Our 10 MCP servers cover the essentials. Growth path:

1. Add project-specific custom MCP servers
2. Build internal tools (code search, doc lookup, test runner)
3. Connect to external services (Jira, Linear, Notion)
4. Create a meta-tool server that dynamically selects from the full registry

The architecture supports any number of MCP servers — the curated subset pattern scales regardless of total tool count.
