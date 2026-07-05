package com.olcayertas.namazvakti

import android.app.Application

/** Holds the app-wide dependency graph ([AppContainer]). */
class NamazVaktiApp : Application() {
    lateinit var container: AppContainer
        private set

    override fun onCreate() {
        super.onCreate()
        container = AppContainer(this)
    }
}
