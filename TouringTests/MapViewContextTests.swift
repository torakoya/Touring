import MapKit
import XCTest
@testable import Touring

class MapViewContextTests: XCTestCase {
    override func setUpWithError() throws {
    }

    override func tearDownWithError() throws {
    }

    func testDestination() throws {
        let ctx = MapViewContext()
        XCTAssert(ctx.destinations.isEmpty)
        XCTAssertNil(ctx.currentDestination)
        XCTAssertTrue(ctx.originOnly)
        XCTAssertFalse(ctx.following)
    }

    func testAddDestination() throws {
        var ctx = MapViewContext()

        ctx.destinations += [MKPointAnnotation()]
        XCTAssertEqual(ctx.currentDestination, 0)

        ctx.destinations += [MKPointAnnotation()]
        XCTAssertEqual(ctx.currentDestination, 0)
    }

    func testRemoveDestination() throws {
        var ctx = MapViewContext()

        ctx.destinations = [MKPointAnnotation(), MKPointAnnotation()]
        ctx.currentDestination = 1

        ctx.destinations.remove(at: 1)
        XCTAssertEqual(ctx.currentDestination, 0)
    }

    func testEmptyDestination() throws {
        var ctx = MapViewContext()

        ctx.destinations = [MKPointAnnotation()]
        ctx.originOnly = false

        ctx.destinations.remove(at: 0)
        XCTAssertNil(ctx.currentDestination)
        XCTAssertTrue(ctx.originOnly)
    }

    func testGoForwardWithEmptyDestination() throws {
        var ctx = MapViewContext()

        ctx.goForward()
        XCTAssertNil(ctx.currentDestination)
    }

    func testGoForwardWithSingleDestination() throws {
        var ctx = MapViewContext()
        ctx.destinations = [MKPointAnnotation()]

        ctx.goForward()
        XCTAssertEqual(ctx.currentDestination, 0)
    }

    func testGoForwardWithSomeDestinations() throws {
        var ctx = MapViewContext()
        ctx.destinations = [MKPointAnnotation(), MKPointAnnotation(), MKPointAnnotation()]

        ctx.goForward()
        XCTAssertEqual(ctx.currentDestination, 1)

        ctx.goForward()
        XCTAssertEqual(ctx.currentDestination, 2)

        ctx.goForward()
        XCTAssertEqual(ctx.currentDestination, 0)
    }

    func testGoBackwardWithEmptyDestination() throws {
        var ctx = MapViewContext()

        ctx.goBackward()
        XCTAssertNil(ctx.currentDestination)
    }

    func testGoBackwardWithSingleDestination() throws {
        var ctx = MapViewContext()
        ctx.destinations = [MKPointAnnotation()]

        ctx.goBackward()
        XCTAssertEqual(ctx.currentDestination, 0)
    }

    func testGoBackwardWithSomeDestinations() throws {
        var ctx = MapViewContext()
        ctx.destinations = [MKPointAnnotation(), MKPointAnnotation(), MKPointAnnotation()]

        ctx.goBackward()
        XCTAssertEqual(ctx.currentDestination, 2)

        ctx.goBackward()
        XCTAssertEqual(ctx.currentDestination, 1)

        ctx.goBackward()
        XCTAssertEqual(ctx.currentDestination, 0)
    }
}
