import SwiftUI

@main
struct MissionControlApp: App {
    @State var appState = AppState()

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
        .windowStyle(.hiddenTitleBar)

        WindowGroup("Blueprint Viewer", id: "blueprint-popout") {
            Text("Blueprint Viewer")
                .environment(appState)
        }

        WindowGroup("Audit Log", id: "audit-popout") {
            Text("Audit Log")
                .environment(appState)
        }

        Settings {
            Text("Settings")
        }

        MenuBarExtra("Mission Control", systemImage: "circle.fill") {
            Text("Menu Bar")
        }
    }
}

#Preview {
    EmptyView()
}
