import Foundation

/// The next prayer relative to a moment in time, with how long until it begins.
struct UpcomingPrayer: Equatable, Sendable {
    let prayer: Prayer
    let date: Date
    let remaining: TimeInterval
}

/// Turns a month of `PrayerDay` rows into time-of-day instants and answers
/// "what's the next prayer and how long until it?".
///
/// All instants are built in Türkiye local time (`Europe/Istanbul`) because that is the
/// clock the published times refer to, regardless of where the Mac's own clock is set.
struct PrayerSchedule: Equatable, Sendable {
    var days: [PrayerDay]
    var timeZone: TimeZone

    init(days: [PrayerDay], timeZone: TimeZone = Config.timeZone) {
        self.days = days
        self.timeZone = timeZone
    }

    private var calendar: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = timeZone
        return c
    }

    /// All (prayer, instant) pairs across the loaded month, sorted ascending.
    func sortedTimes() -> [(prayer: Prayer, date: Date)] {
        days
            .flatMap { day in
                Prayer.allCases.compactMap { prayer -> (Prayer, Date)? in
                    guard let date = date(for: prayer, on: day) else { return nil }
                    return (prayer, date)
                }
            }
            .sorted { $0.1 < $1.1 }
    }

    /// The next prayer strictly after `now`. Rolls into the following day automatically
    /// (e.g. after Yatsı it returns tomorrow's İmsak), as long as the month covers it.
    func upcoming(now: Date) -> UpcomingPrayer? {
        guard let next = sortedTimes().first(where: { $0.date > now }) else { return nil }
        return UpcomingPrayer(prayer: next.prayer, date: next.date, remaining: next.date.timeIntervalSince(now))
    }

    /// The prayer period `now` currently falls in (the most recent time at or before `now`).
    func current(now: Date) -> Prayer? {
        sortedTimes().last(where: { $0.date <= now })?.prayer
    }

    /// The `PrayerDay` row whose Gregorian date matches `date` in Istanbul time.
    func day(on date: Date) -> PrayerDay? {
        let comps = calendar.dateComponents([.year, .month, .day], from: date)
        return days.first { day in
            guard let ymd = Self.parseDate(day.miladiTarihKisa) else { return false }
            return ymd.year == comps.year && ymd.month == comps.month && ymd.day == comps.day
        }
    }

    /// Builds the instant for one prayer on one day, in Istanbul time.
    func date(for prayer: Prayer, on day: PrayerDay) -> Date? {
        guard let ymd = Self.parseDate(day.miladiTarihKisa),
              let hm = Self.parseTime(day.time(for: prayer)) else { return nil }
        var comps = DateComponents()
        comps.year = ymd.year
        comps.month = ymd.month
        comps.day = ymd.day
        comps.hour = hm.hour
        comps.minute = hm.minute
        return calendar.date(from: comps)
    }

    // MARK: - Parsing helpers

    /// "dd.MM.yyyy" → (year, month, day).
    static func parseDate(_ string: String?) -> (year: Int, month: Int, day: Int)? {
        guard let string else { return nil }
        let parts = string.split(separator: ".")
        guard parts.count == 3,
              let day = Int(parts[0]), let month = Int(parts[1]), let year = Int(parts[2]) else {
            return nil
        }
        return (year, month, day)
    }

    /// "HH:mm" → (hour, minute). Tolerates surrounding whitespace.
    static func parseTime(_ string: String) -> (hour: Int, minute: Int)? {
        let parts = string.trimmingCharacters(in: .whitespaces).split(separator: ":")
        guard parts.count >= 2, let hour = Int(parts[0]), let minute = Int(parts[1]) else {
            return nil
        }
        return (hour, minute)
    }
}
