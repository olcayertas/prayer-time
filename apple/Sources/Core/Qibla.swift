import Foundation

/// Qibla (direction to the Kaaba in Mecca) math. Pure and UI-free — it takes plain `Double`
/// degrees, not CoreLocation types — so it compiles into every target and is unit-testable on
/// macOS without a device. The iOS compass (`QiblaController`/`QiblaView`) feeds the device's
/// coordinate in and rotates a needle by the returned bearing.
enum Qibla {
    /// The Kaaba, Mecca (decimal degrees, WGS-84).
    static let kaabaLatitude = 21.4225
    static let kaabaLongitude = 39.8262

    /// Initial great-circle bearing (forward azimuth) from the given point to the Kaaba, in
    /// degrees clockwise from **true** north, normalized to `0..<360`.
    ///
    ///     θ = atan2( sinΔλ·cosφ₂ , cosφ₁·sinφ₂ − sinφ₁·cosφ₂·cosΔλ )
    ///
    /// where φ = latitude, λ = longitude, point 1 = observer, point 2 = the Kaaba.
    ///
    /// Edge cases are finite and non-crashing: at the Kaaba itself it returns `0`; at the
    /// antipode/poles the great circle is degenerate but `atan2` stays defined.
    static func bearing(latitude: Double, longitude: Double) -> Double {
        let phi1 = latitude * .pi / 180
        let phi2 = kaabaLatitude * .pi / 180
        let deltaLon = (kaabaLongitude - longitude) * .pi / 180

        let y = sin(deltaLon) * cos(phi2)
        let x = cos(phi1) * sin(phi2) - sin(phi1) * cos(phi2) * cos(deltaLon)
        let degrees = atan2(y, x) * 180 / .pi
        return (degrees.truncatingRemainder(dividingBy: 360) + 360)
            .truncatingRemainder(dividingBy: 360)
    }
}
