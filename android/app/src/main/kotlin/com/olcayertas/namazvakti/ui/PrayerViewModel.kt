package com.olcayertas.namazvakti.ui

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.olcayertas.namazvakti.domain.CalculationMethod
import com.olcayertas.namazvakti.domain.EffectiveTimes
import com.olcayertas.namazvakti.domain.PlaceContext
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

    private var loadedKey: Any? = null

    /**
     * Fetch the month for [districtId] unless it's already loaded with the same method and place
     * (idempotent). The raw Diyanet month goes through [EffectiveTimes] for the calculation method.
     */
    fun ensureLoaded(
        districtId: String,
        locationName: String,
        method: CalculationMethod = CalculationMethod.DIYANET,
        place: PlaceContext = PlaceContext(),
    ) {
        val key = listOf(districtId, locationName, method, place)
        if (key == loadedKey && _state.value is PrayerUiState.Loaded) return
        loadedKey = key
        viewModelScope.launch {
            _state.value = PrayerUiState.Loading
            _state.value = try {
                val days = EffectiveTimes.days(repo.monthlyTimes(districtId), method, place)
                PrayerUiState.Loaded(PrayerSchedule(days), locationName)
            } catch (e: Exception) {
                loadedKey = null // let a later attempt retry
                PrayerUiState.Error(e.message ?: "Unknown error")
            }
        }
    }
}
