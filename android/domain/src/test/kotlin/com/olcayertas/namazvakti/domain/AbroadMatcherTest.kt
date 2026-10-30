package com.olcayertas.namazvakti.domain

import kotlinx.serialization.Serializable
import kotlinx.serialization.decodeFromString
import java.io.File
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull
import kotlin.test.assertTrue

/** Runs the shared golden corpus (`shared/golden/abroad-matching.json`, also run by the Swift suite). */
class AbroadMatcherTest {

    @Serializable private data class Corpus(val cases: List<Case>)
    @Serializable private data class Case(
        val name: String,
        val place: PlaceRow,
        val cities: List<Row>,
        val districts: List<Row>,
        val expectedCityId: String? = null,
        val expectedDistrictId: String? = null,
    )
    @Serializable private data class PlaceRow(
        val isoCountryCode: String? = null, val administrativeArea: String? = null,
        val subAdministrativeArea: String? = null, val locality: String? = null, val subLocality: String? = null,
    ) {
        fun toPlace() = AbroadMatcher.Place(isoCountryCode, administrativeArea, subAdministrativeArea, locality, subLocality)
    }
    @Serializable private data class Row(val id: String, val name: String, val nameEn: String? = null)

    private fun corpus(): Corpus {
        // Gradle runs tests with the module dir (android/domain) as the working directory.
        val file = generateSequence(File("").absoluteFile) { it.parentFile }
            .map { File(it, "shared/golden/abroad-matching.json") }
            .first { it.exists() }
        return EzanVaktiJson.decodeFromString(file.readText())
    }

    @Test fun goldenCorpus() {
        val cases = corpus().cases
        assertTrue(cases.size >= 16)
        for (c in cases) {
            val place = c.place.toPlace()
            val city = AbroadMatcher.matchCity(place, c.cities.map { City(it.id, it.name, it.nameEn) })
            assertEquals(c.expectedCityId, city?.id, "city: ${c.name}")
            if (city == null) continue
            val district = AbroadMatcher.matchDistrict(place, c.districts.map { District(it.id, it.name, it.nameEn) })
            assertEquals(c.expectedDistrictId, district?.id, "district: ${c.name}")
        }
    }

    @Test fun districtKeysIgnoreTextInsideParentheses() {
        val dorfen = District("1", "DORFEN (Munih)", "DORFEN (Munih)")
        assertEquals(listOf(listOf("dorfen", "munih"), listOf("dorfen")), AbroadMatcher.districtTokens(dorfen))
        assertNull(AbroadMatcher.matchDistrict(AbroadMatcher.Place(isoCountryCode = "DE", locality = "Munih"), listOf(dorfen)))
    }

    @Test fun administrativeWordsAreDropped() {
        assertEquals(listOf("jeddah"), AbroadMatcher.candidateTokens("Jeddah Governorate", "SA"))
        assertEquals(listOf("mexico", "city"), AbroadMatcher.candidateTokens("Mexico City", "MX"))
    }

    @Test fun countryCodes() {
        assertEquals("2", CountryCodes.ezanVaktiCountryId["TR"])
        assertEquals("64", CountryCodes.ezanVaktiCountryId["SA"])
        assertEquals("9", CountryCodes.ezanVaktiCountryId["BA"])
        // No guess where one code covers two EzanVakti countries (Northern Cyprus, Crimea, Chechnya).
        assertNull(CountryCodes.ezanVaktiCountryId["CY"])
        assertEquals("SA", CountryCodes.isoCode("64"))
        val ids = CountryCodes.ezanVaktiCountryId.values
        assertEquals(ids.size, ids.toSet().size)
    }

    /** The Kotlin and Swift tables are generated from one JSON; check that the generator was run. */
    @Test fun tablesMatchTheSharedJson() {
        val file = generateSequence(File("").absoluteFile) { it.parentFile }
            .map { File(it, "shared/ezanvakti-country-codes.json") }.first { it.exists() }
        val json = EzanVaktiJson.parseToJsonElement(file.readText())
        val codes = (json as kotlinx.serialization.json.JsonObject)["codes"] as kotlinx.serialization.json.JsonObject
        assertEquals(codes.mapValues { it.value.toString().trim('"') }, CountryCodes.ezanVaktiCountryId)
        val swift = File(file.parentFile.parentFile, "apple/Sources/Core/CountryCodes.swift").readText()
        for ((iso, id) in CountryCodes.ezanVaktiCountryId) assertTrue("\"$iso\": \"$id\"," in swift, "swift row $iso")
    }
}
