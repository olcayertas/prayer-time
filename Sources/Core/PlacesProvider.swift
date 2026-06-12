import Foundation

/// Looks up the EzanVakti location hierarchy for the location picker.
/// Completion handlers fire on a background queue (same convention as `PrayerTimesProvider`).
protocol PlacesProvider {
    func countries(completion: @escaping (Result<[Country], Error>) -> Void)
    func cities(countryId: String, completion: @escaping (Result<[City], Error>) -> Void)
    func districts(cityId: String, completion: @escaping (Result<[District], Error>) -> Void)
}

extension EzanVaktiProvider: PlacesProvider {
    func countries(completion: @escaping (Result<[Country], Error>) -> Void) {
        fetchList(path: ["ulkeler"], completion: completion)
    }

    func cities(countryId: String, completion: @escaping (Result<[City], Error>) -> Void) {
        fetchList(path: ["sehirler", countryId], completion: completion)
    }

    func districts(cityId: String, completion: @escaping (Result<[District], Error>) -> Void) {
        fetchList(path: ["ilceler", cityId], completion: completion)
    }

    private func fetchList<T: Decodable>(path: [String], completion: @escaping (Result<[T], Error>) -> Void) {
        var url = baseURL
        for component in path {
            url.append(path: component)
        }
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
                completion(.success(try JSONDecoder().decode([T].self, from: data)))
            } catch {
                completion(.failure(error))
            }
        }
        task.resume()
    }
}
