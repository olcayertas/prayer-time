package com.olcayertas.namazvakti.domain

/**
 * The six daily prayers in chronological order (İmsak…Yatsı). **Order is load-bearing** — the UI
 * and schedule iterate [entries] in this order to build rows and pick the "next" prayer.
 *
 * Güneş (sunrise) is **informational, not a prayer**: [isInformational] marks it so the UI dims it
 * (0.5 opacity on its palette color) and never highlights it as "next". [apiField] is the Turkish
 * PascalCase key in the EzanVakti JSON.
 *
 * Ported from the Swift `Prayer` enum (`Sources/Core/PrayerDay.swift`).
 */
enum class Prayer(val apiField: String, val isInformational: Boolean = false) {
    IMSAK("Imsak"),
    GUNES("Gunes", isInformational = true),
    OGLE("Ogle"),
    IKINDI("Ikindi"),
    AKSAM("Aksam"),
    YATSI("Yatsi"),
}
