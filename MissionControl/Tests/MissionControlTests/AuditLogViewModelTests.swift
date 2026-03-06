import XCTest
@testable import MissionControl

@MainActor
final class AuditLogViewModelTests: XCTestCase {

    // MARK: - loadEvents

    func testLoadEventsPopulatesEvents() async {
        let vm = AuditLogViewModel(bridgeService: QuickMockBridgeService())
        XCTAssertTrue(vm.events.isEmpty)

        await vm.loadEvents()

        XCTAssertFalse(vm.events.isEmpty)
    }

    func testLoadEventsReturnsExpectedCount() async {
        // MockBridgeService.mockAuditEvents() has 20 events; limit is 100
        let vm = AuditLogViewModel(bridgeService: QuickMockBridgeService())
        await vm.loadEvents()

        XCTAssertEqual(vm.events.count, 20)
    }

    func testLoadEventsClearsLoadingState() async {
        let vm = AuditLogViewModel(bridgeService: QuickMockBridgeService())

        await vm.loadEvents()

        XCTAssertFalse(vm.isLoading)
        XCTAssertNil(vm.error)
    }

    func testLoadEventsSetsErrorWhenServiceFails() async {
        let vm = AuditLogViewModel(bridgeService: FailingBridgeService())

        await vm.loadEvents()

        XCTAssertNotNil(vm.error)
    }

    // MARK: - filteredEvents — no filter

    func testFilteredEventsShowsAllWhenNoFilterApplied() async {
        let vm = AuditLogViewModel(bridgeService: QuickMockBridgeService())
        await vm.loadEvents()

        XCTAssertTrue(vm.selectedEventTypes.isEmpty)
        XCTAssertEqual(vm.filteredEvents.count, vm.events.count)
    }

    // MARK: - filteredEvents — event type filter

    func testFilteringByEventTypeReturnOnlyMatchingEvents() async {
        let vm = AuditLogViewModel(bridgeService: QuickMockBridgeService())
        await vm.loadEvents()

        vm.selectedEventTypes = [.taskStarted]

        XCTAssertFalse(vm.filteredEvents.isEmpty)
        XCTAssertTrue(vm.filteredEvents.allSatisfy { $0.eventType == .taskStarted })
        XCTAssertLessThan(vm.filteredEvents.count, vm.events.count)
    }

    func testFilteringByMultipleEventTypesIncludesAll() async {
        let vm = AuditLogViewModel(bridgeService: QuickMockBridgeService())
        await vm.loadEvents()

        vm.selectedEventTypes = [.taskStarted, .taskCompleted]

        XCTAssertFalse(vm.filteredEvents.isEmpty)
        XCTAssertTrue(vm.filteredEvents.allSatisfy {
            $0.eventType == .taskStarted || $0.eventType == .taskCompleted
        })
    }

    func testClearingEventTypeFilterRestoresAll() async {
        let vm = AuditLogViewModel(bridgeService: QuickMockBridgeService())
        await vm.loadEvents()
        let totalCount = vm.events.count

        vm.selectedEventTypes = [.taskFailed]
        XCTAssertLessThan(vm.filteredEvents.count, totalCount)

        vm.selectedEventTypes = []
        XCTAssertEqual(vm.filteredEvents.count, totalCount)
    }

    // MARK: - filteredEvents — search

    func testSearchFilteringByTaskId() async {
        let vm = AuditLogViewModel(bridgeService: QuickMockBridgeService())
        await vm.loadEvents()

        vm.searchQuery = "task-001"

        XCTAssertFalse(vm.filteredEvents.isEmpty)
        XCTAssertTrue(vm.filteredEvents.allSatisfy {
            $0.taskId.localizedCaseInsensitiveContains("task-001")
            || $0.eventType.rawValue.localizedCaseInsensitiveContains("task-001")
            || $0.data.values.contains { $0.localizedCaseInsensitiveContains("task-001") }
        })
    }

    func testSearchFilteringByEventTypeRawValue() async {
        let vm = AuditLogViewModel(bridgeService: QuickMockBridgeService())
        await vm.loadEvents()

        vm.searchQuery = "task_started"

        XCTAssertFalse(vm.filteredEvents.isEmpty)
        // All results should contain "task_started" in some field
        XCTAssertTrue(vm.filteredEvents.allSatisfy {
            $0.taskId.localizedCaseInsensitiveContains("task_started")
            || $0.eventType.rawValue.localizedCaseInsensitiveContains("task_started")
            || $0.data.values.contains { $0.localizedCaseInsensitiveContains("task_started") }
        })
    }

    func testEmptySearchQueryShowsAllEvents() async {
        let vm = AuditLogViewModel(bridgeService: QuickMockBridgeService())
        await vm.loadEvents()
        let totalCount = vm.events.count

        vm.searchQuery = "xyz-nonexistent-query-abc"
        XCTAssertTrue(vm.filteredEvents.isEmpty)

        vm.searchQuery = ""
        XCTAssertEqual(vm.filteredEvents.count, totalCount)
    }

    // MARK: - filteredEvents — combined

    func testCombinedTypeFilterAndSearchNarrowsResults() async {
        let vm = AuditLogViewModel(bridgeService: QuickMockBridgeService())
        await vm.loadEvents()

        vm.selectedEventTypes = [.taskStarted]
        vm.searchQuery = "task-001"

        XCTAssertFalse(vm.filteredEvents.isEmpty)
        XCTAssertTrue(vm.filteredEvents.allSatisfy { $0.eventType == .taskStarted })
        XCTAssertTrue(vm.filteredEvents.allSatisfy {
            $0.taskId.localizedCaseInsensitiveContains("task-001")
            || $0.data.values.contains { $0.localizedCaseInsensitiveContains("task-001") }
        })
    }

    // MARK: - Data Source Toggle

    func testUseLiveDataDefaultsToFalse() {
        let vm = AuditLogViewModel(bridgeService: QuickMockBridgeService())
        XCTAssertFalse(vm.useLiveData)
    }

    func testToggleUseLiveDataFlipsFlag() {
        let vm = AuditLogViewModel(bridgeService: QuickMockBridgeService())
        XCTAssertFalse(vm.useLiveData)

        vm.useLiveData = true
        XCTAssertTrue(vm.useLiveData)

        vm.useLiveData = false
        XCTAssertFalse(vm.useLiveData)
    }
}
