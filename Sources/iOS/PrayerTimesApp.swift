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
    }
}
