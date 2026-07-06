import Foundation

/// The App Group shared between the app and its widget. Both targets carry the
/// `group.com.olcayertas.NamazVakti` entitlement, so the selected district and the cached month
/// live in one place the widget can read — letting the widget follow the app's Automatic/Pinned
/// location instead of a fixed default.
///
/// Everything degrades gracefully when the group container isn't available (unit tests, or a build
/// without the entitlement): `defaults` falls back to `.standard` and `containerURL` is nil, so
/// `Core` stays usable everywhere.
enum AppGroup {
    static let identifier = "group.com.olcayertas.NamazVakti"

    /// Keys shared between the app (writer) and the widget (reader) in `defaults`.
    static let selectedDistrictIdKey = "selectedDistrictId"
    static let selectedDistrictNameKey = "selectedDistrictName"

    /// Shared user defaults, or `.standard` if the group suite can't be opened.
    static var defaults: UserDefaults {
        UserDefaults(suiteName: identifier) ?? .standard
    }

    /// The shared container directory, or nil when the entitlement isn't present.
    static var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier)
    }
}
