import Foundation
import Observation

@MainActor
@Observable
final class DashboardViewModel {

    // MARK: - Published Properties

    var metrics: DashboardMetrics?
    var recentTasks: [RecentTask] = []
    var isLoading: Bool = false
    var error: Error?

    // MARK: - Private

    private let service: any BridgeServiceProtocol
    private var refreshTimer: Task<Void, Never>?

    // MARK: - Init

    init(service: any BridgeServiceProtocol = MockBridgeService()) {
        self.service = service
    }

    // MARK: - Data Loading

    func loadData() async {
        isLoading = true
        error = nil

        do {
            async let metricsResult = service.fetchDashboardMetrics()
            async let tasksResult = service.fetchRecentTasks()
            let (fetchedMetrics, fetchedTasks) = try await (metricsResult, tasksResult)
            metrics = fetchedMetrics
            recentTasks = fetchedTasks
        } catch {
            self.error = error
        }

        isLoading = false
    }

    // MARK: - Auto Refresh

    func startAutoRefresh(interval: TimeInterval = 10) {
        stopAutoRefresh()
        refreshTimer = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(interval))
                guard !Task.isCancelled else { break }
                await self?.loadData()
            }
        }
    }

    func stopAutoRefresh() {
        refreshTimer?.cancel()
        refreshTimer = nil
    }
}
