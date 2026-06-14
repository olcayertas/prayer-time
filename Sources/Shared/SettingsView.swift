import SwiftUI

/// App settings, shown in the main window's "Ayarlar" section.
struct SettingsView: View {
    @ObservedObject var store: PrayerStore

    var body: some View {
        Form {
            Section("Location") {
                LocationPickerView(store: store)
            }

            Section("Notifications") {
                Toggle("Prayer notifications", isOn: Binding(
                    get: { store.notificationsEnabled },
                    set: { store.setNotifications(enabled: $0) }
                ))
                Text("When on, you'll get a notification at each prayer time.")
                    .font(.caption).foregroundStyle(.secondary)
            }

            #if os(iOS)
            Section("Live Activity") {
                LiveActivityToggle(store: store)
            }
            #endif

            Section("General") {
                Button("Refresh now") { store.refresh() }
                    .disabled(store.isLoading)
                if let updated = store.lastUpdated {
                    LabeledContent("Last updated", value: updated.formatted(date: .abbreviated, time: .shortened))
                }
                if let error = store.lastError {
                    Text(error).font(.caption).foregroundStyle(.red)
                }
            }

            Section("About") {
                LabeledContent("Version", value: appVersion)
                Text("Prayer times are sourced from the EzanVakti service, based on the Turkish Directorate of Religious Affairs (Diyanet).")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Settings")
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
        return "\(version) (\(build))"
    }
}
