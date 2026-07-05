package com.olcayertas.namazvakti.domain

import java.time.ZoneId

/**
 * Static configuration for the v1 build. Ported from the Swift `Config`.
 *
 * The default location is Küçükçekmece (Diyanet district id `9543`, the id from the source URL).
 */
object Config {
    /** Diyanet district id used for `/vakitler/{id}`. */
    const val DEFAULT_DISTRICT_ID = "9543"

    /** Human-readable name for the default district. */
    const val DEFAULT_LOCATION_NAME = "Küçükçekmece"

    /** Türkiye country id in the EzanVakti hierarchy (`/sehirler/2`). */
    const val TURKIYE_COUNTRY_ID = "2"

    /**
     * All prayer times are published as Türkiye-local clock times, so every prayer instant is built
     * in this zone regardless of the device's own zone.
     */
    val ISTANBUL_ZONE: ZoneId = ZoneId.of("Europe/Istanbul")
}
