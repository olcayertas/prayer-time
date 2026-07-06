import XCTest

/// The cache-freshness predicate `PrayerStore` uses (`schedule.day(on: Date()) != nil`) — verified
/// directly against `PrayerSchedule`, which is pure. A cached month is "fresh" only while it still
/// contains today's Istanbul date, so it correctly goes stale across a month boundary.
final class CacheFreshnessTests: XCTestCase {

    private func istanbul(_ y: Int, _ mo: Int, _ d: Int) -> Date {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Europe/Istanbul")!
        return cal.date(from: DateComponents(year: y, month: mo, day: d, hour: 12))!
    }

    private func day(_ ddMMyyyy: String) -> PrayerDay {
        PrayerDay(imsak: "03:27", gunes: "05:26", ogle: "13:09",
                  ikindi: "17:08", aksam: "20:42", yatsi: "22:31", miladiTarihKisa: ddMMyyyy)
    }

    func testTodayInCacheIsFresh() {
        let schedule = PrayerSchedule(days: [day("16.06.2026"), day("17.06.2026")])
        XCTAssertNotNil(schedule.day(on: istanbul(2026, 6, 17)))
    }

    func testOldMonthIsStale() {
        let schedule = PrayerSchedule(days: [day("16.07.2026"), day("17.07.2026")])
        XCTAssertNil(schedule.day(on: istanbul(2026, 8, 1)))
    }

    func testEmptyCacheIsStale() {
        XCTAssertNil(PrayerSchedule(days: []).day(on: istanbul(2026, 6, 17)))
    }
}
