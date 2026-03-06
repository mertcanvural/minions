import SwiftUI

struct QuickLaunchCard: View {
    @Binding var taskInput: String
    let estimatedComplexity: TaskComplexity?
    let isLaunching: Bool
    let onLaunch: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.itemSpacing) {
            Text("Quick Launch")
                .font(DesignTokens.Typography.subheading)
                .foregroundColor(DesignTokens.textPrimary(for: colorScheme))

            // Task input field
            ZStack(alignment: .topLeading) {
                if taskInput.isEmpty {
                    Text("Describe your task...")
                        .font(DesignTokens.Typography.body)
                        .foregroundColor(DesignTokens.textSecondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 10)
                        .allowsHitTesting(false)
                }
                TextEditor(text: $taskInput)
                    .font(DesignTokens.Typography.body)
                    .foregroundColor(DesignTokens.textPrimary(for: colorScheme))
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 6)
                    .frame(minHeight: 72, maxHeight: 120)
            }
            .background(DesignTokens.background(for: colorScheme))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(DesignTokens.border(for: colorScheme), lineWidth: 1)
            )

            // Complexity chips
            VStack(alignment: .leading, spacing: 6) {
                Text("Complexity")
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(DesignTokens.textSecondary)

                HStack(spacing: 8) {
                    ForEach(TaskComplexity.allCases, id: \.self) { complexity in
                        ComplexityChip(
                            complexity: complexity,
                            isSelected: estimatedComplexity == complexity
                        )
                    }
                }
            }

            // Launch button
            Button(action: onLaunch) {
                HStack(spacing: 8) {
                    if isLaunching {
                        ProgressView()
                            .scaleEffect(0.75)
                            .progressViewStyle(.circular)
                            .tint(.white)
                    } else {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    Text(isLaunching ? "Launching..." : "Launch Task")
                        .font(DesignTokens.Typography.body.weight(.semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    taskInput.trimmingCharacters(in: .whitespaces).isEmpty || isLaunching
                        ? DesignTokens.accent.opacity(0.5)
                        : DesignTokens.accent
                )
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .buttonStyle(.plain)
            .disabled(taskInput.trimmingCharacters(in: .whitespaces).isEmpty || isLaunching)
        }
    }
}

// MARK: - Complexity Chip

struct ComplexityChip: View {
    let complexity: TaskComplexity
    let isSelected: Bool

    private var label: String {
        switch complexity {
        case .simple: return "Simple"
        case .medium: return "Medium"
        case .complex: return "Complex"
        }
    }

    private var chipColor: Color {
        switch complexity {
        case .simple: return DesignTokens.success
        case .medium: return DesignTokens.warning
        case .complex: return DesignTokens.failure
        }
    }

    var body: some View {
        Text(label)
            .font(DesignTokens.Typography.caption)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(isSelected ? chipColor.opacity(0.2) : Color.clear)
            .foregroundColor(isSelected ? chipColor : DesignTokens.textSecondary)
            .overlay(
                Capsule()
                    .stroke(
                        isSelected ? chipColor : DesignTokens.textSecondary.opacity(0.4),
                        lineWidth: 1
                    )
            )
            .clipShape(Capsule())
    }
}

#Preview {
    @Previewable @State var input = ""
    QuickLaunchCard(
        taskInput: $input,
        estimatedComplexity: .medium,
        isLaunching: false,
        onLaunch: {}
    )
    .frame(width: 280)
    .padding()
    .background(DesignTokens.backgroundLight)
}
