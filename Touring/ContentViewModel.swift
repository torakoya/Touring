import SwiftUI

class ContentViewModel: ObservableObject, LocationDelegate, LocationLoggerDelegate {
    let location = Location()

    @Published var prefersMile = UserDefaults.standard.bool(forKey: "prefersMile") {
        didSet {
            UserDefaults.standard.set(prefersMile, forKey: "prefersMile")
            updateSpeedNumber()
        }
    }
    @Published var isSpeedValid = false
    @Published var speedNumber = ""
    var speedUnit: String {
        return prefersMile ? "mph" : "km/h"
    }
    @Published var isCourseValid = false
    @Published var course = Angle.degrees(0)

    @Published var alertingLocationAuthorizationRestricted = false
    @Published var alertingLocationAuthorizationDenied = false
    @Published var alertingLocationAccuracy = false
    @Published var alertingLocationLoggingError = false
    @Published var loggingState = LocationLogger.State.stopped

    init() {
        location.delegate = self
        location.logger.delegate = self

        updateSpeedNumber()
        updateCourse()
        loggingStateChanged()
    }

    func locationDidChangeAuthorization(_ location: Location) {
        if location.manager.authorizationStatus == .restricted {
            alertingLocationAuthorizationRestricted = true
        } else if location.manager.authorizationStatus == .denied {
            alertingLocationAuthorizationDenied = true
        } else if location.manager.accuracyAuthorization == .reducedAccuracy {
            alertingLocationAccuracy = true
        }
    }

    private func updateSpeedNumber() {
        if let mps = location.last?.speed, mps >= 0 {
            let val = mps * 60 * 60 / (prefersMile ? 1609.344 : 1000)
            speedNumber = Self.displayString(val)
            isSpeedValid = true
        } else {
            speedNumber = Self.displayString(0)
            isSpeedValid = false
        }
    }

    private func updateCourse() {
        if let loc = location.last, loc.courseAccuracy >= 0, loc.course >= 0 {
            course = .degrees(loc.course)
            isCourseValid = true
        } else {
            course = .degrees(0)
            isCourseValid = false
        }
    }

    /// Returns a string that represents a pretty-rounded number.
    ///
    /// * If the integer part of the number has a single digit, the
    ///   fractional part of the result has a single digit, otherwise no
    ///   digit.
    /// * Keeping the fractional part is preferable since it is more
    ///   informative. For example, if the number is 9.94, the result will
    ///   be "9.9", not "10".
    /// * If the number is zero, the result will be "0", not "0.0".
    /// * If the number is x.000, the result will be "x.0", not "x". FYI,
    ///   Apple Maps seems to prefer "x.0" and Google Maps "x".
    static func displayString(_ number: Double) -> String {
        let digits1 = round(number * 10) / 10

        if digits1 < 10 && digits1 != 0 {
            return String(format: "%.1f", digits1) // "a.x"
        } else {
            return String(Int(round(number))) // "ab"
        }
    }

    func locationDidUpdate(_ location: Location) {
        updateSpeedNumber()
        updateCourse()
    }

    func loggingStateChanged() {
        loggingState = location.logger.state
    }

    func loggingDidFailWithError(_ error: Error) {
        alertingLocationLoggingError = true
    }

    /// Open the Settings app.
    func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
}
