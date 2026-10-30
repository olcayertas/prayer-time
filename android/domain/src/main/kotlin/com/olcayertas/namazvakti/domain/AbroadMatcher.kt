package com.olcayertas.namazvakti.domain

/**
 * Pure matching of a geocoded place OUTSIDE Türkiye to the EzanVakti hierarchy. The Türkiye path
 * ([LocationMatcher]) is separate and unchanged. Ported from the Swift `AbroadMatcher`; both run the
 * shared golden corpus `shared/golden/abroad-matching.json`.
 *
 * Abroad the hierarchy has a different shape: 198 of 202 countries have ONE "city" that is the whole
 * country, and its districts are the real cities and towns ("MEKKE", "CIDDE", "SARAYBOSNA(sarajevo)").
 * Only the US, Germany and Canada have a state level. District names are Turkish exonyms in ASCII, with
 * an English/local twin in `nameEn`. So matching tries both names, a few verified aliases, and never the
 * province first (Jeddah's province is "Mecca").
 */
object AbroadMatcher {

    /** The address fields the matcher reads. */
    data class Place(
        val isoCountryCode: String? = null,
        val administrativeArea: String? = null,
        val subAdministrativeArea: String? = null,
        val locality: String? = null,
        val subLocality: String? = null,
    )

    /**
     * The EzanVakti city for an abroad place: the only city of a single-city country, else the state that
     * matches `administrativeArea` (by name, English name, or a per-country alias/abbreviation).
     */
    fun matchCity(place: Place, cities: List<City>): City? {
        if (cities.size == 1) return cities[0]
        val area = place.administrativeArea ?: return null
        var key = LocationMatcher.normalize(area)
        stateAliases[place.isoCountryCode?.uppercase().orEmpty()]?.get(key)?.let { key = it }
        if (key.isEmpty()) return null
        return cities
            .filter { city -> listOfNotNull(city.name, city.nameEn).map(LocationMatcher::normalize).contains(key) }
            .minWithOrNull(cityOrder)
    }

    /**
     * Best district for an abroad place, or null when there is no confident match.
     *
     * 1. Exact: locality, then sub-administrative area, then sub-locality, against the full name and the
     *    text before "(" of `name` and `nameEn`.
     * 2. Token prefix: the district name STARTS with the candidate's words ("BANDUNG (JAWA BARAT)" for
     *    "Bandung"), candidate of 4+ letters, and only when exactly one district qualifies.
     * 3. Last: the administrative area exactly (a town with no entry of its own gets its province's
     *    namesake, as the Türkiye matcher does with metropolitan centres).
     * Text inside "( )" is never matched alone: it is sometimes the real name ("SARAYBOSNA(sarajevo)",
     * already covered by `nameEn`) and sometimes only a nearby city ("DORFEN (Munih)").
     */
    fun matchDistrict(place: Place, districts: List<District>): District? {
        val iso = place.isoCountryCode?.uppercase().orEmpty()
        val candidates = listOfNotNull(place.locality, place.subAdministrativeArea, place.subLocality)
            .map { candidateTokens(it, iso) }
            .filter { it.isNotEmpty() }
        val indexed = districts.map { it to districtTokens(it) }

        for (tokens in candidates) {
            val key = tokens.joinToString("")
            indexed.filter { (_, keys) -> keys.any { it.joinToString("") == key } }
                .map { it.first }.minWithOrNull(districtOrder)?.let { return it }
        }
        for (tokens in candidates) {
            if (tokens.joinToString("").length < 4) continue
            val hits = indexed.filter { (_, keys) ->
                keys.any { it.size > tokens.size && it.take(tokens.size) == tokens }
            }.map { it.first }
            if (hits.map { it.id }.toSet().size == 1) return hits[0]
        }
        place.administrativeArea?.let { area ->
            val key = candidateTokens(area, iso).joinToString("")
            if (key.isNotEmpty()) {
                indexed.filter { (_, keys) -> keys.any { it.joinToString("") == key } }
                    .map { it.first }.minWithOrNull(districtOrder)?.let { return it }
            }
        }
        return null
    }

    /** Words of a geocoded name, folded, without administrative words, then through the alias table. */
    fun candidateTokens(raw: String, iso: String): List<String> {
        val words = tokens(raw).filter { it !in adminWords }
        cityAliases[words.joinToString("")]?.let { return listOf(it) }
        return words
    }

    /** Token lists a district answers to: full name and the text before "(", for `name` and `nameEn`. */
    fun districtTokens(district: District): List<List<String>> {
        val keys = mutableListOf<List<String>>()
        for (raw in listOfNotNull(district.name, district.nameEn)) {
            val forms = mutableListOf(tokens(raw))
            val open = raw.indexOf('(')
            if (open >= 0) forms += tokens(raw.substring(0, open))
            for (form in forms) if (form.isNotEmpty() && form !in keys) keys += form
        }
        return keys
    }

    /** Folded words: split on anything that is not a letter or digit, then [LocationMatcher.normalize]. */
    fun tokens(raw: String): List<String> =
        raw.split(Regex("[^\\p{L}\\p{M}\\p{N}]+")).map(LocationMatcher::normalize).filter { it.isNotEmpty() }

    /** Same key, two ids ("SAINT AVOLD" / "SAINT-AVOLD"): the lower numeric id wins, independent of list order. */
    private val cityOrder = compareBy<City>({ it.id.toIntOrNull() ?: Int.MAX_VALUE }, { it.id })
    private val districtOrder = compareBy<District>({ it.id.toIntOrNull() ?: Int.MAX_VALUE }, { it.id })

    /** Words geocoders add to administrative names (en/tr/ar transliterations seen in geocoder output). */
    val adminWords: Set<String> = setOf(
        "governorate", "province", "region", "district", "municipality", "county", "prefecture",
        "muhafazah", "eyaleti",
    )

    /** Geocoder exonym → catalog key. Each row was checked against the live /ilceler data (2026-10-30). */
    val cityAliases: Map<String, String> = mapOf(
        "munich" to "munchen", "nuremberg" to "nurnberg", "cologne" to "koln", "vienna" to "wien",
        "makkah" to "mecca", "makkahalmukarramah" to "mecca", "almukarramah" to "mecca",
        "madinah" to "medina", "almadinah" to "medina", "almadinahalmunawwarah" to "medina",
        "dammam" to "addammam", "hofuf" to "alhufuf",
    )

    /**
     * Per-country state aliases: geocoder abbreviations and English names that differ from the catalog's
     * spelling ("ONTORIO", "BRITISH COLOMBIA", "N.A.L.", "HAVAI ADALARI").
     */
    val stateAliases: Map<String, Map<String, String>> = mapOf(
        "US" to mapOf(
            "al" to "alabama", "ak" to "alaska", "az" to "arizona", "ar" to "arkansas", "ca" to "california",
            "co" to "colorado", "ct" to "connecticut", "dc" to "dc", "districtofcolumbia" to "dc", "de" to "delaware",
            "fl" to "florida", "ga" to "georgia", "hi" to "havaiadalari", "hawaii" to "havaiadalari", "id" to "idaho",
            "il" to "illinois", "in" to "indiana", "ia" to "iowa", "ks" to "kansas", "ky" to "kentucky",
            "la" to "louisiana", "me" to "maine", "md" to "maryland", "ma" to "massachusetts", "mi" to "michigan",
            "mn" to "minnesota", "ms" to "mississippi", "mo" to "missouri", "mt" to "montana", "ne" to "nebraska",
            "nv" to "nevada", "nh" to "newhampshire", "nj" to "newjersey", "nm" to "newmexico", "ny" to "newyork",
            "nc" to "northcarolina", "nd" to "northdakota", "oh" to "ohio", "ok" to "oklahoma", "or" to "oregon",
            "pa" to "pennsylvania", "ri" to "rhodeisland", "sc" to "southcarolina", "sd" to "southdakota",
            "tn" to "tennessee", "tx" to "texas", "ut" to "utah", "vt" to "vermont", "va" to "virginia",
            "wa" to "washington", "wv" to "westvirginia", "wi" to "wisconsin", "wy" to "wyoming",
        ),
        "CA" to mapOf(
            "ab" to "alberta", "bc" to "britishcolombia", "britishcolumbia" to "britishcolombia", "mb" to "manitoba",
            "nl" to "nal", "newfoundlandandlabrador" to "nal", "nb" to "newbrunswick", "nt" to "northwestterritories",
            "ns" to "novascotia", "nu" to "nunavut", "on" to "ontorio", "ontario" to "ontorio", "pe" to "pei",
            "princeedwardisland" to "pei", "qc" to "quebec", "sk" to "saskatchewan",
        ),
        "DE" to mapOf(
            "northrhinewestphalia" to "nordrheinwestfalen", "thuringia" to "thuringen",
            "saxonyanhalt" to "sachsenanhalt", "mecklenburgwesternpomerania" to "mecklenburgvorpommern",
        ),
    )
}

/** EzanVakti country id → ISO code, the reverse of [CountryCodes.ezanVaktiCountryId] (ids are unique). */
fun CountryCodes.isoCode(countryId: String): String? =
    ezanVaktiCountryId.entries.firstOrNull { it.value == countryId }?.key
