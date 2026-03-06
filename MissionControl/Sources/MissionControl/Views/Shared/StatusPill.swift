import SwiftUI

struct StatusPill: View {
    let text: String
    let backgroundColor: Color
    let textColor: Color

    init(_ text: String, backgroundColor: Color, textColor: Color = .white) {
        self.text = text
        self.backgroundColor = backgroundColor
        self.textColor = textColor
    }

    var body: some View {
        Text(text)
            .font(DesignTokens.Typography.caption)
            .foregroundColor(textColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(backgroundColor.opacity(0.15))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(backgroundColor, lineWidth: 1)
            )
    }
}

// MARK: - Convenience Initializers

extension StatusPill {
    init(status: String) {
        let (backgroundColor, textColor) = Self.colorForStatus(status)
        self.init(status, backgroundColor: backgroundColor, textColor: textColor)
    }

    private static func colorForStatus(_ status: String) -> (Color, Color) {
        let lowercased = status.lowercased()
        switch lowercased {
        case "running":
            return (DesignTokens.running, DesignTokens.running)
        case "completed", "success":
            return (DesignTokens.success, DesignTokens.success)
        case "failed", "failure":
            return (DesignTokens.failure, DesignTokens.failure)
        case "pending":
            return (DesignTokens.pending, DesignTokens.pending)
        case "warning", "warm":
            return (DesignTokens.warning, DesignTokens.warning)
        default:
            return (DesignTokens.textSecondary, DesignTokens.textSecondary)
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        StatusPill("running", backgroundColor: DesignTokens.running)
        StatusPill("completed", backgroundColor: DesignTokens.success)
        StatusPill("failed", backgroundColor: DesignTokens.failure)
        StatusPill("pending", backgroundColor: DesignTokens.pending)
        StatusPill("warning", backgroundColor: DesignTokens.warning)
    }
    .padding()
}
