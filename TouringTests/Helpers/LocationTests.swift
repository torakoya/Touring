import CoreLocation
import XCTest
@testable import Touring

class LocationTests: XCTestCase {
    override func setUpWithError() throws {
    }

    override func tearDownWithError() throws {
    }

    func locationWith(latitude: CLLocationDegrees? = nil, longitude: CLLocationDegrees? = nil,
                      speed: CLLocationSpeed) -> CLLocation {
        CLLocation(
            coordinate: CLLocationCoordinate2D(
                latitude: latitude ?? Double.random(in: -90...90),
                longitude: longitude ?? Double.random(in: -180...180)),
            altitude: 0, horizontalAccuracy: 1, verticalAccuracy: 1,
            course: 0, courseAccuracy: 1, speed: speed, speedAccuracy: 1, timestamp: Date())
    }

    func testShouldAcceptWithoutLastLocation() throws {
        let location = locationWith(speed: 0)
        XCTAssertTrue(Location().shouldAccept(location, last: nil))
    }

    func testShoulAcceptWithFarLocation() throws {
        let location = locationWith(latitude: 0, longitude: 0, speed: 123)
        let last = locationWith(latitude: 0, longitude: 0.000046, speed: 123)
        XCTAssertTrue(Location().shouldAccept(location, last: last))
    }

    func testShoulAcceptWithNotFarLocation() throws {
        let location = locationWith(latitude: 0, longitude: 0, speed: 123)
        let last = locationWith(latitude: 0, longitude: 0.000044, speed: 123)
        XCTAssertFalse(Location().shouldAccept(location, last: last))
    }

    func testShouldAcceptWithInvalidSpeed() throws {
        let location = locationWith(latitude: 45, longitude: 90, speed: -1)
        let last = locationWith(latitude: 45, longitude: 90, speed: 123)
        XCTAssertFalse(Location().shouldAccept(location, last: last))
    }

    func testShouldAcceptWithInvalidLastSpeed() throws {
        let location = locationWith(latitude: 45, longitude: 90, speed: 123)
        let last = locationWith(latitude: 45, longitude: 90, speed: -1)
        XCTAssertTrue(Location().shouldAccept(location, last: last))
    }

    func testShouldAcceptWithStopping() throws {
        let location = locationWith(latitude: 45, longitude: 90, speed: 0)
        let last = locationWith(latitude: 45, longitude: 90, speed: 123)
        XCTAssertTrue(Location().shouldAccept(location, last: last))
    }

    func testShouldAcceptWithAlmostStopping() throws {
        let location = locationWith(latitude: 45, longitude: 90, speed: 0.005)
        let last = locationWith(latitude: 45, longitude: 90, speed: 0.02)
        XCTAssertTrue(Location().shouldAccept(location, last: last))
    }
}
