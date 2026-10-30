import XCTest

final class PrayerDayZoneTests: XCTestCase {

    private func day(_ iso: String?) -> PrayerDay {
        PrayerDay(imsak: "04:38", gunes: "06:07", ogle: "11:35", ikindi: "14:24", aksam: "16:54", yatsi: "18:12",
                  miladiTarihKisa: "26.10.2026", miladiTarihUzunIso8601: iso)
    }

    func testOffsetParsing() {
        XCTAssertEqual(day("2026-10-26T00:00:00.0000000+01:00").utcOffsetSeconds, 3600)
        XCTAssertEqual(day("2026-10-26T00:00:00.0000000+03:00").utcOffsetSeconds, 10800)
        XCTAssertEqual(day("2026-10-26T00:00:00.0000000-05:30").utcOffsetSeconds, -19800)
        XCTAssertEqual(day("2026-10-26T00:00:00Z").utcOffsetSeconds, 0)
        XCTAssertNil(day(nil).utcOffsetSeconds)
        XCTAssertNil(day("garbage").utcOffsetSeconds)
    }

    /// Sarajevo publishes CET clock times: Akşam 16:54 at +01:00 is 15:54 UTC, not 13:54 (Istanbul).
    func testScheduleUsesTheDaysOwnOffset() {
        let schedule = PrayerSchedule(days: [day("2026-10-26T00:00:00.0000000+01:00")])
        let aksam = schedule.date(for: .aksam, on: schedule.days[0])
        XCTAssertEqual(aksam, ISO8601DateFormatter().date(from: "2026-10-26T15:54:00Z"))
        XCTAssertEqual(schedule.timeZone.secondsFromGMT(), 3600)
    }

    /// A month cached by an older version has no offset: keep the old Europe/Istanbul behaviour.
    func testScheduleFallsBackToIstanbulWithoutOffset() {
        let schedule = PrayerSchedule(days: [day(nil)])
        let aksam = schedule.date(for: .aksam, on: schedule.days[0])
        XCTAssertEqual(aksam, ISO8601DateFormatter().date(from: "2026-10-26T13:54:00Z"))
        XCTAssertEqual(schedule.timeZone.identifier, "Europe/Istanbul")
    }

    func testDecodesOffsetAndEnglishNames() throws {
        let json = #"[{"Imsak":"04:38","Gunes":"06:07","Ogle":"11:35","Ikindi":"14:24","Aksam":"16:54","Yatsi":"18:12","MiladiTarihKisa":"26.10.2026","MiladiTarihUzunIso8601":"2026-10-26T00:00:00.0000000+01:00"}]"#
        let days = try JSONDecoder().decode([PrayerDay].self, from: Data(json.utf8))
        XCTAssertEqual(days.first?.utcOffsetSeconds, 3600)

        let withEn = try JSONDecoder().decode([District].self, from: Data(#"[{"IlceAdi":"MEKKE","IlceAdiEn":"MECCA","IlceID":"16309"}]"#.utf8))
        XCTAssertEqual(withEn.first?.nameEn, "MECCA")
        let withoutEn = try JSONDecoder().decode([District].self, from: Data(#"[{"IlceAdi":"MEKKE","IlceID":"16309"}]"#.utf8))
        XCTAssertNil(withoutEn.first?.nameEn)
    }
}
