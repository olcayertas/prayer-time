@file:OptIn(androidx.compose.ui.text.ExperimentalTextApi::class)

package com.olcayertas.namazvakti.ui.theme

import androidx.compose.ui.text.font.Font
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontVariation
import androidx.compose.ui.text.font.FontWeight
import com.olcayertas.namazvakti.R

// The bundled Arc fonts — variable .ttf in res/font, the same files the iOS app bundles.
// Each family exposes the weights the UI uses (the variable "wght" axis drives them).

private fun variable(resId: Int, weight: FontWeight, axis: Int) =
    Font(resId, weight = weight, variationSettings = FontVariation.Settings(FontVariation.weight(axis)))

private fun family(resId: Int) = FontFamily(
    variable(resId, FontWeight.Normal, 400),
    variable(resId, FontWeight.Medium, 500),
    variable(resId, FontWeight.SemiBold, 600),
    variable(resId, FontWeight.Bold, 700),
)

val Fraunces: FontFamily = family(R.font.fraunces)             // display — headings / hero name
val HankenGrotesk: FontFamily = family(R.font.hanken_grotesk)  // body
val SplineSansMono: FontFamily = family(R.font.spline_sans_mono) // mono — all numerals / times / countdown
