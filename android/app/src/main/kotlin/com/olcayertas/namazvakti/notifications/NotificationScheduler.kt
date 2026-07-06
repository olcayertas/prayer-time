package com.olcayertas.namazvakti.notifications

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationChannelCompat
import androidx.core.app.NotificationManagerCompat
import com.olcayertas.namazvakti.R
import com.olcayertas.namazvakti.domain.PrayerSchedule
import com.olcayertas.namazvakti.ui.prayerName
import java.time.Instant

/**
 * Schedules an exact alarm at each upcoming prayer time (~3 days ahead); [PrayerAlarmReceiver] posts
 * the notification when one fires. Reschedule on app foreground and on boot (Android alarms don't
 * survive a reboot). Self-chaining beyond the scheduled window and the full exact-alarm rationale UI
 * are later refinements (see the plan §6.1).
 */
class NotificationScheduler(private val context: Context) {

    fun ensureChannel() {
        val channel = NotificationChannelCompat.Builder(CHANNEL, NotificationManagerCompat.IMPORTANCE_HIGH)
            .setName(context.getString(R.string.notif_channel_name))
            .setDescription(context.getString(R.string.notif_channel_desc))
            .build()
        NotificationManagerCompat.from(context).createNotificationChannel(channel)
    }

    /** Whether exact alarms are permitted (always on < API 31; user-grantable on 31+). */
    fun canScheduleExact(): Boolean {
        val am = context.getSystemService(AlarmManager::class.java) ?: return false
        return Build.VERSION.SDK_INT < Build.VERSION_CODES.S || am.canScheduleExactAlarms()
    }

    fun schedule(schedule: PrayerSchedule, locationName: String) {
        ensureChannel()
        cancelAll()
        val am = context.getSystemService(AlarmManager::class.java) ?: return
        val exact = canScheduleExact()
        schedule.upcomingTimes(Instant.now(), MAX).forEachIndexed { i, (prayer, instant) ->
            val pi = pendingIntent(i, prayerName(prayer), locationName)
            val at = instant.toEpochMilli()
            try {
                if (exact) am.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, pi)
                else am.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, pi) // inexact → may fire late
            } catch (e: SecurityException) {
                am.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, pi)
            }
        }
    }

    fun cancelAll() {
        val am = context.getSystemService(AlarmManager::class.java) ?: return
        for (i in 0 until MAX) am.cancel(pendingIntent(i, "", ""))
    }

    private fun pendingIntent(id: Int, prayer: String, location: String): PendingIntent {
        val intent = Intent(context, PrayerAlarmReceiver::class.java).apply {
            putExtra(PrayerAlarmReceiver.EXTRA_PRAYER, prayer)
            putExtra(PrayerAlarmReceiver.EXTRA_LOCATION, location)
        }
        return PendingIntent.getBroadcast(
            context, BASE_REQUEST + id, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    companion object {
        const val CHANNEL = "prayers"
        private const val BASE_REQUEST = 1000
        private const val MAX = 15 // ~3 days × 5 prayers (Güneş excluded)
    }
}
