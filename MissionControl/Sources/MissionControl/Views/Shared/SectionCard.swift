import SwiftUI

struct SectionCard<Content: View>: View {
    let title: String
    let subtitle: String?
    @ViewBuilder let content: () -> Content

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.cardPadding) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(DesignTokens.Typography.subheading)
                    .foregroundColor(DesignTokens.textPrimary(for: colorScheme))

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(DesignTokens.Typography.caption)
                        .foregroundColor(DesignTokens.textSecondary)
                }
            }

            // Content
            content()
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
        SectionCard(title: "Recent Tasks", subtitle: "Last 24 hours") {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(1...3, id: \.self) { i in
                    Text("Task \(i)")
                        .font(DesignTokens.Typography.body)
                }
            }
        }

        SectionCard(title: "System Status", subtitle: nil) {
            HStack {
                Circle()
                    .fill(DesignTokens.success)
                    .frame(width: 8, height: 8)
                Text("Connected")
                    .font(DesignTokens.Typography.body)
            }
        }
    }
    .padding()
    .background(DesignTokens.backgroundLight)
}
