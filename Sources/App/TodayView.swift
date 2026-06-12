import SwiftUI
import AppKit

/// Rich view of today's prayer times: hero countdown, the six times, and extras.
struct TodayView: View {
    @ObservedObject var store: PrayerStore

    private let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let now = context.date
            let today = store.schedule.day(on: now) ?? store.days.first
            let upcoming = store.schedule.upcoming(now: now)
            let current = store.schedule.current(now: now)

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header(today: today)
                    if let today {
                        hero(upcoming: upcoming)
                        grid(today: today, current: current, next: upcoming?.prayer)
                        extras(today: today)
                    } else {
                        ProgressView("Loading…")
                            .frame(maxWidth: .infinity, minHeight: 220)
                    }
                }
                .padding(24)
            }
        }
        .navigationTitle("Today")
    }

    private func header(today: PrayerDay?) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(store.locationName).font(.largeTitle.bold())
            if let today {
                HStack(spacing: 8) {
                    if let gregorian = DateLocalizer.gregorianLong(today.miladiTarihKisa) { Text(gregorian) }
                    if let hicri = DateLocalizer.hijriLong(today.hicriTarihKisa) {
                        Text("·").foregroundStyle(.tertiary)
                        Text(hicri)
                    }
                }
                .font(.callout)
                .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func hero(upcoming: UpcomingPrayer?) -> some View {
        HStack(spacing: 20) {
            if let upcoming {
                Image(systemName: upcoming.prayer.symbolName)
                    .font(.system(size: 44))
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 64)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Next prayer").font(.subheadline).foregroundStyle(.secondary)
                    Text(upcoming.prayer.displayName).font(.title.weight(.semibold))
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(CountdownFormatter.string(upcoming.remaining))
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(Color.accentColor)
                    Text("remaining").font(.caption).foregroundStyle(.secondary)
                }
            } else {
                Text("Couldn't load today's times").foregroundStyle(.secondary)
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity)
        .background(Color.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 16))
    }

    private func grid(today: PrayerDay, current: Prayer?, next: Prayer?) -> some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(Prayer.allCases) { prayer in
                let isNext = prayer == next
                let isCurrent = prayer == current
                VStack(spacing: 6) {
                    Image(systemName: prayer.symbolName)
                        .font(.title2)
                        .foregroundStyle(isNext ? Color.accentColor : Color.secondary)
                    Text(prayer.displayName)
                        .font(.subheadline)
                        .fontWeight(isNext ? .semibold : .regular)
                    Text(today.time(for: prayer))
                        .font(.title3)
                        .monospacedDigit()
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isNext ? Color.accentColor.opacity(0.15) : Color(nsColor: .controlBackgroundColor))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(isCurrent ? Color.accentColor : Color.clear, lineWidth: 1.5)
                )
            }
        }
    }

    private func extras(today: PrayerDay) -> some View {
        HStack(spacing: 28) {
            if let sunrise = today.gunesDogus {
                infoItem("sunrise.fill", String(localized: "extras.sunrise", defaultValue: "Sunrise"), sunrise)
            }
            if let sunset = today.gunesBatis {
                infoItem("sunset.fill", String(localized: "extras.sunset", defaultValue: "Sunset"), sunset)
            }
            if let qibla = today.kibleSaati {
                infoItem("location.north.line.fill", String(localized: "extras.qibla", defaultValue: "Qibla time"), qibla)
            }
            Spacer()
        }
        .padding(.top, 4)
    }

    private func infoItem(_ symbol: String, _ label: String, _ value: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: symbol).foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 1) {
                Text(label).font(.caption2).foregroundStyle(.secondary)
                Text(value).font(.callout).monospacedDigit()
            }
        }
    }
}
