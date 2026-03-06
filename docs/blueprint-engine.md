# Blueprint Engine

## Overview
The Blueprint Engine is the core orchestration layer — a state machine that interleaves deterministic code execution with agentic LLM reasoning. Based on Stripe's Minions architecture (Part 2).

Key insight: **agents + code beats agents alone AND beats code alone**. Putting LLMs in contained boxes compounds into system-wide reliability. You save tokens, reduce errors, and get guarantees where you need them.

## Two Node Types

### Agentic Nodes (cloud shapes in Stripe's diagram)
- Free-form LLM reasoning
- "Implement this task", "Fix these CI failures"
- Agent has latitude to make decisions, use tools, write code
- Uses Goose CLI with specialized system prompts
- Controlled by `agent_timeout` parameter

### Deterministic Nodes (rectangles in Stripe's diagram)
- Pure code execution — no LLM involved
- Run linters, push changes, trigger CI, create PR
- Predictable, fast, cheap
- Uses subprocess calls with timeouts

## The 12-Node Sequence

```
┌─────────────────┐
│  1. IMPLEMENT   │  [AGENTIC]
│     TASK        │  Goose writes code based on enhanced prompt
└────────┬────────┘
         ▼
┌─────────────────┐
│  2. RUN         │  [DETERMINISTIC]
│     LINTERS     │  Auto-detects lint command (npm run lint / make lint)
└────────┬────────┘
    pass │    fail
         │     ▼
         │  ┌─────────────────┐
         │  │  3. FIX LINT    │  [AGENTIC]
         │  │     ISSUES      │  Agent fixes lint errors autonomously
         │  └────────┬────────┘
         │           │
         ▼           ▼
┌─────────────────┐
│  4. GIT COMMIT  │  [DETERMINISTIC]
│                 │  git add -A && git commit
└────────┬────────┘
         ▼
┌─────────────────┐
│  5. PUSH BRANCH │  [DETERMINISTIC]
│                 │  git push -u origin HEAD
└────────┬────────┘
         ▼
┌─────────────────┐
│  6. CI          │  [DETERMINISTIC]
│     ATTEMPT 1   │  GitHub Actions or local tests
└────────┬────────┘
    pass │    fail
         │     ▼
         │  ┌─────────────────┐
         │  │  7. FIX CI      │  [AGENTIC]
         │  │     (attempt 1) │  Agent fixes test failures, commits, pushes
         │  └────────┬────────┘
         │           ▼
         │  ┌─────────────────┐
         │  │  8. CI          │  [DETERMINISTIC]
         │  │     ATTEMPT 2   │  Re-run tests
         │  └────────┬────────┘
         │      pass │    fail
         │           │     ▼
         │           │  ┌─────────────────┐
         │           │  │  9. FIX CI      │  [AGENTIC]
         │           │  │     (attempt 2) │  "Last chance — fix the root cause"
         │           │  └────────┬────────┘
         │           │           ▼
         │           │  ┌─────────────────┐
         │           │  │  10. CI FINAL   │  [DETERMINISTIC]
         │           │  │      ATTEMPT    │  Final test run
         │           │  └────────┬────────┘
         │           │      pass │    fail
         ▼           ▼           ▼     ▼
┌─────────────────┐         ┌─────────────────┐
│  11. CREATE PR  │         │  12. HUMAN      │
│  [DETERMINISTIC]│         │      REVIEW     │
│  gh pr create   │         │  "All attempts  │
│                 │         │   failed"       │
└─────────────────┘         └─────────────────┘
```

## Implementation Details

### Blueprint class (`blueprint.py`)
```python
class Blueprint:
    def __init__(self, name: str)
    def add_node(self, node: Node) -> None
    def set_start(self, node_name: str) -> None
    def execute(self, **context) -> tuple[bool, list]
```

### Node class
```python
@dataclass
class Node:
    name: str
    node_type: NodeType  # DETERMINISTIC or AGENTIC
    action: Callable
    next_on_success: Optional[str]
    next_on_failure: Optional[str]
```

Each node executes its action and routes to the next node based on success/failure. Actions signal failure by including "❌" (the cross mark emoji) in their output.

### Goose CLI Integration
Agentic nodes write prompts to `task.prompt.txt` and invoke Goose:
```
goose run -i task.prompt.txt --no-session -q --max-turns 20 \
  --provider openai --model gpt-4o --system "..."
```

### Fix Node Preamble
All fix nodes prepend this autonomous execution directive:
```
You are running UNATTENDED. There is NO human to answer questions.
Fix the issue by editing files directly. Do NOT ask for clarification.
Do NOT explain what you would do - just do it. Write code now.
```

### CI Detection
The system auto-detects the test command:
1. `package.json` with `scripts.test` → `npm test` (skips placeholder scripts)
2. `Package.swift` → `swift test`
3. `gradlew` → `./gradlew test`
4. `Makefile` → `make test`

Similarly for linting: checks `package.json scripts.lint` → `npm run lint`, or `Makefile` → `make lint`.

### File Change Verification
After the implement step, the blueprint verifies the agent actually modified files using `git diff --stat` and `git ls-files --others`. If no changes were made, the node fails with "Agent produced no file changes".

## Why Hybrid Beats Pure Approaches

| Approach | Problem |
|---|---|
| Pure agent | Runs linters via LLM (expensive, slow, unreliable). Might forget to push. |
| Pure code | Can't implement features or fix CI failures — needs reasoning. |
| Hybrid (Blueprint) | Agents reason where needed, code handles the rest. Deterministic steps are fast, cheap, and guaranteed. |

## Per-Team Customization
`create_standard_blueprint()` accepts `provider`, `model`, and `system_prompt` parameters. Different teams can create blueprints with different agent configurations while sharing the same deterministic infrastructure.
