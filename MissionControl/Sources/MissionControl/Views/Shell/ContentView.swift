import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            switch appState.selectedTab {
            case .dashboard:
                DashboardView()
                    .transition(.opacity)
            case .blueprint:
                BlueprintView()
                    .transition(.opacity)
            case .sandboxes:
                SandboxView()
                    .transition(.opacity)
            case .agents:
                AgentProfilesView()
                    .transition(.opacity)
            case .auditLog:
                AuditLogView()
                    .transition(.opacity)
            case .settings:
                SettingsView()
                    .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignTokens.background(for: colorScheme))
        .animation(reduceMotion ? nil : .spring(duration: 0.3), value: appState.selectedTab)
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
