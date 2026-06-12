import Foundation

/// Static configuration for the v1 single-location build.
///
/// The location is currently hardcoded to Küçükçekmece (Diyanet district id `9543`,
/// the id from the source URL). A country/city/district picker is deferred — see the
/// EzanVakti hierarchy endpoints (`/ulkeler`, `/sehirler/{id}`, `/ilceler/{id}`).
enum Config {
    /// Diyanet district id used for `/vakitler/{id}`.
    static let defaultDistrictId = "9543"

    /// Human-readable name for the default district.
    static let defaultLocationName = "Küçükçekmece"

    /// All prayer times are published as Türkiye-local clock times.
    static let timeZoneIdentifier = "Europe/Istanbul"

    static var timeZone: TimeZone {
        TimeZone(identifier: timeZoneIdentifier) ?? .current
    }
}
