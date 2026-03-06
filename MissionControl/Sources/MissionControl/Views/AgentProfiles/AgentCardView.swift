import SwiftUI

struct AgentCardView: View {
    let profile: AgentProfile
    let isSelected: Bool

    @Environment(\.colorScheme) private var colorScheme
    @State private var isHovered = false
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header: avatar + name + model badge
            HStack(alignment: .center, spacing: 12) {
                // Avatar circle with SF Symbol
                ZStack {
                    Circle()
                        .fill(accentColor.opacity(0.15))
                        .frame(width: 48, height: 48)
                    Circle()
                        .stroke(accentColor.opacity(0.4), lineWidth: 1.5)
                        .frame(width: 48, height: 48)
                    Image(systemName: profile.iconName)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(accentColor)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(profile.displayName)
                        .font(DesignTokens.Typography.subheading)
                        .foregroundStyle(DesignTokens.textPrimary(for: colorScheme))
                        .lineLimit(1)

                    // Model badge
                    Text(profile.model)
                        .font(DesignTokens.Typography.codeSmall)
                        .foregroundStyle(accentColor)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(accentColor.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }

                Spacer()
            }

            // Stats row: timeout + max files
            HStack(spacing: DesignTokens.Spacing.itemSpacing) {
                statBadge(icon: "clock", label: "\(profile.timeoutSeconds)s timeout")
                statBadge(icon: "doc.on.doc", label: "\(profile.maxFiles) max files")
            }

            // Task type pills
            if !profile.taskTypes.isEmpty {
                FlowLayout(spacing: 6) {
                    ForEach(profile.taskTypes, id: \.self) { type in
                        Text(type.capitalized)
                            .font(DesignTokens.Typography.caption)
                            .foregroundStyle(accentColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(accentColor.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(accentColor.opacity(0.3), lineWidth: 1)
                            )
                    }
                }
            }

            Divider()
                .background(DesignTokens.border(for: colorScheme))

            // System prompt with expand/collapse
            VStack(alignment: .leading, spacing: 6) {
                Button {
                    withAnimation(.spring(duration: 0.3)) {
                        isExpanded.toggle()
                    }
                } label: {
                    HStack {
                        Text("System Prompt")
                            .font(DesignTokens.Typography.caption)
                            .foregroundStyle(DesignTokens.textSecondary)
                        Spacer()
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(DesignTokens.textSecondary)
                    }
                }
                .buttonStyle(.plain)

                if isExpanded {
                    Text(profile.systemPrompt)
                        .font(DesignTokens.Typography.caption)
                        .foregroundStyle(DesignTokens.textSecondary)
                        .lineLimit(nil)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                } else {
                    Text(profile.systemPrompt)
                        .font(DesignTokens.Typography.caption)
                        .foregroundStyle(DesignTokens.textSecondary)
                        .lineLimit(2)
                }
            }
        }
        .padding(DesignTokens.Spacing.cardPadding)
        .background(DesignTokens.surface(for: colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Spacing.cardRadius))
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Spacing.cardRadius)
                .stroke(
                    isSelected ? accentColor : (isHovered ? accentColor.opacity(0.5) : DesignTokens.border(for: colorScheme)),
                    lineWidth: isSelected ? 2 : 1
                )
        )
        .cardShadow()
        .brightness(isHovered ? DesignTokens.Effects.hoverBrightnessIncrease : 0)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }

    // MARK: - Helpers

    private var accentColor: Color {
        colorForAgent(profile.accentColor)
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

    @ViewBuilder
    private func statBadge(icon: String, label: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundStyle(DesignTokens.textSecondary)
            Text(label)
                .font(DesignTokens.Typography.caption)
                .foregroundStyle(DesignTokens.textSecondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(DesignTokens.border(for: colorScheme).opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

// MARK: - Flow Layout

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
