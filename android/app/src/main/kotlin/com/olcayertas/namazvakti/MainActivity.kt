package com.olcayertas.namazvakti

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.systemBarsPadding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.unit.dp
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.lifecycle.viewmodel.initializer
import androidx.lifecycle.viewmodel.viewModelFactory
import com.olcayertas.namazvakti.domain.Config
import com.olcayertas.namazvakti.ui.theme.LocalNamazTheme
import com.olcayertas.namazvakti.ui.theme.NamazVaktiTheme
import com.olcayertas.namazvakti.ui.theme.ThemeId
import com.olcayertas.namazvakti.ui.today.TodayScreen
import com.olcayertas.namazvakti.ui.today.TodayViewModel

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        installSplashScreen()
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        val container = (application as NamazVaktiApp).container
        setContent {
            // Default to Arc so the app opens on the distinctive dark/gold identity; the toggle
            // (top-right) flips to the native Material "Default" look. Persistence of the choice
            // moves to Settings + DataStore in a later phase.
            var themeId by rememberSaveable { mutableStateOf(ThemeId.ARC) }
            NamazVaktiTheme(themeId) {
                val vm: TodayViewModel = viewModel(
                    factory = viewModelFactory {
                        initializer {
                            TodayViewModel(
                                container.prayerTimesRepository,
                                Config.DEFAULT_DISTRICT_ID,
                                Config.DEFAULT_LOCATION_NAME,
                            )
                        }
                    },
                )
                Box(Modifier.fillMaxSize()) {
                    TodayScreen(vm)
                    ThemeToggle(
                        themeId = themeId,
                        onToggle = { themeId = if (themeId == ThemeId.ARC) ThemeId.DEFAULT else ThemeId.ARC },
                        modifier = Modifier.align(Alignment.TopEnd).systemBarsPadding().padding(12.dp),
                    )
                }
            }
        }
    }
}

@Composable
private fun ThemeToggle(themeId: ThemeId, onToggle: () -> Unit, modifier: Modifier = Modifier) {
    val theme = LocalNamazTheme.current
    Text(
        text = if (themeId == ThemeId.ARC) "Arc" else "Default",
        color = theme.accent,
        fontFamily = theme.fonts.body,
        modifier = modifier
            .clip(RoundedCornerShape(50))
            .background(theme.accentSoft)
            .clickable(onClick = onToggle)
            .padding(horizontal = 14.dp, vertical = 8.dp),
    )
}
