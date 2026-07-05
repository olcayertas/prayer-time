package com.olcayertas.namazvakti.domain

import kotlinx.coroutines.runBlocking
import java.nio.file.Files
import java.time.Instant
import java.time.LocalDateTime
import java.time.ZoneId
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith

/** The cache-first / freshness / offline-fallback orchestration, with a fake remote + temp cache +
 *  a fixed clock (so "today" is deterministic). */
class PrayerTimesRepositoryTest {

    private fun istanbul(y: Int, mo: Int, d: Int): Instant =
        LocalDateTime.of(y, mo, d, 12, 0).atZone(ZoneId.of("Europe/Istanbul")).toInstant()

    private fun month(vararg dates: String) = dates.map {
        PrayerDay("03:27", "05:26", "13:09", "17:08", "20:42", "22:31", miladiTarihKisa = it)
    }

    private class FakeRemote(var result: List<PrayerDay>, var fail: Boolean = false) : PrayerTimesRemote {
        var calls = 0
        override suspend fun monthlyTimes(districtId: String): List<PrayerDay> {
            calls++
            if (fail) throw RuntimeException("network down")
            return result
        }
    }

    private fun cache() = MonthCache(Files.createTempDirectory("repo").toFile())

    @Test fun freshCacheSkipsNetwork() = runBlocking {
        val c = cache(); c.save(month("16.06.2026", "17.06.2026"), "9543")
        val remote = FakeRemote(month("01.01.2000"))
        val repo = DefaultPrayerTimesRepository(remote, c) { istanbul(2026, 6, 17) }
        assertEquals("16.06.2026", repo.monthlyTimes("9543").first().miladiTarihKisa)
        assertEquals(0, remote.calls) // fresh cache → never hit the network
    }

    @Test fun staleCacheFetchesAndReCaches() = runBlocking {
        val c = cache(); c.save(month("16.05.2026"), "9543") // May — stale in June
        val remote = FakeRemote(month("16.06.2026", "17.06.2026"))
        val repo = DefaultPrayerTimesRepository(remote, c) { istanbul(2026, 6, 17) }
        assertEquals("16.06.2026", repo.monthlyTimes("9543").first().miladiTarihKisa)
        assertEquals(1, remote.calls)
        assertEquals("16.06.2026", c.load("9543")?.first()?.miladiTarihKisa) // saved the fresh month
    }

    @Test fun noCacheFetches() = runBlocking {
        val remote = FakeRemote(month("16.06.2026"))
        val repo = DefaultPrayerTimesRepository(remote, cache()) { istanbul(2026, 6, 17) }
        repo.monthlyTimes("9543")
        assertEquals(1, remote.calls)
    }

    @Test fun forceRefreshBypassesFreshCache() = runBlocking {
        val c = cache(); c.save(month("16.06.2026", "17.06.2026"), "9543")
        val remote = FakeRemote(month("18.06.2026"))
        val repo = DefaultPrayerTimesRepository(remote, c) { istanbul(2026, 6, 17) }
        repo.monthlyTimes("9543", forceRefresh = true)
        assertEquals(1, remote.calls)
    }

    @Test fun networkFailureFallsBackToStaleCache() = runBlocking {
        val c = cache(); c.save(month("16.05.2026"), "9543") // stale
        val remote = FakeRemote(emptyList(), fail = true)
        val repo = DefaultPrayerTimesRepository(remote, c) { istanbul(2026, 6, 17) }
        assertEquals("16.05.2026", repo.monthlyTimes("9543").first().miladiTarihKisa) // stale > nothing
    }

    @Test fun networkFailureNoCacheThrows() {
        val remote = FakeRemote(emptyList(), fail = true)
        val repo = DefaultPrayerTimesRepository(remote, cache()) { istanbul(2026, 6, 17) }
        assertFailsWith<RuntimeException> { runBlocking { repo.monthlyTimes("9543") } }
    }
}
