package com.olcayertas.namazvakti.domain

import java.time.Duration
import java.time.Instant
import java.time.LocalDateTime
import java.time.ZoneId
import java.time.ZoneOffset

/** The next prayer relative to a moment, with how long until it begins. Ported from `UpcomingPrayer`. */
data class UpcomingPrayer(val prayer: Prayer, val instant: Instant, val remaining: Duration)

/**
 * Turns a month of [PrayerDay] rows into instants and answers "what's the next prayer and how long
 * until it?". The published times are local clock times of the place: each day's instants use that
 * day's UTC offset from the API (Türkiye +03:00, Sarajevo +01:00/+02:00, Mecca +03:00), regardless of
 * the device zone. Days without an offset (months cached by an older version) fall back to
 * Europe/Istanbul, the old behaviour. Ported from the Swift `PrayerSchedule`.
 */
data class PrayerSchedule(
    val days: List<PrayerDay>,
    /** The place's zone for "which row is today?" and display: the first day's offset, else Istanbul. */
    val zone: ZoneId = zoneOf(days.firstOrNull()) ?: Config.ISTANBUL_ZONE,
) {
    /** All (prayer, instant) pairs across the loaded month, ascending. */
    fun sortedTimes(): List<Pair<Prayer, Instant>> =
        days.flatMap { day ->
            Prayer.entries.mapNotNull { prayer -> instant(prayer, day)?.let { prayer to it } }
        }.sortedBy { it.second }

    /** The next prayer strictly after [now]. Rolls into the following day (after Yatsı → tomorrow's İmsak). */
    fun upcoming(now: Instant): UpcomingPrayer? {
        val next = sortedTimes().firstOrNull { it.second > now } ?: return null
        return UpcomingPrayer(next.first, next.second, Duration.between(now, next.second))
    }

    /** The prayer period [now] falls in (the most recent time at or before [now]). */
    fun current(now: Instant): Prayer? =
        sortedTimes().lastOrNull { it.second <= now }?.first

    /**
     * The upcoming (prayer, instant) pairs strictly after [now], for scheduling notifications.
     * Excludes informational prayers (Güneş/sunrise) by default and caps at [limit].
     */
    fun upcomingTimes(now: Instant, limit: Int = 15, includeInformational: Boolean = false): List<Pair<Prayer, Instant>> =
        sortedTimes().filter { it.second > now && (includeInformational || !it.first.isInformational) }.take(limit)

    /**
     * The [PrayerDay] whose Gregorian date matches [now] in the place's zone. Also the cache-freshness
     * predicate: a cached month is fresh only while it still contains today's date there.
     */
    fun day(now: Instant): PrayerDay? {
        val date = now.atZone(zone).toLocalDate()
        return days.firstOrNull { day ->
            parseDate(day.miladiTarihKisa)?.let { (y, m, d) ->
                y == date.year && m == date.monthValue && d == date.dayOfMonth
            } ?: false
        }
    }

    /** Builds the instant for one prayer on one day, in that day's own zone (see the class doc). */
    fun instant(prayer: Prayer, day: PrayerDay): Instant? {
        val ymd = parseDate(day.miladiTarihKisa) ?: return null
        val hm = parseTime(day.time(prayer)) ?: return null
        return runCatching {
            LocalDateTime.of(ymd.year, ymd.month, ymd.day, hm.hour, hm.minute)
                .atZone(zoneOf(day) ?: zone).toInstant()
        }.getOrNull()
    }

    companion object {
        /** Fixed-offset zone of one day, or null when the day has no offset. */
        fun zoneOf(day: PrayerDay?): ZoneId? = day?.utcOffsetSeconds?.let { ZoneOffset.ofTotalSeconds(it) }

        data class Ymd(val year: Int, val month: Int, val day: Int)
        data class Hm(val hour: Int, val minute: Int)

        /** "dd.MM.yyyy" → (year, month, day), or null. */
        fun parseDate(string: String?): Ymd? {
            val parts = string?.split(".") ?: return null
            if (parts.size != 3) return null
            val day = parts[0].toIntOrNull() ?: return null
            val month = parts[1].toIntOrNull() ?: return null
            val year = parts[2].toIntOrNull() ?: return null
            return Ymd(year, month, day)
        }

        /** "HH:mm" → (hour, minute). Tolerates surrounding whitespace. */
        fun parseTime(string: String): Hm? {
            val parts = string.trim().split(":")
            if (parts.size < 2) return null
            val hour = parts[0].toIntOrNull() ?: return null
            val minute = parts[1].toIntOrNull() ?: return null
            return Hm(hour, minute)
        }
    }
}
