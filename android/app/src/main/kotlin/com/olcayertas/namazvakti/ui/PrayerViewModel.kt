package com.olcayertas.namazvakti.ui

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.olcayertas.namazvakti.domain.PrayerSchedule
import com.olcayertas.namazvakti.domain.PrayerTimesRepository
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

sealed interface PrayerUiState {
    data object Loading : PrayerUiState
    data class Loaded(val schedule: PrayerSchedule) : PrayerUiState
    data class Error(val message: String) : PrayerUiState
}

/**
 * App-wide prayer data: loads the month for [districtId] through the cache-first repository. Shared
 * by the Today and Monthly screens (one load, one cache), so switching tabs never re-fetches. The
 * 1 Hz countdown ticks live in the composables (the schedule is stable within the day).
 */
class PrayerViewModel(
    private val repo: PrayerTimesRepository,
    private val districtId: String,
    val locationName: String,
) : ViewModel() {

    private val _state = MutableStateFlow<PrayerUiState>(PrayerUiState.Loading)
    val state: StateFlow<PrayerUiState> = _state.asStateFlow()

    init { load() }

    fun load() {
        viewModelScope.launch {
            _state.value = try {
                PrayerUiState.Loaded(PrayerSchedule(repo.monthlyTimes(districtId)))
            } catch (e: Exception) {
                PrayerUiState.Error(e.message ?: "Unknown error")
            }
        }
    }
}
