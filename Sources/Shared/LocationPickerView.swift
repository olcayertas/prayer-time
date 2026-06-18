import SwiftUI

/// Cascading country → city → district picker, embeddable in a settings `Form` section.
struct LocationPickerView: View {
    @ObservedObject var store: PrayerStore
    @StateObject private var model = LocationPickerModel()
    @Environment(\.theme) private var theme

    var body: some View {
        Group {
            LabeledContent("Current", value: store.locationName)

            Picker("Country", selection: Binding(
                get: { model.selectedCountryId },
                set: { model.selectCountry($0) }
            )) {
                ForEach(model.countries) { Text($0.name).tag($0.id) }
            }

            Picker("City", selection: Binding(
                get: { model.selectedCityId },
                set: { model.selectCity($0) }
            )) {
                Text("Select…").tag("")
                ForEach(model.cities) { Text($0.name).tag($0.id) }
            }
            .disabled(model.cities.isEmpty)

            Picker("District", selection: $model.selectedDistrictId) {
                Text("Select…").tag("")
                ForEach(model.districts) { Text($0.name).tag($0.id) }
            }
            .disabled(model.districts.isEmpty)

            if let error = model.error {
                Text(error).font(.caption).foregroundStyle(theme.error)
            }

            Button("Save this location") {
                if let district = model.selectedDistrict {
                    store.selectLocation(districtId: district.id, name: district.name)
                }
            }
            .disabled(model.selectedDistrict == nil)
        }
        .task { model.loadCountriesIfNeeded() }
    }
}
