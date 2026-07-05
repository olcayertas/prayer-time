package com.olcayertas.namazvakti.domain

import java.time.Instant

/** Monthly prayer times for a district, cache-first. */
interface PrayerTimesRepository {
    /**
     * Returns the cached month while it still covers today; otherwise fetches, caches, and returns
     * the fresh month. On a network error with a (stale) cache present, returns the stale cache
     * rather than failing; with no cache, rethrows. [forceRefresh] bypasses the fresh-cache
     * short-circuit. Mirrors the Swift `PrayerStore` refresh/freshness behavior.
     */
    suspend fun monthlyTimes(districtId: String, forceRefresh: Boolean = false): List<PrayerDay>
}

class DefaultPrayerTimesRepository(
    private val remote: PrayerTimesRemote,
    private val cache: MonthCache,
    private val clock: () -> Instant = Instant::now,
) : PrayerTimesRepository {

    override suspend fun monthlyTimes(districtId: String, forceRefresh: Boolean): List<PrayerDay> {
        val cached = cache.load(districtId)
        val cacheCoversToday = cached != null && PrayerSchedule(cached).day(clock()) != null
        if (!forceRefresh && cacheCoversToday) return cached!!
        return try {
            remote.monthlyTimes(districtId).also { cache.save(it, districtId) }
        } catch (e: Exception) {
            // Offline with a stale cache → show stale (better than nothing); no cache → surface it.
            cached ?: throw e
        }
    }
}
