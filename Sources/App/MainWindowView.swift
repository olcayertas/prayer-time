import SwiftUI
import AppKit

/// The main desktop window: a sidebar + detail layout. Shows a Dock icon only while open
/// (the app is otherwise a menu bar agent).
struct MainWindowView: View {
    @ObservedObject var store: PrayerStore
    @State private var section: AppSection? = .today

    var body: some View {
        NavigationSplitView {
            List(AppSection.displayed, selection: $section) { item in
                Label(item.title, systemImage: item.systemImage)
                    .tag(item)
            }
            .navigationSplitViewColumnWidth(min: 170, ideal: 190, max: 230)
        } detail: {
            switch section ?? .today {
            case .today: TodayView(store: store)
            case .month: MonthView(store: store)
            case .settings: SettingsView(store: store)
            case .qibla: EmptyView() // iOS-only; filtered from `displayed`, so never selected here
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
