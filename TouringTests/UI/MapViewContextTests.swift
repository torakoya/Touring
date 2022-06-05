import XCTest
@testable import Touring

class MapViewContextTests: XCTestCase {
    override func setUpWithError() throws {
    }

    override func tearDownWithError() throws {
    }

    func testDestination() throws {
        let ctx = MapViewContext()
        XCTAssertTrue(ctx.originOnly)
        XCTAssertFalse(ctx.following)
    }

    func testEmptyDestination() throws {
        let ctx = MapViewContext()

        DestinationSet.current.destinations = [Destination()]
        ctx.originOnly = false

        DestinationSet.current.destinations.remove(at: 0)
        XCTAssertTrue(ctx.originOnly)
    }
}
