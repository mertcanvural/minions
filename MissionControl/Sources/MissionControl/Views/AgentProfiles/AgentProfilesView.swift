import SwiftUI

struct AgentProfilesView: View {
    @State private var viewModel = AgentProfilesViewModel()
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedProfileId: String?

    private let columns = [
        GridItem(.adaptive(minimum: 340), spacing: DesignTokens.Spacing.itemSpacing)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sectionSpacing) {
                // Header
                Text("Agent Profiles")
                    .font(DesignTokens.Typography.title)
                    .foregroundStyle(DesignTokens.textPrimary(for: colorScheme))

                // Route a Task card
                routeTaskCard

                // Routing result (shown when available)
                if let result = viewModel.routingResult {
                    TaskRoutingResultView(result: result, profiles: viewModel.profiles)
                        .transition(.scale(scale: 0.97).combined(with: .opacity))
                }

                // Agent grid
                if viewModel.isLoading {
                    loadingView
                } else if viewModel.profiles.isEmpty {
                    emptyView
                } else {
                    agentGrid
                }
            }
            .padding(DesignTokens.Spacing.sectionSpacing)
        }
        .background(DesignTokens.background(for: colorScheme))
        .task { await viewModel.loadProfiles() }
        .animation(.spring(duration: 0.3), value: viewModel.routingResult != nil)
    }

    // MARK: - Route a Task Card

    private var routeTaskCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Route a Task", systemImage: "arrow.triangle.branch")
                    .font(DesignTokens.Typography.subheading)
                    .foregroundStyle(DesignTokens.textPrimary(for: colorScheme))
                Spacer()
                // Live complexity estimate
                if !viewModel.taskInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    let complexity = viewModel.estimateComplexity(task: viewModel.taskInput)
                    complexityChip(for: complexity)
                        .transition(.scale.combined(with: .opacity))
                        .animation(.easeInOut(duration: 0.2), value: viewModel.taskInput)
                }
            }

            HStack(spacing: 10) {
                HStack(spacing: 6) {
                    Image(systemName: "text.cursor")
                        .foregroundStyle(DesignTokens.textSecondary)
                        .font(.system(size: 13))
                    TextField("Describe your task...", text: $viewModel.taskInput)
                        .textFieldStyle(.plain)
                        .font(DesignTokens.Typography.body)
                        .onSubmit {
                            Task { await viewModel.routeTask() }
                        }
                    if !viewModel.taskInput.isEmpty {
                        Button {
                            viewModel.taskInput = ""
                            viewModel.routingResult = nil
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(DesignTokens.textSecondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(DesignTokens.background(for: colorScheme))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(DesignTokens.border(for: colorScheme), lineWidth: 1)
                )

                Button {
                    Task { await viewModel.routeTask() }
                } label: {
                    if viewModel.isRouting {
                        ProgressView()
                            .controlSize(.small)
                            .frame(width: 70)
                    } else {
                        Text("Route")
                            .font(DesignTokens.Typography.body)
                            .frame(width: 70)
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(DesignTokens.accent)
                .disabled(viewModel.taskInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isRouting)
            }

            // Tappable complexity chips
            HStack(spacing: 8) {
                Text("Complexity:")
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(DesignTokens.textSecondary)
                ForEach(TaskComplexity.allCases, id: \.self) { complexity in
                    let isActive = viewModel.taskInput.isEmpty
                        ? false
                        : viewModel.estimateComplexity(task: viewModel.taskInput) == complexity
                    complexityChip(for: complexity, isActive: isActive)
                }
            }
        }
        .padding(DesignTokens.Spacing.cardPadding)
        .background(DesignTokens.surface(for: colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Spacing.cardRadius))
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Spacing.cardRadius)
                .stroke(DesignTokens.border(for: colorScheme), lineWidth: 1)
        )
        .cardShadow()
    }

    // MARK: - Agent Grid

    private var agentGrid: some View {
        LazyVGrid(columns: columns, spacing: DesignTokens.Spacing.itemSpacing) {
            ForEach(viewModel.profiles) { profile in
                AgentCardView(
                    profile: profile,
                    isSelected: selectedProfileId == profile.id
                )
                .contentShape(RoundedRectangle(cornerRadius: DesignTokens.Spacing.cardRadius))
                .onTapGesture {
                    withAnimation(.spring(duration: 0.2)) {
                        selectedProfileId = selectedProfileId == profile.id ? nil : profile.id
                    }
                }
                // Highlight matched agent when routing result is available
                .opacity(highlightOpacity(for: profile))
                .animation(.easeInOut(duration: 0.3), value: viewModel.routingResult?.selectedAgent.id)
            }
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        LazyVGrid(columns: columns, spacing: DesignTokens.Spacing.itemSpacing) {
            ForEach(0..<6, id: \.self) { _ in
                RoundedRectangle(cornerRadius: DesignTokens.Spacing.cardRadius)
                    .fill(DesignTokens.surface(for: colorScheme))
                    .frame(height: 220)
                    .redacted(reason: .placeholder)
            }
        }
    }

    // MARK: - Empty View

    private var emptyView: some View {
        VStack(spacing: DesignTokens.Spacing.itemSpacing) {
            Image(systemName: "person.3")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(DesignTokens.textSecondary)
            Text("No agent profiles found")
                .font(DesignTokens.Typography.heading)
                .foregroundStyle(DesignTokens.textPrimary(for: colorScheme))
            Text("Agent profiles will appear when the bridge is connected.")
                .font(DesignTokens.Typography.body)
                .foregroundStyle(DesignTokens.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    // MARK: - Helpers

    @ViewBuilder
    private func complexityChip(for complexity: TaskComplexity, isActive: Bool = true) -> some View {
        let color: Color = {
            switch complexity {
            case .simple: return DesignTokens.success
            case .medium: return DesignTokens.warning
            case .complex: return DesignTokens.failure
            }
        }()

        Text(complexity.rawValue.capitalized)
            .font(DesignTokens.Typography.caption)
            .foregroundStyle(isActive ? color : DesignTokens.textSecondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(isActive ? color.opacity(0.12) : DesignTokens.border(for: colorScheme).opacity(0.3))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(isActive ? color.opacity(0.4) : DesignTokens.border(for: colorScheme), lineWidth: 1))
    }

    private func highlightOpacity(for profile: AgentProfile) -> Double {
        guard let result = viewModel.routingResult else { return 1.0 }
        return result.selectedAgent.id == profile.id ? 1.0 : 0.5
    }
}

#Preview {
    AgentProfilesView()
        .environment(AppState())
}
