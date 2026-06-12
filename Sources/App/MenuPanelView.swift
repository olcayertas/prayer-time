import SwiftUI
import AppKit

/// The window shown when the menu bar item is clicked.
struct MenuPanelView: View {
    @ObservedObject var store: PrayerStore
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                let now = context.date
                let today = store.schedule.day(on: now) ?? store.days.first
                let upcoming = store.schedule.upcoming(now: now)

                VStack(alignment: .leading, spacing: 0) {
                    header(today: today)
                    Divider()
                    if let today {
                        hero(upcoming: upcoming)
                        Divider()
                        timesList(today: today, upcoming: upcoming?.prayer)
                    } else {
                        emptyState
                    }
                }
            }
            Divider()
            notificationsToggle
            Divider()
            footer
        }
        .frame(width: 288)
    }

    // MARK: - Sections

    private var notificationsToggle: some View {
        Toggle(isOn: Binding(
            get: { store.notificationsEnabled },
            set: { store.setNotifications(enabled: $0) }
        )) {
            Label("Vakit bildirimleri", systemImage: "bell")
        }
        .toggleStyle(.switch)
        .controlSize(.small)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }

    private func header(today: PrayerDay?) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(store.locationName)
                .font(.headline)
            if let today {
                if let gregorian = today.miladiTarihUzun {
                    Text(gregorian).font(.caption).foregroundStyle(.secondary)
                }
                if let hicri = today.hicriTarihUzun {
                    Text(hicri).font(.caption).foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
    }

    private func hero(upcoming: UpcomingPrayer?) -> some View {
        HStack(spacing: 12) {
            if let upcoming {
                Image(systemName: upcoming.prayer.symbolName)
                    .font(.system(size: 26))
                    .foregroundStyle(.tint)
                    .frame(width: 34)
                VStack(alignment: .leading, spacing: 1) {
                    Text("Sıradaki vakit")
                        .font(.caption).foregroundStyle(.secondary)
                    Text(upcoming.prayer.displayName)
                        .font(.title3).fontWeight(.semibold)
                }
                Spacer()
                Text(CountdownFormatter.string(upcoming.remaining))
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.tint)
            } else {
                Text("Bugünün vakitleri yüklenemedi")
                    .font(.callout).foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    private func timesList(today: PrayerDay, upcoming: Prayer?) -> some View {
        VStack(spacing: 0) {
            ForEach(Prayer.allCases) { prayer in
                let isNext = prayer == upcoming
                HStack {
                    Image(systemName: prayer.symbolName)
                        .frame(width: 22)
                        .foregroundStyle(isNext ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))
                    Text(prayer.displayName)
                        .fontWeight(isNext ? .semibold : .regular)
                    Spacer()
                    Text(today.time(for: prayer))
                        .monospacedDigit()
                        .fontWeight(isNext ? .semibold : .regular)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background {
                    if isNext {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(.tint.opacity(0.14))
                            .padding(.horizontal, 6)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var emptyState: some View {
        HStack(spacing: 8) {
            if store.isLoading {
                ProgressView().controlSize(.small)
                Text("Yükleniyor…").foregroundStyle(.secondary)
            } else {
                Image(systemName: "wifi.exclamationmark").foregroundStyle(.secondary)
                Text(store.lastError ?? "Veri yok").foregroundStyle(.secondary)
            }
        }
        .font(.callout)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
    }

    private var footer: some View {
        VStack(spacing: 8) {
            Button {
                dismiss() // close the menu bar popup
                openWindow(id: "main")
                NSApp.activate(ignoringOtherApps: true)
            } label: {
                Label("Uygulamayı aç", systemImage: "macwindow")
                    .frame(maxWidth: .infinity)
            }
            .controlSize(.large)

            HStack {
                Button {
                    store.refresh()
                } label: {
                    if store.isLoading {
                        ProgressView().controlSize(.small)
                    } else {
                        Label("Yenile", systemImage: "arrow.clockwise")
                    }
                }
                .buttonStyle(.borderless)
                .disabled(store.isLoading)

                Spacer()

                Button("Çıkış") { NSApplication.shared.terminate(nil) }
                    .buttonStyle(.borderless)
                    .keyboardShortcut("q")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}
