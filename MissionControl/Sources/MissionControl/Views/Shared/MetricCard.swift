import SwiftUI

struct MetricCard: View {
    let title: String
    let value: String
    let trend: Trend?
    let subtitle: String?

    enum Trend {
        case up
        case down

        var icon: String {
            switch self {
            case .up: return "arrow.up"
            case .down: return "arrow.down"
            }
        }

        var color: Color {
            switch self {
            case .up: return DesignTokens.success
            case .down: return DesignTokens.failure
            }
        }
    }

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title
            Text(title)
                .font(DesignTokens.Typography.caption)
                .foregroundColor(DesignTokens.textSecondary)

            // Value with trend
            HStack(alignment: .lastTextBaseline, spacing: 8) {
                Text(value)
                    .font(DesignTokens.Typography.metric)
                    .foregroundColor(DesignTokens.textPrimary(for: colorScheme))

                if let trend = trend {
                    VStack(spacing: 0) {
                        Image(systemName: trend.icon)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(trend.color)
                    }
                }
            }

            // Subtitle
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(DesignTokens.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DesignTokens.Spacing.cardPadding)
        .background(DesignTokens.surface(for: colorScheme))
        .cornerRadius(DesignTokens.Spacing.cardRadius)
        .cardShadow()
    }
}

#Preview {
    VStack(spacing: 16) {
        MetricCard(title: "Active Tasks", value: "12", trend: .up, subtitle: "+2 from yesterday")
        MetricCard(title: "Success Rate", value: "87%", trend: .down, subtitle: "-3% from yesterday")
        MetricCard(title: "Avg Duration", value: "2m 45s", trend: nil, subtitle: nil)
    }
    .padding()
    .background(DesignTokens.backgroundLight)
}
