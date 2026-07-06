package com.olcayertas.namazvakti

import android.app.Application
import dagger.hilt.android.HiltAndroidApp

/** Hilt's application entry point — bootstraps the DI graph (see `di/AppModule`). */
@HiltAndroidApp
class NamazVaktiApp : Application()
