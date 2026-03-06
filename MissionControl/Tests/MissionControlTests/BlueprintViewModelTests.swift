import XCTest
@testable import MissionControl

@MainActor
final class BlueprintViewModelTests: XCTestCase {

    // MARK: - loadRun

    func testLoadRunCreates12Nodes() async {
        let vm = BlueprintViewModel(service: QuickMockBridgeService())
        XCTAssertNil(vm.currentRun)

        await vm.loadRun()

        XCTAssertNotNil(vm.currentRun)
        XCTAssertEqual(vm.currentRun?.nodes.count, 12)
    }

    func testLoadRunResetsAllNodesToPending() async {
        let vm = BlueprintViewModel(service: QuickMockBridgeService())

        await vm.loadRun()

        let allPending = vm.currentRun?.nodes.allSatisfy { $0.status == .pending } ?? false
        XCTAssertTrue(allPending)
    }

    func testLoadRunResetsDurations() async {
        let vm = BlueprintViewModel(service: QuickMockBridgeService())

        await vm.loadRun()

        let allZero = vm.currentRun?.nodes.allSatisfy { $0.duration == 0 } ?? false
        XCTAssertTrue(allZero)
    }

    func testLoadRunInitializesActiveNodeIndex() async {
        let vm = BlueprintViewModel(service: QuickMockBridgeService())

        await vm.loadRun()

        XCTAssertEqual(vm.activeNodeIndex, 0)
        XCTAssertNil(vm.selectedNode)
    }

    func testLoadRunClearsLoadingState() async {
        let vm = BlueprintViewModel(service: QuickMockBridgeService())

        await vm.loadRun()

        XCTAssertFalse(vm.isLoading)
        XCTAssertNil(vm.error)
    }

    func testLoadRunSetsErrorWhenServiceFails() async {
        let vm = BlueprintViewModel(service: FailingBridgeService())

        await vm.loadRun()

        XCTAssertNotNil(vm.error)
        XCTAssertNil(vm.currentRun)
    }

    // MARK: - stepForward

    func testStepForwardMovesPendingNodeToRunning() async {
        let vm = BlueprintViewModel(service: QuickMockBridgeService())
        await vm.loadRun()

        vm.stepForward()

        XCTAssertEqual(vm.currentRun?.nodes[0].status, .running)
        // activeNodeIndex stays at 0 while the node transitions pending->running
        XCTAssertEqual(vm.activeNodeIndex, 0)
    }

    func testStepForwardCompletesRunningNodeAndAdvances() async {
        let vm = BlueprintViewModel(service: QuickMockBridgeService())
        await vm.loadRun()

        vm.stepForward() // pending -> running
        vm.stepForward() // running -> completed, advances

        XCTAssertEqual(vm.currentRun?.nodes[0].status, .completed)
        XCTAssertGreaterThan(vm.activeNodeIndex, 0)
    }

    func testStepForwardDoesNothingWithoutLoadedRun() {
        let vm = BlueprintViewModel(service: QuickMockBridgeService())
        // Should not crash
        vm.stepForward()
        XCTAssertNil(vm.currentRun)
    }

    // MARK: - Simulation

    func testStartSimulationSetsIsSimulating() async {
        let vm = BlueprintViewModel(service: QuickMockBridgeService())
        await vm.loadRun()
        XCTAssertFalse(vm.isSimulating)

        vm.startSimulation()
        XCTAssertTrue(vm.isSimulating)

        vm.pauseSimulation() // cleanup
    }

    func testPauseSimulationStopsIsSimulating() async {
        let vm = BlueprintViewModel(service: QuickMockBridgeService())
        await vm.loadRun()

        vm.startSimulation()
        XCTAssertTrue(vm.isSimulating)

        vm.pauseSimulation()
        XCTAssertFalse(vm.isSimulating)
    }

    func testStartSimulationIsIdempotentWhenAlreadySimulating() async {
        let vm = BlueprintViewModel(service: QuickMockBridgeService())
        await vm.loadRun()

        vm.startSimulation()
        vm.startSimulation() // second call should be a no-op
        XCTAssertTrue(vm.isSimulating)

        vm.pauseSimulation()
    }

    // MARK: - resetSimulation

    func testResetSimulationResetsNodesToInitialState() async {
        let vm = BlueprintViewModel(service: QuickMockBridgeService())
        await vm.loadRun()

        vm.stepForward() // pending -> running
        vm.stepForward() // running -> completed, advances
        XCTAssertEqual(vm.currentRun?.nodes[0].status, .completed)
        XCTAssertGreaterThan(vm.activeNodeIndex, 0)

        vm.resetSimulation()

        XCTAssertEqual(vm.activeNodeIndex, 0)
        let allPending = vm.currentRun?.nodes.allSatisfy { $0.status == .pending } ?? false
        XCTAssertTrue(allPending)
    }

    func testResetSimulationStopsActiveSimulation() async {
        let vm = BlueprintViewModel(service: QuickMockBridgeService())
        await vm.loadRun()

        vm.startSimulation()
        XCTAssertTrue(vm.isSimulating)

        vm.resetSimulation()
        XCTAssertFalse(vm.isSimulating)
    }

    // MARK: - selectNode

    func testSelectNodeSetsSelectedNode() async {
        let vm = BlueprintViewModel(service: QuickMockBridgeService())
        await vm.loadRun()

        vm.selectNode(id: "node-0")

        XCTAssertNotNil(vm.selectedNode)
        XCTAssertEqual(vm.selectedNode?.id, "node-0")
    }

    func testSelectNodeWithInvalidIdLeavesSelectedNodeNil() async {
        let vm = BlueprintViewModel(service: QuickMockBridgeService())
        await vm.loadRun()

        vm.selectNode(id: "nonexistent-node")

        XCTAssertNil(vm.selectedNode)
    }

    // MARK: - Computed Properties

    func testComputedPropertiesBeforeLoad() {
        let vm = BlueprintViewModel(service: QuickMockBridgeService())

        XCTAssertEqual(vm.completedNodeCount, 0)
        XCTAssertEqual(vm.failedNodeCount, 0)
        XCTAssertEqual(vm.currentProgress, 0.0, accuracy: 0.001)
        XCTAssertEqual(vm.estimatedTimeRemaining, 0.0, accuracy: 0.001)
    }

    func testCompletedNodeCountAfterStep() async {
        let vm = BlueprintViewModel(service: QuickMockBridgeService())
        await vm.loadRun()
        XCTAssertEqual(vm.completedNodeCount, 0)

        vm.stepForward() // pending -> running
        vm.stepForward() // running -> completed

        XCTAssertEqual(vm.completedNodeCount, 1)
    }

    func testCurrentProgressAfterCompletingFirstNode() async {
        let vm = BlueprintViewModel(service: QuickMockBridgeService())
        await vm.loadRun()
        XCTAssertEqual(vm.currentProgress, 0.0, accuracy: 0.001)

        vm.stepForward() // pending -> running
        vm.stepForward() // running -> completed

        XCTAssertGreaterThan(vm.currentProgress, 0.0)
        // 1 of 12 nodes completed = ~0.0833
        XCTAssertEqual(vm.currentProgress, 1.0 / 12.0, accuracy: 0.01)
    }
}
