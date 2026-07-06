import SwiftUI

/// The "Live Activity" controls shown in the iOS Settings tab. Kept iOS-only (ActivityKit),
/// so the shared `SettingsView` references it behind `#if os(iOS)`.
struct LiveActivityToggle: View {
    @ObservedObject var store: PrayerStore
    @ObservedObject private var controller = LiveActivityController.shared

    var body: some View {
        Toggle("Live Activity", isOn: Binding(
            get: { controller.isEnabled },
            set: { controller.setEnabled($0, schedule: store.schedule, locationName: store.locationName) }
        ))
        .disabled(!controller.isSupported)
        Text(controller.isSupported
             ? "Shows the next prayer and a live countdown in the Dynamic Island and on the Lock Screen."
             : "Turn on Live Activities for Prayer Times in iOS Settings to use this.")
            .font(.caption).foregroundStyle(.secondary)
    }
}
