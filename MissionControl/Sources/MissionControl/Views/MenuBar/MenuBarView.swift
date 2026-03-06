import SwiftUI
import AppKit

struct MenuBarView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.openWindow) private var openWindow
    @State private var dashboardVM = DashboardViewModel()
    @State private var auditVM = AuditLogViewModel()
    @State private var showLaunchSheet = false
    @State private var taskInput = ""

    private var lastThreeEvents: [AuditEvent] {
        Array(auditVM.events.prefix(3))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            connectionHeader
                .padding(.bottom, 8)

            statsRow
                .padding(.bottom, 8)

            Divider()
                .padding(.bottom, 8)

            if !lastThreeEvents.isEmpty {
                Text("Recent Events")
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(DesignTokens.textSecondary)
                    .padding(.bottom, 4)

                ForEach(lastThreeEvents) { event in
                    auditEventRow(event: event)
                }

                Divider()
                    .padding(.vertical, 8)
            }

            actionButtons

            Divider()
                .padding(.vertical, 8)

            footerRow
        }
        .padding(12)
        .frame(width: 300)
        .task {
            await dashboardVM.loadData()
            await auditVM.loadEvents()
        }
        .sheet(isPresented: $showLaunchSheet) {
            launchSheet
        }
    }

    // MARK: - Connection Header

    private var connectionHeader: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(appState.bridgeConnected ? DesignTokens.success : DesignTokens.failure)
                .frame(width: 8, height: 8)

            Text(appState.bridgeConnected ? "Connected" : "Disconnected")
                .font(DesignTokens.Typography.subheading)
                .foregroundStyle(appState.bridgeConnected ? DesignTokens.success : DesignTokens.failure)

            Spacer()

            Text("Mission Control")
                .font(DesignTokens.Typography.caption)
                .foregroundStyle(DesignTokens.textSecondary)
        }
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: 16) {
            if let metrics = dashboardVM.metrics {
                statItem(label: "Active", value: "\(metrics.activeTasks)")
                statItem(label: "Success", value: "\(Int(metrics.successRate))%")
                statItem(label: "Queue", value: "\(metrics.queueDepth)")
            } else {
                statItem(label: "Active", value: "—")
                statItem(label: "Success", value: "—")
                statItem(label: "Queue", value: "—")
            }
        }
        .padding(8)
        .background(Color.primary.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func statItem(label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)
            Text(label)
                .font(DesignTokens.Typography.caption)
                .foregroundStyle(DesignTokens.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Audit Event Row

    private func auditEventRow(event: AuditEvent) -> some View {
        HStack(spacing: 8) {
            Text(event.timestamp, format: .dateTime.hour().minute().second())
                .font(DesignTokens.Typography.codeSmall)
                .foregroundStyle(DesignTokens.textSecondary)
                .monospacedDigit()

            Text(event.eventType.displayName)
                .font(DesignTokens.Typography.caption)
                .foregroundStyle(event.eventType.color)
                .lineLimit(1)

            Spacer()

            Text(event.taskId)
                .font(DesignTokens.Typography.codeSmall)
                .foregroundStyle(DesignTokens.textSecondary)
                .lineLimit(1)
                .truncationMode(.middle)
                .frame(maxWidth: 80, alignment: .trailing)
        }
        .padding(.vertical, 2)
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 4) {
            menuButton(icon: "gauge", label: "Open Dashboard") {
                appState.selectedTab = .dashboard
                NSApp.activate(ignoringOtherApps: true)
            }

            menuButton(icon: "plus.circle", label: "Launch Task...") {
                showLaunchSheet = true
            }

            menuButton(icon: "doc.text.magnifyingglass", label: "View Audit Log") {
                appState.selectedTab = .auditLog
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }

    private func menuButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .frame(width: 16)
                    .foregroundStyle(DesignTokens.accent)
                Text(label)
                    .font(DesignTokens.Typography.body)
                Spacer()
            }
            .padding(.vertical, 5)
            .padding(.horizontal, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.primary.opacity(0.0))
        )
    }

    // MARK: - Footer

    private var footerRow: some View {
        HStack {
            Button("Settings...") {
                appState.selectedTab = .settings
                NSApp.activate(ignoringOtherApps: true)
            }
            .buttonStyle(.plain)
            .font(DesignTokens.Typography.caption)
            .foregroundStyle(DesignTokens.textSecondary)

            Spacer()

            Text("v1.0.0")
                .font(DesignTokens.Typography.caption)
                .foregroundStyle(DesignTokens.textSecondary)
        }
    }

    // MARK: - Launch Task Sheet

    private var launchSheet: some View {
        VStack(spacing: 16) {
            Text("Launch Task")
                .font(DesignTokens.Typography.heading)

            TextField("Describe the task...", text: $taskInput, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(3...6)
                .frame(width: 320)

            HStack(spacing: 12) {
                Button("Cancel") {
                    showLaunchSheet = false
                    taskInput = ""
                }
                .keyboardShortcut(.cancelAction)

                Button("Launch") {
                    let description = taskInput
                    showLaunchSheet = false
                    taskInput = ""
                    Task { await dashboardVM.launchTask(description: description) }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(taskInput.trimmingCharacters(in: .whitespaces).isEmpty)
                .buttonStyle(.borderedProminent)
                .tint(DesignTokens.accent)
            }
        }
        .padding(24)
        .frame(minWidth: 380)
    }
}

#Preview {
    MenuBarView()
        .environment(AppState())
}
