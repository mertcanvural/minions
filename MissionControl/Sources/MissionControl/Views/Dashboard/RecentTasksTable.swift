import SwiftUI

struct RecentTasksTable: View {
    let tasks: [RecentTask]

    @State private var selection: String? = nil
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Table(tasks, selection: $selection) {
            TableColumn("Task") { task in
                Text(task.description)
                    .font(DesignTokens.Typography.body)
                    .foregroundColor(DesignTokens.textPrimary(for: colorScheme))
                    .lineLimit(1)
            }

            TableColumn("Agent") { task in
                Text(task.agentName)
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(DesignTokens.textSecondary)
                    .lineLimit(1)
            }
            .width(min: 100, ideal: 130, max: 160)

            TableColumn("Status") { task in
                StatusPill(status: task.status)
            }
            .width(min: 70, ideal: 90, max: 100)

            TableColumn("Duration") { task in
                Text(formatDuration(task.duration))
                    .font(DesignTokens.Typography.code)
                    .foregroundColor(DesignTokens.textSecondary)
            }
            .width(min: 60, ideal: 75, max: 90)
        }
        .tableStyle(.inset(alternatesRowBackgrounds: true))
        .accessibilityIdentifier("dashboard.recentTasksTable")
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        guard seconds > 0 else { return "—" }
        if seconds < 60 { return String(format: "%.0fs", seconds) }
        let minutes = Int(seconds / 60)
        let secs = Int(seconds.truncatingRemainder(dividingBy: 60))
        return "\(minutes)m \(secs)s"
    }
}

#Preview {
    let now = Date()
    let tasks = [
        RecentTask(id: "task-001", description: "Add user authentication with JWT", agentName: "Backend Expert", status: "completed", duration: 187.3, startedAt: now.addingTimeInterval(-3600)),
        RecentTask(id: "task-002", description: "Create responsive dashboard component", agentName: "Frontend Expert", status: "running", duration: 45.2, startedAt: now.addingTimeInterval(-900)),
        RecentTask(id: "task-003", description: "Update deployment pipeline to Kubernetes", agentName: "Infra Expert", status: "failed", duration: 78.9, startedAt: now.addingTimeInterval(-300))
    ]
    return RecentTasksTable(tasks: tasks)
        .frame(height: 200)
        .padding()
}
