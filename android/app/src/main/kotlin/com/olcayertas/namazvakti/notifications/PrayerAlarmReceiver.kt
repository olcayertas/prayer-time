package com.olcayertas.namazvakti.notifications

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import com.olcayertas.namazvakti.R

/** Posts a "{Prayer} time" notification when a scheduled alarm fires. */
class PrayerAlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val prayer = intent.getStringExtra(EXTRA_PRAYER) ?: return
        val location = intent.getStringExtra(EXTRA_LOCATION).orEmpty()
        val nm = NotificationManagerCompat.from(context)
        if (!nm.areNotificationsEnabled()) return // channel/app blocked → nothing to do
        val notification = NotificationCompat.Builder(context, NotificationScheduler.CHANNEL)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle(context.getString(R.string.notif_title, prayer))
            .setContentText(context.getString(R.string.notif_body, prayer, location))
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .build()
        try {
            nm.notify(prayer.hashCode(), notification)
        } catch (e: SecurityException) {
            // POST_NOTIFICATIONS not granted — ignore.
        }
    }

    companion object {
        const val EXTRA_PRAYER = "prayer"
        const val EXTRA_LOCATION = "location"
    }
}
