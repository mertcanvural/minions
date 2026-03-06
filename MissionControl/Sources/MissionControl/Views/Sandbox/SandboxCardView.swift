import SwiftUI

struct SandboxCardView: View {
    let sandbox: Sandbox
    let onOpenTerminal: () -> Void
    let onCleanup: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header: task ID + status pill
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(sandbox.taskId)
                        .font(DesignTokens.Typography.code)
                        .foregroundStyle(DesignTokens.textPrimary(for: colorScheme))
                        .lineLimit(1)
                    Text(sandbox.branchName)
                        .font(DesignTokens.Typography.codeSmall)
                        .foregroundStyle(DesignTokens.textSecondary)
                        .lineLimit(1)
                }
                Spacer()
                StatusPill(sandbox.status.rawValue, backgroundColor: statusColor(sandbox.status))
            }

            // Project path
            Text(sandbox.projectPath)
                .font(DesignTokens.Typography.caption)
                .foregroundStyle(DesignTokens.textSecondary)
                .lineLimit(1)
                .truncationMode(.middle)
                .help(sandbox.projectPath)

            // Time + duration row
            HStack {
                Label(relativeTime(from: sandbox.createdAt), systemImage: "clock")
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(DesignTokens.textSecondary)
                if sandbox.status != .warm {
                    Spacer()
                    Text(formatDuration(sandbox.duration))
                        .font(DesignTokens.Typography.caption)
                        .foregroundStyle(DesignTokens.textSecondary)
                }
            }

            // Pipeline stage dots
            pipelineDotsView

            Divider()
                .background(DesignTokens.border(for: colorScheme))

            // Action buttons
            HStack(spacing: 8) {
                if sandbox.status == .running || sandbox.status == .claimed {
                    Button(action: onOpenTerminal) {
                        Label("Terminal", systemImage: "terminal")
                            .font(DesignTokens.Typography.caption)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }

                Button(action: {}) {
                    Label("Logs", systemImage: "doc.text")
                        .font(DesignTokens.Typography.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Spacer()

                if sandbox.status == .completed || sandbox.status == .failed {
                    Button(action: onCleanup) {
                        Label("Cleanup", systemImage: "trash")
                            .font(DesignTokens.Typography.caption)
                    }
                    .buttonStyle(.bordered)
                    .tint(DesignTokens.failure)
                    .controlSize(.small)
                }
            }
        }
        .padding(DesignTokens.Spacing.cardPadding)
        .background(DesignTokens.surface(for: colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Spacing.cardRadius))
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Spacing.cardRadius)
                .stroke(isHovered ? DesignTokens.accent.opacity(0.5) : DesignTokens.border(for: colorScheme), lineWidth: 1)
        )
        .cardShadow()
        .brightness(isHovered ? DesignTokens.Effects.hoverBrightnessIncrease : 0)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }

    // MARK: - Pipeline Dots

    private var pipelineDotsView: some View {
        HStack(spacing: 3) {
            ForEach(1...12, id: \.self) { stage in
                Circle()
                    .fill(stage <= sandbox.pipelineStage ? stageColor(stage) : DesignTokens.border(for: colorScheme))
                    .frame(width: 6, height: 6)
            }
            Spacer()
            Text("Stage \(sandbox.pipelineStage)/12")
                .font(DesignTokens.Typography.codeSmall)
                .foregroundStyle(DesignTokens.textSecondary)
        }
    }

    // MARK: - Helpers

    private func statusColor(_ status: SandboxStatus) -> Color {
        switch status {
        case .warm: return DesignTokens.warning
        case .claimed: return DesignTokens.running
        case .running: return DesignTokens.accent
        case .completed: return DesignTokens.success
        case .failed: return DesignTokens.failure
        case .cleaned: return DesignTokens.pending
        }
    }

    private func stageColor(_ stage: Int) -> Color {
        if sandbox.status == .failed && stage == sandbox.pipelineStage {
            return DesignTokens.failure
        }
        return DesignTokens.accent
    }

    private func relativeTime(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        switch interval {
        case 0..<60: return "\(Int(interval))s ago"
        case 60..<3600: return "\(Int(interval / 60))m ago"
        case 3600..<86400: return "\(Int(interval / 3600))h ago"
        default: return "\(Int(interval / 86400))d ago"
        }
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        if minutes > 0 {
            return "\(minutes)m \(secs)s"
        }
        return "\(secs)s"
    }
}
