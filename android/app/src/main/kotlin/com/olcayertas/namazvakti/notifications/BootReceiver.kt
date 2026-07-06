package com.olcayertas.namazvakti.notifications

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import com.olcayertas.namazvakti.di.AppEntryPoint
import com.olcayertas.namazvakti.domain.PrayerSchedule
import dagger.hilt.android.EntryPointAccessors
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch

/**
 * Re-schedules the prayer alarms after a reboot / app update / timezone change (Android alarms don't
 * survive a reboot). Uses the cached month, so it works offline.
 */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED, Intent.ACTION_MY_PACKAGE_REPLACED, Intent.ACTION_TIMEZONE_CHANGED -> Unit
            else -> return
        }
        val pending = goAsync()
        val ep = EntryPointAccessors.fromApplication(context.applicationContext, AppEntryPoint::class.java)
        CoroutineScope(Dispatchers.IO).launch {
            try {
                val settings = ep.settingsStore().settings.first()
                if (settings.notificationsEnabled) {
                    ep.monthCache().load(settings.districtId)?.let { days ->
                        NotificationScheduler(context).schedule(PrayerSchedule(days), settings.districtName)
                    }
                }
            } catch (_: Exception) {
                // best-effort
            } finally {
                pending.finish()
            }
        }
    }
}
