# Build Plan - Mission Control macOS App

## Task Distribution

- **Opus** (6 tasks): Blueprint Viewer hero screen + BlueprintViewModel
- **Sonnet** (21 tasks): Core screens, data layer, ViewModels, testing, polish
- **Haiku** (4 tasks): Foundation scaffolding, simple settings screen

## Recommended Execution

- **Max iterations**: 50
- **Headroom**: 1.6x for retries
- **Estimated tasks**: 31

## Tasks

```json
[
  {
    "id": "F-001",
    "category": "Foundation",
    "title": "Create Package.swift and app entry point",
    "description": "Create MissionControl/Package.swift with swift-tools-version 5.9, macOS 15 platform, single executable target 'MissionControl' with source in Sources/MissionControl and test targets. Create Sources/MissionControl/App/MissionControlApp.swift with @main App struct, WindowGroup for main window, Settings scene, and MenuBarExtra. Use .windowStyle(.hiddenTitleBar) for the main window.",
    "dependencies": [],
    "status": "completed",
    "model": "haiku"
  },
  {
    "id": "F-002",
    "category": "Foundation",
    "title": "Create design system tokens",
    "description": "Create Sources/MissionControl/Design/DesignTokens.swift with all color tokens as static Color properties: accent (#6366F1), backgroundDark (#0F0F14), backgroundLight (#FAFAFA), surfaceDark (#1A1A24), surfaceLight (#FFFFFF), textPrimary, textSecondary (#8B8B9E), success (#22C55E), failure (#EF4444), running (#3B82F6), pending (#6B7280), warning (#F59E0B), border colors. Include semantic computed properties that switch on colorScheme. Add typography constants (SF Pro sizes, SF Mono for code). Add spacing/radius constants (cardRadius=16, standard paddings).",
    "dependencies": ["F-001"],
    "status": "completed",
    "model": "haiku"
  },
  {
    "id": "F-003",
    "category": "Foundation",
    "title": "Create shared UI components",
    "description": "Create Sources/MissionControl/Views/Shared/StatusPill.swift - a capsule-shaped view with text and background color based on status string. Create Sources/MissionControl/Views/Shared/MetricCard.swift - a card view with title, large value, trend indicator (up/down arrow with color), and subtitle. Create Sources/MissionControl/Views/Shared/SectionCard.swift - a generic card container with title, optional subtitle, and content ViewBuilder. All use DesignTokens.",
    "dependencies": ["F-002"],
    "status": "completed",
    "model": "haiku"
  },
  {
    "id": "F-004",
    "category": "Foundation",
    "title": "Create AppState and environment setup",
    "description": "Create Sources/MissionControl/Design/AppState.swift with an @Observable AppState class holding: selectedTab (enum: dashboard, blueprint, sandboxes, agents, auditLog, settings), bridgeConnected (Bool), theme preference (dark/light/system). Create Sources/MissionControl/Design/Theme.swift with environment key for current theme and color scheme resolution logic. Inject AppState as environment object in MissionControlApp.",
    "dependencies": ["F-001"],
    "status": "completed",
    "model": "haiku"
  },
  {
    "id": "D-001",
    "category": "Data Layer",
    "title": "Create core data models",
    "description": "Create Sources/MissionControl/Models/BlueprintModels.swift with: enum NodeType (agentic, deterministic), enum NodeStatus (pending, running, completed, failed, skipped), struct BlueprintNode (id, name, nodeType, status, duration, output, nextOnSuccess, nextOnFailure, retryCount), struct BlueprintRun (id, taskDescription, nodes: [BlueprintNode], startedAt, completedAt, status). Create Sources/MissionControl/Models/SandboxModels.swift with: enum SandboxStatus (warm, claimed, running, completed, failed, cleaned), struct Sandbox (taskId, projectPath, workspacePath, branchName, createdAt, status, duration, pipelineStage), struct PoolStats (poolSize, available, inUse). Create Sources/MissionControl/Models/AgentModels.swift with: struct AgentProfile (name, displayName, model, systemPrompt, taskTypes, maxFiles, timeoutSeconds, iconName, accentColor), enum TaskComplexity (simple, medium, complex), struct TaskRouting (detectedType, selectedAgent, complexity, keywordMatches). Create Sources/MissionControl/Models/AuditModels.swift with: enum AuditEventType (taskStarted, agentSelected, toolSetSelected, blueprintStep, ciResult, prCreated, taskCompleted, taskFailed), struct AuditEvent (timestamp, taskId, eventType, data: [String:String], durationMs). Create Sources/MissionControl/Models/DashboardModels.swift with: struct DashboardMetrics (activeTasks, successRate, avgDuration, queueDepth, trends), struct RecentTask (id, description, agentName, status, duration, startedAt). All conform to Identifiable, Codable where appropriate.",
    "dependencies": ["F-001"],
    "status": "completed",
    "model": "sonnet"
  },
  {
    "id": "D-002",
    "category": "Data Layer",
    "title": "Create service protocols",
    "description": "Create Sources/MissionControl/Services/Protocols/BridgeServiceProtocol.swift with: protocol BridgeServiceProtocol defining methods: fetchDashboardMetrics() async throws -> DashboardMetrics, fetchRecentTasks() async throws -> [RecentTask], fetchBlueprintRun(id: String?) async throws -> BlueprintRun, fetchSandboxes() async throws -> [Sandbox], fetchPoolStats() async throws -> PoolStats, fetchAgentProfiles() async throws -> [AgentProfile], routeTask(description: String) async throws -> TaskRouting, launchTask(description: String, project: String) async throws -> String, fetchAuditEvents(limit: Int) async throws -> [AuditEvent]. Create Sources/MissionControl/Services/Protocols/AuditFileServiceProtocol.swift with: protocol for reading real JSONL files: loadEvents(from path: String, limit: Int) throws -> [AuditEvent], availableLogFiles(in directory: String) throws -> [URL]. Create Sources/MissionControl/Services/Protocols/SettingsServiceProtocol.swift with: protocol for loading/saving settings (bridgeURL, apiKey, refreshIntervals, theme, auditPath, terminalPreference).",
    "dependencies": ["D-001"],
    "status": "completed",
    "model": "sonnet"
  },
  {
    "id": "D-003",
    "category": "Data Layer",
    "title": "Create mock service implementations",
    "description": "Create Sources/MissionControl/Services/Mock/MockBridgeService.swift implementing BridgeServiceProtocol with realistic mock data: 4 dashboard metrics with trends, 8 recent tasks across different agents/statuses, a full 12-node blueprint run with mixed statuses, 6 sandboxes in various states, pool stats (3 warm, 2 in-use, 1 available), all 6 agent profiles matching docs/agent-routing.md exactly (Frontend Expert, Backend Expert, Infra Expert, Docs Expert, Test Expert, Generalist), task routing with keyword detection. Create Sources/MissionControl/Services/Mock/MockAuditFileService.swift with 20 mock audit events spanning all event types. Create Sources/MissionControl/Services/Mock/MockSettingsService.swift with sensible defaults (bridgeURL: http://localhost:8080, refreshInterval: 10s, etc.). Add artificial async delays (0.3-0.8s) to simulate network latency.",
    "dependencies": ["D-002"],
    "status": "completed",
    "model": "sonnet"
  },
  {
    "id": "C-001",
    "category": "Core ViewModels",
    "title": "Create DashboardViewModel",
    "description": "Create Sources/MissionControl/ViewModels/DashboardViewModel.swift as @Observable class. Properties: metrics (DashboardMetrics), recentTasks ([RecentTask]), isLoading, error, refreshTimer. Methods: loadData() async, startAutoRefresh(interval:), stopAutoRefresh(). Takes BridgeServiceProtocol via init. Auto-refreshes on configurable interval. Handles loading and error states gracefully.",
    "dependencies": ["D-003"],
    "status": "completed",
    "model": "sonnet"
  },
  {
    "id": "C-002",
    "category": "Core ViewModels",
    "title": "Create BlueprintViewModel",
    "description": "Create Sources/MissionControl/ViewModels/BlueprintViewModel.swift as @Observable class. Properties: currentRun (BlueprintRun?), selectedNode (BlueprintNode?), isSimulating (Bool), simulationSpeed (Double, 1.0-5.0), activeNodeIndex (Int). Methods: loadRun() async, startSimulation() - advances through nodes with delays matching simulationSpeed, pauseSimulation(), resetSimulation(), stepForward(), selectNode(id:). Simulation updates node statuses from pending->running->completed/failed with realistic timing. Includes computed properties: completedNodeCount, failedNodeCount, currentProgress (0.0-1.0), estimatedTimeRemaining.",
    "dependencies": ["D-003"],
    "status": "completed",
    "model": "opus"
  },
  {
    "id": "C-003",
    "category": "Core ViewModels",
    "title": "Create SandboxViewModel",
    "description": "Create Sources/MissionControl/ViewModels/SandboxViewModel.swift as @Observable class. Properties: sandboxes ([Sandbox]), poolStats (PoolStats), filterStatus (SandboxStatus?), searchQuery (String), isLoading. Methods: loadData() async, filteredSandboxes (computed), openTerminal(sandbox:) - uses Process to launch iTerm2 or Terminal.app at workspace path, cleanup(taskId:) async. Takes BridgeServiceProtocol.",
    "dependencies": ["D-003"],
    "status": "completed",
    "model": "sonnet"
  },
  {
    "id": "C-004",
    "category": "Core ViewModels",
    "title": "Create AgentProfilesViewModel",
    "description": "Create Sources/MissionControl/ViewModels/AgentProfilesViewModel.swift as @Observable class. Properties: profiles ([AgentProfile]), routingResult (TaskRouting?), taskInput (String), isRouting. Methods: loadProfiles() async, routeTask() async - calls service with taskInput and sets routingResult, estimateComplexity(task:) -> TaskComplexity (port the keyword heuristic from docs/agent-routing.md). Takes BridgeServiceProtocol.",
    "dependencies": ["D-003"],
    "status": "completed",
    "model": "sonnet"
  },
  {
    "id": "C-005",
    "category": "Core ViewModels",
    "title": "Create AuditLogViewModel and SettingsViewModel",
    "description": "Create Sources/MissionControl/ViewModels/AuditLogViewModel.swift as @Observable class. Properties: events ([AuditEvent]), filteredEvents (computed), useLiveData (Bool toggling real vs mock), searchQuery (String), selectedEventTypes (Set<AuditEventType>), isAutoScrolling, isLoading. Methods: loadEvents() async, toggleDataSource(), exportEvents(format: json|csv) -> URL. Takes both BridgeServiceProtocol and AuditFileServiceProtocol. Create Sources/MissionControl/ViewModels/SettingsViewModel.swift as @Observable class. Properties matching all settings fields. Methods: save() async, testConnection() async -> Bool, resetToDefaults(), detectTerminal() -> String. Takes SettingsServiceProtocol.",
    "dependencies": ["D-003"],
    "status": "completed",
    "model": "sonnet"
  },
  {
    "id": "N-001",
    "category": "Navigation",
    "title": "Create sidebar navigation shell",
    "description": "Create Sources/MissionControl/Views/Shell/SidebarView.swift with NavigationSplitView. Sidebar has List with selection binding to AppState.selectedTab. Items: Dashboard (gauge), Blueprint (point.3.connected.trianglepath.dotted), Sandboxes (shippingbox), Agents (person.3), Audit Log (doc.text.magnifyingglass), Settings (gear). Each item shows SF Symbol + label. Highlight uses DesignTokens.accent. Bottom of sidebar shows connection status indicator (green/red dot + text). Create Sources/MissionControl/Views/Shell/ContentView.swift that switches on selectedTab to show the appropriate screen view.",
    "dependencies": ["F-003", "F-004"],
    "status": "completed",
    "model": "sonnet"
  },
  {
    "id": "N-002",
    "category": "Navigation",
    "title": "Wire up multi-window support",
    "description": "Update MissionControlApp.swift to add Window scenes for Blueprint (id: 'blueprint-popout') and Audit Log (id: 'audit-popout'). Add keyboard shortcuts: Cmd+1 through Cmd+6 for tab switching. Add menu bar commands for 'Pop Out Blueprint' and 'Pop Out Audit Log' that open new windows. Ensure the main ContentView and popout windows can share the same ViewModels.",
    "dependencies": ["N-001"],
    "status": "completed",
    "model": "sonnet"
  },
  {
    "id": "H-001",
    "category": "Dashboard",
    "title": "Create Dashboard screen views",
    "description": "Create Sources/MissionControl/Views/Dashboard/DashboardView.swift as the main dashboard screen. Layout: ScrollView with VStack. Top row: HStack of 4 MetricCard views (Active Tasks, Success Rate, Avg Duration, Queue Depth). Middle: SectionCard containing PipelineActivityChart (simple bar chart using Swift Charts framework showing 24 hourly bars). Bottom: HStack with RecentTasksTable (left, wider) and QuickLaunchCard (right). Create Sources/MissionControl/Views/Dashboard/PipelineActivityChart.swift using Charts framework with BarMark, indigo color, x=hour, y=completions. Create Sources/MissionControl/Views/Dashboard/RecentTasksTable.swift with Table view (columns: Task, Agent, Status pill, Duration). Create Sources/MissionControl/Views/Dashboard/QuickLaunchCard.swift with TextField, complexity chips (tappable, auto-estimated), and indigo 'Launch Task' button.",
    "dependencies": ["C-001", "N-001"],
    "status": "completed",
    "model": "sonnet"
  },
  {
    "id": "H-002",
    "category": "Dashboard",
    "title": "Connect Dashboard to ViewModel",
    "description": "Wire DashboardView to DashboardViewModel. Add .task { await vm.loadData() } and .onDisappear { vm.stopAutoRefresh() }. Bind MetricCards to vm.metrics. Bind RecentTasksTable to vm.recentTasks. Wire QuickLaunchCard's launch button to vm (via BridgeService.launchTask). Add loading skeleton states (redacted placeholder modifier) and error banner. Ensure auto-refresh works with configurable interval from SettingsViewModel.",
    "dependencies": ["H-001"],
    "status": "completed",
    "model": "sonnet"
  },
  {
    "id": "B-001",
    "category": "Blueprint",
    "title": "Create Blueprint node layout engine",
    "description": "Create Sources/MissionControl/Views/Blueprint/BlueprintLayout.swift. Define the 12-node layout as a computed graph: vertical flow with branching at lint (pass/fail) and CI attempts (pass/fail). Each node has a position (CGPoint), size (CGSize), and connections to next nodes. The layout engine calculates positions for the full 12-node sequence from docs/blueprint-engine.md: IMPLEMENT TASK -> RUN LINTERS -> (fail) FIX LINT -> GIT COMMIT -> PUSH BRANCH -> CI ATTEMPT 1 -> (fail) FIX CI 1 -> CI ATTEMPT 2 -> (fail) FIX CI 2 -> CI FINAL -> CREATE PR / HUMAN REVIEW. Success path flows straight down, failure branches offset to the right then rejoin. Return [NodeLayout] with id, position, size, nodeType, connections [(fromPoint, toPoint, isFailurePath)].",
    "dependencies": ["D-001"],
    "status": "completed",
    "model": "opus"
  },
  {
    "id": "B-002",
    "category": "Blueprint",
    "title": "Create Blueprint node views",
    "description": "Create Sources/MissionControl/Views/Blueprint/BlueprintNodeView.swift. Agentic nodes: rounded cloud shape using custom Path with soft curves, indigo gradient border (2pt), inner glow effect when active, icon + name + duration label. Deterministic nodes: sharp rectangle with 4pt corner radius, blue-gray border, icon + name + duration. Both show status: pending (dim, gray), running (bright glow, pulsing animation), completed (green tint, checkmark), failed (red tint, xmark), skipped (very dim). Selected node has a highlight ring. Create Sources/MissionControl/Views/Blueprint/ConnectionView.swift drawing bezier curves between nodes with animated dashed stroke for pending, solid for completed, red for failed paths.",
    "dependencies": ["B-001"],
    "status": "completed",
    "model": "opus"
  },
  {
    "id": "B-003",
    "category": "Blueprint",
    "title": "Create animated particle flow system",
    "description": "Create Sources/MissionControl/Views/Blueprint/ParticleFlowView.swift. Implement a particle system that animates small glowing dots (3-4pt circles) traveling along the connection bezier paths between nodes. Particles flow from completed nodes toward the active node. Use TimelineView for smooth 60fps animation. Particle properties: position along path (0.0-1.0), opacity (fade in/out at endpoints), color (indigo for success path, red for failure path), speed (configurable via simulationSpeed). Show 3-5 particles per active connection, staggered. Particles should have a subtle trail effect (2-3 fading copies behind).",
    "dependencies": ["B-002"],
    "status": "completed",
    "model": "opus"
  },
  {
    "id": "B-004",
    "category": "Blueprint",
    "title": "Create Blueprint canvas and control bar",
    "description": "Create Sources/MissionControl/Views/Blueprint/BlueprintCanvasView.swift combining all Blueprint sub-views into a scrollable, zoomable canvas. Use ScrollView with magnification gesture. Layer order: background grid pattern, connections, particles, nodes. Add floating control bar (HStack, pill-shaped, glass background) at top with: Play/Pause button, Step Forward button, Reset button, Speed slider (1x-5x), current node label. Add floating side panel (right) when a node is selected showing: node name, type, status, duration, output log (scrollable, SF Mono), retry count. Create Sources/MissionControl/Views/Blueprint/BlueprintView.swift as the screen wrapper that creates BlueprintCanvasView with the BlueprintViewModel.",
    "dependencies": ["B-003", "C-002"],
    "status": "completed",
    "model": "opus"
  },
  {
    "id": "B-005",
    "category": "Blueprint",
    "title": "Add Blueprint cinematic effects",
    "description": "Enhance BlueprintCanvasView with cinematic polish: 1) Background: subtle dot grid pattern that parallax-scrolls slightly on mouse movement. 2) Active node: pulsing glow ring animation (scale 1.0->1.05, opacity 0.6->1.0, repeating). 3) Node completion: brief flash animation (white overlay fade out over 0.3s). 4) Connection activation: draw-on animation (trim from 0->1 over 0.5s) when a new connection becomes active. 5) Global ambient particles: very faint, slow-moving dots in background for atmosphere. 6) Smooth camera auto-scroll to keep the active node centered. Use withAnimation(.spring) for all state transitions.",
    "dependencies": ["B-004"],
    "status": "completed",
    "model": "opus"
  },
  {
    "id": "S-001",
    "category": "Sandbox Manager",
    "title": "Create Sandbox Manager screen",
    "description": "Create Sources/MissionControl/Views/Sandbox/SandboxView.swift as main screen. Top section: PoolStatsBar showing pool size, available, in-use as a segmented visual meter with labels. Filter bar: Picker for status filter + TextField for search. Main content: LazyVGrid (columns: adaptive minimum 320pt) of SandboxCardView. Create Sources/MissionControl/Views/Sandbox/PoolStatsBar.swift with horizontal bar segments colored by status. Create Sources/MissionControl/Views/Sandbox/SandboxCardView.swift showing: task ID (monospace), branch name, status pill (colored per status), project path, created time, duration, pipeline stage as mini progress dots, action buttons (Open Terminal - launches via SandboxViewModel.openTerminal, View Logs, Cleanup). Wire to SandboxViewModel with .task loading and filtered results.",
    "dependencies": ["C-003", "N-001"],
    "status": "completed",
    "model": "sonnet"
  },
  {
    "id": "A-001",
    "category": "Agent Profiles",
    "title": "Create Agent Profiles screen",
    "description": "Create Sources/MissionControl/Views/AgentProfiles/AgentProfilesView.swift as main screen. Top section: 'Route a Task' card with TextField bound to vm.taskInput, a 'Route' button, and result display showing detected type, selected agent name (highlighted), complexity badge, and keyword matches (each in a chip). Main content: LazyVGrid (2 columns) of AgentCardView. Create Sources/MissionControl/Views/AgentProfiles/AgentCardView.swift showing: SF Symbol avatar in colored circle (paintbrush.pointed for Frontend/purple, server.rack for Backend/blue, cloud for Infra/orange, doc.text for Docs/green, checkmark.shield for Test/teal, star for Generalist/indigo), display name, model badge, timeout + max files stats, task type pills, truncated system prompt (expandable via disclosure). Create Sources/MissionControl/Views/AgentProfiles/TaskRoutingResultView.swift for the routing result display. Wire all to AgentProfilesViewModel.",
    "dependencies": ["C-004", "N-001"],
    "status": "completed",
    "model": "sonnet"
  },
  {
    "id": "L-001",
    "category": "Audit Log",
    "title": "Create Audit Log screen",
    "description": "Create Sources/MissionControl/Views/AuditLog/AuditLogView.swift as main screen. Toolbar: Toggle('Live Data'/'Mock Data'), search TextField with magnifying glass icon, filter chips for each AuditEventType (multi-select, colored), auto-scroll toggle, export button (Menu with JSON/CSV options). Main content: Table with columns - Timestamp (SF Mono, secondary color), Task ID (monospace, clickable), Event Type (StatusPill with event-specific colors), Data (truncated, expandable), Duration. Create Sources/MissionControl/Views/AuditLog/AuditEventRow.swift for custom row rendering with expandable JSON detail view. Create Sources/MissionControl/Views/AuditLog/AuditEventDetailView.swift showing full JSON with syntax-highlighted formatting (color keywords, strings, numbers differently). Wire to AuditLogViewModel.",
    "dependencies": ["C-005", "N-001"],
    "status": "completed",
    "model": "sonnet"
  },
  {
    "id": "L-002",
    "category": "Audit Log",
    "title": "Implement real JSONL file reading",
    "description": "Create Sources/MissionControl/Services/Mock/RealAuditFileService.swift implementing AuditFileServiceProtocol. Reads actual ~/.minion/audit/audit-YYYY-MM-DD.jsonl files. Parse each line as JSON, map to AuditEvent model. Handle malformed lines gracefully (skip with warning). Implement availableLogFiles() scanning the audit directory. Add file watching using DispatchSource.makeFileSystemObjectSource for live-tailing new events. Update AuditLogViewModel to switch between MockAuditFileService and RealAuditFileService based on useLiveData toggle. Handle case where ~/.minion/audit/ doesn't exist (show helpful message).",
    "dependencies": ["L-001"],
    "status": "completed",
    "model": "sonnet"
  },
  {
    "id": "P-001",
    "category": "Settings",
    "title": "Create Settings screen",
    "description": "Create Sources/MissionControl/Views/Settings/SettingsView.swift using Form with grouped sections. Connection section: TextField for bridge URL, SecureField for API key, Button 'Test Connection' with inline status (checkmark.circle.fill green or xmark.circle.fill red). Refresh section: Slider for dashboard interval (5-60s, step 5), Slider for audit interval (1-30s, step 1), labels showing current values. Appearance section: Picker (Dark/Light/System) with .segmentedPickerStyle, color swatches for accent (5 preset colors as tappable circles). Audit section: TextField for audit path with folder icon button (opens NSOpenPanel), Stepper for max events. Terminal section: detected terminal display with Picker override. Advanced section: Button 'Reset to Defaults' (with confirmation alert), Toggle for debug logging. Wire to SettingsViewModel. Use @AppStorage for persistence.",
    "dependencies": ["C-005", "N-001"],
    "status": "completed",
    "model": "sonnet"
  },
  {
    "id": "M-001",
    "category": "Menu Bar",
    "title": "Create Menu Bar Extra",
    "description": "Create Sources/MissionControl/Views/MenuBar/MenuBarView.swift for the MenuBarExtra content. Show: connection status header (colored dot + 'Connected'/'Disconnected'), stats row (Active: N, Success: N%, Queue: N) in compact HStack, divider, last 3 audit events as compact rows (time + event type + task ID), divider, buttons: 'Open Dashboard' (opens/focuses main window), 'Launch Task...' (opens sheet with text field), 'View Audit Log' (switches to audit tab). Footer: 'Settings...' link + version label. Update MissionControlApp.swift MenuBarExtra to use this view with a systemImage that changes based on connection status (circle.fill colored green/red). Keep the menu bar view lightweight - it reads from shared ViewModels.",
    "dependencies": ["C-001", "C-005", "N-002"],
    "status": "pending",
    "model": "sonnet"
  },
  {
    "id": "T-001",
    "category": "Testing",
    "title": "Create ViewModel unit tests",
    "description": "Create Tests/MissionControlTests/DashboardViewModelTests.swift: test loadData populates metrics and recentTasks, test auto-refresh timer fires, test error handling. Create Tests/MissionControlTests/BlueprintViewModelTests.swift: test loadRun creates 12 nodes, test simulation advances through nodes, test pause/resume, test stepForward, test reset. Create Tests/MissionControlTests/AuditLogViewModelTests.swift: test loadEvents, test filtering by event type, test search filtering, test data source toggle. All tests use mock services injected via protocol.",
    "dependencies": ["C-001", "C-002", "C-005"],
    "status": "pending",
    "model": "sonnet"
  },
  {
    "id": "T-002",
    "category": "Testing",
    "title": "Create model and service tests",
    "description": "Create Tests/MissionControlTests/ModelTests.swift: test BlueprintNode status transitions, test Sandbox status values, test AuditEvent Codable round-trip (encode then decode), test TaskComplexity estimation logic. Create Tests/MissionControlTests/MockServiceTests.swift: test MockBridgeService returns expected counts (6 agent profiles, 12 blueprint nodes, etc.), test mock delays are within expected range, test all protocol methods return valid data.",
    "dependencies": ["D-003"],
    "status": "pending",
    "model": "sonnet"
  },
  {
    "id": "T-003",
    "category": "Testing",
    "title": "Create UI tests",
    "description": "Create Tests/MissionControlUITests/NavigationUITests.swift: test app launches successfully, test all 6 sidebar items are visible, test tapping each sidebar item changes the content view, test keyboard shortcuts Cmd+1 through Cmd+6 switch tabs. Create Tests/MissionControlUITests/DashboardUITests.swift: test metric cards are visible, test recent tasks table has rows, test quick launch text field accepts input. Use XCUIApplication and standard accessibility identifiers. Add .accessibilityIdentifier() to key views in the main screens.",
    "dependencies": ["H-002", "N-002"],
    "status": "pending",
    "model": "sonnet"
  },
  {
    "id": "X-001",
    "category": "Polish",
    "title": "Add animations and transitions",
    "description": "Add view transition animations throughout the app: 1) Sidebar selection: .animation(.spring(duration: 0.3)) on content switching. 2) Dashboard metric cards: .transition(.scale.combined(with: .opacity)) on appear. 3) Sandbox cards: .animation(.spring) on filter changes. 4) Audit log rows: .transition(.slide) for new events. 5) Settings: .animation(.easeInOut) on section expand/collapse. 6) Loading states: shimmer effect using gradient mask animation on redacted placeholders. Add matchedGeometryEffect for smooth transitions between sidebar and content where appropriate. Ensure all animations respect .reducedMotion accessibility setting.",
    "dependencies": ["H-002", "B-005", "S-001", "A-001", "L-001", "P-001"],
    "status": "pending",
    "model": "sonnet"
  },
  {
    "id": "X-002",
    "category": "Polish",
    "title": "Final compilation fix and cleanup",
    "description": "Run 'swift build' and fix ALL compiler errors. Run 'swift test' and fix ALL test failures. Verify: 1) App launches without crashes. 2) All 6 sidebar tabs render their screens. 3) Blueprint simulation can be started and shows animation. 4) Audit log toggle between mock and live works. 5) Settings form is functional. 6) Menu bar extra appears. Remove any dead code, unused imports, or TODO comments. Ensure consistent code style throughout. This is the final task - the app must build and run cleanly.",
    "dependencies": ["X-001", "M-001", "T-003"],
    "status": "pending",
    "model": "sonnet"
  }
]
```
