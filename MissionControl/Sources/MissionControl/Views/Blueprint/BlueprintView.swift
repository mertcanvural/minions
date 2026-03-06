import SwiftUI

// MARK: - Blueprint View (Screen Wrapper)

struct BlueprintView: View {
    @State private var viewModel = BlueprintViewModel()
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            if viewModel.isLoading {
                loadingView
            } else if let error = viewModel.error {
                errorView(error)
            } else if viewModel.currentRun != nil {
                BlueprintCanvasView(viewModel: viewModel)
            } else {
                emptyView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignTokens.background(for: colorScheme))
        .task {
            await viewModel.loadRun()
        }
    }

    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
                .controlSize(.large)
            Text("Loading blueprint...")
                .font(DesignTokens.Typography.body)
                .foregroundColor(DesignTokens.textSecondary)
        }
    }

    private func errorView(_ error: Error) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 36))
                .foregroundColor(DesignTokens.failure)
            Text("Failed to load blueprint")
                .font(DesignTokens.Typography.subheading)
                .foregroundColor(DesignTokens.textPrimary(for: colorScheme))
            Text(error.localizedDescription)
                .font(DesignTokens.Typography.caption)
                .foregroundColor(DesignTokens.textSecondary)
            Button("Retry") {
                Task { await viewModel.loadRun() }
            }
            .buttonStyle(.borderedProminent)
            .tint(DesignTokens.accent)
        }
    }

    private var emptyView: some View {
        VStack(spacing: 12) {
            Image(systemName: "point.3.connected.trianglepath.dotted")
                .font(.system(size: 48, weight: .light))
                .foregroundColor(DesignTokens.textSecondary)
            Text("No blueprint loaded")
                .font(DesignTokens.Typography.heading)
                .foregroundColor(DesignTokens.textPrimary(for: colorScheme))
        }
    }
}

#Preview {
    BlueprintView()
}
