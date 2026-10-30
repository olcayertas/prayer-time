@file:OptIn(androidx.compose.material3.ExperimentalMaterial3Api::class)

package com.olcayertas.namazvakti.ui.settings

import android.Manifest
import android.content.pm.PackageManager
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.core.content.ContextCompat
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Switch
import androidx.compose.material3.SwitchDefaults
import androidx.compose.material3.Text
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.olcayertas.namazvakti.R
import com.olcayertas.namazvakti.data.LocationMode
import com.olcayertas.namazvakti.data.Settings
import com.olcayertas.namazvakti.domain.CalculationMethod
import com.olcayertas.namazvakti.domain.City
import com.olcayertas.namazvakti.domain.LocalMethod
import com.olcayertas.namazvakti.domain.Config
import com.olcayertas.namazvakti.domain.PlacesRepository
import com.olcayertas.namazvakti.domain.foldedForSearch
import com.olcayertas.namazvakti.notifications.NotificationScheduler
import com.olcayertas.namazvakti.ui.localeUppercase
import com.olcayertas.namazvakti.ui.theme.LocalNamazTheme
import com.olcayertas.namazvakti.ui.theme.NamazTheme
import com.olcayertas.namazvakti.ui.theme.ThemeId
import kotlinx.coroutines.launch

@Composable
fun SettingsScreen(
    settings: Settings,
    placesRepository: PlacesRepository,
    onSetTheme: (ThemeId) -> Unit,
    onSetDistrict: (String, String) -> Unit,
    onSetNotifications: (Boolean) -> Unit,
    onSetLocationMode: (LocationMode) -> Unit,
    onSetCalculationMethod: (CalculationMethod) -> Unit,
    modifier: Modifier = Modifier,
) {
    val theme = LocalNamazTheme.current
    val context = LocalContext.current
    var showPicker by remember { mutableStateOf(false) }

    fun hasLocationPermission() =
        ContextCompat.checkSelfPermission(context, Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED ||
            ContextCompat.checkSelfPermission(context, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED
    var locationGranted by remember { mutableStateOf(hasLocationPermission()) }
    val locationPermLauncher = rememberLauncherForActivityResult(ActivityResultContracts.RequestMultiplePermissions()) { result ->
        locationGranted = result.values.any { it }
        if (locationGranted) onSetLocationMode(LocationMode.AUTOMATIC)
    }
    fun selectAutomatic() {
        if (hasLocationPermission()) onSetLocationMode(LocationMode.AUTOMATIC)
        else locationPermLauncher.launch(arrayOf(Manifest.permission.ACCESS_FINE_LOCATION, Manifest.permission.ACCESS_COARSE_LOCATION))
    }

    Column(
        modifier.fillMaxSize().verticalScroll(rememberScrollState()).statusBarsPadding().padding(24.dp),
        verticalArrangement = Arrangement.spacedBy(24.dp),
    ) {
        Text(stringResource(R.string.settings_title), fontFamily = theme.fonts.display, fontWeight = FontWeight.Bold, fontSize = 34.sp, color = theme.text)

        Section(stringResource(R.string.settings_appearance), theme) {
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                SegButton(stringResource(R.string.theme_default), settings.themeId == ThemeId.DEFAULT, Modifier.weight(1f), theme) { onSetTheme(ThemeId.DEFAULT) }
                SegButton(stringResource(R.string.theme_arc), settings.themeId == ThemeId.ARC, Modifier.weight(1f), theme) { onSetTheme(ThemeId.ARC) }
            }
            Text(
                if (settings.themeId == ThemeId.ARC) stringResource(R.string.theme_arc_desc) else stringResource(R.string.theme_default_desc),
                fontFamily = theme.fonts.body, fontSize = 12.sp, color = theme.muted,
            )
        }

        Section(stringResource(R.string.settings_location), theme) {
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                SegButton(stringResource(R.string.location_automatic), settings.locationMode == LocationMode.AUTOMATIC, Modifier.weight(1f), theme) { selectAutomatic() }
                SegButton(stringResource(R.string.location_pinned), settings.locationMode == LocationMode.PINNED, Modifier.weight(1f), theme) { onSetLocationMode(LocationMode.PINNED) }
            }
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween, verticalAlignment = Alignment.CenterVertically) {
                Column {
                    Text(stringResource(R.string.settings_current), fontFamily = theme.fonts.body, fontSize = 12.sp, color = theme.muted)
                    Text(settings.districtName, fontFamily = theme.fonts.body, fontWeight = FontWeight.SemiBold, fontSize = 16.sp, color = theme.text)
                }
                if (settings.locationMode == LocationMode.PINNED) {
                    Pill(stringResource(R.string.action_change), theme) { showPicker = true }
                }
            }
            if (settings.locationMode == LocationMode.AUTOMATIC) {
                Text(
                    stringResource(if (locationGranted) R.string.location_auto_hint else R.string.location_auto_permission),
                    fontFamily = theme.fonts.body, fontSize = 12.sp, color = theme.muted,
                )
            }
        }

        settings.placeContext.localMethod?.let { local ->
            Section(stringResource(R.string.settings_calculation_method), theme) {
                val isLocal = settings.calculationMethod == CalculationMethod.LOCAL
                Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    SegButton(stringResource(R.string.method_diyanet), !isLocal, Modifier.weight(1f), theme) { onSetCalculationMethod(CalculationMethod.DIYANET) }
                    SegButton(stringResource(local.labelRes()), isLocal, Modifier.weight(1f), theme) { onSetCalculationMethod(CalculationMethod.LOCAL) }
                }
                Text(
                    stringResource(if (isLocal) R.string.method_local_desc else R.string.method_diyanet_desc),
                    fontFamily = theme.fonts.body, fontSize = 12.sp, color = theme.muted,
                )
            }
        }

        Section(stringResource(R.string.settings_notifications), theme) {
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween, verticalAlignment = Alignment.CenterVertically) {
                Text(stringResource(R.string.prayer_notifications), fontFamily = theme.fonts.body, fontSize = 16.sp, color = theme.text)
                Switch(
                    checked = settings.notificationsEnabled,
                    onCheckedChange = onSetNotifications,
                    colors = SwitchDefaults.colors(checkedThumbColor = theme.accent, checkedTrackColor = theme.accentSoft),
                )
            }
            val ctx = LocalContext.current
            if (settings.notificationsEnabled && android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.S &&
                !NotificationScheduler(ctx).canScheduleExact()
            ) {
                Text(stringResource(R.string.exact_alarms_hint), fontFamily = theme.fonts.body, fontSize = 12.sp, color = theme.muted)
                Pill(stringResource(R.string.allow_exact_alarms), theme) {
                    ctx.startActivity(
                        android.content.Intent(
                            android.provider.Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM,
                            android.net.Uri.parse("package:" + ctx.packageName),
                        ),
                    )
                }
            }
        }

        val ctx = LocalContext.current
        val version = remember { runCatching { ctx.packageManager.getPackageInfo(ctx.packageName, 0).versionName }.getOrNull() ?: "—" }
        Section(stringResource(R.string.settings_about), theme) {
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                Text(stringResource(R.string.settings_version), fontFamily = theme.fonts.body, fontSize = 15.sp, color = theme.text)
                Text(version, fontFamily = theme.fonts.mono, fontSize = 15.sp, color = theme.muted)
            }
            Text(
                stringResource(R.string.about_source),
                fontFamily = theme.fonts.body, fontSize = 12.sp, color = theme.muted,
            )
        }
    }

    if (showPicker) {
        LocationPickerSheet(
            placesRepository = placesRepository,
            theme = theme,
            onDismiss = { showPicker = false },
            onSelect = { id, name -> onSetDistrict(id, name); showPicker = false },
        )
    }
}

@Composable
private fun Section(title: String, theme: NamazTheme, content: @Composable ColumnScope.() -> Unit) {
    Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
        Text(localeUppercase(title), fontFamily = theme.fonts.body, fontWeight = FontWeight.Bold, fontSize = 11.sp, letterSpacing = 1.5.sp, color = theme.faint)
        Column(
            Modifier.fillMaxWidth().clip(RoundedCornerShape(14.dp)).background(theme.surface).padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(10.dp),
            content = content,
        )
    }
}

@Composable
private fun SegButton(label: String, selected: Boolean, modifier: Modifier, theme: NamazTheme, onClick: () -> Unit) {
    Box(
        modifier.clip(RoundedCornerShape(9.dp)).background(if (selected) theme.accentSoft else theme.elevatedCardTop).clickable(onClick = onClick).padding(vertical = 10.dp),
        contentAlignment = Alignment.Center,
    ) {
        Text(label, color = if (selected) theme.accent else theme.muted, fontFamily = theme.fonts.body, fontWeight = if (selected) FontWeight.SemiBold else FontWeight.Normal, fontSize = 14.sp)
    }
}

@Composable
private fun Pill(label: String, theme: NamazTheme, onClick: () -> Unit) {
    Text(
        label, color = theme.accent, fontFamily = theme.fonts.body, fontWeight = FontWeight.SemiBold, fontSize = 13.sp,
        modifier = Modifier.clip(RoundedCornerShape(50)).background(theme.accentSoft).clickable(onClick = onClick).padding(horizontal = 16.dp, vertical = 8.dp),
    )
}

private fun LocalMethod.labelRes(): Int = when (this) {
    LocalMethod.UMM_AL_QURA -> R.string.method_umm_al_qura
}

private enum class PickStep { CITY, DISTRICT }

/** Searchable city → district picker (Türkiye is the only supported country — the app's focus). */
@Composable
private fun LocationPickerSheet(placesRepository: PlacesRepository, theme: NamazTheme, onDismiss: () -> Unit, onSelect: (String, String) -> Unit) {
    val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)
    val scope = rememberCoroutineScope()
    var step by remember { mutableStateOf(PickStep.CITY) }
    var query by remember { mutableStateOf("") }
    var cities by remember { mutableStateOf<List<City>>(emptyList()) }
    var districts by remember { mutableStateOf<List<Pair<String, String>>>(emptyList()) }
    var cityName by remember { mutableStateOf("") }
    var loading by remember { mutableStateOf(true) }
    var error by remember { mutableStateOf<String?>(null) }

    LaunchedEffect(Unit) {
        try {
            cities = placesRepository.cities(Config.TURKIYE_COUNTRY_ID).sortedBy { it.name.foldedForSearch() }
        } catch (e: Exception) {
            error = e.message
        }
        loading = false
    }

    ModalBottomSheet(onDismissRequest = onDismiss, sheetState = sheetState, containerColor = theme.elevatedCardTop) {
        Column(Modifier.fillMaxWidth().padding(horizontal = 20.dp).padding(bottom = 24.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
            if (step == PickStep.DISTRICT) {
                Text(stringResource(R.string.picker_back_cities), color = theme.accent, fontFamily = theme.fonts.body, modifier = Modifier.clickable { step = PickStep.CITY; query = "" })
            }
            Text(
                if (step == PickStep.CITY) stringResource(R.string.picker_choose_city) else stringResource(R.string.picker_choose_district, cityName),
                fontFamily = theme.fonts.display, fontWeight = FontWeight.SemiBold, fontSize = 20.sp, color = theme.text,
            )
            OutlinedTextField(value = query, onValueChange = { query = it }, placeholder = { Text(stringResource(R.string.action_search)) }, singleLine = true, modifier = Modifier.fillMaxWidth())

            when {
                loading -> Box(Modifier.fillMaxWidth().height(120.dp), contentAlignment = Alignment.Center) { CircularProgressIndicator(color = theme.accent) }
                error != null -> Text(stringResource(R.string.error_load_generic, error!!), color = theme.error, fontFamily = theme.fonts.body)
                else -> LazyColumn(Modifier.fillMaxWidth().heightIn(max = 420.dp)) {
                    if (step == PickStep.CITY) {
                        items(cities.filter { it.name.foldedForSearch().contains(query.foldedForSearch()) }, key = { it.id }) { city ->
                            PickRow(city.name, theme) {
                                scope.launch {
                                    loading = true; error = null; query = ""; cityName = city.name
                                    try {
                                        districts = placesRepository.districts(city.id).sortedBy { it.name.foldedForSearch() }.map { it.id to it.name }
                                        step = PickStep.DISTRICT
                                    } catch (e: Exception) {
                                        error = e.message
                                    }
                                    loading = false
                                }
                            }
                        }
                    } else {
                        items(districts.filter { it.second.foldedForSearch().contains(query.foldedForSearch()) }, key = { it.first }) { (id, name) ->
                            PickRow(name, theme) { onSelect(id, name) }
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun PickRow(name: String, theme: NamazTheme, onClick: () -> Unit) {
    Column {
        Text(name, fontFamily = theme.fonts.body, fontSize = 16.sp, color = theme.text, modifier = Modifier.fillMaxWidth().clickable(onClick = onClick).padding(vertical = 12.dp))
        HorizontalDivider(color = theme.line)
    }
}
