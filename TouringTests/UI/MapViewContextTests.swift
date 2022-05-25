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
        XCTAssertNil(ctx.targetIndex)
        XCTAssertNil(ctx.target)
        XCTAssertTrue(ctx.originOnly)
        XCTAssertFalse(ctx.following)
    }

    func testAddDestination() throws {
        let dest0 = Destination()
        let dest1 = Destination()

        var ctx = MapViewContext()

        ctx.destinations += [dest0]
        XCTAssertEqual(ctx.targetIndex, 0)
        XCTAssertEqual(ctx.target, dest0)

        ctx.destinations += [dest1]
        XCTAssertEqual(ctx.targetIndex, 0)
        XCTAssertEqual(ctx.target, dest0)
    }

    func testRemoveDestination() throws {
        let dests = [Destination(), Destination()]

        var ctx = MapViewContext()

        ctx.destinations = dests
        ctx.targetIndex = 1

        ctx.destinations.remove(at: 1)
        XCTAssertEqual(ctx.targetIndex, 0)
        XCTAssertEqual(ctx.target, dests[0])
    }

    func testEmptyDestination() throws {
        var ctx = MapViewContext()

        ctx.destinations = [Destination()]
        ctx.originOnly = false

        ctx.destinations.remove(at: 0)
        XCTAssertNil(ctx.targetIndex)
        XCTAssertNil(ctx.target)
        XCTAssertTrue(ctx.originOnly)
    }

    func testGoForwardWithEmptyDestination() throws {
        var ctx = MapViewContext()

        ctx.goForward()
        XCTAssertNil(ctx.targetIndex)
        XCTAssertNil(ctx.target)
    }

    func testGoForwardWithSingleDestination() throws {
        let dests = [Destination()]

        var ctx = MapViewContext()
        ctx.destinations = dests

        ctx.goForward()
        XCTAssertEqual(ctx.targetIndex, 0)
        XCTAssertEqual(ctx.target, dests[0])
    }

    func testGoForwardWithSomeDestinations() throws {
        let dests = [Destination(), Destination(), Destination()]

        var ctx = MapViewContext()
        ctx.destinations = dests

        ctx.goForward()
        XCTAssertEqual(ctx.targetIndex, 1)
        XCTAssertEqual(ctx.target, dests[1])

        ctx.goForward()
        XCTAssertEqual(ctx.targetIndex, 2)
        XCTAssertEqual(ctx.target, dests[2])

        ctx.goForward()
        XCTAssertEqual(ctx.targetIndex, 0)
        XCTAssertEqual(ctx.target, dests[0])
    }

    func testGoBackwardWithEmptyDestination() throws {
        var ctx = MapViewContext()

        ctx.goBackward()
        XCTAssertNil(ctx.targetIndex)
        XCTAssertNil(ctx.target)
    }

    func testGoBackwardWithSingleDestination() throws {
        let dests = [Destination()]

        var ctx = MapViewContext()
        ctx.destinations = dests

        ctx.goBackward()
        XCTAssertEqual(ctx.targetIndex, 0)
        XCTAssertEqual(ctx.target, dests[0])
    }

    func testGoBackwardWithSomeDestinations() throws {
        let dests = [Destination(), Destination(), Destination()]

        var ctx = MapViewContext()
        ctx.destinations = dests

        ctx.goBackward()
        XCTAssertEqual(ctx.targetIndex, 2)
        XCTAssertEqual(ctx.target, dests[2])

        ctx.goBackward()
        XCTAssertEqual(ctx.targetIndex, 1)
        XCTAssertEqual(ctx.target, dests[1])

        ctx.goBackward()
        XCTAssertEqual(ctx.targetIndex, 0)
        XCTAssertEqual(ctx.target, dests[0])
    }
}
