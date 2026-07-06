package com.olcayertas.namazvakti.domain

import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.time.format.FormatStyle
import java.util.Locale

/**
 * Localizes the EzanVakti API's Turkish-only long dates. The Gregorian date is reformatted per locale
 * via `java.time`; the Hijri date is built from the Diyanet-supplied numeric triple (`HicriTarihKisa`,
 * e.g. "18.1.1448") plus a per-language month table — we never convert Gregorian→Hijri, so Diyanet's
 * day is preserved. Ported from the iOS `DateLocalizer`. Pure JVM, so it's unit-testable.
 */
object DateLocalizer {

    /** "03.07.2026" → the locale's full date ("Friday, July 3, 2026" / "3 Temmuz 2026 Cuma"). */
    fun gregorianLong(miladiTarihKisa: String?, locale: Locale): String? {
        val (d, m, y) = parseTriple(miladiTarihKisa) ?: return null
        val date = runCatching { LocalDate.of(y, m, d) }.getOrNull() ?: return null
        return DateTimeFormatter.ofLocalizedDate(FormatStyle.FULL).withLocale(locale).format(date)
    }

    /** "18.1.1448" → "18 Muharrem 1448" / "18 Muharram 1448" / "١٨ محرم ١٤٤٨" (digits per locale). */
    fun hijriLong(hicriTarihKisa: String?, locale: Locale): String? {
        val (day, month, year) = parseTriple(hicriTarihKisa) ?: return null
        if (month !in 1..12) return null
        return String.format(locale, "%d %s %d", day, hijriMonths(locale)[month - 1], year)
    }

    /** "d.M.yyyy" → (day, month, year). */
    private fun parseTriple(kisa: String?): Triple<Int, Int, Int>? {
        val parts = kisa?.split('.') ?: return null
        if (parts.size != 3) return null
        val d = parts[0].trim().toIntOrNull() ?: return null
        val m = parts[1].trim().toIntOrNull() ?: return null
        val y = parts[2].trim().toIntOrNull() ?: return null
        return Triple(d, m, y)
    }

    private fun hijriMonths(locale: Locale): Array<String> = when (locale.language) {
        "tr" -> TR
        "ar" -> AR
        else -> EN
    }

    private val EN = arrayOf(
        "Muharram", "Safar", "Rabiʻ al-Awwal", "Rabiʻ al-Thani", "Jumada al-Ula", "Jumada al-Akhirah",
        "Rajab", "Shaʻban", "Ramadan", "Shawwal", "Dhu al-Qiʻdah", "Dhu al-Hijjah",
    )
    private val TR = arrayOf(
        "Muharrem", "Safer", "Rebiülevvel", "Rebiülahir", "Cemaziyelevvel", "Cemaziyelahir",
        "Recep", "Şaban", "Ramazan", "Şevval", "Zilkade", "Zilhicce",
    )
    private val AR = arrayOf(
        "محرم", "صفر", "ربيع الأول", "ربيع الآخر", "جمادى الأولى", "جمادى الآخرة",
        "رجب", "شعبان", "رمضان", "شوال", "ذو القعدة", "ذو الحجة",
    )
}
