import SwiftUI

/// Rich view of today's prayer times: hero countdown, the six times, and extras.
struct TodayView: View {
    @ObservedObject var store: PrayerStore
    @Environment(\.theme) private var theme

    private let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    // Hero point sizes — fixed by design, but scaled with Dynamic Type via @ScaledMetric.
    @ScaledMetric(relativeTo: .largeTitle) private var countdownSize: CGFloat = 42
    @ScaledMetric(relativeTo: .largeTitle) private var heroIconSize: CGFloat = 44
    @ScaledMetric(relativeTo: .title2) private var heroIconCompactSize: CGFloat = 36

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
            .themedRootBackground(theme)
        }
        .navigationTitle("Today")
        #if os(iOS)
        .toolbar(.hidden, for: .navigationBar)
        #endif
    }

    private func header(today: PrayerDay?) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(store.locationName)
                .font(theme.font(.display, .largeTitle, weight: .bold))
                .foregroundStyle(theme.text)
            if let today {
                HStack(spacing: 8) {
                    if let gregorian = DateLocalizer.gregorianLong(today.miladiTarihKisa) { Text(gregorian) }
                    if let hicri = DateLocalizer.hijriLong(today.hicriTarihKisa) {
                        Text("·").foregroundStyle(theme.faint)
                        Text(hicri)
                    }
                }
                .font(theme.font(.body, .callout))
                .foregroundStyle(theme.muted)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func hero(upcoming: UpcomingPrayer?) -> some View {
        Group {
            if let upcoming {
                // Wide (macOS / iPad) shows it all on one row; a narrow phone can't fit the
                // big H:MM:SS countdown beside the name, so fall back to a stacked layout
                // that gives the countdown its own full-width line.
                ViewThatFits(in: .horizontal) {
                    heroRow(upcoming)
                    heroStacked(upcoming)
                }
            } else {
                Text("Couldn't load today's times").foregroundStyle(theme.muted)
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity)
        .background(theme.accentSoft, in: RoundedRectangle(cornerRadius: 16))
    }

    private func heroLabel(_ upcoming: UpcomingPrayer) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Next prayer").font(theme.font(.body, .subheadline)).foregroundStyle(theme.muted)
            Text(upcoming.prayer.displayName)
                .font(theme.font(.display, .title, weight: .semibold))
                .foregroundStyle(theme.text)
                .lineLimit(1)
        }
    }

    private func heroCountdown(_ upcoming: UpcomingPrayer) -> some View {
        Text(CountdownFormatter.string(upcoming.remaining))
            .font(theme.font(.rounded, size: countdownSize, weight: .bold, relativeTo: .largeTitle))
            .monospacedDigit()
            .foregroundStyle(theme.accent)
            .lineLimit(1)
    }

    /// One-row hero. `.fixedSize()` makes the name + countdown report their full intrinsic
    /// width so `ViewThatFits` can tell when the row no longer fits and switch to stacked.
    private func heroRow(_ upcoming: UpcomingPrayer) -> some View {
        HStack(spacing: 20) {
            Image(systemName: upcoming.prayer.symbolName)
                .font(.system(size: heroIconSize)).foregroundStyle(theme.accent).frame(width: 64)
            heroLabel(upcoming).fixedSize()
            Spacer(minLength: 16)
            VStack(alignment: .trailing, spacing: 2) {
                heroCountdown(upcoming).fixedSize()
                Text("remaining").font(theme.font(.body, .caption)).foregroundStyle(theme.muted)
            }
        }
    }

    private func heroStacked(_ upcoming: UpcomingPrayer) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 14) {
                Image(systemName: upcoming.prayer.symbolName)
                    .font(.system(size: heroIconCompactSize)).foregroundStyle(theme.accent)
                heroLabel(upcoming)
                Spacer(minLength: 0)
            }
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                heroCountdown(upcoming).minimumScaleFactor(0.7)
                Text("remaining").font(theme.font(.body, .caption)).foregroundStyle(theme.muted)
                Spacer(minLength: 0)
            }
        }
    }

    private func grid(today: PrayerDay, current: Prayer?, next: Prayer?) -> some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(Prayer.allCases) { prayer in
                let isNext = prayer == next
                let isCurrent = prayer == current
                VStack(spacing: 6) {
                    Image(systemName: prayer.symbolName)
                        .font(.title2)
                        .foregroundStyle(isNext ? theme.accent : theme.muted)
                    Text(prayer.displayName)
                        .font(theme.font(.body, .subheadline, weight: isNext ? .semibold : .regular))
                        .foregroundStyle(theme.text)
                    Text(today.time(for: prayer))
                        .font(theme.font(.mono, .title3, weight: .medium))
                        .monospacedDigit()
                        .foregroundStyle(theme.text)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isNext ? theme.accentSoft : theme.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(isCurrent ? theme.accent : Color.clear, lineWidth: 1.5)
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
            Image(systemName: symbol).foregroundStyle(theme.muted)
            VStack(alignment: .leading, spacing: 1) {
                Text(label).font(theme.font(.body, .caption2)).foregroundStyle(theme.muted)
                Text(value).font(theme.font(.mono, .callout)).monospacedDigit().foregroundStyle(theme.text)
            }
        }
    }
}
