import SwiftUI

struct SandboxView: View {
    @State private var viewModel = SandboxViewModel()
    @Environment(\.colorScheme) private var colorScheme

    private let columns = [
        GridItem(.adaptive(minimum: 320), spacing: DesignTokens.Spacing.itemSpacing)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sectionSpacing) {
                // Header
                Text("Sandbox Manager")
                    .font(DesignTokens.Typography.title)
                    .foregroundStyle(DesignTokens.textPrimary(for: colorScheme))

                // Pool stats bar
                PoolStatsBar(poolStats: viewModel.poolStats)

                // Filter bar
                filterBar

                // Content
                if viewModel.isLoading {
                    loadingView
                } else if viewModel.filteredSandboxes.isEmpty {
                    emptyView
                } else {
                    LazyVGrid(columns: columns, spacing: DesignTokens.Spacing.itemSpacing) {
                        ForEach(viewModel.filteredSandboxes) { sandbox in
                            SandboxCardView(
                                sandbox: sandbox,
                                onOpenTerminal: {
                                    viewModel.openTerminal(sandbox: sandbox)
                                },
                                onCleanup: {
                                    Task { await viewModel.cleanup(taskId: sandbox.taskId) }
                                }
                            )
                        }
                    }
                }
            }
            .padding(DesignTokens.Spacing.sectionSpacing)
        }
        .background(DesignTokens.background(for: colorScheme))
        .task { await viewModel.loadData() }
    }

    // MARK: - Filter Bar

    private var filterBar: some View {
        HStack(spacing: DesignTokens.Spacing.itemSpacing) {
            // Status picker
            Picker("Status", selection: $viewModel.filterStatus) {
                Text("All").tag(Optional<SandboxStatus>.none)
                ForEach(SandboxStatus.allCases, id: \.self) { status in
                    Text(status.rawValue.capitalized).tag(Optional(status))
                }
            }
            .pickerStyle(.menu)
            .frame(width: 140)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(DesignTokens.surface(for: colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(DesignTokens.border(for: colorScheme), lineWidth: 1)
            )

            // Search field
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(DesignTokens.textSecondary)
                    .font(.system(size: 13))
                TextField("Search by task ID or path...", text: $viewModel.searchQuery)
                    .textFieldStyle(.plain)
                    .font(DesignTokens.Typography.body)
                if !viewModel.searchQuery.isEmpty {
                    Button {
                        viewModel.searchQuery = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(DesignTokens.textSecondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(DesignTokens.surface(for: colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(DesignTokens.border(for: colorScheme), lineWidth: 1)
            )

            Spacer()

            // Refresh button
            Button {
                Task { await viewModel.loadData() }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 13, weight: .medium))
            }
            .buttonStyle(.bordered)
            .controlSize(.regular)
            .help("Refresh")

            // Count label
            Text("\(viewModel.filteredSandboxes.count) sandbox\(viewModel.filteredSandboxes.count == 1 ? "" : "es")")
                .font(DesignTokens.Typography.caption)
                .foregroundStyle(DesignTokens.textSecondary)
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        LazyVGrid(columns: columns, spacing: DesignTokens.Spacing.itemSpacing) {
            ForEach(0..<6, id: \.self) { _ in
                RoundedRectangle(cornerRadius: DesignTokens.Spacing.cardRadius)
                    .fill(DesignTokens.surface(for: colorScheme))
                    .frame(height: 180)
                    .redacted(reason: .placeholder)
            }
        }
    }

    // MARK: - Empty View

    private var emptyView: some View {
        VStack(spacing: DesignTokens.Spacing.itemSpacing) {
            Image(systemName: "shippingbox")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(DesignTokens.textSecondary)
            Text("No sandboxes found")
                .font(DesignTokens.Typography.heading)
                .foregroundStyle(DesignTokens.textPrimary(for: colorScheme))
            Text(viewModel.searchQuery.isEmpty && viewModel.filterStatus == nil
                 ? "No sandboxes are currently active."
                 : "Try adjusting your filters.")
                .font(DesignTokens.Typography.body)
                .foregroundStyle(DesignTokens.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

#Preview {
    SandboxView()
        .environment(AppState())
}
