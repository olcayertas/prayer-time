package com.olcayertas.namazvakti.domain

import kotlinx.serialization.decodeFromString
import kotlinx.serialization.encodeToString
import java.io.File

/**
 * Per-district month cache as a JSON file (`monthlyTimes.{districtId}.json`) in [directory]. Ported
 * from the Swift `PrayerCache`. On Android the directory is the app's internal `filesDir`, which the
 * Glance widget reads directly (same process — no App Group needed). Pure `java.io.File`, so it's
 * JVM-testable with a temp dir. Reads/writes are best-effort: a missing or corrupt file → null.
 */
class MonthCache(private val directory: File) {

    private fun file(districtId: String) = File(directory, "monthlyTimes.$districtId.json")

    fun load(districtId: String): List<PrayerDay>? {
        val f = file(districtId)
        if (!f.exists()) return null
        return runCatching { EzanVaktiJson.decodeFromString<List<PrayerDay>>(f.readText()) }.getOrNull()
    }

    fun save(days: List<PrayerDay>, districtId: String) {
        runCatching {
            directory.mkdirs()
            file(districtId).writeText(EzanVaktiJson.encodeToString(days))
        }
    }
}
