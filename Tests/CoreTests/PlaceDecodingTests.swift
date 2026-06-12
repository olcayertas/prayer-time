import XCTest

final class PlaceDecodingTests: XCTestCase {

    func testDecodesCountries() throws {
        let json = """
        [{"UlkeAdi":"TURKIYE","UlkeAdiEn":"TURKEY","UlkeID":"2"}]
        """
        let list = try JSONDecoder().decode([Country].self, from: Data(json.utf8))
        XCTAssertEqual(list.first?.id, "2")
        XCTAssertEqual(list.first?.name, "TURKIYE")
    }

    func testDecodesCities() throws {
        let json = """
        [{"SehirAdi":"İSTANBUL","SehirAdiEn":"ISTANBUL","SehirID":"539"}]
        """
        let list = try JSONDecoder().decode([City].self, from: Data(json.utf8))
        XCTAssertEqual(list.first?.id, "539")
        XCTAssertEqual(list.first?.name, "İSTANBUL")
    }

    func testDecodesDistrictsAndIdMatchesVakitlerId() throws {
        let json = """
        [{"IlceAdi":"KÜÇÜKÇEKMECE","IlceAdiEn":"KUCUKCEKMECE","IlceID":"9543"}]
        """
        let list = try JSONDecoder().decode([District].self, from: Data(json.utf8))
        // The district id is exactly the id used for /vakitler/{id}.
        XCTAssertEqual(list.first?.id, "9543")
        XCTAssertEqual(list.first?.name, "KÜÇÜKÇEKMECE")
    }
}
