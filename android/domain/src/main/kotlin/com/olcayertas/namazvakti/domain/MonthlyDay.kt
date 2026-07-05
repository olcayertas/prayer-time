package com.olcayertas.namazvakti.domain

import java.time.DayOfWeek
import java.time.Instant
import java.time.LocalDate
import java.time.Month
import java.time.format.TextStyle
import java.util.Locale

/**
 * One day shaped for the Monthly chart + focus card. Built from [PrayerSchedule] (not a parallel
 * data source). [times] index 0…5 = `Prayer.entries`; null = missing (omit the dot). Ported from the
 * Swift `MonthlyDay`.
 */
data class MonthlyDay(
    val id: String, // = PrayerDay.miladiTarihKisa ("dd.MM.yyyy")
    val dayNumber: Int,
    val monthIndex: Int, // 1-based
    val year: Int,
    val weekdayName: String, // localized ("Cuma" / "Friday")
    val isFriday: Boolean,
    val isToday: Boolean,
    val times: List<Instant?>,
    val displayTimes: List<String?>,
)

object MonthlyFormat {
    /** Localized standalone month name for a 1-based index (6 → "June" / "Haziran"). */
    fun monthName(monthIndex: Int, locale: Locale = Locale.getDefault()): String =
        if (monthIndex in 1..12) Month.of(monthIndex).getDisplayName(TextStyle.FULL_STANDALONE, locale) else ""
}

object MonthlyDayBuilder {
    /** Maps `schedule.days` to view models, in order. [now] decides "today" (in Istanbul time). */
    fun build(schedule: PrayerSchedule, now: Instant, locale: Locale = Locale.getDefault()): List<MonthlyDay> {
        val todayKey = schedule.day(now)?.miladiTarihKisa
        return schedule.days.mapNotNull { day ->
            val key = day.miladiTarihKisa ?: return@mapNotNull null
            val ymd = PrayerSchedule.parseDate(key) ?: return@mapNotNull null
            val date = LocalDate.of(ymd.year, ymd.month, ymd.day)
            MonthlyDay(
                id = key,
                dayNumber = ymd.day,
                monthIndex = ymd.month,
                year = ymd.year,
                weekdayName = date.dayOfWeek.getDisplayName(TextStyle.FULL, locale),
                isFriday = date.dayOfWeek == DayOfWeek.FRIDAY,
                isToday = key == todayKey,
                times = Prayer.entries.map { schedule.instant(it, day) },
                displayTimes = Prayer.entries.map { day.time(it).trim().ifEmpty { null } },
            )
        }
    }
}
