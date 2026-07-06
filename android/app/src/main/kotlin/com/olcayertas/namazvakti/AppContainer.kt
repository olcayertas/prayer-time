package com.olcayertas.namazvakti

import android.content.Context
import com.olcayertas.namazvakti.data.EzanVaktiRemote
import com.olcayertas.namazvakti.data.SettingsStore
import com.olcayertas.namazvakti.domain.DefaultPlacesRepository
import com.olcayertas.namazvakti.domain.DefaultPrayerTimesRepository
import com.olcayertas.namazvakti.domain.MonthCache
import com.olcayertas.namazvakti.domain.PlacesRepository
import com.olcayertas.namazvakti.domain.PrayerTimesRepository
import okhttp3.OkHttpClient

/**
 * The app's dependency graph, wired by hand for now. (Hilt is a mechanical follow-up per the plan.)
 * Constructed once in [NamazVaktiApp] and read by the UI. The month cache uses the app's internal
 * `filesDir`, which the Glance widget will read directly (same process — no App Group needed).
 */
class AppContainer(context: Context) {
    private val httpClient = OkHttpClient()
    private val remote = EzanVaktiRemote(httpClient)
    private val cache = MonthCache(context.filesDir)

    val prayerTimesRepository: PrayerTimesRepository = DefaultPrayerTimesRepository(remote, cache)
    val placesRepository: PlacesRepository = DefaultPlacesRepository(remote)
    val settingsStore = SettingsStore(context)
}
