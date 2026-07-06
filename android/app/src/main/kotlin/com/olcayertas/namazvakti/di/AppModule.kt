package com.olcayertas.namazvakti.di

import android.content.Context
import com.olcayertas.namazvakti.data.EzanVaktiRemote
import com.olcayertas.namazvakti.data.SettingsStore
import com.olcayertas.namazvakti.domain.DefaultPlacesRepository
import com.olcayertas.namazvakti.domain.DefaultPrayerTimesRepository
import com.olcayertas.namazvakti.domain.MonthCache
import com.olcayertas.namazvakti.domain.PlacesRepository
import com.olcayertas.namazvakti.domain.PrayerTimesRepository
import com.olcayertas.namazvakti.location.AutoLocation
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import okhttp3.OkHttpClient
import javax.inject.Singleton

/** The app's dependency graph (was the hand-wired `AppContainer`). Everything is app-scoped; the
 *  month cache uses the internal `filesDir`, which the widget / BootReceiver read same-process. */
@Module
@InstallIn(SingletonComponent::class)
object AppModule {

    @Provides @Singleton
    fun httpClient(): OkHttpClient = OkHttpClient()

    @Provides @Singleton
    fun remote(client: OkHttpClient): EzanVaktiRemote = EzanVaktiRemote(client)

    @Provides @Singleton
    fun monthCache(@ApplicationContext context: Context): MonthCache = MonthCache(context.filesDir)

    @Provides @Singleton
    fun prayerTimesRepository(remote: EzanVaktiRemote, cache: MonthCache): PrayerTimesRepository =
        DefaultPrayerTimesRepository(remote, cache)

    @Provides @Singleton
    fun placesRepository(remote: EzanVaktiRemote): PlacesRepository = DefaultPlacesRepository(remote)

    @Provides @Singleton
    fun settingsStore(@ApplicationContext context: Context): SettingsStore = SettingsStore(context)

    @Provides @Singleton
    fun autoLocation(@ApplicationContext context: Context, places: PlacesRepository): AutoLocation =
        AutoLocation(context, places)
}
