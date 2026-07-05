package com.olcayertas.namazvakti.domain

import java.time.Instant
import java.time.LocalDateTime
import java.time.ZoneId
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class MonthlyDayBuilderTest {

    private fun istanbul(y: Int, mo: Int, d: Int): Instant =
        LocalDateTime.of(y, mo, d, 12, 0).atZone(ZoneId.of("Europe/Istanbul")).toInstant()

    private fun day(date: String) = PrayerDay(
        imsak = "03:27", gunes = "05:26", ogle = "13:09",
        ikindi = "17:08", aksam = "20:42", yatsi = "22:31", miladiTarihKisa = date,
    )

    @Test fun buildsOnePerDayInOrderWithSixTimes() {
        val schedule = PrayerSchedule(listOf(day("08.06.2026"), day("09.06.2026")))
        val days = MonthlyDayBuilder.build(schedule, istanbul(2026, 6, 8))
        assertEquals(2, days.size)
        assertEquals(listOf(8, 9), days.map { it.dayNumber })
        assertEquals(6, days[0].times.size)
        assertEquals("03:27", days[0].displayTimes[Prayer.IMSAK.ordinal])
    }

    @Test fun marksTodayInIstanbulTime() {
        val schedule = PrayerSchedule(listOf(day("08.06.2026"), day("09.06.2026")))
        val days = MonthlyDayBuilder.build(schedule, istanbul(2026, 6, 9))
        assertFalse(days[0].isToday)
        assertTrue(days[1].isToday)
    }

    @Test fun flagsFriday() {
        // 12.06.2026 is a Friday.
        val days = MonthlyDayBuilder.build(PrayerSchedule(listOf(day("12.06.2026"))), istanbul(2026, 6, 12))
        assertTrue(days[0].isFriday)
    }
}
