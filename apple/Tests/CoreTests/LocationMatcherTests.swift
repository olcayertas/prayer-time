import XCTest

final class LocationMatcherTests: XCTestCase {

    // MARK: normalize — the Turkish casing/diacritic folding

    func testNormalizeFoldsTurkishCasingAndDiacritics() {
        // EzanVakti ALL-CAPS vs CLGeocoder mixed-case must fold to the same key.
        XCTAssertEqual(LocationMatcher.normalize("İstanbul"), LocationMatcher.normalize("İSTANBUL"))
        XCTAssertEqual(LocationMatcher.normalize("İSTANBUL"), "istanbul")
        XCTAssertEqual(LocationMatcher.normalize("Küçükçekmece"), LocationMatcher.normalize("KÜÇÜKÇEKMECE"))
        XCTAssertEqual(LocationMatcher.normalize("KÜÇÜKÇEKMECE"), "kucukcekmece")
    }

    func testNormalizeHandlesDotlessIAndPunctuation() {
        // Dotless ı (geocoder) vs dotless capital I (EzanVakti caps) must agree.
        XCTAssertEqual(LocationMatcher.normalize("Şırnak"), LocationMatcher.normalize("ŞIRNAK"))
        // Spaces / hyphens are stripped.
        XCTAssertEqual(LocationMatcher.normalize("  Çekme-köy "), "cekmekoy")
    }

    // MARK: matchCity (province → il)

    func testMatchCityDottedI() {
        let cities = [City(id: "539", name: "İSTANBUL"), City(id: "506", name: "ANKARA")]
        XCTAssertEqual(LocationMatcher.matchCity(province: "İstanbul", in: cities)?.id, "539")
        XCTAssertNil(LocationMatcher.matchCity(province: "Konya", in: cities))
        XCTAssertNil(LocationMatcher.matchCity(province: nil, in: cities))
    }

    // MARK: bestMatch (district → ilçe)

    func testBestMatchExactIlce() {
        let districts = [District(id: "9543", name: "KÜÇÜKÇEKMECE"),
                         District(id: "9540", name: "ÇEKMEKÖY")]
        let m = LocationMatcher.bestMatch(province: "İstanbul", district: "Küçükçekmece",
                                          districts: districts)
        XCTAssertEqual(m?.id, "9543")
    }

    func testNearMissDoesNotMatch() {
        // A different ilçe must NOT collapse onto Küçükçekmece (and there's no İstanbul-named entry).
        let districts = [District(id: "9543", name: "KÜÇÜKÇEKMECE")]
        let m = LocationMatcher.bestMatch(province: "İstanbul", district: "Çekmeköy",
                                          districts: districts)
        XCTAssertNil(m)
    }

    func testMetropolitanCenterFallback() {
        // Diyanet's Ankara list collapses central ilçe into a single "ANKARA" entry, so Çankaya
        // (geocoded, ASCII "Cankaya") must resolve to "ANKARA" via the province-name fallback.
        let districts = [District(id: "9206", name: "ANKARA"),
                         District(id: "9211", name: "CUBUK"),
                         District(id: "9220", name: "POLATLI")]
        XCTAssertEqual(LocationMatcher.bestMatch(province: "Ankara", district: "Cankaya",
                                                 districts: districts)?.id, "9206")
        // A peripheral ilçe that IS listed still matches exactly.
        XCTAssertEqual(LocationMatcher.bestMatch(province: "Ankara", district: "Polatlı",
                                                 districts: districts)?.id, "9220")
    }

    func testBestMatchNilDistrictNoCenterReturnsNil() {
        let districts = [District(id: "9543", name: "KÜÇÜKÇEKMECE")]
        XCTAssertNil(LocationMatcher.bestMatch(province: "İstanbul", district: nil,
                                               districts: districts))
    }
}
