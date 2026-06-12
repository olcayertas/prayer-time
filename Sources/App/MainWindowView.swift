import SwiftUI
import AppKit

/// Sections in the main window sidebar. Add cases here to grow the app.
enum AppSection: String, CaseIterable, Identifiable {
    case today = "Bugün"
    case month = "Aylık"
    case settings = "Ayarlar"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .today: return "sun.max.fill"
        case .month: return "calendar"
        case .settings: return "gearshape.fill"
        }
    }
}

/// The main desktop window: a sidebar + detail layout. Shows a Dock icon only while open
/// (the app is otherwise a menu bar agent).
struct MainWindowView: View {
    @ObservedObject var store: PrayerStore
    @State private var section: AppSection? = .today

    var body: some View {
        NavigationSplitView {
            List(AppSection.allCases, selection: $section) { item in
                Label(item.rawValue, systemImage: item.systemImage)
                    .tag(item)
            }
            .navigationSplitViewColumnWidth(min: 170, ideal: 190, max: 230)
        } detail: {
            switch section ?? .today {
            case .today: TodayView(store: store)
            case .month: MonthView(store: store)
            case .settings: SettingsView(store: store)
            }
        }
        .frame(minWidth: 660, minHeight: 480)
        .onAppear {
            NSApp.setActivationPolicy(.regular)
            NSApp.activate(ignoringOtherApps: true)
        }
        .onDisappear {
            NSApp.setActivationPolicy(.accessory)
        }
    }
}
