import SwiftUI
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

/// App settings, shown in the main window's "Ayarlar" section.
struct SettingsView: View {
    @ObservedObject var store: PrayerStore
    @EnvironmentObject private var themeManager: ThemeManager

    var body: some View {
        Form {
            Section("Appearance") {
                Picker("Theme", selection: Binding(
                    get: { themeManager.themeID },
                    set: { themeManager.setTheme($0) }
                )) {
                    ForEach(ThemeID.allCases) { Text($0.displayName).tag($0) }
                }
                .pickerStyle(.segmented)
                Text(themeManager.themeID == .arc
                     ? "A dark palette with gold accents."
                     : "Follows your system light and dark appearance.")
                    .font(.caption).foregroundStyle(.secondary)
            }

            Section("Location") {
                Picker("Mode", selection: Binding(
                    get: { store.locationMode },
                    set: { store.setLocationMode($0) }
                )) {
                    Text("Automatic").tag(LocationMode.automatic)
                    Text("Pinned").tag(LocationMode.pinned)
                }
                .pickerStyle(.segmented)

                if store.locationMode == .automatic {
                    AutomaticLocationStatusView(store: store)
                } else {
                    LocationPickerView(store: store)
                }
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
        #if os(iOS)
        .toolbar(.hidden, for: .navigationBar)
        #endif
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
        return "\(version) (\(build))"
    }
}

/// Shows the automatically-tracked location + the pipeline status (locating / resolving / using a
/// city / denied or unavailable fallbacks).
private struct AutomaticLocationStatusView: View {
    @ObservedObject var store: PrayerStore

    var body: some View {
        LabeledContent("Current", value: store.locationName)
        statusLine
    }

    @ViewBuilder private var statusLine: some View {
        switch store.trackingStatus {
        case .idle, .locating:
            locatingRow("Locating…")
        case .resolving:
            locatingRow("Finding your city…")
        case .resolved(let name):
            Label("Using \(name)", systemImage: "location.fill")
                .font(.caption).foregroundStyle(.secondary)
        case .permissionDenied:
            VStack(alignment: .leading, spacing: 6) {
                Text("Location access is off — showing \(store.locationName).")
                    .font(.caption).foregroundStyle(.secondary)
                OpenLocationSettingsButton()
            }
        case .unavailable:
            Text("Couldn't determine your location — showing \(store.locationName).")
                .font(.caption).foregroundStyle(.secondary)
        }
    }

    private func locatingRow(_ text: LocalizedStringKey) -> some View {
        HStack(spacing: 6) {
            ProgressView().controlSize(.small)
            Text(text).font(.caption).foregroundStyle(.secondary)
        }
    }
}

/// Deep-links to the system location-permission settings (per platform).
private struct OpenLocationSettingsButton: View {
    var body: some View {
        Button("Open Settings") {
            #if os(iOS)
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
            #elseif os(macOS)
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_LocationServices") {
                NSWorkspace.shared.open(url)
            }
            #endif
        }
    }
}
