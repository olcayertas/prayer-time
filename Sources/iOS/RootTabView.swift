import SwiftUI

/// iOS root: one tab per `AppSection`, each wrapped in its own `NavigationStack` so the
/// shared views' navigation titles render and the Settings location picker can push.
struct RootTabView: View {
    @ObservedObject var store: PrayerStore
    @State private var selection: AppSection = .today

    var body: some View {
        TabView(selection: $selection) {
            NavigationStack { TodayView(store: store) }
                .tag(AppSection.today)
                .tabItem { Label(AppSection.today.title, systemImage: AppSection.today.systemImage) }
            NavigationStack { MonthView(store: store) }
                .tag(AppSection.month)
                .tabItem { Label(AppSection.month.title, systemImage: AppSection.month.systemImage) }
            NavigationStack { SettingsView(store: store) }
                .tag(AppSection.settings)
                .tabItem { Label(AppSection.settings.title, systemImage: AppSection.settings.systemImage) }
        }
    }
}
