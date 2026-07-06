import Foundation

enum ProviderError: LocalizedError, Sendable {
    case badResponse(Int)
    case noData
    case notImplemented(String)

    var errorDescription: String? {
        switch self {
        case .badResponse(let code):
            return String(localized: "The server returned an unexpected response (HTTP \(code)).")
        case .noData:
            return String(localized: "No data was received from the server.")
        case .notImplemented(let what):
            return String(localized: "\(what) is not implemented yet.")
        }
    }
}

/// A source of monthly prayer times for a Diyanet district.
///
/// EzanVakti is the v1 implementation. The protocol is the seam for swapping in the
/// official Diyanet `AwqatSalah` API later without touching the UI or store.
///
/// `Sendable` so an `any PrayerTimesProvider` can be held by the `@MainActor` store and
/// awaited off the main actor.
protocol PrayerTimesProvider: Sendable {
    func monthlyTimes(districtId: String) async throws -> [PrayerDay]
}

/// Community wrapper around Diyanet's published tables. No auth, no key.
/// `GET https://ezanvakti.emushaf.net/vakitler/{districtId}` → one month of `PrayerDay`.
struct EzanVaktiProvider: PrayerTimesProvider {
    var baseURL = URL(string: "https://ezanvakti.emushaf.net")!
    var session: URLSession = EzanVaktiProvider.makeSession()

    /// Ephemeral session with explicit timeouts (in-process loading, guaranteed failure
    /// instead of an indefinite hang).
    static func makeSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 30
        config.waitsForConnectivity = false
        return URLSession(configuration: config)
    }

    func monthlyTimes(districtId: String) async throws -> [PrayerDay] {
        let url = baseURL.appending(path: "vakitler").appending(path: districtId)
        let (data, response) = try await session.data(from: url)
        try Self.validate(response)
        return try JSONDecoder().decode([PrayerDay].self, from: data)
    }

    /// Throws `ProviderError.badResponse` for non-2xx HTTP statuses; passes everything else.
    static func validate(_ response: URLResponse) throws {
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw ProviderError.badResponse(http.statusCode)
        }
    }
}

/// Seam for the official Diyanet API (https://awqatsalah.diyanet.gov.tr).
///
/// Requires issued credentials and an OAuth flow (access token ~45m / refresh ~15m) plus
/// strict per-endpoint rate limits, so it is not shippable in a client yet. Left as a
/// concrete drop-in target: implement `monthlyTimes` here and inject it into `PrayerStore`.
struct AwqatSalahProvider: PrayerTimesProvider {
    func monthlyTimes(districtId: String) async throws -> [PrayerDay] {
        throw ProviderError.notImplemented("Resmi Diyanet AwqatSalah API")
    }
}
