import XCTest

class DestinationSetListUITests: BaseUITestCase {
    var closeButton: XCUIElement { app.buttons["Close"] }
    var menuItem: XCUIElement { app.buttons["Switch Destination Set"] }
    var nameField: XCUIElement { app.textFields["Name"] }
    var addButton: XCUIElement { app.buttons["Add"] }
    var switchButton: XCUIElement { app.buttons["Share Multiple"] }

    func openList() {
        menuButton.tap()
        _ = menuItem.waitForExistence(timeout: 2)
        menuItem.tap()
        _ = closeButton.waitForExistence(timeout: 2)
    }

    func testMenuItemDisabledWithEmptyCurrentAndEmptyOthers() throws {
        menuButton.tap()
        _ = menuItem.waitForExistence(timeout: 2)
        XCTAssertFalse(menuItem.isEnabled)
    }

    func testMenuItemEnabled() throws {
        randomPoint().press(forDuration: 2)
        openList()
        XCTAssert(closeButton.waitForExistence(timeout: 2))
    }

    func testInitialState() throws {
        let name = randomName()
        openDetail()
        nameField.tap()
        nameField.typeText(name)
        closeDetail()

        openList()
        XCTAssert(addButton.isEnabled)
        let row = app.staticTexts.containing(NSPredicate(format: "label contains %@", name)).element
        XCTAssert(row.exists)

        row.tap()
        XCTAssert(app.staticTexts[name].waitForExistence(timeout: 2))

        // The close button should close the sheet, not go back to the parent sheet.
        closeButton.tap()
        XCTAssert(closeButton.waitForNonexistence(timeout: 2))
    }

    func testAddAndSwitchAndDelete() throws {
        let name = randomName()
        openDetail()
        nameField.tap()
        nameField.typeText(name)
        closeDetail()

        // Add
        openList()
        addButton.tap()
        XCTAssert(closeButton.waitForNonexistence(timeout: 2))
        XCTAssertFalse(app.otherElements[name].exists)

        openList()
        let row = app.staticTexts.containing(NSPredicate(format: "label contains %@", name)).element
        XCTAssert(row.exists)
        XCTAssertFalse(addButton.isEnabled)

        // Switch
        switchButton.tap()
        XCTAssert(app.otherElements[name].waitForExistence(timeout: 2))

        // Delete
        openList()
        row.swipeLeft()
        app.buttons["Delete"].tap()
        XCTAssert(app.otherElements[name].waitForNonexistence(timeout: 2))
    }

    func testSwitchInDetailSheet() throws {
        let name = randomName()
        openDetail()
        nameField.tap()
        nameField.typeText(name)
        closeDetail()

        // Add
        openList()
        addButton.tap()
        _ = closeButton.waitForNonexistence(timeout: 2)

        openList()
        app.staticTexts.containing(NSPredicate(format: "label contains %@", name)).element.tap()

        // Switch
        XCTAssert(switchButton.waitForExistence(timeout: 2))
        switchButton.tap()
        XCTAssert(app.otherElements[name].waitForExistence(timeout: 2))
    }
}
