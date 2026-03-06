import SwiftUI

struct AuditLogPopoutView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.itemSpacing) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(DesignTokens.accent)
            Text("Audit Log")
                .font(DesignTokens.Typography.heading)
                .foregroundStyle(DesignTokens.textPrimary(for: colorScheme))
            Text("Full audit log view coming soon")
                .font(DesignTokens.Typography.caption)
                .foregroundStyle(DesignTokens.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignTokens.background(for: colorScheme))
    }
}

#Preview {
    AuditLogPopoutView()
        .environment(AppState())
}
