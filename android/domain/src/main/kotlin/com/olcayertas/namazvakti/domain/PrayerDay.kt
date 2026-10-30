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
    /** "2026-10-26T00:00:00.0000000+01:00": local midnight of the day with the place's UTC offset. */
    @SerialName("MiladiTarihUzunIso8601") val miladiTarihUzunIso8601: String? = null,
) {
    /** Stable id (one row per day). */
    val id: String get() = miladiTarihKisa ?: "$imsak-$ogle-$yatsi"

    /**
     * The day's UTC offset in seconds, read from the trailing "+hh:mm" / "-hh:mm" / "Z" of
     * [miladiTarihUzunIso8601]. Null when absent (a month cached by an older version): the caller then
     * falls back to Europe/Istanbul. The offset is the one at local midnight, so on a DST change day the
     * times after the change are an hour off for that one day.
     */
    val utcOffsetSeconds: Int?
        get() {
            val iso = miladiTarihUzunIso8601?.trim().orEmpty()
            if (iso.isEmpty()) return null
            if (iso.endsWith("Z")) return 0
            if (iso.length < 6) return null
            val tail = iso.takeLast(6)
            val sign = when (tail[0]) { '+' -> 1; '-' -> -1; else -> return null }
            val parts = tail.drop(1).split(":")
            if (parts.size != 2) return null
            val h = parts[0].toIntOrNull() ?: return null
            val m = parts[1].toIntOrNull() ?: return null
            return sign * (h * 3600 + m * 60)
        }

    /** A copy with the six times (and the sunrise/sunset extras) replaced; dates, Hijri and offset kept. */
    fun replacingTimes(imsak: String, gunes: String, ogle: String, ikindi: String, aksam: String, yatsi: String) =
        copy(imsak = imsak, gunes = gunes, ogle = ogle, ikindi = ikindi, aksam = aksam, yatsi = yatsi,
            gunesDogus = gunes, gunesBatis = aksam)

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
