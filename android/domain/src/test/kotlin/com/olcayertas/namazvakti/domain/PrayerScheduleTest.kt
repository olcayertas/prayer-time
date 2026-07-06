package com.olcayertas.namazvakti.domain

import java.time.Instant
import java.time.LocalDateTime
import java.time.ZoneId
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

/** Ported verbatim from the Swift `PrayerScheduleTests`. Pins Istanbul-tz math, the strict-`>` /
 *  inclusive-`<=` split, and the midnight roll. */
class PrayerScheduleTest {

    private val day1 = PrayerDay(
        imsak = "03:27", gunes = "05:26", ogle = "13:09",
        ikindi = "17:08", aksam = "20:42", yatsi = "22:31",
        miladiTarihKisa = "08.06.2026",
    )
    private val day2 = PrayerDay(
        imsak = "03:27", gunes = "05:27", ogle = "13:09",
        ikindi = "17:09", aksam = "20:43", yatsi = "22:32",
        miladiTarihKisa = "09.06.2026",
    )
    private val schedule get() = PrayerSchedule(listOf(day1, day2))

    private fun istanbul(y: Int, mo: Int, d: Int, h: Int = 0, mi: Int = 0): Instant =
        LocalDateTime.of(y, mo, d, h, mi).atZone(ZoneId.of("Europe/Istanbul")).toInstant()

    @Test fun nextPrayerBetweenOgleAndIkindi() {
        val now = istanbul(2026, 6, 8, 14, 0) // after Öğle 13:09, before İkindi 17:08
        val upcoming = schedule.upcoming(now)
        assertEquals(Prayer.IKINDI, upcoming?.prayer)
        assertEquals(istanbul(2026, 6, 8, 17, 8), upcoming?.instant)
        assertEquals(3 * 3600 + 8 * 60L, upcoming?.remaining?.seconds)
        assertEquals(Prayer.OGLE, schedule.current(now))
    }

    @Test fun beforeImsakUsesPreviousDayYatsiAsCurrent() {
        val now = istanbul(2026, 6, 9, 2, 0) // early on day2, before its İmsak
        val upcoming = schedule.upcoming(now)
        assertEquals(Prayer.IMSAK, upcoming?.prayer)
        assertEquals(istanbul(2026, 6, 9, 3, 27), upcoming?.instant)
        assertEquals(Prayer.YATSI, schedule.current(now)) // previous day's Yatsı
    }

    @Test fun afterYatsiRollsToTomorrowImsak() {
        val now = istanbul(2026, 6, 8, 23, 0) // after day1 Yatsı 22:31
        val upcoming = schedule.upcoming(now)
        assertEquals(Prayer.IMSAK, upcoming?.prayer)
        assertEquals(istanbul(2026, 6, 9, 3, 27), upcoming?.instant) // tomorrow
        assertEquals(Prayer.YATSI, schedule.current(now))
    }

    @Test fun boundaryStrictAfterForUpcomingInclusiveForCurrent() {
        val now = istanbul(2026, 6, 8, 13, 9) // exactly Öğle
        assertEquals(Prayer.IKINDI, schedule.upcoming(now)?.prayer)
        assertEquals(Prayer.OGLE, schedule.current(now))
    }

    @Test fun instantForPrayerBuildsIstanbulInstant() {
        assertEquals(istanbul(2026, 6, 8, 17, 8), schedule.instant(Prayer.IKINDI, day1))
    }

    @Test fun upcomingReturnsNullWhenMonthExhausted() {
        assertNull(schedule.upcoming(istanbul(2026, 6, 9, 23, 0))) // after the last loaded time
    }

    @Test fun upcomingTimesExcludesGunesAndCaps() {
        val now = istanbul(2026, 6, 8, 0, 0) // start of day1
        val ups = schedule.upcomingTimes(now, limit = 4)
        // imsak 03:27, [gunes 05:26 excluded], ogle 13:09, ikindi 17:08, aksam 20:42 → first 4 non-Güneş
        assertEquals(listOf(Prayer.IMSAK, Prayer.OGLE, Prayer.IKINDI, Prayer.AKSAM), ups.map { it.first })
    }

    @Test fun parseHelpers() {
        assertEquals(6, PrayerSchedule.parseDate("08.06.2026")?.month)
        assertEquals(8, PrayerSchedule.parseDate("08.06.2026")?.day)
        assertNull(PrayerSchedule.parseDate("nonsense"))
        assertEquals(17, PrayerSchedule.parseTime(" 17:08 ")?.hour)
        assertEquals(8, PrayerSchedule.parseTime("17:08")?.minute)
        assertNull(PrayerSchedule.parseTime("17"))
    }
}
