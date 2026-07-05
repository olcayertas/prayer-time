package com.olcayertas.namazvakti.ui.theme

import androidx.compose.foundation.background
import androidx.compose.material3.ColorScheme
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.drawWithCache
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontFamily
import com.olcayertas.namazvakti.domain.Prayer

enum class ThemeId { DEFAULT, ARC }

/** Font families per role (mirrors the iOS `Theme.FontRole`). */
data class NamazFonts(val display: FontFamily, val body: FontFamily, val mono: FontFamily)

/**
 * A fully resolved set of color + font tokens for one theme, provided via [LocalNamazTheme] — the
 * Compose analogue of the iOS `Theme` value carried in `\.theme`. Composables read tokens
 * (`theme.accent`, `theme.prayerColor(p)`, `theme.fonts.display`, …) rather than hardcoding colors.
 * The six-prayer palette is shared by both themes (the app's signature); Güneş (sunrise) is dimmed.
 */
data class NamazTheme(
    val nightBackground: Boolean, // Arc → the radial night gradient; Default → solid [baseBackground]
    val baseBackground: Color,
    val surface: Color,
    val elevatedCardTop: Color,
    val elevatedCardBottom: Color,
    val line: Color,
    val lineStrong: Color,
    val text: Color,
    val muted: Color,
    val faint: Color,
    val accent: Color,
    val accentSoft: Color,
    val success: Color,
    val error: Color,
    val prayerPalette: List<Color>,
    val dark: Boolean,
    val fonts: NamazFonts,
) {
    /** Prayer color, with Güneş (sunrise) dimmed — it's informational, never a prayer. */
    fun prayerColor(prayer: Prayer): Color {
        val base = prayerPalette[prayer.ordinal]
        return if (prayer == Prayer.GUNES) base.copy(alpha = 0.5f) else base
    }
}

/** The dawn→dusk arc — shared by both themes. Index = `Prayer.ordinal` (İmsak…Yatsı). */
val SharedPrayerPalette: List<Color> = listOf(
    Color(0xFF6E7AB8), Color(0xFFD7A07C), Color(0xFFF2C84B),
    Color(0xFFE89B4C), Color(0xFFD4663C), Color(0xFF7E6CC0),
)

val LocalNamazTheme = staticCompositionLocalOf<NamazTheme> { error("NamazTheme not provided") }

/** Default theme — maps every token to the Material 3 color scheme (native, auto light/dark). */
fun defaultTheme(cs: ColorScheme, dark: Boolean): NamazTheme = NamazTheme(
    nightBackground = false,
    baseBackground = cs.background,
    surface = cs.surfaceVariant,
    elevatedCardTop = cs.surfaceVariant,
    elevatedCardBottom = cs.surfaceVariant,
    line = cs.onSurface.copy(alpha = 0.08f),
    lineStrong = cs.onSurface.copy(alpha = 0.14f),
    text = cs.onSurface,
    muted = cs.onSurfaceVariant,
    faint = cs.onSurfaceVariant.copy(alpha = 0.55f),
    accent = cs.primary,
    accentSoft = cs.primary.copy(alpha = 0.14f),
    success = Color(0xFF34C759),
    error = cs.error,
    prayerPalette = SharedPrayerPalette,
    dark = dark,
    fonts = NamazFonts(FontFamily.Default, FontFamily.Default, FontFamily.Monospace),
)

/** Arc theme — the fixed dark/gold identity (literal hex + night gradient + bundled fonts). */
fun arcTheme(): NamazTheme = NamazTheme(
    nightBackground = true,
    baseBackground = Color(0xFF05070F),
    surface = Color(0xFF10152B),
    elevatedCardTop = Color(0xFF161D38),
    elevatedCardBottom = Color(0xFF121733),
    line = Color(0xFFE9ECF8).copy(alpha = 0.065f),
    lineStrong = Color(0xFFE9ECF8).copy(alpha = 0.11f),
    text = Color(0xFFEEF0F8),
    muted = Color(0xFF8B92AE),
    faint = Color(0xFF5A6182),
    accent = Color(0xFFE7B873),
    accentSoft = Color(0xFFE7B873).copy(alpha = 0.12f),
    success = Color(0xFF6FCF97),
    error = Color(0xFFE0796B),
    prayerPalette = SharedPrayerPalette,
    dark = true,
    fonts = NamazFonts(Fraunces, HankenGrotesk, SplineSansMono),
)

/** Root background: the Arc night radial gradient (center (50%, −8%)) or a solid Default surface. */
fun Modifier.themedBackground(theme: NamazTheme): Modifier =
    if (theme.nightBackground) {
        drawWithCache {
            val brush = Brush.radialGradient(
                colorStops = arrayOf(
                    0.0f to Color(0xFF131A36),
                    0.46f to Color(0xFF080B1A),
                    1.0f to Color(0xFF05070F),
                ),
                center = Offset(size.width * 0.5f, size.height * -0.08f),
                radius = size.height * 0.95f,
            )
            onDrawBehind { drawRect(brush) }
        }
    } else {
        background(theme.baseBackground)
    }
