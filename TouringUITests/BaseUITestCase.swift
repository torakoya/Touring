import XCTest

class BaseUITestCase: XCTestCase {
    let app = XCUIApplication()

    var menuButton: XCUIElement { app.buttons["More"] }

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launchArguments += ["-AppleLanguages", "(en)"]
        app.launchEnvironment["UITEST"] = "1"
        app.resetAuthorizationStatus(for: .location)
        app.launch()

        if !name.contains("LocationAuthorization") {
            addUIInterruptionMonitor(withDescription: "Location Authorization") { (alert) -> Bool in
                let b = alert.buttons["Precise: Off"]
                if b.exists {
                    b.tap()
                }
                alert.buttons["Allow While Using App"].tap()
                return true
            }

            // Make the app responsive.
            app.tap()
            _ = app.otherElements["My Location"].waitForExistence(timeout: 2)

            // Tap a bit right of the center of the screen. The above
            // makes the user location annotation in the map selected,
            // so deselect it.
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.6, dy: 0.5)).tap()
        }
    }

    override func tearDownWithError() throws {
    }

    func randomName(withLength length: Int = 6) -> String {
        let chars = "abcdefghijklmnopqrstuvwxyz"

        return String((0..<length).map { _ in
            chars[chars.index(chars.startIndex, offsetBy: Int.random(in: 0..<chars.count))] })
    }

    func randomPoint() -> XCUICoordinate {
        app.coordinate(withNormalizedOffset: CGVector(
            dx: Double.random(in: 0.2...0.8), dy: Double.random(in: 0.3...0.8)))
    }

    @discardableResult
    func openDetail(at point: XCUICoordinate? = nil, ofExisting: Bool = false) -> XCUICoordinate {
        let point = point ?? randomPoint()
        if !ofExisting {
            point.press(forDuration: 2)
        }
        point.tap()
        _ = app.buttons["Close"].waitForExistence(timeout: 2)
        return point
    }

    func closeDetail() {
        app.buttons["Close"].firstMatch.tap()
        _ = app.buttons["Close"].waitForNonexistence(timeout: 2)
    }
}

extension XCUIElement {
    func waitForNonexistence(timeout: TimeInterval) -> Bool {
        let predicate = NSPredicate(format: "exists != true")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: self)
        let result = XCTWaiter().wait(for: [expectation], timeout: timeout)
        return result == .completed
    }
}
