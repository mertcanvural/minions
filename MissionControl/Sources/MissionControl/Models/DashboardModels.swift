import Foundation

// MARK: - Dashboard Metrics

struct DashboardMetrics: Codable {
    let activeTasks: Int
    let successRate: Double
    let avgDuration: TimeInterval
    let queueDepth: Int
    let trends: MetricsTrends

    struct MetricsTrends: Codable {
        let activeTasksTrend: Int
        let successRateTrend: Double
        let avgDurationTrend: TimeInterval
        let queueDepthTrend: Int
    }
}

// MARK: - Recent Task

struct RecentTask: Identifiable, Codable {
    let id: String
    let description: String
    let agentName: String
    let status: String
    let duration: TimeInterval
    let startedAt: Date
}
