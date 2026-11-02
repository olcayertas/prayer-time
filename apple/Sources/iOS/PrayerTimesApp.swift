import SwiftUI

/// iOS entry point. A single `WindowGroup` hosting the tab UI; the shared `PrayerStore`
/// loads cache, refreshes from the network, and (when enabled) schedules notifications —
/// exactly as on macOS. No `MenuBarExtra` / `AppDelegate` here: iOS has no menu bar.
@main
struct PrayerTimesApp: App {
    @StateObject private var store = PrayerStore.shared
    @StateObject private var themeManager = ThemeManager.shared

    var body: some Scene {
        WindowGroup {
            RootTabView(store: store)
                .themed(themeManager)
        }
        // The Live Activity cannot move on to the next prayer by itself; this refresh, asked for
        // at the prayer time, points it at the next one. The month comes from the cache.
        .backgroundTask(.appRefresh(LiveActivityController.refreshTaskIdentifier)) {
            let update = await MainActor.run {
                let store = PrayerStore.shared
                return LiveActivityController.shared.sync(schedule: store.schedule, locationName: store.locationName)
            }
            await update?.value // finish before iOS suspends the app again
        }
    }
}
