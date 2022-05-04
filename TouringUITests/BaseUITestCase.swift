import XCTest

class BaseUITestCase: XCTestCase {
    let app = XCUIApplication()

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

            // app.tap() is common, but it fires a tap event on an element
            // if the element is at the place where XCTest taps.
            app.swipeDown()
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
