package com.olcayertas.namazvakti.data

import com.olcayertas.namazvakti.domain.City
import com.olcayertas.namazvakti.domain.Country
import com.olcayertas.namazvakti.domain.District
import com.olcayertas.namazvakti.domain.EzanVaktiJson
import com.olcayertas.namazvakti.domain.PlacesRemote
import com.olcayertas.namazvakti.domain.PrayerDay
import com.olcayertas.namazvakti.domain.PrayerTimesRemote
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.serialization.decodeFromString
import okhttp3.OkHttpClient
import okhttp3.Request
import java.io.IOException

/**
 * The keyless EzanVakti backend, implementing the `:domain` remote seams with OkHttp. (A Retrofit
 * swap is a future nicety — the interfaces make it trivial; OkHttp keeps the v1 build lean.) One GET
 * per endpoint; each body is a JSON array decoded with [EzanVaktiJson] (unknown keys ignored). The
 * blocking call runs on [Dispatchers.IO].
 */
class EzanVaktiRemote(
    private val client: OkHttpClient = OkHttpClient(),
    private val baseUrl: String = "https://ezanvakti.emushaf.net",
) : PrayerTimesRemote, PlacesRemote {

    override suspend fun monthlyTimes(districtId: String): List<PrayerDay> =
        EzanVaktiJson.decodeFromString(fetch("/vakitler/$districtId"))

    override suspend fun countries(): List<Country> =
        EzanVaktiJson.decodeFromString(fetch("/ulkeler"))

    override suspend fun cities(countryId: String): List<City> =
        EzanVaktiJson.decodeFromString(fetch("/sehirler/$countryId"))

    override suspend fun districts(cityId: String): List<District> =
        EzanVaktiJson.decodeFromString(fetch("/ilceler/$cityId"))

    private suspend fun fetch(path: String): String = withContext(Dispatchers.IO) {
        val request = Request.Builder().url("$baseUrl$path").build()
        client.newCall(request).execute().use { response ->
            if (!response.isSuccessful) throw IOException("HTTP ${response.code} for $path")
            response.body?.string() ?: throw IOException("Empty body for $path")
        }
    }
}
