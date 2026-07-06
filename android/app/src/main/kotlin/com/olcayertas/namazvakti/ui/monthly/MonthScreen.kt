package com.olcayertas.namazvakti.ui.monthly

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxScope
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.olcayertas.namazvakti.R
import com.olcayertas.namazvakti.domain.CountdownFormatter
import com.olcayertas.namazvakti.domain.MonthlyDay
import com.olcayertas.namazvakti.domain.MonthlyDayBuilder
import com.olcayertas.namazvakti.domain.MonthlyFormat
import com.olcayertas.namazvakti.domain.Prayer
import com.olcayertas.namazvakti.domain.PrayerSchedule
import com.olcayertas.namazvakti.domain.UpcomingPrayer
import com.olcayertas.namazvakti.ui.Dot
import com.olcayertas.namazvakti.ui.localeUppercase
import com.olcayertas.namazvakti.ui.prayerName
import com.olcayertas.namazvakti.ui.theme.LocalNamazTheme
import com.olcayertas.namazvakti.ui.theme.NamazTheme
import kotlinx.coroutines.delay
import kotlinx.coroutines.isActive
import java.time.Instant

@Composable
fun MonthScreen(schedule: PrayerSchedule, locationName: String, modifier: Modifier = Modifier) {
    val theme = LocalNamazTheme.current
    var now by remember { mutableStateOf(Instant.now()) }
    LaunchedEffect(Unit) { while (isActive) { now = Instant.now(); delay(1000) } }

    val monthKey = schedule.days.firstOrNull()?.miladiTarihKisa
    val days = remember(monthKey) { MonthlyDayBuilder.build(schedule, now) }
    var selectedId by rememberSaveable(monthKey) {
        mutableStateOf(days.firstOrNull { it.isToday }?.id ?: days.firstOrNull()?.id)
    }
    val selected = days.firstOrNull { it.id == selectedId } ?: days.firstOrNull()

    Column(modifier.fillMaxSize().statusBarsPadding()) {
        MonthHeader(selected?.monthIndex, selected?.year, theme)
        FocusCard(selected, schedule, locationName, now, theme, Modifier.padding(horizontal = 16.dp).padding(bottom = 6.dp))
        GlanceDivider(theme)
        ColumnHeader(theme, Modifier.padding(horizontal = 14.dp))
        MonthChart(days, selectedId, onSelect = { selectedId = it }, theme, Modifier.weight(1f))
    }
}

@Composable
private fun MonthHeader(month: Int?, year: Int?, theme: NamazTheme) {
    Column(
        Modifier.fillMaxWidth().padding(horizontal = 22.dp).padding(top = 4.dp, bottom = 8.dp),
        verticalArrangement = Arrangement.spacedBy(4.dp),
    ) {
        Text(stringResource(R.string.month_focus_eyebrow), fontFamily = theme.fonts.body, fontWeight = FontWeight.Bold, fontSize = 11.sp, letterSpacing = 2.sp, color = theme.accent.copy(alpha = 0.85f))
        Row(verticalAlignment = Alignment.CenterVertically) {
            Text(month?.let { MonthlyFormat.monthName(it) } ?: "", fontFamily = theme.fonts.display, fontWeight = FontWeight.Medium, fontSize = 28.sp, color = theme.text)
            Spacer(Modifier.width(6.dp))
            year?.let { Text(it.toString(), fontFamily = theme.fonts.display, fontWeight = FontWeight.Medium, fontSize = 28.sp, color = theme.faint) }
            Spacer(Modifier.weight(1f))
            NavChevron("‹", theme); Spacer(Modifier.width(8.dp)); NavChevron("›", theme)
        }
    }
}

@Composable
private fun NavChevron(glyph: String, theme: NamazTheme) {
    // Disabled in v1 (the store holds a single month).
    Box(Modifier.size(32.dp).clip(RoundedCornerShape(10.dp)).background(theme.surface.copy(alpha = 0.4f)), contentAlignment = Alignment.Center) {
        Text(glyph, color = theme.muted.copy(alpha = 0.4f), fontSize = 16.sp)
    }
}

@Composable
private fun FocusCard(day: MonthlyDay?, schedule: PrayerSchedule, location: String, now: Instant, theme: NamazTheme, modifier: Modifier) {
    Column(
        modifier = modifier.fillMaxWidth()
            .clip(RoundedCornerShape(18.dp))
            .background(Brush.verticalGradient(listOf(theme.elevatedCardTop, theme.elevatedCardBottom)))
            .border(1.dp, theme.accent.copy(alpha = 0.16f), RoundedCornerShape(18.dp))
            .padding(top = 13.dp, start = 15.dp, end = 15.dp, bottom = 14.dp),
        verticalArrangement = Arrangement.spacedBy(13.dp),
    ) {
        if (day == null) {
            Text(stringResource(R.string.error_load_today), color = theme.muted, fontFamily = theme.fonts.body)
            return@Column
        }
        val upcoming = if (day.isToday) schedule.upcoming(now) else null
        val nextIndex = upcoming?.prayer?.ordinal
        FocusHeader(day, location, upcoming, theme)
        FocusCells(day, nextIndex, theme)
    }
}

@Composable
private fun FocusHeader(day: MonthlyDay, location: String, upcoming: UpcomingPrayer?, theme: NamazTheme) {
    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(11.dp)) {
        Text("%02d".format(day.dayNumber), fontFamily = theme.fonts.display, fontWeight = FontWeight.Medium, fontSize = 34.sp, color = theme.accent)
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(1.dp)) {
            Text(if (day.isToday) stringResource(R.string.month_focus_today, day.weekdayName) else day.weekdayName, fontFamily = theme.fonts.body, fontWeight = FontWeight.SemiBold, fontSize = 15.sp, color = theme.text)
            Text("$location · ${MonthlyFormat.monthName(day.monthIndex)} ${day.year}", fontFamily = theme.fonts.body, fontSize = 12.sp, color = theme.muted)
        }
        FocusChip(day, upcoming, theme)
    }
}

@Composable
private fun FocusChip(day: MonthlyDay, upcoming: UpcomingPrayer?, theme: NamazTheme) {
    if (day.isToday && upcoming != null) {
        Column(
            horizontalAlignment = Alignment.End,
            verticalArrangement = Arrangement.spacedBy(1.dp),
            modifier = Modifier.clip(RoundedCornerShape(14.dp)).background(theme.accentSoft)
                .border(1.dp, theme.accent.copy(alpha = 0.25f), RoundedCornerShape(14.dp))
                .padding(horizontal = 10.dp, vertical = 5.dp),
        ) {
            Text(stringResource(R.string.month_next_chip, prayerName(upcoming.prayer)), fontFamily = theme.fonts.body, fontWeight = FontWeight.SemiBold, fontSize = 11.sp, color = theme.accent)
            Text(CountdownFormatter.string(upcoming.remaining), fontFamily = theme.fonts.mono, fontWeight = FontWeight.SemiBold, fontSize = 11.sp, color = theme.accent)
        }
    } else {
        Text(
            "${MonthlyFormat.monthName(day.monthIndex)} ${day.dayNumber}",
            fontFamily = theme.fonts.body, fontWeight = FontWeight.SemiBold, fontSize = 11.sp, color = theme.muted,
            modifier = Modifier.clip(RoundedCornerShape(14.dp)).background(theme.surface).padding(horizontal = 10.dp, vertical = 5.dp),
        )
    }
}

@Composable
private fun FocusCells(day: MonthlyDay, nextIndex: Int?, theme: NamazTheme) {
    Row(horizontalArrangement = Arrangement.spacedBy(4.dp)) {
        Prayer.entries.forEachIndexed { i, prayer ->
            val isNext = i == nextIndex
            val isSun = prayer == Prayer.GUNES
            val labelColor = if (isNext) theme.accent else if (isSun) theme.faint else theme.muted
            val timeColor = if (isNext) theme.accent else if (isSun) theme.faint else theme.text
            Column(
                modifier = Modifier.weight(1f)
                    .then(if (isNext) Modifier.clip(RoundedCornerShape(11.dp)).background(theme.accentSoft).border(1.dp, theme.accent.copy(alpha = 0.3f), RoundedCornerShape(11.dp)) else Modifier)
                    .padding(vertical = 8.dp, horizontal = 2.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(5.dp),
            ) {
                Dot(theme.prayerColor(prayer), 7.dp)
                Text(localeUppercase(prayerName(prayer)), fontFamily = theme.fonts.body, fontWeight = FontWeight.Bold, fontSize = 9.sp, maxLines = 1, softWrap = false, color = labelColor)
                Text(day.displayTimes[i] ?: "—", fontFamily = theme.fonts.mono, fontWeight = FontWeight.Medium, fontSize = 13.sp, color = timeColor)
            }
        }
    }
}

@Composable
private fun GlanceDivider(theme: NamazTheme) {
    Row(
        Modifier.fillMaxWidth().padding(horizontal = 22.dp).padding(top = 8.dp, bottom = 4.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        Text(stringResource(R.string.month_eyebrow), fontFamily = theme.fonts.body, fontWeight = FontWeight.Bold, fontSize = 11.sp, letterSpacing = 1.5.sp, color = theme.faint)
        Box(Modifier.weight(1f).height(1.dp).background(theme.line))
        Text(stringResource(R.string.month_tap_hint), fontFamily = theme.fonts.body, fontSize = 11.sp, color = theme.faint)
    }
}

@Composable
private fun ColumnHeader(theme: NamazTheme, modifier: Modifier) {
    Column(modifier) {
        DayRowLayout(
            gutter = { Spacer(Modifier.height(1.dp)) },
            cell = { i ->
                val prayer = Prayer.entries[i]
                Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(3.dp)) {
                    Dot(theme.prayerColor(prayer), 6.dp)
                    Text(localeUppercase(prayerName(prayer)), fontFamily = theme.fonts.body, fontWeight = FontWeight.Bold, fontSize = 9.sp, maxLines = 1, softWrap = false, color = if (prayer == Prayer.GUNES) theme.faint else theme.muted)
                }
            },
        )
        Spacer(Modifier.height(6.dp))
        Box(Modifier.fillMaxWidth().height(1.dp).background(theme.line))
    }
}

/** Fixed-width trailing gutter (day number) + six equal columns, so dots align under labels. */
@Composable
private fun DayRowLayout(
    modifier: Modifier = Modifier,
    stretchCells: Boolean = false, // true only for fixed-height chart rows (so rails fill the row)
    gutter: @Composable BoxScope.() -> Unit,
    cell: @Composable BoxScope.(Int) -> Unit,
) {
    Row(modifier, verticalAlignment = Alignment.CenterVertically) {
        Box(Modifier.width(MonthlyMetrics.gutter), contentAlignment = Alignment.CenterEnd, content = gutter)
        for (i in 0 until 6) {
            val cellMod = if (stretchCells) Modifier.weight(1f).fillMaxHeight() else Modifier.weight(1f)
            Box(cellMod, contentAlignment = Alignment.Center) { cell(i) }
        }
    }
}

@Composable
private fun MonthChart(days: List<MonthlyDay>, selectedId: String?, onSelect: (String) -> Unit, theme: NamazTheme, modifier: Modifier) {
    val listState = rememberLazyListState()
    LaunchedEffect(days) {
        val i = days.indexOfFirst { it.id == selectedId }
        if (i >= 0) listState.scrollToItem((i - 6).coerceAtLeast(0)) // scroll the selected day toward center
    }
    LazyColumn(state = listState, modifier = modifier.padding(horizontal = 14.dp), contentPadding = PaddingValues(bottom = 24.dp)) {
        itemsIndexed(days, key = { _, d -> d.id }) { index, day ->
            val divider = if (index > 0 && day.monthIndex != days[index - 1].monthIndex) localeUppercase(MonthlyFormat.monthName(day.monthIndex)) else null
            MonthChartRow(day, day.id == selectedId, divider, theme) { onSelect(day.id) }
        }
    }
}

@Composable
private fun MonthChartRow(day: MonthlyDay, isSelected: Boolean, monthDivider: String?, theme: NamazTheme, onTap: () -> Unit) {
    Column {
        if (monthDivider != null) {
            Row(Modifier.padding(top = 8.dp, bottom = 2.dp), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                Text(monthDivider, fontFamily = theme.fonts.body, fontWeight = FontWeight.Bold, fontSize = 9.sp, color = theme.faint)
                Box(Modifier.weight(1f).height(1.dp).background(theme.lineStrong))
            }
        }
        DayRowLayout(
            modifier = Modifier
                .height(if (isSelected) MonthlyMetrics.selectedRowHeight else MonthlyMetrics.rowHeight)
                .clip(RoundedCornerShape(5.dp))
                .then(rowBand(isSelected, day.isToday, theme))
                .clickable(onClick = onTap),
            stretchCells = true,
            gutter = {
                Text(
                    "%02d".format(day.dayNumber),
                    fontFamily = theme.fonts.mono,
                    fontWeight = if (day.isToday || day.isFriday) FontWeight.Bold else FontWeight.SemiBold,
                    fontSize = 12.sp,
                    color = if (day.isToday || day.isFriday) theme.accent else theme.muted,
                    modifier = Modifier.padding(end = 6.dp),
                )
            },
            cell = { i -> ChartCell(day, i, isSelected, theme) },
        )
    }
}

@Composable
private fun BoxScope.ChartCell(day: MonthlyDay, i: Int, isSelected: Boolean, theme: NamazTheme) {
    val prayer = Prayer.entries[i]
    val color = theme.prayerColor(prayer)
    // rail (a thin vertical line; stacks into a continuous column across rows)
    Box(Modifier.width(MonthlyMetrics.railWidth).fillMaxHeight().background(color.copy(alpha = if (prayer == Prayer.GUNES) 0.12f else 0.2f)))
    if (day.times[i] != null) {
        if (isSelected) {
            Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(1.dp)) {
                Text(day.displayTimes[i] ?: "", fontFamily = theme.fonts.mono, fontWeight = FontWeight.SemiBold, fontSize = 9.sp, maxLines = 1, softWrap = false, color = color)
                Dot(color, MonthlyMetrics.selectedDotDiameter)
            }
        } else {
            Dot(color, MonthlyMetrics.dotDiameter)
        }
    }
}

private fun rowBand(isSelected: Boolean, isToday: Boolean, theme: NamazTheme): Modifier = when {
    isSelected -> Modifier.background(theme.accent.copy(alpha = 0.10f)).border(1.dp, theme.accent.copy(alpha = 0.35f), RoundedCornerShape(5.dp))
    isToday -> Modifier.background(theme.accent.copy(alpha = 0.05f))
    else -> Modifier
}
