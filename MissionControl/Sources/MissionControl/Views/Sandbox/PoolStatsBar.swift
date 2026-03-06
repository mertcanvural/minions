import SwiftUI

struct PoolStatsBar: View {
    let poolStats: PoolStats
    @Environment(\.colorScheme) private var colorScheme

    private var total: Int { max(poolStats.poolSize, 1) }
    private var warmCount: Int { poolStats.warm }
    private var inUseCount: Int { poolStats.inUse }
    private var availableCount: Int { poolStats.available }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Sandbox Pool")
                    .font(DesignTokens.Typography.subheading)
                    .foregroundStyle(DesignTokens.textPrimary(for: colorScheme))
                Spacer()
                Text("\(poolStats.poolSize) total")
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(DesignTokens.textSecondary)
            }

            // Segmented bar
            GeometryReader { geo in
                HStack(spacing: 2) {
                    // In-use segment (running/claimed)
                    if inUseCount > 0 {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(DesignTokens.accent)
                            .frame(width: segmentWidth(count: inUseCount, totalWidth: geo.size.width))
                    }
                    // Warm segment
                    if warmCount > 0 {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(DesignTokens.warning)
                            .frame(width: segmentWidth(count: warmCount, totalWidth: geo.size.width))
                    }
                    // Available segment
                    if availableCount > 0 {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(DesignTokens.success)
                            .frame(width: segmentWidth(count: availableCount, totalWidth: geo.size.width))
                    }
                    // Empty remainder
                    Spacer()
                }
            }
            .frame(height: 12)
            .background(DesignTokens.border(for: colorScheme).opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 4))

            // Labels
            HStack(spacing: DesignTokens.Spacing.sectionSpacing) {
                statLabel(count: inUseCount, label: "in use", color: DesignTokens.accent)
                statLabel(count: warmCount, label: "warm", color: DesignTokens.warning)
                statLabel(count: availableCount, label: "available", color: DesignTokens.success)
                Spacer()
            }
        }
        .padding(DesignTokens.Spacing.cardPadding)
        .background(DesignTokens.surface(for: colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Spacing.cardRadius))
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Spacing.cardRadius)
                .stroke(DesignTokens.border(for: colorScheme), lineWidth: 1)
        )
        .cardShadow()
    }

    private func segmentWidth(count: Int, totalWidth: CGFloat) -> CGFloat {
        guard poolStats.poolSize > 0 else { return 0 }
        let gap: CGFloat = 2
        let segments = CGFloat(poolStats.poolSize)
        let availWidth = totalWidth - (segments - 1) * gap
        return (CGFloat(count) / segments) * availWidth
    }

    private func statLabel(count: Int, label: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text("\(count) \(label)")
                .font(DesignTokens.Typography.caption)
                .foregroundStyle(DesignTokens.textSecondary)
        }
    }
}
