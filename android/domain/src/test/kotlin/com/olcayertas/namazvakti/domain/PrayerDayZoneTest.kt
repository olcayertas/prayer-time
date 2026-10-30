package com.olcayertas.namazvakti.domain

import kotlinx.serialization.decodeFromString
import java.time.Instant
import java.time.ZoneId
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

class PrayerDayZoneTest {

    private fun day(iso: String?) = PrayerDay(
        imsak = "04:38", gunes = "06:07", ogle = "11:35", ikindi = "14:24", aksam = "16:54", yatsi = "18:12",
        miladiTarihKisa = "26.10.2026", miladiTarihUzunIso8601 = iso,
    )

    @Test fun offsetParsing() {
        assertEquals(3600, day("2026-10-26T00:00:00.0000000+01:00").utcOffsetSeconds)
        assertEquals(10800, day("2026-10-26T00:00:00.0000000+03:00").utcOffsetSeconds)
        assertEquals(-19800, day("2026-10-26T00:00:00.0000000-05:30").utcOffsetSeconds)
        assertEquals(0, day("2026-10-26T00:00:00Z").utcOffsetSeconds)
        assertNull(day(null).utcOffsetSeconds)
        assertNull(day("garbage").utcOffsetSeconds)
    }

    /** Sarajevo publishes CET clock times: Akşam 16:54 at +01:00 is 15:54 UTC, not 13:54 (Istanbul). */
    @Test fun scheduleUsesTheDaysOwnOffset() {
        val schedule = PrayerSchedule(listOf(day("2026-10-26T00:00:00.0000000+01:00")))
        assertEquals(Instant.parse("2026-10-26T15:54:00Z"), schedule.instant(Prayer.AKSAM, schedule.days[0]))
    }

    @Test fun scheduleFallsBackToIstanbulWithoutOffset() {
        val schedule = PrayerSchedule(listOf(day(null)))
        assertEquals(Instant.parse("2026-10-26T13:54:00Z"), schedule.instant(Prayer.AKSAM, schedule.days[0]))
        assertEquals(ZoneId.of("Europe/Istanbul"), schedule.zone)
    }

    @Test fun decodesOffsetAndEnglishNames() {
        val days = EzanVaktiJson.decodeFromString<List<PrayerDay>>(
            """[{"Imsak":"04:38","Gunes":"06:07","Ogle":"11:35","Ikindi":"14:24","Aksam":"16:54","Yatsi":"18:12","MiladiTarihKisa":"26.10.2026","MiladiTarihUzunIso8601":"2026-10-26T00:00:00.0000000+01:00"}]""",
        )
        assertEquals(3600, days.first().utcOffsetSeconds)
        assertEquals("MECCA", EzanVaktiJson.decodeFromString<List<District>>("""[{"IlceAdi":"MEKKE","IlceAdiEn":"MECCA","IlceID":"16309"}]""").first().nameEn)
        assertNull(EzanVaktiJson.decodeFromString<List<District>>("""[{"IlceAdi":"MEKKE","IlceID":"16309"}]""").first().nameEn)
    }
}
