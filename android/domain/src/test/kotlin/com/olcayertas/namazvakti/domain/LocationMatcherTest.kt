package com.olcayertas.namazvakti.domain

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

/** Ported verbatim from the Swift `LocationMatcherTests` — the Turkish fold + the Ankara
 *  province-collapse fallback. */
class LocationMatcherTest {

    @Test fun normalizeFoldsTurkishCasingAndDiacritics() {
        assertEquals(LocationMatcher.normalize("İstanbul"), LocationMatcher.normalize("İSTANBUL"))
        assertEquals("istanbul", LocationMatcher.normalize("İSTANBUL"))
        assertEquals(LocationMatcher.normalize("Küçükçekmece"), LocationMatcher.normalize("KÜÇÜKÇEKMECE"))
        assertEquals("kucukcekmece", LocationMatcher.normalize("KÜÇÜKÇEKMECE"))
    }

    @Test fun normalizeHandlesDotlessIAndPunctuation() {
        assertEquals(LocationMatcher.normalize("Şırnak"), LocationMatcher.normalize("ŞIRNAK"))
        assertEquals("cekmekoy", LocationMatcher.normalize("  Çekme-köy "))
    }

    @Test fun matchCityDottedI() {
        val cities = listOf(City("539", "İSTANBUL"), City("506", "ANKARA"))
        assertEquals("539", LocationMatcher.matchCity("İstanbul", cities)?.id)
        assertNull(LocationMatcher.matchCity("Konya", cities))
        assertNull(LocationMatcher.matchCity(null, cities))
    }

    @Test fun bestMatchExactIlce() {
        val districts = listOf(District("9543", "KÜÇÜKÇEKMECE"), District("9540", "ÇEKMEKÖY"))
        assertEquals("9543", LocationMatcher.bestMatch("İstanbul", "Küçükçekmece", districts)?.id)
    }

    @Test fun nearMissDoesNotMatch() {
        // A different ilçe must NOT collapse onto Küçükçekmece (and there's no İstanbul-named entry).
        val districts = listOf(District("9543", "KÜÇÜKÇEKMECE"))
        assertNull(LocationMatcher.bestMatch("İstanbul", "Çekmeköy", districts))
    }

    @Test fun metropolitanCenterFallback() {
        // Diyanet collapses Ankara's central ilçe into a single "ANKARA" entry, so Çankaya (geocoded
        // ASCII "Cankaya") resolves to "ANKARA" via the province-name fallback.
        val districts = listOf(
            District("9206", "ANKARA"), District("9211", "CUBUK"), District("9220", "POLATLI"),
        )
        assertEquals("9206", LocationMatcher.bestMatch("Ankara", "Cankaya", districts)?.id)
        // A peripheral ilçe that IS listed still matches exactly.
        assertEquals("9220", LocationMatcher.bestMatch("Ankara", "Polatlı", districts)?.id)
    }

    @Test fun bestMatchNullDistrictNoCenterReturnsNull() {
        val districts = listOf(District("9543", "KÜÇÜKÇEKMECE"))
        assertNull(LocationMatcher.bestMatch("İstanbul", null, districts))
    }
}
