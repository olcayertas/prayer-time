import SwiftUI

/// The app's top-level sections. Drives the macOS window sidebar and the iOS tab bar, so it
/// lives in Shared — add a case here to grow both apps at once.
enum AppSection: String, CaseIterable, Identifiable {
    case today
    case month
    case qibla
    case settings

    var id: String { rawValue }

    /// The sections to show on this platform. The Qibla finder is a live compass and needs a
    /// magnetometer, which Macs don't have — so it's iOS-only and filtered out of the macOS UI.
    /// (The `qibla` case stays in the enum so the shared switches remain exhaustive.)
    static var displayed: [AppSection] {
        #if os(macOS)
        allCases.filter { $0 != .qibla }
        #else
        allCases
        #endif
    }

    /// Localized label and navigation title.
    var title: LocalizedStringKey {
        switch self {
        case .today: return "Today"
        case .month: return "Monthly"
        case .qibla: return "Qibla"
        case .settings: return "Settings"
        }
    }

    var systemImage: String {
        switch self {
        case .today: return "sun.max.fill"
        case .month: return "calendar"
        case .qibla: return "location.north.circle.fill"
        case .settings: return "gearshape.fill"
        }
    }
}
