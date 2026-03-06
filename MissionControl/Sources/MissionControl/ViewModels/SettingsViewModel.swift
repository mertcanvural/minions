import Foundation
import Observation

@MainActor
@Observable
final class SettingsViewModel {

    // MARK: - Settings Properties

    var bridgeURL: String = "http://localhost:8080"
    var apiKey: String = ""
    var dashboardRefreshInterval: TimeInterval = 10
    var auditRefreshInterval: TimeInterval = 5
    var theme: AppState.ThemePreference = .system
    var auditPath: String = "\(NSHomeDirectory())/.minion/audit"
    var terminalPreference: String = "auto"
    var maxAuditEvents: Int = 500
    var debugLogging: Bool = false

    // MARK: - UI State

    var isSaving: Bool = false
    var isTestingConnection: Bool = false
    var connectionTestResult: ConnectionTestResult? = nil
    var error: Error?
    var showResetConfirmation: Bool = false

    // MARK: - Private

    private var service: any SettingsServiceProtocol

    // MARK: - Init

    init(service: any SettingsServiceProtocol = MockSettingsService()) {
        self.service = service
        loadFromService()
    }

    // MARK: - Load

    private func loadFromService() {
        bridgeURL = service.bridgeURL.absoluteString
        apiKey = service.apiKey
        dashboardRefreshInterval = service.dashboardRefreshInterval
        auditRefreshInterval = service.auditRefreshInterval
        theme = service.theme
        auditPath = service.auditPath
        terminalPreference = service.terminalPreference
    }

    // MARK: - Save

    func save() async {
        isSaving = true
        error = nil

        service.bridgeURL = URL(string: bridgeURL) ?? URL(string: "http://localhost:8080")!
        service.apiKey = apiKey
        service.dashboardRefreshInterval = dashboardRefreshInterval
        service.auditRefreshInterval = auditRefreshInterval
        service.theme = theme
        service.auditPath = auditPath
        service.terminalPreference = terminalPreference

        do {
            try service.save()
        } catch {
            self.error = error
        }

        isSaving = false
    }

    // MARK: - Test Connection

    func testConnection() async -> Bool {
        isTestingConnection = true
        connectionTestResult = nil

        // Simulate a connection test by attempting to reach the bridge URL
        let url = URL(string: bridgeURL) ?? URL(string: "http://localhost:8080")!
        let healthURL = url.appendingPathComponent("health")

        do {
            var request = URLRequest(url: healthURL)
            request.timeoutInterval = 5
            if !apiKey.isEmpty {
                request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            }
            let (_, response) = try await URLSession.shared.data(for: request)
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            let success = (200..<300).contains(statusCode)
            connectionTestResult = success ? .success : .failure("Server returned \(statusCode)")
            isTestingConnection = false
            return success
        } catch {
            connectionTestResult = .failure(error.localizedDescription)
            isTestingConnection = false
            return false
        }
    }

    // MARK: - Reset

    func resetToDefaults() {
        do {
            try service.reset()
            loadFromService()
            connectionTestResult = nil
            error = nil
        } catch {
            self.error = error
        }
    }

    // MARK: - Terminal Detection

    func detectTerminal() -> String {
        let iTermPath = "/Applications/iTerm.app"
        let warpPath = "/Applications/Warp.app"
        let ghosttyPath = "/Applications/Ghostty.app"

        if FileManager.default.fileExists(atPath: iTermPath) {
            return "iTerm2"
        } else if FileManager.default.fileExists(atPath: warpPath) {
            return "Warp"
        } else if FileManager.default.fileExists(atPath: ghosttyPath) {
            return "Ghostty"
        } else {
            return "Terminal"
        }
    }

    // MARK: - Supporting Types

    enum ConnectionTestResult {
        case success
        case failure(String)

        var isSuccess: Bool {
            if case .success = self { return true }
            return false
        }

        var message: String {
            switch self {
            case .success: return "Connected successfully"
            case .failure(let reason): return reason
            }
        }
    }
}
