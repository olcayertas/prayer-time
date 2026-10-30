import Foundation

/// On-device prayer-time calculation from coordinates, for the "local authority" calculation method.
/// Pure and deterministic, so it lives in Core and is golden-tested against published tables.
///
/// The solar position and hour-angle formulas are the standard low-precision ones (U.S. Naval
/// Observatory approximation, as used by most prayer-time calculators); they are accurate to well
/// under a minute between ±65° latitude. Higher latitudes, where twilight angles may never be reached,
/// return nil for that time and the caller keeps the Diyanet value.
enum PrayerCalculator {

    /// Times of one day as fractional hours of the local clock (e.g. 5.087 = 05:05:13).
    struct DayTimes: Equatable, Sendable {
        var fajr: Double?
        var sunrise: Double?
        var dhuhr: Double
        var asr: Double?
        var maghrib: Double?
        var isha: Double?
    }

    struct Parameters: Equatable, Sendable {
        /// Sun angle below the horizon at dawn, in degrees.
        var fajrAngle: Double
        /// Sun angle below the horizon at nightfall, or nil when Isha is a fixed interval after Maghrib.
        var ishaAngle: Double?
        /// Minutes after Maghrib, used when `ishaAngle` is nil.
        var ishaMinutesAfterMaghrib: Double = 0
        /// Shadow length factor for Asr: 1 = Shafi'i/Maliki/Hanbali, 2 = Hanafi.
        var asrShadowFactor: Double = 1
    }

    static func times(
        year: Int, month: Int, day: Int,
        latitude: Double, longitude: Double, utcOffsetHours: Double,
        parameters: Parameters
    ) -> DayTimes {
        let jd = julianDay(year: year, month: month, day: day) - longitude / 360

        func noon(_ t: Double) -> Double {
            let eqt = sunPosition(jd + t / 24).equationOfTime
            return fixHour(12 - eqt)
        }
        func hourAngleTime(_ angle: Double, _ t: Double, beforeNoon: Bool) -> Double? {
            let dec = sunPosition(jd + t / 24).declination
            let cosT = (-dsin(angle) - dsin(dec) * dsin(latitude)) / (dcos(dec) * dcos(latitude))
            guard (-1...1).contains(cosT) else { return nil }
            let h = darccos(cosT) / 15
            return noon(t) + (beforeNoon ? -h : h)
        }
        func asrTime(_ t: Double) -> Double? {
            let dec = sunPosition(jd + t / 24).declination
            let angle = -darccot(parameters.asrShadowFactor + dtan(abs(latitude - dec)))
            return hourAngleTime(angle, t, beforeNoon: false)
        }

        let fajr = hourAngleTime(parameters.fajrAngle, 5, beforeNoon: true)
        let sunrise = hourAngleTime(0.833, 6, beforeNoon: true)
        let dhuhr = noon(12)
        let asr = asrTime(13)
        let maghrib = hourAngleTime(0.833, 18, beforeNoon: false)
        let isha: Double?
        if let angle = parameters.ishaAngle {
            isha = hourAngleTime(angle, 18, beforeNoon: false)
        } else {
            isha = maghrib.map { $0 + parameters.ishaMinutesAfterMaghrib / 60 }
        }

        // The hour angles are in local solar time; shift to the zone's clock.
        let shift = utcOffsetHours - longitude / 15
        func clock(_ t: Double?) -> Double? { t.map { fixHour($0 + shift) } }
        return DayTimes(
            fajr: clock(fajr), sunrise: clock(sunrise), dhuhr: fixHour(dhuhr + shift), asr: clock(asr),
            maghrib: clock(maghrib), isha: clock(isha)
        )
    }

    /// "HH:mm" from fractional hours, rounding up to the next whole minute (`roundUp`) or down.
    static func hhmm(_ hours: Double, roundUp: Bool) -> String {
        let seconds = hours * 3600
        // A tolerance so a value that is exactly on a minute does not jump to the next one.
        var minutes = Int(roundUp ? (seconds / 60 - 1e-6).rounded(.up) : (seconds / 60 + 1e-6).rounded(.down))
        minutes = ((minutes % 1440) + 1440) % 1440
        return String(format: "%02d:%02d", minutes / 60, minutes % 60)
    }

    // MARK: - Astronomy

    static func julianDay(year: Int, month: Int, day: Int) -> Double {
        var y = year, m = month
        if m <= 2 { y -= 1; m += 12 }
        let a = y / 100
        let b = 2 - a + a / 4
        return floor(365.25 * Double(y + 4716)) + floor(30.6001 * Double(m + 1)) + Double(day) + Double(b) - 1524.5
    }

    /// Sun declination (degrees) and equation of time (hours) for a Julian day.
    static func sunPosition(_ jd: Double) -> (declination: Double, equationOfTime: Double) {
        let d = jd - 2451545.0
        let g = fixAngle(357.529 + 0.98560028 * d)
        let q = fixAngle(280.459 + 0.98564736 * d)
        let l = fixAngle(q + 1.915 * dsin(g) + 0.020 * dsin(2 * g))
        let e = 23.439 - 0.00000036 * d
        let ra = fixHour(datan2(dcos(e) * dsin(l), dcos(l)) / 15)
        return (darcsin(dsin(e) * dsin(l)), q / 15 - ra)
    }

    private static func fixAngle(_ a: Double) -> Double { let r = a.truncatingRemainder(dividingBy: 360); return r < 0 ? r + 360 : r }
    private static func fixHour(_ h: Double) -> Double { let r = h.truncatingRemainder(dividingBy: 24); return r < 0 ? r + 24 : r }
    private static func dsin(_ d: Double) -> Double { sin(d * .pi / 180) }
    private static func dcos(_ d: Double) -> Double { cos(d * .pi / 180) }
    private static func dtan(_ d: Double) -> Double { tan(d * .pi / 180) }
    private static func darcsin(_ x: Double) -> Double { asin(x) * 180 / .pi }
    private static func darccos(_ x: Double) -> Double { acos(x) * 180 / .pi }
    private static func darccot(_ x: Double) -> Double { atan(1 / x) * 180 / .pi }
    private static func datan2(_ y: Double, _ x: Double) -> Double { atan2(y, x) * 180 / .pi }
}
