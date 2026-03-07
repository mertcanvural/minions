import SwiftUI

@main
struct MissionControlApp: App {
    @State var appState = AppState()
    @Environment(\.openWindow) private var openWindow

    var body: some Scene {
        WindowGroup {
            SidebarView()
                .environment(appState)
                .applyTheme(appState.themePreference)
                .frame(
                    minWidth: DesignTokens.Spacing.minWindowWidth,
                    minHeight: DesignTokens.Spacing.minWindowHeight
                )
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .commands {
            AppCommands(appState: appState, openWindow: openWindow)
        }

        Window("Blueprint Viewer", id: "blueprint-popout") {
            BlueprintPopoutView()
                .environment(appState)
                .applyTheme(appState.themePreference)
                .frame(minWidth: 900, minHeight: 650)
        }

        Window("Audit Log", id: "audit-popout") {
            AuditLogPopoutView()
                .environment(appState)
                .applyTheme(appState.themePreference)
                .frame(minWidth: 800, minHeight: 500)
        }

        Settings {
            Text("Settings")
        }

        MenuBarExtra("Mission Control", systemImage: appState.bridgeConnected ? "circle.fill" : "circle") {
            MenuBarView()
                .environment(appState)
        }
    }
}

#Preview {
    EmptyView()
}
