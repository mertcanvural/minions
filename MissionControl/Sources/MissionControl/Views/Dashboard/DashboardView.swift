import SwiftUI

struct DashboardView: View {
    @State private var vm = DashboardViewModel()
    @State private var taskInput: String = ""
    @State private var isLaunching: Bool = false
    @State private var launchError: String? = nil

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sectionSpacing) {
                // MARK: Header
                Text("Dashboard")
                    .font(DesignTokens.Typography.title)
                    .foregroundColor(DesignTokens.textPrimary(for: colorScheme))

                // MARK: Metric Cards Row
                HStack(spacing: DesignTokens.Spacing.itemSpacing) {
                    MetricCard(
                        title: "Active Tasks",
                        value: vm.metrics.map { "\($0.activeTasks)" } ?? "—",
                        trend: vm.metrics.map { $0.trends.activeTasksTrend > 0 ? .up : .down },
                        subtitle: vm.metrics.map { trendLabel($0.trends.activeTasksTrend, unit: "") }
                    )

                    MetricCard(
                        title: "Success Rate",
                        value: vm.metrics.map { String(format: "%.0f%%", $0.successRate * 100) } ?? "—",
                        trend: vm.metrics.map { $0.trends.successRateTrend >= 0 ? .up : .down },
                        subtitle: vm.metrics.map { trendLabel(Int($0.trends.successRateTrend * 100), unit: "%") }
                    )

                    MetricCard(
                        title: "Avg Duration",
                        value: vm.metrics.map { formatDuration($0.avgDuration) } ?? "—",
                        trend: vm.metrics.map { $0.trends.avgDurationTrend <= 0 ? .up : .down },
                        subtitle: vm.metrics.map { trendDuration($0.trends.avgDurationTrend) }
                    )

                    MetricCard(
                        title: "Queue Depth",
                        value: vm.metrics.map { "\($0.queueDepth)" } ?? "—",
                        trend: vm.metrics.map { $0.trends.queueDepthTrend <= 0 ? .up : .down },
                        subtitle: vm.metrics.map { trendLabel($0.trends.queueDepthTrend, unit: " tasks") }
                    )
                }

                // MARK: Pipeline Activity Chart
                SectionCard(title: "Pipeline Activity", subtitle: "Completions by hour (last 24h)") {
                    PipelineActivityChart(data: PipelineActivityChart.sampleData)
                }

                // MARK: Bottom Row
                HStack(alignment: .top, spacing: DesignTokens.Spacing.itemSpacing) {
                    // Recent Tasks (wider)
                    SectionCard(title: "Recent Tasks", subtitle: "\(vm.recentTasks.count) tasks") {
                        if vm.isLoading && vm.recentTasks.isEmpty {
                            loadingPlaceholder
                        } else if vm.recentTasks.isEmpty {
                            emptyTasksPlaceholder
                        } else {
                            RecentTasksTable(tasks: vm.recentTasks)
                                .frame(minHeight: 200)
                        }
                    }
                    .frame(maxWidth: .infinity)

                    // Quick Launch (fixed width)
                    SectionCard(title: "Quick Launch", subtitle: nil) {
                        QuickLaunchCard(
                            taskInput: $taskInput,
                            estimatedComplexity: estimatedComplexity,
                            isLaunching: isLaunching,
                            onLaunch: launchTask
                        )
                    }
                    .frame(width: 280)
                }

                // Error banner
                if let error = vm.error {
                    errorBanner(message: error.localizedDescription)
                }

                if let launchError = launchError {
                    errorBanner(message: launchError)
                }
            }
            .padding(DesignTokens.Spacing.sectionSpacing)
        }
        .background(DesignTokens.background(for: colorScheme))
        .task {
            await vm.loadData()
            vm.startAutoRefresh(interval: 10)
        }
        .onDisappear {
            vm.stopAutoRefresh()
        }
    }

    // MARK: - Computed Properties

    private var estimatedComplexity: TaskComplexity? {
        guard !taskInput.trimmingCharacters(in: .whitespaces).isEmpty else { return nil }
        return estimateComplexity(taskInput)
    }

    // MARK: - Sub-views

    private var loadingPlaceholder: some View {
        VStack(spacing: 8) {
            ForEach(0..<4, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 4)
                    .fill(DesignTokens.border(for: colorScheme))
                    .frame(height: 20)
                    .redacted(reason: .placeholder)
            }
        }
    }

    private var emptyTasksPlaceholder: some View {
        VStack(spacing: 8) {
            Image(systemName: "tray")
                .font(.system(size: 28, weight: .light))
                .foregroundColor(DesignTokens.textSecondary)
            Text("No recent tasks")
                .font(DesignTokens.Typography.body)
                .foregroundColor(DesignTokens.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    private func errorBanner(message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(DesignTokens.failure)
            Text(message)
                .font(DesignTokens.Typography.caption)
                .foregroundColor(DesignTokens.failure)
            Spacer()
        }
        .padding(12)
        .background(DesignTokens.failure.opacity(0.1))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(DesignTokens.failure.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Actions

    private func launchTask() {
        let description = taskInput.trimmingCharacters(in: .whitespaces)
        guard !description.isEmpty else { return }

        isLaunching = true
        launchError = nil

        Task {
            do {
                _ = try await MockBridgeService().launchTask(description: description, project: "")
                taskInput = ""
                await vm.loadData()
            } catch {
                launchError = "Launch failed: \(error.localizedDescription)"
            }
            isLaunching = false
        }
    }

    // MARK: - Formatting Helpers

    private func formatDuration(_ seconds: TimeInterval) -> String {
        if seconds < 60 { return String(format: "%.0fs", seconds) }
        let minutes = Int(seconds / 60)
        let secs = Int(seconds.truncatingRemainder(dividingBy: 60))
        return "\(minutes)m \(secs)s"
    }

    private func trendLabel(_ value: Int, unit: String) -> String {
        let sign = value >= 0 ? "+" : ""
        return "\(sign)\(value)\(unit) from last hour"
    }

    private func trendDuration(_ delta: TimeInterval) -> String {
        let abs = Swift.abs(delta)
        let sign = delta <= 0 ? "-" : "+"
        if abs < 60 { return "\(sign)\(Int(abs))s from last hour" }
        let m = Int(abs / 60)
        let s = Int(abs.truncatingRemainder(dividingBy: 60))
        return "\(sign)\(m)m \(s)s from last hour"
    }

    private func estimateComplexity(_ task: String) -> TaskComplexity {
        let lower = task.lowercased()
        let words = lower.components(separatedBy: .whitespaces)
        var score = 0

        if words.count > 50 { score += 2 } else if words.count > 25 { score += 1 }

        let complexityKeywords = ["refactor", "multiple", "rewrite", "migrate", "redesign", "overhaul", "architect", "integrate"]
        for keyword in complexityKeywords where lower.contains(keyword) { score += 1 }

        let multiFileKeywords = ["across", "everywhere", "all files", "many", "several"]
        for keyword in multiFileKeywords where lower.contains(keyword) { score += 1 }

        if lower.contains("and also") || lower.contains("and then") || lower.contains("additionally") { score += 1 }

        if score >= 4 { return .complex }
        if score >= 2 { return .medium }
        return .simple
    }
}

#Preview {
    DashboardView()
        .environment(AppState())
        .frame(width: 1100, height: 700)
}
