import SwiftUI

private struct ThemeKey: EnvironmentKey {
    static let defaultValue: Theme = .default
}

extension EnvironmentValues {
    /// The active theme. Read with `@Environment(\.theme) private var theme`; set at the app roots
    /// from `ThemeManager.theme`.
    var theme: Theme {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}
