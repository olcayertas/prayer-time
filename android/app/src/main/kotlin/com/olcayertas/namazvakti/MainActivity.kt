package com.olcayertas.namazvakti

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.ui.platform.LocalContext
import androidx.core.content.ContextCompat
import com.olcayertas.namazvakti.notifications.NotificationScheduler
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
import androidx.compose.material.icons.filled.Explore
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
import androidx.annotation.StringRes
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import androidx.hilt.navigation.compose.hiltViewModel
import com.olcayertas.namazvakti.data.LocationMode
import com.olcayertas.namazvakti.domain.PlaceContext
import com.olcayertas.namazvakti.domain.PlacesRepository
import com.olcayertas.namazvakti.location.AutoLocation
import dagger.hilt.android.AndroidEntryPoint
import javax.inject.Inject
import com.olcayertas.namazvakti.ui.PrayerUiState
import com.olcayertas.namazvakti.ui.PrayerViewModel
import com.olcayertas.namazvakti.ui.SettingsViewModel
import com.olcayertas.namazvakti.qibla.QiblaScreen
import com.olcayertas.namazvakti.ui.monthly.MonthScreen
import com.olcayertas.namazvakti.ui.settings.SettingsScreen
import com.olcayertas.namazvakti.ui.theme.NamazTheme
import com.olcayertas.namazvakti.ui.theme.LocalNamazTheme
import com.olcayertas.namazvakti.ui.theme.NamazVaktiTheme
import com.olcayertas.namazvakti.ui.theme.ThemeId
import com.olcayertas.namazvakti.ui.theme.themedBackground
import androidx.glance.appwidget.updateAll
import com.olcayertas.namazvakti.ui.today.TodayScreen
import com.olcayertas.namazvakti.widget.PrayerWidget

private enum class Tab(@StringRes val labelRes: Int, val icon: ImageVector) {
    TODAY(R.string.tab_today, Icons.Filled.WbSunny),
    MONTHLY(R.string.tab_monthly, Icons.Filled.CalendarMonth),
    QIBLA(R.string.tab_qibla, Icons.Filled.Explore),
    SETTINGS(R.string.tab_settings, Icons.Filled.Settings),
}

@AndroidEntryPoint
class MainActivity : ComponentActivity() {
    @Inject lateinit var placesRepository: PlacesRepository
    @Inject lateinit var autoLocation: AutoLocation

    override fun onCreate(savedInstanceState: Bundle?) {
        installSplashScreen()
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            val settingsVm: SettingsViewModel = hiltViewModel()
            val settings by settingsVm.settings.collectAsState()
            val s = settings

            NamazVaktiTheme(themeId = s?.themeId ?: ThemeId.ARC) {
                val theme = LocalNamazTheme.current
                Box(Modifier.fillMaxSize().themedBackground(theme)) {
                    if (s == null) {
                        CircularProgressIndicator(color = theme.accent, modifier = Modifier.align(Alignment.Center))
                    } else {
                        var tab by rememberSaveable { mutableStateOf(Tab.TODAY) }
                        val prayerVm: PrayerViewModel = hiltViewModel()
                        LaunchedEffect(s.districtId, s.districtName, s.calculationMethod, s.placeContext) {
                            prayerVm.ensureLoaded(s.districtId, s.districtName, s.calculationMethod, s.placeContext)
                        }

                        // Automatic location: reverse-geocode the device location to a Diyanet
                        // district and pin it (which triggers the reload above). No-op without a
                        // fix / permission / match — keeps the current district.
                        LaunchedEffect(s.locationMode) {
                            if (s.locationMode == LocationMode.AUTOMATIC) {
                                autoLocation.resolve()?.let { match ->
                                    if (match.districtId != s.districtId || !match.place.isNear(s.placeContext)) {
                                        settingsVm.setDistrict(match.districtId, match.districtName, match.place)
                                    }
                                }
                            }
                        }
                        val prayerState by prayerVm.state.collectAsState()

                        // Notifications: request POST_NOTIFICATIONS when enabled, and (re)schedule /
                        // cancel the prayer alarms as the toggle + loaded schedule change.
                        val context = LocalContext.current
                        val notifPermLauncher = rememberLauncherForActivityResult(ActivityResultContracts.RequestPermission()) { }
                        LaunchedEffect(s.notificationsEnabled) {
                            if (s.notificationsEnabled && Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
                                ContextCompat.checkSelfPermission(context, Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED
                            ) {
                                notifPermLauncher.launch(Manifest.permission.POST_NOTIFICATIONS)
                            }
                        }
                        LaunchedEffect(s.notificationsEnabled, prayerState) {
                            val scheduler = NotificationScheduler(context)
                            val ps = prayerState
                            if (s.notificationsEnabled && ps is PrayerUiState.Loaded) scheduler.schedule(ps.schedule, ps.locationName)
                            else if (!s.notificationsEnabled) scheduler.cancelAll()
                            if (ps is PrayerUiState.Loaded) PrayerWidget().updateAll(context) // refresh the home-screen widget
                        }

                        Column(Modifier.fillMaxSize()) {
                            Box(Modifier.fillMaxWidth().weight(1f)) {
                                when (tab) {
                                    Tab.SETTINGS -> SettingsScreen(
                                        settings = s,
                                        placesRepository = placesRepository,
                                        onSetTheme = settingsVm::setTheme,
                                        // The Android picker lists Türkiye only, so a pinned place is Turkish.
                                        onSetDistrict = { id, name -> settingsVm.setDistrict(id, name, PlaceContext("TR")) },
                                        onSetCalculationMethod = settingsVm::setCalculationMethod,
                                        onSetNotifications = settingsVm::setNotifications,
                                        onSetLocationMode = settingsVm::setLocationMode,
                                    )
                                    Tab.QIBLA -> QiblaScreen(locationName = s.districtName)
                                    Tab.TODAY, Tab.MONTHLY -> when (val ps = prayerState) {
                                        PrayerUiState.Loading -> CircularProgressIndicator(color = theme.accent, modifier = Modifier.align(Alignment.Center))
                                        is PrayerUiState.Error -> Text(
                                            stringResource(R.string.error_load_times, ps.message),
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
                val label = stringResource(t.labelRes)
                Column(
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.spacedBy(2.dp),
                    modifier = Modifier.clip(RoundedCornerShape(12.dp)).clickable { onSelect(t) }.padding(horizontal = 18.dp, vertical = 6.dp),
                ) {
                    Icon(t.icon, contentDescription = label, tint = tint, modifier = Modifier.size(22.dp))
                    Text(label, color = tint, fontFamily = theme.fonts.body, fontSize = 11.sp, fontWeight = if (selected) FontWeight.SemiBold else FontWeight.Normal)
                }
            }
        }
    }
}

/** Same country and within ~1 km: no need to rewrite the stored place (avoids a reload on every fix). */
private fun PlaceContext.isNear(other: PlaceContext): Boolean {
    if (isoCountryCode != other.isoCountryCode) return false
    val lat = latitude ?: return other.latitude == null
    val lon = longitude ?: return other.longitude == null
    val oLat = other.latitude ?: return false
    val oLon = other.longitude ?: return false
    return kotlin.math.abs(lat - oLat) < 0.01 && kotlin.math.abs(lon - oLon) < 0.01
}
