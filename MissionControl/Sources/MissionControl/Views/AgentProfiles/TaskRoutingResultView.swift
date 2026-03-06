import SwiftUI

struct TaskRoutingResultView: View {
    let result: TaskRouting
    let profiles: [AgentProfile]

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header row
            HStack {
                Label("Routing Result", systemImage: "arrow.triangle.branch")
                    .font(DesignTokens.Typography.subheading)
                    .foregroundStyle(DesignTokens.textPrimary(for: colorScheme))
                Spacer()
                complexityBadge
            }

            Divider()
                .background(DesignTokens.border(for: colorScheme))

            // Selected agent highlight
            HStack(spacing: 12) {
                // Agent avatar
                ZStack {
                    Circle()
                        .fill(agentAccentColor.opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: result.selectedAgent.iconName)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(agentAccentColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(result.selectedAgent.displayName)
                        .font(DesignTokens.Typography.subheading)
                        .foregroundStyle(agentAccentColor)
                    Text("Detected type: \(result.detectedType.capitalized)")
                        .font(DesignTokens.Typography.caption)
                        .foregroundStyle(DesignTokens.textSecondary)
                }

                Spacer()
            }
            .padding(10)
            .background(agentAccentColor.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(agentAccentColor.opacity(0.25), lineWidth: 1)
            )

            // Keyword matches
            if !result.keywordMatches.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Keyword matches")
                        .font(DesignTokens.Typography.caption)
                        .foregroundStyle(DesignTokens.textSecondary)

                    FlowLayout(spacing: 6) {
                        ForEach(result.keywordMatches, id: \.self) { keyword in
                            Text(keyword)
                                .font(DesignTokens.Typography.codeSmall)
                                .foregroundStyle(DesignTokens.accent)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(DesignTokens.accent.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(DesignTokens.accent.opacity(0.3), lineWidth: 1)
                                )
                        }
                    }
                }
            }
        }
        .padding(DesignTokens.Spacing.cardPadding)
        .background(DesignTokens.surface(for: colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Spacing.cardRadius))
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Spacing.cardRadius)
                .stroke(DesignTokens.success.opacity(0.4), lineWidth: 1)
        )
        .cardShadow()
    }

    // MARK: - Helpers

    private var agentAccentColor: Color {
        colorForAgent(result.selectedAgent.accentColor)
    }

    private var complexityBadge: some View {
        let (color, label): (Color, String) = {
            switch result.complexity {
            case .simple: return (DesignTokens.success, "Simple")
            case .medium: return (DesignTokens.warning, "Medium")
            case .complex: return (DesignTokens.failure, "Complex")
            }
        }()

        return Text(label)
            .font(DesignTokens.Typography.caption)
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(color.opacity(0.4), lineWidth: 1))
    }

    private func colorForAgent(_ colorName: String) -> Color {
        switch colorName.lowercased() {
        case "purple": return Color(red: 0.68, green: 0.37, blue: 0.93)
        case "blue": return DesignTokens.running
        case "orange": return DesignTokens.warning
        case "green": return DesignTokens.success
        case "teal": return Color(red: 0.19, green: 0.68, blue: 0.68)
        case "indigo": return DesignTokens.accent
        default: return DesignTokens.accent
        }
    }
}

// MARK: - Flow Layout (local copy for TaskRoutingResultView)

private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        var height: CGFloat = 0
        var x: CGFloat = 0
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > width && x > 0 {
                height += lineHeight + spacing
                x = 0
                lineHeight = 0
            }
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
        height += lineHeight
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX && x > bounds.minX {
                y += lineHeight + spacing
                x = bounds.minX
                lineHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
    }
}
