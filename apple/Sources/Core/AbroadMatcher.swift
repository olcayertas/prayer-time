import Foundation

/// Pure matching of a geocoded place OUTSIDE Türkiye to the EzanVakti hierarchy. The Türkiye path
/// (`LocationMatcher`) is separate and unchanged.
///
/// Abroad the hierarchy has a different shape: 198 of 202 countries have ONE "city" that is the whole
/// country, and its districts are the real cities and towns ("MEKKE", "CIDDE", "SARAYBOSNA(sarajevo)").
/// Only the US, Germany and Canada have a state level. District names are Turkish exonyms in ASCII, with
/// an English/local twin in `nameEn` (MEKKE/MECCA, CIDDE/JEDDAH, MUNCHEN/MUNCHEN). So matching tries
/// both names, a few verified aliases, and never the province first (Jeddah's province is "Mecca").
enum AbroadMatcher {

    /// The placemark fields the matcher reads, as plain Strings (CLPlacemark / Address are not Sendable).
    struct Place: Equatable, Sendable {
        var isoCountryCode: String?
        var administrativeArea: String?
        var subAdministrativeArea: String?
        var locality: String?
        var subLocality: String?
    }

    // MARK: - City (state) level

    /// The EzanVakti city for an abroad place: the only city of a single-city country, else the state
    /// that matches `administrativeArea` (by name, English name, or a per-country alias/abbreviation).
    static func matchCity(_ place: Place, in cities: [City]) -> City? {
        if cities.count == 1 { return cities[0] }
        guard let area = place.administrativeArea else { return nil }
        var key = LocationMatcher.normalize(area)
        if let alias = stateAliases[place.isoCountryCode?.uppercased() ?? ""]?[key] { key = alias }
        guard !key.isEmpty else { return nil }
        return cities
            .filter { city in [city.name, city.nameEn].compactMap { $0 }.map(LocationMatcher.normalize).contains(key) }
            .min(by: idOrder)
    }

    // MARK: - District level

    /// Best district for an abroad place, or nil when there is no confident match.
    ///
    /// 1. Exact: locality, then sub-administrative area, then sub-locality, against the full name and the
    ///    text before "(" of `name` and `nameEn`.
    /// 2. Token prefix: the district name STARTS with the candidate's words ("BANDUNG (JAWA BARAT)" for
    ///    "Bandung"), candidate of 4+ letters, and only when exactly one district qualifies.
    /// 3. Last: the administrative area exactly (a town with no entry of its own gets its province's
    ///    namesake, as the Türkiye matcher does with metropolitan centres).
    /// Text inside "( )" is never matched alone: it is sometimes the real name ("SARAYBOSNA(sarajevo)",
    /// already covered by `nameEn`) and sometimes only a nearby city ("DORFEN (Munih)").
    static func matchDistrict(_ place: Place, in districts: [District]) -> District? {
        let iso = place.isoCountryCode?.uppercased() ?? ""
        let candidates = [place.locality, place.subAdministrativeArea, place.subLocality]
            .compactMap { $0 }
            .map { candidateTokens($0, iso: iso) }
            .filter { !$0.isEmpty }
        let indexed = districts.map { (district: $0, keys: districtTokens($0)) }

        for tokens in candidates {
            let key = tokens.joined()
            let hits = indexed.filter { $0.keys.contains { $0.joined() == key } }.map(\.district)
            if let best = hits.min(by: idOrder) { return best }
        }
        for tokens in candidates where tokens.joined().count >= 4 {
            let hits = indexed.filter { entry in
                entry.keys.contains { $0.count > tokens.count && Array($0.prefix(tokens.count)) == tokens }
            }.map(\.district)
            if Set(hits.map(\.id)).count == 1 { return hits[0] }
        }
        if let area = place.administrativeArea {
            let key = candidateTokens(area, iso: iso).joined()
            if !key.isEmpty, let best = indexed.filter({ $0.keys.contains { $0.joined() == key } })
                .map(\.district).min(by: idOrder) {
                return best
            }
        }
        return nil
    }

    // MARK: - Keys

    /// Words of a geocoded name, folded, without administrative words ("Jeddah Governorate" → ["jeddah"]),
    /// then mapped through the verified alias table ("Munich" → ["munchen"]).
    static func candidateTokens(_ raw: String, iso: String) -> [String] {
        let words = tokens(raw).filter { !adminWords.contains($0) }
        let joined = words.joined()
        if let alias = cityAliases[joined] { return [alias] }
        return words
    }

    /// Token lists a district answers to: full name and the text before "(", for `name` and `nameEn`.
    static func districtTokens(_ district: District) -> [[String]] {
        var keys: [[String]] = []
        for raw in [district.name, district.nameEn].compactMap({ $0 }) {
            var forms = [tokens(raw)]
            if let open = raw.firstIndex(of: "(") { forms.append(tokens(String(raw[..<open]))) }
            for form in forms where !form.isEmpty && !keys.contains(form) { keys.append(form) }
        }
        return keys
    }

    /// Folded words: split on anything that is not a letter or digit, then `LocationMatcher.normalize`.
    static func tokens(_ raw: String) -> [String] {
        raw.components(separatedBy: CharacterSet.alphanumerics.inverted)
            .map(LocationMatcher.normalize)
            .filter { !$0.isEmpty }
    }

    /// Same key, two ids (e.g. "SAINT AVOLD" and "SAINT-AVOLD"): the lower numeric id wins, so the
    /// result does not depend on the API's list order.
    private static func idOrder<P: NamedPlace>(_ a: P, _ b: P) -> Bool {
        (Int(a.id) ?? .max, a.id) < (Int(b.id) ?? .max, b.id)
    }

    /// Words geocoders add to administrative names (en/tr/ar transliterations seen in CLGeocoder output).
    static let adminWords: Set<String> = [
        "governorate", "province", "region", "district", "municipality", "county", "prefecture",
        "muhafazah", "eyaleti",
    ]

    /// Geocoder exonym → catalog key. Each row was checked against the live /ilceler data (2026-10-30).
    static let cityAliases: [String: String] = [
        "munich": "munchen", "nuremberg": "nurnberg", "cologne": "koln", "vienna": "wien",
        "makkah": "mecca", "makkahalmukarramah": "mecca", "almukarramah": "mecca",
        "madinah": "medina", "almadinah": "medina", "almadinahalmunawwarah": "medina",
        "dammam": "addammam", "hofuf": "alhufuf",
    ]

    /// Per-country state aliases: geocoder abbreviations (Apple returns "CA", "ON") and English names that
    /// differ from the catalog's spelling ("ONTORIO", "BRITISH COLOMBIA", "N.A.L.", "HAVAI ADALARI").
    static let stateAliases: [String: [String: String]] = [
        "US": [
            "al": "alabama", "ak": "alaska", "az": "arizona", "ar": "arkansas", "ca": "california",
            "co": "colorado", "ct": "connecticut", "dc": "dc", "districtofcolumbia": "dc", "de": "delaware",
            "fl": "florida", "ga": "georgia", "hi": "havaiadalari", "hawaii": "havaiadalari", "id": "idaho",
            "il": "illinois", "in": "indiana", "ia": "iowa", "ks": "kansas", "ky": "kentucky",
            "la": "louisiana", "me": "maine", "md": "maryland", "ma": "massachusetts", "mi": "michigan",
            "mn": "minnesota", "ms": "mississippi", "mo": "missouri", "mt": "montana", "ne": "nebraska",
            "nv": "nevada", "nh": "newhampshire", "nj": "newjersey", "nm": "newmexico", "ny": "newyork",
            "nc": "northcarolina", "nd": "northdakota", "oh": "ohio", "ok": "oklahoma", "or": "oregon",
            "pa": "pennsylvania", "ri": "rhodeisland", "sc": "southcarolina", "sd": "southdakota",
            "tn": "tennessee", "tx": "texas", "ut": "utah", "vt": "vermont", "va": "virginia",
            "wa": "washington", "wv": "westvirginia", "wi": "wisconsin", "wy": "wyoming",
        ],
        "CA": [
            "ab": "alberta", "bc": "britishcolombia", "britishcolumbia": "britishcolombia", "mb": "manitoba",
            "nl": "nal", "newfoundlandandlabrador": "nal", "nb": "newbrunswick", "nt": "northwestterritories",
            "ns": "novascotia", "nu": "nunavut", "on": "ontorio", "ontario": "ontorio", "pe": "pei",
            "princeedwardisland": "pei", "qc": "quebec", "sk": "saskatchewan",
        ],
        "DE": [
            "northrhinewestphalia": "nordrheinwestfalen", "thuringia": "thuringen",
            "saxonyanhalt": "sachsenanhalt", "mecklenburgwesternpomerania": "mecklenburgvorpommern",
        ],
    ]
}

extension CountryCodes {
    /// EzanVakti country id → ISO code, the reverse of `ezanVaktiCountryId` (ids are unique in the table).
    static func isoCode(forCountryId id: String) -> String? {
        ezanVaktiCountryId.first { $0.value == id }?.key
    }
}
