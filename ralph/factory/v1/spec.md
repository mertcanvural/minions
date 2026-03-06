# Specification: Mission Control - macOS Dashboard for Minions

## 1. Project Overview

**Mission Control** is a native macOS SwiftUI desktop application for monitoring and managing the Minions agentic engineering system. It provides real-time visualization of coding agent pipelines, sandbox management, agent profile inspection, and audit log browsing.

- **Platform**: macOS 15 (Sequoia)
- **Language**: Swift 5.9+
- **Framework**: SwiftUI (no UIKit, no AppKit except Process/NSOpenPanel)
- **Architecture**: MVVM with @Observable macro
- **Dependencies**: Zero external - Apple frameworks only (SwiftUI, Charts, Foundation, Combine)
- **Project Type**: Swift Package (Package.swift, no .xcodeproj)

## 2. Design System

### 2.1 Colors

| Token | Hex | Usage |
|---|---|---|
| `accent` | #6366F1 | Primary interactive elements, indigo |
| `accentLight` | #818CF8 | Hover/highlight states |
| `backgroundDark` | #0F0F14 | App background (dark mode) |
| `backgroundLight` | #FAFAFA | App background (light mode) |
| `surfaceDark` | #1A1A24 | Card/panel backgrounds (dark mode) |
| `surfaceLight` | #FFFFFF | Card/panel backgrounds (light mode) |
| `textPrimary` | #F1F1F3 / #111111 | Primary text (dark/light) |
| `textSecondary` | #8B8B9E | Secondary/muted text |
| `success` | #22C55E | Completed, pass, connected |
| `failure` | #EF4444 | Failed, error, disconnected |
| `running` | #3B82F6 | In-progress, active |
| `pending` | #6B7280 | Waiting, queued |
| `warning` | #F59E0B | Degraded, warm sandbox |
| `borderDark` | #2A2A3C | Card borders (dark) |
| `borderLight` | #E5E7EB | Card borders (light) |

### 2.2 Typography

| Style | Font | Size | Weight | Usage |
|---|---|---|---|---|
| `title` | SF Pro | 28 | Bold | Screen titles |
| `heading` | SF Pro | 20 | Semibold | Section headings |
| `subheading` | SF Pro | 16 | Medium | Card titles |
| `body` | SF Pro | 14 | Regular | General text |
| `caption` | SF Pro | 12 | Regular | Secondary info |
| `code` | SF Mono | 13 | Regular | Code, logs, IDs |
| `codeSmall` | SF Mono | 11 | Regular | Compact code display |
| `metric` | SF Pro Rounded | 36 | Bold | Dashboard numbers |

### 2.3 Spacing & Layout

| Token | Value | Usage |
|---|---|---|
| `cardRadius` | 16pt | All card corners |
| `cardPadding` | 16pt | Internal card padding |
| `sectionSpacing` | 24pt | Between major sections |
| `itemSpacing` | 12pt | Between items in lists/grids |
| `sidebarWidth` | 220pt | Navigation sidebar |
| `minWindowWidth` | 1100pt | Minimum app width |
| `minWindowHeight` | 700pt | Minimum app height |

### 2.4 Shadows & Effects

- **Card shadow**: color .black.opacity(0.15), radius 8, y offset 2
- **Glow (active node)**: color .accent.opacity(0.6), radius 20
- **Glass morphism**: .ultraThinMaterial background for floating controls
- **Hover**: brightness +0.05 on card hover

## 3. Data Models

### 3.1 Blueprint (12-Node State Machine)

Source: `docs/blueprint-engine.md`

```
Node 1:  IMPLEMENT TASK       [AGENTIC]      -> success: 2, failure: null
Node 2:  RUN LINTERS          [DETERMINISTIC] -> success: 4, failure: 3
Node 3:  FIX LINT ISSUES      [AGENTIC]      -> success: 4, failure: 4
Node 4:  GIT COMMIT           [DETERMINISTIC] -> success: 5, failure: null
Node 5:  PUSH BRANCH          [DETERMINISTIC] -> success: 6, failure: null
Node 6:  CI ATTEMPT 1         [DETERMINISTIC] -> success: 11, failure: 7
Node 7:  FIX CI (attempt 1)   [AGENTIC]      -> success: 8, failure: 8
Node 8:  CI ATTEMPT 2         [DETERMINISTIC] -> success: 11, failure: 9
Node 9:  FIX CI (attempt 2)   [AGENTIC]      -> success: 10, failure: 10
Node 10: CI FINAL ATTEMPT     [DETERMINISTIC] -> success: 11, failure: 12
Node 11: CREATE PR            [DETERMINISTIC] -> terminal success
Node 12: HUMAN REVIEW         [DETERMINISTIC] -> terminal failure
```

Node statuses: `pending`, `running`, `completed`, `failed`, `skipped`

### 3.2 Agent Profiles (6 Agents)

Source: `docs/agent-routing.md`

| Name | Display Name | Model | Timeout | Max Files | Task Types | Icon | Color |
|---|---|---|---|---|---|---|---|
| frontend_expert | Frontend Expert | gpt-4o-mini | 180s | 15 | frontend | paintbrush.pointed | purple |
| backend_expert | Backend Expert | gpt-4o | 300s | 20 | backend, database | server.rack | blue |
| infra_expert | Infra Expert | gpt-4o-mini | 120s | 10 | infra | cloud | orange |
| docs_expert | Docs Expert | gpt-4o-mini | 120s | 10 | docs | doc.text | green |
| test_expert | Test Expert | gpt-4o-mini | 180s | 15 | testing | checkmark.shield | teal |
| generalist | Generalist | gpt-4o | 300s | 25 | general | star | indigo |

Task type detection keywords (from docs):
- **frontend**: component, button, page, ui, css, style, layout, modal, form, dashboard, spinner, loading, card, menu, sidebar
- **backend**: api, endpoint, route, controller, service, auth, jwt, webhook, socket, cors, graphql
- **database**: migration, schema, database, prisma, sql, table, column, seed
- **infra**: docker, terraform, deploy, ci/cd, pipeline, kubernetes, aws, ec2
- **docs**: readme, documentation, docs, changelog, contributing
- **testing**: test, spec, coverage, mock, jest, vitest, playwright

Complexity estimation:
- Word count >50 = +2, >25 = +1
- Complexity keywords (refactor, multiple, rewrite, migrate, redesign, overhaul, architect, integrate) = +1 each
- Multi-file indicators (across, everywhere, all files, many, several) = +1 each
- Score >= 4 = complex, >= 2 = medium, else simple

### 3.3 Sandbox States

Source: `docs/devbox-model.md`

Statuses: `warm`, `claimed`, `running`, `completed`, `failed`, `cleaned`

Pool stats: `poolSize`, `available`, `inUse`

Sandbox fields: taskId, projectPath, workspacePath, branchName, createdAt, status, duration (computed), pipelineStage (1-12)

### 3.4 Audit Events

Source: `docs/api-reference.md` (audit_log.py section)

Event types: `task_started`, `agent_selected`, `tool_set_selected`, `blueprint_step`, `ci_result`, `pr_created`, `task_completed`, `task_failed`

Log format: JSON Lines at `~/.minion/audit/audit-YYYY-MM-DD.jsonl`
Fields: timestamp (ISO 8601), taskId, eventType, data (dictionary), durationMs (optional)

### 3.5 Dashboard Metrics

- **Active Tasks**: count of running sandboxes
- **Success Rate**: percentage of completed vs total (last 24h)
- **Avg Duration**: mean task duration in seconds (last 24h)
- **Queue Depth**: number of pending tasks

## 4. Screen Specifications

### 4.1 Dashboard

**Purpose**: At-a-glance system health and quick task launch.

**Layout**:
```
┌─────────────────────────────────────────────────┐
│  [Active Tasks] [Success Rate] [Avg Duration] [Queue] │  <- MetricCard row
├─────────────────────────────────────────────────┤
│  Pipeline Activity (24h bar chart)                      │  <- Charts BarMark
├────────────────────────────┬────────────────────┤
│  Recent Tasks (table)      │  Quick Launch       │
│  - Task, Agent, Status,    │  - Text field       │
│    Duration                │  - Complexity chips  │
│  - 8 rows                  │  - Launch button     │
└────────────────────────────┴────────────────────┘
```

**States**:
- Loading: redacted placeholders with shimmer
- Loaded: full data display
- Error: banner with retry button
- Empty: "No recent tasks" message

**Interactions**:
- Click metric card: no action (informational)
- Click recent task row: navigate to Blueprint Viewer for that task
- Quick Launch: type task, see live complexity estimation, click Launch
- Auto-refresh: configurable interval (default 10s)

### 4.2 Blueprint Viewer (Hero Screen)

**Purpose**: Cinematic visualization of the 12-node state machine pipeline.

**Layout**:
```
┌──────────────────────────────────────────────────────────┐
│  [Play] [Step] [Reset] [Speed: ====o====]  Node 3/12    │  <- Control bar (floating, glass)
├──────────────────────────────────────────┬───────────────┤
│                                          │  Node Detail  │
│     ╭─────────────╮                      │  ─────────── │
│     │ IMPLEMENT   │  (agentic, glow)     │  Name: ...   │
│     ╰──────┬──────╯                      │  Type: ...   │
│            │                             │  Status: ... │
│     ┌──────┴──────┐                      │  Duration:   │
│     │ RUN LINTERS │  (deterministic)     │  Output:     │
│     └──────┬──────┘                      │  ┌─────────┐ │
│       pass │ fail                        │  │ log...  │ │
│            │  ╭──────────╮               │  │ log...  │ │
│            │  │ FIX LINT │               │  └─────────┘ │
│            │  ╰────┬─────╯               │               │
│            ▼       ▼                     │               │
│     ... (continues for all 12 nodes)     │               │
│                                          │               │
│     ● ● ● (ambient particles)           │               │
└──────────────────────────────────────────┴───────────────┘
```

**Node Visual Types**:
- Agentic: Rounded/cloud shape, indigo gradient border, inner glow when active
- Deterministic: Sharp rectangle, 4pt corners, blue-gray border

**Node Status Visual**:
- Pending: dim gray, low opacity
- Running: bright glow, pulsing scale animation (1.0-1.05), full opacity
- Completed: green tint, checkmark badge
- Failed: red tint, xmark badge
- Skipped: very dim, dashed border

**Animations**:
- Particle flow: glowing dots (3-4pt) traveling along connection paths, 3-5 per active connection
- Particle trails: 2-3 fading copies behind each particle
- Connection activation: trim(from: 0, to: 1) draw-on animation over 0.5s
- Node completion: white flash overlay fading out over 0.3s
- Active node: pulsing glow ring (scale 1.0->1.05, opacity 0.6->1.0)
- Background: dot grid with subtle parallax on mouse movement
- Ambient: very faint, slow-moving particles in background
- Camera: auto-scroll to keep active node centered

**Simulation Controls**:
- Play/Pause: starts/stops automatic node progression
- Step Forward: advance to next node manually
- Reset: return all nodes to pending state
- Speed: 1x to 5x slider controlling simulation speed
- Click node: select it, show details in side panel

**Side Panel (Node Detail)**:
- Node name, type (badge), status (colored pill)
- Duration timer (counting up while running)
- Output log (scrollable, SF Mono, syntax colored)
- Retry count (for CI fix nodes)

### 4.3 Sandbox Manager

**Purpose**: View and manage isolated coding workspaces.

**Layout**:
```
┌─────────────────────────────────────────────────┐
│  Pool: [███░░] 3 warm | 2 in-use | 1 avail     │  <- PoolStatsBar
│  [Status: All ▼]  [Search: ________]            │  <- Filters
├─────────────────────────────────────────────────┤
│  ┌──────────┐  ┌──────────┐  ┌──────────┐      │
│  │ a1b2c3d4 │  │ e5f6g7h8 │  │ i9j0k1l2 │      │  <- SandboxCardView grid
│  │ minion/  │  │ minion/  │  │ minion/  │      │
│  │ ●running │  │ ●warm    │  │ ●done    │      │
│  │ [Term]   │  │          │  │ [Clean]  │      │
│  └──────────┘  └──────────┘  └──────────┘      │
└─────────────────────────────────────────────────┘
```

**Card Content**:
- Task ID (SF Mono, prominent)
- Branch name (minion/{taskId})
- Status pill (colored per status: warm=amber, claimed=blue, running=indigo, completed=green, failed=red, cleaned=gray)
- Project path (truncated with tooltip)
- Created timestamp (relative, e.g., "2m ago")
- Duration (for non-warm sandboxes)
- Pipeline stage as mini dots (12 dots, filled up to current stage)
- Actions: Open Terminal (if running), View Logs, Cleanup (if completed/failed)

**Filters**:
- Status dropdown: All, Warm, Running, Completed, Failed
- Search: filter by task ID

### 4.4 Agent Profiles

**Purpose**: Explore the 6 specialized agents and test task routing.

**Layout**:
```
┌─────────────────────────────────────────────────┐
│  Route a Task                                    │
│  [Enter task description...          ] [Route]   │
│  → Frontend Expert (confidence: 0.85)            │
│  → Complexity: Medium | Keywords: component, ui  │
├─────────────────────────────────────────────────┤
│  ┌──────────────┐  ┌──────────────┐             │
│  │ 🎨 Frontend  │  │ ⚙️ Backend   │             │
│  │ gpt-4o-mini  │  │ gpt-4o      │             │
│  │ 180s / 15f   │  │ 300s / 20f  │             │
│  │ [frontend]   │  │ [backend]   │             │
│  └──────────────┘  └──────────────┘             │
│  ┌──────────────┐  ┌──────────────┐             │
│  │ ☁️ Infra     │  │ 📝 Docs     │             │
│  └──────────────┘  └──────────────┘             │
│  ┌──────────────┐  ┌──────────────┐             │
│  │ ✅ Test      │  │ ⭐ General   │             │
│  └──────────────┘  └──────────────┘             │
└─────────────────────────────────────────────────┘
```

**Agent Card Content**:
- SF Symbol icon in colored circle (per agent identity color)
- Display name (heading style)
- Model badge (pill: "gpt-4o" or "gpt-4o-mini")
- Timeout seconds + max files
- Task type pills
- System prompt (truncated to 2 lines, expandable on click)
- Stats bar: tasks completed, avg duration, success rate (mock data)

**Task Routing**:
- Text input for task description
- Route button triggers routing logic
- Result shows: detected task type, selected agent (highlighted card), complexity badge, matched keywords as chips

### 4.5 Audit Log

**Purpose**: Browse and search structured audit events.

**Layout**:
```
┌─────────────────────────────────────────────────┐
│  [Mock Data ○──● Live Data]  [🔍 Search...]     │
│  [task_started] [agent_selected] [ci_result] ... │  <- Filter chips
│  [Auto-scroll: ON]  [Export ▼]                   │
├─────────────────────────────────────────────────┤
│  Timestamp      Task ID   Event Type      Dur   │
│  ─────────────────────────────────────────────── │
│  10:23:45.123  a1b2c3d4  task_started     -     │
│  10:23:45.456  a1b2c3d4  agent_selected   12ms  │
│  10:23:48.789  a1b2c3d4  blueprint_step   3200ms│
│  ▼ (expanded row)                                │
│    { "node": "IMPLEMENT TASK",                   │
│      "status": "completed",                      │
│      "output": "..." }                           │
│  10:24:02.345  a1b2c3d4  ci_result        -     │
└─────────────────────────────────────────────────┘
```

**Data Source Toggle**:
- Mock Data: uses MockAuditFileService (always available)
- Live Data: reads ~/.minion/audit/*.jsonl files
- If audit directory doesn't exist, show message with path

**Event Type Colors**:
- task_started: running (blue)
- agent_selected: accent (indigo)
- tool_set_selected: accent (indigo)
- blueprint_step: purple (#A855F7)
- ci_result: success/failure (green/red based on data)
- pr_created: success (green)
- task_completed: success (green)
- task_failed: failure (red)

**Features**:
- Search: filters across all text fields (task ID, event type, data)
- Filter chips: toggle event types on/off
- Expandable rows: click to show full JSON data with syntax highlighting
- Auto-scroll: when enabled, scrolls to latest event
- Export: save filtered events as JSON or CSV file

### 4.6 Settings

**Purpose**: Configure connection, appearance, and behavior.

**Sections**:

1. **Connection**
   - Bridge URL (TextField, default: http://localhost:8080)
   - API Key (SecureField)
   - Test Connection button → shows green check or red X inline

2. **Refresh Intervals**
   - Dashboard refresh: Slider 5-60s (step 5, default 10)
   - Audit log refresh: Slider 1-30s (step 1, default 5)

3. **Appearance**
   - Theme: Dark / Light / System (segmented picker)
   - Accent color: 5 preset swatches (indigo, blue, purple, green, orange) as tappable circles

4. **Audit**
   - Audit directory path (TextField + folder picker via NSOpenPanel)
   - Max events to load (Stepper, 50-1000, step 50, default 200)

5. **Terminal**
   - Auto-detected terminal (iTerm2 or Terminal.app)
   - Override dropdown

6. **Advanced**
   - Reset to Defaults (with confirmation alert)
   - Debug logging toggle
   - Clear cache button

**Persistence**: @AppStorage for all settings.

### 4.7 Menu Bar Extra

**Purpose**: Quick status check without focusing the app.

**Layout** (~280px wide):
```
┌────────────────────────────┐
│  ● Mission Control         │
│    Connected               │
├────────────────────────────┤
│  Active: 3  Success: 87%   │
│  Queue: 1                  │
├────────────────────────────┤
│  10:23 task_started a1b2.. │
│  10:22 pr_created   e5f6.. │
│  10:20 task_completed i9j0 │
├────────────────────────────┤
│  Open Dashboard             │
│  Launch Task...             │
│  View Audit Log             │
├────────────────────────────┤
│  Settings...    v1.0.0      │
└────────────────────────────┘
```

**Status Icon**: SF Symbol circle.fill - green when connected, red when disconnected, amber when degraded.

## 5. Project Structure

```
MissionControl/
  Package.swift
  Sources/MissionControl/
    App/
      MissionControlApp.swift
    Models/
      BlueprintModels.swift
      SandboxModels.swift
      AgentModels.swift
      AuditModels.swift
      DashboardModels.swift
    Design/
      DesignTokens.swift
      AppState.swift
      Theme.swift
    Services/
      Protocols/
        BridgeServiceProtocol.swift
        AuditFileServiceProtocol.swift
        SettingsServiceProtocol.swift
      Mock/
        MockBridgeService.swift
        MockAuditFileService.swift
        MockSettingsService.swift
        RealAuditFileService.swift
    ViewModels/
      DashboardViewModel.swift
      BlueprintViewModel.swift
      SandboxViewModel.swift
      AgentProfilesViewModel.swift
      AuditLogViewModel.swift
      SettingsViewModel.swift
    Views/
      Shell/
        SidebarView.swift
        ContentView.swift
      Dashboard/
        DashboardView.swift
        PipelineActivityChart.swift
        RecentTasksTable.swift
        QuickLaunchCard.swift
      Blueprint/
        BlueprintView.swift
        BlueprintCanvasView.swift
        BlueprintLayout.swift
        BlueprintNodeView.swift
        ConnectionView.swift
        ParticleFlowView.swift
      Sandbox/
        SandboxView.swift
        PoolStatsBar.swift
        SandboxCardView.swift
      AgentProfiles/
        AgentProfilesView.swift
        AgentCardView.swift
        TaskRoutingResultView.swift
      AuditLog/
        AuditLogView.swift
        AuditEventRow.swift
        AuditEventDetailView.swift
      Settings/
        SettingsView.swift
      MenuBar/
        MenuBarView.swift
      Shared/
        StatusPill.swift
        MetricCard.swift
        SectionCard.swift
  Tests/
    MissionControlTests/
      DashboardViewModelTests.swift
      BlueprintViewModelTests.swift
      AuditLogViewModelTests.swift
      ModelTests.swift
      MockServiceTests.swift
    MissionControlUITests/
      NavigationUITests.swift
      DashboardUITests.swift
```

## 6. Package.swift Specification

```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MissionControl",
    platforms: [.macOS(.v15)],
    targets: [
        .executableTarget(
            name: "MissionControl",
            path: "Sources/MissionControl"
        ),
        .testTarget(
            name: "MissionControlTests",
            dependencies: ["MissionControl"],
            path: "Tests/MissionControlTests"
        ),
        .testTarget(
            name: "MissionControlUITests",
            dependencies: ["MissionControl"],
            path: "Tests/MissionControlUITests"
        ),
    ]
)
```

## 7. Non-Goals

- No real HTTP networking (mock backend only)
- No database or CoreData
- No custom networking layer
- No third-party dependencies
- No iOS/iPadOS support
- No Xcode project file (.xcodeproj)
- No real-time WebSocket connections
- No authentication/authorization

## 8. Success Criteria

1. `swift build` compiles with zero errors
2. `swift test` passes all unit tests
3. App launches and displays sidebar with all 6 navigation items
4. All 5 main screens render with mock data
5. Blueprint Viewer shows 12 nodes with working simulation (play/pause/step)
6. Blueprint animations are smooth (particles, glows, transitions)
7. Audit Log toggles between mock and real data sources
8. Settings persist across app restarts via @AppStorage
9. Menu bar extra shows status and provides quick actions
10. Multi-window: Blueprint and Audit Log can be popped out
11. Both dark and light mode render correctly
12. Keyboard shortcuts (Cmd+1-6) switch tabs
