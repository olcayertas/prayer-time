package com.olcayertas.namazvakti.domain

/** The location hierarchy (country → city → district) from [PlacesRemote]. Thin for now — a cache
 *  can be layered on later; the lists are small and change rarely. */
interface PlacesRepository {
    suspend fun countries(): List<Country>
    suspend fun cities(countryId: String): List<City>
    suspend fun districts(cityId: String): List<District>
}

class DefaultPlacesRepository(private val remote: PlacesRemote) : PlacesRepository {
    override suspend fun countries(): List<Country> = remote.countries()
    override suspend fun cities(countryId: String): List<City> = remote.cities(countryId)
    override suspend fun districts(cityId: String): List<District> = remote.districts(cityId)
}
