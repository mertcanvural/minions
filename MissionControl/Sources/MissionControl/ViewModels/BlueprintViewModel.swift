import Foundation
import Observation

@MainActor
@Observable
final class BlueprintViewModel {

    // MARK: - Properties

    var currentRun: BlueprintRun?
    var selectedNode: BlueprintNode?
    var isSimulating: Bool = false
    var simulationSpeed: Double = 1.0
    var activeNodeIndex: Int = 0
    var isLoading: Bool = false
    var error: Error?

    // MARK: - Computed Properties

    var completedNodeCount: Int {
        currentRun?.nodes.filter { $0.status == .completed }.count ?? 0
    }

    var failedNodeCount: Int {
        currentRun?.nodes.filter { $0.status == .failed }.count ?? 0
    }

    var currentProgress: Double {
        guard let run = currentRun, !run.nodes.isEmpty else { return 0.0 }
        let finished = run.nodes.filter { $0.status == .completed || $0.status == .failed || $0.status == .skipped }.count
        return Double(finished) / Double(run.nodes.count)
    }

    var estimatedTimeRemaining: TimeInterval {
        guard let run = currentRun else { return 0 }
        let completedNodes = run.nodes.filter { $0.status == .completed }
        guard !completedNodes.isEmpty else { return 0 }
        let avgDuration = completedNodes.reduce(0.0) { $0 + $1.duration } / Double(completedNodes.count)
        let remainingCount = run.nodes.filter { $0.status == .pending || $0.status == .running }.count
        return avgDuration * Double(remainingCount) / simulationSpeed
    }

    // MARK: - Private

    private let service: any BridgeServiceProtocol
    private var simulationTask: Task<Void, Never>?

    // MARK: - Init

    init(service: any BridgeServiceProtocol = MockBridgeService()) {
        self.service = service
    }

    // MARK: - Data Loading

    func loadRun(id: String? = nil) async {
        isLoading = true
        error = nil

        do {
            var run = try await service.fetchBlueprintRun(id: id)
            // Reset all nodes to pending for simulation
            for i in run.nodes.indices {
                run.nodes[i].status = .pending
                run.nodes[i].duration = 0
            }
            currentRun = run
            activeNodeIndex = 0
            selectedNode = nil
        } catch {
            self.error = error
        }

        isLoading = false
    }

    // MARK: - Simulation Controls

    func startSimulation() {
        guard currentRun != nil, !isSimulating else { return }
        isSimulating = true
        simulationTask = Task { [weak self] in
            guard let self else { return }
            await self.runSimulationLoop()
        }
    }

    func pauseSimulation() {
        isSimulating = false
        simulationTask?.cancel()
        simulationTask = nil
    }

    func resetSimulation() {
        pauseSimulation()
        guard currentRun != nil else { return }
        for i in currentRun!.nodes.indices {
            currentRun!.nodes[i].status = .pending
            currentRun!.nodes[i].duration = 0
        }
        activeNodeIndex = 0
        selectedNode = nil
    }

    func stepForward() {
        guard var run = currentRun else { return }
        guard activeNodeIndex < run.nodes.count else { return }

        let idx = activeNodeIndex
        // If current node is pending, set to running
        if run.nodes[idx].status == .pending {
            run.nodes[idx].status = .running
            currentRun = run
            return
        }

        // If current node is running, complete it and advance
        if run.nodes[idx].status == .running {
            let result = simulatedOutcome(for: run.nodes[idx], at: idx)
            run.nodes[idx].status = result.status
            run.nodes[idx].duration = result.duration
            run.nodes[idx].output = result.output
            currentRun = run

            advanceToNextNode(from: idx, didFail: result.status == .failed)
        }
    }

    func selectNode(id: String) {
        selectedNode = currentRun?.nodes.first { $0.id == id }
    }

    // MARK: - Simulation Engine

    private func runSimulationLoop() async {
        while !Task.isCancelled, isSimulating {
            guard var run = currentRun else { break }
            guard activeNodeIndex < run.nodes.count else {
                // Simulation complete
                isSimulating = false
                break
            }

            let idx = activeNodeIndex

            // Set node to running
            run.nodes[idx].status = .running
            currentRun = run

            // Wait based on node type and simulation speed
            let baseDuration = run.nodes[idx].nodeType == .agentic
                ? Double.random(in: 2.0...5.0)
                : Double.random(in: 0.5...2.0)
            let scaledDuration = baseDuration / simulationSpeed

            let startTime = Date()
            do {
                try await Task.sleep(for: .seconds(scaledDuration))
            } catch {
                break // Cancelled
            }

            guard !Task.isCancelled, isSimulating else { break }
            guard var updatedRun = currentRun else { break }

            let elapsed = Date().timeIntervalSince(startTime)
            let outcome = simulatedOutcome(for: updatedRun.nodes[idx], at: idx)
            updatedRun.nodes[idx].status = outcome.status
            updatedRun.nodes[idx].duration = elapsed * simulationSpeed
            updatedRun.nodes[idx].output = outcome.output
            currentRun = updatedRun

            // Update selected node if it's the one we just changed
            if selectedNode?.id == updatedRun.nodes[idx].id {
                selectedNode = updatedRun.nodes[idx]
            }

            advanceToNextNode(from: idx, didFail: outcome.status == .failed)
        }
    }

    private struct NodeOutcome {
        let status: NodeStatus
        let duration: TimeInterval
        let output: String
    }

    private func simulatedOutcome(for node: BlueprintNode, at index: Int) -> NodeOutcome {
        // Use predetermined outcomes for the mock scenario
        // Nodes 0-4: succeed (implement, lint pass, commit, push)
        // Node 5 (CI attempt 1): fail to show the failure path
        // Node 6 (Fix CI 1): succeed
        // Node 7 (CI attempt 2): succeed
        // Rest: succeed
        let shouldFail: Bool
        switch index {
        case 1:
            // Lint: 80% pass
            shouldFail = false
        case 5:
            // CI Attempt 1: fail to demonstrate the recovery path
            shouldFail = true
        default:
            shouldFail = false
        }

        let outputs: [Int: (success: String, failure: String)] = [
            0: ("Implementation complete. Modified 3 files with 127 insertions.", "Failed to implement task."),
            1: ("ESLint: 0 errors, 0 warnings. Prettier: all files formatted.", "ESLint: 3 errors found in auth.ts"),
            2: ("Fixed 3 lint issues: unused imports, missing semicolons.", "Unable to fix lint issues."),
            3: ("[feat/auth abc1234] Add JWT authentication\n 3 files changed, 127 insertions(+)", "Git commit failed."),
            4: ("Branch 'feat/auth' pushed to origin.", "Push failed: remote rejected."),
            5: ("GitHub Actions: 142 tests passed, 0 failed.", "GitHub Actions: 2 tests failed\n- test_refresh_token\n- test_token_expiry"),
            6: ("Fixed failing tests by updating token expiry logic.", "Unable to fix CI failures."),
            7: ("GitHub Actions: 144 tests passed, 0 failed.", "GitHub Actions: 1 test failed."),
            8: ("Applied additional CI fixes.", "CI fix attempt 2 failed."),
            9: ("CI passed on final attempt.", "All CI attempts exhausted."),
            10: ("PR #42 created: feat: Add JWT authentication", "Failed to create PR."),
            11: ("Escalated to human review. All CI attempts failed.", "")
        ]

        let pair = outputs[index] ?? ("Step completed.", "Step failed.")
        let status: NodeStatus = shouldFail ? .failed : .completed
        let output = shouldFail ? pair.failure : pair.success
        let duration = node.nodeType == .agentic
            ? Double.random(in: 20...60)
            : Double.random(in: 1...10)

        return NodeOutcome(status: status, duration: duration, output: output)
    }

    private func advanceToNextNode(from index: Int, didFail: Bool) {
        guard let run = currentRun else { return }
        let node = run.nodes[index]

        let nextIndex: Int?
        if didFail {
            nextIndex = node.nextOnFailure
        } else {
            nextIndex = node.nextOnSuccess
        }

        if let next = nextIndex, next < run.nodes.count {
            // Skip nodes between current and next (mark as skipped)
            var updatedRun = run
            for i in (index + 1)..<next {
                if updatedRun.nodes[i].status == .pending {
                    updatedRun.nodes[i].status = .skipped
                }
            }
            currentRun = updatedRun
            activeNodeIndex = next
        } else if nextIndex == nil {
            // Terminal node - simulation complete
            activeNodeIndex = run.nodes.count
            if isSimulating {
                isSimulating = false
                simulationTask?.cancel()
                simulationTask = nil
            }
            // Mark run as completed
            var updatedRun = run
            updatedRun.completedAt = Date()
            updatedRun.status = didFail ? .failed : .completed
            currentRun = updatedRun
        }
    }
}
