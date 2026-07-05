package com.olcayertas.namazvakti.ui.theme

import android.os.Build
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.dynamicDarkColorScheme
import androidx.compose.material3.dynamicLightColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext

/**
 * Provides the selected [NamazTheme] via [LocalNamazTheme] and a matching Material 3 color scheme.
 * Default = M3 baseline + Material You dynamic color (native look, auto light/dark); Arc = the fixed
 * dark/gold identity (forces dark). Mirrors the iOS theming: Default stays platform-idiomatic, Arc is
 * the cross-platform brand look.
 */
@Composable
fun NamazVaktiTheme(
    themeId: ThemeId = ThemeId.DEFAULT,
    content: @Composable () -> Unit,
) {
    val arc = themeId == ThemeId.ARC
    val systemDark = isSystemInDarkTheme()

    val colorScheme = when {
        arc -> darkColorScheme(
            primary = Color(0xFFE7B873),
            background = Color(0xFF05070F),
            surface = Color(0xFF10152B),
            error = Color(0xFFE0796B),
        )
        Build.VERSION.SDK_INT >= Build.VERSION_CODES.S -> {
            val ctx = LocalContext.current
            if (systemDark) dynamicDarkColorScheme(ctx) else dynamicLightColorScheme(ctx)
        }
        systemDark -> darkColorScheme()
        else -> lightColorScheme()
    }

    val theme = if (arc) arcTheme() else defaultTheme(colorScheme, dark = systemDark)

    CompositionLocalProvider(LocalNamazTheme provides theme) {
        MaterialTheme(colorScheme = colorScheme, content = content)
    }
}
