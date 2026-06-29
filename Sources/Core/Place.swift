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

    enum CodingKeys: String, CodingKey {
        case id = "UlkeID"
        case name = "UlkeAdi"
    }
}

/// A city/province (`/sehirler/{countryId}`). İstanbul is id `"539"`.
struct City: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let name: String

    enum CodingKeys: String, CodingKey {
        case id = "SehirID"
        case name = "SehirAdi"
    }
}

/// A district (`/ilceler/{cityId}`). The `id` is exactly the `/vakitler/{id}` district id
/// (e.g. Küçükçekmece = `"9543"`).
struct District: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let name: String

    enum CodingKeys: String, CodingKey {
        case id = "IlceID"
        case name = "IlceAdi"
    }
}

extension Country: NamedPlace {}
extension City: NamedPlace {}
extension District: NamedPlace {}
