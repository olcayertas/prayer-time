import XCTest

final class PrayerCalculatorTests: XCTestCase {

    /// Mecca, 30 Oct 2026 (19 Jumada I 1448), official Umm al-Qura calendar, ummulqura.org.sa (KACST):
    /// Fajr 05:06, Sunrise 06:22, Dhuhr 12:05, Asr 15:21, Maghrib 17:46, Isha 19:16.
    func testUmmAlQuraMatchesOfficialMeccaTable() {
        let day = PrayerDay(
            imsak: "05:08", gunes: "06:16", ogle: "12:09", ikindi: "15:25", aksam: "17:53", yatsi: "18:57",
            hicriTarihKisa: "19.5.1448", miladiTarihKisa: "30.10.2026",
            miladiTarihUzunIso8601: "2026-10-30T00:00:00.0000000+03:00")
        let local = LocalMethod.ummAlQura.apply(to: day, latitude: 21.4225, longitude: 39.8262)
        XCTAssertEqual(Prayer.allCases.map(local.time(for:)), ["05:06", "06:22", "12:05", "15:21", "17:46", "19:16"])
        // Dates and Hijri stay Diyanet's.
        XCTAssertEqual(local.hicriTarihKisa, "19.5.1448")
        XCTAssertEqual(local.miladiTarihKisa, "30.10.2026")
    }

    func testUmmAlQuraRamadanIshaIs120MinutesAfterMaghrib() {
        let normal = PrayerDay(imsak: "", gunes: "", ogle: "", ikindi: "", aksam: "", yatsi: "",
                               hicriTarihKisa: "19.5.1448", miladiTarihKisa: "30.10.2026",
                               miladiTarihUzunIso8601: "2026-10-30T00:00:00.0000000+03:00")
        let ramadan = PrayerDay(imsak: "", gunes: "", ogle: "", ikindi: "", aksam: "", yatsi: "",
                                hicriTarihKisa: "19.9.1448", miladiTarihKisa: "30.10.2026",
                                miladiTarihUzunIso8601: "2026-10-30T00:00:00.0000000+03:00")
        let a = LocalMethod.ummAlQura.apply(to: normal, latitude: 21.4225, longitude: 39.8262)
        let b = LocalMethod.ummAlQura.apply(to: ramadan, latitude: 21.4225, longitude: 39.8262)
        XCTAssertEqual(a.yatsi, "19:16")
        XCTAssertEqual(b.yatsi, "19:46")
        XCTAssertEqual(a.aksam, b.aksam)
    }

    func testDayWithoutOffsetIsUnchanged() {
        let day = PrayerDay(imsak: "05:08", gunes: "06:16", ogle: "12:09", ikindi: "15:25", aksam: "17:53",
                            yatsi: "18:57", miladiTarihKisa: "30.10.2026")
        XCTAssertEqual(LocalMethod.ummAlQura.apply(to: day, latitude: 21.4, longitude: 39.8), day)
    }

    func testEffectiveTimesNeedsLocalMethodAndCoordinates() {
        let day = PrayerDay(imsak: "05:08", gunes: "06:16", ogle: "12:09", ikindi: "15:25", aksam: "17:53",
                            yatsi: "18:57", hicriTarihKisa: "19.5.1448", miladiTarihKisa: "30.10.2026",
                            miladiTarihUzunIso8601: "2026-10-30T00:00:00.0000000+03:00")
        let mecca = PlaceContext(isoCountryCode: "SA", latitude: 21.4225, longitude: 39.8262)
        XCTAssertEqual(EffectiveTimes.days([day], method: .diyanet, place: mecca), [day])
        XCTAssertEqual(EffectiveTimes.days([day], method: .local, place: mecca).first?.imsak, "05:06")
        // No local method for Türkiye or Bosnia; no coordinates → Diyanet.
        XCTAssertEqual(EffectiveTimes.days([day], method: .local, place: .init(isoCountryCode: "BA", latitude: 43.8, longitude: 18.4)), [day])
        XCTAssertEqual(EffectiveTimes.days([day], method: .local, place: .init(isoCountryCode: "SA")), [day])
    }

    func testHHmmRounding() {
        XCTAssertEqual(PrayerCalculator.hhmm(5 + 5.0 / 60 + 17.0 / 3600, roundUp: true), "05:06")
        XCTAssertEqual(PrayerCalculator.hhmm(6 + 22.0 / 60 + 43.0 / 3600, roundUp: false), "06:22")
        XCTAssertEqual(PrayerCalculator.hhmm(17 + 45.0 / 60, roundUp: true), "17:45") // exact minute stays
    }
}
