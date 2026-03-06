import SwiftUI

struct ThemeKey: EnvironmentKey {
    static let defaultValue: ColorScheme? = nil
}

extension EnvironmentValues {
    var theme: ColorScheme? {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}

extension View {
    func applyTheme(_ preference: AppState.ThemePreference) -> some View {
        self.preferredColorScheme(colorSchemeForPreference(preference))
    }
}

private func colorSchemeForPreference(_ preference: AppState.ThemePreference) -> ColorScheme? {
    switch preference {
    case .dark:
        return .dark
    case .light:
        return .light
    case .system:
        return nil
    }
}
