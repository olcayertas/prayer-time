import Foundation

/// A named entry in the place hierarchy (country / city / district), identified by a
/// `String` id — lets the picker sheet sort, filter, and select any of them generically.
protocol NamedPlace: Identifiable, Hashable, Sendable where ID == String {
    var name: String { get }
}

/// A country in the EzanVakti hierarchy (`/ulkeler`). Türkiye is id `"2"`.
struct Country: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    /// English (or local ASCII) name from `UlkeAdiEn`. Optional, so a response without it still decodes.
    var nameEn: String? = nil

    enum CodingKeys: String, CodingKey {
        case id = "UlkeID"
        case name = "UlkeAdi"
        case nameEn = "UlkeAdiEn"
    }
}

/// A city/province (`/sehirler/{countryId}`). İstanbul is id `"539"`.
struct City: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    /// English (or local ASCII) name from `SehirAdiEn`. Optional, so a response without it still decodes.
    var nameEn: String? = nil

    enum CodingKeys: String, CodingKey {
        case id = "SehirID"
        case name = "SehirAdi"
        case nameEn = "SehirAdiEn"
    }
}

/// A district (`/ilceler/{cityId}`). The `id` is exactly the `/vakitler/{id}` district id
/// (e.g. Küçükçekmece = `"9543"`).
struct District: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    /// English (or local ASCII) name from `IlceAdiEn`. Optional, so a response without it still decodes.
    var nameEn: String? = nil

    enum CodingKeys: String, CodingKey {
        case id = "IlceID"
        case name = "IlceAdi"
        case nameEn = "IlceAdiEn"
    }
}

extension Country: NamedPlace {}
extension City: NamedPlace {}
extension District: NamedPlace {}

extension String {
    /// Case- and diacritic-insensitive normalization for search matching. Folding
    /// (rather than `localizedCaseInsensitive…`) makes matching robust across the
    /// Turkish dotted/dotless-I casing and accents, so "istanbul" matches "İSTANBUL"
    /// and "sanliurfa" matches "ŞANLIURFA". Locale `nil` keeps it deterministic.
    func foldedForSearch() -> String {
        folding(options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive],
                locale: nil)
    }
}
