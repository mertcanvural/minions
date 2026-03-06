import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Group {
            switch appState.selectedTab {
            case .dashboard:
                DashboardView()
            case .blueprint:
                BlueprintView()
            case .sandboxes:
                SandboxView()
            case .agents:
                AgentProfilesView()
            case .auditLog:
                placeholderView(title: "Audit Log", icon: "doc.text.magnifyingglass")
            case .settings:
                placeholderView(title: "Settings", icon: "gear")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignTokens.background(for: colorScheme))
    }

    private func placeholderView(title: String, icon: String) -> some View {
        VStack(spacing: DesignTokens.Spacing.itemSpacing) {
            Image(systemName: icon)
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(DesignTokens.textSecondary)
            Text(title)
                .font(DesignTokens.Typography.heading)
                .foregroundStyle(DesignTokens.textPrimary(for: colorScheme))
            Text("Coming soon")
                .font(DesignTokens.Typography.caption)
                .foregroundStyle(DesignTokens.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ContentView()
        .environment(AppState())
}
