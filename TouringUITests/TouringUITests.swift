import XCTest

class TouringUITests: XCTestCase {
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
            app.tap()
        }
    }

    override func tearDownWithError() throws {
    }

    func testLocationAuthAllowed() throws {
        XCTAssertEqual(app.alerts.count, 0)
    }

    func testLocationAuthorizationDenied() throws {
        addUIInterruptionMonitor(withDescription: "Location Authorization") { (alert) -> Bool in
            alert.buttons["Don’t Allow"].tap()
            return true
        }

        app.tap()
        XCTAssert(app.alerts["Location access is denied"].exists)
    }

    func testLocationAuthorizationReducedAccuracy() throws {
        addUIInterruptionMonitor(withDescription: "Location Authorization") { (alert) -> Bool in
            let b = alert.buttons["Precise: On"]
            if b.exists {
                b.tap()
            }
            alert.buttons["Allow While Using App"].tap()
            return true
        }

        app.tap()
        XCTAssert(app.alerts["Location accuracy is reduced"].exists)
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

    func testRestoreSpeedUnitChoice() throws {
        let u1 = app.staticTexts["km/h"]
        let u2 = app.staticTexts["mph"]
        let e1 = u1.exists

        (u1.exists ? u1 : u2).tap()
        app.launch()
        XCTAssertNotEqual(u1.exists, e1)
    }
}
