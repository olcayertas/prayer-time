import Foundation

/// Cache of a district's monthly times, stored as a JSON file in the shared App Group container
/// so the app and the widget read the same copy (the widget thus follows the app's location).
/// Falls back to the process's Application Support directory when the group container is
/// unavailable (e.g. unit tests, or a build without the entitlement). A file is written atomically
/// and persists immediately — no `UserDefaults` flush delay.
struct PrayerCache {
    private let directory: URL

    init(directory: URL? = nil) {
        if let directory {
            self.directory = directory
        } else if let group = AppGroup.containerURL {
            self.directory = group
        } else {
            self.directory = (try? FileManager.default.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )) ?? FileManager.default.temporaryDirectory
        }
    }

    private func fileURL(for districtId: String) -> URL {
        directory.appending(path: "monthlyTimes.\(districtId).json")
    }

    func save(_ days: [PrayerDay], districtId: String) {
        guard let data = try? JSONEncoder().encode(days) else { return }
        try? data.write(to: fileURL(for: districtId), options: .atomic)
    }

    func load(districtId: String) -> [PrayerDay]? {
        guard let data = try? Data(contentsOf: fileURL(for: districtId)) else { return nil }
        return try? JSONDecoder().decode([PrayerDay].self, from: data)
    }
}
