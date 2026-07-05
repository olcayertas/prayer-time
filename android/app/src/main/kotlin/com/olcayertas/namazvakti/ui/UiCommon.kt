package com.olcayertas.namazvakti.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.Dp
import com.olcayertas.namazvakti.domain.Prayer

/** English display names (localized TR/AR via string resources arrives in the i18n phase). */
internal fun prayerName(prayer: Prayer): String = when (prayer) {
    Prayer.IMSAK -> "Dawn"
    Prayer.GUNES -> "Sunrise"
    Prayer.OGLE -> "Noon"
    Prayer.IKINDI -> "Afternoon"
    Prayer.AKSAM -> "Sunset"
    Prayer.YATSI -> "Night"
}

/** A filled circle — the palette dot used across Today and Monthly (stands in for the iOS SF symbol). */
@Composable
internal fun Dot(color: Color, diameter: Dp) {
    androidx.compose.foundation.layout.Box(Modifier.size(diameter).clip(CircleShape).background(color))
}
