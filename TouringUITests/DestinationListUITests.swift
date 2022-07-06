import XCTest
import SwiftUI

class DestinationListUITests: BaseUITestCase {
    var closeButton: XCUIElement { app.buttons["Close"] }
    var nameField: XCUIElement { app.textFields["Name"] }
    var noteField: XCUIElement { app.textViews.firstMatch }

    func openList() {
        menuButton.tap()
        _ = app.buttons["Destination List"].waitForExistence(timeout: 2)
        app.buttons["Destination List"].tap()
        _ = closeButton.waitForExistence(timeout: 2)
    }

    func testListDisabled() throws {
        openList()
        XCTAssert(closeButton.waitForNonexistence(timeout: 2))
    }

    func testClose() throws {
        openDetail()
        closeDetail()

        openList()
        closeButton.tap()
        XCTAssert(closeButton.waitForNonexistence(timeout: 2))
    }

    func testModifyDestinationSetName() throws {
        let name = randomName()
        let note = randomName()

        putDestination()

        openList()
        app.buttons["Edit"].tap()
        nameField.tap()
        nameField.typeText(name)
        noteField.tap()
        noteField.typeText(note)
        closeButton.firstMatch.tap()
        XCTAssert(closeButton.waitForNonexistence(timeout: 2))

        openList()
        XCTAssert(app.staticTexts[name].exists)
        XCTAssert(app.staticTexts[note].exists)
    }

    func testNameDisplayed() throws {
        let name = randomName()
        openDetail()
        nameField.tap()
        nameField.typeText(name)
        closeDetail()

        openList()
        XCTAssert(app.staticTexts[name].exists)
    }

    func testRemove() throws {
        let name = randomName()
        openDetail()
        nameField.tap()
        nameField.typeText(name)
        closeDetail()

        openList()
        app.staticTexts[name].swipeLeft()
        app.buttons["Delete"].tap()
        closeButton.tap()
        _ = closeButton.waitForNonexistence(timeout: 2)

        XCTAssertFalse(app.otherElements[name].exists)
    }

    func testReorder() throws {
        let name1 = randomName()
        openDetail()
        nameField.tap()
        nameField.typeText(name1)
        closeDetail()

        let name2 = randomName()
        openDetail()
        nameField.tap()
        nameField.typeText(name2)
        closeDetail()

        openList()
        app.buttons["Edit"].tap()
        let reorder1 = app.buttons["Reorder"].firstMatch
        let reorder1pos = reorder1.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0))
        let reorder2pos = reorder1.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 1))
        reorder1pos.press(forDuration: 0, thenDragTo: reorder2pos)

        closeButton.tap()
        _ = closeButton.waitForNonexistence(timeout: 2)

        openList()
        let name1pos = app.staticTexts[name1].coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0))
        let name2pos = app.staticTexts[name2].coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0))
        XCTAssertGreaterThan(name1pos.screenPoint.y, name2pos.screenPoint.y)
    }

    func testDestruct() throws {
        let setname = randomName()
        let setnote = randomName()
        let name1 = randomName()
        let name2 = randomName()

        openDetail()
        nameField.tap()
        nameField.typeText(name1)
        closeDetail()

        openDetail()
        nameField.tap()
        nameField.typeText(name2)
        closeDetail()

        openList()
        app.buttons["Edit"].tap()
        nameField.tap()
        nameField.typeText(setname)
        noteField.tap()
        noteField.typeText(setnote)
        app.buttons["Trash"].tap()
        app.alerts.buttons["Delete"].tap()
        _ = closeButton.waitForNonexistence(timeout: 2)

        putDestination()
        openList()
        XCTAssertFalse(app.staticTexts[setname].exists)
        XCTAssertFalse(app.staticTexts[setnote].exists)
        XCTAssertFalse(app.staticTexts[name1].exists)
        XCTAssertFalse(app.staticTexts[name2].exists)
    }

    func testTapDestination() throws {
        let name = randomName()
        openDetail()
        nameField.tap()
        nameField.typeText(name)
        closeDetail()

        // Scroll out the pin.
        app.swipeUp()
        app.swipeUp()

        openList()
        app.staticTexts[name].tap()
        _ = closeButton.waitForNonexistence(timeout: 2)

        XCTAssert(app.otherElements[name].waitForExistence(timeout: 3))
    }
}
