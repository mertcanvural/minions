import SwiftUI

@Observable
class AppState {
    enum Tab: Hashable {
        case dashboard
        case blueprint
        case sandboxes
        case agents
        case auditLog
        case settings
    }

    enum ThemePreference: String {
        case dark
        case light
        case system
    }

    var selectedTab: Tab = .dashboard
    var bridgeConnected: Bool = false
    var themePreference: ThemePreference = .system
}
