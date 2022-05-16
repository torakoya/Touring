import XCTest

class TouringUITests: BaseUITestCase {
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

    func testPutDestinations() throws {
        let oldCount = app.otherElements.count
        let point = app.coordinate(withNormalizedOffset: CGVector(
            dx: Double.random(in: 0.2...0.8), dy: Double.random(in: 0.2...0.8)))
        point.press(forDuration: 2)
        XCTAssertGreaterThan(app.otherElements.count, oldCount)
    }

    func testSwitchFollowing() throws {
        XCTAssert(app.buttons["location.square.fill"].exists)

        app.swipeUp()
        XCTAssert(app.buttons["location.square"].exists)

        app.buttons["location.square"].tap()
        XCTAssert(app.buttons["location.square.fill"].exists)
    }

    func testSwitchMapMode() throws {
        app.buttons["location.square.fill"].tap()
        XCTAssert(app.buttons["mappin.square.fill"].exists)

        app.buttons["mappin.square.fill"].tap()
        XCTAssert(app.buttons["location.square.fill"].exists)
    }

    func testChangeTarget() throws {
        let point1 = app.coordinate(withNormalizedOffset: CGVector(
            dx: Double.random(in: 0.2...0.8), dy: Double.random(in: 0.2...0.8)))
        point1.press(forDuration: 2)

        let point2 = app.coordinate(withNormalizedOffset: CGVector(
            dx: Double.random(in: 0.2...0.8), dy: Double.random(in: 0.2...0.8)))
        point2.press(forDuration: 2)

        XCTAssert(app.images["1.circle"].exists)

        app.buttons["Back"].tap()
        XCTAssertFalse(app.images["1.circle"].exists)

        app.buttons["Forward"].tap()
        XCTAssert(app.images["1.circle"].exists)

        app.buttons["Forward"].tap()
        XCTAssert(app.images["2.circle"].exists)
    }
}
