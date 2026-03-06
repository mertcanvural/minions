# Sandbox & DevBox Pool

## Philosophy: Cattle, Not Pets

Every agent task runs in its own isolated workspace. Sandboxes are disposable — created, used, and destroyed. No state persists between tasks. This mirrors Stripe's devbox model where engineers spin up 6+ devboxes in parallel.

## How Sandboxes Are Created

The `SandboxManager.create()` method:

1. **Generate unique task ID**: `uuid4().hex[:8]` (e.g., `a1b2c3d4`)
2. **Create branch name**: `minion/{task_id}` (e.g., `minion/a1b2c3d4`)
3. **Clone repo**: `git clone --depth 1 --single-branch {project} {workspace}`
   - Fallback: `shutil.copytree` if clone times out (skips node_modules, .next, build, dist, .git)
   - Fallback initializes fresh git repo in the copy
4. **Create branch**: `git checkout -b minion/{task_id}`
5. **Set GitHub remote**: Detects GitHub URL from source project, sets it in sandbox so `gh pr create` works
6. **Add .gitignore entries**: `goose-config.yaml`, `*.prompt.txt` (pipeline artifacts)
7. **Copy .mdc rules**: Walks source project, copies all `.mdc` files to sandbox preserving directory structure

### Workspace Layout
```
/tmp/minion-sandboxes/
  task-a1b2c3d4/          # Isolated workspace
    .git/                  # Fresh git with unique branch
    .gitignore             # Includes pipeline artifact exclusions
    .mdc                   # Copied from source project
    src/                   # Full project source (shallow clone)
    ...
```

## Sandbox Lifecycle

```
created → running → completed/failed → cleaned
```

- `create()` → status: "created"
- `mark_running()` → status: "running"
- `mark_completed()` / `mark_failed()` → terminal status
- `cleanup()` → `shutil.rmtree`, removes from active list

### Status Methods
```python
sandbox_manager.create(project_path, task_description) → Sandbox
sandbox_manager.mark_running(task_id)
sandbox_manager.mark_completed(task_id)
sandbox_manager.mark_failed(task_id)
sandbox_manager.cleanup(task_id)
sandbox_manager.list_active() → list[dict]
```

## Warm DevBox Pool

The `DevBoxPool` class pre-creates sandboxes for instant claiming. This is our equivalent of Stripe's 10-second warm start.

### Pool Lifecycle
```
warm() → [sandbox, sandbox, sandbox]  (pre-created, status: "warm")
                    │
claim() ←──────────┘  (returns warm sandbox, status: "claimed")
                    │
         ┌──────────┘
         ▼
  _replenish_async()  (background thread creates replacement)
                    │
release(task_id) ───┘  (cleanup + trigger replenish)
```

### Configuration
```python
pool = sandbox_manager.enable_pool(
    project_path="/home/ubuntu/Projects/myapp",
    pool_size=3  # number of pre-warmed sandboxes
)
```

### Implementation Details
- Pool uses `threading.Lock` for thread safety
- `warm()` creates `pool_size` sandboxes in parallel threads
- `claim()` returns a pre-warmed sandbox or cold-creates one if pool is empty
- `release()` cleans up workspace and triggers async replenishment
- `_replenish_async()` spawns background threads to refill pool to target size

### Pool Stats
```python
sandbox_manager.pool_stats()
# Returns: {
#   "/home/ubuntu/Projects/myapp": {
#     "pool_size": 3,
#     "available": 2,
#     "in_use": 1
#   }
# }
```

## Parallelization

Tasks run on separate threads (Slack handler uses `threading.Thread(target=run_task, daemon=True)`). Each thread gets its own sandbox — no cross-contamination.

The Slack handler supports `concurrency=10` via `SocketModeHandler`. Combined with the DevBox pool, multiple tasks can execute simultaneously without interference.

## Stripe's DevBox vs Ours

| Aspect | Stripe | Ours |
|---|---|---|
| Infrastructure | AWS EC2 instances (full VMs) | Local git clones in /tmp |
| Warm start | ~10 seconds | ~5 seconds (shallow clone) |
| Pool size | Half dozen per engineer | Configurable (default: 3) |
| Isolation | Full VM isolation | Directory-level isolation |
| Pre-loaded | Source code, services, caches | Shallow git clone + .mdc rules |
| Remote detection | N/A (already on EC2) | Auto-detects GitHub URL from source |
| Cleanup | VM termination | shutil.rmtree |

## Key Classes

### Sandbox (dataclass)
```python
@dataclass
class Sandbox:
    task_id: str
    project_path: str
    workspace_path: str
    branch_name: str
    created_at: datetime
    status: str  # created, running, completed, failed, cleaned, warm, claimed
```

### SandboxManager
Manages the full lifecycle: create, track, push, cleanup. Maintains `active_sandboxes` dict and optional `_pools` dict for warm pools.

### DevBoxPool
Pre-warms sandboxes in background threads. Thread-safe claim/release with automatic replenishment.
