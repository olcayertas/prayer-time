import SwiftUI

/// Non-scrolling header above the chart: a colored dot + localized name per prayer column, aligned
/// to the chart's columns via `DayRowLayout`. Güneş (sunrise) is dimmed (informational).
struct ColumnHeaderView: View {
    let theme: Theme

    var body: some View {
        DayRowLayout {
            // Height-constrained so the empty gutter (a Color, greedy by default) doesn't stretch
            // the header row to fill the screen.
            Color.clear.frame(height: 1)
        } cell: { i in
            let prayer = Prayer.allCases[i]
            VStack(spacing: 3) {
                Circle()
                    .fill(theme.prayerColor(prayer))
                    .frame(width: 6, height: 6)
                Text(prayer.displayName)
                    .font(theme.font(.body, .caption2, weight: .bold))
                    .foregroundStyle(prayer == .gunes ? theme.faint : theme.muted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .padding(.bottom, 6)
        .overlay(alignment: .bottom) { theme.line.frame(height: 1) }
    }
}

/// The scrollable month: one thin row per day, six colored dots in equal columns over continuous
/// vertical rails. Tapping a row promotes it into the Focus Card.
struct MonthChart: View {
    let days: [MonthlyDay]
    @Binding var selectedID: String?
    let theme: Theme
    let reduceMotion: Bool

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(Array(days.enumerated()), id: \.element.id) { index, day in
                        let monthDivider = (index > 0 && day.monthIndex != days[index - 1].monthIndex)
                            ? MonthlyFormat.monthName(day.monthIndex).uppercased() : nil
                        MonthChartRow(
                            day: day,
                            isSelected: day.id == selectedID,
                            monthDivider: monthDivider,
                            theme: theme
                        ) {
                            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) {
                                selectedID = day.id
                            }
                        }
                        .id(day.id)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 24)
            }
            .onAppear {
                if let selectedID { proxy.scrollTo(selectedID, anchor: .center) }
            }
        }
    }
}

/// One day row (height `MonthlyMetrics.rowHeight`). A single `Button` (the whole row), with the full
/// VoiceOver summary. Rails are per-cell vertical lines that stack into continuous columns.
struct MonthChartRow: View {
    let day: MonthlyDay
    let isSelected: Bool
    let monthDivider: String?
    let theme: Theme
    let onTap: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            if let monthDivider { divider(monthDivider) }
            Button(action: onTap) {
                DayRowLayout {
                    Text(String(format: "%02d", day.dayNumber))
                        .font(theme.font(.mono, size: 12,
                                         weight: (day.isToday || day.isFriday) ? .bold : .semibold,
                                         relativeTo: .footnote))
                        .monospacedDigit()
                        .foregroundStyle((day.isToday || day.isFriday) ? theme.accent : theme.muted)
                        .padding(.trailing, 6)
                } cell: { i in
                    cell(i)
                }
                .frame(height: MonthlyMetrics.rowHeight)
                .background(band)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(voiceOverLabel)
            .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
        }
    }

    private func cell(_ i: Int) -> some View {
        let prayer = Prayer.allCases[i]
        let hasTime = day.times[i] != nil
        return ZStack {
            // rail (continuous across rows)
            theme.prayerColor(prayer)
                .frame(width: MonthlyMetrics.railWidth)
                .opacity(prayer == .gunes ? 0.12 : 0.2)
            if hasTime {
                if isSelected, let t = day.displayTimes[i] {
                    VStack(spacing: 2) {
                        Text(t)
                            .font(theme.font(.mono, size: 9, weight: .semibold, relativeTo: .caption2))
                            .monospacedDigit()
                            .foregroundStyle(theme.prayerColor(prayer))
                            .fixedSize()
                        Circle().fill(theme.prayerColor(prayer))
                            .frame(width: MonthlyMetrics.selectedDotRadius * 2,
                                   height: MonthlyMetrics.selectedDotRadius * 2)
                    }
                    .offset(y: -7)
                } else {
                    Circle().fill(theme.prayerColor(prayer))
                        .frame(width: MonthlyMetrics.dotRadius * 2, height: MonthlyMetrics.dotRadius * 2)
                }
            }
        }
        .frame(maxHeight: .infinity)
    }

    @ViewBuilder private var band: some View {
        if isSelected {
            RoundedRectangle(cornerRadius: 5)
                .fill(theme.accent.opacity(0.10))
                .overlay(RoundedRectangle(cornerRadius: 5).stroke(theme.accent.opacity(0.35), lineWidth: 1))
        } else if day.isToday {
            RoundedRectangle(cornerRadius: 5).fill(theme.accent.opacity(0.05))
        }
    }

    private func divider(_ label: String) -> some View {
        HStack(spacing: 8) {
            Text(label)
                .font(theme.font(.body, .caption2, weight: .bold))
                .foregroundStyle(theme.faint)
            theme.lineStrong.frame(height: 1)
        }
        .padding(.top, 8)
        .padding(.bottom, 2)
    }

    private var voiceOverLabel: Text {
        var parts = "\(day.dayNumber) \(day.weekdayName)."
        if day.isToday { parts += " Today." }
        if day.isFriday { parts += " Friday." }
        for (i, prayer) in Prayer.allCases.enumerated() {
            if let t = day.displayTimes[i] { parts += " \(prayer.displayName) \(t)." }
        }
        return Text(parts)
    }
}
