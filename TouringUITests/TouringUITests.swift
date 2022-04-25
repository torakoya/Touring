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

            // app.tap() is common, but it fires a tap event on an element
            // if the element is at the place where XCTest taps.
            app.swipeDown()
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

    func testTapLoggingControlButtons() throws {
        // Some system-provided symbol images seem to have alternative
        // names, and they can't be accessed by the original names but
        // by the alternative names.
        //
        // * "record.circle" => "Screen Recording"
        // * "pause.circle" => "Pause"
        // * "stop.circle" => "stop.circle" (no alternative name)

        XCTAssert(app.buttons["Screen Recording"].exists)
        XCTAssert(app.buttons["stop.circle"].exists)
        XCTAssertFalse(app.buttons["stop.circle"].isEnabled)

        app.buttons["Screen Recording"].tap()

        XCTAssert(app.buttons["Pause"].exists)
        XCTAssert(app.buttons["stop.circle"].isEnabled)

        app.buttons["Pause"].tap()

        XCTAssert(app.buttons["Screen Recording"].exists)
        XCTAssert(app.buttons["stop.circle"].isEnabled)

        app.buttons["Screen Recording"].tap()

        XCTAssert(app.buttons["Pause"].exists)
        XCTAssert(app.buttons["stop.circle"].isEnabled)

        app.buttons["stop.circle"].tap()

        XCTAssert(app.buttons["Screen Recording"].exists)
        XCTAssertFalse(app.buttons["stop.circle"].isEnabled)
    }
}
