package com.olcayertas.namazvakti.domain

import java.text.Normalizer
import java.util.Locale

/**
 * Pure matching of geocoded place names to the EzanVakti hierarchy. Ported from the Swift
 * `LocationMatcher`.
 *
 * The hard problem: EzanVakti returns ALL-CAPS Turkish ("İSTANBUL", "KÜÇÜKÇEKMECE") while the
 * geocoder returns mixed-case, and Turkish's dotted/dotless I makes naive `uppercase`/`lowercase`
 * unreliable. Both sides fold to a locale-independent canonical key before comparing.
 */
object LocationMatcher {

    private val combiningMarks = Regex("\\p{Mn}+")

    /**
     * Canonical comparison key: all four I-forms (`İ` `I` `ı` → `i`) pinned first (so Turkish casing
     * can't diverge), then case- and diacritic-folded, then non-alphanumerics stripped.
     * "İstanbul"/"İSTANBUL" → "istanbul"; "KÜÇÜKÇEKMECE" → "kucukcekmece"; "Çekme-köy" → "cekmekoy".
     */
    fun normalize(raw: String): String {
        val iFolded = raw.replace('İ', 'i').replace('ı', 'i').replace('I', 'i')
        return Normalizer.normalize(iFolded.lowercase(Locale.ROOT), Normalizer.Form.NFD)
            .replace(combiningMarks, "")
            .filter { it.isLetterOrDigit() }
    }

    /** Match a geocoded province (il) name to a [City] in the given list. */
    fun matchCity(province: String?, cities: List<City>): City? {
        val key = province?.let(::normalize) ?: return null
        if (key.isEmpty()) return null
        return cities.firstOrNull { normalize(it.name) == key }
            ?: cities.firstOrNull {
                val n = normalize(it.name)
                n.contains(key) || key.contains(n)
            }
    }

    /**
     * Best EzanVakti district for a geocoded (province, district) pair. Prefers an exact ilçe match
     * (İstanbul lists all ~39 ilçe), then containment, then falls back to the province-named central
     * entry for cities where Diyanet collapses the central ilçe into one (Ankara lists only peripheral
     * ilçe + a single "ANKARA", so Çankaya/Keçiören resolve to "ANKARA"). Returns null when nothing
     * matches, so the caller keeps the current district.
     */
    fun bestMatch(province: String?, district: String?, districts: List<District>): District? {
        val districtKey = district?.let(::normalize)
        if (!districtKey.isNullOrEmpty()) {
            // 1. Exact ilçe match.
            districts.firstOrNull { normalize(it.name) == districtKey }?.let { return it }
            // 2. Containment (geocoder "Küçükçekmece" vs a catalog "Küçükçekmece Merkez", etc.).
            districts.firstOrNull {
                val n = normalize(it.name)
                n.contains(districtKey) || districtKey.contains(n)
            }?.let { return it }
        }
        // 3. Metropolitan-center fallback: the geocoded ilçe isn't separately listed → use the
        //    province-named central entry if present.
        val provinceKey = province?.let(::normalize)
        if (!provinceKey.isNullOrEmpty()) {
            districts.firstOrNull { normalize(it.name) == provinceKey }?.let { return it }
        }
        return null
    }
}
