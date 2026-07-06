package com.olcayertas.namazvakti

import android.content.Context
import com.olcayertas.namazvakti.data.EzanVaktiRemote
import com.olcayertas.namazvakti.data.SettingsStore
import com.olcayertas.namazvakti.domain.DefaultPlacesRepository
import com.olcayertas.namazvakti.domain.DefaultPrayerTimesRepository
import com.olcayertas.namazvakti.domain.MonthCache
import com.olcayertas.namazvakti.domain.PlacesRepository
import com.olcayertas.namazvakti.domain.PrayerTimesRepository
import com.olcayertas.namazvakti.location.AutoLocation
import okhttp3.OkHttpClient

/**
 * The app's dependency graph, wired by hand for now. (Hilt is a mechanical follow-up per the plan.)
 * Constructed once in [NamazVaktiApp] and read by the UI + receivers. The month cache uses the app's
 * internal `filesDir` (the Glance widget / BootReceiver read it same-process — no App Group needed).
 */
class AppContainer(context: Context) {
    private val httpClient = OkHttpClient()
    private val remote = EzanVaktiRemote(httpClient)

    val monthCache = MonthCache(context.filesDir)
    val prayerTimesRepository: PrayerTimesRepository = DefaultPrayerTimesRepository(remote, monthCache)
    val placesRepository: PlacesRepository = DefaultPlacesRepository(remote)
    val settingsStore = SettingsStore(context)
    val autoLocation = AutoLocation(context.applicationContext, placesRepository)
}
