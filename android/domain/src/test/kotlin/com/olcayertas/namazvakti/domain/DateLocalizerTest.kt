package com.olcayertas.namazvakti.domain

import java.util.Locale
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull
import kotlin.test.assertTrue

/** Pins [DateLocalizer]: the Gregorian date reformats per locale; the Hijri date is built from the
 *  Diyanet numeric triple + the per-language month table (no Gregorian→Hijri conversion). */
class DateLocalizerTest {

    @Test fun gregorianTurkish() {
        val s = DateLocalizer.gregorianLong("03.07.2026", Locale("tr"))!!
        assertTrue("Temmuz" in s && "2026" in s && "Cuma" in s, "got: $s")
    }

    @Test fun gregorianEnglish() {
        val s = DateLocalizer.gregorianLong("03.07.2026", Locale.ENGLISH)!!
        assertTrue("July" in s && "2026" in s && "Friday" in s, "got: $s")
    }

    @Test fun hijriTurkish() {
        assertEquals("18 Muharrem 1448", DateLocalizer.hijriLong("18.1.1448", Locale("tr")))
    }

    @Test fun hijriEnglish() {
        assertEquals("18 Muharram 1448", DateLocalizer.hijriLong("18.1.1448", Locale.ENGLISH))
    }

    @Test fun hijriArabicMonth() {
        val s = DateLocalizer.hijriLong("18.1.1448", Locale("ar"))!!
        assertTrue("محرم" in s, "got: $s") // Muharram; digits localize to Arabic-Indic
    }

    @Test fun hijriMonthNames() {
        // Ramadan (month 9) — the one users check for.
        assertEquals("1 Ramazan 1448", DateLocalizer.hijriLong("1.9.1448", Locale("tr")))
        assertEquals("1 Ramadan 1448", DateLocalizer.hijriLong("1.9.1448", Locale.ENGLISH))
    }

    @Test fun nullOnBadInput() {
        assertNull(DateLocalizer.gregorianLong(null, Locale.ENGLISH))
        assertNull(DateLocalizer.gregorianLong("not-a-date", Locale.ENGLISH))
        assertNull(DateLocalizer.hijriLong("18.13.1448", Locale.ENGLISH)) // month out of range
        assertNull(DateLocalizer.hijriLong("18.1", Locale.ENGLISH)) // too few parts
    }
}
