import XCTest

final class SearchMatchingTests: XCTestCase {

    /// Helper mirroring the picker sheet's match: both sides folded, then `contains`.
    private func matches(_ query: String, _ name: String) -> Bool {
        name.foldedForSearch().contains(query.foldedForSearch())
    }

    func testTurkishDottedICaseFold() {
        // The reported bug: lowercase ASCII "istanbul" should match "İSTANBUL".
        XCTAssertTrue(matches("istanbul", "İSTANBUL"))
        XCTAssertTrue(matches("İstanbul", "İSTANBUL"))
        XCTAssertTrue(matches("ISTANBUL", "İstanbul"))
    }

    func testDiacriticInsensitive() {
        XCTAssertTrue(matches("sanliurfa", "ŞANLIURFA"))
        XCTAssertTrue(matches("kucukcekmece", "KÜÇÜKÇEKMECE"))
        XCTAssertTrue(matches("gumushane", "GÜMÜŞHANE"))
    }

    func testSubstringMatch() {
        XCTAssertTrue(matches("stan", "İSTANBUL"))
        XCTAssertTrue(matches("çek", "Küçükçekmece"))
    }

    func testNonMatch() {
        XCTAssertFalse(matches("ankara", "İSTANBUL"))
    }
}
