import SwiftUI

/// The selectable themes. Persisted (raw value) by `ThemeManager`.
enum ThemeID: String, CaseIterable, Identifiable, Sendable {
    case `default`
    case arc

    var id: String { rawValue }

    /// Localized name shown in the Appearance picker.
    var displayName: LocalizedStringKey {
        switch self {
        case .default: return "Default"
        case .arc:     return "Arc"
        }
    }

    var theme: Theme { self == .arc ? .arc : .default }
}
