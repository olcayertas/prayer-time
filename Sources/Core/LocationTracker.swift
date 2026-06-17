import CoreLocation
import Foundation

/// Cross-platform, one-shot location source for *city-granularity* prayer-times tracking. Owns its
/// own `CLLocationManager` (a second one alongside the iOS Qibla compass's — each is independent).
///
/// `@MainActor` like `QiblaController`: the manager is created on the main actor so its delegate
/// callbacks arrive on the main run loop; they're declared `nonisolated` (the protocol isn't
/// `@MainActor`) and bridge back with the *synchronous* `MainActor.assumeIsolated` after extracting
/// value types from the non-`Sendable` `CLLocation`.
///
/// Exposes an `async` pull API (permission + one-shot fix wrapped in continuations) rather than a
/// `@Published` coordinate stream — `PrayerStore` drives it linearly from a single `Task`, which is
/// simpler and avoids streaming a non-`Sendable` `CLLocationCoordinate2D` across actors.
@MainActor
final class LocationTracker: NSObject, ObservableObject {
    private(set) var authorizationStatus: CLAuthorizationStatus

    private let manager = CLLocationManager()
    private var authContinuation: CheckedContinuation<CLAuthorizationStatus, Never>?
    private var fixContinuation: CheckedContinuation<CLLocationCoordinate2D?, Never>?

    override init() {
        authorizationStatus = manager.authorizationStatus
        super.init()
        manager.delegate = self
        // Kilometre-level precise accuracy resolves the right ilçe without the battery/precision of
        // a pinpoint fix — prayer times are city-granularity.
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    /// Prompts for when-in-use access if undetermined and awaits the user's decision; otherwise
    /// returns the current status immediately (so it never hangs when already decided).
    func requestWhenInUseAuthorization() async -> CLAuthorizationStatus {
        guard authorizationStatus == .notDetermined else { return authorizationStatus }
        return await withCheckedContinuation { continuation in
            authContinuation = continuation
            manager.requestWhenInUseAuthorization()
        }
    }

    /// One-shot location fix. Returns nil if unauthorized or the fix fails. `requestLocation()`
    /// delivers exactly one `didUpdateLocations`/`didFailWithError` and auto-stops.
    func requestCoordinate() async -> CLLocationCoordinate2D? {
        guard authorizationStatus.isAuthorizedForLocation else { return nil }
        finishFix(nil) // resume any stale pending fix before starting a new one
        return await withCheckedContinuation { continuation in
            fixContinuation = continuation
            manager.requestLocation()
        }
    }

    private func finishFix(_ coordinate: CLLocationCoordinate2D?) {
        fixContinuation?.resume(returning: coordinate)
        fixContinuation = nil
    }
}

// MARK: - CLLocationManagerDelegate (nonisolated; bridged synchronously onto the main actor)
extension LocationTracker: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        MainActor.assumeIsolated {
            authorizationStatus = status
            if status != .notDetermined {           // resume only once the user actually decides
                authContinuation?.resume(returning: status)
                authContinuation = nil
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let coordinate = locations.last?.coordinate    // value type out before the hop
        MainActor.assumeIsolated { finishFix(coordinate) }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        MainActor.assumeIsolated { finishFix(nil) }
    }
}

extension CLAuthorizationStatus {
    /// Cross-platform "location granted" check — macOS has no `.authorizedWhenInUse`, only
    /// `.authorizedAlways`.
    var isAuthorizedForLocation: Bool {
        #if os(macOS)
        self == .authorizedAlways
        #else
        self == .authorizedWhenInUse || self == .authorizedAlways
        #endif
    }
}
