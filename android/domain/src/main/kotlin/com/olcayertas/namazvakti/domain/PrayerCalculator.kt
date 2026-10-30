package com.olcayertas.namazvakti.domain

import java.util.Locale
import kotlin.math.abs
import kotlin.math.acos
import kotlin.math.asin
import kotlin.math.atan
import kotlin.math.atan2
import kotlin.math.ceil
import kotlin.math.cos
import kotlin.math.floor
import kotlin.math.sin
import kotlin.math.tan

/**
 * On-device prayer-time calculation from coordinates, for the "local authority" calculation method.
 * Pure and deterministic; golden-tested against published tables. Ported from the Swift
 * `PrayerCalculator`.
 *
 * The solar position and hour-angle formulas are the standard low-precision ones (U.S. Naval
 * Observatory approximation, as used by most prayer-time calculators); they are accurate to well under
 * a minute between ±65° latitude. Where a twilight angle is never reached, that time is null and the
 * caller keeps the Diyanet value.
 */
object PrayerCalculator {

    /** Times of one day as fractional hours of the local clock (e.g. 5.087 = 05:05:13). */
    data class DayTimes(
        val fajr: Double?, val sunrise: Double?, val dhuhr: Double,
        val asr: Double?, val maghrib: Double?, val isha: Double?,
    )

    data class Parameters(
        /** Sun angle below the horizon at dawn, in degrees. */
        val fajrAngle: Double,
        /** Sun angle below the horizon at nightfall, or null when Isha is a fixed interval after Maghrib. */
        val ishaAngle: Double?,
        /** Minutes after Maghrib, used when [ishaAngle] is null. */
        val ishaMinutesAfterMaghrib: Double = 0.0,
        /** Shadow length factor for Asr: 1 = Shafi'i/Maliki/Hanbali, 2 = Hanafi. */
        val asrShadowFactor: Double = 1.0,
    )

    fun times(
        year: Int, month: Int, day: Int,
        latitude: Double, longitude: Double, utcOffsetHours: Double,
        parameters: Parameters,
    ): DayTimes {
        val jd = julianDay(year, month, day) - longitude / 360

        fun noon(t: Double): Double = fixHour(12 - sunPosition(jd + t / 24).second)
        fun hourAngleTime(angle: Double, t: Double, beforeNoon: Boolean): Double? {
            val dec = sunPosition(jd + t / 24).first
            val cosT = (-dsin(angle) - dsin(dec) * dsin(latitude)) / (dcos(dec) * dcos(latitude))
            if (cosT < -1 || cosT > 1) return null
            val h = darccos(cosT) / 15
            return noon(t) + if (beforeNoon) -h else h
        }
        fun asrTime(t: Double): Double? {
            val dec = sunPosition(jd + t / 24).first
            val angle = -darccot(parameters.asrShadowFactor + dtan(abs(latitude - dec)))
            return hourAngleTime(angle, t, beforeNoon = false)
        }

        val fajr = hourAngleTime(parameters.fajrAngle, 5.0, beforeNoon = true)
        val sunrise = hourAngleTime(0.833, 6.0, beforeNoon = true)
        val dhuhr = noon(12.0)
        val asr = asrTime(13.0)
        val maghrib = hourAngleTime(0.833, 18.0, beforeNoon = false)
        val ishaAngle = parameters.ishaAngle
        val isha = if (ishaAngle != null) hourAngleTime(ishaAngle, 18.0, beforeNoon = false)
        else maghrib?.plus(parameters.ishaMinutesAfterMaghrib / 60)

        // The hour angles are in local solar time; shift to the zone's clock.
        val shift = utcOffsetHours - longitude / 15
        fun clock(t: Double?): Double? = t?.let { fixHour(it + shift) }
        return DayTimes(clock(fajr), clock(sunrise), fixHour(dhuhr + shift), clock(asr), clock(maghrib), clock(isha))
    }

    /** "HH:mm" from fractional hours, rounding up to the next whole minute ([roundUp]) or down. */
    fun hhmm(hours: Double, roundUp: Boolean): String {
        val seconds = hours * 3600
        // A tolerance so a value that is exactly on a minute does not jump to the next one.
        var minutes = if (roundUp) ceil(seconds / 60 - 1e-6).toInt() else floor(seconds / 60 + 1e-6).toInt()
        minutes = ((minutes % 1440) + 1440) % 1440
        // Locale.ROOT: ASCII digits on every device, because PrayerSchedule parses these strings back.
        return String.format(Locale.ROOT, "%02d:%02d", minutes / 60, minutes % 60)
    }

    // Astronomy

    fun julianDay(year: Int, month: Int, day: Int): Double {
        var y = year
        var m = month
        if (m <= 2) { y -= 1; m += 12 }
        val a = y / 100
        val b = 2 - a + a / 4
        return floor(365.25 * (y + 4716)) + floor(30.6001 * (m + 1)) + day + b - 1524.5
    }

    /** Sun declination (degrees) and equation of time (hours) for a Julian day. */
    fun sunPosition(jd: Double): Pair<Double, Double> {
        val d = jd - 2451545.0
        val g = fixAngle(357.529 + 0.98560028 * d)
        val q = fixAngle(280.459 + 0.98564736 * d)
        val l = fixAngle(q + 1.915 * dsin(g) + 0.020 * dsin(2 * g))
        val e = 23.439 - 0.00000036 * d
        val ra = fixHour(datan2(dcos(e) * dsin(l), dcos(l)) / 15)
        return darcsin(dsin(e) * dsin(l)) to q / 15 - ra
    }

    private fun fixAngle(a: Double): Double = ((a % 360) + 360) % 360
    private fun fixHour(h: Double): Double = ((h % 24) + 24) % 24
    private fun dsin(d: Double) = sin(Math.toRadians(d))
    private fun dcos(d: Double) = cos(Math.toRadians(d))
    private fun dtan(d: Double) = tan(Math.toRadians(d))
    private fun darcsin(x: Double) = Math.toDegrees(asin(x))
    private fun darccos(x: Double) = Math.toDegrees(acos(x))
    private fun darccot(x: Double) = Math.toDegrees(atan(1 / x))
    private fun datan2(y: Double, x: Double) = Math.toDegrees(atan2(y, x))
}
