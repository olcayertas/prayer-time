package com.olcayertas.namazvakti.domain

import java.time.Duration
import kotlin.test.Test
import kotlin.test.assertEquals

class CountdownFormatterTest {
    @Test fun overAnHour() =
        assertEquals("3:08:42", CountdownFormatter.string(Duration.ofSeconds(3 * 3600 + 8 * 60 + 42L)))

    @Test fun underAnHour() =
        assertEquals("8:42", CountdownFormatter.string(Duration.ofSeconds(8 * 60 + 42L)))

    @Test fun clampsNegative() =
        assertEquals("0:00", CountdownFormatter.string(Duration.ofSeconds(-5)))

    @Test fun zero() =
        assertEquals("0:00", CountdownFormatter.string(Duration.ZERO))
}
