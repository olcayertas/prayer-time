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
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CalendarMonth
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material.icons.filled.WbSunny
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.lifecycle.viewmodel.initializer
import androidx.lifecycle.viewmodel.viewModelFactory
import com.olcayertas.namazvakti.ui.PrayerUiState
import com.olcayertas.namazvakti.ui.PrayerViewModel
import com.olcayertas.namazvakti.ui.SettingsViewModel
import com.olcayertas.namazvakti.ui.monthly.MonthScreen
import com.olcayertas.namazvakti.ui.settings.SettingsScreen
import com.olcayertas.namazvakti.ui.theme.NamazTheme
import com.olcayertas.namazvakti.ui.theme.LocalNamazTheme
import com.olcayertas.namazvakti.ui.theme.NamazVaktiTheme
import com.olcayertas.namazvakti.ui.theme.ThemeId
import com.olcayertas.namazvakti.ui.theme.themedBackground
import com.olcayertas.namazvakti.ui.today.TodayScreen

private enum class Tab(val label: String, val icon: ImageVector) {
    TODAY("Today", Icons.Filled.WbSunny),
    MONTHLY("Monthly", Icons.Filled.CalendarMonth),
    SETTINGS("Settings", Icons.Filled.Settings),
}

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        installSplashScreen()
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        val container = (application as NamazVaktiApp).container
        setContent {
            val settingsVm: SettingsViewModel = viewModel(factory = viewModelFactory {
                initializer { SettingsViewModel(container.settingsStore) }
            })
            val settings by settingsVm.settings.collectAsState()
            val s = settings

            NamazVaktiTheme(themeId = s?.themeId ?: ThemeId.ARC) {
                val theme = LocalNamazTheme.current
                Box(Modifier.fillMaxSize().themedBackground(theme)) {
                    if (s == null) {
                        CircularProgressIndicator(color = theme.accent, modifier = Modifier.align(Alignment.Center))
                    } else {
                        var tab by rememberSaveable { mutableStateOf(Tab.TODAY) }
                        val prayerVm: PrayerViewModel = viewModel(factory = viewModelFactory {
                            initializer { PrayerViewModel(container.prayerTimesRepository) }
                        })
                        LaunchedEffect(s.districtId, s.districtName) { prayerVm.ensureLoaded(s.districtId, s.districtName) }
                        val prayerState by prayerVm.state.collectAsState()

                        Column(Modifier.fillMaxSize()) {
                            Box(Modifier.fillMaxWidth().weight(1f)) {
                                when (tab) {
                                    Tab.SETTINGS -> SettingsScreen(
                                        settings = s,
                                        placesRepository = container.placesRepository,
                                        onSetTheme = settingsVm::setTheme,
                                        onSetDistrict = settingsVm::setDistrict,
                                        onSetNotifications = settingsVm::setNotifications,
                                    )
                                    Tab.TODAY, Tab.MONTHLY -> when (val ps = prayerState) {
                                        PrayerUiState.Loading -> CircularProgressIndicator(color = theme.accent, modifier = Modifier.align(Alignment.Center))
                                        is PrayerUiState.Error -> Text(
                                            "Couldn't load times: ${ps.message}",
                                            color = theme.error, fontFamily = theme.fonts.body,
                                            modifier = Modifier.align(Alignment.Center).padding(24.dp),
                                        )
                                        is PrayerUiState.Loaded ->
                                            if (tab == Tab.TODAY) TodayScreen(ps.schedule, ps.locationName)
                                            else MonthScreen(ps.schedule, ps.locationName)
                                    }
                                }
                            }
                            NavBar(tab, onSelect = { tab = it }, theme)
                        }
                    }
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
                    modifier = Modifier.clip(RoundedCornerShape(12.dp)).clickable { onSelect(t) }.padding(horizontal = 18.dp, vertical = 6.dp),
                ) {
                    Icon(t.icon, contentDescription = t.label, tint = tint, modifier = Modifier.size(22.dp))
                    Text(t.label, color = tint, fontFamily = theme.fonts.body, fontSize = 11.sp, fontWeight = if (selected) FontWeight.SemiBold else FontWeight.Normal)
                }
            }
        }
    }
}
