package com.olcayertas.namazvakti.ui.monthly

import androidx.compose.ui.unit.dp

/** Chart geometry — the same dp values as the iOS `MonthlyMetrics`, so dots line up under labels. */
object MonthlyMetrics {
    val gutter = 34.dp
    val rowHeight = 20.dp
    val selectedRowHeight = 34.dp // iOS keeps 20 + overflows the time labels; we grow the row instead
    val railWidth = 1.3.dp
    val dotDiameter = 4.6.dp // 2.3 radius × 2
    val selectedDotDiameter = 6.8.dp // 3.4 radius × 2
}
