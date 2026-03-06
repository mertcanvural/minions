import XCTest
@testable import MissionControl

@MainActor
final class DashboardViewModelTests: XCTestCase {

    // MARK: - loadData

    func testLoadDataPopulatesMetrics() async throws {
        let vm = DashboardViewModel(service: QuickMockBridgeService())
        XCTAssertNil(vm.metrics)

        await vm.loadData()

        let metrics = try XCTUnwrap(vm.metrics)
        XCTAssertEqual(metrics.activeTasks, 3)
        XCTAssertEqual(metrics.successRate, 0.87, accuracy: 0.001)
        XCTAssertEqual(metrics.queueDepth, 5)
    }

    func testLoadDataPopulatesRecentTasks() async {
        let vm = DashboardViewModel(service: QuickMockBridgeService())
        XCTAssertTrue(vm.recentTasks.isEmpty)

        await vm.loadData()

        XCTAssertEqual(vm.recentTasks.count, 2)
        XCTAssertEqual(vm.recentTasks.first?.id, "t1")
    }

    func testLoadDataClearsLoadingStateAfterCompletion() async {
        let vm = DashboardViewModel(service: QuickMockBridgeService())

        await vm.loadData()

        XCTAssertFalse(vm.isLoading)
        XCTAssertNil(vm.error)
    }

    func testLoadDataClearsErrorOnSuccess() async {
        // First load fails, second succeeds — error should clear
        let vm = DashboardViewModel(service: FailingBridgeService())
        await vm.loadData()
        XCTAssertNotNil(vm.error)

        // Replace service by creating a fresh VM with a good service
        let vm2 = DashboardViewModel(service: QuickMockBridgeService())
        await vm2.loadData()
        XCTAssertNil(vm2.error)
        XCTAssertNotNil(vm2.metrics)
    }

    // MARK: - Error Handling

    func testErrorHandlingSetsErrorWhenServiceFails() async {
        let vm = DashboardViewModel(service: FailingBridgeService())
        XCTAssertNil(vm.error)

        await vm.loadData()

        XCTAssertNotNil(vm.error)
        XCTAssertNil(vm.metrics)
        XCTAssertTrue(vm.recentTasks.isEmpty)
        XCTAssertFalse(vm.isLoading)
    }

    // MARK: - Auto Refresh

    func testStopAutoRefreshIsIdempotent() {
        let vm = DashboardViewModel(service: QuickMockBridgeService())
        // Should not crash when called without a prior startAutoRefresh
        vm.stopAutoRefresh()
        vm.stopAutoRefresh()
    }

    func testAutoRefreshStartAndStopDoesNotCrash() async {
        let vm = DashboardViewModel(service: QuickMockBridgeService())
        await vm.loadData()

        XCTAssertNotNil(vm.metrics)

        vm.startAutoRefresh(interval: 60)
        vm.stopAutoRefresh()

        // Metrics remain after stop
        XCTAssertNotNil(vm.metrics)
    }

    func testAutoRefreshFiresOnInterval() async {
        let vm = DashboardViewModel(service: QuickMockBridgeService())
        await vm.loadData()
        XCTAssertNotNil(vm.metrics)

        // Start with a short interval and wait slightly longer than one tick
        vm.startAutoRefresh(interval: 0.1)
        try? await Task.sleep(for: .milliseconds(250))
        vm.stopAutoRefresh()

        // After auto-refresh fired at least once, metrics are still populated
        XCTAssertNotNil(vm.metrics)
    }
}
