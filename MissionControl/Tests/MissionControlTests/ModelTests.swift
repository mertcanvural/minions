import XCTest
@testable import MissionControl

@MainActor
final class ModelTests: XCTestCase {

    // MARK: - BlueprintNode Status Transitions

    func testBlueprintNodeDefaultStatusIsPending() {
        let node = BlueprintNode(
            id: "n1", name: "Test Node", nodeType: .agentic,
            nextOnSuccess: nil, nextOnFailure: nil
        )
        XCTAssertEqual(node.status, .pending)
    }

    func testBlueprintNodeStatusCanTransitionToRunning() {
        var node = BlueprintNode(
            id: "n1", name: "Test Node", nodeType: .deterministic,
            nextOnSuccess: nil, nextOnFailure: nil
        )
        node.status = .running
        XCTAssertEqual(node.status, .running)
    }

    func testBlueprintNodeStatusCanTransitionToCompleted() {
        var node = BlueprintNode(
            id: "n1", name: "Test Node", nodeType: .agentic,
            nextOnSuccess: nil, nextOnFailure: nil
        )
        node.status = .running
        node.status = .completed
        XCTAssertEqual(node.status, .completed)
    }

    func testBlueprintNodeStatusCanTransitionToFailed() {
        var node = BlueprintNode(
            id: "n1", name: "Test Node", nodeType: .deterministic,
            nextOnSuccess: nil, nextOnFailure: nil
        )
        node.status = .running
        node.status = .failed
        XCTAssertEqual(node.status, .failed)
    }

    func testBlueprintNodeStatusCanBeSkipped() {
        var node = BlueprintNode(
            id: "n1", name: "Fix Lint", nodeType: .agentic,
            nextOnSuccess: nil, nextOnFailure: nil
        )
        node.status = .skipped
        XCTAssertEqual(node.status, .skipped)
    }

    func testBlueprintNodeAllStatusValues() {
        XCTAssertEqual(NodeStatus.allCases.count, 5)
        XCTAssertTrue(NodeStatus.allCases.contains(.pending))
        XCTAssertTrue(NodeStatus.allCases.contains(.running))
        XCTAssertTrue(NodeStatus.allCases.contains(.completed))
        XCTAssertTrue(NodeStatus.allCases.contains(.failed))
        XCTAssertTrue(NodeStatus.allCases.contains(.skipped))
    }

    func testBlueprintNodeAllTypes() {
        XCTAssertEqual(NodeType.allCases.count, 2)
        XCTAssertTrue(NodeType.allCases.contains(.agentic))
        XCTAssertTrue(NodeType.allCases.contains(.deterministic))
    }

    func testBlueprintRunDurationCalculation() {
        let start = Date()
        let end = start.addingTimeInterval(120)
        let run = BlueprintRun(
            id: "run-1", taskDescription: "Test",
            nodes: [], startedAt: start, completedAt: end, status: .completed
        )
        XCTAssertEqual(run.duration, 120, accuracy: 1.0)
    }

    func testBlueprintRunDurationUsesNowWhenNotCompleted() {
        let start = Date().addingTimeInterval(-60)
        let run = BlueprintRun(
            id: "run-2", taskDescription: "Running task",
            nodes: [], startedAt: start, completedAt: nil, status: .running
        )
        XCTAssertGreaterThan(run.duration, 59)
        XCTAssertLessThan(run.duration, 70)
    }

    // MARK: - Sandbox Status Values

    func testSandboxStatusAllCases() {
        XCTAssertEqual(SandboxStatus.allCases.count, 6)
        XCTAssertTrue(SandboxStatus.allCases.contains(.warm))
        XCTAssertTrue(SandboxStatus.allCases.contains(.claimed))
        XCTAssertTrue(SandboxStatus.allCases.contains(.running))
        XCTAssertTrue(SandboxStatus.allCases.contains(.completed))
        XCTAssertTrue(SandboxStatus.allCases.contains(.failed))
        XCTAssertTrue(SandboxStatus.allCases.contains(.cleaned))
    }

    func testSandboxDurationIncreasesOverTime() {
        let sandbox = Sandbox(
            id: "sb-1", taskId: "t-1",
            projectPath: "/projects/myapp",
            workspacePath: "/workspace/t-1",
            branchName: "feat/test",
            createdAt: Date().addingTimeInterval(-30),
            status: .running,
            pipelineStage: 3
        )
        XCTAssertGreaterThan(sandbox.duration, 29)
    }

    func testPoolStatsWarmCalculation() {
        // poolSize=6, available=1, inUse=2 -> warm = 6 - 1 - 2 = 3
        let stats = PoolStats(poolSize: 6, available: 1, inUse: 2)
        XCTAssertEqual(stats.warm, 3)
    }

    func testPoolStatsWarmIsZeroWhenFullyAllocated() {
        let stats = PoolStats(poolSize: 4, available: 2, inUse: 2)
        XCTAssertEqual(stats.warm, 0)
    }

    // MARK: - AuditEvent Codable Round-Trip

    func testAuditEventCodableRoundTripWithoutDuration() throws {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let original = AuditEvent(
            timestamp: now,
            taskId: "task-xyz",
            eventType: .taskStarted,
            data: ["description": "Build feature", "agent": "backend_expert"]
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        let decoded = try decoder.decode(AuditEvent.self, from: data)

        XCTAssertEqual(decoded.taskId, original.taskId)
        XCTAssertEqual(decoded.eventType, original.eventType)
        XCTAssertEqual(decoded.data["description"], original.data["description"])
        XCTAssertEqual(decoded.data["agent"], original.data["agent"])
        XCTAssertNil(decoded.durationMs)
        XCTAssertEqual(decoded.timestamp.timeIntervalSince1970,
                        original.timestamp.timeIntervalSince1970, accuracy: 0.001)
    }

    func testAuditEventCodableRoundTripWithDuration() throws {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let original = AuditEvent(
            timestamp: now,
            taskId: "task-abc",
            eventType: .ciResult,
            data: ["attempt": "1", "status": "pass"],
            durationMs: 127000
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        let decoded = try decoder.decode(AuditEvent.self, from: data)

        XCTAssertEqual(decoded.taskId, "task-abc")
        XCTAssertEqual(decoded.eventType, .ciResult)
        XCTAssertEqual(decoded.durationMs, 127000)
        XCTAssertEqual(decoded.data["attempt"], "1")
    }

    func testAuditEventCodableRoundTripAllEventTypes() throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970

        for eventType in AuditEventType.allCases {
            let event = AuditEvent(
                timestamp: Date(timeIntervalSince1970: 1_700_000_000),
                taskId: "task-test",
                eventType: eventType,
                data: ["key": "value"]
            )
            let data = try encoder.encode(event)
            let decoded = try decoder.decode(AuditEvent.self, from: data)
            XCTAssertEqual(decoded.eventType, eventType)
        }
    }

    func testAuditEventAllCases() {
        XCTAssertEqual(AuditEventType.allCases.count, 8)
    }

    func testAuditEventIdIsUnique() {
        let t1 = Date(timeIntervalSince1970: 1000)
        let t2 = Date(timeIntervalSince1970: 2000)
        let e1 = AuditEvent(timestamp: t1, taskId: "task-1", eventType: .taskStarted, data: [:])
        let e2 = AuditEvent(timestamp: t2, taskId: "task-1", eventType: .taskStarted, data: [:])
        XCTAssertNotEqual(e1.id, e2.id)
    }

    // MARK: - TaskComplexity Estimation

    func testComplexitySimpleForShortTask() {
        let vm = AgentProfilesViewModel(service: QuickMockBridgeService())
        let result = vm.estimateComplexity(task: "Add a login button")
        XCTAssertEqual(result, .simple)
    }

    func testComplexityMediumForRefactorKeyword() {
        let vm = AgentProfilesViewModel(service: QuickMockBridgeService())
        // "refactor" (+1) + "migrate" (+1) = score 2 -> medium
        let result = vm.estimateComplexity(task: "Refactor and migrate the authentication service")
        XCTAssertEqual(result, .medium)
    }

    func testComplexitySingleKeywordIsSimple() {
        let vm = AgentProfilesViewModel(service: QuickMockBridgeService())
        // A single complexity keyword only scores 1 point -> simple
        let result = vm.estimateComplexity(task: "Refactor the authentication service")
        XCTAssertEqual(result, .simple)
    }

    func testComplexityMediumForMultipleKeyword() {
        let vm = AgentProfilesViewModel(service: QuickMockBridgeService())
        let result = vm.estimateComplexity(task: "Update multiple components and also migrate the database")
        XCTAssertEqual(result, .medium)
    }

    func testComplexityComplexForHighScore() {
        let vm = AgentProfilesViewModel(service: QuickMockBridgeService())
        // "refactor" (+1) + "migrate" (+1) + "across" (+1) + "many" (+1) = score 4
        let result = vm.estimateComplexity(task: "Refactor and migrate all services across many modules")
        XCTAssertEqual(result, .complex)
    }

    func testComplexityComplexForLongDescription() {
        let vm = AgentProfilesViewModel(service: QuickMockBridgeService())
        // More than 50 words = score +2, plus complexity keywords
        let longTask = Array(repeating: "word", count: 55).joined(separator: " ") + " and also refactor"
        let result = vm.estimateComplexity(task: longTask)
        XCTAssertEqual(result, .complex)
    }

    func testComplexitySimpleForEmptyTask() {
        let vm = AgentProfilesViewModel(service: QuickMockBridgeService())
        let result = vm.estimateComplexity(task: "")
        XCTAssertEqual(result, .simple)
    }

    func testComplexityAllCasesExist() {
        XCTAssertEqual(TaskComplexity.allCases.count, 3)
        XCTAssertTrue(TaskComplexity.allCases.contains(.simple))
        XCTAssertTrue(TaskComplexity.allCases.contains(.medium))
        XCTAssertTrue(TaskComplexity.allCases.contains(.complex))
    }

    func testComplexityMigrateKeyword() {
        let vm = AgentProfilesViewModel(service: QuickMockBridgeService())
        // "migrate" (+1) + "redesign" (+1) = score 2 -> medium
        let result = vm.estimateComplexity(task: "Migrate and redesign the database schema")
        XCTAssertEqual(result, .medium)
    }

    func testComplexityArchitectKeyword() {
        let vm = AgentProfilesViewModel(service: QuickMockBridgeService())
        // "architect" (+1) + "integrate" (+1) = score 2 -> medium
        let result = vm.estimateComplexity(task: "architect and integrate a new microservice layer")
        XCTAssertEqual(result, .medium)
    }
}
