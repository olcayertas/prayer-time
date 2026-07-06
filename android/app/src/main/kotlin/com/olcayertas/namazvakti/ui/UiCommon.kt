package com.olcayertas.namazvakti.ui

import androidx.annotation.StringRes
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.Dp
import com.olcayertas.namazvakti.R
import com.olcayertas.namazvakti.domain.Prayer

/** The localized display-name resource for a prayer — usable from Compose and from the notification
 *  receiver (which resolves it with `context.getString`). */
@StringRes
internal fun prayerNameRes(prayer: Prayer): Int = when (prayer) {
    Prayer.IMSAK -> R.string.prayer_dawn
    Prayer.GUNES -> R.string.prayer_sunrise
    Prayer.OGLE -> R.string.prayer_noon
    Prayer.IKINDI -> R.string.prayer_afternoon
    Prayer.AKSAM -> R.string.prayer_sunset
    Prayer.YATSI -> R.string.prayer_night
}

/** Localized prayer display name for Compose. */
@Composable
internal fun prayerName(prayer: Prayer): String = stringResource(prayerNameRes(prayer))

/** Locale-aware uppercase for display labels — so Turkish lowercase i uppercases to İ (not I). */
@Composable
internal fun localeUppercase(text: String): String = text.uppercase(LocalConfiguration.current.locales[0])

/** A filled circle — the palette dot used across Today and Monthly (stands in for the iOS SF symbol). */
@Composable
internal fun Dot(color: Color, diameter: Dp) {
    androidx.compose.foundation.layout.Box(Modifier.size(diameter).clip(CircleShape).background(color))
}
