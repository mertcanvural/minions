import Foundation
import Observation

@MainActor
@Observable
final class SandboxViewModel {

    // MARK: - Properties

    var sandboxes: [Sandbox] = []
    var poolStats: PoolStats = PoolStats(poolSize: 0, available: 0, inUse: 0)
    var filterStatus: SandboxStatus? = nil
    var searchQuery: String = ""
    var isLoading: Bool = false
    var error: Error?

    // MARK: - Computed

    var filteredSandboxes: [Sandbox] {
        sandboxes.filter { sandbox in
            let matchesStatus = filterStatus == nil || sandbox.status == filterStatus
            let matchesSearch = searchQuery.isEmpty
                || sandbox.taskId.localizedCaseInsensitiveContains(searchQuery)
                || sandbox.branchName.localizedCaseInsensitiveContains(searchQuery)
                || sandbox.projectPath.localizedCaseInsensitiveContains(searchQuery)
            return matchesStatus && matchesSearch
        }
    }

    // MARK: - Private

    private let service: any BridgeServiceProtocol

    // MARK: - Init

    init(service: any BridgeServiceProtocol = MockBridgeService()) {
        self.service = service
    }

    // MARK: - Data Loading

    func loadData() async {
        isLoading = true
        error = nil

        do {
            async let sandboxesResult = service.fetchSandboxes()
            async let poolStatsResult = service.fetchPoolStats()
            let (fetchedSandboxes, fetchedPoolStats) = try await (sandboxesResult, poolStatsResult)
            sandboxes = fetchedSandboxes
            poolStats = fetchedPoolStats
        } catch {
            self.error = error
        }

        isLoading = false
    }

    // MARK: - Terminal

    func openTerminal(sandbox: Sandbox) {
        let path = sandbox.workspacePath

        // Try iTerm2 first, fall back to Terminal.app
        let iTermScript = """
        tell application "iTerm2"
            activate
            create window with default profile
            tell current session of current window
                write text "cd \(path.replacingOccurrences(of: "\"", with: "\\\""))"
            end tell
        end tell
        """

        let terminalScript = """
        tell application "Terminal"
            activate
            do script "cd \(path.replacingOccurrences(of: "\"", with: "\\\""))"
        end tell
        """

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")

        // Check if iTerm2 is installed
        let iTermURL = URL(fileURLWithPath: "/Applications/iTerm.app")
        let iTermExists = FileManager.default.fileExists(atPath: iTermURL.path)

        process.arguments = ["-e", iTermExists ? iTermScript : terminalScript]

        do {
            try process.run()
        } catch {
            self.error = error
        }
    }

    // MARK: - Cleanup

    func cleanup(taskId: String) async {
        // Optimistically update status
        if let index = sandboxes.firstIndex(where: { $0.taskId == taskId }) {
            sandboxes[index].status = .cleaned
        }

        // Reload to get fresh state
        await loadData()
    }
}
