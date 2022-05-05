import XCTest
import SwiftUI

class DestinationDetailUITests: BaseUITestCase {
    private func randomName(withLength length: Int = 6) -> String {
        let chars = "abcdefghijklmnopqrstuvwxyz"

        return String((0..<length).map { _ in
            chars[chars.index(chars.startIndex, offsetBy: Int.random(in: 0..<chars.count))] })
    }

    private func randomPoint() -> XCUICoordinate {
        app.coordinate(withNormalizedOffset: CGVector(
            dx: Double.random(in: 0.2...0.8), dy: Double.random(in: 0.2...0.8)))
    }

    @discardableResult
    private func openDetail(at point: XCUICoordinate? = nil, ofExisting: Bool = false) -> XCUICoordinate {
        let point = point ?? randomPoint()
        if !ofExisting {
            point.press(forDuration: 2)
        }
        point.tap()
        _ = app.buttons["Close"].waitForExistence(timeout: 2)
        return point
    }

    private func closeDetail() {
        app.buttons["Close"].tap()
        _ = app.buttons["Close"].waitForNonexistence(timeout: 2)
    }

    func testTapCloseButton() throws {
        openDetail()
        app.buttons["Close"].tap()
        XCTAssert(app.buttons["Close"].waitForNonexistence(timeout: 2))
    }

    func testRename() throws {
        let name = randomName()

        let point = openDetail()

        let tf = app.textFields["Name"]
        tf.tap()
        tf.typeText(name)
        XCTAssert(app.textFields[name].exists)

        closeDetail()
        XCTAssert(app.otherElements[name].exists)

        openDetail(at: point, ofExisting: true)
        XCTAssert(app.textFields[name].exists)
    }

    func testRemove() throws {
        let name = randomName()
        let point = openDetail()

        let tf = app.textFields["Name"]
        tf.tap()
        tf.typeText(name)

        closeDetail()
        openDetail(at: point, ofExisting: true)
        app.buttons["Remove"].tap()
        _ = app.buttons["Close"].waitForNonexistence(timeout: 2)
        XCTAssertFalse(app.otherElements[name].exists)
    }

    func testRemoveMiddle() throws {
        let name1 = randomName()
        openDetail()
        let tf1 = app.textFields["Name"]
        tf1.tap()
        tf1.typeText(name1)
        closeDetail()

        let name2 = randomName()
        let point2 = openDetail()
        let tf2 = app.textFields["Name"]
        tf2.tap()
        tf2.typeText(name2)
        closeDetail()

        let name3 = randomName()
        openDetail()
        let tf3 = app.textFields["Name"]
        tf3.tap()
        tf3.typeText(name3)
        closeDetail()

        openDetail(at: point2, ofExisting: true)
        app.buttons["Remove"].tap()
        _ = app.buttons["Close"].waitForNonexistence(timeout: 2)
        XCTAssert(app.otherElements[name1].exists)
        XCTAssertFalse(app.otherElements[name2].exists)
        XCTAssert(app.otherElements[name3].exists)
    }
}
