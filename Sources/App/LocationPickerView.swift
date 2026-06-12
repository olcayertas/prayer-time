import SwiftUI

/// Cascading country → city → district picker, embeddable in a settings `Form` section.
struct LocationPickerView: View {
    @ObservedObject var store: PrayerStore
    @StateObject private var model = LocationPickerModel()

    var body: some View {
        Group {
            LabeledContent("Geçerli", value: store.locationName)

            Picker("Ülke", selection: Binding(
                get: { model.selectedCountryId },
                set: { model.selectCountry($0) }
            )) {
                ForEach(model.countries) { Text($0.name).tag($0.id) }
            }

            Picker("Şehir", selection: Binding(
                get: { model.selectedCityId },
                set: { model.selectCity($0) }
            )) {
                Text("Seçiniz").tag("")
                ForEach(model.cities) { Text($0.name).tag($0.id) }
            }
            .disabled(model.cities.isEmpty)

            Picker("İlçe", selection: $model.selectedDistrictId) {
                Text("Seçiniz").tag("")
                ForEach(model.districts) { Text($0.name).tag($0.id) }
            }
            .disabled(model.districts.isEmpty)

            if let error = model.error {
                Text(error).font(.caption).foregroundStyle(.red)
            }

            Button("Bu konumu kaydet") {
                if let district = model.selectedDistrict {
                    store.selectLocation(districtId: district.id, name: district.name)
                }
            }
            .disabled(model.selectedDistrict == nil)
        }
        .task { model.loadCountriesIfNeeded() }
    }
}
