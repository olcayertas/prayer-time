import CoreLocation
import Foundation

/// Pure, synchronous matching of geocoded place names to the EzanVakti hierarchy. No
/// CoreLocation, no networking — so it's exhaustively unit-testable (and lives in Core, which the
/// macOS test target compiles).
///
/// The hard problem this solves: EzanVakti returns ALL-CAPS Turkish ("İSTANBUL", "KÜÇÜKÇEKMECE")
/// while CLGeocoder returns mixed-case ("İstanbul", "Küçükçekmece"), and Turkish's dotted/dotless I
/// makes `uppercased()`/`lowercased()` unreliable. So both sides are folded to a locale-independent
/// canonical key before comparing.
enum LocationMatcher {

    /// Canonical comparison key: case- and diacritic-folded, dotless `ı` pinned to `i`, and all
    /// non-alphanumerics stripped. "İstanbul"/"İSTANBUL" → "istanbul"; "Küçükçekmece"/"KÜÇÜKÇEKMECE"
    /// → "kucukcekmece".
    static func normalize(_ raw: String) -> String {
        raw.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
            .replacingOccurrences(of: "ı", with: "i") // dotless ı isn't a diacritic; pin it explicitly
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .joined()
    }

    /// Match a geocoded province (il) name to a `City` in the given list.
    static func matchCity(province: String?, in cities: [City]) -> City? {
        guard let province else { return nil }
        let key = normalize(province)
        guard !key.isEmpty else { return nil }
        return cities.first { normalize($0.name) == key }
            ?? cities.first {
                let n = normalize($0.name)
                return n.contains(key) || key.contains(n)
            }
    }

    /// Best EzanVakti district for a geocoded (province, district) pair. Prefers an exact ilçe match
    /// (İstanbul lists all ~39 ilçe individually), but falls back to the province-named central
    /// entry for cities where Diyanet collapses the central ilçe into one (e.g. Ankara lists only
    /// peripheral ilçe + a single "ANKARA" entry, so Çankaya/Keçiören resolve to "ANKARA"). Returns
    /// nil when nothing matches, so the caller can keep the current district.
    static func bestMatch(
        province: String?,
        district: String?,
        districts: [District]
    ) -> District? {
        let districtKey = district.map(normalize)
        if let districtKey, !districtKey.isEmpty {
            // 1. Exact ilçe match.
            if let exact = districts.first(where: { normalize($0.name) == districtKey }) {
                return exact
            }
            // 2. Containment (geocoder "Küçükçekmece" vs a catalog "Küçükçekmece Merkez", etc.).
            if let contained = districts.first(where: {
                let n = normalize($0.name)
                return n.contains(districtKey) || districtKey.contains(n)
            }) {
                return contained
            }
        }
        // 3. Metropolitan-center fallback: the geocoded ilçe isn't separately listed, so use the
        //    province-named central entry if present.
        if let provinceKey = province.map(normalize), !provinceKey.isEmpty,
           let center = districts.first(where: { normalize($0.name) == provinceKey }) {
            return center
        }
        return nil
    }
}

/// Coordinate → Diyanet district. Reverse-geocodes (CLGeocoder), then matches the place names
/// against the EzanVakti hierarchy via `PlacesProvider`. Pure async I/O (not `@MainActor`) — the
/// caller awaits it from a `Task` and applies the result on the main actor.
///
/// CLGeocoder is rate-limited (~50 req/hr), so successful matches are cached by a coarse coordinate
/// bucket; combined with `PrayerStore`'s ~500 m coordinate de-dupe and one-shot fixes, the geocoder
/// is hit at most about once per genuine move. Turkey/Diyanet-focused: it resolves within Türkiye
/// (`countryId` "2"); elsewhere it returns nil and the caller keeps the pinned/default district.
final class LocationResolver: Sendable {
    struct Match: Sendable, Equatable {
        let id: String     // district id == /vakitler/{id}
        let name: String   // display name in catalog casing, e.g. "KÜÇÜKÇEKMECE"
    }

    private let provider: PlacesProvider
    private let countryId: String
    private let geocode: @Sendable (CLLocation) async throws -> [CLPlacemark]
    private let cache = ResolverCache()

    init(
        provider: PlacesProvider = EzanVaktiProvider(),
        countryId: String = "2", // Türkiye
        geocode: @escaping @Sendable (CLLocation) async throws -> [CLPlacemark] = { location in
            try await CLGeocoder().reverseGeocodeLocation(location)
        }
    ) {
        self.provider = provider
        self.countryId = countryId
        self.geocode = geocode
    }

    /// Best district for a coordinate, or nil when there's no confident match. Throws only on a
    /// transport/geocoder error.
    func resolve(coordinate: CLLocationCoordinate2D) async throws -> Match? {
        let key = Self.cacheKey(coordinate)
        if let hit = await cache.value(for: key) { return hit }

        // 1. Reverse geocode, then extract Sendable Strings out of the non-Sendable CLPlacemark.
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        guard let placemark = try await geocode(location).first else { return nil }
        let province = placemark.administrativeArea // il (province)
        // ilçe (district) placement drifts across OS versions — try most-specific first.
        let districtName = placemark.subAdministrativeArea ?? placemark.locality ?? placemark.subLocality

        // 2. Match province → City (within Türkiye), then its ilçe list → District.
        let cities = try await provider.cities(countryId: countryId)
        guard let city = LocationMatcher.matchCity(province: province, in: cities) else { return nil }
        let districts = try await provider.districts(cityId: city.id)
        guard let district = LocationMatcher.bestMatch(
            province: province, district: districtName, districts: districts
        ) else { return nil }
        let match = Match(id: district.id, name: district.name)
        await cache.set(match, for: key)
        return match
    }

    /// ~0.01° (~1 km) bucket so jitter neither busts the cache nor burns geocoder quota.
    private static func cacheKey(_ c: CLLocationCoordinate2D) -> String {
        String(format: "%.2f,%.2f", c.latitude, c.longitude)
    }
}

/// Tiny actor-isolated cache so `LocationResolver` stays `Sendable` without a lock.
private actor ResolverCache {
    private var store: [String: LocationResolver.Match] = [:]
    func value(for key: String) -> LocationResolver.Match? { store[key] }
    func set(_ value: LocationResolver.Match, for key: String) { store[key] = value }
}
