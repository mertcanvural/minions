import SwiftUI

// MARK: - AuditEventType Extensions

extension AuditEventType {
    var displayName: String {
        switch self {
        case .taskStarted:     return "Task Started"
        case .agentSelected:   return "Agent Selected"
        case .toolSetSelected: return "Tool Set"
        case .blueprintStep:   return "Blueprint Step"
        case .ciResult:        return "CI Result"
        case .prCreated:       return "PR Created"
        case .taskCompleted:   return "Completed"
        case .taskFailed:      return "Failed"
        }
    }

    var color: Color {
        switch self {
        case .taskStarted:     return DesignTokens.accent
        case .agentSelected:   return Color.purple
        case .toolSetSelected: return Color.teal
        case .blueprintStep:   return DesignTokens.running
        case .ciResult:        return DesignTokens.warning
        case .prCreated:       return DesignTokens.success
        case .taskCompleted:   return DesignTokens.success
        case .taskFailed:      return DesignTokens.failure
        }
    }

    var iconName: String {
        switch self {
        case .taskStarted:     return "play.circle"
        case .agentSelected:   return "person.circle"
        case .toolSetSelected: return "wrench.and.screwdriver"
        case .blueprintStep:   return "arrow.triangle.branch"
        case .ciResult:        return "checkmark.shield"
        case .prCreated:       return "arrow.triangle.pull"
        case .taskCompleted:   return "checkmark.circle"
        case .taskFailed:      return "xmark.circle"
        }
    }
}

// MARK: - AuditEvent Extensions

extension AuditEvent {
    var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter.string(from: timestamp)
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: timestamp)
    }

    var dataPreview: String {
        guard !data.isEmpty else { return "—" }
        return data.sorted(by: { $0.key < $1.key })
            .map { "\($0.key): \($0.value)" }
            .joined(separator: ", ")
    }
}

// MARK: - AuditEventDetailView

struct AuditEventDetailView: View {
    let event: AuditEvent
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerRow
            Divider()
                .background(DesignTokens.border(for: colorScheme))
            jsonBody
        }
        .padding(16)
        .background(DesignTokens.surface(for: colorScheme).opacity(0.4))
        .cornerRadius(8)
    }

    private var headerRow: some View {
        HStack(spacing: 12) {
            Image(systemName: event.eventType.iconName)
                .foregroundStyle(event.eventType.color)
                .font(.system(size: 16, weight: .medium))

            Text(event.eventType.displayName)
                .font(DesignTokens.Typography.subheading)
                .foregroundStyle(event.eventType.color)

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(event.formattedDate)
                    .font(DesignTokens.Typography.codeSmall)
                    .foregroundStyle(DesignTokens.textSecondary)
                if let ms = event.durationMs {
                    Text("\(ms) ms")
                        .font(DesignTokens.Typography.codeSmall)
                        .foregroundStyle(DesignTokens.textSecondary)
                }
            }
        }
    }

    private var jsonBody: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(alignment: .leading, spacing: 0) {
                syntaxHighlightedJSON(data: event.data, taskId: event.taskId)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(12)
            .background(DesignTokens.background(for: colorScheme).opacity(0.6))
            .cornerRadius(6)
        }
        .frame(maxHeight: 280)
    }

    @ViewBuilder
    private func syntaxHighlightedJSON(data: [String: String], taskId: String) -> some View {
        let allPairs: [(String, String)] = [("taskId", taskId)] +
            data.sorted(by: { $0.key < $1.key })

        VStack(alignment: .leading, spacing: 1) {
            jsonLine("{", color: DesignTokens.textSecondary)

            ForEach(Array(allPairs.enumerated()), id: \.offset) { idx, pair in
                HStack(spacing: 0) {
                    Text("  ")
                        .font(DesignTokens.Typography.code)
                    Text("\"\(pair.0)\"")
                        .font(DesignTokens.Typography.code)
                        .foregroundStyle(DesignTokens.accent)
                    Text(": ")
                        .font(DesignTokens.Typography.code)
                        .foregroundStyle(DesignTokens.textSecondary)
                    Text("\"\(pair.1)\"")
                        .font(DesignTokens.Typography.code)
                        .foregroundStyle(DesignTokens.success)
                    if idx < allPairs.count - 1 {
                        Text(",")
                            .font(DesignTokens.Typography.code)
                            .foregroundStyle(DesignTokens.textSecondary)
                    }
                }
            }

            jsonLine("}", color: DesignTokens.textSecondary)
        }
    }

    private func jsonLine(_ text: String, color: Color) -> some View {
        Text(text)
            .font(DesignTokens.Typography.code)
            .foregroundStyle(color)
    }
}

#Preview {
    AuditEventDetailView(event: AuditEvent(
        timestamp: Date(),
        taskId: "task-abc-123",
        eventType: .agentSelected,
        data: ["agent": "Frontend Expert", "model": "claude-opus-4-6", "reason": "UI task detected"],
        durationMs: 42
    ))
    .padding()
    .frame(width: 600)
}
