import CoreLocation
import XCTest
@testable import Touring

class MeasureUtilTests: XCTestCase {
    override func setUpWithError() throws {
    }

    override func tearDownWithError() throws {
    }

    func testKphFrom() throws {
        XCTAssertEqual(MeasureUtil.kphFrom(mps: 0), 0, accuracy: 0.01)
        XCTAssertEqual(MeasureUtil.kphFrom(mps: 1000.0 / 60 / 60), 1, accuracy: 0.01)
    }

    func testMphFrom() throws {
        XCTAssertEqual(MeasureUtil.mphFrom(mps: 0), 0, accuracy: 0.01)
        XCTAssertEqual(MeasureUtil.mphFrom(mps: 1609.344 / 60 / 60), 1, accuracy: 0.01)
    }

    func testMilesFrom() throws {
        XCTAssertEqual(MeasureUtil.milesFrom(meters: 0), 0, accuracy: 0.01)
        XCTAssertEqual(MeasureUtil.milesFrom(meters: 1609.344), 1, accuracy: 0.01)
        XCTAssertEqual(MeasureUtil.milesFrom(meters: 1609.344 * 2), 2, accuracy: 0.01)
    }

    func testFeetFrom() throws {
        XCTAssertEqual(MeasureUtil.feetFrom(meters: 0), 0, accuracy: 0.001)
        XCTAssertEqual(MeasureUtil.feetFrom(meters: 0.3048), 1, accuracy: 0.001)
        XCTAssertEqual(MeasureUtil.feetFrom(meters: 0.3048 * 2), 2, accuracy: 0.001)
    }

    func testDisplayString() throws {
        XCTAssertEqual(MeasureUtil.displayString(0), "0")
        XCTAssertEqual(MeasureUtil.displayString(0.1), "0.1")
        XCTAssertEqual(MeasureUtil.displayString(0.11), "0.1")
        XCTAssertEqual(MeasureUtil.displayString(0.99), "1.0")
        XCTAssertEqual(MeasureUtil.displayString(1), "1.0")
        XCTAssertEqual(MeasureUtil.displayString(1.1), "1.1")
        XCTAssertEqual(MeasureUtil.displayString(1.11), "1.1")
        XCTAssertEqual(MeasureUtil.displayString(9.91), "9.9")
        XCTAssertEqual(MeasureUtil.displayString(9.99), "10")
        XCTAssertEqual(MeasureUtil.displayString(10.1), "10")
        XCTAssertEqual(MeasureUtil.displayString(10.9), "11")
    }

    func testMetersString() throws {
        XCTAssertEqual(MeasureUtil.metersString(0), ["0", "m"])
        XCTAssertEqual(MeasureUtil.metersString(0.9), ["1", "m"])
        XCTAssertEqual(MeasureUtil.metersString(999.4), ["999", "m"])
        XCTAssertEqual(MeasureUtil.metersString(999.6), ["1.0", "km"])
        XCTAssertEqual(MeasureUtil.metersString(9940), ["9.9", "km"])
        XCTAssertEqual(MeasureUtil.metersString(9960), ["10", "km"])
    }

    func testMilesString() throws {
        XCTAssertEqual(MeasureUtil.milesString(meters: ft2m(0)), ["0", "ft"])
        XCTAssertEqual(MeasureUtil.milesString(meters: ft2m(0.9)), ["1", "ft"])
        XCTAssertEqual(MeasureUtil.milesString(meters: ft2m(999.4)), ["999", "ft"])
        XCTAssertEqual(MeasureUtil.milesString(meters: ft2m(999.6)), ["0.2", "mi"])

        XCTAssertEqual(MeasureUtil.milesString(meters: mi2m(1)), ["1.0", "mi"])
        XCTAssertEqual(MeasureUtil.milesString(meters: mi2m(9.94)), ["9.9", "mi"])
        XCTAssertEqual(MeasureUtil.milesString(meters: mi2m(9.96)), ["10", "mi"])
    }

    func ft2m(_ feet: Double) -> Double {
        feet * 0.3048
    }

    func mi2m(_ miles: Double) -> Double {
        miles * 1609.344
    }

    func testDistanceString() throws {
        XCTAssertEqual(MeasureUtil.distanceString(meters: 123), ["123", "m"])
        XCTAssertEqual(MeasureUtil.distanceString(meters: 123, prefersMile: false), ["123", "m"])
        XCTAssertEqual(MeasureUtil.distanceString(meters: ft2m(123), prefersMile: true), ["123", "ft"])
    }

    func testDistanceWithDiagonalPoints() throws {
        let p1 = CLLocation(latitude: 45, longitude: 90)
        let p2 = CLLocation(latitude: 46, longitude: 91)
        let px = CLLocation(latitude: 45, longitude: 91)

        let mindist = p2.distance(from: p1)
        let maxdist = px.distance(from: p1) + p2.distance(from: px)

        let dist = MeasureUtil.distance(from: p1, to: p2)
        XCTAssertGreaterThanOrEqual(dist, mindist)
        XCTAssertLessThanOrEqual(dist, maxdist)
    }

    func testDistanceWithHorizontalPoints() throws {
        let p1 = CLLocation(latitude: 45, longitude: 90)
        let p2 = CLLocation(latitude: 45, longitude: 91)

        let dist = MeasureUtil.distance(from: p1, to: p2)
        XCTAssertEqual(dist, p2.distance(from: p1), accuracy: 500)
    }

    func testDistanceWithVerticalPoints() throws {
        let p1 = CLLocation(latitude: 45, longitude: 90)
        let p2 = CLLocation(latitude: 46, longitude: 90)

        let dist = MeasureUtil.distance(from: p1, to: p2)
        XCTAssertEqual(dist, p2.distance(from: p1), accuracy: 500)
    }
}
