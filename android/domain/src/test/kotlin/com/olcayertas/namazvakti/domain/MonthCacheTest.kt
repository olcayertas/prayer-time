package com.olcayertas.namazvakti.domain

import java.io.File
import java.nio.file.Files
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

class MonthCacheTest {

    private fun tempCache(): MonthCache = MonthCache(Files.createTempDirectory("mc").toFile())

    private val days = listOf(
        PrayerDay("03:27", "05:26", "13:09", "17:08", "20:42", "22:31", miladiTarihKisa = "08.06.2026"),
    )

    @Test fun saveThenLoadRoundTrips() {
        val cache = tempCache()
        cache.save(days, "9543")
        assertEquals(days, cache.load("9543"))
    }

    @Test fun loadMissingReturnsNull() {
        assertNull(tempCache().load("9543"))
    }

    @Test fun cacheIsPerDistrict() {
        val cache = tempCache()
        cache.save(days, "9543")
        assertNull(cache.load("9206"))
    }

    @Test fun loadCorruptReturnsNull() {
        val dir = Files.createTempDirectory("mc").toFile()
        File(dir, "monthlyTimes.9543.json").writeText("not json {{")
        assertNull(MonthCache(dir).load("9543"))
    }
}
