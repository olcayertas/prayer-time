import ActivityKit
import Foundation

/// Live Activity payload for the next-prayer countdown (iOS only). Shared by the app, which
/// starts and refreshes the activity, and the widget extension, which renders it on the
/// Lock Screen and in the Dynamic Island.
struct PrayerActivityAttributes: ActivityAttributes {
    /// The part that changes as one prayer passes and the next becomes current.
    struct ContentState: Codable, Hashable {
        var prayerName: String
        var symbolName: String
        var time: String
        var endDate: Date
        /// The place shown in the activity. In the state, not the attributes, so a location
        /// change reaches a running activity. Nil in payloads from older versions.
        var locationName: String?
    }

    /// The place when the activity started. Fixed for the activity's lifetime, so the views read
    /// `ContentState.locationName` first.
    var locationName: String
}
