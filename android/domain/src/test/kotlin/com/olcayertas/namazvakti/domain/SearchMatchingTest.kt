package com.olcayertas.namazvakti.domain

import kotlin.test.Test
import kotlin.test.assertFalse
import kotlin.test.assertTrue

/** Ported from the Swift `SearchMatchingTests` — the picker sheet's folded-`contains` match. */
class SearchMatchingTest {

    private fun matches(query: String, name: String): Boolean =
        name.foldedForSearch().contains(query.foldedForSearch())

    @Test fun turkishDottedICaseFold() {
        assertTrue(matches("istanbul", "İSTANBUL"))
        assertTrue(matches("İstanbul", "İSTANBUL"))
        assertTrue(matches("ISTANBUL", "İstanbul"))
    }

    @Test fun diacriticInsensitive() {
        assertTrue(matches("sanliurfa", "ŞANLIURFA"))
        assertTrue(matches("kucukcekmece", "KÜÇÜKÇEKMECE"))
        assertTrue(matches("gumushane", "GÜMÜŞHANE"))
    }

    @Test fun substringMatch() {
        assertTrue(matches("stan", "İSTANBUL"))
        assertTrue(matches("çek", "Küçükçekmece"))
    }

    @Test fun nonMatch() {
        assertFalse(matches("ankara", "İSTANBUL"))
    }
}
