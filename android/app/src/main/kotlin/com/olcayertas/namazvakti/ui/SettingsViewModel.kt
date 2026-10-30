package com.olcayertas.namazvakti.ui

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.olcayertas.namazvakti.data.LocationMode
import com.olcayertas.namazvakti.data.Settings
import com.olcayertas.namazvakti.data.SettingsStore
import com.olcayertas.namazvakti.domain.CalculationMethod
import com.olcayertas.namazvakti.domain.PlaceContext
import com.olcayertas.namazvakti.ui.theme.ThemeId
import dagger.hilt.android.lifecycle.HiltViewModel
import javax.inject.Inject
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch

/** Exposes persisted [Settings] as state and forwards edits to the [SettingsStore]. */
@HiltViewModel
class SettingsViewModel @Inject constructor(private val store: SettingsStore) : ViewModel() {

    val settings: StateFlow<Settings?> = store.settings.stateIn(viewModelScope, SharingStarted.Eagerly, null)

    fun setTheme(id: ThemeId) { viewModelScope.launch { store.setTheme(id) } }
    fun setDistrict(id: String, name: String, place: PlaceContext) { viewModelScope.launch { store.setDistrict(id, name, place) } }
    fun setCalculationMethod(method: CalculationMethod) { viewModelScope.launch { store.setCalculationMethod(method) } }
    fun setNotifications(enabled: Boolean) { viewModelScope.launch { store.setNotifications(enabled) } }
    fun setLocationMode(mode: LocationMode) { viewModelScope.launch { store.setLocationMode(mode) } }
}
