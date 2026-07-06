import SwiftUI

@main
struct NamazVaktiApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var store = PrayerStore.shared
    @StateObject private var themeManager = ThemeManager.shared

    var body: some Scene {
        // Plain String title (not a rendered SwiftUI label) — AppKit sets the status
        // item's text directly, avoiding the view-to-image sizing hang. The title is
        // driven by `store.menuTitle`, updated once a second by the store's timer.
        // (The title String is NOT themed; only the popover + window content are.)
        MenuBarExtra(store.menuTitle) {
            MenuPanelView(store: store)
                .themed(themeManager)
        }
        .menuBarExtraStyle(.window)

        Window("Prayer Times", id: "main") {
            MainWindowView(store: store)
                .themed(themeManager)
        }
        .defaultSize(width: 760, height: 560)
    }
}
