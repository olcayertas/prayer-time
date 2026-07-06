package com.olcayertas.namazvakti.qibla

import android.Manifest
import android.annotation.SuppressLint
import android.content.Context
import android.content.pm.PackageManager
import android.hardware.GeomagneticField
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.os.Build
import android.os.CancellationSignal
import android.view.Surface
import androidx.core.content.ContextCompat
import com.olcayertas.namazvakti.domain.Qibla
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update

/**
 * Drives the Qibla compass: the device heading from [SensorManager] `TYPE_ROTATION_VECTOR` (magnetic
 * azimuth → **true** north via [GeomagneticField.declination], per the plan's correctness note — we
 * add declination explicitly rather than trusting the sensor's north reference) plus a one-shot
 * coarse location, from which the qibla bearing is derived (great-circle math in `:domain` `Qibla`).
 * Ported from the iOS `QiblaController`. Coarse location only; the caller checks the permission
 * before [start].
 */
class QiblaController(private val context: Context) {

    data class State(
        val latitude: Double? = null,
        val longitude: Double? = null,
        val trueHeading: Double? = null, // degrees, clockwise from true north
        // Assume a good sensor until told otherwise: onAccuracyChanged is device-dependent and on
        // many OEMs is never delivered for the fused rotation-vector sensor. Defaulting to a bad
        // value would pin the "calibrate" hint on-screen forever over a correctly-pointing needle.
        val accuracy: Int = SensorManager.SENSOR_STATUS_ACCURACY_HIGH,
    )

    private val sensorManager = context.getSystemService(SensorManager::class.java)
    private val locationManager = context.getSystemService(LocationManager::class.java)
    private val rotationSensor = sensorManager?.getDefaultSensor(Sensor.TYPE_ROTATION_VECTOR)

    /**
     * Whether this device can show a live compass. `TYPE_ROTATION_VECTOR` is magnetometer-backed, so
     * its presence is the accurate signal (more so than the coarser `FEATURE_SENSOR_COMPASS` feature
     * flag, which some devices — and emulators — omit even with a working virtual magnetometer).
     */
    val hasCompass: Boolean = rotationSensor != null

    private val _state = MutableStateFlow(State())
    val state: StateFlow<State> = _state.asStateFlow()

    private val rotationMatrix = FloatArray(9)
    private val remappedMatrix = FloatArray(9)
    private val orientation = FloatArray(3)
    @Volatile private var declination = 0f
    private var started = false // idempotency guard — lifecycle may deliver ON_RESUME more than once
    private var locationSignal: CancellationSignal? = null

    private val sensorListener = object : SensorEventListener {
        override fun onSensorChanged(event: SensorEvent) {
            SensorManager.getRotationMatrixFromVector(rotationMatrix, event.values)
            // Remap the axes for the current display rotation so the heading stays correct in any
            // orientation (iOS pins the compass to portrait; on Android we compensate explicitly).
            val matrix = when (displayRotation()) {
                Surface.ROTATION_90 -> remap(SensorManager.AXIS_Y, SensorManager.AXIS_MINUS_X)
                Surface.ROTATION_180 -> remap(SensorManager.AXIS_MINUS_X, SensorManager.AXIS_MINUS_Y)
                Surface.ROTATION_270 -> remap(SensorManager.AXIS_MINUS_Y, SensorManager.AXIS_X)
                else -> rotationMatrix
            }
            SensorManager.getOrientation(matrix, orientation)
            val magnetic = Math.toDegrees(orientation[0].toDouble())
            val trueHeading = (magnetic + declination + 360.0) % 360.0
            _state.update { it.copy(trueHeading = trueHeading) }
        }

        override fun onAccuracyChanged(sensor: Sensor?, acc: Int) {
            _state.update { it.copy(accuracy = acc) }
        }
    }

    private val locationListener = LocationListener { onLocation(it, settle = true) }

    /**
     * Apply a fix. [settle] means it came from an active source (a real fix, not a possibly-stale
     * last-known), so we can stop draining the location radios — the qibla bearing doesn't change
     * as you stand still, so one good fix is all the compass needs (keeps the GPS radio off after).
     */
    private fun onLocation(loc: Location, settle: Boolean = false) {
        declination = GeomagneticField(
            loc.latitude.toFloat(), loc.longitude.toFloat(), loc.altitude.toFloat(),
            System.currentTimeMillis(),
        ).declination
        _state.update { it.copy(latitude = loc.latitude, longitude = loc.longitude) }
        if (settle) stopLocationUpdates()
    }

    private fun remap(axisX: Int, axisY: Int): FloatArray {
        SensorManager.remapCoordinateSystem(rotationMatrix, axisX, axisY, remappedMatrix)
        return remappedMatrix
    }

    private fun displayRotation(): Int =
        runCatching { context.display?.rotation ?: Surface.ROTATION_0 }.getOrDefault(Surface.ROTATION_0)

    @SuppressLint("MissingPermission") // caller ensures COARSE or FINE is granted
    fun start() {
        if (!hasCompass || started) return
        started = true
        rotationSensor?.let { sensorManager?.registerListener(sensorListener, it, SensorManager.SENSOR_DELAY_UI) }
        val lm = locationManager ?: return
        val hasFine = ContextCompat.checkSelfPermission(context, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED
        // Every provider the granted precision allows, best-first. GPS needs FINE and is the ONLY
        // fix source on emulators (and on devices with no cached network location), so without it
        // the fix never arrives — the "stuck on Finding your location…" bug. Listen on all of them
        // so whichever delivers first wins.
        val providers = buildList {
            if (hasFine && lm.isProviderEnabled(LocationManager.GPS_PROVIDER)) add(LocationManager.GPS_PROVIDER)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && LocationManager.FUSED_PROVIDER in lm.allProviders) add(LocationManager.FUSED_PROVIDER)
            if (lm.isProviderEnabled(LocationManager.NETWORK_PROVIDER)) add(LocationManager.NETWORK_PROVIDER)
        }.ifEmpty { listOf(LocationManager.PASSIVE_PROVIDER) }
        try {
            // Freshest cached fix across providers for an instant first paint (not settled — it may
            // be stale, so we keep listening for a live one)…
            providers.mapNotNull { runCatching { lm.getLastKnownLocation(it) }.getOrNull() }
                .maxByOrNull { it.time }?.let { onLocation(it) }
            // …an active one-shot on the primary (cancellable so teardown can't leave it pending on a
            // destroyed controller — it captures this instance + the Activity's mainExecutor)…
            locationSignal = CancellationSignal()
            lm.getCurrentLocation(providers.first(), locationSignal, context.mainExecutor) { loc ->
                if (started) loc?.let { onLocation(it, settle = true) }
            }
            // …and continuous updates on each provider.
            providers.forEach { lm.requestLocationUpdates(it, 30_000L, 100f, locationListener) }
        } catch (e: SecurityException) {
            // permission not granted — the UI stays in "locating"
        }
    }

    fun stop() {
        if (!started) return
        started = false
        stopLocationUpdates()
        sensorManager?.unregisterListener(sensorListener)
    }

    /** Cancel the one-shot + continuous location requests, leaving the compass sensor running. */
    private fun stopLocationUpdates() {
        locationSignal?.cancel()
        locationSignal = null
        try {
            locationManager?.removeUpdates(locationListener)
        } catch (e: SecurityException) {
        }
    }

    fun bearing(state: State): Double? =
        if (state.latitude != null && state.longitude != null) Qibla.bearing(state.latitude, state.longitude) else null
}
