import Foundation

protocol SettingsServiceProtocol: Sendable {
    var bridgeURL: URL { get set }
    var apiKey: String { get set }
    var dashboardRefreshInterval: TimeInterval { get set }
    var auditRefreshInterval: TimeInterval { get set }
    var theme: AppState.ThemePreference { get set }
    var auditPath: String { get set }
    var terminalPreference: String { get set }

    func save() throws
    func load() throws
    func reset() throws
}
