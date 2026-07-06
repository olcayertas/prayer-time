import SwiftUI

/// Monthly browsing screen: a spacious **Focus Card** for one selected day on top, and a compact
/// **chart** of the whole month below (one thin row per day, six prayers as colored dots in equal
/// columns). Tapping a row promotes it into the Focus Card. Replaces the old 7-column table;
/// renders under any theme (colors/fonts come from `@Environment(\.theme)`).
struct MonthView: View {
    @ObservedObject var store: PrayerStore
    @Environment(\.theme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var selectedID: String?

    var body: some View {
        let days = MonthlyDayBuilder.build(schedule: store.schedule, now: Date())
        let selected = days.first { $0.id == selectedID } ?? days.first

        VStack(spacing: 0) {
            MonthHeaderView(month: selected?.monthIndex, year: selected?.year, theme: theme)
            if days.isEmpty {
                Spacer()
                ProgressView("Loading…").foregroundStyle(theme.muted)
                Spacer()
            } else {
                FocusCard(day: selected, store: store, theme: theme)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 6)
                GlanceDivider(theme: theme)
                ColumnHeaderView(theme: theme)
                    .padding(.horizontal, 14)
                MonthChart(days: days, selectedID: $selectedID, theme: theme, reduceMotion: reduceMotion)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .themedRootBackground(theme)
        .navigationTitle("Monthly")
        #if os(iOS)
        .toolbar(.hidden, for: .navigationBar)
        #endif
        .onAppear { if selectedID == nil { selectedID = days.first(where: \.isToday)?.id ?? days.first?.id } }
        .onChange(of: store.days.first?.miladiTarihKisa) { _, _ in
            // New month loaded (e.g. location change) — re-anchor the selection to today / first day.
            let fresh = MonthlyDayBuilder.build(schedule: store.schedule, now: Date())
            selectedID = fresh.first(where: \.isToday)?.id ?? fresh.first?.id
        }
    }
}

/// Eyebrow + month title + ‹ › nav. Nav is disabled in v1 (the store holds a single month);
/// wiring month navigation to a multi-month loader is a follow-up.
private struct MonthHeaderView: View {
    let month: Int?
    let year: Int?
    let theme: Theme

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Prayer Times")
                .font(theme.font(.body, .caption2, weight: .bold))
                .tracking(2)
                .textCase(.uppercase)
                .foregroundStyle(theme.accent.opacity(0.85))
            HStack(alignment: .firstTextBaseline) {
                HStack(spacing: 6) {
                    Text(month.map(MonthlyFormat.monthName) ?? "")
                        .foregroundStyle(theme.text)
                    if let year { Text(String(year)).foregroundStyle(theme.faint) }
                }
                .font(theme.font(.display, .title, weight: .medium))
                Spacer()
                HStack(spacing: 8) {
                    navButton("chevron.left")
                    navButton("chevron.right")
                }
            }
        }
        .padding(.horizontal, 22)
        .padding(.top, 4)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func navButton(_ symbol: String) -> some View {
        Image(systemName: symbol)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(theme.muted)
            .frame(width: 32, height: 32)
            .background(theme.surface, in: RoundedRectangle(cornerRadius: 10))
            .opacity(0.4)   // disabled: single month in v1
    }
}

/// "The Month" divider with a "tap a day" hint.
private struct GlanceDivider: View {
    let theme: Theme
    var body: some View {
        HStack(spacing: 10) {
            Text("The Month")
                .font(theme.font(.body, .caption, weight: .bold))
                .tracking(1.5)
                .textCase(.uppercase)
                .foregroundStyle(theme.faint)
            theme.line.frame(height: 1)
            Text("tap a day")
                .font(theme.font(.body, .caption2))
                .foregroundStyle(theme.faint)
        }
        .padding(.horizontal, 22)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }
}

/// The selected day in full: big day number, weekday + location, a next-prayer/date chip, and the
/// six prayer times as cells (the next one highlighted on today; Güneş dimmed).
private struct FocusCard: View {
    let day: MonthlyDay?
    @ObservedObject var store: PrayerStore
    let theme: Theme

    var body: some View {
        Group {
            if let day {
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    let upcoming = day.isToday ? store.schedule.upcoming(now: context.date) : nil
                    let nextIndex = upcoming.flatMap { up in Prayer.allCases.firstIndex(of: up.prayer) }
                    VStack(spacing: 13) {
                        header(day, upcoming: upcoming)
                        prayerCells(day, nextIndex: nextIndex)
                    }
                }
            } else {
                Text("Couldn't load today's times")
                    .font(theme.font(.body, .callout)).foregroundStyle(theme.muted)
                    .frame(maxWidth: .infinity, minHeight: 100)
            }
        }
        .padding(EdgeInsets(top: 13, leading: 15, bottom: 14, trailing: 15))
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(colors: [theme.elevatedCardTop, theme.elevatedCardBottom],
                           startPoint: .top, endPoint: .bottom),
            in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(theme.accent.opacity(0.16), lineWidth: 1))
    }

    private func header(_ day: MonthlyDay, upcoming: UpcomingPrayer?) -> some View {
        HStack(alignment: .center, spacing: 11) {
            Text(String(format: "%02d", day.dayNumber))
                .font(theme.font(.display, size: 34, weight: .medium, relativeTo: .largeTitle))
                .foregroundStyle(theme.accent)
            VStack(alignment: .leading, spacing: 1) {
                Text(day.isToday ? "\(day.weekdayName) · \(todayWord)" : day.weekdayName)
                    .font(theme.font(.body, .subheadline, weight: .semibold))
                    .foregroundStyle(theme.text)
                HStack(spacing: 4) {
                    Image(systemName: "mappin.and.ellipse").font(.system(size: 10))
                    Text("\(store.locationName) · \(MonthlyFormat.monthName(day.monthIndex)) \(String(day.year))")
                }
                .font(theme.font(.body, .caption))
                .foregroundStyle(theme.muted)
            }
            Spacer(minLength: 8)
            chip(day, upcoming: upcoming)
        }
    }

    private var todayWord: String { String(localized: "Today") }

    @ViewBuilder private func chip(_ day: MonthlyDay, upcoming: UpcomingPrayer?) -> some View {
        if day.isToday, let upcoming {
            VStack(alignment: .trailing, spacing: 1) {
                Text("Next · \(upcoming.prayer.displayName)")
                Text(CountdownFormatter.string(upcoming.remaining)).monospacedDigit()
            }
            .font(theme.font(.body, .caption2, weight: .semibold))
            .foregroundStyle(theme.accent)
            .padding(.vertical, 5).padding(.horizontal, 10)
            .background(theme.accentSoft, in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(theme.accent.opacity(0.25), lineWidth: 1))
        } else {
            Text("\(MonthlyFormat.monthName(day.monthIndex)) \(day.dayNumber)")
                .font(theme.font(.body, .caption2, weight: .semibold))
                .foregroundStyle(theme.muted)
                .padding(.vertical, 5).padding(.horizontal, 10)
                .background(theme.surface, in: RoundedRectangle(cornerRadius: 14))
        }
    }

    private func prayerCells(_ day: MonthlyDay, nextIndex: Int?) -> some View {
        HStack(spacing: 4) {
            ForEach(Array(Prayer.allCases.enumerated()), id: \.element) { i, prayer in
                let isNext = i == nextIndex
                let isSun = prayer == .gunes
                VStack(spacing: 5) {
                    Circle().fill(theme.prayerColor(prayer)).frame(width: 7, height: 7)
                    Text(prayer.displayName)
                        .font(theme.font(.body, .caption2, weight: .bold))
                        .textCase(.uppercase)
                        .foregroundStyle(isNext ? theme.accent : (isSun ? theme.faint : theme.muted))
                        .lineLimit(1).minimumScaleFactor(0.6)
                    Text(day.displayTimes[i] ?? "—")
                        .font(theme.font(.mono, size: 13, weight: .medium, relativeTo: .footnote))
                        .monospacedDigit()
                        .foregroundStyle(isNext ? theme.accent : (isSun ? theme.faint : theme.text))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8).padding(.horizontal, 2)
                .background {
                    if isNext {
                        RoundedRectangle(cornerRadius: 11).fill(theme.accentSoft)
                            .overlay(RoundedRectangle(cornerRadius: 11).strokeBorder(theme.accent.opacity(0.3), lineWidth: 1))
                    }
                }
            }
        }
    }
}
