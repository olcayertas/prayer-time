package com.olcayertas.namazvakti.domain

/** Which source gives the prayer times. Ported from the Swift `CalculationMethod`. */
enum class CalculationMethod {
    /** The Diyanet times from EzanVakti, unchanged. The default. */
    DIYANET,

    /**
     * The local authority's method of the place's country, calculated on the device. Only available where
     * [LocalMethod.forCountry] has one and the place has coordinates; otherwise Diyanet is used.
     */
    LOCAL,
}

/**
 * A local authority's published method. Only methods whose published parameters reproduce the
 * authority's own published table are listed (see `docs/CALCULATION-METHODS.md`).
 */
enum class LocalMethod {
    /**
     * Saudi Arabia, Umm al-Qura calendar (KACST): Fajr 18.5°, Isha 90 min after Maghrib (120 in Ramadan),
     * Asr shadow factor 1. Times round up to the next minute, sunrise rounds down.
     */
    UMM_AL_QURA;

    /**
     * The six times of one Diyanet day, recalculated with this method. Dates, Hijri date and the day's UTC
     * offset stay as Diyanet gives them (the Hijri month decides Ramadan; no calendar conversion). Returns
     * the day unchanged when it has no date or offset, or a time cannot be calculated.
     */
    fun apply(day: PrayerDay, latitude: Double, longitude: Double): PrayerDay {
        val ymd = PrayerSchedule.parseDate(day.miladiTarihKisa) ?: return day
        val offset = day.utcOffsetSeconds ?: return day
        return when (this) {
            UMM_AL_QURA -> {
                val ramadan = PrayerSchedule.parseDate(day.hicriTarihKisa)?.month == 9
                val t = PrayerCalculator.times(
                    ymd.year, ymd.month, ymd.day, latitude, longitude, offset / 3600.0,
                    PrayerCalculator.Parameters(
                        fajrAngle = 18.5, ishaAngle = null,
                        ishaMinutesAfterMaghrib = if (ramadan) 120.0 else 90.0,
                    ),
                )
                val fajr = t.fajr ?: return day
                val sunrise = t.sunrise ?: return day
                val asr = t.asr ?: return day
                val maghrib = t.maghrib ?: return day
                val isha = t.isha ?: return day
                fun up(h: Double) = PrayerCalculator.hhmm(h, roundUp = true)
                day.replacingTimes(
                    imsak = up(fajr), gunes = PrayerCalculator.hhmm(sunrise, roundUp = false), ogle = up(t.dhuhr),
                    ikindi = up(asr), aksam = up(maghrib), yatsi = up(isha),
                )
            }
        }
    }

    companion object {
        fun forCountry(iso: String?): LocalMethod? = when (iso?.uppercase()) {
            "SA" -> UMM_AL_QURA
            else -> null
        }
    }
}

/** What the method needs to know about the selected place. Persisted with the selection. */
data class PlaceContext(
    val isoCountryCode: String? = null,
    val latitude: Double? = null,
    val longitude: Double? = null,
) {
    /** The local method for this place, when the country has one and the place has coordinates. */
    val localMethod: LocalMethod?
        get() = if (latitude != null && longitude != null) LocalMethod.forCountry(isoCountryCode) else null
}

/** Raw Diyanet month → the month the app shows, for the chosen method. Pure; app, widget and alarms share it. */
object EffectiveTimes {
    fun days(raw: List<PrayerDay>, method: CalculationMethod, place: PlaceContext): List<PrayerDay> {
        val local = place.localMethod
        val lat = place.latitude
        val lon = place.longitude
        if (method != CalculationMethod.LOCAL || local == null || lat == null || lon == null) return raw
        return raw.map { local.apply(it, lat, lon) }
    }
}
