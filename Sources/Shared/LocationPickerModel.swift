import Foundation
import Combine

/// Loads the country → city → district hierarchy for the picker. Uses the async
/// `PlacesProvider`, which hops off the main actor for the request and resumes here on
/// `@MainActor`. Each selection supersedes the previous in-flight load.
@MainActor
final class LocationPickerModel: ObservableObject {
    @Published var countries: [Country] = []
    @Published var cities: [City] = []
    @Published var districts: [District] = []

    @Published var selectedCountryId: String = ""
    @Published var selectedCityId: String = ""
    @Published var selectedDistrictId: String = ""

    @Published var isLoading = false
    @Published var error: String?

    private let provider: PlacesProvider
    /// The in-flight hierarchy load, cancelled whenever a newer selection starts one.
    private var loadTask: Task<Void, Never>?

    init(provider: PlacesProvider = EzanVaktiProvider()) {
        self.provider = provider
    }

    var selectedDistrict: District? {
        districts.first { $0.id == selectedDistrictId }
    }

    /// Display name of the currently selected country (for the picker row).
    var selectedCountryName: String? {
        countries.first { $0.id == selectedCountryId }?.name
    }

    /// Countries sorted by name (locale-aware), optionally filtered by a search term.
    func countries(matching search: String) -> [Country] {
        let sorted = countries.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
        let term = search.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !term.isEmpty else { return sorted }
        return sorted.filter { $0.name.localizedCaseInsensitiveContains(term) }
    }

    func loadCountriesIfNeeded() {
        guard countries.isEmpty else { return }
        isLoading = true
        loadTask?.cancel()
        loadTask = Task { [provider] in
            defer { isLoading = false }
            do {
                let list = try await provider.countries()
                countries = list
                if let turkiye = list.first(where: { $0.id == "2" }) ?? list.first {
                    selectCountry(turkiye.id)
                }
            } catch {
                self.error = error.localizedDescription
            }
        }
    }

    func selectCountry(_ id: String) {
        selectedCountryId = id
        selectedCityId = ""
        selectedDistrictId = ""
        cities = []
        districts = []
        loadTask?.cancel()
        loadTask = Task { [provider] in
            do {
                cities = try await provider.cities(countryId: id)
            } catch {
                self.error = error.localizedDescription
            }
        }
    }

    func selectCity(_ id: String) {
        selectedCityId = id
        selectedDistrictId = ""
        districts = []
        guard !id.isEmpty else { return }
        loadTask?.cancel()
        loadTask = Task { [provider] in
            do {
                districts = try await provider.districts(cityId: id)
            } catch {
                self.error = error.localizedDescription
            }
        }
    }
}
