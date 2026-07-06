import Foundation

/// One day shaped for the Monthly chart + focus card. Built from the app's `PrayerDay` via the
/// existing schedule APIs — not a parallel data source.
struct MonthlyDay: Identifiable, Equatable {
    let id: String              // = PrayerDay.miladiTarihKisa ("dd.MM.yyyy"), stable
    let dayNumber: Int
    let monthIndex: Int         // for the month-boundary divider
    let year: Int
    let weekdayName: String     // localized (e.g. "Cuma" / "Friday")
    let isFriday: Bool
    let isToday: Bool
    let times: [Date?]          // index 0…5 = Prayer.allCases; nil = missing (omit dot)
    let displayTimes: [String?] // "HH:mm" per prayer; nil → render "—"

    /// All six times present? (used for the VoiceOver summary)
    var hasAnyTime: Bool { times.contains { $0 != nil } }
}

enum MonthlyFormat {
    /// Localized standalone month name for a 1-based month index (e.g. 6 → "June" / "Haziran").
    static func monthName(_ monthIndex: Int) -> String {
        let symbols = DateFormatter().standaloneMonthSymbols ?? []
        guard monthIndex >= 1, monthIndex <= symbols.count else { return "" }
        return symbols[monthIndex - 1]
    }
}

enum MonthlyMetrics {
    static let gutter: CGFloat = 34
    static let rowHeight: CGFloat = 20
    static let railWidth: CGFloat = 1.3
    static let dotRadius: CGFloat = 2.3
    static let selectedDotRadius: CGFloat = 3.4
}

enum MonthlyDayBuilder {
    /// Maps `schedule.days` to view models, in order. `now` decides "today".
    static func build(schedule: PrayerSchedule, now: Date) -> [MonthlyDay] {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = Config.timeZone
        let todayKey = schedule.day(on: now)?.miladiTarihKisa

        let weekdayFmt = DateFormatter()
        weekdayFmt.calendar = cal
        weekdayFmt.timeZone = Config.timeZone
        weekdayFmt.locale = .autoupdatingCurrent
        weekdayFmt.setLocalizedDateFormatFromTemplate("EEEE")

        return schedule.days.compactMap { day in
            guard let key = day.miladiTarihKisa,
                  let ymd = PrayerSchedule.parseDate(key),
                  let date = cal.date(from: DateComponents(year: ymd.year, month: ymd.month, day: ymd.day, hour: 12))
            else { return nil }
            let weekday = cal.component(.weekday, from: date)   // 1=Sun … 6=Fri … 7=Sat
            return MonthlyDay(
                id: key,
                dayNumber: ymd.day,
                monthIndex: ymd.month,
                year: ymd.year,
                weekdayName: weekdayFmt.string(from: date),
                isFriday: weekday == 6,
                isToday: key == todayKey,
                times: Prayer.allCases.map { schedule.date(for: $0, on: day) },
                displayTimes: Prayer.allCases.map {
                    let t = day.time(for: $0).trimmingCharacters(in: .whitespaces)
                    return t.isEmpty ? nil : t
                })
        }
    }
}
