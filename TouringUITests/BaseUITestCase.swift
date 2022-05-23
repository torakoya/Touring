import XCTest

class BaseUITestCase: XCTestCase {
    let app = XCUIApplication()

    var menuButton: XCUIElement { app.buttons["More"] }

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launchArguments += ["-AppleLanguages", "(en)"]
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

            // Tap a bit right of the center of the screen. The above
            // makes the user location annotation in the map selected,
            // so deselect it.
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.6, dy: 0.5)).tap()
        }
    }

    override func tearDownWithError() throws {
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
