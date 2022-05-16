import CoreLocation
import XCTest
@testable import Touring

class CLLocationTests: XCTestCase {
    override func setUpWithError() throws {
    }

    override func tearDownWithError() throws {
    }

    func testWithPositiveHorizontalAccuracy() throws {
        let location = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 45, longitude: 90),
            altitude: 0, horizontalAccuracy: 1, verticalAccuracy: 0, timestamp: Date())
        XCTAssertEqual(location.validLatitude, 45)
        XCTAssertEqual(location.validLongitude, 90)
    }

    func testWithZeroHorizontalAccuracy() throws {
        let location = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 45, longitude: 90),
            altitude: 0, horizontalAccuracy: 0, verticalAccuracy: 0, timestamp: Date())
        XCTAssertEqual(location.validLatitude, 45)
        XCTAssertEqual(location.validLongitude, 90)
    }

    func testWithNegativeHorizontalAccuracy() throws {
        let location = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 45, longitude: 90),
            altitude: 0, horizontalAccuracy: -1, verticalAccuracy: 0, timestamp: Date())
        XCTAssertNil(location.validLatitude)
        XCTAssertNil(location.validLongitude)
    }

    func testWithPositiveSpeed() throws {
        let location = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 45, longitude: 90),
            altitude: 0, horizontalAccuracy: 1, verticalAccuracy: 1,
            course: 0, courseAccuracy: 1, speed: 123, speedAccuracy: 1, timestamp: Date())
        XCTAssertEqual(location.validSpeed, 123)
    }

    func testWithZeroSpeed() throws {
        let location = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 45, longitude: 90),
            altitude: 0, horizontalAccuracy: 1, verticalAccuracy: 1,
            course: 0, courseAccuracy: 1, speed: 0, speedAccuracy: 1, timestamp: Date())
        XCTAssertEqual(location.validSpeed, 0)
    }

    func testWithNegativeSpeed() throws {
        let location = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 45, longitude: 90),
            altitude: 0, horizontalAccuracy: 1, verticalAccuracy: 1,
            course: 0, courseAccuracy: 1, speed: -1, speedAccuracy: 1, timestamp: Date())
        XCTAssertNil(location.validSpeed)
    }

    func testWithZeroSpeedAccuracy() throws {
        let location = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 45, longitude: 90),
            altitude: 0, horizontalAccuracy: 1, verticalAccuracy: 1,
            course: 0, courseAccuracy: 1, speed: 123, speedAccuracy: 0, timestamp: Date())
        XCTAssertEqual(location.validSpeed, 123)
    }

    func testWithNegativeSpeedAccuracy() throws {
        let location = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 45, longitude: 90),
            altitude: 0, horizontalAccuracy: 1, verticalAccuracy: 1,
            course: 0, courseAccuracy: 1, speed: 123, speedAccuracy: -1, timestamp: Date())
        XCTAssertNil(location.validSpeed)
    }

    func testWithPositiveCourse() throws {
        let location = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 45, longitude: 90),
            altitude: 0, horizontalAccuracy: 1, verticalAccuracy: 1,
            course: 123, courseAccuracy: 1, speed: 0, speedAccuracy: 1, timestamp: Date())
        XCTAssertEqual(location.validCourse, 123)
    }

    func testWithZeroCourse() throws {
        let location = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 45, longitude: 90),
            altitude: 0, horizontalAccuracy: 1, verticalAccuracy: 1,
            course: 0, courseAccuracy: 1, speed: 0, speedAccuracy: 1, timestamp: Date())
        XCTAssertEqual(location.validCourse, 0)
    }

    func testWithNegativeCourse() throws {
        let location = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 45, longitude: 90),
            altitude: 0, horizontalAccuracy: 1, verticalAccuracy: 1,
            course: -1, courseAccuracy: 1, speed: 0, speedAccuracy: 1, timestamp: Date())
        XCTAssertNil(location.validCourse)
    }

    func testWithZeroCourseAccuracy() throws {
        let location = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 45, longitude: 90),
            altitude: 0, horizontalAccuracy: 1, verticalAccuracy: 1,
            course: 123, courseAccuracy: 0, speed: 0, speedAccuracy: 1, timestamp: Date())
        XCTAssertEqual(location.validCourse, 123)
    }

    func testWithNegativeCourseAccuracy() throws {
        let location = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 45, longitude: 90),
            altitude: 0, horizontalAccuracy: 1, verticalAccuracy: 1,
            course: 123, courseAccuracy: -1, speed: 0, speedAccuracy: 1, timestamp: Date())
        XCTAssertNil(location.validCourse)
    }

    func testWithPositiveAltitudeAccuracy() throws {
        let location = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 45, longitude: 90),
            altitude: 123, horizontalAccuracy: 1, verticalAccuracy: 1,
            course: 0, courseAccuracy: 1, speed: 0, speedAccuracy: 1, timestamp: Date())
        XCTAssertEqual(location.validAltitude, 123)
    }

    func testWithZeroAltitudeAccuracy() throws {
        let location = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 45, longitude: 90),
            altitude: 123, horizontalAccuracy: 1, verticalAccuracy: 0,
            course: 0, courseAccuracy: 1, speed: 0, speedAccuracy: 1, timestamp: Date())
        XCTAssertNil(location.validAltitude)
    }

    func testWithNegativeAltitudeAccuracy() throws {
        let location = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 45, longitude: 90),
            altitude: 123, horizontalAccuracy: 1, verticalAccuracy: -1,
            course: 0, courseAccuracy: 1, speed: 0, speedAccuracy: 1, timestamp: Date())
        XCTAssertNil(location.validAltitude)
    }
}
