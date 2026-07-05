package com.olcayertas.namazvakti.domain

import kotlin.math.atan2
import kotlin.math.cos
import kotlin.math.sin

/**
 * Qibla (direction to the Kaaba in Mecca) math. Pure and platform-free — plain [Double] degrees in,
 * a bearing out — so it lives in `:domain`, compiles anywhere, and is JVM-unit-testable without a
 * device. The Android compass screen will feed the device coordinate in and rotate a needle by the
 * returned bearing (correcting magnetic→true north with `GeomagneticField` at the call site).
 *
 * Ported verbatim from the Swift `Qibla` enum (`Sources/Core/Qibla.swift`); the golden values in
 * `QiblaTest` are the cross-platform contract.
 */
object Qibla {
    /** The Kaaba, Mecca (decimal degrees, WGS-84). */
    const val KAABA_LATITUDE = 21.4225
    const val KAABA_LONGITUDE = 39.8262

    /**
     * Initial great-circle bearing (forward azimuth) from the given point to the Kaaba, in degrees
     * clockwise from **true** north, normalized to `0..<360`.
     *
     *     θ = atan2( sinΔλ·cosφ₂ , cosφ₁·sinφ₂ − sinφ₁·cosφ₂·cosΔλ )
     *
     * where φ = latitude, λ = longitude, point 1 = observer, point 2 = the Kaaba. Finite and
     * non-crashing at every input: at the Kaaba it returns 0; `atan2` stays defined at poles/antipode.
     */
    fun bearing(latitude: Double, longitude: Double): Double {
        val phi1 = Math.toRadians(latitude)
        val phi2 = Math.toRadians(KAABA_LATITUDE)
        val deltaLon = Math.toRadians(KAABA_LONGITUDE - longitude)

        val y = sin(deltaLon) * cos(phi2)
        val x = cos(phi1) * sin(phi2) - sin(phi1) * cos(phi2) * cos(deltaLon)
        val degrees = Math.toDegrees(atan2(y, x))
        // Kotlin's `%` on Double is truncating (like Swift's truncatingRemainder / fmod).
        return (degrees % 360 + 360) % 360
    }
}
