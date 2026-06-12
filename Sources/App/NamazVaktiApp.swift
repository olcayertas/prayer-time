import SwiftUI

@main
struct NamazVaktiApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var store = PrayerStore.shared

    var body: some Scene {
        // Plain String title (not a rendered SwiftUI label) — AppKit sets the status
        // item's text directly, avoiding the view-to-image sizing hang. The title is
        // driven by `store.menuTitle`, updated once a second by the store's timer.
        MenuBarExtra(store.menuTitle) {
            MenuPanelView(store: store)
        }
        .menuBarExtraStyle(.window)

        Window("Prayer Times", id: "main") {
            MainWindowView(store: store)
        }
        .defaultSize(width: 760, height: 560)
    }
}
