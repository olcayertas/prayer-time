import XCTest

final class PrayerScheduleTests: XCTestCase {

    // Two consecutive days (Istanbul times) used across the schedule tests.
    private let day1 = PrayerDay(
        imsak: "03:27", gunes: "05:26", ogle: "13:09",
        ikindi: "17:08", aksam: "20:42", yatsi: "22:31",
        miladiTarihKisa: "08.06.2026"
    )
    private let day2 = PrayerDay(
        imsak: "03:27", gunes: "05:27", ogle: "13:09",
        ikindi: "17:09", aksam: "20:43", yatsi: "22:32",
        miladiTarihKisa: "09.06.2026"
    )

    private var schedule: PrayerSchedule { PrayerSchedule(days: [day1, day2]) }

    /// Builds an unambiguous instant in Europe/Istanbul.
    private func istanbul(_ y: Int, _ mo: Int, _ d: Int, _ h: Int, _ mi: Int) -> Date {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Europe/Istanbul")!
        return cal.date(from: DateComponents(year: y, month: mo, day: d, hour: h, minute: mi))!
    }

    func testNextPrayerBetweenOgleAndIkindi() {
        let now = istanbul(2026, 6, 8, 14, 0) // after Öğle 13:09, before İkindi 17:08
        let upcoming = schedule.upcoming(now: now)
        XCTAssertEqual(upcoming?.prayer, .ikindi)
        XCTAssertEqual(upcoming?.date, istanbul(2026, 6, 8, 17, 8))
        XCTAssertEqual(upcoming?.remaining ?? 0, 3 * 3600 + 8 * 60, accuracy: 0.5)
        XCTAssertEqual(schedule.current(now: now), .ogle)
    }

    func testBeforeImsakUsesPreviousDayYatsiAsCurrent() {
        let now = istanbul(2026, 6, 9, 2, 0) // early on day2, before its İmsak
        let upcoming = schedule.upcoming(now: now)
        XCTAssertEqual(upcoming?.prayer, .imsak)
        XCTAssertEqual(upcoming?.date, istanbul(2026, 6, 9, 3, 27))
        // Current period is the previous day's Yatsı.
        XCTAssertEqual(schedule.current(now: now), .yatsi)
    }

    func testAfterYatsiRollsToTomorrowImsak() {
        let now = istanbul(2026, 6, 8, 23, 0) // after day1 Yatsı 22:31
        let upcoming = schedule.upcoming(now: now)
        XCTAssertEqual(upcoming?.prayer, .imsak)
        XCTAssertEqual(upcoming?.date, istanbul(2026, 6, 9, 3, 27)) // tomorrow
        XCTAssertEqual(schedule.current(now: now), .yatsi)
    }

    func testBoundaryIsStrictlyAfterForUpcomingInclusiveForCurrent() {
        let now = istanbul(2026, 6, 8, 13, 9) // exactly Öğle
        XCTAssertEqual(schedule.upcoming(now: now)?.prayer, .ikindi)
        XCTAssertEqual(schedule.current(now: now), .ogle)
    }

    func testDateForPrayerBuildsIstanbulInstant() {
        let date = schedule.date(for: .ikindi, on: day1)
        XCTAssertEqual(date, istanbul(2026, 6, 8, 17, 8))
    }

    func testUpcomingReturnsNilWhenMonthExhausted() {
        let now = istanbul(2026, 6, 9, 23, 0) // after the last loaded time
        XCTAssertNil(schedule.upcoming(now: now))
    }

    func testParseHelpers() {
        XCTAssertEqual(PrayerSchedule.parseDate("08.06.2026")?.month, 6)
        XCTAssertEqual(PrayerSchedule.parseDate("08.06.2026")?.day, 8)
        XCTAssertNil(PrayerSchedule.parseDate("nonsense"))
        XCTAssertEqual(PrayerSchedule.parseTime(" 17:08 ")?.hour, 17)
        XCTAssertEqual(PrayerSchedule.parseTime("17:08")?.minute, 8)
        XCTAssertNil(PrayerSchedule.parseTime("17"))
    }
}
