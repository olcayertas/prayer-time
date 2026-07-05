package com.olcayertas.namazvakti

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CalendarMonth
import androidx.compose.material.icons.filled.WbSunny
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.lifecycle.viewmodel.initializer
import androidx.lifecycle.viewmodel.viewModelFactory
import com.olcayertas.namazvakti.domain.Config
import com.olcayertas.namazvakti.ui.PrayerUiState
import com.olcayertas.namazvakti.ui.PrayerViewModel
import com.olcayertas.namazvakti.ui.monthly.MonthScreen
import com.olcayertas.namazvakti.ui.theme.LocalNamazTheme
import com.olcayertas.namazvakti.ui.theme.NamazTheme
import com.olcayertas.namazvakti.ui.theme.NamazVaktiTheme
import com.olcayertas.namazvakti.ui.theme.ThemeId
import com.olcayertas.namazvakti.ui.theme.themedBackground
import com.olcayertas.namazvakti.ui.today.TodayScreen

private enum class Tab(val label: String, val icon: ImageVector) {
    TODAY("Today", Icons.Filled.WbSunny),
    MONTHLY("Monthly", Icons.Filled.CalendarMonth),
}

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        installSplashScreen()
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        val container = (application as NamazVaktiApp).container
        setContent {
            var themeId by rememberSaveable { mutableStateOf(ThemeId.ARC) }
            var tab by rememberSaveable { mutableStateOf(Tab.TODAY) }
            NamazVaktiTheme(themeId) {
                val theme = LocalNamazTheme.current
                val vm: PrayerViewModel = viewModel(
                    factory = viewModelFactory {
                        initializer {
                            PrayerViewModel(container.prayerTimesRepository, Config.DEFAULT_DISTRICT_ID, Config.DEFAULT_LOCATION_NAME)
                        }
                    },
                )
                val state by vm.state.collectAsState()

                Box(Modifier.fillMaxSize().themedBackground(theme)) {
                    Column(Modifier.fillMaxSize()) {
                        Box(Modifier.fillMaxWidth().weight(1f)) {
                            when (val s = state) {
                                PrayerUiState.Loading -> CircularProgressIndicator(color = theme.accent, modifier = Modifier.align(Alignment.Center))
                                is PrayerUiState.Error -> Text(
                                    "Couldn't load times: ${s.message}",
                                    color = theme.error, fontFamily = theme.fonts.body,
                                    modifier = Modifier.align(Alignment.Center).padding(24.dp),
                                )
                                is PrayerUiState.Loaded -> when (tab) {
                                    Tab.TODAY -> TodayScreen(s.schedule, vm.locationName)
                                    Tab.MONTHLY -> MonthScreen(s.schedule, vm.locationName)
                                }
                            }
                        }
                        NavBar(tab, onSelect = { tab = it }, theme)
                    }
                    ThemeToggle(
                        themeId = themeId,
                        onToggle = { themeId = if (themeId == ThemeId.ARC) ThemeId.DEFAULT else ThemeId.ARC },
                        modifier = Modifier.align(Alignment.TopEnd).statusBarsPadding().padding(12.dp),
                    )
                }
            }
        }
    }
}

@Composable
private fun NavBar(current: Tab, onSelect: (Tab) -> Unit, theme: NamazTheme) {
    Column {
        Box(Modifier.fillMaxWidth().height(1.dp).background(theme.line))
        Row(
            Modifier.fillMaxWidth().background(theme.surface).navigationBarsPadding().padding(vertical = 6.dp),
            horizontalArrangement = Arrangement.SpaceEvenly,
        ) {
            Tab.entries.forEach { t ->
                val selected = t == current
                val tint = if (selected) theme.accent else theme.muted
                Column(
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.spacedBy(2.dp),
                    modifier = Modifier.clip(RoundedCornerShape(12.dp)).clickable { onSelect(t) }.padding(horizontal = 24.dp, vertical = 6.dp),
                ) {
                    Icon(t.icon, contentDescription = t.label, tint = tint, modifier = Modifier.size(22.dp))
                    Text(t.label, color = tint, fontFamily = theme.fonts.body, fontSize = 11.sp, fontWeight = if (selected) FontWeight.SemiBold else FontWeight.Normal)
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
        color = theme.accent, fontFamily = theme.fonts.body,
        modifier = modifier.clip(RoundedCornerShape(50)).background(theme.accentSoft).clickable(onClick = onToggle).padding(horizontal = 14.dp, vertical = 8.dp),
    )
}
