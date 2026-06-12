import Foundation

/// Reformats the Diyanet date strings for the app's current language.
///
/// The API returns the *long* Gregorian and Hijri dates as Turkish-only text
/// ("08 Haziran 2026 Pazartesi", "22 Zilhicce 1447"), but it also gives numeric short forms
/// ("08.06.2026", "22.12.1447"). We reformat those numbers locally so English and Arabic
/// users see localized month names (and Arabic-Indic digits) instead of Turkish.
///
/// `@MainActor` so the cached `DateFormatter`s (not `Sendable`) are only ever touched from
/// the UI. The locale is pinned to the app's resolved language so dates match the strings.
@MainActor
enum DateLocalizer {
    private static let appLocale = Locale(identifier: Bundle.main.preferredLocalizations.first ?? "en")

    private static let gregorian: DateFormatter = {
        let formatter = DateFormatter()
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = Config.timeZone
        formatter.calendar = calendar
        formatter.timeZone = Config.timeZone
        formatter.locale = appLocale
        formatter.dateStyle = .full          // weekday + day + month + year
        return formatter
    }()

    private static let hijri: DateFormatter = {
        let formatter = DateFormatter()
        var calendar = Calendar(identifier: .islamicUmmAlQura)
        calendar.timeZone = Config.timeZone
        formatter.calendar = calendar
        formatter.timeZone = Config.timeZone
        formatter.locale = appLocale
        formatter.setLocalizedDateFormatFromTemplate("d MMMM y")   // day + month name + year
        return formatter
    }()

    /// "08.06.2026" → "Monday, June 8, 2026" / "8 Haziran 2026 Pazartesi" / "الاثنين، ٨ يونيو ٢٠٢٦".
    static func gregorianLong(_ shortDate: String?) -> String? {
        format(shortDate, with: gregorian)
    }

    /// "22.12.1447" (numeric Hijri) → "Dhuʻl-Hijjah 22, 1447" / "22 Zilhicce 1447" / "٢٢ ذو الحجة ١٤٤٧".
    static func hijriLong(_ shortDate: String?) -> String? {
        format(shortDate, with: hijri)
    }

    private static func format(_ shortDate: String?, with formatter: DateFormatter) -> String? {
        guard let ymd = PrayerSchedule.parseDate(shortDate) else { return nil }
        var components = DateComponents()
        components.year = ymd.year
        components.month = ymd.month
        components.day = ymd.day
        components.hour = 12                  // midday avoids any midnight/DST edge
        guard let date = formatter.calendar.date(from: components) else { return nil }
        return formatter.string(from: date)
    }
}
