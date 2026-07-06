package com.olcayertas.namazvakti.di

import com.olcayertas.namazvakti.data.SettingsStore
import com.olcayertas.namazvakti.domain.MonthCache
import dagger.hilt.EntryPoint
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent

/** Hilt entry point for components Hilt doesn't construct — the Glance widget's `provideGlance` and
 *  the BootReceiver — which reach the graph via `EntryPointAccessors.fromApplication(...)`. */
@EntryPoint
@InstallIn(SingletonComponent::class)
interface AppEntryPoint {
    fun settingsStore(): SettingsStore
    fun monthCache(): MonthCache
}
