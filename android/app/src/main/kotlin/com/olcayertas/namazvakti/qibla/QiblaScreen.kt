package com.olcayertas.namazvakti.qibla

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.ContextWrapper
import android.content.Intent
import android.content.pm.PackageManager
import android.hardware.SensorManager
import android.net.Uri
import android.provider.Settings
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.drawscope.rotate
import androidx.compose.ui.graphics.nativeCanvas
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.platform.LocalLifecycleOwner
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver
import com.olcayertas.namazvakti.ui.theme.LocalNamazTheme
import com.olcayertas.namazvakti.ui.theme.NamazTheme
import kotlin.math.abs
import kotlin.math.roundToInt
import kotlinx.coroutines.delay

@Composable
fun QiblaScreen(locationName: String, modifier: Modifier = Modifier) {
    val theme = LocalNamazTheme.current
    val context = LocalContext.current
    val activity = remember(context) { context.findActivity() }
    val controller = remember { QiblaController(context) }

    val locationPerms = remember { arrayOf(Manifest.permission.ACCESS_FINE_LOCATION, Manifest.permission.ACCESS_COARSE_LOCATION) }
    fun granted() = locationPerms.any { ContextCompat.checkSelfPermission(context, it) == PackageManager.PERMISSION_GRANTED }

    var hasPermission by remember { mutableStateOf(granted()) }
    var permanentlyDenied by remember { mutableStateOf(false) }
    val permLauncher = rememberLauncherForActivityResult(ActivityResultContracts.RequestMultiplePermissions()) { result ->
        val anyGranted = result.values.any { it } // FINE or COARSE (approximate) is enough
        hasPermission = anyGranted
        // A denial with no rationale prompt means the system won't ask again — route to Settings.
        if (!anyGranted && activity != null) {
            permanentlyDenied = !ActivityCompat.shouldShowRequestPermissionRationale(activity, Manifest.permission.ACCESS_COARSE_LOCATION)
        }
    }

    val lifecycleOwner = LocalLifecycleOwner.current
    DisposableEffect(lifecycleOwner, hasPermission) {
        val observer = LifecycleEventObserver { _, event ->
            when (event) {
                // Re-read on resume so returning from system Settings (where the user may have just
                // granted the permission) recovers the compass without needing Activity recreation.
                Lifecycle.Event.ON_RESUME -> when {
                    granted() -> { permanentlyDenied = false; hasPermission = true; controller.start() }
                    hasPermission -> hasPermission = false
                }
                Lifecycle.Event.ON_PAUSE -> controller.stop()
                else -> Unit
            }
        }
        lifecycleOwner.lifecycle.addObserver(observer)
        if (hasPermission) controller.start()
        onDispose {
            lifecycleOwner.lifecycle.removeObserver(observer)
            controller.stop()
        }
    }

    val state by controller.state.collectAsState()

    Box(modifier.fillMaxSize().statusBarsPadding().padding(24.dp), contentAlignment = Alignment.Center) {
        when {
            !hasPermission && permanentlyDenied -> StatusMessage(
                "Location needed",
                "Enable location access for Prayer Times in Settings to point the compass toward Mecca.",
                theme,
            ) { PillButton("Open settings", theme) { context.openAppSettings() } }

            !hasPermission -> StatusMessage(
                "Find the Qibla",
                "Prayer Times uses your location to point the compass toward the Kaaba in Mecca.",
                theme,
            ) { PillButton("Allow location", theme) { permLauncher.launch(locationPerms) } }

            !controller.hasCompass -> StatusMessage(
                "No compass",
                "This device doesn't have a compass, so the Qibla direction can't be shown here.",
                theme,
            )

            state.latitude == null -> LocatingState(theme) { controller.stop(); controller.start() }

            else -> LiveCompass(state, controller.bearing(state) ?: 0.0, locationName, theme)
        }
    }
}

private fun Context.findActivity(): Activity? {
    var c: Context? = this
    while (c is ContextWrapper) {
        if (c is Activity) return c
        c = c.baseContext
    }
    return null
}

private fun Context.openAppSettings() {
    startActivity(
        Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.fromParts("package", packageName, null))
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
    )
}

@Composable
private fun LocatingState(theme: NamazTheme, onRetry: () -> Unit) {
    // Never hang: if no fix arrives within a grace period (e.g. approximate-only permission with no
    // network provider on API 30), fall back to a retry + guidance instead of an endless spinner. It
    // auto-resolves to the compass the moment a fix lands — the location requests keep running under it.
    var attempt by remember { mutableStateOf(0) }
    var timedOut by remember { mutableStateOf(false) }
    LaunchedEffect(attempt) { timedOut = false; delay(18_000); timedOut = true }

    if (timedOut) {
        StatusMessage(
            "Still searching…",
            "Couldn't get a location fix yet. Make sure location is on — choosing Precise location helps most.",
            theme,
        ) { PillButton("Try again", theme) { onRetry(); attempt++ } }
    } else {
        Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(16.dp)) {
            CircularProgressIndicator(color = theme.accent)
            Text("Finding your location…", color = theme.muted, fontFamily = theme.fonts.body)
        }
    }
}

@Composable
private fun LiveCompass(state: QiblaController.State, bearing: Double, locationName: String, theme: NamazTheme) {
    val heading = state.trueHeading ?: 0.0
    val rotation = bearing - heading
    val aligned = abs((rotation + 540.0) % 360.0 - 180.0) <= 5.0

    val haptic = LocalHapticFeedback.current
    var wasAligned by remember { mutableStateOf(false) }
    LaunchedEffect(aligned) {
        if (aligned && !wasAligned) haptic.performHapticFeedback(HapticFeedbackType.LongPress)
        wasAligned = aligned
    }

    Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(20.dp)) {
        CompassDial(heading, bearing, aligned, theme, Modifier.size(300.dp))
        if (aligned) {
            Text("Facing the Qibla", color = theme.success, fontFamily = theme.fonts.body, fontWeight = FontWeight.SemiBold, fontSize = 18.sp)
        } else {
            Text("${bearing.roundToInt()}° from North", color = theme.text, fontFamily = theme.fonts.mono, fontWeight = FontWeight.SemiBold, fontSize = 22.sp)
        }
        Text(locationName, color = theme.muted, fontFamily = theme.fonts.body, fontSize = 15.sp)
        if (state.accuracy <= SensorManager.SENSOR_STATUS_ACCURACY_LOW) {
            Text("Move your phone in a figure 8 to calibrate the compass.", color = theme.muted, fontFamily = theme.fonts.body, fontSize = 13.sp)
        }
    }
}

@Composable
private fun CompassDial(heading: Double, qiblaBearing: Double, aligned: Boolean, theme: NamazTheme, modifier: Modifier) {
    // Accumulate the shortest signed step so the needle never spins the long way across 0°/360°.
    var display by remember { mutableStateOf(heading) }
    LaunchedEffect(heading) {
        var d = (heading - display) % 360.0
        if (d > 180) d -= 360.0
        if (d < -180) d += 360.0
        display += d
    }
    val animated by animateFloatAsState(display.toFloat(), tween(120), label = "heading")
    val qiblaAngle = qiblaBearing.toFloat() - animated
    val arrowColor = if (aligned) theme.success else theme.accent

    // Reused across frames to avoid per-frame allocation while the needle animates.
    val cardinalPaint = remember { android.graphics.Paint().apply { textAlign = android.graphics.Paint.Align.CENTER; isAntiAlias = true } }
    val arrowPath = remember { Path() }
    val refPath = remember { Path() }

    Box(modifier, contentAlignment = Alignment.Center) {
        Canvas(Modifier.fillMaxSize()) {
            val r = size.minDimension / 2f
            val c = center
            drawCircle(theme.surface, r, c)
            drawCircle(theme.muted.copy(alpha = 0.25f), r, c, style = Stroke(2.dp.toPx()))

            // Rotating rose: ticks + cardinals, so North tracks true north.
            rotate(-animated, c) {
                for (i in 0 until 72) {
                    val major = i % 9 == 0
                    rotate(i / 72f * 360f, c) {
                        drawLine(
                            theme.muted.copy(alpha = if (major) 0.55f else 0.22f),
                            Offset(c.x, 10.dp.toPx()),
                            Offset(c.x, (if (major) 22f else 16f).dp.toPx()),
                            strokeWidth = (if (major) 2f else 1f).dp.toPx(),
                        )
                    }
                }
                cardinalPaint.textSize = 17.dp.toPx()
                listOf("N" to 0f, "E" to 90f, "S" to 180f, "W" to 270f).forEach { (label, ang) ->
                    rotate(ang, c) {
                        cardinalPaint.color = (if (label == "N") theme.error else theme.muted).toArgb()
                        cardinalPaint.isFakeBoldText = label == "N"
                        drawContext.canvas.nativeCanvas.drawText(label, c.x, 42.dp.toPx(), cardinalPaint)
                    }
                }
            }

            // Kaaba marker: an upright cube on the rim in the qibla direction (the arrow's target).
            val theta = Math.toRadians(qiblaAngle.toDouble())
            val markerR = r - 20.dp.toPx()
            val mx = c.x + (markerR * Math.sin(theta)).toFloat()
            val my = c.y - (markerR * Math.cos(theta)).toFloat()
            drawCircle(theme.surface, 15.dp.toPx(), Offset(mx, my))
            val ks = 8.dp.toPx()
            drawRoundRect(
                arrowColor,
                topLeft = Offset(mx - ks, my - ks),
                size = Size(ks * 2f, ks * 2f),
                cornerRadius = CornerRadius(2.5.dp.toPx()),
            )

            // Hero qibla arrow: a notched navigation glyph (like iOS location.north.fill), pointing
            // from the center toward the qibla.
            rotate(qiblaAngle, c) {
                arrowPath.rewind()
                arrowPath.moveTo(c.x, c.y - 46.dp.toPx())               // tip
                arrowPath.lineTo(c.x - 27.dp.toPx(), c.y + 30.dp.toPx()) // left wing
                arrowPath.lineTo(c.x, c.y + 12.dp.toPx())               // bottom notch
                arrowPath.lineTo(c.x + 27.dp.toPx(), c.y + 30.dp.toPx()) // right wing
                arrowPath.close()
                drawPath(arrowPath, arrowColor)
            }

            // Fixed top reference at 12 o'clock — the direction you're facing.
            refPath.rewind()
            refPath.moveTo(c.x, 20.dp.toPx())
            refPath.lineTo(c.x - 7.dp.toPx(), 6.dp.toPx())
            refPath.lineTo(c.x + 7.dp.toPx(), 6.dp.toPx())
            refPath.close()
            drawPath(refPath, theme.muted)
        }

        if (aligned) {
            Text(
                "Qibla", color = theme.success, fontFamily = theme.fonts.body,
                fontWeight = FontWeight.SemiBold, fontSize = 12.sp, modifier = Modifier.offset(y = 46.dp),
            )
        }
    }
}

@Composable
private fun StatusMessage(title: String, message: String, theme: NamazTheme, action: @Composable () -> Unit = {}) {
    Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(14.dp)) {
        Text(title, color = theme.text, fontFamily = theme.fonts.display, fontWeight = FontWeight.SemiBold, fontSize = 22.sp)
        Text(message, color = theme.muted, fontFamily = theme.fonts.body, fontSize = 15.sp, modifier = Modifier.padding(horizontal = 8.dp))
        action()
    }
}

@Composable
private fun PillButton(label: String, theme: NamazTheme, onClick: () -> Unit) {
    Text(
        label, color = theme.accent, fontFamily = theme.fonts.body, fontWeight = FontWeight.SemiBold, fontSize = 15.sp,
        modifier = Modifier.clip(RoundedCornerShape(50)).background(theme.accentSoft).clickable(onClick = onClick).padding(horizontal = 18.dp, vertical = 10.dp),
    )
}
