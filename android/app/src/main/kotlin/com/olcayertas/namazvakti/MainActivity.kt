package com.olcayertas.namazvakti

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import com.olcayertas.namazvakti.domain.Qibla
import com.olcayertas.namazvakti.ui.theme.NamazVaktiTheme
import kotlin.math.roundToInt

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        installSplashScreen()
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            NamazVaktiTheme {
                Surface(modifier = Modifier.fillMaxSize()) {
                    Phase0Screen()
                }
            }
        }
    }
}

/**
 * Phase 0 smoke screen — deliberately trivial. Its one job is to prove the wiring is real:
 * `:app` depends on `:domain` and calls the ported [Qibla] math. It is replaced by the real Today
 * screen in Phase 3.
 */
@Composable
private fun Phase0Screen() {
    val bearing = Qibla.bearing(latitude = 41.00, longitude = 28.78) // Küçükçekmece (the default)
    Column(
        modifier = Modifier.fillMaxSize().padding(24.dp),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Text("Namaz Vakti", style = MaterialTheme.typography.headlineMedium)
        Spacer(Modifier.height(8.dp))
        Text("Android · Phase 0 scaffold", style = MaterialTheme.typography.bodyMedium)
        Spacer(Modifier.height(24.dp))
        Text("Qibla from Küçükçekmece", style = MaterialTheme.typography.labelLarge)
        Text("${bearing.roundToInt()}° from north", style = MaterialTheme.typography.displaySmall)
    }
}

@Preview(showBackground = true)
@Composable
private fun Phase0ScreenPreview() = NamazVaktiTheme { Phase0Screen() }
