import XCTest

class TouringUITests: XCTestCase {
    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launch()
    }

    override func tearDownWithError() throws {
    }

    func testToggleSpeedUnit() throws {
        let u1 = app.staticTexts["km/h"]
        let u2 = app.staticTexts["mph"]
        let e1 = u1.exists

        (u1.exists ? u1 : u2).tap()
        XCTAssertNotEqual(u1.exists, e1)
        XCTAssertEqual(u2.exists, e1)

        (u1.exists ? u1 : u2).tap()
        XCTAssertEqual(u1.exists, e1)
        XCTAssertNotEqual(u2.exists, e1)
    }
}
