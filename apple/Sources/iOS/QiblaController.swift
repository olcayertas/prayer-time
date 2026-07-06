import CoreLocation
import Foundation

/// Drives the iOS Qibla compass: owns one `CLLocationManager`, publishes the device's location +
/// heading, and derives the bearing/rotation to the Kaaba (the math lives in `Qibla` in Core).
///
/// Concurrency: the class is `@MainActor` and the manager is created on the main actor, so
/// CoreLocation delivers its delegate callbacks on the main run loop. The delegate methods are
/// therefore `nonisolated` (the protocol requirements aren't `@MainActor`) and hop onto the main
/// actor with the *synchronous* `MainActor.assumeIsolated` — no per-tick `Task`, no reordering of
/// rapid heading updates, and a loud trap if a callback ever arrives off-main. Value types are
/// read out of the non-`Sendable` `CLLocation`/`CLHeading` before the hop.
@MainActor
final class QiblaController: NSObject, ObservableObject {
    @Published private(set) var authorizationStatus: CLAuthorizationStatus
    @Published private(set) var coordinate: CLLocationCoordinate2D?
    /// Device heading in degrees (true north when available, else magnetic); nil until the first reading.
    @Published private(set) var headingDegrees: Double?
    /// `CLHeading.headingAccuracy`: < 0 means invalid/uncalibrated; larger is worse.
    @Published private(set) var headingAccuracy: Double = -1
    @Published private(set) var usingTrueNorth = false

    private let manager = CLLocationManager()

    override init() {
        authorizationStatus = manager.authorizationStatus
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters // city-level is plenty for a bearing
        manager.distanceFilter = 1000                              // recompute only after ~1 km
        manager.headingFilter = 1                                  // 1° — smooth needle, less spam
        manager.headingOrientation = .portrait                     // compass is used portrait; see QiblaView
    }

    /// Qibla bearing from true north for the current location, or nil until we have a fix.
    var qiblaBearing: Double? {
        coordinate.map { Qibla.bearing(latitude: $0.latitude, longitude: $0.longitude) }
    }

    /// Degrees to rotate an up-pointing needle so it points at the qibla, given the device heading.
    /// Intentionally *not* normalized — the view accumulates the shortest-path delta so the needle
    /// never swings the long way across the 0°/360° seam.
    var rotation: Double? {
        guard let qiblaBearing, let headingDegrees else { return nil }
        return qiblaBearing - headingDegrees
    }

    /// True when the phone is pointed within 5° of the qibla (wrap-aware).
    var isAligned: Bool {
        guard let rotation else { return false }
        let delta = abs((rotation + 540).truncatingRemainder(dividingBy: 360) - 180)
        return delta <= 5
    }

    /// True while the compass is uncalibrated or low-accuracy — prompt the figure-8 gesture.
    var isCalibrating: Bool { headingAccuracy < 0 || headingAccuracy > 25 }

    func requestAuthorization() { manager.requestWhenInUseAuthorization() }

    /// Begin location + heading updates. No-op without a magnetometer (Simulator / some iPads),
    /// which the view surfaces as a "no compass" state. Call from `.onAppear` / when foregrounded.
    func start() {
        guard CLLocationManager.headingAvailable() else { return }
        manager.startUpdatingLocation()
        manager.startUpdatingHeading()
    }

    /// Stop both sensors — call from `.onDisappear` and when backgrounded (GPS + magnetometer are
    /// power-hungry).
    func stop() {
        manager.stopUpdatingHeading()
        manager.stopUpdatingLocation()
    }
}

// MARK: - CLLocationManagerDelegate (nonisolated; bridged synchronously onto the main actor)
extension QiblaController: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        MainActor.assumeIsolated {
            authorizationStatus = status
            if status == .authorizedWhenInUse || status == .authorizedAlways { start() }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let coord = locations.last?.coordinate else { return }
        MainActor.assumeIsolated { coordinate = coord }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        // Prefer true north when valid (needs a location fix; -1 until then), else magnetic.
        let useTrue = newHeading.trueHeading >= 0
        let value = useTrue ? newHeading.trueHeading : newHeading.magneticHeading
        let accuracy = newHeading.headingAccuracy
        MainActor.assumeIsolated {
            headingDegrees = value
            usingTrueNorth = useTrue
            headingAccuracy = accuracy
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Transient CoreLocation errors (e.g. kCLErrorLocationUnknown) — keep the last good values;
        // the UI stays in its "locating"/"calibrating" state until a fix returns.
    }
}
