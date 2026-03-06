import SwiftUI

@main
struct MissionControlApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.hiddenTitleBar)

        WindowGroup("Blueprint Viewer", id: "blueprint-popout") {
            Text("Blueprint Viewer")
        }

        WindowGroup("Audit Log", id: "audit-popout") {
            Text("Audit Log")
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
