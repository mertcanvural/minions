import SwiftUI

struct BlueprintPopoutView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.itemSpacing) {
            Image(systemName: "point.3.connected.trianglepath.dotted")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(DesignTokens.accent)
            Text("Blueprint Viewer")
                .font(DesignTokens.Typography.heading)
                .foregroundStyle(DesignTokens.textPrimary(for: colorScheme))
            Text("Full pipeline visualization coming soon")
                .font(DesignTokens.Typography.caption)
                .foregroundStyle(DesignTokens.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignTokens.background(for: colorScheme))
    }
}

#Preview {
    BlueprintPopoutView()
        .environment(AppState())
}
