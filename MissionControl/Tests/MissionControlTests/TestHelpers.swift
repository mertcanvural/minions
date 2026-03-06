import Foundation
@testable import MissionControl

// MARK: - Test Error

enum TestError: Error {
    case intentional
}

// MARK: - Quick Mock Bridge Service (no artificial delays)

struct QuickMockBridgeService: BridgeServiceProtocol {

    func fetchDashboardMetrics() async throws -> DashboardMetrics {
        DashboardMetrics(
            activeTasks: 3,
            successRate: 0.87,
            avgDuration: 142.5,
            queueDepth: 5,
            trends: DashboardMetrics.MetricsTrends(
                activeTasksTrend: 2,
                successRateTrend: 0.03,
                avgDurationTrend: -12.0,
                queueDepthTrend: -1
            )
        )
    }

    func fetchRecentTasks() async throws -> [RecentTask] {
        [
            RecentTask(id: "t1", description: "Test task alpha", agentName: "Backend Expert",
                       status: "completed", duration: 10.0, startedAt: Date()),
            RecentTask(id: "t2", description: "Test task beta", agentName: "Frontend Expert",
                       status: "running", duration: 5.0, startedAt: Date())
        ]
    }

    func fetchBlueprintRun(id: String?) async throws -> BlueprintRun {
        let nodes: [BlueprintNode] = [
            BlueprintNode(id: "node-0",  name: "Implement Task",   nodeType: .agentic,       nextOnSuccess: 1,   nextOnFailure: nil),
            BlueprintNode(id: "node-1",  name: "Run Linters",      nodeType: .deterministic, nextOnSuccess: 3,   nextOnFailure: 2),
            BlueprintNode(id: "node-2",  name: "Fix Lint Issues",  nodeType: .agentic,       nextOnSuccess: 3,   nextOnFailure: nil),
            BlueprintNode(id: "node-3",  name: "Git Commit",       nodeType: .deterministic, nextOnSuccess: 4,   nextOnFailure: nil),
            BlueprintNode(id: "node-4",  name: "Push Branch",      nodeType: .deterministic, nextOnSuccess: 5,   nextOnFailure: nil),
            BlueprintNode(id: "node-5",  name: "CI Attempt 1",     nodeType: .deterministic, nextOnSuccess: 10,  nextOnFailure: 6),
            BlueprintNode(id: "node-6",  name: "Fix CI 1",         nodeType: .agentic,       nextOnSuccess: 7,   nextOnFailure: nil),
            BlueprintNode(id: "node-7",  name: "CI Attempt 2",     nodeType: .deterministic, nextOnSuccess: 10,  nextOnFailure: 8),
            BlueprintNode(id: "node-8",  name: "Fix CI 2",         nodeType: .agentic,       nextOnSuccess: 9,   nextOnFailure: nil),
            BlueprintNode(id: "node-9",  name: "CI Final Attempt", nodeType: .deterministic, nextOnSuccess: 10,  nextOnFailure: 11),
            BlueprintNode(id: "node-10", name: "Create PR",        nodeType: .deterministic, nextOnSuccess: nil, nextOnFailure: nil),
            BlueprintNode(id: "node-11", name: "Human Review",     nodeType: .deterministic, nextOnSuccess: nil, nextOnFailure: nil)
        ]
        return BlueprintRun(
            id: id ?? "run-test",
            taskDescription: "Test blueprint run",
            nodes: nodes,
            startedAt: Date(),
            completedAt: nil,
            status: .running
        )
    }

    func fetchSandboxes() async throws -> [Sandbox] { [] }

    func fetchPoolStats() async throws -> PoolStats {
        PoolStats(poolSize: 3, available: 1, inUse: 1)
    }

    func fetchAgentProfiles() async throws -> [AgentProfile] {
        MockBridgeService.agentProfiles
    }

    func routeTask(description: String) async throws -> TaskRouting {
        TaskRouting(
            detectedType: "backend",
            selectedAgent: MockBridgeService.agentProfiles[1],
            complexity: .simple,
            keywordMatches: ["api"]
        )
    }

    func launchTask(description: String, project: String) async throws -> String {
        "task-test-\(UUID().uuidString.prefix(8).lowercased())"
    }

    func fetchAuditEvents(limit: Int) async throws -> [AuditEvent] {
        Array(MockBridgeService.mockAuditEvents().prefix(limit))
    }
}

// MARK: - Failing Bridge Service (always throws)

struct FailingBridgeService: BridgeServiceProtocol {
    func fetchDashboardMetrics() async throws -> DashboardMetrics { throw TestError.intentional }
    func fetchRecentTasks() async throws -> [RecentTask] { throw TestError.intentional }
    func fetchBlueprintRun(id: String?) async throws -> BlueprintRun { throw TestError.intentional }
    func fetchSandboxes() async throws -> [Sandbox] { throw TestError.intentional }
    func fetchPoolStats() async throws -> PoolStats { throw TestError.intentional }
    func fetchAgentProfiles() async throws -> [AgentProfile] { throw TestError.intentional }
    func routeTask(description: String) async throws -> TaskRouting { throw TestError.intentional }
    func launchTask(description: String, project: String) async throws -> String { throw TestError.intentional }
    func fetchAuditEvents(limit: Int) async throws -> [AuditEvent] { throw TestError.intentional }
}
