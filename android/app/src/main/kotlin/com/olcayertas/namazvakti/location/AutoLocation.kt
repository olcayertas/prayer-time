package com.olcayertas.namazvakti.location

import android.Manifest
import android.annotation.SuppressLint
import android.content.Context
import android.content.pm.PackageManager
import android.location.Address
import android.location.Geocoder
import android.location.Location
import android.location.LocationManager
import android.os.Build
import android.os.CancellationSignal
import androidx.core.content.ContextCompat
import com.olcayertas.namazvakti.domain.Config
import com.olcayertas.namazvakti.domain.LocationMatcher
import com.olcayertas.namazvakti.domain.PlacesRepository
import kotlinx.coroutines.suspendCancellableCoroutine
import java.util.Locale
import kotlin.coroutines.resume

/**
 * Reverse-geocodes the device location to a Diyanet district (Automatic location mode). Online path:
 * the platform [Geocoder] → province/ilçe names → [LocationMatcher] against the EzanVakti hierarchy.
 * Gracefully returns null (the caller keeps the pinned district) when there's no permission, no fix,
 * no geocoder backend (de-Googled devices), or no match. A bundled district-centroid offline
 * geocoder for the no-Geocoder case is a follow-up — it needs the centroid dataset.
 */
class AutoLocation(private val context: Context, private val places: PlacesRepository) {

    data class Match(val districtId: String, val districtName: String)

    fun hasPermission(): Boolean =
        ContextCompat.checkSelfPermission(context, Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED ||
            ContextCompat.checkSelfPermission(context, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED

    suspend fun resolve(): Match? {
        if (!hasPermission()) return null
        val location = currentLocation() ?: return null
        val address = reverseGeocode(location.latitude, location.longitude) ?: return null
        val province = address.adminArea
        val district = address.subAdminArea ?: address.locality
        val cities = runCatching { places.cities(Config.TURKIYE_COUNTRY_ID) }.getOrNull() ?: return null
        val city = LocationMatcher.matchCity(province, cities) ?: return null
        val districts = runCatching { places.districts(city.id) }.getOrNull() ?: return null
        val match = LocationMatcher.bestMatch(province, district, districts) ?: return null
        return Match(match.id, match.name)
    }

    private suspend fun reverseGeocode(lat: Double, lon: Double): Address? {
        if (!Geocoder.isPresent()) return null
        val geocoder = Geocoder(context, Locale("tr")) // Turkish names, to match the EzanVakti catalog
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            suspendCancellableCoroutine { cont ->
                geocoder.getFromLocation(lat, lon, 1, object : Geocoder.GeocodeListener {
                    override fun onGeocode(addresses: MutableList<Address>) { cont.resume(addresses.firstOrNull()) }
                    override fun onError(errorMessage: String?) { cont.resume(null) } // else the coroutine hangs
                })
            }
        } else {
            @Suppress("DEPRECATION")
            runCatching { geocoder.getFromLocation(lat, lon, 1)?.firstOrNull() }.getOrNull()
        }
    }

    @SuppressLint("MissingPermission") // hasPermission() is checked in resolve()
    private suspend fun currentLocation(): Location? {
        val lm = context.getSystemService(LocationManager::class.java) ?: return null
        val hasFine = ContextCompat.checkSelfPermission(context, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED
        val provider = when {
            hasFine && lm.isProviderEnabled(LocationManager.GPS_PROVIDER) -> LocationManager.GPS_PROVIDER
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && LocationManager.FUSED_PROVIDER in lm.allProviders -> LocationManager.FUSED_PROVIDER
            lm.isProviderEnabled(LocationManager.NETWORK_PROVIDER) -> LocationManager.NETWORK_PROVIDER
            else -> LocationManager.PASSIVE_PROVIDER
        }
        runCatching { lm.getLastKnownLocation(provider) }.getOrNull()?.let { return it }
        return suspendCancellableCoroutine { cont ->
            val signal = CancellationSignal()
            cont.invokeOnCancellation { signal.cancel() }
            try {
                lm.getCurrentLocation(provider, signal, context.mainExecutor) { loc -> cont.resume(loc) }
            } catch (e: SecurityException) {
                cont.resume(null)
            }
        }
    }
}
