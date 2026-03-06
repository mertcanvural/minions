# Module API Reference

Quick reference for all Python modules in the Minions agentic engineering system.

---

## minion_bridge.py
Core orchestration bridge. Entry points: Slack + CLI.

### Functions
| Function | Signature | Description |
|---|---|---|
| `parse_task` | `(text: str) -> Tuple[str, str]` | Extract `project=X` from text. Returns (project_path, clean_task). Default project: agentic-coding |
| `is_trivial_command` | `(text: str) -> bool` | Filter trivial commands: hi, hello, ping, status, help, test |
| `execute_task_in_sandbox` | `(project_path: str, task: str, say_callback) -> bool` | Full pipeline: sandbox → decompose → route → blueprint → cleanup. Returns True on success |
| `_execute_single_subtask` | `(project_path, sandbox, task, task_type, say_callback) -> bool` | Execute one subtask: hydrate → route → tools → skills → prompt → blueprint |
| `main` | `() -> None` | Start Slack Bolt app with Socket Mode handler (concurrency=10) |

### Slack Commands
| Command | Handler | Description |
|---|---|---|
| `@minion <task>` | `handle_app_mentions` | Execute task in sandbox (threaded) |
| `/minion-template` | `handle_template_command` | Generate .mdc template for a stack |
| `/minion-tools` | `handle_tools_command` | Show MCP tools for a task type |
| `/minion-setup` | `handle_setup_command` | Show MCP setup instructions |
| `/minion-discover` | `handle_discover_command` | Scan for installed MCP servers |
| `/minion-status` | `handle_status_command` | Show bridge status and pool stats |
| `/minion-audit` | `handle_audit_command` | Show recent audit log events |

### Constants
- `PROJECTS_DIR = "/home/ubuntu/Projects"`

---

## minion_cli.py
CLI entry point for the system.

### Usage
```bash
python minion_cli.py "task description" [--project NAME] [--dry-run] [--status]
```

### Functions
| Function | Description |
|---|---|
| `cmd_status()` | Print active sandboxes |
| `cmd_dry_run(project_path, task)` | Show routing, tools, skills without executing |
| `cmd_execute(project_path, task)` | Full execution with real sandbox |
| `say_cli(msg)` | Print callback matching Slack interface |

---

## blueprint.py
State machine interleaving deterministic + agentic nodes.

### Classes

**`NodeType(Enum)`**
- `DETERMINISTIC` — pure code execution
- `AGENTIC` — LLM reasoning

**`Node`** (dataclass)
| Field | Type | Description |
|---|---|---|
| `name` | `str` | Node identifier |
| `node_type` | `NodeType` | DETERMINISTIC or AGENTIC |
| `action` | `Callable` | Function to execute |
| `next_on_success` | `Optional[str]` | Next node name on success |
| `next_on_failure` | `Optional[str]` | Next node name on failure |

Method: `execute(**kwargs) -> tuple[bool, str]` — runs action, returns (success, output). Failure signaled by `X` emoji in output.

**`Blueprint`**
| Method | Signature | Description |
|---|---|---|
| `__init__` | `(name: str)` | Create named blueprint |
| `add_node` | `(node: Node) -> None` | Register a node |
| `set_start` | `(node_name: str) -> None` | Set entry point |
| `execute` | `(**context) -> tuple[bool, list]` | Run state machine to completion |

### Factory Function
```python
create_standard_blueprint(
    project_path: str,
    provider: str = "",
    model: str = "",
    system_prompt: str = ""
) -> Blueprint
```
Creates the standard 12-node blueprint matching Stripe's sequence.

### Internal Functions
| Function | Description |
|---|---|
| `_filter_goose_output(stdout)` | Remove Goose session markers |
| `_build_goose_cmd(prompt_path, system_prompt, provider, model)` | Build goose CLI command list |
| `_read_package_scripts(project_path)` | Read scripts from package.json |
| `_detect_test_cmd(project_path)` | Auto-detect test command |
| `_detect_lint_cmd(project_path)` | Auto-detect lint command |
| `_run_ci(project_path)` | Run CI (GitHub Actions or local) |
| `_trigger_github_actions(project_path)` | Trigger and wait for GitHub Actions |

---

## agent_router.py
Specialized agent selection and task decomposition.

### Classes

**`AgentProfile`** (dataclass)
| Field | Type | Description |
|---|---|---|
| `name` | `str` | Internal name |
| `display_name` | `str` | Human-readable name |
| `model` | `str` | LLM model ID |
| `system_prompt` | `str` | Domain-specific instructions |
| `task_types` | `list[str]` | Matching task types |
| `max_files` | `int` | Max files agent can modify |
| `timeout_seconds` | `int` | Goose execution timeout |

### Functions
| Function | Signature | Returns |
|---|---|---|
| `select_agent` | `(task, task_type, project_path) -> AgentProfile` | Best matching profile with complexity-based model upgrades |
| `estimate_complexity` | `(task: str) -> str` | "simple", "medium", or "complex" |
| `decompose_task` | `(task, task_type) -> list[dict]` | List of `{"task": str, "task_type": str}` |
| `build_agent_prompt` | `(profile, base_context, tool_instructions, task, skills_prompt) -> str` | Full assembled prompt |

### Constants
- `AUTONOMOUS_PREAMBLE` — injected into every prompt
- `AGENT_PROFILES` — dict of 6 profile definitions
- `COMPLEX_MODEL_OVERRIDES` — model upgrades for complex tasks

---

## context.py
Pre-execution context fetching.

### Functions
| Function | Signature | Returns |
|---|---|---|
| `hydrate_context` | `(project_path, task, file_path=None) -> str` | Complete formatted context block |
| `detect_stack` | `(project_path: str) -> Dict[str, str]` | Stack info dict (type, framework, test_framework, linter) |
| `load_scoped_rules` | `(project_path, file_path=None) -> str` | Combined .mdc rules (walks up directory tree) |
| `load_documentation` | `(project_path: str) -> str` | Priority docs from docs/ folder |
| `get_git_context` | `(project_path: str) -> str` | Repo URL, branch, recent commits |
| `get_file_tree` | `(project_path, max_depth=3, max_files=80) -> str` | Depth-limited project tree |
| `get_changed_files` | `(project_path: str) -> str` | Staged and unstaged changes |
| `load_template_mdc` | `(stack_type: str) -> str` | Template .mdc for Next.js, NestJS, Swift, Generic |

---

## tool_shed.py
Curated tool subsets per task type.

### Classes
**`ToolSet`** (dataclass)
| Field | Type | Description |
|---|---|---|
| `name` | `str` | Tool set identifier |
| `description` | `str` | Human description |
| `allowed_paths` | `list[str]` | Directories agent CAN modify |
| `forbidden_paths` | `list[str]` | Directories agent MUST NOT modify |
| `commands` | `list[str]` | Available shell commands |
| `instructions` | `str` | Extra prompt instructions |

### Functions
| Function | Signature | Returns |
|---|---|---|
| `detect_task_type` | `(task: str) -> str` | Task type classification |
| `get_tool_set` | `(task: str) -> ToolSet` | Curated tool set for task |
| `format_tool_instructions` | `(tool_set: ToolSet) -> str` | Formatted prompt text |

### Constants
- `TOOL_REGISTRY` — dict of 7 ToolSet definitions
- `TOOL_DISCOVERY_KEYWORDS` — regex patterns for MCP server detection

---

## sandbox.py
Per-task isolation and DevBox pooling.

### Classes

**`Sandbox`** (dataclass) — fields: task_id, project_path, workspace_path, branch_name, created_at, status

**`SandboxManager`**
| Method | Description |
|---|---|
| `create(project_path, task_description)` | Create isolated sandbox with git clone + branch |
| `mark_running/completed/failed(task_id)` | Update sandbox status |
| `push_changes(task_id, remote_url)` | Push branch to remote |
| `cleanup(task_id)` | Remove workspace directory |
| `cleanup_all()` | Remove all sandboxes |
| `list_active()` | List active sandboxes as dicts |
| `get_sandbox(task_id)` | Get Sandbox by ID |
| `enable_pool(project_path, pool_size=3)` | Enable warm DevBox pool |
| `claim_from_pool(project_path)` | Claim pre-warmed or cold-create |
| `pool_stats()` | Pool utilization stats |

**`DevBoxPool`**
| Method | Description |
|---|---|
| `warm()` | Pre-create pool_size sandboxes (threaded) |
| `claim()` | Return warm sandbox or cold-create |
| `release(task_id)` | Cleanup + async replenish |
| `stats()` | {pool_size, available, in_use} |

---

## skills.py
Reusable action templates from markdown files.

### Classes
**`Skill`** (dataclass) — fields: name, description, task_types, steps, keywords

### Functions
| Function | Signature | Returns |
|---|---|---|
| `load_all_skills` | `(skills_dir=SKILLS_DIR) -> list[Skill]` | All skills from ~/.claude/skills/*.md |
| `get_skills_for_task` | `(task, task_type, skills_dir) -> list[Skill]` | Matched skills (keyword + type) |
| `format_skills_prompt` | `(skills: list[Skill]) -> str` | Formatted prompt section |

### Skill File Format
```markdown
---
name: skill-name
description: What this skill does
task_types: [frontend, testing]
keywords: [component, form]
---
1. First step
2. Second step
```

### Constants
- `SKILLS_DIR = ~/.claude/skills/`

---

## mcp_config.py
MCP server configuration and discovery.

### Functions
| Function | Signature | Returns |
|---|---|---|
| `get_mcp_servers_for_task` | `(task_type: str) -> list[dict]` | Curated MCP server list |
| `generate_goose_config` | `(task_type, project_path, allowed_paths, model) -> dict` | Complete Goose config dict |
| `write_goose_config` | `(config, config_path) -> str` | Write to ~/.config/goose/config.yaml |
| `discover_installed_servers` | `() -> list[dict]` | npm list -g scan results |
| `refresh_registry` | `(registry_path) -> dict` | Discover + merge + save |
| `load_registry` / `save_registry` | Registry I/O | JSON file at ~/.minion/mcp_registry.json |
| `get_setup_instructions` | `() -> str` | EC2 setup guide text |
| `list_available_tools` | `(task_type) -> list[dict]` | Available tools (optional type filter) |
| `get_available_servers` | `(task_type, registry_path) -> list[dict]` | Servers with install status |

### Constants
- `MCP_SERVERS` — dict of 10 server definitions
- `DEFAULT_REGISTRY_PATH = ~/.minion/mcp_registry.json`

---

## audit_log.py
Persistent structured logging.

### Classes
**`AuditLogger`**
| Method | Signature | Description |
|---|---|---|
| `log` | `(task_id, event_type, data=None, duration_ms=None)` | Write single event (never raises) |
| `get_recent_events` | `(n=50) -> list[dict]` | Last n events, most recent first |
| `get_events_for_task` | `(task_id) -> list[dict]` | All events for a task ID |
| `get_log_path` | `() -> str` | Current day's log file path |

### Event Types
`task_started`, `agent_selected`, `tool_set_selected`, `blueprint_step`, `ci_result`, `pr_created`, `task_completed`, `task_failed`

### Log Format
JSON Lines at `~/.minion/audit/audit-YYYY-MM-DD.jsonl`:
```json
{"timestamp": "2026-03-06T...", "task_id": "a1b2c3d4", "event_type": "task_started", "data": {"project": "...", "task": "..."}, "duration_ms": null}
```

### Constants
- `AUDIT_DIR = ~/.minion/audit/`
