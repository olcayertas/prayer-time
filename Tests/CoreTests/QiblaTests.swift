import XCTest

final class QiblaTests: XCTestCase {

    // Expected forward azimuths to the Kaaba (21.4225°N, 39.8262°E), degrees clockwise from
    // true north, cross-checked against the standard great-circle bearing formula.

    func testKucukcekmeceBearing() { // the app's default location
        XCTAssertEqual(Qibla.bearing(latitude: 41.00, longitude: 28.78), 151.150, accuracy: 0.01)
    }

    func testIstanbulBearing() {
        XCTAssertEqual(Qibla.bearing(latitude: 41.0082, longitude: 28.9784), 151.621, accuracy: 0.01)
    }

    func testLondonBearing() {
        XCTAssertEqual(Qibla.bearing(latitude: 51.5074, longitude: -0.1278), 118.987, accuracy: 0.01)
    }

    func testJakartaWrapsPastNorthwest() { // > 180°, exercises the +360 normalization
        XCTAssertEqual(Qibla.bearing(latitude: -6.2088, longitude: 106.8456), 295.152, accuracy: 0.01)
    }

    func testNewYorkBearing() {
        XCTAssertEqual(Qibla.bearing(latitude: 40.7128, longitude: -74.0060), 58.482, accuracy: 0.01)
    }

    func testAtKaabaIsZero() { // same-point edge case stays finite
        XCTAssertEqual(Qibla.bearing(latitude: Qibla.kaabaLatitude, longitude: Qibla.kaabaLongitude),
                       0, accuracy: 0.001)
    }

    func testResultAlwaysNormalized() {
        for lat in stride(from: -80.0, through: 80.0, by: 20) {
            for lon in stride(from: -180.0, through: 180.0, by: 30) {
                let b = Qibla.bearing(latitude: lat, longitude: lon)
                XCTAssertGreaterThanOrEqual(b, 0)
                XCTAssertLessThan(b, 360)
                XCTAssertFalse(b.isNaN)
            }
        }
    }
}
