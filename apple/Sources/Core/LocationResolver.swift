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
/// Two paths, chosen by the placemark's ISO country code:
/// - "TR" or no code: the Türkiye path, exactly as before (country "2", `LocationMatcher`).
/// - any other code: `CountryCodes` → EzanVakti country, then `AbroadMatcher`. On a miss it geocodes
///   once more in English, because the catalog's twin names are English ("Mecca", not "Makkah Al
///   Mukarramah"). Codes the table leaves out (CY, and so on) give nil: no guess.
///
/// CLGeocoder is rate-limited (~50 req/hr), so results are cached by a coarse coordinate bucket —
/// matches for the session, misses abroad for an hour — and `PrayerStore` de-dupes fixes at ~500 m.
final class LocationResolver: Sendable {
    struct Match: Sendable, Equatable {
        let id: String     // district id == /vakitler/{id}
        let name: String   // display name in catalog casing, e.g. "KÜÇÜKÇEKMECE"
        var countryId: String = Config.turkiyeCountryId
        /// ISO 3166-1 code of the place ("TR", "SA"); picks the local calculation method.
        var isoCountryCode: String? = nil
    }

    typealias Geocode = @Sendable (CLLocation, Locale?) async throws -> [CLPlacemark]

    private let provider: PlacesProvider
    private let countryId: String
    private let geocode: Geocode
    private let cache = ResolverCache()

    init(
        provider: PlacesProvider = EzanVaktiProvider(),
        countryId: String = Config.turkiyeCountryId,
        geocode: @escaping Geocode = { location, locale in
            try await CLGeocoder().reverseGeocodeLocation(location, preferredLocale: locale)
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
        switch await cache.value(for: key) {
        case .hit(let match): return match
        case .miss: return nil
        case .none: break
        }

        // 1. Reverse geocode, then extract Sendable Strings out of the non-Sendable CLPlacemark.
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        guard let placemark = try await geocode(location, nil).first else { return nil }
        let iso = placemark.isoCountryCode?.uppercased()

        if iso == nil || iso == "TR" {
            let match = try await resolveInTurkiye(placemark)
            if let match { await cache.set(match, for: key) } // as before: matches only
            return match
        }
        let match = try await resolveAbroad(Self.place(placemark), location: location)
        await cache.set(match, for: key)
        return match
    }

    /// The Türkiye path, unchanged: province → City (within Türkiye), then its ilçe list → District.
    private func resolveInTurkiye(_ placemark: CLPlacemark) async throws -> Match? {
        let province = placemark.administrativeArea // il (province)
        // ilçe (district) placement drifts across OS versions — try most-specific first.
        let districtName = placemark.subAdministrativeArea ?? placemark.locality ?? placemark.subLocality

        let cities = try await provider.cities(countryId: countryId)
        guard let city = LocationMatcher.matchCity(province: province, in: cities) else { return nil }
        let districts = try await provider.districts(cityId: city.id)
        guard let district = LocationMatcher.bestMatch(
            province: province, district: districtName, districts: districts
        ) else { return nil }
        // Display the geocoded ilçe name (specific + nicely cased, e.g. "Üsküdar" / "Küçükçekmece"),
        // but keep the matched EzanVakti `id` for the times — central İstanbul ilçe fold into the
        // "İSTANBUL" entry, yet the user should still see their own district.
        return Match(id: district.id, name: districtName ?? district.name,
                     countryId: countryId, isoCountryCode: placemark.isoCountryCode?.uppercased())
    }

    /// The abroad path: ISO → country → city (state) → district, in the device locale, then once in English.
    private func resolveAbroad(_ place: AbroadMatcher.Place, location: CLLocation) async throws -> Match? {
        guard let iso = place.isoCountryCode,
              let abroadCountryId = CountryCodes.ezanVaktiCountryId[iso] else { return nil }
        let cities = try await provider.cities(countryId: abroadCountryId)

        var candidate = place
        var city = AbroadMatcher.matchCity(candidate, in: cities)
        var district: District? = nil
        if let city {
            district = AbroadMatcher.matchDistrict(candidate, in: try await provider.districts(cityId: city.id))
        }
        if district == nil, let english = try await geocode(location, Locale(identifier: "en_US")).first {
            candidate = Self.place(english)
            city = AbroadMatcher.matchCity(candidate, in: cities)
            if let city {
                district = AbroadMatcher.matchDistrict(candidate, in: try await provider.districts(cityId: city.id))
            }
        }
        guard let district else { return nil }
        // Show the name in the user's own language (first geocode), as the Türkiye path does.
        let name = place.locality ?? place.subAdministrativeArea ?? district.nameEn ?? district.name
        return Match(id: district.id, name: name, countryId: abroadCountryId, isoCountryCode: iso)
    }

    private static func place(_ p: CLPlacemark) -> AbroadMatcher.Place {
        AbroadMatcher.Place(
            isoCountryCode: p.isoCountryCode?.uppercased(),
            administrativeArea: p.administrativeArea,
            subAdministrativeArea: p.subAdministrativeArea,
            locality: p.locality,
            subLocality: p.subLocality
        )
    }

    /// ~0.01° (~1 km) bucket so jitter neither busts the cache nor burns geocoder quota.
    private static func cacheKey(_ c: CLLocationCoordinate2D) -> String {
        String(format: "%.2f,%.2f", c.latitude, c.longitude)
    }
}

/// Tiny actor-isolated cache so `LocationResolver` stays `Sendable` without a lock. Matches are kept
/// for the session; misses for `missTTL`, so an unmatched place abroad does not re-geocode on every fix.
private actor ResolverCache {
    enum Lookup { case hit(LocationResolver.Match), miss }

    private static let missTTL: TimeInterval = 3600
    private var matches: [String: LocationResolver.Match] = [:]
    private var misses: [String: Date] = [:]

    func value(for key: String, now: Date = Date()) -> Lookup? {
        if let match = matches[key] { return .hit(match) }
        if let at = misses[key], now.timeIntervalSince(at) < Self.missTTL { return .miss }
        return nil
    }

    func set(_ value: LocationResolver.Match?, for key: String, now: Date = Date()) {
        if let value { matches[key] = value } else { misses[key] = now }
    }
}
