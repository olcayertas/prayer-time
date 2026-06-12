import Foundation

enum ProviderError: LocalizedError {
    case badResponse(Int)
    case noData
    case notImplemented(String)

    var errorDescription: String? {
        switch self {
        case .badResponse(let code):
            return "Sunucu beklenmeyen bir yanıt verdi (HTTP \(code))."
        case .noData:
            return "Sunucudan veri alınamadı."
        case .notImplemented(let what):
            return "\(what) henüz uygulanmadı."
        }
    }
}

/// A source of monthly prayer times for a Diyanet district.
///
/// EzanVakti is the v1 implementation. The protocol is the seam for swapping in the
/// official Diyanet `AwqatSalah` API later without touching the UI or store.
///
/// Completion-handler based (not async/await) on purpose: in this menu-bar app the Swift
/// concurrency continuations do not resume reliably, whereas URLSession's delegate queue
/// and GCD do. The completion runs on a background queue.
protocol PrayerTimesProvider {
    func monthlyTimes(districtId: String, completion: @escaping (Result<[PrayerDay], Error>) -> Void)
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

    func monthlyTimes(districtId: String, completion: @escaping (Result<[PrayerDay], Error>) -> Void) {
        let url = baseURL.appending(path: "vakitler").appending(path: districtId)
        let task = session.dataTask(with: url) { data, response, error in
            if let error {
                completion(.failure(error))
                return
            }
            if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
                completion(.failure(ProviderError.badResponse(http.statusCode)))
                return
            }
            guard let data else {
                completion(.failure(ProviderError.noData))
                return
            }
            do {
                let days = try JSONDecoder().decode([PrayerDay].self, from: data)
                completion(.success(days))
            } catch {
                completion(.failure(error))
            }
        }
        task.resume()
    }
}

/// Seam for the official Diyanet API (https://awqatsalah.diyanet.gov.tr).
///
/// Requires issued credentials and an OAuth flow (access token ~45m / refresh ~15m) plus
/// strict per-endpoint rate limits, so it is not shippable in a client yet. Left as a
/// concrete drop-in target: implement `monthlyTimes` here and inject it into `PrayerStore`.
struct AwqatSalahProvider: PrayerTimesProvider {
    func monthlyTimes(districtId: String, completion: @escaping (Result<[PrayerDay], Error>) -> Void) {
        completion(.failure(ProviderError.notImplemented("Resmi Diyanet AwqatSalah API")))
    }
}
