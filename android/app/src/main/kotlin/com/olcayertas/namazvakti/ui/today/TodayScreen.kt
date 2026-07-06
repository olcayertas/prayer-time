package com.olcayertas.namazvakti.ui.today

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.olcayertas.namazvakti.R
import com.olcayertas.namazvakti.domain.CountdownFormatter
import com.olcayertas.namazvakti.domain.Prayer
import com.olcayertas.namazvakti.domain.PrayerDay
import com.olcayertas.namazvakti.domain.PrayerSchedule
import com.olcayertas.namazvakti.domain.UpcomingPrayer
import com.olcayertas.namazvakti.ui.Dot
import com.olcayertas.namazvakti.ui.prayerName
import com.olcayertas.namazvakti.ui.theme.LocalNamazTheme
import com.olcayertas.namazvakti.ui.theme.NamazTheme
import kotlinx.coroutines.delay
import kotlinx.coroutines.isActive
import java.time.Instant

@Composable
fun TodayScreen(schedule: PrayerSchedule, locationName: String, modifier: Modifier = Modifier) {
    val theme = LocalNamazTheme.current
    var now by remember { mutableStateOf(Instant.now()) } // 1 Hz tick for the live countdown
    LaunchedEffect(Unit) { while (isActive) { now = Instant.now(); delay(1000) } }

    val today = schedule.day(now) ?: schedule.days.firstOrNull()
    val upcoming = schedule.upcoming(now)
    val current = schedule.current(now)

    Column(
        modifier = modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .statusBarsPadding()
            .padding(24.dp),
        verticalArrangement = Arrangement.spacedBy(20.dp),
    ) {
        Header(locationName, today, theme)
        if (today != null) {
            Hero(upcoming, theme)
            Grid(today, current = current, next = upcoming?.prayer, theme = theme)
            Extras(today, theme)
        }
    }
}

@Composable
private fun Header(location: String, today: PrayerDay?, theme: NamazTheme) {
    Column(Modifier.fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(4.dp)) {
        Text(location, fontFamily = theme.fonts.display, fontWeight = FontWeight.Bold, fontSize = 34.sp, color = theme.text)
        if (today != null) {
            val line = listOfNotNull(today.miladiTarihUzun, today.hicriTarihUzun).joinToString("  ·  ")
            if (line.isNotEmpty()) Text(line, fontFamily = theme.fonts.body, fontSize = 15.sp, color = theme.muted)
        }
    }
}

@Composable
private fun Hero(upcoming: UpcomingPrayer?, theme: NamazTheme) {
    Column(
        modifier = Modifier.fillMaxWidth().clip(RoundedCornerShape(16.dp)).background(theme.accentSoft).padding(22.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        if (upcoming == null) {
            Text(stringResource(R.string.error_load_today), color = theme.muted, fontFamily = theme.fonts.body)
            return@Column
        }
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(14.dp)) {
            Dot(theme.accent, 40.dp)
            Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
                Text(stringResource(R.string.next_prayer), fontFamily = theme.fonts.body, fontSize = 15.sp, color = theme.muted)
                Text(prayerName(upcoming.prayer), fontFamily = theme.fonts.display, fontWeight = FontWeight.SemiBold, fontSize = 28.sp, color = theme.text)
            }
        }
        Row(verticalAlignment = Alignment.Bottom, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            Text(CountdownFormatter.string(upcoming.remaining), fontFamily = theme.fonts.mono, fontWeight = FontWeight.Bold, fontSize = 42.sp, color = theme.accent)
            Text(stringResource(R.string.countdown_remaining), fontFamily = theme.fonts.body, fontSize = 12.sp, color = theme.muted, modifier = Modifier.padding(bottom = 7.dp))
        }
    }
}

@Composable
private fun Grid(today: PrayerDay, current: Prayer?, next: Prayer?, theme: NamazTheme) {
    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Prayer.entries.chunked(3).forEach { rowPrayers ->
            Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                rowPrayers.forEach { prayer ->
                    GridCell(prayer, today, prayer == next, prayer == current, theme, Modifier.weight(1f))
                }
            }
        }
    }
}

@Composable
private fun GridCell(prayer: Prayer, today: PrayerDay, isNext: Boolean, isCurrent: Boolean, theme: NamazTheme, modifier: Modifier) {
    Column(
        modifier = modifier
            .clip(RoundedCornerShape(12.dp))
            .background(if (isNext) theme.accentSoft else theme.surface)
            .then(if (isCurrent) Modifier.border(1.5.dp, theme.accent, RoundedCornerShape(12.dp)) else Modifier)
            .padding(vertical = 14.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(6.dp),
    ) {
        Dot(theme.prayerColor(prayer), 14.dp)
        Text(prayerName(prayer), fontFamily = theme.fonts.body, fontWeight = if (isNext) FontWeight.SemiBold else FontWeight.Normal, fontSize = 15.sp, color = theme.text)
        Text(today.time(prayer), fontFamily = theme.fonts.mono, fontWeight = FontWeight.Medium, fontSize = 20.sp, color = theme.text)
    }
}

@Composable
private fun Extras(today: PrayerDay, theme: NamazTheme) {
    Row(horizontalArrangement = Arrangement.spacedBy(28.dp)) {
        today.gunesDogus?.let { InfoItem(stringResource(R.string.prayer_sunrise), it, theme) }
        today.gunesBatis?.let { InfoItem(stringResource(R.string.prayer_sunset), it, theme) }
        today.kibleSaati?.let { InfoItem(stringResource(R.string.qibla_time), it, theme) }
    }
}

@Composable
private fun InfoItem(label: String, value: String, theme: NamazTheme) {
    Column(verticalArrangement = Arrangement.spacedBy(1.dp)) {
        Text(label, fontFamily = theme.fonts.body, fontSize = 11.sp, color = theme.muted)
        Text(value, fontFamily = theme.fonts.mono, fontSize = 16.sp, color = theme.text)
    }
}
