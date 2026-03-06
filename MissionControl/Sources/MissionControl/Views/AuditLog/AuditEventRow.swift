import SwiftUI

struct AuditEventRow: View {
    let event: AuditEvent
    @State private var isExpanded = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            summaryRow
            if isExpanded {
                AuditEventDetailView(event: event)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 10)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(
            isExpanded
                ? DesignTokens.surface(for: colorScheme).opacity(0.35)
                : Color.clear
        )
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                isExpanded.toggle()
            }
        }
    }

    private var summaryRow: some View {
        HStack(spacing: 10) {
            // Expand indicator
            Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(DesignTokens.textSecondary)
                .frame(width: 12)

            // Timestamp
            Text(event.formattedTimestamp)
                .font(DesignTokens.Typography.codeSmall)
                .foregroundStyle(DesignTokens.textSecondary)
                .frame(width: 90, alignment: .leading)
                .lineLimit(1)

            // Task ID
            Text(event.taskId)
                .font(DesignTokens.Typography.codeSmall)
                .foregroundStyle(DesignTokens.accent)
                .frame(width: 150, alignment: .leading)
                .lineLimit(1)
                .truncationMode(.middle)

            // Event Type pill
            StatusPill(
                event.eventType.displayName,
                backgroundColor: event.eventType.color
            )
            .frame(width: 120, alignment: .leading)

            // Data preview
            Text(event.dataPreview)
                .font(DesignTokens.Typography.caption)
                .foregroundStyle(DesignTokens.textSecondary)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Duration
            Group {
                if let ms = event.durationMs {
                    Text("\(ms) ms")
                } else {
                    Text("—")
                }
            }
            .font(DesignTokens.Typography.codeSmall)
            .foregroundStyle(DesignTokens.textSecondary)
            .frame(width: 65, alignment: .trailing)
        }
        .padding(.vertical, 7)
        .padding(.horizontal, 12)
    }
}

#Preview {
    VStack(spacing: 0) {
        AuditEventRow(event: AuditEvent(
            timestamp: Date(),
            taskId: "task-frontend-001",
            eventType: .agentSelected,
            data: ["agent": "Frontend Expert", "model": "claude-opus-4-6"],
            durationMs: 38
        ))
        Divider()
        AuditEventRow(event: AuditEvent(
            timestamp: Date().addingTimeInterval(-60),
            taskId: "task-backend-002",
            eventType: .taskCompleted,
            data: ["result": "success", "pr": "https://github.com/org/repo/pull/42"],
            durationMs: 12500
        ))
    }
    .padding()
    .frame(width: 900)
}
