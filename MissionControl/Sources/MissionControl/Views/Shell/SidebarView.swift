import SwiftUI

struct SidebarView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        @Bindable var state = appState

        let selectionBinding = Binding<AppState.Tab?>(
            get: { state.selectedTab },
            set: { if let tab = $0 { state.selectedTab = tab } }
        )

        NavigationSplitView {
            VStack(spacing: 0) {
                // App header
                HStack(spacing: 10) {
                    Image(systemName: "cpu")
                        .foregroundStyle(DesignTokens.accent)
                        .font(.system(size: 16, weight: .semibold))
                    Text("Mission Control")
                        .font(DesignTokens.Typography.subheading)
                        .foregroundStyle(DesignTokens.textPrimary(for: colorScheme))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 12)

                Divider()

                List(selection: selectionBinding) {
                    Label("Dashboard", systemImage: "gauge")
                        .tag(AppState.Tab.dashboard)
                        .accessibilityIdentifier("sidebar.dashboard")
                    Label("Blueprint", systemImage: "point.3.connected.trianglepath.dotted")
                        .tag(AppState.Tab.blueprint)
                        .accessibilityIdentifier("sidebar.blueprint")
                    Label("Sandboxes", systemImage: "shippingbox")
                        .tag(AppState.Tab.sandboxes)
                        .accessibilityIdentifier("sidebar.sandboxes")
                    Label("Agents", systemImage: "person.3")
                        .tag(AppState.Tab.agents)
                        .accessibilityIdentifier("sidebar.agents")
                    Label("Audit Log", systemImage: "doc.text.magnifyingglass")
                        .tag(AppState.Tab.auditLog)
                        .accessibilityIdentifier("sidebar.auditLog")
                    Label("Settings", systemImage: "gear")
                        .tag(AppState.Tab.settings)
                        .accessibilityIdentifier("sidebar.settings")
                }
                .listStyle(.sidebar)
                .accentColor(DesignTokens.accent)

                Spacer()

                Divider()

                // Connection status indicator
                HStack(spacing: 8) {
                    Circle()
                        .fill(appState.bridgeConnected ? DesignTokens.success : DesignTokens.failure)
                        .frame(width: 8, height: 8)
                    Text(appState.bridgeConnected ? "Connected" : "Disconnected")
                        .font(DesignTokens.Typography.caption)
                        .foregroundStyle(DesignTokens.textSecondary)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .navigationSplitViewColumnWidth(
                min: 180,
                ideal: DesignTokens.Spacing.sidebarWidth,
                max: 260
            )
        } detail: {
            ContentView()
        }
    }
}

#Preview {
    SidebarView()
        .environment(AppState())
}
