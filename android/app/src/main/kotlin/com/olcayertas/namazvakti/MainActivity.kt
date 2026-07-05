package com.olcayertas.namazvakti

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.produceState
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import com.olcayertas.namazvakti.domain.Config
import com.olcayertas.namazvakti.domain.Prayer
import com.olcayertas.namazvakti.domain.PrayerDay
import com.olcayertas.namazvakti.domain.PrayerSchedule
import com.olcayertas.namazvakti.domain.PrayerTimesRepository
import com.olcayertas.namazvakti.domain.UpcomingPrayer
import com.olcayertas.namazvakti.ui.theme.NamazVaktiTheme
import java.time.Instant

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        installSplashScreen()
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        val repo = (application as NamazVaktiApp).container.prayerTimesRepository
        setContent {
            NamazVaktiTheme {
                Surface(modifier = Modifier.fillMaxSize()) { TodayScreen(repo) }
            }
        }
    }
}

private sealed interface TodayUi {
    data object Loading : TodayUi
    data class Loaded(val today: PrayerDay?, val upcoming: UpcomingPrayer?) : TodayUi
    data class Error(val message: String) : TodayUi
}

/**
 * Phase 2 smoke screen — fetches the real month for the default district through the repository
 * (network → cache → freshness) and shows today's times. The polished Today screen (ViewModel, live
 * countdown, the Focus Card, and both themes) arrives in Phase 3.
 */
@Composable
private fun TodayScreen(repo: PrayerTimesRepository) {
    val state by produceState<TodayUi>(TodayUi.Loading) {
        value = try {
            val schedule = PrayerSchedule(repo.monthlyTimes(Config.DEFAULT_DISTRICT_ID))
            val now = Instant.now()
            TodayUi.Loaded(schedule.day(now), schedule.upcoming(now))
        } catch (e: Exception) {
            TodayUi.Error(e.message ?: "Unknown error")
        }
    }

    Column(
        modifier = Modifier.fillMaxSize().padding(24.dp),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Text("Namaz Vakti", style = MaterialTheme.typography.headlineMedium)
        Text(Config.DEFAULT_LOCATION_NAME, style = MaterialTheme.typography.titleMedium)
        Spacer(Modifier.height(16.dp))
        when (val s = state) {
            TodayUi.Loading -> CircularProgressIndicator()
            is TodayUi.Error -> Text(
                "Couldn't load times: ${s.message}",
                color = MaterialTheme.colorScheme.error,
            )
            is TodayUi.Loaded -> {
                val today = s.today
                if (today == null) {
                    Text("No times for today in the loaded month.")
                } else {
                    today.miladiTarihUzun?.let { Text(it, style = MaterialTheme.typography.bodyMedium) }
                    Spacer(Modifier.height(12.dp))
                    Prayer.entries.forEach { prayer ->
                        Row(
                            modifier = Modifier.fillMaxWidth().padding(vertical = 3.dp),
                            horizontalArrangement = Arrangement.SpaceBetween,
                        ) {
                            Text(
                                prayer.name,
                                color = if (prayer.isInformational) {
                                    MaterialTheme.colorScheme.onSurfaceVariant
                                } else {
                                    MaterialTheme.colorScheme.onSurface
                                },
                            )
                            Text(today.time(prayer))
                        }
                    }
                    s.upcoming?.let {
                        Spacer(Modifier.height(12.dp))
                        Text(
                            "Next: ${it.prayer.name}",
                            style = MaterialTheme.typography.titleSmall,
                            color = MaterialTheme.colorScheme.primary,
                        )
                    }
                }
            }
        }
    }
}
