package com.olcayertas.namazvakti.data

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.doublePreferencesKey
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import com.olcayertas.namazvakti.domain.CalculationMethod
import com.olcayertas.namazvakti.domain.Config
import com.olcayertas.namazvakti.domain.PlaceContext
import com.olcayertas.namazvakti.ui.theme.ThemeId
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map

private val Context.dataStore: DataStore<Preferences> by preferencesDataStore("settings")

/** How the current location is chosen. Automatic reverse-geocodes the device location to a Diyanet
 *  district; Pinned uses the district the user picked. Mirrors the iOS `LocationMode`. */
enum class LocationMode { AUTOMATIC, PINNED }

/** Persisted user settings (the app analogue of the iOS UserDefaults values). */
data class Settings(
    val themeId: ThemeId,
    val districtId: String,
    val districtName: String,
    val notificationsEnabled: Boolean,
    val locationMode: LocationMode,
    /** Diyanet (default) or the local authority's method; mirrors the iOS `CalculationMethod`. */
    val calculationMethod: CalculationMethod = CalculationMethod.DIYANET,
    /** Country and coordinates of the selected place, for the local method. */
    val placeContext: PlaceContext = PlaceContext(),
)

/** Preferences DataStore wrapper. Defaults come from [Config] (Küçükçekmece, Arc). */
class SettingsStore(private val context: Context) {

    private object Keys {
        val theme = stringPreferencesKey("theme_id")
        val districtId = stringPreferencesKey("district_id")
        val districtName = stringPreferencesKey("district_name")
        val notifications = booleanPreferencesKey("notifications_enabled")
        val locationMode = stringPreferencesKey("location_mode")
        val calculationMethod = stringPreferencesKey("calculation_method")
        val placeIso = stringPreferencesKey("place_iso_country_code")
        val placeLat = doublePreferencesKey("place_latitude")
        val placeLon = doublePreferencesKey("place_longitude")
    }

    val settings: Flow<Settings> = context.dataStore.data.map { p ->
        Settings(
            themeId = runCatching { ThemeId.valueOf(p[Keys.theme] ?: "") }.getOrDefault(ThemeId.ARC),
            districtId = p[Keys.districtId] ?: Config.DEFAULT_DISTRICT_ID,
            districtName = p[Keys.districtName] ?: Config.DEFAULT_LOCATION_NAME,
            notificationsEnabled = p[Keys.notifications] ?: false,
            locationMode = runCatching { LocationMode.valueOf(p[Keys.locationMode] ?: "") }.getOrDefault(LocationMode.PINNED),
            calculationMethod = runCatching { CalculationMethod.valueOf(p[Keys.calculationMethod] ?: "") }
                .getOrDefault(CalculationMethod.DIYANET),
            placeContext = PlaceContext(p[Keys.placeIso], p[Keys.placeLat], p[Keys.placeLon]),
        )
    }

    suspend fun setTheme(id: ThemeId) = context.dataStore.edit { it[Keys.theme] = id.name }
    /** Saves a district together with its place context in one edit, so no reader sees a mixed state. */
    suspend fun setDistrict(id: String, name: String, place: PlaceContext) = context.dataStore.edit {
        it[Keys.districtId] = id
        it[Keys.districtName] = name
        place.isoCountryCode?.let { iso -> it[Keys.placeIso] = iso } ?: it.remove(Keys.placeIso)
        place.latitude?.let { lat -> it[Keys.placeLat] = lat } ?: it.remove(Keys.placeLat)
        place.longitude?.let { lon -> it[Keys.placeLon] = lon } ?: it.remove(Keys.placeLon)
    }
    suspend fun setCalculationMethod(method: CalculationMethod) =
        context.dataStore.edit { it[Keys.calculationMethod] = method.name }
    suspend fun setNotifications(enabled: Boolean) = context.dataStore.edit { it[Keys.notifications] = enabled }
    suspend fun setLocationMode(mode: LocationMode) = context.dataStore.edit { it[Keys.locationMode] = mode.name }
}
