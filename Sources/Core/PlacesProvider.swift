import Foundation

/// Looks up the EzanVakti location hierarchy for the location picker.
/// `Sendable` so an `any PlacesProvider` can be awaited off the `@MainActor` picker model.
protocol PlacesProvider: Sendable {
    func countries() async throws -> [Country]
    func cities(countryId: String) async throws -> [City]
    func districts(cityId: String) async throws -> [District]
}

extension EzanVaktiProvider: PlacesProvider {
    func countries() async throws -> [Country] {
        try await fetchList(path: ["ulkeler"])
    }

    func cities(countryId: String) async throws -> [City] {
        try await fetchList(path: ["sehirler", countryId])
    }

    func districts(cityId: String) async throws -> [District] {
        try await fetchList(path: ["ilceler", cityId])
    }

    private func fetchList<T: Decodable & Sendable>(path: [String]) async throws -> [T] {
        var url = baseURL
        for component in path {
            url.append(path: component)
        }
        let (data, response) = try await session.data(from: url)
        try Self.validate(response)
        return try JSONDecoder().decode([T].self, from: data)
    }
}
