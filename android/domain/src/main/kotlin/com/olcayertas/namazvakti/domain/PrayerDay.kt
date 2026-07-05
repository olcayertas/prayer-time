package com.olcayertas.namazvakti.domain

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/**
 * One day of prayer times from the EzanVakti wrapper of Diyanet data. `@SerialName` maps the Turkish
 * PascalCase JSON keys; unknown keys the app doesn't model are ignored by [EzanVaktiJson]. Ported
 * from the Swift `PrayerDay` (Codable + CodingKeys).
 */
@Serializable
data class PrayerDay(
    @SerialName("Imsak") val imsak: String,
    @SerialName("Gunes") val gunes: String,
    @SerialName("Ogle") val ogle: String,
    @SerialName("Ikindi") val ikindi: String,
    @SerialName("Aksam") val aksam: String,
    @SerialName("Yatsi") val yatsi: String,
    @SerialName("GunesDogus") val gunesDogus: String? = null,
    @SerialName("GunesBatis") val gunesBatis: String? = null,
    @SerialName("KibleSaati") val kibleSaati: String? = null,
    @SerialName("HicriTarihUzun") val hicriTarihUzun: String? = null,
    @SerialName("HicriTarihKisa") val hicriTarihKisa: String? = null,
    @SerialName("MiladiTarihKisa") val miladiTarihKisa: String? = null,
    @SerialName("MiladiTarihUzun") val miladiTarihUzun: String? = null,
) {
    /** Stable id (one row per day). */
    val id: String get() = miladiTarihKisa ?: "$imsak-$ogle-$yatsi"

    /** The published `HH:mm` string for a given prayer. */
    fun time(prayer: Prayer): String = when (prayer) {
        Prayer.IMSAK -> imsak
        Prayer.GUNES -> gunes
        Prayer.OGLE -> ogle
        Prayer.IKINDI -> ikindi
        Prayer.AKSAM -> aksam
        Prayer.YATSI -> yatsi
    }
}
