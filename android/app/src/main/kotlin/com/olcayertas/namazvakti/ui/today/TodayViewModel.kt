package com.olcayertas.namazvakti.ui.today

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.olcayertas.namazvakti.domain.PrayerSchedule
import com.olcayertas.namazvakti.domain.PrayerTimesRepository
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

sealed interface TodayState {
    data object Loading : TodayState
    data class Loaded(val schedule: PrayerSchedule) : TodayState
    data class Error(val message: String) : TodayState
}

/** Loads the month for [districtId] through the cache-first repository and exposes it as a schedule.
 *  The 1 Hz countdown tick lives in the composable (the schedule is stable within the day). */
class TodayViewModel(
    private val repo: PrayerTimesRepository,
    private val districtId: String,
    val locationName: String,
) : ViewModel() {

    private val _state = MutableStateFlow<TodayState>(TodayState.Loading)
    val state: StateFlow<TodayState> = _state.asStateFlow()

    init { load() }

    fun load() {
        viewModelScope.launch {
            _state.value = try {
                TodayState.Loaded(PrayerSchedule(repo.monthlyTimes(districtId)))
            } catch (e: Exception) {
                TodayState.Error(e.message ?: "Unknown error")
            }
        }
    }
}
