package com.olcayertas.namazvakti.domain

import kotlinx.serialization.decodeFromString
import kotlin.test.Test
import kotlin.test.assertEquals

/** Ported from the Swift `PlaceDecodingTests` — the hierarchy JSON keys, and that a district's id is
 *  exactly the `/vakitler/{id}` id. */
class PlaceDecodingTest {

    @Test fun decodesCountries() {
        val list = EzanVaktiJson.decodeFromString<List<Country>>(
            """[{"UlkeAdi":"TURKIYE","UlkeAdiEn":"TURKEY","UlkeID":"2"}]""",
        )
        assertEquals("2", list.first().id)
        assertEquals("TURKIYE", list.first().name)
    }

    @Test fun decodesCities() {
        val list = EzanVaktiJson.decodeFromString<List<City>>(
            """[{"SehirAdi":"İSTANBUL","SehirAdiEn":"ISTANBUL","SehirID":"539"}]""",
        )
        assertEquals("539", list.first().id)
        assertEquals("İSTANBUL", list.first().name)
    }

    @Test fun decodesDistrictsAndIdMatchesVakitlerId() {
        val list = EzanVaktiJson.decodeFromString<List<District>>(
            """[{"IlceAdi":"KÜÇÜKÇEKMECE","IlceAdiEn":"KUCUKCEKMECE","IlceID":"9543"}]""",
        )
        assertEquals("9543", list.first().id) // exactly the /vakitler/{id} id
        assertEquals("KÜÇÜKÇEKMECE", list.first().name)
    }
}
