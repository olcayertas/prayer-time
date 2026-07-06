import Foundation

/// How the app decides which district's prayer times to show.
enum LocationMode: String, Codable, Sendable, CaseIterable, Identifiable {
    /// Track the device location and resolve it to the nearest Diyanet district.
    case automatic
    /// Use a district the user explicitly chose in the picker.
    case pinned

    var id: String { rawValue }
}

/// Transient state of the automatic-tracking pipeline, surfaced in Settings. Not persisted —
/// recomputed each launch.
enum LocationTrackingStatus: Equatable, Sendable {
    case idle                  // automatic off, or not started yet
    case locating              // waiting for a CoreLocation fix
    case resolving             // have a coordinate, reverse-geocoding + matching a district
    case resolved(String)      // using <city/district name>
    case permissionDenied      // location denied/restricted → fell back to the saved district
    case unavailable           // no fix or no confident match → fell back to the saved district
}
