import SwiftUI

struct AppCommands: Commands {
    var appState: AppState
    let openWindow: OpenWindowAction

    var body: some Commands {
        CommandMenu("View") {
            Button("Dashboard") {
                appState.selectedTab = .dashboard
            }
            .keyboardShortcut("1", modifiers: .command)

            Button("Blueprint") {
                appState.selectedTab = .blueprint
            }
            .keyboardShortcut("2", modifiers: .command)

            Button("Sandboxes") {
                appState.selectedTab = .sandboxes
            }
            .keyboardShortcut("3", modifiers: .command)

            Button("Agents") {
                appState.selectedTab = .agents
            }
            .keyboardShortcut("4", modifiers: .command)

            Button("Audit Log") {
                appState.selectedTab = .auditLog
            }
            .keyboardShortcut("5", modifiers: .command)

            Button("Settings") {
                appState.selectedTab = .settings
            }
            .keyboardShortcut("6", modifiers: .command)

            Divider()

            Button("Pop Out Blueprint") {
                openWindow(id: "blueprint-popout")
            }
            .keyboardShortcut("b", modifiers: [.command, .shift])

            Button("Pop Out Audit Log") {
                openWindow(id: "audit-popout")
            }
            .keyboardShortcut("a", modifiers: [.command, .shift])
        }
    }
}
