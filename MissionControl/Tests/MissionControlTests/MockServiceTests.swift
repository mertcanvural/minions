import XCTest
@testable import MissionControl

final class MockServiceTests: XCTestCase {

    // MARK: - Agent Profiles Count

    func testMockBridgeServiceReturnsSixAgentProfiles() async throws {
        let service = MockBridgeService()
        let profiles = try await service.fetchAgentProfiles()
        XCTAssertEqual(profiles.count, 6)
    }

    func testMockBridgeServiceAgentProfileNames() async throws {
        let service = MockBridgeService()
        let profiles = try await service.fetchAgentProfiles()
        let names = profiles.map { $0.displayName }
        XCTAssertTrue(names.contains("Frontend Expert"))
        XCTAssertTrue(names.contains("Backend Expert"))
        XCTAssertTrue(names.contains("Infra Expert"))
        XCTAssertTrue(names.contains("Docs Expert"))
        XCTAssertTrue(names.contains("Test Expert"))
        XCTAssertTrue(names.contains("Generalist"))
    }

    func testMockBridgeServiceAgentProfileIds() {
        let profiles = MockBridgeService.agentProfiles
        let ids = profiles.map { $0.id }
        XCTAssertTrue(ids.contains("frontend_expert"))
        XCTAssertTrue(ids.contains("backend_expert"))
        XCTAssertTrue(ids.contains("infra_expert"))
        XCTAssertTrue(ids.contains("docs_expert"))
        XCTAssertTrue(ids.contains("test_expert"))
        XCTAssertTrue(ids.contains("generalist"))
    }

    // MARK: - Blueprint Nodes Count

    func testMockBridgeServiceReturnsTwelveBlueprintNodes() async throws {
        let service = MockBridgeService()
        let run = try await service.fetchBlueprintRun(id: nil)
        XCTAssertEqual(run.nodes.count, 12)
    }

    func testMockBridgeServiceBlueprintRunHasExpectedNodeNames() async throws {
        let service = MockBridgeService()
        let run = try await service.fetchBlueprintRun(id: "test-run")
        let names = run.nodes.map { $0.name }
        XCTAssertTrue(names.contains("Implement Task"))
        XCTAssertTrue(names.contains("Run Linters"))
        XCTAssertTrue(names.contains("Git Commit"))
        XCTAssertTrue(names.contains("Push Branch"))
        XCTAssertTrue(names.contains("Create PR"))
    }

    func testMockBridgeServiceBlueprintRunUsesProvidedId() async throws {
        let service = MockBridgeService()
        let run = try await service.fetchBlueprintRun(id: "custom-id-123")
        XCTAssertEqual(run.id, "custom-id-123")
    }

    func testMockBridgeServiceBlueprintRunUsesDefaultIdWhenNil() async throws {
        let service = MockBridgeService()
        let run = try await service.fetchBlueprintRun(id: nil)
        XCTAssertFalse(run.id.isEmpty)
    }

    func testMockBridgeServiceBlueprintNodesMixAgenticAndDeterministic() async throws {
        let service = MockBridgeService()
        let run = try await service.fetchBlueprintRun(id: nil)
        let agenticCount = run.nodes.filter { $0.nodeType == .agentic }.count
        let deterministicCount = run.nodes.filter { $0.nodeType == .deterministic }.count
        XCTAssertGreaterThan(agenticCount, 0)
        XCTAssertGreaterThan(deterministicCount, 0)
        XCTAssertEqual(agenticCount + deterministicCount, 12)
    }

    // MARK: - Dashboard Metrics

    func testMockBridgeServiceReturnsDashboardMetrics() async throws {
        let service = MockBridgeService()
        let metrics = try await service.fetchDashboardMetrics()
        XCTAssertGreaterThanOrEqual(metrics.activeTasks, 0)
        XCTAssertGreaterThanOrEqual(metrics.successRate, 0.0)
        XCTAssertLessThanOrEqual(metrics.successRate, 1.0)
        XCTAssertGreaterThanOrEqual(metrics.queueDepth, 0)
        XCTAssertGreaterThan(metrics.avgDuration, 0)
    }

    func testMockBridgeServiceMetricsTrendsArePresent() async throws {
        let service = MockBridgeService()
        let metrics = try await service.fetchDashboardMetrics()
        // trends is a value type - verify it has a valid success rate trend
        XCTAssertGreaterThanOrEqual(metrics.trends.successRateTrend, -1.0)
        XCTAssertLessThanOrEqual(metrics.trends.successRateTrend, 1.0)
    }

    // MARK: - Recent Tasks

    func testMockBridgeServiceReturnsEightRecentTasks() async throws {
        let service = MockBridgeService()
        let tasks = try await service.fetchRecentTasks()
        XCTAssertEqual(tasks.count, 8)
    }

    func testMockBridgeServiceRecentTasksHaveValidStatuses() async throws {
        let service = MockBridgeService()
        let tasks = try await service.fetchRecentTasks()
        let validStatuses: Set<String> = ["pending", "running", "completed", "failed"]
        for task in tasks {
            XCTAssertTrue(validStatuses.contains(task.status), "Unexpected status: \(task.status)")
        }
    }

    func testMockBridgeServiceRecentTasksHaveUniqueIds() async throws {
        let service = MockBridgeService()
        let tasks = try await service.fetchRecentTasks()
        let ids = tasks.map { $0.id }
        XCTAssertEqual(ids.count, Set(ids).count, "Task IDs should be unique")
    }

    // MARK: - Sandboxes

    func testMockBridgeServiceReturnsSixSandboxes() async throws {
        let service = MockBridgeService()
        let sandboxes = try await service.fetchSandboxes()
        XCTAssertEqual(sandboxes.count, 6)
    }

    func testMockBridgeServiceSandboxesHaveVariedStatuses() async throws {
        let service = MockBridgeService()
        let sandboxes = try await service.fetchSandboxes()
        let statuses = Set(sandboxes.map { $0.status })
        XCTAssertGreaterThan(statuses.count, 1, "Sandboxes should have varied statuses")
    }

    func testMockBridgeServiceSandboxesHaveUniqueIds() async throws {
        let service = MockBridgeService()
        let sandboxes = try await service.fetchSandboxes()
        let ids = sandboxes.map { $0.id }
        XCTAssertEqual(ids.count, Set(ids).count, "Sandbox IDs should be unique")
    }

    // MARK: - Pool Stats

    func testMockBridgeServicePoolStatsAreValid() async throws {
        let service = MockBridgeService()
        let stats = try await service.fetchPoolStats()
        XCTAssertGreaterThan(stats.poolSize, 0)
        XCTAssertGreaterThanOrEqual(stats.available, 0)
        XCTAssertGreaterThanOrEqual(stats.inUse, 0)
        XCTAssertLessThanOrEqual(stats.available + stats.inUse, stats.poolSize)
    }

    func testMockBridgeServicePoolStatsWarmCountIsCorrect() async throws {
        let service = MockBridgeService()
        let stats = try await service.fetchPoolStats()
        XCTAssertEqual(stats.warm, stats.poolSize - stats.available - stats.inUse)
    }

    // MARK: - Audit Events

    func testMockBridgeServiceReturnsTwentyAuditEvents() async throws {
        let service = MockBridgeService()
        let events = try await service.fetchAuditEvents(limit: 100)
        XCTAssertEqual(events.count, 20)
    }

    func testMockBridgeServiceAuditEventsRespectLimit() async throws {
        let service = MockBridgeService()
        let events = try await service.fetchAuditEvents(limit: 5)
        XCTAssertEqual(events.count, 5)
    }

    func testMockBridgeServiceAuditEventsHaveAllEventTypes() {
        let events = MockBridgeService.mockAuditEvents()
        let types = Set(events.map { $0.eventType })
        // All 8 event types should appear across 20 events
        XCTAssertEqual(types.count, AuditEventType.allCases.count)
    }

    func testMockBridgeServiceAuditEventsHaveNonEmptyTaskIds() {
        let events = MockBridgeService.mockAuditEvents()
        for event in events {
            XCTAssertFalse(event.taskId.isEmpty)
        }
    }

    // MARK: - Task Routing

    func testMockBridgeServiceRoutesFrontendTask() async throws {
        let service = MockBridgeService()
        let result = try await service.routeTask(description: "Create a responsive dashboard component with sidebar")
        XCTAssertEqual(result.detectedType, "frontend")
        XCTAssertEqual(result.selectedAgent.id, "frontend_expert")
    }

    func testMockBridgeServiceRoutesBackendTask() async throws {
        let service = MockBridgeService()
        let result = try await service.routeTask(description: "Add a REST API endpoint for user authentication")
        XCTAssertEqual(result.detectedType, "backend")
        XCTAssertEqual(result.selectedAgent.id, "backend_expert")
    }

    func testMockBridgeServiceRoutesTestingTask() async throws {
        let service = MockBridgeService()
        let result = try await service.routeTask(description: "Write tests for the auth service")
        XCTAssertEqual(result.detectedType, "testing")
        XCTAssertEqual(result.selectedAgent.id, "test_expert")
    }

    func testMockBridgeServiceRoutingIncludesKeywordMatches() async throws {
        let service = MockBridgeService()
        let result = try await service.routeTask(description: "Add a button component with CSS styling")
        XCTAssertFalse(result.keywordMatches.isEmpty)
    }

    func testMockBridgeServiceRoutingReturnsValidComplexity() async throws {
        let service = MockBridgeService()
        let result = try await service.routeTask(description: "Fix the login button style")
        XCTAssertTrue(TaskComplexity.allCases.contains(result.complexity))
    }

    // MARK: - Launch Task

    func testMockBridgeServiceLaunchTaskReturnsTaskId() async throws {
        let service = MockBridgeService()
        let taskId = try await service.launchTask(description: "Add login feature", project: "myapp")
        XCTAssertTrue(taskId.hasPrefix("task-"))
        XCTAssertGreaterThan(taskId.count, 5)
    }

    func testMockBridgeServiceLaunchTaskReturnsUniqueIds() async throws {
        let service = MockBridgeService()
        let id1 = try await service.launchTask(description: "Task A", project: "proj")
        let id2 = try await service.launchTask(description: "Task B", project: "proj")
        XCTAssertNotEqual(id1, id2)
    }

    // MARK: - Mock Delays Are Within Expected Range

    func testMockBridgeServiceFetchMetricsCompletesWithinTimeout() async throws {
        let service = MockBridgeService()
        let start = Date()
        _ = try await service.fetchDashboardMetrics()
        let elapsed = Date().timeIntervalSince(start)
        // Mock delay is 400ms; should complete in under 2 seconds
        XCTAssertLessThan(elapsed, 2.0)
    }

    func testMockBridgeServiceFetchProfilesCompletesWithinTimeout() async throws {
        let service = MockBridgeService()
        let start = Date()
        _ = try await service.fetchAgentProfiles()
        let elapsed = Date().timeIntervalSince(start)
        XCTAssertLessThan(elapsed, 2.0)
    }

    func testMockBridgeServiceFetchPoolStatsCompletesWithinTimeout() async throws {
        let service = MockBridgeService()
        let start = Date()
        _ = try await service.fetchPoolStats()
        let elapsed = Date().timeIntervalSince(start)
        // Mock delay is 300ms
        XCTAssertLessThan(elapsed, 2.0)
    }

    // MARK: - MockAuditFileService

    func testMockAuditFileServiceReturnsTwentyEvents() throws {
        let service = MockAuditFileService()
        let events = try service.loadEvents(from: "/mock/path", limit: 100)
        XCTAssertEqual(events.count, 20)
    }

    func testMockAuditFileServiceRespectsLimit() throws {
        let service = MockAuditFileService()
        let events = try service.loadEvents(from: "/mock/path", limit: 3)
        XCTAssertEqual(events.count, 3)
    }

    func testMockAuditFileServiceAvailableLogFiles() throws {
        let service = MockAuditFileService()
        let files = try service.availableLogFiles(in: "/mock/audit")
        XCTAssertFalse(files.isEmpty)
    }

    func testMockAuditFileServiceEventsHaveValidData() throws {
        let service = MockAuditFileService()
        let events = try service.loadEvents(from: "/mock/path", limit: 100)
        for event in events {
            XCTAssertFalse(event.taskId.isEmpty)
            XCTAssertTrue(AuditEventType.allCases.contains(event.eventType))
        }
    }
}
