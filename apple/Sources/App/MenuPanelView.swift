import SwiftUI
import AppKit

/// The window shown when the menu bar item is clicked.
struct MenuPanelView: View {
    @ObservedObject var store: PrayerStore
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme

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
        .tint(theme.accent)
        .themedRootBackground(theme)
    }

    // MARK: - Sections

    private var notificationsToggle: some View {
        Toggle(isOn: Binding(
            get: { store.notificationsEnabled },
            set: { store.setNotifications(enabled: $0) }
        )) {
            Label("Prayer notifications", systemImage: "bell")
        }
        .toggleStyle(.switch)
        .controlSize(.small)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }

    private func header(today: PrayerDay?) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(store.locationName)
                .font(theme.font(.display, .headline, weight: .semibold))
                .foregroundStyle(theme.text)
            if let today {
                if let gregorian = DateLocalizer.gregorianLong(today.miladiTarihKisa) {
                    Text(gregorian).font(theme.font(.body, .caption)).foregroundStyle(theme.muted)
                }
                if let hicri = DateLocalizer.hijriLong(today.hicriTarihKisa) {
                    Text(hicri).font(theme.font(.body, .caption)).foregroundStyle(theme.muted)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
    }

    @ScaledMetric(relativeTo: .title) private var heroIconSize: CGFloat = 26
    @ScaledMetric(relativeTo: .title2) private var heroCountdownSize: CGFloat = 24

    private func hero(upcoming: UpcomingPrayer?) -> some View {
        HStack(spacing: 12) {
            if let upcoming {
                Image(systemName: upcoming.prayer.symbolName)
                    .font(.system(size: heroIconSize))
                    .foregroundStyle(theme.accent)
                    .frame(width: 34)
                VStack(alignment: .leading, spacing: 1) {
                    Text("Next prayer")
                        .font(theme.font(.body, .caption)).foregroundStyle(theme.muted)
                    Text(upcoming.prayer.displayName)
                        .font(theme.font(.display, .title3, weight: .semibold))
                        .foregroundStyle(theme.text)
                }
                Spacer()
                Text(CountdownFormatter.string(upcoming.remaining))
                    .font(theme.font(.rounded, size: heroCountdownSize, weight: .semibold, relativeTo: .title2))
                    .monospacedDigit()
                    .foregroundStyle(theme.accent)
            } else {
                Text("Couldn't load today's times")
                    .font(theme.font(.body, .callout)).foregroundStyle(theme.muted)
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
                        .foregroundStyle(isNext ? theme.accent : theme.muted)
                    Text(prayer.displayName)
                        .font(theme.font(.body, .body, weight: isNext ? .semibold : .regular))
                        .foregroundStyle(theme.text)
                    Spacer()
                    Text(today.time(for: prayer))
                        .font(theme.font(.mono, .body, weight: isNext ? .semibold : .regular))
                        .monospacedDigit()
                        .foregroundStyle(theme.text)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background {
                    if isNext {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(theme.accentSoft)
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
                Text("Loading…").foregroundStyle(theme.muted)
            } else {
                Image(systemName: "wifi.exclamationmark").foregroundStyle(theme.muted)
                Text(store.lastError ?? String(localized: "No data")).foregroundStyle(theme.muted)
            }
        }
        .font(theme.font(.body, .callout))
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
                Label("Open app", systemImage: "macwindow")
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
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                }
                .buttonStyle(.borderless)
                .disabled(store.isLoading)

                Spacer()

                Button("Quit") { NSApplication.shared.terminate(nil) }
                    .buttonStyle(.borderless)
                    .keyboardShortcut("q")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}
