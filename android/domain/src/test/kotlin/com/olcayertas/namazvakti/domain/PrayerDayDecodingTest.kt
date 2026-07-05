package com.olcayertas.namazvakti.domain

import kotlinx.serialization.decodeFromString
import kotlin.test.Test
import kotlin.test.assertEquals

/** Ported from the Swift `PrayerDayDecodingTests` — a real EzanVakti day object, including keys the
 *  app doesn't model (null ISO fields, moon-phase URL, GMT offset), to prove decoding is resilient. */
class PrayerDayDecodingTest {

    private val sampleJson = """
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
            "Aksam": "20:42", "Gunes": "05:26", "GunesBatis": "20:35", "GunesDogus": "05:33",
            "Ikindi": "17:08", "Imsak": "03:27", "KibleSaati": "12:22", "Ogle": "13:09", "Yatsi": "22:31"
          }
        ]
    """.trimIndent()

    @Test fun decodesMonthlyArray() {
        val days = EzanVaktiJson.decodeFromString<List<PrayerDay>>(sampleJson)
        assertEquals(1, days.size)
        val day = days.first()
        assertEquals("03:27", day.imsak)
        assertEquals("05:26", day.gunes)
        assertEquals("13:09", day.ogle)
        assertEquals("17:08", day.ikindi)
        assertEquals("20:42", day.aksam)
        assertEquals("22:31", day.yatsi)
        assertEquals("05:33", day.gunesDogus)
        assertEquals("20:35", day.gunesBatis)
        assertEquals("12:22", day.kibleSaati)
        assertEquals("08.06.2026", day.miladiTarihKisa)
        assertEquals("22 Zilhicce 1447", day.hicriTarihUzun)
    }

    @Test fun timeForPrayerAccessor() {
        val day = EzanVaktiJson.decodeFromString<List<PrayerDay>>(sampleJson).first()
        assertEquals("03:27", day.time(Prayer.IMSAK))
        assertEquals("22:31", day.time(Prayer.YATSI))
    }
}
