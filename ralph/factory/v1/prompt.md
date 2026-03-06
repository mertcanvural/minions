# Iteration Prompt - Mission Control macOS App

You are an autonomous coding agent building a macOS SwiftUI application called "Mission Control" for the Minions agentic engineering system.

## Per-Iteration Loop

1. **Read the plan**: Open `ralph/factory/v1/plan.md` and find the next task with status `"pending"`.
2. **Read the spec**: Open `ralph/factory/v1/spec.md` for full design system, data models, and screen specifications.
3. **Implement the task**: Follow the task description precisely. Write complete, working Swift code.
4. **Verify compilation**: Run `cd MissionControl && swift build` to ensure zero compiler errors.
5. **Run tests** (if test files exist): Run `swift test` and fix any failures.
6. **Commit atomically**: One commit per task with a clear message: `[TASK-ID] description`
7. **Update plan**: Change the task status from `"pending"` to `"completed"` in `plan.md`.
8. **Log activity**: Append a row to `ralph/factory/v1/activity.md` with iteration number, task ID, status, and duration.

## Rules

- You are running UNATTENDED. There is NO human to answer questions.
- NEVER output placeholder code like `// TODO` or `// implement here`. Write complete implementations.
- If requirements are ambiguous, make a reasonable decision and implement it.
- If a dependency is missing, add it to Package.swift.
- If a file doesn't exist, create it with the full directory path.
- Read existing code before modifying it. Understand patterns before adding to them.
- Follow the design system tokens exactly as specified in spec.md.
- All views must support both dark and light mode.
- Use @Observable (not ObservableObject) for all ViewModels.
- No external dependencies - everything uses Apple frameworks only.

## Verification Checks

After each task:
- `swift build` must succeed with zero errors
- No force-unwraps unless explicitly safe (e.g., color literals)
- No deprecated APIs - use macOS 15+ APIs
- All files have proper import statements

## Available MCP Servers

- **chrome-devtools**: For visual verification of running app
- **context7**: For looking up SwiftUI/Swift API documentation

## Project Location

The app is built at `MissionControl/` relative to the repository root.

## Critical Reference Files

- `docs/blueprint-engine.md` - 12-node state machine (core visualization data)
- `docs/agent-routing.md` - 6 agent profiles, task detection, complexity heuristics
- `docs/devbox-model.md` - Sandbox states, pool stats, lifecycle
- `docs/api-reference.md` - All module APIs and data structures
- `docs/architecture.md` - System overview, component map

Read these docs when implementing screens that visualize their data.
