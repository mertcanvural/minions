import SwiftUI

// MARK: - Blueprint Node View

struct BlueprintNodeView: View {
    let layout: NodeLayout
    let status: NodeStatus
    let duration: TimeInterval
    let isSelected: Bool
    let onTap: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isPulsing = false
    @State private var flashOpacity: CGFloat = 0

    var body: some View {
        Group {
            if layout.nodeType == .agentic {
                agenticNode
            } else {
                deterministicNode
            }
        }
        .overlay {
            // Completion flash overlay
            if flashOpacity > 0 {
                Group {
                    if layout.nodeType == .agentic {
                        AgenticShape()
                            .fill(Color.white)
                            .frame(width: layout.size.width, height: layout.size.height)
                    } else {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white)
                            .frame(width: layout.size.width, height: layout.size.height)
                    }
                }
                .opacity(flashOpacity)
                .allowsHitTesting(false)
            }
        }
        .position(layout.position)
        .onTapGesture(perform: onTap)
        .onChange(of: status) { oldStatus, newStatus in
            isPulsing = (newStatus == .running)

            if !reduceMotion && (newStatus == .completed || newStatus == .failed) && oldStatus == .running {
                flashOpacity = 0.6
                withAnimation(.easeOut(duration: 0.3)) {
                    flashOpacity = 0
                }
            }
        }
        .onAppear {
            isPulsing = (status == .running)
        }
    }

    // MARK: - Agentic Node (Cloud Shape)

    private var agenticNode: some View {
        ZStack {
            // Glow effect when running
            if status == .running {
                AgenticShape()
                    .fill(DesignTokens.accent.opacity(0.3))
                    .frame(width: layout.size.width + 12, height: layout.size.height + 12)
                    .blur(radius: 12)
                    .scaleEffect(isPulsing ? 1.05 : 1.0)
                    .opacity(isPulsing ? 1.0 : 0.6)
                    .animation(
                        .easeInOut(duration: 1.2).repeatForever(autoreverses: true),
                        value: isPulsing
                    )
            }

            // Selection ring
            if isSelected {
                AgenticShape()
                    .stroke(DesignTokens.accent, lineWidth: 3)
                    .frame(width: layout.size.width + 8, height: layout.size.height + 8)
            }

            // Background fill
            AgenticShape()
                .fill(nodeFillColor)
                .frame(width: layout.size.width, height: layout.size.height)

            // Gradient border
            AgenticShape()
                .stroke(
                    LinearGradient(
                        colors: [borderColor, borderColor.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
                .frame(width: layout.size.width, height: layout.size.height)

            // Content
            nodeContent(icon: "cpu")
        }
        .opacity(nodeOpacity)
    }

    // MARK: - Deterministic Node (Sharp Rectangle)

    private var deterministicNode: some View {
        ZStack {
            // Glow effect when running
            if status == .running {
                RoundedRectangle(cornerRadius: 4)
                    .fill(DesignTokens.running.opacity(0.3))
                    .frame(width: layout.size.width + 12, height: layout.size.height + 12)
                    .blur(radius: 12)
                    .scaleEffect(isPulsing ? 1.05 : 1.0)
                    .opacity(isPulsing ? 1.0 : 0.6)
                    .animation(
                        .easeInOut(duration: 1.2).repeatForever(autoreverses: true),
                        value: isPulsing
                    )
            }

            // Selection ring
            if isSelected {
                RoundedRectangle(cornerRadius: 6)
                    .stroke(DesignTokens.accent, lineWidth: 3)
                    .frame(width: layout.size.width + 8, height: layout.size.height + 8)
            }

            // Background fill
            RoundedRectangle(cornerRadius: 4)
                .fill(nodeFillColor)
                .frame(width: layout.size.width, height: layout.size.height)

            // Border
            RoundedRectangle(cornerRadius: 4)
                .stroke(borderColor, lineWidth: status == .skipped ? 1 : 2)
                .frame(width: layout.size.width, height: layout.size.height)
                .if(status == .skipped) { view in
                    view.overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [6, 4]))
                            .foregroundColor(DesignTokens.pending.opacity(0.5))
                            .frame(width: layout.size.width, height: layout.size.height)
                    )
                }

            // Content
            nodeContent(icon: "gearshape")
        }
        .opacity(nodeOpacity)
    }

    // MARK: - Shared Content

    private func nodeContent(icon: String) -> some View {
        HStack(spacing: 8) {
            // Status badge
            statusBadge

            VStack(alignment: .leading, spacing: 2) {
                Text(layout.name)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(textColor)
                    .lineLimit(1)

                if duration > 0 {
                    Text(formattedDuration)
                        .font(DesignTokens.Typography.codeSmall)
                        .foregroundColor(DesignTokens.textSecondary)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .frame(width: layout.size.width, height: layout.size.height)
    }

    @ViewBuilder
    private var statusBadge: some View {
        switch status {
        case .pending:
            Image(systemName: "circle")
                .font(.system(size: 14))
                .foregroundColor(DesignTokens.pending)
        case .running:
            Image(systemName: "circle.fill")
                .font(.system(size: 14))
                .foregroundColor(DesignTokens.running)
                .symbolEffect(.pulse)
        case .completed:
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 14))
                .foregroundColor(DesignTokens.success)
        case .failed:
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 14))
                .foregroundColor(DesignTokens.failure)
        case .skipped:
            Image(systemName: "forward.circle")
                .font(.system(size: 14))
                .foregroundColor(DesignTokens.pending.opacity(0.5))
        }
    }

    // MARK: - Computed Properties

    private var nodeFillColor: Color {
        switch status {
        case .completed:
            return colorScheme == .dark
                ? DesignTokens.success.opacity(0.1)
                : DesignTokens.success.opacity(0.05)
        case .failed:
            return colorScheme == .dark
                ? DesignTokens.failure.opacity(0.1)
                : DesignTokens.failure.opacity(0.05)
        case .running:
            return colorScheme == .dark
                ? DesignTokens.surfaceDark
                : DesignTokens.surfaceLight
        default:
            return colorScheme == .dark
                ? DesignTokens.surfaceDark.opacity(0.8)
                : DesignTokens.surfaceLight.opacity(0.8)
        }
    }

    private var borderColor: Color {
        switch status {
        case .completed: return DesignTokens.success.opacity(0.6)
        case .failed: return DesignTokens.failure.opacity(0.6)
        case .running:
            return layout.nodeType == .agentic ? DesignTokens.accent : DesignTokens.running
        case .skipped: return DesignTokens.pending.opacity(0.3)
        default:
            return layout.nodeType == .agentic
                ? DesignTokens.accent.opacity(0.3)
                : DesignTokens.border(for: colorScheme)
        }
    }

    private var textColor: Color {
        switch status {
        case .skipped: return DesignTokens.textSecondary.opacity(0.5)
        case .pending: return DesignTokens.textSecondary
        default: return DesignTokens.textPrimary(for: colorScheme)
        }
    }

    private var nodeOpacity: Double {
        switch status {
        case .skipped: return 0.35
        case .pending: return 0.6
        default: return 1.0
        }
    }

    private var formattedDuration: String {
        if duration < 1 {
            return String(format: "%.0fms", duration * 1000)
        } else if duration < 60 {
            return String(format: "%.1fs", duration)
        } else {
            let minutes = Int(duration) / 60
            let seconds = Int(duration) % 60
            return "\(minutes)m \(seconds)s"
        }
    }
}

// MARK: - Agentic Shape (Rounded Cloud)

struct AgenticShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let r: CGFloat = 20

        // Rounded cloud-like shape with soft curves
        path.move(to: CGPoint(x: rect.minX + r, y: rect.minY))

        // Top edge
        path.addLine(to: CGPoint(x: rect.maxX - r, y: rect.minY))
        // Top-right corner
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY + r),
            control: CGPoint(x: rect.maxX, y: rect.minY)
        )

        // Right edge
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - r))
        // Bottom-right corner
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX - r, y: rect.maxY),
            control: CGPoint(x: rect.maxX, y: rect.maxY)
        )

        // Bottom edge
        path.addLine(to: CGPoint(x: rect.minX + r, y: rect.maxY))
        // Bottom-left corner
        path.addQuadCurve(
            to: CGPoint(x: rect.minX, y: rect.maxY - r),
            control: CGPoint(x: rect.minX, y: rect.maxY)
        )

        // Left edge
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + r))
        // Top-left corner
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + r, y: rect.minY),
            control: CGPoint(x: rect.minX, y: rect.minY)
        )

        path.closeSubpath()
        return path
    }
}

// MARK: - Conditional View Modifier

extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
