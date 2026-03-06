import Foundation

final class MockSettingsService: SettingsServiceProtocol, @unchecked Sendable {

    var bridgeURL: URL = URL(string: "http://localhost:8080")!
    var apiKey: String = ""
    var dashboardRefreshInterval: TimeInterval = 10
    var auditRefreshInterval: TimeInterval = 5
    var theme: AppState.ThemePreference = .system
    var auditPath: String = "\(NSHomeDirectory())/.minion/audit"
    var terminalPreference: String = "auto"

    func save() throws {
        // No-op for mock implementation
    }

    func load() throws {
        // No-op for mock implementation — values are already set to defaults
    }

    func reset() throws {
        bridgeURL = URL(string: "http://localhost:8080")!
        apiKey = ""
        dashboardRefreshInterval = 10
        auditRefreshInterval = 5
        theme = .system
        auditPath = "\(NSHomeDirectory())/.minion/audit"
        terminalPreference = "auto"
    }
}
