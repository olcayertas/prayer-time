import XCTest

final class PrayerDayDecodingTests: XCTestCase {

    /// A real EzanVakti day object, including keys the app does not model
    /// (null ISO fields, moon-phase URL, GMT offset) to prove decoding is resilient.
    private let sampleJSON = """
    [
      {
        "HicriTarihKisa": "22.12.1447",
        "HicriTarihKisaIso8601": null,
        "HicriTarihUzun": "22 Zilhicce 1447",
        "HicriTarihUzunIso8601": null,
        "AyinSekliURL": "https://namazvakti.diyanet.gov.tr/images/sondordun.gif",
        "MiladiTarihKisa": "08.06.2026",
        "MiladiTarihKisaIso8601": "08.06.2026",
        "MiladiTarihUzun": "08 Haziran 2026 Pazartesi",
        "MiladiTarihUzunIso8601": "2026-06-08T00:00:00.0000000+03:00",
        "GreenwichOrtalamaZamani": 3.0,
        "Aksam": "20:42",
        "Gunes": "05:26",
        "GunesBatis": "20:35",
        "GunesDogus": "05:33",
        "Ikindi": "17:08",
        "Imsak": "03:27",
        "KibleSaati": "12:22",
        "Ogle": "13:09",
        "Yatsi": "22:31"
      }
    ]
    """

    func testDecodesMonthlyArray() throws {
        let days = try JSONDecoder().decode([PrayerDay].self, from: Data(sampleJSON.utf8))
        XCTAssertEqual(days.count, 1)
        let day = try XCTUnwrap(days.first)

        XCTAssertEqual(day.imsak, "03:27")
        XCTAssertEqual(day.gunes, "05:26")
        XCTAssertEqual(day.ogle, "13:09")
        XCTAssertEqual(day.ikindi, "17:08")
        XCTAssertEqual(day.aksam, "20:42")
        XCTAssertEqual(day.yatsi, "22:31")

        XCTAssertEqual(day.gunesDogus, "05:33")
        XCTAssertEqual(day.gunesBatis, "20:35")
        XCTAssertEqual(day.kibleSaati, "12:22")
        XCTAssertEqual(day.miladiTarihKisa, "08.06.2026")
        XCTAssertEqual(day.hicriTarihUzun, "22 Zilhicce 1447")
    }

    func testTimeForPrayerAccessor() throws {
        let day = try XCTUnwrap(
            try JSONDecoder().decode([PrayerDay].self, from: Data(sampleJSON.utf8)).first
        )
        XCTAssertEqual(day.time(for: .imsak), "03:27")
        XCTAssertEqual(day.time(for: .yatsi), "22:31")
    }
}
