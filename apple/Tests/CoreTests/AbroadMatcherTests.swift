import XCTest

/// Runs the shared golden corpus (`shared/golden/abroad-matching.json`, also run by the Kotlin suite)
/// plus the cases that only make sense on one side.
final class AbroadMatcherTests: XCTestCase {

    private struct Corpus: Decodable { let cases: [Case] }
    private struct Case: Decodable {
        let name: String
        let place: PlaceJSON
        let cities: [PlaceRow]
        let districts: [PlaceRow]
        let expectedCityId: String?
        let expectedDistrictId: String?
    }
    private struct PlaceJSON: Decodable {
        let isoCountryCode, administrativeArea, subAdministrativeArea, locality, subLocality: String?
    }
    private struct PlaceRow: Decodable { let id: String; let name: String; let nameEn: String? }

    private func loadCorpus() throws -> Corpus {
        // Tests/CoreTests/<this file> → repo root → shared/golden/…
        let url = URL(filePath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent()
            .appending(path: "shared/golden/abroad-matching.json")
        return try JSONDecoder().decode(Corpus.self, from: Data(contentsOf: url))
    }

    func testGoldenCorpus() throws {
        let corpus = try loadCorpus()
        XCTAssertGreaterThanOrEqual(corpus.cases.count, 16)
        for c in corpus.cases {
            let place = AbroadMatcher.Place(
                isoCountryCode: c.place.isoCountryCode, administrativeArea: c.place.administrativeArea,
                subAdministrativeArea: c.place.subAdministrativeArea, locality: c.place.locality,
                subLocality: c.place.subLocality)
            let cities = c.cities.map { City(id: $0.id, name: $0.name, nameEn: $0.nameEn) }
            let city = AbroadMatcher.matchCity(place, in: cities)
            XCTAssertEqual(city?.id, c.expectedCityId, "city: \(c.name)")
            guard city != nil else { continue }
            let districts = c.districts.map { District(id: $0.id, name: $0.name, nameEn: $0.nameEn) }
            XCTAssertEqual(AbroadMatcher.matchDistrict(place, in: districts)?.id, c.expectedDistrictId, "district: \(c.name)")
        }
    }

    func testDistrictKeysIgnoreTextInsideParentheses() {
        let dorfen = District(id: "1", name: "DORFEN (Munih)", nameEn: "DORFEN (Munih)")
        XCTAssertEqual(AbroadMatcher.districtTokens(dorfen), [["dorfen", "munih"], ["dorfen"]])
        let place = AbroadMatcher.Place(isoCountryCode: "DE", locality: "Munih")
        XCTAssertNil(AbroadMatcher.matchDistrict(place, in: [dorfen]))
    }

    func testAdministrativeWordsAreDropped() {
        XCTAssertEqual(AbroadMatcher.candidateTokens("Jeddah Governorate", iso: "SA"), ["jeddah"])
        XCTAssertEqual(AbroadMatcher.candidateTokens("Mexico City", iso: "MX"), ["mexico", "city"])
    }

    func testCountryCodes() {
        XCTAssertEqual(CountryCodes.ezanVaktiCountryId["TR"], "2")
        XCTAssertEqual(CountryCodes.ezanVaktiCountryId["SA"], "64")
        XCTAssertEqual(CountryCodes.ezanVaktiCountryId["BA"], "9")
        // No guess where one code covers two EzanVakti countries (Northern Cyprus, Crimea, Chechnya).
        XCTAssertNil(CountryCodes.ezanVaktiCountryId["CY"])
        XCTAssertEqual(CountryCodes.isoCode(forCountryId: "64"), "SA")
        // Ids are unique, so the reverse lookup is well defined.
        let ids = Array(CountryCodes.ezanVaktiCountryId.values)
        XCTAssertEqual(ids.count, Set(ids).count)
    }
}
