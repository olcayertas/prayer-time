package com.olcayertas.namazvakti.domain

import kotlin.test.Test
import kotlin.test.assertEquals

class PrayerCalculatorTest {

    private fun mecca(hijri: String = "19.5.1448") = PrayerDay(
        imsak = "05:08", gunes = "06:16", ogle = "12:09", ikindi = "15:25", aksam = "17:53", yatsi = "18:57",
        hicriTarihKisa = hijri, miladiTarihKisa = "30.10.2026",
        miladiTarihUzunIso8601 = "2026-10-30T00:00:00.0000000+03:00",
    )

    /**
     * Mecca, 30 Oct 2026 (19 Jumada I 1448), official Umm al-Qura calendar, ummulqura.org.sa (KACST):
     * Fajr 05:06, Sunrise 06:22, Dhuhr 12:05, Asr 15:21, Maghrib 17:46, Isha 19:16.
     */
    @Test fun ummAlQuraMatchesOfficialMeccaTable() {
        val local = LocalMethod.UMM_AL_QURA.apply(mecca(), 21.4225, 39.8262)
        assertEquals(listOf("05:06", "06:22", "12:05", "15:21", "17:46", "19:16"), Prayer.entries.map(local::time))
        assertEquals("19.5.1448", local.hicriTarihKisa)
    }

    @Test fun ramadanIshaIs120MinutesAfterMaghrib() {
        assertEquals("19:46", LocalMethod.UMM_AL_QURA.apply(mecca("19.9.1448"), 21.4225, 39.8262).yatsi)
    }

    @Test fun effectiveTimesNeedsLocalMethodAndCoordinates() {
        val day = mecca()
        val place = PlaceContext("SA", 21.4225, 39.8262)
        assertEquals(listOf(day), EffectiveTimes.days(listOf(day), CalculationMethod.DIYANET, place))
        assertEquals("05:06", EffectiveTimes.days(listOf(day), CalculationMethod.LOCAL, place).first().imsak)
        assertEquals(listOf(day), EffectiveTimes.days(listOf(day), CalculationMethod.LOCAL, PlaceContext("BA", 43.8, 18.4)))
        assertEquals(listOf(day), EffectiveTimes.days(listOf(day), CalculationMethod.LOCAL, PlaceContext("SA")))
    }

    @Test fun hhmmRounding() {
        assertEquals("05:06", PrayerCalculator.hhmm(5 + 5.0 / 60 + 17.0 / 3600, roundUp = true))
        assertEquals("06:22", PrayerCalculator.hhmm(6 + 22.0 / 60 + 43.0 / 3600, roundUp = false))
        assertEquals("17:45", PrayerCalculator.hhmm(17 + 45.0 / 60, roundUp = true))
    }
}
