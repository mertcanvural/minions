# Screen Design Prompts - Mission Control

## Design System Tokens

- **Accent**: Electric Indigo #6366F1
- **Background Dark**: #0F0F14
- **Background Light**: #FAFAFA
- **Surface Dark**: #1A1A24
- **Surface Light**: #FFFFFF
- **Text Primary Dark**: #F1F1F3
- **Text Primary Light**: #111111
- **Text Secondary**: #8B8B9E
- **Success**: #22C55E
- **Failure**: #EF4444
- **Running**: #3B82F6
- **Pending**: #6B7280
- **Warning**: #F59E0B
- **Border Dark**: #2A2A3C
- **Border Light**: #E5E7EB
- **Card Radius**: 16pt
- **Font UI**: SF Pro
- **Font Code**: SF Mono

---

## Screen 1: Dashboard

**Prompt**: Design a dark-themed macOS dashboard for an agentic engineering system called "Mission Control". The dashboard has a sidebar on the left with navigation items (Dashboard, Blueprint, Sandboxes, Agents, Audit Log, Settings) using SF Symbols. The main content area shows:
- Top row: 4 metric cards (Active Tasks, Success Rate, Avg Duration, Queue Depth) with large numbers, trend arrows, and subtle indigo accent borders
- Middle: A horizontal "Pipeline Activity" chart showing task completions over the last 24 hours as a bar chart with indigo bars
- Bottom left: "Recent Tasks" table with columns (Task, Agent, Status, Duration) showing 5 rows with colored status pills (green=completed, red=failed, blue=running)
- Bottom right: "Quick Launch" card with a text field, complexity estimation chips (Simple/Medium/Complex), and a prominent "Launch Task" button in electric indigo

Style: Dark background (#0F0F14), card surfaces (#1A1A24), 16pt rounded corners, subtle shadows, SF Pro font. macOS native feel with vibrancy effects.

---

## Screen 2: Blueprint Viewer (Hero Screen)

**Prompt**: Design a cinematic blueprint state machine viewer for a 12-node engineering pipeline. Dark canvas background with a vertical flow of connected nodes:

Nodes alternate between two types:
- **Agentic nodes** (cloud-shaped, indigo glow, pulsing border): IMPLEMENT TASK, FIX LINT, FIX CI (attempt 1), FIX CI (attempt 2), HUMAN REVIEW
- **Deterministic nodes** (sharp rectangles, blue-gray): RUN LINTERS, GIT COMMIT, PUSH BRANCH, CI ATTEMPT 1/2/3, CREATE PR

Each node shows: name, type badge, duration timer, status icon. Connections between nodes have animated particle flow (small dots traveling along paths). The currently active node has a bright glow and scale animation. Completed nodes are green-tinted, failed nodes red-tinted, pending nodes are dim gray.

A floating control bar at top has: Play/Pause, Step Forward, Reset, Speed slider. A side panel shows the selected node's details (output log, timing, retry count).

Style: Deep dark canvas, neon-like glows on active elements, smooth bezier connections between nodes, cinematic feel like a sci-fi mission control display.

---

## Screen 3: Sandbox Manager

**Prompt**: Design a sandbox/devbox management screen for isolated coding workspaces. Grid layout of sandbox cards, each showing:
- Task ID (monospace), branch name, status pill (warm=amber, claimed=blue, running=indigo, completed=green, failed=red, cleaned=gray)
- Project path, created timestamp, duration
- Mini progress bar showing pipeline stage
- Action buttons: Open Terminal, View Logs, Cleanup

Top section: Pool stats bar showing "Pool: 3 warm | 2 in-use | 1 available" with a visual meter. "Create Sandbox" button.

Filter bar: dropdown for status, search by task ID.

Style: Card grid with 16pt radius, dark surfaces, status-colored left borders on cards.

---

## Screen 4: Agent Profiles

**Prompt**: Design an agent profiles gallery for 6 specialized AI coding agents. Each agent gets a card with:
- Agent avatar (SF Symbol icon in a colored circle): Frontend (paintbrush, purple), Backend (server.rack, blue), Infra (cloud, orange), Docs (doc.text, green), Test (checkmark.shield, teal), Generalist (star, indigo)
- Name, model badge (gpt-4o / gpt-4o-mini), timeout, max files
- Task type tags as pills
- System prompt preview (truncated, expandable)
- Stats: tasks completed, avg duration, success rate

Top section: "Route a Task" input with live detection showing which agent would be selected and why (keyword matches highlighted).

Style: 2x3 grid of agent cards, dark theme, each card's accent color matches the agent's identity.

---

## Screen 5: Audit Log

**Prompt**: Design a real-time audit log viewer. Full-width table with columns:
- Timestamp (SF Mono, dim), Task ID (monospace link), Event Type (colored badge: task_started=blue, agent_selected=indigo, blueprint_step=purple, ci_result=green/red, pr_created=green, task_failed=red), Data (expandable JSON), Duration

Features:
- Toggle switch: "Live Data" / "Mock Data" at top right
- Search bar with regex support
- Filter chips for event types (multi-select)
- Auto-scroll toggle for live tailing
- Expandable rows showing full JSON data with syntax highlighting
- Export button (JSON/CSV)

Style: Dense data table, dark theme, monospace for data fields, alternating row shading, colored event type badges.

---

## Screen 6: Settings

**Prompt**: Design a settings screen with grouped sections:
1. **Connection**: Bridge URL text field, API Key (masked), Test Connection button with status indicator
2. **Refresh**: Sliders for dashboard refresh interval (5-60s), audit log refresh (1-30s)
3. **Appearance**: Dark/Light/System toggle, accent color picker (preset swatches)
4. **Audit**: Path to audit directory (file picker), max events to load
5. **Terminal**: Auto-detected preference (iTerm2 / Terminal.app) with override dropdown
6. **Advanced**: Reset to defaults, clear cache, debug logging toggle

Style: macOS-native settings layout with grouped sections, dark theme, form controls.

---

## Screen 7: Menu Bar Extra

**Prompt**: Design a macOS menu bar extra (status item) popup:
- Status icon: Circle indicator (green=connected, red=disconnected, amber=degraded)
- Header: "Mission Control" with connection status text
- Stats row: Active Tasks (count), Success Rate (%), Queue Depth
- Recent activity: Last 3 task events as compact rows
- Quick actions: "Open Dashboard", "Launch Task...", "View Audit Log"
- Footer: "Settings" link, version number

Style: Compact macOS popover, dark theme matching system appearance, ~280px wide.
