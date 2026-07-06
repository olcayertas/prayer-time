package com.olcayertas.namazvakti.widget

import android.content.Context
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.action.actionStartActivity
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.cornerRadius
import androidx.glance.appwidget.provideContent
import androidx.glance.background
import androidx.glance.layout.Alignment
import androidx.glance.layout.Column
import androidx.glance.layout.Row
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.height
import androidx.glance.layout.padding
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextAlign
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider
import com.olcayertas.namazvakti.MainActivity
import com.olcayertas.namazvakti.NamazVaktiApp
import com.olcayertas.namazvakti.domain.Config
import com.olcayertas.namazvakti.domain.Prayer
import com.olcayertas.namazvakti.domain.PrayerSchedule
import com.olcayertas.namazvakti.ui.prayerNameRes
import kotlinx.coroutines.flow.first
import java.time.Instant
import java.time.format.DateTimeFormatter

/**
 * Home-screen widget: the location, the next prayer (name + clock time), and today's six times.
 * Reads the shared [com.olcayertas.namazvakti.data.SettingsStore] + month cache (same process as the
 * app — no App Group needed), so it works offline. Fixed dark/gold palette: a widget renders in a
 * separate host and can't read the in-app Compose theme (same constraint as the iOS widget).
 */
class PrayerWidget : GlanceAppWidget() {
    override suspend fun provideGlance(context: Context, id: GlanceId) {
        val container = (context.applicationContext as NamazVaktiApp).container
        val settings = container.settingsStore.settings.first()
        val schedule = container.monthCache.load(settings.districtId)?.let { PrayerSchedule(it) }
        provideContent { WidgetContent(context, settings.districtName, schedule) }
    }
}

private object WidgetColors {
    val bg = Color(0xFF141A2E)
    val accent = Color(0xFFE3B341)
    val text = Color(0xFFEDEFF7)
    val muted = Color(0xFF8A93A8)
    val line = Color(0x22FFFFFF)
}

private val hhmm = DateTimeFormatter.ofPattern("HH:mm")
private fun clock(instant: Instant): String = hhmm.format(instant.atZone(Config.ISTANBUL_ZONE))

@Composable
private fun WidgetContent(context: Context, location: String, schedule: PrayerSchedule?) {
    val now = Instant.now()
    val today = schedule?.day(now)
    val upcoming = schedule?.upcoming(now)

    Column(
        modifier = GlanceModifier.fillMaxSize().background(WidgetColors.bg).cornerRadius(18.dp)
            .padding(horizontal = 16.dp, vertical = 14.dp)
            .clickable(actionStartActivity<MainActivity>()),
    ) {
        Text(location, style = TextStyle(color = ColorProvider(WidgetColors.muted), fontSize = 12.sp, fontWeight = FontWeight.Medium))
        Spacer(GlanceModifier.height(6.dp))

        if (upcoming != null) {
            Text(
                context.getString(prayerNameRes(upcoming.prayer)),
                style = TextStyle(color = ColorProvider(WidgetColors.accent), fontSize = 26.sp, fontWeight = FontWeight.Bold),
            )
            Text(clock(upcoming.instant), style = TextStyle(color = ColorProvider(WidgetColors.text), fontSize = 18.sp, fontWeight = FontWeight.Medium))
        } else {
            Text("—", style = TextStyle(color = ColorProvider(WidgetColors.muted), fontSize = 22.sp))
        }

        Spacer(GlanceModifier.height(12.dp))
        Spacer(GlanceModifier.fillMaxWidth().height(1.dp).background(WidgetColors.line))
        Spacer(GlanceModifier.height(10.dp))

        Row(modifier = GlanceModifier.fillMaxWidth()) {
            Prayer.entries.forEach { prayer ->
                val next = upcoming?.prayer == prayer
                Column(
                    modifier = GlanceModifier.defaultWeight(),
                    horizontalAlignment = Alignment.CenterHorizontally,
                ) {
                    Text(
                        context.getString(prayerNameRes(prayer)),
                        maxLines = 1,
                        style = TextStyle(
                            color = ColorProvider(if (next) WidgetColors.accent else WidgetColors.muted),
                            fontSize = 10.sp, textAlign = TextAlign.Center,
                            fontWeight = if (next) FontWeight.Bold else FontWeight.Normal,
                        ),
                    )
                    Text(
                        today?.time(prayer) ?: "—",
                        maxLines = 1,
                        style = TextStyle(
                            color = ColorProvider(if (next) WidgetColors.accent else WidgetColors.text),
                            fontSize = 12.sp, textAlign = TextAlign.Center,
                            fontWeight = if (next) FontWeight.Bold else FontWeight.Medium,
                        ),
                    )
                }
            }
        }
    }
}
