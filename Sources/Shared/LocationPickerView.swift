import SwiftUI

/// Cascading country → city → district picker, embeddable in a settings `Form` section.
struct LocationPickerView: View {
    @ObservedObject var store: PrayerStore
    @StateObject private var model = LocationPickerModel()
    @Environment(\.theme) private var theme
    @State private var showCountryPicker = false

    var body: some View {
        Group {
            LabeledContent("Current", value: store.locationName)

            Button {
                showCountryPicker = true
            } label: {
                LabeledContent("Country") {
                    HStack(spacing: 6) {
                        Text(model.selectedCountryName ?? "Select…")
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.caption2)
                            .foregroundStyle(theme.muted)
                    }
                }
            }
            .buttonStyle(.plain)
            .disabled(model.countries.isEmpty)

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
        .sheet(isPresented: $showCountryPicker) {
            CountryPickerSheet(
                model: model,
                selectedId: model.selectedCountryId,
                onSelect: { model.selectCountry($0.id) }
            )
        }
    }
}

/// Searchable, name-sorted country list shown as a sheet.
private struct CountryPickerSheet: View {
    @ObservedObject var model: LocationPickerModel
    let selectedId: String
    let onSelect: (Country) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme
    @State private var search = ""

    var body: some View {
        NavigationStack {
            List(model.countries(matching: search)) { country in
                Button {
                    onSelect(country)
                    dismiss()
                } label: {
                    HStack {
                        Text(country.name)
                            .foregroundStyle(theme.text)
                        Spacer()
                        if country.id == selectedId {
                            Image(systemName: "checkmark")
                                .foregroundStyle(theme.accent)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .navigationTitle("Country")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .searchable(text: $search, prompt: "Search")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
