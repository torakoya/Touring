import XCTest

class TouringUITests: BaseUITestCase {
    var backwardButton: XCUIElement { app.buttons["chevron.backward.2"] }
    var forwardButton: XCUIElement { app.buttons["chevron.forward.2"] }

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

    func testMenu() throws {
        menuButton.tap()
        XCTAssert(app.buttons["Start Location Tracking"].waitForExistence(timeout: 2))

        app.coordinate(withNormalizedOffset: CGVector(dx: 0.6, dy: 0.5)).tap()
        XCTAssert(app.buttons["Start Location Tracking"].waitForNonexistence(timeout: 2))
    }

    func testLocationTracking() throws {
        let startButton = app.buttons["Start Location Tracking"]
        let resumeButton = app.buttons["Resume Location Tracking"]
        let pauseButton = app.buttons["Pause Location Tracking"]
        let stopButton = app.buttons["Stop Location Tracking"]
        let recordLabel = app.staticTexts["Rec"]
        let pauseLabel = app.staticTexts["Pause"]

        menuButton.tap()
        XCTAssert(startButton.waitForExistence(timeout: 2))
        XCTAssertFalse(resumeButton.exists)
        XCTAssertFalse(pauseButton.exists)
        XCTAssertFalse(stopButton.exists)
        startButton.tap()
        XCTAssert(recordLabel.waitForExistence(timeout: 2))

        menuButton.tap()
        XCTAssert(pauseButton.waitForExistence(timeout: 2))
        XCTAssert(stopButton.waitForExistence(timeout: 2))
        XCTAssertFalse(startButton.exists)
        XCTAssertFalse(resumeButton.exists)
        pauseButton.tap()
        XCTAssert(pauseLabel.waitForExistence(timeout: 2))

        menuButton.tap()
        XCTAssert(resumeButton.waitForExistence(timeout: 2))
        XCTAssert(stopButton.waitForExistence(timeout: 2))
        XCTAssertFalse(startButton.exists)
        XCTAssertFalse(pauseButton.exists)
        resumeButton.tap()
        XCTAssert(recordLabel.waitForExistence(timeout: 2))

        // started => stop
        menuButton.tap()
        XCTAssert(pauseButton.waitForExistence(timeout: 2))
        XCTAssert(stopButton.waitForExistence(timeout: 2))
        XCTAssertFalse(startButton.exists)
        XCTAssertFalse(resumeButton.exists)
        stopButton.tap()
        XCTAssert(recordLabel.waitForNonexistence(timeout: 2))
        XCTAssertFalse(pauseLabel.exists)

        menuButton.tap()
        XCTAssert(startButton.waitForExistence(timeout: 2))
        XCTAssertFalse(resumeButton.exists)
        XCTAssertFalse(pauseButton.exists)
        XCTAssertFalse(stopButton.exists)

        // paused => stop
        startButton.tap()
        menuButton.tap()
        _ = pauseButton.waitForExistence(timeout: 2)
        pauseButton.tap()
        menuButton.tap()
        _ = stopButton.waitForExistence(timeout: 2)
        stopButton.tap()
        XCTAssert(recordLabel.waitForNonexistence(timeout: 2))
        XCTAssertFalse(pauseLabel.exists)
        menuButton.tap()
        XCTAssert(startButton.waitForExistence(timeout: 2))
        XCTAssertFalse(resumeButton.exists)
        XCTAssertFalse(pauseButton.exists)
        XCTAssertFalse(stopButton.exists)
    }

    func testPutDestinations() throws {
        putDestination()
        XCTAssert(app.otherElements["Map pin"].exists)
    }

    func testSwitchFollowing() throws {
        XCTAssert(app.buttons["location.square.fill"].exists)

        app.swipeUp()
        XCTAssert(app.buttons["location.square"].exists)

        app.buttons["location.square"].tap()
        XCTAssert(app.buttons["location.square.fill"].exists)
    }

    func testSwitchMapMode() throws {
        putDestination()

        app.buttons["location.square.fill"].tap()
        XCTAssert(app.buttons["mappin.square.fill"].exists)

        app.buttons["mappin.square.fill"].tap()
        XCTAssert(app.buttons["location.square.fill"].exists)

        app.buttons["location.square.fill"].press(forDuration: 2)
        XCTAssert(app.buttons["Show Map"].exists)

        app.buttons["Show Map"].tap()
        XCTAssert(app.buttons["location.square.fill"].exists)

        app.buttons["location.square.fill"].tap()
        app.buttons["mappin.square.fill"].press(forDuration: 2)
        XCTAssert(app.buttons["Show Map"].exists)

        app.buttons["Show Map"].tap()
        XCTAssert(app.buttons["mappin.square.fill"].exists)
    }

    func testChangeTarget() throws {
        putDestination()
        putDestination()

        XCTAssert(app.images["1.circle"].exists)

        backwardButton.tap()
        XCTAssertFalse(app.images["1.circle"].exists)

        forwardButton.tap()
        XCTAssert(app.images["1.circle"].exists)

        forwardButton.tap()
        XCTAssert(app.images["2.circle"].exists)
    }

    func testRoutes() throws {
        putDestination()

        backwardButton.tap()
        app.buttons["Hide"].tap()
        let query = app.staticTexts.containing(NSPredicate(format: "label matches '[0-9]h [0-9]+m'"))
        XCTAssert(query.element.waitForExistence(timeout: 5))

        putDestination()

        forwardButton.tap()
        XCTAssert(query.element.waitForExistence(timeout: 8))

        app.buttons["Show"].tap()
        XCTAssert(query.element.waitForNonexistence(timeout: 5))
    }
}
