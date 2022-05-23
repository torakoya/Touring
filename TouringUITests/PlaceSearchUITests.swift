import XCTest

class PlaceSearchUITests: BaseUITestCase {
    var searchField: XCUIElement { app.textFields["Search"] }

    func openSearch() {
        menuButton.tap()
        _ = app.buttons["Search Place"].waitForExistence(timeout: 2)
        app.buttons["Search Place"].tap()
        _ = searchField.waitForExistence(timeout: 2)
    }

    func testClose() throws {
        openSearch()

        app.buttons["Close"].tap()
        XCTAssert(app.buttons["Close"].waitForNonexistence(timeout: 2))
    }

    func testSearch() throws {
        openSearch()

        searchField.tap()
        searchField.typeText("apple park")

        let row = app.staticTexts["Apple Park"]
        XCTAssert(row.waitForExistence(timeout: 3))
        row.tap()
        XCTAssert(app.buttons["Close"].waitForNonexistence(timeout: 3))
    }
}
