package com.olcayertas.namazvakti.ui

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.olcayertas.namazvakti.domain.PrayerSchedule
import com.olcayertas.namazvakti.domain.PrayerTimesRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import javax.inject.Inject
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

sealed interface PrayerUiState {
    data object Loading : PrayerUiState
    data class Loaded(val schedule: PrayerSchedule, val locationName: String) : PrayerUiState
    data class Error(val message: String) : PrayerUiState
}

/**
 * App-wide prayer data: loads the month for the selected district through the cache-first repository.
 * Shared by the Today and Monthly screens (one load, one cache). Reloads when the district changes;
 * the 1 Hz countdown ticks live in the composables.
 */
@HiltViewModel
class PrayerViewModel @Inject constructor(private val repo: PrayerTimesRepository) : ViewModel() {

    private val _state = MutableStateFlow<PrayerUiState>(PrayerUiState.Loading)
    val state: StateFlow<PrayerUiState> = _state.asStateFlow()

    private var loadedDistrict: String? = null

    /** Fetch the month for [districtId] unless it's already loaded (idempotent per district). */
    fun ensureLoaded(districtId: String, locationName: String) {
        if (districtId == loadedDistrict && _state.value is PrayerUiState.Loaded) return
        loadedDistrict = districtId
        viewModelScope.launch {
            _state.value = PrayerUiState.Loading
            _state.value = try {
                PrayerUiState.Loaded(PrayerSchedule(repo.monthlyTimes(districtId)), locationName)
            } catch (e: Exception) {
                loadedDistrict = null // let a later attempt retry
                PrayerUiState.Error(e.message ?: "Unknown error")
            }
        }
    }
}
