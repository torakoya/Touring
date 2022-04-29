import XCTest
@testable import Touring

class TouringTests: XCTestCase {
    override func setUpWithError() throws {
    }

    override func tearDownWithError() throws {
    }

    func testDisplayNumber() throws {
        XCTAssertEqual(ContentViewModel.displayString(0), "0")
        XCTAssertEqual(ContentViewModel.displayString(0.1), "0.1")
        XCTAssertEqual(ContentViewModel.displayString(0.11), "0.1")
        XCTAssertEqual(ContentViewModel.displayString(0.99), "1.0")
        XCTAssertEqual(ContentViewModel.displayString(1), "1.0")
        XCTAssertEqual(ContentViewModel.displayString(1.1), "1.1")
        XCTAssertEqual(ContentViewModel.displayString(1.11), "1.1")
        XCTAssertEqual(ContentViewModel.displayString(9.91), "9.9")
        XCTAssertEqual(ContentViewModel.displayString(9.99), "10")
        XCTAssertEqual(ContentViewModel.displayString(10.1), "10")
        XCTAssertEqual(ContentViewModel.displayString(10.9), "11")
    }
}
