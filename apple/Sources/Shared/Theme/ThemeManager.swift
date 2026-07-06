import SwiftUI

/// Owns the selected theme and persists it. Separate from `PrayerStore` (theme is a UI concern);
/// mirrors its `locationMode` UserDefaults pattern. `@StateObject`-injected at both app roots so the
/// whole app re-themes live when `themeID` changes.
@MainActor
final class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    static let themeIDKey = "selectedThemeID"

    @Published private(set) var themeID: ThemeID

    init() {
        themeID = UserDefaults.standard.string(forKey: Self.themeIDKey)
            .flatMap(ThemeID.init(rawValue:)) ?? .default
    }

    var theme: Theme { themeID.theme }

    func setTheme(_ id: ThemeID) {
        guard id != themeID else { return }
        themeID = id
        UserDefaults.standard.set(id.rawValue, forKey: Self.themeIDKey)
    }
}
