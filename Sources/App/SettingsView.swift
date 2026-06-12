import SwiftUI

/// App settings, shown in the main window's "Ayarlar" section.
struct SettingsView: View {
    @ObservedObject var store: PrayerStore

    var body: some View {
        Form {
            Section("Konum") {
                LocationPickerView(store: store)
            }

            Section("Bildirimler") {
                Toggle("Vakit bildirimleri", isOn: Binding(
                    get: { store.notificationsEnabled },
                    set: { store.setNotifications(enabled: $0) }
                ))
                Text("Açıkken her namaz vaktinde bir bildirim gönderilir.")
                    .font(.caption).foregroundStyle(.secondary)
            }

            Section("Genel") {
                Button("Şimdi yenile") { store.refresh() }
                    .disabled(store.isLoading)
                if let updated = store.lastUpdated {
                    LabeledContent("Son güncelleme", value: updated.formatted(date: .abbreviated, time: .shortened))
                }
                if let error = store.lastError {
                    Text(error).font(.caption).foregroundStyle(.red)
                }
            }

            Section("Hakkında") {
                LabeledContent("Sürüm", value: appVersion)
                Text("Vakitler T.C. Diyanet İşleri Başkanlığı kaynaklı EzanVakti servisinden alınır.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Ayarlar")
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
        return "\(version) (\(build))"
    }
}
