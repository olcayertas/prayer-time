import Foundation
import Combine

/// Loads the country → city → district hierarchy for the picker. Uses the completion-based
/// `PlacesProvider` and bounces results to the main thread via GCD (the convention that
/// works reliably in this app).
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

    init(provider: PlacesProvider = EzanVaktiProvider()) {
        self.provider = provider
    }

    var selectedDistrict: District? {
        districts.first { $0.id == selectedDistrictId }
    }

    func loadCountriesIfNeeded() {
        guard countries.isEmpty else { return }
        isLoading = true
        provider.countries { [weak self] result in
            Self.onMain {
                guard let self else { return }
                self.isLoading = false
                switch result {
                case .success(let list):
                    self.countries = list
                    let turkiye = list.first { $0.id == "2" } ?? list.first
                    if let turkiye {
                        self.selectCountry(turkiye.id)
                    }
                case .failure(let error):
                    self.error = error.localizedDescription
                }
            }
        }
    }

    func selectCountry(_ id: String) {
        selectedCountryId = id
        selectedCityId = ""
        selectedDistrictId = ""
        cities = []
        districts = []
        provider.cities(countryId: id) { [weak self] result in
            Self.onMain {
                guard let self else { return }
                switch result {
                case .success(let list): self.cities = list
                case .failure(let error): self.error = error.localizedDescription
                }
            }
        }
    }

    func selectCity(_ id: String) {
        selectedCityId = id
        selectedDistrictId = ""
        districts = []
        guard !id.isEmpty else { return }
        provider.districts(cityId: id) { [weak self] result in
            Self.onMain {
                guard let self else { return }
                switch result {
                case .success(let list): self.districts = list
                case .failure(let error): self.error = error.localizedDescription
                }
            }
        }
    }

    private static func onMain(_ work: @escaping @MainActor () -> Void) {
        DispatchQueue.main.async { MainActor.assumeIsolated { work() } }
    }
}
