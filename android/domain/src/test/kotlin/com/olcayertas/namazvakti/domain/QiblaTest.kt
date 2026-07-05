package com.olcayertas.namazvakti.domain

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

/**
 * Golden tests ported verbatim from the Swift `QiblaTests` — the same expected forward azimuths to
 * the Kaaba (21.4225°N, 39.8262°E), degrees clockwise from true north. These pin the ported math;
 * the expected values are the cross-platform contract, so they must stay identical to the Swift
 * suite (`Tests/CoreTests/QiblaTests.swift`).
 */
class QiblaTest {

    @Test fun kucukcekmece() { // the app's default location
        assertEquals(151.150, Qibla.bearing(41.00, 28.78), absoluteTolerance = 0.01)
    }

    @Test fun istanbul() {
        assertEquals(151.621, Qibla.bearing(41.0082, 28.9784), absoluteTolerance = 0.01)
    }

    @Test fun london() {
        assertEquals(118.987, Qibla.bearing(51.5074, -0.1278), absoluteTolerance = 0.01)
    }

    @Test fun jakartaWrapsPastNorthwest() { // > 180°, exercises the +360 normalization
        assertEquals(295.152, Qibla.bearing(-6.2088, 106.8456), absoluteTolerance = 0.01)
    }

    @Test fun newYork() {
        assertEquals(58.482, Qibla.bearing(40.7128, -74.0060), absoluteTolerance = 0.01)
    }

    @Test fun atKaabaIsZero() { // same-point edge case stays finite
        assertEquals(0.0, Qibla.bearing(Qibla.KAABA_LATITUDE, Qibla.KAABA_LONGITUDE), absoluteTolerance = 0.001)
    }

    @Test fun resultAlwaysNormalized() {
        var lat = -80.0
        while (lat <= 80.0) {
            var lon = -180.0
            while (lon <= 180.0) {
                val b = Qibla.bearing(lat, lon)
                assertTrue(b >= 0.0, "bearing $b < 0 at ($lat, $lon)")
                assertTrue(b < 360.0, "bearing $b >= 360 at ($lat, $lon)")
                assertFalse(b.isNaN(), "NaN at ($lat, $lon)")
                lon += 30.0
            }
            lat += 20.0
        }
    }
}
