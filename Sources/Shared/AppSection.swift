import SwiftUI

/// The app's top-level sections. Drives the macOS window sidebar and the iOS tab bar, so it
/// lives in Shared — add a case here to grow both apps at once.
enum AppSection: String, CaseIterable, Identifiable {
    case today
    case month
    case settings

    var id: String { rawValue }

    /// Localized label and navigation title.
    var title: LocalizedStringKey {
        switch self {
        case .today: return "Today"
        case .month: return "Monthly"
        case .settings: return "Settings"
        }
    }

    var systemImage: String {
        switch self {
        case .today: return "sun.max.fill"
        case .month: return "calendar"
        case .settings: return "gearshape.fill"
        }
    }
}
