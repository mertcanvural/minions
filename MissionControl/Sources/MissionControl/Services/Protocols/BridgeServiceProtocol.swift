import Foundation

protocol BridgeServiceProtocol: Sendable {
    func fetchDashboardMetrics() async throws -> DashboardMetrics
    func fetchRecentTasks() async throws -> [RecentTask]
    func fetchBlueprintRun(id: String?) async throws -> BlueprintRun
    func fetchSandboxes() async throws -> [Sandbox]
    func fetchPoolStats() async throws -> PoolStats
    func fetchAgentProfiles() async throws -> [AgentProfile]
    func routeTask(description: String) async throws -> TaskRouting
    func launchTask(description: String, project: String) async throws -> String
    func fetchAuditEvents(limit: Int) async throws -> [AuditEvent]
}
