package com.olcayertas.namazvakti.domain

import java.time.Duration

/**
 * Formats a remaining interval as a compact digital countdown: `3:08:42` when an hour or more
 * remains, otherwise `8:42`. Ported from the Swift `CountdownFormatter`.
 */
object CountdownFormatter {
    fun string(remaining: Duration): String {
        val total = remaining.seconds.coerceAtLeast(0)
        val hours = total / 3600
        val minutes = (total % 3600) / 60
        val seconds = total % 60
        return if (hours > 0) "%d:%02d:%02d".format(hours, minutes, seconds)
        else "%d:%02d".format(minutes, seconds)
    }
}
