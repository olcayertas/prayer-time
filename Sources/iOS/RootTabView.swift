import SwiftUI

/// iOS root: one tab per `AppSection`, each wrapped in its own `NavigationStack` so the
/// shared views' navigation titles render and the Settings location picker can push.
struct RootTabView: View {
    @ObservedObject var store: PrayerStore
    @State private var selection: AppSection = .today
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.theme) private var theme

    var body: some View {
        TabView(selection: $selection) {
            NavigationStack { TodayView(store: store) }
                .tag(AppSection.today)
                .tabItem { Label(AppSection.today.title, systemImage: AppSection.today.systemImage) }
            NavigationStack { MonthView(store: store) }
                .tag(AppSection.month)
                .tabItem { Label(AppSection.month.title, systemImage: AppSection.month.systemImage) }
            NavigationStack { QiblaView(store: store) }
                .tag(AppSection.qibla)
                .tabItem { Label(AppSection.qibla.title, systemImage: AppSection.qibla.systemImage) }
            NavigationStack { SettingsView(store: store) }
                .tag(AppSection.settings)
                .tabItem { Label(AppSection.settings.title, systemImage: AppSection.settings.systemImage) }
        }
        .tint(theme.accent)
        .task(id: store.days.count) {
            LiveActivityController.shared.sync(schedule: store.schedule, locationName: store.locationName)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                store.onForeground()   // re-check current location / freshen the cache
                LiveActivityController.shared.sync(schedule: store.schedule, locationName: store.locationName)
            }
        }
    }
}
