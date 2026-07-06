package com.olcayertas.namazvakti.data

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import com.olcayertas.namazvakti.domain.Config
import com.olcayertas.namazvakti.ui.theme.ThemeId
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map

private val Context.dataStore: DataStore<Preferences> by preferencesDataStore("settings")

/** Persisted user settings (the app analogue of the iOS UserDefaults values). */
data class Settings(
    val themeId: ThemeId,
    val districtId: String,
    val districtName: String,
    val notificationsEnabled: Boolean,
)

/** Preferences DataStore wrapper. Defaults come from [Config] (Küçükçekmece, Arc). */
class SettingsStore(private val context: Context) {

    private object Keys {
        val theme = stringPreferencesKey("theme_id")
        val districtId = stringPreferencesKey("district_id")
        val districtName = stringPreferencesKey("district_name")
        val notifications = booleanPreferencesKey("notifications_enabled")
    }

    val settings: Flow<Settings> = context.dataStore.data.map { p ->
        Settings(
            themeId = runCatching { ThemeId.valueOf(p[Keys.theme] ?: "") }.getOrDefault(ThemeId.ARC),
            districtId = p[Keys.districtId] ?: Config.DEFAULT_DISTRICT_ID,
            districtName = p[Keys.districtName] ?: Config.DEFAULT_LOCATION_NAME,
            notificationsEnabled = p[Keys.notifications] ?: false,
        )
    }

    suspend fun setTheme(id: ThemeId) = context.dataStore.edit { it[Keys.theme] = id.name }
    suspend fun setDistrict(id: String, name: String) = context.dataStore.edit {
        it[Keys.districtId] = id
        it[Keys.districtName] = name
    }
    suspend fun setNotifications(enabled: Boolean) = context.dataStore.edit { it[Keys.notifications] = enabled }
}
