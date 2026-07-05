package com.olcayertas.namazvakti.domain

import java.time.Instant
import java.time.LocalDateTime
import java.time.ZoneId
import kotlin.test.Test
import kotlin.test.assertNotNull
import kotlin.test.assertNull

/** Ported from the Swift `CacheFreshnessTests`. A cached month is "fresh" only while it still
 *  contains today's Istanbul date (`schedule.day(now) != null`), so it goes stale across a month
 *  boundary. */
class CacheFreshnessTest {

    private fun istanbul(y: Int, mo: Int, d: Int): Instant =
        LocalDateTime.of(y, mo, d, 12, 0).atZone(ZoneId.of("Europe/Istanbul")).toInstant()

    private fun day(ddMMyyyy: String) = PrayerDay(
        imsak = "03:27", gunes = "05:26", ogle = "13:09",
        ikindi = "17:08", aksam = "20:42", yatsi = "22:31", miladiTarihKisa = ddMMyyyy,
    )

    @Test fun todayInCacheIsFresh() {
        val schedule = PrayerSchedule(listOf(day("16.06.2026"), day("17.06.2026")))
        assertNotNull(schedule.day(istanbul(2026, 6, 17)))
    }

    @Test fun oldMonthIsStale() {
        val schedule = PrayerSchedule(listOf(day("16.07.2026"), day("17.07.2026")))
        assertNull(schedule.day(istanbul(2026, 8, 1)))
    }

    @Test fun emptyCacheIsStale() {
        assertNull(PrayerSchedule(emptyList()).day(istanbul(2026, 6, 17)))
    }
}
