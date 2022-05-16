import MapKit
import XCTest
@testable import Touring

class MapUtilTests: XCTestCase {
    override func setUpWithError() throws {
    }

    override func tearDownWithError() throws {
    }

    func testRegionWithSinglePoint() throws {
        let points = [CLLocationCoordinate2D(latitude: 45.0, longitude: 90.0)]
        let region = MapUtil.region(with: points)
        XCTAssertEqual(region.center.latitude, points[0].latitude, accuracy: 0.001)
        XCTAssertEqual(region.center.longitude, points[0].longitude, accuracy: 0.001)
        XCTAssertEqual(region.span.latitudeDelta, 0.001)
        XCTAssertEqual(region.span.longitudeDelta, 0.001)
    }

    func testRegionWithVerticalPoints() throws {
        let points = [
            CLLocationCoordinate2D(latitude: 45.0, longitude: 90.0),
            CLLocationCoordinate2D(latitude: 46.0, longitude: 90.0)]
        let region = MapUtil.region(with: points)
        XCTAssertEqual(region.center.latitude, points[0].latitude, accuracy: region.span.latitudeDelta / 2)
        XCTAssertEqual(region.center.longitude, points[0].longitude, accuracy: region.span.longitudeDelta / 2)
        XCTAssertEqual(region.center.latitude, points[1].latitude, accuracy: region.span.latitudeDelta / 2)
        XCTAssertEqual(region.center.longitude, points[1].longitude, accuracy: region.span.longitudeDelta / 2)
    }

    func testRegionWithHorizontalPoints() throws {
        let points = [
            CLLocationCoordinate2D(latitude: 45.0, longitude: 90.0),
            CLLocationCoordinate2D(latitude: 45.0, longitude: 91.0)]
        let region = MapUtil.region(with: points)
        XCTAssertEqual(region.center.latitude, points[0].latitude, accuracy: region.span.latitudeDelta / 2)
        XCTAssertEqual(region.center.longitude, points[0].longitude, accuracy: region.span.longitudeDelta / 2)
        XCTAssertEqual(region.center.latitude, points[1].latitude, accuracy: region.span.latitudeDelta / 2)
        XCTAssertEqual(region.center.longitude, points[1].longitude, accuracy: region.span.longitudeDelta / 2)
    }

    func testRegionWithDiagonalPoints() throws {
        let points = [
            CLLocationCoordinate2D(latitude: 45.0, longitude: 90.0),
            CLLocationCoordinate2D(latitude: 46.0, longitude: 91.0)]
        let region = MapUtil.region(with: points)
        XCTAssertEqual(region.center.latitude, points[0].latitude, accuracy: region.span.latitudeDelta / 2)
        XCTAssertEqual(region.center.longitude, points[0].longitude, accuracy: region.span.longitudeDelta / 2)
        XCTAssertEqual(region.center.latitude, points[1].latitude, accuracy: region.span.latitudeDelta / 2)
        XCTAssertEqual(region.center.longitude, points[1].longitude, accuracy: region.span.longitudeDelta / 2)
    }
}
