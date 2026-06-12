import Foundation

/// Per-process cache of a district's monthly times, stored as a JSON file in the
/// process's Application Support directory.
///
/// v1 has no App Group (App Groups need a paid Apple Developer account, which we avoid),
/// so the app and the widget each keep their own copy in their own sandbox container.
/// A file is written atomically and persists immediately — no `UserDefaults` flush delay.
struct PrayerCache {
    private let directory: URL

    init(directory: URL? = nil) {
        if let directory {
            self.directory = directory
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
