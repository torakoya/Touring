import XCTest

class HelpUITests: BaseUITestCase {
    var helpMenuItem: XCUIElement { app.buttons["Help"] }
    var closeButton: XCUIElement { app.buttons["Close"] }
    var childLink: XCUIElement { app.buttons["Plan a Route"] }
    var backButton: XCUIElement { app.buttons["Quick Start"] }

    func testParent() throws {
        menuButton.tap()
        _ = helpMenuItem.waitForExistence(timeout: 2)
        helpMenuItem.tap()
        XCTAssert(childLink.waitForExistence(timeout: 2))

        closeButton.tap()
        XCTAssert(closeButton.waitForNonexistence(timeout: 2))
    }

    func testChild() throws {
        menuButton.tap()
        _ = helpMenuItem.waitForExistence(timeout: 2)
        helpMenuItem.tap()

        _ = childLink.waitForExistence(timeout: 2)
        childLink.tap()

        XCTAssert(backButton.waitForExistence(timeout: 2))
        backButton.tap()

        XCTAssert(childLink.waitForExistence(timeout: 2))
        childLink.tap()

        _ = closeButton.waitForExistence(timeout: 2)
        closeButton.tap()
        XCTAssert(closeButton.waitForNonexistence(timeout: 2))
    }
}
