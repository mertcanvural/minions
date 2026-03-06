import SwiftUI

/// Design system tokens for Mission Control
struct DesignTokens {
    // MARK: - Colors (Static)

    static let accent = Color(red: 0.39, green: 0.41, blue: 0.95)           // #6366F1 Indigo
    static let accentLight = Color(red: 0.51, green: 0.55, blue: 0.97)      // #818CF8

    static let backgroundDark = Color(red: 0.06, green: 0.06, blue: 0.08)   // #0F0F14
    static let backgroundLight = Color(red: 0.98, green: 0.98, blue: 0.98)  // #FAFAFA

    static let surfaceDark = Color(red: 0.10, green: 0.10, blue: 0.14)      // #1A1A24
    static let surfaceLight = Color(red: 1.0, green: 1.0, blue: 1.0)        // #FFFFFF

    static let textPrimary = Color(red: 0.95, green: 0.95, blue: 0.95)      // #F1F1F3 (dark)
    static let textPrimaryLight = Color(red: 0.07, green: 0.07, blue: 0.07) // #111111 (light)
    static let textSecondary = Color(red: 0.55, green: 0.55, blue: 0.62)    // #8B8B9E

    static let success = Color(red: 0.13, green: 0.77, blue: 0.30)          // #22C55E
    static let failure = Color(red: 0.94, green: 0.27, blue: 0.27)          // #EF4444
    static let running = Color(red: 0.23, green: 0.51, blue: 0.96)          // #3B82F6
    static let pending = Color(red: 0.42, green: 0.45, blue: 0.50)          // #6B7280
    static let warning = Color(red: 0.96, green: 0.62, blue: 0.04)          // #F59E0B

    static let borderDark = Color(red: 0.16, green: 0.16, blue: 0.24)       // #2A2A3C
    static let borderLight = Color(red: 0.90, green: 0.91, blue: 0.93)      // #E5E7EB

    // MARK: - Semantic Colors (Environment-aware)

    static func background(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? backgroundDark : backgroundLight
    }

    static func surface(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? surfaceDark : surfaceLight
    }

    static func textPrimary(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? textPrimary : textPrimaryLight
    }

    static func border(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? borderDark : borderLight
    }

    // MARK: - Typography

    struct Typography {
        // Title: 28pt, Bold
        static let title = Font.system(size: 28, weight: .bold, design: .default)

        // Heading: 20pt, Semibold
        static let heading = Font.system(size: 20, weight: .semibold, design: .default)

        // Subheading: 16pt, Medium
        static let subheading = Font.system(size: 16, weight: .medium, design: .default)

        // Body: 14pt, Regular
        static let body = Font.system(size: 14, weight: .regular, design: .default)

        // Caption: 12pt, Regular
        static let caption = Font.system(size: 12, weight: .regular, design: .default)

        // Code: 13pt, Regular (Monospace)
        static let code = Font.system(size: 13, weight: .regular, design: .monospaced)

        // Code Small: 11pt, Regular (Monospace)
        static let codeSmall = Font.system(size: 11, weight: .regular, design: .monospaced)

        // Metric: 36pt, Bold (Rounded)
        static let metric = Font.system(size: 36, weight: .bold, design: .rounded)
    }

    // MARK: - Spacing

    struct Spacing {
        static let cardRadius: CGFloat = 16
        static let cardPadding: CGFloat = 16
        static let sectionSpacing: CGFloat = 24
        static let itemSpacing: CGFloat = 12
        static let sidebarWidth: CGFloat = 220
        static let minWindowWidth: CGFloat = 1100
        static let minWindowHeight: CGFloat = 700
    }

    // MARK: - Shadows & Effects

    struct Effects {
        // Card shadow: color .black.opacity(0.15), radius 8, y offset 2
        static let cardShadowOpacity: Double = 0.15
        static let cardShadowRadius: CGFloat = 8
        static let cardShadowOffsetY: CGFloat = 2

        // Glow (active node): color .accent.opacity(0.6), radius 20
        static let glowRadius: CGFloat = 20
        static let glowOpacity: Double = 0.6

        // Hover: brightness +0.05
        static let hoverBrightnessIncrease: Double = 0.05
    }
}

// MARK: - Shadow Extension

extension View {
    func cardShadow() -> some View {
        self.shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 2)
    }

    func accentGlow() -> some View {
        self.shadow(color: DesignTokens.accent.opacity(0.6), radius: 20)
    }
}
