package com.olcayertas.namazvakti.domain

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json
import java.text.Normalizer
import java.util.Locale

/** Shared JSON codec for the EzanVakti API — tolerates the extra keys the API sends. */
val EzanVaktiJson: Json = Json { ignoreUnknownKeys = true }

/** A country in the EzanVakti hierarchy (`/ulkeler`). Türkiye is id `"2"`. */
@Serializable
data class Country(@SerialName("UlkeID") val id: String, @SerialName("UlkeAdi") val name: String)

/** A city/province (`/sehirler/{countryId}`). İstanbul is id `"539"`. */
@Serializable
data class City(@SerialName("SehirID") val id: String, @SerialName("SehirAdi") val name: String)

/** A district (`/ilceler/{cityId}`). The `id` is exactly the `/vakitler/{id}` district id. */
@Serializable
data class District(@SerialName("IlceID") val id: String, @SerialName("IlceAdi") val name: String)

private val COMBINING_MARKS = Regex("\\p{Mn}+")

/**
 * Case- and diacritic-insensitive fold for the picker's search matching (mirrors the Swift
 * `String.foldedForSearch()`): lower-case (locale-independent) then strip combining marks, so
 * "istanbul" matches "İSTANBUL" and "sanliurfa" matches "ŞANLIURFA". The dotted capital `İ` is pinned
 * to `i` first (its Unicode lower-casing would otherwise leave a combining dot).
 */
fun String.foldedForSearch(): String =
    Normalizer.normalize(replace('İ', 'i').lowercase(Locale.ROOT), Normalizer.Form.NFD)
        .replace(COMBINING_MARKS, "")
