package com.olcayertas.namazvakti.domain

/**
 * Raw network sources behind the repositories — the seam that lets the keyless EzanVakti backend be
 * swapped for the official Diyanet AwqatSalah OAuth API later (mirrors the Swift `PrayerTimesProvider`
 * / `PlacesProvider` protocols). Impls live in `:app` (Retrofit). Suspending; throw on transport error.
 */
interface PrayerTimesRemote {
    /** One month of times for a district (`/vakitler/{id}`). */
    suspend fun monthlyTimes(districtId: String): List<PrayerDay>
}

interface PlacesRemote {
    suspend fun countries(): List<Country>                 // /ulkeler
    suspend fun cities(countryId: String): List<City>      // /sehirler/{countryId}
    suspend fun districts(cityId: String): List<District>  // /ilceler/{cityId}
}
