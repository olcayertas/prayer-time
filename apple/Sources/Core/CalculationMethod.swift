import Foundation

/// Which source gives the prayer times. Persisted in the App Group so the widget agrees with the app.
enum CalculationMethod: String, CaseIterable, Identifiable, Sendable {
    /// The Diyanet times from EzanVakti, unchanged. The default.
    case diyanet
    /// The local authority's method of the place's country, calculated on the device. Only available
    /// where `LocalMethod.forCountry` has one and the place has coordinates; otherwise Diyanet is used.
    case local

    var id: String { rawValue }

    static let key = "calculationMethod"

    static func load(_ defaults: UserDefaults = AppGroup.defaults) -> CalculationMethod {
        defaults.string(forKey: key).flatMap(CalculationMethod.init(rawValue:)) ?? .diyanet
    }
}

/// A local authority's published method. Only methods whose published parameters reproduce the
/// authority's own published table are listed (see `docs/CALCULATION-METHODS.md`).
enum LocalMethod: String, Sendable {
    /// Saudi Arabia, Umm al-Qura calendar (KACST): Fajr 18.5°, Isha 90 min after Maghrib (120 in
    /// Ramadan), Asr shadow factor 1. Times round up to the next minute, sunrise rounds down.
    case ummAlQura

    static func forCountry(_ iso: String?) -> LocalMethod? {
        switch iso?.uppercased() {
        case "SA": return .ummAlQura
        default: return nil
        }
    }

    var displayName: String {
        switch self {
        case .ummAlQura: return String(localized: "Umm al-Qura", comment: "Calculation method of Saudi Arabia")
        }
    }

    /// The six times of one Diyanet day, recalculated with this method. Dates, Hijri date and the day's
    /// UTC offset stay as Diyanet gives them (the Hijri month decides Ramadan; no calendar conversion).
    /// Returns the day unchanged when it has no date or offset, or a time cannot be calculated.
    func apply(to day: PrayerDay, latitude: Double, longitude: Double) -> PrayerDay {
        guard let ymd = PrayerSchedule.parseDate(day.miladiTarihKisa),
              let offset = day.utcOffsetSeconds else { return day }
        switch self {
        case .ummAlQura:
            let ramadan = PrayerSchedule.parseDate(day.hicriTarihKisa)?.month == 9
            let t = PrayerCalculator.times(
                year: ymd.year, month: ymd.month, day: ymd.day,
                latitude: latitude, longitude: longitude, utcOffsetHours: Double(offset) / 3600,
                parameters: .init(fajrAngle: 18.5, ishaAngle: nil, ishaMinutesAfterMaghrib: ramadan ? 120 : 90)
            )
            guard let fajr = t.fajr, let sunrise = t.sunrise, let asr = t.asr,
                  let maghrib = t.maghrib, let isha = t.isha else { return day }
            let up = { PrayerCalculator.hhmm($0, roundUp: true) }
            return day.replacingTimes(
                imsak: up(fajr), gunes: PrayerCalculator.hhmm(sunrise, roundUp: false), ogle: up(t.dhuhr),
                ikindi: up(asr), aksam: up(maghrib), yatsi: up(isha)
            )
        }
    }
}

/// What the method needs to know about the selected place. Written with the selection (automatic or
/// pinned) into the App Group; the widget reads the same values.
struct PlaceContext: Equatable, Sendable {
    var isoCountryCode: String?
    var latitude: Double?
    var longitude: Double?

    static let isoKey = "placeIsoCountryCode"
    static let latitudeKey = "placeLatitude"
    static let longitudeKey = "placeLongitude"

    static func load(_ defaults: UserDefaults = AppGroup.defaults) -> PlaceContext {
        PlaceContext(
            isoCountryCode: defaults.string(forKey: isoKey),
            latitude: defaults.object(forKey: latitudeKey) as? Double,
            longitude: defaults.object(forKey: longitudeKey) as? Double
        )
    }

    func save(_ defaults: UserDefaults = AppGroup.defaults) {
        defaults.set(isoCountryCode, forKey: Self.isoKey)
        defaults.set(latitude, forKey: Self.latitudeKey)
        defaults.set(longitude, forKey: Self.longitudeKey)
    }

    /// The local method for this place, when the country has one and the place has coordinates.
    var localMethod: LocalMethod? {
        guard latitude != nil, longitude != nil else { return nil }
        return LocalMethod.forCountry(isoCountryCode)
    }
}

/// Raw Diyanet month → the month the app shows, for the chosen method. Pure; the app and the widget
/// both call it, so they never disagree.
enum EffectiveTimes {
    static func days(_ raw: [PrayerDay], method: CalculationMethod, place: PlaceContext) -> [PrayerDay] {
        guard method == .local, let local = place.localMethod,
              let lat = place.latitude, let lon = place.longitude else { return raw }
        return raw.map { local.apply(to: $0, latitude: lat, longitude: lon) }
    }

    static func days(_ raw: [PrayerDay], defaults: UserDefaults = AppGroup.defaults) -> [PrayerDay] {
        days(raw, method: .load(defaults), place: .load(defaults))
    }
}
