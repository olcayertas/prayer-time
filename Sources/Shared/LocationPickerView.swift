import SwiftUI

/// Cascading country → city → district picker, embeddable in a settings `Form` section.
/// Each level opens a searchable, name-sorted sheet (`PlacePickerSheet`).
struct LocationPickerView: View {
    @ObservedObject var store: PrayerStore
    @StateObject private var model = LocationPickerModel()
    @Environment(\.theme) private var theme
    @State private var showCountryPicker = false
    @State private var showCityPicker = false
    @State private var showDistrictPicker = false

    var body: some View {
        Group {
            LabeledContent("Current", value: store.locationName)

            pickerRow("Country", value: model.selectedCountryName,
                      enabled: !model.countries.isEmpty) { showCountryPicker = true }

            pickerRow("City", value: model.selectedCityName,
                      enabled: !model.cities.isEmpty) { showCityPicker = true }

            pickerRow("District", value: model.selectedDistrictName,
                      enabled: !model.districts.isEmpty) { showDistrictPicker = true }

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
            PlacePickerSheet(title: "Country", items: model.countries,
                             selectedId: model.selectedCountryId) { model.selectCountry($0.id) }
        }
        .sheet(isPresented: $showCityPicker) {
            PlacePickerSheet(title: "City", items: model.cities,
                             selectedId: model.selectedCityId) { model.selectCity($0.id) }
        }
        .sheet(isPresented: $showDistrictPicker) {
            PlacePickerSheet(title: "District", items: model.districts,
                             selectedId: model.selectedDistrictId) { model.selectedDistrictId = $0.id }
        }
    }

    /// A tappable settings row that shows the current selection and opens a picker sheet.
    private func pickerRow(_ title: LocalizedStringKey, value: String?,
                           enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            LabeledContent(title) {
                HStack(spacing: 6) {
                    Text(value ?? String(localized: "Select…"))
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption2)
                        .foregroundStyle(theme.muted)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }
}

/// Searchable, name-sorted list of places shown as a sheet (country / city / district).
private struct PlacePickerSheet<Item: NamedPlace>: View {
    let title: LocalizedStringKey
    let items: [Item]
    let selectedId: String
    let onSelect: (Item) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme
    @State private var search = ""

    private var filtered: [Item] {
        let sorted = items.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
        let term = search.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !term.isEmpty else { return sorted }
        return sorted.filter { $0.name.localizedCaseInsensitiveContains(term) }
    }

    var body: some View {
        NavigationStack {
            placeList
                .navigationTitle(title)
                #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                .searchable(text: $search, prompt: "Search")
                #endif
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                }
        }
        #if os(macOS)
        // A macOS sheet has no intrinsic size; give the searchable list room.
        .frame(minWidth: 360, idealWidth: 420, minHeight: 420, idealHeight: 520)
        #endif
    }

    private var placeList: some View {
        List(filtered) { item in
            Button {
                onSelect(item)
                dismiss()
            } label: {
                HStack {
                    Text(item.name)
                        .foregroundStyle(theme.text)
                    Spacer()
                    if item.id == selectedId {
                        Image(systemName: "checkmark")
                            .foregroundStyle(theme.accent)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        #if os(macOS)
        // macOS sheets don't render `.searchable`'s field reliably, so use an
        // explicit search field pinned above the list.
        .safeAreaInset(edge: .top) {
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass").foregroundStyle(theme.muted)
                TextField("Search", text: $search)
                    .textFieldStyle(.plain)
            }
            .padding(8)
            .background(theme.surface, in: RoundedRectangle(cornerRadius: 8))
            .padding(.horizontal)
            .padding(.top, 8)
        }
        #endif
    }
}
