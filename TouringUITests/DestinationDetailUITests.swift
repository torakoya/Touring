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

    @discardableResult private func openDetail(at point: XCUICoordinate? = nil) -> XCUICoordinate {
        let point = point ?? randomPoint()
        point.press(forDuration: 2)
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

        openDetail(at: point)
        XCTAssert(app.textFields[name].exists)
    }
}
